// polars-style `Show` for `AnyValue`, `Series` and `DataFrame`.
//
// The layout and the cell text follow polars 2.1.0 under its default
// configuration (see docs/golden/show.json):
// - tables show at most 10 rows (first 5, `…`, last 5) and 8 columns (first
//   4, `…`, last 4); series show at most 10 elements the same way;
// - strings longer than 30 characters are cut to 30 characters plus `…`;
// - floats follow polars' `fmt_float`, which is not the cast-to-string text.
//
// Text widths are measured from polars' own output (see `char_width.mbt`):
// per code point, plus the sequence rules for variation selectors, ZWJ emoji,
// modifiers and a few ligatures.

///|
/// Longest string (in characters) printed before it is cut.
let fmt_str_len : Int32 = 30

///|
/// Widest a table column is (the cut string plus the `…` is 31 characters);
/// wider cell lines (only possible with wide characters) are wrapped.
let fmt_cell_width : Int32 = 31

///|
/// comfy-table does not split a word into a line with fewer free columns than
/// this (not counting the joining space); the word starts the next line.
let fmt_min_free : Int32 = 4

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
/// Splits `word` for `split_long_word`: the longest prefix of whole grapheme
/// clusters whose widths (each measured on its own) add up to at most `room`
/// columns, and the rest. When not even the first cluster fits and `fresh` (the
/// line is empty), one code point is taken anyway.
fn split_long_word(
  word : String,
  room : Int32,
  fresh : Bool,
) -> (String, String) {
  let cs : Array[Int32] = []
  for c in word {
    cs.push(c.to_int())
  }
  let n = cs.length()
  let mut taken = 0
  let mut w = 0
  while taken < n {
    let stop = grapheme_end(cs, taken)
    let part : Array[Int32] = []
    for k in taken..<stop {
      part.push(cs[k])
    }
    let pw = code_points_width(part, part.length())
    if w + pw > room {
      break
    }
    w += pw
    taken = stop
  }
  if taken == 0 && fresh && n > 0 {
    taken = 1
  }
  let first = StringBuilder()
  let rest = StringBuilder()
  for k in 0..<n {
    if k < taken {
      first.write_char(cs[k].unsafe_to_char())
    } else {
      rest.write_char(cs[k].unsafe_to_char())
    }
  }
  (first.to_string(), rest.to_string())
}

///|
/// Wraps one line (no `\n`) to `limit` columns the way comfy-table's
/// `split_line` does. A line that fits is kept. Otherwise it is split at
/// single spaces into words that are laid out in order: a word that fits next
/// to the text of the current line (one column for the joining space) is
/// appended; a word wider than the column is cut into the free space of the
/// current line, cluster by cluster, when at least `fmt_min_free` columns are
/// free; any other word starts a new line. The spaces at the breaks are
/// dropped, and so are leading spaces (the line is "empty" while it has no
/// text).
fn wrap_line(line : String, limit : Int32) -> Array[String] {
  let out : Array[String] = []
  if str_width(line) <= limit {
    out.push(line)
    return out
  }
  let parts : Array[String] = []
  for p in line.split(" ") {
    parts.push(p.to_owned())
  }
  // a stack: the next word is on top
  let words : Array[String] = []
  for k = parts.length() - 1; k >= 0; k = k - 1 {
    words.push(parts[k])
  }
  let mut cur = ""
  while words.pop() is Some(word) {
    let join = if cur.length() > 0 { 1 } else { 0 }
    let cw = str_width(cur)
    let ww = str_width(word)
    if join == 1 && limit - cw - 1 <= 0 {
      // no column left, not even for a zero-width word
      out.push(cur)
      cur = ""
      words.push(word)
    } else if cw + join + ww <= limit {
      cur = if join == 1 { cur + " " + word } else { word }
    } else if ww > limit && (join == 0 || limit - cw >= fmt_min_free) {
      let (first, rest) = split_long_word(word, limit - cw - join, join == 0)
      out.push(if join == 1 { cur + " " + first } else { first })
      cur = ""
      words.push(rest)
    } else {
      out.push(cur)
      cur = ""
      words.push(word)
    }
  }
  if cur.length() > 0 {
    out.push(cur)
  }
  out
}

///|
/// The lines of a table cell: split at `\n` (a `\r` stays in the text and
/// counts as one column) and every line wrapped to `limit` columns.
fn cell_lines(text : String, limit : Int32) -> Array[String] {
  let out : Array[String] = []
  for part in text.split("\n") {
    for line in wrap_line(part.to_owned(), limit) {
      out.push(line)
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
/// The complete text of a value (not cut or rounded like a table cell).
fn full_text(v : AnyValue) -> String {
  match v {
    Float32(x) => format_f32(x)
    Float64(x) => format_f64(x)
    String(s) => s
    v => cell_text(v)
  }
}

///|
/// Shows the whole value, never a table-cell abbreviation: `null`, `true`,
/// `-3`; floats as their shortest round-trip digits (`3.3333333333333335`,
/// `1234567.891`, `1e-6`, `1.5e+16`, `NaN`, `inf`; the text of
/// `Series::cast` to `String`); strings in full and without quotes; dates as
/// `1970-01-01` and datetimes as `1970-01-01 00:00:00` (plus `.123` or
/// `.123456` when there is a fraction). A `DataFrame` or `Series` print cuts
/// long strings and rounds floats to table width; this does not.
pub impl Show for AnyValue with fn output(self, logger) {
  logger.write_string(full_text(self))
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
/// The column is `limit` columns wide (or wider, if a line cannot be wrapped
/// that narrow).
fn TableColumn::new(
  header : Array[String],
  cells : Array[Array[String]],
  limit : Int32,
) -> TableColumn {
  let mut width = limit
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
/// The bound polars puts on a cell when it lays a column out: twice its number
/// of code points, but at most its length in UTF-8 bytes. Only U+17D8 (three
/// columns, three bytes) is ever wider than that, see `column_limit`.
fn cell_bound(text : String) -> Int32 {
  let mut chars = 0
  let mut bytes = 0
  for c in text {
    chars += 1
    let u = c.to_int()
    bytes += if u < 0x80 {
      1
    } else if u < 0x800 {
      2
    } else if u < 0x10000 {
      3
    } else {
      4
    }
  }
  if 2 * chars < bytes {
    2 * chars
  } else {
    bytes
  }
}

///|
/// The width of a column, from the texts of all its cells (the name, `---` and
/// the dtype included): the widest cell, where no cell counts for more than the
/// largest `cell_bound` of the column, and at most `fmt_cell_width`. Cells
/// wider than this are wrapped to it.
fn column_limit(texts : Array[String]) -> Int32 {
  let mut bound = 0
  for t in texts {
    let b = cell_bound(t)
    if b > bound {
      bound = b
    }
  }
  let mut width = 0
  for t in texts {
    let w = cell_natural_width(t)
    let w = if w > bound { bound } else { w }
    if w > width {
      width = w
    }
  }
  if width > fmt_cell_width {
    fmt_cell_width
  } else {
    width
  }
}

///|
/// The header lines of a column: name, `---`, dtype.
fn header_lines(
  name : String,
  dtype : DataType,
  limit : Int32,
) -> Array[String] {
  let out = cell_lines(cell_str(name), limit)
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
      let name_text = cell_str(s.name())
      let all = [name_text, "---", "\{s.dtype()}"]
      for t in texts {
        all.push(t)
      }
      let natural = column_limit(all)
      cols.push(
        TableColumn::new(
          header_lines(s.name(), s.dtype(), natural),
          texts.map(t => cell_lines(t, natural)),
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
