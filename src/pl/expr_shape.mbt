// Expression methods that change the order or the length of a column:
// `sort`, `arg_sort`, `sort_by`, `head`, `tail`, `slice`, `unique`,
// `drop_nulls`, `filter`, and the reductions `any` and `all`.
//
// None of them is row-wise (row `i` of the result is not a function of row `i`
// of the input), see the list at the top of `eval.mbt`.

// ---------------------------------------------------------------------------
// The operations of one input
// ---------------------------------------------------------------------------

///|
/// A method of one expression that sorts it or cuts rows out of it.
priv enum ShapeOp {
  /// `Sort(descending, nulls_last)`
  Sort(Bool, Bool)
  /// `ArgSort(descending, nulls_last)`: an `Int64` column
  ArgSort(Bool, Bool)
  Head(Int32)
  Tail(Int32)
  /// `Slice(offset, length)`
  Slice(Int32, Int32?)
  /// `Unique(maintain_order)`
  Unique(Bool)
  DropNulls
}

///|
/// polars' text of the call: `head` and `tail` are slices in polars, so they
/// print as slices.
fn ShapeOp::text(self : ShapeOp) -> String {
  match self {
    Sort(descending, _) => "sort(\{if descending { "desc" } else { "asc" }})"
    ArgSort(_, _) => "arg_sort()"
    Head(n) => "slice(offset=dyn int: 0, length=dyn int: \{n})"
    Tail(n) => "slice(offset=dyn int: \{-n.to_int64()}, length=dyn int: \{n})"
    Slice(offset, length) => {
      let len = match length {
        Some(l) => "dyn int: \{l}"
        None => "null"
      }
      "slice(offset=dyn int: \{offset}, length=\{len})"
    }
    Unique(stable) => if stable { "unique_stable()" } else { "unique()" }
    DropNulls => "drop_nulls()"
  }
}

///|
/// polars refuses a negative length of `slice` (and so of `head` and `tail`)
/// when it runs the expression, with the debug text of the literal.
fn shape_negative_length(length : Int32) -> PolarsError {
  ComputeError(
    "unable to extract length from Scalar(ScalarColumn { name: \"literal\", scalar: Scalar { dtype: Int32, value: Int32(\{length}) }, length: 1, materialized: OnceLock(<uninit>) })",
  )
}

///|
/// The rows of `s` that are not null.
fn Series::without_nulls(self : Series) -> Series {
  match self.col.validity() {
    None => self
    Some(valid) =>
      if valid.count_zeros() == 0 {
        self
      } else {
        Series::make(
          self.name,
          self.col.filter(@arrow.BoolArray::new(valid, None)),
        )
      }
  }
}

///|
fn ShapeOp::apply(self : ShapeOp, s : Series) -> Series raise PolarsError {
  match self {
    Sort(descending, nulls_last) => s.sort(descending~, nulls_last~)
    ArgSort(descending, nulls_last) => s.arg_sort(descending~, nulls_last~)
    Head(n) => {
      if n < 0 {
        raise shape_negative_length(n)
      }
      s.head(n~)
    }
    Tail(n) => {
      if n < 0 {
        raise shape_negative_length(n)
      }
      s.tail(n~)
    }
    Slice(offset, length) => {
      if length is Some(l) && l < 0 {
        raise shape_negative_length(l)
      }
      s.slice(offset, length?)
    }
    Unique(maintain_order) => s.unique(maintain_order~)
    DropNulls => s.without_nulls()
  }
}

// ---------------------------------------------------------------------------
// The shape of a result
// ---------------------------------------------------------------------------

