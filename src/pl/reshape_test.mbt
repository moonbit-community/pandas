///|
/// i, k, v, w: five rows, the cell (3, "b") is missing.
fn rs_long() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::int64("i", [1L, 1L, 2L, 2L, 3L]),
    @pl.Series::str("k", ["a", "b", "a", "b", "a"]),
    @pl.Series::int64("v", [10L, 20L, 30L, 40L, 50L]),
    @pl.Series::float64("w", [1.5, 2.5, 3.5, 4.5, 5.5]),
  ])
}

///|
/// Cell (1, "a") has two values, (1, "b") one, (2, "a") one.
fn rs_dup() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::int64("i", [1L, 1L, 1L, 2L]),
    @pl.Series::str("k", ["a", "a", "b", "a"]),
    @pl.Series::int64("v", [1L, 2L, 3L, 4L]),
    @pl.Series::float64("f", [1.0, 2.0, 3.0, 4.0]),
  ])
}

///|
test "pivot spreads the values of `on` into columns" {
  let out = rs_long().pivot(["k"], index=["i"], values=["v"])
  assert_eq(out.columns(), ["i", "a", "b"])
  assert_eq(out.column("i").to_int64_array(), [Some(1L), Some(2L), Some(3L)])
  assert_eq(out.column("a").to_int64_array(), [Some(10L), Some(30L), Some(50L)])
  assert_eq(out.column("b").to_int64_array(), [Some(20L), Some(40L), None])
}

///|
test "pivot without values takes every other column and prefixes the names" {
  let out = rs_long().pivot(["k"], index=["i"])
  assert_eq(out.columns(), ["i", "v_a", "v_b", "w_a", "w_b"])
  assert_eq(out.dtypes(), [
    @pl.DataType::Int64,
    @pl.DataType::Int64,
    @pl.DataType::Int64,
    @pl.DataType::Float64,
    @pl.DataType::Float64,
  ])
  let two = rs_long().pivot(
    ["k"],
    index=["i"],
    values=["v", "w"],
    separator="|",
  )
  assert_eq(two.columns(), ["i", "v|a", "v|b", "w|a", "w|b"])
}

///|
test "pivot without index takes every column that is neither on nor values" {
  let out = rs_long().pivot(["k"], values=["v"])
  assert_eq(out.columns(), ["i", "w", "a", "b"])
  assert_eq(out.height(), 5)
  assert_eq(out.column("a").to_int64_array(), [
    Some(10L),
    None,
    Some(30L),
    None,
    Some(50L),
  ])
  match raises(() => rs_long().pivot(["k"])) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(
        m, "`pivot` needs either `index or `values` needs to be specified",
      )
    _ => fail("expected InvalidOperation")
  }
}

///|
test "pivot with a repeated cell and no aggregate_function raises" {
  match raises(() => rs_dup().pivot(["k"], index=["i"], values=["v"])) {
    Some(@pl.ComputeError(m)) =>
      assert_eq(
        m, "aggregation 'item' expected no or a single value, got 2 values",
      )
    _ => fail("expected ComputeError")
  }
}

