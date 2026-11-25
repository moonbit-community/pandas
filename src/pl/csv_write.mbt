///|
/// When `write_csv_str` puts quote characters around a field (the names are
/// polars' `quote_style` values).
///
/// - `Necessary` (the default): a field is quoted when it contains the
///   separator, the quote character, `\n` or `\r`, or is the empty string.
///   Header names follow the same rule.
/// - `Always`: every field and header name is quoted; a null is written as
///   the quote character, the `null_value` and the quote character.
/// - `NonNumeric`: strings (also numeric-looking ones), booleans, dates,
///   datetimes and header names are quoted; integers and floats (`NaN` and
///   `inf` included) and nulls are not.
/// - `Never`: nothing is quoted, even when that makes the output ambiguous.
///
/// Inside a quoted field the quote character is doubled (except with
/// `Never`).
#derive(Eq, @debug.Debug)
pub(all) enum QuoteStyle {
  Necessary
  Always
  NonNumeric
  Never
}

///|
/// Formats the style with polars' name (`necessary`, `always`, `non_numeric`,
/// `never`).
pub impl Show for QuoteStyle with fn output(self, logger) {
  logger.write_string(
    match self {
      Necessary => "necessary"
      Always => "always"
      NonNumeric => "non_numeric"
      Never => "never"
    },
  )
}

///|
/// Makes `to_string` callable as a method (`QuoteStyle::Always.to_string()` is
/// `"always"`).
pub extend QuoteStyle with Show::{to_string}

///|
/// Options of `write_csv_str` (the counterparts of the keyword arguments of
/// polars' `DataFrame.write_csv`). Build them with `CsvWriteOptions::new`; the
/// fields can be read but not changed.
///
/// - `include_header`: write the column names as the first line.
/// - `separator`: the field separator (any character except `\n` and `\r`;
///   polars only takes a single byte).
/// - `line_terminator`: the text that ends every line, the header and the last
///   row included (any string, also `""`).
/// - `quote_char`: the quote character (any character except `\n` and `\r`,
///   and not the separator).
/// - `quote_style`: see `QuoteStyle`.
/// - `null_value`: the text written for a null (polars: `null_value`, empty by
///   default). It is written as it is, never quoted or escaped, except that
///   `Always` puts quote characters around it.
/// - `include_bom`: start the output with U+FEFF.
#derive(Eq, @debug.Debug)
pub struct CsvWriteOptions {
  include_header : Bool
  separator : Char
  line_terminator : String
  quote_char : Char
  quote_style : QuoteStyle
  null_value : String
  include_bom : Bool
}

///|
/// Creates write options. The defaults are polars': header, `,` as separator,
/// `"\n"` as line terminator, `"` as quote character, `Necessary` quoting, an
/// empty `null_value` and no BOM. The combination is checked by
/// `write_csv_str`, not here.
pub fn CsvWriteOptions::new(
  include_header~ : Bool = true,
  separator~ : Char = ',',
  line_terminator~ : String = "\n",
  quote_char~ : Char = '"',
  quote_style~ : QuoteStyle = Necessary,
  null_value~ : String = "",
  include_bom~ : Bool = false,
) -> CsvWriteOptions {
  {
    include_header,
    separator,
    line_terminator,
    quote_char,
    quote_style,
    null_value,
    include_bom,
  }
}

///|
/// A character as the UTF-16 code units it takes in a `String` (`lo` is -1
/// for a character in the basic plane).
priv struct CsvUnits {
  hi : Int32
  lo : Int32
}

///|
fn CsvUnits::of(c : Char) -> CsvUnits {
  let code = c.to_int()
  if code < 0x10000 {
    { hi: code, lo: -1, }
  } else {
    let v = code - 0x10000
    { hi: 0xD800 + (v >> 10), lo: 0xDC00 + (v & 0x3FF), }
  }
}

///|
fn CsvUnits::len(self : CsvUnits) -> Int32 {
  if self.lo < 0 {
    1
  } else {
    2
  }
}

///|
/// Whether the character starts at index `i` of `s` (`c` is `s[i]`).
fn CsvUnits::matches(self : CsvUnits, s : String, i : Int32, c : Int32) -> Bool {
  c == self.hi &&
  (self.lo < 0 || (i + 1 < s.length() && s[i + 1].to_int() == self.lo))
}

