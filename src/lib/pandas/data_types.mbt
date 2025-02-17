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
