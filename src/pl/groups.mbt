// Grouping rows by key columns and aggregating a column per group.
//
// `GroupIndex` is the result of hashing the key columns once: the group of
// every row and the rows of every group. `grouped_agg` then aggregates a
// column in one pass over the rows for the common operations and gives, group
// by group, bit for bit what `agg_column` gives on the rows of that group.

// ---------------------------------------------------------------------------
// The index
// ---------------------------------------------------------------------------

///|
/// The rows of a table split into groups of equal key. Groups are numbered
/// in order of first appearance; `rows(g)` lists the rows of a group in
/// ascending order.
///
/// A group may have no rows only in the two cases `group_by` allows: a frame
/// without rows grouped by no key (one group, `GroupIndex::from_keys([], 0)`)
/// and one-row keys next to a frame without rows (`GroupIndex::ghost`).
priv struct GroupIndex {
  n_groups : Int32
  /// the group of each row
  ids : Array[Int32]
  /// `starts[g]..starts[g + 1]` is the slice of `flat` holding group `g`
  starts : Array[Int32]
  /// the rows of group 0, then those of group 1, ...
  flat : Array[Int32]
  /// the first row of each group (0 for a group without rows)
  firsts : Array[Int32]
  /// all rows are one group by construction (no key, or keys that are one
  /// value each: a literal, an aggregation): polars aggregates such a group
  /// with the kernels of `select` (`Column`-wide pairwise sums), not the ones
  /// it uses for the groups of a key column
  whole : Bool
}

///|
/// Builds the index from the group of each row.
fn GroupIndex::from_ids(
  ids : Array[Int32],
  n_groups : Int32,
  firsts : Array[Int32],
) -> GroupIndex {
  let n = ids.length()
  let starts : Array[Int32] = Array::make(n_groups + 1, 0)
  for g in ids {
    starts[g + 1] += 1
  }
  for g in 0..<n_groups {
    starts[g + 1] += starts[g]
  }
  let next : Array[Int32] = Array::make(n_groups, 0)
  for g in 0..<n_groups {
    next[g] = starts[g]
  }
  let flat : Array[Int32] = Array::make(n, 0)
  for i in 0..<n {
    let g = ids[i]
    flat[next[g]] = i
    next[g] += 1
  }
  { n_groups, ids, starts, flat, firsts, whole: false, }
}

///|
/// The same index, marked as one group of every row made by keys that are one
/// value each (see `whole`).
fn GroupIndex::as_whole(self : GroupIndex) -> GroupIndex {
  { ..self, whole: true, }
}

///|
/// Groups the rows `0..<height` by equal rows of `keys` (null equals null,
/// NaN equals NaN, `-0.0` equals `0.0`, as in `unique`); the groups are
/// numbered by first appearance. With no key column all rows are one group,
/// also when there are none. O(height).
///
/// # Panics
/// Aborts when a key column is not `height` long.
fn GroupIndex::from_keys(keys : Array[Column], height : Int32) -> GroupIndex {
  if keys.length() == 0 {
    return GroupIndex::from_ids(Array::make(height, 0), 1, [0]).as_whole()
  }
  for c in keys {
    if c.length() != height {
      abort("GroupIndex::from_keys: a key column is not \{height} rows long")
    }
  }
  let table = GroupTable::new(if height < 64 { height } else { 64 })
  let ids : Array[Int32] = Array::make(height, 0)
  for i in 0..<height {
    let h = row_hash(keys, i)
    let found = table.find(h, keys, keys, i)
    ids[i] = if found < 0 { table.add(h, i) } else { found }
  }
  GroupIndex::from_ids(ids, table.length(), table.group_row)
}

///|
/// One group without rows, for the one-row keys of a frame without rows
/// (`group_by(lit(1))` on a frame with no rows is one empty group in polars).
fn GroupIndex::ghost() -> GroupIndex {
  GroupIndex::from_ids([], 1, [0])
}

