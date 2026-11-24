"""Generates the Series sort / arg_sort / unique / n_unique / is_in golden data
and the multi-key sort / unique data (T5).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/sort.py

Outputs
- docs/golden/sort.json + src/pl/golden_sort_data_test.mbt: `{"inputs":
  {key: series}, "cases": [...]}` (compact layout). A case has `id`, `op`
  (`sort`, `arg_sort`, `unique`, `n_unique`, `is_in`), `a` (and `b` for
  `is_in`), `descending` / `nulls_last` (sort, arg_sort), `polars` (the Python
  spelling) and one of `result` (a series, through `to_ours`), `result_int`
  (n_unique, as text) or `error` + `message`.
- docs/golden/sort_multi.json + src/pl/golden_sort_multi_data_wbtest.mbt:
  `{"sort": [...], "unique": [...]}`; a case has `cols` (list of series),
  `descending` / `nulls_last` (sort) or `keep` (unique), `polars` and
  `result`, the row indices polars returns (`with_row_index` of the sorted /
  uniqued frame). The MoonBit side calls the private `arg_sort_columns` and
  `unique_row_indices` (white-box test, so the data lives in a `_wbtest` file).

Series.sort has no `maintain_order` argument; polars' single-key sort is
stable in practice (ties keep their original order, also for descending, and
`-0.0` / `0.0` keep theirs); the multi-key cases use `maintain_order=True`.
`Series.is_in(Series)` of a same-typed collection is deprecated in polars 2.1
(use `implode`); the data is generated with the plain call and the warning
silenced, which has the semantics this library implements.
"""
import os
import random
import sys
import warnings

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import polars as pl

from emit import DTYPE_NAMES, _compact_text, _repo_root, emit, encode_series, series_from_spec, to_ours

warnings.filterwarnings("ignore")

nan = float("nan")
inf = float("inf")
I64_MIN = -9223372036854775808
I64_MAX = 9223372036854775807

DTYPES = list(DTYPE_NAMES)

VARIANTS = {
    "ColumnNotFoundError": "ColumnNotFound",
    "DuplicateError": "DuplicateColumn",
    "SchemaError": "SchemaMismatch",
    "ShapeError": "ShapeMismatch",
    "OutOfBoundsError": "OutOfBounds",
    "InvalidOperationError": "InvalidOperation",
    "ComputeError": "ComputeError",
}

# Values per dtype: duplicates, nulls, NaN, -0.0 / 0.0, +-inf, the MIN / MAX
# of the integers, and the Review Focus 1 strings ("｡" < "\U0001F600" by
# code point but not by UTF-16 code unit).
VALS = {
    "bool": [True, False, None, True, False, None, False],
    "i32": [3, -1, None, 0, 3, -2147483648, 2147483647, None, 0, 1, -1],
    "i64": [3, -1, None, 0, 3, I64_MIN, I64_MAX, None, 0, 1, -1],
    "f32": [1.0, nan, None, -inf, -0.0, 0.0, inf, 1.0, nan, 0.1, 3.0e38, -0.0, None, 0.0],
    "f64": [1.0, nan, None, -inf, -0.0, 0.0, inf, 1.0, nan, 5.5, -2.5, 1e308, None, 0.0, -0.0],
    "str": ["｡", "\U0001F600", "a", "", "Z", None, "a", "\U0001F600", "", "￿", "ab", "｡", None],
    "date": [0, -1, 19782, -25567, None, 0, 19782, None],
    "datetime[μs]": [0, -1, 1709210096123456, 86399999999, None, 0, -1, None],
    "null": [None, None, None, None],
}
# the exact list from the Review Focus (sorting and unique)
FOCUS_STR = ["｡", "\U0001F600", "a", "", "Z"]
FOCUS_F64 = [1.0, nan, None, -inf, -0.0, 0.0]


def error_of(e):
    name = type(e).__name__
    return VARIANTS.get(name, name), str(e).split("\n")[0]