///|
/// Whether the result of `node` can be a column of one row that is *not* a
/// scalar: polars repeats a literal or an aggregate of one row to the height of
/// the other results, but not a column that happens to have one row (`head(1)`,
/// a `filter` that keeps one row ...), where it reports a shape error.
///
/// `sort` and `arg_sort` keep the scalar-ness of their input, an aggregation
/// (`Agg`, `NUnique`, `AnyAll`, and any aggregation another task adds) is a
/// scalar whatever its input is, and every other function of its inputs is a
/// scalar only when all its inputs are.
fn nonscalar_shape(node : ExprNode) -> Bool {
  match node {
    Shape(op, x) =>
      match op {
        Sort(_, _) | ArgSort(_, _) => nonscalar_shape(x)
        _ => true
      }
    Filter(_, _) => true
    SortBy(x, _, _, _) => nonscalar_shape(x)
    Binary(_, l, r) => nonscalar_shape(l) || nonscalar_shape(r)
    Not(x)
    | Neg(x)
    | Alias(x, _)
    | Cast(x, _, _)
    | IsNull(x)
    | IsNotNull(x)
    | Func(_, x)
    | IsIn(x, _)
    | Seq(_, x)
    | Str(_, x)
    | Dt(_, x) => nonscalar_shape(x)
    FillNull(x, v) => nonscalar_shape(x) || nonscalar_shape(v)
    Between(x, lo, hi, _) =>
      nonscalar_shape(x) || nonscalar_shape(lo) || nonscalar_shape(hi)
    Ternary(c, t, o) =>
      nonscalar_shape(c) || nonscalar_shape(t) || nonscalar_shape(o)
    Horizontal(_, xs, _) => xs.iter().any(x => nonscalar_shape(x))
    // a window has a value for every row of the frame: a column
    Over(_, _) => true
    // a column of the frame does not stretch either; literals and
    // aggregations do
    Column(_) => true
    _ => false
  }
}

///|
/// The check polars makes where results of different lengths meet: a result
/// of one row that is not a scalar (`flags[i]`, see `nonscalar_shape`) does not
/// stretch to the others.
///
/// `height` is the height of the frame for `with_columns`; `select` has none
/// and takes the longest result.
///
/// # Errors
/// `ShapeMismatch` (`select`) or `InvalidOperation` (`with_columns`): `Series a,
/// length 1 doesn't match the DataFrame height of 5`.
fn check_unit_results(
  results : Array[Series],
  flags : Array[Bool],
  height : Int32?,
) -> Unit raise PolarsError {
  let target = match height {
    Some(h) => h
    None => {
      let mut longest = 0
      for s in results {
        if s.len() > longest {
          longest = s.len()
        }
      }
      // with an empty result in the mix, the height is 0 and a one-row
      // result that is not a scalar is refused against it
      if longest == 1 && results.iter().any(s => s.len() == 0) {
        0
      } else {
        longest
      }
    }
  }
  if target == 1 {
    return
  }
  for i, s in results {
    if s.len() == 1 && flags[i] {
      let text = "Series \{s.name}, length 1 doesn't match the DataFrame height of \{target}"
      match height {
        Some(_) => raise InvalidOperation(text)
        None => raise ShapeMismatch(text)
      }
    }
  }
}

// ---------------------------------------------------------------------------
// filter
// ---------------------------------------------------------------------------

///|
/// `x.filter(predicate)`: the rows of `x` where the predicate is true.
///
/// A predicate of one row applies to every row (`true` keeps all, `false` or
/// null none); an aggregate or a literal as the subject meets a predicate of
/// any other length by being repeated (also to no row), but `any` and `all`
/// do not.
///
/// # Errors
/// `SchemaMismatch` unless the predicate is `Boolean` (a weak literal names its
/// weak type: `got `i32``), `ShapeMismatch` when the lengths differ and neither
/// is 1.
fn filter_eval(
  df : DataFrame,
  x : ExprNode,
  predicate : ExprNode,
) -> Series raise PolarsError {
  let s = eval_node(df, x)
  let mask = match eval_operand(df, predicate) {
    Weak(Int(v)) =>
      raise SchemaMismatch(
        "invalid series dtype: expected `Boolean`, got `\{weak_int_name(v)}` for series with name `\{output_name(predicate)}`",
      )
    Weak(Float(_)) =>
      raise SchemaMismatch(
        "invalid series dtype: expected `Boolean`, got `f64` for series with name `\{output_name(predicate)}`",
      )
    Strong(m) => m
  }
  if !(mask.dtype() is Boolean) {
    raise SchemaMismatch(
      "invalid series dtype: expected `Boolean`, got `\{mask.dtype()}` for series with name `\{mask.name}`",
    )
  }
  // an aggregate or a literal subject is repeated to the predicate's length
  // (also to none); `any` and `all` are not
  let mut inner = x
  while inner is Alias(y, _) {
    inner = y
  }
  if s.len() == 1 && mask.len() != 1 && !(inner is AnyAll(_, _, _)) {
    return Series::make(s.name, s.col.broadcast(mask.len())).filter(mask)
  }
  s.filter(mask)
}

// ---------------------------------------------------------------------------
// sort_by
// ---------------------------------------------------------------------------

