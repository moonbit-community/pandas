///|
/// Options of `read_csv_str`, the counterparts of the parameters of polars'
/// `pl.read_csv`. Build one with `CsvReadOptions::new`; the fields are
/// read-only.
#derive(Eq, @debug.Debug)
pub struct CsvReadOptions {
  /// The field separator (one character, not a line break).
  separator : Char
  /// Whether the first record is the header.
  has_header : Bool
  /// The quote character, `None` when quoting is off.
  quote_char : Char?
  /// Texts that read as null, in every column.
  null_values : Array[String]
  /// Column types by name, instead of inferring them.
  schema_overrides : Map[String, DataType]
  /// How many records the type inference looks at (`None`: all of them).
  infer_schema_length : Int32?
  /// The maximum number of rows to return.
  n_rows : Int32?
  /// How many records to skip before the header.
  skip_rows : Int32
  /// Whether date and datetime texts are read as `Date` and `Datetime`.
  try_parse_dates : Bool
}

///|
/// Creates the options of `read_csv_str`.
///
/// - `separator` (default `','`): any character that is not a line break and
///   differs from `quote_char`. polars accepts one byte only; here a character
///   of any width is fine.
/// - `has_header` (default `true`): when `false` the columns are named
///   `column_0`, `column_1`, ... and every record is data, blank lines too
///   (polars does the same).
/// - `quote_char` (default `Some('"')`): `None` makes every character an
///   ordinary one. Same as polars (`quote_char=None`).
/// - `null_values` (default none): texts that are null in every column, matched
///   exactly (no trimming, case-sensitive) against the field without its
///   quotes, so a quoted field can be null too (a doubled quote inside stays
///   doubled, as in polars). The header is not affected. polars also takes a
///   per-column dictionary; here the list applies to all columns.
/// - `schema_overrides` (default none): the type of the named columns, taken
///   from `Int32`, `Int64`, `Float32`, `Float64`, `Boolean`, `String`, `Date`
///   and `Datetime`; a name that is not a column is ignored (as in polars).
///   `Null` raises `ComputeError`. The names are those after the header's
///   de-duplication (`a`, `a_duplicated_0`, ...).
/// - `infer_schema_length` (default `Some(100)`): the number of data records
///   the type inference reads; `None` reads all of them, `Some(0)` makes every
///   column `String`. A later value that does not read as the inferred type
///   raises `ParseError`. Integer texts that do not fit `Int64`
///   (`18446744073709551615`) inside that window: next to a float-shaped value
///   (`1.5`, `inf`, `1e3`) and no small integer the column is `Float64`, as in
///   polars; with no float-shaped value (polars reads `Int128`, which this
///   library has not) or with small integers, big ones and floats together
///   (polars: `String`) it is `String`, the digits exact; override the column
///   as `Float64` to get floats. Past the window such a value is a
///   `ParseError` in an `Int64` column and a float in a `Float64` column.
/// - `n_rows` (default: all): at most this many rows are returned. It only
///   trims the result, the inference still looks at `infer_schema_length`
///   records (polars does the same). The exact rule: without `n_rows` every
///   record is read, so a bad value or record anywhere is an error; with
///   `n_rows = n` the reading stops after `max(n, infer_schema_length)` records
///   (all of them when `infer_schema_length` is `None`) and what comes later is
///   never looked at; with `n_rows = 0` the result has no rows and nothing is
///   raised for the data: the types come from the first `infer_schema_length`
///   records, the malformed ones (too many fields, a wrong quote) included as in
///   the other cases (polars reads the rows after `n_rows` too, and raises for
///   them on small texts, except for `n_rows = 0`).
/// - `skip_rows` (default 0): the number of records (not lines: a quoted line
///   break is inside one record) skipped before the header. With a header,
///   blank lines at the very start of the text are not counted, and a blank
///   line right after the skipped records is the header (as in polars); without
///   a header the blank lines at the start are records like any other.
/// - `try_parse_dates` (default `false`): when `true`, a column of date texts
///   (`2024-01-02`, `2024/01/02`, `02.01.2024`, ...) is `Date` and one of
///   datetime texts without an offset is `Datetime`; by default both are
///   `String`, as in polars. Texts with an offset (`Z`, `+01:00`) and bare times
///   stay `String` (polars reads them as `Datetime` with a time zone and `Time`).
///
/// `read_csv_str` raises `InvalidOperation` (polars raises `ValueError` or
/// `OverflowError`) for:
///
/// - a negative `n_rows`, `skip_rows` or `infer_schema_length`:
///   `n_rows must not be negative, got -1` (and likewise for the other two);
/// - a `separator` or `quote_char` that is `'\n'` or `'\r'`:
///   `separator must not be a line break (LF or CR)` and
///   `quote_char must not be a line break (LF or CR)`, the same texts as
///   `write_csv_str`;
/// - a `separator` equal to the `quote_char`:
///   `separator and quote_char must differ, got '|'` (the separator in the
///   quotes).
pub fn CsvReadOptions::new(
  separator~ : Char = ',',
  has_header~ : Bool = true,
  quote_char~ : Char? = Some('"'),
  null_values~ : Array[String] = [],
  schema_overrides~ : Map[String, DataType] = {},
  infer_schema_length~ : Int32? = Some(100),
  n_rows? : Int32,
  skip_rows~ : Int32 = 0,
  try_parse_dates~ : Bool = false,
) -> CsvReadOptions {
  {
    separator,
    has_header,
    quote_char,
    null_values,
    schema_overrides,
    infer_schema_length,
    n_rows,
    skip_rows,
    try_parse_dates,
  }
}