def attempt(f):
    try:
        return f(), None
    except Exception as e:  # noqa: BLE001
        return None, error_of(e)
    except BaseException as e:  # noqa: BLE001
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        return None, error_of(e)


INPUTS = {}


def ref(label, series):
    enc = encode_series(series)
    for key, value in INPUTS.items():
        if {k: v for k, v in value.items() if k != "for"} == enc:
            return key
    key = f"i{len(INPUTS)}"
    INPUTS[key] = dict(enc, **{"for": label})
    return key


def mk(name, dtype, values):
    return series_from_spec(name, dtype, values)


def finish(case, result, err):
    if err is not None:
        case["error"], case["message"] = err
        return case
    if isinstance(result, int):
        case["result_int"] = str(result)
        return case
    ours, original = to_ours(result)
    case["result"] = encode_series(ours)
    if ours.dtype != result.dtype:
        case["polars_dtype"] = original
    return case


def py_flag(b):
    return "True" if b else "False"


def sort_cases(cases, label, x, a):
    """sort and arg_sort over the four (descending, nulls_last) combinations."""
    for d in (False, True):
        for nl in (False, True):
            tag = f"{label}/{x}/d{int(d)}n{int(nl)}"
            for op in ("sort", "arg_sort"):
                result, err = attempt(lambda: getattr(a, op)(descending=d, nulls_last=nl))
                case = {
                    "id": f"{op}/{tag}", "op": op, "a": ref(f"{label}/{x}", a),
                    "descending": d, "nulls_last": nl,
                    "polars": f"s1.{op}(descending={py_flag(d)}, nulls_last={py_flag(nl)})",
                }
                if op == "sort" and err is None and x in ("f32", "f64"):
                    # polars' Series.sort leaves the order of -0.0 and 0.0 unspecified
                    # (not stable from about 32 rows on, see known-diffs/sort.md);
                    # arg_sort is stable, so its gather is the expectation there
                    stable = a.gather(a.arg_sort(descending=d, nulls_last=nl))
                    if [str(v) for v in result] != [str(v) for v in stable]:
                        result = stable
                        case["polars"] = f"s1.gather(s1.arg_sort(descending={py_flag(d)}, nulls_last={py_flag(nl)}))"
                        case["note"] = "s1.sort() leaves -0.0 / 0.0 in an unspecified order here; expected is the stable arg_sort gather"
                cases.append(finish(case, result, err))


def unique_cases(cases, label, x, a):
    result, err = attempt(lambda: a.unique(maintain_order=True))
    cases.append(finish({
        "id": f"unique/{label}/{x}", "op": "unique", "a": ref(f"{label}/{x}", a),
        "polars": "s1.unique(maintain_order=True)",
    }, result, err))
    result, err = attempt(lambda: a.n_unique())
    cases.append(finish({
        "id": f"n_unique/{label}/{x}", "op": "n_unique", "a": ref(f"{label}/{x}", a),
        "polars": "s1.n_unique()",
    }, result, err))


def random_values(rng, dtype, n):
    pools = {
        "bool": [True, False, None],
        "i32": [-5, 0, 1, 2, 3, 7, None],
        "i64": [-5, 0, 1, 2, 3, I64_MAX, I64_MIN, None],
        "f32": [nan, -0.0, 0.0, 1.0, 2.5, -inf, inf, None],
        "f64": [nan, -0.0, 0.0, 1.0, 2.5, -inf, inf, None],
        "str": ["", "a", "b", "ab", "｡", "\U0001F600", "", None],
        "date": [-3, 0, 1, 19782, None],
        "datetime[μs]": [-3, 0, 1, 1709210096123456, None],
    }
    pool = pools[dtype]
    return [rng.choice(pool) for _ in range(n)]


# ---- is_in ----------------------------------------------------------------

