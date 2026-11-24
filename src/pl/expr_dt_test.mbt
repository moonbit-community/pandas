///|
fn dt_df() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    // 1970-01-01, 2024-02-29, null, 1969-12-31, 2000-01-02
    @pl.Series::date_nullable("d", [
      Some(0),
      Some(19782),
      None,
      Some(-1),
      Some(10958),
    ]),
    // 1970-01-01 00:00:00, 2024-02-29 12:34:56.123456, null, 1969-12-31 23:59:59.999999, 1970-01-02 01:02:03
    @pl.Series::datetime_nullable("t", [
      Some(0L),
      Some(1709210096123456L),
      None,
      Some(-1L),
      Some(90123000000L),
    ]),
    @pl.Series::int32("i", [1, 2, 3, 4, 5]),
    @pl.Series::str("s", ["a", "b", "c", "d", "e"]),
    @pl.Series::null("n", 5),
  ])
}

///|
fn dt_out(e : @pl.Expr) -> @pl.Series raise @pl.PolarsError {
  dt_df().select([e]).get_columns()[0]
}

///|
test "dt(): calendar fields of a Date and a Datetime" {
  let d = @pl.col("d")
  let y = dt_out(d.dt().year())
  assert_eq(y.name(), "d")
  assert_eq(y.dtype(), @pl.DataType::Int32)
  assert_eq(y.to_int32_array(), [
    Some(1970),
    Some(2024),
    None,
    Some(1969),
    Some(2000),
  ])
  assert_eq(dt_out(d.dt().month()).to_int32_array(), [
    Some(1),
    Some(2),
    None,
    Some(12),
    Some(1),
  ])
  assert_eq(dt_out(d.dt().day()).to_int32_array(), [
    Some(1),
    Some(29),
    None,
    Some(31),
    Some(2),
  ])
  // ISO weekday: Monday is 1
  assert_eq(dt_out(d.dt().weekday()).to_int32_array(), [
    Some(4),
    Some(4),
    None,
    Some(3),
    Some(7),
  ])
  assert_eq(dt_out(d.dt().ordinal_day()).to_int32_array(), [
    Some(1),
    Some(60),
    None,
    Some(365),
    Some(2),
  ])
  let t = @pl.col("t")
  assert_eq(dt_out(t.dt().year()).to_int32_array(), [
    Some(1970),
    Some(2024),
    None,
    Some(1969),
    Some(1970),
  ])
  assert_eq(dt_out(t.dt().hour()).to_int32_array(), [
    Some(0),
    Some(12),
    None,
    Some(23),
    Some(1),
  ])
  assert_eq(dt_out(t.dt().minute()).to_int32_array(), [
    Some(0),
    Some(34),
    None,
    Some(59),
    Some(2),
  ])
  assert_eq(dt_out(t.dt().second()).to_int32_array(), [
    Some(0),
    Some(56),
    None,
    Some(59),
    Some(3),
  ])
  assert_eq(dt_out(t.dt().day()).to_int32_array(), [
    Some(1),
    Some(29),
    None,
    Some(31),
    Some(2),
  ])
}

