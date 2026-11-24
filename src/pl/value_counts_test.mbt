///|
fn vc_x() -> @pl.Series {
  @pl.Series::int64_nullable("x", [
    Some(1L),
    Some(2L),
    None,
    Some(1L),
    Some(3L),
    Some(2L),
    Some(1L),
  ])
}

///|
test "value_counts lists the values in order of first appearance" {
  let out = vc_x().value_counts()
  assert_eq(out.columns(), ["x", "count"])
  assert_eq(out.dtypes(), [@pl.DataType::Int64, @pl.DataType::Int64])
  assert_eq(out.column("x").to_int64_array(), [
    Some(1L),
    Some(2L),
    None,
    Some(3L),
  ])
  assert_eq(out.column("count").to_int64_array(), [
    Some(3L),
    Some(2L),
    Some(1L),
    Some(1L),
  ])
}

///|
test "value_counts with sort puts the biggest first and keeps first appearance on ties" {
  let out = vc_x().value_counts(sort=true)
  assert_eq(out.column("x").to_int64_array(), [
    Some(1L),
    Some(2L),
    None,
    Some(3L),
  ])
  let s = @pl.Series::str("s", ["b", "a", "c", "a", "c", "b", "d", "c"])
  let o2 = s.value_counts(sort=true)
  assert_eq(o2.column("s").to_str_array(), [
    Some("c"),
    Some("b"),
    Some("a"),
    Some("d"),
  ])
  assert_eq(o2.column("count").to_int64_array(), [
    Some(3L),
    Some(2L),
    Some(2L),
    Some(1L),
  ])
}

///|
test "value_counts name and normalize" {
  let named = vc_x().value_counts(name="n")
  assert_eq(named.columns(), ["x", "n"])
  let p = vc_x().value_counts(normalize=true)
  assert_eq(p.columns(), ["x", "proportion"])
  assert_eq(p.dtypes(), [@pl.DataType::Int64, @pl.DataType::Float64])
  assert_eq(p.column("proportion").to_float64_array(), [
    Some(3.0 / 7.0),
    Some(2.0 / 7.0),
    Some(1.0 / 7.0),
    Some(1.0 / 7.0),
  ])
  let q = vc_x().value_counts(normalize=true, name="share")
  assert_eq(q.columns(), ["x", "share"])
}

///|
test "value_counts refuses a name equal to the series name" {
  match raises(() => vc_x().value_counts(name="x")) {
    Some(@pl.DuplicateColumn(m)) =>
      assert_eq(
        m, "using `value_counts` on a column/series named 'x' would lead to duplicate column names; change `name` to fix",
      )
    _ => fail("expected DuplicateColumn")
  }
  // also when the default name is the series name
  let s = @pl.Series::int64("count", [1L, 1L])
  assert_true(raises(() => s.value_counts()) is Some(@pl.DuplicateColumn(_)))
  let p = @pl.Series::int64("proportion", [1L, 1L])
  assert_true(
    raises(() => p.value_counts(normalize=true)) is Some(@pl.DuplicateColumn(_)),
  )
}

///|
test "value_counts of an empty series" {
  let e = @pl.Series::int64("x", [])
  let out = e.value_counts()
  assert_eq(out.shape(), (0, 2))
  assert_eq(out.dtypes(), [@pl.DataType::Int64, @pl.DataType::Int64])
  let p = e.value_counts(normalize=true)
  assert_eq(p.shape(), (0, 2))
  assert_eq(p.dtypes(), [@pl.DataType::Int64, @pl.DataType::Float64])
}

///|
test "value_counts treats null, NaN and signed zero as polars does" {
  let s = @pl.Series::float64_nullable("f", [
    Some(1.0),
    Some(0.0 / 0.0),
    None,
    Some(-0.0),
    Some(0.0),
    Some(0.0 / 0.0),
    None,
  ])
  let out = s.value_counts()
  assert_eq(out.height(), 4)
  assert_eq(out.column("count").to_int64_array(), [
    Some(1L),
    Some(2L),
    Some(2L),
    Some(2L),
  ])
  // the first member of a group is shown: -0.0 came before 0.0
  match out.get(3, "f") {
    Float64(x) =>
      assert_eq(x.reinterpret_as_int64(), (-0.0).reinterpret_as_int64())
    _ => fail("expected a Float64")
  }
  let n = @pl.Series::null("n", 3)
  let on = n.value_counts()
  assert_eq(on.shape(), (1, 2))
  assert_eq(on.dtypes(), [@pl.DataType::Null, @pl.DataType::Int64])
  assert_eq(on.column("count").to_int64_array(), [Some(3L)])
}

///|
test "value_counts normalize with only nulls is one" {
  let s = @pl.Series::int64_nullable("x", [None, None])
  let out = s.value_counts(normalize=true)
  assert_eq(out.column("proportion").to_float64_array(), [Some(1.0)])
}

///|
test "unique_counts is Int64 in order of first appearance and keeps the name" {
  let out = vc_x().unique_counts()
  assert_eq(out.name(), "x")
  assert_eq(out.dtype(), @pl.DataType::Int64)
  assert_eq(out.to_int64_array(), [Some(3L), Some(2L), Some(1L), Some(1L)])
  let e = @pl.Series::str("e", []).unique_counts()
  assert_eq(e.len(), 0)
  assert_eq(e.dtype(), @pl.DataType::Int64)
}

///|
test "value_counts works on a slice and on every type" {
  let s = @pl.Series::int32("a", [9, 1, 1, 2, 2, 2, 9]).slice(1, length=5)
  let out = s.value_counts()
  assert_eq(out.column("a").to_int32_array(), [Some(1), Some(2)])
  assert_eq(out.column("count").to_int64_array(), [Some(2L), Some(3L)])
  let b = @pl.Series::bool("b", [true, false, true]).value_counts()
  assert_eq(b.column("b").to_bool_array(), [Some(true), Some(false)])
  let d = @pl.Series::date("d", [5, 5, 6]).value_counts(sort=true)
  assert_eq(d.dtypes(), [@pl.DataType::Date, @pl.DataType::Int64])
  let t = @pl.Series::datetime("t", [5L, 6L, 6L]).value_counts(sort=true)
  assert_eq(t.column("count").to_int64_array(), [Some(2L), Some(1L)])
}
