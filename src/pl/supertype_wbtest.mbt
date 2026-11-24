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
/// `supertype(row, column)` for the nine types, in the order of `all_types`;
/// `-` is `None`. It is polars 2.1.0's supertype
/// (`pl.concat(..., how="vertical_relaxed")`) with two differences: `str` with
/// a number is `None` here (polars says `str`, but both comparison and
/// arithmetic reject that pair).
let expected_supertypes : Array[Array[String]] = [
  ["bool", "i32", "i64", "f32", "f64", "str", "-", "-", "bool"],
  ["i32", "i32", "i64", "f64", "f64", "-", "i32", "i64", "i32"],
  ["i64", "i64", "i64", "f64", "f64", "-", "i64", "i64", "i64"],
  ["f32", "f64", "f64", "f32", "f64", "-", "f32", "f64", "f32"],
  ["f64", "f64", "f64", "f64", "f64", "-", "f64", "f64", "f64"],
  ["str", "-", "-", "-", "-", "str", "str", "str", "str"],
  ["-", "i32", "i64", "f32", "f64", "str", "date", "datetime[μs]", "date"],
  [
    "-", "i64", "i64", "f64", "f64", "str", "datetime[μs]", "datetime[μs]", "datetime[μs]",
  ],
  ["bool", "i32", "i64", "f32", "f64", "str", "date", "datetime[μs]", "null"],
]

///|
fn supertype_text(a : DataType, b : DataType) -> String {
  match supertype(a, b) {
    Some(t) => t.to_string()
    None => "-"
  }
}

///|
test "supertype matches the polars table for all 81 pairs" {
  for i, a in all_types {
    for j, b in all_types {
      assert_eq(supertype_text(a, b), expected_supertypes[i][j])
    }
  }
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
