// Series::cast and the package-private text conversions behind it.
//
// Semantics follow polars 2.1.0 (see docs/golden/cast.json):
// - the same type is returned as is;
// - pairs polars rejects even with `strict=False` raise `InvalidOperation`
//   with polars' message, unless the series is empty or all null (that casts
//   to every type);
// - a non-null value that cannot be converted becomes null with
//   `strict=false` and raises `InvalidOperation` with polars' message
//   (`conversion from `str` to `i64` failed in column 'a' for 3 out of 4
//   values: [...]`) with `strict=true`;
// - nulls stay null.
//
// The conversion loops run directly over the typed arrays (no `AnyValue` per
// element); a value only becomes an `AnyValue` when it fails and has to be
// reported.

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
      // The text is `to_string` output of this library's own floats, so the
      // exponent always parses; anything else is a broken invariant.
      exp10 = @string.parse_int(es) catch {
        _ => abort("float_digits: cannot parse the exponent of \{text}")
      }
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
/// The syntactic shape of a float text. The parts are views into the text.
priv enum FloatText {
  /// `inf`, `infinity` (signed) or `nan`.
  Special(Double)
  /// Sign, integer digits, fraction digits and the exponent text (empty, or
  /// `e-5`, `e+5`, `e5`, `E5`); at least one digit in the integer or fraction
  /// part.
  Decimal(Bool, StringView, StringView, StringView)
}

///|
/// Scans a decimal float: optional sign, digits with an optional fraction
/// (`5.`, `.5`), optional exponent; or `inf` / `infinity` / `nan` in any
/// letter case. `None` on any other shape (spaces, underscores, hex, a bare
/// exponent).
fn scan_float_text(s : String) -> FloatText? {
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
  // only a text that starts with a letter can be `inf`, `infinity` or `nan`
  if s[i] != '.' && (s[i] < '0' || s[i] > '9') {
    let rest = s[i:].to_owned().to_lower()
    if rest == "inf" || rest == "infinity" {
      return Some(Special(if neg { -1.0 / 0.0 } else { 1.0 / 0.0 }))
    }
    if rest == "nan" {
      return Some(Special(0.0 / 0.0))
    }
    return None
  }
  let int_start = i
  while i < n && s[i] >= '0' && s[i] <= '9' {
    i += 1
  }
  let int_part = s[int_start:i]
  let mut frac_part = s[0:0]
  if i < n && s[i] == '.' {
    i += 1
    let frac_start = i
    while i < n && s[i] >= '0' && s[i] <= '9' {
      i += 1
    }
    frac_part = s[frac_start:i]
  }
  if int_part.length() + frac_part.length() == 0 {
    return None
  }
  let mut exp_part = s[0:0]
  if i < n && (s[i] == 'e' || s[i] == 'E') {
    let exp_start = i
    i += 1
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
    exp_part = s[exp_start:i]
  }
  if i != n {
    return None
  }
  Some(Decimal(neg, int_part, frac_part, exp_part))
}

///|
/// The value of a decimal text that `parse_double` rejects, which happens
/// when it is outside the `Double` range: infinity when it is at least 1 (a
/// long mantissa can overflow whatever the sign of the exponent is), zero
/// otherwise. `neg` is not applied.
fn out_of_range_double(
  int_part : StringView,
  frac_part : StringView,
  exp_part : StringView,
) -> Double {
  let exp = if exp_part.is_empty() { 0 } else { saturated_exponent(exp_part) }
  // the value is 0.DIGITS * 10^point, DIGITS starting at the first non-zero
  // digit
  let mut k = 0
  while k < int_part.length() && int_part[k] == '0' {
    k += 1
  }
  if k < int_part.length() {
    return if int_part.length() - k + exp > 0 { 1.0 / 0.0 } else { 0.0 }
  }
  k = 0
  while k < frac_part.length() && frac_part[k] == '0' {
    k += 1
  }
  if k < frac_part.length() && exp - k > 0 {
    1.0 / 0.0
  } else {
    0.0
  }
}

