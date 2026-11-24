"""Generates the golden data of the expression methods that sort, cut, filter and
combine (`filter`, `sort_by`, `sort`, `unique`, `head`, `tail`, `slice`,
`drop_nulls`, `any`, `all`, `sum_horizontal` ...) and of `over` inside
`DataFrame::group_by(...).agg(...)` (docs/golden/group_by_ext.json,
src/pl/golden_group_by_ext_data_test.mbt) and the MoonBit expressions of every
case (src/pl/group_by_ext_cases_test.mbt).

Run from the repository root (on a machine with polars 2.1.0):
    ulimit -v 16000000; POLARS_MAX_THREADS=4 \
        /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/group_by_ext.py

Built on `shape_base.py`. The cases, their fields and the meaning of `result`,
`error`, `restricted`, `list`, `known_diff`, `key_str`, `str` are those of
`group_by.py` (every case is `table.group_by([keys], maintain_order=True)
.agg([aggs])`); see docs/golden/known-diffs/group_by.md and group_by_ext.md.

The table `g` (12 rows) is the table `w` of `window.py`: keys `k` (a null group
and a group of one row), `j`, `k2` and `id`, one column of every type with
nulls, NaN, `-0.0`, infinities, and `x`, `y`, `v`, `vn`. `ge` has its schema and
no rows.
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
col, cols, all_ = W["col"], W["cols"], W["all_"]
li, lf, ls, lb, lit = W["li"], W["lf"], W["ls"], W["lb"], W["lit"]
bin_, neg, not_, alias, cast = W["bin_"], W["neg"], W["not_"], W["alias"], W["cast"]
is_null, is_not_null = W["is_null"], W["is_not_null"]
agg, fill, fn = W["agg"], W["fill"], W["fn"]
when_ = W["when_"]
std, var, quant = A["std"], A["var"], A["quant"]
shift, cum, rank = W["shift"], W["cum"], W["rank"]
st = W["st"]
mb_str = W["mb_str"]
nan, inf = W["nan"], W["inf"]
I64_MAX, I64_MIN = W["I64_MAX"], W["I64_MIN"]
VARIANTS = W["VARIANTS"]
schema_text = W["_ns"]["schema_text"]
strengthen = W["strengthen"]
to_pl, to_py, to_mb = W["to_pl"], W["to_py"], W["to_mb"]
sort_, arg_sort, sort_by, head, tail, slice_ = (
    W["sort_"], W["arg_sort"], W["sort_by"], W["head"], W["tail"], W["slice_"])
unique, drop_nulls, filter_, any_, all_fn = (
    W["unique"], W["drop_nulls"], W["filter_"], W["any_"], W["all_fn"])
horiz = W["horiz"]
IDS = set()

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
GDF = pl.DataFrame([series_from_spec(c, GT[c], v) for c, v in G.items()])
TABLES = {"g": GDF, "ge": GDF.clear()}

# -- running --------------------------------------------------------------------------
CASES = []
MB = []
FLAKY_RUNS = 6


def run_gb(df, keys, aggs):
    """`(frame, None)` or `(None, (polars class, variant, first message line))`."""
    try:
        g = df.group_by([to_pl(k) for k in keys], maintain_order=True)
        return g.agg([to_pl(a) for a in aggs]), None
    except BaseException as e:  # noqa: BLE001  (polars panics are BaseExceptions)
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        cls = type(e).__name__
        return None, (cls, VARIANTS.get(cls, cls), str(e).split("\n")[0])


def py_text(table, keys, aggs):
    ks = ", ".join(to_py(k) for k in keys)
    return f"{table}.group_by([{ks}], maintain_order=True).agg([" + ", ".join(to_py(a) for a in aggs) + "])"


def case(cid, table, keys, aggs, restricted=False):
    assert cid not in IDS, cid
    keys, aggs = list(keys), list(aggs)
    df = TABLES[table]
    res, err = run_gb(df, keys, aggs)
    rec = {
        "id": cid,
        "polars": py_text(table, keys, aggs),
        "key_str": [str(to_pl(k)) for k in keys],
        "str": [str(to_pl(a)) for a in aggs],
        "table": table,
    }
    if restricted:
        rec["restricted"] = True
        if res is not None:
            rec["polars_schema"] = schema_text(res)
            if any(isinstance(s.dtype, pl.List) for s in res.get_columns()):
                rec["list"] = True
        else:
            rec["polars_error"] = err[2]
    elif err is not None:
        cls, var_, msg = err
        # polars runs the expressions on several threads: with two different
        # failures the one it reports can change from run to run
        for _ in range(FLAKY_RUNS):
            _, again = run_gb(df, keys, aggs)
            if again is None or again[2] != msg:
                print("FLAKY (skipped)", cid, msg, "|", None if again is None else again[2])
                return
        if cls == "PanicException":
            print("PANIC (skipped)", cid, msg)
            return
        rec["error"] = var_
        rec["message"] = msg
    else:
        ours, oerr = run_gb(df, [strengthen(n) for n in keys], [strengthen(n) for n in aggs])
        if oerr is None and schema_text(ours) != schema_text(res):
            rec["known_diff"] = "dyn-literal-default"
            rec["polars_schema"] = schema_text(res)
            res = ours
        try:
            rec["result"] = encode_frame(res)
        except (ValueError, pl.exceptions.PolarsError) as e:
            print("SKIP", cid, e)
            return
    IDS.add(cid)
    CASES.append(rec)
    MB.append((cid, ([to_mb(k) for k in keys], [to_mb(a) for a in aggs])))


K, J, ID, K2 = col("k"), col("j"), col("id"), col("k2")
V, VN, X, Y = col("v"), col("vn"), col("x"), col("y")


def listy(cid, table, keys, aggs):
    """polars gives a list column: restricted."""
    case(cid, table, keys, aggs, restricted=True)


def stricter(op, c):
    return (op == "sum" and c in ("d", "dt")) or (op == "quantile" and c in ("s", "b", "n"))


# ---------------------------------------------------------------------------
# filter
# ---------------------------------------------------------------------------
Y40 = bin_("gt", Y, li(40))
for op in ["sum", "mean", "min", "max", "first", "last", "count", "len", "n_unique"]:
    for c in (["i32", "f64", "s", "b", "d"] if op in ("sum", "mean") else ["i32", "i64", "f64", "s", "b", "d", "dt", "n"]):
        case(f"filter/{op}/{c}", "g", [K], [agg(op, filter_(col(c), Y40))], restricted=stricter(op, c))
for op in ["sum", "len", "first", "count"]:
    case(f"filter/{op}/null-pred", "g", [K], [agg(op, filter_(V, col("b")))])
    case(f"filter/{op}/all-false", "g", [K], [agg(op, filter_(V, bin_("lt", V, li(-5))))])
    case(f"filter/{op}/agg-pred", "g", [K], [agg(op, filter_(V, bin_("gt", V, agg("mean", V))))])
    case(f"filter/{op}/by-j", "g", [J], [agg(op, filter_(V, bin_("gt", V, li(2))))])
    case(f"filter/{op}/e", "ge", [K], [agg(op, filter_(V, bin_("gt", V, li(2))))])
case("filter/sum-two-keys", "g", [K, J], [agg("sum", filter_(V, bin_("gt", V, li(2)))), len_])
case("filter/spec-example", "g", [K], [agg("sum", filter_(V, bin_("gt", Y, li(0))))])
case("filter/ratio", "g", [K], [bin_("div", agg("sum", filter_(V, bin_("gt", V, li(2)))), len_).alias("r")])
case("filter/two-aggs", "g", [K], [agg("sum", filter_(V, bin_("gt", V, li(2)))).alias("a"),
                                   agg("sum", filter_(V, bin_("le", V, li(2)))).alias("b")])
case("filter/of-sorted", "g", [K], [agg("first", filter_(sort_(V), bin_("gt", V, li(2))))])
case("filter/when", "g", [K], [when_(bin_("gt", agg("sum", filter_(V, bin_("gt", V, li(2)))), li(10)), li(1), li(0)).alias("w")])
case("filter/no-key", "g", [], [agg("sum", filter_(V, bin_("gt", V, li(2)))), len_])
case("filter/no-key/e", "ge", [], [agg("sum", filter_(V, bin_("gt", V, li(2)))), len_])
case("filter/bad-pred-type", "g", [K], [agg("sum", filter_(V, V))])
case("filter/missing", "g", [K], [agg("sum", filter_(V, bin_("gt", col("zz"), li(2))))])
listy("filter/list", "g", [K], [filter_(V, bin_("gt", V, li(2)))])
listy("filter/list-sum-of-scalar", "g", [K], [filter_(agg("sum", V), lb(True))])
listy("filter/list-lit", "g", [K], [filter_(li(1), lb(True))])

# ---------------------------------------------------------------------------
# sort_by and sort
# ---------------------------------------------------------------------------
for op in ["first", "last"]:
    for c in ["i32", "i64", "f64", "s", "b", "d", "dt", "n"]:
        case(f"sort_by/{op}/{c}", "g", [K], [agg(op, sort_by(col(c), [Y]))])
        case(f"sort_by/{op}-desc/{c}", "g", [K], [agg(op, sort_by(col(c), [Y], True))])
    case(f"sort_by/{op}/two-keys", "g", [K], [agg(op, sort_by(Y, [col("i32"), ID], [True, False]))])
    case(f"sort_by/{op}/null-key", "g", [K], [agg(op, sort_by(Y, [col("i32"), ID], None, True))])
    case(f"sort_by/{op}/null-key-first", "g", [K], [agg(op, sort_by(Y, [col("i32"), ID]))])
    case(f"sort_by/{op}/float-key", "g", [K], [agg(op, sort_by(Y, [col("f64"), ID]))])
    case(f"sort_by/{op}/str-key", "g", [K], [agg(op, sort_by(Y, [col("s"), ID], [True, False]))])
    case(f"sort_by/{op}/e", "ge", [K], [agg(op, sort_by(Y, [X]))])
    case(f"sort_by/{op}/by-j", "g", [J], [agg(op, sort_by(Y, [V, ID]))])
case("sort_by/sum", "g", [K], [agg("sum", sort_by(Y, [V, ID]))])
case("sort_by/cum-last", "g", [K], [agg("last", cum("sum", sort_by(Y, [V, ID])))])
case("sort_by/first-minus-last", "g", [K], [bin_("sub", agg("first", sort_by(Y, [V, ID])), agg("last", sort_by(Y, [V, ID]))).alias("d")])
case("sort_by/expr-key", "g", [K], [agg("first", sort_by(Y, [bin_("mul", V, li(-1)), ID]))])
case("sort_by/agg-key", "g", [K], [agg("first", sort_by(Y, [agg("sum", V)]))])
case("sort_by/no-key", "g", [], [agg("first", sort_by(Y, [V, ID])), agg("last", sort_by(Y, [V, ID])).alias("l")])
case("sort_by/scalar-both", "g", [K], [sort_by(agg("sum", Y), [agg("sum", V)]).alias("s")])
case("sort_by/scalar-both-lits", "g", [K], [sort_by(agg("max", Y), [agg("min", V), agg("sum", X)]).alias("s")])
case("sort_by/filtered-base-unfiltered-key", "g", [K], [agg("first", sort_by(filter_(V, bin_("gt", V, li(2))), [V]))])
case("sort_by/filtered-base-unfiltered-key-sum", "g", [K], [agg("sum", sort_by(filter_(V, bin_("gt", V, li(2))), [Y]))])
listy("sort_by/list", "g", [K], [sort_by(Y, [V, ID])])
listy("sort_by/list-scalar-key", "g", [K], [sort_by(Y, [agg("sum", V)])])
for c in ["i32", "i64", "f32", "f64", "s", "b", "d", "dt", "n"]:
    case(f"sort/first/{c}", "g", [K], [agg("first", sort_(col(c)))])
    case(f"sort/last/{c}", "g", [K], [agg("last", sort_(col(c)))])
for d, nl in [(True, False), (False, True), (True, True)]:
    case(f"sort/first/f64/{d}{nl}", "g", [K], [agg("first", sort_(col("f64"), d, nl))])
    case(f"sort/last/i32/{d}{nl}", "g", [K], [agg("last", sort_(col("i32"), d, nl))])
case("sort/sum", "g", [K], [agg("sum", sort_(V))])
case("sort/mean-f64", "g", [K], [agg("mean", sort_(col("f64")))])
case("sort/e", "ge", [K], [agg("first", sort_(V)), agg("last", sort_(col("s"))).alias("l")])
case("sort/no-key", "g", [], [agg("first", sort_(V)), agg("last", sort_(V)).alias("l")])
case("sort/of-sum", "g", [K], [sort_(agg("sum", V)).alias("s")])
case("sort/of-sum-plus", "g", [K], [bin_("add", sort_(agg("sum", V)), li(1)).alias("s")])
case("sort/of-lit", "g", [K], [sort_(li(1)).alias("s")])
case("sort/of-len", "g", [K], [sort_(len_).alias("n")])
case("arg_sort/of-sum", "g", [K], [arg_sort(agg("sum", V)).alias("a")])
case("arg_sort/first", "g", [K], [agg("first", arg_sort(V))])
case("arg_sort/last-desc", "g", [K], [agg("last", arg_sort(VN, True, True))])
case("arg_sort/sum", "g", [K], [agg("sum", arg_sort(V))])
listy("sort/list", "g", [K], [sort_(V)])
listy("sort/list-str", "g", [K], [sort_(col("s"))])
listy("sort/list-plus", "g", [K], [bin_("add", sort_(V), li(1))])
listy("arg_sort/list", "g", [K], [arg_sort(V)])

# ---------------------------------------------------------------------------
# unique, drop_nulls
# ---------------------------------------------------------------------------
for c in ["i32", "i64", "f64", "s", "b", "d", "dt", "n"]:
    case(f"unique/len/{c}", "g", [K], [agg("len", unique(col(c)))])
    case(f"unique/count/{c}", "g", [K], [agg("count", unique(col(c)))])
    case(f"unique/n_unique/{c}", "g", [K], [agg("n_unique", unique(col(c)))])
    case(f"unique/first-stable/{c}", "g", [K], [agg("first", unique(col(c), True))])
    case(f"unique/last-stable/{c}", "g", [K], [agg("last", unique(col(c), True))])
case("unique/sum", "g", [K], [agg("sum", unique(V))])
case("unique/sum-stable-f64", "g", [K], [agg("sum", unique(col("f64"), True))])
case("unique/max", "g", [K], [agg("max", unique(V))])
case("unique/len-by-j", "g", [J], [agg("len", unique(V))])
case("unique/len-minus-n_unique", "g", [K], [bin_("sub", agg("len", unique(V)), agg("n_unique", V)).alias("d")])
case("unique/e", "ge", [K], [agg("len", unique(V))])
case("unique/no-key", "g", [], [agg("len", unique(V))])
case("unique/spec-example", "g", [K], [agg("len", unique(V)), agg("sum", V).alias("s")])
for c in ["vn", "i32", "f64", "s", "n"]:
    case(f"drop_nulls/len/{c}", "g", [K], [agg("len", drop_nulls(col(c)))])
    case(f"drop_nulls/first/{c}", "g", [K], [agg("first", drop_nulls(col(c)))])
    case(f"drop_nulls/last/{c}", "g", [K], [agg("last", drop_nulls(col(c)))])
case("drop_nulls/sum", "g", [K], [agg("sum", drop_nulls(VN))])
case("drop_nulls/mean", "g", [K], [agg("mean", drop_nulls(VN))])
case("drop_nulls/count-vs-len", "g", [K], [agg("count", VN).alias("c"), agg("len", drop_nulls(VN)).alias("l")])
case("drop_nulls/e", "ge", [K], [agg("sum", drop_nulls(VN))])
listy("unique/list", "g", [K], [unique(V)])
listy("unique/list-stable", "g", [K], [unique(V, True)])
listy("unique/list-of-sum", "g", [K], [unique(agg("sum", V))])
listy("drop_nulls/list", "g", [K], [drop_nulls(VN)])
listy("drop_nulls/list-of-sum", "g", [K], [drop_nulls(agg("sum", V))])

# ---------------------------------------------------------------------------
# head, tail, slice
# ---------------------------------------------------------------------------
for n in [0, 1, 2, 100]:
    for op in ["sum", "len", "first", "last"]:
        case(f"head/{op}/{n}", "g", [K], [agg(op, head(V, n))])
for n in [1, 2, 100]:
    for op in ["sum", "len", "first", "last"]:
        case(f"tail/{op}/{n}", "g", [K], [agg(op, tail(V, n))])
for off, ln in [(1, 2), (-2, None), (-2, 1), (5, 3), (0, 0)]:
    for op in ["sum", "len", "first"]:
        case(f"slice/{op}/{off}/{ln}", "g", [K], [agg(op, slice_(V, off, ln))])
for c in ["i32", "f64", "s", "b", "d", "n"]:
    case(f"head/first/type/{c}", "g", [K], [agg("first", head(col(c), 2))])
    case(f"tail/last/type/{c}", "g", [K], [agg("last", tail(col(c), 2))])
case("head/sum-f64", "g", [K], [agg("sum", head(col("f64"), 2))])
case("head/mean", "g", [K], [agg("mean", head(X, 2))])
case("head/sum-of-sorted", "g", [K], [agg("sum", head(sort_(V, True), 2))])
case("head/sum-top-2-by", "g", [K], [agg("sum", head(sort_by(Y, [V, ID], True), 2))])
case("head/e", "ge", [K], [agg("sum", head(V, 2))])
case("head/no-key", "g", [], [agg("sum", head(V, 2)), agg("len", tail(V, 3)).alias("l")])
case("head/by-j", "g", [J], [agg("sum", head(V, 2))])
case("head/with-len", "g", [K], [bin_("add", agg("sum", head(V, 2)), len_)])
case("head/default", "g", [K], [agg("len", head(V))])
case("head/negative", "g", [K], [agg("len", head(V, -1))])
case("head/lit", "g", [K], [agg("sum", head(li(1), 3))])
listy("head/list", "g", [K], [head(V, 2)])
listy("head/list-1", "g", [K], [head(V, 1)])
listy("tail/list", "g", [K], [tail(V, 2)])
listy("slice/list", "g", [K], [slice_(V, 1, 2)])
listy("head/list-of-sum", "g", [K], [head(agg("sum", V), 1)])
listy("head/list-plus", "g", [K], [bin_("add", head(V, 2), li(1))])
listy("head/list-two", "g", [K], [head(V, 2), agg("sum", V).alias("s")])

# ---------------------------------------------------------------------------
# any, all
# ---------------------------------------------------------------------------
for ig in (True, False):
    sfx = "" if ig else "-keep"
    for c in ["b", "i32", "f64", "vn", "n"]:
        case(f"any/{c}{sfx}", "g", [K], [any_(col(c), ig)])
        case(f"all/{c}{sfx}", "g", [K], [all_fn(col(c), ig)])
    case(f"any/cmp{sfx}", "g", [K], [any_(bin_("gt", V, li(8)), ig)])
    case(f"all/cmp{sfx}", "g", [K], [all_fn(bin_("gt", V, li(0)), ig)])
    case(f"any/e{sfx}", "ge", [K], [any_(col("b"), ig), all_fn(col("b"), ig).alias("a")])
    case(f"any/no-key{sfx}", "g", [], [any_(col("b"), ig), all_fn(col("b"), ig).alias("a")])
case("any/of-filter", "g", [K], [any_(filter_(col("b"), bin_("gt", V, li(2))))])
case("all/of-filter-empty", "g", [K], [all_fn(filter_(col("b"), bin_("gt", V, li(100))))])
case("any/of-filter-empty", "g", [K], [any_(filter_(col("b"), bin_("gt", V, li(100))))])
case("any/of-sort", "g", [K], [any_(sort_(col("b")))])
case("any/of-head", "g", [K], [any_(head(col("b"), 1))])
case("any/of-scalar", "g", [K], [any_(agg("sum", V)).alias("a")])
case("any/of-lit", "g", [K], [any_(lb(True)).alias("a")])
case("all/of-lit-false", "g", [K], [all_fn(lb(False)).alias("a")])
case("any/in-when", "g", [K], [when_(any_(bin_("gt", V, li(8))), li(1), li(0)).alias("w")])
case("any/and-all", "g", [K], [any_(col("b")).alias("a"), all_fn(col("b")).alias("l"), agg("sum", V)])
case("any/not", "g", [K], [alias(not_(any_(col("b"))), "n")])
case("any/of-str", "g", [K], [any_(col("s"))])
case("any/of-date", "g", [K], [any_(col("d"))])
case("any/by-j", "g", [J], [any_(col("b")), all_fn(bin_("gt", V, li(0))).alias("a")])
case("any/by-two", "g", [K, J], [any_(col("b")), all_fn(col("b")).alias("a")])

# ---------------------------------------------------------------------------
# sum_horizontal, min_horizontal, max_horizontal
# ---------------------------------------------------------------------------
for op in ["sum", "min", "max"]:
    case(f"horiz/{op}/scalars", "g", [K], [horiz(op, [agg("sum", V), agg("max", Y)])])
    case(f"horiz/{op}/scalar-lit", "g", [K], [horiz(op, [agg("sum", V), li(1)])])
    case(f"horiz/{op}/scalar-lit-strong", "g", [K], [horiz(op, [agg("sum", V), lit("i64", 5)])])
    case(f"horiz/{op}/three-scalars", "g", [K], [horiz(op, [agg("sum", V), agg("max", Y), agg("len", V)])])
    case(f"horiz/{op}/floats", "g", [K], [horiz(op, [agg("mean", V), agg("max", X)])])
    case(f"horiz/{op}/len", "g", [K], [horiz(op, [len_, agg("sum", V)])])
    case(f"horiz/{op}/sum-of-rows", "g", [K], [agg("sum", horiz(op, [V, Y]))])
    case(f"horiz/{op}/first-of-rows", "g", [K], [agg("first", horiz(op, [V, X]))])
    case(f"horiz/{op}/last-of-rows-nulls", "g", [K], [agg("last", horiz(op, [VN, V]))])
    case(f"horiz/{op}/rows-and-scalar-inside", "g", [K], [agg("sum", horiz(op, [V, agg("mean", V)]))])
    case(f"horiz/{op}/e", "ge", [K], [horiz(op, [agg("sum", V), agg("max", Y)])])
    case(f"horiz/{op}/no-key", "g", [], [horiz(op, [agg("sum", V), agg("max", Y)])])
    case(f"horiz/{op}/plus-one", "g", [K], [bin_("add", horiz(op, [agg("sum", V), agg("max", Y)]), li(1)).alias("h")])
    listy(f"horiz/{op}/list-rows", "g", [K], [horiz(op, [V, Y])])
    listy(f"horiz/{op}/list-mixed", "g", [K], [horiz(op, [V, agg("sum", Y)])])
case("horiz/sum/keep-nulls", "g", [K], [horiz("sum", [agg("first", VN), agg("last", VN)], False)])
case("horiz/sum/ignore-nulls", "g", [K], [horiz("sum", [agg("first", VN), agg("last", VN)], True)])
case("horiz/sum/null-aggregate", "g", [K], [horiz("sum", [agg("first", col("i32")), agg("sum", V)], False)])
case("horiz/sum/strings-min", "g", [K], [horiz("min", [agg("first", col("s")), agg("last", col("s"))])])
case("horiz/sum/bool-max", "g", [K], [horiz("max", [agg("first", col("b")), agg("last", col("b"))])])
case("horiz/sum/types", "g", [K], [horiz("sum", [agg("sum", col("i32")), agg("sum", col("f32"))])])

# ---------------------------------------------------------------------------
# over inside an aggregation: the window is the group
# ---------------------------------------------------------------------------
for op in ["first", "last", "sum", "max", "len"]:
    case(f"over/sum-{op}", "g", [K], [agg(op, over(agg("sum", V), [J]))])
    case(f"over/cum-{op}", "g", [K], [agg(op, over(cum("sum", V), [J]))])
    case(f"over/len-{op}", "g", [K], [agg(op, over(len_, [J]))])
case("over/same-key", "g", [K], [agg("sum", over(agg("sum", V), [K]))])
case("over/key-id", "g", [K], [agg("sum", over(cum("sum", V), [ID]))])
case("over/two-keys", "g", [K], [agg("sum", over(cum("sum", V), [J, col("b")]))])
case("over/dev-inside", "g", [K], [agg("sum", bin_("sub", V, over(agg("mean", V), [J])))])
case("over/dev-sum-of-window", "g", [K], [agg("max", over(bin_("sub", V, agg("mean", V)), [J]))])
case("over/shift-last", "g", [K], [agg("last", over(shift(V, 1), [J]))])
case("over/rank-max", "g", [K], [agg("max", over(rank(V, "dense"), [J]))])
case("over/mixed", "g", [K], [agg("sum", over(cum("sum", V), [J])).alias("a"), agg("sum", V).alias("b"), len_])
case("over/plus-agg", "g", [K], [bin_("add", agg("first", over(agg("sum", V), [J])), agg("sum", V)).alias("p")])
case("over/sort-first", "g", [K], [agg("first", over(sort_(V), [J]))])
case("over/e", "ge", [K], [agg("first", over(agg("sum", V), [J]))])
case("over/no-key", "g", [], [agg("first", over(agg("sum", V), [J])), agg("sum", over(cum("sum", V), [K])).alias("c")])
case("over/lit", "g", [K], [agg("first", over(li(1), [J]))])
case("over/any", "g", [K], [agg("sum", over(any_(col("b")), [J]))])
case("over/inner-key-expr", "g", [K], [agg("sum", over(agg("sum", V), [bin_("mod", V, li(2))]))])
case("over/missing-key", "g", [K], [agg("first", over(agg("sum", V), [col("zz")]))])
case("over/head-too-short", "g", [K], [agg("first", over(head(V, 1), [J]))])
case("over/head-fits-by-id", "g", [K], [agg("sum", over(head(V, 1), [ID]))])
listy("over/list", "g", [K], [over(agg("sum", V), [J])])
listy("over/list-by-key", "g", [K], [over(agg("sum", V), [K])])
listy("over/list-plus", "g", [K], [bin_("add", over(agg("sum", V), [J]), li(1))])
listy("over/list-cum", "g", [K], [over(cum("sum", V), [J])])

# ---------------------------------------------------------------------------
# Combinations
# ---------------------------------------------------------------------------
case("combo/everything", "g", [K], [
    agg("sum", filter_(V, bin_("gt", V, li(2)))).alias("fs"),
    agg("first", sort_by(Y, [V, ID])).alias("sb"),
    agg("last", sort_(V)).alias("mx"),
    agg("len", unique(V)).alias("nu"),
    agg("sum", head(V, 2)).alias("h2"),
    any_(col("b")).alias("any"),
    horiz("sum", [agg("sum", V), agg("max", Y)]).alias("hz"),
    len_,
])
case("combo/everything-e", "ge", [K], [
    agg("sum", filter_(V, bin_("gt", V, li(2)))).alias("fs"),
    agg("first", sort_by(Y, [V, ID])).alias("sb"),
    agg("last", sort_(V)).alias("mx"),
    agg("len", unique(V)).alias("nu"),
    agg("sum", head(V, 2)).alias("h2"),
    any_(col("b")).alias("any"),
    horiz("sum", [agg("sum", V), agg("max", Y)]).alias("hz"),
    len_,
])
case("combo/by-expr-key", "g", [bin_("mod", V, li(2))], [agg("sum", filter_(Y, bin_("gt", X, lf(0.5)))), agg("first", sort_(V, True)).alias("m")])
case("combo/by-null-key-f64", "g", [col("f64")], [agg("sum", filter_(Y, bin_("gt", Y, li(30)))), agg("len", unique(col("s"))).alias("u"), any_(col("b")).alias("a")])
case("combo/by-null-key-f32", "g", [col("f32")], [agg("first", sort_by(Y, [V, ID])), agg("sum", head(Y, 1)).alias("h")])
case("combo/sum-of-filter-over-total", "g", [K], [bin_("div", agg("sum", filter_(Y, bin_("gt", V, li(2)))), agg("sum", Y)).alias("share")])
case("combo/dup-name", "g", [K], [agg("sum", filter_(V, bin_("gt", V, li(2)))), agg("sum", head(V, 2))])
case("combo/key-name", "g", [K], [agg("sum", filter_(V, bin_("gt", V, li(2)))).alias("k")])
case("combo/cols", "g", [K], [agg("sum", filter_(cols(["v", "y"]), bin_("gt", V, li(2))))])
case("combo/all-numbers", "g", [K], [agg("first", sort_(cols(["v", "x", "y"])))])


# ---------------------------------------------------------------------------
# Division of an aggregated value in a group: polars keeps an aggregate a scalar
# and divides a float column by a scalar by multiplying with its reciprocal
# (`/`, `//` and `%`); an aggregate divided by an aggregate is a plain quotient
# ---------------------------------------------------------------------------
FDV = [0.1, 0.7, 0.3, 0.6, 1.1, 0.7, 0.3, 2.3, 0.3, 0.9, 0.6, 2.1]
TABLES["dv"] = pl.DataFrame([
    series_from_spec("k", "i64", [1] * 8 + [2] * 4),
    series_from_spec("f", "f64", FDV),
    series_from_spec("f3", "f32", FDV),
    series_from_spec("n", "i64", [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8]),
])
F, F3, NN = col("f"), col("f3"), col("n")
# a quotient of two aggregates multiplied by the rows (the divisor of the quotient
# is not the divisor of the product)
case("div/agg-quotient-times-col", "dv", [K], [agg("last", bin_("mul", bin_("div", agg("max", F), agg("sum", F)), F))])
case("div/agg-quotient-over-col", "dv", [K], [agg("first", bin_("div", bin_("div", agg("last", F), agg("sum", F)), F))])
case("div/agg-quotient-len-times-col", "dv", [K], [agg("last", bin_("mul", bin_("div", agg("sum", F), len_), F))])
case("div/agg-quotient-f32", "dv", [K], [agg("last", bin_("mul", bin_("div", agg("max", F3), agg("sum", F3)), F3))])
for op in ["div", "floordiv", "mod"]:
    for c in ["f", "f3", "n"]:
        C = col(c)
        case(f"div/{op}/{c}-by-first", "dv", [K], [agg("last", bin_(op, C, agg("first", C)))])
        case(f"div/{op}/{c}-by-sum", "dv", [K], [agg("last", bin_(op, C, agg("sum", C)))])
        case(f"div/{op}/{c}-by-agg-expr", "dv", [K], [agg("sum", bin_(op, C, bin_("add", agg("max", C), li(1))))])
        case(f"div/{op}/{c}-by-mixed", "dv", [K], [agg("sum", bin_(op, C, bin_("add", C, agg("first", C))))])
        case(f"div/{op}/{c}-agg-by-col", "dv", [K], [agg("sum", bin_(op, agg("first", C), C))])
        case(f"div/{op}/{c}-agg-by-agg", "dv", [K], [bin_(op, agg("sum", C), agg("first", C))])
# `//` and `%` of two aggregates, then the rows: the quotient is a plain one
for op in ["floordiv", "mod"]:
    for c in ["f", "f3"]:
        C = col(c)
        for a in ["sum", "max", "last", "mean"]:
            for b in ["first", "min", "last", "mean", "sum", "max"]:
                case(f"div/{op}/{c}-grid-{a}-{b}", "dv", [K], [agg("last", bin_("mul", bin_(op, agg(a, C), agg(b, C)), C))])
for i, (e, _) in enumerate(W["gen_div_exprs"](20261124, 90, ["f", "f3"])):
    case(f"div/rand/{i}", "dv", [K], [e])
for i, (e, _) in enumerate(W["gen_div_exprs"](20261125, 30, ["n", "f"], ["n", "f", "f3"])):
    case(f"div/rand-mixed/{i}", "dv", [K], [e])

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------


def mb_cases_file():
    lines = ["// 由 docs/golden/scripts/group_by_ext.py 生成，勿手改", ""]
    chunk = 40
    parts = [MB[i:i + chunk] for i in range(0, len(MB), chunk)]
    ty = "(Array[@pl.Expr], Array[@pl.Expr])"
    for pi, part in enumerate(parts):
        lines += ["///|", f"fn golden_group_by_ext_cases_{pi}(m : Map[String, {ty}]) -> Unit {{"]
        for cid, (ks, aggs) in part:
            lines.append(f"  m[{mb_str(cid)}] = ([{', '.join(ks)}], [{', '.join(aggs)}])")
        lines += ["}", ""]
    lines += ["///|", "/// Every case id with its key expressions and aggregation expressions.",
              f"fn golden_group_by_ext_cases() -> Map[String, {ty}] {{",
              f"  let m : Map[String, {ty}] = Map([])"]
    for pi in range(len(parts)):
        lines.append(f"  golden_group_by_ext_cases_{pi}(m)")
    lines += ["  m", "}", ""]
    path = os.path.join(_repo_root(), "src", "pl", "group_by_ext_cases_test.mbt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


doc = {
    "tables": {name: encode_frame(df) for name, df in TABLES.items()},
    "cases": CASES,
}
emit("group_by_ext", doc, compact=True)
# MoonBit source may not contain a raw U+2028/U+2029 (not even in a `#|` string)
path = os.path.join(_repo_root(), "src", "pl", "golden_group_by_ext_data_test.mbt")
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
