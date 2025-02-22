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
  mut data_type : DataType
  mut bitmap : BitMap
  mut length : Int
} derive(Show, Eq)

///|
impl Hash for SeriesData with hash_combine(self, hasher) {
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
/// let series = Series::new("A", SeriesInput::Int32([1, 2, 3]))
/// ```
pub fn Series::new(name : String, values : SeriesInput) -> Series {
  let mut bit_map = emptyBitMap
  let data = match values {
    SeriesInput::Int32(data) => SeriesData::Int(data)
    SeriesInput::Float32(data) => SeriesData::Float(data)
    SeriesInput::Bool(data) => SeriesData::Bool(data)
    SeriesInput::Str(data) => SeriesData::Str(data)
    SeriesInput::Int32_Nullable(data) => {
      bit_map = BitMap::new(data~)
      SeriesData::Int(
        Array::makei(data.length(), fn(i) {
          match data[i] {
            None => 0
            Some(x) => x
          }
        }),
      )
    }
    SeriesInput::Float32_Nullable(data) => {
      bit_map = BitMap::new(data~)
      SeriesData::Float(
        Array::makei(data.length(), fn(i) {
          match data[i] {
            None => 0.0
            Some(x) => x
          }
        }),
      )
    }
    SeriesInput::Bool_Nullable(data) => {
      bit_map = BitMap::new(data~)
      SeriesData::Bool(
        Array::makei(data.length(), fn(i) {
          match data[i] {
            None => false
            Some(x) => x
          }
        }),
      )
    }
    SeriesInput::Str_Nullable(data) => {
      bit_map = BitMap::new(data~)
      SeriesData::Str(
        Array::makei(data.length(), fn(i) {
          match data[i] {
            None => ""
            Some(x) => x
          }
        }),
      )
    }
  }
  Series::{
    name: name.to_string(),
    data,
    data_type: get_dtype(data),
    bitmap: bit_map,
    length: data.length(),
  }
}

///| 内部保证无null时使用
fn Series::new_by_SeriesData(name : String, data : SeriesData) -> Series {
  Series::{
    name,
    data,
    data_type: get_dtype(data),
    bitmap: emptyBitMap,
    length: data.length(),
  }
}

///|
fn get_dtype(data : SeriesData) -> DataType {
  match data {
    SeriesData::Int(_) => DataType::Int32
    SeriesData::Float(_) => DataType::Float32
    SeriesData::Bool(_) => DataType::Bool
    SeriesData::Str(_) => DataType::String
  }
}

///| Get the length of the SeriesData
fn SeriesData::length(self : SeriesData) -> Int {
  match self {
    SeriesData::Int(data) => data.length()
    SeriesData::Float(data) => data.length()
    SeriesData::Bool(data) => data.length()
    SeriesData::Str(data) => data.length()
  }
}

///|
pub fn Series::length(self : Series) -> Int {
  self.length
}

///| SeriesData clear
fn SeriesData::clear(self : SeriesData) -> Unit {
  match self {
    SeriesData::Int(data) => data.clear()
    SeriesData::Float(data) => data.clear()
    SeriesData::Bool(data) => data.clear()
    SeriesData::Str(data) => data.clear()
  }
}

///| Series clear
pub fn Series::clear(self : Series) -> Unit {
  self.name = ""
  self.length = 0
  self.data.clear()
  self.bitmap.clear()
}

///| Check if the SeriesData is empty
fn SeriesData::empty(self : SeriesData) -> Bool {
  self.length() == 0
}

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
fn SeriesData::erase(self : SeriesData, index : Int) -> Unit!EmptyArrayError {
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

///| Erase an element from the Series at a specified index
///
/// ### Parameters
///
/// - `self` : An instance of the Series
/// - `index` : The index of the element to be erased
///
/// ### Errors
///
/// - `IndexOutOfBounds` : index is out of bounds
/// - `EmptyArrayError` : Series is empty
///
/// ### Example
/// ```
/// series.erase!(1)
/// ```
pub fn Series::erase(self : Series, index : Int) -> Unit! {
  guard index >= 0 && index < self.length() else {
    raise IndexOutOfBounds("Index out of bounds")
  }
  self.data.erase!(index)
  self.length -= 1
  // compute bitmap
  self.bitmap.erase(index)
}

///| Sort the SeriesData
/// cause when build Series use SeriesInput instead of SeriesData, SeriesData become to inner type
fn SeriesData::sort(self : SeriesData) -> Unit {
  match self {
    SeriesData::Int(data) => data.sort()
    SeriesData::Float(data) => data.sort()
    SeriesData::Bool(data) => data.sort()
    SeriesData::Str(data) => data.sort()
  }
}

///|
fn SeriesData::op_get(self : SeriesData, index : Int) -> SeriesValue {
  match self {
    SeriesData::Int(data) => SeriesValue::Int(data[index])
    SeriesData::Float(data) => SeriesValue::Float(data[index])
    SeriesData::Bool(data) => SeriesValue::Bool(data[index])
    SeriesData::Str(data) => SeriesValue::Str(data[index])
  }
}

///|
fn SeriesData::op_set(
  self : SeriesData,
  index : Int,
  value : SeriesValue
) -> Unit {
  match (self, value) {
    (SeriesData::Int(data), SeriesValue::Int(v)) => data[index] = v
    (SeriesData::Float(data), SeriesValue::Float(v)) => data[index] = v
    (SeriesData::Bool(data), SeriesValue::Bool(v)) => data[index] = v
    (SeriesData::Str(data), SeriesValue::Str(v)) => data[index] = v
    _ => abort("unsupported types")
  }
}

///|
fn SeriesData::swap(self : SeriesData, i : Int, j : Int) -> Unit {
  let tmp = self[i]
  self[i] = self[j]
  self[j] = tmp
}

///|
fn SeriesData::split_at(
  self : SeriesData,
  index : Int
) -> (SeriesData, SeriesData) {
  match self {
    SeriesData::Int(data) => {
      let (a, b) = data.split_at(index)
      (SeriesData::Int(a), SeriesData::Int(b))
    }
    SeriesData::Float(data) => {
      let (a, b) = data.split_at(index)
      (SeriesData::Float(a), SeriesData::Float(b))
    }
    SeriesData::Bool(data) => {
      let (a, b) = data.split_at(index)
      (SeriesData::Bool(a), SeriesData::Bool(b))
    }
    SeriesData::Str(data) => {
      let (a, b) = data.split_at(index)
      (SeriesData::Str(a), SeriesData::Str(b))
    }
  }
}

///| Sort the Series
///
/// Parameters
///
/// - `self` : An instance of the Series
///
/// Example
/// ```
/// let series = Series::new("test", SeriesInput::Int32([2, 1, 3]))
/// series.sort()
/// inspect!(series.data, content="Int([1, 2, 3])")
/// let series = Series::new("test", SeriesInput::Int32_Nullable([Some(2), None, Some(3)]))
/// series.sort()
/// inspect!(series.data, content="Int([0, 2, 3])")
/// ```
pub fn Series::sort(self : Series) -> Unit {
  match self.bitmap.optional {
    false => self.data.sort()
    true => {
      // 没有自定义排序
      let mut l = 0
      for i in 0..<self.length {
        while l < self.length && self.bitmap[l] {
          l += 1
        }
        if self.bitmap[i] && i > l {
          self.data.swap(i, l)
          self.bitmap.swap(i, l)
          l += 1
        }
      }
      self.data.split_at(l).1.sort()
    }
  }
}

///| Get the indices that would sort the SeriesData
///
/// Parameters
///
/// - `self` : An instance of the SeriesData
/// - `descending` : A boolean indicating whether to sort in descending order (default is false)
///
/// Returns
///
/// - `Array[Int]` : An array of indices representing the sorted order of the elements
///
/// Example
/// ```
/// let data = SeriesData::Int([3, 1, 2])
/// let sorted_indices = data.get_argsort_indices()
/// inspect!(sorted_indices, content="[2, 0, 1]")
/// let sorted_indices_desc = data.get_argsort_indices(descending=true)
/// inspect!(sorted_indices_desc, content="[0, 2, 1]")
/// ```
pub fn SeriesData::get_argsort_indices(
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
fn SeriesData::argsort(
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
  let indices = self.data.argsort(descending~)
  self.data.argsort_indices(indices)
  indices
}

///|
pub fn Series::name(self : Series) -> String {
  self.name
}

///|
pub fn Series::data(self : Series) -> SeriesData {
  self.data
}

fn SeriesData::get_type(self : SeriesData) -> DataType {
  match self {
    SeriesData::Int(_) => DataType::Int32
    SeriesData::Float(_) => DataType::Float32
    SeriesData::Bool(_) => DataType::Bool
    SeriesData::Str(_) => DataType::String
  }
}

///| SeriesData add
fn op_add(self : SeriesData, other : SeriesData) -> SeriesData {
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
pub fn Series::op_add(self : Series, other : Series) -> Series {
  Series::{
    name: self.name(),
    data: self.data() + other.data(),
    data_type: get_dtype(self.data()),
    bitmap: self.bitmap + other.bitmap,
    length: self.length(),
  }
}

///| SeriesData sub
fn op_sub(self : SeriesData, other : SeriesData) -> SeriesData {
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
pub fn Series::op_get(self : Series, index : Int) -> SeriesValue {
  match self.data {
    SeriesData::Int(data) => SeriesValue::Int(data[index])
    SeriesData::Float(data) => SeriesValue::Float(data[index])
    SeriesData::Bool(data) => SeriesValue::Bool(data[index])
    SeriesData::Str(data) => SeriesValue::Str(data[index])
  }
}

///| Series sub
pub fn Series::op_sub(self : Series, other : Series) -> Series {
  Series::{
    name: self.name(),
    data: self.data() - other.data(),
    data_type: get_dtype(self.data()),
    bitmap: self.bitmap + other.bitmap,
    length: self.length(),
  }
}

///| SeriesData mul
fn SeriesData::op_mul(self : SeriesData, other : SeriesData) -> SeriesData {
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
pub fn Series::op_mul(self : Series, other : Series) -> Series {
  Series::{
    name: self.name(),
    data: self.data() * other.data(),
    data_type: get_dtype(self.data()),
    bitmap: self.bitmap + other.bitmap,
    length: self.length(),
  }
}

///| SeriesData div
fn SeriesData::op_div(self : SeriesData, other : SeriesData) -> SeriesData {
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
pub fn Series::op_div(self : Series, other : Series) -> Series {
  Series::{
    name: self.name(),
    data: self.data() / other.data(),
    data_type: get_dtype(self.data()),
    bitmap: self.bitmap + other.bitmap,
    length: self.length(),
  }
}

///|
pub fn merge(self : Series, other : Series) -> Series!InvalidType {
  let data = match (self.data, other.data) {
    (SeriesData::Int(a), SeriesData::Int(b)) => SeriesData::Int(a + b)
    (SeriesData::Float(a), SeriesData::Float(b)) => SeriesData::Float(a + b)
    (SeriesData::Bool(a), SeriesData::Bool(b)) => SeriesData::Bool(a + b)
    (SeriesData::Str(a), SeriesData::Str(b)) => SeriesData::Str(a + b)
    _ => raise InvalidType("merger must be the same type")
  }
  let bitmap = BitMap::{
    optional: self.bitmap.optional || other.bitmap.optional,
    bitmap: self.bitmap.bitmap + other.bitmap.bitmap,
    length: self.length() + other.length(),
    offset: 0,
  }
  Series::{
    name: self.name(),
    data: data,
    data_type: get_dtype(data),
    bitmap: bitmap,
    length: self.length() + other.length(),
  }
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
pub fn Series::copy(self : Series) -> Series {
  Series::{
    name: self.name(),
    data: self.data.copy(),
    data_type: self.data_type,
    bitmap: self.bitmap.copy(),
    length: self.length(),
  }
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
  self.bitmap.reverse()
}

///|
fn DataType::to_string(self : DataType) -> String {
  match self {
    DataType::Int32 => "int32"
    DataType::Float32 => "float32"
    DataType::Bool => "bool"
    DataType::String => "string"
  }
}

///|
pub fn get_type(self : Series) -> DataType {
  match self.data {
    SeriesData::Int(_) => DataType::Int32
    SeriesData::Float(_) => DataType::Float32
    SeriesData::Bool(_) => DataType::Bool
    SeriesData::Str(_) => DataType::String
  }
}

///|
/// Returns the maximum value in the Series.
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
/// ```
/// let series = Series::new("test", SeriesInput::Int32([1, 3, 2]))
/// inspect!(series.max!(), content="Int(3)")
/// ```
pub fn Series::max(self : Series) -> SeriesValue!Error {
  if self.data.empty() {
    raise EmptyArrayError("Cannot find the maximum of an empty array")
  }
  match self.data {
    SeriesData::Int(data) =>
      data.foldi(init=SeriesValue::Null, fn(i, acc, x) { if (acc == SeriesValue::Null || SeriesValue::Int(x) > acc) && not(self.bitmap[i]) { SeriesValue::Int(x) } else { acc } })
    SeriesData::Float(data) =>
      data.foldi(init=SeriesValue::Null, fn(i, acc, x) { if (acc == SeriesValue::Null || SeriesValue::Float(x) > acc) && not(self.bitmap[i]) { SeriesValue::Float(x) } else { acc } })
    SeriesData::Bool(data) =>
      data.foldi(init=SeriesValue::Null, fn(i, acc, x) { if (acc == SeriesValue::Null || SeriesValue::Bool(x) > acc) && not(self.bitmap[i]) { SeriesValue::Bool(x) } else { acc } })
    SeriesData::Str(data) =>
      data.foldi(init=SeriesValue::Null, fn(i, acc, x) { if (acc == SeriesValue::Null || SeriesValue::Str(x) > acc) && not(self.bitmap[i]) { SeriesValue::Str(x) } else { acc } })
  }
}

///|
/// Returns the minimum value in the Series
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
pub fn Series::min(self : Series) -> SeriesValue!Error {
  if self.data.empty() {
    raise EmptyArrayError("Cannot find the minimum of an empty array")
  }
  match self.data {
    SeriesData::Int(data) =>
      data.foldi(init=SeriesValue::Null, fn(i, acc, x) { if (acc == SeriesValue::Null || SeriesValue::Int(x) < acc) && not(self.bitmap[i]) { SeriesValue::Int(x) } else { acc } })
    SeriesData::Float(data) =>
      data.foldi(init=SeriesValue::Null, fn(i, acc, x) { if (acc == SeriesValue::Null || SeriesValue::Float(x) < acc) && not(self.bitmap[i]) { SeriesValue::Float(x) } else { acc } })
    SeriesData::Bool(data) =>
      data.foldi(init=SeriesValue::Null, fn(i, acc, x) { if (acc == SeriesValue::Null || SeriesValue::Bool(x) < acc) && not(self.bitmap[i]) { SeriesValue::Bool(x) } else { acc } })
    SeriesData::Str(data) =>
      data.foldi(init=SeriesValue::Null, fn(i, acc, x) { if (acc == SeriesValue::Null || SeriesValue::Str(x) < acc) && not(self.bitmap[i]) { SeriesValue::Str(x) } else { acc } })
  }
}

///| Calculate the sum of the Series
///
/// ### Parameters
///
/// - `self` : An instance of the Series
///
/// ### Returns
///
/// - `SeriesValue` : The sum of the Series
///
/// ### Errors
///
/// - `InvalidType` : Raised if the Series data type is not supported
///
/// ### Example
/// ```
/// let sum = series.sum()
/// ```
pub fn Series::sum(self : Series) -> SeriesValue!InvalidType {
  match self.data {
    SeriesData::Int(data) =>
      match data {
        _ => SeriesValue::Int(data.foldi(init=0, fn(i, acc, x) { 
          if not(self.bitmap[i]) { acc + x } else { acc }
      }))
      }
    SeriesData::Float(data) =>
      match data {
        _ =>
          SeriesValue::Float(data.foldi(init=0.0, fn(i, acc, x) {
            if not(self.bitmap[i]) { acc + x } else { acc }
          }))
      }
    _ => raise InvalidType("unsupported type")
  }
}

///|
/// Calculates the arithmetic mean of all elements in the Series.
///
/// Parameters:
///
/// * `self` : The Series to calculate the mean from.
///
/// Returns a floating-point number representing the arithmetic mean of the
/// Series.
///
/// Throws:
///
/// * `EmptyArrayError` : Raised if the Series is empty
/// * `InvalidType` : Raised if the Series contains data types that don't support
/// mean calculation (e.g., Boolean or String)
///
/// Example:
///
/// ```moonbit
/// let series = Series::new("test", SeriesData::Int([1, 2, 3, 4, 5]))
/// series.mean!()
/// let float_series = Series::new("test", SeriesData::Float([1.5, 2.5, 3.5]))
/// float_series.mean!()
/// ```
pub fn Series::mean(self : Series) -> Float!Error {
  match self.data {
    SeriesData::Int(data) =>
      match data {
        [] => raise EmptyArrayError("Cannot find the mean of an empty array")
        _ => {
          let mut cnt = 0
          let sum = data.foldi(init=0, fn(i, acc, x) { 
            if not(self.bitmap[i]) { cnt += 1; acc + x } else { acc }
           })
          sum.to_float() / cnt.to_float()
        }
      }
    SeriesData::Float(data) =>
      match data {
        [] => raise EmptyArrayError("Cannot find the mean of an empty array")
        _ => {
          let mut cnt = 0
          let sum = data.foldi(init=(0.0 : Float), fn(i, acc, x) {
            if not(self.bitmap[i]) { cnt += 1; acc + x } else { acc }
          })
          sum / cnt.to_float()
        }
      }
    _ => raise InvalidType("unsupported type")
  }
}

///|
/// Calculates the variance of a Series using ddof (delta degrees of freedom) for
/// unbiased estimation.
///
/// Parameters:
///
/// * `self` : The Series to calculate variance from. Supports numeric types
/// (Int, Float) and Bool values.
/// * `ddof` : Delta degrees of freedom (default is 1). The divisor used in
/// calculations is `n - ddof`, where n is the number of elements.
///
/// Returns a floating-point number representing the variance of the Series.
///
/// Throws:
///
/// * `EmptyArrayError` : If there are not enough observations for the specified
/// ddof value
/// * `InvalidType` : If the Series contains unsupported data types (e.g.,
/// String)
///
/// Example:
///
/// ```moonbit
/// test "Series::var" {
///   let series = Series::new("test", SeriesData::Int([1, 2, 3, 4, 5]))
///   series.var!()
///   let bool_series = Series::new("test", SeriesData::Bool([true, false, true]))
///   series.var!()
/// }
/// ```
pub fn Series::var(self : Series, ddof~ : Int = 1) -> Float! {
  let raw_float_data : Array[Float] = match self.data {
    SeriesData::Int(arr) => arr.map(fn(x) { x.to_float() })
    SeriesData::Float(arr) => arr
    SeriesData::Bool(arr) => arr.map(fn(x) { if x { 1.0 } else { 0.0 } })
    _ => raise InvalidType("unsupported type")
  }
  // have no filteri, use loop instead
  let float_data : Array[Float] = []
  for i in 0..<raw_float_data.length() {
    if not(self.bitmap[i]) {
      float_data.push(raw_float_data[i])
    }
  }
  let n = float_data.length()
  if n <= ddof {
    raise EmptyArrayError("Not enough observations for specified ddof")
  }
  let mean = float_data
    .iter()
    .fold(init=Double::to_float(0.0), fn(acc, x) { acc + x }) /
    n.to_float()
  let sum_squared_diff = float_data
    .iter()
    .fold(init=Double::to_float(0.0), fn(acc, x) {
      let diff = x - mean
      acc + diff * diff
    })
  sum_squared_diff / (n - ddof).to_float()
}

///|
pub fn Series::count(self : Series) -> Int {
  self.length
}

///|
fn SeriesData::min(self : SeriesData, other : SeriesData) -> Unit {
  match (self, other) {
    (SeriesData::Int(a), SeriesData::Int(b)) =>
      a.eachi(fn(i, v) { a[i] = @math.minimum(v, b[i]) })
    (SeriesData::Float(a), SeriesData::Float(b)) =>
      a.eachi(fn(i, v) { a[i] = @math.minimum(v, b[i]) })
    (SeriesData::Float(a), SeriesData::Int(b))
    | (SeriesData::Int(b), SeriesData::Float(a)) =>
      a.eachi(fn(i, v) { a[i] = @math.minimum(v, b[i].to_float()) })
    _ => abort("unsupported types")
  }
}

///|
fn SeriesData::max(self : SeriesData, other : SeriesData) -> Unit {
  match (self, other) {
    (SeriesData::Int(a), SeriesData::Int(b)) =>
      a.eachi(fn(i, v) { a[i] = @math.maximum(v, b[i]) })
    (SeriesData::Float(a), SeriesData::Float(b)) =>
      a.eachi(fn(i, v) { a[i] = @math.maximum(v, b[i]) })
    (SeriesData::Float(a), SeriesData::Int(b))
    | (SeriesData::Int(b), SeriesData::Float(a)) =>
      a.eachi(fn(i, v) { a[i] = @math.maximum(v, b[i].to_float()) })
    _ => abort("unsupported types")
  }
}

///|
impl Compare for SeriesData with compare(self, other) -> Int {
  match (self, other) {
    (SeriesData::Int(a), SeriesData::Int(b)) => a.compare(b)
    (SeriesData::Float(a), SeriesData::Float(b)) => a.compare(b)
    (SeriesData::Bool(a), SeriesData::Bool(b)) => a.compare(b)
    (SeriesData::Str(a), SeriesData::Str(b)) => a.compare(b)
    _ => abort("unsupported types")
  }
}

///| Check if all elements in the Series are true
///
/// Parameters
///
/// - `self` : An instance of the Series
///
/// Returns
///
/// - `Bool` : True if all elements are true, otherwise false
///
/// Errors
///
/// - `InvalidType` : Raised if the Series data type is not Bool
///
/// Example
/// ```
/// test {
///   let series = Series::new("test", SeriesData::Bool([true, true, true]))
///   let result = series.all()
///   assert_eq!(result, true)
/// }
/// ```
pub fn Series::all(self : Series) -> Bool!InvalidType {
  match self.data {
    SeriesData::Bool(data) =>
      match self.bitmap.optional {
        false => data.iter().all(fn(x) { x })
        true =>
          data.foldi(init=true, fn(i, acc, x) {
            match self.bitmap[i] {
              true => acc && x
              false => acc
            }
          })
      }
    _ => raise InvalidType("unsupported type")
  }
}

test "Series::all" {
  let series = Series::new("test", SeriesInput::Bool([true, false, true]))
  inspect!(series.all!(), content="false")
  let series = Series::new("test", SeriesInput::Bool([true, true, true]))
  inspect!(series.all!(), content="true")
}

///| Check if any element in the Series is true
///
/// Parameters
///
/// - `self` : An instance of the Series
///
/// Returns
///
/// - `Bool` : True if any element is true, otherwise false
///
/// Errors
///
/// - `InvalidType` : Raised if the Series data type is not Bool
///
/// Example
/// ```moonbit
/// let series = Series::new("test", SeriesData::Bool([true, false, true]))
/// inspect!(series.any!(), content="true")
/// let series = Series::new("test", SeriesData::Bool([false, false, false]))
/// inspect!(series.any!(), content="false")
/// ```
pub fn Series::any(self : Series) -> Bool!InvalidType {
  match self.data {
    SeriesData::Bool(data) =>
      // data.iter().any(fn(x) { x })
      match self.bitmap.optional {
        false => data.iter().any(fn(x) { x })
        true =>
          data.foldi(init=false, fn(i, acc, x) {
            match self.bitmap[i] {
              true => acc || x
              false => acc
            }
          })
      }
    _ => raise InvalidType("unsupported type")
  }
}

test "Series::any" {
  let series = Series::new("test", SeriesInput::Bool([true, false, true]))
  inspect!(series.any!(), content="true")
  let series = Series::new("test", SeriesInput::Bool([false, false, false]))
  inspect!(series.any!(), content="false")
}

///| Negate all boolean values in the Series
///
/// Parameters
///
/// - `self` : An instance of the Series
///
/// Returns
///
/// - `Series` : A new Series with all boolean values negated
///
/// Example
/// ```moonbit
/// let series = Series::new("test", SeriesData::Bool([true, false, true]))
/// inspect!(series.not_().data.to_string(), content="Bool([false, true, false])")
/// let series = Series::new("test", SeriesData::Bool([true, false, true]))
/// inspect!(series.not_().data.to_string(), content="Bool([false, true, false])")
/// ```
pub fn Series::not_(self : Series) -> Series {
  match self.data {
    SeriesData::Bool(data) =>
      // bitmap will not change
      // Series::new_by_SeriesData(self.name(), SeriesData::Bool(data.map(fn(x) { not(x) })))
      match self.bitmap.optional {
        false =>
          Series::new_by_SeriesData(
            self.name(),
            SeriesData::Bool(data.map(fn(x) { not(x) })),
          )
        true =>
          Series::new_by_SeriesData(
            self.name(),
            SeriesData::Bool(
              data.mapi(fn(i, x) {
                match self.bitmap[i] {
                  true => x
                  false => not(x)
                }
              }),
            ),
          )
      }
    _ => abort("unsupported type")
  }
}

test "Series::not_" {
  let series = Series::new("test", SeriesInput::Bool([true, false, true]))
  inspect!(series.not_().data.to_string(), content="Bool([false, true, false])")
  let series = Series::new("test", SeriesInput::Bool([true, false, true]))
  inspect!(series.not_().data.to_string(), content="Bool([false, true, false])")
}

///|
pub fn Series::has_null(self : Series) -> Bool {
  match self.bitmap.optional {
    false => false
    true => self.bitmap.bitmap.iter().any(fn(x) { x })
  }
}
