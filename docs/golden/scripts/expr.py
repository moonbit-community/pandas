"""Generates the expression golden data (docs/golden/expr.json,
src/pl/golden_expr_data_test.mbt) and the MoonBit expressions of every case
(src/pl/expr_golden_cases_test.mbt).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/expr.py

The file is `{"tables": {name: frame}, "cases": [...]}` (compact layout).
A frame is `{"columns": [series, ...]}` (series as in docs/golden/README.md).
Tables: `t` (nine columns i32, i64, f32, f64, s, b, d, dt, n; seven rows with
nulls, NaN, -0.0, the integer limits and the Review Focus strings), `num` (its
four number columns), `e0` (the schema of `t`, no rows) and `z0` (no columns).

Every case has `id`, `polars` (the
Python spelling), `str` (polars' `str(expr)` for every expression of the case),
`table` (default `t`), `op` (`select`, the default, or `with_columns`) and one of
  - `result`: a frame (through `to_ours`);
  - `error` + `message`: the variant per the M2 error mapping and the first
    line of polars' message (`polars_error` keeps the polars class when the
    library uses another variant);
  - `restricted: true`: the library is deliberately stricter than polars
    (spec 5.5), only `InvalidOperation` is required.
`known_diff` marks a case whose `result` is the library's, not polars': the
polars result is in `polars_schema` (see docs/golden/known-diffs/expr.md).

The cases are written once as a small expression tree; the tree is rendered as
a polars expression, as the Python text of `polars` and as MoonBit source.
The MoonBit rendering goes to src/pl/expr_golden_cases_test.mbt, which maps
every case id to its expressions.
"""
import datetime
import json
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import polars as pl

from emit import DTYPE_NAMES, _repo_root, emit, encode_series, series_from_spec, to_ours

nan = float("nan")
inf = float("inf")
I64_MIN = -9223372036854775808
I64_MAX = 9223372036854775807

# ---------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------

COLS = {
    "i32": [1, -1, 0, 2147483647, -2147483648, None, 7],
    "i64": [1, -1, 0, I64_MAX, I64_MIN, None, 3000000000],
    "f32": [0.5, nan, None, -inf, -0.0, 0.0, 3.0e38],
    "f64": [1.0, nan, None, -inf, -0.0, 0.0, 2.5],
    "s": ["｡", "\U0001F600", "a", "", "Z", None, "a"],
    "b": [True, False, None, True, False, None, True],
    "d": [0, -1, 19782, None, -25567, 1, 2],
    "dt": [0, -1, 1709210096123456, None, 86399999999, 5, 6],
    "n": [None] * 7,
}
DT_OF = {"i32": "i32", "i64": "i64", "f32": "f32", "f64": "f64", "s": "str",
         "b": "bool", "d": "date", "dt": "datetime[μs]", "n": "null"}
NUMS = ["i32", "i64", "f32", "f64"]
ALL = list(COLS)

T = pl.DataFrame([series_from_spec(c, DT_OF[c], v) for c, v in COLS.items()])
TABLES = {
    "t": T,
    "num": T.select(NUMS),
    "e0": T.clear(),
    "z0": pl.DataFrame(),
}

# ---------------------------------------------------------------------------
# Expression trees
# ---------------------------------------------------------------------------
# ("col", name) ("cols", [names]) ("all",) ("lit_int", v) ("lit_float", v)
# ("lit_str", s) ("lit_bool", b) ("lit", dtype, v)
# ("bin", op, l, r) ("neg", x) ("not", x) ("alias", x, name)
# ("cast", x, dtype, strict) ("is_null", x) ("is_not_null", x)

col = lambda n: ("col", n)
cols = lambda ns: ("cols", list(ns))
all_ = ("all",)
li = lambda v: ("lit_int", v)
lf = lambda v: ("lit_float", v)
ls = lambda v: ("lit_str", v)
lb = lambda v: ("lit_bool", v)
lit = lambda dt, v: ("lit", dt, v)
bin_ = lambda op, a, b: ("bin", op, a, b)
neg = lambda x: ("neg", x)
not_ = lambda x: ("not", x)
alias = lambda x, n: ("alias", x, n)
cast = lambda x, dt, strict=True: ("cast", x, dt, strict)
is_null = lambda x: ("is_null", x)
is_not_null = lambda x: ("is_not_null", x)

PY_OPS = {"add": "+", "sub": "-", "mul": "*", "div": "/", "mod": "%",
          "floordiv": "//", "and": "&", "or": "|"}
PY_CMP = {"eq": "eq", "neq": "ne", "gt": "gt", "ge": "ge", "lt": "lt", "le": "le"}
MB_CMP = {"eq": "eq", "neq": "neq", "gt": "gt", "ge": "ge", "lt": "lt", "le": "le"}
MB_OPS = {"add": "+", "sub": "-", "mul": "*", "div": "/", "mod": "%",
          "and": "&", "or": "|"}
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


def lit_py(dt, v):
    if v is None:
        return f"pl.lit(None, dtype={POLARS_DTYPES[dt]})" if dt != "null" else "pl.lit(None)"
    if dt == "date":
        return f"pl.lit(datetime.date(1970, 1, 1) + datetime.timedelta(days={v}))"
    if dt == "datetime[μs]":
        return f"pl.lit(datetime.datetime(1970, 1, 1) + datetime.timedelta(microseconds={v}))"
    if dt == "f32" or dt == "f64":
        return f"pl.lit({py_float(v)}, dtype={POLARS_DTYPES[dt]})"
    if dt == "str":
        return f"pl.lit({json.dumps(v, ensure_ascii=False)})"
    if dt == "bool":
        return f"pl.lit({v})"
    return f"pl.lit({v}, dtype={POLARS_DTYPES[dt]})"


def lit_pl(dt, v):
    if v is None:
        return pl.lit(None) if dt == "null" else pl.lit(None, dtype=series_from_spec("x", dt, []).dtype)
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
        return pl.col(n[1])
    if k == "all":
        return pl.all()
    if k in ("lit_int", "lit_float", "lit_str", "lit_bool"):
        return pl.lit(n[1])
    if k == "lit":
        return lit_pl(n[1], n[2])
    if k == "bin":
        _, op, a, b = n
        a, b = to_pl(a), to_pl(b)
        if op in PY_CMP:
            return getattr(a, PY_CMP[op])(b)
        return {"add": lambda: a + b, "sub": lambda: a - b, "mul": lambda: a * b,
                "div": lambda: a / b, "mod": lambda: a % b, "floordiv": lambda: a // b,
                "and": lambda: a & b, "or": lambda: a | b}[op]()
    if k == "neg":
        return -to_pl(n[1])
    if k == "not":
        return ~to_pl(n[1])
    if k == "alias":
        return to_pl(n[1]).alias(n[2])
    if k == "cast":
        return to_pl(n[1]).cast(series_from_spec("x", n[2], []).dtype, strict=n[3])
    if k == "is_null":
        return to_pl(n[1]).is_null()
    if k == "is_not_null":
        return to_pl(n[1]).is_not_null()
    raise ValueError(k)


