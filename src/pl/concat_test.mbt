///|
/// `<Variant>: <message>` of the error `f` raises, `"no error"` when it
/// returns.
fn[T] cd_err(f : () -> T raise @pl.PolarsError) -> String {
  match raises(f) {
    Some(e) => e.to_string()
    None => "no error"
  }
}

///|
fn concat_df(cols : Array[@pl.Series]) -> @pl.DataFrame {
  @pl.DataFrame::new(cols) catch {
    e => abort("concat_df: \{e}")
  }
}

///|
/// The nine types, three rows each, with a null in each column.
fn concat_nine(offset : Int32) -> @pl.DataFrame {
  concat_df([
    @pl.Series::bool_nullable("b", [Some(offset % 2 == 0), None, Some(true)]),
    @pl.Series::int32_nullable("i32", [Some(offset), None, Some(-2)]),
    @pl.Series::int64_nullable("i64", [Some(offset.to_int64()), None, Some(-2L)]),
    @pl.Series::float32_nullable("f32", [
      Some(Float::from_double(offset.to_double())),
      None,
      Some(-2.5),
    ]),
    @pl.Series::float64_nullable("f64", [
      Some(offset.to_double()),
      None,
      Some(0.0 / 0.0),
    ]),
    @pl.Series::str_nullable("s", [Some("s\{offset}"), None, Some("\u{1F600}")]),
    @pl.Series::date_nullable("d", [Some(offset), None, Some(-25567)]),
    @pl.Series::datetime_nullable("dt", [
      Some(offset.to_int64()),
      None,
      Some(-1L),
    ]),
    @pl.Series::null("n", 3),
  ])
}

///|
test "concat vertical stacks every type and keeps nulls and NaN" {
  let r = @pl.concat([concat_nine(1), concat_nine(2)])
  assert_eq(r.shape(), (6, 9))
  assert_eq(r.dtypes(), concat_nine(1).dtypes())
  assert_eq(r.column("i32").to_int32_array(), [
    Some(1),
    None,
    Some(-2),
    Some(2),
    None,
    Some(-2),
  ])
  assert_eq(r.column("s").to_str_array(), [
    Some("s1"),
    None,
    Some("\u{1F600}"),
    Some("s2"),
    None,
    Some("\u{1F600}"),
  ])
  assert_eq(r.column("b").to_bool_array(), [
    Some(false),
    None,
    Some(true),
    Some(true),
    None,
    Some(true),
  ])
  assert_eq(r.column("n").len(), 6)
  assert_eq(r.column("n").null_count(), 6)
  assert_true(r.column("f64").get(5) is Float64(x) && x.is_nan())
  // slicing the result gives the inputs back
  assert_eq(r.slice(0, length=3), concat_nine(1))
  assert_eq(r.slice(3), concat_nine(2))
}

///|
test "concat vertical with one frame, empty frames and no columns" {
  let a = concat_nine(1)
  assert_eq(@pl.concat([a]), a)
  assert_eq(@pl.concat([a.head(n=0), a]), a)
  assert_eq(@pl.concat([a, a.head(n=0)]), a)
  assert_eq(@pl.concat([a.head(n=0), a.head(n=0)]), a.head(n=0))
  assert_eq(
    @pl.concat([@pl.DataFrame::empty(), @pl.DataFrame::empty()]),
    @pl.DataFrame::empty(),
  )
  // a leading frame without columns is dropped, a later one does not fit
  assert_eq(@pl.concat([@pl.DataFrame::empty(), a]), a)
  assert_eq(@pl.concat([@pl.DataFrame::empty(), @pl.DataFrame::empty(), a]), a)
  assert_true(
    raises(() => @pl.concat([a, @pl.DataFrame::empty()]))
    is Some(@pl.ShapeMismatch(_)),
  )
}

