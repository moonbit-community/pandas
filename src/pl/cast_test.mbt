///|
test "cast basics" {
  let s = @pl.Series::int64_nullable("a", [Some(1L), None, Some(3_000_000_000L)])
  assert_eq(s.cast(@pl.DataType::Int32, strict=false).to_int32_array(), [
    Some(1),
    None,
    None,
  ])
  assert_true(
    raises(() => s.cast(@pl.DataType::Int32)) is Some(@pl.InvalidOperation(_)),
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
test "cast strict error is polars' InvalidOperation with the failing values" {
  let s = @pl.Series::str("s", ["1", "x", "y"])
  match raises(() => s.cast(@pl.DataType::Int32)) {
    Some(@pl.InvalidOperation(msg)) =>
      assert_eq(
        msg, "conversion from `str` to `i32` failed in column 's' for 2 out of 3 values: [\"x\", \"y\"]",
      )
    _ => fail("expected InvalidOperation")
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
    raises(() => f.cast(@pl.DataType::Int32)) is Some(@pl.InvalidOperation(_)),
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
    raises(() => x.cast(@pl.DataType::Null)) is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "cast string to int64 limits and stray characters" {
  let s = @pl.Series::str("s", [
    "99999999999999999999", "9223372036854775807", "9223372036854775808", "-9223372036854775808",
    "-9223372036854775809", "1:", "1/", "1a", ":", "/", "-99999999999999999999",
    "9223372036854775810", "-9223372036854775810", "9223372036854775819",
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
    None,
    None,
    None,
  ])
  // strict mode: each bad value is an InvalidOperation that names the value
  let bad = [
    "99999999999999999999", "9223372036854775808", "-9223372036854775809", "1:",
    "1/", "1a", "9223372036854775810", "-9223372036854775810", "9223372036854775819",
  ]
  for b in bad {
    match raises(() => @pl.Series::str("s", [b]).cast(@pl.DataType::Int64)) {
      Some(@pl.InvalidOperation(msg)) => assert_true(msg.contains("[\"\{b}\"]"))
      _ => fail("expected InvalidOperation for \{b}")
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
    is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "cast string to f64 with a long mantissa and a negative exponent" {
  let zeros = String::make(400, '0')
  let inf = 1.0 / 0.0
  // 1e400 * 1e-91 = 1e309 overflows, whatever the sign of the exponent
  let s = @pl.Series::str("s", [
    "1" + zeros + "e-91",
    "-1" + zeros + "e-90",
    "1" + zeros + "e-92",
    "1" + zeros + "e-93",
    "1" + zeros + "e-400",
    "1" + zeros + "e5",
    "0." + zeros + "1e400",
    "0." + zeros + "1e-5",
    "1" + zeros + "e-10000000000",
    "-1" + zeros + "e-10000000000",
    "0" + zeros + "e-91",
    "1e4294967297",
    "-1e4294967297",
    "1e-4294967297",
    "-1e-4294967297",
    "17976931348623157" + String::make(292, '0'),
    "17976931348623159" + String::make(292, '0'),
  ])
  assert_eq(s.cast(@pl.DataType::Float64).to_float64_array(), [
    Some(inf),
    Some(-inf),
    Some(1.0e308),
    Some(1.0e307),
    Some(1.0),
    Some(inf),
    Some(0.1),
    Some(0.0),
    Some(0.0),
    Some(-0.0),
    Some(0.0),
    Some(inf),
    Some(-inf),
    Some(0.0),
    Some(-0.0),
    Some(1.7976931348623157e308),
    Some(inf),
  ])
  // the sign of a zero survives
  let negzero = @pl.Series::str("s", ["-0", "-1e-4294967297"])
    .cast(@pl.DataType::Float64)
    .to_float64_array()
  assert_eq(negzero[0].unwrap().reinterpret_as_uint64(), 0x8000000000000000UL)
  assert_eq(negzero[1].unwrap().reinterpret_as_uint64(), 0x8000000000000000UL)
}

///|
test "cast datetime to f32 rounds the integer once" {
  // 2^60 + 2^36 + 1: through f64 it would lose the last bit and tie to even
  let t = @pl.Series::datetime("t", [1152921573326323713L])
  let f = t.cast(@pl.DataType::Float32).to_float32_array()[0].unwrap()
  assert_eq(f.reinterpret_as_uint(), 0x5D800001U)
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
    Some(@pl.ComputeError(msg)) =>
      assert_eq(
        msg, "column \"d\": cannot cast date to str: value date(110000001) at index 1 cannot be converted (use strict=false to turn it into null)",
      )
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
    Some(@pl.ComputeError(msg)) =>
      assert_eq(
        msg, "column \"e\": cannot cast date to datetime[\u{3bc}s]: value date(106751992) at index 0 cannot be converted (use strict=false to turn it into null)",
      )
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

///|
/// The message of the error `s.cast(to)` raises.
fn cast_error_message(s : @pl.Series, to : @pl.DataType) -> String raise {
  match raises(() => s.cast(to)) {
    Some(@pl.InvalidOperation(m)) => m
    Some(e) => fail("expected InvalidOperation, got \{e}")
    None => fail("expected an error")
  }
}

///|
test "cast strict failure messages follow polars" {
  // lines taken from polars 2.1.0
  assert_eq(
    cast_error_message(
      @pl.Series::str("a", ["1", "x", "2", "y", "z", "3"]),
      @pl.DataType::Int64,
    ),
    "conversion from `str` to `i64` failed in column 'a' for 3 out of 6 values: [\"x\", \"y\", \"z\"]",
  )
  assert_eq(
    cast_error_message(@pl.Series::int64("", [1L]), @pl.DataType::Null),
    "conversion from `i64` to `null` failed in column '' for 1 out of 1 values: [1]",
  )
  assert_eq(
    cast_error_message(@pl.Series::float64("a", [3.0e10]), @pl.DataType::Int32),
    "conversion from `f64` to `i32` failed in column 'a' for 1 out of 1 values: [3.0000e10]",
  )
  assert_eq(
    cast_error_message(
      @pl.Series::str("", Array::makei(20, _ => "a")),
      @pl.DataType::Float64,
    ),
    "conversion from `str` to `f64` failed in column '' for 20 out of 20 values: [\"a\", \"a\", \u{2026} \"a\"]",
  )
}

///|
test "cast strict failure lists show at most three values" {
  let bad = fn(n) { Array::makei(n, i => "x\{i}") }
  let msg = fn(n) raise {
    cast_error_message(@pl.Series::str("a", bad(n)), @pl.DataType::Int64)
  }
  let head = "conversion from `str` to `i64` failed in column 'a' for"
  assert_eq(msg(1), "\{head} 1 out of 1 values: [\"x0\"]")
  assert_eq(msg(2), "\{head} 2 out of 2 values: [\"x0\", \"x1\"]")
  assert_eq(msg(3), "\{head} 3 out of 3 values: [\"x0\", \"x1\", \"x2\"]")
  // four or more: the first two, an ellipsis, the last collected one
  assert_eq(
    msg(4),
    "\{head} 4 out of 4 values: [\"x0\", \"x1\", \u{2026} \"x3\"]",
  )
  assert_eq(
    msg(10),
    "\{head} 10 out of 10 values: [\"x0\", \"x1\", \u{2026} \"x9\"]",
  )
  // only the first ten failing values are collected; the count is complete
  assert_eq(
    msg(11),
    "\{head} 11 out of 11 values: [\"x0\", \"x1\", \u{2026} \"x9\"]",
  )
  assert_eq(
    msg(20),
    "\{head} 20 out of 20 values: [\"x0\", \"x1\", \u{2026} \"x9\"]",
  )
  // good values and nulls count towards the length, not the failures
  let mixed : Array[String?] = []
  for _ in 0..<30 {
    mixed.push(Some("1"))
    mixed.push(None)
  }
  for i in 0..<15 {
    mixed.push(Some("b\{i}"))
  }
  assert_eq(
    cast_error_message(
      @pl.Series::str_nullable("a", mixed),
      @pl.DataType::Int64,
    ),
    "\{head} 15 out of 75 values: [\"b0\", \"b1\", \u{2026} \"b9\"]",
  )
}

///|
test "cast strict failure values are shown like polars table cells" {
  // floats: `fmt_float` text, `f32` widened to `f64`
  assert_eq(
    cast_error_message(
      @pl.Series::float64("a", [
        1.0e20,
        1.0e300,
        0.0 / 0.0,
        1.0 / 0.0,
        -1.0 / 0.0,
      ]),
      @pl.DataType::Int32,
    ),
    "conversion from `f64` to `i32` failed in column 'a' for 5 out of 5 values: [1.0000e20, 1.0000e300, \u{2026} -inf]",
  )
  assert_eq(
    cast_error_message(
      @pl.Series::float32("a", [3.0e10, 1.0e11]),
      @pl.DataType::Int32,
    ),
    "conversion from `f32` to `i32` failed in column 'a' for 2 out of 2 values: [3.0000e10, 1.0000e11]",
  )
  assert_eq(
    cast_error_message(
      @pl.Series::float64("a", [0.1, 0.30000000000000004, 1.0 / 3.0, 12345.0]),
      @pl.DataType::Null,
    ),
    "conversion from `f64` to `null` failed in column 'a' for 4 out of 4 values: [0.1, 0.3, \u{2026} 12345.0]",
  )
  // bool, integers, datetimes
  assert_eq(
    cast_error_message(
      @pl.Series::bool_nullable("a", [Some(true), Some(false), None, Some(true)]),
      @pl.DataType::Null,
    ),
    "conversion from `bool` to `null` failed in column 'a' for 3 out of 4 values: [true, false, true]",
  )
  assert_eq(
    cast_error_message(
      @pl.Series::int64("a", [2147483648L, -2147483649L, 9223372036854775807L]),
      @pl.DataType::Int32,
    ),
    "conversion from `i64` to `i32` failed in column 'a' for 3 out of 3 values: [2147483648, -2147483649, 9223372036854775807]",
  )
  assert_eq(
    cast_error_message(
      @pl.Series::int64("a", [2147483648L]),
      @pl.DataType::Date,
    ),
    "conversion from `i64` to `date` failed in column 'a' for 1 out of 1 values: [2147483648]",
  )
  assert_eq(
    cast_error_message(
      @pl.Series::datetime_nullable("a", [
        Some(1099511627776L),
        Some(-1099511627776L),
        Some(5L),
        Some(1709210096123456L),
        None,
      ]),
      @pl.DataType::Int32,
    ),
    "conversion from `datetime[\u{3bc}s]` to `i32` failed in column 'a' for 3 out of 5 values: [1970-01-13 17:25:11.627776, 1969-12-19 06:34:48.372224, 2024-02-29 12:34:56.123456]",
  )
  // strings are quoted but neither escaped nor cut; the column name is raw
  assert_eq(
    cast_error_message(
      @pl.Series::str("it's", [
        "a\"b",
        "x\ny",
        "\u{65e5}\u{672c}",
        String::make(35, 'x'),
      ]),
      @pl.DataType::Int32,
    ),
    "conversion from `str` to `i32` failed in column 'it's' for 4 out of 4 values: [\"a\"b\", \"x\ny\", \u{2026} \"\{String::make(35, 'x')}\"]",
  )
}

///|
test "cast strict mode only fails for values that do not convert" {
  // nulls and convertible values never fail; strict=false never raises here
  let s = @pl.Series::int64_nullable("a", [Some(1L), None, Some(3L)])
  assert_eq(s.cast(@pl.DataType::Int32).to_int32_array(), [
    Some(1),
    None,
    Some(3),
  ])
  let bad = @pl.Series::str("a", ["x"])
  assert_eq(bad.cast(@pl.DataType::Int32, strict=false).to_int32_array(), [None])
  assert_eq(bad.cast(@pl.DataType::Null, strict=false).len(), 1)
  // an all-null series casts to Null in strict mode
  let n = @pl.Series::str_nullable("a", [None, None])
  let r = n.cast(@pl.DataType::Null)
  assert_eq(r.dtype(), @pl.DataType::Null)
  assert_eq(r.len(), 2)
}

///|
test "cast unsupported pairs use polars' messages" {
  let msg = fn(s : @pl.Series, to : @pl.DataType, strict : Bool) raise {
    match raises(() => s.cast(to, strict~)) {
      Some(@pl.InvalidOperation(m)) => m
      _ => fail("expected InvalidOperation")
    }
  }
  let text = @pl.Series::str("a", ["x"])
  let day = @pl.Series::date("a", [1])
  let time = @pl.Series::datetime("a", [1L])
  for strict in [true, false] {
    assert_eq(
      msg(text, @pl.DataType::Boolean, strict),
      "casting from Utf8View to Boolean not supported",
    )
    assert_eq(
      msg(text, @pl.DataType::Date, strict),
      "casting from string to date is not supported.",
    )
    assert_eq(
      msg(text, @pl.DataType::Datetime, strict),
      "casting from string to datetime is not supported.",
    )
    assert_eq(
      msg(day, @pl.DataType::Boolean, strict),
      "casting from Date to Boolean not supported",
    )
    assert_eq(
      msg(day, @pl.DataType::Null, strict),
      "casting from Date to Null not supported",
    )
    assert_eq(
      msg(time, @pl.DataType::Boolean, strict),
      "casting from Datetime('\u{3bc}s') to Boolean not supported",
    )
    assert_eq(
      msg(time, @pl.DataType::Null, strict),
      "casting from Datetime('\u{3bc}s') to Null not supported",
    )
  }
}

///|
/// `Float32` with the given IEEE bit pattern.
fn f32_bits(bits : UInt32) -> Float {
  Float::reinterpret_from_uint(bits)
}

///|
/// The `Float32` a one-element string series casts to (lenient mode).
fn parse_f32(text : String) -> Float? raise {
  @pl.Series::str("s", [text])
  .cast(@pl.DataType::Float32, strict=false)
  .to_float32_array()[0]
}

///|
test "cast string to f32 rounds the exact decimal value once" {
  let inf = f32_bits(0x7F800000U)
  // f32::MAX is 3.4028234663852886e38; the midpoint to 2^128 is
  // 3.40282356779733661637...e38, and only a value at or above it is infinity
  assert_eq(parse_f32("3.4028235677973366e38"), Some(f32_bits(0x7F7FFFFFU)))
  assert_eq(parse_f32("-3.4028235677973366e38"), Some(f32_bits(0xFF7FFFFFU)))
  assert_eq(parse_f32("3.4028235e38"), Some(f32_bits(0x7F7FFFFFU)))
  assert_eq(parse_f32("3.4028235677973367e38"), Some(inf))
  assert_eq(parse_f32("3.40282357e38"), Some(inf))
  assert_eq(parse_f32("1e39"), Some(inf))
  // double rounding through f64 lands on the midpoint and then on the even
  // neighbour; the exact value decides
  assert_eq(
    parse_f32("1.00000005960464477539062500001"),
    Some(f32_bits(0x3F800001U)),
  )
  assert_eq(
    parse_f32("1.0000000596046447753906250"),
    Some(f32_bits(0x3F800000U)),
  )
  assert_eq(
    parse_f32("1.00000017881393432617187499"),
    Some(f32_bits(0x3F800001U)),
  )
  assert_eq(
    parse_f32("1.000000178813934326171875"),
    Some(f32_bits(0x3F800002U)),
  )
  assert_eq(parse_f32("16777217"), Some(f32_bits(0x4B800000U)))
  assert_eq(parse_f32("16777217.0000000001"), Some(f32_bits(0x4B800001U)))
  // subnormals: halfway to zero is 2^-150 = 7.00649232162408535...e-46
  assert_eq(parse_f32("7e-46"), Some(f32_bits(0U)))
  assert_eq(parse_f32("7.006492321624085e-46"), Some(f32_bits(0U)))
  assert_eq(parse_f32("7.006492321624086e-46"), Some(f32_bits(1U)))
  assert_eq(parse_f32("1e-45"), Some(f32_bits(1U)))
  assert_eq(parse_f32("2.1019476964872255e-45"), Some(f32_bits(1U)))
  assert_eq(parse_f32("2.1019476964872257e-45"), Some(f32_bits(2U)))
  assert_eq(
    parse_f32("-7e-46").map(x => x.reinterpret_as_uint()),
    Some(0x80000000U),
  )
  // exponents far outside the range, and zero with any exponent
  assert_eq(parse_f32("1e99999999999999999999"), Some(inf))
  assert_eq(parse_f32("1e-99999999999999999999"), Some(f32_bits(0U)))
  assert_eq(parse_f32("0e99999999999999999999"), Some(f32_bits(0U)))
  assert_eq(parse_f32("1e-400"), Some(f32_bits(0U)))
  // an exponent past Int32 must saturate, not wrap around (4294967297 is
  // 2^32 + 1: wrapped it would read as 1)
  assert_eq(parse_f32("1e4294967297"), Some(inf))
  assert_eq(parse_f32("-1e4294967297"), Some(f32_bits(0xFF800000U)))
  assert_eq(parse_f32("1e-4294967297"), Some(f32_bits(0U)))
  // exact ties below 1.0 (0.5 + 2^-25): to even, and one digit past the tie
  assert_eq(
    parse_f32("0.5000000298023223876953125"),
    Some(f32_bits(0x3F000000U)),
  )
  assert_eq(
    parse_f32(".5000000298023223876953125"),
    Some(f32_bits(0x3F000000U)),
  )
  assert_eq(
    parse_f32("0.50000002980232238769531251"),
    Some(f32_bits(0x3F000001U)),
  )
  // signed zero
  for z in ["-0", "-0.0", "-0e5", "-.0", "-0.", "-1e-400"] {
    assert_eq(parse_f32(z).map(x => x.reinterpret_as_uint()), Some(0x80000000U))
  }
  for z in ["0", "+0", "0.0", "0e5"] {
    assert_eq(parse_f32(z).map(x => x.reinterpret_as_uint()), Some(0U))
  }
  // plain values and shapes are unchanged
  assert_eq(parse_f32("0.1"), Some(f32_bits(0x3DCCCCCDU)))
  assert_eq(parse_f32("1.5"), Some(1.5))
  assert_eq(parse_f32("  1.5"), None)
  assert_eq(parse_f32("1e"), None)
  assert_eq(parse_f32("-inf"), Some(f32_bits(0xFF800000U)))
  assert_true(parse_f32("nan").unwrap().is_nan())
  // long digit strings: 60 zeros after the point, then a one, are 1e-61
  let long = "0." + String::make(60, '0') + "1"
  assert_eq(parse_f32(long), Some(f32_bits(0U)))
  assert_eq(parse_f32("1" + String::make(60, '0') + "e-60"), Some(1.0))
}

///|
test "cast of an empty or all-null series succeeds for every type pair" {
  let targets : Array[@pl.DataType] = [
    Boolean,
    Int32,
    Int64,
    Float32,
    Float64,
    String,
    Date,
    Datetime,
    Null,
  ]
  let sources : Array[@pl.Series] = [
    @pl.Series::str("s", []),
    @pl.Series::str_nullable("s", [None, None, None]),
    @pl.Series::date("s", []),
    @pl.Series::date_nullable("s", [None, None, None]),
    @pl.Series::datetime("s", []),
    @pl.Series::datetime_nullable("s", [None, None, None]),
    @pl.Series::null("s", 0),
    @pl.Series::null("s", 3),
    @pl.Series::int64_nullable("s", [None, None, None]),
    @pl.Series::float64("s", []),
  ]
  for src in sources {
    for to in targets {
      for strict in [true, false] {
        let r = src.cast(to, strict~)
        assert_eq(r.dtype(), to)
        assert_eq(r.name(), "s")
        assert_eq(r.len(), src.len())
        assert_eq(r.null_count(), src.len())
      }
    }
  }
  // one non-null value brings the unsupported-pair error back
  let one = @pl.Series::str_nullable("s", [None, Some("x")])
  assert_true(
    raises(() => one.cast(@pl.DataType::Boolean))
    is Some(@pl.InvalidOperation(_)),
  )
  let day = @pl.Series::date_nullable("s", [None, Some(1)])
  assert_true(
    raises(() => day.cast(@pl.DataType::Null, strict=false))
    is Some(@pl.InvalidOperation(_)),
  )
}
