///|
fn select_df() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int32_nullable("a", [Some(1), None, Some(3)]),
    @pl.Series::int64("b", [10L, 20L, 30L]),
    @pl.Series::str("s", ["x", "y", "z"]),
  ])
}

///|
fn select_empty_rows() -> @pl.DataFrame raise {
  @pl.DataFrame::new([@pl.Series::int32("a", []), @pl.Series::str("s", [])])
}

///|
test "select picks, computes and reorders" {
  let df = select_df()
  let out = df.select([@pl.col("s"), @pl.col("a") + @pl.lit_int(1L)])
  assert_eq(out.columns(), ["s", "a"])
  assert_eq(out.shape(), (3, 2))
  assert_eq(out.get_columns()[1].to_list(), [
    @pl.AnyValue::Int32(2),
    Null,
    Int32(4),
  ])
  assert_eq(df.select([]).shape(), (0, 0))
}

///|
test "select broadcasts a literal to the table height" {
  let df = select_df()
  let out = df.select([@pl.col("a"), @pl.lit_int(7L).alias("k")])
  assert_eq(out.shape(), (3, 2))
  assert_eq(out.get_columns()[1].to_list(), [
    @pl.AnyValue::Int64(7L),
    Int64(7L),
    Int64(7L),
  ])
  let first = df.select([@pl.lit_str("x"), @pl.col("b")])
  assert_eq(first.columns(), ["literal", "b"])
  assert_eq(first.get_columns()[0].to_list(), [
    @pl.AnyValue::String("x"),
    String("x"),
    String("x"),
  ])
}

///|
test "select of literals only gives one row" {
  let df = select_df()
  let out = df.select([@pl.lit_int(1L), @pl.lit_str("x").alias("t")])
  assert_eq(out.shape(), (1, 2))
  // also on a frame without columns and on one without rows
  assert_eq(@pl.DataFrame::empty().select([@pl.lit_int(1L)]).shape(), (1, 1))
  assert_eq(select_empty_rows().select([@pl.lit_int(1L)]).shape(), (1, 1))
}

///|
test "select on a frame without rows" {
  let df = select_empty_rows()
  // a literal next to a column is broadcast to zero rows
  let out = df.select([@pl.col("a"), @pl.lit_int(1L)])
  assert_eq(out.shape(), (0, 2))
  assert_eq(out.dtypes(), [@pl.DataType::Int32, @pl.DataType::Int64])
  let e = df.select([@pl.col("a") + @pl.lit_int(1L)])
  assert_eq(e.shape(), (0, 1))
  assert_eq(e.dtypes(), [@pl.DataType::Int32])
}

///|
test "select with a frame without columns" {
  let df = @pl.DataFrame::empty()
  assert_eq(df.select([@pl.all(), @pl.lit_int(1L)]).shape(), (1, 1))
  assert_eq(df.select([@pl.all()]).shape(), (0, 0))
  expect_error(
    raises(() => df.select([@pl.col("a")])),
    "ColumnNotFound",
    "unable to find column \"a\"; valid columns: []",
  )
}

///|
test "select rejects duplicate output names" {
  let df = select_df()
  let msg = "projections contained duplicate output name 'a'. It's possible that multiple expressions are returning the same default column name. If this is the case, try renaming the columns with `.alias(\"new_name\")` to avoid duplicate column names."
  expect_error(
    raises(() => df.select([@pl.col("a"), @pl.col("a") + @pl.lit_int(1L)])),
    "DuplicateColumn",
    msg,
  )
  // a column renamed to an existing name
  expect_error(
    raises(() => df.select([@pl.col("a"), @pl.col("b").alias("a")])),
    "DuplicateColumn",
    msg,
  )
  // two literals
  assert_true(
    raises(() => df.select([@pl.lit_int(1L), @pl.lit_int(2L)]))
    is Some(@pl.DuplicateColumn(_)),
  )
  // the same name twice is fine once one of them is renamed
  let ok = df.select([@pl.col("a"), @pl.col("a").alias("a2")])
  assert_eq(ok.columns(), ["a", "a2"])
}

///|
test "select errors" {
  let df = select_df()
  assert_true(
    raises(() => df.select([@pl.col("nope")])) is Some(@pl.ColumnNotFound(_)),
  )
  assert_true(
    raises(() => df.select([@pl.col("s") + @pl.lit_int(1L)]))
    is Some(@pl.InvalidOperation(_)),
  )
  // the frame is not modified
  assert_eq(df.shape(), (3, 3))
}

