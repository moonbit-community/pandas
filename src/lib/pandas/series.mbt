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
pub impl Hash for SeriesData with hash_combine(self, hasher) {
  match self {
    SeriesData::Int(data) =>
      for value in data {
        hasher.combine(value)
      }
    SeriesData::Float(data) =>
      for value in data {
        hasher.combine(value)
      }
    SeriesData::Bool(data) =>
      for value in data {
        hasher.combine(value)
      }
    SeriesData::Str(data) =>
      for value in data {
        hasher.combine(value)
      }
  }
}

///|
pub impl Hash for Series with hash_combine(self, hasher) {
  self.name.hash_combine(hasher)
  self.data.hash_combine(hasher)
}

///| Create a new Series
///
/// ### Parameters
///
/// - `name` : The name of the Series
/// - `values` : The data contained in the Series
///
/// ### Returns
///
/// - `Series` : A new Series instance
///
/// ### Example
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

///| SeriesData clear
pub fn SeriesData::clear(self : SeriesData) -> Unit {
  match self {
    SeriesData::Int(data) => data.clear()
    SeriesData::Float(data) => data.clear()
    SeriesData::Bool(data) => data.clear()
    SeriesData::Str(data) => data.clear()
  }
}

///| Check if the SeriesData is empty
pub fn SeriesData::empty(self : SeriesData) -> Bool {
  self.length() == 0
}

///|
type! EmptyArrayError String derive(Show)

///| Erase an element from the SeriesData at a specified index
///
/// ### Parameters
///
/// - `self` : An instance of the SeriesData
/// - `index` : The index of the element to be erased
///
/// ### Errors
///
/// - `EmptyArrayError` : Raised if the SeriesData is empty
///
/// ### Example
/// ```
/// data.erase(1)
/// ```
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
  descending~ : Bool = false
) -> Array[Int] {
  let indices = Array::makei(self.length(), fn(i) { i })
  match self {
    SeriesData::Int(data) => indices.sort_by_key(fn(i) { data[i] })
    SeriesData::Float(data) => indices.sort_by_key(fn(i) { data[i] })
    SeriesData::Bool(data) => indices.sort_by_key(fn(i) { data[i] })
    SeriesData::Str(data) => indices.sort_by_key(fn(i) { data[i] })
  }
  if descending {
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
/// ### Parameters
///
/// - `self` : An instance of the SeriesData
/// - `descending~` : A boolean indicating whether to sort in descending order (default is false)
///
/// ### Returns
///
/// - `Array[Int]` : An array of indices representing the sorted order of the elements
///
/// ### Example
/// ```
/// let data = SeriesData::Int([3, 1, 2])
/// let sorted_indices = data.argsort()
/// ```
pub fn SeriesData::argsort(
  self : SeriesData,
  descending~ : Bool = false
) -> Array[Int] {
  let indices = self.get_argsort_indices(descending~)
  self.argsort_indices(indices)
  indices
}

///| Sort the SeriesData in Series and return the indices of the sorted elements
///
/// ### Parameters
///
/// - `self` : An instance of the SeriesData
/// - `descending~` : A boolean indicating whether to sort in descending order (default is false)
///
/// ### Returns
///
/// - `Array[Int]` : An array of indices representing the sorted order of the elements
///
/// ### Example
/// ```
/// let series = Series :: { name: "A", data: SeriesData::Int([3, 1, 2]) }
/// let sorted_indices = series.argsort()
/// ```
pub fn Series::argsort(self : Series, descending~ : Bool = false) -> Array[Int] {
  self.data.argsort(descending~)
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
      let res = a.copy()
      res.eachi(fn(i, v) { res[i] = v + b[i] })
      SeriesData::Int(res)
    }
    (SeriesData::Float(a), SeriesData::Float(b)) => {
      let res = a.copy()
      res.eachi(fn(i, v) { res[i] = v + b[i] })
      SeriesData::Float(res)
    }
    (SeriesData::Str(a), SeriesData::Str(b)) => SeriesData::Str(a + b)
    (SeriesData::Int(a), SeriesData::Float(b))
    | (SeriesData::Float(b), SeriesData::Int(a)) => {
      let res = b.copy()
      res.eachi(fn(i, v) { res[i] = v + a[i].to_float() })
      SeriesData::Float(res)
    }
    _ => abort("unsupported types")
  }
}

