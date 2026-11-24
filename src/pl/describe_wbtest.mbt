///|
test "desc_g follows Python's %g" {
  assert_eq(desc_g(0.0), "0")
  assert_eq(desc_g(25.0), "25")
  assert_eq(desc_g(100.0), "100")
  assert_eq(desc_g(12.5), "12.5")
  assert_eq(desc_g(33.3), "33.3")
  assert_eq(desc_g(100.0 / 3.0), "33.3333")
  assert_eq(desc_g(99.99999), "100")
  assert_eq(desc_g(0.0001), "0.0001")
  assert_eq(desc_g(0.00001), "1e-05")
  assert_eq(desc_g(0.000012345678), "1.23457e-05")
  assert_eq(desc_g(1.5e-10), "1.5e-10")
  assert_eq(desc_g(0.5), "0.5")
  assert_eq(desc_g(7.000000000000001), "7")
  // exact ties are rounded half to even on the exact binary value
  assert_eq(desc_g(12.34375), "12.3438")
  assert_eq(desc_g(12.34365), "12.3437")
  // 12.34565 is just below the tie as a double
  assert_eq(desc_g(12.34565), "12.3456")
  assert_eq(desc_g(-0.0), "-0")
}

///|
test "desc_float_repr follows Python's repr" {
  assert_eq(desc_float_repr(0.0), "0.0")
  assert_eq(desc_float_repr(-0.0), "-0.0")
  assert_eq(desc_float_repr(1.0), "1.0")
  assert_eq(desc_float_repr(0.5), "0.5")
  assert_eq(desc_float_repr(0.1), "0.1")
  assert_eq(desc_float_repr(0.25), "0.25")
  assert_eq(desc_float_repr(0.0001), "0.0001")
  assert_eq(desc_float_repr(0.00001), "1e-05")
  assert_eq(desc_float_repr(1.0e-7), "1e-07")
  assert_eq(desc_float_repr(1.5e-10), "1.5e-10")
  assert_eq(desc_float_repr(0.12345678), "0.12345678")
  assert_eq(desc_float_repr(1.0 / 3.0), "0.3333333333333333")
}

///|
test "desc_datetime prints the fraction only when it is not zero" {
  assert_eq(desc_datetime(0L), "1970-01-01 00:00:00")
  assert_eq(desc_datetime(5L), "1970-01-01 00:00:00.000005")
  assert_eq(desc_datetime(-1L), "1969-12-31 23:59:59.999999")
  assert_eq(desc_datetime(86399999999L), "1970-01-01 23:59:59.999999")
  // the extremes of Int64 do not abort
  assert_eq(desc_datetime(@int64.MAX_VALUE).length() > 10, true)
  assert_eq(desc_datetime(@int64.MIN_VALUE).length() > 10, true)
}

///|
test "desc_sorted is a stable ascending sort" {
  assert_eq(desc_sorted([0.9, 0.1, 0.5, 0.0]), [0.0, 0.1, 0.5, 0.9])
  assert_eq(desc_sorted([]), [])
  let zeros = desc_sorted([0.0, -0.0])
  assert_eq(zeros[0].reinterpret_as_int64() == 0L, true)
  let zeros2 = desc_sorted([-0.0, 0.0])
  assert_eq(zeros2[0].reinterpret_as_int64() < 0L, true)
}
