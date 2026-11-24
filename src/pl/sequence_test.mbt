///|
fn seq_i64(name : String, vs : Array[Int64?]) -> @pl.Series {
  @pl.Series::int64_nullable(name, vs)
}

// ---------------------------------------------------------------------------
// shift
// ---------------------------------------------------------------------------

///|
test "shift moves values down and leaves null in the first rows" {
  let s = seq_i64("a", [Some(1L), None, Some(3L), Some(4L)])
  let down = s.shift(1)
  assert_eq(down.to_int64_array(), [None, Some(1L), None, Some(3L)])
  assert_eq(down.name(), "a")
  assert_eq(down.dtype(), @pl.DataType::Int64)
  assert_eq(s.shift(-1).to_int64_array(), [None, Some(3L), Some(4L), None])
  assert_eq(s.shift(0).to_int64_array(), s.to_int64_array())
  // beyond the length (either way) nothing is left
  assert_eq(s.shift(10).to_int64_array(), [None, None, None, None])
  assert_eq(s.shift(-4).to_int64_array(), [None, None, None, None])
  // n at the edge of Int32 does not overflow
  assert_eq(s.shift(-2147483648).null_count(), 4)
  assert_eq(s.shift(2147483647).null_count(), 4)
  assert_eq(seq_i64("e", []).shift(3).len(), 0)
}

///|
test "shift keeps every dtype" {
  let b = @pl.Series::bool_nullable("b", [Some(true), None, Some(false)])
  assert_eq(b.shift(1).to_bool_array(), [None, Some(true), None])
  let f = @pl.Series::float64("f", [1.5, 0.0 / 0.0])
  assert_true(f.shift(-1).get(0) is Float64(x) && x.is_nan())
  let s = @pl.Series::str_nullable("s", [Some("a"), None, Some("\u{1F600}")])
  assert_eq(s.shift(2).to_str_array(), [None, None, Some("a")])
  let d = @pl.Series::date("d", [1, 2])
  assert_eq(d.shift(1).get(1), @pl.AnyValue::Date(1))
  assert_eq(d.shift(1).dtype(), @pl.DataType::Date)
  let t = @pl.Series::datetime("t", [1L, 2L])
  assert_eq(t.shift(-1).get(0), @pl.AnyValue::Datetime(2L))
  // a null series stays null
  let n = @pl.Series::null("n", 3).shift(1)
  assert_eq(n.dtype(), @pl.DataType::Null)
  assert_eq(n.len(), 3)
}

///|
test "shift fill_value: same type, supertype, null series" {
  let s = @pl.Series::int32_nullable("a", [Some(1), None, Some(3)])
  let r = s.shift(1, fill_value=@pl.AnyValue::Int32(9))
  assert_eq(r.to_int32_array(), [Some(9), Some(1), None])
  // an existing null stays null, only the new rows are filled
  assert_eq(s.shift(-1, fill_value=@pl.AnyValue::Int32(9)).to_int32_array(), [
    None,
    Some(3),
    Some(9),
  ])
  // supertype of Int32 and Int64 / Float64 / String
  let wide = s.shift(1, fill_value=@pl.AnyValue::Int64(3000000000L))
  assert_eq(wide.dtype(), @pl.DataType::Int64)
  assert_eq(wide.get(0), @pl.AnyValue::Int64(3000000000L))
  let fl = s.shift(1, fill_value=@pl.AnyValue::Float64(1.5))
  assert_eq(fl.dtype(), @pl.DataType::Float64)
  assert_eq(fl.get(1), @pl.AnyValue::Float64(1.0))
  let st = s.shift(1, fill_value=@pl.AnyValue::String("x"))
  assert_eq(st.to_str_array(), [Some("x"), Some("1"), None])
  // an explicit null fill is the same as no fill, the type is kept
  assert_eq(
    s.shift(1, fill_value=@pl.AnyValue::Null).dtype(),
    @pl.DataType::Int32,
  )
  // a null series takes the type of the value
  let n = @pl.Series::null("n", 2).shift(1, fill_value=@pl.AnyValue::Int32(5))
  assert_eq(n.dtype(), @pl.DataType::Int32)
  assert_eq(n.to_int32_array(), [Some(5), None])
  // all rows are fill rows
  assert_eq(s.shift(10, fill_value=@pl.AnyValue::Int32(0)).to_int32_array(), [
    Some(0),
    Some(0),
    Some(0),
  ])
}