def to_py(n):
    k = n[0]
    if k == "col":
        return f"pl.col({json.dumps(n[1], ensure_ascii=False)})"
    if k == "cols":
        return "pl.col([" + ", ".join(json.dumps(x, ensure_ascii=False) for x in n[1]) + "])"
    if k == "all":
        return "pl.all()"
    if k == "lit_int":
        return f"pl.lit({n[1]})"
    if k == "lit_float":
        return f"pl.lit({py_float(n[1])})"
    if k == "lit_str":
        return f"pl.lit({json.dumps(n[1], ensure_ascii=False)})"
    if k == "lit_bool":
        return f"pl.lit({n[1]})"
    if k == "lit":
        return lit_py(n[1], n[2])
    if k == "bin":
        _, op, a, b = n
        if op in PY_CMP:
            return f"({to_py(a)}).{PY_CMP[op]}({to_py(b)})"
        return f"({to_py(a)} {PY_OPS[op]} {to_py(b)})"
    if k == "neg":
        return f"(-{to_py(n[1])})"
    if k == "not":
        return f"(~{to_py(n[1])})"
    if k == "alias":
        return f"{to_py(n[1])}.alias({json.dumps(n[2], ensure_ascii=False)})"
    if k == "cast":
        return f"{to_py(n[1])}.cast({POLARS_DTYPES[n[2]]}, strict={n[3]})"
    if k == "is_null":
        return f"{to_py(n[1])}.is_null()"
    if k == "is_not_null":
        return f"{to_py(n[1])}.is_not_null()"
    raise ValueError(k)


def to_mb(n):
    k = n[0]
    if k == "col":
        return f"@pl.col({mb_str(n[1])})"
    if k == "cols":
        return "@pl.cols([" + ", ".join(mb_str(x) for x in n[1]) + "])"
    if k == "all":
        return "@pl.all()"
    if k == "lit_int":
        return f"@pl.lit_int({mb_i64(n[1])})"
    if k == "lit_float":
        return f"@pl.lit_float({mb_float(n[1])})"
    if k == "lit_str":
        return f"@pl.lit_str({mb_str(n[1])})"
    if k == "lit_bool":
        return f"@pl.lit_bool({'true' if n[1] else 'false'})"
    if k == "lit":
        return lit_mb(n[1], n[2])
    if k == "bin":
        _, op, a, b = n
        if op in MB_CMP:
            return f"{to_mb(a)}.{MB_CMP[op]}({to_mb(b)})"
        if op == "floordiv":
            return f"{to_mb(a)}.floor_div({to_mb(b)})"
        return f"({to_mb(a)} {MB_OPS[op]} {to_mb(b)})"
    if k == "neg":
        return f"(-{to_mb(n[1])})"
    if k == "not":
        return f"{to_mb(n[1])}.not_()"
    if k == "alias":
        return f"{to_mb(n[1])}.alias({mb_str(n[2])})"
    if k == "cast":
        strict = "" if n[3] else ", strict=false"
        return f"{to_mb(n[1])}.cast(@pl.DataType::{MB_DTYPES[n[2]]}{strict})"
    if k == "is_null":
        return f"{to_mb(n[1])}.is_null()"
    if k == "is_not_null":
        return f"{to_mb(n[1])}.is_not_null()"
    raise ValueError(k)


def has(n, kinds):
    """Whether the tree contains a node of one of the `kinds`."""
    if n[0] in kinds:
        return True
    return any(has(c, kinds) for c in n[1:] if isinstance(c, tuple))


def pure_weak(n):
    """Whether `n` is made of weak literals only (the type of the result is
    then not decided by a column or a strong literal)."""
    k = n[0]
    if k in ("lit_int", "lit_float"):
        return True
    if k in ("alias", "neg"):
        return pure_weak(n[1])
    if k == "bin":
        return pure_weak(n[2]) and pure_weak(n[3])
    return False


def strong_all(n):
    k = n[0]
    if k == "lit_int":
        return ("lit", "i64", n[1])
    if k == "lit_float":
        return ("lit", "f64", n[1])
    return tuple(strong_all(c) if isinstance(c, tuple) else c for c in n)


def strengthen(n, keep_weak=False):
    """`n` with every weak literal that no column or strong literal decides
    the type of replaced by the 64-bit strong literal the library gives it
    (spec 5.5: `Int64` / `Float64`; polars uses `Int32` when the value
    fits). A pure-weak operand of a binary operation next to something else is
    left alone: it adapts to the other side."""
    if pure_weak(n):
        return n if keep_weak else strong_all(n)
    if n[0] == "bin":
        return ("bin", n[1], strengthen(n[2], True), strengthen(n[3], True))
    return tuple(strengthen(c) if isinstance(c, tuple) else c for c in n)


# ---------------------------------------------------------------------------
# Running polars
# ---------------------------------------------------------------------------

VARIANTS = {
    "ColumnNotFoundError": "ColumnNotFound",
    "DuplicateError": "DuplicateColumn",
    "SchemaError": "SchemaMismatch",
    "ShapeError": "ShapeMismatch",
    "OutOfBoundsError": "OutOfBounds",
    "InvalidOperationError": "InvalidOperation",
    "ComputeError": "ComputeError",
}


def run(df, op, nodes):
    """`(frame, None)` or `(None, (polars class, variant, first message line))`."""
    try:
        exprs = [to_pl(n) for n in nodes]
        return getattr(df, op)(exprs), None
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
MB = []
IDS = set()


def register(rec, nodes):
    IDS.add(rec["id"])
    CASES.append(rec)
    MB.append((rec["id"], [to_mb(n) for n in nodes]))


