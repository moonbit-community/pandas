// `Series::any`, `all`, `is_sorted`, `gather_every` and `DataFrame::gather_every`.

///|
/// The error of a `Series` or an expression that needs a `Boolean` column.
fn boolean_expected(s : Series) -> PolarsError {
  SchemaMismatch(
    "invalid series dtype: expected `Boolean`, got `\{s.dtype()}` for series with name `\{s.name}`",
  )
}

///|
/// Whether any value is true. With `ignore_nulls` (the default) nulls are
/// skipped, so the result is `Some` and an empty or all-null series gives
/// `Some(false)`; without it the result is `None` when no value is true and one
/// is null (Kleene logic).
///
/// # Errors
/// `SchemaMismatch` (``invalid series dtype: expected `Boolean`, got `i32` for
/// series with name `x` ``) unless the series is `Boolean`.
pub fn Series::any(
  self : Series,
  ignore_nulls~ : Bool = true,
) -> Bool? raise PolarsError {
  match self.col {
    Boolean(a) =>
      any_all_scan(
        a.length(),
        i => a.is_valid(i),
        i => a.value(i),
        true,
        ignore_nulls,
      )
    _ => raise boolean_expected(self)
  }
}

///|
/// Whether every value is true; an empty series gives `Some(true)`. See
/// `Series::any` for the null handling and the errors.
pub fn Series::all(
  self : Series,
  ignore_nulls~ : Bool = true,
) -> Bool? raise PolarsError {
  match self.col {
    Boolean(a) =>
      any_all_scan(
        a.length(),
        i => a.is_valid(i),
        i => a.value(i),
        false,
        ignore_nulls,
      )
    _ => raise boolean_expected(self)
  }
}

///|
/// Whether the values are in the order `Series::sort(descending~,
/// nulls_last~)` would put them (rows that compare equal may be in any
/// order). Nulls must all come first, or all last with `nulls_last`; NaN is
/// greater than every number. An empty series, a single value and an all-null
/// series are sorted in every direction. A single pass: O(n).
pub fn Series::is_sorted(
  self : Series,
  descending~ : Bool = false,
  nulls_last~ : Bool = false,
) -> Bool {
  let n = self.col.length()
  let cmp = self.col.value_cmp(descending)
  let valid = self.col.validity()
  for i in 1..<n {
    let c = match valid {
      None => cmp(i - 1, i)
      Some(v) =>
        match (v.get(i - 1), v.get(i)) {
          (true, true) => cmp(i - 1, i)
          (false, false) => 0
          (false, true) => if nulls_last { 1 } else { -1 }
          (true, false) => if nulls_last { -1 } else { 1 }
        }
    }
    if c > 0 {
      return false
    }
  }
  true
}

///|
/// The rows `offset, offset + n, offset + 2n, ...` of a column of `len` rows.
///
/// # Errors
/// `InvalidOperation` for a negative `n` or `offset` (polars' text:
/// `can't convert negative int to unsigned`) and for `n = 0` (`gather_every(n):
/// n should be positive`).
fn gather_every_indices(
  len : Int32,
  n : Int32,
  offset : Int32,
) -> Array[Int32] raise PolarsError {
  if n < 0 || offset < 0 {
    raise InvalidOperation("can't convert negative int to unsigned")
  }
  if n == 0 {
    raise InvalidOperation("gather_every(n): n should be positive")
  }
  let out : Array[Int32] = Array(
    capacity=if offset >= len { 0 } else { (len - offset - 1) / n + 1 },
  )
  let mut i = offset.to_int64()
  let step = n.to_int64()
  while i < len.to_int64() {
    out.push(i.to_int())
    i += step
  }
  out
}

///|
/// Every `n`-th value starting at row `offset` (`offset` itself is kept), with
/// the name and type of the series. An `offset` beyond the end gives an empty
/// series.
///
/// # Errors
/// `InvalidOperation` for `n = 0` (`gather_every(n): n should be positive`) and
/// for a negative `n` or `offset` (`can't convert negative int to unsigned`).
pub fn Series::gather_every(
  self : Series,
  n : Int32,
  offset~ : Int32 = 0,
) -> Series raise PolarsError {
  let idx = gather_every_indices(self.col.length(), n, offset)
  Series::make(self.name, self.col.gather(idx))
}

///|
/// Every `n`-th row starting at row `offset`, all columns. Errors as for
/// `Series::gather_every`.
pub fn DataFrame::gather_every(
  self : DataFrame,
  n : Int32,
  offset~ : Int32 = 0,
) -> DataFrame raise PolarsError {
  frame_gather(self, gather_every_indices(self.height(), n, offset))
}
