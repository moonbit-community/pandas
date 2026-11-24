///|
test "date_ymd gives days since 1970-01-01" {
  assert_eq(@pl.AnyValue::date_ymd(1970, 1, 1), @pl.AnyValue::Date(0))
  assert_eq(@pl.AnyValue::date_ymd(2024, 1, 15), @pl.AnyValue::Date(19737))
  assert_eq(@pl.AnyValue::date_ymd(1969, 12, 31), @pl.AnyValue::Date(-1))
  assert_eq(@pl.AnyValue::date_ymd(2024, 2, 29), @pl.AnyValue::Date(19782))
  assert_eq(@pl.AnyValue::date_ymd(1, 1, 1), @pl.AnyValue::Date(-719162))
  assert_eq(@pl.AnyValue::date_ymd(9999, 12, 31), @pl.AnyValue::Date(2932896))
  // years polars reads from text (`0000-01-01`, `+10000-01-01`)
  assert_eq(@pl.AnyValue::date_ymd(0, 1, 1), @pl.AnyValue::Date(-719528))
  assert_eq(@pl.AnyValue::date_ymd(10000, 1, 1), @pl.AnyValue::Date(2932897))
}

///|
test "date_ymd rejects an invalid date with the numbers as given" {
  let msg = fn(y, m, d) raise {
    match raises(() => @pl.AnyValue::date_ymd(y, m, d)) {
      Some(@pl.ComputeError(m)) => m
      _ => fail("expected ComputeError")
    }
  }
  assert_eq(msg(2024, 2, 30), "invalid date: 2024-2-30")
  assert_eq(msg(2023, 2, 29), "invalid date: 2023-2-29")
  assert_eq(msg(1900, 2, 29), "invalid date: 1900-2-29")
  assert_eq(msg(2024, 13, 1), "invalid date: 2024-13-1")
  assert_eq(msg(2024, 0, 1), "invalid date: 2024-0-1")
  assert_eq(msg(2024, 1, 0), "invalid date: 2024-1-0")
  assert_eq(msg(2024, -1, 5), "invalid date: 2024--1-5")
  assert_eq(msg(2024, 4, 31), "invalid date: 2024-4-31")
  // beyond what a `Date` (and the text parser) can hold
  assert_eq(msg(300000, 1, 1), "invalid date: 300000-1-1")
  assert_eq(msg(-300000, 1, 1), "invalid date: -300000-1-1")
}

///|
test "datetime_ymd gives microseconds since the epoch" {
  assert_eq(@pl.AnyValue::datetime_ymd(1970, 1, 1), @pl.AnyValue::Datetime(0L))
  assert_eq(
    @pl.AnyValue::datetime_ymd(2024, 1, 15),
    @pl.AnyValue::Datetime(1705276800000000L),
  )
  assert_eq(
    @pl.AnyValue::datetime_ymd(
      2024,
      1,
      15,
      hour=10,
      minute=20,
      second=30,
      microsecond=123456,
    ),
    @pl.AnyValue::Datetime(1705314030123456L),
  )
  assert_eq(
    @pl.AnyValue::datetime_ymd(
      1969,
      12,
      31,
      hour=23,
      minute=59,
      second=59,
      microsecond=999999,
    ),
    @pl.AnyValue::Datetime(-1L),
  )
  assert_eq(
    @pl.AnyValue::datetime_ymd(2024, 1, 15, hour=10),
    @pl.AnyValue::Datetime(1705312800000000L),
  )
}

