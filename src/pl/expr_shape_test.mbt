///|
fn shape_df() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int64_nullable("a", [
      Some(3L),
      None,
      Some(1L),
      Some(2L),
      Some(3L),
    ]),
    @pl.Series::str_nullable("s", [
      Some("b"),
      None,
      Some("a"),
      Some("b"),
      Some("c"),
    ]),
    @pl.Series::bool_nullable("p", [
      Some(true),
      None,
      Some(false),
      Some(true),
      Some(true),
    ]),
    @pl.Series::int32("id", [0, 1, 2, 3, 4]),
  ])
}

///|
/// The text of the error `f` raises, or `no error`.
fn shape_msg(f : () -> Unit raise @pl.PolarsError) -> String {
  try {
    f()
    "no error"
  } catch {
    e => "\{e}"
  }
}

///|
fn shape_col(df : @pl.DataFrame, es : Array[@pl.Expr]) -> @pl.Series raise {
  df.select(es).get_columns()[0]
}

///|
test "filter then sum in a select gives one row" {
  let df = shape_df()
  let out = df.select([
    @pl.col("a").filter(@pl.col("a").gt(@pl.lit_int(1L))).sum(),
  ])
  assert_eq(out.shape(), (1, 1))
  assert_eq(out.column("a").to_list(), [@pl.AnyValue::Int64(8L)])
}

///|
test "filter keeps the rows where the predicate is true, a null predicate drops" {
  let df = shape_df()
  let s = shape_col(df, [@pl.col("id").filter(@pl.col("p"))])
  assert_eq(s.to_int32_array(), [Some(0), Some(3), Some(4)])
  assert_eq(s.name(), "id")
}

///|
test "filter raises polars' errors" {
  let df = shape_df()
  assert_eq(
    shape_msg(() => ignore(df.select([@pl.col("a").filter(@pl.col("a"))]))),
    "SchemaMismatch: invalid series dtype: expected `Boolean`, got `i64` for series with name `a`",
  )
  assert_eq(
    shape_msg(() => {
      ignore(df.select([@pl.col("a").filter(@pl.col("p").head(n=2))]))
    }),
    "ShapeMismatch: filter's length: 2 differs from that of the series: 5",
  )
}

///|
test "head, tail and slice" {
  let df = shape_df()
  assert_eq(shape_col(df, [@pl.col("id").head(n=2)]).to_int32_array(), [
    Some(0),
    Some(1),
  ])
  assert_eq(shape_col(df, [@pl.col("id").tail(n=2)]).to_int32_array(), [
    Some(3),
    Some(4),
  ])
  assert_eq(
    shape_col(df, [@pl.col("id").slice(-3, length=2)]).to_int32_array(),
    [Some(2), Some(3)],
  )
  assert_eq(shape_col(df, [@pl.col("id").slice(3)]).to_int32_array(), [
    Some(3),
    Some(4),
  ])
  // n larger than the column is clamped; the default is 10
  assert_eq(shape_col(df, [@pl.col("id").head()]).len(), 5)
  assert_eq(shape_col(df, [@pl.col("id").head(n=0)]).len(), 0)
}

///|
test "head and tail with a negative length are polars' error" {
  let df = shape_df()
  let m = shape_msg(() => ignore(df.select([@pl.col("id").head(n=-1)])))
  assert_true(
    m.has_prefix("ComputeError: unable to extract length from Scalar("),
  )
  let t = shape_msg(() => ignore(df.select([@pl.col("id").tail(n=-1)])))
  assert_eq(t, m)
}

///|
test "a result of another length next to a column is a shape error" {
  let df = shape_df()
  assert_eq(
    shape_msg(() => ignore(df.select([@pl.col("id").head(n=2), @pl.col("a")]))),
    "ShapeMismatch: Series length 2 doesn't match the DataFrame height of 5",
  )
  // a column cut to one row does not broadcast: only a literal or an
  // aggregate does
  assert_eq(
    shape_msg(() => ignore(df.select([@pl.col("id").head(n=1), @pl.col("a")]))),
    "ShapeMismatch: Series id, length 1 doesn't match the DataFrame height of 5",
  )
  let ok = df.select([@pl.col("id").head(n=1), @pl.col("a").sum()])
  assert_eq(ok.shape(), (1, 2))
  // with_columns: against the height of the frame
  assert_eq(
    shape_msg(() => {
      ignore(df.with_columns([@pl.col("id").head(n=2).alias("x")]))
    }),
    "ShapeMismatch: can't broadcast Series 'x' of length 2 to length 5",
  )
  assert_eq(
    shape_msg(() => {
      ignore(df.with_columns([@pl.col("id").head(n=1).alias("x")]))
    }),
    "InvalidOperation: Series x, length 1 doesn't match the DataFrame height of 5",
  )
}

