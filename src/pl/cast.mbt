// Series::cast and the package-private text conversions behind it.
//
// Semantics follow polars 2.1.0 (see docs/golden/cast.json):
// - the same type is returned as is;
// - pairs polars rejects even with `strict=False` raise `InvalidOperation`;
// - a non-null value that cannot be converted becomes null with
//   `strict=false` and raises `ComputeError` (first bad value and index)
//   with `strict=true`;
// - nulls stay null.

///|
/// Microseconds per day.
let micros_per_day : Int64 = 86_400_000_000L

///|
/// Dates farther than this many days from 1970-01-01 are not formatted: that
/// is beyond every `Int64` microsecond timestamp (about +-106.8 million days)
/// and keeps the calendar arithmetic inside `Int32`. polars panics there.
let max_format_days : Int32 = 110_000_000

///|
/// Splits the shortest round-trip rendering of a finite non-zero float
/// (`to_string` output: `123.45`, `0.00001`, `1.5e-7`, `1e+21`) into its
/// decimal digits without leading or trailing zeros and the decimal exponent
/// `e` of the first digit (`value = d.ddd * 10^e`).
fn float_digits(text : String) -> (String, Int32) {
  let body = if text.has_prefix("-") { text[1:].to_owned() } else { text }
  let mut mantissa = body
  let mut exp10 = 0
  match body.find("e") {
    Some(k) => {
      mantissa = body[:k].to_owned()
      let es = body[k + 1:].to_owned()
      let es = if es.has_prefix("+") { es[1:].to_owned() } else { es }
      exp10 = @string.parse_int(es) catch { _ => 0 }
    }
    None => ()
  }
  let (int_part, frac_part) = match mantissa.find(".") {
    Some(k) => (mantissa[:k].to_owned(), mantissa[k + 1:].to_owned())
    None => (mantissa, "")
  }
  let all = int_part + frac_part
  // position of the decimal point relative to the first stored digit
  let mut point = int_part.length() + exp10
  let mut start = 0
  while start < all.length() - 1 && all[start] == '0' {
    start += 1
    point -= 1
  }
  let mut stop = all.length()
  while stop > start + 1 && all[stop - 1] == '0' {
    stop -= 1
  }
  (all[start:stop].to_owned(), point - 1)
}

///|
/// polars' text form of a float. `shortest` is the shortest round-trip
/// rendering of the value, `lo` / `hi` bound the decimal exponents printed in
/// positional notation (`1e-5 <= |x| < 1e16` for `f64`, `1e-6 <= |x| < 1e13`
/// for `f32`); outside them the form is `d.ddde+x`.
fn format_float_text(
  x_is_neg : Bool,
  shortest : String,
  lo : Int32,
  hi : Int32,
) -> String {
  let (digits, e) = float_digits(shortest)
  let sign = if x_is_neg { "-" } else { "" }
  let nd = digits.length()
  if e < lo || e >= hi {
    let rest = if nd > 1 { "." + digits[1:].to_owned() } else { "" }
    let es = if e < 0 { "-" + (-e).to_string() } else { "+" + e.to_string() }
    return sign + digits[:1].to_owned() + rest + "e" + es
  }
  if e >= 0 {
    let int_len = e + 1
    if nd <= int_len {
      sign + digits + "0".repeat(int_len - nd) + ".0"
    } else {
      sign + digits[:int_len].to_owned() + "." + digits[int_len:].to_owned()
    }
  } else {
    sign + "0." + "0".repeat(-e - 1) + digits
  }
}

///|
/// polars' text form of an `f64`: `0.0`, `-0.0`, `1e-6`, `1.5e+16`, `NaN`,
/// `inf`, `-inf`.
fn format_f64(x : Double) -> String {
  if x.is_nan() {
    "NaN"
  } else if x.is_pos_inf() {
    "inf"
  } else if x.is_neg_inf() {
    "-inf"
  } else if x == 0.0 {
    if x.reinterpret_as_int64() < 0L {
      "-0.0"
    } else {
      "0.0"
    }
  } else {
    format_float_text(x < 0.0, x.to_string(), -5, 16)
  }
}

///|
/// polars' text form of an `f32` (shortest digits of the `f32`, positional
/// notation for `1e-6 <= |x| < 1e13`).
fn format_f32(x : Float) -> String {
  if x.is_nan() {
    "NaN"
  } else if x.is_pos_inf() {
    "inf"
  } else if x.is_neg_inf() {
    "-inf"
  } else if x == 0.0 {
    if x.reinterpret_as_int() < 0 {
      "-0.0"
    } else {
      "0.0"
    }
  } else {
    format_float_text(x < 0.0, x.to_string(), -6, 13)
  }
}

