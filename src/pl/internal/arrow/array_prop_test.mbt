///|
/// Maps arbitrary numbers to a legal (offset, length) pair inside `n` items.
fn arr_range(n : Int32, a : UInt32, b : UInt32) -> (Int32, Int32) {
  let o = (a % (n + 1).reinterpret_as_uint()).reinterpret_as_int()
  let l = (b % (n - o + 1).reinterpret_as_uint()).reinterpret_as_int()
  (o, l)
}

///|
/// Maps arbitrary numbers to indices valid for `n` items (needs n > 0).
fn arr_indices(n : Int32, raw : Array[UInt32]) -> Array[Int32] {
  raw.map(r => (r % n.reinterpret_as_uint()).reinterpret_as_int())
}

///|
test "prop: prim from_options/to_options roundtrip" {
  @quickcheck.check(
    (xs : Array[Int64?]) => {
      @arrow.PrimArray::from_options(xs).to_options() == xs
    },
    count=300,
    max_size=200,
  )
}

///|
test "prop: prim slice of slice" {
  @quickcheck.check(
    (t : (Array[Int64?], UInt32, UInt32, UInt32, UInt32)) => {
      let (xs, a, b, c, d) = t
      let arr = @arrow.PrimArray::from_options(xs)
      let (o1, l1) = arr_range(xs.length(), a, b)
      let (o2, l2) = arr_range(l1, c, d)
      let nested = arr.slice(o1, l1).slice(o2, l2)
      let direct = arr.slice(o1 + o2, l2)
      let expected = xs[o1 + o2:o1 + o2 + l2].to_owned()
      nested == direct &&
      nested.to_options() == expected &&
      nested.null_count() == expected.iter().filter(x => x is None).count()
    },
    count=500,
    max_size=200,
  )
}

///|
test "prop: prim gather matches indexing" {
  @quickcheck.check(
    (t : (Array[Int64?], Array[UInt32], UInt32, UInt32)) => {
      let (xs, raw, a, b) = t
      if xs.length() == 0 {
        return @arrow.PrimArray::from_options(xs).gather([]).length() == 0
      }
      let idx = arr_indices(xs.length(), raw)
      let (o, l) = arr_range(xs.length(), a, b)
      let arr = @arrow.PrimArray::from_options(xs)
      let g = arr.gather(idx)
      // gather on a slice too
      let sl_idx = if l == 0 { [] } else { arr_indices(l, raw) }
      let gs = arr.slice(o, l).gather(sl_idx)
      let expected = idx.map(i => xs[i])
      g.to_options() == expected &&
      (g.null_count() > 0 || g.validity() is None) &&
      gs.to_options() == sl_idx.map(i => xs[o + i])
    },
    count=500,
    max_size=200,
  )
}

///|
test "prop: prim builder equals from_options" {
  @quickcheck.check(
    (xs : Array[Int64?]) => {
      let b = @arrow.PrimBuilder::new()
      for x in xs {
        b.push_option(x)
      }
      b.finish() == @arrow.PrimArray::from_options(xs)
    },
    count=300,
    max_size=200,
  )
}

///|
test "prop: str from_options/to_options roundtrip" {
  @quickcheck.check(
    (xs : Array[String?]) => {
      @arrow.StrArray::from_options(xs).to_options() == xs
    },
    count=300,
    max_size=100,
  )
}

///|
test "prop: str slice of slice" {
  @quickcheck.check(
    (t : (Array[String?], UInt32, UInt32, UInt32, UInt32)) => {
      let (xs, a, b, c, d) = t
      let arr = @arrow.StrArray::from_options(xs)
      let (o1, l1) = arr_range(xs.length(), a, b)
      let (o2, l2) = arr_range(l1, c, d)
      let nested = arr.slice(o1, l1).slice(o2, l2)
      let direct = arr.slice(o1 + o2, l2)
      let expected = xs[o1 + o2:o1 + o2 + l2].to_owned()
      nested == direct &&
      nested.to_options() == expected &&
      nested.null_count() == expected.iter().filter(x => x is None).count()
    },
    count=500,
    max_size=100,
  )
}

///|
test "prop: str gather matches indexing" {
  @quickcheck.check(
    (t : (Array[String?], Array[UInt32])) => {
      let (xs, raw) = t
      if xs.length() == 0 {
        return true
      }
      let idx = arr_indices(xs.length(), raw)
      let g = @arrow.StrArray::from_options(xs).gather(idx)
      g.to_options() == idx.map(i => xs[i]) &&
      (g.null_count() > 0 || g.validity() is None)
    },
    count=500,
    max_size=100,
  )
}

///|
test "prop: str builder equals from_options" {
  @quickcheck.check(
    (xs : Array[String?]) => {
      let b = @arrow.StrBuilder::new()
      for x in xs {
        b.push_option(x)
      }
      b.finish() == @arrow.StrArray::from_options(xs)
    },
    count=300,
    max_size=100,
  )
}

///|
test "prop: bool roundtrip, slice of slice, gather, builder" {
  @quickcheck.check(
    (t : (Array[Bool?], Array[UInt32], UInt32, UInt32, UInt32, UInt32)) => {
      let (xs, raw, a, b, c, d) = t
      let arr = @arrow.BoolArray::from_options(xs)
      let (o1, l1) = arr_range(xs.length(), a, b)
      let (o2, l2) = arr_range(l1, c, d)
      let nested = arr.slice(o1, l1).slice(o2, l2)
      let bld = @arrow.BoolBuilder::new()
      for x in xs {
        bld.push_option(x)
      }
      let gather_ok = if xs.length() == 0 {
        true
      } else {
        let idx = arr_indices(xs.length(), raw)
        arr.gather(idx).to_options() == idx.map(i => xs[i])
      }
      arr.to_options() == xs &&
      nested == arr.slice(o1 + o2, l2) &&
      nested.to_options() == xs[o1 + o2:o1 + o2 + l2].to_owned() &&
      bld.finish() == arr &&
      gather_ok
    },
    count=500,
    max_size=200,
  )
}
