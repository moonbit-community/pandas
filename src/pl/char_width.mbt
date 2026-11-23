// Display width of text in a table cell, as polars 2.1.0 lays it out.
//
// polars prints tables with comfy-table, whose layout uses the `unicode-width`
// crate's *string* width. That is not the sum of per-character widths: a
// variation selector can widen or narrow the character before it, a ZWJ joins
// emoji into one glyph, and a few scripts have ligature rules. The per-code-point
// widths and the character sets the rules refer to are in `char_width_data.mbt`,
// which `docs/golden/scripts/char_width.py` measures from polars' own output;
// that script's header describes the measurement and states every rule below.

///|
/// Whether `u` is inside one of the inclusive ranges of `tbl`, stored flat as
/// `first, last` pairs in ascending order (binary search).
fn in_char_set(tbl : FixedArray[Int32], u : Int32) -> Bool {
  let mut lo = 0
  let mut hi = tbl.length() / 2 - 1
  while lo <= hi {
    let mid = (lo + hi) / 2
    if u < tbl[mid * 2] {
      hi = mid - 1
    } else if u > tbl[mid * 2 + 1] {
      lo = mid + 1
    } else {
      return true
    }
  }
  false
}

///|
/// Width of one code point on its own (binary search in the measured table).
fn cp_width(u : Int32) -> Int32 {
  if u < char_width_fast_limit {
    return 1
  }
  // the biggest two-column blocks (checked against the table by the tests)
  if (u >= 0x4e00 && u <= 0x9fff) ||
    (u >= 0xac00 && u <= 0xd7a3) ||
    (u >= 0x3041 && u <= 0x3096) ||
    (u >= 0x30a1 && u <= 0x30fa) ||
    (u >= 0x3400 && u <= 0x4dbf) {
    return 2
  }
  let mut lo = 0
  let mut hi = char_width_ranges.length() / 3 - 1
  while lo <= hi {
    let mid = (lo + hi) / 2
    if u < char_width_ranges[mid * 3] {
      hi = mid - 1
    } else if u > char_width_ranges[mid * 3 + 1] {
      lo = mid + 1
    } else {
      return char_width_ranges[mid * 3 + 2]
    }
  }
  1
}

///|
fn is_regional_indicator(u : Int32) -> Bool {
  u >= 0x1f1e6 && u <= 0x1f1ff
}

///|
fn is_emoji_modifier(u : Int32) -> Bool {
  u >= 0x1f3fb && u <= 0x1f3ff
}

///|
/// Characters U+FE01 widens: the curly quotes.
fn is_fe01_base(u : Int32) -> Bool {
  u == 0x2018 || u == 0x2019 || u == 0x201c || u == 0x201d
}

///|
/// The marks between U+17D2 (or U+05D0) and the next letter are transparent,
/// except that polars' width library loses the letter after a run of variation
/// selectors that holds U+FE01 and U+FE0E (in either order, U+FE0F may sit
/// between). Returns the new state and whether the run broke the chain. States:
/// 0 start, 1 only U+FE01/U+FE0F so far (with a U+FE01), 2 only U+FE0E/U+FE0F
/// so far (with a U+FE0E), 3 only U+FE0F so far, 4 any other mark seen (nothing
/// breaks any more). After a U+FE0E run, another mark starts again from 0.
fn vs_step(state : Int32, c : Int32) -> (Int32, Bool) {
  if state == 0 || state == 3 {
    if c == 0xfe01 {
      return (1, false)
    }
    if c == 0xfe0e {
      return (2, false)
    }
    if c == 0xfe0f {
      return (3, false)
    }
    return (4, false)
  }
  if state == 1 {
    if c == 0xfe0e {
      return (1, true)
    }
    return (if c == 0xfe01 || c == 0xfe0f { 1 } else { 4 }, false)
  }
  if state == 2 {
    if c == 0xfe01 {
      return (2, true)
    }
    return (if c == 0xfe0e || c == 0xfe0f { 2 } else { 0 }, false)
  }
  (4, false)
}