///|
/// Repeats the results of one row to the length of the others, as the inputs
/// of a function over several expressions are: the first result that is not
/// one row long sets the length and every later one must have it.
///
/// # Errors
/// `ShapeMismatch` (`can't compute broadcast length, found incompatible
/// lengths 3 (column 'b') and 2 (column 'a')`: the result that does not fit
/// first, then the one it was compared with).
fn broadcast_inputs(xs : Array[Series]) -> Array[Series] raise PolarsError {
  let mut target = -1
  let mut first = 0
  for i, s in xs {
    if s.len() != 1 {
      if target < 0 {
        target = s.len()
        first = i
      } else if s.len() != target {
        raise ShapeMismatch(
          "can't compute broadcast length, found incompatible lengths \{s.len()} (column '\{s.name}') and \{target} (column '\{xs[first].name}')",
        )
      }
    }
  }
  if target < 0 || target == 1 {
    return xs
  }
  xs.map(s => {
    if s.len() == target {
      s
    } else {
      Series::make(s.name, s.col.broadcast(target))
    }
  })
}

///|
/// `x.sort_by(keys)`: the rows of `x` ordered by the key columns (stable).
/// A literal or an aggregate as a key orders nothing (it is one row, repeated
/// next to longer keys); a column that happens to have one row is not repeated.
/// With no key `x` is returned.
///
/// # Errors
/// `ShapeMismatch` (``sort_by` produced different length (3) than the Series
/// that has to be sorted (5)`) for keys that are not as long as `x`.
fn sort_by_eval(
  df : DataFrame,
  x : ExprNode,
  keys : Array[ExprNode],
  descending : Array[Bool],
  nulls_last : Bool,
) -> Series raise PolarsError {
  let s = eval_node(df, x)
  let n = s.len()
  if keys.length() == 0 {
    return s
  }
  let evaluated = keys.map(k => eval_node(df, k))
  // with several keys, a key that is one row but not a scalar does not stretch
  // to the others
  if evaluated.length() > 1 {
    for i, k in evaluated {
      if k.len() == 1 &&
        nonscalar_shape(keys[i]) &&
        evaluated.iter().any(o => o.len() != 1) {
        raise ShapeMismatch(
          "non-scalar expression produces broadcasting column",
        )
      }
    }
  }
  let ks = broadcast_inputs(evaluated)
  let len = ks[0].len()
  if len != n {
    if len == 1 && !keys.iter().any(k => nonscalar_shape(k)) {
      // every key is a literal or an aggregate: nothing to order by
      return s
    }
    raise ShapeMismatch(
      "`sort_by` produced different length (\{len}) than the Series that has to be sorted (\{n})",
    )
  }
  let flags = if descending.length() == 0 {
    Array::make(keys.length(), false)
  } else {
    descending
  }
  let order = arg_sort_columns(
    ks.map(k => k.col),
    flags,
    Array::make(keys.length(), nulls_last),
  )
  Series::make(s.name, s.col.gather(order))
}

///|
/// The check polars makes when it builds a `sort_by`: `descending` is empty
/// or has one flag per element of `by`.
///
/// # Errors
/// `InvalidOperation` (``the length of `descending` (1) does not match the
/// length of `by` (2)``).
fn sort_by_check(
  descending : Array[Bool],
  by_count : Int32,
) -> Unit raise PolarsError {
  if descending.length() != 0 && descending.length() != by_count {
    raise InvalidOperation(
      "the length of `descending` (\{descending.length()}) does not match the length of `by` (\{by_count})",
    )
  }
}

///|
fn ExprNode::write_sort_by(
  x : ExprNode,
  keys : Array[ExprNode],
  descending : Array[Bool],
  nulls_last : Bool,
  sb : StringBuilder,
) -> Unit {
  x.write_text(sb)
  sb.write_string(".sort_by(by=[")
  for i, key in keys {
    if i > 0 {
      sb.write_string(", ")
    }
    key.write_text(sb)
  }
  let flags = if descending.length() == 0 {
    Array::make(keys.length(), false)
  } else {
    descending
  }
  let fs = flags.map(f => f.to_string()).join(", ")
  let ns = Array::make(keys.length(), nulls_last)
    .map(f => f.to_string())
    .join(", ")
  sb.write_string(
    "], sort_option=SortMultipleOptions { descending: [\{fs}], nulls_last: [\{ns}], multithreaded: true, maintain_order: false, limit: None })",
  )
}

// ---------------------------------------------------------------------------
// any, all
// ---------------------------------------------------------------------------

///|
/// polars' name of the call in its messages: `any_ignore_nulls()`, `all()`.
fn any_all_name(is_any : Bool, ignore_nulls : Bool) -> String {
  (if is_any { "any" } else { "all" }) +
  (if ignore_nulls { "_ignore_nulls()" } else { "()" })
}