///|
/// Parses a float text (see `scan_float_text`) to the nearest `Double`.
/// Overflow gives infinity. `None` on any other shape.
fn parse_double_text(s : String) -> Double? {
  match scan_float_text(s) {
    None => None
    Some(Special(v)) => Some(v)
    Some(Decimal(neg, int_part, frac_part, exp_part)) =>
      // the shape is valid, so `parse_double` (which handles the sign, `5.`
      // and `.5`) raises only when the value is out of the `Double` range
      Some(
        @string.parse_double(s) catch {
          _ => {
            let v = out_of_range_double(int_part, frac_part, exp_part)
            if neg {
              -v
            } else {
              v
            }
          }
        },
      )
  }
}

///|
/// 2^128, the first value past `f32::MAX`.
let two_pow_128 : Double = 4294967296.0 *
  4294967296.0 *
  4294967296.0 *
  4294967296.0

///|
/// Bit pattern of positive infinity as a `Float`.
let f32_inf_bits : UInt32 = 0x7F800000U

///|
/// The value of a non-negative `Float` bit pattern as a `Double`; infinity
/// (`0x7F800000`) stands for 2^128, the edge the rounding rule uses.
fn f32_edge(bits : UInt32) -> Double {
  if bits >= f32_inf_bits {
    two_pow_128
  } else {
    Float::reinterpret_from_uint(bits).to_double()
  }
}

///|
/// The exponent of a float text as an `Int32`, saturated at +-100 million
/// (anything that large is far outside every float's range anyway).
fn saturated_exponent(exp_part : StringView) -> Int32 {
  let cap = 100_000_000
  let mut i = 1 // skip the `e`
  let mut neg = false
  if i < exp_part.length() && (exp_part[i] == '-' || exp_part[i] == '+') {
    neg = exp_part[i] == '-'
    i += 1
  }
  let mut acc = 0
  while i < exp_part.length() {
    acc = acc * 10 + (exp_part[i].to_int() - 48)
    if acc > cap {
      acc = cap
    }
    i += 1
  }
  if neg {
    -acc
  } else {
    acc
  }
}

///|
/// Compares the decimal `0.DIGITS * 10^point` (`digits` has no leading or
/// trailing zero) with the positive double `m`, both exactly: negative, zero
/// or positive as the decimal is smaller than, equal to or larger than `m`.
fn compare_decimal_double(digits : String, point : Int32, m : Double) -> Int32 {
  let (md, mp) = exact_decimal(m)
  if point != mp {
    return if point < mp { -1 } else { 1 }
  }
  let n = if digits.length() < md.length() {
    digits.length()
  } else {
    md.length()
  }
  for i in 0..<n {
    let d = digits[i].to_int() - 48
    if d != md[i] {
      return if d < md[i] { -1 } else { 1 }
    }
  }
  if digits.length() == md.length() {
    0
  } else if digits.length() < md.length() {
    -1
  } else {
    1
  }
}

///|
/// Bit pattern of the `Float` nearest to the exact positive decimal
/// `0.DIGITS * 10^point` (`digits` has no leading or trailing zero and
/// `-46 <= point <= 40`), ties to even; `x` is the nearest `Double` to it.
///
/// Rounding `x` to `Float` is right except when `x` itself is the exact
/// midpoint of two adjacent `Float` values (a midpoint is a `Double`, so no
/// other value of the decimal can lie on the far side of one): then the exact
/// decimal decides, which is what a direct decimal-to-`Float` parse (Rust's
/// `f32::from_str`) does.
fn round_decimal_to_f32_bits(
  digits : String,
  point : Int32,
  x : Double,
) -> UInt32 {
  if x >= two_pow_128 {
    return f32_inf_bits
  }
  let f = Float::from_double(x)
  let bits = f.reinterpret_as_uint()
  let g = f32_edge(bits)
  if g == x {
    return bits
  }
  let (lower, mid) = if g < x {
    (bits, (g + f32_edge(bits + 1U)) / 2.0)
  } else {
    (bits - 1U, (f32_edge(bits - 1U) + g) / 2.0)
  }
  if x != mid {
    return bits
  }
  let c = compare_decimal_double(digits, point, mid)
  if c < 0 || (c == 0 && lower % 2U == 0U) {
    lower
  } else {
    lower + 1U
  }
}

