///|
/// Reference model of polars' slice semantics, computed in 64-bit arithmetic.
fn model_slice(
  xs : Array[@pl.AnyValue],
  offset : Int32,
  length : Int32?,
) -> Array[@pl.AnyValue] {
  let n = xs.length().to_int64()
  let start0 = if offset < 0 {
    offset.to_int64() + n
  } else {
    offset.to_int64()
  }
  let len64 = match length {
    None => 8589934592L // unbounded: longer than any i32 range
    Some(l) => if l < 0 { 0L } else { l.to_int64() }
  }
  let stop0 = start0 + len64
  let clamp = (v : Int64) => if v < 0L { 0L } else if v > n { n } else { v }
  let start = clamp(start0)
  let stop = clamp(stop0)
  let out = []
  let mut i = start
  while i < stop {
    out.push(xs[i.to_int()])
    i += 1L
  }
  out
}

///|
test "prop: slice matches the polars model and never aborts" {
  @quickcheck.check(
    (t : (Array[Int64?], Int32, Int32?)) => {
      let (xs, off, len) = t
      let s = @pl.Series::int64_nullable("a", xs)
      let got = match len {
        None => s.slice(off)
        Some(l) => s.slice(off, length=l)
      }
      got.to_list() == model_slice(s.to_list(), off, len)
    },
    count=500,
    max_size=40,
  )
}

///|
test "slice matches the model at extreme offsets and lengths" {
  let xs = [Some(1L), None, Some(3L), Some(4L), None]
  let s = @pl.Series::int64_nullable("a", xs)
  let extremes = [
    @int.MIN_VALUE,
    @int.MIN_VALUE + 1,
    -6,
    -5,
    -1,
    0,
    1,
    4,
    5,
    6,
    @int.MAX_VALUE - 1,
    @int.MAX_VALUE,
  ]
  for off in extremes {
    assert_eq(s.slice(off).to_list(), model_slice(s.to_list(), off, None))
    for l in extremes {
      assert_eq(
        s.slice(off, length=l).to_list(),
        model_slice(s.to_list(), off, Some(l)),
      )
    }
  }
}

///|
fn imin(a : Int32, b : Int32) -> Int32 {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn imax(a : Int32, b : Int32) -> Int32 {
  if a > b {
    a
  } else {
    b
  }
}

///|
test "prop: head and tail are consistent with slice" {
  @quickcheck.check(
    (t : (Array[Int64?], Int32)) => {
      let (xs, n) = t
      let s = @pl.Series::int64_nullable("a", xs)
      let len = xs.length()
      let k64 = if n < 0 { -n.to_int64() } else { n.to_int64() }
      let k = if k64 > len.to_int64() { len } else { k64.to_int() }
      let h = if n >= 0 {
        xs[:imin(k, len)].to_owned()
      } else {
        xs[:imax(len - imin(k, len), 0)].to_owned()
      }
      let tl = if n >= 0 {
        xs[len - imin(k, len):].to_owned()
      } else {
        xs[imin(k, len):].to_owned()
      }
      s.head(n~).to_int64_array() == h && s.tail(n~).to_int64_array() == tl
    },
    count=500,
    max_size=40,
  )
}

///|
test "prop: gather of normalised indices matches direct indexing" {
  @quickcheck.check(
    (t : (Array[Int64?], Array[Int32])) => {
      let (xs, raw) = t
      let s = @pl.Series::int64_nullable("a", xs)
      let n = xs.length()
      if n == 0 {
        true
      } else {
        let idx = raw.map(r => {
          let m = (r.reinterpret_as_uint() % n.reinterpret_as_uint()).reinterpret_as_int()
          if r % 2 == 0 {
            m
          } else {
            m - n
          }
        })
        let got = s.gather(idx).to_int64_array()
        let want = idx.map(i => if i < 0 { xs[i + n] } else { xs[i] })
        got == want
      }
    },
    count=300,
    max_size=40,
  )
}
