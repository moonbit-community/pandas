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

///|
test "to_double and to_int64" {
  assert_eq(@pl.AnyValue::Int32(-3).to_double(), Some(-3.0))
  assert_eq(
    @pl.AnyValue::Int64(@int64.MAX_VALUE).to_double(),
    Some(9.223372036854776e18),
  )
  assert_eq(@pl.AnyValue::Float32(0.5).to_double(), Some(0.5))
  assert_eq(@pl.AnyValue::Float64(2.5).to_double(), Some(2.5))
  assert_true(@pl.AnyValue::Float64(0.0 / 0.0).to_double().unwrap().is_nan())
  assert_eq(@pl.AnyValue::Null.to_double(), None)
  assert_eq(@pl.AnyValue::Boolean(true).to_double(), None)
  assert_eq(@pl.AnyValue::String("1").to_double(), None)
  assert_eq(@pl.AnyValue::Date(1).to_double(), None)
  assert_eq(@pl.AnyValue::Datetime(1L).to_double(), None)
  assert_eq(@pl.AnyValue::Int32(@int.MIN_VALUE).to_int64(), Some(-2147483648L))
  assert_eq(
    @pl.AnyValue::Int64(@int64.MIN_VALUE).to_int64(),
    Some(@int64.MIN_VALUE),
  )
  assert_eq(@pl.AnyValue::Float64(1.0).to_int64(), None)
  assert_eq(@pl.AnyValue::Float32(1.0).to_int64(), None)
  assert_eq(@pl.AnyValue::Null.to_int64(), None)
  assert_eq(@pl.AnyValue::Boolean(true).to_int64(), None)
  assert_eq(@pl.AnyValue::String("1").to_int64(), None)
  assert_eq(@pl.AnyValue::Date(1).to_int64(), None)
  assert_eq(@pl.AnyValue::Datetime(1L).to_int64(), None)
  // aggregation results
  let s = @pl.Series::int32("a", [1, 2, 4])
  assert_eq(s.sum().to_int64(), Some(7L))
  assert_eq(s.mean().to_double(), Some(7.0 / 3.0))
  assert_eq(@pl.Series::int32("e", []).mean().to_double(), None)
}
