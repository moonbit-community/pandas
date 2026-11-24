///|
fn sb_run(
  vals : Array[String],
  f : (@pl.Expr) -> @pl.Expr,
) -> Array[String?] raise @pl.PolarsError {
  let df = @pl.DataFrame::new([@pl.Series::str("s", vals)])
  df.select([f(@pl.col("s"))]).get_columns()[0].to_str_array()
}

///|
fn sb_some(vals : Array[String]) -> Array[String?] {
  vals.map(v => Some(v))
}

// Expected values of every test below were produced by polars 2.1.0
// (fw-scripts/str_probe.py).

///|
test "to_uppercase and to_lowercase of Latin-1 and beyond, next to ASCII" {
  assert_eq(
    sb_run(["zé", "z", "é", "ÿ", "àz"], e => e.str().to_uppercase()),
    sb_some(["ZÉ", "Z", "É", "Ÿ", "ÀZ"]),
  )
  assert_eq(
    sb_run(["ZÉ", "Z", "É", "AÀ"], e => e.str().to_lowercase()),
    sb_some(["zé", "z", "é", "aà"]),
  )
}

///|
test "strip_chars strips exactly the Unicode whitespace" {
  // true: stripped by polars; false: not whitespace for Rust's `is_whitespace`
  let cases : Array[(String, Bool)] = [
    ("\u{9}", true),
    ("\u{A}", true),
    ("\u{B}", true),
    ("\u{C}", true),
    ("\u{D}", true),
    ("\u{20}", true),
    ("\u{85}", true),
    ("\u{A0}", true),
    ("\u{1680}", true),
    ("\u{2000}", true),
    ("\u{2005}", true),
    ("\u{200A}", true),
    ("\u{200B}", false),
    ("\u{2028}", true),
    ("\u{2029}", true),
    ("\u{202F}", true),
    ("\u{205F}", true),
    ("\u{3000}", true),
    ("\u{180E}", false),
    ("\u{FEFF}", false),
  ]
  for c in cases {
    let (w, stripped) = c
    let v = w + "a" + w
    let got = sb_run([v], e => e.str().strip_chars())
    let want = if stripped { "a" } else { v }
    assert_eq(got, sb_some([want]))
  }
}

///|
test "replace_all: group numbers that are huge are not groups" {
  let run = (r : String) => sb_run(["a"], e => e.str().replace_all("(a)", r))
  assert_eq(run("[$1]"), sb_some(["[a]"]))
  assert_eq(run("[${+1}]"), sb_some(["[a]"]))
  assert_eq(run("[$9999]"), sb_some(["[]"]))
  assert_eq(run("[$4294967297]"), sb_some(["[]"]))
  assert_eq(run("[${4294967297}]"), sb_some(["[]"]))
  assert_eq(run("[${99999999999}]"), sb_some(["[]"]))
  assert_eq(run("[$99999999999]"), sb_some(["[]"]))
  assert_eq(run("[${100000000}]"), sb_some(["[]"]))
}

///|
test "to_lowercase: the final sigma rule" {
  let got = sb_run(
    [
      "ΑΣ", "Σ", "ΑΣ Α", "Α.Σ", "ΑΣ.", "Σ.Α", "ΑΣΣ", "Α\u{AD}Σ",
      "Α Σ", "ΑΣ\u{301}", "ΑΣ'", "ΑΣ'Α", "ΑΣ1", "Α1Σ",
    ],
    e => e.str().to_lowercase(),
  )
  assert_eq(
    got,
    sb_some([
      "ας", "σ", "ας α", "α.ς", "ας.", "σ.α", "ασς", "α\u{AD}ς",
      "α σ", "ας\u{301}", "ας'", "ασ'α", "ας1", "α1σ",
    ]),
  )
}

