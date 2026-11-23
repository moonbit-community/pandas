///|
test "float_digits splits the shortest rendering of a float" {
  assert_eq(float_digits("123.45"), ("12345", 2))
  assert_eq(float_digits("-123.45"), ("12345", 2))
  assert_eq(float_digits("0.00001"), ("1", -5))
  assert_eq(float_digits("1.5e-7"), ("15", -7))
  assert_eq(float_digits("1e+21"), ("1", 21))
  assert_eq(float_digits("1.2345e+30"), ("12345", 30))
  assert_eq(float_digits("100"), ("1", 2))
  assert_eq(float_digits("5e-324"), ("5", -324))
  assert_eq(float_digits("0.1"), ("1", -1))
}

///|
test "compare_decimal_double compares exact decimal expansions" {
  // 0.1 as a double is 0.1000000000000000055511151231257827...
  assert_eq(compare_decimal_double("1", 0, 0.1), -1)
  assert_eq(
    compare_decimal_double(
      "1000000000000000055511151231257827021181583404541015625", 0, 0.1,
    ),
    0,
  )
  assert_eq(
    compare_decimal_double(
      "1000000000000000055511151231257827021181583404541015626", 0, 0.1,
    ),
    1,
  )
  // a larger decimal point is a larger number
  assert_eq(compare_decimal_double("1", 1, 0.5), 1)
  assert_eq(compare_decimal_double("9", -1, 0.5), -1)
  assert_eq(compare_decimal_double("5", 0, 0.5), 0)
  assert_eq(compare_decimal_double("51", 0, 0.5), 1)
  assert_eq(compare_decimal_double("49", 0, 0.5), -1)
}

///|
test "round_decimal_to_f32_bits only consults the digits at a midpoint" {
  // 1 + 2^-24 is the midpoint of 1.0 and 1 + 2^-23 (bits 0x3F800000 / 1)
  let mid = 1.0 + 5.9604644775390625e-8
  assert_eq(
    round_decimal_to_f32_bits("100000005960464477539062500001", 1, mid),
    0x3F800001U,
  )
  assert_eq(
    round_decimal_to_f32_bits("1000000059604644775390625", 1, mid),
    0x3F800000U,
  )
  assert_eq(
    round_decimal_to_f32_bits("100000005960464477539062499999", 1, mid),
    0x3F800000U,
  )
  // an exact f32 and a value far from any midpoint are returned unchanged
  assert_eq(round_decimal_to_f32_bits("15", 1, 1.5), 0x3FC00000U)
  assert_eq(round_decimal_to_f32_bits("1", 0, 0.1), 0x3DCCCCCDU)
}
