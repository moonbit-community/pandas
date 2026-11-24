// `when(...).then(...).otherwise(...)`.
//
// A chain `when(c1).then(v1).when(c2).then(v2).otherwise(v3)` is stored as
// nested ternaries, `c1 ? v1 : (c2 ? v2 : v3)`, like polars does: the error
// messages that count lengths and the evaluation order follow that nesting.

///|
/// A `when(condition)` that still waits for its `then`. See `when`.
struct When {
  /// the finished `(condition, value)` branches before this one
  done : Array[(ExprNode, ExprNode)]
  cond : ExprNode
}

///|
/// A `when(...).then(...)` that waits for `otherwise` (or another `when`).
/// See `when`.
struct Then {
  branches : Array[(ExprNode, ExprNode)]
}

///|
/// Starts a conditional expression: `when(cond).then(a).otherwise(b)` gives
/// `a` where `cond` is true and `b` elsewhere, and more branches can be
/// chained with `Then::when`: the first condition that is true decides.
///
/// - A null condition counts as false (the row goes to the next branch).
/// - The result type is the supertype of the branches (`Int32` and `Int64`
///   give `Int64`; a number and text give `String`; `Boolean` with a number
///   gives the number); weak literals (`lit_int`) adapt to the other
///   branches.
/// - The output name is that of the first `then`, as in polars (`lit_int(1)`
///   is called `literal`).
/// - The condition, `then` and `otherwise` are expressions of the frame's
///   height or of length 1 (a literal, an aggregate), which is repeated.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([
///     @pl.Series::int32_nullable("a", [Some(1), None, Some(3)]),
///   ])
///   let out = df.select([
///     @pl.when(@pl.col("a").gt(@pl.lit_int(1L)))
///     .then(@pl.lit_str("big"))
///     .otherwise(@pl.lit_str("small")),
///   ])
///   assert_eq(out.columns(), ["literal"])
///   assert_eq(out.column("literal").to_list(), [
///     @pl.AnyValue::String("small"),
///     @pl.AnyValue::String("small"),
///     @pl.AnyValue::String("big"),
///   ])
/// }
/// ```
///
/// # Errors
/// Evaluating the expression raises `SchemaMismatch` when the condition is
/// not `Boolean` (`invalid series dtype: expected `Boolean`, got `i32` for
/// series with name `a``; a `Null` column is not `Boolean` either) or when the
/// branches have no common type (`failed to determine supertype of bool and
/// date`), and `ShapeMismatch` when they have different lengths that are not
/// 1.
pub fn when(condition : Expr) -> When {
  { done: [], cond: condition.node, }
}

///|
/// The value where the condition of this `when` is true; see `when`.
pub fn When::then(self : When, value : Expr) -> Then {
  let branches = self.done.copy()
  branches.push((self.cond, value.node))
  { branches, }
}

///|
/// Adds a branch that is tried when the earlier conditions were not true;
/// see `when`.
pub fn Then::when(self : Then, condition : Expr) -> When {
  { done: self.branches.copy(), cond: condition.node, }
}

///|
/// The value where no condition was true, which ends the chain and gives the
/// expression; see `when`. The chain is nested into the `otherwise` of the
/// previous branch: polars prints
/// `.when(c1).then(a).otherwise(.when(c2).then(b).otherwise(c))`.
pub fn Then::otherwise(self : Then, value : Expr) -> Expr {
  let mut node = value.node
  let mut i = self.branches.length() - 1
  while i >= 0 {
    let (c, t) = self.branches[i]
    node = Ternary(c, t, node)
    i = i - 1
  }
  Expr::of(node)
}

///|
/// The common length of the three parts of a ternary: the one length that is
/// not 1, or 1 when all of them are.
///
/// # Errors
/// `ShapeMismatch` (polars' `zip_with` text) when two lengths that are not 1
/// differ.
fn when_length(
  cond : Int32,
  then : Int32,
  otherwise : Int32,
) -> Int32 raise PolarsError {
  let mut n = 1
  for k in [cond, then, otherwise] {
    if k != 1 {
      if n == 1 || n == k {
        n = k
      } else {
        raise ShapeMismatch(
          "shapes of `self`, `mask` and `other` are not suitable for `zip_with` operation",
        )
      }
    }
  }
  n
}

