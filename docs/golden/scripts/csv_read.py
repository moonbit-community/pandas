"""Golden data for `read_csv_str`: `pl.read_csv` on CSV text.

Run from the repository root (needs polars 2.1.0):

    python docs/golden/scripts/csv_read.py

Writes `docs/golden/csv_read.json` and `src/pl/golden_csv_read_data_test.mbt`.

Every case is `{"id", "polars", "input", "options", ...}`; `polars` is the call
(`text` is the case's `input`), `options` holds the `CsvReadOptions` fields
that differ from the defaults (`separator`, `has_header`, `quote_char`,
`null_values`, `schema_overrides` as `{name: dtype name}`, `infer_schema_length`,
`n_rows`, `skip_rows`, `try_parse_dates`). The expectation is either

* `"columns"`: the frame, a list of `{"name", "dtype", "values"}` (see
  `emit.encode_series`), or
* `"error"` and `"message"`: the `PolarsError` variant and message.

polars raises `ComputeError` / `NoDataError` for a bad value, a long row, a bad
quote and empty input; the library raises `ParseError` with the first line of
polars' message and ` at line N`, N being the physical line (1 based) of the
start of the offending record (`empty CSV` has no line). Those cases carry
`"restricted": true`, and so do the cases where polars has a type the library
has not (`Time`, a `Datetime` with a time zone): the expected frame is then
polars' result read with that column as String, see `"note"`. An integer text
beyond `Int64` inside the inference window follows polars where the library has
the type: next to a float-shaped value (`1.5`, `inf`, `1e3`) and no small integer
the column is Float64 in both; with small integers, big ones and floats together
it is String in both. With no float-shaped value polars reads `Int128`, the
library String: those cases are restricted, the expected value is polars' result
with that column read as String (so are cases where polars raises and the library
reads the column as String).

The groups of cases: hand-made tables (inference, infer_schema_length,
headers, shapes, RFC 4180, separators, n_rows and skip_rows, overrides), every
single value text and every ordered pair of 14 texts as a one-column file, with
and without `try_parse_dates`, and seeded random tables.
"""
import io
import itertools
import random
import re
import warnings

warnings.simplefilter("ignore")

import polars as pl

from emit import emit, encode_series

DT = {
    "i32": ("pl.Int32", pl.Int32),
    "i64": ("pl.Int64", pl.Int64),
    "f32": ("pl.Float32", pl.Float32),
    "f64": ("pl.Float64", pl.Float64),
    "bool": ("pl.Boolean", pl.Boolean),
    "str": ("pl.String", pl.String),
    "date": ("pl.Date", pl.Date),
    "datetime[μs]": ('pl.Datetime("us")', pl.Datetime("us")),
    "null": ("pl.Null", pl.Null),
}

CASES = []
IDS = set()


def kwargs_of(opts):
    kw = {}
    for key, v in opts.items():
        if key == "schema_overrides":
            kw[key] = {n: DT[d][1] for n, d in v.items()}
        else:
            kw[key] = v
    return kw


def call_text(opts):
    parts = ["io.BytesIO(text.encode())"]
    for key, v in opts.items():
        if key == "schema_overrides":
            body = ", ".join(f"{n!r}: {DT[d][0]}" for n, d in v.items())
            parts.append(f"{key}={{{body}}}")
        else:
            parts.append(f"{key}={v!r}")
    return "pl.read_csv(" + ", ".join(parts) + ")"


def line_of(text, at):
    """The physical line (1 based) of the record that starts at `at`: a line
    number, or the text where the record starts."""
    if isinstance(at, int):
        return at
    idx = text.index(at)
    return 1 + text[:idx].count("\n")


def bad_line(rows, opts, header="a"):
    """The line of the first of the one-column `rows` that makes the read fail
    (rows are lines 2, 3, ...)."""
    for k in range(1, len(rows) + 1):
        try:
            read(header + "\n" + "\n".join(rows[:k]) + "\n", opts)
        except Exception:  # noqa: BLE001
            return k + 1
    return None


def read(text, opts):
    return pl.read_csv(io.BytesIO(text.encode()), **kwargs_of(opts))


def supported(df):
    """The columns whose dtype the library has not: `{index: fallback}`."""
    bad = {}
    for i, (name, dtype) in enumerate(zip(df.columns, df.dtypes)):
        if dtype in (pl.Int128,):
            bad[i] = ("str", "integer beyond Int64: polars reads Int128, the library String")
        elif dtype == pl.Time:
            bad[i] = ("str", "time of day: polars reads Time, the library keeps String")
        elif isinstance(dtype, pl.Datetime) and dtype.time_zone is not None:
            bad[i] = ("str", "offset: polars reads Datetime with a time zone, the library keeps String")
        elif dtype not in [d[1] for d in DT.values()] and not isinstance(dtype, pl.Datetime):
            raise ValueError(f"unexpected dtype {dtype}")
    return bad


def auto_line(text, opts, first):
    """The line of the record that raises `first`, for a text without quotes:
    the shortest run of whole lines that raises the same message."""
    assert '"' not in text and "'" not in text, ("give `at` for a quoted text", text)
    pos = 0
    while True:
        pos = text.find("\n", pos)
        prefix = text if pos < 0 else text[: pos + 1]
        try:
            read(prefix, opts)
        except Exception as e:  # noqa: BLE001
            if str(e).split("\n")[0] == first:
                return prefix.count("\n") if prefix.endswith("\n") else prefix.count("\n") + 1
        if pos < 0:
            raise AssertionError(("no line found", text, first))
        pos += 1


FLOAT_SHAPE = re.compile(
    r"[+-]?(inf|NaN|[0-9]+\.|[0-9]*\.[0-9]+([eE][+-]?[0-9]+)?|[0-9]+\.[0-9]+([eE][+-]?[0-9]+)?|[0-9]+[eE][+-]?[0-9]+)"
)


def big_cols(text, opts):
    """The columns (not overridden) that the library reads as String because of
    an integer text beyond Int64 inside the inference window: one with no
    float-shaped value (polars: Int128), or with a small integer as well as a
    float (polars gives String there too). Big + float and no small integer is
    Float64 in both."""
    skip = ("schema_overrides", "n_rows", "infer_schema_length", "try_parse_dates")
    kw = {k: v for k, v in opts.items() if k not in skip}
    try:
        df = pl.read_csv(io.BytesIO(text.encode()), infer_schema_length=0, **kwargs_of(kw))
    except Exception:  # noqa: BLE001
        return []
    window = opts.get("infer_schema_length", 100)
    if window is not None:
        df = df.head(window)
    out = []
    for name in df.columns:
        if name in opts.get("schema_overrides", {}):
            continue
        vals = [v for v in df[name].to_list() if v is not None]
        big = [v for v in vals if re.fullmatch(r"-?[0-9]+", v) and not (-(2**63) <= int(v) < 2**63)]
        small = [v for v in vals if re.fullmatch(r"-?[0-9]+", v) and (-(2**63) <= int(v) < 2**63)]
        flt = [v for v in vals if FLOAT_SHAPE.fullmatch(v)]
        if big and (small or not flt):
            out.append(name)
    return out


