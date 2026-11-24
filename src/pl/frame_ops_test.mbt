///|
/// Five rows: `a` Int32 with nulls and ties, `s` String with nulls, `f`
/// Float64 with NaN, `n` of type `Null`.
fn frame_ops_df() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int32_nullable("a", [Some(3), None, Some(1), Some(3), None]),
    @pl.Series::str_nullable("s", [Some("x"), Some("y"), None, Some("x"), None]),
    @pl.Series::float64("f", [1.0, 0.0 / 0.0, 2.0, 1.0, 0.0 / 0.0]),
    @pl.Series::null("n", 5),
  ])
}

///|
fn frame_ops_ints(df : @pl.DataFrame, name : String) -> Array[Int32?] raise {
  df.column(name).to_int32_array()
}

// ---------------------------------------------------------------------------
// filter
// ---------------------------------------------------------------------------

///|
test "filter keeps the rows where the predicate is true" {
  let df = frame_ops_df()
  let out = df.filter(@pl.col("a").gt(@pl.lit_int(1L)))
  assert_eq(out.shape(), (2, 4))
  assert_eq(frame_ops_ints(out, "a"), [Some(3), Some(3)])
  // every column is cut, the types and the Null column included
  assert_eq(out.dtypes(), df.dtypes())
  assert_eq(out.column("n").len(), 2)
  assert_eq(out.column("s").to_str_array(), [Some("x"), Some("x")])
}

///|
test "filter drops rows where the predicate is null" {
  let df = frame_ops_df()
  // a > 0 is null where a is null
  assert_eq(df.filter(@pl.col("a").gt(@pl.lit_int(0L))).height(), 3)
  // not(a > 1) keeps the false rows only
  let out = df.filter(@pl.col("a").gt(@pl.lit_int(1L)).not_())
  assert_eq(frame_ops_ints(out, "a"), [Some(1)])
  // a predicate that is null everywhere
  let none = df.filter(@pl.col("n").eq(@pl.lit_int(1L)))
  assert_eq(none.shape(), (0, 4))
}

///|
test "filter with a literal predicate keeps all rows or none" {
  let df = frame_ops_df()
  assert_true(df.filter(@pl.lit_bool(true)).equals(df))
  assert_eq(df.filter(@pl.lit_bool(false)).shape(), (0, 4))
  let empty = df.slice(0, length=0)
  assert_eq(empty.filter(@pl.lit_bool(true)).shape(), (0, 4))
  assert_eq(empty.filter(@pl.lit_bool(false)).shape(), (0, 4))
  assert_eq(empty.filter(@pl.col("a").gt(@pl.lit_int(1L))).shape(), (0, 4))
  // a frame without columns
  let z = @pl.DataFrame::empty()
  assert_eq(z.filter(@pl.lit_bool(true)).shape(), (0, 0))
}

///|
test "filter accepts one column from a selector" {
  let df = @pl.DataFrame::new([@pl.Series::bool("b", [true, false, true])])
  assert_eq(df.filter(@pl.all()).height(), 2)
  assert_eq(df.filter(@pl.cols(["b"])).height(), 2)
}

///|
test "filter errors" {
  let df = frame_ops_df()
  expect_error(
    raises(() => df.filter(@pl.col("zz"))),
    "ColumnNotFound",
    "unable to find column \"zz\"; valid columns: [\"a\", \"s\", \"f\", \"n\"]",
  )
  // not Boolean, the Null type included
  expect_error(
    raises(() => df.filter(@pl.col("a"))),
    "InvalidOperation",
    "filter predicate must be of type `Boolean`, got `Int32`",
  )
  expect_error(
    raises(() => df.filter(@pl.col("n"))),
    "InvalidOperation",
    "filter predicate must be of type `Boolean`, got `Null`",
  )
  expect_error(
    raises(() => df.filter(@pl.lit(@pl.AnyValue::Null))),
    "InvalidOperation",
    "filter predicate must be of type `Boolean`, got `Null`",
  )
  expect_error(
    raises(() => df.filter(@pl.lit_str("x"))),
    "InvalidOperation",
    "filter predicate must be of type `Boolean`, got `String`",
  )
  // a bare weak literal names its weak type
  expect_error(
    raises(() => df.filter(@pl.lit_int(1L))),
    "ComputeError",
    "filter predicate must be of type `Boolean`, got `i32`",
  )
  expect_error(
    raises(() => df.filter(@pl.lit_int(3000000000L))),
    "ComputeError",
    "filter predicate must be of type `Boolean`, got `i64`",
  )
  // weak through alias, negation and arithmetic
  let weak = "filter predicate must be of type `Boolean`, got `i32`"
  expect_error(
    raises(() => df.filter(@pl.lit_int(1L).alias("x"))),
    "ComputeError",
    weak,
  )
  expect_error(raises(() => df.filter(-@pl.lit_int(1L))), "ComputeError", weak)
  expect_error(
    raises(() => df.filter(@pl.lit_int(1L) + @pl.lit_int(2L))),
    "ComputeError",
    weak,
  )
  expect_error(
    raises(() => df.filter(@pl.lit_float(1.5) + @pl.lit_int(1L))),
    "ComputeError",
    "filter predicate must be of type `Boolean`, got `f64`",
  )
  expect_error(
    raises(() => df.filter(@pl.lit_float(1.5))),
    "ComputeError",
    "filter predicate must be of type `Boolean`, got `f64`",
  )
  // several columns, or none
  expect_error(
    raises(() => df.filter(@pl.cols(["a", "s"]))),
    "ComputeError",
    "The predicate passed to 'LazyFrame.filter' expanded to multiple expressions: ",
  )
  expect_error_kind(
    raises(() => @pl.DataFrame::empty().filter(@pl.all())),
    "ComputeError",
  )
  // the frame is unchanged
  assert_eq(df.shape(), (5, 4))
}

