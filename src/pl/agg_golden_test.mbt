///|
/// Number of cases `docs/golden/scripts/agg.py` writes (polars 2.1.0).
let golden_agg_count : Int32 = 2472

///|
/// Cases whose result is a zero of the other sign than polars'. polars picks
/// the quantile of two equal-comparing zeros (`[0.0, -0.0]`, `[-0.0, 0.0]`) from
/// an unstable partial sort, so the sign of the zero at the top position
/// depends on its internals; ours keeps the input order of equal values. The
/// value is compared with `==` there. See docs/golden/known-diffs/agg.md.
let golden_agg_zero_sign : Array[String] = [
  "quantile/f32/zeros/nearest/0.5", "quantile/f32/zeros2/nearest/0.5", "quantile/f64/zeros/nearest/0.5",
  "quantile/f64/zeros/nearest/1", "quantile/f64/zeros/higher/0.1", "quantile/f64/zeros/higher/0.5",
  "quantile/f64/zeros/higher/1", "quantile/f64/zeros/lower/1", "quantile/f64/zeros/midpoint/1",
  "quantile/f64/zeros/linear/1", "quantile/f64/zeros/equiprobable/1", "quantile/f64/zeros2/nearest/0.5",
  "quantile/f64/zeros2/nearest/1", "quantile/f64/zeros2/higher/0.1", "quantile/f64/zeros2/higher/0.5",
  "quantile/f64/zeros2/higher/1", "quantile/f64/zeros2/lower/1", "quantile/f64/zeros2/midpoint/1",
  "quantile/f64/zeros2/linear/1", "quantile/f64/zeros2/equiprobable/1",
]

///|
/// Distance in units in the last place between two finite doubles of the same
/// sign (the order of the bit patterns is the order of the magnitudes).
fn golden_agg_ulps64(x : Double, y : Double) -> Int64 {
  let a = x.reinterpret_as_int64()
  let b = y.reinterpret_as_int64()
  if a >= b {
    a - b
  } else {
    b - a
  }
}

///|
/// `true` when two doubles agree: both NaN, equal (infinities and the zeros
/// included) or, for `ulps > 0`, within that many units in the last place
/// (same sign, finite). With `ulps == 0` the bits must match, so the sign of a
/// zero counts.
fn golden_agg_close(x : Double, y : Double, ulps : Int32) -> Bool {
  if x.is_nan() || y.is_nan() {
    return x.is_nan() && y.is_nan()
  }
  if ulps == 0 {
    return x.reinterpret_as_int64() == y.reinterpret_as_int64()
  }
  if x == y {
    return true
  }
  if x.is_inf() || y.is_inf() || (x < 0.0) != (y < 0.0) {
    return false
  }
  golden_agg_ulps64(x, y) <= ulps.to_int64()
}

///|
/// Compares a result with the expected value. Floats must match bit for bit
/// (the sign of zero included) unless `ulps > 0`, which allows that many units
/// in the last place for `Float64` and `Float32`; `loose` compares a zero with
/// `==` (the sign may differ, see `golden_agg_zero_sign`). Everything else is
/// compared exactly.
fn golden_agg_same(
  expected : @pl.AnyValue,
  actual : @pl.AnyValue,
  ulps : Int32,
  loose : Bool,
) -> Bool {
  match (expected, actual) {
    (Float64(x), Float64(y)) =>
      if loose && x == y {
        true
      } else {
        golden_agg_close(x, y, ulps)
      }
    (Float32(x), Float32(y)) =>
      if loose && x == y {
        true
      } else if x.is_nan() || y.is_nan() {
        x.is_nan() && y.is_nan()
      } else if ulps == 0 {
        x.reinterpret_as_int() == y.reinterpret_as_int()
      } else if x == y {
        true
      } else if (x < 0.0) != (y < 0.0) {
        false
      } else {
        let d = x.reinterpret_as_int() - y.reinterpret_as_int()
        (if d < 0 { -d } else { d }) <= ulps
      }
    _ => expected == actual
  }
}

///|
/// The value a case expects as an `AnyValue`: a one-row series is decoded by
/// `golden_series` so every type is parsed the same way as the inputs.
fn golden_agg_expected(
  dtype : String,
  value : @json.Json,
) -> @pl.AnyValue raise {
  let obj : Map[String, @json.Json] = Map([])
  obj["name"] = @json.Json::string("a")
  obj["dtype"] = @json.Json::string(dtype)
  obj["values"] = @json.Json::array([value])
  golden_series(@json.Json::object(obj)).get(0)
}

