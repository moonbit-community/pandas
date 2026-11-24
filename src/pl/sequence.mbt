///|
/// How `Series::fill_null_strategy` picks the value that replaces a null,
/// named after polars' `strategy` argument.
///
/// - `Forward` / `Backward`: the nearest non-null value before / after;
/// - `Min` / `Max` / `Mean`: the minimum, maximum or mean of the non-null
///   values (the mean of an integer, `Date` or `Datetime` series is
///   truncated towards zero);
/// - `Zero` / `One`: `0` / `1` (`false` / `true`, `""` for `Zero` on text).
#derive(Eq, @debug.Debug)
pub(all) enum FillStrategy {
  Forward
  Backward
  Min
  Max
  Mean
  Zero
  One
}

///|
/// Formats the strategy with its polars name (`forward`, `backward`, `min`,
/// `max`, `mean`, `zero`, `one`).
pub impl Show for FillStrategy with fn output(self, logger) {
  logger.write_string(
    match self {
      Forward => "forward"
      Backward => "backward"
      Min => "min"
      Max => "max"
      Mean => "mean"
      Zero => "zero"
      One => "one"
    },
  )
}

///|
/// Makes `to_string` callable as a method, giving the same polars name as
/// `Show`.
pub extend FillStrategy with Show::{to_string}

///|
/// How `Series::rank` numbers rows that compare equal, named after polars'
/// `method` argument (`random` is not offered).
///
/// - `Average`: the mean of the positions the tie group occupies (`Float64`);
/// - `Min` / `Max`: the first / last position of the group (`Int64`);
/// - `Dense`: groups are numbered 1, 2, 3, ... with no gaps (`Int64`);
/// - `Ordinal`: every row gets its own position, ties in original order
///   (`Int64`).
#derive(Eq, @debug.Debug)
pub(all) enum RankMethod {
  Average
  Min
  Max
  Dense
  Ordinal
}

///|
/// Formats the method with its polars name (`average`, `min`, `max`, `dense`,
/// `ordinal`).
pub impl Show for RankMethod with fn output(self, logger) {
  logger.write_string(
    match self {
      Average => "average"
      Min => "min"
      Max => "max"
      Dense => "dense"
      Ordinal => "ordinal"
    },
  )
}

///|
/// Makes `to_string` callable as a method, giving the same polars name as
/// `Show`.
pub extend RankMethod with Show::{to_string}

// ---------------------------------------------------------------------------
// shift
// ---------------------------------------------------------------------------

///|
/// The loop of every `shift`: for each of the `len` output rows `take(j)` is
/// called with the row `j = i - n` of the source when it exists and `fill()`
/// when it does not. `n` is widened so that `Int32::MIN` cannot overflow.
fn seq_shift_loop(
  len : Int32,
  n : Int32,
  take : (Int32) -> Unit,
  fill : () -> Unit,
) -> Unit {
  let wide = n.to_int64()
  let len64 = len.to_int64()
  for i in 0..<len {
    let src = i.to_int64() - wide
    if src >= 0L && src < len64 {
      take(src.to_int())
    } else {
      fill()
    }
  }
}

///|
/// `a` moved down by `n` rows (up for a negative `n`): row `i` takes row
/// `i - n`; rows without a source get `fill` (null for `None`).
fn[T : Default] seq_shift_prim(
  a : @arrow.PrimArray[T],
  n : Int32,
  fill : T?,
) -> @arrow.PrimArray[T] {
  let b : @arrow.PrimBuilder[T] = @arrow.PrimBuilder::new(capacity=a.length())
  seq_shift_loop(
    a.length(),
    n,
    j => if a.is_valid(j) { b.push(a.value(j)) } else { b.push_null() },
    () => b.push_option(fill),
  )
  b.finish()
}

