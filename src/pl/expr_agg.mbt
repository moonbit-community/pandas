// Aggregations and element-wise functions on expressions.
//
// An aggregation turns a column into one value (a series of length 1, which
// `select` and `with_columns` repeat to the height of the frame). The
// element-wise functions keep the length. `fill_null` and `when/then`
// (`when.mbt`) share the row-wise picker at the end of this file.

// ---------------------------------------------------------------------------
// Show text and evaluation of the pieces
// ---------------------------------------------------------------------------

///|
/// An element-wise function of one expression.
priv enum ElemFunc {
  IsNan
  IsNotNan
  IsFinite
  IsInfinite
  Abs
  Sqrt
  Exp
  /// `Log(base)`
  Log(Double)
  /// `Round(decimals)`
  Round(Int32)
}

///|
/// The call as polars prints it: `is_nan()`, `log([dyn float: 2])`; the
/// `decimals` of `round` is not part of polars' text.
fn ElemFunc::text(self : ElemFunc) -> String {
  match self {
    IsNan => "is_nan()"
    IsNotNan => "is_not_nan()"
    IsFinite => "is_finite()"
    IsInfinite => "is_infinite()"
    Abs => "abs()"
    Sqrt => "sqrt()"
    Exp => "exp()"
    Log(base) => "log([dyn float: \{rust_display_float(base)}])"
    Round(_) => "round()"
  }
}

///|
fn ElemFunc::apply(self : ElemFunc, s : Series) -> Series raise PolarsError {
  match self {
    IsNan => s.is_nan()
    IsNotNan => s.is_not_nan()
    IsFinite => s.is_finite()
    IsInfinite => s.is_infinite()
    Abs => s.abs()
    Sqrt => s.sqrt()
    Exp => s.exp()
    Log(base) => s.log(base~)
    Round(decimals) => s.round(decimals~)
  }
}

///|
/// The call as polars prints it: `sum()`, `quantile([dyn float: 0.25])`
/// (neither `ddof` nor the interpolation is part of the text).
fn AggOp::text(self : AggOp) -> String {
  match self {
    Quantile(q, _) => "quantile([dyn float: \{rust_display_float(q)}])"
    _ => self.name() + "()"
  }
}

///|
/// polars prints a `Series` argument as `Series[name]`, `Series` when it has
/// no name.
fn series_text(s : Series) -> String {
  if s.name == "" {
    "Series"
  } else {
    "Series[\{s.name}]"
  }
}

///|
/// The aggregate of a series: one row, named like the series.
///
/// # Errors
/// What `agg_column` raises, with one difference: on a column with rows
/// polars' expression engine puts the name of the operation in backticks in
/// the error for a quantile outside `[0, 1]` (`` `quantile` should be between
/// 0.0 and 1.0, got 1.5 ``) when the column has a null (an all-null one
/// too); with no null, on an empty column, and in the Series method, it does
/// not.
fn xagg_agg(s : Series, op : AggOp) -> Series raise PolarsError {
  Series::make(s.name, agg_column(s.col, op)) catch {
    ComputeError(m) if s.null_count() > 0 && m.has_prefix("quantile should") =>
      raise ComputeError("`quantile` " + m[9:].to_owned())
    e => raise e
  }
}

///|
/// `n_unique` as an `Int64` row (null counts as one value).
fn xagg_n_unique(s : Series) -> Series {
  Series::make(s.name, agg_col_i64(Some(s.n_unique().to_int64())))
}

///|
/// `x.between(lo, hi)` as the two comparisons it stands for, so that weak
/// literals adapt to `x` and the comparison errors are those of `<` and `>=`:
/// `(x >= lo) & (x <= hi)`, with a strict comparison for an end `closed` does
/// not include. `x` is evaluated once, then `lo`, the first comparison, `hi`,
/// the second one, the `&` (the order of evaluating that expression).
///
/// # Errors
/// What the comparisons and `&` raise.
fn xagg_between(
  df : DataFrame,
  x : ExprNode,
  lo : ExprNode,
  hi : ExprNode,
  closed : ClosedInterval,
) -> Series raise PolarsError {
  let (lower_op, upper_op) = match closed {
    Both => (BinaryOp::Ge, BinaryOp::Le)
    Left => (BinaryOp::Ge, BinaryOp::Lt)
    Right => (BinaryOp::Gt, BinaryOp::Le)
    Neither => (BinaryOp::Gt, BinaryOp::Lt)
  }
  let xo = eval_operand(df, x)
  let lower = combine_operands(lower_op, x, lo, xo, eval_operand(df, lo))
  let upper = combine_operands(upper_op, x, hi, xo, eval_operand(df, hi))
  match combine_operands(BinaryOp::And, x, x, lower, upper) {
    Weak(w) => weak_default(output_name(x), w)
    Strong(s) => s
  }
}

