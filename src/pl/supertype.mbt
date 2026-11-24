///|
/// The type both operands of a binary operation are cast to (polars'
/// supertype, restricted to this library's nine types); `None` when the pair
/// has no common type.
///
/// - Equal types give themselves; `Null` gives the other type.
/// - `Boolean` is a number next to a number (`Int32`, `Int64`, `Float32`,
///   `Float64`) and text next to `String`; it has no common type with `Date`
///   or `Datetime`.
/// - `Int32` with `Int64` is `Int64`; `Float32` with `Float32` is `Float32`;
///   every other pair of numbers is `Float64` (so `Float32` with `Int32` or
///   `Int64` is `Float64`).
/// - A `Date` is its day count next to an integer (`Int32` with `Int32`,
///   `Int64` with `Int64`) and next to `Float32` (`Float32`) or `Float64`
///   (`Float64`); with `Datetime` it is `Datetime`. A `Datetime` is its
///   microseconds next to an integer (`Int64`) or a float (`Float64`).
/// - `String` has a common type with `Boolean`, `Date` and `Datetime` (the
///   other side is read as text), but not with a number: polars would say
///   `String` there too, yet it rejects both comparison and arithmetic, so
///   the pair is `None` here.
fn supertype(a : DataType, b : DataType) -> DataType? {
  if a == b {
    return Some(a)
  }
  match (a, b) {
    (Null, t) | (t, Null) => Some(t)
    (Boolean, t) | (t, Boolean) =>
      match t {
        Int32 | Int64 | Float32 | Float64 | String => Some(t)
        _ => None
      }
    (String, t) | (t, String) =>
      match t {
        Date | Datetime => Some(String)
        _ => None
      }
    (Int32, Int64) | (Int64, Int32) => Some(Int64)
    (Float32, Float64) | (Float64, Float32) => Some(Float64)
    (Int32, Float32) | (Float32, Int32) | (Int64, Float32) | (Float32, Int64) =>
      Some(Float64)
    (Int32, Float64) | (Float64, Int32) | (Int64, Float64) | (Float64, Int64) =>
      Some(Float64)
    (Date, Datetime) | (Datetime, Date) => Some(Datetime)
    (Date, Int32) | (Int32, Date) => Some(Int32)
    (Date, Int64) | (Int64, Date) => Some(Int64)
    (Date, Float32) | (Float32, Date) => Some(Float32)
    (Date, Float64) | (Float64, Date) => Some(Float64)
    (Datetime, Int32) | (Int32, Datetime) => Some(Int64)
    (Datetime, Int64) | (Int64, Datetime) => Some(Int64)
    (Datetime, Float32) | (Float32, Datetime) => Some(Float64)
    (Datetime, Float64) | (Float64, Datetime) => Some(Float64)
    _ => None
  }
}

///|
/// polars' debug name of a type, as it appears in some error messages
/// (`Boolean`, `Datetime('μs')`).
fn polars_type_name(t : DataType) -> String {
  match t {
    Boolean => "Boolean"
    Int32 => "Int32"
    Int64 => "Int64"
    Float32 => "Float32"
    Float64 => "Float64"
    String => "String"
    Date => "Date"
    Datetime => "Datetime('\u{3bc}s')"
    Null => "Null"
  }
}
