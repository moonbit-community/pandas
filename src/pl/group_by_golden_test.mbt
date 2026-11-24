///|
/// Number of cases `docs/golden/scripts/group_by.py` writes (polars 2.1.0).
let golden_group_by_count : Int32 = 814

///|
/// The tail of the message of every `restricted` case: polars gives a list
/// per group, the library refuses it.
let golden_group_by_list_tail : String = " does not reduce each group to one value; this library has no List type, so aggregate it (for example with first(), sum() or len())"

///|
/// `group_by(...).agg(...)` and `group_by(...).len()` against polars 2.1.0
/// (`maintain_order=True`). The data set has the format of the expression
/// ones (see `expr_agg_golden_test.mbt`): per case a table, the key
/// expressions, the aggregations (or `how = "len"` with an optional `name`),
/// and a `result`, an `error` + `message`, or `restricted`. A `restricted`
/// case is one where polars gives a `list[...]` column, which this library
/// has not: only `InvalidOperation` with the fixed message is required. A
/// `known_diff` case carries the library's result, not polars' (a weak
/// literal is an `Int64`). Every case also pins `to_string()` of its keys and
/// aggregations to polars' `str(expr)`.
test "group_by matches the polars golden data" {
  guard @json.parse(golden_group_by) is Object(doc) else {
    fail("golden_group_by is not a JSON object")
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
  let exprs = golden_group_by_cases(inputs)
  assert_eq(cases.length(), golden_group_by_count)
  assert_eq(exprs.length(), golden_group_by_count)
  let failures : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  let mut restricted = 0
  let mut errors = 0
  let mut values = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    seen[id] = true
    guard exprs.get(id) is Some((keys, aggs, name)) else {
      failures.push("[\{id}] no expressions in group_by_cases_test.mbt")
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
    let is_len = obj.get("how") is Some(String("len"))
    let label = "[\{id}] \{polars}"
    // str(expr) of the keys and of the aggregations
    for entry in [("key_str", keys), ("str", aggs)] {
      let (field, es) = entry
      guard obj.get(field) is Some(Array(strs)) else {
        fail("\{id}: no \{field}")
      }
      if strs.length() != es.length() {
        failures.push(
          "\{label}: \{es.length()} expressions, \{strs.length()} \{field}",
        )
      } else {
        for i in 0..<es.length() {
          guard strs[i] is String(expected) else {
            fail("\{id}: \{field} is not text")
          }
          if es[i].to_string() != expected {
            failures.push(
              "\{label}: \{field}: expected \{expected}, got \{es[i].to_string()}",
            )
          }
        }
      }
    }
    let outcome : Result[@pl.DataFrame, @pl.PolarsError] = Ok(
      if is_len {
        match name {
          Some(n) => df.group_by(keys, maintain_order=true).len(name=n)
          None => df.group_by(keys, maintain_order=true).len()
        }
      } else {
        df.group_by(keys, maintain_order=true).agg(aggs)
      },
    ) catch {
      e => Err(e)
    }
    if obj.get("restricted") is Some(True) {
      restricted += 1
      match outcome {
        Err(@pl.InvalidOperation(m)) =>
          if obj.get("list") is Some(True) &&
            !(m.has_prefix("expression ") &&
            m.has_suffix(golden_group_by_list_tail)) {
            failures.push("\{label}: unexpected message \{m}")
          }
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
  assert_eq(restricted + errors + values, golden_group_by_count)
}
