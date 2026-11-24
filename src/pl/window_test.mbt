///|
/// A frame of eight rows: `k` (a null group, groups of 3, 2, 1 and 2 rows),
/// `j`, `v`, `f` (NaN, null, -0.0), `u` (every group of `u` has one row). The
/// expected values below are what polars 2.1.0 gives.
fn win_df() -> @pl.DataFrame raise {
  let nan = 0.0 / 0.0
  @pl.DataFrame::new([
    @pl.Series::int64_nullable("k", [
      Some(1L),
      Some(1L),
      Some(2L),
      Some(1L),
      None,
      Some(2L),
      Some(3L),
      Some(3L),
    ]),
    @pl.Series::str_nullable("j", [
      Some("a"),
      Some("b"),
      Some("a"),
      Some("b"),
      Some("a"),
      None,
      Some("b"),
      Some("a"),
    ]),
    @pl.Series::int64("v", [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L]),
    @pl.Series::float64_nullable("f", [
      Some(1.0),
      Some(nan),
      None,
      Some(-0.0),
      Some(0.0),
      Some(2.5),
      Some(nan),
      Some(1.0),
    ]),
    @pl.Series::int64("u", [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L]),
  ])
}

///|
fn win_raises(
  f : () -> @pl.DataFrame raise @pl.PolarsError,
) -> @pl.PolarsError? {
  try {
    f() |> ignore
    None
  } catch {
    e => Some(e)
  }
}

///|
fn win_ints(df : @pl.DataFrame, name : String) -> Array[Int64?] raise {
  df.column(name).to_int64_array()
}

///|
test "an aggregation over a partition is repeated on every row of it" {
  let df = win_df()
  let out = df.select([@pl.col("v").sum().over([@pl.col("k")])])
  assert_eq(out.columns(), ["v"])
  assert_eq(win_ints(out, "v"), [
    Some(5L),
    Some(5L),
    Some(13L),
    Some(5L),
    Some(5L),
    Some(13L),
    Some(8L),
    Some(8L),
  ])
  // null is a partition of its own (the row with k = null is alone)
  let n = df.select([@pl.len().over([@pl.col("k")])])
  assert_eq(win_ints(n, "len"), [
    Some(3L),
    Some(3L),
    Some(2L),
    Some(3L),
    Some(1L),
    Some(2L),
    Some(2L),
    Some(2L),
  ])
}

///|
test "a sequence operation sees the rows of its partition in order" {
  let df = win_df()
  let out = df.select([
    @pl.col("v").cum_sum().over([@pl.col("k")]).alias("cs"),
    @pl.col("v").shift().over([@pl.col("k")]).alias("sh"),
    @pl.col("v").diff().over([@pl.col("k")]).alias("df"),
  ])
  assert_eq(win_ints(out, "cs"), [
    Some(3L),
    Some(4L),
    Some(4L),
    Some(5L),
    Some(5L),
    Some(13L),
    Some(2L),
    Some(8L),
  ])
  assert_eq(win_ints(out, "sh"), [
    None,
    Some(3L),
    None,
    Some(1L),
    None,
    Some(4L),
    None,
    Some(2L),
  ])
  assert_eq(win_ints(out, "df"), [
    None,
    Some(-2L),
    None,
    Some(0L),
    None,
    Some(5L),
    None,
    Some(4L),
  ])
}

///|
test "sort over a partition puts the sorted values back in the rows of the partition" {
  let df = win_df()
  let out = df.select([
    @pl.col("v").sort().over([@pl.col("k")]),
    @pl.col("v").sort(descending=true).over([@pl.col("k")]).alias("d"),
  ])
  assert_eq(win_ints(out, "v"), [
    Some(1L),
    Some(1L),
    Some(4L),
    Some(3L),
    Some(5L),
    Some(9L),
    Some(2L),
    Some(6L),
  ])
  assert_eq(win_ints(out, "d"), [
    Some(3L),
    Some(1L),
    Some(9L),
    Some(1L),
    Some(5L),
    Some(4L),
    Some(6L),
    Some(2L),
  ])
}

