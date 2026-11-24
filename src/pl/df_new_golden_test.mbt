///|
/// Number of cases of `docs/golden/df_new.json`.
let golden_df_new_count : Int32 = 853

///|
/// `DataFrame::new` against `pl.DataFrame([series, ...])`: the shape, or the
/// error variant and message, of every list of columns (see
/// `docs/golden/scripts/df_new.py`).
test "DataFrame::new matches polars on duplicate names and heights" {
  let root = @json.parse(golden_df_new)
  guard root is Object(top) else { fail("df_new: expected an object") }
  guard top.get("cases") is Some(Array(cases)) else {
    fail("df_new: missing cases")
  }
  assert_eq(cases.length(), golden_df_new_count)
  let failures : Array[String] = []
  let seen : Map[String, Bool] = Map([])
  let mut errors = 0
  for c in cases {
    guard c is Object(obj) else { fail("df_new: case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("df_new: no id") }
    if seen.contains(id) {
      fail("duplicate case id \{id}")
    }
    seen[id] = true
    guard obj.get("polars") is Some(String(polars)) && polars != "" else {
      fail("\{id}: no polars annotation")
    }
    guard obj.get("cols") is Some(Array(specs)) else { fail("\{id}: no cols") }
    let series : Array[@pl.Series] = []
    for spec in specs {
      guard spec is Array([String(name), Number(h, ..)]) else {
        fail("\{id}: bad column spec")
      }
      series.push(@pl.Series::int32(name, Array::makei(h.to_int(), i => i)))
    }
    let outcome : Result[@pl.DataFrame, @pl.PolarsError] = Ok(
      @pl.DataFrame::new(series),
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
              "\{id}: expected \{kind}, got (\{df.shape().0}, \{df.shape().1})",
            )
          Err(e) => {
            let (k, m) = match e {
              @pl.DuplicateColumn(m) => ("DuplicateColumn", m)
              @pl.ShapeMismatch(m) => ("ShapeMismatch", m)
              _ => ("other", "\{e}")
            }
            if k != kind || m != message {
              failures.push("\{id}: expected \{kind}(\{message}), got \{e}")
            }
          }
        }
      }
      _ => {
        guard obj.get("shape") is Some(Array([Number(h, ..), Number(w, ..)])) else {
          fail("\{id}: no shape")
        }
        match outcome {
          Ok(df) =>
            if df.shape() != (h.to_int(), w.to_int()) {
              failures.push(
                "\{id}: expected shape, got (\{df.shape().0}, \{df.shape().1})",
              )
            }
          Err(e) => failures.push("\{id}: expected a frame, got \{e}")
        }
      }
    }
  }
  assert_true(errors > 0)
  if failures.length() > 0 {
    fail(
      "\{failures.length()} of \{cases.length()} cases failed:\n" +
      failures.map(s => s).join("\n"),
    )
  }
}
