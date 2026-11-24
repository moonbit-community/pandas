///|
/// Evaluates `exprs` on the frame and returns one column per resulting
/// series, in order (`cols` and `all` stand for several columns).
///
/// - The output columns are named as `Expr` documents (the leftmost column,
///   `literal`, or the alias); two with the same name raise `DuplicateColumn`.
/// - A length-1 result (a literal) is repeated to the length of the other
///   results, which is the frame's height: `select([col("a"), lit_int(1)])`
///   on 3 rows has 3 rows, also on a frame without rows (0 rows). When every
///   result is length 1 there is one row: `select([lit_int(1)])` is a 1x1
///   frame whatever the input (a frame without columns included).
/// - No expressions give a frame with no columns.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::int32("a", [1, 2, 3])])
///   let out = df.select([@pl.col("a") * @pl.lit_int(2L), @pl.lit_str("k")])
///   assert_eq(out.shape(), (3, 2))
///   assert_eq(out.columns(), ["a", "literal"])
/// }
/// ```
///
/// # Errors
/// - `ColumnNotFound` for a column that does not exist.
/// - `DuplicateColumn` for repeated output names.
/// - `ShapeMismatch` when two results differ in length and neither is 1.
/// - `InvalidOperation`, `SchemaMismatch`, `ComputeError` from the operations
///   (for example `InvalidOperation` for arithmetic on a `String` column).
pub fn DataFrame::select(
  self : DataFrame,
  exprs : Array[Expr],
) -> DataFrame raise PolarsError {
  DataFrame::new(eval_exprs(self, exprs))
}

///|
/// `s` as a column of a frame `height` rows high: itself when it is that
/// long, its row repeated when it has length 1.
///
/// # Errors
/// `ShapeMismatch` (polars' `can't broadcast Series 'a' of length 2 to length
/// 4`) for any other length.
fn fit_height(s : Series, height : Int32) -> Series raise PolarsError {
  if s.len() == height {
    s
  } else if s.len() == 1 {
    Series::make(s.name, s.col.broadcast(height))
  } else {
    raise ShapeMismatch(
      "can't broadcast Series '\{s.name}' of length \{s.len()} to length \{height}",
    )
  }
}

///|
/// The frame with the columns `exprs` produce added: a result named like an
/// existing column replaces it where it is, any other is appended at the end,
/// in the order of `exprs`. Every expression sees the original frame, not the
/// columns added by the ones before it.
///
/// A length-1 result (a literal) is repeated to the frame's height; a frame
/// without rows stays without rows (`with_columns([lit_int(1)])` has 0 rows),
/// and so does a frame without columns, where the height is 0.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::int32("a", [1, 2])])
///   let out = df.with_columns([@pl.col("a").alias("b"), @pl.lit_int(0L)])
///   assert_eq(out.columns(), ["a", "b", "literal"])
/// }
/// ```
///
/// # Errors
/// - `ColumnNotFound`, `InvalidOperation`, `SchemaMismatch`, `ComputeError`
///   as for `select`.
/// - `DuplicateColumn` when two expressions produce the same name.
/// - `ShapeMismatch` when a result is neither as long as the frame is high
///   nor of length 1.
pub fn DataFrame::with_columns(
  self : DataFrame,
  exprs : Array[Expr],
) -> DataFrame raise PolarsError {
  // each result against the frame height, not against the other results
  let results = eval_unbroadcast(self, exprs, true)
  let height = self.height()
  let cols = self.get_columns()
  for s in results {
    let fitted = fit_height(s, height)
    match self.get_column_index(s.name) {
      Some(i) => cols[i] = fitted
      None => cols.push(fitted)
    }
  }
  DataFrame::new(cols)
}