///|
test "concat vertical errors" {
  let a = concat_df([@pl.Series::int64("a", [1L]), @pl.Series::str("b", ["x"])])
  assert_eq(
    cd_err(() => @pl.concat([])),
    @pl.InvalidOperation("cannot concat empty list").to_string(),
  )
  // names
  let q = concat_df([@pl.Series::int64("q", [1L]), @pl.Series::str("b", ["x"])])
  assert_eq(
    cd_err(() => @pl.concat([a, q])),
    @pl.ShapeMismatch(
      "unable to vstack, column names don't match: \"a\" and \"q\"",
    ).to_string(),
  )
  let swapped = concat_df([
    @pl.Series::str("b", ["x"]),
    @pl.Series::int64("a", [1L]),
  ])
  assert_eq(
    cd_err(() => @pl.concat([a, swapped])),
    @pl.ShapeMismatch(
      "unable to vstack, column names don't match: \"a\" and \"b\"",
    ).to_string(),
  )
  // widths
  let one = concat_df([@pl.Series::int64("a", [1L])])
  assert_eq(
    cd_err(() => @pl.concat([a, one])),
    @pl.ShapeMismatch(
      "unable to append to a DataFrame of width 2 with a DataFrame of width 1",
    ).to_string(),
  )
  assert_eq(
    cd_err(() => @pl.concat([a, a, @pl.DataFrame::empty()])),
    @pl.ShapeMismatch(
      "unable to append to a DataFrame of width 2 with a DataFrame of width 0",
    ).to_string(),
  )
  // types
  let other = concat_df([
    @pl.Series::int32("a", [1]),
    @pl.Series::str("b", ["x"]),
  ])
  assert_eq(
    cd_err(() => @pl.concat([a, other])),
    @pl.SchemaMismatch("type Int32 is incompatible with expected type Int64").to_string(),
  )
  let dt = concat_df([
    @pl.Series::datetime("a", [1L]),
    @pl.Series::str("b", ["x"]),
  ])
  assert_eq(
    cd_err(() => @pl.concat([dt, a])),
    @pl.SchemaMismatch(
      "type Int64 is incompatible with expected type Datetime('\u{3bc}s')",
    ).to_string(),
  )
  // the first mismatch in frame order wins; a name is checked before a type
  assert_eq(
    cd_err(() => @pl.concat([a, a, q, other])),
    @pl.ShapeMismatch(
      "unable to vstack, column names don't match: \"a\" and \"q\"",
    ).to_string(),
  )
  let both = concat_df([@pl.Series::str("q", ["s"])])
  assert_eq(
    cd_err(() => @pl.concat([concat_df([@pl.Series::int64("a", [1L])]), both])),
    @pl.ShapeMismatch(
      "unable to vstack, column names don't match: \"a\" and \"q\"",
    ).to_string(),
  )
}

///|
test "concat vertical reads a Null column as nulls of the type before it" {
  let a = concat_df([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::str("b", ["x", "y"]),
  ])
  let nulls = concat_df([@pl.Series::null("a", 2), @pl.Series::null("b", 2)])
  let r = @pl.concat([a, nulls, a])
  assert_eq(r.dtypes(), [@pl.DataType::Int64, @pl.DataType::String])
  assert_eq(r.column("a").to_int64_array(), [
    Some(1L),
    Some(2L),
    None,
    None,
    Some(1L),
    Some(2L),
  ])
  assert_eq(r.column("b").to_str_array(), [
    Some("x"),
    Some("y"),
    None,
    None,
    Some("x"),
    Some("y"),
  ])
  // but not the other way round: a Null column fixes the type
  assert_eq(
    cd_err(() => @pl.concat([nulls, a])),
    @pl.SchemaMismatch("type Int64 is incompatible with expected type Null").to_string(),
  )
  let r2 = @pl.concat([nulls, nulls])
  assert_eq(r2.dtypes(), [@pl.DataType::Null, @pl.DataType::Null])
  assert_eq(r2.height(), 4)
}