def add(cid, text, at=None, expect_error=None, **opts):
    """One case. `at`: text where the offending record starts (error cases)."""
    assert cid not in IDS, cid
    IDS.add(cid)
    rec = {"id": cid, "input": text, "options": opts, "polars": call_text(opts)}
    # what the library reads: a column with an integer beyond Int64 in the
    # window is a String, which polars gives only in some of the mixes
    forced = False
    eff = opts
    bigs = big_cols(text, opts)
    if bigs:
        try:
            orig = read(text, opts)
        except Exception:  # noqa: BLE001
            orig = None
        if orig is None or not all(orig[c].dtype == pl.String for c in bigs):
            forced = True
            eff = {**opts, "schema_overrides": {**opts.get("schema_overrides", {}), **{c: "str" for c in bigs}}}
    try:
        df = read(text, eff)
    except Exception as e:  # noqa: BLE001
        cls = type(e).__name__
        first = str(e).split("\n")[0]
        if cls == "DuplicateError":
            rec["error"] = "DuplicateColumn"
            rec["message"] = first
        elif cls == "ComputeError" and first.startswith("unsupported data type when reading CSV"):
            rec["error"] = "ComputeError"
            rec["message"] = first
        elif cls == "NoDataError":
            assert first == "empty CSV"
            rec["error"] = "ParseError"
            rec["message"] = first
            rec["restricted"] = True
        elif cls == "ComputeError":
            if at is None:
                at = auto_line(text, eff, first)
            rec["error"] = "ParseError"
            rec["message"] = f"{first} at line {line_of(text, at)}"
            rec["restricted"] = True
        else:
            raise
        assert expect_error is None or expect_error in rec["message"], (cid, rec["message"])
        CASES.append(rec)
        return
    assert expect_error is None, (cid, "expected an error")
    bad = supported(df)
    if forced:
        rec["restricted"] = True
        rec["note"] = "integer beyond Int64 in the inference window: polars gives Int128 (or an error), the library String"
    if bad:
        # the library reads those columns as the fallback type
        ours = dict(eff.get("schema_overrides", {}))
        notes = []
        for i, (dname, note) in bad.items():
            ours[df.columns[i]] = dname
            notes.append(note)
        df = read(text, {**eff, "schema_overrides": ours})
        assert not supported(df), cid
        rec["restricted"] = True
        rec["note"] = "; ".join(sorted(set(notes + ([rec["note"]] if forced else []))))
    rec["columns"] = [encode_series(df[c]) for c in df.columns]
    CASES.append(rec)



def one(cid, text, **opts):
    add(cid, text, **opts)


# ---------------------------------------------------------------------------
# A2.a inference
VALUES = [
    "1", "-2", "007", "-007", "-0", "+5", "-", "+", ".", "9223372036854775807", "-9223372036854775808",
    "9223372036854775808", "-9223372036854775809", "1" * 25, "1.5", ".5", "5.", "-.5", "+1.5", "+.5",
    "1e3", "1E-3", "1e+3", "+1e3", "1e5", "00.5", "1e400", "1e", "1e+", "e3", "1e3.5", "1.5.5", "1_000",
    "0x10", "1e5f", "1.e5", ".e5", "5e3", "inf", "-inf", "+inf", "Inf", "INF", "infinity", "-nan", "NaN",
    "+NaN", "-NaN", "nan", "NAN", "nAn", "true", "True", "TRUE", "tRuE", "false", "FALSE", "t", "yes",
    "1", "0", " 1", "1 ", " x ", " true", "true ", "NA", "null", "NULL", "None", "N/A",
    "2024-01-02", "2024-1-2", "2024/01/02", "2024.01.02", "01/02/2024", "1/2/2024", "02-01-2024",
    "02.01.2024", "24-01-15", "99-12-31", "  2024-01-02", " 2024- 01-02", "+2024-01-02", "+12024-01-02",
    "2024-01-02 ", "2024-01-02T", "12024-01-02", "2024-13-01", "2024-02-30", "2023-02-29", "2024-01",
    "Jan 2 2024", "20240102", "2024", "2024-01-02T03:04:05", "2024-01-02 03:04:05", "T03:04", "T03:04:05.5",
    ".123456789", "T3:4:5", "2024/01/02 03:04:05", "02/01/2024 03:04:05", "T03:04:60",
    "2024-01-02T03:04:05Z", "2024-01-02T03:04:05 +0100", "2024-01-02T03:04:05+01:00", "03:04:05",
    "03:04:05.123", "T24:00:00", "2024-01-02T03:04:05.123456789", "né", "日本", "😀", "a b", " 1",
]
seen_vals = set()
for v in VALUES:
    if v in seen_vals:
        continue
    seen_vals.add(v)
    for dates in (False, True):
        opts = {"try_parse_dates": True} if dates else {}
        text = f"a\n{v}\n"
        one(f"infer/{'d' if dates else 'n'}/{v!r}", text, **opts)
        # quoted, with a second row
        if not dates and len(seen_vals) % 3 == 0:
            one(f"infer2/n/{v!r}", f'a\n"{v}"\n{v}\n', **opts)

# ordered pairs
POOL = [
    "1", "+5", "2.5", "inf", "nan", "true", "x", "", '""', "9223372036854775808", "2024-01-02", "01/02/2024",
    "2024-01-02T01:02:03", "2024-01-02T01:02:03Z",
]
for dates in (False, True):
    opts = {"try_parse_dates": True} if dates else {}
    for x, y in itertools.product(POOL, repeat=2):
        one(f"pair/{'d' if dates else 'n'}/{x!r},{y!r}", f"a\n{x}\n{y}\n", **opts)

# all-empty, quoted-empty, quoted numbers
one("infer/all-empty", "a,b\n1,\n2,\n")
one("infer/quoted-empty", 'a,b\n1,""\n2,""\n')
one("infer/quoted-empty-mixed", 'a\n1\n\n""\n5\n')
one("infer/quoted-numbers", 'a,b,c\n"1","1.5","true"\n')
one("infer/null-words", "a\nNA\nnull\nNULL\nNone\nN/A\nnan\n-\n")
one("infer/empty-vs-missing", "a,b,c\n1,2\n")

