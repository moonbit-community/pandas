"""Generates the `DataFrame::join` golden data (docs/golden/join.json,
src/pl/golden_join_data_test.mbt).

Run from the repository root (polars 2.1.0; the thread count is fixed so that
two runs write the same bytes):
    ulimit -v 16000000; POLARS_MAX_THREADS=4 \\
        /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/join.py

The file is `{"tables": {name: frame}, "cases": [...]}` (compact layout). A
frame is `{"columns": [series, ...]}` (series as in docs/golden/README.md).

Every case has
  - `id`, `polars` (the Python spelling of the call), `left` and `right` (table
    names), `how` (`inner`, `left`, `right`, `full`, `semi`, `anti`, `cross`);
  - the arguments that were given: `on`, `left_on`, `right_on` (lists of key
    expressions), `suffix`, `validate`, `nulls_equal`, `coalesce`;
  - `result` (a frame) or `error` + `message` (the variant per the M2 error
    mapping and the first line of polars' message; `polars_error` keeps the
    polars class when it is a Python `ValueError`, which the library reports as
    `InvalidOperation`).

A key expression is a JSON value: a string is `pl.col(name)`; an object is one
of `{"cols": [names]}`, `{"all": true}`, `{"rem": [e, n]}` (`e % n`),
`{"add": [e, n]}`, `{"cast": [e, dtype]}`, `{"lit": n}`, `{"alias": [e, name]}`,
`{"cum_sum": e}`, `{"sum": e}`, `{"len": e}`, `{"abs": e}`, `{"is_null": e}`,
`{"fill_null": [e, n]}`.

Row order: polars' `maintain_order` is `"left_right"` for every `how` but
`right` (`"right_left"`), the order the library always gives.
"""
import os

# must be set before polars is imported
os.environ["POLARS_MAX_THREADS"] = "4"

import json
import math
import re
import sys
import warnings

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import polars as pl

from emit import emit, encode_series, series_from_spec

warnings.simplefilter("ignore")

nan = float("nan")
I64_MIN = -9223372036854775808

# ---------------------------------------------------------------------------
# Key expressions
# ---------------------------------------------------------------------------

POLARS_DTYPES = {"bool": "pl.Boolean", "i32": "pl.Int32", "i64": "pl.Int64",
                 "f32": "pl.Float32", "f64": "pl.Float64", "str": "pl.String",
                 "date": "pl.Date", "datetime[μs]": "pl.Datetime(\"us\")",
                 "null": "pl.Null"}


def mb_str(s):
    return json.dumps(s, ensure_ascii=False)


def key_pl(k):
    if isinstance(k, str):
        return pl.col(k)
    op = next(iter(k))
    v = k[op]
    if op == "cols":
        return pl.col(*v)
    if op == "all":
        return pl.all()
    if op == "rem":
        return key_pl(v[0]) % v[1]
    if op == "add":
        return key_pl(v[0]) + v[1]
    if op == "cast":
        return key_pl(v[0]).cast(series_from_spec("x", v[1], []).dtype)
    if op == "lit":
        return pl.lit(v)
    if op == "alias":
        return key_pl(v[0]).alias(v[1])
    if op == "cum_sum":
        return key_pl(v).cum_sum()
    if op == "sum":
        return key_pl(v).sum()
    if op == "len":
        return key_pl(v).len()
    if op == "abs":
        return key_pl(v).abs()
    if op == "is_null":
        return key_pl(v).is_null()
    if op == "fill_null":
        return key_pl(v[0]).fill_null(v[1])
    raise ValueError(k)


def key_py(k):
    if isinstance(k, str):
        return f"pl.col({mb_str(k)})"
    op = next(iter(k))
    v = k[op]
    if op == "cols":
        return "pl.col(" + ", ".join(mb_str(x) for x in v) + ")"
    if op == "all":
        return "pl.all()"
    if op == "rem":
        return f"({key_py(v[0])} % {v[1]})"
    if op == "add":
        return f"({key_py(v[0])} + {v[1]})"
    if op == "cast":
        return f"{key_py(v[0])}.cast({POLARS_DTYPES[v[1]]})"
    if op == "lit":
        return f"pl.lit({v})"
    if op == "alias":
        return f"{key_py(v[0])}.alias({mb_str(v[1])})"
    if op in ("cum_sum", "sum", "len", "abs", "is_null"):
        return f"{key_py(v)}.{op}()"
    if op == "fill_null":
        return f"{key_py(v[0])}.fill_null({v[1]})"
    raise ValueError(k)


def keys_pl(ks):
    return [key_pl(k) for k in ks]


def keys_py(ks):
    return "[" + ", ".join(key_py(k) for k in ks) + "]"


# ---------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------

TABLES = {}


def reg(name, df):
    assert name not in TABLES, name
    TABLES[name] = df
    return name


def frame(cols):
    """`cols`: [(name, dtype, values)]"""
    return pl.DataFrame([series_from_spec(n, d, v) for n, d, v in cols])


TYPES = ["bool", "i32", "i64", "f32", "f64", "str", "date", "datetime[μs]", "null"]

# four distinct values per type: v0, v1 are on both sides (twice on each),
# v2 only on the left, v3 only on the right
DISTINCT = {
    "i32": [1, -1, 7, 2147483647],
    "i64": [10, I64_MIN, 30, 31],
    "str": ["｡", "\U0001F600", "a", "Z"],
    "date": [0, -1, 19782, 5],
    "datetime[μs]": [0, -1, 1709210096123456, 5],
}


def key_lists(t):
    """The key columns `(left, right)` of the key-type tables."""
    if t == "bool":
        return [True, False, None, True, None], [False, None, False, False]
    if t == "null":
        return [None] * 7, [None] * 5
    if t in ("f32", "f64"):
        return ([1.0, nan, None, -0.0, 0.0, nan, None],
                [nan, 0.0, None, 1.0, -0.0, 2.5, None])
    v0, v1, v2, v3 = DISTINCT[t]
    left = [v0, v1, None, v2, v0, v1, None]
    right = [v1, v0, None, v0, v3, v1, None]
    if t == "str":
        left.append("")
        right.append("")
    return left, right


for _t in TYPES:
    _l, _r = key_lists(_t)
    reg(f"L_{_t}", frame([("k", _t, _l), ("i", "i64", list(range(len(_l))))]))
    reg(f"R_{_t}", frame([("k", _t, _r), ("j", "i64", list(range(len(_r))))]))