///|
fn GroupIndex::length(self : GroupIndex) -> Int32 {
  self.n_groups
}

///|
/// The group row `row` belongs to.
#warnings("-unused_value")
fn GroupIndex::group_of(self : GroupIndex, row : Int32) -> Int32 {
  self.ids[row]
}

///|
/// The rows of group `g`, ascending.
fn GroupIndex::rows(self : GroupIndex, g : Int32) -> ArrayView[Int32] {
  self.flat[self.starts[g]:self.starts[g + 1]]
}

///|
/// Number of rows of group `g`.
fn GroupIndex::size(self : GroupIndex, g : Int32) -> Int32 {
  self.starts[g + 1] - self.starts[g]
}

///|
/// The first row of every group (0 for a group without rows).
fn GroupIndex::first_rows(self : GroupIndex) -> Array[Int32] {
  self.firsts
}

///|
/// The last row of every group (0 for a group without rows).
fn GroupIndex::last_rows(self : GroupIndex) -> Array[Int32] {
  let out : Array[Int32] = Array(capacity=self.n_groups)
  for g in 0..<self.n_groups {
    out.push(
      if self.size(g) == 0 {
        0
      } else {
        self.flat[self.starts[g + 1] - 1]
      },
    )
  }
  out
}

///|
/// The number of rows of every group.
fn GroupIndex::sizes(self : GroupIndex) -> Array[Int32] {
  let out : Array[Int32] = Array(capacity=self.n_groups)
  for g in 0..<self.n_groups {
    out.push(self.size(g))
  }
  out
}

// ---------------------------------------------------------------------------
// The group_by flavour of the aggregations
// ---------------------------------------------------------------------------
//
// polars does not aggregate a group the way it aggregates a whole column:
// `group_by(...).agg(col("x").sum())` adds floats with Kahan summation (the
// sum of a whole column is the blocked pairwise sum of `agg_sum`), and
// `mean`, `var` and `std` follow (the mean is the Kahan sum over the count,
// the variance Welford's online algorithm, both in double precision, the
// result cast to `Float32` for a `Float32` column). The results differ in the
// last digits, so the golden data pins this flavour. Everything else
// (integer sums, min, max, count, first, last, median, quantile, product,
// n_unique) aggregates exactly as `agg_column` does.

///|
/// Kahan summation of `xs` in order (polars' float `sum` in a `group_by`). The
/// compensation is dropped once the running sum is not finite, so an infinity
/// (or an overflow) stays an infinity instead of turning into NaN.
fn kahan_sum(xs : Array[Double]) -> Double {
  let mut s = 0.0
  let mut c = 0.0
  for x in xs {
    let y = x - c
    let t = s + y
    c = if t - t == 0.0 { t - s - y } else { 0.0 }
    s = t
  }
  s
}

///|
/// `kahan_sum` in `Float` arithmetic.
fn kahan_sum_f32(xs : Array[Float]) -> Float {
  let mut s : Float = 0.0
  let mut c : Float = 0.0
  for x in xs {
    let y = x - c
    let t = s + y
    c = if t - t == 0.0 { t - s - y } else { 0.0 }
    s = t
  }
  s
}

///|
/// Welford's online variance of `xs` with `ddof` delta degrees of freedom;
/// `None` when there are no more than `ddof` values.
fn welford_variance(xs : Array[Double], ddof : Int32) -> Double? {
  if xs.length() <= ddof {
    return None
  }
  let mut n = 0
  let mut mean = 0.0
  let mut m2 = 0.0
  for x in xs {
    n += 1
    let d = x - mean
    mean = mean + d / n.to_double()
    m2 = m2 + d * (x - mean)
  }
  Some(m2 / (n - ddof).to_double())
}

