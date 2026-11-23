// polars-style `Show` for `AnyValue`, `Series` and `DataFrame`.
//
// The layout and the cell text follow polars 2.1.0 under its default
// configuration (see docs/golden/show.json):
// - tables show at most 10 rows (first 5, `…`, last 5) and 8 columns (first
//   4, `…`, last 4); series show at most 10 elements the same way;
// - strings longer than 30 characters are cut to 30 characters plus `…`;
// - floats follow polars' `fmt_float`, which is not the cast-to-string text.
//
// Text widths use an approximation of Unicode East Asian widths (see
// `char_width`); the golden data pins ASCII, CJK, Hangul, fullwidth and
// halfwidth forms, combining and zero-width marks, emoji and U+FE0F sequences.

///|
/// Longest string (in characters) printed before it is cut.
let fmt_str_len : Int32 = 30

///|
/// Widest a table cell line may be (the cut string plus the `…`); longer
/// lines (only possible with wide characters) are wrapped.
let fmt_cell_width : Int32 = 31

///|
/// Row count above which tables and series are folded.
let fmt_max_rows : Int32 = 10

///|
/// Column count above which tables are folded.
let fmt_max_cols : Int32 = 8

///|
/// Text for a date outside the range polars can print (it panics there).
let fmt_bad_date : String = "<out-of-range date>"

// ---------------------------------------------------------------------------
// Floats
// ---------------------------------------------------------------------------

///|
/// Multiplies a little-endian base-10^9 number by `m` (`m` < 2^31).
fn big_mul_small(limbs : Array[Int64], m : Int64) -> Unit {
  let base = 1_000_000_000L
  let mut carry = 0L
  for i in 0..<limbs.length() {
    let v = limbs[i] * m + carry
    limbs[i] = v % base
    carry = v / base
  }
  while carry > 0L {
    limbs.push(carry % base)
    carry = carry / base
  }
}

///|
/// Decimal text of a little-endian base-10^9 number.
fn big_to_digits(limbs : Array[Int64]) -> String {
  let sb = StringBuilder()
  let mut i = limbs.length() - 1
  while i > 0 && limbs[i] == 0L {
    i -= 1
  }
  sb.write_string(limbs[i].to_string())
  i -= 1
  while i >= 0 {
    sb.write_string(limbs[i].to_string().pad_start(9, '0'))
    i -= 1
  }
  sb.to_string()
}

///|
/// The exact decimal expansion of a finite, positive double: the digits (most
/// significant first, no leading zeros, trailing zeros dropped) and `point`
/// such that the value is `0.DIGITS * 10^point`.
fn exact_decimal(a : Double) -> (Array[Int32], Int32) {
  let bits = a.reinterpret_as_int64()
  let biased = ((bits >> 52) & 0x7ffL).to_int()
  let frac = bits & 0xfffffffffffffL
  let (m, e) = if biased == 0 {
    (frac, -1074)
  } else {
    (frac | 0x10000000000000L, biased - 1075)
  }
  let limbs : Array[Int64] = [m % 1_000_000_000L, m / 1_000_000_000L]
  // value = m * 2^e; for e < 0 it is (m * 5^-e) / 10^-e
  let mut shift = 0
  if e >= 0 {
    let mut k = e
    while k > 0 {
      let step = if k > 29 { 29 } else { k }
      big_mul_small(limbs, 1L << step)
      k -= step
    }
  } else {
    let mut k = -e
    shift = k
    while k > 0 {
      let step = if k > 12 { 12 } else { k }
      let mut p = 1L
      for _ in 0..<step {
        p = p * 5L
      }
      big_mul_small(limbs, p)
      k -= step
    }
  }
  let text = big_to_digits(limbs)
  let digits : Array[Int32] = []
  for c in text {
    digits.push(c.to_int() - 48)
  }
  let point = digits.length() - shift
  while digits.length() > 1 && digits[digits.length() - 1] == 0 {
    digits.pop() |> ignore
  }
  (digits, point)
}

