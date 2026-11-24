///|
fn when_df() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int32_nullable("a", [Some(1), None, Some(3)]),
    @pl.Series::int64("b", [10L, 20L, 30L]),
    @pl.Series::bool_nullable("p", [Some(true), None, Some(false)]),
    @pl.Series::str("s", ["x", "y", "z"]),
    @pl.Series::null("n", 3),
  ])
}

///|
test "when then otherwise" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32_nullable("a", [Some(1), None, Some(3)]),
  ])
  let out = df.select([
    @pl.when(@pl.col("a").gt(@pl.lit_int(1L)))
    .then(@pl.lit_str("big"))
    .otherwise(@pl.lit_str("small")),
  ])
  // the name is that of the first `then`; the null condition goes to otherwise
  assert_eq(out.columns(), ["literal"])
  assert_eq(out.column("literal").to_str_array(), [
    Some("small"),
    Some("small"),
    Some("big"),
  ])
}

///|
test "when: types, names and nulls" {
  let df = when_df()
  let p = @pl.col("p")
  // Int32 and Int64 give Int64; the name is the first then's
  let r = expr_col(df, @pl.when(p).then(@pl.col("a")).otherwise(@pl.col("b")))
  assert_eq(r.dtype(), @pl.DataType::Int64)
  assert_eq(r.name(), "a")
  assert_eq(r.to_int64_array(), [Some(1L), Some(20L), Some(30L)])
  // a weak literal adapts to the column
  let w = expr_col(
    df,
    @pl.when(p).then(@pl.col("a")).otherwise(@pl.lit_int(0L)),
  )
  assert_eq(w.dtype(), @pl.DataType::Int32)
  assert_eq(w.to_int32_array(), [Some(1), Some(0), Some(0)])
  // a null in the chosen branch stays null
  let nb = expr_col(
    df,
    @pl.when(@pl.lit_bool(true)).then(@pl.col("a")).otherwise(@pl.lit_int(0L)),
  )
  assert_eq(nb.to_int32_array(), [Some(1), None, Some(3)])
  // a number with text is text
  let t = expr_col(df, @pl.when(p).then(@pl.col("s")).otherwise(@pl.col("a")))
  assert_eq(t.to_str_array(), [Some("x"), None, Some("3")])
  // the first then names the result, whatever the otherwise is called
  let al = df.select([
    @pl.when(p).then(@pl.col("a").alias("q")).otherwise(@pl.col("b").alias("r")),
  ])
  assert_eq(al.columns(), ["q"])
  let z = df.select([
    @pl.when(p).then(@pl.col("a")).otherwise(@pl.col("b")).alias("z"),
  ])
  assert_eq(z.columns(), ["z"])
  // literals alone: weak ints are Int64 here (spec 5.5), floats win over ints
  assert_eq(
    expr_col(df, @pl.when(p).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L))).dtype(),
    @pl.DataType::Int64,
  )
  assert_eq(
    expr_col(
      df,
      @pl.when(p).then(@pl.lit_int(1L)).otherwise(@pl.lit_float(2.5)),
    ).dtype(),
    @pl.DataType::Float64,
  )
}

