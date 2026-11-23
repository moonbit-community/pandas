///|
/// Parses a float from its Python `repr` text (`nan`, `inf`, `-inf`, `-0.0`,
/// `1.5e+20`, ...).
fn golden_double(text : String) -> Double raise {
  match text {
    "nan" => 0.0 / 0.0
    "inf" => 1.0 / 0.0
    "-inf" => -1.0 / 0.0
    _ => @string.parse_double(text)
  }
}

///|
/// Maps the non-null entries of `vals` through `f`.
fn[T] golden_conv(
  vals : Array[String?],
  f : (String) -> T raise,
) -> Array[T?] raise {
  let out : Array[T?] = []
  for v in vals {
    match v {
      None => out.push(None)
      Some(s) => out.push(Some(f(s)))
    }
  }
  out
}

///|
/// Rebuilds a `@pl.Series` from the golden-data encoding
/// `{"name": str, "dtype": "<display name>", "values": [...]}`.
///
/// Non-null values are strings (integers in decimal, floats as Python `repr`,
/// booleans as `true`/`false`, strings verbatim, dates as days, datetimes as
/// microseconds); nulls are JSON `null`.
fn golden_series(j : @json.Json) -> @pl.Series raise {
  guard j is Object(obj) else { fail("golden series: expected an object") }
  guard obj.get("name") is Some(String(name)) else {
    fail("golden series: missing name")
  }
  guard obj.get("dtype") is Some(String(dtype)) else {
    fail("golden series: missing dtype")
  }
  guard obj.get("values") is Some(Array(items)) else {
    fail("golden series: missing values")
  }
  let vals : Array[String?] = []
  for item in items {
    match item {
      Null => vals.push(None)
      String(s) => vals.push(Some(s))
      _ => fail("golden series: unexpected value \{@debug.to_string(item)}")
    }
  }
  match dtype {
    "bool" =>
      @pl.Series::bool_nullable(
        name,
        golden_conv(vals, s => {
          match s {
            "true" => true
            "false" => false
            _ => fail("golden series: bad bool \{s}")
          }
        }),
      )
    "i32" =>
      @pl.Series::int32_nullable(
        name,
        golden_conv(vals, s => @string.parse_int(s)),
      )
    "i64" =>
      @pl.Series::int64_nullable(
        name,
        golden_conv(vals, s => @string.parse_int64(s)),
      )
    "f32" =>
      @pl.Series::float32_nullable(
        name,
        golden_conv(vals, s => Float::from_double(golden_double(s))),
      )
    "f64" =>
      @pl.Series::float64_nullable(name, golden_conv(vals, golden_double))
    "str" => @pl.Series::str_nullable(name, vals)
    "date" =>
      @pl.Series::date_nullable(
        name,
        golden_conv(vals, s => @string.parse_int(s)),
      )
    "datetime[μs]" =>
      @pl.Series::datetime_nullable(
        name,
        golden_conv(vals, s => @string.parse_int64(s)),
      )
    "null" => @pl.Series::null(name, vals.length())
    _ => fail("golden series: unknown dtype \{dtype}")
  }
}

///|
/// Maps a display name (`"i32"`, `"datetime[μs]"`, ...) to its `DataType`.
fn golden_dtype(name : String) -> @pl.DataType raise {
  match name {
    "bool" => @pl.DataType::Boolean
    "i32" => @pl.DataType::Int32
    "i64" => @pl.DataType::Int64
    "f32" => @pl.DataType::Float32
    "f64" => @pl.DataType::Float64
    "str" => @pl.DataType::String
    "date" => @pl.DataType::Date
    "datetime[μs]" => @pl.DataType::Datetime
    "null" => @pl.DataType::Null
    _ => fail("golden: unknown dtype \{name}")
  }
}

///|
/// `Series::equals` plus an exact check of the sign of zero (`-0.0` and `0.0`
/// are `==` but differ in the golden data).
fn golden_same(a : @pl.Series, b : @pl.Series) -> Bool {
  if !a.equals(b) {
    return false
  }
  let xs = a.to_list()
  let ys = b.to_list()
  for i in 0..<xs.length() {
    match (xs[i], ys[i]) {
      (Float64(x), Float64(y)) =>
        if !x.is_nan() && x.reinterpret_as_int64() != y.reinterpret_as_int64() {
          return false
        }
      (Float32(x), Float32(y)) =>
        if !x.is_nan() && x.reinterpret_as_int() != y.reinterpret_as_int() {
          return false
        }
      _ => ()
    }
  }
  true
}

///|
test "golden_series decodes every dtype" {
  let j = @json.parse(
    (
      #|{"name": "x", "dtype": "f64", "values": ["-0.0", "nan", "inf", "-inf", "1.5e+20", null]}
    ),
  )
  let s = golden_series(j)
  assert_eq(s.name(), "x")
  assert_eq(s.dtype(), @pl.DataType::Float64)
  assert_eq(s.null_count(), 1)
  assert_true(golden_same(s, s))
  let d = golden_series(
    @json.parse(
      (
        #|{"name": "d", "dtype": "date", "values": ["-25567", null]}
      ),
    ),
  )
  assert_eq(d.get(0), @pl.AnyValue::Date(-25567))
  let t = golden_series(
    @json.parse(
      (
        #|{"name": "t", "dtype": "datetime[μs]", "values": ["-9223372036854775808"]}
      ),
    ),
  )
  assert_eq(t.get(0), @pl.AnyValue::Datetime(@int64.MIN_VALUE))
  let n = golden_series(
    @json.parse(
      (
        #|{"name": "n", "dtype": "null", "values": [null, null]}
      ),
    ),
  )
  assert_eq(n.len(), 2)
  assert_eq(n.dtype(), @pl.DataType::Null)
  // -0.0 and 0.0 are told apart by `golden_same`
  let z = @pl.Series::float64("z", [0.0])
  let nz = @pl.Series::float64("z", [-0.0])
  assert_true(z.equals(nz))
  assert_false(golden_same(z, nz))
}
