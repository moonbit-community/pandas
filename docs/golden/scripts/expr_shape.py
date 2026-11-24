"""Generates the golden data of the expression methods that change the length
or the order of a column (`sort`, `arg_sort`, `sort_by`, `head`, `tail`,
`slice`, `unique`, `drop_nulls`, `filter`), of `any` / `all`, of the
trigonometric functions and of `sum_horizontal` / `min_horizontal` /
`max_horizontal`, plus the `Series` methods `is_sorted`, `any`, `all`,
`gather_every`, `sin` ... `arctan` and `DataFrame::gather_every`
(docs/golden/expr_shape.json, src/pl/golden_expr_shape_data_test.mbt) and the
MoonBit expressions of every expression case
(src/pl/expr_shape_cases_test.mbt).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/expr_shape.py

It builds on `expr_seq.py`, whose part before its first case is executed here
(and so on `expr_agg.py` and `expr.py`): tables, expression trees, renderers,
`case`, the meaning of `result`, `error`, `restricted`, `known_diff` are the
same (see those docstrings and docs/golden/known-diffs/expr_shape.md).

The file is `{"tables", "cases", "series_cases", "frame_cases"}` (compact
layout, only the tables the cases use). `cases` are expression cases (a table,
`select` or `with_columns`, the expressions); a case with `"ulp": true`
contains a trigonometric function and is compared up to a few units in the last
place (the last bit of `sin` and friends is the C library's). `series_cases`
are `Series` method calls (`series`, `method`, `args`, `result` or `error` +
`message`); `frame_cases` are `DataFrame.gather_every` calls.

Extra tables: `dup` (duplicates of every type), `sk` (sort keys: ties, nulls,
NaN and an `id` column that breaks the ties), `an` (Boolean and number columns
for `any` / `all`), `hz` (columns of every type for the horizontal functions,
with NaN and `-0.0`).

Nodes added to the trees:
  ("sort", x, desc, nl)  ("arg_sort", x, desc, nl)
  ("sort_by", x, [keys], desc, nl)   desc: None, a bool or a list of bools
  ("head", x, n)  ("tail", x, n)  ("slice", x, offset, length | None)
  ("unique", x, stable)  ("drop_nulls", x)  ("filter", x, predicate)
  ("any_vals", x, ignore_nulls)  ("all_vals", x, ignore_nulls)
  ("trig", fn, x)        fn: sin cos tan arcsin arccos arctan
  ("horiz", op, [xs], ignore_nulls)   op: sum min max
"""
import hashlib
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

# -- the shared part of expr_seq.py (which shares those of expr_agg.py and expr.py) --
_src = open(os.path.join(HERE, "expr_seq.py"), encoding="utf-8").read()
_prefix = _src[: _src.index("DTS = list(Q)")]
S = {"__name__": "expr_seq_prefix", "__file__": os.path.join(HERE, "expr_seq.py")}
exec(compile(_prefix, os.path.join(HERE, "expr_seq.py"), "exec"), S)
A = S["A"]
_ns = S["_ns"]

pl = S["pl"]
emit = S["emit"]
encode_series = S["encode_series"]
series_from_spec = S["series_from_spec"]
encode_frame = S["encode_frame"]
to_ours = S["to_ours"]
_repo_root = S["_repo_root"]
TABLES = S["TABLES"]
CASES = S["CASES"]
MB = S["MB"]
col, cols, all_ = S["col"], S["cols"], S["all_"]
li, lf, ls, lb, lit = S["li"], S["lf"], S["ls"], S["lb"], S["lit"]
bin_, neg, not_, alias, cast = S["bin_"], S["neg"], S["not_"], S["alias"], S["cast"]
is_null, is_not_null = S["is_null"], S["is_not_null"]
agg, fill, fn, isin = S["agg"], S["fill"], S["fn"], S["isin"]
when_ = S["when_"]
shift, cum, rank, reverse = S["shift"], S["cum"], S["rank"], S["reverse"]
st, dtf = S["st"], S["dtf"]
N = S["N"]
mb_str, mb_float, mb_i64, mb_i32 = S["mb_str"], S["mb_float"], S["mb_i64"], S["mb_i32"]
py_float = S["py_float"]
nan, inf = S["nan"], S["inf"]
I64_MAX, I64_MIN = S["I64_MAX"], S["I64_MIN"]
VARIANTS = S["VARIANTS"]
PY_ERRORS = S["PY_ERRORS"]
DT_OF = S["DT_OF"]
QDF = S["QDF"]
_seq_case = S["case"]
_prev = {k: S[k] for k in ("to_pl", "to_py", "to_mb", "pure_weak_ext")}
_prev_strengthen = _ns["strengthen"]
POLARS_DTYPES = _ns["POLARS_DTYPES"]
pure_weak_old = S["pure_weak_ext"]
strong_all = _ns["strong_all"]

# -- tables --------------------------------------------------------------------------
DUP = {
    "i32": [1, 2, 1, None, 2, None, 3, 1],
    "i64": [5, 5, None, 7, None, 5, 7, 0],
    "f32": [0.5, nan, 0.5, None, nan, 0.0, -0.0, None],
    "f64": [nan, 0.0, -0.0, nan, 1.0, 1.0, None, 0.0],
    "s": ["a", "b", "a", None, "B", "b", None, ""],
    "b": [True, False, True, None, None, False, True, True],
    "d": [0, 1, 0, None, 1, None, -5, 0],
    "dt": [7, None, 7, 8, None, 8, 7, 0],
    "n": [None] * 8,
}
TABLES["dup"] = pl.DataFrame([series_from_spec(c, DT_OF[c], v) for c, v in DUP.items()])
SK = {
    "id": [0, 1, 2, 3, 4, 5, 6, 7],
    "a": [3, None, 1, 2, 3, None, 2, 1],
    "s": ["b", None, "a", "b", "c", "a", None, "b"],
    "f": [2.0, nan, None, -0.0, 0.0, 1.5, nan, None],
    "bo": [True, None, False, True, False, None, True, False],
    "x": [10, 20, 30, 40, 50, 60, 70, 80],
}
SKDT = {"id": "i64", "a": "i64", "s": "str", "f": "f64", "bo": "bool", "x": "i32"}
TABLES["sk"] = pl.DataFrame([series_from_spec(c, SKDT[c], v) for c, v in SK.items()])
AN = {
    "t": [True, True, True],
    "f": [False, False, False],
    "m": [True, False, True],
    "tn": [True, None, True],
    "fn": [False, None, False],
    "tfn": [True, False, None],
    "n1": [None, None, None],
    "i": [0, 1, None],
    "iz": [0, 0, 0],
    "i1": [1, 2, 3],
    "fl": [0.0, nan, None],
    "fnan": [nan, nan, nan],
    "fz": [-0.0, 0.0, -0.0],
    "f32": [1.5, 0.0, None],
}
ANDT = {"t": "bool", "f": "bool", "m": "bool", "tn": "bool", "fn": "bool", "tfn": "bool",
        "n1": "null", "i": "i64", "iz": "i32", "i1": "i32", "fl": "f64", "fnan": "f64",
        "fz": "f64", "f32": "f32"}
TABLES["an"] = pl.DataFrame([series_from_spec(c, ANDT[c], v) for c, v in AN.items()])
HZ = {
    "a": [nan, 1.0, nan, None, -0.0, 0.0, 2.0],
    "b": [1.0, nan, nan, nan, 0.0, -0.0, None],
    "n": [None] * 7,
    "bo": [True, False, None, None, True, False, True],
    "bo2": [True, True, None, False, None, False, True],
    "s": ["a", None, "c", "d", None, "f", "g"],
    "s2": ["x", "y", None, "w", None, "u", None],
    "i": [1, 2, 3, 4, 5, 6, None],
    "i32": [2147483647, -2147483648, 5, None, 0, 1, None],
    "f32": [0.5, nan, None, -inf, 3.0e38, 0.0, -0.0],
    "d": [0, 1, 2, 3, 19782, -25567, None],
    "dt": [0, 1, 2, 3, 1709210096123456, -1, None],
}
HZDT = {"a": "f64", "b": "f64", "n": "null", "bo": "bool", "bo2": "bool", "s": "str",
        "s2": "str", "i": "i64", "i32": "i32", "f32": "f32", "d": "date", "dt": "datetime[μs]"}
TABLES["hz"] = pl.DataFrame([series_from_spec(c, HZDT[c], v) for c, v in HZ.items()])
TABLES["uo"] = pl.DataFrame([series_from_spec("x", "str", ["\uff61", "\U0001F600", "a", None]),
                           series_from_spec("y", "str", ["\U0001F600", "\uff61", "b", "c"])])
TABLES["ng"] = pl.DataFrame([series_from_spec("x", "f32", [-0.5, -1.0]), series_from_spec("y", "f64", [-0.5, 0.0]),
                           series_from_spec("z", "i32", [-3, 0]), series_from_spec("w", "i64", [-7, -1])])

# -- constructors ----------------------------------------------------------------------
sort_ = lambda x, desc=False, nl=False: N(("sort", x, desc, nl))
arg_sort = lambda x, desc=False, nl=False: N(("arg_sort", x, desc, nl))
sort_by = lambda x, keys, desc=None, nl=False: N(("sort_by", x, list(keys), desc, nl))
head = lambda x, n=10: N(("head", x, n))
tail = lambda x, n=10: N(("tail", x, n))
slice_ = lambda x, off, length=None: N(("slice", x, off, length))
unique = lambda x, stable=False: N(("unique", x, stable))
drop_nulls = lambda x: N(("drop_nulls", x))
filter_ = lambda x, p: N(("filter", x, p))
any_ = lambda x, ig=True: N(("any_vals", x, ig))
all_fn = lambda x, ig=True: N(("all_vals", x, ig))
trig = lambda f, x: N(("trig", f, x))
horiz = lambda op, xs, ig=True: N(("horiz", op, list(xs), ig))
NEW3 = {"sort", "arg_sort", "sort_by", "head", "tail", "slice", "unique", "drop_nulls",
        "filter", "any_vals", "all_vals", "trig", "horiz"}
TRIGS = ["sin", "cos", "tan", "arcsin", "arccos", "arctan"]


