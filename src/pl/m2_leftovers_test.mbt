///|
fn leftovers_dates() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::date("d", [1, 2, 3]),
    @pl.Series::date("e", [4, 5, 6]),
    @pl.Series::int32("a", [1, 2, 3]),
  ])
}

///|
test "Date - Date is not a plan time error: a later missing column or duplicate name comes first" {
  let df = leftovers_dates()
  let d = @pl.col("d")
  let e = @pl.col("e")
  assert_true(
    raises(() => df.select([d - e, @pl.col("zz")]))
    is Some(@pl.ColumnNotFound(_)),
  )
  assert_true(
    raises(() => df.select([d - e, @pl.col("a"), @pl.col("a")]))
    is Some(@pl.DuplicateColumn(_)),
  )
  assert_true(
    raises(() => df.with_columns([d - e, @pl.col("zz")]))
    is Some(@pl.ColumnNotFound(_)),
  )
  assert_true(
    raises(() => df.with_columns([d - e, @pl.col("a").alias("x"), @pl.col("x")]))
    is Some(@pl.ColumnNotFound(_)),
  )
  // the subtraction itself still fails when it runs
  assert_true(raises(() => df.select([d - e])) is Some(@pl.InvalidOperation(_)))
  // Datetime - Datetime the same
  let t = @pl.DataFrame::new([
    @pl.Series::datetime("t", [1L]),
    @pl.Series::datetime("u", [2L]),
  ])
  assert_true(
    raises(() => t.select([@pl.col("t") - @pl.col("u"), @pl.col("zz")]))
    is Some(@pl.ColumnNotFound(_)),
  )
  // the plan time errors that polars raises are still first
  assert_true(
    raises(() => df.select([d + e, @pl.col("zz")]))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => df.select([d * @pl.lit_int(2L), @pl.col("zz")]))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => df.select([d - @pl.lit_int(1L), @pl.col("zz")]))
    is Some(@pl.InvalidOperation(_)),
  )
}

///|
fn leftovers_frame() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::int32("a", [1, 2, 3]),
    @pl.Series::bool("g", [true, false, true]),
    @pl.Series::bool("h", [false, false, true]),
  ])
}

