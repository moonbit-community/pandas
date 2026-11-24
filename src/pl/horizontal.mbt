// `sum_horizontal`, `min_horizontal` and `max_horizontal`: one value per row
// from the values of several expressions.

///|
priv enum HorizOp {
  Sum
  Min
  Max
}

///|
fn HorizOp::name(self : HorizOp) -> String {
  match self {
    Sum => "sum_horizontal"
    Min => "min_horizontal"
    Max => "max_horizontal"
  }
}

///|
/// How a row is combined: `Fill` (sum, nulls count as zero), `Strict` (sum, a
/// null makes the row null) or `Pick` (min and max, nulls are skipped and the
/// row is null only when every value is).
priv enum HorizMode {
  Fill
  Strict
  Pick
}

///|
fn ExprNode::write_horizontal(
  op : HorizOp,
  xs : Array[ExprNode],
  sb : StringBuilder,
) -> Unit {
  if xs.length() == 0 {
    sb.write_string("null")
  } else {
    xs[0].write_text(sb)
  }
  sb.write_string(".\{op.name()}(")
  if xs.length() > 1 {
    sb.write_string("[")
    for i in 1..<xs.length() {
      if i > 1 {
        sb.write_string(", ")
      }
      xs[i].write_text(sb)
    }
    sb.write_string("]")
  }
  sb.write_string(")")
}

///|
/// The common type of the inputs: the supertype of the first two, of that and
/// the third, and so on (a number and text give text).
///
/// # Errors
/// `SchemaMismatch` (`failed to determine supertype of bool and date`) for a
/// pair without one.
fn horizontal_type(dtypes : Array[DataType]) -> DataType raise PolarsError {
  let mut t = dtypes[0]
  for k in 1..<dtypes.length() {
    match ew_fill_type(t, dtypes[k]) {
      Some(u) => t = u
      None =>
        raise SchemaMismatch(
          "failed to determine supertype of \{t} and \{dtypes[k]}",
        )
    }
  }
  t
}

///|
/// Combines the rows of equally long primitive arrays. `zero` is what a null
/// counts as in `Fill` mode and `combine` joins the value so far with the next
/// one.
fn[T : Default] horizontal_prim(
  arrs : Array[@arrow.PrimArray[T]],
  n : Int32,
  mode : HorizMode,
  zero : T,
  combine : (T, T) -> T,
) -> @arrow.PrimArray[T] {
  let out = @arrow.PrimBuilder::new(capacity=n)
  for i in 0..<n {
    match mode {
      Fill => {
        let mut acc = if arrs[0].is_valid(i) { arrs[0].value(i) } else { zero }
        for k in 1..<arrs.length() {
          let v = if arrs[k].is_valid(i) { arrs[k].value(i) } else { zero }
          acc = combine(acc, v)
        }
        out.push(acc)
      }
      Strict => {
        let mut ok = true
        let mut acc = zero
        for k in 0..<arrs.length() {
          if arrs[k].is_valid(i) {
            acc = if k == 0 {
              arrs[k].value(i)
            } else {
              combine(acc, arrs[k].value(i))
            }
          } else {
            ok = false
          }
        }
        if ok {
          out.push(acc)
        } else {
          out.push_null()
        }
      }
      Pick => {
        let mut have = false
        let mut acc = zero
        for k in 0..<arrs.length() {
          if arrs[k].is_valid(i) {
            if have {
              acc = combine(acc, arrs[k].value(i))
            } else {
              acc = arrs[k].value(i)
              have = true
            }
          }
        }
        if have {
          out.push(acc)
        } else {
          out.push_null()
        }
      }
    }
  }
  out.finish()
}

///|
fn horizontal_str(
  arrs : Array[@arrow.StrArray],
  n : Int32,
  mode : HorizMode,
  combine : (String, String) -> String,
) -> @arrow.StrArray {
  let out = @arrow.StrBuilder::new(capacity=n)
  for i in 0..<n {
    let mut have = false
    let mut missing = false
    let mut acc = ""
    for k in 0..<arrs.length() {
      if arrs[k].is_valid(i) {
        let v = arrs[k].value(i)
        if have {
          acc = combine(acc, v)
        } else {
          acc = v
          have = true
        }
      } else {
        missing = true
      }
    }
    match mode {
      Fill => out.push(acc)
      Strict => if missing { out.push_null() } else { out.push(acc) }
      Pick => if have { out.push(acc) } else { out.push_null() }
    }
  }
  out.finish()
}

///|
fn horizontal_bool(
  arrs : Array[@arrow.BoolArray],
  n : Int32,
  want_min : Bool,
) -> @arrow.BoolArray {
  let out = @arrow.BoolBuilder::new(capacity=n)
  for i in 0..<n {
    let mut have = false
    let mut acc = false
    for k in 0..<arrs.length() {
      if arrs[k].is_valid(i) {
        let v = arrs[k].value(i)
        if have {
          acc = if want_min { acc && v } else { acc || v }
        } else {
          acc = v
          have = true
        }
      }
    }
    if have {
      out.push(acc)
    } else {
      out.push_null()
    }
  }
  out.finish()
}

