///|
test "kleene logic" {
  let t = @pl.Series::bool_nullable("a", [Some(false), Some(true), None, None])
  let u = @pl.Series::bool_nullable("b", [None, None, Some(false), Some(true)])
  assert_eq(t.and_(u).to_bool_array(), [Some(false), None, Some(false), None])
  assert_eq(t.or_(u).to_bool_array(), [None, Some(true), None, Some(true)])
}

///|
test "and_, or_ and not_ truth tables with nulls" {
  let a = @pl.Series::bool_nullable("a", [
    Some(true),
    Some(true),
    Some(false),
    Some(false),
    None,
    None,
    None,
    Some(true),
    Some(false),
  ])
  let b = @pl.Series::bool_nullable("b", [
    Some(true),
    Some(false),
    Some(true),
    Some(false),
    Some(true),
    Some(false),
    None,
    None,
    None,
  ])
  assert_eq(a.and_(b).to_bool_array(), [
    Some(true),
    Some(false),
    Some(false),
    Some(false),
    None,
    Some(false),
    None,
    None,
    Some(false),
  ])
  assert_eq(a.or_(b).to_bool_array(), [
    Some(true),
    Some(true),
    Some(true),
    Some(false),
    Some(true),
    None,
    None,
    Some(true),
    None,
  ])
  assert_eq(a.not_().to_bool_array(), [
    Some(false),
    Some(false),
    Some(true),
    Some(true),
    None,
    None,
    None,
    Some(false),
    Some(true),
  ])
  assert_eq(a.and_(b).name(), "a")
  assert_eq(a.not_().name(), "a")
}

///|
test "logic broadcasts a length 1 operand" {
  let a = @pl.Series::bool_nullable("a", [Some(true), None, Some(false)])
  let t = @pl.Series::bool("t", [true])
  let n = @pl.Series::bool_nullable("n", [None])
  assert_eq(a.and_(t).to_bool_array(), [Some(true), None, Some(false)])
  assert_eq(t.and_(a).to_bool_array(), [Some(true), None, Some(false)])
  assert_eq(a.or_(n).to_bool_array(), [Some(true), None, None])
  assert_eq(n.and_(a).to_bool_array(), [None, None, Some(false)])
  assert_eq(@pl.Series::bool("e", []).or_(t).len(), 0)
}

///|
test "a Null column is an all-null Boolean for and_ and or_" {
  let a = @pl.Series::bool("a", [true, false])
  let n = @pl.Series::null("n", 2)
  assert_eq(a.and_(n).to_bool_array(), [None, Some(false)])
  assert_eq(n.and_(a).to_bool_array(), [None, Some(false)])
  assert_eq(a.or_(n).to_bool_array(), [Some(true), None])
  assert_eq(n.or_(a).to_bool_array(), [Some(true), None])
  assert_eq(a.and_(n).dtype(), @pl.DataType::Boolean)
}

///|
test "logic errors" {
  let b = @pl.Series::bool("a", [true])
  let i = @pl.Series::int32("b", [1])
  let l = @pl.Series::int64("c", [1L])
  let f = @pl.Series::float64("f", [1.0])
  let n = @pl.Series::null("n", 1)
  assert_eq(
    err_text(() => b.and_(i)),
    "SchemaMismatch: cannot unpack series of type `i32` into `bool`",
  )
  assert_eq(
    err_text(() => i.or_(b)),
    "SchemaMismatch: cannot unpack series of type `bool` into `i32`",
  )
  assert_eq(
    err_text(() => i.and_(l)),
    "SchemaMismatch: cannot unpack series of type `i64` into `i32`",
  )
  assert_eq(
    err_text(() => f.and_(b)),
    "InvalidOperation: `bitand` operation not supported for dtype `f64`",
  )
  assert_eq(
    err_text(() => @pl.Series::str("s", ["x"]).or_(b)),
    "InvalidOperation: `bitor` operation not supported for dtype `str`",
  )
  assert_eq(
    err_text(() => n.and_(n)),
    "InvalidOperation: `bitand` operation not supported for dtype `null`",
  )
  // integers are bitwise in polars; here logic is Boolean only
  assert_true(raises(() => i.and_(i)) is Some(@pl.InvalidOperation(_)))
  assert_true(raises(() => l.or_(l)) is Some(@pl.InvalidOperation(_)))
  assert_eq(
    err_text(() => {
      b.and_(@pl.Series::bool("b", [true, false, true]).slice(0, length=2))
    }),
    "no error",
  )
  assert_eq(
    err_text(() => {
      @pl.Series::bool("a", [true, false]).and_(
        @pl.Series::bool("b", [true, false, true]),
      )
    }),
    "ShapeMismatch: cannot evaluate two Series of different lengths (2 and 3)",
  )
}

///|
test "not_ errors" {
  assert_eq(
    err_text(() => @pl.Series::float32("f", [1.0]).not_()),
    "InvalidOperation: dtype Float32 not supported in 'not' operation",
  )
  assert_eq(
    err_text(() => @pl.Series::str("s", ["x"]).not_()),
    "InvalidOperation: dtype String not supported in 'not' operation",
  )
  assert_eq(
    err_text(() => @pl.Series::date("d", [1]).not_()),
    "InvalidOperation: dtype Date not supported in 'not' operation",
  )
  assert_eq(
    err_text(() => @pl.Series::datetime("t", [1L]).not_()),
    "InvalidOperation: dtype Datetime('\u{3bc}s') not supported in 'not' operation",
  )
  assert_eq(
    err_text(() => @pl.Series::null("n", 1).not_()),
    "InvalidOperation: dtype Null not supported in 'not' operation",
  )
  assert_true(
    raises(() => @pl.Series::int32("i", [1]).not_())
    is Some(@pl.InvalidOperation(_)),
  )
  assert_eq(@pl.Series::bool("e", []).not_().len(), 0)
}
