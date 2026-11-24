// `DataFrame::describe`, following polars 2.1.0, where `describe` is Python
// code (`LazyFrame.describe`): the statistics are computed per column and
// then turned into numbers (numeric, Boolean and Null columns) or into
// Python `str` text (every other column). See docs/golden/concat_describe.json
// and docs/golden/known-diffs/concat_describe.md.

///|
/// Python's `repr` of a float in `[0, 1]` (`0.5`, `1.0`, `1e-07`).
fn desc_float_repr(x : Double) -> String {
  if x == 0.0 {
    return if x.reinterpret_as_int64() < 0L { "-0.0" } else { "0.0" }
  }
  let (digits, e) = float_digits(x.to_string())
  if e >= -4 && e < 16 {
    return format_float_text(x < 0.0, x.to_string(), -4, 16)
  }
  let rest = if digits.length() > 1 { "." + digits[1:].to_owned() } else { "" }
  let es = if e < 0 { "-" } else { "+" }
  let ea = if e < 0 { -e } else { e }
  (if x < 0.0 { "-" } else { "" }) +
  digits[:1].to_owned() +
  rest +
  "e" +
  es +
  pad_digits(ea, 2)
}

///|
/// Python's `f"{x:g}"` for a non-negative finite double: six significant
/// digits (rounded half to even on the exact value), trailing zeros removed,
/// `e-05` style exponents below `1e-4` and from `1e6`.
fn desc_g(x : Double) -> String {
  if x == 0.0 {
    return if x.reinterpret_as_int64() < 0L { "-0" } else { "0" }
  }
  let (d, point) = exact_decimal(x)
  let (r, carried) = round_digits(d, 6)
  let p = if carried { point + 1 } else { point }
  let digits : Array[Int32] = []
  for i in 0..<6 {
    if i < r.length() {
      digits.push(r[i])
    }
  }
  while digits.length() > 1 && digits[digits.length() - 1] == 0 {
    digits.pop() |> ignore
  }
  let e = p - 1
  let sb = StringBuilder()
  if e < -4 || e >= 6 {
    sb.write_string(digits[0].to_string())
    if digits.length() > 1 {
      sb.write_char('.')
      for i in 1..<digits.length() {
        sb.write_string(digits[i].to_string())
      }
    }
    sb.write_string(
      "e" +
      (if e < 0 { "-" } else { "+" }) +
      pad_digits(if e < 0 { -e } else { e }, 2),
    )
  } else if e >= 0 {
    for i in 0..<=e {
      sb.write_string(
        (if i < digits.length() { digits[i] } else { 0 }).to_string(),
      )
    }
    if digits.length() > e + 1 {
      sb.write_char('.')
      for i in (e + 1)..<digits.length() {
        sb.write_string(digits[i].to_string())
      }
    }
  } else {
    sb.write_string("0.")
    for _ in 0..<(-e - 1) {
      sb.write_char('0')
    }
    for dg in digits {
      sb.write_string(dg.to_string())
    }
  }
  sb.to_string()
}

///|
/// The row label of a percentile: `25%`, `33.3%`.
fn desc_label(p : Double) -> String {
  desc_g(p * 100.0) + "%"
}

///|
/// Python's `str(datetime)` of microseconds since the epoch: the fraction is
/// printed (six digits) only when it is not zero. Unlike `format_datetime`
/// this never gives up on a far date.
fn desc_datetime(us : Int64) -> String {
  let days = floor_div64(us, micros_per_day).to_int()
  let rem = floor_mod64(us, micros_per_day)
  let secs = (rem / 1_000_000L).to_int()
  let micro = (rem % 1_000_000L).to_int()
  format_date(days) +
  " " +
  pad_digits(secs / 3600, 2) +
  ":" +
  pad_digits(secs / 60 % 60, 2) +
  ":" +
  pad_digits(secs % 60, 2) +
  (if micro != 0 { "." + pad_digits(micro, 6) } else { "" })
}

///|
/// The number behind a statistic of a numeric or Boolean column; `None` for a
/// null.
fn desc_double(v : AnyValue) -> Double? {
  match v {
    Boolean(b) => Some(if b { 1.0 } else { 0.0 })
    Int32(x) => Some(x.to_double())
    Int64(x) => Some(x.to_double())
    Float32(x) => Some(x.to_double())
    Float64(x) => Some(x)
    _ => None
  }
}

