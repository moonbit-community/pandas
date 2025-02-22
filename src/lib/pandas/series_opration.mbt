fn type_check(a : DataType, b : DataType) -> Bool {
  match (a, b) {
    (DataType::Int32, DataType::Int32) |
    (DataType::Float32, DataType::Float32) |
    (DataType::Int32, DataType::Float32) |
    (DataType::Float32, DataType::Int32) |
    (DataType::String, DataType::String) |
    (DataType::Bool, DataType::Bool) => true
    _ => false
  }
}
