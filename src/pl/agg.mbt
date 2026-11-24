///|
/// How `Series::quantile` picks a value between two neighbours of the sorted
/// non-null values, named after polars' `interpolation` argument.
///
/// With `n` values and quantile `q`, the position is `p = (n - 1) * q`:
/// - `Nearest`: the value at `p` rounded (halves away from zero);
/// - `Higher` / `Lower`: the value at `ceil(p)` / `floor(p)`;
/// - `Midpoint`: the mean of the values at `floor(p)` and `ceil(p)`;
/// - `Linear`: linear interpolation between them;
/// - `Equiprobable`: the value at `max(ceil(n * q) - 1, 0)`.
#derive(Eq, @debug.Debug)
pub(all) enum QuantileMethod {
  Nearest
  Higher
  Lower
  Midpoint
  Linear
  Equiprobable
}

///|
/// Formats the method with its polars name (`nearest`, `higher`, `lower`,
/// `midpoint`, `linear`, `equiprobable`).
pub impl Show for QuantileMethod with fn output(self, logger) {
  logger.write_string(
    match self {
      Nearest => "nearest"
      Higher => "higher"
      Lower => "lower"
      Midpoint => "midpoint"
      Linear => "linear"
      Equiprobable => "equiprobable"
    },
  )
}

///|
/// Makes `to_string` callable as a method, giving the same polars name as
/// `Show`.
pub extend QuantileMethod with Show::{to_string}

///|
/// An aggregation over one column. `Std` and `Var` carry the delta degrees
/// of freedom.
priv enum AggOp {
  Sum
  Mean
  Min
  Max
  Count
  Len
  First
  Last
  Std(Int32)
  Var(Int32)
  Median
  Quantile(Double, QuantileMethod)
  Product
}

///|
/// The name polars uses for the operation in its error messages.
fn AggOp::name(self : AggOp) -> String {
  match self {
    Sum => "sum"
    Mean => "mean"
    Min => "min"
    Max => "max"
    Count => "count"
    Len => "len"
    First => "first"
    Last => "last"
    Std(_) => "std"
    Var(_) => "var"
    Median => "median"
    Quantile(_, _) => "quantile"
    Product => "product"
  }
}

///|
fn[T] agg_unsupported(op : AggOp, dt : DataType) -> T raise PolarsError {
  raise InvalidOperation(
    "`\{op.name()}` operation not supported for dtype `\{dt}`",
  )
}

///|
fn agg_col_i64(v : Int64?) -> Column {
  Int64(@arrow.PrimArray::from_options([v]))
}

///|
fn agg_col_f64(v : Double?) -> Column {
  Float64(@arrow.PrimArray::from_options([v]))
}

///|
/// The values of a numeric, Boolean or temporal column as doubles (Boolean as
/// 0 / 1, Date as days, Datetime as microseconds). A null row is left out, or
/// with `pad` kept as 0.0 (the layout polars sums over). Empty for the other
/// types.
fn agg_doubles(col : Column, pad~ : Bool = false) -> Array[Double] {
  let out : Array[Double] = []
  match col {
    Boolean(a) =>
      for i in 0..<a.length() {
        if a.is_valid(i) {
          out.push(if a.value(i) { 1.0 } else { 0.0 })
        } else if pad {
          out.push(0.0)
        }
      }
    Int32(a) | Date(a) =>
      for i in 0..<a.length() {
        if a.is_valid(i) {
          out.push(a.value(i).to_double())
        } else if pad {
          out.push(0.0)
        }
      }
    Int64(a) | Datetime(a) =>
      for i in 0..<a.length() {
        if a.is_valid(i) {
          out.push(a.value(i).to_double())
        } else if pad {
          out.push(0.0)
        }
      }
    Float32(a) =>
      for i in 0..<a.length() {
        if a.is_valid(i) {
          out.push(a.value(i).to_double())
        } else if pad {
          out.push(0.0)
        }
      }
    Float64(a) =>
      for i in 0..<a.length() {
        if a.is_valid(i) {
          out.push(a.value(i))
        } else if pad {
          out.push(0.0)
        }
      }
    String(_) | Null(_) => ()
  }
  out
}

///|
/// Sequential sum of `xs[lo:hi]` from zero.
fn[T : Add + Default] agg_seq_sum(xs : Array[T], lo : Int32, hi : Int32) -> T {
  let mut acc : T = Default::default()
  for i in lo..<hi {
    acc = acc + xs[i]
  }
  acc
}

