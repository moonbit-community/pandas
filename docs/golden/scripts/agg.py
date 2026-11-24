"""Generates the Series aggregation golden data (docs/golden/agg.json,
src/pl/golden_agg_data_test.mbt).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/agg.py

The file is `{"inputs": {key: series}, "cases": [...]}` (compact layout, see
`emit(compact=True)`). Every case has `id`, `op`, `a` (a key of `inputs`),
`polars` (the Python spelling), optional parameters (`ddof`; `q` as the
Python `repr` of a float, so `nan` and `inf` fit; `method`)
and either `dtype` + `value` (the result, mapped to the library's types through
`to_ours`; `value` is the `emit.encode_value` text or JSON null) or `error` +
`message` (variant per the M2 error mapping, first line of polars' message).

Results are taken from the expression engine (`pl.select(pl.lit(s).sum())`)
so that the result dtype of a null result is known too. `polars_dtype` is
stored only when `to_ours` mapped the type (`UInt32` -> `i64`).
"""
import os
import random
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import polars as pl

from emit import emit, encode_series, series_from_spec, to_ours

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
}

FOCUS_STR = ["｡", "\U0001F600", "a", "", "Z"]  # Review Focus 1
FOCUS_FLOAT = [1.0, nan, None, -inf, -0.0, 0.0]  # Review Focus 2

# name -> values per dtype. `full` marks the inputs that get the whole
# quantile grid (6 q x 6 methods); the others get one quantile case.
VALS = {
    "bool": {
        "plain": [True, False, True],
        "nulls": [True, None, False],
        "allnull": [None, None],
        "empty": [],
        "one": [True],
        "alltrue": [True, True],
        "allfalse": [False, False, None],
    },
    "i32": {
        "plain": [3, 1, 4, 1, 5, 9, 2, 6],
        "nulls": [3, None, 1, None, 5],
        "allnull": [None, None],
        "empty": [],
        "one": [7],
        "ovf": [I32_MAX, 1],  # sum wraps
        "bounds": [I32_MIN, I32_MAX, -1, 0, None],
        "prod": [I32_MAX, I32_MAX, 2],  # product is i64, does not wrap
        "neg": [-5, -4, -3, -2],
    },
    "i64": {
        "plain": [3, 1, 4, 1, 5, 9, 2, 6],
        "nulls": [3, None, 1, None, 5],
        "allnull": [None, None],
        "empty": [],
        "one": [7],
        "ovf": [I64_MAX, 1],  # sum wraps
        "bounds": [I64_MIN, I64_MAX, -1, 0, None],
        "prod": [4294967296, 4294967296],  # product wraps to 0
        "neg": [-5, -4, -3, -2],
    },
    "f32": {
        "plain": [1.5, 2.25, -0.5, 4.0, 8.0],
        "nulls": [0.5, None, 2.0, None, 1.0],
        "allnull": [None, None],
        "empty": [],
        "one": [0.1],
        "special": FOCUS_FLOAT,
        "inf": [1.0, inf, 2.0],
        "infs": [1.0, inf, -inf],
        "allnan": [nan, nan],
        "big": [3.0e38, 3.0e38, -3.0e38],
        "zeros": [-0.0, 0.0],
        "zeros2": [0.0, -0.0],
        "one_inf": [inf],
        "one_nan": [nan],
    },
    "f64": {
        "plain": [1.5, 2.25, -0.5, 4.0, 8.0],
        "nulls": [0.5, None, 2.0, None, 1.0],
        "allnull": [None, None],
        "empty": [],
        "one": [0.1],
        "special": FOCUS_FLOAT,
        "inf": [1.0, inf, 2.0],
        "infs": [1.0, inf, -inf],
        "allnan": [nan, nan],
        "big": [1e308, 1e308, -1e308],
        "huge": [1e200, -1e200],  # var overflows to inf
        "equal_inf": [inf, inf],  # linear quantile of equal infinities is inf
        "equal_ninf": [-inf, -inf, -inf, -inf],
        "big2": [1e308, 1e308],  # polars' var is NaN here, see known-diffs
        "zeros": [-0.0, 0.0],
        "zeros2": [0.0, -0.0],
        "one_inf": [inf],
        "one_nan": [nan],
        "close": [1e9 + 1, 1e9 + 2, 1e9 + 3],
    },
    "str": {
        "plain": ["b", "a", "c", "a"],
        "nulls": ["b", None, "a"],
        "allnull": [None, None],
        "empty": [],
        "one": ["x"],
        "focus": FOCUS_STR,
        "focus_null": FOCUS_STR + [None],
    },
    "date": {
        "plain": [0, 5, 19782, -25567],
        "nulls": [0, None, 5, None, 4],
        "allnull": [None, None],
        "empty": [],
        "one": [5],
        "neg": [-3, -2],
        "odd": [1, 2, 4],
    },
    "datetime[μs]": {
        "plain": [0, 5, 1709210096123456, 86399999999],
        "nulls": [0, None, 5, None, 4],
        "allnull": [None, None],
        "empty": [],
        "one": [5],
        "neg": [-3, -2],
        "odd": [1, 2, 4],
    },
    "null": {
        "empty": [],
        "three": [None, None, None],
    },
}

