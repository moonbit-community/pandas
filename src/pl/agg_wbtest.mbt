///|
fn agg_op_of(name : String) -> AggOp {
  match name {
    "mean" => Mean
    "min" => Min
    "max" => Max
    "median" => Median
    "sum" => Sum
    "std" => Std(1)
    "var" => Var(1)
    "quantile" => Quantile(0.5, Nearest)
    _ => abort("unknown aggregation \{name}")
  }
}

///|
/// The result type of an aggregation with no value to aggregate (all null or
/// no rows). Black-box tests only see `Null` there, so the type is checked
/// here. The table is what polars 2.1.0 gives for the same input (see
/// `docs/golden/agg.json`, the cases whose value is null).
test "a null result keeps the polars result type" {
  let table : Array[(String, DataType, DataType)] = [
    ("max", DataType::Boolean, DataType::Boolean),
    ("max", DataType::Date, DataType::Date),
    ("max", DataType::Datetime, DataType::Datetime),
    ("max", DataType::Float32, DataType::Float32),
    ("max", DataType::Float64, DataType::Float64),
    ("max", DataType::Int32, DataType::Int32),
    ("max", DataType::Int64, DataType::Int64),
    ("max", DataType::Null, DataType::Null),
    ("max", DataType::String, DataType::String),
    ("mean", DataType::Boolean, DataType::Float64),
    ("mean", DataType::Date, DataType::Datetime),
    ("mean", DataType::Datetime, DataType::Datetime),
    ("mean", DataType::Float32, DataType::Float32),
    ("mean", DataType::Float64, DataType::Float64),
    ("mean", DataType::Int32, DataType::Float64),
    ("mean", DataType::Int64, DataType::Float64),
    ("mean", DataType::Null, DataType::Null),
    ("median", DataType::Boolean, DataType::Float64),
    ("median", DataType::Date, DataType::Datetime),
    ("median", DataType::Datetime, DataType::Datetime),
    ("median", DataType::Float32, DataType::Float32),
    ("median", DataType::Float64, DataType::Float64),
    ("median", DataType::Int32, DataType::Float64),
    ("median", DataType::Int64, DataType::Float64),
    ("median", DataType::Null, DataType::Null),
    ("min", DataType::Boolean, DataType::Boolean),
    ("min", DataType::Date, DataType::Date),
    ("min", DataType::Datetime, DataType::Datetime),
    ("min", DataType::Float32, DataType::Float32),
    ("min", DataType::Float64, DataType::Float64),
    ("min", DataType::Int32, DataType::Int32),
    ("min", DataType::Int64, DataType::Int64),
    ("min", DataType::Null, DataType::Null),
    ("min", DataType::String, DataType::String),
    ("quantile", DataType::Datetime, DataType::Datetime),
    ("quantile", DataType::Float32, DataType::Float32),
    ("quantile", DataType::Float64, DataType::Float64),
    ("quantile", DataType::Int32, DataType::Float64),
    ("quantile", DataType::Int64, DataType::Float64),
    ("std", DataType::Boolean, DataType::Float64),
    ("std", DataType::Float32, DataType::Float32),
    ("std", DataType::Float64, DataType::Float64),
    ("std", DataType::Int32, DataType::Float64),
    ("std", DataType::Int64, DataType::Float64),
    ("std", DataType::Null, DataType::Null),
    ("sum", DataType::Null, DataType::Null),
    ("var", DataType::Boolean, DataType::Float64),
    ("var", DataType::Float32, DataType::Float32),
    ("var", DataType::Float64, DataType::Float64),
    ("var", DataType::Int32, DataType::Float64),
    ("var", DataType::Int64, DataType::Float64),
    ("var", DataType::Null, DataType::Null),
  ]
  for entry in table {
    let (name, input, output) = entry
    for n in [0, 2] {
      let col = Column::full_null(input, n)
      let r = agg_column(col, agg_op_of(name))
      assert_eq(r.dtype(), output)
      assert_eq(r.length(), 1)
      assert_eq(r.get(0), AnyValue::Null)
    }
  }
  // the same for the Boolean and Null types of `Null`-only operations
  for
    dtype in [
      DataType::Boolean,
      DataType::Int32,
      DataType::Int64,
      DataType::Float32,
      DataType::Float64,
      DataType::String,
      DataType::Date,
      DataType::Datetime,
      DataType::Null,
    ] {
    for op in [AggOp::First, AggOp::Last] {
      let r = agg_column(Column::full_null(dtype, 2), op)
      assert_eq(r.dtype(), dtype)
      assert_eq(r.get(0), AnyValue::Null)
      let e = agg_column(Column::full_null(dtype, 0), op)
      assert_eq(e.dtype(), dtype)
      assert_eq(e.length(), 1)
    }
  }
  // polars panics on the quantile of no dates; here it is a null Datetime
  let q = agg_column(
    Column::full_null(DataType::Date, 0),
    Quantile(0.5, Linear),
  )
  assert_eq(q.dtype(), DataType::Datetime)
  assert_eq(q.get(0), AnyValue::Null)
}

