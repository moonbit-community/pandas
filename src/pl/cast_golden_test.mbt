///|
/// Case ids that cannot match polars; each one is documented under
/// "已知差异" in docs/golden/README.md.
let golden_cast_skips : Array[String] = []

///|
/// Short description of a series for failure messages.
fn golden_describe(s : @pl.Series) -> String {
  "\{s.dtype()}\{@debug.to_string(s.to_list())}"
}

///|
test "cast matches the polars golden data" {
  guard @json.parse(golden_cast) is Array(cases) else {
    fail("golden_cast is not a JSON array")
  }
  // 9 source types x 9 target types x {strict, lenient}
  assert_eq(cases.length(), 162)
  let failures : Array[String] = []
  let mut checked = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    if golden_cast_skips.contains(id) {
      continue
    }
    guard obj.get("from") is Some(from_json) else { fail("\{id}: no from") }
    guard obj.get("to") is Some(String(to_name)) else { fail("\{id}: no to") }
    guard obj.get("strict") is Some(strict_json) else {
      fail("\{id}: no strict")
    }
    let strict = strict_json is True
    let src = golden_series(from_json)
    let to = golden_dtype(to_name)
    let label = "[\{id}] from \{golden_describe(src)} to \{to} strict=\{strict}"
    checked += 1
    let outcome : Result[@pl.Series, @pl.PolarsError] = Ok(
      src.cast(to, strict~),
    ) catch {
      e => Err(e)
    }
    match obj.get("error") {
      Some(String("InvalidOperation")) =>
        if !(outcome is Err(@pl.InvalidOperation(_))) {
          failures.push("\{label}: expected InvalidOperation")
        }
      Some(String("ComputeError")) =>
        if !(outcome is Err(@pl.ComputeError(_))) {
          failures.push("\{label}: expected ComputeError")
        }
      Some(_) => fail("\{id}: unknown error kind")
      None => {
        guard obj.get("result") is Some(result_json) else {
          fail("\{id}: neither result nor error")
        }
        let expected = golden_series(result_json)
        match outcome {
          Err(e) => failures.push("\{label}: unexpected error \{e}")
          Ok(actual) =>
            if !golden_same(actual, expected) {
              failures.push(
                "\{label}: expected \{golden_describe(expected)}, got \{golden_describe(actual)}",
              )
            }
        }
      }
    }
  }
  if failures.length() > 0 {
    fail(
      "\{failures.length()} of \{checked} golden cases failed:\n" +
      failures.join("\n"),
    )
  }
  assert_eq(checked + golden_cast_skips.length(), 162)
}
