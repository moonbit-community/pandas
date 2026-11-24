// Reshaping frames: `pivot`, `unpivot`, `transpose` and `to_dict`.
//
// Semantics follow polars 2.1.0 (see docs/golden/reshape.json). `pivot` reuses
// the hashing of `group_by` (`GroupIndex`): the rows are grouped by index key
// and by `on` key once each, the cells by the pair of both, and every cell is
// aggregated in one pass (`grouped_agg`), so the cost is O(rows) plus the size
// of the result.

///|
/// How `pivot` combines the values that land in one cell (rows with the same
/// index key and the same `on` key). The aggregation is the one `group_by`
/// uses: `First` and `Last` keep nulls, the others skip them; `Sum` of a
/// number keeps its type, `Mean` and `Median` of integers are `Float64`, `Len`
/// counts the rows (nulls included) as `Int64`.
///
/// A cell no row lands in gets what the aggregation of no values gives: 0 for
/// `Sum` and `Len`, null for the others.
#derive(Eq, @debug.Debug)
pub(all) enum PivotAgg {
  First
  Last
  Sum
  Min
  Max
  Mean
  Median
  Len
}

///|
/// Formats the option with its polars name (`first`, `last`, `sum`, `min`, `max`, `mean`, `median`, `len`).
pub impl Show for PivotAgg with fn output(self, logger) {
  logger.write_string(
    match self {
      First => "first"
      Last => "last"
      Sum => "sum"
      Min => "min"
      Max => "max"
      Mean => "mean"
      Median => "median"
      Len => "len"
    },
  )
}

///|
/// Makes `to_string` callable as a method, giving the same polars name as
/// `Show`.
pub extend PivotAgg with Show::{to_string}

///|
fn PivotAgg::op(self : PivotAgg) -> AggOp {
  match self {
    First => AggOp::First
    Last => AggOp::Last
    Sum => AggOp::Sum
    Min => AggOp::Min
    Max => AggOp::Max
    Mean => AggOp::Mean
    Median => AggOp::Median
    Len => AggOp::Len
  }
}

///|
/// `names` without repeats, first occurrences kept.
fn reshape_dedup(names : Array[String]) -> Array[String] {
  let seen : Map[String, Bool] = Map([])
  let out : Array[String] = []
  for n in names {
    if !seen.contains(n) {
      seen[n] = true
      out.push(n)
    }
  }
  out
}

///|
/// The type every column of a `unpivot` or `transpose` is cast to: the common
/// type of all of them (`Null` when there is no column).
///
/// `swapped` words the error as `unpivot` does (the new type first), else as
/// `transpose` does (the type so far first), as polars does.
///
/// # Errors
/// `SchemaMismatch` when two types have no common type.
fn reshape_common_type(
  cols : Array[Series],
  swapped : Bool,
) -> DataType raise PolarsError {
  let mut t = DataType::Null
  for i, c in cols {
    if i == 0 {
      t = c.dtype()
    } else {
      match concat_supertype(t, c.dtype()) {
        Some(u) => t = u
        None =>
          raise SchemaMismatch(
            if swapped {
              "failed to determine supertype of \{c.dtype()} and \{t}"
            } else {
              "failed to determine supertype of \{t} and \{c.dtype()}"
            },
          )
      }
    }
  }
  t
}

///|
/// The columns as one column of type `t`, one after the other.
fn reshape_stack(
  cols : Array[Series],
  t : DataType,
) -> Column raise PolarsError {
  if cols.length() == 0 {
    return null_column(t, 0)
  }
  Column::concat(
    cols.map(s => {
      if s.dtype() == t {
        s.col
      } else {
        s.cast(t, strict=false).col
      }
    }),
  )
}

// ---------------------------------------------------------------------------
// pivot
// ---------------------------------------------------------------------------

///|
/// The name of the column that holds the cells of one `on` key: the key as
/// text (`null` for a null key). With several `on` columns the key is a
/// struct as polars prints it, `{1,"a"}` (strings quoted, no escaping), and a
/// key with a null in it is just `null`.
fn pivot_key_name(cols : Array[Column], row : Int32) -> String {
  if cols.length() == 1 {
    match cols[0].get(row) {
      Null => "null"
      Boolean(b) => if b { "true" } else { "false" }
      Int32(x) => x.to_string()
      Int64(x) => x.to_string()
      Float32(x) => format_f32(x)
      Float64(x) => format_f64(x)
      String(s) => s
      Date(d) => cell_date(d)
      Datetime(t) => format_datetime(t)
    }
  } else {
    let parts : Array[String] = []
    for c in cols {
      match c.get(row) {
        Null => return "null"
        String(s) => parts.push("\"" + s + "\"")
        v => parts.push(cell_text(v))
      }
    }
    "{" + parts.join(",") + "}"
  }
}

