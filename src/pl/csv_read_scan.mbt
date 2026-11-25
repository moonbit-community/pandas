///|
/// Larger than any column count or record count.
let csv_unbounded : Int32 = 1073741824

///|
/// The records of a CSV text, scanned once and stored as offsets into the text.
///
/// Field `i` (a flat index over all records) is the text range
/// `[fstart[i], fend[i])` of `text`; for a quoted field the range excludes the
/// quotes, and `fflag[i]` is 0 (not quoted), 1 (quoted) or 2 (quoted, with
/// doubled quotes inside that have to be collapsed). Record `r` has the fields
/// `rec_first[r] ..` up to the first field of the next record; `rec_line[r]` is
/// the physical line (1 based) its first character is on.
priv struct CsvScanner {
  text : String
  len : Int32
  mut pos : Int32
  mut line : Int32
  sep0 : Int32
  sep1 : Int32
  sep_n : Int32
  q0 : Int32
  q1 : Int32
  q_n : Int32
  fstart : Array[Int32]
  fend : Array[Int32]
  fflag : Array[Byte]
  rec_first : Array[Int32]
  rec_line : Array[Int32]
  /// The record of the last value error made by `parse_error`.
  mut err_row : Int32
  /// Set by `scan_record` for the record it scanned when a quote is wrong (text
  /// after a closing quote, or a quote that never closes): the raw range of
  /// the field, its column and the line. The field stays in the record (as
  /// plain text) so that the other fields keep their columns.
  mut bad_quote : (Int32, Int32, Int32, Int32)?
  /// The first malformed record that `scan_some` met: 0 none, 1 more fields
  /// than columns (the extra ones are dropped), 2 a wrong quote.
  mut struct_kind : Int32
  /// Its index in the records, and the column the error is at (for more fields
  /// than columns, the number of columns).
  mut struct_rec : Int32
  mut struct_col : Int32
}

///|
/// The UTF-16 code units of a character: `(first, second, count)`.
fn csv_units(c : Char) -> (Int32, Int32, Int32) {
  let v = c.to_int()
  if v >= 65536 {
    let w = v - 65536
    (55296 + (w >> 10), 56320 + (w & 1023), 2)
  } else {
    (v, 0, 1)
  }
}

///|
fn CsvScanner::new(text : String, sep : Char, quote : Char?) -> CsvScanner {
  let (s0, s1, sn) = csv_units(sep)
  let (q0, q1, qn) = match quote {
    Some(q) => csv_units(q)
    None => (-1, -1, 0)
  }
  let len = text.length()
  // a leading byte order mark is not part of the data
  let pos = if len > 0 && text.unsafe_get(0).to_int() == 65279 { 1 } else { 0 }
  {
    text,
    len,
    pos,
    line: 1,
    sep0: s0,
    sep1: s1,
    sep_n: sn,
    q0,
    q1,
    q_n: qn,
    fstart: [],
    fend: [],
    fflag: [],
    rec_first: [],
    rec_line: [],
    err_row: 0,
    bad_quote: None,
    struct_kind: 0,
    struct_rec: -1,
    struct_col: 0,
  }
}

///|
fn CsvScanner::unit(self : CsvScanner, i : Int32) -> Int32 {
  self.text.unsafe_get(i).to_int()
}

///|
/// Whether the separator starts at `i` (`i < len`).
fn CsvScanner::is_sep(self : CsvScanner, i : Int32) -> Bool {
  self.unit(i) == self.sep0 &&
  (self.sep_n == 1 || (i + 1 < self.len && self.unit(i + 1) == self.sep1))
}

///|
/// Whether the quote character starts at `i` (`i < len`).
fn CsvScanner::is_quote(self : CsvScanner, i : Int32) -> Bool {
  self.q_n > 0 &&
  self.unit(i) == self.q0 &&
  (self.q_n == 1 || (i + 1 < self.len && self.unit(i + 1) == self.q1))
}

///|
fn CsvScanner::nrecords(self : CsvScanner) -> Int32 {
  self.rec_first.length()
}

///|
/// Number of fields of record `r`.
fn CsvScanner::nfields(self : CsvScanner, r : Int32) -> Int32 {
  let stop = if r + 1 < self.rec_first.length() {
    self.rec_first[r + 1]
  } else {
    self.fstart.length()
  }
  stop - self.rec_first[r]
}

