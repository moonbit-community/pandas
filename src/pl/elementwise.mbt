// Element-wise Series functions: null / NaN predicates, `fill_null`,
// `between`, `abs`, `sqrt`, `exp`, `log` and `round`.
//
// Semantics follow polars 2.1.0 (see docs/golden/elementwise.json and
// docs/golden/known-diffs/elementwise.md). The kernels loop over the typed
// arrays of a `Column`; no value is boxed as an `AnyValue`.

///|
/// Which ends of the interval `Series::between` counts as inside (polars'
/// `closed="both" | "left" | "right" | "none"`).
#derive(Eq, @debug.Debug)
pub(all) enum ClosedInterval {
  /// `lower <= x <= upper`
  Both
  /// `lower <= x < upper`
  Left
  /// `lower < x <= upper`
  Right
  /// `lower < x < upper`
  Neither
}

///|
/// Formats the option with its polars name (`both`, `left`, `right`, `none`).
pub impl Show for ClosedInterval with fn output(self, logger) {
  logger.write_string(
    match self {
      Both => "both"
      Left => "left"
      Right => "right"
      Neither => "none"
    },
  )
}

///|
/// Makes `to_string` callable as a method, giving the same polars name as
/// `Show`.
pub extend ClosedInterval with Show::{to_string}

///|
/// The error polars gives for a function the type does not support.
fn ew_unsupported(op : String, dtype : DataType) -> PolarsError {
  InvalidOperation("`\{op}` operation not supported for dtype `\{dtype}`")
}

///|
/// Whether `abs`, `sqrt`, `exp`, `log` and `round` refuse the type on purpose
/// (spec 5.5: `Boolean` has no arithmetic, `String` and the temporal types
/// only comparisons). polars computes some of these; see
/// docs/golden/known-diffs/elementwise.md.
fn ew_math_refused(dtype : DataType) -> Bool {
  match dtype {
    Boolean | String | Date | Datetime => true
    _ => false
  }
}

///|
fn ew_refused(op : String, dtype : DataType) -> PolarsError {
  InvalidOperation("\{op} is not supported for dtype \{dtype}")
}

///|
/// The error of `exp` and `log` for a type that is neither numeric nor
/// Boolean (polars reports the argument position).
fn ew_unsupported_arg(op : String, dtype : DataType) -> PolarsError {
  InvalidOperation(
    "`\{op}` operation not supported for dtype `\{dtype}` as argument 0",
  )
}

// ---------------------------------------------------------------------------
// is_null / is_not_null
// ---------------------------------------------------------------------------

///|
/// Boolean column that is true where the row is null (`want_null`) or where
/// it is not; it has no nulls itself.
fn ew_null_mask(col : Column, want_null : Bool) -> Column {
  let n = col.length()
  let bits = match col.validity() {
    None => @arrow.Bitmap::filled(n, !want_null)
    Some(v) => if want_null { v.bit_not() } else { v }
  }
  Column::Boolean(@arrow.BoolArray::new(bits, None))
}

///|
/// Whether each row is null; the result is `Boolean` without nulls and has the
/// name of `self`. A `Null` column is all true; NaN is a value, not null.
pub fn Series::is_null(self : Series) -> Series {
  Series::make(self.name, ew_null_mask(self.col, true))
}

///|
/// Whether each row is not null; the opposite of `Series::is_null`.
pub fn Series::is_not_null(self : Series) -> Series {
  Series::make(self.name, ew_null_mask(self.col, false))
}

// ---------------------------------------------------------------------------
// is_nan / is_not_nan / is_finite / is_infinite
// ---------------------------------------------------------------------------

///|
priv enum FloatClass {
  Nan
  NotNan
  Finite
  Infinite
}

///|
fn FloatClass::holds(self : FloatClass, x : Double) -> Bool {
  match self {
    Nan => x.is_nan()
    NotNan => !x.is_nan()
    Finite => !x.is_nan() && !x.is_inf()
    Infinite => x.is_inf()
  }
}

///|
/// The answer for an integer, which is never NaN and always finite.
fn FloatClass::for_integer(self : FloatClass) -> Bool {
  match self {
    Nan | Infinite => false
    NotNan | Finite => true
  }
}

///|
fn[T] ew_classify(a : @arrow.PrimArray[T], f : (T) -> Bool) -> @arrow.BoolArray {
  let n = a.length()
  let b = @arrow.BitmapBuilder::new(capacity=n)
  for i in 0..<n {
    b.push(f(a.value(i)))
  }
  @arrow.BoolArray::new(b.finish(), a.validity())
}