///|
test "case mapping near the end of the tables" {
  assert_eq(
    sb_run(
      [
        "\u{1E921}", "\u{1E900}", "\u{10D50}", "\u{16E40}", "\u{1E943}", "ǅ", "ǆ",
        "ꭰ", "Ꭰ",
      ],
      e => e.str().to_lowercase(),
    ),
    sb_some([
      "\u{1E943}", "\u{1E922}", "\u{10D70}", "\u{16E60}", "\u{1E943}", "ǆ", "ǆ",
      "ꭰ", "ꭰ",
    ]),
  )
  assert_eq(
    sb_run(
      [
        "\u{1E921}", "\u{1E900}", "\u{10D70}", "\u{16E60}", "\u{1E943}", "ǅ", "ǆ",
        "ꭰ", "Ꭰ", "ﬃ", "ŉ",
      ],
      e => e.str().to_uppercase(),
    ),
    sb_some([
      "\u{1E921}", "\u{1E900}", "\u{10D50}", "\u{16E40}", "\u{1E921}", "Ǆ", "Ǆ",
      "Ꭰ", "Ꭰ", "FFI", "ʼN",
    ]),
  )
}

///|
/// A lone leading (high) and trailing (low) surrogate: the halves of U+1F600.
fn sb_hi() -> String {
  let sb = StringBuilder()
  sb.write_char(Int32::unsafe_to_char(0xD83D))
  sb.to_string()
}

///|
fn sb_lo() -> String {
  let sb = StringBuilder()
  sb.write_char(Int32::unsafe_to_char(0xDE00))
  sb.to_string()
}

///|
// There is no polars reference: a UTF-8 string cannot hold a lone surrogate.
// The library keeps it as it is and maps the text around it.
test "case mapping and strip keep lone surrogates" {
  let hi = sb_hi()
  let lo = sb_lo()
  let pair = hi + lo
  assert_eq(pair, "\u{1F600}")
  assert_eq(
    sb_run(
      ["A" + hi, lo + "B", hi + "xÉ", "É" + lo + hi, pair + "é", hi + "É"],
      e => e.str().to_lowercase(),
    ),
    sb_some([
      "a" + hi,
      lo + "b",
      hi + "xé",
      "é" + lo + hi,
      pair + "é",
      hi + "é",
    ]),
  )
  assert_eq(
    sb_run(["a" + hi, lo + "b", "é" + hi, pair + "é", lo + hi + "é"], e => {
      e.str().to_uppercase()
    }),
    sb_some(["A" + hi, lo + "B", "É" + hi, pair + "É", lo + hi + "É"]),
  )
  assert_eq(
    sb_run([" " + hi + " ", lo + " ", " " + lo + hi], e => e.str().strip_chars()),
    sb_some([hi, lo, lo + hi]),
  )
}

///|
test "replace and strip never abort on lone surrogates" {
  let hi = sb_hi()
  let lo = sb_lo()
  // a literal pattern found right before a lone trailing surrogate
  assert_eq(
    sb_run(["a" + lo + "a", lo + "a", "a" + hi + "a"], e => {
      e.str().replace_all("a", "b", literal=true)
    }),
    sb_some(["b" + lo + "b", lo + "b", "b" + hi + "b"]),
  )
  assert_eq(
    sb_run(["a" + lo + "a", "xa" + lo], e => {
      e.str().replace("a", "b", literal=true)
    }),
    sb_some(["b" + lo + "a", "xb" + lo]),
  )
  // a regex match followed by one
  assert_eq(
    sb_run(["a" + lo + "a", lo + "a", "a" + hi], e => {
      e.str().replace_all("a", "b")
    }),
    sb_some(["b" + lo + "b", lo + "b", "b" + hi]),
  )
  // a replacement with a group name that starts with one (the `$` and `{` are
  // joined at run time: the js backend breaks on a string literal that ends in `${`)
  assert_eq(
    sb_run(["a"], e => {
      e.str().replace_all("(a)", sb_join(["[$", "{", lo, "x}]"]))
    }),
    sb_some(["[]"]),
  )
  assert_eq(
    sb_run(["a"], e => e.str().replace_all("(a)", "[$" + "z" + lo + "]")),
    sb_some(["[" + lo + "]"]),
  )
}

///|
fn sb_join(parts : Array[String]) -> String {
  parts.join("")
}
