///|
/// The error `f` raises, `None` when it does not.
fn gb_raises(f : () -> @pl.DataFrame raise @pl.PolarsError) -> @pl.PolarsError? {
  try {
    f() |> ignore
    None
  } catch {
    e => Some(e)
  }
}

///|
fn gb_kv() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::str("k", ["b", "a", "b"]),
    @pl.Series::int64("v", [1L, 2L, 3L]),
  ])
}

///|
test "group_by keeps first appearance order" {
  let df = gb_kv()
  let out = df.group_by([@pl.col("k")]).agg([@pl.col("v").sum(), @pl.len()])
  assert_eq(out.columns(), ["k", "v", "len"])
  assert_eq(out.column("k").to_str_array(), [Some("b"), Some("a")])
  assert_eq(out.column("v").to_int64_array(), [Some(4L), Some(2L)])
  assert_eq(out.column("len").to_int64_array(), [Some(2L), Some(1L)])
}

///|
test "non-aggregated column in agg raises" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L]),
    @pl.Series::int64("b", [2L]),
  ])
  let r = gb_raises(() => df.group_by([@pl.col("k")]).agg([@pl.col("b")]))
  assert_true(r is Some(@pl.InvalidOperation(_)))
}

///|
test "the List message names the expression and says what to do" {
  let df = gb_kv()
  match gb_raises(() => df.group_by([@pl.col("k")]).agg([@pl.col("v")])) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(
        m, "expression col(\"v\") does not reduce each group to one value; this library has no List type, so aggregate it (for example with first(), sum() or len())",
      )
    _ => fail("expected InvalidOperation")
  }
  // the verdict is about the shape of the expression: a group of one row
  // is a list in polars too
  let one = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L]),
    @pl.Series::int64("b", [2L]),
  ])
  let r = gb_raises(() => {
    one.group_by([@pl.col("k")]).agg([@pl.col("b").cum_sum()])
  })
  assert_true(r is Some(@pl.InvalidOperation(_)))
  // a column next to an aggregation is still a list
  let r2 = gb_raises(() => {
    df.group_by([@pl.col("k")]).agg([@pl.col("v") + @pl.col("v").sum()])
  })
  assert_true(r2 is Some(@pl.InvalidOperation(_)))
}

///|
test "aggregations on aggregations and literals are one value per group" {
  let df = gb_kv()
  let out = df
    .group_by([@pl.col("k")])
    .agg([
      (@pl.col("v").sum() + @pl.lit_int(1L)).alias("plus"),
      (@pl.col("v").max() - @pl.col("v").min()).alias("range"),
      @pl.lit_int(7L).alias("seven"),
      @pl.col("v").sum().cum_sum().alias("cum"),
    ])
  assert_eq(out.columns(), ["k", "plus", "range", "seven", "cum"])
  assert_eq(out.column("plus").to_int64_array(), [Some(5L), Some(3L)])
  assert_eq(out.column("range").to_int64_array(), [Some(2L), Some(0L)])
  assert_eq(out.column("seven").to_int64_array(), [Some(7L), Some(7L)])
  assert_eq(out.column("cum").to_int64_array(), [Some(4L), Some(2L)])
}

///|
test "an expression under an aggregation is evaluated row by row" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("k", ["x", "y", "x", "y", "x"]),
    @pl.Series::int64("a", [1L, 2L, 3L, 4L, 5L]),
    @pl.Series::int64_nullable("b", [
      Some(10L),
      None,
      Some(30L),
      Some(40L),
      None,
    ]),
  ])
  let out = df
    .group_by([@pl.col("k")])
    .agg([
      (@pl.col("a") * @pl.col("a")).sum().alias("sq"),
      @pl.col("b").fill_null(@pl.lit_int(0L)).mean().alias("m"),
      @pl.when(@pl.col("a").gt(@pl.lit_int(2L)))
      .then(@pl.col("a"))
      .otherwise(@pl.lit_int(0L))
      .sum()
      .alias("big"),
    ])
  assert_eq(out.column("sq").to_int64_array(), [Some(35L), Some(20L)])
  assert_eq(out.column("m").to_float64_array(), [Some(40.0 / 3.0), Some(20.0)])
  assert_eq(out.column("big").to_int64_array(), [Some(8L), Some(4L)])
}

///|
test "an aggregation inside a group-wise expression sees the group" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("k", ["x", "y", "x", "y"]),
    @pl.Series::int64("a", [1L, 10L, 3L, 30L]),
  ])
  // sum of the distances to the group's first value
  let out = df
    .group_by([@pl.col("k")])
    .agg([(@pl.col("a") - @pl.col("a").first()).sum().alias("d")])
  assert_eq(out.column("d").to_int64_array(), [Some(2L), Some(20L)])
}

