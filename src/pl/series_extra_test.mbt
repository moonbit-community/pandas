///|
test "Series::is_sorted: nulls must sit on the side nulls_last says" {
  let s = @pl.Series::int64_nullable("x", [None, Some(1L), Some(2L)])
  assert_true(s.is_sorted())
  assert_false(s.is_sorted(nulls_last=true))
  assert_false(s.is_sorted(descending=true))
  let t = @pl.Series::int64_nullable("x", [Some(1L), Some(2L), None])
  assert_false(t.is_sorted())
  assert_true(t.is_sorted(nulls_last=true))
  let mid = @pl.Series::int64_nullable("x", [Some(1L), None, Some(2L)])
  assert_false(mid.is_sorted())
  assert_false(mid.is_sorted(nulls_last=true))
}

///|
test "Series::is_sorted: empty, one value and all null are sorted either way; NaN is the largest" {
  assert_true(@pl.Series::int64("x", []).is_sorted(descending=true))
  assert_true(@pl.Series::int64("x", [1L]).is_sorted(descending=true))
  assert_true(@pl.Series::null("x", 3).is_sorted(nulls_last=true))
  let f = @pl.Series::float64("x", [1.0, 2.0, 0.0 / 0.0])
  assert_true(f.is_sorted())
  assert_false(f.is_sorted(descending=true))
  assert_true(@pl.Series::float64("x", [-0.0, 0.0]).is_sorted())
  assert_true(@pl.Series::float64("x", [0.0, -0.0]).is_sorted(descending=true))
}

///|
test "Series::gather_every" {
  let s = @pl.Series::int64("x", [1L, 2L, 3L, 4L, 5L, 6L, 7L])
  assert_eq(s.gather_every(2).to_int64_array(), [
    Some(1L),
    Some(3L),
    Some(5L),
    Some(7L),
  ])
  assert_eq(s.gather_every(2, offset=1).to_int64_array(), [
    Some(2L),
    Some(4L),
    Some(6L),
  ])
  assert_eq(s.gather_every(3, offset=6).to_int64_array(), [Some(7L)])
  assert_eq(s.gather_every(3, offset=7).len(), 0)
  assert_eq(s.gather_every(100).len(), 1)
  assert_eq(s.gather_every(2, offset=1).name(), "x")
}

///|
test "Series::gather_every: n must be positive, offset must not be negative" {
  let s = @pl.Series::int64("x", [1L, 2L])
  assert_eq(
    shape_msg(() => ignore(s.gather_every(0))),
    "InvalidOperation: gather_every(n): n should be positive",
  )
  assert_eq(
    shape_msg(() => ignore(s.gather_every(-1))),
    "InvalidOperation: can't convert negative int to unsigned",
  )
  assert_eq(
    shape_msg(() => ignore(s.gather_every(2, offset=-1))),
    "InvalidOperation: can't convert negative int to unsigned",
  )
}

///|
test "DataFrame::gather_every" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L, 4L, 5L]),
    @pl.Series::str_nullable("b", [
      Some("x"),
      Some("y"),
      None,
      Some("w"),
      Some("v"),
    ]),
  ])
  let out = df.gather_every(2, offset=1)
  assert_eq(out.shape(), (2, 2))
  assert_eq(out.column("a").to_int64_array(), [Some(2L), Some(4L)])
}

///|
test "Series::any and all: Kleene logic and the ignore_nulls flag" {
  let s = @pl.Series::bool_nullable("x", [Some(true), None])
  assert_eq(s.any(), Some(true))
  assert_eq(s.all(), Some(true))
  assert_eq(s.all(ignore_nulls=false), None)
  assert_eq(s.any(ignore_nulls=false), Some(true))
  let f = @pl.Series::bool_nullable("x", [Some(false), None])
  assert_eq(f.any(), Some(false))
  assert_eq(f.any(ignore_nulls=false), None)
  assert_eq(f.all(ignore_nulls=false), Some(false))
  // an empty series: nothing is true, everything is true
  let e = @pl.Series::bool("x", [])
  assert_eq(e.any(), Some(false))
  assert_eq(e.all(), Some(true))
}

///|
test "Series::any and all refuse every type but Boolean" {
  assert_eq(
    shape_msg(() => ignore(@pl.Series::int32("x", [1]).any())),
    "SchemaMismatch: invalid series dtype: expected `Boolean`, got `i32` for series with name `x`",
  )
  assert_eq(
    shape_msg(() => ignore(@pl.Series::str("x", ["a"]).all())),
    "SchemaMismatch: invalid series dtype: expected `Boolean`, got `str` for series with name `x`",
  )
}

///|
/// A series that is a slice at offset 2 of a longer one.
fn sliced_series(xs : Array[Int64?]) -> @pl.Series {
  let all : Array[Int64?] = [Some(100L), Some(-100L)]
  all.append(xs)
  all.push(Some(5L))
  @pl.Series::int64_nullable("x", all).slice(2, length=xs.length())
}

///|
test "Series::is_sorted, gather_every, any and all on a slice (offset 2)" {
  let s = sliced_series([None, Some(1L), Some(2L), Some(2L)])
  assert_true(s.is_sorted())
  assert_false(s.is_sorted(nulls_last=true))
  assert_false(s.is_sorted(descending=true))
  assert_eq(s.gather_every(2, offset=1).to_int64_array(), [Some(1L), Some(2L)])
  assert_eq(s.gather_every(3).to_int64_array(), [None, Some(2L)])
  let t = sliced_series([Some(3L), Some(2L), None])
  assert_true(t.is_sorted(descending=true, nulls_last=true))
  assert_false(t.is_sorted(descending=true))
  let b = @pl.Series::bool_nullable("b", [
    Some(true),
    Some(true),
    None,
    Some(false),
    Some(true),
    Some(true),
  ]).slice(2, length=3)
  assert_eq(b.any(), Some(true))
  assert_eq(b.all(), Some(false))
  assert_eq(b.all(ignore_nulls=false), Some(false))
  let c = @pl.Series::bool_nullable("b", [
    Some(false),
    Some(false),
    None,
    Some(true),
    Some(false),
  ]).slice(2, length=2)
  assert_eq(c.all(ignore_nulls=false), None)
  assert_eq(c.all(), Some(true))
  assert_eq(c.any(), Some(true))
}