///|
/// Whether the group_by variance and standard deviation are defined for the
/// column: not for text, `Date`, `Datetime` or a negative `ddof` (`agg_column`
/// raises for those) and not for a `Null` column (all null).
fn group_has_variance(col : Column, ddof : Int32) -> Bool {
  if ddof < 0 {
    return false
  }
  match col {
    String(_) | Date(_) | Datetime(_) | Null(_) => false
    _ => true
  }
}

///|
/// The Kahan sum `xs` of the non-null values of `col`, except that polars
/// returns the value itself for a group of one row (so `-0.0` stays `-0.0`).
fn group_double_sum(col : Column, xs : Array[Double]) -> Double {
  if col.length() == 1 && xs.length() == 1 {
    xs[0]
  } else {
    kahan_sum(xs)
  }
}

///|
/// Aggregates `col` to a column of length 1 as polars does for one group of a
/// `group_by` (see above): `agg_column` for everything but the float `sum`
/// and the `mean`, `std` and `var` of a numeric column.
///
/// # Errors
/// What `agg_column` raises.
fn group_agg_column(col : Column, op : AggOp) -> Column raise PolarsError {
  match (op, col) {
    (Sum, Float32(a)) =>
      if a.length() == 1 && a.is_valid(0) {
        col
      } else {
        let xs : Array[Float] = []
        for i in 0..<a.length() {
          if a.is_valid(i) {
            xs.push(a.value(i))
          }
        }
        Float32(@arrow.PrimArray::from_array([kahan_sum_f32(xs)]))
      }
    (Sum, Float64(_)) =>
      agg_col_f64(Some(group_double_sum(col, agg_doubles(col))))
    (Mean, Null(_) | String(_)) => agg_column(col, op)
    (Mean, _) => {
      let xs = agg_doubles(col)
      agg_real_result(
        col,
        if xs.length() == 0 {
          None
        } else {
          Some(group_double_sum(col, xs) / xs.length().to_double())
        },
      )
    }
    (Std(ddof), _) if group_has_variance(col, ddof) =>
      agg_real_result(
        col,
        welford_variance(agg_doubles(col), ddof).map(v => v.sqrt()),
      )
    (Var(ddof), _) if group_has_variance(col, ddof) =>
      agg_real_result(col, welford_variance(agg_doubles(col), ddof))
    _ => agg_column(col, op)
  }
}

///|
/// `group_agg_column` with the quantile error as `xagg_agg` words it: the
/// aggregation of a series, named like it.
fn group_xagg(s : Series, op : AggOp) -> Series raise PolarsError {
  Series::make(s.name, group_agg_column(s.col, op)) catch {
    ComputeError(m) if s.null_count() > 0 && m.has_prefix("quantile should") =>
      raise ComputeError("`quantile` " + m[9:].to_owned())
    e => raise e
  }
}

// ---------------------------------------------------------------------------
// Aggregation
// ---------------------------------------------------------------------------

///|
/// The reference: aggregates the rows of each group with `group_agg_column`
/// and puts the results one under the other. Every faster path below has to
/// give the same column.
fn grouped_agg_generic(
  col : Column,
  groups : GroupIndex,
  op : AggOp,
) -> Column raise PolarsError {
  let parts : Array[Column] = Array(capacity=groups.n_groups)
  for g in 0..<groups.n_groups {
    parts.push(group_agg_column(col.gather(groups.rows(g).to_owned()), op))
  }
  Column::concat(parts)
}

///|
/// Number of non-null values of each group.
fn grouped_counts(col : Column, groups : GroupIndex) -> Array[Int32] {
  match col.validity() {
    None => groups.sizes()
    Some(valid) => {
      let out : Array[Int32] = Array::make(groups.n_groups, 0)
      let ids = groups.ids
      for i in 0..<ids.length() {
        if valid.get(i) {
          out[ids[i]] += 1
        }
      }
      out
    }
  }
}

///|
fn grouped_int64_column(xs : Array[Int32]) -> Column {
  let b : @arrow.PrimBuilder[Int64] = @arrow.PrimBuilder::new(
    capacity=xs.length(),
  )
  for x in xs {
    b.push(x.to_int64())
  }
  Int64(b.finish())
}