///|
/// Gives two evaluated operands that meet (the branches of a `when`, a value
/// and its fill) a type each: a weak literal takes its type from the other
/// one (see `weak_series`); two weak literals are `Int64` / `Float64`. Both
/// series are named after their expressions.
fn xagg_resolve(
  a : ExprNode,
  b : ExprNode,
  ao : Operand,
  bo : Operand,
) -> (Series, Series) {
  match (ao, bo) {
    (Weak(x), Weak(y)) =>
      (weak_default(output_name(a), x), weak_default(output_name(b), y))
    (Weak(x), Strong(t)) => (weak_series(output_name(a), x, t.dtype()), t)
    (Strong(s), Weak(y)) => (s, weak_series(output_name(b), y, s.dtype()))
    (Strong(s), Strong(t)) => (s, t)
  }
}

///|
/// The type the two branches of `fill_null` or `when` are cast to: the
/// supertype, and `String` for a number next to text (polars casts both to
/// text there, while comparison and arithmetic refuse that pair).
///
/// # Errors
/// `SchemaMismatch` (`failed to determine supertype of bool and date`).
fn xagg_common_type(a : DataType, b : DataType) -> DataType raise PolarsError {
  match ew_fill_type(a, b) {
    Some(t) => t
    None =>
      raise SchemaMismatch("failed to determine supertype of \{a} and \{b}")
  }
}

///|
/// How polars names a weak literal in its messages.
fn WeakVal::text(self : WeakVal) -> String {
  match self {
    Int(_) => "dyn int"
    Float(_) => "dyn float"
  }
}

///|
/// `fill_null` of expressions: the null rows of `x` are replaced by the row
/// of the value expression (a column of the same length fills row by row, a
/// length-1 value fills every row), in the supertype of the two. A value that
/// is itself null leaves the row null.
///
/// # Errors
/// `InvalidOperation` for a weak literal next to a `Date` or `Datetime`
/// (polars: `got invalid or ambiguous dtypes: '[date, dyn int]' in expression
/// 'fill_null'`), `SchemaMismatch` when there is no common type.
fn xagg_fill_null(
  df : DataFrame,
  x : ExprNode,
  v : ExprNode,
) -> Series raise PolarsError {
  let ao = eval_operand(df, x)
  let bo = eval_operand(df, v)
  // polars cannot fill a temporal value with a weak literal
  match (ao, bo) {
    (Weak(w), Strong(t)) | (Strong(t), Weak(w)) if t.dtype()
      is (Date | Datetime) => {
      let (left, right) = match ao {
        Weak(_) => (w.text(), "\{t.dtype()}")
        Strong(_) => ("\{t.dtype()}", w.text())
      }
      raise InvalidOperation(
        "got invalid or ambiguous dtypes: '[\{left}, \{right}]' in expression 'fill_null'",
      )
    }
    _ => ()
  }
  let (s, f) = xagg_resolve(x, v, ao, bo)
  let t = xagg_common_type(s.dtype(), f.dtype())
  let n = binary_length("fill_null", s.len(), f.len())
  let base = s.col.cast_lenient(t).expand(n)
  let fill = f.col.cast_lenient(t).expand(n)
  if base.null_count() == 0 {
    return Series::make(s.name, base)
  }
  let take = @arrow.BitmapBuilder::new(capacity=n)
  for i in 0..<n {
    take.push(base.is_valid(i))
  }
  Series::make(s.name, xagg_pick(take.finish(), base, fill))
}

// ---------------------------------------------------------------------------
// The row-wise picker
// ---------------------------------------------------------------------------

///|
fn[T : Default] xagg_pick_prim(
  take : @arrow.Bitmap,
  a : @arrow.PrimArray[T],
  b : @arrow.PrimArray[T],
) -> @arrow.PrimArray[T] {
  let n = take.length()
  let out = @arrow.PrimBuilder::new(capacity=n)
  for i in 0..<n {
    let src = if take.get(i) { a } else { b }
    if src.is_valid(i) {
      out.push(src.value(i))
    } else {
      out.push_null()
    }
  }
  out.finish()
}

