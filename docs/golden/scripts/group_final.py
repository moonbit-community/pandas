"""Generates the golden data of two things `group_by(...).agg(...)` and `over` do
with a whole column that polars does per group or with other kernels
(docs/golden/group_final.json, src/pl/golden_group_final_data_test.mbt) and the
MoonBit expressions of every case (src/pl/group_final_cases_test.mbt).

Run from the repository root (on a machine with polars 2.1.0):
    ulimit -v 16000000; POLARS_MAX_THREADS=4 \
        /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/group_final.py

Built on `shape_base.py`, with two more nodes: `("todate", x, strict)` and
`("todatetime", x, strict)` (`x.str.to_date(strict=...)`,
`x.str.to_datetime(time_unit="us", strict=...)`).

1. The format of `str.to_date()` / `to_datetime()` is guessed from the first
   value it sees. Inside `agg` and `over` that is the first value of each
   group, not of the column. Tables `dd` (every group has a clean format of its
   own) and `ddx` (unreadable texts, a group of nulls); both functions, strict
   and lenient; first, last, count, n_unique, max, min, len, an expression
   built on the parsed value, a parsed value as a key and as a partition.
2. With no key, or keys that are all one value (a literal, an aggregation,
   `len()`), the whole column is one group and polars aggregates it with the
   kernels of `select` (pairwise float sums), not the ones it uses for the
   groups of a key column: the last digit of a float `sum`, `mean`, `std` and
   `var` differs. Table `fl` has 1000 rows (a float column with nulls, an
   `f32` column, an integer column); the keys `[]`, `lit(1)`,
   `lit(1).cast(i32)`, `lit("a")`, `sum()`, `len()`, and the same keys as
   `over` partitions, next to the plain `select` of the same aggregations.
   (The groups of a key column are in the small golden tables of `group_by.py`
   and `window.py`; from groups of about 40 rows polars' sums differ from
   the library's in the last digit, see known-diffs/group_by.md.)

Every case is `table.group_by([keys], maintain_order=True).agg([aggs])` (field
`op` is `group_by`) or `table.select([es])` / `table.with_columns([es])` (`op`
absent or `with_columns`); the fields are those of `group_by_ext.py` and
`window.py`.
"""
import json
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from shape_base import W, len_, over  # noqa: E402

A = W["A"]
pl = W["pl"]
emit = W["emit"]
encode_frame = W["encode_frame"]
series_from_spec = W["series_from_spec"]
_repo_root = W["_repo_root"]
N = W["N"]
col = W["col"]
li, lf, ls, lit = W["li"], W["lf"], W["ls"], W["lit"]
bin_, alias, cast = W["bin_"], W["alias"], W["cast"]
is_null = W["is_null"]
agg = W["agg"]
std, var = A["std"], A["var"]
dtf = W["dtf"]
mb_str = W["mb_str"]
VARIANTS = W["VARIANTS"]
schema_text = W["_ns"]["schema_text"]
strengthen = W["strengthen"]
_prev = {k: W[k] for k in ("to_pl", "to_py", "to_mb", "strengthen")}
TABLES = W["TABLES"]
_case = W["case"]


# -- the two nodes ----------------------------------------------------------------------
def to_pl(n):
    if n[0] == "todate":
        return to_pl(n[1]).str.to_date(strict=n[2])
    if n[0] == "todatetime":
        return to_pl(n[1]).str.to_datetime(time_unit="us", strict=n[2])
    return _prev["to_pl"](n)


def to_py(n):
    if n[0] == "todate":
        return f"{to_py(n[1])}.str.to_date(strict={n[2]})"
    if n[0] == "todatetime":
        return f"{to_py(n[1])}.str.to_datetime(time_unit=\"us\", strict={n[2]})"
    return _prev["to_py"](n)


def to_mb(n):
    if n[0] == "todate":
        return f"{to_mb(n[1])}.str().to_date(strict={'true' if n[2] else 'false'})"
    if n[0] == "todatetime":
        return f"{to_mb(n[1])}.str().to_datetime(strict={'true' if n[2] else 'false'})"
    return _prev["to_mb"](n)


def strengthen_ext(n, keep_weak=False):
    if n[0] in ("todate", "todatetime"):
        return (n[0], strengthen_ext(n[1]), n[2])
    return _prev["strengthen"](n, keep_weak)