///|
/// The outcome of evaluating one part of a ternary: the parts are all
/// evaluated before it is decided which of their errors counts.
priv enum Attempt[T] {
  Done(T)
  Failed(PolarsError)
}

///|
fn[T] when_try(f : () -> T raise PolarsError) -> Attempt[T] {
  Done(f()) catch {
    e => Failed(e)
  }
}

///|
/// Whether `e` is an error polars raises while planning the query (the
/// supertype of two branches), before any column is evaluated.
fn when_plan_error(e : PolarsError) -> Bool {
  match e {
    SchemaMismatch(m) => m.has_prefix("failed to determine supertype")
    _ => false
  }
}

///|
/// Evaluates `when(c).then(t).otherwise(o)`. The three parts are evaluated,
/// then the errors are reported in the order polars reports them (checked
/// against 2.1.0, `docs/golden/expr_agg.json`, `when/err/*`):
///
/// 1. no common type of two branches, also in a nested `when` (polars finds
///    it when it plans the query);
/// 2. the condition: the error of evaluating it, then a type other than
///    `Boolean` (`SchemaMismatch`);
/// 3. the `then`, then the `otherwise` (which holds the later branches of a
///    chain, so a chain is checked branch by branch: condition, value, next
///    condition, ...).
///
/// Every part is evaluated, also when the condition has length 1 (and so
/// selects a whole branch): polars skips the runtime errors of the branch that
/// is not selected, this does not (see `known-diffs/expr_agg.md`).
///
/// A weak literal takes the type of the other branch (`xagg_resolve`); the
/// result is named after `then`.
///
/// # Errors
/// See `when`.
fn when_eval(
  df : DataFrame,
  c : ExprNode,
  t : ExprNode,
  o : ExprNode,
) -> Series raise PolarsError {
  let cr = when_try(() => eval_node(df, c))
  let tr = when_try(() => eval_operand(df, t))
  let orr = when_try(() => eval_operand(df, o))
  // 1. planning
  if tr is Failed(e) && when_plan_error(e) {
    raise e
  }
  if orr is Failed(e) && when_plan_error(e) {
    raise e
  }
  if cr is Failed(e) && when_plan_error(e) {
    raise e
  }
  let resolved : (Series, Series, DataType)? = match (tr, orr) {
    (Done(ao), Done(bo)) => {
      let (ts, os) = xagg_resolve(t, o, ao, bo)
      Some((ts, os, xagg_common_type(ts.dtype(), os.dtype())))
    }
    _ => None
  }
  // 2. the condition
  let cs = match cr {
    Done(s) => s
    Failed(e) => raise e
  }
  if cs.dtype() != Boolean {
    raise SchemaMismatch(
      "invalid series dtype: expected `Boolean`, got `\{cs.dtype()}` for series with name `\{cs.name}`",
    )
  }
  // 3. the branches
  guard resolved is Some((ts, os, ty)) else {
    if tr is Failed(e) {
      raise e
    }
    if orr is Failed(e) {
      raise e
    }
    abort("when_eval: no branch error and no result")
  }
  let n = when_length(cs.len(), ts.len(), os.len())
  let take = @arrow.BitmapBuilder::new(capacity=n)
  match cs.col.expand(n) {
    Boolean(b) =>
      for i in 0..<n {
        take.push(b.is_valid(i) && b.value(i))
      }
    _ => abort("when_eval: the condition is not Boolean")
  }
  let a = ts.col.cast_lenient(ty).expand(n)
  let b = os.col.cast_lenient(ty).expand(n)
  Series::make(ts.name, xagg_pick(take.finish(), a, b))
}