///|
fn reshape_missing_on(df : DataFrame, name : String) -> PolarsError {
  let valid = df.columns().map(debug_quote).join(", ")
  ColumnNotFound(
    "unable to find column \{debug_quote(name)}; valid columns: [\{valid}]",
  )
}

///|
/// Spreads the values of the `on` columns over new columns: one output row per
/// distinct `index` key (in order of first appearance) and, for every
/// `values` column, one output column per distinct `on` key (in order of first
/// appearance, or sorted by the key with `sort_columns=true`, nulls first).
///
/// - `index` defaults to the columns that are neither `on` nor `values` and
///   `values` to the columns that are neither `index` nor `on`; at least one
///   of the two must be given. `index=[]` is one row. Repeated names count
///   once.
/// - The new columns are named after the `on` key (`null` for a null key; a
///   struct text like `{1,"a"}` for several `on` columns); with more than one
///   `values` column the name is `<value><separator><key>`.
/// - Several rows may land in one cell. Without `aggregate_function` that is an
///   error; otherwise they are combined as `PivotAgg` says. Cells without rows
///   are null (0 for `Sum` and `Len`). Keys compare as in `group_by` (null
///   equals null, NaN equals NaN, `-0.0` equals `0.0`).
/// - A frame without rows gives a frame without rows that has only the index
///   columns (no columns at all when there is no index).
///
/// # Errors
/// `InvalidOperation` for an empty `on` or `values` and when neither `index`
/// nor `values` is given; `ColumnNotFound` for an unknown column;
/// `DuplicateColumn` when `on` repeats a column or when two output columns get
/// the same name; `ComputeError` for a cell with several rows and no
/// `aggregate_function` (`aggregation 'item' expected no or a single value,
/// got 2 values`, naming the first such cell); what `group_by` raises for an
/// aggregation the type does not support.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::int64("i", [1L, 1L, 2L]),
///     @pl.Series::str("k", ["a", "b", "a"]),
///     @pl.Series::int64("v", [10L, 20L, 30L]),
///   ])
///   let out = df.pivot(["k"], index=["i"], values=["v"])
///   assert_eq(out.columns(), ["i", "a", "b"])
///   assert_eq(out.column("b").to_int64_array(), [Some(20L), None])
/// }
/// ```
pub fn DataFrame::pivot(
  self : DataFrame,
  on : Array[String],
  index? : Array[String],
  values? : Array[String],
  aggregate_function? : PivotAgg,
  sort_columns~ : Bool = false,
  separator~ : String = "_",
) -> DataFrame raise PolarsError {
  if on.length() == 0 {
    raise InvalidOperation("`pivot` called without `on` columns.")
  }
  for c in on {
    if !self.index.contains(c) {
      raise reshape_missing_on(self, c)
    }
  }
  let seen : Map[String, Bool] = Map([])
  for c in on {
    if seen.contains(c) {
      raise DuplicateColumn(
        "projections contained duplicate output name '\{c}'. It's possible that multiple expressions are returning the same default column name. If this is the case, try renaming the columns with `.alias(\"new_name\")` to avoid duplicate column names.",
      )
    }
    seen[c] = true
  }
  let index_names = match index {
    Some(ix) => reshape_dedup(ix)
    None =>
      match values {
        None =>
          raise InvalidOperation(
            "`pivot` needs either `index or `values` needs to be specified",
          )
        Some(vs) =>
          self.columns().filter(c => !on.contains(c) && !vs.contains(c))
      }
  }
  let idx_series : Array[Series] = []
  for n in index_names {
    idx_series.push(self.column(n))
  }
  let value_names = match values {
    Some(vs) => reshape_dedup(vs)
    None =>
      self.columns().filter(c => !index_names.contains(c) && !on.contains(c))
  }
  if value_names.length() == 0 {
    raise InvalidOperation("`pivot` called without `values` columns.")
  }
  let val_series : Array[Series] = []
  for n in value_names {
    val_series.push(self.column(n))
  }
  let on_cols = on.map(n => self.cols[self.index[n]].col)
  let h = self.height()
  if h == 0 {
    return DataFrame::from_valid(idx_series.map(s => s.slice(0, length=0)))
  }
  let rows = GroupIndex::from_keys(idx_series.map(s => s.col), h)
  let colg = GroupIndex::from_keys(on_cols, h)
  let cells = GroupIndex::from_keys(
    [
      Column::Int32(@arrow.PrimArray::from_array(rows.ids)),
      Column::Int32(@arrow.PrimArray::from_array(colg.ids)),
    ],
    h,
  )
  let nrows = rows.n_groups
  let ncols = colg.n_groups
  let ncells = cells.n_groups
  if aggregate_function is None {
    for g in 0..<ncells {
      let n = cells.size(g)
      if n > 1 {
        raise ComputeError(
          "aggregation 'item' expected no or a single value, got \{n} values",
        )
      }
    }
  }
  let op = match aggregate_function {
    Some(a) => a.op()
    None => AggOp::First
  }
  // the cell of every (key of `on`, row) pair; `ncells` stands for a cell that
  // no row lands in
  if nrows.to_int64() * ncols.to_int64() > @int.MAX_VALUE.to_int64() {
    raise ComputeError(
      "the pivot would have more than 2147483647 cells per value column (\{nrows} x \{ncols})",
    )
  }
  let cell_of : Array[Int32] = Array::make(nrows * ncols, ncells)
  let first_cell_rows = cells.first_rows()
  for g in 0..<ncells {
    let f = first_cell_rows[g]
    cell_of[colg.ids[f] * nrows + rows.ids[f]] = g
  }
  let first_keys = colg.first_rows()
  let order : Array[Int32] = if sort_columns {
    let keys = on_cols.map(c => c.gather(first_keys))
    arg_sort_columns(keys, keys.map(_ => false), keys.map(_ => false))
  } else {
    Array::makei(ncols, i => i)
  }
  let key_names = order.map(c => pivot_key_name(on_cols, first_keys[c]))
  let out : Array[Series] = []
  let first_rows = rows.first_rows()
  for i, s in idx_series {
    out.push(Series::make(index_names[i], s.col.gather(first_rows)))
  }
  for i, s in val_series {
    let agg = grouped_agg(s.col, cells, op)
    let empty = group_agg_column(s.col.slice(0, 0), op)
    let full = Column::concat([agg, empty])
    for j, c in order {
      let picks : Array[Int32] = Array::make(nrows, 0)
      for r in 0..<nrows {
        picks[r] = cell_of[c * nrows + r]
      }
      let name = if value_names.length() == 1 {
        key_names[j]
      } else {
        value_names[i] + separator + key_names[j]
      }
      out.push(Series::make(name, full.gather(picks)))
    }
  }
  let names : Map[String, Bool] = Map([])
  for s in out {
    if names.contains(s.name) {
      raise DuplicateColumn(
        "column with name '\{s.name}' has more than one occurrence",
      )
    }
    names[s.name] = true
  }
  DataFrame::from_valid(out)
}

