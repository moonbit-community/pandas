///|
/// Number of cases `docs/golden/scripts/expr.py` writes (polars 2.1.0).
let golden_expr_count : Int32 = 1479

///|
/// The frame of the golden encoding `{"columns": [series, ...]}`.
fn golden_expr_frame(j : @json.Json) -> @pl.DataFrame raise {
  guard j is Object(obj) else { fail("golden frame: expected an object") }
  guard obj.get("columns") is Some(Array(items)) else {
    fail("golden frame: missing columns")
  }
  @pl.DataFrame::new(items.map(golden_series))
}

///|
/// Names, types and values (including the sign of zero) of two frames.
fn golden_frame_same(a : @pl.DataFrame, b : @pl.DataFrame) -> Bool {
  if a.shape() != b.shape() ||
    a.columns() != b.columns() ||
    a.dtypes() != b.dtypes() {
    return false
  }
  let xs = a.get_columns()
  let ys = b.get_columns()
  for i in 0..<xs.length() {
    if !golden_same(xs[i], ys[i]) {
      return false
    }
  }
  true
}

///|
fn golden_frame_describe(df : @pl.DataFrame) -> String {
  let (h, w) = df.shape()
  let parts = df.get_columns().map(s => "\{s.name()}:\{golden_describe(s)}")
  "(\{h}x\{w}) " + parts.join(", ")
}

///|
/// Expressions against polars 2.1.0 (`select` and `with_columns`). A
/// `restricted` case is one where the library is deliberately stricter than
/// polars (spec 5.5, see docs/golden/known-diffs/expr.md): only
/// `InvalidOperation` is required. A `known_diff` case carries the library's
/// result, not polars'. Every case also pins `to_string()` of its expressions
/// to polars' `str(expr)`.
test "expressions match the polars golden data" {
  guard @json.parse(golden_expr) is Object(doc) else {
    fail("golden_expr is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("tables") is Some(Object(tables_json)) else {
    fail("no tables")
  }
  let tables : Map[String, @pl.DataFrame] = Map([])
  for name, j in tables_json {
    tables[name] = golden_expr_frame(j)
  }
  let exprs = golden_expr_cases()
  assert_eq(cases.length(), golden_expr_count)
  assert_eq(exprs.length(), golden_expr_count)
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
      failures.push("[\{id}] no expressions in expr_golden_cases_test.mbt")
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
    // str(expr)
    guard obj.get("str") is Some(Array(strs)) else { fail("\{id}: no str") }
    if strs.length() != es.length() {
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
      if op == "select" {
        df.select(es)
      } else {
        df.with_columns(es)
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
  assert_eq(restricted + errors + values, golden_expr_count)
}
