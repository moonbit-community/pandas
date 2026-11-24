///|
priv enum CmpOp {
  Eq
  Ne
  Lt
  Le
  Gt
  Ge
}

///|
/// The operator as polars writes it in its type error (`eq` and `ne` have no
/// symbol there).
fn CmpOp::symbol(self : CmpOp) -> String {
  match self {
    Eq | Ne => ""
    Lt => " '<'"
    Le => " '<='"
    Gt => " '>'"
    Ge => " '>='"
  }
}

///|
/// Result of `op` given the sign of `compare(x, y)`.
fn CmpOp::holds(self : CmpOp, c : Int32) -> Bool {
  match self {
    Eq => c == 0
    Ne => c != 0
    Lt => c < 0
    Le => c <= 0
    Gt => c > 0
    Ge => c >= 0
  }
}

///|
/// Element-wise comparison of two arrays of the same length; `cmp` is the
/// three-way comparison of two values (null slots are compared too, their
/// result is masked by the validity).
fn[T] cmp_prim(
  op : CmpOp,
  x : @arrow.PrimArray[T],
  y : @arrow.PrimArray[T],
  cmp : (T, T) -> Int32,
) -> @arrow.BoolArray {
  let n = x.length()
  let b = @arrow.BitmapBuilder::new(capacity=n)
  for i in 0..<n {
    b.push(op.holds(cmp(x.value(i), y.value(i))))
  }
  @arrow.BoolArray::new(b.finish(), and_validity(x.validity(), y.validity()))
}

///|
fn[T : Compare] ord_cmp(x : T, y : T) -> Int32 {
  if x < y {
    -1
  } else if x > y {
    1
  } else {
    0
  }
}

///|
/// NaN is equal to itself and greater than every number; `-0.0 == 0.0`
/// (polars' total order for floats).
fn[T : Compare] float_cmp(x : T, y : T) -> Int32 {
  let x_nan = x != x
  let y_nan = y != y
  if x_nan {
    if y_nan {
      0
    } else {
      1
    }
  } else if y_nan {
    -1
  } else {
    ord_cmp(x, y)
  }
}

///|
fn cmp_bool_array(
  op : CmpOp,
  x : @arrow.BoolArray,
  y : @arrow.BoolArray,
) -> @arrow.BoolArray {
  let n = x.length()
  let b = @arrow.BitmapBuilder::new(capacity=n)
  for i in 0..<n {
    b.push(op.holds(ord_cmp(x.value(i), y.value(i))))
  }
  @arrow.BoolArray::new(b.finish(), and_validity(x.validity(), y.validity()))
}

///|
fn cmp_str_array(
  op : CmpOp,
  x : @arrow.StrArray,
  y : @arrow.StrArray,
) -> @arrow.BoolArray {
  let n = x.length()
  let b = @arrow.BitmapBuilder::new(capacity=n)
  for i in 0..<n {
    let l = x.value(i)
    let r = y.value(i)
    b.push(
      match op {
        Eq => l == r
        Ne => l != r
        _ => op.holds(str_cmp(l, r))
      },
    )
  }
  @arrow.BoolArray::new(b.finish(), and_validity(x.validity(), y.validity()))
}

///|
fn Series::compare(
  self : Series,
  other : Series,
  op : CmpOp,
) -> Series raise PolarsError {
  let a = self.dtype()
  let b = other.dtype()
  let t = match supertype(a, b) {
    Some(t) => t
    None => {
      match (a, b) {
        (String, t) | (t, String) if t.is_numeric() =>
          raise ComputeError("cannot compare string with numeric type (\{t})")
        _ => ()
      }
      raise SchemaMismatch(
        "could not evaluate\{op.symbol()} comparison between series '\{self.name}' of dtype: \{polars_type_name(a)} and series '\{other.name}' of dtype: \{polars_type_name(b)}",
      )
    }
  }
  let n = binary_length("compare", self.len(), other.len())
  if t == Null {
    return Series::make(self.name, Column::full_null(Boolean, n))
  }
  let x = self.col.cast_lenient(t).expand(n)
  let y = other.col.cast_lenient(t).expand(n)
  let col = match (x, y) {
    (Boolean(p), Boolean(q)) => cmp_bool_array(op, p, q)
    (Int32(p), Int32(q)) | (Date(p), Date(q)) => cmp_prim(op, p, q, ord_cmp)
    (Int64(p), Int64(q)) | (Datetime(p), Datetime(q)) =>
      cmp_prim(op, p, q, ord_cmp)
    (Float32(p), Float32(q)) => cmp_prim(op, p, q, float_cmp)
    (Float64(p), Float64(q)) => cmp_prim(op, p, q, float_cmp)
    (String(p), String(q)) => cmp_str_array(op, p, q)
    _ => abort("Series::compare: operands of different types after the cast")
  }
  Series::make(self.name, Column::Boolean(col))
}

///|
/// Element-wise equality; the result is `Boolean` (null where either side is
/// null) and has `self`'s name. Operands are cast to their supertype first (see
/// the notes on `Series::add`): `Int32` against `Float32` compares as `Float64`,
/// a `Date` against an integer compares its day count, against a `Datetime` it
/// is the midnight microsecond, and `String` against `Boolean`, `Date` or
/// `Datetime` compares text. Floats follow polars: NaN equals NaN, `-0.0`
/// equals `0.0`. Length-1 operands broadcast.
///
/// # Errors
/// - `ComputeError` (`cannot compare string with numeric type (i32)`) for a
///   `String` against a number.
/// - `SchemaMismatch` (`could not evaluate comparison between series 'a' of
///   dtype: Boolean and series 'b' of dtype: Date`) for `Boolean` against
///   `Date` or `Datetime`.
/// - `ShapeMismatch` when the lengths differ and neither is 1.
pub fn Series::eq(self : Series, other : Series) -> Series raise PolarsError {
  self.compare(other, Eq)
}

///|
/// Element-wise inequality; types, nulls, NaN, broadcasting and errors as for
/// `Series::eq`.
pub fn Series::neq(self : Series, other : Series) -> Series raise PolarsError {
  self.compare(other, Ne)
}

///|
/// Element-wise `>`. NaN is greater than every number; strings compare by
/// Unicode code point. Types, nulls, broadcasting and errors as for
/// `Series::eq` (the symbol shows in the `SchemaMismatch` text: `could not
/// evaluate '>' comparison ...`).
pub fn Series::gt(self : Series, other : Series) -> Series raise PolarsError {
  self.compare(other, Gt)
}

///|
/// Element-wise `>=`; see `Series::gt`.
pub fn Series::ge(self : Series, other : Series) -> Series raise PolarsError {
  self.compare(other, Ge)
}

///|
/// Element-wise `<`; see `Series::gt`.
pub fn Series::lt(self : Series, other : Series) -> Series raise PolarsError {
  self.compare(other, Lt)
}

///|
/// Element-wise `<=`; see `Series::gt`.
pub fn Series::le(self : Series, other : Series) -> Series raise PolarsError {
  self.compare(other, Le)
}
