///|
/// Number of cases `docs/golden/scripts/frame_ops.py` writes (polars 2.1.0).
let golden_frame_ops_count : Int32 = 495

///|
/// The rows of a frame as text, sorted: for the cases whose row order polars
/// does not promise (`unique(maintain_order=False)`).
fn golden_frame_ops_row_set(df : @pl.DataFrame) -> Array[String] {
  let rows : Array[String] = []
  for i in 0..<df.height() {
    let row = df.row(i) catch { _ => abort("row out of range") }
    rows.push(@debug.to_string(row))
  }
  rows.sort()
  rows
}

///|
/// DataFrame operations against polars 2.1.0. A case carries its result as a
/// frame (`result`), as row numbers of its table (`rows`), as an error
/// (`error` and `message`) or as `restricted` (the library is stricter than
/// polars: only `InvalidOperation`). A `known_diff` case carries the
/// library's result. See docs/golden/known-diffs/frame_ops.md.
test "frame operations match the polars golden data" {
  guard @json.parse(golden_frame_ops) is Object(doc) else {
    fail("golden_frame_ops is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("tables") is Some(Object(tables_json)) else {
    fail("no tables")
  }
  let tables : Map[String, @pl.DataFrame] = Map([])
  for name, j in tables_json {
    tables[name] = golden_expr_frame(j)
  }
  let ops = golden_frame_ops_cases()
  assert_eq(cases.length(), golden_frame_ops_count)
  assert_eq(ops.length(), golden_frame_ops_count)
  let failures : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  let mut restricted = 0
  let mut errors = 0
  let mut values = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    seen[id] = true
    guard ops.get(id) is Some(run) else {
      failures.push("[\{id}] no call in frame_ops_golden_cases_test.mbt")
      continue
    }
    guard obj.get("polars") is Some(String(polars)) else {
      fail("\{id}: no polars spelling")
    }
    guard obj.get("table") is Some(String(table_name)) else {
      fail("\{id}: no table")
    }
    guard tables.get(table_name) is Some(df) else {
      fail("\{id}: unknown table \{table_name}")
    }
    let label = "[\{id}] \{polars}"
    let outcome : Result[@pl.DataFrame, @pl.PolarsError] = Ok(run(df)) catch {
      e => Err(e)
    }
    if obj.get("restricted") is Some(True) {
      restricted += 1
      match outcome {
        Err(@pl.InvalidOperation(_)) => ()
        Err(e) => failures.push("\{label}: expected InvalidOperation, got \{e}")
        Ok(r) =>
          failures.push(
            "\{label}: expected InvalidOperation, got \{golden_frame_describe(r)}",
          )
      }
      continue
    }
    match obj.get("error") {
      Some(String(kind)) => {
        errors += 1
        guard obj.get("message") is Some(String(message)) else {
          fail("\{id}: error case without message")
        }
        match outcome {
          Err(e) => {
            let (k, m) = golden_error_parts(e)
            if k != kind || m != message {
              failures.push("\{label}: expected \{kind}(\{message}), got \{e}")
            }
          }
          Ok(r) =>
            failures.push(
              "\{label}: expected \{kind}(\{message}), got \{golden_frame_describe(r)}",
            )
        }
      }
      Some(_) => fail("\{id}: error kind is not a string")
      None => {
        values += 1
        let expected : @pl.DataFrame = match
          (obj.get("result"), obj.get("rows")) {
          (Some(r), _) => golden_expr_frame(r)
          (None, Some(Array(rows))) =>
            df.gather(
              rows.map(r => {
                match r {
                  Number(d, ..) => d.to_int()
                  _ => fail("\{id}: row number is not a number")
                }
              }),
            )
          _ => fail("\{id}: neither result, rows, error nor restricted")
        }
        match outcome {
          Err(e) => failures.push("\{label}: unexpected error \{e}")
          Ok(actual) =>
            if obj.get("unordered") is Some(True) {
              if actual.columns() != expected.columns() ||
                actual.dtypes() != expected.dtypes() ||
                golden_frame_ops_row_set(actual) !=
                golden_frame_ops_row_set(expected) {
                failures.push(
                  "\{label}: expected the rows of \{golden_frame_describe(expected)}, got \{golden_frame_describe(actual)}",
                )
              }
            } else if !golden_frame_same(actual, expected) {
              failures.push(
                "\{label}: expected \{golden_frame_describe(expected)}, got \{golden_frame_describe(actual)}",
              )
            }
        }
      }
    }
  }
  for id, _ in ops {
    if !seen.contains(id) {
      failures.push("[\{id}] call without a golden case")
    }
  }
  if failures.length() > 0 {
    let shown = if failures.length() > 60 {
      failures[:60].to_owned()
    } else {
      failures
    }
    fail(
      "\{failures.length()} of \{cases.length()} golden cases failed:\n" +
      shown.join("\n"),
    )
  }
  assert_eq(restricted + errors + values, golden_frame_ops_count)
}
