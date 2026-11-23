///|
test "cast basics" {
  let s = @pl.Series::int64_nullable("a", [Some(1L), None, Some(3_000_000_000L)])
  assert_eq(s.cast(@pl.DataType::Int32, strict=false).to_int32_array(), [
    Some(1),
    None,
    None,
  ])
  assert_true(
    raises(() => s.cast(@pl.DataType::Int32)) is Some(@pl.ComputeError(_)),
  )
  assert_eq(
    @pl.Series::datetime("t", [-1L]).cast(@pl.DataType::Date).get(0),
    @pl.AnyValue::Date(-1),
  )
  assert_eq(s.cast(@pl.DataType::Int64), s)
  assert_eq(@pl.Series::null("n", 2).cast(@pl.DataType::String).null_count(), 2)
}

///|
test "cast keeps the name and length" {
  let s = @pl.Series::int32("col", [1, 2, 3])
  let r = s.cast(@pl.DataType::Float64)
  assert_eq(r.name(), "col")
  assert_eq(r.len(), 3)
  assert_eq(r.to_float64_array(), [Some(1.0), Some(2.0), Some(3.0)])
  // empty input
  let e = @pl.Series::int32("e", []).cast(@pl.DataType::String)
  assert_eq(e.len(), 0)
  assert_eq(e.dtype(), @pl.DataType::String)
}

///|
test "cast strict error names the first bad value and its index" {
  let s = @pl.Series::str("s", ["1", "x", "y"])
  match raises(() => s.cast(@pl.DataType::Int32)) {
    Some(@pl.ComputeError(msg)) => {
      assert_true(msg.contains("\"x\""))
      assert_true(msg.contains("index 1"))
    }
    _ => fail("expected ComputeError")
  }
  // all-null input never fails
  let n = @pl.Series::int64_nullable("n", [None, None])
  assert_eq(n.cast(@pl.DataType::Int32).null_count(), 2)
}

///|
test "cast unsupported pairs are InvalidOperation in both modes" {
  let d = @pl.Series::date("d", [0])
  assert_true(
    raises(() => d.cast(@pl.DataType::Boolean)) is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => d.cast(@pl.DataType::Null, strict=false))
    is Some(@pl.InvalidOperation(_)),
  )
  let s = @pl.Series::str("s", ["2024-01-01"])
  assert_true(
    raises(() => s.cast(@pl.DataType::Date, strict=false))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => s.cast(@pl.DataType::Boolean)) is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "cast float to string follows polars formatting" {
  let f = @pl.Series::float64("f", [
    0.0,
    -0.0,
    1.5,
    0.1,
    1.0e-5,
    1.0e-6,
    1.0e15,
    1.0e16,
    1.0e21,
    0.0 / 0.0,
    1.0 / 0.0,
    -1.0 / 0.0,
    123456789.125,
    1.2345678901234568e17,
  ])
  assert_eq(f.cast(@pl.DataType::String).to_str_array(), [
    Some("0.0"),
    Some("-0.0"),
    Some("1.5"),
    Some("0.1"),
    Some("0.00001"),
    Some("1e-6"),
    Some("1000000000000000.0"),
    Some("1e+16"),
    Some("1e+21"),
    Some("NaN"),
    Some("inf"),
    Some("-inf"),
    Some("123456789.125"),
    Some("1.2345678901234568e+17"),
  ])
  let g = @pl.Series::float32("g", [
    1.0e-6, 1.0e-7, 1.0e12, 1.0e13, 16777216.0, 0.1, 2147483648.0,
  ])
  assert_eq(g.cast(@pl.DataType::String).to_str_array(), [
    Some("0.000001"),
    Some("1e-7"),
    Some("1000000000000.0"),
    Some("1e+13"),
    Some("16777216.0"),
    Some("0.1"),
    Some("2147483600.0"),
  ])
}