///|
/// `YYYY-MM-DD` as polars prints it: years above 9999 get a leading `+`,
/// negative years a leading `-` (four digits at least). `None` when `days` is
/// farther than `max_format_days` from the epoch.
fn format_date_checked(days : Int32) -> String? {
  if days > max_format_days || days < -max_format_days {
    return None
  }
  let s = format_date(days)
  Some(if !s.has_prefix("-") && s.length() > 10 { "+" + s } else { s })
}

///|
/// `YYYY-MM-DD HH:MM:SS.ffffff` for microseconds since the epoch (floor
/// division, so -1 is 1969-12-31 23:59:59.999999). Every `Int64` value is in
/// range.
fn format_datetime(us : Int64) -> String {
  let days = floor_div64(us, micros_per_day).to_int()
  let rem = floor_mod64(us, micros_per_day)
  let secs = (rem / 1_000_000L).to_int()
  let micro = (rem % 1_000_000L).to_int()
  let date = match format_date_checked(days) {
    Some(d) => d
    None => abort("format_datetime: day \{days} out of range")
  }
  date +
  " " +
  pad_digits(secs / 3600, 2) +
  ":" +
  pad_digits(secs / 60 % 60, 2) +
  ":" +
  pad_digits(secs % 60, 2) +
  "." +
  pad_digits(micro, 6)
}

///|
/// Parses an optionally signed run of ASCII digits (no spaces, no
/// underscores); `None` on any other shape or on `Int64` overflow.
fn parse_int64_text(s : String) -> Int64? {
  let n = s.length()
  let mut i = 0
  let mut neg = false
  if n > 0 && (s[0] == '-' || s[0] == '+') {
    neg = s[0] == '-'
    i = 1
  }
  if i >= n {
    return None
  }
  // accumulate negatively so that Int64's minimum is representable
  let mut acc = 0L
  while i < n {
    let c = s[i].to_int()
    if c < 48 || c > 57 {
      return None
    }
    if acc < @int64.MIN_VALUE / 10L {
      return None
    }
    let m = acc * 10L
    let d = (c - 48).to_int64()
    if m < @int64.MIN_VALUE + d {
      return None
    }
    acc = m - d
    i += 1
  }
  if neg {
    Some(acc)
  } else if acc == @int64.MIN_VALUE {
    None
  } else {
    Some(-acc)
  }
}

///|
/// Parses a decimal float: optional sign, digits with an optional fraction
/// (`5.`, `.5`), optional exponent; or `inf` / `infinity` / `nan` in any
/// letter case. Overflow gives infinity. `None` on any other shape (spaces,
/// underscores, hex, a bare exponent).
fn parse_double_text(s : String) -> Double? {
  let n = s.length()
  let mut i = 0
  let mut neg = false
  if n > 0 && (s[0] == '-' || s[0] == '+') {
    neg = s[0] == '-'
    i = 1
  }
  if i >= n {
    return None
  }
  let rest = s[i:].to_owned().to_lower()
  if rest == "inf" || rest == "infinity" {
    return Some(if neg { -1.0 / 0.0 } else { 1.0 / 0.0 })
  }
  if rest == "nan" {
    return Some(0.0 / 0.0)
  }
  let int_start = i
  while i < n && s[i] >= '0' && s[i] <= '9' {
    i += 1
  }
  let int_part = s[int_start:i].to_owned()
  let mut frac_part = ""
  if i < n && s[i] == '.' {
    i += 1
    let frac_start = i
    while i < n && s[i] >= '0' && s[i] <= '9' {
      i += 1
    }
    frac_part = s[frac_start:i].to_owned()
  }
  if int_part.length() + frac_part.length() == 0 {
    return None
  }
  let mut exp_part = ""
  if i < n && (s[i] == 'e' || s[i] == 'E') {
    i += 1
    let exp_start = i
    if i < n && (s[i] == '-' || s[i] == '+') {
      i += 1
    }
    let digits_start = i
    while i < n && s[i] >= '0' && s[i] <= '9' {
      i += 1
    }
    if i == digits_start {
      return None
    }
    exp_part = "e" + s[exp_start:i].to_owned()
  }
  if i != n {
    return None
  }
  let normalized = (if int_part.is_empty() { "0" } else { int_part }) +
    "." +
    (if frac_part.is_empty() { "0" } else { frac_part }) +
    exp_part
  // `parse_double` raises when the value is out of the `Double` range; the
  // exponent's sign then says which way it went (infinity or zero).
  let v = @string.parse_double(normalized) catch {
    _ => if exp_part.has_prefix("e-") { 0.0 } else { 1.0 / 0.0 }
  }
  Some(if neg { -v } else { v })
}

