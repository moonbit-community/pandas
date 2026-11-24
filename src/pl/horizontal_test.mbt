///|
fn hz_df() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int64_nullable("a", [Some(1L), None, Some(3L), None]),
    @pl.Series::int32_nullable("b", [Some(10), Some(20), None, None]),
    @pl.Series::float64_nullable("f", [Some(0.5), Some(1.5), Some(2.5), None]),
    @pl.Series::str_nullable("s", [Some("x"), None, Some("z"), None]),
  ])
}

///|
test "sum_horizontal: nulls count as zero, the type is the supertype, the name is the first" {
  let out = hz_df().select([@pl.sum_horizontal([@pl.col("a"), @pl.col("b")])])
  assert_eq(out.columns(), ["a"])
  assert_eq(out.column("a").dtype(), @pl.DataType::Int64)
  assert_eq(out.column("a").to_int64_array(), [
    Some(11L),
    Some(20L),
    Some(3L),
    Some(0L),
  ])
  let mixed = hz_df().select([@pl.sum_horizontal([@pl.col("b"), @pl.col("f")])])
  assert_eq(mixed.column("b").dtype(), @pl.DataType::Float64)
  assert_eq(mixed.column("b").to_float64_array(), [
    Some(10.5),
    Some(21.5),
    Some(2.5),
    Some(0.0),
  ])
}

///|
test "sum_horizontal with ignore_nulls=false: a null makes the row null" {
  let out = hz_df().select([
    @pl.sum_horizontal([@pl.col("a"), @pl.col("b")], ignore_nulls=false),
  ])
  assert_eq(out.column("a").to_int64_array(), [Some(11L), None, None, None])
}

///|
test "min_horizontal and max_horizontal skip nulls; null only when all are null" {
  let df = hz_df()
  let lo = df.select([@pl.min_horizontal([@pl.col("a"), @pl.col("b")])])
  assert_eq(lo.column("a").to_int64_array(), [
    Some(1L),
    Some(20L),
    Some(3L),
    None,
  ])
  let hi = df.select([@pl.max_horizontal([@pl.col("a"), @pl.col("b")])])
  assert_eq(hi.column("a").to_int64_array(), [
    Some(10L),
    Some(20L),
    Some(3L),
    None,
  ])
}

///|
test "sum_horizontal of strings concatenates, min_horizontal of text and a number is an error" {
  let df = hz_df()
  let cat = df.select([@pl.sum_horizontal([@pl.col("s"), @pl.col("a")])])
  assert_eq(cat.column("s").to_str_array(), [
    Some("x1"),
    Some(""),
    Some("z3"),
    Some(""),
  ])
  assert_eq(
    shape_msg(() => {
      ignore(df.select([@pl.min_horizontal([@pl.col("s"), @pl.col("a")])]))
    }),
    "InvalidOperation: got invalid or ambiguous dtypes: '[str, i64]' in expression 'min_horizontal'",
  )
}

///|
test "horizontal functions: weak literals adapt, selectors are one expression, text" {
  let df = hz_df()
  let lit_out = df.select([@pl.sum_horizontal([@pl.col("b"), @pl.lit_int(1L)])])
  assert_eq(lit_out.column("b").dtype(), @pl.DataType::Int32)
  assert_eq(lit_out.column("b").to_int32_array(), [
    Some(11),
    Some(21),
    Some(1),
    Some(1),
  ])
  let sel = df.select([@pl.sum_horizontal([@pl.cols(["a", "b"])])])
  assert_eq(sel.shape(), (4, 1))
  assert_eq(sel.columns(), ["a"])
  assert_eq(
    @pl.sum_horizontal([@pl.col("a"), @pl.col("b")]).to_string(),
    "col(\"a\").sum_horizontal([col(\"b\")])",
  )
  assert_eq(
    @pl.min_horizontal([@pl.col("a")]).to_string(),
    "col(\"a\").min_horizontal()",
  )
}

