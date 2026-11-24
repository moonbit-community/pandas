///|
fn expr_df() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int32_nullable("a", [Some(1), None, Some(3)]),
    @pl.Series::int64("b", [10L, 20L, 30L]),
    @pl.Series::float32("f", [0.5, 1.5, 2.5]),
    @pl.Series::str("s", ["x", "y", "z"]),
    @pl.Series::bool_nullable("p", [Some(true), None, Some(false)]),
  ])
}

///|
/// Checks that `r` is the error `kind` (a `PolarsError` variant name) with
/// exactly `message`.
fn expect_error(
  r : @pl.PolarsError?,
  kind : String,
  message : String,
) -> Unit raise {
  match r {
    None => fail("expected \{kind}(\{message}), got no error")
    Some(e) => {
      let (k, m) = golden_error_parts(e)
      assert_eq(k, kind)
      assert_eq(m, message)
    }
  }
}

///|
fn expect_error_kind(r : @pl.PolarsError?, kind : String) -> Unit raise {
  match r {
    None => fail("expected \{kind}, got no error")
    Some(e) => assert_eq(golden_error_parts(e).0, kind)
  }
}

///|
fn expr_col(df : @pl.DataFrame, e : @pl.Expr) -> @pl.Series raise {
  df.select([e]).get_columns()[0]
}

// ---------------------------------------------------------------------------
// Weak literals
// ---------------------------------------------------------------------------

///|
test "weak int literal keeps column type" {
  let df = @pl.DataFrame::new([@pl.Series::int32("a", [1, 2])])
  let out = df.select([@pl.col("a") + @pl.lit_int(1L)])
  assert_eq(out.dtypes(), [@pl.DataType::Int32])
  assert_eq(out.columns(), ["a"])
  assert_eq(out.get_columns()[0].to_list(), [@pl.AnyValue::Int32(2), Int32(3)])
}

///|
test "aggregation-free select on empty frame" {
  let out = @pl.DataFrame::empty().select([@pl.lit_int(1L)])
  assert_eq(out.shape(), (1, 1))
  assert_eq(out.columns(), ["literal"])
}

///|
test "weak int literal out of the column's range promotes to Int64" {
  let df = expr_df()
  let r = expr_col(df, @pl.col("a") + @pl.lit_int(3_000_000_000L))
  assert_eq(r.dtype(), @pl.DataType::Int64)
  assert_eq(r.to_list(), [
    @pl.AnyValue::Int64(3_000_000_001L),
    Null,
    Int64(3_000_000_003L),
  ])
  // the boundaries of Int32
  let m = expr_col(df, @pl.col("a") + @pl.lit_int(2147483647L))
  assert_eq(m.dtype(), @pl.DataType::Int32)
  let m1 = expr_col(df, @pl.col("a") + @pl.lit_int(2147483648L))
  assert_eq(m1.dtype(), @pl.DataType::Int64)
  let n1 = expr_col(df, @pl.col("a") + @pl.lit_int(-2147483648L))
  assert_eq(n1.dtype(), @pl.DataType::Int32)
  let n2 = expr_col(df, @pl.col("a") + @pl.lit_int(-2147483649L))
  assert_eq(n2.dtype(), @pl.DataType::Int64)
}

///|
test "comparison with an out-of-range weak literal does not wrap" {
  let df = expr_df()
  let r = expr_col(df, @pl.col("a").eq(@pl.lit_int(1L << 40)))
  assert_eq(r.dtype(), @pl.DataType::Boolean)
  assert_eq(r.to_list(), [@pl.AnyValue::Boolean(false), Null, Boolean(false)])
  let lt = expr_col(df, @pl.col("a").lt(@pl.lit_int(1L << 40)))
  assert_eq(lt.to_list(), [@pl.AnyValue::Boolean(true), Null, Boolean(true)])
}