///|
test "dt(): errors" {
  // a clock field of a Date, a calendar field of a number, a string, a Null
  assert_true(
    raises(() => dt_out(@pl.col("d").dt().hour()))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => dt_out(@pl.col("d").dt().second()))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => dt_out(@pl.col("i").dt().year()))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => dt_out(@pl.col("s").dt().month()))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => dt_out(@pl.col("n").dt().day()))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => dt_out(@pl.lit_int(1L).dt().year()))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => dt_out(@pl.col("zz").dt().year()))
    is Some(@pl.ColumnNotFound(_)),
  )
  // the first failing column of a selector
  assert_true(
    raises(() => dt_df().select([@pl.cols(["d", "s"]).dt().year()]))
    is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "dt(): show text" {
  let x = @pl.col("a")
  assert_eq(x.dt().year().to_string(), "col(\"a\").dt.year()")
  assert_eq(x.dt().month().to_string(), "col(\"a\").dt.month()")
  assert_eq(x.dt().day().to_string(), "col(\"a\").dt.day()")
  assert_eq(x.dt().weekday().to_string(), "col(\"a\").dt.weekday()")
  assert_eq(x.dt().ordinal_day().to_string(), "col(\"a\").dt.ordinal_day()")
  assert_eq(x.dt().hour().to_string(), "col(\"a\").dt.hour()")
  assert_eq(x.dt().minute().to_string(), "col(\"a\").dt.minute()")
  assert_eq(x.dt().second().to_string(), "col(\"a\").dt.second()")
}

///|
test "dt(): composition, names, literals and empty frames" {
  let df = dt_df()
  // arithmetic, a comparison and an aggregate of a field
  let y = df.select([@pl.col("d").dt().year() + @pl.lit_int(1L)])
  assert_eq(y.column("d").to_int32_array(), [
    Some(1971),
    Some(2025),
    None,
    Some(1970),
    Some(2001),
  ])
  let wk = df.select([@pl.col("d").dt().weekday().eq(@pl.lit_int(4L))])
  assert_eq(wk.column("d").to_bool_array(), [
    Some(true),
    Some(true),
    None,
    Some(false),
    Some(false),
  ])
  assert_eq(
    df.select([@pl.col("d").dt().year().max()]).column("d").to_int32_array(),
    [Some(2024)],
  )
  // names, alias, selectors
  let out = df.select([
    @pl.col("d").dt().year().alias("y"),
    @pl.col("t").dt().hour(),
  ])
  assert_eq(out.columns(), ["y", "t"])
  let sel = df.select([@pl.cols(["d", "t"]).dt().year()])
  assert_eq(sel.columns(), ["d", "t"])
  // duplicated names
  assert_true(
    raises(() => {
      df.select([@pl.col("d").dt().year(), @pl.col("d").dt().month()])
    })
    is Some(@pl.DuplicateColumn(_)),
  )
  // a Date literal gives one value, repeated next to a column
  let lit = df.select([
    @pl.col("i"),
    @pl.lit(@pl.AnyValue::Date(19782)).dt().year().alias("y"),
  ])
  assert_eq(lit.column("y").to_int32_array(), [
    Some(2024),
    Some(2024),
    Some(2024),
    Some(2024),
    Some(2024),
  ])
  // a field of a shifted column, as a filter
  let kept = df.filter(@pl.col("d").dt().year().ge(@pl.lit_int(2000L)))
  assert_eq(kept.column("i").to_int32_array(), [Some(2), Some(5)])
  // an empty frame
  let e = df
    .head(n=0)
    .select([@pl.col("d").dt().year(), @pl.col("t").dt().hour()])
  assert_eq(e.shape(), (0, 2))
  assert_eq(e.dtypes(), [@pl.DataType::Int32, Int32])
}

///|
test "dt() errors: weak literal type, first failing expression" {
  let df = dt_df()
  match raises(() => df.select([@pl.lit_int(1L).dt().year()])) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(m, "`year` operation not supported for dtype `i64`")
    _ => fail("expected InvalidOperation")
  }
  match
    raises(() => df.select([@pl.col("s").dt().year(), @pl.col("d").dt().hour()])) {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(m, "`year` operation not supported for dtype `str`")
    _ => fail("expected InvalidOperation")
  }
  // out of the supported calendar range a field is null, the weekday is not
  let far = @pl.DataFrame::new([@pl.Series::date("d", [95026237, -96465293])])
  let out = far.select([
    @pl.col("d").dt().year().alias("y"),
    @pl.col("d").dt().weekday().alias("w"),
  ])
  assert_eq(out.column("y").null_count(), 2)
  assert_eq(out.column("w").null_count(), 0)
}
