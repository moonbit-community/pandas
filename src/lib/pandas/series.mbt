///|
pub(all) enum DType {
  Int(Int)
  Float(Float)
  Bool(Bool)
  Str(String)
}

///|
pub(all) enum SeriesData {
  Int(Array[Int])
  Float(Array[Float])
  Bool(Array[Bool])
  Str(Array[String])
} derive(Show, Eq)

///|
pub(all) struct Series {
  mut name : String
  mut data : SeriesData
} derive(Show, Eq)

///|
pub fn Series::new(name : String, values : SeriesData) -> Series {
  Series::{ name: name.to_string(), data: values }
}

///|
pub fn SeriesData::length(self : SeriesData) -> Int {
  match self {
    SeriesData::Int(data) => data.length()
    SeriesData::Float(data) => data.length()
    SeriesData::Bool(data) => data.length()
    SeriesData::Str(data) => data.length()
  }
}

///|
pub fn SeriesData::erase(self : SeriesData, index : Int) -> Unit {
  match self {
    SeriesData::Int(data) => {
      let _ = data.remove(index)

    }
    SeriesData::Float(data) => {
      let _ = data.remove(index)

    }
    SeriesData::Bool(data) => {
      let _ = data.remove(index)

    }
    SeriesData::Str(data) => {
      let _ = data.remove(index)

    }
  }
}

///|
pub fn Series::name(self : Series) -> String {
  self.name
}

///|
pub fn Series::data(self : Series) -> SeriesData {
  self.data
}

test "series" {
  let series = Series::new("test", SeriesData::Int([1, 2, 3, 4, 5]))
  assert_eq!(series.name(), "test")
  assert_eq!(series.data(), SeriesData::Int([1, 2, 3, 4, 5]))
}
