///|
test "dataframe construct and validate" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L]),
    @pl.Series::str_nullable("b", [Some("x"), None, Some("z")]),
  ])
  assert_eq(df.shape(), (3, 2))
  assert_eq(df.schema(), [
    ("a", @pl.DataType::Int64),
    ("b", @pl.DataType::String),
  ])
  assert_eq(df.get(-1, "b"), @pl.AnyValue::String("z"))
  assert_eq(df.row(1), [@pl.AnyValue::Int64(2L), @pl.AnyValue::Null])
  assert_eq(df.get_column_index("b"), Some(1))
  assert_eq(df.tail(n=2).column("a").to_int64_array(), [Some(2L), Some(3L)])
  assert_eq(df.gather([2, 0]).row(0), [
    @pl.AnyValue::Int64(3L),
    @pl.AnyValue::String("z"),
  ])
}

///|
test "dataframe accessors" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L]),
    @pl.Series::float64("b", [1.0, 2.0, 3.0]),
  ])
  assert_eq(df.height(), 3)
  assert_eq(df.width(), 2)
  assert_eq(df.columns(), ["a", "b"])
  assert_eq(df.dtypes(), [@pl.DataType::Int64, @pl.DataType::Float64])
  assert_eq(df.get_column_index("a"), Some(0))
  assert_eq(df.get_column_index("zz"), None)
  assert_eq(df.column("b").dtype(), @pl.DataType::Float64)
  assert_eq(df.get_columns().length(), 2)
  assert_eq(df.get(0, "a"), @pl.AnyValue::Int64(1L))
  assert_eq(df.get(-3, "b"), @pl.AnyValue::Float64(1.0))
}

///|
test "dataframe errors" {
  let a = @pl.Series::int64("a", [1L])
  assert_true(
    raises(() => @pl.DataFrame::new([a, a])) is Some(@pl.DuplicateColumn(_)),
  )
  assert_true(
    raises(() => @pl.DataFrame::new([a, @pl.Series::int64("b", [1L, 2L])]))
    is Some(@pl.ShapeMismatch(_)),
  )
  let df = @pl.DataFrame::new([a])
  assert_true(raises(() => df.column("zz")) is Some(@pl.ColumnNotFound(_)))
  assert_true(raises(() => df.row(1)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => df.get(0, "zz")) is Some(@pl.ColumnNotFound(_)))
}

///|
test "dataframe error messages" {
  let a = @pl.Series::int64("a", [1L])
  match raises(() => @pl.DataFrame::new([a, a])) {
    Some(@pl.DuplicateColumn(m)) =>
      assert_eq(m, "column with name 'a' has more than one occurrence")
    _ => fail("expected DuplicateColumn")
  }
  match
    raises(() => @pl.DataFrame::new([a, @pl.Series::int64("b", [1L, 2L])])) {
    Some(@pl.ShapeMismatch(m)) => {
      assert_true(m.contains("'a'"))
      assert_true(m.contains("'b'"))
      assert_true(m.contains("1"))
      assert_true(m.contains("2"))
    }
    _ => fail("expected ShapeMismatch")
  }
  match raises(() => @pl.DataFrame::new([a]).column("zz")) {
    Some(@pl.ColumnNotFound(m)) => assert_eq(m, "column 'zz' not found")
    _ => fail("expected ColumnNotFound")
  }
}

///|
test "empty frames" {
  assert_eq(@pl.DataFrame::empty().shape(), (0, 0))
  assert_eq(@pl.DataFrame::new([]).shape(), (0, 0))
  let z = @pl.DataFrame::new([@pl.Series::int64("a", [])])
  assert_eq(z.shape(), (0, 1))
  assert_eq(z.head().shape(), (0, 1))
  assert_eq(z.tail().shape(), (0, 1))
  assert_eq(z.slice(0).shape(), (0, 1))
  assert_eq(z.gather([]).shape(), (0, 1))
  assert_true(raises(() => z.row(0)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => z.row(-1)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => z.gather([0])) is Some(@pl.OutOfBounds(_)))
  let e = @pl.DataFrame::empty()
  assert_eq(e.height(), 0)
  assert_eq(e.width(), 0)
  assert_eq(e.columns(), [])
  assert_eq(e.head().shape(), (0, 0))
  assert_eq(e.slice(-3, length=2).shape(), (0, 0))
  assert_eq(e.gather([]).shape(), (0, 0))
  assert_true(raises(() => e.row(0)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => e.gather([0])) is Some(@pl.OutOfBounds(_)))
  assert_true(e == @pl.DataFrame::new([]))
}

///|
test "get_columns does not leak internal state" {
  let df = @pl.DataFrame::new([@pl.Series::int64("a", [1L])])
  let cols = df.get_columns()
  cols.push(@pl.Series::int64("b", [2L]))
  assert_eq(df.width(), 1)
  assert_eq(df.get_columns().length(), 1)
}

