// Tests of the final fix wave (see docs/golden/known-diffs). Expected values
// of the cases that compare with polars were taken from polars 2.1.0.

// ---------------------------------------------------------------------------
// The size of a join is checked before anything is allocated
// ---------------------------------------------------------------------------

///|
fn ff_constant_key_frame(
  n : Int32,
  value : String,
) -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::int64("k", Array::make(n, 7L)),
    @pl.Series::int64(value, Array::makei(n, i => i.to_int64())),
  ])
}

///|
test "join on a constant key of two 50000-row frames raises ComputeError for Inner, Left, Right and Full" {
  let l = ff_constant_key_frame(50000, "a")
  let r = ff_constant_key_frame(50000, "b")
  for how in [@pl.JoinHow::Inner, Left, Right, Full] {
    expect_error(
      raises(() => l.join(r, on=[@pl.col("k")], how~)),
      "ComputeError",
      "the \{how} join would have more than 2147483647 rows (2500000000 rows)",
    )
  }
}

///|
test "join size guard counts the rows the join really makes" {
  // 3 left rows with key 1 and 2 with key 2; right: 4 rows with key 1, none with 2
  let l = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L, 1L, 1L, 2L, 2L]),
    @pl.Series::int64("a", [1L, 2L, 3L, 4L, 5L]),
  ])
  let r = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L, 1L, 1L, 1L, 3L]),
    @pl.Series::int64("b", [1L, 2L, 3L, 4L, 5L]),
  ])
  // inner: 3 * 4; left: 12 + 2 unmatched; right: 12 + 1 unmatched; full: 12 + 2 + 1
  assert_eq(l.join(r, on=[@pl.col("k")]).height(), 12)
  assert_eq(l.join(r, on=[@pl.col("k")], how=Left).height(), 14)
  assert_eq(l.join(r, on=[@pl.col("k")], how=Right).height(), 13)
  assert_eq(l.join(r, on=[@pl.col("k")], how=Full).height(), 15)
  assert_eq(l.join(r, on=[@pl.col("k")], how=Semi).height(), 3)
  assert_eq(l.join(r, on=[@pl.col("k")], how=Anti).height(), 2)
}

///|
test "join on a constant key: Semi and Anti never multiply the rows" {
  let l = ff_constant_key_frame(50000, "a")
  let r = ff_constant_key_frame(50000, "b")
  assert_eq(l.join(r, on=[@pl.col("k")], how=Semi).height(), 50000)
  assert_eq(l.join(r, on=[@pl.col("k")], how=Anti).height(), 0)
}

// ---------------------------------------------------------------------------
// unpivot and transpose check the size of the result
// ---------------------------------------------------------------------------

///|
/// 50000 rows and 50000 columns that share one buffer.
fn ff_wide_frame() -> @pl.DataFrame raise @pl.PolarsError {
  let n = 50000
  let s = @pl.Series::int32("c", Array::makei(n, i => i))
  @pl.DataFrame::new(Array::makei(n, i => s.rename("c\{i}")))
}

///|
test "unpivot refuses a result of more than 2147483647 rows" {
  expect_error(
    raises(() => ff_wide_frame().unpivot()),
    "ComputeError",
    "the unpivot would have more than 2147483647 rows (50000 x 50000)",
  )
}

///|
test "transpose refuses a result of more than 2147483647 cells" {
  expect_error(
    raises(() => ff_wide_frame().transpose()),
    "ComputeError",
    "the transpose would have more than 2147483647 cells (50000 x 50000)",
  )
}

// ---------------------------------------------------------------------------
// pivot: an empty-string `on` value names its column "" (as polars' pivot does)
// ---------------------------------------------------------------------------

///|
test "pivot names the column of an empty-string on value with the empty string" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L, 1L, 2L, 2L]),
    @pl.Series::str_nullable("s", [Some(""), Some("a"), Some(""), None]),
    @pl.Series::int64("v", [1L, 2L, 3L, 4L]),
  ])
  let out = df.pivot(["s"], index=["k"], values=["v"], aggregate_function=Sum)
  assert_eq(out.columns(), ["k", "", "a", "null"])
  assert_eq(out.column("").to_int64_array(), [Some(1L), Some(3L)])
  let sorted = df.pivot(
    ["s"],
    index=["k"],
    values=["v"],
    aggregate_function=Sum,
    sort_columns=true,
  )
  assert_eq(sorted.columns(), ["k", "null", "", "a"])
}

