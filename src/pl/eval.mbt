// Expansion and evaluation of expressions.
//
// `expand_selectors` turns the selectors (`cols`, `all`) into plain column
// expressions, `eval_node` computes one expanded expression on a frame and
// `eval_exprs` does both for a list, checks the names and broadcasts length-1
// results.
// Nothing is cached: an expression is evaluated every time it is used.

// ---------------------------------------------------------------------------
// Output names
// ---------------------------------------------------------------------------

///|
/// The name of the column an (expanded) expression produces: the leftmost
/// column it reads, `literal` for a literal, the alias when there is one.
/// `|` with a temporal operand or a Boolean next to a number, and `~` on a
/// type polars has no bitwise not for (`~` on `Int32` and `Int64` is valid in
/// polars; this library rejects it only when the kernel runs, see
/// `Series::not_`, so it is not a plan time error here).lit(1) + col("a")` is called `literal`.
fn output_name(node : ExprNode) -> String {
  match node {
    Column(name) => name
    Columns(_) | All =>
      abort("output_name: a selector must be expanded before it has a name")
    Literal(_, _) => "literal"
    Binary(_, left, _) => output_name(left)
    Not(x) | Neg(x) | IsNull(x) | IsNotNull(x) | Cast(x, _, _) => output_name(x)
    Alias(_, name) => name
    // an aggregation or a function is named after its input, a fill, a range
    // test after the value, a `when` after its first `then`
    Agg(_, x) | NUnique(x) | Func(_, x) | IsIn(x, _) => output_name(x)
    FillNull(x, _) | Between(x, _, _, _) => output_name(x)
    Ternary(_, then, _) => output_name(then)
    // a sequence operation, a string function or a date field is named after
    // its input
    Seq(_, x) | Str(_, x) | Dt(_, x) => output_name(x)
  }
}

// ---------------------------------------------------------------------------
// Expansion
// ---------------------------------------------------------------------------

///|
/// Escapes `s` like Rust's `Debug` for a string (the part of it polars shows
/// in "valid columns: [...]").
fn debug_quote(s : String) -> String {
  let sb = StringBuilder()
  sb.write_char('"')
  for c in s {
    match c {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(c)
    }
  }
  sb.write_char('"')
  sb.to_string()
}

///|
/// polars' error for `col(name)` on a frame without that column.
fn column_not_found(df : DataFrame, name : String) -> PolarsError {
  let valid = df.columns().map(debug_quote).join(", ")
  ColumnNotFound(
    "unable to find column \{debug_quote(name)}; valid columns: [\{valid}]",
  )
}

///|
/// The column `name` of `df`, as `ColumnNotFound` with polars' text when it
/// does not exist.
fn frame_column(df : DataFrame, name : String) -> Series raise PolarsError {
  match df.get_column_index(name) {
    Some(_) => df.column(name)
    None => raise column_not_found(df, name)
  }
}

///|
/// Expands the children of a unary expression: one result per column of
/// `x`, each wrapped by `wrap`.
fn expand_unary(
  df : DataFrame,
  x : ExprNode,
  wrap : (ExprNode) -> ExprNode,
) -> Array[ExprNode] raise PolarsError {
  expand_node(df, x).map(wrap)
}

///|
/// The number of expressions an operation over children that expand to the
/// given widths gives. A child of width 1 pairs with every column of the
/// others; the other widths must be equal, else polars' `InvalidOperation`
/// (`(k != n)`: the first width that is not 1 differing from the one before).
fn common_width(widths : Array[Int32]) -> Int32 raise PolarsError {
  let mut n = -1
  for k in widths {
    if k != 1 {
      if n < 0 {
        n = k
      } else if k != n {
        raise InvalidOperation(
          "cannot combine selectors that produce a different number of columns (\{k} != \{n})",
        )
      }
    }
  }
  if n < 0 {
    1
  } else {
    n
  }
}