///|
fn csv_check_options(o : CsvReadOptions) -> Unit raise PolarsError {
  if o.n_rows is Some(n) && n < 0 {
    raise InvalidOperation("n_rows must not be negative, got \{n}")
  }
  if o.skip_rows < 0 {
    raise InvalidOperation("skip_rows must not be negative, got \{o.skip_rows}")
  }
  if o.infer_schema_length is Some(n) && n < 0 {
    raise InvalidOperation("infer_schema_length must not be negative, got \{n}")
  }
  if o.separator == '\n' || o.separator == '\r' {
    raise InvalidOperation("separator must not be a line break (LF or CR)")
  }
  if o.quote_char is Some(q) {
    if q == '\n' || q == '\r' {
      raise InvalidOperation("quote_char must not be a line break (LF or CR)")
    }
    if q == o.separator {
      raise InvalidOperation(
        "separator and quote_char must differ, got '\{o.separator}'",
      )
    }
  }
}

///|
/// The names of the columns from the header's fields: a repeated name gets
/// `_duplicated_0`, `_duplicated_1`, ... after it; a generated name that is
/// also in the header is an error.
fn csv_dedup_names(raw : Array[String]) -> Array[String] raise PolarsError {
  let all : Map[String, Unit] = Map([])
  for n in raw {
    all[n] = ()
  }
  let seen : Map[String, Int32] = Map([])
  let out : Array[String] = []
  for n in raw {
    let count = seen.get(n).unwrap_or(0)
    if count == 0 {
      out.push(n)
    } else {
      let cand = "\{n}_duplicated_\{count - 1}"
      if all.contains(cand) {
        raise DuplicateColumn(
          "de-duplication of occurrence #\{count + 1} of column name '\{n}' failed; the name '\{cand}' also exists in the file.",
        )
      }
      out.push(cand)
    }
    seen[n] = count + 1
  }
  out
}

