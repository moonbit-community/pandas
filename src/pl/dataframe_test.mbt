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
    Some(@pl.ShapeMismatch(m)) =>
      assert_eq(m, "column 'b' has length 2 but column 'a' has length 1")
    _ => fail("expected ShapeMismatch")
  }
  // the third column is compared with the first one, not with its neighbour
  assert_eq(
    err_text(() => {
      @pl.DataFrame::new([
        @pl.Series::int64("x", [1L, 2L]),
        @pl.Series::int64("y", [3L, 4L]),
        @pl.Series::str("z", ["p", "q", "r"]),
      ])
    }),
    "ShapeMismatch: column 'z' has length 3 but column 'x' has length 2",
  )
  // a 0-row column against a non-empty one
  assert_eq(
    err_text(() => {
      @pl.DataFrame::new([
        @pl.Series::int64("a", [1L]),
        @pl.Series::null("n", 0),
      ])
    }),
    "ShapeMismatch: column 'n' has length 0 but column 'a' has length 1",
  )
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
  // every column of the frame must equal the same operation on the series
  fn check(d : @pl.DataFrame, f : (@pl.Series) -> @pl.Series) -> Unit raise {
    assert_eq(d.width(), 2)
    assert_eq(d.columns(), ["a", "b"])
    for name in df.columns() {
      let expected = f(df.column(name))
      assert_eq(d.height(), expected.len())
      assert_eq(d.column(name).dtype(), expected.dtype())
      assert_eq(d.column(name).to_list(), expected.to_list())
    }
  }

  check(df.head(), s => s.head())
  check(df.head(n=0), s => s.head(n=0))
  check(df.head(n=2), s => s.head(n=2))
  check(df.head(n=-2), s => s.head(n=-2))
  check(df.head(n=100), s => s.head(n=100))
  check(df.head(n=-100), s => s.head(n=-100))
  check(df.tail(n=2), s => s.tail(n=2))
  check(df.tail(n=-2), s => s.tail(n=-2))
  check(df.tail(n=100), s => s.tail(n=100))
  check(df.tail(n=-100), s => s.tail(n=-100))
  check(df.slice(1, length=2), s => s.slice(1, length=2))
  check(df.slice(-2), s => s.slice(-2))
  check(df.slice(-7, length=3), s => s.slice(-7, length=3))
  check(df.slice(10), s => s.slice(10))
  check(df.slice(1, length=-1), s => s.slice(1, length=-1))
  // extreme values must not overflow
  check(df.slice(@int.MIN_VALUE), s => s.slice(@int.MIN_VALUE))
  check(df.slice(@int.MIN_VALUE, length=@int.MAX_VALUE), s => {
    s.slice(@int.MIN_VALUE, length=@int.MAX_VALUE)
  })
  check(df.slice(0, length=@int.MAX_VALUE), s => {
    s.slice(0, length=@int.MAX_VALUE)
  })
  check(df.slice(@int.MAX_VALUE), s => s.slice(@int.MAX_VALUE))
  check(df.head(n=@int.MAX_VALUE), s => s.head(n=@int.MAX_VALUE))
  check(df.head(n=@int.MIN_VALUE), s => s.head(n=@int.MIN_VALUE))
  check(df.tail(n=@int.MAX_VALUE), s => s.tail(n=@int.MAX_VALUE))
  check(df.tail(n=@int.MIN_VALUE), s => s.tail(n=@int.MIN_VALUE))
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
test "DataFrame::row out-of-bounds message" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L]),
    @pl.Series::str("b", ["x", "y", "z"]),
  ])
  assert_eq(
    err_text(() => df.row(3)),
    "OutOfBounds: index 3 is out of bounds for DataFrame of height 3",
  )
  assert_eq(
    err_text(() => df.row(-4)),
    "OutOfBounds: index -4 is out of bounds for DataFrame of height 3",
  )
  assert_eq(
    err_text(() => df.row(@int.MIN_VALUE)),
    "OutOfBounds: index -2147483648 is out of bounds for DataFrame of height 3",
  )
  assert_eq(
    err_text(() => df.row(@int.MAX_VALUE)),
    "OutOfBounds: index 2147483647 is out of bounds for DataFrame of height 3",
  )
  // 0 rows, and no columns at all
  let z = @pl.DataFrame::new([@pl.Series::int64("a", [])])
  assert_eq(
    err_text(() => z.row(0)),
    "OutOfBounds: index 0 is out of bounds for DataFrame of height 0",
  )
  assert_eq(
    err_text(() => z.row(-1)),
    "OutOfBounds: index -1 is out of bounds for DataFrame of height 0",
  )
  assert_eq(
    err_text(() => @pl.DataFrame::empty().row(0)),
    "OutOfBounds: index 0 is out of bounds for DataFrame of height 0",
  )
}