def desc_list(desc, n):
    """Python `descending` of `sort_by` as the list the library takes."""
    if desc is None or desc is False:
        return None
    if desc is True:
        return [True] * n
    return list(desc)


def to_pl(n):
    k = n[0]
    if k not in NEW3:
        return _prev["to_pl"](n)
    if k == "sort":
        return to_pl(n[1]).sort(descending=n[2], nulls_last=n[3])
    if k == "arg_sort":
        return to_pl(n[1]).arg_sort(descending=n[2], nulls_last=n[3])
    if k == "sort_by":
        d = False if n[3] is None else n[3]
        return to_pl(n[1]).sort_by([to_pl(x) for x in n[2]], descending=d, nulls_last=n[4])
    if k == "head":
        return to_pl(n[1]).head(n[2])
    if k == "tail":
        return to_pl(n[1]).tail(n[2])
    if k == "slice":
        return to_pl(n[1]).slice(n[2], n[3])
    if k == "unique":
        return to_pl(n[1]).unique(maintain_order=n[2])
    if k == "drop_nulls":
        return to_pl(n[1]).drop_nulls()
    if k == "filter":
        return to_pl(n[1]).filter(to_pl(n[2]))
    if k == "any_vals":
        return to_pl(n[1]).any(ignore_nulls=n[2])
    if k == "all_vals":
        return to_pl(n[1]).all(ignore_nulls=n[2])
    if k == "trig":
        return getattr(to_pl(n[2]), n[1])()
    if k == "horiz":
        f = getattr(pl, n[1] + "_horizontal")
        xs = [to_pl(x) for x in n[2]]
        if n[1] == "sum":
            return f(*xs, ignore_nulls=n[3])
        return f(*xs)
    raise ValueError(k)


def to_py(n):
    k = n[0]
    if k not in NEW3:
        return _prev["to_py"](n)
    if k in ("sort", "arg_sort"):
        return f"{to_py(n[1])}.{k}(descending={n[2]}, nulls_last={n[3]})"
    if k == "sort_by":
        d = False if n[3] is None else n[3]
        return (f"{to_py(n[1])}.sort_by([{', '.join(to_py(x) for x in n[2])}], "
                f"descending={d}, nulls_last={n[4]})")
    if k in ("head", "tail"):
        return f"{to_py(n[1])}.{k}({n[2]})"
    if k == "slice":
        return f"{to_py(n[1])}.slice({n[2]}, {n[3]})"
    if k == "unique":
        return f"{to_py(n[1])}.unique(maintain_order={n[2]})"
    if k == "drop_nulls":
        return f"{to_py(n[1])}.drop_nulls()"
    if k == "filter":
        return f"{to_py(n[1])}.filter({to_py(n[2])})"
    if k in ("any_vals", "all_vals"):
        return f"{to_py(n[1])}.{k[:3]}(ignore_nulls={n[2]})"
    if k == "trig":
        return f"{to_py(n[2])}.{n[1]}()"
    if k == "horiz":
        extra = f", ignore_nulls={n[3]}" if n[1] == "sum" else ""
        return f"pl.{n[1]}_horizontal({', '.join(to_py(x) for x in n[2])}{extra})"
    raise ValueError(k)


def bool_mb(v):
    return "true" if v else "false"


def to_mb(n):
    k = n[0]
    if k not in NEW3:
        return _prev["to_mb"](n)
    if k in ("sort", "arg_sort"):
        a = (", descending=true" if n[2] else "") + (", nulls_last=true" if n[3] else "")
        return f"{to_mb(n[1])}.{k}({a[2:]})"
    if k == "sort_by":
        keys = ", ".join(to_mb(x) for x in n[2])
        dl = desc_list(n[3], len(n[2]))
        a = ""
        if dl is not None:
            a += ", descending=[" + ", ".join(bool_mb(b) for b in dl) + "]"
        if n[4]:
            a += ", nulls_last=true"
        return f"{to_mb(n[1])}.sort_by([{keys}]{a})"
    if k in ("head", "tail"):
        return f"{to_mb(n[1])}.{k}(n={mb_i32(n[2])})"
    if k == "slice":
        a = "" if n[3] is None else f", length={mb_i32(n[3])}"
        return f"{to_mb(n[1])}.slice({mb_i32(n[2])}{a})"
    if k == "unique":
        return f"{to_mb(n[1])}.unique(" + ("maintain_order=true" if n[2] else "") + ")"
    if k == "drop_nulls":
        return f"{to_mb(n[1])}.drop_nulls()"
    if k == "filter":
        return f"{to_mb(n[1])}.filter({to_mb(n[2])})"
    if k in ("any_vals", "all_vals"):
        return f"{to_mb(n[1])}.{k[:3]}(" + ("" if n[2] else "ignore_nulls=false") + ")"
    if k == "trig":
        return f"{to_mb(n[2])}.{n[1]}()"
    if k == "horiz":
        a = ", ignore_nulls=false" if (n[1] == "sum" and not n[3]) else ""
        return f"@pl.{n[1]}_horizontal([{', '.join(to_mb(x) for x in n[2])}]{a})"
    raise ValueError(k)


def pure_weak_ext(n):
    if n[0] in NEW3:
        return False
    return pure_weak_old(n)


def strengthen(n, keep_weak=False):
    """`expr.py`'s `strengthen` with the nodes of this file. The inputs of a
    horizontal function meet each other: weak literals are strong (64-bit) only
    when every input is one."""
    k = n[0]
    if k == "horiz":
        xs = n[2]
        if all(pure_weak_ext(x) for x in xs):
            xs2 = [strong_all(x) for x in xs]
        else:
            xs2 = [strengthen(x, True) for x in xs]
        return ("horiz", n[1], xs2, n[3])
    if k == "sort_by":
        return ("sort_by", strengthen(n[1]), [strengthen(x) for x in n[2]], n[3], n[4])
    if k in NEW3:
        return tuple(strengthen(c) if isinstance(c, tuple) else c for c in n)
    return _prev_strengthen(n, keep_weak)


for d in (_ns, A, S):
    d["to_pl"], d["to_py"], d["to_mb"] = to_pl, to_py, to_mb
    d["strengthen"] = strengthen
    d["pure_weak"] = pure_weak_ext
S["pure_weak_ext"] = pure_weak_ext


def case(cid, table, nodes, ulp=False, **kw):
    before = len(CASES)
    _seq_case(cid, table, nodes, **kw)
    if ulp and len(CASES) > before and "result" in CASES[-1]:
        CASES[-1]["ulp"] = True


DTS = ["i32", "i64", "f32", "f64", "s", "b", "d", "dt", "n"]
Q_TBL = "q"
FLAGS = [(False, False), (True, False), (False, True), (True, True)]

# ---------------------------------------------------------------------------
# sort, arg_sort
# ---------------------------------------------------------------------------
for c in DTS:
    for d, nl in (FLAGS if c in ("i32", "f64", "s", "b", "n") else [FLAGS[0], FLAGS[3]]):
        tag = f"{'desc' if d else 'asc'}{'-nl' if nl else ''}"
        case(f"sort/q/{c}/{tag}", "q", [sort_(col(c), d, nl)])
        case(f"arg_sort/q/{c}/{tag}", "q", [arg_sort(col(c), d, nl)])
for c in ["i32", "s", "n", "f64"]:
    for t in ["e0", "r1"]:
        case(f"sort/{t}/{c}", t, [sort_(col(c))])
        case(f"arg_sort/{t}/{c}", t, [arg_sort(col(c), True, True)])
for c in ["i64", "f64", "s", "b"]:
    case(f"sort/dup/{c}", "dup", [sort_(col(c))])
    case(f"sort/dup/{c}/desc-nl", "dup", [sort_(col(c), True, True)])
    case(f"arg_sort/dup/{c}", "dup", [arg_sort(col(c))])
    case(f"arg_sort/dup/{c}/desc", "dup", [arg_sort(col(c), True)])
    case(f"arg_sort/dup/{c}/desc-nl", "dup", [arg_sort(col(c), True, True)])

# ---------------------------------------------------------------------------
# sort_by
# ---------------------------------------------------------------------------
KEYS = ["a", "s", "f", "bo", "id"]
for kk in KEYS:
    for d, nl in FLAGS:
        if kk != "id" and not (d == nl):
            continue
        # a final `id` key breaks the ties
        tag = f"{'desc' if d else 'asc'}{'-nl' if nl else ''}"
        case(f"sort_by/sk/{kk}/{tag}", "sk", [sort_by(col("x"), [col(kk), col("id")], None if not d else [True, False], nl)])