// ---------------------------------------------------------------------------
// to_date / to_datetime as a join key are not elementwise
// ---------------------------------------------------------------------------

///|
fn ff_join_sides() -> (@pl.DataFrame, @pl.DataFrame) raise @pl.PolarsError {
  let l = @pl.DataFrame::new([
    @pl.Series::str("s", ["2020-01-01", "2020-01-02"]),
    @pl.Series::int64("i", [1L, 2L]),
  ])
  let r = @pl.DataFrame::new([
    @pl.Series::date("d", [18262, 18263]),
    @pl.Series::int64("j", [1L, 2L]),
  ])
  (l, r)
}

///|
test "a to_date or to_datetime join key is refused as not elementwise, on either side, for every kind" {
  let (l, r) = ff_join_sides()
  let text = "all join key expressions must be elementwise."
  for how in [@pl.JoinHow::Inner, Left, Right, Full, Semi, Anti] {
    expect_error(
      raises(() => {
        l.join(
          r,
          left_on=[@pl.col("s").str().to_date()],
          right_on=[@pl.col("d")],
          how~,
        )
      }),
      "InvalidOperation",
      text,
    )
  }
  expect_error(
    raises(() => {
      r.join(l, left_on=[@pl.col("d")], right_on=[@pl.col("s").str().to_date()])
    }),
    "InvalidOperation",
    text,
  )
  // nested in another operation, and next to an elementwise key
  expect_error(
    raises(() => {
      l.join(r, left_on=[@pl.col("s").str().to_date().dt().year()], right_on=[
        @pl.col("j"),
      ])
    }),
    "InvalidOperation",
    text,
  )
  // a to_date of a column that is not text: the type is known, and matches
  expect_error(
    raises(() => {
      l.join(r, left_on=[@pl.col("i").str().to_date()], right_on=[@pl.col("d")])
    }),
    "InvalidOperation",
    text,
  )
}

///|
test "a to_date join key is compared by type first, then refused; other string functions are fine" {
  let (l, r) = ff_join_sides()
  expect_error(
    raises(() => {
      l.join(r, left_on=[@pl.col("s").str().to_date()], right_on=[@pl.col("j")])
    }),
    "SchemaMismatch",
    "datatypes of join keys don't match - `s`: date on left does not match `j`: i64 on right (and no other type was available to cast to)",
  )
  expect_error(
    raises(() => {
      l.join(r, left_on=[@pl.col("s").str().to_datetime()], right_on=[
        @pl.col("d"),
      ])
    }),
    "SchemaMismatch",
    "datatypes of join keys don't match - `s`: datetime[μs] on left does not match `d`: date on right (and no other type was available to cast to)",
  )
  // elementwise string functions stay accepted
  let out = l.join(
    @pl.DataFrame::new([@pl.Series::str("u", ["2020-01-01"])]),
    left_on=[@pl.col("s").str().to_uppercase()],
    right_on=[@pl.col("u")],
  )
  assert_eq(out.height(), 1)
}

// ---------------------------------------------------------------------------
// over inside agg: the partition must be elementwise
// ---------------------------------------------------------------------------

///|
fn ff_over_frame() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::int64("k", [1L, 1L, 2L, 2L, 3L]),
    @pl.Series::str("s", [
      "2020-01-01", "2020-01-02", "2020-01-01", "2020-01-01", "2020-01-03",
    ]),
    @pl.Series::int64("v", [1L, 2L, 3L, 4L, 5L]),
    @pl.Series::str("g", ["a", "b", "a", "b", "a"]),
  ])
}

///|
fn ff_agg_over(part : @pl.Expr) -> @pl.DataFrame raise @pl.PolarsError {
  ff_over_frame()
  .group_by([@pl.col("k")])
  .agg([@pl.col("v").sum().over([part]).first()])
}

///|
test "over inside agg: elementwise partitions work" {
  let sums = (p : @pl.Expr) => ff_agg_over(p).column("v").to_int64_array()
  assert_eq(sums(@pl.col("g")), [Some(1L), Some(3L), Some(5L)])
  assert_eq(sums(@pl.lit_int(1L)), [Some(3L), Some(7L), Some(5L)])
  assert_eq(sums(@pl.col("v") % @pl.lit_int(2L)), [Some(1L), Some(3L), Some(5L)])
  assert_eq(sums(@pl.col("s").str().to_uppercase()), [
    Some(1L),
    Some(7L),
    Some(5L),
  ])
  assert_eq(sums(@pl.col("g").is_in(@pl.Series::str("x", ["a"]))), [
    Some(1L),
    Some(3L),
    Some(5L),
  ])
}