///|
/// Expands the children of an operation with any number of operands (two for
/// a binary one, three for `when/then/otherwise`): the children pair up
/// column by column and `join` builds the expression of each group. A child
/// that expands to a single column pairs with every column of the others;
/// other widths cannot be combined. When a child gives no column at all the
/// result is empty (`all() + col("missing")` on a frame without columns
/// is no error: the plain column is never looked up).
///
/// Only selectors are resolved here; plain columns are looked up afterwards
/// by `check_columns` (see `eval_unbroadcast`).
///
/// `early` is the number of leading children whose widths are compared before
/// the next child is expanded (0 for none): polars checks the condition and
/// the `then` of a `when` before it looks into the `otherwise`, where the
/// rest of a chain is nested, so the width error of the outer pair wins over
/// those of the inner ones.
fn expand_n(
  df : DataFrame,
  children : Array[ExprNode],
  join : (Array[ExprNode]) -> ExprNode,
  early~ : Int32 = 0,
) -> Array[ExprNode] raise PolarsError {
  let k = children.length()
  let expanded : Array[Array[ExprNode]] = Array(capacity=k)
  for i, child in children {
    expanded.push(expand_node(df, child))
    if early > 0 && i == early - 1 {
      ignore(common_width(expanded.map(x => x.length())))
    }
  }
  let n = common_width(expanded.map(x => x.length()))
  let out : Array[ExprNode] = Array(capacity=n)
  for j in 0..<n {
    let group : Array[ExprNode] = Array(capacity=k)
    for xs in expanded {
      group.push(if xs.length() == 1 { xs[0] } else { xs[j] })
    }
    out.push(join(group))
  }
  out
}

///|
/// Expands the two children of a binary expression; see `expand_n`.
fn expand_zip(
  df : DataFrame,
  left : ExprNode,
  right : ExprNode,
  join : (ExprNode, ExprNode) -> ExprNode,
) -> Array[ExprNode] raise PolarsError {
  expand_n(df, [left, right], g => join(g[0], g[1]))
}

///|
fn expand_node(
  df : DataFrame,
  node : ExprNode,
) -> Array[ExprNode] raise PolarsError {
  match node {
    // plain columns are looked up later, by `check_columns`
    Column(_) => [node]
    Columns(names) => {
      let seen : Map[String, Bool] = Map([])
      let out : Array[ExprNode] = []
      for name in names {
        if df.get_column_index(name) is None {
          raise ColumnNotFound("\{debug_quote(name)} not found")
        }
        if !seen.contains(name) {
          seen[name] = true
          out.push(ExprNode::Column(name))
        }
      }
      out
    }
    All => df.columns().map(name => ExprNode::Column(name))
    Literal(_, _) => [node]
    Binary(op, l, r) => expand_zip(df, l, r, (a, b) => Binary(op, a, b))
    Not(x) => expand_unary(df, x, y => Not(y))
    Neg(x) => expand_unary(df, x, y => Neg(y))
    Alias(x, name) => expand_unary(df, x, y => Alias(y, name))
    Cast(x, dtype, strict) => expand_unary(df, x, y => Cast(y, dtype, strict))
    IsNull(x) => expand_unary(df, x, y => IsNull(y))
    IsNotNull(x) => expand_unary(df, x, y => IsNotNull(y))
    Agg(op, x) => expand_unary(df, x, y => Agg(op, y))
    NUnique(x) => expand_unary(df, x, y => NUnique(y))
    Func(f, x) => expand_unary(df, x, y => Func(f, y))
    IsIn(x, values) => expand_unary(df, x, y => IsIn(y, values))
    FillNull(x, v) => expand_n(df, [x, v], g => FillNull(g[0], g[1]))
    Between(x, lo, hi, closed) =>
      expand_n(df, [x, lo, hi], g => Between(g[0], g[1], g[2], closed))
    Ternary(c, t, o) =>
      expand_n(df, [c, t, o], g => Ternary(g[0], g[1], g[2]), early=2)
    Seq(op, x) => {
      // polars refuses a bad `limit` when it builds the expression, before
      // anything is looked at (also when a selector gives no column)
      if op is Fill(strategy, limit) {
        xseq_check_limit(strategy, limit)
      }
      expand_unary(df, x, y => Seq(op, y))
    }
    Str(op, x) => expand_unary(df, x, y => Str(op, y))
    Dt(f, x) => expand_unary(df, x, y => Dt(f, y))
  }
}