///|
test "sort and arg_sort keep the name; arg_sort is an Int64" {
  let df = shape_df()
  let s = shape_col(df, [@pl.col("a").sort(descending=true, nulls_last=true)])
  assert_eq(s.to_int64_array(), [Some(3L), Some(3L), Some(2L), Some(1L), None])
  let i = shape_col(df, [@pl.col("a").arg_sort()])
  assert_eq(i.name(), "a")
  assert_eq(i.dtype(), @pl.DataType::Int64)
  assert_eq(i.to_int64_array(), [
    Some(1L),
    Some(2L),
    Some(3L),
    Some(0L),
    Some(4L),
  ])
}

///|
test "sort of a single value stays a single value that broadcasts" {
  let df = shape_df()
  let out = df.select([@pl.col("a").sum().sort(), @pl.col("id")])
  assert_eq(out.height(), 5)
  assert_eq(out.column("a").to_list()[4], @pl.AnyValue::Int64(9L))
}

///|
test "sort_by: several keys, descending per key, ties keep their order" {
  let df = shape_df()
  let s = shape_col(df, [
    @pl.col("id").sort_by([@pl.col("s"), @pl.col("a")], descending=[true, false]),
  ])
  // s descending (null first): null(1), c(4), b(a=2: 3, a=3: 0), a(2)
  assert_eq(s.to_int32_array(), [Some(1), Some(4), Some(3), Some(0), Some(2)])
  // a key of length 1 changes nothing
  let t = shape_col(df, [@pl.col("id").sort_by([@pl.lit_int(1L)])])
  assert_eq(t.to_int32_array(), [Some(0), Some(1), Some(2), Some(3), Some(4)])
  // no keys: unchanged
  let u = shape_col(df, [@pl.col("id").sort_by([])])
  assert_eq(u.to_int32_array(), [Some(0), Some(1), Some(2), Some(3), Some(4)])
}

///|
test "sort_by: wrong lengths" {
  let df = shape_df()
  assert_eq(
    shape_msg(() => {
      ignore(
        df.select([
          @pl.col("id").sort_by([@pl.col("s"), @pl.col("a")], descending=[true]),
        ]),
      )
    }),
    "InvalidOperation: the length of `descending` (1) does not match the length of `by` (2)",
  )
  assert_eq(
    shape_msg(() => {
      ignore(df.select([@pl.col("id").sort_by([@pl.col("a").head(n=3)])]))
    }),
    "ShapeMismatch: `sort_by` produced different length (3) than the Series that has to be sorted (5)",
  )
}

///|
test "unique, drop_nulls" {
  let df = shape_df()
  let u = shape_col(df, [@pl.col("a").unique(maintain_order=true)])
  assert_eq(u.to_int64_array(), [Some(3L), None, Some(1L), Some(2L)])
  let sorted = shape_col(df, [@pl.col("a").unique().sort()])
  assert_eq(sorted.to_int64_array(), [None, Some(1L), Some(2L), Some(3L)])
  let d = shape_col(df, [@pl.col("a").drop_nulls()])
  assert_eq(d.to_int64_array(), [Some(3L), Some(1L), Some(2L), Some(3L)])
  assert_eq(d.name(), "a")
}

///|
test "any and all: Kleene logic, numbers count as their truth value" {
  let df = @pl.DataFrame::new([
    @pl.Series::bool_nullable("t", [Some(true), None, Some(true)]),
    @pl.Series::bool_nullable("f", [Some(false), None, Some(false)]),
    @pl.Series::int64("i", [0L, 1L, 2L]),
  ])
  let one = (e : @pl.Expr) => df.select([e]).get_columns()[0].to_list()[0]
  assert_eq(one(@pl.col("t").any()), @pl.AnyValue::Boolean(true))
  assert_eq(one(@pl.col("t").all()), @pl.AnyValue::Boolean(true))
  assert_eq(one(@pl.col("t").all(ignore_nulls=false)), @pl.AnyValue::Null)
  assert_eq(one(@pl.col("f").any()), @pl.AnyValue::Boolean(false))
  assert_eq(one(@pl.col("f").any(ignore_nulls=false)), @pl.AnyValue::Null)
  assert_eq(
    one(@pl.col("f").all(ignore_nulls=false)),
    @pl.AnyValue::Boolean(false),
  )
  assert_eq(one(@pl.col("i").any()), @pl.AnyValue::Boolean(true))
  assert_eq(one(@pl.col("i").all()), @pl.AnyValue::Boolean(false))
}

