///|
test "any value dtype" {
  assert_eq(@pl.AnyValue::Int32(1).dtype(), @pl.DataType::Int32)
  assert_eq(@pl.AnyValue::Null.dtype(), @pl.DataType::Null)
}

///|
test "any value dtype of every variant" {
  assert_eq(@pl.AnyValue::Boolean(true).dtype(), @pl.DataType::Boolean)
  assert_eq(@pl.AnyValue::Int64(1L).dtype(), @pl.DataType::Int64)
  assert_eq(@pl.AnyValue::Float32(1.0).dtype(), @pl.DataType::Float32)
  assert_eq(@pl.AnyValue::Float64(1.0).dtype(), @pl.DataType::Float64)
  assert_eq(@pl.AnyValue::String("a").dtype(), @pl.DataType::String)
  assert_eq(@pl.AnyValue::Date(-1).dtype(), @pl.DataType::Date)
  assert_eq(@pl.AnyValue::Datetime(-1L).dtype(), @pl.DataType::Datetime)
}

///|
test "any value is_null and eq" {
  assert_true(@pl.AnyValue::Null.is_null())
  assert_false(@pl.AnyValue::Int32(0).is_null())
  assert_false(@pl.AnyValue::String("").is_null())
  assert_true(@pl.AnyValue::Null == @pl.AnyValue::Null)
  assert_true(@pl.AnyValue::Int32(1) == @pl.AnyValue::Int32(1))
  assert_true(@pl.AnyValue::Int32(1) != @pl.AnyValue::Int64(1L))
  assert_true(@pl.AnyValue::Null != @pl.AnyValue::Int32(0))
}
// 无错误路径：AnyValue 的方法均为纯函数，不会 raise。
