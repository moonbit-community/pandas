///|
/// The null texts of `null_values`, with the length of the longest (-1 when
/// there are none).
priv struct CsvNulls {
  set : Map[String, Unit]
  max_len : Int32
}

///|
fn CsvNulls::new(values : Array[String]) -> CsvNulls {
  let set : Map[String, Unit] = Map([])
  let mut max_len = -1
  for v in values {
    set[v] = ()
    if v.length() > max_len {
      max_len = v.length()
    }
  }
  { set, max_len, }
}

///|
/// Whether field `i` is null: an empty field that is not quoted, or one whose
/// text is one of the `null_values` (quoted or not).
fn CsvScanner::field_null(self : CsvScanner, i : Int32, ns : CsvNulls) -> Bool {
  let flag = self.fflag[i]
  let a = self.fstart[i]
  let b = self.fend[i]
  if flag == 0 && a == b {
    return true
  }
  if ns.max_len < 0 {
    return false
  }
  if b - a > ns.max_len {
    return false
  }
  ns.set.contains(self.text[a:b].to_owned())
}

///|
/// A quoted field with nothing in it: the empty string.
fn CsvScanner::is_quoted_empty(self : CsvScanner, i : Int32) -> Bool {
  self.fflag[i] != 0 && self.fstart[i] == self.fend[i]
}

// ---------------------------------------------------------------------------
// Inference predicates (the strict ones of polars' CSV reader)

///|
fn csv_is_digit(c : Int32) -> Bool {
  c >= 48 && c <= 57
}

///|
/// The number of ASCII digits of `s` from `i` on, up to `b`.
fn csv_digits(s : String, i : Int32, b : Int32) -> Int32 {
  let mut j = i
  while j < b && csv_is_digit(s.unsafe_get(j).to_int()) {
    j += 1
  }
  j - i
}

///|
/// `-?[0-9]+` over `s[a, b)`.
fn csv_is_int_text(s : String, a : Int32, b : Int32) -> Bool {
  let i = if a < b && s.unsafe_get(a).to_int() == 45 { a + 1 } else { a }
  i < b && csv_digits(s, i, b) == b - i
}

///|
/// Whether the integer text `s[a, b)` (see `csv_is_int_text`) fits `Int64`.
fn csv_int_fits(s : String, a : Int32, b : Int32) -> Bool {
  let digits = if s.unsafe_get(a).to_int() == 45 { b - a - 1 } else { b - a }
  // at most 18 digits always fit
  digits <= 18 || parse_int64_text(s[a:b].to_owned()) is Some(_)
}

///|
/// The exponent `[eE][-+]?[0-9]+` ending exactly at `b`.
fn csv_is_exponent(s : String, j : Int32, b : Int32) -> Bool {
  if j >= b {
    return false
  }
  let e = s.unsafe_get(j).to_int()
  if e != 101 && e != 69 {
    return false
  }
  let mut p = j + 1
  if p < b {
    let c = s.unsafe_get(p).to_int()
    if c == 43 || c == 45 {
      p += 1
    }
  }
  p < b && csv_digits(s, p, b) == b - p
}

///|
/// polars' float shape over `s[a, b)`: an optional sign, then `inf`, `NaN`,
/// `digits.`, `digits[.digits][exponent]` with at least one digit after a point
/// or an exponent (`5` alone is an integer, `1.e5` is not a float).
fn csv_is_float_text(s : String, a : Int32, b : Int32) -> Bool {
  let mut i = a
  if i < b {
    let c = s.unsafe_get(i).to_int()
    if c == 43 || c == 45 {
      i += 1
    }
  }
  if i >= b {
    return false
  }
  let c0 = s.unsafe_get(i).to_int()
  if c0 == 105 || c0 == 78 {
    // `inf`, `NaN`
    return b - i == 3 &&
      (
        (
          c0 == 105 &&
          s.unsafe_get(i + 1).to_int() == 110 &&
          s.unsafe_get(i + 2).to_int() == 102
        ) ||
        (
          c0 == 78 &&
          s.unsafe_get(i + 1).to_int() == 97 &&
          s.unsafe_get(i + 2).to_int() == 78
        )
      )
  }
  let d1 = csv_digits(s, i, b)
  let mut j = i + d1
  if j < b && s.unsafe_get(j).to_int() == 46 {
    j += 1
    let d2 = csv_digits(s, j, b)
    j += d2
    if d2 == 0 {
      // `5.`
      return d1 > 0 && j == b
    }
    return j == b || csv_is_exponent(s, j, b)
  }
  d1 > 0 && csv_is_exponent(s, j, b)
}