///|
test "shift fill_value: Boolean in Date, Date in Boolean" {
  let d = @pl.Series::date("d", [10, 20])
  let r = d.shift(1, fill_value=@pl.AnyValue::Boolean(true))
  assert_eq(r.dtype(), @pl.DataType::Date)
  assert_eq(r.to_list(), [@pl.AnyValue::Date(1), @pl.AnyValue::Date(10)])
  let t = @pl.Series::datetime("t", [10L, 20L])
  assert_eq(
    t.shift(-1, fill_value=@pl.AnyValue::Boolean(false)).get(1),
    @pl.AnyValue::Datetime(0L),
  )
  let b = @pl.Series::bool("b", [true])
  assert_true(
    raises(() => b.shift(1, fill_value=@pl.AnyValue::Date(100)))
    is Some(@pl.ComputeError("fill value '1970-04-11' is not supported")),
  )
  assert_true(
    raises(() => b.shift(1, fill_value=@pl.AnyValue::Datetime(5L)))
    is Some(
      @pl.ComputeError(
        "fill value '1970-01-01 00:00:00.000005' is not supported",
      ),
    ),
  )
}

// ---------------------------------------------------------------------------
// diff
// ---------------------------------------------------------------------------

///|
test "diff of a series with a null gives null on both sides" {
  let s = seq_i64("a", [Some(1L), None, Some(3L), Some(4L)])
  assert_eq(s.diff().to_int64_array(), [None, None, None, Some(1L)])
  assert_eq(s.diff(n=2).to_int64_array(), [None, None, Some(2L), None])
  assert_eq(s.diff(n=-1).to_int64_array(), [None, None, Some(-1L), None])
  assert_eq(s.diff(n=0).to_int64_array(), [Some(0L), None, Some(0L), Some(0L)])
  assert_eq(s.diff(n=10).null_count(), 4)
  assert_eq(s.diff().name(), "a")
}

///|
test "diff wraps around on overflow and follows IEEE for floats" {
  let s = @pl.Series::int64("a", [1L, @int64.MAX_VALUE, @int64.MIN_VALUE])
  assert_eq(s.diff().to_int64_array(), [
    None,
    Some(@int64.MAX_VALUE - 1L),
    Some(1L),
  ])
  let i = @pl.Series::int32("a", [@int.MAX_VALUE, @int.MIN_VALUE])
  assert_eq(i.diff().to_int32_array(), [None, Some(1)])
  let inf = 1.0 / 0.0
  let f = @pl.Series::float64("f", [inf, inf, 1.0])
  let d = f.diff()
  assert_eq(d.dtype(), @pl.DataType::Float64)
  assert_true(d.get(1) is Float64(x) && x.is_nan())
  assert_eq(d.get(2), @pl.AnyValue::Float64(1.0 - inf))
  let g = @pl.Series::float32("g", [1.0, 4.0])
  assert_eq(g.diff().get(1), @pl.AnyValue::Float32(3.0))
}

///|
test "diff: types without a difference, Null series" {
  assert_true(
    raises(() => @pl.Series::bool("b", [true, false]).diff())
    is Some(
      @pl.InvalidOperation(
        "`subtract` operation not supported for dtype `bool`",
      ),
    ),
  )
  assert_true(
    raises(() => @pl.Series::str("s", ["a"]).diff())
    is Some(
      @pl.InvalidOperation(
        "sub operation not supported for dtypes `str` and `str`",
      ),
    ),
  )
  // polars gives a Duration for these; the library has none
  assert_true(
    raises(() => @pl.Series::date("d", [1, 2]).diff())
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => @pl.Series::datetime("t", [1L, 2L]).diff())
    is Some(@pl.InvalidOperation(_)),
  )
  let n = @pl.Series::null("n", 3).diff()
  assert_eq(n.dtype(), @pl.DataType::Null)
  assert_eq(n.len(), 3)
}

// ---------------------------------------------------------------------------
// cumulative operations
// ---------------------------------------------------------------------------

