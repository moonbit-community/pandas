///|
/// A single dynamically typed cell value.
///
/// `Date` holds days since 1970-01-01; `Datetime` holds microseconds since
/// 1970-01-01T00:00:00 (both may be negative).
///
/// `AnyValue` derives `Eq`, which is structural: `Float64(nan) != Float64(nan)`.
/// `Series::equals` and `DataFrame::equals` instead treat NaN as equal to NaN.
#derive(Eq, @debug.Debug)
pub(all) enum AnyValue {
  Null
  Boolean(Bool)
  Int32(Int32)
  Int64(Int64)
  Float32(Float)
  Float64(Double)
  String(String)
  Date(Int32)
  Datetime(Int64)
}

///|
/// Returns the `DataType` of the value; `Null` maps to `DataType::Null`.
pub fn AnyValue::dtype(self : AnyValue) -> DataType {
  match self {
    Null => DataType::Null
    Boolean(_) => DataType::Boolean
    Int32(_) => DataType::Int32
    Int64(_) => DataType::Int64
    Float32(_) => DataType::Float32
    Float64(_) => DataType::Float64
    String(_) => DataType::String
    Date(_) => DataType::Date
    Datetime(_) => DataType::Datetime
  }
}

///|
/// Returns `true` if the value is `Null`.
pub fn AnyValue::is_null(self : AnyValue) -> Bool {
  match self {
    Null => true
    _ => false
  }
}
