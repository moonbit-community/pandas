"""Golden data for `write_csv_str`: polars' `DataFrame.write_csv()` text.

Run from the repository root (needs polars 2.1.0):

    python docs/golden/scripts/csv_write.py

Writes `docs/golden/csv_write.json` and `src/pl/golden_csv_write_data_test.mbt`.

Every case is `{"id", "polars", "frame", "options", "output"}`:
`frame` is the list of columns (`emit.encode_series`), `options` holds the
`write_csv` keyword arguments that are not the default (`include_header`,
`separator`, `line_terminator`, `quote_char`, `quote_style`, `null_value`,
`include_bom`), `output` is the text polars returns. A case with
`"restricted": true` has `"error": "InvalidOperation"` instead of `output`:
polars accepts the option (and writes unreadable text), the library rejects
it.

Not covered (the library has no such option or type): `float_precision`,
`float_scientific`, `decimal_comma`, `date_format`, `datetime_format`,
`time_format`, `batch_size`, compression, the other dtypes, non-ASCII
separators (polars: single byte only). A number whose text contains the
separator (`separator="."` with floats) is a known difference.
"""
import warnings

warnings.simplefilter("ignore")

import polars as pl

from emit import emit, encode_series, series_from_spec

NAN = float("nan")
INF = float("inf")

PL_DTYPES = {
    "bool": "pl.Boolean",
    "i32": "pl.Int32",
    "i64": "pl.Int64",
    "f32": "pl.Float32",
    "f64": "pl.Float64",
    "str": "pl.String",
    "null": "pl.Null",
}


def pyrepr(v):
    if isinstance(v, float):
        if v != v:
            return "float('nan')"
        if v in (INF, -INF):
            return "float('inf')" if v > 0 else "-float('inf')"
    return repr(v)


def series_text(name, dtype, values):
    vals = "[" + ", ".join(pyrepr(v) for v in values) + "]"
    if dtype == "date":
        return f"pl.Series({name!r}, {vals}, dtype=pl.Int32).cast(pl.Date)"
    if dtype == "datetime[μs]":
        return f"pl.Series({name!r}, {vals}, dtype=pl.Int64).cast(pl.Datetime('us'))"
    return f"pl.Series({name!r}, {vals}, dtype={PL_DTYPES[dtype]})"


def build(cols):
    return pl.DataFrame([series_from_spec(n, d, v) for n, d, v in cols])


def frame_text(cols):
    if not cols:
        return "pl.DataFrame()"
    return "pl.DataFrame([" + ", ".join(series_text(*c) for c in cols) + "])"


def call_text(opts):
    return ", ".join(f"{k}={v!r}" for k, v in sorted(opts.items()))


cases = []
seen = set()


def add(cid, cols, **opts):
    assert cid not in seen, cid
    seen.add(cid)
    df = build(cols)
    out = df.write_csv(**opts)
    assert isinstance(out, str)
    cases.append(
        {
            "id": cid,
            "polars": f"{frame_text(cols)}.write_csv({call_text(opts)})",
            "frame": [encode_series(s) for s in df.get_columns()],
            "options": opts,
            "output": out,
        }
    )


def add_restricted(cid, cols, **opts):
    assert cid not in seen, cid
    seen.add(cid)
    df = build(cols)
    df.write_csv(**opts)  # polars accepts it
    cases.append(
        {
            "id": cid,
            "polars": f"{frame_text(cols)}.write_csv({call_text(opts)})",
            "frame": [encode_series(s) for s in df.get_columns()],
            "options": opts,
            "error": "InvalidOperation",
            "restricted": True,
        }
    )