# ---------------------------------------------------------------------------
# A2.b infer_schema_length
for isl in (0, 1, 2, None):
    for cid, text, at in [
        ("x-at-4", "a\n1\n2\n3\nx\n5\n", "x\n"),
        ("float-at-4", "a\n1\n2\n3\n1.5\n", "1.5"),
        ("big-at-4", "a\n1\n2\n3\n9223372036854775808\n", "9223372036854775808"),
        ("inf-at-4", "a\n1\n2\n3\ninf\n", "inf"),
        ("bool-col-x", "a\ntrue\nfalse\nTRUE\nx\n", "x\n"),
        ("float-col-x", "a\n1.5\n2.5\n3.5\nx\n", "x\n"),
        ("float-col-int", "a\n1.5\n2.5\n3\n", None),
        ("int-plus", "a\n1\n2\n+5\n", None),
        ("int-space", "a\n1\n2\n 5\n", None),
        ("int-space-after", "a\n1\n2\n5 \n", "5 "),
        ("float-nan", "a\n1.5\n2.5\nnan\n", None),
        ("float-Inf", "a\n1.5\n2.5\nInf\n", None),
        ("bool-1", "a\ntrue\nfalse\n1\n", "1\n"),
        ("quoted-empty-later", 'a\n1\n2\n""\n', None),
        ("quoted-x-later", 'a\n1\n2\n"x"\n', '"x"'),
        ("quoted-esc-later", 'a\n1\n2\n"x""y"\n', '"x""y"'),
        ("quoted-nl-later", 'a\n1\n2\n"x\ny"\n', '"x\ny"'),
        ("quoted-comma-later", 'a\n1\n2\n"x,y"\n', '"x,y"'),
        ("str-then-int", "a\nx\ny\n3\n", None),
        ("empty-then-value", "a,b\n,\n,\n1,5\n", None),
        ("nulls-then-float", "a\n\n\n1.5\n", None),
        ("two-cols", "b,a\n1,2\n1,3\n1,x\n", "1,x"),
        ("crlf", "a\r\n1\r\n2\r\nx\r\n", "x\r"),
        ("date-later-ok", "a\n2024-01-02\n2024-01-03\n2024-1-4\n", None),
    ]:
        opts = {"infer_schema_length": isl}
        if cid == "date-later-ok":
            opts["try_parse_dates"] = True
        add(f"isl/{isl}/{cid}", text, at=at, **opts)
# n_rows trims, the inference does not shrink
for cid, text in [
    ("float-after", "a\n1\n2.5\n"),
    ("x-after", "a\n1\nx\n"),
    ("two-cols", "a,b\n1,2\n3,x\n"),
]:
    for n in (0, 1, 5):
        add(f"n_rows/{n}/{cid}", text, n_rows=n)
        add(f"n_rows/{n}/{cid}/isl0", text, n_rows=n, infer_schema_length=0)
add("n_rows/ragged-in-window", "a,b\n1,2\n3,4\n5,6,7\n", at="5,6,7", n_rows=1)
add("n_rows/bad-quote-in-window", 'a,b\n1,2\n3,"x"y\n', at='3,"x"y', n_rows=1)

# ---------------------------------------------------------------------------
# A2.c headers
for cid, text in [
    ("dup2", "a,a\n1,2\n"),
    ("dup3", "a,a,a\n1,2,3\n"),
    ("dup5", "a,b,a,b,a\n1,2,3,4,5\n"),
    ("dup4", "a,a,a,a\n1,2,3,4\n"),
    ("case", "a,A\n1,2\n"),
    ("clash-1", "a,a,a_duplicated_0\n1,2,3\n"),
    ("clash-2", "a_duplicated_0,a,a\n1,2,3\n"),
    ("clash-3", "a,a_duplicated_0,a\n1,2,3\n"),
    ("clash-4", "a,a,a,a_duplicated_1\n1,2,3,4\n"),
    ("empty-name", "a,,b\n1,2,3\n"),
    ("empty-names", ",,\n1,2,3\n"),
    ("empty-first", ",a\n1,2\n"),
    ("trailing-sep", "a,b,\n1,2,3\n"),
    ("trailing-sep-short", "a,b,\n1,2\n"),
    ("spaces", " a , b \n1,2\n"),
    ("quoted", '"a b","c,d"\n1,2\n'),
    ("quoted-esc", '"a""b"\n1\n'),
    ("quoted-nl", 'a,"b\nc"\n1,2\n'),
    ("quoted-empty", '""\n1\n'),
    ("quoted-first", '"a",b\n1,2\n'),
    ("leading-blank", "\n1\n2\n"),
    ("leading-blank-crlf", "\r\na\r\n1\r\n"),
    ("only-header", "a,b\n"),
    ("only-header-no-nl", "a,b"),
    ("only-header-crlf", "a,b\r\n"),
    ("spaces-only", "  "),
    ("unicode", "né,日本,😀\n1,2,3\n"),
    ("bom", "﻿a,b\n1,2\n"),
    ("bom-quoted", '﻿"a",b\n1,2\n'),
    ("bom-blank", "﻿\na,b\n1,2\n"),
    ("bom-mid", "a\n1\n﻿2\n"),
    ("trailing-sep-data", "a,b\n1,2,\n"),
]:
    at = {"clash-1": None, "trailing-sep-data": "1,2,"}.get(cid)
    add(f"header/{cid}", text, at=at)
for cid, text in [("dup", "a,a\n1,2\n")]:
    add("header/override-first", text, schema_overrides={"a": "str"})
    add("header/override-second", text, schema_overrides={"a_duplicated_0": "str"})
add("header/typed-empty", "a,b\n", schema_overrides={"a": "i32"})
add("header/typed-empty-2", "a,b\n", schema_overrides={"a": "date", "b": "datetime[μs]"})

# no header
NH = {"has_header": False}
for cid, text in [
    ("plain", "1,2\n3,4\n"),
    ("blank-first", "\n1,2\n3,4\n"),
    ("short-first", "1\n3,4\n"),
    ("long-later", "1,2\n3,4,5\n"),
    ("only-nl", "\n"),
    ("only-nls", "\n\n"),
    ("quoted", '"a b",2\n'),
    ("dup", "a,a\n"),
    ("empty-fields", ",\n"),
    ("blank-mid", "1,2\n\n3,4\n"),
    ("crlf-blank", "1,2\r\n\r\n3,4\r\n"),
    ("bom-only", "﻿"),
    ("empty", ""),
    ("one-line", "x\n"),
]:
    add(f"noheader/{cid}", text, **NH)
