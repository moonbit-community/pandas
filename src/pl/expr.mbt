///|
/// A lazy expression: a description of a computation on a frame's columns
/// that `DataFrame::select` and `DataFrame::with_columns` evaluate.
///
/// Build one with `col`, `cols`, `all`, `lit`, `lit_int`, `lit_float`,
/// `lit_str` or `lit_bool`, and combine them with the arithmetic operators
/// (`+ - * / %`, unary `-`), the logic operators (`&`, `|`) and the methods
/// (`eq`, `neq`, `gt`, `ge`, `lt`, `le`, `floor_div`, `not_`, `alias`, `cast`,
/// `is_null`, `is_not_null`), the aggregations (`sum`, `mean`, `min`, `max`,
/// `count`, `len`, `n_unique`, `first`, `last`, `median`, `product`, `std`,
/// `var_`, `quantile`), the element-wise functions (`is_nan`, `is_not_nan`,
/// `is_finite`, `is_infinite`, `abs`, `sqrt`, `exp`, `log`, `round`,
/// `fill_null`, `is_in`, `between`), the sequence operations (`shift`, `diff`,
/// `cum_sum`, `cum_min`, `cum_max`, `cum_prod`, `cum_count`, `rank`,
/// `reverse`, `fill_null_strategy`), `sort`, `arg_sort`, `sort_by`, `head`,
/// `tail`, `slice`, `unique`, `drop_nulls`, `filter`, `any`, `all`, the
/// trigonometric functions (`sin`, `cos`, `tan`, `arcsin`, `arccos`,
/// `arctan`), `sum_horizontal` / `min_horizontal` / `max_horizontal`, the
/// `str()` and `dt()` functions and `when(...).then(...).otherwise(...)`.
/// An expression is a value: building one does no work and an expression can
/// be used many times.
///
/// `to_string()` gives the text polars prints for the same expression, for
/// example `[(col("a")) + (dyn int: 1)]`.
struct Expr {
  node : ExprNode
}

///|
/// How a literal takes its type (spec 5.5).
///
/// - `Strong`: the type of the value (`lit`, `lit_str`, `lit_bool`).
/// - `WeakInt`: `lit_int`; next to a number or a Boolean it becomes the
///   other side's type when the value fits it, and `Int32` / `Int64`
///   otherwise.
/// - `WeakFloat`: `lit_float`; next to `Float32` it is a `Float32`, otherwise
///   a `Float64`.
priv enum LitKind {
  Strong
  WeakInt
  WeakFloat
}

///|
priv enum BinaryOp {
  Add
  Sub
  Mul
  Div
  FloorDiv
  Rem
  Eq
  Neq
  Gt
  Ge
  Lt
  Le
  And
  Or
}

///|
/// The expression tree. Later tasks add variants here; each addition needs an
/// arm in `ExprNode::text` (the `Show` text), `expand_node` (selectors) and
/// `eval_node` (evaluation), and in `output_name` (the default column name).
priv enum ExprNode {
  /// `col(name)`
  Column(String)
  /// `cols(names)`; `expand_selectors` turns it into one `Column` per name
  Columns(Array[String])
  /// `all()`; `expand_selectors` turns it into one `Column` per column of the frame
  All
  /// A literal; `Literal(Int64(v), WeakInt)` and `Literal(Float64(v),
  /// WeakFloat)` are the weak ones
  Literal(AnyValue, LitKind)
  Binary(BinaryOp, ExprNode, ExprNode)
  Not(ExprNode)
  Neg(ExprNode)
  Alias(ExprNode, String)
  /// `Cast(expr, dtype, strict)`
  Cast(ExprNode, DataType, Bool)
  IsNull(ExprNode)
  IsNotNull(ExprNode)
  /// An aggregation to one value (`expr_agg.mbt`): `sum`, `mean`, ...
  Agg(AggOp, ExprNode)
  /// `n_unique` (an `Int64`; `AggOp` has no such operation)
  NUnique(ExprNode)
  /// An element-wise function (`expr_agg.mbt`): `is_nan`, `abs`, `log`, ...
  Func(ElemFunc, ExprNode)
  /// `FillNull(expr, value)`
  FillNull(ExprNode, ExprNode)
  /// `IsIn(expr, values)`
  IsIn(ExprNode, Series)
  /// `Between(expr, lower, upper, closed)`; evaluated as two comparisons
  Between(ExprNode, ExprNode, ExprNode, ClosedInterval)
  /// `Ternary(condition, then, otherwise)` (`when.mbt`); a chain of
  /// `when/then` is nested in `otherwise`
  Ternary(ExprNode, ExprNode, ExprNode)
  /// A sequence operation (`expr_seq.mbt`): `shift`, `cum_sum`, `rank`, ...
  Seq(SeqOp, ExprNode)
  /// A string function (`expr_str.mbt`): `str().contains(...)`, ...
  Str(StrOp, ExprNode)
  /// A date or time field (`expr_dt.mbt`): `dt().year()`, ...
  Dt(DtField, ExprNode)
  /// `len()`: the number of rows of the frame (of the group in `agg`)
  Len
  /// A sort, a cut or a de-duplication (`expr_shape.mbt`): `sort`, `head`, `unique`, ...
  Shape(ShapeOp, ExprNode)
  /// `Filter(expr, predicate)`
  Filter(ExprNode, ExprNode)
  /// `SortBy(expr, keys, descending, nulls_last)`
  SortBy(ExprNode, Array[ExprNode], Array[Bool], Bool)
  /// `AnyAll(is_any, ignore_nulls, expr)`: a reduction to one `Boolean`
  AnyAll(Bool, Bool, ExprNode)
  /// `Horizontal(op, inputs, ignore_nulls)` (`horizontal.mbt`)
  Horizontal(HorizOp, Array[ExprNode], Bool)
  /// `Over(expr, partition_by)` (`window.mbt`): `expr` evaluated per partition
  Over(ExprNode, Array[ExprNode])
}

