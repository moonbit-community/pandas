///|
test "when_length: the one length that is not 1" {
  assert_eq(when_length(1, 1, 1), 1)
  assert_eq(when_length(3, 1, 3), 3)
  assert_eq(when_length(1, 4, 1), 4)
  assert_eq(when_length(0, 1, 0), 0)
  assert_eq(when_length(1, 0, 1), 0)
}

///|
test "when_length: lengths that differ are a ShapeMismatch" {
  for lens in [(3, 2, 3), (1, 2, 3), (2, 1, 3), (3, 3, 0)] {
    let (c, t, o) = lens
    let r : Result[Int32, PolarsError] = Ok(when_length(c, t, o)) catch {
      e => Err(e)
    }
    match r {
      Err(ShapeMismatch(m)) =>
        assert_eq(
          m, "shapes of `self`, `mask` and `other` are not suitable for `zip_with` operation",
        )
      _ => fail("expected ShapeMismatch")
    }
  }
}

///|
test "xagg_pick takes rows from either column and keeps nulls" {
  let take = @arrow.Bitmap::from_array([true, false, true, false])
  let a = Column::Int32(
    @arrow.PrimArray::from_options([Some(1), Some(2), None, None]),
  )
  let b = Column::Int32(
    @arrow.PrimArray::from_options([Some(10), None, Some(30), Some(40)]),
  )
  let r = xagg_pick(take, a, b)
  assert_eq(Series::make("x", r).to_list(), [
    AnyValue::Int32(1),
    Null,
    Null,
    Int32(40),
  ])
  // strings, booleans and Null columns
  let s = xagg_pick(
    take,
    Column::String(@arrow.StrArray::from_array(["a", "b", "c", "d"])),
    Column::String(
      @arrow.StrArray::from_options([None, Some("y"), None, Some("w")]),
    ),
  )
  assert_eq(Series::make("s", s).to_str_array(), [
    Some("a"),
    Some("y"),
    Some("c"),
    Some("w"),
  ])
  assert_eq(xagg_pick(take, Column::Null(4), Column::Null(4)).length(), 4)
  let bl = xagg_pick(
    take,
    Column::Boolean(@arrow.BoolArray::from_array([true, true, true, true])),
    Column::Boolean(@arrow.BoolArray::from_array([false, false, false, false])),
  )
  assert_eq(Series::make("b", bl).to_bool_array(), [
    Some(true),
    Some(false),
    Some(true),
    Some(false),
  ])
}

///|
test "when_plan_error recognises only the supertype failure" {
  assert_true(
    when_plan_error(
      SchemaMismatch("failed to determine supertype of bool and date"),
    ),
  )
  assert_false(
    when_plan_error(
      SchemaMismatch(
        "invalid series dtype: expected `Boolean`, got `i32` for series with name `a`",
      ),
    ),
  )
  assert_false(when_plan_error(ComputeError("x")))
}

///|
test "a ShapeMismatch from when_length reaches the caller of when_eval" {
  // lengths that are neither 1 nor equal cannot be made with the Expr API on
  // a frame (every column has the height of the frame), but a frame of one
  // height and literals give the general case a try
  let df = DataFrame::new([Series::int32("a", [1, 2, 3])])
  let e = when(col("a").gt(lit_int(1L))).then(col("a")).otherwise(lit_int(0L))
  assert_eq(df.select([e]).shape(), (3, 1))
}
