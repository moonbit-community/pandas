///|
fn agg_df() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int32_nullable("a", [Some(1), None, Some(3), Some(4)]),
    @pl.Series::float64_nullable("f", [Some(1.0), Some(2.0), None, Some(5.0)]),
    @pl.Series::str_nullable("s", [Some("b"), None, Some("a"), Some("c")]),
    @pl.Series::bool_nullable("p", [Some(true), None, Some(false), Some(true)]),
    @pl.Series::null("n", 4),
  ])
}

///|
/// The only value of the aggregate `e` of the frame.
fn agg_value(df : @pl.DataFrame, e : @pl.Expr) -> @pl.AnyValue raise {
  let s = df.select([e]).get_columns()[0]
  assert_eq(s.len(), 1)
  s.to_list()[0]
}

///|
/// The only value of the aggregate `e` as a double, which must be within
/// 1e-12 of `expected`.
fn agg_close(df : @pl.DataFrame, e : @pl.Expr, expected : Double) -> Unit raise {
  match agg_value(df, e) {
    Float64(x) => assert_true((x - expected).abs() < 1.0e-12)
    v => fail("expected a Float64, got \{v}")
  }
}

///|
test "aggregations: values and result types" {
  let df = agg_df()
  let a = @pl.col("a")
  assert_eq(agg_value(df, a.sum()), @pl.AnyValue::Int32(8))
  agg_close(df, a.mean(), 8.0 / 3.0)
  assert_eq(agg_value(df, a.min()), @pl.AnyValue::Int32(1))
  assert_eq(agg_value(df, a.max()), @pl.AnyValue::Int32(4))
  assert_eq(agg_value(df, a.count()), @pl.AnyValue::Int64(3L))
  assert_eq(agg_value(df, a.len()), @pl.AnyValue::Int64(4L))
  assert_eq(agg_value(df, a.n_unique()), @pl.AnyValue::Int64(4L))
  assert_eq(agg_value(df, a.first()), @pl.AnyValue::Int32(1))
  assert_eq(agg_value(df, a.last()), @pl.AnyValue::Int32(4))
  assert_eq(agg_value(df, a.median()), @pl.AnyValue::Float64(3.0))
  assert_eq(agg_value(df, a.product()), @pl.AnyValue::Int64(12L))
  agg_close(df, a.std(), (7.0 / 3.0).sqrt())
  agg_close(df, a.std(ddof=0), (14.0 / 9.0).sqrt())
  agg_close(df, a.var_(), 7.0 / 3.0)
  agg_close(df, a.var_(ddof=0), 14.0 / 9.0)
  assert_eq(agg_value(df, a.quantile(0.5)), @pl.AnyValue::Float64(3.0))
  assert_eq(
    agg_value(df, a.quantile(0.5, interpolation=@pl.QuantileMethod::Linear)),
    @pl.AnyValue::Float64(3.0),
  )
  assert_eq(
    agg_value(
      df,
      @pl.col("f").quantile(0.25, interpolation=@pl.QuantileMethod::Lower),
    ),
    @pl.AnyValue::Float64(1.0),
  )
  // strings and booleans
  assert_eq(agg_value(df, @pl.col("s").min()), @pl.AnyValue::String("a"))
  assert_eq(agg_value(df, @pl.col("s").max()), @pl.AnyValue::String("c"))
  assert_eq(agg_value(df, @pl.col("p").sum()), @pl.AnyValue::Int64(2L))
  assert_eq(agg_value(df, @pl.col("p").max()), @pl.AnyValue::Boolean(true))
  // the output is named after the column; count, len, n_unique are Int64
  let out = df.select([a.count(), @pl.col("f").len(), @pl.col("s").n_unique()])
  assert_eq(out.columns(), ["a", "f", "s"])
  assert_eq(out.dtypes(), [@pl.DataType::Int64, Int64, Int64])
}

