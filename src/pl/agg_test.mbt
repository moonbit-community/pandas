///|
/// `<Variant>: <message>` of the error `f` raises, `"no error"` when it
/// returns.
fn[T] agg_err(f : () -> T raise @pl.PolarsError) -> String {
  match raises(f) {
    Some(e) => e.to_string()
    None => "no error"
  }
}

///|
test "sum of all null is zero, mean is null" {
  let s = @pl.Series::int64_nullable("a", [None, None])
  assert_eq(s.sum(), @pl.AnyValue::Int64(0L))
  assert_eq(s.mean(), @pl.AnyValue::Null)
  assert_eq(s.count(), 0)
}

///|
test "sum: types, wrap-around, empty and Null" {
  assert_eq(
    @pl.Series::int32("a", [2147483647, 1]).sum(),
    @pl.AnyValue::Int32(-2147483648),
  )
  assert_eq(
    @pl.Series::int64("a", [9223372036854775807L, 1L]).sum(),
    @pl.AnyValue::Int64(-9223372036854775808L),
  )
  assert_eq(
    @pl.Series::int32_nullable("a", [Some(1), None, Some(4)]).sum(),
    @pl.AnyValue::Int32(5),
  )
  assert_eq(@pl.Series::int32("a", []).sum(), @pl.AnyValue::Int32(0))
  assert_eq(@pl.Series::float64("a", []).sum(), @pl.AnyValue::Float64(0.0))
  assert_eq(
    @pl.Series::float64_nullable("a", [None]).sum(),
    @pl.AnyValue::Float64(0.0),
  )
  assert_eq(
    @pl.Series::float32("a", [1.5, 2.0]).sum(),
    @pl.AnyValue::Float32(3.5),
  )
  // Boolean counts the true values, as an Int64
  assert_eq(
    @pl.Series::bool_nullable("a", [Some(true), None, Some(true), Some(false)]).sum(),
    @pl.AnyValue::Int64(2L),
  )
  // the Null type sums to a null
  assert_eq(@pl.Series::null("a", 3).sum(), @pl.AnyValue::Null)
  // text and temporal types have no sum
  assert_eq(
    agg_err(() => @pl.Series::str("a", ["x"]).sum()),
    "InvalidOperation: `sum` operation not supported for dtype `str`",
  )
  assert_eq(
    agg_err(() => @pl.Series::date("a", [1]).sum()),
    "InvalidOperation: `sum` operation not supported for dtype `date`",
  )
  assert_eq(
    agg_err(() => @pl.Series::datetime("a", [1L]).sum()),
    "InvalidOperation: `sum` operation not supported for dtype `datetime[μs]`",
  )
}

///|
test "sum: NaN and infinities" {
  assert_true(
    @pl.Series::float64("a", [1.0, 0.0 / 0.0]).sum() is Float64(x) && x.is_nan(),
  )
  assert_true(
    @pl.Series::float64("a", [1.0 / 0.0, -1.0 / 0.0]).sum() is Float64(x) &&
    x.is_nan(),
  )
  assert_eq(
    @pl.Series::float64("a", [1.0 / 0.0, 1.0]).sum(),
    @pl.AnyValue::Float64(1.0 / 0.0),
  )
}

///|
test "mean: result types, null and error" {
  assert_eq(@pl.Series::int32("a", [1, 2]).mean(), @pl.AnyValue::Float64(1.5))
  assert_eq(
    @pl.Series::int64_nullable("a", [Some(1L), None, Some(2L)]).mean(),
    @pl.AnyValue::Float64(1.5),
  )
  assert_eq(
    @pl.Series::float32("a", [1.0, 2.0]).mean(),
    @pl.AnyValue::Float32(1.5),
  )
  assert_eq(
    @pl.Series::bool("a", [true, false]).mean(),
    @pl.AnyValue::Float64(0.5),
  )
  assert_eq(@pl.Series::int32("a", []).mean(), @pl.AnyValue::Null)
  assert_eq(@pl.Series::null("a", 2).mean(), @pl.AnyValue::Null)
  // Date and Datetime average to a Datetime (truncated to a microsecond)
  assert_eq(
    @pl.Series::date("a", [0, 5]).mean(),
    @pl.AnyValue::Datetime(216000000000L),
  )
  assert_eq(
    @pl.Series::datetime("a", [-3L, -2L]).mean(),
    @pl.AnyValue::Datetime(-2L),
  )
  assert_eq(
    agg_err(() => @pl.Series::str("a", ["x"]).mean()),
    "InvalidOperation: `mean` operation not supported for dtype `str`",
  )
}

