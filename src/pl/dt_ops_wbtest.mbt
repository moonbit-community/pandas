///|
fn dt_ints(s : Series) -> Array[Int32?] raise PolarsError {
  s.to_int32_array()
}

///|
test "dt_field on dates: before 1970, leap day, year 10000" {
  // 1970-01-01, 1969-12-31, 2024-02-29, 1900-01-01, 9999-12-31, 10000-01-01
  let s = Series::date_nullable("d", [
    Some(0),
    Some(-1),
    Some(19782),
    Some(-25567),
    Some(2932896),
    Some(2932897),
    None,
  ])
  let year = dt_field(s, Year)
  assert_eq(year.dtype(), DataType::Int32)
  assert_eq(year.name(), "d")
  assert_eq(dt_ints(year), [
    Some(1970),
    Some(1969),
    Some(2024),
    Some(1900),
    Some(9999),
    Some(10000),
    None,
  ])
  assert_eq(dt_ints(dt_field(s, Month)), [
    Some(1),
    Some(12),
    Some(2),
    Some(1),
    Some(12),
    Some(1),
    None,
  ])
  assert_eq(dt_ints(dt_field(s, Day)), [
    Some(1),
    Some(31),
    Some(29),
    Some(1),
    Some(31),
    Some(1),
    None,
  ])
  // ISO weekday: Monday is 1, Sunday is 7
  assert_eq(dt_ints(dt_field(s, Weekday)), [
    Some(4),
    Some(3),
    Some(4),
    Some(1),
    Some(5),
    Some(6),
    None,
  ])
  assert_eq(dt_ints(dt_field(s, OrdinalDay)), [
    Some(1),
    Some(365),
    Some(60),
    Some(1),
    Some(365),
    Some(1),
    None,
  ])
}

///|
test "dt_field on datetimes: negative microseconds round down" {
  let s = Series::datetime_nullable("t", [
    Some(0L),
    Some(-1L),
    Some(1709210096123456L),
    Some(-86400000001L),
    Some(59_999_999L),
    None,
  ])
  assert_eq(dt_ints(dt_field(s, Year)), [
    Some(1970),
    Some(1969),
    Some(2024),
    Some(1969),
    Some(1970),
    None,
  ])
  assert_eq(dt_ints(dt_field(s, Day)), [
    Some(1),
    Some(31),
    Some(29),
    Some(30),
    Some(1),
    None,
  ])
  assert_eq(dt_ints(dt_field(s, Hour)), [
    Some(0),
    Some(23),
    Some(12),
    Some(23),
    Some(0),
    None,
  ])
  assert_eq(dt_ints(dt_field(s, Minute)), [
    Some(0),
    Some(59),
    Some(34),
    Some(59),
    Some(0),
    None,
  ])
  assert_eq(dt_ints(dt_field(s, Second)), [
    Some(0),
    Some(59),
    Some(56),
    Some(59),
    Some(59),
    None,
  ])
  assert_eq(dt_ints(dt_field(s, Weekday)), [
    Some(4),
    Some(3),
    Some(4),
    Some(2),
    Some(4),
    None,
  ])
}

///|
test "dt_field: days outside the calendar are null, except the weekday" {
  // the last and first representable days and the ones just outside
  let s = Series::date("d", [95026236, 95026237, -96465292, -96465293])
  assert_eq(dt_ints(dt_field(s, Year)), [
    Some(262142),
    None,
    Some(-262143),
    None,
  ])
  assert_eq(dt_ints(dt_field(s, OrdinalDay)), [Some(365), None, Some(1), None])
  assert_eq(dt_ints(dt_field(s, Weekday)), [Some(1), Some(2), Some(4), Some(3)])
  let t = Series::datetime("t", [
    8210266876799999999L,
    8210266876800000000L,
    @int64.MAX_VALUE,
    @int64.MIN_VALUE,
  ])
  assert_eq(dt_ints(dt_field(t, Hour)), [Some(23), None, None, None])
  assert_eq(dt_ints(dt_field(t, Month)), [Some(12), None, None, None])
  assert_eq(dt_ints(dt_field(t, Weekday)), [Some(1), Some(2), Some(7), Some(7)])
  // the extreme days do not overflow
  let e = Series::date("e", [@int.MAX_VALUE, @int.MIN_VALUE])
  assert_eq(dt_ints(dt_field(e, Year)), [None, None])
  assert_eq(dt_ints(dt_field(e, Weekday)), [Some(5), Some(6)])
  // polars wraps `days - 4` for the four smallest days (-2147483648 + 3 .. )
  let w = Series::date("w", [
    -2147483648, -2147483647, -2147483646, -2147483645, -2147483644,
  ])
  assert_eq(dt_ints(dt_field(w, Weekday)), [
    Some(6),
    Some(7),
    Some(1),
    Some(2),
    Some(6),
  ])
}

///|
test "dt_field: other types and clock fields of a Date are errors" {
  assert_eq(
    sd_raises(() => dt_field(Series::int32("a", [1]), Year)),
    Some("InvalidOperation: `year` operation not supported for dtype `i32`"),
  )
  assert_eq(
    sd_raises(() => dt_field(Series::str("a", ["2024-01-01"]), Month)),
    Some("InvalidOperation: `month` operation not supported for dtype `str`"),
  )
  assert_eq(
    sd_raises(() => dt_field(Series::null("a", 2), OrdinalDay)),
    Some(
      "InvalidOperation: `ordinal_day` operation not supported for dtype `null`",
    ),
  )
  assert_eq(
    sd_raises(() => dt_field(Series::date("a", [0]), Hour)),
    Some("InvalidOperation: `hour` operation not supported for dtype `date`"),
  )
  assert_eq(
    sd_raises(() => dt_field(Series::date("a", [0]), Second)),
    Some("InvalidOperation: `second` operation not supported for dtype `date`"),
  )
}

///|
test "dt_field: empty and all-null columns" {
  assert_eq(dt_field(Series::date("a", []), Year).len(), 0)
  let n = dt_field(Series::datetime_nullable("a", [None, None]), Minute)
  assert_eq(n.dtype(), DataType::Int32)
  assert_eq(n.null_count(), 2)
}