///|
test "aggregations: nulls, empty frames and Null columns" {
  let df = agg_df()
  // first/last keep a null; n_unique counts it
  assert_eq(agg_value(df, @pl.col("p").first()), @pl.AnyValue::Boolean(true))
  assert_eq(agg_value(df, @pl.col("s").n_unique()), @pl.AnyValue::Int64(4L))
  // a Null column
  assert_eq(agg_value(df, @pl.col("n").sum()), @pl.AnyValue::Null)
  assert_eq(agg_value(df, @pl.col("n").count()), @pl.AnyValue::Int64(0L))
  assert_eq(agg_value(df, @pl.col("n").len()), @pl.AnyValue::Int64(4L))
  assert_eq(agg_value(df, @pl.col("n").n_unique()), @pl.AnyValue::Int64(1L))
  assert_eq(agg_value(df, @pl.col("n").max()), @pl.AnyValue::Null)
  assert_eq(agg_value(df, @pl.col("n").median()), @pl.AnyValue::Null)
  // an empty frame: the sum is 0, the mean is null, one row each
  let empty = @pl.DataFrame::new([
    @pl.Series::int32("a", []),
    @pl.Series::str("s", []),
  ])
  let out = empty.select([@pl.col("a").sum(), @pl.col("a").mean().alias("m")])
  assert_eq(out.shape(), (1, 2))
  assert_eq(out.get_columns()[0].to_list(), [@pl.AnyValue::Int32(0)])
  assert_eq(out.get_columns()[1].to_list(), [@pl.AnyValue::Null])
  assert_eq(agg_value(empty, @pl.col("a").count()), @pl.AnyValue::Int64(0L))
  assert_eq(agg_value(empty, @pl.col("a").first()), @pl.AnyValue::Null)
  assert_eq(agg_value(empty, @pl.col("s").max()), @pl.AnyValue::Null)
  assert_eq(agg_value(empty, @pl.col("a").n_unique()), @pl.AnyValue::Int64(0L))
  assert_eq(agg_value(empty, @pl.col("a").product()), @pl.AnyValue::Int64(1L))
  // all null
  let nulls = @pl.DataFrame::new([@pl.Series::int32_nullable("a", [None, None])])
  assert_eq(agg_value(nulls, @pl.col("a").sum()), @pl.AnyValue::Int32(0))
  assert_eq(agg_value(nulls, @pl.col("a").mean()), @pl.AnyValue::Null)
  assert_eq(agg_value(nulls, @pl.col("a").std()), @pl.AnyValue::Null)
}

///|
test "aggregations: errors" {
  let df = agg_df()
  expect_error(
    raises(() => df.select([@pl.col("s").sum()])),
    "InvalidOperation",
    "`sum` operation not supported for dtype `str`",
  )
  expect_error(
    raises(() => df.select([@pl.col("p").quantile(0.5)])),
    "InvalidOperation",
    "`quantile` operation not supported for dtype `bool`",
  )
  expect_error(
    raises(() => df.select([@pl.col("n").product()])),
    "InvalidOperation",
    "`product` operation not supported for dtype `null`",
  )
  // the quantile range: backticks on a frame with rows, none on an empty one
  expect_error(
    raises(() => df.select([@pl.col("a").quantile(1.5)])),
    "ComputeError",
    "`quantile` should be between 0.0 and 1.0, got 1.5",
  )
  let empty = @pl.DataFrame::new([@pl.Series::int32("a", [])])
  expect_error(
    raises(() => empty.select([@pl.col("a").quantile(-0.1)])),
    "ComputeError",
    "quantile should be between 0.0 and 1.0, got -0.1",
  )
  expect_error_kind(
    raises(() => df.select([@pl.col("a").std(ddof=-1)])),
    "InvalidOperation",
  )
  expect_error_kind(
    raises(() => df.select([@pl.col("zz").sum()])),
    "ColumnNotFound",
  )
  // a missing column is reported before a type error
  expect_error_kind(
    raises(() => df.select([@pl.col("s").sum(), @pl.col("zz").max()])),
    "ColumnNotFound",
  )
}