///|
/// `any` or `all` of the `valid` / `truth` rows (see `Series::any`).
fn any_all_scan(
  n : Int32,
  valid : (Int32) -> Bool,
  truth : (Int32) -> Bool,
  is_any : Bool,
  ignore_nulls : Bool,
) -> Bool? {
  let mut saw_null = false
  for i in 0..<n {
    if valid(i) {
      if truth(i) == is_any {
        // a true for `any`, a false for `all`: decided
        return Some(is_any)
      }
    } else {
      saw_null = true
    }
  }
  if saw_null && !ignore_nulls {
    None
  } else {
    Some(!is_any)
  }
}

///|
/// `any` / `all` of a column as polars' expressions give it: `Boolean`, and
/// every number counts as `value != 0` (NaN is true); a `Null` column is all
/// null; text and dates are errors.
fn Column::any_all(
  self : Column,
  is_any : Bool,
  ignore_nulls : Bool,
) -> Bool? raise PolarsError {
  let n = self.length()
  match self {
    Boolean(a) =>
      any_all_scan(n, i => a.is_valid(i), i => a.value(i), is_any, ignore_nulls)
    Int32(a) =>
      any_all_scan(
        n,
        i => a.is_valid(i),
        i => a.value(i) != 0,
        is_any,
        ignore_nulls,
      )
    Int64(a) =>
      any_all_scan(
        n,
        i => a.is_valid(i),
        i => a.value(i) != 0L,
        is_any,
        ignore_nulls,
      )
    Float32(a) =>
      any_all_scan(
        n,
        i => a.is_valid(i),
        i => a.value(i) != 0.0,
        is_any,
        ignore_nulls,
      )
    Float64(a) =>
      any_all_scan(
        n,
        i => a.is_valid(i),
        i => a.value(i) != 0.0,
        is_any,
        ignore_nulls,
      )
    Null(_) => any_all_scan(n, _ => false, _ => false, is_any, ignore_nulls)
    String(_) =>
      if n == 0 {
        // nothing to cast: no error
        any_all_scan(0, _ => false, _ => false, is_any, ignore_nulls)
      } else {
        raise InvalidOperation("casting from Utf8View to Boolean not supported")
      }
    Date(_) | Datetime(_) =>
      raise InvalidOperation(
        "expected boolean input for '\{any_all_name(is_any, ignore_nulls)}' (got \{self.dtype()})",
      )
  }
}

///|
/// The one-row `Boolean` series `any` / `all` give.
fn any_all_series(
  s : Series,
  is_any : Bool,
  ignore_nulls : Bool,
) -> Series raise PolarsError {
  let r = s.col.any_all(is_any, ignore_nulls)
  Series::make(s.name, Boolean(@arrow.BoolArray::from_options([r])))
}

// ---------------------------------------------------------------------------
// Expr methods
// ---------------------------------------------------------------------------

///|
/// The values in order, ascending (or `descending`), nulls first (or last with
/// `nulls_last`, whichever the direction), NaN after every number; the sort is
/// stable and the name is kept (`Series::sort`). Sorting a literal or an
/// aggregate gives the one value, which still broadcasts. polars prints
/// `col("a").sort(asc)`.
pub fn Expr::sort(
  self : Expr,
  descending~ : Bool = false,
  nulls_last~ : Bool = false,
) -> Expr {
  Expr::of(Shape(Sort(descending, nulls_last), self.node))
}

///|
/// The row numbers that sort the column, as an `Int64` column with the name of
/// `self` (`Series::arg_sort`; polars gives `UInt32`, which this library does
/// not have).
pub fn Expr::arg_sort(
  self : Expr,
  descending~ : Bool = false,
  nulls_last~ : Bool = false,
) -> Expr {
  Expr::of(Shape(ArgSort(descending, nulls_last), self.node))
}

///|
/// The rows of `self` ordered by the key expressions `by`, first key first,
/// stable (rows equal on every key keep their order, also when descending).
///
/// - `descending` is empty (all ascending) or has one flag per element of
///   `by`; `nulls_last` applies to every key.
/// - A key must be as long as `self`; a literal or an aggregate (one row,
///   repeated) orders nothing, but a column that happens to have one row
///   (`k.head(1)`) is a `ShapeMismatch`. With no key `self` is returned.
/// - A selector in `by` (`cols`, `all()`) stands for several keys.
///
/// # Errors
/// Evaluating raises `InvalidOperation` for a `descending` of another length
/// than `by` (``the length of `descending` (1) does not match the length of
/// `by` (2)``) and `ShapeMismatch` for a key of another length.
pub fn Expr::sort_by(
  self : Expr,
  by : Array[Expr],
  descending~ : Array[Bool] = [],
  nulls_last~ : Bool = false,
) -> Expr {
  Expr::of(SortBy(self.node, by.map(e => e.node), descending, nulls_last))
}

