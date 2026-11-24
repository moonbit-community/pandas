// Reading dates and datetimes from text, and building them from numbers.
//
// polars 2.1.0 no longer casts a string to a date; `str.to_date()` and
// `str.to_datetime()` read it (with a format guessed from the values). The
// parsers here read the same texts for the common shapes: year first
// (`2024-01-15`) or day first (`15-01-2024`), with `-`, `/` or `.`, for a
// datetime optionally followed by a time. As in polars the format is found in the
// first value that has one (year first or day first, and for a datetime the
// shape of its text) and every value of the column is read with that format
// only. See `docs/golden/known-diffs/date_parse.md` for the differences.

///|
/// The largest year `chrono` (the library polars uses) can hold is 262142 and
/// the smallest -262143; a text or a call beyond is not a date.
let date_max_year : Int32 = 262142

///|
let date_min_year : Int32 = -262143

///|
/// A position in a text, read one code unit at a time, and what the reading
/// has seen of the text's shape (`sep`: the separator of the date, `tsep`:
/// 84 for `T`, 32 for white space, 0 for no time; `secs`: the time has
/// seconds).
priv struct DpCursor {
  s : String
  len : Int32
  mut pos : Int32
  mut sep : Int32
  mut tsep : Int32
  mut secs : Bool
}

///|
fn DpCursor::new(s : String) -> DpCursor {
  { s, len: s.length(), pos: 0, sep: 0, tsep: 0, secs: false, }
}

///|
/// The code unit at the position, or -1 at the end.
fn DpCursor::peek(self : DpCursor) -> Int32 {
  if self.pos < self.len {
    self.s.unsafe_get(self.pos).to_int()
  } else {
    -1
  }
}

///|
fn DpCursor::at_end(self : DpCursor) -> Bool {
  self.pos >= self.len
}

///|
/// Skips white space (Unicode `White_Space`, as `chrono` does).
fn DpCursor::skip_space(self : DpCursor) -> Unit {
  while self.pos < self.len && str_is_space(self.peek()) {
    self.pos += 1
  }
}

///|
/// Consumes the code unit `c`; false (nothing consumed) when it is not next.
fn DpCursor::eat(self : DpCursor, c : Int32) -> Bool {
  if self.peek() == c {
    self.pos += 1
    true
  } else {
    false
  }
}

///|
/// Reads `min` to `max` ASCII digits (as many as there are, up to `max`);
/// `None` when there are fewer than `min`.
fn DpCursor::digits(self : DpCursor, min : Int32, max : Int32) -> Int32? {
  let mut n = 0
  let mut count = 0
  while count < max {
    let c = self.peek()
    if c < 48 || c > 57 {
      break
    }
    n = n * 10 + (c - 48)
    count += 1
    self.pos += 1
  }
  if count >= min {
    Some(n)
  } else {
    None
  }
}

///|
/// A year: with `sign` (`+` or `-` was read) any number of digits (at least
/// one); without, one to four. `None` for no digit or a year beyond
/// `date_max_year` / `date_min_year` (the digits are consumed all the same).
fn DpCursor::year(self : DpCursor, sign : Int32) -> Int32? {
  if sign == 0 {
    return self.digits(1, 4)
  }
  let mut n = 0
  let mut count = 0
  while true {
    let c = self.peek()
    if c < 48 || c > 57 {
      break
    }
    // stop adding once the year is out of range (no overflow on long runs)
    if n <= -date_min_year {
      n = n * 10 + (c - 48)
    }
    count += 1
    self.pos += 1
  }
  if count == 0 {
    None
  } else if sign > 0 {
    if n <= date_max_year {
      Some(n)
    } else {
      None
    }
  } else if n <= -date_min_year {
    Some(-n)
  } else {
    None
  }
}

///|
/// Whether the code unit is a separator of the date part: `-`, `/` or `.`.
fn dp_separator(c : Int32) -> Bool {
  c == 45 || c == 47 || c == 46
}

