///|
priv enum ArithOp {
  Add
  Sub
  Mul
  Div
  FloorDiv
  Rem
}

///|
/// Name used in error messages (polars' names for the operators).
fn ArithOp::name(self : ArithOp) -> String {
  match self {
    Add => "add"
    Sub => "sub"
    Mul => "mul"
    Div => "div"
    FloorDiv => "floor_div"
    Rem => "rem"
  }
}

///|
/// Arithmetic is defined for the four number types and `Null` only.
fn arith_operand_ok(t : DataType) -> Bool {
  match t {
    Int32 | Int64 | Float32 | Float64 | Null => true
    _ => false
  }
}

///|
/// Floor division of integers; the divisor is not 0. `MIN / -1` wraps (a plain
/// `/` would trap on some backends).
fn int32_floor_div(x : Int32, y : Int32) -> Int32 {
  if y == -1 {
    return 0 - x
  }
  let q = x / y
  if x % y != 0 && (x < 0) != (y < 0) {
    q - 1
  } else {
    q
  }
}

///|
/// Remainder with the sign of the divisor; the divisor is not 0.
fn int32_rem(x : Int32, y : Int32) -> Int32 {
  if y == -1 {
    return 0
  }
  let r = x % y
  if r != 0 && (r < 0) != (y < 0) {
    r + y
  } else {
    r
  }
}

///|
fn int64_floor_div(x : Int64, y : Int64) -> Int64 {
  if y == -1L {
    return 0L - x
  }
  let q = x / y
  if x % y != 0L && (x < 0L) != (y < 0L) {
    q - 1L
  } else {
    q
  }
}

///|
fn int64_rem(x : Int64, y : Int64) -> Int64 {
  if y == -1L {
    return 0L
  }
  let r = x % y
  if r != 0L && (r < 0L) != (y < 0L) {
    r + y
  } else {
    r
  }
}

///|
fn arith_int32(
  op : ArithOp,
  x : @arrow.PrimArray[Int32],
  y : @arrow.PrimArray[Int32],
) -> @arrow.PrimArray[Int32] {
  match op {
    Add => zip_prim(x, y, (a, b) => a + b)
    Sub => zip_prim(x, y, (a, b) => a - b)
    Mul => zip_prim(x, y, (a, b) => a * b)
    FloorDiv => zip_prim_nonzero(x, y, 0, int32_floor_div)
    Rem => zip_prim_nonzero(x, y, 0, int32_rem)
    Div => abort("arith_int32: true division is done on floats")
  }
}

///|
fn arith_int64(
  op : ArithOp,
  x : @arrow.PrimArray[Int64],
  y : @arrow.PrimArray[Int64],
) -> @arrow.PrimArray[Int64] {
  match op {
    Add => zip_prim(x, y, (a, b) => a + b)
    Sub => zip_prim(x, y, (a, b) => a - b)
    Mul => zip_prim(x, y, (a, b) => a * b)
    FloorDiv => zip_prim_nonzero(x, y, 0L, int64_floor_div)
    Rem => zip_prim_nonzero(x, y, 0L, int64_rem)
    Div => abort("arith_int64: true division is done on floats")
  }
}

///|
/// Float kernels: `floor_div` is `floor(x / y)` and `rem` is
/// `x - y * floor(x / y)` (polars' definition: the remainder takes the sign
/// of the divisor; `1.0 % inf` and `x % 0.0` are NaN).
fn arith_float64(
  op : ArithOp,
  x : @arrow.PrimArray[Double],
  y : @arrow.PrimArray[Double],
) -> @arrow.PrimArray[Double] {
  match op {
    Add => zip_prim(x, y, (a, b) => a + b)
    Sub => zip_prim(x, y, (a, b) => a - b)
    Mul => zip_prim(x, y, (a, b) => a * b)
    Div => zip_prim(x, y, (a, b) => a / b)
    FloorDiv => zip_prim(x, y, (a, b) => (a / b).floor())
    Rem => zip_prim(x, y, (a, b) => a - b * (a / b).floor())
  }
}

