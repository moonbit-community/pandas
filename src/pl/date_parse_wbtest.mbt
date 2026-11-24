///|
test "parse_iso_date reads the date texts polars reads" {
  assert_eq(parse_iso_date("2024-01-15"), Some(19737))
  assert_eq(parse_iso_date("2024-1-5"), Some(19727))
  assert_eq(parse_iso_date("2024/01/15"), Some(19737))
  assert_eq(parse_iso_date("2024.01.15"), Some(19737))
  assert_eq(parse_iso_date("0001-01-01"), Some(-719162))
  assert_eq(parse_iso_date("9999-12-31"), Some(2932896))
  // day first
  assert_eq(parse_iso_date("15-01-2024"), Some(19737))
  assert_eq(parse_iso_date("15/01/2024"), Some(19737))
  assert_eq(parse_iso_date("15.01.2024"), Some(19737))
  assert_eq(parse_iso_date("5-1-2024"), Some(19727))
  assert_eq(parse_iso_date("31-12-1999"), Some(10956))
  // leading white space, a signed year of any length (as polars does)
  assert_eq(parse_iso_date(" 2024-01-15"), Some(19737))
  assert_eq(parse_iso_date("\t2024- 01- 15"), Some(19737))
  assert_eq(parse_iso_date("+2024-01-15"), Some(19737))
  assert_eq(parse_iso_date("-0001-01-01"), Some(-719893))
  assert_eq(parse_iso_date("+10000-01-01"), Some(2932897))
  assert_eq(parse_iso_date("+20240-01-15"), Some(6672994))
  // a year of one to three digits: day first when that is a date, else year first
  assert_eq(parse_iso_date("99-12-31"), Some(-683004))
  assert_eq(parse_iso_date("999-12-31"), Some(-354286))
  assert_eq(parse_iso_date("+999-01-01"), Some(-354650))
  assert_eq(parse_iso_date("+99-01-01"), Some(-683368))
  assert_eq(parse_iso_date("-999-01-01"), Some(-1084405))
  assert_eq(parse_iso_date("9-1-1"), Some(-719154))
  assert_eq(parse_iso_date("1-1-1"), Some(-719162))
  assert_eq(parse_iso_date("15-01-24"), Some(-710748))
  assert_eq(parse_iso_date("24-01-15"), Some(-714026))
  assert_eq(parse_iso_date("99/12/31"), Some(-683004))
  assert_eq(parse_iso_date("15-01-999"), Some(-354636))
  // the year bounds of chrono: -262143 to 262142
  assert_eq(parse_iso_date("+262142-12-31"), Some(95026236))
  assert_eq(parse_iso_date("-262143-01-01"), Some(-96465292))
  assert_eq(parse_iso_date("+262143-01-01"), None)
  assert_eq(parse_iso_date("+262143-12-31"), None)
  assert_eq(parse_iso_date("-262144-01-01"), None)
  assert_eq(parse_iso_date("+300000-01-01"), None)
  // not a date
  assert_eq(parse_iso_date(""), None)
  assert_eq(parse_iso_date("2024-02-30"), None)
  assert_eq(parse_iso_date("2024-01-15 "), None)
  assert_eq(parse_iso_date("2024-01-15 10:20:30"), None)
  assert_eq(parse_iso_date("2024-01/15"), None)
  assert_eq(parse_iso_date("15-01/2024"), None)
  assert_eq(parse_iso_date("20240115"), None)
  assert_eq(parse_iso_date("10000-01-01"), None)
  assert_eq(parse_iso_date("2024-001-15"), None)
  assert_eq(parse_iso_date("2024-13-01"), None)
  assert_eq(parse_iso_date("15-01-02024"), None)
  assert_eq(parse_iso_date("005-01-2024"), None)
  assert_eq(parse_iso_date("31-02-2024"), None)
  assert_eq(parse_iso_date("12-31-99"), None)
  assert_eq(parse_iso_date("2024-15-01"), None)
}

