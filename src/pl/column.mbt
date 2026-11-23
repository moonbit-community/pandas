///|
/// Type-erased storage of one column. `Null` carries only the length.
priv enum Column {
  Boolean(@arrow.BoolArray)
  Int32(@arrow.PrimArray[Int32])
  Int64(@arrow.PrimArray[Int64])
  Float32(@arrow.PrimArray[Float])
  Float64(@arrow.PrimArray[Double])
  String(@arrow.StrArray)
  Date(@arrow.PrimArray[Int32])
  Datetime(@arrow.PrimArray[Int64])
  Null(Int32)
}

///|
/// Number of rows.
fn Column::length(self : Column) -> Int32 {
  match self {
    Boolean(a) => a.length()
    Int32(a) => a.length()
    Int64(a) => a.length()
    Float32(a) => a.length()
    Float64(a) => a.length()
    String(a) => a.length()
    Date(a) => a.length()
    Datetime(a) => a.length()
    Null(n) => n
  }
}

///|
/// Logical type of the column.
fn Column::dtype(self : Column) -> DataType {
  match self {
    Boolean(_) => DataType::Boolean
    Int32(_) => DataType::Int32
    Int64(_) => DataType::Int64
    Float32(_) => DataType::Float32
    Float64(_) => DataType::Float64
    String(_) => DataType::String
    Date(_) => DataType::Date
    Datetime(_) => DataType::Datetime
    Null(_) => DataType::Null
  }
}

///|
/// Number of null rows; every row of a `Null` column is null.
fn Column::null_count(self : Column) -> Int32 {
  match self {
    Boolean(a) => a.null_count()
    Int32(a) => a.null_count()
    Int64(a) => a.null_count()
    Float32(a) => a.null_count()
    Float64(a) => a.null_count()
    String(a) => a.null_count()
    Date(a) => a.null_count()
    Datetime(a) => a.null_count()
    Null(n) => n
  }
}

///|
/// Value at row `i`. The index must already be validated (`0 <= i < length`).
fn Column::get(self : Column, i : Int32) -> AnyValue {
  match self {
    Boolean(a) =>
      match a.get(i) {
        Some(v) => AnyValue::Boolean(v)
        None => AnyValue::Null
      }
    Int32(a) =>
      match a.get(i) {
        Some(v) => AnyValue::Int32(v)
        None => AnyValue::Null
      }
    Int64(a) =>
      match a.get(i) {
        Some(v) => AnyValue::Int64(v)
        None => AnyValue::Null
      }
    Float32(a) =>
      match a.get(i) {
        Some(v) => AnyValue::Float32(v)
        None => AnyValue::Null
      }
    Float64(a) =>
      match a.get(i) {
        Some(v) => AnyValue::Float64(v)
        None => AnyValue::Null
      }
    String(a) =>
      match a.get(i) {
        Some(v) => AnyValue::String(v)
        None => AnyValue::Null
      }
    Date(a) =>
      match a.get(i) {
        Some(v) => AnyValue::Date(v)
        None => AnyValue::Null
      }
    Datetime(a) =>
      match a.get(i) {
        Some(v) => AnyValue::Datetime(v)
        None => AnyValue::Null
      }
    Null(n) => {
      if i < 0 || i >= n {
        abort("Column::get: index \{i} out of range for length \{n}")
      }
      AnyValue::Null
    }
  }
}

///|
/// Zero-copy window `[offset, offset + length)`; the range must already be
/// normalised (see `normalize_slice`).
fn Column::slice(self : Column, offset : Int32, length : Int32) -> Column {
  match self {
    Boolean(a) => Boolean(a.slice(offset, length))
    Int32(a) => Int32(a.slice(offset, length))
    Int64(a) => Int64(a.slice(offset, length))
    Float32(a) => Float32(a.slice(offset, length))
    Float64(a) => Float64(a.slice(offset, length))
    String(a) => String(a.slice(offset, length))
    Date(a) => Date(a.slice(offset, length))
    Datetime(a) => Datetime(a.slice(offset, length))
    Null(n) => {
      if offset < 0 || length < 0 || offset > n - length {
        abort("Column::slice: range out of bounds")
      }
      Null(length)
    }
  }
}

