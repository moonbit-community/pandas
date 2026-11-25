///|
/// Number of cases of `docs/golden/csv_write.json`.
let golden_csv_write_count : Int32 = 165

///|
/// The single character of a golden option string.
fn golden_char(s : String, what : String) -> Char raise {
  let chars = s.to_array()
  if chars.length() != 1 {
    fail(
      "csv_write: option \{what} is not one character: \{@debug.to_string(s)}",
    )
  }
  chars[0]
}

///|
/// The write options of a golden case; `null` means the default.
fn golden_csv_options(
  opts : Map[String, @json.Json],
) -> @pl.CsvWriteOptions raise {
  let mut include_header = true
  let mut separator = ','
  let mut line_terminator = "\n"
  let mut quote_char = '"'
  let mut quote_style : @pl.QuoteStyle = Necessary
  let mut null_value = ""
  let mut include_bom = false
  for key, value in opts {
    match (key, value) {
      (_, Null) => ()
      ("include_header", True) => include_header = true
      ("include_header", False) => include_header = false
      ("include_bom", True) => include_bom = true
      ("include_bom", False) => include_bom = false
      ("separator", String(s)) => separator = golden_char(s, key)
      ("quote_char", String(s)) => quote_char = golden_char(s, key)
      ("line_terminator", String(s)) => line_terminator = s
      ("null_value", String(s)) => null_value = s
      ("quote_style", String(s)) =>
        quote_style = match s {
          "necessary" => Necessary
          "always" => Always
          "non_numeric" => NonNumeric
          "never" => Never
          _ => fail("csv_write: unknown quote_style \{s}")
        }
      _ => fail("csv_write: unknown option \{key}")
    }
  }
  @pl.CsvWriteOptions::new(
    include_header~,
    separator~,
    line_terminator~,
    quote_char~,
    quote_style~,
    null_value~,
    include_bom~,
  )
}

///|
/// `write_csv_str` against polars' `DataFrame.write_csv()`: the text of every
/// frame and option combination (see `docs/golden/scripts/csv_write.py`). The
/// `restricted` cases are options polars accepts and the library rejects with
/// `InvalidOperation`.
test "write_csv_str matches polars write_csv" {
  let root = @json.parse(golden_csv_write)
  guard root is Object(top) else { fail("csv_write: expected an object") }
  guard top.get("cases") is Some(Array(cases)) else {
    fail("csv_write: missing cases")
  }
  assert_eq(cases.length(), golden_csv_write_count)
  let failures : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  let mut errors = 0
  let mut texts = 0
  for c in cases {
    guard c is Object(obj) else { fail("csv_write: case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("csv_write: no id") }
    if seen.contains(id) {
      fail("duplicate case id \{id}")
    }
    seen[id] = true
    guard obj.get("polars") is Some(String(polars)) && polars != "" else {
      fail("\{id}: no polars annotation")
    }
    guard obj.get("frame") is Some(Array(specs)) else {
      fail("\{id}: no frame")
    }
    guard obj.get("options") is Some(Object(opts)) else {
      fail("\{id}: no options")
    }
    let series : Array[@pl.Series] = []
    for spec in specs {
      series.push(golden_series(spec))
    }
    let df = @pl.DataFrame::new(series)
    let options = golden_csv_options(opts)
    let outcome : Result[String, @pl.PolarsError] = Ok(
      @pl.write_csv_str(df, options~),
    ) catch {
      e => Err(e)
    }
    match obj.get("error") {
      Some(String(kind)) => {
        errors += 1
        guard kind == "InvalidOperation" && obj.get("restricted") is Some(True) else {
          fail("\{id}: unexpected error kind \{kind}")
        }
        match outcome {
          Ok(text) =>
            failures.push(
              "\{id}: expected InvalidOperation, got \{@debug.to_string(text)}",
            )
          Err(@pl.InvalidOperation(_)) => ()
          Err(e) => failures.push("\{id}: expected InvalidOperation, got \{e}")
        }
      }
      _ => {
        texts += 1
        guard obj.get("output") is Some(String(expected)) else {
          fail("\{id}: no output")
        }
        match outcome {
          Ok(text) =>
            if text != expected {
              failures.push(
                "\{id}: expected \{@debug.to_string(expected)}, got \{@debug.to_string(text)}",
              )
            }
          Err(e) => failures.push("\{id}: expected text, got \{e}")
        }
      }
    }
  }
  assert_eq(errors, 8)
  assert_eq(texts + errors, golden_csv_write_count)
  if failures.length() > 0 {
    fail(
      "\{failures.length()} of \{cases.length()} cases failed:\n" +
      failures.join("\n"),
    )
  }
}
