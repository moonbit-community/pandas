"""Generates the Series sequence-operation golden data (docs/golden/sequence.json,
src/pl/golden_sequence_data_test.mbt): shift, diff, cum_sum / cum_min / cum_max /
cum_prod / cum_count, rank, reverse and fill_null(strategy=...).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/sequence.py

The file is `{"inputs": {label: series}, "cases": [...]}` (compact layout, see
`emit(compact=True)`). A case has `id`, `op`, `a` (a key of `inputs`), `polars`
(the Python spelling, `s1` is the input) and its parameters:

- `shift`: `n`, optional `fill` = `{"dtype", "value"}` (a strongly typed fill
  value, `pl.lit(value, dtype=...)`; `"dtype": "null"` is `pl.lit(None)`)
- `diff`: `n`
- `cum_sum`, `cum_min`, `cum_max`, `cum_prod`, `cum_count`: `reverse`
- `rank`: `method` (`average`, `min`, `max`, `dense`, `ordinal`), `descending`
- `reverse`: none
- `fill_null`: `strategy` and optional `limit` (Python int, may be negative)

and one of `result` (a series, mapped through `to_ours`; `polars_dtype` is
stored when the mapping changed the type), `error` + `message` (variant per the
M2 error mapping, first line of polars' message; Python's own `ValueError` /
`OverflowError` map to `InvalidOperation`, `pyerr` keeps the Python name), or
`restricted: true` + `polars_dtype` (polars succeeds with a type this library
does not have, a `Duration`: only `InvalidOperation` is required, see
known-diffs/sequence.md).

The `fill_null` cases never use an input whose integer mean does not fit
`Int64` (polars panics there).
"""
import datetime
import os
import sys
import warnings

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import polars as pl

from emit import emit, encode_series, polars_dtype, series_from_spec, to_ours

warnings.filterwarnings("ignore")

nan = float("nan")
inf = float("inf")
I32_MIN, I32_MAX = -2147483648, 2147483647
I64_MIN, I64_MAX = -9223372036854775808, 9223372036854775807

VARIANTS = {
    "ColumnNotFoundError": "ColumnNotFound",
    "DuplicateError": "DuplicateColumn",
    "SchemaError": "SchemaMismatch",
    "ShapeError": "ShapeMismatch",
    "OutOfBoundsError": "OutOfBounds",
    "InvalidOperationError": "InvalidOperation",
    "ComputeError": "ComputeError",
    # no variant for Python's own errors: the library uses InvalidOperation
    "ValueError": "InvalidOperation",
    "OverflowError": "InvalidOperation",
}

DTYPES = ["bool", "i32", "i64", "f32", "f64", "str", "date", "datetime[μs]", "null"]
FOCUS_STR = ["｡", "\U0001F600", "a", "", "Z"]  # Review Focus 1
FOCUS_FLOAT = [1.0, nan, None, -inf, -0.0, 0.0]  # Review Focus 2

