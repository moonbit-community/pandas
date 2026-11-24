///|
/// Number of cases `docs/golden/scripts/elementwise.py` writes (415 for polars
/// 2.1.0).
let golden_elementwise_count : Int32 = 415

///|
/// Number of `exp` / `log` cases whose `Float64` values differ from polars in
/// the last bits (at most `golden_ew_max_ulp` units in the last place): the
/// library's `@math.ln` is not the C library's (`ln(3.0)` is one unit off, and
/// the three `log(base=3.0)` cases inherit that). Everything else is compared
/// bit for bit. See docs/golden/known-diffs/elementwise.md.
let golden_elementwise_inexact : Int32 = 3

///|
let golden_ew_max_ulp : Int64 = 2L

///|
/// Compares two `Float64` series allowing at most `golden_ew_max_ulp` units in
/// the last place on finite values (NaN, infinities, signs of zero and nulls
/// must agree exactly). `Some(true)` when they differ within that tolerance,
/// `Some(false)` when they are identical, `None` when they differ more.
fn golden_ew_close(a : @pl.Series, b : @pl.Series) -> Bool? raise {
  let xs = a.to_float64_array()
  let ys = b.to_float64_array()
  if xs.length() != ys.length() {
    return None
  }
  let mut inexact = false
  for i in 0..<xs.length() {
    match (xs[i], ys[i]) {
      (None, None) => ()
      (Some(x), Some(y)) =>
        if x.is_nan() && y.is_nan() {
          continue
        } else if x.reinterpret_as_int64() == y.reinterpret_as_int64() {
          continue
        } else if x.is_nan() || y.is_nan() || x.is_inf() || y.is_inf() {
          return None
        } else {
          let bx = x.reinterpret_as_int64()
          let by = y.reinterpret_as_int64()
          // same sign, neighbouring bit patterns
          let d = if bx > by { bx - by } else { by - bx }
          if (bx < 0L) != (by < 0L) || d > golden_ew_max_ulp {
            return None
          }
          inexact = true
        }
      _ => return None
    }
  }
  Some(inexact)
}

///|
fn golden_ew_interval(name : String) -> @pl.ClosedInterval raise {
  match name {
    "both" => Both
    "left" => Left
    "right" => Right
    "none" => Neither
    _ => fail("golden elementwise: unknown closed \{name}")
  }
}

///|
/// The series a case refers to by key.
fn golden_ew_input(
  inputs : Map[String, @json.Json],
  key : String,
) -> @pl.Series raise {
  match inputs.get(key) {
    Some(j) => golden_series(j)
    None => fail("golden elementwise: unknown input \{key}")
  }
}

///|
/// The extra operands of a case, already decoded.
priv struct GoldenEwArgs {
  base : Double?
  decimals : Int32?
  value : @pl.AnyValue?
  lo : @pl.Series?
  hi : @pl.Series?
  closed : @pl.ClosedInterval
}

///|
/// Decodes `base`, `decimals`, `value`, `lo`, `hi` and `closed` of a case.
fn golden_ew_args(
  inputs : Map[String, @json.Json],
  obj : Map[String, @json.Json],
) -> GoldenEwArgs raise {
  let base = match obj.get("base") {
    Some(String(b)) => Some(golden_double(b))
    _ => None
  }
  let decimals = match obj.get("decimals") {
    Some(Number(d, ..)) => Some(d.to_int())
    _ => None
  }
  let value = match obj.get("value") {
    Some(String(k)) => Some(golden_ew_input(inputs, k).get(0))
    _ => None
  }
  let lo = match obj.get("lo") {
    Some(String(k)) => Some(golden_ew_input(inputs, k))
    _ => None
  }
  let hi = match obj.get("hi") {
    Some(String(k)) => Some(golden_ew_input(inputs, k))
    _ => None
  }
  let closed = match obj.get("closed") {
    Some(String(c)) => golden_ew_interval(c)
    _ => @pl.ClosedInterval::Both
  }
  { base, decimals, value, lo, hi, closed, }
}

///|
/// Runs the operation a golden case names.
fn golden_ew_run(
  op : String,
  a : @pl.Series,
  args : GoldenEwArgs,
) -> @pl.Series raise @pl.PolarsError {
  match (op, args) {
    ("is_null", _) => a.is_null()
    ("is_not_null", _) => a.is_not_null()
    ("is_nan", _) => a.is_nan()
    ("is_not_nan", _) => a.is_not_nan()
    ("is_finite", _) => a.is_finite()
    ("is_infinite", _) => a.is_infinite()
    ("abs", _) => a.abs()
    ("sqrt", _) => a.sqrt()
    ("exp", _) => a.exp()
    ("log", { base: Some(b), .. }) => a.log(base=b)
    ("log", _) => a.log()
    ("round", { decimals: Some(d), .. }) => a.round(decimals=d)
    ("fill_null", { value: Some(v), .. }) => a.fill_null(v)
    ("between", { lo: Some(l), hi: Some(h), closed, .. }) =>
      a.between(l, h, closed~)
    _ =>
      abort("golden elementwise: unknown operation or missing operand: \{op}")
  }
}

///|
/// Series element-wise functions against polars 2.1.0.
test "element-wise functions match the polars golden data" {
  guard @json.parse(golden_elementwise) is Object(doc) else {
    fail("golden_elementwise is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("inputs") is Some(Object(inputs)) else { fail("no inputs") }
  assert_eq(cases.length(), golden_elementwise_count)
  let failures : Array[String] = []
  let mut errors = 0
  let mut values = 0
  let mut inexact = 0
  let mut restricted = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("op") is Some(String(op)) else { fail("\{id}: no op") }
    guard obj.get("a") is Some(String(a_key)) else { fail("\{id}: no a") }
    let a = golden_ew_input(inputs, a_key)
    let label = "[\{id}] \{golden_describe(a)}"
    let args = golden_ew_args(inputs, obj)
    let outcome : Result[@pl.Series, @pl.PolarsError] = Ok(
      golden_ew_run(op, a, args),
    ) catch {
      e => Err(e)
    }
    if obj.get("restricted") is Some(True) {
      // spec 5.5: the library refuses these types; only the variant is required
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
          fail("\{id}: neither result nor error")
        }
        let expected = golden_series(result_json)
        match outcome {
          Err(e) => failures.push("\{label}: unexpected error \{e}")
          Ok(actual) =>
            if actual.name() != expected.name() ||
              actual.dtype() != expected.dtype() {
              failures.push(
                "\{label}: expected \{expected.name()}:\{golden_describe(expected)}, got \{actual.name()}:\{golden_describe(actual)}",
              )
            } else if golden_same(actual, expected) {
              ()
            } else if (op == "exp" || op == "log") &&
              actual.dtype() == @pl.DataType::Float64 &&
              golden_ew_close(actual, expected) is Some(true) {
              inexact += 1
            } else {
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
  assert_eq(errors + values + restricted, golden_elementwise_count)
  assert_eq(inexact, golden_elementwise_inexact)
}