///|
/// The value of row `i` of a numeric, Boolean or temporal column as a double
/// (0.0 for a null: check `is_valid` first).
fn Column::double_value(self : Column, i : Int32) -> Double {
  match self {
    Boolean(a) => if a.value(i) { 1.0 } else { 0.0 }
    Int32(a) | Date(a) => a.value(i).to_double()
    Int64(a) | Datetime(a) => a.value(i).to_double()
    Float32(a) => a.value(i).to_double()
    Float64(a) => a.value(i)
    String(_) | Null(_) => 0.0
  }
}

///|
/// Calls `f(group, value)` for the non-null rows of a numeric, Boolean or
/// temporal column, in row order, with the value as a double. (The loops for
/// `Int64` and `Float64` are written out: they are the common ones.)
fn grouped_each_double(
  col : Column,
  groups : GroupIndex,
  f : (Int32, Double) -> Unit,
) -> Unit {
  let ids = groups.ids
  match col {
    Int64(a) | Datetime(a) =>
      for i in 0..<ids.length() {
        if a.is_valid(i) {
          f(ids[i], a.value(i).to_double())
        }
      }
    Float64(a) =>
      for i in 0..<ids.length() {
        if a.is_valid(i) {
          f(ids[i], a.value(i))
        }
      }
    _ =>
      for i in 0..<ids.length() {
        if col.is_valid(i) {
          f(ids[i], col.double_value(i))
        }
      }
  }
}

///|
/// The Kahan sum of each group over its non-null values as doubles (the value itself for a group of one row), as
/// `kahan_sum` on the values of the group.
fn grouped_kahan_sums(col : Column, groups : GroupIndex) -> Array[Double] {
  let s : Array[Double] = Array::make(groups.n_groups, 0.0)
  let c : Array[Double] = Array::make(groups.n_groups, 0.0)
  grouped_each_double(col, groups, (g, x) => {
    let y = x - c[g]
    let t = s[g] + y
    c[g] = if t - t == 0.0 { t - s[g] - y } else { 0.0 }
    s[g] = t
  })
  for g in 0..<groups.n_groups {
    if groups.size(g) == 1 {
      let r = groups.rows(g)[0]
      if col.is_valid(r) {
        s[g] = col.double_value(r)
      }
    }
  }
  s
}

///|
/// `Float32` sums, Kahan in `Float` arithmetic like `kahan_sum_f32`.
fn grouped_float32_sums(
  a : @arrow.PrimArray[Float],
  groups : GroupIndex,
) -> Column {
  let ng = groups.n_groups
  let ids = groups.ids
  let s : Array[Float] = Array::make(ng, 0.0)
  let c : Array[Float] = Array::make(ng, 0.0)
  for i in 0..<ids.length() {
    if a.is_valid(i) {
      let g = ids[i]
      let y = a.value(i) - c[g]
      let t = s[g] + y
      c[g] = if t - t == 0.0 { t - s[g] - y } else { 0.0 }
      s[g] = t
    }
  }
  for g in 0..<ng {
    if groups.size(g) == 1 {
      let r = groups.rows(g)[0]
      if a.is_valid(r) {
        s[g] = a.value(r)
      }
    }
  }
  Float32(@arrow.PrimArray::from_array(s))
}

