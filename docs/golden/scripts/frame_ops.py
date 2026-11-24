"""Generates the DataFrame-operation golden data (docs/golden/frame_ops.json,
src/pl/golden_frame_ops_data_test.mbt) and the MoonBit call of every case
(src/pl/frame_ops_golden_cases_test.mbt).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/frame_ops.py

The file is `{"tables": {name: frame}, "cases": [...]}` (compact layout). A
frame is `{"columns": [series, ...]}` (series as in docs/golden/README.md).
Tables: `t` (nine columns i32, i64, f32, f64, s, b, d, dt, n; ten rows with
nulls, NaN, -0.0, duplicate rows and the Review Focus strings), `p` (no
nulls), `e0` (the schema of `t`, no rows) and `z0` (no columns).

Every case has `id`, `polars` (the Python spelling), `table`, `op` and one of
  - `result`: a frame (through `to_ours`);
  - `rows`: the result is `table.gather(rows)` (filter, sort, unique and
    drop_nulls only reorder or drop rows; this keeps the file small);
  - `error` + `message`: the variant per the M2 error mapping and the first
    line of polars' message (`polars_error` keeps the polars class when the
    library uses another variant);
  - `restricted: true`: the library is deliberately stricter than polars,
    only `InvalidOperation` is required.
`unordered: true` marks a `unique(maintain_order=False)` case: polars does not
promise an order, so the rows are compared as a set.
`known_diff` marks a case whose `result` is the library's, not polars'; the
polars result is in `polars_schema` or `polars_shape` (see
docs/golden/known-diffs/frame_ops.md).

How the library's arguments are spelled in Python: `descending=[]` is
`descending=False`, a one-element list is that bool; a list of the expanded
width is passed as it is (the `by` list is written out column by column, since
polars checks the length against the unexpanded list). The fill value of
`fill_null` is a Python scalar for the literals (`lit_int(0)` is `0`; polars
then fills only the columns of the matching kind), and an expression
otherwise.
"""
import datetime
import json
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import polars as pl

from emit import _repo_root, emit, encode_series, series_from_spec, to_ours

nan = float("nan")
inf = float("inf")
I64_MIN = -9223372036854775808
I64_MAX = 9223372036854775807

# ---------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------