# label -> values, per dtype. The first input of a dtype is its "main" one:
# every parameter combination runs on it; the others get a reduced grid.
VALS = {
    "bool": {
        "plain": [True, False, None, True, False, None, False],
        "allnull": [None, None],
        "empty": [],
        "one": [True],
    },
    "i32": {
        "plain": [3, -1, None, 0, 3, I32_MIN, I32_MAX, None, 0, 1, -1],
        "ovf": [I32_MAX, 1, None, I32_MIN, I32_MIN],
        "prod": [2**20, 2**20, 2**20, None, 3],
        "ties": [3, 1, None, 3, 2, 1, None, 5],
        "allnull": [None, None],
        "empty": [],
        "one": [7],
    },
    "i64": {
        "plain": [3, -1, None, 0, 3, I64_MIN, I64_MAX, None, 0, 1, -1],
        "ovf": [I64_MAX, 1, None, -I64_MAX, -I64_MAX, -5],
        "prod": [2**32, 2**32, 3, None],
        "ties": [3, 1, None, 3, 2, 1, None, 5],
        "allnull": [None, None],
        "empty": [],
        "one": [7],
    },
    "f32": {
        "plain": [1.0, nan, None, -inf, -0.0, 0.0, inf, 1.0, nan, 0.1, 3.0e38],
        "focus": FOCUS_FLOAT,
        "nofocus": [3.0, None, 1.0, -0.0, 0.0, 2.0],
        "allnull": [None, None],
        "empty": [],
    },
    "f64": {
        "focus": FOCUS_FLOAT,
        "special": [1.0, nan, None, -inf, -0.0, 0.0, inf, 2.0, nan, 0.0],
        "nan_first": [nan, 1.0, 2.0],
        "nan_first2": [nan, nan, 1.0],
        "nan_mid": [None, nan, 2.0, nan, 1.0],
        "nofocus": [3.0, None, 1.0, -0.0, 0.0, 2.0],
        "zeros": [-0.0, 0.0, -0.0],
        "zeros2": [0.0, -0.0, 0.0],
        "one_nan": [nan],
        "allnan": [nan, nan],
        "big": [1e308, 1e308, None, -1e308],
        "allnull": [None, None],
        "empty": [],
    },
    "str": {
        "focus": FOCUS_STR,
        "plain": ["b", "a", None, "a", "｡", "\U0001F600", "", "￿", None],
        "allnull": [None, None],
        "empty": [],
        "one": ["x"],
    },
    "date": {
        "plain": [0, 5, None, 7, 5, -25567, None, 19782],
        "allnull": [None, None],
        "empty": [],
    },
    "datetime[μs]": {
        "plain": [0, 5, None, 7, 5, -86400000000, None, 1709210096123456],
        "allnull": [None, None],
        "empty": [],
    },
    "null": {
        "three": [None, None, None],
        "empty": [],
    },
}

# dtype -> list of inputs with the full parameter grid
MAIN = {
    "bool": ["plain"], "i32": ["plain", "ovf"], "i64": ["plain", "ovf"],
    "f32": ["plain"], "f64": ["focus", "special", "nan_first", "nan_mid"],
    "str": ["focus", "plain"], "date": ["plain"], "datetime[μs]": ["plain"],
    "null": ["three"],
}

# inputs with the full rank grid (5 methods x 2 directions)
RANK_FULL = {
    "bool": ["plain"], "i32": ["ties"], "i64": ["ties", "plain"], "f32": ["plain"],
    "f64": ["focus", "special", "nan_first"], "str": ["focus", "plain"], "date": ["plain"],
    "datetime[μs]": ["plain"], "null": ["three"],
}

# fill values of shift: dtype -> value (python / encoded)
FILL_VALUES = {
    "bool": True,
    "i32": 7,
    "i64": 3000000000,
    "f32": 1.5,
    "f64": 2.25,
    "str": "x",
    "date": 100,
    "datetime[μs]": 5,
    "null": None,
}

STRATEGIES = ["forward", "backward", "min", "max", "mean", "zero", "one"]
RANK_METHODS = ["average", "min", "max", "dense", "ordinal"]

# fill_null inputs with long runs of nulls (the limit grid)
FILL_RUNS = [None, 1, None, None, 3, None, None, None, 4, None]
FILL_EXTRA = {
    "i64": {
        "runs": FILL_RUNS,
        "mean_neg": [None, -1, -2, -4],
        "mean_neg2": [None, -1, -2],
        "mean_big": [None, 2**62 + 1, 2**62 + 3],
        "mean_min": [None, I64_MIN, I64_MIN + 1],
        "nonull": [1, 2, 3],
    },
    "i32": {"runs": FILL_RUNS, "mean_neg": [None, -1, -2], "mean_big": [None, I32_MAX, I32_MAX - 1]},
    "f64": {"runs": [None, 1.5, None, None, nan, None, None, -inf, None], "mean": [None, 1.0, 2.0, None]},
    "f32": {"runs": [None, 2.5, None, None, 1.0, None], "mean": [None, 1.5, 2.5, None]},
    "bool": {"runs": [None, True, None, None, False, None]},
    "str": {"runs": [None, "b", None, None, "a", None]},
    "date": {"runs": FILL_RUNS, "mean_neg": [None, -3, -2], "mean_odd": [None, 3, 4, 4]},
    "datetime[μs]": {"runs": FILL_RUNS, "mean_neg": [None, -3, -2], "mean_odd": [None, 3, 4, 4]},
}


def error_of(e):
    name = type(e).__name__
    return VARIANTS.get(name, name), str(e).split("\n")[0], name


