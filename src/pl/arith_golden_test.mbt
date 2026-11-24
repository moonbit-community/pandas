///|
/// Number of cases `docs/golden/scripts/arith.py` writes (1291 for polars 2.1.0).
let golden_arith_count : Int32 = 1291

///|
/// Runs the operation a golden case names on `a` (and `other`: the right
/// operand, or the mask for `filter`).
fn golden_arith_run(
  op : String,
  a : @pl.Series,
  other : @pl.Series?,
) -> @pl.Series raise @pl.PolarsError {
  match (op, other) {
    ("neg", None) => a.neg()
    ("not", None) => a.not_()
    ("add", Some(b)) => a.add(b)
    ("sub", Some(b)) => a.sub(b)
    ("mul", Some(b)) => a.mul(b)
    ("truediv", Some(b)) => a.div(b)
    ("floordiv", Some(b)) => a.floor_div(b)
    ("mod", Some(b)) => a.rem(b)
    ("eq", Some(b)) => a.eq(b)
    ("ne", Some(b)) => a.neq(b)
    ("gt", Some(b)) => a.gt(b)
    ("ge", Some(b)) => a.ge(b)
    ("lt", Some(b)) => a.lt(b)
    ("le", Some(b)) => a.le(b)
    ("and", Some(b)) => a.and_(b)
    ("or", Some(b)) => a.or_(b)
    ("filter", Some(m)) => a.filter(m)
    _ => abort("golden arith: unknown operation \{op}")
  }
}

///|
/// Variant name and message of a `PolarsError`.
fn golden_error_parts(e : @pl.PolarsError) -> (String, String) {
  match e {
    @pl.ColumnNotFound(m) => ("ColumnNotFound", m)
    @pl.DuplicateColumn(m) => ("DuplicateColumn", m)
    @pl.SchemaMismatch(m) => ("SchemaMismatch", m)
    @pl.ShapeMismatch(m) => ("ShapeMismatch", m)
    @pl.OutOfBounds(m) => ("OutOfBounds", m)
    @pl.InvalidOperation(m) => ("InvalidOperation", m)
    @pl.ComputeError(m) => ("ComputeError", m)
    @pl.ParseError(m) => ("ParseError", m)
  }
}

///|
/// The series a case refers to by key.
fn golden_arith_input(
  inputs : Map[String, @json.Json],
  key : String,
) -> @pl.Series raise {
  match inputs.get(key) {
    Some(j) => golden_series(j)
    None => fail("golden arith: unknown input \{key}")
  }
}

///|
/// Series operators against polars 2.1.0. A `restricted` case is one where the
/// library is deliberately stricter than polars (spec 5.5, see
/// docs/golden/known-diffs/arith.md): only `InvalidOperation` is required.
test "arithmetic, comparison, logic and filter match the polars golden data" {
  guard @json.parse(golden_arith) is Object(doc) else {
    fail("golden_arith is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("inputs") is Some(Object(inputs)) else { fail("no inputs") }
  assert_eq(cases.length(), golden_arith_count)
  let failures : Array[String] = []
  let mut restricted = 0
  let mut errors = 0
  let mut values = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("op") is Some(String(op)) else { fail("\{id}: no op") }
    guard obj.get("a") is Some(String(a_key)) else { fail("\{id}: no a") }
    let a = golden_arith_input(inputs, a_key)
    let other = match (obj.get("b"), obj.get("mask")) {
      (Some(String(k)), _) => Some(golden_arith_input(inputs, k))
      (None, Some(String(k))) => Some(golden_arith_input(inputs, k))
      _ => None
    }
    let label = "[\{id}] \{golden_describe(a)} " +
      (match other {
        Some(o) => "\{op} \{golden_describe(o)}"
        None => op
      })
    let outcome : Result[@pl.Series, @pl.PolarsError] = Ok(
      golden_arith_run(op, a, other),
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
            "\{label}: expected InvalidOperation, got \{golden_describe(r)}",
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
              "\{label}: expected \{kind}(\{message}), got \{golden_describe(r)}",
            )
        }
      }
      Some(_) => fail("\{id}: error kind is not a string")
      None => {
        values += 1
        guard obj.get("result") is Some(result_json) else {
          fail("\{id}: neither result, error nor restricted")
        }
        let expected = golden_series(result_json)
        match outcome {
          Err(e) => failures.push("\{label}: unexpected error \{e}")
          Ok(actual) =>
            if actual.name() != expected.name() ||
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
  assert_eq(restricted + errors + values, golden_arith_count)
}
