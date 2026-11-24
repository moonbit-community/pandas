///|
/// Left frame: `k` Int64 with a null and a repeated key, `x` Int32.
fn join_test_left() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int64_nullable("k", [Some(1L), Some(2L), Some(2L), None]),
    @pl.Series::int32("x", [10, 20, 30, 40]),
  ])
}

///|
/// Right frame: `k` Int64 with a null and a repeated key, `y` Int32.
fn join_test_right() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int64_nullable("k", [Some(2L), Some(3L), Some(2L), None]),
    @pl.Series::int32("y", [100, 200, 300, 400]),
  ])
}

///|
fn join_test_ints(df : @pl.DataFrame, name : String) -> Array[Int32?] raise {
  df.column(name).to_int32_array()
}

///|
fn join_test_longs(df : @pl.DataFrame, name : String) -> Array[Int64?] raise {
  df.column(name).to_int64_array()
}

// ---------------------------------------------------------------------------
// The seven kinds
// ---------------------------------------------------------------------------

///|
test "inner join: every match, left row order, then right row order" {
  let out = join_test_left().join(join_test_right(), on=[@pl.col("k")])
  assert_eq(out.columns(), ["k", "x", "y"])
  assert_eq(join_test_longs(out, "k"), [Some(2L), Some(2L), Some(2L), Some(2L)])
  assert_eq(join_test_ints(out, "x"), [Some(20), Some(20), Some(30), Some(30)])
  assert_eq(join_test_ints(out, "y"), [
    Some(100),
    Some(300),
    Some(100),
    Some(300),
  ])
}

///|
test "left join keeps every left row; a null key matches nothing" {
  let out = join_test_left().join(
    join_test_right(),
    on=[@pl.col("k")],
    how=Left,
  )
  assert_eq(out.columns(), ["k", "x", "y"])
  assert_eq(join_test_longs(out, "k"), [
    Some(1L),
    Some(2L),
    Some(2L),
    Some(2L),
    Some(2L),
    None,
  ])
  assert_eq(join_test_ints(out, "x"), [
    Some(10),
    Some(20),
    Some(20),
    Some(30),
    Some(30),
    Some(40),
  ])
  // the right column is null for the rows without a match, the null-key row
  // included
  assert_eq(join_test_ints(out, "y"), [
    None,
    Some(100),
    Some(300),
    Some(100),
    Some(300),
    None,
  ])
}

///|
test "left join with nulls_equal: a null key matches a null key" {
  let out = join_test_left().join(
    join_test_right(),
    on=[@pl.col("k")],
    how=Left,
    nulls_equal=true,
  )
  assert_eq(join_test_ints(out, "y"), [
    None,
    Some(100),
    Some(300),
    Some(100),
    Some(300),
    Some(400),
  ])
  assert_eq(out.column("k").null_count(), 1)
}

///|
test "right join: right row order, the left columns first without the key" {
  let out = join_test_left().join(
    join_test_right(),
    on=[@pl.col("k")],
    how=Right,
  )
  assert_eq(out.columns(), ["x", "k", "y"])
  assert_eq(join_test_ints(out, "x"), [
    Some(20),
    Some(30),
    None,
    Some(20),
    Some(30),
    None,
  ])
  assert_eq(join_test_longs(out, "k"), [
    Some(2L),
    Some(2L),
    Some(3L),
    Some(2L),
    Some(2L),
    None,
  ])
  assert_eq(join_test_ints(out, "y"), [
    Some(100),
    Some(100),
    Some(200),
    Some(300),
    Some(300),
    Some(400),
  ])
}

