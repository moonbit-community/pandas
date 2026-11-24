///|
let nan : Double = 0.0 / 0.0

///|
let inf : Double = 1.0 / 0.0

///|
let min64 : Int64 = @int64.MIN_VALUE

///|
let max64 : Int64 = @int64.MAX_VALUE

///|
test "add and sub keep the type, widen and propagate null" {
  let a = @pl.Series::int32_nullable("a", [Some(1), None, Some(3)])
  let b = @pl.Series::int32("b", [10, 20, 30])
  let r = a.add(b)
  assert_eq(r.name(), "a")
  assert_eq(r.dtype(), @pl.DataType::Int32)
  assert_eq(r.to_int32_array(), [Some(11), None, Some(33)])
  assert_eq(a.sub(b).to_int32_array(), [Some(-9), None, Some(-27)])
  // Int32 with Int64 is Int64
  let c = @pl.Series::int64("c", [1L, 2L, 3L])
  assert_eq(b.add(c).dtype(), @pl.DataType::Int64)
  assert_eq(b.add(c).to_int64_array(), [Some(11L), Some(22L), Some(33L)])
  // Float32 with anything but Float32 is Float64
  let f = @pl.Series::float32("f", [0.5, 1.5, 2.5])
  assert_eq(f.add(f).dtype(), @pl.DataType::Float32)
  assert_eq(f.add(b).dtype(), @pl.DataType::Float64)
  assert_eq(c.sub(f).dtype(), @pl.DataType::Float64)
  assert_eq(f.add(f).to_float32_array(), [Some(1.0), Some(3.0), Some(5.0)])
}

///|
test "integer add sub mul neg wrap around" {
  let a = @pl.Series::int32("a", [@int.MAX_VALUE, @int.MIN_VALUE])
  let one = @pl.Series::int32("b", [1, 1])
  assert_eq(a.add(one).to_int32_array(), [
    Some(@int.MIN_VALUE),
    Some(@int.MIN_VALUE + 1),
  ])
  assert_eq(a.sub(one).to_int32_array(), [
    Some(@int.MAX_VALUE - 1),
    Some(@int.MAX_VALUE),
  ])
  assert_eq(a.mul(a).to_int32_array(), [Some(1), Some(0)])
  assert_eq(a.neg().to_int32_array(), [
    Some(-@int.MAX_VALUE),
    Some(@int.MIN_VALUE),
  ])
  let b = @pl.Series::int64("b", [max64, min64, 0L])
  assert_eq(b.add(@pl.Series::int64("c", [1L, -1L, 0L])).to_int64_array(), [
    Some(min64),
    Some(max64),
    Some(0L),
  ])
  assert_eq(b.neg().to_int64_array(), [Some(-max64), Some(min64), Some(0L)])
  assert_eq(b.mul(b).to_int64_array(), [Some(1L), Some(0L), Some(0L)])
}

///|
test "true division is Float64 and follows IEEE for zero" {
  let a = @pl.Series::int32_nullable("a", [
    Some(1),
    Some(0),
    Some(-1),
    Some(6),
    None,
  ])
  let b = @pl.Series::int32("b", [0, 0, 0, 4, 1])
  let r = a.div(b)
  assert_eq(r.dtype(), @pl.DataType::Float64)
  let xs = r.to_float64_array()
  assert_eq(xs[0], Some(inf))
  assert_true(xs[1].unwrap().is_nan())
  assert_eq(xs[2], Some(-inf))
  assert_eq(xs[3], Some(1.5))
  assert_eq(xs[4], None)
  // Float32 / Float32 stays Float32
  let f = @pl.Series::float32("f", [1.0, 3.0])
  let g = @pl.Series::float32("g", [4.0, 2.0])
  assert_eq(f.div(g).dtype(), @pl.DataType::Float32)
  assert_eq(f.div(g).to_float32_array(), [Some(0.25), Some(1.5)])
  assert_eq(
    f.div(@pl.Series::int32("i", [2, 2])).dtype(),
    @pl.DataType::Float64,
  )
}

///|
test "floor_div and rem round towards negative infinity" {
  let a = @pl.Series::int64("a", [-7L, 7L, -7L, 7L])
  let b = @pl.Series::int64("b", [2L, -2L, -2L, 2L])
  assert_eq(a.floor_div(b).to_int64_array(), [
    Some(-4L),
    Some(-4L),
    Some(3L),
    Some(3L),
  ])
  assert_eq(a.rem(b).to_int64_array(), [
    Some(1L),
    Some(-1L),
    Some(-1L),
    Some(1L),
  ])
  let x = @pl.Series::float64("x", [5.5, -5.5, 5.5, -5.5])
  let y = @pl.Series::float64("y", [2.0, 2.0, -2.0, -2.0])
  assert_eq(x.floor_div(y).to_float64_array(), [
    Some(2.0),
    Some(-3.0),
    Some(-3.0),
    Some(2.0),
  ])
  assert_eq(x.rem(y).to_float64_array(), [
    Some(1.5),
    Some(0.5),
    Some(-0.5),
    Some(-1.5),
  ])
}