IS_IN_SELF = {
    "bool": [True, False, None],
    "i32": [1, 2, 3, None, -2147483648],
    "i64": [1, 2, 3, None, I64_MIN],
    "f32": [1.0, 2.0, nan, None, 0.0, -0.0],
    "f64": [1.0, 2.0, nan, None, 0.0, -0.0],
    "str": ["a", "b", "｡", None, "\U0001F600"],
    "date": [1, 2, 3, None],
    "datetime[μs]": [1, 2, 3, None],
    "null": [None, None, None],
}
IS_IN_OTHER = {
    "bool": [True, None],
    "i32": [2, 3, -2147483648, None],
    "i64": [2, 3, I64_MIN, None],
    "f32": [2.0, nan, None, -0.0],
    "f64": [2.0, nan, None, -0.0],
    "str": ["b", "\U0001F600", None],
    "date": [2, 3, None],
    "datetime[μs]": [2, 3, None],
    "null": [None, None],
}


def is_in_case(cases, cid, a, b):
    result, err = attempt(lambda: a.is_in(b))
    cases.append(finish({
        "id": cid, "op": "is_in", "a": ref(f"{cid}.a", a), "b": ref(f"{cid}.b", b),
        "polars": "s1.is_in(s2)",
    }, result, err))


def build_series_cases():
    cases = []
    rng = random.Random(20261123)

    # sort / arg_sort / unique / n_unique over every dtype
    for x in DTYPES:
        a = mk("a", x, VALS[x])
        sort_cases(cases, "vals", x, a)
        unique_cases(cases, "vals", x, a)
        # empty and length 1
        sort_cases(cases, "empty", x, mk("a", x, []))
        unique_cases(cases, "empty", x, mk("a", x, []))
        one = [VALS[x][0]]
        sort_cases(cases, "one", x, mk("a", x, one))
        unique_cases(cases, "one", x, mk("a", x, one))
        # all null, all equal
        sort_cases(cases, "allnull", x, mk("a", x, [None, None, None]))
        unique_cases(cases, "allnull", x, mk("a", x, [None, None, None]))
        if x != "null":
            same = [VALS[x][0]] * 4
            sort_cases(cases, "same", x, mk("a", x, same))
            unique_cases(cases, "same", x, mk("a", x, same))
    # the exact Review Focus lists
    sort_cases(cases, "focus", "str", mk("a", "str", FOCUS_STR))
    unique_cases(cases, "focus", "str", mk("a", "str", FOCUS_STR))
    sort_cases(cases, "focus", "f64", mk("a", "f64", FOCUS_F64))
    unique_cases(cases, "focus", "f64", mk("a", "f64", FOCUS_F64))
    # NaN with different bit patterns is one value
    neg_nan = -nan
    unique_cases(cases, "nan-payload", "f64", mk("a", "f64", [nan, neg_nan, 1.0, nan]))
    unique_cases(cases, "zero-first", "f64", mk("a", "f64", [0.0, -0.0, 0.0]))
    unique_cases(cases, "negzero-first", "f64", mk("a", "f64", [-0.0, 0.0, -0.0]))
    unique_cases(cases, "zero", "f32", mk("a", "f32", [0.0, -0.0, nan, nan]))
    # seeded random data with many ties: arg_sort shows stability
    for x in DTYPES:
        if x == "null":
            continue
        a = mk("a", x, random_values(rng, x, 48))
        sort_cases(cases, "random", x, a)
        unique_cases(cases, "random", x, a)

    # is_in: every pair of dtypes
    for x in DTYPES:
        for y in DTYPES:
            is_in_case(cases, f"is_in/{x}x{y}", mk("a", x, IS_IN_SELF[x]), mk("b", y, IS_IN_OTHER[y]))
    # is_in: semantics
    f64 = lambda v: mk("a", "f64", v)
    is_in_case(cases, "is_in/other-empty", f64([1.0, None]), mk("b", "f64", []))
    is_in_case(cases, "is_in/self-empty", f64([]), mk("b", "f64", [1.0, None]))
    is_in_case(cases, "is_in/both-empty", f64([]), mk("b", "f64", []))
    is_in_case(cases, "is_in/other-all-null", f64([1.0, None]), mk("b", "f64", [None, None]))
    is_in_case(cases, "is_in/other-nan", f64([nan, 1.0, None]), mk("b", "f64", [nan]))
    is_in_case(cases, "is_in/other-negzero", f64([0.0, -0.0, 1.0]), mk("b", "f64", [-0.0]))
    is_in_case(cases, "is_in/other-zero", f64([0.0, -0.0, 1.0]), mk("b", "f64", [0.0]))
    is_in_case(cases, "is_in/i32-in-i64-large", mk("a", "i32", [1, 2, 3, None]), mk("b", "i64", [3000000000, 2]))
    is_in_case(cases, "is_in/i64-in-i32", mk("a", "i64", [1, 2, 3000000000, None]), mk("b", "i32", [2, 1]))
    is_in_case(cases, "is_in/f32-in-f64", mk("a", "f32", [0.1, 0.5, nan, None]), mk("b", "f64", [0.1, 0.5, nan]))
    is_in_case(cases, "is_in/f64-in-f32", mk("a", "f64", [0.1, 0.5, nan, None]), mk("b", "f32", [0.1, 0.5, nan]))
    is_in_case(cases, "is_in/str-codepoints", mk("a", "str", FOCUS_STR + [None]), mk("b", "str", ["\U0001F600", "Z", "｡"]))
    is_in_case(cases, "is_in/length-1", mk("a", "i64", [5]), mk("b", "i64", [1, 2, 3, 4, 5]))
    is_in_case(cases, "is_in/dup-other", mk("a", "i32", [1, 2, 3]), mk("b", "i32", [2, 2, 2, 2]))
    is_in_case(cases, "is_in/bool-all", mk("a", "bool", [True, False, None]), mk("b", "bool", [False, False]))
    is_in_case(cases, "is_in/null-other-empty", mk("a", "null", [None, None]), mk("b", "i64", []))
    is_in_case(cases, "is_in/null-self-empty", mk("a", "null", []), mk("b", "i64", [1]))
    is_in_case(cases, "is_in/i64-in-null-empty", mk("a", "i64", [1, None]), mk("b", "null", []))
    # a longer other, random with hash collisions in mind
    big = [rng.randrange(0, 300) for _ in range(300)]
    is_in_case(cases, "is_in/random-i64", mk("a", "i64", [rng.randrange(0, 600) for _ in range(120)]), mk("b", "i64", big))
    return cases