///|
test "pivot aggregate functions" {
  let df = rs_dup()
  let run = (agg : @pl.PivotAgg, col : String) => {
    df.pivot(["k"], index=["i"], values=[col], aggregate_function=agg)
  }
  assert_eq(run(First, "v").column("a").to_int64_array(), [Some(1L), Some(4L)])
  assert_eq(run(Last, "v").column("a").to_int64_array(), [Some(2L), Some(4L)])
  assert_eq(run(Sum, "v").column("a").to_int64_array(), [Some(3L), Some(4L)])
  assert_eq(run(Min, "v").column("a").to_int64_array(), [Some(1L), Some(4L)])
  assert_eq(run(Max, "v").column("a").to_int64_array(), [Some(2L), Some(4L)])
  assert_eq(run(Mean, "v").column("a").to_float64_array(), [
    Some(1.5),
    Some(4.0),
  ])
  assert_eq(run(Median, "v").column("a").to_float64_array(), [
    Some(1.5),
    Some(4.0),
  ])
  assert_eq(run(Len, "v").column("a").to_int64_array(), [Some(2L), Some(1L)])
  // a missing cell: the aggregation of no values (0 for a sum and a length,
  // null for the others)
  assert_eq(run(Sum, "v").column("b").to_int64_array(), [Some(3L), Some(0L)])
  assert_eq(run(Sum, "f").column("b").to_float64_array(), [Some(3.0), Some(0.0)])
  assert_eq(run(Len, "v").column("b").to_int64_array(), [Some(1L), Some(0L)])
  assert_eq(run(Max, "v").column("b").to_int64_array(), [Some(3L), None])
  assert_eq(run(Mean, "v").column("b").to_float64_array(), [Some(3.0), None])
  assert_eq(run(First, "v").column("b").to_int64_array(), [Some(3L), None])
  // a sum of text is not defined, as in group_by
  let s = @pl.DataFrame::new([
    @pl.Series::int64("i", [1L]),
    @pl.Series::str("k", ["a"]),
    @pl.Series::str("v", ["x"]),
  ])
  assert_true(
    raises(() => {
      s.pivot(["k"], index=["i"], values=["v"], aggregate_function=Sum)
    })
    is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "pivot sort_columns orders the new columns by value" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("i", [0L, 0L, 0L]),
    @pl.Series::int64_nullable("k", [Some(10L), Some(9L), None]),
    @pl.Series::int64("v", [1L, 2L, 3L]),
  ])
  assert_eq(df.pivot(["k"], index=["i"], values=["v"]).columns(), [
    "i", "10", "9", "null",
  ])
  assert_eq(
    df.pivot(["k"], index=["i"], values=["v"], sort_columns=true).columns(),
    ["i", "null", "9", "10"],
  )
}

///|
test "pivot names the columns after the keys" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("i", [0L, 0L, 0L, 0L]),
    @pl.Series::float64_nullable("a", [
      Some(1.5),
      Some(0.0 / 0.0),
      None,
      Some(-0.0),
    ]),
    @pl.Series::str("b", ["x", "y", "z", "w"]),
    @pl.Series::int64("v", [1L, 2L, 3L, 4L]),
  ])
  assert_eq(df.pivot(["a"], index=["i"], values=["v"]).columns(), [
    "i", "1.5", "NaN", "null", "-0.0",
  ])
  assert_eq(df.pivot(["a", "b"], index=["i"], values=["v"]).columns(), [
    "i", "{1.5,\"x\"}", "{NaN,\"y\"}", "null", "{-0.0,\"w\"}",
  ])
  let d = @pl.DataFrame::new([
    @pl.Series::int64("i", [0L, 0L]),
    @pl.Series::date("d", [19723, 0]),
    @pl.Series::datetime("t", [0L, 1_500_000L]),
    @pl.Series::bool("b", [true, false]),
    @pl.Series::int64("v", [1L, 2L]),
  ])
  assert_eq(d.pivot(["d"], index=["i"], values=["v"]).columns(), [
    "i", "2024-01-01", "1970-01-01",
  ])
  assert_eq(d.pivot(["t"], index=["i"], values=["v"]).columns(), [
    "i", "1970-01-01 00:00:00.000000", "1970-01-01 00:00:01.500000",
  ])
  assert_eq(d.pivot(["d", "t", "b"], index=["i"], values=["v"]).columns(), [
    "i", "{2024-01-01,1970-01-01 00:00:00,true}", "{1970-01-01,1970-01-01 00:00:01.500,false}",
  ])
}

///|
test "pivot with a null index key and a name clash" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64_nullable("i", [Some(1L), None, None]),
    @pl.Series::str("k", ["a", "a", "b"]),
    @pl.Series::int64("v", [1L, 2L, 3L]),
  ])
  let out = df.pivot(["k"], index=["i"], values=["v"])
  assert_eq(out.column("i").to_int64_array(), [Some(1L), None])
  assert_eq(out.column("a").to_int64_array(), [Some(1L), Some(2L)])
  assert_eq(out.column("b").to_int64_array(), [None, Some(3L)])
  // the value "i" of `on` clashes with the index column
  let c = @pl.DataFrame::new([
    @pl.Series::int64("i", [1L, 2L]),
    @pl.Series::str("k", ["i", "x"]),
    @pl.Series::int64("v", [1L, 2L]),
  ])
  match raises(() => c.pivot(["k"], index=["i"], values=["v"])) {
    Some(@pl.DuplicateColumn(m)) =>
      assert_eq(m, "column with name 'i' has more than one occurrence")
    _ => fail("expected DuplicateColumn")
  }
  // several value columns are prefixed, so no clash
  let c2 = c.with_columns([@pl.col("v").alias("w")])
  assert_eq(c2.pivot(["k"], index=["i"], values=["v", "w"]).columns(), [
    "i", "v_i", "v_x", "w_i", "w_x",
  ])
}