///|
test "over inside agg: a partition that is not elementwise is InvalidOperation" {
  let text = "window expression with non-elementwise `partition_by` or `order_by` not allowed in aggregation context"
  for
    part in [
      @pl.col("s").str().to_date(),
      @pl.col("s").str().to_datetime(),
      @pl.col("s").str().to_date().dt().year(),
      @pl.col("v").cum_sum(),
      @pl.col("v").sort(),
      @pl.col("v").head(n=1),
      @pl.col("v").unique(),
      @pl.col("v").rank(),
      @pl.col("v").reverse(),
      @pl.col("v").sum(),
      @pl.col("v").n_unique(),
      @pl.len(),
      @pl.col("v").any(),
      @pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(0L))),
      @pl.col("v").sort_by([@pl.col("v")]),
    ] {
    expect_error(raises(() => ff_agg_over(part)), "InvalidOperation", text)
  }
  // in a larger expression, and as the second partition key
  expect_error(
    raises(() => {
      ff_over_frame()
      .group_by([@pl.col("k")])
      .agg([
        (@pl.col("v").sum().over([@pl.col("s").str().to_date()]) +
        @pl.lit_int(1L)).first(),
      ])
    }),
    "InvalidOperation",
    text,
  )
  expect_error(
    raises(() => {
      ff_over_frame()
      .group_by([@pl.col("k")])
      .agg([
        @pl.col("v").sum().over([@pl.col("g"), @pl.col("v").cum_sum()]).first(),
      ])
    }),
    "InvalidOperation",
    text,
  )
  // plain select and with_columns accept a to_date partition
  let out = ff_over_frame().select([
    @pl.col("v").sum().over([@pl.col("s").str().to_date()]),
  ])
  assert_eq(out.column("v").to_int64_array(), [
    Some(8L),
    Some(2L),
    Some(8L),
    Some(8L),
    Some(5L),
  ])
}

///|
test "over inside agg: the errors polars finds first still come first" {
  let bad = @pl.col("s").str().to_date()
  // a missing column, a duplicate output name and a type error are found before
  expect_error(
    raises(() => {
      ff_over_frame()
      .group_by([@pl.col("k")])
      .agg([@pl.col("v").sum().over([bad]).first(), @pl.col("zz").sum()])
    }),
    "ColumnNotFound",
    "unable to find column \"zz\"; valid columns: [\"k\", \"s\", \"v\", \"g\"]",
  )
  expect_error(
    raises(() => {
      ff_over_frame()
      .group_by([@pl.col("k")])
      .agg([
        @pl.col("v").sum().over([bad]).first(),
        @pl.col("v").sum().alias("w"),
        @pl.col("v").max().alias("w"),
      ])
    }),
    "DuplicateColumn",
    "column with name 'w' has more than one occurrence",
  )
  expect_error(
    raises(() => {
      ff_over_frame()
      .group_by([@pl.col("k")])
      .agg([@pl.col("v").sum().over([bad]).first(), @pl.col("g").sum()])
    }),
    "InvalidOperation",
    "`sum` operation not supported for dtype `str`",
  )
}

// ---------------------------------------------------------------------------
// sort_by of a scalar in a group of one row
// ---------------------------------------------------------------------------

///|
test "sort_by of a literal or an aggregate in a group of one row works" {
  let one = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L]),
    @pl.Series::int64("w", [3L]),
  ])
  let keys = [@pl.col("w")]
  let g = one.group_by([@pl.col("k")])
  let c = g.agg([@pl.lit_float(0.5).sort_by(keys).count()])
  assert_eq(c.columns(), ["k", "literal"])
  assert_eq(c.column("literal").to_int64_array(), [Some(1L)])
  let f = g.agg([@pl.lit_float(0.5).sort_by(keys).first()])
  assert_eq(f.column("literal").to_list(), [@pl.AnyValue::Float64(0.5)])
  let s = g.agg([@pl.col("w").sum().sort_by(keys).first()])
  assert_eq(s.column("w").to_int64_array(), [Some(3L)])
  let total = g.agg([@pl.col("w").sum().sort_by(keys).sum()])
  assert_eq(total.column("w").to_int64_array(), [Some(3L)])
  // a window of one row
  let o = one.select([
    @pl.lit_float(0.5).sort_by(keys).first().over([@pl.col("k")]),
  ])
  assert_eq(o.column("literal").to_list(), [@pl.AnyValue::Float64(0.5)])
}

