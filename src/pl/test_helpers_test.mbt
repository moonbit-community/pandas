///|
/// Runs `f`; returns `Some(err)` if it raised a `PolarsError`, `None` otherwise.
fn[T] raises(f : () -> T raise @pl.PolarsError) -> @pl.PolarsError? {
  try {
    ignore(f())
    None
  } catch {
    e => Some(e)
  }
}

///|
test "raises helper" {
  assert_true(raises(() => ()) is None)
  fn boom() -> Unit raise @pl.PolarsError {
    raise @pl.OutOfBounds("x")
  }

  assert_true(raises(boom) is Some(@pl.OutOfBounds(_)))
}
