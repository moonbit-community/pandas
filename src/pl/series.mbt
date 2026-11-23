///|
/// A named, typed, immutable column of values (nulls allowed).
///
/// Operations return new series; slices share storage with the original.
struct Series {
  name : String
  col : Column
}

///|
fn Series::make(name : String, col : Column) -> Series {
  { name, col, }
}

///|
/// Creates a boolean series without nulls.
pub fn Series::bool(name : String, values : Array[Bool]) -> Series {
  Series::make(name, Boolean(@arrow.BoolArray::from_array(values)))
}

///|
/// Creates a boolean series from optional values (`None` is null).
pub fn Series::bool_nullable(name : String, values : Array[Bool?]) -> Series {
  Series::make(name, Boolean(@arrow.BoolArray::from_options(values)))
}

///|
/// Creates a 32-bit integer series without nulls.
pub fn Series::int32(name : String, values : Array[Int32]) -> Series {
  Series::make(name, Int32(@arrow.PrimArray::from_array(values)))
}

///|
/// Creates a 32-bit integer series from optional values (`None` is null).
pub fn Series::int32_nullable(name : String, values : Array[Int32?]) -> Series {
  Series::make(name, Int32(@arrow.PrimArray::from_options(values)))
}

///|
/// Creates a 64-bit integer series without nulls.
pub fn Series::int64(name : String, values : Array[Int64]) -> Series {
  Series::make(name, Int64(@arrow.PrimArray::from_array(values)))
}

///|
/// Creates a 64-bit integer series from optional values (`None` is null).
pub fn Series::int64_nullable(name : String, values : Array[Int64?]) -> Series {
  Series::make(name, Int64(@arrow.PrimArray::from_options(values)))
}

///|
/// Creates a 32-bit float series without nulls.
pub fn Series::float32(name : String, values : Array[Float]) -> Series {
  Series::make(name, Float32(@arrow.PrimArray::from_array(values)))
}

///|
/// Creates a 32-bit float series from optional values (`None` is null).
pub fn Series::float32_nullable(
  name : String,
  values : Array[Float?],
) -> Series {
  Series::make(name, Float32(@arrow.PrimArray::from_options(values)))
}

///|
/// Creates a 64-bit float series without nulls.
pub fn Series::float64(name : String, values : Array[Double]) -> Series {
  Series::make(name, Float64(@arrow.PrimArray::from_array(values)))
}

///|
/// Creates a 64-bit float series from optional values (`None` is null).
pub fn Series::float64_nullable(
  name : String,
  values : Array[Double?],
) -> Series {
  Series::make(name, Float64(@arrow.PrimArray::from_options(values)))
}

///|
/// Creates a string series without nulls.
pub fn Series::str(name : String, values : Array[String]) -> Series {
  Series::make(name, String(@arrow.StrArray::from_array(values)))
}

///|
/// Creates a string series from optional values (`None` is null).
pub fn Series::str_nullable(name : String, values : Array[String?]) -> Series {
  Series::make(name, String(@arrow.StrArray::from_options(values)))
}

///|
/// Creates a date series; values are days since 1970-01-01 (may be negative).
pub fn Series::date(name : String, values : Array[Int32]) -> Series {
  Series::make(name, Date(@arrow.PrimArray::from_array(values)))
}

///|
/// Creates a date series from optional days since 1970-01-01.
pub fn Series::date_nullable(name : String, values : Array[Int32?]) -> Series {
  Series::make(name, Date(@arrow.PrimArray::from_options(values)))
}

///|
/// Creates a datetime series; values are microseconds since
/// 1970-01-01T00:00:00 (may be negative).
pub fn Series::datetime(name : String, values : Array[Int64]) -> Series {
  Series::make(name, Datetime(@arrow.PrimArray::from_array(values)))
}

///|
/// Creates a datetime series from optional microseconds since the epoch.
pub fn Series::datetime_nullable(
  name : String,
  values : Array[Int64?],
) -> Series {
  Series::make(name, Datetime(@arrow.PrimArray::from_options(values)))
}