///|
/// The column of the real valued aggregations (`mean`, `std`, `var`):
/// `vals[g]` where `has[g]`, null elsewhere; `Float32` for a `Float32`
/// column, a `Datetime` (microseconds, truncated towards zero) for `Date`
/// (the values are days) and `Datetime`, `Float64` otherwise, as
/// `agg_real_result`.
fn grouped_real_column(
  col : Column,
  vals : Array[Double],
  has : Array[Bool],
) -> Column {
  let ng = vals.length()
  match col {
    Float32(_) => {
      let b : @arrow.PrimBuilder[Float] = @arrow.PrimBuilder::new(capacity=ng)
      for g in 0..<ng {
        if has[g] {
          b.push(Float::from_double(vals[g]))
        } else {
          b.push_null()
        }
      }
      Float32(b.finish())
    }
    Date(_) | Datetime(_) => {
      let scale = if col is Date(_) { 86400000000.0 } else { 1.0 }
      let b : @arrow.PrimBuilder[Int64] = @arrow.PrimBuilder::new(capacity=ng)
      for g in 0..<ng {
        if has[g] {
          b.push_option(double_to_int64(vals[g] * scale))
        } else {
          b.push_null()
        }
      }
      Datetime(b.finish())
    }
    _ => {
      let b : @arrow.PrimBuilder[Double] = @arrow.PrimBuilder::new(capacity=ng)
      for g in 0..<ng {
        if has[g] {
          b.push(vals[g])
        } else {
          b.push_null()
        }
      }
      Float64(b.finish())
    }
  }
}

///|
/// Sum of each group; `None` for the types `agg_sum` refuses.
fn grouped_sum(col : Column, groups : GroupIndex) -> Column? {
  let ng = groups.n_groups
  let ids = groups.ids
  let n = ids.length()
  match col {
    Boolean(a) => {
      let acc : Array[Int64] = Array::make(ng, 0L)
      for i in 0..<n {
        if a.is_valid(i) && a.value(i) {
          acc[ids[i]] += 1L
        }
      }
      Some(Int64(@arrow.PrimArray::from_array(acc)))
    }
    Int32(a) => {
      let acc : Array[Int32] = Array::make(ng, 0)
      for i in 0..<n {
        if a.is_valid(i) {
          let g = ids[i]
          acc[g] = acc[g] + a.value(i)
        }
      }
      Some(Int32(@arrow.PrimArray::from_array(acc)))
    }
    Int64(a) => {
      let acc : Array[Int64] = Array::make(ng, 0L)
      for i in 0..<n {
        if a.is_valid(i) {
          let g = ids[i]
          acc[g] = acc[g] + a.value(i)
        }
      }
      Some(Int64(@arrow.PrimArray::from_array(acc)))
    }
    Float32(a) => Some(grouped_float32_sums(a, groups))
    Float64(_) =>
      Some(
        Float64(@arrow.PrimArray::from_array(grouped_kahan_sums(col, groups))),
      )
    Null(_) => Some(Null(ng))
    String(_) | Date(_) | Datetime(_) => None
  }
}

///|
/// Mean of each group, the Kahan sum over the count; `None` for `String`.
fn grouped_mean(col : Column, groups : GroupIndex) -> Column? {
  let ng = groups.n_groups
  match col {
    Null(_) => Some(Null(ng))
    String(_) => None
    _ => {
      let sums = grouped_kahan_sums(col, groups)
      let counts = grouped_counts(col, groups)
      let vals : Array[Double] = Array::make(ng, 0.0)
      let has : Array[Bool] = Array::make(ng, false)
      for g in 0..<ng {
        if counts[g] > 0 {
          vals[g] = sums[g] / counts[g].to_double()
          has[g] = true
        }
      }
      Some(grouped_real_column(col, vals, has))
    }
  }
}

///|
/// Variance (`is_std` false) or standard deviation of each group by Welford's
/// online algorithm; the column must satisfy `group_has_variance`.
fn grouped_variance(
  col : Column,
  groups : GroupIndex,
  ddof : Int32,
  is_std : Bool,
) -> Column {
  let ng = groups.n_groups
  let n : Array[Int32] = Array::make(ng, 0)
  let mean : Array[Double] = Array::make(ng, 0.0)
  let m2 : Array[Double] = Array::make(ng, 0.0)
  grouped_each_double(col, groups, (g, x) => {
    n[g] = n[g] + 1
    let d = x - mean[g]
    mean[g] = mean[g] + d / n[g].to_double()
    m2[g] = m2[g] + d * (x - mean[g])
  })
  let vals : Array[Double] = Array::make(ng, 0.0)
  let has : Array[Bool] = Array::make(ng, false)
  for g in 0..<ng {
    if n[g] > ddof {
      let v = m2[g] / (n[g] - ddof).to_double()
      vals[g] = if is_std { v.sqrt() } else { v }
      has[g] = true
    }
  }
  grouped_real_column(col, vals, has)
}