def attempt(f):
    try:
        return f(), None
    except BaseException as e:  # noqa: BLE001 (polars panics are BaseException)
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        return None, error_of(e)


INPUTS = {}
CASES = []


def mk(dtype, values, name="a"):
    return series_from_spec(name, dtype, values)


def add_input(label, dtype, values):
    key = f"{dtype}/{label}"
    if key not in INPUTS:
        INPUTS[key] = encode_series(mk(dtype, values))
    return key


def finish(case, result, err):
    if err is not None:
        case["error"], case["message"], pyerr = err
        if pyerr in ("ValueError", "OverflowError"):
            case["pyerr"] = pyerr
        return case
    if result.dtype == pl.Duration or isinstance(result.dtype, pl.Duration):
        case["restricted"] = True
        case["polars_dtype"] = str(result.dtype)
        return case
    ours, original = to_ours(result)
    case["result"] = encode_series(ours)
    if ours.dtype != result.dtype:
        case["polars_dtype"] = original
    return case


def py_bool(b):
    return "True" if b else "False"


def run(cid, op, key, a, call, spelling, **params):
    result, err = attempt(call)
    case = {"id": cid, "op": op, "a": key, "polars": spelling}
    case.update(params)
    CASES.append(finish(case, result, err))


EPOCH_DATE = datetime.date(1970, 1, 1)
EPOCH_DT = datetime.datetime(1970, 1, 1)


def fill_expr(dtype, value):
    """`(polars fill_value, python spelling, JSON form)` of a strongly typed fill."""
    enc = encode_series(mk(dtype, [value]))["values"][0]
    js = {"dtype": dtype, "value": enc}
    pl_dtype = {"bool": "pl.Boolean", "i32": "pl.Int32", "i64": "pl.Int64", "f32": "pl.Float32",
                "f64": "pl.Float64", "str": "pl.String", "date": "pl.Date",
                "datetime[μs]": "pl.Datetime('us')"}
    if dtype == "null":
        return pl.lit(None), "pl.lit(None)", js
    if dtype == "date":
        py = EPOCH_DATE + datetime.timedelta(days=value)
        text = f"datetime.date(1970, 1, 1) + datetime.timedelta(days={value})"
    elif dtype == "datetime[μs]":
        py = EPOCH_DT + datetime.timedelta(microseconds=value)
        text = f"datetime.datetime(1970, 1, 1) + datetime.timedelta(microseconds={value})"
    else:
        py = value
        text = repr(value)
    return pl.lit(py, dtype=polars_dtype(dtype)), f"pl.lit({text}, dtype={pl_dtype[dtype]})", js


def shift_cases(key, a, full):
    ns = (-4, -1, 0, 1, 2, 10) if full else (-1, 2)
    for n in ns:
        run(f"shift/{key}/{n}", "shift", key, a, lambda: a.shift(n), f"s1.shift({n})", n=n)


def diff_cases(key, a, full):
    ns = (-4, -1, 0, 1, 2, 10) if full else (1,)
    for n in ns:
        run(f"diff/{key}/{n}", "diff", key, a, lambda: a.diff(n), f"s1.diff({n})", n=n)


def cum_cases(key, a, full):
    for op in ("cum_sum", "cum_min", "cum_max", "cum_prod", "cum_count"):
        for rev in (False, True) if full else (False,):
            run(
                f"{op}/{key}/r{int(rev)}", op, key, a,
                lambda: getattr(a, op)(reverse=rev),
                f"s1.{op}(reverse={py_bool(rev)})", reverse=rev,
            )


def rank_cases(key, a, full):
    for m in RANK_METHODS if full else ("average", "dense"):
        for d in (False, True) if full else (False,):
            run(
                f"rank/{key}/{m}/d{int(d)}", "rank", key, a,
                lambda: a.rank(method=m, descending=d),
                f"s1.rank(method='{m}', descending={py_bool(d)})",
                method=m, descending=d,
            )


def reverse_case(key, a):
    run(f"reverse/{key}", "reverse", key, a, lambda: a.reverse(), "s1.reverse()")


