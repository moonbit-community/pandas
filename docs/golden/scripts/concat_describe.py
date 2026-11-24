"""Generates the concat / stacking / `describe` golden data
(docs/golden/concat_describe.json, src/pl/golden_concat_describe_data_test.mbt).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/concat_describe.py

The file is `{"cases": [...], "inputs": {key: frame | series}}` (compact
layout, see `emit(compact=True)`). An input is a frame `{"columns": [series]}`
(key starts with `f.`) or a series (key starts with `s.`); a case refers to
them by key. Every case has `id`, `op`, `polars` (the Python spelling) and
either `result` (a frame, or for `append` a series) or `error` + `message`
(variant per the M2 error mapping, first line of polars' message; `polars_error`
is the polars class when the library uses another variant: `ValueError` and
`TypeError` map to `InvalidOperation`).

Operations and their fields:
  concat      `frames` (keys), `how` (vertical, vertical_relaxed, horizontal,
              diagonal)
  vstack      `a`, `b` (frame keys)
  hstack      `a` (frame key), `columns` (series keys)
  append      `a`, `b` (series keys)
  to_frame    `a` (series key)
  describe    `a` (frame key), `percentiles` (list of Python float `repr`
              strings; absent for the default), `interpolation` (default
              nearest)

`describe` is a Python function in polars 2.1.0 (`LazyFrame.describe`): count
and null_count of numeric, Boolean and Null columns are floats and of the
other columns strings; the values of String, Date and Datetime columns are
`str()` of the Python value (datetimes print the fraction only when it is not
zero). See docs/golden/known-diffs/concat_describe.md.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# polars merges the chunks of `describe` (mean, std) and of a `concat` of three
# or more tables by the size of its thread pool, so a few values depend on the
# machine. The pool is pinned before polars is imported: the committed data
# is the result with 4 threads.
os.environ["POLARS_MAX_THREADS"] = "4"

import polars as pl

from emit import DTYPE_NAMES, emit, encode_series, series_from_spec

nan = float("nan")
inf = float("inf")
I64_MIN = -9223372036854775808
I64_MAX = 9223372036854775807

VARIANTS = {
    "ColumnNotFoundError": "ColumnNotFound",
    "DuplicateError": "DuplicateColumn",
    "SchemaError": "SchemaMismatch",
    "ShapeError": "ShapeMismatch",
    "OutOfBoundsError": "OutOfBounds",
    "InvalidOperationError": "InvalidOperation",
    "ComputeError": "ComputeError",
    # Python exceptions without a library variant
    "ValueError": "InvalidOperation",
    "TypeError": "InvalidOperation",
}

DTYPES = list(DTYPE_NAMES)  # bool i32 i64 f32 f64 str date datetime[μs] null
SHORT = {"bool": "bool", "i32": "i32", "i64": "i64", "f32": "f32", "f64": "f64",
         "str": "str", "date": "date", "datetime[μs]": "dt", "null": "null"}

INPUTS = {}
FR = {}
SE = {}


def mk(name, dtype, values):
    return series_from_spec(name, dtype, values)


def frame(key, df):
    """Register a polars DataFrame under `f.<key>`; returns the key."""
    k = "f." + key
    INPUTS[k] = {"columns": [encode_series(s) for s in df.get_columns()]}
    FR[k] = df
    return k


def series(key, s):
    k = "s." + key
    INPUTS[k] = encode_series(s)
    SE[k] = s
    return k


def attempt(f):
    try:
        return f(), None
    except BaseException as e:  # polars panics are BaseException
        return None, e


def encode_result(r):
    if isinstance(r, pl.DataFrame):
        return {"columns": [encode_series(s) for s in r.get_columns()]}
    return encode_series(r)


def finish(case, result, err):
    if err is not None:
        name = type(err).__name__
        case["error"] = VARIANTS[name]
        if name in ("ValueError", "TypeError"):
            case["polars_error"] = name
        case["message"] = str(err).splitlines()[0]
    else:
        case["result"] = encode_result(result)
    return case


def fl(v):
    return repr(float(v))


# ---------------------------------------------------------------------------
# Inputs for concat
# ---------------------------------------------------------------------------
cases = []

ab1 = frame("ab1", pl.DataFrame([mk("a", "i64", [1, 2, None]), mk("b", "str", ["x", None, "z"])]))
ab2 = frame("ab2", pl.DataFrame([mk("a", "i64", [4]), mk("b", "str", ["w"])]))
ab3 = frame("ab3", pl.DataFrame([mk("a", "i64", [-1, I64_MAX]), mk("b", "str", ["｡", "\U0001F600"])]))
ab0 = frame("ab0", pl.DataFrame([mk("a", "i64", []), mk("b", "str", [])]))
ba = frame("ba", pl.DataFrame([mk("b", "str", ["q"]), mk("a", "i64", [9])]))
aq = frame("aq", pl.DataFrame([mk("q", "i64", [7]), mk("b", "str", ["r"])]))
qb0 = frame("qb0", pl.DataFrame([mk("q", "i64", []), mk("b", "str", [])]))
a_only = frame("a_only", pl.DataFrame([mk("a", "i64", [5])]))
abc = frame("abc", pl.DataFrame([mk("a", "i64", [1]), mk("b", "str", ["m"]), mk("c", "f64", [1.5])]))
bc = frame("bc", pl.DataFrame([mk("b", "str", ["n"]), mk("c", "f64", [2.5])]))
cd = frame("cd", pl.DataFrame([mk("c", "date", [19782]), mk("d", "bool", [True])]))
d_only = frame("d_only", pl.DataFrame([mk("d", "datetime[μs]", [86399999999, None])]))
ab_i32 = frame("ab_i32", pl.DataFrame([mk("a", "i32", [3]), mk("b", "str", ["i"])]))
ab_f64 = frame("ab_f64", pl.DataFrame([mk("a", "f64", [1.5]), mk("b", "str", ["f"])]))
ab_str = frame("ab_str", pl.DataFrame([mk("a", "str", ["s"]), mk("b", "str", ["t"])]))
ab_null = frame("ab_null", pl.DataFrame([mk("a", "null", [None, None]), mk("b", "null", [None, None])]))
ab_null1 = frame("ab_null1", pl.DataFrame([mk("a", "null", [None]), mk("b", "null", [None])]))
a_null = frame("a_null", pl.DataFrame([mk("a", "null", [None])]))
a_i64 = frame("a_i64", pl.DataFrame([mk("a", "i64", [8, None])]))
a_f64 = frame("a_f64", pl.DataFrame([mk("a", "f64", [0.5])]))
a_i32 = frame("a_i32", pl.DataFrame([mk("a", "i32", [6])]))
a_f32 = frame("a_f32", pl.DataFrame([mk("a", "f32", [1.5])]))
a_bool = frame("a_bool", pl.DataFrame([mk("a", "bool", [True])]))
a_date = frame("a_date", pl.DataFrame([mk("a", "date", [19000, None])]))
a_dt = frame("a_dt", pl.DataFrame([mk("a", "datetime[μs]", [5])]))
a_str = frame("a_str", pl.DataFrame([mk("a", "str", ["s", None])]))
a0_str = frame("a0_str", pl.DataFrame([mk("a", "str", [])]))
xy_bool = frame("xy_bool", pl.DataFrame([mk("x", "bool", [True]), mk("y", "bool", [False])]))
xz_date = frame("xz_date", pl.DataFrame([mk("x", "date", [19000]), mk("z", "bool", [True])]))
zy_date = frame("zy_date", pl.DataFrame([mk("z", "bool", [True]), mk("y", "date", [19000])]))
x_bool = frame("x_bool1", pl.DataFrame([mk("x", "bool", [True])]))
x_i32 = frame("x_i32_1", pl.DataFrame([mk("x", "i32", [1])]))
x_f32 = frame("x_f32_1", pl.DataFrame([mk("x", "f32", [1.5])]))
x_i64 = frame("x_i64_1", pl.DataFrame([mk("x", "i64", [1])]))
x_date1 = frame("x_date1", pl.DataFrame([mk("x", "date", [19000])]))
x_dt1 = frame("x_dt1", pl.DataFrame([mk("x", "datetime[μs]", [5])]))
x_str1 = frame("x_str1", pl.DataFrame([mk("x", "str", ["s"])]))
y_bool = frame("y_bool", pl.DataFrame([mk("y", "bool", [True])]))
x_null = frame("x_null1", pl.DataFrame([mk("x", "null", [None])]))
y_str = frame("y_str", pl.DataFrame([mk("y", "str", ["s"])]))
z0 = frame("z0", pl.DataFrame())
h2 = frame("h2", pl.DataFrame([mk("c", "i64", [5, 6])]))
h2d = frame("h2d", pl.DataFrame([mk("d", "f64", [0.5, None])]))
h2a = frame("h2a", pl.DataFrame([mk("a", "i64", [5, 6])]))
h3 = frame("h3", pl.DataFrame([mk("c", "i64", [5, 6, 7])]))
h1 = frame("h1", pl.DataFrame([mk("c", "i64", [5])]))
h0 = frame("h0", pl.DataFrame([mk("c", "null", [])]))
h2ab = frame("h2ab", pl.DataFrame([mk("a", "i64", [1, 2]), mk("b", "str", ["x", "y"])]))
h2cd = frame("h2cd", pl.DataFrame([mk("c", "i64", [1, 2]), mk("d", "i64", [3, 4])]))
h2dc = frame("h2dc", pl.DataFrame([mk("d", "i64", [1, 2]), mk("c", "i64", [3, 4])]))
h1z = frame("h1z", pl.DataFrame([mk("z", "i64", [1])]))
h1c = frame("h1c", pl.DataFrame([mk("c", "i64", [1])]))
e_x = frame("e_x", pl.DataFrame([mk("x", "null", [])]))
e_y = frame("e_y", pl.DataFrame([mk("y", "null", [])]))
d0 = frame("d0", pl.DataFrame([mk("c", "date", [])]))

# one column "x" of every dtype
X = {}
XVALS = {
    "bool": [True, None, False],
    "i32": [1, None, -2147483648],
    "i64": [1, None, I64_MAX],
    "f32": [0.5, nan, None, -0.0],
    "f64": [1.5, nan, None, -0.0],
    "str": ["a", None, "｡", "\U0001F600"],
    "date": [0, None, -25567, 19782],
    "datetime[μs]": [0, None, -1, 1709210096123456],
    "null": [None, None],
}
for dt in DTYPES:
    X[dt] = frame("x_" + SHORT[dt], pl.DataFrame([mk("x", dt, XVALS[dt])]))
X0 = {dt: frame("x0_" + SHORT[dt], pl.DataFrame([mk("x", dt, [])])) for dt in DTYPES}


def add_concat(cid, keys, how, spelling=None):
    dfs = [FR[k] for k in keys]
    result, err = attempt(lambda: pl.concat(dfs, how=how))
    names = ", ".join(k[2:] for k in keys)
    cases.append(finish({
        "id": f"concat/{how}/{cid}", "op": "concat", "how": how, "frames": keys,
        "polars": spelling or f'pl.concat([{names}], how="{how}")',
    }, result, err))


# ---- concat: the four modes on named frames ----------------------------
for how in ("vertical", "vertical_relaxed", "diagonal", "horizontal"):
    add_concat("single", [ab1], how)
    add_concat("empty-list", [], how, spelling=f'pl.concat([], how="{how}")')
    add_concat("zero-cols-both", [z0, z0], how)
    add_concat("zero-cols-all-3", [z0, z0, z0], how)
    add_concat("zero-rows-both", [ab0, ab0], how)
for how in ("vertical", "vertical_relaxed", "diagonal"):
    add_concat("two", [ab1, ab2], how)
    add_concat("three", [ab1, ab2, ab3], how)
    add_concat("zero-rows-first", [ab0, ab2], how)
    add_concat("zero-rows-last", [ab2, ab0], how)
    add_concat("zero-rows-mid", [ab1, ab0, ab2], how)
    add_concat("same-frame-twice", [ab1, ab1], how)
    add_concat("i64-i32", [ab1, ab_i32], how)
    add_concat("i64-f64", [ab1, ab_f64], how)
    add_concat("i64-str", [ab1, ab_str], how)
    add_concat("i64-null", [ab1, ab_null], how)
    add_concat("null-i64", [ab_null, ab1], how)
    add_concat("null-null", [ab_null, ab_null1], how)
    add_concat("null-null-i64", [ab_null, ab_null1, ab1], how)
    add_concat("i64-null-i64", [ab1, ab_null, ab2], how)
    add_concat("i32-i64-f64", [ab_i32, ab1, ab_f64], how)
    add_concat("f64-i64-str", [ab_f64, ab1, ab_str], how)
    add_concat("str-i64-f64", [ab_str, ab1, ab_f64], how)
    add_concat("swapped-columns", [ab1, ba], how)
    add_concat("renamed-column", [ab1, aq], how)
    add_concat("renamed-column-zero-rows", [ab0, aq], how)
    add_concat("renamed-column-zero-rows-b", [ab1, qb0], how)
    add_concat("fewer-columns", [ab1, a_only], how)
    add_concat("more-columns", [ab1, abc], how)
    add_concat("zero-cols-first", [z0, ab1], how)
    add_concat("zero-cols-last", [ab1, z0], how)
    add_concat("zero-cols-mid", [ab1, z0, ab2], how)
    add_concat("zero-cols-two-first", [z0, z0, ab1], how)
    add_concat("error-at-third", [ab1, ab2, aq], how)
    add_concat("error-at-second-then-third", [ab1, aq, a_only], how)
    add_concat("width-error-at-third", [ab1, ab2, a_only], how)
    add_concat("name-and-type-same-column", [x_i64, y_str], how)
    add_concat("type-error-before-name-error", [ab1, frame("a_str_c", pl.DataFrame([mk("a", "str", ["s"]), mk("c", "str", ["t"])]))], how)
    add_concat("name-error-before-type-error", [ab1, frame("q_i64_b_i64", pl.DataFrame([mk("q", "i64", [1]), mk("b", "i64", [1])]))], how)
    add_concat("date-first", [a_date, a_dt], how)
    add_concat("dt-date", [a_dt, a_date], how)
    add_concat("bool-i32", [a_bool, a_i32], how)
    add_concat("i32-bool", [a_i32, a_bool], how)
    add_concat("f32-i32", [a_f32, a_i32], how)
    add_concat("date-i32-dt", [x_date1, x_i32, x_dt1], how)
    add_concat("bool-i32-date", [x_bool, x_i32, x_date1], how)
    add_concat("bool-date-i32", [x_bool, x_date1, x_i32], how)
    add_concat("i32-f32-i64", [x_i32, x_f32, x_i64], how)
    add_concat("f32-i32-f32", [x_f32, x_i32, x_f32], how)
    add_concat("str-bool-date", [x_str1, x_bool, x_date1], how)
    add_concat("null-then-i64", [a_null, a_null, a_i64], how)
    add_concat("i64-str-empty", [a_i64, a0_str], how)
    add_concat("str-empty-first", [a0_str, a_str], how)

# relaxed-only error order (width, names and supertype are checked frame by frame)
add_concat("supertype-before-name-error", [x_bool, x_date1, y_bool], "vertical_relaxed")
add_concat("name-error-before-supertype", [x_bool, y_bool, x_date1], "vertical_relaxed")
add_concat("supertype-before-width", [x_bool, x_date1, xy_bool], "vertical_relaxed")
add_concat("width-before-supertype", [x_bool, xy_bool, x_date1], "vertical_relaxed")
add_concat("supertype-before-name-same-frame", [xy_bool, xz_date], "vertical_relaxed")
add_concat("name-before-supertype-same-frame", [xy_bool, zy_date], "vertical_relaxed")
add_concat("vertical-type-before-name-same-frame", [xy_bool, xz_date], "vertical")

# diagonal
add_concat("union-columns", [ab1, bc, cd, d_only], "diagonal")
add_concat("union-order", [abc, bc, ab1], "diagonal")
add_concat("missing-in-first", [a_only, ab1], "diagonal")
add_concat("filler-null-column-first", [a_null, ab1], "diagonal")
add_concat("filler-null-column-later", [ab1, a_null], "diagonal")
add_concat("null-appears-then-typed", [y_str, x_null, X["i64"]], "diagonal")
add_concat("null-appears-then-typed-b", [y_str, x_null, x_i64], "diagonal")
add_concat("typed-filler-date", [a_only, d0], "diagonal")
add_concat("typed-filler-date-first", [d0, a_only], "diagonal")
add_concat("typed-filler-zero-rows", [ab1, d0], "diagonal")
add_concat("disjoint", [x_i64, y_str], "diagonal")
add_concat("disjoint-three", [x_i64, y_str, y_bool], "diagonal")
add_concat("types-differ-in-later-frame", [ab1, frame("ba_types", pl.DataFrame([mk("b", "i64", [1]), mk("a", "str", ["s"])]))], "diagonal")
add_concat("null-in-later-frame", [ab1, frame("ba_nulls", pl.DataFrame([mk("b", "null", [None]), mk("a", "null", [None])]))], "diagonal")
add_concat("i64-then-f64-then-i64", [a_i64, a_f64, a_i64], "diagonal")

# horizontal
add_concat("two", [ab1, frame("h3c", pl.DataFrame([mk("c", "f64", [0.5, nan, None])]))], "horizontal")
add_concat("two-h2", [h2ab, h2], "horizontal")
add_concat("three", [h2ab, h2, h2d], "horizontal")
add_concat("duplicate-name", [h2ab, h2a], "horizontal")
add_concat("duplicate-name-third", [h2ab, h2, h2a], "horizontal")
add_concat("duplicate-name-second-and-third", [h2ab, h2cd, h2dc], "horizontal")
add_concat("duplicate-before-height", [ab1, a_only], "horizontal")
add_concat("height-short", [h2ab, h1], "horizontal")
add_concat("height-long", [h2ab, h3], "horizontal")
add_concat("height-third", [h2ab, h2, h3], "horizontal")
add_concat("height-one-one", [h1z, h1c], "horizontal")
add_concat("height-zero-rows-vs-rows", [ab0, h2], "horizontal")
add_concat("height-zero-rows-both", [ab0, h0], "horizontal")
add_concat("zero-cols-first", [z0, h2ab], "horizontal")
add_concat("zero-cols-last", [h2ab, z0], "horizontal")
add_concat("zero-cols-mid", [h2ab, z0, h2], "horizontal")
add_concat("zero-cols-with-zero-rows", [ab0, z0], "horizontal")
add_concat("zero-cols-first-with-zero-rows", [z0, ab0], "horizontal")
add_concat("zero-rows-two-frames", [e_x, e_y], "horizontal")
add_concat("zero-rows-same-name", [e_x, e_x], "horizontal")
add_concat("null-columns", [h2ab, frame("h2n", pl.DataFrame([mk("n", "null", [None, None])]))], "horizontal")

# ---- concat: dtype pairs of a single column ---------------------------
for how in ("vertical", "vertical_relaxed"):
    for x in DTYPES:
        for y in DTYPES:
            add_concat(f"pair/{SHORT[x]}-{SHORT[y]}", [X[x], X[y]], how)
    for x in DTYPES:
        for y in DTYPES:
            add_concat(f"pair-empty/{SHORT[x]}-{SHORT[y]}", [X0[x], X[y]], how)
for x in DTYPES:
    for y in DTYPES:
        add_concat(f"pair/{SHORT[x]}-{SHORT[y]}", [X[x], X[y]], "diagonal")

# ---------------------------------------------------------------------------
# vstack / hstack / append / to_frame
# ---------------------------------------------------------------------------
def add_vstack(cid, a, b):
    result, err = attempt(lambda: FR[a].vstack(FR[b]))
    cases.append(finish({"id": f"vstack/{cid}", "op": "vstack", "a": a, "b": b,
                         "polars": f"{a[2:]}.vstack({b[2:]})"}, result, err))


add_vstack("two", ab1, ab2)
add_vstack("same-frame", ab1, ab1)
add_vstack("zero-rows-self", ab0, ab2)
add_vstack("zero-rows-other", ab1, ab0)
add_vstack("zero-cols-self", z0, ab1)
add_vstack("zero-cols-other", ab1, z0)
add_vstack("zero-cols-both", z0, z0)
add_vstack("names", ab1, aq)
add_vstack("order", ab1, ba)
add_vstack("width-fewer", ab1, a_only)
add_vstack("width-more", ab1, abc)
add_vstack("type", ab1, ab_i32)
add_vstack("type-float", ab1, ab_f64)
add_vstack("null-other", ab1, ab_null)
add_vstack("null-self", ab_null, ab1)
add_vstack("null-both", ab_null, ab_null1)
add_vstack("name-and-type-same-column", x_i64, y_str)
add_vstack("date-datetime", a_date, a_dt)
for x in DTYPES:
    for y in DTYPES:
        add_vstack(f"pair/{SHORT[x]}-{SHORT[y]}", X[x], X[y])

# hstack
S3 = {
    "c3": mk("c", "i64", [1, 2, 3]),
    "c2": mk("c", "i64", [1, 2]),
    "c1": mk("c", "i64", [1]),
    "c0": mk("c", "i64", []),
    "d2": mk("d", "f64", [0.5, None]),
    "d1": mk("d", "f64", [0.5]),
    "d3": mk("d", "f64", [0.5, 1.5, 2.5]),
    "a2": mk("a", "i64", [1, 2]),
    "b2": mk("b", "str", ["u", "v"]),
    "n2": mk("n", "null", [None, None]),
    "n0": mk("n", "null", []),
    "e2": mk("", "i64", [1, 2]),
    "cs2": mk("c", "str", ["s", None]),
    "a0": mk("a", "i64", []),
    "b0": mk("b", "i64", []),
    "a3": mk("a", "i64", [1, 2, 3]),
    "b3": mk("b", "i64", [1, 2, 3]),
    "b1": mk("b", "i64", [1]),
}
SK = {k: series(k, v) for k, v in S3.items()}


def add_hstack(cid, a, names):
    keys = [SK[n] for n in names]
    result, err = attempt(lambda: FR[a].hstack([SE[k] for k in keys]))
    spelling = f"{a[2:]}.hstack([{', '.join(n for n in names)}])"
    cases.append(finish({"id": f"hstack/{cid}", "op": "hstack", "a": a, "columns": keys,
                         "polars": spelling}, result, err))


add_hstack("one", h2ab, ["c2"])
add_hstack("two", h2ab, ["c2", "d2"])
add_hstack("none", h2ab, [])
add_hstack("none-zero-cols", z0, [])
add_hstack("duplicate-self", h2ab, ["a2"])
add_hstack("duplicate-self-second", h2ab, ["c2", "a2"])
add_hstack("duplicate-self-b", h2ab, ["c2", "b2"])
add_hstack("duplicate-new", h2ab, ["c2", "c2"])
add_hstack("duplicate-order-c-a-c", h2ab, ["c2", "a2", "c2"])
add_hstack("duplicate-order-c-c-a", h2ab, ["c2", "c2", "a2"])
add_hstack("duplicate-before-height", h2ab, ["a2", "c1"])
add_hstack("duplicate-before-height-b", h2ab, ["c1", "a2"])
add_hstack("duplicate-before-height-c", h2ab, ["c1", "c2", "c1"])
add_hstack("height-short", h2ab, ["c1"])
add_hstack("height-long", h2ab, ["c3"])
add_hstack("height-second", h2ab, ["c2", "d1"])
add_hstack("height-first", h2ab, ["d1", "c2"])
add_hstack("height-zero", h2ab, ["c0"])
add_hstack("zero-cols-self", z0, ["c2"])
add_hstack("zero-cols-self-empty-col", z0, ["c0"])
add_hstack("zero-cols-self-mismatch", z0, ["c3", "d1"])
add_hstack("zero-cols-self-two", z0, ["c0", "n0"])
add_hstack("zero-rows-self-empty", ab0, ["c0"])
add_hstack("zero-rows-self-one", ab0, ["c1"])
add_hstack("zero-rows-self-null", ab0, ["n0"])
add_hstack("null-column", h2ab, ["n2"])
add_hstack("empty-name", h2ab, ["e2"])
add_hstack("one-row-both", h1z, ["d1"])
add_hstack("one-row-self-two-new", h1z, ["c2"])
add_hstack("one-row-new", h2ab, ["d1"])
add_hstack("string-column", h2ab, ["cs2"])
add_hstack("three", h2ab, ["c2", "d2", "n2"])
add_hstack("height-third-wrong", h2ab, ["c2", "d2", "d3"])
# a frame without columns has height 0; the message names the first new
# column of height 0 (reviewer fix: 283 of 283 probe cases follow this rule)
for tag, names in {
    "zero-first-then-three": ["a0", "b3"],
    "three-then-zero": ["a3", "b0"],
    "zero-zero": ["a0", "b0"],
    "zero-then-one": ["a0", "b1"],
    "one-then-zero": ["a3", "b1", "c0"],
    "zero-in-middle": ["c3", "d1", "n0", "c2"],
    "two-zeros": ["c3", "n0", "b0"],
    "no-zero-height": ["a3", "b3"],
    "five-columns": ["a3", "c1", "n0", "d3", "b0"],
    "five-columns-zero-last": ["a3", "c1", "d2", "n2", "b0"],
    "five-columns-no-zero": ["a3", "c1", "d2", "n2", "b3"],
}.items():
    add_hstack("empty-self/" + tag, z0, names)
add_hstack("zero-row-self/three", ab0, ["c3"])
add_hstack("zero-row-self/three-zero", ab0, ["c3", "n0"])

# Series.append (polars appends in place: clone first)
SV = {
    "bool": [True, None, False],
    "i32": [1, None, -2147483648],
    "i64": [1, None, I64_MAX],
    "f32": [0.5, nan, None, -0.0],
    "f64": [1.5, nan, None, -0.0],
    "str": ["a", None, "｡", "\U0001F600"],
    "date": [0, None, -25567, 19782],
    "datetime[μs]": [0, None, -1, 1709210096123456],
    "null": [None, None],
}
SS = {dt: series(SHORT[dt], mk("s", dt, SV[dt])) for dt in DTYPES}
SO = {dt: series(SHORT[dt] + "_other", mk("t", dt, SV[dt][:2])) for dt in DTYPES}
SE0 = {dt: series(SHORT[dt] + "_empty", mk("t", dt, [])) for dt in DTYPES}


def add_append(cid, a, b):
    result, err = attempt(lambda: SE[a].clone().append(SE[b]))
    cases.append(finish({"id": f"append/{cid}", "op": "append", "a": a, "b": b,
                         "polars": f"{a[2:]}.append({b[2:]})"}, result, err))


for x in DTYPES:
    for y in DTYPES:
        add_append(f"{SHORT[x]}-{SHORT[y]}", SS[x], SO[y])
for x in DTYPES:
    add_append(f"{SHORT[x]}-empty-same", SS[x], SE0[x])
    add_append(f"empty-{SHORT[x]}-same", SE0[x], SS[x])
    add_append(f"empty-{SHORT[x]}-empty", SE0[x], SE0[x])
add_append("i64-empty-null", SS["i64"], SE0["null"])
add_append("null-empty-i64", SE0["null"], SS["i64"])
add_append("i64-empty-i32", SS["i64"], SE0["i32"])
add_append("i64-empty-str", SS["i64"], SE0["str"])
add_append("same-series", SS["i64"], SS["i64"])
add_append("name-kept", SS["str"], SO["str"])

# to_frame
for dt in DTYPES:
    for tag, s in (("values", SS[dt]), ("empty", SE0[dt])):
        k = "s." + (SHORT[dt] if tag == "values" else SHORT[dt] + "_empty")
        result, err = attempt(lambda: SE[k].to_frame())
        cases.append(finish({"id": f"to_frame/{SHORT[dt]}/{tag}", "op": "to_frame", "a": k,
                             "polars": f"{k[2:]}.to_frame()"}, result, err))
ke = series("empty_name", mk("", "i64", [1, 2]))
result, err = attempt(lambda: SE[ke].to_frame())
cases.append(finish({"id": "to_frame/empty-name", "op": "to_frame", "a": ke,
                     "polars": "s.to_frame()"}, result, err))

# ---------------------------------------------------------------------------
# describe
# ---------------------------------------------------------------------------
I32 = [1, -1, 0, 2147483647, -2147483648, None, 7]
# The describe tables keep the sums of the numbers exact in f64: polars sums
# `[1, -1, 0, MAX, MIN, None, 3e9]` in an order that changes from run to run
# (its mean is 5e8 or 500000085.33), so the extremes of Int64 only appear in
# `d_big` below, where every partial sum is exact.
I64 = [1, -1, 0, 2**52, -2**52, None, 3000000000]
F32 = [0.5, nan, None, -inf, -0.0, 0.0, 3.0e38]
F64 = [1.0, nan, None, -inf, -0.0, 0.0, 2.5]
STR = ["｡", "\U0001F600", "a", "", "Z", None, "a"]
BOOL = [True, False, None, True, False, None, True]
DATE = [0, -1, 19782, None, -25567, 1, 2]
DT = [0, -1, 1709210096123456, None, 86399999999, 5, 6]
COLS = {"i32": ("i32", I32), "i64": ("i64", I64), "f32": ("f32", F32), "f64": ("f64", F64),
        "s": ("str", STR), "b": ("bool", BOOL), "d": ("date", DATE),
        "dt": ("datetime[μs]", DT), "n": ("null", [None] * 7)}


def table(cols, rows=None):
    out = []
    for c in cols:
        dt, vals = COLS[c]
        out.append(mk(c, dt, vals if rows is None else vals[:rows]))
    return pl.DataFrame(out)


D_ALL = frame("d_all", table(list(COLS)))
D_NUM = frame("d_num", table(["i32", "i64", "f32", "f64"]))
D_E0 = frame("d_e0", table(list(COLS), 0))
D_ONE = frame("d_one", table(list(COLS), 1))
D_TWO = frame("d_two", table(list(COLS), 2))
D_NULLS = frame("d_nulls", pl.DataFrame([mk(c, dt, [None, None, None]) for c, (dt, _) in COLS.items()]))
D_Z0 = frame("d_z0", pl.DataFrame())
for c in COLS:
    frame("d_col_" + c, table([c]))

D_PCT = frame("d_pct", pl.DataFrame([
    mk("i", "i64", [1, 2, 3, 4, 10]),
    mk("d", "date", [0, 10, 3, 19000, 5]),
    mk("dt", "datetime[μs]", [0, 10, 3, 19000 * 86400 * 10**6, 5]),
    mk("f", "f64", [1.5, 2.5, 0.1, -3.0, 7.0]),
    mk("s", "str", ["a", "b", "c", "d", "e"]),
    mk("b", "bool", [True, False, True, True, False]),
]))
D_NEG = frame("d_neg", pl.DataFrame([
    mk("d", "date", [-1, -2, -1000]),
    mk("dt", "datetime[μs]", [-1, -2, -1000001]),
    mk("f", "f64", [-1.5, -2.5, -0.5]),
]))
D_NEG_N = frame("d_neg_n", pl.DataFrame([
    mk("d", "date", [-1, None, -2, -1000, None]),
    mk("dt", "datetime[μs]", [-1, None, -2, -1000001, None]),
    mk("i", "i32", [-1, None, -2, -1000, None]),
]))
D_BIG = frame("d_big", pl.DataFrame([mk("x", "i64", [2**62, 2**62 + 1, -2**63 + 1]),
                                      mk("y", "i64", [I64_MAX, I64_MAX, I64_MIN])]))
D_INF = frame("d_inf", pl.DataFrame([mk("x", "f64", [inf, 1.0, -inf]), mk("y", "f64", [inf, inf, 1.0]),
                                      mk("z", "f64", [nan, nan, nan])]))
D_F32 = frame("d_f32", pl.DataFrame([mk("x", "f32", [0.1, 0.2, 0.7]), mk("y", "f32", [3e38, 3e38, -3e38]),
                                      mk("z", "f32", [16777216.0, 1.0, 1.0])]))
D_DT_MEAN = frame("d_dt_mean", pl.DataFrame([mk("x", "datetime[μs]", [1, 2]), mk("y", "date", [1, 2]),
                                              mk("z", "datetime[μs]", [86399999999, 86400000000])]))
D_DATE_EDGES = frame("d_date_edges", pl.DataFrame([mk("x", "date", [-719162, 2932896]),
                                                    mk("y", "date", [-719162, 2932896])]))
D_STRS = frame("d_strs", pl.DataFrame([mk("x", "str", ["é", "\U0001F600", None, "｡", ""]),
                                        mk("y", "str", ["b", "a", "b", "", "a"])]))
D_STATISTIC = frame("d_statistic", pl.DataFrame([mk("statistic", "i64", [1, 2]), mk("x", "i64", [3, 4])]))
D_NAMES = frame("d_names", pl.DataFrame([mk("", "i64", [1, 2]), mk("count:x", "f64", [0.5, 1.5]),
                                          mk("25%", "str", ["a", "b"])]))
D_ST_STR = frame("d_st_str", pl.DataFrame([mk("s", "str", ["a", "b"]), mk("i", "i64", [1, 2])]))
# 8 rows (a power of two) of values whose sums are exact: with percentiles=[]
# polars does not sort first and its `std` of other data (10 integers, 5
# floats) changes in the last digit from run to run (merging of chunks)
D_SMALL = frame("d_small", pl.DataFrame([mk("x", "i64", [3, 1, 2, 5, 4, 8, 6, 7]),
                                          mk("y", "f64", [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5])]))

DEFAULT = None

DESCRIBE_RUNS = 100


def settle_describe(case, run):
    """polars' `describe` computes `mean` and `std` by merging chunk results
    in an order that can change from run to run, so the last digit of a
    Float64 `mean`/`std` is not always the same (known-diffs/concat_describe.md).
    To make the generated file reproducible the case is run DESCRIBE_RUNS times:
    every other value must be identical in all runs (otherwise this raises),
    and a `mean`/`std` cell that varies is recorded as the smallest value seen.
    The tests compare these two rows with a tolerance."""
    cols = case["result"]["columns"]
    labels = cols[0]["values"] if cols and cols[0]["name"] == "statistic" else None
    varied = 0
    for _ in range(DESCRIBE_RUNS - 1):
        other = encode_result(run())["columns"]
        assert [c["name"] for c in other] == [c["name"] for c in cols], case["id"]
        for c, o in zip(cols, other):
            assert c["dtype"] == o["dtype"] and len(c["values"]) == len(o["values"]), case["id"]
            for ri, (x, y) in enumerate(zip(c["values"], o["values"])):
                if x == y:
                    continue
                ok = (labels is not None and c["dtype"] == "f64" and labels[ri] in ("mean", "std")
                      and x is not None and y is not None)
                assert ok, (case["id"], c["name"], ri, x, y)
                fx, fy = float(x), float(y)
                assert fx == fx and fy == fy, (case["id"], c["name"], ri, x, y)
                varied += 1
                if fy < fx:
                    c["values"][ri] = y
    if varied:
        print(f"describe {case['id']}: mean/std varied {varied} times in {DESCRIBE_RUNS} runs", file=sys.stderr)


def add_describe(cid, a, percentiles=DEFAULT, interpolation=None):
    kw = {}
    spelling_args = []
    case = {"id": f"describe/{cid}", "op": "describe", "a": a}
    if percentiles is not DEFAULT:
        kw["percentiles"] = percentiles
        case["percentiles"] = [fl(p) for p in percentiles]
        spelling_args.append("percentiles=[" + ", ".join(fl(p) for p in percentiles) + "]")
    if interpolation is not None:
        kw["interpolation"] = interpolation
        case["interpolation"] = interpolation
        spelling_args.append(f'interpolation="{interpolation}"')
    result, err = attempt(lambda: FR[a].describe(**kw))
    case["polars"] = f"{a[2:]}.describe(" + ", ".join(spelling_args) + ")"
    case = finish(case, result, err)
    if err is None:
        settle_describe(case, lambda: FR[a].describe(**kw))
    cases.append(case)


INTERPS = ["nearest", "higher", "lower", "midpoint", "linear", "equiprobable"]
for f in ("d_all", "d_num", "d_e0", "d_one", "d_two", "d_nulls", "d_pct", "d_neg", "d_neg_n", "d_big", "d_inf",
          "d_f32", "d_dt_mean", "d_date_edges", "d_strs", "d_names", "d_st_str", "d_small"):
    add_describe(f"default/{f[2:]}", "f." + f)
for c in COLS:
    add_describe(f"default/col-{c}", "f.d_col_" + c)
for f in ("d_all", "d_pct", "d_neg", "d_neg_n", "d_small", "d_f32", "d_one", "d_e0"):
    for ip in INTERPS:
        add_describe(f"interp/{f[2:]}/{ip}", "f." + f, [0.1, 0.3, 0.5, 0.9, 0.0, 1.0], ip)
for ip in INTERPS:
    add_describe(f"interp-default-pcts/all/{ip}", "f.d_all", DEFAULT, ip)
    add_describe(f"interp-default-pcts/neg-n/{ip}", "f.d_neg_n", DEFAULT, ip)
    add_describe(f"interp-many/small/{ip}", "f.d_small", [i / 20 for i in range(21)], ip)
PCTS = {
    "empty": [],
    "zero-one": [0, 1],
    "only-median": [0.5],
    "unsorted": [0.9, 0.1, 0.5, 0.0],
    "just-below-half": [0.4999999],
    "half-and-above": [0.75, 0.5],
    "neg-zero": [-0.0],
    "labels": [0.333, 0.1, 0.07, 1e-7, 0.999, 0.12345678, 1 / 3, 0.9999999],
    "labels-b": [0.125, 0.9995, 0.00001, 0.000001, 0.0001, 0.001, 0.01, 0.2, 0.3, 0.7, 0.99],
    "labels-c": [0.1234565, 0.1234575, 0.0123456, 0.00012345678, 0.5, 0.99999949, 0.999999951],
    "labels-d": [0.12345, 0.123455, 0.1234549, 0.8, 0.29, 0.57, 0.58, 0.59],
    "many": [i / 10 for i in range(11)],
}
for tag, p in PCTS.items():
    if tag != "empty":  # see D_SMALL: with percentiles=[] polars does not sort first and
        # the std of `d_all` (1 to 30 runs in 100 differ in the last digit) and of
        # `d_pct` is not reproducible
        add_describe(f"pcts/{tag}/all", "f.d_all", p)
        add_describe(f"pcts/{tag}/pct", "f.d_pct", p)
    add_describe(f"pcts/{tag}/small", "f.d_small", p, "linear")
# errors
add_describe("error/no-columns", "f.d_z0")
add_describe("error/no-columns-bad-pct", "f.d_z0", [2.0])
add_describe("error/pct-below", "f.d_all", [-0.1])
add_describe("error/pct-above", "f.d_all", [1.1])
add_describe("error/pct-nan", "f.d_all", [nan])
add_describe("error/pct-inf", "f.d_all", [inf])
add_describe("error/pct-neg-inf", "f.d_all", [-inf])
add_describe("error/pct-one-bad-among-good", "f.d_all", [0.1, 0.5, 1.0000001])
add_describe("error/pct-duplicate", "f.d_pct", [0.5, 0.5])
add_describe("error/pct-duplicate-first-column-string", "f.d_st_str", [0.25, 0.25])
add_describe("error/pct-duplicate-unsorted", "f.d_pct", [0.9, 0.1, 0.9, 0.1])
add_describe("error/pct-duplicate-default-extra", "f.d_all", [0.25, 0.5, 0.75, 0.5])
add_describe("error/pct-duplicate-zero", "f.d_pct", [0.0, 0.0])
add_describe("error/pct-duplicate-one", "f.d_pct", [1.0, 1.0])
add_describe("error/pct-duplicate-small", "f.d_pct", [1e-7, 1e-7])
add_describe("error/pct-duplicate-neg-zero-zero", "f.d_pct", [-0.0, 0.0])
add_describe("error/statistic-column", "f.d_statistic")
add_describe("error/statistic-column-and-duplicate-pct", "f.d_statistic", [0.5, 0.5])
add_describe("error/statistic-column-no-pcts", "f.d_statistic", [])

ids = [c["id"] for c in cases]
assert len(ids) == len(set(ids)), "duplicate case ids: " + str([i for i in ids if ids.count(i) > 1][:5])
emit("concat_describe", {"cases": cases, "inputs": INPUTS}, compact=True)
print(f"polars {pl.__version__}: wrote {len(cases)} cases, {len(INPUTS)} inputs")