///|
/// The text of a statistic of a String, Date or Datetime column; `None` for a
/// null.
fn desc_text(v : AnyValue) -> String? {
  match v {
    String(s) => Some(s)
    Date(d) => Some(format_date(d))
    Datetime(us) => Some(desc_datetime(us))
    _ => None
  }
}

///|
/// `describe` rows of a numeric, Boolean or `Null` column, as floats: count,
/// null_count, mean, std, min, the percentiles, max.
fn desc_float_rows(
  col : Column,
  qs : Array[Double],
  how : QuantileMethod,
) -> Array[Double?] raise PolarsError {
  let dt = col.dtype()
  let numeric = dt.is_numeric()
  let rows : Array[Double?] = []
  rows.push(Some((col.length() - col.null_count()).to_double()))
  rows.push(Some(col.null_count().to_double()))
  rows.push(
    if numeric || dt == Boolean {
      desc_double(agg_column(col, Mean).get(0))
    } else {
      None
    },
  )
  rows.push(
    if numeric {
      desc_double(agg_column(col, Std(1)).get(0))
    } else {
      None
    },
  )
  rows.push(
    if dt != Null {
      desc_double(agg_column(col, Min).get(0))
    } else {
      None
    },
  )
  // the values are sorted once for all the percentiles
  let quantiles = if numeric { agg_quantile_columns(col, qs, how) } else { [] }
  for k in 0..<qs.length() {
    rows.push(if numeric { desc_double(quantiles[k].get(0)) } else { None })
  }
  rows.push(
    if dt != Null {
      desc_double(agg_column(col, Max).get(0))
    } else {
      None
    },
  )
  rows
}

///|
/// The percentiles of a Date or Datetime column: the quantiles of the
/// underlying day or microsecond counts (sorted once for all of them), each
/// cut back to the type (`to_physical().quantile().cast(dtype)` in polars).
fn desc_temporal_quantiles(
  col : Column,
  qs : Array[Double],
  how : QuantileMethod,
) -> Array[AnyValue] raise PolarsError {
  let physical = match col {
    Date(a) => Column::Int32(a)
    Datetime(a) => Column::Int64(a)
    _ => abort("desc_temporal_quantiles: not a temporal column")
  }
  let out : Array[AnyValue] = []
  for c in agg_quantile_columns(physical, qs, how) {
    out.push(Series::make("q", c).cast(col.dtype()).col.get(0))
  }
  out
}

///|
/// `describe` rows of a String, Date or Datetime column, as text.
fn desc_text_rows(
  col : Column,
  qs : Array[Double],
  how : QuantileMethod,
) -> Array[String?] raise PolarsError {
  let dt = col.dtype()
  let temporal = dt == Date || dt == Datetime
  let rows : Array[String?] = []
  rows.push(Some((col.length() - col.null_count()).to_string()))
  rows.push(Some(col.null_count().to_string()))
  rows.push(
    if temporal {
      desc_text(agg_column(col, Mean).get(0))
    } else {
      None
    },
  )
  rows.push(None)
  rows.push(desc_text(agg_column(col, Min).get(0)))
  let quantiles = if temporal {
    desc_temporal_quantiles(col, qs, how)
  } else {
    []
  }
  for k in 0..<qs.length() {
    rows.push(if temporal { desc_text(quantiles[k]) } else { None })
  }
  rows.push(desc_text(agg_column(col, Max).get(0)))
  rows
}

///|
/// The percentiles in the order polars uses (ascending; the ones below 0.5
/// and the others are sorted separately, which comes to the same thing).
fn desc_sorted(percentiles : Array[Double]) -> Array[Double] {
  let out : Array[Double] = []
  for p in percentiles {
    // stable insertion: after every element that is not greater than p
    let mut at = out.length()
    while at > 0 && out[at - 1] > p {
      at -= 1
    }
    out.insert(at, p)
  }
  out
}