///| Series add
pub fn op_add(self : Series, other : Series) -> Series {
  Series::new(self.name(), self.data() + other.data())
}

///| SeriesData sub
pub fn op_sub(self : SeriesData, other : SeriesData) -> SeriesData {
  match (self, other) {
    (SeriesData::Int(a), SeriesData::Int(b)) => {
      let res = a.copy()
      res.eachi(fn(i, v) { res[i] = v - b[i] })
      SeriesData::Int(res)
    }
    (SeriesData::Float(a), SeriesData::Float(b)) => {
      let res = a.copy()
      res.eachi(fn(i, v) { res[i] = v - b[i] })
      SeriesData::Float(res)
    }
    (SeriesData::Int(a), SeriesData::Float(b))
    | (SeriesData::Float(b), SeriesData::Int(a)) => {
      let res = b.copy()
      res.eachi(fn(i, v) { res[i] = v - a[i].to_float() })
      SeriesData::Float(res)
    }
    _ => abort("unsupported types")
  }
}

///| 
pub fn op_get(self : Series, index : Int) -> DType {
  match self.data {
    SeriesData::Int(data) => DType::Int(data[index])
    SeriesData::Float(data) => DType::Float(data[index])
    SeriesData::Bool(data) => DType::Bool(data[index])
    SeriesData::Str(data) => DType::Str(data[index])
  }
}

///| Series sub
pub fn op_sub(self : Series, other : Series) -> Series {
  Series::new(self.name(), self.data() - other.data())
}

///| SeriesData mul
pub fn op_mul(self : SeriesData, other : SeriesData) -> SeriesData {
  match (self, other) {
    (SeriesData::Int(a), SeriesData::Int(b)) => {
      let res = a.copy()
      res.eachi(fn(i, v) { res[i] = v * b[i] })
      SeriesData::Int(res)
    }
    (SeriesData::Float(a), SeriesData::Float(b)) => {
      let res = a.copy()
      res.eachi(fn(i, v) { res[i] = v * b[i] })
      SeriesData::Float(res)
    }
    (SeriesData::Int(a), SeriesData::Float(b))
    | (SeriesData::Float(b), SeriesData::Int(a)) => {
      let res = b.copy()
      res.eachi(fn(i, v) { res[i] = v * a[i].to_float() })
      SeriesData::Float(res)
    }
    _ => abort("unsupported types")
  }
}

///| Series mul
pub fn op_mul(self : Series, other : Series) -> Series {
  Series::new(self.name(), self.data() * other.data())
}

///| SeriesData div
pub fn op_div(self : SeriesData, other : SeriesData) -> SeriesData {
  match (self, other) {
    (SeriesData::Int(a), SeriesData::Int(b)) => {
      let res = a.copy()
      res.eachi(fn(i, v) { res[i] = v / b[i] })
      SeriesData::Int(res)
    }
    (SeriesData::Float(a), SeriesData::Float(b)) => {
      let res = a.copy()
      res.eachi(fn(i, v) { res[i] = v / b[i] })
      SeriesData::Float(res)
    }
    (SeriesData::Int(a), SeriesData::Float(b))
    | (SeriesData::Float(b), SeriesData::Int(a)) => {
      let res = b.copy()
      res.eachi(fn(i, v) { res[i] = v / a[i].to_float() })
      SeriesData::Float(res)
    }
    _ => abort("unsupported types")
  }
}

///| Series div
pub fn op_div(self : Series, other : Series) -> Series {
  Series::new(self.name(), self.data() / other.data())
}

///|
pub fn merge(self : Series, other : Series) -> Series!InvalidType {
  let data = match (self.data, other.data) {
    (SeriesData::Int(a), SeriesData::Int(b)) => SeriesData::Int(a + b)
    (SeriesData::Float(a), SeriesData::Float(b)) => SeriesData::Float(a + b)
    (SeriesData::Bool(a), SeriesData::Bool(b)) => SeriesData::Bool(a + b)
    (SeriesData::Str(a), SeriesData::Str(b)) => SeriesData::Str(a + b)
    _ => raise InvalidType("unsupported types")
  }
  Series::new(self.name, data)
}

///|
fn copy(self : SeriesData) -> SeriesData {
  match self {
    SeriesData::Int(data) => SeriesData::Int(data.copy())
    SeriesData::Float(data) => SeriesData::Float(data.copy())
    SeriesData::Bool(data) => SeriesData::Bool(data.copy())
    SeriesData::Str(data) => SeriesData::Str(data.copy())
  }
}