///|
/// Replaces the selectors of `e` by plain columns: one expression per column
/// the selectors stand for, so `cols(["a", "b"]) + lit_int(1)` gives
/// `col("a") + 1` and `col("b") + 1`, in order. Any other expression gives
/// itself. The tree is only read; no frame data is touched. This is the
/// first of polars' two expansion passes: the plain columns are not looked
/// up yet (`check_columns` does that).
///
/// # Errors
/// `ColumnNotFound` (`"x" not found`) for a name of `cols` that does not exist
/// and `InvalidOperation` when two selectors in one operation differ in
/// width.
fn expand_selectors(
  df : DataFrame,
  e : Expr,
) -> Array[ExprNode] raise PolarsError {
  expand_node(df, e.node)
}

///|
/// Looks up every plain column of an expanded expression, left to right.
///
/// # Errors
/// `ColumnNotFound` with polars' text (`unable to find column "x"; valid
/// columns: [...]`).
fn check_columns(df : DataFrame, node : ExprNode) -> Unit raise PolarsError {
  match node {
    Column(name) =>
      if df.get_column_index(name) is None {
        raise column_not_found(df, name)
      }
    Columns(_) | All | Literal(_, _) => ()
    Binary(_, l, r) => {
      check_columns(df, l)
      check_columns(df, r)
    }
    Not(x) | Neg(x) | Alias(x, _) | Cast(x, _, _) | IsNull(x) | IsNotNull(x) =>
      check_columns(df, x)
    Agg(_, x) | NUnique(x) | Func(_, x) | IsIn(x, _) => check_columns(df, x)
    FillNull(x, v) => {
      check_columns(df, x)
      check_columns(df, v)
    }
    Between(x, lo, hi, _) => {
      check_columns(df, x)
      check_columns(df, lo)
      check_columns(df, hi)
    }
    Ternary(c, t, o) => {
      check_columns(df, c)
      check_columns(df, t)
      check_columns(df, o)
    }
    Seq(_, x) | Str(_, x) | Dt(_, x) => check_columns(df, x)
  }
}

// ---------------------------------------------------------------------------
// Weak literals
// ---------------------------------------------------------------------------

///|
/// The value of a weak literal that has not found its type yet.
priv enum WeakVal {
  Int(Int64)
  Float(Double)
}

///|
/// What evaluating an expression gives: a weak literal (its type is decided
/// by the other side of the operation it ends up in) or a series.
priv enum Operand {
  Weak(WeakVal)
  Strong(Series)
}

///|
/// The series a weak literal becomes next to a column of type `other`.
///
/// An integer takes `Int64`, `Float32` or `Float64` from those types; next to
/// anything else (`Int32`, `Null`, `Boolean`, `String`, `Date`, ...) it is an
/// `Int32` when the value fits and an `Int64` otherwise. A float is a
/// `Float32` next to `Float32` and a `Float64` otherwise.
fn weak_series(name : String, w : WeakVal, other : DataType) -> Series {
  match w {
    Int(v) =>
      match other {
        Int64 => Series::int64(name, [v])
        Float32 => Series::float32(name, [Float::from_int64(v)])
        Float64 => Series::float64(name, [v.to_double()])
        _ =>
          if v >= @int.MIN_VALUE.to_int64() && v <= @int.MAX_VALUE.to_int64() {
            Series::int32(name, [v.to_int()])
          } else {
            Series::int64(name, [v])
          }
      }
    Float(v) =>
      match other {
        Float32 => Series::float32(name, [Float::from_double(v)])
        _ => Series::float64(name, [v])
      }
  }
}

///|
/// The series a weak literal becomes when nothing decides its type: `Int64`
/// or `Float64`.
fn weak_default(name : String, w : WeakVal) -> Series {
  match w {
    Int(v) => Series::int64(name, [v])
    Float(v) => Series::float64(name, [v])
  }
}

///|
/// `x op y` on integers, or `None` when the result does not fit an `Int64`
/// (or the operation has no value: division by zero).
fn fold_int(op : BinaryOp, x : Int64, y : Int64) -> Int64? {
  let min = @int64.MIN_VALUE
  match op {
    Add => {
      let r = x + y
      if ((x ^ r) & (y ^ r)) < 0L {
        None
      } else {
        Some(r)
      }
    }
    Sub => {
      let r = x - y
      if ((x ^ y) & (x ^ r)) < 0L {
        None
      } else {
        Some(r)
      }
    }
    Mul =>
      if x == 0L || y == 0L {
        Some(0L)
      } else if (x == -1L && y == min) || (y == -1L && x == min) {
        None
      } else {
        let r = x * y
        if r / y != x {
          None
        } else {
          Some(r)
        }
      }
    FloorDiv =>
      if y == 0L || (x == min && y == -1L) {
        None
      } else {
        Some(int64_floor_div(x, y))
      }
    Rem =>
      if y == 0L || (x == min && y == -1L) {
        None
      } else {
        Some(int64_rem(x, y))
      }
    _ => None
  }
}