///|
test "aggregates broadcast in select and with_columns" {
  let df = agg_df()
  let a = @pl.col("a")
  let out = df.select([a, a.sum().alias("total")])
  assert_eq(out.shape(), (4, 2))
  assert_eq(out.get_columns()[1].to_list(), [
    @pl.AnyValue::Int32(8),
    Int32(8),
    Int32(8),
    Int32(8),
  ])
  // all aggregates: one row
  let one = df.select([a.sum(), @pl.col("f").mean()])
  assert_eq(one.shape(), (1, 2))
  // with_columns repeats the row to the height of the frame
  let wc = df.with_columns([a.max().alias("m")])
  assert_eq(wc.shape(), (4, 6))
  assert_eq(wc.column("m").to_list(), [
    @pl.AnyValue::Int32(4),
    Int32(4),
    Int32(4),
    Int32(4),
  ])
  // a column minus its mean; a column over its sum (nulls stay null)
  let c = df.select([@pl.col("f") - @pl.col("f").mean()])
  assert_eq(c.get_columns()[0].to_float64_array(), [
    Some(1.0 - 8.0 / 3.0),
    Some(2.0 - 8.0 / 3.0),
    None,
    Some(5.0 - 8.0 / 3.0),
  ])
  let frac = df.select([(@pl.col("f") / @pl.col("f").sum()).alias("frac")])
  assert_eq(
    frac.get_columns()[0].to_float64_array()[3],
    Some(5.0 * (1.0 / 8.0)),
  )
  // an aggregate of an expression
  assert_eq(agg_value(df, (a + @pl.lit_int(1L)).sum()), @pl.AnyValue::Int32(11))
  // an empty frame: an aggregate next to a column has no rows
  let empty = @pl.DataFrame::new([@pl.Series::int32("a", [])])
  let e = empty.select([a, a.sum().alias("s")])
  assert_eq(e.shape(), (0, 2))
  let ew = empty.with_columns([a.sum().alias("s")])
  assert_eq(ew.shape(), (0, 2))
  // a frame without columns: aggregates of literals
  let z = @pl.DataFrame::empty().select([@pl.lit_int(2L).sum()])
  assert_eq(z.shape(), (1, 1))
}

///|
test "aggregations of selectors and with names" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2]),
    @pl.Series::int64("b", [10L, 20L]),
  ])
  let out = df.select([@pl.all().max()])
  assert_eq(out.columns(), ["a", "b"])
  assert_eq(out.get_columns()[1].to_list(), [@pl.AnyValue::Int64(20L)])
  // `alias` on a selector names every column alike
  expect_error_kind(
    raises(() => df.select([@pl.cols(["a", "b"]).sum().alias("x")])),
    "DuplicateColumn",
  )
  // two aggregates with the same name are a duplicate
  expect_error_kind(
    raises(() => df.select([@pl.col("a").sum(), @pl.col("a").max()])),
    "DuplicateColumn",
  )
  assert_eq(
    df
    .select([@pl.col("a").sum().alias("s"), @pl.col("a").max().alias("m")])
    .columns(),
    ["s", "m"],
  )
}

///|
test "aggregations print as polars does" {
  let a = @pl.col("a")
  assert_eq(a.sum().to_string(), "col(\"a\").sum()")
  assert_eq(a.n_unique().to_string(), "col(\"a\").n_unique()")
  assert_eq(a.std(ddof=0).to_string(), "col(\"a\").std()")
  assert_eq(a.var_(ddof=2).to_string(), "col(\"a\").var()")
  assert_eq(
    a.quantile(0.25, interpolation=@pl.QuantileMethod::Higher).to_string(),
    "col(\"a\").quantile([dyn float: 0.25])",
  )
  assert_eq((a - a.mean()).to_string(), "[(col(\"a\")) - (col(\"a\").mean())]")
  assert_eq(
    a.median().alias("z").to_string(),
    "col(\"a\").median().alias(\"z\")",
  )
}

// ---------------------------------------------------------------------------
// Element-wise functions
// ---------------------------------------------------------------------------

