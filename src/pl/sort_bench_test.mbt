///|
/// Pseudo-random `Int64`s (about 100k distinct values, so there are ties).
fn sort_bench_values() -> Array[Int64] {
  let mut state = 42UL
  Array::makei(bench_n, _ => {
    let (next, v) = lcg_next(state, 100000)
    state = next
    v.to_int64()
  })
}

///|
test "bench Series::sort int64 random n=1000000" (it : @bench.T) {
  let s = @pl.Series::int64("a", sort_bench_values())
  it.bench(fn() { it.keep(s.sort()) })
}

///|
test "bench Series::arg_sort int64 random n=1000000" (it : @bench.T) {
  let s = @pl.Series::int64("a", sort_bench_values())
  it.bench(fn() { it.keep(s.arg_sort()) })
}

///|
test "bench Series::unique int64 random n=1000000" (it : @bench.T) {
  let s = @pl.Series::int64("a", sort_bench_values())
  it.bench(fn() { it.keep(s.unique()) })
}

///|
test "bench Series::is_in int64 n=1000000 in 100000" (it : @bench.T) {
  let s = @pl.Series::int64("a", sort_bench_values())
  let o = @pl.Series::int64("b", Array::makei(100000, i => (i * 2).to_int64()))
  it.bench(fn() { it.keep(must(() => s.is_in(o))) })
}

///|
test "bench Series::sort string random n=200000" (it : @bench.T) {
  let mut state = 7UL
  let strs = Array::makei(200000, _ => {
    let (next, v) = lcg_next(state, 1000000)
    state = next
    "k\{v}"
  })
  let s = @pl.Series::str("a", strs)
  it.bench(fn() { it.keep(s.sort()) })
}

///|
/// Composite ids `(shard << 32) | seq`: 100 shards x 10000 sequence numbers.
test "bench Series::unique int64 composite ids n=1000000" (it : @bench.T) {
  let s = @pl.Series::int64(
    "a",
    Array::makei(bench_n, i => {
      ((i % 100).to_int64() << 32) | (i / 100).to_int64()
    }),
  )
  it.bench(fn() { it.keep(s.unique()) })
}

///|
fn str_bench_values(seed : UInt64) -> Array[String] {
  let mut state = seed
  Array::makei(bench_n, _ => {
    let (next, v) = lcg_next(state, bench_n)
    state = next
    "k\{v}"
  })
}

///|
test "bench Series::unique string random n=1000000" (it : @bench.T) {
  let s = @pl.Series::str("a", str_bench_values(11UL))
  it.bench(fn() { it.keep(s.unique()) })
}

///|
test "bench Series::is_in string n=1000000 in 100000" (it : @bench.T) {
  let s = @pl.Series::str("a", str_bench_values(11UL))
  let o = @pl.Series::str("b", Array::makei(100000, i => "k\{i * 7}"))
  it.bench(fn() { it.keep(must(() => s.is_in(o))) })
}
