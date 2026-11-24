///|
/// Which end(s) of a string `str_strip_chars` trims.
priv enum StripSide {
  Both
  Start
  End
}

///|
/// The array of a `String` series for the operations polars implements as
/// binary functions (`contains`, `starts_with`, `ends_with`, `replace`): any
/// other type is an `InvalidOperation`, with polars' text.
fn str_array_op(s : Series) -> @arrow.StrArray raise PolarsError {
  match s.col {
    String(a) => a
    other =>
      raise InvalidOperation("expected String type, got: \{other.dtype()}")
  }
}

///|
/// The array of a `String` series for the operations polars implements as
/// unary functions (`to_lowercase`, `len_chars`, `strip_chars`, ...): any
/// other type is a `SchemaMismatch`, with polars' text (which names the
/// series).
fn str_array_unary(s : Series) -> @arrow.StrArray raise PolarsError {
  match s.col {
    String(a) => a
    other =>
      raise SchemaMismatch(
        "invalid series dtype: expected `String`, got `\{other.dtype()}` for series with name `\{s.name}`",
      )
  }
}

///|
/// The hint of a regex parse error: core reports `ParserError at position N:
/// <hint>`; anything else is kept whole.
fn str_regex_hint(e : Error) -> String {
  let text = e.to_string()
  if text.has_prefix("ParserError at position ") {
    match text.find(": ") {
      Some(i) => text[i + 2:].to_owned()
      None => text
    }
  } else {
    text
  }
}

///|
/// Compiles a regular expression. A pattern `@string.Regex` rejects is a
/// `ComputeError` that names the pattern and keeps the engine's hint (polars'
/// own first line only says `regex error: regex parse error:`):
/// `regex error: regex parse error: "<pattern>": <hint>`.
fn str_compile(pattern : String) -> @string.Regex raise PolarsError {
  @string.Regex(pattern) catch {
    e =>
      raise ComputeError(
        "regex error: regex parse error: \"\{pattern}\": \{str_regex_hint(e)}",
      )
  }
}

///|
/// Whether the code unit starting at `i` begins a surrogate pair.
fn str_pair_at(s : String, i : Int32) -> Bool {
  i + 1 < s.length() &&
  s.unsafe_get(i).is_leading_surrogate() &&
  s.unsafe_get(i + 1).is_trailing_surrogate()
}

///|
/// The code point starting at code unit `i` and its width in code units (1 or
/// 2). A lone surrogate is returned as itself.
fn str_cp_at(s : String, i : Int32) -> (Int32, Int32) {
  let u = s.unsafe_get(i).to_int()
  if str_pair_at(s, i) {
    let v = s.unsafe_get(i + 1).to_int()
    (0x10000 + (u - 0xD800) * 0x400 + (v - 0xDC00), 2)
  } else {
    (u, 1)
  }
}

///|
/// The code point that ends just before code unit `end` and its width.
fn str_cp_before(s : String, end : Int32) -> (Int32, Int32) {
  let v = s.unsafe_get(end - 1).to_int()
  if end >= 2 &&
    s.unsafe_get(end - 1).is_trailing_surrogate() &&
    s.unsafe_get(end - 2).is_leading_surrogate() {
    let u = s.unsafe_get(end - 2).to_int()
    (0x10000 + (u - 0xD800) * 0x400 + (v - 0xDC00), 2)
  } else {
    (v, 1)
  }
}

///|
/// Index of the code point after the one starting at `i` (past the end stays
/// past the end).
fn str_next_index(s : String, i : Int32) -> Int32 {
  if i >= s.length() {
    i + 1
  } else if str_pair_at(s, i) {
    i + 2
  } else {
    i + 1
  }
}