case("sort_by/sk/single-id", "sk", [sort_by(col("x"), [col("id")], True)])
case("sort_by/sk/two-desc-bool", "sk", [sort_by(col("x"), [col("s"), col("a"), col("id")], True)])
case("sort_by/sk/two-desc-list", "sk", [sort_by(col("x"), [col("s"), col("a"), col("id")], [True, False, True])])
case("sort_by/sk/two-desc-nl", "sk", [sort_by(col("x"), [col("s"), col("a"), col("id")], [False, True, False], True)])
case("sort_by/sk/by-self", "sk", [sort_by(col("a"), [col("a"), col("id")])])
case("sort_by/sk/expr-key", "sk", [sort_by(col("x"), [bin_("mul", col("a"), li(-1)), col("id")])])
case("sort_by/sk/key-is-bool", "sk", [sort_by(col("x"), [col("bo"), col("id")])])
case("sort_by/sk/key-float", "sk", [sort_by(col("x"), [col("f"), col("id")], [True, False])])
case("sort_by/sk/key-float-nl", "sk", [sort_by(col("x"), [col("f"), col("id")], None, True)])
case("sort_by/sk/ties-stable", "sk", [sort_by(col("x"), [col("a")])])
case("sort_by/sk/ties-stable-desc", "sk", [sort_by(col("x"), [col("a")], [True])])
case("sort_by/sk/ties-stable-nl", "sk", [sort_by(col("x"), [col("s")], None, True)])
case("sort_by/sk/ties-two-keys", "sk", [sort_by(col("x"), [col("a"), col("s")])])
case("sort_by/sk/no-keys", "sk", [sort_by(col("x"), [])])
case("sort_by/sk/lit-key", "sk", [sort_by(col("x"), [lit("i32", 1)])])
case("sort_by/sk/lit-weak-key", "sk", [sort_by(col("x"), [li(1)])])
case("sort_by/sk/agg-key", "sk", [sort_by(col("x"), [agg("sum", col("a"))])])
case("sort_by/sk/agg-base", "sk", [sort_by(agg("sum", col("x")), [col("a")])])
case("sort_by/sk/agg-both", "sk", [sort_by(agg("sum", col("x")), [agg("sum", col("a"))])])
case("sort_by/sk/short-key", "sk", [sort_by(col("x"), [head(col("a"), 3)])])
case("sort_by/sk/short-base", "sk", [sort_by(head(col("x"), 3), [col("a")])])
case("sort_by/sk/short-both", "sk", [sort_by(head(col("x"), 3), [head(col("a"), 3), col("id")])])
case("sort_by/sk/desc-too-long", "sk", [sort_by(col("x"), [col("a"), col("id")], [True, False, True])])
case("sort_by/sk/desc-one-of-two", "sk", [sort_by(col("x"), [col("a"), col("id")], [True])])
case("sort_by/sk/desc-one-of-one", "sk", [sort_by(col("x"), [col("id")], [True])])
case("sort_by/sk/missing-key", "sk", [sort_by(col("x"), [col("zz")])])
case("sort_by/sk/missing-base", "sk", [sort_by(col("zz"), [col("a")])])
case("sort_by/sk/chain-head", "sk", [head(sort_by(col("x"), [col("a"), col("id")]), 3)])
case("sort_by/sk/first", "sk", [agg("first", sort_by(col("x"), [col("a"), col("id")], True))])
case("sort_by/sk/cols", "sk", [sort_by(cols(["x", "a"]), [col("s"), col("id")])])
case("sort_by/sk/all", "sk", [sort_by(all_, [col("id")], True)])
case("sort_by/sk/cols-key", "sk", [sort_by(col("x"), [cols(["s", "id"])])])
case("sort_by/sk/alias", "sk", [sort_by(col("x"), [col("a"), col("id")]).alias("z")])
case("sort_by/sk/with-col", "sk", [sort_by(col("x"), [col("a"), col("id")]).alias("sorted")], op="with_columns")
case("sort_by/e0", "e0", [sort_by(col("i32"), [col("i64")])])
case("sort_by/e0/lit", "e0", [sort_by(col("i32"), [lit("i32", 1)])])
case("sort_by/r1", "r1", [sort_by(col("i32"), [col("i64"), col("f64")], [True, False])])
case("sort_by/z0", "z0", [sort_by(li(1), [li(2)])])
case("sort_by/q/str-by-date", "q", [sort_by(col("s"), [col("d"), col("dt")], [False, True])])
case("sort_by/q/null-key", "q", [sort_by(col("i32"), [col("n")])])

# ---------------------------------------------------------------------------
# head, tail, slice
# ---------------------------------------------------------------------------
for c in ["i32", "f64", "s", "b", "d", "n"]:
    for n in [0, 2, 100]:
        case(f"head/q/{c}/{n}", "q", [head(col(c), n)])
        case(f"tail/q/{c}/{n}", "q", [tail(col(c), n)])
for c in ["i32", "s", "d", "n"]:
    for off, length in [(1, 2), (-3, None), (-3, 2), (8, 5), (0, 0), (-20, 12)]:
        case(f"slice/q/{c}/{off}/{length}", "q", [slice_(col(c), off, length)])
case("head/q/default", "q", [head(col("i32"))])
case("tail/q/default", "q", [tail(col("i32"))])
for n in [-1, -3]:
    case(f"head/q/neg{n}", "q", [head(col("i32"), n)])
    case(f"tail/q/neg{n}", "q", [tail(col("i32"), n)])
    case(f"head/e0/neg{n}", "e0", [head(col("i32"), n)])
case("slice/q/neg-length", "q", [slice_(col("i32"), 1, -1)])
case("slice/q/neg-length-zero-offset", "q", [slice_(col("s"), 0, -2)])
for t in ["e0", "r1"]:
    for c in ["i32", "s", "n"]:
        case(f"head/{t}/{c}", t, [head(col(c), 3)])
        case(f"tail/{t}/{c}", t, [tail(col(c), 3)])
        case(f"slice/{t}/{c}", t, [slice_(col(c), -1, 2)])
case("head/z0-lit", "z0", [head(li(1), 3)])
case("head/lit", "q", [head(li(1), 3)])
case("head/lit-strong", "q", [head(lit("i32", 4), 3)])
case("head/lit-str", "q", [head(ls("a"), 0)])
case("tail/lit", "q", [tail(ls("a"), 2)])
case("slice/lit", "q", [slice_(lf(1.5), 0, 5)])
case("head/agg", "q", [head(agg("sum", col("i32")), 3)])
case("head/cols", "qn", [head(cols(["i32", "i64"]), 3)])
case("head/all", "qn", [head(all_, 2)])
case("head/all-z0", "z0", [head(all_, 2)])
case("head/cols-empty", "q", [head(cols([]), 2)])
case("head/missing", "q", [head(col("zz"), 2)])
case("head/alias", "q", [head(col("i32"), 2).alias("h")])
case("head/alias-inner", "q", [head(alias(col("i32"), "z"), 2)])
case("head/names", "q", [head(col("i32"), 2), head(col("i64"), 2).alias("b"), tail(col("f64"), 2).alias("c")])
case("head/dup-name", "q", [head(col("i32"), 2), tail(col("i32"), 2)])
case("head/dup-with-col", "q", [col("i32"), head(col("i32"), 2)])

# ---------------------------------------------------------------------------
# unique, drop_nulls
# ---------------------------------------------------------------------------
for c in DTS:
    case(f"unique/dup/{c}/stable", "dup", [unique(col(c), True)])
    # `unique()` does not promise an order: sorted afterwards
    case(f"unique/dup/{c}/sorted", "dup", [sort_(unique(col(c)))])
    case(f"drop_nulls/q/{c}", "q", [drop_nulls(col(c))])
    if c in ("i32", "s", "n"):
        case(f"drop_nulls/dup/{c}", "dup", [drop_nulls(col(c))])
        case(f"unique/q/{c}/stable", "q", [unique(col(c), True)])
for t in ["e0", "r1"]:
    for c in ["i32", "s", "n"]:
        case(f"unique/{t}/{c}", t, [unique(col(c), True)])
        case(f"drop_nulls/{t}/{c}", t, [drop_nulls(col(c))])
case("unique/lit", "q", [unique(li(3), True)])
case("unique/z0-lit", "z0", [unique(ls("a"), True)])
case("drop_nulls/lit", "q", [drop_nulls(li(3))])
case("drop_nulls/lit-null", "q", [drop_nulls(lit("null", None))])
case("unique/agg", "q", [unique(agg("sum", col("i32")), True)])
case("unique/count", "dup", [agg("count", unique(col("i32"), True))])
case("unique/n_unique-same", "dup", [agg("n_unique", unique(col("f64"), True)), agg("n_unique", col("f64")).alias("m")])
case("drop_nulls/mean", "q", [agg("mean", drop_nulls(col("f64")))])
case("drop_nulls/sum-len", "q", [agg("len", drop_nulls(col("i32"))), agg("count", col("i32")).alias("c")])
case("unique/cols", "dup", [unique(cols(["i32", "i64"]), True)])
case("unique/cols-uneven", "dup", [unique(cols(["i32", "i64"]), True)], op="with_columns")
case("drop_nulls/all-qn", "qn", [drop_nulls(all_)])
case("drop_nulls/wc", "q", [drop_nulls(col("i32")).alias("x")], op="with_columns")
case("drop_nulls/wc-same-name", "dup", [drop_nulls(col("i32"))], op="with_columns")

# ---------------------------------------------------------------------------
# filter
# ---------------------------------------------------------------------------
for c in DTS:
    case(f"filter/q/{c}/b", "q", [filter_(col(c), col("b"))])
    if c in ("i32", "s", "n"):
        case(f"filter/e0/{c}", "e0", [filter_(col(c), col("b"))])
for c in ["i64", "f64", "s", "d", "n"]:
    case(f"filter/q/pred-type/{c}", "q", [filter_(col("i32"), col(c))])
case("filter/q/gt", "q", [filter_(col("i64"), bin_("gt", col("i64"), li(0)))])
case("filter/q/sum", "q", [agg("sum", filter_(col("i64"), bin_("gt", col("i64"), li(0))))])
case("filter/q/sum-i32", "q", [agg("sum", filter_(col("i32"), bin_("gt", col("i32"), li(1))))])
case("filter/q/mean-two", "q", [agg("mean", filter_(col("f64"), col("b"))), agg("sum", filter_(col("f64"), not_(col("b")))).alias("t")])
case("filter/q/lit-true", "q", [filter_(col("i32"), lb(True))])
case("filter/q/lit-false", "q", [filter_(col("i32"), lb(False))])
case("filter/q/lit-null", "q", [filter_(col("i32"), lit("null", None))])
case("filter/q/lit-int", "q", [filter_(col("i32"), li(1))])
case("filter/q/lit-float", "q", [filter_(col("i32"), lf(1.5))])
case("filter/q/lit-str", "q", [filter_(col("i32"), ls("a"))])
case("filter/q/agg-pred", "q", [filter_(col("i32"), bin_("gt", agg("sum", col("i64")), li(0)))])
case("filter/q/agg-pred-false", "q", [filter_(col("i32"), bin_("lt", agg("sum", col("i64")), li(0)))])
case("filter/q/agg-base", "q", [filter_(agg("sum", col("i32")), col("b"))])
case("filter/q/agg-base-true", "q", [filter_(agg("sum", col("i32")), lb(True))])
case("filter/q/agg-base-false", "q", [filter_(agg("sum", col("i32")), lb(False))])
case("filter/q/lit-base", "q", [filter_(lit("i32", 1), col("b"))])
case("filter/q/short-pred", "q", [filter_(col("i32"), head(col("b"), 2))])
case("filter/q/short-base", "q", [filter_(head(col("i32"), 3), col("b"))])
case("filter/q/short-both", "q", [filter_(head(col("i32"), 3), head(col("b"), 3))])
case("filter/q/one-pred", "q", [filter_(col("i32"), head(col("b"), 1))])
case("filter/q/chain-head", "q", [head(filter_(col("i64"), col("b")), 2)])
case("filter/q/chain-sort", "q", [sort_(filter_(col("i64"), is_not_null(col("i64"))), True)])
case("filter/q/filter-filter", "q", [filter_(filter_(col("i64"), is_not_null(col("i64"))), bin_("gt", filter_(col("i64"), is_not_null(col("i64"))), li(0)))])
case("filter/q/cols", "qn", [filter_(cols(["i32", "i64"]), bin_("gt", col("f64"), lf(0.0)))])
case("filter/q/all-pred", "qn", [filter_(all_, bin_("gt", col("f64"), lf(0.0)))])
case("filter/q/pred-cols", "qn", [filter_(col("i32"), bin_("gt", cols(["i32", "i64"]), li(0)))])
case("filter/q/missing-base", "q", [filter_(col("zz"), col("b"))])
case("filter/q/missing-pred", "q", [filter_(col("i32"), col("zz"))])
case("filter/q/alias", "q", [filter_(col("i32"), col("b")).alias("z")])
case("filter/q/wc", "q", [filter_(col("i32"), col("b")).alias("z")], op="with_columns")
case("filter/q/wc-agg", "q", [agg("sum", filter_(col("i32"), col("b"))).alias("tot")], op="with_columns")
case("filter/z0-lit", "z0", [filter_(li(1), lb(True))])
case("filter/z0-lit-false", "z0", [filter_(li(1), lb(False))])
case("filter/r1", "r1", [filter_(col("i32"), col("b"))])