///|
fn Expr::of(node : ExprNode) -> Expr {
  { node, }
}

// ---------------------------------------------------------------------------
// Constructors
// ---------------------------------------------------------------------------

///|
/// The column called `name`. The output column is named `name` too.
///
/// A missing column is reported when the expression is evaluated, as
/// `ColumnNotFound`.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::int32("a", [1, 2])])
///   let out = df.select([@pl.col("a")])
///   assert_eq(out.columns(), ["a"])
/// }
/// ```
pub fn col(name : String) -> Expr {
  Expr::of(ExprNode::Column(name))
}

///|
/// Several columns at once: the expression is evaluated once per name, so
/// `cols(["a", "b"]) + lit_int(1)` is `col("a") + lit_int(1)` followed by
/// `col("b") + lit_int(1)`. A name that appears twice counts once; with no
/// names the expression gives no columns.
///
/// When two selectors meet in an operator they pair up column by column and
/// must be equally wide (a single column pairs with every column of the other
/// side). The output names are the left side's.
///
/// # Errors
/// Evaluation raises `ColumnNotFound` (`"zz" not found`) for a name the frame
/// does not have and `InvalidOperation` when two selectors differ in width.
pub fn cols(names : Array[String]) -> Expr {
  Expr::of(ExprNode::Columns(names))
}

///|
/// Every column of the frame, in order; a frame without columns gives none.
/// Like `cols`, it is expanded to one expression per column, so
/// `all().alias("x")` names every column `x` and fails with `DuplicateColumn`.
pub fn all() -> Expr {
  Expr::of(ExprNode::All)
}

///|
/// The number of rows, an `Int64` named `len` (polars' `pl.len()`). In
/// `select` and `with_columns` it is the height of the frame (0 for a frame
/// without columns), repeated next to longer columns like any one-row
/// result; in `group_by(...).agg(...)` it is the number of rows of each
/// group, null keys included (`col("a").count()` skips nulls, `len()` does
/// not).
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::int32("a", [1, 2, 3])])
///   let out = df.select([@pl.len()])
///   assert_eq(out.column("len").to_int64_array(), [Some(3L)])
/// }
/// ```
pub fn len() -> Expr {
  Expr::of(ExprNode::Len)
}

///|
/// A literal of exactly the type of `value` (no weak-literal adaption): a
/// column is promoted to the supertype when it meets it (`Int32` column +
/// `lit(Int64(1))` is `Int64`). `AnyValue::Null` gives a `Null` literal. The
/// output column is named `literal`.
pub fn lit(value : AnyValue) -> Expr {
  Expr::of(ExprNode::Literal(value, LitKind::Strong))
}

