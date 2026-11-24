///|
/// A frame of a nullable key and a nullable value from generated rows.
fn gp_frame(t : Array[(Int32?, Int64?)]) -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int32_nullable("k", t.map(p => p.0.map(x => x % 5))),
    @pl.Series::int64_nullable("v", t.map(p => p.1.map(x => x % 1000L))),
  ])
}

///|
test "prop: the group sizes add up to the height" {
  @quickcheck.check(
    (t : Array[(Int32?, Int64?)]) => {
      let df = gp_frame(t)
      let out = df.group_by([@pl.col("k")]).agg([@pl.len()])
      let sizes = out.column("len").to_int64_array()
      let mut total = 0L
      for s in sizes {
        total += s.unwrap()
      }
      total == t.length().to_int64() &&
      (t.length() == 0 || sizes.length() <= t.length()) &&
      out.height() == sizes.length()
    },
    count=300,
    max_size=40,
  )
}

///|
test "prop: the sum per group is the sum of the rows with that key" {
  @quickcheck.check(
    (t : Array[(Int32?, Int64?)]) => {
      let df = gp_frame(t)
      let out = df.group_by([@pl.col("k")]).agg([@pl.col("v").sum()])
      let keys = out.column("k").to_int32_array()
      let sums = out.column("v").to_int64_array()
      if keys.length() != sums.length() {
        return false
      }
      // the keys are the distinct keys, in order of first appearance
      let expected_keys : Array[Int32?] = []
      for p in df.column("k").to_int32_array() {
        if !expected_keys.contains(p) {
          expected_keys.push(p)
        }
      }
      if keys != expected_keys {
        return false
      }
      // each sum is that of the rows filtered by the key
      for i in 0..<keys.length() {
        let mask = match keys[i] {
          Some(x) => @pl.col("k").eq(@pl.lit_int(x.to_int64()))
          None => @pl.col("k").is_null()
        }
        let one = df.filter(mask).select([@pl.col("v").sum()])
        if one.column("v").to_int64_array() != [sums[i]] {
          return false
        }
      }
      true
    },
    count=200,
    max_size=40,
  )
}

///|
test "prop: maintain_order does not change the result" {
  @quickcheck.check(
    (t : Array[(Int32?, Int64?)]) => {
      let df = gp_frame(t)
      let a = df
        .group_by([@pl.col("k")], maintain_order=true)
        .agg([
          @pl.col("v").sum().alias("s"),
          @pl.col("v").count().alias("c"),
          @pl.col("v").min().alias("lo"),
          @pl.col("v").max().alias("hi"),
        ])
      let b = df
        .group_by([@pl.col("k")])
        .agg([
          @pl.col("v").sum().alias("s"),
          @pl.col("v").count().alias("c"),
          @pl.col("v").min().alias("lo"),
          @pl.col("v").max().alias("hi"),
        ])
      a.equals(b)
    },
    count=200,
    max_size=40,
  )
}
