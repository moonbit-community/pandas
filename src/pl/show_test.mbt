///|
test "AnyValue show is the full value" {
  assert_eq(@pl.AnyValue::Null.to_string(), "null")
  assert_eq(@pl.AnyValue::Boolean(true).to_string(), "true")
  assert_eq(@pl.AnyValue::Boolean(false).to_string(), "false")
  assert_eq(@pl.AnyValue::Int32(-7).to_string(), "-7")
  assert_eq(
    @pl.AnyValue::Int64(@int64.MIN_VALUE).to_string(),
    "-9223372036854775808",
  )
  assert_eq(@pl.AnyValue::Float64(1.0).to_string(), "1.0")
  assert_eq(@pl.AnyValue::Float64(-0.0).to_string(), "-0.0")
  // shortest round-trip digits, not the six decimals of a table cell
  assert_eq(@pl.AnyValue::Float64(10.0 / 3.0).to_string(), "3.3333333333333335")
  assert_eq(@pl.AnyValue::Float64(1.0 / 3.0).to_string(), "0.3333333333333333")
  assert_eq(@pl.AnyValue::Float64(1234567.891).to_string(), "1234567.891")
  assert_eq(@pl.AnyValue::Float64(123456789.125).to_string(), "123456789.125")
  assert_eq(@pl.AnyValue::Float64(1.0e6).to_string(), "1000000.0")
  assert_eq(@pl.AnyValue::Float64(0.1 + 0.2).to_string(), "0.30000000000000004")
  assert_eq(@pl.AnyValue::Float64(1.5e16).to_string(), "1.5e+16")
  assert_eq(@pl.AnyValue::Float64(1.0e-6).to_string(), "1e-6")
  assert_eq(@pl.AnyValue::Float64(0.0 / 0.0).to_string(), "NaN")
  assert_eq(@pl.AnyValue::Float64(1.0 / 0.0).to_string(), "inf")
  assert_eq(@pl.AnyValue::Float64(-1.0 / 0.0).to_string(), "-inf")
  assert_eq(@pl.AnyValue::Float32(0.1).to_string(), "0.1")
  assert_eq(@pl.AnyValue::Float32(1234.5678).to_string(), "1234.5677")
  assert_eq(@pl.AnyValue::Float32(-0.0).to_string(), "-0.0")
  assert_eq(@pl.AnyValue::String("a\"q").to_string(), "a\"q")
  assert_eq(@pl.AnyValue::String("").to_string(), "")
  assert_eq(@pl.AnyValue::Date(0).to_string(), "1970-01-01")
  assert_eq(@pl.AnyValue::Date(-1).to_string(), "1969-12-31")
  assert_eq(
    @pl.AnyValue::Datetime(-1L).to_string(),
    "1969-12-31 23:59:59.999999",
  )
  assert_eq(@pl.AnyValue::Datetime(0L).to_string(), "1970-01-01 00:00:00")
  assert_eq(
    @pl.AnyValue::Datetime(1000L).to_string(),
    "1970-01-01 00:00:00.001",
  )
}

///|
test "AnyValue show does not cut long strings, a table does" {
  let s30 = "a".repeat(30)
  let s40 = "b".repeat(40)
  assert_eq(@pl.AnyValue::String(s30).to_string(), s30)
  assert_eq(@pl.AnyValue::String(s30 + "b").to_string(), s30 + "b")
  assert_eq(@pl.AnyValue::String(s40).to_string().length(), 40)
  assert_eq("\{@pl.AnyValue::String(s40)}", s40)
  inspect(@pl.AnyValue::String(s40), content=s40)
  // the table cut stays
  let df = @pl.DataFrame::new([@pl.Series::str("s", [s40])])
  assert_true(df.to_string().contains("b".repeat(30) + "…"))
  assert_false(df.to_string().contains(s40))
  // an aggregation result can be interpolated without losing digits
  let m = @pl.Series::float64("x", [1.0, 2.0, 7.0]).mean()
  assert_eq("mean=\{m}", "mean=3.3333333333333335")
}

///|
test "show never aborts on extreme dates and datetimes" {
  // beyond +-110 million days polars panics; a placeholder is printed
  assert_eq(
    @pl.AnyValue::Date(@int.MAX_VALUE).to_string(),
    "<out-of-range date>",
  )
  assert_eq(
    @pl.AnyValue::Date(@int.MIN_VALUE).to_string(),
    "<out-of-range date>",
  )
  assert_eq(@pl.AnyValue::Date(110_000_001).to_string(), "<out-of-range date>")
  assert_eq(@pl.AnyValue::Date(-110_000_001).to_string(), "<out-of-range date>")
  assert_true(
    @pl.AnyValue::Date(110_000_000).to_string() != "<out-of-range date>",
  )
  // every Int64 microsecond value prints
  assert_true(@pl.AnyValue::Datetime(@int64.MAX_VALUE).to_string().length() > 0)
  assert_true(@pl.AnyValue::Datetime(@int64.MIN_VALUE).to_string().length() > 0)
  let df = @pl.DataFrame::new([
    @pl.Series::date("d", [@int.MAX_VALUE, @int.MIN_VALUE, 0]),
    @pl.Series::datetime("t", [@int64.MAX_VALUE, @int64.MIN_VALUE, 0L]),
  ])
  assert_true(df.to_string().length() > 0)
  assert_true(df.get_columns()[0].to_string().length() > 0)
  assert_true(df.get_columns()[1].to_string().length() > 0)
}