///|
test "full join keeps both keys apart unless coalesce is true" {
  let out = join_test_left().join(
    join_test_right(),
    on=[@pl.col("k")],
    how=Full,
  )
  assert_eq(out.columns(), ["k", "x", "k_right", "y"])
  assert_eq(join_test_longs(out, "k"), [
    Some(1L),
    Some(2L),
    Some(2L),
    Some(2L),
    Some(2L),
    None,
    None,
    None,
  ])
  assert_eq(join_test_longs(out, "k_right"), [
    None,
    Some(2L),
    Some(2L),
    Some(2L),
    Some(2L),
    None,
    Some(3L),
    None,
  ])
  assert_eq(join_test_ints(out, "x"), [
    Some(10),
    Some(20),
    Some(20),
    Some(30),
    Some(30),
    Some(40),
    None,
    None,
  ])
  assert_eq(join_test_ints(out, "y"), [
    None,
    Some(100),
    Some(300),
    Some(100),
    Some(300),
    None,
    Some(200),
    Some(400),
  ])
  let co = join_test_left().join(
    join_test_right(),
    on=[@pl.col("k")],
    how=Full,
    coalesce=true,
  )
  assert_eq(co.columns(), ["k", "x", "y"])
  // the right-only rows take the key of the right side
  assert_eq(join_test_longs(co, "k"), [
    Some(1L),
    Some(2L),
    Some(2L),
    Some(2L),
    Some(2L),
    None,
    Some(3L),
    None,
  ])
}

///|
test "semi and anti join keep left rows only" {
  let semi = join_test_left().join(
    join_test_right(),
    on=[@pl.col("k")],
    how=Semi,
  )
  assert_eq(semi.columns(), ["k", "x"])
  assert_eq(join_test_ints(semi, "x"), [Some(20), Some(30)])
  let anti = join_test_left().join(
    join_test_right(),
    on=[@pl.col("k")],
    how=Anti,
  )
  assert_eq(anti.columns(), ["k", "x"])
  assert_eq(join_test_ints(anti, "x"), [Some(10), Some(40)])
  // nulls_equal moves the null-key row from anti to semi
  let semi_ne = join_test_left().join(
    join_test_right(),
    on=[@pl.col("k")],
    how=Semi,
    nulls_equal=true,
  )
  assert_eq(join_test_ints(semi_ne, "x"), [Some(20), Some(30), Some(40)])
}

///|
test "cross join: left row first, the right columns renamed on a clash" {
  let a = @pl.DataFrame::new([@pl.Series::int32("a", [1, 2])])
  let b = @pl.DataFrame::new([
    @pl.Series::int32("a", [3, 4, 5]),
    @pl.Series::str("s", ["p", "q", "r"]),
  ])
  let out = a.join(b, how=Cross)
  assert_eq(out.columns(), ["a", "a_right", "s"])
  assert_eq(join_test_ints(out, "a"), [
    Some(1),
    Some(1),
    Some(1),
    Some(2),
    Some(2),
    Some(2),
  ])
  assert_eq(join_test_ints(out, "a_right"), [
    Some(3),
    Some(4),
    Some(5),
    Some(3),
    Some(4),
    Some(5),
  ])
  // an empty side gives no rows
  assert_eq(a.slice(0, length=0).join(b, how=Cross).shape(), (0, 3))
  assert_eq(a.join(b.slice(0, length=0), how=Cross).shape(), (0, 3))
  assert_eq(a.join(@pl.DataFrame::empty(), how=Cross).shape(), (0, 1))
}

// ---------------------------------------------------------------------------
// Keys
// ---------------------------------------------------------------------------

///|
test "left_on and right_on with different names" {
  let l = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2, 3]),
    @pl.Series::str("s", ["x", "y", "z"]),
  ])
  let r = @pl.DataFrame::new([
    @pl.Series::int32("b", [3, 1]),
    @pl.Series::str("t", ["P", "Q"]),
  ])
  let out = l.join(r, left_on=[@pl.col("a")], right_on=[@pl.col("b")], how=Left)
  // the key keeps the name of the left side
  assert_eq(out.columns(), ["a", "s", "t"])
  assert_eq(out.column("t").to_str_array(), [Some("Q"), None, Some("P")])
  let kept = l.join(
    r,
    left_on=[@pl.col("a")],
    right_on=[@pl.col("b")],
    how=Left,
    coalesce=false,
  )
  assert_eq(kept.columns(), ["a", "s", "b", "t"])
  // a right join keeps the name of the right side
  let rj = l.join(r, left_on=[@pl.col("a")], right_on=[@pl.col("b")], how=Right)
  assert_eq(rj.columns(), ["s", "b", "t"])
}