///|
/// Keeps the first `keep` digits of `d`, rounding half to even on the exact
/// digits. The flag is true when the rounding carried into a new leading
/// digit (`999` -> `1000`: the result is `[1, 0, 0, 0]`). Fewer digits than
/// `keep` are returned unchanged.
fn round_digits(d : Array[Int32], keep : Int32) -> (Array[Int32], Bool) {
  if keep >= d.length() {
    return (d, false)
  }
  if keep < 0 {
    return ([], false)
  }
  let mut rest_nonzero = false
  for i in (keep + 1)..<d.length() {
    if d[i] != 0 {
      rest_nonzero = true
    }
  }
  let next = d[keep]
  let prev_odd = keep > 0 && d[keep - 1] % 2 == 1
  let up = next > 5 || (next == 5 && (rest_nonzero || prev_odd))
  let out : Array[Int32] = []
  for i in 0..<keep {
    out.push(d[i])
  }
  if !up {
    return (out, false)
  }
  let mut i = keep - 1
  while i >= 0 {
    if out[i] == 9 {
      out[i] = 0
      i -= 1
    } else {
      out[i] = out[i] + 1
      return (out, false)
    }
  }
  out.insert(0, 1)
  (out, true)
}

///|
/// Rust's `format!("{:.6}")` for a finite non-zero double whose exact digits
/// are `d` / `point`, with trailing zeros removed but at least one decimal
/// (`12.0` stays `12.0`).
fn fixed6_trimmed(neg : Bool, d : Array[Int32], point : Int32) -> String {
  let (r, carried) = round_digits(d, point + 6)
  let p = if carried { point + 1 } else { point }
  let sb = StringBuilder()
  if neg {
    sb.write_char('-')
  }
  if p <= 0 {
    sb.write_char('0')
  } else {
    for j in 0..<p {
      sb.write_string(if j < r.length() { r[j].to_string() } else { "0" })
    }
  }
  let frac : Array[Int32] = []
  for i in 0..<6 {
    let idx = p + i
    frac.push(if idx >= 0 && idx < r.length() { r[idx] } else { 0 })
  }
  let mut stop = frac.length()
  while stop > 1 && frac[stop - 1] == 0 {
    stop -= 1
  }
  sb.write_char('.')
  for i in 0..<stop {
    sb.write_string(frac[i].to_string())
  }
  sb.to_string()
}

///|
/// Rust's `format!("{:.4e}")`: five significant digits, `1.2346e8`,
/// `1.0000e-7`.
fn sci4(neg : Bool, d : Array[Int32], point : Int32) -> String {
  let (r, carried) = round_digits(d, 5)
  let p = if carried { point + 1 } else { point }
  let sb = StringBuilder()
  if neg {
    sb.write_char('-')
  }
  for i in 0..<5 {
    if i == 1 {
      sb.write_char('.')
    }
    sb.write_string((if i < r.length() { r[i] } else { 0 }).to_string())
  }
  sb.write_string("e" + (p - 1).to_string())
  sb.to_string()
}

///|
/// Length of Rust's `Display` text of a double (positional, never scientific)
/// from its shortest digits `nd` and decimal exponent `e` of the first digit.
fn display_len(neg : Bool, nd : Int32, e : Int32) -> Int32 {
  let sign = if neg { 1 } else { 0 }
  if e >= 0 {
    let int_len = e + 1
    if nd <= int_len {
      sign + int_len
    } else {
      sign + nd + 1
    }
  } else {
    sign + 2 + (-e - 1) + nd
  }
}

///|
/// Rust's `Display` text of a finite non-zero double (positional).
fn display_text(neg : Bool, digits : String, e : Int32) -> String {
  let nd = digits.length()
  let sign = if neg { "-" } else { "" }
  if e >= 0 {
    let int_len = e + 1
    if nd <= int_len {
      sign + digits + "0".repeat(int_len - nd)
    } else {
      sign + digits[:int_len].to_owned() + "." + digits[int_len:].to_owned()
    }
  } else {
    sign + "0." + "0".repeat(-e - 1) + digits
  }
}

