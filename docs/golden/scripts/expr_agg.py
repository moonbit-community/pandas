"""Generates the golden data of the expression aggregations, element-wise
functions and `when/then/otherwise` (docs/golden/expr_agg.json,
src/pl/golden_expr_agg_data_test.mbt) and the MoonBit expressions of every
case (src/pl/expr_agg_cases_test.mbt).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/expr_agg.py

It builds on the machinery of `expr.py` (T7): the part of that file before its
cases (tables, expression trees, renderers, `run`, `case`) is executed here and
extended with the nodes of this task, so the two data sets share the table `t`,
the encoding and the meaning of `result`, `error`, `restricted`, `known_diff`
(see the docstring of expr.py and docs/golden/known-diffs/expr_agg.md).

The file is `{"tables": {name: frame}, "inputs": {key: series}, "cases": [...]}`
(compact layout). `inputs` holds the Series that `is_in` takes as its values;
a case refers to one by key. Extra tables: `r1` (the first row of `t`).

Nodes added to the trees of expr.py:
  ("agg", op, x)                    sum mean min max count len n_unique first last median product
  ("std", x, ddof) ("var", x, ddof) ("quantile", x, q, method)
  ("fn", op, x)                     is_nan is_not_nan is_finite is_infinite abs sqrt exp
  ("log", x, base | None) ("round", x, decimals)
  ("fill_null", x, v) ("is_in", x, key) ("between", x, lo, hi, closed)
  ("when", cond, then, otherwise, chained)   (nested; `chained` renders a
                                              `.when()` link of the previous one)
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

# -- the shared part of expr.py ------------------------------------------------
_src = open(os.path.join(HERE, "expr.py"), encoding="utf-8").read()
_prefix = _src[: _src.index("ARITH = [")]
_ns = {"__name__": "expr_prefix", "__file__": os.path.join(HERE, "expr.py")}
exec(compile(_prefix, os.path.join(HERE, "expr.py"), "exec"), _ns)

pl = _ns["pl"]
series_from_spec = _ns["series_from_spec"]
encode_series = _ns["encode_series"]
to_ours = _ns["to_ours"]
emit = _ns["emit"]
_repo_root = _ns["_repo_root"]
TABLES = _ns["TABLES"]
T = _ns["T"]
ALL = _ns["ALL"]
NUMS = _ns["NUMS"]
DT_OF = _ns["DT_OF"]
CASES = _ns["CASES"]
MB = _ns["MB"]
IDS = _ns["IDS"]
encode_frame = _ns["encode_frame"]
col, cols, all_ = _ns["col"], _ns["cols"], _ns["all_"]
li, lf, ls, lb, lit = _ns["li"], _ns["lf"], _ns["ls"], _ns["lb"], _ns["lit"]
bin_, neg, not_, alias, cast = _ns["bin_"], _ns["neg"], _ns["not_"], _ns["alias"], _ns["cast"]
is_null, is_not_null = _ns["is_null"], _ns["is_not_null"]
mb_str, mb_float, mb_i64 = _ns["mb_str"], _ns["mb_float"], _ns["mb_i64"]
py_float = _ns["py_float"]
nan, inf = _ns["nan"], _ns["inf"]
I64_MAX, I64_MIN = _ns["I64_MAX"], _ns["I64_MIN"]
pure_weak, strong_all = _ns["pure_weak"], _ns["strong_all"]
_orig = {k: _ns[k] for k in ("to_pl", "to_py", "to_mb", "strengthen", "pure_weak")}

TABLES["r1"] = T.head(1)

# -- Series passed to is_in ---------------------------------------------------------
INPUTS = {
    "i32": ("i32", "v", [1, 2, None, 7, -2147483648]),
    "i64": ("i64", "v", [1, 3000000000, None, 3, -1]),
    "f32": ("f32", "v", [0.5, nan, None, 3.0e38]),
    "f64": ("f64", "v", [1.0, nan, None, -0.0, 2.5]),
    "str": ("str", "v", ["a", "｡", None, "", "\U0001F600"]),
    "bool": ("bool", "v", [True, None]),
    "bool-f": ("bool", "v", [False]),
    "date": ("date", "v", [0, 19782, None]),
    "dt": ("datetime[μs]", "v", [0, 1709210096123456, None]),
    "null": ("null", "v", [None, None]),
    "empty-i32": ("i32", "v", []),
    "empty-str": ("str", "v", []),
    "i32-unnamed": ("i32", "", [1, 7]),
    "i32-one": ("i32", "v", [7]),
}


def input_series(key):
    dt, name, vals = INPUTS[key]
    return series_from_spec(name, dt, vals)


# -- renderers --------------------------------------------------------------------------
NEW = {"agg", "std", "var", "quantile", "fn", "log", "round", "fill_null", "is_in",
       "between", "when"}
MB_METHOD = {"var": "var_"}
MB_QUANT = {"nearest": "Nearest", "higher": "Higher", "lower": "Lower",
            "midpoint": "Midpoint", "linear": "Linear", "equiprobable": "Equiprobable"}
MB_CLOSED = {"both": "Both", "left": "Left", "right": "Right", "none": "Neither"}


def when_chain(n):
    """`([(cond, then), ...], otherwise)` of a nested when node, following the
    `chained` links."""
    branches = []
    cur = n
    while True:
        branches.append((cur[1], cur[2]))
        o = cur[3]
        if o[0] == "when" and o[4]:
            cur = o
        else:
            return branches, o


def to_pl(n):
    k = n[0]
    if k not in NEW:
        return _orig["to_pl"](n)
    if k == "agg":
        return getattr(to_pl(n[2]), n[1])()
    if k == "std":
        return to_pl(n[1]).std(ddof=n[2])
    if k == "var":
        return to_pl(n[1]).var(ddof=n[2])
    if k == "quantile":
        return to_pl(n[1]).quantile(n[2], n[3])
    if k == "fn":
        return getattr(to_pl(n[2]), n[1])()
    if k == "log":
        return to_pl(n[1]).log() if n[2] is None else to_pl(n[1]).log(n[2])
    if k == "round":
        return to_pl(n[1]).round(n[2])
    if k == "fill_null":
        return to_pl(n[1]).fill_null(to_pl(n[2]))
    if k == "is_in":
        return to_pl(n[1]).is_in(input_series(n[2]))
    if k == "between":
        return to_pl(n[1]).is_between(to_pl(n[2]), to_pl(n[3]), closed=n[4])
    if k == "when":
        branches, other = when_chain(n)
        w = pl.when(to_pl(branches[0][0])).then(to_pl(branches[0][1]))
        for c, t in branches[1:]:
            w = w.when(to_pl(c)).then(to_pl(t))
        return w.otherwise(to_pl(other))
    raise ValueError(k)


def to_py(n):
    k = n[0]
    if k not in NEW:
        return _orig["to_py"](n)
    if k == "agg":
        return f"{to_py(n[2])}.{n[1]}()"
    if k == "std":
        return f"{to_py(n[1])}.std(ddof={n[2]})"
    if k == "var":
        return f"{to_py(n[1])}.var(ddof={n[2]})"
    if k == "quantile":
        return f"{to_py(n[1])}.quantile({py_float(n[2])}, {json.dumps(n[3])})"
    if k == "fn":
        return f"{to_py(n[2])}.{n[1]}()"
    if k == "log":
        return f"{to_py(n[1])}.log()" if n[2] is None else f"{to_py(n[1])}.log({py_float(n[2])})"
    if k == "round":
        return f"{to_py(n[1])}.round({n[2]})"
    if k == "fill_null":
        return f"{to_py(n[1])}.fill_null({to_py(n[2])})"
    if k == "is_in":
        dt, name, vals = INPUTS[n[2]]
        return f"{to_py(n[1])}.is_in(pl.Series({json.dumps(name)}, {vals!r}, dtype={_ns['POLARS_DTYPES'][dt]}))"
    if k == "between":
        return f"{to_py(n[1])}.is_between({to_py(n[2])}, {to_py(n[3])}, closed={json.dumps(n[4])})"
    if k == "when":
        branches, other = when_chain(n)
        text = f"pl.when({to_py(branches[0][0])}).then({to_py(branches[0][1])})"
        for c, t in branches[1:]:
            text += f".when({to_py(c)}).then({to_py(t)})"
        return text + f".otherwise({to_py(other)})"
    raise ValueError(k)


def to_mb(n):
    k = n[0]
    if k not in NEW:
        return _orig["to_mb"](n)
    if k == "agg":
        return f"{to_mb(n[2])}.{n[1]}()"
    if k in ("std", "var"):
        return f"{to_mb(n[1])}.{MB_METHOD.get(k, k)}(ddof={n[2]})"
    if k == "quantile":
        return f"{to_mb(n[1])}.quantile({mb_float(n[2])}, interpolation=@pl.QuantileMethod::{MB_QUANT[n[3]]})"
    if k == "fn":
        return f"{to_mb(n[2])}.{n[1]}()"
    if k == "log":
        return f"{to_mb(n[1])}.log()" if n[2] is None else f"{to_mb(n[1])}.log(base={mb_float(n[2])})"
    if k == "round":
        return f"{to_mb(n[1])}.round(decimals={n[2]})"
    if k == "fill_null":
        return f"{to_mb(n[1])}.fill_null({to_mb(n[2])})"
    if k == "is_in":
        return f"{to_mb(n[1])}.is_in(vs[{mb_str(n[2])}])"
    if k == "between":
        return f"{to_mb(n[1])}.between({to_mb(n[2])}, {to_mb(n[3])}, closed=@pl.ClosedInterval::{MB_CLOSED[n[4]]})"
    if k == "when":
        branches, other = when_chain(n)
        text = f"@pl.when({to_mb(branches[0][0])}).then({to_mb(branches[0][1])})"
        for c, t in branches[1:]:
            text += f".when({to_mb(c)}).then({to_mb(t)})"
        return text + f".otherwise({to_mb(other)})"
    raise ValueError(k)


def pure_weak_ext(n):
    if n[0] == "when":
        return False
    return _orig["pure_weak"](n)


def strengthen(n, keep_weak=False):
    """`expr.py`'s `strengthen` with the nodes of this file: the operands that
    meet each other (the two branches of a `when`, a value and what fills it,
    a value and its bounds) are weak next to a strong one and strong (64-bit)
    only when all of them are weak literals."""
    k = n[0]
    if k == "when":
        c, t, o = n[1], n[2], n[3]
        if pure_weak(t) and pure_weak(o):
            t2, o2 = strong_all(t), strong_all(o)
        else:
            t2, o2 = strengthen(t, True), strengthen(o, True)
        return ("when", strengthen(c), t2, o2, n[4])
    if k == "fill_null":
        if pure_weak(n[1]) and pure_weak(n[2]):
            return ("fill_null", strong_all(n[1]), strong_all(n[2]))
        return ("fill_null", strengthen(n[1], True), strengthen(n[2], True))
    if k == "between":
        parts = n[1:4]
        if all(pure_weak(p) for p in parts):
            parts = [strong_all(p) for p in parts]
        else:
            parts = [strengthen(p, True) for p in parts]
        return ("between", *parts, n[4])
    return _orig["strengthen"](n, keep_weak)


_ns["to_pl"] = to_pl
_ns["to_py"] = to_py
_ns["to_mb"] = to_mb
_ns["pure_weak"] = pure_weak_ext
_ns["strengthen"] = strengthen
pure_weak = pure_weak_ext
_case = _ns["case"]

# -- constructors -------------------------------------------------------------------------
class N(tuple):
    """A tree node with `.alias` (the nodes of expr.py are plain tuples)."""

    def alias(self, name):
        return N(("alias", self, name))


bin_ = lambda op, a, b: N(("bin", op, a, b))
agg = lambda op, x: N(("agg", op, x))
std = lambda x, ddof=1: N(("std", x, ddof))
var = lambda x, ddof=1: N(("var", x, ddof))
quant = lambda x, q, m="nearest": N(("quantile", x, q, m))
fn = lambda op, x: N(("fn", op, x))
log_ = lambda x, base=None: N(("log", x, base))
round_ = lambda x, d=0: N(("round", x, d))
fill = lambda x, v: N(("fill_null", x, v))
isin = lambda x, key: N(("is_in", x, key))
btw = lambda x, lo, hi, closed="both": N(("between", x, lo, hi, closed))
when_ = lambda c, t, o, chained=False: N(("when", c, t, o, chained))


def chain(branches, other):
    """`when(c1).then(t1).when(c2).then(t2)...otherwise(other)`."""
    node = other
    for i in range(len(branches) - 1, -1, -1):
        c, t = branches[i]
        node = when_(c, t, node, chained=(i > 0))
    return node


def case(cid, table, nodes, **kw):
    return _case(cid, table, nodes, **kw)


SIMPLE = ["sum", "mean", "min", "max", "count", "len", "n_unique", "first", "last",
          "median", "product"]
ALL_T = list(ALL)

# ---------------------------------------------------------------------------
# Aggregations
# ---------------------------------------------------------------------------
for tbl in ["t", "e0"]:
    sfx = "" if tbl == "t" else "/e0"
    for op in SIMPLE:
        for c in ALL_T:
            case(f"agg/{op}/{c}{sfx}", tbl, [agg(op, col(c))])
    for d in [0, 1, 2]:
        for c in ALL_T:
            if tbl == "e0" and d == 2:
                continue
            case(f"agg/std{d}/{c}{sfx}", tbl, [std(col(c), d)])
            case(f"agg/var{d}/{c}{sfx}", tbl, [var(col(c), d)])
    for c in ALL_T:
        case(f"agg/quantile/{c}{sfx}", tbl, [quant(col(c), 0.5)])
for m in ["nearest", "higher", "lower", "midpoint", "linear", "equiprobable"]:
    for c in ["i32", "f64", "d"]:
        for q in [0.0, 0.25, 0.9, 1.0]:
            case(f"agg/quantile-{m}/{q}/{c}", "t", [quant(col(c), q, m)])
for q in [-0.1, 1.5, nan, inf]:
    for c in ["f64", "i32", "s", "b", "n"]:
        case(f"agg/quantile-bad/{q}/{c}", "t", [quant(col(c), q)])
    case(f"agg/quantile-bad/{q}/e0", "e0", [quant(col("f64"), q)])
# the backticks of the message depend on nulls: `r1` has none (review T8 minor 2)
for c in ["i32", "f64", "d", "s"]:
    case(f"agg/quantile-bad/1.5/{c}/r1", "r1", [quant(col(c), 1.5)])

# several aggregates at once, aggregates of expressions, selectors
case("agg/many", "t", [agg("sum", col("i32")), agg("mean", col("f64")).alias("m"),
                       agg("min", col("s")).alias("mn"), agg("max", col("d")).alias("mx"),
                       agg("count", col("n")).alias("cn")])
case("agg/many/e0", "e0", [agg("sum", col("i32")), agg("mean", col("f64")).alias("m"),
                           agg("min", col("s")).alias("mn"), agg("max", col("d")).alias("mx"),
                           agg("len", col("n")).alias("ln")])
case("agg/many/z0-lit", "z0", [agg("sum", li(1)), agg("count", li(1)).alias("c")])
case("agg/of-expr", "t", [agg("sum", bin_("add", col("i32"), li(1)))])
case("agg/of-expr/cmp", "t", [agg("sum", bin_("gt", col("i64"), li(0)))])
case("agg/of-expr/cast", "t", [agg("sum", cast(col("f32"), "f64")).alias("x")])
case("agg/of-agg", "t", [agg("sum", agg("mean", col("i32")))])
case("agg/of-alias", "t", [agg("max", alias(col("i64"), "z"))])
case("agg/alias-after", "t", [alias(agg("sum", col("i32")), "z")])
case("agg/neg", "t", [neg(agg("sum", col("i32")))])
case("agg/is_null", "t", [is_null(agg("sum", col("n")))])
case("agg/cols", "num", [agg("sum", cols(["i32", "f64"]))])
case("agg/all", "num", [agg("max", all_)])
case("agg/all/e0", "num", [agg("count", all_)])
case("agg/cols-mean-lit", "num", [bin_("add", agg("mean", cols(["i32", "i64"])), li(1))])
for op in ["sum", "min", "mean", "count", "n_unique", "first"]:
    case(f"agg/lit/{op}", "t", [agg(op, li(1))])
    case(f"agg/litf/{op}", "t", [agg(op, lf(1.5))])
case("agg/lit-str/max", "t", [agg("max", ls("abc"))])
case("agg/lit-null/sum", "t", [agg("sum", lit("null", None))])
case("agg/lit-null/n_unique", "t", [agg("n_unique", lit("null", None))])
case("agg/missing-col", "t", [agg("sum", col("zz"))])
case("agg/sum-str-error-first", "t", [agg("sum", col("i32")), agg("sum", col("s")).alias("x")])
case("agg/dup-name", "t", [agg("sum", col("i32")), agg("max", col("i32"))])

# in arithmetic with the column: the aggregate is a length-1 operand
for c in ["i32", "i64", "f32", "f64"]:
    case(f"agg/op/{c}-mean", "t", [bin_("sub", col(c), agg("mean", col(c)))])
    case(f"agg/op/{c}-over-sum", "t", [bin_("div", col(c), agg("sum", col(c)))])
    case(f"agg/op/{c}-floordiv-sum", "t", [bin_("floordiv", col(c), agg("sum", col(c)))])
    case(f"agg/op/{c}-mod-max", "t", [bin_("mod", col(c), agg("max", col(c)))])
    case(f"agg/op/{c}-gt-mean", "t", [bin_("gt", col(c), agg("mean", col(c)))])
case("agg/op/agg-agg", "t", [bin_("sub", agg("max", col("i32")), agg("min", col("i32")))])
case("agg/op/agg-div-agg", "t", [bin_("div", agg("sum", col("i64")), agg("count", col("i64")))])
case("agg/op/agg-lit", "t", [bin_("add", agg("sum", col("i32")), li(1))])
case("agg/op/lit-agg", "t", [bin_("add", li(1), agg("sum", col("i32")))])
case("agg/op/agg-over-lit", "t", [bin_("div", agg("sum", col("i32")), li(0))])
case("agg/op/str-agg", "t", [bin_("add", col("s"), agg("max", col("s")))], restricted=True)
case("agg/op/z-score", "t", [bin_("div", bin_("sub", col("f64"), agg("mean", col("f64"))), std(col("f64")))])
case("agg/op/z-score/e0", "e0", [bin_("div", bin_("sub", col("f64"), agg("mean", col("f64"))), std(col("f64")))])

# ---------------------------------------------------------------------------
# Aggregates in select / with_columns (broadcast)
# ---------------------------------------------------------------------------
for tbl in ["t", "e0", "r1"]:
    for c in ["i32", "s", "n"]:
        case(f"bc/select/col-sum/{c}/{tbl}", tbl, [col(c), alias(agg("sum" if c in ("i32", "n") else "max", col(c)), "agg")])
        case(f"bc/select/sum-col/{c}/{tbl}", tbl, [alias(agg("count", col(c)), "agg"), col(c)])
    case(f"bc/wc/len/{tbl}", tbl, [alias(agg("len", col("i32")), "agg")], op="with_columns")
    case(f"bc/select/two-aggs/{tbl}", tbl, [agg("sum", col("i32")), agg("mean", col("f64")).alias("m")])
    case(f"bc/select/lit-agg/{tbl}", tbl, [li(1), agg("sum", col("i32"))])
    case(f"bc/select/agg-lit/{tbl}", tbl, [agg("sum", col("i32")), alias(li(1), "k")])
    case(f"bc/select/agg-col-lit/{tbl}", tbl, [agg("sum", col("i32")).alias("s"), col("i64"), alias(ls("k"), "k")])
    if tbl != "r1":
        case(f"bc/wc/agg-in-place/{tbl}", tbl, [agg("sum", col("i32")).alias("i32")], op="with_columns")
        case(f"bc/wc/two-aggs/{tbl}", tbl, [agg("sum", col("i32")).alias("a"), agg("mean", col("f64")).alias("b")], op="with_columns")
        case(f"bc/wc/mix/{tbl}", tbl, [bin_("sub", col("i64"), agg("mean", col("i64"))).alias("c"), agg("max", col("s")).alias("m")], op="with_columns")
    case(f"bc/select/centered/{tbl}", tbl, [bin_("sub", col("f64"), agg("mean", col("f64"))), bin_("sub", col("i64"), agg("min", col("i64"))).alias("r")])
    case(f"bc/select/frac/{tbl}", tbl, [alias(bin_("div", col("i32"), agg("sum", col("i32"))), "frac")])
case("bc/select/agg-all/z0", "z0", [agg("sum", li(1)), agg("max", li(2)).alias("m")])
case("bc/select/agg-lit/z0", "z0", [li(1), agg("sum", li(2)).alias("s")])
case("bc/wc/agg/z0", "z0", [agg("sum", li(1))], op="with_columns")
case("bc/select/cols-agg", "num", [agg("sum", cols(["i32", "i64"])), alias(agg("max", col("f64")), "x")])
case("bc/select/all-sum-broadcast", "num", [col("i32"), agg("sum", col("i64")).alias("s"), agg("mean", col("f32")).alias("m")])
case("bc/select/dup", "t", [col("i32"), agg("sum", col("i32"))])
case("bc/wc/dup", "t", [agg("sum", col("i32")).alias("x"), agg("max", col("i32")).alias("x")], op="with_columns",
     variant="DuplicateColumn")

# ---------------------------------------------------------------------------
# Element-wise functions
# ---------------------------------------------------------------------------
for op in ["is_nan", "is_not_nan", "is_finite", "is_infinite", "abs", "sqrt", "exp"]:
    for c in ALL_T:
        restricted = op in ("abs", "sqrt", "exp") and c in ("b", "s", "d", "dt")
        case(f"fn/{op}/{c}", "t", [fn(op, col(c))], restricted=restricted)
    case(f"fn/{op}/e0", "e0", [fn(op, col("f64")), fn(op, col("i32")).alias("i")])
    case(f"fn/{op}/lit-float", "t", [fn(op, lf(-2.5))])
    case(f"fn/{op}/lit-int", "t", [fn(op, li(-4))])
for base in [None, 2.0, 10.0, 0.5, 1.0, -2.0]:
    for c in ["i32", "i64", "f32", "f64"]:
        case(f"fn/log/{base}/{c}", "t", [log_(col(c), base)])
    for c in (["b", "s", "d", "dt", "n"] if base is None else ["s", "n"]):
        case(f"fn/log/{base}/{c}", "t", [log_(col(c), base)], restricted=(c != "n"))
    case(f"fn/log/{base}/e0", "e0", [log_(col("f64"), base)])
for d in [0, 1, 2, 5, 15]:
    for c in ALL_T:
        case(f"fn/round/{d}/{c}", "t", [round_(col(c), d)],
             restricted=(c in ("b", "s", "d", "dt")))
    case(f"fn/round/{d}/e0", "e0", [round_(col("f64"), d)])
# negative decimals: polars refuses in Python (OverflowError); see expr_agg_test.mbt
case("fn/round/lit", "t", [round_(lf(2.675), 2)])
case("fn/chain", "t", [fn("abs", log_(col("f64"), 2.0))])
case("fn/in-op", "t", [bin_("add", fn("abs", col("i32")), li(1))])
case("fn/in-op-sqrt", "t", [bin_("mul", fn("sqrt", col("f32")), col("f64"))])
case("fn/is_nan-agg", "t", [fn("is_nan", agg("sum", col("f64")))])
case("fn/abs-agg", "t", [fn("abs", agg("min", col("f64")))])
case("fn/abs-alias", "t", [fn("abs", alias(col("i32"), "z"))])
case("fn/abs-cols", "num", [fn("abs", cols(["i32", "f64"]))])
case("fn/abs-all", "num", [fn("is_nan", all_)])
case("fn/abs-neg", "t", [fn("abs", neg(col("i32")))])
case("fn/abs-missing", "t", [fn("abs", col("zz"))])
case("fn/abs-str-then-missing", "t", [fn("abs", col("s")), col("zz")])
case("fn/null-is_nan-agg", "t", [fn("is_nan", agg("mean", col("n")))])

# fill_null
FILL_LITS = {
    "int0": li(0), "int3e9": li(3000000000), "float1.5": lf(1.5), "str": ls("x"),
    "bool": lb(True), "null": lit("null", None),
    "i64": lit("i64", 7), "f32": lit("f32", 1.5),
    "date": lit("date", 5),
}
for c in ALL_T:
    for name, v in FILL_LITS.items():
        case(f"fill/lit/{c}/{name}", "t", [fill(col(c), v)])
    case(f"fill/lit/{c}/e0", "e0", [fill(col(c), li(0))])
for a in ALL_T:
    for b in ["i32", "i64", "f64", "s", "b", "d", "n"]:
        if a != b:
            case(f"fill/col/{a}/{b}", "t", [fill(col(a), col(b))])
case("fill/agg", "t", [fill(col("i32"), agg("mean", col("i32")))])
case("fill/agg-i64", "t", [fill(col("i64"), agg("min", col("i64")))])
case("fill/agg-all-null", "t", [fill(col("i32"), agg("first", col("n")))])
case("fill/agg-self", "t", [fill(agg("max", col("n")), col("i32"))])
case("fill/agg-self2", "t", [fill(agg("sum", col("i32")), col("i64"))])
case("fill/agg-agg", "t", [fill(agg("first", col("n")), agg("sum", col("i32")))])
case("fill/agg-agg/e0", "e0", [fill(agg("first", col("i32")), agg("sum", col("i64")))])
case("fill/agg-self/e0", "e0", [fill(agg("first", col("i32")), col("i64"))])
case("fill/e0-col", "e0", [fill(col("i32"), col("i64"))])
case("fill/expr", "t", [fill(bin_("add", col("i32"), li(1)), li(0))])
case("fill/expr-both", "t", [fill(bin_("add", col("i32"), li(1)), bin_("mul", col("i64"), li(2)))])
case("fill/lit-lit", "t", [fill(li(1), li(2))])
case("fill/lit-date", "t", [fill(li(1), col("d"))])
case("fill/lit-dt", "t", [fill(lf(1.5), col("dt"))])
case("fill/lit-neg-date", "t", [fill(col("d"), neg(li(1)))])
case("fill/lit-alias-date", "t", [fill(col("d"), alias(li(1), "q"))])
case("fill/lit-arith-date", "t", [fill(col("d"), bin_("add", li(1), li(2)))])
case("fill/lit-strong-date", "t", [fill(col("d"), lit("i32", 0))])
case("fill/lit-date-agg", "t", [fill(col("d"), agg("min", col("d")))])
case("fill/lit-col", "t", [fill(li(1), col("i32"))])
case("fill/null-lit-col", "t", [fill(lit("null", None), col("i32"))])
case("fill/null-lit-lit", "t", [fill(lit("null", None), li(1))])
case("fill/alias", "t", [alias(fill(col("i32"), li(0)), "z")])
case("fill/alias-value", "t", [fill(col("i32"), alias(col("i64"), "z"))])
case("fill/cols", "num", [fill(cols(["i32", "i64"]), li(0))])
case("fill/all-lit", "num", [fill(all_, lf(0.5))])
case("fill/cols-cols", "num", [fill(cols(["i32", "f32"]), cols(["i64", "f64"]))])
case("fill/nan-kept", "t", [fill(col("f64"), li(0))])
case("fill/missing", "t", [fill(col("i32"), col("zz"))])
case("fill/missing-order", "t", [fill(col("zz1"), col("zz2"))])
case("fill/wc", "t", [fill(col("i32"), li(0))], op="with_columns")
case("fill/wc-col", "t", [fill(col("i32"), col("i64")).alias("x")], op="with_columns")
case("fill/neg-lit", "t", [fill(col("i32"), neg(li(1)))])
case("fill/lit-arith", "t", [fill(col("i32"), bin_("add", li(1), li(2)))])
case("fill/f32-1e300", "t", [fill(col("f32"), lf(1e300))])
case("fill/i32-minus3e9", "t", [fill(col("i32"), li(-3000000000))])

# is_in
for c in ALL_T:
    for key in INPUTS:
        case(f"isin/{c}/{key}", "t", [isin(col(c), key)])
    case(f"isin/{c}/e0", "e0", [isin(col(c), "i32")] if c in ("i32", "i64") else [isin(col(c), "null")])
case("isin/expr", "t", [isin(bin_("add", col("i32"), li(1)), "i32")])
case("isin/agg", "t", [isin(agg("max", col("i32")), "i32")])
case("isin/lit-int", "t", [isin(li(7), "i32")])
case("isin/lit-str", "t", [isin(ls("a"), "str")])
case("isin/alias", "t", [alias(isin(col("i32"), "i32"), "z")])
case("isin/cols", "num", [isin(cols(["i32", "i64"]), "i32")])
case("isin/not", "t", [not_(isin(col("i32"), "i32"))])
case("isin/and", "t", [bin_("and", isin(col("i32"), "i32"), isin(col("i64"), "i64"))])
case("isin/missing", "t", [isin(col("zz"), "i32")])
case("isin/wc", "t", [isin(col("i32"), "i32").alias("x")], op="with_columns")

# between
BOUNDS = {
    "int": (li(0), li(7)), "int-wide": (li(-3000000000), li(3000000000)),
    "float": (lf(-1.0), lf(2.5)), "float-big": (lf(-1e300), lf(1e300)),
    "str": (ls("A"), ls("a")), "swapped": (li(7), li(0)),
    "bool": (lb(False), lb(True)), "same": (li(1), li(1)),
}
for c in ALL_T:
    for name, (lo, hi) in BOUNDS.items():
        case(f"btw/{c}/{name}", "t", [btw(col(c), lo, hi)])
    case(f"btw/{c}/e0", "e0", [btw(col(c), li(0), li(7))])
for closed in ["both", "left", "right", "none"]:
    for c in ["i32", "i64", "f32", "f64", "s", "d"]:
        case(f"btw-closed/{closed}/{c}", "t", [btw(col(c), col(c), col(c), closed)])
    case(f"btw-closed/{closed}/lit", "t", [btw(col("i32"), li(0), li(7), closed)])
    case(f"btw-closed/{closed}/f64-lit", "t", [btw(col("f64"), lf(-0.0), lf(2.5), closed)])
for a, lo, hi in [("i32", "i64", "f64"), ("i64", "i32", "i32"), ("f32", "f64", "i64"),
                  ("s", "s", "s"), ("d", "dt", "dt"), ("dt", "d", "d"), ("b", "i32", "i64"),
                  ("n", "n", "n"), ("i32", "n", "i64"), ("s", "d", "d"), ("d", "s", "s"),
                  ("s", "i32", "i32"), ("b", "d", "d"), ("f64", "f64", "f32")]:
    case(f"btw-col/{a}/{lo}/{hi}", "t", [btw(col(a), col(lo), col(hi))])
case("btw/agg-bounds", "t", [btw(col("i32"), agg("min", col("i32")), agg("max", col("i32")))])
case("btw/agg-bounds-f64", "t", [btw(col("f64"), agg("min", col("f64")), agg("max", col("f64")))])
case("btw/lit-value", "t", [btw(li(2), col("i32"), col("i64"))])
case("btw/lit-value-all-lit", "t", [btw(li(2), li(1), li(3))])
case("btw/alias", "t", [alias(btw(col("i32"), li(0), li(7)), "z")])
case("btw/expr", "t", [btw(bin_("add", col("i32"), li(1)), li(0), li(7))])
case("btw/not", "t", [not_(btw(col("i32"), li(0), li(7)))])
case("btw/cols", "num", [btw(cols(["i32", "i64"]), li(0), li(7))])
case("btw/all", "num", [btw(all_, lf(0.0), lf(3.0))])
case("btw/and", "t", [bin_("and", btw(col("i32"), li(0), li(7)), btw(col("f64"), lf(0.0), lf(3.0)))])
case("btw/missing", "t", [btw(col("i32"), col("zz"), li(1))])
case("btw/missing-order", "t", [btw(col("zz1"), col("zz2"), col("zz3"))])
case("btw/missing-order2", "t", [btw(col("i32"), col("zz2"), col("zz3"))])
for c in ["i32", "f64", "s", "d"]:
    case(f"btw/{c}/null-both", "t", [btw(col(c), lit("null", None), lit("null", None))])
    case(f"btw/{c}/null-col-lo", "t", [btw(col(c), col("n"), li(7))])
# a null literal as one bound: polars gives all null for most column types
# (`i32.is_between(pl.lit(None), 7)`, f64 or str columns, a typed null of another
# type) but the Kleene result (false where the other bound fails) for others
# (`i32` with `pl.lit(None, dtype=pl.Int32)`); not reproduced, see
# docs/golden/known-diffs/expr_agg.md. Only the stable ones are cases.
case("btw/i32/typed-null-lo", "t", [btw(col("i32"), lit("i32", None), li(7))])
case("btw/null-lit-value", "t", [btw(lit("null", None), li(0), li(7))])
case("btw/null-lit-cast", "t", [btw(col("i32"), cast(lit("null", None), "i32"), li(7))])
case("btw/null-lit-e0", "e0", [btw(col("i32"), lit("null", None), li(7))])
case("btw/wc", "t", [btw(col("i32"), li(0), li(7)).alias("x")], op="with_columns")

# ---------------------------------------------------------------------------
# when / then / otherwise
# ---------------------------------------------------------------------------
C_B = col("b")
# (the diagonal, a type with itself, is left out to stay in the size budget)
for x in ALL_T:
    for y in ALL_T:
        if x != y:
            case(f"when/types/{x}/{y}", "t", [when_(C_B, col(x), col(y))])
for c in ALL_T:
    case(f"when/cond/{c}", "t", [when_(col(c), li(1), li(2))])
case("when/basic", "t", [when_(bin_("gt", col("i32"), li(1)), ls("big"), ls("small"))])
case("when/basic-int", "t", [when_(bin_("gt", col("i32"), li(1)), col("i32"), li(0))])
case("when/basic-null-cond", "t", [when_(bin_("gt", col("i32"), li(0)), li(1), li(2))])
case("when/cond-null-goes-otherwise", "t", [when_(col("b"), col("i32"), col("i64"))])
case("when/no-match", "t", [when_(lb(False), col("i32"), col("i64"))])
case("when/all-match", "t", [when_(lb(True), col("i32"), col("i64"))])
case("when/cond-lit-null", "t", [when_(lit("null", None), col("i32"), col("i64"))])
case("when/cond-agg", "t", [when_(bin_("gt", agg("sum", col("i32")), li(3)), col("i32"), li(0))])
case("when/cond-agg-false", "t", [when_(bin_("gt", agg("sum", col("i32")), li(100)), col("i32"), li(0))])
case("when/then-agg", "t", [when_(col("b"), agg("sum", col("i32")), col("i32"))])
case("when/otherwise-agg", "t", [when_(col("b"), col("i32"), agg("max", col("i32")))])
case("when/all-agg", "t", [when_(bin_("gt", agg("sum", col("i32")), li(3)), agg("sum", col("i32")), agg("min", col("i32")))])
case("when/all-lit-cond", "t", [when_(lb(True), li(1), li(2))])
case("when/all-lit-cond-null", "t", [when_(bin_("gt", agg("sum", col("n")), li(3)), li(1), li(2))])
case("when/lit-lit", "t", [when_(col("b"), li(1), li(2))])
case("when/lit-lit-big", "t", [when_(col("b"), li(1), li(3000000000))])
case("when/lit-lit-float", "t", [when_(col("b"), li(1), lf(2.5))])
case("when/lit-lit-neg", "t", [when_(col("b"), neg(li(1)), li(2))])
case("when/lit-str", "t", [when_(col("b"), ls("x"), ls("y"))])
case("when/lit-bool", "t", [when_(col("b"), lb(True), lb(False))])
case("when/lit-null-then", "t", [when_(col("b"), lit("null", None), col("i32"))])
case("when/lit-null-otherwise", "t", [when_(col("b"), col("i32"), lit("null", None))])
case("when/lit-null-both", "t", [when_(col("b"), lit("null", None), lit("null", None))])
case("when/weak-i32", "t", [when_(col("b"), col("i32"), li(1))])
case("when/weak-i32-big", "t", [when_(col("b"), col("i32"), li(3000000000))])
case("when/weak-i32-big-then", "t", [when_(col("b"), li(3000000000), col("i32"))])
case("when/weak-f32", "t", [when_(col("b"), col("f32"), lf(1e300))])
case("when/weak-f32-int", "t", [when_(col("b"), col("f32"), li(3))])
case("when/weak-i64-float", "t", [when_(col("b"), col("i64"), lf(0.5))])
case("when/weak-i32-float", "t", [when_(col("b"), col("i32"), lf(0.5))])
case("when/weak-str", "t", [when_(col("b"), col("s"), li(1))])
case("when/weak-str-lit-int", "t", [when_(col("b"), li(1), col("s"))])
case("when/weak-bool", "t", [when_(col("b"), col("b"), li(1))])
case("when/weak-date", "t", [when_(col("b"), col("d"), li(1))])
case("when/weak-null", "t", [when_(col("b"), col("n"), li(1))])
case("when/strong-lit", "t", [when_(col("b"), col("i32"), lit("i64", 5))])
case("when/strong-lit-date", "t", [when_(col("b"), col("d"), lit("date", 5))])
case("when/strong-lit-dt", "t", [when_(col("b"), col("dt"), lit("datetime[μs]", 5))])
case("when/strong-f32", "t", [when_(col("b"), col("f32"), lit("f32", 1.5))])
case("when/names/then-col", "t", [when_(col("b"), col("i32"), col("i64"))])
case("when/names/then-lit", "t", [when_(col("b"), li(1), col("i32"))])
case("when/names/alias-then", "t", [when_(col("b"), alias(col("i32"), "q"), alias(col("i64"), "r"))])
case("when/names/alias-otherwise", "t", [when_(col("b"), col("i32"), alias(col("i64"), "r"))])
case("when/names/alias-after", "t", [alias(when_(col("b"), col("i32"), col("i64")), "z")])
case("when/names/cond-named", "t", [when_(alias(col("b"), "c"), li(1), li(2))])
case("when/names/dup", "t", [when_(col("b"), col("i32"), li(0)), col("i32")])
case("when/names/dup-ok", "t", [when_(col("b"), col("i32"), li(0)), alias(col("i32"), "x")])
# chains: nested ternaries (Review T8 item 1)
for n in [2, 3, 4]:
    br = [(bin_("gt", col("i32"), li(k)), col("i64") if k % 2 else col("i32")) for k in range(n)]
    case(f"when/chain/{n}", "t", [chain(br, li(0))])
case("when/chain/names-first-lit", "t", [chain([(col("b"), li(1)), (bin_("gt", col("i32"), li(1)), col("i64"))], col("f64"))])
case("when/chain/names-first-col", "t", [chain([(col("b"), col("i32")), (bin_("gt", col("i32"), li(1)), li(5))], col("f64"))])
case("when/chain/null-conds", "t", [chain([(col("b"), li(1)), (is_null(col("i32")), li(2))], li(3))])
case("when/chain/null-conds-all", "t", [chain([(col("b"), ls("b")), (bin_("gt", col("i32"), li(0)), ls("pos")), (bin_("lt", col("i32"), li(0)), ls("neg"))], ls("zero"))])
case("when/chain/types", "t", [chain([(col("b"), col("i32")), (is_null(col("i32")), col("f32"))], col("i64"))])
case("when/chain/weak", "t", [chain([(col("b"), col("i32")), (is_null(col("i32")), li(5))], li(3))])
case("when/chain/weak-lits", "t", [chain([(col("b"), li(1)), (is_null(col("i32")), li(5))], li(3))])
case("when/chain/weak-big", "t", [chain([(col("b"), li(1)), (is_null(col("i32")), li(3000000000))], li(3))])
case("when/chain/weak-float", "t", [chain([(col("b"), li(1)), (is_null(col("i32")), lf(0.5))], li(3))])
case("when/chain/str", "t", [chain([(col("b"), ls("T")), (is_null(col("s")), col("s"))], ls("none"))])
case("when/chain/scalar-branch", "t", [chain([(col("b"), agg("sum", col("i32"))), (is_null(col("i32")), agg("min", col("i64")))], col("i32"))])
case("when/chain/alias", "t", [alias(chain([(col("b"), li(1)), (is_null(col("i32")), li(2))], li(3)), "z")])
case("when/nested/otherwise", "t", [when_(col("b"), li(1), when_(is_null(col("i32")), li(2), li(3)))])
case("when/nested/then", "t", [when_(col("b"), when_(is_null(col("i32")), li(1), li(2)), li(3))])
case("when/nested/cond", "t", [when_(when_(col("b"), lb(True), is_null(col("i32"))), li(1), li(2))])
case("when/nested/then-chain", "t", [when_(col("b"), chain([(is_null(col("i32")), li(1)), (bin_("gt", col("i32"), li(1)), li(2))], li(3)), li(4))])
case("when/chain/e0", "e0", [chain([(col("b"), col("i32")), (is_null(col("i32")), col("i64"))], col("f64"))])
# errors
case("when/err/cond-int", "t", [when_(col("i32"), li(1), li(2))])
case("when/err/cond-str", "t", [when_(col("s"), li(1), li(2))])
case("when/err/cond-null-col", "t", [when_(col("n"), li(1), li(2))])
case("when/err/cond-lit-int", "t", [when_(lit("i32", 1), col("i32"), col("i64"))])
case("when/err/cond-agg", "t", [when_(agg("sum", col("i32")), li(1), li(2))])
case("when/err/cond-date", "t", [when_(col("d"), li(1), li(2))])
case("when/err/supertype", "t", [when_(col("b"), col("b"), col("d"))])
case("when/err/supertype-dt", "t", [when_(col("b"), col("dt"), col("b"))])
case("when/err/supertype-then-cond", "t", [when_(col("i32"), col("b"), col("d"))])
case("when/err/chain-supertype", "t", [chain([(col("b"), col("i32")), (col("b"), col("d"))], col("i64"))])
def E(x):
    """A kernel error with a text of its own: `s == col(x)` (text against a number)."""
    return bin_("eq", col("s"), col(x))


case("when/err/then-kernel", "t", [when_(col("b"), E("i32"), col("b"))])
case("when/err/otherwise-kernel", "t", [when_(col("b"), col("b"), E("i32"))])
case("when/err/cond-kernel", "t", [when_(E("i32"), col("i32"), col("i64"))])
case("when/err/order-then-otherwise", "t", [when_(col("b"), E("i32"), E("i64"))])
case("when/err/order-otherwise-cond", "t", [when_(E("i32"), col("b"), E("i64"))])
case("when/err/order-then-cond", "t", [when_(E("i32"), E("i64"), col("b"))])
case("when/err/order-all", "t", [when_(E("i32"), E("i64"), E("f64"))])
C2 = is_null(col("s"))
NB = not_(col("b"))
case("when/err/order-chain-conds", "t", [chain([(E("i32"), col("b")), (E("i64"), NB)], C2)])
case("when/err/order-chain-then1-then2", "t", [chain([(col("b"), E("i32")), (C2, E("i64"))], NB)])
case("when/err/order-chain-then1-cond2", "t", [chain([(col("b"), E("i32")), (E("i64"), NB)], C2)])
case("when/err/order-chain-cond1-then2", "t", [chain([(E("i32"), col("b")), (C2, E("i64"))], NB)])
case("when/err/order-chain-cond2-then2", "t", [chain([(col("b"), NB), (E("i32"), E("i64"))], C2)])
case("when/err/order-chain-cond2-otherwise", "t", [chain([(col("b"), NB), (E("i32"), C2)], E("i64"))])
case("when/err/order-chain-then2-otherwise", "t", [chain([(col("b"), NB), (C2, E("i32"))], E("i64"))])
case("when/err/order-chain-supertype-cond", "t", [chain([(E("i32"), col("b")), (col("b"), col("d"))], NB)])
# polars knows the type of a branch that fails when run (`s == i32` is bool) and
# reports the supertype error; here a failed branch has no type: known diff
case("when/err/kernel-vs-cond", "t", [when_(col("i32"), E("i64"), col("b"))])
case("when/err/missing-cond", "t", [when_(col("zz"), li(1), li(2))])
case("when/err/missing-then", "t", [when_(col("b"), col("zz"), li(2))])
case("when/err/missing-otherwise", "t", [when_(col("b"), li(1), col("zz"))])
case("when/err/missing-vs-kernel", "t", [when_(col("b"), bin_("add", col("s"), li(1)), col("zz"))])
case("when/err/missing-order", "t", [when_(col("zz1"), col("zz2"), col("zz3"))])
case("when/err/missing-order2", "t", [when_(col("b"), col("zz2"), col("zz3"))])
case("when/err/missing-order-chain", "t", [chain([(col("b"), col("i32")), (col("zz1"), col("zz2"))], col("zz3"))])
case("when/err/missing-chain", "t", [chain([(col("b"), li(1)), (col("b"), col("zz"))], li(3))])
# widths of a chain: the outer (condition, then) pair is checked before the
# `otherwise`, where the rest of the chain is nested (review T8 important 1)
W = {0: cols([]), 1: col("i32"), 2: cols(["i32", "i64"]), 3: cols(["i32", "i64", "f64"])}


def wchain(ws):
    br = [(is_not_null(W[ws[2 * i]]), W[ws[2 * i + 1]]) for i in range((len(ws) - 1) // 2)]
    return chain(br, W[ws[-1]])


for ws in [(0, 2, 0, 3, 1), (2, 2, 3, 3, 1), (1, 2, 1, 3, 2), (1, 2, 2, 2, 2), (0, 2, 0, 3, 0, 2, 1), (1, 2, 1, 2, 3, 2, 2), (2, 1, 1, 1, 0)]:
    case("when/width/" + "".join(map(str, ws)), "num", [wchain(ws)])
# shapes
case("when/shape/e0", "e0", [when_(col("b"), col("i32"), col("i64"))])
case("when/shape/e0-lit", "e0", [when_(col("b"), li(1), li(2))])
case("when/shape/e0-then-agg", "e0", [when_(col("b"), agg("sum", col("i32")), col("i64"))])
case("when/shape/e0-otherwise-agg", "e0", [when_(col("b"), col("i32"), agg("sum", col("i64")))])
case("when/shape/e0-cond-agg", "e0", [when_(agg("first", col("b")), col("i32"), col("i64"))])
case("when/shape/e0-all-agg", "e0", [when_(agg("first", col("b")), agg("sum", col("i32")), agg("sum", col("i64")))])
case("when/shape/e0-lit-agg", "e0", [when_(col("b"), li(1), agg("sum", col("i64")))])
case("when/shape/z0-lit", "z0", [when_(lb(True), li(1), li(2))])
case("when/shape/r1", "r1", [when_(col("b"), col("i32"), col("i64"))])
case("when/shape/r1-agg", "r1", [when_(col("b"), agg("sum", col("i32")), col("i64"))])
case("when/shape/select-lit", "t", [when_(col("b"), col("i32"), li(0)), li(1)])
case("when/shape/select-agg", "t", [when_(col("b"), col("i32"), li(0)).alias("x"), agg("sum", col("i32"))])
case("when/shape/wc", "t", [when_(col("b"), li(1), li(2))], op="with_columns")
case("when/shape/wc-in-place", "t", [alias(when_(col("b"), col("i32"), li(0)), "i32")], op="with_columns")
case("when/shape/wc-agg", "t", [when_(bin_("gt", agg("sum", col("i32")), li(3)), li(1), li(2))], op="with_columns")
case("when/shape/wc-e0", "e0", [when_(col("b"), li(1), li(2))], op="with_columns")
case("when/shape/wc-z0", "z0", [when_(lb(True), li(1), li(2))], op="with_columns")
# selectors and composition
case("when/sel/cols-then", "num", [when_(lb(True), cols(["i32", "i64"]), li(0))])
case("when/sel/cols-cond", "t", [when_(cols(["b"]), li(1), li(2))])
case("when/sel/all-otherwise", "num", [when_(lb(True), col("i32"), all_)])
case("when/sel/width", "num", [when_(lb(False), cols(["i32", "i64"]), cols(["i32", "i64", "f64"]))])
case("when/sel/all-all", "num", [when_(lb(False), all_, all_)])
case("when/in-op", "t", [bin_("add", when_(col("b"), col("i32"), li(0)), li(1))])
case("when/in-op-weak", "t", [bin_("add", when_(col("b"), li(1), li(2)), col("i32"))])
case("when/in-agg", "t", [agg("sum", when_(col("b"), col("i32"), li(0)))])
case("when/in-cmp", "t", [bin_("gt", when_(col("b"), col("i32"), li(0)), li(1))])
case("when/in-fill", "t", [fill(when_(col("b"), col("i32"), lit("null", None)), li(-1))])
case("when/fill-value", "t", [fill(col("i32"), when_(col("b"), li(1), li(2)))])
case("when/not-cond", "t", [when_(not_(col("b")), col("i32"), col("i64"))])
case("when/cond-and", "t", [when_(bin_("and", col("b"), bin_("gt", col("i32"), li(0))), li(1), li(0))])
case("when/cond-between", "t", [when_(btw(col("i32"), li(0), li(7)), ls("in"), ls("out"))])
case("when/cond-isin", "t", [when_(isin(col("i32"), "i32"), ls("in"), ls("out"))])
case("when/cond-is_null", "t", [when_(is_null(col("i32")), li(0), col("i32"))])
case("when/cond-nan", "t", [when_(fn("is_nan", col("f64")), lf(0.0), col("f64"))])
case("when/clip", "t", [alias(when_(bin_("gt", col("i64"), li(10)), li(10), col("i64")), "i64")])
case("when/sign", "t", [when_(bin_("gt", col("f64"), lf(0.0)), li(1), when_(bin_("lt", col("f64"), lf(0.0)), li(-1), li(0)))])

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------


def mb_cases_file():
    lines = ["// 由 docs/golden/scripts/expr_agg.py 生成，勿手改", ""]
    chunk = 60
    parts = [MB[i:i + chunk] for i in range(0, len(MB), chunk)]
    sig = "m : Map[String, Array[@pl.Expr]], vs : Map[String, @pl.Series]"
    for pi, part in enumerate(parts):
        lines += ["///|", f"fn golden_expr_agg_cases_{pi}({sig}) -> Unit {{", "  ignore(vs)"]
        for cid, exprs in part:
            lines.append(f"  m[{mb_str(cid)}] = [{', '.join(exprs)}]")
        lines += ["}", ""]
    lines += ["///|", "/// Every case id with the expressions it builds; `vs` is the `inputs` table.",
              "fn golden_expr_agg_cases(vs : Map[String, @pl.Series]) -> Map[String, Array[@pl.Expr]] {",
              "  let m : Map[String, Array[@pl.Expr]] = Map([])"]
    for pi in range(len(parts)):
        lines.append(f"  golden_expr_agg_cases_{pi}(m, vs)")
    lines += ["  m", "}", ""]
    path = os.path.join(_repo_root(), "src", "pl", "expr_agg_cases_test.mbt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


doc = {
    "tables": {name: encode_frame(df) for name, df in TABLES.items()},
    "inputs": {k: encode_series(input_series(k)) for k in INPUTS},
    "cases": CASES,
}
emit("expr_agg", doc, compact=True)
mb_cases_file()
kinds = {"result": 0, "error": 0, "restricted": 0}
for c in CASES:
    for k in kinds:
        if k in c:
            kinds[k] += 1
print(f"{len(CASES)} cases", kinds, "known_diff:", sum(1 for c in CASES if "known_diff" in c))
