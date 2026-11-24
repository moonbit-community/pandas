///|
let ew_nan : Double = 0.0 / 0.0

///|
let ew_inf : Double = 1.0 / 0.0

///|
let ew_min64 : Int64 = @int64.MIN_VALUE

///|
let ew_max64 : Int64 = @int64.MAX_VALUE

///|
/// Bit pattern of every non-null value, so that the sign of zero and NaN are
/// told apart from plain `==`.
fn ew_bits(s : @pl.Series) -> Array[Int64?] raise {
  s
  .to_float64_array()
  .map(x => {
    match x {
      Some(v) => Some(if v.is_nan() { 0L } else { v.reinterpret_as_int64() })
      None => None
    }
  })
}

///|
test "is_null and is_not_null: normal, null and Null-typed input" {
  let a = @pl.Series::int32_nullable("a", [Some(1), None, Some(3)])
  let r = a.is_null()
  assert_eq(r.name(), "a")
  assert_eq(r.dtype(), @pl.DataType::Boolean)
  assert_eq(r.null_count(), 0)
  assert_eq(r.to_bool_array(), [Some(false), Some(true), Some(false)])
  assert_eq(a.is_not_null().to_bool_array(), [
    Some(true),
    Some(false),
    Some(true),
  ])
  // a column without a validity bitmap
  let b = @pl.Series::str("b", ["x", ""])
  assert_eq(b.is_null().to_bool_array(), [Some(false), Some(false)])
  assert_eq(b.is_not_null().to_bool_array(), [Some(true), Some(true)])
  // every type, including Boolean, String, Date, Datetime
  let d = @pl.Series::date_nullable("d", [None, Some(0)])
  assert_eq(d.is_null().to_bool_array(), [Some(true), Some(false)])
  let t = @pl.Series::datetime_nullable("t", [Some(0L), None])
  assert_eq(t.is_not_null().to_bool_array(), [Some(true), Some(false)])
  let f = @pl.Series::bool_nullable("f", [None, Some(true)])
  assert_eq(f.is_null().to_bool_array(), [Some(true), Some(false)])
  // a Null column is all null; empty input gives empty output
  let n = @pl.Series::null("n", 3)
  assert_eq(n.is_null().to_bool_array(), [Some(true), Some(true), Some(true)])
  assert_eq(n.is_not_null().to_bool_array(), [
    Some(false),
    Some(false),
    Some(false),
  ])
  assert_eq(@pl.Series::int64("e", []).is_null().len(), 0)
  // NaN is not null
  let x = @pl.Series::float64_nullable("x", [Some(ew_nan), None])
  assert_eq(x.is_null().to_bool_array(), [Some(false), Some(true)])
}

///|
test "is_null on a sliced series" {
  let a = @pl.Series::int32_nullable("a", [
    Some(1),
    None,
    Some(3),
    None,
    Some(5),
  ])
  let s = a.slice(1, length=3)
  assert_eq(s.is_null().to_bool_array(), [Some(true), Some(false), Some(true)])
  assert_eq(s.is_not_null().to_bool_array(), [
    Some(false),
    Some(true),
    Some(false),
  ])
}

///|
test "is_nan is_not_nan is_finite is_infinite on floats" {
  let a = @pl.Series::float64_nullable("a", [
    Some(1.0),
    Some(ew_nan),
    None,
    Some(-ew_inf),
    Some(ew_inf),
    Some(-0.0),
  ])
  assert_eq(a.is_nan().to_bool_array(), [
    Some(false),
    Some(true),
    None,
    Some(false),
    Some(false),
    Some(false),
  ])
  assert_eq(a.is_not_nan().to_bool_array(), [
    Some(true),
    Some(false),
    None,
    Some(true),
    Some(true),
    Some(true),
  ])
  assert_eq(a.is_finite().to_bool_array(), [
    Some(true),
    Some(false),
    None,
    Some(false),
    Some(false),
    Some(true),
  ])
  assert_eq(a.is_infinite().to_bool_array(), [
    Some(false),
    Some(false),
    None,
    Some(true),
    Some(true),
    Some(false),
  ])
  assert_eq(a.is_nan().dtype(), @pl.DataType::Boolean)
  let f = @pl.Series::float32("f", [
    Float::from_double(ew_nan),
    2.5,
    1.0e38 * 10.0,
  ])
  assert_eq(f.is_nan().to_bool_array(), [Some(true), Some(false), Some(false)])
  assert_eq(f.is_infinite().to_bool_array(), [
    Some(false),
    Some(false),
    Some(true),
  ])
}