///|
test "sort_by of a scalar by the rows of a group of several rows is still a ShapeMismatch" {
  let two = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L, 1L, 2L]),
    @pl.Series::int64("w", [3L, 4L, 5L]),
  ])
  let text = "expressions in 'sort_by' must have matching group lengths"
  expect_error(
    raises(() => {
      two
      .group_by([@pl.col("k")])
      .agg([@pl.col("w").sum().sort_by([@pl.col("w")]).first()])
    }),
    "ShapeMismatch",
    text,
  )
  // the one-row group alone is fine, the two-row group fails: the frame fails
  expect_error_kind(
    raises(() => {
      two
      .group_by([@pl.col("k")])
      .agg([@pl.lit_float(0.5).sort_by([@pl.col("w")]).count()])
    }),
    "ShapeMismatch",
  )
}

// ---------------------------------------------------------------------------
// between and when: aggregates in a group, one-row results in a select
// ---------------------------------------------------------------------------

///|
test "between with aggregate bounds in group_by takes the bounds of each group" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("k", [0L, 0L, 0L, 1L, 1L]),
    @pl.Series::int64("v", [1L, 2L, 3L, 10L, 11L]),
  ])
  let v = @pl.col("v")
  let lo = v.min() + @pl.lit_int(1L)
  let hi = v.max() - @pl.lit_int(1L)
  let out = df
    .group_by([@pl.col("k")])
    .agg([v.between(lo, hi).sum().alias("n")])
  assert_eq(out.column("n").to_int64_array(), [Some(1L), Some(0L)])
  // each of the three operands on its own
  let each = df
    .group_by([@pl.col("k")])
    .agg([
      v.between(lo, @pl.lit_int(100L)).sum().alias("lo_only"),
      v.between(@pl.lit_int(0L), hi).sum().alias("hi_only"),
      @pl.lit_int(2L).between(v.min(), v.max()).first().alias("scalar"),
    ])
  assert_eq(each.column("lo_only").to_int64_array(), [Some(2L), Some(1L)])
  assert_eq(each.column("hi_only").to_int64_array(), [Some(2L), Some(1L)])
  assert_eq(each.column("scalar").to_bool_array(), [Some(true), Some(false)])
}

///|
fn ff_a() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([@pl.Series::int64("a", [1L, 2L, 3L])])
}

///|
test "a one-row result that is not a scalar does not stretch through between" {
  let text = "Series t, length 1 doesn't match the DataFrame height of 3"
  let a = @pl.col("a")
  let one = a.head(n=1)
  let cases : Array[@pl.Expr] = [
    one.between(@pl.lit_int(1L), @pl.lit_int(3L)).alias("t"),
    @pl.lit_int(2L).between(one, @pl.lit_int(3L)).alias("t"),
    @pl.lit_int(2L).between(@pl.lit_int(1L), one).alias("t"),
  ]
  for e in cases {
    expect_error(raises(() => ff_a().select([e, a])), "ShapeMismatch", text)
  }
  // an aggregate is a scalar and stretches
  let ok = ff_a().select([
    a.sum().between(@pl.lit_int(1L), @pl.lit_int(3L)).alias("t"),
    a,
  ])
  assert_eq(ok.column("t").to_bool_array(), [
    Some(false),
    Some(false),
    Some(false),
  ])
}

///|
test "a one-row result that is not a scalar does not stretch through when" {
  let text = "Series t, length 1 doesn't match the DataFrame height of 3"
  let a = @pl.col("a")
  let one = a.head(n=1)
  let cases : Array[@pl.Expr] = [
    @pl.when(one.gt(@pl.lit_int(0L)))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(0L))
    .alias("t"),
    @pl.when(@pl.lit_bool(true)).then(one).otherwise(@pl.lit_int(0L)).alias("t"),
    @pl.when(@pl.lit_bool(true)).then(@pl.lit_int(1L)).otherwise(one).alias("t"),
  ]
  for e in cases {
    expect_error(raises(() => ff_a().select([e, a])), "ShapeMismatch", text)
  }
  // with_columns says InvalidOperation
  expect_error(
    raises(() => {
      ff_a().with_columns([
        one.between(@pl.lit_int(1L), @pl.lit_int(3L)).alias("t"),
      ])
    }),
    "InvalidOperation",
    text,
  )
  // aggregates stretch
  let ok = ff_a().select([
    @pl.when(a.sum().gt(@pl.lit_int(0L)))
    .then(a.sum())
    .otherwise(@pl.lit_int(0L))
    .alias("t"),
    a,
  ])
  assert_eq(ok.column("t").to_int64_array(), [Some(6L), Some(6L), Some(6L)])
}