///|
test "cast float to integer truncates and checks the range" {
  let f = @pl.Series::float64("f", [
    1.9,
    -1.9,
    2147483647.9,
    -2147483648.9,
    2147483648.0,
    0.0 / 0.0,
  ])
  assert_eq(f.cast(@pl.DataType::Int32, strict=false).to_int32_array(), [
    Some(1),
    Some(-1),
    Some(2147483647),
    Some(-2147483648),
    None,
    None,
  ])
  assert_true(
    raises(() => f.cast(@pl.DataType::Int32)) is Some(@pl.ComputeError(_)),
  )
  let big = @pl.Series::float64("b", [
    9.223372036854775e18, 9.223372036854775808e18,
  ])
  assert_eq(big.cast(@pl.DataType::Int64, strict=false).to_int64_array(), [
    Some(9223372036854774784L),
    None,
  ])
}

///|
test "cast string to number" {
  let s = @pl.Series::str("s", [
    "+5", "007", "-0", "2147483648", "1_0", " 1", "",
  ])
  assert_eq(s.cast(@pl.DataType::Int32, strict=false).to_int32_array(), [
    Some(5),
    Some(7),
    Some(0),
    None,
    None,
    None,
    None,
  ])
  let f = @pl.Series::str("f", [
    ".5", "5.", "1e", "1E3", "-inf", "Infinity", "NaN", "1e400", "1_0", "0x10",
  ])
  let r = f.cast(@pl.DataType::Float64, strict=false).to_float64_array()
  assert_eq(r[0], Some(0.5))
  assert_eq(r[1], Some(5.0))
  assert_eq(r[2], None)
  assert_eq(r[3], Some(1000.0))
  assert_eq(r[4], Some(-1.0 / 0.0))
  assert_eq(r[5], Some(1.0 / 0.0))
  assert_true(r[6].unwrap().is_nan())
  assert_eq(r[7], Some(1.0 / 0.0))
  assert_eq(r[8], None)
  assert_eq(r[9], None)
}

///|
test "cast temporal values before 1970 and at the edges" {
  // floor division: -1 microsecond is still 1969-12-31
  let t = @pl.Series::datetime("t", [
    -1L, -86400000000L, -86400000001L, 86399999999L,
  ])
  assert_eq(t.cast(@pl.DataType::Date).to_list(), [
    @pl.AnyValue::Date(-1),
    @pl.AnyValue::Date(-1),
    @pl.AnyValue::Date(-2),
    @pl.AnyValue::Date(0),
  ])
  assert_eq(t.cast(@pl.DataType::String).to_str_array(), [
    Some("1969-12-31 23:59:59.999999"),
    Some("1969-12-31 00:00:00.000000"),
    Some("1969-12-30 23:59:59.999999"),
    Some("1970-01-01 23:59:59.999999"),
  ])
  let d = @pl.Series::date("d", [-25567, -719529, 2932896, 2932897, -719528])
  assert_eq(d.cast(@pl.DataType::String).to_str_array(), [
    Some("1900-01-01"),
    Some("-0001-12-31"),
    Some("9999-12-31"),
    Some("+10000-01-01"),
    Some("0000-01-01"),
  ])
  assert_eq(
    @pl.Series::date("d", [-1]).cast(@pl.DataType::Datetime).get(0),
    @pl.AnyValue::Datetime(-86400000000L),
  )
}

///|
test "cast out-of-range dates never abort" {
  let d = @pl.Series::date("d", [@int.MAX_VALUE, @int.MIN_VALUE, 0])
  assert_eq(d.cast(@pl.DataType::String, strict=false).to_str_array(), [
    None,
    None,
    Some("1970-01-01"),
  ])
  assert_true(
    raises(() => d.cast(@pl.DataType::String)) is Some(@pl.ComputeError(_)),
  )
  // Date -> Datetime would overflow 64-bit microseconds
  assert_eq(d.cast(@pl.DataType::Datetime, strict=false).to_list(), [
    @pl.AnyValue::Null,
    @pl.AnyValue::Null,
    @pl.AnyValue::Datetime(0L),
  ])
  assert_true(
    raises(() => d.cast(@pl.DataType::Datetime)) is Some(@pl.ComputeError(_)),
  )
  // the full Int64 microsecond range still formats and floors to a date
  let t = @pl.Series::datetime("t", [@int64.MAX_VALUE, @int64.MIN_VALUE])
  assert_eq(t.cast(@pl.DataType::Date).to_list(), [
    @pl.AnyValue::Date(106751991),
    @pl.AnyValue::Date(-106751992),
  ])
  assert_eq(t.cast(@pl.DataType::String).null_count(), 0)
}