///|
/// The output being built and the formatting rules of one `write_csv_str`
/// call.
priv struct CsvOut {
  sb : StringBuilder
  sep : CsvUnits
  quote : CsvUnits
  quote_text : String
  style : QuoteStyle
  null_value : String
}

///|
/// Whether `s` must be quoted under the `Necessary` rule: it is empty or
/// contains the separator, the quote character, `\n` or `\r`.
fn CsvOut::needs_quote(self : CsvOut, s : String) -> Bool {
  let n = s.length()
  if n == 0 {
    return true
  }
  for i in 0..<n {
    let c = s[i].to_int()
    if c == 10 ||
      c == 13 ||
      self.sep.matches(s, i, c) ||
      self.quote.matches(s, i, c) {
      return true
    }
  }
  false
}

///|
/// Writes `s` with every quote character doubled, without the outer quotes.
fn CsvOut::write_escaped(self : CsvOut, s : String) -> Unit {
  let n = s.length()
  let qlen = self.quote.len()
  let mut start = 0
  let mut i = 0
  while i < n {
    if self.quote.matches(s, i, s[i].to_int()) {
      // copy up to and including the quote, then write the quote again
      self.sb.write_substring(s, start, i + qlen - start)
      self.sb.write_string(self.quote_text)
      i += qlen
      start = i
    } else {
      i += 1
    }
  }
  if start < n {
    self.sb.write_substring(s, start, n - start)
  }
}

///|
fn CsvOut::write_quoted(self : CsvOut, s : String) -> Unit {
  self.sb.write_string(self.quote_text)
  self.write_escaped(s)
  self.sb.write_string(self.quote_text)
}

///|
/// Writes one field. `textual` is true for strings, booleans, dates,
/// datetimes and header names (what `NonNumeric` quotes).
fn CsvOut::field(self : CsvOut, s : String, textual : Bool) -> Unit {
  match self.style {
    Never => self.sb.write_string(s)
    Always => self.write_quoted(s)
    NonNumeric =>
      if textual || self.needs_quote(s) {
        self.write_quoted(s)
      } else {
        self.sb.write_string(s)
      }
    Necessary =>
      if self.needs_quote(s) {
        self.write_quoted(s)
      } else {
        self.sb.write_string(s)
      }
  }
}

///|
/// Writes a null: the `null_value`, in quotes only under `Always`.
fn CsvOut::null(self : CsvOut) -> Unit {
  match self.style {
    Always => {
      self.sb.write_string(self.quote_text)
      self.sb.write_string(self.null_value)
      self.sb.write_string(self.quote_text)
    }
    _ => self.sb.write_string(self.null_value)
  }
}

///|
/// The function that writes the cell of row `i` of `col`.
fn csv_cell_writer(out : CsvOut, col : Column) -> (Int32) -> Unit {
  match col {
    Boolean(a) =>
      i => {
        if a.is_valid(i) {
          out.field(if a.value(i) { "true" } else { "false" }, true)
        } else {
          out.null()
        }
      }
    Int32(a) =>
      i => {
        if a.is_valid(i) {
          out.field(a.value(i).to_string(), false)
        } else {
          out.null()
        }
      }
    Int64(a) =>
      i => {
        if a.is_valid(i) {
          out.field(a.value(i).to_string(), false)
        } else {
          out.null()
        }
      }
    Float32(a) =>
      i => {
        if a.is_valid(i) {
          out.field(format_f32(a.value(i)), false)
        } else {
          out.null()
        }
      }
    Float64(a) =>
      i => {
        if a.is_valid(i) {
          out.field(format_f64(a.value(i)), false)
        } else {
          out.null()
        }
      }
    String(a) =>
      i => if a.is_valid(i) { out.field(a.value(i), true) } else { out.null() }
    Date(a) =>
      i => {
        if a.is_valid(i) {
          match format_date_checked(a.value(i)) {
            Some(s) => out.field(s, true)
            // checked before writing starts
            None => abort("write_csv_str: unformattable date")
          }
        } else {
          out.null()
        }
      }
    Datetime(a) =>
      i => {
        if a.is_valid(i) {
          out.field(format_datetime_sep(a.value(i), "T"), true)
        } else {
          out.null()
        }
      }
    Null(_) => _ => out.null()
  }
}