///|
/// Case-insensitive `true` / `false` over `s[a, b)`; 1 for true, 0 for false,
/// -1 for anything else.
fn csv_bool_code(s : String, a : Int32, b : Int32) -> Int32 {
  let n = b - a
  if n != 4 && n != 5 {
    return -1
  }
  let word = if n == 4 { "true" } else { "false" }
  for k in 0..<n {
    let c = s.unsafe_get(a + k).to_int()
    let lower = if c >= 65 && c <= 90 { c + 32 } else { c }
    if lower != word.unsafe_get(k).to_int() {
      return -1
    }
  }
  if n == 4 {
    1
  } else {
    0
  }
}

///|
/// Kinds of a value text, for the inference.
let csv_kind_str : Int32 = 0

///|
let csv_kind_int : Int32 = 1

///|
/// An integer text that does not fit `Int64` (polars reads `Int128`, this
/// library has no such type; see `infer_column` for what the column becomes).
let csv_kind_big : Int32 = 2

///|
let csv_kind_float : Int32 = 3

///|
let csv_kind_bool : Int32 = 4

///|
let csv_kind_date : Int32 = 5

///|
let csv_kind_datetime : Int32 = 6

///|
/// The kind of the value text `s[a, b)`. Date and datetime texts are only
/// looked for with `dates`.
fn csv_classify(s : String, a : Int32, b : Int32, dates : Bool) -> Int32 {
  if b <= a {
    return csv_kind_str
  }
  if csv_is_int_text(s, a, b) {
    return if csv_int_fits(s, a, b) { csv_kind_int } else { csv_kind_big }
  }
  if csv_is_float_text(s, a, b) {
    return csv_kind_float
  }
  if csv_bool_code(s, a, b) >= 0 {
    return csv_kind_bool
  }
  if dates {
    let v = s[a:b].to_owned()
    if date_class(v) is Some(_) {
      return csv_kind_date
    }
    // an offset (`Z`, `+01:00`) is a time zone, which this library has not
    if datetime_format(v) is Some(f) && !f.zone {
      return csv_kind_datetime
    }
  }
  csv_kind_str
}

///|
/// The type of column `c` from the first `window` records: the first of
/// Int64, Float64, Boolean, Date, Datetime that reads every value, else String.
/// Nulls do not count, a column of nothing but nulls is String, and a quoted
/// empty string makes the column String. Integer texts beyond `Int64` follow
/// polars where this library has the type: with a float-shaped value (`1.5`,
/// `inf`, `1e3`) and no small integer in the window the column is Float64; with
/// no float-shaped value (polars: `Int128`), or with small integers, big ones
/// and floats all together (polars: String), it is String.
fn CsvScanner::infer_column(
  self : CsvScanner,
  c : Int32,
  window : Int32,
  ns : CsvNulls,
  dates : Bool,
) -> DataType {
  let mut can_int = true
  let mut can_float = true
  let mut can_bool = true
  let mut can_date = dates
  let mut can_dt = dates
  let mut seen = false
  let mut seen_big = false
  let mut seen_small = false
  let mut seen_float = false
  for r in 0..<window {
    let i = self.field_index(r, c)
    if i < 0 || self.field_null(i, ns) {
      continue
    }
    if self.is_quoted_empty(i) {
      return DataType::String
    }
    seen = true
    let kind = if self.fflag[i] == 2 {
      let t = self.field_text(i)
      csv_classify(t, 0, t.length(), dates)
    } else {
      csv_classify(self.text, self.fstart[i], self.fend[i], dates)
    }
    if kind == csv_kind_int {
      seen_small = true
      can_bool = false
      can_date = false
      can_dt = false
    } else if kind == csv_kind_big || kind == csv_kind_float {
      if kind == csv_kind_big {
        seen_big = true
      } else {
        seen_float = true
      }
      can_int = false
      can_bool = false
      can_date = false
      can_dt = false
    } else if kind == csv_kind_bool {
      can_int = false
      can_float = false
      can_date = false
      can_dt = false
    } else if kind == csv_kind_date {
      can_int = false
      can_float = false
      can_bool = false
      can_dt = false
    } else if kind == csv_kind_datetime {
      can_int = false
      can_float = false
      can_bool = false
      can_date = false
    } else {
      return DataType::String
    }
    if !(can_int || can_float || can_bool || can_date || can_dt) {
      return DataType::String
    }
  }
  if !seen {
    DataType::String
  } else if seen_big && (seen_small || !seen_float) {
    // polars: `Int128` (no float in the window) or `String` (small integers,
    // big ones and floats together); this library has no `Int128`
    DataType::String
  } else if can_int {
    DataType::Int64
  } else if can_float {
    DataType::Float64
  } else if can_bool {
    DataType::Boolean
  } else if can_date {
    DataType::Date
  } else if can_dt {
    DataType::Datetime
  } else {
    DataType::String
  }
}