add("noheader/n_rows0", "1,2\n3,4\n", n_rows=0, **NH)
add("noheader/n_rows1", "1,2\n3,4\n", n_rows=1, **NH)
add("noheader/skip", "x\n1,2\n3,4\n", skip_rows=1, **NH)
add("noheader/skip-all", "x\n1,2\n3,4\n", skip_rows=5, **NH)
add("noheader/isl0", "1,2\n3,4\n", infer_schema_length=0, **NH)
add("noheader/isl1-wider", "1\n2,3\n4,5,6\n", at="2,3", infer_schema_length=1, **NH)
add("noheader/isl2-wider", "1\n2,3\n4,5,6\n", at="4,5,6", infer_schema_length=2, **NH)
add("noheader/isl-none", "1\n2,3\n4,5,6\n", infer_schema_length=None, **NH)
add("noheader/override", "1,2\n", schema_overrides={"column_0": "str"}, **NH)

# ---------------------------------------------------------------------------
# A2.d shapes
for cid, text, at in [
    ("long-first", "a,b\n1,2,3\n", "1,2,3"),
    ("long-later", "a,b\n1,2\n3,4,5\n", "3,4,5"),
    ("long-after-blank", "a,b\n\n\n1,2,3\n", "1,2,3"),
    ("long-quoted", 'a\n1,"x"y\n', '1,"x"y'),
    ("long-after-multiline", 'a,b\n"p\nq",1\n3,4,5\n', "3,4,5"),
    ("short-1", "a,b,c\n1\n2,3\n", None),
    ("short-last-no-nl", "a,b,c\n1,2", None),
    ("short-quoted", 'a,b,c\n"x"\n', None),
    ("trailing-nl", "a,b\n1,2\n", None),
    ("no-trailing-nl", "a,b\n1,2", None),
    ("blank-last", "a,b\n1,2\n\n", None),
    ("blank-last-3", "a,b\n1,2\n\n\n", None),
    ("blank-mid-1col", "a\n1\n\n3\n", None),
    ("blank-mid-2col", "a,b\n1,2\n\n3,4\n", None),
    ("blank-crlf", "a\r\n1\r\n\r\n3\r\n", None),
    ("blank-crlf-2col", "a,b\r\n1,2\r\n\r\n", None),
    ("space-line", "a,b\n  \n1,2\n", None),
    ("blank-all-str", "a\n\n\n", None),
    ("blank-all-str-crlf", "a\r\n\r\n\r\n", None),
    ("blank-before-header-2", "\n\na,b\n1,2\n", None),
    ("empty", "", None),
    ("nl", "\n", None),
    ("nls", "\n\n", None),
    ("crlf", "\r\n", None),
    ("bom", "﻿", None),
    ("bom-nl", "﻿\n", None),
    ("header-no-nl", "a,b", None),
    ("header-spaces", "  ", None),
]:
    add(f"shape/{cid}", text, at=at)

# ---------------------------------------------------------------------------
# A2.e RFC 4180
for cid, text, at in [
    ("quoted-sep", 'a,b\n"x,y",2\n', None),
    ("quoted-nl", 'a,b\n"x\ny",2\n', None),
    ("quoted-crlf", 'a,b\n"x\r\ny",2\n', None),
    ("quoted-esc", 'a\n"he said ""hi"""\n', None),
    ("quoted-quote", 'a\n""""\n', None),
    ("quoted-lone-nl", 'a\n"\n"', None),
    ("crlf", "a,b\r\n1,2\r\n3,4\r\n", None),
    ("crlf-no-final", "a,b\r\n1,2\r\n3,4", None),
    ("mixed-eol", "a,b\r\n1,2\n3,4\r\n5,6", None),
    ("cr-in-field", "a\nx\ry\n", None),
    ("cr-after-quote", 'a,b\n1,"x"\r\n2,3\r\n', None),
    ("trailing-cr", "a\n1\r", None),
    ("trailing-cr-2", "a,b\n1,2\r", None),
    ("quote-mid-literal-1", 'a,b\nab"c"d,2\n', None),
    ("quote-mid-literal-2", 'a,b\nab"",2\n', None),
    ("quote-after-space", 'a,b\n "ab",2\n', None),
    ("trail-1", 'a,b\n"ab"c,2\n', '"ab"c'),
    ("trail-2", 'a,b\n"x" ,2\n', '"x" '),
    ("trail-3", 'a,b\n1,"x"y\n', '1,"x"y'),
    ("trail-4", 'a,b\n1,"x"y', '1,"x"y'),
    ("trail-5", 'a,b\r\n1,"x"y\r\n', '1,"x"y'),
    ("trail-6", 'a,b\n"x,y"z,2\n', '"x,y"z'),
    ("trail-7", 'a,b\n"x"  ,2\n', '"x"  '),
    ("trail-8", 'a,b\n1,"x" \n', '1,"x" '),
    ("trail-9", 'a,b\n1,2\n3,"x"y\n', '3,"x"y'),
    ("trail-10", 'a\n"x"y,2\n', '"x"y'),
    ("trail-multiline", 'a,b\n"p\nq",1\n3,"x"y\n', '3,"x"y'),
    ("open-1", 'a,b\n1,"abc', '1,"abc'),
    ("open-2", 'a,b\n1,"\n', '1,"'),
    ("open-3", 'a,b\n1,"x\ny,z\nq', '1,"x'),
    ("open-4", 'a,b\n1,"x\ny,z\nq\nw', '1,"x'),
    ("open-5", 'a,b\n1,2\n3,"x\ny\n', '3,"x'),
    ("open-6", 'a\n"x\ny"\n"z\n', '"z'),
    ("quote-none-1", 'a,b\n"x",2\n', None),
    ("quote-none-2", 'a,b\n"x,y",2\n', '"x,y"'),
    ("quote-none-3", 'a,b\nab"c,2\n', None),
    ("bom-quoted-first", '﻿"a",b\n1,2\n', None),
]:
    if cid.startswith("quote-none"):
        add(f"rfc/{cid}", text, at=at, quote_char=None)
    else:
        add(f"rfc/{cid}", text, at=at)
add("rfc/quote-single", "a,b\n'x,y',2\n", quote_char="'")
add("rfc/quote-single-dq", 'a,b\n"x,y",2\n', at='"x,y"', quote_char="'")
add("rfc/quote-single-esc", "a\n'it''s'\n", quote_char="'")

# ---------------------------------------------------------------------------
# A2.f separators
add("sep/tab", "a\tb\n1\t2\n", separator="\t")
add("sep/semicolon", "a;b\n1;2\n", separator=";")
add("sep/semicolon-quoted", 'a;b\n"1;2";3\n', separator=";")
add("sep/pipe", "a|b\n1|2\n", separator="|")
add("sep/space", "a b\n1 2\n", separator=" ")
add("sep/space-double", "a  b\n1  2\n", separator=" ")
add("sep/comma-in-semicolon", "a;b\n1,5;2\n", separator=";")
add("sep/quote-eq-sep-none", "a;b\n1;2\n", separator=";", quote_char=None)

