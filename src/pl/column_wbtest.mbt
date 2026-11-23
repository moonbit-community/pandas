///|
fn[T] wb_raises(f : () -> T raise PolarsError) -> PolarsError? {
  try {
    ignore(f())
    None
  } catch {
    e => Some(e)
  }
}

///|
test "normalize_slice basics" {
  assert_eq(normalize_slice(5, 0, None), (0, 5))
  assert_eq(normalize_slice(5, 2, None), (2, 3))
  assert_eq(normalize_slice(5, -2, None), (3, 2))
  assert_eq(normalize_slice(5, 3, Some(100)), (3, 2))
  assert_eq(normalize_slice(5, 10, None), (5, 0))
  assert_eq(normalize_slice(5, -7, Some(3)), (0, 1))
  assert_eq(normalize_slice(5, -7, Some(2)), (0, 0))
  assert_eq(normalize_slice(5, 1, Some(-3)), (1, 0))
  assert_eq(normalize_slice(0, 0, None), (0, 0))
  assert_eq(normalize_slice(0, -3, Some(5)), (0, 0))
}

///|
test "normalize_slice extremes do not overflow" {
  let lo = @int.MIN_VALUE
  let hi = @int.MAX_VALUE
  assert_eq(normalize_slice(5, lo, Some(hi)), (0, 4))
  assert_eq(normalize_slice(5, lo, None), (0, 5))
  assert_eq(normalize_slice(5, hi, Some(hi)), (5, 0))
  assert_eq(normalize_slice(5, 1, Some(hi)), (1, 4))
  assert_eq(normalize_slice(hi, lo, Some(hi)), (0, hi - 1))
  assert_eq(normalize_slice(hi, -1, Some(hi)), (hi - 1, 1))
  assert_eq(normalize_slice(hi, hi - 1, Some(hi)), (hi - 1, 1))
}

///|
test "normalize_index" {
  assert_eq(normalize_index(3, 0), 0)
  assert_eq(normalize_index(3, 2), 2)
  assert_eq(normalize_index(3, -1), 2)
  assert_eq(normalize_index(3, -3), 0)
  assert_true(wb_raises(() => normalize_index(3, 3)) is Some(OutOfBounds(_)))
  assert_true(wb_raises(() => normalize_index(3, -4)) is Some(OutOfBounds(_)))
  assert_true(
    wb_raises(() => normalize_index(3, @int.MIN_VALUE)) is Some(OutOfBounds(_)),
  )
  assert_true(
    wb_raises(() => normalize_index(3, @int.MAX_VALUE)) is Some(OutOfBounds(_)),
  )
  assert_true(wb_raises(() => normalize_index(0, 0)) is Some(OutOfBounds(_)))
  assert_true(wb_raises(() => normalize_index(0, -1)) is Some(OutOfBounds(_)))
  match wb_raises(() => normalize_index(3, -4)) {
    Some(OutOfBounds(m)) =>
      assert_eq(m, "index -4 is out of bounds for length 3")
    _ => fail("expected OutOfBounds")
  }
}

///|
test "column basics" {
  let c = Column::Int64(@arrow.PrimArray::from_options([Some(1L), None]))
  assert_eq(c.length(), 2)
  assert_eq(c.dtype(), DataType::Int64)
  assert_eq(c.null_count(), 1)
  assert_eq(c.get(0), AnyValue::Int64(1L))
  assert_eq(c.get(1), AnyValue::Null)
  assert_eq(c.slice(1, 1).length(), 1)
  assert_eq(c.gather([1, 0, 0]).length(), 3)
  assert_true(c.equals(c.slice(0, 2)))
  assert_false(c.equals(c.slice(0, 1)))
  assert_eq(Column::Null(4).length(), 4)
  assert_eq(Column::Null(4).slice(1, 2).length(), 2)
  assert_eq(Column::Null(4).gather([0, 0]).length(), 2)
  assert_eq(Column::Null(4).null_count(), 4)
  assert_eq(Column::Null(0).dtype(), DataType::Null)
  assert_false(c.equals(Column::Null(2)))
  assert_false(Column::Null(2).equals(c))
}
