///|
pub(all) enum DataType {
  Int32
  Float32
  String
  Bool
} derive(Eq, Hash, Show)

///|
pub(all) enum SeriesValue {
  Int(Int)
  Float(Float)
  Bool(Bool)
  Str(String)
  Null
} derive(Show, Eq, Compare, Hash)

///|
pub(all) enum SeriesInput {
  Int32(Array[Int])
  Float32(Array[Float])
  Bool(Array[Bool])
  Str(Array[String])
  Int32_Nullable(Array[Int?])
  Float32_Nullable(Array[Float?])
  Bool_Nullable(Array[Bool?])
  Str_Nullable(Array[String?])
}

///|
fn SeriesValue::get_type(self : SeriesValue) -> DataType {
  match self {
    SeriesValue::Int(_) => DataType::Int32
    SeriesValue::Float(_) => DataType::Float32
    SeriesValue::Bool(_) => DataType::Bool
    SeriesValue::Str(_) => DataType::String
    SeriesValue::Null => abort("SeriesValue::get_type: Null")
  }
}

///|
fn DataType::max_value(self : DataType) -> SeriesValue {
  match self {
    DataType::Int32 => SeriesValue::Int(@int.max_value)
    DataType::Float32 => SeriesValue::Float(@float.max_value)
    DataType::String => abort(@byte.max_value.to_string())
    DataType::Bool => SeriesValue::Bool(true)
  }
}

///|
fn DataType::min_value(self : DataType) -> SeriesValue {
  match self {
    DataType::Int32 => SeriesValue::Int(@int.min_value)
    DataType::Float32 => SeriesValue::Float(@float.min_value)
    DataType::String => abort("")
    DataType::Bool => SeriesValue::Bool(false)
  }
}

///|
fn SeriesValue::to_float(self : SeriesValue) -> Float {
  match self {
    SeriesValue::Int(x) => x.to_float()
    SeriesValue::Float(x) => x
    SeriesValue::Bool(x) => x.to_int().to_float()
    SeriesValue::Str(_) => abort("SeriesValue::to_float: Str")
    SeriesValue::Null => abort("SeriesValue::to_float: Null")
  }
}