///|
/// `min` or `max` of two floats where NaN stands for "no value" (it loses
/// against any number; two NaN give NaN) and a tie goes to the later one, as
/// polars does.
fn float_pick(want_min : Bool, acc : Double, next : Double) -> Double {
  if acc.is_nan() {
    next
  } else if next.is_nan() {
    acc
  } else if want_min {
    if next <= acc {
      next
    } else {
      acc
    }
  } else if next >= acc {
    next
  } else {
    acc
  }
}

///|
fn float32_pick(want_min : Bool, acc : Float, next : Float) -> Float {
  if acc.is_nan() {
    next
  } else if next.is_nan() {
    acc
  } else if want_min {
    if next <= acc {
      next
    } else {
      acc
    }
  } else if next >= acc {
    next
  } else {
    acc
  }
}

///|
/// The result of the operation over `cols`, all of type `t` and of length `n`.
fn horizontal_column(
  op : HorizOp,
  t : DataType,
  cols : Array[Column],
  n : Int32,
  ignore_nulls : Bool,
) -> Column {
  let want_min = op is Min
  let mode = match op {
    Sum => if ignore_nulls { HorizMode::Fill } else { Strict }
    Min | Max => Pick
  }
  let ints = () => {
    cols.map(c => {
      match c {
        Int32(a) | Date(a) => a
        _ => abort("horizontal: not an Int32 column")
      }
    })
  }
  let longs = () => {
    cols.map(c => {
      match c {
        Int64(a) | Datetime(a) => a
        _ => abort("horizontal: not an Int64 column")
      }
    })
  }
  match t {
    Int32 | Date => {
      let combine = match op {
        Sum => (a : Int32, b : Int32) => a + b
        _ =>
          (a : Int32, b : Int32) => {
            if want_min {
              if b <= a {
                b
              } else {
                a
              }
            } else if b >= a {
              b
            } else {
              a
            }
          }
      }
      let r = horizontal_prim(ints(), n, mode, 0, combine)
      if t is Date {
        Column::Date(r)
      } else {
        Column::Int32(r)
      }
    }
    Int64 | Datetime => {
      let combine = match op {
        Sum => (a : Int64, b : Int64) => a + b
        _ =>
          (a : Int64, b : Int64) => {
            if want_min {
              if b <= a {
                b
              } else {
                a
              }
            } else if b >= a {
              b
            } else {
              a
            }
          }
      }
      let r = horizontal_prim(longs(), n, mode, 0L, combine)
      if t is Datetime {
        Column::Datetime(r)
      } else {
        Column::Int64(r)
      }
    }
    Float32 => {
      let arrs = cols.map(c => {
        match c {
          Float32(a) => a
          _ => abort("horizontal: not a Float32 column")
        }
      })
      let combine = match op {
        Sum => (a : Float, b : Float) => a + b
        _ => (a : Float, b : Float) => float32_pick(want_min, a, b)
      }
      Column::Float32(horizontal_prim(arrs, n, mode, 0.0, combine))
    }
    Float64 => {
      let arrs = cols.map(c => {
        match c {
          Float64(a) => a
          _ => abort("horizontal: not a Float64 column")
        }
      })
      let combine = match op {
        Sum => (a : Double, b : Double) => a + b
        _ => (a : Double, b : Double) => float_pick(want_min, a, b)
      }
      Column::Float64(horizontal_prim(arrs, n, mode, 0.0, combine))
    }
    String => {
      let arrs = cols.map(c => {
        match c {
          String(a) => a
          _ => abort("horizontal: not a String column")
        }
      })
      let combine = match op {
        Sum => (a : String, b : String) => a + b
        _ =>
          (a : String, b : String) => {
            let c = str_cmp(b, a)
            if want_min {
              if c <= 0 {
                b
              } else {
                a
              }
            } else if c >= 0 {
              b
            } else {
              a
            }
          }
      }
      Column::String(horizontal_str(arrs, n, mode, combine))
    }
    Boolean => {
      let arrs = cols.map(c => {
        match c {
          Boolean(a) => a
          _ => abort("horizontal: not a Boolean column")
        }
      })
      Column::Boolean(horizontal_bool(arrs, n, want_min))
    }
    Null => Column::Null(n)
  }
}

