///|
/// Text (`<Variant>: <message>`) of the error raised by `f`, or `"no error"`.
fn[T] err_text(f : () -> T raise @pl.PolarsError) -> String {
  match raises(f) {
    Some(e) => e.to_string()
    None => "no error"
  }
}

///|
test "series basics" {
  let s = @pl.Series::int64_nullable("a", [Some(1L), None, Some(3L)])
  assert_eq(s.len(), 3)
  assert_eq(s.null_count(), 1)
  assert_eq(s.dtype(), @pl.DataType::Int64)
  assert_eq(s.get(-1), @pl.AnyValue::Int64(3L))
  assert_eq(s.get(1), @pl.AnyValue::Null)
  assert_eq(s.rename("b").name(), "b")
  assert_eq(s.name(), "a")
  assert_eq(s.to_int64_array(), [Some(1L), None, Some(3L)])
  assert_false(s.is_empty())
}

///|
test "series errors" {
  let s = @pl.Series::str("s", ["x"])
  assert_true(raises(() => s.get(1)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => s.get(-2)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => s.gather([0, 5])) is Some(@pl.OutOfBounds(_)))
  assert_eq(
    err_text(() => s.to_int64_array()),
    "SchemaMismatch: column \"s\": expected i64 but the series has type str",
  )
  assert_eq(
    err_text(() => {
      @pl.Series::from_any_values("m", [
        @pl.AnyValue::Int64(1L),
        @pl.AnyValue::String("x"),
      ])
    }),
    "SchemaMismatch: column \"m\": expected i64 but found str at index 1",
  )
}

///|
test "slice head tail clamp" {
  let s = @pl.Series::int32("a", [0, 1, 2, 3, 4])
  assert_eq(s.slice(-2).to_int32_array(), [Some(3), Some(4)])
  assert_eq(s.slice(3, length=100).len(), 2)
  assert_eq(s.slice(@int.MIN_VALUE).len(), 5)
  // polars (checked against polars 2.1.0): offset -2^31 counts from the end,
  // so the window is [5 - 2^31, 4) and clamps to 4 rows, not 5.
  assert_eq(s.slice(@int.MIN_VALUE, length=@int.MAX_VALUE).len(), 4)
  assert_eq(s.slice(10).len(), 0)
  assert_eq(s.head(n=-2).len(), 3)
  assert_eq(s.tail(n=0).len(), 0)
  assert_eq(s.gather([-1, 0]).to_int32_array(), [Some(4), Some(0)])
  assert_eq(s.gather([]).len(), 0)
}

///|
test "equals treats null and NaN as equal" {
  let nan = 0.0 / 0.0
  assert_eq(
    @pl.Series::float64_nullable("f", [Some(nan), None]),
    @pl.Series::float64_nullable("f", [Some(nan), None]),
  )
  assert_false(
    @pl.Series::int64("a", [1L]).equals(@pl.Series::int64("b", [1L])),
  )
  assert_true(
    @pl.Series::int64("a", [1L]).equals(
      @pl.Series::int64("b", [1L]),
      check_names=false,
    ),
  )
}

///|
test "null series" {
  let n = @pl.Series::null("n", 3)
  assert_eq(n.dtype(), @pl.DataType::Null)
  assert_eq(n.null_count(), 3)
  assert_eq(
    @pl.Series::from_any_values("x", [Null, Null]).dtype(),
    @pl.DataType::Null,
  )
}

///|
test "null series slice gather get" {
  let n = @pl.Series::null("n", 3)
  assert_eq(n.len(), 3)
  assert_eq(n.get(-1), @pl.AnyValue::Null)
  assert_eq(n.slice(1).len(), 2)
  assert_eq(n.slice(1).null_count(), 2)
  assert_eq(n.gather([2, 2, 0, -1]).len(), 4)
  assert_eq(n.head(n=0).len(), 0)
  assert_eq(n.to_list(), [@pl.AnyValue::Null, Null, Null])
  assert_true(raises(() => n.get(3)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => n.gather([-4])) is Some(@pl.OutOfBounds(_)))
  assert_eq(
    err_text(() => n.to_int64_array()),
    "SchemaMismatch: column \"n\": expected i64 but the series has type null",
  )
  assert_true(n.equals(@pl.Series::null("n", 3)))
  assert_false(n.equals(@pl.Series::null("n", 2)))
  assert_eq(@pl.Series::null("z", 0).len(), 0)
  assert_true(@pl.Series::null("z", 0).is_empty())
}

