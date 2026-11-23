///|
/// White-box proofs that `slice` never copies: the result and the original
/// hold the very same backing storage (`physical_equal`), only the window
/// (`offset`, `length`) differs.
test "Bitmap::slice shares the words" {
  let b = Bitmap::from_array(Array::makei(200, i => i % 3 == 0))
  let s = b.slice(61, 70)
  assert_true(physical_equal(b.words, s.words))
  assert_eq(s.offset, 61)
  assert_eq(s.length, 70)
  // a slice of a slice still shares the original words
  let ss = s.slice(5, 10)
  assert_true(physical_equal(b.words, ss.words))
  assert_eq(ss.offset, 66)
  // empty and full windows too
  assert_true(physical_equal(b.words, b.slice(0, 0).words))
  assert_true(physical_equal(b.words, b.slice(0, 200).words))
  assert_true(physical_equal(b.words, b.slice(200, 0).words))
  // an owned result of an operation does NOT share (it is a new bitmap)
  assert_false(physical_equal(b.words, b.bit_not().words))
  assert_false(physical_equal(b.words, b.gather([0, 1]).words))
}

///|
test "PrimArray::slice shares the values and the validity words" {
  let a : PrimArray[Int64] = PrimArray::from_options([
    Some(1L),
    None,
    Some(3L),
    Some(4L),
    None,
  ])
  let s = a.slice(1, 3)
  assert_true(physical_equal(a.values, s.values))
  assert_eq(s.offset, 1)
  assert_eq(s.length, 3)
  match (a.validity, s.validity) {
    (Some(v), Some(sv)) => assert_true(physical_equal(v.words, sv.words))
    _ => fail("expected a validity bitmap on both arrays")
  }
  // slice of a slice
  let ss = s.slice(1, 2)
  assert_true(physical_equal(a.values, ss.values))
  assert_eq(ss.offset, 2)
  match (a.validity, ss.validity) {
    (Some(v), Some(sv)) => assert_true(physical_equal(v.words, sv.words))
    _ => fail("expected a validity bitmap on both arrays")
  }
  // an array without nulls
  let plain = PrimArray::from_array([1, 2, 3, 4])
  let ps = plain.slice(2, 2)
  assert_true(physical_equal(plain.values, ps.values))
  assert_true(ps.validity is None)
  // and an array built over a caller-owned FixedArray keeps that FixedArray
  let raw : FixedArray[Int32] = [10, 20, 30]
  let wrapped = PrimArray::new(raw, None)
  assert_true(physical_equal(raw, wrapped.values))
  assert_true(physical_equal(raw, wrapped.slice(1, 1).values))
  // gather is the copying operation, for contrast
  assert_false(physical_equal(plain.values, plain.gather([0, 1]).values))
}

///|
test "BoolArray::slice shares the values and the validity words" {
  let a = BoolArray::from_options([
    Some(true),
    None,
    Some(false),
    Some(true),
    None,
  ])
  let s = a.slice(1, 3)
  assert_true(physical_equal(a.values.words, s.values.words))
  assert_eq(s.values.offset, 1)
  assert_eq(s.values.length, 3)
  match (a.validity, s.validity) {
    (Some(v), Some(sv)) => {
      assert_true(physical_equal(v.words, sv.words))
      assert_eq(sv.offset, 1)
    }
    _ => fail("expected a validity bitmap on both arrays")
  }
  let ss = s.slice(2, 1)
  assert_true(physical_equal(a.values.words, ss.values.words))
  assert_eq(ss.values.offset, 3)
  // no nulls
  let plain = BoolArray::from_array([true, false, true])
  let ps = plain.slice(1, 2)
  assert_true(physical_equal(plain.values.words, ps.values.words))
  assert_true(ps.validity is None)
  assert_false(
    physical_equal(plain.values.words, plain.gather([0, 1]).values.words),
  )
}

///|
test "StrArray::slice shares the values and the validity words" {
  let a = StrArray::from_options([Some("a"), None, Some("c"), Some("d")])
  let s = a.slice(1, 2)
  assert_true(physical_equal(a.inner.values, s.inner.values))
  assert_eq(s.inner.offset, 1)
  assert_eq(s.inner.length, 2)
  match (a.inner.validity, s.inner.validity) {
    (Some(v), Some(sv)) => assert_true(physical_equal(v.words, sv.words))
    _ => fail("expected a validity bitmap on both arrays")
  }
  let ss = s.slice(1, 1)
  assert_true(physical_equal(a.inner.values, ss.inner.values))
  assert_eq(ss.inner.offset, 2)
  let plain = StrArray::from_array(["x", "y", "z"])
  assert_true(
    physical_equal(plain.inner.values, plain.slice(1, 1).inner.values),
  )
  assert_false(
    physical_equal(plain.inner.values, plain.gather([0, 1]).inner.values),
  )
}