///|
/// `x op y` on floats for the arithmetic operators, as the float kernels do
/// (`/` is not folded: polars gives a `Float64` series).
fn fold_float(op : BinaryOp, x : Double, y : Double) -> Double? {
  match op {
    Add => Some(x + y)
    Sub => Some(x - y)
    Mul => Some(x * y)
    FloorDiv => Some((x / y).floor())
    Rem => Some(x - y * (x / y).floor())
    _ => None
  }
}

///|
fn WeakVal::to_double(self : WeakVal) -> Double {
  match self {
    Int(v) => v.to_double()
    Float(v) => v
  }
}

///|
/// Two weak literals in one operation. polars keeps arithmetic on them weak
/// (`(lit(1) + lit(2)) + col(i32)` is `Int32`; an integer overflow, a
/// division by zero and `/` give an ordinary series).
fn fold_weak(
  op : BinaryOp,
  name : () -> String,
  a : WeakVal,
  b : WeakVal,
) -> Operand raise PolarsError {
  let folded : WeakVal? = match (a, b) {
    (Int(x), Int(y)) =>
      match fold_int(op, x, y) {
        Some(r) => Some(WeakVal::Int(r))
        None => None
      }
    _ =>
      match fold_float(op, a.to_double(), b.to_double()) {
        Some(r) => Some(WeakVal::Float(r))
        None => None
      }
  }
  match folded {
    Some(w) => Weak(w)
    None =>
      Strong(
        binary_series(op, weak_default(name(), a), weak_default(name(), b)),
      )
  }
}

///|
/// What an expression that is made of weak literals only comes to in polars,
/// for the error of a `filter` predicate (which names the weak type).
priv enum WeakProbe {
  /// a weak integer
  PInt(Int64)
  /// a weak float
  PFloat(Double)
  /// the null literal
  PNull
  /// polars' weak type name of a result that is no longer an `Int64`: `i32`
  /// for a division by zero (a null of the dividend's type), `u64` or `i128`
  /// for an overflow, the type of the bitwise result
  PFailed(String)
  /// negating the null literal: a `Null` result
  PNullBad
}

///|
/// `i32` when the integer fits an `Int32`, `i64` otherwise: what polars calls
/// the weak integer type in a message.
fn weak_int_name(v : Int64) -> String {
  if v >= @int.MIN_VALUE.to_int64() && v <= @int.MAX_VALUE.to_int64() {
    "i32"
  } else {
    "i64"
  }
}

///|
/// The probe of `x op y` for two weak integers.
fn weak_probe_ints(op : BinaryOp, x : Int64, y : Int64) -> WeakProbe? {
  match op {
    Add | Sub | Mul | FloorDiv | Rem =>
      match fold_int(op, x, y) {
        Some(r) => Some(PInt(r))
        None =>
          if (op is FloorDiv || op is Rem) && y == 0L {
            // a zero divisor: a null of the dividend's type
            Some(PFailed(weak_int_name(x)))
          } else {
            // an overflow: positive ones are u64, negative ones i128
            let positive = match op {
              Add => x > 0L
              Sub => x >= 0L
              Mul => (x > 0L) == (y > 0L)
              _ => true
            }
            Some(PFailed(if positive { "u64" } else { "i128" }))
          }
      }
    And | Or => {
      let name = if weak_int_name(x) == "i32" && weak_int_name(y) == "i32" {
        "i32"
      } else {
        "i64"
      }
      Some(PFailed(name))
    }
    _ => None
  }
}