COLS = {
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
DT_OF = {"i32": "i32", "i64": "i64", "f32": "f32", "f64": "f64", "s": "str",
         "b": "bool", "d": "date", "dt": "datetime[μs]", "n": "null"}
ALL = list(COLS)

T = pl.DataFrame([series_from_spec(c, DT_OF[c], v) for c, v in COLS.items()])
P = pl.DataFrame([
    series_from_spec("a", "i64", [3, 1, 2, 1]),
    series_from_spec("b", "f64", [0.5, 1.5, -2.0, 1.5]),
    series_from_spec("c", "str", ["x", "y", "x", "y"]),
])
TABLES = {"t": T, "p": P, "e0": T.clear(), "z0": pl.DataFrame()}

# ---------------------------------------------------------------------------
# Expression trees (a small subset: what the operations need)
# ---------------------------------------------------------------------------
# ("col", n) ("cols", [n]) ("all",) ("li", v) ("lf", v) ("ls", s) ("lb", b)
# ("lit", dtype, v) ("alias", x, name) ("neg", x) ("bin", op, a, b) ("not", x) ("is_null", x)
# ("cast", x, dtype)

col = lambda n: ("col", n)
cols = lambda ns: ("cols", list(ns))
all_ = ("all",)
li = lambda v: ("li", v)
lf = lambda v: ("lf", v)
ls = lambda v: ("ls", v)
lb = lambda v: ("lb", v)
lit = lambda dt, v: ("lit", dt, v)
neg = lambda x: ("neg", x)
bin_ = lambda op, a, b: ("bin", op, a, b)
not_ = lambda x: ("not", x)
is_null = lambda x: ("is_null", x)
cast = lambda x, dt: ("cast", x, dt)
alias = lambda x, n: ("alias", x, n)

PY_OPS = {"add": "+", "sub": "-", "mul": "*", "rem": "%", "fdiv": "//", "and": "&", "or": "|"}
PY_CMP = {"eq": "eq", "neq": "ne", "gt": "gt", "ge": "ge", "lt": "lt", "le": "le"}
POLARS_DTYPES = {"bool": "pl.Boolean", "i32": "pl.Int32", "i64": "pl.Int64",
                 "f32": "pl.Float32", "f64": "pl.Float64", "str": "pl.String",
                 "date": "pl.Date", "datetime[μs]": "pl.Datetime(\"us\")",
                 "null": "pl.Null"}
MB_DTYPES = {"bool": "Boolean", "i32": "Int32", "i64": "Int64", "f32": "Float32",
             "f64": "Float64", "str": "String", "date": "Date",
             "datetime[μs]": "Datetime", "null": "Null"}


def py_float(v):
    if math.isnan(v):
        return 'float("nan")'
    if math.isinf(v):
        return 'float("inf")' if v > 0 else 'float("-inf")'
    return repr(v)


def mb_float(v):
    if math.isnan(v):
        return "(0.0 / 0.0)"
    if math.isinf(v):
        return "(1.0 / 0.0)" if v > 0 else "(-1.0 / 0.0)"
    r = repr(v)
    m = re.match(r"^(-?)(\d+)(\.\d+)?(e[+-]?\d+)?$", r)
    sign, ip, fp, ex = m.groups()
    text = ip + (fp or ".0") + (ex or "").replace("e+", "e")
    return f"(-{text})" if sign else text


def mb_str(s):
    return json.dumps(s, ensure_ascii=False)


def mb_i64(v):
    if v == I64_MIN:
        return "(-9223372036854775807L - 1L)"
    return f"{v}L" if v >= 0 else f"(-{-v}L)"


def mb_i32(v):
    if v == -2147483648:
        return "(-2147483647 - 1)"
    return str(v) if v >= 0 else f"(-{-v})"


def mb_strs(xs):
    return "[" + ", ".join(mb_str(x) for x in xs) + "]"


def lit_value_py(dt, v):
    """The Python spelling of the typed literal `lit(AnyValue::<dt>(v))`."""
    if v is None:
        return "pl.lit(None)"
    if dt == "date":
        return f"pl.lit(datetime.date(1970, 1, 1) + datetime.timedelta(days={v}))"
    if dt == "datetime[μs]":
        return f"pl.lit(datetime.datetime(1970, 1, 1) + datetime.timedelta(microseconds={v}))"
    if dt in ("f32", "f64"):
        return f"pl.lit({py_float(v)}, dtype={POLARS_DTYPES[dt]})"
    if dt == "str":
        return f"pl.lit({json.dumps(v, ensure_ascii=False)})"
    if dt == "bool":
        return f"pl.lit({v})"
    return f"pl.lit({v}, dtype={POLARS_DTYPES[dt]})"


def lit_value_pl(dt, v):
    if v is None:
        return pl.lit(None)
    if dt == "date":
        return pl.lit(datetime.date(1970, 1, 1) + datetime.timedelta(days=v))
    if dt == "datetime[μs]":
        return pl.lit(datetime.datetime(1970, 1, 1) + datetime.timedelta(microseconds=v))
    if dt in ("f32", "f64"):
        return pl.lit(v, dtype=series_from_spec("x", dt, []).dtype)
    if dt in ("str", "bool"):
        return pl.lit(v)
    return pl.lit(v, dtype=series_from_spec("x", dt, []).dtype)


def lit_mb(dt, v):
    if v is None:
        return "@pl.lit(@pl.AnyValue::Null)"
    if dt == "bool":
        return f"@pl.lit(@pl.AnyValue::Boolean({'true' if v else 'false'}))"
    if dt == "i32":
        return f"@pl.lit(@pl.AnyValue::Int32({mb_i32(v)}))"
    if dt == "i64":
        return f"@pl.lit(@pl.AnyValue::Int64({mb_i64(v)}))"
    if dt == "f32":
        return f"@pl.lit(@pl.AnyValue::Float32({mb_float(v)}))"
    if dt == "f64":
        return f"@pl.lit(@pl.AnyValue::Float64({mb_float(v)}))"
    if dt == "str":
        return f"@pl.lit(@pl.AnyValue::String({mb_str(v)}))"
    if dt == "date":
        return f"@pl.lit(@pl.AnyValue::Date({mb_i32(v)}))"
    if dt == "datetime[μs]":
        return f"@pl.lit(@pl.AnyValue::Datetime({mb_i64(v)}))"
    raise ValueError(dt)


def to_pl(n):
    k = n[0]
    if k == "col":
        return pl.col(n[1])
    if k == "cols":
        return pl.col(*n[1])
    if k == "all":
        return pl.all()
    if k == "li":
        return pl.lit(n[1])
    if k == "lf":
        return pl.lit(n[1])
    if k in ("ls", "lb"):
        return pl.lit(n[1])
    if k == "lit":
        return lit_value_pl(n[1], n[2])
    if k == "alias":
        return to_pl(n[1]).alias(n[2])
    if k == "neg":
        return -to_pl(n[1])
    if k == "not":
        return ~to_pl(n[1])
    if k == "is_null":
        return to_pl(n[1]).is_null()
    if k == "cast":
        return to_pl(n[1]).cast(series_from_spec("x", n[2], []).dtype)
    if k == "bin":
        a, b = to_pl(n[2]), to_pl(n[3])
        op = n[1]
        if op in PY_CMP:
            return getattr(a, PY_CMP[op])(b)
        return {"add": a + b, "sub": a - b, "mul": a * b, "rem": a % b, "fdiv": a // b, "and": a & b, "or": a | b}[op]
    raise ValueError(n)


def to_py(n):
    k = n[0]
    if k == "col":
        return f'pl.col({mb_str(n[1])})'
    if k == "cols":
        return f'pl.col({", ".join(mb_str(x) for x in n[1])})'
    if k == "all":
        return "pl.all()"
    if k == "li":
        return f"pl.lit({n[1]})"
    if k == "lf":
        return f"pl.lit({py_float(n[1])})"
    if k == "ls":
        return f"pl.lit({mb_str(n[1])})"
    if k == "lb":
        return f"pl.lit({n[1]})"
    if k == "lit":
        return lit_value_py(n[1], n[2])
    if k == "alias":
        return f"{to_py(n[1])}.alias({mb_str(n[2])})"
    if k == "neg":
        return f"-({to_py(n[1])})"
    if k == "not":
        return f"~({to_py(n[1])})"
    if k == "is_null":
        return f"{to_py(n[1])}.is_null()"
    if k == "cast":
        return f"{to_py(n[1])}.cast({POLARS_DTYPES[n[2]]})"
    if k == "bin":
        op = n[1]
        if op in PY_CMP:
            return f"({to_py(n[2])}).{PY_CMP[op]}({to_py(n[3])})"
        return f"({to_py(n[2])} {PY_OPS[op]} {to_py(n[3])})"
    raise ValueError(n)


def to_mb(n):
    k = n[0]
    if k == "col":
        return f"@pl.col({mb_str(n[1])})"
    if k == "cols":
        return f"@pl.cols({mb_strs(n[1])})"
    if k == "all":
        return "@pl.all()"
    if k == "li":
        return f"@pl.lit_int({mb_i64(n[1])})"
    if k == "lf":
        return f"@pl.lit_float({mb_float(n[1])})"
    if k == "ls":
        return f"@pl.lit_str({mb_str(n[1])})"
    if k == "lb":
        return f"@pl.lit_bool({'true' if n[1] else 'false'})"
    if k == "lit":
        return lit_mb(n[1], n[2])
    if k == "alias":
        return f"{to_mb(n[1])}.alias({mb_str(n[2])})"
    if k == "neg":
        return f"(-({to_mb(n[1])}))"
    if k == "not":
        return f"{to_mb(n[1])}.not_()"
    if k == "is_null":
        return f"{to_mb(n[1])}.is_null()"
    if k == "cast":
        return f"{to_mb(n[1])}.cast(@pl.DataType::{MB_DTYPES[n[2]]})"
    if k == "bin":
        op = n[1]
        if op in PY_CMP:
            return f"{to_mb(n[2])}.{op}({to_mb(n[3])})"
        if op == "fdiv":
            return f"{to_mb(n[2])}.floor_div({to_mb(n[3])})"
        return f"({to_mb(n[2])} {PY_OPS[op]} {to_mb(n[3])})"
    raise ValueError(n)


def expand_py(n, df):
    """The columns a tree stands for, one polars expression each (so that the
    `by` list of `sort` is as wide as the library's expanded list)."""
    if n[0] == "cols":
        return [pl.col(x) for x in n[1]], [f"pl.col({mb_str(x)})" for x in n[1]]
    if n[0] == "all":
        return [pl.col(x) for x in df.columns], [f"pl.col({mb_str(x)})" for x in df.columns]
    return [to_pl(n)], [to_py(n)]


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
    # no counterpart: the task maps it to InvalidOperation
    "ValueError": "InvalidOperation",
}


def run(thunk):
    """`(frame, None)` or `(None, (polars class, variant, first message line))`."""
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


def row_keys(df):
    cols_ = [encode_series(to_ours(s)[0])["values"] for s in df.get_columns()]
    return [tuple(c[i] for c in cols_) for i in range(df.height)]


def as_rows(src, res):
    """The row numbers of `src` that make `res`, or None when `res` is not a
    selection of rows of `src` (other columns, no columns)."""
    if res.width == 0 or res.schema != src.schema:
        return None
    first = {}
    for i, k in enumerate(row_keys(src)):
        first.setdefault(k, i)
    try:
        rows = [first[k] for k in row_keys(res)]
    except KeyError:
        return None
    assert encode_frame(src[rows]) == encode_frame(res), "rows do not rebuild the result"
    return rows


CASES = []
MB = []
IDS = set()


def case(cid, table, op, polars_text, thunk, mb_call, restricted=False,
         variant=None, known_diff=None, unordered=False, note=None,
         ours_thunk=None, polars_error_ok=True):
    """Adds a case. `mb_call` is the MoonBit body on `df`. `ours_thunk` is run
    instead of `thunk` when the library's result is deliberately not polars'
    (with `known_diff`; the polars result is kept in `polars_schema` /
    `polars_shape`)."""
    assert cid not in IDS, cid
    src = TABLES[table]
    res, err = run(thunk)
    rec = {"id": cid, "polars": polars_text, "table": table, "op": op}
    if unordered:
        rec["unordered"] = True
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
        if variant is not None and variant != var:
            rec["polars_error"] = cls
            var = variant
        elif cls == "ValueError":
            rec["polars_error"] = cls
        rec["error"] = var
        rec["message"] = msg
    else:
        if known_diff:
            rec["known_diff"] = known_diff
            rec["polars_schema"] = schema_text(res)
            rec["polars_shape"] = list(res.shape)
            res, err2 = run(ours_thunk)
            assert err2 is None, cid
        rows = as_rows(src, res)
        if rows is not None:
            # the rows of an unordered case are a set: sorted, so that the
            # file does not depend on the order polars happened to give
            rec["rows"] = sorted(rows) if unordered else rows
        else:
            rec["result"] = encode_frame(res)
            if any(str(a) != str(b) for a, b in zip(res.dtypes, [to_ours(s)[0].dtype for s in res.get_columns()])):
                rec["polars_schema"] = schema_text(res)
    IDS.add(cid)
    CASES.append(rec)
    MB.append((cid, mb_call))


# ---------------------------------------------------------------------------
# filter
# ---------------------------------------------------------------------------

def c_filter(cid, table, tree, **kw):
    df = TABLES[table]
    case(cid, table, "filter", f"{table}.filter({to_py(tree)})",
         lambda: df.filter(to_pl(tree)), f"df.filter({to_mb(tree)})", **kw)


F_OK = [
    ("b", col("b")),
    ("not-b", not_(col("b"))),
    ("i32>0", bin_("gt", col("i32"), li(0))),
    ("i32>=1", bin_("ge", col("i32"), li(1))),
    ("i64<25", bin_("lt", col("i64"), li(25))),
    ("and", bin_("and", bin_("gt", col("i32"), li(0)), col("b"))),
    ("or", bin_("or", col("b"), bin_("lt", col("i32"), li(0)))),
    ("s==a", bin_("eq", col("s"), ls("a"))),
    ("s>z", bin_("gt", col("s"), ls("\U0001F600"))),
    ("f64>0", bin_("gt", col("f64"), lf(0.0))),
    ("f64==nan", bin_("eq", col("f64"), lf(nan))),
    ("f32==-0", bin_("eq", col("f32"), lf(0.0))),
    ("is_null", is_null(col("i32"))),
    ("not-is_null", not_(is_null(col("i32")))),
    ("d>0", bin_("gt", col("d"), lit("date", 0))),
    ("dt<5", bin_("lt", col("dt"), lit("datetime[μs]", 5))),
    ("lit-true", lb(True)),
    ("lit-false", lb(False)),
    ("lit-bool-expr", lit("bool", True)),
    ("neg-b", bin_("and", col("b"), lb(True))),
]
for name, tree in F_OK:
    c_filter(f"filter/t/{name}", "t", tree)
c_filter("filter/p/a>1", "p", bin_("gt", col("a"), li(1)))
c_filter("filter/p/all-true", "p", bin_("ge", col("a"), li(0)))
c_filter("filter/p/none-true", "p", bin_("gt", col("a"), li(9)))
c_filter("filter/p/lit-true", "p", lb(True))
c_filter("filter/p/lit-false", "p", lb(False))
for tname in ("e0", "z0"):
    c_filter(f"filter/{tname}/lit-true", tname, lb(True))
    c_filter(f"filter/{tname}/lit-false", tname, lb(False))
c_filter("filter/e0/b", "e0", col("b"))
c_filter("filter/e0/i32>0", "e0", bin_("gt", col("i32"), li(0)))
for c in ALL:
    if c != "b":
        c_filter(f"filter/t/not-bool/{c}", "t", col(c))
c_filter("filter/t/lit-int", "t", li(1))
c_filter("filter/t/lit-int-big", "t", li(3000000000))
c_filter("filter/t/lit-float", "t", lf(1.5))
# weak literals stay weak through alias, negation and arithmetic
c_filter("filter/t/weak/alias", "t", alias(li(1), "x"))
c_filter("filter/t/weak/neg", "t", neg(li(1)))
c_filter("filter/t/weak/neg-big", "t", neg(li(3000000000)))
c_filter("filter/t/weak/add", "t", bin_("add", li(1), li(2)))
c_filter("filter/t/weak/add-big", "t", bin_("add", li(3000000000), li(1)))
c_filter("filter/t/weak/mul", "t", bin_("mul", li(2), li(3)))
c_filter("filter/t/weak/float-add", "t", bin_("add", lf(1.5), li(1)))
c_filter("filter/t/weak/float-neg", "t", neg(lf(1.5)))
c_filter("filter/t/weak/float-alias", "t", alias(lf(1.5), "y"))
c_filter("filter/t/weak/alias-neg-add", "t", alias(neg(bin_("sub", li(5), li(2))), "z"))
c_filter("filter/t/weak/e0", "e0", alias(li(1), "x"))
c_filter("filter/t/weak/strong-col-alias", "t", alias(col("b"), "x"))
c_filter("filter/t/weak/plus-col", "t", bin_("gt", col("i32"), bin_("add", li(1), li(2))))
# a folding that leaves the Int64 / Float64 range (zero divisor, overflow, the
# null literal, a bitwise operator) is a ComputeError that names polars' weak
# type (i32, u64, i128, f64)
NULL = lit("null", None)
c_filter("filter/t/weak/rem-zero", "t", bin_("rem", li(3), li(0)))
c_filter("filter/t/weak/fdiv-zero", "t", bin_("fdiv", li(3), li(0)))
c_filter("filter/t/weak/float-rem-zero", "t", bin_("rem", lf(3.0), lf(0.0)))
c_filter("filter/t/weak/max-add", "t", bin_("add", li(I64_MAX), li(1)))
c_filter("filter/t/weak/mul-overflow", "t", bin_("mul", li(4611686018427387904), li(2)))
c_filter("filter/t/weak/min-sub", "t", bin_("sub", li(I64_MIN), li(1)))
c_filter("filter/t/weak/neg-min", "t", neg(li(I64_MIN)))
c_filter("filter/t/weak/i32max-add", "t", bin_("add", li(2147483647), li(1)))
c_filter("filter/t/weak/null-add", "t", bin_("add", NULL, li(1)))
c_filter("filter/t/weak/add-null", "t", bin_("add", li(1), NULL))
c_filter("filter/t/weak/null-mul-float", "t", bin_("mul", NULL, lf(1.5)))
c_filter("filter/t/weak/neg-null", "t", neg(NULL))
c_filter("filter/t/weak/and-int", "t", bin_("and", li(1), li(2)))
c_filter("filter/t/weak/or-int", "t", bin_("or", li(1), li(2)))
c_filter("filter/t/weak/and-int-big", "t", bin_("and", li(3000000000), li(1)))
c_filter("filter/t/weak/not-int", "t", not_(li(1)))
c_filter("filter/t/lit-str", "t", ls("a"))
c_filter("filter/t/lit-null", "t", lit("null", None))
c_filter("filter/t/lit-i32", "t", lit("i32", 1))
c_filter("filter/t/missing", "t", col("zz"))
c_filter("filter/t/two-cols", "t", cols(["b", "i32"]))
c_filter("filter/t/one-of-cols", "t", cols(["b"]))
c_filter("filter/t/neg-int", "t", neg(col("i32")))
c_filter("filter/z0/missing", "z0", col("a"))
c_filter("filter/z0/all", "z0", all_)
c_filter("filter/t/all-bool", "t", all_)
c_filter("filter/t/null-pred", "t", bin_("eq", col("n"), li(1)))

# ---------------------------------------------------------------------------
# sort
# ---------------------------------------------------------------------------


def c_sort(cid, table, by, desc=None, nulls_last=False, note=None, **kw):
    """`desc` is the library's `descending~` (None: omitted)."""
    df = TABLES[table]
    py_by = []
    py_texts = []
    for n in by:
        e, t = expand_py(n, df)
        py_by += e
        py_texts += t
    width = len(py_by)
    if not desc:
        py_desc = False
    elif len(desc) == 1:
        py_desc = desc[0]
    else:
        py_desc = list(desc)
    text = (f"{table}.sort(by=[{', '.join(py_texts)}], descending={py_desc}, "
            f"nulls_last={nulls_last}, maintain_order=True)")
    args = f"[{', '.join(to_mb(n) for n in by)}]"
    if desc is not None:
        args += f", descending=[{', '.join('true' if d else 'false' for d in desc)}]"
    if nulls_last:
        args += ", nulls_last=true"
    case(cid, table, "sort", text,
         lambda: df.sort(py_by, descending=py_desc, nulls_last=nulls_last, maintain_order=True),
         f"df.sort({args})", note=note, **kw)


def tf(b):
    return "T" if b else "F"


for c in ALL:
    for d in (False, True):
        for nl in (False, True):
            c_sort(f"sort/t/{c}/d{tf(d)}n{tf(nl)}", "t", [col(c)],
                   desc=[d] if d else None, nulls_last=nl)

PAIRS = [("i32", "s"), ("b", "f64"), ("s", "i64"), ("f64", "i32"), ("f32", "dt"),
         ("d", "b"), ("n", "i32"), ("i64", "i64")]
for a, b in PAIRS:
    for da, db in ((False, False), (True, True), (True, False), (False, True)):
        for nl in (False, True):
            desc = [] if (not da and not db) else ([True] if (da and db) else [da, db])
            c_sort(f"sort/t/{a},{b}/d{tf(da)}{tf(db)}n{tf(nl)}", "t", [col(a), col(b)],
                   desc=desc, nulls_last=nl)
for desc in ([True, False, True], [False, True, False], [True, True, True], [False, False, True]):
    for nl in (False, True):
        c_sort(f"sort/t/b,s,i32/d{''.join(tf(x) for x in desc)}n{tf(nl)}", "t",
               [col("b"), col("s"), col("i32")], desc=desc, nulls_last=nl)
c_sort("sort/t/b,s,i32/nodesc", "t", [col("b"), col("s"), col("i32")])
c_sort("sort/t/b,s,i32/desc1", "t", [col("b"), col("s"), col("i32")], desc=[True])
c_sort("sort/t/i32,i64,f64/d[F]", "t", [col("i32"), col("i64"), col("f64")], desc=[False])
c_sort("sort/p/a", "p", [col("a")])
c_sort("sort/p/a,b/dTF", "p", [col("a"), col("b")], desc=[True, False])
c_sort("sort/p/c,a/dFT", "p", [col("c"), col("a")], desc=[False, True])
c_sort("sort/p/c/dT", "p", [col("c")], desc=[True])
# expressions as keys
for name, tree in [
    ("neg-i32", neg(col("i32"))),
    ("neg-f64", neg(col("f64"))),
    ("i32*-1", bin_("mul", col("i32"), li(-1))),
    ("i32+i64", bin_("add", col("i32"), col("i64"))),
    ("i32-i32", bin_("sub", col("i32"), col("i32"))),
    ("is_null-i32", is_null(col("i32"))),
    ("not-b", not_(col("b"))),
    ("i32>0", bin_("gt", col("i32"), li(0))),
    ("f64*2", bin_("mul", col("f64"), lf(2.0))),
    ("cast-i32-f64", cast(col("i32"), "f64")),
    ("cast-b-i32", cast(col("b"), "i32")),
]:
    c_sort(f"sort/t/expr/{name}", "t", [tree])
    c_sort(f"sort/t/expr/{name}/dTnT", "t", [tree], desc=[True], nulls_last=True)
c_sort("sort/t/expr/is_null,s", "t", [is_null(col("i32")), col("s")], desc=[True, False])
c_sort("sort/t/expr/neg,i64", "t", [neg(col("i32")), col("i64")], desc=[False, True])
# selectors expand before the length of `descending` is checked
c_sort("sort/t/cols-i32,s", "t", [cols(["i32", "s"])])
c_sort("sort/t/cols-i32,s/dTF", "t", [cols(["i32", "s"])], desc=[True, False],
       note="polars checks descending against the unexpanded by list; the python spelling is the expanded list")
c_sort("sort/t/cols-i32,s/dT", "t", [cols(["i32", "s"])], desc=[True])
c_sort("sort/t/cols+f64/dTFT", "t", [cols(["i32", "s"]), col("f64")], desc=[True, False, True],
       note="polars checks descending against the unexpanded by list; the python spelling is the expanded list")
c_sort("sort/t/cols+f64/dTF", "t", [cols(["i32", "s"]), col("f64")], desc=[True, False],
       note="polars checks descending against the unexpanded by list; the python spelling is the expanded list")
c_sort("sort/t/all", "t", [all_])
c_sort("sort/t/all/dT", "t", [all_], desc=[True], nulls_last=True)
c_sort("sort/p/all", "p", [all_])
c_sort("sort/t/dup-keys", "t", [col("i32"), col("i32")])
c_sort("sort/t/dup-keys/dTF", "t", [col("i32"), col("i32")], desc=[True, False])
c_sort("sort/t/no-keys", "t", [])
c_sort("sort/t/no-keys/nlT", "t", [], nulls_last=True)
c_sort("sort/e0/i32", "e0", [col("i32")])
c_sort("sort/e0/i32,s/dTF", "e0", [col("i32"), col("s")], desc=[True, False])
c_sort("sort/z0/no-keys", "z0", [])
# errors
c_sort("sort/err/desc3-by2", "t", [col("i32"), col("s")], desc=[True, False, True])
c_sort("sort/err/desc4-by2", "t", [col("i32"), col("s")], desc=[True, False, True, False])
c_sort("sort/err/desc2-by1", "t", [col("i32")], desc=[True, False])
c_sort("sort/err/desc2-by3", "t", [col("i32"), col("s"), col("b")], desc=[True, False])
c_sort("sort/err/desc4-by3", "t", [col("i32"), col("s"), col("b")], desc=[True, False, True, False])
c_sort("sort/err/desc3-by2-missing", "t", [col("zz"), col("i32")], desc=[True, False, True])
c_sort("sort/err/missing", "t", [col("zz")])
c_sort("sort/err/second-missing", "t", [col("i32"), col("zz")])
c_sort("sort/err/missing-e0", "e0", [col("zz")])
c_sort("sort/err/lit-int", "t", [li(1)])
c_sort("sort/err/col+lit", "t", [col("i32"), li(1)])
c_sort("sort/err/lit-str", "t", [ls("a")])
c_sort("sort/err/lit-e0", "e0", [li(1)])
c_sort("sort/err/lit-z0", "z0", [li(1)])
c_sort("sort/err/lit-p", "p", [lb(True)])

# ---------------------------------------------------------------------------
# unique
# ---------------------------------------------------------------------------

KEEPS = {"any": "Any", "first": "First", "last": "Last", "none": "KeepNone"}


def c_unique(cid, table, subset=None, keep="any", maintain_order=True,
             unordered=False, **kw):
    df = TABLES[table]
    py_sub = "None" if subset is None else repr(subset)
    text = (f"{table}.unique(subset={py_sub}, keep={keep!r}, "
            f"maintain_order={maintain_order})")
    args = []
    if subset is not None:
        args.append(f"subset={mb_strs(subset)}")
    if keep != "any":
        args.append(f"keep=@pl.UniqueKeep::{KEEPS[keep]}")
    args.append(f"maintain_order={'true' if maintain_order else 'false'}")
    case(cid, table, "unique", text,
         lambda: df.unique(subset=subset, keep=keep, maintain_order=maintain_order),
         f"df.unique({', '.join(args)})", unordered=unordered, **kw)


SUBSETS = [None, ["i32"], ["i64", "s"], ["f64"], ["f32"], ["b"], ["n"], ["s", "d"],
           ["dt", "n"], ["s"], ["i32", "i64", "f64", "s", "b"]]
for sub in SUBSETS:
    label = "all" if sub is None else ",".join(sub)
    for keep in KEEPS:
        c_unique(f"unique/t/{label}/{keep}", "t", sub, keep)
for sub in (None, ["i32"], ["f64"], ["s"], ["b"], ["n"]):
    label = "all" if sub is None else ",".join(sub)
    for keep in ("first", "last", "none"):
        c_unique(f"unique/t/{label}/{keep}/unordered", "t", sub, keep,
                 maintain_order=False, unordered=True)
c_unique("unique/t/all/any/unordered", "t", None, "any", maintain_order=False, unordered=True)
c_unique("unique/p/all/any", "p")
c_unique("unique/p/c/first", "p", ["c"], "first")
c_unique("unique/p/c/last", "p", ["c"], "last")
c_unique("unique/p/c/none", "p", ["c"], "none")
c_unique("unique/p/b,c/last", "p", ["b", "c"], "last")
c_unique("unique/t/dup-names", "t", ["i32", "i32"], "first")
c_unique("unique/t/order-names", "t", ["s", "i32"], "last")
c_unique("unique/e0/all", "e0")
c_unique("unique/e0/i32/none", "e0", ["i32"], "none")
c_unique("unique/z0/all", "z0")
c_unique("unique/z0/all/none", "z0", None, "none")
c_unique("unique/err/missing", "t", ["zz"])
c_unique("unique/err/second-missing", "t", ["i32", "zz"])
c_unique("unique/err/empty-subset", "t", [])
c_unique("unique/err/z0-subset", "z0", ["a"])
c_unique("unique/err/e0-missing", "e0", ["zz"], "first")

# ---------------------------------------------------------------------------
# drop
# ---------------------------------------------------------------------------


def c_drop(cid, table, names, strict=True, **kw):
    df = TABLES[table]
    text = f"{table}.drop({', '.join(mb_str(n) for n in names)}, strict={strict})"
    args = mb_strs(names) + ("" if strict else ", strict=false")
    case(cid, table, "drop", text, lambda: df.drop(*names, strict=strict),
         f"df.drop({args})", **kw)


c_drop("drop/t/i32", "t", ["i32"])
c_drop("drop/t/i32,s", "t", ["i32", "s"])
c_drop("drop/t/s,i32", "t", ["s", "i32"])
c_drop("drop/t/last-first", "t", ["n", "i32"])
c_drop("drop/t/dup", "t", ["i32", "i32"])
c_drop("drop/t/none", "t", [])
c_drop("drop/t/none-nonstrict", "t", [], strict=False)
c_drop("drop/t/all-but-one", "t", ALL[1:])
c_drop("drop/t/all", "t", ALL)
c_drop("drop/t/missing", "t", ["zz"])
c_drop("drop/t/missing-nonstrict", "t", ["zz"], strict=False)
c_drop("drop/t/missing-then-present", "t", ["zz", "i32"])
c_drop("drop/t/present-then-missing", "t", ["i32", "zz"])
c_drop("drop/t/two-missing", "t", ["zz", "yy"])
c_drop("drop/t/two-missing-b", "t", ["yy", "zz"])
c_drop("drop/t/mixed-nonstrict", "t", ["i32", "zz", "i32", "s"], strict=False)
c_drop("drop/t/mixed-strict", "t", ["i32", "zz", "i32"])
c_drop("drop/p/a", "p", ["a"])
c_drop("drop/e0/i32", "e0", ["i32"])
c_drop("drop/e0/all", "e0", ALL)
c_drop("drop/z0/a", "z0", ["a"])
c_drop("drop/z0/a-nonstrict", "z0", ["a"], strict=False)

# ---------------------------------------------------------------------------
# rename
# ---------------------------------------------------------------------------


def mb_map(m):
    if not m:
        return "({} : Map[String, String])"
    return "{" + ", ".join(f"{mb_str(k)}: {mb_str(v)}" for k, v in m.items()) + "}"


def c_rename(cid, table, mapping, strict=True, **kw):
    df = TABLES[table]
    text = f"{table}.rename({json.dumps(mapping, ensure_ascii=False)}, strict={strict})"
    args = mb_map(mapping) + ("" if strict else ", strict=false")
    case(cid, table, "rename", text, lambda: df.rename(mapping, strict=strict),
         f"df.rename({args})", **kw)


c_rename("rename/t/one", "t", {"i32": "x"})
c_rename("rename/t/two", "t", {"i32": "x", "s": "y"})
c_rename("rename/t/swap", "t", {"i32": "i64", "i64": "i32"})
c_rename("rename/t/chain", "t", {"i32": "i64", "i64": "f32"})
c_rename("rename/t/rotate", "t", {"i32": "i64", "i64": "f32", "f32": "i32"})
c_rename("rename/t/same", "t", {"i32": "i32"})
c_rename("rename/t/empty-map", "t", {})
c_rename("rename/t/empty-name", "t", {"i32": ""})
c_rename("rename/t/unicode", "t", {"s": "\U0001F600", "b": "｡"})
c_rename("rename/t/all", "t", {c: c.upper() for c in ALL})
c_rename("rename/t/dup-existing", "t", {"i32": "s"})
c_rename("rename/t/dup-new", "t", {"i32": "x", "s": "x"})
c_rename("rename/t/dup-new-3", "t", {"i32": "x", "s": "y", "b": "x"})
c_rename("rename/t/dup-two", "t", {"i32": "s", "i64": "b"})
c_rename("rename/t/dup-nonstrict", "t", {"i32": "s", "zz": "q"}, strict=False)
c_rename("rename/t/missing", "t", {"zz": "x"})
c_rename("rename/t/missing-nonstrict", "t", {"zz": "x"}, strict=False)
c_rename("rename/t/missing-two", "t", {"zz": "x", "yy": "w"})
c_rename("rename/t/missing-two-b", "t", {"yy": "w", "zz": "x"})
c_rename("rename/t/present-missing", "t", {"i32": "x", "zz": "y"})
c_rename("rename/t/missing-present", "t", {"zz": "y", "i32": "x"})
c_rename("rename/t/present-missing-nonstrict", "t", {"i32": "x", "zz": "y"}, strict=False)
c_rename("rename/t/missing-dup-strict", "t", {"zz": "s", "i32": "s"})
c_rename("rename/t/missing-to-existing-nonstrict", "t", {"zz": "s"}, strict=False)
c_rename("rename/p/a", "p", {"a": "x"})
c_rename("rename/e0/i32", "e0", {"i32": "x"})
c_rename("rename/z0/a", "z0", {"a": "b"})
c_rename("rename/z0/a-nonstrict", "z0", {"a": "b"}, strict=False)

# ---------------------------------------------------------------------------
# fill_null
# ---------------------------------------------------------------------------


def fill_py(tree):
    """`(value to pass to polars, text)`: a Python scalar for the literals."""
    k = tree[0]
    if k == "li":
        return tree[1], repr(tree[1])
    if k == "lf":
        return tree[1], py_float(tree[1])
    if k in ("ls", "lb"):
        return tree[1], json.dumps(tree[1], ensure_ascii=False) if k == "ls" else repr(tree[1])
    if k == "lit" and tree[1] == "date":
        v = tree[2]
        return (datetime.date(1970, 1, 1) + datetime.timedelta(days=v),
                f"datetime.date(1970, 1, 1) + datetime.timedelta(days={v})")
    if k == "lit" and tree[1] == "datetime[μs]":
        v = tree[2]
        return (datetime.datetime(1970, 1, 1) + datetime.timedelta(microseconds=v),
                f"datetime.datetime(1970, 1, 1) + datetime.timedelta(microseconds={v})")
    return to_pl(tree), to_py(tree)


def c_fill(cid, table, tree, **kw):
    df = TABLES[table]
    value, vtext = fill_py(tree)
    case(cid, table, "fill_null", f"{table}.fill_null({vtext})",
         lambda: df.fill_null(value), f"df.fill_null({to_mb(tree)})", **kw)


FILLS = [
    ("int0", li(0)), ("int-1", li(-1)), ("int3e9", li(3000000000)), ("int2^40", li(1 << 40)),
    ("int-max", li(I64_MAX)), ("int-min", li(I64_MIN)),
    ("float1.5", lf(1.5)), ("float0", lf(0.0)), ("float-0", lf(-0.0)), ("float-nan", lf(nan)),
    ("float-inf", lf(inf)), ("float1e300", lf(1e300)),
    ("str-z", ls("z")), ("str-empty", ls("")), ("str-emoji", ls("\U0001F600")), ("str-0", ls("0")),
    ("bool-true", lb(True)), ("bool-false", lb(False)),
    ("date", lit("date", 3)), ("datetime", lit("datetime[μs]", 7)),
    ("i32", lit("i32", 0)), ("i32-neg", lit("i32", -5)), ("i64", lit("i64", 3000000000)),
    ("f32", lit("f32", 0.5)), ("f64", lit("f64", 0.5)), ("f64-nan", lit("f64", nan)),
    ("null", lit("null", None)),
]
for name, tree in FILLS:
    c_fill(f"fill_null/t/{name}", "t", tree)
for name, tree in [("int0", li(0)), ("float1.5", lf(1.5)), ("str-z", ls("z")),
                   ("bool-true", lb(True)), ("i32", lit("i32", 0)), ("null", lit("null", None))]:
    c_fill(f"fill_null/p/{name}", "p", tree)
    c_fill(f"fill_null/e0/{name}", "e0", tree)
    c_fill(f"fill_null/z0/{name}", "z0", tree)
# an expression value: polars fills every column from it (`all().fill_null(expr)`,
# M2 T9; before T9 these cases were `restricted`)
for name, tree in [("col-i32", col("i32")), ("col-f64", col("f64")), ("col-s", col("s")),
                   ("col-b", col("b")), ("col-n", col("n")), ("col-d", col("d")),
                   ("expr-i32+1", bin_("add", col("i32"), li(1))),
                   ("neg-i32", neg(col("i32"))), ("alias", alias(col("i64"), "z"))]:
    c_fill(f"fill_null/t/expr/{name}", "t", tree)
for name, tree in [("col-a", col("a")), ("col-c", col("c"))]:
    c_fill(f"fill_null/p/expr/{name}", "p", tree)
for name, tree in [("col-i32", col("i32")), ("col-s", col("s"))]:
    c_fill(f"fill_null/e0/expr/{name}", "e0", tree)
c_fill("fill_null/z0/expr/col", "z0", col("i32"))
# weak literals inside the value expression adapt like in `select` (table `t` has
# a Date and a Datetime column, where polars refuses a weak literal and names the
# last of them: not compared, see known-diffs/frame_ops.md)
c_fill("fill_null/p/expr/lit-sum", "p", bin_("add", li(1), li(2)))
c_fill("fill_null/p/expr/lit-float-sum", "p", bin_("add", lf(0.5), li(2)))
c_fill("fill_null/p/expr/neg-lit", "p", neg(li(1)))
c_fill("fill_null/t/expr/cols", "t", cols(["i32", "i64"]))
c_fill("fill_null/p/expr/cols3", "p", cols(["c", "a", "b"]))

# ---------------------------------------------------------------------------
# drop_nulls
# ---------------------------------------------------------------------------


def c_drop_nulls(cid, table, subset=None, **kw):
    df = TABLES[table]
    text = f"{table}.drop_nulls({'' if subset is None else repr(subset)})"
    args = "" if subset is None else f"subset={mb_strs(subset)}"
    case(cid, table, "drop_nulls", text, lambda: df.drop_nulls(subset),
         f"df.drop_nulls({args})", **kw)


for sub in (None, ["i32"], ["i32", "s"], ["f64"], ["f32"], ["s"], ["b", "d"], ["n"], ["i32", "n"],
            ["dt"], ["i64", "b", "dt"], ["i32", "i32"], ["s", "i32"], ["d", "b", "f64"], []):
    label = "all" if sub is None else ("empty" if not sub else ",".join(sub))
    c_drop_nulls(f"drop_nulls/t/{label}", "t", sub)
c_drop_nulls("drop_nulls/t/missing", "t", ["zz"])
c_drop_nulls("drop_nulls/t/second-missing", "t", ["i32", "zz"])
c_drop_nulls("drop_nulls/t/two-missing", "t", ["yy", "zz"])
c_drop_nulls("drop_nulls/p/all", "p")
c_drop_nulls("drop_nulls/p/a", "p", ["a"])
c_drop_nulls("drop_nulls/e0/all", "e0")
c_drop_nulls("drop_nulls/e0/i32", "e0", ["i32"])
c_drop_nulls("drop_nulls/z0/all", "z0")
c_drop_nulls("drop_nulls/z0/empty", "z0", [])
c_drop_nulls("drop_nulls/z0/a", "z0", ["a"])

# ---------------------------------------------------------------------------
# null_count, with_row_index
# ---------------------------------------------------------------------------

for tname in TABLES:
    df = TABLES[tname]
    kd = {}
    if tname == "z0":
        # polars: a (1, 0) frame; the library has no rows when it has no columns
        kd = dict(known_diff="no-columns-height", ours_thunk=lambda: pl.DataFrame())
    case(f"null_count/{tname}", tname, "null_count", f"{tname}.null_count()",
         lambda df=df: df.null_count(), "df.null_count()", **kd)


def c_wri(cid, table, name=None, offset=None, **kw):
    df = TABLES[table]
    py_args = []
    mb_args = []
    if name is not None:
        py_args.append(f"name={mb_str(name)}")
        mb_args.append(f"name={mb_str(name)}")
    if offset is not None:
        py_args.append(f"offset={offset}")
        mb_args.append(f"offset={mb_i32(offset)}")
    kwargs = {}
    if name is not None:
        kwargs["name"] = name
    if offset is not None:
        kwargs["offset"] = offset
    case(cid, table, "with_row_index", f"{table}.with_row_index({', '.join(py_args)})",
         lambda: df.with_row_index(**kwargs), f"df.with_row_index({', '.join(mb_args)})", **kw)


for tname in TABLES:
    c_wri(f"with_row_index/{tname}/default", tname)
c_wri("with_row_index/t/name", "t", name="r")
c_wri("with_row_index/t/offset", "t", offset=5)
c_wri("with_row_index/t/name+offset", "t", name="r", offset=100)
c_wri("with_row_index/t/offset0", "t", offset=0)
c_wri("with_row_index/t/offset-max", "t", offset=2147483647)
c_wri("with_row_index/t/offset-1000000000", "t", offset=1000000000)
c_wri("with_row_index/t/empty-name", "t", name="")
c_wri("with_row_index/t/unicode-name", "t", name="\U0001F600")
c_wri("with_row_index/p/name", "p", name="row")
c_wri("with_row_index/e0/offset", "e0", offset=3)
c_wri("with_row_index/z0/name+offset", "z0", name="r", offset=4)
c_wri("with_row_index/err/dup-i32", "t", name="i32")
c_wri("with_row_index/err/dup-n", "t", name="n", offset=1)
c_wri("with_row_index/err/dup-e0", "e0", name="s")
c_wri("with_row_index/err/neg-1", "t", offset=-1)
c_wri("with_row_index/err/neg-big", "t", offset=-2147483648)
c_wri("with_row_index/err/neg-dup", "t", name="i32", offset=-1)
c_wri("with_row_index/err/neg-z0", "z0", offset=-3)

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------


def mb_cases_file():
    lines = ["// 由 docs/golden/scripts/frame_ops.py 生成，勿手改", "",
             ]
    chunk = 60
    parts = [MB[i:i + chunk] for i in range(0, len(MB), chunk)]
    for pi, part in enumerate(parts):
        lines += ["///|", f"fn golden_frame_ops_cases_{pi}(m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError]) -> Unit {{"]
        for cid, call in part:
            # `null_count` cannot raise; the error type would be unused
            raises = "" if call == "df.null_count()" else " raise @pl.PolarsError"
            lines.append(f"  m[{mb_str(cid)}] = fn(df : @pl.DataFrame) -> @pl.DataFrame{raises} {{")
            lines.append(f"    {call}")
            lines.append("  }")
        lines += ["}", ""]
    lines += ["///|", "/// Every case id with the operation it runs.",
              "fn golden_frame_ops_cases() -> Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError] {",
              "  let m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError] = Map([])"]
    for pi in range(len(parts)):
        lines.append(f"  golden_frame_ops_cases_{pi}(m)")
    lines += ["  m", "}", ""]
    path = os.path.join(_repo_root(), "src", "pl", "frame_ops_golden_cases_test.mbt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


doc = {
    "tables": {name: encode_frame(df) for name, df in TABLES.items()},
    "cases": CASES,
}
emit("frame_ops", doc, compact=True)
mb_cases_file()
kinds = {"result": 0, "rows": 0, "error": 0, "restricted": 0}
for c in CASES:
    for k in kinds:
        if k in c:
            kinds[k] += 1
print(f"{len(CASES)} cases", kinds, "known_diff:", sum(1 for c in CASES if "known_diff" in c))
