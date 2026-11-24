"""Generates the Series arithmetic / comparison / logic / filter golden data
(docs/golden/arith.json, src/pl/golden_arith_data_test.mbt).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/arith.py

The file is `{"inputs": {key: series}, "cases": [...]}` (compact layout, see
`emit(compact=True)`); `a`, `b` and `mask` of a case are keys of `inputs`.
Every case has `id`, `op`, `a` (and `b` or `mask`), `polars` (the Python
spelling that produced it) and either `result` (a series, through `to_ours`),
`error` + `message` (variant name per the M2 error mapping and the first line
of polars' message), or `restricted: true`.

`restricted` marks the cases where this library is deliberately stricter than
polars (spec 5.5: arithmetic is only for Int32, Int64, Float32, Float64 and
Null; bitwise and/or/not only for Boolean). polars may succeed there (bool +
i32, str + str, date - date, i32 & i32, ...) or fail with a text that varies
from case to case; the test only requires `InvalidOperation`. The polars
dtype of a successful result is kept in `polars_dtype` for the record (for
ordinary cases only when `to_ours` mapped it, e.g. `UInt32`). See
docs/golden/known-diffs/arith.md.
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

# Values per dtype. Every list has a null; the ints have 0, -1, 1, MIN, MAX;
# the floats have NaN, +-inf, -0.0 and 0.0; the strings have the Review Focus
# set ("｡" < "\U0001F600" by code point but not by UTF-16 code unit).
VALS = {
    "bool": [True, False, None],
    "i32": [0, -1, 1, -2147483648, 2147483647, None],
    "i64": [0, -1, 1, I64_MIN, I64_MAX, None],
    "f32": [1.0, nan, None, -inf, -0.0, 0.0, inf, 3.0e38, 0.1],
    "f64": [1.0, nan, None, -inf, -0.0, 0.0, inf, 5.5, -2.5, 1e308],
    "str": ["｡", "\U0001F600", "a", "", "Z", None],
    "date": [0, -1, 19782, -25567, None],
    "datetime[μs]": [0, -1, 1709210096123456, 86399999999, None],
    "null": [None, None, None, None],
}
DTYPES = list(DTYPE_NAMES)

ARITH_OK = ("i32", "i64", "f32", "f64", "null")
INTS = ("i32", "i64")

VARIANTS = {
    "ColumnNotFoundError": "ColumnNotFound",
    "DuplicateError": "DuplicateColumn",
    "SchemaError": "SchemaMismatch",
    "ShapeError": "ShapeMismatch",
    "OutOfBoundsError": "OutOfBounds",
    "InvalidOperationError": "InvalidOperation",
    "ComputeError": "ComputeError",
}

BINARY = {
    "add": (lambda a, b: a + b, "s1 + s2"),
    "sub": (lambda a, b: a - b, "s1 - s2"),
    "mul": (lambda a, b: a * b, "s1 * s2"),
    "truediv": (lambda a, b: a / b, "s1 / s2"),
    "floordiv": (lambda a, b: a // b, "s1 // s2"),
    "mod": (lambda a, b: a % b, "s1 % s2"),
    "eq": (lambda a, b: a == b, "s1 == s2"),
    "ne": (lambda a, b: a != b, "s1 != s2"),
    "gt": (lambda a, b: a > b, "s1 > s2"),
    "ge": (lambda a, b: a >= b, "s1 >= s2"),
    "lt": (lambda a, b: a < b, "s1 < s2"),
    "le": (lambda a, b: a <= b, "s1 <= s2"),
    "and": (lambda a, b: a & b, "s1 & s2"),
    "or": (lambda a, b: a | b, "s1 | s2"),
}
# the same operators as expressions, used where the Series operator is not
# the contract: and/or with a Null operand (the expression engine treats Null
# as an all-null Boolean) and length mismatches (`ShapeError`, same text for
# every operator)
EXPR = {
    "add": lambda a, b: a + b,
    "eq": lambda a, b: a == b,
    "and": lambda a, b: a & b,
    "or": lambda a, b: a | b,
    "floordiv": lambda a, b: a // b,
    "lt": lambda a, b: a < b,
    "mul": lambda a, b: a * b,
}
SYMBOL = {"and": "&", "or": "|", "add": "+", "eq": "==", "floordiv": "//", "lt": "<", "mul": "*"}
ARITH = ("add", "sub", "mul", "truediv", "floordiv", "mod")


def error_of(e):
    """(variant, first line of the message). Names without an entry in the
    M2 error mapping (Python's `TypeError`, `RuntimeError`, ...) stay as is."""
    name = type(e).__name__
    return VARIANTS.get(name, name), str(e).split("\n")[0]


def attempt(f):
    """`(result, None)` or `(None, (variant, message))`; polars panics
    (`PanicException`, a `BaseException`) count as errors too."""
    try:
        return f(), None
    except Exception as e:  # noqa: BLE001
        return None, error_of(e)
    except BaseException as e:  # noqa: BLE001
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        return None, error_of(e)


# Input series, shared between cases: `ref` stores a series once under the
# first label that used it and returns the key a case refers to.
INPUTS = {}


def ref(label, series):
    """Key of `series` in `INPUTS` (`i0`, `i1`, ...). `label` says what the
    series is for and is stored with it as `"for"` so the file stays
    readable; identical series share one entry."""
    enc = encode_series(series)
    for key, value in INPUTS.items():
        if {k: v for k, v in value.items() if k != "for"} == enc:
            return key
    key = f"i{len(INPUTS)}"
    INPUTS[key] = dict(enc, **{"for": label})
    return key


def mk(name, dtype, values):
    return series_from_spec(name, dtype, values)


def cross(av, bv):
    """Every pair (x, y) of the two value lists: x repeated, y tiled."""
    return [x for x in av for _ in bv], [y for _ in av for y in bv]


def small(vals):
    """The first two values (used where the pair is restricted anyway)."""
    return vals[:2] if len(vals) > 1 else vals


def finish(case, result, err, restricted=False):
    if restricted:
        case["restricted"] = True
        if result is not None:
            case["polars_dtype"] = str(result.dtype)
        return case
    if err is not None:
        case["error"], case["message"] = err
        return case
    ours, original = to_ours(result)
    case["result"] = encode_series(ours)
    if ours.dtype != result.dtype:  # only a type the library maps differently
        case["polars_dtype"] = original
    return case


def binary_case(op, x, y, a_vals, b_vals, restricted, expr=False, label=None):
    a = mk("a", x, a_vals)
    b = mk("b", y, b_vals)
    f, text = BINARY[op]
    if expr:
        g = EXPR[op]
        text = f'pl.DataFrame([s1, s2]).select(pl.col("a") {SYMBOL[op]} pl.col("b")).to_series()'
        run = lambda: pl.DataFrame([a, b]).select(g(pl.col("a"), pl.col("b"))).to_series()
    else:
        run = lambda: f(a, b)
    result, err = attempt(run)
    cid = label or f"{op}/{x}x{y}"
    case = {
        "id": cid,
        "op": op,
        "a": ref(f"{cid}.a", a),
        "b": ref(f"{cid}.b", b),
        "polars": text,
    }
    return finish(case, result, err, restricted)


def main():
    cases = []

    # ---- binary operators over every pair of dtypes -------------------
    for op in BINARY:
        for x in DTYPES:
            for y in DTYPES:
                if op in ARITH:
                    restricted = x not in ARITH_OK or y not in ARITH_OK
                elif op in ("and", "or"):
                    # i32 & i32 and i64 & i64 are bitwise in polars
                    restricted = x == y and x in INTS
                else:
                    restricted = False
                av, bv = VALS[x], VALS[y]
                if restricted or (op in ("and", "or") and not (x == "bool" and y == "bool")):
                    av, bv = small(av), small(bv)
                a_vals, b_vals = cross(av, bv)
                # Boolean with Null: the Series operator rejects it but the
                # expression engine (Null is an all-null Boolean) is the
                # contract. Null with any other type: the Series operator.
                expr = op in ("and", "or") and {x, y} == {"bool", "null"}
                cases.append(binary_case(op, x, y, a_vals, b_vals, restricted, expr))

    # ---- unary: neg, not ---------------------------------------------
    for x in DTYPES:
        s = mk("a", x, VALS[x])
        result, err = attempt(lambda: -s)
        restricted = False
        cases.append(finish(
            {"id": f"neg/{x}", "op": "neg", "a": ref(f"{x}.vals", s), "polars": "-s1"},
            result, err, restricted))
        result, err = attempt(lambda: ~s)
        restricted = x in INTS
        cases.append(finish(
            {"id": f"not/{x}", "op": "not", "a": ref(f"{x}.vals", s), "polars": "~s1"},
            result, err, restricted))

    # ---- broadcast and length errors ---------------------------------
    one = {"bool": [True], "i32": [7], "i64": [I64_MAX], "f32": [0.5], "f64": [2.0], "str": ["a"], "date": [5], "datetime[μs]": [5]}
    three = {"bool": [True, None, False], "i32": [1, None, -3], "i64": [1, 0, None], "f32": [1.0, nan, None], "f64": [0.0, -1.5, None], "str": ["a", "b", None], "date": [4, 5, None], "datetime[μs]": [4, 5, None]}
    for op, x, y in [
        ("add", "i32", "i32"), ("add", "i32", "i64"), ("mul", "f32", "f32"), ("floordiv", "i64", "i64"),
        ("lt", "str", "str"), ("eq", "date", "date"), ("eq", "i32", "f64"), ("and", "bool", "bool"), ("or", "bool", "bool"),
    ]:
        for tag, (av, bv) in {
            "1x3": (one[x], three[y]),
            "3x1": (three[x], one[y]),
            "1x1": (one[x], one[y]),
        }.items():
            cases.append(binary_case(op, x, y, av, bv, False, label=f"broadcast/{op}/{x}x{y}/{tag}"))
    # empty operands
    for op, x, y in [("add", "i64", "i64"), ("eq", "str", "str"), ("and", "bool", "bool")]:
        for tag, (av, bv) in {
            "0x1": ([], one[y]),
            "1x0": (one[x], []),
            "0x0": ([], []),
        }.items():
            cases.append(binary_case(op, x, y, av, bv, False, label=f"empty/{op}/{x}x{y}/{tag}"))
    # a length that is neither equal nor 1: ShapeMismatch for every operator
    for op, x, y in [
        ("add", "i32", "i32"), ("mul", "f32", "f64"), ("floordiv", "i64", "i64"), ("eq", "i32", "i32"),
        ("lt", "str", "str"), ("and", "bool", "bool"), ("or", "bool", "bool"),
    ]:
        for tag, (av, bv) in {
            "2x3": (three[x][:2], three[y]),
            "3x2": (three[x], three[y][:2]),
            "0x2": ([], three[y][:2]),
        }.items():
            a = mk("a", x, av)
            b = mk("b", y, bv)
            g = EXPR[op]
            result, err = attempt(lambda: pl.select(g(pl.lit(a), pl.lit(b))).to_series())
            case = {
                "id": f"length/{op}/{x}x{y}/{tag}", "op": op,
                "a": ref(f"length/{op}/{x}x{y}/{tag}.a", a),
                "b": ref(f"length/{op}/{x}x{y}/{tag}.b", b),
                "polars": f"pl.select(pl.lit(s1) {SYMBOL[op]} pl.lit(s2))",
            }
            cases.append(finish(case, result, err))

    # ---- filter ------------------------------------------------------
    masks = {
        "mixed": [True, None, False, True],
        "all-true": [True, True, True, True],
        "all-null": [None, None, None, None],
    }
    for x in DTYPES:
        vals = (VALS[x] * 2)[:4]
        for tag, m in masks.items():
            s = mk("a", x, vals)
            mask = pl.Series("m", m, dtype=pl.Boolean)
            result, err = attempt(lambda: s.filter(mask))
            case = {"id": f"filter/{x}/{tag}", "op": "filter", "a": ref(f"filter/{x}/{tag}.a", s),
                    "mask": ref(f"filter/{x}/{tag}.mask", mask), "polars": "s1.filter(mask)"}
            cases.append(finish(case, result, err))
        # a length-1 mask broadcasts; a length-2 mask on 4 rows is an error
        for tag, m in {"len1-true": [True], "len1-false": [False], "len1-null": [None], "len2": [True, False]}.items():
            s = mk("a", x, vals)
            mask = pl.Series("m", m, dtype=pl.Boolean)
            result, err = attempt(lambda: s.filter(mask))
            case = {"id": f"filter/{x}/{tag}", "op": "filter", "a": ref(f"filter/{x}/{tag}.a", s),
                    "mask": ref(f"filter/{x}/{tag}.mask", mask), "polars": "s1.filter(mask)"}
            cases.append(finish(case, result, err))
        # empty series with an empty mask and a length-1 mask
        for tag, m in {"empty": [], "empty-len1": [True]}.items():
            s = mk("a", x, [])
            mask = pl.Series("m", m, dtype=pl.Boolean)
            result, err = attempt(lambda: s.filter(mask))
            case = {"id": f"filter/{x}/{tag}", "op": "filter", "a": ref(f"filter/{x}/{tag}.a", s),
                    "mask": ref(f"filter/{x}/{tag}.mask", mask), "polars": "s1.filter(mask)"}
            cases.append(finish(case, result, err))
    # a series of length 1 and a longer mask
    s = mk("a", "i32", [1])
    mask = pl.Series("m", [True, False], dtype=pl.Boolean)
    result, err = attempt(lambda: s.filter(mask))
    cases.append(finish({"id": "filter/i32/len1-series", "op": "filter", "a": ref("filter/i32/len1-series.a", s),
                         "mask": ref("filter/i32/len1-series.mask", mask), "polars": "s1.filter(mask)"}, result, err))

    ids = [c["id"] for c in cases]
    assert len(ids) == len(set(ids)), "duplicate case ids"
    emit("arith", {"cases": cases, "inputs": INPUTS}, compact=True)
    print(f"polars {pl.__version__}: wrote {len(cases)} cases")


main()