# ---------------------------------------------------------------------------
# lengths: results of different lengths in one select / with_columns
# ---------------------------------------------------------------------------
case("shape/head-and-col", "q", [head(col("i32"), 2), col("i64")])
case("shape/col-and-head", "q", [col("i64"), head(col("i32"), 2)])
case("shape/head1-and-col", "q", [head(col("i32"), 1), col("i64")])
case("shape/tail1-and-col", "q", [tail(col("i32"), 1), col("i64")])
case("shape/slice1-and-col", "q", [slice_(col("i32"), 3, 1), col("i64")])
case("shape/filter1-and-col", "q", [filter_(col("i32"), bin_("eq", col("i32"), li(4))), col("i64")])
case("shape/unique1-and-col", "dup", [unique(col("n"), True), col("i32")])
case("shape/drop1-and-col", "q", [drop_nulls(head(col("s"), 2)).alias("s1"), col("i64")])
case("shape/head1-and-head3", "q", [head(col("i32"), 1), head(col("i64"), 3)])
case("shape/head2-and-head3", "q", [head(col("i32"), 2), head(col("i64"), 3)])
case("shape/head3-and-head2", "q", [head(col("i32"), 3), head(col("i64"), 2)])
case("shape/head2-and-sum", "q", [head(col("i32"), 2), agg("sum", col("i64"))])
case("shape/head2-and-lit", "q", [head(col("i32"), 2), li(1)])
case("shape/head1-and-lit", "q", [head(col("i32"), 1), li(1)])
case("shape/head1-and-sum", "q", [head(col("i32"), 1), agg("sum", col("i64")).alias("s")])
case("shape/head1-alone", "q", [head(col("i32"), 1)])
case("shape/head2-alone", "q", [head(col("i32"), 2)])
case("shape/head0-and-col", "q", [head(col("i32"), 0), col("i64")])
case("shape/head0-and-sum", "q", [head(col("i32"), 0), agg("sum", col("i64"))])
case("shape/head0-and-head0", "q", [head(col("i32"), 0), head(col("i64"), 0)])
# an empty result next to a column of one row (or a cut to one row): height 0
case("shape/head0-and-head1", "q", [head(col("i32"), 0), head(col("i64"), 1)])
case("shape/r1-head0-and-col", "r1", [head(col("i32"), 0), col("i64")])
case("shape/r1-filter-false-and-col", "r1", [filter_(col("i32"), lb(False)), col("i64")])
case("shape/r1-slice-and-head", "r1", [slice_(col("i32"), 1, 3), head(col("i64"), 2)])
case("shape/r1-head0-and-lit", "r1", [head(col("i32"), 0), li(1)])
case("shape/r1-head0-and-sum", "r1", [head(col("i32"), 0), agg("sum", col("i64")).alias("s")])
case("shape/r1-col-and-head3", "r1", [col("i32"), head(col("i64"), 3)])
case("horiz/r1-head0-head1-and-col", "r1", [horiz("sum", [head(col("i32"), 0), head(col("i64"), 1)]), col("i64")])
case("filter/e0-agg-base", "e0", [filter_(agg("sum", col("i32")), col("b"))])
case("filter/e0-agg-base-alias", "e0", [filter_(agg("sum", col("i32")), col("b")).alias("x"), col("i64")])
case("filter/q/head1-base-empty-pred", "q", [filter_(head(col("i32"), 1), head(col("b"), 0))])
case("filter/q/agg-empty-pred", "q", [filter_(agg("sum", col("i32")), head(col("b"), 0))])
case("filter/q/any-base", "q", [filter_(any_(col("b")), col("b"))])
case("filter/q/all-base", "q", [filter_(all_fn(col("b")), col("b"))])
case("filter/q/lit-base-empty-pred", "q", [filter_(li(1), head(col("b"), 0))])
case("sort_by/sk/key-head1", "sk", [sort_by(col("x"), [head(col("a"), 1)])])
case("sort_by/sk/key-drop-head1", "sk", [sort_by(col("x"), [head(drop_nulls(col("a")), 1)])])
case("sort_by/sk/base-head2-key-head1", "sk", [sort_by(head(col("x"), 2), [head(col("a"), 1)])])
case("sort_by/sk/multi-key-head1", "sk", [sort_by(col("x"), [col("a"), head(col("a"), 1)])])
case("sort_by/sk/multi-head1-key", "sk", [sort_by(col("x"), [head(col("a"), 1), col("a")])])
case("sort_by/sk/multi-empty-base", "sk", [sort_by(head(col("x"), 0), [head(col("a"), 1), head(col("a"), 0)])])
case("sort_by/sk/multi-agg-key", "sk", [sort_by(col("x"), [col("a"), agg("sum", col("id"))])])
case("sort_by/r1-head0-and-sorted", "r1", [head(col("i32"), 0), sort_by(col("i64"), [col("i64")])])
case("sort_by/r1-key-col", "r1", [sort_by(col("i32"), [col("i64")])])
case("shape/sum-sort-and-col", "q", [sort_(agg("sum", col("i32"))), col("i64")])
case("shape/lit-sort-and-col", "q", [sort_(li(1)), col("i64")])
case("shape/sum-arg_sort-and-col", "q", [arg_sort(agg("sum", col("i32"))), col("i64")])
case("shape/sum-head-and-col", "q", [head(agg("sum", col("i32")), 1), col("i64")])
case("shape/lit-head-and-col", "q", [head(li(1), 1), col("i64")])
case("shape/sum-unique-and-col", "q", [unique(agg("sum", col("i32"))), col("i64")])
case("shape/sum-filter-and-col", "q", [filter_(agg("sum", col("i32")), lb(True)), col("i64")])
case("shape/sum-drop_nulls-and-col", "q", [drop_nulls(agg("sum", col("i32"))), col("i64")])
case("shape/sum-slice-and-col", "q", [slice_(agg("sum", col("i32")), 0, 1), col("i64")])
case("shape/head1-sin-and-col", "q", [trig("sin", head(col("i32"), 1)), col("i64")])
case("shape/head1-plus-and-col", "q", [bin_("add", head(col("i32"), 1), li(1)), col("i64")])
case("shape/head1-plus-col", "q", [bin_("add", head(col("i32"), 1), col("i64"))])
case("shape/head2-plus-col", "q", [bin_("add", head(col("i32"), 2), col("i64"))])
case("shape/head1-plus-head3", "q", [bin_("add", head(col("i32"), 1), head(col("i64"), 3))])
case("shape/sum-plus-head1-and-col", "q", [bin_("add", agg("sum", col("i32")), head(col("i64"), 1)), col("f64")])
case("shape/head1-alias-and-col", "q", [head(col("i32"), 1).alias("z"), col("i64")])
case("shape/head1-cast-and-col", "q", [cast(head(col("i32"), 1), "i64"), col("f64")])
case("shape/head1-fill-and-col", "q", [fill(head(col("i32"), 1), li(0)), col("i64")])
case("shape/head1-shift-and-col", "q", [shift(head(col("i32"), 1), 1), col("i64")])
case("shape/head1-is_null-and-col", "q", [is_null(head(col("i32"), 1)), col("i64")])
case("shape/head1-not-and-col", "q", [not_(head(col("b"), 1)), col("i64")])
case("shape/head1-sort-and-col", "q", [sort_(head(col("i32"), 1)), col("i64")])
case("shape/head1-and-r1", "r1", [head(col("i32"), 1), col("i64")])
case("shape/head5-and-r1", "r1", [head(col("i32"), 5), col("i64")])
case("shape/e0-head-and-col", "e0", [head(col("i32"), 1), col("i64")])
case("shape/e0-head-and-sum", "e0", [head(col("i32"), 1), agg("sum", col("i64"))])
case("shape/e0-sum-and-col", "e0", [agg("sum", col("i32")), col("i64")])
case("shape/wc-head2", "q", [head(col("i32"), 2)], op="with_columns")
case("shape/wc-head2-alias", "q", [head(col("i32"), 2).alias("x")], op="with_columns")
case("shape/wc-head1", "q", [head(col("i32"), 1)], op="with_columns")
case("shape/wc-head1-alias", "q", [head(col("i32"), 1).alias("x")], op="with_columns")
case("shape/wc-head10", "q", [head(col("i32"), 10).alias("x")], op="with_columns")
case("shape/wc-head100", "q", [head(col("i32"), 100).alias("x")], op="with_columns")
case("shape/wc-tail1", "q", [tail(col("i32"), 1)], op="with_columns")
case("shape/wc-filter1", "q", [filter_(col("i32"), bin_("eq", col("i32"), li(4))).alias("x")], op="with_columns")
case("shape/wc-filter-all", "q", [filter_(col("i32"), lb(True)).alias("x")], op="with_columns")
case("shape/wc-unique1", "dup", [unique(col("n"), True)], op="with_columns")
case("shape/wc-sort", "q", [sort_(col("i32")).alias("x")], op="with_columns")
case("shape/wc-sort-in-place", "q", [sort_(col("i32"))], op="with_columns")
case("shape/wc-arg_sort", "q", [arg_sort(col("i32")).alias("rank")], op="with_columns")
case("shape/wc-sum-sort", "q", [sort_(agg("sum", col("i32"))).alias("x")], op="with_columns")
case("shape/wc-lit-head1", "q", [head(li(1), 1).alias("x")], op="with_columns")
case("shape/wc-sum-head1", "q", [head(agg("sum", col("i32")), 1).alias("x")], op="with_columns")
case("shape/wc-drop_nulls", "q", [drop_nulls(col("i32")).alias("x")], op="with_columns")
case("shape/wc-e0-head", "e0", [head(col("i32"), 1).alias("x")], op="with_columns")
case("shape/wc-e0-head0", "e0", [head(col("i32"), 0).alias("x")], op="with_columns")
case("shape/wc-r1-head1", "r1", [head(col("i32"), 1).alias("x")], op="with_columns")
case("shape/wc-z0-head", "z0", [head(li(1), 0).alias("x")], op="with_columns")
# the end-to-end cases M2 had to leave out
case("shape/m2-head-two-cols", "q", [head(col("i32"), 2), head(col("i64"), 4)])
case("shape/m2-all-lengths", "q", [col("i32"), head(col("i64"), 4), agg("sum", col("f64"))])

