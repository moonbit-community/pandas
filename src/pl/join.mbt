// `DataFrame::join`: hash joins on key expressions.
//
// The right side (the left side for a right join) is indexed by its keys:
// one `GroupTable` entry per distinct key, the rows of a key chained in
// ascending order. The other side probes it row by row, so the work is
// proportional to the two inputs plus the output.

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

///|
/// How `DataFrame::join` combines the rows of the two frames, with polars'
/// names for `how`.
///
/// - `Inner`: the rows with a match on both sides.
/// - `Left`: every left row; the right columns are null where nothing matches.
/// - `Right`: every right row; the left columns are null where nothing
///   matches.
/// - `Full`: every row of both sides.
/// - `Semi`: the left rows that have a match (left columns only).
/// - `Anti`: the left rows that have no match (left columns only).
/// - `Cross`: every left row paired with every right row (no keys).
#derive(Eq, @debug.Debug)
pub(all) enum JoinHow {
  Inner
  Left
  Right
  Full
  Semi
  Anti
  Cross
}

///|
/// Formats the kind with its polars name (`inner`, `left`, `right`, `full`,
/// `semi`, `anti`, `cross`).
pub impl Show for JoinHow with fn output(self, logger) {
  logger.write_string(
    match self {
      Inner => "inner"
      Left => "left"
      Right => "right"
      Full => "full"
      Semi => "semi"
      Anti => "anti"
      Cross => "cross"
    },
  )
}

///|
/// Makes `to_string` callable as a method, giving the same polars name as
/// `Show`.
pub extend JoinHow with Show::{to_string}

///|
/// Which side of a join may repeat a key, as polars' `validate` (`m:m`,
/// `1:m`, `m:1`, `1:1`): `OneToMany` needs unique keys on the left,
/// `ManyToOne` on the right, `OneToOne` on both.
#derive(Eq, @debug.Debug)
pub(all) enum JoinValidation {
  ManyToMany
  OneToMany
  ManyToOne
  OneToOne
}

///|
/// Formats the option with its polars name (`m:m`, `1:m`, `m:1`, `1:1`).
pub impl Show for JoinValidation with fn output(self, logger) {
  logger.write_string(
    match self {
      ManyToMany => "m:m"
      OneToMany => "1:m"
      ManyToOne => "m:1"
      OneToOne => "1:1"
    },
  )
}

///|
/// Makes `to_string` callable as a method, giving the same polars name as
/// `Show`.
pub extend JoinValidation with Show::{to_string}

///|
fn JoinValidation::text(self : JoinValidation) -> String {
  match self {
    ManyToMany => "m:m"
    OneToMany => "1:m"
    ManyToOne => "m:1"
    OneToOne => "1:1"
  }
}

// ---------------------------------------------------------------------------
// Columns
// ---------------------------------------------------------------------------

///|
fn[T : Default] gather_prim_opt(
  a : @arrow.PrimArray[T],
  idx : Array[Int32],
) -> @arrow.PrimArray[T] {
  let b : @arrow.PrimBuilder[T] = @arrow.PrimBuilder::new(capacity=idx.length())
  for i in idx {
    if i < 0 || !a.is_valid(i) {
      b.push_null()
    } else {
      b.push(a.value(i))
    }
  }
  b.finish()
}

///|
/// The rows at the given indices; a negative index gives a null row. Every
/// other index must be in range.
fn Column::gather_opt(self : Column, idx : Array[Int32]) -> Column {
  let mut has_null = false
  for i in idx {
    if i < 0 {
      has_null = true
      break
    }
  }
  if !has_null {
    return self.gather(idx)
  }
  match self {
    Boolean(a) => {
      let b = @arrow.BoolBuilder::new(capacity=idx.length())
      for i in idx {
        if i < 0 || !a.is_valid(i) {
          b.push_null()
        } else {
          b.push(a.value(i))
        }
      }
      Boolean(b.finish())
    }
    Int32(a) => Int32(gather_prim_opt(a, idx))
    Int64(a) => Int64(gather_prim_opt(a, idx))
    Float32(a) => Float32(gather_prim_opt(a, idx))
    Float64(a) => Float64(gather_prim_opt(a, idx))
    String(a) => {
      let b = @arrow.StrBuilder::new(capacity=idx.length())
      for i in idx {
        if i < 0 || !a.is_valid(i) {
          b.push_null()
        } else {
          b.push(a.value(i))
        }
      }
      String(b.finish())
    }
    Date(a) => Date(gather_prim_opt(a, idx))
    Datetime(a) => Datetime(gather_prim_opt(a, idx))
    Null(_) => Null(idx.length())
  }
}

