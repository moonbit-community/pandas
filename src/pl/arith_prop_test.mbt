///|
test "prop: filter length is the number of true mask rows" {
  @quickcheck.check(
    (t : Array[(Int64?, Bool?)]) => {
      let s = @pl.Series::int64_nullable("a", t.map(p => p.0))
      let m = @pl.Series::bool_nullable("m", t.map(p => p.1))
      let r = s.filter(m)
      let mut expected = 0
      let kept : Array[Int64?] = []
      for p in t {
        if p.1 is Some(true) {
          expected += 1
          kept.push(p.0)
        }
      }
      r.len() == expected && r.to_int64_array() == kept
    },
    count=300,
    max_size=40,
  )
}

///|
test "prop: floor_div and rem satisfy a == (a // b) * b + a % b" {
  @quickcheck.check(
    (t : (Int64, Int64)) => {
      let (x, y) = t
      let a = @pl.Series::int64("a", [x])
      let b = @pl.Series::int64("b", [y])
      let q = a.floor_div(b).to_int64_array()[0]
      let r = a.rem(b).to_int64_array()[0]
      if y == 0L {
        q is None && r is None
      } else {
        // wraps for MIN // -1, so compare in wrapping arithmetic
        q.unwrap() * y + r.unwrap() == x &&
        (r.unwrap() == 0L || (r.unwrap() < 0L) == (y < 0L))
      }
    },
    count=500,
  )
}

///|
test "prop: and_ and or_ obey De Morgan with nulls" {
  @quickcheck.check(
    (t : Array[(Bool?, Bool?)]) => {
      let a = @pl.Series::bool_nullable("a", t.map(p => p.0))
      let b = @pl.Series::bool_nullable("b", t.map(p => p.1))
      a.and_(b).not_().to_bool_array() == a.not_().or_(b.not_()).to_bool_array() &&
      a.or_(b).not_().to_bool_array() == a.not_().and_(b.not_()).to_bool_array()
    },
    count=300,
    max_size=40,
  )
}

///|
test "prop: lt and gt are mirror images, ne is not eq" {
  @quickcheck.check(
    (t : Array[(Double?, Double?)]) => {
      let a = @pl.Series::float64_nullable("a", t.map(p => p.0))
      let b = @pl.Series::float64_nullable("b", t.map(p => p.1))
      a.lt(b).to_bool_array() == b.gt(a).to_bool_array() &&
      a.neq(b).to_bool_array() == a.eq(b).not_().to_bool_array() &&
      a.le(b).to_bool_array() == b.ge(a).to_bool_array()
    },
    count=300,
    max_size=40,
  )
}

///|
test "prop: add is commutative and sub undoes it (wrapping Int32)" {
  @quickcheck.check(
    (t : Array[(Int32?, Int32)]) => {
      let a = @pl.Series::int32_nullable("a", t.map(p => p.0))
      let b = @pl.Series::int32("b", t.map(p => p.1))
      a.add(b).to_int32_array() == b.add(a).to_int32_array() &&
      a.add(b).sub(b).to_int32_array() == a.to_int32_array()
    },
    count=300,
    max_size=40,
  )
}
