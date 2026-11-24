///|
/// A calendar or clock field of a `Date` or `Datetime` column.
priv enum DtField {
  Year
  Month
  Day
  Weekday
  OrdinalDay
  Hour
  Minute
  Second
}

///|
/// polars' name of the field (used in its error text).
fn DtField::name(self : DtField) -> String {
  match self {
    Year => "year"
    Month => "month"
    Day => "day"
    Weekday => "weekday"
    OrdinalDay => "ordinal_day"
    Hour => "hour"
    Minute => "minute"
    Second => "second"
  }
}

///|
/// First and last day (since 1970-01-01) of the calendar polars can break
/// down into year, month and day: -262143-01-01 to 262142-12-31 (chrono's
/// range). Outside it those fields (and the clock fields) are null, while the
/// weekday is still computed from the day number.
let dt_min_day : Int32 = -96465292

///|
/// See `dt_min_day`.
let dt_max_day : Int32 = 95026236

///|
/// Microseconds in a day.
const MICROS_PER_DAY : Int64 = 86_400_000_000L

///|
/// The field of the day `days` since the epoch (`Year`..`OrdinalDay`,
/// `Weekday`; ISO weekday: Monday is 1, Sunday is 7), or `None` outside the
/// supported calendar.
fn dt_day_field(days : Int32, field : DtField) -> Int32? {
  if field is Weekday {
    // 1970-01-01 was a Thursday. polars computes `(days - 4) mod 7` in 32-bit
    // arithmetic, so the four smallest days wrap around before the reduction;
    // the same wrap is kept here (`days - 4` wraps in `Int32`).
    let r = ((days - 4) % 7 + 7) % 7
    return Some(r + 1)
  }
  if days < dt_min_day || days > dt_max_day {
    return None
  }
  let (y, m, d) = civil_from_days(days)
  match field {
    Year => Some(y)
    Month => Some(m)
    Day => Some(d)
    OrdinalDay => Some(days - days_from_civil(y, 1, 1) + 1)
    _ => None
  }
}

///|
/// A field of each date or datetime of the column, as `Int32` (polars gives
/// `Int8`/`Int16` for most of them, which this library maps to `Int32`).
/// `Hour`, `Minute` and `Second` need a `Datetime`; a day outside the
/// calendar of `dt_day_field` gives null for every field but the weekday.
///
/// # Errors
/// `InvalidOperation` for a column that is not `Date` (or `Datetime`), and for
/// a clock field of a `Date` column.
fn dt_field(s : Series, field : DtField) -> Series raise PolarsError {
  let clock = field is (Hour | Minute | Second)
  match s.col {
    Date(a) if !clock => {
      let n = a.length()
      let b : @arrow.PrimBuilder[Int32] = @arrow.PrimBuilder::new(capacity=n)
      for i in 0..<n {
        if a.is_valid(i) {
          b.push_option(dt_day_field(a.value(i), field))
        } else {
          b.push_null()
        }
      }
      Series::make(s.name, Int32(b.finish()))
    }
    Datetime(a) => {
      let n = a.length()
      let b : @arrow.PrimBuilder[Int32] = @arrow.PrimBuilder::new(capacity=n)
      for i in 0..<n {
        if !a.is_valid(i) {
          b.push_null()
          continue
        }
        let us = a.value(i)
        let days = floor_div64(us, MICROS_PER_DAY).to_int()
        if !clock {
          b.push_option(dt_day_field(days, field))
        } else if days < dt_min_day || days > dt_max_day {
          b.push_null()
        } else {
          let tod = floor_mod64(us, MICROS_PER_DAY)
          let v = match field {
            Hour => tod / 3_600_000_000L
            Minute => tod / 60_000_000L % 60L
            _ => tod / 1_000_000L % 60L
          }
          b.push(v.to_int())
        }
      }
      Series::make(s.name, Int32(b.finish()))
    }
    other =>
      raise InvalidOperation(
        "`\{field.name()}` operation not supported for dtype `\{other.dtype()}`",
      )
  }
}