///|
/// The two kinds of date text polars looks for (`%d-%m-%Y` and `%Y-%m-%d`,
/// each with the three separators), the first value that has one decides which
/// the whole column is read with.
priv enum DpClass {
  DayFirst
  YearFirst
}

///|
/// A year of one to four digits, or with a sign any number of digits.
fn dp_year(c : DpCursor, lenient : Bool) -> Int32? {
  if !lenient {
    return c.digits(4, 4)
  }
  c.skip_space()
  let sign = if c.eat(43) { 1 } else if c.eat(45) { -1 } else { 0 }
  c.year(sign)
}

///|
/// The day-first date `D-M-Y` (`D/M/Y`, `D.M.Y`) at the position, as days
/// since the epoch.
///
/// - `lenient` true (the date reader and the guess for datetimes): white space
///   before each number, a year of one to four digits, or with a sign any
///   number of digits.
/// - `lenient` false (the datetime reader): a year of exactly four digits.
fn dp_day_first(c : DpCursor, lenient : Bool) -> Int32? {
  if lenient {
    c.skip_space()
  }
  guard c.digits(1, 2) is Some(d) else { return None }
  let sep = c.peek()
  if !dp_separator(sep) {
    return None
  }
  c.pos += 1
  if lenient {
    c.skip_space()
  }
  guard c.digits(1, 2) is Some(m) else { return None }
  if !c.eat(sep) {
    return None
  }
  c.sep = sep
  guard dp_year(c, lenient) is Some(y) else { return None }
  ymd_days(y, m, d)
}

///|
/// The year-first date `Y-M-D` (`Y/M/D`, `Y.M.D`) at the position, as days
/// since the epoch; `lenient` as for `dp_day_first`.
fn dp_year_first(c : DpCursor, lenient : Bool) -> Int32? {
  guard dp_year(c, lenient) is Some(y) else { return None }
  let sep = c.peek()
  if !dp_separator(sep) {
    return None
  }
  c.pos += 1
  c.sep = sep
  if lenient {
    c.skip_space()
  }
  guard c.digits(1, 2) is Some(m) else { return None }
  if !c.eat(sep) {
    return None
  }
  if lenient {
    c.skip_space()
  }
  guard c.digits(1, 2) is Some(d) else { return None }
  ymd_days(y, m, d)
}

///|
fn dp_date_part(c : DpCursor, lenient : Bool, cls : DpClass) -> Int32? {
  match cls {
    DayFirst => dp_day_first(c, lenient)
    YearFirst => dp_year_first(c, lenient)
  }
}

///|
/// Reads a date text of the class `cls` (nothing may follow), as days since the
/// epoch: `D-M-Y` or `Y-M-D` with `-`, `/` or `.` (the separator may differ
/// from one text to the next), one or two digits for the day and the month,
/// white space before any of the three numbers (`" 2024- 01- 15"`), the year
/// one to four digits, or a sign and any number of digits (from `-262143` to
/// `+262142`).
fn dp_read_date(s : String, cls : DpClass) -> Int32? {
  let c = DpCursor::new(s)
  guard dp_date_part(c, true, cls) is Some(days) else { return None }
  if c.at_end() {
    Some(days)
  } else {
    None
  }
}

///|
/// The class of a date text: day first when that reads it, else year first
/// (polars tries `%d-%m-%Y` first: `24-01-15` is the 24th of January of the year
/// 15, while `99-12-31`, with no day 99, is year first); `None` for no date.
fn date_class(s : String) -> DpClass? {
  if dp_read_date(s, DayFirst) is Some(_) {
    Some(DayFirst)
  } else if dp_read_date(s, YearFirst) is Some(_) {
    Some(YearFirst)
  } else {
    None
  }
}

