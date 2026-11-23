///|
test "slice is zero copy view with logical equality" {
  let xs = Array::makei(200, i => i % 3 == 0)
  let b = @arrow.Bitmap::from_array(xs)
  let s = b.slice(61, 70)
  assert_eq(s.length(), 70)
  assert_eq(s.to_array(), xs[61:131].to_owned())
  assert_eq(s, @arrow.Bitmap::from_array(xs[61:131].to_owned()))
  assert_eq(s.count_ones(), xs[61:131].iter().filter(x => x).count())
}

///|
test "ops on unaligned slices" {
  let a = @arrow.Bitmap::filled(130, true).slice(3, 100)
  let b = @arrow.Bitmap::from_array(Array::makei(150, i => i % 2 == 0)).slice(
    37, 100,
  )
  assert_eq(a.bit_and(b).to_array(), Array::makei(100, i => (i + 37) % 2 == 0))
  assert_eq(b.bit_not().count_ones(), 50)
}

///|
test "empty bitmap" {
  let e = @arrow.Bitmap::from_array([])
  assert_eq(e.length(), 0)
  assert_eq(e.count_ones(), 0)
  assert_eq(e.bit_not().length(), 0)
}

///|
test "filled, counts and get" {
  let t = @arrow.Bitmap::filled(130, true)
  assert_eq(t.length(), 130)
  assert_eq(t.count_ones(), 130)
  assert_eq(t.count_zeros(), 0)
  let f = @arrow.Bitmap::filled(130, false)
  assert_eq(f.count_ones(), 0)
  assert_eq(f.count_zeros(), 130)
  assert_eq(f.bit_not().count_ones(), 130)
  assert_eq(t.get(0), true)
  assert_eq(t.get(129), true)
  assert_eq(f.get(64), false)
  assert_eq(@arrow.Bitmap::filled(0, true).length(), 0)
}

///|
test "stale bits outside the slice do not affect count or equality" {
  // The parent is all ones; slices cut out of it expose stale 1 bits around.
  let parent = @arrow.Bitmap::filled(256, true)
  let s = parent.slice(5, 60)
  assert_eq(s.count_ones(), 60)
  assert_eq(s.bit_not().count_ones(), 0)
  assert_eq(s, @arrow.Bitmap::filled(60, true))
  assert_eq(s == @arrow.Bitmap::filled(60, false), false)
  assert_eq(s == @arrow.Bitmap::filled(61, true), false)
}

///|
test "slice of slice and boundary lengths" {
  let xs = Array::makei(300, i => i % 5 < 2)
  let b = @arrow.Bitmap::from_array(xs)
  for n in [0, 1, 63, 64, 65, 127, 128, 129, 300] {
    let s = b.slice(0, n)
    assert_eq(s.to_array(), xs[0:n].to_owned())
    assert_eq(s.bit_not().count_ones(), n - s.count_ones())
  }
  let s2 = b.slice(10, 200).slice(55, 100)
  assert_eq(s2.to_array(), xs[65:165].to_owned())
  assert_eq(b.slice(300, 0).length(), 0)
}

///|
test "bit_or and bit_not on unaligned slices" {
  let xs = Array::makei(200, i => i % 3 == 0)
  let ys = Array::makei(230, i => i % 7 < 3)
  let a = @arrow.Bitmap::from_array(xs).slice(1, 150)
  let b = @arrow.Bitmap::from_array(ys).slice(66, 150)
  assert_eq(
    a.bit_or(b).to_array(),
    Array::makei(150, i => xs[1 + i] || ys[66 + i]),
  )
  assert_eq(a.bit_not().to_array(), Array::makei(150, i => !xs[1 + i]))
  // results have offset 0 and are clean
  assert_eq(a.bit_not().bit_not(), a)
}

///|
test "gather" {
  let xs = Array::makei(200, i => i % 3 == 0)
  let s = @arrow.Bitmap::from_array(xs).slice(10, 150)
  let idx = [149, 0, 64, 63, 5, 5, 100]
  assert_eq(s.gather(idx).to_array(), idx.map(i => xs[10 + i]))
  assert_eq(s.gather([]).length(), 0)
}

///|
test "builder" {
  let b = @arrow.BitmapBuilder::new()
  assert_eq(b.length(), 0)
  let xs = Array::makei(130, i => i % 4 == 1)
  for x in xs {
    b.push(x)
  }
  assert_eq(b.length(), 130)
  let bm = b.finish()
  assert_eq(bm.to_array(), xs)
  assert_eq(bm, @arrow.Bitmap::from_array(xs))
  let c = @arrow.BitmapBuilder::new(capacity=1000)
  assert_eq(c.finish(), @arrow.Bitmap::from_array([]))
}

///|
test "iter and debug" {
  let b = @arrow.Bitmap::from_array([true, false, true])
  assert_eq(b.iter().to_array(), [true, false, true])
  assert_eq(b.slice(1, 2).iter().to_array(), [false, true])
  assert_eq(@arrow.Bitmap::from_array([]).iter().to_array(), [])
  debug_inspect(b, content="[true, false, true]")
}

///|
test "large bitmap word-level ops stay correct" {
  let n = 1_000_003
  let len = n - 20
  let a = @arrow.Bitmap::filled(n, true).slice(7, len)
  let b = @arrow.Bitmap::from_array(Array::makei(n, i => i % 2 == 0)).slice(
    13, len,
  )
  assert_eq(a.bit_and(b).count_ones(), b.count_ones())
  assert_eq(a.bit_or(b).count_ones(), len)
  assert_eq(b.bit_not().count_ones() + b.count_ones(), len)
  assert_eq(a.bit_and(b), b)
}

///|
test "panic get out of bounds" {
  ignore(@arrow.Bitmap::filled(10, true).get(10))
}

///|
test "panic get negative" {
  ignore(@arrow.Bitmap::filled(10, true).get(-1))
}

///|
test "panic slice out of range" {
  ignore(@arrow.Bitmap::filled(10, true).slice(5, 6))
}

///|
test "panic slice negative offset" {
  ignore(@arrow.Bitmap::filled(10, true).slice(-1, 2))
}

///|
test "panic slice huge length no overflow" {
  ignore(@arrow.Bitmap::filled(10, true).slice(5, 2147483647))
}

///|
test "panic bit_and length mismatch" {
  ignore(
    @arrow.Bitmap::filled(10, true).bit_and(@arrow.Bitmap::filled(9, true)),
  )
}

///|
test "panic bit_or length mismatch" {
  ignore(
    @arrow.Bitmap::filled(10, true).bit_or(@arrow.Bitmap::filled(11, true)),
  )
}

///|
test "panic gather out of range" {
  ignore(@arrow.Bitmap::filled(10, true).gather([0, 10]))
}

///|
test "panic gather negative" {
  ignore(@arrow.Bitmap::filled(10, true).gather([-1]))
}

///|
test "panic filled negative length" {
  ignore(@arrow.Bitmap::filled(-1, true))
}
