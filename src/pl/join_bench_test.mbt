///|
/// A frame of the `Int64` key `k` and the `Int32` payload `v`.
fn join_bench_frame(keys : Array[Int64], payload : String) -> @pl.DataFrame {
  must(() => {
    @pl.DataFrame::new([
      @pl.Series::int64("k", keys),
      @pl.Series::int32(payload, Array::makei(keys.length(), i => i)),
    ])
  })
}

///|
/// 1M keys 0..1M in a scrambled order (both sides are permutations).
fn join_bench_permutation(mult : Int32) -> Array[Int64] {
  Array::makei(bench_n, i => i.to_int64() * mult.to_int64() % bench_n.to_int64())
}

///|
test "bench join inner int64 unique keys 1M x 1M" (it : @bench.T) {
  let l = join_bench_frame(join_bench_permutation(7), "i")
  let r = join_bench_frame(join_bench_permutation(3), "j")
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")]))) })
}

///|
test "bench join left int64 unique keys 1M x 1M" (it : @bench.T) {
  let l = join_bench_frame(join_bench_permutation(7), "i")
  let r = join_bench_frame(join_bench_permutation(3), "j")
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")], how=Left))) })
}

///|
test "bench join full int64 unique keys 1M x 1M" (it : @bench.T) {
  let l = join_bench_frame(join_bench_permutation(7), "i")
  let r = join_bench_frame(join_bench_permutation(3), "j")
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")], how=Full))) })
}

///|
test "bench join right int64 unique keys 1M x 1M" (it : @bench.T) {
  let l = join_bench_frame(join_bench_permutation(7), "i")
  let r = join_bench_frame(join_bench_permutation(3), "j")
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")], how=Right))) })
}

///|
test "bench join semi int64 unique keys 1M x 1M" (it : @bench.T) {
  let l = join_bench_frame(join_bench_permutation(7), "i")
  let r = join_bench_frame(join_bench_permutation(3), "j")
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")], how=Semi))) })
}

///|
/// 1M left rows with 100 distinct keys; 1 000 right rows, each of those keys
/// 10 times: every left row has 10 matches, the output has 10M rows.
test "bench join inner int64 1M x 1000 right keys repeated 10 times" (
  it : @bench.T,
) {
  let l = join_bench_frame(
    Array::makei(bench_n, i => (i % 100).to_int64()),
    "i",
  )
  let r = join_bench_frame(Array::makei(1000, i => (i % 100).to_int64()), "j")
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")]))) })
}

///|
test "bench join left int64 1M x 1000 right keys repeated 10 times" (
  it : @bench.T,
) {
  let l = join_bench_frame(
    Array::makei(bench_n, i => (i % 1000).to_int64()),
    "i",
  )
  let r = join_bench_frame(Array::makei(1000, i => (i % 100).to_int64()), "j")
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")], how=Left))) })
}

///|
/// Strings that share a 60 character prefix.
fn join_bench_strings(mult : Int32) -> Array[String] {
  let prefix = "common-prefix-common-prefix-common-prefix-common-prefix-"
  Array::makei(bench_n, i => {
    "\{prefix}\{(i.to_int64() * mult.to_int64()) % bench_n.to_int64()}"
  })
}

///|
test "bench join inner string keys with a long common prefix 1M x 1M" (
  it : @bench.T,
) {
  let l = must(() => {
    @pl.DataFrame::new([
      @pl.Series::str("k", join_bench_strings(7)),
      @pl.Series::int32("i", Array::makei(bench_n, i => i)),
    ])
  })
  let r = must(() => {
    @pl.DataFrame::new([
      @pl.Series::str("k", join_bench_strings(3)),
      @pl.Series::int32("j", Array::makei(bench_n, i => i)),
    ])
  })
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")]))) })
}

///|
test "bench join inner two int64 keys 1M x 1M" (it : @bench.T) {
  let l = must(() => {
    @pl.DataFrame::new([
      @pl.Series::int64("a", join_bench_permutation(7)),
      @pl.Series::int64("b", Array::makei(bench_n, i => (i % 3).to_int64())),
      @pl.Series::int32("i", Array::makei(bench_n, i => i)),
    ])
  })
  let r = must(() => {
    @pl.DataFrame::new([
      @pl.Series::int64("a", join_bench_permutation(3)),
      @pl.Series::int64("b", Array::makei(bench_n, i => (i % 3).to_int64())),
      @pl.Series::int32("j", Array::makei(bench_n, i => i)),
    ])
  })
  it.bench(fn() {
    it.keep(must(() => l.join(r, on=[@pl.col("a"), @pl.col("b")])))
  })
}