///|
test "pivot errors" {
  let df = rs_long()
  match raises(() => df.pivot(["zz"], index=["i"], values=["v"])) {
    Some(@pl.ColumnNotFound(m)) =>
      assert_eq(
        m, "unable to find column \"zz\"; valid columns: [\"i\", \"k\", \"v\", \"w\"]",
      )
    _ => fail("expected ColumnNotFound")
  }
  match raises(() => df.pivot(["k"], index=["yy"], values=["v"])) {
    Some(@pl.ColumnNotFound(m)) => assert_eq(m, "\"yy\" not found")
    _ => fail("expected ColumnNotFound")
  }
  match raises(() => df.pivot(["k"], index=["i"], values=["yy"])) {
    Some(@pl.ColumnNotFound(m)) => assert_eq(m, "\"yy\" not found")
    _ => fail("expected ColumnNotFound")
  }
  match raises(() => df.pivot([], index=["i"], values=["v"])) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(m, "`pivot` called without `on` columns.")
    _ => fail("expected InvalidOperation")
  }
  match raises(() => df.pivot(["k"], index=["i"], values=[])) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(m, "`pivot` called without `values` columns.")
    _ => fail("expected InvalidOperation")
  }
  match raises(() => df.pivot(["k", "k"], index=["i"], values=["v"])) {
    Some(@pl.DuplicateColumn(m)) =>
      assert_true(
        m.has_prefix("projections contained duplicate output name 'k'."),
      )
    _ => fail("expected DuplicateColumn")
  }
}

///|
test "pivot of an empty frame keeps only the index columns" {
  let e = rs_long().head(n=0)
  let out = e.pivot(["k"], index=["i"], values=["v"])
  assert_eq(out.shape(), (0, 1))
  assert_eq(out.columns(), ["i"])
  let none = e.pivot(["k"], values=["v"], index=[])
  assert_eq(none.shape(), (0, 0))
}

///|
test "pivot with an empty index is one row" {
  let out = rs_long().pivot(
    ["k"],
    index=[],
    values=["w"],
    aggregate_function=Sum,
  )
  assert_eq(out.shape(), (1, 2))
  assert_eq(out.column("a").to_float64_array(), [Some(10.5)])
  assert_eq(out.column("b").to_float64_array(), [Some(7.0)])
  // without an index and without the other columns
  let kv = rs_long().select([@pl.col("k"), @pl.col("v")])
  assert_true(
    raises(() => kv.pivot(["k"], values=["v"])) is Some(@pl.ComputeError(_)),
  )
  let s = kv.pivot(["k"], values=["v"], aggregate_function=Sum)
  assert_eq(s.columns(), ["a", "b"])
  assert_eq(s.column("a").to_int64_array(), [Some(90L)])
}

///|
test "pivot treats NaN, null and signed zero in the index as one key each" {
  let df = @pl.DataFrame::new([
    @pl.Series::float64_nullable("i", [
      Some(1.0),
      Some(0.0 / 0.0),
      None,
      Some(-0.0),
      Some(0.0),
      Some(0.0 / 0.0),
      None,
    ]),
    @pl.Series::str("k", ["a", "a", "a", "a", "a", "a", "a"]),
    @pl.Series::int64("v", [0L, 1L, 2L, 3L, 4L, 5L, 6L]),
  ])
  let out = df.pivot(["k"], index=["i"], values=["v"], aggregate_function=Sum)
  assert_eq(out.height(), 4)
  assert_eq(out.column("a").to_int64_array(), [
    Some(0L),
    Some(6L),
    Some(8L),
    Some(7L),
  ])
}