///|
test "min and max: types, null, NaN, code point order" {
  let s = @pl.Series::int32_nullable("a", [Some(3), None, Some(-1), Some(2)])
  assert_eq(s.min(), @pl.AnyValue::Int32(-1))
  assert_eq(s.max(), @pl.AnyValue::Int32(3))
  assert_eq(@pl.Series::int64("a", []).min(), @pl.AnyValue::Null)
  assert_eq(@pl.Series::int64_nullable("a", [None]).max(), @pl.AnyValue::Null)
  assert_eq(@pl.Series::null("a", 2).min(), @pl.AnyValue::Null)
  assert_eq(@pl.Series::null("a", 2).max(), @pl.AnyValue::Null)
  // Boolean: false < true
  assert_eq(
    @pl.Series::bool("a", [true, false]).min(),
    @pl.AnyValue::Boolean(false),
  )
  assert_eq(
    @pl.Series::bool("a", [false, false]).max(),
    @pl.AnyValue::Boolean(false),
  )
  assert_eq(@pl.Series::date("a", [5, -2, 3]).min(), @pl.AnyValue::Date(-2))
  assert_eq(
    @pl.Series::datetime("a", [5L, -2L, 3L]).max(),
    @pl.AnyValue::Datetime(5L),
  )
  // NaN is ignored unless every value is NaN
  let nan = 0.0 / 0.0
  let f = @pl.Series::float64_nullable("a", [
    Some(1.0),
    Some(nan),
    None,
    Some(-1.0 / 0.0),
  ])
  assert_eq(f.min(), @pl.AnyValue::Float64(-1.0 / 0.0))
  assert_eq(f.max(), @pl.AnyValue::Float64(1.0))
  assert_true(
    @pl.Series::float64("a", [nan, nan]).max() is Float64(x) && x.is_nan(),
  )
  assert_true(
    @pl.Series::float32("a", [Float::from_double(nan)]).min() is Float32(x) &&
    x.is_nan(),
  )
  // strings order by code point: U+FF61 < U+1F600 although the UTF-16
  // surrogate of the second is smaller
  let t = @pl.Series::str_nullable("a", [
    Some("\u{FF61}"),
    Some("\u{1F600}"),
    Some("a"),
    Some(""),
    Some("Z"),
    None,
  ])
  assert_eq(t.min(), @pl.AnyValue::String(""))
  assert_eq(t.max(), @pl.AnyValue::String("\u{1F600}"))
  assert_eq(
    @pl.Series::str("a", ["\u{FF61}", "\u{1F600}"]).min(),
    @pl.AnyValue::String("\u{FF61}"),
  )
}

///|
test "first and last keep nulls" {
  let s = @pl.Series::int32_nullable("a", [None, Some(2), Some(3), None])
  assert_eq(s.first(), @pl.AnyValue::Null)
  assert_eq(s.last(), @pl.AnyValue::Null)
  let t = @pl.Series::str_nullable("a", [Some("x"), None, Some("z")])
  assert_eq(t.first(), @pl.AnyValue::String("x"))
  assert_eq(t.last(), @pl.AnyValue::String("z"))
  assert_eq(@pl.Series::float64("a", []).first(), @pl.AnyValue::Null)
  assert_eq(@pl.Series::float64("a", []).last(), @pl.AnyValue::Null)
  assert_eq(@pl.Series::null("a", 2).first(), @pl.AnyValue::Null)
  assert_eq(@pl.Series::null("a", 0).last(), @pl.AnyValue::Null)
  assert_eq(@pl.Series::date("a", [4, 5]).last(), @pl.AnyValue::Date(5))
  assert_eq(
    @pl.Series::bool("a", [true, false]).first(),
    @pl.AnyValue::Boolean(true),
  )
}

///|
test "count skips nulls" {
  assert_eq(
    @pl.Series::int32_nullable("a", [Some(1), None, Some(3)]).count(),
    2,
  )
  assert_eq(@pl.Series::str("a", []).count(), 0)
  assert_eq(@pl.Series::null("a", 4).count(), 0)
  assert_eq(@pl.Series::bool("a", [true, false]).count(), 2)
}