///|
/// polars' table-cell text of a float (its `fmt_float` with the default
/// configuration). `f32` values are widened to `f64` first, as polars does.
///
/// - integral values below 999999 print with one decimal (`1.0`, `-0.0`);
/// - values whose positional text is longer than 9 characters print as
///   `1.2346e8` outside `1e-6 <= |x| <= 999999` and with at most six decimals
///   (`0.333333`, `12.0`) inside it;
/// - other integral values print as `1e6` / `1.2345678e7`, the rest
///   positionally; `NaN`, `inf` and `-inf` as such.
fn cell_float(x : Double) -> String {
  if x.is_nan() {
    return "NaN"
  }
  if x.is_pos_inf() {
    return "inf"
  }
  if x.is_neg_inf() {
    return "-inf"
  }
  let neg = x.reinterpret_as_int64() < 0L
  let a = if neg { -x } else { x }
  let integral = a >= 4503599627370496.0 || a == a.to_int64().to_double()
  if integral && a < 999999.0 {
    return (if neg { "-" } else { "" }) + a.to_int64().to_string() + ".0"
  }
  let (digits, e) = float_digits(a.to_string())
  if display_len(neg, digits.length(), e) > 9 {
    let (d, point) = exact_decimal(a)
    if a < 0.000001 || a > 999999.0 {
      sci4(neg, d, point)
    } else {
      fixed6_trimmed(neg, d, point)
    }
  } else if integral {
    let rest = if digits.length() > 1 {
      "." + digits[1:].to_owned()
    } else {
      ""
    }
    (if neg { "-" } else { "" }) +
    digits[:1].to_owned() +
    rest +
    "e" +
    e.to_string()
  } else {
    display_text(neg, digits, e)
  }
}

// ---------------------------------------------------------------------------
// Dates, strings, widths
// ---------------------------------------------------------------------------

///|
/// A date cell; days beyond `max_format_days` get a placeholder.
fn cell_date(days : Int32) -> String {
  match format_date_checked(days) {
    Some(s) => s
    None => fmt_bad_date
  }
}

///|
/// A datetime cell: `YYYY-MM-DD HH:MM:SS` followed by the fraction with 3
/// digits when it is whole milliseconds and 6 digits otherwise.
fn cell_datetime(us : Int64) -> String {
  let s = format_datetime(us)
  if s.has_suffix(".000000") {
    s[:s.length() - 7].to_owned()
  } else if s.has_suffix("000") {
    s[:s.length() - 3].to_owned()
  } else {
    s
  }
}

///|
/// Cuts `s` to `fmt_str_len` characters; the flag says whether it was cut.
fn cut_str(s : String) -> (String, Bool) {
  let sb = StringBuilder()
  let mut n = 0
  for c in s {
    if n == fmt_str_len {
      return (sb.to_string(), true)
    }
    sb.write_char(c)
    n += 1
  }
  (s, false)
}

///|
/// The text of a string cell in a table (cut, no quotes).
fn cell_str(s : String) -> String {
  let (t, cut) = cut_str(s)
  if cut {
    t + "…"
  } else {
    t
  }
}

///|
/// The text of a string element in a series listing: quoted; a cut string
/// loses its closing quote, as in polars.
fn series_str(s : String) -> String {
  let (t, cut) = cut_str(s)
  if cut {
    "\"" + t + "…"
  } else {
    "\"" + t + "\""
  }
}

