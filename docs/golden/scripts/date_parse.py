"""Golden data for the ISO date and datetime parsers (`String` -> `Date` /
`Datetime` casts, `AnyValue::date_ymd`, `AnyValue::datetime_ymd`).

Run from the repository root (needs polars 2.1.0):

    python docs/golden/scripts/date_parse.py

Writes `docs/golden/date_parse.json` and `src/pl/golden_date_parse_data_test.mbt`.
Every case is in the list `cases`; `kind` tells the two sorts apart.

`"kind": "cast"`: `input` is a series named `a` (a `String` series, or another
type to check the error), `target` is `"date"` or `"datetime"` and `strict`
the mode of `pl.col("a").str.to_date(strict=...)` /
`pl.col("a").str.to_datetime(time_unit="us", strict=...)` evaluated by
`pl.DataFrame([s]).select(...)` (the expression, not the `Series.str` methods,
which answer differently; the library's `ExprStr::to_date` / `to_datetime`; polars 2.1.0
no longer casts a string to a date, see `cast.json`). The expected result is
the series (`result`), or the error variant and the first line of polars'
message (`error`, `message`). `str` (only on some cases) is `str(expr)` of the polars expression,
which the library's `to_string()` must give too.
polars refuses a datetime column whose format has a UTC offset (strict: `ComputeError`;
not strict: nulls), so no case has a value with a time zone.

`"kind": "ymd"`: `args` are the arguments of `date_ymd(year, month, day)` or
`datetime_ymd(year, month, day, hour, minute, second, microsecond)`
(`target` says which). The expected value `result` is days (`date`) or
microseconds (`datetime`) since 1970-01-01, computed with Python's `datetime`
(years 1 to 9999) or with `pl.date` / `pl.datetime` (the others, where `None`
is an invalid date: chrono's years are -262143 to 262142);
an invalid date is `error` `ComputeError` with the library's message
(`message`, not a polars text: `pl.date` raises in a different way).

Not in the cases (see `docs/golden/known-diffs/date_parse.md`): day-first datetimes
with a year of more than four digits or leading zeros (`31-12-10000`,
`15-01-02024`: polars' format guess finds a format for some of them), and the
format polars finds in a value that mixes a time zone offset with other shapes
beyond the cases below.
"""
import datetime
import warnings

warnings.simplefilter("ignore")

import polars as pl

from emit import emit, encode_series, series_from_spec

EPOCH = datetime.date(1970, 1, 1)
EPOCH_DT = datetime.datetime(1970, 1, 1)