///|
test "with_columns replaces in place and appends" {
  let df = select_df()
  let out = df.with_columns([
    (@pl.col("b") * @pl.lit_int(2L)).alias("a"),
    @pl.lit_str("k").alias("new"),
  ])
  assert_eq(out.columns(), ["a", "b", "s", "new"])
  assert_eq(out.dtypes(), [
    @pl.DataType::Int64,
    @pl.DataType::Int64,
    @pl.DataType::String,
    @pl.DataType::String,
  ])
  assert_eq(out.get_columns()[0].to_list(), [
    @pl.AnyValue::Int64(20L),
    Int64(40L),
    Int64(60L),
  ])
  assert_eq(out.get_columns()[3].to_list(), [
    @pl.AnyValue::String("k"),
    String("k"),
    String("k"),
  ])
  // a name that exists is replaced where it is, whatever the order
  let swap = df.with_columns([@pl.col("a").alias("b"), @pl.col("b").alias("a")])
  assert_eq(swap.columns(), ["a", "b", "s"])
  assert_eq(swap.get_columns()[0].to_list(), [
    @pl.AnyValue::Int64(10L),
    Int64(20L),
    Int64(30L),
  ])
  assert_eq(swap.get_columns()[1].to_list(), [
    @pl.AnyValue::Int32(1),
    Null,
    Int32(3),
  ])
  // the source frame is unchanged
  assert_eq(df.columns(), ["a", "b", "s"])
}

///|
test "with_columns with a bare column or no expression changes nothing" {
  let df = select_df()
  assert_true(df.with_columns([]).equals(df))
  assert_true(df.with_columns([@pl.col("a")]).equals(df))
  assert_true(df.with_columns([@pl.all()]).equals(df))
}

///|
test "with_columns broadcasts a literal, also to zero rows" {
  let df = select_df()
  let out = df.with_columns([@pl.lit_int(1L)])
  assert_eq(out.shape(), (3, 4))
  assert_eq(out.columns(), ["a", "b", "s", "literal"])
  let e = select_empty_rows().with_columns([@pl.lit_int(1L)])
  assert_eq(e.shape(), (0, 3))
  // on a frame without columns the height is 0
  let z = @pl.DataFrame::empty().with_columns([@pl.lit_int(1L)])
  assert_eq(z.shape(), (0, 1))
  let z2 = @pl.DataFrame::empty().with_columns([
    @pl.lit_int(1L),
    @pl.lit_str("x").alias("t"),
  ])
  assert_eq(z2.shape(), (0, 2))
}

