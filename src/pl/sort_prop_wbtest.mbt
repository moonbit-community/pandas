///|
fn sortp_cmp(
  a : (Int32?, Int32?),
  b : (Int32?, Int32?),
  desc : Array[Bool],
  nl : Array[Bool],
) -> Int32 {
  let c0 = sortp_key(a.0, b.0, desc[0], nl[0])
  if c0 != 0 {
    c0
  } else {
    sortp_key(a.1, b.1, desc[1], nl[1])
  }
}

///|
fn sortp_key(a : Int32?, b : Int32?, desc : Bool, nl : Bool) -> Int32 {
  match (a, b) {
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
}

///|
test "prop: arg_sort_columns is the stable two-key sort" {
  @quickcheck.check(
    (t : (Array[(Int32?, Int32?)], Bool, Bool, Bool, Bool)) => {
      let (rows, d0, d1, n0, n1) = t
      let desc = [d0, d1]
      let nl = [n0, n1]
      let c0 = Column::Int32(@arrow.PrimArray::from_options(rows.map(r => r.0)))
      let c1 = Column::Int32(@arrow.PrimArray::from_options(rows.map(r => r.1)))
      let got = arg_sort_columns([c0, c1], desc, nl)
      // reference: insertion sort with the same comparator (stable)
      let expected : Array[Int32] = []
      for i in 0..<rows.length() {
        let mut pos = expected.length()
        while pos > 0 &&
              sortp_cmp(rows[expected[pos - 1]], rows[i], desc, nl) > 0 {
          pos -= 1
        }
        expected.insert(pos, i)
      }
      got == expected
    },
    count=300,
    max_size=50,
  )
}

///|
test "prop: unique_row_indices keeps are ascending and agree with a quadratic scan" {
  @quickcheck.check(
    (t : (Array[(Int32?, Int32?)], Int32)) => {
      let (rows, k) = t
      let keep = match k.abs() % 4 {
        0 => UniqueKeep::Any
        1 => UniqueKeep::First
        2 => UniqueKeep::Last
        _ => UniqueKeep::KeepNone
      }
      let c0 = Column::Int32(@arrow.PrimArray::from_options(rows.map(r => r.0)))
      let c1 = Column::Int32(@arrow.PrimArray::from_options(rows.map(r => r.1)))
      let got = unique_row_indices([c0, c1], keep)
      let expected : Array[Int32] = []
      for i in 0..<rows.length() {
        let mut before = false
        let mut after = false
        for j in 0..<rows.length() {
          if j < i && rows[j] == rows[i] {
            before = true
          }
          if j > i && rows[j] == rows[i] {
            after = true
          }
        }
        let keep_it = match keep {
          Any | First => !before
          Last => !after
          KeepNone => !before && !after
        }
        if keep_it {
          expected.push(i)
        }
      }
      got == expected
    },
    count=300,
    max_size=40,
  )
}