///|
test "constructors and accessors for every type" {
  let b = @pl.Series::bool("b", [true, false])
  assert_eq(b.dtype(), @pl.DataType::Boolean)
  assert_eq(b.to_bool_array(), [Some(true), Some(false)])
  assert_eq(b.get(0), @pl.AnyValue::Boolean(true))
  let bn = @pl.Series::bool_nullable("b", [None, Some(true)])
  assert_eq(bn.to_bool_array(), [None, Some(true)])
  assert_eq(bn.null_count(), 1)
  let i32 = @pl.Series::int32_nullable("i", [Some(1), None])
  assert_eq(i32.dtype(), @pl.DataType::Int32)
  assert_eq(i32.to_int32_array(), [Some(1), None])
  assert_eq(i32.get(0), @pl.AnyValue::Int32(1))
  let f32 = @pl.Series::float32("f", [1.5, 2.5])
  assert_eq(f32.dtype(), @pl.DataType::Float32)
  assert_eq(f32.to_float32_array(), [Some(1.5), Some(2.5)])
  assert_eq(f32.get(1), @pl.AnyValue::Float32(2.5))
  let f32n = @pl.Series::float32_nullable("f", [None])
  assert_eq(f32n.null_count(), 1)
  let f64 = @pl.Series::float64_nullable("f", [Some(0.5), None])
  assert_eq(f64.dtype(), @pl.DataType::Float64)
  assert_eq(f64.to_float64_array(), [Some(0.5), None])
  assert_eq(f64.get(0), @pl.AnyValue::Float64(0.5))
  let st = @pl.Series::str_nullable("s", [Some("a"), None])
  assert_eq(st.dtype(), @pl.DataType::String)
  assert_eq(st.to_str_array(), [Some("a"), None])
  assert_eq(st.get(0), @pl.AnyValue::String("a"))
  let d = @pl.Series::date_nullable("d", [Some(-1), None, Some(19000)])
  assert_eq(d.dtype(), @pl.DataType::Date)
  assert_eq(d.get(0), @pl.AnyValue::Date(-1))
  assert_eq(d.get(1), @pl.AnyValue::Null)
  let dt = @pl.Series::datetime("t", [-1L, 5L])
  assert_eq(dt.dtype(), @pl.DataType::Datetime)
  assert_eq(dt.get(0), @pl.AnyValue::Datetime(-1L))
  let dtn = @pl.Series::datetime_nullable("t", [None])
  assert_eq(dtn.null_count(), 1)
  let i64 = @pl.Series::int64("i", [7L])
  assert_eq(i64.to_list(), [@pl.AnyValue::Int64(7L)])
  assert_eq(i64.dtype(), @pl.DataType::Int64)
}

///|
test "to_*_array type mismatch for every accessor" {
  let s = @pl.Series::int64("a", [1L])
  assert_eq(
    err_text(() => s.to_bool_array()),
    "SchemaMismatch: column \"a\": expected bool but the series has type i64",
  )
  assert_eq(
    err_text(() => s.to_int32_array()),
    "SchemaMismatch: column \"a\": expected i32 but the series has type i64",
  )
  assert_eq(
    err_text(() => s.to_float32_array()),
    "SchemaMismatch: column \"a\": expected f32 but the series has type i64",
  )
  assert_eq(
    err_text(() => s.to_float64_array()),
    "SchemaMismatch: column \"a\": expected f64 but the series has type i64",
  )
  assert_eq(
    err_text(() => s.to_str_array()),
    "SchemaMismatch: column \"a\": expected str but the series has type i64",
  )
  let d = @pl.Series::date("d", [1])
  assert_eq(
    err_text(() => d.to_int32_array()),
    "SchemaMismatch: column \"d\": expected i32 but the series has type date",
  )
  let t = @pl.Series::datetime("t", [1L])
  assert_eq(
    err_text(() => t.to_int64_array()),
    "SchemaMismatch: column \"t\": expected i64 but the series has type datetime[μs]",
  )
}

