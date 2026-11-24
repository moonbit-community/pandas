///|
test "prop: sort is ordered (null first) and a permutation of the input" {
  @quickcheck.check(
    (xs : Array[Int32?]) => {
      let s = @pl.Series::int32_nullable("a", xs)
      let sorted = s.sort().to_int32_array()
      let expected = xs.copy()
      expected.sort()
      sorted == expected
    },
    count=300,
    max_size=60,
  )
}

///|
test "prop: sort descending is the reverse order with null still first" {
  @quickcheck.check(
    (xs : Array[Int32?]) => {
      let s = @pl.Series::int32_nullable("a", xs)
      let got = s.sort(descending=true).to_int32_array()
      let nulls = xs.filter(x => x is None)
      let vals = xs.filter(x => x is Some(_))
      vals.sort()
      vals.rev_in_place()
      got == nulls + vals
    },
    count=300,
    max_size=60,
  )
}

///|
test "prop: arg_sort is a stable permutation" {
  @quickcheck.check(
    (t : (Array[Int32?], Bool, Bool)) => {
      let (xs, desc, nl) = t
      let s = @pl.Series::int32_nullable("a", xs)
      let idx = s.arg_sort(descending=desc, nulls_last=nl).to_int64_array()
      let n = xs.length()
      if idx.length() != n {
        return false
      }
      let seen : Array[Bool] = Array::make(n, false)
      let order : Array[Int32] = []
      for i in idx {
        let k = i.unwrap().to_int()
        if k < 0 || k >= n || seen[k] {
          return false
        }
        seen[k] = true
        order.push(k)
      }
      for p in 1..<n {
        let a = xs[order[p - 1]]
        let b = xs[order[p]]
        let c = match (a, b) {
          (None, None) => 0
          (None, Some(_)) => if nl { 1 } else { -1 }
          (Some(_), None) => if nl { -1 } else { 1 }
          (Some(x), Some(y)) => {
            let r = x.compare(y)
            if desc {
              -r
            } else {
              r
            }
          }
        }
        // ordered, and equal keys keep their original order
        if c > 0 || (c == 0 && order[p - 1] > order[p]) {
          return false
        }
      }
      true
    },
    count=300,
    max_size=60,
  )
}

///|
/// Lexicographic comparison of two code point sequences (`Array`'s own
/// ordering compares the lengths first).
fn sortp_lex_cmp(a : Array[Int32], b : Array[Int32]) -> Int32 {
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<n {
    if a[i] != b[i] {
      return if a[i] < b[i] { -1 } else { 1 }
    }
  }
  a.length().compare(b.length())
}

///|
test "prop: sort of strings follows code point order" {
  let pool = [
    "a", "Z", "\u{FF61}", "\u{E000}", "\u{FFFF}", "\u{1F600}", "\u{10000}", "",
  ]
  @quickcheck.check(
    (xs : Array[Array[Int32]]) => {
      // every string is a sequence of pieces from the pool (BMP and astral)
      let strs = xs.map(ix => ix.map(i => pool[(i % 8 + 8) % 8]).join(""))
      let sorted = @pl.Series::str("a", strs).sort().to_str_array()
      for i in 1..<sorted.length() {
        let a = sorted[i - 1].unwrap().to_array().map(c => c.to_int())
        let b = sorted[i].unwrap().to_array().map(c => c.to_int())
        if sortp_lex_cmp(a, b) > 0 {
          return false
        }
      }
      sorted.length() == xs.length()
    },
    count=200,
    max_size=12,
  )
}

///|
test "prop: unique has no duplicates, keeps first occurrences and covers every value" {
  @quickcheck.check(
    (xs : Array[Int32?]) => {
      let s = @pl.Series::int32_nullable("a", xs)
      let u = s.unique(maintain_order=true).to_int32_array()
      let expected : Array[Int32?] = []
      for x in xs {
        if !expected.contains(x) {
          expected.push(x)
        }
      }
      u == expected && s.n_unique() == expected.length()
    },
    count=300,
    max_size=60,
  )
}

///|
test "prop: is_in agrees with a linear search (null in the series gives null)" {
  @quickcheck.check(
    (t : (Array[Int32?], Array[Int32?])) => {
      let (xs, ys) = t
      let r = @pl.Series::int32_nullable("a", xs)
        .is_in(@pl.Series::int32_nullable("b", ys))
        .to_bool_array()
      for i in 0..<xs.length() {
        let expected = match xs[i] {
          None => None
          Some(_) => Some(ys.contains(xs[i]))
        }
        if r[i] != expected {
          return false
        }
      }
      r.length() == xs.length()
    },
    count=300,
    max_size=40,
  )
}