///|
test "to_string of the new expressions is polars' str(expr)" {
  let a = @pl.col("a")
  assert_eq(
    a.head(n=2).to_string(),
    "col(\"a\").slice(offset=dyn int: 0, length=dyn int: 2)",
  )
  assert_eq(
    a.tail(n=2).to_string(),
    "col(\"a\").slice(offset=dyn int: -2, length=dyn int: 2)",
  )
  assert_eq(
    a.slice(1).to_string(),
    "col(\"a\").slice(offset=dyn int: 1, length=null)",
  )
  assert_eq(a.sort().to_string(), "col(\"a\").sort(asc)")
  assert_eq(a.sort(descending=true).to_string(), "col(\"a\").sort(desc)")
  assert_eq(a.arg_sort().to_string(), "col(\"a\").arg_sort()")
  assert_eq(a.unique().to_string(), "col(\"a\").unique()")
  assert_eq(
    a.unique(maintain_order=true).to_string(),
    "col(\"a\").unique_stable()",
  )
  assert_eq(a.drop_nulls().to_string(), "col(\"a\").drop_nulls()")
  assert_eq(a.filter(@pl.col("b")).to_string(), "col(\"a\").filter(col(\"b\"))")
  assert_eq(a.any().to_string(), "col(\"a\").any_ignore_nulls()")
  assert_eq(a.any(ignore_nulls=false).to_string(), "col(\"a\").any()")
  assert_eq(a.all().to_string(), "col(\"a\").all_ignore_nulls()")
  assert_eq(a.sin().to_string(), "col(\"a\").sin()")
  assert_eq(
    a
    .sort_by([@pl.col("b"), @pl.col("c")], descending=[true, false])
    .to_string(),
    "col(\"a\").sort_by(by=[col(\"b\"), col(\"c\")], sort_option=SortMultipleOptions { descending: [true, false], nulls_last: [false, false], multithreaded: true, maintain_order: false, limit: None })",
  )
}

///|
test "an empty result next to a column or a cut of one row: height 0" {
  let df = shape_df()
  assert_eq(
    shape_msg(() => {
      ignore(df.select([@pl.col("a").head(n=0), @pl.col("id").head(n=1)]))
    }),
    "ShapeMismatch: Series id, length 1 doesn't match the DataFrame height of 0",
  )
  let one = df.head(n=1)
  assert_eq(
    shape_msg(() => ignore(one.select([@pl.col("a").head(n=0), @pl.col("id")]))),
    "ShapeMismatch: Series id, length 1 doesn't match the DataFrame height of 0",
  )
  assert_eq(
    shape_msg(() => {
      ignore(
        one.select([@pl.col("a").filter(@pl.lit_bool(false)), @pl.col("id")]),
      )
    }),
    "ShapeMismatch: Series id, length 1 doesn't match the DataFrame height of 0",
  )
  // a literal or an aggregate is repeated to no row
  let ok = one.select([@pl.col("a").head(n=0), @pl.lit_int(1L)])
  assert_eq(ok.shape(), (0, 2))
  let ok2 = one.select([@pl.col("a").head(n=0), @pl.col("id").sum().alias("t")])
  assert_eq(ok2.shape(), (0, 2))
}

///|
test "filter: an aggregate or a literal subject with a predicate of no rows" {
  let df = shape_df()
  let empty = df.head(n=0)
  let out = empty.select([@pl.col("id").sum().filter(@pl.col("p"))])
  assert_eq(out.shape(), (0, 1))
  assert_eq(out.columns(), ["id"])
  let out2 = df.select([@pl.col("id").head(n=1).filter(@pl.col("p").head(n=0))])
  assert_eq(out2.shape(), (0, 1))
  let out3 = df.select([@pl.col("id").sum().filter(@pl.col("p").head(n=0))])
  assert_eq(out3.shape(), (0, 1))
  let out4 = empty.select([
    @pl.col("id").sum().filter(@pl.col("p")).alias("x"),
    @pl.col("a"),
  ])
  assert_eq(out4.shape(), (0, 2))
}