///|
/// Creates a series of `length` nulls with the `Null` data type. A negative
/// length is treated as 0.
pub fn Series::null(name : String, length : Int32) -> Series {
  Series::make(name, Null(if length < 0 { 0 } else { length }))
}

///|
fn mismatch_at(
  name : String,
  expected : DataType,
  v : AnyValue,
  i : Int32,
) -> PolarsError {
  SchemaMismatch(
    "column \"\{name}\": expected \{expected} but found \{v.dtype()} at index \{i}",
  )
}

///|
/// Builds a series from dynamically typed values.
///
/// Without `dtype`, the type of the first non-null value is used (all nulls or
/// no values give the `Null` type). Every non-null value must have exactly the
/// target type; there is no implicit promotion.
///
/// # Errors
/// Raises `SchemaMismatch` when a value does not match the target type, or
/// when `dtype` is `Null` but a non-null value is present.
pub fn Series::from_any_values(
  name : String,
  values : Array[AnyValue],
  dtype? : DataType,
) -> Series raise PolarsError {
  let target = match dtype {
    Some(t) => t
    None => {
      let mut found = DataType::Null
      for v in values {
        if !v.is_null() {
          found = v.dtype()
          break
        }
      }
      found
    }
  }
  let n = values.length()
  match target {
    Null => {
      for i, v in values {
        if !v.is_null() {
          raise mismatch_at(name, target, v, i)
        }
      }
      Series::make(name, Null(n))
    }
    Boolean => {
      let b : @arrow.BoolBuilder = @arrow.BoolBuilder::new(capacity=n)
      for i, v in values {
        match v {
          Null => b.push_null()
          Boolean(x) => b.push(x)
          _ => raise mismatch_at(name, target, v, i)
        }
      }
      Series::make(name, Boolean(b.finish()))
    }
    Int32 => {
      let b : @arrow.PrimBuilder[Int32] = @arrow.PrimBuilder::new(capacity=n)
      for i, v in values {
        match v {
          Null => b.push_null()
          Int32(x) => b.push(x)
          _ => raise mismatch_at(name, target, v, i)
        }
      }
      Series::make(name, Int32(b.finish()))
    }
    Int64 => {
      let b : @arrow.PrimBuilder[Int64] = @arrow.PrimBuilder::new(capacity=n)
      for i, v in values {
        match v {
          Null => b.push_null()
          Int64(x) => b.push(x)
          _ => raise mismatch_at(name, target, v, i)
        }
      }
      Series::make(name, Int64(b.finish()))
    }
    Float32 => {
      let b : @arrow.PrimBuilder[Float] = @arrow.PrimBuilder::new(capacity=n)
      for i, v in values {
        match v {
          Null => b.push_null()
          Float32(x) => b.push(x)
          _ => raise mismatch_at(name, target, v, i)
        }
      }
      Series::make(name, Float32(b.finish()))
    }
    Float64 => {
      let b : @arrow.PrimBuilder[Double] = @arrow.PrimBuilder::new(capacity=n)
      for i, v in values {
        match v {
          Null => b.push_null()
          Float64(x) => b.push(x)
          _ => raise mismatch_at(name, target, v, i)
        }
      }
      Series::make(name, Float64(b.finish()))
    }
    String => {
      let b : @arrow.StrBuilder = @arrow.StrBuilder::new(capacity=n)
      for i, v in values {
        match v {
          Null => b.push_null()
          String(x) => b.push(x)
          _ => raise mismatch_at(name, target, v, i)
        }
      }
      Series::make(name, String(b.finish()))
    }
    Date => {
      let b : @arrow.PrimBuilder[Int32] = @arrow.PrimBuilder::new(capacity=n)
      for i, v in values {
        match v {
          Null => b.push_null()
          Date(x) => b.push(x)
          _ => raise mismatch_at(name, target, v, i)
        }
      }
      Series::make(name, Date(b.finish()))
    }
    Datetime => {
      let b : @arrow.PrimBuilder[Int64] = @arrow.PrimBuilder::new(capacity=n)
      for i, v in values {
        match v {
          Null => b.push_null()
          Datetime(x) => b.push(x)
          _ => raise mismatch_at(name, target, v, i)
        }
      }
      Series::make(name, Datetime(b.finish()))
    }
  }
}

