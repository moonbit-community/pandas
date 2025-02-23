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
} derive(Show, Eq, Compare)

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
