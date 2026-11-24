///|
/// Number of cases `docs/golden/scripts/expr_seq.py` writes (polars 2.1.0).
let golden_expr_seq_count : Int32 = 1011

///|
/// Sequence operations, `str()` and `dt()` on expressions against polars 2.1.0
/// (`select` and `with_columns`). Same format as the T7 data set (see
/// `expr_golden_test.mbt`), plus the `inputs` table of `is_in` values and the
/// `build_error` cases (polars refuses while the expression is built, so there
/// is no `str(expr)`; the library reports the error when it is used). A
/// `restricted` case is one where the library is deliberately stricter than
/// polars (spec 5.5, see docs/golden/known-diffs/expr_seq.md): only
/// `InvalidOperation` is required. A `known_diff` case carries the library's
/// result, not polars'. Every case also pins `to_string()` of its expressions
/// to polars' `str(expr)`.
test "sequence, str and dt expressions match the polars golden data" {
  guard @json.parse(golden_expr_seq) is Object(doc) else {
    fail("golden_expr_seq is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("tables") is Some(Object(tables_json)) else {
    fail("no tables")
  }
  let tables : Map[String, @pl.DataFrame] = Map([])
  for name, j in tables_json {
    tables[name] = golden_expr_frame(j)
  }
  guard doc.get("inputs") is Some(Object(inputs_json)) else {
    fail("no inputs")
  }
  let inputs : Map[String, @pl.Series] = Map([])
  for name, j in inputs_json {
    inputs[name] = golden_series(j)
  }
  let exprs = golden_expr_seq_cases(inputs)
  assert_eq(cases.length(), golden_expr_seq_count)
  assert_eq(exprs.length(), golden_expr_seq_count)
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
      failures.push("[\{id}] no expressions in expr_seq_cases_test.mbt")
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
            if k != kind ||
              !(m == message ||
              (
                obj.get("polars_message") is Some(_) &&
                m.has_prefix(message + ": ")
              )) {
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
  assert_eq(restricted + errors + values, golden_expr_seq_count)
}

///|
/// Number of cases of `frame_cases` in the golden data.
let golden_expr_seq_frame_count : Int32 = 165

///|
fn golden_expr_seq_strategy(name : String) -> @pl.FillStrategy raise {
  match name {
    "forward" => @pl.FillStrategy::Forward
    "backward" => @pl.FillStrategy::Backward
    "min" => @pl.FillStrategy::Min
    "max" => @pl.FillStrategy::Max
    "mean" => @pl.FillStrategy::Mean
    "zero" => @pl.FillStrategy::Zero
    "one" => @pl.FillStrategy::One
    _ => fail("unknown strategy \{name}")
  }
}

///|
/// `DataFrame::fill_null_strategy` against `df.fill_null(strategy=..., limit=...)`
/// of polars 2.1.0, on frames of every type mix.
test "DataFrame::fill_null_strategy matches the polars golden data" {
  guard @json.parse(golden_expr_seq) is Object(doc) else {
    fail("golden_expr_seq is not a JSON object")
  }
  guard doc.get("frame_cases") is Some(Array(cases)) else {
    fail("no frame_cases")
  }
  guard doc.get("tables") is Some(Object(tables_json)) else {
    fail("no tables")
  }
  assert_eq(cases.length(), golden_expr_seq_frame_count)
  let failures : Array[String] = []
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("table") is Some(String(table_name)) else {
      fail("\{id}: no table")
    }
    guard tables_json.get(table_name) is Some(table_json) else {
      fail("\{id}: unknown table \{table_name}")
    }
    let df = golden_expr_frame(table_json)
    guard obj.get("strategy") is Some(String(sname)) else {
      fail("\{id}: no strategy")
    }
    let strategy = golden_expr_seq_strategy(sname)
    let limit : Int32? = match obj.get("limit") {
      Some(Number(n, ..)) => Some(n.to_int())
      _ => None
    }
    let polars = match obj.get("polars") {
      Some(String(p)) => p
      _ => fail("\{id}: no polars spelling")
    }
    let label = "[\{id}] \{polars}"
    let outcome : Result[@pl.DataFrame, @pl.PolarsError] = Ok(
      df.fill_null_strategy(strategy, limit?),
    ) catch {
      e => Err(e)
    }
    match obj.get("error") {
      Some(String(kind)) => {
        guard obj.get("message") is Some(String(message)) else {
          fail("\{id}: error case without message")
        }
        match outcome {
          Err(e) => {
            let (k, m) = golden_error_parts(e)
            if k != kind ||
              !(m == message ||
              (
                obj.get("polars_message") is Some(_) &&
                m.has_prefix(message + ": ")
              )) {
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
        guard obj.get("result") is Some(result_json) else {
          fail("\{id}: neither result nor error")
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
  if failures.length() > 0 {
    let shown = if failures.length() > 40 {
      failures[:40].to_owned()
    } else {
      failures
    }
    fail(
      "\{failures.length()} of \{cases.length()} frame cases failed:\n" +
      shown.join("\n"),
    )
  }
}