///|
test "integer floor_div and rem by zero are null and never trap" {
  let a = @pl.Series::int64_nullable("a", [
    Some(5L),
    Some(min64),
    None,
    Some(0L),
  ])
  let z = @pl.Series::int64("z", [0L, 0L, 0L, 0L])
  assert_eq(a.floor_div(z).to_int64_array(), [None, None, None, None])
  assert_eq(a.rem(z).to_int64_array(), [None, None, None, None])
  let a32 = @pl.Series::int32("a", [5, @int.MIN_VALUE])
  let z32 = @pl.Series::int32("z", [0, 0])
  assert_eq(a32.floor_div(z32).to_int32_array(), [None, None])
  assert_eq(a32.rem(z32).to_int32_array(), [None, None])
  // a null divisor is null, a zero divisor under a null dividend too
  let n = @pl.Series::int32_nullable("n", [None, Some(0)])
  assert_eq(a32.floor_div(n).to_int32_array(), [None, None])
}

///|
test "int64 min div minus one wraps instead of trapping" {
  let a = @pl.Series::int64("a", [min64, min64])
  let b = @pl.Series::int64("b", [-1L, 1L])
  assert_eq(a.floor_div(b).to_int64_array(), [Some(min64), Some(min64)])
  assert_eq(a.rem(b).to_int64_array(), [Some(0L), Some(0L)])
  let c = @pl.Series::int32("c", [@int.MIN_VALUE])
  let d = @pl.Series::int32("d", [-1])
  assert_eq(c.floor_div(d).to_int32_array(), [Some(@int.MIN_VALUE)])
  assert_eq(c.rem(d).to_int32_array(), [Some(0)])
}

///|
test "float arithmetic keeps NaN, inf and the sign of zero" {
  let a = @pl.Series::float64("a", [1.0, 0.0, -0.0, nan, inf])
  let b = @pl.Series::float64("b", [0.0, 0.0, 0.0, 1.0, inf])
  let q = a.floor_div(b).to_float64_array()
  assert_eq(q[0], Some(inf))
  assert_true(q[1].unwrap().is_nan())
  assert_true(q[3].unwrap().is_nan())
  let m = a.rem(b).to_float64_array()
  assert_true(m[0].unwrap().is_nan())
  let n = a.neg().to_float64_array()
  assert_eq(n[1].unwrap().reinterpret_as_int64(), (-0.0).reinterpret_as_int64())
  assert_eq(n[2].unwrap().reinterpret_as_int64(), 0.0.reinterpret_as_int64())
  assert_eq(n[4], Some(-inf))
  // f32 overflow is inf
  let big = @pl.Series::float32("g", [3.0e38])
  assert_eq(big.mul(@pl.Series::float32("h", [10.0])).to_float32_array(), [
    Some(Float::from_double(inf)),
  ])
}

///|
test "length 1 operands broadcast and the result is named after the left side" {
  let a = @pl.Series::int32("a", [1, 2, 3])
  let one = @pl.Series::int32("one", [10])
  let r = a.add(one)
  assert_eq(r.name(), "a")
  assert_eq(r.to_int32_array(), [Some(11), Some(12), Some(13)])
  let l = one.sub(a)
  assert_eq(l.name(), "one")
  assert_eq(l.to_int32_array(), [Some(9), Some(8), Some(7)])
  // a null scalar makes everything null
  let n = @pl.Series::int32_nullable("n", [None])
  assert_eq(a.mul(n).to_int32_array(), [None, None, None])
  // empty operands
  let e = @pl.Series::int32("e", [])
  assert_eq(e.add(one).len(), 0)
  assert_eq(one.add(e).len(), 0)
  assert_eq(e.add(e).len(), 0)
}