///|
test "filter folds an empty is_in anywhere in an & / | chain" {
  let df = leftovers_frame()
  let empty = @pl.Series::str("e", [])
  let i = @pl.col("a").is_in(empty)
  let g = @pl.col("g")
  let h = @pl.col("h")
  let gt0 = @pl.col("a").gt(@pl.lit_int(0L))
  // polars 2.1.0: `|` keeps the other side, `&` gives no row
  assert_eq(df.filter(i | g).height(), 2)
  assert_eq(df.filter(g | i).height(), 2)
  assert_eq(df.filter(i & gt0).height(), 0)
  assert_eq(df.filter(i & i).height(), 0)
  assert_eq(df.filter(i | g | h).height(), 2)
  assert_eq(df.filter((i & g) | h).height(), 1)
  assert_eq(df.filter(i | (i & g)).height(), 0)
  assert_eq(df.filter((i | g) & h).height(), 1)
  assert_eq(df.filter(g & (i | h)).height(), 1)
  assert_eq(df.filter(i.alias("q") | g).height(), 2)
  assert_eq(df.filter((i | g).alias("z")).height(), 2)
  assert_eq(df.filter(i).height(), 0)
  assert_eq(df.filter(i.alias("q")).height(), 0)
  // the rows that are kept
  assert_eq(df.filter(i | g).column("a").to_int32_array(), [Some(1), Some(3)])
  // anything else around the is_in still raises
  for
    bad in [
      i.not_(),
      i.eq(@pl.lit_bool(false)),
      i.is_null(),
      i.is_not_null(),
      i.neq(@pl.lit_bool(true)),
      i.not_() | g,
      (i | g).eq(@pl.lit_bool(true)),
      (i | g).not_(),
      @pl.when(i).then(g).otherwise(h),
    ] {
    match raises(() => df.filter(bad)) {
      Some(@pl.InvalidOperation(m)) =>
        assert_eq(
          m, "'is_in' cannot check for Int32 values in List(String) data",
        )
      _ => fail("expected InvalidOperation")
    }
  }
  // select and a non-empty set of another type raise as before
  assert_true(raises(() => df.select([i])) is Some(@pl.InvalidOperation(_)))
  assert_true(
    raises(() => df.filter(@pl.col("a").is_in(@pl.Series::str("e", ["x"])) | g))
    is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "DataFrame::column names the missing column like polars" {
  let df = leftovers_frame()
  match raises(() => df.column("zz")) {
    Some(@pl.ColumnNotFound(m)) => assert_eq(m, "\"zz\" not found")
    _ => fail("expected ColumnNotFound")
  }
  // a name with a quote or a backslash is escaped as Rust's Debug does
  match raises(() => df.column("a\"b\\c")) {
    Some(@pl.ColumnNotFound(m)) => assert_eq(m, "\"a\\\"b\\\\c\" not found")
    _ => fail("expected ColumnNotFound")
  }
}

///|
test "shift without n is shift(n=1)" {
  let s = @pl.Series::int32_nullable("a", [Some(1), None, Some(3), Some(4)])
  assert_true(s.shift().equals(s.shift(n=1)))
  assert_eq(s.shift().to_int32_array(), [None, Some(1), None, Some(3)])
  assert_eq(s.shift(fill_value=@pl.AnyValue::Int32(9)).to_int32_array(), [
    Some(9),
    Some(1),
    None,
    Some(3),
  ])
  assert_true(s.shift(n=2).equals(s.shift(n=2, fill_value=@pl.AnyValue::Null)))
  let df = @pl.DataFrame::new([s])
  let out = df.select([@pl.col("a").shift()])
  assert_eq(out.column("a").to_int32_array(), [None, Some(1), None, Some(3)])
  assert_eq(@pl.col("a").shift().to_string(), "col(\"a\").shift([dyn int: 1])")
  let filled = df.select([@pl.col("a").shift(fill_value=@pl.AnyValue::Int32(7))])
  assert_eq(filled.column("a").to_int32_array(), [
    Some(7),
    Some(1),
    None,
    Some(3),
  ])
}

///|
fn column_text(df : @pl.DataFrame, name : String) -> String {
  match raises(() => df.column(name)) {
    Some(@pl.ColumnNotFound(m)) => m
    _ => "no ColumnNotFound"
  }
}

///|
test "DataFrame::column escapes a name as Rust's Debug does (polars' get_column text)" {
  let df = leftovers_frame()
  // control characters, `\0`, DEL, no-break space, zero-width and combining
  // characters, format characters, tag characters (every one `\u{..}`)
  assert_eq(column_text(df, "a\u{1}"), "\"a\\u{1}\" not found")
  assert_eq(column_text(df, "\u{0}"), "\"\\0\" not found")
  assert_eq(column_text(df, "\u{7f}"), "\"\\u{7f}\" not found")
  assert_eq(column_text(df, "\u{1b}"), "\"\\u{1b}\" not found")
  assert_eq(column_text(df, "\u{a0}"), "\"\\u{a0}\" not found")
  assert_eq(column_text(df, "\u{200b}"), "\"\\u{200b}\" not found")
  assert_eq(column_text(df, "a\u{301}"), "\"a\\u{301}\" not found")
  assert_eq(column_text(df, "\u{ad}"), "\"\\u{ad}\" not found")
  assert_eq(column_text(df, "\u{85}"), "\"\\u{85}\" not found")
  assert_eq(column_text(df, "\u{2028}"), "\"\\u{2028}\" not found")
  assert_eq(column_text(df, "\u{feff}"), "\"\\u{feff}\" not found")
  assert_eq(column_text(df, "\u{61c}"), "\"\\u{61c}\" not found")
  assert_eq(column_text(df, "\u{2066}"), "\"\\u{2066}\" not found")
  assert_eq(column_text(df, "\u{e0001}"), "\"\\u{e0001}\" not found")
  // printable characters stay as they are, also beyond the BMP
  assert_eq(column_text(df, "é 日本"), "\"é 日本\" not found")
  assert_eq(column_text(df, "😀"), "\"😀\" not found")
  // the escapes with a letter: \n \r \t
  assert_eq(column_text(df, "a\n\r\tb"), "\"a\\n\\r\\tb\" not found")
}

///|
test "str().to_date() / to_datetime() are temporal for the plan time error check" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("s", ["2024-01-15", "2024-01-16"]),
    @pl.Series::int32("a", [1, 2]),
  ])
  for
    x in [
      @pl.col("s").str().to_date(strict=false),
      @pl.col("s").str().to_datetime(strict=false),
    ] {
    // arithmetic on the result is a type error found before a missing column
    // or a duplicate name (polars raises it while resolving the type)
    for
      y in [
        x + @pl.lit_int(1L),
        x * @pl.lit_int(2L),
        x % @pl.lit_int(2L),
        @pl.lit_int(1L) - x,
      ] {
      assert_true(
        raises(() => df.select([y, @pl.col("zz")]))
        is Some(@pl.InvalidOperation(_)),
      )
      assert_true(
        raises(() => df.select([y, @pl.col("a"), @pl.col("a")]))
        is Some(@pl.InvalidOperation(_)),
      )
    }
    // the same value used on its own is fine
    assert_eq(df.select([x]).height(), 2)
  }
}

///|
test "Datetime, a Datetime literal, a cast to Datetime and % are temporal arithmetic" {
  let df = @pl.DataFrame::new([
    @pl.Series::datetime("t", [1L, 2L, 3L]),
    @pl.Series::date("d", [1, 2, 3]),
    @pl.Series::int32("a", [1, 2, 3]),
  ])
  let zz = @pl.col("zz")
  // % on a Date column
  assert_true(
    raises(() => df.select([@pl.col("d") % @pl.lit_int(2L), zz]))
    is Some(@pl.InvalidOperation(_)),
  )
  // a Datetime column
  assert_true(
    raises(() => df.select([@pl.col("t") * @pl.lit_int(2L), zz]))
    is Some(@pl.InvalidOperation(_)),
  )
  // a Datetime literal
  assert_true(
    raises(() => {
      df.select([@pl.col("a") + @pl.lit(@pl.AnyValue::Datetime(1L)), zz])
    })
    is Some(@pl.InvalidOperation(_)),
  )
  // a cast to Datetime
  assert_true(
    raises(() => {
      df.select([@pl.col("a").cast(@pl.Datetime) * @pl.lit_int(2L), zz])
    })
    is Some(@pl.InvalidOperation(_)),
  )
}