def case(cid, table, nodes, op="select", restricted=False, variant=None,
         known_diff=None):
    """Adds a case. `variant` renames the error variant the library uses where
    it differs from the mapping of polars' class. With `known_diff` unset, a
    col-free tree of weak literals is run again with strong 64-bit literals
    when polars' result differs (dtype only)."""
    assert cid not in IDS, cid
    df = TABLES[table]
    res, err = run(df, op, nodes)
    rec = {
        "id": cid,
        "polars": f"{table}.{op}([{', '.join(to_py(n) for n in nodes)}])",
        "str": [],
    }
    if table != "t":
        rec["table"] = table
    if op != "select":
        rec["op"] = op
    try:
        rec["str"] = [str(to_pl(n)) for n in nodes]
    except BaseException as e:  # noqa: BLE001
        raise RuntimeError(f"{cid}: cannot print") from e
    if restricted:
        rec["restricted"] = True
        if res is not None:
            rec["polars_schema"] = schema_text(res)
        return register(rec, nodes)
    if err is not None:
        cls, var, msg = err
        if variant is not None and variant != var:
            rec["polars_error"] = cls
            var = variant
        rec["error"] = var
        rec["message"] = msg
        if cls == "PanicException":
            # a polars bug (no error to compare with): not a case
            print("PANIC (skipped)", cid, msg)
            return
        return register(rec, nodes)
    if known_diff is None:
        ours_nodes = [strengthen(n) for n in nodes]
        ours, oerr = run(df, op, ours_nodes)
        if oerr is None and (schema_text(ours) != schema_text(res)):
            known_diff = "dyn-literal-default"
            rec["polars_schema"] = schema_text(res)
            res = ours
    if known_diff:
        rec["known_diff"] = known_diff
    try:
        rec["result"] = encode_frame(res)
    except (ValueError, pl.exceptions.PolarsError) as e:
        print("SKIP", cid, e)
        return
    register(rec, nodes)


# ---------------------------------------------------------------------------
# Cases
# ---------------------------------------------------------------------------

ARITH = ["add", "sub", "mul", "div", "floordiv", "mod"]
CMP = ["eq", "neq", "gt", "ge", "lt", "le"]
OPS = ARITH + CMP
ARITH_OK = set(NUMS) | {"n"}

# -- column x column --------------------------------------------------------
for op in OPS:
    for a in NUMS:
        for b in NUMS:
            if op in ("gt", "le"):
                continue
            case(f"cc/{op}/{a}/{b}", "t", [bin_(op, col(a), col(b))])
    if op not in ("add", "floordiv", "eq"):
        continue
    for a, b in [("n", "i32"), ("i32", "n"), ("n", "f32"), ("f32", "n"), ("n", "n"),
                 ("n", "i64"), ("f64", "n")]:
        case(f"cc/{op}/{a}/{b}", "t", [bin_(op, col(a), col(b))])
for op in ["eq", "lt"]:
    for a, b in [("s", "s"), ("b", "b"), ("d", "d"), ("dt", "dt"), ("d", "dt"),
                 ("dt", "d"), ("s", "b"), ("b", "s"), ("b", "i32"), ("b", "f64"),
                 ("d", "i32"), ("dt", "i64"), ("n", "s"), ("s", "n"), ("n", "b"),
                 ("s", "i32"), ("i32", "s"), ("b", "d"), ("s", "d"), ("s", "dt")]:
        case(f"cc/{op}/{a}/{b}", "t", [bin_(op, col(a), col(b))])
for op in ["add", "div", "floordiv"]:
    for a, b in [("b", "b"), ("b", "i32"), ("i32", "b"), ("s", "s"), ("s", "i32"),
                 ("i64", "s"), ("d", "d"), ("d", "i32"), ("dt", "dt"), ("dt", "i64"),
                 ("b", "n"), ("s", "n")]:
        case(f"cc/{op}/{a}/{b}", "t", [bin_(op, col(a), col(b))], restricted=True)
for op in ["and", "or"]:
    for a, b in [("b", "b"), ("b", "n"), ("n", "b"), ("n", "n"), ("s", "b"),
                 ("b", "s"), ("b", "i32"), ("i32", "b"), ("f64", "b"), ("f64", "f64"),
                 ("d", "d"), ("n", "s")]:
        case(f"cc/{op}/{a}/{b}", "t", [bin_(op, col(a), col(b))])
    for a, b in [("i32", "i32"), ("i64", "i64"), ("i32", "i64")]:
        case(f"cc/{op}/{a}/{b}", "t", [bin_(op, col(a), col(b))], restricted=True)
    for a, b in [("b", "d"), ("d", "b"), ("s", "d"), ("dt", "b"), ("dt", "dt")]:
        case(f"cc/{op}/{a}/{b}", "t", [bin_(op, col(a), col(b))])

# -- column x weak literal (Review Focus 5) ----------------------------------
WEAK = {
    "1": li(1), "3e9": li(3000000000), "2^40": li(1 << 40),
    "f1.5": lf(1.5), "f1e300": lf(1e300),
    "i32max": li(2147483647), "i32max+1": li(2147483648),
}
WEAK_EXTRA = {
    "0": li(0), "-3e9": li(-3000000000), "i32min": li(-2147483648),
    "i32min-1": li(-2147483649), "i64max": li(I64_MAX), "i64min": li(I64_MIN),
    "f0.0": lf(0.0), "f-0.0": lf(-0.0), "fnan": lf(nan), "finf": lf(inf),
    "f-1.5": lf(-1.5),
}
for op in OPS:
    for a in NUMS:
        if a in ("i64", "f64") and op in ("sub", "mod", "neq", "ge"):
            continue
        for lname in ["1", "3e9", "2^40", "f1.5", "f1e300"]:
            if lname == "2^40" and op not in ("add", "floordiv", "eq", "gt"):
                continue
            if lname == "f1e300" and op not in ("add", "mul", "div", "lt"):
                continue
            case(f"cw/{op}/{a}/{lname}", "t", [bin_(op, col(a), WEAK[lname])])
for op in ["add", "eq", "lt"]:
    for a in ["i32", "i64", "f32"]:
        for lname in ["i32max", "i32max+1"]:
            case(f"cw/{op}/{a}/{lname}", "t", [bin_(op, col(a), WEAK[lname])])
for op in ["add", "div", "eq"]:
    for a in ["i32", "f32"]:
        for lname, lnode in WEAK_EXTRA.items():
            if op == "div" and lname not in ("0", "f0.0", "fnan", "-3e9"):
                continue
            if op == "add" and a == "f32" and lname in ("0", "f0.0"):
                # polars' optimizer drops `x + 0`, so `-0.0 + 0` stays `-0.0`
                continue
            case(f"cw/{op}/{a}/{lname}", "t", [bin_(op, col(a), lnode)])