///|
/// Smallest or largest non-null value of each group, with the rules of
/// `agg_extreme`: a NaN counts only when a group has nothing else, and of
/// equal values (the two zeros) the last wins.
fn[T : Compare + Default] grouped_extreme(
  a : @arrow.PrimArray[T],
  groups : GroupIndex,
  is_max : Bool,
) -> @arrow.PrimArray[T] {
  let ng = groups.n_groups
  let ids = groups.ids
  let best : Array[T] = Array::make(ng, Default::default())
  let has : Array[Bool] = Array::make(ng, false)
  let nan : Array[T] = Array::make(ng, Default::default())
  let has_nan : Array[Bool] = Array::make(ng, false)
  for i in 0..<ids.length() {
    if !a.is_valid(i) {
      continue
    }
    let g = ids[i]
    let x = a.value(i)
    if x != x {
      if !has_nan[g] {
        has_nan[g] = true
        nan[g] = x
      }
      continue
    }
    if !has[g] {
      has[g] = true
      best[g] = x
    } else {
      let b = best[g]
      if (is_max && x >= b) || (!is_max && x <= b) {
        best[g] = x
      }
    }
  }
  let out : @arrow.PrimBuilder[T] = @arrow.PrimBuilder::new(capacity=ng)
  for g in 0..<ng {
    if has[g] {
      out.push(best[g])
    } else if has_nan[g] {
      out.push(nan[g])
    } else {
      out.push_null()
    }
  }
  out.finish()
}

///|
/// Smallest or largest string of each group, by code point.
fn grouped_str_extreme(
  a : @arrow.StrArray,
  groups : GroupIndex,
  is_max : Bool,
) -> @arrow.StrArray {
  let ng = groups.n_groups
  let ids = groups.ids
  let best : Array[Int32] = Array::make(ng, -1)
  for i in 0..<ids.length() {
    if !a.is_valid(i) {
      continue
    }
    let g = ids[i]
    if best[g] < 0 {
      best[g] = i
    } else {
      let c = str_cmp(a.value(i), a.value(best[g]))
      if (is_max && c > 0) || (!is_max && c < 0) {
        best[g] = i
      }
    }
  }
  let out = @arrow.StrBuilder::new(capacity=ng)
  for g in 0..<ng {
    if best[g] < 0 {
      out.push_null()
    } else {
      out.push(a.value(best[g]))
    }
  }
  out.finish()
}

///|
fn grouped_bool_extreme(
  a : @arrow.BoolArray,
  groups : GroupIndex,
  is_max : Bool,
) -> @arrow.BoolArray {
  let ng = groups.n_groups
  let ids = groups.ids
  let any : Array[Bool] = Array::make(ng, false)
  let has_true : Array[Bool] = Array::make(ng, false)
  let has_false : Array[Bool] = Array::make(ng, false)
  for i in 0..<ids.length() {
    if a.is_valid(i) {
      let g = ids[i]
      any[g] = true
      if a.value(i) {
        has_true[g] = true
      } else {
        has_false[g] = true
      }
    }
  }
  let out = @arrow.BoolBuilder::new(capacity=ng)
  for g in 0..<ng {
    if !any[g] {
      out.push_null()
    } else if is_max {
      out.push(has_true[g])
    } else {
      out.push(!has_false[g])
    }
  }
  out.finish()
}

