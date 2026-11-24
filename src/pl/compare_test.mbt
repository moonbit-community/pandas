///|
test "comparisons are Boolean, null where an operand is null" {
  let a = @pl.Series::int32_nullable("a", [Some(1), Some(2), None, Some(4)])
  let b = @pl.Series::int32("b", [1, 3, 3, 3])
  let r = a.eq(b)
  assert_eq(r.dtype(), @pl.DataType::Boolean)
  assert_eq(r.name(), "a")
  assert_eq(r.to_bool_array(), [Some(true), Some(false), None, Some(false)])
  assert_eq(a.neq(b).to_bool_array(), [
    Some(false),
    Some(true),
    None,
    Some(true),
  ])
  assert_eq(a.lt(b).to_bool_array(), [
    Some(false),
    Some(true),
    None,
    Some(false),
  ])
  assert_eq(a.le(b).to_bool_array(), [Some(true), Some(true), None, Some(false)])
  assert_eq(a.gt(b).to_bool_array(), [
    Some(false),
    Some(false),
    None,
    Some(true),
  ])
  assert_eq(a.ge(b).to_bool_array(), [Some(true), Some(false), None, Some(true)])
}

///|
test "mixed numeric types compare after widening" {
  // 2^53 + 1 is not representable as a double: Int64 vs Float64 widens to f64
  let i = @pl.Series::int64("i", [9007199254740993L])
  let f = @pl.Series::float64("f", [9007199254740992.0])
  assert_eq(i.eq(f).to_bool_array(), [Some(true)])
  // Int32 vs Float32 is Float64 (16777217 is exact there)
  let i32 = @pl.Series::int32("i", [16777217])
  let f32 = @pl.Series::float32("f", [16777216.0])
  assert_eq(i32.eq(f32).to_bool_array(), [Some(false)])
  assert_eq(
    @pl.Series::int32("i", [1, 2])
    .lt(@pl.Series::int64("j", [2L, 2L]))
    .to_bool_array(),
    [Some(true), Some(false)],
  )
}

///|
test "NaN equals NaN and is greater than every number" {
  let a = @pl.Series::float64("a", [1.0, nan, nan, -inf, inf, -0.0, 0.0])
  let b = @pl.Series::float64("b", [nan, nan, 1.0, nan, nan, 0.0, -0.0])
  assert_eq(a.eq(b).to_bool_array(), [
    Some(false),
    Some(true),
    Some(false),
    Some(false),
    Some(false),
    Some(true),
    Some(true),
  ])
  assert_eq(a.lt(b).to_bool_array(), [
    Some(true),
    Some(false),
    Some(false),
    Some(true),
    Some(true),
    Some(false),
    Some(false),
  ])
  assert_eq(a.gt(b).to_bool_array(), [
    Some(false),
    Some(false),
    Some(true),
    Some(false),
    Some(false),
    Some(false),
    Some(false),
  ])
  assert_eq(a.ge(b).to_bool_array(), [
    Some(false),
    Some(true),
    Some(true),
    Some(false),
    Some(false),
    Some(true),
    Some(true),
  ])
  assert_eq(a.le(b).to_bool_array(), [
    Some(true),
    Some(true),
    Some(false),
    Some(true),
    Some(true),
    Some(true),
    Some(true),
  ])
  assert_eq(a.neq(b).to_bool_array(), [
    Some(true),
    Some(false),
    Some(true),
    Some(true),
    Some(true),
    Some(false),
    Some(false),
  ])
  // Float32 behaves the same
  let f = @pl.Series::float32("f", [Float::from_double(nan), 1.0])
  assert_eq(f.eq(f).to_bool_array(), [Some(true), Some(true)])
  assert_eq(f.gt(@pl.Series::float32("g", [1.0, 1.0])).to_bool_array(), [
    Some(true),
    Some(false),
  ])
}

///|
test "strings compare by code point, not by UTF-16 code unit" {
  // U+FF61 is below U+1F600 by code point; as UTF-16 it is above the
  // surrogate pair 0xD83D 0xDE00
  let a = @pl.Series::str("a", [
    "\u{FF61}", "\u{1F600}", "a", "", "Z", "\u{E000}", "\u{10000}",
  ])
  let b = @pl.Series::str("b", [
    "\u{1F600}", "\u{FF61}", "A", "a", "z", "\u{10000}", "\u{FFFF}",
  ])
  assert_eq(a.lt(b).to_bool_array(), [
    Some(true),
    Some(false),
    Some(false),
    Some(true),
    Some(true),
    Some(true),
    Some(false),
  ])
  assert_eq(a.gt(b).to_bool_array(), [
    Some(false),
    Some(true),
    Some(true),
    Some(false),
    Some(false),
    Some(false),
    Some(true),
  ])
  assert_eq(a.eq(a).to_bool_array(), [
    Some(true),
    Some(true),
    Some(true),
    Some(true),
    Some(true),
    Some(true),
    Some(true),
  ])
  assert_eq(a.le(a).to_bool_array()[2], Some(true))
  assert_eq(a.ge(b).to_bool_array()[3], Some(false))
  // a prefix is smaller
  assert_eq(
    @pl.Series::str("a", ["ab"])
    .lt(@pl.Series::str("b", ["abc"]))
    .to_bool_array(),
    [Some(true)],
  )
}

