///|
/// Number of cases `docs/golden/scripts/group_final.py` writes (polars 2.1.0).
let golden_group_final_count : Int32 = 269

///|
/// What `group_by(...).agg(...)` and `over` do with a whole column that polars
/// does per group or with other kernels, against polars 2.1.0
/// (`maintain_order=True`):
///
/// - the format of `str().to_date()` / `to_datetime()` is guessed per group
///   (tables `dd`, `ddx`);
/// - with no key, or keys that are one value (a literal, an aggregation,
///   `len()`), the float `sum`, `mean`, `std` and `var` are the kernels of
///   `select`, with a key column they are the group kernels (table `fl`,
///   1000 rows).
///
/// The format is that of `group_by_ext_golden_test.mbt`: per case a table, the
/// key expressions (`op` is `group_by`) and the aggregations, or the
/// expressions of a `select` (`op` absent) or `with_columns`, and a `result`
/// or an `error` + `message`. A `known_diff` case carries the library's
/// result, not polars' (a weak literal is an `Int64`). Every case also pins
/// `to_string()` of its keys and expressions to polars' `str(expr)`.
test "group_by and over per group and whole column match the polars golden data" {
  guard @json.parse(golden_group_final) is Object(doc) else {
    fail("golden_group_final is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("tables") is Some(Object(tables_json)) else {
    fail("no tables")
  }
  let tables : Map[String, @pl.DataFrame] = Map([])
  for name, j in tables_json {
    tables[name] = golden_expr_frame(j)
  }
  let exprs = golden_group_final_cases()
  assert_eq(cases.length(), golden_group_final_count)
  assert_eq(exprs.length(), golden_group_final_count)
  let failures : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  let mut errors = 0
  let mut values = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    seen[id] = true
    guard exprs.get(id) is Some((keys, aggs)) else {
      failures.push("[\{id}] no expressions in group_final_cases_test.mbt")
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
    let op = match obj.get("op") {
      Some(String(o)) => o
      _ => "select"
    }
    let label = "[\{id}] \{polars}"
    // str(expr) of the keys and of the aggregations
    let pins = if op == "group_by" {
      [("key_str", keys), ("str", aggs)]
    } else {
      [("str", aggs)]
    }
    for entry in pins {
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
      match op {
        "group_by" => df.group_by(keys, maintain_order=true).agg(aggs)
        "select" => df.select(aggs)
        "with_columns" => df.with_columns(aggs)
        _ => abort("golden: unknown op \{op}")
      },
    ) catch {
      e => Err(e)
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
  assert_eq(errors + values, golden_group_final_count)
}