///|
test "show non-ASCII strings does not abort" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("名", ["数据", "日本語", "é", "😀"]),
    @pl.Series::int32("n", [1, 2, 3, 4]),
  ])
  let text = df.to_string()
  assert_true(text.has_prefix("shape: (4, 2)\n"))
  assert_true(text.contains("数据"))
  assert_true(text.contains("😀"))
  assert_true(df.get_columns()[0].to_string().contains("\"数据\""))
}

///|
test "show empty frames and series" {
  assert_eq(
    @pl.DataFrame::empty().to_string(),
    "shape: (0, 0)\n┌┐\n╞╡\n└┘",
  )
  assert_eq(
    @pl.DataFrame::new([]).to_string(),
    @pl.DataFrame::empty().to_string(),
  )
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::str("b", ["x", "y"]),
  ])
  assert_eq(
    df.head(n=0).to_string(),
    (
      #|shape: (0, 2)
      #|┌─────┬─────┐
      #|│ a   ┆ b   │
      #|│ --- ┆ --- │
      #|│ i64 ┆ str │
      #|╞═════╪═════╡
      #|└─────┴─────┘
    ),
  )
  assert_eq(
    @pl.Series::str("s", []).to_string(),
    "shape: (0,)\nSeries: 's' [str]\n[\n]",
  )
  assert_eq(df.gather([]).to_string(), df.head(n=0).to_string())
}

///|
test "show small frame and series" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64_nullable("a", [Some(1L), None]),
    @pl.Series::str_nullable("b", [None, Some("x")]),
  ])
  assert_eq(
    df.to_string(),
    (
      #|shape: (2, 2)
      #|┌──────┬──────┐
      #|│ a    ┆ b    │
      #|│ ---  ┆ ---  │
      #|│ i64  ┆ str  │
      #|╞══════╪══════╡
      #|│ 1    ┆ null │
      #|│ null ┆ x    │
      #|└──────┴──────┘
    ),
  )
  assert_eq(
    df.column("b").to_string(),
    "shape: (2,)\nSeries: 'b' [str]\n[\n\tnull\n\t\"x\"\n]",
  )
}

///|
test "show folds long frames and series" {
  let n = @pl.Series::int64("n", Array::makei(12, i => i.to_int64()))
  let lines = @pl.DataFrame::new([n]).to_string().split("\n").collect()
  // shape, top, name, ---, dtype, header rule, 5 rows, ..., 5 rows, bottom
  assert_eq(lines.length(), 5 + 1 + 5 + 1 + 5 + 1)
  assert_eq("\{lines[11]}", "│ …   │")
  let sl = n.to_string().split("\n").collect()
  assert_eq(sl.length(), 3 + 5 + 1 + 5 + 1)
  assert_eq("\{sl[8]}", "\t…")
}

///|
test "show floats never aborts across the exponent range" {
  // sweep sign, exponent and a few mantissas of f64 and f32
  let mantissas : Array[Int64] = [
    0L, 1L, 0x5555555555555L, 0xfffffffffffffL, 0x8000000000000L,
  ]
  for sign in [0L, 1L] {
    for e in 0..<2048 {
      for m in mantissas {
        let bits = (sign << 63) | (e.to_int64() << 52) | m
        let x = bits.reinterpret_as_double()
        let text = @pl.AnyValue::Float64(x).to_string()
        assert_true(text.length() > 0)
        let f = Float::from_double(x)
        assert_true(@pl.AnyValue::Float32(f).to_string().length() > 0)
      }
    }
  }
}

///|
test "table float rounding carries into the next digit" {
  let t = (x : Double) => @pl.DataFrame::new([@pl.Series::float64("x", [x])])
  assert_true(t(9.99996e20).to_string().contains("1.0000e21"))
  assert_true(t(0.9999999999).to_string().contains("1.0"))
  assert_true(t(12345500000.0).to_string().contains("1.2346e10"))
  assert_true(t(12344500000.0).to_string().contains("1.2344e10"))
  // AnyValue::Float64 shows the full value instead
  assert_eq(@pl.AnyValue::Float64(9.99996e20).to_string(), "9.99996e+20")
  assert_eq(@pl.AnyValue::Float64(0.9999999999).to_string(), "0.9999999999")
  assert_eq(@pl.AnyValue::Float64(12345500000.0).to_string(), "12345500000.0")
}