///|
/// Sum of the 128 values from `start` on: 16 interleaved partial sums that are
/// folded half onto half.
fn[T : Add + Default] agg_block_sum(xs : Array[T], start : Int32) -> T {
  let lanes : Array[T] = Array::make(16, Default::default())
  for j in 0..<128 {
    lanes[j % 16] = lanes[j % 16] + xs[start + j]
  }
  let mut width = 8
  while width >= 1 {
    for i in 0..<width {
      lanes[i] = lanes[i] + lanes[i + width]
    }
    width = width / 2
  }
  lanes[0]
}

///|
fn[T : Add] agg_tree_sum(parts : Array[T], lo : Int32, hi : Int32) -> T {
  if hi - lo == 1 {
    parts[lo]
  } else {
    let mid = lo + (hi - lo) / 2
    agg_tree_sum(parts, lo, mid) + agg_tree_sum(parts, mid, hi)
  }
}

///|
/// Pairwise sum, the order polars adds floats in (checked bit for bit against
/// polars 2.1.0 up to 1e5 values): fewer than 128 values are added in order;
/// otherwise the `n % 128` leading values are added in order, the remaining
/// blocks of 128 are each summed by `agg_block_sum`, and the block sums are
/// added by halving the block list recursively.
fn[T : Add + Default] agg_pairwise_sum(xs : Array[T]) -> T {
  let n = xs.length()
  if n < 128 {
    return agg_seq_sum(xs, 0, n)
  }
  let r = n % 128
  let blocks : Array[T] = []
  let mut start = r
  while start < n {
    blocks.push(agg_block_sum(xs, start))
    start += 128
  }
  let total = agg_tree_sum(blocks, 0, blocks.length())
  if r > 0 {
    agg_seq_sum(xs, 0, r) + total
  } else {
    total
  }
}

///|
/// Wraps a double computed from `col` as the result column of a "real valued"
/// aggregation: `Float32` for a `Float32` column, a `Datetime` (microseconds,
/// truncated towards zero) for `Date` and `Datetime`, `Float64` otherwise.
fn agg_real_result(col : Column, v : Double?) -> Column {
  match col {
    Float32(_) =>
      Float32(
        @arrow.PrimArray::from_options([
          match v {
            Some(x) => Some(Float::from_double(x))
            None => None
          },
        ]),
      )
    Date(_) =>
      Datetime(
        @arrow.PrimArray::from_options([
          match v {
            Some(x) => double_to_int64(x * 86400000000.0)
            None => None
          },
        ]),
      )
    Datetime(_) =>
      Datetime(
        @arrow.PrimArray::from_options([
          match v {
            Some(x) => double_to_int64(x)
            None => None
          },
        ]),
      )
    _ => agg_col_f64(v)
  }
}

///|
/// Sum of the non-null values; integers wrap around, Boolean counts the true
/// values (as `Int64`), floats add in their own width.
fn agg_sum(col : Column) -> Column raise PolarsError {
  match col {
    Boolean(a) => {
      let mut n = 0L
      for i in 0..<a.length() {
        if a.is_valid(i) && a.value(i) {
          n += 1L
        }
      }
      agg_col_i64(Some(n))
    }
    Int32(a) => {
      let mut acc = 0
      for i in 0..<a.length() {
        if a.is_valid(i) {
          acc += a.value(i)
        }
      }
      Int32(@arrow.PrimArray::from_array([acc]))
    }
    Int64(a) => {
      let mut acc = 0L
      for i in 0..<a.length() {
        if a.is_valid(i) {
          acc += a.value(i)
        }
      }
      agg_col_i64(Some(acc))
    }
    Float32(a) => {
      // null rows count as 0.0, so the pairwise layout is that of the column
      let xs : Array[Float] = Array::make(a.length(), 0.0)
      for i in 0..<a.length() {
        if a.is_valid(i) {
          xs[i] = a.value(i)
        }
      }
      Float32(@arrow.PrimArray::from_array([agg_pairwise_sum(xs)]))
    }
    Float64(_) =>
      agg_col_f64(Some(agg_pairwise_sum(agg_doubles(col, pad=true))))
    Null(_) => Null(1)
    String(_) | Date(_) | Datetime(_) => agg_unsupported(Sum, col.dtype())
  }
}