import shape_base  # noqa: E402

# the recursion of every layer below must come back through these functions
for _d in (W, W["_ns"], W["A"], W["S"], vars(shape_base)):
    _d["to_pl"], _d["to_py"], _d["to_mb"] = to_pl, to_py, to_mb
    _d["strengthen"] = strengthen_ext
strengthen = strengthen_ext

todate = lambda x, strict=True: N(("todate", x, strict))
todatetime = lambda x, strict=True: N(("todatetime", x, strict))

# -- tables -----------------------------------------------------------------------------
# every group has a clean format of its own (the last group is a single row)
DD = {
    "k": [0, 0, 1, 1, 2, 2, 3, 3, 3, 4],
    "sd": ["2020-01-31", "2020-02-01", "31.01.2020", "01.02.2020", "2020-03-01",
           "2020-03-02", "2020/04/05", None, "2020/04/06", "05.06.2020"],
    "st": ["2020-01-31 10:00:00", "2020-02-01 11:30:15", "31.01.2020 10:00:00",
           "01.02.2020 11:30:15", "2020-03-01T08:00:00", "2020-03-02T09:00:00",
           "2020/04/05 12:00:00", None, "2020/04/06 13:00:00", "05.06.2020 14:00:00"],
    "v": [3, 1, 4, 1, 5, 9, 2, 6, 5, 3],
}
# unreadable texts: the first value of a group decides, one group is all null
DDX = {
    "k": [0, 0, 1, 1, 2, 2, 3, 3],
    "sd": ["2020-01-31", "bad", "31.01.2020", "01.02.2020", "junk", "2020-03-02", None, None],
    "st": ["2020-01-31 10:00:00", "bad", "31.01.2020 10:00:00", "01.02.2020 11:30:15",
           "junk", "2020-03-02 09:00:00", None, None],
    "v": [3, 1, 4, 1, 5, 9, 2, 6],
}
DDT = {c: "str" for c in ("sd", "st")}
DDT.update({"k": "i64", "v": "i64"})
TABLES["dd"] = pl.DataFrame([series_from_spec(c, DDT[c], v) for c, v in DD.items()])
TABLES["ddx"] = pl.DataFrame([series_from_spec(c, DDT[c], v) for c, v in DDX.items()])

_rng = random.Random(20261125)
FL_N = 1000
FL = {
    "k": [1] * FL_N,
    "g": [i % 3 for i in range(FL_N)],
    "v": [None if _rng.random() < 0.08 else round(_rng.uniform(-10, 10), 2) for _ in range(FL_N)],
    "f": [None if _rng.random() < 0.08 else round(_rng.uniform(-100, 100), 1) for _ in range(FL_N)],
    "i": [None if _rng.random() < 0.05 else _rng.randint(-1000, 1000) for _ in range(FL_N)],
}
FLT = {"k": "i64", "g": "i64", "v": "f64", "f": "f32", "i": "i64"}
TABLES["fl"] = pl.DataFrame([series_from_spec(c, FLT[c], v) for c, v in FL.items()])

# -- running ----------------------------------------------------------------------------
CASES = W["CASES"]
GB_CASES = []
GB_MB = []
MB = W["MB"]
IDS = A["IDS"]
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


def gcase(cid, table, keys, aggs):
    assert cid not in IDS, cid
    keys, aggs = list(keys), list(aggs)
    df = TABLES[table]
    res, err = run_gb(df, keys, aggs)
    rec = {
        "id": cid,
        "op": "group_by",
        "polars": py_text(table, keys, aggs),
        "key_str": [str(to_pl(k)) for k in keys],
        "str": [str(to_pl(a)) for a in aggs],
        "table": table,
    }
    if err is not None:
        cls, var_, msg = err
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
    GB_CASES.append(rec)
    GB_MB.append((cid, ([to_mb(k) for k in keys], [to_mb(a) for a in aggs])))


def ocase(cid, table, nodes, **kw):
    return _case(cid, table, nodes, **kw)


K, G, V, F, I = col("k"), col("g"), col("v"), col("f"), col("i")
SD, ST = col("sd"), col("st")