///|
/// A column of the given nullable booleans built from `f`, which is not called
/// for a null row.
fn str_bool_result(
  a : @arrow.StrArray,
  f : (String) -> Bool,
) -> @arrow.BoolArray {
  let n = a.length()
  let b = @arrow.BoolBuilder::new(capacity=n)
  for i in 0..<n {
    if a.is_valid(i) {
      b.push(f(a.value(i)))
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
/// A column of the given nullable integers built from `f`, which is not called
/// for a null row.
fn str_int_result(
  a : @arrow.StrArray,
  f : (String) -> Int64,
) -> @arrow.PrimArray[Int64] {
  let n = a.length()
  let b : @arrow.PrimBuilder[Int64] = @arrow.PrimBuilder::new(capacity=n)
  for i in 0..<n {
    if a.is_valid(i) {
      b.push(f(a.value(i)))
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
/// A string column built from `f`, which is not called for a null row.
fn str_str_result(
  a : @arrow.StrArray,
  f : (String) -> String,
) -> @arrow.StrArray {
  let n = a.length()
  let b = @arrow.StrBuilder::new(capacity=n)
  for i in 0..<n {
    if a.is_valid(i) {
      b.push(f(a.value(i)))
    } else {
      b.push_null()
    }
  }
  b.finish()
}

///|
/// Whether each string matches `pattern`: a regular expression (an unanchored
/// search) or, with `literal`, a plain substring. The result is `Boolean`,
/// null for a null row.
///
/// # Errors
/// `InvalidOperation` for a column that is not `String`; `ComputeError` for a
/// pattern `@string.Regex` rejects (checked even when no row is looked at).
fn str_contains(
  s : Series,
  pattern : String,
  literal : Bool,
) -> Series raise PolarsError {
  let a = str_array_op(s)
  let out = if literal {
    str_bool_result(a, v => v.contains(pattern))
  } else {
    let re = str_compile(pattern)
    str_bool_result(a, v => re.execute(v) is Some(_))
  }
  Series::make(s.name, Boolean(out))
}

///|
/// Whether each string starts with `prefix` (a literal, not a pattern).
///
/// # Errors
/// `InvalidOperation` for a column that is not `String`.
fn str_starts_with(s : Series, prefix : String) -> Series raise PolarsError {
  let a = str_array_op(s)
  Series::make(s.name, Boolean(str_bool_result(a, v => v.has_prefix(prefix))))
}

///|
/// Whether each string ends with `suffix` (a literal, not a pattern).
///
/// # Errors
/// `InvalidOperation` for a column that is not `String`.
fn str_ends_with(s : Series, suffix : String) -> Series raise PolarsError {
  let a = str_array_op(s)
  Series::make(s.name, Boolean(str_bool_result(a, v => v.has_suffix(suffix))))
}

///|
/// Number of Unicode code points (a surrogate pair counts once).
fn str_count_chars(v : String) -> Int64 {
  let n = v.length()
  let mut count = 0L
  let mut i = 0
  while i < n {
    i += if str_pair_at(v, i) { 2 } else { 1 }
    count += 1L
  }
  count
}

///|
/// Number of bytes of the UTF-8 encoding. A lone surrogate counts 3 bytes (as
/// in WTF-8); strings of polars cannot contain one.
fn str_count_bytes(v : String) -> Int64 {
  let n = v.length()
  let mut count = 0L
  let mut i = 0
  while i < n {
    let u = v.unsafe_get(i).to_int()
    if u < 0x80 {
      count += 1L
    } else if u < 0x800 {
      count += 2L
    } else if str_pair_at(v, i) {
      count += 4L
      i += 1
    } else {
      count += 3L
    }
    i += 1
  }
  count
}

///|
/// Number of characters (Unicode code points) of each string, as `Int64`.
///
/// # Errors
/// `SchemaMismatch` for a column that is not `String`.
fn str_len_chars(s : Series) -> Series raise PolarsError {
  let a = str_array_unary(s)
  Series::make(s.name, Int64(str_int_result(a, str_count_chars)))
}

///|
/// Number of bytes of the UTF-8 encoding of each string, as `Int64`.
///
/// # Errors
/// `SchemaMismatch` for a column that is not `String`.
fn str_len_bytes(s : Series) -> Series raise PolarsError {
  let a = str_array_unary(s)
  Series::make(s.name, Int64(str_int_result(a, str_count_bytes)))
}

///|
/// Whether `cp` lies in one of the inclusive `first, last` ranges of `ranges`
/// (ascending, stride 2).
fn str_in_ranges(ranges : FixedArray[Int32], cp : Int32) -> Bool {
  let mut lo = 0
  let mut hi = ranges.length() / 2
  while lo < hi {
    let mid = (lo + hi) / 2
    if cp < ranges[mid * 2] {
      hi = mid
    } else if cp > ranges[mid * 2 + 1] {
      lo = mid + 1
    } else {
      return true
    }
  }
  false
}

///|
/// Index of the entry for `cp` in a case table (stride 5: `cp, n, c1, c2, c3`,
/// ascending by `cp`), or -1.
fn str_case_entry(table : FixedArray[Int32], cp : Int32) -> Int32 {
  let mut lo = 0
  let mut hi = table.length() / 5
  while lo < hi {
    let mid = (lo + hi) / 2
    let key = table[mid * 5]
    if cp < key {
      hi = mid
    } else if cp > key {
      lo = mid + 1
    } else {
      return mid * 5
    }
  }
  -1
}

///|
/// Whether the first character at or after code unit `i` (going forward when
/// `forward`, else backward from just before `i`) that is not case-ignorable
/// is cased. This is the test of the final-sigma rule.
fn str_cased_beyond(s : String, i : Int32, forward : Bool) -> Bool {
  let n = s.length()
  let mut pos = i
  while (forward && pos < n) || (!forward && pos > 0) {
    let (cp, w) = if forward {
      str_cp_at(s, pos)
    } else {
      str_cp_before(s, pos)
    }
    if !str_in_ranges(case_ignorable_ranges, cp) {
      return str_in_ranges(case_cased_ranges, cp)
    }
    pos = if forward { pos + w } else { pos - w }
  }
  false
}

///|
/// `str::to_lowercase` / `to_uppercase` of Rust (which polars uses): the full
/// Unicode mapping, so `ß` becomes `SS`, `İ` becomes `i` and U+0307, and a
/// capital sigma at the end of a word becomes `ς`. The tables are in
/// `case_data.mbt`.
fn str_map_case(v : String, upper : Bool) -> String {
  let n = v.length()
  let mut ascii = true
  for i in 0..<n {
    if v.unsafe_get(i).to_int() >= 0x80 {
      ascii = false
      break
    }
  }
  if ascii {
    return if upper { v.to_upper() } else { v.to_lower() }
  }
  let table = if upper { case_upper_map } else { case_lower_map }
  let sb = StringBuilder(capacity=n)
  let mut i = 0
  while i < n {
    let (cp, w) = str_cp_at(v, i)
    if cp < 0x80 {
      let c = if upper {
        if cp >= 0x61 && cp <= 0x7A {
          cp - 32
        } else {
          cp
        }
      } else if cp >= 0x41 && cp <= 0x5A {
        cp + 32
      } else {
        cp
      }
      sb.write_char(c.unsafe_to_char())
    } else if !upper && cp == 0x3A3 {
      // final sigma: a cased letter before (skipping case-ignorable
      // characters) and none after
      if str_cased_beyond(v, i, false) && !str_cased_beyond(v, i + w, true) {
        sb.write_char('ς')
      } else {
        sb.write_char('σ')
      }
    } else {
      let e = str_case_entry(table, cp)
      if e < 0 {
        sb.write_substring(v, i, w)
      } else {
        for k in 0..<table[e + 1] {
          sb.write_char(table[e + 2 + k].unsafe_to_char())
        }
      }
    }
    i += w
  }
  sb.to_string()
}

///|
/// Each string in lower case (full Unicode mapping, as polars).
///
/// # Errors
/// `SchemaMismatch` for a column that is not `String`.
fn str_to_lowercase(s : Series) -> Series raise PolarsError {
  let a = str_array_unary(s)
  Series::make(s.name, String(str_str_result(a, v => str_map_case(v, false))))
}

///|
/// Each string in upper case (full Unicode mapping, as polars).
///
/// # Errors
/// `SchemaMismatch` for a column that is not `String`.
fn str_to_uppercase(s : Series) -> Series raise PolarsError {
  let a = str_array_unary(s)
  Series::make(s.name, String(str_str_result(a, v => str_map_case(v, true))))
}

///|
/// One piece of a parsed replacement text.
priv enum ReplacePart {
  Text(String)
  Group(Int32)
  Named(String)
}

///|
/// Whether the code unit is an ASCII letter, digit or `_` (the characters of an
/// unbraced group name in a replacement text).
fn str_is_cap_letter(u : Int32) -> Bool {
  (u >= 0x30 && u <= 0x39) ||
  (u >= 0x41 && u <= 0x5A) ||
  (u >= 0x61 && u <= 0x7A) ||
  u == 0x5F
}

///|
/// A group number written with ASCII digits (and, for the braced form, one
/// leading `+`, which Rust's integer parser accepts): the number, saturated
/// well above any group count; `None` when the text is not such a number.
fn str_parse_group_number(
  v : String,
  start : Int32,
  end : Int32,
  allow_plus : Bool,
) -> Int32? {
  let mut i = start
  if allow_plus && i < end && v.unsafe_get(i).to_int() == 0x2B {
    i += 1
  }
  if i >= end {
    return None
  }
  let mut n = 0
  while i < end {
    let d = v.unsafe_get(i).to_int()
    if d < 0x30 || d > 0x39 {
      return None
    }
    if n < 100_000_000 {
      n = n * 10 + (d - 0x30)
    }
    i += 1
  }
  Some(n)
}

///|
/// Parses a replacement text the way Rust's `regex` expands it, which polars
/// uses: `$$` is a dollar sign; `$name` takes the longest run of ASCII letters,
/// digits and `_` (all digits: a group number, else a group name; `$1a` is the
/// group *named* `1a`); `${name}` takes everything up to the closing brace; a
/// `$` that starts no reference stays a dollar sign. A group that does not
/// exist (or did not take part in the match) is empty.
fn str_parse_replacement(v : String) -> Array[ReplacePart] {
  let parts : Array[ReplacePart] = []
  let n = v.length()
  let text = StringBuilder()
  let mut i = 0
  while i < n {
    let u = v.unsafe_get(i).to_int()
    if u != 0x24 {
      // a supplementary character is a surrogate pair: copy both halves
      let w = if str_pair_at(v, i) { 2 } else { 1 }
      text.write_substring(v, i, w)
      i += w
      continue
    }
    if i + 1 < n && v.unsafe_get(i + 1).to_int() == 0x24 {
      text.write_char('$')
      i += 2
      continue
    }
    if i + 1 < n && v.unsafe_get(i + 1).to_int() == 0x7B {
      // `${name}`: the name is whatever lies up to the closing brace
      let mut j = i + 2
      while j < n && v.unsafe_get(j).to_int() != 0x7D {
        j += 1
      }
      if j >= n {
        text.write_char('$')
        i += 1
        continue
      }
      if text.is_empty() {
        ()
      } else {
        parts.push(Text(text.to_string()))
        text.reset()
      }
      match str_parse_group_number(v, i + 2, j, true) {
        Some(g) => parts.push(Group(g))
        None => parts.push(Named(v.unsafe_substring(start=i + 2, end=j)))
      }
      i = j + 1
      continue
    }
    let mut j = i + 1
    while j < n && str_is_cap_letter(v.unsafe_get(j).to_int()) {
      j += 1
    }
    if j == i + 1 {
      text.write_char('$')
      i += 1
      continue
    }
    if !text.is_empty() {
      parts.push(Text(text.to_string()))
      text.reset()
    }
    match str_parse_group_number(v, i + 1, j, false) {
      Some(g) => parts.push(Group(g))
      None => parts.push(Named(v.unsafe_substring(start=i + 1, end=j)))
    }
    i = j
  }
  if !text.is_empty() {
    parts.push(Text(text.to_string()))
  }
  parts
}

///|
/// Appends the expansion of `parts` for the match `m`.
fn str_expand(
  sb : StringBuilder,
  parts : Array[ReplacePart],
  m : @string.MatchResult,
) -> Unit {
  for part in parts {
    match part {
      Text(t) => sb.write_string(t)
      Group(g) =>
        if g == 0 {
          sb.write_view(m.content())
        } else if m.group(g) is Some(v) {
          sb.write_view(v)
        }
      Named(name) => if m.named_group(name) is Some(v) { sb.write_view(v) }
    }
  }
}

///|
/// Replaces the first match (`all = false`) or every match of the regular
/// expression `re` in `v`. Empty matches are found as Rust's `regex` finds
/// them: one right after the previous match is skipped, so `b*` on `abc`
/// matches at 0, at `b`, and at the end.
fn str_replace_regex(
  re : @string.Regex,
  v : String,
  parts : Array[ReplacePart],
  all : Bool,
) -> String {
  let n = v.length()
  let mut pos = 0
  let mut copied = 0
  let mut last_end = -1
  let mut sb : StringBuilder? = None
  while pos <= n {
    guard re.execute(v, last_index=pos) is Some(m) else { break }
    let start = m.before().length()
    let end = n - m.after().length()
    if start == end && end == last_end {
      pos = str_next_index(v, pos)
      continue
    }
    let b = match sb {
      Some(b) => b
      None => {
        let b = StringBuilder(capacity=n)
        sb = Some(b)
        b
      }
    }
    b.write_substring(v, copied, start - copied)
    str_expand(b, parts, m)
    copied = end
    last_end = end
    pos = end
    if !all {
      break
    }
  }
  match sb {
    None => v
    Some(b) => {
      b.write_substring(v, copied, n - copied)
      b.to_string()
    }
  }
}

///|
/// Replaces the first (`all = false`) or every occurrence of the plain text
/// `pattern` in `v` by `value`, taken literally. An empty pattern matches
/// before every character and at the end, as in Rust's `str::replace`.
fn str_replace_literal(
  pattern : String,
  value : String,
  v : String,
  all : Bool,
) -> String {
  let n = v.length()
  let sb = StringBuilder(capacity=n)
  let mut copied = 0
  if pattern.length() == 0 {
    let mut pos = 0
    while pos <= n {
      sb.write_substring(v, copied, pos - copied)
      sb.write_string(value)
      copied = pos
      if !all {
        break
      }
      pos = str_next_index(v, pos)
    }
  } else {
    let mut pos = 0
    while pos <= n {
      // `unsafe_view`: `exact_view` aborts when `pos` is a lone trailing surrogate
      guard v.unsafe_view(start=pos, end=n).find(pattern) is Some(k) else {
        break
      }
      let start = pos + k
      sb.write_substring(v, copied, start - copied)
      sb.write_string(value)
      copied = start + pattern.length()
      pos = copied
      if !all {
        break
      }
    }
  }
  if copied == 0 && sb.is_empty() && !(pattern.length() == 0) {
    return v
  }
  sb.write_substring(v, copied, n - copied)
  sb.to_string()
}

///|
/// Replaces the first match (`all = false`) or every match of `pattern` by
/// `value`. A regular expression by default; with `literal`, both `pattern`
/// and `value` are plain text. In a regular expression's `value`, `$0`..`$9`,
/// `$name` and `${name}` insert the text of a group and `$$` is a dollar sign
/// (see `str_parse_replacement`).
///
/// # Errors
/// `InvalidOperation` for a column that is not `String`; `ComputeError` for a
/// pattern `@string.Regex` rejects (checked even when no row is looked at).
fn str_replace(
  s : Series,
  pattern : String,
  value : String,
  literal : Bool,
  all : Bool,
) -> Series raise PolarsError {
  let a = str_array_op(s)
  let out = if literal {
    str_str_result(a, v => str_replace_literal(pattern, value, v, all))
  } else {
    let re = str_compile(pattern)
    let parts = str_parse_replacement(value)
    str_str_result(a, v => str_replace_regex(re, v, parts, all))
  }
  Series::make(s.name, String(out))
}

///|
/// Whitespace as polars strips it: Unicode `White_Space` (U+0009-U+000D,
/// U+0020, U+0085, U+00A0, U+1680, U+2000-U+200A, U+2028, U+2029, U+202F,
/// U+205F, U+3000). Not U+001C-U+001F and not the zero-width characters.
fn str_is_space(cp : Int32) -> Bool {
  (cp >= 0x09 && cp <= 0x0D) ||
  cp == 0x20 ||
  cp == 0x85 ||
  cp == 0xA0 ||
  cp == 0x1680 ||
  (cp >= 0x2000 && cp <= 0x200A) ||
  cp == 0x2028 ||
  cp == 0x2029 ||
  cp == 0x202F ||
  cp == 0x205F ||
  cp == 0x3000
}

///|
/// `v` without the leading and/or trailing characters for which `strip` is
/// true.
fn str_strip_with(
  v : String,
  side : StripSide,
  strip : (Int32) -> Bool,
) -> String {
  let n = v.length()
  let mut start = 0
  let mut end = n
  if side is (Both | Start) {
    while start < n {
      let (cp, w) = str_cp_at(v, start)
      if !strip(cp) {
        break
      }
      start += w
    }
  }
  if side is (Both | End) {
    while end > start {
      let (cp, w) = str_cp_before(v, end)
      if !strip(cp) {
        break
      }
      end -= w
    }
  }
  if start == 0 && end == n {
    v
  } else {
    // not `exact_view`: it aborts when an end falls on a lone trailing surrogate
    v.unsafe_substring(start~, end~)
  }
}

///|
/// Removes characters from the ends of each string: with `chars = None` the
/// whitespace (see `str_is_space`), otherwise any character that occurs in
/// `chars` (a set of characters, not a prefix; an empty `chars` removes
/// nothing).
///
/// # Errors
/// `SchemaMismatch` for a column that is not `String`.
fn str_strip_chars(
  s : Series,
  chars : String?,
  side : StripSide,
) -> Series raise PolarsError {
  let a = str_array_unary(s)
  let out = match chars {
    None => str_str_result(a, v => str_strip_with(v, side, str_is_space))
    Some(set) => {
      let cps : Array[Int32] = []
      let mut i = 0
      while i < set.length() {
        let (cp, w) = str_cp_at(set, i)
        cps.push(cp)
        i += w
      }
      str_str_result(a, v => str_strip_with(v, side, cp => cps.contains(cp)))
    }
  }
  Series::make(s.name, String(out))
}