///|
test "with_columns errors" {
  let df = select_df()
  assert_true(
    raises(() => df.with_columns([@pl.col("zz")]))
    is Some(@pl.ColumnNotFound(_)),
  )
  expect_error(
    raises(() => {
      df.with_columns([@pl.col("a").alias("q"), @pl.col("b").alias("q")])
    }),
    "DuplicateColumn",
    "the name 'q' passed to `LazyFrame.with_columns` is duplicate",
  )
  assert_true(
    raises(() => df.with_columns([@pl.col("s") + @pl.col("s")]))
    is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "with_columns expressions all see the original frame" {
  let df = select_df()
  let out = df.with_columns([
    (@pl.col("a") + @pl.lit_int(1L)).alias("a"),
    (@pl.col("a") + @pl.lit_int(2L)).alias("a2"),
  ])
  assert_eq(out.get_columns()[0].to_list(), [
    @pl.AnyValue::Int32(2),
    Null,
    Int32(4),
  ])
  assert_eq(out.get_columns()[3].to_list(), [
    @pl.AnyValue::Int32(3),
    Null,
    Int32(5),
  ])
}

///|
test "type resolution errors come before missing columns and duplicate names" {
  // polars 2.1.0 raises `date * i64`, `~date` and `f64 & date` while it
  // resolves the output type of an expression, before the output names of
  // the expressions are checked
  let t = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2]),
    @pl.Series::date("d", [1, 2]),
    @pl.Series::int64("b", [1L, 2L]),
    @pl.Series::float64("f", [1.5, 2.5]),
    @pl.Series::str("s", ["x", "y"]),
  ])
  let bad : Array[(String, @pl.Expr)] = [
    ("date * i64", (@pl.col("d") * @pl.col("b")).alias("x")),
    ("~date", @pl.col("d").not_().alias("x")),
    ("f64 & date", (@pl.col("f") & @pl.col("d")).alias("x")),
    ("~f64", @pl.col("f").not_().alias("x")),
    ("~str", @pl.col("s").not_().alias("x")),
  ]
  for pair in bad {
    let (name, p) = pair
    let is_plan = (r : () -> @pl.DataFrame raise @pl.PolarsError) => {
      match raises(r) {
        Some(@pl.InvalidOperation(_)) => true
        _ => false
      }
    }
    // a missing column after it
    assert_true(
      is_plan(() => t.select([p, @pl.col("zz")])),
      msg=name + " select zz",
    )
    // a duplicate output name after it
    assert_true(
      is_plan(() => t.select([@pl.col("a"), p, @pl.col("a")])),
      msg=name + " select dup",
    )
    assert_true(
      is_plan(() => t.select([@pl.col("a").alias("x"), p])),
      msg=name + " select alias dup",
    )
    assert_true(
      is_plan(() => t.with_columns([@pl.col("a"), p, @pl.col("a")])),
      msg=name + " with_columns dup",
    )
    assert_true(
      is_plan(() => t.with_columns([@pl.col("a").alias("x"), p])),
      msg=name + " with_columns alias dup",
    )
    // unchanged orders: an earlier missing column or duplicate wins
    match raises(() => t.select([@pl.col("zz"), p])) {
      Some(@pl.ColumnNotFound(_)) => ()
      _ => fail(name + ": expected ColumnNotFound first")
    }
    match raises(() => t.select([@pl.col("a"), @pl.col("a"), p])) {
      Some(@pl.DuplicateColumn(_)) => ()
      _ => fail(name + ": expected DuplicateColumn first")
    }
    match raises(() => t.with_columns([p, @pl.col("zz")])) {
      Some(@pl.ColumnNotFound(_)) => ()
      _ => fail(name + ": with_columns takes every plain column first")
    }
  }
  // errors that polars raises later keep their order: `str + 1` after a
  // missing column
  match raises(() => t.select([@pl.col("s") + @pl.lit_int(1), @pl.col("zz")])) {
    Some(@pl.ColumnNotFound(_)) => ()
    _ => fail("expected ColumnNotFound before a late type error")
  }
}

///|
test "not on an integer is no plan time error here: names are checked first" {
  // polars accepts `~int` (bitwise not); this library rejects it when the
  // kernel runs (arith.md), so a duplicate or missing column still comes first
  let t = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2]),
    @pl.Series::int64("b", [1L, 2L]),
  ])
  for n in ["a", "b"] {
    let p = @pl.col(n).not_().alias("x")
    match raises(() => t.select([@pl.col("a"), @pl.col("a"), p])) {
      Some(@pl.DuplicateColumn(_)) => ()
      _ => fail("~" + n + ": expected DuplicateColumn first")
    }
    match raises(() => t.select([p, @pl.col("zz")])) {
      Some(@pl.ColumnNotFound(_)) => ()
      _ => fail("~" + n + ": expected ColumnNotFound first")
    }
    match raises(() => t.select([p])) {
      Some(@pl.InvalidOperation(_)) => ()
      _ => fail("~" + n + ": expected InvalidOperation alone")
    }
  }
}

///|
test "the outputs of one expression are checked against each other before their types" {
  // polars 2.1.0: `a.is_null() == ~cols("s", "d")` expands to two outputs
  // both named `a`; the duplicate is reported, not `~str`
  let t = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2]),
    @pl.Series::str("s", ["x", "y"]),
    @pl.Series::date("d", [1, 2]),
  ])
  let e = @pl.col("a").is_null().eq(@pl.cols(["s", "d"]).not_())
  match raises(() => t.select([e])) {
    Some(@pl.DuplicateColumn(_)) => ()
    _ => fail("select: expected DuplicateColumn")
  }
  match raises(() => t.with_columns([e])) {
    Some(@pl.DuplicateColumn(_)) => ()
    _ => fail("with_columns: expected DuplicateColumn")
  }
  // one output only: the type error is raised
  match
    raises(() => t.select([@pl.col("a").is_null().eq(@pl.col("s").not_())])) {
    Some(@pl.InvalidOperation(_)) => ()
    _ => fail("expected InvalidOperation")
  }
}