///|
fn Series::float_class(
  self : Series,
  kind : FloatClass,
  name : String,
) -> Series raise PolarsError {
  let col = match self.col {
    Float32(a) =>
      Column::Boolean(ew_classify(a, x => kind.holds(x.to_double())))
    Float64(a) => Column::Boolean(ew_classify(a, x => kind.holds(x)))
    Int32(a) =>
      Column::Boolean(
        @arrow.BoolArray::new(
          @arrow.Bitmap::filled(a.length(), kind.for_integer()),
          a.validity(),
        ),
      )
    Int64(a) =>
      Column::Boolean(
        @arrow.BoolArray::new(
          @arrow.Bitmap::filled(a.length(), kind.for_integer()),
          a.validity(),
        ),
      )
    Null(n) => Column::full_null(Boolean, n)
    _ => raise ew_unsupported(name, self.dtype())
  }
  Series::make(self.name, col)
}

///|
/// Whether each row is NaN. Integers are never NaN; null rows stay null, so a
/// `Null` column gives an all-null `Boolean`.
///
/// # Errors
/// `InvalidOperation` for `Boolean`, `String`, `Date` and `Datetime`.
pub fn Series::is_nan(self : Series) -> Series raise PolarsError {
  self.float_class(Nan, "is_nan")
}

///|
/// Whether each row is not NaN (null rows stay null); the opposite of
/// `Series::is_nan` and with the same errors.
pub fn Series::is_not_nan(self : Series) -> Series raise PolarsError {
  self.float_class(NotNan, "is_not_nan")
}

///|
/// Whether each row is neither NaN nor infinite (integers always are); null
/// rows stay null. Errors as for `Series::is_nan`.
pub fn Series::is_finite(self : Series) -> Series raise PolarsError {
  self.float_class(Finite, "is_finite")
}

///|
/// Whether each row is `inf` or `-inf` (integers never are); null rows stay
/// null. Errors as for `Series::is_nan`.
pub fn Series::is_infinite(self : Series) -> Series raise PolarsError {
  self.float_class(Infinite, "is_infinite")
}

// ---------------------------------------------------------------------------
// fill_null
// ---------------------------------------------------------------------------

///|
/// A column of one row holding `v`.
fn ew_scalar_column(v : AnyValue) -> Column {
  match v {
    Null => Column::Null(1)
    Boolean(x) => Column::Boolean(@arrow.BoolArray::from_array([x]))
    Int32(x) => Column::Int32(@arrow.PrimArray::from_array([x]))
    Int64(x) => Column::Int64(@arrow.PrimArray::from_array([x]))
    Float32(x) => Column::Float32(@arrow.PrimArray::from_array([x]))
    Float64(x) => Column::Float64(@arrow.PrimArray::from_array([x]))
    String(x) => Column::String(@arrow.StrArray::from_array([x]))
    Date(x) => Column::Date(@arrow.PrimArray::from_array([x]))
    Datetime(x) => Column::Datetime(@arrow.PrimArray::from_array([x]))
  }
}

///|
/// The common type of a column and a fill value: the supertype, and `String`
/// for a number next to text (`fill_null` casts both to text, although
/// comparison and arithmetic refuse that pair).
fn ew_fill_type(a : DataType, b : DataType) -> DataType? {
  match supertype(a, b) {
    Some(t) => Some(t)
    None =>
      match (a, b) {
        (String, t) | (t, String) if t.is_numeric() => Some(String)
        _ => None
      }
  }
}

///|
/// `a` with its null rows replaced by the only row of `fill` (kept as is when
/// that row is itself null).
fn[T : Default] ew_fill_prim(
  a : @arrow.PrimArray[T],
  fill : @arrow.PrimArray[T],
) -> @arrow.PrimArray[T] {
  if a.null_count() == 0 || !fill.is_valid(0) {
    return a
  }
  let v = fill.value(0)
  let n = a.length()
  let out : FixedArray[T] = FixedArray::make(n, Default::default())
  for i in 0..<n {
    out[i] = if a.is_valid(i) { a.value(i) } else { v }
  }
  @arrow.PrimArray::new(out, None)
}

///|
fn ew_fill_bool(
  a : @arrow.BoolArray,
  fill : @arrow.BoolArray,
) -> @arrow.BoolArray {
  if a.null_count() == 0 || !fill.is_valid(0) {
    return a
  }
  let v = fill.value(0)
  let b = @arrow.BoolBuilder::new(capacity=a.length())
  for i in 0..<a.length() {
    b.push(if a.is_valid(i) { a.value(i) } else { v })
  }
  b.finish()
}