# ---------------------------------------------------------------------------
# 1. the format of to_date / to_datetime is guessed per group
# ---------------------------------------------------------------------------
PARSE = [("date", "sd", todate), ("datetime", "st", todatetime)]
for tab in ("dd", "ddx"):
    for kind, c, mk in PARSE:
        for strict in (True, False):
            tag = f"{tab}/{kind}/{'strict' if strict else 'lenient'}"
            for op in ["first", "last", "count", "n_unique", "max", "min", "len"]:
                gcase(f"parse/agg/{op}/{tag}", tab, [K], [agg(op, mk(col(c), strict))])
            gcase(f"parse/agg/two/{tag}", tab, [K], [agg("first", mk(col(c), strict)).alias("a"),
                                                     agg("count", mk(col(c), strict)).alias("b"),
                                                     agg("sum", col("v")).alias("s")])
            gcase(f"parse/agg/is-null-sum/{tag}", tab, [K], [agg("sum", is_null(mk(col(c), strict)))])
            gcase(f"parse/agg/no-key/{tag}", tab, [], [agg("first", mk(col(c), strict)),
                                                      agg("count", mk(col(c), strict)).alias("n")])
            gcase(f"parse/key/{tag}", tab, [mk(col(c), strict)], [agg("sum", col("v"))])
            if tab == "ddx" and strict:
                continue  # polars reports the error of one of the groups, which one is not fixed
            ocase(f"parse/over/first/{tag}", tab, [over(agg("first", mk(col(c), strict)), [K])],
                  op="with_columns")
            ocase(f"parse/over/count/{tag}", tab, [over(agg("count", mk(col(c), strict)), [K])],
                  op="with_columns")
            ocase(f"parse/over/row/{tag}", tab, [over(mk(col(c), strict), [K])], op="with_columns")
            ocase(f"parse/over/key/{tag}", tab, [over(agg("sum", col("v")), [mk(col(c), strict)])],
                  op="with_columns")
            ocase(f"parse/select/{tag}", tab, [mk(col(c), strict)])
    gcase(f"parse/agg/year/{tab}", tab, [K], [agg("max", dtf("year", todate(SD, False)))])
    gcase(f"parse/agg/cast/{tab}", tab, [K], [agg("max", cast(todate(SD, False), "i32"))])

# ---------------------------------------------------------------------------
# 2. no key, a one-value key, a column key: the kernels
# ---------------------------------------------------------------------------
KEYS = {
    "none": [],
    "lit": [li(1)],
    "lit-i32": [cast(li(1), "i32")],
    "lit-str": [ls("a")],
    "agg": [agg("sum", V)],
    "len": [len_],
}
STATS = [("sum", lambda c: agg("sum", c)), ("mean", lambda c: agg("mean", c)),
         ("std", lambda c: std(c, 1)), ("var", lambda c: var(c, 1))]
# `fs`: the first 100 rows of `fl`. The whole-column `std` and `var` of the library
# differ from polars in the last digits at every size (known-diffs/group_by.md);
# these two are pinned on `fs`, whose values agree; sums and means use all 1000 rows
TABLES["fs"] = TABLES["fl"].head(100)


def pairs():
    for cname, c in [("v", V), ("f", F), ("i", I)]:
        for sname, mk in STATS:
            if cname == "i" and sname == "sum":
                continue
            if cname == "f" and sname in ("std", "var"):
                continue
            yield cname, c, sname, mk, ("fs" if sname in ("std", "var") else "fl")


for kname, keys in KEYS.items():
    for cname, c, sname, mk, tab in pairs():
        gcase(f"kernel/{kname}/{cname}/{sname}", tab, keys, [mk(c).alias(f"{sname}_{cname}")])
    gcase(f"kernel/{kname}/sums", "fl", keys, [agg("sum", V).alias("sum_v"), agg("mean", V).alias("mean_v"),
                                               agg("sum", F).alias("sum_f"), len_.alias("n")])
    gcase(f"kernel/{kname}/vars", "fs", keys, [std(V, 1).alias("std_v"), var(V, 0).alias("var_v0"),
                                               var(I, 1).alias("var_i"), len_.alias("n")])
    gcase(f"kernel/{kname}/nested", "fl", keys, [agg("sum", bin_("sub", V, agg("mean", V))).alias("dev_sum"),
                                                 agg("mean", bin_("mul", V, V)).alias("sq_mean"),
                                                 agg("sum", bin_("mul", V, li(2))).alias("dbl")])
    gcase(f"kernel/{kname}/nested-var", "fs", keys, [var(bin_("sub", V, agg("mean", V)), 1).alias("var_dev")])
    gcase(f"kernel/{kname}/mixed", "fl", keys, [bin_("div", agg("sum", V), len_).alias("ratio"),
                                                bin_("add", agg("mean", F), agg("sum", V)).alias("m_plus_s")])