# ---- one column per dtype, default options -------------------------------
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
add("dtype/i32", [("a", "i32", [0, 1, -1, 2147483647, -2147483648, None])])
add("dtype/i64", [("a", "i64", [0, 7, -1, I64_MAX, I64_MIN, None])])
add("dtype/bool", [("a", "bool", [True, False, None, True])])
F64_A = [
    1.0, 0.1, -0.0, 0.0, 1e20, 1e21, 1e15, 1e16, 1.2345678901234568e17,
    0.00001, 1e-6, 9.99e-6, 1e-7, 1.5e-10, 5e-324, 1.7976931348623157e308,
]
F64_B = [
    0.30000000000000004, 123456780000000.0, 0.000025, 0.0000100001,
    9999999999999998.0, NAN, INF, -INF, -2.5, None, 100.0, 2.5e-5, -1e-5,
    1e100, -1e-100, 12345.678,
]
add("dtype/f64/a", [("a", "f64", F64_A)])
add("dtype/f64/b", [("a", "f64", F64_B)])
add("dtype/f64/nan-null", [("a", "f64", [NAN, None])])
F32_A = [
    0.1, 0.000001, 0.0000015, 9.99e-7, 1e-7, 10000000000.0, 1000000000000.0,
    1e13, 1e15, 3.4028235e38, 123456789.0, 123456.79, 1.1754944e-38, -0.0,
]
F32_B = [0.0, 1.0, -2.5, NAN, INF, -INF, None, 1e-45, 16777216.0, 0.3333333, 1e-6, 1e12]
add("dtype/f32/a", [("a", "f32", F32_A)])
add("dtype/f32/b", [("a", "f32", F32_B)])
add(
    "dtype/str",
    [
        (
            "a",
            "str",
            ["x", "a,b", "", None, "1", "-2.5", 'a"b', " lead", "trail ", "l1\nl2",
             "l1\r\nl2", "cr\rcr", "tab\tx", "semi;colon", "#hash", "NA", "null",
             " ", " ", '"', '""', ",", "你好", "\U0001f600", "﻿bom"],
        )
    ],
)
DATES = [0, -1, 19723, 2932896, 2932897, 3000000, -719162, -719528, -800000,
         90000000, -90000000, 1, None, 11016, -25567]
add("dtype/date", [("a", "date", DATES)])
DT = [0, 1704164645000000, 1704164645123456, -1500000, -1, 86399999999,
      253402300800000000, -62135596800000000, 1, 999999, None,
      -12219292800000000, 4102444800000000]
add("dtype/datetime", [("a", "datetime[μs]", DT)])
add("dtype/null", [("a", "null", [None, None, None])])
add("dtype/null+int", [("n", "null", [None, None]), ("m", "i64", [1, 2])])

# ---- quote_style on a mixed frame (every quote style, nulls and empties) ---
STYLE_COLS = [
    ("s", "str", ["x", "a,b", "", None, "1", "-2.5", 'a"b', " lead"]),
    ("i", "i64", [1, None, -3, 4, 5, 6, 7, 8]),
    ("f", "f64", [1.5, NAN, INF, -INF, None, 1e20, -0.0, 0.1]),
    ("b", "bool", [True, False, None, True, True, True, True, True]),
    ("d", "date", [0, 19724, None, 1, 2, 3, 4, 5]),
    ("t", "datetime[μs]", [0, 1704164645123456, None, 1, 2, 3, 4, 5]),
    ("g", "f32", [0.1, None, 1.5, NAN, 1e13, 3.0, 4.0, 5.0]),
    ("n", "null", [None] * 8),
    ("j", "i32", [None, 1, 2, 3, 4, 5, 6, 7]),
]
for qs in ("necessary", "always", "non_numeric", "never"):
    add(f"style/{qs}", STYLE_COLS, quote_style=qs)
    add(f"style/{qs}/null-NA", STYLE_COLS, quote_style=qs, null_value="NA")
    add(f"style/{qs}/no-header", STYLE_COLS, quote_style=qs, include_header=False)
    add(f"style/{qs}/quote-apostrophe", STYLE_COLS, quote_style=qs, quote_char="'")
    add(f"style/{qs}/sep-semicolon", STYLE_COLS, quote_style=qs, separator=";")
    add(f"style/{qs}/crlf", STYLE_COLS, quote_style=qs, line_terminator="\r\n")
add("style/default-is-necessary", STYLE_COLS)
add("style/none-is-necessary", STYLE_COLS, quote_style=None)