///|
test "cum_sum skips nulls, supports reverse and keeps the type" {
  let s = seq_i64("a", [Some(1L), None, Some(3L), Some(4L)])
  assert_eq(s.cum_sum().to_int64_array(), [Some(1L), None, Some(4L), Some(8L)])
  assert_eq(s.cum_sum(reverse=true).to_int64_array(), [
    Some(8L),
    None,
    Some(7L),
    Some(4L),
  ])
  let i = @pl.Series::int32("i", [1, 2])
  assert_eq(i.cum_sum().dtype(), @pl.DataType::Int32)
  assert_eq(
    @pl.Series::float32("f", [0.5, 1.0]).cum_sum().dtype(),
    @pl.DataType::Float32,
  )
  assert_eq(seq_i64("e", []).cum_sum().len(), 0)
  // Boolean counts the true values as Int64
  let b = @pl.Series::bool_nullable("b", [
    Some(true),
    Some(false),
    None,
    Some(true),
  ])
  let c = b.cum_sum()
  assert_eq(c.dtype(), @pl.DataType::Int64)
  assert_eq(c.to_int64_array(), [Some(1L), Some(1L), None, Some(2L)])
}

///|
test "cum_sum and cum_prod wrap around instead of trapping" {
  let s = @pl.Series::int64("a", [@int64.MAX_VALUE, 1L])
  assert_eq(s.cum_sum().to_int64_array(), [
    Some(@int64.MAX_VALUE),
    Some(@int64.MIN_VALUE),
  ])
  let i = @pl.Series::int32("i", [@int.MAX_VALUE, 1])
  assert_eq(i.cum_sum().to_int32_array(), [
    Some(@int.MAX_VALUE),
    Some(@int.MIN_VALUE),
  ])
  // the product of Int32 is Int64, it does not wrap at 32 bits
  let p = @pl.Series::int32("p", [1048576, 1048576, 1048576])
  let r = p.cum_prod()
  assert_eq(r.dtype(), @pl.DataType::Int64)
  assert_eq(r.to_int64_array(), [
    Some(1048576L),
    Some(1099511627776L),
    Some(1152921504606846976L),
  ])
  let w = @pl.Series::int64("w", [4294967296L, 4294967296L])
  assert_eq(w.cum_prod().to_int64_array(), [Some(4294967296L), Some(0L)])
}

///|
test "cum_sum of floats: NaN spreads, a leading -0.0 becomes 0.0" {
  let nan = 0.0 / 0.0
  let f = @pl.Series::float64("f", [1.0, nan, 2.0])
  let c = f.cum_sum()
  assert_eq(c.get(0), @pl.AnyValue::Float64(1.0))
  assert_true(c.get(1) is Float64(x) && x.is_nan())
  assert_true(c.get(2) is Float64(x) && x.is_nan())
  let z = @pl.Series::float64("z", [-0.0, -0.0]).cum_sum()
  assert_true(golden_same(z, @pl.Series::float64("z", [0.0, 0.0])))
  let p = @pl.Series::float64("z", [-0.0, -0.0]).cum_prod()
  assert_true(golden_same(p, @pl.Series::float64("z", [-0.0, 0.0])))
}

///|
test "cum_min and cum_max: NaN is ignored, strings by code point, Boolean" {
  let nan = 0.0 / 0.0
  let f = @pl.Series::float64_nullable("f", [
    Some(nan),
    Some(2.0),
    None,
    Some(nan),
    Some(1.0),
  ])
  let mn = f.cum_min()
  assert_true(mn.get(0) is Float64(x) && x.is_nan())
  assert_eq(mn.get(1), @pl.AnyValue::Float64(2.0))
  assert_eq(mn.get(2), @pl.AnyValue::Null)
  assert_eq(mn.get(3), @pl.AnyValue::Float64(2.0))
  assert_eq(mn.get(4), @pl.AnyValue::Float64(1.0))
  let mx = @pl.Series::float64("f", [1.0, nan, 3.0]).cum_max()
  assert_eq(mx.to_float64_array(), [Some(1.0), Some(1.0), Some(3.0)])
  // on a tie the newer value wins, so -0.0 and 0.0 follow the input
  let z = @pl.Series::float64("z", [0.0, -0.0, 0.0])
  assert_true(golden_same(z.cum_min(), z))
  assert_true(golden_same(z.cum_max(), z))
  // strings: U+FF61 < U+1F600 by code point (not by UTF-16 code unit)
  let s = @pl.Series::str("s", ["\u{1F600}", "\u{FF61}", "a"])
  assert_eq(s.cum_max().to_str_array(), [
    Some("\u{1F600}"),
    Some("\u{1F600}"),
    Some("\u{1F600}"),
  ])
  assert_eq(s.cum_min().to_str_array(), [
    Some("\u{1F600}"),
    Some("\u{FF61}"),
    Some("a"),
  ])
  let b = @pl.Series::bool_nullable("b", [
    Some(true),
    None,
    Some(false),
    Some(true),
  ])
  assert_eq(b.cum_min().to_bool_array(), [
    Some(true),
    None,
    Some(false),
    Some(false),
  ])
  assert_eq(b.cum_max(reverse=true).to_bool_array(), [
    Some(true),
    None,
    Some(true),
    Some(true),
  ])
  let d = @pl.Series::date("d", [5, 3, 9])
  assert_eq(d.cum_min().dtype(), @pl.DataType::Date)
  assert_eq(d.cum_max().to_list(), [
    @pl.AnyValue::Date(5),
    @pl.AnyValue::Date(5),
    @pl.AnyValue::Date(9),
  ])
  let t = @pl.Series::datetime("t", [5L, 3L])
  assert_eq(t.cum_min().dtype(), @pl.DataType::Datetime)
}

