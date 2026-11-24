///|
/// Number of expression cases `docs/golden/scripts/expr_shape.py` writes
/// (polars 2.1.0).
let golden_expr_shape_count : Int32 = 1021

///|
/// Number of `series_cases` in the golden data.
let golden_expr_shape_series_count : Int32 = 341

///|
/// Number of `frame_cases` in the golden data.
let golden_expr_shape_frame_count : Int32 = 15

///|
/// The largest difference, in units in the last place, tolerated between the
/// library's trigonometric results and polars' (the math routines are not the
/// same ones; on every backend a few values differ by one unit). See
/// docs/golden/known-diffs/expr_shape.md.
let golden_expr_shape_max_ulp : Int64 = 1L

///|
/// Whether two `Float64` values are the same up to `golden_expr_shape_max_ulp`
/// units in the last place; NaN, infinities, signs of zero must agree exactly.
fn golden_expr_shape_close64(x : Double, y : Double) -> Bool {
  if x.is_nan() || y.is_nan() {
    return x.is_nan() && y.is_nan()
  }
  let bx = x.reinterpret_as_int64()
  let by = y.reinterpret_as_int64()
  if bx == by {
    return true
  }
  if x.is_inf() || y.is_inf() || (bx < 0L) != (by < 0L) {
    return false
  }
  let d = if bx > by { bx - by } else { by - bx }
  d <= golden_expr_shape_max_ulp
}

///|
fn golden_expr_shape_close32(x : Float, y : Float) -> Bool {
  if x.is_nan() || y.is_nan() {
    return x.is_nan() && y.is_nan()
  }
  let bx = x.reinterpret_as_int().to_int64()
  let by = y.reinterpret_as_int().to_int64()
  if bx == by {
    return true
  }
  if x.is_inf() || y.is_inf() || (bx < 0L) != (by < 0L) {
    return false
  }
  let d = if bx > by { bx - by } else { by - bx }
  d <= golden_expr_shape_max_ulp
}

///|
/// `golden_same`, but a float column may differ in the last bits.
fn golden_expr_shape_series_close(a : @pl.Series, b : @pl.Series) -> Bool {
  if a.dtype() != b.dtype() || a.len() != b.len() || a.name() != b.name() {
    return false
  }
  match a.dtype() {
    Float64 => {
      let xs = a.to_float64_array() catch { _ => return false }
      let ys = b.to_float64_array() catch { _ => return false }
      for i in 0..<xs.length() {
        match (xs[i], ys[i]) {
          (None, None) => ()
          (Some(x), Some(y)) =>
            if !golden_expr_shape_close64(x, y) {
              return false
            }
          _ => return false
        }
      }
      true
    }
    Float32 => {
      let xs = a.to_float32_array() catch { _ => return false }
      let ys = b.to_float32_array() catch { _ => return false }
      for i in 0..<xs.length() {
        match (xs[i], ys[i]) {
          (None, None) => ()
          (Some(x), Some(y)) =>
            if !golden_expr_shape_close32(x, y) {
              return false
            }
          _ => return false
        }
      }
      true
    }
    _ => golden_same(a, b)
  }
}

///|
fn golden_expr_shape_frame_close(a : @pl.DataFrame, b : @pl.DataFrame) -> Bool {
  if a.shape() != b.shape() ||
    a.columns() != b.columns() ||
    a.dtypes() != b.dtypes() {
    return false
  }
  let xs = a.get_columns()
  let ys = b.get_columns()
  for i in 0..<xs.length() {
    if !golden_expr_shape_series_close(xs[i], ys[i]) {
      return false
    }
  }
  true
}

