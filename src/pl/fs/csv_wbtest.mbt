///|
fn io_text(e : @pl.PolarsError) -> String {
  match e {
    @pl.PolarsError::IOError(m) => m
    _ => "not an IOError"
  }
}

///|
test "io_error: the path is put in front when the text only has it inside a word" {
  // the js text for a directory read; "dir" is a part of "directory"
  assert_eq(
    io_text(io_error("dir", "EISDIR: illegal operation on a directory, read")),
    "dir: EISDIR: illegal operation on a directory, read",
  )
  // the path is a prefix, a suffix or the middle of a longer word
  assert_eq(
    io_text(io_error("a.csv", "open a.csvx: gone")),
    "a.csv: open a.csvx: gone",
  )
  assert_eq(
    io_text(io_error("a.csv", "open aa.csv: gone")),
    "a.csv: open aa.csv: gone",
  )
  assert_eq(
    io_text(io_error("a.csv", "open xa.csvx: gone")),
    "a.csv: open xa.csvx: gone",
  )
  // the text does not hold the path at all
  assert_eq(io_text(io_error("p", "boom")), "p: boom")
  assert_eq(io_text(io_error("p/q.csv", "")), "p/q.csv: ")
  // an empty path is never "named"
  assert_eq(io_text(io_error("", "boom")), ": boom")
}

///|
test "io_error: the text is kept when it names the path" {
  // native, wasm and wasm-gc style: the path after a space, then `:`
  let native = "open a/b.csv: No such file or directory (2)"
  assert_eq(io_text(io_error("a/b.csv", native)), native)
  let wasm_gc = "Failed to read file a/b.csv: No such file or directory (os error 2)"
  assert_eq(io_text(io_error("a/b.csv", wasm_gc)), wasm_gc)
  // js style: the path in single quotes, also with a comma or a space after it
  let quoted = "ENOENT: no such file or directory, open 'a/b.csv'"
  assert_eq(io_text(io_error("a/b.csv", quoted)), quoted)
  let double = "ENOENT: cannot open \"a/b.csv\" here"
  assert_eq(io_text(io_error("a/b.csv", double)), double)
  assert_eq(
    io_text(io_error("a/b.csv", "open a/b.csv, no luck")),
    "open a/b.csv, no luck",
  )
  // the path at the start, at the end and alone
  assert_eq(io_text(io_error("a/b.csv", "a/b.csv: EISDIR")), "a/b.csv: EISDIR")
  assert_eq(
    io_text(io_error("a/b.csv", "cannot read a/b.csv")),
    "cannot read a/b.csv",
  )
  assert_eq(io_text(io_error("a/b.csv", "a/b.csv")), "a/b.csv")
  // a later occurrence that stands alone counts even after a word occurrence
  assert_eq(
    io_text(io_error("dir", "in a directory dir: failed")),
    "in a directory dir: failed",
  )
  // the same text with the path inside a word before it is not enough
  assert_eq(
    io_text(io_error("dir", "the directory: failed")),
    "dir: the directory: failed",
  )
  // a path with a space in it
  assert_eq(
    io_text(io_error("my dir/x.csv", "open my dir/x.csv: gone")),
    "open my dir/x.csv: gone",
  )
}

///|
test "has_unpaired_surrogate: the bounds of both ranges" {
  // outside the surrogate range, right next to it
  assert_false(has_unpaired_surrogate("a\u{D7FF}b"))
  assert_false(has_unpaired_surrogate("a\u{E000}b"))
  assert_false(has_unpaired_surrogate("\u{D7FF}\u{E000}"))
  // the first and last high halves and the first and last low halves, paired
  assert_false(has_unpaired_surrogate("\u{10000}"))
  assert_false(has_unpaired_surrogate("\u{10FFFF}"))
  assert_false(has_unpaired_surrogate("\u{103FF}"))
  assert_false(has_unpaired_surrogate("\u{10C00}"))
  assert_false(has_unpaired_surrogate("\u{10000}\u{10FFFF}"))
  // the same four code units alone
  assert_true(has_unpaired_surrogate(wb_unit(0xD800)))
  assert_true(has_unpaired_surrogate(wb_unit(0xDBFF)))
  assert_true(has_unpaired_surrogate(wb_unit(0xDC00)))
  assert_true(has_unpaired_surrogate(wb_unit(0xDFFF)))
  // a pair of the wrong order or two of a kind
  assert_true(has_unpaired_surrogate(wb_unit(0xDC00) + wb_unit(0xD800)))
  assert_true(has_unpaired_surrogate(wb_unit(0xD800) + wb_unit(0xD800)))
  assert_true(has_unpaired_surrogate(wb_unit(0xDBFF) + wb_unit(0xDBFF)))
  assert_true(has_unpaired_surrogate(wb_unit(0xDC00) + wb_unit(0xDC00)))
  assert_true(has_unpaired_surrogate(wb_unit(0xDC00) + wb_unit(0xDFFF)))
  assert_true(has_unpaired_surrogate(wb_unit(0xDFFF) + wb_unit(0xDFFF)))
  // every pair of bounds is a valid pair
  assert_false(has_unpaired_surrogate(wb_unit(0xD800) + wb_unit(0xDC00)))
  assert_false(has_unpaired_surrogate(wb_unit(0xD800) + wb_unit(0xDFFF)))
  assert_false(has_unpaired_surrogate(wb_unit(0xDBFF) + wb_unit(0xDC00)))
  assert_false(has_unpaired_surrogate(wb_unit(0xDBFF) + wb_unit(0xDFFF)))
  // the unit before the high range and the one after the low range next to a lone half
  assert_true(has_unpaired_surrogate(wb_unit(0xD800) + "\u{E000}"))
  assert_true(has_unpaired_surrogate("\u{D7FF}" + wb_unit(0xDC00)))
  assert_true(has_unpaired_surrogate(wb_unit(0xDBFF) + "\u{D7FF}"))
  assert_true(has_unpaired_surrogate(wb_unit(0xDBFF) + "\u{E000}"))
  assert_false(has_unpaired_surrogate(""))
}

///|
/// A string of one UTF-16 code unit.
fn wb_unit(code : Int32) -> String {
  let sb = StringBuilder()
  sb.write_char(Int32::unsafe_to_char(code))
  sb.to_string()
}