# Single texts; each one becomes a one-element series.
SINGLES = [
    "2024-01-15",
    "2024-1-5",
    "2024-01-15 10:20:30",
    "2024-01-15T10:20:30",
    "2024-01-15T10:20:30.123456",
    "2024-01-15 10:20:30.5",
    "2024-01-15T10:20:30Z",
    "2024-01-15T10:20:30z",
    "2024-01-15T10:20:30+02:00",
    "2024-01-15 10:20:30+0200",
    "2024-01-15T10:20:30+02",
    "2024-01-15T10:20:30-05:30",
    "2024-01-15T10:20:30 +02:00",
    "2024-01-15T10:20:30 Z",
    "2024-01-15T10:20:30.5+02:00",
    "2024-01-15T10:20:30.5Z",
    "2024-01-15 10:20:30.123456+00:00",
    "2024-01-15T10:20:30+14:00",
    "2024-01-15T10:20:30+2",
    "2024-01-15T10:20:30+02:0",
    "2024-01-15T10:20:30ZZ",
    "2024-02-30",
    "2023-02-29",
    "2024-02-29",
    "1900-02-29",
    "2000-02-29",
    "2024-02-29 10:20:30",
    "",
    " 2024-01-15",
    "  2024-01-15",
    "\t2024-01-15",
    "\n2024-01-15",
    " 2024-01-15",
    "2024- 01-15",
    "2024-01- 15",
    " 2024-01-15 10:20:30",
    "2024-01-15 ",
    "2024-01-15\n",
    "0999-01-01",
    "0001-01-01",
    "0000-01-01",
    "9999-12-31",
    "10000-01-01",
    "12345-01-01",
    "+2024-01-15",
    "+0001-01-01",
    "-0001-01-01",
    "-0000-01-01",
    "-2024-01-15",
    "+10000-01-01",
    "+20240-01-15",
    "2024/01/15",
    "2024/1/5",
    "2024-01/15",
    "2024/01-15",
    "20240115",
    "2024-001-15",
    "02024-01-15",
    "2024-01-015",
    "2024-01-15T10:20",
    "2024-01-15 10:20",
    "2024-01-15T10:20:30.123456789",
    "2024-01-15T10:20:30.1234567890",
    "2024-13-01",
    "2024-00-10",
    "2024-01-00",
    "2024-01-32",
    "2024-01-15T24:00:00",
    "2024-01-15T10:60:00",
    "2024-01-15T10:20:60",
    "abc",
    "2024-01-15 10:20:30 ",
    "2024-01-15T10:20:30.",
    "2024-01-15T10:20:30,5",
    "2024-01-15T1:2:3",
    "2024-1-5 1:2:3",
    "2024-01-15 10",
    "2024-01-15T",
    "2024-01-15 10:20:30.000001",
    "2024-01-15T10:20:30.123",
    "2024-01-15T10:20:30.12",
    "0001-01-01T00:00:00",
    "9999-12-31T23:59:59.999999",
    "2024-01-15t10:20:30",
    "2024-01-15  10:20:30",
    "2024-01-15\t10:20:30",
    "2024-01-15\x00",
    "２０２４-01-15",
    # offset forms (a space before the offset, -00:00, the extremes)
    "2024-01-15T10:20:30-00:00",
    "2024-01-15T10:20:30+00:00",
    "2024-01-15T10:20:30-0000",
    "2024-01-15T00:00:00 +0200",
    "2024-01-15T23:59:60+23:59",
    "2024-01-15T10:20:30-23:59",
    "2024-01-15T10:20:30+24:00",
    "2024-01-15T10:20:30+24:01",
    "2024-01-15T10:20:30+25:00",
    "2024-01-15T10:20:30+99",
    "2024-01-15T10:20:30+02:60",
    "2024-01-15T10:20:30+0260",
    "2024-01-15T10:20:30+99:99",
    "2024-01-15T10:20:30+02:30",
    "2024-01-15T10:20:30+1:00",
    "2024-01-15T10:20:30+02:00 ",
    "2024-01-15T10:20:30.123456789+02:00",
    "2024-01-15T10:20:30.123456789Z",
    "2024-01-15T10:20:30.5 Z",
    "2024-01-15T10:20+02:00",
    "2024-01-15T10:20Z",
    "2024-01-15Z",
    "2024-01-15+02:00",
    "0001-01-01T00:00:00+23:59",
    "0001-01-01T00:00:00Z",
    "9999-12-31T23:59:59-02:00",
    "2024-01-15T01:02:03z",
    "2024-01-15 01:02:03z",
    # year bounds (chrono: -262143 to 262142)
    "+262142-12-31",
    "+262142-01-01",
    "+262143-01-01",
    "+262143-12-31",
    "-262143-01-01",
    "-262144-01-01",
    "262143-01-01",
    # a year of one to three digits; day-first dates; other separators
    "99-12-31",
    "999-12-31",
    "24-01-15",
    "15-01-24",
    "+999-01-01",
    "+99-01-01",
    "-999-01-01",
    "9-1-1",
    "1-1-1",
    "99/12/31",
    "999/12/31",
    "15-01-999",
    "15-01-99",
    "31-12-99",
    "12-31-99",
    "01-02-03",
    "99-1-1",
    "999-1-1",
    "15.01.2024",
    "15/01/2024",
    "15-01-2024",
    "5-1-2024",
    "15-1-2024",
    "31-12-1999",
    "2024.01.15",
    "15-01/2024",
    "15/01-2024",
    "005-01-2024",
    "31-02-2024",
    "32-01-2024",
    "00-01-2024",
    "15- 01- 2024",
    " 15-01-2024",
    "15-01-+2024",
    "15-01--0001",
    "15-01-0000",
    "31-12-9999",
    "1-1-99999",
    "2024-15-01",
    "15-01-2024 10:20:30",
    "15-01-2024T10:20:30",
    "15-01-2024 10:20",
    "15/01/2024 10:20:30.5",
    "99-12-31 10:20:30",
    "24-01-15 10:20:30",
    "0999-01-01 10:20:30",
    # a year with a sign or fewer than four digits, after a T and seconds
    "+262142-12-31T10:20:30",
    "-262143-01-01T10:20:30",
    "+262143-01-01T10:20:30",
    "+10000-01-01T10:20:30",
    "31-12-+262142T10:20:30",
    "+2024-01-03T10:20",
    "+2024-01-03 10:20:30",
    "+2024-01-03T10:20:30.5",
    "+2024-01-03T1:2:3",
    "+2024/01/03T10:20:30",
    "99-12-31T10:20:30",
    "24-01-15T10:20:30",
    "04-01-24T10:20:30",
    " 2024-01-03T10:20:30",
    "2024-01-03T 10:20:30",
    "2024- 01-03T10:20:30",
    "15-01-2024T10:20:30+02:00",
    "15-01-2024 10:20:30Z",
    "15/01/24T10:20:30",
    "15.01.24T10:20:30",
    "15-01-24T10:20:30",
    "15-01-24 10:20:30",
]