// ---------------------------------------------------------------------------
// sort
// ---------------------------------------------------------------------------

///|
test "sort orders ascending with nulls first by default" {
  let df = frame_ops_df()
  let out = df.sort([@pl.col("a")])
  assert_eq(frame_ops_ints(out, "a"), [None, None, Some(1), Some(3), Some(3)])
  // the other columns follow their rows
  assert_eq(out.column("s").to_str_array(), [
    Some("y"),
    None,
    None,
    Some("x"),
    Some("x"),
  ])
  assert_eq(out.dtypes(), df.dtypes())
  assert_eq(
    df.sort([@pl.col("a")], nulls_last=true).column("a").get(0),
    @pl.AnyValue::Int32(1),
  )
}

///|
test "sort is stable, also when descending" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32("k", [2, 1, 2, 1, 2]),
    @pl.Series::int32("i", [0, 1, 2, 3, 4]),
  ])
  assert_eq(frame_ops_ints(df.sort([@pl.col("k")]), "i"), [
    Some(1),
    Some(3),
    Some(0),
    Some(2),
    Some(4),
  ])
  assert_eq(frame_ops_ints(df.sort([@pl.col("k")], descending=[true]), "i"), [
    Some(0),
    Some(2),
    Some(4),
    Some(1),
    Some(3),
  ])
}

///|
test "sort descending keeps the nulls where nulls_last says" {
  let df = frame_ops_df()
  let first = df.sort([@pl.col("a")], descending=[true])
  assert_eq(frame_ops_ints(first, "a"), [None, None, Some(3), Some(3), Some(1)])
  let last = df.sort([@pl.col("a")], descending=[true], nulls_last=true)
  assert_eq(frame_ops_ints(last, "a"), [Some(3), Some(3), Some(1), None, None])
}

///|
test "sort by several keys with mixed directions" {
  let df = frame_ops_df()
  // a descending, then s ascending (nulls first)
  let out = df.sort([@pl.col("a"), @pl.col("s")], descending=[true, false])
  assert_eq(frame_ops_ints(out, "a"), [None, None, Some(3), Some(3), Some(1)])
  assert_eq(out.column("s").to_str_array(), [
    None,
    Some("y"),
    Some("x"),
    Some("x"),
    None,
  ])
  // a single flag applies to every key
  let both = df.sort([@pl.col("a"), @pl.col("s")], descending=[true])
  assert_true(
    both.equals(df.sort([@pl.col("a"), @pl.col("s")], descending=[true, true])),
  )
}

///|
test "sort puts NaN after the numbers and compares strings by code point" {
  let df = @pl.DataFrame::new([
    @pl.Series::float64("f", [0.0 / 0.0, 1.0, -1.0 / 0.0, 0.0]),
    @pl.Series::str("s", ["\u{1F600}", "\u{FF61}", "a", ""]),
  ])
  let f = df.sort([@pl.col("f")]).column("f").to_float64_array()
  assert_eq(f[0], Some(-1.0 / 0.0))
  assert_eq(f[3].unwrap().is_nan(), true)
  assert_eq(df.sort([@pl.col("s")]).column("s").to_str_array(), [
    Some(""),
    Some("a"),
    Some("\u{FF61}"),
    Some("\u{1F600}"),
  ])
}