///|
/// Reads CSV text into a `DataFrame`, like polars' `pl.read_csv` on the same
/// text (see `CsvReadOptions::new` for the options).
///
/// - **Records** end at `\n` (a `\r` before it is dropped; a bare `\r` is an
///   ordinary character); the last line needs no line break and the final line
///   break does not start a record. A BOM at the start is removed.
/// - **Quoting**: a field is quoted when it starts with the quote character; a
///   doubled quote inside is one quote, and separators and line breaks are
///   literal. A quote in the middle of an unquoted field is an ordinary
///   character (polars reports "CSV malformed" when the quotes are odd in
///   number).
/// - **Header**: blank lines before it are skipped. Repeated names become
///   `a`, `a_duplicated_0`, ... (`DuplicateColumn` when a generated name is in
///   the header too); empty names stay; a header does not unescape `""`.
/// - **Rows**: a blank line between records is a row of nulls; an unquoted empty
///   field is null while `""` is the empty string; a short record is padded with
///   nulls; a record with more fields than the header is an error.
/// - **Types**: per column, the first of `Int64` (`-?digits`), `Float64`
///   (`1.5`, `.5`, `5.`, `1e3`, `inf`, `NaN`, with a sign), `Boolean`
///   (`true`/`false`, any case), `Date`, `Datetime` (only with
///   `try_parse_dates`), `String` that reads every non-null value of the first
///   `infer_schema_length` records; integer texts beyond `Int64` in that window
///   give `Float64` next to a float-shaped value and no small integer, else
///   `String` (see `CsvReadOptions::new`). Texts are never
///   trimmed, `+5`, `Inf`, `nan` are strings. A quoted empty string makes a column
///   `String`; a column with no values is `String`. A value beyond the inference
///   window that does not read as the column's type is an error. An override
///   reads more: `Int` and `Float` texts may start with spaces or tabs, an `Int`
///   may have a `+`, a `Float` may be `Inf` or `nan`, a `Datetime` may be a date
///   alone (midnight). In an `Int` or `Float` column (override, or a value
///   beyond the inference window) a field of nothing but spaces and tabs is
///   null, as in polars; for the other types it is an error.
/// - **Errors**: `ParseError` with polars' message (its first line) and
///   ` at line N`, where N is the physical line (1 based, quoted line breaks
///   counted) on which the offending record starts: a value that does not parse,
///   a quote left open, text after a closing quote, a record with too many
///   fields. With several problems the first record in file order is reported,
///   and in a record the first column (a record with too many fields is
///   reported after all its columns), as polars does. Empty input (or
///   everything skipped) is `ParseError("empty CSV")`. Bad options are
///   `InvalidOperation`.
pub fn read_csv_str(
  text : String,
  options~ : CsvReadOptions = CsvReadOptions::new(),
) -> DataFrame raise PolarsError {
  csv_check_options(options)
  let sc = CsvScanner::new(text, options.separator, options.quote_char)
  let mut names : Array[String] = []
  // with a header, blank lines before the first record are not counted by
  // `skip_rows`
  let mut have = false
  if options.has_header {
    while sc.pos < sc.len {
      sc.scan_record()
      if sc.is_blank_record(0) {
        sc.clear_records()
      } else {
        have = true
        break
      }
    }
  }
  // records skipped before the header
  let mut to_skip = options.skip_rows
  if have && to_skip > 0 {
    sc.clear_records()
    have = false
    to_skip -= 1
  }
  for _ in 0..<to_skip {
    if sc.pos >= sc.len {
      break
    }
    sc.scan_record()
    sc.clear_records()
  }
  if options.has_header {
    // the header is the next record; blank lines before it are skipped only at
    // the start of the text (polars takes a blank line after skipped rows as the
    // header)
    while !have {
      if sc.pos >= sc.len {
        raise ParseError("empty CSV")
      }
      sc.scan_record()
      if options.skip_rows == 0 && sc.is_blank_record(0) {
        sc.clear_records()
      } else {
        have = true
      }
    }
    if sc.bad_quote is Some((a, b, k, line)) {
      raise ParseError(
        sc.could_not_parse(a, b, "str", csv_column_name([], k), k) +
        " at line \{line}",
      )
    }
    let raw : Array[String] = []
    for i in 0..<sc.nfields(0) {
      raw.push(sc.text[sc.fstart[i]:sc.fend[i]].to_owned())
    }
    sc.clear_records()
    names = csv_dedup_names(raw)
  } else if sc.pos >= sc.len {
    raise ParseError("empty CSV")
  }
  // the records the inference and the result need
  let window = options.infer_schema_length
  let nrows_want = options.n_rows
  // Without `n_rows` every record is read (a bad value beyond the inference
  // window is an error); with it, reading stops after the records the result
  // and the inference need; with `n_rows = 0`, after the inference window.
  let limit = match nrows_want {
    None => csv_unbounded
    Some(n) =>
      match window {
        None => csv_unbounded
        Some(k) => if n > k { n } else { k }
      }
  }
  // The first malformed record (more fields than columns, a wrong quote) is
  // noted by the scanner, not raised: the records after it are read for the
  // type inference, and a value error that comes before it in file order is
  // the error. `after_err` is the number of records read when there is one.
  let after_err = match window {
    None => csv_unbounded
    Some(k) => k
  }
  if options.has_header {
    sc.scan_some(limit, after_err, names.length())
  } else {
    // no header: the width is that of the widest record of the inference
    // window, at least the first record
    let first = match window {
      None => csv_unbounded
      Some(k) => if k < 1 { 1 } else { k }
    }
    sc.scan_some(first, after_err, csv_unbounded)
    let mut width = 0
    for r in 0..<sc.nrecords() {
      if sc.nfields(r) > width {
        width = sc.nfields(r)
      }
    }
    for k in 0..<width {
      names.push("column_\{k}")
    }
    let limit2 = if limit < first { first } else { limit }
    sc.scan_some(limit2, after_err, width)
  }
  let total = sc.nrecords()
  let nrows = match nrows_want {
    Some(n) => if n < total { n } else { total }
    None => total
  }
  let infer_rows = match window {
    None => total
    Some(k) => if k < total { k } else { total }
  }
  // the malformed record: its column and line, and for a wrong quote the
  // raw text of the field
  let skind = if nrows_want is Some(0) { 0 } else { sc.struct_kind }
  // A wrong quote in a record of the inference window is a string there: its
  // column is `String`.
  let qcol = if sc.struct_kind == 2 &&
    (match window {
      None => true
      Some(w) => sc.struct_rec < w
    }) {
    sc.struct_col
  } else {
    -1
  }
  for name in names {
    if options.schema_overrides.get(name) is Some(Null) {
      raise ComputeError(
        "unsupported data type when reading CSV: null when reading CSV",
      )
    }
  }
  // values after the malformed record are not read
  let build_rows = if skind != 0 && sc.struct_rec + 1 < nrows {
    sc.struct_rec + 1
  } else {
    nrows
  }
  let ns = CsvNulls::new(options.null_values)
  let cols : Array[Series] = []
  // the first value error: the first record, then the first column
  let mut best : (Int32, Int32, PolarsError)? = None
  let dtypes : Array[DataType] = []
  for c, name in names {
    let dtype = match options.schema_overrides.get(name) {
      Some(dt) => dt
      None =>
        if c == qcol {
          DataType::String
        } else {
          sc.infer_column(c, infer_rows, ns, options.try_parse_dates)
        }
    }
    dtypes.push(dtype)
    let r : Result[Series, PolarsError] = Ok(
      sc.build_column(c, build_rows, ns, name, dtype),
    ) catch {
      e => Err(e)
    }
    match r {
      Ok(s) => cols.push(s)
      Err(e) =>
        match best {
          Some((row, _, _)) if row <= sc.err_row => ()
          _ => best = Some((sc.err_row, c, e))
        }
    }
  }
  // a value error before the malformed record, or in the same record at a
  // column before (or at) the error's column, comes first
  if best is Some((row, c, e)) {
    if skind == 0 ||
      row < sc.struct_rec ||
      (row == sc.struct_rec && c <= sc.struct_col) {
      raise e
    }
  }
  if skind == 1 {
    raise ParseError(
      "found more fields than defined in 'Schema' at line \{sc.rec_line[sc.struct_rec]}",
    )
  }
  if skind == 2 {
    let i = sc.rec_first[sc.struct_rec] + sc.struct_col
    let k = sc.struct_col
    let dname = if k < dtypes.length() { dtypes[k].to_string() } else { "str" }
    raise ParseError(
      sc.could_not_parse(
        sc.fstart[i],
        sc.fend[i],
        dname,
        csv_column_name(names, k),
        k,
      ) +
      " at line \{sc.rec_line[sc.struct_rec]}",
    )
  }
  DataFrame::new(cols)
}