///|
fn seq_shift_bool(
  a : @arrow.BoolArray,
  n : Int32,
  fill : Bool?,
) -> @arrow.BoolArray {
  let b = @arrow.BoolBuilder::new(capacity=a.length())
  seq_shift_loop(
    a.length(),
    n,
    j => if a.is_valid(j) { b.push(a.value(j)) } else { b.push_null() },
    () => b.push_option(fill),
  )
  b.finish()
}

///|
fn seq_shift_str(
  a : @arrow.StrArray,
  n : Int32,
  fill : String?,
) -> @arrow.StrArray {
  let b = @arrow.StrBuilder::new(capacity=a.length())
  seq_shift_loop(
    a.length(),
    n,
    j => if a.is_valid(j) { b.push(a.value(j)) } else { b.push_null() },
    () => b.push_option(fill),
  )
  b.finish()
}

///|
/// The type of `shift` with a fill value and the fill value as a column of
/// length 1 of that type, which is the supertype of the series and the value
/// (as in `fill_null`) with two polars special cases: a `Boolean` value in a
/// `Date` or `Datetime` series is read as the number 0 / 1 of days or
/// microseconds, and a `Date` or `Datetime` value in a `Boolean` series is
/// refused.
fn seq_shift_fill(
  col : Column,
  value : AnyValue,
) -> (Column, Column) raise PolarsError {
  let dt = col.dtype()
  match (dt, value) {
    (Date, Boolean(b)) =>
      return (
        col,
        Column::Date(@arrow.PrimArray::from_array([if b { 1 } else { 0 }])),
      )
    (Datetime, Boolean(b)) =>
      return (
        col,
        Column::Datetime(
          @arrow.PrimArray::from_array([if b { 1L } else { 0L }]),
        ),
      )
    (Boolean, Date(d)) =>
      raise ComputeError("fill value '\{format_date(d)}' is not supported")
    (Boolean, Datetime(t)) =>
      raise ComputeError("fill value '\{format_datetime(t)}' is not supported")
    _ => ()
  }
  let t = match ew_fill_type(dt, value.dtype()) {
    Some(t) => t
    None =>
      raise SchemaMismatch(
        "failed to determine supertype of \{dt} and \{value.dtype()}",
      )
  }
  (col.cast_lenient(t), ew_scalar_column(value).cast_lenient(t))
}

///|
/// Moves the values down by `n` rows (default 1, as in polars; up for a negative
/// `n`). The rows that
/// get no value from the series are null, or `fill_value` when it is not
/// `Null`; `n` beyond the length (either way) gives only fill rows.
///
/// The result type is the type of the series, unless a `fill_value` calls for
/// the supertype of both (the rule of `fill_null`: `Int32` with
/// `Float64(1.5)` is `Float64`, a number with a `String` is `String`, `Int32`
/// with `Int64` is `Int64`). A `Null` series with a non-null `fill_value`
/// takes the type of the value. A `Boolean` `fill_value` in a `Date` or
/// `Datetime` series counts as 0 or 1.
///
/// # Errors
/// `SchemaMismatch` when the series and the fill value have no common type;
/// `ComputeError` (``fill value '1970-04-11' is not supported``) for a `Date`
/// or `Datetime` fill value in a `Boolean` series.
pub fn Series::shift(
  self : Series,
  n~ : Int32 = 1,
  fill_value~ : AnyValue = AnyValue::Null,
) -> Series raise PolarsError {
  let (base, fill) = if fill_value is Null {
    (self.col, Column::full_null(self.col.dtype(), 1))
  } else {
    seq_shift_fill(self.col, fill_value)
  }
  let col = match (base, fill) {
    (Boolean(a), Boolean(f)) => Column::Boolean(seq_shift_bool(a, n, f.get(0)))
    (Int32(a), Int32(f)) => Column::Int32(seq_shift_prim(a, n, f.get(0)))
    (Int64(a), Int64(f)) => Column::Int64(seq_shift_prim(a, n, f.get(0)))
    (Float32(a), Float32(f)) => Column::Float32(seq_shift_prim(a, n, f.get(0)))
    (Float64(a), Float64(f)) => Column::Float64(seq_shift_prim(a, n, f.get(0)))
    (String(a), String(f)) => Column::String(seq_shift_str(a, n, f.get(0)))
    (Date(a), Date(f)) => Column::Date(seq_shift_prim(a, n, f.get(0)))
    (Datetime(a), Datetime(f)) =>
      Column::Datetime(seq_shift_prim(a, n, f.get(0)))
    (Null(len), _) => Column::Null(len)
    _ => abort("Series::shift: column and fill value differ after the cast")
  }
  Series::make(self.name, col)
}

