///|
/// Runs `f`; `Some("<Variant>: <message>")` if it raised a `PolarsError`.
fn[T] sd_raises(f : () -> T raise PolarsError) -> String? {
  try {
    ignore(f())
    None
  } catch {
    e => Some(e.to_string())
  }
}

///|
fn sd_strs(xs : Array[String?]) -> Series {
  Series::str_nullable("a", xs)
}

///|
test "contains: a regular expression by default, a substring with literal" {
  let s = sd_strs([Some("abc"), Some("a.c"), Some("aXc"), None, Some("")])
  assert_eq(str_contains(s, "a.c", false).to_bool_array(), [
    Some(true),
    Some(true),
    Some(true),
    None,
    Some(false),
  ])
  assert_eq(str_contains(s, "a.c", true).to_bool_array(), [
    Some(false),
    Some(true),
    Some(false),
    None,
    Some(false),
  ])
  // the result keeps the name and is Boolean
  let r = str_contains(s, "b", false)
  assert_eq(r.name(), "a")
  assert_eq(r.dtype(), DataType::Boolean)
  // an empty pattern matches everything that is not null
  assert_eq(str_contains(s, "", false).to_bool_array(), [
    Some(true),
    Some(true),
    Some(true),
    None,
    Some(true),
  ])
  assert_eq(str_contains(s, "", true).to_bool_array(), [
    Some(true),
    Some(true),
    Some(true),
    None,
    Some(true),
  ])
}

///|
test "contains: anchors, classes, groups and case-insensitive groups" {
  let s = sd_strs([Some("abc"), Some("xabc"), Some("ABC"), Some("cat"), None])
  assert_eq(str_contains(s, "^abc$", false).to_bool_array(), [
    Some(true),
    Some(false),
    Some(false),
    Some(false),
    None,
  ])
  assert_eq(str_contains(s, "(?i:abc)", false).to_bool_array(), [
    Some(true),
    Some(true),
    Some(true),
    Some(false),
    None,
  ])
  assert_eq(str_contains(s, "[[:upper:]]{3}", false).to_bool_array(), [
    Some(false),
    Some(false),
    Some(true),
    Some(false),
    None,
  ])
  assert_eq(str_contains(s, "cat|ABC", false).to_bool_array(), [
    Some(false),
    Some(false),
    Some(true),
    Some(true),
    None,
  ])
}

///|
test "contains: wrong dtype, Null column, invalid pattern" {
  assert_eq(
    sd_raises(() => str_contains(Series::int32("a", [1]), "a", false)),
    Some("InvalidOperation: expected String type, got: i32"),
  )
  assert_eq(
    sd_raises(() => str_contains(Series::null("a", 2), "a", true)),
    Some("InvalidOperation: expected String type, got: null"),
  )
  // the pattern is named in the message, also when there is no row, also
  // for replace
  let bad = sd_raises(() => str_contains(sd_strs([]), "(", false))
  assert_eq(
    bad,
    Some("ComputeError: regex error: regex parse error: \"(\": Unclosed group"),
  )
  assert_eq(
    sd_raises(() => str_replace(sd_strs([Some("a")]), "[a", "x", false, true)),
    Some(
      "ComputeError: regex error: regex parse error: \"[a\": Unclosed character class",
    ),
  )
  // a literal is never parsed
  assert_eq(str_contains(sd_strs([Some("f(x)")]), "(", true).to_bool_array(), [
    Some(true),
  ])
}

///|
test "starts_with and ends_with take literals" {
  let s = sd_strs([Some("abc"), Some("a.c"), None, Some(""), Some("😀a")])
  assert_eq(str_starts_with(s, "a").to_bool_array(), [
    Some(true),
    Some(true),
    None,
    Some(false),
    Some(false),
  ])
  assert_eq(str_starts_with(s, "").to_bool_array(), [
    Some(true),
    Some(true),
    None,
    Some(true),
    Some(true),
  ])
  assert_eq(str_ends_with(s, ".c").to_bool_array(), [
    Some(false),
    Some(true),
    None,
    Some(false),
    Some(false),
  ])
  assert_eq(str_ends_with(s, "a").to_bool_array(), [
    Some(false),
    Some(false),
    None,
    Some(false),
    Some(true),
  ])
  // `.` is not a wildcard here
  assert_eq(str_starts_with(s, "a.").to_bool_array()[0], Some(false))
  assert_eq(
    sd_raises(() => str_starts_with(Series::float64("a", [1.0]), "a")),
    Some("InvalidOperation: expected String type, got: f64"),
  )
  assert_eq(
    sd_raises(() => str_ends_with(Series::date("a", [1]), "a")),
    Some("InvalidOperation: expected String type, got: date"),
  )
}