# ---- multi-key sort / unique ------------------------------------------------

MULTI_DTYPES = [d for d in DTYPES if d != "null"]


def multi_columns(rng, dtypes, n):
    cols = []
    for k, dt in enumerate(dtypes):
        cols.append(mk(f"c{k}", dt, random_values(rng, dt, n)))
    return cols


def multi_cases():
    rng = random.Random(7)
    sort, unique = [], []
    combos = [
        ["i32", "str"], ["f64", "i64"], ["str", "f32", "bool"], ["bool", "date"],
        ["datetime[μs]", "i32"], ["f32", "str"], ["i64", "i64", "i64"], ["f64", "f64"],
    ]
    for ci, dts in enumerate(combos):
        for n in (0, 1, 30):
            cols = multi_columns(rng, dts, n)
            df = pl.DataFrame(cols)
            flags = [
                ([False] * len(dts), [False] * len(dts)),
                ([True] * len(dts), [True] * len(dts)),
                ([bool(rng.getrandbits(1)) for _ in dts], [bool(rng.getrandbits(1)) for _ in dts]),
                ([i % 2 == 0 for i in range(len(dts))], [i % 2 == 1 for i in range(len(dts))]),
            ]
            if n == 0:
                flags = flags[:1]
            for fi, (d, nl) in enumerate(flags):
                names = [c.name for c in cols]
                res = (
                    df.with_row_index("idx")
                    .sort(names, descending=d, nulls_last=nl, maintain_order=True)["idx"]
                    .to_list()
                    if n > 0
                    else []
                )
                sort.append({
                    "id": f"sort/{ci}/n{n}/f{fi}",
                    "cols": [encode_series(c) for c in cols],
                    "descending": d,
                    "nulls_last": nl,
                    "polars": f'df.with_row_index("idx").sort({names}, descending={d}, nulls_last={nl}, maintain_order=True)["idx"]',
                    "result": res,
                })
            for keep in ("any", "first", "last", "none"):
                names = [c.name for c in cols]
                res = (
                    df.with_row_index("idx")
                    .unique(subset=names, keep=keep, maintain_order=True)["idx"]
                    .to_list()
                    if n > 0
                    else []
                )
                unique.append({
                    "id": f"unique/{ci}/n{n}/{keep}",
                    "cols": [encode_series(c) for c in cols],
                    "keep": keep,
                    "polars": f'df.with_row_index("idx").unique(subset={names}, keep="{keep}", maintain_order=True)["idx"]',
                    "result": res,
                })
    # focus lists as a one-column frame
    for name, dt, vals in (("focus-str", "str", FOCUS_STR + [None, "a"]), ("focus-f64", "f64", FOCUS_F64 + [nan, 0.0])):
        c = mk("c0", dt, vals)
        df = pl.DataFrame([c]).with_row_index("idx")
        for keep in ("any", "first", "last", "none"):
            unique.append({
                "id": f"unique/{name}/{keep}",
                "cols": [encode_series(c)],
                "keep": keep,
                "polars": f'df.with_row_index("idx").unique(subset=["c0"], keep="{keep}", maintain_order=True)["idx"]',
                "result": df.unique(subset=["c0"], keep=keep, maintain_order=True)["idx"].to_list(),
            })
        for d in (False, True):
            for nl in (False, True):
                sort.append({
                    "id": f"sort/{name}/d{int(d)}n{int(nl)}",
                    "cols": [encode_series(c)],
                    "descending": [d],
                    "nulls_last": [nl],
                    "polars": f'df.sort(["c0"], descending=[{d}], nulls_last=[{nl}], maintain_order=True)["idx"]',
                    "result": df.sort(["c0"], descending=[d], nulls_last=[nl], maintain_order=True)["idx"].to_list(),
                })
    return sort, unique