///|
/// Width of the first `n` code points of `cs` as one text. The rules, in the
/// order they are tried for each code point `c`:
///
/// - ZWJ (U+200D) is zero wide; after an emoji it lets the next emoji (an
///   emoji presentation character, a text symbol with U+FE0F or an emoji
///   modifier base with a modifier, or a pair of regional indicators) join, and
///   a joined emoji is zero wide.
/// - Hebrew alef, ZWJ, lamed: the lamed is zero wide.
/// - A pair of regional indicators (a flag) is two columns, a single one is one.
/// - U+FE0F after a `char_set_vs16` character makes it two columns wide;
///   U+FE0E after a `char_set_vs15` character makes it one column wide;
///   U+FE01 after a curly quote makes it two columns wide.
/// - An emoji modifier after an emoji modifier base is zero wide (the base is
///   then two columns wide).
/// - Arabic: an alef after a lam (marks and further lam letters may sit between)
///   is zero wide.
/// - Khmer: a letter after COENG (U+17D2) is zero wide (see `vs_step` for the
///   marks that may sit between).
/// - U+1F3F4, 3 to 6 tag digits or letters (U+E0030-U+E0039, U+E0061-U+E007A) and
///   U+E007F make an emoji tag sequence: it counts as an emoji for a following ZWJ.
/// - A quirk of the width library: after a curly quote or `char_set_vs15`
///   character, U+FE01 and U+FE0E, the next lamed, alef or Khmer subscript
///   letter is zero wide.
/// - Anything else has its table width.
fn code_points_width(cs : Array[Int32], n : Int32) -> Int32 {
  let mut tot = 0
  let mut last = -1
  let mut lastw = 0
  // 0: the text so far does not end in an emoji, 1: it does, 2: it does iff
  // `last` is an emoji presentation character (decided only when a ZWJ comes)
  let mut emoji = 0
  let mut zr = false
  let mut lam = false
  let mut vf = false
  let mut heb = 0
  let mut coeng = false
  let mut leak = false
  // inside an emoji tag sequence after U+1F3F4: `tags` is -1 outside one, else
  // the number of tag letters (`tagl`) and leading tag digits (`tagd`) so far;
  // `tagbad`: a tag digit came after a tag letter
  let mut tags = -1
  let mut tagd = 0
  let mut tagl = 0
  let mut tagbad = false
  let mut vsd = 0
  let mut i = 0
  while i < n {
    let c = cs[i]
    let nxt = if i + 1 < n { cs[i + 1] } else { -1 }
    let zr_here = zr
    let vf_here = vf
    zr = false
    vf = false
    // this character completes an emoji tag sequence
    let mut tag_end = false
    if c == 0x1f3f4 {
      tags = 0
      tagd = 0
      tagl = 0
      tagbad = false
    } else if tags >= 0 && c >= 0xe0030 && c <= 0xe0039 {
      // digits count only in front of the letters
      if tagl > 0 {
        tagbad = true
      }
      tagd += 1
    } else if tags >= 0 && c >= 0xe0061 && c <= 0xe007a {
      tagl += 1
    } else if c == 0xe007f &&
      tags >= 0 &&
      !tagbad &&
      ((tagd == 0 && tagl >= 3 && tagl <= 6) || (tagd == 3 && tagl <= 4)) {
      tag_end = true
      tags = -1
    } else {
      tags = -1
    }
    if c == 0x5d0 {
      heb = 1
      vsd = 0
    } else if c == 0x200d && heb >= 1 {
      heb = 2
    } else if heb >= 1 && in_char_set(char_set_hebt, c) {
      if heb == 1 {
        let (st, broke) = vs_step(vsd, c)
        vsd = st
        if broke {
          heb = 0
        }
      }
    } else if c != 0x5dc || heb != 2 {
      heb = 0
    }
    let mut leak_hit = false
    if c == 0xfe0e &&
      i >= 2 &&
      cs[i - 1] == 0xfe01 &&
      (is_fe01_base(cs[i - 2]) || in_char_set(char_set_vs15, cs[i - 2])) {
      leak = true
    } else if leak && !in_char_set(char_set_hebt, c) {
      leak = false
      leak_hit = c == 0x5dc ||
        in_char_set(char_set_alef, c) ||
        in_char_set(char_set_coeng, c)
    }
    let mut coeng_hit = false
    if c == 0x17d2 {
      coeng = true
      vsd = 0
    } else if coeng && in_char_set(char_set_hebt, c) {
      let (st, broke) = vs_step(vsd, c)
      vsd = st
      if broke {
        coeng = false
      }
    } else if coeng && in_char_set(char_set_coeng, c) {
      coeng = false
      coeng_hit = true
    } else {
      coeng = false
    }
    if c == 0x200d {
      zr = emoji == 1 || (emoji == 2 && in_char_set(char_set_ejoin, last))
      emoji = 0
      last = c
      lam = false
      i += 1
      continue
    }
    if zr_here {
      if is_regional_indicator(c) && is_regional_indicator(nxt) {
        emoji = 1
        last = nxt
        lastw = 0
        lam = false
        i += 2
        continue
      }
      if in_char_set(char_set_ejoin, c) &&
        !(nxt == 0xfe0e && in_char_set(char_set_vs15, c)) {
        emoji = 1
        last = c
        lastw = 0
        lam = false
        i += 1
        continue
      }
      if nxt == 0xfe0f && in_char_set(char_set_vs16, c) {
        emoji = 1
        last = 0xfe0f
        lastw = 0
        lam = false
        i += 2
        continue
      }
      if is_emoji_modifier(nxt) && in_char_set(char_set_emb, c) {
        emoji = 1
        last = nxt
        lastw = 0
        lam = false
        i += 2
        continue
      }
    }
    if heb == 2 && c == 0x5dc {
      heb = 0
      last = c
      lastw = 0
      emoji = 0
      lam = false
      i += 1
      continue
    }
    if is_regional_indicator(c) && is_regional_indicator(nxt) {
      tot += 2
      emoji = 1
      last = nxt
      lastw = 1
      lam = false
      i += 2
      continue
    }
    if c == 0xfe0f && last >= 0 {
      if lastw == 1 && in_char_set(char_set_vs16, last) {
        tot += 1
        lastw = 2
        emoji = 1
        last = c
        vf = true
        i += 1
        continue
      }
      if in_char_set(char_set_vs16, last) || in_char_set(char_set_vs16w, last) {
        emoji = 1
        last = c
        vf = true
        i += 1
        continue
      }
    }
    if c == 0x20e3 && last == 0xfe0f && vf_here {
      last = c
      i += 1
      continue
    }
    if c == 0xfe01 && lastw == 1 && is_fe01_base(last) {
      tot += 1
      lastw = 2
      last = c
      i += 1
      continue
    }
    if c == 0xfe0e && lastw == 2 && in_char_set(char_set_vs15, last) {
      tot -= 1
      lastw = 1
      emoji = 0
      last = c
      i += 1
      continue
    }
    if is_emoji_modifier(c) && last >= 0 && in_char_set(char_set_emb, last) {
      if lastw == 1 {
        tot += 1
        lastw = 2
      }
      emoji = 1
      last = c
      i += 1
      continue
    }
    if lam &&
      (
        (last == 0xfe01 && c == 0xfe0e) ||
        (last == 0xfe0e && c == 0xfe01) ||
        (c == 0xfe0e && last == 0xfe0f && i >= 2 && cs[i - 2] == 0xfe01) ||
        (c == 0xfe01 && last == 0xfe0f && i >= 2 && cs[i - 2] == 0xfe0e)
      ) {
      lam = false
    }
    let mut wd = if coeng_hit || leak_hit { 0 } else { cp_width(c) }
    if coeng_hit || leak_hit {
      lam = false
    } else if lam && wd == 1 && in_char_set(char_set_alef, c) {
      wd = 0
      lam = false
    } else if (
        wd == 1 && c >= 0x600 && c < 0x900 && in_char_set(char_set_lam, c)
      ) ||
      (lam && wd == 0 && in_char_set(char_set_lamt, c)) {
      lam = true
    } else {
      lam = false
    }
    tot += wd
    last = c
    lastw = wd
    emoji = if tag_end { 1 } else { 2 }
    i += 1
  }
  tot
}

///|
/// Scratch buffer of `str_width` (code points of the text being measured).
let width_scratch : Array[Int32] = []

///|
/// Display width of a string.
fn str_width(s : String) -> Int32 {
  // text below `char_width_fast_limit` is one column per character (and one
  // UTF-16 unit each)
  let n = s.length()
  let mut plain = true
  for i in 0..<n {
    if s.code_unit_at(i).to_int() >= char_width_fast_limit {
      plain = false
      break
    }
  }
  if plain {
    return n
  }
  width_scratch.clear()
  for c in s {
    width_scratch.push(c.to_int())
  }
  code_points_width(width_scratch, width_scratch.length())
}