///|
test "is_nan family: integers are never NaN, null stays null, Null is all null" {
  let i = @pl.Series::int32_nullable("i", [Some(1), None])
  assert_eq(i.is_nan().to_bool_array(), [Some(false), None])
  assert_eq(i.is_not_nan().to_bool_array(), [Some(true), None])
  assert_eq(i.is_finite().to_bool_array(), [Some(true), None])
  assert_eq(i.is_infinite().to_bool_array(), [Some(false), None])
  let l = @pl.Series::int64("l", [ew_min64, ew_max64])
  assert_eq(l.is_finite().to_bool_array(), [Some(true), Some(true)])
  let n = @pl.Series::null("n", 2)
  for r in [n.is_nan(), n.is_not_nan(), n.is_finite(), n.is_infinite()] {
    assert_eq(r.dtype(), @pl.DataType::Boolean)
    assert_eq(r.to_bool_array(), [None, None])
  }
}

///|
test "is_nan family: Boolean, String, Date, Datetime are an error" {
  let b = @pl.Series::bool("b", [true])
  assert_true(
    raises(() => b.is_nan())
    is Some(
      @pl.InvalidOperation("`is_nan` operation not supported for dtype `bool`"),
    ),
  )
  let s = @pl.Series::str("s", ["a"])
  assert_true(
    raises(() => s.is_not_nan())
    is Some(
      @pl.InvalidOperation(
        "`is_not_nan` operation not supported for dtype `str`",
      ),
    ),
  )
  let d = @pl.Series::date("d", [1])
  assert_true(
    raises(() => d.is_finite())
    is Some(
      @pl.InvalidOperation(
        "`is_finite` operation not supported for dtype `date`",
      ),
    ),
  )
  let t = @pl.Series::datetime("t", [1L])
  assert_true(
    raises(() => t.is_infinite())
    is Some(
      @pl.InvalidOperation(
        "`is_infinite` operation not supported for dtype `datetime[\u{3bc}s]`",
      ),
    ),
  )
}

///|
test "fill_null widens to the supertype of the column and the value" {
  let a = @pl.Series::int32_nullable("a", [Some(1), None, Some(3)])
  // same type
  let r = a.fill_null(@pl.AnyValue::Int32(9))
  assert_eq(r.name(), "a")
  assert_eq(r.dtype(), @pl.DataType::Int32)
  assert_eq(r.to_int32_array(), [Some(1), Some(9), Some(3)])
  // Int32 column, Float64 value: the whole column becomes Float64
  let f = a.fill_null(@pl.AnyValue::Float64(1.5))
  assert_eq(f.dtype(), @pl.DataType::Float64)
  assert_eq(f.to_float64_array(), [Some(1.0), Some(1.5), Some(3.0)])
  // Int32 column, Int64 value
  let l = a.fill_null(@pl.AnyValue::Int64(ew_max64))
  assert_eq(l.dtype(), @pl.DataType::Int64)
  assert_eq(l.to_int64_array(), [Some(1L), Some(ew_max64), Some(3L)])
  // Int32 column, Float32 value: Float64 (polars: Float32 with Int32 is Float64)
  assert_eq(
    a.fill_null(@pl.AnyValue::Float32(1.5)).dtype(),
    @pl.DataType::Float64,
  )
  // Float32 column, Float32 value stays Float32
  let g = @pl.Series::float32_nullable("g", [None, Some(2.0)])
  let gf = g.fill_null(@pl.AnyValue::Float32(0.5))
  assert_eq(gf.dtype(), @pl.DataType::Float32)
  assert_eq(gf.to_float32_array(), [Some(0.5), Some(2.0)])
  // Boolean column, Int32 value: Int32
  let b = @pl.Series::bool_nullable("b", [None, Some(true)])
  let bi = b.fill_null(@pl.AnyValue::Int32(7))
  assert_eq(bi.dtype(), @pl.DataType::Int32)
  assert_eq(bi.to_int32_array(), [Some(7), Some(1)])
  // numbers and text: String
  let s = a.fill_null(@pl.AnyValue::String("z"))
  assert_eq(s.dtype(), @pl.DataType::String)
  assert_eq(s.to_str_array(), [Some("1"), Some("z"), Some("3")])
  // Date column, Datetime value: Datetime (midnight of the dates)
  let d = @pl.Series::date_nullable("d", [Some(1), None])
  let dt = d.fill_null(@pl.AnyValue::Datetime(5L))
  assert_eq(dt.dtype(), @pl.DataType::Datetime)
  assert_eq(dt.to_list(), [
    @pl.AnyValue::Datetime(86_400_000_000L),
    @pl.AnyValue::Datetime(5L),
  ])
}