///|
/// Forgets the records scanned so far (the position and line stay).
fn CsvScanner::clear_records(self : CsvScanner) -> Unit {
  self.fstart.clear()
  self.fend.clear()
  self.fflag.clear()
  self.rec_first.clear()
  self.rec_line.clear()
}

///|
/// The index of the first `\n` in `[a, b)`, or `b`.
fn CsvScanner::first_newline(self : CsvScanner, a : Int32, b : Int32) -> Int32 {
  let mut i = a
  while i < b && self.unit(i) != 10 {
    i += 1
  }
  i
}

///|
/// The first line of polars' "could not parse" message for the raw text
/// `[a, b)` (a message with a line break in the text stops at the break).
fn CsvScanner::could_not_parse(
  self : CsvScanner,
  a : Int32,
  b : Int32,
  dtype : String,
  name : String,
  k : Int32,
) -> String {
  let nl = self.first_newline(a, b)
  let head = "could not parse `" + self.text[a:nl].to_owned()
  if nl < b {
    return head
  }
  // a line break in the column name ends the line too
  let tail = "` as dtype `\{dtype}` at column '\{name}' (column number \{k + 1})"
  for i in 0..<tail.length() {
    if tail.unsafe_get(i).to_int() == 10 {
      return head + tail[:i].to_owned()
    }
  }
  head + tail
}

///|
/// The name of column `k`: the header's, or `column_<k>` (no header, or a
/// column the header does not have).
fn csv_column_name(names : Array[String], k : Int32) -> String {
  if k < names.length() {
    names[k]
  } else {
    "column_\{k}"
  }
}

///|
/// Scans the record at `pos` (`pos < len`) and stores its fields; it does not
/// fail. A quote that is wrong (text after the closing quote, or no closing
/// quote) is kept as a plain field up to the next separator or line break (to
/// the end of the text for a quote that never closes) and `bad_quote` tells
/// where it is. A record with more fields than `ncols` keeps them all here;
/// `scan_some` drops the extra ones.
fn CsvScanner::scan_record(self : CsvScanner) -> Unit {
  let rline = self.line
  self.bad_quote = None
  self.rec_first.push(self.fstart.length())
  self.rec_line.push(rline)
  let len = self.len
  let mut k = 0
  while true {
    let fs = self.pos
    let mut raw_from = fs
    if fs < len && self.is_quote(fs) {
      let start = fs + self.q_n
      let mut i = start
      let mut escapes = false
      let mut newlines = 0
      let mut closed = -1
      while i < len {
        let c = self.unit(i)
        if c == self.q0 && self.is_quote(i) {
          if i + self.q_n < len && self.is_quote(i + self.q_n) {
            escapes = true
            i += 2 * self.q_n
          } else {
            closed = i
            break
          }
        } else {
          if c == 10 {
            newlines += 1
          }
          i += 1
        }
      }
      if closed < 0 {
        // the quote never closes: the rest of the text is the field
        if self.bad_quote is None {
          self.bad_quote = Some((fs, len, k, rline))
        }
        self.fstart.push(fs)
        self.fend.push(len)
        self.fflag.push(0)
        self.line += newlines
        self.pos = len
        return
      }
      self.fstart.push(start)
      self.fend.push(closed)
      self.fflag.push(if escapes { 2 } else { 1 })
      self.line += newlines
      let j = closed + self.q_n
      if j >= len {
        self.pos = len
        return
      }
      if self.is_sep(j) {
        self.pos = j + self.sep_n
        k += 1
        continue
      }
      let c = self.unit(j)
      if c == 10 {
        self.pos = j + 1
        self.line += 1
        return
      }
      if c == 13 && (j + 1 >= len || self.unit(j + 1) == 10) {
        if j + 1 >= len {
          self.pos = len
        } else {
          self.pos = j + 2
          self.line += 1
        }
        return
      }
      // Text after the closing quote: polars goes on with the quote state
      // (every quote character toggles it), so the raw field runs from its
      // start to the first separator or line break outside quotes, and to the
      // end of the text when a quote is left open. The field stored for the
      // quoted part is replaced by the raw one.
      ignore(self.fstart.pop())
      ignore(self.fend.pop())
      ignore(self.fflag.pop())
      self.line -= newlines
      raw_from = j
    }
    let mut i = fs
    // 0: end of the text, 1: separator, 2: line break
    let mut term = 0
    if raw_from == fs {
      while i < len {
        let c = self.unit(i)
        if c == self.sep0 && self.is_sep(i) {
          term = 1
          break
        }
        if c == 10 {
          term = 2
          break
        }
        i += 1
      }
    } else {
      let mut in_q = false
      let mut raw_nl = 0
      while i < len {
        let c = self.unit(i)
        if c == self.q0 && self.is_quote(i) {
          in_q = !in_q
          i += self.q_n
          continue
        }
        if in_q {
          if c == 10 {
            raw_nl += 1
          }
          i += 1
          continue
        }
        if c == self.sep0 && self.is_sep(i) {
          term = 1
          break
        }
        if c == 10 {
          term = 2
          break
        }
        i += 1
      }
      self.line += raw_nl
    }
    let mut e = i
    // the CR of a CRLF (or a CR at the very end) is not part of the field
    if term != 1 && e > fs && self.unit(e - 1) == 13 {
      e -= 1
    }
    if raw_from != fs && self.bad_quote is None {
      self.bad_quote = Some((fs, e, k, rline))
    }
    self.fstart.push(fs)
    self.fend.push(e)
    self.fflag.push(0)
    if term == 1 {
      self.pos = i + self.sep_n
      k += 1
    } else if term == 2 {
      self.pos = i + 1
      self.line += 1
      return
    } else {
      self.pos = len
      return
    }
  }
}

