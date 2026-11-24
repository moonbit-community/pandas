///|
/// Number of cases `docs/golden/scripts/str_dt.py` writes (576 for polars 2.1.0).
let golden_str_dt_count : Int32 = 576

///|
fn sd_double(text : String) -> Double raise {
  match text {
    "nan" => 0.0 / 0.0
    "inf" => 1.0 / 0.0
    "-inf" => -1.0 / 0.0
    _ => @string.parse_double(text)
  }
}

///|
fn[T] sd_conv(
  vals : Array[String?],
  f : (String) -> T raise,
) -> Array[T?] raise {
  let out : Array[T?] = []
  for v in vals {
    match v {
      None => out.push(None)
      Some(s) => out.push(Some(f(s)))
    }
  }
  out
}

///|
/// Rebuilds a `Series` from the golden-data encoding
/// `{"name": str, "dtype": "<display name>", "values": [...]}` (see
/// `docs/golden/scripts/emit.py`).
fn sd_series(j : @json.Json) -> Series raise {
  guard j is Object(obj) else { fail("golden series: expected an object") }
  guard obj.get("name") is Some(String(name)) else {
    fail("golden series: missing name")
  }
  guard obj.get("dtype") is Some(String(dtype)) else {
    fail("golden series: missing dtype")
  }
  guard obj.get("values") is Some(Array(items)) else {
    fail("golden series: missing values")
  }
  let vals : Array[String?] = []
  for item in items {
    match item {
      Null => vals.push(None)
      String(s) => vals.push(Some(s))
      _ => fail("golden series: unexpected value")
    }
  }
  match dtype {
    "bool" =>
      Series::bool_nullable(
        name,
        sd_conv(vals, s => {
          match s {
            "true" => true
            "false" => false
            _ => fail("golden series: bad bool \{s}")
          }
        }),
      )
    "i32" =>
      Series::int32_nullable(name, sd_conv(vals, s => @string.parse_int(s)))
    "i64" =>
      Series::int64_nullable(name, sd_conv(vals, s => @string.parse_int64(s)))
    "f32" =>
      Series::float32_nullable(
        name,
        sd_conv(vals, s => Float::from_double(sd_double(s))),
      )
    "f64" => Series::float64_nullable(name, sd_conv(vals, sd_double))
    "str" => Series::str_nullable(name, vals)
    "date" =>
      Series::date_nullable(name, sd_conv(vals, s => @string.parse_int(s)))
    "datetime[μs]" =>
      Series::datetime_nullable(
        name,
        sd_conv(vals, s => @string.parse_int64(s)),
      )
    "null" => Series::null(name, vals.length())
    _ => fail("golden series: unknown dtype \{dtype}")
  }
}

///|
fn sd_error_parts(e : PolarsError) -> (String, String) {
  match e {
    ColumnNotFound(m) => ("ColumnNotFound", m)
    DuplicateColumn(m) => ("DuplicateColumn", m)
    SchemaMismatch(m) => ("SchemaMismatch", m)
    ShapeMismatch(m) => ("ShapeMismatch", m)
    OutOfBounds(m) => ("OutOfBounds", m)
    InvalidOperation(m) => ("InvalidOperation", m)
    ComputeError(m) => ("ComputeError", m)
    ParseError(m) => ("ParseError", m)
  }
}

///|
fn sd_field(name : String) -> DtField raise {
  match name {
    "year" => Year
    "month" => Month
    "day" => Day
    "weekday" => Weekday
    "ordinal_day" => OrdinalDay
    "hour" => Hour
    "minute" => Minute
    "second" => Second
    _ => fail("golden str_dt: unknown field \{name}")
  }
}

///|
fn sd_side(name : String) -> StripSide raise {
  match name {
    "both" => Both
    "start" => Start
    "end" => End
    _ => fail("golden str_dt: unknown side \{name}")
  }
}

///|
fn sd_str_arg(obj : Map[String, @json.Json], key : String) -> String raise {
  match obj.get(key) {
    Some(String(v)) => v
    _ => fail("golden str_dt: missing string argument \{key}")
  }
}

///|
fn sd_bool_arg(obj : Map[String, @json.Json], key : String) -> Bool raise {
  match obj.get(key) {
    Some(True) => true
    Some(False) => false
    _ => fail("golden str_dt: missing boolean argument \{key}")
  }
}

