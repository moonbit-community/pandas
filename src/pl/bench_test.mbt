///|
/// Row count for every benchmark (spec: 1M rows).
let bench_n : Int32 = 1000000

///|
/// Deterministic pseudo-random sequence (LCG), so every run uses the same
/// gather indices. Returns the next state and a value in `0..<bound`.
fn lcg_next(state : UInt64, bound : Int32) -> (UInt64, Int32) {
  let next = state * 6364136223846793005UL + 1442695040888963407UL
  (next, ((next >> 33) % bound.to_uint64()).to_int())
}

///|
/// Benchmarked calls must succeed; a `PolarsError` here is a bug, so abort.
fn[T] must(f : () -> T raise @pl.PolarsError) -> T {
  f() catch {
    e => abort("\{e}")
  }
}

///|
fn bench_i64_values() -> Array[Int64] {
  Array::makei(bench_n, i => i.to_int64())
}

///|
fn bench_i64_options() -> Array[Int64?] {
  // 10% null: every 10th slot.
  Array::makei(bench_n, i => if i % 10 == 0 { None } else { Some(i.to_int64()) })
}

///|
test "bench Series::int64 n=1000000" (it : @bench.T) {
  let values = bench_i64_values()
  it.bench(fn() { it.keep(@pl.Series::int64("a", values)) })
}

///|
test "bench Series::int64_nullable 10% null n=1000000" (it : @bench.T) {
  let values = bench_i64_options()
  it.bench(fn() { it.keep(@pl.Series::int64_nullable("a", values)) })
}

///|
test "bench Series::slice x1000 n=1000000" (it : @bench.T) {
  let s = @pl.Series::int64("a", bench_i64_values())
  it.bench(fn() {
    let mut total = 0
    for i in 0..<1000 {
      total += s.slice(i * 997, length=1000).len()
    }
    it.keep(total)
  })
}

///|
test "bench Series::gather random n=1000000" (it : @bench.T) {
  let s = @pl.Series::int64("a", bench_i64_values())
  let indices : Array[Int32] = []
  let mut state = 42UL
  for _ in 0..<bench_n {
    let (next, v) = lcg_next(state, bench_n)
    state = next
    indices.push(v)
  }
  it.bench(fn() { it.keep(must(() => s.gather(indices))) })
}

///|
test "bench Series::cast i64->f64 n=1000000" (it : @bench.T) {
  let s = @pl.Series::int64("a", bench_i64_values())
  it.bench(fn() { it.keep(must(() => s.cast(Float64))) })
}

///|
test "bench Bitmap::bit_and offsets 3/5 n=1000000" (it : @bench.T) {
  let bits = Array::makei(bench_n + 8, i => i % 3 != 0)
  let base = @arrow.Bitmap::from_array(bits)
  let a = base.slice(3, bench_n)
  let b = base.slice(5, bench_n)
  it.bench(fn() { it.keep(a.bit_and(b)) })
}

///|
test "bench DataFrame::new 10 columns n=1000000" (it : @bench.T) {
  let columns = Array::makei(10, i => {
    @pl.Series::int64("c\{i}", bench_i64_values())
  })
  it.bench(fn() { it.keep(must(() => @pl.DataFrame::new(columns))) })
}