///|
/// Summary statistics of every column, one row per statistic: a first column
/// `statistic` holds the row labels `count`, `null_count`, `mean`, `std`,
/// `min`, one `<p*100>%` label per percentile (ascending, `25%`, `33.3%`; the
/// number has six significant digits at most) and `max`.
///
/// The type of a result column depends on the type of the source column, as
/// in polars 2.1.0:
/// - Numeric, `Boolean` and `Null` columns give `Float64`. `Boolean` counts as
///   0 and 1 and has no `std` or percentiles; `Null` has only `count` and
///   `null_count`. `count` is the number of non-null values.
/// - `String`, `Date` and `Datetime` columns give `String`: `count` and
///   `null_count` as digits, the other statistics as Python's `str` of the
///   value (`1970-01-06`, `2022-01-08 00:00:00`, a fraction after the seconds
///   only when it is not zero). `String` has only `min` and `max`; `Date` and
///   `Datetime` also have `mean` (a datetime) and percentiles (of the same
///   type as the column), but no `std`.
/// - A statistic that does not exist, or has no values to work on, is null.
///
/// `percentiles` must be in `[0, 1]`; they are sorted, and giving the same
/// value twice is an error. `interpolation` is passed to the percentiles of
/// numeric and temporal columns. Every statistic is computed over the rows in
/// their original order. (polars sorts numeric and temporal columns first when
/// there are percentiles, which can change the last digits of a float `mean`
/// or `std`; and where huge values of both signs cancel, the mean it gives
/// varies from run to run.)
///
/// # Errors
/// - `InvalidOperation` for a frame without columns (`cannot describe a
///   DataFrame that has no columns`) and for a percentile outside `[0, 1]` or
///   NaN (`` `percentiles` must all be in the range [0, 1] ``).
/// - `InvalidOperation` when a percentile of a `Date` or `Datetime` column
///   does not fit the type (the quantile of `Int64` microseconds near the
///   limits rounds to 2^63 as a `Float64`: `conversion from `f64` to
///   `datetime[μs]` failed in column 'q' ...`; polars raises the same error
///   with an internal column name).
/// - `DuplicateColumn` for a repeated percentile (`projections contained
///   duplicate output name '0.5:a'. ...`; `-0.0` and `0.0` count as
///   different), or for a column called `statistic`.
pub fn DataFrame::describe(
  self : DataFrame,
  percentiles~ : Array[Double] = [0.25, 0.5, 0.75],
  interpolation~ : QuantileMethod = Nearest,
) -> DataFrame raise PolarsError {
  if self.width() == 0 {
    raise InvalidOperation("cannot describe a DataFrame that has no columns")
  }
  for p in percentiles {
    if !(p >= 0.0 && p <= 1.0) {
      raise InvalidOperation("`percentiles` must all be in the range [0, 1]")
    }
  }
  let qs = desc_sorted(percentiles)
  let seen : Map[String, Bool] = Map([])
  for q in qs {
    let text = desc_float_repr(q)
    if seen.contains(text) {
      raise DuplicateColumn(
        "projections contained duplicate output name '\{text}:\{self.cols[0].name}'. It's possible that multiple expressions are returning the same default column name. If this is the case, try renaming the columns with `.alias(\"new_name\")` to avoid duplicate column names.",
      )
    }
    seen[text] = true
  }
  if self.index.contains("statistic") {
    raise DuplicateColumn(
      "column with name \"statistic\" is already present in the DataFrame",
    )
  }
  let labels : Array[String?] = [
    Some("count"),
    Some("null_count"),
    Some("mean"),
    Some("std"),
    Some("min"),
  ]
  for q in qs {
    labels.push(Some(desc_label(q)))
  }
  labels.push(Some("max"))
  let out : Array[Series] = [
    Series::make("statistic", String(@arrow.StrArray::from_options(labels))),
  ]
  for s in self.cols {
    let dt = s.dtype()
    let col = s.col
    match dt {
      String | Date | Datetime =>
        out.push(
          Series::make(
            s.name,
            String(
              @arrow.StrArray::from_options(
                desc_text_rows(col, qs, interpolation),
              ),
            ),
          ),
        )
      _ =>
        out.push(
          Series::make(
            s.name,
            Float64(
              @arrow.PrimArray::from_options(
                desc_float_rows(col, qs, interpolation),
              ),
            ),
          ),
        )
    }
  }
  DataFrame::from_valid(out)
}
