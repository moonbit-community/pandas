///|
/// Whether Rust's `Debug` for `str` writes the code point `cp` as `\u{..}`:
/// the characters that are not printable and the combining ones (table:
/// `debug_escape_data.mbt`). The other special cases (`\0`, `\t`, `\r`, `\n`,
/// `"`, `\`) are not in the table; `debug_quote` writes them.
fn debug_escaped(cp : Int32) -> Bool {
  // binary search for the last range that starts at or before `cp`
  let n = debug_escape_ranges.length() / 2
  let mut lo = 0
  let mut hi = n
  while lo < hi {
    let mid = (lo + hi) / 2
    if debug_escape_ranges[mid * 2] <= cp {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  lo > 0 && cp <= debug_escape_ranges[(lo - 1) * 2 + 1]
}
