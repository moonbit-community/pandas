///|
let sort_nan : Double = 0.0 / 0.0

///|
let sort_inf : Double = 1.0 / 0.0

///|
test "sort ascending puts null first, descending keeps null first" {
  let s = @pl.Series::int64_nullable("a", [Some(3L), None, Some(1L), Some(2L)])
  assert_eq(s.sort().to_int64_array(), [None, Some(1L), Some(2L), Some(3L)])
  assert_eq(s.sort(descending=true).to_int64_array(), [
    None,
    Some(3L),
    Some(2L),
    Some(1L),
  ])
  assert_eq(s.sort(nulls_last=true).to_int64_array(), [
    Some(1L),
    Some(2L),
    Some(3L),
    None,
  ])
  assert_eq(s.sort(descending=true, nulls_last=true).to_int64_array(), [
    Some(3L),
    Some(2L),
    Some(1L),
    None,
  ])
}

///|
test "sort keeps name and type for every dtype" {
  let b = @pl.Series::bool_nullable("b", [Some(true), None, Some(false)])
  assert_eq(b.sort().to_bool_array(), [None, Some(false), Some(true)])
  assert_eq(b.sort().name(), "b")
  let i = @pl.Series::int32("i", [5, -3, 0])
  assert_eq(i.sort().to_int32_array(), [Some(-3), Some(0), Some(5)])
  assert_eq(i.sort().dtype(), @pl.DataType::Int32)
  let f = @pl.Series::float32_nullable("f", [Some(2.5), None, Some(-1.0)])
  assert_eq(f.sort(descending=true).to_float32_array(), [
    None,
    Some(2.5),
    Some(-1.0),
  ])
  let d = @pl.Series::date("d", [19782, -1, 0])
  assert_true(d.sort().equals(@pl.Series::date("d", [-1, 0, 19782])))
  assert_eq(d.sort().dtype(), @pl.DataType::Date)
  let t = @pl.Series::datetime("t", [5L, 1L])
  assert_true(t.sort().equals(@pl.Series::datetime("t", [1L, 5L])))
  assert_eq(t.sort().dtype(), @pl.DataType::Datetime)
  let n = @pl.Series::null("n", 3)
  assert_eq(n.sort().len(), 3)
  assert_eq(n.sort().dtype(), @pl.DataType::Null)
}

///|
test "sort orders NaN after every number and before the nulls of nulls_last" {
  let s = @pl.Series::float64_nullable("a", [
    Some(1.0),
    Some(sort_nan),
    None,
    Some(-sort_inf),
    Some(sort_inf),
    Some(sort_nan),
  ])
  assert_true(
    s
    .sort()
    .equals(
      @pl.Series::float64_nullable("a", [
        None,
        Some(-sort_inf),
        Some(1.0),
        Some(sort_inf),
        Some(sort_nan),
        Some(sort_nan),
      ]),
    ),
  )
  assert_true(
    s
    .sort(descending=true, nulls_last=true)
    .equals(
      @pl.Series::float64_nullable("a", [
        Some(sort_nan),
        Some(sort_nan),
        Some(sort_inf),
        Some(1.0),
        Some(-sort_inf),
        None,
      ]),
    ),
  )
}

///|
test "sort treats -0.0 and 0.0 as equal and keeps their order" {
  let s = @pl.Series::float64("a", [0.0, -0.0, 0.0, -0.0])
  let sorted = s.sort().to_float64_array()
  assert_eq(sorted.map(x => x.unwrap().reinterpret_as_int64()), [
    0L,
    @int64.MIN_VALUE,
    0L,
    @int64.MIN_VALUE,
  ])
  assert_eq(s.arg_sort().to_int64_array(), [
    Some(0L),
    Some(1L),
    Some(2L),
    Some(3L),
  ])
  assert_eq(s.arg_sort(descending=true).to_int64_array(), [
    Some(0L),
    Some(1L),
    Some(2L),
    Some(3L),
  ])
}

///|
test "sort compares strings by code point" {
  let s = @pl.Series::str_nullable("a", [
    Some("\u{FF61}"),
    Some("\u{1F600}"),
    Some("a"),
    Some(""),
    Some("Z"),
    None,
  ])
  assert_eq(s.sort().to_str_array(), [
    None,
    Some(""),
    Some("Z"),
    Some("a"),
    Some("\u{FF61}"),
    Some("\u{1F600}"),
  ])
  assert_eq(s.sort(descending=true, nulls_last=true).to_str_array(), [
    Some("\u{1F600}"),
    Some("\u{FF61}"),
    Some("a"),
    Some("Z"),
    Some(""),
    None,
  ])
}

///|
test "arg_sort is Int64, named like the series, null first, stable" {
  let s = @pl.Series::int32_nullable("k", [
    Some(2),
    None,
    Some(1),
    Some(2),
    None,
    Some(1),
  ])
  let r = s.arg_sort()
  assert_eq(r.dtype(), @pl.DataType::Int64)
  assert_eq(r.name(), "k")
  assert_eq(r.to_int64_array(), [
    Some(1L),
    Some(4L),
    Some(2L),
    Some(5L),
    Some(0L),
    Some(3L),
  ])
  // descending: still stable (ties keep their original order), nulls first
  assert_eq(s.arg_sort(descending=true).to_int64_array(), [
    Some(1L),
    Some(4L),
    Some(0L),
    Some(3L),
    Some(2L),
    Some(5L),
  ])
  assert_eq(s.arg_sort(descending=true, nulls_last=true).to_int64_array(), [
    Some(0L),
    Some(3L),
    Some(2L),
    Some(5L),
    Some(1L),
    Some(4L),
  ])
}

///|
test "sort and arg_sort on empty, single and Null series" {
  let e = @pl.Series::int64("e", [])
  assert_eq(e.sort().len(), 0)
  assert_eq(e.arg_sort().to_int64_array(), [])
  assert_eq(e.arg_sort().dtype(), @pl.DataType::Int64)
  let one = @pl.Series::str("o", ["x"])
  assert_eq(one.sort().to_str_array(), [Some("x")])
  assert_eq(one.arg_sort().to_int64_array(), [Some(0L)])
  let n = @pl.Series::null("n", 3)
  assert_eq(n.arg_sort().to_int64_array(), [Some(0L), Some(1L), Some(2L)])
  assert_eq(n.arg_sort(descending=true, nulls_last=true).to_int64_array(), [
    Some(0L),
    Some(1L),
    Some(2L),
  ])
}

///|
test "sort a million-scale reversed and sorted input stays fast and correct" {
  let n = 100000
  let down : Array[Int64] = Array::makei(n, i => (n - i).to_int64())
  let s = @pl.Series::int64("a", down)
  let r = s.sort().to_int64_array()
  assert_eq(r[0], Some(1L))
  assert_eq(r[n - 1], Some(n.to_int64()))
  let idx = s.arg_sort().to_int64_array()
  assert_eq(idx[0], Some((n - 1).to_int64()))
  assert_eq(idx[n - 1], Some(0L))
  // all equal: arg_sort is the identity
  let same = @pl.Series::int32("a", Array::make(n, 7))
  let ids = same.arg_sort(descending=true).to_int64_array()
  assert_eq(ids[0], Some(0L))
  assert_eq(ids[n - 1], Some((n - 1).to_int64()))
}