///|
/// A weak integer literal, like a Python `int` in polars: next to an `Int32`
/// column it is an `Int32` when the value fits (`Int32 + lit_int(1)` is
/// `Int32`) and an `Int64` otherwise (so the column is promoted and nothing
/// wraps around); next to `Int64` it is `Int64`; next to a float column it is
/// that float. On its own, or next to another weak literal, it is `Int64`.
/// The output column is named `literal`.
pub fn lit_int(value : Int64) -> Expr {
  Expr::of(ExprNode::Literal(AnyValue::Int64(value), LitKind::WeakInt))
}

///|
/// A weak float literal: next to a `Float32` column it is a `Float32` (so
/// `Float32 * lit_float(1.0e300)` is infinity, still `Float32`); next to
/// anything else it is a `Float64`. The output column is named `literal`.
pub fn lit_float(value : Double) -> Expr {
  Expr::of(ExprNode::Literal(AnyValue::Float64(value), LitKind::WeakFloat))
}

///|
/// A `String` literal, named `literal`.
pub fn lit_str(value : String) -> Expr {
  Expr::of(ExprNode::Literal(AnyValue::String(value), LitKind::Strong))
}

///|
/// A `Boolean` literal, named `literal`.
pub fn lit_bool(value : Bool) -> Expr {
  Expr::of(ExprNode::Literal(AnyValue::Boolean(value), LitKind::Strong))
}

// ---------------------------------------------------------------------------
// Operators and methods
// ---------------------------------------------------------------------------

///|
fn Expr::binary(op : BinaryOp, a : Expr, b : Expr) -> Expr {
  Expr::of(ExprNode::Binary(op, a.node, b.node))
}

///|
/// `self + other`. Types follow `Series::add` (the supertype; a weak literal
/// adapts to the other side); a null on either side gives null. Evaluating it
/// raises `InvalidOperation` for a `Boolean`, `String`, `Date` or `Datetime`
/// operand. The output name is the left side's.
pub impl Add for Expr with fn add(self, other) {
  Expr::binary(BinaryOp::Add, self, other)
}

///|
/// `self - other`; see `Expr + Expr`.
pub impl Sub for Expr with fn sub(self, other) {
  Expr::binary(BinaryOp::Sub, self, other)
}

///|
/// `self * other`; see `Expr + Expr`.
pub impl Mul for Expr with fn mul(self, other) {
  Expr::binary(BinaryOp::Mul, self, other)
}

///|
/// `self / other`: true division, `Float64` (`Float32` for two `Float32`s);
/// division by zero follows IEEE 754. See `Expr + Expr`.
pub impl Div for Expr with fn div(self, other) {
  Expr::binary(BinaryOp::Div, self, other)
}

///|
/// `self % other`: the remainder takes the sign of the divisor; an integer
/// remainder by zero is null. See `Expr + Expr`.
pub impl Mod for Expr with fn mod(self, other) {
  Expr::binary(BinaryOp::Rem, self, other)
}

///|
/// Floor division, `self // other` in polars: rounds towards negative
/// infinity; an integer division by zero is null. See `Expr + Expr`.
pub fn Expr::floor_div(self : Expr, other : Expr) -> Expr {
  Expr::binary(BinaryOp::FloorDiv, self, other)
}

///|
/// `-self`: negation of an integer or float expression (`Int32::MIN` and
/// `Int64::MIN` wrap around). Evaluating it raises `InvalidOperation` for
/// any other type. The output name is `self`'s.
pub impl Neg for Expr with fn neg(self) {
  Expr::of(ExprNode::Neg(self.node))
}

///|
/// `self & other` with Kleene logic (`false & null` is `false`). Both sides
/// must be `Boolean` (a `Null` counts as an all-null `Boolean`), otherwise
/// evaluation raises polars' expression errors: `ComputeError` for a
/// `Boolean` with a number, `InvalidOperation` for a `String`, a `Date` or
/// `Datetime`, two numbers (no bitwise `&`) or two `Null`s. The output name is the left side's.
pub impl BitAnd for Expr with fn land(self, other) {
  Expr::binary(BinaryOp::And, self, other)
}

///|
/// `self | other` with Kleene logic (`true | null` is `true`); see
/// `Expr & Expr`.
pub impl BitOr for Expr with fn lor(self, other) {
  Expr::binary(BinaryOp::Or, self, other)
}

///|
/// `self == other`. The result is `Boolean`, null where either side is null.
/// Floats compare as in polars (NaN equals NaN); strings compare by code
/// point. A weak literal that does not fit the column's type compares as an
/// `Int64` (`Int32` column `.eq(lit_int(1 << 40))` is all false, no error).
/// Evaluation raises `ComputeError` for a `String` against a number and
/// `SchemaMismatch` for other incompatible types.
pub fn Expr::eq(self : Expr, other : Expr) -> Expr {
  Expr::binary(BinaryOp::Eq, self, other)
}