///|
test "fill_null with Null keeps the column, a column without null is unchanged" {
  let a = @pl.Series::int32_nullable("a", [Some(1), None])
  let r = a.fill_null(@pl.AnyValue::Null)
  assert_eq(r.dtype(), @pl.DataType::Int32)
  assert_eq(r.to_int32_array(), [Some(1), None])
  // nothing to fill: the type is still the supertype
  let c = @pl.Series::int32("c", [1, 2])
  assert_eq(
    c.fill_null(@pl.AnyValue::Float64(0.5)).dtype(),
    @pl.DataType::Float64,
  )
  assert_eq(c.fill_null(@pl.AnyValue::Int32(0)).to_int32_array(), [
    Some(1),
    Some(2),
  ])
  // a Null column takes the type of the value
  let n = @pl.Series::null("n", 2)
  let nr = n.fill_null(@pl.AnyValue::String("q"))
  assert_eq(nr.dtype(), @pl.DataType::String)
  assert_eq(nr.to_str_array(), [Some("q"), Some("q")])
  assert_eq(n.fill_null(@pl.AnyValue::Null).dtype(), @pl.DataType::Null)
  // empty column
  assert_eq(
    @pl.Series::int32("e", []).fill_null(@pl.AnyValue::Float64(1.0)).dtype(),
    @pl.DataType::Float64,
  )
  // NaN is not null and is kept
  let x = @pl.Series::float64_nullable("x", [Some(ew_nan), None])
  let xr = x.fill_null(@pl.AnyValue::Float64(-1.0))
  assert_eq(xr.to_float64_array()[1], Some(-1.0))
  assert_true(xr.to_float64_array()[0].unwrap().is_nan())
}

///|
test "fill_null with incompatible types is a SchemaMismatch" {
  let b = @pl.Series::bool_nullable("b", [None])
  assert_true(
    raises(() => b.fill_null(@pl.AnyValue::Date(1)))
    is Some(
      @pl.SchemaMismatch("failed to determine supertype of bool and date"),
    ),
  )
  let d = @pl.Series::date_nullable("d", [None])
  assert_true(
    raises(() => d.fill_null(@pl.AnyValue::Boolean(true)))
    is Some(
      @pl.SchemaMismatch("failed to determine supertype of date and bool"),
    ),
  )
  let t = @pl.Series::datetime_nullable("t", [None])
  assert_true(
    raises(() => t.fill_null(@pl.AnyValue::Boolean(true)))
    is Some(
      @pl.SchemaMismatch(
        "failed to determine supertype of datetime[\u{3bc}s] and bool",
      ),
    ),
  )
}