///|
fn arith_float32(
  op : ArithOp,
  x : @arrow.PrimArray[Float],
  y : @arrow.PrimArray[Float],
) -> @arrow.PrimArray[Float] {
  match op {
    Add => zip_prim(x, y, (a, b) => a + b)
    Sub => zip_prim(x, y, (a, b) => a - b)
    Mul => zip_prim(x, y, (a, b) => a * b)
    Div => zip_prim(x, y, (a, b) => a / b)
    FloorDiv => zip_prim(x, y, (a, b) => (a / b).floor())
    Rem => zip_prim(x, y, (a, b) => a - b * (a / b).floor())
  }
}

///|
/// Float kernels for a divisor that is one value: polars does not divide by
/// it, it multiplies with its reciprocal, `x * (1 / y)` (`floor_div` is
/// `floor(x * (1 / y))` and `rem` is `x - y * floor(x * (1 / y))`). The
/// result can differ from `x / y` in the last digit (`2147483647 / 3e9`, and
/// `Float32` `3e38 // 1.5`). `y` has been broadcast, so `1 / y` is computed
/// once per row from the same value.
fn arith_float64_by_scalar(
  op : ArithOp,
  x : @arrow.PrimArray[Double],
  y : @arrow.PrimArray[Double],
) -> @arrow.PrimArray[Double] {
  match op {
    Div => zip_prim(x, y, (a, b) => a * (1.0 / b))
    FloorDiv => zip_prim(x, y, (a, b) => (a * (1.0 / b)).floor())
    Rem => zip_prim(x, y, (a, b) => a - b * (a * (1.0 / b)).floor())
    _ => arith_float64(op, x, y)
  }
}

///|
fn arith_float32_by_scalar(
  op : ArithOp,
  x : @arrow.PrimArray[Float],
  y : @arrow.PrimArray[Float],
) -> @arrow.PrimArray[Float] {
  match op {
    Div => zip_prim(x, y, (a, b) => a * (1.0 / b))
    FloorDiv => zip_prim(x, y, (a, b) => (a * (1.0 / b)).floor())
    Rem => zip_prim(x, y, (a, b) => a - b * (a * (1.0 / b)).floor())
    _ => arith_float32(op, x, y)
  }
}

///|
fn Series::arith(
  self : Series,
  other : Series,
  op : ArithOp,
) -> Series raise PolarsError {
  let a = self.dtype()
  let b = other.dtype()
  if !arith_operand_ok(a) || !arith_operand_ok(b) {
    raise InvalidOperation(
      "\{op.name()} operation not supported for dtypes `\{a}` and `\{b}`",
    )
  }
  let n = binary_length(op.name(), self.len(), other.len())
  let t = match supertype(a, b) {
    Some(t) => t
    None => abort("Series::arith: no supertype of \{a} and \{b}")
  }
  if op is FloorDiv && t == Null {
    raise InvalidOperation("floor_div operation not supported for dtype `null`")
  }
  // true division is always a float division
  // (polars: `Null / Float32` is Float64 but `Float32 / Null` is Float32)
  let ct = match (op, t) {
    (Div, Float32) =>
      if a == Null {
        DataType::Float64
      } else {
        DataType::Float32
      }
    (Div, _) => DataType::Float64
    _ => t
  }
  if ct == Null {
    return Series::make(self.name, Null(n))
  }
  let x = self.col.cast_lenient(ct).expand(n)
  let y = other.col.cast_lenient(ct).expand(n)
  // a divisor of length 1 (next to a longer dividend) is multiplied with, in
  // a float division (polars: `s / pl.Series([3e9])` is `s * (1 / 3e9)`)
  let by_scalar = other.len() == 1 &&
    self.len() != 1 &&
    a != Null &&
    b != Null &&
    ct.is_float() &&
    !(op is Add || op is Sub || op is Mul)
  let col = match (x, y) {
    (Int32(p), Int32(q)) => Column::Int32(arith_int32(op, p, q))
    (Int64(p), Int64(q)) => Column::Int64(arith_int64(op, p, q))
    (Float32(p), Float32(q)) =>
      Column::Float32(
        if by_scalar {
          arith_float32_by_scalar(op, p, q)
        } else {
          arith_float32(op, p, q)
        },
      )
    (Float64(p), Float64(q)) =>
      Column::Float64(
        if by_scalar {
          arith_float64_by_scalar(op, p, q)
        } else {
          arith_float64(op, p, q)
        },
      )
    _ => abort("Series::arith: operands of different types after the cast")
  }
  Series::make(self.name, col)
}