# names, suffixes, coalescing: `nl` (a, x, b) and `nr` (a, y, b)
reg("nl", frame([("a", "i64", [1, 2, 3, None]), ("x", "i64", [10, 20, 30, 40]),
                 ("b", "str", ["p", "q", "r", "s"])]))
reg("nr", frame([("a", "i64", [2, 3, 3, 5]), ("y", "i64", [10, 2, 3, 40]),
                 ("b", "str", ["P", "Q", "R", "S"])]))
reg("nr_k", TABLES["nr"].rename({"a": "k"}))
reg("nr_x", TABLES["nr"].rename({"y": "x"}))
reg("nl_b_right", TABLES["nl"].with_columns(b_right=pl.lit(1)))
reg("nl_a_right", TABLES["nl"].with_columns(a_right=pl.lit(1)))
reg("nl_k", TABLES["nl"].with_columns(k=pl.lit(1)))
reg("nr_b_right", TABLES["nr"].with_columns(b_right=pl.lit(1)))
reg("nl_i32", TABLES["nl"].with_columns(pl.col("a").cast(pl.Int32)))
reg("nl_str", frame([("a", "str", ["u", "v"]), ("x", "i64", [1, 2])]))
reg("nr_i32", TABLES["nr"].with_columns(pl.col("a").cast(pl.Int32)))
reg("nl0", TABLES["nl"].head(0))
reg("nr0", TABLES["nr"].head(0))
reg("z0", pl.DataFrame())
reg("nl_a", TABLES["nl"].select("a"))
# unique keys (one to one)
reg("u_l", frame([("k", "i64", [1, 2, 3]), ("i", "i64", [0, 1, 2])]))
reg("u_r", frame([("k", "i64", [3, 1, 4]), ("j", "i64", [0, 1, 2])]))
# one to many: unique left, repeated right
reg("om_r", frame([("k", "i64", [3, 3, 1, 1, 1, 9]), ("j", "i64", list(range(6)))]))
# unmatched duplicates
reg("d_l", frame([("k", "i64", [1, 2]), ("i", "i64", [0, 1])]))
reg("d_r", frame([("k", "i64", [5, 5]), ("j", "i64", [0, 1])]))
# nulls
reg("n_l", frame([("k", "i64", [1, None, None]), ("i", "i64", [0, 1, 2])]))
reg("n_r", frame([("k", "i64", [1, None, None]), ("j", "i64", [0, 1, 2])]))
reg("n_u", frame([("k", "i64", [1, 2, None]), ("j", "i64", [0, 1, 2])]))
# several keys with nulls
reg("m_l", frame([("a", "i64", [1, 1, None, None, 2]), ("b", "str", ["x", None, "y", None, "z"]),
                  ("i", "i64", [0, 1, 2, 3, 4])]))
reg("m_r", frame([("a", "i64", [1, 1, None, None, 2]), ("b", "str", ["x", None, "y", None, "q"]),
                  ("j", "i64", [0, 1, 2, 3, 4])]))
reg("mk_l", frame([("a", "i64", [1, 1, 2]), ("b", "i64", [None, None, 3]), ("i", "i64", [0, 1, 2])]))
reg("mk_r", frame([("a", "i64", [1, 2]), ("b", "i64", [None, 3]), ("j", "i64", [0, 1])]))
reg("mk2_l", frame([("a", "i64", [1, 1, 2]), ("b", "i64", [None, 5, 3]), ("i", "i64", [0, 1, 2])]))
# order of the output
reg("o_l", frame([("k", "i64", [3, 1, 2, 1]), ("i", "i64", [0, 1, 2, 3])]))
reg("o_r", frame([("k", "i64", [2, 9, 1, 8, 3, 1]), ("j", "i64", list(range(6)))]))
# a 2x3 cross
reg("c_l", frame([("a", "i64", [1, 2])]))
reg("c_r", frame([("a", "i64", [3, 4, 5])]))
# a frame where `a` is a number and one where it is text: key type errors
reg("t_num", frame([("a", "i64", [1, 2]), ("x", "i64", [1, 2])]))
# dates: arithmetic on them is an error polars reports before the key types
reg("dl", frame([("a", "i64", [1, 2]), ("d", "date", [0, 1]), ("x", "i64", [5, 6])]))
reg("dr", frame([("a", "i64", [1, 2]), ("d", "date", [0, 1]), ("y", "i64", [5, 6])]))

# ---------------------------------------------------------------------------
# Running a case
# ---------------------------------------------------------------------------

VARIANTS = {
    "ColumnNotFoundError": "ColumnNotFound",
    "DuplicateError": "DuplicateColumn",
    "SchemaError": "SchemaMismatch",
    "ShapeError": "ShapeMismatch",
    "OutOfBoundsError": "OutOfBounds",
    "InvalidOperationError": "InvalidOperation",
    "ComputeError": "ComputeError",
    # no counterpart: the library reports InvalidOperation
    "ValueError": "InvalidOperation",
}

CASES = []
IDS = set()


def encode_frame(df):
    return {"columns": [encode_series(s) for s in df.get_columns()]}