///|
/// Display width of one character: 2 for East Asian wide and fullwidth
/// characters and emoji, 0 for combining marks and zero-width characters,
/// 1 otherwise (control characters count 1, as in polars' tables). This is a
/// compact approximation of the Unicode width tables; a variation selector
/// that makes a symbol an emoji is handled by `char_width_after`.
fn char_width(c : Char) -> Int32 {
  let u = c.to_int()
  if u < 0x300 {
    return 1
  }
  // text-default symbols (some sit inside emoji blocks) are one column wide
  if is_vs16_base(c) {
    return 1
  }
  if (u >= 0x300 && u <= 0x36f) ||
    (u >= 0x200b && u <= 0x200f) ||
    (u >= 0x2060 && u <= 0x2064) ||
    (u >= 0xfe00 && u <= 0xfe0f) ||
    u == 0xfeff {
    return 0
  }
  if (u >= 0x1100 && u <= 0x115f) ||
    (u >= 0x2e80 && u <= 0x303e) ||
    (u >= 0x3041 && u <= 0x33ff) ||
    (u >= 0x3400 && u <= 0x4dbf) ||
    (u >= 0x4e00 && u <= 0x9fff) ||
    (u >= 0xa000 && u <= 0xa4cf) ||
    (u >= 0xa960 && u <= 0xa97f) ||
    (u >= 0xac00 && u <= 0xd7a3) ||
    (u >= 0xf900 && u <= 0xfaff) ||
    (u >= 0xfe30 && u <= 0xfe6f) ||
    (u >= 0xff00 && u <= 0xff60) ||
    (u >= 0xffe0 && u <= 0xffe6) ||
    (u >= 0x1f300 && u <= 0x1f64f) ||
    (u >= 0x1f680 && u <= 0x1f6ff) ||
    (u >= 0x1f900 && u <= 0x1f9ff) ||
    (u >= 0x20000 && u <= 0x3fffd) {
    return 2
  }
  1
}

///|
/// Characters that are one column wide on their own but two columns wide when
/// directly followed by U+FE0F (emoji presentation selector), as inclusive
/// code point ranges in ascending order. Taken from polars 2.1.0's output for
/// every code point; `#`, `*` and the digits are included.
let vs16_bases : FixedArray[(Int32, Int32)] = [
  (0x23, 0x23),
  (0x2a, 0x2a),
  (0x30, 0x39),
  (0xa9, 0xa9),
  (0xae, 0xae),
  (0x203c, 0x203c),
  (0x2049, 0x2049),
  (0x2122, 0x2122),
  (0x2139, 0x2139),
  (0x2194, 0x2199),
  (0x21a9, 0x21aa),
  (0x2328, 0x2328),
  (0x23cf, 0x23cf),
  (0x23ed, 0x23ef),
  (0x23f1, 0x23f2),
  (0x23f8, 0x23fa),
  (0x24c2, 0x24c2),
  (0x25aa, 0x25ab),
  (0x25b6, 0x25b6),
  (0x25c0, 0x25c0),
  (0x25fb, 0x25fc),
  (0x2600, 0x2604),
  (0x260e, 0x260e),
  (0x2611, 0x2611),
  (0x2618, 0x2618),
  (0x261d, 0x261d),
  (0x2620, 0x2620),
  (0x2622, 0x2623),
  (0x2626, 0x2626),
  (0x262a, 0x262a),
  (0x262e, 0x262f),
  (0x2638, 0x263a),
  (0x2640, 0x2640),
  (0x2642, 0x2642),
  (0x265f, 0x2660),
  (0x2663, 0x2663),
  (0x2665, 0x2666),
  (0x2668, 0x2668),
  (0x267b, 0x267b),
  (0x267e, 0x267e),
  (0x2692, 0x2692),
  (0x2694, 0x2697),
  (0x2699, 0x2699),
  (0x269b, 0x269c),
  (0x26a0, 0x26a0),
  (0x26a7, 0x26a7),
  (0x26b0, 0x26b1),
  (0x26c8, 0x26c8),
  (0x26cf, 0x26cf),
  (0x26d1, 0x26d1),
  (0x26d3, 0x26d3),
  (0x26e9, 0x26e9),
  (0x26f0, 0x26f1),
  (0x26f4, 0x26f4),
  (0x26f7, 0x26f9),
  (0x2702, 0x2702),
  (0x2708, 0x2709),
  (0x270c, 0x270d),
  (0x270f, 0x270f),
  (0x2712, 0x2712),
  (0x2714, 0x2714),
  (0x2716, 0x2716),
  (0x271d, 0x271d),
  (0x2721, 0x2721),
  (0x2733, 0x2734),
  (0x2744, 0x2744),
  (0x2747, 0x2747),
  (0x2763, 0x2764),
  (0x27a1, 0x27a1),
  (0x2934, 0x2935),
  (0x2b05, 0x2b07),
  (0x1f170, 0x1f171),
  (0x1f17e, 0x1f17f),
  (0x1f321, 0x1f321),
  (0x1f324, 0x1f32c),
  (0x1f336, 0x1f336),
  (0x1f37d, 0x1f37d),
  (0x1f396, 0x1f397),
  (0x1f399, 0x1f39b),
  (0x1f39e, 0x1f39f),
  (0x1f3cb, 0x1f3ce),
  (0x1f3d4, 0x1f3df),
  (0x1f3f3, 0x1f3f3),
  (0x1f3f5, 0x1f3f5),
  (0x1f3f7, 0x1f3f7),
  (0x1f43f, 0x1f43f),
  (0x1f441, 0x1f441),
  (0x1f4fd, 0x1f4fd),
  (0x1f549, 0x1f54a),
  (0x1f56f, 0x1f570),
  (0x1f573, 0x1f579),
  (0x1f587, 0x1f587),
  (0x1f58a, 0x1f58d),
  (0x1f590, 0x1f590),
  (0x1f5a5, 0x1f5a5),
  (0x1f5a8, 0x1f5a8),
  (0x1f5b1, 0x1f5b2),
  (0x1f5bc, 0x1f5bc),
  (0x1f5c2, 0x1f5c4),
  (0x1f5d1, 0x1f5d3),
  (0x1f5dc, 0x1f5de),
  (0x1f5e1, 0x1f5e1),
  (0x1f5e3, 0x1f5e3),
  (0x1f5e8, 0x1f5e8),
  (0x1f5ef, 0x1f5ef),
  (0x1f5f3, 0x1f5f3),
  (0x1f5fa, 0x1f5fa),
  (0x1f6cb, 0x1f6cb),
  (0x1f6cd, 0x1f6cf),
  (0x1f6e0, 0x1f6e5),
  (0x1f6e9, 0x1f6e9),
  (0x1f6f0, 0x1f6f0),
  (0x1f6f3, 0x1f6f3),
]

