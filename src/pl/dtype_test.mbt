///|
test "dtype display names" {
  inspect(@pl.DataType::Datetime, content="datetime[μs]")
  inspect(@pl.DataType::String, content="str")
  assert_true(@pl.DataType::Date.is_temporal())
  assert_false(@pl.DataType::Boolean.is_numeric())
}

///|
test "dtype all display names" {
  inspect(@pl.DataType::Boolean, content="bool")
  inspect(@pl.DataType::Int32, content="i32")
  inspect(@pl.DataType::Int64, content="i64")
  inspect(@pl.DataType::Float32, content="f32")
  inspect(@pl.DataType::Float64, content="f64")
  inspect(@pl.DataType::Date, content="date")
  inspect(@pl.DataType::Null, content="null")
}

///|
test "dtype predicates" {
  let all : Array[@pl.DataType] = [
    Boolean,
    Int32,
    Int64,
    Float32,
    Float64,
    String,
    Date,
    Datetime,
    Null,
  ]
  let numeric = [false, true, true, true, true, false, false, false, false]
  let integer = [false, true, true, false, false, false, false, false, false]
  let float = [false, false, false, true, true, false, false, false, false]
  let temporal = [false, false, false, false, false, false, true, true, false]
  for i in 0..<all.length() {
    assert_eq(all[i].is_numeric(), numeric[i])
    assert_eq(all[i].is_integer(), integer[i])
    assert_eq(all[i].is_float(), float[i])
    assert_eq(all[i].is_temporal(), temporal[i])
  }
}

///|
test "dtype eq and hash" {
  assert_true(@pl.DataType::Int32 == @pl.DataType::Int32)
  assert_true(@pl.DataType::Int32 != @pl.DataType::Int64)
  assert_eq(Hash::hash(@pl.DataType::Int32), Hash::hash(@pl.DataType::Int32))
}
// 无错误路径：DataType 的方法均为纯函数，不会 raise。

///|
test "dtype to_string method" {
  assert_eq(@pl.DataType::Int64.to_string(), "i64")
  assert_eq(@pl.DataType::Datetime.to_string(), "datetime[μs]")
  assert_eq(@pl.DataType::Null.to_string(), "null")
}
