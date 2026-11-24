// DataFrame operations: filter, sort, unique, drop, rename, fill_null,
// drop_nulls, null_count, with_row_index.
//
// Layout (T9 adds `fill_null_strategy` in its own section at the end):
//   1. helpers (`frame_` prefix)
//   2. rows: filter, sort, unique, drop_nulls
//   3. columns: drop, rename, with_row_index
//   4. nulls: fill_null, null_count

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

///|
/// The columns of `df` as the series' storage, in order.
fn frame_columns(df : DataFrame) -> Array[Column] {
  df.cols.map(s => s.col)
}

///|
/// The frame made of the rows `idx` (row numbers, all valid) of every column
/// of `df`; the column data of an unchanged frame is shared.
fn frame_gather(df : DataFrame, idx : Array[Int32]) -> DataFrame {
  if idx.length() == df.height() && idx_is_identity(idx) {
    return df
  }
  DataFrame::from_valid(
    df.cols.map(s => Series::make(s.name, s.col.gather(idx))),
  )
}

///|
/// Whether `idx` is `0, 1, 2, ...`.
fn idx_is_identity(idx : Array[Int32]) -> Bool {
  for i in 0..<idx.length() {
    if idx[i] != i {
      return false
    }
  }
  true
}

///|
/// polars' `"name" not found` (the name quoted as Rust's `Debug` does).
fn frame_not_found(name : String) -> PolarsError {
  ColumnNotFound("\{debug_quote(name)} not found")
}

///|
/// The storage of the columns `names`, in the order of `names`.
///
/// # Errors
/// `ColumnNotFound` (`"zz" not found`) for the first name the frame lacks.
fn frame_named_columns(
  df : DataFrame,
  names : Array[String],
) -> Array[Column] raise PolarsError {
  let out : Array[Column] = Array(capacity=names.length())
  for name in names {
    match df.get_column_index(name) {
      Some(i) => out.push(df.cols[i].col)
      None => raise frame_not_found(name)
    }
  }
  out
}

// ---------------------------------------------------------------------------
// Rows: filter, sort, unique, drop_nulls
// ---------------------------------------------------------------------------