// ---------------------------------------------------------------------------
// Time of day: white space after the colons
// ---------------------------------------------------------------------------

///|
test "to_datetime reads white space after a colon of the time, as polars does" {
  let t = 1704105000000000L // 2024-01-01 10:30:00
  let df = @pl.DataFrame::new([
    @pl.Series::str("s", [
      "2024-01-01T10: 30:00", "2024-01-01T10:30: 00", "2024-01-01T10:30:00", "2024-01-01 10: 30:00",
      "2024-01-01T10:30:00 ",
    ]),
  ])
  // lenient: the first three are times, the last two are null
  let lenient = df.select([@pl.col("s").str().to_datetime(strict=false)])
  assert_eq(lenient.column("s").to_list(), [
    @pl.AnyValue::Datetime(t),
    Datetime(t),
    Datetime(t),
    Null,
    Null,
  ])
  // strict: polars refuses the last two only
  expect_error(
    raises(() => df.select([@pl.col("s").str().to_datetime()])),
    "InvalidOperation",
    "conversion from `str` to `datetime[μs]` failed in column 's' for 2 out of 5 values: [\"2024-01-01 10: 30:00\", \"2024-01-01T10:30:00 \"]",
  )
  for text in ["2024-01-01T10: 30:00", "2024-01-01T10:30: 00"] {
    let one = @pl.DataFrame::new([@pl.Series::str("s", [text])])
    for strict in [true, false] {
      let out = one.select([@pl.col("s").str().to_datetime(strict~)])
      assert_eq(out.column("s").to_list(), [@pl.AnyValue::Datetime(t)])
    }
  }
}

// ---------------------------------------------------------------------------
// Show of the option enums
// ---------------------------------------------------------------------------

///|
test "the option enums print polars' names" {
  assert_eq(
    [@pl.PivotAgg::First, Last, Sum, Min, Max, Mean, Median, Len].map(x => {
      x.to_string()
    }),
    ["first", "last", "sum", "min", "max", "mean", "median", "len"],
  )
  assert_eq(
    [@pl.JoinValidation::ManyToMany, OneToMany, ManyToOne, OneToOne].map(x => {
      x.to_string()
    }),
    ["m:m", "1:m", "m:1", "1:1"],
  )
  assert_eq(
    [@pl.UniqueKeep::Any, First, Last, KeepNone].map(x => x.to_string()),
    ["any", "first", "last", "none"],
  )
  assert_eq(
    [@pl.ClosedInterval::Both, Left, Right, Neither].map(x => x.to_string()),
    ["both", "left", "right", "none"],
  )
  assert_eq(
    [@pl.ConcatHow::Vertical, VerticalRelaxed, Horizontal, Diagonal].map(x => {
      x.to_string()
    }),
    ["vertical", "vertical_relaxed", "horizontal", "diagonal"],
  )
  assert_eq(
    "\{@pl.PivotAgg::Median} \{@pl.JoinValidation::OneToOne}",
    "median 1:1",
  )
}

// ---------------------------------------------------------------------------
// plan_check keeps only the type errors polars raises before the names
// ---------------------------------------------------------------------------

///|
test "an error that is not a type resolution error does not come before a duplicate name" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("x", [1L, 2L]),
    @pl.Series::bool("f", [true, false]),
    @pl.Series::date("d", [18262, 18262]),
  ])
  // `f == d` has no common type (SchemaMismatch when the kernel runs, as
  // `SchemaError` in polars); the `&` makes the library evaluate the
  // expression early, and only plan time errors may escape that evaluation
  let e = (@pl.col("f").eq(@pl.col("d")) & @pl.lit_bool(true)).alias("x")
  expect_error_kind(
    raises(() => df.select([@pl.col("x"), e])),
    "DuplicateColumn",
  )
  expect_error_kind(raises(() => df.with_columns([e, e])), "DuplicateColumn")
  // without the duplicate the kernel's own error comes
  expect_error_kind(
    raises(() => df.select([@pl.col("x"), e.alias("y")])),
    "SchemaMismatch",
  )
}
