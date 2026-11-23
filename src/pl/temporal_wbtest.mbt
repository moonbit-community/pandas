///|
test "civil round trip" {
  assert_eq(days_from_civil(1970, 1, 1), 0)
  assert_eq(days_from_civil(2024, 2, 29), 19782)
  assert_eq(days_from_civil(1969, 12, 31), -1)
  assert_eq(days_from_civil(1900, 1, 1), -25567)
  assert_eq(days_from_civil(9999, 12, 31), 2932896)
  assert_eq(civil_from_days(-1), (1969, 12, 31))
  assert_eq(civil_from_days(19782), (2024, 2, 29))
  assert_eq(format_date(-25567), "1900-01-01")
  assert_eq(parse_date("2024-02-29"), Some(19782))
  assert_eq(parse_date("2023-02-29"), None)
  assert_eq(parse_date("2024-2-1"), None)
  assert_eq(floor_div64(-1L, 86_400_000_000L), -1L)
  assert_eq(floor_mod64(-1L, 86_400_000_000L), 86_399_999_999L)
}

///|
test "format_date pads and signs years" {
  assert_eq(format_date(0), "1970-01-01")
  assert_eq(format_date(days_from_civil(5, 3, 7)), "0005-03-07")
  assert_eq(format_date(days_from_civil(0, 1, 1)), "0000-01-01")
  assert_eq(format_date(days_from_civil(-1, 12, 31)), "-0001-12-31")
  assert_eq(format_date(days_from_civil(12345, 1, 2)), "12345-01-02")
  assert_eq(format_date(2932896), "9999-12-31")
}

///|
test "parse_date rejects malformed input" {
  assert_eq(parse_date(""), None)
  assert_eq(parse_date("2024-13-01"), None)
  assert_eq(parse_date("2024-00-10"), None)
  assert_eq(parse_date("2024-01-00"), None)
  assert_eq(parse_date("2024-01-32"), None)
  assert_eq(parse_date("2024-04-31"), None)
  assert_eq(parse_date("1900-02-29"), None)
  assert_eq(parse_date("2000-02-29"), Some(days_from_civil(2000, 2, 29)))
  assert_eq(parse_date("2024/01/01"), None)
  assert_eq(parse_date("2024-01-01 "), None)
  assert_eq(parse_date(" 2024-01-01"), None)
  assert_eq(parse_date("2024-01-011"), None)
  assert_eq(parse_date("+024-01-01"), None)
  assert_eq(parse_date("20a4-01-01"), None)
  assert_eq(parse_date("1970-01-01"), Some(0))
  assert_eq(parse_date("0000-01-01"), Some(days_from_civil(0, 1, 1)))
}

///|
test "parse_date works on a view" {
  let s = "xx2024-02-29yy"
  assert_eq(parse_date(s[2:12]), Some(19782))
}

///|
test "floor_div64 and floor_mod64 on signs" {
  assert_eq(floor_div64(7L, 2L), 3L)
  assert_eq(floor_div64(-7L, 2L), -4L)
  assert_eq(floor_div64(7L, -2L), -4L)
  assert_eq(floor_div64(-7L, -2L), 3L)
  assert_eq(floor_mod64(7L, 2L), 1L)
  assert_eq(floor_mod64(-7L, 2L), 1L)
  assert_eq(floor_mod64(0L, 5L), 0L)
  assert_eq(floor_div64(-86_400_000_000L, 86_400_000_000L), -1L)
  assert_eq(floor_mod64(-86_400_000_000L, 86_400_000_000L), 0L)
}

///|
fn clamp_days(x : Int32) -> Int32 {
  // map an arbitrary Int into [-1_000_000, 3_000_000]
  let span = 4_000_001L
  (floor_mod64(x.to_int64(), span) - 1_000_000L).to_int()
}

///|
test "quickcheck: civil round trip" {
  @quickcheck.check((x : Int32) => {
    let days = clamp_days(x.to_int())
    let (y, m, d) = civil_from_days(days)
    days_from_civil(y, m, d) == days
  })
}

///|
test "quickcheck: format/parse round trip" {
  @quickcheck.check((x : Int32) => {
    let days = clamp_days(x.to_int())
    let (y, _, _) = civil_from_days(days)
    if y >= 0 && y <= 9999 {
      parse_date(format_date(days)[:]) == Some(days)
    } else {
      true
    }
  })
}

///|
test "parse_date checks the length of every month" {
  // 30-day months reject day 31, including November
  assert_eq(parse_date("2024-04-31"), None)
  assert_eq(parse_date("2024-06-31"), None)
  assert_eq(parse_date("2024-09-31"), None)
  assert_eq(parse_date("2024-11-31"), None)
  assert_eq(parse_date("2024-11-30"), Some(days_from_civil(2024, 11, 30)))
  // 31-day months accept day 31
  for m in [1, 3, 5, 7, 8, 10, 12] {
    let text = "2024-" + (if m < 10 { "0" } else { "" }) + m.to_string() + "-31"
    assert_eq(parse_date(text), Some(days_from_civil(2024, m, 31)))
  }
}