///|
/// The rows of the frame where `predicate` is true; rows where it is null are
/// dropped. The columns and their types are kept.
///
/// - The predicate must evaluate to a `Boolean` column as long as the frame is
///   high, or to a single value (`lit_bool(true)` keeps every row,
///   `lit_bool(false)` none, also on a frame without rows).
/// - `all()` and `cols` are fine when they stand for exactly one column.
/// - A predicate that is `is_in` of an empty series (also aliased) keeps no
///   row whatever the types, as in polars; `select` and `Series::is_in` raise
///   `InvalidOperation` for an empty series of an incompatible type.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::int32("a", [1, 2, 3, 4])])
///   let out = df.filter(@pl.col("a").gt(@pl.lit_int(2L)))
///   assert_eq(out.height(), 2)
/// }
/// ```
///
/// # Errors
/// - `ColumnNotFound` for a column that does not exist.
/// - `InvalidOperation` (`` filter predicate must be of type `Boolean`, got
///   `Int64` ``) when the predicate is not `Boolean` (a `Null` column
///   included). For a weak literal (`lit_int`, `lit_float`, also aliased,
///   negated or folded: `lit_int(1) + lit_int(2)`) it is a `ComputeError`
///   that names the weak type (`i32`, `i64`, `f64`), as in polars.
/// - `ComputeError` when the predicate stands for several columns (`cols` of
///   two names, `all()` on a wider frame) or for none.
/// - `ShapeMismatch` (`filter's length: 2 differs from that of the series: 5`)
///   when the predicate is neither as long as the frame nor of length 1.
/// - Whatever evaluating the predicate raises.
pub fn DataFrame::filter(
  self : DataFrame,
  predicate : Expr,
) -> DataFrame raise PolarsError {
  let nodes = expand_selectors(self, predicate)
  if nodes.length() == 0 {
    raise ComputeError(
      "The predicate expanded to zero expressions. This may for example be caused by a regex not matching column names or a column dtype match not hitting any dtypes in the DataFrame",
    )
  }
  if nodes.length() > 1 {
    raise ComputeError(
      "The predicate passed to 'LazyFrame.filter' expanded to multiple expressions: ",
    )
  }
  let node = nodes[0]
  check_columns(self, node)
  // polars folds `is_in` of an empty set of any type inside a filter to "no
  // row" before it looks at the types (`select` and `Series::is_in` still
  // raise); the checked operand is evaluated for its own errors
  let mut inner = node
  while inner is Alias(x, _) {
    inner = x
  }
  if inner is IsIn(x, values) && values.len() == 0 {
    ignore(eval_operand(self, x))
    return frame_gather(self, [])
  }
  // a folding of weak literals that leaves the `Int64` / `Float64` range
  // (zero divisor, overflow, a null operand, a bitwise operator) is a
  // `ComputeError` that names polars' weak type
  match weak_probe(node) {
    Some(PFailed(name)) =>
      raise ComputeError(
        "filter predicate must be of type `Boolean`, got `\{name}`",
      )
    Some(PNullBad) =>
      raise InvalidOperation(
        "filter predicate must be of type `Boolean`, got `Null`",
      )
    _ => ()
  }
  // a weak literal (also aliased, negated or folded) names its weak type
  let mask = match eval_operand(self, node) {
    Weak(Int(v)) =>
      raise ComputeError(
        "filter predicate must be of type `Boolean`, got `\{if v >= @int.MIN_VALUE.to_int64() && v <= @int.MAX_VALUE.to_int64() { "i32" } else { "i64" }}`",
      )
    Weak(Float(_)) =>
      raise ComputeError(
        "filter predicate must be of type `Boolean`, got `f64`",
      )
    Strong(s) => s
  }
  let m = match mask.col {
    Boolean(m) => m
    _ =>
      raise InvalidOperation(
        "filter predicate must be of type `Boolean`, got `\{polars_type_name(mask.dtype())}`",
      )
  }
  let height = self.height()
  if m.length() != height && m.length() != 1 {
    raise ShapeMismatch(
      "filter's length: \{m.length()} differs from that of the series: \{height}",
    )
  }
  let full = match Column::Boolean(m).expand(height) {
    Boolean(f) => f
    _ => abort("DataFrame::filter: the mask is not Boolean")
  }
  // the rows to keep, found once for every column
  let keep : Array[Int32] = []
  for i in 0..<height {
    if full.is_valid(i) && full.value(i) {
      keep.push(i)
    }
  }
  frame_gather(self, keep)
}

///|
/// The `descending` flag of each of `n` sort keys: empty means all ascending,
/// one flag applies to every key, otherwise there must be one per key.
fn frame_descending(
  descending : Array[Bool],
  n : Int32,
) -> Array[Bool] raise PolarsError {
  let len = descending.length()
  if len == 0 {
    Array::make(n, false)
  } else if len == 1 {
    Array::make(n, descending[0])
  } else if len == n {
    descending
  } else {
    raise InvalidOperation(
      "the length of `descending` (\{len}) does not match the length of `by` (\{n})",
    )
  }
}