// ---------------------------------------------------------------------------
// The row index
// ---------------------------------------------------------------------------

///|
/// Whether some key column has a null, which only matters when nulls do not
/// match each other.
fn join_check_nulls(keys : Array[Column], nulls_equal : Bool) -> Bool {
  if nulls_equal {
    return false
  }
  for c in keys {
    if c.null_count() > 0 {
      return true
    }
  }
  false
}

///|
fn join_row_has_null(keys : Array[Column], i : Int32) -> Bool {
  for c in keys {
    if !c.is_valid(i) {
      return true
    }
  }
  false
}

///|
/// The rows of a frame by key: group `g` is a distinct key, `head[g]` its first
/// row, `next[row]` the next row with the same key (`-1` after the last) and
/// `row_group[row]` the group of a row (`-1` for a row left out because a key
/// is null and nulls do not match).
priv struct JoinIndex {
  table : GroupTable
  head : Array[Int32]
  next : FixedArray[Int32]
  row_group : FixedArray[Int32]
}

///|
fn JoinIndex::build(
  keys : Array[Column],
  n : Int32,
  nulls_equal : Bool,
) -> JoinIndex {
  let check = join_check_nulls(keys, nulls_equal)
  let table = GroupTable::new(n)
  let head : Array[Int32] = Array(capacity=n)
  let tail : Array[Int32] = Array(capacity=n)
  let next : FixedArray[Int32] = FixedArray::make(n, -1)
  let row_group : FixedArray[Int32] = FixedArray::make(n, -1)
  for j in 0..<n {
    if check && join_row_has_null(keys, j) {
      continue
    }
    let h = row_hash(keys, j)
    let g = table.find(h, keys, keys, j)
    if g < 0 {
      let g = table.add(h, j)
      head.push(j)
      tail.push(j)
      row_group[j] = g
    } else {
      next[tail[g]] = j
      tail[g] = j
      row_group[j] = g
    }
  }
  { table, head, next, row_group, }
}

///|
/// The group whose key equals that of row `i` of `probe`, or `-1`.
fn JoinIndex::find(
  self : JoinIndex,
  build : Array[Column],
  probe : Array[Column],
  i : Int32,
) -> Int32 {
  self.table.find(row_hash(probe, i), build, probe, i)
}

///|
/// Whether no two rows of `keys` are equal (rows with a null key are not
/// counted when nulls do not match).
fn join_keys_unique(
  keys : Array[Column],
  n : Int32,
  nulls_equal : Bool,
) -> Bool {
  let check = join_check_nulls(keys, nulls_equal)
  let table = GroupTable::new(n)
  for j in 0..<n {
    if check && join_row_has_null(keys, j) {
      continue
    }
    let h = row_hash(keys, j)
    if table.find(h, keys, keys, j) >= 0 {
      return false
    }
    ignore(table.add(h, j))
  }
  true
}

///|
/// The number of rows in each group of `index`, from the group of every row
/// it was built on.
fn JoinIndex::group_sizes(self : JoinIndex) -> Array[Int32] {
  let sizes : Array[Int32] = Array::make(self.head.length(), 0)
  for g in self.row_group {
    if g >= 0 {
      sizes[g] += 1
    }
  }
  sizes
}

///|
/// Raises `ComputeError` when a join would make more rows than an `Int32`
/// can count. It is called with the exact number of rows, found before any
/// row number is stored, so a huge output (two big frames on one key) is an
/// error, not an allocation that fails.
fn join_check_rows(how : JoinHow, total : Int64) -> Unit raise PolarsError {
  if total > @int.MAX_VALUE.to_int64() {
    raise ComputeError(
      "the \{how} join would have more than 2147483647 rows (\{total} rows)",
    )
  }
}

