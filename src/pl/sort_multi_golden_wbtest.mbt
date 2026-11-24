///|
/// Number of multi-key sort cases `docs/golden/scripts/sort.py` writes into
/// `sort_multi.json` (polars 2.1.0).
let golden_sort_multi_sort_count : Int32 = 80

///|
/// Number of multi-key unique cases in the same file.
let golden_sort_multi_unique_count : Int32 = 104

///|
fn sortw_double(text : String) -> Double raise {
  match text {
    "nan" => 0.0 / 0.0
    "inf" => 1.0 / 0.0
    "-inf" => -1.0 / 0.0
    _ => @string.parse_double(text)
  }
}

///|
fn[T] sortw_conv(
  vals : Array[String?],
  f : (String) -> T raise,
) -> Array[T?] raise {
  let out : Array[T?] = []
  for v in vals {
    match v {
      None => out.push(None)
      Some(s) => out.push(Some(f(s)))
    }
  }
  out
}

///|
/// Rebuilds one column from `{"name", "dtype", "values"}` (see
/// `docs/golden/scripts/emit.py`).
fn sortw_column(j : @json.Json) -> Column raise {
  guard j is Object(obj) else { fail("sort multi: column is not an object") }
  guard obj.get("dtype") is Some(String(dtype)) else {
    fail("sort multi: missing dtype")
  }
  guard obj.get("values") is Some(Array(items)) else {
    fail("sort multi: missing values")
  }
  let vals : Array[String?] = []
  for item in items {
    match item {
      Null => vals.push(None)
      String(s) => vals.push(Some(s))
      _ => fail("sort multi: unexpected value")
    }
  }
  match dtype {
    "bool" =>
      Boolean(
        @arrow.BoolArray::from_options(
          sortw_conv(vals, s => {
            match s {
              "true" => true
              "false" => false
              _ => fail("sort multi: bad bool \{s}")
            }
          }),
        ),
      )
    "i32" =>
      Int32(
        @arrow.PrimArray::from_options(
          sortw_conv(vals, s => @string.parse_int(s)),
        ),
      )
    "i64" =>
      Int64(
        @arrow.PrimArray::from_options(
          sortw_conv(vals, s => @string.parse_int64(s)),
        ),
      )
    "f32" =>
      Float32(
        @arrow.PrimArray::from_options(
          sortw_conv(vals, s => Float::from_double(sortw_double(s))),
        ),
      )
    "f64" =>
      Float64(@arrow.PrimArray::from_options(sortw_conv(vals, sortw_double)))
    "str" => String(@arrow.StrArray::from_options(vals))
    "date" =>
      Date(
        @arrow.PrimArray::from_options(
          sortw_conv(vals, s => @string.parse_int(s)),
        ),
      )
    "datetime[\u{3bc}s]" =>
      Datetime(
        @arrow.PrimArray::from_options(
          sortw_conv(vals, s => @string.parse_int64(s)),
        ),
      )
    _ => fail("sort multi: unknown dtype \{dtype}")
  }
}

///|
fn sortw_columns(j : @json.Json) -> Array[Column] raise {
  guard j is Array(items) else { fail("sort multi: cols is not an array") }
  items.map(sortw_column)
}

///|
fn sortw_bools(j : @json.Json) -> Array[Bool] raise {
  guard j is Array(items) else { fail("sort multi: flags are not an array") }
  items.map(x => x is True)
}

///|
fn sortw_ints(j : @json.Json) -> Array[Int32] raise {
  guard j is Array(items) else { fail("sort multi: result is not an array") }
  items.map(x => {
    guard x is Number(n, ..) else { fail("sort multi: result entry") }
    n.to_int()
  })
}

///|
/// `arg_sort_columns` against `DataFrame.sort(by=..., descending=[...],
/// nulls_last=[...], maintain_order=True)` of polars 2.1.0.
test "arg_sort_columns matches the polars multi-key golden data" {
  guard @json.parse(golden_sort_multi) is Object(doc) else {
    fail("golden_sort_multi is not a JSON object")
  }
  guard doc.get("sort") is Some(Array(cases)) else { fail("no sort cases") }
  assert_eq(cases.length(), golden_sort_multi_sort_count)
  let failures : Array[String] = []
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    let cols = sortw_columns(obj.get("cols").unwrap())
    let desc = sortw_bools(obj.get("descending").unwrap())
    let nulls_last = sortw_bools(obj.get("nulls_last").unwrap())
    let expected = sortw_ints(obj.get("result").unwrap())
    let actual = arg_sort_columns(cols, desc, nulls_last)
    if actual != expected {
      failures.push(
        "[\{id}] expected \{@debug.to_string(expected)}, got \{@debug.to_string(actual)}",
      )
    }
  }
  if failures.length() > 0 {
    fail(
      "\{failures.length()} of \{cases.length()} cases failed:\n" +
      failures.join("\n"),
    )
  }
}

///|
/// `unique_row_indices` against `DataFrame.unique(subset=..., keep=...,
/// maintain_order=True)` of polars 2.1.0.
test "unique_row_indices matches the polars multi-key golden data" {
  guard @json.parse(golden_sort_multi) is Object(doc) else {
    fail("golden_sort_multi is not a JSON object")
  }
  guard doc.get("unique") is Some(Array(cases)) else { fail("no unique cases") }
  assert_eq(cases.length(), golden_sort_multi_unique_count)
  let failures : Array[String] = []
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("keep") is Some(String(keep_name)) else {
      fail("\{id}: no keep")
    }
    let keep = match keep_name {
      "any" => UniqueKeep::Any
      "first" => UniqueKeep::First
      "last" => UniqueKeep::Last
      "none" => UniqueKeep::KeepNone
      _ => fail("\{id}: unknown keep \{keep_name}")
    }
    let cols = sortw_columns(obj.get("cols").unwrap())
    let expected = sortw_ints(obj.get("result").unwrap())
    let actual = unique_row_indices(cols, keep)
    if actual != expected {
      failures.push(
        "[\{id}] expected \{@debug.to_string(expected)}, got \{@debug.to_string(actual)}",
      )
    }
  }
  if failures.length() > 0 {
    fail(
      "\{failures.length()} of \{cases.length()} cases failed:\n" +
      failures.join("\n"),
    )
  }
}