///|
test "between: closed variants, null rows and null bounds" {
  let a = @pl.Series::int32_nullable("a", [
    Some(1),
    Some(2),
    Some(3),
    Some(4),
    None,
    Some(5),
  ])
  let lo = @pl.Series::int32_nullable("lo", [
    Some(2),
    Some(2),
    None,
    Some(1),
    Some(0),
    Some(5),
  ])
  let hi = @pl.Series::int32_nullable("hi", [
    Some(4),
    Some(2),
    Some(4),
    Some(3),
    Some(9),
    Some(5),
  ])
  let both = a.between(lo, hi)
  assert_eq(both.name(), "a")
  assert_eq(both.dtype(), @pl.DataType::Boolean)
  assert_eq(both.to_bool_array(), [
    Some(false),
    Some(true),
    None,
    Some(false),
    None,
    Some(true),
  ])
  assert_eq(a.between(lo, hi, closed=Left).to_bool_array(), [
    Some(false),
    Some(false),
    None,
    Some(false),
    None,
    Some(false),
  ])
  assert_eq(a.between(lo, hi, closed=Right).to_bool_array(), [
    Some(false),
    Some(false),
    None,
    Some(false),
    None,
    Some(false),
  ])
  assert_eq(a.between(lo, hi, closed=Neither).to_bool_array(), [
    Some(false),
    Some(false),
    None,
    Some(false),
    None,
    Some(false),
  ])
  // a null bound gives null, unless the other bound already decides (Kleene)
  let nulls = @pl.Series::int32_nullable("lo", [
    None,
    None,
    None,
    None,
    None,
    None,
  ])
  assert_eq(a.between(nulls, hi).to_bool_array(), [
    None,
    None,
    None,
    Some(false),
    None,
    None,
  ])
  // (a >= lo) & null: false where a < lo
  assert_eq(a.between(lo, nulls).to_bool_array(), [
    Some(false),
    None,
    None,
    None,
    None,
    None,
  ])
}

///|
test "between: the closed argument decides which ends count" {
  let a = @pl.Series::int32("a", [1, 2, 3, 4, 5])
  let lo = @pl.Series::int32("lo", [2])
  let hi = @pl.Series::int32("hi", [4])
  assert_eq(a.between(lo, hi).to_bool_array(), [
    Some(false),
    Some(true),
    Some(true),
    Some(true),
    Some(false),
  ])
  assert_eq(a.between(lo, hi, closed=Left).to_bool_array(), [
    Some(false),
    Some(true),
    Some(true),
    Some(false),
    Some(false),
  ])
  assert_eq(a.between(lo, hi, closed=Right).to_bool_array(), [
    Some(false),
    Some(false),
    Some(true),
    Some(true),
    Some(false),
  ])
  assert_eq(a.between(lo, hi, closed=Neither).to_bool_array(), [
    Some(false),
    Some(false),
    Some(true),
    Some(false),
    Some(false),
  ])
  // lower above upper: nothing is between
  assert_eq(a.between(hi, lo).to_bool_array(), [
    Some(false),
    Some(false),
    Some(false),
    Some(false),
    Some(false),
  ])
}

///|
test "between: supertype, NaN, strings by code point, Null columns" {
  // Int32 column against an Int64 and a Float64 bound
  let a = @pl.Series::int32_nullable("a", [Some(1), Some(2), None])
  let lo = @pl.Series::int64("lo", [2L])
  let hi = @pl.Series::float64("hi", [2.5])
  assert_eq(a.between(lo, hi).to_bool_array(), [Some(false), Some(true), None])
  // NaN is above every number
  let f = @pl.Series::float64("f", [ew_nan, ew_inf, 0.0, -0.0])
  let r = f.between(
    @pl.Series::float64("lo", [-ew_inf]),
    @pl.Series::float64("hi", [ew_inf]),
  )
  assert_eq(r.to_bool_array(), [Some(false), Some(true), Some(true), Some(true)])
  // strings are ordered by code point: U+FF61 < U+1F600
  let s = @pl.Series::str_nullable("s", [
    Some("\u{FF61}"),
    Some("\u{1F600}"),
    Some("a"),
    Some(""),
    None,
  ])
  let sr = s.between(
    @pl.Series::str("lo", ["a"]),
    @pl.Series::str("hi", ["\u{1F600}"]),
  )
  assert_eq(sr.to_bool_array(), [
    Some(true),
    Some(true),
    Some(true),
    Some(false),
    None,
  ])
  // Null columns give null
  let n = @pl.Series::null("n", 2)
  let nr = n.between(@pl.Series::int32("lo", [1]), @pl.Series::int32("hi", [2]))
  assert_eq(nr.dtype(), @pl.DataType::Boolean)
  assert_eq(nr.to_bool_array(), [None, None])
  let i = @pl.Series::int32("i", [1, 2])
  let ni = i.between(@pl.Series::null("lo", 2), @pl.Series::null("hi", 2))
  assert_eq(ni.to_bool_array(), [None, None])
  // empty
  let e = @pl.Series::int32("e", [])
  assert_eq(e.between(lo, hi).len(), 0)
}