# ---------------------------------------------------------------------------
# the order of rows: sort, arg_sort, head ... with other expressions
# ---------------------------------------------------------------------------
case("mix/sort-first", "q", [agg("first", sort_(col("i32")))])
case("mix/sort-last", "q", [agg("last", sort_(col("i32"), True))])
case("mix/sort-median", "q", [agg("median", sort_(col("f64")))])
case("mix/sort-plus", "q", [bin_("add", sort_(col("i64")), sort_(col("i32")))])
case("mix/sort-minus-col", "q", [bin_("sub", sort_(col("i64")), col("i64"))])
case("mix/sort-cum_sum", "q", [cum("sum", sort_(col("i64")))])
case("mix/sort-shift", "q", [shift(sort_(col("i64")), 1)])
case("mix/sort-reverse", "q", [reverse(sort_(col("s")))])
case("mix/sort-rank", "q", [rank(sort_(col("i64")))])
case("mix/sort-abs", "q", [fn("abs", sort_(col("i32")))])
case("mix/sort-fill", "q", [fill(sort_(col("i32")), li(0))])
case("mix/sort-cast", "q", [cast(sort_(col("i32")), "f64")])
case("mix/sort-is_null", "q", [is_null(sort_(col("i32")))])
case("mix/sort-between", "q", [A["btw"](sort_(col("i32")), li(0), li(5))])
case("mix/sort-when", "q", [when_(bin_("gt", sort_(col("i64")), li(0)), li(1), li(0))])
case("mix/sort-sort", "q", [sort_(sort_(col("i32"), True))])
case("mix/sort-desc-sort", "q", [sort_(sort_(col("i32")), True)])
case("mix/arg_sort-head", "q", [head(arg_sort(col("i64")), 3)])
case("mix/arg_sort-sum", "q", [agg("sum", arg_sort(col("i64")))])
case("mix/arg_sort-eq-rank", "q", [bin_("eq", arg_sort(col("f64")), rank(col("f64"), "ordinal"))])
case("mix/arg_sort-arg_sort", "q", [arg_sort(arg_sort(col("i64")))])
case("mix/arg_sort-gt", "q", [bin_("gt", arg_sort(col("s")), li(4))])
case("mix/head-sum", "q", [agg("sum", head(col("i32"), 3))])
case("mix/head-mean", "q", [agg("mean", head(col("f64"), 4))])
case("mix/tail-max", "q", [agg("max", tail(col("i64"), 4))])
case("mix/head-count", "q", [agg("count", head(col("i32"), 5)), agg("len", head(col("i32"), 5)).alias("l")])
case("mix/head-head", "q", [head(head(col("i32"), 6), 3)])
case("mix/head-tail", "q", [tail(head(col("i32"), 6), 2)])
case("mix/tail-head", "q", [head(tail(col("i32"), 6), 2)])
case("mix/slice-slice", "q", [slice_(slice_(col("i32"), 2, 6), -2, 5)])
case("mix/head-plus-head", "q", [bin_("add", head(col("i32"), 3), head(col("i64"), 3))])
case("mix/head-plus-lit", "q", [bin_("add", head(col("i64"), 3), li(1))])
case("mix/head-plus-sum", "q", [bin_("sub", head(col("i64"), 3), agg("sum", col("i64")))])
case("mix/head-sort", "q", [sort_(head(col("i32"), 5), True, True)])
case("mix/head-unique", "q", [unique(head(col("i32"), 5), True)])
case("mix/head-drop_nulls", "q", [drop_nulls(head(col("i32"), 5))])
case("mix/head-cum_sum", "q", [cum("sum", head(col("i64"), 5))])
case("mix/head-shift", "q", [shift(head(col("i64"), 5), 1)])
case("mix/head-rank", "q", [rank(head(col("f64"), 5))])
case("mix/head-is_null", "q", [is_null(head(col("i32"), 5))])
case("mix/head-fill", "q", [fill(head(col("i32"), 5), head(col("i64"), 5))])
case("mix/head-fill-long", "q", [fill(head(col("i32"), 5), col("i64"))])
case("mix/head-when", "q", [when_(head(col("b"), 3), head(col("i32"), 3), head(col("i64"), 3))])
case("mix/head-cast", "q", [cast(head(col("i32"), 3), "str")])
case("mix/head-str", "st", [st("to_uppercase", head(col("s"), 3))])
case("mix/head-dt", "tm", [dtf("year", head(col("d"), 3))])
case("mix/unique-sum", "dup", [agg("sum", unique(col("i32"), True))])
case("mix/unique-len", "dup", [agg("len", unique(col("s"), True))])
case("mix/unique-sort", "dup", [sort_(unique(col("f64"), True), True, True)])
case("mix/unique-shift", "dup", [shift(unique(col("i64"), True), 1)])
case("mix/unique-plus", "dup", [bin_("add", unique(col("i32"), True), li(1))])
case("mix/filter-then-sort", "sk", [sort_(filter_(col("x"), bin_("gt", col("a"), li(1))), True)])
case("mix/filter-by-sort-by", "sk", [filter_(sort_by(col("x"), [col("a"), col("id")]), bin_("gt", col("x"), li(30)))])
case("mix/filter-pred-sorted", "sk", [filter_(col("x"), sort_(bin_("gt", col("a"), li(1))))])
case("mix/drop_nulls-sort", "q", [sort_(drop_nulls(col("i32")))])
case("mix/drop_nulls-first", "q", [agg("first", drop_nulls(col("i32")))])
case("mix/drop_nulls-null-col", "q", [drop_nulls(col("n"))])
case("mix/drop_nulls-null-sum", "q", [agg("sum", drop_nulls(col("i32")))])
case("mix/names-several", "q", [sort_(col("i32")), arg_sort(col("i64")).alias("ia"), head(col("f64"), 10).alias("h")])
case("mix/dup-name-sort", "q", [col("i32"), sort_(col("i32"))])
case("mix/dup-name-arg_sort", "q", [arg_sort(col("i32")), sort_(col("i32"))])
case("mix/missing-sort", "q", [sort_(col("zz"))])
case("mix/missing-after", "q", [sort_(col("i32")), unique(col("zz"))])
case("mix/cols-sort", "qn", [sort_(cols(["i32", "i64"]), True)])
case("mix/all-sort", "qn", [sort_(all_)])
case("mix/all-arg_sort", "qn", [arg_sort(all_)])
case("mix/all-z0", "z0", [sort_(all_)])
case("mix/cols-empty", "q", [sort_(cols([]))])
case("mix/cols-width", "qn", [sort_by(cols(["i32", "i64"]), [cols(["f32", "f64"]), col("i32")])])
case("mix/alias-inner-sort", "q", [sort_(alias(col("i32"), "z"))])
case("mix/alias-sort", "q", [sort_(col("i32")).alias("z")])
case("mix/lit-sort", "q", [sort_(li(1))])
case("mix/lit-arg_sort", "q", [arg_sort(li(1))])
case("mix/lit-sort-null", "q", [sort_(lit("null", None))])
case("mix/lit-sort-str", "z0", [sort_(ls("a"))])
case("mix/lit-arg_sort-z0", "z0", [arg_sort(li(1))])
case("mix/sum-sort", "q", [sort_(agg("sum", col("i32")))])
case("mix/sum-arg_sort", "q", [arg_sort(agg("sum", col("i32")))])
case("mix/wc-sort-sum", "q", [agg("sum", sort_(col("i32"))).alias("tot")], op="with_columns")

# ---------------------------------------------------------------------------
# any, all
# ---------------------------------------------------------------------------
for c in AN:
    for ig in (True, False):
        tag = "ign" if ig else "keep"
        case(f"any/an/{c}/{tag}", "an", [any_(col(c), ig)])
        case(f"all/an/{c}/{tag}", "an", [all_fn(col(c), ig)])
for c in ["i32", "f64", "s", "d", "n"]:
    for ig in (True, False):
        tag = "ign" if ig else "keep"
        case(f"any/q/{c}/{tag}", "q", [any_(col(c), ig)])
        case(f"all/q/{c}/{tag}", "q", [all_fn(col(c), ig)])
for c in ["i32", "b", "n", "s", "d", "dt", "f32"]:
    for ig in (True, False):
        tag = "ign" if ig else "keep"
        case(f"any/e0/{c}/{tag}", "e0", [any_(col(c), ig)])
        case(f"all/e0/{c}/{tag}", "e0", [all_fn(col(c), ig)])
