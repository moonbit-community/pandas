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

///| Create a new Series
///
/// # Parameters
///
/// - `name` : The name of the Series
/// - `values` : The data contained in the Series
///
/// # Returns
///
/// - `Series` : A new Series instance
///
/// # Example
/// ```
/// let series = Series::new("A", SeriesData::Int([1, 2, 3]))
/// ```
pub fn Series::new(name : String, values : SeriesData) -> Series {
  Series::{ name: name.to_string(), data: values }
}

///| Get the length of the SeriesData
pub fn SeriesData::length(self : SeriesData) -> Int {
  match self {
    SeriesData::Int(data) => data.length()
    SeriesData::Float(data) => data.length()
    SeriesData::Bool(data) => data.length()
    SeriesData::Str(data) => data.length()
  }
}

///| Check if the SeriesData is empty
pub fn SeriesData::empty(self : SeriesData) -> Bool {
  self.length() == 0
}

///|
type! EmptyArrayError String derive(Show)

///| erase the element at the given index
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

///| Sort the SeriesData
pub fn SeriesData::sort(self : SeriesData) -> Unit {
  match self {
    SeriesData::Int(data) => data.sort()
    SeriesData::Float(data) => data.sort()
    SeriesData::Bool(data) => data.sort()
    SeriesData::Str(data) => data.sort()
  }
}

///| get the indices of the sorted elements
fn SeriesData::get_argsort_indices(
  self : SeriesData,
  decrease~ : Bool = false
) -> Array[Int] {
  let indices = Array::makei(self.length(), fn(i) { i })
  match self {
    SeriesData::Int(data) => indices.sort_by_key(fn(i) { data[i] })
    SeriesData::Float(data) => indices.sort_by_key(fn(i) { data[i] })
    SeriesData::Bool(data) => indices.sort_by_key(fn(i) { data[i] })
    SeriesData::Str(data) => indices.sort_by_key(fn(i) { data[i] })
  }
  if decrease {
    indices.rev_inplace()
  }
  indices
}

///| Sort the SeriesData by the indices
fn SeriesData::argsort_indices(self : SeriesData, indices : Array[Int]) -> Unit {
  match self {
    SeriesData::Int(data) => indices_sort(data, indices)
    SeriesData::Float(data) => indices_sort(data, indices)
    SeriesData::Bool(data) => indices_sort(data, indices)
    SeriesData::Str(data) => indices_sort(data, indices)
  }
}

///| Sort the SeriesData and return the indices of the sorted elements
///
/// # Parameters
///
/// - `self` : An instance of the SeriesData
/// - `decrease` : A boolean indicating whether to sort in descending order (default is false)
///
/// # Returns
///
/// - `Array[Int]` : An array of indices representing the sorted order of the elements
///
/// # Example
/// ```
/// let data = SeriesData::Int([3, 1, 2])
/// let sorted_indices = data.argsort()
/// ```
pub fn SeriesData::argsort(
  self : SeriesData,
  decrease~ : Bool = false
) -> Array[Int] {
  let indices = self.get_argsort_indices(decrease~)
  self.argsort_indices(indices)
  indices
}

///| Sort the SeriesData in Series and return the indices of the sorted elements
///
/// # Parameters
///
/// - `self` : An instance of the SeriesData
/// - `decrease` : A boolean indicating whether to sort in descending order (default is false)
///
/// # Returns
///
/// - `Array[Int]` : An array of indices representing the sorted order of the elements
///
/// # Example
/// ```
/// let series = Series :: { name: "A", data: SeriesData::Int([3, 1, 2]) }
/// let sorted_indices = series.argsort()
/// ```
pub fn Series::argsort(self : Series, decrease~ : Bool = false) -> Array[Int] {
  self.data.argsort(decrease~)
}

///|
pub fn Series::name(self : Series) -> String {
  self.name
}

///|
pub fn Series::data(self : Series) -> SeriesData {
  self.data
}

// type! TypeError String derive(Show)
///| SeriesData add
pub fn op_add(self : SeriesData, other : SeriesData) -> SeriesData {
  match (self, other) {
    (SeriesData::Int(a), SeriesData::Int(b)) => {
      let res = a
      res.eachi(fn(i, v){ res[i] = v + b[i] })
      SeriesData::Int(res)
    }
    (SeriesData::Float(a), SeriesData::Float(b)) => {
      let res = a
      res.eachi(fn(i, v){ res[i] = v + b[i] })
      SeriesData::Float(res)
    }
    (SeriesData::Str(a), SeriesData::Str(b)) => SeriesData::Str(a + b)
    (SeriesData::Int(a), SeriesData::Float(b)) | (SeriesData::Float(b), SeriesData::Int(a)) => {
      let res = b
      res.eachi(fn(i, v){ res[i] = v + a[i].to_float() })
      SeriesData::Float(res)
    }
    _ => self
  }
}

///| Series add
pub fn op_add(self : Series, other : Series) -> Series {
  Series::new(self.name(), self.data() + other.data())
}

test "series" {
  let series = Series::new("test", SeriesData::Int([1, 2, 3, 4, 5]))
  assert_eq!(series.name(), "test")
  assert_eq!(series.data(), SeriesData::Int([1, 2, 3, 4, 5]))
}

test "argsort_indices" {
  let series = Series::new("test", SeriesData::Int([2, 1, 3, 5, 4]))
  let indices = series.data.get_argsort_indices()
  inspect!(indices, content="[1, 0, 2, 4, 3]")
  let series = Series::new("test", SeriesData::Str(["a", "b", "c", "d", "e"]))
  inspect!(series.data.get_argsort_indices(), content="[0, 1, 2, 3, 4]")
}

test "argsort" {
  let series = Series::new("test", SeriesData::Int([2, 1, 3, 5, 4]))
  let indices = series.data.argsort()
  inspect!(indices, content="[1, 0, 2, 4, 3]")
}

test "series_add" {
  let a = Series::new("a", SeriesData::Float([1.5, 2, 3.5]))
  let b = Series::new("b", SeriesData::Int([4, 5, 6]))
  let c = a.data + b.data
  inspect!(c, content="Float([5.5, 7, 9.5])")
  let c = a + b
  inspect!(c, content="Series { name: \"a\", data: Float([5.5, 7, 9.5]) }")
}