///|
test "between: errors" {
  let a = @pl.Series::int32("a", [1, 2, 3, 4, 5, 6])
  let lo3 = @pl.Series::int32("lo", [1, 2, 3])
  let hi6 = @pl.Series::int32("hi", [1, 2, 3, 4, 5, 6])
  assert_true(
    raises(() => a.between(lo3, hi6))
    is Some(
      @pl.ShapeMismatch(
        "could not perform '>=' comparison between series 'a' of length: 6 and series 'lo' of length: 3, because they have different lengths",
      ),
    ),
  )
  assert_true(
    raises(() => a.between(hi6, lo3, closed=Left))
    is Some(
      @pl.ShapeMismatch(
        "could not perform '<' comparison between series 'a' of length: 6 and series 'lo' of length: 3, because they have different lengths",
      ),
    ),
  )
  assert_true(
    raises(() => a.between(lo3, hi6, closed=Neither))
    is Some(
      @pl.ShapeMismatch(
        "could not perform '>' comparison between series 'a' of length: 6 and series 'lo' of length: 3, because they have different lengths",
      ),
    ),
  )
  // types without a common type
  let b = @pl.Series::bool("a", [true])
  let d = @pl.Series::date("d", [1])
  assert_true(raises(() => b.between(d, d)) is Some(@pl.SchemaMismatch(_)))
  let s = @pl.Series::str("s", ["x"])
  assert_true(
    raises(() => a.between(s, s))
    is Some(@pl.ComputeError("cannot compare string with numeric type (i32)")),
  )
}

///|
test "abs: integers wrap at MIN, floats clear the sign" {
  let a = @pl.Series::int32_nullable("a", [
    Some(-5),
    Some(5),
    Some(@int.MIN_VALUE),
    Some(@int.MAX_VALUE),
    None,
  ])
  let r = a.abs()
  assert_eq(r.name(), "a")
  assert_eq(r.dtype(), @pl.DataType::Int32)
  assert_eq(r.to_int32_array(), [
    Some(5),
    Some(5),
    Some(@int.MIN_VALUE),
    Some(@int.MAX_VALUE),
    None,
  ])
  let l = @pl.Series::int64("l", [ew_min64, ew_max64, -1L, 0L])
  assert_eq(l.abs().to_int64_array(), [
    Some(ew_min64),
    Some(ew_max64),
    Some(1L),
    Some(0L),
  ])
  let f = @pl.Series::float64_nullable("f", [
    Some(-0.0),
    Some(-2.5),
    Some(-ew_inf),
    Some(ew_nan),
    None,
  ])
  let fr = f.abs()
  assert_eq(fr.dtype(), @pl.DataType::Float64)
  assert_eq(ew_bits(fr), [
    Some(0L),
    Some(2.5.reinterpret_as_int64()),
    Some(ew_inf.reinterpret_as_int64()),
    Some(0L),
    None,
  ])
  let g = @pl.Series::float32("g", [-1.5, -0.0])
  assert_eq(g.abs().dtype(), @pl.DataType::Float32)
  assert_eq(g.abs().to_float32_array(), [Some(1.5), Some(0.0)])
}