// ---------------------------------------------------------------------------
// diff
// ---------------------------------------------------------------------------

///|
/// `a[i] - a[i - n]` where both rows exist and are valid, null elsewhere.
fn[T : Default] seq_diff_prim(
  a : @arrow.PrimArray[T],
  n : Int32,
  sub : (T, T) -> T,
) -> @arrow.PrimArray[T] {
  let len = a.length()
  let b : @arrow.PrimBuilder[T] = @arrow.PrimBuilder::new(capacity=len)
  let wide = n.to_int64()
  let len64 = len.to_int64()
  for i in 0..<len {
    let src = i.to_int64() - wide
    if src >= 0L && src < len64 && a.is_valid(i) && a.is_valid(src.to_int()) {
      b.push(sub(a.value(i), a.value(src.to_int())))
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
/// The difference of every value with the one `n` rows before it (`n` may be
/// negative: the one `-n` rows after, and `0` gives zeros). The first `n`
/// rows, and every row whose own value or partner is null, are null.
/// Integers wrap around on overflow, floats follow IEEE (`inf - inf` is NaN).
/// The result has the type of the series; a `Null` series gives `Null`.
///
/// # Errors
/// `InvalidOperation` for `Boolean`
/// (``` `subtract` operation not supported for dtype `bool` ```) and `String`
/// (``` sub operation not supported for dtypes `str` and `str` ```), and for
/// `Date` and `Datetime`, whose difference is a duration, a type this library
/// does not have.
pub fn Series::diff(self : Series, n~ : Int32 = 1) -> Series raise PolarsError {
  let col = match self.col {
    Int32(a) => Column::Int32(seq_diff_prim(a, n, (x, y) => x - y))
    Int64(a) => Column::Int64(seq_diff_prim(a, n, (x, y) => x - y))
    Float32(a) => Column::Float32(seq_diff_prim(a, n, (x, y) => x - y))
    Float64(a) => Column::Float64(seq_diff_prim(a, n, (x, y) => x - y))
    Null(len) => Column::Null(len)
    Boolean(_) =>
      raise InvalidOperation(
        "`subtract` operation not supported for dtype `bool`",
      )
    String(_) =>
      raise InvalidOperation(
        "sub operation not supported for dtypes `str` and `str`",
      )
    Date(_) | Datetime(_) =>
      raise InvalidOperation(
        "`diff` operation not supported for dtype `\{self.dtype()}`: the difference would be a duration, which this library has no type for",
      )
  }
  Series::make(self.name, col)
}

// ---------------------------------------------------------------------------
// cumulative operations
// ---------------------------------------------------------------------------

///|
/// Running fold of the valid rows in row order (or from the last row with
/// `reverse`): the first valid row is its own result, every later one is
/// `step(previous result, value)`. A null row stays null and does not
/// interrupt the run. `lift` converts a value to the result type first.
fn[T, R : Default] seq_cum_prim(
  a : @arrow.PrimArray[T],
  reverse : Bool,
  lift : (T) -> R,
  step : (R, R) -> R,
) -> @arrow.PrimArray[R] {
  let n = a.length()
  let out : FixedArray[R] = FixedArray::make(n, Default::default())
  let mut acc : R = Default::default()
  let mut has = false
  for k in 0..<n {
    let i = if reverse { n - 1 - k } else { k }
    if a.is_valid(i) {
      let x = lift(a.value(i))
      acc = if has { step(acc, x) } else { x }
      has = true
      out[i] = acc
    }
  }
  @arrow.PrimArray::new(out, a.validity())
}

///|
/// `seq_cum_prim` for a `Boolean` column read as 0 / 1, with an `Int64`
/// result (`cum_sum`, `cum_prod`).
fn seq_cum_bool_int(
  a : @arrow.BoolArray,
  reverse : Bool,
  step : (Int64, Int64) -> Int64,
) -> @arrow.PrimArray[Int64] {
  let n = a.length()
  let out : FixedArray[Int64] = FixedArray::make(n, 0L)
  let mut acc = 0L
  let mut has = false
  for k in 0..<n {
    let i = if reverse { n - 1 - k } else { k }
    if a.is_valid(i) {
      let x = if a.value(i) { 1L } else { 0L }
      acc = if has { step(acc, x) } else { x }
      has = true
      out[i] = acc
    }
  }
  @arrow.PrimArray::new(out, a.validity())
}

///|
/// Running minimum (`is_max` false) or maximum of a `Boolean` column.
fn seq_cum_bool_extreme(
  a : @arrow.BoolArray,
  reverse : Bool,
  is_max : Bool,
) -> @arrow.BoolArray {
  let n = a.length()
  let out : Array[Bool] = Array::make(n, false)
  let mut acc = false
  let mut has = false
  for k in 0..<n {
    let i = if reverse { n - 1 - k } else { k }
    if a.is_valid(i) {
      let x = a.value(i)
      acc = if !has { x } else if is_max { acc || x } else { acc && x }
      has = true
      out[i] = acc
    }
  }
  @arrow.BoolArray::new(@arrow.Bitmap::from_array(out), a.validity())
}

///|
/// Running minimum or maximum of a `String` column by code point.
fn seq_cum_str_extreme(
  a : @arrow.StrArray,
  reverse : Bool,
  is_max : Bool,
) -> @arrow.StrArray {
  let n = a.length()
  let out : FixedArray[String] = FixedArray::make(n, "")
  let mut acc = ""
  let mut has = false
  for k in 0..<n {
    let i = if reverse { n - 1 - k } else { k }
    if a.is_valid(i) {
      let x = a.value(i)
      acc = if !has {
        x
      } else {
        let c = str_cmp(x, acc)
        if (is_max && c >= 0) || (!is_max && c <= 0) {
          x
        } else {
          acc
        }
      }
      has = true
      out[i] = acc
    }
  }
  @arrow.StrArray::new(out, a.validity())
}

///|
/// Step of a running minimum / maximum over integers: on a tie the newer
/// value wins (it is equal anyway).
fn[T : Compare] seq_ext_step(is_max : Bool) -> (T, T) -> T {
  if is_max {
    (p, x) => if x >= p { x } else { p }
  } else {
    (p, x) => if x <= p { x } else { p }
  }
}

///|
/// Step of a running minimum / maximum over floats: a NaN never replaces a
/// number (a leading NaN is replaced by the first number), and on a tie
/// (`-0.0` and `0.0`) the newer value wins, as in polars.
fn[T : Compare] seq_float_ext_step(is_max : Bool) -> (T, T) -> T {
  if is_max {
    (p, x) => {
      if x != x {
        p
      } else if p != p {
        x
      } else if x >= p {
        x
      } else {
        p
      }
    }
  } else {
    (p, x) => {
      if x != x {
        p
      } else if p != p {
        x
      } else if x <= p {
        x
      } else {
        p
      }
    }
  }
}

///|
fn[T] seq_cum_unsupported(op : String, dt : DataType) -> T raise PolarsError {
  raise InvalidOperation("`\{op}` operation not supported for dtype `\{dt}`")
}

///|
/// Running minimum or maximum (`cum_min`, `cum_max`) of a column.
fn seq_cum_extreme(
  col : Column,
  reverse : Bool,
  is_max : Bool,
) -> Column raise PolarsError {
  match col {
    Boolean(a) => Column::Boolean(seq_cum_bool_extreme(a, reverse, is_max))
    Int32(a) =>
      Column::Int32(seq_cum_prim(a, reverse, x => x, seq_ext_step(is_max)))
    Int64(a) =>
      Column::Int64(seq_cum_prim(a, reverse, x => x, seq_ext_step(is_max)))
    Float32(a) =>
      Column::Float32(
        seq_cum_prim(a, reverse, x => x, seq_float_ext_step(is_max)),
      )
    Float64(a) =>
      Column::Float64(
        seq_cum_prim(a, reverse, x => x, seq_float_ext_step(is_max)),
      )
    String(a) => Column::String(seq_cum_str_extreme(a, reverse, is_max))
    Date(a) =>
      Column::Date(seq_cum_prim(a, reverse, x => x, seq_ext_step(is_max)))
    Datetime(a) =>
      Column::Datetime(seq_cum_prim(a, reverse, x => x, seq_ext_step(is_max)))
    Null(_) =>
      seq_cum_unsupported(
        if is_max {
          "cum_max"
        } else {
          "cum_min"
        },
        col.dtype(),
      )
  }
}

///|
/// Running sum of the non-null values: `Int32` and `Int64` wrap around on
/// overflow, floats keep their width (a NaN makes every later value NaN),
/// `Boolean` counts the true values as `Int64`. A null row stays null and is
/// skipped; with `reverse` the run starts at the last row.
///
/// # Errors
/// `InvalidOperation` for `String`, `Date`, `Datetime` and `Null`
/// (``` `cum_sum` operation not supported for dtype `str` ```).
pub fn Series::cum_sum(
  self : Series,
  reverse~ : Bool = false,
) -> Series raise PolarsError {
  let col = match self.col {
    Boolean(a) => Column::Int64(seq_cum_bool_int(a, reverse, (p, x) => p + x))
    Int32(a) => Column::Int32(seq_cum_prim(a, reverse, x => x, (p, x) => p + x))
    Int64(a) => Column::Int64(seq_cum_prim(a, reverse, x => x, (p, x) => p + x))
    // the run starts from 0.0, so a leading -0.0 gives 0.0 as in polars
    Float32(a) =>
      Column::Float32(
        seq_cum_prim(a, reverse, x => (0.0 : Float) + x, (p, x) => p + x),
      )
    Float64(a) =>
      Column::Float64(seq_cum_prim(a, reverse, x => 0.0 + x, (p, x) => p + x))
    String(_) | Date(_) | Datetime(_) | Null(_) =>
      seq_cum_unsupported("cum_sum", self.dtype())
  }
  Series::make(self.name, col)
}

///|
/// Running product: integers and `Boolean` multiply as `Int64` (wrapping
/// around), floats keep their width. A null row stays null and is skipped;
/// with `reverse` the run starts at the last row.
///
/// # Errors
/// `InvalidOperation` for `String`, `Date`, `Datetime` and `Null`.
pub fn Series::cum_prod(
  self : Series,
  reverse~ : Bool = false,
) -> Series raise PolarsError {
  let col = match self.col {
    Boolean(a) => Column::Int64(seq_cum_bool_int(a, reverse, (p, x) => p * x))
    Int32(a) =>
      Column::Int64(
        seq_cum_prim(a, reverse, x => x.to_int64(), (p, x) => p * x),
      )
    Int64(a) => Column::Int64(seq_cum_prim(a, reverse, x => x, (p, x) => p * x))
    Float32(a) =>
      Column::Float32(seq_cum_prim(a, reverse, x => x, (p, x) => p * x))
    Float64(a) =>
      Column::Float64(seq_cum_prim(a, reverse, x => x, (p, x) => p * x))
    String(_) | Date(_) | Datetime(_) | Null(_) =>
      seq_cum_unsupported("cum_prod", self.dtype())
  }
  Series::make(self.name, col)
}

///|
/// Running minimum of the non-null values, of the type of the series. A NaN
/// is ignored unless it comes first (the first number replaces it); strings
/// compare by code point. A null row stays null and is skipped; with
/// `reverse` the run starts at the last row.
///
/// # Errors
/// `InvalidOperation` for `Null`.
pub fn Series::cum_min(
  self : Series,
  reverse~ : Bool = false,
) -> Series raise PolarsError {
  Series::make(self.name, seq_cum_extreme(self.col, reverse, false))
}

///|
/// Running maximum of the non-null values; the rules of `cum_min`.
///
/// # Errors
/// `InvalidOperation` for `Null`.
pub fn Series::cum_max(
  self : Series,
  reverse~ : Bool = false,
) -> Series raise PolarsError {
  Series::make(self.name, seq_cum_extreme(self.col, reverse, true))
}

///|
/// The number of non-null values up to and including each row, as an `Int64`
/// series without nulls (a null row repeats the count so far, and a `Null`
/// series gives zeros). With `reverse` the count runs from the last row.
pub fn Series::cum_count(self : Series, reverse~ : Bool = false) -> Series {
  let n = self.col.length()
  let out : FixedArray[Int64] = FixedArray::make(n, 0L)
  let validity = self.col.validity()
  let mut count = 0L
  for k in 0..<n {
    let i = if reverse { n - 1 - k } else { k }
    let valid = match validity {
      None => true
      Some(v) => v.get(i)
    }
    if valid {
      count += 1L
    }
    out[i] = count
  }
  Series::make(self.name, Int64(@arrow.PrimArray::new(out, None)))
}

// ---------------------------------------------------------------------------
// reverse
// ---------------------------------------------------------------------------

///|
/// The rows in the opposite order; name, type and nulls are kept.
pub fn Series::reverse(self : Series) -> Series {
  let n = self.col.length()
  Series::make(self.name, self.col.gather(Array::makei(n, i => n - 1 - i)))
}

// ---------------------------------------------------------------------------
// rank
// ---------------------------------------------------------------------------

///|
/// Ranks the non-null values (1 is the smallest, or the largest with
/// `descending`); a null row stays null and takes no rank.
///
/// Equal values (`-0.0` and `0.0`, and every NaN, are equal) are numbered by
/// `method_`. The result is a `Float64` series for `Average` and an `Int64`
/// series for the other methods; a `Null` series gives all nulls of that
/// type. The order is `Series::sort`'s (NaN above every number, strings by
/// code point, stable), computed in O(n log n); `Ordinal` ranks of equal
/// values follow the original order also for `descending`.
pub fn Series::rank(
  self : Series,
  method_~ : RankMethod = Average,
  descending~ : Bool = false,
) -> Series {
  let n = self.col.length()
  let avg = method_ is Average
  if self.col is Null(_) {
    let t = if avg { DataType::Float64 } else { DataType::Int64 }
    return Series::make(self.name, Column::full_null(t, n))
  }
  let order = arg_sort_columns([self.col], [descending], [true])
  let valid = n - self.col.null_count()
  let cmp = self.col.value_cmp(false)
  let ints : FixedArray[Int64] = FixedArray::make(if avg { 0 } else { n }, 0L)
  let floats : FixedArray[Double] = FixedArray::make(
    if avg {
      n
    } else {
      0
    },
    0.0,
  )
  let mut start = 0
  let mut dense = 0L
  while start < valid {
    let mut stop = start + 1
    while stop < valid && cmp(order[start], order[stop]) == 0 {
      stop += 1
    }
    dense += 1L
    for k in start..<stop {
      let row = order[k]
      match method_ {
        Average => floats[row] = (start + 1 + stop).to_double() / 2.0
        Min => ints[row] = (start + 1).to_int64()
        Max => ints[row] = stop.to_int64()
        Dense => ints[row] = dense
        Ordinal => ints[row] = (k + 1).to_int64()
      }
    }
    start = stop
  }
  let col = if avg {
    Column::Float64(@arrow.PrimArray::new(floats, self.col.validity()))
  } else {
    Column::Int64(@arrow.PrimArray::new(ints, self.col.validity()))
  }
  Series::make(self.name, col)
}

// ---------------------------------------------------------------------------
// fill_null with a strategy
// ---------------------------------------------------------------------------

///|
/// `col` with its null rows replaced by the only row of `fill` (a column of
/// the same type; a null `fill` changes nothing).
fn seq_fill_scalar(col : Column, fill : Column) -> Column {
  match (col, fill) {
    (Boolean(a), Boolean(f)) => Column::Boolean(ew_fill_bool(a, f))
    (Int32(a), Int32(f)) => Column::Int32(ew_fill_prim(a, f))
    (Int64(a), Int64(f)) => Column::Int64(ew_fill_prim(a, f))
    (Float32(a), Float32(f)) => Column::Float32(ew_fill_prim(a, f))
    (Float64(a), Float64(f)) => Column::Float64(ew_fill_prim(a, f))
    (String(a), String(f)) => Column::String(ew_fill_str(a, f))
    (Date(a), Date(f)) => Column::Date(ew_fill_prim(a, f))
    (Datetime(a), Datetime(f)) => Column::Datetime(ew_fill_prim(a, f))
    _ => col
  }
}

///|
/// Nulls take the nearest earlier (`forward`) or later valid value, at most
/// `limit` rows away from it (counted over consecutive nulls). The rows are
/// gathered, so the nulls that stay null stay null of the same type.
fn seq_fill_directional(col : Column, forward : Bool, limit : Int32?) -> Column {
  let n = col.length()
  if col.null_count() == 0 {
    return col
  }
  let max_run = match limit {
    Some(l) => l.to_int64()
    None => 9223372036854775807L
  }
  let src : Array[Int32] = Array::makei(n, i => i)
  let valid = col.validity().unwrap()
  let mut last = -1
  let mut run = 0L
  for k in 0..<n {
    let i = if forward { k } else { n - 1 - k }
    if valid.get(i) {
      last = i
      run = 0L
    } else if last >= 0 {
      run += 1L
      if run <= max_run {
        src[i] = last
      }
    }
  }
  col.gather(src)
}

///|
/// The mean of an integer, `Date` or `Datetime` column truncated towards
/// zero, as a column of length 1 of the same type (null when there is no
/// value). A mean beyond `Int64` (rounding in the sum) is clamped.
fn seq_mean_truncated(col : Column) -> Column {
  let count = col.length() - col.null_count()
  if count == 0 {
    return Column::full_null(col.dtype(), 1)
  }
  let m = agg_pairwise_sum(agg_doubles(col, pad=true)) / count.to_double()
  let v = match double_to_int64(m) {
    Some(x) => x
    None => if m > 0.0 { 9223372036854775807L } else { -9223372036854775808L }
  }
  match col {
    Int32(_) => Column::Int32(@arrow.PrimArray::from_array([v.to_int()]))
    Int64(_) => Column::Int64(@arrow.PrimArray::from_array([v]))
    Date(_) => Column::Date(@arrow.PrimArray::from_array([v.to_int()]))
    _ => Column::Datetime(@arrow.PrimArray::from_array([v]))
  }
}

///|
/// The fill value of `Zero` (`one` false) or `One`, as a column of length 1.
fn seq_zero_one(col : Column, one : Bool) -> Column raise PolarsError {
  match col {
    Boolean(_) => Column::Boolean(@arrow.BoolArray::from_array([one]))
    Int32(_) =>
      Column::Int32(@arrow.PrimArray::from_array([if one { 1 } else { 0 }]))
    Int64(_) =>
      Column::Int64(@arrow.PrimArray::from_array([if one { 1L } else { 0L }]))
    Float32(_) =>
      Column::Float32(
        @arrow.PrimArray::from_array([if one { (1.0 : Float) } else { 0.0 }]),
      )
    Float64(_) =>
      Column::Float64(
        @arrow.PrimArray::from_array([if one { 1.0 } else { 0.0 }]),
      )
    Date(_) =>
      Column::Date(@arrow.PrimArray::from_array([if one { 1 } else { 0 }]))
    Datetime(_) =>
      Column::Datetime(
        @arrow.PrimArray::from_array([if one { 1L } else { 0L }]),
      )
    String(_) =>
      if one {
        raise InvalidOperation("fill-null strategy One is not supported")
      } else {
        Column::String(@arrow.StrArray::from_array([""]))
      }
    Null(_) =>
      raise InvalidOperation(
        "fill null strategy not yet supported for dtype: null",
      )
  }
}

///|
/// Replaces the null rows by a value chosen with `strategy`; the result has
/// the type of the series (a `Null` series stays `Null` for every strategy
/// that needs no value).
///
/// - `Forward` / `Backward` copy the nearest valid value before / after a
///   null; with `limit`, a null is filled only when it is at most `limit`
///   rows away from that value (`limit` 0 fills nothing). Nulls with no valid
///   value on that side stay null.
/// - `Min`, `Max`, `Mean` use the aggregations of `Series::min`, `max`,
///   `mean` (so NaN is ignored by `Min` / `Max`); `Mean` of integers,
///   `Date` and `Datetime` is truncated towards zero. A series with no
///   value stays null.
/// - `Zero`, `One`: `0` / `1` (`false` / `true`; `Date` as 1970-01-01 plus 0 /
///   1 days, `Datetime` plus 0 / 1 microseconds; `""` for `Zero` on text).
///
/// A series without a null is returned as it is, and so is a series of only
/// nulls under `Mean`, whatever the type; the errors below come first only for
/// `limit`.
///
/// # Errors
/// `InvalidOperation` when
/// - `limit` is given with another strategy than `Forward` / `Backward`
///   (``can only specify `limit` when strategy is set to 'backward' or 'forward'``)
///   or is negative (`number too small to fit in target type`, polars'
///   `OverflowError`);
/// - `Mean` is asked of `Boolean` (``` `mean` operation not supported for dtype `Boolean` ```)
///   or `String` (`fill-null strategy Mean is not supported`);
/// - `One` is asked of `String` (`fill-null strategy One is not supported`),
///   or `Zero` / `One` of `Null` (`fill null strategy not yet supported for dtype: null`).
pub fn Series::fill_null_strategy(
  self : Series,
  strategy : FillStrategy,
  limit? : Int32,
) -> Series raise PolarsError {
  let directional = strategy is (Forward | Backward)
  match limit {
    Some(l) =>
      if !directional {
        raise InvalidOperation(
          "can only specify `limit` when strategy is set to 'backward' or 'forward'",
        )
      } else if l < 0 {
        raise InvalidOperation("number too small to fit in target type")
      }
    None => ()
  }
  let col = self.col
  // nothing to fill: the series is returned as it is, whatever the strategy
  // (also for the types that strategy is refused for)
  if col.null_count() == 0 {
    return self
  }
  let out = match strategy {
    Forward => seq_fill_directional(col, true, limit)
    Backward => seq_fill_directional(col, false, limit)
    Min => seq_fill_scalar(col, agg_column(col, AggOp::Min))
    Max => seq_fill_scalar(col, agg_column(col, AggOp::Max))
    Mean =>
      match col {
        // no value to average: unchanged, whatever the type
        _ if col.null_count() == col.length() => col
        Boolean(_) =>
          raise InvalidOperation(
            "`mean` operation not supported for dtype `Boolean`",
          )
        String(_) =>
          raise InvalidOperation("fill-null strategy Mean is not supported")
        Null(_) => col
        Int32(_) | Int64(_) | Date(_) | Datetime(_) =>
          seq_fill_scalar(col, seq_mean_truncated(col))
        Float32(_) | Float64(_) =>
          seq_fill_scalar(col, agg_column(col, AggOp::Mean))
      }
    Zero => seq_fill_scalar(col, seq_zero_one(col, false))
    One => seq_fill_scalar(col, seq_zero_one(col, true))
  }
  Series::make(self.name, out)
}
