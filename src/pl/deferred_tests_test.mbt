// Tests for gaps the final review found (surviving mutants and the cases the
// task reviews deferred). The expected values come from polars 2.1.0
// (fw-scripts/misc_probe.py, mask_probe.py) unless a test says otherwise.

///|
fn dt_bits64(xs : Array[Double?]) -> Array[Int64?] {
  xs.map(x => x.map(v => v.reinterpret_as_int64()))
}

///|
fn dt_bits32(xs : Array[Float?]) -> Array[UInt32?] {
  xs.map(x => x.map(v => v.reinterpret_as_uint()))
}

///|
fn dt_msg(f : () -> Unit raise @pl.PolarsError) -> String {
  try {
    f()
    "no error"
  } catch {
    e => "\{e}"
  }
}

///|
test "vstack: a frame without rows but with columns is not an empty frame" {
  let a0 = @pl.DataFrame::new([@pl.Series::int64("a", [])])
  let b1 = @pl.DataFrame::new([@pl.Series::int64("b", [1L])])
  assert_eq(
    dt_msg(() => ignore(a0.vstack(b1))),
    "ShapeMismatch: unable to vstack, column names don't match: \"a\" and \"b\"",
  )
  // a frame without columns is
  let out = @pl.DataFrame::new([]).vstack(b1)
  assert_eq(out.columns(), ["b"])
  assert_eq(out.height(), 1)
  // same name: the rows are appended
  let a1 = @pl.DataFrame::new([@pl.Series::int64("a", [1L])])
  assert_eq(a0.vstack(a1).height(), 1)
}

///|
test "Float32 floor_div and rem with negative non-integers" {
  let x = @pl.Series::float32("x", [-7.5, 7.5, -0.5, 0.5, -1.0, 5.25])
  let d = @pl.Series::float32("d", [2.0, -2.0, 0.25, -0.3, 0.5, -1.5])
  assert_eq(x.floor_div(d).to_float32_array(), [
    Some(-4.0),
    Some(-4.0),
    Some(-2.0),
    Some(-2.0),
    Some(-2.0),
    Some(-4.0),
  ])
  // -0.10000002384185791 is the Float32 nearest to -0.1
  assert_eq(dt_bits32(x.rem(d).to_float32_array()), [
    Some((0.5 : Float).reinterpret_as_uint()),
    Some((-0.5 : Float).reinterpret_as_uint()),
    Some((0.0 : Float).reinterpret_as_uint()),
    Some(Float::from_double(-0.10000002384185791).reinterpret_as_uint()),
    Some((0.0 : Float).reinterpret_as_uint()),
    Some((-0.75 : Float).reinterpret_as_uint()),
  ])
}

///|
test "cast: a lenient cast makes null of what does not fit" {
  let big = @pl.Series::int64_nullable("b", [
    Some(3000000000L),
    Some(-3000000000L),
    Some(2147483647L),
    Some(-2147483648L),
    Some(2147483648L),
    None,
  ])
  assert_eq(big.cast(@pl.DataType::Int32, strict=false).to_int32_array(), [
    None,
    None,
    Some(2147483647),
    Some(-2147483648),
    None,
    None,
  ])
  let nan = 0.0 / 0.0
  let inf = 1.0 / 0.0
  let fl = @pl.Series::float64_nullable("f", [
    Some(3.0e9),
    Some(-3.0e9),
    Some(2147483647.0),
    Some(-2147483648.0),
    Some(2147483648.0),
    Some(nan),
    Some(inf),
    Some(1.0e20),
    Some(1.5),
    Some(-1.5),
    None,
  ])
  assert_eq(fl.cast(@pl.DataType::Int32, strict=false).to_int32_array(), [
    None,
    None,
    Some(2147483647),
    Some(-2147483648),
    None,
    None,
    None,
    None,
    Some(1),
    Some(-1),
    None,
  ])
  assert_eq(fl.cast(@pl.DataType::Int64, strict=false).to_int64_array(), [
    Some(3000000000L),
    Some(-3000000000L),
    Some(2147483647L),
    Some(-2147483648L),
    Some(2147483648L),
    None,
    None,
    None,
    Some(1L),
    Some(-1L),
    None,
  ])
  let fb = @pl.Series::float64("f", [
    9.3e18, -9.3e18, 9.223372036854775807e18, -9.223372036854775808e18, 1.0e19,
  ])
  assert_eq(fb.cast(@pl.DataType::Int64, strict=false).to_int64_array(), [
    None,
    None,
    None,
    Some(-9223372036854775808L),
    None,
  ])
}