///|
test "from_any_values" {
  let s = @pl.Series::from_any_values("x", [
    Null,
    @pl.AnyValue::Int64(1L),
    Null,
    @pl.AnyValue::Int64(3L),
  ])
  assert_eq(s.dtype(), @pl.DataType::Int64)
  assert_eq(s.to_int64_array(), [None, Some(1L), None, Some(3L)])
  assert_eq(s.name(), "x")
  // explicit dtype
  let e = @pl.Series::from_any_values(
    "e",
    [@pl.AnyValue::Int32(1), Null],
    dtype=@pl.DataType::Int32,
  )
  assert_eq(e.to_int32_array(), [Some(1), None])
  // explicit dtype with only nulls
  let n = @pl.Series::from_any_values(
    "n",
    [@pl.AnyValue::Null, Null],
    dtype=@pl.DataType::Float64,
  )
  assert_eq(n.dtype(), @pl.DataType::Float64)
  assert_eq(n.null_count(), 2)
  // empty
  assert_eq(@pl.Series::from_any_values("z", []).dtype(), @pl.DataType::Null)
  assert_eq(@pl.Series::from_any_values("z", []).len(), 0)
  // every dtype
  let all = [
    (@pl.AnyValue::Boolean(true), @pl.DataType::Boolean),
    (@pl.AnyValue::Int32(1), @pl.DataType::Int32),
    (@pl.AnyValue::Int64(1L), @pl.DataType::Int64),
    (@pl.AnyValue::Float32(1.0), @pl.DataType::Float32),
    (@pl.AnyValue::Float64(1.0), @pl.DataType::Float64),
    (@pl.AnyValue::String("s"), @pl.DataType::String),
    (@pl.AnyValue::Date(3), @pl.DataType::Date),
    (@pl.AnyValue::Datetime(3L), @pl.DataType::Datetime),
  ]
  for p in all {
    let (v, dt) = p
    let r = @pl.Series::from_any_values("c", [v, Null])
    assert_eq(r.dtype(), dt)
    assert_eq(r.to_list(), [v, Null])
  }
  // errors: no implicit promotion
  assert_eq(
    err_text(() => {
      @pl.Series::from_any_values(
        "m",
        [@pl.AnyValue::Int32(1)],
        dtype=@pl.DataType::Int64,
      )
    }),
    "SchemaMismatch: column \"m\": expected i64 but found i32 at index 0",
  )
  assert_eq(
    err_text(() => {
      @pl.Series::from_any_values("m", [
        @pl.AnyValue::Int32(1),
        @pl.AnyValue::Float64(1.0),
      ])
    }),
    "SchemaMismatch: column \"m\": expected i32 but found f64 at index 1",
  )
  assert_eq(
    err_text(() => {
      @pl.Series::from_any_values(
        "m",
        [@pl.AnyValue::String("x")],
        dtype=@pl.DataType::Null,
      )
    }),
    "SchemaMismatch: column \"m\": expected null but found str at index 0",
  )
}

///|
test "get extreme indices" {
  let s = @pl.Series::int32("a", [10, 20, 30])
  assert_eq(s.get(-3), @pl.AnyValue::Int32(10))
  assert_eq(s.get(0), @pl.AnyValue::Int32(10))
  assert_eq(s.get(2), @pl.AnyValue::Int32(30))
  assert_true(raises(() => s.get(3)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => s.get(-4)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => s.get(@int.MIN_VALUE)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => s.get(@int.MAX_VALUE)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => s.gather([-4])) is Some(@pl.OutOfBounds(_)))
  assert_true(
    raises(() => s.gather([0, @int.MIN_VALUE])) is Some(@pl.OutOfBounds(_)),
  )
  match raises(() => s.get(3)) {
    Some(@pl.OutOfBounds(m)) =>
      assert_eq(m, "index 3 is out of bounds for sequence of length 3")
    _ => fail("expected OutOfBounds")
  }
  let e = @pl.Series::int32("e", [])
  assert_true(raises(() => e.get(0)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => e.get(-1)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => e.gather([0])) is Some(@pl.OutOfBounds(_)))
}

///|
test "empty series" {
  let e = @pl.Series::int64("e", [])
  assert_eq(e.len(), 0)
  assert_true(e.is_empty())
  assert_eq(e.null_count(), 0)
  assert_eq(e.head().len(), 0)
  assert_eq(e.tail().len(), 0)
  assert_eq(e.head(n=-3).len(), 0)
  assert_eq(e.tail(n=-3).len(), 0)
  assert_eq(e.slice(-5, length=2).len(), 0)
  assert_eq(e.gather([]).len(), 0)
  assert_eq(e.to_list(), [])
  assert_eq(e.to_int64_array(), [])
  assert_true(e.equals(@pl.Series::int64("e", [])))
  let s = @pl.Series::str("s", [])
  assert_eq(s.head(n=0).dtype(), @pl.DataType::String)
}