///|
test "several keys; selectors expand to keys" {
  let l = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 1, 2]),
    @pl.Series::str("b", ["x", "y", "x"]),
    @pl.Series::int32("v", [1, 2, 3]),
  ])
  let r = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2, 1]),
    @pl.Series::str("b", ["y", "x", "x"]),
    @pl.Series::int32("w", [7, 8, 9]),
  ])
  let out = l.join(r, on=[@pl.col("a"), @pl.col("b")])
  assert_eq(out.columns(), ["a", "b", "v", "w"])
  assert_eq(join_test_ints(out, "v"), [Some(1), Some(2), Some(3)])
  assert_eq(join_test_ints(out, "w"), [Some(9), Some(7), Some(8)])
  let sel = l.join(r, on=[@pl.cols(["a", "b"])])
  assert_true(sel.equals(out))
}

///|
test "an expression key is computed on each side and is not in the output" {
  let l = @pl.DataFrame::new([@pl.Series::int32("a", [1, 2, 3, 4])])
  let r = @pl.DataFrame::new([
    @pl.Series::int32("a", [10, 21]),
    @pl.Series::str("s", ["even", "odd"]),
  ])
  let key = @pl.col("a") % @pl.lit_int(2L)
  let out = l.join(
    r,
    left_on=[key],
    right_on=[@pl.col("a") % @pl.lit_int(10L)],
    how=Left,
  )
  // no key is coalesced: both `a` are there
  assert_eq(out.columns(), ["a", "a_right", "s"])
  assert_eq(join_test_ints(out, "a"), [Some(1), Some(2), Some(3), Some(4)])
  assert_eq(join_test_ints(out, "a_right"), [
    Some(21),
    Some(10),
    Some(21),
    Some(10),
  ])
  assert_eq(out.column("s").to_str_array(), [
    Some("odd"),
    Some("even"),
    Some("odd"),
    Some("even"),
  ])
}

///|
test "key types: Int32 with Int64 and Float32 with Float64 join, others fail" {
  let l = @pl.DataFrame::new([@pl.Series::int32("k", [1, 2, 3])])
  let r = @pl.DataFrame::new([
    @pl.Series::int64("k", [3L, 1L]),
    @pl.Series::int32("v", [30, 10]),
  ])
  // the key of a left join keeps the type of the left side
  let out = l.join(r, on=[@pl.col("k")], how=Left)
  assert_eq(out.dtypes(), [@pl.DataType::Int32, Int32])
  assert_eq(join_test_ints(out, "v"), [Some(10), None, Some(30)])
  // a right join takes the type of the right side, a coalesced full join the
  // common type
  assert_eq(
    l.join(r, on=[@pl.col("k")], how=Right).column("k").dtype(),
    @pl.DataType::Int64,
  )
  assert_eq(
    l.join(r, on=[@pl.col("k")], how=Full, coalesce=true).column("k").dtype(),
    @pl.DataType::Int64,
  )
  let f32 = @pl.DataFrame::new([@pl.Series::float32("k", [1.5, 2.5])])
  let f64 = @pl.DataFrame::new([@pl.Series::float64("k", [2.5])])
  assert_eq(f32.join(f64, on=[@pl.col("k")]).height(), 1)
  // no other pair of types
  let text = @pl.DataFrame::new([@pl.Series::str("k", ["1"])])
  expect_error(
    raises(() => l.join(text, on=[@pl.col("k")])),
    "SchemaMismatch",
    "datatypes of join keys don't match - `k`: i32 on left does not match `k`: str on right (and no other type was available to cast to)",
  )
  expect_error(
    raises(() => l.join(f64, on=[@pl.col("k")])),
    "SchemaMismatch",
    "datatypes of join keys don't match - `k`: i32 on left does not match `k`: f64 on right (and no other type was available to cast to)",
  )
  let dates = @pl.DataFrame::new([@pl.Series::date("k", [1])])
  let stamps = @pl.DataFrame::new([@pl.Series::datetime("k", [1L])])
  expect_error_kind(
    raises(() => dates.join(stamps, on=[@pl.col("k")])),
    "SchemaMismatch",
  )
}