# Seeded random inputs: magnitudes from 1 to 1e15, about one value in five
# null. `rand` (25 values) gets the whole quantile grid, the long `pw*` ones
# (more than 128 values, so the pairwise sums of polars have blocks and a
# leading remainder) the other aggregations.
_R = random.Random(20261123)


def _f32(x):
    return struct.unpack("f", struct.pack("f", x))[0]


def _rand_vals(n, make, null_p=0.2):
    return [None if _R.random() < null_p else make() for _ in range(n)]


def _mix(f32=False):
    def make():
        v = _R.choice([1, 1e3, 1e9, 1e15]) * _R.uniform(-1, 1)
        return _f32(v) if f32 else v
    return make


for _d, _mk in {
    "f64": _mix(),
    "f32": _mix(True),
    "i64": lambda: _R.randint(-10**15, 10**15),
    "i32": lambda: _R.randint(-10**9, 10**9),
    "date": lambda: _R.randint(-30000, 60000),
    "datetime[μs]": lambda: _R.randint(-10**15, 10**15),
}.items():
    VALS[_d]["rand"] = _rand_vals(25, _mk)
for _d, _n in (("f64", 400), ("f32", 300), ("i64", 300), ("date", 300), ("datetime[μs]", 300)):
    VALS[_d]["pw"] = _rand_vals(_n, {"f64": _mix(), "f32": _mix(True), "i64": lambda: _R.randint(-10**15, 10**15),
                                     "date": lambda: _R.randint(-30000, 60000),
                                     "datetime[μs]": lambda: _R.randint(-10**15, 10**15)}[_d])
# 1e9 + i * 0.001: sum and mean are checked against polars; polars' own
# variance is only good to about 1e-7 here, so std / var are left out
VALS["f64"]["offset"] = [1e9 + i * 0.001 for i in range(300)]
# no nulls, n values around the pairwise block of 128: the sum of 128 random
# floats differs in the last bits between a block threshold of `n < 128` and
# `n <= 128` (see agg_golden_test.mbt)
_P = random.Random(1)
for _n in (127, 128, 129, 257):
    VALS["f64"][f"blk{_n}"] = [_P.random() for _ in range(_n)]
NO_VAR = {("f64", "big"), ("f64", "big2"), ("f64", "offset")}
# inputs that get the whole quantile grid, per dtype
FULL_Q = {
    "i32": ("plain", "nulls", "bounds"),
    "i64": ("plain", "nulls", "bounds", "rand"),
    "f32": ("plain", "nulls", "special", "rand"),
    "f64": ("plain", "nulls", "special", "rand", "zeros", "zeros2", "equal_inf"),
    "date": ("plain", "nulls", "neg", "rand"),
    "datetime[μs]": ("plain", "nulls", "neg", "rand"),
}
# dtypes `quantile` is defined for (bool, str and null are errors in polars)
Q_DTYPES = tuple(FULL_Q)

QS = [0, 0.1, 0.25, 0.5, 0.9, 1]
METHODS = ["nearest", "higher", "lower", "midpoint", "linear", "equiprobable"]
DDOFS = [0, 1, 5]
BAD_Q = [-0.1, 1.5, 2.0, nan, inf]

INPUTS = {}


def ref(label, series):
    """Key of `series` in `INPUTS` (`i0`, `i1`, ...), stored once with the
    label of the first case that used it (`for`)."""
    enc = encode_series(series)
    for key, value in INPUTS.items():
        if {k: v for k, v in value.items() if k != "for"} == enc:
            return key
    key = f"i{len(INPUTS)}"
    INPUTS[key] = dict(enc, **{"for": label})
    return key


