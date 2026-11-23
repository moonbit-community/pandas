///|
/// Packed validity/boolean bitmap: bit 1 means true (valid).
///
/// Backed by a `FixedArray[UInt64]` shared between slices. A bitmap is a view
/// `[offset, offset + length)` over the words; bits outside the view may hold
/// stale data and are never observable (counting, equality and all operations
/// mask them out). Bit `i` of the view lives at bit `(offset + i) % 64` of word
/// `(offset + i) / 64`.
struct Bitmap {
  words : FixedArray[UInt64]
  offset : Int32
  length : Int32
}

///|
let all_ones : UInt64 = 0xFFFFFFFFFFFFFFFFUL

///|
/// Number of 64-bit words needed to hold `n` bits.
fn words_for(n : Int32) -> Int32 {
  (n + 63) >> 6
}

///|
/// Mask selecting the valid bits of the last word of an `n`-bit bitmap.
fn tail_mask(n : Int32) -> UInt64 {
  let r = n & 63
  if r == 0 {
    all_ones
  } else {
    (1UL << r) - 1UL
  }
}

///|
/// The `i`-th logical word of the view: bits `[64i, 64i + 64)` of the bitmap,
/// re-aligned to bit 0. Bits past `length` are unspecified (may be stale), so
/// callers must mask the last word with `tail_mask`.
fn Bitmap::word_at(self : Bitmap, i : Int32) -> UInt64 {
  let bit = self.offset + (i << 6)
  let w = bit >> 6
  let s = bit & 63
  let lo = self.words[w] >> s
  if s == 0 || w + 1 >= self.words.length() {
    lo
  } else {
    lo | (self.words[w + 1] << (64 - s))
  }
}

///|
/// Like `word_at`, but with bits past `length` cleared.
fn Bitmap::clean_word(self : Bitmap, i : Int32, nwords : Int32) -> UInt64 {
  let w = self.word_at(i)
  if i == nwords - 1 {
    w & tail_mask(self.length)
  } else {
    w
  }
}

///|
/// Creates a bitmap from booleans (`true` = bit set).
pub fn Bitmap::from_array(xs : Array[Bool]) -> Bitmap {
  let n = xs.length()
  let words = FixedArray::make(words_for(n), 0UL)
  for i in 0..<n {
    if xs[i] {
      words[i >> 6] = words[i >> 6] | (1UL << (i & 63))
    }
  }
  { words, offset: 0, length: n, }
}

///|
/// Creates a bitmap of `length` bits, all set to `value`.
///
/// # Panics
/// Aborts when `length` is negative.
pub fn Bitmap::filled(length : Int32, value : Bool) -> Bitmap {
  guard length >= 0 else { abort("Bitmap::filled: negative length") }
  let nwords = words_for(length)
  let words = FixedArray::make(nwords, if value { all_ones } else { 0UL })
  if value && nwords > 0 {
    words[nwords - 1] = tail_mask(length)
  }
  { words, offset: 0, length, }
}

///|
/// Number of bits in the bitmap.
pub fn Bitmap::length(self : Bitmap) -> Int32 {
  self.length
}

///|
/// Returns bit `i`.
///
/// # Panics
/// Aborts when `i` is outside `[0, length)`.
pub fn Bitmap::get(self : Bitmap, i : Int32) -> Bool {
  guard i >= 0 && i < self.length else {
    abort("Bitmap::get: index \{i} out of bounds for length \{self.length}")
  }
  let bit = self.offset + i
  ((self.words[bit >> 6] >> (bit & 63)) & 1UL) != 0UL
}

///|
/// Number of set bits.
pub fn Bitmap::count_ones(self : Bitmap) -> Int32 {
  let nwords = words_for(self.length)
  let mut n = 0
  for i in 0..<nwords {
    n += self.clean_word(i, nwords).popcnt()
  }
  n
}

///|
/// Number of cleared bits.
pub fn Bitmap::count_zeros(self : Bitmap) -> Int32 {
  self.length - self.count_ones()
}

///|
/// Zero-copy view of `length` bits starting at `offset`; shares the underlying
/// words.
///
/// # Panics
/// Aborts unless `0 <= offset`, `0 <= length` and `offset + length <= self.length`.
pub fn Bitmap::slice(self : Bitmap, offset : Int32, length : Int32) -> Bitmap {
  guard offset >= 0 && length >= 0 && offset <= self.length - length else {
    abort(
      "Bitmap::slice: range (offset=\{offset}, length=\{length}) out of bounds for length \{self.length}",
    )
  }
  { words: self.words, offset: self.offset + offset, length, }
}

