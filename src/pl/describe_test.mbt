///|
fn desc_f64(name : String, xs : Array[Double?]) -> @pl.Series {
  @pl.Series::float64_nullable(name, xs)
}

///|
fn desc_labels(df : @pl.DataFrame) -> Array[String?] raise @pl.PolarsError {
  df.column("statistic").to_str_array()
}

///|
test "describe of numeric columns gives Float64 rows in polars order" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32_nullable("i", [Some(1), Some(-1), Some(0), None, Some(7)]),
    @pl.Series::float64("f", [1.0, 2.0, 3.0, 4.0, 5.0]),
  ])
  let r = df.describe()
  assert_eq(r.shape(), (9, 3))
  assert_eq(r.columns(), ["statistic", "i", "f"])
  assert_eq(r.dtypes(), [
    @pl.DataType::String,
    @pl.DataType::Float64,
    @pl.DataType::Float64,
  ])
  assert_eq(desc_labels(r), [
    Some("count"),
    Some("null_count"),
    Some("mean"),
    Some("std"),
    Some("min"),
    Some("25%"),
    Some("50%"),
    Some("75%"),
    Some("max"),
  ])
  assert_eq(r.column("i").to_float64_array(), [
    Some(4.0),
    Some(1.0),
    Some(1.75),
    Some(3.593976442141304),
    Some(-1.0),
    Some(0.0),
    Some(1.0),
    Some(1.0),
    Some(7.0),
  ])
  assert_eq(r.column("f").to_float64_array(), [
    Some(5.0),
    Some(0.0),
    Some(3.0),
    Some(1.5811388300841898),
    Some(1.0),
    Some(2.0),
    Some(3.0),
    Some(4.0),
    Some(5.0),
  ])
}

///|
test "describe of String, Boolean and Null columns" {
  let df = @pl.DataFrame::new([
    @pl.Series::str_nullable("s", [
      Some("b"),
      None,
      Some("a"),
      Some("\u{1F600}"),
    ]),
    @pl.Series::bool_nullable("b", [Some(true), Some(false), None, Some(true)]),
    @pl.Series::null("n", 4),
  ])
  let r = df.describe()
  assert_eq(r.dtypes(), [
    @pl.DataType::String,
    @pl.DataType::String,
    @pl.DataType::Float64,
    @pl.DataType::Float64,
  ])
  assert_eq(r.column("s").to_str_array(), [
    Some("3"),
    Some("1"),
    None,
    None,
    Some("a"),
    None,
    None,
    None,
    Some("\u{1F600}"),
  ])
  let third = 2.0 / 3.0
  assert_eq(r.column("b").to_float64_array(), [
    Some(3.0),
    Some(1.0),
    Some(third),
    None,
    Some(0.0),
    None,
    None,
    None,
    Some(1.0),
  ])
  assert_eq(r.column("n").to_float64_array(), [
    Some(0.0),
    Some(4.0),
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  ])
}

///|
test "describe of Date and Datetime columns shows Python's str of the values" {
  let df = @pl.DataFrame::new([
    @pl.Series::date_nullable("d", [
      Some(0),
      Some(10),
      None,
      Some(19000),
      Some(5),
    ]),
    @pl.Series::datetime_nullable("t", [
      Some(0L),
      Some(10L),
      None,
      Some(19000L * 86400000000L),
      Some(5L),
    ]),
  ])
  let r = df.describe()
  assert_eq(r.dtypes(), [
    @pl.DataType::String,
    @pl.DataType::String,
    @pl.DataType::String,
  ])
  assert_eq(r.column("d").to_str_array(), [
    Some("4"),
    Some("1"),
    Some("1983-01-06 18:00:00"),
    None,
    Some("1970-01-01"),
    Some("1970-01-06"),
    Some("1970-01-11"),
    Some("1970-01-11"),
    Some("2022-01-08"),
  ])
  // the fraction is shown only when it is not zero
  assert_eq(r.column("t").to_str_array(), [
    Some("4"),
    Some("1"),
    Some("1983-01-03 00:00:00.000003"),
    None,
    Some("1970-01-01 00:00:00"),
    Some("1970-01-01 00:00:00.000005"),
    Some("1970-01-01 00:00:00.000010"),
    Some("1970-01-01 00:00:00.000010"),
    Some("2022-01-08 00:00:00"),
  ])
}