///|
test "cum_count counts non-null values and never gives null" {
  let s = seq_i64("a", [Some(1L), None, Some(3L), None])
  let c = s.cum_count()
  assert_eq(c.dtype(), @pl.DataType::Int64)
  assert_eq(c.to_int64_array(), [Some(1L), Some(1L), Some(2L), Some(2L)])
  assert_eq(c.name(), "a")
  assert_eq(s.cum_count(reverse=true).to_int64_array(), [
    Some(2L),
    Some(1L),
    Some(1L),
    Some(0L),
  ])
  // a Null series has no value: zeros
  assert_eq(@pl.Series::null("n", 3).cum_count().to_int64_array(), [
    Some(0L),
    Some(0L),
    Some(0L),
  ])
  assert_eq(@pl.Series::str("s", ["a", "b"]).cum_count().to_int64_array(), [
    Some(1L),
    Some(2L),
  ])
}

///|
test "cumulative operations refuse the types polars refuses" {
  let msg = fn(op : String, t : String) {
    Some(
      @pl.InvalidOperation("`\{op}` operation not supported for dtype `\{t}`"),
    )
  }
  let s = @pl.Series::str("s", ["a"])
  assert_true(raises(() => s.cum_sum()) is Some(@pl.InvalidOperation(_)))
  assert_eq(
    raises(() => s.cum_sum()).map(e => e.to_string()),
    msg("cum_sum", "str").map(e => e.to_string()),
  )
  assert_eq(
    raises(() => s.cum_prod()).map(e => e.to_string()),
    msg("cum_prod", "str").map(e => e.to_string()),
  )
  let d = @pl.Series::date("d", [1])
  assert_eq(
    raises(() => d.cum_sum()).map(e => e.to_string()),
    msg("cum_sum", "date").map(e => e.to_string()),
  )
  assert_eq(
    raises(() => d.cum_prod()).map(e => e.to_string()),
    msg("cum_prod", "date").map(e => e.to_string()),
  )
  let t = @pl.Series::datetime("t", [1L])
  assert_eq(
    raises(() => t.cum_sum()).map(e => e.to_string()),
    msg("cum_sum", "datetime[μs]").map(e => e.to_string()),
  )
  // the Null type: every cumulative operation but cum_count is refused
  let n = @pl.Series::null("n", 2)
  assert_eq(
    raises(() => n.cum_sum()).map(e => e.to_string()),
    msg("cum_sum", "null").map(e => e.to_string()),
  )
  assert_eq(
    raises(() => n.cum_prod()).map(e => e.to_string()),
    msg("cum_prod", "null").map(e => e.to_string()),
  )
  assert_eq(
    raises(() => n.cum_min()).map(e => e.to_string()),
    msg("cum_min", "null").map(e => e.to_string()),
  )
  assert_eq(
    raises(() => n.cum_max()).map(e => e.to_string()),
    msg("cum_max", "null").map(e => e.to_string()),
  )
}

// ---------------------------------------------------------------------------
// reverse
// ---------------------------------------------------------------------------