///|
test "median and quantile: methods and null" {
  let s = @pl.Series::float64("a", [3.0, 1.0, 4.0, 1.0, 5.0, 9.0, 2.0, 6.0])
  assert_eq(s.median(), @pl.AnyValue::Float64(3.5))
  // sorted: 1 1 2 3 4 5 6 9, position 0.25 * 7 = 1.75
  assert_eq(s.quantile(0.25), @pl.AnyValue::Float64(2.0))
  assert_eq(s.quantile(0.25, interpolation=Nearest), @pl.AnyValue::Float64(2.0))
  assert_eq(s.quantile(0.25, interpolation=Higher), @pl.AnyValue::Float64(2.0))
  assert_eq(s.quantile(0.25, interpolation=Lower), @pl.AnyValue::Float64(1.0))
  assert_eq(
    s.quantile(0.25, interpolation=Midpoint),
    @pl.AnyValue::Float64(1.5),
  )
  assert_eq(s.quantile(0.25, interpolation=Linear), @pl.AnyValue::Float64(1.75))
  assert_eq(
    s.quantile(0.25, interpolation=Equiprobable),
    @pl.AnyValue::Float64(1.0),
  )
  assert_eq(s.quantile(0.0), @pl.AnyValue::Float64(1.0))
  assert_eq(s.quantile(1.0), @pl.AnyValue::Float64(9.0))
  // integers give Float64, a Float32 column stays Float32
  assert_eq(
    @pl.Series::int32("a", [1, 2, 4]).quantile(0.5, interpolation=Linear),
    @pl.AnyValue::Float64(2.0),
  )
  assert_eq(
    @pl.Series::int64("a", [1L, 2L]).median(),
    @pl.AnyValue::Float64(1.5),
  )
  assert_eq(
    @pl.Series::float32("a", [1.0, 2.0]).median(),
    @pl.AnyValue::Float32(1.5),
  )
  // nulls are left out; NaN sorts last
  let n = @pl.Series::float64_nullable("a", [None, Some(2.0), None, Some(4.0)])
  assert_eq(n.median(), @pl.AnyValue::Float64(3.0))
  let nan = 0.0 / 0.0
  let w = @pl.Series::float64("a", [nan, 1.0, 2.0])
  assert_eq(w.median(), @pl.AnyValue::Float64(2.0))
  assert_true(w.quantile(1.0) is Float64(x) && x.is_nan())
  // empty, all null, Null and one value
  assert_eq(@pl.Series::int32("a", []).median(), @pl.AnyValue::Null)
  assert_eq(
    @pl.Series::int32_nullable("a", [None]).quantile(0.5),
    @pl.AnyValue::Null,
  )
  assert_eq(@pl.Series::null("a", 2).median(), @pl.AnyValue::Null)
  assert_eq(
    @pl.Series::int32("a", [7]).quantile(0.3),
    @pl.AnyValue::Float64(7.0),
  )
  // temporal: Date and Datetime give a Datetime
  assert_eq(
    @pl.Series::date("a", [0, 5]).median(),
    @pl.AnyValue::Datetime(216000000000L),
  )
  assert_eq(
    @pl.Series::datetime("a", [0L, 5L]).quantile(1.0),
    @pl.AnyValue::Datetime(5L),
  )
  assert_eq(@pl.Series::date("a", []).quantile(0.5), @pl.AnyValue::Null)
  // Boolean has a median but no quantile
  assert_eq(
    @pl.Series::bool("a", [true, false]).median(),
    @pl.AnyValue::Float64(0.5),
  )
}

///|
test "quantile: errors" {
  let s = @pl.Series::int32("a", [1, 2])
  assert_eq(
    agg_err(() => s.quantile(1.5)),
    "ComputeError: quantile should be between 0.0 and 1.0, got 1.5",
  )
  assert_eq(
    agg_err(() => s.quantile(-0.1)),
    "ComputeError: quantile should be between 0.0 and 1.0, got -0.1",
  )
  assert_eq(
    agg_err(() => s.quantile(0.0 / 0.0)),
    "ComputeError: quantile should be between 0.0 and 1.0, got NaN",
  )
  assert_eq(
    agg_err(() => s.quantile(1.0 / 0.0)),
    "ComputeError: quantile should be between 0.0 and 1.0, got inf",
  )
  assert_true(
    agg_err(() => @pl.Series::int32("a", []).quantile(2.0)).has_prefix(
      "ComputeError: ",
    ),
  )
  // the type is checked first
  assert_eq(
    agg_err(() => @pl.Series::str("a", ["x"]).quantile(1.5)),
    "InvalidOperation: `quantile` operation not supported for dtype `str`",
  )
  assert_eq(
    agg_err(() => @pl.Series::bool("a", [true]).quantile(0.5)),
    "InvalidOperation: `quantile` operation not supported for dtype `bool`",
  )
  assert_eq(
    agg_err(() => @pl.Series::null("a", 1).quantile(0.5)),
    "InvalidOperation: `quantile` operation not supported for dtype `null`",
  )
  assert_eq(
    agg_err(() => @pl.Series::str("a", ["x"]).median()),
    "InvalidOperation: `median` operation not supported for dtype `str`",
  )
}