///|
fn xagg_pick_bool(
  take : @arrow.Bitmap,
  a : @arrow.BoolArray,
  b : @arrow.BoolArray,
) -> @arrow.BoolArray {
  let n = take.length()
  let out = @arrow.BoolBuilder::new(capacity=n)
  for i in 0..<n {
    let src = if take.get(i) { a } else { b }
    if src.is_valid(i) {
      out.push(src.value(i))
    } else {
      out.push_null()
    }
  }
  out.finish()
}

///|
fn xagg_pick_str(
  take : @arrow.Bitmap,
  a : @arrow.StrArray,
  b : @arrow.StrArray,
) -> @arrow.StrArray {
  let n = take.length()
  let out = @arrow.StrBuilder::new(capacity=n)
  for i in 0..<n {
    let src = if take.get(i) { a } else { b }
    if src.is_valid(i) {
      out.push(src.value(i))
    } else {
      out.push_null()
    }
  }
  out.finish()
}

///|
/// Row `i` of the result is row `i` of `a` where `take` is set and row `i` of
/// `b` elsewhere (nulls are carried over). The columns have the same type and
/// as many rows as `take` has bits.
fn xagg_pick(take : @arrow.Bitmap, a : Column, b : Column) -> Column {
  match (a, b) {
    (Boolean(x), Boolean(y)) => Boolean(xagg_pick_bool(take, x, y))
    (Int32(x), Int32(y)) => Int32(xagg_pick_prim(take, x, y))
    (Int64(x), Int64(y)) => Int64(xagg_pick_prim(take, x, y))
    (Float32(x), Float32(y)) => Float32(xagg_pick_prim(take, x, y))
    (Float64(x), Float64(y)) => Float64(xagg_pick_prim(take, x, y))
    (String(x), String(y)) => String(xagg_pick_str(take, x, y))
    (Date(x), Date(y)) => Date(xagg_pick_prim(take, x, y))
    (Datetime(x), Datetime(y)) => Datetime(xagg_pick_prim(take, x, y))
    (Null(n), Null(_)) => Null(n)
    _ => abort("xagg_pick: columns of different types")
  }
}

// ---------------------------------------------------------------------------
// Aggregations
// ---------------------------------------------------------------------------

///|
/// Sum of the non-null values, in the type of the expression (`Int32`,
/// `Int64`, `Float32`, `Float64`; `Int64` for `Boolean`); the sum of nothing
/// is 0. The result is a single row, named like `self`, which `select` and
/// `with_columns` repeat next to longer columns:
/// `col("a") / col("a").sum()` divides every row by the total.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::int32("a", [1, 2, 3])])
///   let out = df.select([@pl.col("a").sum()])
///   assert_eq(out.shape(), (1, 1))
///   assert_eq(out.column("a").to_list(), [@pl.AnyValue::Int32(6)])
/// }
/// ```
///
/// # Errors
/// Evaluating raises `InvalidOperation` for `String`, `Date` and `Datetime`
/// (`` `sum` operation not supported for dtype `str` ``), as every
/// aggregation raises it for the types it is not defined for; the types
/// are listed with `Series::sum` and the others.
pub fn Expr::sum(self : Expr) -> Expr {
  Expr::of(Agg(Sum, self.node))
}

///|
/// Mean of the non-null values: `Float64` (`Float32` for `Float32`,
/// `Datetime` for `Date` and `Datetime`); null when there are no values.
/// See `Expr::sum` for the shape of the result.
pub fn Expr::mean(self : Expr) -> Expr {
  Expr::of(Agg(Mean, self.node))
}

///|
/// Smallest non-null value, of the type of the expression (strings by code
/// point, NaN ignored unless all values are NaN); null when there are no
/// values. See `Expr::sum` for the shape of the result.
pub fn Expr::min(self : Expr) -> Expr {
  Expr::of(Agg(Min, self.node))
}

///|
/// Largest non-null value; see `Expr::min`.
pub fn Expr::max(self : Expr) -> Expr {
  Expr::of(Agg(Max, self.node))
}

///|
/// Number of non-null values, an `Int64`. See `Expr::sum` for the shape of
/// the result.
pub fn Expr::count(self : Expr) -> Expr {
  Expr::of(Agg(Count, self.node))
}

