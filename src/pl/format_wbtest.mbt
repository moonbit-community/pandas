///|
test "cell_text is the table-cell text of a value" {
  assert_eq(cell_text(Null), "null")
  assert_eq(cell_text(Boolean(true)), "true")
  assert_eq(cell_text(Int32(-7)), "-7")
  assert_eq(cell_text(Float64(1.0)), "1.0")
  assert_eq(cell_text(Float64(-0.0)), "-0.0")
  assert_eq(cell_text(Float64(1.0 / 3.0)), "0.333333")
  assert_eq(cell_text(Float64(123456789.125)), "1.2346e8")
  assert_eq(cell_text(Float64(1.0e6)), "1e6")
  assert_eq(cell_text(Float64(0.0 / 0.0)), "NaN")
  assert_eq(cell_text(Float64(-1.0 / 0.0)), "-inf")
  assert_eq(cell_text(Float32(0.1)), "0.1")
  assert_eq(cell_text(Float32(1234.5678)), "1234.567749")
  assert_eq(cell_text(Date(0)), "1970-01-01")
  assert_eq(cell_text(Datetime(1000L)), "1970-01-01 00:00:00.001")
}

///|
test "cell_text cuts long strings to 30 characters" {
  let s30 = "a".repeat(30)
  assert_eq(cell_text(String(s30)), s30)
  assert_eq(cell_text(String(s30 + "b")), s30 + "…")
}

///|
test "full_text differs from cell_text only for floats and strings" {
  assert_eq(full_text(Float64(10.0 / 3.0)), "3.3333333333333335")
  assert_eq(cell_text(Float64(10.0 / 3.0)), "3.333333")
  assert_eq(full_text(String("b".repeat(40))), "b".repeat(40))
  let vals : Array[AnyValue] = [
    Null,
    Boolean(true),
    Int32(5),
    Int64(-5L),
    Date(100),
    Datetime(123456L),
  ]
  for v in vals {
    assert_eq(full_text(v), cell_text(v))
  }
}
