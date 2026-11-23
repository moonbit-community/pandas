///|
/// Case ids that cannot match polars; each one is documented under
/// "已知差异" in docs/golden/README.md.
let golden_show_skips : Array[String] = []

///|
/// Builds the frame of a golden case (`"frame": [series...]`).
fn golden_frame(items : Array[@json.Json]) -> @pl.DataFrame raise {
  let cols : Array[@pl.Series] = []
  for item in items {
    cols.push(golden_series(item))
  }
  @pl.DataFrame::new(cols)
}

///|
test "show matches the polars golden data" {
  guard @json.parse(golden_show) is Array(cases) else {
    fail("golden_show is not a JSON array")
  }
  assert_eq(cases.length(), 363)
  let failures : Array[String] = []
  let mut checked = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    if golden_show_skips.contains(id) {
      continue
    }
    guard obj.get("expected") is Some(String(expected)) else {
      fail("\{id}: no expected")
    }
    let actual = match (obj.get("frame"), obj.get("series")) {
      (Some(Array(items)), None) => golden_frame(items).to_string()
      (None, Some(series)) => golden_series(series).to_string()
      _ => fail("\{id}: neither frame nor series")
    }
    checked += 1
    if actual != expected {
      failures.push("[\{id}] expected:\n\{expected}\ngot:\n\{actual}")
    }
  }
  if failures.length() > 0 {
    fail(
      "\{failures.length()} of \{checked} golden cases failed:\n" +
      failures.join("\n\n"),
    )
  }
  assert_eq(checked + golden_show_skips.length(), 363)
}
