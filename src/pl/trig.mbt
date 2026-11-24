// Trigonometric functions: `sin`, `cos`, `tan`, `arcsin`, `arccos`, `arctan`
// of a `Series` and of an `Expr` (`ElemFunc` in `expr_agg.mbt`).

///|
/// polars' error for a type the trigonometric functions do not take.
fn trig_refused(dtype : DataType) -> PolarsError {
  InvalidOperation("trigonometry operation not supported for dtype `\{dtype}`")
}

///|
/// The column as floats for a trigonometric function: `Float32` and `Float64`
/// as they are, integers cast to `Float64`.
fn Column::trig_input(self : Column) -> Column raise PolarsError {
  match self {
    Float32(_) | Float64(_) => self
    Int32(_) | Int64(_) => self.cast_lenient(Float64)
    _ => raise trig_refused(self.dtype())
  }
}

///|
/// Applies a trigonometric function to every value: `f32` for a `Float32`
/// column, `f64` otherwise.
fn Series::trig(
  self : Series,
  f32 : (Float) -> Float,
  f64 : (Double) -> Double,
) -> Series raise PolarsError {
  let col = match self.col.trig_input() {
    Float32(a) => Column::Float32(map_slots(a, f32))
    Float64(a) => Column::Float64(map_slots(a, f64))
    _ => abort("Series::trig: not a float column")
  }
  Series::make(self.name, col)
}

///|
/// Sine of each value (radians). `Float32` stays `Float32`; integers give
/// `Float64`. Nulls stay null; the sine of an infinity is NaN.
///
/// The result can differ from polars' in the last bit, see
/// docs/golden/known-diffs/expr_shape.md.
///
/// # Errors
/// `InvalidOperation` (`` trigonometry operation not supported for dtype `str`
/// ``) for `Boolean`, `String`, `Date`, `Datetime` and `Null`.
pub fn Series::sin(self : Series) -> Series raise PolarsError {
  self.trig(x => @math.sinf(x), x => @math.sin(x))
}

///|
/// Cosine of each value; types, nulls and errors as for `Series::sin`.
pub fn Series::cos(self : Series) -> Series raise PolarsError {
  self.trig(x => @math.cosf(x), x => @math.cos(x))
}

///|
/// Tangent of each value; types, nulls and errors as for `Series::sin`.
pub fn Series::tan(self : Series) -> Series raise PolarsError {
  self.trig(x => Float::from_double(@math.tan(x.to_double())), x => @math.tan(x))
}

///|
/// Inverse sine of each value, in `[-pi/2, pi/2]`; NaN outside `[-1, 1]`.
/// Types, nulls and errors as for `Series::sin`.
pub fn Series::arcsin(self : Series) -> Series raise PolarsError {
  self.trig(x => @math.asinf(x), x => @math.asin(x))
}

///|
/// Inverse cosine of each value, in `[0, pi]`; NaN outside `[-1, 1]`. Types,
/// nulls and errors as for `Series::sin`.
pub fn Series::arccos(self : Series) -> Series raise PolarsError {
  self.trig(x => @math.acosf(x), x => @math.acos(x))
}

///|
/// Inverse tangent of each value, in `[-pi/2, pi/2]`. Types, nulls and errors
/// as for `Series::sin`.
pub fn Series::arctan(self : Series) -> Series raise PolarsError {
  self.trig(x => @math.atanf(x), x => @math.atan(x))
}

///|
/// Sine of each value; see `Series::sin`.
pub fn Expr::sin(self : Expr) -> Expr {
  Expr::of(Func(Sin, self.node))
}

///|
/// Cosine of each value; see `Series::cos`.
pub fn Expr::cos(self : Expr) -> Expr {
  Expr::of(Func(Cos, self.node))
}

///|
/// Tangent of each value; see `Series::tan`.
pub fn Expr::tan(self : Expr) -> Expr {
  Expr::of(Func(Tan, self.node))
}

///|
/// Inverse sine of each value; see `Series::arcsin`.
pub fn Expr::arcsin(self : Expr) -> Expr {
  Expr::of(Func(ArcSin, self.node))
}

///|
/// Inverse cosine of each value; see `Series::arccos`.
pub fn Expr::arccos(self : Expr) -> Expr {
  Expr::of(Func(ArcCos, self.node))
}

///|
/// Inverse tangent of each value; see `Series::arctan`.
pub fn Expr::arctan(self : Expr) -> Expr {
  Expr::of(Func(ArcTan, self.node))
}