# ---------------------------------------------------------------------------
# A2.g n_rows / skip_rows
D = "a,b\n1,2\n3,4\n5,6\n"
add("rows/n2", D, n_rows=2)
add("rows/n10", D, n_rows=10)
add("rows/n0", D, n_rows=0)
add("rows/n0-isl0", D, n_rows=0, infer_schema_length=0)
add("rows/n1-noheader", D, n_rows=1, has_header=False)
add("rows/skip1", D, skip_rows=1)
add("rows/skip1-noheader", D, skip_rows=1, has_header=False)
add("rows/skip3", D, skip_rows=3)
add("rows/skip4", D, skip_rows=4)
add("rows/skip9", D, skip_rows=9)
add("rows/skip1-n1", D, skip_rows=1, n_rows=1)
add("rows/skip-quoted", 'x\n"y\nz"\na,b\n1,2\n', skip_rows=2)
add("rows/skip-simple", "x\ny\na,b\n1,2\n", skip_rows=2)
add("rows/skip-header-only", "x\ny\na,b\n", skip_rows=2)
add("rows/skip-all", "x\ny\n", skip_rows=2)
add("rows/skip-all-1", "x\ny\n", skip_rows=1)
add("rows/skip-crlf", "x\r\ny\r\na,b\r\n1,2\r\n", skip_rows=2)
add("rows/skip-bom", "﻿x\na,b\n1,2\n", skip_rows=1)
add("rows/skip-0", "a\n1\n", skip_rows=0)
add("rows/skip-then-error", "junk\nmore\na\nx\n", at="x\n", skip_rows=2, schema_overrides={"a": "i64"})

# null_values
add("null/NA", "a,b\n1,NA\n2,x\nNA,y\n", null_values=["NA"])
add("null/quoted", 'a,b\n1,"NA"\n2,3\n', null_values=["NA"])
add("null/empty-list-item", 'a,b\n1,\n2,""\n', null_values=[""])
add("null/empty-list-item-2", 'a,b\n1,\n2,""\n3,x\n', null_values=[""])
add("null/header", "NA,b\n1,2\n", null_values=["NA"])
add("null/all", "a\nNA\nNA\n", null_values=["NA"])
add("null/space", "a\n 1\nNA \n", null_values=["NA"])
add("null/multi", "a\n1\n-\nNA\n", null_values=["NA", "-"])
add("null/quoted-empty", 'a\n1\n""\n', null_values=["NA"])
add("null/case", "a\n1\nna\nNA\n", null_values=["NA"])
add("null/date", "a\n2024-01-02\nNA\n", null_values=["NA"], try_parse_dates=True)
add("null/esc", 'a\n"a""b"\nc\n', null_values=['a"b'])
add("null/esc-raw", 'a\n"a""b"\nc\n', null_values=['a""b'])
add("null/quoted-nl", 'a\n"x\ny"\nc\n', null_values=["x\ny"])
add("null/float", "a\n1.5\n-\n2.5\n", null_values=["-"])
add("null/bool", "a\ntrue\nNA\nfalse\n", null_values=["NA"])
add("null/override", "a\n1\nNA\n3\n", null_values=["NA"], schema_overrides={"a": "i32"})
add("null/number", "a\n1\n0\n2\n", null_values=["0"])

# ---------------------------------------------------------------------------
# A2.h overrides
OV_TEXTS = {
    "i32": ["1", "3000000000", "1.5", "1e3", "1.0", "1 ", " 1", "+5", "007", "-2147483648", "2147483648", "x", "", '""', "\t7"],
    "i64": ["1", "9223372036854775807", "9223372036854775808", "-9223372036854775808", "+5", " 1", "1 ", "--5", "+-5", "+ 5", " +5", "-5", "x", "1.0", "2024-01-02", "", '""', "\t3", "  5"],
    "f32": ["0.1", "1e39", "-1e39", "3.4028235e38", "inf", "Inf", "nan", " 1.5", "1.5 ", "x", "+5", "1e-50", ""],
    "f64": ["+5", " 1.5", "1.5 ", "nan", "NaN", "Inf", "inf", "-inf", "-nan", "infinity", "9223372036854775808", "-9223372036854775809", "1e400", "-1e400", "1e-400", "x", ".", "1_0", "1e5", "\t1.5", " \t +1.5", "  -Inf", "", '""'],
    "bool": ["true", "False", "TRUE", "tRuE", "1", "0", "x", " true", "true ", "t", "yes", "", '""'],
    "str": ["007", " 1", "", '""', '"true"', "x y", "1,5"],
    "date": ["2024-01-02", "2024/01/02", " 2024-01-02", "2024-13-02", "2024.01.02", "01/02/2024", "02-01-2024", "2024-01-02T01:02:03", "2024-01-02 ", "x", "", '""', "99-12-31", "+2024-01-02", "2024-02-30"],
    "datetime[μs]": ["2024-01-02T01:02:03", "2024-01-02 01:02:03", "2024-01-02", "2024-1-2 1:2:3", " 2024-01-02T01:02:03", "2024-01-02T01:02:03.123456789", "2024-01-02T01:02:03.5", "2024-01-02T01:02", "2024/01/02 03:04:05", "02/01/2024 03:04:05", "x", "", '""', "T03:04", "2024-01-02T01:02:60"],
}
for dname, texts in OV_TEXTS.items():
    for t in texts:
        ov = {"schema_overrides": {"a": dname}}
        add(f"ov/{dname}/{t!r}", f"a\n{t}\n", at=bad_line([t], ov), **ov)
# pairs for the temporal overrides
for dname in ("date", "datetime[μs]"):
    pool = ["2024-01-02", "01/02/2024", "2024-01-02T01:02:03", "2024-01-02 01:02:03", "01/02/2024 01:02:03", "2024-01-02T01:02", "x"]
    for x, y in itertools.product(pool, repeat=2):
        add(f"ov/{dname}/pair/{x!r},{y!r}", f"a\n{x}\n{y}\n", at=bad_line([x, y], {"schema_overrides": {"a": dname}}), schema_overrides={"a": dname})
add("ov/null", "a\n1\n", schema_overrides={"a": "null"})
add("ov/unknown", "a\n1\n", schema_overrides={"b": "null"})
add("ov/unknown-2", "a,b\n1,x\n", schema_overrides={"zz": "i64", "b": "str"})
add("ov/all-empty-col", "a,b\n1,\n2,\n", schema_overrides={"b": "i64"})
add("ov/two-cols", "b,a\n1,2\n1,x\n", at="1,x", schema_overrides={"a": "i64"})
add("ov/two-cols-ok", "b,a\n1,2\n1,3\n", schema_overrides={"a": "f64", "b": "str"})
add("ov/many", "a,b,c,d,e,f\n1,2,3,x,true,2024-01-02\n", schema_overrides={"a": "i32", "b": "f32", "c": "str", "d": "str", "e": "bool", "f": "date"})
add("ov/quoted-number", 'a\n"1"\n', schema_overrides={"a": "f64"})
add("ov/int-on-float-col", "a\n1\n2\n", schema_overrides={"a": "f64"})
add("ov/date-on-int", "a\n2024-01-02\n", at="2024", schema_overrides={"a": "i64"})
add("ov/trim-header", " a \n1\n", schema_overrides={" a ": "str"})