///|
test "concat vertical_relaxed promotes to the common type" {
  let i32 = concat_df([@pl.Series::int32("x", [1, -2147483648])])
  let i64 = concat_df([@pl.Series::int64("x", [3L])])
  let f32 = concat_df([@pl.Series::float32("x", [1.5])])
  let f64 = concat_df([@pl.Series::float64("x", [0.5])])
  let s = concat_df([@pl.Series::str("x", ["s"])])
  let b = concat_df([@pl.Series::bool("x", [true])])
  let d = concat_df([@pl.Series::date("x", [19782])])
  let dt = concat_df([@pl.Series::datetime("x", [86400000000L])])
  let n = concat_df([@pl.Series::null("x", 1)])
  let v = @pl.ConcatHow::VerticalRelaxed
  assert_eq(@pl.concat([i32, i64], how=v).dtypes(), [@pl.DataType::Int64])
  assert_eq(@pl.concat([i32, f32], how=v).dtypes(), [@pl.DataType::Float64])
  assert_eq(@pl.concat([f32, f64], how=v).dtypes(), [@pl.DataType::Float64])
  assert_eq(@pl.concat([f32, b], how=v).dtypes(), [@pl.DataType::Float32])
  assert_eq(@pl.concat([b, i32], how=v).dtypes(), [@pl.DataType::Int32])
  assert_eq(@pl.concat([d, dt], how=v).dtypes(), [@pl.DataType::Datetime])
  assert_eq(@pl.concat([n, d], how=v).dtypes(), [@pl.DataType::Date])
  assert_eq(@pl.concat([n, n], how=v).dtypes(), [@pl.DataType::Null])
  assert_eq(@pl.concat([i32, i64], how=v).column("x").to_int64_array(), [
    Some(1L),
    Some(-2147483648L),
    Some(3L),
  ])
  // a number or a date next to a string becomes a string
  let r = @pl.concat([i64, f32, s, d, b], how=v)
  assert_eq(r.dtypes(), [@pl.DataType::String])
  assert_eq(r.column("x").to_str_array(), [
    Some("3"),
    Some("1.5"),
    Some("s"),
    Some("2024-02-29"),
    Some("true"),
  ])
  // supertypes accumulate frame by frame: bool, i32, date is i32; bool, date fails
  assert_eq(@pl.concat([b, i32, d], how=v).dtypes(), [@pl.DataType::Int32])
  assert_eq(
    cd_err(() => @pl.concat([b, d, i32], how=v)),
    @pl.SchemaMismatch("failed to determine supertype of bool and date").to_string(),
  )
  assert_eq(
    cd_err(() => @pl.concat([dt, b], how=v)),
    @pl.SchemaMismatch(
      "failed to determine supertype of datetime[\u{3bc}s] and bool",
    ).to_string(),
  )
}

///|
test "concat vertical_relaxed errors and the order of the checks" {
  let v = @pl.ConcatHow::VerticalRelaxed
  let x = concat_df([@pl.Series::bool("x", [true])])
  let y = concat_df([@pl.Series::bool("y", [true])])
  let d = concat_df([@pl.Series::date("x", [1])])
  let xy = concat_df([
    @pl.Series::bool("x", [true]),
    @pl.Series::bool("y", [true]),
  ])
  assert_eq(
    cd_err(() => @pl.concat([], how=v)),
    @pl.InvalidOperation("cannot concat empty list").to_string(),
  )
  assert_eq(
    cd_err(() => @pl.concat([x, y], how=v)),
    @pl.ComputeError("schema names differ: got x, expected y").to_string(),
  )
  assert_eq(
    cd_err(() => @pl.concat([x, xy], how=v)),
    @pl.ComputeError("schema lengths differ").to_string(),
  )
  assert_eq(
    cd_err(() => @pl.concat([@pl.DataFrame::empty(), x], how=v)),
    @pl.ComputeError("schema lengths differ").to_string(),
  )
  assert_eq(
    @pl.concat([@pl.DataFrame::empty(), @pl.DataFrame::empty()], how=v),
    @pl.DataFrame::empty(),
  )
  // frame by frame: the supertype error of frame 2 comes before the name
  // error of frame 3, and the other way round
  assert_eq(
    cd_err(() => @pl.concat([x, d, y], how=v)),
    @pl.SchemaMismatch("failed to determine supertype of bool and date").to_string(),
  )
  assert_eq(
    cd_err(() => @pl.concat([x, y, d], how=v)),
    @pl.ComputeError("schema names differ: got x, expected y").to_string(),
  )
  assert_eq(@pl.concat([x], how=v), x)
}