def jcase(cid, left, right, how="inner", on=None, left_on=None, right_on=None,
          suffix=None, validate=None, nulls_equal=None, coalesce=None, note=None):
    assert cid not in IDS, cid
    kw = {"how": how}
    py = [f"{left}.join({right}"]
    rec = {"id": cid, "left": left, "right": right, "how": how}
    if on is not None:
        kw["on"] = keys_pl(on)
        py.append(f"on={keys_py(on)}")
        rec["on"] = on
    if left_on is not None:
        kw["left_on"] = keys_pl(left_on)
        py.append(f"left_on={keys_py(left_on)}")
        rec["left_on"] = left_on
    if right_on is not None:
        kw["right_on"] = keys_pl(right_on)
        py.append(f"right_on={keys_py(right_on)}")
        rec["right_on"] = right_on
    py.append(f'how="{how}"')
    if suffix is not None:
        kw["suffix"] = suffix
        py.append(f"suffix={mb_str(suffix)}")
        rec["suffix"] = suffix
    if validate is not None:
        kw["validate"] = validate
        py.append(f'validate="{validate}"')
        rec["validate"] = validate
    if nulls_equal is not None:
        kw["nulls_equal"] = nulls_equal
        py.append(f"nulls_equal={nulls_equal}")
        rec["nulls_equal"] = nulls_equal
    if coalesce is not None:
        kw["coalesce"] = coalesce
        py.append(f"coalesce={coalesce}")
        rec["coalesce"] = coalesce
    order = "right_left" if how == "right" else "left_right"
    kw["maintain_order"] = order
    py.append(f'maintain_order="{order}"')
    rec["polars"] = ", ".join(py) + ")"
    if note:
        rec["note"] = note
    try:
        res = TABLES[left].join(TABLES[right], **kw)
        rec["result"] = encode_frame(res)
    except BaseException as e:  # noqa: BLE001  (polars panics are BaseExceptions)
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        name = type(e).__name__
        if name == "PanicException":
            print("PANIC (skipped)", cid, str(e)[:100])
            return
        assert name in VARIANTS, (cid, name, str(e))
        rec["error"] = VARIANTS[name]
        rec["message"] = str(e).split("\n")[0]
        if name == "ValueError":
            rec["polars_error"] = "ValueError"
        if rec["message"].startswith("arithmetic on dtypes str"):
            # spec 5.5: arithmetic on text is InvalidOperation whatever polars
            # does; the library's text differs (known-diffs/join.md), the order
            # of the errors is pinned by the cases on dates
            rec["restricted"] = True
        elif re.match(r"^\S+ not allowed on ", rec["message"]):
            # polars resolves the type of a key without materialising the
            # literal (`+ not allowed on date and dyn int`); the library reports
            # the kernel's text. Same variant, same place in the order of the
            # errors (known-diffs/join.md): only the variant is compared
            rec["message_differs"] = True
    IDS.add(cid)
    CASES.append(rec)


HOWS = ["inner", "left", "right", "full", "semi", "anti"]
C = lambda n: n  # a plain column key is its name

# ---------------------------------------------------------------------------
# 1. every key type: six `how`, nulls_equal false and true, coalesce
# ---------------------------------------------------------------------------

for t in TYPES:
    for how in HOWS:
        for ne in (False, True):
            jcase(f"key/{t}/{how}/ne={str(ne).lower()}", f"L_{t}", f"R_{t}", how,
                  on=["k"], nulls_equal=ne)
    for how, co in (("inner", False), ("left", False), ("right", False),
                    ("full", True)):
        jcase(f"key/{t}/{how}/coalesce={str(co).lower()}", f"L_{t}", f"R_{t}", how,
              on=["k"], coalesce=co)
    jcase(f"key/{t}/full/coalesce=true/ne=true", f"L_{t}", f"R_{t}", "full",
          on=["k"], coalesce=True, nulls_equal=True)
    jcase(f"key/{t}/cross", f"L_{t}", f"R_{t}", "cross")

# ---------------------------------------------------------------------------
# 2. key types that differ between the sides
# ---------------------------------------------------------------------------

for lt in TYPES:
    for rt in TYPES:
        if lt == rt:
            continue
        # a pair that cannot be joined fails the same way for every `how`: one
        # case; a pair that can (the integer and the float pairs) gets all
        for how, co in (("inner", None), ("left", None), ("right", None),
                        ("full", None), ("full", True)):
            if how != "inner" and "result" not in CASES[-1]:
                break
            jcase(f"keytype/{lt}/{rt}/{how}" + ("/coalesce=true" if co else ""),
                  f"L_{lt}", f"R_{rt}", how, on=["k"], coalesce=co)

# ---------------------------------------------------------------------------
# 3. names: suffix, coalesce, key names that differ, collisions
# ---------------------------------------------------------------------------

for how in HOWS:
    for co in (None, True, False):
        tag = "default" if co is None else str(co).lower()
        jcase(f"names/same/{how}/coalesce={tag}", "nl", "nr", how, on=["a"], coalesce=co)
        jcase(f"names/diff/{how}/coalesce={tag}", "nl", "nr_k", how,
              left_on=["a"], right_on=["k"], coalesce=co)
jcase("names/cross", "nl", "nr", "cross")
jcase("names/cross/coalesce=true", "nl", "nr", "cross", coalesce=True)
jcase("names/cross/suffix", "nl", "nr", "cross", suffix="_r")
jcase("names/cross/same-column", "c_l", "c_r", "cross")
jcase("names/cross/empty-suffix", "nl", "nr", "cross", suffix="")
jcase("names/cross/left-has-suffixed", "nl_a_right", "nr", "cross")
jcase("names/cross/no-columns", "z0", "z0", "cross")
jcase("names/cross/no-columns-left", "z0", "nr", "cross")
jcase("names/cross/no-columns-right", "nl", "z0", "cross")
jcase("names/suffix/custom", "nl", "nr", on=["a"], suffix="_r")
jcase("names/suffix/empty-collision", "nl", "nr", on=["a"], suffix="")
jcase("names/suffix/empty-semi", "nl", "nr", "semi", on=["a"], suffix="")
jcase("names/suffix/empty-no-collision", "nl", "nr_k", "left", left_on=["a"],
      right_on=["k"], suffix="")
jcase("names/suffix/left-has-b_right/inner", "nl_b_right", "nr", on=["a"])
jcase("names/suffix/left-has-b_right/left", "nl_b_right", "nr", "left", on=["a"])
jcase("names/suffix/left-has-b_right/semi", "nl_b_right", "nr", "semi", on=["a"])
jcase("names/suffix/right-has-b_right/inner", "nl", "nr_b_right", on=["a"])
jcase("names/suffix/right-has-b_right/right", "nl", "nr_b_right", "right", on=["a"])
jcase("names/suffix/left-has-a_right/full", "nl_a_right", "nr", "full", on=["a"])
jcase("names/suffix/left-has-a_right/inner", "nl_a_right", "nr", on=["a"])
jcase("names/suffix/left-has-a_right/inner/coalesce=false", "nl_a_right", "nr",
      on=["a"], coalesce=False)
jcase("names/suffix/key-collides-with-left-column", "nl_k", "nr_k", "inner",
      left_on=["a"], right_on=["k"])
jcase("names/suffix/key-collides-with-left-column/coalesce=false", "nl_k", "nr_k",
      "inner", left_on=["a"], right_on=["k"], coalesce=False)
