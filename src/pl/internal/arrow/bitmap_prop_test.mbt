///|
/// Maps arbitrary numbers to a legal (offset, length) pair inside `n` bits.
fn range_of(n : Int32, a : UInt32, b : UInt32) -> (Int32, Int32) {
  let o = (a % (n + 1).reinterpret_as_uint()).reinterpret_as_int()
  let l = (b % (n - o + 1).reinterpret_as_uint()).reinterpret_as_int()
  (o, l)
}

///|
/// Builds the bitmap for `bits` embedded between junk so that it is an
/// unaligned slice of a larger bitmap with stale bits around it.
fn embed(junk : Array[Bool], pre : Int32, bits : Array[Bool]) -> @arrow.Bitmap {
  let pre = pre % (junk.length() + 1)
  let all = []
  for i in 0..<pre {
    all.push(junk[i])
  }
  all.append(bits)
  for i in pre..<junk.length() {
    all.push(junk[i])
  }
  @arrow.Bitmap::from_array(all).slice(pre, bits.length())
}

///|
test "prop: from_array/to_array roundtrip" {
  @quickcheck.check(
    (xs : Array[Bool]) => @arrow.Bitmap::from_array(xs).to_array() == xs,
    count=300,
    max_size=400,
  )
}

///|
test "prop: slice equals array view" {
  @quickcheck.check(
    (t : (Array[Bool], UInt32, UInt32)) => {
      let (xs, a, b) = t
      let (o, l) = range_of(xs.length(), a, b)
      let s = @arrow.Bitmap::from_array(xs).slice(o, l)
      s.length() == l && s.to_array() == xs[o:o + l].to_owned()
    },
    count=500,
    max_size=400,
  )
}

///|
test "prop: bit_and / bit_or / bit_not match elementwise" {
  @quickcheck.check(
    (t : (Array[Bool], Array[Bool], UInt32, UInt32, UInt32)) => {
      let (xs, ys, a, b, c) = t
      let oa = (a % (xs.length() + 1).reinterpret_as_uint()).reinterpret_as_int()
      let ob = (b % (ys.length() + 1).reinterpret_as_uint()).reinterpret_as_int()
      let m = if xs.length() - oa < ys.length() - ob {
        xs.length() - oa
      } else {
        ys.length() - ob
      }
      let l = (c % (m + 1).reinterpret_as_uint()).reinterpret_as_int()
      let x = @arrow.Bitmap::from_array(xs).slice(oa, l)
      let y = @arrow.Bitmap::from_array(ys).slice(ob, l)
      let ex = xs[oa:oa + l].to_owned()
      let ey = ys[ob:ob + l].to_owned()
      x.bit_and(y).to_array() == Array::makei(l, i => ex[i] && ey[i]) &&
      x.bit_or(y).to_array() == Array::makei(l, i => ex[i] || ey[i]) &&
      x.bit_not().to_array() == ex.map(v => !v) &&
      x.bit_and(y).length() == l &&
      x.bit_not().count_ones() == l - x.count_ones()
    },
    count=500,
    max_size=400,
  )
}

///|
test "prop: count_ones is number of true" {
  @quickcheck.check(
    (t : (Array[Bool], UInt32, UInt32)) => {
      let (xs, a, b) = t
      let (o, l) = range_of(xs.length(), a, b)
      let s = @arrow.Bitmap::from_array(xs).slice(o, l)
      let n = xs[o:o + l].iter().filter(x => x).count()
      s.count_ones() == n && s.count_zeros() == l - n
    },
    count=500,
    max_size=400,
  )
}

///|
test "prop: equality is logical" {
  @quickcheck.check(
    (t : (Array[Bool], Array[Bool], UInt32, UInt32, UInt32, UInt32)) => {
      let (bits, junk, mode, pa, pb, flip) = t
      let k = (mode % 3).reinterpret_as_int()
      // a: bits embedded in junk. b: variant of bits embedded elsewhere.
      let other : Array[Bool] = match k {
        0 => bits.copy()
        1 =>
          if bits.length() == 0 {
            []
          } else {
            let c = bits.copy()
            let j = (flip % bits.length().reinterpret_as_uint()).reinterpret_as_int()
            c[j] = !c[j]
            c
          }
        _ =>
          if junk.length() == 0 {
            Array::make(bits.length(), false)
          } else {
            Array::makei(bits.length(), i => junk[i % junk.length()])
          }
      }
      let a = embed(junk, (pa % 1000).reinterpret_as_int(), bits)
      let b = embed(junk.map(v => !v), (pb % 1000).reinterpret_as_int(), other)
      (a == b) == (a.to_array() == b.to_array())
    },
    count=500,
    max_size=300,
  )
}

///|
test "prop: equal bitmaps with different offsets and stale bits" {
  @quickcheck.check(
    (t : (Array[Bool], Array[Bool], UInt32, UInt32)) => {
      let (bits, junk, pa, pb) = t
      let a = embed(junk, (pa % 1000).reinterpret_as_int(), bits)
      let b = embed(junk.map(v => !v), (pb % 1000).reinterpret_as_int(), bits)
      a == b && a.count_ones() == b.count_ones()
    },
    count=500,
    max_size=300,
  )
}

///|
test "prop: builder equals from_array" {
  @quickcheck.check(
    (t : (Array[Bool], UInt32)) => {
      let (xs, cap) = t
      let b = @arrow.BitmapBuilder::new(
        capacity=(cap % 500).reinterpret_as_int(),
      )
      for x in xs {
        b.push(x)
      }
      b.length() == xs.length() && b.finish() == @arrow.Bitmap::from_array(xs)
    },
    count=300,
    max_size=400,
  )
}

///|
test "prop: gather matches indexing" {
  @quickcheck.check(
    (t : (Array[Bool], UInt32, UInt32, Array[UInt32])) => {
      let (xs, a, b, raw) = t
      let (o, l) = range_of(xs.length(), a, b)
      guard l > 0 else { true }
      let idx = raw.map(r => (r % l.reinterpret_as_uint()).reinterpret_as_int())
      let s = @arrow.Bitmap::from_array(xs).slice(o, l)
      s.gather(idx).to_array() == idx.map(i => xs[o + i])
    },
    count=500,
    max_size=400,
  )
}