def error_of(e):
    name = type(e).__name__
    return VARIANTS.get(name, name), str(e).split("\n")[0]


def attempt(f):
    try:
        return f(), None
    except Exception as e:  # noqa: BLE001
        return None, error_of(e)
    except BaseException as e:  # noqa: BLE001 - polars panics
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        return None, error_of(e)


def fmt(v):
    return repr(v)


def make_case(cid, op, dname, vname, text, fexpr, **params):
    s = series_from_spec("a", dname, VALS[dname][vname])
    case = {"id": cid, "op": op, "a": ref(f"{dname}/{vname}", s), "polars": f"pl.lit(s).{text}"}
    case.update(params)
    result, err = attempt(lambda: pl.select(fexpr(pl.lit(s))).to_series())
    if err is not None:
        case["error"], case["message"] = err
        return case
    ours, original = to_ours(result)
    enc = encode_series(ours)
    case["dtype"] = enc["dtype"]
    case["value"] = enc["values"][0]
    if ours.dtype != result.dtype:
        case["polars_dtype"] = original
    return case


def main():
    cases = []
    simple = {
        "sum": lambda e: e.sum(),
        "mean": lambda e: e.mean(),
        "min": lambda e: e.min(),
        "max": lambda e: e.max(),
        "first": lambda e: e.first(),
        "last": lambda e: e.last(),
        "median": lambda e: e.median(),
        "product": lambda e: e.product(),
        "count": lambda e: e.count(),
        "len": lambda e: e.len(),
    }
    for d, sets in VALS.items():
        for v in sets:
            for op, f in simple.items():
                cases.append(make_case(f"{op}/{d}/{v}", op, d, v, f"{op}()", f))
            # polars' var of [1e308, 1e308, -1e308] is NaN (our -inf): see
            # known-diffs/agg.md; every other overflow agrees
            for ddof in () if (d, v) in NO_VAR else (DDOFS if v not in ("rand", "pw", "offset") and not v.startswith("blk") else (1,)):
                cases.append(make_case(
                    f"std/{d}/{v}/{ddof}", "std", d, v, f"std(ddof={ddof})",
                    lambda e, ddof=ddof: e.std(ddof=ddof), ddof=ddof))
                cases.append(make_case(
                    f"var/{d}/{v}/{ddof}", "var", d, v, f"var(ddof={ddof})",
                    lambda e, ddof=ddof: e.var(ddof=ddof), ddof=ddof))
            full = v in FULL_Q.get(d, ())
            if full:
                for m in METHODS:
                    for q in (QS if v not in ("zeros", "zeros2", "equal_inf") else (0.1, 0.5, 1)):
                        cases.append(make_case(
                            f"quantile/{d}/{v}/{m}/{q}", "quantile", d, v,
                            f"quantile({fmt(q)}, '{m}')",
                            lambda e, q=q, m=m: e.quantile(q, interpolation=m),
                            q=repr(float(q)), method=m))
            elif d == "date" and v in ("empty", "allnull"):
                continue  # polars panics (Option::unwrap on None), see known-diffs/agg.md
            else:
                cases.append(make_case(
                    f"quantile/{d}/{v}/nearest/0.5", "quantile", d, v,
                    "quantile(0.5, 'nearest')",
                    lambda e: e.quantile(0.5, interpolation="nearest"),
                    q="0.5", method="nearest"))
    # invalid q: ComputeError for every type quantile is defined for, the
    # type error first for bool / str / null; nan is encoded as the text "nan"
    for d in VALS:
        v = "plain" if "plain" in VALS[d] else "three"
        for q in BAD_Q:
            m = "linear"
            cases.append(make_case(
                f"quantile_bad/{d}/{v}/{q}", "quantile", d, v,
                f"quantile({fmt(q)}, 'linear')",
                lambda e, q=q: e.quantile(q, interpolation="linear"),
                q=repr(float(q)), method=m))
    # empty series with an invalid q (not for date / datetime: polars panics)
    for d in ("i32", "f64"):
        cases.append(make_case(
            f"quantile_bad/{d}/empty/1.5", "quantile", d, "empty", "quantile(1.5, 'linear')",
            lambda e: e.quantile(1.5, interpolation="linear"), q=repr(1.5), method="linear"))
    emit("agg", {"inputs": INPUTS, "cases": cases}, compact=True)
    print(len(cases), "cases,", len(INPUTS), "inputs")


main()
