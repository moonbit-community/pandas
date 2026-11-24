///|
/// A frame of the nullable `Int32` key `k` and the row number `i`.
fn frame_prop_df(keys : Array[Int32?]) -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int32_nullable("k", keys),
    @pl.Series::int32("i", Array::makei(keys.length(), i => i)),
  ])
}

///|
test "prop: filter keeps exactly the rows where the predicate is true" {
  @quickcheck.check(
    (rows : Array[(Int32?, Bool?)]) => {
      let df = @pl.DataFrame::new([
        @pl.Series::int32_nullable("k", rows.map(r => r.0)),
        @pl.Series::bool_nullable("m", rows.map(r => r.1)),
      ])
      let out = df.filter(@pl.col("m"))
      let expected = rows.filter(r => r.1 == Some(true)).map(r => r.0)
      out.height() == expected.length() &&
      out.column("k").to_int32_array() == expected &&
      out.width() == 2
    },
    count=300,
    max_size=60,
  )
}

///|
test "prop: sort is ordered on the key and stable on ties" {
  @quickcheck.check(
    (t : (Array[Int32?], Bool, Bool)) => {
      let (keys, desc, nl) = t
      let df = frame_prop_df(keys)
      let out = df.sort([@pl.col("k")], descending=[desc], nulls_last=nl)
      let k = out.column("k").to_int32_array()
      let idx = out.column("i").to_int32_array()
      let n = keys.length()
      if out.height() != n {
        return false
      }
      // a permutation
      let seen : Array[Bool] = Array::make(n, false)
      for p in 0..<n {
        let j = idx[p].unwrap()
        if seen[j] || keys[j] != k[p] {
          return false
        }
        seen[j] = true
      }
      for p in 1..<n {
        let c = match (k[p - 1], k[p]) {
          (None, None) => 0
          (None, Some(_)) => if nl { 1 } else { -1 }
          (Some(_), None) => if nl { -1 } else { 1 }
          (Some(a), Some(b)) => if desc { b.compare(a) } else { a.compare(b) }
        }
        if c > 0 {
          return false
        }
        // ties keep the original order
        if c == 0 && idx[p - 1].unwrap() > idx[p].unwrap() {
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
test "prop: sort by two keys agrees with sorting twice, last key first" {
  @quickcheck.check(
    (rows : Array[(Int32?, Int32?)]) => {
      let df = @pl.DataFrame::new([
        @pl.Series::int32_nullable("a", rows.map(r => r.0)),
        @pl.Series::int32_nullable("b", rows.map(r => r.1)),
        @pl.Series::int32("i", Array::makei(rows.length(), i => i)),
      ])
      let once = df.sort([@pl.col("a"), @pl.col("b")], descending=[false, true])
      let twice = df
        .sort([@pl.col("b")], descending=[true])
        .sort([@pl.col("a")])
      once.equals(twice)
    },
    count=300,
    max_size=60,
  )
}

///|
test "prop: unique keeps the first (or last) row of each key, in row order" {
  @quickcheck.check(
    (t : (Array[Int32?], Bool)) => {
      let (keys, last) = t
      let df = frame_prop_df(keys)
      let keep = if last { @pl.UniqueKeep::Last } else { @pl.UniqueKeep::First }
      let out = df.unique(subset=["k"], keep~)
      let got = out.column("i").to_int32_array().map(v => v.unwrap())
      let expected : Array[Int32] = []
      for i in 0..<keys.length() {
        let mut keep_row = true
        for j in 0..<keys.length() {
          if keys[j] == keys[i] && (if last { j > i } else { j < i }) {
            keep_row = false
          }
        }
        if keep_row {
          expected.push(i)
        }
      }
      got == expected
    },
    count=300,
    max_size=60,
  )
}

///|
test "prop: unique with KeepNone keeps the keys that occur once" {
  @quickcheck.check(
    (keys : Array[Int32?]) => {
      let df = frame_prop_df(keys)
      let out = df.unique(subset=["k"], keep=KeepNone)
      let got = out.column("i").to_int32_array().map(v => v.unwrap())
      let expected = Array::makei(keys.length(), i => i).filter(i => {
        keys.filter(k => k == keys[i]).length() == 1
      })
      got == expected
    },
    count=300,
    max_size=60,
  )
}

///|
test "prop: drop_nulls leaves the rows without nulls and with_row_index counts" {
  @quickcheck.check(
    (rows : Array[(Int32?, Int32?)]) => {
      let df = @pl.DataFrame::new([
        @pl.Series::int32_nullable("a", rows.map(r => r.0)),
        @pl.Series::int32_nullable("b", rows.map(r => r.1)),
      ])
      let out = df.drop_nulls()
      let expected = rows.filter(r => r.0 is Some(_) && r.1 is Some(_))
      let indexed = df.with_row_index(name="r", offset=3)
      out.height() == expected.length() &&
      out.column("a").null_count() == 0 &&
      out.column("b").null_count() == 0 &&
      df.drop_nulls(subset=["a"]).height() ==
      rows.filter(r => r.0 is Some(_)).length() &&
      indexed.column("r").to_int64_array() ==
      Array::makei(rows.length(), i => Some((i + 3).to_int64())) &&
      indexed.null_count().column("r").get(0) == @pl.AnyValue::Int64(0L)
    },
    count=300,
    max_size=60,
  )
}