///|
test "weak float literal and Float32 columns" {
  let df = expr_df()
  let r = expr_col(df, @pl.col("f") * @pl.lit_float(2.0))
  assert_eq(r.dtype(), @pl.DataType::Float32)
  assert_eq(r.to_list(), [
    @pl.AnyValue::Float32(1.0),
    Float32(3.0),
    Float32(5.0),
  ])
  // 1e300 does not fit a Float32: infinity, still Float32
  let big = expr_col(df, @pl.col("f") * @pl.lit_float(1.0e300))
  assert_eq(big.dtype(), @pl.DataType::Float32)
  assert_true(big.to_float32_array()[0].unwrap().is_inf())
  // a Float32 column with a weak int stays Float32
  assert_eq(
    expr_col(df, @pl.col("f") + @pl.lit_int(1L)).dtype(),
    @pl.DataType::Float32,
  )
}

///|
test "weak float literal makes integer columns Float64" {
  let df = expr_df()
  let r = expr_col(df, @pl.col("a") * @pl.lit_float(1.5))
  assert_eq(r.dtype(), @pl.DataType::Float64)
  assert_eq(r.to_list(), [@pl.AnyValue::Float64(1.5), Null, Float64(4.5)])
}

///|
test "literals alone: weak ones are Int64 and Float64" {
  let df = expr_df()
  assert_eq(expr_col(df, @pl.lit_int(1L)).dtype(), @pl.DataType::Int64)
  assert_eq(expr_col(df, @pl.lit_float(1.0)).dtype(), @pl.DataType::Float64)
  assert_eq(expr_col(df, @pl.lit_int(1L) + @pl.lit_int(2L)).to_list(), [
    @pl.AnyValue::Int64(3L),
  ])
  assert_eq(expr_col(df, @pl.lit_int(1L) + @pl.lit_float(2.5)).to_list(), [
    @pl.AnyValue::Float64(3.5),
  ])
  // a strong literal keeps its type
  assert_eq(
    expr_col(df, @pl.lit(@pl.AnyValue::Int32(1))).dtype(),
    @pl.DataType::Int32,
  )
  assert_eq(
    expr_col(df, @pl.lit(@pl.AnyValue::Float32(1.5))).dtype(),
    @pl.DataType::Float32,
  )
  // the weak side of a strong literal is cast to it when it fits
  assert_eq(
    expr_col(df, @pl.lit(@pl.AnyValue::Int32(1)) + @pl.lit_int(2L)).dtype(),
    @pl.DataType::Int32,
  )
  assert_eq(
    expr_col(df, @pl.lit(@pl.AnyValue::Int32(1)) + @pl.lit_int(3_000_000_000L)).dtype(),
    @pl.DataType::Int64,
  )
}

///|
test "a strong literal does not adapt to the column" {
  let df = expr_df()
  let r = expr_col(df, @pl.col("a") + @pl.lit(@pl.AnyValue::Int64(1L)))
  assert_eq(r.dtype(), @pl.DataType::Int64)
  let g = expr_col(df, @pl.col("f") + @pl.lit(@pl.AnyValue::Float64(1.0)))
  assert_eq(g.dtype(), @pl.DataType::Float64)
}

///|
test "weak literals stay weak through alias, negation and arithmetic" {
  let df = expr_df()
  assert_eq(
    expr_col(df, @pl.col("a") + @pl.lit_int(5L).alias("x")).dtype(),
    @pl.DataType::Int32,
  )
  assert_eq(
    expr_col(df, @pl.col("a") + -@pl.lit_int(5L)).dtype(),
    @pl.DataType::Int32,
  )
  assert_eq(
    expr_col(df, @pl.col("a") + -@pl.lit_int(3_000_000_000L)).dtype(),
    @pl.DataType::Int64,
  )
  assert_eq(
    expr_col(df, @pl.col("a") + (@pl.lit_int(1L) + @pl.lit_int(2L))).dtype(),
    @pl.DataType::Int32,
  )
  // a cast makes it strong
  assert_eq(
    expr_col(df, @pl.col("a") + @pl.lit_int(1L).cast(@pl.DataType::Int64)).dtype(),
    @pl.DataType::Int64,
  )
  // 1 / 2 is a Float64, not a weak float
  assert_eq(
    expr_col(df, @pl.col("f") + @pl.lit_int(1L) / @pl.lit_int(2L)).dtype(),
    @pl.DataType::Float64,
  )
}