///|
/// Product of the non-null values; integers and Boolean multiply as `Int64`
/// (wrapping around), floats in their own width. The empty product is 1.
fn agg_product(col : Column) -> Column raise PolarsError {
  match col {
    Boolean(a) => {
      let mut acc = 1L
      for i in 0..<a.length() {
        if a.is_valid(i) && !a.value(i) {
          acc = 0L
        }
      }
      agg_col_i64(Some(acc))
    }
    Int32(a) => {
      let mut acc = 1L
      for i in 0..<a.length() {
        if a.is_valid(i) {
          acc = acc * a.value(i).to_int64()
        }
      }
      agg_col_i64(Some(acc))
    }
    Int64(a) => {
      let mut acc = 1L
      for i in 0..<a.length() {
        if a.is_valid(i) {
          acc = acc * a.value(i)
        }
      }
      agg_col_i64(Some(acc))
    }
    Float32(a) => {
      let mut acc : Float = 1.0
      for i in 0..<a.length() {
        if a.is_valid(i) {
          acc = acc * a.value(i)
        }
      }
      Float32(@arrow.PrimArray::from_array([acc]))
    }
    Float64(a) => {
      let mut acc = 1.0
      for i in 0..<a.length() {
        if a.is_valid(i) {
          acc *= a.value(i)
        }
      }
      agg_col_f64(Some(acc))
    }
    Null(_) | String(_) | Date(_) | Datetime(_) =>
      agg_unsupported(Product, col.dtype())
  }
}

///|
/// Mean of the non-null values: the pairwise sum (null rows as 0.0, as polars
/// sums them) divided by the number of non-null values, in `Float64`.
fn agg_mean(col : Column) -> Column raise PolarsError {
  match col {
    Null(_) => Null(1)
    String(_) => agg_unsupported(Mean, col.dtype())
    _ => {
      let count = col.length() - col.null_count()
      if count == 0 {
        return agg_real_result(col, None)
      }
      let sum = agg_pairwise_sum(agg_doubles(col, pad=true))
      agg_real_result(col, Some(sum / count.to_double()))
    }
  }
}

///|
/// Variance with `ddof` delta degrees of freedom by two passes: the mean
/// first, then the sum of the squared deviations from it (both pairwise sums),
/// which stays accurate for values with a large common offset; `None` when
/// there are no more than `ddof` values.
fn agg_variance(xs : Array[Double], ddof : Int32) -> Double? {
  let n = xs.length()
  if n <= ddof {
    return None
  }
  let mean = agg_pairwise_sum(xs) / n.to_double()
  let dev : Array[Double] = Array::make(n, 0.0)
  for i in 0..<n {
    let d = xs[i] - mean
    dev[i] = d * d
  }
  Some(agg_pairwise_sum(dev) / (n - ddof).to_double())
}

///|
/// Standard deviation (`is_std`) or variance of the non-null values.
fn agg_var(
  col : Column,
  ddof : Int32,
  is_std : Bool,
) -> Column raise PolarsError {
  let op = if is_std { AggOp::Std(ddof) } else { AggOp::Var(ddof) }
  if ddof < 0 {
    raise InvalidOperation("ddof must not be negative, got \{ddof}")
  }
  match col {
    Null(_) => Null(1)
    String(_) | Date(_) | Datetime(_) => agg_unsupported(op, col.dtype())
    _ => {
      let v = agg_variance(agg_doubles(col), ddof)
      agg_real_result(col, if is_std { v.map(x => x.sqrt()) } else { v })
    }
  }
}

///|
/// Total order of doubles with NaN after every number.
fn agg_double_cmp(x : Double, y : Double) -> Int32 {
  if x < y {
    -1
  } else if x > y {
    1
  } else if x == y {
    0
  } else if x.is_nan() {
    if y.is_nan() {
      0
    } else {
      1
    }
  } else {
    -1
  }
}

///|
/// Rounds a non-negative position to the nearest index, halves up.
fn agg_round_index(p : Double) -> Double {
  let f = p.floor()
  if p - f >= 0.5 {
    f + 1.0
  } else {
    f
  }
}

