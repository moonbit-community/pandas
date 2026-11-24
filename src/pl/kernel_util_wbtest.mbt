///|
test "Column::is_valid and validity" {
  let a = Column::Int32(
    @arrow.PrimArray::from_options([Some(1), None, Some(3)]),
  )
  assert_eq(a.is_valid(0), true)
  assert_eq(a.is_valid(1), false)
  assert_eq(a.validity().unwrap().to_array(), [true, false, true])
  let full = Column::Int64(@arrow.PrimArray::from_array([1L, 2L]))
  assert_true(full.validity() is None)
  assert_eq(full.is_valid(1), true)
  // every row of a Null column is null
  let n = Column::Null(3)
  assert_eq(n.is_valid(0), false)
  assert_eq(n.is_valid(2), false)
  assert_eq(n.validity().unwrap().to_array(), [false, false, false])
  assert_eq(Column::Null(0).validity().unwrap().length(), 0)
  let s = Column::String(@arrow.StrArray::from_options([None, Some("x")]))
  assert_eq(s.validity().unwrap().to_array(), [false, true])
  let b = Column::Boolean(@arrow.BoolArray::from_options([Some(true), None]))
  assert_eq(b.validity().unwrap().to_array(), [true, false])
  // a sliced column reports the sliced validity
  let sl = a.slice(1, 2)
  assert_eq(sl.validity().unwrap().to_array(), [false, true])
  assert_eq(sl.is_valid(0), false)
}

///|
test "Column::full_null" {
  for t in all_types {
    let c = Column::full_null(t, 4)
    assert_eq(c.dtype(), t)
    assert_eq(c.length(), 4)
    assert_eq(c.null_count(), 4)
  }
  assert_eq(Column::full_null(Int32, 0).length(), 0)
}

///|
test "Column::broadcast repeats the single row" {
  let c = Column::Int32(@arrow.PrimArray::from_array([7])).broadcast(3)
  assert_eq(c.length(), 3)
  assert_eq(Series::make("x", c).to_int32_array(), [Some(7), Some(7), Some(7)])
  let n = Column::String(@arrow.StrArray::from_options([None])).broadcast(2)
  assert_eq(Series::make("x", n).to_str_array(), [None, None])
  assert_eq(Column::Null(1).broadcast(4).length(), 4)
  assert_eq(Column::Null(1).broadcast(4).dtype(), DataType::Null)
  assert_eq(
    Column::Boolean(@arrow.BoolArray::from_array([true])).broadcast(0).length(),
    0,
  )
  assert_eq(
    Column::Float64(@arrow.PrimArray::from_array([1.5])).broadcast(1).length(),
    1,
  )
}

///|
test "Column::filter treats a null mask row as false" {
  let c = Column::Int32(
    @arrow.PrimArray::from_options([Some(1), None, Some(3), Some(4)]),
  )
  let m = @arrow.BoolArray::from_options([
    Some(true),
    Some(true),
    None,
    Some(false),
  ])
  assert_eq(Series::make("x", c.filter(m)).to_int32_array(), [Some(1), None])
  let all = @arrow.BoolArray::from_array([true, true, true, true])
  assert_eq(c.filter(all).length(), 4)
  let none = @arrow.BoolArray::from_array([false, false, false, false])
  assert_eq(c.filter(none).length(), 0)
  assert_eq(
    Column::Null(3)
    .filter(@arrow.BoolArray::from_options([Some(true), None, Some(true)]))
    .length(),
    2,
  )
  // a sliced mask
  let big = @arrow.BoolArray::from_array([false, true, false, true, true])
  assert_eq(Series::make("x", c.filter(big.slice(1, 4))).to_int32_array(), [
    Some(1),
    Some(3),
    Some(4),
  ])
}

///|
test "and_validity" {
  let a = @arrow.Bitmap::from_array([true, true, false, false])
  let b = @arrow.Bitmap::from_array([true, false, true, false])
  assert_true(and_validity(None, None) is None)
  assert_eq(and_validity(Some(a), None).unwrap().to_array(), [
    true, true, false, false,
  ])
  assert_eq(and_validity(None, Some(b)).unwrap().to_array(), [
    true, false, true, false,
  ])
  assert_eq(and_validity(Some(a), Some(b)).unwrap().to_array(), [
    true, false, false, false,
  ])
}

///|
fn length_text(op : String, l : Int32, r : Int32) -> String {
  binary_length(op, l, r).to_string() catch {
    e => e.to_string()
  }
}

///|
test "binary_length" {
  assert_eq(binary_length("add", 3, 3), 3)
  assert_eq(binary_length("add", 3, 1), 3)
  assert_eq(binary_length("add", 1, 3), 3)
  assert_eq(binary_length("add", 1, 1), 1)
  assert_eq(binary_length("add", 0, 1), 0)
  assert_eq(binary_length("add", 1, 0), 0)
  assert_eq(binary_length("add", 0, 0), 0)
  assert_eq(
    length_text("eq", 2, 3),
    "ShapeMismatch: cannot evaluate two Series of different lengths (2 and 3)",
  )
  assert_true(length_text("eq", 0, 2).has_prefix("ShapeMismatch"))
  assert_true(length_text("eq", 2, 0).has_prefix("ShapeMismatch"))
}

///|
test "str_cmp orders by code point" {
  assert_true(str_cmp("\u{FF61}", "\u{1F600}") < 0)
  assert_true(str_cmp("\u{1F600}", "\u{FF61}") > 0)
  assert_true(str_cmp("\u{E000}", "\u{10000}") < 0)
  assert_true(str_cmp("\u{FFFF}", "\u{10000}") < 0)
  assert_eq(str_cmp("abc", "abc"), 0)
  assert_true(str_cmp("", "a") < 0)
  assert_true(str_cmp("ab", "abc") < 0)
  assert_true(str_cmp("b", "abc") > 0)
  assert_true(str_cmp("Z", "a") < 0)
  assert_true(str_cmp("\u{1F600}a", "\u{1F600}b") < 0)
}
