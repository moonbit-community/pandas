///|
/// Number of cases of `docs/golden/csv_read.json`.
let golden_csv_read_count : Int32 = 1538

///|
/// The `CsvReadOptions` of a case's `options` object (absent keys are the
/// defaults; `quote_char` and `infer_schema_length` may be `null`).
fn csv_golden_options(
  id : String,
  opts : Map[String, @json.Json],
) -> @pl.CsvReadOptions raise {
  let mut separator = ','
  let mut has_header = true
  let mut quote_char : Char? = Some('"')
  let null_values : Array[String] = []
  let overrides : Map[String, @pl.DataType] = Map([])
  let mut isl : Int32? = Some(100)
  let mut n_rows : Int32? = None
  let mut skip_rows = 0
  let mut dates = false
  for key, v in opts {
    match (key, v) {
      ("separator", String(s)) => separator = s[0].to_int().unsafe_to_char()
      ("has_header", False) => has_header = false
      ("has_header", True) => has_header = true
      ("quote_char", Null) => quote_char = None
      ("quote_char", String(s)) =>
        quote_char = Some(s[0].to_int().unsafe_to_char())
      ("null_values", Array(items)) =>
        for item in items {
          guard item is String(s) else { fail("\{id}: bad null_values") }
          null_values.push(s)
        }
      ("schema_overrides", Object(m)) =>
        for name, d in m {
          guard d is String(dn) else { fail("\{id}: bad override") }
          overrides[name] = golden_dtype(dn)
        }
      ("infer_schema_length", Null) => isl = None
      ("infer_schema_length", Number(x, ..)) => isl = Some(x.to_int())
      ("n_rows", Number(x, ..)) => n_rows = Some(x.to_int())
      ("skip_rows", Number(x, ..)) => skip_rows = x.to_int()
      ("try_parse_dates", True) => dates = true
      ("try_parse_dates", False) => dates = false
      _ => fail("\{id}: unknown option \{key}")
    }
  }
  match n_rows {
    Some(n) =>
      @pl.CsvReadOptions::new(
        separator~,
        has_header~,
        quote_char~,
        null_values~,
        schema_overrides=overrides,
        infer_schema_length=isl,
        n_rows=n,
        skip_rows~,
        try_parse_dates=dates,
      )
    None =>
      @pl.CsvReadOptions::new(
        separator~,
        has_header~,
        quote_char~,
        null_values~,
        schema_overrides=overrides,
        infer_schema_length=isl,
        skip_rows~,
        try_parse_dates=dates,
      )
  }
}

///|
/// `read_csv_str` against `pl.read_csv` on the same text: every case of
/// `docs/golden/csv_read.json` gives a frame (column names, types and values),
/// or an error with its variant and message (see
/// `docs/golden/scripts/csv_read.py`; the `restricted` cases are the ones where
/// polars raises `ComputeError` / `NoDataError` and the library `ParseError`
/// with ` at line N`, or reads a type the library has not).
test "read_csv_str matches polars" {
  let root = @json.parse(golden_csv_read)
  guard root is Object(top) else { fail("csv_read: expected an object") }
  guard top.get("cases") is Some(Array(cases)) else {
    fail("csv_read: missing cases")
  }
  assert_eq(cases.length(), golden_csv_read_count)
  let failures : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  let mut errors = 0
  let mut frames = 0
  let mut restricted = 0
  for c in cases {
    guard c is Object(obj) else { fail("csv_read: case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("csv_read: no id") }
    if seen.contains(id) {
      fail("duplicate case id \{id}")
    }
    seen[id] = true
    guard obj.get("polars") is Some(String(polars)) && polars != "" else {
      fail("\{id}: no polars annotation")
    }
    guard obj.get("input") is Some(String(input)) else {
      fail("\{id}: no input")
    }
    guard obj.get("options") is Some(Object(opts)) else {
      fail("\{id}: no options")
    }
    if obj.get("restricted") is Some(True) {
      restricted += 1
    }
    let options = csv_golden_options(id, opts)
    let outcome : Result[@pl.DataFrame, @pl.PolarsError] = Ok(
      @pl.read_csv_str(input, options~),
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
          Ok(df) =>
            failures.push(
              "\{id}: expected \{kind}(\{message}), got a frame of \{df.height()} rows",
            )
          Err(e) => {
            let (k, m) = match e {
              @pl.ParseError(m) => ("ParseError", m)
              @pl.DuplicateColumn(m) => ("DuplicateColumn", m)
              @pl.ComputeError(m) => ("ComputeError", m)
              _ => ("other", "\{e}")
            }
            if k != kind || m != message {
              failures.push("\{id}: expected \{kind}(\{message}), got \{e}")
            }
          }
        }
      }
      _ => {
        frames += 1
        guard obj.get("columns") is Some(Array(specs)) else {
          fail("\{id}: no columns")
        }
        match outcome {
          Err(e) => failures.push("\{id}: expected a frame, got \{e}")
          Ok(df) => {
            let got = df.get_columns()
            if got.length() != specs.length() {
              failures.push(
                "\{id}: expected \{specs.length()} columns, got \{got.length()}",
              )
              continue
            }
            for i in 0..<specs.length() {
              let want = golden_series(specs[i])
              if want.name() != got[i].name() ||
                want.dtype() != got[i].dtype() ||
                !golden_same(want, got[i]) {
                failures.push(
                  "\{id}: column \{i} expected \{want.name()}:\{want.dtype()}\{@debug.to_string(want.to_list())}, got \{got[i].name()}:\{got[i].dtype()}\{@debug.to_string(got[i].to_list())}",
                )
              }
            }
          }
        }
      }
    }
  }
  assert_true(errors > 0)
  assert_true(frames > 0)
  assert_true(restricted > 0)
  if failures.length() > 0 {
    let shown = failures.length().min(40)
    fail(
      "\{failures.length()} of \{cases.length()} cases failed:\n" +
      failures[:shown].to_owned().join("\n"),
    )
  }
}
