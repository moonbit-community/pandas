///|
fn type_infer(data : String) -> DataType? {
  if data.is_empty() {
    return None
  } else if data == "true" ||
    data == "false" ||
    data == "True" ||
    data == "False" {
    return Some(DataType::Bool)
  } else if data.iter().all(fn(c) { c >= '0' && c <= '9' }) {
    return Some(DataType::Int32)
  } else if data
    .iter()
    .fold(init=0, fn(cnt, c) {
      if c == '.' {
        return cnt + 1
      }
      cnt
    }) ==
    1 &&
    data.iter().all(fn(c) { (c >= '0' && c <= '9') || c == '.' }) {
    return Some(DataType::Float32)
  } else {
    return Some(DataType::String)
  }
}

///|
fn type_infer_from_array(data : Array[String]) -> DataType? {
  if data.length() == 0 {
    return None
  }
  let result = type_infer(data[0])
  for i = 1; i < data.length(); i = i + 1 {
    let current = type_infer(data[i])
    if result != current {
      return Some(DataType::String)
    }
  }
  if result == None {
    return Some(DataType::String)
  }
  result
}

///|
fn type_convert(
  data : String,
  type_? : DataType,
  null~ : Bool = false
) -> SeriesValue {
  let mut null = null
  let type_ = match type_ {
    Some(type_) => type_
    None =>
      match type_infer(data) {
        Some(type_) => type_
        None => {
          null = true
          DataType::String
        }
      }
  }
  match null {
    true => SeriesValue::Null
    false =>
      match type_ {
        DataType::Int32 => {
          let mut num : Int = 0
          for i in 0..<data.length() {
            num = num * 10 + (data[i].to_int() - '0')
          }
          SeriesValue::Int(num)
        }
        DataType::Float32 => {
          let mut dicimal = 0
          let mut num : Int64 = 0
          for i in 0..<data.length() {
            if data[i] == '.' {
              dicimal = data.length() - i - 1
            } else {
              num = num * 10 + (data[i].to_int() - '0').to_int64()
            }
          }
          let flt = num.to_float() / quick_pow(10, dicimal).to_float()
          SeriesValue::Float(flt)
        }
        DataType::String => SeriesValue::Str(data)
        DataType::Bool =>
          if data == "true" || data == "True" {
            SeriesValue::Bool(true)
          } else if data == "false" || data == "False" {
            SeriesValue::Bool(false)
          } else {
            SeriesValue::Bool(false)
          }
      }
  }
}

///|
test "type_convert" {
  inspect!(type_convert("123"), content="Int(123)")
  // inspect!(type_convert("123.45"), content="Float(123.45)")
  inspect!(type_convert("true"), content="Bool(true)")
  inspect!(type_convert("false"), content="Bool(false)")
  inspect!(type_convert("True", null=true), content="Null")
  inspect!(
    type_convert("False", type_=DataType::String),
    content="Str(\"False\")",
  )
}

///|
fn type_convert_from_array(
  data : Array[String],
  type_? : DataType
) -> Array[SeriesValue] {
  let res = Array::make(data.length(), SeriesValue::Null)
  match type_ {
    Some(type_) =>
      for i in 0..<data.length() {
        res[i] = type_convert(data[i], type_~)
      }
    None =>
      for i in 0..<data.length() {
        res[i] = type_convert(data[i])
      }
  }
  res
}

///|
test "type_infer" {
  inspect!(type_infer("123"), content="Some(Int32)")
  inspect!(type_infer("123.45"), content="Some(Float32)")
  inspect!(type_infer("true"), content="Some(Bool)")
  inspect!(type_infer("false"), content="Some(Bool)")
  inspect!(type_infer("True"), content="Some(Bool)")
  inspect!(type_infer("False"), content="Some(Bool)")
  inspect!(type_infer("hello"), content="Some(String)")
  inspect!(type_infer(""), content="None")
  inspect!(type_infer("123abc"), content="Some(String)")
  inspect!(type_infer("12.1.2"), content="Some(String)")
}