jcase("names/suffix/suffixed-name-in-both", "nl_b_right", "nr_b_right", on=["a"])
# the key is not the first column
for how, co in (("left", None), ("right", None), ("full", True), ("full", None),
                ("inner", None), ("semi", None)):
    jcase(f"names/middle-key/{how}" + ("/coalesce=true" if co else ""),
          "nl", "nr_x", how, on=["x"], coalesce=co)
# several keys, in another order than the columns
for how, co in (("inner", None), ("left", None), ("right", None), ("full", True),
                ("full", None), ("semi", None), ("anti", None)):
    jcase(f"names/two-keys/{how}" + ("/coalesce=true" if co else ""),
          "nl", "nr", how, on=["b", "a"], coalesce=co)
jcase("names/two-keys/swapped", "nl", "nr", "left", left_on=["a", "x"], right_on=["y", "a"])
jcase("names/two-keys/swapped/full/coalesce=true", "nl", "nr", "full",
      left_on=["a", "x"], right_on=["y", "a"], coalesce=True)
jcase("names/two-keys/right-names-differ", "nl", "nr_k", "right", left_on=["a", "b"],
      right_on=["k", "b"])
# one column used for two keys
jcase("names/repeated/left-column/inner", "nl", "nr", "inner", left_on=["a", "a"], right_on=["a", "y"])
jcase("names/repeated/left-column/semi", "nl", "nr", "semi", left_on=["a", "a"], right_on=["a", "y"])
jcase("names/repeated/left-column/anti", "nl", "nr", "anti", left_on=["a", "a"], right_on=["a", "y"])
jcase("names/repeated/left-column/full/coalesce=true", "nl", "nr", "full",
      left_on=["a", "a"], right_on=["a", "y"], coalesce=True)
jcase("names/repeated/left-column/right", "nl", "nr", "right", left_on=["a", "a"], right_on=["a", "y"])
jcase("names/repeated/right-column/inner", "nl", "nr", "inner", left_on=["a", "x"], right_on=["y", "y"])
# (a full join with coalesce=True and one right column used for two keys is left
# out: polars then also drops the next column of the right frame, see
# known-diffs/join.md)
jcase("names/repeated/right-column/left", "nl", "nr", "left", left_on=["a", "x"], right_on=["y", "y"])
jcase("names/repeated/pair", "nl", "nr", "left", left_on=["a", "a"], right_on=["a", "a"])
jcase("names/repeated/pair-three", "nl", "nr", "left", left_on=["a", "x", "a"], right_on=["a", "y", "a"])
jcase("names/repeated/pair-on", "nl", "nr_x", "inner", on=["a", "x", "a"])
jcase("names/repeated/pair-other-names", "nl", "nr", "inner", left_on=["x", "x"], right_on=["y", "y"])

# ---------------------------------------------------------------------------
# 4. key expressions
# ---------------------------------------------------------------------------

A = "a"
REM = {"rem": [A, 2]}
for how in HOWS:
    jcase(f"expr/rem/{how}", "nl", "nr", how, left_on=[REM], right_on=[REM])
    jcase(f"expr/rem/{how}/coalesce=true", "nl", "nr", how, left_on=[REM], right_on=[REM], coalesce=True)
    jcase(f"expr/rem-left-only/{how}", "nl", "nr", how, left_on=[REM], right_on=[A])
    jcase(f"expr/rem-right-only/{how}", "nl", "nr", how, left_on=[A], right_on=[REM])
    jcase(f"expr/mixed/{how}", "nl", "nr", how, left_on=[A, {"rem": ["x", 7]}],
          right_on=[A, {"rem": ["y", 7]}])
jcase("expr/mixed/full/coalesce=true", "nl", "nr", "full", left_on=[A, {"rem": ["x", 7]}],
      right_on=[A, {"rem": ["y", 7]}], coalesce=True)
jcase("expr/rem/ne", "nl", "nr", "inner", left_on=[REM], right_on=[REM], nulls_equal=True)
jcase("expr/rem-pair-names", "nl", "nr", "left", left_on=[{"rem": [A, 2]}, {"rem": [A, 3]}], right_on=["a", "y"])
jcase("expr/rem-repeated", "nl", "nr", "left", left_on=[{"rem": [A, 2]}, {"rem": [A, 3]}],
      right_on=[{"rem": [A, 2]}, {"rem": [A, 3]}])
for how in ("inner", "left", "full"):
    jcase(f"expr/cast/{how}", "nl", "nr", how, left_on=[{"cast": [A, "f64"]}],
          right_on=[{"cast": [A, "f64"]}])
    jcase(f"expr/cast-narrow/{how}", "nl", "nr", how, left_on=[{"cast": [A, "i32"]}],
          right_on=[A])
    jcase(f"expr/lit/{how}", "nl", "nr", how, left_on=[{"lit": 1}], right_on=[{"lit": 1}])
for how in ("inner", "left", "right", "full", "semi", "anti"):
    jcase(f"expr/lit-vs-column/{how}", "nl", "nr", how, left_on=[{"lit": 1}], right_on=[A])
    jcase(f"expr/sum/{how}", "nl", "nr", how, left_on=[{"sum": A}], right_on=[{"sum": A}])
    jcase(f"expr/len/{how}", "nl", "nr", how, left_on=[{"len": A}], right_on=[{"len": A}])
jcase("expr/sum-empty-left", "nl0", "nr", "left", left_on=[{"sum": A}], right_on=[{"sum": A}])
jcase("expr/sum-empty-left/full", "nl0", "nr", "full", left_on=[{"sum": A}], right_on=[{"sum": A}])
jcase("expr/sum-empty-right/left", "nl", "nr0", "left", left_on=[{"sum": A}], right_on=[{"sum": A}])
jcase("expr/lit-empty-left/left", "nl0", "nr", "left", left_on=[{"lit": 1}], right_on=[{"lit": 1}])
jcase("expr/lit-empty-left/full", "nl0", "nr", "full", left_on=[{"lit": 1}], right_on=[{"lit": 1}])
jcase("expr/lit-empty-right/left", "nl", "nr0", "left", left_on=[{"lit": 1}], right_on=[{"lit": 1}])
jcase("expr/lit-two-keys-semi", "nl", "nr", "semi", left_on=[{"lit": 1}, A], right_on=[{"lit": 1}, A])
jcase("expr/lit-anti-no-match", "nl", "nr", "anti", left_on=[{"lit": 1}], right_on=[{"lit": 2}])
for nm, e in (("fill_null", {"fill_null": [A, 0]}), ("abs", {"abs": A}),
              ("is_null", {"is_null": A}), ("add", {"add": [A, 1]})):
    jcase(f"expr/{nm}/inner", "nl", "nr", "inner", left_on=[e], right_on=[e] if nm != "add" else [A])
