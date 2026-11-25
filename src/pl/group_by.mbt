// `DataFrame::group_by(...).agg(...)`: the key expressions are evaluated on
// the frame, the rows are grouped by them (`groups.mbt`), and every
// aggregation expression is evaluated once per group.
//
// An aggregation expression is evaluated in the "group context": a column
// outside an aggregation stands for the list of the group's values, which the
// library cannot hold (it has no List type), so such an expression is
// refused. What is left are the expressions that give one value per group
// (`is_group_scalar`): aggregations, `len()`, literals and element-wise
// operations on those. They are evaluated in three steps:
//
// 1. every aggregation inside the expression becomes one value per group
//    (a "leaf", `eval_group_leaf`): the expression under it is evaluated once
//    on the whole frame when it works row by row (`is_row_level`) and
//    aggregated with `grouped_agg`, and group by group otherwise;
// 2. the leaves are put in a frame of one row per group, under made-up
//    names, in the place of the aggregations;
// 3. what remains of the expression is evaluated on that frame with
//    `eval_node`, so weak literals, `when`, `fill_null`, ... behave exactly
//    as in `select`.

// ---------------------------------------------------------------------------
// The expression tree
// ---------------------------------------------------------------------------

///|
/// The sub-expressions of a node, in order. `with_children` and
/// `map_children` are built on it, and `plan_check` (`eval.mbt`) reads the tree
/// through them: every new `ExprNode` arm needs one here and in
/// `with_children`, as well as in `eval_node`, `expand_node`, `output_name`
/// and `write_text`.
fn ExprNode::children(self : ExprNode) -> Array[ExprNode] {
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
/// The node with its sub-expressions replaced (as many as `children` gives).
fn ExprNode::with_children(self : ExprNode, kids : Array[ExprNode]) -> ExprNode {
  match self {
    Column(_) | Columns(_) | All | Literal(_, _) | Len => self
    Binary(op, _, _) => Binary(op, kids[0], kids[1])
    Not(_) => Not(kids[0])
    Neg(_) => Neg(kids[0])
    Alias(_, name) => Alias(kids[0], name)
    Cast(_, dtype, strict) => Cast(kids[0], dtype, strict)
    IsNull(_) => IsNull(kids[0])
    IsNotNull(_) => IsNotNull(kids[0])
    Agg(op, _) => Agg(op, kids[0])
    NUnique(_) => NUnique(kids[0])
    Func(f, _) => Func(f, kids[0])
    IsIn(_, values) => IsIn(kids[0], values)
    FillNull(_, _) => FillNull(kids[0], kids[1])
    Between(_, _, _, closed) => Between(kids[0], kids[1], kids[2], closed)
    Ternary(_, _, _) => Ternary(kids[0], kids[1], kids[2])
    Seq(op, _) => Seq(op, kids[0])
    Str(op, _) => Str(op, kids[0])
    Dt(f, _) => Dt(f, kids[0])
    Shape(op, _) => Shape(op, kids[0])
    Filter(_, _) => Filter(kids[0], kids[1])
    SortBy(_, _, descending, nulls_last) =>
      SortBy(kids[0], kids[1:].to_owned(), descending, nulls_last)
    AnyAll(is_any, ignore_nulls, _) => AnyAll(is_any, ignore_nulls, kids[0])
    Horizontal(op, _, ignore_nulls) => Horizontal(op, kids, ignore_nulls)
    Over(_, _) => Over(kids[0], kids[1:].to_owned())
  }
}

///|
/// The node with every `f(child)` in place of a child.
fn ExprNode::map_children(
  self : ExprNode,
  f : (ExprNode) -> ExprNode raise PolarsError,
) -> ExprNode raise PolarsError {
  let kids = self.children()
  if kids.length() == 0 {
    return self
  }
  let out : Array[ExprNode] = Array(capacity=kids.length())
  for k in kids {
    out.push(f(k))
  }
  self.with_children(out)
}

///|
/// Adds the names of the columns `node` reads to `out` (each once).
fn collect_columns(
  node : ExprNode,
  seen : Map[String, Bool],
  out : Array[String],
) -> Unit {
  match node {
    Column(name) =>
      if !seen.contains(name) {
        seen[name] = true
        out.push(name)
      }
    _ =>
      for k in node.children() {
        collect_columns(k, seen, out)
      }
  }
}

///|
/// Whether the expression gives one value per group when it is evaluated in
/// the group context: an aggregation, `len()` or a literal does, and so does
/// an element-wise operation (or a sequence operation, which sees one value
/// per group) on such values. A column on its own is the list of the group's
/// values, and so is anything built on it outside an aggregation. `is_in` is
/// a list in polars even on a single value.
///
/// The answer depends on the shape of the expression only, not on the number
/// of rows of the groups.
fn is_group_scalar(node : ExprNode) -> Bool {
  match node {
    Agg(_, _) | NUnique(_) | Len | Literal(_, _) | AnyAll(_, _, _) => true
    Column(_) | Columns(_) | All | IsIn(_, _) => false
    // sorting one value per group leaves it a value per group; a cut, a
    // de-duplication or a filter is a list in polars even then
    Shape(Sort(_, _), x) | Shape(ArgSort(_, _), x) => is_group_scalar(x)
    Shape(_, _) | Filter(_, _) => false
    // a window gives a value for every row of its group (a list per group
    // in polars, whatever is under it)
    Over(_, _) => false
    SortBy(x, keys, _, _) =>
      is_group_scalar(x) && keys.iter().all(k => is_group_scalar(k))
    Horizontal(_, xs, _) => xs.iter().all(x => is_group_scalar(x))
    Not(x)
    | Neg(x)
    | Alias(x, _)
    | Cast(x, _, _)
    | IsNull(x)
    | IsNotNull(x)
    | Func(_, x)
    | Seq(_, x)
    | Str(_, x)
    | Dt(_, x) => is_group_scalar(x)
    Binary(_, l, r) => is_group_scalar(l) && is_group_scalar(r)
    FillNull(x, v) => is_group_scalar(x) && is_group_scalar(v)
    Between(x, lo, hi, _) =>
      is_group_scalar(x) && is_group_scalar(lo) && is_group_scalar(hi)
    Ternary(c, t, o) =>
      is_group_scalar(c) && is_group_scalar(t) && is_group_scalar(o)
  }
}

///|
/// Whether the expression works row by row, so that evaluating it once on
/// the whole frame and cutting the result into groups gives what evaluating
/// it on each group gives: no aggregation, `len()` or sequence operation in
/// it (those look at the group). Every `ExprNode` arm is listed on purpose
/// (no wildcard): a new arm must be classified here, and in
/// `is_group_scalar`, before the package compiles. A node that changes the
/// number of rows, reorders them or looks at the rest of the group (head,
/// sort, filter, unique, any, all, ...) is not row level.
fn is_row_level(node : ExprNode) -> Bool {
  match node {
    Column(_) | Literal(_, _) => true
    Columns(_) | All | Agg(_, _) | NUnique(_) | Len | Seq(_, _) => false
    // they sort, cut or look at the rest of the group (`any` and `all` reduce
    // it): never evaluated once on the whole frame
    Shape(_, _) | Filter(_, _) | SortBy(_, _, _, _) | AnyAll(_, _, _) => false
    // a window partitions the rows it sees: inside a group it partitions that
    // group, not the whole frame (`eval_sub`)
    Over(_, _) => false
    // `to_date` and `to_datetime` guess the format from the first value they
    // see, so a group is parsed by its own first value (as polars does), not
    // by the first value of the whole column
    Str(ToDate(_), _) | Str(ToDatetime(_), _) => false
    Horizontal(_, xs, _) => xs.iter().all(x => is_row_level(x))
    Not(x)
    | Neg(x)
    | Alias(x, _)
    | Cast(x, _, _)
    | IsNull(x)
    | IsNotNull(x)
    | Func(_, x)
    | IsIn(x, _)
    | Str(_, x)
    | Dt(_, x) => is_row_level(x)
    Binary(_, l, r) | FillNull(l, r) => is_row_level(l) && is_row_level(r)
    Between(x, lo, hi, _) =>
      is_row_level(x) && is_row_level(lo) && is_row_level(hi)
    Ternary(c, t, o) => is_row_level(c) && is_row_level(t) && is_row_level(o)
  }
}

///|
/// Whether the node itself makes an expression a window partition polars
/// refuses inside `agg` as not elementwise: an aggregation, `len()`, `any`,
/// a sequence operation, one that sorts, cuts or filters the rows, a nested
/// window, or `str().to_date()` / `to_datetime()` (the format is guessed from
/// the first value).
fn group_key_not_elementwise(node : ExprNode) -> Bool {
  node
  is (Agg(_, _)
  | NUnique(_)
  | Len
  | AnyAll(_, _, _)
  | Seq(_, _)
  | Shape(_, _)
  | Filter(_, _)
  | SortBy(_, _, _, _)
  | Over(_, _)
  | Str(ToDate(_), _)
  | Str(ToDatetime(_), _))
}

///|
/// Whether `node` holds a window (`over`) whose partition expression is not
/// elementwise (`group_key_not_elementwise`, anywhere in the partition).
fn group_has_bad_window(node : ExprNode) -> Bool {
  if node is Over(_, keys) &&
    keys.iter().any(k => join_node_any(k, group_key_not_elementwise)) {
    return true
  }
  node.children().iter().any(c => group_has_bad_window(c))
}

///|
/// polars returns a list per group for such an expression; the library has
/// no List type.
fn group_list_error(node : ExprNode) -> PolarsError {
  InvalidOperation(
    "expression \{node.text()} does not reduce each group to one value; this library has no List type, so aggregate it (for example with first(), sum() or len())",
  )
}

// ---------------------------------------------------------------------------
// Evaluation in the group context
// ---------------------------------------------------------------------------

///|
/// The columns of `df` an expression reads, as a frame of the rows `rows`.
/// A frame needs a column to have a height: with none read, a `Null` column
/// stands in (`len()` counts it).
fn group_sub_frame(
  df : DataFrame,
  used : Array[String],
  rows : Array[Int32],
) -> DataFrame raise PolarsError {
  let cols : Array[Series] = Array(capacity=used.length() + 1)
  for name in used {
    let s = frame_column(df, name)
    cols.push(Series::make(name, s.col.gather(rows)))
  }
  if cols.length() == 0 {
    cols.push(Series::null("rows", rows.length()))
  }
  DataFrame::from_valid(cols)
}

///|
/// What `op` makes of `s`: the aggregation `agg` or, for `None`, `n_unique`.
/// polars aggregates a column of the frame (or a row by row expression of
/// columns) with the `group_by` flavour of the aggregation (`group_xagg`), but
/// the values an expression with aggregations inside it gave for a group
/// (`listed`) like any column of values (`xagg_agg`): the two differ in the
/// last digits of a float sum, mean, variance and standard deviation.
fn group_leaf_apply(
  s : Series,
  agg : AggOp?,
  listed~ : Bool = false,
  whole~ : Bool = false,
) -> Series raise PolarsError {
  match agg {
    Some(op) =>
      if listed || whole {
        xagg_agg(s, op)
      } else {
        group_xagg(s, op)
      }
    None => xagg_n_unique(s)
  }
}

///|
/// Whether `node` is an aggregation, `n_unique` or `len()` (a value of its own
/// for the group).
fn is_group_leaf(node : ExprNode) -> Bool {
  match node {
    Agg(_, _) | NUnique(_) | Len | AnyAll(_, _, _) => true
    _ => false
  }
}

///|
/// polars names the series of a group `''`: the strict `to_date` and
/// `to_datetime` error raised inside `agg` or `over` says `in column ''`, not
/// the name of the column.
fn group_unnamed_error(e : PolarsError) -> PolarsError {
  guard e is InvalidOperation(m) else { return e }
  for
    prefix in [
      "conversion from `str` to `date` failed in column '", "conversion from `str` to `datetime[μs]` failed in column '",
    ] {
    if m.has_prefix(prefix) {
      let rest = m[prefix.length():]
      if rest.find("' for ") is Some(k) {
        return InvalidOperation(prefix + rest[k:].to_owned())
      }
    }
  }
  e
}

///|
/// `node` evaluated on the rows of one group (`sub`) the way polars does a
/// group: an aggregation inside the expression is the `group_by` flavour of
/// that aggregation (`group_xagg`), `len()` is the number of rows of the group.
/// What the aggregations leave of the expression is evaluated on a frame of the
/// group's columns and the aggregated values (each repeated for every row, or
/// on their own when no column is left), with `eval_node`; a divisor made of
/// aggregated values only stays one row (`group_scalar_divisors`).
fn eval_sub(
  sub : DataFrame,
  node : ExprNode,
  whole~ : Bool = false,
) -> Series raise PolarsError {
  eval_sub_plain(sub, node, whole~) catch {
    // polars words the length error of a `sort_by` in a group (a filtered
    // base next to keys of every row) differently from the one of `select`
    ShapeMismatch(m) if node is SortBy(_, _, _, _) &&
      m.has_prefix("`sort_by` produced different length") =>
      raise ShapeMismatch(
        "expressions in 'sort_by' must have matching group lengths",
      )
    e => raise if whole { e } else { group_unnamed_error(e) }
  }
}

///|
fn eval_sub_plain(
  sub : DataFrame,
  node : ExprNode,
  whole~ : Bool,
) -> Series raise PolarsError {
  if is_row_level(node) {
    return eval_node(sub, node)
  }
  match node {
    Agg(op, x) =>
      if whole {
        xagg_agg(eval_sub(sub, x, whole~), op)
      } else {
        group_xagg(eval_sub(sub, x), op)
      }
    NUnique(x) => xagg_n_unique(eval_sub(sub, x, whole~))
    AnyAll(is_any, ignore_nulls, x) =>
      any_all_series(eval_sub(sub, x, whole~), is_any, ignore_nulls)
    Len => Series::int64("len", [sub.height().to_int64()])
    // a window of the group is evaluated on the group's own rows
    Over(_, _) => eval_node(sub, node)
    // in a group (a window, an aggregation) one value per group is not
    // repeated to sort by a key of many values; a group of one row has keys
    // of one value, as long as the scalar
    SortBy(x, keys, _, _) if sub.height() != 1 &&
      is_group_scalar(x) &&
      keys.iter().any(k => !is_group_scalar(k)) =>
      raise ShapeMismatch(
        "expressions in 'sort_by' must have matching group lengths",
      )
    _ => {
      let leaves = GroupLeaves::new(sub.columns())
      let rewritten0 = node.map_children(k => {
        sub_rewrite(sub, k, leaves, whole~)
      })
      // a divisor made of aggregated values only stays a one-row value
      let leaf_frame = DataFrame::from_valid(leaves.series)
      let rewritten = group_scalar_divisors(rewritten0, leaves, leaf_frame) catch {
        e => raise leaves.fix_error(e)
      }
      let used : Array[String] = []
      collect_columns(rewritten, Map([]), used)
      let cols : Array[Series] = []
      let mut has_rows = false
      for name in used {
        if !leaves.is_leaf(name) {
          has_rows = true
        }
      }
      if has_rows {
        for s in sub.get_columns() {
          cols.push(s)
        }
        for s in leaves.series {
          cols.push(Series::make(s.name, s.col.broadcast(sub.height())))
        }
      } else {
        for s in leaves.series {
          cols.push(s)
        }
      }
      // (these are one row; a frame's height is its first column's)
      for s in leaves.scalars {
        cols.push(s)
      }
      eval_node(DataFrame::from_valid(cols), rewritten) catch {
        e => raise leaves.fix_error(e)
      }
    }
  }
}

///|
/// Whether `node` reads values of aggregations only (at least one), no column
/// of the frame.
fn group_leaf_only(node : ExprNode, leaves : GroupLeaves) -> Bool {
  let used : Array[String] = []
  collect_columns(node, Map([]), used)
  used.length() > 0 && used.iter().all(n => leaves.is_leaf(n))
}

///|
/// `node` with the right operand of every division (`/`, `//`, `%`) that is
/// made of the values of aggregations only evaluated on its own, and standing
/// in the tree as a one-row column (`GroupLeaves::add_scalar`). polars keeps
/// an aggregated value a scalar when it divides the rows of a group, and
/// divides a float column by a scalar by multiplying with its reciprocal
/// (`x / x.sum()` is `x * (1 / x.sum())`, which can differ from the plain
/// quotient in the last digit): a column of repeated values would divide
/// plainly.
fn group_scalar_divisors(
  node : ExprNode,
  leaves : GroupLeaves,
  leaf_frame : DataFrame,
) -> ExprNode raise PolarsError {
  match node {
    // a division of aggregated values by aggregated values is a scalar
    // divided by a scalar (a plain quotient); only what it meets next sees
    // a scalar
    Binary(op, _, r) if op is (Div | FloorDiv | Rem) &&
      group_leaf_only(r, leaves) &&
      group_leaf_only(node, leaves) => {
      let value = eval_node(leaf_frame, node)
      leaves.add_scalar(value, output_name(node))
    }
    Binary(op, l, r) if op is (Div | FloorDiv | Rem) &&
      group_leaf_only(r, leaves) => {
      let l2 = group_scalar_divisors(l, leaves, leaf_frame)
      let value = eval_node(leaf_frame, r)
      Binary(op, l2, leaves.add_scalar(value, output_name(r)))
    }
    _ => node.map_children(k => group_scalar_divisors(k, leaves, leaf_frame))
  }
}

///|
fn sub_rewrite(
  sub : DataFrame,
  node : ExprNode,
  leaves : GroupLeaves,
  whole~ : Bool,
) -> ExprNode raise PolarsError {
  if is_group_leaf(node) {
    return leaves.add(eval_sub(sub, node, whole~), node)
  }
  // a window is evaluated whole, on the rows of the group (its own
  // aggregations see the window, not the group)
  if node is Over(_, _) {
    return node
  }
  node.map_children(k => sub_rewrite(sub, k, leaves, whole~))
}

///|
/// `agg(x)` (or `n_unique(x)` for `None`) of every group, one value each. The
/// expression `x` is evaluated on the whole frame once when it works row by
/// row, group by group otherwise.
fn eval_group_agg(
  df : DataFrame,
  groups : GroupIndex,
  agg : AggOp?,
  x : ExprNode,
  name : String,
) -> Series raise PolarsError {
  let ng = groups.length()
  if is_row_level(x) {
    let s = eval_node(df, x)
    if s.len() == groups.ids.length() {
      let col = match agg {
        Some(op) => grouped_agg(s.col, groups, op)
        None => grouped_n_unique(s.col, groups)
      }
      return Series::make(name, col)
    }
    // a literal (or an expression of literals only): every group sees one
    // value; a Series of that one value, aggregated, is the value of a group
    let one = group_leaf_apply(s, agg, whole=groups.whole)
    return Series::make(name, one.col.broadcast(ng))
  }
  let used : Array[String] = []
  collect_columns(x, Map([]), used)
  if ng == 0 {
    let s = eval_sub(df.head(n=0), x, whole=groups.whole)
    return Series::make(
      name,
      group_leaf_apply(s, agg, whole=groups.whole).col.slice(0, 0),
    )
  }
  let parts : Array[Column] = Array(capacity=ng)
  for g in 0..<ng {
    let sub = group_sub_frame(df, used, groups.rows(g).to_owned())
    parts.push(
      group_leaf_apply(eval_sub(sub, x, whole=groups.whole), agg, listed=true).col,
    )
  }
  Series::make(name, Column::concat(parts))
}

///|
/// The sequence operation `op` of an already aggregated value: it sees one
/// value per group, so it is applied to each group's value on its own (the
/// running sum of one value is that value, a shift of one value is null).
fn eval_group_seq(
  df : DataFrame,
  groups : GroupIndex,
  op : SeqOp,
  x : ExprNode,
  name : String,
) -> Series raise PolarsError {
  let child = eval_grouped(df, groups, x)
  let ng = groups.length()
  if ng == 0 {
    return op.apply(child).rename(name)
  }
  let parts : Array[Column] = Array(capacity=ng)
  for g in 0..<ng {
    parts.push(op.apply(child.slice(g, length=1)).col)
  }
  Series::make(name, Column::concat(parts))
}

///|
/// `sort` or `arg_sort` (`op`) of an already aggregated value, as for
/// `eval_group_seq`: applied to each group's one value on its own (sorting one
/// value gives that value, its `arg_sort` is 0), never across the groups.
fn eval_group_shape(
  df : DataFrame,
  groups : GroupIndex,
  op : ShapeOp,
  x : ExprNode,
  name : String,
) -> Series raise PolarsError {
  let child = eval_grouped(df, groups, x)
  let ng = groups.length()
  if ng == 0 {
    return op.apply(child).rename(name)
  }
  let parts : Array[Column] = Array(capacity=ng)
  for g in 0..<ng {
    parts.push(op.apply(child.slice(g, length=1)).col)
  }
  Series::make(name, Column::concat(parts))
}

///|
/// `any` or `all` of `x` for every group: one `Boolean` value each.
fn eval_group_any_all(
  df : DataFrame,
  groups : GroupIndex,
  is_any : Bool,
  ignore_nulls : Bool,
  x : ExprNode,
  name : String,
) -> Series raise PolarsError {
  let ng = groups.length()
  let used : Array[String] = []
  collect_columns(x, Map([]), used)
  if ng == 0 {
    let s = eval_sub(df.head(n=0), x, whole=groups.whole)
    return Series::make(
      name,
      any_all_series(s, is_any, ignore_nulls).col.slice(0, 0),
    )
  }
  let parts : Array[Column] = Array(capacity=ng)
  for g in 0..<ng {
    let sub = group_sub_frame(df, used, groups.rows(g).to_owned())
    parts.push(
      any_all_series(eval_sub(sub, x, whole=groups.whole), is_any, ignore_nulls).col,
    )
  }
  Series::make(name, Column::concat(parts))
}

///|
/// The values that stand in for the aggregations of an expression while the
/// rest of it is evaluated: each one is a column of a frame under a made-up
/// name, which starts with `pre`. `pre` is chosen so that no column of the
/// frame the expression reads starts with it (`pre` grows until that holds),
/// so a made-up name never collides with a user column. A made-up name may
/// show in the text of an error raised while the rest is evaluated;
/// `fix_error` puts the name of the user's expression back.
priv struct GroupLeaves {
  pre : String
  series : Array[Series]
  origs : Array[String]
  /// divisors kept as one row (`group_scalar_divisors`) and their shown names
  scalars : Array[Series]
  scalar_origs : Array[String]
}

///|
/// Leaves for an expression that reads the columns `taken`.
fn GroupLeaves::new(taken : Array[String]) -> GroupLeaves {
  let mut pre = "group leaf"
  while taken.iter().any(c => c.has_prefix(pre)) {
    pre = pre + "_"
  }
  { pre, series: [], origs: [], scalars: [], scalar_origs: [], }
}

///|
fn GroupLeaves::name(self : GroupLeaves, i : Int32) -> String {
  "\{self.pre} \{i}"
}

///|
/// The made-up name of the `i`-th one-row divisor (it starts like a leaf name,
/// so `is_leaf` holds for it).
fn GroupLeaves::scalar_name(self : GroupLeaves, i : Int32) -> String {
  "\{self.pre} s\{i}"
}

///|
/// Adds the one-row value `s` of a divisor and returns the column that stands
/// for it. `orig` is its output name in the expression (a leaf's made-up
/// name is turned into the name of the aggregation it stands for).
fn GroupLeaves::add_scalar(
  self : GroupLeaves,
  s : Series,
  orig : String,
) -> ExprNode {
  let name = self.scalar_name(self.scalars.length())
  self.scalars.push(s.rename(name))
  let mut shown = orig
  for i in 0..<self.series.length() {
    if self.name(i) == orig {
      shown = self.origs[i]
    }
  }
  self.scalar_origs.push(shown)
  ExprNode::Column(name)
}

///|
/// Adds the value `s` of the aggregation `orig` and returns the column that
/// stands for it.
fn GroupLeaves::add(
  self : GroupLeaves,
  s : Series,
  orig : ExprNode,
) -> ExprNode {
  let name = self.name(self.series.length())
  self.series.push(s.rename(name))
  self.origs.push(output_name(orig))
  ExprNode::Column(name)
}

///|
/// Whether `name` is one of the made-up names.
fn GroupLeaves::is_leaf(self : GroupLeaves, name : String) -> Bool {
  name.has_prefix(self.pre + " ")
}

///|
/// `e` with the made-up names in its message replaced by the output names of
/// the aggregations they stand for.
fn GroupLeaves::fix_error(self : GroupLeaves, e : PolarsError) -> PolarsError {
  // only a made-up name between the quotes the library puts around a column
  // name (`'x'`, `` `x` ``) is a made-up name: the same characters inside a
  // user's column name or value (`'wgroup leaf 0'`, `["group leaf 0"]`) are
  // not touched
  let fix = (m : String) => {
    let mut out = m
    for i in 0..<self.series.length() {
      let name = self.name(i)
      let orig = self.origs[i]
      out = out.replace_all(old="'\{name}'", new="'\{orig}'")
      out = out.replace_all(old="`\{name}`", new="`\{orig}`")
    }
    for i in 0..<self.scalars.length() {
      let name = self.scalar_name(i)
      let orig = self.scalar_origs[i]
      out = out.replace_all(old="'\{name}'", new="'\{orig}'")
      out = out.replace_all(old="`\{name}`", new="`\{orig}`")
    }
    out
  }
  match e {
    ColumnNotFound(m) => ColumnNotFound(fix(m))
    DuplicateColumn(m) => DuplicateColumn(fix(m))
    SchemaMismatch(m) => SchemaMismatch(fix(m))
    ShapeMismatch(m) => ShapeMismatch(fix(m))
    OutOfBounds(m) => OutOfBounds(fix(m))
    InvalidOperation(m) => InvalidOperation(fix(m))
    ComputeError(m) => ComputeError(fix(m))
    ParseError(m) => ParseError(fix(m))
    IOError(m) => IOError(fix(m))
  }
}

///|
/// Replaces the aggregations (and sequence operations) in `node` by columns
/// of `leaves`, evaluating each one; a literal stays as it is.
fn group_rewrite(
  df : DataFrame,
  groups : GroupIndex,
  node : ExprNode,
  leaves : GroupLeaves,
) -> ExprNode raise PolarsError {
  match node {
    Agg(op, x) =>
      leaves.add(eval_group_agg(df, groups, Some(op), x, "leaf"), node)
    NUnique(x) => leaves.add(eval_group_agg(df, groups, None, x, "leaf"), node)
    Len =>
      leaves.add(
        Series::int64("leaf", groups.sizes().map(n => n.to_int64())),
        node,
      )
    Seq(op, x) => leaves.add(eval_group_seq(df, groups, op, x, "leaf"), node)
    AnyAll(is_any, ignore_nulls, x) =>
      leaves.add(
        eval_group_any_all(df, groups, is_any, ignore_nulls, x, "leaf"),
        node,
      )
    // only `sort` and `arg_sort` of a value per group get here (the others
    // are lists, refused before): one value per group, sorted on its own
    Shape(op, x) =>
      leaves.add(eval_group_shape(df, groups, op, x, "leaf"), node)
    // sorting one value per group by values per group leaves that value; the
    // keys are still evaluated, for their errors
    SortBy(x, keys, _, _) => {
      let out = group_rewrite(df, groups, x, leaves)
      for k in keys {
        ignore(group_rewrite(df, groups, k, leaves))
      }
      out
    }
    Column(_) | Columns(_) | All =>
      abort("group_rewrite: a column outside an aggregation")
    _ => node.map_children(k => group_rewrite(df, groups, k, leaves))
  }
}

///|
/// One expanded aggregation expression in the group context: a series with
/// one value per group, named like the expression.
///
/// # Errors
/// `InvalidOperation` (the List message) when the expression is not one
/// value per group, and what the aggregations and operations inside raise.
fn eval_grouped(
  df : DataFrame,
  groups : GroupIndex,
  node : ExprNode,
) -> Series raise PolarsError {
  if !is_group_scalar(node) {
    raise group_list_error(node)
  }
  // the frame of the leaves has no other column: nothing to collide with
  let leaves = GroupLeaves::new([])
  let rewritten = group_rewrite(df, groups, node, leaves)
  let out = match rewritten {
    // an aggregation on its own: its leaf is the result
    Column(name) if leaves.series.length() == 1 && name == leaves.name(0) =>
      leaves.series[0]
    _ =>
      eval_node(DataFrame::from_valid(leaves.series), rewritten) catch {
        e => raise leaves.fix_error(e)
      }
  }
  fit_height(out, groups.length()).rename(output_name(node))
}

// ---------------------------------------------------------------------------
// GroupBy
// ---------------------------------------------------------------------------

///|
/// The rows of a frame split into groups by key expressions, waiting for
/// `agg` or `len`. Made by `DataFrame::group_by`; nothing is evaluated until
/// then.
struct GroupBy {
  df : DataFrame
  keys : Array[Expr]
}

///|
/// Groups the rows by equal values of the `by` expressions (several columns
/// make a group of equal combinations); aggregate them with `GroupBy::agg`
/// or count them with `GroupBy::len`. A key is any expression (`col("a")`,
/// `col("a") % lit_int(2)`, `cols([...])`); a name that stands for several
/// columns (`cols`, `all`) gives one key per column. No key at all makes one
/// group of every row (a frame without rows gives one group of no rows,
/// as in polars).
///
/// Null is a key value of its own, NaN equals NaN and `-0.0` equals `0.0`
/// (the group shows the first one that appears). The groups come in the order
/// of their first row. polars keeps that order only for `maintain_order=true`;
/// this library always does, and `maintain_order` is accepted for
/// compatibility only.
///
/// Errors (a missing column, a bad key) are raised by `agg` or `len`, not
/// here.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::str("k", ["b", "a", "b"]),
///     @pl.Series::int64("v", [1L, 2L, 3L]),
///   ])
///   let out = df.group_by([@pl.col("k")]).agg([@pl.col("v").sum()])
///   assert_eq(out.column("k").to_str_array(), [Some("b"), Some("a")])
///   assert_eq(out.column("v").to_int64_array(), [Some(4L), Some(2L)])
/// }
/// ```
pub fn DataFrame::group_by(
  self : DataFrame,
  by : Array[Expr],
  maintain_order~ : Bool = false,
) -> GroupBy {
  ignore(maintain_order)
  { df: self, keys: by, }
}

///|
/// polars' error for two group keys with the same output name.
fn group_key_duplicate(name : String) -> PolarsError {
  DuplicateColumn(
    "group_by keys contained duplicate output name '\{name}'. It's possible that multiple expressions are returning the same default column name. If this is the case, try renaming the columns with `.alias(\"new_name\")` to avoid duplicate column names.",
  )
}

///|
/// polars' error for two output columns with the same name.
fn group_output_duplicate(name : String) -> PolarsError {
  DuplicateColumn("column with name '\{name}' has more than one occurrence")
}

///|
/// The key expressions expanded (selectors turned into columns), with their
/// columns looked up and their output names checked, key by key in order.
fn group_key_nodes(
  df : DataFrame,
  keys : Array[Expr],
) -> Array[ExprNode] raise PolarsError {
  let nodes : Array[ExprNode] = []
  for k in keys {
    for node in expand_selectors(df, k) {
      nodes.push(node)
    }
  }
  let seen : Map[String, Bool] = Map([])
  for node in nodes {
    check_columns(df, node)
    let name = output_name(node)
    if seen.contains(name) {
      raise group_key_duplicate(name)
    }
    seen[name] = true
  }
  nodes
}

///|
/// `Columns` of the frame's columns without the names in `names` in place of
/// every `all()` in `node`: polars leaves the group keys out of a wildcard
/// in `agg`.
fn group_without_keys(
  df : DataFrame,
  node : ExprNode,
  names : Map[String, Bool],
) -> ExprNode raise PolarsError {
  match node {
    All => Columns(df.columns().filter(c => !names.contains(c)))
    _ => node.map_children(k => group_without_keys(df, k, names))
  }
}

///|
/// Whether `e` is an error polars raises while it resolves the types of an
/// expression, before it runs anything: an aggregation a type does not have
/// (`sum`, `mean`, `median`, `std`, `var`, `quantile` of text; `product` is
/// refused only when polars runs it, and so is `|` of a float and an integer),
/// and the errors `is_plan_time_error` lists.
fn group_is_plan_error(e : PolarsError) -> Bool {
  match e {
    InvalidOperation(m) =>
      ["sum", "mean", "median", "std", "var", "quantile"]
      .iter()
      .any(op => m.has_prefix("`\{op}` operation not supported for dtype `")) ||
      is_plan_time_error(e)
    _ => is_plan_time_error(e)
  }
}

///|
/// Raises the first error evaluating `nodes` on a frame without rows gives, if
/// it is one polars raises when it resolves the types (`group_is_plan_error`).
fn group_plan_probe(
  df0 : DataFrame,
  nodes : Array[ExprNode],
) -> Unit raise PolarsError {
  for node in nodes {
    ignore(eval_node(df0, node)) catch {
      e => if group_is_plan_error(e) { raise e }
    }
  }
}

///|
/// Raises the first error evaluating the key and aggregation expressions on a
/// frame without rows gives, in polars' order: the errors polars finds when it
/// resolves the types of the expressions come first, the keys before the
/// aggregations and each in the order of the expressions (an aggregation a
/// type does not have, "`sum` operation not supported for dtype `str`", and
/// the type errors `is_plan_time_error` knows: `&` of an integer and a
/// Boolean, arithmetic on a `Date`); then the errors of running a kernel
/// (arithmetic on text, a failed cast), the aggregations before the keys.
///
/// Known limit: the class of an error is decided from its text
/// (`group_is_plan_error`); see `docs/golden/known-diffs/group_by.md`.
fn group_probe(
  df0 : DataFrame,
  aggs : Array[ExprNode],
  keys : Array[ExprNode],
) -> Unit raise PolarsError {
  let probe = (node : ExprNode) => {
    try {
      ignore(eval_node(df0, node))
      None
    } catch {
      // a literal or an aggregate sorted by the rows of a frame without rows: the
      // key has no row to be as long as, which says nothing about the groups
      // (a group of one row is fine; the evaluation of the groups decides)
      ShapeMismatch(m) if m.has_prefix(
          "`sort_by` produced different length (0) than the Series that has to be sorted (1)",
        ) => None
      e => Some(e)
    }
  }
  let key_errors = keys.map(probe)
  let agg_errors = aggs.map(probe)
  for errors in [key_errors, agg_errors] {
    for e in errors {
      if e is Some(err) && group_is_plan_error(err) {
        raise err
      }
    }
  }
  for errors in [agg_errors, key_errors] {
    for e in errors {
      if e is Some(err) {
        raise err
      }
    }
  }
}

///|
/// Evaluates the key expressions and groups the rows by them. One-row keys
/// (a literal, an aggregation) are repeated to the height of the frame; a
/// frame without rows and nothing but one-row keys is one group without
/// rows. Returns the key columns as evaluated (not cut to the groups) and
/// the groups.
fn group_by_keys(
  df : DataFrame,
  key_nodes : Array[ExprNode],
) -> (Array[Series], GroupIndex) raise PolarsError {
  let height = df.height()
  let series : Array[Series] = []
  for node in key_nodes {
    series.push(eval_node(df, node))
  }
  if series.length() == 0 {
    return (series, GroupIndex::from_keys([], height))
  }
  if height == 0 && series.iter().all(s => s.len() == 1) {
    return (series, GroupIndex::ghost())
  }
  let fitted : Array[Series] = Array(capacity=series.length())
  for s in series {
    fitted.push(fit_height(s, height))
  }
  let groups = GroupIndex::from_keys(fitted.map(s => s.col), height)
  // keys that are one value each (a literal, an aggregation, `len()`) make one
  // group of every row, aggregated by the kernels of `select`
  (
    fitted,
    if key_nodes.iter().all(n => is_group_scalar(n)) {
      groups.as_whole()
    } else {
      groups
    },
  )
}

///|
/// The key columns of the result: each key's value in the first row of every
/// group.
fn group_key_columns(
  keys : Array[Series],
  groups : GroupIndex,
) -> Array[Series] {
  let firsts = groups.first_rows()
  keys.map(s => Series::make(s.name, s.col.gather(firsts)))
}

///|
/// Aggregates every group with the expressions `aggs` and returns the keys
/// of the groups followed by the aggregated columns: one row per group,
/// the groups in the order of their first row (see `DataFrame::group_by`).
///
/// - An expression is evaluated once per group, with `col("a")` standing for
///   the group's values: `col("a").sum()`, `(col("a") * col("b")).sum()`,
///   `(col("a") - col("a").mean()).sum()`, `col("a").sum() / len()`,
///   `col("a").cum_sum().last()`. The result column is named as in `select`
///   (the leftmost column, `literal`, `len`, or the alias); a literal gives
///   its value for every group.
/// - `all()` stands for every column that is not a key (keys are named by
///   their output names, so a key `col("a") % lit_int(2)` is called `a`).
///   `cols([...])` is taken as it is.
/// - Types are those of `select`; `count`, `len`, `n_unique` are `Int64`.
///   Aggregating a group without rows (no key on a frame without rows) gives
///   the aggregate of an empty column: 0 for `sum`, null for `mean`.
/// - An expression that does not give one value per group (`col("b")` on its
///   own, `col("b") + 1`, `col("b").cum_sum()`, `col("b") + col("b").sum()`,
///   `is_in`) is a list per group in polars; this library has no List type
///   and raises `InvalidOperation` (`expression col("b") does not reduce each
///   group to one value; this library has no List type, so aggregate it (for
///   example with first(), sum() or len())`). The test looks at the shape of
///   the expression only: a group of a single row is no exception.
/// - With no key a frame without rows is one group without rows; with a key
///   it has no groups and the result has no rows, but its columns have the
///   types of the same aggregation on a frame with rows.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::str("k", ["b", "a", "b"]),
///     @pl.Series::int64("v", [1L, 2L, 3L]),
///   ])
///   let out = df.group_by([@pl.col("k")]).agg([@pl.col("v").sum(), @pl.len()])
///   assert_eq(out.columns(), ["k", "v", "len"])
///   assert_eq(out.column("len").to_int64_array(), [Some(2L), Some(1L)])
/// }
/// ```
///
/// # Errors
/// In polars' order, which differs from `select`: `ColumnNotFound` for a
/// missing column (`cols` names first, then columns in the keys, then those
/// in the aggregations); `DuplicateColumn` for two keys with one output name
/// (checked key by key, a key's own columns first); the error of an
/// aggregation a type does not have (`InvalidOperation`, before any other
/// type error), then the other type errors of the aggregations and of the
/// keys; `DuplicateColumn` (`column with name 'a' has more than one
/// occurrence`) for a key and an aggregation, or two aggregations, with one
/// name; `InvalidOperation` for an expression that is not one value per group
/// (the first one); then what the evaluation raises. A quantile outside
/// `[0, 1]` raises `ComputeError` (polars gives null in a group_by).
pub fn GroupBy::agg(
  self : GroupBy,
  aggs : Array[Expr],
) -> DataFrame raise PolarsError {
  let df = self.df
  let key_nodes = group_key_nodes(df, self.keys)
  let key_names : Map[String, Bool] = Map([])
  for node in key_nodes {
    key_names[output_name(node)] = true
  }
  let expanded : Array[Array[ExprNode]] = []
  for e in aggs {
    let node = group_without_keys(df, e.node, key_names)
    expanded.push(expand_selectors(df, Expr::of(node)))
  }
  let agg_nodes : Array[ExprNode] = []
  for nodes in expanded {
    for node in nodes {
      agg_nodes.push(node)
    }
  }
  // a key whose types do not resolve is raised before a missing column of an
  // aggregation
  group_plan_probe(df.head(n=0), key_nodes)
  for node in agg_nodes {
    check_columns(df, node)
  }
  let df0 = df.head(n=0)
  group_probe(df0, agg_nodes, key_nodes)
  let (key_series, groups) = group_by_keys(df, key_nodes)
  // the names of the output: keys, then aggregations
  let seen : Map[String, Bool] = Map([])
  for node in key_nodes {
    seen[output_name(node)] = true
  }
  for node in agg_nodes {
    let name = output_name(node)
    if seen.contains(name) {
      raise group_output_duplicate(name)
    }
    seen[name] = true
  }
  // a window whose partition is not elementwise is refused in `agg`, before
  // anything runs and after the names and types are checked
  for node in agg_nodes {
    if group_has_bad_window(node) {
      raise InvalidOperation(
        "window expression with non-elementwise `partition_by` or `order_by` not allowed in aggregation context",
      )
    }
  }
  for node in agg_nodes {
    if !is_group_scalar(node) {
      raise group_list_error(node)
    }
  }
  let out = group_key_columns(key_series, groups)
  for node in agg_nodes {
    out.push(eval_grouped(df, groups, node))
  }
  DataFrame::new(out)
}

///|
/// The number of rows of every group: the keys of the groups followed by an
/// `Int64` column `name` (default `len`, polars' `GroupBy.len`). Groups
/// come in the order of their first row; see `DataFrame::group_by`.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::str("k", ["b", "a", "b"])])
///   let out = df.group_by([@pl.col("k")]).len(name="n")
///   assert_eq(out.columns(), ["k", "n"])
///   assert_eq(out.column("n").to_int64_array(), [Some(2L), Some(1L)])
/// }
/// ```
///
/// # Errors
/// As `GroupBy::agg` for the keys; `DuplicateColumn` when `name` is the name
/// of a key.
pub fn GroupBy::len(
  self : GroupBy,
  name~ : String = "len",
) -> DataFrame raise PolarsError {
  let df = self.df
  let key_nodes = group_key_nodes(df, self.keys)
  group_probe(df.head(n=0), [], key_nodes)
  let (key_series, groups) = group_by_keys(df, key_nodes)
  for node in key_nodes {
    if output_name(node) == name {
      raise group_output_duplicate(name)
    }
  }
  let out = group_key_columns(key_series, groups)
  out.push(Series::int64(name, groups.sizes().map(n => n.to_int64())))
  DataFrame::new(out)
}