///|
test "std and var: ddof, null, error" {
  let s = @pl.Series::float64("a", [1.0, 2.0])
  assert_eq(s.var_(), @pl.AnyValue::Float64(0.5))
  assert_eq(s.var_(ddof=0), @pl.AnyValue::Float64(0.25))
  assert_eq(s.std(ddof=0), @pl.AnyValue::Float64(0.5))
  assert_eq(s.std(), @pl.AnyValue::Float64(0.5.sqrt()))
  // not enough values for the degrees of freedom
  assert_eq(s.var_(ddof=2), @pl.AnyValue::Null)
  assert_eq(s.std(ddof=5), @pl.AnyValue::Null)
  assert_eq(@pl.Series::float64("a", [3.0]).var_(), @pl.AnyValue::Null)
  assert_eq(
    @pl.Series::float64("a", [3.0]).var_(ddof=0),
    @pl.AnyValue::Float64(0.0),
  )
  assert_eq(@pl.Series::float64("a", []).std(ddof=0), @pl.AnyValue::Null)
  assert_eq(
    @pl.Series::float64_nullable("a", [None, None]).var_(),
    @pl.AnyValue::Null,
  )
  // nulls are left out, integers and Boolean give Float64, Float32 stays
  assert_eq(
    @pl.Series::int32_nullable("a", [Some(1), None, Some(2)]).var_(),
    @pl.AnyValue::Float64(0.5),
  )
  assert_eq(
    @pl.Series::int64("a", [1L, 2L]).var_(ddof=0),
    @pl.AnyValue::Float64(0.25),
  )
  assert_eq(
    @pl.Series::bool("a", [true, false]).var_(),
    @pl.AnyValue::Float64(0.5),
  )
  assert_eq(
    @pl.Series::float32("a", [1.0, 2.0]).var_(),
    @pl.AnyValue::Float32(0.5),
  )
  assert_eq(@pl.Series::null("a", 2).var_(), @pl.AnyValue::Null)
  assert_true(
    @pl.Series::float64("a", [1.0, 0.0 / 0.0]).std() is Float64(x) && x.is_nan(),
  )
  // a stable algorithm: a large offset does not destroy the variance
  assert_eq(
    @pl.Series::float64("a", [1.0e9 + 1.0, 1.0e9 + 2.0, 1.0e9 + 3.0]).var_(),
    @pl.AnyValue::Float64(1.0),
  )
  assert_eq(
    agg_err(() => @pl.Series::str("a", ["x"]).std()),
    "InvalidOperation: `std` operation not supported for dtype `str`",
  )
  assert_eq(
    agg_err(() => @pl.Series::date("a", [1]).var_()),
    "InvalidOperation: `var` operation not supported for dtype `date`",
  )
  assert_eq(
    agg_err(() => s.var_(ddof=-1)),
    "InvalidOperation: ddof must not be negative, got -1",
  )
}

///|
test "product: types, wrap-around, null" {
  assert_eq(
    @pl.Series::int32("a", [2, 3, 4]).product(),
    @pl.AnyValue::Int64(24L),
  )
  // Int32 values multiply as Int64, so they do not wrap at 32 bits
  assert_eq(
    @pl.Series::int32("a", [2147483647, 2147483647, 2]).product(),
    @pl.AnyValue::Int64(9223372028264841218L),
  )
  assert_eq(
    @pl.Series::int64("a", [4294967296L, 4294967296L]).product(),
    @pl.AnyValue::Int64(0L),
  )
  assert_eq(
    @pl.Series::int64_nullable("a", [Some(2L), None, Some(5L)]).product(),
    @pl.AnyValue::Int64(10L),
  )
  assert_eq(
    @pl.Series::int64_nullable("a", [None]).product(),
    @pl.AnyValue::Int64(1L),
  )
  assert_eq(@pl.Series::float64("a", []).product(), @pl.AnyValue::Float64(1.0))
  assert_eq(
    @pl.Series::float32("a", [1.5, 2.0]).product(),
    @pl.AnyValue::Float32(3.0),
  )
  assert_eq(
    @pl.Series::bool("a", [true, true]).product(),
    @pl.AnyValue::Int64(1L),
  )
  assert_eq(
    @pl.Series::bool("a", [true, false]).product(),
    @pl.AnyValue::Int64(0L),
  )
  assert_eq(
    agg_err(() => @pl.Series::null("a", 1).product()),
    "InvalidOperation: `product` operation not supported for dtype `null`",
  )
  assert_eq(
    agg_err(() => @pl.Series::str("a", ["x"]).product()),
    "InvalidOperation: `product` operation not supported for dtype `str`",
  )
}