///|
/// `self != other`; see `Expr::eq`.
pub fn Expr::neq(self : Expr, other : Expr) -> Expr {
  Expr::binary(BinaryOp::Neq, self, other)
}

///|
/// `self > other`; see `Expr::eq`.
pub fn Expr::gt(self : Expr, other : Expr) -> Expr {
  Expr::binary(BinaryOp::Gt, self, other)
}

///|
/// `self >= other`; see `Expr::eq`.
pub fn Expr::ge(self : Expr, other : Expr) -> Expr {
  Expr::binary(BinaryOp::Ge, self, other)
}

///|
/// `self < other`; see `Expr::eq`.
pub fn Expr::lt(self : Expr, other : Expr) -> Expr {
  Expr::binary(BinaryOp::Lt, self, other)
}

///|
/// `self <= other`; see `Expr::eq`.
pub fn Expr::le(self : Expr, other : Expr) -> Expr {
  Expr::binary(BinaryOp::Le, self, other)
}

///|
/// Logical negation (`~self` in polars); null stays null. Evaluation raises
/// `InvalidOperation` unless the expression is `Boolean`.
pub fn Expr::not_(self : Expr) -> Expr {
  Expr::of(ExprNode::Not(self.node))
}

///|
/// Renames the output column to `name` (any text, the empty one included).
/// Nothing else changes; `alias` of a weak literal is still weak. (`alias` is
/// a reserved word in MoonBit: `src/pl/moon.pkg` turns that warning off.)
pub fn Expr::alias(self : Expr, name : String) -> Expr {
  Expr::of(ExprNode::Alias(self.node, name))
}

///|
/// Converts to `dtype` like `Series::cast`. With `strict` (the default) a
/// value that does not convert raises `InvalidOperation`; with `strict=false`
/// it becomes null. A cast makes a weak literal strong. The name is kept.
pub fn Expr::cast(self : Expr, dtype : DataType, strict~ : Bool = true) -> Expr {
  Expr::of(ExprNode::Cast(self.node, dtype, strict))
}

///|
/// A `Boolean` expression: true where `self` is null (NaN is not null). Never
/// null itself; a `Null` expression is true everywhere. The name is `self`'s.
pub fn Expr::is_null(self : Expr) -> Expr {
  Expr::of(ExprNode::IsNull(self.node))
}

///|
/// A `Boolean` expression: true where `self` is not null. Never null itself.
pub fn Expr::is_not_null(self : Expr) -> Expr {
  Expr::of(ExprNode::IsNotNull(self.node))
}

// ---------------------------------------------------------------------------
// Show: polars' `str(expr)`
// ---------------------------------------------------------------------------

///|
/// Rust's `Display` text of a double, as polars prints a weak float literal:
/// positional, never scientific (`1` for `1.0`, `-0`, `NaN`, `inf`).
fn rust_display_float(x : Double) -> String {
  if x.is_nan() {
    return "NaN"
  }
  if x.is_pos_inf() {
    return "inf"
  }
  if x.is_neg_inf() {
    return "-inf"
  }
  if x == 0.0 {
    return if x.reinterpret_as_int64() < 0L { "-0" } else { "0" }
  }
  let neg = x < 0.0
  let (digits, e) = float_digits((if neg { -x } else { x }).to_string())
  display_text(neg, digits, e)
}

///|
fn BinaryOp::symbol(self : BinaryOp) -> String {
  match self {
    Add => "+"
    Sub => "-"
    Mul => "*"
    Div => "/"
    FloorDiv => "//"
    Rem => "%"
    Eq => "=="
    Neq => "!="
    Gt => ">"
    Ge => ">="
    Lt => "<"
    Le => "<="
    And => "&"
    Or => "|"
  }
}

///|
/// The text of a literal: `dyn int: 1` and `dyn float: 1.5` for the weak
/// ones, otherwise the value as polars prints it (strings in double quotes,
/// unescaped; floats like a table cell).
fn literal_text(value : AnyValue, kind : LitKind) -> String {
  match (kind, value) {
    (WeakInt, Int64(v)) => "dyn int: \{v}"
    (WeakFloat, Float64(v)) => "dyn float: \{rust_display_float(v)}"
    (_, String(s)) => "\"" + s + "\""
    _ => cell_text(value)
  }
}

