"""Generates the golden data of the sequence operations, `str()` and `dt()` on
expressions and of `DataFrame::fill_null_strategy` (docs/golden/expr_seq.json,
src/pl/golden_expr_seq_data_test.mbt) and the MoonBit expressions of every
expression case (src/pl/expr_seq_cases_test.mbt).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/expr_seq.py

It builds on `expr_agg.py` (T8), whose part before its first case is executed
here, and so on `expr.py` (T7): tables, expression trees, renderers, `case`,
the meaning of `result`, `error`, `restricted`, `known_diff` are the same (see
those docstrings and docs/golden/known-diffs/expr_seq.md).

The file is `{"tables", "inputs", "cases", "frame_cases"}` (compact layout).
`cases` are expression cases (a table, `select` or `with_columns`, the
expressions); `frame_cases` are `df.fill_null(strategy=..., limit=...)` cases
(`table`, `strategy`, optional `limit`, `result` or `error` + `message`).
Extra tables: `q` (ten rows of every type, with runs of nulls), `st` (strings),
`tm` (dates and datetimes), `qn` (the number columns of `q`), `qs` (`q` without
the Boolean, String and Null columns).

Nodes added to the trees:
  ("shift", x, n, fill)  fill: None or [dtype, value] (a strongly typed literal)
  ("diff", x, n)         ("cum", op, x, reverse)    op: sum min max prod count
  ("rank", x, method, descending)   ("reverse", x)
  ("fills", x, strategy, limit)
  ("str", op, x, args)   op: contains starts_with ends_with to_lowercase
                         to_uppercase len_chars len_bytes replace replace_all
                         strip_chars strip_chars_start strip_chars_end
  ("dt", op, x)          op: year month day weekday ordinal_day hour minute second
"""
import json
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

# -- the shared part of expr_agg.py (which shares that of expr.py) -----------------
_src = open(os.path.join(HERE, "expr_agg.py"), encoding="utf-8").read()
_prefix = _src[: _src.index("SIMPLE = [")]
A = {"__name__": "expr_agg_prefix", "__file__": os.path.join(HERE, "expr_agg.py")}
exec(compile(_prefix, os.path.join(HERE, "expr_agg.py"), "exec"), A)
_ns = A["_ns"]

pl = A["pl"]
emit = A["emit"]
encode_series = A["encode_series"]
series_from_spec = A["series_from_spec"]
encode_frame = A["encode_frame"]
to_ours = A["to_ours"]
_repo_root = A["_repo_root"]
TABLES = A["TABLES"]
CASES = A["CASES"]
MB = A["MB"]
col, cols, all_ = A["col"], A["cols"], A["all_"]
li, lf, ls, lb, lit = A["li"], A["lf"], A["ls"], A["lb"], A["lit"]
bin_, neg, not_, alias, cast = A["bin_"], A["neg"], A["not_"], A["alias"], A["cast"]
is_null, is_not_null = A["is_null"], A["is_not_null"]
agg, fill, fn, isin = A["agg"], A["fill"], A["fn"], A["isin"]
when_ = A["when_"]
N = A["N"]
mb_str, mb_float, mb_i64, mb_i32 = A["mb_str"], A["mb_float"], A["mb_i64"], _ns["mb_i32"]
py_float = A["py_float"]
lit_pl, lit_py = _ns["lit_pl"], _ns["lit_py"]
nan, inf = A["nan"], A["inf"]
I64_MAX, I64_MIN = A["I64_MAX"], A["I64_MIN"]
INPUTS = A["INPUTS"]
input_series = A["input_series"]
VARIANTS = dict(_ns["VARIANTS"])
# Python errors that have no variant of their own (M2 error mapping): the
# library reports them as `InvalidOperation`; `polars_error` keeps the class
PY_ERRORS = {"ValueError": "InvalidOperation", "OverflowError": "InvalidOperation"}
IDS = A["IDS"]
run = _ns["run"]
schema_text = _ns["schema_text"]
_prev = {k: A[k] for k in ("to_pl", "to_py", "to_mb", "strengthen", "pure_weak")}

