///|
/// How many of `exprs` `plan_check` evaluates on a 0-row frame (`plan_check_frame`
/// is `Some`; `plan_check` runs exactly when it is).
fn leftovers_runs(df : DataFrame, exprs : Array[Expr]) -> Int32 {
  let mut n = 0
  for e in exprs {
    if plan_check_frame(df, e.node) is Some(_) {
      n += 1
    }
  }
  n
}

///|
fn leftovers_df() -> DataFrame raise PolarsError {
  DataFrame::new([
    Series::int32("a", [1, 2, 3]),
    Series::int32("b", [4, 5, 6]),
    Series::bool("p", [true, false, true]),
    Series::bool("q", [false, false, true]),
    Series::date("d", [1, 2, 3]),
    Series::str("s", ["x", "y", "z"]),
  ])
}

///|
test "plan_check does not run the 0-row evaluation when no type error can occur" {
  let df = leftovers_df()
  // columns, literals, comparisons, aggregates, casts, strings: nothing to check
  assert_eq(leftovers_runs(df, [col("a"), col("s")]), 0)
  assert_eq(leftovers_runs(df, [col("a").gt(col("b")), col("a").sum()]), 0)
  assert_eq(leftovers_runs(df, [col("a").is_in(Series::int32("v", [1]))]), 0)
  assert_eq(leftovers_runs(df, [col("s").cast(String), lit_int(1L)]), 0)
  assert_eq(leftovers_runs(df, [col("a").fill_null(lit_int(0L))]), 0)
  // arithmetic on numbers or strings has no plan time error either
  assert_eq(
    leftovers_runs(df, [col("a") + col("b"), col("a") * lit_int(2L)]),
    0,
  )
  assert_eq(leftovers_runs(df, [-col("a"), col("a").shift(n=1)]), 0)
}

///|
test "plan_check runs the 0-row evaluation for logic, not and temporal arithmetic" {
  let df = leftovers_df()
  assert_eq(leftovers_runs(df, [col("p") & col("q")]), 1)
  assert_eq(leftovers_runs(df, [col("p") | col("q")]), 1)
  assert_eq(leftovers_runs(df, [col("p").not_()]), 1)
  // one run per output expression
  assert_eq(leftovers_runs(df, [col("p") & col("q"), col("q").not_()]), 2)
  // an operator with a Date column, a Date literal, a cast to a temporal type
  assert_eq(leftovers_runs(df, [col("d") + lit_int(1L)]), 1)
  assert_eq(leftovers_runs(df, [col("a") + lit(AnyValue::Date(1))]), 1)
  assert_eq(leftovers_runs(df, [col("a").cast(Date) * lit_int(2L)]), 1)
}

///|
test "plan_frame_of holds only the columns the expression reads, with no row" {
  let df = leftovers_df()
  let node = Binary(Add, Column("a"), Binary(Mul, Column("d"), Column("a")))
  let df0 = plan_frame_of(df, plan_scan(df, node).cols)
  assert_eq(df0.height(), 0)
  assert_eq(df0.columns(), ["a", "d"])
  assert_eq(df0.column("d").dtype(), DataType::Date)
  // a name the frame lacks is left out (the real evaluation reports it)
  let df1 = plan_frame_of(df, plan_scan(df, Column("zz")).cols)
  assert_eq(df1.width(), 0)
  // a literal reads no column
  assert_eq(
    plan_frame_of(
      df,
      plan_scan(df, Literal(AnyValue::Boolean(true), Strong)).cols,
    ).width(),
    0,
  )
}

///|
test "plan_check_node swaps the value set of is_in for an empty series of the same type" {
  let big = Series::int64("v", [1L, 2L, 3L])
  let node = Binary(
    Add,
    IsIn(Column("a"), big),
    Literal(AnyValue::Int64(1L), WeakInt),
  )
  match plan_check_node(node) {
    Binary(Add, IsIn(Column("a"), v), Literal(_, _)) => {
      assert_eq(v.len(), 0)
      assert_eq(v.dtype(), DataType::Int64)
      assert_eq(v.name(), "v")
    }
    _ => fail("unexpected node")
  }
  // the original is untouched
  match node {
    Binary(_, IsIn(_, v), _) => assert_eq(v.len(), 3)
    _ => fail("unexpected")
  }
  // an is_in under a logic operator is found too
  match plan_check_node(Not(IsIn(Column("a"), big))) {
    Not(IsIn(_, v)) => assert_eq(v.len(), 0)
    _ => fail("unexpected node")
  }
}

