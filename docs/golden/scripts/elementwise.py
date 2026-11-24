"""Generates the element-wise function golden data
(docs/golden/elementwise.json, src/pl/golden_elementwise_data_test.mbt).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/elementwise.py

The file is `{"inputs": {key: series}, "cases": [...]}` (compact layout, see
`emit(compact=True)`); `a`, `lo`, `hi` and `value` of a case are keys of
`inputs`. Every case has `id`, `op`, `a`, `polars` (the Python spelling that
produced it) and either `result` (a series, through `to_ours`) or `error` +
`message` (variant name per the M2 error mapping and the first line of
polars' message), or `restricted: true` (see `MATH_OPS` below; `polars_dtype`
records the type polars returned when it succeeded).

Operations: `is_null is_not_null is_nan is_not_nan is_finite is_infinite abs
sqrt exp log round fill_null between`. Extra case fields: `base` (log, a float
in Python `repr`), `decimals` (round), `value` (fill_null: a series of length
1, or of length 1 with dtype null for a null fill), `lo`, `hi`, `closed`
(between: `both left right none`).

The reference is polars 2.1.0 through the expression engine (what the later
expression task wraps): `pl.DataFrame([s]).select(pl.col("a").<op>())`;
`fill_null` with a strongly typed literal (`pl.lit(v, dtype=...)`), so the
result type is the supertype of the column and the value.

`round` is the default mode of polars 2.1.0, `half_to_even`. polars takes
`decimals` as an unsigned integer: a negative one is a Python `OverflowError`
before polars runs; the library raises `InvalidOperation` instead (see
docs/golden/known-diffs/elementwise.md), so those cases carry that error and
the message the library uses, plus `python_error`.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import polars as pl

from emit import DTYPE_NAMES, emit, encode_series, series_from_spec, to_ours

nan = float("nan")
inf = float("inf")
I64_MIN = -9223372036854775808
I64_MAX = 9223372036854775807

DTYPES = list(DTYPE_NAMES)

# `abs sqrt exp log round` on these types: polars computes (sqrt, exp, log of
# bool; sqrt of str, date, datetime) or fails with varying texts, but spec 5.5
# (Boolean has no arithmetic, String only comparisons and the str namespace,
# Date and Datetime only comparisons in M2) wins: the library raises
# InvalidOperation. Such cases are `"restricted": true`; the test only requires
# the variant. `null` keeps polars' behaviour.
MATH_OPS = ("abs", "sqrt", "exp", "log", "round")
NON_NUMERIC = ("bool", "str", "date", "datetime[μs]")

# Values per dtype (shared by the predicates, abs, sqrt, exp, log). Every list
# has a null; the ints have 0, -1, 1, MIN, MAX; the floats have NaN, +-inf,
# -0.0 and 0.0.
VALS = {
    "bool": [True, False, None],
    "i32": [0, -1, 1, -2147483648, 2147483647, 4, None],
    "i64": [0, -1, 1, I64_MIN, I64_MAX, 4, None],
    "f32": [1.0, nan, None, -inf, -0.0, 0.0, inf, 2.5, -2.5, 0.5, 3.0e38, 0.1, 88.0, 89.0, -104.0, 1e-40, 100.0, 1e-3],
    "f64": [1.0, nan, None, -inf, -0.0, 0.0, inf, 2.5, -2.5, 0.5, 1e308, 0.1, 709.0, 710.0, -745.0, 5e-324, 100.0, 1e-3],
    "str": ["4", "x", "-1", "1e2", "", None, "｡", "\U0001F600"],
    "date": [0, -1, 19782, -25567, None],
    "datetime[μs]": [0, -1, 1709210096123456, 86399999999, None],
    "null": [None, None, None],
}

# Values for round: .5 ties of both signs, values that are not exact in binary
# (2.675, 1.005, 0.285), huge values (x * 10^d overflows) and tiny ones.
ROUND_F = [0.5, 1.5, 2.5, -0.5, -1.5, -2.5, 0.125, 0.375, 2.675, -2.675, 1.005, 0.285,
           15.0, 25.0, 123456.789, 1e308, -1e308, 1e-320, 5e-324, 0.45, 0.55,
           4.5e15, nan, inf, -inf, -0.0, 0.0, None]
ROUND_F32 = [0.5, 1.5, 2.5, -0.5, -2.5, 0.125, 2.675, -2.675, 1.005, 0.285, 15.0, 25.0,
             123456.789, 3e38, -3e38, 1e-40, 0.45, 0.55, nan, inf, -inf, -0.0, 0.0, None]
ROUND_I = [0, 5, 15, 25, -5, -15, -25, 14, 16, 123456, None]

VARIANTS = {
    "ColumnNotFoundError": "ColumnNotFound",
    "DuplicateError": "DuplicateColumn",
    "SchemaError": "SchemaMismatch",
    "ShapeError": "ShapeMismatch",
    "OutOfBoundsError": "OutOfBounds",
    "InvalidOperationError": "InvalidOperation",
    "ComputeError": "ComputeError",
}


def error_of(e):
    name = type(e).__name__
    return VARIANTS.get(name, name), str(e).split("\n")[0]


def attempt(f):
    """`(result, None)` or `(None, (variant, message))`; polars panics count as
    errors too."""
    try:
        return f(), None
    except Exception as e:  # noqa: BLE001
        return None, error_of(e)
    except BaseException as e:  # noqa: BLE001
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        return None, error_of(e)


INPUTS = {}


def ref(label, series):
    """Key of `series` in `INPUTS`; identical series share one entry (the name
    is part of the series). `label` is stored as `"for"` for the reader."""
    enc = encode_series(series)
    for key, value in INPUTS.items():
        if {k: v for k, v in value.items() if k != "for"} == enc:
            return key
    key = f"i{len(INPUTS)}"
    INPUTS[key] = dict(enc, **{"for": label})
    return key


def mk(name, dtype, values):
    return series_from_spec(name, dtype, values)


def finish(case, result, err):
    if err is not None:
        case["error"], case["message"] = err
        return case
    ours, original = to_ours(result)
    case["result"] = encode_series(ours)
    if ours.dtype != result.dtype:
        case["polars_dtype"] = original
    return case


def expr(s, f):
    """Result series of the expression `f(pl.col("a"))` over `s`."""
    return pl.DataFrame([s]).select(f(pl.col("a"))).to_series()


def unary(cases, op, dtype, values, call, text, label=None, **extra):
    s = mk("a", dtype, values)
    result, err = attempt(lambda: expr(s, call))
    cid = label or f"{op}/{dtype}"
    case = {"id": cid, "op": op, "a": ref(f"{dtype}.{op}", s), "polars": text}
    case.update(extra)
    if op in MATH_OPS and dtype in NON_NUMERIC:
        # spec 5.5 / M2 global: the library raises InvalidOperation here
        case["restricted"] = True
        if result is not None:
            case["polars_dtype"] = str(result.dtype)
        cases.append(case)
        return
    cases.append(finish(case, result, err))


def main():
    cases = []

    # ---- predicates and abs/sqrt/exp over every dtype -----------------
    for op in ("is_null", "is_not_null", "is_nan", "is_not_nan", "is_finite", "is_infinite", "abs", "sqrt", "exp"):
        for d in DTYPES:
            unary(cases, op, d, VALS[d], lambda c, op=op: getattr(c, op)(),
                  f'pl.DataFrame([s]).select(pl.col("a").{op}())')
        # empty input
        for d in ("i32", "f64", "str", "null"):
            unary(cases, op, d, [], lambda c, op=op: getattr(c, op)(),
                  f'pl.DataFrame([s]).select(pl.col("a").{op}())', label=f"{op}/{d}/empty")

    # ---- log: default base and several bases --------------------------
    for d in DTYPES:
        unary(cases, "log", d, VALS[d], lambda c: c.log(),
              'pl.DataFrame([s]).select(pl.col("a").log())')
    for base in (2.0, 10.0, 0.5, 3.0, 1.0, 0.0, -2.0, inf, nan):
        for d in ("i32", "i64", "f32", "f64"):
            unary(cases, "log", d, VALS[d], lambda c, base=base: c.log(base),
                  f'pl.DataFrame([s]).select(pl.col("a").log({base!r}))',
                  label=f"log/{d}/base={base!r}", base=repr(base))
    for d in ("str", "bool", "null"):
        unary(cases, "log", d, VALS[d], lambda c: c.log(2.0),
              'pl.DataFrame([s]).select(pl.col("a").log(2.0))',
              label=f"log/{d}/base=2.0", base="2.0")

    # ---- round --------------------------------------------------------
    for d in DTYPES:
        vals = {"f32": ROUND_F32, "f64": ROUND_F, "i32": ROUND_I, "i64": ROUND_I}.get(d, VALS[d])
        for dec in (0, 1, 2, 5):
            if dec > 0 and d not in ("f32", "f64", "i32", "i64"):
                continue
            unary(cases, "round", d, vals, lambda c, dec=dec: c.round(dec),
                  f'pl.DataFrame([s]).select(pl.col("a").round({dec}))',
                  label=f"round/{d}/decimals={dec}", decimals=dec)
    for d in ("f64", "f32", "i32", "i64", "str"):
        for dec in (-1, -3):
            s = mk("a", d, {"f32": ROUND_F32, "f64": ROUND_F, "i32": ROUND_I, "i64": ROUND_I}.get(d, VALS[d]))
            _, err = attempt(lambda: expr(s, lambda c: c.round(dec)))
            assert err is not None and err[0] == "OverflowError", err
            case = {
                "id": f"round/{d}/decimals={dec}", "op": "round", "a": ref(f"{d}.round", s),
                "decimals": dec,
                "polars": f'pl.DataFrame([s]).select(pl.col("a").round({dec}))',
                "python_error": f"{err[0]}: {err[1]}",
                "error": "InvalidOperation",
                "message": f"decimals must be non-negative, got {dec}",
            }
            cases.append(case)
    # rounding does not blow up for huge decimals
    for d in ("f64", "f32"):
        for dec in (15, 22):
            unary(cases, "round", d, ROUND_F if d == "f64" else ROUND_F32, lambda c, dec=dec: c.round(dec),
                  f'pl.DataFrame([s]).select(pl.col("a").round({dec}))',
                  label=f"round/{d}/decimals={dec}", decimals=dec)

    # ---- fill_null: every column dtype x every value dtype -----------
    fills = {
        "bool": [True], "i32": [7], "i64": [I64_MAX], "f32": [1.5], "f64": [2.25],
        "str": ["z\U0001F600"], "date": [5], "datetime[μs]": [86400000005], "null": [None],
    }
    cols = {
        "bool": [True, None, False, None],
        "i32": [0, None, -2147483648, None, 2147483647],
        "i64": [I64_MIN, None, 1, None],
        "f32": [1.0, nan, None, -inf, -0.0, None, 0.1],
        "f64": [1.0, nan, None, -inf, -0.0, None, 0.1],
        "str": ["a", None, "", None],
        "date": [0, None, 19782, None],
        "datetime[μs]": [0, None, 1709210096123456, None],
        "null": [None, None],
    }
    for cd in DTYPES:
        for vd in DTYPES:
            s = mk("a", cd, cols[cd])
            v = mk("v", vd, fills[vd])
            result, err = attempt(lambda: expr(s, lambda c: c.fill_null(pl.lit(v[0], dtype=v.dtype) if vd != "null" else pl.lit(None, dtype=pl.Null))))
            cid = f"fill_null/{cd}/{vd}"
            case = {"id": cid, "op": "fill_null", "a": ref(f"{cid}.a", s), "value": ref(f"{cid}.value", v),
                    "polars": f'pl.DataFrame([s]).select(pl.col("a").fill_null(pl.lit(<{vd} value>, dtype=<{vd}>)))'}
            cases.append(finish(case, result, err))
    # a column without nulls, a column of only nulls, an empty column
    for cd, vals in (("i32", [1, 2, 3]), ("i32", [None, None]), ("i32", []), ("str", []), ("f64", [None])):
        s = mk("a", cd, vals)
        v = mk("v", "f64", [1.5])
        result, err = attempt(lambda: expr(s, lambda c: c.fill_null(pl.lit(1.5, dtype=pl.Float64))))
        cid = f"fill_null/{cd}/f64/{'-'.join(str(x) for x in vals) or 'empty'}"
        case = {"id": cid, "op": "fill_null", "a": ref(f"{cid}.a", s), "value": ref(f"{cid}.value", v),
                "polars": 'pl.DataFrame([s]).select(pl.col("a").fill_null(pl.lit(1.5, dtype=pl.Float64)))'}
        cases.append(finish(case, result, err))

    # ---- between ------------------------------------------------------
    a = mk("a", "i32", [1, 2, 3, 4, None, 5])
    lo = mk("lo", "i32", [2, 2, None, 1, 0, 5])
    hi = mk("hi", "i32", [4, 2, 4, 3, 9, 5])

    def between(cid, a, lo, hi, closed):
        result, err = attempt(lambda: a.is_between(lo, hi, closed=closed))
        case = {"id": cid, "op": "between", "a": ref(f"{cid}.a", a), "lo": ref(f"{cid}.lo", lo),
                "hi": ref(f"{cid}.hi", hi), "closed": closed,
                "polars": f's_a.is_between(s_lo, s_hi, closed="{closed}")'}
        cases.append(finish(case, result, err))

    for closed in ("both", "left", "right", "none"):
        between(f"between/i32/{closed}", a, lo, hi, closed)
        between(f"between/i32/{closed}/null-bounds", a, mk("lo", "i32", [None] * 6), hi, closed)
        between(f"between/i32/{closed}/null-hi", a, lo, mk("hi", "i32", [None] * 6), closed)
        between(f"between/i32/{closed}/scalar-bounds", a, mk("lo", "i32", [2]), mk("hi", "i32", [4]), closed)
        between(f"between/i32/{closed}/lo-gt-hi", a, mk("lo", "i32", [5]), mk("hi", "i32", [1]), closed)
        between(f"between/i32/{closed}/scalar-a", a[:1].alias("a"), lo, hi, closed)
        between(f"between/i32/{closed}/empty", a[:0], lo[:0], hi[:0], closed)
        between(f"between/i32/{closed}/empty-scalar-bounds", a[:0], mk("lo", "i32", [2]), mk("hi", "i32", [4]), closed)
        # length errors: the message names the failing comparison
        for (na, nl, nh) in [(6, 3, 6), (6, 6, 3), (6, 3, 3), (3, 6, 6), (0, 3, 3), (3, 0, 3), (3, 3, 0), (3, 2, 1)]:
            sa = pl.Series("a", list(range(na)), dtype=pl.Int32)
            sl = pl.Series("lo", list(range(nl)), dtype=pl.Int32)
            sh = pl.Series("hi", list(range(nh)), dtype=pl.Int32)
            between(f"between/i32/{closed}/len={na},{nl},{nh}", sa, sl, sh, closed)
    # type combinations (bounds are cut or padded with null to the length of a)
    def fit(s, n):
        return s.extend_constant(None, n - s.len())[:n] if s.len() < n else s[:n]

    combos = [
        ("i32", "i64", "f64"), ("f32", "i32", "i32"), ("i64", "i32", "i32"), ("f32", "f32", "f32"),
        ("f64", "f64", "f64"), ("f32", "f64", "i64"), ("str", "str", "str"), ("str", "i32", "i32"),
        ("str", "bool", "bool"), ("i32", "str", "str"), ("str", "str", "i32"), ("bool", "bool", "bool"),
        ("bool", "i32", "i32"), ("bool", "date", "date"), ("date", "bool", "bool"), ("bool", "bool", "date"),
        ("date", "date", "date"), ("date", "dt", "dt"), ("dt", "date", "date"), ("dt", "dt", "dt"),
        ("i32", "date", "date"), ("null", "i32", "i32"), ("i32", "null", "null"), ("null", "null", "null"),
        ("null", "bool", "date"),
    ]
    dt_name = {"dt": "datetime[μs]"}
    for ka, kl, kh in combos:
        ka, kl, kh = dt_name.get(ka, ka), dt_name.get(kl, kl), dt_name.get(kh, kh)
        sa = mk("a", ka, VALS[ka])
        sl = fit(mk("lo", kl, VALS[kl]), sa.len())
        sh = fit(mk("hi", kh, VALS[kh]), sa.len())
        for closed in ("both", "right"):
            between(f"between/{ka}/{kl}/{kh}/{closed}", sa, sl, sh, closed)
    # same-type scalar bounds on every dtype
    for d in DTYPES:
        sa = mk("a", d, VALS[d])
        one = mk("x", d, VALS[d][:1])
        between(f"between/{d}/same-scalar", sa, one.alias("lo"), one.alias("hi"), "both")
    # floats: NaN is above every number, -0.0 == 0.0
    f = mk("a", "f64", [nan, inf, -inf, 0.0, -0.0, 1.0, None])
    between("between/f64/nan-a", f, mk("lo", "f64", [-inf]), mk("hi", "f64", [inf]), "both")
    between("between/f64/nan-bounds", mk("a", "f64", [1.0, nan, 0.0]), mk("lo", "f64", [nan]), mk("hi", "f64", [nan]), "both")
    between("between/f64/zero-bounds", f, mk("lo", "f64", [-0.0]), mk("hi", "f64", [0.0]), "both")
    between("between/f64/zero-bounds-open", f, mk("lo", "f64", [-0.0]), mk("hi", "f64", [0.0]), "none")
    # strings by code point
    s = mk("a", "str", ["｡", "\U0001F600", "a", "", "Z", None])
    between("between/str/code-point", s, mk("lo", "str", ["a"]), mk("hi", "str", ["\U0001F600"]), "both")
    between("between/str/code-point-left", s, mk("lo", "str", ["｡"]), mk("hi", "str", ["\U0001F600"]), "left")

    ids = [c["id"] for c in cases]
    assert len(ids) == len(set(ids)), "duplicate case ids: " + str([i for i in ids if ids.count(i) > 1][:5])
    emit("elementwise", {"cases": cases, "inputs": INPUTS}, compact=True)
    print(f"polars {pl.__version__}: wrote {len(cases)} cases")


main()