for op in ["sub", "div", "floordiv", "lt"]:
    for a in NUMS:
        for lname in ["1", "3e9", "f1.5"]:
            case(f"wc/{op}/{lname}/{a}", "t", [bin_(op, WEAK[lname], col(a))])
for op in ["eq", "lt", "add"]:
    for a in ["b", "s", "d", "dt", "n"]:
        for lname in ["1", "3e9", "f1.5"]:
            case(f"cw/{op}/{a}/{lname}", "t", [bin_(op, col(a), WEAK[lname])],
                 restricted=(op == "add" and a != "n"))

# -- column x strong literal --------------------------------------------------
STRONG = {
    "i32:1": lit("i32", 1), "i32:max": lit("i32", 2147483647),
    "i64:3e9": lit("i64", 3000000000),
    "f32:1.5": lit("f32", 1.5), "f64:1.5": lit("f64", 1.5),
    "f64:nan": lit("f64", nan),
}
for op in ["add", "div", "eq", "lt"]:
    for a in NUMS:
        for lname, lnode in STRONG.items():
            if op in ("div", "lt") and lname in ("i32:max", "f64:nan") and a in ("i64", "f64"):
                continue
            case(f"cs/{op}/{a}/{lname}", "t", [bin_(op, col(a), lnode)])
OTHER_STRONG = {
    "bool:true": lit("bool", True), "str:a": lit("str", "a"),
    "null": lit("null", None), "date:1": lit("date", 1),
    "datetime:5": lit("datetime[μs]", 5), "i32:1": STRONG["i32:1"],
    "str:emoji": lit("str", "\U0001F600"),
}
for op in ["eq", "lt"]:
    for a in ["b", "s", "d", "dt", "n"]:
        for lname, lnode in OTHER_STRONG.items():
            case(f"cs/{op}/{a}/{lname}", "t", [bin_(op, col(a), lnode)])
for a in NUMS:
    for lname in ["bool:true", "str:a", "null", "date:1"]:
        case(f"cs/add/{a}/{lname}", "t", [bin_("add", col(a), OTHER_STRONG[lname])],
             restricted=lname in ("bool:true", "str:a", "date:1"))
for a in ["n"]:
    for lname in ["i32:1", "null"]:
        case(f"cs/add/{a}/{lname}", "t", [bin_("add", col(a), OTHER_STRONG[lname])])
    case(f"cs/add/{a}/f64:1.5", "t", [bin_("add", col(a), STRONG["f64:1.5"])])

# -- literals alone and with literals -------------------------------------------
LIT_SOLO = {
    "int1": li(1), "int-1": li(-1), "int3e9": li(3000000000), "intmax": li(I64_MAX),
    "intmin": li(I64_MIN), "int0": li(0), "float1.5": lf(1.5), "float1": lf(1.0),
    "float1e20": lf(1e20), "float1e300": lf(1e300), "float-0": lf(-0.0),
    "floatnan": lf(nan), "floatinf": lf(inf), "float-inf": lf(-inf),
    "float0.1": lf(0.1), "float1e-7": lf(1e-7), "float1e15": lf(1e15),
    "float123456789.123456789": lf(123456789.123456789),
    "str": ls("a"), "str-uni": ls("\U0001F600｡"), "str-empty": ls(""),
    "str-quote": ls('a"b'), "bool-t": lb(True), "bool-f": lb(False),
    "null": lit("null", None),
    "i32": lit("i32", 5), "i32-neg": lit("i32", -5), "i32-min": lit("i32", -2147483648),
    "i64": lit("i64", 5), "i64-min": lit("i64", I64_MIN),
    "f32": lit("f32", 1.5), "f32-0.1": lit("f32", 0.1), "f32-1e20": lit("f32", 1e20),
    "f32-nan": lit("f32", nan), "f32-inf": lit("f32", inf), "f32--0": lit("f32", -0.0),
    "f64": lit("f64", 1.5), "f64-1e20": lit("f64", 1e20), "f64-1e-7": lit("f64", 1e-7),
    "f64-nan": lit("f64", nan), "f64--inf": lit("f64", -inf), "f64--0": lit("f64", -0.0),
    "f64-123456.789": lit("f64", 123456.789), "f64-0.333": lit("f64", 1 / 3),
    "bool": lit("bool", True), "str-lit": lit("str", "x y"),
    "date": lit("date", 19782), "date-neg": lit("date", -25567),
    "datetime": lit("datetime[μs]", 1709210096123456),
    "datetime-ms": lit("datetime[μs]", 1500000), "datetime-s": lit("datetime[μs]", 1000000),
    "datetime-neg": lit("datetime[μs]", -1),
}
for name, node in LIT_SOLO.items():
    case(f"lit/{name}", "t", [node])
    if name in ("int1", "float1.5", "str", "bool-t", "null", "i32", "date"):
        case(f"lit/{name}/z0", "z0", [node])
        case(f"lit/{name}/alias", "t", [alias(node, "x")])
        case(f"lit/{name}/is_null", "t", [is_null(node)])
for name in ["int1", "int3e9", "intmin", "float1.5", "float1e300"]:
    case(f"lit/{name}/neg", "t", [neg(LIT_SOLO[name])])
    case(f"lit/{name}/neg-neg", "t", [neg(neg(LIT_SOLO[name]))])
for name in ["i32", "i64", "f32", "f64", "i32-min", "i64-min"]:
    case(f"lit/{name}/neg", "t", [neg(LIT_SOLO[name])])
for name in ["bool-t", "bool-f", "bool", "null"]:
    case(f"lit/{name}/not", "t", [not_(LIT_SOLO[name])])
case("lit/str/neg", "t", [neg(ls("a"))])
case("lit/int1/not", "t", [not_(li(1))], restricted=True)

WEAKS2 = {
    "i1,i2": (li(1), li(2)), "i3e9,i2": (li(3000000000), li(2)),
    "i2,i0": (li(2), li(0)), "i-7,i2": (li(-7), li(2)), "i7,i-2": (li(7), li(-2)),
    "i1,f2.5": (li(1), lf(2.5)), "f1.5,i2": (lf(1.5), li(2)),
    "f1.5,f2.5": (lf(1.5), lf(2.5)), "f1,f0": (lf(1.0), lf(0.0)),
    "imax,i1": (li(I64_MAX), li(1)), "imin,i-1": (li(I64_MIN), li(-1)),
    "i2^62,i4": (li(1 << 62), li(4)),
}
for op in ["add", "sub", "mul", "div", "floordiv", "eq", "lt"]:
    for name, (a, b) in WEAKS2.items():
        case(f"ll/{op}/{name}", "t", [bin_(op, a, b)])