// ---------------------------------------------------------------------------
// unpivot
// ---------------------------------------------------------------------------

///|
/// Turns columns into rows: for every `on` column in turn, one row per row of
/// the frame, holding the `index` columns, the name of the column (in
/// `variable_name`, default `variable`) and its value (in `value_name`,
/// default `value`).
///
/// - `on` defaults to every column that is not an `index` column. A column may
///   be in both. Repeated names count once.
/// - The value column has the common type of the `on` columns (the type
///   `concat` with `VerticalRelaxed` would give: `Int32` and `Float64` give
///   `Float64`, a number and a `String` give `String`, `Date` and `Datetime`
///   give `Datetime`); with no `on` column it is `Null` and there are no rows.
///
/// # Errors
/// `ColumnNotFound` for an unknown column (`on` is checked before `index`);
/// `DuplicateColumn` when `variable_name` or `value_name` (given or default) is the
/// name of any column of the frame, kept in the result or not, or when the two
/// are equal (`duplicate column name 'x'`, the variable name is checked first); `SchemaMismatch` when
/// the `on` columns have no common type.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::int64("id", [1L, 2L]),
///     @pl.Series::int64("x", [10L, 20L]),
///     @pl.Series::int64("y", [30L, 40L]),
///   ])
///   let out = df.unpivot(index=["id"])
///   assert_eq(out.columns(), ["id", "variable", "value"])
///   assert_eq(out.height(), 4)
/// }
/// ```
pub fn DataFrame::unpivot(
  self : DataFrame,
  on? : Array[String],
  index~ : Array[String] = [],
  variable_name? : String,
  value_name? : String,
) -> DataFrame raise PolarsError {
  let on_series : Array[Series] = []
  let on_names : Array[String] = match on {
    Some(o) => {
      let names = reshape_dedup(o)
      for n in names {
        on_series.push(self.column(n))
      }
      names
    }
    None => []
  }
  let index_names = reshape_dedup(index)
  let idx_series : Array[Series] = []
  for n in index_names {
    idx_series.push(self.column(n))
  }
  if on is None {
    for s in self.cols {
      if !index_names.contains(s.name) {
        on_names.push(s.name)
        on_series.push(s)
      }
    }
  }
  let var_name = match variable_name {
    Some(n) => n
    None => "variable"
  }
  let val_name = match value_name {
    Some(n) => n
    None => "value"
  }
  // a name that is a column of the frame clashes, whether or not that column
  // is kept (polars checks the variable name first)
  if self.index.contains(var_name) || var_name == val_name {
    raise DuplicateColumn("duplicate column name '\{var_name}'")
  }
  if self.index.contains(val_name) {
    raise DuplicateColumn("duplicate column name '\{val_name}'")
  }
  let t = reshape_common_type(on_series, true)
  let h = self.height()
  let k = on_series.length()
  if h.to_int64() * k.to_int64() > @int.MAX_VALUE.to_int64() {
    raise ComputeError(
      "the unpivot would have more than 2147483647 rows (\{h} x \{k})",
    )
  }
  let value = reshape_stack(on_series, t)
  let variable : Array[String] = Array(capacity=h * k)
  for n in on_names {
    for _ in 0..<h {
      variable.push(n)
    }
  }
  let out : Array[Series] = []
  let repeat : Array[Int32] = Array(capacity=h * k)
  for _ in 0..<k {
    for r in 0..<h {
      repeat.push(r)
    }
  }
  for i, s in idx_series {
    out.push(
      Series::make(
        index_names[i],
        if k == 1 {
          s.col
        } else {
          s.col.gather(repeat)
        },
      ),
    )
  }
  out.push(Series::str(var_name, variable))
  out.push(Series::make(val_name, value))
  DataFrame::from_valid(out)
}