///|
/// Evaluates `sum_horizontal`, `min_horizontal` or `max_horizontal` of the
/// expanded inputs `xs` (at least one).
///
/// - The result has the common type of the inputs (see `horizontal_type`); a
///   weak literal takes the common type of the other inputs. `Boolean` sums
///   to `Int64`.
/// - The name is that of the first input.
/// - Every input must have the length of the others or one row (repeated).
/// - `sum`: nulls count as zero (empty text), or with `ignore_nulls=false` a
///   null makes the row null. A `Date` or `Datetime` sum of two or more inputs
///   is an error; text sums concatenate. `min` and `max` skip nulls, NaN
///   counts as no value and a tie goes to the later input; text next to
///   anything but text is an error.
///
/// # Errors
/// `SchemaMismatch` (`failed to determine supertype of bool and date`),
/// `InvalidOperation` (`add operation not supported for dtypes `date` and
/// `date``; `got invalid or ambiguous dtypes: '[i64, str]' in expression
/// 'min_horizontal'`), `ShapeMismatch` for lengths that cannot be repeated.
fn horizontal_eval(
  df : DataFrame,
  op : HorizOp,
  xs : Array[ExprNode],
  ignore_nulls : Bool,
) -> Series raise PolarsError {
  let ops = xs.map(x => eval_operand(df, x))
  let strong : Array[DataType] = []
  for o in ops {
    if o is Strong(s) {
      strong.push(s.dtype())
    }
  }
  // polars cannot give a weak literal the type of a temporal input
  if strong.iter().any(d => d is (Date | Datetime)) &&
    ops.iter().any(o => o is Weak(_)) {
    let names = ops.map(o => {
      match o {
        Weak(w) => w.text()
        Strong(s) => s.dtype().to_string()
      }
    })
    raise InvalidOperation(
      "got invalid or ambiguous dtypes: '[\{names.join(", ")}]' in expression '\{op.name()}'",
    )
  }
  // the type a weak literal adapts to
  let base = if strong.length() > 0 {
    Some(horizontal_type(strong))
  } else {
    None
  }
  let series : Array[Series] = Array(capacity=xs.length())
  for i, o in ops {
    match o {
      Strong(s) => series.push(s)
      Weak(w) =>
        series.push(
          match base {
            Some(t) => weak_series(output_name(xs[i]), w, t)
            None => weak_default(output_name(xs[i]), w)
          },
        )
    }
  }
  let dtypes = series.map(s => s.dtype())
  let t = horizontal_type(dtypes)
  match op {
    Sum =>
      if series.length() > 1 && (t is Date || t is Datetime) {
        raise InvalidOperation(
          "add operation not supported for dtypes `\{t}` and `\{t}`",
        )
      }
    Min | Max =>
      if t is String && dtypes.iter().any(d => !(d is String) && !(d is Null)) {
        raise InvalidOperation(
          "got invalid or ambiguous dtypes: '[\{dtypes.map(d => d.to_string()).join(", ")}]' in expression '\{op.name()}'",
        )
      }
  }
  let name = series[0].name
  let fitted = broadcast_inputs(series)
  let n = fitted[0].len()
  let rt = if t is Boolean && op is Sum { DataType::Int64 } else { t }
  let cols : Array[Column] = Array(capacity=fitted.length())
  for s in fitted {
    cols.push(s.col.cast_lenient(rt))
  }
  Series::make(name, horizontal_column(op, rt, cols, n, ignore_nulls))
}

///|
/// The sum of the rows of the expressions, as a column. Nulls count as zero
/// (empty text for text) unless `ignore_nulls` is false, when a row with a
/// null is null. The type is the common type of the inputs (`Int32` with
/// `Float64` gives `Float64`, text with a number gives text, `Boolean` gives
/// `Int64`); the name is that of the first input; every input must be as long
/// as the others or one row. polars prints
/// `col("a").sum_horizontal([col("b")])`.
///
/// # Errors
/// Evaluating raises `ComputeError` for no input at all, `InvalidOperation`
/// when the inputs expand to no column (`expected at least 1 input in
/// null.sum_horizontal()`) and for a `Date` or `Datetime` sum of two or more
/// inputs, `SchemaMismatch` for types without a common one (`bool` and `date`)
/// and `ShapeMismatch` for lengths that differ.
pub fn sum_horizontal(exprs : Array[Expr], ignore_nulls~ : Bool = true) -> Expr {
  Expr::of(Horizontal(Sum, exprs.map(e => e.node), ignore_nulls))
}

///|
/// The smallest value of each row of the expressions; nulls are skipped (the
/// row is null when all are) and NaN counts as no value. Types as for
/// `sum_horizontal` (`Date` and `Datetime` are kept; `Boolean` stays `Boolean`);
/// text next to a number, a Boolean or a date is `InvalidOperation` (`got
/// invalid or ambiguous dtypes: '[i64, str]' in expression 'min_horizontal'`).
pub fn min_horizontal(exprs : Array[Expr]) -> Expr {
  Expr::of(Horizontal(Min, exprs.map(e => e.node), true))
}

///|
/// The largest value of each row of the expressions; see `min_horizontal`.
pub fn max_horizontal(exprs : Array[Expr]) -> Expr {
  Expr::of(Horizontal(Max, exprs.map(e => e.node), true))
}