MIXED2 = {
    "i32:1,i2": (lit("i32", 1), li(2)), "i32:1,i3e9": (lit("i32", 1), li(3000000000)),
    "i2,i32:1": (li(2), lit("i32", 1)), "i64:1,i2": (lit("i64", 1), li(2)),
    "i32:1,f1.5": (lit("i32", 1), lf(1.5)), "f32:1.5,i2": (lit("f32", 1.5), li(2)),
    "f32:1.5,f1e300": (lit("f32", 1.5), lf(1e300)),
    "f64:1.5,i2": (lit("f64", 1.5), li(2)), "i32:1,i64:2": (lit("i32", 1), lit("i64", 2)),
    "i32:1,f32:2": (lit("i32", 1), lit("f32", 2.0)), "f32:1,f64:2": (lit("f32", 1.0), lit("f64", 2.0)),
    "null,i1": (lit("null", None), li(1)), "i1,null": (li(1), lit("null", None)),
    "null,f1.5": (lit("null", None), lf(1.5)), "i32:null,i1": (lit("i32", None), li(1)),
    "str:a,str:b": (lit("str", "a"), lit("str", "b")), "bool,bool": (lit("bool", True), lit("bool", False)),
    "date:1,date:2": (lit("date", 1), lit("date", 2)),
    "date:1,i1": (lit("date", 1), li(1)),
}
for op in ["add", "div", "eq", "lt"]:
    for name, (a, b) in MIXED2.items():
        restricted = op in ARITH and (
            name.startswith(("str", "bool", "date")))
        case(f"ls/{op}/{name}", "t", [bin_(op, a, b)], restricted=restricted)
for op in ["and", "or"]:
    for name, (a, b) in {"b,b": (lb(True), lb(False)), "b,null": (lb(True), lit("null", None)),
                         "null,b": (lit("null", None), lb(False)),
                         "b,col": (lb(True), col("b")), "col,b": (col("b"), lb(False)),
                         "null,col": (lit("null", None), col("b"))}.items():
        case(f"ll/{op}/{name}", "t", [bin_(op, a, b)])

# nested weak literals stay weak (polars folds them)
for name, node in {
    "(1+2)+i32": bin_("add", bin_("add", li(1), li(2)), col("i32")),
    "(3e9+2)+i32": bin_("add", bin_("add", li(3000000000), li(2)), col("i32")),
    "(-1)+i32": bin_("add", neg(li(1)), col("i32")),
    "i32+(-3e9)": bin_("add", col("i32"), neg(li(3000000000))),
    "(1*2.5)+f32": bin_("add", bin_("mul", li(1), lf(2.5)), col("f32")),
    "(1.5+1)+f32": bin_("add", bin_("add", lf(1.5), li(1)), col("f32")),
    "(1/2)+f32": bin_("add", bin_("div", li(1), li(2)), col("f32")),
    "(1.5/2.0)+f32": bin_("add", bin_("div", lf(1.5), lf(2.0)), col("f32")),
    "(1//2)+i32": bin_("add", bin_("floordiv", li(1), li(2)), col("i32")),
    "(7%4)+i32": bin_("add", bin_("mod", li(7), li(4)), col("i32")),
    "(1+2.5)+i32": bin_("add", bin_("add", li(1), lf(2.5)), col("i32")),
    "(imax+1)+i32": bin_("add", bin_("add", li(I64_MAX), li(1)), col("i32")),
    "i32+alias(1)": bin_("add", col("i32"), alias(li(5), "x")),
    "alias(3e9)+i32": bin_("add", alias(li(3000000000), "x"), col("i32")),
    "i32+cast(1,i64)": bin_("add", col("i32"), cast(li(1), "i64")),
    "i32+((1+2)==3)": bin_("add", col("i32"), bin_("eq", bin_("add", li(1), li(2)), li(3))),
    "f32+(-1e300)": bin_("add", col("f32"), neg(lf(1e300))),
    "f32*alias(1e300)": bin_("mul", col("f32"), alias(lf(1e300), "x")),
}.items():
    case(f"weak/{name}", "t", [node], restricted=name.endswith("==3)"))

# -- names, alias ---------------------------------------------------------------
case("name/col", "t", [col("i32")])
case("name/lit+col", "t", [bin_("add", li(1), col("i32"))])
case("name/col+lit", "t", [bin_("add", col("i32"), li(1))])
case("name/col+col", "t", [bin_("add", col("i64"), col("i32"))])
case("name/(lit+lit)+col", "t", [bin_("add", bin_("add", li(1), li(2)), col("i32"))])
case("name/-col", "t", [neg(col("i32"))])
case("name/-(a+b)", "t", [neg(bin_("add", col("i64"), col("i32")))])
case("name/~col", "t", [not_(col("b"))])
case("name/~(a>0)", "t", [not_(bin_("gt", col("i32"), li(0)))])
case("name/cast", "t", [cast(col("i32"), "f64")])
case("name/is_null", "t", [is_null(col("f32"))])
case("name/alias", "t", [alias(col("i32"), "z")])
case("name/alias-alias", "t", [alias(alias(col("i32"), "a"), "b")])
case("name/alias-in-lhs", "t", [bin_("add", alias(col("i32"), "a"), col("i64"))])
case("name/alias-in-rhs", "t", [bin_("add", col("i32"), alias(col("i64"), "zz"))])
case("name/alias-over-op", "t", [alias(bin_("mul", col("i32"), li(2)), "twice")])
case("name/alias-lit", "t", [alias(li(1), "one")])
case("name/lit-alias+col", "t", [bin_("add", alias(li(1), "x"), col("i32"))])
case("name/is_null-alias", "t", [is_null(alias(cast(col("i32"), "i32"), "x"))])
case("name/alias-empty", "t", [alias(col("i32"), "")])
case("name/alias-unicode", "t", [alias(col("i32"), "é\U0001F600")])
case("name/alias-same", "t", [alias(col("i32"), "i32")])
case("name/alias-swap", "t", [alias(col("i32"), "i64"), alias(col("i64"), "i32")])
case("name/col-quote", "t", [alias(col("i32"), 'a"b')])
case("name/two-lits", "t", [li(1), alias(li(2), "x")])
case("name/dup-col", "t", [col("i32"), col("i32")], variant=None)
case("name/dup-alias", "t", [col("i32"), alias(col("i64"), "i32")])
case("name/dup-lit", "t", [li(1), li(2)])
case("name/dup-expr", "t", [bin_("add", col("i32"), li(1)), col("i32")])
case("name/dup-alias2", "t", [alias(col("i32"), "q"), alias(col("i64"), "q"), col("s")])
case("name/missing", "t", [col("zz")])
case("name/missing-in-op", "t", [bin_("add", col("i32"), col("zz"))])
case("name/missing-in-lit-op", "t", [bin_("add", li(1), col("zz"))])
case("name/missing-case", "t", [col("I32")])
case("name/missing-z0", "z0", [col("a")])
case("name/missing-e0", "e0", [col("a")])
case("name/missing-second", "t", [col("i32"), col("zz")])
case("prec/select/missing-then-width", "t",
     [col("zz"), bin_("add", cols(["i32", "i64"]), cols(["i32", "i64", "f32"]))])