///|
/// The series name.
pub fn Series::name(self : Series) -> String {
  self.name
}

///|
/// Returns a series with the same data under a new name.
pub fn Series::rename(self : Series, name : String) -> Series {
  Series::make(name, self.col)
}

///|
/// Number of rows.
pub fn Series::len(self : Series) -> Int32 {
  self.col.length()
}

///|
/// Returns `true` when the series has no rows.
pub fn Series::is_empty(self : Series) -> Bool {
  self.col.length() == 0
}

///|
/// The logical data type.
pub fn Series::dtype(self : Series) -> DataType {
  self.col.dtype()
}

///|
/// Number of null rows.
pub fn Series::null_count(self : Series) -> Int32 {
  self.col.null_count()
}

///|
/// Value at row `index`; a negative index counts from the end.
///
/// # Errors
/// Raises `OutOfBounds` unless `-len <= index < len`.
pub fn Series::get(self : Series, index : Int32) -> AnyValue raise PolarsError {
  self.col.get(normalize_index(self.col.length(), index))
}

///|
/// Rows `[offset, offset + length)`; a negative `offset` counts from the end
/// and `length` defaults to "until the end". The window is computed first and
/// clamped to the series afterwards (polars semantics), so this never fails.
/// A negative `length` gives an empty series.
pub fn Series::slice(self : Series, offset : Int32, length? : Int32) -> Series {
  let (start, count) = normalize_slice(self.col.length(), offset, length)
  Series::make(self.name, self.col.slice(start, count))
}

///|
/// The first `n` rows; a negative `n` drops the last `-n` rows instead.
/// Never fails: `n` beyond the length is clamped.
pub fn Series::head(self : Series, n~ : Int32 = 10) -> Series {
  let len = self.col.length().to_int64()
  let count = if n >= 0 {
    n.to_int64().min(len)
  } else {
    (len + n.to_int64()).max(0L)
  }
  Series::make(self.name, self.col.slice(0, count.to_int()))
}

///|
/// The last `n` rows; a negative `n` drops the first `-n` rows instead.
/// Never fails: `n` beyond the length is clamped.
pub fn Series::tail(self : Series, n~ : Int32 = 10) -> Series {
  let len = self.col.length().to_int64()
  let (start, count) = if n >= 0 {
    let c = n.to_int64().min(len)
    (len - c, c)
  } else {
    let k = (-n.to_int64()).min(len)
    (k, len - k)
  }
  Series::make(self.name, self.col.slice(start.to_int(), count.to_int()))
}

///|
/// Rows at the given indices, in order and with repeats allowed; negative
/// indices count from the end.
///
/// # Errors
/// Raises `OutOfBounds` when any index is outside `-len <= i < len`.
pub fn Series::gather(
  self : Series,
  indices : Array[Int32],
) -> Series raise PolarsError {
  let len = self.col.length()
  let norm : Array[Int32] = Array(capacity=indices.length())
  for i in indices {
    norm.push(normalize_index(len, i))
  }
  Series::make(self.name, self.col.gather(norm))
}

///|
/// All values as `AnyValue`s (`Null` for null rows).
pub fn Series::to_list(self : Series) -> Array[AnyValue] {
  let out : Array[AnyValue] = Array(capacity=self.col.length())
  for i in 0..<self.col.length() {
    out.push(self.col.get(i))
  }
  out
}

///|
fn Series::type_error(self : Series, wanted : DataType) -> PolarsError {
  SchemaMismatch(
    "column \"\{self.name}\": expected \{wanted} but the series has type \{self.col.dtype()}",
  )
}

///|
/// Values of a boolean series (`None` is null).
///
/// # Errors
/// Raises `SchemaMismatch` unless the series is `Boolean`.
pub fn Series::to_bool_array(self : Series) -> Array[Bool?] raise PolarsError {
  match self.col {
    Boolean(a) => a.to_options()
    _ => raise self.type_error(DataType::Boolean)
  }
}