///|
/// The time part after the date: `H:M`, `H:M:S` or `H:M:S.f` (one or two
/// digits each, the fraction any number of digits, cut to microseconds), then
/// an optional UTC offset: `Z`, `z`, `+hh`, `+hhmm`, `+hh:mm` (a space before
/// it allowed). Returns the microseconds since midnight and whether an offset
/// was there.
fn dp_time_part(c : DpCursor, lenient : Bool) -> (Int64, Bool)? {
  if lenient {
    c.skip_space()
  }
  guard c.digits(1, 2) is Some(hh) else { return None }
  if !c.eat(58) {
    return None
  }
  if lenient {
    c.skip_space()
  }
  guard c.digits(1, 2) is Some(mm) else { return None }
  let mut ss = 0
  let mut frac = 0
  if c.eat(58) {
    c.secs = true
    if lenient {
      c.skip_space()
    }
    guard c.digits(1, 2) is Some(s2) else { return None }
    ss = s2
    if c.eat(46) {
      // any number of digits; only the first six count
      let mut count = 0
      let mut scale = 100000
      while true {
        let u = c.peek()
        if u < 48 || u > 57 {
          break
        }
        if scale > 0 {
          frac += (u - 48) * scale
          scale = scale / 10
        }
        count += 1
        c.pos += 1
      }
      if count == 0 {
        return None
      }
    }
  }
  if hh > 23 || mm > 59 || ss > 60 {
    return None
  }
  let micros = hh.to_int64() * 3600000000L +
    mm.to_int64() * 60000000L +
    ss.to_int64() * 1000000L +
    frac.to_int64()
  let save = c.pos
  while c.peek() == 32 {
    c.pos += 1
  }
  let u = c.peek()
  if u == 90 || u == 122 {
    c.pos += 1
    return Some((micros, true))
  }
  if u == 43 || u == 45 {
    c.pos += 1
    // any two digits for the hour (`+99` has a format polars then refuses), at
    // most 59 for the minutes
    guard c.digits(2, 2) is Some(_) else { return None }
    if c.eat(58) || (c.peek() >= 48 && c.peek() <= 57) {
      guard c.digits(2, 2) is Some(om) else { return None }
      if om > 59 {
        return None
      }
    }
    return Some((micros, true))
  }
  c.pos = save
  Some((micros, false))
}

///|
/// What was read of a datetime text: microseconds since the epoch (an offset,
/// if any, is not applied), whether an offset was there, and the shape of the
/// text (see `DpCursor`).
priv struct DpRead {
  micros : Int64
  zone : Bool
  sep : Int32
  tsep : Int32
  secs : Bool
}

///|
/// Reads a datetime text of the class `cls`. `lenient` false is what polars'
/// fast reader takes; true is the wider reading of a chrono format.
fn dp_datetime(s : String, lenient : Bool, cls : DpClass) -> DpRead? {
  let c = DpCursor::new(s)
  guard dp_date_part(c, lenient, cls) is Some(days) else { return None }
  let base = days.to_int64() * 86400000000L
  if c.at_end() {
    return Some({ micros: base, zone: false, sep: c.sep, tsep: 0, secs: false, })
  }
  // `T`, or a space (any white space for the lenient reading)
  if c.eat(84) {
    c.tsep = 84
  } else if lenient {
    if !str_is_space(c.peek()) {
      return None
    }
    c.skip_space()
    c.tsep = 32
  } else if c.eat(32) {
    c.tsep = 32
  } else {
    return None
  }
  guard dp_time_part(c, lenient) is Some((micros, zone)) else { return None }
  if !c.at_end() {
    return None
  }
  Some({ micros: base + micros, zone, sep: c.sep, tsep: c.tsep, secs: c.secs, })
}

///|
/// The format polars finds in the first value of a datetime column that has
/// one, and so reads every value of the column with: its class, whether it has
/// a UTC offset (`YearFirst` only), and the shape of that text.
priv struct DtFormat {
  cls : DpClass
  zone : Bool
  sep : Int32
  tsep : Int32
  secs : Bool
  // the text is also read by the fast reader
  fast : Bool
}