///|
/// Parses a float text to the `Float` nearest to its exact value (ties to
/// even), like Rust's `f32::from_str`: no double rounding through `Double`,
/// and only a value at or above 2^128 - 2^103 (`f32::MAX` plus half an ulp)
/// overflows to infinity. `None` on any other shape.
fn parse_float32_text(s : String) -> Float? {
  match scan_float_text(s) {
    None => None
    Some(Special(v)) => Some(Float::from_double(v))
    Some(Decimal(neg, int_part, frac_part, exp_part)) => {
      let all = int_part.to_owned() + frac_part.to_owned()
      let mut start = 0
      while start < all.length() && all[start] == '0' {
        start += 1
      }
      let mut stop = all.length()
      while stop > start && all[stop - 1] == '0' {
        stop -= 1
      }
      let sign = if neg { 0x80000000U } else { 0U }
      let with_sign = bits => Float::reinterpret_from_uint(bits | sign)
      if start == stop {
        return Some(with_sign(0U))
      }
      let digits = all[start:stop].to_owned()
      // value = 0.DIGITS * 10^point
      let point = int_part.length() - start + saturated_exponent(exp_part)
      // 0.1 * 10^41 is above 2^128 and 10^-47 is below half the smallest
      // subnormal (2^-150), whatever the digits are
      if point > 40 {
        return Some(with_sign(f32_inf_bits))
      }
      if point < -46 {
        return Some(with_sign(0U))
      }
      let rest = if digits.length() > 1 { digits[1:].to_owned() } else { "0" }
      let text = digits[:1].to_owned() + "." + rest + "e\{point - 1}"
      let x = @string.parse_double(text) catch {
        _ => abort("parse_float32_text: cannot parse \{text}")
      }
      Some(with_sign(round_decimal_to_f32_bits(digits, point, x)))
    }
  }
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
/// Parses a signed run of ASCII digits to `Int32`; `None` on any other shape
/// or when it does not fit.
fn parse_int32_text(s : String) -> Int32? {
  match parse_int64_text(s) {
    Some(x) => int64_to_int32(x)
    None => None
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
/// The first line of polars 2.1.0's `InvalidOperationError` for a pair
/// `cast_supported` rejects (the messages are polars' own wording, including
/// `Utf8View` and the missing period after `not supported`).
fn unsupported_cast_message(from : DataType, to : DataType) -> String {
  match (from, to) {
    (String, Boolean) => "casting from Utf8View to Boolean not supported"
    (String, Date) => "casting from string to date is not supported."
    (String, Datetime) => "casting from string to datetime is not supported."
    (Date, Boolean) => "casting from Date to Boolean not supported"
    (Date, Null) => "casting from Date to Null not supported"
    (Datetime, Boolean) =>
      "casting from Datetime('\u{3bc}s') to Boolean not supported"
    (Datetime, Null) =>
      "casting from Datetime('\u{3bc}s') to Null not supported"
    _ => abort("unsupported_cast_message: \{from} to \{to} is supported")
  }
}

///|
/// Short rendering of the first failing value for the out-of-range date
/// errors. Only `Date` values reach it (`CastLog::check` raises that error
/// for a `Date` source only), so any other value is a library bug.
fn describe_value(v : AnyValue) -> String {
  match v {
    Date(d) => "date(\{d})"
    _ => abort("describe_value: only Date values are described, got \{v}")
  }
}

///|
/// A failing value as polars lists it in `conversion from ... failed`: the
/// text of a table cell, except that strings are wrapped in double quotes
/// and are neither escaped nor cut (so `a"b` is `"a"b"` and newlines stay).
fn fail_value_text(v : AnyValue) -> String {
  match v {
    String(s) => "\"" + s + "\""
    _ => cell_text(v)
  }
}

///|
/// The failures of one strict conversion.
///
/// polars collects the first ten failing values (the count is complete) and
/// prints the list `[a, b, c]` for up to three of them and `[a, b, … z]`
/// (first two, an ellipsis, the last one collected) for more. Measured on
/// polars 2.1.0: 1..3 failing values `["x0", "x1", "x2"]`; 4 to 10 failing
/// values `["x0", "x1", … "x3"]`; 11 or more failing values still end at the
/// tenth, `["x0", "x1", … "x9"]` (`for 20 out of 20 values`).
priv struct CastLog {
  mut count : Int32
  mut first_index : Int32
  mut first : AnyValue
  shown : Array[AnyValue]
}

///|
fn CastLog::new() -> CastLog {
  { count: 0, first_index: -1, first: AnyValue::Null, shown: [], }
}

///|
/// Records that the value `x` at index `i` could not be converted; `wrap`
/// turns it into an `AnyValue` only for the ten that are kept.
fn[S] CastLog::fail(
  self : CastLog,
  i : Int32,
  x : S,
  wrap : (S) -> AnyValue,
) -> Unit {
  if self.count < 10 {
    let v = wrap(x)
    if self.count == 0 {
      self.first_index = i
      self.first = v
    }
    self.shown.push(v)
  }
  self.count += 1
}

///|
/// polars' bracketed list of the collected failing values.
fn CastLog::list_text(self : CastLog) -> String {
  let parts = self.shown.map(fail_value_text)
  let n = parts.length()
  if n <= 3 {
    "[" + parts.join(", ") + "]"
  } else {
    "[" + parts[0] + ", " + parts[1] + ", \u{2026} " + parts[n - 1] + "]"
  }
}

///|
/// Raises when anything failed (strict mode). Date values beyond what can be
/// formatted or converted are the exception to polars' wording: polars panics
/// there, so they keep a `ComputeError` that names the first value and index.
fn CastLog::check(
  self : CastLog,
  name : String,
  from : DataType,
  to : DataType,
  length : Int32,
) -> Unit raise PolarsError {
  if self.count == 0 {
    return
  }
  if from == DataType::Date &&
    (to == DataType::String || to == DataType::Datetime) {
    raise ComputeError(
      "column \"\{name}\": cannot cast \{from} to \{to}: value \{describe_value(self.first)} at index \{self.first_index} cannot be converted (use strict=false to turn it into null)",
    )
  }
  raise InvalidOperation(
    "conversion from `\{from}` to `\{to}` failed in column '\{name}' for \{self.count} out of \{length} values: \{self.list_text()}",
  )
}

///|
/// Applies the total function `f` to every valid slot (null slots stay null).
fn[S, T : Default] map_prim(
  src : @arrow.PrimArray[S],
  f : (S) -> T,
) -> @arrow.PrimArray[T] {
  let n = src.length()
  let b : @arrow.PrimBuilder[T] = @arrow.PrimBuilder::new(capacity=n)
  for i in 0..<n {
    if src.is_valid(i) {
      b.push(f(src.value(i)))
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
/// Like `map_prim` for a function that can fail: a failing value becomes null
/// and is recorded in `log`.
fn[S, T : Default] try_map_prim(
  src : @arrow.PrimArray[S],
  f : (S) -> T?,
  wrap : (S) -> AnyValue,
  log : CastLog,
) -> @arrow.PrimArray[T] {
  let n = src.length()
  let b : @arrow.PrimBuilder[T] = @arrow.PrimBuilder::new(capacity=n)
  for i in 0..<n {
    if src.is_valid(i) {
      let x = src.value(i)
      match f(x) {
        Some(r) => b.push(r)
        None => {
          log.fail(i, x, wrap)
          b.push_null()
        }
      }
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
fn[T : Default] map_bool(
  src : @arrow.BoolArray,
  f : (Bool) -> T,
) -> @arrow.PrimArray[T] {
  let n = src.length()
  let b : @arrow.PrimBuilder[T] = @arrow.PrimBuilder::new(capacity=n)
  for i in 0..<n {
    if src.is_valid(i) {
      b.push(f(src.value(i)))
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
fn[T : Default] try_map_str(
  src : @arrow.StrArray,
  f : (String) -> T?,
  log : CastLog,
) -> @arrow.PrimArray[T] {
  let n = src.length()
  let b : @arrow.PrimBuilder[T] = @arrow.PrimBuilder::new(capacity=n)
  for i in 0..<n {
    if src.is_valid(i) {
      let x = src.value(i)
      match f(x) {
        Some(r) => b.push(r)
        None => {
          log.fail(i, x, v => AnyValue::String(v))
          b.push_null()
        }
      }
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
fn[S] prim_to_bool(
  src : @arrow.PrimArray[S],
  f : (S) -> Bool,
) -> @arrow.BoolArray {
  let n = src.length()
  let b = @arrow.BoolBuilder::new(capacity=n)
  for i in 0..<n {
    if src.is_valid(i) {
      b.push(f(src.value(i)))
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
fn[S] prim_to_str(
  src : @arrow.PrimArray[S],
  f : (S) -> String,
) -> @arrow.StrArray {
  let n = src.length()
  let b = @arrow.StrBuilder::new(capacity=n)
  for i in 0..<n {
    if src.is_valid(i) {
      b.push(f(src.value(i)))
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
fn[S] try_prim_to_str(
  src : @arrow.PrimArray[S],
  f : (S) -> String?,
  wrap : (S) -> AnyValue,
  log : CastLog,
) -> @arrow.StrArray {
  let n = src.length()
  let b = @arrow.StrBuilder::new(capacity=n)
  for i in 0..<n {
    if src.is_valid(i) {
      let x = src.value(i)
      match f(x) {
        Some(r) => b.push(r)
        None => {
          log.fail(i, x, wrap)
          b.push_null()
        }
      }
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
fn bool_to_str(src : @arrow.BoolArray) -> @arrow.StrArray {
  let n = src.length()
  let b = @arrow.StrBuilder::new(capacity=n)
  for i in 0..<n {
    if src.is_valid(i) {
      b.push(if src.value(i) { "true" } else { "false" })
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
fn[T : Default] null_prim(n : Int32) -> @arrow.PrimArray[T] {
  let b : @arrow.PrimBuilder[T] = @arrow.PrimBuilder::new(capacity=n)
  for _ in 0..<n {
    b.push_null()
  }
  b.finish()
}

///|
/// A column of `n` nulls of type `to`.
fn null_column(to : DataType, n : Int32) -> Column {
  match to {
    Null => Column::Null(n)
    Boolean => {
      let b = @arrow.BoolBuilder::new(capacity=n)
      for _ in 0..<n {
        b.push_null()
      }
      Column::Boolean(b.finish())
    }
    Int32 => Column::Int32(null_prim(n))
    Int64 => Column::Int64(null_prim(n))
    Float32 => Column::Float32(null_prim(n))
    Float64 => Column::Float64(null_prim(n))
    String => {
      let b = @arrow.StrBuilder::new(capacity=n)
      for _ in 0..<n {
        b.push_null()
      }
      Column::String(b.finish())
    }
    Date => Column::Date(null_prim(n))
    Datetime => Column::Datetime(null_prim(n))
  }
}

///|
fn unsupported_source(target : String, col : Column) -> Unit {
  abort("cast to \{target}: unsupported source type \{col.dtype()}")
}

///|
fn cast_to_null(col : Column, log : CastLog) -> Column {
  // every non-null value is a failure
  let n = col.length()
  match col {
    Boolean(a) =>
      for i in 0..<n {
        if a.is_valid(i) {
          log.fail(i, a.value(i), x => AnyValue::Boolean(x))
        }
      }
    Int32(a) =>
      for i in 0..<n {
        if a.is_valid(i) {
          log.fail(i, a.value(i), x => AnyValue::Int32(x))
        }
      }
    Int64(a) =>
      for i in 0..<n {
        if a.is_valid(i) {
          log.fail(i, a.value(i), x => AnyValue::Int64(x))
        }
      }
    Float32(a) =>
      for i in 0..<n {
        if a.is_valid(i) {
          log.fail(i, a.value(i), x => AnyValue::Float32(x))
        }
      }
    Float64(a) =>
      for i in 0..<n {
        if a.is_valid(i) {
          log.fail(i, a.value(i), x => AnyValue::Float64(x))
        }
      }
    String(a) =>
      for i in 0..<n {
        if a.is_valid(i) {
          log.fail(i, a.value(i), x => AnyValue::String(x))
        }
      }
    // polars cannot cast dates to null at all, `cast_supported` stops them
    Date(_) | Datetime(_) => unsupported_source("null", col)
    Null(_) => ()
  }
  Column::Null(n)
}

///|
fn cast_to_bool(col : Column) -> Column {
  match col {
    Int32(a) => Column::Boolean(prim_to_bool(a, x => x != 0))
    Int64(a) => Column::Boolean(prim_to_bool(a, x => x != 0L))
    Float32(a) => Column::Boolean(prim_to_bool(a, x => x != 0.0))
    Float64(a) => Column::Boolean(prim_to_bool(a, x => x != 0.0))
    _ => {
      unsupported_source("bool", col)
      col
    }
  }
}

///|
fn cast_to_int32(col : Column, log : CastLog) -> Column {
  match col {
    Boolean(a) => Column::Int32(map_bool(a, b => if b { 1 } else { 0 }))
    Int64(a) =>
      Column::Int32(
        try_map_prim(a, int64_to_int32, x => AnyValue::Int64(x), log),
      )
    Float32(a) =>
      Column::Int32(
        try_map_prim(
          a,
          x => double_to_int32(x.to_double()),
          x => AnyValue::Float32(x),
          log,
        ),
      )
    Float64(a) =>
      Column::Int32(
        try_map_prim(a, double_to_int32, x => AnyValue::Float64(x), log),
      )
    String(a) => Column::Int32(try_map_str(a, parse_int32_text, log))
    Date(a) => Column::Int32(map_prim(a, d => d))
    Datetime(a) =>
      Column::Int32(
        try_map_prim(a, int64_to_int32, x => AnyValue::Datetime(x), log),
      )
    _ => {
      unsupported_source("i32", col)
      col
    }
  }
}

///|
fn cast_to_int64(col : Column, log : CastLog) -> Column {
  match col {
    Boolean(a) => Column::Int64(map_bool(a, b => if b { 1L } else { 0L }))
    Int32(a) => Column::Int64(map_prim(a, x => x.to_int64()))
    Float32(a) =>
      Column::Int64(
        try_map_prim(
          a,
          x => double_to_int64(x.to_double()),
          x => AnyValue::Float32(x),
          log,
        ),
      )
    Float64(a) =>
      Column::Int64(
        try_map_prim(a, double_to_int64, x => AnyValue::Float64(x), log),
      )
    String(a) => Column::Int64(try_map_str(a, parse_int64_text, log))
    Date(a) => Column::Int64(map_prim(a, d => d.to_int64()))
    Datetime(a) => Column::Int64(map_prim(a, t => t))
    _ => {
      unsupported_source("i64", col)
      col
    }
  }
}

///|
fn cast_to_float32(col : Column, log : CastLog) -> Column {
  match col {
    Boolean(a) => Column::Float32(map_bool(a, b => if b { 1.0 } else { 0.0 }))
    Int32(a) => Column::Float32(map_prim(a, x => Float::from_int(x)))
    Int64(a) => Column::Float32(map_prim(a, x => Float::from_int64(x)))
    Float64(a) => Column::Float32(map_prim(a, x => Float::from_double(x)))
    String(a) => Column::Float32(try_map_str(a, parse_float32_text, log))
    Date(a) => Column::Float32(map_prim(a, d => Float::from_int(d)))
    Datetime(a) => Column::Float32(map_prim(a, t => Float::from_int64(t)))
    _ => {
      unsupported_source("f32", col)
      col
    }
  }
}

///|
fn cast_to_float64(col : Column, log : CastLog) -> Column {
  match col {
    Boolean(a) => Column::Float64(map_bool(a, b => if b { 1.0 } else { 0.0 }))
    Int32(a) => Column::Float64(map_prim(a, x => x.to_double()))
    Int64(a) => Column::Float64(map_prim(a, x => x.to_double()))
    Float32(a) => Column::Float64(map_prim(a, x => x.to_double()))
    String(a) => Column::Float64(try_map_str(a, parse_double_text, log))
    Date(a) => Column::Float64(map_prim(a, d => d.to_double()))
    Datetime(a) => Column::Float64(map_prim(a, t => t.to_double()))
    _ => {
      unsupported_source("f64", col)
      col
    }
  }
}

///|
fn cast_to_str(col : Column, log : CastLog) -> Column {
  match col {
    Boolean(a) => Column::String(bool_to_str(a))
    Int32(a) => Column::String(prim_to_str(a, x => x.to_string()))
    Int64(a) => Column::String(prim_to_str(a, x => x.to_string()))
    Float32(a) => Column::String(prim_to_str(a, format_f32))
    Float64(a) => Column::String(prim_to_str(a, format_f64))
    Date(a) =>
      Column::String(
        try_prim_to_str(a, format_date_checked, x => AnyValue::Date(x), log),
      )
    Datetime(a) => Column::String(prim_to_str(a, format_datetime))
    _ => {
      unsupported_source("str", col)
      col
    }
  }
}

///|
fn cast_to_date(col : Column, log : CastLog) -> Column {
  match col {
    Boolean(a) => Column::Date(map_bool(a, b => if b { 1 } else { 0 }))
    Int32(a) => Column::Date(map_prim(a, x => x))
    Int64(a) =>
      Column::Date(
        try_map_prim(a, int64_to_int32, x => AnyValue::Int64(x), log),
      )
    Float32(a) =>
      Column::Date(
        try_map_prim(
          a,
          x => double_to_int32(x.to_double()),
          x => AnyValue::Float32(x),
          log,
        ),
      )
    Float64(a) =>
      Column::Date(
        try_map_prim(a, double_to_int32, x => AnyValue::Float64(x), log),
      )
    Datetime(a) =>
      Column::Date(map_prim(a, t => floor_div64(t, micros_per_day).to_int()))
    _ => {
      unsupported_source("date", col)
      col
    }
  }
}

///|
fn cast_to_datetime(col : Column, log : CastLog) -> Column {
  match col {
    Boolean(a) => Column::Datetime(map_bool(a, b => if b { 1L } else { 0L }))
    Int32(a) => Column::Datetime(map_prim(a, x => x.to_int64()))
    Int64(a) => Column::Datetime(map_prim(a, x => x))
    Float32(a) =>
      Column::Datetime(
        try_map_prim(
          a,
          x => double_to_int64(x.to_double()),
          x => AnyValue::Float32(x),
          log,
        ),
      )
    Float64(a) =>
      Column::Datetime(
        try_map_prim(a, double_to_int64, x => AnyValue::Float64(x), log),
      )
    Date(a) =>
      Column::Datetime(
        try_map_prim(a, days_to_micros, x => AnyValue::Date(x), log),
      )
    _ => {
      unsupported_source("datetime", col)
      col
    }
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
///   `Boolean`, `Date` or `Datetime`. A string parsed to `Float32` is the
///   `f32` nearest to the exact decimal value (ties to even), not the `f64`
///   rounded again.
/// - Nulls stay null. A `Null`, empty or all-null series casts to every type;
///   casting to `Null` only works for null values.
///
/// A non-null value that does not fit the target (an out-of-range number, an
/// unparsable string, a date beyond +-110 million days) becomes null with
/// `strict=false`.
///
/// # Errors
/// - `InvalidOperation` when the type pair is unsupported (`str` to `bool`,
///   `date` or `datetime`; `date` or `datetime` to `bool` or `null`), in both
///   modes; the message is polars' (`casting from Date to Boolean not
///   supported`). It is only raised when the series has at least one non-null
///   value: an empty or all-null series casts to every type, giving an
///   all-null series of that type with the same name and length.
/// - `InvalidOperation` with `strict=true` (default) when a non-null value
///   cannot be converted, with polars' message `conversion from `str` to
///   `i64` failed in column 'a' for 3 out of 4 values: ["x", "y", "z"]`: the
///   number of failing values, the length, and the first failing values (all
///   up to three, otherwise the first two, an ellipsis and the last of the
///   first ten). This includes casting non-null values to `Null`.
/// - `ComputeError` with `strict=true` for a `Date` that is out of range when
///   cast to `Datetime` (more than 106 751 991 days) or to `String` (more than
///   110 million days); polars panics there. The message names the first such
///   value and its index.
pub fn Series::cast(
  self : Series,
  to : DataType,
  strict~ : Bool = true,
) -> Series raise PolarsError {
  let from = self.dtype()
  if from == to {
    return self
  }
  let n = self.len()
  // polars casts an empty or all-null series to every type, even a pair it
  // rejects for real values (the check only looks at the values)
  if self.null_count() == n {
    return Series::make(self.name, null_column(to, n))
  }
  if !cast_supported(from, to) {
    raise InvalidOperation(unsupported_cast_message(from, to))
  }
  let log = CastLog::new()
  let col = match to {
    Null => cast_to_null(self.col, log)
    Boolean => cast_to_bool(self.col)
    Int32 => cast_to_int32(self.col, log)
    Int64 => cast_to_int64(self.col, log)
    Float32 => cast_to_float32(self.col, log)
    Float64 => cast_to_float64(self.col, log)
    String => cast_to_str(self.col, log)
    Date => cast_to_date(self.col, log)
    Datetime => cast_to_datetime(self.col, log)
  }
  if strict {
    log.check(self.name, from, to, n)
  }
  Series::make(self.name, col)
}