///|
/// polars' `str(expr)` of the tree. `[(left) op (right)]` for a binary
/// operation; `x.method()` for the others. The text is written into one
/// builder, so the cost is linear in its length also for a deep chain (a
/// recursion that concatenated the children's texts was quadratic).
fn ExprNode::text(self : ExprNode) -> String {
  let sb = StringBuilder()
  self.write_text(sb)
  sb.to_string()
}

///|
/// `x` followed by `suffix`, written into `sb`.
fn ExprNode::write_then(
  self : ExprNode,
  sb : StringBuilder,
  suffix : String,
) -> Unit {
  self.write_text(sb)
  sb.write_string(suffix)
}

///|
fn ExprNode::write_text(self : ExprNode, sb : StringBuilder) -> Unit {
  match self {
    Column(name) => sb.write_string("col(\"\{name}\")")
    Columns(names) => {
      let quoted = names.map(n => "'\{n}'")
      let sep = if names.length() > 0 { ", " } else { "" }
      sb.write_string(
        "cs.by_name(" + quoted.join(", ") + sep + "require_all=true)",
      )
    }
    All => sb.write_string("cs.all()")
    Literal(value, kind) => sb.write_string(literal_text(value, kind))
    Binary(op, l, r) => {
      sb.write_string("[(")
      l.write_text(sb)
      sb.write_string(") \{op.symbol()} (")
      r.write_text(sb)
      sb.write_string(")]")
    }
    Not(x) => x.write_then(sb, ".not()")
    Neg(x) => x.write_then(sb, ".negate()")
    Alias(x, name) => x.write_then(sb, ".alias(\"\{name}\")")
    Cast(x, dtype, strict) => {
      let call = if strict { "strict_cast" } else { "cast" }
      x.write_then(sb, ".\{call}(\{polars_type_name(dtype)})")
    }
    IsNull(x) => x.write_then(sb, ".is_null()")
    IsNotNull(x) => x.write_then(sb, ".is_not_null()")
    Agg(op, x) => x.write_then(sb, ".\{op.text()}")
    NUnique(x) => x.write_then(sb, ".n_unique()")
    Func(f, x) => x.write_then(sb, ".\{f.text()}")
    FillNull(x, v) => {
      x.write_then(sb, ".fill_null([")
      v.write_then(sb, "])")
    }
    IsIn(x, values) => x.write_then(sb, ".is_in([\{series_text(values)}])")
    Between(x, lo, hi, _) => {
      x.write_then(sb, ".is_between([")
      lo.write_then(sb, ", ")
      hi.write_then(sb, "])")
    }
    Ternary(c, t, o) => {
      sb.write_string(".when(")
      c.write_then(sb, ").then(")
      t.write_then(sb, ").otherwise(")
      o.write_then(sb, ")")
    }
    Seq(op, x) => x.write_then(sb, ".\{op.text()}")
    Str(op, x) => x.write_then(sb, ".\{op.text()}")
    Dt(f, x) => x.write_then(sb, ".\{f.text()}")
    Len => sb.write_string("len()")
    Shape(op, x) => x.write_then(sb, ".\{op.text()}")
    Filter(x, p) => {
      x.write_then(sb, ".filter(")
      p.write_then(sb, ")")
    }
    SortBy(x, keys, descending, nulls_last) =>
      x.write_sort_by(keys, descending, nulls_last, sb)
    AnyAll(is_any, ignore_nulls, x) =>
      x.write_then(sb, ".\{any_all_name(is_any, ignore_nulls)}")
    Horizontal(op, xs, _) => ExprNode::write_horizontal(op, xs, sb)
    Over(x, keys) => {
      x.write_then(sb, ".over([")
      for i, k in keys {
        if i > 0 {
          sb.write_string(", ")
        }
        k.write_text(sb)
      }
      sb.write_string("])")
    }
  }
}

///|
/// Shows the expression as polars' `str(expr)`: `col("a")`,
/// `[(col("a")) + (dyn int: 1)]`, `col("a").alias("z")`,
/// `col("a").strict_cast(Float64)`.
pub impl Show for Expr with fn output(self, logger) {
  logger.write_string(self.node.text())
}

///|
/// Makes `to_string` callable as a method (`e.to_string()`), giving the same
/// text as `Show`.
pub extend Expr with Show::{to_string}