///|
test "float keys: NaN matches NaN and -0.0 matches 0.0" {
  let nan = 0.0 / 0.0
  let l = @pl.DataFrame::new([
    @pl.Series::float64_nullable("k", [Some(1.0), Some(nan), Some(-0.0), None]),
    @pl.Series::int32("i", [0, 1, 2, 3]),
  ])
  let r = @pl.DataFrame::new([
    @pl.Series::float64_nullable("k", [Some(0.0), None, Some(nan)]),
    @pl.Series::int32("j", [0, 1, 2]),
  ])
  let out = l.join(r, on=[@pl.col("k")])
  assert_eq(join_test_ints(out, "i"), [Some(1), Some(2)])
  assert_eq(join_test_ints(out, "j"), [Some(2), Some(0)])
  let ne = l.join(r, on=[@pl.col("k")], nulls_equal=true)
  assert_eq(join_test_ints(ne, "i"), [Some(1), Some(2), Some(3)])
}

///|
test "a Null-typed key matches only with nulls_equal" {
  let l = @pl.DataFrame::new([
    @pl.Series::null("k", 2),
    @pl.Series::int32("i", [0, 1]),
  ])
  let r = @pl.DataFrame::new([
    @pl.Series::null("k", 3),
    @pl.Series::int32("j", [0, 1, 2]),
  ])
  assert_eq(l.join(r, on=[@pl.col("k")]).shape(), (0, 3))
  assert_eq(l.join(r, on=[@pl.col("k")], how=Left).shape(), (2, 3))
  let ne = l.join(r, on=[@pl.col("k")], nulls_equal=true)
  assert_eq(ne.shape(), (6, 3))
  assert_eq(ne.column("k").dtype(), @pl.DataType::Null)
  assert_eq(l.join(r, on=[@pl.col("k")], how=Anti).height(), 2)
  assert_eq(
    l.join(r, on=[@pl.col("k")], how=Anti, nulls_equal=true).height(),
    0,
  )
  // a Null key against a typed one is a type error
  let typed = @pl.DataFrame::new([@pl.Series::int32("k", [1])])
  expect_error(
    raises(() => l.join(typed, on=[@pl.col("k")])),
    "SchemaMismatch",
    "datatypes of join keys don't match - `k`: null on left does not match `k`: i32 on right (and no other type was available to cast to)",
  )
}

///|
test "string keys compare by code point" {
  let l = @pl.DataFrame::new([
    @pl.Series::str("k", ["\u{FF61}", "\u{1F600}", "a", ""]),
    @pl.Series::int32("i", [0, 1, 2, 3]),
  ])
  let r = @pl.DataFrame::new([
    @pl.Series::str("k", ["", "\u{1F600}", "\u{FF61}"]),
    @pl.Series::int32("j", [0, 1, 2]),
  ])
  let out = l.join(r, on=[@pl.col("k")], how=Left)
  assert_eq(join_test_ints(out, "j"), [Some(2), Some(1), None, Some(0)])
}

///|
test "sliced inputs (views with an offset) join like copies" {
  let l = join_test_left().slice(1, length=3)
  let r = join_test_right().slice(1)
  let out = l.join(r, on=[@pl.col("k")], how=Full)
  // l: k = 2, 2, null; r: k = 3, 2, null
  assert_eq(join_test_ints(out, "x"), [Some(20), Some(30), Some(40), None, None])
  assert_eq(join_test_ints(out, "y"), [
    Some(300),
    Some(300),
    None,
    Some(200),
    Some(400),
  ])
  // semi on a sliced left
  assert_eq(join_test_ints(l.join(r, on=[@pl.col("k")], how=Semi), "x"), [
    Some(20),
    Some(30),
  ])
}

// ---------------------------------------------------------------------------
// Empty inputs
// ---------------------------------------------------------------------------