///|
test "concat horizontal puts the columns side by side" {
  let ab = concat_df([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::str("b", ["x", "y"]),
  ])
  let c = concat_df([@pl.Series::float64_nullable("c", [Some(0.5), None])])
  let d = concat_df([@pl.Series::null("d", 2)])
  let h = @pl.ConcatHow::Horizontal
  let r = @pl.concat([ab, c, d], how=h)
  assert_eq(r.columns(), ["a", "b", "c", "d"])
  assert_eq(r.dtypes(), [
    @pl.DataType::Int64,
    @pl.DataType::String,
    @pl.DataType::Float64,
    @pl.DataType::Null,
  ])
  assert_eq(r.shape(), (2, 4))
  assert_eq(@pl.concat([ab], how=h), ab)
  // frames without columns are ignored, whatever their position
  assert_eq(
    @pl.concat([@pl.DataFrame::empty(), ab, @pl.DataFrame::empty()], how=h),
    ab,
  )
  assert_eq(
    @pl.concat([@pl.DataFrame::empty(), @pl.DataFrame::empty()], how=h),
    @pl.DataFrame::empty(),
  )
  assert_eq(
    @pl.concat([ab.head(n=0), @pl.DataFrame::empty()], how=h),
    ab.head(n=0),
  )
  // frames without rows join each other
  let e1 = ab.head(n=0)
  let e2 = concat_df([@pl.Series::null("z", 0)])
  assert_eq(@pl.concat([e1, e2], how=h).shape(), (0, 3))
}

///|
test "concat horizontal errors" {
  let h = @pl.ConcatHow::Horizontal
  let ab = concat_df([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::str("b", ["x", "y"]),
  ])
  let a1 = concat_df([@pl.Series::int64("a", [1L])])
  let c1 = concat_df([@pl.Series::int64("c", [1L])])
  let c3 = concat_df([@pl.Series::int64("c", [1L, 2L, 3L])])
  let a2 = concat_df([@pl.Series::int64("a", [5L, 6L])])
  assert_eq(
    cd_err(() => @pl.concat([], how=h)),
    @pl.InvalidOperation("cannot concat empty list").to_string(),
  )
  let heights = @pl.ShapeMismatch(
    "cannot concat dataframes with different heights in 'strict' mode",
  ).to_string()
  assert_eq(cd_err(() => @pl.concat([ab, c1], how=h)), heights)
  assert_eq(cd_err(() => @pl.concat([ab, c3], how=h)), heights)
  assert_eq(cd_err(() => @pl.concat([ab, a1], how=h)), heights) // before the duplicate name
  assert_eq(cd_err(() => @pl.concat([ab.head(n=0), a2], how=h)), heights)
  assert_eq(
    cd_err(() => @pl.concat([ab, a2], how=h)),
    @pl.DuplicateColumn(
      "could not create a new DataFrame: column with name 'a' has more than one occurrence",
    ).to_string(),
  )
}

///|
test "concat diagonal takes the union of the columns" {
  let ab = concat_df([@pl.Series::int64("a", [1L]), @pl.Series::str("b", ["x"])])
  let bc = concat_df([
    @pl.Series::str("b", ["y"]),
    @pl.Series::float64("c", [1.5]),
  ])
  let cd = concat_df([
    @pl.Series::float64("c", [2.5]),
    @pl.Series::bool("d", [true]),
  ])
  let r = @pl.concat([ab, bc, cd], how=Diagonal)
  assert_eq(r.columns(), ["a", "b", "c", "d"])
  assert_eq(r.dtypes()[2], @pl.DataType::Float64)
  assert_eq(r.column("a").to_int64_array(), [Some(1L), None, None])
  assert_eq(r.column("b").to_str_array(), [Some("x"), Some("y"), None])
  assert_eq(r.column("d").to_bool_array(), [None, None, Some(true)])
  // the column order is the order of first appearance
  let r2 = @pl.concat([bc, ab], how=Diagonal)
  assert_eq(r2.columns(), ["b", "c", "a"])
  assert_eq(r2.column("c").to_float64_array(), [Some(1.5), None])
  // a missing column has the type of its first appearance, also when the
  // frame that has it comes later and has no rows
  let d0 = concat_df([@pl.Series::date("d", [])])
  let r3 = @pl.concat([ab, d0], how=Diagonal)
  assert_eq(r3.dtypes(), [
    @pl.DataType::Int64,
    @pl.DataType::String,
    @pl.DataType::Date,
  ])
  assert_eq(r3.height(), 1)
  // frames without columns add nothing
  assert_eq(
    @pl.concat(
      [@pl.DataFrame::empty(), ab, @pl.DataFrame::empty()],
      how=Diagonal,
    ),
    ab,
  )
  assert_eq(
    @pl.concat([@pl.DataFrame::empty(), @pl.DataFrame::empty()], how=Diagonal),
    @pl.DataFrame::empty(),
  )
  assert_eq(@pl.concat([ab], how=Diagonal), ab)
}