jcase("expr/fill_null/full", "nl", "nr", "full", left_on=[{"fill_null": [A, 0]}], right_on=[A])
jcase("expr/is_null-vs-column", "nl", "nr", "inner", left_on=[{"is_null": A}], right_on=[A])
jcase("expr/add-on-text", "nl", "nr", "inner", left_on=[{"add": ["b", 1]}], right_on=[A])
jcase("expr/add-on-text-right", "nl", "nr", "inner", left_on=[A], right_on=[{"add": ["b", 1]}])
jcase("expr/alias/same-name", "nl", "nr", "left", left_on=[{"alias": [A, "q"]}], right_on=[{"alias": [A, "q"]}])
jcase("expr/alias/on", "nl", "nr", "left", on=[{"alias": [A, "q"]}])
jcase("expr/alias/inside", "nl", "nr", "left", left_on=[{"add": [{"alias": [A, "q"]}, 1]}], right_on=[A])
jcase("expr/alias/right-only", "nl", "nr", "left", left_on=[A], right_on=[{"alias": [A, "q"]}])
jcase("expr/alias/literal", "nl", "nr", "left", left_on=[{"alias": [{"lit": 1}, "k"]}], right_on=[{"lit": 1}])
jcase("expr/cum_sum", "nl", "nr", "inner", left_on=[{"cum_sum": "x"}], right_on=[{"cum_sum": "y"}])
jcase("expr/cum_sum/left-only", "nl", "nr", "left", left_on=[{"cum_sum": "x"}], right_on=["y"])
jcase("expr/cum_sum/right-only", "nl", "nr", "left", left_on=["x"], right_on=[{"cum_sum": "y"}])
# selectors
jcase("expr/all/subset", "nl_a", "nr", "left", left_on=[{"all": True}], right_on=[A])
jcase("expr/all/both", "nl", "nl", "left", left_on=[{"all": True}], right_on=[{"all": True}])
jcase("expr/all/semi", "nl", "nl", "semi", on=[{"all": True}])
jcase("expr/cols/both", "nl", "nl", "left", on=[{"cols": ["a", "b"]}])
jcase("expr/cols/diff-names", "nl", "nr", "left", left_on=[{"cols": ["a", "b"]}], right_on=[{"cols": ["a", "b"]}])
jcase("expr/cols/diff-types", "nl", "nr", "left", left_on=[{"cols": ["a", "b"]}], right_on=[{"cols": ["a", "y"]}])
jcase("expr/cols/width-left-2-right-1", "nl", "nr", "left", left_on=[{"cols": ["a", "b"]}], right_on=[A])
jcase("expr/cols/width-left-1-right-2", "nl", "nr", "left", left_on=[A], right_on=[{"cols": ["a", "b"]}])
jcase("expr/cols/width-3-2", "nl", "nr", "left", left_on=[{"all": True}], right_on=[{"cols": ["a", "b"]}])
jcase("expr/cols/width-2-3", "nl_a", "nr", "left", left_on=[{"cols": ["a", "a"]}], right_on=[{"all": True}])
jcase("expr/cols/missing-left", "nl", "nr", "left", left_on=[{"cols": ["a", "zz"]}], right_on=[{"cols": ["a", "y"]}])
jcase("expr/cols/missing-right", "nl", "nr", "left", left_on=[{"cols": ["a", "y"]}], right_on=[{"cols": ["a", "zz"]}])
jcase("expr/cols/missing-both", "nl", "nr", "left", left_on=[{"cols": ["a", "zz1"]}], right_on=[{"cols": ["a", "zz2"]}])
jcase("expr/cols/missing-left-plain-right", "nl", "nr", "left", left_on=[{"cols": ["a", "zz1"]}], right_on=["a"])
jcase("expr/cols/duplicate-names", "nl", "nr", "left", left_on=[{"cols": ["a", "a"]}], right_on=[{"cols": ["a", "a"]}])
jcase("expr/zero/left", "z0", "nr", "left", left_on=[{"all": True}], right_on=[A])
jcase("expr/zero/right", "nl", "z0", "left", left_on=[A], right_on=[{"all": True}])
jcase("expr/zero/both", "z0", "z0", "left", on=[{"all": True}])
jcase("expr/zero/left-and-right-all", "z0", "nr", "left", left_on=[{"all": True}], right_on=[{"all": True}])
jcase("expr/zero/right-and-left-all", "nl", "z0", "left", left_on=[{"all": True}], right_on=[{"all": True}])
jcase("expr/zero/left-vs-missing-in-right-cols", "z0", "nr", "left", left_on=[{"all": True}],
      right_on=[{"cols": ["a", "zz"]}])
jcase("expr/zero/missing-in-left-cols-vs-right", "nl", "z0", "left", left_on=[{"cols": ["a", "zz"]}],
      right_on=[{"all": True}])
jcase("expr/zero/semi", "z0", "nr", "semi", on=[{"all": True}])

# ---------------------------------------------------------------------------
# 5. the arguments
# ---------------------------------------------------------------------------

