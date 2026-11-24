///|
let all_types : Array[DataType] = [
  Boolean,
  Int32,
  Int64,
  Float32,
  Float64,
  String,
  Date,
  Datetime,
  Null,
]

///|
/// The type with the display name `name` (`DataType`'s `Show` text).
fn supertype_dtype(name : String) -> DataType raise {
  for t in all_types {
    if t.to_string() == name {
      return t
    }
  }
  fail("supertype golden data: unknown type \{name}")
}

///|
fn supertype_text(a : DataType, b : DataType) -> String {
  match supertype(a, b) {
    Some(t) => t.to_string()
    None => "-"
  }
}

///|
/// `supertype` of all 81 pairs against polars 2.1.0's supertype of two
/// columns (`pl.concat(..., how="vertical_relaxed")`, data from
/// `docs/golden/scripts/supertype.py`). A pair polars refuses is `-`. One
/// difference is deliberate (the golden case is `restricted`): `str` with a
/// number is `-` here (polars says `str`, but both comparison and arithmetic
/// reject that pair).
test "supertype matches the polars table for all 81 pairs" {
  guard @json.parse(golden_supertype) is Object(doc) else {
    fail("golden_supertype is not a JSON object")
  }
  guard doc.get("cases") is Some(Array(cases)) else {
    fail("golden_supertype has no cases")
  }
  assert_eq(cases.length(), 81)
  let mut restricted = 0
  for c in cases {
    guard c is Object(obj) else { fail("case is not an object") }
    guard obj.get("id") is Some(String(id)) else { fail("case without id") }
    guard obj.get("a") is Some(String(a)) else { fail("\{id}: no a") }
    guard obj.get("b") is Some(String(b)) else { fail("\{id}: no b") }
    let expected = if obj.get("restricted") is Some(True) {
      restricted += 1
      "-"
    } else {
      match obj.get("result") {
        Some(String(r)) => r
        Some(Null) => "-"
        _ => fail("\{id}: no result")
      }
    }
    assert_eq(
      supertype_text(supertype_dtype(a), supertype_dtype(b)),
      expected,
      msg=id,
    )
  }
  assert_eq(restricted, 8)
}

///|
test "supertype is symmetric" {
  for a in all_types {
    for b in all_types {
      assert_eq(supertype(a, b), supertype(b, a))
    }
  }
}

///|
/// One non-null row per type; the values only have to be castable.
fn sample(t : DataType) -> Series {
  match t {
    Boolean => Series::bool("a", [true])
    Int32 => Series::int32("a", [1])
    Int64 => Series::int64("a", [1L])
    Float32 => Series::float32("a", [1.0])
    Float64 => Series::float64("a", [1.0])
    String => Series::str("a", ["a"])
    Date => Series::date("a", [1])
    Datetime => Series::datetime("a", [1L])
    Null => Series::null("a", 1)
  }
}

///|
fn[T] fails(f : () -> T raise PolarsError) -> Bool {
  try {
    ignore(f())
    false
  } catch {
    _ => true
  }
}

///|
test "supertype agrees with the comparison and arithmetic kernels" {
  for a in all_types {
    for b in all_types {
      let x = sample(a)
      let y = sample(b)
      // a pair has a supertype exactly when the comparison works
      assert_eq(!fails(() => x.eq(y)), supertype(a, b) is Some(_))
      // arithmetic on numbers (and Null) gives the supertype
      if (a.is_numeric() || a == Null) && (b.is_numeric() || b == Null) {
        assert_eq(Some(x.add(y).dtype()), supertype(a, b))
      }
    }
  }
}