///|
test "weak literal against a non-number" {
  let df = expr_df()
  // against a Boolean column a literal is just a number
  let r = expr_col(df, @pl.col("p").eq(@pl.lit_int(1L)))
  assert_eq(r.to_list(), [@pl.AnyValue::Boolean(true), Null, Boolean(false)])
  // a String column cannot be compared with one: polars names Int32
  expect_error(
    raises(() => df.select([@pl.col("s").eq(@pl.lit_int(1L))])),
    "ComputeError",
    "cannot compare string with numeric type (i32)",
  )
  expect_error(
    raises(() => df.select([@pl.col("s").eq(@pl.lit_int(3_000_000_000L))])),
    "ComputeError",
    "cannot compare string with numeric type (i64)",
  )
  // against a Null literal the literal gets the smallest fitting type
  let n = expr_col(df, @pl.lit(@pl.AnyValue::Null) + @pl.lit_int(1L))
  assert_eq(n.dtype(), @pl.DataType::Int32)
  assert_eq(n.to_list(), [@pl.AnyValue::Null])
}

// ---------------------------------------------------------------------------
// Operators
// ---------------------------------------------------------------------------

///|
test "arithmetic operators" {
  let df = expr_df()
  let a = @pl.col("a")
  let b = @pl.col("b")
  assert_eq(expr_col(df, a + b).to_list(), [
    @pl.AnyValue::Int64(11L),
    Null,
    Int64(33L),
  ])
  assert_eq(expr_col(df, b - a).to_list(), [
    @pl.AnyValue::Int64(9L),
    Null,
    Int64(27L),
  ])
  assert_eq(expr_col(df, a * b).to_list(), [
    @pl.AnyValue::Int64(10L),
    Null,
    Int64(90L),
  ])
  assert_eq(expr_col(df, b / a).to_list(), [
    @pl.AnyValue::Float64(10.0),
    Null,
    Float64(10.0),
  ])
  assert_eq(expr_col(df, b % @pl.lit_int(7L)).to_list(), [
    @pl.AnyValue::Int64(3L),
    Int64(6L),
    Int64(2L),
  ])
  assert_eq(expr_col(df, b.floor_div(@pl.lit_int(7L))).to_list(), [
    @pl.AnyValue::Int64(1L),
    Int64(2L),
    Int64(4L),
  ])
  // floor division by zero is null, like polars
  assert_eq(expr_col(df, b.floor_div(@pl.lit_int(0L))).to_list(), [
    @pl.AnyValue::Null,
    Null,
    Null,
  ])
  assert_eq(expr_col(df, -a).to_list(), [
    @pl.AnyValue::Int32(-1),
    Null,
    Int32(-3),
  ])
}