// ---------------------------------------------------------------------------
// Conversion of a column

///|
/// Drops the spaces and tabs before a number (polars' CSV number parser
/// accepts them, `parse_*_text` do not).
fn csv_trim_start(s : String) -> String {
  let n = s.length()
  let mut i = 0
  while i < n {
    let c = s.unsafe_get(i).to_int()
    if c != 32 && c != 9 {
      break
    }
    i += 1
  }
  if i == 0 {
    s
  } else {
    s[i:].to_owned()
  }
}

///|
fn csv_parse_int64(s : String) -> Int64? {
  parse_int64_text(csv_trim_start(s))
}

///|
fn csv_parse_int32(s : String) -> Int32? {
  parse_int32_text(csv_trim_start(s))
}

///|
fn csv_parse_double(s : String) -> Double? {
  parse_double_text(csv_trim_start(s))
}

///|
fn csv_parse_float32(s : String) -> Float? {
  parse_float32_text(csv_trim_start(s))
}

///|
fn csv_parse_bool(s : String) -> Bool? {
  match csv_bool_code(s, 0, s.length()) {
    1 => Some(true)
    0 => Some(false)
    _ => None
  }
}

///|
/// The error of a value of column `c` (named `name`) of record `r` that does
/// not read as `dtype`.
fn CsvScanner::parse_error(
  self : CsvScanner,
  i : Int32,
  r : Int32,
  c : Int32,
  name : String,
  dtype : DataType,
) -> PolarsError {
  self.err_row = r
  let (a, b) = self.raw_range(i)
  ParseError(
    self.could_not_parse(a, b, dtype.to_string(), name, c) +
    " at line \{self.rec_line[r]}",
  )
}

///|
/// Reads the first `nrows` values of column `c` with `parse` into `builder`.
/// A null (see `field_null`), a missing field and a quoted empty string are
/// null; any other text that `parse` refuses is an error.
fn[T] CsvScanner::fill(
  self : CsvScanner,
  c : Int32,
  nrows : Int32,
  ns : CsvNulls,
  name : String,
  dtype : DataType,
  blank_null : Bool,
  parse : (String) -> T?,
  builder : @arrow.PrimBuilder[T],
) -> Unit raise PolarsError {
  for r in 0..<nrows {
    let i = self.field_index(r, c)
    if i < 0 || self.field_null(i, ns) || self.is_quoted_empty(i) {
      builder.push_null()
      continue
    }
    if blank_null && self.is_blank_text(i) {
      builder.push_null()
      continue
    }
    match parse(self.field_text(i)) {
      Some(v) => builder.push(v)
      None => raise self.parse_error(i, r, c, name, dtype)
    }
  }
}