///|
test "cast bool and numeric edge cases" {
  let f = @pl.Series::float32("f", [0.0, -0.0, 0.0 / 0.0, 1.0 / 0.0, 2.0])
  assert_eq(f.cast(@pl.DataType::Boolean).to_bool_array(), [
    Some(false),
    Some(false),
    Some(true),
    Some(true),
    Some(true),
  ])
  let b = @pl.Series::bool_nullable("b", [Some(true), None])
  assert_eq(b.cast(@pl.DataType::String).to_str_array(), [Some("true"), None])
  assert_eq(b.cast(@pl.DataType::Float32).to_float32_array(), [Some(1.0), None])
  // Int64 -> Float32 rounds to nearest
  let i = @pl.Series::int64("i", [16777217L, 9223372036854775807L])
  assert_eq(i.cast(@pl.DataType::Float32).to_float32_array(), [
    Some(16777216.0),
    Some(9223372036854775808.0),
  ])
  // no double rounding: 2^60 + 2^36 + 1 is above the f32 tie, so it rounds up
  let tie = @pl.Series::int64("tie", [
    1152921573326323713L, 1152921573326323712L,
  ])
  assert_eq(tie.cast(@pl.DataType::Float32).to_float32_array(), [
    Some(1152921642045800448.0),
    Some(1152921504606846976.0),
  ])
  // Null casts keep the length
  let n = @pl.Series::null("n", 3)
  assert_eq(n.cast(@pl.DataType::Datetime).len(), 3)
  assert_eq(n.cast(@pl.DataType::Datetime).dtype(), @pl.DataType::Datetime)
  // anything -> Null needs every value to be null
  let x = @pl.Series::int32_nullable("x", [None, Some(1)])
  assert_eq(x.cast(@pl.DataType::Null, strict=false).null_count(), 2)
  assert_true(
    raises(() => x.cast(@pl.DataType::Null)) is Some(@pl.ComputeError(_)),
  )
}

///|
test "cast string to int64 limits and stray characters" {
  let s = @pl.Series::str("s", [
    "99999999999999999999", "9223372036854775807", "9223372036854775808", "-9223372036854775808",
    "-9223372036854775809", "1:", "1/", "1a", ":", "/", "-99999999999999999999",
  ])
  assert_eq(s.cast(@pl.DataType::Int64, strict=false).to_int64_array(), [
    None,
    Some(9223372036854775807L),
    None,
    Some(-9223372036854775808L),
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  ])
  // strict mode: each bad value is a ComputeError that names the value
  let bad = [
    "99999999999999999999", "9223372036854775808", "-9223372036854775809", "1:",
    "1/", "1a",
  ]
  for b in bad {
    match raises(() => @pl.Series::str("s", [b]).cast(@pl.DataType::Int64)) {
      Some(@pl.ComputeError(msg)) => assert_true(msg.contains("\"\{b}\""))
      _ => fail("expected ComputeError for \{b}")
    }
  }
  assert_eq(
    @pl.Series::str("s", ["9223372036854775807"])
    .cast(@pl.DataType::Int64)
    .get(0),
    @pl.AnyValue::Int64(9223372036854775807L),
  )
  assert_eq(
    @pl.Series::str("s", ["-9223372036854775808"])
    .cast(@pl.DataType::Int64)
    .get(0),
    @pl.AnyValue::Int64(-9223372036854775808L),
  )
  // the same strings to Int32
  let t = @pl.Series::str("t", ["2147483647", "-2147483648", "2147483648", "1:"])
  assert_eq(t.cast(@pl.DataType::Int32, strict=false).to_int32_array(), [
    Some(2147483647),
    Some(-2147483648),
    None,
    None,
  ])
}