# Series of several texts (and nulls).
MULTI = {
    "empty": [],
    "all-null": [None, None],
    "null-first": [None, "2024-01-15"],
    "date-then-datetime": ["2024-01-15", "2024-01-15 10:20:30"],
    "datetime-then-date": ["2024-01-15 10:20:30", "2024-01-15"],
    "bad-first": ["x", "2024-01-15"],
    "bad-last": ["2024-01-15", "x"],
    "T-then-space": ["2024-01-15T10:20:30", "2024-01-15 10:20:30"],
    "fraction-mix": ["2024-01-15 10:20:30.5", "2024-01-15 10:20:30"],
    "fraction-mix-reverse": ["2024-01-15 10:20:30", "2024-01-15 10:20:30.5"],
    "offsets": ["2024-01-15T10:20:30+02:00", "2024-01-15T10:20:30Z"],
    "slash-dash": ["2024/01/15", "2024-01-15"],
    "all-bad": ["x", "y", "z"],
    "one-bad-of-five": ["2024-01-15", "2024-01-16", "oops", None, "2024-01-18"],
    "three-bad": ["2024-01-15", "b1", "b2", "b3"],
    "four-bad": ["2024-01-15", "b1", "b2", "b3", "b4"],
    "twelve-bad": ["2024-01-15"] + [f"b{i}" for i in range(12)] + [None],
    "valid-run": [f"2024-{m:02d}-{d:02d}" for m in (1, 2, 12) for d in (1, 15, 28)],
    "valid-run-time": [f"2024-{m:02d}-{d:02d} 0{m % 10}:{d:02d}:59.{d}" for m in (1, 2, 9) for d in (1, 15, 28)],
    "nulls-around": [None, "2024-01-15", None, "1999-12-31", None],
    # a time zone in the format: the first value that has a format decides
    "naive-then-offset": ["2024-01-15T10:20:30", "2024-01-15T10:20:30+02:00"],
    "offset-then-naive": ["2024-01-15T10:20:30+02:00", "2024-01-15T10:20:30"],
    "offset-offset": ["2024-01-15T10:20:30+02:00", "2024-01-15T10:20:30Z"],
    "null-then-offset": [None, "2024-01-15T10:20:30+02:00"],
    "offset-then-bad": ["2024-01-15T10:20:30+02:00", "x"],
    "bad-then-offset": ["x", "2024-01-15T10:20:30+02:00"],
    "bad-naive-offset": ["x", "2024-01-15T10:20:30", "2024-01-15T10:20:30+02:00"],
    "offset-then-date": ["2024-01-15T10:20:30+02:00", "2024-01-15"],
    "date-then-offset": ["2024-01-15", "2024-01-15T10:20:30+02:00"],
    "day-first-run": ["15-01-2024", "16-01-2024", "x", None],
    "all-unreadable-with-nulls": [None, "abc", None],
    "unreadable-date-only": ["2024-02-30", "2023-02-29"],
    # the first value that has a format fixes it (year first or day first, and
    # for a datetime the shape of its text); every value is read with it only
    "ymd-then-dmy": ["2024-01-02", "01-02-2024"],
    "dmy-then-ymd": ["01-02-2024", "2024-01-02"],
    "ymd-then-short-year": ["2024-01-02", "24-01-15"],
    "dmy-then-short-year": ["15-01-2024", "24-01-15"],
    "dmy-separators": ["01.02.2024", "01/02/2024"],
    "dmy-two-days": ["01-02-2024", "13-01-2024"],
    "ymd-separators": ["2024-01-02", "2024.01.03", "2024/01/04"],
    "date-then-signed": ["2024-01-02", "+2024-01-02"],
    "signed-then-date": ["+2024-01-02", "2024-01-02"],
    "date-then-long-year": ["2024-01-02", "+262142-12-31"],
    "date-then-dt-t": ["2024-01-02", "2024-01-03T10:20:30"],
    "date-then-signed-dt": ["2024-01-02", "+2024-01-03T10:20:30"],
    "dt-t-then-signed-dt": ["2024-01-02T10:20:30", "+2024-01-03T10:20:30"],
    "dt-t-then-signed-frac": ["2024-01-02T10:20:30", "+2024-01-03T10:20:30.5"],
    "dt-t-then-signed-min": ["2024-01-02T10:20:30", "+2024-01-03T10:20"],
    "dt-t-then-signed-space": ["2024-01-02T10:20:30", "+2024-01-03 10:20:30"],
    "dt-t-then-signed-slash": ["2024-01-02T10:20:30", "+2024/01/03T10:20:30"],
    "dt-t-then-slash": ["2024-01-02T10:20:30", "2024/01/03T10:20:30"],
    "dt-t-then-short-year": ["2024-01-02T10:20:30", "99-12-31T10:20:30"],
    "dt-t-then-short-day-first": ["2024-01-02T10:20:30", "04-01-24T10:20:30"],
    "dt-t-then-padded": ["2024-01-02T10:20:30", " 2024-01-03T10:20:30", "2024-01-03T 10:20:30"],
    "dt-t-then-long-year": ["2024-01-02T10:20:30", "+262142-12-31T10:20:30"],
    "dt-t-then-date-only": ["2024-01-02T10:20:30", "2024-01-03"],
    "dt-t-then-signed-date-only": ["2024-01-02T10:20:30", "+2024-01-03"],
    "signed-dt-then-date": ["+2024-01-02T10:20:30", "2024-01-03"],
    "signed-dt-then-signed-date": ["+2024-01-02T10:20:30", "+2024-01-03"],
    "dt-min-then-signed-min": ["2024-01-02T10:20", "+2024-01-03T10:20"],
    "dt-min-then-signed-sec": ["2024-01-02T10:20", "+2024-01-03T10:20:30"],
    "dt-space-then-signed-space": ["2024-01-02 10:20:30", "+2024-01-03 10:20:30"],
    "dt-space-then-date": ["2024-01-02 10:20:30", "2024-01-03"],
    "dt-space-then-t": ["2024-01-02 10:20:30", "2024-01-03T10:20:30"],
    "dmy-dt-then-short-year": ["15-01-2024 10:20:30", "24-01-15 10:20:30"],
    "dmy-dt-then-ymd": ["15-01-2024 10:20:30", "2024-01-03 10:20:30"],
    "dmy-dt-t-then-short-year": ["15-01-2024T10:20:30", "04-01-24T10:20:30"],
    "dmy-dt-t-slash-short-year": ["15/01/2024T10:20:30", "24/01/15T10:20:30"],
    "dmy-dt-t-mixed-slash": ["15-01-2024T10:20:30", "24/01/15T10:20:30"],
    "dt-t-slash-then-signed": ["2024/01/02T10:20:30", "+2024/01/03T10:20:30"],
    "dt-t-dot-then-signed": ["2024.01.02T10:20:30", "+2024.01.03T10:20:30"],
    "dt-space-slash-then-signed": ["2024/01/02 10:20:30", "+2024/01/03 10:20:30"],
    "date-slash-then-signed": ["2024/01/02", "+2024/01/03"],
    "date-slash-then-short": ["2024/01/02", "24/01/15"],
}

