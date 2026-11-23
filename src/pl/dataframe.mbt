///|
/// An ordered collection of equally long, uniquely named series.
///
/// Operations return new frames; the underlying column data is shared, not
/// copied. A frame with no columns has shape `(0, 0)`.
struct DataFrame {
  cols : Array[Series]
  index : Map[String, Int32]
}

///|
/// Creates a frame from `columns`; an empty array gives a 0x0 frame.
///
/// # Errors
/// Raises `DuplicateColumn` when two columns share a name and
/// `ShapeMismatch` when the columns differ in length.
pub fn DataFrame::new(columns : Array[Series]) -> DataFrame raise PolarsError {
  let index : Map[String, Int32] = Map([])
  let cols : Array[Series] = Array(capacity=columns.length())
  for s in columns {
    if index.contains(s.name()) {
      raise DuplicateColumn(
        "column with name '\{s.name()}' has more than one occurrence",
      )
    }
    if cols.length() > 0 {
      let first = cols[0]
      if s.len() != first.len() {
        raise ShapeMismatch(
          "column '\{s.name()}' has length \{s.len()} but column '\{first.name()}' has length \{first.len()}",
        )
      }
    }
    index[s.name()] = cols.length()
    cols.push(s)
  }
  { cols, index, }
}

///|
/// A frame with no rows and no columns.
pub fn DataFrame::empty() -> DataFrame {
  { cols: [], index: Map([]), }
}

///|
/// Builds a frame from columns already known to be valid (same length,
/// unique names); used by row operations that preserve both.
fn DataFrame::from_valid(cols : Array[Series]) -> DataFrame {
  let index : Map[String, Int32] = Map([])
  for i, s in cols {
    index[s.name()] = i
  }
  { cols, index, }
}

///|
/// Number of rows (0 when there are no columns).
pub fn DataFrame::height(self : DataFrame) -> Int32 {
  if self.cols.length() == 0 {
    0
  } else {
    self.cols[0].len()
  }
}

///|
/// Number of columns.
pub fn DataFrame::width(self : DataFrame) -> Int32 {
  self.cols.length()
}

///|
/// `(height, width)`.
pub fn DataFrame::shape(self : DataFrame) -> (Int32, Int32) {
  (self.height(), self.width())
}

///|
/// Column names in order.
pub fn DataFrame::columns(self : DataFrame) -> Array[String] {
  self.cols.map(s => s.name())
}

///|
/// Column data types in column order.
pub fn DataFrame::dtypes(self : DataFrame) -> Array[DataType] {
  self.cols.map(s => s.dtype())
}

///|
/// `(name, dtype)` pairs in column order.
pub fn DataFrame::schema(self : DataFrame) -> Array[(String, DataType)] {
  self.cols.map(s => (s.name(), s.dtype()))
}

///|
/// The columns as a new array; mutating it does not affect the frame.
pub fn DataFrame::get_columns(self : DataFrame) -> Array[Series] {
  self.cols.copy()
}

///|
/// The column called `name`.
///
/// # Errors
/// Raises `ColumnNotFound` when there is no such column.
pub fn DataFrame::column(
  self : DataFrame,
  name : String,
) -> Series raise PolarsError {
  match self.index.get(name) {
    Some(i) => self.cols[i]
    None => raise ColumnNotFound("column '\{name}' not found")
  }
}

///|
/// Position of the column called `name`, or `None`.
pub fn DataFrame::get_column_index(self : DataFrame, name : String) -> Int32? {
  self.index.get(name)
}

///|
/// The first `n` rows; a negative `n` drops the last `-n` rows instead.
/// Same semantics as `Series::head`; never fails.
pub fn DataFrame::head(self : DataFrame, n~ : Int32 = 10) -> DataFrame {
  DataFrame::from_valid(self.cols.map(s => s.head(n~)))
}

///|
/// The last `n` rows; a negative `n` drops the first `-n` rows instead.
/// Same semantics as `Series::tail`; never fails.
pub fn DataFrame::tail(self : DataFrame, n~ : Int32 = 10) -> DataFrame {
  DataFrame::from_valid(self.cols.map(s => s.tail(n~)))
}

///|
/// Rows `[offset, offset + length)` with the same semantics as
/// `Series::slice` (negative offset counts from the end, window clamped
/// afterwards); never fails.
pub fn DataFrame::slice(
  self : DataFrame,
  offset : Int32,
  length? : Int32,
) -> DataFrame {
  DataFrame::from_valid(self.cols.map(s => s.slice(offset, length?)))
}

///|
/// Rows at the given indices, in order and with repeats allowed; negative
/// indices count from the end.
///
/// # Errors
/// Raises `OutOfBounds` when any index is outside `-height <= i < height`
/// (so any index is out of bounds for a frame without rows).
pub fn DataFrame::gather(
  self : DataFrame,
  indices : Array[Int32],
) -> DataFrame raise PolarsError {
  let h = self.height()
  let norm : Array[Int32] = Array(capacity=indices.length())
  for i in indices {
    norm.push(normalize_index(h, i))
  }
  DataFrame::from_valid(
    self.cols.map(s => Series::make(s.name, s.col.gather(norm))),
  )
}

///|
/// All values of row `i` in column order; a negative `i` counts from the end.
///
/// # Errors
/// Raises `OutOfBounds` unless `-height <= i < height`.
pub fn DataFrame::row(
  self : DataFrame,
  i : Int32,
) -> Array[AnyValue] raise PolarsError {
  let j = normalize_index(self.height(), i)
  self.cols.map(s => s.col.get(j))
}

///|
/// The value at `row` (negative counts from the end) in column `column`.
///
/// # Errors
/// Raises `ColumnNotFound` for an unknown column and `OutOfBounds` for a
/// row outside `-height <= row < height`.
pub fn DataFrame::get(
  self : DataFrame,
  row : Int32,
  column : String,
) -> AnyValue raise PolarsError {
  self.column(column).get(row)
}

///|
/// Compares two frames: same column names in the same order, same types and
/// same values. Null equals null and NaN equals NaN.
pub fn DataFrame::equals(self : DataFrame, other : DataFrame) -> Bool {
  if self.cols.length() != other.cols.length() {
    return false
  }
  for i in 0..<self.cols.length() {
    if !self.cols[i].equals(other.cols[i]) {
      return false
    }
  }
  true
}

///|
/// Same as `DataFrame::equals`: same column names, order and dtypes, and
/// element-wise equal columns.
pub impl Eq for DataFrame with fn equal(self, other) {
  self.equals(other)
}

///|
/// Shows the columns, e.g. `[("a", Int64, [Int64(1)])]`.
pub impl Debug for DataFrame with fn to_repr(self) {
  @debug.Repr(self.cols)
}