///|
test "parse_iso_datetime reads the datetime texts polars reads" {
  assert_eq(parse_iso_datetime("2024-01-15"), Some(1705276800000000L))
  assert_eq(parse_iso_datetime("2024-01-15 10:20:30"), Some(1705314030000000L))
  assert_eq(parse_iso_datetime("2024-01-15T10:20:30"), Some(1705314030000000L))
  assert_eq(parse_iso_datetime("2024-01-15T10:20"), Some(1705314000000000L))
  assert_eq(parse_iso_datetime("2024-1-5 1:2:3"), Some(1704416523000000L))
  assert_eq(
    parse_iso_datetime("2024-01-15T10:20:30.123456789"),
    Some(1705314030123456L),
  )
  assert_eq(
    parse_iso_datetime("2024-01-15 10:20:30.5"),
    Some(1705314030500000L),
  )
  // day first, other separators
  assert_eq(parse_iso_datetime("15-01-2024"), Some(1705276800000000L))
  assert_eq(
    parse_iso_datetime("15/01/2024 10:20:30.5"),
    Some(1705314030500000L),
  )
  assert_eq(parse_iso_datetime("2024.01.15"), Some(1705276800000000L))
  // seconds up to 60 carry into the minute
  assert_eq(parse_iso_datetime("2024-01-15T10:20:60"), Some(1705314060000000L))
  assert_eq(parse_iso_datetime("0000-01-01"), Some(-62167219200000000L))
  assert_eq(parse_iso_datetime("15-01-0000"), Some(-62166009600000000L))
  assert_eq(
    parse_iso_datetime("9999-12-31T23:59:59.999999"),
    Some(253402300799999999L),
  )
  // not read: a UTC offset (polars refuses it without a time zone)
  assert_eq(parse_iso_datetime("2024-01-15T10:20:30Z"), None)
  assert_eq(parse_iso_datetime("2024-01-15T10:20:30z"), None)
  assert_eq(parse_iso_datetime("2024-01-15T10:20:30+02:00"), None)
  assert_eq(parse_iso_datetime("2024-01-15T10:20:30 +0200"), None)
  assert_eq(parse_iso_datetime("2024-01-15T10:20:30-00:00"), None)
  // not a datetime
  assert_eq(parse_iso_datetime(""), None)
  assert_eq(parse_iso_datetime(" 2024-01-15"), None)
  assert_eq(parse_iso_datetime("+2024-01-15"), None)
  assert_eq(parse_iso_datetime("2024-01-15 10"), None)
  assert_eq(parse_iso_datetime("2024-01-15T"), None)
  assert_eq(parse_iso_datetime("2024-01-15t10:20:30"), None)
  assert_eq(parse_iso_datetime("2024-01-15  10:20:30"), None)
  assert_eq(parse_iso_datetime("2024-01-15T24:00:00"), None)
  assert_eq(parse_iso_datetime("2024-01-15T10:60:00"), None)
  assert_eq(parse_iso_datetime("2024-01-15T10:20:30."), None)
  assert_eq(parse_iso_datetime("2024-01-15T10:20:30+2"), None)
  assert_eq(parse_iso_datetime("2024-01-15T10:20:30ZZ"), None)
  assert_eq(parse_iso_datetime("2024-02-30"), None)
  assert_eq(parse_iso_datetime("10000-01-01"), None)
  // a year of fewer than four digits is found as a format but not read
  assert_eq(parse_iso_datetime("99-12-31"), None)
  assert_eq(parse_iso_datetime("999-12-31"), None)
}

///|
test "datetime_format: what polars' format guess finds in a text" {
  // a format without an offset: every text parse_iso_datetime reads
  assert_eq(format_zone("2024-01-15T10:20:30"), Some(false))
  assert_eq(format_zone("15-01-2024"), Some(false))
  // a format that polars finds but whose texts its reader then refuses
  assert_eq(format_zone(" 2024-01-15"), Some(false))
  assert_eq(format_zone("-0001-01-01"), Some(false))
  assert_eq(format_zone("99-12-31"), Some(false))
  assert_eq(format_zone("+262142-12-31"), Some(false))
  // a format with a UTC offset (also the offsets beyond 23:59)
  assert_eq(format_zone("2024-01-15T10:20:30Z"), Some(true))
  assert_eq(format_zone("2024-01-15T10:20:30z"), Some(true))
  assert_eq(format_zone("2024-01-15T10:20:30 +0200"), Some(true))
  assert_eq(format_zone("2024-01-15T10:20:30-00:00"), Some(true))
  assert_eq(format_zone("2024-01-15T10:20:30+24:00"), Some(true))
  assert_eq(format_zone("2024-01-15T23:59:60+23:59"), Some(true))
  assert_eq(format_zone("2024-01-15 10:20:30.123456789+02:00"), Some(true))
  // no format at all
  assert_eq(format_zone("2024-02-30"), None)
  assert_eq(format_zone("abc"), None)
  assert_eq(format_zone(""), None)
  assert_eq(format_zone("2024-01-15 "), None)
  assert_eq(format_zone("2024-01-15T10:20:30+2"), None)
  assert_eq(format_zone("2024-01-15T10:20:30+02:0"), None)
  assert_eq(format_zone("2024-01-15T10:20:30+1:00"), None)
  assert_eq(format_zone("2024-01-15T10:20:30ZZ"), None)
  assert_eq(format_zone("2024-01-15T10:20:30+02:00 "), None)
  assert_eq(format_zone("+262143-01-01"), None)
  assert_eq(format_zone("-262144-01-01"), None)
  // seconds up to 60, offset minutes up to 59: mutation guards for the bounds
  assert_eq(format_zone("2024-01-15T10:20:60"), Some(false))
  assert_eq(format_zone("2024-01-15T10:20:61"), None)
  assert_eq(format_zone("2024-01-15T10:20:30+02:59"), Some(true))
  assert_eq(format_zone("2024-01-15T10:20:30+02:60"), None)
  assert_eq(format_zone("2024-01-15T10:20:30+0260"), None)
  assert_eq(format_zone("2024-01-15T10:20:30+99:59"), Some(true))
  assert_eq(format_zone("2024-01-15T10:20:30+99"), Some(true))
}

///|
/// Whether the format polars finds in `s` has an offset (`None`: no format).
fn format_zone(s : String) -> Bool? {
  match datetime_format(s) {
    Some(f) => Some(f.zone)
    None => None
  }
}

///|
/// Reads a date text on its own, as `str.to_date()` of polars does for a
/// column of that one text. Returns the days since 1970-01-01, or `None` for
/// another text or an invalid date.
fn parse_iso_date(s : String) -> Int32? {
  match date_class(s) {
    Some(cls) => dp_read_date(s, cls)
    None => None
  }
}

///|
/// Reads a datetime text on its own, as a column of that one text: its own
/// format. `None` when it has no format, or has an offset, or the format does not
/// read it.
fn parse_iso_datetime(s : String) -> Int64? {
  match datetime_format(s) {
    Some(f) => if f.zone { None } else { dt_read(s, f) }
    None => None
  }
}
