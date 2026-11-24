///|
/// Number of cases `docs/golden/scripts/date_parse.py` writes for polars 2.1.0.
let golden_date_parse_count : Int32 = 1141

///|
fn dp_int(j : @json.Json) -> Int32 raise {
  match j {
    Number(d, ..) => d.to_int()
    _ => fail("date_parse golden: expected a number")
  }
}

///|
fn dp_ymd(
  target : String,
  a : Array[Int32],
) -> @pl.AnyValue raise @pl.PolarsError {
  if target == "date" {
    @pl.AnyValue::date_ymd(a[0], a[1], a[2])
  } else {
    @pl.AnyValue::datetime_ymd(
      a[0],
      a[1],
      a[2],
      hour=a[3],
      minute=a[4],
      second=a[5],
      microsecond=a[6],
    )
  }
}

///|
/// `ExprStr::to_date`, `ExprStr::to_datetime`, `date_ymd` and `datetime_ymd`
/// against polars 2.1.0 (`str.to_date`, `str.to_datetime`; see the header of
/// `docs/golden/scripts/date_parse.py`). Casts compare the whole series or the
/// variant and the first line of the message; the ymd cases compare the days
/// or microseconds, or the library's own error text.
test "string casts and date constructors match the golden data" {
  guard @json.parse(golden_date_parse) is Object(doc) else {
    fail("golden_date_parse is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else {
    fail("golden_date_parse has no cases")
  }
  assert_eq(cases.length(), golden_date_parse_count)
  let failures : Array[String] = []
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("kind") is Some(String(kind)) else { fail("\{id}: no kind") }
    guard obj.get("target") is Some(String(target)) else {
      fail("\{id}: no target")
    }
    // the outcome of the library, as a series or an error
    let outcome : Result[@pl.Series, @pl.PolarsError] = match kind {
      "cast" => {
        guard obj.get("input") is Some(input) else { fail("\{id}: no input") }
        guard obj.get("strict") is Some(strict_json) else {
          fail("\{id}: no strict")
        }
        let strict = strict_json is True
        let e = if target == "date" {
          @pl.col("a").str().to_date(strict~)
        } else {
          @pl.col("a").str().to_datetime(strict~)
        }
        // `str(expr)` is polars' text
        if obj.get("str") is Some(String(text)) {
          if e.to_string() != text {
            failures.push("\{id}: str: expected \{text}, got \{e}")
          }
        }
        let src = golden_series(input)
        let df = @pl.DataFrame::new([src])
        match (Ok(df.select([e])) catch { err => Err(err) }) {
          Ok(out) => Ok(out.column("a"))
          Err(err) => Err(err)
        }
      }
      "ymd" => {
        guard obj.get("args") is Some(Array(args)) else {
          fail("\{id}: no args")
        }
        let a = args.map(x => dp_int(x))
        let r : Result[@pl.AnyValue, @pl.PolarsError] = Ok(dp_ymd(target, a)) catch {
          e => Err(e)
        }
        match r {
          Ok(Date(d)) => Ok(@pl.Series::date("v", [d]))
          Ok(Datetime(t)) => Ok(@pl.Series::datetime("v", [t]))
          Ok(_) => fail("\{id}: not a date")
          Err(e) => Err(e)
        }
      }
      _ => fail("\{id}: unknown kind \{kind}")
    }
    match obj.get("error") {
      Some(String(variant)) => {
        guard obj.get("message") is Some(String(message)) else {
          fail("\{id}: error case without message")
        }
        let (actual_variant, actual_message) = match outcome {
          Err(@pl.InvalidOperation(m)) => ("InvalidOperation", m)
          Err(@pl.ComputeError(m)) => ("ComputeError", m)
          Err(@pl.SchemaMismatch(m)) => ("SchemaMismatch", m)
          Err(e) => ("other: \{e}", "")
          Ok(_) => ("no error", "")
        }
        if actual_variant != variant || dp_first_line(actual_message) != message {
          failures.push(
            "\{id}: expected \{variant}(\{message}), got \{actual_variant}(\{actual_message})",
          )
        }
      }
      _ => {
        let expected = match kind {
          "cast" => {
            guard obj.get("result") is Some(r) else { fail("\{id}: no result") }
            golden_series(r)
          }
          _ => {
            guard obj.get("result") is Some(String(r)) else {
              fail("\{id}: no result")
            }
            if target == "date" {
              @pl.Series::date("v", [@string.parse_int(r)])
            } else {
              @pl.Series::datetime("v", [@string.parse_int64(r)])
            }
          }
        }
        match outcome {
          Err(e) => failures.push("\{id}: unexpected error \{e}")
          Ok(actual) =>
            if !golden_same(actual, expected) {
              failures.push(
                "\{id}: expected \{golden_describe(expected)}, got \{golden_describe(actual)}",
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
}

///|
/// The text up to the first line break: the golden data keeps the first line
/// of polars' message only (a failing text can hold a line break).
fn dp_first_line(m : String) -> String {
  for part in m.split("\n") {
    return part.to_owned()
  }
  ""
}