///|
test "QuantileMethod shows polars' names" {
  assert_eq(@pl.QuantileMethod::Nearest.to_string(), "nearest")
  assert_eq(@pl.QuantileMethod::Higher.to_string(), "higher")
  assert_eq(@pl.QuantileMethod::Lower.to_string(), "lower")
  assert_eq(@pl.QuantileMethod::Midpoint.to_string(), "midpoint")
  assert_eq(@pl.QuantileMethod::Linear.to_string(), "linear")
  assert_eq(@pl.QuantileMethod::Equiprobable.to_string(), "equiprobable")
  assert_eq(@pl.QuantileMethod::Nearest, @pl.QuantileMethod::Nearest)
  assert_true(@pl.QuantileMethod::Nearest != @pl.QuantileMethod::Linear)
}

///|
test "aggregations respect a slice and its validity window" {
  let s = @pl.Series::int32_nullable("a", [
    Some(1),
    None,
    Some(5),
    Some(7),
    None,
  ])
  let w = s.slice(1, length=3) // null, 5, 7
  assert_eq(w.sum(), @pl.AnyValue::Int32(12))
  assert_eq(w.count(), 2)
  assert_eq(w.first(), @pl.AnyValue::Null)
  assert_eq(w.last(), @pl.AnyValue::Int32(7))
  assert_eq(w.min(), @pl.AnyValue::Int32(5))
  assert_eq(w.mean(), @pl.AnyValue::Float64(6.0))
  assert_eq(w.median(), @pl.AnyValue::Float64(6.0))
}

///|
test "min and max skip a leading NaN" {
  let nan = 0.0 / 0.0
  let s = @pl.Series::float64("a", [nan, 1.0, 2.0])
  assert_eq(s.min(), @pl.AnyValue::Float64(1.0))
  assert_eq(s.max(), @pl.AnyValue::Float64(2.0))
  let t = @pl.Series::float32("a", [Float::from_double(nan), 3.0, -1.0])
  assert_eq(t.min(), @pl.AnyValue::Float32(-1.0))
  assert_eq(t.max(), @pl.AnyValue::Float32(3.0))
}

///|
test "variance of values with a large common offset stays accurate" {
  // 1e9 + i * 0.001: exact variance of the stored doubles, computed with
  // fractions (polars itself is only good to about 1e-7 here)
  let xs : Array[Double] = []
  for i in 0..<1000 {
    xs.push(1.0e9 + i.to_double() * 0.001)
  }
  let s = @pl.Series::float64("a", xs)
  assert_true(
    s.var_() is Float64(v) &&
    (v - 0.08341666666857711).abs() <= 1.0e-12 * 0.08341666666857711,
  )
  assert_true(
    s.std() is Float64(v) &&
    (v - 0.28881943609905675).abs() <= 1.0e-12 * 0.28881943609905675,
  )
  // integers beyond 2^53 are converted first, like polars: 6.0 there
  assert_eq(
    @pl.Series::int64("a", [
      9007199254740993L, 9007199254740993L, 9007199254740995L,
    ]).var_(),
    @pl.AnyValue::Float64(6.0),
  )
}

///|
/// `0.1 + (i % 3) * 0.001` for `i` below `n`, as doubles and as floats.
fn agg_long_series(n : Int32) -> (@pl.Series, @pl.Series) {
  let f64s : Array[Double] = []
  let f32s : Array[Float] = []
  for i in 0..<n {
    let v = 0.1 + (i % 3).to_double() * 0.001
    f64s.push(v)
    f32s.push(Float::from_double(v))
  }
  (@pl.Series::float64("a", f64s), @pl.Series::float32("a", f32s))
}