# select checks a name against the earlier ones right after the plain columns
# of the same expression; with_columns checks the names last
case("prec/select/dup-before-missing", "t", [col("i32"), col("i32"), col("zz")])
case("prec/select/missing-before-dup", "t", [col("zz"), col("i32"), col("i32")])
case("prec/with_columns/missing-before-dup", "t", [col("i32"), col("i32"), col("zz")], op="with_columns")
case("prec/select/z0-cols-before-col", "z0", [col("s"), cols(["qq"])])
# error precedence: every column is looked up and every name checked before
# any kernel runs
for _op in ("select", "with_columns"):
    case(f"prec/{_op}/kernel-then-missing", "t",
         [bin_("add", col("s"), li(1)), col("zz")], op=_op)
    case(f"prec/{_op}/dup-then-kernel", "t",
         [col("i32"), col("i32"), bin_("add", col("s"), li(1))], op=_op, variant="DuplicateColumn")
    # selector errors come before plain columns, whichever expression is first
    case(f"prec/{_op}/missing-then-cols-missing", "t", [col("zz"), cols(["qq"])], op=_op)
    # a selector with no column: the sibling is not looked at
    case(f"prec/{_op}/all-empty+missing", "z0", [bin_("add", all_, alias(col("i32"), "x"))], op=_op)
    if _op == "select":
        case("prec/select/missing+cols", "z0", [bin_("add", col("f32"), cols(["i32", "i64"]))])

# -- cols / all ----------------------------------------------------------------
NUMC = ["i32", "i64", "f32", "f64"]
case("cols/basic", "t", [cols(["i32", "i64"])])
case("cols/single", "t", [cols(["i32"])])
case("cols/empty", "t", [cols([])])
case("cols/empty-z0", "z0", [cols([])])
case("cols/empty+col", "t", [bin_("add", cols([]), col("i32"))])
case("cols/empty+lit", "t", [bin_("add", cols([]), li(1))])
case("cols/empty+lit2", "t", [cols([]), li(1)])
case("cols/order", "t", [cols(["f32", "i32", "i64"])])
case("cols/dup-names", "t", [cols(["i32", "i32", "i64"])])
case("cols/+1", "t", [bin_("add", cols(["i32", "i64", "f32", "f64"]), li(1))])
case("cols/*1.5", "t", [bin_("mul", cols(["i32", "i64", "f32", "f64"]), lf(1.5))])
case("cols/3e9", "t", [bin_("add", cols(["i32", "i64", "f32"]), li(3000000000))])
case("cols/lit+", "t", [bin_("add", li(1), cols(["i32"]))])
case("cols/lit+2", "t", [bin_("add", li(1), cols(["i32", "i64"]))])
case("cols/zip", "t", [bin_("add", cols(["i32", "i64"]), cols(["i64", "i32"]))])
case("cols/zip-names", "t", [bin_("add", cols(["i64", "i32"]), cols(["i32", "i64"]))])
case("cols/zip3", "t", [bin_("add", cols(["i32", "i64"]), cols(["i64", "i32", "f32"]))])
case("cols/zip-cmp", "t", [bin_("lt", cols(["i32", "i64"]), cols(["i64", "f64"]))])
case("cols/x-col", "t", [bin_("add", cols(["i32", "i64"]), col("i32"))])
case("cols/col-x", "t", [bin_("add", col("i32"), cols(["i32", "i64"]))])
case("cols/col-x-alias", "t", [bin_("add", col("f32"), alias(cols(["i32", "i64"]), "q"))])
case("cols/self", "t", [bin_("mul", cols(["i32", "i64"]), cols(["i32", "i64"]))])
case("cols/alias", "t", [alias(cols(["i32", "i64"]), "z")])
case("cols/alias-single", "t", [alias(cols(["i32"]), "z")])
case("cols/cast", "t", [cast(cols(["i32", "i64"]), "f64")])
case("cols/cast-ns", "t", [cast(cols(["i64"]), "i32", False)])
case("cols/is_null", "t", [is_null(cols(["i32", "s", "n"]))])
case("cols/neg", "t", [neg(cols(["i32", "i64", "f32"]))])
case("cols/not", "t", [not_(cols(["b"]))])
case("cols/missing", "t", [cols(["i32", "zz"])])
case("cols/missing-first", "t", [cols(["zz", "yy"])])
case("cols/missing-z0", "z0", [cols(["a"])])
case("cols/+cols-other", "t", [cols(["i32"]), cols(["i64"])])
case("cols/overlap", "t", [cols(["i32", "i64"]), cols(["i64", "f32"])])
case("cols/and-all", "t", [bin_("lt", cols(["i32", "i64"]), li(5)), col("s")])
case("cols/str", "t", [cols(["s", "b"])])
case("cols/quoted", "t", [alias(cols(["i32"]), "q'q")])
case("cols/restricted", "t", [bin_("add", cols(["i32", "s"]), li(1))], restricted=True)
case("all/t", "t", [all_])
case("all/num", "num", [all_])
case("all/num+1", "num", [bin_("add", all_, li(1))])
case("all/num+3e9", "num", [bin_("add", all_, li(3000000000))])
case("all/num*1.5", "num", [bin_("mul", all_, lf(1.5))])
case("all/num-self", "num", [bin_("sub", all_, all_)])
case("all/num-neg", "num", [neg(all_)])
case("all/num-cast", "num", [cast(all_, "f64")])
case("all/num-alias", "num", [alias(all_, "x")])
case("all/num-is_null", "num", [is_null(all_)])
case("all/num+lit", "num", [all_, li(1)])
case("all/num+lit-alias", "num", [all_, alias(li(1), "one")])
case("all/num+all", "num", [all_, all_])
case("all/num+col", "num", [all_, col("i32")])
case("all/num+col-alias", "num", [all_, alias(col("i32"), "q")])
case("all/num+ops", "num", [bin_("add", all_, col("i32"))])
case("all/num-lt", "num", [bin_("lt", all_, li(1))])
case("all/z0", "z0", [all_])
case("all/z0+lit", "z0", [all_, li(1)])
case("all/z0+op", "z0", [bin_("add", all_, li(1))])
case("all/e0", "e0", [all_])
case("all/e0+lit", "e0", [all_, li(1)])
case("all/e0+op", "e0", [bin_("add", all_, li(1))], restricted=True)
case("all/t+1", "t", [bin_("add", all_, li(1))], restricted=True)
case("all/t-is_null", "t", [is_null(all_)])
case("all/t-cast-str", "t", [cast(all_, "str")])