///|
/// The probe of an expression of weak literals only; `None` when it has a
/// column, a typed literal or anything the normal evaluation answers the same
/// as polars.
fn weak_probe(node : ExprNode) -> WeakProbe? {
  match node {
    Literal(value, kind) =>
      match (kind, value) {
        (WeakInt, Int64(v)) => Some(PInt(v))
        (WeakFloat, Float64(v)) => Some(PFloat(v))
        (_, Null) => Some(PNull)
        _ => None
      }
    Alias(x, _) => weak_probe(x)
    Neg(x) =>
      match weak_probe(x) {
        Some(PInt(v)) =>
          if v == @int64.MIN_VALUE {
            Some(PFailed("u64"))
          } else {
            Some(PInt(0L - v))
          }
        Some(PFloat(v)) => Some(PFloat(-v))
        Some(PNull) => Some(PNullBad)
        _ => None
      }
    Not(x) =>
      match weak_probe(x) {
        Some(PInt(v)) => Some(PFailed(weak_int_name(v)))
        _ => None
      }
    Binary(op, l, r) =>
      match (weak_probe(l), weak_probe(r)) {
        (Some(PInt(x)), Some(PInt(y))) => weak_probe_ints(op, x, y)
        (Some(PInt(_) | PFloat(_) as a), Some(PInt(_) | PFloat(_) as b)) =>
          match op {
            Add | Sub | Mul | FloorDiv | Rem =>
              match (a, b) {
                (PInt(x), PFloat(y)) =>
                  fold_float(op, x.to_double(), y).map(r => PFloat(r))
                (PFloat(x), PInt(y)) =>
                  fold_float(op, x, y.to_double()).map(r => PFloat(r))
                (PFloat(x), PFloat(y)) =>
                  fold_float(op, x, y).map(r => PFloat(r))
                _ => None
              }
            _ => None
          }
        // the null literal next to a weak number: a null of its type
        (Some(PNull), Some(PInt(v))) | (Some(PInt(v)), Some(PNull)) =>
          match op {
            Add | Sub | Mul => Some(PFailed(weak_int_name(v)))
            _ => None
          }
        (Some(PNull), Some(PFloat(_))) | (Some(PFloat(_)), Some(PNull)) =>
          match op {
            Add | Sub | Mul => Some(PFailed("f64"))
            _ => None
          }
        _ => None
      }
    _ => None
  }
}

// ---------------------------------------------------------------------------
// Evaluation
// ---------------------------------------------------------------------------

///|
/// polars' expression engine refuses a `String` against a `Date` or
/// `Datetime` in a comparison. The Series operators do not: in polars 2.1.0
/// `pl.Series(["1970-01-02", "a"]) == pl.Series([date] * 2)` is `[true, false]`
/// (the text is read as a date), so the check cannot move into the
/// `Series::eq` kernels and stays here (M2 T8, item 2 of batch3-context).
fn compare_check(a : DataType, b : DataType) -> Unit raise PolarsError {
  match (a, b) {
    (String, Date | Datetime) | (Date | Datetime, String) =>
      raise InvalidOperation(
        "cannot compare 'date/datetime/time' to a string value (create native python { 'date', 'datetime', 'time' } or compare to a temporal column)",
      )
    _ => ()
  }
}

///|
/// The errors of `&` and `|` in polars' expression engine, which differ from
/// those of the Series operators; every pair that is not Boolean (or Null)
/// is an error here. A `Date` or `Datetime` on either side is
/// `InvalidOperation` (`& not allowed on bool and date`), whatever the other
/// side is; then a `String` on either side is `InvalidOperation` (text
/// `bitand`/`bitor ... dtype str`); a Boolean with a number is
/// `ComputeError`; two numbers are `InvalidOperation` (bitwise is not
/// offered).
fn logic_check(
  op : BinaryOp,
  a : DataType,
  b : DataType,
) -> Unit raise PolarsError {
  let (symbol, name) = if op is And { ("&", "bitand") } else { ("|", "bitor") }
  match (a, b) {
    (Boolean | Null, Boolean | Null) => ()
    (Date | Datetime, _) | (_, Date | Datetime) =>
      raise InvalidOperation("\{symbol} not allowed on \{a} and \{b}")
    (String, _) | (_, String) =>
      raise InvalidOperation(
        "`\{name}` operation not supported for dtype `str`",
      )
    (Boolean, t) | (t, Boolean) if t.is_numeric() =>
      raise ComputeError(
        "\{symbol} on \{polars_type_name(a)} and \{polars_type_name(b)} is not supported",
      )
    _ =>
      if a.is_numeric() && b.is_numeric() {
        // bitwise on integers is not offered
        raise InvalidOperation(
          "`\{name}` operation not supported for dtype `\{a}`",
        )
      }
  }
}