///|
/// The row numbers of the two sides that a join pairs up, in the order the
/// library promises (`-1` means that side has no row, so its columns are
/// null).
///
/// `left` and `right` are the key columns, one per key, already of the same
/// type pair by pair; a `Cross` join takes one stand-in column per side for
/// the number of rows. For `Semi` and `Anti` only the left rows come back (the
/// second array is empty).
///
/// - `Inner`, `Left`, `Semi`, `Anti` and `Full` follow the left rows, the
///   matches of a row in right row order; a `Full` join then adds the right
///   rows that matched nothing, in right row order;
/// - `Right` follows the right rows, the matches of a row in left row order;
/// - `Cross` follows the left rows, then the right rows.
///
/// When `nulls_equal` is false a row with a null in any key matches nothing.
/// The work is proportional to the two inputs plus the output.
///
/// # Errors
/// `ComputeError` when the output would have more than 2147483647 rows
/// (`join_check_rows`); the rows are counted first, from the sizes of the key
/// groups, so nothing is allocated for such a join.
fn join_indices(
  left : Array[Column],
  right : Array[Column],
  how : JoinHow,
  nulls_equal : Bool,
) -> (Array[Int32], Array[Int32]) raise PolarsError {
  let ln = left[0].length()
  let rn = right[0].length()
  match how {
    Cross => {
      let li : Array[Int32] = Array(capacity=ln)
      let ri : Array[Int32] = Array(capacity=ln)
      for i in 0..<ln {
        for j in 0..<rn {
          li.push(i)
          ri.push(j)
        }
      }
      (li, ri)
    }
    Right => {
      let index = JoinIndex::build(left, ln, nulls_equal)
      let sizes = index.group_sizes()
      let check = join_check_nulls(right, nulls_equal)
      // the group of every right row, and the number of rows of the result
      let gs : FixedArray[Int32] = FixedArray::make(rn, -1)
      let mut total = 0L
      for j in 0..<rn {
        let g = if check && join_row_has_null(right, j) {
          -1
        } else {
          index.find(left, right, j)
        }
        gs[j] = g
        total += if g < 0 { 1L } else { sizes[g].to_int64() }
      }
      join_check_rows(how, total)
      let li : Array[Int32] = Array(capacity=total.to_int())
      let ri : Array[Int32] = Array(capacity=total.to_int())
      for j in 0..<rn {
        let g = gs[j]
        if g < 0 {
          li.push(-1)
          ri.push(j)
        } else {
          let mut i = index.head[g]
          while i >= 0 {
            li.push(i)
            ri.push(j)
            i = index.next[i]
          }
        }
      }
      (li, ri)
    }
    _ => {
      let index = JoinIndex::build(right, rn, nulls_equal)
      let sizes = index.group_sizes()
      let check = join_check_nulls(left, nulls_equal)
      let seen : FixedArray[Bool] = FixedArray::make(index.head.length(), false)
      // the group of every left row, and the number of rows of the result
      let gs : FixedArray[Int32] = FixedArray::make(ln, -1)
      let mut total = 0L
      for i in 0..<ln {
        let g = if check && join_row_has_null(left, i) {
          -1
        } else {
          index.find(right, left, i)
        }
        gs[i] = g
        match how {
          Semi => if g >= 0 { total += 1L }
          Anti => if g < 0 { total += 1L }
          _ =>
            if g < 0 {
              if how == Left || how == Full {
                total += 1L
              }
            } else {
              seen[g] = true
              total += sizes[g].to_int64()
            }
        }
      }
      if how == Full {
        for j in 0..<rn {
          let g = index.row_group[j]
          if g < 0 || !seen[g] {
            total += 1L
          }
        }
      }
      join_check_rows(how, total)
      let li : Array[Int32] = Array(capacity=total.to_int())
      let ri : Array[Int32] = Array(
        capacity=if how == Semi || how == Anti { 0 } else { total.to_int() },
      )
      for i in 0..<ln {
        let g = gs[i]
        match how {
          Semi => if g >= 0 { li.push(i) }
          Anti => if g < 0 { li.push(i) }
          _ =>
            if g < 0 {
              if how == Left || how == Full {
                li.push(i)
                ri.push(-1)
              }
            } else {
              let mut j = index.head[g]
              while j >= 0 {
                li.push(i)
                ri.push(j)
                j = index.next[j]
              }
            }
        }
      }
      if how == Full {
        for j in 0..<rn {
          let g = index.row_group[j]
          if g < 0 || !seen[g] {
            li.push(-1)
            ri.push(j)
          }
        }
      }
      (li, ri)
    }
  }
}

