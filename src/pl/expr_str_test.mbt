///|
fn str_df() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::str_nullable("s", [
      Some("  Hello  "),
      Some("abc"),
      None,
      Some(""),
      Some("x.y"),
      Some("\u{1F600}a"),
    ]),
    @pl.Series::str_nullable("u", [
      Some("cat"),
      None,
      Some("a1b22"),
      Some("dog"),
      Some("A"),
      Some("é"),
    ]),
    @pl.Series::int32("i", [1, 2, 3, 4, 5, 6]),
    @pl.Series::null("n", 6),
  ])
}

///|
fn str_out(e : @pl.Expr) -> @pl.Series raise @pl.PolarsError {
  str_df().select([e]).get_columns()[0]
}

///|
test "str().contains and the prefix and suffix tests" {
  let s = @pl.col("s")
  let c = str_out(s.str().contains("a"))
  assert_eq(c.name(), "s")
  assert_eq(c.dtype(), @pl.DataType::Boolean)
  assert_eq(c.to_bool_array(), [
    Some(false),
    Some(true),
    None,
    Some(false),
    Some(false),
    Some(true),
  ])
  // a regular expression, or the text itself with `literal`
  assert_eq(str_out(s.str().contains("^a.c$")).to_bool_array(), [
    Some(false),
    Some(true),
    None,
    Some(false),
    Some(false),
    Some(false),
  ])
  assert_eq(str_out(s.str().contains("x.y", literal=true)).to_bool_array(), [
    Some(false),
    Some(false),
    None,
    Some(false),
    Some(true),
    Some(false),
  ])
  assert_eq(str_out(s.str().contains(".", literal=true)).to_bool_array(), [
    Some(false),
    Some(false),
    None,
    Some(false),
    Some(true),
    Some(false),
  ])
  assert_eq(str_out(s.str().starts_with("ab")).to_bool_array(), [
    Some(false),
    Some(true),
    None,
    Some(false),
    Some(false),
    Some(false),
  ])
  assert_eq(str_out(s.str().ends_with("y")).to_bool_array(), [
    Some(false),
    Some(false),
    None,
    Some(false),
    Some(true),
    Some(false),
  ])
  // an invalid regular expression and the wrong types
  assert_true(
    raises(() => str_out(s.str().contains("("))) is Some(@pl.ComputeError(_)),
  )
  assert_true(
    raises(() => str_out(@pl.col("i").str().contains("a")))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => str_out(@pl.col("n").str().starts_with("a")))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => str_out(@pl.col("zz").str().ends_with("a")))
    is Some(@pl.ColumnNotFound(_)),
  )
}

///|
test "str(): case, lengths and replace" {
  let s = @pl.col("s")
  assert_eq(str_out(s.str().to_uppercase()).to_str_array(), [
    Some("  HELLO  "),
    Some("ABC"),
    None,
    Some(""),
    Some("X.Y"),
    Some("\u{1F600}A"),
  ])
  assert_eq(str_out(@pl.col("u").str().to_lowercase()).to_str_array(), [
    Some("cat"),
    None,
    Some("a1b22"),
    Some("dog"),
    Some("a"),
    Some("é"),
  ])
  let n = str_out(s.str().len_chars())
  assert_eq(n.dtype(), @pl.DataType::Int64)
  assert_eq(n.to_int64_array(), [
    Some(9L),
    Some(3L),
    None,
    Some(0L),
    Some(3L),
    Some(2L),
  ])
  assert_eq(str_out(s.str().len_bytes()).to_int64_array(), [
    Some(9L),
    Some(3L),
    None,
    Some(0L),
    Some(3L),
    Some(5L),
  ])
  assert_eq(
    str_out(@pl.col("u").str().replace("[0-9]+", "<$0>")).to_str_array(),
    [Some("cat"), None, Some("a<1>b22"), Some("dog"), Some("A"), Some("é")],
  )
  assert_eq(
    str_out(@pl.col("u").str().replace_all("[0-9]", "#")).to_str_array(),
    [Some("cat"), None, Some("a#b##"), Some("dog"), Some("A"), Some("é")],
  )
  assert_eq(
    str_out(s.str().replace_all(".", "!", literal=true)).to_str_array(),
    [
      Some("  Hello  "),
      Some("abc"),
      None,
      Some(""),
      Some("x!y"),
      Some("\u{1F600}a"),
    ],
  )
  assert_true(
    raises(() => str_out(s.str().replace("(", "x")))
    is Some(@pl.ComputeError(_)),
  )
  assert_true(
    raises(() => str_out(@pl.col("i").str().replace("a", "b")))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => str_out(@pl.col("i").str().to_uppercase()))
    is Some(@pl.SchemaMismatch(_)),
  )
  assert_true(
    raises(() => str_out(@pl.col("n").str().len_chars()))
    is Some(@pl.SchemaMismatch(_)),
  )
}