///|
test "reverse every dtype, with nulls" {
  let s = seq_i64("a", [Some(1L), None, Some(3L)])
  assert_eq(s.reverse().to_int64_array(), [Some(3L), None, Some(1L)])
  assert_eq(s.reverse().name(), "a")
  assert_eq(@pl.Series::str("s", ["a", "b"]).reverse().to_str_array(), [
    Some("b"),
    Some("a"),
  ])
  assert_eq(@pl.Series::bool("b", [true, false]).reverse().to_bool_array(), [
    Some(false),
    Some(true),
  ])
  assert_eq(
    @pl.Series::date("d", [1, 2]).reverse().get(0),
    @pl.AnyValue::Date(2),
  )
  assert_eq(
    @pl.Series::float32("f", [1.0, 2.0]).reverse().get(0),
    @pl.AnyValue::Float32(2.0),
  )
  let n = @pl.Series::null("n", 3).reverse()
  assert_eq(n.dtype(), @pl.DataType::Null)
  assert_eq(n.len(), 3)
  assert_eq(seq_i64("e", []).reverse().len(), 0)
}

// ---------------------------------------------------------------------------
// rank
// ---------------------------------------------------------------------------

///|
test "rank Ordinal is Int64 and Average is Float64" {
  let s = @pl.Series::int32("a", [30, 10, 20])
  let o = s.rank(method=@pl.RankMethod::Ordinal)
  assert_eq(o.dtype(), @pl.DataType::Int64)
  assert_eq(o.to_int64_array(), [Some(3L), Some(1L), Some(2L)])
  let a = s.rank()
  assert_eq(a.dtype(), @pl.DataType::Float64)
  assert_eq(a.to_float64_array(), [Some(3.0), Some(1.0), Some(2.0)])
  assert_eq(a.name(), "a")
  // Float32 and temporal types also give Float64 for Average
  assert_eq(
    @pl.Series::float32("f", [2.0, 1.0]).rank().dtype(),
    @pl.DataType::Float64,
  )
  assert_eq(@pl.Series::date("d", [2, 1]).rank().to_float64_array(), [
    Some(2.0),
    Some(1.0),
  ])
}

///|
test "rank: all methods on ties, nulls take no rank" {
  let s = seq_i64("a", [
    Some(3L),
    Some(1L),
    None,
    Some(3L),
    Some(2L),
    Some(1L),
    None,
    Some(5L),
  ])
  let rk = fn(m : @pl.RankMethod, d : Bool) {
    s
    .rank(method=m, descending=d)
    .to_list()
    .map(v => {
      match v {
        Int64(x) => x.to_double()
        Float64(x) => x
        _ => -1.0
      }
    })
  }
  assert_eq(rk(Average, false), [4.5, 1.5, -1.0, 4.5, 3.0, 1.5, -1.0, 6.0])
  assert_eq(rk(Min, false), [4.0, 1.0, -1.0, 4.0, 3.0, 1.0, -1.0, 6.0])
  assert_eq(rk(Max, false), [5.0, 2.0, -1.0, 5.0, 3.0, 2.0, -1.0, 6.0])
  assert_eq(rk(Dense, false), [3.0, 1.0, -1.0, 3.0, 2.0, 1.0, -1.0, 4.0])
  assert_eq(rk(Ordinal, false), [4.0, 1.0, -1.0, 5.0, 3.0, 2.0, -1.0, 6.0])
  // descending: ties keep the original order for Ordinal
  assert_eq(rk(Ordinal, true), [2.0, 5.0, -1.0, 3.0, 4.0, 6.0, -1.0, 1.0])
  assert_eq(rk(Average, true), [2.5, 5.5, -1.0, 2.5, 4.0, 5.5, -1.0, 1.0])
  assert_eq(rk(Dense, true), [2.0, 4.0, -1.0, 2.0, 3.0, 4.0, -1.0, 1.0])
  assert_eq(s.rank().null_count(), 2)
}

///|
test "rank: NaN above numbers and equal to itself, zeros tie, strings by code point" {
  let nan = 0.0 / 0.0
  let inf = 1.0 / 0.0
  let f = @pl.Series::float64("f", [1.0, nan, -inf, -0.0, 0.0, inf, nan])
  assert_eq(f.rank(method=@pl.RankMethod::Min).to_int64_array(), [
    Some(4L),
    Some(6L),
    Some(1L),
    Some(2L),
    Some(2L),
    Some(5L),
    Some(6L),
  ])
  let s = @pl.Series::str("s", ["\u{1F600}", "\u{FF61}", "a", "", "Z"])
  assert_eq(s.rank(method=@pl.RankMethod::Ordinal).to_int64_array(), [
    Some(5L),
    Some(4L),
    Some(3L),
    Some(1L),
    Some(2L),
  ])
  let b = @pl.Series::bool_nullable("b", [
    Some(true),
    Some(false),
    None,
    Some(true),
  ])
  assert_eq(b.rank().to_float64_array(), [Some(2.5), Some(1.0), None, Some(2.5)])
}