///|
test "case conversion is full Unicode" {
  let s = sd_strs([
    Some("Straße"),
    Some("İstanbul"),
    Some("ΑΣ"),
    Some("ΑΣ Σ"),
    Some("ΣΑΣ"),
    Some("\u{212A}"),
    None,
    Some(""),
    Some("😀中文"),
    Some("ǅ"),
  ])
  assert_eq(str_to_uppercase(s).to_str_array(), [
    Some("STRASSE"),
    Some("İSTANBUL"),
    Some("ΑΣ"),
    Some("ΑΣ Σ"),
    Some("ΣΑΣ"),
    Some("\u{212A}"),
    None,
    Some(""),
    Some("😀中文"),
    Some("Ǆ"),
  ])
  assert_eq(str_to_lowercase(s).to_str_array(), [
    Some("straße"),
    Some("i\u{307}stanbul"),
    Some("ας"),
    Some("ας σ"),
    Some("σας"),
    Some("k"),
    None,
    Some(""),
    Some("😀中文"),
    Some("ǆ"),
  ])
}

///|
test "final sigma needs a cased letter before and none after" {
  let s = sd_strs([
    Some("Σ"),
    Some("ΑΣ."),
    Some(".Σ"),
    Some("ΑΣΑ"),
    Some("Α.Σ.Α"),
    Some("Α.Σ."),
    Some("\u{10400}Σ"),
    Some("1Σ"),
  ])
  assert_eq(str_to_lowercase(s).to_str_array(), [
    Some("σ"),
    Some("ας."),
    Some(".σ"),
    Some("ασα"),
    Some("α.σ.α"),
    Some("α.ς."),
    Some("\u{10428}ς"),
    Some("1σ"),
  ])
}

///|
test "case conversion: ASCII and errors" {
  let s = sd_strs([Some("Hello World 123"), None])
  assert_eq(str_to_lowercase(s).to_str_array(), [Some("hello world 123"), None])
  assert_eq(str_to_uppercase(s).to_str_array(), [Some("HELLO WORLD 123"), None])
  assert_eq(
    sd_raises(() => str_to_lowercase(Series::int64("x", [1L]))),
    Some(
      "SchemaMismatch: invalid series dtype: expected `String`, got `i64` for series with name `x`",
    ),
  )
  assert_eq(
    sd_raises(() => str_to_uppercase(Series::null("n", 1))),
    Some(
      "SchemaMismatch: invalid series dtype: expected `String`, got `null` for series with name `n`",
    ),
  )
}

///|
test "len_chars counts code points, len_bytes counts UTF-8 bytes" {
  let s = sd_strs([
    Some("abc"),
    Some("中文"),
    Some("😀"),
    Some(""),
    None,
    Some("Straße"),
    Some("\u{80}\u{7FF}\u{800}\u{FFFF}\u{10FFFF}"),
  ])
  let chars = str_len_chars(s)
  assert_eq(chars.dtype(), DataType::Int64)
  assert_eq(chars.to_int64_array(), [
    Some(3L),
    Some(2L),
    Some(1L),
    Some(0L),
    None,
    Some(6L),
    Some(5L),
  ])
  let bytes = str_len_bytes(s)
  assert_eq(bytes.dtype(), DataType::Int64)
  assert_eq(bytes.to_int64_array(), [
    Some(3L),
    Some(6L),
    Some(4L),
    Some(0L),
    None,
    Some(7L),
    Some(14L),
  ])
  assert_eq(
    sd_raises(() => str_len_chars(Series::bool("b", [true]))),
    Some(
      "SchemaMismatch: invalid series dtype: expected `String`, got `bool` for series with name `b`",
    ),
  )
}

///|
test "replace: first match only, or all" {
  let s = sd_strs([Some("abcabc"), Some("xyz"), None, Some("")])
  assert_eq(str_replace(s, "b", "X", false, false).to_str_array(), [
    Some("aXcabc"),
    Some("xyz"),
    None,
    Some(""),
  ])
  assert_eq(str_replace(s, "b", "X", false, true).to_str_array(), [
    Some("aXcaXc"),
    Some("xyz"),
    None,
    Some(""),
  ])
  assert_eq(str_replace(s, "[a-c]+", "-", false, false).to_str_array(), [
    Some("-"),
    Some("xyz"),
    None,
    Some(""),
  ])
}

