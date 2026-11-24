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

///|
/// The value as a `Double` for the integer and float types (`Int32`, `Int64`,
/// `Float32`, `Float64`); `None` for `Null`, `Boolean`, `String`, `Date` and
/// `Datetime`. An `Int64` beyond 2^53 is rounded to the nearest `Double`.
///
/// ```mbt check
/// test {
///   let m = @pl.Series::int32("a", [1, 2, 4]).mean()
///   assert_eq(m.to_double(), Some(7.0 / 3.0))
///   assert_eq(@pl.AnyValue::String("x").to_double(), None)
/// }
/// ```
pub fn AnyValue::to_double(self : AnyValue) -> Double? {
  match self {
    Int32(x) => Some(x.to_double())
    Int64(x) => Some(x.to_double())
    Float32(x) => Some(x.to_double())
    Float64(x) => Some(x)
    _ => None
  }
}

///|
/// The value as an `Int64` for the integer types (`Int32`, `Int64`); `None`
/// for everything else, floats included (cast the series first to truncate).
///
/// ```mbt check
/// test {
///   let total = @pl.Series::int32("a", [1, 2, 4]).sum()
///   assert_eq(total.to_int64(), Some(7L))
///   assert_eq(@pl.AnyValue::Float64(1.0).to_int64(), None)
/// }
/// ```
pub fn AnyValue::to_int64(self : AnyValue) -> Int64? {
  match self {
    Int32(x) => Some(x.to_int64())
    Int64(x) => Some(x)
    _ => None
  }
}