///|
test "is_nan, is_finite and friends" {
  let df = @pl.DataFrame::new([
    @pl.Series::float64_nullable("f", [
      Some(1.0),
      Some(0.0 / 0.0),
      None,
      Some(1.0 / 0.0),
    ]),
    @pl.Series::int32("i", [1, 2, 3, 4]),
    @pl.Series::null("n", 4),
    @pl.Series::str("s", ["a", "b", "c", "d"]),
  ])
  let f = @pl.col("f")
  assert_eq(expr_col(df, f.is_nan()).to_bool_array(), [
    Some(false),
    Some(true),
    None,
    Some(false),
  ])
  assert_eq(expr_col(df, f.is_not_nan()).to_bool_array(), [
    Some(true),
    Some(false),
    None,
    Some(true),
  ])
  assert_eq(expr_col(df, f.is_finite()).to_bool_array(), [
    Some(true),
    Some(false),
    None,
    Some(false),
  ])
  assert_eq(expr_col(df, f.is_infinite()).to_bool_array(), [
    Some(false),
    Some(false),
    None,
    Some(true),
  ])
  // integers are never NaN
  assert_eq(expr_col(df, @pl.col("i").is_nan()).to_bool_array(), [
    Some(false),
    Some(false),
    Some(false),
    Some(false),
  ])
  // a Null column gives all null
  assert_eq(expr_col(df, @pl.col("n").is_nan()).to_bool_array(), [
    None,
    None,
    None,
    None,
  ])
  assert_eq(expr_col(df, f.is_nan()).name(), "f")
  expect_error(
    raises(() => df.select([@pl.col("s").is_nan()])),
    "InvalidOperation",
    "`is_nan` operation not supported for dtype `str`",
  )
  // an aggregate is a length-1 input
  assert_eq(df.select([f.sum().is_nan()]).shape(), (1, 1))
}

///|
test "abs, sqrt, exp, log, round" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32_nullable("i", [Some(-4), None, Some(9)]),
    @pl.Series::float64("f", [-2.5, 1.0, 2.675]),
    @pl.Series::str("s", ["a", "b", "c"]),
    @pl.Series::null("n", 3),
  ])
  assert_eq(expr_col(df, @pl.col("i").abs()).to_int32_array(), [
    Some(4),
    None,
    Some(9),
  ])
  assert_eq(expr_col(df, @pl.col("f").abs()).to_float64_array(), [
    Some(2.5),
    Some(1.0),
    Some(2.675),
  ])
  assert_eq(expr_col(df, @pl.col("i").sqrt()).dtype(), @pl.DataType::Float64)
  assert_eq(expr_col(df, @pl.col("i").sqrt()).to_float64_array()[2], Some(3.0))
  assert_eq(
    expr_col(df, @pl.col("f").exp()).to_float64_array()[1],
    Some(@math.exp(1.0)),
  )
  assert_eq(
    expr_col(df, @pl.col("f").log(base=2.0)).to_float64_array()[1],
    Some(0.0),
  )
  assert_eq(expr_col(df, @pl.col("i").log()).to_float64_array()[1], None)
  assert_eq(expr_col(df, @pl.col("f").round()).to_float64_array(), [
    Some(-2.0),
    Some(1.0),
    Some(3.0),
  ])
  assert_eq(
    expr_col(df, @pl.col("f").round(decimals=2)).to_float64_array()[2],
    Some(2.68),
  )
  assert_eq(expr_col(df, @pl.col("i").round(decimals=1)).to_int32_array(), [
    Some(-4),
    None,
    Some(9),
  ])
  // a Null column: sqrt gives Float64 nulls, the others raise polars' errors
  assert_eq(expr_col(df, @pl.col("n").sqrt()).to_float64_array(), [
    None,
    None,
    None,
  ])
  expect_error(
    raises(() => df.select([@pl.col("n").abs()])),
    "InvalidOperation",
    "`abs` operation not supported for dtype `null`",
  )
  // strings are refused (spec 5.5)
  for
    e in [
      @pl.col("s").abs(),
      @pl.col("s").sqrt(),
      @pl.col("s").exp(),
      @pl.col("s").log(),
      @pl.col("s").round(),
    ] {
    expect_error_kind(raises(() => df.select([e])), "InvalidOperation")
  }
  expect_error(
    raises(() => df.select([@pl.col("f").round(decimals=-1)])),
    "InvalidOperation",
    "decimals must be non-negative, got -1",
  )
  // weak literals
  assert_eq(df.select([@pl.lit_int(-4L).abs()]).get_columns()[0].to_list(), [
    @pl.AnyValue::Int64(4L),
  ])
  assert_eq(df.select([@pl.lit_float(-2.5).abs()]).get_columns()[0].to_list(), [
    @pl.AnyValue::Float64(2.5),
  ])
  // composition
  assert_eq(
    expr_col(df, @pl.col("i").abs() + @pl.lit_int(1L)).to_int32_array(),
    [Some(5), None, Some(10)],
  )
}