# Series that are not String: polars raises SchemaError.
NON_STRING = {
    "i64": pl.Series("a", [1, 2], dtype=pl.Int64),
    "null": pl.Series("a", [None, None], dtype=pl.Null),
    "date": pl.Series("a", [1], dtype=pl.Int32).cast(pl.Date),
}

# (the input series is in `input`; it is the column "a" of the frame selected from)
DATE_PYTHON = 'df.select(pl.col("a").str.to_date(strict={strict}))'
DATETIME_PYTHON = 'df.select(pl.col("a").str.to_datetime(time_unit="us", strict={strict}))'

VARIANTS = {
    "ComputeError": "ComputeError",
    "InvalidOperationError": "InvalidOperation",
    "SchemaError": "SchemaMismatch",
}


def convert(s, target, strict):
    # The library API is an expression: the results come from `select`, not from
    # the `Series.str` methods (the two differ: a column of unreadable text gives
    # nulls with `strict=False` here but raises there, and texts with an offset
    # are refused here).
    expr = pl.col("a").str.to_date(strict=strict) if target == "date" else pl.col("a").str.to_datetime(time_unit="us", strict=strict)
    out = pl.DataFrame([s]).select(expr)["a"]
    if out.dtype == pl.Datetime and out.dtype.time_zone is not None:
        out = out.dt.replace_time_zone(None)
    return out