///|
test "len counts the rows of each group" {
  let df = gb_kv()
  let out = df.group_by([@pl.col("k")]).len()
  assert_eq(out.columns(), ["k", "len"])
  assert_eq(out.column("len").to_int64_array(), [Some(2L), Some(1L)])
  let named = df.group_by([@pl.col("k")]).len(name="n")
  assert_eq(named.columns(), ["k", "n"])
  // `len` as a key name is a duplicate
  let r = gb_raises(() => df.group_by([@pl.col("v").alias("len")]).len())
  assert_true(r is Some(@pl.DuplicateColumn(_)))
}

///|
test "pl.len() in select is the height of the frame" {
  let df = gb_kv()
  let out = df.select([@pl.len()])
  assert_eq(out.columns(), ["len"])
  assert_eq(out.column("len").to_int64_array(), [Some(3L)])
  assert_eq(@pl.len().to_string(), "len()")
}

///|
test "null is a key of its own, NaN is one key, -0.0 equals 0.0" {
  let nan = 0.0 / 0.0
  let df = @pl.DataFrame::new([
    @pl.Series::float64_nullable("k", [
      Some(0.0),
      None,
      Some(nan),
      Some(-0.0),
      None,
      Some(-nan),
    ]),
    @pl.Series::int64("v", [1L, 2L, 3L, 4L, 5L, 6L]),
  ])
  let out = df.group_by([@pl.col("k")]).agg([@pl.col("v").sum()])
  assert_eq(out.column("v").to_int64_array(), [Some(5L), Some(7L), Some(9L)])
  assert_eq(out.height(), 3)
}

///|
test "several keys, and a key that is an expression" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L, 4L, 5L, 6L]),
    @pl.Series::str("s", ["x", "y", "x", "y", "x", "x"]),
  ])
  let out = df
    .group_by([@pl.col("a") % @pl.lit_int(2L), @pl.col("s")])
    .agg([@pl.col("a").sum().alias("t")])
  assert_eq(out.columns(), ["a", "s", "t"])
  assert_eq(out.column("a").to_int64_array(), [Some(1L), Some(0L), Some(0L)])
  assert_eq(out.column("s").to_str_array(), [Some("x"), Some("y"), Some("x")])
  assert_eq(out.column("t").to_int64_array(), [Some(9L), Some(6L), Some(6L)])
}

///|
test "group_by with no key makes one group of every row" {
  let df = gb_kv()
  let out = df.group_by([]).agg([@pl.col("v").sum(), @pl.len()])
  assert_eq(out.columns(), ["v", "len"])
  assert_eq(out.column("v").to_int64_array(), [Some(6L)])
  assert_eq(out.column("len").to_int64_array(), [Some(3L)])
}

///|
test "a frame without rows" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("k", []),
    @pl.Series::int64("v", []),
  ])
  let out = df.group_by([@pl.col("k")]).agg([@pl.col("v").sum(), @pl.len()])
  assert_eq(out.shape(), (0, 3))
  assert_eq(out.dtypes(), [
    @pl.DataType::String,
    @pl.DataType::Int64,
    @pl.DataType::Int64,
  ])
  // no key: one group of no rows
  let one = df.group_by([]).agg([@pl.col("v").sum(), @pl.len()])
  assert_eq(one.height(), 1)
  assert_eq(one.column("len").to_int64_array(), [Some(0L)])
}

///|
test "weak literals adapt to the aggregate they meet" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("k", ["a", "a"]),
    @pl.Series::int32("v", [1, 2]),
  ])
  let out = df
    .group_by([@pl.col("k")])
    .agg([(@pl.col("v").sum() + @pl.lit_int(1L)).alias("n")])
  assert_eq(out.dtypes()[1], @pl.DataType::Int32)
}