///|
test "filter: `any` and `all` as the subject are not repeated" {
  let df = shape_df()
  assert_eq(
    shape_msg(() => ignore(df.select([@pl.col("p").any().filter(@pl.col("p"))]))),
    "ShapeMismatch: filter's length: 5 differs from that of the series: 1",
  )
  assert_eq(
    shape_msg(() => ignore(df.select([@pl.col("p").all().filter(@pl.col("p"))]))),
    "ShapeMismatch: filter's length: 5 differs from that of the series: 1",
  )
  // an aggregate is
  let s = shape_col(df, [@pl.col("id").sum().filter(@pl.col("p"))])
  assert_eq(s.len(), 3)
}

///|
test "sort_by: a column cut to one row is not a one-row key; a literal or aggregate is" {
  let df = shape_df()
  let msg = "ShapeMismatch: `sort_by` produced different length (1) than the Series that has to be sorted (5)"
  assert_eq(
    shape_msg(() => {
      ignore(df.select([@pl.col("id").sort_by([@pl.col("a").head(n=1)])]))
    }),
    msg,
  )
  assert_eq(
    shape_msg(() => {
      ignore(
        df.select([@pl.col("id").sort_by([@pl.col("a").drop_nulls().head(n=1)])]),
      )
    }),
    msg,
  )
  let a = shape_col(df, [@pl.col("id").sort_by([@pl.col("a").sum()])])
  assert_eq(a.to_int32_array(), [Some(0), Some(1), Some(2), Some(3), Some(4)])
  let b = shape_col(df, [@pl.col("id").sort_by([@pl.lit_int(1L)])])
  assert_eq(b.len(), 5)
}

///|
test "any and all of an empty String column are false and true; a non-empty one is an error" {
  let df = shape_df()
  let e = df
    .head(n=0)
    .select([@pl.col("s").any(), @pl.col("s").all().alias("al")])
  assert_eq(e.column("s").to_bool_array(), [Some(false)])
  assert_eq(e.column("al").to_bool_array(), [Some(true)])
  assert_eq(
    shape_msg(() => ignore(df.select([@pl.col("s").any()]))),
    "InvalidOperation: casting from Utf8View to Boolean not supported",
  )
}

///|
test "any and all: a negative number is true" {
  let df = @pl.DataFrame::new([
    @pl.Series::float32("x", [-0.5, -1.0]),
    @pl.Series::float64("y", [-0.5, 0.0]),
    @pl.Series::int32("z", [-3, 0]),
    @pl.Series::int64("w", [-7L, -1L]),
  ])
  let one = (e : @pl.Expr) => df.select([e]).get_columns()[0].to_bool_array()[0]
  assert_eq(one(@pl.col("x").any()), Some(true))
  assert_eq(one(@pl.col("x").all()), Some(true))
  assert_eq(one(@pl.col("y").any()), Some(true))
  assert_eq(one(@pl.col("y").all()), Some(false))
  assert_eq(one(@pl.col("z").any()), Some(true))
  assert_eq(one(@pl.col("z").all()), Some(false))
  assert_eq(one(@pl.col("w").all()), Some(true))
}

///|
/// The frame of `shape_df` (and more columns) as a slice at offset 2 of a
/// longer frame: every kernel must honour the array offset.
fn sliced_frames() -> (@pl.DataFrame, @pl.DataFrame) raise {
  let plain = @pl.DataFrame::new([
    @pl.Series::int64_nullable("a", [
      Some(3L),
      None,
      Some(1L),
      Some(2L),
      Some(3L),
    ]),
    @pl.Series::float64_nullable("f", [
      Some(2.5),
      Some(0.0 / 0.0),
      None,
      Some(-0.0),
      Some(0.0),
    ]),
    @pl.Series::float32_nullable("g", [
      Some(-0.5),
      None,
      Some(1.5),
      Some(0.0),
      Some(-1.0),
    ]),
    @pl.Series::str_nullable("s", [
      Some("b"),
      None,
      Some("\u{1F600}"),
      Some("\u{FF61}"),
      Some("b"),
    ]),
    @pl.Series::bool_nullable("p", [
      Some(true),
      None,
      Some(false),
      Some(true),
      Some(true),
    ]),
    @pl.Series::int32("id", [0, 1, 2, 3, 4]),
  ])
  let big = @pl.DataFrame::new([
    @pl.Series::int64_nullable("a", [
      Some(9L),
      Some(8L),
      Some(3L),
      None,
      Some(1L),
      Some(2L),
      Some(3L),
      Some(7L),
    ]),
    @pl.Series::float64_nullable("f", [
      Some(9.0),
      None,
      Some(2.5),
      Some(0.0 / 0.0),
      None,
      Some(-0.0),
      Some(0.0),
      Some(4.0),
    ]),
    @pl.Series::float32_nullable("g", [
      Some(9.0),
      Some(8.0),
      Some(-0.5),
      None,
      Some(1.5),
      Some(0.0),
      Some(-1.0),
      Some(7.0),
    ]),
    @pl.Series::str_nullable("s", [
      Some("z"),
      Some("y"),
      Some("b"),
      None,
      Some("\u{1F600}"),
      Some("\u{FF61}"),
      Some("b"),
      Some("x"),
    ]),
    @pl.Series::bool_nullable("p", [
      Some(false),
      Some(false),
      Some(true),
      None,
      Some(false),
      Some(true),
      Some(true),
      None,
    ]),
    @pl.Series::int32("id", [90, 91, 0, 1, 2, 3, 4, 92]),
  ])
  (plain, big.slice(2, length=5))
}