///|
/// The rows ordered by the expressions `by`, first key first. The sort is
/// stable (rows that are equal on every key keep their order, also when
/// descending) and takes O(n log n) comparisons.
///
/// - `by` is expanded first: `cols` and `all()` stand for several keys.
/// - `descending` is empty (all keys ascending), has one flag (applies to
///   every key) or has one flag per expanded key.
/// - `nulls_last` puts the nulls of every key after the values instead of
///   before them, whatever the direction. NaN is greater than every number;
///   strings compare by code point.
/// - Every key must be as long as the frame; a literal or an aggregate is not
///   repeated. With no key the frame is returned as it is.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::int32("a", [3, 1, 2])])
///   let out = df.sort([@pl.col("a")], descending=[true])
///   assert_eq(out.column("a").to_int32_array(), [Some(3), Some(2), Some(1)])
/// }
/// ```
///
/// # Errors
/// - `InvalidOperation` (``the length of `descending` (3) does not match the
///   length of `by` (2)``) when `descending` has another length.
/// - `ColumnNotFound` for a missing column.
/// - `ShapeMismatch` (`sort expressions must have same length as DataFrame,
///   got DataFrame height: 5 and Series length: 1`) for a key of another
///   length.
/// - Whatever evaluating a key raises.
pub fn DataFrame::sort(
  self : DataFrame,
  by : Array[Expr],
  descending~ : Array[Bool] = [],
  nulls_last~ : Bool = false,
) -> DataFrame raise PolarsError {
  let nodes : Array[ExprNode] = []
  for e in by {
    nodes.append(expand_selectors(self, e))
  }
  let n = nodes.length()
  let desc = frame_descending(descending, n)
  for node in nodes {
    check_columns(self, node)
  }
  if n == 0 {
    return self
  }
  let height = self.height()
  let keys : Array[Column] = Array(capacity=n)
  for node in nodes {
    let s = eval_node(self, node)
    if s.len() != height {
      raise ShapeMismatch(
        "sort expressions must have same length as DataFrame, got DataFrame height: \{height} and Series length: \{s.len()}",
      )
    }
    keys.push(s.col)
  }
  frame_gather(self, arg_sort_columns(keys, desc, Array::make(n, nulls_last)))
}

///|
/// The distinct rows, comparing the columns `subset` (all columns when it is
/// not given) and keeping the whole row. Null equals null, NaN equals NaN and `-0.0`
/// equals `0.0`. A hash table makes this O(n).
///
/// - `keep`: `Any` and `First` keep the first of equal rows, `Last` the last,
///   `KeepNone` drops every row that has an equal one (only rows that occur
///   once survive).
/// - The rows come out in their original order, so `maintain_order` makes no
///   difference (polars only promises the order when it is `true`).
/// - A frame without columns is returned as it is.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::int32("a", [1, 1, 2]),
///     @pl.Series::str("b", ["x", "y", "z"]),
///   ])
///   assert_eq(df.unique(subset=["a"]).height(), 2)
/// }
/// ```
///
/// # Errors
/// - `ColumnNotFound` for a name of `subset` the frame lacks (`unable to find
///   column "zz"; valid columns: [...]`).
/// - `ComputeError` (`at least one key is required in a group_by operation`)
///   for an empty `subset`.
pub fn DataFrame::unique(
  self : DataFrame,
  subset? : Array[String],
  keep~ : UniqueKeep = Any,
  maintain_order~ : Bool = false,
) -> DataFrame raise PolarsError {
  // the order is always kept
  ignore(maintain_order)
  let keys : Array[Column] = match subset {
    None => frame_columns(self)
    Some(names) => {
      if names.length() == 0 {
        raise ComputeError(
          "at least one key is required in a group_by operation",
        )
      }
      let out : Array[Column] = Array(capacity=names.length())
      for name in names {
        out.push(frame_column(self, name).col)
      }
      out
    }
  }
  if keys.length() == 0 {
    return self
  }
  frame_gather(self, unique_row_indices(keys, keep))
}

///|
/// The rows that have no null in the columns `subset` (every column when
/// not given; an empty `subset` keeps every row). NaN is not null. A `Null`
/// column has nothing but nulls, so naming it drops every row.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::int32_nullable("a", [Some(1), None, Some(3)]),
///   ])
///   assert_eq(df.drop_nulls().height(), 2)
/// }
/// ```
///
/// # Errors
/// `ColumnNotFound` (`"zz" not found`) for a name of `subset` the frame lacks.
pub fn DataFrame::drop_nulls(
  self : DataFrame,
  subset? : Array[String],
) -> DataFrame raise PolarsError {
  let keys : Array[Column] = match subset {
    None => frame_columns(self)
    Some(names) => frame_named_columns(self, names)
  }
  let masks : Array[@arrow.Bitmap] = []
  for c in keys {
    match c.validity() {
      Some(v) => masks.push(v)
      None => ()
    }
  }
  if masks.length() == 0 {
    return self
  }
  let keep : Array[Int32] = []
  for i in 0..<self.height() {
    let mut ok = true
    for m in masks {
      if !m.get(i) {
        ok = false
        break
      }
    }
    if ok {
      keep.push(i)
    }
  }
  frame_gather(self, keep)
}