// ---------------------------------------------------------------------------
// Key expressions
// ---------------------------------------------------------------------------

///|
/// The direct operands of an expression node.
fn ExprNode::join_children(self : ExprNode) -> Array[ExprNode] {
  match self {
    Column(_) | Columns(_) | All | Literal(_, _) | Len => []
    Binary(_, l, r) => [l, r]
    Not(x) | Neg(x) | Alias(x, _) | Cast(x, _, _) | IsNull(x) | IsNotNull(x) =>
      [x]
    Agg(_, x) | NUnique(x) | Func(_, x) | IsIn(x, _) => [x]
    FillNull(x, v) => [x, v]
    Between(x, lo, hi, _) => [x, lo, hi]
    Ternary(c, t, o) => [c, t, o]
    Seq(_, x) | Str(_, x) | Dt(_, x) => [x]
    Shape(_, x) | AnyAll(_, _, x) => [x]
    Filter(x, p) => [x, p]
    SortBy(x, keys, _, _) => [x, ..keys]
    Horizontal(_, xs, _) => xs.copy()
    Over(x, keys) => [x, ..keys]
  }
}

///|
/// Whether the node itself is one polars refuses in a join key as not
/// elementwise: a sequence operation (`cum_sum`, `shift`, ...) or one that
/// sorts, cuts or filters the rows (`sort`, `head`, `unique`, `filter`, ...),
/// or `str().to_date()` / `to_datetime()` (the format is guessed from the first
/// value, so a value depends on the others).
/// `any`, `all`, `len` and the aggregations are accepted (their value is
/// repeated), and so are the horizontal functions.
fn join_not_elementwise(node : ExprNode) -> Bool {
  node
  is (Seq(_, _)
  | Shape(_, _)
  | Filter(_, _)
  | SortBy(_, _, _, _)
  | Over(_, _)
  | Str(ToDate(_), _)
  | Str(ToDatetime(_), _))
}

///|
/// Whether `pred` holds for the node or any node below it.
fn join_node_any(node : ExprNode, pred : (ExprNode) -> Bool) -> Bool {
  if pred(node) {
    return true
  }
  for child in node.join_children() {
    if join_node_any(child, pred) {
      return true
    }
  }
  false
}

///|
/// The type of a key, found on a frame without rows. polars knows the type of
/// a sequence operation (`cum_sum`, `shift`, ...) from the schema and rejects
/// the key as not elementwise only afterwards, so a sequence key whose
/// evaluation fails gets the type polars gives it: the type of its input, but
/// `Int64` for the cumulative sum or product of a text, `Float64` for a rank.
/// `None` when that cannot be told (the operation is nested in the key).
fn join_key_dtype(
  df0 : DataFrame,
  node : ExprNode,
) -> DataType? raise PolarsError {
  Some(eval_node(df0, node).dtype()) catch {
    e => {
      if !join_node_any(node, join_not_elementwise) {
        raise e
      }
      match node {
        // the type of a sort, a cut or a filter is the type of its input
        // (`arg_sort`: an index, `Int64` here)
        Shape(ArgSort(_, _), _) => Some(Int64)
        Str(ToDate(_), _) => Some(Date)
        Str(ToDatetime(_), _) => Some(Datetime)
        Shape(_, x) | Filter(x, _) | SortBy(x, _, _, _) =>
          Some(eval_node(df0, x).dtype())
        Seq(op, x) => {
          let d = eval_node(df0, x).dtype()
          Some(
            match (op, d) {
              (CumSum(_), String) | (CumProd(_), _) => Int64
              (Rank(_, _), _) => Float64
              _ => d
            },
          )
        }
        _ => None
      }
    }
  }
}

///|
/// The key expressions of one side, expanded: every selector becomes its
/// columns. polars expands one side completely (and checks that it is not
/// empty) before it looks at the other.
fn join_expand_side(
  df : DataFrame,
  exprs : Array[Expr],
  side : String,
) -> Array[ExprNode] raise PolarsError {
  let out : Array[ExprNode] = []
  for e in exprs {
    for node in expand_selectors(df, e) {
      out.push(node)
    }
  }
  if out.length() == 0 {
    raise InvalidOperation("\{side} join keys expanded to zero expressions")
  }
  out
}

