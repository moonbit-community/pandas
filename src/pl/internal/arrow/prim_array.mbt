///|
/// Immutable array of primitive values with an optional validity bitmap.
///
/// The array is a view `[offset, offset + length)` over a shared
/// `FixedArray[T]`; `validity` (when present) is already sliced to the same
/// logical range, so logical index `i` maps to `values[offset + i]` and
/// `validity[i]`. A null slot holds an arbitrary raw value that is never
/// observable through equality.
struct PrimArray[T] {
  values : FixedArray[T]
  offset : Int32
  length : Int32
  validity : Bitmap?
}

///|
/// Creates an array from raw values and an optional validity bitmap.
///
/// # Panics
/// Aborts when the validity length differs from the number of values.
pub fn[T] PrimArray::new(
  values : FixedArray[T],
  validity : Bitmap?,
) -> PrimArray[T] {
  if validity is Some(v) && v.length() != values.length() {
    abort(
      "PrimArray::new: validity length \{v.length()} differs from values length \{values.length()}",
    )
  }
  { values, offset: 0, length: values.length(), validity, }
}

///|
/// Creates an array without nulls.
pub fn[T] PrimArray::from_array(xs : Array[T]) -> PrimArray[T] {
  PrimArray::new(FixedArray::from_array(xs), None)
}

///|
/// Creates an array from optional values; null slots hold `T::default()`.
/// The validity bitmap is `None` when there is no null.
pub fn[T : Default] PrimArray::from_options(xs : Array[T?]) -> PrimArray[T] {
  let b = PrimBuilder::new(capacity=xs.length())
  for x in xs {
    b.push_option(x)
  }
  b.finish()
}

///|
/// Number of slots (valid or null).
pub fn[T] PrimArray::length(self : PrimArray[T]) -> Int32 {
  self.length
}

///|
/// Number of null slots.
pub fn[T] PrimArray::null_count(self : PrimArray[T]) -> Int32 {
  match self.validity {
    None => 0
    Some(v) => v.count_zeros()
  }
}

///|
/// The validity bitmap (sliced to this array), if any. `Some` does not imply
/// that a null exists after slicing; use `null_count` to decide.
pub fn[T] PrimArray::validity(self : PrimArray[T]) -> Bitmap? {
  self.validity
}

///|
fn[T] PrimArray::check_index(self : PrimArray[T], i : Int32) -> Unit {
  guard i >= 0 && i < self.length else {
    abort("PrimArray: index \{i} out of bounds for length \{self.length}")
  }
}

///|
/// Whether slot `i` is non-null.
///
/// # Panics
/// Aborts when `i` is outside `[0, length)`.
pub fn[T] PrimArray::is_valid(self : PrimArray[T], i : Int32) -> Bool {
  self.check_index(i)
  match self.validity {
    None => true
    Some(v) => v.get(i)
  }
}

///|
/// Raw value at slot `i`, ignoring validity (a null slot yields an arbitrary
/// raw value).
///
/// # Panics
/// Aborts when `i` is outside `[0, length)`.
pub fn[T] PrimArray::value(self : PrimArray[T], i : Int32) -> T {
  self.check_index(i)
  self.values[self.offset + i]
}

///|
/// Value at slot `i`, or `None` for a null slot.
///
/// # Panics
/// Aborts when `i` is outside `[0, length)`.
pub fn[T] PrimArray::get(self : PrimArray[T], i : Int32) -> T? {
  if self.is_valid(i) {
    Some(self.values[self.offset + i])
  } else {
    None
  }
}

///|
/// Zero-copy view of `length` slots starting at `offset`.
///
/// # Panics
/// Aborts unless `0 <= offset`, `0 <= length` and `offset + length <= self.length`.
pub fn[T] PrimArray::slice(
  self : PrimArray[T],
  offset : Int32,
  length : Int32,
) -> PrimArray[T] {
  guard offset >= 0 && length >= 0 && offset <= self.length - length else {
    abort(
      "PrimArray::slice: range (offset=\{offset}, length=\{length}) out of bounds for length \{self.length}",
    )
  }
  {
    values: self.values,
    offset: self.offset + offset,
    length,
    validity: self.validity.map(v => v.slice(offset, length)),
  }
}

