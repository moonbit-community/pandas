"""Generates the reshaping golden data (docs/golden/reshape.json and
src/pl/golden_reshape_data_test.mbt): `Series.value_counts`,
`Series.unique_counts`, `DataFrame.pivot`, `unpivot`, `transpose` and
`to_dict`.

Run from the repository root (on lab5, with the polars venv):
    ulimit -v 16000000; POLARS_MAX_THREADS=4 \\
      /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/reshape.py

The file is `{"tables": {name: frame}, "cases": [...]}` (compact layout). A
frame is `{"columns": [series, ...]}` (series as in docs/golden/README.md).

Every case has `id`, `polars` (the Python spelling), `op`, `table`, `args` and
one of
  - `result`: a frame (through `to_ours`: UInt32 counts are Int64, ...);
  - `error` + `message`: the variant per the M2 error mapping and the first
    line of polars' message (`polars_error` keeps the polars class when the
    library uses another variant);
  - `restricted: true`: the library is deliberately stricter than polars, only
    `InvalidOperation` is required.
`known_diff` marks a case whose `result` is the library's, not polars' (the
polars shape is in `polars_shape`); see docs/golden/known-diffs/reshape.md.

`args` by `op`:
  - `value_counts`: `column`, `sort`, `normalize`, `name` (or null);
  - `unique_counts`: `column`;
  - `pivot`: `on`, `index` (or null), `values` (or null), `agg` (or null),
    `sort_columns`, `separator` (or null);
  - `unpivot`: `on` (or null), `index`, `variable_name`, `value_name` (or
    null);
  - `transpose`: `include_header`, `header_name` (or null), `column_names` (or
    null);
  - `to_dict`: none (the result frame holds the dict's series in order).

polars does not promise an order for `value_counts` (and not for ties with
`sort=True`) nor for `unique_counts`. The rows of those cases are put in the
order the library promises: first appearance, or biggest count first with ties
in first appearance (the script checks that polars returned the same rows and,
for `sort=True`, a non-increasing count). The error message of a cell with
several rows and no `aggregate_function` carries the size of one offending
cell, and which one polars reports varies, so every such case has one
offending size.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import polars as pl

from emit import emit, encode_series, series_from_spec, to_ours

nan = float("nan")
inf = float("inf")
I64_MIN = -9223372036854775808

ALL = ["bool", "i32", "i64", "f32", "f64", "str", "date", "datetime[μs]", "null"]
SHORT = {"bool": "b", "i32": "i32", "i64": "i64", "f32": "f32", "f64": "f64",
         "str": "s", "date": "d", "datetime[μs]": "dt", "null": "n"}

# ---------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------

T_COLS = {
    "i32": [1, -1, None, 1, -1, None, 7, 7, 1, 0],
    "i64": [10, 20, None, 10, 20, None, 30, 31, 10, I64_MIN],
    "f32": [0.5, nan, None, 0.5, nan, None, -inf, -0.0, 0.5, 0.0],
    "f64": [1.0, nan, None, 1.0, nan, None, -inf, -0.0, 1.0, 0.0],
    "s": ["｡", "\U0001F600", None, "｡", "\U0001F600", None, "a", "", "a", "Z"],
    "b": [True, False, None, True, False, None, True, None, True, False],
    "d": [0, -1, None, 0, -1, None, 19782, 5, 0, 6],
    "dt": [0, -1, None, 0, -1, None, 1709210096123456, 5, 0, 6],
    "n": [None] * 10,
}
T_DT = {"i32": "i32", "i64": "i64", "f32": "f32", "f64": "f64", "s": "str",
        "b": "bool", "d": "date", "dt": "datetime[μs]", "n": "null"}


def frame(spec):
    """`spec`: list of (name, dtype, values)."""
    return pl.DataFrame([series_from_spec(n, d, v) for n, d, v in spec])


TABLES = {}
TABLES["t"] = frame([(c, T_DT[c], v) for c, v in T_COLS.items()])
TABLES["e0"] = TABLES["t"].clear()
# the long-format tables of pivot
TABLES["pl"] = frame([("i", "i64", [1, 1, 2, 2, 3]), ("k", "str", ["a", "b", "a", "b", "a"]),
                      ("v", "i64", [10, 20, 30, 40, 50]), ("w", "f64", [1.5, 2.5, 3.5, 4.5, 5.5])])
# cell (1, a) has two rows
TABLES["pd"] = frame([("i", "i64", [1, 1, 1, 2]), ("k", "str", ["a", "a", "b", "a"]),
                      ("v", "i64", [1, 2, 3, 4]), ("f", "f64", [1.0, 2.0, 3.0, 4.0])])
TABLES["pe"] = TABLES["pl"].clear()
TABLES["pz"] = pl.DataFrame()
TABLES["pkv"] = TABLES["pl"].select("k", "v")
TABLES["pkv0"] = TABLES["pkv"].clear()
TABLES["pkv2"] = frame([("k", "str", ["a", "a", "b"]), ("v", "i64", [1, 2, 3])])
TABLES["pi"] = frame([("i", "i64", [1, 2]), ("k", "str", ["i", "x"]), ("v", "i64", [1, 2]),
                      ("w", "i64", [3, 4]), ("v_a", "i64", [0, 0])])
# index keys: NaN, null, -0.0
TABLES["pn"] = frame([("i", "f64", [1.0, nan, None, -0.0, 0.0, nan, None]),
                      ("k", "str", ["a"] * 7), ("v", "i64", list(range(7)))])
TABLES["pnk"] = frame([("i", "i64", [1] * 7), ("k", "f64", [1.0, nan, None, -0.0, 0.0, nan, None]),
                       ("v", "i64", list(range(7)))])
TABLES["psort"] = frame([("i", "i64", [0, 0, 0, 0, 0]), ("k", "i64", [10, 9, None, 100, 9]),
                         ("v", "i64", [1, 2, 3, 4, 5]), ("w", "i64", [6, 7, 8, 9, 10])])
TABLES["psorts"] = frame([("i", "i64", [0] * 6), ("k", "str", ["b", "B", "a", "10", "9", None]),
                          ("v", "i64", [1, 2, 3, 4, 5, 6])])
TABLES["psortf"] = frame([("i", "i64", list(range(5))), ("k", "f64", [1.5, nan, None, -0.0, 0.0]),
                          ("v", "i64", list(range(5)))])
# several `on` columns
TABLES["pm"] = frame([
    ("i", "i64", [0, 0, 1, 1, 2, 2]),
    ("k1", "i64", [1, 2, 1, 2, 3, 1]),
    ("k2", "str", ["a", "b", "a", "b", "a", "b"]),
    ("k3", "f64", [1.5, nan, -0.0, 1e20, 1e-7, 0.1]),
    ("k4", "date", [19723, 0, 19723, 0, 5, 6]),
    ("k5", "datetime[μs]", [1_500_000, 0, 1_500_000, 123456, 5, 6]),
    ("kb", "bool", [True, False, True, False, True, False]),
    ("ks", "str", ["x" * 50, "y", "x" * 50, "y", "z", "z"]),
    ("v", "i64", [1, 2, 3, 4, 5, 6]),
])
TABLES["pmn"] = frame([
    ("i", "i64", [0, 1, 2, 3]),
    ("k1", "i64", [1, 2, None, 4]),
    ("k2", "str", ["a", None, "c", "d"]),
    ("v", "i64", [1, 2, 3, 4]),
])
TABLES["pmn2"] = frame([
    ("i", "i64", [0, 1, 2]),
    ("k1", "i64", [1, 2, None]),
    ("k2", "str", ["a", None, "c"]),
    ("v", "i64", [1, 2, 3]),
])
TABLES["pdate"] = frame([("i", "date", [19723, None, 19723]), ("k", "str", ["a", "a", "b"]),
                         ("v", "i64", [1, 2, 3])])
TABLES["pnullv"] = frame([("i", "i64", [1, 2]), ("k", "str", ["a", "b"]), ("v", "null", [None, None])])
TABLES["pnullk"] = frame([("i", "i64", [1, 2]), ("k", "null", [None, None]), ("v", "i64", [3, 4])])
TABLES["pbig"] = frame([("i", "i64", [1, 1, 1, 1, 1]), ("k", "str", ["a"] * 5), ("v", "i64", [1, 2, 3, 4, 5])])
TABLES["pdup5"] = frame([("i", "i64", [1, 1, 1, 2, 2, 2]), ("k", "str", ["a", "a", "a", "b", "b", "b"]),
                         ("v", "i64", [1, 2, 3, 4, 5, 6])])

# one value column of each type: 4 values (the third is null), cells
# (1,a) = two rows, (2,b) = one null, (3,a) = one row; (1,b), (2,a), (3,b) empty
V4 = {
    "bool": [True, False, None, True],
    "i32": [1, 2, None, 3],
    "i64": [1, 2, None, 3],
    "f32": [1.5, nan, None, -0.0],
    "f64": [1.5, nan, None, -0.0],
    "str": ["a", "b", None, "c"],
    "date": [19723, 0, None, 5],
    "datetime[μs]": [0, 1_500_000, None, 5],
    "null": [None] * 4,
}
for t in ALL:
    TABLES[f"pv_{SHORT[t]}"] = frame([("i", "i64", [1, 1, 2, 3]), ("k", "str", ["a", "a", "b", "a"]),
                                      ("v", t, V4[t])])
    TABLES[f"pw_{SHORT[t]}"] = frame([("i", "i64", [1, 2, 3, 3]), ("k", "str", ["a", "b", "a", "b"]),
                                      ("v", t, V4[t])])

# index and on keys of each type: two values and a null, repeated
K6 = {
    "bool": [True, False, None, True, False, None],
    "i32": [1, 2, None, 1, 2, None],
    "i64": [1, 2, None, 1, 2, None],
    "f32": [1.5, nan, None, 1.5, nan, None],
    "f64": [1.5, nan, None, 1.5, nan, None],
    "str": ["a", "b", None, "a", "b", None],
    "date": [19723, 0, None, 19723, 0, None],
    "datetime[μs]": [1_500_000, 0, None, 1_500_000, 0, None],
    "null": [None] * 6,
}
for t in ALL:
    TABLES[f"px_{SHORT[t]}"] = frame([("i", t, K6[t]), ("k", "str", ["a", "b", "a", "a", "b", "b"]),
                                      ("v", "i64", [1, 2, 3, 4, 5, 6])])
    TABLES[f"po_{SHORT[t]}"] = frame([("i", "i64", [0, 0, 0, 1, 1, 1]), ("k", t, K6[t]),
                                      ("v", "i64", [1, 2, 3, 4, 5, 6])])

# two columns of two types each, three values per column (for unpivot and
# transpose)
V3 = {
    "bool": [True, None, False],
    "i32": [1, None, -5],
    "i64": [10, 20, None],
    "f32": [1.5, None, 0.5],
    "f64": [2.5, -0.0, None],
    "str": ["x", None, "1"],
    "date": [19723, None, 0],
    "datetime[μs]": [1_500_000, None, 0],
    "null": [None] * 3,
}
for a in ALL:
    for b in ALL:
        TABLES[f"pair_{SHORT[a]}_{SHORT[b]}"] = frame([("a", a, V3[a]), ("b", b, V3[b])])
TRIPLES = {
    "tri_i32_i64_f32": ["i32", "i64", "f32"],
    "tri_date_i32_f32": ["date", "i32", "f32"],
    "tri_date_dt_i64": ["date", "datetime[μs]", "i64"],
    "tri_bool_i32_str": ["bool", "i32", "str"],
    "tri_f32_i32_f64": ["f32", "i32", "f64"],
    "tri_null_i32_null": ["null", "i32", "null"],
    "tri_str_null_date": ["str", "null", "date"],
    "tri_f32_f32_i32": ["f32", "f32", "i32"],
}
for name, ts in TRIPLES.items():
    TABLES[name] = frame([(f"c{j}", t, V3[t]) for j, t in enumerate(ts)])
# unpivot / transpose of other shapes
TABLES["abc"] = frame([("a", "i64", [1, 2, 3]), ("b", "i64", [4, 5, 6]), ("c", "i64", [7, 8, 9])])
TABLES["abc0"] = TABLES["abc"].clear()
TABLES["mix"] = frame([("a", "i64", [1, 2]), ("b", "f64", [1.5, None]), ("c", "bool", [True, False])])
TABLES["idx_unp"] = frame([("id", "str", ["p", "q"]), ("x", "i64", [1, 2]), ("y", "i64", [3, 4])])
TABLES["wide"] = frame([("a", "i32", [1]), ("b", "i32", [2]), ("c", "i32", [3]), ("d", "i32", [4])])
TABLES["one"] = frame([("a", "i64", [1, 2, 3])])
TABLES["name_row"] = frame([("n", "str", ["p", "q"]), ("a", "i64", [1, 2])])
TABLES["unp_i"] = frame([("i", "i64", [1, 2]), ("x", "i64", [3, 4]), ("y", "i64", [5, 6]), ("z", "i64", [7, 8])])
TABLES["unp_value"] = frame([("id", "i64", [1]), ("value", "i64", [2])])
TABLES["unp_variable"] = frame([("id", "i64", [1]), ("variable", "i64", [2])])
TABLES["unp_both"] = frame([("variable", "i64", [1]), ("value", "i64", [2])])
TABLES["unp_i0"] = TABLES["unp_i"].clear()
TABLES["unp_value_a"] = frame([("id", "i64", [1]), ("value", "i64", [2]), ("a", "i64", [3])])

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
    "ValueError": "InvalidOperation",
}


def run(thunk):
    try:
        return thunk(), None
    except BaseException as e:  # noqa: BLE001  (polars panics are BaseExceptions)
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        name = type(e).__name__
        return None, (name, VARIANTS.get(name, name), str(e).split("\n")[0])


def encode_frame(df):
    return {"columns": [encode_series(to_ours(s)[0]) for s in df.get_columns()]}


def schema_text(df):
    return [[s.name, str(s.dtype)] for s in df.get_columns()]


CASES = []
IDS = set()


def case(cid, op, table, args, polars_text, thunk, restricted=False, known_diff=None,
         note=None, post=None, ours=None):
    """Adds a case. `post` rewrites a successful polars result (the order of
    `value_counts`); `ours` is the library's result when it deliberately
    differs (with `known_diff`)."""
    assert cid not in IDS, cid
    res, err = run(thunk)
    rec = {"id": cid, "op": op, "table": table, "args": args, "polars": polars_text}
    if note:
        rec["note"] = note
    if restricted:
        rec["restricted"] = True
        if res is not None:
            rec["polars_schema"] = schema_text(res)
    elif err is not None:
        cls, var, msg = err
        if cls == "PanicException":
            print("PANIC (skipped)", cid, msg)
            return
        if cls == "ValueError":
            rec["polars_error"] = cls
        rec["error"] = var
        rec["message"] = msg
    else:
        if post is not None:
            res = post(res)
        if known_diff:
            rec["known_diff"] = known_diff
            rec["polars_shape"] = list(res.shape)
            res = ours
        rec["result"] = encode_frame(res)
        if not known_diff and any(str(a) != str(to_ours(s)[0].dtype)
                                  for a, s in zip(res.dtypes, res.get_columns())):
            rec["polars_schema"] = schema_text(res)
    IDS.add(cid)
    CASES.append(rec)


def py(v):
    """Python spelling of a JSON-like value."""
    return repr(v)


# ---------------------------------------------------------------------------
# value_counts, unique_counts
# ---------------------------------------------------------------------------

def vc_key(v):
    return "0.0" if v == "-0.0" else v


def vc_order(s, sort, count_name):
    """`post` for value_counts: rows in first appearance (or count desc)."""
    enc = encode_series(s)["values"]
    first = {}
    for i, v in enumerate(enc):
        first.setdefault(vc_key(v), i)

    def post(res):
        vals = encode_series(to_ours(res.get_column(s.name))[0])["values"]
        cnts = res.get_column(res.columns[1]).to_list()
        assert sorted(repr(vc_key(v)) for v in vals) == sorted(repr(k) for k in first), "different groups"
        if sort:
            assert all(cnts[i] >= cnts[i + 1] for i in range(len(cnts) - 1)), "counts not sorted"
            order = sorted(range(res.height), key=lambda r: (-cnts[r], first[vc_key(vals[r])]))
        else:
            order = sorted(range(res.height), key=lambda r: first[vc_key(vals[r])])
        return res[order]

    return post


def c_vc(cid, table, col, sort=False, normalize=False, name=None, note=None, **kw):
    s = TABLES[table].get_column(col)
    cname = name if name is not None else ("proportion" if normalize else "count")
    parts = []
    if sort:
        parts.append("sort=True")
    if normalize:
        parts.append("normalize=True")
    if name is not None:
        parts.append(f"name={py(name)}")
    text = f'{table}[{py(col)}].value_counts({", ".join(parts)})'
    kwargs = {}
    if sort:
        kwargs["sort"] = True
    if normalize:
        kwargs["normalize"] = True
    if name is not None:
        kwargs["name"] = name
    args = {"column": col, "sort": sort, "normalize": normalize, "name": name}
    case(cid, "value_counts", table, args, text, lambda: s.value_counts(**kwargs),
         post=vc_order(s, sort, cname),
         note=note or "rows put in first-appearance order (polars gives no order)", **kw)


for c in T_COLS:
    c_vc(f"value_counts/{c}", "t", c)
    c_vc(f"value_counts/{c}/sort", "t", c, sort=True)
    c_vc(f"value_counts/{c}/normalize", "t", c, normalize=True)
    c_vc(f"value_counts/{c}/sort-normalize", "t", c, sort=True, normalize=True)
    c_vc(f"value_counts/{c}/e0", "e0", c)
    c_vc(f"value_counts/{c}/e0-normalize", "e0", c, normalize=True)
    c_vc(f"value_counts/{c}/name", "t", c, name="n")
c_vc("value_counts/i64/name-same", "t", "i64", name="i64")
c_vc("value_counts/count/name-count", "t", "i64", name="count")  # fine: not the series name
c_vc("value_counts/i64/normalize-name", "t", "i64", normalize=True, name="share")
c_vc("value_counts/i64/normalize-name-same", "t", "i64", normalize=True, name="i64")
c_vc("value_counts/i64/sort-name", "t", "i64", sort=True, name="n")
c_vc("value_counts/i64/name-empty", "t", "i64", name="")
TABLES["vc_count"] = frame([("count", "i64", [1, 1, 2]), ("proportion", "i64", [5, 5, 5])])
c_vc("value_counts/series-count", "vc_count", "count")
c_vc("value_counts/series-count/name", "vc_count", "count", name="c")
c_vc("value_counts/series-proportion/normalize", "vc_count", "proportion", normalize=True)
c_vc("value_counts/series-proportion/plain", "vc_count", "proportion")
# ties: first appearance decides
TABLES["vc_ties"] = frame([("s", "str", ["b", "a", "c", "a", "c", "b", "d", "c", "e", "e"]),
                           ("x", "i64", [3, 1, 2, 1, 3, 2, 3, 3, 4, 4])])
c_vc("value_counts/ties/s-sort", "vc_ties", "s", sort=True)
c_vc("value_counts/ties/x-sort", "vc_ties", "x", sort=True)
c_vc("value_counts/ties/s-sort-normalize", "vc_ties", "s", sort=True, normalize=True)
# a normalize that is not a nice fraction
TABLES["vc_thirds"] = frame([("x", "i64", [1, 2, 3, 3, 3, 3, 3])])
c_vc("value_counts/thirds/normalize", "vc_thirds", "x", normalize=True)
TABLES["vc_null_only"] = frame([("x", "i64", [None, None])])
c_vc("value_counts/null-only/normalize", "vc_null_only", "x", normalize=True)
c_vc("value_counts/null-only", "vc_null_only", "x")
TABLES["vc_one"] = frame([("x", "str", ["only"])])
c_vc("value_counts/one", "vc_one", "x", normalize=True)


def c_uc(cid, table, col):
    s = TABLES[table].get_column(col)
    enc = encode_series(s)["values"]
    first = {}
    for i, v in enumerate(enc):
        first.setdefault(vc_key(v), i)

    def post(res):
        # a one-column frame holding the series
        r = res.get_column(s.name)
        # polars gives no order: sort by the first appearance of the group the
        # count belongs to, found through value_counts of the same series
        vc = s.value_counts(name="__n")
        vals = encode_series(to_ours(vc.get_column(s.name))[0])["values"]
        cnt = vc.get_column("__n").to_list()
        order = sorted(range(vc.height), key=lambda g: first[vc_key(vals[g])])
        out = pl.Series(s.name, [cnt[g] for g in order], dtype=pl.UInt32)
        assert sorted(out.to_list()) == sorted(r.to_list())
        return out.to_frame()

    case(cid, "unique_counts", table, {"column": col},
         f"{table}[{py(col)}].unique_counts()",
         lambda: s.unique_counts().to_frame(), post=post,
         note="counts put in first-appearance order (polars gives no order)")


for c in T_COLS:
    c_uc(f"unique_counts/{c}", "t", c)
    c_uc(f"unique_counts/{c}/e0", "e0", c)
c_uc("unique_counts/ties", "vc_ties", "s")
c_uc("unique_counts/null-only", "vc_null_only", "x")
c_uc("unique_counts/one", "vc_one", "x")

# ---------------------------------------------------------------------------
# pivot
# ---------------------------------------------------------------------------

AGGS = ["first", "last", "sum", "min", "max", "mean", "median", "len"]


def c_pivot(cid, table, on, index=None, values=None, agg=None, sort_columns=False,
            separator=None, **kw):
    df = TABLES[table]
    kwargs = {"on": on}
    parts = [f"on={py(on)}"]
    if index is not None:
        kwargs["index"] = index
        parts.append(f"index={py(index)}")
    if values is not None:
        kwargs["values"] = values
        parts.append(f"values={py(values)}")
    if agg is not None:
        kwargs["aggregate_function"] = agg
        parts.append(f"aggregate_function={py(agg)}")
    if sort_columns:
        kwargs["sort_columns"] = True
        parts.append("sort_columns=True")
    if separator is not None:
        kwargs["separator"] = separator
        parts.append(f"separator={py(separator)}")
    args = {"on": on, "index": index, "values": values, "agg": agg,
            "sort_columns": sort_columns, "separator": separator}
    case(cid, "pivot", table, args, f'{table}.pivot({", ".join(parts)})',
         lambda: df.pivot(**kwargs), **kw)


# basics
c_pivot("pivot/basic", "pl", ["k"], ["i"], ["v"])
c_pivot("pivot/no-values", "pl", ["k"], ["i"])
c_pivot("pivot/no-index", "pl", ["k"], None, ["v"])
c_pivot("pivot/no-index/two-values", "pl", ["k"], None, ["v", "w"])
c_pivot("pivot/neither", "pl", ["k"])
c_pivot("pivot/multi-values", "pl", ["k"], ["i"], ["v", "w"])
c_pivot("pivot/multi-values/sep", "pl", ["k"], ["i"], ["v", "w"], separator="|")
c_pivot("pivot/multi-values/sep-empty", "pl", ["k"], ["i"], ["v", "w"], separator="")
c_pivot("pivot/single-value/sep-ignored", "pl", ["k"], ["i"], ["v"], separator="--")
c_pivot("pivot/sort-columns", "pl", ["k"], ["i"], ["v"], sort_columns=True)
c_pivot("pivot/sort-columns/multi-values", "pl", ["k"], ["i"], ["v", "w"], sort_columns=True)
c_pivot("pivot/values-in-index", "pl", ["k"], ["i"], ["i"])
c_pivot("pivot/values-is-on", "pl", ["k"], ["i"], ["k"])
c_pivot("pivot/values-and-on", "pl", ["k"], ["i"], ["v", "k"])
c_pivot("pivot/on-in-index", "pl", ["k"], ["k"], ["v"], agg="first")
c_pivot("pivot/on-in-index/dup", "pd", ["k"], ["k"], ["v"])
c_pivot("pivot/on-is-index-int", "pl", ["i"], ["i"], ["v"], agg="sum")
c_pivot("pivot/on-is-index-unique", "pl", ["i"], ["i", "k"], ["v"])
c_pivot("pivot/multi-index", "pl", ["k"], ["i", "w"], ["v"])
c_pivot("pivot/index-repeated", "pl", ["k"], ["i", "i"], ["v"])
c_pivot("pivot/values-repeated", "pl", ["k"], ["i"], ["v", "v"])
c_pivot("pivot/index-empty-values", "pl", ["k"], [], ["v"], agg="sum")
c_pivot("pivot/index-empty-values-w", "pl", ["k"], [], ["w"], agg="sum")
c_pivot("pivot/index-empty-no-values", "pl", ["k"], [], None, agg="sum")
c_pivot("pivot/index-empty-dup", "pd", ["k"], [], ["v"])
c_pivot("pivot/index-empty/e", "pe", ["k"], [], ["w"], agg="sum")
c_pivot("pivot/no-index-kv/dup", "pkv2", ["k"], None, ["v"])
c_pivot("pivot/no-index-kv/sum", "pkv", ["k"], None, ["v"], agg="sum")
c_pivot("pivot/no-index-kv/e", "pkv0", ["k"], None, ["v"], agg="sum")
c_pivot("pivot/no-index-kv/first", "pkv", ["k"], None, ["v"], agg="first")
c_pivot("pivot/one-on-value", "pl", ["k"], ["i"], ["v"], agg="sum")
c_pivot("pivot/idx-on-value-clash", "pi", ["k"], ["i"], ["v"])
c_pivot("pivot/idx-on-value-clash/multi", "pi", ["k"], ["i"], ["v", "w"])
c_pivot("pivot/prefix-not-in-values", "pi", ["k"], ["i"], ["v", "w"])
c_pivot("pivot/no-index-derived-skips-prefix", "pi", ["k"], None, ["v", "w"])
# the aggregations
for a in AGGS:
    c_pivot(f"pivot/dup/{a}", "pd", ["k"], ["i"], ["v"], agg=a)
    c_pivot(f"pivot/dup/{a}/f", "pd", ["k"], ["i"], ["f"], agg=a)
    c_pivot(f"pivot/dup/{a}/two", "pd", ["k"], ["i"], ["v", "f"], agg=a)
c_pivot("pivot/dup/none", "pd", ["k"], ["i"], ["v"])
c_pivot("pivot/dup/none/f", "pd", ["k"], ["i"], ["f"])
c_pivot("pivot/dup5/none", "pdup5", ["k"], ["i"], ["v"])
c_pivot("pivot/dup5/sum", "pdup5", ["k"], ["i"], ["v"], agg="sum")
c_pivot("pivot/big-cell/none", "pbig", ["k"], ["i"], ["v"])
c_pivot("pivot/big-cell/sum", "pbig", ["k"], ["i"], ["v"], agg="sum")
c_pivot("pivot/count-is-len", "pd", ["k"], ["i"], ["v"], agg="len")
# every value type under every aggregation
for t in ALL:
    s = SHORT[t]
    c_pivot(f"pivot/{s}/none", f"pv_{s}", ["k"], ["i"], ["v"])
    c_pivot(f"pivot/{s}/single/none", f"pw_{s}", ["k"], ["i"], ["v"])
    for a in AGGS:
        # polars sums a Date or Datetime column; the library refuses (as group_by)
        r = (a == "sum" and t in ("date", "datetime[μs]"))
        c_pivot(f"pivot/{s}/{a}", f"pv_{s}", ["k"], ["i"], ["v"], agg=a, restricted=r)
        c_pivot(f"pivot/{s}/single/{a}", f"pw_{s}", ["k"], ["i"], ["v"], agg=a, restricted=r)
# every key type as index and as on
for t in ALL:
    s = SHORT[t]
    c_pivot(f"pivot/index-{s}", f"px_{s}", ["k"], ["i"], ["v"], agg="sum")
    c_pivot(f"pivot/on-{s}", f"po_{s}", ["k"], ["i"], ["v"], agg="sum")
    c_pivot(f"pivot/on-{s}/sort", f"po_{s}", ["k"], ["i"], ["v"], agg="sum", sort_columns=True)
    c_pivot(f"pivot/on-{s}/none", f"po_{s}", ["k"], ["i"], ["v"])
c_pivot("pivot/index-date-null", "pdate", ["k"], ["i"], ["v"])
c_pivot("pivot/null-values", "pnullv", ["k"], ["i"], ["v"])
c_pivot("pivot/null-on", "pnullk", ["k"], ["i"], ["v"])
c_pivot("pivot/null-values/sum", "pnullv", ["k"], ["i"], ["v"], agg="sum")
c_pivot("pivot/null-values/len", "pnullv", ["k"], ["i"], ["v"], agg="len")
# NaN, null, -0.0 keys
c_pivot("pivot/nan-index", "pn", ["k"], ["i"], ["v"], agg="sum")
c_pivot("pivot/nan-on", "pnk", ["k"], ["i"], ["v"], agg="sum")
c_pivot("pivot/nan-on/first", "pnk", ["k"], ["i"], ["v"], agg="first")
c_pivot("pivot/nan-on/dup", "pnk", ["k"], ["i"], ["v"])
c_pivot("pivot/nan-on/sort", "pnk", ["k"], ["i"], ["v"], agg="sum", sort_columns=True)
c_pivot("pivot/nan-index/dup", "pn", ["k"], ["i"], ["v"])
# sort_columns
c_pivot("pivot/sort/ints", "psort", ["k"], ["i"], ["v"], agg="sum", sort_columns=True)
c_pivot("pivot/sort/ints-unsorted", "psort", ["k"], ["i"], ["v"], agg="sum")
c_pivot("pivot/sort/ints-two-values", "psort", ["k"], ["i"], ["v", "w"], agg="sum", sort_columns=True)
c_pivot("pivot/sort/strings", "psorts", ["k"], ["i"], ["v"], sort_columns=True)
c_pivot("pivot/sort/strings-unsorted", "psorts", ["k"], ["i"], ["v"])
c_pivot("pivot/sort/floats", "psortf", ["k"], ["i"], ["v"], sort_columns=True)
# several `on` columns
MULTI_ON = [["k1", "k2"], ["k2", "k1"], ["k1", "k3"], ["k4", "k5"], ["kb", "k2"], ["k3", "kb"],
            ["ks", "k1"], ["k1", "k2", "k3", "k4", "k5", "kb"], ["k5", "k4"]]
for on in MULTI_ON:
    nm = "+".join(on)
    c_pivot(f"pivot/multi-on/{nm}", "pm", on, ["i"], ["v"], agg="sum")
    c_pivot(f"pivot/multi-on/{nm}/sort", "pm", on, ["i"], ["v"], agg="sum", sort_columns=True)
c_pivot("pivot/multi-on/two-values", "pm", ["k1", "k2"], ["i"], ["v", "k3"], agg="first")
c_pivot("pivot/multi-on/two-values/sep", "pm", ["k1", "k2"], ["i"], ["v", "k3"], agg="first", separator="::")
c_pivot("pivot/multi-on/no-values", "pm", ["k1", "k2"], ["i"], None, agg="first")
c_pivot("pivot/multi-on/null-component", "pmn", ["k1", "k2"], ["i"], ["v"])
c_pivot("pivot/multi-on/null-component/sort", "pmn", ["k1", "k2"], ["i"], ["v"], sort_columns=True)
c_pivot("pivot/multi-on/one-null", "pmn2", ["k1", "k2"], ["i"], ["v"])
c_pivot("pivot/multi-on/one-null/sort", "pmn2", ["k1", "k2"], ["i"], ["v"], sort_columns=True)
c_pivot("pivot/multi-on/dup", "pm", ["k1", "k1"], ["i"], ["v"], agg="sum")
c_pivot("pivot/multi-on/dup-missing-index", "pm", ["k1", "k1"], ["yy"], ["v"], agg="sum")
c_pivot("pivot/multi-on/long-string", "pm", ["ks"], ["i"], ["v"], agg="sum")
# empty and degenerate frames
c_pivot("pivot/e", "pe", ["k"], ["i"], ["v"])
c_pivot("pivot/e/sum", "pe", ["k"], ["i"], ["v"], agg="sum")
c_pivot("pivot/e/two-index", "pe", ["k"], ["i", "w"], ["v"])
c_pivot("pivot/e/no-index", "pe", ["k"], None, ["v"])
c_pivot("pivot/e/multi-values", "pe", ["k"], ["i"], ["v", "w"])
c_pivot("pivot/z", "pz", ["k"], ["i"], ["v"])
# errors
c_pivot("pivot/err/missing-on", "pl", ["zz"], ["i"], ["v"])
c_pivot("pivot/err/missing-index", "pl", ["k"], ["yy"], ["v"])
c_pivot("pivot/err/missing-values", "pl", ["k"], ["i"], ["zz"])
c_pivot("pivot/err/missing-on-and-index", "pl", ["zz"], ["yy"], ["v"])
c_pivot("pivot/err/missing-index-and-values", "pl", ["k"], ["yy"], ["zz"])
c_pivot("pivot/err/missing-on-and-values", "pl", ["zz"], None, ["yy"])
c_pivot("pivot/err/missing-on-neither", "pl", ["zz"])
c_pivot("pivot/err/second-on-missing", "pl", ["k", "zz"], ["i"], ["v"])
c_pivot("pivot/err/on-empty", "pl", [], ["i"], ["v"])
c_pivot("pivot/err/values-empty", "pl", ["k"], ["i"], [])
c_pivot("pivot/err/values-derived-empty", "pl", ["k", "v", "w"], ["i"])
c_pivot("pivot/err/all-index", "pl", ["k"], ["i", "v", "w"])
c_pivot("pivot/err/on-repeated", "pl", ["k", "k"], ["i"], ["v"])
c_pivot("pivot/err/on-repeated-multi", "pm", ["k1", "k2", "k1"], ["i"], ["v"], agg="sum")
c_pivot("pivot/err/sum-of-text", "pv_s", ["k"], ["i"], ["v"], agg="sum")
c_pivot("pivot/err/mean-of-text", "pv_s", ["k"], ["i"], ["v"], agg="mean")
c_pivot("pivot/err/zero-columns", "pz", ["k"])

# ---------------------------------------------------------------------------
# unpivot
# ---------------------------------------------------------------------------


def c_unpivot(cid, table, on=None, index=(), variable_name=None, value_name=None, **kw):
    df = TABLES[table]
    index = list(index or [])
    kwargs = {}
    parts = []
    if on is not None:
        kwargs["on"] = on
        parts.append(f"on={py(on)}")
    if index:
        kwargs["index"] = index
        parts.append(f"index={py(index)}")
    if variable_name is not None:
        kwargs["variable_name"] = variable_name
        parts.append(f"variable_name={py(variable_name)}")
    if value_name is not None:
        kwargs["value_name"] = value_name
        parts.append(f"value_name={py(value_name)}")
    args = {"on": on, "index": index, "variable_name": variable_name, "value_name": value_name}
    case(cid, "unpivot", table, args, f'{table}.unpivot({", ".join(parts)})',
         lambda: df.unpivot(**kwargs), **kw)


c_unpivot("unpivot/basic", "pl", ["v", "w"], ["i", "k"])
c_unpivot("unpivot/no-on", "pl", None, ["i", "k"])
c_unpivot("unpivot/no-on-no-index", "pl")
c_unpivot("unpivot/on-only", "pl", ["v"])
c_unpivot("unpivot/names", "pl", ["v", "w"], ["i"], "var", "val")
c_unpivot("unpivot/variable-name-only", "pl", ["v"], ["i"], variable_name="name")
c_unpivot("unpivot/value-name-only", "pl", ["v"], ["i"], value_name="number")
c_unpivot("unpivot/names-empty-strings", "pl", ["v"], ["i"], "", "x")
c_unpivot("unpivot/mixed", "idx_unp", None, ["id"])
c_unpivot("unpivot/mixed-all", "mix")
c_unpivot("unpivot/index-only-no-on", "idx_unp", None, ["id", "x", "y"])
c_unpivot("unpivot/on-empty", "pl", [], ["i"])
c_unpivot("unpivot/on-empty-no-index", "pl", [])
c_unpivot("unpivot/on-repeated", "pl", ["v", "v"], ["i"])
c_unpivot("unpivot/index-repeated", "pl", ["v"], ["i", "i"])
c_unpivot("unpivot/on-in-index", "pl", ["v", "i"], ["i"])
c_unpivot("unpivot/one-on", "pl", ["w"], ["i", "k", "v"])
c_unpivot("unpivot/e0", "pe", ["v", "w"], ["i"])
c_unpivot("unpivot/e0/no-on", "pe", None, ["i"])
c_unpivot("unpivot/e0/all", "pe")
c_unpivot("unpivot/z", "pz")
c_unpivot("unpivot/z/index", "pz", None, ["i"])
c_unpivot("unpivot/t/all", "t")
c_unpivot("unpivot/t/numeric", "t", ["i32", "i64", "f32", "f64", "b"])
c_unpivot("unpivot/t/temporal", "t", ["d", "dt"])
c_unpivot("unpivot/t/index-s", "t", ["i32", "i64"], ["s"])
c_unpivot("unpivot/t/bool-str", "t", ["b", "s"])
c_unpivot("unpivot/t/null-int", "t", ["n", "i32"])
c_unpivot("unpivot/t/only-null", "t", ["n"], ["i32"])
c_unpivot("unpivot/t/date-int", "t", ["d", "i64"])
c_unpivot("unpivot/t/date-f32", "t", ["d", "f32"])
c_unpivot("unpivot/t/dt-f32", "t", ["dt", "f32"])
c_unpivot("unpivot/t/dt-str", "t", ["dt", "s"])
c_unpivot("unpivot/t/dt-i32", "t", ["dt", "i32"])
c_unpivot("unpivot/t/i32-f32", "t", ["i32", "f32"])
c_unpivot("unpivot/t/f32-f64", "t", ["f32", "f64"])
for a in ALL:
    for b in ALL:
        c_unpivot(f"unpivot/pair/{SHORT[a]}-{SHORT[b]}", f"pair_{SHORT[a]}_{SHORT[b]}")
for name in TRIPLES:
    c_unpivot(f"unpivot/{name}", name)
c_unpivot("unpivot/err/missing-on", "pl", ["zz"], ["i"])
c_unpivot("unpivot/err/missing-index", "pl", ["v"], ["yy"])
c_unpivot("unpivot/err/missing-on-and-index", "pl", ["zz"], ["yy"])
c_unpivot("unpivot/err/missing-index-no-on", "pl", None, ["yy"])
c_unpivot("unpivot/err/missing-second-on", "pl", ["v", "zz"], ["i"])
c_unpivot("unpivot/err/variable-in-index", "pl", ["v", "w"], ["i", "k"], variable_name="k")
c_unpivot("unpivot/err/value-in-index", "pl", ["v", "w"], ["i", "k"], value_name="i")
c_unpivot("unpivot/err/names-equal", "pl", ["v", "w"], None, "x", "x")
c_unpivot("unpivot/err/variable-in-index-no-on", "pl", None, ["i", "k"], variable_name="i")
c_unpivot("unpivot/err/value-named-variable", "pl", ["v"], ["i"], "variable", "variable")
# a name that is any column of the frame clashes, kept or not (variable name first)
c_unpivot("unpivot/err/variable-is-on", "unp_i", ["x"], ["i"], variable_name="x")
c_unpivot("unpivot/err/value-is-on", "unp_i", ["x"], ["i"], value_name="x")
c_unpivot("unpivot/err/variable-is-second-on", "unp_i", ["x", "y"], ["i"], variable_name="y")
c_unpivot("unpivot/err/variable-is-unselected", "unp_i", ["x"], None, variable_name="i")
c_unpivot("unpivot/err/value-is-unselected", "unp_i", ["x"], ["z"], value_name="i")
c_unpivot("unpivot/err/value-is-index", "unp_i", ["x"], ["i"], value_name="i")
c_unpivot("unpivot/err/both-clash-variable-first", "unp_i", ["x"], ["i"], variable_name="y", value_name="z")
c_unpivot("unpivot/err/both-clash-variable-first-2", "unp_i", ["x"], ["i"], variable_name="z", value_name="y")
c_unpivot("unpivot/err/variable-on-value-index", "unp_i", ["x"], ["i"], variable_name="x", value_name="i")
c_unpivot("unpivot/err/variable-index-value-on", "unp_i", ["x"], ["i"], variable_name="i", value_name="x")
c_unpivot("unpivot/err/equal-names-no-clash", "unp_i", ["x"], ["i"], variable_name="q", value_name="q")
c_unpivot("unpivot/err/equal-names-clash", "unp_i", ["x"], ["i"], variable_name="x", value_name="x")
c_unpivot("unpivot/err/default-value", "unp_value", None, ["id"])
c_unpivot("unpivot/err/default-variable", "unp_variable", None, ["id"])
c_unpivot("unpivot/err/default-both", "unp_both")
c_unpivot("unpivot/err/default-both-on-value", "unp_both", ["value"])
c_unpivot("unpivot/err/default-value-unselected", "unp_value_a", ["a"], ["id"])
c_unpivot("unpivot/err/default-value-not-in-output", "unp_value_a", ["a"])
c_unpivot("unpivot/err/clash-empty-on", "unp_i", [], ["i"], variable_name="x")
c_unpivot("unpivot/err/clash-0-rows", "unp_i0", ["x"], ["i"], variable_name="y")
c_unpivot("unpivot/ok/variable-not-a-column", "unp_value_a", ["a"], ["id"], variable_name="var", value_name="val")
c_unpivot("unpivot/ok/default-value-renamed", "unp_value", None, ["id"], value_name="v")

# ---------------------------------------------------------------------------
# transpose
# ---------------------------------------------------------------------------


def c_transpose(cid, table, include_header=False, header_name=None, column_names=None, **kw):
    df = TABLES[table]
    # polars keeps one row per old column when no row is left (shape (n, 0)); a
    # frame of this library without columns has no rows
    probe, _ = run(lambda: df.transpose(include_header=include_header,
                                        **({"column_names": column_names} if column_names is not None else {})))
    if probe is not None and probe.width == 0 and probe.height > 0:
        kw["known_diff"] = "no-rows-keeps-height"
        kw["ours"] = pl.DataFrame()
    kwargs = {}
    parts = []
    if include_header:
        kwargs["include_header"] = True
        parts.append("include_header=True")
    if header_name is not None:
        kwargs["header_name"] = header_name
        parts.append(f"header_name={py(header_name)}")
    if column_names is not None:
        kwargs["column_names"] = column_names
        parts.append(f"column_names={py(column_names)}")
    args = {"include_header": include_header, "header_name": header_name,
            "column_names": column_names}
    case(cid, "transpose", table, args, f'{table}.transpose({", ".join(parts)})',
         lambda: df.transpose(**kwargs), **kw)


c_transpose("transpose/basic", "abc")
c_transpose("transpose/header", "abc", True)
c_transpose("transpose/header-name", "abc", True, "h")
c_transpose("transpose/header-name-no-header", "abc", False, "h")
c_transpose("transpose/column-names", "abc", column_names=["x", "y", "z"])
c_transpose("transpose/column-names-header", "abc", True, column_names=["x", "y", "z"])
c_transpose("transpose/column-names-empty-name", "abc", column_names=["", "y", "z"])
c_transpose("transpose/mixed", "mix", True)
c_transpose("transpose/mixed-no-header", "mix")
c_transpose("transpose/name-row", "name_row", True)
c_transpose("transpose/one-column", "one")
c_transpose("transpose/one-column-header", "one", True)
c_transpose("transpose/wide", "wide", True)
c_transpose("transpose/t/all", "t", True)
c_transpose("transpose/e0/header", "abc0", True)
c_transpose("transpose/e0/column-names", "abc0", column_names=[])
c_transpose("transpose/e0/column-names-header", "abc0", True, column_names=[])
c_transpose("transpose/z", "pz")
c_transpose("transpose/z/header", "pz", True)
c_transpose("transpose/z/header-name", "pz", True, "h")
c_transpose("transpose/z/column-names-empty", "pz", column_names=[])
for a in ALL:
    for b in ALL:
        c_transpose(f"transpose/pair/{SHORT[a]}-{SHORT[b]}", f"pair_{SHORT[a]}_{SHORT[b]}", True)
for name in TRIPLES:
    c_transpose(f"transpose/{name}", name, True)
c_transpose("transpose/err/names-few", "abc", column_names=["x", "y"])
c_transpose("transpose/err/names-many", "abc", column_names=["x", "y", "z", "w"])
c_transpose("transpose/err/names-dup", "abc", column_names=["x", "x", "z"])
c_transpose("transpose/err/header-clash", "abc", True, column_names=["column", "y", "z"])
c_transpose("transpose/err/header-clash-default", "name_row", True, "column_0")
c_transpose("transpose/err/header-clash-custom", "abc", True, "x", column_names=["x", "y", "z"])
c_transpose("transpose/err/z-names", "pz", column_names=["a"])
c_transpose("transpose/err/names-few-header", "abc", True, column_names=["x"])
c_transpose("transpose/err/names-dup-header", "abc", True, column_names=["x", "x", "z"])
c_transpose("transpose/err/e0-names", "abc0", column_names=["a"])

# ---------------------------------------------------------------------------
# to_dict
# ---------------------------------------------------------------------------


def c_to_dict(cid, table):
    df = TABLES[table]

    def thunk():
        d = df.to_dict()
        assert list(d) == df.columns
        return pl.DataFrame(list(d.values()))

    case(cid, "to_dict", table, {}, f"{table}.to_dict()", thunk,
         note="the result frame holds the series of the dict, in order")


c_to_dict("to_dict/t", "t")
c_to_dict("to_dict/pl", "pl")
c_to_dict("to_dict/e0", "e0")
c_to_dict("to_dict/z", "pz")
c_to_dict("to_dict/one", "one")

doc = {"tables": {k: encode_frame(v) for k, v in sorted(TABLES.items())}, "cases": CASES}
emit("reshape", doc, compact=True)
print(len(CASES), "cases", len(TABLES), "tables")
