///|
/// Number of cases `docs/golden/scripts/join.py` writes (polars 2.1.0).
let golden_join_count : Int32 = 793

///|
fn golden_join_str_list(j : @json.Json) -> Array[String] raise {
  guard j is Array(items) else { fail("golden join: expected a list of names") }
  items.map(item => {
    match item {
      String(s) => s
      _ => fail("golden join: a name is not a string")
    }
  })
}

///|
fn golden_join_int(j : @json.Json) -> Int64 raise {
  match j {
    Number(d, ..) => d.to_int64()
    _ => fail("golden join: expected a number")
  }
}

///|
/// The key expression of its JSON encoding (see docs/golden/scripts/join.py).
fn golden_join_key(j : @json.Json) -> @pl.Expr raise {
  match j {
    String(name) => @pl.col(name)
    Object(obj) => {
      let entries : Array[(String, @json.Json)] = []
      for k, v in obj {
        entries.push((k, v))
      }
      guard entries.length() == 1 else {
        fail("golden join: a key expression has one operation")
      }
      let (op, v) = entries[0]
      let pair = () => {
        guard v is Array(items) && items.length() == 2 else {
          fail("golden join: \{op} takes two operands")
        }
        (items[0], items[1])
      }
      match op {
        "cols" => @pl.cols(golden_join_str_list(v))
        "all" => @pl.all()
        "rem" => {
          let (e, n) = pair()
          golden_join_key(e) % @pl.lit_int(golden_join_int(n))
        }
        "add" => {
          let (e, n) = pair()
          golden_join_key(e) + @pl.lit_int(golden_join_int(n))
        }
        "cast" => {
          let (e, t) = pair()
          guard t is String(name) else { fail("golden join: bad dtype") }
          golden_join_key(e).cast(golden_dtype(name))
        }
        "lit" => @pl.lit_int(golden_join_int(v))
        "alias" => {
          let (e, n) = pair()
          guard n is String(name) else { fail("golden join: bad alias") }
          golden_join_key(e).alias(name)
        }
        "fill_null" => {
          let (e, n) = pair()
          golden_join_key(e).fill_null(@pl.lit_int(golden_join_int(n)))
        }
        "cum_sum" => golden_join_key(v).cum_sum()
        "sum" => golden_join_key(v).sum()
        "len" => golden_join_key(v).len()
        "abs" => golden_join_key(v).abs()
        "is_null" => golden_join_key(v).is_null()
        _ => fail("golden join: unknown key operation \{op}")
      }
    }
    _ => fail("golden join: a key is a name or an object")
  }
}

///|
fn golden_join_keys(j : @json.Json?) -> Array[@pl.Expr]? raise {
  match j {
    None => None
    Some(Array(items)) => Some(items.map(golden_join_key))
    Some(_) => fail("golden join: keys are a list")
  }
}

///|
fn golden_join_how(name : String) -> @pl.JoinHow raise {
  match name {
    "inner" => Inner
    "left" => Left
    "right" => Right
    "full" => Full
    "semi" => Semi
    "anti" => Anti
    "cross" => Cross
    _ => fail("golden join: unknown how \{name}")
  }
}

///|
/// `DataFrame::join` against polars 2.1.0. A case carries the arguments that
/// were given and either the result frame or the error (`error`, `message`).
test "join matches the polars golden data" {
  guard @json.parse(golden_join) is Object(doc) else {
    fail("golden_join is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else { fail("no cases") }
  guard doc.get("tables") is Some(Object(tables_json)) else {
    fail("no tables")
  }
  let tables : Map[String, @pl.DataFrame] = Map([])
  for name, j in tables_json {
    tables[name] = golden_expr_frame(j)
  }
  assert_eq(cases.length(), golden_join_count)
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
    guard obj.get("left") is Some(String(left_name)) else {
      fail("\{id}: no left table")
    }
    guard obj.get("right") is Some(String(right_name)) else {
      fail("\{id}: no right table")
    }
    guard obj.get("how") is Some(String(how_name)) else {
      fail("\{id}: no how")
    }
    guard tables.get(left_name) is Some(left) else {
      fail("\{id}: unknown table \{left_name}")
    }
    guard tables.get(right_name) is Some(right) else {
      fail("\{id}: unknown table \{right_name}")
    }
    let how = golden_join_how(how_name)
    let on = golden_join_keys(obj.get("on"))
    let left_on = golden_join_keys(obj.get("left_on"))
    let right_on = golden_join_keys(obj.get("right_on"))
    let suffix = match obj.get("suffix") {
      Some(String(s)) => s
      _ => "_right"
    }
    let validate = match obj.get("validate") {
      Some(String("m:m")) | None => @pl.JoinValidation::ManyToMany
      Some(String("1:m")) => OneToMany
      Some(String("m:1")) => ManyToOne
      Some(String("1:1")) => OneToOne
      Some(_) => fail("\{id}: unknown validate")
    }
    let nulls_equal = obj.get("nulls_equal") is Some(True)
    let coalesce : Bool? = match obj.get("coalesce") {
      Some(True) => Some(true)
      Some(False) => Some(false)
      _ => None
    }
    let label = "[\{id}] \{polars}"
    let outcome : Result[@pl.DataFrame, @pl.PolarsError] = Ok(
      left.join(
        right,
        on?,
        left_on?,
        right_on?,
        how~,
        suffix~,
        validate~,
        nulls_equal~,
        coalesce?,
      ),
    ) catch {
      e => Err(e)
    }
    if obj.get("restricted") is Some(True) {
      // the library is stricter than polars (spec 5.5): only the variant
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
        // `message_differs`: the library words the error differently (see
        // docs/golden/known-diffs/join.md); the variant is compared
        let any_text = obj.get("message_differs") is Some(True)
        match outcome {
          Err(e) => {
            let (k, m) = golden_error_parts(e)
            if k != kind || (!any_text && m != message) {
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
          fail("\{id}: neither result nor error")
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
  assert_eq(restricted + errors + values, golden_join_count)
}