///|
test "when: Null columns" {
  let df = when_df()
  let p = @pl.col("p")
  // a Null branch takes the type of the other
  let r = expr_col(df, @pl.when(p).then(@pl.col("n")).otherwise(@pl.col("a")))
  assert_eq(r.dtype(), @pl.DataType::Int32)
  assert_eq(r.to_int32_array(), [None, None, Some(3)])
  // both Null: a Null column
  let both = expr_col(
    df,
    @pl.when(p).then(@pl.col("n")).otherwise(@pl.col("n")),
  )
  assert_eq(both.dtype(), @pl.DataType::Null)
  assert_eq(both.len(), 3)
  // a Null column as the condition is an error
  expect_error(
    raises(() => {
      df.select([
        @pl.when(@pl.col("n")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
      ])
    }),
    "SchemaMismatch",
    "invalid series dtype: expected `Boolean`, got `null` for series with name `n`",
  )
}

///|
test "when: chains are nested ternaries" {
  let df = when_df()
  let a = @pl.col("a")
  let chain = @pl.when(@pl.col("p"))
    .then(@pl.lit_str("p"))
    .when(a.is_null())
    .then(@pl.lit_str("null"))
    .when(a.gt(@pl.lit_int(2L)))
    .then(@pl.lit_str("big"))
    .otherwise(@pl.lit_str("other"))
  // the first true condition decides; a null condition falls through
  assert_eq(expr_col(df, chain).to_str_array(), [
    Some("p"),
    Some("null"),
    Some("big"),
  ])
  // polars' text of a chain: nested in `otherwise`
  assert_eq(
    chain.to_string(),
    ".when(col(\"p\")).then(\"p\").otherwise(.when(col(\"a\").is_null()).then(\"null\").otherwise(.when([(col(\"a\")) > (dyn int: 2)]).then(\"big\").otherwise(\"other\")))",
  )
  // the same as writing the nesting out
  let nested = @pl.when(@pl.col("p"))
    .then(@pl.lit_str("p"))
    .otherwise(
      @pl.when(a.is_null())
      .then(@pl.lit_str("null"))
      .otherwise(
        @pl.when(a.gt(@pl.lit_int(2L)))
        .then(@pl.lit_str("big"))
        .otherwise(@pl.lit_str("other")),
      ),
    )
  assert_eq(nested.to_string(), chain.to_string())
  // the first then names the result; types promote across the chain
  let mixed = @pl.when(@pl.col("p"))
    .then(@pl.col("a"))
    .when(a.is_null())
    .then(@pl.col("b"))
    .otherwise(@pl.lit_float(0.5))
  let r = expr_col(df, mixed)
  assert_eq(r.name(), "a")
  assert_eq(r.dtype(), @pl.DataType::Float64)
  assert_eq(r.to_float64_array(), [Some(1.0), Some(20.0), Some(0.5)])
}

///|
test "when: Then and When are values" {
  let df = when_df()
  let base = @pl.when(@pl.col("p")).then(@pl.lit_int(1L))
  let x = base
    .when(@pl.col("a").is_null())
    .then(@pl.lit_int(2L))
    .otherwise(@pl.lit_int(3L))
  let y = base.otherwise(@pl.lit_int(9L))
  // building x did not change base
  assert_eq(expr_col(df, y).to_int64_array(), [Some(1L), Some(9L), Some(9L)])
  assert_eq(expr_col(df, x).to_int64_array(), [Some(1L), Some(2L), Some(3L)])
  let w = @pl.when(@pl.col("p"))
  let a = w.then(@pl.lit_int(1L)).otherwise(@pl.lit_int(0L))
  let b = w.then(@pl.lit_int(5L)).otherwise(@pl.lit_int(0L))
  assert_eq(expr_col(df, a).to_int64_array(), [Some(1L), Some(0L), Some(0L)])
  assert_eq(expr_col(df, b).to_int64_array(), [Some(5L), Some(0L), Some(0L)])
}

///|
test "when: aggregates, scalars and empty frames" {
  let df = when_df()
  // a scalar condition picks a whole branch
  let c = expr_col(
    df,
    @pl.when(@pl.col("b").sum().gt(@pl.lit_int(50L)))
    .then(@pl.col("b"))
    .otherwise(@pl.lit_int(0L)),
  )
  assert_eq(c.to_int64_array(), [Some(10L), Some(20L), Some(30L)])
  // a scalar branch is repeated
  let s = expr_col(
    df,
    @pl.when(@pl.col("p")).then(@pl.col("b").sum()).otherwise(@pl.col("b")),
  )
  assert_eq(s.to_int64_array(), [Some(60L), Some(20L), Some(30L)])
  // everything scalar: one row
  let one = df.select([
    @pl.when(@pl.col("b").sum().gt(@pl.lit_int(1L)))
    .then(@pl.col("b").min())
    .otherwise(@pl.col("b").max()),
  ])
  assert_eq(one.shape(), (1, 1))
  assert_eq(one.get_columns()[0].to_list(), [@pl.AnyValue::Int64(10L)])
  // an empty frame: no rows; a scalar branch has none either
  let empty = @pl.DataFrame::new([
    @pl.Series::bool("p", []),
    @pl.Series::int32("a", []),
    @pl.Series::int64("b", []),
  ])
  let e = empty.select([
    @pl.when(@pl.col("p")).then(@pl.col("a")).otherwise(@pl.col("b")),
  ])
  assert_eq(e.shape(), (0, 1))
  assert_eq(e.dtypes(), [@pl.DataType::Int64])
  let e2 = empty.select([
    @pl.when(@pl.col("p")).then(@pl.col("a").sum()).otherwise(@pl.col("b")),
  ])
  assert_eq(e2.shape(), (0, 1))
  let e3 = empty.select([
    @pl.when(@pl.col("p").first())
    .then(@pl.col("a").sum())
    .otherwise(@pl.col("b").sum()),
  ])
  assert_eq(e3.shape(), (1, 1))
  // a frame without columns
  let z = @pl.DataFrame::empty().select([
    @pl.when(@pl.lit_bool(true))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(2L)),
  ])
  assert_eq(z.shape(), (1, 1))
  // with_columns repeats a scalar result
  let wc = df.with_columns([
    @pl.when(@pl.col("b").sum().gt(@pl.lit_int(1L)))
    .then(@pl.lit_str("y"))
    .otherwise(@pl.lit_str("n"))
    .alias("k"),
  ])
  assert_eq(wc.column("k").to_str_array(), [Some("y"), Some("y"), Some("y")])
}

