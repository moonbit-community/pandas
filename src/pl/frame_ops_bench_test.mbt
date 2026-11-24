///|
/// Three columns of 1M rows: a random `Int64` key (about 100k distinct values,
/// so there are ties), a `String` key and a payload.
fn frame_bench_df() -> @pl.DataFrame raise @pl.PolarsError {
  let mut state = 11UL
  let keys : Array[Int64] = Array::makei(bench_n, _ => {
    let (next, v) = lcg_next(state, 100000)
    state = next
    v.to_int64()
  })
  @pl.DataFrame::new([
    @pl.Series::int64("k", keys),
    @pl.Series::str("s", keys.map(k => "k\{k % 1000L}")),
    @pl.Series::int64("v", Array::makei(bench_n, i => i.to_int64())),
  ])
}

///|
test "bench DataFrame::sort one Int64 key n=1000000" (it : @bench.T) {
  let df = must(frame_bench_df)
  it.bench(fn() { it.keep(must(() => df.sort([@pl.col("k")]))) })
}

///|
test "bench DataFrame::sort Int64 and String keys n=1000000" (it : @bench.T) {
  let df = must(frame_bench_df)
  it.bench(fn() {
    it.keep(
      must(() => df.sort([@pl.col("s"), @pl.col("k")], descending=[true, false])),
    )
  })
}

///|
test "bench DataFrame::unique Int64 key n=1000000" (it : @bench.T) {
  let df = must(frame_bench_df)
  it.bench(fn() { it.keep(must(() => df.unique(subset=["k"]))) })
}

///|
test "bench DataFrame::unique two keys n=1000000" (it : @bench.T) {
  let df = must(frame_bench_df)
  it.bench(fn() { it.keep(must(() => df.unique(subset=["k", "s"]))) })
}

///|
test "bench DataFrame::filter Int64 predicate n=1000000" (it : @bench.T) {
  let df = must(frame_bench_df)
  it.bench(fn() {
    it.keep(must(() => df.filter(@pl.col("k").lt(@pl.lit_int(50000L)))))
  })
}