///|
test "describe percentiles: order, labels, 0 and 1, none" {
  let df = @pl.DataFrame::new([@pl.Series::int64("x", [1L, 2L, 3L, 4L, 10L])])
  let r = df.describe(percentiles=[0.9, 0.0, 1.0, 0.333, 0.5])
  assert_eq(desc_labels(r), [
    Some("count"),
    Some("null_count"),
    Some("mean"),
    Some("std"),
    Some("min"),
    Some("0%"),
    Some("33.3%"),
    Some("50%"),
    Some("90%"),
    Some("100%"),
    Some("max"),
  ])
  assert_eq(r.column("x").to_float64_array()[5:10].to_owned(), [
    Some(1.0),
    Some(2.0),
    Some(3.0),
    Some(10.0),
    Some(10.0),
  ])
  let none = df.describe(percentiles=[])
  assert_eq(desc_labels(none), [
    Some("count"),
    Some("null_count"),
    Some("mean"),
    Some("std"),
    Some("min"),
    Some("max"),
  ])
  assert_eq(none.shape(), (6, 2))
}

///|
test "describe interpolation reaches numeric and temporal columns" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("x", [1L, 2L, 3L, 4L, 10L]),
    @pl.Series::date("d", [0, 10, 3, 19000, 5]),
  ])
  let linear = df.describe(percentiles=[0.1, 0.9], interpolation=Linear)
  let xs = linear.column("x").to_float64_array()
  assert_true((xs[5].unwrap() - 1.4).abs() < 1.0e-12)
  assert_true((xs[6].unwrap() - 7.6).abs() < 1.0e-12)
  // a date is cut back to a whole day: 0 + 0.4 * 3 days is 1.2 days
  assert_eq(linear.column("d").to_str_array()[5:7].to_owned(), [
    Some("1970-01-02"),
    Some("2001-03-23"),
  ])
  let lower = df.describe(percentiles=[0.9], interpolation=Lower)
  assert_eq(lower.column("x").to_float64_array()[5], Some(4.0))
  assert_eq(lower.column("d").to_str_array()[5], Some("1970-01-11"))
  let mid = df.describe(percentiles=[0.1], interpolation=Midpoint)
  assert_eq(mid.column("x").to_float64_array()[5], Some(1.5))
  assert_eq(mid.column("d").to_str_array()[5], Some("1970-01-02"))
  // before the epoch a date is cut towards zero
  let neg = @pl.DataFrame::new([@pl.Series::date("d", [-1000, -2, -1])])
  let r = neg.describe(percentiles=[0.1], interpolation=Linear)
  assert_eq(r.column("d").to_str_array()[5], Some("1967-10-24"))
}

///|
test "describe with no rows or only nulls" {
  let empty = @pl.DataFrame::new([
    @pl.Series::int64("i", []),
    @pl.Series::str("s", []),
    @pl.Series::date("d", []),
    @pl.Series::bool("b", []),
  ])
  let r = empty.describe()
  assert_eq(r.shape(), (9, 5))
  assert_eq(r.column("i").to_float64_array(), [
    Some(0.0),
    Some(0.0),
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  ])
  assert_eq(r.column("s").to_str_array(), [
    Some("0"),
    Some("0"),
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  ])
  assert_eq(r.column("d").to_str_array(), [
    Some("0"),
    Some("0"),
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  ])
  assert_eq(r.column("b").to_float64_array(), [
    Some(0.0),
    Some(0.0),
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  ])
  let nulls = @pl.DataFrame::new([
    @pl.Series::int64_nullable("i", [None, None]),
    @pl.Series::date_nullable("d", [None, None]),
  ])
  let r2 = nulls.describe()
  assert_eq(r2.column("i").to_float64_array(), [
    Some(0.0),
    Some(2.0),
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  ])
  assert_eq(r2.column("d").to_str_array(), [
    Some("0"),
    Some("2"),
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  ])
}

///|
test "describe of floats with NaN, infinities and Float32" {
  let df = @pl.DataFrame::new([
    desc_f64("f", [Some(1.0), Some(0.0 / 0.0), None, Some(-1.0 / 0.0)]),
    @pl.Series::float32("g", [0.5, 0.25, 1.5, 0.75]),
  ])
  let r = df.describe()
  let f = r.column("f").to_float64_array()
  assert_eq(f[0], Some(3.0))
  assert_eq(f[1], Some(1.0))
  assert_true(f[2].unwrap().is_nan()) // mean
  assert_true(f[3].unwrap().is_nan()) // std
  assert_eq(f[4], Some(-1.0 / 0.0)) // min ignores NaN
  assert_eq(f[5], Some(1.0)) // 25%: NaN sorts after the numbers
  assert_true(f[7].unwrap().is_nan()) // 75%
  assert_eq(f[8], Some(1.0)) // max ignores NaN
  // a Float32 column shows its values widened
  let g = r.column("g").to_float64_array()
  assert_eq(g[2], Some(0.75))
  assert_eq(g[4], Some(0.25))
  assert_eq(g[8], Some(1.5))
  assert_eq(g[0], Some(4.0))
}

