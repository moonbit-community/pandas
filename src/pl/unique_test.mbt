///|
test "unique keeps the first occurrence in order, null is a value" {
  let s = @pl.Series::int64_nullable("a", [
    Some(3L),
    None,
    Some(1L),
    Some(3L),
    None,
    Some(2L),
    Some(1L),
  ])
  let u = s.unique(maintain_order=true)
  assert_eq(u.to_int64_array(), [Some(3L), None, Some(1L), Some(2L)])
  assert_eq(u.name(), "a")
  assert_eq(s.n_unique(), 4)
  // without maintain_order this library returns the same order
  assert_eq(s.unique().to_int64_array(), u.to_int64_array())
}

///|
test "unique and n_unique for every dtype" {
  let b = @pl.Series::bool_nullable("b", [Some(true), Some(true), None, None])
  assert_eq(b.unique().to_bool_array(), [Some(true), None])
  assert_eq(b.n_unique(), 2)
  assert_eq(@pl.Series::int32("i", [1, 1, 2]).unique().to_int32_array(), [
    Some(1),
    Some(2),
  ])
  assert_eq(
    @pl.Series::str("s", ["a", "b", "a", "\u{1F600}", "\u{FF61}", "b"]).n_unique(),
    4,
  )
  assert_true(
    @pl.Series::date("d", [1, 2, 1])
    .unique()
    .equals(@pl.Series::date("d", [1, 2])),
  )
  assert_eq(@pl.Series::datetime("t", [1L, 1L]).n_unique(), 1)
  assert_eq(@pl.Series::float32("f", [1.0, 1.0, 2.0]).n_unique(), 2)
}

///|
test "unique: NaN is one value, -0.0 equals 0.0 and the first one is kept" {
  let s = @pl.Series::float64("a", [
    sort_nan,
    -sort_nan,
    1.0,
    sort_nan,
    -0.0,
    0.0,
  ])
  assert_eq(s.n_unique(), 3)
  let u = s.unique()
  assert_eq(u.len(), 3)
  assert_true(u.equals(@pl.Series::float64("a", [sort_nan, 1.0, -0.0])))
  assert_eq(
    u.to_float64_array()[2].unwrap().reinterpret_as_int64(),
    @int64.MIN_VALUE,
  )
  let z = @pl.Series::float32("a", [0.0, -0.0])
  assert_eq(z.n_unique(), 1)
}

///|
test "unique on empty, single and Null series" {
  assert_eq(@pl.Series::int32("a", []).n_unique(), 0)
  assert_eq(@pl.Series::int32("a", []).unique().len(), 0)
  assert_eq(@pl.Series::str("a", ["x"]).n_unique(), 1)
  let n = @pl.Series::null("n", 4)
  assert_eq(n.n_unique(), 1)
  assert_eq(n.unique().len(), 1)
  assert_eq(n.unique().dtype(), @pl.DataType::Null)
  assert_eq(@pl.Series::null("n", 0).n_unique(), 0)
}

///|
test "unique scales: a hundred thousand rows with many duplicates" {
  let n = 100000
  let s = @pl.Series::int64("a", Array::makei(n, i => (i % 1000).to_int64()))
  assert_eq(s.n_unique(), 1000)
  let u = s.unique().to_int64_array()
  assert_eq(u.length(), 1000)
  assert_eq(u[999], Some(999L))
  // all distinct strings
  let t = @pl.Series::str("a", Array::makei(20000, i => "k\{i}"))
  assert_eq(t.n_unique(), 20000)
}

///|
test "is_in: values, null and NaN" {
  let a = @pl.Series::float64_nullable("a", [
    Some(1.0),
    Some(2.0),
    Some(sort_nan),
    None,
    Some(0.0),
  ])
  let b = @pl.Series::float64_nullable("b", [
    Some(sort_nan),
    None,
    Some(-0.0),
    Some(1.0),
  ])
  let r = a.is_in(b)
  assert_eq(r.name(), "a")
  assert_eq(r.dtype(), @pl.DataType::Boolean)
  // a null in `a` is null (also when `b` has one); NaN matches NaN; 0.0 matches -0.0
  assert_eq(r.to_bool_array(), [
    Some(true),
    Some(false),
    Some(true),
    None,
    Some(true),
  ])
}