///|
test "slice offset and length edge cases" {
  let s = @pl.Series::int32("a", [0, 1, 2, 3, 4])
  assert_eq(s.slice(0).to_int32_array(), [
    Some(0),
    Some(1),
    Some(2),
    Some(3),
    Some(4),
  ])
  assert_eq(s.slice(1, length=2).to_int32_array(), [Some(1), Some(2)])
  assert_eq(s.slice(-3, length=2).to_int32_array(), [Some(2), Some(3)])
  assert_eq(s.slice(-5).len(), 5)
  // offset before the start: the window shifts, so only part of it remains
  assert_eq(s.slice(-7, length=3).to_int32_array(), [Some(0)])
  assert_eq(s.slice(-7, length=2).len(), 0)
  assert_eq(s.slice(-100, length=100).len(), 5)
  assert_eq(s.slice(-100, length=50).len(), 0)
  assert_eq(s.slice(5).len(), 0)
  assert_eq(s.slice(@int.MAX_VALUE).len(), 0)
  assert_eq(s.slice(@int.MAX_VALUE, length=@int.MAX_VALUE).len(), 0)
  assert_eq(s.slice(@int.MIN_VALUE).len(), 5)
  assert_eq(s.slice(@int.MIN_VALUE, length=@int.MAX_VALUE).len(), 4)
  assert_eq(s.slice(2, length=0).len(), 0)
  assert_eq(s.slice(2, length=-1).len(), 0)
  assert_eq(s.slice(1, length=@int.MAX_VALUE).len(), 4)
}

///|
test "head and tail" {
  let s = @pl.Series::int32("a", [0, 1, 2, 3, 4])
  assert_eq(s.head().len(), 5)
  assert_eq(s.head(n=2).to_int32_array(), [Some(0), Some(1)])
  assert_eq(s.head(n=0).len(), 0)
  assert_eq(s.head(n=99).len(), 5)
  assert_eq(s.head(n=-2).to_int32_array(), [Some(0), Some(1), Some(2)])
  assert_eq(s.head(n=-5).len(), 0)
  assert_eq(s.head(n=-99).len(), 0)
  assert_eq(s.head(n=@int.MIN_VALUE).len(), 0)
  assert_eq(s.head(n=@int.MAX_VALUE).len(), 5)
  assert_eq(s.tail().len(), 5)
  assert_eq(s.tail(n=2).to_int32_array(), [Some(3), Some(4)])
  assert_eq(s.tail(n=0).len(), 0)
  assert_eq(s.tail(n=99).len(), 5)
  assert_eq(s.tail(n=-2).to_int32_array(), [Some(2), Some(3), Some(4)])
  assert_eq(s.tail(n=-5).len(), 0)
  assert_eq(s.tail(n=-99).len(), 0)
  assert_eq(s.tail(n=@int.MIN_VALUE).len(), 0)
  assert_eq(s.tail(n=@int.MAX_VALUE).len(), 5)
  // nulls survive slicing
  let n = @pl.Series::int64_nullable("n", [Some(1L), None, Some(3L), None])
  assert_eq(n.head(n=2).to_int64_array(), [Some(1L), None])
  assert_eq(n.tail(n=2).to_int64_array(), [Some(3L), None])
  assert_eq(n.tail(n=2).null_count(), 1)
  assert_eq(n.slice(1, length=1).null_count(), 1)
  // the name is kept
  assert_eq(n.head(n=1).name(), "n")
  assert_eq(n.slice(1).name(), "n")
  assert_eq(n.gather([0]).name(), "n")
}