///|
test "functions print as polars does" {
  let a = @pl.col("a")
  assert_eq(a.is_nan().to_string(), "col(\"a\").is_nan()")
  assert_eq(a.abs().to_string(), "col(\"a\").abs()")
  assert_eq(
    a.log().to_string(),
    "col(\"a\").log([dyn float: 2.718281828459045])",
  )
  assert_eq(a.log(base=2.0).to_string(), "col(\"a\").log([dyn float: 2])")
  assert_eq(a.log(base=10.0).to_string(), "col(\"a\").log([dyn float: 10])")
  assert_eq(a.round(decimals=3).to_string(), "col(\"a\").round()")
  assert_eq(
    a.fill_null(@pl.lit_int(0L)).to_string(),
    "col(\"a\").fill_null([dyn int: 0])",
  )
  assert_eq(
    a.is_in(@pl.Series::int32("v", [1])).to_string(),
    "col(\"a\").is_in([Series[v]])",
  )
  assert_eq(
    a.is_in(@pl.Series::int32("", [1])).to_string(),
    "col(\"a\").is_in([Series])",
  )
  assert_eq(
    a
    .between(@pl.lit_int(1L), @pl.col("b"), closed=@pl.ClosedInterval::Left)
    .to_string(),
    "col(\"a\").is_between([dyn int: 1, col(\"b\")])",
  )
}

// ---------------------------------------------------------------------------
// fill_null, is_in, between
// ---------------------------------------------------------------------------

///|
test "fill_null with a literal, a column and an aggregate" {
  let df = agg_df()
  let a = @pl.col("a")
  // a weak literal keeps the type
  let r = expr_col(df, a.fill_null(@pl.lit_int(0L)))
  assert_eq(r.dtype(), @pl.DataType::Int32)
  assert_eq(r.to_int32_array(), [Some(1), Some(0), Some(3), Some(4)])
  // a literal that does not fit promotes; a float promotes to Float64
  assert_eq(
    expr_col(df, a.fill_null(@pl.lit_int(3000000000L))).dtype(),
    @pl.DataType::Int64,
  )
  assert_eq(
    expr_col(df, a.fill_null(@pl.lit_float(1.5))).to_float64_array()[1],
    Some(1.5),
  )
  // row by row from a column
  let c = expr_col(df, @pl.col("f").fill_null(@pl.col("a")))
  assert_eq(c.to_float64_array(), [Some(1.0), Some(2.0), Some(3.0), Some(5.0)])
  // an aggregate fills every null
  let m = expr_col(df, @pl.col("f").fill_null(@pl.col("f").mean()))
  assert_eq(m.to_float64_array()[2], Some(8.0 / 3.0))
  // an aggregate as the filled value is repeated
  let rep = expr_col(df, @pl.col("n").first().fill_null(a))
  assert_eq(rep.to_int32_array(), [Some(1), None, Some(3), Some(4)])
  // text with a number is text
  assert_eq(
    expr_col(df, @pl.col("s").fill_null(@pl.lit_int(0L))).to_str_array(),
    [Some("b"), Some("0"), Some("a"), Some("c")],
  )
  // a Null column takes the type of the value
  assert_eq(
    expr_col(df, @pl.col("n").fill_null(@pl.lit_int(7L))).to_int32_array(),
    [Some(7), Some(7), Some(7), Some(7)],
  )
  // a null value leaves the null
  assert_eq(
    expr_col(df, a.fill_null(@pl.lit(@pl.AnyValue::Null))).to_int32_array(),
    [Some(1), None, Some(3), Some(4)],
  )
  // the name is the first operand's
  assert_eq(expr_col(df, @pl.lit_int(1L).fill_null(a)).name(), "literal")
  assert_eq(expr_col(df, a.fill_null(@pl.col("f")).alias("z")).name(), "z")
}