def cast_case(cid, values, target, strict, series=None):
    s = series if series is not None else pl.Series("a", values, dtype=pl.String)
    expr = pl.col("a").str.to_date(strict=strict) if target == "date" else pl.col("a").str.to_datetime(time_unit="us", strict=strict)
    template = DATE_PYTHON if target == "date" else DATETIME_PYTHON
    rec = {
        "id": cid,
        "kind": "cast",
        "target": target,
        "strict": strict,
        "input": encode_series(s),
        "polars": template.format(strict=strict),
    }
    # `str(expr)` is the same for every case of a target: kept on the first two
    # singles of each mode and on every multi-value and other-dtype case
    if "/single/" not in cid or cid.endswith(("000", "001")):
        rec["str"] = str(expr)
    try:
        rec["result"] = encode_series(convert(s, target, strict))
    except Exception as e:  # noqa: BLE001
        name = type(e).__name__
        if name not in VARIANTS:
            raise
        rec["error"] = VARIANTS[name]
        rec["message"] = str(e).split("\n")[0]
    return rec


def polars_ymd(kind, args):
    """The value of pl.date / pl.datetime for `args`, None when polars says null."""
    if kind == "date":
        e = pl.date(*args)
    else:
        e = pl.datetime(*args[:6], microsecond=args[6], time_unit="us")
    try:
        v = pl.select(e.alias("x"))["x"].to_physical()[0]
    except (pl.exceptions.ComputeError, pl.exceptions.InvalidOperationError):
        return None
    return None if v is None else str(v)