///|
test "count and len results are Int64 of length 1" {
  let col = Series::int32_nullable("a", [Some(1), None, Some(3)]).col
  let c = agg_column(col, Count)
  assert_eq(c.dtype(), DataType::Int64)
  assert_eq(c.get(0), AnyValue::Int64(2L))
  let l = agg_column(col, Len)
  assert_eq(l.dtype(), DataType::Int64)
  assert_eq(l.get(0), AnyValue::Int64(3L))
  assert_eq(agg_column(Column::Null(4), Count).get(0), AnyValue::Int64(0L))
  assert_eq(agg_column(Column::Null(4), Len).get(0), AnyValue::Int64(4L))
  assert_eq(agg_column(Column::Null(0), Len).get(0), AnyValue::Int64(0L))
}

///|
test "non-null results have the documented types" {
  let cases : Array[(Column, AggOp, DataType)] = [
    (Series::bool("a", [true]).col, Sum, DataType::Int64),
    (Series::int32("a", [1]).col, Sum, DataType::Int32),
    (Series::int32("a", [1]).col, Product, DataType::Int64),
    (Series::float32("a", [1.0]).col, Sum, DataType::Float32),
    (Series::float32("a", [1.0]).col, Mean, DataType::Float32),
    (Series::int64("a", [1L]).col, Mean, DataType::Float64),
    (Series::date("a", [1]).col, Mean, DataType::Datetime),
    (Series::date("a", [1]).col, Min, DataType::Date),
    (Series::datetime("a", [1L]).col, Median, DataType::Datetime),
    (Series::str("a", ["x"]).col, Max, DataType::String),
    (Series::bool("a", [true]).col, Min, DataType::Boolean),
    (Series::bool("a", [true]).col, Median, DataType::Float64),
  ]
  for entry in cases {
    let (col, op, dtype) = entry
    let r = agg_column(col, op)
    assert_eq(r.dtype(), dtype)
    assert_eq(r.length(), 1)
    assert_true(!r.get(0).is_null())
  }
}

///|
/// A null slot may hold any value: the aggregations must look at the validity,
/// not at the slot.
test "sum, mean and extremes ignore the value under a null slot" {
  let validity = @arrow.Bitmap::from_array([false, true, true])
  let i32s = Column::Int32(
    @arrow.PrimArray::new(FixedArray::from_array([1000, 5, 7]), Some(validity)),
  )
  assert_eq(agg_column(i32s, Sum).get(0), AnyValue::Int32(12))
  assert_eq(agg_column(i32s, Min).get(0), AnyValue::Int32(5))
  assert_eq(agg_column(i32s, Max).get(0), AnyValue::Int32(7))
  assert_eq(agg_column(i32s, Mean).get(0), AnyValue::Float64(6.0))
  assert_eq(agg_column(i32s, Product).get(0), AnyValue::Int64(35L))
  let i64s = Column::Int64(
    @arrow.PrimArray::new(
      FixedArray::from_array([1000L, 5L, 7L]),
      Some(validity),
    ),
  )
  assert_eq(agg_column(i64s, Sum).get(0), AnyValue::Int64(12L))
  let f64s = Column::Float64(
    @arrow.PrimArray::new(
      FixedArray::from_array([1000.0, 5.0, 7.0]),
      Some(validity),
    ),
  )
  assert_eq(agg_column(f64s, Sum).get(0), AnyValue::Float64(12.0))
  assert_eq(agg_column(f64s, Median).get(0), AnyValue::Float64(6.0))
  let f32s = Column::Float32(
    @arrow.PrimArray::new(
      FixedArray::from_array([1000.0, 5.0, 7.0]),
      Some(validity),
    ),
  )
  assert_eq(agg_column(f32s, Sum).get(0), AnyValue::Float32(12.0))
}

///|
/// The quantile as it was computed before the selection algorithm: a stable
/// full sort of a copy, then the positions of `agg_quantile_ranks`' formula
/// written out again.
fn agg_ref_quantile(
  xs0 : Array[Double],
  nulls : Int32,
  q : Double,
  how : QuantileMethod,
) -> Double? {
  let xs = xs0.copy()
  let n = xs.length()
  if n == 0 {
    return None
  }
  xs.mut_view().stable_sort_by(agg_double_cmp)
  let skip = nulls.to_double()
  let top = n.to_double() - 1.0 + skip
  let pos = (n.to_double() - 1.0) * q + skip
  let base = match how {
    Nearest => agg_round_index(pos)
    Higher => pos.ceil()
    Lower | Midpoint | Linear => pos.floor()
    Equiprobable => {
      let k = (n.to_double() * q).ceil() - 1.0
      (if k < 0.0 { 0.0 } else { k }) + skip
    }
  }
  let base = if base < skip { skip } else if base > top { top } else { base }
  let upper = if pos.ceil() > top { top } else { pos.ceil() }
  let lo = xs[(base - skip).to_int()]
  let hi = xs[(upper - skip).to_int()]
  Some(
    match how {
      Nearest | Higher | Lower | Equiprobable => lo
      Midpoint => if base == upper || lo == hi { lo } else { (lo + hi) / 2.0 }
      Linear =>
        if base == upper || lo == hi {
          lo
        } else {
          lo + (pos - base) * (hi - lo)
        }
    },
  )
}