///|
test "gather with nulls, repeats and every dtype" {
  let n = @pl.Series::int64_nullable("n", [Some(1L), None, Some(3L)])
  assert_eq(n.gather([1, 1, 2, -3, -2]).to_int64_array(), [
    None,
    None,
    Some(3L),
    Some(1L),
    None,
  ])
  let st = @pl.Series::str_nullable("s", [Some("a"), None, Some("c")])
  assert_eq(st.gather([2, 0, 1]).to_str_array(), [Some("c"), Some("a"), None])
  let b = @pl.Series::bool_nullable("b", [Some(true), None, Some(false)])
  assert_eq(b.gather([2, 1, 0]).to_bool_array(), [Some(false), None, Some(true)])
  let f = @pl.Series::float32("f", [1.0, 2.0])
  assert_eq(f.gather([1, 1]).to_float32_array(), [Some(2.0), Some(2.0)])
  let f64 = @pl.Series::float64("f", [1.0, 2.0])
  assert_eq(f64.gather([-1]).to_float64_array(), [Some(2.0)])
  let d = @pl.Series::date("d", [5, 6])
  assert_eq(d.gather([1]).get(0), @pl.AnyValue::Date(6))
  assert_eq(d.slice(1).dtype(), @pl.DataType::Date)
  let t = @pl.Series::datetime("t", [5L, 6L])
  assert_eq(t.gather([1]).get(0), @pl.AnyValue::Datetime(6L))
  assert_eq(t.tail(n=1).dtype(), @pl.DataType::Datetime)
  let i32 = @pl.Series::int32("i", [5, 6])
  assert_eq(i32.slice(1).get(0), @pl.AnyValue::Int32(6))
  // a gather that yields no null drops nothing observable
  assert_eq(n.gather([0, 2]).null_count(), 0)
  // slicing then gathering composes
  assert_eq(n.slice(1).gather([-1, 0]).to_int64_array(), [Some(3L), None])
}

///|
test "equals details" {
  let nan = 0.0 / 0.0
  let fnan : Float = 0.0 / 0.0
  // NaN equals NaN for both float types, but 1.0 != NaN
  assert_true(
    @pl.Series::float32("f", [fnan]).equals(@pl.Series::float32("f", [fnan])),
  )
  assert_true(
    @pl.Series::float64("f", [nan, 1.0]).equals(
      @pl.Series::float64("f", [nan, 1.0]),
    ),
  )
  assert_false(
    @pl.Series::float64("f", [nan]).equals(@pl.Series::float64("f", [1.0])),
  )
  // null != NaN
  assert_false(
    @pl.Series::float64_nullable("f", [None]).equals(
      @pl.Series::float64("f", [nan]),
    ),
  )
  // null vs value
  assert_false(
    @pl.Series::int64_nullable("a", [None]).equals(@pl.Series::int64("a", [0L])),
  )
  // null in a different position
  assert_false(
    @pl.Series::int64_nullable("a", [None, Some(1L)]).equals(
      @pl.Series::int64_nullable("a", [Some(1L), None]),
    ),
  )
  // length differs
  assert_false(
    @pl.Series::int64("a", [1L]).equals(@pl.Series::int64("a", [1L, 2L])),
  )
  // -0.0 == 0.0 as in IEEE
  assert_true(
    @pl.Series::float64("f", [-0.0]).equals(@pl.Series::float64("f", [0.0])),
  )
  // dtype differs
  let i32 = @pl.Series::int32("a", [1])
  let i64 = @pl.Series::int64("a", [1L])
  assert_false(i32.equals(i64))
  assert_true(i32.equals(i64, check_dtypes=false))
  assert_false(i32.equals(@pl.Series::int64("a", [2L]), check_dtypes=false))
  assert_true(
    @pl.Series::int64("a", [1L]).equals(
      @pl.Series::float64("a", [1.0]),
      check_dtypes=false,
    ),
  )
  assert_false(
    @pl.Series::date("a", [1]).equals(
      @pl.Series::datetime("a", [1L]),
      check_dtypes=false,
    ),
  )
  assert_false(@pl.Series::str("a", ["1"]).equals(i64, check_dtypes=false))
  assert_true(
    @pl.Series::null("a", 2).equals(
      @pl.Series::int64_nullable("a", [None, None]),
      check_dtypes=false,
    ),
  )
  assert_false(
    @pl.Series::null("a", 2).equals(
      @pl.Series::int64_nullable("a", [None, None]),
    ),
  )
  // sliced views compare equal to freshly built ones
  let big = @pl.Series::str_nullable("s", [
    Some("x"),
    Some("a"),
    None,
    Some("q"),
  ])
  assert_true(
    big
    .slice(1, length=2)
    .equals(@pl.Series::str_nullable("s", [Some("a"), None])),
  )
  // every other dtype
  assert_true(
    @pl.Series::bool("a", [true]).equals(@pl.Series::bool("a", [true])),
  )
  assert_false(
    @pl.Series::bool("a", [true]).equals(@pl.Series::bool("a", [false])),
  )
  assert_true(@pl.Series::date("a", [1]).equals(@pl.Series::date("a", [1])))
  assert_false(
    @pl.Series::datetime("a", [1L]).equals(@pl.Series::datetime("a", [2L])),
  )
  assert_false(@pl.Series::str("a", ["x"]).equals(@pl.Series::str("a", ["y"])))
  assert_true(@pl.Series::int32("a", [1]).equals(@pl.Series::int32("a", [1])))
}

