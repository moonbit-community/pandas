///|
/// Error raised by every fallible operation of the `@pl` package.
///
/// Each variant carries an English message that names the column, type or
/// position involved.
pub(all) suberror PolarsError {
  ColumnNotFound(String)
  DuplicateColumn(String)
  SchemaMismatch(String)
  ShapeMismatch(String)
  OutOfBounds(String)
  InvalidOperation(String)
  ComputeError(String)
  ParseError(String)
}

///|
/// Formats the error as `<VariantName>: <message>`.
pub impl Show for PolarsError with fn output(self, logger) {
  let (name, msg) = match self {
    ColumnNotFound(m) => ("ColumnNotFound", m)
    DuplicateColumn(m) => ("DuplicateColumn", m)
    SchemaMismatch(m) => ("SchemaMismatch", m)
    ShapeMismatch(m) => ("ShapeMismatch", m)
    OutOfBounds(m) => ("OutOfBounds", m)
    InvalidOperation(m) => ("InvalidOperation", m)
    ComputeError(m) => ("ComputeError", m)
    ParseError(m) => ("ParseError", m)
  }
  logger.write_string(name)
  logger.write_string(": ")
  logger.write_string(msg)
}

///|
/// Makes `to_string` callable as a method (`e.to_string()`), giving the same
/// `<VariantName>: <message>` text as `Show`.
pub extend PolarsError with Show::{to_string}
