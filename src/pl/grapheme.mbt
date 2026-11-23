// Grapheme clusters (UAX #29, extended) as polars 2.1.0 cuts them.
//
// polars wraps a table cell with comfy-table, whose `split_long_word` walks a
// word cluster by cluster (the `unicode-segmentation` crate, Unicode 17.0.0
// data); see `cell_lines` in `format.mbt`. The class of every code point is in
// `grapheme_data.mbt`, which `docs/golden/scripts/grapheme.py` generates; that
// script's header describes the data and checks the wrapping against polars.

///|
/// Class of a code point: the Grapheme_Cluster_Break value in the low 4 bits
/// (1 CR, 2 LF, 3 Control, 4 Extend, 5 ZWJ, 6 Regional_Indicator, 7 Prepend,
/// 8 SpacingMark, 9 L, 10 V, 11 T, 12 LV, 13 LVT, 0 anything else) plus 16 for
/// Extended_Pictographic and 32 / 64 / 128 for InCB=Consonant / Linker / Extend.
fn grapheme_class(u : Int32) -> Int32 {
  // printable ASCII is "anything else"
  if u >= 0x20 && u < 0x7f {
    return 0
  }
  // Hangul syllables are not in the table: LV every 28th one, LVT otherwise
  if u >= 0xac00 && u <= 0xd7a3 {
    return if (u - 0xac00) % 28 == 0 { 12 } else { 13 }
  }
  let mut lo = 0
  let mut hi = grapheme_ranges.length() / 3 - 1
  while lo <= hi {
    let mid = (lo + hi) / 2
    if u < grapheme_ranges[mid * 3] {
      hi = mid - 1
    } else if u > grapheme_ranges[mid * 3 + 1] {
      lo = mid + 1
    } else {
      return grapheme_ranges[mid * 3 + 2]
    }
  }
  0
}

///|
/// Whether there is a cluster boundary between `cs[i - 1]` and `cs[i]`
/// (`0 < i < cs.length()`): the rules GB3 to GB13 of UAX #29, with GB9c for the
/// Indic conjuncts.
fn grapheme_break(cs : Array[Int32], i : Int32) -> Bool {
  let ca = grapheme_class(cs[i - 1])
  let cb = grapheme_class(cs[i])
  let ga = ca & 15
  let gb = cb & 15
  // GB3, GB4, GB5: CR LF stay together, other controls stand alone
  if ga == 1 && gb == 2 {
    return false
  }
  if ga >= 1 && ga <= 3 {
    return true
  }
  if gb >= 1 && gb <= 3 {
    return true
  }
  // GB6, GB7, GB8: Hangul syllable sequences
  if ga == 9 && (gb == 9 || gb == 10 || gb == 12 || gb == 13) {
    return false
  }
  if (ga == 12 || ga == 10) && (gb == 10 || gb == 11) {
    return false
  }
  if (ga == 13 || ga == 11) && gb == 11 {
    return false
  }
  // GB9, GB9a, GB9b: Extend, ZWJ and SpacingMark join to the left, Prepend to the right
  if gb == 4 || gb == 5 || gb == 8 || ga == 7 {
    return false
  }
  // GB9c: Consonant [Extend Linker]* Linker [Extend Linker]* x Consonant
  if (cb & 224) == 32 {
    let mut j = i - 1
    let mut linker = false
    while j >= 0 {
      let p = grapheme_class(cs[j]) & 224
      if p == 64 {
        linker = true
      } else if p != 128 {
        break
      }
      j -= 1
    }
    if j >= 0 && (grapheme_class(cs[j]) & 224) == 32 && linker {
      return false
    }
  }
  // GB11: ExtPict Extend* ZWJ x ExtPict
  if ga == 5 && (cb & 16) != 0 {
    let mut j = i - 2
    while j >= 0 && (grapheme_class(cs[j]) & 15) == 4 {
      j -= 1
    }
    if j >= 0 && (grapheme_class(cs[j]) & 16) != 0 {
      return false
    }
  }
  // GB12, GB13: regional indicators pair up from the left
  if ga == 6 && gb == 6 {
    let mut n = 0
    let mut j = i - 1
    while j >= 0 && (grapheme_class(cs[j]) & 15) == 6 {
      n += 1
      j -= 1
    }
    if n % 2 == 1 {
      return false
    }
  }
  true
}

///|
/// The end (exclusive code point index) of the cluster that starts at `start`.
fn grapheme_end(cs : Array[Int32], start : Int32) -> Int32 {
  let mut j = start + 1
  while j < cs.length() && !grapheme_break(cs, j) {
    j += 1
  }
  j
}