// ---------------------------------------------------------------------------
// Columns: drop, rename, with_row_index
// ---------------------------------------------------------------------------

///|
/// The frame without the columns `names`; the other columns keep their order.
/// A name may appear twice. Dropping every column gives a frame without
/// columns (shape `(0, 0)`).
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::int32("a", [1]),
///     @pl.Series::int32("b", [2]),
///   ])
///   assert_eq(df.drop(["a"]).columns(), ["b"])
///   assert_eq(df.drop(["zz"], strict=false).columns(), ["a", "b"])
/// }
/// ```
///
/// # Errors
/// `ColumnNotFound` (`"zz" not found`, the first missing name) when `strict`
/// and a name is not a column.
pub fn DataFrame::drop(
  self : DataFrame,
  names : Array[String],
  strict~ : Bool = true,
) -> DataFrame raise PolarsError {
  let gone : Map[String, Bool] = Map([])
  for name in names {
    if self.get_column_index(name) is None {
      if strict {
        raise frame_not_found(name)
      }
    } else {
      gone[name] = true
    }
  }
  DataFrame::from_valid(self.cols.filter(s => !gone.contains(s.name)))
}

///|
/// The frame with columns renamed by `mapping` (old name to new name). All
/// renames apply at once, so `{"a": "b", "b": "a"}` swaps two columns.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::int32("a", [1])])
///   assert_eq(df.rename({ "a": "x" }).columns(), ["x"])
/// }
/// ```
///
/// # Errors
/// - `DuplicateColumn` (`column 's' is duplicate`) when two columns end up
///   with the same name. This is checked before the missing names.
/// - `ColumnNotFound` (`"zz" not found`, the first missing key of `mapping`)
///   when `strict` and a key is not a column.
pub fn DataFrame::rename(
  self : DataFrame,
  mapping : Map[String, String],
  strict~ : Bool = true,
) -> DataFrame raise PolarsError {
  let seen : Map[String, Bool] = Map([])
  let out : Array[Series] = Array(capacity=self.cols.length())
  for s in self.cols {
    let name = match mapping.get(s.name) {
      Some(n) => n
      None => s.name
    }
    if seen.contains(name) {
      raise DuplicateColumn("column '\{name}' is duplicate")
    }
    seen[name] = true
    out.push(if name == s.name { s } else { s.rename(name) })
  }
  if strict {
    for old, _ in mapping {
      if self.get_column_index(old) is None {
        raise frame_not_found(old)
      }
    }
  }
  DataFrame::from_valid(out)
}

///|
/// The frame with an `Int64` column of row numbers in front: `offset`,
/// `offset + 1`, ... A frame without columns has no rows, so the new column is
/// empty.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::str("a", ["x", "y"])])
///   let out = df.with_row_index(offset=10)
///   assert_eq(out.columns(), ["index", "a"])
///   assert_eq(out.column("index").to_int64_array(), [Some(10L), Some(11L)])
/// }
/// ```
///
/// # Errors
/// - `InvalidOperation` (``` `offset` input for `with_row_index` cannot be
///   negative, got -1 ```) for a negative `offset`.
/// - `DuplicateColumn` (`column with name 'a' has more than one occurrence`)
///   when `name` is already a column.
pub fn DataFrame::with_row_index(
  self : DataFrame,
  name~ : String = "index",
  offset~ : Int32 = 0,
) -> DataFrame raise PolarsError {
  if offset < 0 {
    raise InvalidOperation(
      "`offset` input for `with_row_index` cannot be negative, got \{offset}",
    )
  }
  let start = offset.to_int64()
  let values : FixedArray[Int64] = FixedArray::makei(self.height(), i => {
    start + i.to_int64()
  })
  let index = Series::make(
    name,
    Column::Int64(@arrow.PrimArray::new(values, None)),
  )
  // polars checks the name by itself, with the short text (no prefix)
  if self.get_column_index(name) is Some(_) {
    raise DuplicateColumn(
      "column with name '\{name}' has more than one occurrence",
    )
  }
  DataFrame::from_valid([index, ..self.cols])
}