///|
/// Rows at the given indices; every index must already be normalised to
/// `0 <= i < length` (see `normalize_index`).
fn Column::gather(self : Column, indices : Array[Int32]) -> Column {
  match self {
    Boolean(a) => Boolean(a.gather(indices))
    Int32(a) => Int32(a.gather(indices))
    Int64(a) => Int64(a.gather(indices))
    Float32(a) => Float32(a.gather(indices))
    Float64(a) => Float64(a.gather(indices))
    String(a) => String(a.gather(indices))
    Date(a) => Date(a.gather(indices))
    Datetime(a) => Datetime(a.gather(indices))
    Null(n) => {
      for i in indices {
        if i < 0 || i >= n {
          abort("Column::gather: index \{i} out of range for length \{n}")
        }
      }
      Null(indices.length())
    }
  }
}

///|
/// Element-wise equality of two primitive arrays under `same`; nulls equal
/// nulls and never equal a value.
fn[T] prim_equals(
  a : @arrow.PrimArray[T],
  b : @arrow.PrimArray[T],
  same : (T, T) -> Bool,
) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    match (a.get(i), b.get(i)) {
      (None, None) => ()
      (Some(x), Some(y)) => if !same(x, y) { return false }
      _ => return false
    }
  }
  true
}

///|
/// Column equality: same type, same length, nulls equal nulls and NaN equals
/// NaN for the float types.
fn Column::equals(self : Column, other : Column) -> Bool {
  match (self, other) {
    (Boolean(a), Boolean(b)) => a == b
    (Int32(a), Int32(b)) => a == b
    (Int64(a), Int64(b)) => a == b
    (Float32(a), Float32(b)) =>
      prim_equals(a, b, (x, y) => x == y || (x != x && y != y))
    (Float64(a), Float64(b)) =>
      prim_equals(a, b, (x, y) => x == y || (x != x && y != y))
    (String(a), String(b)) => a == b
    (Date(a), Date(b)) => a == b
    (Datetime(a), Datetime(b)) => a == b
    (Null(m), Null(n)) => m == n
    _ => false
  }
}

///|
/// Resolves a polars-style `slice(offset, length)` against `len` rows and
/// returns the clamped `(start, count)`, never overflowing.
///
/// A negative `offset` counts from the end. The window is
/// `[start, start + length)` computed first and clamped to `[0, len]`
/// afterwards, so `slice(-7, length=3)` on 5 rows is the first row only. A
/// `None` length means "to the end"; a negative length is treated as 0.
fn normalize_slice(
  len : Int32,
  offset : Int32,
  length : Int32?,
) -> (Int32, Int32) {
  let n = len.to_int64()
  let start0 = if offset < 0 {
    offset.to_int64() + n
  } else {
    offset.to_int64()
  }
  // 2^33 exceeds every possible start0 + n, so it acts as "unbounded".
  let count = match length {
    None => 8589934592L
    Some(l) => if l < 0 { 0L } else { l.to_int64() }
  }
  let stop0 = start0 + count
  let start = clamp64(start0, n)
  let stop = clamp64(stop0, n)
  (start.to_int(), (stop - start).to_int())
}

///|
fn clamp64(v : Int64, hi : Int64) -> Int64 {
  if v < 0L {
    0L
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
/// Resolves a possibly negative index (negative counts from the end) against
/// `len` rows; raises `OutOfBounds` when it falls outside `[0, len)`.
fn normalize_index(len : Int32, i : Int32) -> Int32 raise PolarsError {
  let j = if i < 0 { i.to_int64() + len.to_int64() } else { i.to_int64() }
  if j < 0L || j >= len.to_int64() {
    raise OutOfBounds("index \{i} is out of bounds for length \{len}")
  }
  j.to_int()
}