///|
fn ew_fill_str(a : @arrow.StrArray, fill : @arrow.StrArray) -> @arrow.StrArray {
  if a.null_count() == 0 || !fill.is_valid(0) {
    return a
  }
  let v = fill.value(0)
  let b = @arrow.StrBuilder::new(capacity=a.length())
  for i in 0..<a.length() {
    b.push(if a.is_valid(i) { a.value(i) } else { v })
  }
  b.finish()
}

///|
/// Replaces the null rows with `value`. The result type is the supertype of
/// the column and the value (polars' rule for a strongly typed fill value):
/// `Int32` filled with `Float64(1.5)` is a `Float64` column, `Int32` with
/// `Int64` is `Int64`, a number with a `String` is `String`. The whole
/// column is cast, also when it has no null. A `Null` value changes nothing
/// (the column keeps its type); a `Null` column takes the type of the value.
/// NaN is not null and is kept.
///
/// # Errors
/// `SchemaMismatch` (`failed to determine supertype of bool and date`) when
/// the column and the value have no common type (`Boolean` with `Date` or
/// `Datetime`).
pub fn Series::fill_null(
  self : Series,
  value : AnyValue,
) -> Series raise PolarsError {
  let t = match ew_fill_type(self.dtype(), value.dtype()) {
    Some(t) => t
    None =>
      raise SchemaMismatch(
        "failed to determine supertype of \{self.dtype()} and \{value.dtype()}",
      )
  }
  let base = self.col.cast_lenient(t)
  if value is Null || base.null_count() == 0 {
    return Series::make(self.name, base)
  }
  let fill = ew_scalar_column(value).cast_lenient(t)
  let col = match (base, fill) {
    (Boolean(a), Boolean(f)) => Column::Boolean(ew_fill_bool(a, f))
    (Int32(a), Int32(f)) => Column::Int32(ew_fill_prim(a, f))
    (Int64(a), Int64(f)) => Column::Int64(ew_fill_prim(a, f))
    (Float32(a), Float32(f)) => Column::Float32(ew_fill_prim(a, f))
    (Float64(a), Float64(f)) => Column::Float64(ew_fill_prim(a, f))
    (String(a), String(f)) => Column::String(ew_fill_str(a, f))
    (Date(a), Date(f)) => Column::Date(ew_fill_prim(a, f))
    (Datetime(a), Datetime(f)) => Column::Datetime(ew_fill_prim(a, f))
    _ => abort("Series::fill_null: column and fill value differ after the cast")
  }
  Series::make(self.name, col)
}

// ---------------------------------------------------------------------------
// between
// ---------------------------------------------------------------------------

///|
/// `self <op> bound` with polars' message when the lengths do not fit.
fn Series::ew_bound(
  self : Series,
  bound : Series,
  op : CmpOp,
) -> Series raise PolarsError {
  self.compare(bound, op) catch {
    ShapeMismatch(_) => {
      let symbol = match op {
        Lt => "<"
        Le => "<="
        Gt => ">"
        Ge => ">="
        Eq => "=="
        Ne => "!="
      }
      raise ShapeMismatch(
        "could not perform '\{symbol}' comparison between series '\{self.name}' of length: \{self.len()} and series '\{bound.name}' of length: \{bound.len()}, because they have different lengths",
      )
    }
    e => raise e
  }
}

///|
/// Whether each row lies between `lower` and `upper`, as
/// `(self >= lower) & (self <= upper)` (the comparisons become strict for the
/// ends `closed` leaves out). The result is `Boolean`, named like `self`.
///
/// - The three series are compared as `Series::ge` and `Series::le` do: cast
///   to a common type, NaN above every number, strings by code point.
/// - A length-1 bound is broadcast. A null row or bound gives null, except
///   that the other bound can already decide (`false & null` is `false`), so
///   `4` is not between a null lower bound and an upper bound of `3`.
/// - `lower` above `upper` is not an error: no row is between.
///
/// # Errors
/// - `ShapeMismatch` (`could not perform '>=' comparison between series 'a'
///   of length: 6 and series 'lo' of length: 3, because they have different
///   lengths`) when `self` and a bound differ in length and neither is 1.
///   The lower bound is checked first.
/// - `SchemaMismatch` / `ComputeError` when a comparison has no common type,
///   as for `Series::ge` (`Boolean` with `Date`, text with a number).
pub fn Series::between(
  self : Series,
  lower : Series,
  upper : Series,
  closed~ : ClosedInterval = Both,
) -> Series raise PolarsError {
  let (lower_op, upper_op) = match closed {
    Both => (CmpOp::Ge, CmpOp::Le)
    Left => (CmpOp::Ge, CmpOp::Lt)
    Right => (CmpOp::Gt, CmpOp::Le)
    Neither => (CmpOp::Gt, CmpOp::Lt)
  }
  let l = self.ew_bound(lower, lower_op)
  let u = self.ew_bound(upper, upper_op)
  l.and_(u)
}