///|
test "when: errors and their order" {
  let df = when_df()
  let p = @pl.col("p")
  expect_error(
    raises(() => {
      df.select([
        @pl.when(@pl.col("a")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
      ])
    }),
    "SchemaMismatch",
    "invalid series dtype: expected `Boolean`, got `i32` for series with name `a`",
  )
  // no common type: reported before the condition's type
  let d = @pl.DataFrame::new([
    @pl.Series::bool("p", [true]),
    @pl.Series::date("d", [1]),
    @pl.Series::int32("i", [1]),
  ])
  expect_error(
    raises(() => {
      d.select([
        @pl.when(@pl.col("i")).then(@pl.col("p")).otherwise(@pl.col("d")),
      ])
    }),
    "SchemaMismatch",
    "failed to determine supertype of bool and date",
  )
  // also when it is in a later branch of a chain
  expect_error(
    raises(() => {
      d.select([
        @pl.when(@pl.col("i"))
        .then(@pl.col("p"))
        .when(@pl.col("p"))
        .then(@pl.col("d"))
        .otherwise(@pl.col("p")),
      ])
    }),
    "SchemaMismatch",
    "failed to determine supertype of date and bool",
  )
  // a missing column comes first, left to right
  expect_error(
    raises(() => {
      df.select([
        @pl.when(@pl.col("z1")).then(@pl.col("z2")).otherwise(@pl.col("z3")),
      ])
    }),
    "ColumnNotFound",
    "unable to find column \"z1\"; valid columns: [\"a\", \"b\", \"p\", \"s\", \"n\"]",
  )
  // the errors of the evaluation: condition, then, otherwise
  let bad = x => @pl.col("s").eq(@pl.col(x))
  expect_error(
    raises(() => df.select([@pl.when(bad("a")).then(bad("b")).otherwise(p)])),
    "ComputeError",
    "cannot compare string with numeric type (i32)",
  )
  expect_error(
    raises(() => df.select([@pl.when(p).then(bad("b")).otherwise(bad("a"))])),
    "ComputeError",
    "cannot compare string with numeric type (i64)",
  )
}

///|
test "when: a chain checks the outer widths before the nested otherwise" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2]),
    @pl.Series::int32("h", [3, 4]),
    @pl.Series::int32("k", [5, 6]),
  ])
  let w = [
    @pl.cols([]),
    @pl.col("a"),
    @pl.cols(["a", "h"]),
    @pl.cols(["a", "h", "k"]),
  ]
  // widths (cond1, then1, cond2, then2, otherwise) = (0, 2, 0, 3, 1): the
  // pair (0, 2) of the first branch fails before the inner `when` (3 != 0)
  let chain = @pl.when(w[0].is_not_null())
    .then(w[2])
    .when(w[0].is_not_null())
    .then(w[3])
    .otherwise(w[1])
  expect_error(
    raises(() => df.select([chain])),
    "InvalidOperation",
    "cannot combine selectors that produce a different number of columns (2 != 0)",
  )
  expect_error(
    raises(() => df.with_columns([chain])),
    "InvalidOperation",
    "cannot combine selectors that produce a different number of columns (2 != 0)",
  )
  // when the outer pair fits, the inner chain is the next to fail:
  // (1, 2, 2, 3, 1): the inner (2, 3) gives (3 != 2)
  let inner = @pl.when(w[1].is_not_null())
    .then(w[2])
    .when(w[2].is_not_null())
    .then(w[3])
    .otherwise(w[1])
  expect_error(
    raises(() => df.select([inner])),
    "InvalidOperation",
    "cannot combine selectors that produce a different number of columns (3 != 2)",
  )
  // widths that agree
  let ok = @pl.when(w[2].is_not_null())
    .then(w[2])
    .when(w[1].is_not_null())
    .then(w[2])
    .otherwise(w[1])
  assert_eq(df.select([ok]).columns(), ["a", "h"])
}

