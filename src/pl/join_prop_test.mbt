///|
/// A frame of the nullable `Int32` key `k` (reduced to `-4..4` so that keys
/// repeat) and the row number `id` under `id_name`.
fn join_prop_frame(
  keys : Array[Int32?],
  id_name : String,
) -> (@pl.DataFrame, Array[Int32?]) raise {
  let small = keys.map(k => k.map(v => v % 5))
  let df = @pl.DataFrame::new([
    @pl.Series::int32_nullable("k", small),
    @pl.Series::int32(id_name, Array::makei(small.length(), i => i)),
  ])
  (df, small)
}

///|
/// Whether the keys `a` and `b` match: equal values, or two nulls when
/// `nulls_equal`.
fn join_prop_match(a : Int32?, b : Int32?, nulls_equal : Bool) -> Bool {
  match (a, b) {
    (Some(x), Some(y)) => x == y
    (None, None) => nulls_equal
    _ => false
  }
}

///|
/// The row pairs `(left, right)` of a join by the definition (every left row
/// against every right row), in the order the library promises; `None` is the
/// side that has no row.
fn join_prop_pairs(
  lk : Array[Int32?],
  rk : Array[Int32?],
  how : @pl.JoinHow,
  nulls_equal : Bool,
) -> Array[(Int32?, Int32?)] {
  let out : Array[(Int32?, Int32?)] = []
  match how {
    Right =>
      for j in 0..<rk.length() {
        let mut any = false
        for i in 0..<lk.length() {
          if join_prop_match(lk[i], rk[j], nulls_equal) {
            any = true
            out.push((Some(i), Some(j)))
          }
        }
        if !any {
          out.push((None, Some(j)))
        }
      }
    _ => {
      let used : Array[Bool] = Array::make(rk.length(), false)
      for i in 0..<lk.length() {
        let mut any = false
        for j in 0..<rk.length() {
          if join_prop_match(lk[i], rk[j], nulls_equal) {
            any = true
            used[j] = true
            out.push((Some(i), Some(j)))
          }
        }
        if !any && (how == Left || how == Full) {
          out.push((Some(i), None))
        }
      }
      if how == Full {
        for j in 0..<rk.length() {
          if !used[j] {
            out.push((None, Some(j)))
          }
        }
      }
    }
  }
  out
}

///|
test "prop: inner, left, right and full joins are the pairs by definition" {
  @quickcheck.check(
    (t : (Array[Int32?], Array[Int32?], Bool)) => {
      let (ls, rs, nulls_equal) = t
      let (l, lk) = join_prop_frame(ls, "i")
      let (r, rk) = join_prop_frame(rs, "j")
      for how in [@pl.JoinHow::Inner, Left, Right, Full] {
        let out = l.join(r, on=[@pl.col("k")], how~, nulls_equal~)
        let expected = join_prop_pairs(lk, rk, how, nulls_equal)
        if out.height() != expected.length() {
          return false
        }
        if out.column("i").to_int32_array() != expected.map(p => p.0) ||
          out.column("j").to_int32_array() != expected.map(p => p.1) {
          return false
        }
      }
      true
    },
    count=300,
    max_size=30,
  )
}

///|
test "prop: the rows of an inner join are the products of the key counts" {
  @quickcheck.check(
    (t : (Array[Int32?], Array[Int32?])) => {
      let (ls, rs) = t
      let (l, lk) = join_prop_frame(ls, "i")
      let (r, rk) = join_prop_frame(rs, "j")
      let mut expected = 0
      for key in [-4, -3, -2, -1, 0, 1, 2, 3, 4] {
        let nl = lk.filter(k => k == Some(key)).length()
        let nr = rk.filter(k => k == Some(key)).length()
        expected += nl * nr
      }
      l.join(r, on=[@pl.col("k")]).height() == expected
    },
    count=300,
    max_size=40,
  )
}

///|
test "prop: semi and anti split the left frame" {
  @quickcheck.check(
    (t : (Array[Int32?], Array[Int32?], Bool)) => {
      let (ls, rs, nulls_equal) = t
      let (l, lk) = join_prop_frame(ls, "i")
      let (r, rk) = join_prop_frame(rs, "j")
      let semi = l.join(r, on=[@pl.col("k")], how=Semi, nulls_equal~)
      let anti = l.join(r, on=[@pl.col("k")], how=Anti, nulls_equal~)
      if semi.height() + anti.height() != l.height() {
        return false
      }
      // the left rows in order, each in exactly one of the two
      let in_semi = semi.column("i").to_int32_array()
      let in_anti = anti.column("i").to_int32_array()
      let semi_expected : Array[Int32?] = []
      let anti_expected : Array[Int32?] = []
      for i in 0..<lk.length() {
        if rk.any(b => join_prop_match(lk[i], b, nulls_equal)) {
          semi_expected.push(Some(i))
        } else {
          anti_expected.push(Some(i))
        }
      }
      in_semi == semi_expected &&
      in_anti == anti_expected &&
      semi.columns() == ["k", "i"]
    },
    count=300,
    max_size=30,
  )
}

///|
test "prop: a left join, cut to the left columns and one row per left row, is the left frame" {
  @quickcheck.check(
    (t : (Array[Int32?], Array[Int32?])) => {
      let (ls, rs) = t
      let (l, _) = join_prop_frame(ls, "i")
      let (r, _) = join_prop_frame(rs, "j")
      let out = l.join(r, on=[@pl.col("k")], how=Left)
      let ids = out.column("i").to_int32_array()
      let keys = out.column("k").to_int32_array()
      let left_ids = l.column("i").to_int32_array()
      let left_keys = l.column("k").to_int32_array()
      // a left row repeats in a row of its matches
      let seen_ids : Array[Int32?] = []
      let seen_keys : Array[Int32?] = []
      for p in 0..<ids.length() {
        if p == 0 || ids[p] != ids[p - 1] {
          seen_ids.push(ids[p])
          seen_keys.push(keys[p])
        }
      }
      seen_ids == left_ids && seen_keys == left_keys
    },
    count=300,
    max_size=30,
  )
}

///|
test "prop: nulls_equal false never matches a null key, the other kinds agree" {
  @quickcheck.check(
    (t : (Array[Int32?], Array[Int32?])) => {
      let (ls, rs) = t
      let (l, _) = join_prop_frame(ls, "i")
      let (r, _) = join_prop_frame(rs, "j")
      let inner = l.join(r, on=[@pl.col("k")])
      // no output row of an inner join has a null key
      if inner.column("k").null_count() != 0 {
        return false
      }
      // a full join has the rows of the left, the right and the inner join
      let full = l.join(r, on=[@pl.col("k")], how=Full)
      let left = l.join(r, on=[@pl.col("k")], how=Left)
      let right = l.join(r, on=[@pl.col("k")], how=Right)
      let only_right = full.height() - left.height()
      only_right >= 0 &&
      right.height() == inner.height() + only_right &&
      full.height() <= inner.height() + l.height() + r.height()
    },
    count=300,
    max_size=30,
  )
}
