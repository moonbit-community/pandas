///|
/// Number of cases `docs/golden/scripts/reshape.py` writes (polars 2.1.0).
let golden_reshape_count : Int32 = 715

///|
fn golden_reshape_strings(j : @json.Json?) -> Array[String]? {
  match j {
    None | Some(Null) => None
    Some(Array(items)) =>
      Some(
        items.map(x => {
          match x {
            String(s) => s
            _ => abort("golden reshape: a name is not text")
          }
        }),
      )
    Some(_) => abort("golden reshape: expected a list of names")
  }
}

///|
fn golden_reshape_string(j : @json.Json?) -> String? {
  match j {
    None | Some(Null) => None
    Some(String(s)) => Some(s)
    Some(_) => abort("golden reshape: expected text")
  }
}

///|
fn golden_reshape_bool(j : @json.Json?) -> Bool {
  j is Some(True)
}

///|
fn golden_pivot_agg(name : String) -> @pl.PivotAgg {
  match name {
    "first" => First
    "last" => Last
    "sum" => Sum
    "min" => Min
    "max" => Max
    "mean" => Mean
    "median" => Median
    "len" => Len
    _ => abort("golden reshape: unknown aggregate_function \{name}")
  }
}

///|
/// Runs the operation of a case on its table.
fn golden_reshape_run(
  op : String,
  df : @pl.DataFrame,
  args : Map[String, @json.Json],
) -> @pl.DataFrame raise @pl.PolarsError {
  match op {
    "value_counts" => {
      guard args.get("column") is Some(String(col)) else {
        abort("value_counts: no column")
      }
      let s = df.column(col)
      let sort = golden_reshape_bool(args.get("sort"))
      let normalize = golden_reshape_bool(args.get("normalize"))
      let name = golden_reshape_string(args.get("name"))
      s.value_counts(sort~, normalize~, name?)
    }
    "unique_counts" => {
      guard args.get("column") is Some(String(col)) else {
        abort("unique_counts: no column")
      }
      df.column(col).unique_counts().to_frame()
    }
    "pivot" => {
      let on = match golden_reshape_strings(args.get("on")) {
        Some(on) => on
        None => abort("pivot: no on")
      }
      let index = golden_reshape_strings(args.get("index"))
      let values = golden_reshape_strings(args.get("values"))
      let aggregate_function = match golden_reshape_string(args.get("agg")) {
        Some(a) => Some(golden_pivot_agg(a))
        None => None
      }
      let sort_columns = golden_reshape_bool(args.get("sort_columns"))
      match golden_reshape_string(args.get("separator")) {
        Some(separator) =>
          df.pivot(
            on,
            index?,
            values?,
            aggregate_function?,
            sort_columns~,
            separator~,
          )
        None =>
          df.pivot(on, index?, values?, aggregate_function?, sort_columns~)
      }
    }
    "unpivot" => {
      let on = golden_reshape_strings(args.get("on"))
      let index = match golden_reshape_strings(args.get("index")) {
        Some(i) => i
        None => []
      }
      let variable_name = golden_reshape_string(args.get("variable_name"))
      let value_name = golden_reshape_string(args.get("value_name"))
      df.unpivot(on?, index~, variable_name?, value_name?)
    }
    "transpose" => {
      let include_header = golden_reshape_bool(args.get("include_header"))
      let column_names = golden_reshape_strings(args.get("column_names"))
      match golden_reshape_string(args.get("header_name")) {
        Some(header_name) =>
          df.transpose(include_header~, header_name~, column_names?)
        None => df.transpose(include_header~, column_names?)
      }
    }
    "to_dict" => {
      let d = df.to_dict()
      let names : Array[String] = []
      let cols : Array[@pl.Series] = []
      for k, s in d {
        names.push(k)
        cols.push(s)
      }
      if names != df.columns() {
        abort("to_dict: the keys are not the column names in order")
      }
      @pl.DataFrame::new(cols)
    }
    _ => abort("golden reshape: unknown op \{op}")
  }
}

///|
/// `value_counts`, `unique_counts`, `pivot`, `unpivot`, `transpose` and
/// `to_dict` against polars 2.1.0. A case carries its result as a frame
/// (`result`), as an error (`error` and `message`) or as `restricted` (the
/// library is stricter than polars: only `InvalidOperation`). A `known_diff`
/// case carries the library's result. The rows of `value_counts` and
/// `unique_counts` cases are in the order the library promises. See
/// docs/golden/known-diffs/reshape.md.
test "reshaping matches the polars golden data" {
  guard @json.parse(golden_reshape) is Object(doc) else {
    fail("golden_reshape is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("tables") is Some(Object(tables_json)) else {
    fail("no tables")
  }
  let tables : Map[String, @pl.DataFrame] = Map([])
  for name, j in tables_json {
    tables[name] = golden_expr_frame(j)
  }
  assert_eq(cases.length(), golden_reshape_count)
  let failures : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  let mut restricted = 0
  let mut errors = 0
  let mut values = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard !seen.contains(id) else { fail("\{id}: duplicate id") }
    seen[id] = true
    guard obj.get("polars") is Some(String(polars)) else {
      fail("\{id}: no polars spelling")
    }
    guard obj.get("op") is Some(String(op)) else { fail("\{id}: no op") }
    guard obj.get("table") is Some(String(table_name)) else {
      fail("\{id}: no table")
    }
    guard obj.get("args") is Some(Object(args)) else { fail("\{id}: no args") }
    guard tables.get(table_name) is Some(df) else {
      fail("\{id}: unknown table \{table_name}")
    }
    let label = "[\{id}] \{polars}"
    let outcome : Result[@pl.DataFrame, @pl.PolarsError] = Ok(
      golden_reshape_run(op, df, args),
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
            "\{label}: expected InvalidOperation, got \{golden_frame_describe(r)}",
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
              "\{label}: expected \{kind}(\{message}), got \{golden_frame_describe(r)}",
            )
        }
      }
      Some(_) => fail("\{id}: error kind is not a string")
      None => {
        values += 1
        guard obj.get("result") is Some(r) else {
          fail("\{id}: neither result, error nor restricted")
        }
        let expected = golden_expr_frame(r)
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
  assert_eq(restricted + errors + values, golden_reshape_count)
}