# -- tables ------------------------------------------------------------------------
Q = {
    "i32": [None, 2147483647, 1, None, None, 4, None, -7, None, 9],
    "i64": [3, None, I64_MAX, 1, None, None, -2, None, 5, None],
    "f32": [None, 0.5, nan, None, -inf, None, -0.0, 0.0, None, 3.0e38],
    "f64": [1.0, None, None, nan, 2.5, None, -0.0, None, inf, 4.0],
    "s": ["b", None, None, "｡", "\U0001F600", None, "", "Z", None, "a"],
    "b": [None, True, None, None, False, True, None, False, None, None],
    "d": [None, 0, 19782, None, None, -25567, None, 1, None, 5],
    "dt": [0, None, None, 1709210096123456, -1, None, None, 86399999999, None, 6],
    "n": [None] * 10,
}
DT_OF = A["DT_OF"]
T = A["T"]
QDF = pl.DataFrame([series_from_spec(c, DT_OF[c], v) for c, v in Q.items()])
TABLES["q"] = QDF
TABLES["qn"] = QDF.select(["i32", "i64", "f32", "f64"])
TABLES["qs"] = QDF.select(["i32", "i64", "f32", "f64", "d", "dt"])
TABLES["r1"] = T.head(1)
ST = {
    "s": ["  Hello World  ", "abc", None, "", "ǅ ß İ Σ", "x.y*z", "ÀÉ àé", "\t tab\n",
          "｡\U0001F600a", "AAbb", "a1 b22 c333", "xxhixx"],
    "u": ["cat", "dog", "x", None, "ab", "aXc", " ", "a.c", "Cat dog", "bird", "", "abcabc"],
    "i32": [1, None, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    "d": [0, None, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    "n": [None] * 12,
    "b": [True, None, False, True, False, True, False, True, False, True, False, True],
}
STDT = {"s": "str", "u": "str", "i32": "i32", "d": "date", "n": "null", "b": "bool"}
TABLES["st"] = pl.DataFrame([series_from_spec(c, STDT[c], v) for c, v in ST.items()])
# the values of the `str` is_in input ("a", "｡", "", a smiley) and others, so that
# every entry of that input decides at least one result
TABLES["sa"] = pl.DataFrame([series_from_spec("s", "str", ["A", "a", "", None, "｡", "\U0001F600", "x"])])
TM = {
    "d": [0, -1, 19782, None, -25567, 11016, 2932896, -719528, 60, 59, 95026236, -96465292],
    "dt": [0, -1, 1709210096123456, None, 86399999999, 951782400000000, -62135596800000000,
           253402300799999999, 3_599_999_999, -3_600_000_000, 59_999_999, 1_000_000_000_000],
    "i32": [1, None, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    "s": ["a"] * 12,
    "n": [None] * 12,
}
TMDT = {"d": "date", "dt": "datetime[μs]", "i32": "i32", "s": "str", "n": "null"}
TABLES["tm"] = pl.DataFrame([series_from_spec(c, TMDT[c], v) for c, v in TM.items()])

# -- constructors ---------------------------------------------------------------------
shift = lambda x, n, fillv=None: N(("shift", x, n, fillv))
diff = lambda x, n=1: N(("diff", x, n))
cum = lambda op, x, rev=False: N(("cum", op, x, rev))
rank = lambda x, method="average", desc=False: N(("rank", x, method, desc))
reverse = lambda x: N(("reverse", x))
fills = lambda x, strategy, limit=None: N(("fills", x, strategy, limit))
st = lambda op, x, **args: N(("str", op, x, args))
dtf = lambda op, x: N(("dt", op, x))
NEW = {"shift", "diff", "cum", "rank", "reverse", "fills", "str", "dt"}

MB_RANK = {"average": "Average", "min": "Min", "max": "Max", "dense": "Dense", "ordinal": "Ordinal"}
MB_STRAT = {"forward": "Forward", "backward": "Backward", "min": "Min", "max": "Max",
            "mean": "Mean", "zero": "Zero", "one": "One"}


def anyv_mb(dt, v):
    if dt == "bool":
        return f"@pl.AnyValue::Boolean({'true' if v else 'false'})"
    if dt == "i32":
        return f"@pl.AnyValue::Int32({mb_i32(v)})"
    if dt == "i64":
        return f"@pl.AnyValue::Int64({mb_i64(v)})"
    if dt == "f32":
        return f"@pl.AnyValue::Float32({mb_float(v)})"
    if dt == "f64":
        return f"@pl.AnyValue::Float64({mb_float(v)})"
    if dt == "str":
        return f"@pl.AnyValue::String({mb_str(v)})"
    if dt == "date":
        return f"@pl.AnyValue::Date({mb_i32(v)})"
    if dt == "datetime[μs]":
        return f"@pl.AnyValue::Datetime({mb_i64(v)})"
    raise ValueError(dt)


def args_py(args):
    return ", ".join(f"{k}={v!r}" if k != "_pos" else "" for k, v in args.items())


def str_call_py(op, args):
    """Python arguments of a `str` method."""
    if op == "contains":
        return f"{args['pattern']!r}, literal={args.get('literal', False)}"
    if op in ("starts_with", "ends_with"):
        return repr(args.get("affix"))
    if op in ("replace", "replace_all"):
        return f"{args['pattern']!r}, {args['value']!r}, literal={args.get('literal', False)}"
    if op.startswith("strip_chars"):
        return "" if args.get("chars") is None else repr(args["chars"])
    return ""


def str_call_pl(op, args):
    if op == "contains":
        return (args["pattern"],), {"literal": args.get("literal", False)}
    if op in ("starts_with", "ends_with"):
        return (args["affix"],), {}
    if op in ("replace", "replace_all"):
        return (args["pattern"], args["value"]), {"literal": args.get("literal", False)}
    if op.startswith("strip_chars"):
        return ((args["chars"],) if args.get("chars") is not None else ()), {}
    return (), {}


def str_call_mb(op, args):
    if op == "contains":
        lit_ = ", literal=true" if args.get("literal") else ""
        return f"({mb_str(args['pattern'])}{lit_})"
    if op in ("starts_with", "ends_with"):
        return f"({mb_str(args['affix'])})"
    if op in ("replace", "replace_all"):
        lit_ = ", literal=true" if args.get("literal") else ""
        return f"({mb_str(args['pattern'])}, {mb_str(args['value'])}{lit_})"
    if op.startswith("strip_chars"):
        return "()" if args.get("chars") is None else f"(characters={mb_str(args['chars'])})"
    return "()"


def to_pl(n):
    k = n[0]
    if k not in NEW:
        return _prev["to_pl"](n)
    if k == "shift":
        x = to_pl(n[1])
        if n[3] is None:
            return x.shift(n[2])
        return x.shift(n[2], fill_value=lit_pl(n[3][0], n[3][1]))
    if k == "diff":
        return to_pl(n[1]).diff(n[2])
    if k == "cum":
        return getattr(to_pl(n[2]), "cum_" + n[1])(reverse=n[3])
    if k == "rank":
        return to_pl(n[1]).rank(method=n[2], descending=n[3])
    if k == "reverse":
        return to_pl(n[1]).reverse()
    if k == "fills":
        return to_pl(n[1]).fill_null(strategy=n[2], limit=n[3])
    if k == "str":
        a, kw = str_call_pl(n[1], n[3])
        return getattr(to_pl(n[2]).str, n[1])(*a, **kw)
    if k == "dt":
        return getattr(to_pl(n[2]).dt, n[1])()
    raise ValueError(k)


def to_py(n):
    k = n[0]
    if k not in NEW:
        return _prev["to_py"](n)
    if k == "shift":
        f = "" if n[3] is None else f", fill_value={lit_py(n[3][0], n[3][1])}"
        return f"{to_py(n[1])}.shift({n[2]}{f})"
    if k == "diff":
        return f"{to_py(n[1])}.diff({n[2]})"
    if k == "cum":
        return f"{to_py(n[2])}.cum_{n[1]}(reverse={n[3]})"
    if k == "rank":
        return f"{to_py(n[1])}.rank(method={n[2]!r}, descending={n[3]})"
    if k == "reverse":
        return f"{to_py(n[1])}.reverse()"
    if k == "fills":
        return f"{to_py(n[1])}.fill_null(strategy={n[2]!r}, limit={n[3]})"
    if k == "str":
        return f"{to_py(n[2])}.str.{n[1]}({str_call_py(n[1], n[3])})"
    if k == "dt":
        return f"{to_py(n[2])}.dt.{n[1]}()"
    raise ValueError(k)


def to_mb(n):
    k = n[0]
    if k not in NEW:
        return _prev["to_mb"](n)
    if k == "shift":
        f = "" if n[3] is None else f", fill_value={anyv_mb(n[3][0], n[3][1])}"
        return f"{to_mb(n[1])}.shift(n={mb_i32(n[2])}{f})"
    if k == "diff":
        return f"{to_mb(n[1])}.diff(n={mb_i32(n[2])})"
    if k == "cum":
        r = ", reverse=true" if n[3] else ""
        return f"{to_mb(n[2])}.cum_{n[1]}({r[2:]})"
    if k == "rank":
        d = ", descending=true" if n[3] else ""
        return f"{to_mb(n[1])}.rank(method_=@pl.RankMethod::{MB_RANK[n[2]]}{d})"
    if k == "reverse":
        return f"{to_mb(n[1])}.reverse()"
    if k == "fills":
        lim = "" if n[3] is None else f", limit={n[3]}"
        return f"{to_mb(n[1])}.fill_null_strategy(@pl.FillStrategy::{MB_STRAT[n[2]]}{lim})"
    if k == "str":
        return f"{to_mb(n[2])}.str().{n[1]}{str_call_mb(n[1], n[3])}"
    if k == "dt":
        return f"{to_mb(n[2])}.dt().{n[1]}()"
    raise ValueError(k)


def pure_weak_ext(n):
    if n[0] in NEW:
        return False
    return _prev["pure_weak"](n)


_ns["to_pl"], _ns["to_py"], _ns["to_mb"] = to_pl, to_py, to_mb
A["to_pl"], A["to_py"], A["to_mb"] = to_pl, to_py, to_mb
_ns["pure_weak"] = A["pure_weak"] = pure_weak_ext
_case = A["case"]


# polars evaluates the expressions of a `select` and the columns of a frame in
# parallel. With two different failures the error it reports changes from run to
# run, so these inputs have no single expected error. They are not generated (the
# list was found by running every error case hundreds of times; set
# EXPR_SEQ_CHECK_FLAKY=1 to repeat that check, it takes a few minutes). See
# docs/golden/known-diffs/expr_seq.md.
FLAKY_CASES = {
    "sel/all-fills-mean-mixed", "sel/all-cum_sum-mixed", "str/all", "dt/all",
    "dt/error-order", "dt/error-order2",
}
FLAKY_FRAME_CASES = {"frame/q/mean", "frame/q/one", "frame/t/mean", "frame/t/one"}
CHECK_FLAKY = os.environ.get("EXPR_SEQ_CHECK_FLAKY") == "1"
CHECK_RUNS = 200
UNSTABLE = set()


def case(cid, table, nodes, regex=None, **kw):
    """`regex`: the pattern of a bad-regex case; the library names it in the
    message (spec 5.6) while polars' first line does not."""
    if cid in FLAKY_CASES and not CHECK_FLAKY:
        return
    before = len(CASES)
    try:
        for n in nodes:
            to_pl(n)
    except BaseException as e:  # noqa: BLE001
        # polars refuses while the expression is built (a Python error): there
        # is no `str(expr)`; the library reports it when the expression is used
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        name = type(e).__name__
        var = VARIANTS.get(name, name)
        want = kw.get("variant", PY_ERRORS.get(name))
        rec = {"id": cid,
               "polars": f"{table}.{kw.get('op', 'select')}([{', '.join(to_py(n) for n in nodes)}])",
               "build_error": True, "str": []}
        if want is not None and want != var:
            rec["polars_error"] = name
            var = want
        rec["error"] = var
        rec["message"] = str(e).split("\n")[0]
        if table != "t":
            rec["table"] = table
        if kw.get("op", "select") != "select":
            rec["op"] = kw["op"]
        _ns["register"](rec, nodes)
        return
    _case(cid, table, nodes, **kw)
    if CHECK_FLAKY and len(CASES) > before and "error" in CASES[-1]:
        df, op = TABLES[table], kw.get("op", "select")
        for _ in range(CHECK_RUNS):
            _, err = run(df, op, nodes)
            if err is None or err[2] != CASES[-1]["message"]:
                UNSTABLE.add(cid)
                break
    if regex is not None and len(CASES) > before:
        rec = CASES[-1]
        if rec.get("error") == "ComputeError" and rec["message"] == "regex error: regex parse error:":
            rec["polars_message"] = rec["message"]
            rec["message"] = f'{rec["message"]} "{regex}"'


DTS = list(Q)  # i32 i64 f32 f64 s b d dt n
FILLV = {"bool": True, "i32": 99, "i64": -5, "f32": 1.5, "f64": 2.5, "str": "x",
         "date": 100, "datetime[μs]": 1000000}

# ---------------------------------------------------------------------------
# shift, diff
# ---------------------------------------------------------------------------
for tbl, cs in [("q", DTS), ("t", ["i32", "f64", "s", "b"])]:
    for c in cs:
        for n in [1, -2, 0, 20]:
            case(f"shift/{tbl}/{c}/{n}", tbl, [shift(col(c), n)])
        for n in ([1, 2, -1] if tbl == "q" else [1, 2]):
            case(f"diff/{tbl}/{c}/{n}", tbl, [diff(col(c), n)], restricted=(c in ("d", "dt")))
for c in DTS:
    for fdt in sorted({DT_OF[c] if c != "n" else "i32", "i64", "str", "date"}):
        case(f"shift-fill/q/{c}/{fdt}", "q", [shift(col(c), 1, [fdt, FILLV[fdt]])])
    case(f"shift-fill/q/{c}/back", "q", [shift(col(c), -3, [DT_OF[c], FILLV[DT_OF[c]]])]
         if c != "n" else [shift(col(c), -3, ["i32", 7])])
for tbl in ["e0", "z0"]:
    for c in (["i32", "s", "n"] if tbl == "e0" else []):
        case(f"shift/{tbl}/{c}", tbl, [shift(col(c), 1)])
        case(f"diff/{tbl}/{c}", tbl, [diff(col(c))])
        case(f"shift-fill/{tbl}/{c}", tbl, [shift(col(c), 1, ["i32", 5])])

# ---------------------------------------------------------------------------
# cumulative operations, rank, reverse
# ---------------------------------------------------------------------------
for tbl, cs in [("q", DTS), ("t", ["i32", "f64", "s"])]:
    for op in ["sum", "min", "max", "prod", "count"]:
        for c in cs:
            for rev in (False, True):
                case(f"cum_{op}/{tbl}/{c}/{'rev' if rev else 'fwd'}", tbl, [cum(op, col(c), rev)])
    for m in ["average", "min", "max", "dense", "ordinal"]:
        for c in cs:
            for d in (False, True):
                if d and m in ("min", "max") and c not in ("f64", "s"):
                    continue
                if tbl == "t" and c == "i32":
                    continue
                case(f"rank/{tbl}/{m}/{c}/{'desc' if d else 'asc'}", tbl, [rank(col(c), m, d)])
    for c in cs:
        case(f"reverse/{tbl}/{c}", tbl, [reverse(col(c))])
for c in ["i32", "s", "n"]:
    for op in ["sum", "min", "max", "prod", "count"]:
        case(f"cum_{op}/e0/{c}", "e0", [cum(op, col(c))])
    case(f"rank/e0/{c}", "e0", [rank(col(c))])
    case(f"rank/e0/{c}/ordinal", "e0", [rank(col(c), "ordinal")])
    case(f"reverse/e0/{c}", "e0", [reverse(col(c))])

# ---------------------------------------------------------------------------
# fill_null with a strategy
# ---------------------------------------------------------------------------
STRATS = ["forward", "backward", "min", "max", "mean", "zero", "one"]
for tbl, cs in [("q", DTS), ("t", ["f64", "s"])]:
    for sname in STRATS:
        for c in cs:
            case(f"fills/{tbl}/{sname}/{c}", tbl, [fills(col(c), sname)])
for sname in ["forward", "backward"]:
    for c in ["i32", "s", "b", "d"]:
        for lim in [0, 1, 2]:
            case(f"fills/q/{sname}-limit{lim}/{c}", "q", [fills(col(c), sname, lim)])
for sname in ["min", "mean", "zero"]:
    case(f"fills/limit-bad/{sname}", "q", [fills(col("i32"), sname, 1)])
    case(f"fills/limit-bad0/{sname}", "q", [fills(col("i32"), sname, 0)])
case("fills/limit-negative", "q", [fills(col("i32"), "forward", -1)], variant="InvalidOperation")
case("fills/limit-negative/bad-strategy", "q", [fills(col("i32"), "min", -1)], variant="InvalidOperation")
for sname in STRATS:
    case(f"fills/e0/{sname}", "e0", [fills(col("i32"), sname)])
    case(f"fills/e0/{sname}/str", "e0", [fills(col("s"), sname)])
case("fills/limit-bad/z0-cols", "z0", [fills(cols([]), "min", 1)])
case("fills/limit-bad/q-cols-empty", "q", [fills(cols([]), "min", 1)])
case("fills/limit-neg/q-cols-empty", "q", [fills(cols([]), "forward", -1)], variant="InvalidOperation")

# ---------------------------------------------------------------------------
# mixed with aggregates, arithmetic, selectors, names, shapes
# ---------------------------------------------------------------------------
case("mix/cum_sum-max", "q", [agg("max", cum("sum", col("i32")))])
case("mix/cum_sum-max/e0", "e0", [agg("max", cum("sum", col("i32")))])
case("mix/cum_sum-sum", "q", [agg("sum", cum("sum", col("f64")))])
case("mix/cum_sum-last", "q", [agg("last", cum("sum", col("i64"))).alias("l")])
case("mix/cum_max-first", "t", [agg("first", cum("max", col("f32")))])
case("mix/diff-sum", "q", [agg("sum", diff(col("i32")))])
case("mix/diff-mean", "q", [agg("mean", diff(col("f64"), 2))])
case("mix/rank-max", "q", [agg("max", rank(col("s")))])
case("mix/rank-sum", "q", [agg("sum", rank(col("i32"), "dense"))])
case("mix/shift-count", "q", [agg("count", shift(col("i32"), 3))])
case("mix/shift-null_count-like", "q", [agg("sum", is_null(shift(col("i32"), 2)))])
case("mix/reverse-first", "q", [agg("first", reverse(col("s")))])
case("mix/cum_sum-minus-col", "q", [bin_("sub", cum("sum", col("i64")), col("i64"))])
case("mix/col-minus-shift", "q", [bin_("sub", col("f64"), shift(col("f64"), 1)).alias("d")])
case("mix/cum_sum-plus-lit", "q", [bin_("add", cum("sum", col("i32")), li(1))])
case("mix/cum_sum-gt", "q", [bin_("gt", cum("sum", col("i32")), li(10))])
case("mix/lit-times-cum", "q", [bin_("mul", li(2), cum("max", col("i32")))])
case("mix/abs-diff", "q", [fn("abs", diff(col("i32")))])
case("mix/diff-is_null", "q", [is_null(diff(col("i64")))])
case("mix/shift-fill_null", "q", [fill(shift(col("i32"), 1), li(0))])
case("mix/shift-fill_null-col", "q", [fill(shift(col("i64"), 1), col("i64"))])
case("mix/shift-fill-lit", "q", [shift(bin_("add", col("i32"), li(1)), 2, ["i32", 0])])
case("mix/shift-twice", "q", [shift(shift(col("i32"), 1), 2)])
case("mix/cum-of-cum", "q", [cum("sum", cum("sum", col("i32")))])
case("mix/rank-of-neg", "q", [rank(neg(col("f64")))])
case("mix/reverse-reverse", "q", [reverse(reverse(col("s")))])
case("mix/fills-of-shift", "q", [fills(shift(col("i32"), 1), "forward")])
case("mix/shift-of-fills", "q", [shift(fills(col("i32"), "forward"), 1)])
case("mix/cast-cum", "q", [cum("sum", cast(col("b"), "i32"))])
case("mix/when-cum", "q", [when_(bin_("gt", cum("sum", col("i32")), li(5)), li(1), li(0))])
case("mix/is_in-shift", "q", [isin(shift(col("i32"), 1), "i32")])
case("mix/alias", "q", [alias(cum("sum", col("i32")), "z")])
case("mix/alias-inner", "q", [cum("sum", alias(col("i32"), "z"))])
case("mix/alias-inner-shift", "q", [shift(alias(col("i32"), "z"), 1)])
case("mix/names-several", "q", [shift(col("i32"), 1), diff(col("i64")).alias("d64"), rank(col("f64")).alias("r"),
                                cum("count", col("s")).alias("c"), reverse(col("d")).alias("rev")])
case("mix/dup-name", "q", [col("i32"), shift(col("i32"), 1)])
case("mix/dup-name-shift", "q", [shift(col("i32"), 1), cum("sum", col("i32"))])
case("mix/missing", "q", [shift(col("zz"), 1)])
case("mix/missing-after", "q", [cum("sum", col("s")), cum("sum", col("zz"))])
case("mix/type-error-first", "q", [cum("sum", col("s")), diff(col("s"))])
case("mix/error-then-missing", "q", [cum("sum", col("s")), shift(col("zz"), 1)])
case("mix/wc", "q", [cum("sum", col("i32")).alias("cs"), shift(col("i32"), 1).alias("sh")], op="with_columns")
case("mix/wc-in-place", "q", [cum("sum", col("i32")).alias("i32")], op="with_columns")
case("mix/wc-dup", "q", [cum("sum", col("i32")), shift(col("i32"), 1)], op="with_columns", variant="DuplicateColumn")
case("mix/wc-e0", "e0", [cum("sum", col("i32")).alias("cs")], op="with_columns")
case("mix/wc-agg-seq", "q", [agg("sum", cum("sum", col("i32"))).alias("tot")], op="with_columns")
# selectors
case("sel/cols-cum_sum", "qn", [cum("sum", cols(["i32", "f64"]))])
case("sel/all-shift", "qn", [shift(all_, 1)])
case("sel/all-cum_max", "qn", [cum("max", all_, True)])
case("sel/all-rank", "qn", [rank(all_, "min")])
case("sel/all-diff", "qn", [diff(all_)])
case("sel/all-diff-dates", "qs", [diff(all_)], restricted=True)
case("sel/all-reverse", "q", [reverse(all_)])
case("sel/all-fills", "qs", [fills(all_, "forward")])
case("sel/all-fills-mean", "qs", [fills(all_, "mean")])
case("sel/all-fills-mean-mixed", "q", [fills(all_, "mean")])
case("sel/all-cum_sum-mixed", "q", [cum("sum", all_)])
case("sel/all-shift-z0", "z0", [shift(all_, 1)])
case("sel/all-shift-e0", "e0", [shift(all_, 1)])
case("sel/cols-empty", "q", [shift(cols([]), 1)])
case("sel/cols-missing", "q", [shift(cols(["i32", "zz"]), 1)])
case("sel/cols-op", "qn", [bin_("sub", cols(["i32", "i64"]), shift(cols(["i32", "i64"]), 1))])
case("sel/cols-op-width", "qn", [bin_("sub", cols(["i32", "i64"]), shift(cols(["i32", "i64", "f64"]), 1))])
case("sel/cols-alias", "qn", [cum("sum", cols(["i32", "i64"])).alias("x")])
case("sel/all-wc", "qn", [cum("sum", all_)], op="with_columns")
# lengths: a length-1 input, literals, broadcasting next to columns
case("len1/sum-shift", "q", [shift(agg("sum", col("i32")), 1)])
case("len1/sum-shift-neg", "q", [shift(agg("sum", col("i32")), -1)])
case("len1/sum-shift-fill", "q", [shift(agg("sum", col("i32")), 1, ["i32", 7])])
case("len1/sum-cum_sum", "q", [cum("sum", agg("sum", col("i32")))])
case("len1/sum-diff", "q", [diff(agg("sum", col("i32")))])
case("len1/sum-rank", "q", [rank(agg("sum", col("i32")))])
case("len1/sum-reverse", "q", [reverse(agg("sum", col("i32")))])
case("len1/sum-fills", "q", [fills(agg("first", col("n")), "forward")])
case("len1/lit-cum_sum", "q", [cum("sum", li(1))])
case("len1/litf-cum_sum", "q", [cum("sum", lf(1.5))])
case("len1/lit-shift", "q", [shift(li(1), 1)])
case("len1/lit-diff", "q", [diff(li(1))])
case("len1/lit-rank", "q", [rank(li(1))])
case("len1/lit-reverse", "q", [reverse(li(1))])
case("len1/lit-cum_count", "q", [cum("count", li(1))])
case("len1/lit-strong-cum_sum", "q", [cum("sum", lit("i32", 5))])
case("len1/lit-str-cum_min", "q", [cum("min", ls("a"))])
case("len1/lit-null-cum_sum", "q", [cum("sum", lit("null", None))])
case("len1/lit-null-shift", "q", [shift(lit("null", None), 1)])
case("len1/col-and-lit-cum", "q", [col("i32"), alias(cum("sum", li(1)), "c")])
case("len1/col-and-sum-shift", "q", [col("i32"), alias(shift(agg("sum", col("i32")), 1), "s")])
case("len1/col-and-seq", "q", [col("i32"), alias(cum("sum", agg("sum", col("i64"))), "c")])
case("len1/wc-lit-cum", "q", [cum("sum", li(1)).alias("c")], op="with_columns")
case("len1/wc-sum-shift", "q", [shift(agg("sum", col("i32")), 1).alias("c")], op="with_columns")
case("len1/z0-lit-cum", "z0", [cum("sum", li(1))])
case("len1/z0-lit-shift", "z0", [shift(li(1), 1)])
case("len1/e0-col-and-seq", "e0", [col("i32"), alias(cum("sum", agg("sum", col("i64"))), "c")])
case("len1/e0-lit-cum", "e0", [cum("sum", li(1))])
case("len1/e0-cum-lit", "e0", [alias(cum("sum", li(1)), "c"), col("i32")])
case("len1/r1-cum", "r1", [cum("sum", col("i32")), shift(col("i64"), 1).alias("s")])
case("len1/r1-lit-seq", "r1", [col("i32"), cum("sum", li(2)).alias("c")])
case("shape/two-lens", "q", [shift(col("i32"), 1), alias(cum("sum", li(1)), "x")])
case("shape/sum-vs-col", "q", [cum("sum", agg("sum", col("i32"))), col("i64")])

# ---------------------------------------------------------------------------
# str
# ---------------------------------------------------------------------------
UNARY = ["to_lowercase", "to_uppercase", "len_chars", "len_bytes"]
for op in UNARY:
    for c in ["s", "u", "i32", "d", "n", "b"]:
        case(f"str/{op}/{c}", "st", [st(op, col(c))])
    case(f"str/{op}/e0", "e0", [st(op, col("s"))])
    case(f"str/{op}/e0-i32", "e0", [st(op, col("i32"))])
    case(f"str/{op}/t", "t", [st(op, col("s"))])
for pat in ["a", "a.c", "^a", "b+", "(ab)+", "", "[a-c]{2}", "é"]:
    for lit_ in (False, True):
        case(f"str/contains/{pat}/{lit_}", "st", [st("contains", col("s"), pattern=pat, literal=lit_)])
for c in ["u", "i32", "d", "n", "b"]:
    case(f"str/contains/{c}", "st", [st("contains", col(c), pattern="a")])
    case(f"str/contains/{c}-literal", "st", [st("contains", col(c), pattern="a", literal=True)])
for bad in ["(", "[a", "a{2,1}", "*"]:
    case(f"str/contains/bad/{bad}", "st", [st("contains", col("s"), pattern=bad)], regex=bad)
    case(f"str/contains/bad/{bad}/e0", "e0", [st("contains", col("s"), pattern=bad)], regex=bad)
    case(f"str/replace/bad/{bad}", "st", [st("replace", col("s"), pattern=bad, value="x")], regex=bad)
    case(f"str/replace_all/bad/{bad}", "st", [st("replace_all", col("s"), pattern=bad, value="x")], regex=bad)
case("str/contains/bad-literal-ok", "st", [st("contains", col("s"), pattern="(", literal=True)])
case("str/contains/bad-wrong-dtype", "st", [st("contains", col("i32"), pattern="(")], regex="(")
for op in ["starts_with", "ends_with"]:
    for aff in ["a", "", "abc", "x", "é", "｡", "b", "  "]:
        case(f"str/{op}/aff-{aff}", "st", [st(op, col("s"), affix=aff)])
    for c in ["u", "i32", "d", "n", "b"]:
        case(f"str/{op}/{c}", "st", [st(op, col(c), affix="a")])
    case(f"str/{op}/e0", "e0", [st(op, col("s"), affix="a")])
for op in ["replace", "replace_all"]:
    for pat, val, lit_ in [("b", "X", False), ("a", "", False), ("", "-", False), ("[0-9]+", "<$0>", False),
                           ("([a-z])([0-9]+)", "$2$1", False), (".", "!", True), ("[a-c]", "!", False),
                           ("A", "$0", True), ("x*", "-", False), ("b", "$$", False),
                           # supplementary characters in the replacement text,
                           # next to group references (T9 fix round 1)
                           ("[a-c]", "\U0001F600", False), ("a", "\U0001F600", False),
                           ("a", "a\U0001F600", False), ("b", "\U0001D4B3y", False),
                           ("[0-9]+", "<$0>\U0001F600", False),
                           ("([a-z])([0-9]+)", "\U0001F600$2$1\U0001F600", False),
                           ("(a)", "\U0001F600${1}\U0001F600$$", False),
                           ("a", "\U0001F600", True)]:
        case(f"str/{op}/{pat}/{val}/{lit_}", "st", [st(op, col("s"), pattern=pat, value=val, literal=lit_)])
    for c in ["u", "i32", "d", "n", "b"]:
        case(f"str/{op}/{c}", "st", [st(op, col(c), pattern="a", value="b")])
    case(f"str/{op}/e0", "e0", [st(op, col("s"), pattern="a", value="b")])
for op in ["strip_chars", "strip_chars_start", "strip_chars_end"]:
    for ch in [None, "", " ", "x", "x ", "\U0001F600", "hi", "ab"]:
        case(f"str/{op}/chars-{ch}", "st", [st(op, col("s"), chars=ch)])
    for c in ["u", "i32", "d", "n", "b"]:
        case(f"str/{op}/{c}", "st", [st(op, col(c), chars=None)])
    case(f"str/{op}/e0", "e0", [st(op, col("s"), chars=None)])
# composition, names, selectors, shapes
case("str/chain", "st", [st("len_chars", st("strip_chars", col("s")))])
case("str/chain-case", "st", [st("contains", st("to_lowercase", col("s")), pattern="hello")])
case("str/chain-replace", "st", [st("to_uppercase", st("replace_all", col("s"), pattern="a", value="b"))])
case("str/len-sum", "st", [agg("sum", st("len_chars", col("s")))])
case("str/len-max", "st", [agg("max", st("len_bytes", col("s"))).alias("m")])
case("str/len-plus", "st", [bin_("add", st("len_chars", col("s")), li(1))])
case("str/len-gt", "st", [bin_("gt", st("len_chars", col("s")), li(3))])
case("str/len-mean", "st", [bin_("div", st("len_chars", col("s")), agg("mean", st("len_chars", col("s"))))])
case("str/contains-and", "st", [bin_("and", st("contains", col("s"), pattern="a"), st("starts_with", col("u"), affix="c"))])
case("str/contains-not", "st", [not_(st("contains", col("s"), pattern="a"))])
case("str/contains-sum", "st", [agg("sum", st("contains", col("s"), pattern="a"))])
case("str/contains-is_null", "st", [is_null(st("contains", col("s"), pattern="a"))])
case("str/when", "st", [when_(st("contains", col("s"), pattern="a"), st("to_uppercase", col("s")), col("u"))])
case("str/fill", "st", [fill(st("to_uppercase", col("s")), ls("none"))])
case("str/fill-value", "st", [fill(col("s"), st("to_uppercase", col("u")))])
case("str/alias", "st", [alias(st("to_uppercase", col("s")), "z")])
case("str/alias-inner", "st", [st("to_uppercase", alias(col("s"), "z"))])
case("str/names", "st", [st("to_uppercase", col("s")), st("to_lowercase", col("u")), st("len_chars", col("s")).alias("n")])
case("str/dup", "st", [st("to_uppercase", col("s")), st("to_lowercase", col("s"))])
case("str/dup-with-col", "st", [col("s"), st("to_lowercase", col("s"))])
case("str/wc", "st", [st("to_uppercase", col("s")).alias("up"), st("len_chars", col("s")).alias("n")], op="with_columns")
case("str/wc-in-place", "st", [st("to_uppercase", col("s"))], op="with_columns")
case("str/cols", "st", [st("to_uppercase", cols(["s", "u"]))])
case("str/cols-len", "st", [st("len_chars", cols(["s", "u"]))])
case("str/cols-with-error", "st", [st("to_uppercase", cols(["s", "i32"]))])
case("str/all", "st", [st("to_uppercase", all_)])
case("str/all-strings", "st", [st("to_uppercase", cols(["s", "u"]))], op="with_columns")
case("str/all-z0", "z0", [st("to_uppercase", all_)])
case("str/cols-empty", "st", [st("to_uppercase", cols([]))])
case("str/missing", "st", [st("to_uppercase", col("zz"))])
case("str/missing-after-error", "st", [st("to_uppercase", col("i32")), st("to_uppercase", col("zz"))])
# polars raises the schema-time error of `contains` on a date before the run-time
# error of `to_uppercase` on an Int32 that comes first (known-diffs/expr_seq.md),
# so only this order is compared
case("str/error-order2", "st", [st("contains", col("d"), pattern="a"), st("to_uppercase", col("i32"))])
case("str/lit", "st", [st("to_uppercase", ls("abc"))])
case("str/lit-len", "st", [st("len_chars", ls("a😀"))])
case("str/lit-contains", "st", [st("contains", ls("abc"), pattern="b")])
case("str/lit-replace", "st", [st("replace", ls("abc"), pattern="b", value="X")])
case("str/lit-strip", "st", [st("strip_chars", ls("  a  "))])
case("str/lit-col", "st", [col("s"), alias(st("to_uppercase", ls("abc")), "k")])
case("str/lit-col-len", "st", [alias(st("len_chars", ls("abc")), "k"), col("i32")])
case("str/lit-wc", "st", [st("to_uppercase", ls("abc")).alias("k")], op="with_columns")
case("str/lit-e0", "e0", [st("to_uppercase", ls("abc"))])
case("str/lit-e0-col", "e0", [col("s"), alias(st("to_uppercase", ls("abc")), "k")])
case("str/lit-z0", "z0", [st("to_uppercase", ls("abc"))])
# (`lit_int(1).str().to_uppercase()` names `i32` in polars' error, `i64` here: the
# lone weak literal is Int64, see known-diffs/expr_seq.md; pinned by a hand test)
case("str/lit-float", "st", [st("len_chars", lf(1.5))])
case("str/lit-bool", "st", [st("to_uppercase", lb(True))])
case("str/lit-null", "st", [st("to_uppercase", lit("null", None))])
case("str/lit-null-contains", "st", [st("contains", lit("null", None), pattern="a")])
case("str/agg-input", "st", [st("to_uppercase", agg("max", col("s")))])
case("str/agg-input-len", "st", [st("len_chars", agg("min", col("s")))])
case("str/agg-input-int", "st", [st("to_uppercase", agg("sum", col("i32")))])
case("str/agg-and-col", "st", [col("s"), alias(st("to_uppercase", agg("max", col("s"))), "m")])
case("str/shift-then", "st", [st("to_uppercase", shift(col("s"), 1))])
case("str/cum_min-then", "st", [st("len_chars", cum("min", col("s")))])
case("str/add-strings", "st", [bin_("add", st("to_uppercase", col("s")), col("u"))], restricted=True)
case("str/cast-len", "st", [cast(st("len_chars", col("s")), "str")])
case("str/cast-then", "st", [st("len_chars", cast(col("i32"), "str"))])
case("str/cast-upper", "st", [st("to_uppercase", cast(col("d"), "str"))])
case("str/is_in", "st", [isin(st("to_lowercase", col("s")), "str")])
case("str/is_in-a", "sa", [isin(st("to_lowercase", col("s")), "str")])
case("str/between", "st", [A["btw"](st("to_lowercase", col("s")), ls("a"), ls("m"))])
case("str/rank-len", "st", [rank(st("len_chars", col("s")), "dense")])
case("str/cum_sum-len", "st", [cum("sum", st("len_chars", col("s")))])
case("str/diff-len", "st", [diff(st("len_chars", col("s")))])
case("str/r1", "r1", [st("to_uppercase", col("s")), st("len_chars", col("s")).alias("n")])
case("str/cum_sum-str", "st", [cum("sum", st("to_uppercase", col("s")))])

# ---------------------------------------------------------------------------
# dt
# ---------------------------------------------------------------------------
FIELDS = ["year", "month", "day", "weekday", "ordinal_day", "hour", "minute", "second"]
for f in FIELDS:
    for c in ["d", "dt", "i32", "s", "n"]:
        case(f"dt/{f}/{c}", "tm", [dtf(f, col(c))])
    case(f"dt/{f}/e0-date", "e0", [dtf(f, col("d"))])
    case(f"dt/{f}/e0-dt", "e0", [dtf(f, col("dt"))])
    case(f"dt/{f}/t", "t", [dtf(f, col("dt"))])
    case(f"dt/{f}/t-date", "t", [dtf(f, col("d"))])
    case(f"dt/{f}/lit", "tm", [dtf(f, lit("datetime[μs]", 1709210096123456))])
    case(f"dt/{f}/lit-date", "tm", [dtf(f, lit("date", 19782))])
    case(f"dt/{f}/agg", "tm", [dtf(f, agg("max", col("dt")))])
case("dt/lit-str", "tm", [dtf("year", ls("2020-01-01"))])
case("dt/lit-null", "tm", [dtf("year", lit("null", None))])
case("dt/chain", "tm", [bin_("add", dtf("year", col("d")), dtf("month", col("d")))])
case("dt/year-plus", "tm", [bin_("add", dtf("year", col("d")), li(1))])
case("dt/weekday-eq", "tm", [bin_("eq", dtf("weekday", col("d")), li(1))])
case("dt/weekday-gt", "tm", [bin_("ge", dtf("weekday", col("dt")), li(6))])
case("dt/year-sum", "tm", [agg("sum", dtf("year", col("d")))])
case("dt/year-max-min", "tm", [agg("max", dtf("year", col("dt"))), agg("min", dtf("year", col("dt"))).alias("mn")])
case("dt/hour-mean", "tm", [agg("mean", dtf("hour", col("dt")))])
case("dt/year-cast", "tm", [cast(dtf("year", col("d")), "i64")])
case("dt/year-cast-str", "tm", [cast(dtf("month", col("d")), "str")])
case("dt/year-fill", "tm", [fill(dtf("year", col("d")), li(0))])
case("dt/year-fill-dt", "tm", [fill(dtf("hour", col("dt")), dtf("year", col("dt")))])
case("dt/when", "tm", [when_(bin_("gt", dtf("year", col("d")), li(1999)), ls("new"), ls("old"))])
case("dt/alias", "tm", [alias(dtf("year", col("d")), "y")])
case("dt/alias-inner", "tm", [dtf("year", alias(col("d"), "y"))])
case("dt/names", "tm", [dtf("year", col("d")), dtf("month", col("d")).alias("m"), dtf("hour", col("dt")).alias("h")])
case("dt/dup", "tm", [dtf("year", col("d")), dtf("month", col("d"))])
case("dt/dup-col", "tm", [col("d"), dtf("month", col("d"))])
case("dt/wc", "tm", [dtf("year", col("d")).alias("y"), dtf("second", col("dt")).alias("sec")], op="with_columns")
case("dt/wc-in-place", "tm", [dtf("year", col("d")).alias("d")], op="with_columns")
case("dt/cols", "tm", [dtf("year", cols(["d", "dt"]))])
case("dt/cols-error", "tm", [dtf("year", cols(["d", "s"]))])
case("dt/cols-hour", "tm", [dtf("hour", cols(["dt", "d"]))])
case("dt/all", "tm", [dtf("year", all_)])
case("dt/all-z0", "z0", [dtf("year", all_)])
case("dt/cols-empty", "tm", [dtf("year", cols([]))])
case("dt/missing", "tm", [dtf("year", col("zz"))])
case("dt/missing-after-error", "tm", [dtf("year", col("s")), dtf("year", col("zz"))])
case("dt/error-order", "tm", [dtf("year", col("s")), dtf("hour", col("d"))])
case("dt/error-order2", "tm", [dtf("hour", col("d")), dtf("year", col("s"))])
case("dt/shift-then", "tm", [dtf("year", shift(col("d"), 1))])
case("dt/cum_max-then", "tm", [dtf("year", cum("max", col("d")))])
case("dt/reverse-then", "tm", [dtf("day", reverse(col("dt")))])
case("dt/fills-then", "tm", [dtf("year", fills(col("d"), "forward"))])
case("dt/cast-then", "tm", [dtf("year", cast(col("dt"), "date"))])
case("dt/cast-then-hour", "tm", [dtf("hour", cast(col("d"), "datetime[μs]"))])
case("dt/rank-year", "tm", [rank(dtf("year", col("d")), "min")])
case("dt/diff-year", "tm", [diff(dtf("year", col("d")))])
case("dt/lit-col", "tm", [col("d"), alias(dtf("year", lit("date", 19782)), "y")])
case("dt/e0-lit-col", "e0", [col("d"), alias(dtf("year", lit("date", 19782)), "y")])
case("dt/e0-lit", "e0", [dtf("year", lit("date", 19782))])
case("dt/z0-lit", "z0", [dtf("year", lit("date", 19782))])
case("dt/r1", "r1", [dtf("year", col("d")), dtf("hour", col("dt")).alias("h")])

# ---------------------------------------------------------------------------
# DataFrame.fill_null(strategy=...)
# ---------------------------------------------------------------------------
FRAME_CASES = []


def frame_case(cid, table, strategy, limit=None, variant=None):
    if cid in FLAKY_FRAME_CASES and not CHECK_FLAKY:
        return
    df = TABLES[table]
    spelling = f"{table}.fill_null(strategy={strategy!r}" + ("" if limit is None else f", limit={limit}") + ")"
    rec = {"id": cid, "table": table, "strategy": strategy, "polars": spelling}
    if limit is not None:
        rec["limit"] = limit
    try:
        out = df.fill_null(strategy=strategy, limit=limit)
        rec["result"] = encode_frame(out)
    except BaseException as e:  # noqa: BLE001
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        name = type(e).__name__
        var = VARIANTS.get(name, name)
        variant = variant or PY_ERRORS.get(name)
        if variant is not None and variant != var:
            rec["polars_error"] = name
            var = variant
        if name == "PanicException":
            print("PANIC (skipped)", cid, str(e).split("\n")[0])
            return
        rec["error"] = var
        rec["message"] = str(e).split("\n")[0]
        if CHECK_FLAKY:
            for _ in range(CHECK_RUNS):
                try:
                    df.fill_null(strategy=strategy, limit=limit)
                    again = None
                except BaseException as e2:  # noqa: BLE001
                    again = str(e2).split("\n")[0]
                if again != rec["message"]:
                    UNSTABLE.add(cid)
                    break
    assert cid not in {c["id"] for c in FRAME_CASES}, cid
    FRAME_CASES.append(rec)


for tbl in ["q", "qn", "qs", "t", "e0", "z0", "r1"]:
    for sname in STRATS:
        frame_case(f"frame/{tbl}/{sname}", tbl, sname)
for tbl in ["q", "qn", "qs", "e0"]:
    for sname in ["forward", "backward"]:
        for lim in [0, 1, 2]:
            frame_case(f"frame/{tbl}/{sname}-limit{lim}", tbl, sname, lim)
for tbl in ["qn", "q", "z0", "e0"]:
    for sname in ["min", "max", "mean", "zero", "one"]:
        frame_case(f"frame/{tbl}/{sname}-limit-bad", tbl, sname, 1)
for tbl in ["qn", "z0"]:
    frame_case(f"frame/{tbl}/forward-limit-neg", tbl, "forward", -1, variant="InvalidOperation")
    frame_case(f"frame/{tbl}/min-limit-neg", tbl, "min", -1, variant="InvalidOperation")
# one-column frames of each type: which strategy each type refuses
for c in DTS:
    TABLES[f"c_{c}"] = QDF.select([c])
    for sname in STRATS:
        frame_case(f"frame/c_{c}/{sname}", f"c_{c}", sname)
    frame_case(f"frame/c_{c}/forward-limit1", f"c_{c}", "forward", 1)

if CHECK_FLAKY:
    # nothing is written: the cases that change between runs must be exactly
    # the excluded ones
    expected = FLAKY_CASES | FLAKY_FRAME_CASES
    print("unstable:", sorted(UNSTABLE))
    assert UNSTABLE <= expected, sorted(UNSTABLE - expected)
    print("excluded but stable in this run:", sorted(expected - UNSTABLE))
    sys.exit(0)

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
def mb_cases_file():
    lines = ["// 由 docs/golden/scripts/expr_seq.py 生成，勿手改", ""]
    chunk = 60
    parts = [MB[i:i + chunk] for i in range(0, len(MB), chunk)]
    sig = "m : Map[String, Array[@pl.Expr]], vs : Map[String, @pl.Series]"
    for pi, part in enumerate(parts):
        lines += ["///|", f"fn golden_expr_seq_cases_{pi}({sig}) -> Unit {{", "  ignore(vs)"]
        for cid, exprs in part:
            lines.append(f"  m[{mb_str(cid)}] = [{', '.join(exprs)}]")
        lines += ["}", ""]
    lines += ["///|", "/// Every case id with the expressions it builds; `vs` is the `inputs` table.",
              "fn golden_expr_seq_cases(vs : Map[String, @pl.Series]) -> Map[String, Array[@pl.Expr]] {",
              "  let m : Map[String, Array[@pl.Expr]] = Map([])"]
    for pi in range(len(parts)):
        lines.append(f"  golden_expr_seq_cases_{pi}(m, vs)")
    lines += ["  m", "}", ""]
    path = os.path.join(_repo_root(), "src", "pl", "expr_seq_cases_test.mbt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


used_inputs = {"i32", "str"}
doc = {
    "tables": {name: encode_frame(df) for name, df in TABLES.items()},
    "inputs": {k: encode_series(input_series(k)) for k in sorted(used_inputs)},
    "cases": CASES,
    "frame_cases": FRAME_CASES,
}
emit("expr_seq", doc, compact=True)
# MoonBit source may not contain a raw U+2028/U+2029 (not even in a `#|` string)
path = os.path.join(_repo_root(), "src", "pl", "golden_expr_seq_data_test.mbt")
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
print(f"{len(FRAME_CASES)} frame cases: result", sum(1 for c in FRAME_CASES if "result" in c),
      "error", sum(1 for c in FRAME_CASES if "error" in c))