for c in ["x", "y", "z", "w"]:
    case(f"any/ng/{c}", "ng", [any_(col(c)), all_fn(col(c)).alias("al")])
case("any/r1", "r1", [any_(col("b")), all_fn(col("b")).alias("al")])
case("any/lit-true", "q", [any_(lb(True))])
case("any/lit-false", "q", [all_fn(lb(False))])
case("any/lit-int", "q", [any_(li(0))])
case("any/lit-float", "q", [all_fn(lf(0.5))])
case("any/lit-null", "q", [any_(lit("null", None))])
case("any/lit-null-keep", "q", [all_fn(lit("null", None), False)])
case("any/lit-str", "q", [any_(ls("a"))])
case("any/z0-lit", "z0", [any_(lb(True))])
case("any/expr", "q", [any_(bin_("gt", col("i32"), li(5)))])
case("all/expr", "q", [all_fn(bin_("gt", col("i64"), li(-5)))])
case("all/expr-keep", "q", [all_fn(bin_("gt", col("i64"), li(-5)), False)])
case("any/mixed-with-col", "q", [col("i32"), any_(col("b")).alias("a")])
case("any/mixed-with-col-error", "q", [col("i32"), any_(col("s")).alias("a")])
case("any/and", "q", [bin_("and", any_(col("b")), all_fn(col("b")))])
case("any/not", "q", [not_(any_(col("b")))])
case("any/when", "q", [when_(any_(col("b")), col("i32"), li(0))])
case("any/cols", "an", [any_(cols(["t", "f", "m"]))])
case("any/all", "an", [any_(all_)])
case("any/all-z0", "z0", [any_(all_)])
case("any/alias", "an", [any_(col("m")).alias("x")])
case("any/alias-inner", "an", [any_(alias(col("m"), "x"))])
case("any/missing", "an", [any_(col("zz"))])
case("any/head", "an", [any_(head(col("m"), 1))])
case("any/sort", "an", [any_(sort_(col("tfn")), False)])
case("any/filter", "q", [any_(filter_(col("b"), col("b")))])
case("all/filter", "q", [all_fn(filter_(col("b"), col("b")))])
case("all/filter-empty", "q", [all_fn(filter_(col("b"), lb(False)))])
case("any/filter-empty", "q", [any_(filter_(col("b"), lb(False)), False)])
case("any/wc", "an", [any_(col("m")).alias("x")], op="with_columns")
case("any/sum", "an", [agg("sum", any_(col("m")))])
case("any/names", "an", [any_(col("m")), all_fn(col("tn"), False).alias("b")])

# ---------------------------------------------------------------------------
# trigonometric functions
# ---------------------------------------------------------------------------
for f in TRIGS:
    for c in (DTS if f in ("sin", "tan") else ["i32", "i64", "f32", "f64", "n"]):
        case(f"trig/{f}/q/{c}", "q", [trig(f, col(c))], ulp=True)
    if f in ("sin", "tan"):
        case(f"trig/{f}/lit-int", "q", [trig(f, li(1))], ulp=True)
    if f in ("sin", "arcsin"):
        for c in ["i32", "f32", "n", "s"]:
            case(f"trig/{f}/e0/{c}", "e0", [trig(f, col(c))], ulp=True)
        case(f"trig/{f}/lit-float", "q", [trig(f, lf(0.5))], ulp=True)
        case(f"trig/{f}/lit-strong", "q", [trig(f, lit("f32", 0.5))], ulp=True)
        case(f"trig/{f}/lit-str", "q", [trig(f, ls("a"))], ulp=True)
        case(f"trig/{f}/sum", "q", [trig(f, agg("sum", col("i32")))], ulp=True)
        case(f"trig/{f}/r1", "r1", [trig(f, col("f64"))], ulp=True)
case("trig/alias", "q", [trig("sin", col("f64")).alias("s")], ulp=True)
case("trig/alias-inner", "q", [trig("sin", alias(col("f64"), "z"))], ulp=True)
case("trig/names", "q", [trig("sin", col("f64")), trig("cos", col("f32")).alias("c"), trig("tan", col("i32")).alias("t")], ulp=True)
case("trig/dup", "q", [trig("sin", col("f64")), trig("cos", col("f64"))], ulp=True)
case("trig/cols", "qn", [trig("sin", cols(["i32", "f64"]))], ulp=True)
case("trig/all", "qn", [trig("arctan", all_)], ulp=True)
case("trig/all-z0", "z0", [trig("sin", all_)], ulp=True)
case("trig/cols-error", "q", [trig("sin", cols(["i32", "s"]))], ulp=True)
case("trig/missing", "q", [trig("sin", col("zz"))], ulp=True)
case("trig/wc", "q", [trig("cos", col("f64")).alias("c")], op="with_columns", ulp=True)
case("trig/pyth", "q", [bin_("add", bin_("mul", trig("sin", col("f64")), trig("sin", col("f64"))),
                              bin_("mul", trig("cos", col("f64")), trig("cos", col("f64"))))], ulp=True)
case("trig/sin-arcsin", "q", [trig("arcsin", trig("sin", col("f32")))], ulp=True)
case("trig/sum-of-sin", "q", [agg("sum", trig("sin", col("f64")))], ulp=True)
case("trig/head", "q", [head(trig("tan", col("f64")), 3)], ulp=True)
case("trig/sort", "q", [sort_(trig("sin", col("f64")))], ulp=True)
# exact values
EX = {"x": [0.0, -0.0, 1.0, -1.0, 0.5, 2.0, nan, inf, -inf, None, 1.5707963267948966]}
TABLES["ex"] = pl.DataFrame([series_from_spec("x", "f64", EX["x"])])
for f in TRIGS:
    case(f"trig/{f}/ex", "ex", [trig(f, col("x"))], ulp=True)

# ---------------------------------------------------------------------------
# horizontal functions
# ---------------------------------------------------------------------------
# one column of each type for the pairs
PAIR_COLS = ["a", "i", "i32", "f32", "s", "bo", "d", "dt", "n"]
# the pairs whose two orders differ (error texts, the order of a concatenation)
REVERSED = [("s", "i32"), ("i32", "s"), ("d", "bo"), ("bo", "d"), ("s", "d"), ("d", "s"), ("dt", "d"), ("d", "dt"),
            ("bo", "s"), ("s", "bo")]
SUM_PAIRS = [(a, b) for i, a in enumerate(PAIR_COLS) for b in PAIR_COLS[i:]] + \
    [p for p in REVERSED if p[0] != p[1]]
SUM_PAIRS = list(dict.fromkeys(SUM_PAIRS))
MIN_PAIRS = [("a", "a"), ("a", "i"), ("i", "i32"), ("f32", "a"), ("f32", "f32"), ("i32", "i32"), ("s", "s"),
             ("s", "i32"), ("bo", "bo"), ("bo", "i32"), ("bo", "d"), ("d", "d"), ("d", "dt"), ("dt", "dt"),
             ("dt", "i32"), ("n", "n"), ("n", "s"), ("a", "n"), ("d", "i32"), ("f32", "bo"), ("i", "s"), ("s", "d"),
             ("s", "bo"), ("i32", "d"), ("i", "n"), ("bo", "bo2"), ("s", "s2")]
MAX_PAIRS = [("bo", "bo2"), ("s", "s2"), ("a", "a"), ("a", "i"), ("i", "i32"), ("f32", "a"), ("f32", "f32"), ("i32", "i32"), ("s", "s"),
             ("s", "i32"), ("bo", "bo"), ("bo", "i32"), ("bo", "d"), ("d", "d"), ("d", "dt"), ("dt", "dt"),
             ("dt", "i32"), ("n", "n"), ("n", "s"), ("a", "n"), ("d", "i32"), ("f32", "bo")]
PAIRS = {"sum": SUM_PAIRS, "min": MIN_PAIRS, "max": MAX_PAIRS}
for op in ["sum", "min", "max"]:
    for a, b in PAIRS[op]:
        case(f"horiz/{op}/two/{a}/{b}", "hz", [horiz(op, [col(a), col(b)])])
    if op != "max":
        for a in ["a", "i", "i32", "f32", "s", "bo", "d", "dt", "n"]:
            case(f"horiz/{op}/one/{a}", "hz", [horiz(op, [col(a)])])
    if op != "sum":
        case(f"horiz/{op}/f32-signed-zero", "hz", [horiz(op, [col("f32"), neg(col("f32"))])])
        case(f"horiz/{op}/str-code-point-order", "uo", [horiz(op, [col("x"), col("y")])])
    case(f"horiz/{op}/three-num", "hz", [horiz(op, [col("i"), col("i32"), col("f32")])])
    case(f"horiz/{op}/three-str-num", "hz", [horiz(op, [col("i"), col("s"), col("i")])])
    case(f"horiz/{op}/three-bool-date-str", "hz", [horiz(op, [col("bo"), col("d"), col("s")])])
    case(f"horiz/{op}/three-str-bool-date", "hz", [horiz(op, [col("s"), col("bo"), col("d")])])
    case(f"horiz/{op}/three-str", "hz", [horiz(op, [col("s"), col("s2"), col("s")])])
    case(f"horiz/{op}/three-null", "hz", [horiz(op, [col("n"), col("i"), col("n")])])
    case(f"horiz/{op}/zeros3", "hz", [horiz(op, [col("a"), col("b"), col("a")])])
    case(f"horiz/{op}/nan-first", "hz", [horiz(op, [col("b"), col("a")])])
    case(f"horiz/{op}/lit-weak", "hz", [horiz(op, [li(1), col("i32")])])
    case(f"horiz/{op}/lit-weak-big", "hz", [horiz(op, [col("i32"), li(1 << 40)])])
    case(f"horiz/{op}/lit-weak-float", "hz", [horiz(op, [col("i32"), lf(1.5)])])
    case(f"horiz/{op}/lit-two-weak", "hz", [horiz(op, [li(1), li(2)])])
    case(f"horiz/{op}/lit-null-col", "hz", [horiz(op, [lit("null", None), col("i")])])
    case(f"horiz/{op}/agg", "hz", [horiz(op, [agg("sum", col("i32")), col("i32")])])
    case(f"horiz/{op}/shape-head", "hz", [horiz(op, [head(col("i"), 2), head(col("i32"), 3)])])
    case(f"horiz/{op}/shape-one", "hz", [horiz(op, [head(col("i"), 1), col("i32")])])
    case(f"horiz/{op}/shape-one-alone", "hz", [horiz(op, [head(col("i"), 1), head(col("i32"), 1)]), col("i")])
    case(f"horiz/{op}/shape-zero", "hz", [horiz(op, [head(col("i"), 0), col("i32")])])
    case(f"horiz/{op}/cols-empty", "hz", [horiz(op, [cols([])])])
    case(f"horiz/{op}/no-inputs", "hz", [horiz(op, [])])
    case(f"horiz/{op}/e0", "e0", [horiz(op, [col("i32"), col("f64")])])
    case(f"horiz/{op}/e0-str", "e0", [horiz(op, [col("s"), col("s")])])
    case(f"horiz/{op}/e0-error", "e0", [horiz(op, [col("i32"), col("s")])])