///|
test "fill_null errors" {
  let df = @pl.DataFrame::new([
    @pl.Series::date_nullable("d", [Some(1), None]),
    @pl.Series::bool_nullable("b", [Some(true), None]),
  ])
  expect_error(
    raises(() => df.select([@pl.col("d").fill_null(@pl.lit_int(0L))])),
    "InvalidOperation",
    "got invalid or ambiguous dtypes: '[date, dyn int]' in expression 'fill_null'",
  )
  expect_error(
    raises(() => df.select([@pl.lit_float(1.5).fill_null(@pl.col("d"))])),
    "InvalidOperation",
    "got invalid or ambiguous dtypes: '[dyn float, date]' in expression 'fill_null'",
  )
  expect_error(
    raises(() => df.select([@pl.col("b").fill_null(@pl.col("d"))])),
    "SchemaMismatch",
    "failed to determine supertype of bool and date",
  )
  expect_error_kind(
    raises(() => df.select([@pl.col("b").fill_null(@pl.col("zz"))])),
    "ColumnNotFound",
  )
  // a date is filled with a date
  let ok = df.select([@pl.col("d").fill_null(@pl.lit(@pl.AnyValue::Date(5)))])
  assert_eq(ok.get_columns()[0].to_list(), [@pl.AnyValue::Date(1), Date(5)])
}

///|
test "is_in" {
  let df = agg_df()
  let r = expr_col(df, @pl.col("a").is_in(@pl.Series::int64("v", [1L, 4L, 9L])))
  assert_eq(r.to_bool_array(), [Some(true), None, Some(false), Some(true)])
  assert_eq(r.name(), "a")
  let s = expr_col(df, @pl.col("s").is_in(@pl.Series::str("v", ["c", "a"])))
  assert_eq(s.to_bool_array(), [Some(false), None, Some(true), Some(true)])
  // an empty set; a Null column
  let e = expr_col(df, @pl.col("a").is_in(@pl.Series::int32("v", [])))
  assert_eq(e.to_bool_array(), [Some(false), None, Some(false), Some(false)])
  assert_eq(
    expr_col(df, @pl.col("n").is_in(@pl.Series::int32("v", [1]))).to_bool_array(),
    [None, None, None, None],
  )
  expect_error(
    raises(() => df.select([@pl.col("a").is_in(@pl.Series::str("v", ["x"]))])),
    "InvalidOperation",
    "'is_in' cannot check for Int32 values in List(String) data",
  )
  // inside an expression
  let n = expr_col(
    df,
    (@pl.col("a") + @pl.lit_int(1L)).is_in(@pl.Series::int32("v", [2, 5])),
  )
  assert_eq(n.to_bool_array(), [Some(true), None, Some(false), Some(true)])
}