///|
/// Where polars reads for the quantile `q` (already validated to lie in
/// `[0, 1]`) of `n` non-null values in a column with `nulls` null rows:
/// the indexes into the sorted non-null values of the lower and the upper
/// neighbour, the clamped base position (in the column that sorts its nulls
/// first) and the position itself.
///
/// This is polars' computation, step for step, so that the floating point
/// rounding agrees too: the position `(n - 1) * q + nulls` is taken in the
/// column that sorts its nulls first, `lo` and `hi` are the values at its floor
/// and ceiling.
fn agg_quantile_ranks(
  n : Int32,
  nulls : Int32,
  q : Double,
  how : QuantileMethod,
) -> (Int32, Int32, Double, Double) {
  let skip = nulls.to_double()
  let top = n.to_double() - 1.0 + skip
  let pos = (n.to_double() - 1.0) * q + skip
  let base = match how {
    Nearest => agg_round_index(pos)
    Higher => pos.ceil()
    Lower | Midpoint | Linear => pos.floor()
    Equiprobable => {
      let k = (n.to_double() * q).ceil() - 1.0
      (if k < 0.0 { 0.0 } else { k }) + skip
    }
  }
  let base = if base < skip { skip } else if base > top { top } else { base }
  let upper = if pos.ceil() > top { top } else { pos.ceil() }
  ((base - skip).to_int(), (upper - skip).to_int(), base, pos)
}

///|
/// The quantile from its two neighbours: `Linear` is
/// `lo + (position - base) * (hi - lo)`; equal neighbours give `lo` for every
/// method (so equal infinities stay infinite).
fn agg_quantile_combine(
  lo : Double,
  hi : Double,
  same : Bool,
  base : Double,
  pos : Double,
  how : QuantileMethod,
) -> Double {
  match how {
    Nearest | Higher | Lower | Equiprobable => lo
    Midpoint => if same || lo == hi { lo } else { (lo + hi) / 2.0 }
    Linear => if same || lo == hi { lo } else { lo + (pos - base) * (hi - lo) }
  }
}

///|
/// The quantile `q` (already validated) of `sorted`, the non-null values
/// sorted with `agg_double_cmp`, where `nulls` rows of the column were null;
/// `None` for no values.
fn agg_quantile_sorted(
  sorted : Array[Double],
  nulls : Int32,
  q : Double,
  how : QuantileMethod,
) -> Double? {
  let n = sorted.length()
  if n == 0 {
    return None
  }
  let (li, hi, base, pos) = agg_quantile_ranks(n, nulls, q, how)
  Some(agg_quantile_combine(sorted[li], sorted[hi], li == hi, base, pos, how))
}

///|
/// Rearranges `xs` so that `xs[k]` is the value a full sort with
/// `agg_double_cmp` would put there, everything before it is not greater and
/// everything after it not smaller (quickselect with a median-of-three pivot
/// and a three-way partition; after about `2 log2 n` rounds the rest is sorted,
/// so the worst case is O(n log n)).
fn agg_select(xs : Array[Double], k : Int32) -> Unit {
  let mut lo = 0
  let mut hi = xs.length() - 1
  let mut budget = 8
  let mut size = xs.length()
  while size > 1 {
    budget += 2
    size = size / 2
  }
  while hi > lo {
    if budget == 0 {
      xs.mut_view(start=lo, end=hi + 1).sort_by(agg_double_cmp)
      return
    }
    budget -= 1
    let mid = lo + (hi - lo) / 2
    let a = xs[lo]
    let b = xs[mid]
    let c = xs[hi]
    let pivot = if agg_double_cmp(a, b) < 0 {
      if agg_double_cmp(b, c) < 0 {
        b
      } else if agg_double_cmp(a, c) < 0 {
        c
      } else {
        a
      }
    } else if agg_double_cmp(a, c) < 0 {
      a
    } else if agg_double_cmp(b, c) < 0 {
      c
    } else {
      b
    }
    // [lo, lt) < pivot, [lt, gt] == pivot, (gt, hi] > pivot
    let mut lt = lo
    let mut i = lo
    let mut gt = hi
    while i <= gt {
      let c = agg_double_cmp(xs[i], pivot)
      if c < 0 {
        let t = xs[lt]
        xs[lt] = xs[i]
        xs[i] = t
        lt += 1
        i += 1
      } else if c > 0 {
        let t = xs[gt]
        xs[gt] = xs[i]
        xs[i] = t
        gt -= 1
      } else {
        i += 1
      }
    }
    if k < lt {
      hi = lt - 1
    } else if k > gt {
      lo = gt + 1
    } else {
      return
    }
  }
}