///|

///|
/// Whether record `r` is a blank line: one empty field that is not quoted.
fn CsvScanner::is_blank_record(self : CsvScanner, r : Int32) -> Bool {
  if self.nfields(r) != 1 {
    return false
  }
  let i = self.rec_first[r]
  self.fflag[i] == 0 && self.fstart[i] == self.fend[i]
}

///|
/// The index of the field of column `c` in record `r`, or -1 when the record
/// is shorter.
fn CsvScanner::field_index(self : CsvScanner, r : Int32, c : Int32) -> Int32 {
  if c < self.nfields(r) {
    self.rec_first[r] + c
  } else {
    -1
  }
}

///|
/// The text of field `i` with the doubled quotes collapsed.
fn CsvScanner::field_text(self : CsvScanner, i : Int32) -> String {
  let a = self.fstart[i]
  let b = self.fend[i]
  if self.fflag[i] != 2 {
    return self.text[a:b].to_owned()
  }
  let sb = StringBuilder()
  let mut p = a
  let mut seg = a
  while p < b {
    if self.is_quote(p) {
      // a doubled quote: keep one, skip the other
      sb.write_string(self.text[seg:p + self.q_n].to_owned())
      p += 2 * self.q_n
      seg = p
    } else {
      p += 1
    }
  }
  sb.write_string(self.text[seg:b].to_owned())
  sb.to_string()
}

///|
/// The range of field `i` in the text as written, quotes included.
fn CsvScanner::raw_range(self : CsvScanner, i : Int32) -> (Int32, Int32) {
  if self.fflag[i] == 0 {
    (self.fstart[i], self.fend[i])
  } else {
    (self.fstart[i] - self.q_n, self.fend[i] + self.q_n)
  }
}

///|
/// Scans records until there are `limit` of them or the text ends. Records are
/// scanned in file order; the first malformed one (more fields than `ncols`, a
/// wrong quote) is noted in `struct_kind`, `struct_rec` and `struct_col`, and
/// scanning goes on, so that the records after it are there for the type
/// inference, up to `after_err` records. A record with more fields than
/// `ncols` is cut to `ncols` fields.
fn CsvScanner::scan_some(
  self : CsvScanner,
  limit : Int32,
  after_err : Int32,
  ncols : Int32,
) -> Unit {
  while self.pos < self.len && self.nrecords() < limit {
    if self.struct_kind != 0 && self.nrecords() >= after_err {
      return
    }
    self.scan_record()
    let r = self.nrecords() - 1
    let first = self.rec_first[r]
    let n = self.nfields(r)
    if self.struct_kind == 0 {
      match self.bad_quote {
        Some((_, _, k, _)) if k < ncols => {
          self.struct_kind = 2
          self.struct_rec = r
          self.struct_col = k
        }
        _ =>
          if n > ncols {
            self.struct_kind = 1
            self.struct_rec = r
            self.struct_col = ncols
          }
      }
    }
    if n > ncols {
      // the fields after the columns are dropped
      let keep = first + ncols
      while self.fstart.length() > keep {
        ignore(self.fstart.pop())
        ignore(self.fend.pop())
        ignore(self.fflag.pop())
      }
    }
  }
}
