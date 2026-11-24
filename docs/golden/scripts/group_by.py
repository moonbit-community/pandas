"""Generates the golden data of `DataFrame::group_by(...).agg(...)` and
`GroupBy::len` (docs/golden/group_by.json, src/pl/golden_group_by_data_test.mbt)
and the MoonBit expressions of every case (src/pl/group_by_cases_test.mbt).

Run from the repository root (on a machine with polars 2.1.0):
    ulimit -v 16000000; POLARS_MAX_THREADS=4 \
        /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/group_by.py

Every case is `table.group_by([keys], maintain_order=True).agg([aggs])` (or
`.len(name=...)`). The expression machinery (trees, renderers, the meaning of
`result`, `error`, `restricted`, `known_diff`, `str`) is that of `expr.py`,
`expr_agg.py` and `expr_seq.py`, whose parts before their first case are
executed here; see docs/golden/known-diffs/group_by.md.

The file is `{"tables": {name: frame}, "cases": [...]}` (compact layout). A case
has `id`, `polars` (the Python spelling), `key_str` and `str` (polars' `str(expr)`
of every key and every aggregation), `table`, optional `how` (`len`, with the
optional `name`), and one of
  - `result`: the frame (through `to_ours`);
  - `error` + `message`: the variant per the M2 error mapping, polars' first
    line of the message;
  - `restricted: true`: polars gives a `list[...]` column (the library has no
    List type) or the library is stricter; the library raises
    `InvalidOperation`; `polars_schema` records polars' result schema.
`known_diff` marks a case whose `result` is the library's, not polars': the
polars result is in `polars_schema`.

Extra tables: `g` (12 rows: an Int64 key `k` with a null group and a group of
one row, one column of every type with nulls, NaN, -0.0 and the Review Focus
values, plus `x` and `y`), `ge` (no rows), `big` (300 rows, groups of 140, 130,
4 and 26 rows: pairwise sums), `gn` (the number columns of `g`), `z0` (no
columns).

Nodes added to the trees: ("len",) is `pl.len()`.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

# -- the shared part of expr_seq.py (which shares that of expr_agg.py and expr.py) --
_src = open(os.path.join(HERE, "expr_seq.py"), encoding="utf-8").read()
_marker = "# ---------------------------------------------------------------------------\n# shift, diff"
_prefix = _src[: _src.index(_marker)]
S = {"__name__": "expr_seq_prefix", "__file__": os.path.join(HERE, "expr_seq.py")}
exec(compile(_prefix, os.path.join(HERE, "expr_seq.py"), "exec"), S)
A = S["A"]
_ns = S["_ns"]

pl = S["pl"]
emit = S["emit"]
encode_series = S["encode_series"]
series_from_spec = S["series_from_spec"]
encode_frame = S["encode_frame"]
_repo_root = S["_repo_root"]
col, cols, all_ = S["col"], S["cols"], S["all_"]
li, lf, ls, lb, lit = S["li"], S["lf"], S["ls"], S["lb"], S["lit"]
bin_, neg, not_, alias, cast = S["bin_"], S["neg"], S["not_"], S["alias"], S["cast"]
is_null, is_not_null = S["is_null"], S["is_not_null"]
agg, fill, fn, isin = S["agg"], S["fill"], S["fn"], S["isin"]
when_ = S["when_"]
std, var, quant = A["std"], A["var"], A["quant"]
N = S["N"]
shift, diff, cum, rank, reverse = S["shift"], S["diff"], S["cum"], S["rank"], S["reverse"]
st, dtf = S["st"], S["dtf"]
mb_str = S["mb_str"]
nan, inf = S["nan"], S["inf"]
I64_MAX, I64_MIN = S["I64_MAX"], S["I64_MIN"]
VARIANTS = S["VARIANTS"]
strengthen = _ns["strengthen"]
schema_text = S["schema_text"]
IDS = set()

# -- pl.len() -----------------------------------------------------------------------
_prev_pl, _prev_py, _prev_mb = S["to_pl"], S["to_py"], S["to_mb"]


def to_pl(n):
    return pl.len() if n[0] == "len" else _prev_pl(n)


def to_py(n):
    return "pl.len()" if n[0] == "len" else _prev_py(n)


def to_mb(n):
    return "@pl.len()" if n[0] == "len" else _prev_mb(n)


for ns in (S, A, _ns):
    ns["to_pl"], ns["to_py"], ns["to_mb"] = to_pl, to_py, to_mb

len_ = N(("len",))

# -- tables ---------------------------------------------------------------------------
G = {
    "k": [1, 1, 2, 1, None, 2, 1, 3, 3, 1, 2, 1],
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
GT = {"k": "i64", "i32": "i32", "i64": "i64", "f32": "f32", "f64": "f64", "s": "str", "b": "bool",
      "d": "date", "dt": "datetime[μs]", "n": "null", "x": "f64", "y": "i64"}
GCOLS = ["i32", "i64", "f32", "f64", "s", "b", "d", "dt", "n"]
GDF = pl.DataFrame([series_from_spec(c, GT[c], v) for c, v in G.items()])

BIG_N = 300
_perm = [(i * 13) % BIG_N for i in range(BIG_N)]
BIG = {
    "k": [0 if p < 140 else 1 if p < 270 else 2 if p < 274 else 3 for p in _perm],
    "x": [((i * 7919) % 1000) / 7.0 - 50.0 + 1e-3 * i for i in range(BIG_N)],
    "xf": [((i * 104729) % 997) / 3.0 - 100.0 + 1e-2 * i for i in range(BIG_N)],
    "v": [(i * 37) % 101 - 50 for i in range(BIG_N)],
}
BIGT = {"k": "i64", "x": "f64", "xf": "f32", "v": "i64"}
BIGDF = pl.DataFrame([series_from_spec(c, BIGT[c], v) for c, v in BIG.items()])


# Groups with infinite values and overflows: the sum of a group keeps an infinity
# (Kahan summation must not turn it into NaN).
INF_ROWS = [
    [1.0, inf, 2.0], [1.0, -inf], [1e308, 1e308, -1e308], [inf, -inf], [inf], [-inf],
    [nan, inf], [inf, nan], [1.0, 2.0, inf, -1.0], [None, inf], [inf, None, 1.0],
    [-1e308, -1e308, 1e308], [0.5, -inf, 0.25], [inf, inf], [1e308, 1e308],
]
INF_F32_ROWS = [
    [1.0, inf, 2.0], [1.0, -inf], [3e38, 3e38, -3e38], [inf, -inf], [inf], [-inf],
    [nan, inf], [inf, nan], [1.0, 2.0, inf, -1.0], [None, inf], [inf, None, 1.0],
    [-3e38, -3e38, 3e38], [0.5, -inf, 0.25], [inf, inf], [3e38, 3e38],
]
INFDF = pl.DataFrame([
    series_from_spec("k", "i64", [i for i, g in enumerate(INF_ROWS) for _ in g]),
    series_from_spec("x", "f64", [v for g in INF_ROWS for v in g]),
    series_from_spec("y", "f32", [v for g in INF_F32_ROWS for v in g]),
])
# a column that has the name the implementation might use for its own helpers
GLDF = pl.DataFrame([
    series_from_spec("k", "i64", [1, 1, 2, 2, 2]),
    series_from_spec("group leaf 0", "i64", [1, 2, 3, 4, 5]),
    series_from_spec("group leaf 1", "f64", [0.5, 1.5, 2.5, 3.5, 4.5]),
    series_from_spec("s", "str", ["a", "b", "1", "2", "3"]),
    series_from_spec("wgroup leaf 0", "str", ["x", "y", "3", "4", "5"]),
    series_from_spec("sv", "str", ["group leaf 0", "1", "2", "3", "group leaf_ 0"]),
])
TABLES = {
    "g": GDF,
    "ge": GDF.clear(),
    "big": BIGDF,
    "gn": GDF.select(["k", "i32", "i64", "f32", "f64"]),
    "inf": INFDF,
    "gl": GLDF,
    "z0": pl.DataFrame(),
}

# -- running --------------------------------------------------------------------------
CASES = []
MB = []
FLAKY_RUNS = 6


def run_gb(df, keys, aggs, how, name):
    """`(frame, None)` or `(None, (polars class, variant, first message line))`."""
    try:
        g = df.group_by([to_pl(k) for k in keys], maintain_order=True)
        if how == "len":
            res = g.len() if name is None else g.len(name=name)
        else:
            res = g.agg([to_pl(a) for a in aggs])
        return res, None
    except BaseException as e:  # noqa: BLE001  (polars panics are BaseExceptions)
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        cls = type(e).__name__
        return None, (cls, VARIANTS.get(cls, cls), str(e).split("\n")[0])


def py_text(table, keys, aggs, how, name):
    ks = ", ".join(to_py(k) for k in keys)
    head = f"{table}.group_by([{ks}], maintain_order=True)"
    if how == "len":
        return head + (".len()" if name is None else f".len(name={json.dumps(name)})")
    return head + ".agg([" + ", ".join(to_py(a) for a in aggs) + "])"


def mb_text(keys, aggs, how, name):
    nm = "None" if name is None else f"Some({mb_str(name)})"
    return ([to_mb(k) for k in keys], [to_mb(a) for a in aggs], nm)


def case(cid, table, keys, aggs=(), how="agg", name=None, restricted=False):
    assert cid not in IDS, cid
    keys, aggs = list(keys), list(aggs)
    df = TABLES[table]
    res, err = run_gb(df, keys, aggs, how, name)
    rec = {
        "id": cid,
        "polars": py_text(table, keys, aggs, how, name),
        "key_str": [str(to_pl(k)) for k in keys],
        "str": [str(to_pl(a)) for a in aggs],
        "table": table,
    }
    if how != "agg":
        rec["how"] = how
        if name is not None:
            rec["name"] = name
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
            _, again = run_gb(df, keys, aggs, how, name)
            if again is None or again[2] != msg:
                print("FLAKY (skipped)", cid, msg, "|", None if again is None else again[2])
                return
        if cls == "PanicException":
            print("PANIC (skipped)", cid, msg)
            return
        rec["error"] = var_
        rec["message"] = msg
    else:
        known = None
        ours_keys = [strengthen(n) for n in keys]
        ours_aggs = [strengthen(n) for n in aggs]
        ours, oerr = run_gb(df, ours_keys, ours_aggs, how, name)
        if oerr is None and schema_text(ours) != schema_text(res):
            known = "dyn-literal-default"
            rec["polars_schema"] = schema_text(res)
            res = ours
        if known:
            rec["known_diff"] = known
        try:
            rec["result"] = encode_frame(res)
        except (ValueError, pl.exceptions.PolarsError) as e:
            print("SKIP", cid, e)
            return
    IDS.add(cid)
    CASES.append(rec)
    MB.append((cid, mb_text(keys, aggs, how, name)))


K = col("k")


def stricter(op, c):
    """polars gives nulls where the library refuses (the sum of a Date or Datetime,
    the quantile of text, Boolean and Null): see known-diffs/group_by.md."""
    return (op == "sum" and c in ("d", "dt")) or (op == "quantile" and c in ("s", "b", "n"))

SIMPLE = ["sum", "mean", "min", "max", "count", "len", "n_unique", "first", "last", "median", "product"]
EXTRA = [("std", 0), ("std", 1), ("std", 2), ("var", 0), ("var", 1), ("var", 2)]

# ---------------------------------------------------------------------------
# Keys
# ---------------------------------------------------------------------------
KEYAGGS = [len_, agg("sum", col("y")).alias("ys"), agg("first", col("s")).alias("sf")]
for c in GCOLS:
    case(f"key/{c}", "g", [col(c)], KEYAGGS)
    case(f"key/{c}/noagg", "g", [col(c)], [])
    case(f"key/{c}/e", "ge", [col(c)], KEYAGGS)
for ks in [["i32", "s"], ["b", "d"], ["s", "i32"], ["i32", "f64", "s"], ["n", "i32"], ["k", "b", "dt"],
           ["f32", "f64"], ["i64", "dt"]]:
    case("key/multi/" + "+".join(ks), "g", [col(c) for c in ks], KEYAGGS)
case("key/multi/e", "ge", [col("i32"), col("s")], KEYAGGS)
case("key/expr/mod", "g", [bin_("mod", col("i32"), li(2))], [len_])
case("key/expr/k-plus", "g", [bin_("add", col("k"), li(1))], [len_])
case("key/expr/alias", "g", [alias(bin_("mod", col("k"), li(2)), "kk")], [len_, agg("sum", col("y"))])
case("key/expr/str-len", "g", [st("len_chars", col("s"))], [len_])
case("key/expr/is-nan", "g", [fn("is_nan", col("f64"))], [len_])
case("key/expr/is-null", "g", [is_null(col("i32"))], [len_, agg("sum", col("y"))])
case("key/expr/cast", "g", [cast(col("f64"), "i64", False)], [len_])
case("key/expr/two", "g", [bin_("mod", col("k"), li(2)), col("b")], [len_])
case("key/expr/same-name", "g", [col("k"), bin_("add", col("k"), li(1))], [len_])
case("key/expr/same-name2", "g", [col("k"), alias(bin_("add", col("k"), li(1)), "k2")], [len_])
case("key/lit", "g", [li(1)], [agg("sum", col("y"))])
case("key/lit/e", "ge", [li(1)], [agg("sum", col("y"))])
case("key/lit-str", "g", [ls("q")], [len_])
case("key/lit+col", "g", [li(1), col("b")], [len_])
case("key/lit+col/e", "ge", [li(1), col("b")], [len_])
case("key/lit+col/e2", "ge", [col("b"), li(1)], [len_])
case("key/agg", "g", [agg("sum", col("k"))], [agg("sum", col("y"))])
case("key/agg/e", "ge", [agg("sum", col("k"))], [agg("sum", col("y")), len_])
case("key/cols", "g", [cols(["i32", "b"])], [len_])
case("key/cols-one", "g", [cols(["b"])], [len_])
case("key/all", "gn", [all_], [len_])
case("key/none", "g", [], [len_, agg("sum", col("y"))])
case("key/none/noagg", "g", [], [])
case("key/none/e", "ge", [], [len_, agg("sum", col("y")), agg("mean", col("y")).alias("m")])
case("key/none/z0", "z0", [], [len_])
case("key/none/z0-lit", "z0", [], [li(1)])
case("key/none/z0-noagg", "z0", [], [])
case("key/none/sums", "g", [], [agg("sum", col("i64")), agg("mean", col("f64")).alias("m"), len_.alias("n")])
case("key/none/sums/e", "ge", [], [agg("sum", col("i64")), agg("mean", col("f64")).alias("m"), len_.alias("n")])
case("key/none/first", "ge", [], [agg("first", col("i32")), agg("last", col("s")).alias("sl"),
                                  agg("n_unique", col("b")).alias("nu"), agg("min", col("f64")).alias("mn"),
                                  agg("median", col("y")).alias("md"), agg("product", col("y")).alias("pr"),
                                  agg("count", col("d")).alias("cn")])
case("key/none/std", "ge", [std(col("y"), 1), var(col("y"), 0).alias("v0"), quant(col("x"), 0.3).alias("q")])
case("key/none/group-level", "ge", [agg("sum", bin_("sub", col("x"), agg("mean", col("x")))).alias("dev"),
                                    agg("last", cum("sum", col("y"))).alias("cl")])
case("key/none/group-level/g", "g", [agg("sum", bin_("sub", col("x"), agg("mean", col("x")))).alias("dev"),
                                     agg("last", cum("sum", col("y"))).alias("cl")])
case("key/none/list/e", "ge", [], [col("y")], restricted=True)
case("key/none/list", "g", [], [col("y")], restricted=True)
case("key/none/lit/e", "ge", [], [li(1)])
case("key/none/lit", "g", [], [li(1), alias(lf(2.5), "f")])
case("key/missing", "g", [col("zz")], [len_])
case("key/missing2", "g", [col("k"), col("zz")], [len_])
case("key/missing/z0", "z0", [col("zz")], [len_])
case("key/dup", "g", [col("k"), col("k")], [len_])
case("key/dup-alias", "g", [col("k"), alias(col("i32"), "k")], [len_])
case("key/type-error", "g", [bin_("add", col("k"), col("s"))], [len_], restricted=True)
case("key/type-error/agg-type-error", "g", [bin_("add", col("k"), col("s"))], [agg("sum", col("s"))])
case("key/agg-type-error", "g", [col("k")], [agg("sum", col("s"))])
case("key/cols-missing", "g", [cols(["i32", "zz"])], [len_])

# ---------------------------------------------------------------------------
# Aggregations: every operation on every type
# ---------------------------------------------------------------------------
for op in SIMPLE:
    for c in GCOLS:
        case(f"agg/{op}/{c}", "g", [K], [agg(op, col(c))], restricted=stricter(op, c))
for op, d in EXTRA:
    for c in GCOLS:
        case(f"agg/{op}{d}/{c}", "g", [K], [(std if op == "std" else var)(col(c), d)])
for c in GCOLS:
    case(f"agg/quantile/{c}", "g", [K], [quant(col(c), 0.5)], restricted=stricter("quantile", c))
for m in ["nearest", "higher", "lower", "midpoint", "linear", "equiprobable"]:
    for c in ["i32", "f64", "x"]:
        for q in [0.0, 0.3, 1.0]:
            case(f"agg/quantile-{m}/{q}/{c}", "g", [K], [quant(col(c), q, m)])
# (a quantile outside [0, 1] is not a case: polars gives nulls in a group_by, the
# library raises ComputeError as in select, see known-diffs/group_by.md)
# the same on a table without rows (the types of the empty result)
for op in SIMPLE:
    for c in GCOLS:
        case(f"agg/{op}/{c}/e", "ge", [K], [agg(op, col(c))], restricted=stricter(op, c))
for op, d in EXTRA:
    for c in ["i32", "f32", "f64", "s", "d", "n", "b"]:
        case(f"agg/{op}{d}/{c}/e", "ge", [K], [(std if op == "std" else var)(col(c), d)])
for c in GCOLS:
    case(f"agg/quantile/{c}/e", "ge", [K], [quant(col(c), 0.5)], restricted=stricter("quantile", c))
# many at once, as the Review Focus asks
for c in GCOLS:
    case(f"agg/focus2/{c}", "ge", [col(c)], [agg("sum", col("y")), agg("mean", col("y")).alias("m"), len_])
    case(f"agg/focus2-f64/{c}", "ge", [col(c)], [agg("sum", col("x")), agg("mean", col("x")).alias("m"), len_])
case("agg/many", "g", [K], [agg("sum", col("i32")), agg("mean", col("f64")).alias("m"),
                            agg("min", col("s")).alias("mn"), agg("max", col("d")).alias("mx"),
                            agg("count", col("n")).alias("cn"), len_])
case("agg/many/e", "ge", [K], [agg("sum", col("i32")), agg("mean", col("f64")).alias("m"),
                               agg("min", col("s")).alias("mn"), agg("max", col("d")).alias("mx"),
                               agg("count", col("n")).alias("cn"), len_])
# the pairwise sums of large groups
for op in ["sum", "mean", "min", "max", "median", "first", "last", "count", "n_unique", "product"]:
    for c in ["x", "xf", "v"]:
        case(f"big/{op}/{c}", "big", [K], [agg(op, col(c))])
for op, d in [("std", 1), ("var", 1), ("var", 0)]:
    for c in ["x", "xf", "v"]:
        case(f"big/{op}{d}/{c}", "big", [K], [(std if op == "std" else var)(col(c), d)])
for c in ["x", "xf"]:
    case(f"big/quantile/{c}", "big", [K], [quant(col(c), 0.3, "linear")])
case("big/sum-mean-len", "big", [K], [agg("sum", col("x")), agg("mean", col("xf")).alias("m"), len_])
case("big/none", "big", [], [agg("sum", col("x")), agg("mean", col("xf")).alias("m"), len_])

# ---------------------------------------------------------------------------
# Literals and pl.len()
# ---------------------------------------------------------------------------
case("lit/int", "g", [K], [li(1)])
case("lit/int-alias", "g", [K], [alias(li(1), "x")])
case("lit/float", "g", [K], [lf(1.5)])
case("lit/str", "g", [K], [ls("q")])
case("lit/bool", "g", [K], [lb(True)])
case("lit/null", "g", [K], [lit("null", None)])
case("lit/i32", "g", [K], [lit("i32", 7)])
case("lit/sum", "g", [K], [agg("sum", li(1))])
case("lit/count", "g", [K], [agg("count", li(1))])
case("lit/len", "g", [K], [agg("len", li(1))])
case("lit/n_unique", "g", [K], [agg("n_unique", li(1))])
case("lit/mean", "g", [K], [agg("mean", lf(2.0))])
case("lit/sum-lits", "g", [K], [agg("sum", bin_("add", li(1), li(2)))])
case("lit/sum-str", "g", [K], [agg("sum", ls("a"))])
case("lit/plus-agg", "g", [K], [bin_("add", li(1), agg("sum", col("y")))])
case("lit/e", "ge", [K], [li(1), alias(lf(2.5), "f"), alias(ls("q"), "s")])
case("plen/expr", "g", [K], [len_])
case("plen/times", "g", [K], [bin_("mul", len_, li(2))])
case("plen/alias", "g", [K], [len_.alias("n"), agg("sum", col("y"))])
case("plen/as-k", "g", [K], [len_.alias("k")])
case("plen/vs-count", "g", [K], [len_, agg("count", col("i32")).alias("c"), agg("len", col("i32")).alias("l")])
case("plen/ratio", "g", [K], [bin_("div", agg("count", col("i32")), len_).alias("r")])
case("plen/e", "ge", [K], [len_])
case("plen/select", "g", [], [len_])

# ---------------------------------------------------------------------------
# Expressions around aggregations
# ---------------------------------------------------------------------------
Y, X = col("y"), col("x")
case("expr/sum-over-count", "g", [K], [bin_("div", agg("sum", Y), agg("count", Y)).alias("avg")])
case("expr/max-minus-min", "g", [K], [bin_("sub", agg("max", Y), agg("min", Y)).alias("range")])
case("expr/sum-plus-1", "g", [K], [bin_("add", agg("sum", Y), li(1))])
case("expr/sum-plus-1.5", "g", [K], [bin_("add", agg("sum", Y), lf(1.5))])
case("expr/1-plus-sum", "g", [K], [bin_("add", li(1), agg("sum", Y))])
case("expr/neg-sum", "g", [K], [neg(agg("sum", Y))])
case("expr/abs-sum", "g", [K], [fn("abs", agg("sum", col("i32")))])
case("expr/sqrt-sum", "g", [K], [fn("sqrt", agg("sum", X))])
case("expr/round-mean", "g", [K], [A["round_"](agg("mean", X), 1)])
case("expr/cast-sum", "g", [K], [cast(agg("sum", Y), "f64")])
case("expr/is-null-sum", "g", [K], [is_null(agg("min", col("i32")))])
case("expr/gt-sum", "g", [K], [bin_("gt", agg("sum", Y), li(100))])
case("expr/and-gt", "g", [K], [bin_("and", bin_("gt", agg("sum", Y), li(100)), bin_("lt", agg("count", Y), li(5)))])
case("expr/fill-null-min", "g", [K], [fill(agg("min", col("i32")), li(-1))])
case("expr/fill-null-mean", "g", [K], [fill(agg("mean", col("i32")), lf(0.0))])
case("expr/between", "g", [K], [A["btw"](agg("sum", Y), li(60), li(300))])
case("expr/when-sums", "g", [K], [when_(bin_("gt", agg("sum", Y), li(100)), agg("sum", X), lf(0.0))])
case("expr/when-lit", "g", [K], [when_(bin_("gt", agg("count", Y), li(2)), li(1), li(0))])
case("expr/str-of-min", "g", [K], [st("len_chars", agg("min", col("s")))])
case("expr/str-of-first", "g", [K], [st("to_uppercase", agg("first", col("s")))])
case("expr/dt-of-max", "g", [K], [dtf("year", agg("max", col("d")))])
case("expr/sum-of-sum", "g", [K], [agg("sum", agg("sum", Y))])
case("expr/mean-of-sum", "g", [K], [agg("mean", agg("sum", Y))])
case("expr/first-of-mean", "g", [K], [agg("first", agg("mean", X))])
case("expr/min-of-count", "g", [K], [agg("min", agg("count", col("i32")))])
case("expr/two-aggs-names", "g", [K], [bin_("add", agg("sum", Y), agg("sum", col("i32"))), bin_("add", agg("sum", col("i32")), agg("sum", Y))])
case("expr/sum+sum-names", "g", [K], [bin_("add", agg("sum", Y), agg("max", Y)).alias("z"), agg("min", Y)])
case("expr/agg-str-lit", "g", [K], [bin_("add", agg("min", col("s")), ls("x"))], restricted=True)

# row-wise expressions, then aggregated
case("rows/a*b-sum", "g", [K], [agg("sum", bin_("mul", Y, col("i32"))).alias("p")])
case("rows/x*y-sum", "g", [K], [agg("sum", bin_("mul", X, Y)).alias("p")])
case("rows/when-sum", "g", [K], [agg("sum", when_(bin_("gt", col("i32"), li(0)), Y, li(0)))])
case("rows/when-sum-f", "g", [K], [agg("sum", when_(bin_("gt", X, lf(0.5)), X, lf(0.0)))])
case("rows/fill_null-mean", "g", [K], [agg("mean", fill(col("i32"), li(0)))])
case("rows/fill_null-sum-f", "g", [K], [agg("sum", fill(col("f64"), lf(0.0)))])
case("rows/abs-max", "g", [K], [agg("max", fn("abs", col("i32")))])
case("rows/is_null-sum", "g", [K], [agg("sum", is_null(col("i32")))])
case("rows/is_not_null-mean", "g", [K], [agg("mean", is_not_null(col("s")))])
case("rows/cast-sum", "g", [K], [agg("sum", cast(col("b"), "i32"))])
case("rows/b-sum", "g", [K], [agg("sum", col("b"))])
case("rows/gt-sum", "g", [K], [agg("sum", bin_("gt", Y, li(50)))])
case("rows/str-len-max", "g", [K], [agg("max", st("len_chars", col("s")))])
case("rows/str-upper-first", "g", [K], [agg("first", st("to_uppercase", col("s")))])
case("rows/dt-year-max", "g", [K], [agg("max", dtf("year", col("d")))])
case("rows/is_in-sum", "g", [K], [agg("sum", isin(col("i32"), "i32"))])
case("rows/between-sum", "g", [K], [agg("sum", A["btw"](Y, li(30), li(90)))])
case("rows/n_unique-expr", "g", [K], [agg("n_unique", bin_("mod", Y, li(20)))])
case("rows/lit-sum", "g", [K], [agg("sum", bin_("add", Y, li(1)))])
case("rows/e", "ge", [K], [agg("sum", bin_("mul", Y, col("i32"))).alias("p"), agg("mean", fill(col("i32"), li(0))).alias("m")])
case("rows/neg-min", "g", [K], [agg("min", neg(Y))])
case("rows/type-error", "g", [K], [agg("sum", bin_("add", col("s"), li(1)))], restricted=True)

# expressions that have to be evaluated group by group
case("grp/dev-sum", "g", [K], [agg("sum", bin_("sub", X, agg("mean", X)))])
case("grp/dev-sum-int", "g", [K], [agg("sum", bin_("sub", Y, agg("min", Y)))])
case("grp/cum_sum-last", "g", [K], [agg("last", cum("sum", Y))])
case("grp/cum_max-sum", "g", [K], [agg("sum", cum("max", col("i32")))])
case("grp/shift-sum", "g", [K], [agg("sum", shift(Y, 1))])
case("grp/shift-first", "g", [K], [agg("first", shift(Y, 1))])
case("grp/shift-neg-last", "g", [K], [agg("last", shift(Y, -1))])
case("grp/diff-sum", "g", [K], [agg("sum", diff(Y))])
case("grp/rank-max", "g", [K], [agg("max", rank(Y))])
case("grp/rank-min-ordinal", "g", [K], [agg("max", rank(col("f64"), "ordinal"))])
case("grp/reverse-first", "g", [K], [agg("first", reverse(Y))])
case("grp/fill-forward-last", "g", [K], [agg("last", S["fills"](col("i32"), "forward"))])
case("grp/count-of-shift", "g", [K], [agg("count", shift(col("i32"), 1))])
case("grp/len-of-shift", "g", [K], [agg("len", shift(col("i32"), 1))])
case("grp/n_unique-of-rank", "g", [K], [agg("n_unique", rank(Y))])
case("grp/sum-in-when", "g", [K], [agg("sum", when_(bin_("gt", Y, agg("mean", Y)), li(1), li(0)))])
case("grp/dev-over-len", "g", [K], [agg("max", bin_("div", Y, len_))])
case("grp/dev-sq", "g", [K], [agg("mean", bin_("mul", bin_("sub", X, agg("mean", X)), bin_("sub", X, agg("mean", X))))])
case("grp/sum-of-sum-in-agg", "g", [K], [agg("sum", bin_("add", Y, agg("sum", Y)))])
case("grp/median-dev", "g", [K], [agg("median", bin_("sub", X, agg("median", X)))])
case("grp/e", "ge", [K], [agg("sum", bin_("sub", X, agg("mean", X))), agg("last", cum("sum", Y)).alias("cl"),
                         agg("max", rank(Y)).alias("rm")])
case("grp/rank-str", "g", [K], [agg("max", rank(col("s")))])
case("grp/cum_sum-str", "g", [K], [agg("last", cum("sum", col("s")))])
case("grp/big-dev", "big", [K], [agg("sum", bin_("sub", col("x"), agg("mean", col("x"))))])
# a sequence operation on a value that is already one per group
case("scalar-seq/cum_sum", "g", [K], [cum("sum", agg("sum", Y))])
case("scalar-seq/shift", "g", [K], [shift(agg("sum", Y), 1)])
case("scalar-seq/shift-neg", "g", [K], [shift(agg("max", col("i32")), -1)])
case("scalar-seq/diff", "g", [K], [diff(agg("sum", Y))])
case("scalar-seq/rank", "g", [K], [rank(agg("sum", Y))])
case("scalar-seq/rank-null", "g", [K], [rank(agg("min", col("i32")))])
case("scalar-seq/reverse", "g", [K], [reverse(agg("sum", Y))])
case("scalar-seq/cum_count", "g", [K], [cum("count", agg("min", col("i32")))])
case("scalar-seq/fill-forward", "g", [K], [S["fills"](agg("min", col("i32")), "forward")])
case("scalar-seq/e", "ge", [K], [cum("sum", agg("sum", Y)), shift(agg("sum", Y), 1).alias("sh")])

# ---------------------------------------------------------------------------
# Restricted: the result would be a list per group
# ---------------------------------------------------------------------------
LISTY = {
    "col": col("y"),
    "col-s": col("s"),
    "col-n": col("n"),
    "alias": alias(col("y"), "z"),
    "cum_sum": cum("sum", Y),
    "shift": shift(Y, 1),
    "rank": rank(Y),
    "reverse": reverse(Y),
    "plus-1": bin_("add", Y, li(1)),
    "plus-agg": bin_("add", Y, agg("sum", Y)),
    "agg-plus": bin_("add", agg("sum", Y), Y),
    "lit-plus-col": bin_("add", li(1), Y),
    "is_null": is_null(col("i32")),
    "abs": fn("abs", col("i32")),
    "cast": cast(col("f64"), "i64", False),
    "fill_null": fill(col("i32"), li(0)),
    "when-col": when_(bin_("gt", Y, li(50)), Y, li(0)),
    "when-mix": when_(bin_("gt", agg("sum", Y), li(100)), Y, li(0)),
    "when-cond": when_(bin_("gt", Y, li(50)), agg("sum", Y), li(0)),
    "str": st("to_uppercase", col("s")),
    "dt": dtf("year", col("d")),
    "is_in": isin(col("i32"), "i32"),
    "between": A["btw"](Y, li(1), li(50)),
    "neg": neg(Y),
    "not": not_(col("b")),
    "sum-of-col-plus": bin_("add", agg("sum", Y), bin_("add", Y, li(1))),
}
for name_, node in LISTY.items():
    case(f"list/{name_}", "g", [K], [node], restricted=True)
case("list/is_in-scalar", "g", [K], [isin(agg("first", col("i32")), "i32")], restricted=True)
case("list/is_in-sum", "g", [K], [isin(agg("sum", Y), "i64")], restricted=True)
case("list/is_in-lit", "g", [K], [isin(li(1), "i64")], restricted=True)
case("list/two", "g", [K], [agg("sum", Y), col("x")], restricted=True)
case("list/first-bad-second", "g", [K], [col("x"), agg("sum", Y).alias("s")], restricted=True)
case("list/all", "gn", [K], [all_], restricted=True)
case("list/cols", "gn", [K], [cols(["i32", "i64"])], restricted=True)
case("list/e", "ge", [K], [col("y")], restricted=True)
case("list/e-cum", "ge", [K], [cum("sum", Y)], restricted=True)
case("list/e-plus-agg", "ge", [K], [bin_("add", Y, agg("sum", Y))], restricted=True)

# ---------------------------------------------------------------------------
# Selectors in agg
# ---------------------------------------------------------------------------
case("sel/all-sum", "gn", [K], [agg("sum", all_)])
case("sel/all-sum-key-i32", "gn", [col("i32")], [agg("sum", all_)])
case("sel/all-sum-key-expr", "gn", [bin_("mod", col("k"), li(2))], [agg("sum", all_)])
case("sel/all-sum-key-alias", "gn", [alias(col("k"), "kk")], [agg("sum", all_)])
case("sel/all-sum-two-keys", "gn", [col("k"), col("i32")], [agg("sum", all_)])
case("sel/all-sum-key-lit", "gn", [li(1)], [agg("sum", all_)])
case("sel/all-sum-no-key", "gn", [], [agg("sum", all_)])
case("sel/all-mean-e", "ge", [K], [agg("mean", all_)])
case("sel/all-len", "gn", [K], [agg("len", all_)])
case("sel/all-alias", "gn", [K], [alias(agg("sum", all_), "x")])
case("sel/all-first-str", "g", [K], [agg("first", all_)])
case("sel/all-sum-str", "g", [K], [agg("sum", all_)])
case("sel/all-plus", "gn", [K], [bin_("add", agg("sum", all_), li(1))])
case("sel/all-sum-plus-all", "gn", [K], [bin_("add", agg("sum", all_), agg("count", all_))])
case("sel/cols-sum", "gn", [K], [agg("sum", cols(["i32", "i64"]))])
case("sel/cols-with-key", "gn", [K], [agg("sum", cols(["k", "i32"]))])
case("sel/cols-missing", "gn", [K], [agg("sum", cols(["i32", "zz"]))])
case("sel/cols-and-col", "gn", [K], [agg("sum", cols(["i32", "i64"])), agg("mean", col("f64"))])
case("sel/cols-empty", "gn", [K], [agg("sum", cols([]))])
case("sel/cols-width", "gn", [K], [bin_("add", agg("sum", cols(["i32", "i64"])), agg("sum", cols(["f32", "f64", "i32"])))])
case("sel/cols-pair", "gn", [K], [bin_("add", agg("sum", cols(["i32", "i64"])), agg("sum", cols(["f32", "f64"])))])
case("sel/cols-dup", "gn", [K], [agg("sum", cols(["i32", "i64"])), agg("min", cols(["i32"]))])

# ---------------------------------------------------------------------------
# Output names and errors
# ---------------------------------------------------------------------------
case("name/key-vs-agg", "g", [K], [agg("sum", K)])
case("name/key-vs-col", "g", [K], [K])
case("name/key-vs-alias", "g", [K], [alias(agg("sum", Y), "k")])
case("name/key-vs-len", "g", [K], [len_.alias("k")])
case("name/key-vs-lit", "g", [K], [alias(li(1), "k")])
case("name/key-alias-vs-agg", "g", [alias(col("i32"), "k")], [agg("sum", K)])
case("name/key-expr-vs-agg", "g", [bin_("mod", K, li(2))], [agg("sum", K)])
case("name/two-aggs", "g", [K], [agg("sum", Y), agg("mean", Y)])
case("name/two-aliases", "g", [K], [agg("sum", Y).alias("a"), agg("mean", Y).alias("a")])
case("name/lit-lit", "g", [K], [li(1), li(2)])
case("name/len-len", "g", [K], [len_, len_])
case("name/len-vs-col", "g", [K], [len_, agg("sum", col("y")).alias("len")])
case("name/alias-of-key", "g", [K], [alias(agg("sum", Y), "y")])
case("name/key-named-len", "g", [alias(col("k"), "len")], [len_])
case("name/three-same", "g", [K], [agg("sum", Y), agg("min", Y), agg("max", Y)])
case("name/empty-alias", "g", [K], [alias(agg("sum", Y), "")])
case("name/empty-key-alias", "g", [alias(K, "")], [len_])
case("err/missing-agg", "g", [K], [agg("sum", col("zz"))])
case("err/missing-agg-z0", "z0", [K], [agg("sum", col("zz"))])
case("err/missing-both", "g", [col("zz")], [agg("sum", col("zz2"))])
case("err/missing-second", "g", [K], [agg("sum", Y), agg("sum", col("zz"))])
case("err/missing-vs-dup", "g", [K], [agg("sum", Y), agg("mean", Y), agg("sum", col("zz"))])
case("err/dup-vs-missing", "g", [K], [agg("sum", K), agg("sum", col("zz"))])
case("err/missing-vs-type", "g", [K], [agg("sum", col("s")), agg("sum", col("zz"))])
case("err/type-vs-missing", "g", [K], [agg("sum", col("zz")), agg("sum", col("s"))])
case("err/type-vs-dup", "g", [K], [agg("sum", col("s")), agg("min", col("s"))])
case("err/type-vs-key-dup", "g", [K], [agg("sum", col("s")), agg("sum", K)])
case("err/type-vs-list", "g", [K], [bin_("add", col("s"), li(1))], restricted=True)
case("err/list-vs-type", "g", [K], [col("x"), agg("sum", col("s"))])
case("err/list-vs-dup", "g", [K], [col("y"), agg("sum", Y)])
case("err/list-vs-key-dup", "g", [K], [col("x"), agg("sum", K)])
case("err/list-vs-missing", "g", [K], [col("y"), agg("sum", col("zz"))])
case("err/missing-vs-list", "g", [K], [agg("sum", col("zz")), col("y")])
case("err/type-1", "g", [K], [agg("sum", col("s"))])
case("err/type-2", "g", [K], [agg("mean", col("s"))])
case("err/type-date-sum", "g", [K], [agg("sum", col("d"))], restricted=True)
case("err/type-2-aggs", "g", [K], [agg("sum", col("s")), agg("sum", col("d")).alias("dd")])
case("err/type-late", "g", [K], [agg("sum", Y), agg("sum", col("s")).alias("ss")])
case("err/type-in-expr", "g", [K], [agg("sum", bin_("add", col("s"), li(1)))], restricted=True)
case("err/type-nested", "g", [K], [bin_("add", agg("sum", col("s")), li(1))])
case("err/key-missing-vs-agg-type", "g", [col("zz")], [agg("sum", col("s"))])
case("err/key-type-vs-agg-missing", "g", [bin_("add", K, col("s"))], [agg("sum", col("zz"))])
case("err/key-dup-vs-agg-missing", "g", [K, K], [agg("sum", col("zz"))])
case("err/key-dup-vs-key-type", "g", [K, K, bin_("add", K, col("s"))], [len_])
case("err/key-dup-vs-agg-type", "g", [K, K], [agg("sum", col("s"))])
case("err/key-type-vs-key-missing", "g", [bin_("add", K, col("s")), col("zz")], [len_])
case("err/key-missing-vs-key-type", "g", [col("zz"), bin_("add", K, col("s"))], [len_])
case("err/e-type", "ge", [K], [agg("sum", col("s"))])
case("err/e-list-type", "ge", [K], [bin_("add", col("s"), li(1))], restricted=True)
case("err/e-missing", "ge", [K], [agg("sum", col("zz"))])

# ---------------------------------------------------------------------------
# GroupBy::len
# ---------------------------------------------------------------------------
for c in GCOLS:
    case(f"len/key/{c}", "g", [col(c)], how="len")
case("len/default", "g", [K], how="len")
case("len/name", "g", [K], how="len", name="n")
case("len/name-empty", "g", [K], how="len", name="")
case("len/name-key", "g", [K], how="len", name="k")
case("len/two-keys", "g", [col("i32"), col("s")], how="len")
case("len/expr-key", "g", [bin_("mod", K, li(2))], how="len")
case("len/expr-key-name", "g", [bin_("mod", K, li(2))], how="len", name="k")
case("len/lit-key", "g", [li(1)], how="len")
case("len/none", "g", [], how="len")
case("len/none/e", "ge", [], how="len")
case("len/none/z0", "z0", [], how="len")
case("len/e", "ge", [K], how="len")
case("len/e-name", "ge", [K], how="len", name="n")
case("len/missing", "g", [col("zz")], how="len")
case("len/dup-keys", "g", [K, K], how="len")
case("len/type-error", "g", [bin_("add", K, col("s"))], how="len", restricted=True)
case("len/cols", "g", [cols(["i32", "b"])], how="len")
case("len/big", "big", [K], how="len")

# ---------------------------------------------------------------------------
# Infinite values and overflow in sums, means and what is built on them
# ---------------------------------------------------------------------------
for c in ["x", "y"]:
    for op in ["sum", "mean", "min", "max", "first", "last", "product"]:
        case(f"inf/{op}/{c}", "inf", [K], [agg(op, col(c))])
    for op, d in [("std", 1), ("var", 1), ("std", 0), ("var", 0)]:
        case(f"inf/{op}{d}/{c}", "inf", [K], [(std if op == "std" else var)(col(c), d)])
    case(f"inf/times-one/{c}", "inf", [K], [agg("sum", bin_("mul", col(c), lf(1.0)))])
    case(f"inf/dev-sum/{c}", "inf", [K], [agg("sum", bin_("sub", col(c), agg("mean", col(c))))])
    case(f"inf/fill-sum/{c}", "inf", [K], [agg("sum", fill(col(c), lf(0.0)))])
    case(f"inf/sum-plus/{c}", "inf", [K], [bin_("add", agg("sum", col(c)), lf(1.0))])
case("inf/no-key", "inf", [], [agg("sum", col("x")), agg("mean", col("y")).alias("m")])

# ---------------------------------------------------------------------------
# Columns that carry the names of the library's helper columns, and the column
# named in an error
# ---------------------------------------------------------------------------
GL0 = col("group leaf 0")
GL1 = col("group leaf 1")
case("gl/sum-times-len", "gl", [K], [agg("sum", bin_("mul", GL0, len_))])
case("gl/dev-sum", "gl", [K], [agg("sum", bin_("sub", GL0, agg("mean", GL0)))])
case("gl/dev-sum-both", "gl", [K], [agg("sum", bin_("sub", GL1, agg("mean", GL0))).alias("a"),
                                    agg("sum", bin_("add", GL0, bin_("add", len_, agg("max", GL1)))).alias("b")])
case("gl/plain", "gl", [K], [agg("sum", GL0), agg("sum", GL1)])
case("gl/leaf-add", "gl", [K], [bin_("add", agg("sum", GL0), bin_("mul", agg("max", GL1), len_))])
case("gl/key", "gl", [GL0], [agg("sum", GL1)])
case("gl/cast-error", "gl", [K], [cast(agg("first", col("s")), "i64", True)])
case("gl/cast-error-two", "gl", [K], [bin_("add", cast(agg("first", col("s")), "i64", True), agg("last", GL0))])

# ---------------------------------------------------------------------------
# The error raised when several expressions are wrong
# ---------------------------------------------------------------------------
case("err2/and-then-unsupported", "g", [K], [agg("sum", bin_("and", col("i32"), col("b"))), agg("sum", col("s"))])
case("err2/unsupported-then-and", "g", [K], [agg("sum", col("s")), agg("sum", bin_("and", col("i32"), col("b")))])
case("err2/add-then-unsupported", "g", [K], [agg("sum", bin_("add", col("s"), li(1))), agg("sum", col("s"))])
case("err2/unsupported-then-add", "g", [K], [agg("sum", col("s")), agg("sum", bin_("add", col("s"), li(1)))])
case("err2/key-and-then-unsupported", "g", [bin_("and", col("i32"), col("b"))], [agg("sum", col("s"))])
case("err2/two-and", "g", [K], [agg("sum", bin_("and", col("i32"), col("b"))), agg("sum", bin_("and", col("i64"), col("b")))])

# user text that looks like the library's helper names is never altered in an error
case("gl/cast-error-value", "gl", [K], [cast(agg("first", col("sv")), "i64", True)])
case("gl/cast-error-value-two", "gl", [K], [bin_("add", cast(agg("first", col("sv")), "i64", True), agg("max", GL0))])

# errors that polars raises only when it runs a kernel, and a key that fails first
case("err2/product-then-and", "g", [K], [agg("product", col("s")), agg("sum", bin_("and", col("i32"), col("b")))])
case("err2/and-then-product", "g", [K], [agg("sum", bin_("and", col("i32"), col("b"))), agg("product", col("s"))])
case("err2/key-or-then-unsupported", "g", [bin_("or", col("f64"), col("i64"))], [agg("sum", col("s"))])
case("err2/key-and-then-missing", "g", [bin_("and", col("i32"), col("b"))], [agg("sum", col("zz"))])
case("err2/key-date-then-missing", "g", [bin_("add", col("d"), col("d"))], [agg("sum", col("zz"))], restricted=True)
case("err2/key-missing-then-key-type", "g", [col("zz"), bin_("and", col("i32"), col("b"))], [len_])
case("err2/and-then-add", "g", [K], [agg("sum", bin_("and", col("i32"), col("b"))), agg("sum", bin_("add", col("s"), li(1)))])

# ---------------------------------------------------------------------------
# The key is the value of the first row, nested aggregations of aggregations
# ---------------------------------------------------------------------------
KZ = pl.DataFrame([series_from_spec("k", "f64", [-0.0, 0.0, 0.0, -0.0, 0.0]),
                   series_from_spec("v", "i64", [1, 2, 3, 4, 5])])
TABLES["kz"] = KZ
case("first/zero-keys", "kz", [K], [agg("sum", col("v"))])
case("first/zero-keys-len", "kz", [K], [len_])
case("nest/sum-plus-sum", "g", [K], [agg("sum", bin_("add", agg("sum", Y), li(1)))])
case("nest/len-plus-sum", "g", [K], [agg("sum", bin_("add", len_, li(1)))])
case("nest/len-plus-mean", "g", [K], [agg("mean", bin_("add", len_, col("y")))])
case("nest/lit-sum", "g", [K], [agg("sum", li(5))])

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------


def mb_cases_file():
    lines = ["// 由 docs/golden/scripts/group_by.py 生成，勿手改", ""]
    chunk = 40
    parts = [MB[i:i + chunk] for i in range(0, len(MB), chunk)]
    ty = "(Array[@pl.Expr], Array[@pl.Expr], String?)"
    sig = f"m : Map[String, {ty}], vs : Map[String, @pl.Series]"
    for pi, part in enumerate(parts):
        lines += ["///|", f"fn golden_group_by_cases_{pi}({sig}) -> Unit {{", "  ignore(vs)"]
        for cid, (ks, aggs, nm) in part:
            lines.append(f"  m[{mb_str(cid)}] = ([{', '.join(ks)}], [{', '.join(aggs)}], {nm})")
        lines += ["}", ""]
    lines += ["///|", "/// Every case id with its key expressions, aggregation expressions and the",
              "/// `name` of a `GroupBy::len` case (`Some` only for the `len` cases that pass one).",
              f"fn golden_group_by_cases(vs : Map[String, @pl.Series]) -> Map[String, {ty}] {{",
              f"  let m : Map[String, {ty}] = Map([])"]
    for pi in range(len(parts)):
        lines.append(f"  golden_group_by_cases_{pi}(m, vs)")
    lines += ["  m", "}", ""]
    path = os.path.join(_repo_root(), "src", "pl", "group_by_cases_test.mbt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


doc = {
    "tables": {name: encode_frame(df) for name, df in TABLES.items()},
    "inputs": {k: encode_series(S["input_series"](k)) for k in ["i32", "i64"]},
    "cases": CASES,
}
emit("group_by", doc, compact=True)
# MoonBit source may not contain a raw U+2028/U+2029 (not even in a `#|` string)
path = os.path.join(_repo_root(), "src", "pl", "golden_group_by_data_test.mbt")
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