///|
test "an expression that mixes rows and aggregations is evaluated by partition" {
  let df = win_df()
  let out = df.select([
    (@pl.col("v") - @pl.col("v").mean()).over([@pl.col("k")]).alias("inside"),
    (@pl.col("v") - @pl.col("v").mean().over([@pl.col("k")])).alias("outside"),
  ])
  let a = out.column("inside").to_float64_array()
  let b = out.column("outside").to_float64_array()
  assert_eq(a, b)
  // k = 1 has the values 3, 1, 1: the mean is 5/3
  match a[1] {
    Some(x) => assert_true((x - (1.0 - 5.0 / 3.0)).abs() < 1.0e-12)
    None => fail("null")
  }
  // k = null is alone
  assert_eq(a[4], Some(0.0))
}

///|
test "a length that is not the length of the partition is a ShapeMismatch" {
  let df = win_df()
  let text = "the length of the window expression did not match that of the group"
  for
    e in [
      @pl.col("v").head(n=1),
      @pl.col("v").head(n=2),
      @pl.col("v").tail(n=1),
      @pl.col("v").unique(),
      @pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))),
    ] {
    match win_raises(() => df.select([e.over([@pl.col("k")])])) {
      Some(@pl.ShapeMismatch(m)) => assert_eq(m, text)
      _ => fail("expected ShapeMismatch")
    }
  }
  // a result as long as the partition (or a longer cut) is fine
  let ok = df.select([@pl.col("v").head(n=3).over([@pl.col("k")])])
  assert_eq(ok.column("v").to_int64_array(), df.column("v").to_int64_array())
  let ok2 = df.select([@pl.col("v").head(n=1).over([@pl.col("u")])])
  assert_eq(ok2.column("v").to_int64_array(), df.column("v").to_int64_array())
}

///|
test "over can be used by filter and sort" {
  let df = win_df()
  let kept = df.filter(
    @pl.col("v").gt(@pl.col("v").mean().over([@pl.col("k")])),
  )
  assert_eq(win_ints(kept, "v"), [Some(3L), Some(9L), Some(6L)])
  assert_eq(win_ints(kept, "k"), [Some(1L), Some(2L), Some(3L)])
  let sorted = df.sort([@pl.col("v").sum().over([@pl.col("k")]), @pl.col("u")])
  assert_eq(win_ints(sorted, "u"), [
    Some(0L),
    Some(1L),
    Some(3L),
    Some(4L),
    Some(6L),
    Some(7L),
    Some(2L),
    Some(5L),
  ])
}

///|
test "several partition keys and expression keys" {
  let df = win_df()
  let two = df.select([@pl.col("v").sum().over([@pl.col("k"), @pl.col("j")])])
  assert_eq(win_ints(two, "v"), [
    Some(3L),
    Some(2L),
    Some(4L),
    Some(2L),
    Some(5L),
    Some(9L),
    Some(2L),
    Some(6L),
  ])
  // an expression key, a literal key (one partition) and an aggregate key
  let odd = df.select([
    @pl.col("v").sum().over([@pl.col("v") % @pl.lit_int(2L)]).alias("odd"),
    @pl.col("v").sum().over([@pl.lit_int(1L)]).alias("all"),
    @pl.col("v").sum().over([@pl.col("v").sum()]).alias("agg"),
  ])
  assert_eq(win_ints(odd, "all"), [
    Some(31L),
    Some(31L),
    Some(31L),
    Some(31L),
    Some(31L),
    Some(31L),
    Some(31L),
    Some(31L),
  ])
  assert_eq(win_ints(odd, "agg"), win_ints(odd, "all"))
  assert_eq(win_ints(odd, "odd"), [
    Some(19L),
    Some(19L),
    Some(12L),
    Some(19L),
    Some(19L),
    Some(19L),
    Some(12L),
    Some(12L),
  ])
}