///|
test "an empty side: the result schema is the same for every kind" {
  let l = join_test_left()
  let r = join_test_right()
  let l0 = l.slice(0, length=0)
  let r0 = r.slice(0, length=0)
  for how in [@pl.JoinHow::Inner, Left, Right, Full] {
    let a = l0.join(r, on=[@pl.col("k")], how~)
    let b = l.join(r0, on=[@pl.col("k")], how~)
    let c = l0.join(r0, on=[@pl.col("k")], how~)
    let full = l.join(r, on=[@pl.col("k")], how~)
    assert_eq(a.dtypes(), full.dtypes())
    assert_eq(b.columns(), full.columns())
    assert_eq(c.dtypes(), full.dtypes())
    assert_eq(c.height(), 0)
  }
  assert_eq(l0.join(r, on=[@pl.col("k")], how=Left).height(), 0)
  assert_eq(l.join(r0, on=[@pl.col("k")], how=Left).height(), 4)
  assert_eq(l0.join(r, on=[@pl.col("k")], how=Right).height(), 4)
  assert_eq(l.join(r0, on=[@pl.col("k")], how=Right).height(), 0)
  assert_eq(l0.join(r, on=[@pl.col("k")], how=Full).height(), 4)
  assert_eq(l.join(r0, on=[@pl.col("k")], how=Full).height(), 4)
  assert_eq(l.join(r0, on=[@pl.col("k")], how=Anti).height(), 4)
  assert_eq(l.join(r0, on=[@pl.col("k")], how=Semi).height(), 0)
  assert_eq(l0.join(r, on=[@pl.col("k")], how=Anti).height(), 0)
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

///|
test "validate checks the keys of the sides it names" {
  let l = join_test_left()
  let r = join_test_right()
  let unique = @pl.DataFrame::new([@pl.Series::int64("k", [1L, 2L, 3L])])
  // l repeats 2, r repeats 2
  expect_error(
    raises(() => l.join(r, on=[@pl.col("k")], validate=OneToOne)),
    "ComputeError",
    "join keys did not fulfill 1:1 validation",
  )
  expect_error(
    raises(() => l.join(unique, on=[@pl.col("k")], validate=OneToMany)),
    "ComputeError",
    "join keys did not fulfill 1:m validation",
  )
  expect_error(
    raises(() => unique.join(l, on=[@pl.col("k")], validate=ManyToOne)),
    "ComputeError",
    "join keys did not fulfill m:1 validation",
  )
  assert_eq(l.join(unique, on=[@pl.col("k")], validate=ManyToOne).height(), 3)
  assert_eq(unique.join(l, on=[@pl.col("k")], validate=OneToMany).height(), 3)
  assert_eq(
    unique.join(unique, on=[@pl.col("k")], validate=OneToOne).height(),
    3,
  )
  // a null key counts only with nulls_equal
  let nulls = @pl.DataFrame::new([@pl.Series::int64_nullable("k", [None, None])])
  assert_eq(nulls.join(nulls, on=[@pl.col("k")], validate=OneToOne).height(), 0)
  expect_error_kind(
    raises(() => {
      nulls.join(nulls, on=[@pl.col("k")], validate=OneToOne, nulls_equal=true)
    }),
    "ComputeError",
  )
  // right, semi and anti joins cannot be validated
  expect_error(
    raises(() => l.join(r, on=[@pl.col("k")], how=Right, validate=OneToOne)),
    "ComputeError",
    "1:1 validation on a RIGHT join is not supported",
  )
  expect_error(
    raises(() => l.join(r, on=[@pl.col("k")], how=Semi, validate=OneToMany)),
    "ComputeError",
    "1:m validation on a SEMI join is not supported",
  )
  expect_error(
    raises(() => l.join(r, on=[@pl.col("k")], how=Anti, validate=ManyToOne)),
    "ComputeError",
    "m:1 validation on a ANTI join is not supported",
  )
  // a cross join ignores it
  assert_eq(l.join(r, how=Cross, validate=OneToOne).height(), 16)
}

// ---------------------------------------------------------------------------
// Column names
// ---------------------------------------------------------------------------

///|
test "suffix: right columns that clash get it; a clash that remains is an error" {
  let l = @pl.DataFrame::new([
    @pl.Series::int32("k", [1]),
    @pl.Series::int32("v", [1]),
  ])
  let r = @pl.DataFrame::new([
    @pl.Series::int32("k", [1]),
    @pl.Series::int32("v", [2]),
  ])
  assert_eq(l.join(r, on=[@pl.col("k")]).columns(), ["k", "v", "v_right"])
  assert_eq(l.join(r, on=[@pl.col("k")], suffix="_r").columns(), [
    "k", "v", "v_r",
  ])
  assert_eq(l.join(r, on=[@pl.col("k")], coalesce=false).columns(), [
    "k", "v", "k_right", "v_right",
  ])
  expect_error(
    raises(() => l.join(r, on=[@pl.col("k")], suffix="")),
    "DuplicateColumn",
    "column 'v' is duplicate",
  )
  // the suffixed name exists on the left
  let l2 = l.with_columns([@pl.lit_int(0L).alias("v_right")])
  expect_error(
    raises(() => l2.join(r, on=[@pl.col("k")])),
    "DuplicateColumn",
    "column with name 'v_right' already exists",
  )
  // ... or on the right
  let r2 = r.with_columns([@pl.lit_int(0L).alias("v_right")])
  expect_error(
    raises(() => l.join(r2, on=[@pl.col("k")])),
    "DuplicateColumn",
    "column 'v_right' is duplicate",
  )
  // a semi join has no right columns, so nothing clashes
  assert_eq(l.join(r2, on=[@pl.col("k")], how=Semi, suffix="").columns(), [
    "k", "v",
  ])
}

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------

///|
test "argument errors, in polars' order" {
  let l = join_test_left()
  let r = join_test_right()
  let k = [@pl.col("k")]
  expect_error(
    raises(() => l.join(r, on=k, left_on=k)),
    "InvalidOperation",
    "cannot use 'on' in conjunction with 'left_on' or 'right_on'",
  )
  expect_error(
    raises(() => l.join(r, left_on=k)),
    "InvalidOperation",
    "'left_on' requires corresponding 'right_on'",
  )
  expect_error(
    raises(() => l.join(r, right_on=k)),
    "InvalidOperation",
    "'left_on' requires corresponding 'right_on'",
  )
  expect_error(
    raises(() => l.join(r)),
    "InvalidOperation",
    "must specify `on` OR `left_on` and `right_on`",
  )
  expect_error(
    raises(() => l.join(r, on=k, how=Cross)),
    "InvalidOperation",
    "cross join should not pass join keys",
  )
  expect_error(
    raises(() => l.join(r, left_on=k, right_on=[@pl.col("k"), @pl.col("y")])),
    "InvalidOperation",
    "the number of columns given as join key (left: 1, right:2) should be equal",
  )
  expect_error(
    raises(() => l.join(r, on=[])),
    "InvalidOperation",
    "expected join keys/predicates",
  )
  expect_error(
    raises(() => l.join(r, on=[@pl.col("zz")])),
    "ColumnNotFound",
    "unable to find column \"zz\"; valid columns: [\"k\", \"x\"]",
  )
  expect_error(
    raises(() => l.join(r, on=[@pl.col("x")])),
    "ColumnNotFound",
    "unable to find column \"x\"; valid columns: [\"k\", \"y\"]",
  )
  expect_error(
    raises(() => l.join(r, on=[@pl.cols(["k", "zz"])])),
    "ColumnNotFound",
    "\"zz\" not found",
  )
  expect_error(
    raises(() => l.join(r, left_on=[@pl.all()], right_on=k)),
    "InvalidOperation",
    "join keys expanded to a different number of expressions (left: 2, right: 1)",
  )
  expect_error(
    raises(() => @pl.DataFrame::empty().join(r, left_on=[@pl.all()], right_on=k)),
    "InvalidOperation",
    "left join keys expanded to zero expressions",
  )
  expect_error(
    raises(() => l.join(r, on=[@pl.col("k").alias("q")])),
    "InvalidOperation",
    "'alias' is not allowed in a join key, use 'with_columns' first",
  )
  expect_error(
    raises(() => l.join(r, on=[@pl.col("x").cum_sum(), @pl.col("k")])),
    "ColumnNotFound",
    "unable to find column \"x\"; valid columns: [\"k\", \"y\"]",
  )
  expect_error(
    raises(() => {
      l.join(r, left_on=[@pl.col("x").cum_sum()], right_on=[@pl.col("y")])
    }),
    "InvalidOperation",
    "all join key expressions must be elementwise.",
  )
  expect_error(
    raises(() => {
      l.join(r, left_on=[@pl.col("k"), @pl.col("k")], right_on=[
        @pl.col("k"),
        @pl.col("k"),
      ])
    }),
    "InvalidOperation",
    "joining with repeated key names; already joined on k and k",
  )
}

///|
test "JoinHow shows polars' names" {
  assert_eq(
    [@pl.JoinHow::Inner, Left, Right, Full, Semi, Anti, Cross].map(h => {
      h.to_string()
    }),
    ["inner", "left", "right", "full", "semi", "anti", "cross"],
  )
  assert_true(@pl.JoinHow::Inner == Inner)
  assert_true(@pl.JoinHow::Inner != Left)
}

// ---------------------------------------------------------------------------
// Size
// ---------------------------------------------------------------------------

///|
test "a thousand rows against a thousand rows join in one pass" {
  let n = 1000
  let l = @pl.DataFrame::new([
    @pl.Series::int64("k", Array::makei(n, i => (i * 7 % n).to_int64())),
    @pl.Series::int32("i", Array::makei(n, i => i)),
  ])
  let r = @pl.DataFrame::new([
    @pl.Series::int64("k", Array::makei(n, i => (i * 3 % n).to_int64())),
    @pl.Series::int32("j", Array::makei(n, i => i)),
  ])
  // both keys are permutations of 0..n
  let out = l.join(r, on=[@pl.col("k")])
  assert_eq(out.height(), n)
  let ks = join_test_longs(out, "k")
  for i in 0..<n {
    assert_eq(ks[i], Some((i * 7 % n).to_int64()))
  }
  // every right row repeated: the output is as large as the matches
  let few = @pl.DataFrame::new([
    @pl.Series::int64("k", Array::make(50, 3L)),
    @pl.Series::int32("j", Array::makei(50, i => i)),
  ])
  let dup = l.join(few, on=[@pl.col("k")], how=Left)
  assert_eq(dup.height(), n - 1 + 50)
}

///|
test "cross join: a result that does not fit in Int32 rows is refused before anything is built" {
  let l = @pl.DataFrame::new([
    @pl.Series::int32("a", Array::makei(65536, i => i)),
  ])
  let r = @pl.DataFrame::new([
    @pl.Series::int32("b", Array::makei(32768, i => i)),
  ])
  // 65536 * 32768 = 2^31 rows
  expect_error(
    raises(() => l.join(r, how=Cross)),
    "ComputeError",
    "the cross join would have more than 2147483647 rows (65536 x 32768)",
  )
}

///|
test "full join with coalesce=true: a right column used for two keys is replaced once, the other right columns stay" {
  let l = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::int64("x", [10L, 20L]),
  ])
  let r = @pl.DataFrame::new([
    @pl.Series::int64("y", [10L, 2L, 5L]),
    @pl.Series::int32("z", [7, 8, 9]),
  ])
  let out = l.join(
    r,
    left_on=[@pl.col("a"), @pl.col("x")],
    right_on=[@pl.col("y"), @pl.col("y")],
    how=Full,
    coalesce=true,
  )
  // polars drops `z` here as well (see known-diffs/join.md); the library keeps it
  assert_eq(out.columns(), ["a", "x", "z"])
  assert_eq(join_test_longs(out, "a"), [
    Some(1L),
    Some(2L),
    Some(10L),
    Some(2L),
    Some(5L),
  ])
  assert_eq(join_test_longs(out, "x"), [
    Some(10L),
    Some(20L),
    Some(10L),
    Some(2L),
    Some(5L),
  ])
  assert_eq(join_test_ints(out, "z"), [None, None, Some(7), Some(8), Some(9)])
}

///|
test "a key that is not elementwise: the key types are compared first" {
  let l = @pl.DataFrame::new([
    @pl.Series::str("s", ["a", "b"]),
    @pl.Series::int64("n", [1L, 2L]),
  ])
  let k = @pl.col("s").cum_sum()
  // the cumulative sum of a text is an Int64 key in polars: it matches `n`, so
  // the key is then refused as not elementwise
  expect_error(
    raises(() => l.join(l, left_on=[k], right_on=[@pl.col("n")])),
    "InvalidOperation",
    "all join key expressions must be elementwise.",
  )
  expect_error(
    raises(() => l.join(l, left_on=[@pl.col("n")], right_on=[k])),
    "InvalidOperation",
    "all join key expressions must be elementwise.",
  )
  // against a text the Int64 key is a type mismatch, reported first
  expect_error(
    raises(() => l.join(l, left_on=[k], right_on=[@pl.col("s")])),
    "SchemaMismatch",
    "datatypes of join keys don't match - `s`: i64 on left does not match `s`: str on right (and no other type was available to cast to)",
  )
}