///|
test "unpivot stacks the columns" {
  let out = rs_long().unpivot(on=["v", "w"], index=["i", "k"])
  assert_eq(out.columns(), ["i", "k", "variable", "value"])
  assert_eq(out.height(), 10)
  assert_eq(out.dtypes()[3], @pl.DataType::Float64)
  assert_eq(out.column("variable").to_str_array()[4:6].to_owned(), [
    Some("v"),
    Some("w"),
  ])
  assert_eq(out.column("value").to_float64_array()[3:7].to_owned(), [
    Some(40.0),
    Some(50.0),
    Some(1.5),
    Some(2.5),
  ])
  assert_eq(out.column("i").to_int64_array()[5:7].to_owned(), [
    Some(1L),
    Some(1L),
  ])
  // on defaults to everything that is not an index column
  let d = rs_long().unpivot(index=["i", "k"])
  assert_true(d.equals(out))
  let o = rs_long().unpivot(
    on=["v"],
    index=["i"],
    variable_name="var",
    value_name="val",
  )
  assert_eq(o.columns(), ["i", "var", "val"])
  assert_eq(o.dtypes(), [
    @pl.DataType::Int64,
    @pl.DataType::String,
    @pl.DataType::Int64,
  ])
  let n = rs_long().unpivot(on=["v"])
  assert_eq(n.columns(), ["variable", "value"])
}

///|
test "unpivot takes the common type of the columns" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::str("b", ["x", "y"]),
  ])
  let out = df.unpivot()
  assert_eq(out.dtypes(), [@pl.DataType::String, @pl.DataType::String])
  assert_eq(out.column("value").to_str_array(), [
    Some("1"),
    Some("2"),
    Some("x"),
    Some("y"),
  ])
  let m = @pl.DataFrame::new([
    @pl.Series::int32("a", [1]),
    @pl.Series::float32("b", [1.5]),
    @pl.Series::bool("c", [true]),
  ])
  let mo = m.unpivot()
  assert_eq(mo.column("value").dtype(), @pl.DataType::Float64)
  assert_eq(mo.column("value").to_float64_array(), [
    Some(1.0),
    Some(1.5),
    Some(1.0),
  ])
}

///|
test "unpivot edge cases" {
  let df = rs_long()
  // nothing to unpivot: no rows, a Null value column
  let e = df.unpivot(on=[], index=["i"])
  assert_eq(e.shape(), (0, 3))
  assert_eq(e.dtypes()[2], @pl.DataType::Null)
  let all = df.unpivot(index=["i", "k", "v", "w"])
  assert_eq(all.shape(), (0, 6))
  // a frame without rows
  let z = df.head(n=0).unpivot(on=["v", "w"], index=["i"])
  assert_eq(z.shape(), (0, 3))
  assert_eq(z.dtypes()[2], @pl.DataType::Float64)
  // repeated names count once; a column may be both index and on
  assert_eq(df.unpivot(on=["v", "v"], index=["i", "i"]).height(), 5)
  assert_eq(df.unpivot(on=["v", "i"], index=["i"]).height(), 10)
  // errors
  match raises(() => df.unpivot(on=["zz"], index=["i"])) {
    Some(@pl.ColumnNotFound(m)) => assert_eq(m, "\"zz\" not found")
    _ => fail("expected ColumnNotFound")
  }
  match raises(() => df.unpivot(on=["v"], index=["yy"])) {
    Some(@pl.ColumnNotFound(m)) => assert_eq(m, "\"yy\" not found")
    _ => fail("expected ColumnNotFound")
  }
  match raises(() => df.unpivot(on=["v"], index=["k"], variable_name="k")) {
    Some(@pl.DuplicateColumn(m)) => assert_eq(m, "duplicate column name 'k'")
    _ => fail("expected DuplicateColumn")
  }
  match raises(() => df.unpivot(on=["v"], index=["i"], value_name="i")) {
    Some(@pl.DuplicateColumn(m)) => assert_eq(m, "duplicate column name 'i'")
    _ => fail("expected DuplicateColumn")
  }
  match raises(() => df.unpivot(on=["v"], variable_name="x", value_name="x")) {
    Some(@pl.DuplicateColumn(m)) => assert_eq(m, "duplicate column name 'x'")
    _ => fail("expected DuplicateColumn")
  }
}