///|
test "replace: group references" {
  let s = sd_strs([Some("ab12cd345"), None])
  let p = "([a-z])([0-9]+)"
  assert_eq(str_replace(s, p, "<$2|$1>", false, false).to_str_array(), [
    Some("a<12|b>cd345"),
    None,
  ])
  assert_eq(str_replace(s, p, "<$2|$1>", false, true).to_str_array(), [
    Some("a<12|b>c<345|d>"),
    None,
  ])
  assert_eq(str_replace(s, p, "${1}_${2}x", false, true).to_str_array(), [
    Some("ab_12xcd_345x"),
    None,
  ])
  // $0 is the whole match; a missing group, `$10`, `$1a` (a group *named*
  // `1a`) and an unmatched group are empty
  assert_eq(str_replace(s, "[0-9]+", "[$0]", false, true).to_str_array(), [
    Some("ab[12]cd[345]"),
    None,
  ])
  assert_eq(str_replace(s, p, "[$10]", false, true).to_str_array(), [
    Some("a[]c[]"),
    None,
  ])
  assert_eq(str_replace(s, p, "$1a", false, true).to_str_array(), [
    Some("ac"),
    None,
  ])
  assert_eq(
    str_replace(sd_strs([Some("ac")]), "(a)|(b)", "[$1,$2]", false, true).to_str_array(),
    [Some("[a,]c")],
  )
  // named groups, with and without braces
  assert_eq(
    str_replace(s, "(?<n>[0-9]+)", "[$n]{${n}}", false, true).to_str_array(),
    [Some("ab[12]{12}cd[345]{345}"), None],
  )
  assert_eq(
    str_replace(s, "(?<n>[0-9]+)", "[$nope]", false, true).to_str_array(),
    [Some("ab[]cd[]"), None],
  )
}

///|
test "replace: dollar signs" {
  let s = sd_strs([Some("abc")])
  let cases : Array[(String, String)] = [
    ("$$", "a$c"),
    ("$", "a$c"),
    ("a$", "aa$c"),
    ("a${", "aa${c"),
    ("a${1", "aa${1c"),
    ("${", "a${c"),
    ("$-", "a$-c"),
    ("[$9]", "a[]c"),
  ]
  for pair in cases {
    let (value, expected) = pair
    assert_eq(str_replace(s, "b", value, false, true).to_str_array(), [
      Some(expected),
    ])
  }
  // with literal=true the replacement is plain text
  assert_eq(str_replace(s, "b", "$0$$", true, true).to_str_array(), [
    Some("a$0$$c"),
  ])
}

///|
test "replace: literal pattern" {
  let s = sd_strs([Some("x.y.z"), Some("xyz"), None])
  assert_eq(str_replace(s, ".", "!", true, true).to_str_array(), [
    Some("x!y!z"),
    Some("xyz"),
    None,
  ])
  assert_eq(str_replace(s, ".", "!", false, true).to_str_array(), [
    Some("!!!!!"),
    Some("!!!"),
    None,
  ])
  assert_eq(str_replace(s, ".", "!", true, false).to_str_array(), [
    Some("x!y.z"),
    Some("xyz"),
    None,
  ])
  // an empty literal pattern matches before every character and at the end
  assert_eq(
    str_replace(sd_strs([Some("a😀"), Some("")]), "", "-", true, true).to_str_array(),
    [Some("-a-😀-"), Some("-")],
  )
  assert_eq(
    str_replace(sd_strs([Some("a😀")]), "", "-", true, false).to_str_array(),
    [Some("-a😀")],
  )
}

///|
test "replace: empty matches are found as Rust's regex finds them" {
  let s = sd_strs([Some("abc"), Some("bbb"), Some("abbc"), Some("")])
  assert_eq(str_replace(s, "b*", "-", false, true).to_str_array(), [
    Some("-a-c-"),
    Some("-"),
    Some("-a-c-"),
    Some("-"),
  ])
  assert_eq(str_replace(s, "b*", "-", false, false).to_str_array(), [
    Some("-abc"),
    Some("-"),
    Some("-abbc"),
    Some("-"),
  ])
  assert_eq(
    str_replace(sd_strs([Some("a😀")]), "", "-", false, true).to_str_array(),
    [Some("-a-😀-")],
  )
  assert_eq(
    str_replace(sd_strs([Some("abc")]), "^", ">", false, true).to_str_array(),
    [Some(">abc")],
  )
  assert_eq(
    str_replace(sd_strs([Some("abc")]), "$", "<", false, true).to_str_array(),
    [Some("abc<")],
  )
  assert_eq(
    str_replace(sd_strs([Some("aaa")]), "^a", ">", false, true).to_str_array(),
    [Some(">aa")],
  )
}