///|
test "comparison, logic and null predicates" {
  let df = expr_df()
  let a = @pl.col("a")
  let p = @pl.col("p")
  assert_eq(expr_col(df, a.gt(@pl.lit_int(1L))).to_list(), [
    @pl.AnyValue::Boolean(false),
    Null,
    Boolean(true),
  ])
  assert_eq(expr_col(df, a.ge(@pl.lit_int(1L))).to_list(), [
    @pl.AnyValue::Boolean(true),
    Null,
    Boolean(true),
  ])
  assert_eq(expr_col(df, a.le(@pl.lit_int(1L))).to_list(), [
    @pl.AnyValue::Boolean(true),
    Null,
    Boolean(false),
  ])
  assert_eq(expr_col(df, a.neq(@pl.lit_int(1L))).to_list(), [
    @pl.AnyValue::Boolean(false),
    Null,
    Boolean(true),
  ])
  // Kleene logic: false & null is false, true | null is true
  assert_eq(expr_col(df, p & @pl.lit_bool(false)).to_list(), [
    @pl.AnyValue::Boolean(false),
    Boolean(false),
    Boolean(false),
  ])
  assert_eq(expr_col(df, p | @pl.lit_bool(true)).to_list(), [
    @pl.AnyValue::Boolean(true),
    Boolean(true),
    Boolean(true),
  ])
  assert_eq(expr_col(df, p.not_()).to_list(), [
    @pl.AnyValue::Boolean(false),
    Null,
    Boolean(true),
  ])
  assert_eq(expr_col(df, a.is_null()).to_list(), [
    @pl.AnyValue::Boolean(false),
    Boolean(true),
    Boolean(false),
  ])
  assert_eq(expr_col(df, a.is_not_null()).to_list(), [
    @pl.AnyValue::Boolean(true),
    Boolean(false),
    Boolean(true),
  ])
  // the string column compares by code point
  assert_eq(expr_col(df, @pl.col("s").lt(@pl.lit_str("y"))).to_list(), [
    @pl.AnyValue::Boolean(true),
    Boolean(false),
    Boolean(false),
  ])
}

///|
test "operator errors" {
  let df = expr_df()
  // strings and booleans have no arithmetic (spec 5.5)
  assert_true(
    raises(() => df.select([@pl.col("s") + @pl.col("s")]))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => df.select([@pl.col("p") + @pl.lit_int(1L)]))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => df.select([-@pl.col("s")])) is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => df.select([@pl.col("a").not_()]))
    is Some(@pl.InvalidOperation(_)),
  )
  // Boolean and a number do not compare... but a number and a string do not either
  assert_true(
    raises(() => df.select([@pl.col("a").eq(@pl.col("s"))]))
    is Some(@pl.ComputeError(_)),
  )
  // a missing column
  expect_error(
    raises(() => df.select([@pl.col("a") + @pl.col("zz")])),
    "ColumnNotFound",
    "unable to find column \"zz\"; valid columns: [\"a\", \"b\", \"f\", \"s\", \"p\"]",
  )
}

///|
test "null columns" {
  let df = @pl.DataFrame::new([
    @pl.Series::null("n", 3),
    @pl.Series::int32("a", [1, 2, 3]),
  ])
  let r = expr_col(df, @pl.col("n") + @pl.col("a"))
  assert_eq(r.dtype(), @pl.DataType::Int32)
  assert_eq(r.to_list(), [@pl.AnyValue::Null, Null, Null])
  let w = expr_col(df, @pl.col("n") + @pl.lit_int(1L))
  assert_eq(w.dtype(), @pl.DataType::Int32)
  assert_eq(expr_col(df, @pl.col("n").is_null()).to_list(), [
    @pl.AnyValue::Boolean(true),
    Boolean(true),
    Boolean(true),
  ])
  assert_eq(expr_col(df, @pl.col("n").is_not_null()).to_list(), [
    @pl.AnyValue::Boolean(false),
    Boolean(false),
    Boolean(false),
  ])
  assert_eq(
    expr_col(df, @pl.col("n").eq(@pl.col("n"))).dtype(),
    @pl.DataType::Boolean,
  )
}

// ---------------------------------------------------------------------------
// Names, alias, cast
// ---------------------------------------------------------------------------

///|
test "output names" {
  let df = expr_df()
  assert_eq(df.select([@pl.col("a")]).columns(), ["a"])
  assert_eq(df.select([@pl.col("b") + @pl.col("a")]).columns(), ["b"])
  assert_eq(df.select([@pl.lit_int(1L) + @pl.col("a")]).columns(), ["literal"])
  assert_eq(df.select([@pl.col("a") + @pl.lit_int(1L)]).columns(), ["a"])
  assert_eq(df.select([-(@pl.col("b") + @pl.col("a"))]).columns(), ["b"])
  assert_eq(df.select([@pl.col("p").not_()]).columns(), ["p"])
  assert_eq(df.select([@pl.col("a").is_null()]).columns(), ["a"])
  assert_eq(df.select([@pl.col("a").cast(@pl.DataType::Float64)]).columns(), [
    "a",
  ])
  assert_eq(df.select([@pl.lit_str("x")]).columns(), ["literal"])
  assert_eq(df.select([@pl.lit(@pl.AnyValue::Null)]).columns(), ["literal"])
}