///|
/// The kernel of a binary operator.
fn binary_series(
  op : BinaryOp,
  a : Series,
  b : Series,
) -> Series raise PolarsError {
  match op {
    And | Or => logic_check(op, a.dtype(), b.dtype())
    Eq | Neq | Gt | Ge | Lt | Le => compare_check(a.dtype(), b.dtype())
    _ => ()
  }
  match op {
    Add => a.add(b)
    Sub => a.sub(b)
    Mul => a.mul(b)
    Div => a.div(b)
    FloorDiv => a.floor_div(b)
    Rem => a.rem(b)
    Eq => a.eq(b)
    Neq => a.neq(b)
    Gt => a.gt(b)
    Ge => a.ge(b)
    Lt => a.lt(b)
    Le => a.le(b)
    And => a.and_(b)
    Or => a.or_(b)
  }
}

///|
/// A strong literal as a series of length 1.
fn literal_series(name : String, value : AnyValue) -> Series {
  match value {
    Null => Series::null(name, 1)
    Boolean(x) => Series::bool(name, [x])
    Int32(x) => Series::int32(name, [x])
    Int64(x) => Series::int64(name, [x])
    Float32(x) => Series::float32(name, [x])
    Float64(x) => Series::float64(name, [x])
    String(x) => Series::str(name, [x])
    Date(x) => Series::date(name, [x])
    Datetime(x) => Series::datetime(name, [x])
  }
}

///|
/// `is_null` (`want_null`) or `is_not_null` of a column, as a `Boolean`
/// series without nulls and the column's name.
fn Series::null_mask(self : Series, want_null : Bool) -> Series {
  let n = self.len()
  let values = match self.col.validity() {
    // no null bitmap: nothing is null
    None => @arrow.Bitmap::filled(n, !want_null)
    Some(valid) => if want_null { valid.bit_not() } else { valid }
  }
  Series::make(self.name, Column::Boolean(@arrow.BoolArray::new(values, None)))
}

///|
/// Evaluates `node` without deciding the type of a weak literal: a weak
/// literal, and an alias, negation or arithmetic made of weak literals only,
/// stay `Weak`; everything else is a series.
fn eval_operand(df : DataFrame, node : ExprNode) -> Operand raise PolarsError {
  match node {
    Literal(value, kind) =>
      match (kind, value) {
        (WeakInt, Int64(v)) => Weak(WeakVal::Int(v))
        (WeakFloat, Float64(v)) => Weak(WeakVal::Float(v))
        _ => Strong(literal_series("literal", value))
      }
    Alias(x, name) =>
      match eval_operand(df, x) {
        Weak(w) => Weak(w)
        Strong(s) => Strong(s.rename(name))
      }
    Neg(x) =>
      match eval_operand(df, x) {
        Weak(Int(v)) =>
          if v == @int64.MIN_VALUE {
            Strong(weak_default(output_name(x), Int(v)).neg())
          } else {
            Weak(Int(0L - v))
          }
        Weak(Float(v)) => Weak(Float(-v))
        Strong(s) => Strong(s.neg())
      }
    Binary(op, l, r) => {
      let lo = eval_operand(df, l)
      let ro = eval_operand(df, r)
      combine_operands(op, l, r, lo, ro)
    }
    _ => Strong(eval_node(df, node))
  }
}

///|
/// The binary operation `op` of two evaluated operands; `l` and `r` are
/// their expressions (they name a weak literal that has to become a series).
fn combine_operands(
  op : BinaryOp,
  l : ExprNode,
  r : ExprNode,
  lo : Operand,
  ro : Operand,
) -> Operand raise PolarsError {
  match (lo, ro) {
    (Weak(a), Weak(b)) => fold_weak(op, () => output_name(l), a, b)
    (Weak(a), Strong(s)) =>
      Strong(binary_series(op, weak_series(output_name(l), a, s.dtype()), s))
    (Strong(s), Weak(b)) =>
      Strong(binary_series(op, s, weak_series(output_name(r), b, s.dtype())))
    (Strong(x), Strong(y)) => Strong(binary_series(op, x, y))
  }
}

