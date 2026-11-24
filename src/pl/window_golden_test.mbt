///|
/// Number of cases `docs/golden/scripts/window.py` writes (polars 2.1.0).
let golden_window_count : Int32 = 574

///|
/// `Expr::over` against polars 2.1.0: aggregations, sequence operations,
/// expressions that work row by row or mix rows and aggregations, the methods
/// that sort, cut and filter (the result must be as long as the partition),
/// partition keys of every kind, several windows, `DataFrame::filter` and
/// `DataFrame::sort` with a window, frames without rows. The data set has the
/// format of the expression ones (see `expr_shape_golden_test.mbt`); `op` is
/// `select` (the default), `with_columns`, `filter` (one predicate) or `sort`
/// (the sort keys). A `restricted` case is one where the library is stricter
/// than polars (only `InvalidOperation` is required); a `known_diff` case
/// carries the library's result, not polars' (a weak literal is an `Int64`).
/// Every case also pins `to_string()` of its expressions to polars'
/// `str(expr)`.
test "over matches the polars golden data" {
  guard @json.parse(golden_window) is Object(doc) else {
    fail("golden_window is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("tables") is Some(Object(tables_json)) else {
    fail("no tables")
  }
  let tables : Map[String, @pl.DataFrame] = Map([])
  for name, j in tables_json {
    tables[name] = golden_expr_frame(j)
  }
  let exprs = golden_window_cases()
  assert_eq(cases.length(), golden_window_count)
  assert_eq(exprs.length(), golden_window_count)
  let failures : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  let mut restricted = 0
  let mut errors = 0
  let mut values = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    seen[id] = true
    guard exprs.get(id) is Some(es) else {
      failures.push("[\{id}] no expressions in window_cases_test.mbt")
      continue
    }
    guard obj.get("polars") is Some(String(polars)) else {
      fail("\{id}: no polars spelling")
    }
    let table_name = match obj.get("table") {
      Some(String(t)) => t
      _ => "t"
    }
    let op = match obj.get("op") {
      Some(String(o)) => o
      _ => "select"
    }
    guard tables.get(table_name) is Some(df) else {
      fail("\{id}: unknown table \{table_name}")
    }
    let label = "[\{id}] \{polars}"
    guard obj.get("str") is Some(Array(strs)) else { fail("\{id}: no str") }
    if obj.get("build_error") is Some(True) {
      ()
    } else if strs.length() != es.length() {
      failures.push(
        "\{label}: \{es.length()} expressions, \{strs.length()} str",
      )
    } else {
      for i in 0..<es.length() {
        guard strs[i] is String(expected) else {
          fail("\{id}: str is not text")
        }
        if es[i].to_string() != expected {
          failures.push(
            "\{label}: str: expected \{expected}, got \{es[i].to_string()}",
          )
        }
      }
    }
    let outcome : Result[@pl.DataFrame, @pl.PolarsError] = Ok(
      match op {
        "select" => df.select(es)
        "with_columns" => df.with_columns(es)
        "filter" => df.filter(es[0])
        "sort" => df.sort(es)
        _ => abort("golden: unknown op \{op}")
      },
    ) catch {
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
        guard obj.get("result") is Some(result_json) else {
          fail("\{id}: neither result, error nor restricted")
        }
        let expected = golden_expr_frame(result_json)
        match outcome {
          Err(e) => failures.push("\{label}: unexpected error \{e}")
          Ok(actual) =>
            if !golden_frame_same(actual, expected) {
              failures.push(
                "\{label}: expected \{golden_frame_describe(expected)}, got \{golden_frame_describe(actual)}",
              )
            }
        }
      }
    }
  }
  for id, _ in exprs {
    if !seen.contains(id) {
      failures.push("[\{id}] expressions without a golden case")
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
  assert_eq(restricted + errors + values, golden_window_count)
}