// ---------------------------------------------------------------------------
// Nulls: fill_null, null_count
// ---------------------------------------------------------------------------

///|
/// Whether a column of type `t` is filled by a literal of the given kind
/// (polars' `DataFrame.fill_null(value)` with a Python scalar fills the
/// columns of the matching kind, and `Null` columns). `None` when the literal
/// is not a scalar of that sort: it then fills every column.
fn frame_fill_targets(
  value : AnyValue,
  kind : LitKind,
) -> ((DataType) -> Bool)? {
  match (value, kind) {
    (Int64(_), WeakInt) | (Float64(_), WeakFloat) =>
      Some(t => {
        match t {
          Int32 | Int64 | Float32 | Float64 | Null => true
          _ => false
        }
      })
    (Boolean(_), Strong) =>
      Some(t => {
        match t {
          Boolean | Null => true
          _ => false
        }
      })
    (String(_), Strong) =>
      Some(t => {
        match t {
          String | Null => true
          _ => false
        }
      })
    (Date(_), Strong) =>
      Some(t => {
        match t {
          Date | Null => true
          _ => false
        }
      })
    (Datetime(_), Strong) =>
      Some(t => {
        match t {
          Datetime | Null => true
          _ => false
        }
      })
    _ => None
  }
}

///|
/// Replaces the nulls of the columns `value` stands for with `value`.
///
/// What a literal fills follows polars' `df.fill_null(value)`:
///
/// - `lit_int` and `lit_float` (a Python `int`/`float`) fill the `Int32`,
///   `Int64`, `Float32`, `Float64` and `Null` columns. The literal is weak, as
///   in `select`: it takes the column's type when it fits (`Int32` filled with
///   `lit_int(0)` stays `Int32`, with `lit_int(3_000_000_000)` becomes
///   `Int64`; `Float32` stays `Float32`; an integer column filled with
///   `lit_float(1.5)` becomes `Float64`; a `Null` column becomes `Int32`,
///   `Int64` or `Float64`).
/// - `lit_bool`, `lit_str` and the `Date` and `Datetime` literals fill the
///   columns of that type and the `Null` columns (a `Null` column takes the
///   literal's type).
/// - A `Null` literal changes nothing.
/// - Any other literal (`lit(Int32(0))` and the like) fills every column, each
///   result being the supertype of the column and the value (`Boolean` filled
///   with an `Int32` value becomes `Int32`, a number filled with a `String`
///   becomes `String`).
/// - Any other expression (`col("a")`, `col("a") + lit_int(1)`, an aggregate
///   such as `col("a").sum()`) is `all().fill_null(value)`: every column is
///   filled from the value, row by row when the value is a column, with the
///   types of `Expr::fill_null` (the supertype of the column and the value;
///   weak literals inside the expression adapt as they do in `select`, and
///   `lit_int(1) + lit_int(2)` is an `Int64`). A value that expands to several
///   columns pairs up with the columns of the frame one by one.
/// - The columns that are not filled keep their type; NaN is not null.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::int32_nullable("a", [Some(1), None]),
///     @pl.Series::str_nullable("s", [None, Some("x")]),
///   ])
///   let out = df.fill_null(@pl.lit_int(0L))
///   assert_eq(out.column("a").to_int32_array(), [Some(1), Some(0)])
///   assert_eq(out.column("s").null_count(), 1)
/// }
/// ```
///
/// # Errors
/// - `InvalidOperation` when the value stands for several columns and their
///   number differs from the frame's (`cannot combine selectors that produce
///   a different number of columns (2 != 4)`).
/// - `SchemaMismatch` (`failed to determine supertype of bool and date`) when
///   a column to fill and the value have no common type.
/// - `ColumnNotFound` and the like from evaluating the value.
///
/// A frame without columns gives a frame without columns.
pub fn DataFrame::fill_null(
  self : DataFrame,
  value : Expr,
) -> DataFrame raise PolarsError {
  match value.node {
    Literal(v, kind) =>
      match frame_fill_targets(v, kind) {
        Some(targets) => {
          let w : WeakVal? = match (v, kind) {
            (Int64(x), WeakInt) => Some(WeakVal::Int(x))
            (Float64(x), WeakFloat) => Some(WeakVal::Float(x))
            _ => None
          }
          let out : Array[Series] = Array(capacity=self.cols.length())
          for s in self.cols {
            if !targets(s.dtype()) {
              out.push(s)
              continue
            }
            let fill = match w {
              Some(w) => weak_series("literal", w, s.dtype()).get(0)
              None => v
            }
            out.push(s.fill_null(fill))
          }
          DataFrame::from_valid(out)
        }
        None => frame_fill_all(self, v)
      }
    // anything else is `all().fill_null(value)`: each column is filled from
    // the value expression, which pairs with the columns like any selector
    _ => self.select([all().fill_null(value)])
  }
}