///|
test "describe errors" {
  let df = @pl.DataFrame::new([@pl.Series::int64("a", [1L, 2L])])
  assert_eq(
    cd_err(() => @pl.DataFrame::empty().describe()),
    @pl.InvalidOperation("cannot describe a DataFrame that has no columns").to_string(),
  )
  // no columns is reported before a bad percentile
  assert_eq(
    cd_err(() => @pl.DataFrame::empty().describe(percentiles=[2.0])),
    @pl.InvalidOperation("cannot describe a DataFrame that has no columns").to_string(),
  )
  let range = @pl.InvalidOperation(
    "`percentiles` must all be in the range [0, 1]",
  ).to_string()
  assert_eq(cd_err(() => df.describe(percentiles=[-0.1])), range)
  assert_eq(cd_err(() => df.describe(percentiles=[1.1])), range)
  assert_eq(cd_err(() => df.describe(percentiles=[0.5, 0.0 / 0.0])), range)
  assert_eq(cd_err(() => df.describe(percentiles=[1.0 / 0.0])), range)
  let dup = fn(name : String) {
    @pl.DuplicateColumn(
      "projections contained duplicate output name '\{name}'. It's possible that multiple expressions are returning the same default column name. If this is the case, try renaming the columns with `.alias(\"new_name\")` to avoid duplicate column names.",
    ).to_string()
  }
  assert_eq(cd_err(() => df.describe(percentiles=[0.5, 0.5])), dup("0.5:a"))
  assert_eq(
    cd_err(() => df.describe(percentiles=[0.9, 0.1, 0.9, 0.1])),
    dup("0.1:a"),
  )
  assert_eq(cd_err(() => df.describe(percentiles=[1.0, 1.0])), dup("1.0:a"))
  assert_eq(
    cd_err(() => df.describe(percentiles=[1.0e-7, 1.0e-7])),
    dup("1e-07:a"),
  )
  // -0.0 and 0.0 are different names in polars
  let zeros = df.describe(percentiles=[0.0, -0.0])
  assert_eq(zeros.height(), 8)
  assert_eq(
    cd_err(() => {
      @pl.DataFrame::new([@pl.Series::int64("statistic", [1L])]).describe()
    }),
    @pl.DuplicateColumn(
      "column with name \"statistic\" is already present in the DataFrame",
    ).to_string(),
  )
}

///|
test "describe percentile labels use six significant digits" {
  let df = @pl.DataFrame::new([@pl.Series::int64("x", [1L, 2L, 3L])])
  let r = df.describe(percentiles=[
    1.0e-7,
    0.07,
    0.1,
    0.125,
    0.333,
    1.0 / 3.0,
    0.999,
    0.9999999,
  ])
  assert_eq(desc_labels(r)[5:13].to_owned(), [
    Some("1e-05%"),
    Some("7%"),
    Some("10%"),
    Some("12.5%"),
    Some("33.3%"),
    Some("33.3333%"),
    Some("99.9%"),
    Some("100%"),
  ])
}

///|
test "describe does not change the frame" {
  let df = @pl.DataFrame::new([@pl.Series::int64("x", [3L, 1L, 2L])])
  let _ = df.describe()
  assert_eq(df.column("x").to_int64_array(), [Some(3L), Some(1L), Some(2L)])
}

///|
test "describe of the extremes of Date, Datetime and Int64 does not trap" {
  let df = @pl.DataFrame::new([
    @pl.Series::date("d", [-2147483648, 2147483647]),
    @pl.Series::datetime("t", [-9223372036854775808L, 9223372036854775807L]),
    @pl.Series::int64("i", [-9223372036854775808L, 9223372036854775807L]),
  ])
  let r = df.describe(percentiles=[0.0, 0.5], interpolation=Linear)
  assert_eq(r.shape(), (8, 4))
  assert_eq(r.column("d").to_str_array()[0], Some("2"))
  assert_eq(r.column("t").to_str_array()[0], Some("2"))
  assert_eq(r.column("i").to_float64_array()[4], Some(-9223372036854775808.0))
  assert_eq(r.column("i").to_float64_array()[7], Some(9223372036854775808.0))
  assert_eq(r.column("i").to_float64_array()[6], Some(0.0))
  // the 100% percentile of a Datetime rounds to 2^63 in a Float64 and does
  // not fit the type any more: polars raises the same error
  let msg = cd_err(() => df.describe(percentiles=[1.0], interpolation=Linear))
  assert_true(
    msg.has_prefix(
      "InvalidOperation: conversion from `f64` to `datetime[\u{3bc}s]` failed",
    ),
  )
}