///|
/// Truncates towards zero; `None` when the result does not fit `Int32`
/// (NaN and the infinities included).
fn double_to_int32(x : Double) -> Int32? {
  if x > -2147483649.0 && x < 2147483648.0 {
    Some(x.to_int())
  } else {
    None
  }
}

///|
/// Truncates towards zero; `None` when the result does not fit `Int64`
/// (NaN and the infinities included).
fn double_to_int64(x : Double) -> Int64? {
  if x >= -9223372036854775808.0 && x < 9223372036854775808.0 {
    Some(x.to_int64())
  } else {
    None
  }
}

///|
fn int64_to_int32(v : Int64) -> Int32? {
  if v >= @int.MIN_VALUE.to_int64() && v <= @int.MAX_VALUE.to_int64() {
    Some(v.to_int())
  } else {
    None
  }
}

///|
/// Days to microseconds; `None` when it overflows `Int64`.
fn days_to_micros(days : Int32) -> Int64? {
  let d = days.to_int64()
  let limit = @int64.MAX_VALUE / micros_per_day
  if d > limit || d < -limit {
    None
  } else {
    Some(d * micros_per_day)
  }
}

///|
/// Converts one non-null value to the target type; `None` when the value
/// cannot be converted. The (source, target) pair must already have been
/// checked with `cast_supported`.
fn convert_value(v : AnyValue, to : DataType) -> AnyValue? {
  match to {
    Null => None
    Boolean =>
      match v {
        Boolean(_) => Some(v)
        Int32(x) => Some(Boolean(x != 0))
        Int64(x) => Some(Boolean(x != 0L))
        Float32(x) => Some(Boolean(x != 0.0))
        Float64(x) => Some(Boolean(x != 0.0))
        _ => None
      }
    Int32 =>
      match v {
        Boolean(b) => Some(Int32(if b { 1 } else { 0 }))
        Int32(_) => Some(v)
        Int64(x) => int64_to_int32(x).map(r => AnyValue::Int32(r))
        Float32(x) =>
          double_to_int32(x.to_double()).map(r => AnyValue::Int32(r))
        Float64(x) => double_to_int32(x).map(r => AnyValue::Int32(r))
        String(s) =>
          match parse_int64_text(s) {
            Some(x) => int64_to_int32(x).map(r => AnyValue::Int32(r))
            None => None
          }
        Date(d) => Some(Int32(d))
        Datetime(t) => int64_to_int32(t).map(r => AnyValue::Int32(r))
        Null => None
      }
    Int64 =>
      match v {
        Boolean(b) => Some(Int64(if b { 1L } else { 0L }))
        Int32(x) => Some(Int64(x.to_int64()))
        Int64(_) => Some(v)
        Float32(x) =>
          double_to_int64(x.to_double()).map(r => AnyValue::Int64(r))
        Float64(x) => double_to_int64(x).map(r => AnyValue::Int64(r))
        String(s) => parse_int64_text(s).map(r => AnyValue::Int64(r))
        Date(d) => Some(Int64(d.to_int64()))
        Datetime(t) => Some(Int64(t))
        Null => None
      }
    Float32 =>
      match v {
        Boolean(b) => Some(Float32(if b { 1.0 } else { 0.0 }))
        Int32(x) => Some(Float32(Float::from_int(x)))
        Int64(x) => Some(Float32(Float::from_int64(x)))
        Float32(_) => Some(v)
        Float64(x) => Some(Float32(Float::from_double(x)))
        String(s) =>
          parse_double_text(s).map(x => AnyValue::Float32(Float::from_double(x)))
        Date(d) => Some(Float32(Float::from_int(d)))
        Datetime(t) => Some(Float32(Float::from_int64(t)))
        Null => None
      }
    Float64 =>
      match v {
        Boolean(b) => Some(Float64(if b { 1.0 } else { 0.0 }))
        Int32(x) => Some(Float64(x.to_double()))
        Int64(x) => Some(Float64(x.to_double()))
        Float32(x) => Some(Float64(x.to_double()))
        Float64(_) => Some(v)
        String(s) => parse_double_text(s).map(r => AnyValue::Float64(r))
        Date(d) => Some(Float64(d.to_double()))
        Datetime(t) => Some(Float64(t.to_double()))
        Null => None
      }
    String =>
      match v {
        Boolean(b) => Some(String(if b { "true" } else { "false" }))
        Int32(x) => Some(String(x.to_string()))
        Int64(x) => Some(String(x.to_string()))
        Float32(x) => Some(String(format_f32(x)))
        Float64(x) => Some(String(format_f64(x)))
        String(_) => Some(v)
        Date(d) => format_date_checked(d).map(r => AnyValue::String(r))
        Datetime(t) => Some(String(format_datetime(t)))
        Null => None
      }
    Date =>
      match v {
        Boolean(b) => Some(Date(if b { 1 } else { 0 }))
        Int32(x) => Some(Date(x))
        Int64(x) => int64_to_int32(x).map(r => AnyValue::Date(r))
        Float32(x) => double_to_int32(x.to_double()).map(r => AnyValue::Date(r))
        Float64(x) => double_to_int32(x).map(r => AnyValue::Date(r))
        Date(_) => Some(v)
        Datetime(t) => Some(Date(floor_div64(t, micros_per_day).to_int()))
        _ => None
      }
    Datetime =>
      match v {
        Boolean(b) => Some(Datetime(if b { 1L } else { 0L }))
        Int32(x) => Some(Datetime(x.to_int64()))
        Int64(x) => Some(Datetime(x))
        Float32(x) =>
          double_to_int64(x.to_double()).map(r => AnyValue::Datetime(r))
        Float64(x) => double_to_int64(x).map(r => AnyValue::Datetime(r))
        Date(d) => days_to_micros(d).map(r => AnyValue::Datetime(r))
        Datetime(_) => Some(v)
        _ => None
      }
  }
}