///|
test "horizontal functions: lengths and no inputs" {
  let df = hz_df()
  assert_eq(
    shape_msg(() => {
      ignore(
        df.select([
          @pl.sum_horizontal([@pl.col("a").head(n=2), @pl.col("b").head(n=3)]),
        ]),
      )
    }),
    "ShapeMismatch: can't compute broadcast length, found incompatible lengths 3 (column 'b') and 2 (column 'a')",
  )
  assert_eq(
    shape_msg(() => ignore(df.select([@pl.sum_horizontal([])]))),
    "ComputeError: cannot return empty fold because the number of output rows is unknown",
  )
}

///|
test "Boolean min_horizontal is the AND, max_horizontal the OR of the row" {
  let df = @pl.DataFrame::new([
    @pl.Series::bool_nullable("x", [Some(true), Some(true), Some(false), None]),
    @pl.Series::bool_nullable("y", [
      Some(true),
      Some(false),
      Some(false),
      Some(true),
    ]),
  ])
  let lo = df.select([@pl.min_horizontal([@pl.col("x"), @pl.col("y")])])
  assert_eq(lo.column("x").to_bool_array(), [
    Some(true),
    Some(false),
    Some(false),
    Some(true),
  ])
  let hi = df.select([@pl.max_horizontal([@pl.col("x"), @pl.col("y")])])
  assert_eq(hi.column("x").to_bool_array(), [
    Some(true),
    Some(true),
    Some(false),
    Some(true),
  ])
}

///|
test "min_horizontal and max_horizontal of Float32: a tie goes to the later input (signed zero)" {
  let df = @pl.DataFrame::new([
    @pl.Series::float32("x", [0.0, -0.0, 1.0]),
    @pl.Series::float32("y", [-0.0, 0.0, 1.0]),
  ])
  for
    out in [
      df.select([@pl.min_horizontal([@pl.col("x"), @pl.col("y")])]),
      df.select([@pl.max_horizontal([@pl.col("x"), @pl.col("y")])]),
    ] {
    let v = out.column("x").to_float32_array()
    // 0.0 vs -0.0 gives -0.0 (the later), -0.0 vs 0.0 gives 0.0
    assert_eq(
      v[0].unwrap().reinterpret_as_int(),
      (-0.0 : Float).reinterpret_as_int(),
    )
    assert_eq(
      v[1].unwrap().reinterpret_as_int(),
      (0.0 : Float).reinterpret_as_int(),
    )
  }
  // Float64 too, and NaN loses against a number
  let d = @pl.DataFrame::new([
    @pl.Series::float64("x", [0.0, 0.0 / 0.0, 1.0]),
    @pl.Series::float64("y", [-0.0, 2.0, 0.0 / 0.0]),
  ])
  let m = d.select([@pl.min_horizontal([@pl.col("x"), @pl.col("y")])])
  let v = m.column("x").to_float64_array()
  assert_eq(v[0].unwrap().reinterpret_as_int64(), (-0.0).reinterpret_as_int64())
  assert_eq(v[1], Some(2.0))
  assert_eq(v[2], Some(1.0))
}

///|
test "min_horizontal and max_horizontal of text compare by code point, not UTF-16 unit" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("x", ["\u{FF61}", "\u{1F600}", "a"]),
    @pl.Series::str("y", ["\u{1F600}", "\u{FF61}", "b"]),
  ])
  let lo = df.select([@pl.min_horizontal([@pl.col("x"), @pl.col("y")])])
  assert_eq(lo.column("x").to_str_array(), [
    Some("\u{FF61}"),
    Some("\u{FF61}"),
    Some("a"),
  ])
  let hi = df.select([@pl.max_horizontal([@pl.col("x"), @pl.col("y")])])
  assert_eq(hi.column("x").to_str_array(), [
    Some("\u{1F600}"),
    Some("\u{1F600}"),
    Some("b"),
  ])
}