///|
test "str(): strip_chars" {
  let s = @pl.col("s")
  assert_eq(str_out(s.str().strip_chars()).to_str_array(), [
    Some("Hello"),
    Some("abc"),
    None,
    Some(""),
    Some("x.y"),
    Some("\u{1F600}a"),
  ])
  assert_eq(str_out(s.str().strip_chars_start()).to_str_array(), [
    Some("Hello  "),
    Some("abc"),
    None,
    Some(""),
    Some("x.y"),
    Some("\u{1F600}a"),
  ])
  assert_eq(str_out(s.str().strip_chars_end()).to_str_array(), [
    Some("  Hello"),
    Some("abc"),
    None,
    Some(""),
    Some("x.y"),
    Some("\u{1F600}a"),
  ])
  // a set of characters
  assert_eq(str_out(s.str().strip_chars(characters="x. ")).to_str_array(), [
    Some("Hello"),
    Some("abc"),
    None,
    Some(""),
    Some("y"),
    Some("\u{1F600}a"),
  ])
  assert_eq(
    str_out(s.str().strip_chars_end(characters="y\u{1F600}a")).to_str_array(),
    [Some("  Hello  "), Some("abc"), None, Some(""), Some("x."), Some("")],
  )
  // an empty set removes nothing
  assert_eq(
    str_out(s.str().strip_chars(characters="")).to_str_array()[0],
    Some("  Hello  "),
  )
  assert_true(
    raises(() => str_out(@pl.col("i").str().strip_chars()))
    is Some(@pl.SchemaMismatch(_)),
  )
}

///|
test "str(): show text" {
  let s = @pl.col("a")
  assert_eq(
    s.str().contains("x").to_string(),
    "col(\"a\").str.contains([\"x\"])",
  )
  assert_eq(
    s.str().contains("x", literal=true).to_string(),
    "col(\"a\").str.contains([\"x\"])",
  )
  assert_eq(
    s.str().starts_with("x").to_string(),
    "col(\"a\").str.starts_with([\"x\"])",
  )
  assert_eq(
    s.str().ends_with("y").to_string(),
    "col(\"a\").str.ends_with([\"y\"])",
  )
  assert_eq(s.str().to_lowercase().to_string(), "col(\"a\").str.to_lowercase()")
  assert_eq(s.str().to_uppercase().to_string(), "col(\"a\").str.to_uppercase()")
  assert_eq(s.str().len_chars().to_string(), "col(\"a\").str.len_chars()")
  assert_eq(s.str().len_bytes().to_string(), "col(\"a\").str.len_bytes()")
  assert_eq(
    s.str().replace("a", "b").to_string(),
    "col(\"a\").str.replace([\"a\", \"b\"])",
  )
  assert_eq(
    s.str().replace_all("a", "b").to_string(),
    "col(\"a\").str.replace_all([\"a\", \"b\"])",
  )
  assert_eq(
    s.str().strip_chars().to_string(),
    "col(\"a\").str.strip_chars([null])",
  )
  assert_eq(
    s.str().strip_chars(characters="xy").to_string(),
    "col(\"a\").str.strip_chars([\"xy\"])",
  )
  assert_eq(
    s.str().strip_chars_start().to_string(),
    "col(\"a\").str.strip_chars_start([null])",
  )
  assert_eq(
    s.str().strip_chars_end(characters="z").to_string(),
    "col(\"a\").str.strip_chars_end([\"z\"])",
  )
}