///|
fn rs_abc() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L]),
    @pl.Series::int64("b", [4L, 5L, 6L]),
    @pl.Series::int64("c", [7L, 8L, 9L]),
  ])
}

///|
test "transpose swaps rows and columns" {
  let out = rs_abc().transpose()
  assert_eq(out.columns(), ["column_0", "column_1", "column_2"])
  assert_eq(out.column("column_0").to_int64_array(), [
    Some(1L),
    Some(4L),
    Some(7L),
  ])
  assert_eq(out.column("column_2").to_int64_array(), [
    Some(3L),
    Some(6L),
    Some(9L),
  ])
  let h = rs_abc().transpose(include_header=true)
  assert_eq(h.columns(), ["column", "column_0", "column_1", "column_2"])
  assert_eq(h.column("column").to_str_array(), [Some("a"), Some("b"), Some("c")])
  let hn = rs_abc().transpose(include_header=true, header_name="h")
  assert_eq(hn.columns()[0], "h")
  let cn = rs_abc().transpose(column_names=["x", "y", "z"])
  assert_eq(cn.columns(), ["x", "y", "z"])
}

///|
test "transpose takes the common type" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::float64_nullable("b", [Some(1.5), None]),
    @pl.Series::bool("c", [true, false]),
  ])
  let out = df.transpose(include_header=true)
  assert_eq(out.column("column_0").dtype(), @pl.DataType::Float64)
  assert_eq(out.column("column_0").to_float64_array(), [
    Some(1.0),
    Some(1.5),
    Some(1.0),
  ])
  assert_eq(out.column("column_1").to_float64_array(), [
    Some(2.0),
    None,
    Some(0.0),
  ])
  let i32 = @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2]),
    @pl.Series::int32("b", [3, 4]),
  ])
  assert_eq(i32.transpose().dtypes(), [@pl.DataType::Int32, @pl.DataType::Int32])
}

///|
test "transpose errors and empty frames" {
  match raises(() => rs_abc().transpose(column_names=["x", "y"])) {
    Some(@pl.ShapeMismatch(m)) =>
      assert_eq(
        m, "Length of new column names must be the same as the row count",
      )
    _ => fail("expected ShapeMismatch")
  }
  match raises(() => rs_abc().transpose(column_names=["x", "x", "z"])) {
    Some(@pl.DuplicateColumn(m)) =>
      assert_eq(
        m, "could not create a new DataFrame: column with name 'x' has more than one occurrence",
      )
    _ => fail("expected DuplicateColumn")
  }
  match
    raises(() => {
      rs_abc().transpose(include_header=true, column_names=["column", "y", "z"])
    }) {
    Some(@pl.DuplicateColumn(m)) =>
      assert_eq(m, "column is already in output column names")
    _ => fail("expected DuplicateColumn")
  }
  let none = @pl.DataFrame::empty()
  assert_eq(none.transpose().shape(), (0, 0))
  let nh = none.transpose(include_header=true)
  assert_eq(nh.columns(), ["column"])
  assert_eq(nh.shape(), (0, 1))
  assert_true(
    raises(() => none.transpose(column_names=["a"]))
    is Some(@pl.ShapeMismatch(_)),
  )
  // no rows: only the header column remains
  let z = rs_abc().head(n=0).transpose(include_header=true)
  assert_eq(z.columns(), ["column"])
  assert_eq(z.column("column").to_str_array(), [Some("a"), Some("b"), Some("c")])
}

///|
test "to_dict maps names to series in column order" {
  let d = rs_long().to_dict()
  assert_eq(d.length(), 4)
  let names : Array[String] = []
  for k, _ in d {
    names.push(k)
  }
  assert_eq(names, ["i", "k", "v", "w"])
  assert_eq(d["v"].to_int64_array(), [
    Some(10L),
    Some(20L),
    Some(30L),
    Some(40L),
    Some(50L),
  ])
  assert_eq(@pl.DataFrame::empty().to_dict().length(), 0)
}