///|
test "Null columns" {
  let n = @pl.Series::null("n", 3)
  let i = @pl.Series::int64("i", [1L, 2L, 3L])
  let r = n.add(i)
  assert_eq(r.dtype(), @pl.DataType::Int64)
  assert_eq(r.to_int64_array(), [None, None, None])
  assert_eq(i.mul(n).dtype(), @pl.DataType::Int64)
  assert_eq(n.add(n).dtype(), @pl.DataType::Null)
  assert_eq(n.add(n).len(), 3)
  assert_eq(n.div(n).dtype(), @pl.DataType::Float64)
  // `Null / Float32` is Float64 but `Float32 / Null` is Float32
  let f32 = @pl.Series::float32("f", [1.0, 2.0, 3.0])
  assert_eq(n.div(f32).dtype(), @pl.DataType::Float64)
  assert_eq(f32.div(n).dtype(), @pl.DataType::Float32)
  assert_eq(f32.div(n).to_float32_array(), [None, None, None])
  assert_eq(n.floor_div(i).dtype(), @pl.DataType::Int64)
  assert_eq(n.rem(i).dtype(), @pl.DataType::Int64)
  assert_eq(n.sub(@pl.Series::null("m", 1)).len(), 3)
  assert_eq(
    err_text(() => n.floor_div(n)),
    "InvalidOperation: floor_div operation not supported for dtype `null`",
  )
}

///|
test "arithmetic is only for numbers" {
  let b = @pl.Series::bool("b", [true])
  let i = @pl.Series::int32("i", [1])
  let s = @pl.Series::str("s", ["x"])
  let d = @pl.Series::date("d", [1])
  let t = @pl.Series::datetime("t", [1L])
  assert_true(raises(() => b.add(i)) is Some(@pl.InvalidOperation(_)))
  assert_true(raises(() => b.sub(b)) is Some(@pl.InvalidOperation(_)))
  assert_true(raises(() => s.add(s)) is Some(@pl.InvalidOperation(_)))
  assert_true(raises(() => i.mul(s)) is Some(@pl.InvalidOperation(_)))
  assert_true(raises(() => d.sub(d)) is Some(@pl.InvalidOperation(_)))
  assert_true(raises(() => t.sub(d)) is Some(@pl.InvalidOperation(_)))
  assert_true(raises(() => d.div(i)) is Some(@pl.InvalidOperation(_)))
  assert_true(raises(() => b.floor_div(b)) is Some(@pl.InvalidOperation(_)))
  assert_true(raises(() => t.rem(i)) is Some(@pl.InvalidOperation(_)))
  assert_eq(
    err_text(() => b.add(i)),
    "InvalidOperation: add operation not supported for dtypes `bool` and `i32`",
  )
  assert_eq(
    err_text(() => i.rem(s)),
    "InvalidOperation: rem operation not supported for dtypes `i32` and `str`",
  )
}