///|
/// Number of rows, null ones included, an `Int64` (`Expr::count` skips the
/// nulls). See `Expr::sum` for the shape of the result.
pub fn Expr::len(self : Expr) -> Expr {
  Expr::of(Agg(Len, self.node))
}

///|
/// Number of distinct values, an `Int64`; null counts as a value, NaN is one
/// value and `-0.0` equals `0.0`. See `Expr::sum` for the shape of the
/// result.
pub fn Expr::n_unique(self : Expr) -> Expr {
  Expr::of(NUnique(self.node))
}

///|
/// The first value, which may be null; null for no rows, of the type of the
/// expression. See `Expr::sum` for the shape of the result.
pub fn Expr::first(self : Expr) -> Expr {
  Expr::of(Agg(First, self.node))
}

///|
/// The last value, which may be null; see `Expr::first`.
pub fn Expr::last(self : Expr) -> Expr {
  Expr::of(Agg(Last, self.node))
}

///|
/// Median of the non-null values (the mean of the two middle ones for an even
/// count): `Float64` (`Float32` for `Float32`, `Datetime` for `Date` and
/// `Datetime`); null when there are no values. See `Expr::sum` for the shape
/// of the result.
pub fn Expr::median(self : Expr) -> Expr {
  Expr::of(Agg(Median, self.node))
}

///|
/// Product of the non-null values: `Int64` for integers and `Boolean`
/// (wrapping around), `Float32` / `Float64` for floats; the empty product is
/// 1. See `Expr::sum` for the shape of the result.
pub fn Expr::product(self : Expr) -> Expr {
  Expr::of(Agg(Product, self.node))
}

///|
/// Standard deviation of the non-null values with `ddof` delta degrees of
/// freedom (default 1): `Float64` (`Float32` for `Float32`); null when there
/// are no more than `ddof` values. polars prints `col("a").std()` whatever
/// the `ddof`. See `Expr::sum` for the shape of the result.
///
/// # Errors
/// Evaluating raises `InvalidOperation` for `String`, `Date` and `Datetime`
/// and for a negative `ddof`.
pub fn Expr::std(self : Expr, ddof~ : Int32 = 1) -> Expr {
  Expr::of(Agg(Std(ddof), self.node))
}

///|
/// Variance of the non-null values (`var` is a MoonBit keyword); see
/// `Expr::std`.
pub fn Expr::var_(self : Expr, ddof~ : Int32 = 1) -> Expr {
  Expr::of(Agg(Var(ddof), self.node))
}

///|
/// The quantile `q` of the non-null values, picked or interpolated by
/// `interpolation` (see `QuantileMethod`): `Float64` (`Float32` for
/// `Float32`, `Datetime` for `Date` and `Datetime`); null when there are no
/// values. polars prints `col("a").quantile([dyn float: 0.25])`. See
/// `Expr::sum` for the shape of the result.
///
/// # Errors
/// Evaluating raises `InvalidOperation` for `String`, `Boolean` and `Null`
/// and `ComputeError` when `q` is not in `[0, 1]` (checked after the type).
pub fn Expr::quantile(
  self : Expr,
  q : Double,
  interpolation~ : QuantileMethod = Nearest,
) -> Expr {
  Expr::of(Agg(Quantile(q, interpolation), self.node))
}

// ---------------------------------------------------------------------------
// Element-wise functions
// ---------------------------------------------------------------------------

///|
/// Whether each value is NaN: `Boolean`, null where `self` is null; integers
/// are never NaN. Evaluating raises `InvalidOperation` for `Boolean`,
/// `String`, `Date` and `Datetime`; a `Null` expression gives all null.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::float64("a", [1.0, 0.0 / 0.0])])
///   let out = df.select([@pl.col("a").is_nan()])
///   assert_eq(out.column("a").to_list(), [
///     @pl.AnyValue::Boolean(false),
///     @pl.AnyValue::Boolean(true),
///   ])
/// }
/// ```
pub fn Expr::is_nan(self : Expr) -> Expr {
  Expr::of(Func(IsNan, self.node))
}

///|
/// The opposite of `Expr::is_nan`, null where `self` is null.
pub fn Expr::is_not_nan(self : Expr) -> Expr {
  Expr::of(Func(IsNotNan, self.node))
}

///|
/// Whether each value is finite (neither NaN nor infinite); see
/// `Expr::is_nan`.
pub fn Expr::is_finite(self : Expr) -> Expr {
  Expr::of(Func(IsFinite, self.node))
}