///|
test "is_in: empty, all-null and Null other" {
  let a = @pl.Series::int64_nullable("a", [Some(1L), None])
  assert_eq(a.is_in(@pl.Series::int64("b", [])).to_bool_array(), [
    Some(false),
    None,
  ])
  assert_eq(
    a.is_in(@pl.Series::int64_nullable("b", [None, None])).to_bool_array(),
    [Some(false), None],
  )
  assert_eq(a.is_in(@pl.Series::null("b", 2)).to_bool_array(), [
    Some(false),
    None,
  ])
  assert_eq(@pl.Series::null("n", 2).is_in(a).to_bool_array(), [None, None])
  assert_eq(
    @pl.Series::null("n", 2).is_in(@pl.Series::null("m", 1)).dtype(),
    @pl.DataType::Boolean,
  )
  assert_eq(@pl.Series::int64("e", []).is_in(a).len(), 0)
}

///|
test "is_in: integer widths and float widths mix, other kinds do not" {
  let i = @pl.Series::int32("a", [1, 2, 3])
  assert_eq(
    i.is_in(@pl.Series::int64("b", [3000000000L, 2L])).to_bool_array(),
    [Some(false), Some(true), Some(false)],
  )
  let j = @pl.Series::int64("a", [1L, 3000000000L])
  assert_eq(j.is_in(@pl.Series::int32("b", [1])).to_bool_array(), [
    Some(true),
    Some(false),
  ])
  // Float32 is widened to Float64: 0.1f is not 0.1
  let f = @pl.Series::float32("a", [0.1, 0.5])
  assert_eq(f.is_in(@pl.Series::float64("b", [0.1, 0.5])).to_bool_array(), [
    Some(false),
    Some(true),
  ])
  assert_eq(
    @pl.Series::float64("a", [0.5])
    .is_in(@pl.Series::float32("b", [0.5]))
    .to_bool_array(),
    [Some(true)],
  )
}

///|
test "is_in: strings by code point and booleans" {
  let a = @pl.Series::str_nullable("a", [
    Some("\u{FF61}"),
    Some("\u{1F600}"),
    Some("x"),
    None,
  ])
  let b = @pl.Series::str("b", ["\u{1F600}", "\u{FF61}"])
  assert_eq(a.is_in(b).to_bool_array(), [
    Some(true),
    Some(true),
    Some(false),
    None,
  ])
  let t = @pl.Series::bool("t", [true, false])
  assert_eq(t.is_in(@pl.Series::bool("o", [false])).to_bool_array(), [
    Some(false),
    Some(true),
  ])
}

///|
test "is_in: incompatible types raise InvalidOperation with polars' message" {
  let i = @pl.Series::int32("a", [1])
  match raises(() => i.is_in(@pl.Series::str("b", ["x"]))) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(m, "'is_in' cannot check for Int32 values in List(String) data")
    _ => fail("unexpected error")
  }
  // an integer against a float: polars ends the message with a period
  match raises(() => i.is_in(@pl.Series::float64("b", [1.0]))) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(
        m, "'is_in' cannot check for Int32 values in List(Float64) data.",
      )
    _ => fail("unexpected error")
  }
  match
    raises(() => {
      @pl.Series::datetime("a", [1L]).is_in(@pl.Series::date("b", [1]))
    }) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(
        m, "'is_in' cannot check for Datetime('\u{3bc}s') values in List(Date) data",
      )
    _ => fail("unexpected error")
  }
  assert_true(
    raises(() => @pl.Series::bool("a", [true]).is_in(i))
    is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "is_in on a large other uses a hash lookup" {
  let n = 50000
  let a = @pl.Series::int64("a", Array::makei(n, i => (i * 2).to_int64()))
  let b = @pl.Series::int64("b", Array::makei(n, i => (i * 3).to_int64()))
  let r = a.is_in(b).to_bool_array()
  let mut hits = 0
  for x in r {
    if x == Some(true) {
      hits += 1
    }
  }
  // multiples of 6 below 100000: 0, 6, ..., 99996
  assert_eq(hits, 16667)
}