///|
test "rank: empty and Null series" {
  assert_eq(seq_i64("e", []).rank().dtype(), @pl.DataType::Float64)
  assert_eq(
    seq_i64("e", []).rank(method=@pl.RankMethod::Dense).dtype(),
    @pl.DataType::Int64,
  )
  let n = @pl.Series::null("n", 3)
  let a = n.rank()
  assert_eq(a.dtype(), @pl.DataType::Float64)
  assert_eq(a.null_count(), 3)
  let o = n.rank(method=@pl.RankMethod::Ordinal)
  assert_eq(o.dtype(), @pl.DataType::Int64)
  assert_eq(o.null_count(), 3)
  let all_null = seq_i64("a", [None, None]).rank()
  assert_eq(all_null.null_count(), 2)
}

///|
test "rank takes O(n log n): 200000 rows" {
  let n = 200000
  let xs : Array[Int64] = Array::makei(n, i => (i * 7919 % 1000).to_int64())
  let s = @pl.Series::int64("a", xs)
  let r = s.rank(method=@pl.RankMethod::Dense)
  assert_eq(r.get(0), @pl.AnyValue::Int64(1L))
  assert_eq(r.len(), n)
  let o = s.rank(method=@pl.RankMethod::Ordinal)
  // ordinal ranks are a permutation of 1..n
  assert_eq(o.max(), @pl.AnyValue::Int64(n.to_int64()))
  assert_eq(o.min(), @pl.AnyValue::Int64(1L))
}

// ---------------------------------------------------------------------------
// fill_null_strategy
// ---------------------------------------------------------------------------

///|
test "fill_null_strategy forward and backward with limit" {
  let s = seq_i64("a", [
    None,
    Some(1L),
    None,
    None,
    Some(3L),
    None,
    None,
    None,
    Some(4L),
    None,
  ])
  assert_eq(s.fill_null_strategy(Forward).to_int64_array(), [
    None,
    Some(1L),
    Some(1L),
    Some(1L),
    Some(3L),
    Some(3L),
    Some(3L),
    Some(3L),
    Some(4L),
    Some(4L),
  ])
  assert_eq(s.fill_null_strategy(Backward).to_int64_array(), [
    Some(1L),
    Some(1L),
    Some(3L),
    Some(3L),
    Some(3L),
    Some(4L),
    Some(4L),
    Some(4L),
    Some(4L),
    None,
  ])
  assert_eq(s.fill_null_strategy(Forward, limit=1).to_int64_array(), [
    None,
    Some(1L),
    Some(1L),
    None,
    Some(3L),
    Some(3L),
    None,
    None,
    Some(4L),
    Some(4L),
  ])
  assert_eq(s.fill_null_strategy(Backward, limit=2).to_int64_array(), [
    Some(1L),
    Some(1L),
    Some(3L),
    Some(3L),
    Some(3L),
    None,
    Some(4L),
    Some(4L),
    Some(4L),
    None,
  ])
  // limit 0 fills nothing
  assert_eq(
    s.fill_null_strategy(Forward, limit=0).to_int64_array(),
    s.to_int64_array(),
  )
  assert_eq(s.fill_null_strategy(Forward).name(), "a")
}