///|
/// Values of an `Int32` series (`None` is null). `Date` series are not
/// accepted; use `cast`.
///
/// # Errors
/// Raises `SchemaMismatch` unless the series is `Int32`.
pub fn Series::to_int32_array(self : Series) -> Array[Int32?] raise PolarsError {
  match self.col {
    Int32(a) => a.to_options()
    _ => raise self.type_error(DataType::Int32)
  }
}

///|
/// Values of an `Int64` series (`None` is null). `Datetime` series are not
/// accepted; use `cast`.
///
/// # Errors
/// Raises `SchemaMismatch` unless the series is `Int64`.
pub fn Series::to_int64_array(self : Series) -> Array[Int64?] raise PolarsError {
  match self.col {
    Int64(a) => a.to_options()
    _ => raise self.type_error(DataType::Int64)
  }
}

///|
/// Values of a `Float32` series (`None` is null).
///
/// # Errors
/// Raises `SchemaMismatch` unless the series is `Float32`.
pub fn Series::to_float32_array(
  self : Series,
) -> Array[Float?] raise PolarsError {
  match self.col {
    Float32(a) => a.to_options()
    _ => raise self.type_error(DataType::Float32)
  }
}

///|
/// Values of a `Float64` series (`None` is null).
///
/// # Errors
/// Raises `SchemaMismatch` unless the series is `Float64`.
pub fn Series::to_float64_array(
  self : Series,
) -> Array[Double?] raise PolarsError {
  match self.col {
    Float64(a) => a.to_options()
    _ => raise self.type_error(DataType::Float64)
  }
}

///|
/// Values of a string series (`None` is null).
///
/// # Errors
/// Raises `SchemaMismatch` unless the series is `String`.
pub fn Series::to_str_array(self : Series) -> Array[String?] raise PolarsError {
  match self.col {
    String(a) => a.to_options()
    _ => raise self.type_error(DataType::String)
  }
}

///|
/// Value equality used when `check_dtypes` is off: integers compare as
/// 64-bit integers, anything involving a float compares as `Double` (NaN
/// equals NaN), null equals null, and all other type pairs differ.
fn loose_value_eq(a : AnyValue, b : AnyValue) -> Bool {
  fn as_int(v : AnyValue) -> Int64? {
    match v {
      Int32(x) => Some(x.to_int64())
      Int64(x) => Some(x)
      _ => None
    }
  }

  fn as_float(v : AnyValue) -> Double? {
    match v {
      Int32(x) => Some(x.to_double())
      Int64(x) => Some(x.to_double())
      Float32(x) => Some(x.to_double())
      Float64(x) => Some(x)
      _ => None
    }
  }

  match (a, b) {
    (Null, Null) => true
    (Null, _) | (_, Null) => false
    _ =>
      match (as_int(a), as_int(b)) {
        (Some(x), Some(y)) => x == y
        _ =>
          match (as_float(a), as_float(b)) {
            (Some(x), Some(y)) => x == y || (x != x && y != y)
            _ => a == b
          }
      }
  }
}

///|
/// Compares two series. Null equals null and NaN equals NaN.
///
/// With `check_names` (default) the names must match; with `check_dtypes`
/// (default) the types must match. When `check_dtypes` is off, values of
/// different numeric types compare by value (integers as `Int64`, any float
/// as `Double`) and an all-null series equals any all-null series.
pub fn Series::equals(
  self : Series,
  other : Series,
  check_names~ : Bool = true,
  check_dtypes~ : Bool = true,
) -> Bool {
  if check_names && self.name != other.name {
    return false
  }
  if self.col.length() != other.col.length() {
    return false
  }
  if self.col.dtype() == other.col.dtype() {
    return self.col.equals(other.col)
  }
  if check_dtypes {
    return false
  }
  for i in 0..<self.col.length() {
    if !loose_value_eq(self.col.get(i), other.col.get(i)) {
      return false
    }
  }
  true
}

///|
/// Same as `Series::equals` with default options (names and dtypes are
/// compared; null equals null, NaN equals NaN).
pub impl Eq for Series with fn equal(self, other) {
  self.equals(other)
}

///|
/// Shows the name, type and values, e.g. `("a", Int64, [Int64(1), Null])`.
pub impl Debug for Series with fn to_repr(self) {
  @debug.Repr((self.name, self.col.dtype(), self.to_list()))
}
