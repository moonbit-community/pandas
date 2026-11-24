///|
/// Whether row `i` is non-null; every row of a `Null` column is null. The
/// index must be in range.
fn Column::is_valid(self : Column, i : Int32) -> Bool {
  match self {
    Boolean(a) => a.is_valid(i)
    Int32(a) => a.is_valid(i)
    Int64(a) => a.is_valid(i)
    Float32(a) => a.is_valid(i)
    Float64(a) => a.is_valid(i)
    String(a) => a.is_valid(i)
    Date(a) => a.is_valid(i)
    Datetime(a) => a.is_valid(i)
    Null(n) => {
      if i < 0 || i >= n {
        abort("Column::is_valid: index \{i} out of range for length \{n}")
      }
      false
    }
  }
}

///|
/// The validity bitmap (`None` when the column has no null bitmap); a `Null`
/// column has an all-zero one.
fn Column::validity(self : Column) -> @arrow.Bitmap? {
  match self {
    Boolean(a) => a.validity()
    Int32(a) => a.validity()
    Int64(a) => a.validity()
    Float32(a) => a.validity()
    Float64(a) => a.validity()
    String(a) => a.validity()
    Date(a) => a.validity()
    Datetime(a) => a.validity()
    Null(n) => Some(@arrow.Bitmap::filled(n, false))
  }
}

///|
/// A column of `length` nulls of type `dtype`; `Null` gives `Null(length)`.
fn Column::full_null(dtype : DataType, length : Int32) -> Column {
  null_column(dtype, length)
}

///|
/// Repeats the only row `length` times.
///
/// # Panics
/// Aborts unless `self.length() == 1`.
fn Column::broadcast(self : Column, length : Int32) -> Column {
  if self.length() != 1 {
    abort(
      "Column::broadcast: expected a column of length 1, got \{self.length()}",
    )
  }
  if length == 1 {
    return self
  }
  self.gather(Array::make(length, 0))
}

///|
/// `self` stretched to `length` rows: unchanged when it already has that
/// length, otherwise the broadcast of its single row.
fn Column::expand(self : Column, length : Int32) -> Column {
  if self.length() == length {
    self
  } else {
    self.broadcast(length)
  }
}

///|
/// The rows where `mask` is true; a null mask row counts as false.
///
/// # Panics
/// Aborts unless the mask has the same length as the column.
fn Column::filter(self : Column, mask : @arrow.BoolArray) -> Column {
  let n = self.length()
  if mask.length() != n {
    abort(
      "Column::filter: mask length \{mask.length()} differs from column length \{n}",
    )
  }
  let keep : Array[Int32] = []
  for i in 0..<n {
    if mask.is_valid(i) && mask.value(i) {
      keep.push(i)
    }
  }
  if keep.length() == n {
    return self
  }
  self.gather(keep)
}

///|
/// The validity of an element-wise result: valid where both inputs are.
fn and_validity(a : @arrow.Bitmap?, b : @arrow.Bitmap?) -> @arrow.Bitmap? {
  match (a, b) {
    (None, None) => None
    (Some(_), None) => a
    (None, Some(_)) => b
    (Some(x), Some(y)) => Some(x.bit_and(y))
  }
}

///|
/// Length of the result of a binary operation: the common length, or the one
/// of the longer side when the other has length 1 (a scalar broadcasts, also
/// to length 0).
///
/// # Errors
/// Raises `ShapeMismatch` when the lengths differ and neither is 1. The
/// message is polars' for expressions, the same for every operator.
fn binary_length(
  op : String,
  left : Int32,
  right : Int32,
) -> Int32 raise PolarsError {
  ignore(op)
  if left == right || right == 1 {
    left
  } else if left == 1 {
    right
  } else {
    raise ShapeMismatch(
      "cannot evaluate two Series of different lengths (\{left} and \{right})",
    )
  }
}

///|
/// Casts like `Series::cast(strict=false)`: a value that does not fit
/// becomes null. This is how both sides of a binary operation reach their
/// common type.
fn Column::cast_lenient(
  self : Column,
  to : DataType,
) -> Column raise PolarsError {
  if self.dtype() == to {
    return self
  }
  Series::make("", self).cast(to, strict=false).col
}

///|
/// Maps a UTF-16 code unit so that comparing the mapped values orders
/// surrogates (code points above U+FFFF) after U+E000..U+FFFF, as the code
/// points themselves are ordered.
fn utf16_order_key(u : UInt16) -> Int32 {
  let c = u.to_int()
  if c >= 0xE000 {
    c - 0x800
  } else if c >= 0xD800 {
    c + 0x2000
  } else {
    c
  }
}

///|
/// Three-way comparison of two strings by Unicode code point (which is also
/// UTF-8 byte order, polars' order), not by UTF-16 code unit.
fn str_cmp(a : String, b : String) -> Int32 {
  let na = a.length()
  let nb = b.length()
  let n = if na < nb { na } else { nb }
  for i in 0..<n {
    let x = a.unsafe_get(i)
    let y = b.unsafe_get(i)
    if x != y {
      let kx = utf16_order_key(x)
      let ky = utf16_order_key(y)
      return if kx < ky { -1 } else { 1 }
    }
  }
  if na < nb {
    -1
  } else if na > nb {
    1
  } else {
    0
  }
}

///|
/// Applies `f` to every pair of rows (null slots included: `f` must accept any
/// value) and keeps a row valid when both inputs are.
fn[T : Default] zip_prim(
  x : @arrow.PrimArray[T],
  y : @arrow.PrimArray[T],
  f : (T, T) -> T,
) -> @arrow.PrimArray[T] {
  let n = x.length()
  let out : FixedArray[T] = FixedArray::make(n, Default::default())
  for i in 0..<n {
    out[i] = f(x.value(i), y.value(i))
  }
  @arrow.PrimArray::new(out, and_validity(x.validity(), y.validity()))
}

///|
/// Like `zip_prim`, but a row whose right operand equals `zero` is null and
/// `f` is not called for it (integer division by zero).
fn[T : Default + Eq] zip_prim_nonzero(
  x : @arrow.PrimArray[T],
  y : @arrow.PrimArray[T],
  zero : T,
  f : (T, T) -> T,
) -> @arrow.PrimArray[T] {
  let n = x.length()
  let out : FixedArray[T] = FixedArray::make(n, Default::default())
  let ok = @arrow.BitmapBuilder::new(capacity=n)
  let mut any_zero = false
  for i in 0..<n {
    let d = y.value(i)
    if d == zero {
      any_zero = true
      ok.push(false)
    } else {
      ok.push(true)
      out[i] = f(x.value(i), d)
    }
  }
  let base = and_validity(x.validity(), y.validity())
  let validity = if any_zero {
    and_validity(base, Some(ok.finish()))
  } else {
    base
  }
  @arrow.PrimArray::new(out, validity)
}