///|
/// Whether `c` is in `vs16_bases` (binary search).
fn is_vs16_base(c : Char) -> Bool {
  let u = c.to_int()
  let mut lo = 0
  let mut hi = vs16_bases.length() - 1
  while lo <= hi {
    let mid = (lo + hi) / 2
    let (a, b) = vs16_bases[mid]
    if u < a {
      hi = mid - 1
    } else if u > b {
      lo = mid + 1
    } else {
      return true
    }
  }
  false
}

///|
/// Width of `c` when it directly follows `prev` (`None` at the start of a
/// string): `char_width`, except that U+FE0F after a `vs16_bases` character
/// adds the second column.
fn char_width_after(prev : Char?, c : Char) -> Int32 {
  match prev {
    Some(p) if c.to_int() == 0xfe0f && is_vs16_base(p) => 1
    _ => char_width(c)
  }
}

///|
/// Display width of a string.
fn str_width(s : String) -> Int32 {
  let mut w = 0
  let mut prev : Char? = None
  for c in s {
    w += char_width_after(prev, c)
    prev = Some(c)
  }
  w
}

///|
/// The lines of a table cell: split at `\n` (a `\r` stays in the text and
/// counts as one column) and every line hard-wrapped to `fmt_cell_width`
/// columns.
fn cell_lines(text : String) -> Array[String] {
  let out : Array[String] = []
  for part in text.split("\n") {
    let line = part.to_owned()
    if str_width(line) <= fmt_cell_width {
      out.push(line)
    } else {
      let sb = StringBuilder()
      let mut w = 0
      let mut prev : Char? = None
      for c in line {
        let cw = char_width_after(prev, c)
        if w + cw > fmt_cell_width && w > 0 {
          out.push(sb.to_string())
          sb.reset()
          w = 0
        }
        sb.write_char(c)
        w += cw
        prev = Some(c)
      }
      out.push(sb.to_string())
    }
  }
  out
}

// ---------------------------------------------------------------------------
// Values
// ---------------------------------------------------------------------------