///|
test "sort by expressions, selectors and a Null column" {
  let df = frame_ops_df()
  // -a ascending is a descending, nulls first
  let neg = df.sort([-@pl.col("a")])
  assert_eq(frame_ops_ints(neg, "a"), [None, None, Some(3), Some(3), Some(1)])
  // is_null(a) puts the nulls last (false < true)
  let nulls = df.sort([@pl.col("a").is_null()])
  assert_eq(frame_ops_ints(nulls, "a"), [Some(3), Some(1), Some(3), None, None])
  // a selector stands for several keys: `a` then `s`
  let sel = df.sort([@pl.cols(["a", "s"])], descending=[false, true])
  assert_true(
    sel.equals(df.sort([@pl.col("a"), @pl.col("s")], descending=[false, true])),
  )
  assert_true(
    df
    .sort([@pl.all()])
    .equals(df.sort([@pl.col("a"), @pl.col("s"), @pl.col("f"), @pl.col("n")])),
  )
  // a Null column is all ties: the order stays
  assert_true(df.sort([@pl.col("n")]).equals(df))
  assert_true(
    df.sort([@pl.col("n")], descending=[true], nulls_last=true).equals(df),
  )
}

///|
test "sort by abs of a column" {
  // |a|: 3 1 null 1 2
  let df = @pl.DataFrame::new([
    @pl.Series::int32_nullable("a", [Some(-3), Some(1), None, Some(-1), Some(2)]),
    @pl.Series::float64("f", [-0.5, 0.0 / 0.0, 1.5, -1.5, 0.0]),
    @pl.Series::int32("i", [0, 1, 2, 3, 4]),
  ])
  // nulls first, ties in the original order
  let asc = df.sort([@pl.col("a").abs()])
  assert_eq(frame_ops_ints(asc, "a"), [
    None,
    Some(1),
    Some(-1),
    Some(2),
    Some(-3),
  ])
  assert_eq(frame_ops_ints(asc, "i"), [2, 1, 3, 4, 0].map(x => Some(x)))
  let desc = df.sort([@pl.col("a").abs()], descending=[true], nulls_last=true)
  assert_eq(frame_ops_ints(desc, "i"), [0, 4, 1, 3, 2].map(x => Some(x)))
  // the key is not part of the output: the frame keeps its columns
  assert_eq(asc.columns(), ["a", "f", "i"])
  // a float key: NaN sorts after the numbers
  let by_f = df.sort([@pl.col("f").abs()])
  assert_eq(frame_ops_ints(by_f, "i"), [4, 0, 2, 3, 1].map(x => Some(x)))
  // abs of a computed key, and a second key for the ties
  let two = df.sort([@pl.col("a").abs(), -@pl.col("i")])
  assert_eq(frame_ops_ints(two, "i"), [2, 3, 1, 4, 0].map(x => Some(x)))
  // a key that is not a number: abs refuses a string
  let s = @pl.DataFrame::new([@pl.Series::str("s", ["a"])])
  assert_true(
    raises(() => s.sort([@pl.col("s").abs()])) is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "sort with no key or no rows" {
  let df = frame_ops_df()
  assert_true(df.sort([]).equals(df))
  assert_true(df.sort([], descending=[true]).equals(df))
  let empty = df.slice(0, length=0)
  assert_eq(empty.sort([@pl.col("a"), @pl.col("s")]).shape(), (0, 4))
  assert_eq(@pl.DataFrame::empty().sort([]).shape(), (0, 0))
}

///|
test "sort errors" {
  let df = frame_ops_df()
  expect_error(
    raises(() => {
      df.sort([@pl.col("a"), @pl.col("s")], descending=[true, false, true])
    }),
    "InvalidOperation",
    "the length of `descending` (3) does not match the length of `by` (2)",
  )
  expect_error(
    raises(() => df.sort([@pl.col("a")], descending=[true, false])),
    "InvalidOperation",
    "the length of `descending` (2) does not match the length of `by` (1)",
  )
  // counted after the selectors expand
  expect_error(
    raises(() => {
      df.sort([@pl.cols(["a", "s"]), @pl.col("f")], descending=[true, false])
    }),
    "InvalidOperation",
    "the length of `descending` (2) does not match the length of `by` (3)",
  )
  // the length is checked before the columns are looked up
  expect_error_kind(
    raises(() => {
      df.sort([@pl.col("zz"), @pl.col("a")], descending=[true, false, true])
    }),
    "InvalidOperation",
  )
  expect_error(
    raises(() => df.sort([@pl.col("zz")])),
    "ColumnNotFound",
    "unable to find column \"zz\"; valid columns: [\"a\", \"s\", \"f\", \"n\"]",
  )
  // a key that is not as long as the frame
  let msg = "sort expressions must have same length as DataFrame, got DataFrame height: 5 and Series length: 1"
  expect_error(raises(() => df.sort([@pl.lit_int(1L)])), "ShapeMismatch", msg)
  expect_error(
    raises(() => df.sort([@pl.col("a"), @pl.lit_str("x")])),
    "ShapeMismatch",
    msg,
  )
  assert_eq(df.shape(), (5, 4))
}

// ---------------------------------------------------------------------------
// unique
// ---------------------------------------------------------------------------

///|
test "unique keeps the first of equal rows, in order" {
  let df = frame_ops_df()
  // rows 0 and 3 are equal, and so are rows 1 and 4? (row 1 has s = y, row 4
  // has s = null): only 0 and 3
  let out = df.unique()
  assert_eq(out.height(), 4)
  assert_eq(frame_ops_ints(out, "a"), [Some(3), None, Some(1), None])
  assert_true(df.unique(keep=First).equals(out))
  assert_true(df.unique(maintain_order=true).equals(out))
}

///|
test "unique with keep Last and KeepNone" {
  let df = frame_ops_df()
  let last = df.unique(subset=["a"], keep=Last)
  assert_eq(last.height(), 3)
  // last of a=3 is row 3, last of a=null is row 4, a=1 is row 2: row order
  assert_eq(last.column("s").to_str_array(), [None, Some("x"), None])
  assert_eq(frame_ops_ints(last, "a"), [Some(1), Some(3), None])
  let only = df.unique(subset=["a"], keep=KeepNone)
  assert_eq(frame_ops_ints(only, "a"), [Some(1)])
  assert_eq(df.unique(keep=KeepNone).height(), 3)
}

///|
test "unique treats null, NaN and -0.0 as values that equal themselves" {
  let df = @pl.DataFrame::new([
    @pl.Series::float64("f", [0.0 / 0.0, 0.0 / 0.0, -0.0, 0.0]),
    @pl.Series::int32_nullable("a", [None, None, Some(1), Some(1)]),
  ])
  assert_eq(df.unique().height(), 2)
  assert_eq(df.unique(subset=["f"]).height(), 2)
  // the first of -0.0 and 0.0 is kept
  let z = df.unique(subset=["a"], keep=First)
  assert_eq(z.height(), 2)
}

///|
test "unique on a Null column and on frames without rows or columns" {
  let df = frame_ops_df()
  // every row of a Null column equals the others
  assert_eq(df.unique(subset=["n"]).height(), 1)
  assert_eq(df.unique(subset=["n"], keep=KeepNone).height(), 0)
  assert_eq(df.slice(0, length=0).unique().shape(), (0, 4))
  let z = @pl.DataFrame::empty()
  assert_eq(z.unique().shape(), (0, 0))
  assert_eq(z.unique(keep=KeepNone).shape(), (0, 0))
  // a name twice
  assert_eq(df.unique(subset=["a", "a"]).height(), 3)
}

///|
test "unique errors" {
  let df = frame_ops_df()
  expect_error(
    raises(() => df.unique(subset=["zz"])),
    "ColumnNotFound",
    "unable to find column \"zz\"; valid columns: [\"a\", \"s\", \"f\", \"n\"]",
  )
  expect_error(
    raises(() => df.unique(subset=["a", "zz"])),
    "ColumnNotFound",
    "unable to find column \"zz\"; valid columns: [\"a\", \"s\", \"f\", \"n\"]",
  )
  expect_error(
    raises(() => df.unique(subset=[])),
    "ComputeError",
    "at least one key is required in a group_by operation",
  )
}

// ---------------------------------------------------------------------------
// drop
// ---------------------------------------------------------------------------

///|
test "drop removes the named columns" {
  let df = frame_ops_df()
  assert_eq(df.drop(["s"]).columns(), ["a", "f", "n"])
  assert_eq(df.drop(["n", "a", "n"]).columns(), ["s", "f"])
  assert_eq(df.drop([]).columns(), ["a", "s", "f", "n"])
  assert_eq(df.drop(["zz", "a"], strict=false).columns(), ["s", "f", "n"])
  // the rows stay, the Null column can go
  assert_eq(df.drop(["n"]).height(), 5)
  // dropping everything leaves no columns
  assert_eq(df.drop(["a", "s", "f", "n"]).shape(), (0, 0))
  assert_eq(df.columns(), ["a", "s", "f", "n"])
}

///|
test "drop errors" {
  let df = frame_ops_df()
  expect_error(
    raises(() => df.drop(["zz"])),
    "ColumnNotFound",
    "\"zz\" not found",
  )
  expect_error(
    raises(() => df.drop(["a", "yy", "zz"])),
    "ColumnNotFound",
    "\"yy\" not found",
  )
  assert_eq(df.drop(["zz"], strict=false).columns(), df.columns())
  expect_error(
    raises(() => @pl.DataFrame::empty().drop(["a"])),
    "ColumnNotFound",
    "\"a\" not found",
  )
  // the name is quoted like Rust's Debug
  expect_error(
    raises(() => df.drop(["a\"b"])),
    "ColumnNotFound",
    "\"a\\\"b\" not found",
  )
}

// ---------------------------------------------------------------------------
// rename
// ---------------------------------------------------------------------------

///|
test "rename changes names and keeps data and order" {
  let df = frame_ops_df()
  let out = df.rename({ "a": "x", "n": "m" })
  assert_eq(out.columns(), ["x", "s", "f", "m"])
  assert_eq(out.dtypes(), df.dtypes())
  assert_eq(frame_ops_ints(out, "x"), frame_ops_ints(df, "a"))
  assert_eq(out.column("m").dtype(), @pl.DataType::Null)
  // all at once: a swap, a rotation
  let swap = df.rename({ "a": "s", "s": "a" })
  assert_eq(swap.columns(), ["s", "a", "f", "n"])
  assert_eq(swap.column("a").to_str_array(), df.column("s").to_str_array())
  assert_eq(df.rename({ "a": "a" }).columns(), df.columns())
  assert_eq(df.rename(({} : Map[String, String])).columns(), df.columns())
  assert_eq(df.rename({ "zz": "q", "a": "b" }, strict=false).columns(), [
    "b", "s", "f", "n",
  ])
}

///|
test "rename errors" {
  let df = frame_ops_df()
  expect_error(
    raises(() => df.rename({ "a": "s" })),
    "DuplicateColumn",
    "column 's' is duplicate",
  )
  expect_error(
    raises(() => df.rename({ "a": "x", "s": "x" })),
    "DuplicateColumn",
    "column 'x' is duplicate",
  )
  // the duplicate is reported before a missing name
  expect_error(
    raises(() => df.rename({ "zz": "s", "a": "s" })),
    "DuplicateColumn",
    "column 's' is duplicate",
  )
  expect_error(
    raises(() => df.rename({ "zz": "x" })),
    "ColumnNotFound",
    "\"zz\" not found",
  )
  expect_error(
    raises(() => df.rename({ "yy": "x", "zz": "w" })),
    "ColumnNotFound",
    "\"yy\" not found",
  )
  expect_error(
    raises(() => df.rename({ "a": "x", "zz": "w" })),
    "ColumnNotFound",
    "\"zz\" not found",
  )
  assert_eq(df.rename({ "zz": "x" }, strict=false).columns(), df.columns())
  assert_eq(df.columns(), ["a", "s", "f", "n"])
}

// ---------------------------------------------------------------------------
// fill_null
// ---------------------------------------------------------------------------

///|
test "fill_null with an integer fills the numeric columns" {
  let df = frame_ops_df()
  let out = df.fill_null(@pl.lit_int(0L))
  // a stays Int32 (the literal is weak), the strings are untouched
  assert_eq(out.column("a").dtype(), @pl.DataType::Int32)
  assert_eq(frame_ops_ints(out, "a"), [
    Some(3),
    Some(0),
    Some(1),
    Some(3),
    Some(0),
  ])
  assert_eq(out.column("s").null_count(), 2)
  // NaN is not null
  assert_eq(out.column("f").to_float64_array()[1].unwrap().is_nan(), true)
  // a Null column takes the type of the literal (Int32 for a small integer)
  assert_eq(out.column("n").dtype(), @pl.DataType::Int32)
  assert_eq(frame_ops_ints(out, "n"), [
    Some(0),
    Some(0),
    Some(0),
    Some(0),
    Some(0),
  ])
  assert_eq(out.columns(), df.columns())
  assert_eq(df.column("a").null_count(), 2)
}

///|
test "fill_null with a weak integer takes the column's type or widens" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32_nullable("i32", [None]),
    @pl.Series::int64_nullable("i64", [None]),
    @pl.Series::float32("f32", [1.0]),
    @pl.Series::null("n", 1),
  ])
  let out = df.fill_null(@pl.lit_int(3000000000L))
  assert_eq(out.dtypes(), [
    @pl.DataType::Int64,
    @pl.DataType::Int64,
    @pl.DataType::Float32,
    @pl.DataType::Int64,
  ])
  let small = df.fill_null(@pl.lit_int(7L))
  assert_eq(small.dtypes(), [
    @pl.DataType::Int32,
    @pl.DataType::Int64,
    @pl.DataType::Float32,
    @pl.DataType::Int32,
  ])
}

