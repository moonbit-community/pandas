pub(all) enum DataType{
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
} derive(Show, Eq, Compare)