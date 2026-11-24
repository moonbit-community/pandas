///|
/// Number of cases `docs/golden/scripts/concat_describe.py` writes (polars
/// 2.1.0).
let golden_concat_describe_count : Int32 = 1033

///|
/// The frame of the golden encoding `{"columns": [series, ...]}`.
fn golden_cd_frame(j : @json.Json) -> @pl.DataFrame raise {
  guard j is Object(obj) else { fail("golden frame: expected an object") }
  guard obj.get("columns") is Some(Array(items)) else {
    fail("golden frame: missing columns")
  }
  let cols : Array[@pl.Series] = []
  for item in items {
    cols.push(golden_series(item))
  }
  @pl.DataFrame::new(cols)
}

///|
fn golden_cd_input(
  inputs : Map[String, @json.Json],
  key : String,
) -> @json.Json raise {
  match inputs.get(key) {
    Some(j) => j
    None => fail("golden concat_describe: unknown input \{key}")
  }
}

///|
/// The strings of the array field `name` of a case.
fn golden_cd_strings(
  obj : Map[String, @json.Json],
  name : String,
) -> Array[String] raise {
  guard obj.get(name) is Some(Array(items)) else {
    fail("golden concat_describe: missing array \{name}")
  }
  let out : Array[String] = []
  for item in items {
    guard item is String(s) else { fail("\{name}: not a string") }
    out.push(s)
  }
  out
}

///|
fn golden_cd_string(
  obj : Map[String, @json.Json],
  name : String,
) -> String raise {
  guard obj.get(name) is Some(String(s)) else {
    fail("golden concat_describe: missing string \{name}")
  }
  s
}

///|
fn golden_cd_how(name : String) -> @pl.ConcatHow raise {
  match name {
    "vertical" => @pl.ConcatHow::Vertical
    "vertical_relaxed" => @pl.ConcatHow::VerticalRelaxed
    "horizontal" => @pl.ConcatHow::Horizontal
    "diagonal" => @pl.ConcatHow::Diagonal
    _ => fail("golden concat_describe: unknown how \{name}")
  }
}

///|
fn golden_cd_interpolation(name : String) -> @pl.QuantileMethod raise {
  match name {
    "nearest" => @pl.QuantileMethod::Nearest
    "higher" => @pl.QuantileMethod::Higher
    "lower" => @pl.QuantileMethod::Lower
    "midpoint" => @pl.QuantileMethod::Midpoint
    "linear" => @pl.QuantileMethod::Linear
    "equiprobable" => @pl.QuantileMethod::Equiprobable
    _ => fail("golden concat_describe: unknown interpolation \{name}")
  }
}

///|
/// The operation of a case with its arguments already decoded, so that only
/// the library call can raise a `PolarsError`.
fn golden_cd_thunk(
  op : String,
  obj : Map[String, @json.Json],
  inputs : Map[String, @json.Json],
) -> (() -> @pl.DataFrame raise @pl.PolarsError) raise {
  match op {
    "concat" => {
      let frames : Array[@pl.DataFrame] = []
      for k in golden_cd_strings(obj, "frames") {
        frames.push(golden_cd_frame(golden_cd_input(inputs, k)))
      }
      let how = golden_cd_how(golden_cd_string(obj, "how"))
      () => @pl.concat(frames, how~)
    }
    "vstack" => {
      let a = golden_cd_frame(
        golden_cd_input(inputs, golden_cd_string(obj, "a")),
      )
      let b = golden_cd_frame(
        golden_cd_input(inputs, golden_cd_string(obj, "b")),
      )
      () => a.vstack(b)
    }
    "hstack" => {
      let a = golden_cd_frame(
        golden_cd_input(inputs, golden_cd_string(obj, "a")),
      )
      let cols : Array[@pl.Series] = []
      for k in golden_cd_strings(obj, "columns") {
        cols.push(golden_series(golden_cd_input(inputs, k)))
      }
      () => a.hstack(cols)
    }
    "append" => {
      let a = golden_series(golden_cd_input(inputs, golden_cd_string(obj, "a")))
      let b = golden_series(golden_cd_input(inputs, golden_cd_string(obj, "b")))
      () => a.append(b).to_frame()
    }
    "to_frame" => {
      let a = golden_series(golden_cd_input(inputs, golden_cd_string(obj, "a")))
      () => a.to_frame()
    }
    "describe" => {
      let a = golden_cd_frame(
        golden_cd_input(inputs, golden_cd_string(obj, "a")),
      )
      let ip = match obj.get("interpolation") {
        Some(String(name)) => golden_cd_interpolation(name)
        _ => @pl.QuantileMethod::Nearest
      }
      match obj.get("percentiles") {
        Some(_) => {
          let ps : Array[Double] = []
          for t in golden_cd_strings(obj, "percentiles") {
            ps.push(golden_double(t))
          }
          () => a.describe(percentiles=ps, interpolation=ip)
        }
        None => () => a.describe(interpolation=ip)
      }
    }
    _ => fail("golden concat_describe: unknown operation \{op}")
  }
}