///|
test "pivot, unpivot and transpose read sliced frames" {
  // rows 1..4 of the long frame: i = 1, 2, 2, 3 and k = b, a, b, a
  let s = rs_long().slice(1, length=4)
  let out = s.pivot(["k"], index=["i"], values=["v"])
  assert_eq(out.column("i").to_int64_array(), [Some(1L), Some(2L), Some(3L)])
  assert_eq(out.column("b").to_int64_array(), [Some(20L), Some(40L), None])
  assert_eq(out.column("a").to_int64_array(), [None, Some(30L), Some(50L)])
  let u = s.unpivot(on=["v"], index=["i"])
  assert_eq(u.column("value").to_int64_array(), [
    Some(20L),
    Some(30L),
    Some(40L),
    Some(50L),
  ])
  let t = s.select([@pl.col("v"), @pl.col("i")]).transpose()
  assert_eq(t.column("column_3").to_int64_array(), [Some(50L), Some(3L)])
  let vc = s.column("k").value_counts()
  assert_eq(vc.column("count").to_int64_array(), [Some(2L), Some(2L)])
}

///|
test "value_counts treats an empty name as not given" {
  let out = vc_x().value_counts(name="")
  assert_eq(out.columns(), ["x", "count"])
}

///|
test "unpivot refuses a variable or value name that is a column of the frame" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("i", [1L, 2L]),
    @pl.Series::int64("x", [3L, 4L]),
    @pl.Series::int64("y", [5L, 6L]),
    @pl.Series::int64("z", [7L, 8L]),
  ])
  fn dup(r : @pl.PolarsError?, name : String) -> Unit raise {
    match r {
      Some(@pl.DuplicateColumn(m)) =>
        assert_eq(m, "duplicate column name '\{name}'")
      _ => fail("expected DuplicateColumn for \{name}")
    }
  }

  // a column that is selected, an unselected one, an index column
  dup(raises(() => df.unpivot(on=["x"], index=["i"], variable_name="x")), "x")
  dup(raises(() => df.unpivot(on=["x"], index=["i"], value_name="x")), "x")
  dup(
    raises(() => df.unpivot(on=["x", "y"], index=["i"], variable_name="y")),
    "y",
  )
  dup(raises(() => df.unpivot(on=["x"], variable_name="i")), "i")
  dup(raises(() => df.unpivot(on=["x"], index=["z"], value_name="i")), "i")
  // the variable name is checked first
  dup(
    raises(() => {
      df.unpivot(on=["x"], index=["i"], variable_name="z", value_name="y")
    }),
    "z",
  )
  // a name that is not a column is fine; two equal names clash
  let ok = df.unpivot(on=["x"], index=["i"], variable_name="q")
  assert_eq(ok.columns(), ["i", "q", "value"])
  dup(
    raises(() => {
      df.unpivot(on=["x"], index=["i"], variable_name="q", value_name="q")
    }),
    "q",
  )
  // the default names clash too
  let v = @pl.DataFrame::new([
    @pl.Series::int64("id", [1L]),
    @pl.Series::int64("value", [2L]),
  ])
  dup(raises(() => v.unpivot(index=["id"])), "value")
  assert_eq(v.unpivot(index=["id"], value_name="v").columns(), [
    "id", "variable", "v",
  ])
  let both = @pl.DataFrame::new([
    @pl.Series::int64("variable", [1L]),
    @pl.Series::int64("value", [2L]),
  ])
  dup(raises(() => both.unpivot()), "variable")
}

///|
test "pivot refuses more cells than an Int32 can number" {
  // 70_000 index keys x 70_000 on keys would be 4.9e9 cells per value column
  let n = 70000
  let df = @pl.DataFrame::new([
    @pl.Series::int32("i", Array::makei(n, i => i)),
    @pl.Series::int32("k", Array::makei(n, i => i)),
    @pl.Series::int32("v", Array::makei(n, i => i)),
  ])
  match raises(() => df.pivot(["k"], index=["i"], values=["v"])) {
    Some(@pl.ComputeError(m)) =>
      assert_eq(
        m, "the pivot would have more than 2147483647 cells per value column (70000 x 70000)",
      )
    _ => fail("expected ComputeError")
  }
}
