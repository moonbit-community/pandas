# Reading CSV text (`read_csv_str`) compared with `pl.read_csv`

`@pl.read_csv_str(text, options~)` is checked against polars 2.1.0 on 1538 cases
(`docs/golden/csv_read.json`, made by `docs/golden/scripts/csv_read.py`): the
tables of inference, headers, ragged rows, RFC 4180 quoting, line endings, a BOM,
`null_values`, `skip_rows`, `n_rows`, `infer_schema_length`, `schema_overrides`,
`try_parse_dates`, and every ordered pair of 14 value texts as a one-column file.
The result of a case is the same frame, or the same error text, except for the
differences below. Cases marked `"restricted": true` in the JSON are the ones that
follow the rules of the first two sections.

## Errors

- **A bad value, a record with too many fields, a quote that is not closed, text
  after a closing quote, and empty input raise `ParseError`.** polars raises
  `ComputeError` (or `NoDataError` for `empty CSV`). The message is the first line
  of polars' message followed by ` at line N`, where N is the physical line
  (1 based, counting the line breaks inside quoted fields, not counting a BOM) on
  which the offending record starts. `empty CSV` has no line. If the text of the
  message contains a line break (a quoted value with a break), the message stops
  at it, as the first line of polars' message does.
- **Bad options raise `InvalidOperation`:** a negative `n_rows`, `skip_rows` or
  `infer_schema_length`, a `separator` or `quote_char` that is `'\n'` or `'\r'`,
  and a `separator` equal to the `quote_char`. polars raises `ValueError` or
  `OverflowError`. The texts are the same as in `write_csv_str`:
  - `separator must not be a line break (LF or CR)`
  - `quote_char must not be a line break (LF or CR)`
  - `separator and quote_char must differ, got '<c>'`
  - `n_rows must not be negative, got <n>` (the same for `skip_rows` and
    `infer_schema_length`)
- **A file that is not valid UTF-8 raises `ParseError("invalid utf-8 sequence")`**
  in `@plfs.read_csv`, wherever the bad byte is. polars 2.1.0 raises an error for
  a bad byte in a value too (`ComputeError: invalid utf-8 sequence`). The
  difference is only in two places, where polars is lenient: a bad byte in the
  header is replaced with U+FFFD in the column name (`a\xff` gives `a�`), and a bad
  byte in a row that `skip_rows` skips is ignored. The library raises in both.
  Convert the file to UTF-8 first.
- **A file that cannot be opened raises `PolarsError::IOError(msg)`** with the text
  of the operating system, which includes the path; `e.to_string()` is
  `IOError: <msg>`. polars raises `FileNotFoundError` or another Python
  `OSError`.
- The duplicate-name error (`DuplicateColumn`) and the "unsupported data type when
  reading CSV: null" error (`ComputeError`, for a `Null` override) have polars'
  text.

## Types the library does not have

- **An integer that does not fit `Int64` is read as polars does, except where
  polars gives `Int128`, which the library does not have: there the column is a
  `String`**, so no digit is lost. In the inference window:
  - Such integers with no float-shaped value (`1.5`, `1e3`, `NaN`, `inf`), with
    or without small integers and empty fields: `Int128` in polars, `String`
    here, the text kept to the last digit (`9223372036854775808` stays
    `9223372036854775808`). An integer above the `Int128` maximum
    (`170141183460469231731687303715884105727`, about 1.7e38) or below its minimum
    (`-170141183460469231731687303715884105728`) is a `ComputeError` in polars
    (`could not parse ... as dtype i128`) and a `String` here.
  - Such integers with float-shaped values and no small integer: `Float64` in
    both.
  - A small integer, such an integer and a float-shaped value: `String` in both.

  To get floats from the first case, name the column in `schema_overrides`:
  `{ "id": Float64 }`. A column that was inferred as `Int64` and has such a value
  after the inference window is a `ParseError`, as in polars. The cases are not
  all in the golden data.