///|
test "the new expressions give the same on a sliced frame (offset 2)" {
  let (plain, sliced) = sliced_frames()
  let c = @pl.col
  let exprs : Array[Array[@pl.Expr]] = [
    [c("a").sort(descending=true, nulls_last=true)],
    [c("s").sort()],
    [c("f").arg_sort()],
    [c("id").sort_by([c("s"), c("a")], descending=[true, false])],
    [c("a").unique(maintain_order=true)],
    [c("f").unique(maintain_order=true)],
    [c("s").drop_nulls()],
    [c("id").filter(c("p"))],
    [c("a").head(n=3)],
    [c("a").tail(n=2)],
    [c("g").slice(1, length=3)],
    [c("p").any(), c("p").all(ignore_nulls=false).alias("al")],
    [c("g").any(), c("g").all().alias("al")],
    [c("f").sin(), c("g").cos().alias("cg"), c("a").arctan().alias("aa")],
    [c("g").tan().alias("tg"), c("f").arcsin().alias("sf")],
    [@pl.sum_horizontal([c("a"), c("id")])],
    [@pl.sum_horizontal([c("s"), c("a")]).alias("ss")],
    [@pl.min_horizontal([c("f"), c("g")]).alias("mf")],
    [@pl.max_horizontal([c("p"), c("p").not_()]).alias("mp")],
    [@pl.min_horizontal([c("s"), c("s").sort()]).alias("ms")],
    [@pl.sum_horizontal([c("a"), c("f")], ignore_nulls=false).alias("sk")],
  ]
  for es in exprs {
    let x = plain.select(es)
    let y = sliced.select(es)
    assert_eq(x.shape(), y.shape())
    assert_eq(x.columns(), y.columns())
    let xs = x.get_columns()
    let ys = y.get_columns()
    for i in 0..<xs.length() {
      assert_eq(xs[i].dtype(), ys[i].dtype())
      assert_eq(
        @debug.to_string(xs[i].to_list()),
        @debug.to_string(ys[i].to_list()),
      )
    }
  }
}

///|
test "sort_by with several keys: a one-row key that is not a scalar does not stretch" {
  let df = shape_df()
  let msg = "ShapeMismatch: non-scalar expression produces broadcasting column"
  assert_eq(
    shape_msg(() => {
      ignore(
        df.select([
          @pl.col("id").sort_by([@pl.col("a"), @pl.col("a").head(n=1)]),
        ]),
      )
    }),
    msg,
  )
  assert_eq(
    shape_msg(() => {
      ignore(
        df.select([
          @pl.col("id").sort_by([@pl.col("a").head(n=1), @pl.col("a")]),
        ]),
      )
    }),
    msg,
  )
  assert_eq(
    shape_msg(() => {
      ignore(
        df.select([
          @pl.col("id")
          .head(n=0)
          .sort_by([@pl.col("a").head(n=1), @pl.col("a").head(n=0)]),
        ]),
      )
    }),
    msg,
  )
  // an aggregate or a literal next to a full key is fine
  let ok = shape_col(df, [
    @pl.col("id").sort_by([@pl.col("a"), @pl.col("id").sum(), @pl.lit_int(1L)]),
  ])
  assert_eq(ok.len(), 5)
}

///|
test "a sort_by of a column is not a scalar next to an empty result" {
  let one = shape_df().head(n=1)
  assert_eq(
    shape_msg(() => {
      ignore(
        one.select([
          @pl.col("a").head(n=0),
          @pl.col("id").sort_by([@pl.col("id")]),
        ]),
      )
    }),
    "ShapeMismatch: Series id, length 1 doesn't match the DataFrame height of 0",
  )
}
