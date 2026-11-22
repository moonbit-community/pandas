///|
#derive(Eq)
pub(all) struct DataFrame {
  mut data : Array[Series]
  mut shape : Array[Int32]
  index : Map[String, Int32]
}

///|
#derive(Show, Debug, Eq)
enum SeriesData {
  Int(Array[Int32])
  Float(Array[Float])
  Bool(Array[Bool])
  Str(Array[String])
}

///|
#derive(Show, Debug, Eq)
struct Series {
  mut name : String
  mut data : SeriesData
  mut data_type : DataType
  mut bitmap : BitMap
  mut length : Int32
}

///|
#derive(Eq, Hash, Show, Debug)
pub(all) enum DataType {
  Int32
  Float32
  String
  Bool
}

///|
#derive(Show, Debug, Eq, Compare, Hash)
pub(all) enum SeriesValue {
  Int(Int32)
  Float(Float)
  Bool(Bool)
  Str(String)
  Null
}

///|
pub(all) enum SeriesInput {
  Int32(Array[Int32])
  Float32(Array[Float])
  Bool(Array[Bool])
  Str(Array[String])
  Int32_Nullable(Array[Int32?])
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
    DataType::Int32 => SeriesValue::Int(@int.MAX_VALUE)
    DataType::Float32 => SeriesValue::Float(@float.max_value)
    DataType::String => abort(@byte.MAX_VALUE.to_string())
    DataType::Bool => SeriesValue::Bool(true)
  }
}

///|
fn DataType::min_value(self : DataType) -> SeriesValue {
  match self {
    DataType::Int32 => SeriesValue::Int(@int.MIN_VALUE)
    DataType::Float32 => SeriesValue::Float(@float.min_value)
    DataType::String => abort("")
    DataType::Bool => SeriesValue::Bool(false)
  }
}

///|
fn SeriesValue::to_float(self : SeriesValue) -> Float {
  match self {
    SeriesValue::Int(x) => Float::from_int(x)
    SeriesValue::Float(x) => x
    SeriesValue::Bool(x) => Float::from_int(x.to_int())
    SeriesValue::Str(_) => abort("SeriesValue::to_float: Str")
    SeriesValue::Null => abort("SeriesValue::to_float: Null")
  }
}