///|
test "a key of one row stretches, a key of another length does not" {
  let df = win_df()
  let one = df.select([@pl.col("v").sum().over([@pl.col("u").head(n=1)])])
  assert_eq(one.column("v").to_int64_array()[0], Some(31L))
  match
    win_raises(() => {
      df.select([@pl.col("v").sum().over([@pl.col("k").head(n=2)])])
    }) {
    Some(@pl.ShapeMismatch(m)) =>
      assert_eq(m, "can't broadcast Series 'k' of length 2 to length 8")
    _ => fail("expected ShapeMismatch")
  }
}

///|
test "no key is a ComputeError, except on a frame without rows" {
  let df = win_df()
  match win_raises(() => df.select([@pl.col("v").sum().over([])])) {
    Some(@pl.ComputeError(m)) =>
      assert_eq(m, "at least one key is required in a group_by operation")
    _ => fail("expected ComputeError")
  }
  let none = df.head(n=0).select([@pl.col("v").sum().over([])])
  assert_eq(none.shape(), (0, 1))
}

///|
test "a missing column is ColumnNotFound, in the expression or in the keys" {
  let df = win_df()
  for
    e in [
      @pl.col("zz").sum().over([@pl.col("k")]),
      @pl.col("v").sum().over([@pl.col("zz")]),
    ] {
    match win_raises(() => df.select([e])) {
      Some(@pl.ColumnNotFound(m)) =>
        assert_eq(
          m, "unable to find column \"zz\"; valid columns: [\"k\", \"j\", \"v\", \"f\", \"u\"]",
        )
      _ => fail("expected ColumnNotFound")
    }
  }
}

///|
test "a frame without rows keeps the types" {
  let df = win_df().head(n=0)
  let out = df.select([
    @pl.col("v").sum().over([@pl.col("k")]),
    @pl.col("v").cum_sum().over([@pl.col("k")]).alias("c"),
    @pl.col("j").sort().over([@pl.col("k")]).alias("s"),
    @pl.len().over([@pl.col("k")]).alias("n"),
    @pl.col("f").mean().over([@pl.col("k")]).alias("m"),
  ])
  assert_eq(out.shape(), (0, 5))
  assert_eq(out.dtypes(), [
    @pl.Int64,
    @pl.Int64,
    @pl.String,
    @pl.Int64,
    @pl.Float64,
  ])
}

///|
test "partitions by NaN, null and -0.0" {
  let df = win_df()
  // f = [1.0, NaN, null, -0.0, 0.0, 2.5, NaN, 1.0]: 1.0 twice, NaN twice,
  // -0.0 and 0.0 together
  let out = df.select([@pl.col("v").sum().over([@pl.col("f")])])
  assert_eq(win_ints(out, "v"), [
    Some(9L),
    Some(3L),
    Some(4L),
    Some(6L),
    Some(6L),
    Some(9L),
    Some(3L),
    Some(9L),
  ])
}

///|
test "over nested in over splits the partitions by both keys" {
  let df = win_df()
  let nested = df.select([
    @pl.col("v").sum().over([@pl.col("k")]).over([@pl.col("j")]),
  ])
  let two = df.select([@pl.col("v").sum().over([@pl.col("j"), @pl.col("k")])])
  assert_eq(win_ints(nested, "v"), win_ints(two, "v"))
}

///|
test "over inside an aggregation is the window of the group" {
  let df = win_df()
  // group_by j: the window of each group is partitioned by k inside it
  let out = df
    .group_by([@pl.col("j")])
    .agg([@pl.col("v").sum().over([@pl.col("k")]).first()])
  assert_eq(out.column("j").to_str_array(), [Some("a"), Some("b"), None])
  assert_eq(win_ints(out, "v"), [Some(3L), Some(2L), Some(9L)])
  let out2 = df
    .group_by([@pl.col("j")])
    .agg([@pl.col("v").cum_sum().over([@pl.col("k")]).last()])
  assert_eq(win_ints(out2, "v"), [Some(6L), Some(2L), Some(9L)])
  // on its own it is a list per group
  match
    win_raises(() => {
      df.group_by([@pl.col("j")]).agg([@pl.col("v").sum().over([@pl.col("k")])])
    }) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(
        m, "expression col(\"v\").sum().over([col(\"k\")]) does not reduce each group to one value; this library has no List type, so aggregate it (for example with first(), sum() or len())",
      )
    _ => fail("expected InvalidOperation")
  }
}

