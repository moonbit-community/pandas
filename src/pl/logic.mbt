///|
/// The text polars uses for the operator in "not supported" errors.
priv enum LogicOp {
  And
  Or
}

///|
fn LogicOp::method_name(self : LogicOp) -> String {
  match self {
    And => "bitand"
    Or => "bitor"
  }
}

///|
/// Kleene `and` / `or` of two Boolean arrays of the same length: `false & null`
/// is `false`, `true | null` is `true`, every other combination with a null is
/// null.
fn logic_bool_arrays(
  op : LogicOp,
  x : @arrow.BoolArray,
  y : @arrow.BoolArray,
) -> @arrow.BoolArray {
  let n = x.length()
  let b = @arrow.BoolBuilder::new(capacity=n)
  for i in 0..<n {
    let xv = x.is_valid(i)
    let yv = y.is_valid(i)
    let xb = x.value(i)
    let yb = y.value(i)
    match op {
      And =>
        if (xv && !xb) || (yv && !yb) {
          b.push(false)
        } else if xv && yv {
          b.push(true)
        } else {
          b.push_null()
        }
      Or =>
        if (xv && xb) || (yv && yb) {
          b.push(true)
        } else if xv && yv {
          b.push(false)
        } else {
          b.push_null()
        }
    }
  }
  b.finish()
}

///|
fn Series::logic(
  self : Series,
  other : Series,
  op : LogicOp,
) -> Series raise PolarsError {
  let a = self.dtype()
  let b = other.dtype()
  // polars' errors: a Boolean left side wants a Boolean right side; an integer
  // left side wants the same integer type (and is bitwise there, which this
  // library does not offer); everything else has no `&` / `|`. A `Null` is an
  // all-null Boolean when the other side is Boolean.
  match (a, b) {
    (Boolean, Boolean) | (Boolean, Null) | (Null, Boolean) => ()
    (Boolean, _) =>
      raise SchemaMismatch("cannot unpack series of type `\{b}` into `bool`")
    (Int32, Int32) | (Int64, Int64) =>
      raise InvalidOperation(
        "`\{op.method_name()}` operation not supported for dtype `\{a}`",
      )
    (Int32, _) | (Int64, _) =>
      raise SchemaMismatch("cannot unpack series of type `\{b}` into `\{a}`")
    _ =>
      raise InvalidOperation(
        "`\{op.method_name()}` operation not supported for dtype `\{a}`",
      )
  }
  let n = binary_length(op.method_name(), self.len(), other.len())
  let x = self.col.cast_lenient(Boolean).expand(n)
  let y = other.col.cast_lenient(Boolean).expand(n)
  match (x, y) {
    (Boolean(p), Boolean(q)) =>
      Series::make(self.name, Column::Boolean(logic_bool_arrays(op, p, q)))
    _ => abort("Series::logic: operands are not Boolean after the cast")
  }
}

///|
/// Element-wise `and` with Kleene three-valued logic: `false & null` is
/// `false`, `true & null` and `null & null` are null. The result is `Boolean`
/// with `self`'s name; a length-1 operand broadcasts. A `Null` column counts as
/// an all-null `Boolean`, but two `Null` columns are an error.
///
/// # Errors
/// - `SchemaMismatch` (`cannot unpack series of type `i32` into `bool``) when
///   a `Boolean` is combined with another type, or an integer with a
///   different type.
/// - `InvalidOperation` (`` `bitand` operation not supported for dtype `f64` ``)
///   when `self` is not `Boolean` (polars does bitwise `&` on two integers of
///   the same type; this library does not).
/// - `ShapeMismatch` when the lengths differ and neither is 1.
pub fn Series::and_(self : Series, other : Series) -> Series raise PolarsError {
  self.logic(other, And)
}

///|
/// Element-wise `or` with Kleene three-valued logic: `true | null` is `true`,
/// `false | null` and `null | null` are null. Types, broadcasting and errors as
/// for `Series::and_` (with `bitor` in the messages).
pub fn Series::or_(self : Series, other : Series) -> Series raise PolarsError {
  self.logic(other, Or)
}

///|
/// Logical negation; null stays null and the name is kept.
///
/// # Errors
/// `InvalidOperation` unless the series is `Boolean`; the message is polars':
/// `dtype Float32 not supported in 'not' operation` (polars negates the bits of
/// an integer, which this library does not offer).
pub fn Series::not_(self : Series) -> Series raise PolarsError {
  match self.col {
    Boolean(a) => {
      let n = a.length()
      let b = @arrow.BoolBuilder::new(capacity=n)
      for i in 0..<n {
        if a.is_valid(i) {
          b.push(!a.value(i))
        } else {
          b.push_null()
        }
      }
      Series::make(self.name, Column::Boolean(b.finish()))
    }
    _ =>
      raise InvalidOperation(
        "dtype \{polars_type_name(self.dtype())} not supported in 'not' operation",
      )
  }
}