///|
/// Whether each value is `inf` or `-inf`; see `Expr::is_nan`.
pub fn Expr::is_infinite(self : Expr) -> Expr {
  Expr::of(Func(IsInfinite, self.node))
}

///|
/// Absolute value, in the type of the expression (`Int32::MIN` and
/// `Int64::MIN` wrap around). Evaluating raises `InvalidOperation` for every
/// other type (see `Series::abs`).
pub fn Expr::abs(self : Expr) -> Expr {
  Expr::of(Func(Abs, self.node))
}

///|
/// Square root: `Float32` stays `Float32`, integers give `Float64`; a
/// negative value gives NaN. Evaluating raises `InvalidOperation` for
/// `Boolean`, `String`, `Date` and `Datetime` (see `Series::sqrt`).
pub fn Expr::sqrt(self : Expr) -> Expr {
  Expr::of(Func(Sqrt, self.node))
}

///|
/// `e` to the power of each value; see `Series::exp`.
pub fn Expr::exp(self : Expr) -> Expr {
  Expr::of(Func(Exp, self.node))
}

///|
/// Logarithm to `base` (natural by default); see `Series::log`. polars prints
/// the base: `col("a").log([dyn float: 2])`.
pub fn Expr::log(self : Expr, base~ : Double = 2.718281828459045) -> Expr {
  Expr::of(Func(Log(base), self.node))
}

///|
/// Rounds to `decimals` places (ties to even, as polars 2.1.0 does); see
/// `Series::round`. Evaluating raises `InvalidOperation` for a negative
/// `decimals`.
pub fn Expr::round(self : Expr, decimals~ : Int32 = 0) -> Expr {
  Expr::of(Func(Round(decimals), self.node))
}

///|
/// Replaces the null rows of `self` with `value`. The result type is the
/// supertype of the two (`Int32` filled with `lit_float(1.5)` is `Float64`;
/// a number with text is `String`; a weak literal adapts to `self`, so
/// `Int32` filled with `lit_int(0)` stays `Int32`). A `value` of the same
/// length fills row by row (`col("a").fill_null(col("b"))`), a length-1 value
/// (a literal, an aggregate such as `col("a").mean()`) fills every null; a
/// null in `value` leaves the row null. NaN is not null. The name is
/// `self`'s.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::int32_nullable("a", [Some(1), None, Some(3)]),
///   ])
///   let out = df.select([@pl.col("a").fill_null(@pl.lit_int(0L))])
///   assert_eq(out.column("a").to_list(), [
///     @pl.AnyValue::Int32(1),
///     @pl.AnyValue::Int32(0),
///     @pl.AnyValue::Int32(3),
///   ])
/// }
/// ```
///
/// # Errors
/// Evaluating raises `SchemaMismatch` (`failed to determine supertype of
/// bool and date`) when the two have no common type.
pub fn Expr::fill_null(self : Expr, value : Expr) -> Expr {
  Expr::of(FillNull(self.node, value.node))
}

///|
/// Whether each value is in `values`: `Boolean`, null where `self` is null;
/// see `Series::is_in` for the rules (NaN matches NaN, `Int32` and `Int64`
/// mix, nulls in `values` never match). polars prints the argument as
/// `Series[name]`.
///
/// # Errors
/// Evaluating raises `InvalidOperation` when the types do not fit
/// (`'is_in' cannot check for Int32 values in List(String) data`).
pub fn Expr::is_in(self : Expr, values : Series) -> Expr {
  Expr::of(IsIn(self.node, values))
}

///|
/// Whether each value lies between `lower` and `upper`, as
/// `(self >= lower) & (self <= upper)` (an end that `closed` leaves out is a
/// strict comparison). Both bounds may be columns, literals or aggregates;
/// weak literals adapt to `self`. The result is `Boolean`, null where the
/// comparison cannot decide (`false & null` is `false`); `lower` above
/// `upper` gives all false. The name is `self`'s.
///
/// # Errors
/// Evaluating raises what the comparisons raise: `ComputeError` for text
/// against a number, `SchemaMismatch` for other pairs without a common type,
/// `InvalidOperation` for text against a date.
pub fn Expr::between(
  self : Expr,
  lower : Expr,
  upper : Expr,
  closed~ : ClosedInterval = Both,
) -> Expr {
  Expr::of(Between(self.node, lower.node, upper.node, closed))
}