# -- select / with_columns shapes ------------------------------------------------
for table in ["t", "e0", "z0"]:
    sfx = table
    case(f"shape/select-lit/{sfx}", table, [li(1)])
    case(f"shape/select-lit-lit/{sfx}", table, [li(1), alias(li(2), "x")])
    case(f"shape/select-lit-lit-lit/{sfx}", table, [li(1), alias(ls("x"), "x"), alias(lit("null", None), "y")])
    case(f"shape/select-empty/{sfx}", table, [])
    case(f"shape/wc-empty/{sfx}", table, [], op="with_columns")
    case(f"shape/wc-lit/{sfx}", table, [li(1)], op="with_columns")
    case(f"shape/wc-lit-lit/{sfx}", table, [li(1), alias(ls("x"), "x")], op="with_columns")
    case(f"shape/wc-lit-null/{sfx}", table, [lit("null", None)], op="with_columns")
    case(f"shape/wc-lit-alias/{sfx}", table, [alias(lf(1.5), "x"), alias(lit("i32", 4), "y")], op="with_columns")
for table in ["t", "e0"]:
    case(f"shape/select-col-lit/{table}", table, [col("i32"), li(1)])
    case(f"shape/select-lit-col/{table}", table, [li(1), col("i32")])
    case(f"shape/select-col-lit-col/{table}", table, [col("i32"), alias(li(7), "k"), col("s")])
    case(f"shape/select-lit-expr/{table}", table, [bin_("add", col("i32"), li(1)), alias(lf(2.5), "k")])
    case(f"shape/select-reorder/{table}", table, [col("s"), col("i32")])
    case(f"shape/select-is_null-lit/{table}", table, [is_null(li(1)), alias(is_not_null(col("i32")), "nn")])
    case(f"shape/select-lit-cmp/{table}", table, [bin_("lt", li(1), li(2)), alias(col("b"), "bb")])
    case(f"shape/select-lit-op-col/{table}", table, [bin_("add", li(1), col("i32"))])
    case(f"shape/select-lit+lit/{table}", table, [bin_("add", li(1), li(2))])
    case(f"shape/wc-replace/{table}", table, [bin_("add", col("i32"), li(1))], op="with_columns")
    case(f"shape/wc-replace-mid/{table}", table,
         [alias(bin_("mul", col("i64"), li(2)), "i32"), alias(ls("x"), "new")], op="with_columns")
    case(f"shape/wc-append/{table}", table, [alias(bin_("add", col("i32"), col("i64")), "sum")], op="with_columns")
    case(f"shape/wc-append-2/{table}", table,
         [alias(li(1), "one"), alias(bin_("add", col("i32"), li(1)), "i32p")], op="with_columns")
    case(f"shape/wc-replace-all/{table}", table,
         [alias(li(0), c) for c in ["i32", "s", "n"]], op="with_columns")
    case(f"shape/wc-cols/{table}", table, [bin_("mul", cols(["i32", "i64"]), li(2))], op="with_columns")
    case(f"shape/wc-cast/{table}", table, [cast(col("i32"), "f64"), cast(col("i64"), "i32", False)], op="with_columns")
    case(f"shape/wc-dup/{table}", table, [alias(col("i32"), "q"), alias(col("i64"), "q")],
         op="with_columns", variant="DuplicateColumn")
    case(f"shape/wc-dup-col/{table}", table, [col("i32"), col("i32")], op="with_columns",
         variant="DuplicateColumn")
    case(f"shape/wc-missing/{table}", table, [col("zz")], op="with_columns")
    case(f"shape/wc-swap/{table}", table, [alias(col("i32"), "i64"), alias(col("i64"), "i32")], op="with_columns")
    case(f"shape/wc-self-ref/{table}", table,
         [alias(bin_("add", col("i32"), li(1)), "i32"), alias(bin_("add", col("i32"), li(2)), "i32b")], op="with_columns")
case("shape/wc-all/num", "num", [all_], op="with_columns")
case("shape/wc-all+1/num", "num", [bin_("add", all_, li(1))], op="with_columns")
case("shape/wc-all+lit/num", "num", [all_, li(1)], op="with_columns")
case("shape/wc-all-alias/num", "num", [alias(all_, "x")], op="with_columns", variant="DuplicateColumn")
case("shape/z0-select-all-lit", "z0", [all_, alias(li(1), "k")])
case("shape/z0-select-all-and-lit-expr", "z0", [bin_("add", li(1), li(2))])
case("shape/num-select-lit-first", "num", [alias(li(1), "k"), all_])
case("shape/num-select-1-row", "num", [alias(li(1), "k")])

# -- cast ----------------------------------------------------------------------
for src in ["i32", "i64", "f32", "f64", "s", "b", "d", "dt", "n"]:
    for dt in DTYPE_NAMES:
        for strict in (True, False):
            if src in ("b", "d", "dt", "n", "f32") and dt not in ("i64", "str", "f64", "bool", "date"):
                continue
            case(f"cast/{src}->{dt}/{'strict' if strict else 'lenient'}", "t",
                 [cast(col(src), dt, strict)])