///|
test "series debug output shows name, dtype and values" {
  let s = @pl.Series::int64_nullable("col", [Some(1L), None])
  assert_eq(
    @debug.render(@debug.Debug::to_repr(s)),
    "(\"col\", Int64, [Int64(1), Null])",
  )
  assert_eq(
    @debug.render(@debug.Debug::to_repr(@pl.Series::null("n", 1))),
    "(\"n\", Null, [Null])",
  )
  assert_true(@pl.Series::int64("e", []) == @pl.Series::int64("e", []))
  assert_true(@pl.Series::int64("e", []) != @pl.Series::int64("f", []))
}

///|
test "equals with check_dtypes=false across numeric types" {
  let nan = 0.0 / 0.0
  let fnan : Float = 0.0 / 0.0
  // Int32 vs Int64: equal values, different values, nulls
  assert_true(
    @pl.Series::int32("a", [1, -2]).equals(
      @pl.Series::int64("a", [1L, -2L]),
      check_dtypes=false,
    ),
  )
  assert_true(
    @pl.Series::int64("a", [1L, -2L]).equals(
      @pl.Series::int32("a", [1, -2]),
      check_dtypes=false,
    ),
  )
  assert_false(
    @pl.Series::int32("a", [1, -2]).equals(
      @pl.Series::int64("a", [1L, 2L]),
      check_dtypes=false,
    ),
  )
  // null versus non-null in either order and either dtype order
  assert_false(
    @pl.Series::int32("a", [1]).equals(
      @pl.Series::int64_nullable("a", [None]),
      check_dtypes=false,
    ),
  )
  assert_false(
    @pl.Series::int64_nullable("a", [None]).equals(
      @pl.Series::int32("a", [1]),
      check_dtypes=false,
    ),
  )
  assert_false(
    @pl.Series::int32_nullable("a", [Some(0), None]).equals(
      @pl.Series::float64_nullable("a", [None, Some(0.0)]),
      check_dtypes=false,
    ),
  )
  assert_true(
    @pl.Series::int32_nullable("a", [Some(0), None]).equals(
      @pl.Series::int64_nullable("a", [Some(0L), None]),
      check_dtypes=false,
    ),
  )
  // Float32 vs Float64
  assert_true(
    @pl.Series::float32("f", [1.5, -0.25]).equals(
      @pl.Series::float64("f", [1.5, -0.25]),
      check_dtypes=false,
    ),
  )
  assert_false(
    @pl.Series::float32("f", [1.5]).equals(
      @pl.Series::float64("f", [2.5]),
      check_dtypes=false,
    ),
  )
  // NaN equals NaN across f32/f64, in both orders, but not 1.0
  assert_true(
    @pl.Series::float32("f", [fnan]).equals(
      @pl.Series::float64("f", [nan]),
      check_dtypes=false,
    ),
  )
  assert_true(
    @pl.Series::float64("f", [nan]).equals(
      @pl.Series::float32("f", [fnan]),
      check_dtypes=false,
    ),
  )
  assert_false(
    @pl.Series::float32("f", [fnan]).equals(
      @pl.Series::float64("f", [1.0]),
      check_dtypes=false,
    ),
  )
  assert_false(
    @pl.Series::float64("f", [nan]).equals(
      @pl.Series::float32("f", [1.0]),
      check_dtypes=false,
    ),
  )
  // NaN versus a null
  assert_false(
    @pl.Series::float32("f", [fnan]).equals(
      @pl.Series::float64_nullable("f", [None]),
      check_dtypes=false,
    ),
  )
  // integer versus NaN float
  assert_false(
    @pl.Series::int32("f", [1]).equals(
      @pl.Series::float64("f", [nan]),
      check_dtypes=false,
    ),
  )
  // all-null versus all-null of another dtype: equal; lengths still matter
  assert_true(
    @pl.Series::float32_nullable("a", [None, None]).equals(
      @pl.Series::str_nullable("a", [None, None]),
      check_dtypes=false,
    ),
  )
  assert_false(
    @pl.Series::float32_nullable("a", [None, None]).equals(
      @pl.Series::str_nullable("a", [None]),
      check_dtypes=false,
    ),
  )
  // all-null versus a series with a value is never equal
  assert_false(
    @pl.Series::null("a", 1).equals(
      @pl.Series::int64("a", [0L]),
      check_dtypes=false,
    ),
  )
  assert_false(
    @pl.Series::int64("a", [0L]).equals(
      @pl.Series::null("a", 1),
      check_dtypes=false,
    ),
  )
}