///|
/// Builds column `c` as `dtype` from the first `nrows` records.
fn CsvScanner::build_column(
  self : CsvScanner,
  c : Int32,
  nrows : Int32,
  ns : CsvNulls,
  name : String,
  dtype : DataType,
) -> Series raise PolarsError {
  match dtype {
    Int64 => {
      let b : @arrow.PrimBuilder[Int64] = @arrow.PrimBuilder::new(
        capacity=nrows,
      )
      self.fill(c, nrows, ns, name, dtype, true, csv_parse_int64, b)
      Series::make(name, Column::Int64(b.finish()))
    }
    Int32 => {
      let b : @arrow.PrimBuilder[Int32] = @arrow.PrimBuilder::new(
        capacity=nrows,
      )
      self.fill(c, nrows, ns, name, dtype, true, csv_parse_int32, b)
      Series::make(name, Column::Int32(b.finish()))
    }
    Float64 => {
      let b : @arrow.PrimBuilder[Double] = @arrow.PrimBuilder::new(
        capacity=nrows,
      )
      self.fill(c, nrows, ns, name, dtype, true, csv_parse_double, b)
      Series::make(name, Column::Float64(b.finish()))
    }
    Float32 => {
      let b : @arrow.PrimBuilder[Float] = @arrow.PrimBuilder::new(
        capacity=nrows,
      )
      self.fill(c, nrows, ns, name, dtype, true, csv_parse_float32, b)
      Series::make(name, Column::Float32(b.finish()))
    }
    Boolean => {
      let b = @arrow.BoolBuilder::new(capacity=nrows)
      for r in 0..<nrows {
        let i = self.field_index(r, c)
        if i < 0 || self.field_null(i, ns) || self.is_quoted_empty(i) {
          b.push_null()
          continue
        }
        match csv_parse_bool(self.field_text(i)) {
          Some(v) => b.push(v)
          None => raise self.parse_error(i, r, c, name, dtype)
        }
      }
      Series::make(name, Column::Boolean(b.finish()))
    }
    String => {
      let b = @arrow.StrBuilder::new(capacity=nrows)
      for r in 0..<nrows {
        let i = self.field_index(r, c)
        if i < 0 || self.field_null(i, ns) {
          b.push_null()
        } else {
          b.push(self.field_text(i))
        }
      }
      Series::make(name, Column::String(b.finish()))
    }
    Date => {
      // the first value decides the day-first or year-first reading
      let mut cls : DpClass? = None
      let parse = fn(s : String) -> Int32? {
        if cls is None {
          cls = date_class(s)
        }
        match cls {
          Some(k) => dp_read_date(s, k)
          None => None
        }
      }
      let b : @arrow.PrimBuilder[Int32] = @arrow.PrimBuilder::new(
        capacity=nrows,
      )
      self.fill(c, nrows, ns, name, dtype, false, parse, b)
      Series::make(name, Column::Date(b.finish()))
    }
    Datetime => {
      // the first text that has a datetime format decides the format
      let mut fmt : DtFormat? = None
      let parse = fn(s : String) -> Int64? {
        match fmt {
          Some(f) => dt_read(s, f)
          None =>
            match datetime_format(s) {
              Some(f) if !f.zone => {
                fmt = Some(f)
                dt_read(s, f)
              }
              _ => None
            }
        }
      }
      let b : @arrow.PrimBuilder[Int64] = @arrow.PrimBuilder::new(
        capacity=nrows,
      )
      self.fill(c, nrows, ns, name, dtype, false, parse, b)
      Series::make(name, Column::Datetime(b.finish()))
    }
    Null =>
      raise ComputeError(
        "unsupported data type when reading CSV: null when reading CSV",
      )
  }
}

///|
/// Whether field `i` is not empty and has nothing but spaces and tabs (a number
/// column reads such a field as null).
fn CsvScanner::is_blank_text(self : CsvScanner, i : Int32) -> Bool {
  let a = self.fstart[i]
  let b = self.fend[i]
  if a >= b {
    return false
  }
  for p in a..<b {
    let c = self.unit(p)
    if c != 32 && c != 9 {
      return false
    }
  }
  true
}