// ---------------------------------------------------------------------------
// transpose, to_dict
// ---------------------------------------------------------------------------

///|
/// Swaps rows and columns: row `r` of the frame becomes column `r` of the
/// result and column `c` becomes row `c`. All columns are cast to their common
/// type first (see `unpivot`).
///
/// - The new columns are called `column_0`, `column_1`, ... or `column_names`.
/// - `include_header=true` adds a first `String` column (`header_name`,
///   default `column`) with the names of the old columns.
/// - A frame without rows has no columns left to show: the result has no
///   columns (only the header column, if asked for). polars gives a frame of
///   zero columns and as many rows as the frame had columns; this library's
///   frames without columns have no rows, so that row count is lost.
///
/// # Errors
/// `ShapeMismatch` when `column_names` does not have one name per row (`Length
/// of new column names must be the same as the row count`); `DuplicateColumn`
/// when the header name is one of the new names (`column is already in output
/// column names`) or two new names are equal; `SchemaMismatch` when the
/// columns have no common type.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::int64("a", [1L, 2L]),
///     @pl.Series::int64("b", [3L, 4L]),
///   ])
///   let out = df.transpose(include_header=true)
///   assert_eq(out.columns(), ["column", "column_0", "column_1"])
///   assert_eq(out.column("column_1").to_int64_array(), [Some(2L), Some(4L)])
/// }
/// ```
pub fn DataFrame::transpose(
  self : DataFrame,
  include_header~ : Bool = false,
  header_name~ : String = "column",
  column_names? : Array[String],
) -> DataFrame raise PolarsError {
  let h = self.height()
  let w = self.width()
  let names = match column_names {
    Some(ns) => {
      if ns.length() != h {
        raise ShapeMismatch(
          "Length of new column names must be the same as the row count",
        )
      }
      ns
    }
    None => Array::makei(h, i => "column_\{i}")
  }
  if include_header && names.contains(header_name) {
    raise DuplicateColumn("\{header_name} is already in output column names")
  }
  let t = reshape_common_type(self.cols, false)
  if h.to_int64() * w.to_int64() > @int.MAX_VALUE.to_int64() {
    raise ComputeError(
      "the transpose would have more than 2147483647 cells (\{h} x \{w})",
    )
  }
  let out : Array[Series] = []
  if include_header {
    out.push(Series::str(header_name, self.columns()))
  }
  if w > 0 && h > 0 {
    let flat = reshape_stack(self.cols, t)
    for j in 0..<h {
      let picks : Array[Int32] = Array(capacity=w)
      for i in 0..<w {
        picks.push(i * h + j)
      }
      out.push(Series::make(names[j], flat.gather(picks)))
    }
  }
  DataFrame::new(out)
}

///|
/// The columns by name, in column order.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::int64("a", [1L])])
///   assert_eq(df.to_dict().length(), 1)
/// }
/// ```
pub fn DataFrame::to_dict(self : DataFrame) -> Map[String, Series] {
  let out : Map[String, Series] = Map([])
  for s in self.cols {
    out[s.name] = s
  }
  out
}