///|
test "replace: wrong dtype" {
  assert_eq(
    sd_raises(() => str_replace(Series::int32("a", [1]), "a", "b", false, true)),
    Some("InvalidOperation: expected String type, got: i32"),
  )
  assert_eq(
    sd_raises(() => str_replace(Series::null("a", 1), "a", "b", true, false)),
    Some("InvalidOperation: expected String type, got: null"),
  )
}

///|
test "strip_chars: whitespace by default, a set of characters otherwise" {
  let s = sd_strs([
    Some("  hi  "),
    Some("\t\n x \u{A0}\u{3000}"),
    Some("xxhixx"),
    None,
    Some(""),
    Some("\u{200B} x \u{200B}"),
    Some("\u{B}x\u{B}"),
    Some("\u{1C}x"),
  ])
  assert_eq(str_strip_chars(s, None, Both).to_str_array(), [
    Some("hi"),
    Some("x"),
    Some("xxhixx"),
    None,
    Some(""),
    Some("\u{200B} x \u{200B}"),
    Some("x"),
    Some("\u{1C}x"),
  ])
  assert_eq(str_strip_chars(s, None, Start).to_str_array()[0], Some("hi  "))
  assert_eq(str_strip_chars(s, None, End).to_str_array()[0], Some("  hi"))
  assert_eq(str_strip_chars(s, Some("x"), Both).to_str_array()[2], Some("hi"))
  assert_eq(
    str_strip_chars(s, Some("x"), Start).to_str_array()[2],
    Some("hixx"),
  )
  assert_eq(str_strip_chars(s, Some("x"), End).to_str_array()[2], Some("xxhi"))
  // a set, not a prefix: any of the characters, in any order
  assert_eq(
    str_strip_chars(sd_strs([Some("xhixh")]), Some("hx"), Both).to_str_array(),
    [Some("i")],
  )
  // an empty set strips nothing (not even whitespace)
  assert_eq(
    str_strip_chars(sd_strs([Some("  a ")]), Some(""), Both).to_str_array(),
    [Some("  a ")],
  )
  // characters outside the BMP
  assert_eq(
    str_strip_chars(sd_strs([Some("😀a😀")]), Some("😀"), Both).to_str_array(),
    [Some("a")],
  )
  assert_eq(
    str_strip_chars(sd_strs([Some("😀😀")]), Some("😀"), Both).to_str_array(),
    [Some("")],
  )
  assert_eq(
    sd_raises(() => str_strip_chars(Series::date("d", [1]), None, Both)),
    Some(
      "SchemaMismatch: invalid series dtype: expected `String`, got `date` for series with name `d`",
    ),
  )
  assert_eq(
    sd_raises(() => str_strip_chars(Series::null("n", 1), Some("x"), End)),
    Some(
      "SchemaMismatch: invalid series dtype: expected `String`, got `null` for series with name `n`",
    ),
  )
}

///|
test "case tables are sorted and well formed" {
  for table in [case_lower_map, case_upper_map] {
    let n = table.length() / 5
    assert_eq(table.length(), n * 5)
    for k in 1..<n {
      assert_true(table[(k - 1) * 5] < table[k * 5])
    }
    for k in 0..<n {
      assert_true(table[k * 5 + 1] >= 1 && table[k * 5 + 1] <= 3)
    }
  }
  for ranges in [case_ignorable_ranges, case_cased_ranges] {
    let n = ranges.length() / 2
    for k in 0..<n {
      assert_true(ranges[k * 2] <= ranges[k * 2 + 1])
      if k > 0 {
        assert_true(ranges[(k - 1) * 2 + 1] < ranges[k * 2])
      }
    }
  }
}

///|
test "kernels work on a slice (offsets into shared storage)" {
  let s = sd_strs([Some("Aß"), None, Some("xΣ"), Some("😀b")])
  let tail = s.slice(1, length=3)
  assert_eq(str_to_uppercase(tail).to_str_array(), [
    None,
    Some("XΣ"),
    Some("😀B"),
  ])
  assert_eq(str_contains(tail, "b$", false).to_bool_array(), [
    None,
    Some(false),
    Some(true),
  ])
  assert_eq(str_replace(tail, "x", "-", true, true).to_str_array(), [
    None,
    Some("-Σ"),
    Some("😀b"),
  ])
  assert_eq(str_len_chars(tail).to_int64_array(), [None, Some(2L), Some(2L)])
  let d = Series::date_nullable("d", [Some(0), None, Some(19782), Some(-1)])
  assert_eq(dt_ints(dt_field(d.slice(1, length=3), Day)), [
    None,
    Some(29),
    Some(31),
  ])
}