///|
test "dataframe head tail slice semantics equal series" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L, 4L, 5L]),
    @pl.Series::str("b", ["a", "b", "c", "d", "e"]),
  ])
  let a = df.column("a")
  fn check(d : @pl.DataFrame, s : @pl.Series) -> Unit raise {
    assert_eq(d.height(), s.len())
    assert_eq(d.width(), 2)
    assert_eq(d.column("a").to_list(), s.to_list())
  }

  check(df.head(), a.head())
  check(df.head(n=0), a.head(n=0))
  check(df.head(n=2), a.head(n=2))
  check(df.head(n=-2), a.head(n=-2))
  check(df.head(n=100), a.head(n=100))
  check(df.head(n=-100), a.head(n=-100))
  check(df.tail(n=2), a.tail(n=2))
  check(df.tail(n=-2), a.tail(n=-2))
  check(df.tail(n=100), a.tail(n=100))
  check(df.tail(n=-100), a.tail(n=-100))
  check(df.slice(1, length=2), a.slice(1, length=2))
  check(df.slice(-2), a.slice(-2))
  check(df.slice(-7, length=3), a.slice(-7, length=3))
  check(df.slice(10), a.slice(10))
  check(df.slice(1, length=-1), a.slice(1, length=-1))
  // extreme values must not overflow
  check(df.slice(@int.MIN_VALUE), a.slice(@int.MIN_VALUE))
  check(
    df.slice(@int.MIN_VALUE, length=@int.MAX_VALUE),
    a.slice(@int.MIN_VALUE, length=@int.MAX_VALUE),
  )
  check(df.slice(0, length=@int.MAX_VALUE), a.slice(0, length=@int.MAX_VALUE))
  check(df.slice(@int.MAX_VALUE), a.slice(@int.MAX_VALUE))
  check(df.head(n=@int.MAX_VALUE), a.head(n=@int.MAX_VALUE))
  check(df.head(n=@int.MIN_VALUE), a.head(n=@int.MIN_VALUE))
  check(df.tail(n=@int.MAX_VALUE), a.tail(n=@int.MAX_VALUE))
  check(df.tail(n=@int.MIN_VALUE), a.tail(n=@int.MIN_VALUE))
  // columns stay aligned
  assert_eq(df.slice(1, length=2).row(0), [
    @pl.AnyValue::Int64(2L),
    @pl.AnyValue::String("b"),
  ])
  assert_eq(df.slice(@int.MIN_VALUE, length=@int.MAX_VALUE).height(), 4)
}

///|
test "dataframe row get gather extreme indices" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L]),
    @pl.Series::str("b", ["x", "y", "z"]),
  ])
  assert_eq(df.row(-3), [@pl.AnyValue::Int64(1L), @pl.AnyValue::String("x")])
  assert_eq(df.row(2), [@pl.AnyValue::Int64(3L), @pl.AnyValue::String("z")])
  assert_true(raises(() => df.row(3)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => df.row(-4)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => df.row(@int.MIN_VALUE)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => df.row(@int.MAX_VALUE)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => df.get(3, "a")) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => df.get(-4, "a")) is Some(@pl.OutOfBounds(_)))
  assert_true(
    raises(() => df.get(@int.MIN_VALUE, "a")) is Some(@pl.OutOfBounds(_)),
  )
  assert_eq(df.get(-3, "a"), @pl.AnyValue::Int64(1L))
  assert_true(raises(() => df.gather([-4])) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => df.gather([0, 3])) is Some(@pl.OutOfBounds(_)))
  assert_true(
    raises(() => df.gather([@int.MIN_VALUE])) is Some(@pl.OutOfBounds(_)),
  )
  let g = df.gather([-1, 0, 0, -3])
  assert_eq(g.height(), 4)
  assert_eq(g.column("a").to_int64_array(), [
    Some(3L),
    Some(1L),
    Some(1L),
    Some(1L),
  ])
  assert_eq(g.column("b").to_str_array(), [
    Some("z"),
    Some("x"),
    Some("x"),
    Some("x"),
  ])
}

///|
test "dataframe equals" {
  fn mk(v : Double) -> @pl.DataFrame raise {
    @pl.DataFrame::new([
      @pl.Series::int64_nullable("a", [Some(1L), None]),
      @pl.Series::float64("b", [v, 2.0]),
    ])
  }
  assert_true(mk(1.0).equals(mk(1.0)))
  assert_true(mk(1.0) == mk(1.0))
  assert_false(mk(1.0) == mk(1.5))
  // NaN equals NaN
  assert_true(mk(0.0 / 0.0) == mk(0.0 / 0.0))
  // null equals null
  let n1 = @pl.DataFrame::new([@pl.Series::null("n", 2)])
  let n2 = @pl.DataFrame::new([@pl.Series::null("n", 2)])
  assert_true(n1 == n2)
  // column names, order, dtypes, heights
  let a = @pl.Series::int64("a", [1L])
  let b = @pl.Series::int64("b", [1L])
  assert_false(@pl.DataFrame::new([a, b]) == @pl.DataFrame::new([b, a]))
  assert_false(@pl.DataFrame::new([a]) == @pl.DataFrame::new([a.rename("c")]))
  assert_false(
    @pl.DataFrame::new([a]) == @pl.DataFrame::new([@pl.Series::int32("a", [1])]),
  )
  assert_false(@pl.DataFrame::new([a]) == @pl.DataFrame::new([a, b]))
  assert_false(
    @pl.DataFrame::new([a]) ==
    @pl.DataFrame::new([@pl.Series::int64("a", [1L, 1L])]),
  )
  assert_false(@pl.DataFrame::empty() == @pl.DataFrame::new([a]))
  // 0 rows but different schema
  assert_false(
    @pl.DataFrame::new([@pl.Series::int64("a", [])]) ==
    @pl.DataFrame::new([@pl.Series::str("a", [])]),
  )
}

///|
test "dataframe debug" {
  let df = @pl.DataFrame::new([@pl.Series::int64("a", [1L])])
  let s = @debug.to_string(df)
  assert_true(s.contains("\"a\""))
  assert_true(@debug.to_string(@pl.DataFrame::empty()).length() > 0)
}