///|
/// The operation a golden case names, as a function of the input series (the
/// arguments are read here, so a malformed case fails the test, while the
/// function itself only raises `PolarsError`).
fn sd_plan(
  obj : Map[String, @json.Json],
  op : String,
) -> ((Series) -> Series raise PolarsError) raise {
  match op {
    "contains" => {
      let pattern = sd_str_arg(obj, "pattern")
      let literal = sd_bool_arg(obj, "literal")
      a => str_contains(a, pattern, literal)
    }
    "starts_with" => {
      let prefix = sd_str_arg(obj, "prefix")
      a => str_starts_with(a, prefix)
    }
    "ends_with" => {
      let suffix = sd_str_arg(obj, "suffix")
      a => str_ends_with(a, suffix)
    }
    "lower" => a => str_to_lowercase(a)
    "upper" => a => str_to_uppercase(a)
    "len_chars" => a => str_len_chars(a)
    "len_bytes" => a => str_len_bytes(a)
    "replace" => {
      let pattern = sd_str_arg(obj, "pattern")
      let value = sd_str_arg(obj, "value")
      let literal = sd_bool_arg(obj, "literal")
      let all = sd_bool_arg(obj, "all")
      a => str_replace(a, pattern, value, literal, all)
    }
    "strip" => {
      let chars = match obj.get("chars") {
        Some(String(c)) => Some(c)
        _ => None
      }
      let side = sd_side(sd_str_arg(obj, "side"))
      a => str_strip_chars(a, chars, side)
    }
    "dt" => {
      let field = sd_field(sd_str_arg(obj, "field"))
      a => dt_field(a, field)
    }
    _ => fail("golden str_dt: unknown operation \{op}")
  }
}

///|
/// `Series::equals` plus the sign of zero is of no concern here: the results are
/// Boolean, Int32, Int64 and String columns.
fn sd_same(actual : Series, expected : Series) -> Bool {
  actual.name() == expected.name() &&
  actual.dtype() == expected.dtype() &&
  actual.equals(expected)
}

///|
/// The `str` and `dt` kernels against polars 2.1.0. A case with `skip` is a
/// documented difference (docs/golden/known-diffs/regex.md): the test checks
/// that the library still answers differently from polars, so that a change in
/// core's regex engine is noticed.
test "str and dt kernels match the polars golden data" {
  guard @json.parse(golden_str_dt) is Object(doc) else {
    fail("golden_str_dt is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("inputs") is Some(Object(inputs)) else { fail("no inputs") }
  assert_eq(cases.length(), golden_str_dt_count)
  let failures : Array[String] = []
  let ids : Map[String, Bool] = Map([])
  let mut errors = 0
  let mut values = 0
  let mut skipped = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("op") is Some(String(op)) else { fail("\{id}: no op") }
    guard obj.get("a") is Some(String(a_key)) else { fail("\{id}: no a") }
    guard inputs.get(a_key) is Some(input) else { fail("\{id}: no input") }
    if ids.contains(id) {
      fail("duplicate case id \{id}")
    }
    ids[id] = true
    let a = sd_series(input)
    let plan = sd_plan(obj, op)
    let outcome : Result[Series, PolarsError] = Ok(plan(a)) catch {
      e => Err(e)
    }
    // does the outcome equal what polars gave?
    let matches = match obj.get("error") {
      Some(String(kind)) => {
        errors += 1
        guard obj.get("message") is Some(String(message)) else {
          fail("\{id}: error case without message")
        }
        match outcome {
          Err(e) => {
            let (k, m) = sd_error_parts(e)
            if k == kind &&
              (
                m == message ||
                (
                  obj.get("polars_message") is Some(_) &&
                  m.has_prefix(message + ": ")
                )
              ) {
              None
            } else {
              Some("expected \{kind}(\{message}), got \{e}")
            }
          }
          Ok(_) => Some("expected \{kind}(\{message}), got a result")
        }
      }
      Some(_) => fail("\{id}: error kind is not a string")
      None => {
        values += 1
        guard obj.get("result") is Some(result_json) else {
          fail("\{id}: neither result nor error")
        }
        let expected = sd_series(result_json)
        match outcome {
          Err(e) => Some("unexpected error \{e}")
          Ok(actual) =>
            if sd_same(actual, expected) {
              None
            } else {
              Some(
                "expected \{expected.name()}:\{@debug.to_string(expected.to_list())}, got \{actual.name()}:\{@debug.to_string(actual.to_list())}",
              )
            }
        }
      }
    }
    if obj.get("skip") is Some(String(_)) {
      skipped += 1
      if matches is None {
        failures.push(
          "[\{id}] listed as a known difference but now agrees with polars",
        )
      }
    } else if matches is Some(why) {
      failures.push("[\{id}] \{why}")
    }
  }
  if failures.length() > 0 {
    let shown = failures[:if failures.length() < 30 {
        failures.length()
      } else {
        30
      }]
    fail(
      "\{failures.length()} of \{cases.length()} golden cases fail:\n" +
      shown.iter().fold(init="", (acc, f) => acc + f + "\n"),
    )
  }
  // the data really exercises results, errors and documented differences
  assert_true(values > 250)
  assert_true(errors > 150)
  assert_true(skipped == 48)
}