///|
/// The first `n` rows (default 10); `n` beyond the length is clamped. polars
/// prints it as a slice: `col("a").slice(offset=dyn int: 0, length=dyn int:
/// 2)`.
///
/// The result has as many rows as it has, so it does not meet longer results
/// in a `select` (`ShapeMismatch`), also when it has exactly one row: only an
/// aggregate or a literal is repeated.
///
/// # Errors
/// Evaluating raises `ComputeError` for a negative `n` (polars' expression
/// `head` refuses it with an internal message; `Series::head` takes it as
/// "all but the last").
pub fn Expr::head(self : Expr, n~ : Int32 = 10) -> Expr {
  Expr::of(Shape(Head(n), self.node))
}

///|
/// The last `n` rows (default 10); see `Expr::head`.
pub fn Expr::tail(self : Expr, n~ : Int32 = 10) -> Expr {
  Expr::of(Shape(Tail(n), self.node))
}

///|
/// The rows `[offset, offset + length)`; a negative `offset` counts from the
/// end, `length` defaults to "until the end". The window is computed first and
/// clamped afterwards, so it never fails for the offset; see `Expr::head` for
/// the shape of the result.
///
/// # Errors
/// Evaluating raises `ComputeError` for a negative `length`.
pub fn Expr::slice(self : Expr, offset : Int32, length? : Int32) -> Expr {
  Expr::of(Shape(Slice(offset, length), self.node))
}

///|
/// The distinct values (null counts as a value, NaN is one value and `-0.0`
/// equals `0.0`). This library always returns them in order of first
/// appearance; only with `maintain_order=true` is that guaranteed (polars
/// prints `unique_stable()` for it). See `Expr::head` for the shape of the
/// result.
pub fn Expr::unique(self : Expr, maintain_order~ : Bool = false) -> Expr {
  Expr::of(Shape(Unique(maintain_order), self.node))
}

///|
/// The rows that are not null (NaN is not null). See `Expr::head` for the
/// shape of the result.
pub fn Expr::drop_nulls(self : Expr) -> Expr {
  Expr::of(Shape(DropNulls, self.node))
}

///|
/// The rows of `self` where `predicate` is true (a null row is dropped); the
/// name is `self`'s. A predicate of one row applies to every row, and a value
/// of one row (an aggregate) meets a longer predicate by being repeated, so
/// `col("a").filter(col("a").gt(lit_int(1))).sum()` is the sum of the values
/// above 1 and gives one row.
///
/// # Errors
/// Evaluating raises `SchemaMismatch` for a predicate that is not `Boolean`
/// (``invalid series dtype: expected `Boolean`, got `i64` for series with name
/// `a` ``) and `ShapeMismatch` (`filter's length: 2 differs from that of the
/// series: 5`) when the lengths differ and neither is 1.
pub fn Expr::filter(self : Expr, predicate : Expr) -> Expr {
  Expr::of(Filter(self.node, predicate.node))
}

///|
/// Whether any value is true, a one-row `Boolean` column. With
/// `ignore_nulls` (the default) nulls are skipped, so the result is never
/// null and an empty or all-null column gives `false`; without it the result
/// is null when no value is true and one is null (Kleene logic). A number
/// counts as `value != 0` (NaN is true), as in polars' expressions.
///
/// # Errors
/// Evaluating raises `InvalidOperation` for `String` (`casting from Utf8View
/// to Boolean not supported`), `Date` and `Datetime` (`expected boolean input
/// for 'any_ignore_nulls()' (got date)`).
pub fn Expr::any(self : Expr, ignore_nulls~ : Bool = true) -> Expr {
  Expr::of(AnyAll(true, ignore_nulls, self.node))
}

///|
/// Whether every value is true, a one-row `Boolean` column; an empty column
/// gives `true`. See `Expr::any` for the null handling.
pub fn Expr::all(self : Expr, ignore_nulls~ : Bool = true) -> Expr {
  Expr::of(AnyAll(false, ignore_nulls, self.node))
}
