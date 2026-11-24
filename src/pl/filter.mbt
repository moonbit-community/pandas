///|
/// The rows where `mask` is true; rows where the mask is null are dropped. The
/// name and type are kept. A mask of length 1 applies to every row (`true`
/// keeps all rows, `false` or null none).
///
/// # Errors
/// - `SchemaMismatch` unless the mask is `Boolean` (a `Null` column is not).
/// - `ShapeMismatch` (`filter's length: 2 differs from that of the series: 3`)
///   when the mask length is neither the series length nor 1.
pub fn Series::filter(self : Series, mask : Series) -> Series raise PolarsError {
  let m = match mask.col {
    Boolean(m) => m
    _ =>
      raise SchemaMismatch("filter mask must be Boolean, got \{mask.dtype()}")
  }
  let n = self.len()
  if m.length() != n && m.length() != 1 {
    raise ShapeMismatch(
      "filter's length: \{m.length()} differs from that of the series: \{n}",
    )
  }
  let full = Column::Boolean(m).expand(n)
  match full {
    Boolean(f) => Series::make(self.name, self.col.filter(f))
    _ => abort("Series::filter: the mask is not Boolean")
  }
}