///|
test "when: two supertype errors come in the order then, otherwise, condition" {
  let df = @pl.DataFrame::new([
    @pl.Series::bool("p", [true, false]),
    @pl.Series::date("d", [1, 2]),
    @pl.Series::datetime("dt", [1L, 2L]),
  ])
  let p = @pl.col("p")
  let on_date = @pl.when(p).then(p).otherwise(@pl.col("d"))
  let on_dt = @pl.when(p).then(p).otherwise(@pl.col("dt"))
  expect_error(
    raises(() => df.select([@pl.when(p).then(on_date).otherwise(on_dt)])),
    "SchemaMismatch",
    "failed to determine supertype of bool and date",
  )
  expect_error(
    raises(() => df.select([@pl.when(p).then(on_dt).otherwise(on_date)])),
    "SchemaMismatch",
    "failed to determine supertype of bool and datetime[μs]",
  )
  // the condition comes after both
  expect_error(
    raises(() => df.select([@pl.when(on_date).then(on_dt).otherwise(p)])),
    "SchemaMismatch",
    "failed to determine supertype of bool and datetime[μs]",
  )
  expect_error(
    raises(() => df.select([@pl.when(on_dt).then(p).otherwise(on_date)])),
    "SchemaMismatch",
    "failed to determine supertype of bool and date",
  )
}

///|
test "when: every branch is evaluated, also for a condition of length 1" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2, 3]),
    @pl.Series::date("d", [1, 2, 3]),
  ])
  let yes = @pl.col("a").sum().gt(@pl.lit_int(1L))
  let bad = @pl.col("d").sum()
  // polars skips the unselected branch here and returns `a`; this raises
  // (known difference, known-diffs/expr_agg.md)
  expect_error(
    raises(() => df.select([@pl.when(yes).then(@pl.col("a")).otherwise(bad)])),
    "InvalidOperation",
    "`sum` operation not supported for dtype `date`",
  )
  // the same with a selected failing branch, and with a condition of the
  // height of the frame
  expect_error_kind(
    raises(() => df.select([@pl.when(yes).then(bad).otherwise(@pl.col("a"))])),
    "InvalidOperation",
  )
  expect_error_kind(
    raises(() => {
      df.select([
        @pl.when(@pl.col("a").gt(@pl.lit_int(1L)))
        .then(@pl.col("a"))
        .otherwise(bad),
      ])
    }),
    "InvalidOperation",
  )
}

///|
// Checked against polars 2.1.0 (fw-scripts/mask_probe.py), column
// `a = [null, 1, 9]` and the condition `a < 5`, which is null, true, false.
test "when: a null condition takes the otherwise branch" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32_nullable("a", [None, Some(1), Some(9)]),
  ])
  let cond = @pl.col("a").lt(@pl.lit_int(5L))
  let r = expr_col(
    df,
    @pl.when(cond).then(@pl.lit_int(100L)).otherwise(@pl.lit_int(0L)),
  )
  assert_eq(r.to_int64_array(), [Some(0L), Some(100L), Some(0L)])
  // without `otherwise` the row is null
  let r2 = expr_col(
    df,
    @pl.when(cond)
    .then(@pl.lit_int(100L))
    .otherwise(@pl.lit(@pl.AnyValue::Null)),
  )
  assert_eq(r2.to_int32_array(), [None, Some(100), None])
  // a chain: the null condition falls through to the next one
  let r3 = expr_col(
    df,
    @pl.when(cond)
    .then(@pl.lit_int(1L))
    .when(@pl.col("a").gt(@pl.lit_int(5L)))
    .then(@pl.lit_int(2L))
    .otherwise(@pl.lit_int(3L)),
  )
  assert_eq(r3.to_int64_array(), [Some(3L), Some(1L), Some(2L)])
  // text branches
  let r4 = expr_col(
    df,
    @pl.when(cond).then(@pl.lit_str("y")).otherwise(@pl.lit_str("n")),
  )
  assert_eq(r4.to_str_array(), [Some("n"), Some("y"), Some("n")])
  // a null in the chosen branch stays null
  let df2 = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 9]),
    @pl.Series::int32_nullable("t", [None, Some(5)]),
  ])
  let r5 = expr_col(
    df2,
    @pl.when(@pl.col("a").lt(@pl.lit_int(5L)))
    .then(@pl.col("t"))
    .otherwise(@pl.lit_int(0L)),
  )
  assert_eq(r5.to_int32_array(), [None, Some(0)])
}