jcase("args/on-and-left_on", "nl", "nr", on=["a"], left_on=["a"])
jcase("args/on-and-right_on", "nl", "nr", on=["a"], right_on=["a"])
jcase("args/on-and-both", "nl", "nr", on=["a"], left_on=["a"], right_on=["a"])
jcase("args/none", "nl", "nr")
jcase("args/none/left", "nl", "nr", "left")
jcase("args/none/semi", "nl", "nr", "semi")
jcase("args/left_on-only", "nl", "nr", left_on=["a"])
jcase("args/right_on-only", "nl", "nr", right_on=["a"])
jcase("args/left_on-empty-only", "nl", "nr", left_on=[])
jcase("args/count-2-1", "nl", "nr", left_on=["a", "x"], right_on=["a"])
jcase("args/count-1-2", "nl", "nr", left_on=["a"], right_on=["a", "y"])
jcase("args/count-0-1", "nl", "nr", left_on=[], right_on=["a"])
jcase("args/count-1-0", "nl", "nr", left_on=["a"], right_on=[])
jcase("args/empty-both", "nl", "nr", left_on=[], right_on=[])
jcase("args/empty-on", "nl", "nr", on=[])
jcase("args/empty-on/cross", "nl", "nr", "cross", on=[])
jcase("args/cross-on", "nl", "nr", "cross", on=["a"])
jcase("args/cross-left_on-right_on", "nl", "nr", "cross", left_on=["a"], right_on=["a"])
jcase("args/cross-left_on-only", "nl", "nr", "cross", left_on=["a"])
jcase("args/cross-on-validate", "nl", "nr", "cross", on=["a"], validate="1:1")
jcase("args/missing-on", "nl", "nr", on=["zz"])
jcase("args/missing-left", "nl", "nr", left_on=["zz"], right_on=["a"])
jcase("args/missing-right", "nl", "nr", left_on=["a"], right_on=["zz"])
jcase("args/missing-both", "nl", "nr", left_on=["zz"], right_on=["yy"])
jcase("args/on-only-in-left", "nl", "nr", on=["x"])
jcase("args/on-only-in-right", "nl", "nr", on=["y"])
jcase("args/key-type-mismatch", "nl", "nr", left_on=["b"], right_on=["a"])
jcase("args/key-type-mismatch-expr", "nl", "nr", left_on=[{"add": ["x", 1]}], right_on=["b"])

# ---------------------------------------------------------------------------
# 6. which error comes first
# ---------------------------------------------------------------------------

Z = "zz"
CS = {"cum_sum": "x"}
ORDER = [
    ("count+missing", dict(left_on=[Z, "x"], right_on=["a"])),
    ("count+alias", dict(left_on=[{"alias": [A, "q"]}, "x"], right_on=["a"])),
    ("count+validate-right", dict(left_on=["a", "x"], right_on=["a"], validate="1:1", how="right")),
    ("count+validate-semi", dict(left_on=["a", "x"], right_on=["a"], validate="1:m", how="semi")),
    ("empty+validate-right", dict(left_on=[], right_on=[], validate="1:1", how="right")),
    ("validate-right+missing", dict(left_on=[Z], right_on=["a"], validate="1:1", how="right")),
    ("validate-right+dtype", dict(left_on=["b"], right_on=["a"], validate="1:1", how="right")),
    ("validate-semi+dtype", dict(left_on=["b"], right_on=["a"], validate="1:1", how="semi")),
    ("validate-anti+missing", dict(left_on=[Z], right_on=["a"], validate="m:1", how="anti")),
    ("validate-inner+missing", dict(left_on=[Z], right_on=["a"], validate="1:1")),
    ("validate-inner+dtype", dict(left_on=["b"], right_on=["a"], validate="1:1")),
    ("alias+missing", dict(left_on=[Z, {"alias": [A, "q"]}], right_on=["a", "a"])),
    ("missing+alias", dict(left_on=[{"alias": [A, "q"]}, Z], right_on=["a", "a"])),
    ("alias-left+missing-right", dict(left_on=[{"alias": [A, "q"]}], right_on=[Z])),
    ("alias-right+missing-left", dict(left_on=[Z], right_on=[{"alias": [A, "q"]}])),
    ("alias+nonelementwise", dict(left_on=[{"alias": [A, "q"]}, CS], right_on=["a", "y"])),
    ("nonelementwise+alias", dict(left_on=[CS, {"alias": [A, "q"]}], right_on=["a", "y"])),
    ("alias+dtype", dict(left_on=[{"alias": [A, "q"]}], right_on=["b"])),
    ("alias+selector-error", dict(left_on=[{"cols": ["a", "zz"]}], right_on=[{"alias": [A, "q"]}])),
    ("selector-error+alias-left", dict(left_on=[{"alias": [A, "q"]}], right_on=[{"cols": ["a", "zz"]}])),
    ("alias+width", dict(left_on=[{"cols": ["a", "x"]}], right_on=[{"alias": [A, "q"]}])),
    ("alias+zero", dict(left_on=[{"all": True}], right_on=[{"alias": [A, "q"]}], left="z0")),
    ("selector-left+selector-right", dict(left_on=[{"cols": ["a", "zz1"]}], right_on=[{"cols": ["a", "zz2"]}])),
    ("selector-right+plain-left", dict(left_on=[Z], right_on=[{"cols": ["a", "zz"]}])),
    ("selector-right-missing-x", dict(left_on=[Z], right_on=[{"cols": ["a", "x"]}])),
    ("width+plain-missing", dict(left_on=[{"cols": ["a", "x"]}], right_on=[Z])),
    ("width+nonelementwise", dict(left_on=[{"cols": ["a", "x"]}], right_on=[{"cum_sum": "a"}])),
    ("width+dtype", dict(left_on=[{"cols": ["a", "x"]}], right_on=["b"])),
    ("width-all-vs-plain", dict(left_on=[{"all": True}], right_on=["a"])),
    ("zero-left+selector-right", dict(left_on=[{"all": True}], right_on=[{"cols": ["a", "zz"]}], left="z0")),
    ("selector-left+zero-right", dict(left_on=[{"cols": ["a", "zz"]}], right_on=[{"all": True}], right="z0")),
    ("missing-left+missing-right", dict(left_on=["zz1"], right_on=["zz2"])),
    ("missing-pair2-left-vs-pair1-right", dict(left_on=["a", "zz1"], right_on=["zz2", "y"])),
    ("missing-pair1-left-vs-pair2-right", dict(left_on=["zz1", "a"], right_on=["a", "zz2"])),
    ("missing+dtype", dict(left_on=["a", Z], right_on=["b", "y"])),
    ("missing+dup", dict(left_on=[Z, Z], right_on=["a", "a"])),
    ("missing-right+dup", dict(left_on=["a", "a"], right_on=[Z, Z])),
    ("missing+arith", dict(left_on=[{"add": ["b", 1]}, Z], right_on=["a", "a"])),
    ("arith+missing", dict(left_on=[Z, {"add": ["b", 1]}], right_on=["a", "a"])),
    ("arith-left+missing-right", dict(left_on=[{"add": ["b", 1]}], right_on=[Z])),
    ("arith-right+missing-left", dict(left_on=[Z], right_on=[{"add": ["b", 1]}])),
    ("missing+nonelementwise", dict(left_on=[CS, Z], right_on=["a", "a"])),
    ("nonelementwise+missing", dict(left_on=[Z, CS], right_on=["a", "a"])),
    ("arith+dtype", dict(left_on=[{"add": ["b", 1]}, "a"], right_on=["a", "b"])),
    ("arith-right+dtype-left", dict(left_on=["b"], right_on=[{"add": ["b", 1]}])),
    ("arith-left+arith-right", dict(left_on=[{"add": ["b", 1]}], right_on=[{"add": ["b", 2]}])),
    ("arith-left-pair2+arith-right-pair1", dict(left_on=["a", {"add": ["b", 1]}], right_on=[{"add": ["b", 2]}, "a"])),
    ("arith-left-pair1+arith-right-pair1", dict(left_on=[{"add": ["b", 1]}, "a"], right_on=["a", {"add": ["b", 2]}])),
    ("arith-right-only", dict(left_on=["a"], right_on=[{"add": ["b", 2]}])),
    ("arith+dup", dict(left_on=[{"add": ["b", 1]}, {"add": ["b", 1]}], right_on=["a", "a"])),
    ("arith+nonelementwise", dict(left_on=[CS], right_on=[{"add": ["b", 1]}])),
    ("arith+alias", dict(left_on=[{"add": ["b", 1]}, {"alias": [A, "q"]}], right_on=["a", "a"])),
    ("dup+dtype", dict(left_on=["a", "a"], right_on=["a", "a"], left="nl_str")),
    ("dup+nonelementwise", dict(left_on=["a", "a", CS], right_on=["a", "a", "y"])),
    ("nonelementwise+dup", dict(left_on=[CS, "a", "a"], right_on=["y", "a", "a"])),
    ("dup-then-nonelementwise-pair", dict(left_on=["a", CS], right_on=["a", "y"])),
    ("dtype+nonelementwise", dict(left_on=[CS], right_on=["b"])),
    ("dtype-pair2+nonelementwise-pair1", dict(left_on=[CS, "b"], right_on=["y", "a"])),
    ("dtype-first-pair", dict(left_on=["a", "b"], right_on=["b", "a"])),
    ("dtype+dup-names", dict(left_on=["a", "b"], right_on=["a", "a"])),
    ("dtype+suffix-collision", dict(left_on=["b"], right_on=["a"], left="nl_b_right")),
    ("nonelementwise+suffix-collision", dict(left_on=[CS], right_on=["y"], left="nl_b_right")),
    ("suffix-collision+validate-fail", dict(on=["a"], validate="1:1", left="nl_b_right")),
    ("empty-suffix+validate-fail", dict(on=["a"], validate="1:1", suffix="")),
    ("right-has-suffixed+validate-fail", dict(on=["a"], validate="1:1", right="nr_b_right")),
    ("empty-suffix+validate-right", dict(on=["a"], validate="1:1", how="right", suffix="")),
    ("cross-suffix-collision", dict(how="cross", left="nl_b_right")),
]
for name, kw in ORDER:
    kw = dict(kw)
    left = kw.pop("left", "nl")
    right = kw.pop("right", "nr")
    how = kw.pop("how", "inner")
    jcase(f"order/{name}", left, right, how, **kw)

