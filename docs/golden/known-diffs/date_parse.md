# Reading dates and datetimes from text (`str().to_date()`, `str().to_datetime()`)

polars 2.1.0 does not cast a string to a date: `s.cast(pl.Date)` raises
`casting from string to date is not supported. It was removed in Polars 2.0.
Use str.to_date() instead.` `@pl` does the same (`Series::cast` and
`Expr::cast` raise `InvalidOperation` with that first line). The reading is
`ExprStr::to_date` and `ExprStr::to_datetime`, the counterparts of the
expressions `pl.col("d").str.to_date()` and
`pl.col("d").str.to_datetime(time_unit="us")`:
`col("d").str().to_date(strict=false)`. Their `Show` text is polars' `str(expr)`
(`col("d").str.strptime(["raise"])`, strict or not). The `Series.str.to_date` /
`to_datetime` methods of polars answer differently for some inputs (a column of
unreadable text raises there and gives nulls here with `strict=false`; `-00:00`
and offset texts are read there); the library follows the expression, as
`select` evaluates it.

**There is no `format` parameter.** Only polars' format inference is supported
(the shapes below); reading a text with an explicit format
(`str.to_date("%d.%m.%Y")`, `str.strptime`) is not offered.

On a column that is not a `String` column (a `Null` column included) both
methods raise `SchemaMismatch` (``invalid series dtype: expected `String`, got
`i64` for series with name `a` ``), as the other unary string functions do.

You can also build values from numbers: `AnyValue::date_ymd(2024, 1, 15)` and
`AnyValue::datetime_ymd(2024, 1, 15, hour=10, minute=20)`; an invalid date is a
`ComputeError` (`invalid date: 2024-2-30`; `invalid datetime: 2024-2-30
0:0:0.0` for the datetime form; the numbers are shown as given). The years run
from -262143 to 262142, the range of `chrono` (the library polars uses):
`date_ymd(262143, 1, 1)` is an error, as `pl.date(262143, 1, 1)` is null.

## What is read

The format is found in the first value that has one, and every value of the
column is read with that format only, as in polars (a value that does not fit is
null, or `InvalidOperation` in strict mode; a value with no format is skipped
when looking for the first).

In `group_by(...).agg(...)` and in `over`, the unit is the group: each group
finds its own format from its own first value, as polars does (a table with
`2020-03-02` in one group and `05.06.2020` in another is read with two formats).
The expression is therefore not evaluated row by row there; see
`known-diffs/group_by.md` ("Dates are read per group"). With no key the whole
column is one group.

- A date, year first or day first: `Y-M-D` or `D-M-Y`, with `-`, `/` or `.`;
  month and day have one or two digits (`2024-1-5`, `15.01.2024`). The first
  value decides between the two (day first is tried first: `24-01-15` is the
  24th of January of the year 15, `99-12-31`, with no day 99, is year first;
  after a year-first text `24-01-15` is year 24). The separator may differ from
  value to value. The year has one to four digits, or a sign and any number of
  digits (`+2024`, `-0001`, `+10000`, `+999`, from `-262143` to `+262142`).
  Nothing may follow. As polars does, white space is skipped before each of the
  three numbers (`" 2024- 01- 15"`).
- A datetime: a date of the class of the first value, alone (midnight) or
  followed by `T` or one space and `H:M`, `H:M:S` or `H:M:S.f` (one or two
  digits each, any number of fraction digits, cut to microseconds, seconds up
  to 60). That is the fast reader: the year has exactly four digits and there is
  no white space. polars also reads the values that have the *shape* of the
  first value (the same separator of the date, `T` or a space or no time, with or
  without seconds) with the first value's own format, which allows the wide year
  and white space of the date reader: when the first value is itself read by the
  fast reader (`["2024-01-02", "+2024-01-03"]`), or has `T`, seconds and `-`
  (`+262142-12-31T10:20:30`, alone or in a column that starts with a text of
  that shape). The library reproduces this (`dt_read`); it was measured, not
  derived from polars' code, so some shapes may be missing.
  White space after a `:` of the time is read when the date and time are
  separated by `T` (`2024-01-01T10: 30:00` and `2024-01-01T10:30: 00` are
  2024-01-01 10:30:00, in strict and lenient mode); with a space as the
  separator (`2024-01-01 10: 30:00`) or after the time (`2024-01-01T10:30:00 `)
  the text is not read: null, or `InvalidOperation` in strict mode.