///|
/// The text of a value as it appears in a polars table cell.
fn cell_text(v : AnyValue) -> String {
  match v {
    Null => "null"
    Boolean(b) => if b { "true" } else { "false" }
    Int32(x) => x.to_string()
    Int64(x) => x.to_string()
    Float32(x) => cell_float(x.to_double())
    Float64(x) => cell_float(x)
    String(s) => cell_str(s)
    Date(d) => cell_date(d)
    Datetime(t) => cell_datetime(t)
  }
}

///|
/// Shows the value as polars prints it in a table cell: `null`, `true`,
/// `-3`, floats like `1.0`, `0.333333`, `1.2346e8`, `NaN`, `inf`; dates as
/// `1970-01-01`, datetimes as `1970-01-01 00:00:00` (plus `.123` or
/// `.123456` when there is a fraction). Strings are printed without quotes
/// and cut to 30 characters followed by `…`, exactly as in a table.
pub impl Show for AnyValue with fn output(self, logger) {
  logger.write_string(cell_text(self))
}

///|
/// The element at `i`, which the callers guarantee to be in range.
fn value_at(s : Series, i : Int32) -> AnyValue {
  s.get(i) catch {
    e => abort("format: element \{i} of '\{s.name()}' is unreachable: \{e}")
  }
}

// ---------------------------------------------------------------------------
// Series
// ---------------------------------------------------------------------------

///|
/// Shows the series as `str(series)` does in polars:
///
/// ```
/// shape: (3,)
/// Series: 'a' [i64]
/// [
///   1
///   2
///   null
/// ]
/// ```
///
/// (elements are indented with a tab). Strings are quoted, more than 10
/// elements are folded to the first 5, `…` and the last 5.
pub impl Show for Series with fn output(self, logger) {
  let n = self.len()
  let sb = StringBuilder()
  sb.write_string(
    "shape: (\{n},)\nSeries: '\{self.name()}' [\{self.dtype()}]\n[\n",
  )
  let elem = (i : Int32) => {
    match value_at(self, i) {
      String(s) => series_str(s)
      v => cell_text(v)
    }
  }
  if n > fmt_max_rows {
    let half = fmt_max_rows / 2
    for i in 0..<half {
      sb.write_string("\t" + elem(i) + "\n")
    }
    sb.write_string("\t…\n")
    for i in (n - half)..<n {
      sb.write_string("\t" + elem(i) + "\n")
    }
  } else {
    for i in 0..<n {
      sb.write_string("\t" + elem(i) + "\n")
    }
  }
  sb.write_string("]")
  logger.write_string(sb.to_string())
}

// ---------------------------------------------------------------------------
// DataFrame
// ---------------------------------------------------------------------------

///|
/// One printed column: the header cell (name, `---`, dtype) and the body
/// cells, each already split into lines.
priv struct TableColumn {
  header : Array[String]
  cells : Array[Array[String]]
  width : Int32
}

///|
fn TableColumn::new(
  header : Array[String],
  cells : Array[Array[String]],
  natural : Int32,
) -> TableColumn {
  // wrapped cells still make the column as wide as the wrap limit
  let mut width = if natural > fmt_cell_width {
    fmt_cell_width
  } else {
    natural
  }
  for line in header {
    let w = str_width(line)
    if w > width {
      width = w
    }
  }
  for cell in cells {
    for line in cell {
      let w = str_width(line)
      if w > width {
        width = w
      }
    }
  }
  { header, cells, width, }
}

///|
/// The widest line of a cell before wrapping.
fn cell_natural_width(text : String) -> Int32 {
  let mut w = 0
  for part in text.split("\n") {
    let pw = str_width(part.to_owned())
    if pw > w {
      w = pw
    }
  }
  w
}

///|
/// The header lines of a column: name, `---`, dtype.
fn header_lines(name : String, dtype : DataType) -> Array[String] {
  let out = cell_lines(cell_str(name))
  out.push("---")
  out.push("\{dtype}")
  out
}

