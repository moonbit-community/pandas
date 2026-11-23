///|
/// Asserts the invariants of a freshly produced bitmap: offset 0 and no set
/// bit in the last word beyond `length`.
fn check_owned(b : Bitmap) -> Unit raise {
  assert_eq(b.offset, 0)
  assert_eq(b.words.length(), words_for(b.length))
  if b.length > 0 {
    let last = b.words[b.words.length() - 1]
    assert_eq(last & tail_mask(b.length).lnot(), 0UL)
  }
}

///|
/// Builds `n` parent bits where the window `[o, o + l)` follows `inside` and
/// every bit outside of it is `outside`, then returns the window as a slice.
fn dirty_window(
  n : Int32,
  o : Int32,
  l : Int32,
  outside : Bool,
  inside : (Int32) -> Bool,
) -> Bitmap {
  let bits = Array::makei(n, i => {
    if i >= o && i < o + l {
      inside(i - o)
    } else {
      outside
    }
  })
  Bitmap::from_array(bits).slice(o, l)
}

///|
test "bit_and / bit_or / bit_not with an all-ones parent and dirty surroundings" {
  let offsets = [0, 1, 5, 31, 32, 33, 62, 63, 64, 65, 100, 127, 128, 129]
  let lengths = [0, 1, 2, 31, 63, 64, 65, 100, 127, 128, 129, 191]
  for o in offsets {
    for l in lengths {
      let n = o + l + 70
      // the parent is all ones: the window is all ones, the surroundings are
      // dirty relative to an all-zero operand
      let ones = Bitmap::filled(n, true).slice(o, l)
      let zeros = dirty_window(n, o, l, true, _ => false)
      let pattern = dirty_window(n, o, l, true, i => i % 3 == 0)
      let pat_bits = Array::makei(l, i => i % 3 == 0)
      let one_bits = Array::make(l, true)
      let zero_bits = Array::make(l, false)
      // ones & ones, ones | zeros, ones & zeros ...
      let cases : Array[(Bitmap, Bitmap, Array[Bool], Array[Bool])] = [
        (ones, ones, one_bits, one_bits),
        (ones, zeros, one_bits, zero_bits),
        (zeros, ones, zero_bits, one_bits),
        (zeros, zeros, zero_bits, zero_bits),
        (ones, pattern, one_bits, pat_bits),
        (pattern, zeros, pat_bits, zero_bits),
        (pattern, pattern, pat_bits, pat_bits),
      ]
      for c in cases {
        let (x, y, xb, yb) = c
        let a = x.bit_and(y)
        let r = x.bit_or(y)
        assert_eq(a.to_array(), Array::makei(l, i => xb[i] && yb[i]))
        assert_eq(r.to_array(), Array::makei(l, i => xb[i] || yb[i]))
        assert_eq(a, Bitmap::from_array(Array::makei(l, i => xb[i] && yb[i])))
        assert_eq(r, Bitmap::from_array(Array::makei(l, i => xb[i] || yb[i])))
        assert_eq(a.length, l)
        assert_eq(r.length, l)
        // stale bits of the parents must not leak into the result
        check_owned(a)
        check_owned(r)
        assert_eq(
          a.count_ones(),
          xb.iter().zip(yb.iter()).filter(p => p.0 && p.1).count(),
        )
        assert_eq(
          r.count_ones(),
          xb.iter().zip(yb.iter()).filter(p => p.0 || p.1).count(),
        )
      }
      let nz = zeros.bit_not()
      check_owned(nz)
      assert_eq(nz.to_array(), one_bits)
      assert_eq(nz.count_ones(), l)
      assert_eq(ones.bit_not().count_ones(), 0)
      assert_eq(pattern.bit_not().to_array(), pat_bits.map(v => !v))
    }
  }
}

///|
test "bit_and / bit_or on slices whose parents differ in alignment" {
  // left window starts mid-word, right window starts at another bit of
  // another parent; both parents are all ones outside the window
  let l = 130
  let x = dirty_window(400, 37, l, true, i => i % 2 == 0)
  let y = dirty_window(400, 90, l, true, i => i % 5 != 0)
  let xb = Array::makei(l, i => i % 2 == 0)
  let yb = Array::makei(l, i => i % 5 != 0)
  assert_eq(x.bit_and(y).to_array(), Array::makei(l, i => xb[i] && yb[i]))
  assert_eq(x.bit_or(y).to_array(), Array::makei(l, i => xb[i] || yb[i]))
  check_owned(x.bit_and(y))
  check_owned(x.bit_or(y))
  check_owned(x.bit_not())
}