DD = lambda n: {"add": ["d", n]}
DATE_ORDER = [
    ("left", dict(left_on=[DD(1)], right_on=["a"])),
    ("right", dict(left_on=["a"], right_on=[DD(1)])),
    ("both", dict(left_on=[DD(1)], right_on=[DD(2)])),
    ("alias", dict(left_on=[{"alias": ["d", "q"]}], right_on=["a"])),
    ("pair2-left+pair1-right", dict(left_on=["a", DD(1)], right_on=[DD(2), "a"])),
    ("pair1-left+pair2-right", dict(left_on=[DD(1), "a"], right_on=["a", DD(2)])),
    ("+missing", dict(left_on=[DD(1), Z], right_on=["a", "a"])),
    ("missing+", dict(left_on=[Z, DD(1)], right_on=["a", "a"])),
    ("left+missing-right", dict(left_on=[DD(1)], right_on=[Z])),
    ("right+missing-left", dict(left_on=[Z], right_on=[DD(1)])),
    ("+dup", dict(left_on=[DD(1), DD(1)], right_on=["a", "a"])),
    ("+dtype", dict(left_on=[DD(1), "a"], right_on=["a", "d"])),
    ("right+dtype", dict(left_on=["a"], right_on=[DD(1)])),
    ("+nonelementwise", dict(left_on=[CS], right_on=[DD(1)])),
    ("nonelementwise-right+left", dict(left_on=[DD(1)], right_on=[{"cum_sum": "y"}])),
    ("+alias", dict(left_on=[DD(1), {"alias": ["a", "q"]}], right_on=["a", "a"])),
    ("+validate-right", dict(left_on=[DD(1)], right_on=["a"], validate="1:1", how="right")),
    ("dtype-date-vs-int", dict(left_on=["d"], right_on=["a"])),
    ("nonelementwise+dtype", dict(left_on=[CS], right_on=["d"])),
    ("ok-date-keys", dict(left_on=["d"], right_on=["d"])),
]
for name, kw in DATE_ORDER:
    kw = dict(kw)
    how = kw.pop("how", "inner")
    jcase(f"order-date/{name}", "dl", "dr", how, **kw)

# a key that is not elementwise: polars finds the type of the key from the
# schema first (the cumulative sum of a text is Int64, of a date a Date), so a
# type mismatch is reported before "must be elementwise", even where the
# operation refuses the type when it runs
SEQ_ORDER = [
    ("text-vs-int/left", "nl", "nr", dict(left_on=[{"cum_sum": "b"}], right_on=["a"])),
    ("text-vs-int/right", "nl", "nr", dict(left_on=["a"], right_on=[{"cum_sum": "b"}])),
    ("text-vs-text", "nl", "nr", dict(left_on=[{"cum_sum": "b"}], right_on=["b"])),
    ("text-vs-text/right", "nl", "nr", dict(left_on=["b"], right_on=[{"cum_sum": "b"}])),
    ("text-both", "nl", "nr", dict(left_on=[{"cum_sum": "b"}], right_on=[{"cum_sum": "b"}])),
    ("date-vs-text", "dl", "nr", dict(left_on=[{"cum_sum": "d"}], right_on=["b"])),
    ("date-vs-date", "dl", "dr", dict(left_on=[{"cum_sum": "d"}], right_on=["d"])),
    ("date-vs-int", "dl", "dr", dict(left_on=[{"cum_sum": "d"}], right_on=["a"])),
    ("int-vs-text", "nl", "nr", dict(left_on=[{"cum_sum": "x"}], right_on=["b"])),
    ("text-second-key", "nl", "nr",
     dict(left_on=["a", {"cum_sum": "b"}], right_on=["a", "b"])),
    ("text-first-key", "nl", "nr",
     dict(left_on=[{"cum_sum": "b"}, "a"], right_on=["b", "a"])),
]
for name, lt, rt, kw in SEQ_ORDER:
    for how in ("inner", "semi"):
        jcase(f"order-seq/{name}/{how}", lt, rt, how, **kw)

