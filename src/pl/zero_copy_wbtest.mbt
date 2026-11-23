// Zero-copy proofs at the `@pl` level. The storage of an `@arrow` array is
// private, so the tests wrap a `FixedArray` they keep a reference to and then
// mutate it *after* slicing: a view that really shares storage observes the
// change, a copy would not. (`Boolean` columns cannot be checked this way:
// their `Bitmap` storage has no mutable entry point; `Column::slice` hands
// them straight to `BoolArray::slice`, whose sharing is proven in
// `internal/arrow/zero_copy_wbtest.mbt`.)

///|
test "Series::slice, head and tail share storage with the original" {
  let raw : FixedArray[Int64] = [10L, 20L, 30L, 40L, 50L]
  let s = Series::make("a", Column::Int64(@arrow.PrimArray::new(raw, None)))
  let sl = s.slice(1, length=3)
  let hd = s.head(n=2)
  let tl = s.tail(n=2)
  let neg = s.slice(-3)
  let nested = sl.slice(1).head(n=1)
  assert_eq(sl.to_int64_array(), [Some(20L), Some(30L), Some(40L)])
  assert_eq(hd.to_int64_array(), [Some(10L), Some(20L)])
  assert_eq(tl.to_int64_array(), [Some(40L), Some(50L)])
  assert_eq(nested.to_int64_array(), [Some(30L)])
  // write through the shared FixedArray: every view sees it
  raw[1] = 21L
  raw[2] = 31L
  raw[3] = 41L
  raw[4] = 51L
  assert_eq(sl.to_int64_array(), [Some(21L), Some(31L), Some(41L)])
  assert_eq(hd.to_int64_array(), [Some(10L), Some(21L)])
  assert_eq(tl.to_int64_array(), [Some(41L), Some(51L)])
  assert_eq(neg.to_int64_array(), [Some(31L), Some(41L), Some(51L)])
  assert_eq(nested.to_int64_array(), [Some(31L)])
  // gather is the copying operation, for contrast: it does not see writes
  let copy = s.gather([0, 1])
  raw[0] = 11L
  assert_eq(s.head(n=1).to_int64_array(), [Some(11L)])
  assert_eq(copy.to_int64_array(), [Some(10L), Some(21L)])
}

///|
test "slices of every primitive column type share storage" {
  // Int32
  let i32 : FixedArray[Int32] = [1, 2, 3]
  let a = Series::make("i", Column::Int32(@arrow.PrimArray::new(i32, None)))
  let a_tail = a.tail(n=2)
  i32[2] = 9
  assert_eq(a_tail.to_int32_array(), [Some(2), Some(9)])
  // Float32
  let f32 : FixedArray[Float] = [1.0, 2.0, 3.0]
  let b = Series::make("f", Column::Float32(@arrow.PrimArray::new(f32, None)))
  let b_head = b.head(n=2)
  f32[1] = 7.5
  assert_eq(b_head.to_float32_array(), [Some(1.0), Some(7.5)])
  // Float64
  let f64 : FixedArray[Double] = [1.0, 2.0, 3.0]
  let c = Series::make("d", Column::Float64(@arrow.PrimArray::new(f64, None)))
  let c_mid = c.slice(1, length=1)
  f64[1] = -2.0
  assert_eq(c_mid.to_float64_array(), [Some(-2.0)])
  // Date
  let days : FixedArray[Int32] = [0, 1, 2]
  let d = Series::make("dt", Column::Date(@arrow.PrimArray::new(days, None)))
  let d_tail = d.tail(n=1)
  days[2] = -5
  assert_eq(d_tail.to_list(), [AnyValue::Date(-5)])
  // Datetime
  let us : FixedArray[Int64] = [0L, 1L, 2L]
  let e = Series::make("ts", Column::Datetime(@arrow.PrimArray::new(us, None)))
  let e_head = e.head(n=2)
  us[0] = -1L
  assert_eq(e_head.to_list(), [AnyValue::Datetime(-1L), AnyValue::Datetime(1L)])
  // String
  let strs : FixedArray[String] = ["a", "b", "c"]
  let f = Series::make("s", Column::String(@arrow.StrArray::new(strs, None)))
  let f_mid = f.slice(1, length=2)
  strs[2] = "z"
  assert_eq(f_mid.to_str_array(), [Some("b"), Some("z")])
}

///|
test "slices keep sharing storage when the column has nulls" {
  let raw : FixedArray[Int64] = [1L, 2L, 3L, 4L]
  let validity = @arrow.Bitmap::from_array([true, false, true, false])
  let s = Series::make(
    "a",
    Column::Int64(@arrow.PrimArray::new(raw, Some(validity))),
  )
  let t = s.tail(n=3)
  assert_eq(t.to_int64_array(), [None, Some(3L), None])
  assert_eq(t.null_count(), 2)
  raw[2] = 33L
  assert_eq(t.to_int64_array(), [None, Some(33L), None])
}

///|
test "DataFrame::slice, head and tail share each column's storage" {
  let ra : FixedArray[Int64] = [1L, 2L, 3L, 4L]
  let rb : FixedArray[String] = ["w", "x", "y", "z"]
  let rc : FixedArray[Double] = [0.5, 1.5, 2.5, 3.5]
  let df = DataFrame::new([
    Series::make("a", Column::Int64(@arrow.PrimArray::new(ra, None))),
    Series::make("b", Column::String(@arrow.StrArray::new(rb, None))),
    Series::make("c", Column::Float64(@arrow.PrimArray::new(rc, None))),
  ])
  let sl = df.slice(1, length=2)
  let hd = df.head(n=2)
  let tl = df.tail(n=2)
  ra[1] = 20L
  ra[2] = 30L
  rb[1] = "X"
  rb[2] = "Y"
  rc[1] = 15.0
  rc[2] = 25.0
  assert_eq(sl.row(0), [AnyValue::Int64(20L), String("X"), Float64(15.0)])
  assert_eq(sl.row(1), [AnyValue::Int64(30L), String("Y"), Float64(25.0)])
  assert_eq(hd.row(1), [AnyValue::Int64(20L), String("X"), Float64(15.0)])
  assert_eq(tl.row(0), [AnyValue::Int64(30L), String("Y"), Float64(25.0)])
  // the frame itself saw the writes too
  assert_eq(df.get(1, "b"), AnyValue::String("X"))
  // a Null column has no storage; slicing it only changes the length
  let n = DataFrame::new([Series::null("n", 4)])
  assert_eq(n.slice(1, length=2).height(), 2)
  assert_eq(n.head(n=3).column("n").null_count(), 3)
  assert_eq(n.tail(n=1).column("n").len(), 1)
}