///|
test "fill_null with a float widens integer columns" {
  let df = frame_ops_df()
  let out = df.fill_null(@pl.lit_float(1.5))
  assert_eq(out.column("a").dtype(), @pl.DataType::Float64)
  assert_eq(out.column("a").to_float64_array(), [
    Some(3.0),
    Some(1.5),
    Some(1.0),
    Some(3.0),
    Some(1.5),
  ])
  assert_eq(out.column("n").dtype(), @pl.DataType::Float64)
  assert_eq(out.column("s").dtype(), @pl.DataType::String)
}

///|
test "fill_null with a string, a Boolean or a date fills that type and Null" {
  let df = frame_ops_df()
  let out = df.fill_null(@pl.lit_str("z"))
  assert_eq(out.column("s").to_str_array(), [
    Some("x"),
    Some("y"),
    Some("z"),
    Some("x"),
    Some("z"),
  ])
  assert_eq(out.column("n").dtype(), @pl.DataType::String)
  // the numbers keep their nulls
  assert_eq(out.column("a").null_count(), 2)
  let b = @pl.DataFrame::new([
    @pl.Series::bool_nullable("b", [Some(true), None]),
    @pl.Series::int32_nullable("i", [None, Some(1)]),
    @pl.Series::date_nullable("d", [None, Some(5)]),
  ])
  let fb = b.fill_null(@pl.lit_bool(false))
  assert_eq(fb.column("b").to_bool_array(), [Some(true), Some(false)])
  assert_eq(fb.column("i").null_count(), 1)
  let fd = b.fill_null(@pl.lit(@pl.AnyValue::Date(9)))
  assert_eq(fd.column("d").get(0), @pl.AnyValue::Date(9))
  assert_eq(fd.column("b").null_count(), 1)
}