def ymd_cases():
    cases = []

    def date_case(y, m, d):
        rec = {
            "id": f"date_ymd/{y}-{m}-{d}",
            "kind": "ymd",
            "target": "date",
            "args": [y, m, d],
            "polars": f"(datetime.date({y}, {m}, {d}) - datetime.date(1970, 1, 1)).days",
        }
        try:
            if not 1 <= y <= 9999:
                raise ValueError
            rec["result"] = str((datetime.date(y, m, d) - EPOCH).days)
        except ValueError:
            v = polars_ymd("date", [y, m, d])
            if v is not None:
                rec["result"] = v
                cases.append(rec)
                return
            rec["error"] = "ComputeError"
            rec["message"] = f"invalid date: {y}-{m}-{d}"
        cases.append(rec)

    def datetime_case(y, m, d, hh, mi, ss, us):
        rec = {
            "id": f"datetime_ymd/{y}-{m}-{d}T{hh}:{mi}:{ss}.{us}",
            "kind": "ymd",
            "target": "datetime",
            "args": [y, m, d, hh, mi, ss, us],
            "polars": f"(datetime.datetime({y}, {m}, {d}, {hh}, {mi}, {ss}, {us}) - datetime.datetime(1970, 1, 1)) // datetime.timedelta(microseconds=1)",
        }
        try:
            if not 1 <= y <= 9999:
                raise ValueError
            delta = datetime.datetime(y, m, d, hh, mi, ss, us) - EPOCH_DT
            rec["result"] = str(delta // datetime.timedelta(microseconds=1))
        except ValueError:
            v = polars_ymd("datetime", [y, m, d, hh, mi, ss, us])
            if v is not None and us != 1000000:
                rec["result"] = v
                cases.append(rec)
                return
            rec["error"] = "ComputeError"
            rec["message"] = f"invalid datetime: {y}-{m}-{d} {hh}:{mi}:{ss}.{us}"
        cases.append(rec)

    for y, m, d in [
        (1970, 1, 1), (1969, 12, 31), (2024, 1, 15), (2024, 2, 29), (2023, 2, 29), (1900, 2, 29),
        (2000, 2, 29), (2100, 2, 29), (1, 1, 1), (9999, 12, 31), (2024, 2, 30), (2024, 4, 31),
        (2024, 6, 31), (2024, 12, 31), (2024, 0, 1), (2024, 13, 1), (2024, 1, 0), (2024, 1, 32),
        (2024, -1, 5), (2024, 5, -1), (999, 3, 4), (2024, 11, 31), (1582, 10, 10), (2400, 2, 29),
        (262142, 12, 31), (262142, 1, 1), (262143, 1, 1), (262143, 12, 31), (-262143, 1, 1),
        (-262143, 12, 31), (-262144, 1, 1), (262140, 2, 29), (262142, 2, 29), (0, 1, 1), (-1, 12, 31),
        (-4, 2, 29), (10000, 1, 1), (100000, 6, 15), (-100000, 6, 15), (300000, 1, 1), (2147483647, 1, 1),
        (-2147483648, 1, 1), (262142, 12, 32), (262142, 13, 1),
    ]:
        date_case(y, m, d)
    for args in [
        (1970, 1, 1, 0, 0, 0, 0), (2024, 1, 15, 10, 20, 30, 123456), (2024, 1, 15, 23, 59, 59, 999999),
        (1969, 12, 31, 23, 59, 59, 999999), (1, 1, 1, 0, 0, 0, 0), (9999, 12, 31, 23, 59, 59, 999999),
        (2024, 2, 30, 0, 0, 0, 0), (2024, 2, 29, 0, 0, 0, 0), (2024, 1, 15, 24, 0, 0, 0),
        (2024, 1, 15, 0, 60, 0, 0), (2024, 1, 15, 0, 0, 60, 0), (2024, 1, 15, 0, 0, 0, 1000000),
        (2024, 1, 15, -1, 0, 0, 0), (2024, 1, 15, 0, -1, 0, 0), (2024, 1, 15, 0, 0, -1, 0),
        (2024, 1, 15, 0, 0, 0, -1), (2024, 13, 1, 12, 0, 0, 0), (2023, 2, 29, 12, 0, 0, 0),
        (2024, 1, 15, 12, 0, 0, 1),
        (262142, 12, 31, 23, 59, 59, 999999), (262143, 1, 1, 0, 0, 0, 0), (-262143, 1, 1, 0, 0, 0, 0),
        (-262144, 12, 31, 0, 0, 0, 0), (0, 1, 1, 0, 0, 0, 0), (-1, 12, 31, 23, 59, 59, 999999),
        (10000, 1, 1, 0, 0, 0, 0), (262142, 1, 1, 0, 0, 0, 0), (262143, 12, 31, 23, 59, 59, 999999),
        (-262143, 12, 31, 23, 59, 59, 999999),
    ]:
        datetime_case(*args)
    return cases


def main():
    cases = []
    for target in ("date", "datetime"):
        for strict in (True, False):
            mode = "strict" if strict else "lenient"
            for i, text in enumerate(SINGLES):
                cases.append(cast_case(f"cast/{target}/{mode}/single/{i:03d}", [text], target, strict))
            for name, values in MULTI.items():
                cases.append(cast_case(f"cast/{target}/{mode}/multi/{name}", values, target, strict))
            for name, ser in NON_STRING.items():
                cases.append(cast_case(f"cast/{target}/{mode}/other/{name}", None, target, strict, series=ser))
    cases += ymd_cases()
    ids = [c["id"] for c in cases]
    assert len(ids) == len(set(ids)), "duplicate case ids"
    emit("date_parse", {"cases": cases}, compact=True)
    ok = sum(1 for c in cases if "error" not in c)
    print(f"polars {pl.__version__}: wrote {len(cases)} cases ({len(cases) - ok} errors)")


main()