///|
test "concat diagonal errors and Null columns" {
  let ab = concat_df([@pl.Series::int64("a", [1L]), @pl.Series::str("b", ["x"])])
  let ba_types = concat_df([
    @pl.Series::int64("b", [1L]),
    @pl.Series::str("a", ["s"]),
  ])
  assert_eq(
    cd_err(() => @pl.concat([ab, ba_types], how=Diagonal)),
    @pl.SchemaMismatch("type String is incompatible with expected type Int64").to_string(),
  )
  assert_eq(
    cd_err(() => @pl.concat([], how=Diagonal)),
    @pl.InvalidOperation("cannot concat empty list").to_string(),
  )
  // a Null column fits the type of the first appearance, not the other way
  let nulls = concat_df([@pl.Series::null("a", 2)])
  let r = @pl.concat([ab, nulls], how=Diagonal)
  assert_eq(r.column("a").to_int64_array(), [Some(1L), None, None])
  assert_eq(
    cd_err(() => @pl.concat([nulls, ab], how=Diagonal)),
    @pl.SchemaMismatch("type Int64 is incompatible with expected type Null").to_string(),
  )
  // the first appearance may be Null: that fixes the column type
  let y = concat_df([@pl.Series::str("y", ["s"])])
  let x_null = concat_df([@pl.Series::null("x", 1)])
  let x_int = concat_df([@pl.Series::int64("x", [1L])])
  assert_eq(
    cd_err(() => @pl.concat([y, x_null, x_int], how=Diagonal)),
    @pl.SchemaMismatch("type Int64 is incompatible with expected type Null").to_string(),
  )
  let r2 = @pl.concat([y, x_null], how=Diagonal)
  assert_eq(r2.dtypes(), [@pl.DataType::String, @pl.DataType::Null])
}

///|
test "vstack appends the rows of another frame" {
  let a = concat_df([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::str_nullable("b", [Some("x"), None]),
  ])
  let b = concat_df([@pl.Series::int64("a", [3L]), @pl.Series::str("b", ["z"])])
  let r = a.vstack(b)
  assert_eq(r.column("a").to_int64_array(), [Some(1L), Some(2L), Some(3L)])
  assert_eq(r.column("b").to_str_array(), [Some("x"), None, Some("z")])
  assert_eq(a.vstack(a.head(n=0)), a)
  assert_eq(a.head(n=0).vstack(a), a)
  // a frame without columns takes the other frame; the other way is an error
  assert_eq(@pl.DataFrame::empty().vstack(a), a)
  assert_eq(
    @pl.DataFrame::empty().vstack(@pl.DataFrame::empty()),
    @pl.DataFrame::empty(),
  )
  assert_eq(
    cd_err(() => a.vstack(@pl.DataFrame::empty())),
    @pl.ShapeMismatch(
      "unable to append to a DataFrame of shape (2, 2) with a DataFrame of width 0",
    ).to_string(),
  )
  // the other frame's Null columns are read as nulls
  let n = concat_df([@pl.Series::null("a", 1), @pl.Series::null("b", 1)])
  assert_eq(a.vstack(n).column("a").to_int64_array(), [Some(1L), Some(2L), None])
}

///|
test "vstack errors" {
  let a = concat_df([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::str("b", ["x", "y"]),
  ])
  let q = concat_df([@pl.Series::int64("q", [1L]), @pl.Series::str("b", ["x"])])
  assert_eq(
    cd_err(() => a.vstack(q)),
    @pl.ShapeMismatch(
      "unable to vstack, column names don't match: \"a\" and \"q\"",
    ).to_string(),
  )
  assert_eq(
    cd_err(() => a.vstack(concat_df([@pl.Series::int64("a", [1L])]))),
    @pl.ShapeMismatch(
      "unable to append to a DataFrame of shape (2, 2) with a DataFrame of width 1",
    ).to_string(),
  )
  assert_eq(
    cd_err(() => {
      a.vstack(
        concat_df([@pl.Series::int32("a", [1]), @pl.Series::str("b", ["x"])]),
      )
    }),
    @pl.SchemaMismatch("type Int32 is incompatible with expected type Int64").to_string(),
  )
  let n = concat_df([@pl.Series::null("a", 1), @pl.Series::null("b", 1)])
  assert_eq(
    cd_err(() => n.vstack(a)),
    @pl.SchemaMismatch("type Int64 is incompatible with expected type Null").to_string(),
  )
}