///|
test "abs: Boolean, String, Date, Datetime are refused, Null is polars' error" {
  assert_true(
    raises(() => @pl.Series::bool("b", [true]).abs())
    is Some(@pl.InvalidOperation("abs is not supported for dtype bool")),
  )
  assert_true(
    raises(() => @pl.Series::str("s", ["a"]).abs())
    is Some(@pl.InvalidOperation("abs is not supported for dtype str")),
  )
  assert_true(
    raises(() => @pl.Series::date("d", [1]).abs())
    is Some(@pl.InvalidOperation("abs is not supported for dtype date")),
  )
  assert_true(
    raises(() => @pl.Series::datetime("d", [1L]).abs())
    is Some(
      @pl.InvalidOperation("abs is not supported for dtype datetime[\u{3bc}s]"),
    ),
  )
  assert_true(
    raises(() => @pl.Series::null("n", 2).abs())
    is Some(
      @pl.InvalidOperation("`abs` operation not supported for dtype `null`"),
    ),
  )
}

///|
test "sqrt: always floating point, negative gives NaN, nulls stay null" {
  let a = @pl.Series::int32_nullable("a", [Some(4), Some(-1), Some(0), None])
  let r = a.sqrt()
  assert_eq(r.dtype(), @pl.DataType::Float64)
  let v = r.to_float64_array()
  assert_eq(v[0], Some(2.0))
  assert_true(v[1].unwrap().is_nan())
  assert_eq(v[2], Some(0.0))
  assert_eq(v[3], None)
  // Int64 also gives Float64
  assert_eq(@pl.Series::int64("l", [9L]).sqrt().to_float64_array(), [Some(3.0)])
  // Float32 stays Float32
  let f = @pl.Series::float32("f", [2.25, -1.0])
  assert_eq(f.sqrt().dtype(), @pl.DataType::Float32)
  assert_eq(f.sqrt().to_float32_array()[0], Some(1.5))
  assert_true(f.sqrt().to_float32_array()[1].unwrap().is_nan())
  // -0.0 and infinities
  let z = @pl.Series::float64("z", [-0.0, ew_inf, -ew_inf])
  let zv = z.sqrt().to_float64_array()
  assert_eq(
    zv[0].unwrap().reinterpret_as_int64(),
    (-0.0).reinterpret_as_int64(),
  )
  assert_eq(zv[1], Some(ew_inf))
  assert_true(zv[2].unwrap().is_nan())
  // Null gives an all-null Float64
  let n = @pl.Series::null("n", 2).sqrt()
  assert_eq(n.dtype(), @pl.DataType::Float64)
  assert_eq(n.to_float64_array(), [None, None])
  // empty
  assert_eq(@pl.Series::int32("e", []).sqrt().len(), 0)
}

///|
test "exp and log: types, special values, null" {
  let a = @pl.Series::float64_nullable("a", [
    Some(0.0),
    Some(1.0),
    Some(-ew_inf),
    Some(ew_inf),
    Some(710.0),
    None,
  ])
  let e = a.exp()
  assert_eq(e.dtype(), @pl.DataType::Float64)
  let ev = e.to_float64_array()
  assert_eq(ev[0], Some(1.0))
  assert_eq(ev[1], Some(2.718281828459045))
  assert_eq(ev[2], Some(0.0))
  assert_eq(ev[3], Some(ew_inf))
  assert_eq(ev[4], Some(ew_inf))
  assert_eq(ev[5], None)
  // integers give Float64, Float32 stays Float32
  assert_eq(@pl.Series::int32("i", [0]).exp().to_float64_array(), [Some(1.0)])
  assert_eq(
    @pl.Series::float32("f", [0.0]).exp().dtype(),
    @pl.DataType::Float32,
  )
  assert_eq(@pl.Series::float32("f", [0.0]).exp().to_float32_array(), [
    Some(1.0),
  ])
  // log: 0 is -inf, negative is NaN, 1 is 0
  let x = @pl.Series::float64_nullable("x", [
    Some(0.0),
    Some(-1.0),
    Some(1.0),
    Some(ew_inf),
    None,
  ])
  let lv = x.log().to_float64_array()
  assert_eq(lv[0], Some(-ew_inf))
  assert_true(lv[1].unwrap().is_nan())
  assert_eq(lv[2], Some(0.0))
  assert_eq(lv[3], Some(ew_inf))
  assert_eq(lv[4], None)
  assert_eq(x.log().dtype(), @pl.DataType::Float64)
  assert_eq(@pl.Series::int64("i", [1L]).log().to_float64_array(), [Some(0.0)])
  assert_eq(
    @pl.Series::float32("f", [1.0]).log().dtype(),
    @pl.DataType::Float32,
  )
}