///|
test "sum and mean of long float series add in polars' pairwise order" {
  // expected values are polars 2.1.0's own (pl.lit(s).sum() / .mean()), bit
  // for bit: it adds blocks of 128 values pairwise (a plain left-to-right sum
  // of the Float32 series is off by 3e-4 at this length)
  let (d, f) = agg_long_series(60000)
  assert_eq(d.sum(), @pl.AnyValue::Float64(6059.999999999999))
  assert_eq(d.mean(), @pl.AnyValue::Float64(0.10099999999999998))
  assert_eq(
    f.sum(),
    @pl.AnyValue::Float32(Float::from_double(6060.00048828125)),
  )
  assert_eq(
    f.mean(),
    @pl.AnyValue::Float32(Float::from_double(0.10100000351667404)),
  )
}

///|
test "sum of 100000 floats agrees with polars to the relative tolerance" {
  // polars splits such a long array over its threads, so the last digits
  // depend on the machine: 10099.9990234375 (Float32) there, 1e-6 allowed
  let (d, f) = agg_long_series(100000)
  assert_eq(d.sum(), @pl.AnyValue::Float64(10099.999))
  assert_eq(d.mean(), @pl.AnyValue::Float64(0.10099999))
  assert_true(
    f.sum() is Float32(x) &&
    (x.to_double() - 10099.9990234375).abs() <= 1.0e-6 * 10099.9990234375,
  )
}

///|
test "linear and midpoint of equal values give that value" {
  let inf = 1.0 / 0.0
  assert_eq(
    @pl.Series::float64("a", [inf, inf]).median(),
    @pl.AnyValue::Float64(inf),
  )
  let ninf = @pl.Series::float64("a", [-inf, -inf, -inf, -inf])
  for
    how in [
      @pl.QuantileMethod::Linear,
      @pl.QuantileMethod::Midpoint,
      @pl.QuantileMethod::Nearest,
      @pl.QuantileMethod::Higher,
      @pl.QuantileMethod::Lower,
      @pl.QuantileMethod::Equiprobable,
    ] {
    assert_eq(
      ninf.quantile(0.3, interpolation=how),
      @pl.AnyValue::Float64(-inf),
    )
  }
  assert_eq(
    @pl.Series::float64("a", [inf, inf, inf, inf]).quantile(
      0.3,
      interpolation=Linear,
    ),
    @pl.AnyValue::Float64(inf),
  )
  // unequal infinities still give NaN
  assert_true(
    @pl.Series::float64("a", [-inf, inf]).median() is Float64(x) && x.is_nan(),
  )
  assert_true(
    @pl.Series::float64("a", [-inf, 1.0]).median() is Float64(x) && x.is_nan(),
  )
}

///|
test "median and quantile keep the sign of an equal-valued zero" {
  let z = @pl.Series::float64("a", [-0.0, -0.0])
  assert_true(
    z.median() is Float64(x) && x == 0.0 && x.reinterpret_as_int64() < 0L,
  )
  let m = @pl.Series::float64("a", [-0.0, 0.0])
  for
    how in [
      @pl.QuantileMethod::Linear,
      @pl.QuantileMethod::Midpoint,
      @pl.QuantileMethod::Lower,
    ] {
    assert_true(
      m.quantile(0.5, interpolation=how) is Float64(x) &&
      x == 0.0 &&
      x.reinterpret_as_int64() < 0L,
    )
  }
}

///|
test "Date and Datetime linear quantile with nulls match polars to the microsecond" {
  // expected values are polars 2.1.0's (nulls sort first, so the position is
  // (n - 1) * q + null_count, and a Date is interpolated in days)
  assert_eq(
    @pl.Series::date_nullable("a", [None, Some(-15732), Some(1748), Some(-251)]).quantile(
      0.9,
      interpolation=Linear,
    ),
    @pl.AnyValue::Datetime(116484479999999L),
  )
  assert_eq(
    @pl.Series::date_nullable("a", [None, Some(-19938), Some(5025)]).quantile(
      0.4,
      interpolation=Linear,
    ),
    @pl.AnyValue::Datetime(-859921920000000L),
  )
  assert_eq(
    @pl.Series::datetime_nullable("a", [
      Some(13360766776295L),
      None,
      Some(-165814674872757L),
      Some(193603918930822L),
      Some(605936700547722L),
      Some(-320470126547339L),
    ]).quantile(0.9, interpolation=Linear),
    @pl.AnyValue::Datetime(441003587900961L),
  )
  assert_eq(
    @pl.Series::datetime_nullable("a", [
      Some(-883011251442479L),
      Some(665725334089615L),
      Some(263752702210181L),
      None,
    ]).quantile(0.05, interpolation=Linear),
    @pl.AnyValue::Datetime(-768334856077212L),
  )
}