///|
test "the text of an expression with over is polars' text" {
  assert_eq(
    @pl.col("v").sum().over([@pl.col("k")]).to_string(),
    "col(\"v\").sum().over([col(\"k\")])",
  )
  assert_eq(
    @pl.col("v").sum().over([@pl.col("k"), @pl.col("j")]).to_string(),
    "col(\"v\").sum().over([col(\"k\"), col(\"j\")])",
  )
  assert_eq(
    @pl.col("v").sum().over([@pl.col("k") % @pl.lit_int(2L)]).to_string(),
    "col(\"v\").sum().over([[(col(\"k\")) % (dyn int: 2)]])",
  )
  assert_eq(
    @pl.col("v").sum().over([@pl.col("k")]).alias("z").to_string(),
    "col(\"v\").sum().over([col(\"k\")]).alias(\"z\")",
  )
}

///|
test "selectors in over expand like polars' do" {
  let df = win_df()
  let out = df.select([@pl.cols(["v", "u"]).sum().over([@pl.col("k")])])
  assert_eq(out.columns(), ["v", "u"])
  let both = df.select([@pl.cols(["v", "u"]).sum().over([@pl.cols(["k", "j"])])])
  assert_eq(both.columns(), ["v", "u"])
  // one expression, two keys that expand to two columns: two outputs of one name
  match
    win_raises(() => {
      df.select([@pl.col("v").sum().over([@pl.cols(["k", "j"])])])
    }) {
    Some(@pl.DuplicateColumn(_)) => ()
    _ => fail("expected DuplicateColumn")
  }
}

///|
test "a one-row frame and the tail of a partition" {
  let one = win_df().head(n=1)
  let out = one.select([
    @pl.col("v").sum().over([@pl.col("k")]),
    @pl.col("v").head(n=1).over([@pl.col("k")]).alias("h"),
    @pl.col("v").cum_sum().over([@pl.col("k")]).alias("c"),
  ])
  assert_eq(win_ints(out, "v"), [Some(3L)])
  assert_eq(win_ints(out, "h"), [Some(3L)])
  assert_eq(win_ints(out, "c"), [Some(3L)])
}

///|
test "an aggregate that divides the rows of a partition is a scalar (reciprocal)" {
  let df = win_df()
  // k = 1 has v = 3, 1, 1 (sum 5). polars divides a float column by a scalar
  // by multiplying with its reciprocal when the aggregate is inside the
  // window, and divides plainly when the sum is a column of its own
  let inside = df.select([
    (@pl.col("v") / @pl.col("v").sum()).over([@pl.col("k")]),
  ])
  let outside = df.select([
    @pl.col("v") / @pl.col("v").sum().over([@pl.col("k")]),
  ])
  let a = inside.column("v").to_float64_array()
  let b = outside.column("v").to_float64_array()
  assert_eq(a[0], Some(3.0 * (1.0 / 5.0)))
  assert_eq(b[0], Some(3.0 / 5.0))
  assert_true(a[0] != b[0])
  // k = 3 has v = 2, 6 (sum 8): the reciprocal of 8 is exact, both agree
  assert_eq(a[6], b[6])
}

///|
test "a window is not an elementwise join key" {
  let df = win_df()
  match
    win_raises(() => {
      df.join(df, left_on=[@pl.col("v").sum().over([@pl.col("k")])], right_on=[
        @pl.col("v"),
      ])
    }) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(m, "all join key expressions must be elementwise.")
    _ => fail("expected InvalidOperation")
  }
}

///|
test "sort_by of an aggregate by a column in a window is a ShapeMismatch" {
  let df = win_df()
  match
    win_raises(() => {
      df.select([
        @pl.col("v").sum().sort_by([@pl.col("u")]).over([@pl.col("k")]),
      ])
    }) {
    Some(@pl.ShapeMismatch(m)) =>
      assert_eq(m, "expressions in 'sort_by' must have matching group lengths")
    _ => fail("expected ShapeMismatch")
  }
  // a column sorted by an aggregate is fine (nothing to order)
  let ok = df.select([
    @pl.col("v").sort_by([@pl.col("v").sum()]).over([@pl.col("k")]),
  ])
  assert_eq(win_ints(ok, "v"), df.column("v").to_int64_array())
}