///|
test "fill_null_strategy Min, Max, Mean keep the type" {
  let s = @pl.Series::int32_nullable("a", [
    None,
    Some(5),
    None,
    Some(2),
    None,
    Some(8),
  ])
  assert_eq(s.fill_null_strategy(Min).to_int32_array(), [
    Some(2),
    Some(5),
    Some(2),
    Some(2),
    Some(2),
    Some(8),
  ])
  assert_eq(s.fill_null_strategy(Max).to_int32_array(), [
    Some(8),
    Some(5),
    Some(8),
    Some(2),
    Some(8),
    Some(8),
  ])
  // mean 5 of an integer series
  assert_eq(s.fill_null_strategy(Mean).to_int32_array(), [
    Some(5),
    Some(5),
    Some(5),
    Some(2),
    Some(5),
    Some(8),
  ])
  // truncated towards zero
  let neg = seq_i64("n", [None, Some(-1L), Some(-2L)])
  assert_eq(neg.fill_null_strategy(Mean).to_int64_array(), [
    Some(-1L),
    Some(-1L),
    Some(-2L),
  ])
  let f = @pl.Series::float32_nullable("f", [None, Some(1.5), Some(2.5)])
  let m = f.fill_null_strategy(Mean)
  assert_eq(m.dtype(), @pl.DataType::Float32)
  assert_eq(m.get(0), @pl.AnyValue::Float32(2.0))
  // the mean of the largest Int64 values rounds to 2^63: clamped, no trap
  let big = seq_i64("b", [None, Some(@int64.MAX_VALUE), Some(@int64.MAX_VALUE)])
  assert_eq(
    big.fill_null_strategy(Mean).get(0),
    @pl.AnyValue::Int64(@int64.MAX_VALUE),
  )
  // Date and Datetime
  let d = @pl.Series::date_nullable("d", [None, Some(3), Some(4)])
  assert_eq(d.fill_null_strategy(Mean).get(0), @pl.AnyValue::Date(3))
  assert_eq(d.fill_null_strategy(Max).dtype(), @pl.DataType::Date)
  let t = @pl.Series::datetime_nullable("t", [None, Some(-3L), Some(-2L)])
  assert_eq(t.fill_null_strategy(Mean).get(0), @pl.AnyValue::Datetime(-2L))
  // strings and Boolean
  let st = @pl.Series::str_nullable("s", [None, Some("b"), Some("a")])
  assert_eq(st.fill_null_strategy(Min).to_str_array(), [
    Some("a"),
    Some("b"),
    Some("a"),
  ])
  assert_eq(st.fill_null_strategy(Max).to_str_array(), [
    Some("b"),
    Some("b"),
    Some("a"),
  ])
  let b = @pl.Series::bool_nullable("b", [None, Some(true), Some(false)])
  assert_eq(b.fill_null_strategy(Max).to_bool_array(), [
    Some(true),
    Some(true),
    Some(false),
  ])
  assert_eq(b.fill_null_strategy(Min).to_bool_array(), [
    Some(false),
    Some(true),
    Some(false),
  ])
}

///|
test "fill_null_strategy Min and Max ignore NaN; Mean of NaN is NaN" {
  let nan = 0.0 / 0.0
  let f = @pl.Series::float64_nullable("f", [
    None,
    Some(nan),
    Some(1.5),
    Some(-0.0),
    Some(0.0),
  ])
  assert_eq(f.fill_null_strategy(Min).get(0), @pl.AnyValue::Float64(0.0))
  assert_eq(f.fill_null_strategy(Max).get(0), @pl.AnyValue::Float64(1.5))
  assert_true(f.fill_null_strategy(Mean).get(0) is Float64(x) && x.is_nan())
  // a NaN is a value, not a null: Forward copies it
  let g = @pl.Series::float64_nullable("g", [Some(nan), None])
  assert_true(g.fill_null_strategy(Forward).get(1) is Float64(x) && x.is_nan())
}

///|
test "fill_null_strategy Zero and One" {
  let i = @pl.Series::int32_nullable("i", [None, Some(5)])
  assert_eq(i.fill_null_strategy(Zero).to_int32_array(), [Some(0), Some(5)])
  assert_eq(i.fill_null_strategy(One).to_int32_array(), [Some(1), Some(5)])
  let b = @pl.Series::bool_nullable("b", [None, Some(false)])
  assert_eq(b.fill_null_strategy(Zero).to_bool_array(), [
    Some(false),
    Some(false),
  ])
  assert_eq(b.fill_null_strategy(One).to_bool_array(), [Some(true), Some(false)])
  let s = @pl.Series::str_nullable("s", [None, Some("x")])
  assert_eq(s.fill_null_strategy(Zero).to_str_array(), [Some(""), Some("x")])
  let d = @pl.Series::date_nullable("d", [None, Some(5)])
  assert_eq(d.fill_null_strategy(One).get(0), @pl.AnyValue::Date(1))
  let t = @pl.Series::datetime_nullable("t", [None, Some(5L)])
  assert_eq(t.fill_null_strategy(One).get(0), @pl.AnyValue::Datetime(1L))
  let f = @pl.Series::float32_nullable("f", [None, Some(2.0)])
  assert_eq(f.fill_null_strategy(One).get(0), @pl.AnyValue::Float32(1.0))
  // an all-null series is filled
  assert_eq(
    seq_i64("n", [None, None]).fill_null_strategy(One).to_int64_array(),
    [Some(1L), Some(1L)],
  )
}