///|
fn golden_agg_method(name : String) -> @pl.QuantileMethod raise {
  match name {
    "nearest" => @pl.QuantileMethod::Nearest
    "higher" => @pl.QuantileMethod::Higher
    "lower" => @pl.QuantileMethod::Lower
    "midpoint" => @pl.QuantileMethod::Midpoint
    "linear" => @pl.QuantileMethod::Linear
    "equiprobable" => @pl.QuantileMethod::Equiprobable
    _ => fail("golden agg: unknown quantile method \{name}")
  }
}

///|
/// Runs the aggregation a golden case names; `ddof`, `q` and `how` are the
/// case's parameters (ignored by the other operations).
fn golden_agg_run(
  op : String,
  s : @pl.Series,
  ddof : Int32,
  q : Double,
  how : @pl.QuantileMethod,
) -> @pl.AnyValue raise @pl.PolarsError {
  match op {
    "sum" => s.sum()
    "mean" => s.mean()
    "min" => s.min()
    "max" => s.max()
    "first" => s.first()
    "last" => s.last()
    "median" => s.median()
    "product" => s.product()
    "count" => @pl.AnyValue::Int64(s.count().to_int64())
    "len" => @pl.AnyValue::Int64(s.len().to_int64())
    "std" => s.std(ddof~)
    "var" => s.var_(ddof~)
    "quantile" => s.quantile(q, interpolation=how)
    _ => abort("golden agg: unknown operation \{op}")
  }
}

///|
/// Series aggregations against polars 2.1.0 (`pl.select(pl.lit(s).sum())`,
/// result types mapped by `to_ours`): value, result type and the error
/// variant and message. A null result is checked for its value only; its type
/// is covered by `agg_wbtest.mbt` and the expression tests.
test "aggregations match the polars golden data" {
  guard @json.parse(golden_agg) is Object(doc) else {
    fail("golden_agg is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("inputs") is Some(Object(inputs)) else { fail("no inputs") }
  assert_eq(cases.length(), golden_agg_count)
  let failures : Array[String] = []
  let mut errors = 0
  let mut values = 0
  let mut typed = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("op") is Some(String(op)) else { fail("\{id}: no op") }
    guard obj.get("a") is Some(String(key)) else { fail("\{id}: no a") }
    guard inputs.get(key) is Some(input_json) else {
      fail("\{id}: unknown input \{key}")
    }
    let s = golden_series(input_json)
    let label = "[\{id}] \{golden_describe(s)}"
    let ddof = match obj.get("ddof") {
      Some(Number(d, ..)) => d.to_int()
      _ => 1
    }
    let q = match obj.get("q") {
      Some(String(t)) => golden_double(t)
      _ => 0.5
    }
    let how = match obj.get("method") {
      Some(String(m)) => golden_agg_method(m)
      _ => @pl.QuantileMethod::Nearest
    }
    let outcome : Result[@pl.AnyValue, @pl.PolarsError] = Ok(
      golden_agg_run(op, s, ddof, q, how),
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
              "\{label}: expected \{kind}(\{message}), got \{@debug.to_string(r)}",
            )
        }
      }
      Some(_) => fail("\{id}: error kind is not a string")
      None => {
        values += 1
        guard obj.get("dtype") is Some(String(dtype)) else {
          fail("\{id}: no dtype")
        }
        guard obj.get("value") is Some(value) else { fail("\{id}: no value") }
        let expected = golden_agg_expected(dtype, value)
        match outcome {
          Err(e) => failures.push("\{label}: unexpected error \{e}")
          Ok(actual) => {
            // only std / var may differ in the last digits (another order of
            // summation than polars'); sum and mean are bit for bit
            let ulps = match op {
              "std" | "var" => 4
              _ => 0
            }
            let loose = golden_agg_zero_sign.contains(id)
            // a null result carries no type: only a value is type-checked
            if !actual.is_null() {
              typed += 1
              if actual.dtype() != golden_dtype(dtype) {
                failures.push(
                  "\{label}: expected type \{dtype}, got \{actual.dtype()}",
                )
                continue
              }
            }
            if !golden_agg_same(expected, actual, ulps, loose) {
              failures.push(
                "\{label}: expected \{@debug.to_string(expected)}, got \{@debug.to_string(actual)}",
              )
            }
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
  assert_eq(errors + values, golden_agg_count)
  assert_true(typed > 0)
}