///|
test "when every partition is one row the length error has polars' other text" {
  let df = win_df()
  match
    win_raises(() => {
      df.select([
        @pl.col("v")
        .filter(@pl.col("v").gt(@pl.lit_int(4L)))
        .over([@pl.col("u")]),
      ])
    }) {
    Some(@pl.ShapeMismatch(m)) =>
      assert_eq(m, "expressions must have matching group lengths")
    _ => fail("expected ShapeMismatch")
  }
}

///|
test "a window in with_columns replaces or adds a column; a constant stays one partition" {
  let df = win_df()
  let out = df.with_columns([
    @pl.col("v").sum().over([@pl.col("k")]),
    @pl.col("v").cum_sum().over([@pl.col("j")]).alias("c"),
    @pl.lit_int(1L).over([@pl.col("k")]).alias("one"),
  ])
  assert_eq(out.columns(), ["k", "j", "v", "f", "u", "c", "one"])
  assert_eq(win_ints(out, "v"), [
    Some(5L),
    Some(5L),
    Some(13L),
    Some(5L),
    Some(5L),
    Some(13L),
    Some(8L),
    Some(8L),
  ])
  assert_eq(out.column("one").dtype(), @pl.Int64)
}

///|
test "the window of a mixed expression inside an aggregation is the group" {
  let df = win_df()
  // within group j = "a" (rows 0, 2, 4, 7: v = 3, 4, 5, 6; k = 1, 2, null, 3):
  // every k is alone, so v - mean(v) over k is 0 and its sum is 0
  let out = df
    .group_by([@pl.col("j")])
    .agg([(@pl.col("v") - @pl.col("v").mean().over([@pl.col("k")])).sum()])
  assert_eq(out.column("v").to_float64_array(), [
    Some(0.0),
    Some(0.0),
    Some(0.0),
  ])
}

///|
test "one partition of all the rows words the length error like partitions of one row" {
  let df = win_df()
  for key in [@pl.lit_int(1L), @pl.col("k").sum(), @pl.col("k").first()] {
    match win_raises(() => df.select([@pl.col("v").head(n=3).over([key])])) {
      Some(@pl.ShapeMismatch(m)) =>
        assert_eq(m, "expressions must have matching group lengths")
      _ => fail("expected ShapeMismatch")
    }
  }
  // several partitions of several rows: the other text
  match
    win_raises(() => df.select([@pl.col("v").head(n=3).over([@pl.col("j")])])) {
    Some(@pl.ShapeMismatch(m)) =>
      assert_eq(
        m, "the length of the window expression did not match that of the group",
      )
    _ => fail("expected ShapeMismatch")
  }
}

///|
test "a quotient of two aggregates is a plain quotient, also times a column" {
  // k = 1 (8 rows) has f = 0.1, 0.7, 0.3, 0.6, 1.1, 0.7, 0.3, 2.3. polars keeps
  // `max / sum` a scalar in the group, so only the product with the column
  // multiplies; the quotient is not multiplied by a reciprocal
  let df = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L]),
    @pl.Series::float64("f", [
      0.1, 0.7, 0.3, 0.6, 1.1, 0.7, 0.3, 2.3, 0.3, 0.9, 0.6, 2.1,
    ]),
  ])
  let f = @pl.col("f")
  let out = df.group_by([@pl.col("k")]).agg([(f.max() / f.sum() * f).last()])
  let got = out.column("f").to_float64_array()[0].unwrap()
  assert_eq(got.reinterpret_as_int64(), 4605986380866191144L)
  // in a window as well
  let w = df.select([(f.max() / f.sum() * f).over([@pl.col("k")])])
  let last = w.column("f").to_float64_array()[7].unwrap()
  assert_eq(last.reinterpret_as_int64(), 4605986380866191144L)
}
