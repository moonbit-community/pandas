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
test "bench Series::cast i64->str n=1000000" (it : @bench.T) {
  let s = @pl.Series::int64("a", bench_i64_values())
  it.bench(fn() { it.keep(must(() => s.cast(String))) })
}

///|
test "bench Series::cast str->f64 n=1000000" (it : @bench.T) {
  let s = @pl.Series::str("a", Array::makei(bench_n, i => "\{i}.\{i % 1000}"))
  it.bench(fn() { it.keep(must(() => s.cast(Float64))) })
}

///|
test "bench Series::cast f64->i32 10% null n=1000000" (it : @bench.T) {
  let s = @pl.Series::float64_nullable(
    "a",
    Array::makei(bench_n, i => {
      if i % 10 == 0 {
        None
      } else {
        Some(i.to_double() + 0.5)
      }
    }),
  )
  it.bench(fn() { it.keep(must(() => s.cast(Int32))) })
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

///|
/// The M2 benchmark table (n = 1,000,000 rows, fixed-seed LCG):
/// `a` random `Int64` in `0..<n` (about 632k distinct values), `b` a `Float64`
/// ramp, `g` random `Int64` in `0..<100`, `s` a `String` key built from a
/// random number in `0..<n`.
fn m2_bench_df() -> @pl.DataFrame raise @pl.PolarsError {
  let mut state = 2024UL
  let a : Array[Int64] = Array::makei(bench_n, _ => {
    let (next, v) = lcg_next(state, bench_n)
    state = next
    v.to_int64()
  })
  let g : Array[Int64] = Array::makei(bench_n, _ => {
    let (next, v) = lcg_next(state, 100)
    state = next
    v.to_int64()
  })
  let s : Array[String] = Array::makei(bench_n, _ => {
    let (next, v) = lcg_next(state, bench_n)
    state = next
    "k\{v}"
  })
  @pl.DataFrame::new([
    @pl.Series::int64("a", a),
    @pl.Series::float64("b", Array::makei(bench_n, i => i.to_double() * 0.5)),
    @pl.Series::int64("g", g),
    @pl.Series::str("s", s),
  ])
}

///|
test "bench m2 filter a > 499999 (half) n=1000000" (it : @bench.T) {
  let df = must(m2_bench_df)
  it.bench(fn() {
    it.keep(must(() => df.filter(@pl.col("a").gt(@pl.lit_int(499999L)))))
  })
}

///|
test "bench m2 sort one Int64 key n=1000000" (it : @bench.T) {
  let df = must(m2_bench_df)
  it.bench(fn() { it.keep(must(() => df.sort([@pl.col("a")]))) })
}

///|
test "bench m2 sort one String key n=1000000" (it : @bench.T) {
  let df = must(m2_bench_df)
  it.bench(fn() { it.keep(must(() => df.sort([@pl.col("s")]))) })
}

///|
test "bench m2 sort two keys (g asc, a desc) n=1000000" (it : @bench.T) {
  let df = must(m2_bench_df)
  it.bench(fn() {
    it.keep(
      must(() => df.sort([@pl.col("g"), @pl.col("a")], descending=[false, true])),
    )
  })
}

///|
test "bench m2 select a * 2.0 + b n=1000000" (it : @bench.T) {
  let df = must(m2_bench_df)
  it.bench(fn() {
    it.keep(
      must(() => {
        df.select([
          (@pl.col("a") * @pl.lit_float(2.0) + @pl.col("b")).alias("c"),
        ])
      }),
    )
  })
}

///|
test "bench m2 unique on a (632k distinct) n=1000000" (it : @bench.T) {
  let df = must(m2_bench_df)
  it.bench(fn() { it.keep(must(() => df.unique(subset=["a"]))) })
}

///|
test "bench m2 unique on g (100 distinct) n=1000000" (it : @bench.T) {
  let df = must(m2_bench_df)
  it.bench(fn() { it.keep(must(() => df.unique(subset=["g"]))) })
}

///|
test "bench m2 describe 4 columns n=1000000" (it : @bench.T) {
  let df = must(m2_bench_df)
  it.bench(fn() { it.keep(must(() => df.describe())) })
}

///|
/// `a + 1 + 1 + ...` with `terms` additions: a left-deep chain of weak
/// literals next to one column. Printing and folding it must be linear in the
/// number of terms (they were quadratic).
fn deep_sum(terms : Int32) -> @pl.Expr {
  let mut e = @pl.col("a")
  for _ in 0..<terms {
    e = e + @pl.lit_int(1L)
  }
  e
}

///|
fn deep_weak_sum(terms : Int32) -> @pl.Expr {
  let mut e = @pl.lit_int(1L)
  for _ in 0..<terms {
    e = e + @pl.lit_int(1L)
  }
  e
}

///|
test "bench Expr::to_string chain of 5000 terms" (it : @bench.T) {
  let e = deep_sum(5000)
  it.bench(fn() { it.keep(e.to_string()) })
}

///|
test "bench Expr::to_string chain of 10000 terms" (it : @bench.T) {
  let e = deep_sum(10000)
  it.bench(fn() { it.keep(e.to_string()) })
}

///|
test "bench select of a weak literal chain of 5000 terms" (it : @bench.T) {
  let df = must(() => @pl.DataFrame::new([@pl.Series::int64("a", [1L, 2L, 3L])]))
  let e = deep_weak_sum(5000)
  it.bench(fn() { it.keep(must(() => df.select([e]))) })
}

///|
test "bench select of a weak literal chain of 10000 terms" (it : @bench.T) {
  let df = must(() => @pl.DataFrame::new([@pl.Series::int64("a", [1L, 2L, 3L])]))
  let e = deep_weak_sum(10000)
  it.bench(fn() { it.keep(must(() => df.select([e]))) })
}