///|
test "str(): composition, names, selectors and literals" {
  let df = str_df()
  // a chain, an aggregate of it, arithmetic with it
  let n = df.select([@pl.col("s").str().strip_chars().str().len_chars()])
  assert_eq(n.column("s").to_int64_array(), [
    Some(5L),
    Some(3L),
    None,
    Some(0L),
    Some(3L),
    Some(2L),
  ])
  assert_eq(
    df
    .select([@pl.col("s").str().len_chars().sum()])
    .column("s")
    .to_int64_array(),
    [Some(17L)],
  )
  let m = df.select([@pl.col("s").str().len_chars() + @pl.lit_int(1L)])
  assert_eq(m.column("s").to_int64_array()[0], Some(10L))
  // the name is the column's, alias renames
  let named = df.select([
    @pl.col("s").str().to_uppercase().alias("up"),
    @pl.col("u").str().len_chars(),
  ])
  assert_eq(named.columns(), ["up", "u"])
  // selectors expand to one expression per column
  let both = df.select([@pl.cols(["s", "u"]).str().to_uppercase()])
  assert_eq(both.columns(), ["s", "u"])
  assert_eq(both.column("u").to_str_array()[0], Some("CAT"))
  // the first column that is not a string raises
  assert_true(
    raises(() => df.select([@pl.all().str().to_uppercase()]))
    is Some(@pl.SchemaMismatch(_)),
  )
  // duplicated names
  assert_true(
    raises(() => df.select([@pl.col("s"), @pl.col("s").str().to_uppercase()]))
    is Some(@pl.DuplicateColumn(_)),
  )
  // a literal gives one value, repeated next to a column
  let lit = df.select([
    @pl.col("i"),
    @pl.lit_str("abc").str().to_uppercase().alias("k"),
  ])
  assert_eq(lit.column("k").to_str_array(), [
    Some("ABC"),
    Some("ABC"),
    Some("ABC"),
    Some("ABC"),
    Some("ABC"),
    Some("ABC"),
  ])
  assert_eq(
    df
    .select([@pl.lit_str("a\u{1F600}").str().len_chars()])
    .column("literal")
    .to_int64_array(),
    [Some(2L)],
  )
  // a weak number or a Null literal is not a string
  assert_true(
    raises(() => df.select([@pl.lit_int(1L).str().to_uppercase()]))
    is Some(@pl.SchemaMismatch(_)),
  )
  assert_true(
    raises(() => df.select([@pl.lit(@pl.AnyValue::Null).str().len_chars()]))
    is Some(@pl.SchemaMismatch(_)),
  )
  // used as a predicate and as a sort key
  let kept = df.filter(@pl.col("s").str().contains("a"))
  assert_eq(kept.column("i").to_int32_array(), [Some(2), Some(6)])
  let sorted = df.sort([@pl.col("s").str().len_chars()])
  assert_eq(sorted.column("i").to_int32_array(), [
    Some(3),
    Some(4),
    Some(6),
    Some(2),
    Some(5),
    Some(1),
  ])
  // an empty frame
  let e = df
    .head(n=0)
    .select([
      @pl.col("s").str().to_uppercase(),
      @pl.col("s").str().len_chars().alias("n"),
    ])
  assert_eq(e.shape(), (0, 2))
  assert_eq(e.dtypes(), [@pl.DataType::String, Int64])
}