// ---------------------------------------------------------------------------
// abs
// ---------------------------------------------------------------------------

///|
/// Absolute value, in the type of the column. `Int32::MIN` and `Int64::MIN`
/// stay as they are (wrap around, no trap); `-0.0` gives `0.0`, NaN stays
/// NaN, nulls stay null.
///
/// # Errors
/// `InvalidOperation` for `Boolean`, `String`, `Date` and `Datetime`
/// (`abs is not supported for dtype bool`; spec 5.5, polars refuses these
/// too), and for `Null` (polars' text: `` `abs` operation not supported for
/// dtype `null` ``).
pub fn Series::abs(self : Series) -> Series raise PolarsError {
  let col = match self.col {
    Int32(a) => Column::Int32(map_slots(a, x => if x < 0 { 0 - x } else { x }))
    Int64(a) =>
      Column::Int64(map_slots(a, x => if x < 0L { 0L - x } else { x }))
    Float32(a) => Column::Float32(map_slots(a, x => x.abs()))
    Float64(a) => Column::Float64(map_slots(a, x => x.abs()))
    _ =>
      if ew_math_refused(self.dtype()) {
        raise ew_refused("abs", self.dtype())
      } else {
        raise ew_unsupported("abs", self.dtype())
      }
  }
  Series::make(self.name, col)
}

// ---------------------------------------------------------------------------
// sqrt / exp / log
// ---------------------------------------------------------------------------

///|
/// Square root. `Float32` stays `Float32`; integers are cast to `Float64`, and
/// `Null` gives an all-null `Float64`. A negative value gives NaN, `-0.0` stays
/// `-0.0`.
///
/// # Errors
/// `InvalidOperation` (`sqrt is not supported for dtype str`) for `Boolean`,
/// `String`, `Date` and `Datetime`. (polars computes these by casting to
/// `Float64`; spec 5.5 wins, see docs/golden/known-diffs/elementwise.md.)
pub fn Series::sqrt(self : Series) -> Series raise PolarsError {
  if ew_math_refused(self.dtype()) {
    raise ew_refused("sqrt", self.dtype())
  }
  let col = match self.col {
    Float32(a) => Column::Float32(map_slots(a, x => x.sqrt()))
    Float64(a) => Column::Float64(map_slots(a, x => x.sqrt()))
    c =>
      match c.cast_lenient(Float64) {
        Float64(a) => Column::Float64(map_slots(a, x => x.sqrt()))
        _ => abort("Series::sqrt: cast to Float64 gave another type")
      }
  }
  Series::make(self.name, col)
}

///|
/// The column as floats for `exp` and `log`: `Float32` and `Float64` as they
/// are, integers cast to `Float64`.
fn Column::ew_floating(self : Column, op : String) -> Column raise PolarsError {
  match self {
    Float32(_) | Float64(_) => self
    Int32(_) | Int64(_) => self.cast_lenient(Float64)
    _ =>
      if ew_math_refused(self.dtype()) {
        raise ew_refused(op, self.dtype())
      } else {
        raise ew_unsupported_arg(op, self.dtype())
      }
  }
}

///|
/// `e` to the power of each value. `Float32` stays `Float32`; integers give
/// `Float64`. Overflow gives `inf`, a very negative value `0.0`.
///
/// The result can differ from polars' in the last bit (the library computes
/// `exp` itself, polars calls the C library; see
/// docs/golden/known-diffs/elementwise.md).
///
/// # Errors
/// `InvalidOperation` for `Boolean`, `String`, `Date` and `Datetime`
/// (`exp is not supported for dtype str`; spec 5.5), and for `Null` (polars'
/// text: `` `exp` operation not supported for dtype `null` as argument 0 ``).
pub fn Series::exp(self : Series) -> Series raise PolarsError {
  let col = match self.col.ew_floating("exp") {
    Float32(a) => Column::Float32(map_slots(a, x => @math.expf(x)))
    Float64(a) => Column::Float64(map_slots(a, x => @math.exp(x)))
    _ => abort("Series::exp: not a float column")
  }
  Series::make(self.name, col)
}