///|
/// New array whose slot `k` is slot `indices[k]` of `self`. The result has no
/// validity bitmap when it contains no null.
///
/// # Panics
/// Aborts when an index is outside `[0, length)`.
pub fn[T] PrimArray::gather(
  self : PrimArray[T],
  indices : Array[Int32],
) -> PrimArray[T] {
  for i in indices {
    self.check_index(i)
  }
  let values = FixedArray::makei(indices.length(), k => {
    self.values[self.offset + indices[k]]
  })
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
  { values, offset: 0, length: indices.length(), validity, }
}

///|
/// All slots as options, in order.
pub fn[T] PrimArray::to_options(self : PrimArray[T]) -> Array[T?] {
  Array::makei(self.length, i => self.get(i))
}

///|
/// Lazy iterator over the slots as options.
pub fn[T] PrimArray::iter(self : PrimArray[T]) -> Iter[T?] {
  let mut i = 0
  Iter(
    fn() {
      guard i < self.length else { None }
      let v = self.get(i)
      i += 1
      Some(v)
    },
    size_hint=self.length,
  )
}

///|
/// Logical equality: same length, same null positions and equal values at
/// valid positions (raw values of null slots are ignored). Values are compared
/// with `T`'s own `==`, so a floating-point NaN is not equal to itself.
pub impl[T : Eq] Eq for PrimArray[T] with fn equal(self, other) {
  guard self.length == other.length else { return false }
  for i in 0..<self.length {
    let va = self.is_valid(i)
    guard va == other.is_valid(i) else { return false }
    if va && self.values[self.offset + i] != other.values[other.offset + i] {
      return false
    }
  }
  true
}

///|
/// Shows the logical elements (`None` for null).
pub impl[T : Debug] Debug for PrimArray[T] with fn to_repr(self) {
  @debug.Repr(self.to_options())
}

///|
/// Incremental builder for a `PrimArray[T]`.
struct PrimBuilder[T] {
  mut values : Array[T]
  validity : BitmapBuilder
  default : T
  mut has_null : Bool
}

///|
/// Creates a builder; `capacity` is a hint for the number of slots.
pub fn[T : Default] PrimBuilder::new(capacity~ : Int32 = 0) -> PrimBuilder[T] {
  let cap = if capacity > 0 { capacity } else { 0 }
  {
    values: Array(capacity=cap),
    validity: BitmapBuilder::new(capacity=cap),
    default: T::default(),
    has_null: false,
  }
}

///|
/// Appends a valid value.
pub fn[T] PrimBuilder::push(self : PrimBuilder[T], value : T) -> Unit {
  self.values.push(value)
  self.validity.push(true)
}

///|
/// Appends a null (the raw slot holds `T::default()`).
pub fn[T] PrimBuilder::push_null(self : PrimBuilder[T]) -> Unit {
  self.values.push(self.default)
  self.validity.push(false)
  self.has_null = true
}

///|
/// Appends a value or a null.
pub fn[T] PrimBuilder::push_option(self : PrimBuilder[T], value : T?) -> Unit {
  match value {
    Some(v) => self.push(v)
    None => self.push_null()
  }
}

///|
/// Number of slots pushed so far.
pub fn[T] PrimBuilder::length(self : PrimBuilder[T]) -> Int32 {
  self.values.length()
}

///|
/// Finishes the builder into an array (validity is `None` when nothing null
/// was pushed). The builder is left empty and may be reused.
pub fn[T] PrimBuilder::finish(self : PrimBuilder[T]) -> PrimArray[T] {
  let values = FixedArray::from_array(self.values)
  let bits = self.validity.finish()
  let validity = if self.has_null { Some(bits) } else { None }
  self.values = []
  self.has_null = false
  { values, offset: 0, length: values.length(), validity, }
}