///|
/// Evaluates one expanded expression on `df`. The result is named by
/// `output_name` and is as long as the frame is high, or 1 for a literal.
/// A weak literal that nothing decides the type of is an `Int64` or `Float64`.
///
/// # Errors
/// `ColumnNotFound`, and whatever the kernels raise for the types involved
/// (`InvalidOperation`, `SchemaMismatch`, `ComputeError`, `ShapeMismatch`).
fn eval_node(df : DataFrame, node : ExprNode) -> Series raise PolarsError {
  match node {
    Column(name) => frame_column(df, name)
    Columns(_) | All => abort("eval_node: a selector must be expanded first")
    Literal(_, _) | Binary(_, _, _) | Neg(_) | Alias(_, _) =>
      match eval_operand(df, node) {
        Weak(w) => weak_default(output_name(node), w)
        Strong(s) => s
      }
    Not(x) => eval_node(df, x).not_()
    Cast(x, dtype, strict) => eval_node(df, x).cast(dtype, strict~)
    IsNull(x) => eval_node(df, x).null_mask(true)
    IsNotNull(x) => eval_node(df, x).null_mask(false)
    Agg(op, x) => xagg_agg(eval_node(df, x), op)
    NUnique(x) => xagg_n_unique(eval_node(df, x))
    Func(f, x) => f.apply(eval_node(df, x))
    IsIn(x, values) => eval_node(df, x).is_in(values)
    FillNull(x, v) => xagg_fill_null(df, x, v)
    Between(x, lo, hi, closed) => xagg_between(df, x, lo, hi, closed)
    Ternary(c, t, o) => when_eval(df, c, t, o)
    Seq(op, x) => op.apply(eval_node(df, x))
    Str(op, x) => op.apply(eval_node(df, x))
    Dt(f, x) => dt_field(eval_node(df, x), f)
  }
}

// ---------------------------------------------------------------------------
// Lists of expressions
// ---------------------------------------------------------------------------

///|
/// Records `name` as an output name in `seen`; raises `DuplicateColumn` when
/// it is there already. The text is polars': that of `select`, or of
/// `with_columns`.
fn claim_name(
  seen : Map[String, Bool],
  name : String,
  with_columns : Bool,
) -> Unit raise PolarsError {
  if seen.contains(name) {
    if with_columns {
      raise DuplicateColumn(
        "the name '\{name}' passed to `LazyFrame.with_columns` is duplicate",
      )
    }
    raise DuplicateColumn(
      "projections contained duplicate output name '\{name}'. It's possible that multiple expressions are returning the same default column name. If this is the case, try renaming the columns with `.alias(\"new_name\")` to avoid duplicate column names.",
    )
  }
  seen[name] = true
}

///|
/// Gives every length-1 result the common length of the others. When every
/// result has length 1 nothing is broadcast (a `select` of literals is one
/// row).
///
/// # Errors
/// `ShapeMismatch` when two results differ in length and neither is 1. As in
/// polars the height is the longest result and the series named is the first
/// that differs from it: lengths 4 and 2 give `Series length 2 doesn't match
/// the DataFrame height of 4`, 2 and 3 give `Series length 2 doesn't match
/// the DataFrame height of 3`. When a result is empty and the height is not
/// 0, a length-1 result is not repeated either (it counts as a mismatch):
/// lengths 1, 0 and 2 name the length 1.
fn broadcast_results(
  results : Array[Series],
) -> Array[Series] raise PolarsError {
  let mut target = -1
  for s in results {
    if s.len() != 1 && s.len() > target {
      target = s.len()
    }
  }
  if target < 0 {
    return results
  }
  // with an empty result in the mix polars does not broadcast: the first
  // series that is not as long as the longest one is the offender
  let strict = target > 0 && results.iter().any(s => s.len() == 0)
  for s in results {
    if s.len() != target && (s.len() != 1 || strict) {
      raise ShapeMismatch(
        "Series length \{s.len()} doesn't match the DataFrame height of \{target}",
      )
    }
  }
  results.map(s => {
    if s.len() == target {
      s
    } else {
      Series::make(s.name, s.col.broadcast(target))
    }
  })
}

