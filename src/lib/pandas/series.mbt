///|
pub(all) enum DType {
  Int(Int)
  Float(Float)
  Bool(Bool)
  Str(String)
} derive(Show, Eq, Compare)

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
pub fn SeriesData::empty(self : SeriesData) -> Bool {
  self.length() == 0
}

///|
type! EmptyArrayError String derive(Show)

///|
pub fn SeriesData::erase(
  self : SeriesData,
  index : Int
) -> Unit!EmptyArrayError {
  if self.empty() {
    raise EmptyArrayError("Cannot erase from an empty array")
  }
  match self {
    SeriesData::Int(data) => data.remove(index) |> ignore
    SeriesData::Float(data) => data.remove(index) |> ignore
    SeriesData::Bool(data) => data.remove(index) |> ignore
    SeriesData::Str(data) => data.remove(index) |> ignore
  }
}

///|
pub fn SeriesData::sort(self : SeriesData) -> Unit {
  match self {
    SeriesData::Int(data) => data.sort()
    SeriesData::Float(data) => data.sort()
    SeriesData::Bool(data) => data.sort()
    SeriesData::Str(data) => data.sort()
  }
}

///|
pub fn SeriesData::argsort(self: SeriesData) -> Array[Int] {
  let indices = Array::makei(self.length(), fn(i) {i})
  match self {
    SeriesData::Int(data) => indices.sort_by_key(fn(i) {data[i]})
    SeriesData::Float(data) => indices.sort_by_key(fn(i) {data[i]})
    SeriesData::Bool(data) => indices.sort_by_key(fn(i) {data[i]})
    SeriesData::Str(data) => indices.sort_by_key(fn(i) {data[i]})
  }
  indices
}

///|
pub fn Series::argsort(self : Series) -> Array[Int] {
  self.data.argsort()
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

test "argsort" {
  let series = Series::new("test", SeriesData::Int([2, 1, 3, 5, 4]))
  let indices = series.argsort()
  inspect!(indices, content="[1, 0, 2, 4, 3]")
}