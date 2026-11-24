///|
test "trigonometric functions of an expression: Float64 for integers, Float32 stays" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32_nullable("i", [Some(0), None, Some(1)]),
    @pl.Series::float32("g", [0.0, 0.5, 1.0]),
    @pl.Series::float64("f", [0.0, 1.0, 0.0 / 0.0]),
  ])
  let out = df.select([
    @pl.col("i").sin(),
    @pl.col("g").cos().alias("cg"),
    @pl.col("f").arctan().alias("af"),
  ])
  assert_eq(out.column("i").dtype(), @pl.DataType::Float64)
  assert_eq(out.column("cg").dtype(), @pl.DataType::Float32)
  let xs = out.column("i").to_float64_array()
  assert_eq(xs[0], Some(0.0))
  assert_eq(xs[1], None)
  assert_true((xs[2].unwrap() - 0.8414709848078965).abs() < 1.0e-15)
  let ys = out.column("af").to_float64_array()
  assert_true(ys[2].unwrap().is_nan())
  assert_true((ys[1].unwrap() - 0.7853981633974483).abs() < 1.0e-15)
}

///|
test "arcsin and arccos outside [-1, 1] are NaN; tan of 0 is 0" {
  let s = @pl.Series::float64("x", [2.0, -2.0, 0.0])
  let a = s.arcsin().to_float64_array()
  assert_true(a[0].unwrap().is_nan() && a[1].unwrap().is_nan())
  assert_eq(a[2], Some(0.0))
  let t = s.tan().to_float64_array()
  assert_eq(t[2], Some(0.0))
}

///|
test "trigonometric functions refuse Boolean, String, Date, Datetime and Null" {
  let check = (s : @pl.Series, name : String) => {
    assert_eq(
      shape_msg(() => ignore(s.sin())),
      "InvalidOperation: trigonometry operation not supported for dtype `\{name}`",
    )
  }
  check(@pl.Series::bool("x", [true]), "bool")
  check(@pl.Series::str("x", ["a"]), "str")
  check(@pl.Series::date("x", [1]), "date")
  check(@pl.Series::datetime("x", [1L]), "datetime[\u{3bc}s]")
  check(@pl.Series::null("x", 2), "null")
}