case("cast/lit-int->f64", "t", [cast(li(1), "f64")])
case("cast/lit-int->i32", "t", [cast(li(3000000000), "i32", False)])
case("cast/lit-str->i32-lenient", "t", [cast(ls("a"), "i32", False)])
case("cast/lit-float->i32", "t", [cast(lf(1.9), "i32")])
case("cast/lit-null->i32", "t", [cast(lit("null", None), "i32")])
case("cast/cast-cast", "t", [cast(cast(col("i32"), "f32"), "i64")])
case("cast/in-op", "t", [bin_("add", cast(col("i32"), "i64"), col("i32"))])
case("cast/in-op-lit", "t", [bin_("add", cast(col("i32"), "f32"), li(1))])
case("cast/in-op-lit-f", "t", [bin_("mul", cast(col("i32"), "f32"), lf(1e300))])
case("cast/lit-cast-op", "t", [bin_("add", col("i32"), cast(li(1), "i64"))])
case("cast/lit-cast-op2", "t", [bin_("add", col("i32"), cast(li(1), "f32"))])
case("cast/alias", "t", [alias(cast(col("i32"), "f64"), "x")])
case("cast/z0-lit", "z0", [cast(li(1), "f64")])
case("cast/e0", "e0", [cast(col("i32"), "f64"), cast(col("s"), "i64", False)])
case("cast/i64-big", "t", [cast(col("i64"), "i32")])
case("cast/f64-nan->i64", "t", [cast(col("f64"), "i64")])
case("cast/f64-nan->i64-lenient", "t", [cast(col("f64"), "i64", False)])
case("cast/s->f64", "t", [cast(col("s"), "f64")])

# -- is_null / is_not_null -----------------------------------------------------------
for c in ALL:
    case(f"null/is_null/{c}", "t", [is_null(col(c))])
    case(f"null/is_not_null/{c}", "t", [is_not_null(col(c))])
    case(f"null/is_null/{c}/e0", "e0", [is_null(col(c))])
case("null/is_null-op", "t", [is_null(bin_("add", col("i32"), li(1)))])
case("null/is_null-cmp", "t", [is_null(bin_("lt", col("f32"), col("i32")))])
case("null/not-is_null", "t", [not_(is_null(col("i32")))])
case("null/is_null-nan", "t", [is_null(col("f64")), alias(bin_("eq", col("f64"), col("f64")), "eq")])
case("null/is_null-lit", "t", [is_null(lit("null", None)), alias(is_not_null(lit("null", None)), "nn")])
case("null/is_null-cols", "t", [is_not_null(cols(["i32", "n"]))])
case("null/is_null-z0", "z0", [is_null(li(1))])

# -- unary ------------------------------------------------------------------------------
for c in ALL:
    case(f"unary/neg/{c}", "t", [neg(col(c))], restricted=False)
    case(f"unary/not/{c}", "t", [not_(col(c))], restricted=(c in ("i32", "i64")))
case("unary/neg-neg", "t", [neg(neg(col("i32")))])
case("unary/neg-op", "t", [neg(bin_("add", col("i32"), li(1)))])
case("unary/neg-in-op", "t", [bin_("add", neg(col("i32")), neg(col("i64")))])
case("unary/not-cmp", "t", [not_(bin_("lt", col("i32"), li(0)))])
case("unary/not-and", "t", [not_(bin_("and", col("b"), col("b")))])
case("unary/and-cmp", "t", [bin_("and", bin_("gt", col("i32"), li(0)), bin_("lt", col("i64"), li(3)))])
case("unary/or-cmp", "t", [bin_("or", bin_("gt", col("i32"), li(0)), bin_("lt", col("i64"), li(3)))])
case("unary/and-lit", "t", [bin_("and", col("b"), lb(True)), alias(bin_("or", col("b"), lb(False)), "o"),
                            alias(bin_("and", col("b"), lb(False)), "a2"), alias(bin_("or", col("b"), lb(True)), "o2")])
case("unary/not-n", "t", [not_(col("n"))])
case("unary/not-lit", "t", [not_(lb(True))])

# -- Review Focus 4 / 5 named cases ----------------------------------------------------------
case("rf5/i32+3e9", "t", [bin_("add", col("i32"), li(3000000000))])
case("rf5/i32==2^40", "t", [bin_("eq", col("i32"), li(1 << 40))])
case("rf5/i32!=2^40", "t", [bin_("neq", col("i32"), li(1 << 40))])
case("rf5/i32<2^40", "t", [bin_("lt", col("i32"), li(1 << 40))])
case("rf5/f32*1e300", "t", [bin_("mul", col("f32"), lf(1e300))])
case("rf5/f32+3e9", "t", [bin_("add", col("f32"), li(3000000000))])
case("rf5/i32*1.5", "t", [bin_("mul", col("i32"), lf(1.5))])
case("rf5/i32-i64max", "t", [bin_("sub", col("i32"), li(I64_MAX))])
case("rf5/i64+i64max", "t", [bin_("add", col("i64"), li(I64_MAX))])
case("rf4/select-col-lit/e0", "e0", [col("i32"), li(1)])
case("rf4/wc-lit/e0", "e0", [li(1)], op="with_columns")
case("rf4/select-lit/z0", "z0", [li(1)])
case("rf4/select-lit-lit/e0", "e0", [li(1), alias(li(2), "k")])
case("rf4/select-lit-expr/e0", "e0", [alias(li(1), "k"), bin_("add", col("i32"), li(1))])


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def mb_cases_file():
    lines = ["// 由 docs/golden/scripts/expr.py 生成，勿手改", ""]
    chunk = 60
    parts = [MB[i:i + chunk] for i in range(0, len(MB), chunk)]
    for pi, part in enumerate(parts):
        lines += ["///|", f"fn golden_expr_cases_{pi}(m : Map[String, Array[@pl.Expr]]) -> Unit {{"]
        for cid, exprs in part:
            lines.append(f"  m[{mb_str(cid)}] = [{', '.join(exprs)}]")
        lines += ["}", ""]
    lines += ["///|", "/// Every case id with the expressions it builds.",
              "fn golden_expr_cases() -> Map[String, Array[@pl.Expr]] {",
              "  let m : Map[String, Array[@pl.Expr]] = Map([])"]
    for pi in range(len(parts)):
        lines.append(f"  golden_expr_cases_{pi}(m)")
    lines += ["  m", "}", ""]
    path = os.path.join(_repo_root(), "src", "pl", "expr_golden_cases_test.mbt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


doc = {
    "tables": {name: encode_frame(df) for name, df in TABLES.items()},
    "cases": CASES,
}
emit("expr", doc, compact=True)
mb_cases_file()
kinds = {"result": 0, "error": 0, "restricted": 0}
for c in CASES:
    for k in kinds:
        if k in c:
            kinds[k] += 1
print(f"{len(CASES)} cases", kinds, "known_diff:", sum(1 for c in CASES if "known_diff" in c))