///|
test "datetime_ymd rejects an invalid date or time" {
  let msg = fn(f) raise {
    match raises(f) {
      Some(@pl.ComputeError(m)) => m
      _ => fail("expected ComputeError")
    }
  }
  assert_eq(
    msg(() => @pl.AnyValue::datetime_ymd(2024, 2, 30)),
    "invalid datetime: 2024-2-30 0:0:0.0",
  )
  assert_eq(
    msg(() => @pl.AnyValue::datetime_ymd(2024, 1, 15, hour=24)),
    "invalid datetime: 2024-1-15 24:0:0.0",
  )
  assert_eq(
    msg(() => @pl.AnyValue::datetime_ymd(2024, 1, 15, minute=60)),
    "invalid datetime: 2024-1-15 0:60:0.0",
  )
  assert_eq(
    msg(() => @pl.AnyValue::datetime_ymd(2024, 1, 15, second=60)),
    "invalid datetime: 2024-1-15 0:0:60.0",
  )
  assert_eq(
    msg(() => @pl.AnyValue::datetime_ymd(2024, 1, 15, microsecond=1000000)),
    "invalid datetime: 2024-1-15 0:0:0.1000000",
  )
  assert_eq(
    msg(() => @pl.AnyValue::datetime_ymd(2024, 1, 15, hour=-1)),
    "invalid datetime: 2024-1-15 -1:0:0.0",
  )
}

///|
test "str().to_date and to_datetime read ISO text" {
  let s = @pl.Series::str_nullable("d", [
    Some("2024-01-15"),
    None,
    Some("1999-12-31"),
  ])
  let df = @pl.DataFrame::new([s])
  let d = df.select([@pl.col("d").str().to_date()]).column("d")
  assert_eq(d.dtype(), @pl.DataType::Date)
  assert_eq(d.to_list(), [
    @pl.AnyValue::Date(19737),
    @pl.AnyValue::Null,
    @pl.AnyValue::Date(10956),
  ])
  let t = @pl.DataFrame::new([
    @pl.Series::str("t", ["2024-01-15 10:20:30", "2024-01-15"]),
  ])
  let out = t.select([@pl.col("t").str().to_datetime()]).column("t")
  assert_eq(out.to_list(), [
    @pl.AnyValue::Datetime(1705314030000000L),
    @pl.AnyValue::Datetime(1705276800000000L),
  ])
  // `Show` is polars' `str(expr)`, strict or not
  assert_eq(
    @pl.col("d").str().to_date().to_string(),
    "col(\"d\").str.strptime([\"raise\"])",
  )
  assert_eq(
    @pl.col("d").str().to_datetime(strict=false).to_string(),
    "col(\"d\").str.strptime([\"raise\"])",
  )
}

///|
test "str().to_date: strict failure and lenient null" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("d", ["2024-01-15", "2024-02-30", "x"]),
  ])
  let msg = match raises(() => df.select([@pl.col("d").str().to_date()])) {
    Some(@pl.InvalidOperation(m)) => m
    _ => fail("expected InvalidOperation")
  }
  assert_eq(
    msg, "conversion from `str` to `date` failed in column 'd' for 2 out of 3 values: [\"2024-02-30\", \"x\"]",
  )
  let lenient = df
    .select([@pl.col("d").str().to_date(strict=false)])
    .column("d")
  assert_eq(lenient.to_list(), [
    @pl.AnyValue::Date(19737),
    @pl.AnyValue::Null,
    @pl.AnyValue::Null,
  ])
  // nothing to infer a format from: strict gives a ComputeError, lenient a
  // null column of the target type (a Datetime too: `select` of the expression)
  let bad = @pl.DataFrame::new([@pl.Series::str("d", ["x", "y"])])
  let no_format = "ComputeError: could not find an appropriate format to parse dates, please define a format"
  assert_eq(
    raises(() => bad.select([@pl.col("d").str().to_date()])).map(e => {
      e.to_string()
    }),
    Some(no_format),
  )
  assert_eq(
    bad
    .select([@pl.col("d").str().to_date(strict=false)])
    .column("d")
    .null_count(),
    2,
  )
  assert_eq(
    raises(() => bad.select([@pl.col("d").str().to_datetime()])).map(e => {
      e.to_string()
    }),
    Some(no_format),
  )
  let dt = bad
    .select([@pl.col("d").str().to_datetime(strict=false)])
    .column("d")
  assert_eq(dt.dtype(), @pl.DataType::Datetime)
  assert_eq(dt.null_count(), 2)
  // a format with a UTC offset: no time zone is available, strict raises, lenient is null
  let tz = @pl.DataFrame::new([
    @pl.Series::str("d", ["2024-01-15T10:20:30+02:00", "2024-01-15T10:20:30"]),
  ])
  assert_eq(
    raises(() => tz.select([@pl.col("d").str().to_datetime()])).map(e => {
      e.to_string()
    }),
    Some(
      "ComputeError: `strptime` / `to_datetime` was called with no format and no time zone, but a time zone is part of the data.",
    ),
  )
  assert_eq(
    tz
    .select([@pl.col("d").str().to_datetime(strict=false)])
    .column("d")
    .null_count(),
    2,
  )
}

