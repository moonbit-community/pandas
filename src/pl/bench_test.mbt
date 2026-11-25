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

///|
/// The M3 benchmark table (n = 1,000,000 rows): `gi` an `Int64` key with exactly
/// `groups` distinct values (every key `groups` apart in a scrambled order),
/// `gs` the same key as a `String` (`"key<value>"`), `v` an `Int64` value.
/// Inputs are built outside the timed closure.
fn m3_bench_df(groups : Int32) -> @pl.DataFrame raise @pl.PolarsError {
  let keys : Array[Int64] = Array::makei(bench_n, i => {
    i.to_int64() * 7919L % groups.to_int64()
  })
  @pl.DataFrame::new([
    @pl.Series::int64("gi", keys),
    @pl.Series::str("gs", keys.map(k => "key\{k}")),
    @pl.Series::int64("v", Array::makei(bench_n, i => (i % 1000).to_int64())),
  ])
}

///|
/// The aggregations of the M3 `group_by` benchmarks.
fn m3_bench_aggs() -> Array[@pl.Expr] {
  [
    @pl.col("v").sum().alias("sum"),
    @pl.col("v").mean().alias("mean"),
    @pl.len().alias("len"),
  ]
}

///|
test "bench m3 group_by Int64 key 1000 groups sum/mean/len n=1000000" (
  it : @bench.T,
) {
  let df = must(() => m3_bench_df(1000))
  it.bench(fn() {
    it.keep(must(() => df.group_by([@pl.col("gi")]).agg(m3_bench_aggs())))
  })
}

///|
test "bench m3 group_by Int64 key 500000 groups sum/mean/len n=1000000" (
  it : @bench.T,
) {
  let df = must(() => m3_bench_df(500000))
  it.bench(fn() {
    it.keep(must(() => df.group_by([@pl.col("gi")]).agg(m3_bench_aggs())))
  })
}

///|
test "bench m3 group_by String key 1000 groups sum/mean/len n=1000000" (
  it : @bench.T,
) {
  let df = must(() => m3_bench_df(1000))
  it.bench(fn() {
    it.keep(must(() => df.group_by([@pl.col("gs")]).agg(m3_bench_aggs())))
  })
}

///|
test "bench m3 group_by String key 500000 groups sum/mean/len n=1000000" (
  it : @bench.T,
) {
  let df = must(() => m3_bench_df(500000))
  it.bench(fn() {
    it.keep(must(() => df.group_by([@pl.col("gs")]).agg(m3_bench_aggs())))
  })
}

///|
test "bench m3 over sum Int64 key 1000 groups n=1000000" (it : @bench.T) {
  let df = must(() => m3_bench_df(1000))
  it.bench(fn() {
    it.keep(
      must(() => {
        df.with_columns([
          @pl.col("v").sum().over([@pl.col("gi")]).alias("total"),
        ])
      }),
    )
  })
}

///|
test "bench m3 over sum Int64 key 500000 groups n=1000000" (it : @bench.T) {
  let df = must(() => m3_bench_df(500000))
  it.bench(fn() {
    it.keep(
      must(() => {
        df.with_columns([
          @pl.col("v").sum().over([@pl.col("gi")]).alias("total"),
        ])
      }),
    )
  })
}

///|
test "bench m3 over sum String key 1000 groups n=1000000" (it : @bench.T) {
  let df = must(() => m3_bench_df(1000))
  it.bench(fn() {
    it.keep(
      must(() => {
        df.with_columns([
          @pl.col("v").sum().over([@pl.col("gs")]).alias("total"),
        ])
      }),
    )
  })
}

///|
test "bench m3 over sum String key 500000 groups n=1000000" (it : @bench.T) {
  let df = must(() => m3_bench_df(500000))
  it.bench(fn() {
    it.keep(
      must(() => {
        df.with_columns([
          @pl.col("v").sum().over([@pl.col("gs")]).alias("total"),
        ])
      }),
    )
  })
}

///|
/// Left: the keys 0..1M in a scrambled order (unique). Right: 1M rows whose
/// keys are `i / 2` (500 000 distinct keys, each twice). Every left key below
/// 500 000 matches twice, so the inner join has 1M rows. The unique-key
/// joins are in `join_bench_test.mbt`.
fn m3_join_dup_frames() -> (@pl.DataFrame, @pl.DataFrame) {
  let l = join_bench_frame(join_bench_permutation(7), "i")
  let r = join_bench_frame(Array::makei(bench_n, i => (i / 2).to_int64()), "j")
  (l, r)
}

///|
test "bench m3 join inner int64 right keys repeated twice 1M x 1M" (
  it : @bench.T,
) {
  let (l, r) = m3_join_dup_frames()
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")]))) })
}

///|
test "bench m3 join left int64 right keys repeated twice 1M x 1M" (
  it : @bench.T,
) {
  let (l, r) = m3_join_dup_frames()
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")], how=Left))) })
}

///|
test "bench m3 group_by Int64 key 1 group sum/mean/len n=1000000" (
  it : @bench.T,
) {
  let df = must(() => m3_bench_df(1))
  it.bench(fn() {
    it.keep(must(() => df.group_by([@pl.col("gi")]).agg(m3_bench_aggs())))
  })
}

///|
test "bench m3 group_by String key 1 group sum/mean/len n=1000000" (
  it : @bench.T,
) {
  let df = must(() => m3_bench_df(1))
  it.bench(fn() {
    it.keep(must(() => df.group_by([@pl.col("gs")]).agg(m3_bench_aggs())))
  })
}