///|
test "a plan time error is still found after the narrowing" {
  let df = leftovers_df()
  // `bool & i32` and `date * i64` errors come before a missing column
  assert_true(
    wb_err(() => df.select([col("p") & col("a"), col("zz")]))
    is Some(ComputeError(_)),
  )
  assert_true(
    wb_err(() => df.select([col("d") * lit_int(2L), col("zz")]))
    is Some(InvalidOperation(_)),
  )
  assert_true(
    wb_err(() => df.select([col("s").not_(), col("zz")]))
    is Some(InvalidOperation(_)),
  )
  // an is_in inside the failing expression does not hide it
  let v = Series::int32("v", [1, 2, 3])
  assert_true(
    wb_err(() => df.select([(col("d") * lit_int(2L)).is_in(v), col("zz")]))
    is Some(InvalidOperation(_)),
  )
}

///|
test "plan_check_frame: when the 0-row evaluation runs, and on which columns" {
  let df = DataFrame::new([
    Series::int32("a", [1, 2, 3]),
    Series::datetime("t", [1L, 2L, 3L]),
    Series::date("d", [1, 2, 3]),
    Series::str("s", ["x", "y", "z"]),
    Series::bool("p", [true, false, true]),
  ])
  let lit_t = Literal(AnyValue::Datetime(1L), Strong)
  // every temporal source with an arithmetic operator runs
  for
    node in [
      Binary(Add, Column("d"), Column("a")),
      Binary(Add, Column("t"), Column("a")),
      Binary(Add, Column("a"), lit_t),
      Binary(Add, Cast(Column("a"), Datetime, true), Column("a")),
      Binary(
        Add,
        Seq(Shift(1, AnyValue::Datetime(1L)), Column("a")),
        Column("a"),
      ),
      Binary(Add, Seq(Shift(1, AnyValue::Date(1)), Column("a")), Column("a")),
      Binary(Add, Str(ToDate(false), Column("s")), Column("a")),
      Binary(Add, Str(ToDatetime(false), Column("s")), Column("a")),
    ] {
    assert_true(plan_check_frame(df, node) is Some(_))
  }
  // every arithmetic operator counts
  for
    op in [
      BinaryOp::Add,
      BinaryOp::Sub,
      BinaryOp::Mul,
      BinaryOp::Div,
      BinaryOp::FloorDiv,
      BinaryOp::Rem,
    ] {
    assert_true(
      plan_check_frame(df, Binary(op, Column("d"), Column("a"))) is Some(_),
    )
  }
  // arithmetic without a temporal source, a temporal source without arithmetic
  assert_true(
    plan_check_frame(df, Binary(Add, Column("a"), Column("a"))) is None,
  )
  assert_true(plan_check_frame(df, Column("d")) is None)
  assert_true(plan_check_frame(df, Str(ToDate(false), Column("s"))) is None)
  // the frame holds the columns read, no row
  match plan_check_frame(df, Binary(Rem, Column("d"), Column("a"))) {
    Some(f) => {
      assert_eq(f.height(), 0)
      assert_eq(f.columns(), ["d", "a"])
    }
    None => fail("expected a frame")
  }
}

///|
test "plan_check_frame keeps the cost of a wide frame and a large set out of the check" {
  // 2000 columns, an expression that reads two of them: the frame has two
  let cols : Array[Series] = []
  for i in 0..<2000 {
    cols.push(Series::int32("c\{i}", [1, 2, 3]))
  }
  cols.push(Series::date("d", [1, 2, 3]))
  let df = DataFrame::new(cols)
  let node = Binary(Add, Column("d"), Column("c7"))
  match plan_check_frame(df, node) {
    Some(f) => {
      assert_eq(f.width(), 2)
      assert_eq(f.height(), 0)
    }
    None => fail("expected a frame")
  }
  // the set of an is_in is emptied before the check runs
  let big = Series::int64("v", [1L, 2L, 3L, 4L])
  match plan_check_node(Binary(Add, Column("d"), IsIn(Column("c7"), big))) {
    Binary(_, _, IsIn(_, v)) => assert_eq(v.len(), 0)
    _ => fail("unexpected node")
  }
}