///|
test "str().to_date on a column that is not String" {
  let df = @pl.DataFrame::new([@pl.Series::int64("a", [1L])])
  assert_eq(
    raises(() => df.select([@pl.col("a").str().to_date()])).map(e => {
      e.to_string()
    }),
    Some(
      "SchemaMismatch: invalid series dtype: expected `String`, got `i64` for series with name `a`",
    ),
  )
  // casting a string to a date stays unsupported, as in polars 2.1.0
  let s = @pl.Series::str("d", ["2024-01-15"])
  assert_eq(
    raises(() => s.cast(@pl.DataType::Date)).map(e => e.to_string()),
    Some("InvalidOperation: casting from string to date is not supported."),
  )
}

///|
test "the year bounds are those of chrono and polars: -262143 to 262142" {
  // date_ymd, both sides of both bounds
  assert_eq(
    @pl.AnyValue::date_ymd(262142, 12, 31),
    @pl.AnyValue::Date(95026236),
  )
  assert_eq(
    @pl.AnyValue::date_ymd(-262143, 1, 1),
    @pl.AnyValue::Date(-96465292),
  )
  for
    ymd in [
      (262143, 1, 1),
      (262143, 12, 31),
      (-262144, 12, 31),
      (-262144, 1, 1),
    ] {
    let (y, m, d) = ymd
    assert_true(
      raises(() => @pl.AnyValue::date_ymd(y, m, d)) is Some(@pl.ComputeError(_)),
    )
  }
  // datetime_ymd
  assert_eq(
    @pl.AnyValue::datetime_ymd(
      262142,
      12,
      31,
      hour=23,
      minute=59,
      second=59,
      microsecond=999999,
    ),
    @pl.AnyValue::Datetime(8210266876799999999L),
  )
  assert_eq(
    @pl.AnyValue::datetime_ymd(-262143, 1, 1),
    @pl.AnyValue::Datetime(-8334601228800000000L),
  )
  assert_true(
    raises(() => @pl.AnyValue::datetime_ymd(262143, 1, 1))
    is Some(@pl.ComputeError(_)),
  )
  assert_true(
    raises(() => @pl.AnyValue::datetime_ymd(-262144, 12, 31))
    is Some(@pl.ComputeError(_)),
  )
  // the text readers (to_date, strict): a year beyond has no format
  let df = @pl.DataFrame::new([
    @pl.Series::str("s", ["+262142-12-31", "-262143-01-01"]),
  ])
  assert_eq(df.select([@pl.col("s").str().to_date()]).column("s").to_list(), [
    @pl.AnyValue::Date(95026236),
    @pl.AnyValue::Date(-96465292),
  ])
  for text in ["+262143-01-01", "+262143-12-31", "-262144-01-01"] {
    let one = @pl.DataFrame::new([@pl.Series::str("s", [text])])
    assert_true(
      raises(() => one.select([@pl.col("s").str().to_date()]))
      is Some(@pl.ComputeError(_)),
    )
    assert_true(
      raises(() => one.select([@pl.col("s").str().to_datetime()]))
      is Some(@pl.ComputeError(_)),
    )
  }
}