///|
test "slice bool, float32 and float64 series with nulls" {
  let b = @pl.Series::bool_nullable("b", [
    Some(true),
    None,
    Some(false),
    Some(true),
    None,
  ])
  let bs = b.slice(1, length=3)
  assert_eq(bs.len(), 3)
  assert_eq(bs.to_bool_array(), [None, Some(false), Some(true)])
  assert_eq(bs.null_count(), 1)
  assert_eq(b.slice(-2).to_bool_array(), [Some(true), None])
  assert_eq(b.slice(0, length=0).len(), 0)
  let f32 = @pl.Series::float32_nullable("f", [
    Some(1.5),
    None,
    Some(-2.5),
    Some(4.0),
    None,
  ])
  let f32s = f32.slice(1, length=3)
  assert_eq(f32s.len(), 3)
  assert_eq(f32s.to_float32_array(), [None, Some(-2.5), Some(4.0)])
  assert_eq(f32s.null_count(), 1)
  assert_eq(f32.slice(2).to_float32_array(), [Some(-2.5), Some(4.0), None])
  let f64 = @pl.Series::float64_nullable("d", [
    Some(1.5),
    None,
    Some(-2.5),
    Some(4.0),
    None,
  ])
  let f64s = f64.slice(1, length=3)
  assert_eq(f64s.len(), 3)
  assert_eq(f64s.to_float64_array(), [None, Some(-2.5), Some(4.0)])
  assert_eq(f64s.null_count(), 1)
  assert_eq(f64.slice(-3, length=2).to_float64_array(), [Some(-2.5), Some(4.0)])
  // head and tail go through the same slice path
  assert_eq(b.head(n=2).to_bool_array(), [Some(true), None])
  assert_eq(f32.tail(n=2).to_float32_array(), [Some(4.0), None])
  assert_eq(f64.head(n=1).to_float64_array(), [Some(1.5)])
}

///|
test "date series null_count and slice" {
  let d = @pl.Series::date_nullable("d", [Some(0), None, Some(-1), None, None])
  assert_eq(d.null_count(), 3)
  assert_eq(d.slice(1, length=2).null_count(), 1)
  assert_eq(d.slice(1, length=2).to_list(), [@pl.AnyValue::Null, Date(-1)])
  assert_eq(@pl.Series::date("d", [1, 2]).null_count(), 0)
  let dt = @pl.Series::datetime_nullable("t", [None, Some(5L)])
  assert_eq(dt.null_count(), 1)
}

///|
test "from_any_values mismatch reports dtype and index for every type" {
  // one bad value (a String) at index 2 for every non-String target type
  let good : Array[(@pl.DataType, @pl.AnyValue, String)] = [
    (Boolean, Boolean(true), "bool"),
    (Int32, Int32(1), "i32"),
    (Int64, Int64(1L), "i64"),
    (Float32, Float32(1.0), "f32"),
    (Float64, Float64(1.0), "f64"),
    (Date, Date(1), "date"),
    (Datetime, Datetime(1L), "datetime[μs]"),
  ]
  for p in good {
    let (dt, v, name) = p
    let bad : @pl.AnyValue = String("x")
    assert_eq(
      err_text(() => {
        @pl.Series::from_any_values("c", [v, Null, bad, v], dtype=dt)
      }),
      "SchemaMismatch: column \"c\": expected \{name} but found str at index 2",
    )
    // a mismatch at index 0 and at the last index
    assert_eq(
      err_text(() => @pl.Series::from_any_values("c", [bad, v], dtype=dt)),
      "SchemaMismatch: column \"c\": expected \{name} but found str at index 0",
    )
    assert_eq(
      err_text(() => {
        @pl.Series::from_any_values("c", [v, v, v, v, bad], dtype=dt)
      }),
      "SchemaMismatch: column \"c\": expected \{name} but found str at index 4",
    )
  }
  // String target: bad value is an Int32 at index 2
  assert_eq(
    err_text(() => {
      @pl.Series::from_any_values(
        "c",
        [String("a"), Null, Int32(7)],
        dtype=@pl.DataType::String,
      )
    }),
    "SchemaMismatch: column \"c\": expected str but found i32 at index 2",
  )
  // Null target: the offending non-null value's index
  assert_eq(
    err_text(() => {
      @pl.Series::from_any_values(
        "c",
        [Null, Null, Int64(1L)],
        dtype=@pl.DataType::Null,
      )
    }),
    "SchemaMismatch: column \"c\": expected null but found i64 at index 2",
  )
  // inferred dtype: the first non-null value decides, the later one fails
  assert_eq(
    err_text(() => {
      @pl.Series::from_any_values("c", [
        Null,
        Boolean(true),
        Boolean(false),
        Int32(1),
      ])
    }),
    "SchemaMismatch: column \"c\": expected bool but found i32 at index 3",
  )
}