///|
/// The element a *stable* sort puts at rank `rank` when its value is `v`.
/// Only `0.0` / `-0.0` and NaN can be equal without being the same bits; for
/// those the answer is the `(rank - #smaller)`-th equal element in the order
/// of `original()` (the values in their original order), as a stable sort
/// would leave it.
fn agg_stable_pick(
  v : Double,
  rank : Int32,
  original : () -> Array[Double],
) -> Double {
  if v == 0.0 || v != v {
    let orig = original()
    let mut less = 0
    for x in orig {
      if agg_double_cmp(x, v) < 0 {
        less += 1
      }
    }
    let target = rank - less
    let mut seen = 0
    for x in orig {
      if agg_double_cmp(x, v) == 0 {
        if seen == target {
          return x
        }
        seen += 1
      }
    }
  }
  v
}

///|
/// The quantile `q` (already validated to lie in `[0, 1]`) of `xs`, where
/// `nulls` rows of the column were null; `None` for no values. `xs` is
/// rearranged (selection, not a full sort); `original` gives the values in
/// their original order again for the rare tie of `0.0` with `-0.0` or of
/// NaNs, so the result is bit for bit what a stable full sort would read.
fn agg_quantile_value(
  xs : Array[Double],
  nulls : Int32,
  q : Double,
  how : QuantileMethod,
  original : () -> Array[Double],
) -> Double? {
  let n = xs.length()
  if n == 0 {
    return None
  }
  let (li, hi, base, pos) = agg_quantile_ranks(n, nulls, q, how)
  agg_select(xs, li)
  let lo_v = agg_stable_pick(xs[li], li, original)
  let uses_hi = match how {
    Midpoint | Linear => true
    _ => false
  }
  let hi_v = if !uses_hi || hi == li {
    lo_v
  } else if hi == li + 1 {
    // everything after `li` is not smaller: the next rank is the minimum
    let mut m = xs[hi]
    for j in (li + 1)..<n {
      if agg_double_cmp(xs[j], m) < 0 {
        m = xs[j]
      }
    }
    agg_stable_pick(m, hi, original)
  } else {
    agg_select(xs, hi)
    agg_stable_pick(xs[hi], hi, original)
  }
  Some(agg_quantile_combine(lo_v, hi_v, li == hi, base, pos, how))
}

///|
/// One result column per quantile of `qs` (each validated to lie in `[0, 1]`
/// by the caller) of a numeric column, sorting the values only once: for
/// `describe`, which asks for several percentiles of the same column.
fn agg_quantile_columns(
  col : Column,
  qs : Array[Double],
  how : QuantileMethod,
) -> Array[Column] {
  let xs = agg_doubles(col)
  xs.mut_view().stable_sort_by(agg_double_cmp)
  let nulls = col.null_count()
  qs.map(q => agg_real_result(col, agg_quantile_sorted(xs, nulls, q, how)))
}

///|
/// Text of a quantile in an error message, as polars prints it.
fn agg_quantile_text(q : Double) -> String {
  if q.is_nan() {
    "NaN"
  } else if q.is_pos_inf() {
    "inf"
  } else if q.is_neg_inf() {
    "-inf"
  } else {
    q.to_string()
  }
}

///|
/// Median (`q = 0.5`, linear) or quantile of the non-null values.
fn agg_quantile(
  col : Column,
  op : AggOp,
  q : Double,
  how : QuantileMethod,
) -> Column raise PolarsError {
  match col {
    Null(_) =>
      match op {
        Median => Null(1)
        _ => agg_unsupported(op, col.dtype())
      }
    String(_) => agg_unsupported(op, col.dtype())
    Boolean(_) =>
      match op {
        Median =>
          agg_real_result(
            col,
            agg_quantile_value(agg_doubles(col), col.null_count(), q, how, () => {
              agg_doubles(col)
            }),
          )
        _ => agg_unsupported(op, col.dtype())
      }
    _ => {
      if q.is_nan() || q < 0.0 || q > 1.0 {
        raise ComputeError(
          "quantile should be between 0.0 and 1.0, got \{agg_quantile_text(q)}",
        )
      }
      agg_real_result(
        col,
        agg_quantile_value(agg_doubles(col), col.null_count(), q, how, () => {
          agg_doubles(col)
        }),
      )
    }
  }
}