///|
test "errors: missing columns, duplicate names, unsupported types" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("k", ["a", "b"]),
    @pl.Series::str("s", ["x", "y"]),
    @pl.Series::int64("v", [1L, 2L]),
  ])
  assert_true(
    gb_raises(() => df.group_by([@pl.col("z")]).agg([@pl.col("v").sum()]))
    is Some(@pl.ColumnNotFound(_)),
  )
  assert_true(
    gb_raises(() => df.group_by([@pl.col("k")]).agg([@pl.col("z").sum()]))
    is Some(@pl.ColumnNotFound(_)),
  )
  assert_true(
    gb_raises(() => {
      df.group_by([@pl.col("k"), @pl.col("k")]).agg([@pl.col("v").sum()])
    })
    is Some(@pl.DuplicateColumn(_)),
  )
  assert_true(
    gb_raises(() => {
      df.group_by([@pl.col("k")]).agg([@pl.col("v").sum(), @pl.col("v").mean()])
    })
    is Some(@pl.DuplicateColumn(_)),
  )
  assert_true(
    gb_raises(() => df.group_by([@pl.col("k")]).agg([@pl.col("s").sum()]))
    is Some(@pl.InvalidOperation(_)),
  )
  // a key's name is an output name too
  assert_true(
    gb_raises(() => df.group_by([@pl.col("k")]).agg([@pl.col("k").first()]))
    is Some(@pl.DuplicateColumn(_)),
  )
}

///|
test "all() in agg leaves the key columns out" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("k", ["a", "b", "a"]),
    @pl.Series::int64("x", [1L, 2L, 3L]),
    @pl.Series::int64("y", [10L, 20L, 30L]),
  ])
  let out = df.group_by([@pl.col("k")]).agg([@pl.all().sum()])
  assert_eq(out.columns(), ["k", "x", "y"])
  assert_eq(out.column("x").to_int64_array(), [Some(4L), Some(2L)])
  assert_eq(out.column("y").to_int64_array(), [Some(40L), Some(20L)])
}

///|
test "a quantile outside [0, 1] is a ComputeError" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("k", ["a", "a"]),
    @pl.Series::float64("x", [1.0, 2.0]),
  ])
  let r = gb_raises(() => {
    df.group_by([@pl.col("k")]).agg([@pl.col("x").quantile(1.5)])
  })
  assert_true(r is Some(@pl.ComputeError(_)))
}

///|
test "group_by on a frame is the same whatever maintain_order says" {
  let df = gb_kv()
  let a = df.group_by([@pl.col("k")], maintain_order=true).agg([@pl.len()])
  let b = df.group_by([@pl.col("k")], maintain_order=false).agg([@pl.len()])
  assert_true(a.equals(b))
}

///|
test "a column that has the name of a helper column works" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L, 1L, 2L, 2L, 2L]),
    @pl.Series::int64("group leaf 0", [1L, 2L, 3L, 4L, 5L]),
    @pl.Series::float64("group leaf 1", [0.5, 1.5, 2.5, 3.5, 4.5]),
    @pl.Series::str("group leaf_", ["a", "b", "c", "d", "e"]),
  ])
  let a = @pl.col("group leaf 0")
  let out = df
    .group_by([@pl.col("k")])
    .agg([
      (a * @pl.len()).sum().alias("p"),
      (@pl.col("group leaf 1") - a.mean()).sum().alias("q"),
      (a + @pl.len() + @pl.col("group leaf 1").max()).sum().alias("r"),
    ])
  assert_eq(out.column("p").to_int64_array(), [Some(6L), Some(36L)])
  assert_eq(out.column("q").to_float64_array(), [Some(-1.0), Some(-1.5)])
  assert_eq(out.column("r").to_float64_array(), [Some(10.0), Some(34.5)])
}

///|
test "an error names the column of the expression, not a helper" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L, 1L, 2L, 2L, 2L]),
    @pl.Series::int64("n", [1L, 2L, 3L, 4L, 5L]),
    @pl.Series::str("s", ["a", "b", "1", "2", "3"]),
  ])
  let want = "conversion from `str` to `i64` failed in column 's' for 1 out of 2 values: [\"a\"]"
  for
    e in [
      @pl.col("s").first().cast(@pl.DataType::Int64),
      @pl.col("s").first().cast(@pl.DataType::Int64) + @pl.col("n").last(),
    ] {
    match gb_raises(() => df.group_by([@pl.col("k")]).agg([e])) {
      Some(@pl.InvalidOperation(m)) => assert_eq(m, want)
      _ => fail("expected InvalidOperation")
    }
  }
  // inside an aggregation: the message counts the values of one group
  match
    gb_raises(() => {
      df
      .group_by([@pl.col("k")])
      .agg([
        (@pl.col("s").first().cast(@pl.DataType::Int64) * @pl.col("n")).sum(),
      ])
    }) {
    Some(@pl.InvalidOperation(m)) => {
      assert_true(
        m.has_prefix("conversion from `str` to `i64` failed in column 's'"),
      )
      assert_false(m.contains("group leaf"))
    }
    _ => fail("expected InvalidOperation")
  }
}