def fill_cases(key, a, full=True):
    for st in STRATEGIES:
        if st in ("forward", "backward"):
            limits = [None, 0, 1, 2, 5, -1] if full else [None]
        else:
            limits = [None, 1] if full else [None]
        for lim in limits:
            tag = "none" if lim is None else str(lim)
            kw = "" if lim is None else f", limit={lim}"
            params = {"strategy": st}
            if lim is not None:
                params["limit"] = lim
            run(
                f"fill_null/{key}/{st}/{tag}", "fill_null", key, a,
                lambda: a.fill_null(strategy=st, limit=lim),
                f"s1.fill_null(strategy='{st}'{kw})", **params,
            )


def build():
    for dtype in DTYPES:
        for label, values in VALS[dtype].items():
            key = add_input(label, dtype, values)
            a = mk(dtype, values)
            full = label in MAIN[dtype]
            shift_cases(key, a, full)
            diff_cases(key, a, full)
            cum_cases(key, a, full)
            rank_cases(key, a, label in RANK_FULL[dtype])
            reverse_case(key, a)
            fill_cases(key, a, full=False)
    # fill_null: inputs with runs of nulls (all strategies and limits)
    for dtype, extra in FILL_EXTRA.items():
        for label, values in extra.items():
            key = add_input(label, dtype, values)
            a = mk(dtype, values)
            fill_cases(key, a, full=label.startswith("runs"))
    # the all-null / empty inputs get the whole limit grid too (cheap)
    # shift with a strongly typed fill value: every dtype of the series x every
    # dtype of the fill value
    for dtype in DTYPES:
        base = {"bool": [True, None, False], "i32": [1, None, 3], "i64": [1, None, 3],
                "f32": [1.5, None, 3.0], "f64": [1.5, None, 3.0], "str": ["a", None, "c"],
                "date": [1, None, 3], "datetime[μs]": [1, None, 3], "null": [None, None, None]}[dtype]
        key = add_input("fillbase", dtype, base)
        a = mk(dtype, base)
        for fdtype in DTYPES:
            if dtype == "null" and fdtype == "null":
                # polars refuses an explicit null fill on a null series
                # (`shift_and_fill`); the library cannot tell it from no fill
                continue
            value = FILL_VALUES[fdtype]
            fv, spelling, js = fill_expr(fdtype, value)
            for n in ((1, -2, 10) if dtype == fdtype else (1, -2)):
                run(
                    f"shift_fill/{dtype}/{fdtype}/{n}", "shift", key, a,
                    lambda: a.shift(n, fill_value=fv),
                    f"s1.shift({n}, fill_value={spelling})", n=n, fill=js,
                )
    # fill values with special content, on a float and a string series
    f = add_input("fillbase", "f64", [1.5, None, 3.0])
    fa = mk("f64", [1.5, None, 3.0])
    for label, fdtype, value in (("nan", "f64", nan), ("neg0", "f64", -0.0), ("inf", "f64", inf)):
        fv, spelling, js = fill_expr(fdtype, value)
        run(f"shift_fill/f64/{label}", "shift", f, fa, lambda: fa.shift(1, fill_value=fv),
            f"s1.shift(1, fill_value={spelling})", n=1, fill=js)
    s = add_input("fillbase", "str", ["a", None, "c"])
    sa = mk("str", ["a", None, "c"])
    for label, value in (("emoji", "\U0001F600"), ("empty", ""), ("fullwidth", "｡")):
        fv, spelling, js = fill_expr("str", value)
        run(f"shift_fill/str/{label}", "shift", s, sa, lambda: sa.shift(1, fill_value=fv),
            f"s1.shift(1, fill_value={spelling})", n=1, fill=js)
    # shift and diff with n at the edge of Int32 (no overflow in n - i)
    i = add_input("plain", "i64", VALS["i64"]["plain"])
    ia = mk("i64", VALS["i64"]["plain"])
    for n in (I32_MIN, I32_MAX):
        run(f"shift/i64/plain/{n}", "shift", i, ia, lambda: ia.shift(n), f"s1.shift({n})", n=n)
        run(f"diff/i64/plain/{n}", "diff", i, ia, lambda: ia.diff(n), f"s1.diff({n})", n=n)


build()
ids = [c["id"] for c in CASES]
assert len(ids) == len(set(ids)), "duplicate case ids"
emit("sequence", {"inputs": INPUTS, "cases": CASES}, compact=True)
print(f"{len(CASES)} cases, {len(INPUTS)} inputs")