///|
/// Left: 1M rows, the key is `i % 10` (10 distinct keys). Right: 10 rows that
/// all have the key 0. The 100 000 left rows with key 0 match 10 rows each, so
/// the Inner join has 1,000,000 rows (the Left join 1,900,000); the cost must
/// follow the output.
fn m3_join_same_key_frames() -> (@pl.DataFrame, @pl.DataFrame) {
  let l = join_bench_frame(Array::makei(bench_n, i => (i % 10).to_int64()), "i")
  let r = join_bench_frame(Array::makei(10, _ => 0L), "j")
  (l, r)
}

///|
test "bench m3 join inner int64 right keys all equal 1M x 10" (it : @bench.T) {
  let (l, r) = m3_join_same_key_frames()
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")]))) })
}

///|
test "bench m3 join left int64 right keys all equal 1M x 10" (it : @bench.T) {
  let (l, r) = m3_join_same_key_frames()
  it.bench(fn() { it.keep(must(() => l.join(r, on=[@pl.col("k")], how=Left))) })
}

// ---- M4: CSV, 1M rows x 5 columns (i64, f64, str, bool, date) ----

///|
/// A CSV text of `bench_n` rows and five columns: an integer, a float, a
/// string, a boolean and a date.
fn csv_bench_text() -> String {
  let sb = StringBuilder()
  sb.write_string("i,f,s,b,d\n")
  for i in 0..<bench_n {
    let day = i % 28 + 1
    let month = i % 12 + 1
    sb.write_string("\{i},\{i % 1000}.\{i % 97 + 10},str\{i % 1000},")
    sb.write_string(if i % 2 == 0 { "true" } else { "false" })
    sb.write_string(
      ",2024-\{if month < 10 { "0" } else { "" }}\{month}-\{if day < 10 { "0" } else { "" }}\{day}\n",
    )
  }
  sb.to_string()
}

///|
fn csv_bench_must(text : String, options : @pl.CsvReadOptions) -> @pl.DataFrame {
  @pl.read_csv_str(text, options~) catch {
    e => abort("\{e}")
  }
}

///|
test "bench csv read_csv_str 5 columns n=1000000 inferred default" (
  it : @bench.T,
) {
  let text = csv_bench_text()
  let options = @pl.CsvReadOptions::new()
  it.bench(fn() { it.keep(csv_bench_must(text, options).height()) })
}

///|
test "bench csv read_csv_str 5 columns n=1000000 inferred try_parse_dates=true" (
  it : @bench.T,
) {
  let text = csv_bench_text()
  let options = @pl.CsvReadOptions::new(try_parse_dates=true)
  it.bench(fn() { it.keep(csv_bench_must(text, options).height()) })
}

///|
test "bench csv read_csv_str 5 columns n=1000000 all strings" (it : @bench.T) {
  let text = csv_bench_text()
  let options = @pl.CsvReadOptions::new(infer_schema_length=Some(0))
  it.bench(fn() { it.keep(csv_bench_must(text, options).height()) })
}

///|
test "bench csv read_csv_str 5 columns n=1000000 overrides" (it : @bench.T) {
  let text = csv_bench_text()
  let options = @pl.CsvReadOptions::new(
    schema_overrides=Map::from_array([
      ("i", @pl.DataType::Int64),
      ("f", Float64),
      ("s", String),
      ("b", Boolean),
      ("d", Date),
    ]),
  )
  it.bench(fn() { it.keep(csv_bench_must(text, options).height()) })
}

///|
/// The frame of the write benchmarks: i64, f64, str (every 5th needs quotes), bool, date.
fn csvw_bench_frame() -> @pl.DataFrame {
  must(() => {
    @pl.DataFrame::new([
      @pl.Series::int64(
        "i",
        Array::makei(bench_n, i => i.to_int64() * 7919L - 1000L),
      ),
      @pl.Series::float64(
        "f",
        Array::makei(bench_n, i => i.to_double() * 0.37 - 5.0),
      ),
      @pl.Series::str(
        "s",
        Array::makei(bench_n, i => {
          if i % 5 == 0 {
            "a,\"q\"\{i}"
          } else {
            "value\{i}"
          }
        }),
      ),
      @pl.Series::bool("b", Array::makei(bench_n, i => i % 3 == 0)),
      @pl.Series::date("d", Array::makei(bench_n, i => i % 40000)),
    ])
  })
}

///|
test "bench write_csv_str 1M rows x 5 columns (i64 f64 str bool date)" (
  it : @bench.T,
) {
  let df = csvw_bench_frame()
  it.bench(fn() { it.keep(must(() => @pl.write_csv_str(df))) })
}

///|
test "bench write_csv_str 1M rows x 5 columns, quote_style always" (
  it : @bench.T,
) {
  let df = csvw_bench_frame()
  let o = @pl.CsvWriteOptions::new(quote_style=Always)
  it.bench(fn() { it.keep(must(() => @pl.write_csv_str(df, options=o))) })
}

///|
test "bench write_csv_str 1M rows x 1 string column needing quotes" (
  it : @bench.T,
) {
  let df = must(() => {
    @pl.DataFrame::new([
      @pl.Series::str("s", Array::makei(bench_n, i => "x,\"y\" \{i} z")),
    ])
  })
  it.bench(fn() { it.keep(must(() => @pl.write_csv_str(df))) })
}