///|
test "hstack adds columns on the right" {
  let a = concat_df([@pl.Series::int64("a", [1L, 2L])])
  let r = a.hstack([@pl.Series::str("b", ["x", "y"]), @pl.Series::null("n", 2)])
  assert_eq(r.columns(), ["a", "b", "n"])
  assert_eq(r.dtypes(), [
    @pl.DataType::Int64,
    @pl.DataType::String,
    @pl.DataType::Null,
  ])
  assert_eq(a.hstack([]), a)
  assert_eq(@pl.DataFrame::empty().hstack([]), @pl.DataFrame::empty())
  // an empty frame has height 0: only empty columns fit
  let e = @pl.DataFrame::empty().hstack([@pl.Series::int64("c", [])])
  assert_eq(e.shape(), (0, 1))
  let e2 = a.head(n=0).hstack([@pl.Series::str("c", [])])
  assert_eq(e2.shape(), (0, 2))
  // the original frame is not changed
  assert_eq(a.shape(), (2, 1))
}

///|
test "hstack errors" {
  let ab = concat_df([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::str("b", ["x", "y"]),
  ])
  let dup = @pl.DuplicateColumn(
    "could not create a new DataFrame: column with name 'a' has more than one occurrence",
  ).to_string()
  assert_eq(cd_err(() => ab.hstack([@pl.Series::int64("a", [1L, 2L])])), dup)
  assert_eq(
    cd_err(() => {
      ab.hstack([
        @pl.Series::int64("c", [1L, 2L]),
        @pl.Series::int64("c", [1L, 2L]),
      ])
    }),
    @pl.DuplicateColumn(
      "could not create a new DataFrame: column with name 'c' has more than one occurrence",
    ).to_string(),
  )
  // duplicates are reported before heights, in column order
  assert_eq(
    cd_err(() => {
      ab.hstack([@pl.Series::int64("c", [1L]), @pl.Series::int64("a", [1L, 2L])])
    }),
    dup,
  )
  assert_eq(
    cd_err(() => ab.hstack([@pl.Series::int64("c", [1L])])),
    @pl.ShapeMismatch(
      "could not create a new DataFrame: height of column 'c' (1) does not match height of column 'a' (2)",
    ).to_string(),
  )
  assert_eq(
    cd_err(() => ab.hstack([@pl.Series::int64("c", [1L, 2L, 3L])])),
    @pl.ShapeMismatch(
      "could not create a new DataFrame: height of column 'c' (3) does not match height of column 'a' (2)",
    ).to_string(),
  )
  assert_eq(
    cd_err(() => {
      @pl.DataFrame::empty().hstack([@pl.Series::int64("c", [1L, 2L, 3L])])
    }),
    @pl.ShapeMismatch(
      "could not create a new DataFrame: height of column 'c' (3) does not match DataFrame height (0)",
    ).to_string(),
  )
}

///|
test "Series::append joins two series under the first name" {
  let a = @pl.Series::int64_nullable("a", [Some(1L), None])
  let b = @pl.Series::int64("b", [3L])
  let r = a.append(b)
  assert_eq(r.name(), "a")
  assert_eq(r.to_int64_array(), [Some(1L), None, Some(3L)])
  assert_eq(a.append(a.head(n=0)).to_int64_array(), a.to_int64_array())
  // a Null series is read as nulls of the type; two Null series stay Null
  let n = @pl.Series::null("n", 2)
  assert_eq(a.append(n).to_int64_array(), [Some(1L), None, None, None])
  assert_eq(n.append(n).dtype(), @pl.DataType::Null)
  assert_eq(n.append(n).len(), 4)
  let s = @pl.Series::str("s", ["a"]).append(@pl.Series::null("x", 1))
  assert_eq(s.to_str_array(), [Some("a"), None])
  // the inputs are not changed
  assert_eq(a.len(), 2)
}