///|
test "DataFrame::gather out-of-bounds message" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L]),
    @pl.Series::str("b", ["x", "y", "z"]),
  ])
  assert_eq(
    err_text(() => df.gather([0, 3])),
    "OutOfBounds: gather indices are out of bounds: index 3 for DataFrame of height 3",
  )
  assert_eq(
    err_text(() => df.gather([-4])),
    "OutOfBounds: gather indices are out of bounds: index -4 for DataFrame of height 3",
  )
  assert_eq(
    err_text(() => df.gather([@int.MIN_VALUE])),
    "OutOfBounds: gather indices are out of bounds: index -2147483648 for DataFrame of height 3",
  )
  assert_eq(
    err_text(() => df.gather([@int.MAX_VALUE])),
    "OutOfBounds: gather indices are out of bounds: index 2147483647 for DataFrame of height 3",
  )
  // the first offending index is reported
  assert_eq(
    err_text(() => df.gather([2, 9, -9])),
    "OutOfBounds: gather indices are out of bounds: index 9 for DataFrame of height 3",
  )
  assert_eq(
    err_text(() => df.gather([-9, 9])),
    "OutOfBounds: gather indices are out of bounds: index -9 for DataFrame of height 3",
  )
  let z = @pl.DataFrame::new([@pl.Series::int64("a", [])])
  assert_eq(
    err_text(() => z.gather([0])),
    "OutOfBounds: gather indices are out of bounds: index 0 for DataFrame of height 0",
  )
  assert_eq(
    err_text(() => @pl.DataFrame::empty().gather([-1])),
    "OutOfBounds: gather indices are out of bounds: index -1 for DataFrame of height 0",
  )
}

///|
test "DataFrame::get out-of-bounds message" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L]),
    @pl.Series::str("b", ["x", "y", "z"]),
  ])
  assert_eq(
    err_text(() => df.get(3, "a")),
    "OutOfBounds: index 3 is out of bounds for column 'a' of length 3",
  )
  assert_eq(
    err_text(() => df.get(-4, "b")),
    "OutOfBounds: index -4 is out of bounds for column 'b' of length 3",
  )
  assert_eq(
    err_text(() => df.get(@int.MIN_VALUE, "a")),
    "OutOfBounds: index -2147483648 is out of bounds for column 'a' of length 3",
  )
  assert_eq(
    err_text(() => df.get(@int.MAX_VALUE, "b")),
    "OutOfBounds: index 2147483647 is out of bounds for column 'b' of length 3",
  )
  // an unknown column is reported before the row is looked at
  assert_eq(
    err_text(() => df.get(99, "zz")),
    "ColumnNotFound: column 'zz' not found",
  )
  let z = @pl.DataFrame::new([@pl.Series::null("n", 0)])
  assert_eq(
    err_text(() => z.get(0, "n")),
    "OutOfBounds: index 0 is out of bounds for column 'n' of length 0",
  )
  // a frame without columns has no column 'a', whatever the row
  assert_eq(
    err_text(() => @pl.DataFrame::empty().get(0, "a")),
    "ColumnNotFound: column 'a' not found",
  )
  assert_true(
    raises(() => @pl.DataFrame::empty().get(0, "a"))
    is Some(@pl.ColumnNotFound(_)),
  )
}

///|
/// Every row of `df`, in order.
fn frame_rows(df : @pl.DataFrame) -> Array[Array[@pl.AnyValue]] raise {
  let out = []
  for i in 0..<df.height() {
    out.push(df.row(i))
  }
  out
}

///|
/// A 4-row frame with a null in every kind of column, plus a `Null` column.
fn null_frame() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int64_nullable("a", [Some(1L), None, Some(3L), None]),
    @pl.Series::str_nullable("b", [None, Some("x"), None, Some("w")]),
    @pl.Series::null("c", 4),
    @pl.Series::bool_nullable("d", [Some(true), None, None, Some(false)]),
    @pl.Series::float64_nullable("e", [None, Some(2.5), Some(-1.0), None]),
    @pl.Series::date_nullable("f", [Some(-1), Some(0), None, None]),
    @pl.Series::datetime_nullable("g", [None, None, Some(-1L), Some(7L)]),
    @pl.Series::int32_nullable("h", [None, Some(5), Some(-2), None]),
    @pl.Series::float32_nullable("i", [Some(1.5), None, None, Some(-0.25)]),
  ])
}

///|
fn null_row(i : Int32) -> Array[@pl.AnyValue] {
  let all = [
    [
      @pl.AnyValue::Int64(1L),
      @pl.AnyValue::Null,
      @pl.AnyValue::Null,
      @pl.AnyValue::Boolean(true),
      @pl.AnyValue::Null,
      @pl.AnyValue::Date(-1),
      @pl.AnyValue::Null,
      @pl.AnyValue::Null,
      @pl.AnyValue::Float32(1.5),
    ],
    [
      @pl.AnyValue::Null,
      @pl.AnyValue::String("x"),
      @pl.AnyValue::Null,
      @pl.AnyValue::Null,
      @pl.AnyValue::Float64(2.5),
      @pl.AnyValue::Date(0),
      @pl.AnyValue::Null,
      @pl.AnyValue::Int32(5),
      @pl.AnyValue::Null,
    ],
    [
      @pl.AnyValue::Int64(3L),
      @pl.AnyValue::Null,
      @pl.AnyValue::Null,
      @pl.AnyValue::Null,
      @pl.AnyValue::Float64(-1.0),
      @pl.AnyValue::Null,
      @pl.AnyValue::Datetime(-1L),
      @pl.AnyValue::Int32(-2),
      @pl.AnyValue::Null,
    ],
    [
      @pl.AnyValue::Null,
      @pl.AnyValue::String("w"),
      @pl.AnyValue::Null,
      @pl.AnyValue::Boolean(false),
      @pl.AnyValue::Null,
      @pl.AnyValue::Null,
      @pl.AnyValue::Datetime(7L),
      @pl.AnyValue::Null,
      @pl.AnyValue::Float32(-0.25),
    ],
  ]
  all[i]
}