///|
/// The format of a datetime text, `None` when polars finds none: day first
/// without an offset, year first without an offset, then year first with one.
fn datetime_format(s : String) -> DtFormat? {
  for cls in [DayFirst, YearFirst] {
    if dp_datetime(s, true, cls) is Some(r) && !r.zone {
      let fast = match dp_datetime(s, false, cls) {
        Some(f) => !f.zone
        None => false
      }
      return Some({
        cls,
        zone: false,
        sep: r.sep,
        tsep: r.tsep,
        secs: r.secs,
        fast,
      })
    }
  }
  if dp_datetime(s, true, YearFirst) is Some(r) {
    return Some({
      cls: YearFirst,
      zone: true,
      sep: r.sep,
      tsep: r.tsep,
      secs: r.secs,
      fast: false,
    })
  }
  None
}

///|
/// Reads the datetime text `s` of a column whose format is `f` (no offset), as
/// polars' `str.to_datetime(time_unit="us")` does: the fast reader (a date of
/// the class of `f` with a year of exactly four digits, then `T` or one space
/// and `H:M`, `H:M:S` or `H:M:S.f` one or two digits each, the fraction any
/// number of digits cut to microseconds, seconds up to 60 where 60 carries into
/// the minute; no white space), and, for a text of the shape of the text that
/// gave the format (the same separator of the date, `T` or space or none, with
/// or without seconds), the wider reading of the format itself (white space
/// before the numbers, a year with a sign or fewer than four digits). That
/// wider reading is only there when the text that gave the format is itself read
/// by the fast reader, or has seconds after a `T` and `-` as the separator
/// (the one chrono format polars always has). A text with an offset is
/// not read. Returns the microseconds since 1970-01-01T00:00:00.
fn dt_read(s : String, f : DtFormat) -> Int64? {
  if (f.tsep == 84 && f.secs && f.sep == 45) || f.fast {
    match dp_datetime(s, true, f.cls) {
      Some(r) =>
        if !r.zone && r.sep == f.sep && r.tsep == f.tsep && r.secs == f.secs {
          return Some(r.micros)
        }
      None => ()
    }
  }
  match dp_datetime(s, false, f.cls) {
    Some(r) => if r.zone { None } else { Some(r.micros) }
    None => None
  }
}

///|
/// The days since the epoch of `year`-`month`-`day`, or `None` when it is not a
/// date (years from -262143 to 262142 only, the range of `chrono`; the
/// microseconds of the last of them still fit an `Int64`).
fn ymd_days(year : Int32, month : Int32, day : Int32) -> Int32? {
  if year < date_min_year ||
    year > date_max_year ||
    month < 1 ||
    month > 12 ||
    day < 1 ||
    day > days_in_month(year, month) {
    None
  } else {
    Some(days_from_civil(year, month, day))
  }
}

///|
/// The date `year`-`month`-`day` (proleptic Gregorian calendar, years
/// -262143 to 262142) as a `Date` value.
///
/// ```mbt check
/// test {
///   assert_eq(@pl.AnyValue::date_ymd(2024, 1, 15), @pl.AnyValue::Date(19737))
/// }
/// ```
///
/// # Errors
/// `ComputeError` (`invalid date: 2024-2-30`, the numbers as given) for a
/// month outside 1 to 12, a day the month does not have, or a year beyond
/// the range.
pub fn AnyValue::date_ymd(
  year : Int32,
  month : Int32,
  day : Int32,
) -> AnyValue raise PolarsError {
  match ymd_days(year, month, day) {
    Some(d) => AnyValue::Date(d)
    None => raise ComputeError("invalid date: \{year}-\{month}-\{day}")
  }
}

