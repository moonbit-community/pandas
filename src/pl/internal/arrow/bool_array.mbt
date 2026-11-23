///|
/// Immutable array of booleans: a packed values bitmap plus an optional
/// validity bitmap, both covering the same logical range. The raw value of a
/// null slot is never observable through equality.
struct BoolArray {
  values : Bitmap
  validity : Bitmap?
}

///|
/// Creates an array from a values bitmap and an optional validity bitmap.
///
/// # Panics
/// Aborts when the validity length differs from the number of values.
pub fn BoolArray::new(values : Bitmap, validity : Bitmap?) -> BoolArray {
  if validity is Some(v) && v.length() != values.length() {
    abort(
      "BoolArray::new: validity length \{v.length()} differs from values length \{values.length()}",
    )
  }
  { values, validity, }
}

///|
/// Creates an array without nulls.
pub fn BoolArray::from_array(xs : Array[Bool]) -> BoolArray {
  BoolArray::new(Bitmap::from_array(xs), None)
}

///|
/// Creates an array from optional values; null slots hold `false`. The
/// validity bitmap is `None` when there is no null.
pub fn BoolArray::from_options(xs : Array[Bool?]) -> BoolArray {
  let b = BoolBuilder::new(capacity=xs.length())
  for x in xs {
    b.push_option(x)
  }
  b.finish()
}

///|
/// Number of slots (valid or null).
pub fn BoolArray::length(self : BoolArray) -> Int32 {
  self.values.length()
}

///|
/// Number of null slots.
pub fn BoolArray::null_count(self : BoolArray) -> Int32 {
  match self.validity {
    None => 0
    Some(v) => v.count_zeros()
  }
}

///|
/// The validity bitmap (sliced to this array), if any. `Some` does not imply
/// that a null exists after slicing; use `null_count` to decide.
pub fn BoolArray::validity(self : BoolArray) -> Bitmap? {
  self.validity
}

///|
fn BoolArray::check_index(self : BoolArray, i : Int32) -> Unit {
  guard i >= 0 && i < self.values.length() else {
    abort(
      "BoolArray: index \{i} out of bounds for length \{self.values.length()}",
    )
  }
}

///|
/// Whether slot `i` is non-null.
///
/// # Panics
/// Aborts when `i` is outside `[0, length)`.
pub fn BoolArray::is_valid(self : BoolArray, i : Int32) -> Bool {
  self.check_index(i)
  match self.validity {
    None => true
    Some(v) => v.get(i)
  }
}

///|
/// Raw value at slot `i`, ignoring validity.
///
/// # Panics
/// Aborts when `i` is outside `[0, length)`.
pub fn BoolArray::value(self : BoolArray, i : Int32) -> Bool {
  self.check_index(i)
  self.values.get(i)
}

///|
/// Value at slot `i`, or `None` for a null slot.
///
/// # Panics
/// Aborts when `i` is outside `[0, length)`.
pub fn BoolArray::get(self : BoolArray, i : Int32) -> Bool? {
  if self.is_valid(i) {
    Some(self.values.get(i))
  } else {
    None
  }
}

///|
/// Zero-copy view of `length` slots starting at `offset`.
///
/// # Panics
/// Aborts unless `0 <= offset`, `0 <= length` and `offset + length <= self.length`.
pub fn BoolArray::slice(
  self : BoolArray,
  offset : Int32,
  length : Int32,
) -> BoolArray {
  let n = self.values.length()
  guard offset >= 0 && length >= 0 && offset <= n - length else {
    abort(
      "BoolArray::slice: range (offset=\{offset}, length=\{length}) out of bounds for length \{n}",
    )
  }
  {
    values: self.values.slice(offset, length),
    validity: self.validity.map(v => v.slice(offset, length)),
  }
}

///|
/// New array whose slot `k` is slot `indices[k]` of `self`. The result has no
/// validity bitmap when it contains no null.
///
/// # Panics
/// Aborts when an index is outside `[0, length)`.
pub fn BoolArray::gather(self : BoolArray, indices : Array[Int32]) -> BoolArray {
  for i in indices {
    self.check_index(i)
  }
  let validity = match self.validity {
    None => None
    Some(v) => {
      let g = v.gather(indices)
      if g.count_zeros() == 0 {
        None
      } else {
        Some(g)
      }
    }
  }
  { values: self.values.gather(indices), validity, }
}

///|
/// All slots as options, in order.
pub fn BoolArray::to_options(self : BoolArray) -> Array[Bool?] {
  Array::makei(self.values.length(), i => self.get(i))
}

///|
/// Lazy iterator over the slots as options.
pub fn BoolArray::iter(self : BoolArray) -> Iter[Bool?] {
  let mut i = 0
  let n = self.values.length()
  Iter(
    fn() {
      guard i < n else { None }
      let v = self.get(i)
      i += 1
      Some(v)
    },
    size_hint=n,
  )
}

///|
/// Logical equality: same length, same null positions and equal values at
/// valid positions.
pub impl Eq for BoolArray with fn equal(self, other) {
  let n = self.values.length()
  guard n == other.values.length() else { return false }
  match (self.validity, other.validity) {
    (None, None) => self.values == other.values
    (Some(a), Some(b)) =>
      a == b && self.values.bit_and(a) == other.values.bit_and(b)
    (Some(a), None) =>
      a.count_zeros() == 0 && self.values.bit_and(a) == other.values
    (None, Some(b)) =>
      b.count_zeros() == 0 && self.values == other.values.bit_and(b)
  }
}

///|
/// Shows the logical elements (`None` for null).
pub impl Debug for BoolArray with fn to_repr(self) {
  @debug.Repr(self.to_options())
}

///|
/// Incremental builder for a `BoolArray`.
struct BoolBuilder {
  values : BitmapBuilder
  validity : BitmapBuilder
  mut has_null : Bool
}

///|
/// Creates a builder; `capacity` is a hint for the number of slots.
pub fn BoolBuilder::new(capacity~ : Int32 = 0) -> BoolBuilder {
  {
    values: BitmapBuilder::new(capacity~),
    validity: BitmapBuilder::new(capacity~),
    has_null: false,
  }
}

///|
/// Appends a valid value.
pub fn BoolBuilder::push(self : BoolBuilder, value : Bool) -> Unit {
  self.values.push(value)
  self.validity.push(true)
}

///|
/// Appends a null (the raw slot holds `false`).
pub fn BoolBuilder::push_null(self : BoolBuilder) -> Unit {
  self.values.push(false)
  self.validity.push(false)
  self.has_null = true
}

///|
/// Appends a value or a null.
pub fn BoolBuilder::push_option(self : BoolBuilder, value : Bool?) -> Unit {
  match value {
    Some(v) => self.push(v)
    None => self.push_null()
  }
}

///|
/// Number of slots pushed so far.
pub fn BoolBuilder::length(self : BoolBuilder) -> Int32 {
  self.values.length()
}

///|
/// Finishes the builder into an array (validity is `None` when nothing null
/// was pushed). The builder is left empty and may be reused.
pub fn BoolBuilder::finish(self : BoolBuilder) -> BoolArray {
  let values = self.values.finish()
  let bits = self.validity.finish()
  let validity = if self.has_null { Some(bits) } else { None }
  self.has_null = false
  { values, validity, }
}