///|
/// Logarithm to `base` (natural by default), computed as `ln(x) / ln(base)`
/// like polars. `Float32` stays `Float32` (the base is rounded to `Float32`
/// and the arithmetic is done in `Float32`); integers give `Float64`. `log(0)` is `-inf`, the logarithm of a negative number is NaN;
/// base `1` divides by zero (`inf`, or NaN for `x = 1`), a base outside
/// `(0, inf)` gives NaN or zero as the division does. Nulls stay null.
///
/// The result can differ from polars' in the last bit, see `Series::exp`.
///
/// # Errors
/// `InvalidOperation` for `Boolean`, `String`, `Date` and `Datetime`
/// (`log is not supported for dtype date`; spec 5.5), and for `Null` (polars'
/// text: `` `log` operation not supported for dtype `null` as argument 0 ``).
pub fn Series::log(
  self : Series,
  base~ : Double = 2.718281828459045,
) -> Series raise PolarsError {
  let col = match self.col.ew_floating("log") {
    Float32(a) => {
      let ln_base = @math.lnf(Float::from_double(base))
      Column::Float32(map_slots(a, x => @math.lnf(x) / ln_base))
    }
    Float64(a) => {
      let ln_base = @math.ln(base)
      Column::Float64(map_slots(a, x => @math.ln(x) / ln_base))
    }
    _ => abort("Series::log: not a float column")
  }
  Series::make(self.name, col)
}

// ---------------------------------------------------------------------------
// round
// ---------------------------------------------------------------------------

///|
/// `10^d` by repeated squaring, as the compiler's `powi` does (exact up to
/// `10^22`).
fn ew_pow10(d : Int32) -> Double {
  let mut result = 1.0
  let mut base = 10.0
  let mut e = d
  while e > 0 {
    if e % 2 == 1 {
      result = result * base
    }
    e = e / 2
    if e > 0 {
      base = base * base
    }
  }
  result
}

///|
/// Rounds `y` to the nearest integer, ties to the even one; `-0.5` gives
/// `-0.0`. Values with no fractional part (`|y| >= 2^52`) are returned as
/// they are.
fn ew_round_ties_even(y : Double) -> Double {
  if y.abs() >= 4503599627370496.0 {
    return y
  }
  let f = y.floor()
  let diff = y - f
  let r = if diff < 0.5 {
    f
  } else if diff > 0.5 {
    f + 1.0
  } else if (f / 2.0).floor() * 2.0 == f {
    f
  } else {
    f + 1.0
  }
  if r == 0.0 && y.reinterpret_as_int64() < 0L {
    -0.0
  } else {
    r
  }
}

///|
/// `round(x * m) / m` with ties to even. A value that is NaN or infinite, or
/// whose product with `m` overflows, is returned unchanged.
fn ew_round_decimals(x : Double, m : Double) -> Double {
  if x.is_nan() || x.is_inf() {
    return x
  }
  let y = x * m
  if y.is_nan() || y.is_inf() {
    return x
  }
  ew_round_ties_even(y) / m
}

///|
/// Rounds to `decimals` decimal places; a tie goes to the even neighbour (the
/// default mode of polars 2.1.0, `half_to_even`), computed as
/// `round(x * 10^decimals) / 10^decimals`. The result keeps the type.
/// `Float32` is computed in `Float64` and rounded back. Integers are returned
/// as they are. NaN, infinities and values whose scaling overflows are
/// returned unchanged; `-0.5` rounds to `-0.0`.
///
/// # Errors
/// - `InvalidOperation` (`decimals must be non-negative, got -1`) for a
///   negative `decimals` (polars takes an unsigned count and fails before it
///   runs).
/// - `InvalidOperation` (`round is not supported for dtype bool`) for
///   `Boolean`, `String`, `Date` and `Datetime` (spec 5.5).
/// - `InvalidOperation` (`rounding ('half_to_even') operation not supported
///   for dtype `null` (expected: numeric)`, polars' text) for `Null`.
pub fn Series::round(
  self : Series,
  decimals~ : Int32 = 0,
) -> Series raise PolarsError {
  if decimals < 0 {
    raise InvalidOperation("decimals must be non-negative, got \{decimals}")
  }
  match self.col {
    Float32(a) => {
      let m = ew_pow10(decimals)
      Series::make(
        self.name,
        Column::Float32(
          map_slots(a, x => {
            Float::from_double(ew_round_decimals(x.to_double(), m))
          }),
        ),
      )
    }
    Float64(a) => {
      let m = ew_pow10(decimals)
      Series::make(
        self.name,
        Column::Float64(map_slots(a, x => ew_round_decimals(x, m))),
      )
    }
    Int32(_) | Int64(_) => self
    _ if ew_math_refused(self.dtype()) =>
      raise ew_refused("round", self.dtype())
    _ =>
      raise InvalidOperation(
        "rounding ('half_to_even') operation not supported for dtype `\{self.dtype()}` (expected: numeric)",
      )
  }
}