///|
/// Smallest (`is_max` false) or largest non-null value. A NaN is ignored
/// unless every value is NaN; of equal values (the two zeros) the last wins.
fn[T : Compare] agg_extreme(a : @arrow.PrimArray[T], is_max : Bool) -> T? {
  let mut best : T? = None
  let mut nan : T? = None
  for i in 0..<a.length() {
    if !a.is_valid(i) {
      continue
    }
    let x = a.value(i)
    if x != x {
      if nan is None {
        nan = Some(x)
      }
      continue
    }
    match best {
      None => best = Some(x)
      Some(b) => if (is_max && x >= b) || (!is_max && x <= b) { best = Some(x) }
    }
  }
  match best {
    None => nan
    Some(_) => best
  }
}

///|
/// Smallest or largest non-null string by code point.
fn agg_str_extreme(a : @arrow.StrArray, is_max : Bool) -> String? {
  let mut best : String? = None
  for i in 0..<a.length() {
    if !a.is_valid(i) {
      continue
    }
    let x = a.value(i)
    match best {
      None => best = Some(x)
      Some(b) => {
        let c = str_cmp(x, b)
        if (is_max && c > 0) || (!is_max && c < 0) {
          best = Some(x)
        }
      }
    }
  }
  best
}

///|
fn agg_min_max(col : Column, is_max : Bool) -> Column {
  match col {
    Boolean(a) => {
      let mut any = false
      let mut has_true = false
      let mut has_false = false
      for i in 0..<a.length() {
        if a.is_valid(i) {
          any = true
          if a.value(i) {
            has_true = true
          } else {
            has_false = true
          }
        }
      }
      let v : Bool? = if !any {
        None
      } else if is_max {
        Some(has_true)
      } else {
        Some(!has_false)
      }
      Boolean(@arrow.BoolArray::from_options([v]))
    }
    Int32(a) => Int32(@arrow.PrimArray::from_options([agg_extreme(a, is_max)]))
    Int64(a) => Int64(@arrow.PrimArray::from_options([agg_extreme(a, is_max)]))
    Float32(a) =>
      Float32(@arrow.PrimArray::from_options([agg_extreme(a, is_max)]))
    Float64(a) =>
      Float64(@arrow.PrimArray::from_options([agg_extreme(a, is_max)]))
    String(a) =>
      String(@arrow.StrArray::from_options([agg_str_extreme(a, is_max)]))
    Date(a) => Date(@arrow.PrimArray::from_options([agg_extreme(a, is_max)]))
    Datetime(a) =>
      Datetime(@arrow.PrimArray::from_options([agg_extreme(a, is_max)]))
    Null(_) => Null(1)
  }
}

///|
/// The row at `index` as a column of length 1 (a null of the column's type
/// when the column is empty).
fn agg_pick(col : Column, index : Int32) -> Column {
  if col.length() == 0 {
    Column::full_null(col.dtype(), 1)
  } else {
    col.gather([index])
  }
}

///|
/// Aggregates `col` to a column of length 1 whose type follows polars (with
/// the library's types: polars' `UInt32` counts are `Int64`):
///
/// - `Sum`: `Int32`, `Int64`, `Float32`, `Float64` keep their type, Boolean
///   gives `Int64`; the sum of nothing is 0, `Null` gives `Null`.
/// - `Mean`, `Median`: `Float64` (`Float32` for `Float32`, `Datetime` for
///   `Date` and `Datetime`); a null for no values.
/// - `Min`, `Max`, `First`, `Last`: the column's type; `First` and `Last`
///   keep a null row.
/// - `Count`, `Len`: `Int64`.
/// - `Std`, `Var`: like `Mean`, but not for `Date`, `Datetime`.
/// - `Quantile`: like `Median`, not for Boolean and `Null`.
/// - `Product`: `Int64` for integers and Boolean, else the column's type;
///   not for `Null`, text or temporal types.
///
/// # Errors
/// `InvalidOperation` for a type the operation is not defined for,
/// `ComputeError` for a quantile outside `[0, 1]`, `InvalidOperation` for a
/// negative `ddof`.
fn agg_column(col : Column, op : AggOp) -> Column raise PolarsError {
  match op {
    Sum => agg_sum(col)
    Product => agg_product(col)
    Mean => agg_mean(col)
    Min => agg_min_max(col, false)
    Max => agg_min_max(col, true)
    Count => agg_col_i64(Some((col.length() - col.null_count()).to_int64()))
    Len => agg_col_i64(Some(col.length().to_int64()))
    First => agg_pick(col, 0)
    Last => agg_pick(col, col.length() - 1)
    Std(ddof) => agg_var(col, ddof, true)
    Var(ddof) => agg_var(col, ddof, false)
    Median => agg_quantile(col, Median, 0.5, Linear)
    Quantile(q, how) => agg_quantile(col, op, q, how)
  }
}