///|
test "fill_null with a typed literal or a Null literal" {
  let df = frame_ops_df()
  // a strongly typed literal fills every column with the supertype
  let out = df.fill_null(@pl.lit(@pl.AnyValue::Int64(0L)))
  assert_eq(out.column("a").dtype(), @pl.DataType::Int64)
  assert_eq(out.column("s").to_str_array()[2], Some("0"))
  assert_eq(out.column("f").dtype(), @pl.DataType::Float64)
  // a Null literal changes nothing
  assert_true(df.fill_null(@pl.lit(@pl.AnyValue::Null)).equals(df))
  // an expression of weak literals stays weak, as in `select`: the Int32
  // column is still Int32 (polars: `df.fill_null(pl.lit(1) + pl.lit(2))`)
  let sum = df.fill_null(@pl.lit_int(1L) + @pl.lit_int(2L))
  assert_eq(sum.column("a").dtype(), @pl.DataType::Int32)
  assert_eq(frame_ops_ints(sum, "a"), [
    Some(3),
    Some(3),
    Some(1),
    Some(3),
    Some(3),
  ])
  // ... and it does not fit a Date or Datetime column
  let dates = @pl.DataFrame::new([
    @pl.Series::date_nullable("d", [None, Some(1)]),
  ])
  assert_true(
    raises(() => dates.fill_null(@pl.lit_int(1L) + @pl.lit_int(2L)))
    is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "fill_null with an expression fills every column from it" {
  let df = frame_ops_df()
  // a column of values: every column is filled row by row, in the supertype
  let out = df.fill_null(@pl.col("a"))
  assert_eq(out.columns(), ["a", "s", "f", "n"])
  assert_eq(frame_ops_ints(out, "a"), [Some(3), None, Some(1), Some(3), None])
  assert_eq(out.column("s").to_str_array(), [
    Some("x"),
    Some("y"),
    Some("1"),
    Some("x"),
    None,
  ])
  assert_eq(out.column("f").dtype(), @pl.DataType::Float64)
  assert_eq(out.column("f").null_count(), 0)
  // a Null column takes the type of the value
  assert_eq(out.column("n").dtype(), @pl.DataType::Int32)
  assert_eq(frame_ops_ints(out, "n"), [Some(3), None, Some(1), Some(3), None])
  // an expression computed from a column, an aggregate, an alias
  let neg = df.fill_null(-@pl.col("a"))
  assert_eq(neg.column("s").to_str_array()[2], Some("-1"))
  let agg = df.select([@pl.col("a")]).fill_null(@pl.col("a").sum())
  assert_eq(frame_ops_ints(agg, "a"), [
    Some(3),
    Some(7),
    Some(1),
    Some(3),
    Some(7),
  ])
  let named = df.select([@pl.col("a")]).fill_null(@pl.col("a").alias("z"))
  assert_eq(named.columns(), ["a"])
  // several columns pair up with the frame's columns
  let pair = df
    .select([@pl.col("a"), @pl.col("f")])
    .fill_null(@pl.cols(["f", "a"]))
  assert_eq(pair.column("a").dtype(), @pl.DataType::Float64)
  assert_eq(pair.column("a").null_count(), 0)
  assert_eq(pair.column("f").dtype(), @pl.DataType::Float64)
}

///|
test "fill_null on frames without rows or columns" {
  let df = frame_ops_df()
  let empty = df.slice(0, length=0).fill_null(@pl.lit_int(0L))
  assert_eq(empty.shape(), (0, 4))
  assert_eq(empty.column("n").dtype(), @pl.DataType::Int32)
  assert_eq(@pl.DataFrame::empty().fill_null(@pl.lit_int(0L)).shape(), (0, 0))
}

///|
test "fill_null errors" {
  let df = frame_ops_df()
  expect_error(
    raises(() => df.fill_null(@pl.col("zz"))),
    "ColumnNotFound",
    "unable to find column \"zz\"; valid columns: [\"a\", \"s\", \"f\", \"n\"]",
  )
  expect_error(
    raises(() => df.fill_null(@pl.cols(["a", "s"]))),
    "InvalidOperation",
    "cannot combine selectors that produce a different number of columns (2 != 4)",
  )
  // no common type: a Boolean column filled from a date column
  let bd = @pl.DataFrame::new([
    @pl.Series::bool_nullable("b", [None, Some(true)]),
    @pl.Series::date_nullable("d", [Some(1), Some(2)]),
  ])
  expect_error(
    raises(() => bd.fill_null(@pl.col("d"))),
    "SchemaMismatch",
    "failed to determine supertype of bool and date",
  )
  // no common type: Boolean and a date
  let b = @pl.DataFrame::new([@pl.Series::bool_nullable("b", [None])])
  expect_error(
    raises(() => {
      b.fill_null(@pl.lit(@pl.AnyValue::Int32(1)).cast(@pl.DataType::Date))
    }),
    "SchemaMismatch",
    "failed to determine supertype of bool and date",
  )
}

// ---------------------------------------------------------------------------
// drop_nulls
// ---------------------------------------------------------------------------

///|
test "drop_nulls drops the rows with a null in the subset" {
  let df = frame_ops_df()
  assert_eq(df.drop_nulls(subset=["a"]).height(), 3)
  assert_eq(df.drop_nulls(subset=["a", "s"]).height(), 2)
  assert_eq(df.drop_nulls(subset=["a", "a"]).height(), 3)
  // NaN is not null
  assert_eq(df.drop_nulls(subset=["f"]).height(), 5)
  // an empty subset keeps everything
  assert_true(df.drop_nulls(subset=[]).equals(df))
  let out = df.drop_nulls(subset=["s"])
  assert_eq(frame_ops_ints(out, "a"), [Some(3), None, Some(3)])
  assert_eq(out.dtypes(), df.dtypes())
}

///|
test "drop_nulls on every column and on a Null column" {
  let df = frame_ops_df()
  // the Null column has a null in every row
  assert_eq(df.drop_nulls().shape(), (0, 4))
  assert_eq(df.drop_nulls(subset=["n"]).shape(), (0, 4))
  assert_eq(df.drop(["n"]).drop_nulls().height(), 2)
  // no nulls: the frame itself
  let p = @pl.DataFrame::new([@pl.Series::int32("a", [1, 2])])
  assert_true(p.drop_nulls().equals(p))
  assert_eq(@pl.DataFrame::empty().drop_nulls().shape(), (0, 0))
  assert_eq(df.slice(0, length=0).drop_nulls().shape(), (0, 4))
}

///|
test "drop_nulls errors" {
  let df = frame_ops_df()
  expect_error(
    raises(() => df.drop_nulls(subset=["zz"])),
    "ColumnNotFound",
    "\"zz\" not found",
  )
  expect_error(
    raises(() => df.drop_nulls(subset=["a", "yy", "zz"])),
    "ColumnNotFound",
    "\"yy\" not found",
  )
  expect_error(
    raises(() => @pl.DataFrame::empty().drop_nulls(subset=["a"])),
    "ColumnNotFound",
    "\"a\" not found",
  )
}

// ---------------------------------------------------------------------------
// null_count
// ---------------------------------------------------------------------------

///|
test "null_count is one row of Int64 counts" {
  let df = frame_ops_df()
  let out = df.null_count()
  assert_eq(out.shape(), (1, 4))
  assert_eq(out.columns(), df.columns())
  assert_eq(out.dtypes(), [
    @pl.DataType::Int64,
    @pl.DataType::Int64,
    @pl.DataType::Int64,
    @pl.DataType::Int64,
  ])
  assert_eq(out.column("a").get(0), @pl.AnyValue::Int64(2L))
  assert_eq(out.column("s").get(0), @pl.AnyValue::Int64(2L))
  // NaN is not null
  assert_eq(out.column("f").get(0), @pl.AnyValue::Int64(0L))
  // a Null column counts every row
  assert_eq(out.column("n").get(0), @pl.AnyValue::Int64(5L))
}

///|
test "null_count of a frame without rows or columns" {
  let df = frame_ops_df()
  let out = df.slice(0, length=0).null_count()
  assert_eq(out.shape(), (1, 4))
  assert_eq(out.column("n").get(0), @pl.AnyValue::Int64(0L))
  // polars has a (1, 0) frame here; this library has no rows without columns
  assert_eq(@pl.DataFrame::empty().null_count().shape(), (0, 0))
}

// ---------------------------------------------------------------------------
// with_row_index
// ---------------------------------------------------------------------------

///|
test "with_row_index puts an Int64 column in front" {
  let df = frame_ops_df()
  let out = df.with_row_index()
  assert_eq(out.columns(), ["index", "a", "s", "f", "n"])
  assert_eq(out.column("index").dtype(), @pl.DataType::Int64)
  assert_eq(out.column("index").to_int64_array(), [
    Some(0L),
    Some(1L),
    Some(2L),
    Some(3L),
    Some(4L),
  ])
  assert_eq(out.column("index").null_count(), 0)
  let named = df.with_row_index(name="row", offset=10)
  assert_eq(named.columns()[0], "row")
  assert_eq(named.column("row").get(4), @pl.AnyValue::Int64(14L))
  // the other columns are the same data
  assert_eq(frame_ops_ints(named, "a"), frame_ops_ints(df, "a"))
}

///|
test "with_row_index with a large offset does not wrap" {
  let df = frame_ops_df()
  let out = df.with_row_index(offset=2147483647)
  assert_eq(out.column("index").get(0), @pl.AnyValue::Int64(2147483647L))
  assert_eq(out.column("index").get(4), @pl.AnyValue::Int64(2147483651L))
}

///|
test "with_row_index on frames without rows or columns" {
  let df = frame_ops_df()
  let empty = df.slice(0, length=0).with_row_index()
  assert_eq(empty.shape(), (0, 5))
  assert_eq(empty.column("index").dtype(), @pl.DataType::Int64)
  let z = @pl.DataFrame::empty().with_row_index(name="r", offset=4)
  assert_eq(z.shape(), (0, 1))
  assert_eq(z.columns(), ["r"])
  // the empty name is a name
  assert_eq(df.with_row_index(name="").columns()[0], "")
}

///|
test "with_row_index errors" {
  let df = frame_ops_df()
  expect_error(
    raises(() => df.with_row_index(name="a")),
    "DuplicateColumn",
    "column with name 'a' has more than one occurrence",
  )
  expect_error(
    raises(() => df.with_row_index(name="n")),
    "DuplicateColumn",
    "column with name 'n' has more than one occurrence",
  )
  expect_error(
    raises(() => df.with_row_index(offset=-1)),
    "InvalidOperation",
    "`offset` input for `with_row_index` cannot be negative, got -1",
  )
  assert_eq(df.columns(), ["a", "s", "f", "n"])
}

///|
test "filter: is_in of an empty series of another type keeps no row (polars folds it)" {
  let df = @pl.DataFrame::new([
    @pl.Series::float32_nullable("a", [Some(1.5), None, Some(2.5)]),
    @pl.Series::str("s", ["x", "y", "z"]),
    @pl.Series::int64("i", [1L, 2L, 3L]),
  ])
  let empty_i32 = @pl.Series::int32("e", [])
  let empty_str = @pl.Series::str("e", [])
  // polars 2.1.0: df.filter(pl.col("a").is_in(pl.Series([], dtype=pl.Int32)))
  // is an empty frame; select, with_columns and Series.is_in raise
  assert_eq(df.filter(@pl.col("a").is_in(empty_i32)).shape(), (0, 3))
  assert_eq(df.filter(@pl.col("s").is_in(empty_i32)).shape(), (0, 3))
  assert_eq(df.filter(@pl.col("i").is_in(empty_str)).shape(), (0, 3))
  assert_eq(df.filter(@pl.col("i").is_in(empty_i32)).shape(), (0, 3))
  assert_eq(df.filter(@pl.col("a").is_in(empty_i32).alias("z")).shape(), (0, 3))
  assert_eq(
    df.filter(@pl.col("a").is_in(@pl.Series::null("n", 0))).shape(),
    (0, 3),
  )
  // the schema is kept
  assert_eq(df.filter(@pl.col("a").is_in(empty_i32)).dtypes(), df.dtypes())
  // the inner expression is still checked
  assert_true(
    raises(() => df.filter(@pl.col("zz").is_in(empty_i32)))
    is Some(@pl.ColumnNotFound(_)),
  )
  // select and Series::is_in still raise for the same input
  assert_true(
    raises(() => df.select([@pl.col("a").is_in(empty_i32)]))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => df.column("a").is_in(empty_i32))
    is Some(@pl.InvalidOperation(_)),
  )
  // a non-empty set of the wrong type still raises in filter, and `not` is
  // not folded
  assert_true(
    raises(() => df.filter(@pl.col("a").is_in(@pl.Series::int32("e", [1]))))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => df.filter(@pl.col("a").is_in(empty_i32).not_()))
    is Some(@pl.InvalidOperation(_)),
  )
}