# ---------------------------------------------------------------------------
# 7. validate
# ---------------------------------------------------------------------------

VALIDATES = ["m:m", "1:m", "m:1", "1:1"]
for v in VALIDATES:
    for how in HOWS + ["cross"]:
        kw = {} if how == "cross" else {"on": ["a"]}
        jcase(f"validate/{v}/{how}/unique-left-dup-right", "nl", "nr", how, validate=v, **kw)
        jcase(f"validate/{v}/{how}/dup-left-unique-right", "nr", "nl", how, validate=v, **kw)
    for how in ("inner", "left", "full"):
        jcase(f"validate/{v}/{how}/unique-both", "u_l", "u_r", how, on=["k"], validate=v)
for v in ("1:1", "1:m", "m:1"):
    for how in ("inner", "left"):
        jcase(f"validate/{v}/{how}/unmatched-dups-right", "d_l", "d_r", how, on=["k"], validate=v)
        jcase(f"validate/{v}/{how}/unmatched-dups-left", "d_r", "d_l", how, on=["k"], validate=v)
    jcase(f"validate/{v}/inner/one-to-many", "u_l", "om_r", on=["k"], validate=v)
    jcase(f"validate/{v}/inner/many-to-one", "om_r", "u_l", on=["k"], validate=v)
    for ne in (False, True):
        tag = f"ne={str(ne).lower()}"
        jcase(f"validate/{v}/inner/nulls/dups-both/{tag}", "n_l", "n_r", on=["k"], validate=v, nulls_equal=ne)
        jcase(f"validate/{v}/inner/nulls/dups-left/{tag}", "n_l", "n_u", on=["k"], validate=v, nulls_equal=ne)
        jcase(f"validate/{v}/inner/nulls/dups-right/{tag}", "n_u", "n_l", on=["k"], validate=v, nulls_equal=ne)
    for ne in (False, True):
        tag = f"ne={str(ne).lower()}"
        jcase(f"validate/{v}/inner/two-keys-partial-null/{tag}", "mk_l", "mk_r", on=["a", "b"],
              validate=v, nulls_equal=ne)
        jcase(f"validate/{v}/inner/two-keys-partial-null-right/{tag}", "mk_r", "mk_l", on=["a", "b"],
              validate=v, nulls_equal=ne)
        jcase(f"validate/{v}/inner/two-keys-one-column-repeats/{tag}", "mk2_l", "mk_r", on=["a", "b"],
              validate=v, nulls_equal=ne)
jcase("validate/1:1/inner/empty", "nl0", "nr0", on=["a"], validate="1:1")
jcase("validate/1:1/left/empty-right", "nl", "nr0", "left", on=["a"], validate="1:1")

# ---------------------------------------------------------------------------
# 8. empty sides
# ---------------------------------------------------------------------------

for how in HOWS:
    jcase(f"empty/left/{how}", "nl0", "nr", how, on=["a"])
    jcase(f"empty/right/{how}", "nl", "nr0", how, on=["a"])
    jcase(f"empty/both/{how}", "nl0", "nr0", how, on=["a"])
    jcase(f"empty/left/{how}/ne=true", "nl0", "nr", how, on=["a"], nulls_equal=True)
for co in (True, False):
    for how in ("inner", "left", "right", "full"):
        tag = str(co).lower()
        jcase(f"empty/left/{how}/coalesce={tag}", "nl0", "nr", how, on=["a"], coalesce=co)
        jcase(f"empty/right/{how}/coalesce={tag}", "nl", "nr0", how, on=["a"], coalesce=co)
jcase("empty/left/cross", "nl0", "nr", "cross")
jcase("empty/right/cross", "nl", "nr0", "cross")
jcase("empty/both/cross", "nl0", "nr0", "cross")
jcase("empty/left/full/two-keys/coalesce=true", "nl0", "nr", "full", on=["a", "b"], coalesce=True)
jcase("empty/left/expr", "nl0", "nr", "left", left_on=[REM], right_on=[REM])
jcase("empty/right/expr", "nl", "nr0", "left", left_on=[REM], right_on=[REM])
jcase("empty/typed-null-keys/inner", "nl0", "nr", "inner", left_on=[{"cast": [A, "i32"]}], right_on=[A])

# ---------------------------------------------------------------------------
# 9. several keys with nulls
# ---------------------------------------------------------------------------

for how in HOWS:
    for ne in (False, True):
        jcase(f"multi/{how}/ne={str(ne).lower()}", "m_l", "m_r", how, on=["a", "b"], nulls_equal=ne)
for ne in (False, True):
    jcase(f"multi/full/coalesce=true/ne={str(ne).lower()}", "m_l", "m_r", "full", on=["a", "b"],
          coalesce=True, nulls_equal=ne)

# ---------------------------------------------------------------------------
# 10. order of the output
# ---------------------------------------------------------------------------

for how in HOWS:
    jcase(f"order-of-rows/{how}", "o_l", "o_r", how, on=["k"])
jcase("order-of-rows/full/coalesce=true", "o_l", "o_r", "full", on=["k"], coalesce=True)
jcase("order-of-rows/cross", "c_l", "c_r", "cross")
for how in HOWS:
    jcase(f"unique/{how}", "u_l", "u_r", how, on=["k"])
    jcase(f"one-to-many/{how}", "u_l", "om_r", how, on=["k"])
    jcase(f"many-to-one/{how}", "om_r", "u_l", how, on=["k"])

# ---------------------------------------------------------------------------

doc = {
    "tables": {name: encode_frame(df) for name, df in TABLES.items()},
    "cases": CASES,
}
emit("join", doc, compact=True)
print(f"{len(CASES)} cases, {len(TABLES)} tables")