///|
test "neg" {
  let a = @pl.Series::int32_nullable("a", [Some(1), None, Some(-2)])
  assert_eq(a.neg().to_int32_array(), [Some(-1), None, Some(2)])
  assert_eq(a.neg().name(), "a")
  let f = @pl.Series::float32("f", [1.5])
  assert_eq(f.neg().to_float32_array(), [Some(-1.5)])
  assert_eq(@pl.Series::int32("e", []).neg().len(), 0)
  assert_eq(
    err_text(() => @pl.Series::bool("b", [true]).neg()),
    "InvalidOperation: `neg` operation not supported for dtype `bool`",
  )
  assert_eq(
    err_text(() => @pl.Series::str("s", ["x"]).neg()),
    "InvalidOperation: `neg` operation not supported for dtype `str`",
  )
  assert_eq(
    err_text(() => @pl.Series::null("n", 2).neg()),
    "InvalidOperation: `neg` operation not supported for dtype `null`",
  )
  assert_true(
    raises(() => @pl.Series::date("d", [1]).neg())
    is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "shape mismatch" {
  let a = @pl.Series::int32("a", [1, 2])
  let b = @pl.Series::int32("b", [1, 2, 3])
  assert_true(raises(() => a.add(b)) is Some(@pl.ShapeMismatch(_)))
  assert_true(raises(() => a.sub(b)) is Some(@pl.ShapeMismatch(_)))
  assert_true(raises(() => a.mul(b)) is Some(@pl.ShapeMismatch(_)))
  assert_true(raises(() => a.div(b)) is Some(@pl.ShapeMismatch(_)))
  assert_true(raises(() => a.floor_div(b)) is Some(@pl.ShapeMismatch(_)))
  assert_true(raises(() => a.rem(b)) is Some(@pl.ShapeMismatch(_)))
  assert_eq(
    err_text(() => a.add(b)),
    "ShapeMismatch: cannot evaluate two Series of different lengths (2 and 3)",
  )
  assert_true(
    raises(() => @pl.Series::int32("e", []).add(a))
    is Some(@pl.ShapeMismatch(_)),
  )
}

///|
/// polars divides by a divisor of length 1 by multiplying with its reciprocal
/// (`s / pl.Series([3e9])` is `s * (1 / 3e9)`); checked against polars 2.1.0
/// (`2147483647 / 3e9` is `0.7158278823333333` that way and
/// `0.7158278823333334` as a plain division).
test "division by a divisor of length 1 multiplies with its reciprocal" {
  let a = @pl.Series::float64("a", [2147483647.0, 1.0, -5.0])
  let three_e9 = @pl.Series::float64("b", [3.0e9])
  let q = a.div(three_e9).to_float64_array()
  assert_eq(q[0], Some(2147483647.0 * (1.0 / 3.0e9)))
  assert_true(q[0] != Some(2147483647.0 / 3.0e9))
  // integers are divided as floats too
  let ints = @pl.Series::int32("i", [2147483647, 1, 5, -7])
  let r = ints.div(three_e9).to_float64_array()
  assert_eq(r[0], Some(2147483647.0 * (1.0 / 3.0e9)))
  assert_eq(ints.div(three_e9).dtype(), @pl.DataType::Float64)
  // not applicable: a divisor as long as the dividend, a dividend of length 1
  let same = @pl.Series::float64("c", [3.0e9, 3.0e9, 3.0e9])
  assert_eq(a.div(same).to_float64_array()[0], Some(2147483647.0 / 3.0e9))
  assert_eq(three_e9.div(three_e9).to_float64_array(), [Some(1.0)])
  assert_eq(
    @pl.Series::float64("x", [1.0]).div(a).to_float64_array()[1],
    Some(1.0),
  )
  // integer `//` and `%` are exact integer operations
  let j = @pl.Series::int64("j", [7L, 8L])
  assert_eq(j.floor_div(@pl.Series::int64("k", [2L])).to_int64_array(), [
    Some(3L),
    Some(4L),
  ])
  assert_eq(j.rem(@pl.Series::int64("k", [3L])).to_int64_array(), [
    Some(1L),
    Some(2L),
  ])
  // `//` and `%` of floats use the product as well: `3e38 // 1.5` in Float32
  // is 2.0000001e38 (polars), not 2e38
  let f = @pl.Series::float32("f", [3.0e38, 5.0, -5.0])
  let one_and_half = @pl.Series::float32("g", [1.5])
  let fd = f.floor_div(one_and_half)
  assert_eq(fd.dtype(), @pl.DataType::Float32)
  assert_true(fd.to_float32_array()[0] != Some(Float::from_double(2.0e38)))
  assert_eq(fd.to_float32_array()[1], Some(3.0))
  assert_eq(fd.to_float32_array()[2], Some(-4.0))
  let fr = f.rem(one_and_half)
  assert_eq(fr.to_float32_array()[1], Some(0.5))
  assert_eq(fr.to_float32_array()[2], Some(1.0))
  // divisor 0: infinities and NaN as with `/`
  let zero = @pl.Series::float64("z", [0.0])
  let inf = @pl.Series::float64("a", [1.0, -1.0, 0.0])
    .div(zero)
    .to_float64_array()
  assert_eq(inf[0], Some(1.0 / 0.0))
  assert_eq(inf[1], Some(-1.0 / 0.0))
  assert_true(inf[2].unwrap().is_nan())
  // null divisor and Null series stay null
  let null_div = @pl.Series::float64_nullable("n", [None])
  assert_eq(a.div(null_div).to_float64_array(), [None, None, None])
  assert_eq(
    @pl.Series::null("n", 2).div(three_e9).dtype(),
    @pl.DataType::Float64,
  )
  assert_eq(a.div(@pl.Series::null("n", 1)).to_float64_array(), [
    None,
    None,
    None,
  ])
  // an empty dividend
  assert_eq(@pl.Series::float64("e", []).div(three_e9).len(), 0)
}

///|
/// `Float64 %` by a divisor of length 1 is `a - b * floor(a * (1 / b))`
/// (polars 2.1.0: `[0.3, 0.6] % [0.1]` is `[-5.55e-17, -1.11e-16]`; a plain
/// `a - b * floor(a / b)` gives `0.0999...` for the first value).
test "Float64 remainder by a divisor of length 1 uses the reciprocal" {
  let a = @pl.Series::float64("a", [0.3, 0.6])
  let b = @pl.Series::float64("b", [0.1])
  let r = a.rem(b).to_float64_array()
  assert_eq(r[0], Some(0.3 - 0.1 * (0.3 * (1.0 / 0.1)).floor()))
  assert_eq(r[1], Some(0.6 - 0.1 * (0.6 * (1.0 / 0.1)).floor()))
  assert_true(r[0].unwrap() < 0.0)
  // the same divisor as long as the dividend: a plain division
  let same = @pl.Series::float64("c", [0.1, 0.1])
  assert_eq(
    a.rem(same).to_float64_array()[0],
    Some(0.3 - 0.1 * (0.3 / 0.1).floor()),
  )
  // and floor division
  assert_eq(a.floor_div(b).to_float64_array(), [Some(3.0), Some(6.0)])
}