///|
/// Asserts that `df` has the schema of `null_frame()` and exactly the rows
/// `null_row(i)` for the `i` in `which`.
fn check_null_frame(df : @pl.DataFrame, which : Array[Int32]) -> Unit raise {
  assert_eq(df.shape(), (which.length(), 9))
  assert_eq(df.schema(), [
    ("a", @pl.DataType::Int64),
    ("b", @pl.DataType::String),
    ("c", @pl.DataType::Null),
    ("d", @pl.DataType::Boolean),
    ("e", @pl.DataType::Float64),
    ("f", @pl.DataType::Date),
    ("g", @pl.DataType::Datetime),
    ("h", @pl.DataType::Int32),
    ("i", @pl.DataType::Float32),
  ])
  assert_eq(frame_rows(df), which.map(null_row))
  // a Null column keeps its length and stays all-null
  assert_eq(df.column("c").len(), which.length())
  assert_eq(df.column("c").null_count(), which.length())
}

///|
test "dataframe null path: head, tail, slice" {
  let df = null_frame()
  check_null_frame(df, [0, 1, 2, 3])
  check_null_frame(df.head(n=2), [0, 1])
  check_null_frame(df.head(n=-1), [0, 1, 2])
  check_null_frame(df.head(n=0), [])
  check_null_frame(df.head(), [0, 1, 2, 3])
  check_null_frame(df.tail(n=2), [2, 3])
  check_null_frame(df.tail(n=-3), [3])
  check_null_frame(df.tail(n=0), [])
  check_null_frame(df.slice(1, length=2), [1, 2])
  check_null_frame(df.slice(-3), [1, 2, 3])
  check_null_frame(df.slice(3), [3])
  check_null_frame(df.slice(9), [])
  // a slice of a slice keeps nulls aligned with their rows
  check_null_frame(df.slice(1).slice(1, length=2), [2, 3])
  check_null_frame(df.tail(n=3).head(n=2), [1, 2])
  // null counts are those of the window, not of the whole column
  assert_eq(df.slice(1, length=1).column("a").null_count(), 1)
  assert_eq(df.slice(2, length=1).column("a").null_count(), 0)
  assert_eq(df.head(n=2).column("c").null_count(), 2)
}

///|
test "dataframe null path: gather" {
  let df = null_frame()
  check_null_frame(df.gather([3, 0, 0, 2, 1]), [3, 0, 0, 2, 1])
  check_null_frame(df.gather([-1, -4]), [3, 0])
  check_null_frame(df.gather([]), [])
  // gathering from a slice indexes the window
  check_null_frame(df.slice(1, length=3).gather([2, 0]), [3, 1])
  // gathering only null rows of column `a` gives an all-null column
  let g = df.gather([1, 3])
  assert_eq(g.column("a").null_count(), 2)
  assert_eq(g.column("a").to_int64_array(), [None, None])
  assert_eq(g.column("c").to_list(), [@pl.AnyValue::Null, Null])
}

///|
test "dataframe null path: row and get" {
  let df = null_frame()
  for i in 0..<4 {
    assert_eq(df.row(i), null_row(i))
    assert_eq(df.row(i - 4), null_row(i))
  }
  let names = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
  for i in 0..<4 {
    for j, name in names {
      assert_eq(df.get(i, name), null_row(i)[j])
      assert_eq(df.get(i - 4, name), null_row(i)[j])
    }
  }
  // rows and cells of a sliced frame
  let t = df.tail(n=2)
  assert_eq(t.row(0), null_row(2))
  assert_eq(t.row(-1), null_row(3))
  assert_eq(t.get(0, "g"), @pl.AnyValue::Datetime(-1L))
  assert_eq(t.get(1, "c"), @pl.AnyValue::Null)
  assert_eq(t.get(0, "h"), @pl.AnyValue::Int32(-2))
  assert_eq(t.get(1, "i"), @pl.AnyValue::Float32(-0.25))
  assert_eq(t.get(-1, "h"), @pl.AnyValue::Null)
  assert_eq(
    err_text(() => t.get(2, "a")),
    "OutOfBounds: index 2 is out of bounds for column 'a' of length 2",
  )
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
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L]),
    @pl.Series::str_nullable("b", [None]),
  ])
  assert_eq(
    @debug.render(@debug.Debug::to_repr(df)),
    "[(\"a\", Int64, [Int64(1)]), (\"b\", String, [Null])]",
  )
  assert_eq(@debug.render(@debug.Debug::to_repr(@pl.DataFrame::empty())), "[]")
}
