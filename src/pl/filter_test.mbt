///|
test "filter drops null mask rows" {
  let s = @pl.Series::int32("a", [1, 2, 3])
  let m = @pl.Series::bool_nullable("m", [Some(true), None, Some(false)])
  assert_eq(s.filter(m).to_int32_array(), [Some(1)])
}

///|
test "filter keeps null values and the name for every type" {
  let m = @pl.Series::bool("m", [true, false, true])
  let a = @pl.Series::int32_nullable("a", [Some(1), Some(2), None])
  assert_eq(a.filter(m).to_int32_array(), [Some(1), None])
  assert_eq(a.filter(m).name(), "a")
  assert_eq(
    @pl.Series::str_nullable("s", [Some("x"), Some("y"), None])
    .filter(m)
    .to_str_array(),
    [Some("x"), None],
  )
  assert_eq(
    @pl.Series::bool("b", [true, false, false]).filter(m).to_bool_array(),
    [Some(true), Some(false)],
  )
  assert_eq(
    @pl.Series::float64("f", [1.0, 2.0, 3.0]).filter(m).to_float64_array(),
    [Some(1.0), Some(3.0)],
  )
  assert_eq(@pl.Series::int64("i", [1L, 2L, 3L]).filter(m).to_int64_array(), [
    Some(1L),
    Some(3L),
  ])
  assert_eq(
    @pl.Series::float32("f", [1.0, 2.0, 3.0]).filter(m).to_float32_array(),
    [Some(1.0), Some(3.0)],
  )
  assert_eq(
    @pl.Series::date("d", [1, 2, 3]).filter(m).get(1),
    @pl.AnyValue::Date(3),
  )
  assert_eq(
    @pl.Series::datetime("t", [1L, 2L, 3L]).filter(m).get(1),
    @pl.AnyValue::Datetime(3L),
  )
}

///|
test "filter on a Null column and with a sliced mask" {
  let n = @pl.Series::null("n", 3)
  let m = @pl.Series::bool_nullable("m", [Some(true), None, Some(true)])
  let r = n.filter(m)
  assert_eq(r.dtype(), @pl.DataType::Null)
  assert_eq(r.len(), 2)
  // a sliced mask / series (non-zero offsets) is read at the right rows
  let s = @pl.Series::int32("s", [9, 9, 1, 2, 3, 9]).slice(2, length=3)
  let big = @pl.Series::bool_nullable("m", [
    Some(false),
    Some(true),
    Some(false),
    Some(true),
    None,
    Some(true),
  ])
  assert_eq(s.filter(big.slice(1, length=3)).to_int32_array(), [
    Some(1),
    Some(3),
  ])
}

///|
test "a length 1 mask broadcasts" {
  let s = @pl.Series::int32("a", [1, 2, 3])
  assert_eq(s.filter(@pl.Series::bool("m", [true])).to_int32_array(), [
    Some(1),
    Some(2),
    Some(3),
  ])
  assert_eq(s.filter(@pl.Series::bool("m", [false])).len(), 0)
  assert_eq(s.filter(@pl.Series::bool_nullable("m", [None])).len(), 0)
  assert_eq(
    @pl.Series::int32("a", []).filter(@pl.Series::bool("m", [true])).len(),
    0,
  )
  assert_eq(
    @pl.Series::int32("a", [5])
    .filter(@pl.Series::bool("m", [true]))
    .to_int32_array(),
    [Some(5)],
  )
}

///|
test "filter errors" {
  let s = @pl.Series::int32("a", [1, 2, 3])
  assert_eq(
    err_text(() => s.filter(@pl.Series::bool("m", [true, false]))),
    "ShapeMismatch: filter's length: 2 differs from that of the series: 3",
  )
  assert_true(
    raises(() => s.filter(@pl.Series::bool("m", [])))
    is Some(@pl.ShapeMismatch(_)),
  )
  assert_true(
    raises(() => s.filter(@pl.Series::int32("m", [1, 0, 1])))
    is Some(@pl.SchemaMismatch(_)),
  )
  assert_true(
    raises(() => s.filter(@pl.Series::null("m", 3)))
    is Some(@pl.SchemaMismatch(_)),
  )
  assert_eq(
    err_text(() => s.filter(@pl.Series::str("m", ["x"]))),
    "SchemaMismatch: filter mask must be Boolean, got str",
  )
}

///|
test "shape mismatch" {
  let a = @pl.Series::int32("a", [1, 2])
  let b = @pl.Series::int32("b", [1, 2, 3])
  assert_true(raises(() => a.add(b)) is Some(@pl.ShapeMismatch(_)))
}

///|
// Checked against polars 2.1.0 (fw-scripts/mask_probe.py): a null mask entry
// drops the row, as `False` does; an all-null mask keeps nothing.
test "filter: a null in the mask drops the row" {
  let a = @pl.Series::int32_nullable("a", [None, Some(1), Some(9)])
  let m = @pl.Series::bool_nullable("m", [None, Some(true), Some(false)])
  assert_eq(a.filter(m).to_int32_array(), [Some(1)])
  let all_null = @pl.Series::bool_nullable("m", [None, None, None])
  assert_eq(a.filter(all_null).to_int32_array(), [])
  assert_eq(a.filter(all_null).len(), 0)
  assert_eq(a.filter(all_null).name(), "a")
  // the mask of a comparison with a null is null where the value is null
  let lt = a.lt(@pl.Series::int32("five", [5]))
  assert_eq(a.filter(lt).to_int32_array(), [Some(1)])
}