///|
/// The key series of one side on the frame: a plain column as it is, any other
/// expression evaluated; a length-1 result (a literal, an aggregation) is
/// repeated to the frame's height.
fn join_eval_keys(
  df : DataFrame,
  nodes : Array[ExprNode],
) -> Array[Series] raise PolarsError {
  let height = df.height()
  let out : Array[Series] = []
  for node in nodes {
    let s = eval_node(df, node)
    if s.len() == height {
      out.push(s)
    } else if s.len() == 1 {
      out.push(Series::make(s.name, s.col.broadcast(height)))
    } else {
      raise ShapeMismatch(
        "Series length \{s.len()} doesn't match the DataFrame height of \{height}",
      )
    }
  }
  out
}

///|
/// The type both sides of a key pair are compared in: the type itself when the
/// two are equal, `Int64` for `Int32` with `Int64`, `Float64` for `Float32`
/// with `Float64`, and no other pair (polars joins nothing else: a number
/// with a date, a text with a number, a `Null` key with a typed one fail).
fn join_key_type(a : DataType, b : DataType) -> DataType? {
  if a == b {
    return Some(a)
  }
  match (a, b) {
    (Int32, Int64) | (Int64, Int32) => Some(Int64)
    (Float32, Float64) | (Float64, Float32) => Some(Float64)
    _ => None
  }
}

///|
fn join_key_is_column(node : ExprNode) -> Bool {
  node is Column(_)
}

// ---------------------------------------------------------------------------
// Output columns
// ---------------------------------------------------------------------------

///|
/// The names the right columns get next to the left ones: a name the left side
/// has gets `suffix`. polars renames them one after the other, in the order
/// of the right columns, and a rename that cannot be done is an error: the new
/// name is a name of the left side (`column with name 'x' already exists`),
/// else a name the right columns have at that moment, the column itself
/// included when `suffix` is empty (`column 'x' is duplicate`).
fn join_right_names(
  left_names : Array[String],
  right_names : Array[String],
  suffix : String,
) -> Array[String] raise PolarsError {
  let left_set : Map[String, Bool] = Map([])
  for n in left_names {
    left_set[n] = true
  }
  let names = right_names.copy()
  let current : Map[String, Bool] = Map([])
  for n in names {
    current[n] = true
  }
  for i in 0..<names.length() {
    let old = names[i]
    if left_set.contains(old) {
      let new_name = old + suffix
      if new_name != old && left_set.contains(new_name) {
        raise DuplicateColumn("column with name '\{new_name}' already exists")
      }
      if current.contains(new_name) {
        raise DuplicateColumn("column '\{new_name}' is duplicate")
      }
      current.remove(old)
      current[new_name] = true
      names[i] = new_name
    }
  }
  names
}

///|
/// The frame of a join: the left columns at `left_keep` (taken by `li`; a
/// column of `replaced` is that series instead), then the right columns at
/// `right_keep` under `right_names` (taken by `ri`).
fn join_assemble(
  left : DataFrame,
  right : DataFrame,
  left_keep : Array[Int32],
  replaced : Map[Int32, Column],
  right_keep : Array[Int32],
  right_names : Array[String],
  li : Array[Int32],
  ri : Array[Int32],
) -> DataFrame {
  let cols : Array[Series] = Array(
    capacity=left_keep.length() + right_keep.length(),
  )
  for c in left_keep {
    let s = left.cols[c]
    match replaced.get(c) {
      Some(col) => cols.push(Series::make(s.name, col))
      None => cols.push(Series::make(s.name, s.col.gather_opt(li)))
    }
  }
  for k in 0..<right_keep.length() {
    let s = right.cols[right_keep[k]]
    cols.push(Series::make(right_names[k], s.col.gather_opt(ri)))
  }
  DataFrame::from_valid(cols)
}

///|
fn join_all(n : Int32) -> Array[Int32] {
  Array::makei(n, i => i)
}