///|
test "log with a base" {
  let a = @pl.Series::float64("a", [8.0, 1.0, 0.0])
  let r = a.log(base=2.0).to_float64_array()
  assert_eq(r, [Some(3.0), Some(0.0), Some(-ew_inf)])
  assert_eq(
    @pl.Series::float64("a", [100.0]).log(base=10.0).to_float64_array(),
    [Some(2.0)],
  )
  // base 1 divides by zero: 1.0 -> NaN, other positive values -> inf
  let b = @pl.Series::float64("b", [1.0, 2.0]).log(base=1.0).to_float64_array()
  assert_true(b[0].unwrap().is_nan())
  assert_eq(b[1], Some(ew_inf))
  // a negative base is NaN
  assert_true(
    @pl.Series::float64("c", [2.0]).log(base=-2.0).to_float64_array()[0]
    .unwrap()
    .is_nan(),
  )
  // integers
  assert_eq(@pl.Series::int32("i", [8]).log(base=2.0).to_float64_array(), [
    Some(3.0),
  ])
  // Float32 keeps its type
  let f = @pl.Series::float32("f", [8.0]).log(base=2.0)
  assert_eq(f.dtype(), @pl.DataType::Float32)
  assert_eq(f.to_float32_array(), [Some(3.0)])
}

///|
test "sqrt, exp, log: Boolean, String, Date, Datetime are refused, Null per polars" {
  let b = @pl.Series::bool("b", [true])
  let t = @pl.Series::str("s", ["4"])
  let d = @pl.Series::date("d", [1])
  let dt = @pl.Series::datetime("t", [1L])
  assert_true(
    raises(() => b.sqrt())
    is Some(@pl.InvalidOperation("sqrt is not supported for dtype bool")),
  )
  assert_true(
    raises(() => t.sqrt())
    is Some(@pl.InvalidOperation("sqrt is not supported for dtype str")),
  )
  assert_true(
    raises(() => d.sqrt())
    is Some(@pl.InvalidOperation("sqrt is not supported for dtype date")),
  )
  assert_true(
    raises(() => dt.sqrt())
    is Some(
      @pl.InvalidOperation("sqrt is not supported for dtype datetime[\u{3bc}s]"),
    ),
  )
  assert_true(
    raises(() => b.exp())
    is Some(@pl.InvalidOperation("exp is not supported for dtype bool")),
  )
  assert_true(
    raises(() => t.exp())
    is Some(@pl.InvalidOperation("exp is not supported for dtype str")),
  )
  assert_true(
    raises(() => d.log())
    is Some(@pl.InvalidOperation("log is not supported for dtype date")),
  )
  assert_true(
    raises(() => b.log(base=2.0))
    is Some(@pl.InvalidOperation("log is not supported for dtype bool")),
  )
  assert_true(
    raises(() => dt.exp())
    is Some(
      @pl.InvalidOperation("exp is not supported for dtype datetime[\u{3bc}s]"),
    ),
  )
  // Null keeps polars' behaviour
  assert_true(
    raises(() => @pl.Series::null("n", 1).exp())
    is Some(
      @pl.InvalidOperation(
        "`exp` operation not supported for dtype `null` as argument 0",
      ),
    ),
  )
  assert_true(
    raises(() => @pl.Series::null("n", 1).log(base=2.0))
    is Some(
      @pl.InvalidOperation(
        "`log` operation not supported for dtype `null` as argument 0",
      ),
    ),
  )
}