///|
test "BitmapBuilder::finish empties the builder and it can be reused" {
  let b = BitmapBuilder::new()
  for i in 0..<70 {
    b.push(true)
    ignore(i)
  }
  assert_eq(b.length(), 70)
  let first = b.finish()
  // the builder is empty again
  assert_eq(b.length(), 0)
  assert_eq(first.length(), 70)
  assert_eq(first.count_ones(), 70)
  // finishing an empty (reused) builder gives an empty bitmap
  let empty = b.finish()
  assert_eq(empty.length(), 0)
  assert_eq(empty, Bitmap::from_array([]))
  assert_eq(b.length(), 0)
  // pushing again starts from a clean state: no residue of the first run
  b.push(false)
  b.push(true)
  b.push(false)
  assert_eq(b.length(), 3)
  let second = b.finish()
  assert_eq(second.to_array(), [false, true, false])
  assert_eq(second.count_ones(), 1)
  check_owned(second)
  // the earlier result is untouched and shares no storage with the later one
  assert_eq(first.count_ones(), 70)
  assert_eq(first.length(), 70)
  assert_false(physical_equal(first.words, second.words))
  // the builder keeps working across the 64-bit word boundary after a reuse
  for i in 0..<130 {
    b.push(i % 2 == 0)
  }
  let third = b.finish()
  assert_eq(third, Bitmap::from_array(Array::makei(130, i => i % 2 == 0)))
  assert_eq(b.length(), 0)
  assert_eq(second.to_array(), [false, true, false])
}

///|
test "words_for and tail_mask" {
  assert_eq(words_for(0), 0)
  assert_eq(words_for(1), 1)
  assert_eq(words_for(64), 1)
  assert_eq(words_for(65), 2)
  assert_eq(words_for(128), 2)
  assert_eq(tail_mask(1), 1UL)
  assert_eq(tail_mask(63), 0x7FFFFFFFFFFFFFFFUL)
  assert_eq(tail_mask(64), 0xFFFFFFFFFFFFFFFFUL)
  assert_eq(tail_mask(65), 1UL)
}

///|
test "bit_not masks the tail when the parent is all zero outside the window" {
  // Outside the window the parent holds 0 bits, so the stale bits past the
  // end of the view are 0 and `lnot` turns them into 1: only the tail mask
  // keeps them out of the result.
  let offsets = [0, 1, 5, 31, 32, 33, 62, 63, 64, 65, 100, 127, 128, 129]
  let lengths = [0, 1, 2, 31, 63, 64, 65, 100, 127, 128, 129, 191]
  for o in offsets {
    for l in lengths {
      let n = o + l + 70
      let zeros = dirty_window(n, o, l, false, _ => false)
      let pattern = dirty_window(n, o, l, false, i => i % 3 == 0)
      let ones = dirty_window(n, o, l, false, _ => true)
      let nz = zeros.bit_not()
      check_owned(nz)
      assert_eq(nz.length, l)
      assert_eq(nz.count_ones(), l)
      assert_eq(nz.to_array(), Array::make(l, true))
      assert_eq(nz, Bitmap::filled(l, true))
      let np = pattern.bit_not()
      check_owned(np)
      assert_eq(np.to_array(), Array::makei(l, i => i % 3 != 0))
      assert_eq(np, Bitmap::from_array(Array::makei(l, i => i % 3 != 0)))
      let no = ones.bit_not()
      check_owned(no)
      assert_eq(no.count_ones(), 0)
      assert_eq(no.words.length(), words_for(l))
      // double negation gives the original window back
      assert_eq(nz.bit_not().count_ones(), 0)
      assert_eq(np.bit_not().to_array(), pattern.to_array())
    }
  }
  // a concrete case: 5 zero bits at offset 3 of a zero parent
  let w = Bitmap::from_array(Array::make(20, false)).slice(3, 5).bit_not()
  assert_eq(w.words, [0x1FUL])
}

///|
test "Bitmap::filled keeps the bits past the end of the last word clear" {
  for l in [0, 1, 2, 31, 63, 64, 65, 100, 127, 128, 129, 191] {
    let t = Bitmap::filled(l, true)
    check_owned(t)
    assert_eq(t.length, l)
    assert_eq(t.count_ones(), l)
    assert_eq(t.to_array(), Array::make(l, true))
    if l > 0 {
      let last = t.words[t.words.length() - 1]
      assert_eq(last, tail_mask(l))
    }
    let f = Bitmap::filled(l, false)
    check_owned(f)
    assert_eq(f.count_ones(), 0)
    for w in f.words {
      assert_eq(w, 0UL)
    }
  }
  // the raw words of a 5-bit all-true bitmap hold exactly 5 set bits
  assert_eq(Bitmap::filled(5, true).words, [0x1FUL])
  assert_eq(Bitmap::filled(65, true).words, [0xFFFFFFFFFFFFFFFFUL, 1UL])
}