# the rest does not depend on the operation: `sum` only
case("horiz/sum/three-int", "hz", [horiz("sum", [col("i32"), col("i"), col("bo")])])
case("horiz/sum/three-date-int", "hz", [horiz("sum", [col("d"), col("i"), col("i32")])])
case("horiz/sum/three-bool", "hz", [horiz("sum", [col("bo"), col("bo2"), col("bo")])])
case("horiz/sum/alias", "hz", [horiz("sum", [col("i"), col("i32")]).alias("z")])
case("horiz/sum/alias-inner", "hz", [horiz("sum", [alias(col("i"), "q"), col("i32")])])
case("horiz/sum/lit-first", "hz", [horiz("sum", [lit("i64", 5), col("i")])])
case("horiz/sum/lit-last", "hz", [horiz("sum", [col("i"), lit("i64", 5)])])
case("horiz/sum/lit-weak-last", "hz", [horiz("sum", [col("i32"), li(1)])])
case("horiz/sum/lit-weak-i64", "hz", [horiz("sum", [col("i"), li(1)])])
case("horiz/sum/lit-weak-f32", "hz", [horiz("sum", [col("f32"), li(1)])])
case("horiz/sum/lit-weak-float-f32", "hz", [horiz("sum", [col("f32"), lf(1.5)])])
case("horiz/sum/lit-weak-bool", "hz", [horiz("sum", [col("bo"), li(1)])])
case("horiz/sum/lit-weak-str", "hz", [horiz("sum", [col("s"), li(1)])])
case("horiz/sum/lit-weak-date", "hz", [horiz("sum", [col("d"), li(1)])])
case("horiz/sum/lit-weak-float-int", "hz", [horiz("sum", [li(1), lf(1.5)])])
case("horiz/sum/lit-bools", "hz", [horiz("sum", [lb(True), lb(False)])])
case("horiz/sum/lit-str-col", "hz", [horiz("sum", [ls("x"), col("s")])])
case("horiz/sum/lit-null", "hz", [horiz("sum", [lit("null", None)])])
case("horiz/sum/lit-col-null", "hz", [horiz("sum", [col("i"), lit("null", None)])])
case("horiz/sum/agg-two", "hz", [horiz("sum", [agg("sum", col("i")), agg("max", col("i"))])])
case("horiz/sum/arith", "hz", [bin_("add", horiz("sum", [col("i"), col("i32")]), li(1))])
case("horiz/sum/in-arith", "hz", [horiz("sum", [bin_("add", col("i"), li(1)), col("i32")])])
case("horiz/sum/shape-head2", "hz", [horiz("sum", [head(col("i32"), 3), head(col("i"), 2), col("f32")])])
case("horiz/sum/shape-head3", "hz", [horiz("sum", [col("i32"), head(col("i"), 2), head(col("f32"), 3)])])
case("horiz/sum/shape-same", "hz", [horiz("sum", [head(col("i"), 2), head(col("i32"), 2)])])
case("horiz/sum/shape-one-first", "hz", [horiz("sum", [col("i32"), head(col("i"), 1)])])
case("horiz/sum/shape-zero-alone", "hz", [horiz("sum", [head(col("i"), 0), head(col("i32"), 0)])])
case("horiz/sum/shape-zero-one", "hz", [horiz("sum", [head(col("i"), 0), head(col("i32"), 1)])])
case("horiz/sum/dup-name", "hz", [horiz("sum", [col("i"), col("i32")]), col("i")])
case("horiz/sum/names", "hz", [horiz("sum", [col("i32"), col("i")]), horiz("sum", [col("a"), col("b")]).alias("ab")])
case("horiz/sum/missing", "hz", [horiz("sum", [col("i"), col("zz")])])
case("horiz/sum/missing-first", "hz", [horiz("sum", [col("zz"), col("i")])])
case("horiz/sum/cols", "hz", [horiz("sum", [cols(["i", "i32"])])])
case("horiz/sum/cols-and-col", "hz", [horiz("sum", [cols(["i", "i32"]), col("f32")])])
case("horiz/sum/col-and-cols", "hz", [horiz("sum", [col("f32"), cols(["i", "i32"])])])
case("horiz/sum/two-cols", "hz", [horiz("sum", [cols(["i", "i32"]), cols(["f32", "a"])])])
case("horiz/sum/all", "hz", [horiz("sum", [all_])])
case("horiz/min/all", "hz", [horiz("min", [all_])])
case("horiz/sum/cols-empty-and-col", "hz", [horiz("sum", [cols([]), col("i")])])
case("horiz/sum/all-z0", "z0", [horiz("sum", [all_])])
case("horiz/sum/z0-lit", "z0", [horiz("sum", [li(1), li(2)])])
case("horiz/sum/z0-lit-str", "z0", [horiz("sum", [ls("a"), ls("b")])])
case("horiz/sum/e0-null", "e0", [horiz("sum", [col("n"), col("n")])])
case("horiz/sum/e0-lit", "e0", [horiz("sum", [col("i32"), li(1)])])
case("horiz/sum/r1", "r1", [horiz("sum", [col("i32"), col("i64"), col("f64")])])
case("horiz/min/r1", "r1", [horiz("min", [col("i32"), col("i64"), col("f64")])])
case("horiz/sum/wc", "hz", [horiz("sum", [col("i"), col("i32")]).alias("w")], op="with_columns")
case("horiz/sum/wc-in-place", "hz", [horiz("sum", [col("i"), col("i32")])], op="with_columns")
case("horiz/sum/wc-shape", "hz", [horiz("sum", [head(col("i"), 2), head(col("i32"), 2)]).alias("w")], op="with_columns")
case("horiz/sum/wc-shape-one", "hz", [horiz("sum", [head(col("i"), 1), head(col("i32"), 1)]).alias("w")], op="with_columns")
case("horiz/sum/wc-lit", "hz", [horiz("sum", [li(1), li(2)]).alias("w")], op="with_columns")
case("horiz/sum/wc-agg", "hz", [horiz("sum", [agg("sum", col("i")), agg("max", col("i"))]).alias("w")], op="with_columns")
case("horiz/sum/sort", "hz", [sort_(horiz("sum", [col("i"), col("i32")]))])
case("horiz/sum/cast", "hz", [cast(horiz("sum", [col("i"), col("i32")]), "f64")])
case("horiz/sum/sum-of", "hz", [agg("sum", horiz("sum", [col("i"), col("i32")]))])
case("horiz/sum/fill", "hz", [fill(horiz("sum", [col("i"), col("i32")]), li(0))])
case("horiz/min/nested", "hz", [horiz("min", [horiz("min", [col("i"), col("i32")]), col("f32")])])
# ignore_nulls=false
for a, b in [("i", "i"), ("a", "b"), ("s", "s2"), ("bo", "bo2"), ("n", "n"), ("i", "n"), ("i32", "i"), ("f32", "i"), ("d", "d"), ("dt", "i")]:
    case(f"horiz/sum-keep/two/{a}/{b}", "hz", [horiz("sum", [col(a), col(b)], False)])
for a in ["i", "bo", "s", "d", "n", "f32"]:
    case(f"horiz/sum-keep/one/{a}", "hz", [horiz("sum", [col(a)], False)])
case("horiz/sum-keep/three-num", "hz", [horiz("sum", [col("i"), col("i32"), col("f32")], False)])
case("horiz/sum-keep/lit", "hz", [horiz("sum", [li(1), col("i")], False)])
case("horiz/sum-keep/lit-null", "hz", [horiz("sum", [lit("null", None), col("i")], False)])
case("horiz/sum-keep/lits", "hz", [horiz("sum", [li(1), li(2)], False)])
case("horiz/sum-keep/e0", "e0", [horiz("sum", [col("i32"), col("i64")], False)])
case("horiz/sum-keep/agg", "hz", [horiz("sum", [agg("sum", col("i")), col("i")], False)])
case("horiz/sum-keep/wc", "hz", [horiz("sum", [col("i"), col("i32")], False).alias("w")], op="with_columns")

# ---------------------------------------------------------------------------
# Series methods
# ---------------------------------------------------------------------------
SERIES_CASES = []


def series_spec(name, dtype, values):
    return {"name": name, "dtype": dtype, "values": values}