- Texts with an offset (`2024-01-02T01:02:03Z`, `+01:00`) and bare times
  (`03:04:05`) are `String` with `try_parse_dates=true`; polars reads `Datetime`
  with a time zone and `Time`. With a `Datetime` override a text with an offset is
  a `ParseError` (polars converts it to UTC). To read such a column, read it as a
  `String` first (`schema_overrides={ "ts": String }`) and deal with the offset
  afterwards, or export the file without the `Z` or offset.
- `schema_overrides` takes `Int32`, `Int64`, `Float32`, `Float64`, `Boolean`,
  `String`, `Date`, `Datetime`; there are no unsigned or small integers, `Time`,
  `Decimal` or `Categorical` overrides. A `Null` override is an error, as in polars.

## Options that differ or are missing

- **`try_parse_dates` is an option (default `false`).** The spec says dates are
  inferred; polars does not do that by default (`2024-01-02` is a `String`), and
  the library follows polars. With `true` the rules are polars': day-first formats
  are tried first, a column mixing a date and a datetime is a `String`, the first
  value decides the format of the rest (a later text in another format is a
  `ParseError`, not a `String`).
- **`separator` and `quote_char` are `Char`s of any width** (polars: one byte), so
  `'§'` and `'😀'` work.
- **`null_values` is a list for every column** (polars also takes a dictionary per
  column and a single string). It is matched against the field as written between
  the quotes (a doubled quote stays doubled), like polars.
- **`schema_overrides` is by name only** (no list by position). The names are those
  after de-duplication (`a`, `a_duplicated_0`), like polars; names that are not
  columns are ignored.
- **Not offered:** `columns`, `new_columns`, `schema`, `comment_prefix`,
  `skip_lines`, `skip_rows_after_header`, `truncate_ragged_lines`, `eol_char`,
  `decimal_comma`, `ignore_errors`, `raise_if_empty`, `encoding`,
  `empty_string_is_null`, `low_memory`, `row_index_*`, `include_file_paths`.
  Line endings are `\n` and `\r\n`; a bare `\r` is an ordinary character.
- `n_rows` follows this rule: without it every record is read; with `n_rows = n` the
  reading stops after `max(n, infer_schema_length)` records (all of them when
  `infer_schema_length` is `None`), and what comes later is never looked at; with
  `n_rows = 0` the result has no rows, nothing is raised for the data, and the types
  come from the first `infer_schema_length` records (a malformed record there is
  inferred like the others: its fields before the extra ones, a wrong quote as a
  string). polars parses a whole chunk, so with `n_rows >= 1` on a small text it
  still raises the error of a bad value or a long row after those records, which the
  library does not (cases where that matters are not in the golden data). With
  `n_rows = 0` polars raises nothing either, as here; the golden data has such cases
  (a bad quote inside the window makes the column `String`, as in polars).

## Lexical differences

- **A quote inside an unquoted field is an ordinary character**, always. polars
  does that when the quotes in the line are even in number and raises
  `CSV malformed: expected 0 rows, ...` when they are odd (`ab"c,2`); the library
  reads `ab"c`.
- **A header with a broken quote is a `ParseError`** (a quote that is not closed,
  or text after the closing quote). polars reads such a header as one odd column
  name (`"x"y,b` gives the names `x"` and `b`; an open quote swallows the rest of the
  text into the name).
- **`skip_rows` counts records.** With a header, blank lines at the very start of the
  text are not counted (`"\na,b\n1,2\n3,4"` with `skip_rows=1` gives the names `1`,
  `2`, as in polars), a blank line right after the skipped records is the header
  (so `"x\n\na,b\n1,2"` with `skip_rows=1` is a long-row error, as in polars), and
  blank lines inside the skipped records count. Without a header the blank lines at
  the start are records like any other. The golden data has these cases; the
  remaining oddities of polars with blank lines when `n_rows` and `skip_rows` are
  combined are not copied.