///|
test "the first text with a format fixes the format of the column (to_date)" {
  let col_of = fn(values : Array[String]) raise @pl.PolarsError {
    @pl.DataFrame::new([@pl.Series::str("a", values)])
  }
  // year first, then a day-first text: not read with that format
  let df = col_of(["2024-01-02", "01-02-2024"])
  assert_true(
    raises(() => df.select([@pl.col("a").str().to_date()]))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_eq(
    df.select([@pl.col("a").str().to_date(strict=false)]).column("a").to_list(),
    [@pl.AnyValue::Date(19724), @pl.AnyValue::Null],
  )
  // and the other way round
  let df2 = col_of(["01-02-2024", "2024-01-02"])
  assert_true(
    raises(() => df2.select([@pl.col("a").str().to_date()]))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_eq(
    df2.select([@pl.col("a").str().to_date(strict=false)]).column("a").to_list(),
    [@pl.AnyValue::Date(19754), @pl.AnyValue::Null],
  )
  // a short year after a year-first text is year first (year 24), not day first
  let df3 = col_of(["2024-01-02", "24-01-15"])
  assert_eq(df3.select([@pl.col("a").str().to_date()]).column("a").to_list(), [
    @pl.AnyValue::Date(19724),
    @pl.AnyValue::Date(-710748),
  ])
  // after a day-first text the same text is day first (the year 15)
  let df4 = col_of(["15-01-2024", "24-01-15"])
  assert_eq(df4.select([@pl.col("a").str().to_date()]).column("a").to_list(), [
    @pl.AnyValue::Date(19737),
    @pl.AnyValue::Date(-714026),
  ])
  // a text that has no format is skipped when looking for the format
  let df5 = col_of(["x", "01-02-2024", "2024-01-02"])
  assert_eq(
    df5.select([@pl.col("a").str().to_date(strict=false)]).column("a").to_list(),
    [@pl.AnyValue::Null, @pl.AnyValue::Date(19754), @pl.AnyValue::Null],
  )
}

///|
test "to_datetime: the shape of the first text decides how far the others are read" {
  let col_of = fn(values : Array[String]) raise @pl.PolarsError {
    @pl.DataFrame::new([@pl.Series::str("a", values)])
  }
  let dt = fn(values : Array[String], strict : Bool) raise @pl.PolarsError {
    col_of(values)
    .select([@pl.col("a").str().to_datetime(strict~)])
    .column("a")
    .to_list()
  }
  // a signed year is read after a date without time, not after one with a space
  assert_eq(dt(["2024-01-02", "+2024-01-02"], true), [
    @pl.AnyValue::Datetime(1704153600000000L),
    @pl.AnyValue::Datetime(1704153600000000L),
  ])
  assert_true(
    raises(() => dt(["2024-01-02 10:20:30", "+2024-01-03T10:20:30"], true))
    is Some(@pl.InvalidOperation(_)),
  )
  // a signed year with T and seconds, alone or after such a text
  assert_eq(dt(["+262142-12-31T10:20:30"], true), [
    @pl.AnyValue::Datetime(8210266827630000000L),
  ])
  assert_eq(dt(["2024-01-02T10:20:30", "+262142-12-31T10:20:30"], true), [
    @pl.AnyValue::Datetime(1704190830000000L),
    @pl.AnyValue::Datetime(8210266827630000000L),
  ])
  // not after T without seconds, not alone with a space
  assert_true(
    raises(() => dt(["2024-01-02T10:20", "+2024-01-03T10:20:30"], true))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_eq(dt(["+2024-01-03 10:20:30"], false), [@pl.AnyValue::Null])
  // year first then day first: not read
  assert_eq(dt(["2024-01-02", "01-02-2024"], false), [
    @pl.AnyValue::Datetime(1704153600000000L),
    @pl.AnyValue::Null,
  ])
}