///|
fn agg_bits(x : Double?) -> Int64? {
  // the sign and payload of a NaN that comes out of arithmetic (`(lo + hi) / 2`)
  // are up to the engine (wasm gives a different one than native), so every
  // NaN is one value; everything else, including the sign of zero, is compared
  // bit for bit
  x.map(v => {
    if v.is_nan() {
      0x7FF8000000000000L
    } else {
      v.reinterpret_as_int64()
    }
  })
}

///|
/// Selection and the single sort give the same bits as the full stable sort,
/// including which of `0.0` / `-0.0` sits at a rank (NaN is one value, see
/// `agg_bits`).
test "quantile by selection is bit for bit the full-sort quantile" {
  let nan = 0.0 / 0.0
  let neg_nan = -nan
  let pool : Array[Double] = [
    0.0,
    -0.0,
    0.0,
    -0.0,
    nan,
    neg_nan,
    1.0 / 0.0,
    -1.0 / 0.0,
    1.5,
    -1.5,
    2.0,
    7.0,
    -3.0,
    1.0e300,
    -1.0e300,
    5.0e-324,
    0.1,
    0.2,
    0.3,
  ]
  let qs : Array[Double] = [
    0.0, 0.1, 0.25, 0.3333333333333333, 0.5, 0.6, 0.75, 0.9, 0.99, 1.0,
  ]
  let hows : Array[QuantileMethod] = [
    Nearest,
    Lower,
    Higher,
    Midpoint,
    Linear,
    Equiprobable,
  ]
  let mut state = 12345UL
  let mut cases = 0
  for round in 0..<400 {
    let (s1, size_r) = lcg_next_w(state, if round < 300 { 12 } else { 700 })
    state = s1
    let size = size_r + 1
    let xs : Array[Double] = []
    // some rounds draw from a tiny pool (ties), some from all of it
    let width = if round % 3 == 0 { 5 } else { pool.length() }
    for _ in 0..<size {
      let (s2, k) = lcg_next_w(state, width)
      state = s2
      xs.push(pool[k])
    }
    let (s3, nulls) = lcg_next_w(state, 4)
    state = s3
    let sorted = xs.copy()
    sorted.mut_view().stable_sort_by(agg_double_cmp)
    for q in qs {
      for how in hows {
        let want = agg_bits(agg_ref_quantile(xs, nulls, q, how))
        let got = agg_bits(
          agg_quantile_value(xs.copy(), nulls, q, how, () => xs.copy()),
        )
        if got != want {
          fail("selection differs: round \{round} nulls=\{nulls} q=\{q}")
        }
        let got2 = agg_bits(agg_quantile_sorted(sorted, nulls, q, how))
        if got2 != want {
          fail("sorted differs: round \{round} nulls=\{nulls} q=\{q}")
        }
        cases += 1
      }
    }
  }
  assert_eq(cases, 400 * 10 * 6)
  assert_eq(agg_quantile_value([], 2, 0.5, Linear, () => []), None)
}

///|
/// Next state and a value in `0..<bound` of a small LCG.
fn lcg_next_w(state : UInt64, bound : Int32) -> (UInt64, Int32) {
  let next = state * 6364136223846793005UL + 1442695040888963407UL
  (next, ((next >> 33) % bound.to_uint64()).to_int())
}

///|
/// Sorted, reversed, all-equal, sawtooth and organ-pipe inputs finish and
/// agree with a full sort (the worst cases for a naive pivot).
test "selection on adversarial inputs" {
  let n = 6000
  let shapes : Array[Array[Double]] = [
    Array::makei(n, i => i.to_double()),
    Array::makei(n, i => (n - i).to_double()),
    Array::make(n, 1.5),
    Array::makei(n, i => (i % 7).to_double()),
    Array::makei(n, i => {
      if i < n / 2 {
        i.to_double()
      } else {
        (n - i).to_double()
      }
    }),
    Array::makei(n, i => if i % 2 == 0 { 0.0 } else { -0.0 }),
  ]
  for xs in shapes {
    for q in [0.0, 0.25, 0.5, 0.75, 1.0] {
      let want = agg_bits(agg_ref_quantile(xs, 0, q, Linear))
      let got = agg_bits(
        agg_quantile_value(xs.copy(), 0, q, Linear, () => xs.copy()),
      )
      assert_eq(got, want)
    }
  }
}