///|
/// Whether polars raises this error while it resolves the output type of an
/// expression (before it looks at the output names), as opposed to when it
/// runs the kernel: arithmetic with a `Date` or `Datetime` operand, `&` and
/// `|` with a temporal operand or a Boolean next to a number, and `~` on a
/// type that has no bitwise not in polars. `~` on `Int32` and `Int64` is
/// valid in polars; this library rejects it only when the kernel runs
/// (`Series::not_`), so that error is not a plan time one.
fn is_plan_time_error(e : PolarsError) -> Bool {
  match e {
    InvalidOperation(m) =>
      m.contains(" not allowed on ") ||
      (
        m.contains("not supported in 'not' operation") &&
        !(m.contains("dtype Int32 ") || m.contains("dtype Int64 "))
      ) ||
      (
        m.contains("operation not supported for dtypes `") &&
        (m.contains("`date`") || m.contains("`datetime"))
      )
    ComputeError(m) =>
      (m.has_prefix("& on ") || m.has_prefix("| on ")) &&
      m.has_suffix(" is not supported")
    _ => false
  }
}

///|
/// Raises the type resolution error of `node` that polars raises before it
/// checks the output names: the expression is evaluated on a frame with the
/// same columns and no row (the type errors do not depend on the values) and
/// only an error of that class is kept; any other is left to the real
/// evaluation, which raises it in its turn.
fn plan_check(df0 : DataFrame, node : ExprNode) -> Unit raise PolarsError {
  ignore(eval_node(df0, node)) catch {
    e => if is_plan_time_error(e) { raise e }
  }
}

///|
/// Resolves and evaluates `exprs` in polars' order, so that the error raised
/// is the one polars raises when several are possible:
///
/// 1. selectors of every expression (`ColumnNotFound` for `cols`, width
///    `InvalidOperation`);
/// 2. `select`: expression by expression, its plain columns
///    (`ColumnNotFound`), then its type resolution error (`plan_check`: `date
///    * i64`, `~date`, `f64 & date`), then its output name against the
///    earlier ones (the several outputs of one expression, for example
///    `a == cols(["s", "d"])`, are checked against each other before any
///    type is resolved) (`DuplicateColumn`), so `[col("a"), col("a"), col("zz")]`
///    is a duplicate and `[col("a"), col("zz"), col("a")]` a missing column;
///    `with_columns`: all the plain columns first, then per expression the
///    type resolution error and the name;
/// 3. the kernels, left to right.
///
/// The results are as the expressions give them: no broadcasting.
fn eval_unbroadcast(
  df : DataFrame,
  exprs : Array[Expr],
  with_columns : Bool,
) -> Array[Series] raise PolarsError {
  let groups : Array[Array[ExprNode]] = []
  for e in exprs {
    groups.push(expand_selectors(df, e))
  }
  let seen : Map[String, Bool] = Map([])
  let df0 = df.head(n=0)
  // the outputs one expression expands to are checked against each other
  // before their types are resolved (polars: `cols(["s", "d"]).not_()` ...)
  let group_names = (g : Array[ExprNode]) => {
    let own : Map[String, Bool] = Map([])
    for node in g {
      claim_name(own, output_name(node), with_columns)
    }
  }
  for g in groups {
    for node in g {
      check_columns(df, node)
    }
    if !with_columns {
      group_names(g)
      for node in g {
        plan_check(df0, node)
        claim_name(seen, output_name(node), false)
      }
    }
  }
  if with_columns {
    for g in groups {
      group_names(g)
      for node in g {
        plan_check(df0, node)
        claim_name(seen, output_name(node), true)
      }
    }
  }
  let results : Array[Series] = []
  for g in groups {
    for node in g {
      results.push(eval_node(df, node))
    }
  }
  results
}

///|
/// Expands and evaluates `exprs` on `df`, in order: first all the expansion
/// (see `eval_unbroadcast` for the order), then the
/// kernels. Selectors give one series per column. Length-1 results
/// are broadcast to the length of the others; when all are length 1 they stay
/// so (`select` of literals is one row).
///
/// For `sort`, `filter` and the like (T10): a result that must be as long as
/// the frame (a predicate, a sort key) has to be fitted with
/// `fit_height(s, df.height())` after this call, because a lone literal or
/// aggregate comes back with length 1 and nothing here knows the height; a
/// result of another length is `fit_height`'s `ShapeMismatch`.
///
/// # Errors
/// What `expand_selectors`, `check_columns` and `eval_node` raise, `DuplicateColumn` for a repeated
/// output name and `ShapeMismatch` for lengths that cannot be broadcast.
fn eval_exprs(
  df : DataFrame,
  exprs : Array[Expr],
) -> Array[Series] raise PolarsError {
  broadcast_results(eval_unbroadcast(df, exprs, false))
}