///|
/// The instant `year`-`month`-`day` `hour`:`minute`:`second` and
/// `microsecond` microseconds (no time zone) as a `Datetime` value. `hour` is
/// 0 to 23, `minute` and `second` 0 to 59 and `microsecond` 0 to 999999; the
/// date is as in `date_ymd`.
///
/// ```mbt check
/// test {
///   assert_eq(
///     @pl.AnyValue::datetime_ymd(2024, 1, 15, hour=10),
///     @pl.AnyValue::Datetime(1705312800000000L),
///   )
/// }
/// ```
///
/// # Errors
/// `ComputeError` (`invalid datetime: 2024-2-30 0:0:0.0`, the numbers as
/// given) when the date or the time is not valid.
pub fn AnyValue::datetime_ymd(
  year : Int32,
  month : Int32,
  day : Int32,
  hour~ : Int32 = 0,
  minute~ : Int32 = 0,
  second~ : Int32 = 0,
  microsecond~ : Int32 = 0,
) -> AnyValue raise PolarsError {
  match ymd_days(year, month, day) {
    Some(d) =>
      if hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59 ||
        microsecond < 0 ||
        microsecond > 999999 {
        raise ComputeError(
          "invalid datetime: \{year}-\{month}-\{day} \{hour}:\{minute}:\{second}.\{microsecond}",
        )
      } else {
        AnyValue::Datetime(
          d.to_int64() * 86400000000L +
          hour.to_int64() * 3600000000L +
          minute.to_int64() * 60000000L +
          second.to_int64() * 1000000L +
          microsecond.to_int64(),
        )
      }
    None =>
      raise ComputeError(
        "invalid datetime: \{year}-\{month}-\{day} \{hour}:\{minute}:\{second}.\{microsecond}",
      )
  }
}

///|
/// `str.to_date()` (`to` is `Date`) and `str.to_datetime(time_unit="us")`
/// (`to` is `Datetime`) on an evaluated `String` series, from `ExprStr`, as
/// polars' expression evaluates them.
///
/// polars looks for a format in the values: the first value that has one gives
/// it (`DpClass` and, for a datetime, the shape of the text), and every value
/// is read with that format only. It raises when no value has one, or, for a
/// `Datetime`, when that format has a time zone; with `strict=false` such a
/// column gives only nulls. A value the format cannot read is null, or an
/// `InvalidOperation` in strict mode. An empty or all-null series gives an
/// all-null column of the target type.
///
/// # Errors
/// `SchemaMismatch` when the series is not a `String` series (the text of
/// the other unary string functions); strict: `ComputeError` when no value has
/// a format (`could not find an appropriate format to parse dates, please
/// define a format`) or the format of a datetime has a UTC offset (`` `strptime`
/// / `to_datetime` was called with no format and no time zone, but a time zone
/// is part of the data. ``); `InvalidOperation` for the values that cannot be
/// read.
fn str_to_temporal(
  s : Series,
  to : DataType,
  strict : Bool,
) -> Series raise PolarsError {
  let a = str_array_unary(s)
  let n = a.length()
  if s.null_count() == n {
    return Series::make(s.name, null_column(to, n))
  }
  let datetime = to == Datetime
  let no_format = "could not find an appropriate format to parse dates, please define a format"
  let log = CastLog::new()
  let col = if datetime {
    // the format of the first value that has one
    let mut format : DtFormat? = None
    for i in 0..<n {
      if a.is_valid(i) {
        if datetime_format(a.value(i)) is Some(f) {
          format = Some(f)
          break
        }
      }
    }
    match format {
      None => {
        if strict {
          raise ComputeError(no_format)
        }
        return Series::make(s.name, null_column(to, n))
      }
      Some(f) => {
        if f.zone {
          if strict {
            raise ComputeError(
              "`strptime` / `to_datetime` was called with no format and no time zone, but a time zone is part of the data.",
            )
          }
          return Series::make(s.name, null_column(to, n))
        }
        Column::Datetime(try_map_str(a, v => dt_read(v, f), log))
      }
    }
  } else {
    let mut cls : DpClass? = None
    for i in 0..<n {
      if a.is_valid(i) {
        if date_class(a.value(i)) is Some(c) {
          cls = Some(c)
          break
        }
      }
    }
    match cls {
      None => {
        if strict {
          raise ComputeError(no_format)
        }
        return Series::make(s.name, null_column(to, n))
      }
      Some(c) => Column::Date(try_map_str(a, v => dp_read_date(v, c), log))
    }
  }
  if strict {
    log.check(s.name, DataType::String, to, n)
  }
  Series::make(s.name, col)
}