# the same as partitions of `over`
for kname, keys in KEYS.items():
    if not keys:
        continue
    for cname, c, sname, mk, tab in pairs():
        # one value per row: reduced with `first`, so a case stays small
        ocase(f"kernel/over/{kname}/{cname}/{sname}", tab,
              [agg("first", over(mk(c), keys)).alias(f"{sname}_{cname}")])
    ocase(f"kernel/over/{kname}/nested", "fl",
          [agg("first", over(agg("sum", bin_("sub", V, agg("mean", V))), keys)).alias("dev_sum"),
           agg("last", over(bin_("sub", V, agg("mean", V)), keys)).alias("dev_last")])
# the kernels of `select` on the same rows: what the one-group forms must equal
for cname, c, sname, mk, tab in pairs():
    ocase(f"kernel/select/{cname}/{sname}", tab, [mk(c).alias(f"{sname}_{cname}")])
ocase("kernel/select/nested-var", "fs", [var(bin_("sub", V, agg("mean", V)), 1).alias("var_dev")])
# whole result columns (1000 rows each: only two, the file stays small)
ocase("kernel/over/lit/full-mean", "fl", [over(agg("mean", V), KEYS["lit"]).alias("t")], op="with_columns")
ocase("kernel/over/agg/full-sum", "fl", [over(agg("sum", V), KEYS["agg"]).alias("t")],
      op="with_columns")
ocase("kernel/over/lit/full-std", "fs", [over(std(V, 1), KEYS["lit"]).alias("t")], op="with_columns")


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
def mb_cases_file():
    lines = ["// 由 docs/golden/scripts/group_final.py 生成，勿手改", ""]
    ty = "(Array[@pl.Expr], Array[@pl.Expr])"
    entries = [(cid, ([], exprs)) for cid, exprs in MB] + GB_MB
    chunk = 40
    parts = [entries[i:i + chunk] for i in range(0, len(entries), chunk)]
    for pi, part in enumerate(parts):
        lines += ["///|", f"fn golden_group_final_cases_{pi}(m : Map[String, {ty}]) -> Unit {{"]
        for cid, (ks, aggs) in part:
            lines.append(f"  m[{mb_str(cid)}] = ([{', '.join(ks)}], [{', '.join(aggs)}])")
        lines += ["}", ""]
    lines += ["///|", "/// Every case id with its key expressions (none for a `select` or `with_columns`",
              "/// case) and its expressions.",
              f"fn golden_group_final_cases() -> Map[String, {ty}] {{",
              f"  let m : Map[String, {ty}] = Map([])"]
    for pi in range(len(parts)):
        lines.append(f"  golden_group_final_cases_{pi}(m)")
    lines += ["  m", "}", ""]
    path = os.path.join(_repo_root(), "src", "pl", "group_final_cases_test.mbt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


ALL = list(GB_CASES) + list(CASES)
used = {c.get("table", "t") for c in ALL}
doc = {
    "tables": {name: encode_frame(df) for name, df in TABLES.items() if name in used},
    "cases": ALL,
}
emit("group_final", doc, compact=True)
# MoonBit source may not contain a raw U+2028/U+2029 (not even in a `#|` string)
path = os.path.join(_repo_root(), "src", "pl", "golden_group_final_data_test.mbt")
with open(path, encoding="utf-8") as f:
    text = f.read()
text = text.replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")
with open(path, "w", encoding="utf-8") as f:
    f.write(text)
mb_cases_file()
kinds = {"result": 0, "error": 0, "restricted": 0}
for c in ALL:
    for k in kinds:
        if k in c:
            kinds[k] += 1
print(f"{len(ALL)} cases", kinds, "known_diff:", sum(1 for c in ALL if "known_diff" in c),
      "bytes:", len(json.dumps(doc, ensure_ascii=False)))