///|
/// Replaces the nulls of every column using `strategy`, as polars'
/// `df.fill_null(strategy=...)` (the same as `all().fill_null_strategy(...)`
/// in `select`): each column goes through `Series::fill_null_strategy`, so the
/// types are kept, a column without a null is left as it is whatever the
/// strategy, and a column whose type the strategy refuses (`Mean` of a
/// `Boolean` or `String` column, `One` of a `String` column, `Zero` or `One`
/// of a `Null` column) raises when it has a null; the first such column is
/// the one reported. `limit` (`limit=1`) bounds the run of nulls that
/// `Forward` and `Backward` fill.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::int32_nullable("a", [Some(1), None, None]),
///     @pl.Series::str_nullable("s", [None, Some("x"), None]),
///   ])
///   let out = df.fill_null_strategy(@pl.FillStrategy::Forward, limit=1)
///   assert_eq(out.column("a").to_int32_array(), [Some(1), Some(1), None])
///   assert_eq(out.column("s").to_str_array(), [None, Some("x"), Some("x")])
/// }
/// ```
///
/// # Errors
/// `InvalidOperation` for a `limit` with a strategy other than `Forward` or
/// `Backward` and for a negative `limit` (also when the frame has no column),
/// and for a column whose type the strategy refuses (see
/// `Series::fill_null_strategy`).
pub fn DataFrame::fill_null_strategy(
  self : DataFrame,
  strategy : FillStrategy,
  limit? : Int32,
) -> DataFrame raise PolarsError {
  xseq_check_limit(strategy, limit)
  let out : Array[Series] = Array(capacity=self.cols.length())
  for s in self.cols {
    out.push(s.fill_null_strategy(strategy, limit?))
  }
  DataFrame::from_valid(out)
}

///|
/// Every column filled with `value`, as `Series::fill_null` does it.
fn frame_fill_all(
  df : DataFrame,
  value : AnyValue,
) -> DataFrame raise PolarsError {
  let out : Array[Series] = Array(capacity=df.cols.length())
  for s in df.cols {
    out.push(s.fill_null(value))
  }
  DataFrame::from_valid(out)
}

///|
/// A one-row frame with the number of nulls of each column (`Int64`); the
/// columns keep their names. A `Null` column counts all its rows. A frame
/// without columns gives a frame without columns (polars gives one row).
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::int32_nullable("a", [Some(1), None, None]),
///   ])
///   assert_eq(df.null_count().column("a").to_int64_array(), [Some(2L)])
/// }
/// ```
pub fn DataFrame::null_count(self : DataFrame) -> DataFrame {
  DataFrame::from_valid(
    self.cols.map(s => Series::int64(s.name, [s.null_count().to_int64()])),
  )
}