def emit_wbtest(name, doc):
    """Like `emit(compact=True)` but writes `golden_<name>_data_wbtest.mbt`
    (a white-box test cannot see the data of a black-box test file)."""
    root = _repo_root()
    text = _compact_text(doc)
    with open(os.path.join(root, "docs", "golden", f"{name}.json"), "w", encoding="utf-8") as f:
        f.write(text + "\n")
    lines = [f"// 由 docs/golden/scripts/sort.py 生成，勿手改", "", "///|", f"let golden_{name} : String ="]
    lines += ["  #|" + line for line in text.split("\n")]
    with open(os.path.join(root, "src", "pl", f"golden_{name}_data_wbtest.mbt"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def main():
    cases = build_series_cases()
    ids = [c["id"] for c in cases]
    assert len(ids) == len(set(ids)), "duplicate case ids"
    emit("sort", {"cases": cases, "inputs": INPUTS}, compact=True)
    sort, unique = multi_cases()
    ids = [c["id"] for c in sort + unique]
    assert len(ids) == len(set(ids)), "duplicate multi case ids"
    emit_wbtest("sort_multi", {"sort": sort, "unique": unique})
    print(f"polars {pl.__version__}: wrote {len(cases)} series cases, {len(sort)} multi sort, {len(unique)} multi unique")


main()
