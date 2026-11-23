// White-box tests of the grapheme cluster rules (`grapheme.mbt`) and of the table
// cell wrapping built on them (`wrap_line`, `split_long_word`, `cell_lines` in
// `format.mbt`). The wrapped lines of whole tables are checked against polars in
// `show_golden_test.mbt`.

///|
/// Decodes a line of Unicode's GraphemeBreakTest.txt: the code points and, for
/// every position between them, whether it is a boundary.
fn parse_break_case(line : String) -> (Array[Int32], Array[Bool]) raise {
  let cps : Array[Int32] = []
  let breaks : Array[Bool] = []
  for item in line.split(" ") {
    let item = item.to_owned()
    if item == "÷" {
      breaks.push(true)
    } else if item == "×" {
      breaks.push(false)
    } else {
      cps.push(@string.parse_int(item, radix=16))
    }
  }
  (cps, breaks)
}

///|
test "grapheme_break agrees with Unicode's GraphemeBreakTest.txt" {
  assert_eq(grapheme_break_cases.length(), 766)
  for line in grapheme_break_cases {
    let (cps, breaks) = parse_break_case(line)
    assert_eq(breaks.length(), cps.length() + 1)
    for i in 1..<cps.length() {
      if grapheme_break(cps, i) != breaks[i] {
        fail("\{line}: wrong at position \{i}")
      }
    }
  }
}

///|
test "grapheme_end and grapheme_class" {
  // a flag is one cluster, a third regional indicator starts the next
  let flags = [0x1f1e8, 0x1f1f3, 0x1f1fa]
  assert_eq(grapheme_end(flags, 0), 2)
  assert_eq(grapheme_end(flags, 2), 3)
  // crlf, then a letter
  assert_eq(grapheme_end([0x0d, 0x0a, 0x41], 0), 2)
  // Hangul LV and LVT are computed: U+AC00 is LV, U+AC01 is LVT
  assert_eq(grapheme_class(0xac00) & 15, 12)
  assert_eq(grapheme_class(0xac01) & 15, 13)
  assert_eq(grapheme_class(0xd7a3) & 15, 13)
  assert_eq(grapheme_class(0xd7a4) & 15, 0)
  assert_eq(grapheme_class(0x41), 0)
  assert_eq(grapheme_class(0x200d) & 15, 5)
  // Devanagari KA, VIRAMA, SSA: one conjunct cluster (Unicode 15.1 and later)
  assert_eq(grapheme_end([0x915, 0x94d, 0x937, 0x93f], 0), 4)
}

///|
test "split_long_word cuts whole clusters" {
  // two-column characters
  assert_eq(split_long_word("日日日日", 5, false), ("日日", "日日"))
  // room for no whole cluster: nothing taken in the middle of a line ...
  assert_eq(split_long_word("日日", 1, false), ("", "日日"))
  // ... but one code point on a fresh line
  assert_eq(split_long_word("日日", 1, true), ("日", "日"))
  // a flag is not cut between its two regional indicators
  assert_eq(
    split_long_word("\u{1f1e8}\u{1f1f3}a", 1, false),
    ("", "\u{1f1e8}\u{1f1f3}a"),
  )
  assert_eq(
    split_long_word("a\u{1f1e8}\u{1f1f3}", 2, false),
    ("a", "\u{1f1e8}\u{1f1f3}"),
  )
  // a run of choseong is one 32-column cluster: one code point on a fresh line
  let jamo = "\u{1100}".repeat(16)
  assert_eq(
    split_long_word(jamo, 31, true),
    ("\u{1100}", "\u{1100}".repeat(15)),
  )
}

///|
test "wrap_line follows comfy-table's word wrapping" {
  // fits: kept as it is
  assert_eq(wrap_line("a b c", 10), ["a b c"])
  // words that do not fit start a new line; the space at the break is dropped
  assert_eq(wrap_line("aaaa bbbb cccc", 9), ["aaaa bbbb", "cccc"])
  // several spaces: only the single space is a separator, the rest are empty words
  // (the spaces left at the end of a line are padding)
  assert_eq(wrap_line("aaaa    bbbb", 6), ["aaaa ", "bbbb"])
  // a word wider than the column is cut into the free space of the line
  assert_eq(
    wrap_line("日日日日日日日日 日日日日日日日日日日日", 16),
    ["日日日日日日日日", "日日日日日日日日", "日日日"],
  )
  // fewer than 4 free columns: the long word starts a new line instead
  assert_eq(
    wrap_line("日日日日日日 日日日日日日日日日日", 15),
    ["日日日日日日", "日日日日日日日", "日日日"],
  )
  // an over-long word with at least 4 free columns is cut into the current line
  assert_eq(wrap_line("ab 日日日日日日日日日日", 10), [
    "ab 日日日", "日日日日日", "日日",
  ])
}

///|
test "wrap_line at exactly the column width" {
  let w15 = "日".repeat(15)
  // a line exactly 31 columns wide stays as it is, a leading space too
  assert_eq(wrap_line(w15 + "x", 31), [w15 + "x"])
  assert_eq(wrap_line(" " + w15, 31), [" " + w15])
  // a word exactly 31 columns wide is not cut: it starts a new line
  assert_eq(wrap_line("ab " + w15 + "x", 31), ["ab", w15 + "x"])
  // one column wider: it is cut into the free space of the first line
  assert_eq(wrap_line("ab " + "日".repeat(16), 31), [
    "ab " + "日".repeat(14),
    "日日",
  ])
}

///|
test "cell_lines splits at newlines and wraps every line" {
  assert_eq(cell_lines("a\nb", 5), ["a", "b"])
  assert_eq(cell_lines("", 5), [""])
  assert_eq(cell_lines("aaaa bbbb\ncc", 4), ["aaaa", "bbbb", "cc"])
}

///|
test "column_limit and cell_bound" {
  assert_eq(cell_bound("abc"), 3)
  assert_eq(cell_bound("日"), 2)
  assert_eq(cell_bound("é"), 2)
  assert_eq(cell_bound("\u{17d8}"), 2)
  assert_eq(cell_bound("\u{17d8}\u{17d8}"), 4)
  assert_eq(cell_bound("\u{1f600}"), 2)
  // plain columns: the widest cell, at most 31
  assert_eq(column_limit(["ab", "---", "str"]), 3)
  assert_eq(column_limit(["日".repeat(20), "---", "str"]), 31)
  // U+17D8 is three columns, but its cell counts for no more than the bound
  assert_eq(column_limit(["\u{17d8}\u{17d8}", "s", "---", "str"]), 4)
  assert_eq(column_limit(["\u{17d8}", "s", "---", "str"]), 3)
}
