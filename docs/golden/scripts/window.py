"""Generates the golden data of `Expr::over(partition_by)` (docs/golden/window.json,
src/pl/golden_window_data_test.mbt) and the MoonBit expressions of every case
(src/pl/window_cases_test.mbt).

Run from the repository root (on a machine with polars 2.1.0):
    ulimit -v 16000000; POLARS_MAX_THREADS=4 \
        /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/window.py

Built on `shape_base.py` (the expression machinery of `expr_shape.py` and the
nodes `("len",)` and `("over", x, [keys])`). Every case is
`table.<op>([expressions])` with `op` one of `select` (the default),
`with_columns`, `filter` (one predicate) and `sort` (the sort keys, an `id`
column last to break ties); `result`, `error` + `message`, `restricted`,
`known_diff` and `str` (polars' `str(expr)` of every expression) mean what they
mean in `expr.py` and `expr_agg.py`; see docs/golden/known-diffs/window.md.

Extra tables: `w` (12 rows: partition keys `k` (with a null group and a group
of one row), `j`, `k2` (groups of at most two rows) and `id` (every group has
one row), one column of every type with nulls, NaN, `-0.0`, infinities
(`i32`, `i64`, `f32`, `f64`, `s`, `b`, `d`, `dt`, `n`), `x`, `y`, `v`, `vn`),
`wbig` (300 rows, groups of 140, 130, 4 and 26 rows: the order of the
additions of a float sum), `we` (the schema of `w`, no rows), `w1` (one row).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from shape_base import W, len_, over  # noqa: E402

A = W["A"]
S = W["S"]
pl = W["pl"]
emit = W["emit"]
encode_frame = W["encode_frame"]
series_from_spec = W["series_from_spec"]
_repo_root = W["_repo_root"]
TABLES = W["TABLES"]
CASES = W["CASES"]
MB = W["MB"]
col, cols, all_ = W["col"], W["cols"], W["all_"]
li, lf, ls, lb, lit = W["li"], W["lf"], W["ls"], W["lb"], W["lit"]
bin_, neg, not_, alias, cast = W["bin_"], W["neg"], W["not_"], W["alias"], W["cast"]
is_null, is_not_null = W["is_null"], W["is_not_null"]
agg, fill, fn = W["agg"], W["fill"], W["fn"]
when_ = W["when_"]
std, var, quant = A["std"], A["var"], A["quant"]
shift, cum, rank, reverse = W["shift"], W["cum"], W["rank"], W["reverse"]
diff, fills = S["diff"], S["fills"]
st = W["st"]
mb_str = W["mb_str"]
nan, inf = W["nan"], W["inf"]
I64_MAX, I64_MIN = W["I64_MAX"], W["I64_MIN"]
sort_, arg_sort, sort_by, head, tail, slice_ = (
    W["sort_"], W["arg_sort"], W["sort_by"], W["head"], W["tail"], W["slice_"])
unique, drop_nulls, filter_, any_, all_fn = (
    W["unique"], W["drop_nulls"], W["filter_"], W["any_"], W["all_fn"])
horiz = W["horiz"]
_case = W["case"]

# -- tables ---------------------------------------------------------------------------
G = {
    "id": list(range(12)),
    "k": [1, 1, 2, 1, None, 2, 1, 3, 3, 1, 2, 1],
    "j": ["a", "b", "a", "b", "a", None, "b", "a", "b", "a", None, "b"],
    "k2": [1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 6, 7],
    "v": [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8],
    "vn": [3, None, 4, 1, None, 9, 2, 6, None, 3, 5, 8],
    "i32": [1, 2, 1, None, 2, 1, None, 2147483647, 1, 2, None, 2147483647],
    "i64": [3, 3, I64_MAX, I64_MIN, None, 3, I64_MAX, None, 3, 3, I64_MIN, None],
    "f32": [1.0, nan, None, -0.0, 0.0, nan, None, 1.0, -0.0, 3.0e38, 0.5, -inf],
    "f64": [1.0, nan, None, -0.0, 0.0, nan, None, 1.0, -0.0, inf, 2.5, -inf],
    "s": ["a", "｡", "\U0001F600", "a", None, "", "Z", "｡", None, "a", "", "Z"],
    "b": [True, False, None, True, False, None, True, True, False, None, True, False],
    "d": [0, -1, 19782, None, 0, -1, None, 19782, 0, -25567, -1, None],
    "dt": [0, -1, 1709210096123456, None, 0, -1, None, 1709210096123456, 0, 86399999999, -1, None],
    "n": [None] * 12,
    "x": [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2],
    "y": [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120],
}
GT = {"id": "i64", "k": "i64", "j": "str", "k2": "i64", "v": "i64", "vn": "i64", "i32": "i32",
      "i64": "i64", "f32": "f32", "f64": "f64", "s": "str", "b": "bool", "d": "date",
      "dt": "datetime[μs]", "n": "null", "x": "f64", "y": "i64"}
GCOLS = ["i32", "i64", "f32", "f64", "s", "b", "d", "dt", "n"]
WDF = pl.DataFrame([series_from_spec(c, GT[c], v) for c, v in G.items()])
BIG_N = 300
_perm = [(i * 13) % BIG_N for i in range(BIG_N)]
BIG = {
    "k": [0 if p < 140 else 1 if p < 270 else 2 if p < 274 else 3 for p in _perm],
    "x": [((i * 7919) % 1000) / 7.0 - 50.0 + 1e-3 * i for i in range(BIG_N)],
    "xf": [((i * 104729) % 997) / 3.0 - 100.0 + 1e-2 * i for i in range(BIG_N)],
    "v": [(i * 37) % 101 - 50 for i in range(BIG_N)],
}
BIGT = {"k": "i64", "x": "f64", "xf": "f32", "v": "i64"}
TABLES["w"] = WDF
TABLES["we"] = WDF.clear()
TABLES["w1"] = WDF.head(1)
TABLES["wbig"] = pl.DataFrame([series_from_spec(c, BIGT[c], v) for c, v in BIG.items()])


def case(cid, table, nodes, **kw):
    return _case(cid, table, nodes, **kw)


def stricter(op, c):
    """polars gives nulls where the library refuses (the sum of a Date or Datetime,
    the quantile of text, Boolean and Null): see known-diffs/window.md."""
    return (op == "sum" and c in ("d", "dt")) or (op == "quantile" and c in ("s", "b", "n"))


K, J, ID, K2 = col("k"), col("j"), col("id"), col("k2")
V, VN, X, Y = col("v"), col("vn"), col("x"), col("y")
OK = lambda x: over(x, [K])
SIMPLE = ["sum", "mean", "min", "max", "count", "len", "n_unique", "first", "last", "median", "product"]

# ---------------------------------------------------------------------------
# Aggregations: every operation, one value per partition repeated on its rows
# ---------------------------------------------------------------------------
for op in ["sum", "mean", "min", "max", "count", "n_unique", "first"]:
    for c in GCOLS:
        case(f"agg/{op}/{c}", "w", [OK(agg(op, col(c)))], restricted=stricter(op, c))
for op in ["len", "last", "median", "product"]:
    for c in ["i32", "f64", "s", "b"]:
        case(f"agg/{op}/{c}", "w", [OK(agg(op, col(c)))])
for op, d in [("std", 1), ("std", 0), ("var", 1), ("var", 0)]:
    for c in ["i32", "f32", "f64", "v"]:
        case(f"agg/{op}{d}/{c}", "w", [OK((std if op == "std" else var)(col(c), d))])
for c in ["i32", "f64", "v", "s"]:
    case(f"agg/quantile/{c}", "w", [OK(quant(col(c), 0.5))], restricted=stricter("quantile", c))
case("agg/quantile-lower/f64", "w", [OK(quant(col("f64"), 0.3, "lower"))])
case("agg/sum/v-by-j", "w", [over(agg("sum", V), [J])])
case("agg/sum-two", "w", [OK(agg("sum", V)), OK(agg("mean", X)).alias("m")])
case("agg/sum-with-columns", "w", [OK(agg("sum", V)).alias("tot")], op="with_columns")
case("agg/sum-replaces", "w", [OK(agg("sum", V))], op="with_columns")
case("agg/sum-literal-next", "w", [lit("i32", 7), OK(agg("sum", V)).alias("t")])
case("agg/sum-cols", "w", [over(agg("sum", cols(["v", "y"])), [K])])
case("agg/sum-all-is-text", "w", [over(agg("sum", all_), [K])])
case("agg/sum-unsupported-text", "w", [OK(agg("sum", col("s")))])
case("agg/mean-unsupported-text", "w", [OK(agg("mean", col("s")))])
case("agg/missing-column", "w", [OK(agg("sum", col("zz")))])

# ---------------------------------------------------------------------------
# Literals and pl.len()
# ---------------------------------------------------------------------------
case("lit/int", "w", [OK(li(1))])
case("lit/float", "w", [OK(lf(1.5))])
case("lit/str", "w", [OK(ls("q"))])
case("lit/bool", "w", [OK(lb(True))])
case("lit/null", "w", [OK(lit("null", None))])
case("lit/i32", "w", [OK(lit("i32", 7))])
case("lit/plus-lit", "w", [OK(bin_("add", li(1), li(2)))])
case("len/plain", "w", [OK(len_)])
case("len/plus", "w", [OK(bin_("add", len_, li(1)))])
case("len/times-sum", "w", [OK(bin_("mul", len_, agg("sum", V)))])
case("len/by-id", "w", [over(len_, [ID])])
case("len/by-two", "w", [over(len_, [K, J])])
case("len/count-vs-len", "w", [OK(agg("count", VN)).alias("c"), OK(agg("len", VN)).alias("l"), OK(len_).alias("n")])

# ---------------------------------------------------------------------------
# Sequence operations see the rows of the partition in their order
# ---------------------------------------------------------------------------
for op in ["sum", "min", "max", "prod", "count"]:
    for c in ["v", "vn", "f64", "i32"] if op in ("sum", "max") else ["vn", "f64"]:
        for rev in (False, True):
            case(f"cum_{op}/{c}/{'rev' if rev else 'fwd'}", "w", [OK(cum(op, col(c), rev))])
for c in ["s", "b", "d", "n"]:
    case(f"cum_sum/{c}", "w", [OK(cum("sum", col(c)))])
for n in [1, 2, -1, 0, 20]:
    for c in ["v", "s", "d"]:
        case(f"shift/{c}/{n}", "w", [OK(shift(col(c), n))])
case("shift/fill", "w", [OK(shift(V, 1, ["i32", 5]))])
case("shift/fill-neg", "w", [OK(shift(col("s"), -2, ["str", "z"]))])
for n in [1, 2, -1]:
    for c in ["v", "vn", "f64", "i32"]:
        case(f"diff/{c}/{n}", "w", [OK(diff(col(c), n))])
case("diff/date", "w", [OK(diff(col("d")))], restricted=True)
for m in ["average", "min", "max", "dense", "ordinal"]:
    for c in ["v", "vn", "f64", "s"]:
        for d in (False, True):
            if m in ("min", "max", "ordinal") and c in ("vn", "s") and d:
                continue
            case(f"rank/{m}/{c}/{'desc' if d else 'asc'}", "w", [OK(rank(col(c), m, d))])
case("rank/b", "w", [OK(rank(col("b")))])
for c in ["v", "vn", "s", "f64"]:
    case(f"reverse/{c}", "w", [OK(reverse(col(c)))])
for sname in ["forward", "backward", "min", "max", "mean", "zero", "one"]:
    for c in ["vn", "f64"]:
        case(f"fills/{sname}/{c}", "w", [OK(fills(col(c), sname))])
case("fills/forward/s", "w", [OK(fills(col("s"), "forward"))])
case("fills/forward-limit/vn", "w", [OK(fills(VN, "forward", 1))])
case("seq/by-j", "w", [over(cum("sum", V), [J]), over(shift(V, 1), [J]).alias("sh")])
case("seq/cum-two-keys", "w", [over(cum("sum", V), [K, J])])
case("seq/cum-and-total", "w", [bin_("div", OK(cum("sum", V)), OK(agg("sum", V)))])
case("seq/cum-over-len", "w", [OK(bin_("div", cum("sum", V), len_))])
case("seq/rank-over-len", "w", [OK(bin_("div", rank(V, "ordinal"), len_))])
case("seq/diff-of-cum", "w", [OK(diff(cum("sum", V)))])
case("seq/cum-of-diff", "w", [OK(cum("sum", diff(V)))])
case("seq/last-of-cum", "w", [OK(agg("last", cum("sum", V)))])
case("seq/shift-minus-self", "w", [OK(bin_("sub", V, shift(V, 1)))])

# ---------------------------------------------------------------------------
# Expressions that work row by row
# ---------------------------------------------------------------------------
case("row/col", "w", [OK(V)])
case("row/col-str", "w", [OK(col("s"))])
case("row/plus-lit", "w", [OK(bin_("add", V, li(1)))])
case("row/times", "w", [OK(bin_("mul", V, Y))])
case("row/float", "w", [OK(bin_("add", X, lf(0.5)))])
case("row/is-null", "w", [OK(is_null(VN))])
case("row/is-not-null", "w", [OK(is_not_null(col("i32")))])
case("row/cast", "w", [OK(cast(V, "f64", False))])
case("row/neg", "w", [OK(neg(V))])
case("row/not", "w", [OK(not_(col("b")))])
case("row/alias", "w", [OK(alias(V, "z"))])
case("row/str-len", "w", [OK(st("len_chars", col("s")))])
case("row/when", "w", [OK(when_(bin_("gt", V, li(3)), li(1), li(0)))])
case("row/fill-null-lit", "w", [OK(fill(VN, li(0)))])
case("row/is-nan", "w", [OK(fn("is_nan", col("f64")))])
case("row/cols", "w", [OK(bin_("add", cols(["v", "y"]), li(1)))])
case("row/all-on-numbers", "w", [over(bin_("add", cols(["v", "x", "y"]), li(1)), [K])])

# ---------------------------------------------------------------------------
# An aggregation mixed with the rows
# ---------------------------------------------------------------------------
case("mix/dev-inside", "w", [OK(bin_("sub", X, agg("mean", X)))])
case("mix/dev-outside", "w", [bin_("sub", X, OK(agg("mean", X)))])
case("mix/dev-both-forms-same-name", "w", [OK(bin_("sub", V, agg("mean", V))), bin_("sub", V, OK(agg("mean", V))).alias("w")])
case("mix/share", "w", [bin_("div", Y, OK(agg("sum", Y))).alias("share")])
case("mix/share-inside", "w", [OK(bin_("div", Y, agg("sum", Y))).alias("share")])
case("mix/abs-dev", "w", [OK(fn("abs", bin_("sub", V, agg("mean", V))))])
case("mix/max-minus-self", "w", [OK(bin_("sub", agg("max", Y), Y))])
case("mix/when-agg", "w", [OK(when_(bin_("gt", V, li(3)), V, agg("sum", V)))])
case("mix/when-agg-mean", "w", [OK(when_(bin_("gt", V, agg("mean", V)), li(1), li(0)))])
case("mix/fill-null-mean", "w", [OK(fill(VN, agg("mean", VN)))])
case("mix/fill-null-agg-of-other", "w", [OK(fill(VN, agg("max", V)))])
case("mix/sum-plus-sum", "w", [OK(bin_("add", agg("sum", V), agg("sum", Y)))])
case("mix/sum-of-products", "w", [OK(agg("sum", bin_("mul", V, X)))])
case("mix/dev-sum", "w", [OK(agg("sum", bin_("sub", X, agg("mean", X))))])
case("mix/zscore", "w", [OK(bin_("div", bin_("sub", X, agg("mean", X)), std(X, 1)))])
case("mix/horizontal-agg", "w", [OK(horiz("sum", [V, agg("sum", V)]))])
case("mix/horizontal-two-aggs", "w", [OK(horiz("sum", [agg("sum", V), agg("max", V)]))])
case("mix/horizontal-rows", "w", [OK(horiz("max", [V, Y]))])
case("mix/any", "w", [OK(any_(col("b")))])
case("mix/all", "w", [OK(all_fn(col("b"), False)).alias("a")])
case("mix/any-of-cmp", "w", [OK(any_(bin_("gt", V, li(8))))])
case("mix/filter-any", "w", [OK(any_(filter_(col("b"), bin_("gt", V, li(2)))))])
case("mix/outer-alias", "w", [OK(agg("sum", V)).alias("tot"), OK(len_).alias("n")])
case("mix/cast-sum", "w", [OK(cast(agg("sum", V), "f64", False))])
case("mix/neg-sum", "w", [OK(neg(agg("sum", V)))])
case("mix/sum-plus-1", "w", [OK(bin_("add", agg("sum", V), li(1)))])
case("mix/1-plus-sum", "w", [OK(bin_("add", li(1), agg("sum", V)))])
case("mix/first-of-sorted-desc", "w", [OK(agg("first", sort_(V, True)))])

# ---------------------------------------------------------------------------
# The methods that sort, cut and filter: the result must be as long as the partition
# ---------------------------------------------------------------------------
for c in ["v", "vn", "f64", "s", "b"]:
    for d, nl in [(False, False), (True, False), (False, True), (True, True)]:
        case(f"sort/{c}/{'desc' if d else 'asc'}{'-nl' if nl else ''}", "w", [OK(sort_(col(c), d, nl))])
    case(f"arg_sort/{c}", "w", [OK(arg_sort(col(c)))])
case("arg_sort/desc-nl", "w", [OK(arg_sort(VN, True, True))])
for kk in ["x", "v"]:
    case(f"sort_by/{kk}", "w", [OK(sort_by(Y, [col(kk), ID]))])
    case(f"sort_by/{kk}-desc", "w", [OK(sort_by(Y, [col(kk), ID], [True, False]))])
case("sort_by/self-key-null", "w", [OK(sort_by(VN, [VN, ID], None, True))])
case("sort_by/sum-key", "w", [OK(sort_by(V, [agg("sum", Y)]))])
case("sort_by/sum-base", "w", [OK(sort_by(agg("sum", V), [Y]))])
case("sort_by/first", "w", [OK(agg("first", sort_by(Y, [V, ID])))])
case("sort_by/last-desc", "w", [OK(agg("last", sort_by(Y, [V, ID], True)))])
case("sort/first", "w", [OK(agg("first", sort_(V)))])
case("sort/last", "w", [OK(agg("last", sort_(V)))])
case("sort/sum-of-sorted", "w", [OK(agg("sum", sort_(V)))])
case("sort/sum-then-sort", "w", [OK(sort_(agg("sum", V)))])
case("sort/plus-sum", "w", [OK(bin_("add", sort_(V), agg("sum", V)))])
case("sort/lit", "w", [OK(sort_(li(3)))])
case("sort/key-id", "w", [over(sort_(V), [ID])])
case("sort/by-two", "w", [over(sort_(V), [K, J])])
# lengths: every partition must keep its length
case("head/ok-3", "w", [OK(head(V, 6))])
case("head/ok-100", "w", [OK(head(V, 100))])
case("head/ok-by-id-1", "w", [over(head(V, 1), [ID])])
case("head/ok-by-k2-2", "w", [over(head(V, 2), [K2])])
case("head/short-1", "w", [OK(head(V, 1))])
case("head/short-2", "w", [OK(head(V, 2))])
case("head/zero", "w", [OK(head(V, 0))])
case("head/by-k2-1", "w", [over(head(V, 1), [K2])])
case("tail/short-1", "w", [OK(tail(V, 1))])
case("tail/ok-by-k2-2", "w", [over(tail(V, 2), [K2])])
case("tail/ok-by-id-1", "w", [over(tail(V, 1), [ID])])
case("slice/short", "w", [OK(slice_(V, 1, 2))])
case("slice/ok-by-k2", "w", [over(slice_(V, 0, 5), [K2])])
case("slice/offset-by-k2", "w", [over(slice_(V, 1), [K2])])
case("unique/by-id", "w", [over(unique(V, True), [ID])])
case("unique/by-k", "w", [OK(unique(V, True))])
case("unique/by-k2-distinct", "w", [over(unique(Y, True), [K2])])
case("unique/by-k2-dups", "w", [over(unique(col("k"), True), [K2])])
case("unique/len", "w", [OK(agg("len", unique(V)))])
case("unique/n_unique-same", "w", [OK(agg("n_unique", unique(V))), OK(agg("n_unique", V)).alias("m")])
case("drop_nulls/by-k", "w", [OK(drop_nulls(VN))])
case("drop_nulls/no-nulls", "w", [OK(drop_nulls(V))])
case("drop_nulls/by-id", "w", [over(drop_nulls(VN), [ID])])
case("drop_nulls/sum", "w", [OK(agg("sum", drop_nulls(VN)))])
case("filter/by-k", "w", [OK(filter_(V, bin_("gt", V, li(2))))])
case("filter/all-true", "w", [OK(filter_(V, bin_("gt", V, li(-2))))])
case("filter/all-false", "w", [OK(filter_(V, bin_("lt", V, li(-2))))])
case("filter/by-id-true", "w", [over(filter_(V, bin_("gt", V, li(-2))), [ID])])
case("filter/by-id-mixed", "w", [over(filter_(V, bin_("gt", V, li(4))), [ID])])
case("filter/sum", "w", [OK(agg("sum", filter_(V, bin_("gt", V, li(2)))))])
case("filter/sum-empty-group", "w", [OK(agg("sum", filter_(V, bin_("gt", V, li(100)))))])
case("filter/len", "w", [OK(agg("len", filter_(V, bin_("gt", V, li(2)))))])
case("filter/mean", "w", [OK(agg("mean", filter_(X, bin_("gt", V, li(2)))))])
case("filter/agg-in-predicate", "w", [OK(agg("sum", filter_(V, bin_("gt", V, agg("mean", V)))))])
case("filter/null-predicate", "w", [OK(agg("sum", filter_(V, col("b"))))])
case("head/sum", "w", [OK(agg("sum", head(V, 2)))])
case("tail/first", "w", [OK(agg("first", tail(V, 2)))])
case("slice/last", "w", [OK(agg("last", slice_(V, 1, 2)))])
case("head/sum-plus-len", "w", [OK(bin_("add", agg("sum", head(V, 2)), len_))])

# ---------------------------------------------------------------------------
# The partition keys
# ---------------------------------------------------------------------------
for c in GCOLS:
    case(f"key/{c}", "w", [over(agg("sum", Y), [col(c)]), over(len_, [col(c)]).alias("n"),
                           over(cum("sum", Y), [col(c)]).alias("cs")])
    case(f"key/{c}/e", "we", [over(agg("sum", Y), [col(c)]), over(len_, [col(c)]).alias("n")])
for ks in [["k", "j"], ["j", "k"], ["i32", "s"], ["b", "d"], ["f64", "f32"], ["n", "i32"], ["k", "b", "dt"]]:
    case("key/multi/" + "+".join(ks), "w", [over(agg("sum", Y), [col(c) for c in ks]),
                                            over(cum("sum", Y), [col(c) for c in ks]).alias("cs")])
case("key/multi/e", "we", [over(agg("sum", Y), [K, J])])
case("key/expr/mod", "w", [over(agg("sum", Y), [bin_("mod", K, li(2))])])
case("key/expr/mod-i32", "w", [over(agg("sum", Y), [bin_("mod", col("i32"), li(2))])])
case("key/expr/k-plus", "w", [over(agg("sum", Y), [bin_("add", K, li(1))])])
case("key/expr/is-null", "w", [over(agg("sum", Y), [is_null(col("i32"))])])
case("key/expr/is-nan", "w", [over(agg("sum", Y), [fn("is_nan", col("f64"))])])
case("key/expr/cmp", "w", [over(agg("sum", Y), [bin_("gt", V, li(3))])])
case("key/expr/str-len", "w", [over(agg("sum", Y), [st("len_chars", col("s"))])])
case("key/expr/cast", "w", [over(agg("sum", Y), [cast(col("f64"), "i64", False)])])
case("key/expr/alias", "w", [over(agg("sum", Y), [alias(K, "q")])])
case("key/expr/two", "w", [over(agg("sum", Y), [bin_("mod", K, li(2)), col("b")])])
case("key/expr/sort", "w", [over(agg("sum", Y), [sort_(K)])])
case("key/expr/cum-sum", "w", [over(agg("sum", Y), [bin_("mod", cum("sum", ID), li(2))])])
case("key/expr/over", "w", [over(agg("sum", Y), [OK(cum("sum", V))])])
case("key/expr/over-sum", "w", [over(agg("sum", Y), [OK(agg("sum", V))])])
case("key/lit", "w", [over(agg("sum", Y), [li(1)])])
case("key/lit-str", "w", [over(agg("sum", Y), [ls("q")])])
case("key/lit-plus-col", "w", [over(agg("sum", Y), [li(1), K])])
case("key/agg", "w", [over(agg("sum", Y), [agg("sum", K)])])
case("key/agg-plus-col", "w", [over(agg("sum", Y), [agg("sum", K), J])])
case("key/head-one", "w", [over(agg("sum", Y), [head(K, 1)])])
case("key/head-two", "w", [over(agg("sum", Y), [head(K, 2)])])
case("key/lit/e", "we", [over(agg("sum", Y), [li(1)])])
case("key/cols", "w", [over(agg("sum", cols(["v", "y"])), [cols(["k", "j"])])])
case("key/cols-one-side", "w", [over(agg("sum", V), [cols(["k", "j"])])])
case("key/cols-mismatch", "w", [over(agg("sum", cols(["v", "y", "x"])), [cols(["k", "j"])])])
case("key/cols-empty", "w", [over(agg("sum", V), [cols([])])])
case("key/none", "w", [over(agg("sum", V), [])])
case("key/none/e", "we", [over(agg("sum", V), [])])
case("key/missing", "w", [over(agg("sum", V), [col("zz")])])
case("key/missing-and-column", "w", [over(agg("sum", col("zy")), [col("zz")])])
case("key/missing-second", "w", [over(agg("sum", V), [K, col("zz")])])
case("key/type-error", "w", [over(agg("sum", V), [bin_("add", K, col("s"))])], restricted=True)
case("key/same-twice", "w", [over(agg("sum", Y), [K, K])])
case("key/f64-focus", "w", [over(agg("sum", Y), [col("f64")]), over(agg("first", col("f64")), [col("f64")]).alias("fk")])
case("key/f32-focus", "w", [over(agg("len", Y), [col("f32")]), over(agg("first", col("f32")), [col("f32")]).alias("fk")])

# ---------------------------------------------------------------------------
# Output names and several windows
# ---------------------------------------------------------------------------
case("name/two-same", "w", [OK(agg("sum", V)), over(cum("sum", V), [J])])
case("name/two-alias", "w", [OK(agg("sum", V)).alias("a"), over(cum("sum", V), [J]).alias("b")])
case("name/with-columns-two", "w", [OK(agg("sum", V)).alias("a"), OK(cum("sum", V)).alias("b")], op="with_columns")
case("name/with-columns-dup", "w", [OK(agg("sum", V)).alias("a"), OK(cum("sum", V)).alias("a")], op="with_columns",
     variant="DuplicateColumn")
case("name/select-lit", "w", [alias(lit("i32", 1), "one"), OK(agg("sum", V)).alias("t")])
case("name/alias-in-key", "w", [over(alias(agg("sum", V), "inner"), [K])])
case("name/alias-over-alias", "w", [over(alias(agg("sum", V), "inner"), [K]).alias("outer")])
case("name/cols-both", "w", [OK(cum("sum", cols(["v", "y"])))])
case("name/all-numbers", "w", [over(cum("sum", cols(["v", "x", "y"])), [K])])
case("name/key-column-too", "w", [K, OK(agg("sum", V)).alias("t")])
case("name/same-as-key", "w", [OK(agg("sum", V)).alias("k")], op="with_columns")

# ---------------------------------------------------------------------------
# Windows inside windows
# ---------------------------------------------------------------------------
case("nest/sum-over-k-over-j", "w", [over(OK(agg("sum", V)), [J])])
case("nest/cum-over-k-over-j", "w", [over(OK(cum("sum", V)), [J])])
case("nest/same-as-two-keys", "w", [over(agg("sum", V), [K, J]).alias("two")])
case("nest/sum-of-window", "w", [OK(agg("sum", OK(agg("sum", V))))])
case("nest/inner-different-key", "w", [OK(bin_("sub", V, over(agg("mean", V), [J])))])
case("nest/sum-plus-window", "w", [bin_("add", OK(agg("sum", V)), over(agg("max", V), [J]))])

# ---------------------------------------------------------------------------
# DataFrame::filter and DataFrame::sort with a window
# ---------------------------------------------------------------------------
case("frame/filter/above-mean", "w", [bin_("gt", V, OK(agg("mean", V)))], op="filter")
case("frame/filter/is-max", "w", [bin_("eq", V, OK(agg("max", V)))], op="filter")
case("frame/filter/sum-gt", "w", [bin_("gt", OK(agg("sum", V)), li(20))], op="filter")
case("frame/filter/cum", "w", [bin_("le", OK(cum("sum", V)), li(10))], op="filter")
case("frame/filter/rank-first", "w", [bin_("eq", OK(rank(V, "ordinal")), li(1))], op="filter")
case("frame/filter/len", "w", [bin_("gt", OK(len_), li(2))], op="filter")
case("frame/filter/sorted-is-itself", "w", [bin_("eq", V, OK(sort_(V)))], op="filter")
case("frame/filter/short", "w", [bin_("gt", V, OK(head(V, 2)))], op="filter")
case("frame/filter/e", "we", [bin_("gt", V, OK(agg("mean", V)))], op="filter")
case("frame/sort/sum", "w", [OK(agg("sum", V)), ID], op="sort")
case("frame/sort/cum", "w", [OK(cum("sum", V)), ID], op="sort")
case("frame/sort/rank", "w", [over(rank(V, "min"), [J]), ID], op="sort")
case("frame/sort/len-then-id", "w", [OK(len_), ID], op="sort")
case("frame/sort/e", "we", [OK(agg("sum", V)), ID], op="sort")

# ---------------------------------------------------------------------------
# Frames without rows, with one row and without columns
# ---------------------------------------------------------------------------
for c in ["i32", "f64", "s", "n"]:
    case(f"e/sum/{c}", "we", [OK(agg("sum", col(c))), OK(agg("mean", col(c))).alias("m"), OK(len_).alias("n")],
         restricted=stricter("sum", c))
case("e/cum", "we", [OK(cum("sum", V)), OK(shift(col("s"), 1)).alias("sh"), OK(rank(col("f64"))).alias("rk")])
case("e/sort", "we", [OK(sort_(V)), OK(arg_sort(col("s"))).alias("a")])
case("e/head", "we", [OK(head(V, 2))])
case("e/unique", "we", [OK(unique(V))])
case("e/lit", "we", [OK(li(1)), OK(lf(2.5)).alias("f"), OK(ls("q")).alias("s")])
case("e/row", "we", [OK(bin_("add", V, li(1))), OK(col("s"))])
case("e/with-columns", "we", [OK(agg("sum", V)).alias("t")], op="with_columns")
case("e/key-lit", "we", [over(cum("sum", V), [li(1)])])
case("e/missing", "we", [OK(agg("sum", col("zz")))])
case("one/sum", "w1", [OK(agg("sum", V)), OK(cum("sum", V)).alias("c"), OK(len_).alias("n")])
case("one/shift", "w1", [OK(shift(V, 1)), OK(rank(V)).alias("r")])
case("one/head", "w1", [OK(head(V, 1)), OK(sort_(V)).alias("s")])
case("one/head-too-long", "w1", [OK(head(V, 5))])
case("one/filter", "w1", [OK(filter_(V, bin_("gt", V, li(100))))])
case("one/unique", "w1", [OK(unique(V))])
case("z0/sum", "z0", [over(agg("sum", V), [K])])
case("z0/lit", "z0", [over(li(1), [K])])
case("z0/none", "z0", [over(li(1), [])])
case("z0/keys-lit", "z0", [over(li(1), [li(1)])])

# ---------------------------------------------------------------------------
# The order the additions of a float sum are made in
# ---------------------------------------------------------------------------
BK = col("k")
for op in ["sum", "mean", "min", "max", "median", "first", "last"]:
    for c in ["x", "xf", "v"]:
        case(f"big/{op}/{c}", "wbig", [over(agg(op, col(c)), [BK])])
for op, d in [("std", 1), ("var", 1), ("var", 0)]:
    for c in ["x", "xf"]:
        case(f"big/{op}{d}/{c}", "wbig", [over((std if op == "std" else var)(col(c), d), [BK])])
case("big/dev-sum", "wbig", [over(agg("sum", bin_("sub", col("x"), agg("mean", col("x")))), [BK])])
case("big/dev-inside", "wbig", [over(bin_("sub", col("x"), agg("mean", col("x"))), [BK])])
case("big/cum", "wbig", [over(cum("sum", col("x")), [BK])])
case("big/sum-by-expr", "wbig", [over(agg("sum", col("x")), [bin_("mod", col("v"), li(3))])])

# ---------------------------------------------------------------------------
# One partition of all the rows: polars words the length error like the one of
# partitions of one row
# ---------------------------------------------------------------------------
case("part/all-rows-head", "w", [over(head(V, 3), [li(1)])])
case("part/agg-key-head", "w", [over(head(V, 3), [agg("sum", K)])])
case("part/first-key-head", "w", [over(head(V, 3), [agg("first", K)])])
case("part/all-rows-filter", "w", [over(filter_(V, bin_("gt", V, li(100))), [li(1)])])
case("part/all-rows-ok", "w", [over(cum("sum", V), [li(1)]), over(agg("sum", V), [li(1)]).alias("t")])

# ---------------------------------------------------------------------------
# Division of an aggregated value inside a window: polars keeps an aggregate a
# scalar and divides a float column by a scalar by multiplying with its
# reciprocal (`/`, `//` and `%`); an aggregate divided by an aggregate is a plain
# quotient
# ---------------------------------------------------------------------------
FDV = [0.1, 0.7, 0.3, 0.6, 1.1, 0.7, 0.3, 2.3, 0.3, 0.9, 0.6, 2.1]
TABLES["dv"] = pl.DataFrame([
    series_from_spec("k", "i64", [1] * 8 + [2] * 4),
    series_from_spec("f", "f64", FDV),
    series_from_spec("f3", "f32", FDV),
    series_from_spec("n", "i64", [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8]),
])
F, F3, NN = col("f"), col("f3"), col("n")
case("dv/quotient-times-col", "dv", [over(bin_("mul", bin_("div", agg("max", F), agg("sum", F)), F), [K])])
case("dv/quotient-over-col", "dv", [over(bin_("div", bin_("div", agg("last", F), agg("sum", F)), F), [K])])
case("dv/sum-per-len-over-col", "dv", [over(bin_("div", bin_("div", agg("sum", F), len_), F), [K])])
case("dv/sum-per-len-times-col", "dv", [over(bin_("mul", bin_("div", agg("sum", F), len_), F), [K])])
for op in ["div", "floordiv", "mod"]:
    for c in ["f", "f3", "n"]:
        C = col(c)
        case(f"dv/{op}/{c}-by-first", "dv", [over(bin_(op, C, agg("first", C)), [K])])
        case(f"dv/{op}/{c}-by-sum", "dv", [over(bin_(op, C, agg("sum", C)), [K])])
        case(f"dv/{op}/{c}-by-mixed", "dv", [over(bin_(op, C, bin_("add", C, agg("first", C))), [K])])
for i, (e, _) in enumerate(W["gen_div_exprs"](20261126, 12, ["f", "f3"], wrap=False)):
    case(f"dv/rand/{i}", "dv", [over(e, [K])])
for i, (e, _) in enumerate(W["gen_div_exprs"](20261127, 4, ["n", "f"], ["n", "f", "f3"], wrap=False)):
    case(f"dv/rand-mixed/{i}", "dv", [over(e, [K])])

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------


def mb_cases_file():
    lines = ["// 由 docs/golden/scripts/window.py 生成，勿手改", ""]
    chunk = 60
    parts = [MB[i:i + chunk] for i in range(0, len(MB), chunk)]
    for pi, part in enumerate(parts):
        lines += ["///|", f"fn golden_window_cases_{pi}(m : Map[String, Array[@pl.Expr]]) -> Unit {{"]
        for cid, exprs in part:
            lines.append(f"  m[{mb_str(cid)}] = [{', '.join(exprs)}]")
        lines += ["}", ""]
    lines += ["///|", "/// Every case id with the expressions it builds.",
              "fn golden_window_cases() -> Map[String, Array[@pl.Expr]] {",
              "  let m : Map[String, Array[@pl.Expr]] = Map([])"]
    for pi in range(len(parts)):
        lines.append(f"  golden_window_cases_{pi}(m)")
    lines += ["  m", "}", ""]
    path = os.path.join(_repo_root(), "src", "pl", "window_cases_test.mbt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


used = {c.get("table", "t") for c in CASES}
doc = {
    "tables": {name: encode_frame(df) for name, df in TABLES.items() if name in used},
    "cases": CASES,
}
emit("window", doc, compact=True)
# MoonBit source may not contain a raw U+2028/U+2029 (not even in a `#|` string)
path = os.path.join(_repo_root(), "src", "pl", "golden_window_data_test.mbt")
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