///|
pub fn copy(self : Series) -> Series {
  Series::new(self.name(), self.data().copy())
}

///|
fn SeriesData::reverse(self : SeriesData) -> Unit {
  match self {
    SeriesData::Int(data) => data.rev_inplace()
    SeriesData::Float(data) => data.rev_inplace()
    SeriesData::Bool(data) => data.rev_inplace()
    SeriesData::Str(data) => data.rev_inplace()
  }
}

///|
pub fn Series::reverse(self : Series) -> Unit {
  self.data.reverse()
}

///|
enum BasicType {
  Int
  Float
  Bool
  Str
} derive(Eq)

///|
fn get_type(self : Series) -> BasicType {
  match self.data {
    SeriesData::Int(_) => BasicType::Int
    SeriesData::Float(_) => BasicType::Float
    SeriesData::Bool(_) => BasicType::Bool
    SeriesData::Str(_) => BasicType::Str
  }
}

///|
/// Returns the maximum value in the Series. Currently only works for Series with
/// integer values.
///
/// Parameters:
///
/// * `self` : The Series to find the maximum value from.
///
/// Returns the maximum value in the Series.
///
/// Throws:
///
/// * `EmptyArrayError` : Raised if the Series is empty
/// * `InvalidType` : Raised if the Series contains non-integer values
///
/// Example:
///
/// ```moonbit
/// let series = Series::new("test", SeriesData::Int([1, 3, 2]))
/// series.arg_max!()
/// ```
pub fn Series::arg_max(self : Series) -> Int!Error {
  match self.data {
    SeriesData::Int(data) =>
      match data {
        [] => raise EmptyArrayError("Cannot find the maximum of an empty array")
        _ => {
          let mut max = data[0]
          for value in data {
            if value > max {
              max = value
            }
          }
          max
        }
      }
    _ => raise InvalidType("unsupported type")
  }
}

///|
/// Returns the minimum value in the Series. Currently only works for Series with
/// integer values.
///
/// Parameters:
///
/// * `self` : The Series to find the minimum value from.
///
/// Returns the minimum value in the Series.
///
/// Throws:
///
/// * `EmptyArrayError` : Raised if the Series is empty
/// * `InvalidType` : Raised if the Series contains non-integer values
///
/// Example:
///
/// ```moonbit
///   let series = Series::new("test", SeriesData::Int([3, 1, 2]))
///   series.arg_min!()
/// ```
pub fn Series::arg_min(self : Series) -> Int!Error {
  match self.data {
    SeriesData::Int(data) =>
      match data {
        [] => raise EmptyArrayError("Cannot find the minimum of an empty array")
        _ => {
          let mut min = data[0]
          for value in data {
            if value < min {
              min = value
            }
          }
          min
        }
      }
    _ => raise InvalidType("unsupported type")
  }
}

///|
pub fn Series::count(self : Series) -> Int {
  self.data.length()
}

///| Tests
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
  inspect!(c, content="{name: \"a\", data: Float([5.5, 7, 9.5])}")
}

test "series_sub" {
  let a = Series::new("a", SeriesData::Float([1.5, 2, 3.5]))
  let b = Series::new("b", SeriesData::Int([4, 5, 6]))
  let c = a.data - b.data
  inspect!(c, content="Float([-2.5, -3, -2.5])")
  let c = a - b
  inspect!(c, content="{name: \"a\", data: Float([-2.5, -3, -2.5])}")
}

test "series_mul" {
  let a = Series::new("a", SeriesData::Float([1.5, 2, 3.5]))
  let b = Series::new("b", SeriesData::Int([4, 5, 6]))
  let c = a.data * b.data
  inspect!(c, content="Float([6, 10, 21])")
  let c = a * b
  inspect!(c, content="{name: \"a\", data: Float([6, 10, 21])}")
}

test "series_div" {
  let a = Series::new("a", SeriesData::Int([2, 4, 9]))
  let b = Series::new("b", SeriesData::Int([1, 2, 3]))
  let c = a.data / b.data
  inspect!(c, content="Int([2, 2, 3])")
  let c = a / b
  inspect!(c, content="{name: \"a\", data: Int([2, 2, 3])}")
}