///|
test "fill_null_strategy on series with no nulls or no values" {
  let s = seq_i64("a", [Some(1L), Some(2L)])
  assert_true(s.fill_null_strategy(Mean).equals(s))
  assert_true(s.fill_null_strategy(Forward, limit=1).equals(s))
  // nothing to fill: refused types are not looked at
  let st = @pl.Series::str("s", ["a"])
  assert_true(st.fill_null_strategy(One).equals(st))
  // all nulls: min / max / mean / directions leave them
  let n = seq_i64("n", [None, None])
  assert_eq(n.fill_null_strategy(Min).null_count(), 2)
  assert_eq(n.fill_null_strategy(Mean).null_count(), 2)
  assert_eq(n.fill_null_strategy(Forward).null_count(), 2)
  assert_eq(n.fill_null_strategy(Backward).dtype(), @pl.DataType::Int64)
  // the Null type stays Null for the strategies that need no value
  let z = @pl.Series::null("z", 2)
  assert_eq(z.fill_null_strategy(Forward).dtype(), @pl.DataType::Null)
  assert_eq(z.fill_null_strategy(Max).dtype(), @pl.DataType::Null)
  assert_eq(z.fill_null_strategy(Mean).dtype(), @pl.DataType::Null)
  assert_eq(seq_i64("e", []).fill_null_strategy(Backward).len(), 0)
}

///|
test "fill_null_strategy errors" {
  let s = seq_i64("a", [None, Some(1L)])
  let limit_msg = "can only specify `limit` when strategy is set to 'backward' or 'forward'"
  for st in [@pl.FillStrategy::Min, Max, Mean, Zero, One] {
    assert_true(
      raises(() => s.fill_null_strategy(st, limit=1))
      is Some(@pl.InvalidOperation(m)) &&
      m == limit_msg,
    )
  }
  // limit 0 is also refused, and checked before the negative limit
  assert_true(
    raises(() => s.fill_null_strategy(Zero, limit=0))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => s.fill_null_strategy(Min, limit=-1))
    is Some(@pl.InvalidOperation(m)) &&
    m == limit_msg,
  )
  assert_true(
    raises(() => s.fill_null_strategy(Forward, limit=-1))
    is Some(@pl.InvalidOperation("number too small to fit in target type")),
  )
  let b = @pl.Series::bool_nullable("b", [None, Some(true)])
  assert_true(
    raises(() => b.fill_null_strategy(Mean))
    is Some(
      @pl.InvalidOperation("`mean` operation not supported for dtype `Boolean`"),
    ),
  )
  let st = @pl.Series::str_nullable("s", [None, Some("a")])
  assert_true(
    raises(() => st.fill_null_strategy(Mean))
    is Some(@pl.InvalidOperation("fill-null strategy Mean is not supported")),
  )
  assert_true(
    raises(() => st.fill_null_strategy(One))
    is Some(@pl.InvalidOperation("fill-null strategy One is not supported")),
  )
  let n = @pl.Series::null("n", 2)
  assert_true(
    raises(() => n.fill_null_strategy(Zero))
    is Some(
      @pl.InvalidOperation(
        "fill null strategy not yet supported for dtype: null",
      ),
    ),
  )
  assert_true(
    raises(() => n.fill_null_strategy(One)) is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "FillStrategy and RankMethod show their polars names" {
  assert_eq(@pl.FillStrategy::Forward.to_string(), "forward")
  assert_eq(@pl.FillStrategy::Backward.to_string(), "backward")
  assert_eq(@pl.FillStrategy::Min.to_string(), "min")
  assert_eq(@pl.FillStrategy::Max.to_string(), "max")
  assert_eq(@pl.FillStrategy::Mean.to_string(), "mean")
  assert_eq(@pl.FillStrategy::Zero.to_string(), "zero")
  assert_eq(@pl.FillStrategy::One.to_string(), "one")
  assert_eq(@pl.RankMethod::Average.to_string(), "average")
  assert_eq(@pl.RankMethod::Min.to_string(), "min")
  assert_eq(@pl.RankMethod::Max.to_string(), "max")
  assert_eq(@pl.RankMethod::Dense.to_string(), "dense")
  assert_eq(@pl.RankMethod::Ordinal.to_string(), "ordinal")
  assert_true(@pl.RankMethod::Dense == @pl.RankMethod::Dense)
  assert_true(@pl.FillStrategy::Min != @pl.FillStrategy::Max)
}
