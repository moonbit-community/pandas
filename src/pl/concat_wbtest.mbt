///|
test "Column::concat copies into one buffer and keeps validity" {
  let a = Column::Int64(@arrow.PrimArray::from_options([Some(1L), None]))
  let b = Column::Int64(@arrow.PrimArray::from_options([Some(3L)]))
  let c = Column::Int64(@arrow.PrimArray::from_array([4L, 5L]))
  let r = Column::concat([a, b, c])
  assert_eq(r.length(), 5)
  assert_eq(r.null_count(), 1)
  assert_eq(r.get(0), AnyValue::Int64(1L))
  assert_eq(r.get(1), AnyValue::Null)
  assert_eq(r.get(4), AnyValue::Int64(5L))
  // a single column is returned as it is
  assert_eq(Column::concat([a]).equals(a), true)
}

///|
test "Column::concat of every type" {
  let cols : Array[Column] = [
    Boolean(@arrow.BoolArray::from_options([Some(true), None])),
    Int32(@arrow.PrimArray::from_options([Some(1), None])),
    Int64(@arrow.PrimArray::from_options([Some(1L), None])),
    Float32(@arrow.PrimArray::from_options([Some(1.5), None])),
    Float64(@arrow.PrimArray::from_options([Some(1.5), None])),
    String(@arrow.StrArray::from_options([Some("a"), None])),
    Date(@arrow.PrimArray::from_options([Some(1), None])),
    Datetime(@arrow.PrimArray::from_options([Some(1L), None])),
    Null(2),
  ]
  for c in cols {
    let r = Column::concat([c, c, c.slice(0, 1)])
    assert_eq(r.length(), 5)
    assert_eq(r.dtype(), c.dtype())
    assert_eq(r.null_count(), if c.dtype() == DataType::Null { 5 } else { 2 })
    assert_eq(r.slice(2, 2).equals(c), true)
    assert_eq(r.get(4), c.get(0))
  }
}

///|
test "Column::concat of sliced columns reads only the window" {
  let a = Column::String(@arrow.StrArray::from_array(["a", "b", "c", "d"]))
  let r = Column::concat([a.slice(1, 2), a.slice(3, 1), a.slice(0, 0)])
  assert_eq(r.length(), 3)
  assert_eq(r.get(0), AnyValue::String("b"))
  assert_eq(r.get(1), AnyValue::String("c"))
  assert_eq(r.get(2), AnyValue::String("d"))
}