///|
test "alias overrides the name" {
  let df = expr_df()
  assert_eq(df.select([@pl.col("a").alias("z")]).columns(), ["z"])
  assert_eq(df.select([@pl.col("a").alias("z").alias("y")]).columns(), ["y"])
  assert_eq(df.select([@pl.col("a").alias("z") + @pl.col("b")]).columns(), ["z"])
  assert_eq(df.select([@pl.col("a") + @pl.col("b").alias("z")]).columns(), ["a"])
  assert_eq(df.select([@pl.lit_int(1L).alias("one")]).columns(), ["one"])
  assert_eq(df.select([@pl.col("a").alias("")]).columns(), [""])
  // the data is untouched
  assert_eq(df.select([@pl.col("a").alias("z")]).get_columns()[0].to_list(), [
    @pl.AnyValue::Int32(1),
    Null,
    Int32(3),
  ])
}

///|
test "cast strict and lenient" {
  let df = expr_df()
  let f = expr_col(df, @pl.col("a").cast(@pl.DataType::Float64))
  assert_eq(f.dtype(), @pl.DataType::Float64)
  assert_eq(f.to_list(), [@pl.AnyValue::Float64(1.0), Null, Float64(3.0)])
  // strict (the default) fails on a value that does not convert
  expect_error(
    raises(() => df.select([@pl.col("s").cast(@pl.DataType::Int64)])),
    "InvalidOperation",
    "conversion from `str` to `i64` failed in column 's' for 3 out of 3 values: [\"x\", \"y\", \"z\"]",
  )
  // lenient turns it into null
  let n = expr_col(df, @pl.col("s").cast(@pl.DataType::Int64, strict=false))
  assert_eq(n.to_list(), [@pl.AnyValue::Null, Null, Null])
  assert_eq(n.dtype(), @pl.DataType::Int64)
  // a cast of a literal
  assert_eq(
    expr_col(df, @pl.lit_int(1L).cast(@pl.DataType::Float64)).to_list(),
    [@pl.AnyValue::Float64(1.0)],
  )
}