///|
fn join_cross(
  left : DataFrame,
  right : DataFrame,
  suffix : String,
) -> DataFrame raise PolarsError {
  let names = join_right_names(left.columns(), right.columns(), suffix)
  let lh = left.height()
  let rh = right.height()
  if lh.to_int64() * rh.to_int64() > @int.MAX_VALUE.to_int64() {
    raise ComputeError(
      "the cross join would have more than 2147483647 rows (\{lh} x \{rh})",
    )
  }
  let (li, ri) = join_indices(
    [Column::Null(lh)],
    [Column::Null(rh)],
    Cross,
    false,
  )
  join_assemble(
    left,
    right,
    join_all(left.width()),
    Map([]),
    join_all(right.width()),
    names,
    li,
    ri,
  )
}

// ---------------------------------------------------------------------------
// join
// ---------------------------------------------------------------------------

///|
/// Joins `other` to the frame on key expressions, with the semantics of
/// polars' `DataFrame.join`.
///
/// # Keys
/// Give `on` (the same expressions on both sides) or `left_on` and
/// `right_on`; the keys are paired in order. Selectors expand (`all()` and
/// `cols([...])` stand for several keys), plain columns are looked up, and any
/// other expression (`col("a") % lit_int(2)`, a literal, an aggregation) is
/// computed on its side first; a length-1 result is repeated to the height of
/// its frame. A key may not contain an `alias` and may not be a sequence
/// operation (`cum_sum`, `shift`, `rank`, ...). `how=Cross` takes no keys.
///
/// The two keys of a pair must have the same type, except `Int32` with
/// `Int64` and `Float32` with `Float64`, which are compared as `Int64` and
/// `Float64`. A null key matches nothing unless `nulls_equal` is true (then
/// it matches a null key); with several keys, a row with a null in any key
/// matches nothing. NaN matches NaN and `-0.0` matches `0.0`.
///
/// # Rows
/// The order of the rows is the same on every run, whatever the sizes:
///
/// - `Inner`, `Left`, `Semi`, `Anti` follow the left rows, and the matches of
///   one left row come in right row order;
/// - `Right` follows the right rows, the matches of a row in left row order;
/// - `Full` is the `Left` result followed by the right rows that matched
///   nothing, in right row order;
/// - `Cross` has the left rows in order, each with all right rows in order.
///
/// # Columns
/// The columns are the left ones, then the right ones; a right column whose
/// name a left column has gets `suffix` added. The keys are coalesced by
/// default for `Inner`, `Left` and `Right` (not for `Full`) when every key is
/// a plain column: the key column of the right side is dropped (`Right`: the
/// key column of the left side, and the left columns come first without it),
/// so the key appears once, under the name and with the type of the side that
/// is kept. `coalesce=true` for `Full` makes the key one column too: the left
/// key where the left row exists, else the right key, in the common type of
/// the two. `coalesce=false` keeps both key columns. With an expression among
/// the keys nothing is coalesced, whatever `coalesce` says. `Semi` and `Anti`
/// give the left columns only; `Cross` ignores `coalesce`.
///
/// # Validation
/// `validate` checks the keys before joining: `OneToMany` that the left keys
/// are unique, `ManyToOne` the right ones, `OneToOne` both. It does not matter
/// whether a key matches. `Right`, `Semi` and `Anti` joins cannot be validated;
/// `Cross` ignores it.
///
/// ```mbt check
/// test {
///   let users = @pl.DataFrame::new([
///     @pl.Series::int32("id", [1, 2, 3]),
///     @pl.Series::str("name", ["ann", "bob", "cy"]),
///   ])
///   let orders = @pl.DataFrame::new([
///     @pl.Series::int32("id", [2, 2, 4]),
///     @pl.Series::int32("total", [10, 20, 30]),
///   ])
///   let out = users.join(orders, on=[@pl.col("id")], how=Left)
///   assert_eq(out.columns(), ["id", "name", "total"])
///   assert_eq(out.height(), 4)
///   assert_eq(out.column("total").to_int32_array(), [
///     None,
///     Some(10),
///     Some(20),
///     None,
///   ])
/// }
/// ```
///
/// # Errors
/// In the order polars checks them:
///
/// 1. `InvalidOperation` for the arguments: `on` together with `left_on` or
///    `right_on`, only one of `left_on` and `right_on`, keys with
///    `how=Cross`, no keys at all; then for a different number of `left_on`
///    and `right_on` expressions, no key expression, and a `validate` other
///    than `ManyToMany` with `Right`, `Semi` or `Anti` (`ComputeError`);
/// 2. `InvalidOperation` for an `alias` in a key; for selectors that expand
///    to nothing or to different numbers of keys on the two sides;
///    `ColumnNotFound` for a name of `cols([...])` that does not exist;
/// 3. `ColumnNotFound` for a plain key column that does not exist (the left
///    keys first), then `InvalidOperation` for the same output name pair twice
///    (`joining with repeated key names; already joined on a and a`);
/// 4. the errors of evaluating a key expression (the left keys first);
///    `SchemaMismatch` for a pair of key types that cannot be joined;
///    `InvalidOperation` for a key that is not element-wise;
/// 5. `DuplicateColumn` when the output would have two columns with one name
///    (`suffix` clashes);
/// 6. `ComputeError` when `validate` is not met.
pub fn DataFrame::join(
  self : DataFrame,
  other : DataFrame,
  on? : Array[Expr],
  left_on? : Array[Expr],
  right_on? : Array[Expr],
  how~ : JoinHow = Inner,
  suffix~ : String = "_right",
  validate~ : JoinValidation = ManyToMany,
  nulls_equal~ : Bool = false,
  coalesce? : Bool,
) -> DataFrame raise PolarsError {
  // the arguments, in the order of polars' Python wrapper
  let uses_on = on is Some(_)
  let uses_lr = left_on is Some(_) || right_on is Some(_)
  if uses_on && uses_lr {
    raise InvalidOperation(
      "cannot use 'on' in conjunction with 'left_on' or 'right_on'",
    )
  }
  if (left_on is Some(_)) != (right_on is Some(_)) {
    raise InvalidOperation("'left_on' requires corresponding 'right_on'")
  }
  if how == Cross {
    if uses_on || uses_lr {
      raise InvalidOperation("cross join should not pass join keys")
    }
    return join_cross(self, other, suffix)
  }
  let (left_exprs, right_exprs) = match (on, left_on, right_on) {
    (Some(o), _, _) => (o, o)
    (None, Some(l), Some(r)) => (l, r)
    _ => raise InvalidOperation("must specify `on` OR `left_on` and `right_on`")
  }
  // the checks of the lazy frame builder
  if left_exprs.length() != right_exprs.length() {
    raise InvalidOperation(
      "the number of columns given as join key (left: \{left_exprs.length()}, right:\{right_exprs.length()}) should be equal",
    )
  }
  if left_exprs.length() == 0 {
    raise InvalidOperation("expected join keys/predicates")
  }
  if validate != ManyToMany && (how == Right || how == Semi || how == Anti) {
    let name = match how {
      Right => "RIGHT"
      Semi => "SEMI"
      _ => "ANTI"
    }
    raise ComputeError(
      "\{validate.text()} validation on a \{name} join is not supported",
    )
  }
  // the keys: aliases first, then each side is expanded in turn
  for e in left_exprs {
    if join_node_any(e.node, n => n is Alias(_, _)) {
      raise InvalidOperation(
        "'alias' is not allowed in a join key, use 'with_columns' first",
      )
    }
  }
  for e in right_exprs {
    if join_node_any(e.node, n => n is Alias(_, _)) {
      raise InvalidOperation(
        "'alias' is not allowed in a join key, use 'with_columns' first",
      )
    }
  }
  let left_nodes = join_expand_side(self, left_exprs, "left")
  let right_nodes = join_expand_side(other, right_exprs, "right")
  if left_nodes.length() != right_nodes.length() {
    raise InvalidOperation(
      "join keys expanded to a different number of expressions (left: \{left_nodes.length()}, right: \{right_nodes.length()})",
    )
  }
  let nkeys = left_nodes.length()
  for node in left_nodes {
    check_columns(self, node)
  }
  for node in right_nodes {
    check_columns(other, node)
  }
  let left_names = left_nodes.map(output_name)
  let right_names = right_nodes.map(output_name)
  let pairs : Map[String, Bool] = Map([])
  for k in 0..<nkeys {
    let pair = "\{left_names[k]}\u{0}\{right_names[k]}"
    if pairs.contains(pair) {
      raise InvalidOperation(
        "joining with repeated key names; already joined on \{left_names[k]} and \{right_names[k]}",
      )
    }
    pairs[pair] = true
  }
  // the type of every key: the expressions run on a frame without rows
  let left0 = self.head(n=0)
  let right0 = other.head(n=0)
  let left_types : Array[DataType?] = []
  let right_types : Array[DataType?] = []
  for node in left_nodes {
    left_types.push(join_key_dtype(left0, node))
  }
  for node in right_nodes {
    right_types.push(join_key_dtype(right0, node))
  }
  // a key whose type is unknown (a sequence operation that refuses its input
  // type) is not compared: the elementwise check below reports it
  let key_types : Array[DataType] = []
  for k in 0..<nkeys {
    let (lt, rt) = match (left_types[k], right_types[k]) {
      (Some(a), Some(b)) => (a, b)
      (Some(a), None) => (a, a)
      (None, Some(b)) => (b, b)
      (None, None) => (Null, Null)
    }
    match join_key_type(lt, rt) {
      Some(t) => key_types.push(t)
      None =>
        raise SchemaMismatch(
          "datatypes of join keys don't match - `\{left_names[k]}`: \{lt} on left does not match `\{right_names[k]}`: \{rt} on right (and no other type was available to cast to)",
        )
    }
  }
  for node in left_nodes {
    if join_node_any(node, join_not_elementwise) {
      raise InvalidOperation("all join key expressions must be elementwise.")
    }
  }
  for node in right_nodes {
    if join_node_any(node, join_not_elementwise) {
      raise InvalidOperation("all join key expressions must be elementwise.")
    }
  }
  // the output columns
  let plain = left_nodes.iter().all(join_key_is_column) &&
    right_nodes.iter().all(join_key_is_column)
  let coalesced = plain &&
    (match coalesce {
      Some(c) => c
      None => how != Full
    }) &&
    (how == Inner || how == Left || how == Right || how == Full)
  let left_key_cols : Map[String, Bool] = Map([])
  let right_key_cols : Map[String, Bool] = Map([])
  if plain {
    for k in 0..<nkeys {
      left_key_cols[left_names[k]] = true
      right_key_cols[right_names[k]] = true
    }
  }
  let left_keep : Array[Int32] = []
  let right_keep : Array[Int32] = []
  for c in 0..<self.width() {
    if !(coalesced && how == Right && left_key_cols.contains(self.cols[c].name)) {
      left_keep.push(c)
    }
  }
  if how != Semi && how != Anti {
    for c in 0..<other.width() {
      if !(coalesced &&
        how != Right &&
        right_key_cols.contains(other.cols[c].name)) {
        right_keep.push(c)
      }
    }
  }
  let out_right_names = join_right_names(
    left_keep.map(c => self.cols[c].name),
    right_keep.map(c => other.cols[c].name),
    suffix,
  )
  // the key values; this is where a key expression can fail on real data
  let left_series = join_eval_keys(self, left_nodes)
  let right_series = join_eval_keys(other, right_nodes)
  let lcols : Array[Column] = []
  let rcols : Array[Column] = []
  for k in 0..<nkeys {
    lcols.push(left_series[k].cast(key_types[k]).col)
    rcols.push(right_series[k].cast(key_types[k]).col)
  }
  if validate != ManyToMany {
    let left_ok = validate == ManyToOne ||
      join_keys_unique(lcols, self.height(), nulls_equal)
    let right_ok = validate == OneToMany ||
      join_keys_unique(rcols, other.height(), nulls_equal)
    if !left_ok || !right_ok {
      raise ComputeError(
        "join keys did not fulfill \{validate.text()} validation",
      )
    }
  }
  let (li, ri) = join_indices(lcols, rcols, how, nulls_equal)
  // a coalesced full join: the key is the left value where the left row
  // exists, else the right value
  let replaced : Map[Int32, Column] = Map([])
  if coalesced && how == Full {
    for k in 0..<nkeys {
      match self.get_column_index(left_names[k]) {
        Some(c) =>
          if !replaced.contains(c) {
            let lh = lcols[k].length()
            let both = Column::concat([lcols[k], rcols[k]])
            let idx = Array::makei(li.length(), p => {
              if li[p] >= 0 {
                li[p]
              } else {
                lh + ri[p]
              }
            })
            replaced[c] = both.gather(idx)
          }
        None => ()
      }
    }
  }
  join_assemble(
    self, other, left_keep, replaced, right_keep, out_right_names, li, ri,
  )
}