///|
/// Whether polars can cast `from` to `to` at all (even with `strict=False`).
fn cast_supported(from : DataType, to : DataType) -> Bool {
  if from == to || from == Null {
    return true
  }
  match (from, to) {
    (String, Boolean) | (String, Date) | (String, Datetime) => false
    (Date, Boolean) | (Date, Null) => false
    (Datetime, Boolean) | (Datetime, Null) => false
    _ => true
  }
}

///|
/// Short rendering of a value for error messages.
fn describe_value(v : AnyValue) -> String {
  match v {
    Null => "null"
    Boolean(b) => b.to_string()
    Int32(x) => x.to_string()
    Int64(x) => x.to_string()
    Float32(x) => format_f32(x)
    Float64(x) => format_f64(x)
    String(s) => "\"" + s + "\""
    Date(d) => "date(\{d})"
    Datetime(t) => "datetime(\{t})"
  }
}

///|
/// Converts the series to the type `to`.
///
/// - Casting to the series' own type returns the series unchanged.
/// - Numeric casts truncate floats towards zero; `bool` is `value != 0`
///   (NaN is true); `Date` is days and `Datetime` microseconds since the
///   epoch, so `Int32 -> Datetime` reads the integer as microseconds and
///   `Datetime -> Date` rounds down (`-1` microsecond is 1969-12-31).
/// - Floats print like polars: `0.0`, `-0.0`, `1e-6`, `1.5e+16`, `NaN`,
///   `inf`; dates print as `YYYY-MM-DD`, datetimes as
///   `YYYY-MM-DD HH:MM:SS.ffffff`.
/// - Strings parse to integers (optional sign, digits only) and floats
///   (decimal or exponent form, `inf`, `nan`); they cannot be cast to
///   `Boolean`, `Date` or `Datetime`.
/// - Nulls stay null. A `Null` series casts to every type; casting to `Null`
///   only works for null values.
///
/// A non-null value that does not fit the target (an out-of-range number, an
/// unparsable string, a date beyond +-110 million days) becomes null with
/// `strict=false`.
///
/// # Errors
/// - `InvalidOperation` when the type pair is unsupported (`str` to `bool`,
///   `date` or `datetime`; `date` or `datetime` to `bool` or `null`), in both
///   modes.
/// - `ComputeError` with `strict=true` (default) naming the first value that
///   cannot be converted and its index.
pub fn Series::cast(
  self : Series,
  to : DataType,
  strict~ : Bool = true,
) -> Series raise PolarsError {
  let from = self.dtype()
  if from == to {
    return self
  }
  if !cast_supported(from, to) {
    raise InvalidOperation("cannot cast \{from} to \{to}")
  }
  let n = self.len()
  let out : Array[AnyValue] = Array(capacity=n)
  for i in 0..<n {
    let v = self.col.get(i)
    if v.is_null() {
      out.push(AnyValue::Null)
      continue
    }
    match convert_value(v, to) {
      Some(r) => out.push(r)
      None =>
        if strict {
          raise ComputeError(
            "column \"\{self.name}\": cannot cast \{from} to \{to}: value \{describe_value(v)} at index \{i} cannot be converted (use strict=false to turn it into null)",
          )
        } else {
          out.push(AnyValue::Null)
        }
    }
  }
  Series::from_any_values(self.name, out, dtype=to)
}
