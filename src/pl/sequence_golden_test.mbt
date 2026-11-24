///|
/// Number of cases `docs/golden/scripts/sequence.py` writes (polars 2.1.0).
let golden_sequence_count : Int32 = 1641

///|
fn golden_sequence_method(name : String) -> @pl.RankMethod raise {
  match name {
    "average" => @pl.RankMethod::Average
    "min" => @pl.RankMethod::Min
    "max" => @pl.RankMethod::Max
    "dense" => @pl.RankMethod::Dense
    "ordinal" => @pl.RankMethod::Ordinal
    _ => fail("golden sequence: unknown rank method \{name}")
  }
}

///|
fn golden_sequence_strategy(name : String) -> @pl.FillStrategy raise {
  match name {
    "forward" => @pl.FillStrategy::Forward
    "backward" => @pl.FillStrategy::Backward
    "min" => @pl.FillStrategy::Min
    "max" => @pl.FillStrategy::Max
    "mean" => @pl.FillStrategy::Mean
    "zero" => @pl.FillStrategy::Zero
    "one" => @pl.FillStrategy::One
    _ => fail("golden sequence: unknown fill strategy \{name}")
  }
}

///|
/// The fill value of a shift case, `{"dtype": ..., "value": ...}`, as an
/// `AnyValue` (decoded like a series of one row).
fn golden_sequence_fill(j : @json.Json) -> @pl.AnyValue raise {
  guard j is Object(obj) else { fail("golden sequence: fill is not an object") }
  guard obj.get("dtype") is Some(String(dtype)) else {
    fail("golden sequence: fill without dtype")
  }
  guard obj.get("value") is Some(value) else {
    fail("golden sequence: fill without value")
  }
  let s : Map[String, @json.Json] = Map([])
  s["name"] = @json.Json::string("f")
  s["dtype"] = @json.Json::string(dtype)
  s["values"] = @json.Json::array([value])
  golden_series(@json.Json::object(s)).get(0)
}

///|
/// The operation a golden case names with the parameters it carries, ready to
/// run (the parameters are decoded here so that the run itself can only raise
/// a `PolarsError`).
fn golden_sequence_op(
  op : String,
  s : @pl.Series,
  obj : Map[String, @json.Json],
) -> (() -> @pl.Series raise @pl.PolarsError) raise {
  let n = match obj.get("n") {
    Some(Number(d, ..)) => d.to_int()
    _ => 1
  }
  let reverse = obj.get("reverse") is Some(True)
  match op {
    "shift" =>
      match obj.get("fill") {
        Some(f) => {
          let fill = golden_sequence_fill(f)
          () => s.shift(n~, fill_value=fill)
        }
        None => () => s.shift(n~)
      }
    "diff" => () => s.diff(n~)
    "cum_sum" => () => s.cum_sum(reverse~)
    "cum_min" => () => s.cum_min(reverse~)
    "cum_max" => () => s.cum_max(reverse~)
    "cum_prod" => () => s.cum_prod(reverse~)
    "cum_count" => () => s.cum_count(reverse~)
    "reverse" => () => s.reverse()
    "rank" => {
      guard obj.get("method") is Some(String(m)) else {
        fail("rank: no method")
      }
      let method = golden_sequence_method(m)
      let descending = obj.get("descending") is Some(True)
      () => s.rank(method_=method, descending~)
    }
    "fill_null" => {
      guard obj.get("strategy") is Some(String(st)) else {
        fail("fill_null: no strategy")
      }
      let strategy = golden_sequence_strategy(st)
      let limit = match obj.get("limit") {
        Some(Number(d, ..)) => Some(d.to_int())
        _ => None
      }
      () => s.fill_null_strategy(strategy, limit?)
    }
    _ => fail("golden sequence: unknown operation \{op}")
  }
}

///|
/// shift, diff, cum_*, rank, reverse and fill_null(strategy) against polars
/// 2.1.0 (every case carries its Python spelling in `polars`). A `restricted`
/// case is one where polars returns a Duration (diff of Date and Datetime),
/// a type the library does not have: only `InvalidOperation` is required (see
/// docs/golden/known-diffs/sequence.md).
test "sequence operations match the polars golden data" {
  guard @json.parse(golden_sequence) is Object(doc) else {
    fail("golden_sequence is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("inputs") is Some(Object(inputs)) else { fail("no inputs") }
  assert_eq(cases.length(), golden_sequence_count)
  let failures : Array[String] = []
  let mut errors = 0
  let mut values = 0
  let mut restricted = 0
  let ops : Map[String, Int32] = Map([])
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("op") is Some(String(op)) else { fail("\{id}: no op") }
    guard obj.get("a") is Some(String(key)) else { fail("\{id}: no a") }
    ops[op] = ops.get(op).unwrap_or(0) + 1
    let a = golden_arith_input(inputs, key)
    let label = "[\{id}] \{golden_describe(a)} \{op}"
    let run = golden_sequence_op(op, a, obj)
    let outcome : Result[@pl.Series, @pl.PolarsError] = Ok(run()) catch {
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
        guard obj.get("result") is Some(j) else { fail("\{id}: no result") }
        let expected = golden_series(j)
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
  assert_eq(errors + values + restricted, golden_sequence_count)
  assert_eq(ops.length(), 10)
}
