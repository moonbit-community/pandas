///|
test "error show" {
  let e : @pl.PolarsError = @pl.ColumnNotFound("column 'x' not found")
  inspect(e, content="ColumnNotFound: column 'x' not found")
}

///|
test "error show for every variant" {
  let errs : Array[@pl.PolarsError] = [
    DuplicateColumn("m1"),
    SchemaMismatch("m2"),
    ShapeMismatch("m3"),
    OutOfBounds("m4"),
    InvalidOperation("m5"),
    ComputeError("m6"),
    ParseError("m7"),
  ]
  let expected = [
    "DuplicateColumn: m1", "SchemaMismatch: m2", "ShapeMismatch: m3", "OutOfBounds: m4",
    "InvalidOperation: m5", "ComputeError: m6", "ParseError: m7",
  ]
  for i in 0..<errs.length() {
    assert_eq(Show::to_string(errs[i]), expected[i])
  }
}
// 无错误路径：本文件测的就是错误类型本身；raises 辅助见 test_helpers_test.mbt。

///|
test "error to_string method on a caught error" {
  let df = @pl.DataFrame::new([@pl.Series::int64("a", [1L])])
  try df.column("x") catch {
    e => assert_eq(e.to_string(), "ColumnNotFound: \"x\" not found")
  } noraise {
    _ => fail("expected an error")
  }
  let e : @pl.PolarsError = @pl.OutOfBounds("index 3")
  assert_eq(e.to_string(), "OutOfBounds: index 3")
}
