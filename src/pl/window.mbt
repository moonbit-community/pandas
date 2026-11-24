// `Expr::over(partition_by)`: an expression evaluated on every partition of
// the rows (the rows with equal partition keys) and put back in the rows.
//
// The partition keys are evaluated on the whole frame and the rows hashed once
// into a `GroupIndex` (`groups.mbt`, the one `group_by` uses). What the
// expression gives for a partition decides how it is put back, as in polars'
// default `group_to_rows` mapping:
//
// - one value per partition (an aggregation, `len()`, a literal, an
//   element-wise operation on those: `is_group_scalar`) is repeated on every
//   row of the partition. It is evaluated by `eval_grouped`, so it costs what
//   the same aggregation costs in a `group_by`: one pass over the rows for the
//   common aggregations;
// - an expression that works row by row (`is_row_level`: no aggregation, no
//   sequence operation, ...) does not depend on the partition and is evaluated
//   once on the whole frame;
// - anything else (`cum_sum`, `shift`, `rank`, `sort`, `head`, an expression
//   with an aggregation next to a column, ...) is evaluated partition by
//   partition on the partition's rows (`eval_sub`, the rule of the group
//   context). Its result must be as long as the partition and goes back to
//   the rows of the partition in order.
//
// The cost is O(rows + partitions x size of the expression).

///|
/// polars' error for a partition whose result is not as long as the partition.
/// When every partition is one row (`unit_groups`: a key that is different in
/// every row, or a frame of one row) polars takes another path and words it
/// differently.
fn window_length_error(unit_groups : Bool) -> PolarsError {
  if unit_groups {
    ShapeMismatch("expressions must have matching group lengths")
  } else {
    ShapeMismatch(
      "the length of the window expression did not match that of the group",
    )
  }
}

///|
/// `x` evaluated on every partition of `df` by the `keys` and put back in the
/// rows; see `Expr::over`.
fn eval_over(
  df : DataFrame,
  x : ExprNode,
  keys : Array[ExprNode],
) -> Series raise PolarsError {
  let height = df.height()
  if height == 0 {
    // no partition: the keys are still evaluated (their errors count), the
    // result is the expression's column without rows
    for k in keys {
      ignore(eval_node(df, k))
    }
    return eval_node(df, x).head(n=0)
  }
  if keys.length() == 0 {
    raise ComputeError("at least one key is required in a group_by operation")
  }
  let (_, groups) = group_by_keys(df, keys)
  let name = output_name(x)
  if is_group_scalar(x) {
    let per_group = eval_grouped(df, groups, x)
    return Series::make(name, per_group.col.gather(groups.ids))
  }
  if is_row_level(x) {
    return eval_node(df, x)
  }
  let used : Array[String] = []
  collect_columns(x, Map([]), used)
  let ng = groups.length()
  let parts : Array[Column] = Array(capacity=ng)
  for g in 0..<ng {
    let rows = groups.rows(g).to_owned()
    let result = eval_sub(
      group_sub_frame(df, used, rows),
      x,
      whole=groups.whole,
    )
    if result.len() != rows.length() {
      raise window_length_error(ng == height || ng == 1)
    }
    parts.push(result.col)
  }
  // the values are in the order of `groups.flat` (partition by partition):
  // row `flat[i]` takes the i-th value
  let back : Array[Int32] = Array::make(height, 0)
  for i in 0..<height {
    back[groups.flat[i]] = i
  }
  Series::make(name, Column::concat(parts).gather(back))
}

///|
/// The expression evaluated on every partition of the frame, as polars'
/// `Expr.over(partition_by)`: the rows with equal values of the `partition_by`
/// expressions form a partition, and the result has one value for every row.
///
/// - An expression that gives one value per partition (`col("v").sum()`,
///   `len()`, `col("v").max() - col("v").min()`) is repeated on the rows of
///   the partition: `col("v").sum().over([col("k")])`.
/// - A sequence operation (`cum_sum`, `shift`, `diff`, `rank`, `reverse`,
///   `fill_null` with a strategy) or `sort`, `sort_by`, `arg_sort` sees the
///   rows of its partition in their order, and the result goes back to the
///   same rows: `col("v").cum_sum().over([col("k")])`.
/// - An element-wise expression is not changed by the partition; one that
///   mixes rows and aggregations has its aggregations computed per partition:
///   `(col("v") - col("v").mean()).over([col("k")])` is the same as
///   `col("v") - col("v").mean().over([col("k")])`.
/// - A partition whose result is not as long as the partition (`head(1)`,
///   `unique()`, `filter(...)` that drops rows) is a `ShapeMismatch`
///   (`the length of the window expression did not match that of the
///   group`), also when only some partitions have such a result.
///
/// Partition keys are any expressions (a literal or an aggregation is one
/// partition of all the rows); null is a partition of its own, NaN equals NaN
/// and `-0.0` equals `0.0`. Several keys partition by the combination.
/// Selectors pair up as in other operations: `cols(["a", "b"]).sum()
/// .over([cols(["k", "j"])])` is `a` over `k` and `b` over `j`. A window
/// nested in a window is partitioned by both keys. On a frame without rows
/// the result is an empty column of the type the expression has.
///
/// `over` works in `select`, `with_columns`, `filter` and `sort`, and can be
/// part of a larger expression (`col("a") - col("a").mean().over([col("g")])`).
/// Inside `group_by(...).agg(...)` the window is the group: `col("v").sum()
/// .over([col("k")]).first()` partitions each group by `k`. A window on its
/// own in `agg` is a list per group in polars; this library has no List type
/// and raises `InvalidOperation`.
///
/// Only `partition_by` is supported; polars' `order_by` and `mapping_strategy`
/// are not (see `docs/golden/known-diffs/window.md`).
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::str("g", ["a", "b", "a", "b"]),
///     @pl.Series::int64("v", [1L, 2L, 3L, 4L]),
///   ])
///   let out = df.with_columns([
///     @pl.col("v").sum().over([@pl.col("g")]).alias("total"),
///     @pl.col("v").cum_sum().over([@pl.col("g")]).alias("running"),
///   ])
///   assert_eq(out.column("total").to_int64_array(), [
///     Some(4L),
///     Some(6L),
///     Some(4L),
///     Some(6L),
///   ])
///   assert_eq(out.column("running").to_int64_array(), [
///     Some(1L),
///     Some(2L),
///     Some(4L),
///     Some(6L),
///   ])
/// }
/// ```
///
/// # Errors
/// `ComputeError` (`at least one key is required in a group_by operation`)
/// for no key on a frame with rows; `ShapeMismatch` for a partition result of
/// the wrong length and for a key that is neither one row nor the height of
/// the frame; `ColumnNotFound` and whatever the expressions raise.
pub fn Expr::over(self : Expr, partition_by : Array[Expr]) -> Expr {
  Expr::of(Over(self.node, partition_by.map(k => k.node)))
}