///|
test "round: ties go to the even neighbour (polars half_to_even)" {
  let a = @pl.Series::float64_nullable("a", [
    Some(0.5),
    Some(1.5),
    Some(2.5),
    Some(-0.5),
    Some(-1.5),
    Some(-2.5),
    Some(2.4),
    Some(2.6),
    None,
  ])
  let r = a.round()
  assert_eq(r.name(), "a")
  assert_eq(r.dtype(), @pl.DataType::Float64)
  assert_eq(r.to_float64_array(), [
    Some(0.0),
    Some(2.0),
    Some(2.0),
    Some(-0.0),
    Some(-2.0),
    Some(-2.0),
    Some(2.0),
    Some(3.0),
    None,
  ])
  // the sign of zero: -0.5 rounds to -0.0
  assert_eq(
    r.to_float64_array()[3].unwrap().reinterpret_as_int64(),
    (-0.0).reinterpret_as_int64(),
  )
  let d = @pl.Series::float64("d", [0.125, 0.375, 2.675, 1.005, 123456.789])
  assert_eq(d.round(decimals=2).to_float64_array(), [
    Some(0.12),
    Some(0.38),
    Some(2.68),
    Some(1.0),
    Some(123456.79),
  ])
  assert_eq(d.round(decimals=1).to_float64_array()[0], Some(0.1))
}

///|
test "round: special values, huge values, Float32, integers" {
  let a = @pl.Series::float64("a", [ew_nan, ew_inf, -ew_inf, 1.0e308, -0.0])
  let v = a.round(decimals=2).to_float64_array()
  assert_true(v[0].unwrap().is_nan())
  assert_eq(v[1], Some(ew_inf))
  assert_eq(v[2], Some(-ew_inf))
  // x * 10^2 overflows: the value is returned unchanged
  assert_eq(v[3], Some(1.0e308))
  assert_eq(v[4].unwrap().reinterpret_as_int64(), (-0.0).reinterpret_as_int64())
  // 2^52 and above have no fraction
  assert_eq(
    @pl.Series::float64("b", [4503599627370496.0, 4.5e15])
    .round()
    .to_float64_array(),
    [Some(4503599627370496.0), Some(4.5e15)],
  )
  // Float32 is rounded through Float64: 2.675f is a little below 2.675
  let f = @pl.Series::float32("f", [2.675, 0.5, 1.5, -2.5])
  let fr = f.round(decimals=2)
  assert_eq(fr.dtype(), @pl.DataType::Float32)
  assert_eq(fr.to_float32_array()[0], Some(2.67))
  assert_eq(f.round().to_float32_array(), [
    Some(3.0),
    Some(0.0),
    Some(2.0),
    Some(-2.0),
  ])
  // integers are returned as they are for every decimals >= 0
  let i = @pl.Series::int32_nullable("i", [Some(15), Some(@int.MIN_VALUE), None])
  assert_eq(i.round().to_int32_array(), [Some(15), Some(@int.MIN_VALUE), None])
  assert_eq(i.round(decimals=3).dtype(), @pl.DataType::Int32)
  let l = @pl.Series::int64("l", [ew_max64, ew_min64])
  assert_eq(l.round(decimals=2).to_int64_array(), [
    Some(ew_max64),
    Some(ew_min64),
  ])
}

///|
test "round: negative decimals, non-numeric types" {
  assert_true(
    raises(() => @pl.Series::float64("a", [1.0]).round(decimals=-1))
    is Some(@pl.InvalidOperation("decimals must be non-negative, got -1")),
  )
  assert_true(
    raises(() => @pl.Series::int32("a", [1]).round(decimals=-3))
    is Some(@pl.InvalidOperation("decimals must be non-negative, got -3")),
  )
  assert_true(
    raises(() => @pl.Series::bool("b", [true]).round())
    is Some(@pl.InvalidOperation("round is not supported for dtype bool")),
  )
  assert_true(
    raises(() => @pl.Series::str("s", ["a"]).round())
    is Some(@pl.InvalidOperation("round is not supported for dtype str")),
  )
  assert_true(
    raises(() => @pl.Series::null("n", 1).round())
    is Some(
      @pl.InvalidOperation(
        "rounding ('half_to_even') operation not supported for dtype `null` (expected: numeric)",
      ),
    ),
  )
  assert_true(
    raises(() => @pl.Series::date("d", [1]).round(decimals=1))
    is Some(@pl.InvalidOperation("round is not supported for dtype date")),
  )
}