///|
/// Element-wise sum. The result type is the supertype of the operands
/// (`Int32` + `Int64` is `Int64`, `Float32` + `Int32` is `Float64`; `Null` takes
/// the other type) and the name is `self`'s. Integer overflow wraps around.
/// A null on either side gives null. A length-1 operand is broadcast.
///
/// # Errors
/// - `InvalidOperation` unless both operands are `Int32`, `Int64`, `Float32`,
///   `Float64` or `Null` (`Boolean`, `String`, `Date` and `Datetime` have no
///   arithmetic).
/// - `ShapeMismatch` when the lengths differ and neither is 1.
pub fn Series::add(self : Series, other : Series) -> Series raise PolarsError {
  self.arith(other, Add)
}

///|
/// Element-wise difference; types, nulls, overflow, broadcasting and errors
/// as for `Series::add`.
pub fn Series::sub(self : Series, other : Series) -> Series raise PolarsError {
  self.arith(other, Sub)
}

///|
/// Element-wise product; types, nulls, overflow, broadcasting and errors as
/// for `Series::add`.
pub fn Series::mul(self : Series, other : Series) -> Series raise PolarsError {
  self.arith(other, Mul)
}

///|
/// Element-wise true division. The result is `Float64`, or `Float32` when both
/// operands are `Float32` or `self` is `Float32` and `other` is `Null` (polars:
/// `Null / Float32` is `Float64`). Division by zero
/// follows IEEE 754 (`1 / 0` is `inf`, `0 / 0` is NaN). Nulls, broadcasting and
/// errors as for `Series::add`.
///
/// When `other` has length 1 and `self` does not, polars multiplies by the
/// reciprocal (`x * (1 / y)`) instead of dividing, and so does this: the last
/// digit can differ from `x / y` (`2147483647 / 3e9`). The same holds for
/// `floor_div` and `rem` when the quotient is a float.
pub fn Series::div(self : Series, other : Series) -> Series raise PolarsError {
  self.arith(other, Div)
}

///|
/// Element-wise floor division (rounds towards negative infinity). Integer
/// division by zero is null; `Int64::MIN // -1` wraps. For floats the result is
/// `floor(x / y)`. Types, nulls, broadcasting and errors as for `Series::add`,
/// plus `InvalidOperation` when both operands are `Null`.
pub fn Series::floor_div(
  self : Series,
  other : Series,
) -> Series raise PolarsError {
  self.arith(other, FloorDiv)
}

///|
/// Element-wise remainder, taking the sign of the divisor (`-7 % 2` is `1`).
/// Integer remainder by zero is null and `MIN % -1` is 0. For floats it is
/// `x - y * floor(x / y)`. Types, nulls, broadcasting and errors as for
/// `Series::add`.
pub fn Series::rem(self : Series, other : Series) -> Series raise PolarsError {
  self.arith(other, Rem)
}

///|
/// Applies `f` to every slot, null slots included, and keeps the validity.
fn[T : Default] map_slots(
  a : @arrow.PrimArray[T],
  f : (T) -> T,
) -> @arrow.PrimArray[T] {
  let n = a.length()
  let out : FixedArray[T] = FixedArray::make(n, Default::default())
  for i in 0..<n {
    out[i] = f(a.value(i))
  }
  @arrow.PrimArray::new(out, a.validity())
}

///|
/// Arithmetic negation. `Int32::MIN` and `Int64::MIN` stay unchanged (wrap
/// around); `-0.0` and `0.0` swap. The name and nulls are kept.
///
/// # Errors
/// `InvalidOperation` for every type but `Int32`, `Int64`, `Float32` and
/// `Float64` (the message is polars': `` `neg` operation not supported for
/// dtype `bool` ``).
pub fn Series::neg(self : Series) -> Series raise PolarsError {
  let col = match self.col {
    Int32(a) => Column::Int32(map_slots(a, x => 0 - x))
    Int64(a) => Column::Int64(map_slots(a, x => 0L - x))
    Float32(a) => Column::Float32(map_slots(a, x => x * -1.0))
    Float64(a) => Column::Float64(map_slots(a, x => x * -1.0))
    _ =>
      raise InvalidOperation(
        "`neg` operation not supported for dtype `\{self.dtype()}`",
      )
  }
  Series::make(self.name, col)
}