///|
/// Sorting, truncating, filtering and combining expressions against polars
/// 2.1.0 (`select` and `with_columns`): `sort`, `arg_sort`, `sort_by`, `head`,
/// `tail`, `slice`, `unique`, `drop_nulls`, `filter`, `any`, `all`, the
/// trigonometric functions and `sum_horizontal` / `min_horizontal` /
/// `max_horizontal`, with the results of different lengths a `select` and a
/// `with_columns` can be given. Same format as the T7 data set (see
/// `expr_golden_test.mbt`). A `known_diff` case carries the library's result,
/// not polars' (see docs/golden/known-diffs/expr_shape.md); a case with `ulp`
/// holds a trigonometric function and may differ in the last bits. Every case
/// also pins `to_string()` of its expressions to polars' `str(expr)`.
test "sort, filter, shape, trig and horizontal expressions match the polars golden data" {
  guard @json.parse(golden_expr_shape) is Object(doc) else {
    fail("golden_expr_shape is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("tables") is Some(Object(tables_json)) else {
    fail("no tables")
  }
  let tables : Map[String, @pl.DataFrame] = Map([])
  for name, j in tables_json {
    tables[name] = golden_expr_frame(j)
  }
  let exprs = golden_expr_shape_cases()
  assert_eq(cases.length(), golden_expr_shape_count)
  assert_eq(exprs.length(), golden_expr_shape_count)
  let failures : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  let mut errors = 0
  let mut values = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    seen[id] = true
    guard exprs.get(id) is Some(es) else {
      failures.push("[\{id}] no expressions in expr_shape_cases_test.mbt")
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
        let close = obj.get("ulp") is Some(True)
        match outcome {
          Err(e) => failures.push("\{label}: unexpected error \{e}")
          Ok(actual) => {
            let same = if close {
              golden_expr_shape_frame_close(actual, expected)
            } else {
              golden_frame_same(actual, expected)
            }
            if !same {
              failures.push(
                "\{label}: expected \{golden_frame_describe(expected)}, got \{golden_frame_describe(actual)}",
              )
            }
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
  assert_eq(errors + values, golden_expr_shape_count)
}

///|
/// Calls the `Series` method of a `series_cases` entry; the result is a
/// `Series` or a `Bool?` (`Series::any` and `all` may give null).
enum GoldenShapeOut {
  Ser(@pl.Series)
  Flag(Bool?)
}

///|
fn golden_expr_shape_call(
  s : @pl.Series,
  method : String,
  args : Map[String, @json.Json],
) -> GoldenShapeOut raise @pl.PolarsError {
  let flag = (key : String) => {
    match args.get(key) {
      Some(True) => true
      _ => false
    }
  }
  let int = (key : String) => {
    match args.get(key) {
      Some(Number(n, ..)) => n.to_int()
      _ => 0
    }
  }
  match method {
    "is_sorted" =>
      Flag(
        Some(
          s.is_sorted(
            descending=flag("descending"),
            nulls_last=flag("nulls_last"),
          ),
        ),
      )
    "any" => Flag(s.any(ignore_nulls=flag("ignore_nulls")))
    "all" => Flag(s.all(ignore_nulls=flag("ignore_nulls")))
    "gather_every" => Ser(s.gather_every(int("n"), offset=int("offset")))
    "sin" => Ser(s.sin())
    "cos" => Ser(s.cos())
    "tan" => Ser(s.tan())
    "arcsin" => Ser(s.arcsin())
    "arccos" => Ser(s.arccos())
    "arctan" => Ser(s.arctan())
    _ => abort("golden: unknown Series method \{method}")
  }
}

///|
/// `Series::is_sorted`, `any`, `all`, `gather_every` and the trigonometric
/// methods against polars 2.1.0.
test "Series methods of the shape data set match the polars golden data" {
  guard @json.parse(golden_expr_shape) is Object(doc) else {
    fail("golden_expr_shape is not a JSON object")
  }
  guard doc.get("series_cases") is Some(Array(cases)) else {
    fail("no series_cases")
  }
  guard doc.get("inputs") is Some(Object(inputs_json)) else {
    fail("no inputs")
  }
  assert_eq(cases.length(), golden_expr_shape_series_count)
  let failures : Array[String] = []
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("polars") is Some(String(polars)) else {
      fail("\{id}: no polars spelling")
    }
    guard obj.get("input") is Some(String(key)) else { fail("\{id}: no input") }
    guard inputs_json.get(key) is Some(input_json) else {
      fail("\{id}: unknown input \{key}")
    }
    guard obj.get("method") is Some(String(method)) else {
      fail("\{id}: no method")
    }
    guard obj.get("args") is Some(Object(args)) else { fail("\{id}: no args") }
    let s = golden_series(input_json)
    let label = "[\{id}] \{polars}"
    let outcome : Result[GoldenShapeOut, @pl.PolarsError] = Ok(
      golden_expr_shape_call(s, method, args),
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
            if k != kind || m != message {
              failures.push("\{label}: expected \{kind}(\{message}), got \{e}")
            }
          }
          Ok(_) => failures.push("\{label}: expected \{kind}(\{message})")
        }
      }
      _ => {
        guard obj.get("result") is Some(Object(result)) else {
          fail("\{id}: neither result nor error")
        }
        match (outcome, result.get("series"), result.get("bool")) {
          (Err(e), _, _) => failures.push("\{label}: unexpected error \{e}")
          (Ok(Ser(actual)), Some(sj), _) => {
            let expected = golden_series(sj)
            let same = if obj.get("ulp") is Some(True) {
              golden_expr_shape_series_close(actual, expected)
            } else {
              golden_same(actual, expected)
            }
            if !same {
              failures.push(
                "\{label}: expected \{golden_describe(expected)}, got \{golden_describe(actual)}",
              )
            }
          }
          (Ok(Flag(actual)), _, Some(bj)) => {
            let expected : Bool? = match bj {
              True => Some(true)
              False => Some(false)
              _ => None
            }
            if actual != expected {
              failures.push(
                "\{label}: expected \{@debug.to_string(expected)}, got \{@debug.to_string(actual)}",
              )
            }
          }
          _ => failures.push("\{label}: result kind does not match the method")
        }
      }
    }
  }
  if failures.length() > 0 {
    let shown = if failures.length() > 60 {
      failures[:60].to_owned()
    } else {
      failures
    }
    fail(
      "\{failures.length()} of \{cases.length()} series cases failed:\n" +
      shown.join("\n"),
    )
  }
}

///|
/// `DataFrame::gather_every` against `df.gather_every(n, offset)` of polars
/// 2.1.0.
test "DataFrame::gather_every matches the polars golden data" {
  guard @json.parse(golden_expr_shape) is Object(doc) else {
    fail("golden_expr_shape is not a JSON object")
  }
  guard doc.get("frame_cases") is Some(Array(cases)) else {
    fail("no frame_cases")
  }
  guard doc.get("tables") is Some(Object(tables_json)) else {
    fail("no tables")
  }
  assert_eq(cases.length(), golden_expr_shape_frame_count)
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
    let n = match obj.get("n") {
      Some(Number(v, ..)) => v.to_int()
      _ => fail("\{id}: no n")
    }
    let offset = match obj.get("offset") {
      Some(Number(v, ..)) => v.to_int()
      _ => fail("\{id}: no offset")
    }
    let polars = match obj.get("polars") {
      Some(String(p)) => p
      _ => fail("\{id}: no polars spelling")
    }
    let label = "[\{id}] \{polars}"
    let outcome : Result[@pl.DataFrame, @pl.PolarsError] = Ok(
      df.gather_every(n, offset~),
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
      _ => {
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
    fail(
      "\{failures.length()} of \{cases.length()} frame cases failed:\n" +
      failures.join("\n"),
    )
  }
}
