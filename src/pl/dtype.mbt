///|
/// Logical column types, named after their polars counterparts.
#derive(Eq, Hash, @debug.Debug)
pub(all) enum DataType {
  Boolean
  Int32
  Int64
  Float32
  Float64
  String
  Date
  Datetime
  Null
}

///|
/// Formats the type with its polars display name (`bool`, `i32`, `i64`,
/// `f32`, `f64`, `str`, `date`, `datetime[μs]`, `null`).
pub impl Show for DataType with fn output(self, logger) {
  logger.write_string(
    match self {
      Boolean => "bool"
      Int32 => "i32"
      Int64 => "i64"
      Float32 => "f32"
      Float64 => "f64"
      String => "str"
      Date => "date"
      Datetime => "datetime[μs]"
      Null => "null"
    },
  )
}

///|
/// Makes `to_string` callable as a method (`t.to_string()`), giving the same
/// polars display name as `Show` (`DataType::Int64.to_string()` is `"i64"`).
pub extend DataType with Show::{to_string}

///|
/// Returns `true` for `Int32`, `Int64`, `Float32` and `Float64`.
pub fn DataType::is_numeric(self : DataType) -> Bool {
  self.is_integer() || self.is_float()
}

///|
/// Returns `true` for `Int32` and `Int64`.
pub fn DataType::is_integer(self : DataType) -> Bool {
  match self {
    Int32 | Int64 => true
    _ => false
  }
}

///|
/// Returns `true` for `Float32` and `Float64`.
pub fn DataType::is_float(self : DataType) -> Bool {
  match self {
    Float32 | Float64 => true
    _ => false
  }
}

///|
/// Returns `true` for `Date` and `Datetime`.
pub fn DataType::is_temporal(self : DataType) -> Bool {
  match self {
    Date | Datetime => true
    _ => false
  }
}