///|
test "the key of a group is the value of its first row" {
  let df = @pl.DataFrame::new([
    @pl.Series::float64("a", [-0.0, 0.0, 0.0, -0.0]),
    @pl.Series::float64("b", [0.0, -0.0, -0.0, 0.0]),
    @pl.Series::int64("v", [1L, 2L, 3L, 4L]),
  ])
  let out = df.group_by([@pl.col("a")]).agg([@pl.col("v").sum()])
  assert_eq(out.height(), 1)
  let k = out.column("a").to_float64_array()[0].unwrap()
  assert_true(k == 0.0 && k.reinterpret_as_int64() != 0L) // -0.0
  let out2 = df.group_by([@pl.col("b")]).agg([@pl.col("v").sum()])
  let k2 = out2.column("b").to_float64_array()[0].unwrap()
  assert_true(k2 == 0.0 && k2.reinterpret_as_int64() == 0L) // +0.0
  // the last row of the group is the other zero
  let tail = @pl.DataFrame::new([
    @pl.Series::float64("a", [0.0, -0.0]),
    @pl.Series::int64("v", [1L, 2L]),
  ])
  let k3 = tail
  .group_by([@pl.col("a")])
  .agg([@pl.col("v").sum()])
  .column("a")
  .to_float64_array()[0].unwrap()
  assert_eq(k3.reinterpret_as_int64(), 0L)
}

///|
test "aggregations of aggregations and of len() see one value per group" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("k", ["a", "a", "b", "a", "b"]),
    @pl.Series::int64("y", [1L, 2L, 3L, 4L, 5L]),
  ])
  let out = df
    .group_by([@pl.col("k")])
    .agg([
      (@pl.col("y").sum() + @pl.lit_int(1L)).sum().alias("s1"),
      (@pl.len() + @pl.lit_int(1L)).sum().alias("s2"),
      (@pl.len() + @pl.col("y")).mean().alias("m"),
      @pl.lit_int(5L).sum().alias("l"),
      (@pl.col("y").max() - @pl.col("y").min()).sum().alias("r"),
    ])
  // group a: y = [1, 2, 4], group b: y = [3, 5]
  assert_eq(out.column("s1").to_int64_array(), [Some(8L), Some(9L)])
  assert_eq(out.column("s2").to_int64_array(), [Some(4L), Some(3L)])
  assert_eq(out.column("m").to_float64_array(), [Some(16.0 / 3.0), Some(6.0)])
  assert_eq(out.column("l").to_int64_array(), [Some(5L), Some(5L)])
  assert_eq(out.column("r").to_int64_array(), [Some(3L), Some(2L)])
}

///|
test "sums and means keep an infinity instead of turning into NaN" {
  let inf = 1.0 / 0.0
  let inf32 = Float::from_double(inf)
  let df = @pl.DataFrame::new([
    @pl.Series::int64("k", [0L, 0L, 0L, 1L, 1L, 2L, 2L, 2L, 3L, 3L]),
    @pl.Series::float64("x", [
      1.0,
      inf,
      2.0,
      1.0,
      -inf,
      1.0e308,
      1.0e308,
      -1.0e308,
      inf,
      -inf,
    ]),
    @pl.Series::float32("y", [
      1.0,
      inf32,
      2.0,
      1.0,
      -inf32,
      3.0e38,
      3.0e38,
      -3.0e38,
      inf32,
      -inf32,
    ]),
  ])
  let out = df
    .group_by([@pl.col("k")])
    .agg([
      @pl.col("x").sum().alias("xs"),
      @pl.col("x").mean().alias("xm"),
      @pl.col("y").sum().alias("ys"),
      (@pl.col("x") * @pl.lit_float(1.0)).sum().alias("xp"),
    ])
  let xs = out.column("xs").to_float64_array()
  assert_eq(xs[0], Some(inf))
  assert_eq(xs[1], Some(-inf))
  assert_eq(xs[2], Some(inf))
  assert_true(xs[3].unwrap().is_nan())
  let xm = out.column("xm").to_float64_array()
  assert_eq(xm[0], Some(inf))
  assert_eq(xm[1], Some(-inf))
  let ys = out.column("ys").cast(@pl.DataType::Float64).to_float64_array()
  assert_eq(ys[0], Some(inf))
  assert_eq(ys[1], Some(-inf))
  assert_eq(ys[2], Some(inf))
  assert_eq(out.column("xp").to_float64_array()[0], Some(inf))
}