///|
test "round near 2^51 and with many decimals" {
  let p51 = 2251799813685248.0 // 2^51
  let x = @pl.Series::float64("x", [
    p51 + 0.5,
    p51 - 0.5,
    4503599627370496.0 + 1.0,
    -p51 - 0.5,
    4503599627370495.5,
    0.5,
    1.5,
    2.5,
    -0.5,
  ])
  assert_eq(
    dt_bits64(x.round().to_float64_array()),
    dt_bits64([
      Some(2251799813685248.0),
      Some(2251799813685248.0),
      Some(4503599627370497.0),
      Some(-2251799813685248.0),
      Some(4503599627370496.0),
      Some(0.0),
      Some(2.0),
      Some(2.0),
      Some(-0.0),
    ]),
  )
  assert_eq(
    dt_bits64(x.round(decimals=2).to_float64_array()),
    dt_bits64([
      Some(2251799813685248.5),
      Some(2251799813685247.2),
      Some(4503599627370497.0),
      Some(-2251799813685248.5),
      Some(4503599627370495.5),
      Some(0.5),
      Some(1.5),
      Some(2.5),
      Some(-0.5),
    ]),
  )
  let y = @pl.Series::float64("y", [
    1.2345678901234567e20, 123456.789, 0.000123456, 1.0e-20, 2.5e15, 1.005, 2.675,
  ])
  let want : Array[(Int32, Array[Double])] = [
    (
      14,
      [
        1.2345678901234567e20, 123456.789, 0.000123456, 0.0, 2.5e15, 1.005, 2.675,
      ],
    ),
    (
      15,
      [
        1.2345678901234567e20, 123456.78900000002, 0.000123456, 0.0, 2.5e15, 1.005,
        2.675,
      ],
    ),
    (
      16,
      [
        1.2345678901234567e20, 123456.789, 0.000123456, 0.0, 2.5e15, 1.005, 2.675,
      ],
    ),
    (
      17,
      [
        1.2345678901234567e20, 123456.78899999999, 0.000123456, 0.0, 2.5e15, 1.005,
        2.675,
      ],
    ),
    (
      20,
      [
        1.2345678901234567e20, 123456.78900000002, 0.000123456, 1.0e-20, 2.5e15,
        1.005, 2.675,
      ],
    ),
    (
      25,
      [
        1.2345678901234567e20, 123456.789, 0.000123456, 1.0e-20, 2.5e15, 1.005, 2.675,
      ],
    ),
    (
      300,
      [
        1.2345678901234567e20, 123456.789, 0.000123456, 1.0e-20, 2.5e15, 1.005, 2.675,
      ],
    ),
    (
      400,
      [
        1.2345678901234567e20, 123456.789, 0.000123456, 1.0e-20, 2.5e15, 1.005, 2.675,
      ],
    ),
  ]
  for w in want {
    let (d, vals) = w
    assert_eq(
      dt_bits64(y.round(decimals=d).to_float64_array()),
      dt_bits64(vals.map(v => Some(v))),
    )
  }
}