///|
/// Sum of the non-null values: `Int32` and `Int64` wrap around on overflow,
/// `Float32`/`Float64` keep their type, Boolean counts the true values as an
/// `Int64`. The sum of no values is 0; a `Null` series gives `Null`.
///
/// # Errors
/// Raises `InvalidOperation` for `String`, `Date` and `Datetime`.
pub fn Series::sum(self : Series) -> AnyValue raise PolarsError {
  agg_column(self.col, Sum).get(0)
}

///|
/// Mean of the non-null values: `Float64` (`Float32` for a `Float32` series,
/// `Datetime` for `Date` and `Datetime`). `Null` when there are no values.
///
/// # Errors
/// Raises `InvalidOperation` for `String`.
pub fn Series::mean(self : Series) -> AnyValue raise PolarsError {
  agg_column(self.col, Mean).get(0)
}

///|
/// Smallest non-null value, of the series' type. Strings compare by code
/// point; a NaN is ignored unless every value is NaN. `Null` when there are
/// no values.
pub fn Series::min(self : Series) -> AnyValue raise PolarsError {
  agg_column(self.col, Min).get(0)
}

///|
/// Largest non-null value, of the series' type; see `Series::min`.
pub fn Series::max(self : Series) -> AnyValue raise PolarsError {
  agg_column(self.col, Max).get(0)
}

///|
/// The first value, which may be null; `Null` for an empty series.
pub fn Series::first(self : Series) -> AnyValue raise PolarsError {
  agg_column(self.col, First).get(0)
}

///|
/// The last value, which may be null; `Null` for an empty series.
pub fn Series::last(self : Series) -> AnyValue raise PolarsError {
  agg_column(self.col, Last).get(0)
}

///|
/// Median of the non-null values (the mean of the two middle ones for an even
/// count): `Float64` (`Float32` for a `Float32` series, `Datetime` for `Date`
/// and `Datetime`). `Null` when there are no values.
///
/// # Errors
/// Raises `InvalidOperation` for `String`.
pub fn Series::median(self : Series) -> AnyValue raise PolarsError {
  agg_column(self.col, Median).get(0)
}

///|
/// Product of the non-null values: `Int64` for integers and Boolean (wrapping
/// around on overflow), `Float32`/`Float64` for floats. The product of no
/// values is 1.
///
/// # Errors
/// Raises `InvalidOperation` for `String`, `Date`, `Datetime` and `Null`.
pub fn Series::product(self : Series) -> AnyValue raise PolarsError {
  agg_column(self.col, Product).get(0)
}

///|
/// Standard deviation of the non-null values with `ddof` delta degrees of
/// freedom (default 1): `Float64` (`Float32` for a `Float32` series). `Null`
/// when there are no more than `ddof` values.
///
/// # Errors
/// Raises `InvalidOperation` for `String`, `Date` and `Datetime`, and for a
/// negative `ddof`.
pub fn Series::std(
  self : Series,
  ddof~ : Int32 = 1,
) -> AnyValue raise PolarsError {
  agg_column(self.col, Std(ddof)).get(0)
}

///|
/// Variance of the non-null values (polars' `var`; `var` is a MoonBit
/// keyword); see `Series::std`.
pub fn Series::var_(
  self : Series,
  ddof~ : Int32 = 1,
) -> AnyValue raise PolarsError {
  agg_column(self.col, Var(ddof)).get(0)
}

///|
/// The quantile `q` of the non-null values, picked or interpolated by
/// `interpolation` (see `QuantileMethod`): `Float64` (`Float32` for a `Float32`
/// series, `Datetime` for `Date` and `Datetime`). `Null` when there are no
/// values.
///
/// # Errors
/// Raises `InvalidOperation` for `String`, Boolean and `Null` series, and
/// `ComputeError` when `q` is not in `[0, 1]` (checked after the type).
pub fn Series::quantile(
  self : Series,
  q : Double,
  interpolation~ : QuantileMethod = Nearest,
) -> AnyValue raise PolarsError {
  agg_column(self.col, Quantile(q, interpolation)).get(0)
}

///|
/// Number of non-null values.
pub fn Series::count(self : Series) -> Int32 {
  self.len() - self.null_count()
}