///|
test "str() errors: weak literal type, order of two failing expressions" {
  let df = str_df()
  // a lone weak integer is an Int64 here (polars names i32)
  match raises(() => df.select([@pl.lit_int(1L).str().to_uppercase()])) {
    Some(@pl.SchemaMismatch(m)) =>
      assert_eq(
        m, "invalid series dtype: expected `String`, got `i64` for series with name `literal`",
      )
    _ => fail("expected SchemaMismatch")
  }
  match raises(() => df.select([@pl.lit_float(1.5).str().len_chars()])) {
    Some(@pl.SchemaMismatch(m)) =>
      assert_eq(
        m, "invalid series dtype: expected `String`, got `f64` for series with name `literal`",
      )
    _ => fail("expected SchemaMismatch")
  }
  // the first failing expression is reported (polars reports the schema-time
  // error of `contains` on a number before the run-time one of `to_uppercase`)
  match
    raises(() => {
      df.select([
        @pl.col("i").str().to_uppercase(),
        @pl.col("i").str().contains("a").alias("c"),
      ])
    }) {
    Some(@pl.SchemaMismatch(_)) => ()
    _ => fail("expected the error of the first expression")
  }
  // the message of an invalid regular expression names the pattern and
  // keeps the engine's hint
  match raises(() => df.select([@pl.col("s").str().contains("[a")])) {
    Some(@pl.ComputeError(m)) =>
      assert_eq(
        m, "regex error: regex parse error: \"[a\": Unclosed character class",
      )
    _ => fail("expected ComputeError")
  }
  // unsupported Rust syntax: the hint points to the replacement
  for pat in ["\\d+", "\\s+", "\\w+", "^\\S+"] {
    match raises(() => df.select([@pl.col("s").str().contains(pat)])) {
      Some(@pl.ComputeError(m)) =>
        assert_eq(
          m,
          "regex error: regex parse error: \"\{pat}\": Use POSIX character class instead of \\w, \\W, \\d, \\D, \\s, \\S",
        )
      _ => fail("expected ComputeError for \{pat}")
    }
  }
  match raises(() => df.select([@pl.col("s").str().contains("(?i)foo")])) {
    Some(@pl.ComputeError(m)) => {
      assert_true(m.has_prefix("regex error: regex parse error: \"(?i)foo\": "))
      assert_true(m.length() > 48)
    }
    _ => fail("expected ComputeError")
  }
}

///|
test "str(): supplementary characters in the replacement text" {
  let df = @pl.DataFrame::new([
    @pl.Series::str_nullable("s", [
      Some("abc"),
      Some("\u{1F600}x\u{1F600}"),
      None,
      Some("a1b22"),
    ]),
  ])
  fn run(e : @pl.Expr) -> Array[String?] raise @pl.PolarsError {
    df.select([e]).get_columns()[0].to_str_array()
  }

  let s = @pl.col("s").str()
  assert_eq(run(s.replace_all(".", "\u{1F600}")), [
    Some("\u{1F600}\u{1F600}\u{1F600}"),
    Some("\u{1F600}\u{1F600}\u{1F600}"),
    None,
    Some("\u{1F600}\u{1F600}\u{1F600}\u{1F600}\u{1F600}"),
  ])
  assert_eq(run(s.replace("a", "\u{1F600}")), [
    Some("\u{1F600}bc"),
    Some("\u{1F600}x\u{1F600}"),
    None,
    Some("\u{1F600}1b22"),
  ])
  assert_eq(run(s.replace("a", "a\u{1F600}")), [
    Some("a\u{1F600}bc"),
    Some("\u{1F600}x\u{1F600}"),
    None,
    Some("a\u{1F600}1b22"),
  ])
  assert_eq(run(s.replace("b", "\u{1D4B3}y")), [
    Some("a\u{1D4B3}yc"),
    Some("\u{1F600}x\u{1F600}"),
    None,
    Some("a1\u{1D4B3}y22"),
  ])
  // group references next to supplementary characters
  assert_eq(run(s.replace_all("[0-9]+", "<$0>\u{1F600}")), [
    Some("abc"),
    Some("\u{1F600}x\u{1F600}"),
    None,
    Some("a<1>\u{1F600}b<22>\u{1F600}"),
  ])
  assert_eq(run(s.replace_all("([a-z])([0-9]+)", "\u{1F600}$2$1\u{1F600}")), [
    Some("abc"),
    Some("\u{1F600}x\u{1F600}"),
    None,
    Some("\u{1F600}1a\u{1F600}\u{1F600}22b\u{1F600}"),
  ])
  assert_eq(run(s.replace("(a)", "\u{1F600}${1}\u{1F600}$$")), [
    Some("\u{1F600}a\u{1F600}$bc"),
    Some("\u{1F600}x\u{1F600}"),
    None,
    Some("\u{1F600}a\u{1F600}$1b22"),
  ])
  // literal replacement was already right
  assert_eq(run(s.replace("a", "\u{1F600}", literal=true)), [
    Some("\u{1F600}bc"),
    Some("\u{1F600}x\u{1F600}"),
    None,
    Some("\u{1F600}1b22"),
  ])
}