///|
test "cum_sum of Float32 and Float64 starting with -0.0" {
  let z = @pl.Series::float32("z", [-0.0, -0.0, 0.0, 1.0])
  let zero : Float = 0.0
  let one : Float = 1.0
  assert_eq(dt_bits32(z.cum_sum().to_float32_array()), [
    Some(zero.reinterpret_as_uint()),
    Some(zero.reinterpret_as_uint()),
    Some(zero.reinterpret_as_uint()),
    Some(one.reinterpret_as_uint()),
  ])
  assert_eq(dt_bits32(z.cum_sum(reverse=true).to_float32_array()), [
    Some(one.reinterpret_as_uint()),
    Some(one.reinterpret_as_uint()),
    Some(one.reinterpret_as_uint()),
    Some(one.reinterpret_as_uint()),
  ])
  let n = @pl.Series::float32_nullable("z", [None, Some(-0.0), Some(-0.0)])
  assert_eq(dt_bits32(n.cum_sum().to_float32_array()), [
    None,
    Some(zero.reinterpret_as_uint()),
    Some(zero.reinterpret_as_uint()),
  ])
  let g = @pl.Series::float32_nullable("z", [
    Some(-0.0),
    None,
    Some(-0.0),
    Some(0.0),
  ])
  assert_eq(dt_bits32(g.cum_sum().to_float32_array()), [
    Some(zero.reinterpret_as_uint()),
    None,
    Some(zero.reinterpret_as_uint()),
    Some(zero.reinterpret_as_uint()),
  ])
  let d = @pl.Series::float64("z", [-0.0, -0.0, 0.0, 1.0])
  assert_eq(
    dt_bits64(d.cum_sum().to_float64_array()),
    dt_bits64([Some(0.0), Some(0.0), Some(0.0), Some(1.0)]),
  )
}

///|
test "fill_null with Min and Max: the sign of a zero" {
  // polars 2.1.0: the filled value is the first zero of the column for both
  // strategies (here -0.0 sits before 0.0 and the other way round)
  let w = @pl.Series::float64_nullable("w", [None, Some(-0.0), Some(0.0), None])
  let w2 = @pl.Series::float64_nullable("w", [None, Some(0.0), Some(-0.0), None])
  let run = (s : @pl.Series, st : @pl.FillStrategy) => {
    dt_bits64(s.fill_null_strategy(st).to_float64_array())
  }
  // what polars gives (kept in known-diffs/sequence.md if the library differs)
  let polars_min = dt_bits64([Some(0.0), Some(-0.0), Some(0.0), Some(0.0)])
  let polars_max = dt_bits64([Some(0.0), Some(-0.0), Some(0.0), Some(0.0)])
  let polars_min2 = dt_bits64([Some(-0.0), Some(0.0), Some(-0.0), Some(-0.0)])
  let polars_max2 = dt_bits64([Some(-0.0), Some(0.0), Some(-0.0), Some(-0.0)])
  assert_eq(run(w, Min), polars_min)
  assert_eq(run(w, Max), polars_max)
  assert_eq(run(w2, Min), polars_min2)
  assert_eq(run(w2, Max), polars_max2)
}

///|
// Deep chains: printing and folding walk the left spine once. The depth is
// kept below what wasm-gc and js can recurse (about 700); the timing of the
// 5000 and 10000 terms is in `bench_test.mbt` (they were quadratic).
test "an expression chain of 500 terms prints and folds" {
  let mut e = @pl.col("a")
  let mut w = @pl.lit_int(1L)
  for _ in 0..<500 {
    e = e + @pl.lit_int(1L)
    w = w + @pl.lit_int(1L)
  }
  let text = e.to_string()
  assert_true(text.has_prefix("[([([(["))
  assert_true(text.has_suffix(") + (dyn int: 1)]"))
  let tail = ") + (dyn int: 1)]"
  assert_eq(
    text.length(),
    500 * 2 + "col(\"a\")".length() + 500 * tail.length(),
  )
  let df = @pl.DataFrame::new([@pl.Series::int64("a", [1L, 2L, 3L])])
  assert_eq(df.select([e.alias("x")]).column("x").to_int64_array(), [
    Some(501L),
    Some(502L),
    Some(503L),
  ])
  // a literal-only expression is one row
  assert_eq(df.select([w.alias("w")]).column("w").to_int64_array(), [Some(501L)])
}