///|
/// Row indices to print; `-1` marks the `…` row.
fn visible_rows(height : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  if height > fmt_max_rows {
    let half = fmt_max_rows / 2
    for i in 0..<half {
      out.push(i)
    }
    out.push(-1)
    for i in (height - half)..<height {
      out.push(i)
    }
  } else {
    for i in 0..<height {
      out.push(i)
    }
  }
  out
}

///|
/// Column indices to print; `-1` marks the `…` column.
fn visible_cols(width : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  if width > fmt_max_cols {
    let half = fmt_max_cols / 2
    for i in 0..<half {
      out.push(i)
    }
    out.push(-1)
    for i in (width - half)..<width {
      out.push(i)
    }
  } else {
    for i in 0..<width {
      out.push(i)
    }
  }
  out
}

///|
/// Writes one table row: `height` lines, cells padded to the column widths.
fn write_row(
  sb : StringBuilder,
  cols : Array[TableColumn],
  lines_of : (TableColumn) -> Array[String],
) -> Unit {
  let cells = cols.map(lines_of)
  let mut height = 0
  for c in cells {
    if c.length() > height {
      height = c.length()
    }
  }
  for k in 0..<height {
    sb.write_string("│")
    for j, c in cells {
      if j > 0 {
        sb.write_string("┆")
      }
      let line = if k < c.length() { c[k] } else { "" }
      sb.write_string(
        " " + line + " ".repeat(cols[j].width - str_width(line)) + " ",
      )
    }
    sb.write_string("│\n")
  }
}

///|
/// A horizontal rule `left` + `fill`s joined by `mid` + `right`.
fn rule(
  cols : Array[TableColumn],
  left : String,
  mid : String,
  right : String,
  fill : String,
) -> String {
  left + cols.map(c => fill.repeat(c.width + 2)).join(mid) + right + "\n"
}

///|
/// Shows the frame as `str(df)` does in polars: a `shape:` line and a box
/// table with the name, `---` and dtype of every column, left-aligned cells,
/// null as `null`, strings cut to 30 characters, more than 10 rows folded to
/// the first 5, a `…` row and the last 5, more than 8 columns folded to the
/// first 4, a `…` column and the last 4. An empty frame prints its (empty)
/// box.
pub impl Show for DataFrame with fn output(self, logger) {
  let (h, w) = self.shape()
  let sb = StringBuilder()
  sb.write_string("shape: (\{h}, \{w})\n")
  let all = self.get_columns()
  let rows = visible_rows(h)
  let cols : Array[TableColumn] = []
  for j in visible_cols(w) {
    if j < 0 {
      cols.push(TableColumn::new(["…"], rows.map(_ => ["…"]), 1))
    } else {
      let s = all[j]
      let texts = rows.map(i => {
        if i < 0 {
          "…"
        } else {
          cell_text(value_at(s, i))
        }
      })
      let mut natural = cell_natural_width(cell_str(s.name()))
      for text in texts {
        let w = cell_natural_width(text)
        if w > natural {
          natural = w
        }
      }
      cols.push(
        TableColumn::new(
          header_lines(s.name(), s.dtype()),
          texts.map(cell_lines),
          natural,
        ),
      )
    }
  }
  sb.write_string(rule(cols, "┌", "┬", "┐", "─"))
  write_row(sb, cols, c => c.header)
  sb.write_string(rule(cols, "╞", "╪", "╡", "═"))
  for r in 0..<rows.length() {
    write_row(sb, cols, c => c.cells[r])
  }
  let text = sb.to_string() + rule(cols, "└", "┴", "┘", "─")
  // no trailing newline
  logger.write_string(text[:text.length() - 1].to_owned())
}

///|
/// Makes `to_string` callable as a method (`v.to_string()`). The text is the
/// table-cell format of `Show for AnyValue`, so strings are cut at 30
/// characters followed by `…`.
pub extend AnyValue with Show::{to_string}

///|
/// Makes `to_string` callable as a method (`s.to_string()`).
pub extend Series with Show::{to_string}

///|
/// Makes `to_string` callable as a method (`df.to_string()`).
pub extend DataFrame with Show::{to_string}