///|
fn Bitmap::zip_words(
  self : Bitmap,
  other : Bitmap,
  name : String,
  f : (UInt64, UInt64) -> UInt64,
) -> Bitmap {
  guard self.length == other.length else {
    abort(
      "Bitmap::\{name}: length mismatch (\{self.length} vs \{other.length})",
    )
  }
  let nwords = words_for(self.length)
  let words = FixedArray::make(nwords, 0UL)
  for i in 0..<nwords {
    words[i] = f(self.word_at(i), other.word_at(i))
  }
  if nwords > 0 {
    words[nwords - 1] = words[nwords - 1] & tail_mask(self.length)
  }
  { words, offset: 0, length: self.length, }
}

///|
/// Bitwise AND of two equal-length bitmaps; the result has offset 0.
///
/// # Panics
/// Aborts when the lengths differ.
pub fn Bitmap::bit_and(self : Bitmap, other : Bitmap) -> Bitmap {
  self.zip_words(other, "bit_and", (a, b) => a & b)
}

///|
/// Bitwise OR of two equal-length bitmaps; the result has offset 0.
///
/// # Panics
/// Aborts when the lengths differ.
pub fn Bitmap::bit_or(self : Bitmap, other : Bitmap) -> Bitmap {
  self.zip_words(other, "bit_or", (a, b) => a | b)
}

///|
/// Bitwise NOT; the result has offset 0.
pub fn Bitmap::bit_not(self : Bitmap) -> Bitmap {
  let nwords = words_for(self.length)
  let words = FixedArray::make(nwords, 0UL)
  for i in 0..<nwords {
    words[i] = self.word_at(i).lnot()
  }
  if nwords > 0 {
    words[nwords - 1] = words[nwords - 1] & tail_mask(self.length)
  }
  { words, offset: 0, length: self.length, }
}

///|
/// New bitmap whose bit `k` is bit `indices[k]` of `self`.
///
/// # Panics
/// Aborts when an index is outside `[0, length)`.
pub fn Bitmap::gather(self : Bitmap, indices : Array[Int32]) -> Bitmap {
  let n = indices.length()
  let words = FixedArray::make(words_for(n), 0UL)
  for k in 0..<n {
    let i = indices[k]
    guard i >= 0 && i < self.length else {
      abort(
        "Bitmap::gather: index \{i} out of bounds for length \{self.length}",
      )
    }
    let bit = self.offset + i
    if ((self.words[bit >> 6] >> (bit & 63)) & 1UL) != 0UL {
      words[k >> 6] = words[k >> 6] | (1UL << (k & 63))
    }
  }
  { words, offset: 0, length: n, }
}

///|
/// Booleans of the bitmap, in order.
pub fn Bitmap::to_array(self : Bitmap) -> Array[Bool] {
  Array::makei(self.length, i => {
    let bit = self.offset + i
    ((self.words[bit >> 6] >> (bit & 63)) & 1UL) != 0UL
  })
}

///|
/// Lazy iterator over the booleans of the bitmap.
pub fn Bitmap::iter(self : Bitmap) -> Iter[Bool] {
  let mut i = 0
  Iter(
    fn() {
      guard i < self.length else { None }
      let bit = self.offset + i
      i += 1
      Some(((self.words[bit >> 6] >> (bit & 63)) & 1UL) != 0UL)
    },
    size_hint=self.length,
  )
}

///|
/// Logical equality: same length and same bits, regardless of offset or of
/// stale bits outside the view.
pub impl Eq for Bitmap with fn equal(self, other) {
  guard self.length == other.length else { return false }
  let nwords = words_for(self.length)
  for i in 0..<nwords {
    if self.clean_word(i, nwords) != other.clean_word(i, nwords) {
      return false
    }
  }
  true
}

///|
/// Shows the logical bits of the view.
pub impl Debug for Bitmap with fn to_repr(self) {
  @debug.Repr(self.to_array())
}

///|
/// Incremental builder for a `Bitmap`.
struct BitmapBuilder {
  mut words : Array[UInt64]
  mut length : Int32
}

///|
/// Creates a builder; `capacity` is a hint for the number of bits.
pub fn BitmapBuilder::new(capacity~ : Int32 = 0) -> BitmapBuilder {
  let cap = if capacity > 0 { capacity } else { 0 }
  { words: Array(capacity=words_for(cap)), length: 0, }
}

///|
/// Appends one bit.
pub fn BitmapBuilder::push(self : BitmapBuilder, value : Bool) -> Unit {
  let n = self.length
  if (n & 63) == 0 {
    self.words.push(0UL)
  }
  if value {
    let w = n >> 6
    self.words[w] = self.words[w] | (1UL << (n & 63))
  }
  self.length = n + 1
}

///|
/// Number of bits pushed so far.
pub fn BitmapBuilder::length(self : BitmapBuilder) -> Int32 {
  self.length
}

///|
/// Finishes the builder into a `Bitmap` (offset 0). The builder is left empty
/// and may be reused.
pub fn BitmapBuilder::finish(self : BitmapBuilder) -> Bitmap {
  let n = self.length
  let src = self.words
  let words = FixedArray::makei(src.length(), i => src[i])
  self.words = []
  self.length = 0
  { words, offset: 0, length: n, }
}