///|
test "Series::append errors" {
  let a = @pl.Series::int64("a", [1L])
  assert_eq(
    cd_err(() => a.append(@pl.Series::int32("b", [1]))),
    @pl.SchemaMismatch("type Int32 is incompatible with expected type Int64").to_string(),
  )
  assert_eq(
    cd_err(() => a.append(@pl.Series::str("b", []))),
    @pl.SchemaMismatch("type String is incompatible with expected type Int64").to_string(),
  )
  assert_eq(
    cd_err(() => @pl.Series::null("n", 1).append(a)),
    @pl.SchemaMismatch("type Int64 is incompatible with expected type Null").to_string(),
  )
  assert_eq(
    cd_err(() => {
      @pl.Series::date("d", [1]).append(@pl.Series::datetime("t", [1L]))
    }),
    @pl.SchemaMismatch(
      "type Datetime('\u{3bc}s') is incompatible with expected type Date",
    ).to_string(),
  )
  assert_eq(
    cd_err(() => {
      @pl.Series::float64("f", [1.0]).append(@pl.Series::int64("i", [1L]))
    }),
    @pl.SchemaMismatch("type Int64 is incompatible with expected type Float64").to_string(),
  )
}

///|
test "Series::to_frame makes a one-column frame" {
  let s = @pl.Series::int64_nullable("a", [Some(1L), None])
  let df = s.to_frame()
  assert_eq(df.shape(), (2, 1))
  assert_eq(df.columns(), ["a"])
  assert_eq(df.column("a"), s)
  assert_eq(@pl.Series::null("n", 3).to_frame().dtypes(), [@pl.DataType::Null])
  assert_eq(@pl.Series::str("", []).to_frame().columns(), [""])
  assert_eq(@pl.Series::str("", []).to_frame().shape(), (0, 1))
}

///|
test "concat of many frames is linear and correct" {
  let k = 20000
  let frames : Array[@pl.DataFrame] = []
  for i in 0..<k {
    frames.push(
      concat_df([
        @pl.Series::int64("a", [i.to_int64()]),
        @pl.Series::str_nullable("b", [
          if i % 3 == 0 {
            None
          } else {
            Some("s\{i}")
          },
        ]),
      ]),
    )
  }
  let r = @pl.concat(frames)
  assert_eq(r.shape(), (k, 2))
  let a = r.column("a").to_int64_array()
  let b = r.column("b").to_str_array()
  for i in 0..<k {
    assert_eq(a[i], Some(i.to_int64()))
    assert_eq(b[i], if i % 3 == 0 { None } else { Some("s\{i}") })
  }
  let r2 = @pl.concat(frames, how=Diagonal)
  assert_eq(r2, r)
  let r3 = @pl.concat(frames, how=VerticalRelaxed)
  assert_eq(r3, r)
}

///|
test "hstack on a frame without columns names the first empty new column" {
  let e = @pl.DataFrame::empty()
  let msg = (t : String) => {
    @pl.ShapeMismatch("could not create a new DataFrame: height of column " + t).to_string()
  }
  assert_eq(
    cd_err(() => {
      e.hstack([
        @pl.Series::int64("a", []),
        @pl.Series::int64("b", [1L, 2L, 3L]),
      ])
    }),
    msg("'b' (3) does not match height of column 'a' (0)"),
  )
  assert_eq(
    cd_err(() => {
      e.hstack([
        @pl.Series::int64("a", [1L, 2L, 3L]),
        @pl.Series::int64("b", []),
      ])
    }),
    msg("'a' (3) does not match height of column 'b' (0)"),
  )
  assert_eq(
    cd_err(() => {
      e.hstack([
        @pl.Series::int64("a", [1L, 2L, 3L]),
        @pl.Series::int64("b", [1L]),
      ])
    }),
    msg("'a' (3) does not match DataFrame height (0)"),
  )
  assert_eq(
    cd_err(() => {
      e.hstack([
        @pl.Series::int64("a", [1L, 2L, 3L]),
        @pl.Series::int64("b", [1L]),
        @pl.Series::int64("c", []),
        @pl.Series::int64("d", []),
      ])
    }),
    msg("'a' (3) does not match height of column 'c' (0)"),
  )
}
