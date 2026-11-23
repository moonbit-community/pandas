///|
/// Floor division (rounds toward negative infinity). `b` must not be zero.
fn floor_div64(a : Int64, b : Int64) -> Int64 {
  let q = a / b
  if a % b != 0L && (a < 0L) != (b < 0L) {
    q - 1L
  } else {
    q
  }
}

///|
/// Floor modulo; the result has the sign of `b`. `b` must not be zero.
fn floor_mod64(a : Int64, b : Int64) -> Int64 {
  let r = a % b
  if r != 0L && (r < 0L) != (b < 0L) {
    r + b
  } else {
    r
  }
}

///|
/// Days since 1970-01-01 for a proleptic Gregorian date (Hinnant's algorithm).
fn days_from_civil(y : Int32, m : Int32, d : Int32) -> Int32 {
  let y = if m <= 2 { y - 1 } else { y }
  let era = (if y >= 0 { y } else { y - 399 }) / 400
  let yoe = y - era * 400
  let mp = if m > 2 { m - 3 } else { m + 9 }
  let doy = (153 * mp + 2) / 5 + d - 1
  let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
  era * 146097 + doe - 719468
}

///|
/// Inverse of `days_from_civil`: returns `(year, month, day)`.
fn civil_from_days(days : Int32) -> (Int32, Int32, Int32) {
  let z = days + 719468
  let era = (if z >= 0 { z } else { z - 146096 }) / 146097
  let doe = z - era * 146097
  let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  let y = yoe + era * 400
  let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  let mp = (5 * doy + 2) / 153
  let d = doy - (153 * mp + 2) / 5 + 1
  let m = if mp < 10 { mp + 3 } else { mp - 9 }
  (if m <= 2 { y + 1 } else { y }, m, d)
}

///|
fn pad_digits(n : Int32, width : Int32) -> String {
  n.to_string().pad_start(width, '0')
}

///|
/// Formats days since the epoch as `YYYY-MM-DD`. Years are zero-padded to
/// four digits; negative years get a leading `-`.
fn format_date(days : Int32) -> String {
  let (y, m, d) = civil_from_days(days)
  let ys = if y < 0 { "-" + pad_digits(-y, 4) } else { pad_digits(y, 4) }
  ys + "-" + pad_digits(m, 2) + "-" + pad_digits(d, 2)
}

///|
fn is_leap_year(y : Int32) -> Bool {
  (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
}

///|
fn days_in_month(y : Int32, m : Int32) -> Int32 {
  match m {
    2 => if is_leap_year(y) { 29 } else { 28 }
    4 | 6 | 9 | 11 => 30
    _ => 31
  }
}

///|
/// Reads `len` ASCII digits starting at `start`; `None` on any non-digit.
fn parse_digits(s : StringView, start : Int32, len : Int32) -> Int32? {
  let mut n = 0
  for i in start..<(start + len) {
    let c = s.at(i).to_int()
    if c < 48 || c > 57 {
      return None
    }
    n = n * 10 + (c - 48)
  }
  Some(n)
}

///|
/// Parses a strict `YYYY-MM-DD` string into days since the epoch. Returns
/// `None` on any other shape or when month/day are out of range.
#warnings("-unused_value")
fn parse_date(s : StringView) -> Int32? {
  if s.length() != 10 || s.at(4).to_int() != 45 || s.at(7).to_int() != 45 {
    return None
  }
  guard parse_digits(s, 0, 4) is Some(y) else { return None }
  guard parse_digits(s, 5, 2) is Some(m) else { return None }
  guard parse_digits(s, 8, 2) is Some(d) else { return None }
  if m < 1 || m > 12 || d < 1 || d > days_in_month(y, m) {
    return None
  }
  Some(days_from_civil(y, m, d))
}