# ---- header names ---------------------------------------------------------
HEAD_COLS = [
    ("a,b", "i32", [1]), ("c\"d", "i32", [2]), ("e f", "i32", [3]),
    (" g", "i32", [4]), ("", "i32", [5]), ("h\ni", "i32", [6]),
    ("j;k", "i32", [7]), ("é", "i32", [8]), ("1", "i32", [9]),
]
for qs in ("necessary", "always", "non_numeric", "never"):
    add(f"header/{qs}", HEAD_COLS, quote_style=qs)
add("header/sep-semicolon", HEAD_COLS, separator=";")
add("header/quote-apostrophe", HEAD_COLS, quote_char="'")

# ---- shapes ---------------------------------------------------------------
ZERO_ROWS = [("a", "i64", []), ("b", "str", [])]
for qs in ("necessary", "always", "non_numeric", "never"):
    add(f"shape/zero-rows/{qs}", ZERO_ROWS, quote_style=qs)
    add(f"shape/zero-cols/{qs}", [], quote_style=qs)
add("shape/zero-rows", ZERO_ROWS)
add("shape/zero-rows/no-header", ZERO_ROWS, include_header=False)
add("shape/zero-rows/crlf", ZERO_ROWS, line_terminator="\r\n")
add("shape/zero-rows/bom", ZERO_ROWS, include_bom=True)
add("shape/zero-rows/bom-no-header", ZERO_ROWS, include_bom=True, include_header=False)
add("shape/zero-rows/all-dtypes", [
    ("a", "i32", []), ("b", "i64", []), ("c", "f64", []), ("d", "f32", []),
    ("e", "bool", []), ("f", "str", []), ("g", "date", []),
    ("h", "datetime[μs]", []), ("i", "null", []),
])
add("shape/zero-cols", [])
add("shape/zero-cols/no-header", [], include_header=False)
add("shape/zero-cols/crlf", [], line_terminator="\r\n")
add("shape/zero-cols/empty-terminator", [], line_terminator="")
add("shape/zero-cols/bom", [], include_bom=True)
add("shape/zero-cols/bom-no-header", [], include_bom=True, include_header=False)
add("shape/one-null-row", [("a", "str", [None])])
add("shape/two-null-rows", [("a", "str", [None, None])])
add("shape/one-null-row/int", [("a", "i64", [None])])
add("shape/one-null-row/null-dtype", [("a", "null", [None])])
add("shape/two-cols-null-row", [("a", "str", [None]), ("b", "str", [None])])
add("shape/one-empty-string", [("a", "str", [""])])
add("shape/one-empty-string/always", [("a", "str", [""])], quote_style="always")
add("shape/one-empty-string/never", [("a", "str", [""])], quote_style="never")
add("shape/one-null-row/always", [("a", "str", [None])], quote_style="always")
add("shape/one-null-row/null-NA", [("a", "str", [None])], null_value="NA")
add("shape/many-cols", [(f"c{i}", "i32", [i, None]) for i in range(12)])

# ---- null_value -----------------------------------------------------------
NULL_COLS = [
    ("a", "str", ["x,y", None, "", "it's"]),
    ("b", "i64", [1, None, 3, 4]),
    ("c", "f64", [None, 1.5, None, NAN]),
    ("d", "bool", [None, True, False, None]),
    ("e", "date", [None, 0, None, 1]),
    ("f", "null", [None] * 4),
]
for nv in ("NA", "null", "-", "x,y", 'a"b', "", "é", " ", "NULL\n"):
    add(f"null_value/{nv!r}", NULL_COLS, null_value=nv)
for qs in ("always", "non_numeric", "never"):
    for nv in ("NA", ""):
        add(f"null_value/{nv!r}/{qs}", NULL_COLS, null_value=nv, quote_style=qs)
add("null_value/default-none", NULL_COLS, null_value=None)