///|
test "booleans, dates and datetimes compare" {
  let t = @pl.Series::bool_nullable("a", [Some(true), Some(false), None])
  let u = @pl.Series::bool("b", [false, false, false])
  assert_eq(t.gt(u).to_bool_array(), [Some(true), Some(false), None])
  assert_eq(t.eq(u).to_bool_array(), [Some(false), Some(true), None])
  let d = @pl.Series::date("d", [1, -1])
  let e = @pl.Series::date("e", [1, 0])
  assert_eq(d.lt(e).to_bool_array(), [Some(false), Some(true)])
  // Date vs Datetime compares at microsecond resolution
  let dt = @pl.Series::datetime("t", [86400000000L, 86400000001L])
  assert_eq(@pl.Series::date("d", [1, 1]).eq(dt).to_bool_array(), [
    Some(true),
    Some(false),
  ])
  assert_eq(dt.gt(@pl.Series::date("d", [1, 1])).to_bool_array(), [
    Some(false),
    Some(true),
  ])
  // numbers read dates as days and datetimes as microseconds
  assert_eq(d.eq(@pl.Series::int32("i", [1, 5])).to_bool_array(), [
    Some(true),
    Some(false),
  ])
  assert_eq(dt.eq(@pl.Series::int64("i", [86400000000L, 0L])).to_bool_array(), [
    Some(true),
    Some(false),
  ])
}

///|
test "strings compare with booleans, dates and datetimes as text" {
  let s = @pl.Series::str("s", ["true", "1970-01-02", "x"])
  assert_eq(s.eq(@pl.Series::bool("b", [true, true, true])).to_bool_array(), [
    Some(true),
    Some(false),
    Some(false),
  ])
  assert_eq(s.eq(@pl.Series::date("d", [1, 1, 1])).to_bool_array(), [
    Some(false),
    Some(true),
    Some(false),
  ])
  assert_eq(
    @pl.Series::str("s", ["1970-01-01 00:00:00.000001"])
    .eq(@pl.Series::datetime("t", [1L]))
    .to_bool_array(),
    [Some(true)],
  )
}

///|
test "Null columns compare to null of Boolean" {
  let n = @pl.Series::null("n", 2)
  let i = @pl.Series::int32("i", [1, 2])
  assert_eq(n.eq(i).dtype(), @pl.DataType::Boolean)
  assert_eq(n.eq(i).to_bool_array(), [None, None])
  assert_eq(i.lt(n).to_bool_array(), [None, None])
  assert_eq(n.eq(n).to_bool_array(), [None, None])
  assert_eq(n.eq(@pl.Series::str("s", ["a", "b"])).to_bool_array(), [None, None])
  assert_eq(n.neq(@pl.Series::date("d", [1, 2])).to_bool_array(), [None, None])
}

///|
test "length 1 operands broadcast" {
  let a = @pl.Series::str("a", ["a", "b", "c"])
  let b = @pl.Series::str("b", ["b"])
  assert_eq(a.eq(b).to_bool_array(), [Some(false), Some(true), Some(false)])
  assert_eq(b.eq(a).to_bool_array(), [Some(false), Some(true), Some(false)])
  assert_eq(b.eq(a).name(), "b")
  assert_eq(@pl.Series::str("e", []).eq(b).len(), 0)
}

///|
test "comparison errors" {
  let b = @pl.Series::bool("a", [true])
  let d = @pl.Series::date("b", [1])
  let t = @pl.Series::datetime("c", [1L])
  let s = @pl.Series::str("s", ["x"])
  assert_eq(
    err_text(() => b.eq(d)),
    "SchemaMismatch: could not evaluate comparison between series 'a' of dtype: Boolean and series 'b' of dtype: Date",
  )
  assert_eq(
    err_text(() => b.gt(t)),
    "SchemaMismatch: could not evaluate '>' comparison between series 'a' of dtype: Boolean and series 'c' of dtype: Datetime('\u{3bc}s')",
  )
  assert_eq(
    err_text(() => t.le(b)),
    "SchemaMismatch: could not evaluate '<=' comparison between series 'c' of dtype: Datetime('\u{3bc}s') and series 'a' of dtype: Boolean",
  )
  assert_eq(
    err_text(() => d.ge(b)),
    "SchemaMismatch: could not evaluate '>=' comparison between series 'b' of dtype: Date and series 'a' of dtype: Boolean",
  )
  assert_eq(
    err_text(() => d.lt(b)),
    "SchemaMismatch: could not evaluate '<' comparison between series 'b' of dtype: Date and series 'a' of dtype: Boolean",
  )
  assert_eq(
    err_text(() => s.eq(@pl.Series::int32("i", [1]))),
    "ComputeError: cannot compare string with numeric type (i32)",
  )
  assert_eq(
    err_text(() => @pl.Series::float64("f", [1.0]).neq(s)),
    "ComputeError: cannot compare string with numeric type (f64)",
  )
  assert_eq(
    err_text(() => {
      @pl.Series::int32("a", [1, 2]).eq(@pl.Series::int32("b", [1, 2, 3]))
    }),
    "ShapeMismatch: cannot evaluate two Series of different lengths (2 and 3)",
  )
  assert_true(
    raises(() => {
      @pl.Series::str("a", ["x", "y"]).lt(@pl.Series::str("b", ["x", "y", "z"]))
    })
    is Some(@pl.ShapeMismatch(_)),
  )
}