# an integer beyond Int64 inside the inference window: a String column here
BIG = "9223372036854775808"
add("big/small-big-float", f"a\n1\n{BIG}\n1.5\n")
add("big/float-small-big", f"a\n1.5\n1\n{BIG}\n")
add("big/float-big", f"a\n1.5\n{BIG}\n")
add("big/big-float", f"a\n{BIG}\n1.5\n")
add("big/big-inf", f"a\n{BIG}\ninf\n")
add("big/big-1e3-null", f"a\n\n{BIG}\n1e3\n")
add("big/small-big-inf", f"a\n1\n{BIG}\ninf\n")
add("big/neg-big-float", "a\n-9223372036854775809\n-2.5\n")
add("big/isl1-big-float", f"a\n{BIG}\n1.5\n", infer_schema_length=1)
add("big/isl1-small-big", f"a\n1\n{BIG}\n", at=BIG, infer_schema_length=1)
add("big/isl1-float-big", f"a\n1.5\n{BIG}\n", infer_schema_length=1)
add("big/two-columns", f"a,b\n{BIG},1.5\n1,2\n")
add("big/null-values", f"a\nNA\n{BIG}\n1\n", null_values=["NA"])
add("big/n_rows0", f"a\n{BIG}\n", n_rows=0)

# dates with try_parse_dates
TD = {"try_parse_dates": True}
for cid, text, at in [
    ("dates", "a\n2024-01-02\n2024-1-2\n2024/01/03\n", None),
    ("dmy", "a\n01/02/2024\n", None),
    ("dmy-2", "a\n02-01-2024\n02.01.2024\n", None),
    ("quoted", 'a\n"2024-01-02"\n', None),
    ("null", "a\n2024-01-02\n\n2024-01-03\n", None),
    ("mixed-fmt", "a\n2024-01-02\n01/02/2024\n", "01/02/2024"),
    ("mixed-fmt-2", "a\n01/02/2024\n2024-01-02\n", "2024-01-02\n"),
    ("two-year-first", "a\n2024-01-02\n99-12-31\n", None),
    ("dt-mixed-sep", "a\n2024-01-02T01:02:03\n2024-01-02 01:02:03\n", None),
    ("dt-mixed-secs", "a\n2024-01-02T01:02:03\n2024-01-02T01:02\n", None),
    ("dt-mixed-fmt", "a\n2024-01-02T01:02:03\n01/02/2024 01:02:03\n", "01/02/2024 01:02:03"),
    ("dt-frac", "a\n2024-01-02T01:02:03.123456789\n2024-01-02T01:02:03.5\n", None),
    ("dt-date-mix", "a\n2024-01-02T01:02:03\n2024-01-02\n", None),
    ("date-dt-mix", "a\n2024-01-02\n2024-01-02T01:02:03\n", None),
    ("tz-first", "a\n2024-01-02T01:02:03Z\n2024-01-02T01:02:03\n", None),
    ("tz-second", "a\n2024-01-02T01:02:03\n2024-01-02T01:02:03Z\n", None),
    ("date-int", "a\n2024-01-02\n5\n", None),
    ("int-date", "a\n5\n2024-01-02\n", None),
    ("all-empty", "a\n\n\n", None),
    ("quoted-empty", 'a\n2024-01-02\n""\n', None),
    ("multi-col", "a,b,c\n2024-01-02,2024-01-02T01:02:03,x\n2024-01-03,2024-01-03T04:05:06,y\n", None),
]:
    add(f"dates/{cid}", text, at=at, **TD)
for isl in (1, 2):
    for cid, text, at in [
        ("date-bad", "a\n2024-01-02\n2024-01-03\nx\n", "x\n"),
        ("dt-bad", "a\n2024-01-02T01:02:03\n2024-01-03T01:02:03\nx\n", "x\n"),
        ("date-badfmt", "a\n2024-01-02\n2024-01-03\n01/02/2024\n", "01/02/2024"),
        ("dt-badfmt-ok", "a\n2024-01-02T01:02:03\n2024-01-03T01:02:03\n2024-01-02 01:02:03\n", None),
        ("date-then-dt", "a\n2024-01-02\n2024-01-03\n2024-01-03T01:02:03\n", "2024-01-03T"),
        ("dt-then-date", "a\n2024-01-02T01:02:03\n2024-01-03T01:02:03\n2024-01-03\n", None),
        ("date-later-ok", "a\n2024-01-02\n2024-01-03\n2024-1-4\n", None),
    ]:
        add(f"dates/isl{isl}/{cid}", text, at=at, infer_schema_length=isl, **TD)

# ---------------------------------------------------------------------------
# Several problems in one text: the error is the first bad record in file order
I64 = {"schema_overrides": {"a": "i64"}}
B64 = {"schema_overrides": {"b": "i64"}}
AB64 = {"schema_overrides": {"a": "i64", "b": "i64"}}
for cid, text, at, opts in [
    ("value-then-long", "a,b\nx,2\n1,2,3\n", "x,2", I64),
    ("long-then-value", "a,b\n1,2,3\nx,2\n", "1,2,3", I64),
    ("same-record-long", "a,b\nx,2,3\n", "x,2,3", I64),
    ("same-record-quote-1", 'a,b\nx,"y"z\n', 'x,"y"z', I64),
    ("same-record-open-quote", 'a,b\nx,"y\n', 'x,"y', I64),
    ("quote-col0-value-col1", 'a,b\n"y"z,x\n', '"y"z', B64),
    ("quote-before-value", 'a,b\n1,"y"z\nx,2\n', '1,"y"z', I64),
    ("value-before-quote", 'a,b\nx,2\n1,"y"z\n', "x,2", I64),
    ("value-then-long-b", "a,b\nx,2\n1,2,3\n", "1,2,3", B64),
    ("long-then-quote", 'a,b\n1,2,3\n1,"y"z\n', "1,2,3", I64),
    ("row-then-column", "a,b\n1,x\ny,2\n", "1,x", AB64),
    ("one-row-two-values", "a,b\ny,x\n", "y,x", AB64),
    ("value-row-then-long", "a,b\n1,2\ny,x\n3,4,5\n", "y,x", AB64),
    ("long-then-value-row", "a,b\n1,2,3\nx,y\n", "1,2,3", AB64),
    ("value-then-long-2", "a,b\nx,y\n1,2,3\n", "x,y", AB64),
    ("empty-long-then-value", "a,b\n,2,3\nx,y\n", ",2,3", AB64),
    ("quote-first-col-value-later", 'a,b\n"x"y,3\nx,2\n', '"x"y', I64),
    ("value-first-quote-later", 'a,b\nx,2\n"x"y,3\n', "x,2", I64),
    ("multiline-quote-then-value", 'a\n"p\nq"r\nx\n1,2\n', '"p', I64),
    ("structural-only-order-1", 'a,b\n1,2\n3,4,5\n6,"x"y\n', "3,4,5", {}),
    ("structural-only-order-2", 'a,b\n1,"x"y\n3,4,5\n', '1,"x"y', {}),
    ("structural-only-order-3", 'a,b\n1,2,3\n1,"x"y\n', "1,2,3", {}),
    ("structural-only-order-4", 'a,b\n1,2\n"x"y,3\n3,4,5\n', '"x"y', {}),
    ("multiline-then-values", 'a,b\n"p\nq",1\n1,x\n3,4,5\n', "1,x", B64),
]:
    add(f"order/{cid}", text, at=at, **opts)