///|
test "between" {
  let df = agg_df()
  let a = @pl.col("a")
  let both = expr_col(df, a.between(@pl.lit_int(1L), @pl.lit_int(3L)))
  assert_eq(both.to_bool_array(), [Some(true), None, Some(true), Some(false)])
  assert_eq(both.name(), "a")
  let left = expr_col(
    df,
    a.between(@pl.lit_int(1L), @pl.lit_int(3L), closed=@pl.ClosedInterval::Left),
  )
  assert_eq(left.to_bool_array(), [Some(true), None, Some(false), Some(false)])
  let right = expr_col(
    df,
    a.between(
      @pl.lit_int(1L),
      @pl.lit_int(3L),
      closed=@pl.ClosedInterval::Right,
    ),
  )
  assert_eq(right.to_bool_array(), [Some(false), None, Some(true), Some(false)])
  let nei = expr_col(
    df,
    a.between(
      @pl.lit_int(1L),
      @pl.lit_int(4L),
      closed=@pl.ClosedInterval::Neither,
    ),
  )
  assert_eq(nei.to_bool_array(), [Some(false), None, Some(true), Some(false)])
  // bounds that are aggregates; lower above upper is all false (null stays)
  let agg_bounds = expr_col(df, a.between(a.min(), a.max()))
  assert_eq(agg_bounds.to_bool_array(), [
    Some(true),
    None,
    Some(true),
    Some(true),
  ])
  let swapped = expr_col(df, a.between(@pl.lit_int(4L), @pl.lit_int(1L)))
  assert_eq(swapped.to_bool_array(), [
    Some(false),
    None,
    Some(false),
    Some(false),
  ])
  // a bound that is out of the range of Int32 still compares
  let wide = expr_col(
    df,
    a.between(@pl.lit_int(-3000000000L), @pl.lit_int(3000000000L)),
  )
  assert_eq(wide.to_bool_array(), [Some(true), None, Some(true), Some(true)])
  // a null bound: false where the other bound already decides
  let nb = expr_col(df, a.between(@pl.col("n"), @pl.lit_int(1L)))
  assert_eq(nb.to_bool_array(), [None, None, Some(false), Some(false)])
  expect_error(
    raises(() => {
      df.select([@pl.col("s").between(@pl.lit_int(1L), @pl.lit_int(3L))])
    }),
    "ComputeError",
    "cannot compare string with numeric type (i32)",
  )
  expect_error_kind(
    raises(() => df.select([a.between(@pl.col("zz"), @pl.lit_int(1L))])),
    "ColumnNotFound",
  )
}

///|
test "quantile out of range: backticks only when the column has a null" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("b", [10L, 20L, 30L, 40L]),
    @pl.Series::int64_nullable("n", [Some(1L), None, Some(3L), Some(4L)]),
    @pl.Series::int64_nullable("z", [None, None, None, None]),
  ])
  // no null: the text of the Series method
  expect_error(
    raises(() => df.select([@pl.col("b").quantile(1.5)])),
    "ComputeError",
    "quantile should be between 0.0 and 1.0, got 1.5",
  )
  // a null: backticks
  expect_error(
    raises(() => df.select([@pl.col("n").quantile(1.5)])),
    "ComputeError",
    "`quantile` should be between 0.0 and 1.0, got 1.5",
  )
  // all null counts as a null
  expect_error(
    raises(() => df.select([@pl.col("z").quantile(-0.5)])),
    "ComputeError",
    "`quantile` should be between 0.0 and 1.0, got -0.5",
  )
  // one row without a null
  let one = df.slice(0, length=1)
  expect_error(
    raises(() => one.select([@pl.col("b").quantile(2.0)])),
    "ComputeError",
    "quantile should be between 0.0 and 1.0, got 2",
  )
}

///|
test "between: the width errors come in the order self, lower, upper" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2]),
    @pl.Series::int32("h", [3, 4]),
    @pl.Series::int32("k", [5, 6]),
  ])
  // widths (2, 3, 0): the lower bound differs from self first
  expect_error(
    raises(() => {
      df.select([@pl.cols(["a", "h"]).between(@pl.all(), @pl.cols([]))])
    }),
    "InvalidOperation",
    "cannot combine selectors that produce a different number of columns (3 != 2)",
  )
  // widths (2, 1, 0): the upper bound is the first that differs
  expect_error(
    raises(() => {
      df.select([@pl.cols(["a", "h"]).between(@pl.col("k"), @pl.cols([]))])
    }),
    "InvalidOperation",
    "cannot combine selectors that produce a different number of columns (0 != 2)",
  )
}
