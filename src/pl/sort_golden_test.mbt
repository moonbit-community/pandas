///|
/// Number of cases `docs/golden/scripts/sort.py` writes into `sort.json`
/// (648 for polars 2.1.0).
let golden_sort_count : Int32 = 648

///|
/// Runs the operation of a golden case; `n_unique` yields its count as a
/// one-element `Int64` series so that every operation returns a series.
fn golden_sort_run(
  op : String,
  desc : Bool,
  nulls_last : Bool,
  a : @pl.Series,
  b : @pl.Series?,
) -> @pl.Series raise @pl.PolarsError {
  match (op, b) {
    ("sort", None) => a.sort(descending=desc, nulls_last~)
    ("arg_sort", None) => a.arg_sort(descending=desc, nulls_last~)
    ("unique", None) => a.unique(maintain_order=true)
    ("n_unique", None) => @pl.Series::int64("n", [a.n_unique().to_int64()])
    ("is_in", Some(o)) => a.is_in(o)
    _ => abort("golden sort: unknown operation \{op}")
  }
}

///|
/// Sort, arg_sort, unique, n_unique and is_in against polars 2.1.0 (every
/// case carries its Python spelling in `polars`).
test "sort, unique and is_in match the polars golden data" {
  guard @json.parse(golden_sort) is Object(doc) else {
    fail("golden_sort is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("inputs") is Some(Object(inputs)) else { fail("no inputs") }
  assert_eq(cases.length(), golden_sort_count)
  let failures : Array[String] = []
  let mut errors = 0
  let mut values = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("op") is Some(String(op)) else { fail("\{id}: no op") }
    guard obj.get("a") is Some(String(a_key)) else { fail("\{id}: no a") }
    let a = golden_arith_input(inputs, a_key)
    let b = match obj.get("b") {
      Some(String(k)) => Some(golden_arith_input(inputs, k))
      _ => None
    }
    let desc = obj.get("descending") is Some(True)
    let nulls_last = obj.get("nulls_last") is Some(True)
    let label = "[\{id}] \{golden_describe(a)} \{op}"
    let outcome : Result[@pl.Series, @pl.PolarsError] = Ok(
      golden_sort_run(op, desc, nulls_last, a, b),
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
              "\{label}: expected \{kind}(\{message}), got \{golden_describe(r)}",
            )
        }
      }
      Some(_) => fail("\{id}: error kind is not a string")
      None => {
        values += 1
        let expected = match (obj.get("result"), obj.get("result_int")) {
          (Some(j), _) => golden_series(j)
          (None, Some(String(n))) =>
            @pl.Series::int64("n", [@string.parse_int64(n)])
          _ => fail("\{id}: neither result, result_int nor error")
        }
        match outcome {
          Err(e) => failures.push("\{label}: unexpected error \{e}")
          Ok(actual) =>
            // n_unique has no polars name: compare values and type only
            if (op != "n_unique" && actual.name() != expected.name()) ||
              actual.dtype() != expected.dtype() ||
              !golden_same(actual, expected) {
              failures.push(
                "\{label}: expected \{expected.name()}:\{golden_describe(expected)}, got \{actual.name()}:\{golden_describe(actual)}",
              )
            }
        }
      }
    }
  }
  if failures.length() > 0 {
    fail(
      "\{failures.length()} of \{cases.length()} golden cases failed:\n" +
      failures.join("\n"),
    )
  }
  assert_eq(errors + values, golden_sort_count)
}