for isl in (1, 2):
    add(f"order/window-{isl}-value-then-quote", 'a\n1\nx\n"x"y\n', at="x\n", infer_schema_length=isl) if isl == 1 else add(f"order/window-{isl}-value-then-quote", 'a\n1\nx\n"x"y\n', at='"x"y', infer_schema_length=isl)
add("order/window-1-value-then-long", "a,b\n1,2\nx,3\n4,5,6\n", at="x,3", infer_schema_length=1)
add("order/window-1-long-then-value", "a,b\n1,2\n4,5,6\nx,3\n", at="4,5,6", infer_schema_length=1)
add("order/window-1-two-columns", "a,b\n1,2\n3,y\nx,4\n", at="3,y", infer_schema_length=1)

# whitespace-only fields
for dname in ("i32", "i64", "f32", "f64", "bool", "date", "datetime[μs]", "str"):
    for ws in ([" ", "   ", "\t", " \t", '" "', '"\t"', "\u00a0", "\u2003", "\x0b", "\x0c"] if dname in ("i32", "i64", "f32", "f64") else [" ", "\t", '" "', "\u00a0"]):
        add(f"ws/{dname}/{ws!r}", f"a,b\n{ws},x\n", at=2, schema_overrides={"a": dname})
        if dname in ("i32", "i64", "f32", "f64"):
            add(f"ws/{dname}/mid/{ws!r}", f"a\n1\n{ws}\n2\n", at=3, schema_overrides={"a": dname})
for ws in [" ", "\t", '" "', "  "]:
    add(f"ws/late-int/{ws!r}", f"a\n1\n{ws}\n3\n", at=3, infer_schema_length=1)
    add(f"ws/late-float/{ws!r}", f"a\n1.5\n{ws}\n", at=3, infer_schema_length=1)
    add(f"ws/late-bool/{ws!r}", f"a\ntrue\n{ws}\n", at=3, infer_schema_length=1)
    add(f"ws/late-date/{ws!r}", f"a\n2024-01-02\n{ws}\n", at=3, infer_schema_length=1, try_parse_dates=True)
    add(f"ws/infer/{ws!r}", f"a\n{ws}\n1\n")
add("ws/all-blank-float", "a\n \n \n", at=2, schema_overrides={"a": "f64"})
add("ws/trailing-after-number", "a\n1\n1 \n", at=3, schema_overrides={"a": "i64"})
add("ws/with-null-values", "a\n1\n \n", at=3, infer_schema_length=1, null_values=["x"])

# skip_rows and blank lines
for text in [
    "\na,b\n1,2\n3,4\n", "\n\na,b\n1,2\n3,4\n", "x\n\na,b\n1,2\n", "x\n\na,b\n1,2\n3,4\n",
    "x\ny\n\na,b\n1,2\n", "\nx\na,b\n1,2\n3,4\n", "x\n\n\na,b\n1,2\n", "\n\nx\ny\na,b\n1,2\n",
    "\r\na,b\r\n1,2\r\n", '\n"x\ny"\na,b\n1,2\n', "\n\n", "x\n\na\n1\n", "x\n\n\na\n1\n", "x\ny\n\na\n1\n",
]:
    for s in (1, 2, 3):
        add(f"skip-blank/{s}/{text!r}", text, skip_rows=s)
add("skip-blank/nh-1", "\na,b\n1,2\n", skip_rows=1, has_header=False)
add("skip-blank/nh-2", "\na,b\n1,2\n", skip_rows=2, has_header=False)

# n_rows = 0
for cid, text, opts in [
    ("long-row", "a\n1\n2,3\n", {}),
    ("isl1", "a\n1\nx\n", {"infer_schema_length": 1}),
    ("isl1-first-str", "a\nx\n1\n", {"infer_schema_length": 1}),
    ("isl2", "a\n1\nx\n", {"infer_schema_length": 2}),
    ("long-isl1", "a\n1\n2,3\n", {"infer_schema_length": 1}),
    ("long-isl2", "a\n1\n2,3\n", {"infer_schema_length": 2}),
    ("long-isl-none", "a\n1\n2,3\n", {"infer_schema_length": None}),
    ("quote-isl1", 'a\n1\n"x"y\n', {"infer_schema_length": 1}),
    ("long-2cols", "a,b\n1,2\n3,4,5\n", {"infer_schema_length": 2}),
    ("override", "a\n1\nx\n", {"schema_overrides": {"a": "i64"}}),
    ("float-isl1", "a\n1\n2.5\n", {"infer_schema_length": 1}),
    ("noheader", "a,b\n1,2\n", {"has_header": False}),
    ("noheader-long", "a,b\n\n1,2,3\n", {"has_header": False}),
]:
    add(f"n_rows0/{cid}", text, n_rows=0, **opts)
add("n_rows1/long-in-window", "a,b\n1,2\n3,4\n5,6,7\n", at="5,6,7", n_rows=1)