- **A trailing separator** at the end of a data record is one more (empty) field,
  hence a long-row error when the header has no such column, as in polars, when a
  line break follows. At the very end of the text polars drops it (`"a,b\n1,2,"` is a
  frame there), the library reports the long row (`"a\n1,"` and `"a\n1\n,"` too).
  The other leniencies of polars at the end of the text are not copied either: an
  unterminated quote in the last record is null in a non-`String` column past the
  inference window; with `try_parse_dates` or a `Date` / `Datetime` override a last
  record without a final line break may be in another date format (with a final line
  break it is an error); a last record that is only a bare `\r` before a separator
  is null there and `"\r"` here.
- **A letter as `quote_char`** (rare): with `quote_char=Some('N')`, polars reads the
  field `NNaNN` as the float `NaN` (the column is `Float64`), while the library
  raises `ParseError` (``could not parse `NNaNN` as dtype `str` ...``).
- **Fullwidth digits** (`１２`) among digits: polars infers `Int128` from the other
  values and then fails to parse; here the column is a `String`.

## Same as polars (and easy to get wrong)

A blank line is a row of nulls (also with `has_header=false`, where it is data); an
unquoted empty field is null, `""` is the empty string, and a `""` in an otherwise
numeric column makes the column `String` inside the inference window and null
after it; an all-empty column is `String`; short records are padded with nulls; the
header is not unescaped (`"a""b"` is the name `a""b`); `+5`, `Inf`, `INF`, `nan`,
`-nan`, `1.e5` and `infinity` are strings when inferred, but `+5`, `Inf`, `nan`,
`-nan` and `infinity` parse with a `Float64` override; an `Int` or `Float` override
accepts leading spaces and tabs, an `Int` override a `+`; `n_rows` does not shrink
the inference window.

A record with more fields than the header is an error. Without a header the table
is as wide as the widest record inside the inference window (every record with
`infer_schema_length=None`) and the other rows are padded with nulls, as in
polars. So N rows and one record of W fields make N x W cells, and one very wide
row in a long file takes a lot of memory (about 62 billion cells for a 250,000-row
file with one 250,000-field row).

## Order of errors and white space

- With several problems in one text the error is the first one in file order, as
  in polars: the first bad record, and inside a record the first column; a record
  with too many fields counts after all its columns. The message of text after a
  closing quote names the type of the column (`i64`, `f64`, `bool`, `date`, ...), which is `str`
  when the record is inside the inference window (polars reads the bad field as a
  string there).
- A field of only spaces and tabs is null in an `Int32`, `Int64`, `Float32` or
  `Float64` column (override, or a value past the inference window), quoted or
  not, as in polars. For `Boolean`, `Date`, `Datetime` it is an error and for
  `String` the text. Other white space (NBSP, em space, `\v`, `\f`) is not blank.

## Malformed records and the inference

- A record with too many fields or a wrong quote is read for the type inference
  like any other record of the window (as polars does): its fields before the extra
  ones, and a field with text after the closing quote or a quote that never closes
  as a string. The records after it, inside the window, are read too. So
  `a\n-5\n1.5,x\n` is a long-row error (the column is `Float64`), not a value error
  for `1.5`, and `n_rows=0` gives the types of the whole window.
- A quote character that is not at the start of a field toggles polars' quote state:
  a field with text after the closing quote goes on to the first separator or line
  break outside quotes, up to the end of the text when a quote stays open. The
  library does the same for the text of the error message. polars sometimes does not
  raise for such a field and returns the text with the quotes removed (`a,b,c,d\n2024-13-01,"x,"1",x,"q"`
  gives the text `x,1,x,q` in column `b`); the library raises. These cases are not in the golden
  data.
- A quote that never closes in a skipped record is skipped (`empty CSV` when nothing
  is left, as in polars). In the header it is an error.
- On the error path the columns are built up to the malformed record before the error
  is raised (so that an earlier value error can win); an error on the last line of a
  large text costs about a full build.
