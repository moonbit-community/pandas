// Counting distinct values: `Series::value_counts` and `Series::unique_counts`.
//
// Both hash the series once (`GroupIndex::from_keys`), so they cost O(n).
// Equality is the one of `unique` and `group_by`: null equals null, NaN
// equals NaN, `-0.0` equals `0.0` (the first member of a group is shown).

///|
/// The distinct values of the series with how often each occurs, as a frame
/// of two columns: the values (named like the series) and the counts.
///
/// - The counts are `Int64` and the column is called `count`; with
///   `normalize=true` they are the share of all values (`Float64`, null
///   counted as a value) and the column is called `proportion`. `name`
///   replaces either name (an empty `name` counts as not given, as in
///   polars).
/// - Order: by default the values come in order of first appearance. With
///   `sort=true` the biggest count comes first and values with the same count
///   keep their order of first appearance. (polars does not promise an order
///   in either case; this library always gives this one.)
/// - A series without values gives a frame without rows.
///
/// # Errors
/// `DuplicateColumn` when the name of the count column is the name of the
/// series (`using `value_counts` on a column/series named 'x' would lead to
/// duplicate column names; change `name` to fix`).
///
/// ```mbt check
/// test {
///   let s = @pl.Series::str("s", ["b", "a", "b"])
///   let out = s.value_counts()
///   assert_eq(out.column("s").to_str_array(), [Some("b"), Some("a")])
///   assert_eq(out.column("count").to_int64_array(), [Some(2L), Some(1L)])
/// }
/// ```
pub fn Series::value_counts(
  self : Series,
  sort~ : Bool = false,
  name? : String,
  normalize~ : Bool = false,
) -> DataFrame raise PolarsError {
  let count_name = match name {
    Some(n) if n != "" => n
    _ => if normalize { "proportion" } else { "count" }
  }
  if count_name == self.name {
    raise DuplicateColumn(
      "using `value_counts` on a column/series named '\{self.name}' would lead to duplicate column names; change `name` to fix",
    )
  }
  let n = self.len()
  let groups = GroupIndex::from_keys([self.col], n)
  let mut firsts = groups.first_rows()
  let mut sizes = groups.sizes()
  if sort {
    let counts = Column::Int32(@arrow.PrimArray::from_array(sizes))
    let order = arg_sort_columns([counts], [true], [false])
    firsts = order.map(g => firsts[g])
    sizes = order.map(g => sizes[g])
  }
  let values = Series::make(self.name, self.col.gather(firsts))
  let counts = if normalize {
    let total = n.to_double()
    Series::float64(count_name, sizes.map(c => c.to_double() / total))
  } else {
    Series::int64(count_name, sizes.map(c => c.to_int64()))
  }
  DataFrame::from_valid([values, counts])
}

///|
/// How often each distinct value occurs, as an `Int64` series named like
/// this one, in order of first appearance (the order of `unique`). Nulls count
/// as one value; NaN equals NaN and `-0.0` equals `0.0`.
///
/// ```mbt check
/// test {
///   let s = @pl.Series::int64("x", [1L, 2L, 1L])
///   assert_eq(s.unique_counts().to_int64_array(), [Some(2L), Some(1L)])
/// }
/// ```
pub fn Series::unique_counts(self : Series) -> Series {
  let groups = GroupIndex::from_keys([self.col], self.len())
  Series::int64(self.name, groups.sizes().map(c => c.to_int64()))
}