///|
test "to_string follows polars' str(expr)" {
  assert_eq(@pl.col("a").to_string(), "col(\"a\")")
  assert_eq(
    (@pl.col("a") + @pl.lit_int(1L)).to_string(),
    "[(col(\"a\")) + (dyn int: 1)]",
  )
  assert_eq(
    (@pl.lit_int(1L) - @pl.col("a")).to_string(),
    "[(dyn int: 1) - (col(\"a\"))]",
  )
  assert_eq(
    (@pl.col("a") * @pl.lit_float(1.5)).to_string(),
    "[(col(\"a\")) * (dyn float: 1.5)]",
  )
  assert_eq(
    (@pl.col("a") / @pl.col("b")).to_string(),
    "[(col(\"a\")) / (col(\"b\"))]",
  )
  assert_eq(
    (@pl.col("a") % @pl.col("b")).to_string(),
    "[(col(\"a\")) % (col(\"b\"))]",
  )
  assert_eq(
    @pl.col("a").floor_div(@pl.col("b")).to_string(),
    "[(col(\"a\")) // (col(\"b\"))]",
  )
  assert_eq(
    @pl.col("a").eq(@pl.col("b")).to_string(),
    "[(col(\"a\")) == (col(\"b\"))]",
  )
  assert_eq(
    @pl.col("a").neq(@pl.col("b")).to_string(),
    "[(col(\"a\")) != (col(\"b\"))]",
  )
  assert_eq(
    @pl.col("a").ge(@pl.col("b")).to_string(),
    "[(col(\"a\")) >= (col(\"b\"))]",
  )
  assert_eq(
    (@pl.col("a") & @pl.col("b")).to_string(),
    "[(col(\"a\")) & (col(\"b\"))]",
  )
  assert_eq(
    (@pl.col("a") | @pl.col("b")).to_string(),
    "[(col(\"a\")) | (col(\"b\"))]",
  )
  assert_eq((-@pl.col("a")).to_string(), "col(\"a\").negate()")
  assert_eq(@pl.col("a").not_().to_string(), "col(\"a\").not()")
  assert_eq(@pl.col("a").alias("z").to_string(), "col(\"a\").alias(\"z\")")
  assert_eq(
    @pl.col("a").cast(@pl.DataType::Float64).to_string(),
    "col(\"a\").strict_cast(Float64)",
  )
  assert_eq(
    @pl.col("a").cast(@pl.DataType::Int32, strict=false).to_string(),
    "col(\"a\").cast(Int32)",
  )
  assert_eq(@pl.col("a").is_null().to_string(), "col(\"a\").is_null()")
  assert_eq(@pl.col("a").is_not_null().to_string(), "col(\"a\").is_not_null()")
  assert_eq(
    @pl.cols(["a", "b"]).to_string(),
    "cs.by_name('a', 'b', require_all=true)",
  )
  assert_eq(@pl.all().to_string(), "cs.all()")
  assert_eq(@pl.lit_str("x").to_string(), "\"x\"")
  assert_eq(@pl.lit_bool(true).to_string(), "true")
  assert_eq(@pl.lit(@pl.AnyValue::Null).to_string(), "null")
  assert_eq(@pl.lit(@pl.AnyValue::Int32(-5)).to_string(), "-5")
  assert_eq(@pl.lit(@pl.AnyValue::Float64(1.0)).to_string(), "1.0")
  assert_eq(@pl.lit_float(1.0).to_string(), "dyn float: 1")
  assert_eq(@pl.lit_float(0.1).to_string(), "dyn float: 0.1")
  assert_eq(
    @pl.lit_float(1.0e20).to_string(),
    "dyn float: 100000000000000000000",
  )
  assert_eq(@pl.lit_float(0.0 / 0.0).to_string(), "dyn float: NaN")
  assert_eq(@pl.lit_float(-0.0).to_string(), "dyn float: -0")
  assert_eq(@pl.lit_int(-1L).to_string(), "dyn int: -1")
  // `Show` prints the same
  assert_eq("\{@pl.col("a")}", "col(\"a\")")
}

///|
test "cols and all" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2]),
    @pl.Series::int64("b", [3L, 4L]),
    @pl.Series::float64("c", [0.5, 1.5]),
  ])
  let r = df.select([@pl.cols(["a", "b"]) + @pl.lit_int(1L)])
  assert_eq(r.columns(), ["a", "b"])
  assert_eq(r.dtypes(), [@pl.DataType::Int32, @pl.DataType::Int64])
  let all = df.select([@pl.all() * @pl.lit_int(2L)])
  assert_eq(all.columns(), ["a", "b", "c"])
  assert_eq(all.get_columns()[2].to_list(), [
    @pl.AnyValue::Float64(1.0),
    Float64(3.0),
  ])
  // an unknown column
  expect_error(
    raises(() => df.select([@pl.cols(["a", "zz"])])),
    "ColumnNotFound",
    "\"zz\" not found",
  )
  // two selectors of different width cannot be combined
  expect_error(
    raises(() => df.select([@pl.cols(["a", "b"]) + @pl.cols(["a", "b", "c"])])),
    "InvalidOperation",
    "cannot combine selectors that produce a different number of columns (3 != 2)",
  )
  // an alias on a selector gives the same name to all columns
  expect_error_kind(
    raises(() => df.select([@pl.all().alias("x")])),
    "DuplicateColumn",
  )
  // no columns, no frame
  assert_eq(@pl.DataFrame::empty().select([@pl.all()]).shape(), (0, 0))
  assert_eq(df.select([@pl.cols([])]).shape(), (0, 0))
}