///|
test "the error raised with several wrong expressions follows polars" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L]),
    @pl.Series::int32("i", [1]),
    @pl.Series::bool("b", [true]),
    @pl.Series::str("s", ["x"]),
  ])
  let and_ = (@pl.col("i") & @pl.col("b")).sum()
  let unsupported = @pl.col("s").sum()
  // both are found when the types are resolved: the first expression wins
  assert_true(
    gb_raises(() => df.group_by([@pl.col("k")]).agg([and_, unsupported]))
    is Some(@pl.ComputeError(_)),
  )
  assert_true(
    gb_raises(() => df.group_by([@pl.col("k")]).agg([unsupported, and_]))
    is Some(@pl.InvalidOperation(_)),
  )
  // so does a key
  assert_true(
    gb_raises(() => {
      df.group_by([@pl.col("i") & @pl.col("b")]).agg([unsupported])
    })
    is Some(@pl.ComputeError(_)),
  )
  // a failure that only shows when a kernel runs comes after the others
  let add = (@pl.col("s") + @pl.lit_int(1L)).sum()
  match gb_raises(() => df.group_by([@pl.col("k")]).agg([add, unsupported])) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(m, "`sum` operation not supported for dtype `str`")
    _ => fail("expected InvalidOperation")
  }
}

///|
test "a List error comes before the errors of running the expressions" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L, 1L]),
    @pl.Series::int64("v", [1L, 2L]),
    @pl.Series::str("s", ["a", "b"]),
  ])
  let bad_cast = @pl.col("s").first().cast(@pl.DataType::Int64)
  match
    gb_raises(() => df.group_by([@pl.col("k")]).agg([bad_cast, @pl.col("v")])) {
    Some(@pl.InvalidOperation(m)) => assert_true(m.has_prefix("expression "))
    _ => fail("expected the List error")
  }
}

///|
test "user text that looks like a helper name is not altered in an error" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("k", [1L, 1L, 2L, 2L, 2L]),
    @pl.Series::str("wgroup leaf 0", ["x", "y", "3", "4", "5"]),
    @pl.Series::str("sv", ["group leaf 0", "1", "2", "3", "group leaf_ 0"]),
  ])
  let cast = (name : String) => @pl.col(name).cast(@pl.DataType::Int64)
  // a column name that contains a helper name
  match
    gb_raises(() => {
      df
      .group_by([@pl.col("k")])
      .agg([(cast("wgroup leaf 0") + @pl.len()).sum()])
    }) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(
        m, "conversion from `str` to `i64` failed in column 'wgroup leaf 0' for 2 out of 2 values: [\"x\", \"y\"]",
      )
    _ => fail("expected InvalidOperation")
  }
  // values that are a helper name
  match
    gb_raises(() => {
      df.group_by([@pl.col("k")]).agg([(cast("sv") + @pl.len()).sum()])
    }) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(
        m, "conversion from `str` to `i64` failed in column 'sv' for 1 out of 2 values: [\"group leaf 0\"]",
      )
    _ => fail("expected InvalidOperation")
  }
  match
    gb_raises(() => {
      df
      .group_by([@pl.col("k")])
      .agg([cast("sv").first() + @pl.col("k").first()])
    }) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(
        m, "conversion from `str` to `i64` failed in column 'sv' for 2 out of 5 values: [\"group leaf 0\", \"group leaf_ 0\"]",
      )
    _ => fail("expected InvalidOperation")
  }
}

///|
test "a key type error is raised before a missing column of an aggregation" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32("i", [1]),
    @pl.Series::bool("b", [true]),
    @pl.Series::str("s", ["x"]),
    @pl.Series::float64("f", [1.0]),
    @pl.Series::int64("n", [1L]),
  ])
  assert_true(
    gb_raises(() => {
      df.group_by([@pl.col("i") & @pl.col("b")]).agg([@pl.col("zz").sum()])
    })
    is Some(@pl.ComputeError(_)),
  )
  // a missing column in a key is still first
  assert_true(
    gb_raises(() => {
      df.group_by([@pl.col("zz"), @pl.col("i") & @pl.col("b")]).agg([@pl.len()])
    })
    is Some(@pl.ColumnNotFound(_)),
  )
  // product of text and `|` of a float and an integer fail when a kernel
  // runs: a type error found earlier in another expression wins
  assert_true(
    gb_raises(() => {
      df
      .group_by([@pl.col("n")])
      .agg([@pl.col("s").product(), (@pl.col("i") & @pl.col("b")).sum()])
    })
    is Some(@pl.ComputeError(_)),
  )
  match
    gb_raises(() => {
      df.group_by([@pl.col("f") | @pl.col("n")]).agg([@pl.col("s").sum()])
    }) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(m, "`sum` operation not supported for dtype `str`")
    _ => fail("expected InvalidOperation")
  }
}