///|
test "null series with a negative length is empty" {
  assert_eq(@pl.Series::null("z", -1).len(), 0)
  assert_eq(@pl.Series::null("z", @int.MIN_VALUE).len(), 0)
  assert_eq(@pl.Series::null("z", -1).null_count(), 0)
}

///|
test "Series::get out-of-bounds message" {
  let s = @pl.Series::int32("a", [10, 20, 30])
  assert_eq(
    err_text(() => s.get(3)),
    "OutOfBounds: index 3 is out of bounds for sequence of length 3",
  )
  assert_eq(
    err_text(() => s.get(-4)),
    "OutOfBounds: index -4 is out of bounds for sequence of length 3",
  )
  assert_eq(
    err_text(() => s.get(@int.MIN_VALUE)),
    "OutOfBounds: index -2147483648 is out of bounds for sequence of length 3",
  )
  assert_eq(
    err_text(() => s.get(@int.MAX_VALUE)),
    "OutOfBounds: index 2147483647 is out of bounds for sequence of length 3",
  )
  // empty and Null-typed series
  let e = @pl.Series::int32("e", [])
  assert_eq(
    err_text(() => e.get(0)),
    "OutOfBounds: index 0 is out of bounds for sequence of length 0",
  )
  assert_eq(
    err_text(() => e.get(-1)),
    "OutOfBounds: index -1 is out of bounds for sequence of length 0",
  )
  let n = @pl.Series::null("n", 2)
  assert_eq(
    err_text(() => n.get(2)),
    "OutOfBounds: index 2 is out of bounds for sequence of length 2",
  )
  assert_eq(
    err_text(() => n.get(-3)),
    "OutOfBounds: index -3 is out of bounds for sequence of length 2",
  )
}

///|
test "Series::gather out-of-bounds message" {
  let s = @pl.Series::int32("a", [10, 20, 30])
  assert_eq(
    err_text(() => s.gather([0, 5])),
    "OutOfBounds: gather indices are out of bounds: index 5 in column 'a' of length 3",
  )
  assert_eq(
    err_text(() => s.gather([-4])),
    "OutOfBounds: gather indices are out of bounds: index -4 in column 'a' of length 3",
  )
  assert_eq(
    err_text(() => s.gather([@int.MIN_VALUE])),
    "OutOfBounds: gather indices are out of bounds: index -2147483648 in column 'a' of length 3",
  )
  assert_eq(
    err_text(() => s.gather([@int.MAX_VALUE])),
    "OutOfBounds: gather indices are out of bounds: index 2147483647 in column 'a' of length 3",
  )
  // the first offending index is reported, later ones are not
  assert_eq(
    err_text(() => s.gather([1, 7, -9])),
    "OutOfBounds: gather indices are out of bounds: index 7 in column 'a' of length 3",
  )
  assert_eq(
    err_text(() => s.gather([-9, 7])),
    "OutOfBounds: gather indices are out of bounds: index -9 in column 'a' of length 3",
  )
  let e = @pl.Series::str("txt", [])
  assert_eq(
    err_text(() => e.gather([0])),
    "OutOfBounds: gather indices are out of bounds: index 0 in column 'txt' of length 0",
  )
  let n = @pl.Series::null("nul", 2)
  assert_eq(
    err_text(() => n.gather([1, 2])),
    "OutOfBounds: gather indices are out of bounds: index 2 in column 'nul' of length 2",
  )
  // valid indices (including negative ones) do not raise
  assert_eq(s.gather([-3, 2, 0]).to_int32_array(), [
    Some(10),
    Some(30),
    Some(10),
  ])
}