///|
test "cast string to float with a signed exponent" {
  let s = @pl.Series::str("s", ["1e-5", "1e+5", "-2.5E-3", "2.5e+2", "1e-"])
  let r = s.cast(@pl.DataType::Float64, strict=false).to_float64_array()
  assert_eq(r[0], Some(0.00001))
  assert_eq(r[1], Some(100000.0))
  assert_eq(r[2], Some(-0.0025))
  assert_eq(r[3], Some(250.0))
  assert_eq(r[4], None)
  let f = s.cast(@pl.DataType::Float32, strict=false).to_float32_array()
  assert_eq(f[0], Some(0.00001))
  assert_eq(f[1], Some(100000.0))
  assert_eq(f[4], None)
  assert_true(
    raises(() => @pl.Series::str("s", ["1e+"]).cast(@pl.DataType::Float64))
    is Some(@pl.ComputeError(_)),
  )
}

///|
test "cast dates at the exact limits of the supported range" {
  // 110 000 000 days is the last day that formats; one more gives null.
  // (polars panics beyond about 95.7 million days, so this is not golden data.)
  let d = @pl.Series::date("d", [110000000, 110000001, -110000000, -110000001])
  assert_eq(d.cast(@pl.DataType::String, strict=false).to_str_array(), [
    Some("+303139-10-10"),
    None,
    Some("-299200-03-25"),
    None,
  ])
  match raises(() => d.cast(@pl.DataType::String)) {
    Some(@pl.ComputeError(msg)) => assert_true(msg.contains("index 1"))
    _ => fail("expected ComputeError")
  }
  assert_eq(
    @pl.Series::date("d", [110000000]).cast(@pl.DataType::String).get(0),
    @pl.AnyValue::String("+303139-10-10"),
  )
  assert_eq(
    @pl.Series::date("d", [-110000000]).cast(@pl.DataType::String).get(0),
    @pl.AnyValue::String("-299200-03-25"),
  )
  // Date -> Datetime: 106751991 days is the last that fits Int64 microseconds
  let e = @pl.Series::date("e", [106751991, 106751992, -106751991, -106751992])
  assert_eq(e.cast(@pl.DataType::Datetime, strict=false).to_list(), [
    @pl.AnyValue::Datetime(9223372022400000000L),
    @pl.AnyValue::Null,
    @pl.AnyValue::Datetime(-9223372022400000000L),
    @pl.AnyValue::Null,
  ])
  assert_eq(
    @pl.Series::date("e", [106751991]).cast(@pl.DataType::Datetime).get(0),
    @pl.AnyValue::Datetime(9223372022400000000L),
  )
  assert_eq(
    @pl.Series::date("e", [-106751991]).cast(@pl.DataType::Datetime).get(0),
    @pl.AnyValue::Datetime(-9223372022400000000L),
  )
  match
    raises(() => @pl.Series::date("e", [106751992]).cast(@pl.DataType::Datetime)) {
    Some(@pl.ComputeError(msg)) => assert_true(msg.contains("index 0"))
    _ => fail("expected ComputeError")
  }
  match
    raises(() => {
      @pl.Series::date("e", [-106751992]).cast(@pl.DataType::Datetime)
    }) {
    Some(@pl.ComputeError(_)) => ()
    _ => fail("expected ComputeError")
  }
}

///|
test "cast integer and float boundaries to Int32 and Int64" {
  let i = @pl.Series::int64("i", [
    -2147483648L, 2147483647L, 2147483648L, -2147483649L,
  ])
  assert_eq(i.cast(@pl.DataType::Int32, strict=false).to_int32_array(), [
    Some(-2147483648),
    Some(2147483647),
    None,
    None,
  ])
  let f = @pl.Series::float64("f", [
    -2147483648.0, -2147483649.0, 2147483647.0, 2147483648.0, -2147483648.9, -2147483649.0,
  ])
  assert_eq(f.cast(@pl.DataType::Int32, strict=false).to_int32_array(), [
    Some(-2147483648),
    None,
    Some(2147483647),
    None,
    Some(-2147483648),
    None,
  ])
  let g = @pl.Series::float64("g", [
    -9223372036854775808.0, 9223372036854775807.0, -9223372036854777856.0,
  ])
  assert_eq(g.cast(@pl.DataType::Int64, strict=false).to_int64_array(), [
    Some(-9223372036854775808L),
    None,
    None,
  ])
}