- A time zone: `Z`, `z` or `+hh`, `+hhmm`, `+hh:mm` (hours of any two digits,
  minutes up to 59, a space before it allowed) after the time, on a year-first
  text. polars finds a format for such a text but has no time zone to give the
  column (`to_datetime` without `time_zone`): the library does the same. When the
  first text with a format has an offset, strict mode raises `ComputeError`
  (`` `strptime` / `to_datetime` was called with no format and no time zone, but a
  time zone is part of the data. ``) and `strict=false` gives only nulls. A text
  with an offset after a first text without one is an `InvalidOperation` (strict)
  or null.

## Errors

- A string that is not a date is `null` with `strict=false` and
  `InvalidOperation` with `strict=true`, with the message of a strict conversion
  (`conversion from `str` to `date` failed in column 'a' for 2 out of 3 values:
  ["2024-02-30", "x"]`).
- A series in which no text has a format (`2024-02-30`, `abc`, an empty string;
  for a date a text with a time of day has none either) has nothing polars
  could use. `ComputeError` (`could not find an appropriate format to parse
  dates, please define a format`) with `strict=true`; with `strict=false` both
  `to_date` and `to_datetime` give only nulls.
- A series of only nulls (or empty) gives an all-null column of the target type.

## Where the library differs from polars

- **No time zones.** polars would give `datetime[us, UTC]` for a text with an
  offset if a time zone were allowed; the library never builds such a column
  (see above).
- **Datetimes whose shape is not one the library knows.** The reading of the
  values after the first (see "What is read") was measured on the shapes above;
  a text of another shape (for example a short year after `T` without seconds
  when the first text has none) is read as polars does in the cases measured, and
  is null or an `InvalidOperation` where the library lacks the shape.
  The golden file has the mixed columns that were measured. Day-first datetimes with a
  year of more than four digits or leading zeros (`31-12-10000`, `15-01-02024`)
  get a format from polars' guess for some of them; the library finds none
  (`ComputeError`, where polars gives `InvalidOperation` or null).
- **A lowercase `t` before a UTC offset is not recognised.** When the first
  value of a `to_datetime` column looks like `2024-12-31t10:20:30+02:00`
  (a lowercase `t` between date and time, then an offset or `Z`), polars
  recognises a time zone format: strict mode raises `ComputeError`, and
  `strict=false` returns only nulls. The library finds no format in such a text
  and takes the format from a later value instead, so strict mode raises
  `InvalidOperation` (or reads the column) and `strict=false` can return values.
  An uppercase `T`, and a column that holds only such a text, behave like polars.
- **Wide years after a first value that cannot be read quickly
  (`strict=false` only).** If the first value of a `to_datetime` column is not
  read by polars' fast reader (it has a signed or short year, or white space,
  and is not of the form `<date with "-">T<h:m:s>`), polars still reads later
  values such as `+262142-01-01T00:00:00`, `99-12-31T10:20:30` or
  `1-1-1T1:2:3`. The library returns null for them. In strict mode such a column
  raises on its first value in both, so only `strict=false` differs.
- **Not every polars format is tried.** polars' inference knows more shapes
  (`20240115`, `Jan 15 2024`, ...); only the ones above are read. A series of
  such texts is "no format" here and `str.strptime` with a format is not
  offered.
- **`microsecond=1000000`** is rejected by `datetime_ymd` (0 to 999999);
  `pl.datetime(..., microsecond=1000000)` accepts it as one second later.

## Notes on the golden data

- `docs/golden/date_parse.json` (1141 cases, `scripts/date_parse.py`, polars
  2.1.0) records `str().to_date()` and `to_datetime(time_unit="us")` evaluated
  with `DataFrame.select`, strict and not, on single columns of text. The
  library's `Show` text of each expression is compared with polars'
  `str(expr)`.
- The per-group reading (`group_by(...).agg(...)`, `over`) is in
  `docs/golden/group_final.json` (the cases `parse/...`; see
  `known-diffs/group_by.md`).
- The generated `.mbt` files are committed after `moon fmt`; see
  `docs/golden/README.md`.