SERIES_INPUTS = {
    "i64-nulls": ("x", "i64", [3, None, 1, 2, 3]),
    "i32": ("x", "i32", [1, 2, 3, 4]),
    "f64-nan": ("x", "f64", [1.0, nan, 2.0, None, -0.0, 0.0]),
    "f32": ("x", "f32", [0.5, nan, None, -inf, 3.0e38, 0.0]),
    "str": ("x", "str", ["b", None, "a", "", "Z"]),
    "bool": ("x", "bool", [True, None, False, True]),
    "date": ("x", "date", [0, 1, None, 19782]),
    "dt": ("x", "datetime[μs]", [5, None, 1709210096123456, -1]),
    "null": ("", "null", [None, None]),
    "empty-i64": ("e", "i64", []),
    "empty-str": ("e", "str", []),
    "empty-bool": ("e", "bool", []),
    "empty-date": ("e", "date", []),
    "f32-tan": ("x", "f32", [2.3713321685791016, 7.35245943069458, -1.5, 100.25]),
    "unnamed-i32": ("", "i32", [1, 2]),
}
SORT_INPUTS = {
    "empty": ("x", "i64", []), "one": ("x", "i64", [1]), "none1": ("x", "i64", [None]),
    "nones": ("x", "i64", [None, None]), "asc": ("x", "i64", [1, 2, 3]), "desc": ("x", "i64", [3, 2, 1]),
    "eq": ("x", "i64", [2, 2, 2]), "unsorted": ("x", "i64", [1, 3, 2]),
    "nl-first": ("x", "i64", [None, 1, 2]), "nl-last": ("x", "i64", [1, 2, None]),
    "nl-mid": ("x", "i64", [1, None, 2]), "desc-nl-first": ("x", "i64", [None, 3, 2]),
    "desc-nl-last": ("x", "i64", [3, 2, None]), "two-nulls-first": ("x", "i64", [None, None, 1]),
    "nulls-both": ("x", "i64", [None, 1, None]), "null-one": ("x", "i64", [None, 1]),
    "one-null": ("x", "i64", [1, None]),
    "f-nan-last": ("x", "f64", [1.0, 2.0, nan]), "f-nan-first": ("x", "f64", [nan, 1.0, 2.0]),
    "f-nan-mid": ("x", "f64", [1.0, nan, 2.0]), "f-zeros": ("x", "f64", [-0.0, 0.0]),
    "f-zeros2": ("x", "f64", [0.0, -0.0]), "f-nan-nan": ("x", "f64", [nan, nan]),
    "f-nan-null": ("x", "f64", [nan, None]), "f-null-nan": ("x", "f64", [None, nan]),
    "f-nan-desc": ("x", "f64", [nan, 2.0, 1.0]), "f-nan-desc2": ("x", "f64", [2.0, 1.0, nan]),
    "str": ("x", "str", ["a", "b", None]), "str2": ("x", "str", [None, "a", "b"]),
    "str-desc": ("x", "str", ["b", "a"]), "bool": ("x", "bool", [False, True, None]),
    "bool-desc": ("x", "bool", [True, False]), "date": ("x", "date", [1, 2, 3]),
    "dt-desc": ("x", "datetime[μs]", [3, 2, 1]), "null": ("x", "null", [None, None]),
    "f32": ("x", "f32", [1.0, nan]), "i32": ("x", "i32", [1, 2]),
}


def series_py(spec):
    n, dt, vals = spec
    return series_from_spec(n, dt, vals)


INPUT_KEYS = {}
INPUTS_S = {}


def input_key(spec):
    """The key of `spec` in the top-level `inputs` (shared by the cases that use it)."""
    skey = repr(spec)
    if skey not in INPUT_KEYS:
        INPUT_KEYS[skey] = f"{spec[1]}-{len(INPUT_KEYS)}"
        INPUTS_S[INPUT_KEYS[skey]] = encode_series(series_py(spec))
    return INPUT_KEYS[skey]


def series_case(cid, spec, method, args):
    s = series_py(spec)
    key = input_key(spec)
    rec = {"id": cid, "input": key, "method": method, "args": args}
    spelling = ", ".join(f"{k}={v!r}" for k, v in args.items())
    rec["polars"] = f"inputs[{key!r}].{method}({spelling})"
    try:
        out = getattr(s, method)(**args)
        if isinstance(out, pl.Series):
            rec["result"] = {"series": encode_series(to_ours(out)[0])}
        else:
            rec["result"] = {"bool": out}
    except BaseException as e:  # noqa: BLE001
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        name = type(e).__name__
        var = VARIANTS.get(name, name)
        var = PY_ERRORS.get(name, var)
        rec["error"] = var
        rec["message"] = str(e).split("\n")[0]
        if name == "PanicException":
            print("PANIC (skipped)", cid, rec["message"])
            return
    if method in TRIGS and "result" in rec:
        rec["ulp"] = True
    SERIES_CASES.append(rec)


for key, spec in SORT_INPUTS.items():
    for d in (False, True):
        for nl in (False, True):
            series_case(f"is_sorted/{key}/{'desc' if d else 'asc'}{'-nl' if nl else ''}", spec,
                        "is_sorted", {"descending": d, "nulls_last": nl})
for key, spec in SERIES_INPUTS.items():
    for m in ("any", "all"):
        for ig in (True, False):
            series_case(f"{m}/{key}/{'ign' if ig else 'keep'}", spec, m, {"ignore_nulls": ig})
KLEENE = {"[]": [], "[null]": [None], "[null,true]": [None, True], "[null,false]": [None, False],
          "[true,true]": [True, True], "[false,false]": [False, False], "[true,false]": [True, False]}
for key, vals in KLEENE.items():
    for m in ("any", "all"):
        for ig in (True, False):
            series_case(f"{m}/kleene{key}/{'ign' if ig else 'keep'}", ("k", "bool", vals), m, {"ignore_nulls": ig})
GE = ("x", "i64", [1, 2, 3, 4, 5, 6, 7])
for n, off in [(1, 0), (2, 0), (2, 1), (3, 0), (3, 2), (3, 6), (3, 7), (3, 10), (7, 0), (8, 0), (2, 100), (2, -1), (0, 0), (-1, 0), (0, 3)]:
    series_case(f"gather_every/i64/{n}/{off}", GE, "gather_every", {"n": n, "offset": off})
for key in ["i64-nulls", "str", "bool", "date", "dt", "null", "f64-nan", "empty-i64", "empty-str"]:
    series_case(f"gather_every/{key}/2/0", SERIES_INPUTS[key], "gather_every", {"n": 2, "offset": 0})
    series_case(f"gather_every/{key}/2/1", SERIES_INPUTS[key], "gather_every", {"n": 2, "offset": 1})
    series_case(f"gather_every/{key}/1/0", SERIES_INPUTS[key], "gather_every", {"n": 1, "offset": 0})
for f in TRIGS:
    for key in ["i64-nulls", "i32", "f64-nan", "f32", "str", "bool", "date", "dt", "null", "empty-i64"]:
        series_case(f"{f}/{key}", SERIES_INPUTS[key], f, {})
series_case("tan/f32-tan", SERIES_INPUTS["f32-tan"], "tan", {})
series_case("sin/f32-tan", SERIES_INPUTS["f32-tan"], "sin", {})
series_case("cos/f32-tan", SERIES_INPUTS["f32-tan"], "cos", {})

# DataFrame.gather_every
FRAME_CASES = []
GF = pl.DataFrame({"a": pl.Series([1, 2, 3, 4, 5], dtype=pl.Int64),
                   "b": pl.Series(["x", "y", None, "w", "v"], dtype=pl.String)})
TABLES["gf"] = GF
for n, off in [(1, 0), (2, 0), (2, 1), (5, 0), (6, 0), (0, 0), (-1, 0), (2, -1), (1, 3), (2, 10), (3, 4), (3, 5)]:
    rec = {"id": f"frame/gf/{n}/{off}", "table": "gf", "n": n, "offset": off,
           "polars": f"gf.gather_every({n}, {off})"}
    try:
        rec["result"] = encode_frame(GF.gather_every(n, off))
    except BaseException as e:  # noqa: BLE001
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        name = type(e).__name__
        rec["error"] = PY_ERRORS.get(name, VARIANTS.get(name, name))
        rec["message"] = str(e).split("\n")[0]
    FRAME_CASES.append(rec)
for t in ["e0", "z0", "r1"]:
    rec = {"id": f"frame/{t}", "table": t, "n": 2, "offset": 0, "polars": f"{t}.gather_every(2, 0)"}
    rec["result"] = encode_frame(TABLES[t].gather_every(2, 0))
    FRAME_CASES.append(rec)

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
def mb_cases_file():
    lines = ["// 由 docs/golden/scripts/expr_shape.py 生成，勿手改", ""]
    chunk = 60
    parts = [MB[i:i + chunk] for i in range(0, len(MB), chunk)]
    for pi, part in enumerate(parts):
        lines += ["///|", f"fn golden_expr_shape_cases_{pi}(m : Map[String, Array[@pl.Expr]]) -> Unit {{"]
        for cid, exprs in part:
            lines.append(f"  m[{mb_str(cid)}] = [{', '.join(exprs)}]")
        lines += ["}", ""]
    lines += ["///|", "/// Every case id with the expressions it builds.",
              "fn golden_expr_shape_cases() -> Map[String, Array[@pl.Expr]] {",
              "  let m : Map[String, Array[@pl.Expr]] = Map([])"]
    for pi in range(len(parts)):
        lines.append(f"  golden_expr_shape_cases_{pi}(m)")
    lines += ["  m", "}", ""]
    path = os.path.join(_repo_root(), "src", "pl", "expr_shape_cases_test.mbt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


used = {c.get("table", "t") for c in CASES} | {c["table"] for c in FRAME_CASES}
doc = {
    "tables": {name: encode_frame(df) for name, df in TABLES.items() if name in used},
    "inputs": INPUTS_S,
    "cases": CASES,
    "series_cases": SERIES_CASES,
    "frame_cases": FRAME_CASES,
}
emit("expr_shape", doc, compact=True)
# MoonBit source may not contain a raw U+2028/U+2029 (not even in a `#|` string)
path = os.path.join(_repo_root(), "src", "pl", "golden_expr_shape_data_test.mbt")
with open(path, encoding="utf-8") as f:
    text = f.read()
text = text.replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")
with open(path, "w", encoding="utf-8") as f:
    f.write(text)
mb_cases_file()
kinds = {"result": 0, "error": 0, "restricted": 0}
for c in CASES:
    for k in kinds:
        if k in c:
            kinds[k] += 1
print(f"{len(CASES)} cases", kinds, "known_diff:", sum(1 for c in CASES if "known_diff" in c))
print(f"{len(SERIES_CASES)} series cases: result", sum(1 for c in SERIES_CASES if "result" in c),
      "error", sum(1 for c in SERIES_CASES if "error" in c))
print(f"{len(FRAME_CASES)} frame cases")