///|
/// `true` when two doubles agree: both NaN, equal (the infinities included) or
/// within the relative tolerance `rel`.
fn golden_cd_close(x : Double, y : Double, rel : Double) -> Bool {
  if x.is_nan() || y.is_nan() {
    return x.is_nan() && y.is_nan()
  }
  if x == y {
    return true
  }
  if x.is_inf() || y.is_inf() {
    return false
  }
  let scale = if x.abs() > y.abs() { x.abs() } else { y.abs() }
  (x - y).abs() <= rel * scale
}

///|
/// Names, types and values (including the sign of zero) of two frames. With
/// `describe`, the `mean` and `std` rows of `Float64` columns only need to
/// agree within a relative `1e-12` (the library's `std` is a two-pass
/// algorithm and polars' is not, see docs/golden/known-diffs/agg.md and
/// concat_describe.md).
fn golden_cd_same(
  a : @pl.DataFrame,
  b : @pl.DataFrame,
  describe~ : Bool,
) -> Bool raise @pl.PolarsError {
  if a.shape() != b.shape() ||
    a.columns() != b.columns() ||
    a.dtypes() != b.dtypes() {
    return false
  }
  let xs = a.get_columns()
  let ys = b.get_columns()
  let labels = if describe && b.width() > 0 {
    b.column("statistic").to_str_array()
  } else {
    []
  }
  for i in 0..<xs.length() {
    if !describe || xs[i].dtype() != @pl.DataType::Float64 {
      if !golden_same(xs[i], ys[i]) {
        return false
      }
      continue
    }
    let p = xs[i].to_float64_array()
    let q = ys[i].to_float64_array()
    for r in 0..<p.length() {
      match (p[r], q[r]) {
        (None, None) => ()
        (Some(x), Some(y)) => {
          let loose = labels[r] is Some("mean" | "std")
          let same = if loose {
            golden_cd_close(x, y, 1.0e-12)
          } else {
            (x.is_nan() && y.is_nan()) ||
            x.reinterpret_as_int64() == y.reinterpret_as_int64()
          }
          if !same {
            return false
          }
        }
        _ => return false
      }
    }
  }
  true
}

///|
fn golden_cd_show(df : @pl.DataFrame) -> String {
  let (h, w) = df.shape()
  let parts = df.get_columns().map(s => "\{s.name()}:\{golden_describe(s)}")
  "(\{h}x\{w}) " + parts.join(", ")
}

///|
/// `concat`, `vstack`, `hstack`, `append`, `to_frame` and `describe` against
/// polars 2.1.0: values, types and error variants with their messages.
test "concat, stacking, append and describe match the polars golden data" {
  guard @json.parse(golden_concat_describe) is Object(doc) else {
    fail("golden_concat_describe is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("inputs") is Some(Object(inputs)) else { fail("no inputs") }
  assert_eq(cases.length(), golden_concat_describe_count)
  let failures : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  let ops : Map[String, Int32] = Map([])
  let mut errors = 0
  let mut values = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("op") is Some(String(op)) else { fail("\{id}: no op") }
    guard obj.get("polars") is Some(String(polars)) else {
      fail("\{id}: no polars spelling")
    }
    assert_false(seen.contains(id))
    seen[id] = true
    ops[op] = ops.get(op).unwrap_or(0) + 1
    let label = "[\{id}] \{polars}"
    let run = golden_cd_thunk(op, obj, inputs)
    let outcome : Result[@pl.DataFrame, @pl.PolarsError] = Ok(run()) catch {
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
              "\{label}: expected \{kind}(\{message}), got \{golden_cd_show(r)}",
            )
        }
      }
      Some(_) => fail("\{id}: error kind is not a string")
      None => {
        values += 1
        guard obj.get("result") is Some(result_json) else {
          fail("\{id}: neither result nor error")
        }
        // `append` gives a series: compare it as a one-column frame
        let expected = match result_json {
          Object(r) if r.contains("columns") => golden_cd_frame(result_json)
          _ => golden_series(result_json).to_frame()
        }
        match outcome {
          Err(e) => failures.push("\{label}: unexpected error \{e}")
          Ok(actual) =>
            if !golden_cd_same(actual, expected, describe=op == "describe") {
              failures.push(
                "\{label}: expected \{golden_cd_show(expected)}, got \{golden_cd_show(actual)}",
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
      "\{failures.length()} of \{cases.length()} golden cases failed:\n" +
      shown.join("\n"),
    )
  }
  assert_eq(errors + values, golden_concat_describe_count)
  // every operation is covered
  assert_true(ops.get("concat").unwrap_or(0) > 0)
  assert_true(ops.get("vstack").unwrap_or(0) > 0)
  assert_true(ops.get("hstack").unwrap_or(0) > 0)
  assert_true(ops.get("append").unwrap_or(0) > 0)
  assert_true(ops.get("to_frame").unwrap_or(0) > 0)
  assert_true(ops.get("describe").unwrap_or(0) > 0)
  assert_eq(ops.length(), 6)
}