///|
fn grouped_min_max(col : Column, groups : GroupIndex, is_max : Bool) -> Column {
  match col {
    Boolean(a) => Boolean(grouped_bool_extreme(a, groups, is_max))
    Int32(a) => Int32(grouped_extreme(a, groups, is_max))
    Int64(a) => Int64(grouped_extreme(a, groups, is_max))
    Float32(a) => Float32(grouped_extreme(a, groups, is_max))
    Float64(a) => Float64(grouped_extreme(a, groups, is_max))
    String(a) => String(grouped_str_extreme(a, groups, is_max))
    Date(a) => Date(grouped_extreme(a, groups, is_max))
    Datetime(a) => Datetime(grouped_extreme(a, groups, is_max))
    Null(_) => Null(groups.n_groups)
  }
}

///|
/// Aggregates `col` (as long as the frame the groups index) to one value per
/// group: a column as long as the groups are many. The value of group `g`
/// is, bit for bit and of the same type, what `group_agg_column` gives on the
/// rows of that group (also for a group without rows, and for no groups at
/// all, where the result has the type `agg_column` gives on an empty column).
/// That is `agg_column` except for the float `sum` and the `mean`, `std` and
/// `var` of a numeric column, which follow polars' `group_by` (see
/// `group_agg_column`).
///
/// `count`, `len`, `first`, `last`, `sum`, `mean`, `std`, `var`, `min` and
/// `max` are computed in one pass over the rows; the others aggregate the
/// rows of each group with `group_agg_column`.
///
/// # Errors
/// What `agg_column` raises for the type (`InvalidOperation`, `ComputeError`).
fn grouped_agg(
  col : Column,
  groups : GroupIndex,
  op : AggOp,
) -> Column raise PolarsError {
  if groups.n_groups == 0 {
    return group_agg_column(col.slice(0, 0), op).slice(0, 0)
  }
  if col.length() != groups.ids.length() {
    abort("grouped_agg: the column is not as long as the grouped frame")
  }
  if groups.ids.length() == 0 {
    // only a group without rows: not worth a special path
    return grouped_agg_generic(col, groups, op)
  }
  // one group by construction: polars uses the kernels of `select` for the
  // float sums and their relatives, not the ones of a key column's groups
  if groups.whole && op is (Sum | Mean | Std(_) | Var(_)) {
    return agg_column(col, op)
  }
  let fast : Column? = match op {
    Count => Some(grouped_int64_column(grouped_counts(col, groups)))
    Len => Some(grouped_int64_column(groups.sizes()))
    First => Some(col.gather(groups.first_rows()))
    Last => Some(col.gather(groups.last_rows()))
    Sum => grouped_sum(col, groups)
    Mean => grouped_mean(col, groups)
    Std(ddof) =>
      if group_has_variance(col, ddof) {
        Some(grouped_variance(col, groups, ddof, true))
      } else {
        None
      }
    Var(ddof) =>
      if group_has_variance(col, ddof) {
        Some(grouped_variance(col, groups, ddof, false))
      } else {
        None
      }
    Min => Some(grouped_min_max(col, groups, false))
    Max => Some(grouped_min_max(col, groups, true))
    _ => None
  }
  match fast {
    Some(c) => c
    None => grouped_agg_generic(col, groups, op)
  }
}

///|
/// Number of distinct values of `col` in each group (null counts as a value,
/// NaN is one value, `-0.0` equals `0.0`), an `Int64` column: the distinct
/// (group, value) pairs are counted per group with one hash table.
fn grouped_n_unique(col : Column, groups : GroupIndex) -> Column {
  let ng = groups.n_groups
  let n = groups.ids.length()
  let counts : Array[Int32] = Array::make(ng, 0)
  if n > 0 {
    let pairs = GroupIndex::from_keys(
      [Int32(@arrow.PrimArray::from_array(groups.ids)), col],
      n,
    )
    for row in pairs.first_rows() {
      counts[groups.ids[row]] += 1
    }
  }
  grouped_int64_column(counts)
}
