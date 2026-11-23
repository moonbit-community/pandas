///|
/// Immutable array of strings with an optional validity bitmap. Slicing is
/// zero-copy. A null slot holds `""` as its raw value, which is never
/// observable through equality.
struct StrArray {
  inner : PrimArray[String]
}

///|
/// Creates an array from raw values and an optional validity bitmap.
///
/// # Panics
/// Aborts when the validity length differs from the number of values.
pub fn StrArray::new(
  values : FixedArray[String],
  validity : Bitmap?,
) -> StrArray {
  { inner: PrimArray::new(values, validity), }
}

///|
/// Creates an array without nulls.
pub fn StrArray::from_array(xs : Array[String]) -> StrArray {
  { inner: PrimArray::from_array(xs), }
}

///|
/// Creates an array from optional values; null slots hold `""`. The validity
/// bitmap is `None` when there is no null.
pub fn StrArray::from_options(xs : Array[String?]) -> StrArray {
  { inner: PrimArray::from_options(xs), }
}

///|
/// Number of slots (valid or null).
pub fn StrArray::length(self : StrArray) -> Int32 {
  self.inner.length()
}

///|
/// Number of null slots.
pub fn StrArray::null_count(self : StrArray) -> Int32 {
  self.inner.null_count()
}

///|
/// The validity bitmap (sliced to this array), if any. `Some` does not imply
/// that a null exists after slicing; use `null_count` to decide.
pub fn StrArray::validity(self : StrArray) -> Bitmap? {
  self.inner.validity()
}

///|
/// Whether slot `i` is non-null.
///
/// # Panics
/// Aborts when `i` is outside `[0, length)`.
pub fn StrArray::is_valid(self : StrArray, i : Int32) -> Bool {
  self.inner.is_valid(i)
}

///|
/// Raw value at slot `i`, ignoring validity.
///
/// # Panics
/// Aborts when `i` is outside `[0, length)`.
pub fn StrArray::value(self : StrArray, i : Int32) -> String {
  self.inner.value(i)
}

///|
/// Value at slot `i`, or `None` for a null slot.
///
/// # Panics
/// Aborts when `i` is outside `[0, length)`.
pub fn StrArray::get(self : StrArray, i : Int32) -> String? {
  self.inner.get(i)
}

///|
/// Zero-copy view of `length` slots starting at `offset`.
///
/// # Panics
/// Aborts unless `0 <= offset`, `0 <= length` and `offset + length <= self.length`.
pub fn StrArray::slice(
  self : StrArray,
  offset : Int32,
  length : Int32,
) -> StrArray {
  { inner: self.inner.slice(offset, length), }
}

///|
/// New array whose slot `k` is slot `indices[k]` of `self`. The result has no
/// validity bitmap when it contains no null.
///
/// # Panics
/// Aborts when an index is outside `[0, length)`.
pub fn StrArray::gather(self : StrArray, indices : Array[Int32]) -> StrArray {
  { inner: self.inner.gather(indices), }
}

///|
/// All slots as options, in order.
pub fn StrArray::to_options(self : StrArray) -> Array[String?] {
  self.inner.to_options()
}

///|
/// Lazy iterator over the slots as options.
pub fn StrArray::iter(self : StrArray) -> Iter[String?] {
  self.inner.iter()
}

///|
/// Logical equality: same length, same null positions and equal strings at
/// valid positions.
pub impl Eq for StrArray with fn equal(self, other) {
  self.inner == other.inner
}

///|
/// Shows the logical elements (`None` for null).
pub impl Debug for StrArray with fn to_repr(self) {
  @debug.Repr(self.to_options())
}

///|
/// Incremental builder for a `StrArray`.
struct StrBuilder {
  inner : PrimBuilder[String]
}

///|
/// Creates a builder; `capacity` is a hint for the number of slots.
pub fn StrBuilder::new(capacity~ : Int32 = 0) -> StrBuilder {
  { inner: PrimBuilder::new(capacity~), }
}

///|
/// Appends a valid string.
pub fn StrBuilder::push(self : StrBuilder, value : String) -> Unit {
  self.inner.push(value)
}

///|
/// Appends a null (the raw slot holds `""`).
pub fn StrBuilder::push_null(self : StrBuilder) -> Unit {
  self.inner.push_null()
}

///|
/// Appends a string or a null.
pub fn StrBuilder::push_option(self : StrBuilder, value : String?) -> Unit {
  self.inner.push_option(value)
}

///|
/// Number of slots pushed so far.
pub fn StrBuilder::length(self : StrBuilder) -> Int32 {
  self.inner.length()
}

///|
/// Finishes the builder into an array (validity is `None` when nothing null
/// was pushed). The builder is left empty and may be reused.
pub fn StrBuilder::finish(self : StrBuilder) -> StrArray {
  { inner: self.inner.finish(), }
}