///|
/// Raises `ComputeError` for the first `Date` that cannot be formatted (more
/// than `max_format_days` from the epoch; polars panics there).
fn csv_check_dates(df : DataFrame) -> Unit raise PolarsError {
  for s in df.cols {
    match s.col {
      Date(a) =>
        for i in 0..<a.length() {
          if a.is_valid(i) {
            let d = a.value(i)
            if d > max_format_days || d < -max_format_days {
              raise ComputeError(
                "column \"\{s.name}\": cannot write Date to CSV: value date(\{d}) at index \{i} cannot be formatted",
              )
            }
          }
        }
      _ => ()
    }
  }
}

///|
/// Renders `df` as CSV text.
///
/// The text follows polars' `DataFrame.write_csv()`:
/// - the header line (unless `include_header` is false), then one line per
///   row; every line, the last one included, ends with `line_terminator`;
/// - quoting follows `quote_style` (see `QuoteStyle`); the quote character
///   inside a quoted field is doubled;
/// - a null is written as `null_value` (empty by default), a `Null` column is
///   all nulls; an empty string is `""` under `Necessary`;
/// - `Int32`, `Int64`, `Boolean` as `123`, `true`/`false`; `Float64` and
///   `Float32` in polars' shortest round-trip form (`1.0`, `0.1`, `1e+20`,
///   `1e-6`, `NaN`, `inf`, `-inf`, `-0.0`); `Date` as `YYYY-MM-DD` (`+10183-09-21`
///   above year 9999, `-0221-09-04` below year 0); `Datetime` as
///   `YYYY-MM-DDTHH:MM:SS.ffffff` (a `T`, always six digits);
/// - no rows: only the header line; no columns: one empty line (nothing with
///   `include_header=false`); `include_bom` puts U+FEFF in front of all of it.
///
/// Every cell is written once into one buffer, so the time and memory are
/// linear in the size of the output.
///
/// Differences from polars: under `Necessary` and `NonNumeric` a number,
/// date or boolean whose text contains the separator or the quote character
/// (only possible with a separator such as `.`, `-` or `1`) is quoted, where
/// polars writes it raw and produces an unreadable row; `Never` writes raw.
///
/// # Errors
/// - `InvalidOperation` when `separator` or `quote_char` is `\n` or `\r`
///   (`separator must not be a line break (LF or CR)`, `quote_char must not
///   be a line break (LF or CR)`), or when they are the same character
///   (`separator and quote_char must differ, got ','`). Checked first, even
///   for an empty frame. polars accepts these and writes unreadable text.
/// - `ComputeError` when a non-null `Date` is more than 110 million days from
///   1970-01-01 (polars panics): `column "d": cannot write Date to CSV: value
///   date(110000001) at index 1 cannot be formatted`.
pub fn write_csv_str(
  df : DataFrame,
  options~ : CsvWriteOptions = CsvWriteOptions::new(),
) -> String raise PolarsError {
  let sep = options.separator
  let quote = options.quote_char
  if sep == '\n' || sep == '\r' {
    raise InvalidOperation("separator must not be a line break (LF or CR)")
  }
  if quote == '\n' || quote == '\r' {
    raise InvalidOperation("quote_char must not be a line break (LF or CR)")
  }
  if sep == quote {
    raise InvalidOperation("separator and quote_char must differ, got '\{sep}'")
  }
  csv_check_dates(df)
  let sb = StringBuilder()
  let out : CsvOut = {
    sb,
    sep: CsvUnits::of(sep),
    quote: CsvUnits::of(quote),
    quote_text: quote.to_string(),
    style: options.quote_style,
    null_value: options.null_value,
  }
  let sep_text = sep.to_string()
  let term = options.line_terminator
  let cols = df.cols
  let nc = cols.length()
  if options.include_bom {
    sb.write_char('\u{FEFF}')
  }
  if options.include_header {
    for j in 0..<nc {
      if j > 0 {
        sb.write_string(sep_text)
      }
      out.field(cols[j].name, true)
    }
    sb.write_string(term)
  }
  let writers = cols.map(s => csv_cell_writer(out, s.col))
  let nr = df.height()
  for r in 0..<nr {
    for j in 0..<nc {
      if j > 0 {
        sb.write_string(sep_text)
      }
      writers[j](r)
    }
    sb.write_string(term)
  }
  sb.to_string()
}