# the message of text after a closing quote names the type of the column
for cid, text, at, opts in [
    ("quote-int-isl1", 'a,b\n1,2\n"x"y,3\n', '"x"y', {"infer_schema_length": 1}),
    ("quote-int-col2", 'a,b\n1,2\n3,"x"y\n', '3,"x"y', {"infer_schema_length": 1}),
    ("quote-float", 'a,b\n1.5,2\n"x"y,3\n', '"x"y', {"infer_schema_length": 1}),
    ("quote-bool", 'a,b\ntrue,2\n"x"y,3\n', '"x"y', {"infer_schema_length": 1}),
    ("quote-date", 'a,b\n2024-01-02,2\n"x"y,3\n', '"x"y', {"infer_schema_length": 1, "try_parse_dates": True}),
    ("quote-default-str", 'a,b\n1,2\n"x"y,3\n', '"x"y', {}),
    ("quote-isl0", 'a,b\n1,2\n"x"y,3\n', '"x"y', {"infer_schema_length": 0}),
    ("quote-override-f64", 'a,b\n1,2\n"x"y,3\n', '"x"y', {"schema_overrides": {"a": "f64"}}),
    ("quote-override-i32", 'a,b\n1,2\n"x"y,3\n', '"x"y', {"schema_overrides": {"a": "i32"}}),
    ("quote-override-f32", 'a,b\n1,2\n"x"y,3\n', '"x"y', {"schema_overrides": {"a": "f32"}}),
    ("quote-override-str", 'a,b\n1,2\n"x"y,3\n', '"x"y', {"schema_overrides": {"a": "str"}}),
    ("quote-override-bool-first", 'a,b\n1,2\n"x"y,3\n', "1,2", {"schema_overrides": {"a": "bool"}}),
    ("quote-override-date-first", 'a,b\n1,2\n"x"y,3\n', "1,2", {"schema_overrides": {"a": "date"}}),
]:
    add(f"quote-dtype/{cid}", text, at=at, **opts)
for cid, text, opts in [
    ("quote-default", 'a\n1\n"x"y\n', {}),
    ("quote-isl2", 'a\n1\n"x"y\n', {"infer_schema_length": 2}),
]:
    add(f"n_rows0/{cid}", text, n_rows=0, **opts)

# A malformed record inside the inference window is inferred like the others
for cid, text, at, opts in [
    ("long-int-then-float", "a\n-5\n1.5,x\n", "1.5,x", {}),
    ("long-str-field", "a,b\n1,2\nz,5,y\n", "z,5,y", {}),
    ("long-window2", "a\n1\n1.5,x\n-7\n", "1.5,x", {"infer_schema_length": 2}),
    ("long-window1", "a\n1\n1.5,x\n-7\n", "1.5,x", {"infer_schema_length": 1}),
    ("long-window-none", "a\n1\n1.5,x\n-7\ny\n", "1.5,x", {"infer_schema_length": None}),
    ("long-then-str-after", "a,b\n1,2\n3,4,5\nx,y\n", "3,4,5", {}),
    ("long-quote-first", 'a,b\n1,"x"y,3\n', '1,"x"y,3', {}),
    ("quote-f32", 'a,b\nfalse,0.1\n   \t ,"x"y\nTrue,"ab"cd\n', '   \t ,"x"y', {"schema_overrides": {"b": "f32"}}),
    ("quote-window3", 'a\n1\n"x"y\n2.5\n', '"x"y', {"infer_schema_length": 3}),
    ("open-quote-i64", 'a,b,c\n-5,007,NaNa\n ,"x,NA', ' ,"x,NA', {"infer_schema_length": 1}),
    ("open-quote-override", 'a\n1\n"x\n', '"x', {"schema_overrides": {"a": "i64"}}),
    ("open-quote-str", 'a\n1\n"x\n', '"x', {}),
    ("toggle-1", 'a,b,c\n"x,"ab"cd,007', '"x,"ab"cd,007', {"infer_schema_length": 2}),
    ("toggle-2", 'a,b\n"x,"x"y,\n1,\n', '"x,"x"y,', {"infer_schema_length": 3}),
    ("noheader-quote-override", '007,"x"y\n', 1, {"has_header": False, "schema_overrides": {"column_1": "i64"}}),
]:
    add(f"mal/{cid}", text, at=at, **opts)
for cid, text, opts in [
    ("quote-bool", 'a,b\n"x"y,false\n', {}),
    ("open-quote", 'a\n1\n"x\n', {}),
    ("dates", 'a,b,c\n"x",007,2000-02-29,x\n', {"try_parse_dates": True}),
    ("long-default", "a,b\n1,2\n3,4,5\nx,y\n", {}),
    ("long-isl2", "a,b\n1,2\n3,4,5\nx,y\n", {"infer_schema_length": 2}),
    ("long-isl3", "a,b\n1,2\n3,4,5\nx,y\n", {"infer_schema_length": 3}),
    ("long-first-value", "a,b\n1,2\n3,4,5\n6,x\n", {}),
]:
    add(f"mal/n_rows0/{cid}", text, n_rows=0, **opts)
add("mal/skip-open-quote", "﻿a\n\"x\r\n", skip_rows=2)

# ---------------------------------------------------------------------------
# seeded random tables (no errors)
rng = random.Random(20261125)
FIELDS = [
    "", "", "1", "-7", "007", "2.5", "-0.25", "1e3", "+5", "inf", "NaN", "nan", "true", "False", "x", "hello",
    "a b", " 1", "1 ", '"q"', '"a,b"', '"a""b"', '""', '"x\ny"', "NA", "-", "2024-01-02", "2024-01-02T01:02:03",
    "né", "😀",
]
n_random = 0
tries = 0
while n_random < 60 and tries < 5000:
    tries += 1
    ncol = rng.randint(1, 4)
    nrow = rng.randint(0, 6)
    eol = rng.choice(["\n", "\r\n"])
    header = ",".join(rng.choice(["a", "b", "c", "d", "x", "y z"]) if rng.random() < 0.5 else f"c{i}" for i in range(ncol))
    rows = []
    for _ in range(nrow):
        k = ncol if rng.random() < 0.8 else rng.randint(1, ncol)
        rows.append(",".join(rng.choice(FIELDS) for _ in range(k)))
    text = header + eol + eol.join(rows) + (eol if rng.random() < 0.7 else "")
    opts = {}
    if rng.random() < 0.3:
        opts["try_parse_dates"] = True
    if rng.random() < 0.2:
        opts["infer_schema_length"] = rng.choice([0, 1, 2, None])
    if rng.random() < 0.2:
        opts["null_values"] = rng.choice([["NA"], ["-"], ["NA", "x"], [""]])
    if rng.random() < 0.15:
        opts["n_rows"] = rng.randint(0, 4)
    if rng.random() < 0.1:
        opts["has_header"] = False
    try:
        df = read(text, opts)
    except Exception:  # noqa: BLE001
        continue
    # a quirk of polars with a quoted empty string next to nulls and null_values:
    # keep only what the library models (checked by the test)
    add(f"random/{n_random:03d}", text, **opts)
    n_random += 1

emit("csv_read", {"cases": CASES}, compact=True)
errors = sum(1 for c in CASES if "error" in c)
restricted = sum(1 for c in CASES if c.get("restricted"))
print(f"{len(CASES)} cases, {errors} errors, {restricted} restricted")