# ---- line_terminator ------------------------------------------------------
LT_COLS = [("a", "i32", [1, 2]), ("b", "str", ["x;;y", 'p"q'])]
for lt in ("\r\n", "", ";;", "\r", "\n\n", "\n", "|", "\t"):
    add(f"line_terminator/{lt!r}", LT_COLS, line_terminator=lt)
    add(f"line_terminator/{lt!r}/no-header", LT_COLS, line_terminator=lt, include_header=False)
add("line_terminator/semicolon-sep", LT_COLS, line_terminator=";;", separator=";")
add("line_terminator/always", LT_COLS, line_terminator="\r\n", quote_style="always")

# ---- quote_char -----------------------------------------------------------
Q_COLS = [
    ("it's", "str", ["it's", 'q"r', "x,y", "", None, "'", "''"]),
    ("n", "i32", [1, 2, 3, 4, 5, 6, 7]),
]
for qc in ("'", "|", "`", "x", "\t"):
    add(f"quote_char/{qc!r}", Q_COLS, quote_char=qc)
    add(f"quote_char/{qc!r}/always", Q_COLS, quote_char=qc, quote_style="always")
    add(f"quote_char/{qc!r}/non_numeric", Q_COLS, quote_char=qc, quote_style="non_numeric")
add("quote_char/apostrophe/never", Q_COLS, quote_char="'", quote_style="never")

# ---- separator ------------------------------------------------------------
S_COLS = [
    ("a", "str", ["x,y", "p;q", "t\tu", "a b", "p|q", "", None, "axb", "tab"]),
    ("b", "i32", [1, 2, 3, 4, 5, 6, 7, 8, 9]),
    ("c", "date", [0, 1, 2, 3, 4, 5, 6, 7, 8]),
]
for sep in (";", "\t", " ", "|", ":", "a", "x", "t", "b", "\x01"):
    add(f"separator/{sep!r}", S_COLS, separator=sep)
    add(f"separator/{sep!r}/always", S_COLS, separator=sep, quote_style="always")
add("separator/semicolon/non_numeric", S_COLS, separator=";", quote_style="non_numeric")
add("separator/tab/never", S_COLS, separator="\t", quote_style="never")

# ---- include_header / include_bom ----------------------------------------
PLAIN = [("a", "i32", [1, 2]), ("b", "str", ["x", None])]
add("header/off", PLAIN, include_header=False)
add("header/on", PLAIN, include_header=True)
add("bom/on", PLAIN, include_bom=True)
add("bom/off", PLAIN, include_bom=False)
add("bom/on/no-header", PLAIN, include_bom=True, include_header=False)
add("bom/on/crlf-always", PLAIN, include_bom=True, line_terminator="\r\n", quote_style="always")
add("bom/on/one-null-row", [("a", "str", [None])], include_bom=True)

# ---- all options at once --------------------------------------------------
add(
    "combo/all-options",
    STYLE_COLS,
    include_header=True,
    separator="|",
    line_terminator="\r\n",
    quote_char="'",
    quote_style="non_numeric",
    null_value="<null>",
    include_bom=True,
)
add(
    "combo/always-tab-bom",
    STYLE_COLS,
    separator="\t",
    quote_style="always",
    null_value="N/A",
    include_bom=True,
    include_header=False,
)

# ---- options the library rejects (polars writes unreadable text) ----------
BASIC = [("a", "i32", [1, 2])]
add_restricted("invalid/separator-lf", BASIC, separator="\n")
add_restricted("invalid/separator-cr", BASIC, separator="\r")
add_restricted("invalid/quote-lf", BASIC, quote_char="\n")
add_restricted("invalid/quote-cr", BASIC, quote_char="\r")
add_restricted("invalid/separator-eq-quote", BASIC, separator="'", quote_char="'")
add_restricted("invalid/comma-eq-quote", BASIC, separator=",", quote_char=",")
add_restricted("invalid/quote-eq-default-separator", BASIC, quote_char=",")
add_restricted("invalid/separator-eq-default-quote", BASIC, separator='"')

emit("csv_write", {"cases": cases}, compact=True)
errors = sum(1 for c in cases if "error" in c)
print(f"{len(cases)} cases, {errors} restricted errors")
