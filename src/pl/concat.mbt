// Concatenation of columns, series and frames (`concat`, `DataFrame::vstack`,
// `DataFrame::hstack`, `Series::append`, `Series::to_frame`).
//
// Semantics follow polars 2.1.0 (see docs/golden/concat_describe.json). Every
// column is copied exactly once, whatever the number of frames, so joining k
// frames costs O(total rows), not O(k * total rows).

///|
/// How `concat` joins its frames.
///
/// - `Vertical`: stack the rows. Column names, their order and their types
///   must be the same in every frame (a `Null` column fits any type).
/// - `VerticalRelaxed`: like `Vertical`, but a column takes the common type
///   of its types in all the frames (an `Int32` next to a `Float64` gives
///   `Float64`, a number next to a `String` gives `String`); the names must
///   still be the same.
/// - `Horizontal`: put the columns side by side; every frame with columns
///   must have the same height and no two columns may share a name.
/// - `Diagonal`: stack the rows over the union of the column names (in order
///   of first appearance); a frame that lacks a column gets nulls there.
#derive(Eq, @debug.Debug)
pub(all) enum ConcatHow {
  Vertical
  VerticalRelaxed
  Horizontal
  Diagonal
}

// ---------------------------------------------------------------------------
// Column::concat
// ---------------------------------------------------------------------------

///|
fn concat_total(lengths : Array[Int32]) -> Int32 {
  let mut total = 0
  for n in lengths {
    total += n
  }
  total
}

///|
fn[T : Default] concat_prims(
  parts : Array[@arrow.PrimArray[T]],
) -> @arrow.PrimArray[T] {
  let total = concat_total(parts.map(a => a.length()))
  let b : @arrow.PrimBuilder[T] = @arrow.PrimBuilder::new(capacity=total)
  for a in parts {
    for i in 0..<a.length() {
      if a.is_valid(i) {
        b.push(a.value(i))
      } else {
        b.push_null()
      }
    }
  }
  b.finish()
}

///|
fn concat_bools(parts : Array[@arrow.BoolArray]) -> @arrow.BoolArray {
  let total = concat_total(parts.map(a => a.length()))
  let b = @arrow.BoolBuilder::new(capacity=total)
  for a in parts {
    for i in 0..<a.length() {
      if a.is_valid(i) {
        b.push(a.value(i))
      } else {
        b.push_null()
      }
    }
  }
  b.finish()
}

///|
fn concat_strs(parts : Array[@arrow.StrArray]) -> @arrow.StrArray {
  let total = concat_total(parts.map(a => a.length()))
  let b = @arrow.StrBuilder::new(capacity=total)
  for a in parts {
    for i in 0..<a.length() {
      if a.is_valid(i) {
        b.push(a.value(i))
      } else {
        b.push_null()
      }
    }
  }
  b.finish()
}

///|
fn concat_mismatch() -> Unit {
  abort("Column::concat: the columns do not have the same type")
}

///|
/// The columns one after the other as a new column. The columns must all have
/// the same type and there must be at least one (the callers cast a `Null`
/// column to the type of the others first). A single column is returned as it
/// is; otherwise the values are copied once into a new buffer.
fn Column::concat(cols : Array[Column]) -> Column {
  if cols.length() == 0 {
    abort("Column::concat: no columns")
  }
  if cols.length() == 1 {
    return cols[0]
  }
  match cols[0] {
    Boolean(_) => {
      let parts : Array[@arrow.BoolArray] = []
      for c in cols {
        guard c is Boolean(a) else { concat_mismatch() }
        parts.push(a)
      }
      Boolean(concat_bools(parts))
    }
    Int32(_) => {
      let parts : Array[@arrow.PrimArray[Int32]] = []
      for c in cols {
        guard c is Int32(a) else { concat_mismatch() }
        parts.push(a)
      }
      Int32(concat_prims(parts))
    }
    Int64(_) => {
      let parts : Array[@arrow.PrimArray[Int64]] = []
      for c in cols {
        guard c is Int64(a) else { concat_mismatch() }
        parts.push(a)
      }
      Int64(concat_prims(parts))
    }
    Float32(_) => {
      let parts : Array[@arrow.PrimArray[Float]] = []
      for c in cols {
        guard c is Float32(a) else { concat_mismatch() }
        parts.push(a)
      }
      Float32(concat_prims(parts))
    }
    Float64(_) => {
      let parts : Array[@arrow.PrimArray[Double]] = []
      for c in cols {
        guard c is Float64(a) else { concat_mismatch() }
        parts.push(a)
      }
      Float64(concat_prims(parts))
    }
    String(_) => {
      let parts : Array[@arrow.StrArray] = []
      for c in cols {
        guard c is String(a) else { concat_mismatch() }
        parts.push(a)
      }
      String(concat_strs(parts))
    }
    Date(_) => {
      let parts : Array[@arrow.PrimArray[Int32]] = []
      for c in cols {
        guard c is Date(a) else { concat_mismatch() }
        parts.push(a)
      }
      Date(concat_prims(parts))
    }
    Datetime(_) => {
      let parts : Array[@arrow.PrimArray[Int64]] = []
      for c in cols {
        guard c is Datetime(a) else { concat_mismatch() }
        parts.push(a)
      }
      Datetime(concat_prims(parts))
    }
    Null(_) => {
      let mut total = 0
      for c in cols {
        guard c is Null(n) else { concat_mismatch() }
        total += n
      }
      Null(total)
    }
  }
}

///|
/// `col` as a column of type `dt`: a `Null` column becomes nulls of that
/// type; the type of any other column is already `dt`.
fn concat_fit(col : Column, dt : DataType) -> Column {
  match col {
    Null(n) if dt != DataType::Null => null_column(dt, n)
    _ => col
  }
}

// ---------------------------------------------------------------------------
// Checks shared by `concat`, `vstack` and `append`
// ---------------------------------------------------------------------------

///|
/// polars' error for a column whose type does not fit the one it is appended
/// to; a `Null` column fits any type.
fn concat_check_type(
  expected : DataType,
  actual : DataType,
) -> Unit raise PolarsError {
  if actual != expected && actual != DataType::Null {
    raise SchemaMismatch(
      "type \{polars_type_name(actual)} is incompatible with expected type \{polars_type_name(expected)}",
    )
  }
}

///|
/// Checks that `other` can be stacked under `base` (both with columns): the
/// same width, then column by column the same name and a fitting type.
/// `base_text` names the first frame in the width error (`width 2` for
/// `concat`, `shape (3, 2)` for `vstack`).
fn concat_check_append(
  base : DataFrame,
  other : DataFrame,
  base_text : String,
) -> Unit raise PolarsError {
  if other.width() != base.width() {
    raise ShapeMismatch(
      "unable to append to a DataFrame of \{base_text} with a DataFrame of width \{other.width()}",
    )
  }
  for i in 0..<base.width() {
    let l = base.cols[i]
    let r = other.cols[i]
    if l.name != r.name {
      raise ShapeMismatch(
        "unable to vstack, column names don't match: \"\{l.name}\" and \"\{r.name}\"",
      )
    }
    concat_check_type(l.dtype(), r.dtype())
  }
}

///|
/// Stacks frames that were already checked against `parts[0]` (same width,
/// names and fitting types, at least one frame with columns first).
fn concat_stack(parts : Array[DataFrame]) -> DataFrame {
  let base = parts[0]
  let cols : Array[Series] = Array(capacity=base.width())
  for i in 0..<base.width() {
    let dt = base.cols[i].dtype()
    let pieces = parts.map(f => concat_fit(f.cols[i].col, dt))
    cols.push(Series::make(base.cols[i].name, Column::concat(pieces)))
  }
  DataFrame::from_valid(cols)
}

///|
/// polars' checks when it builds a frame from the columns `cols`
/// (`DataFrame::new` inside `hstack` and the horizontal `concat`): every
/// column must have `height` rows and no two may share a name. `target` is
/// the text after `does not match` in the height error.
///
/// With up to four columns polars looks at each column in turn, checks its
/// height and then looks for a later column with the same name (so the name
/// reported is the one that appears first); with more it checks height and
/// then repeated name column by column (the name reported is the first one
/// that repeats an earlier name). The two give different errors when a
/// column has the wrong height and a name is also repeated.
fn concat_validate_columns(
  cols : Array[Series],
  height : Int32,
  target : String,
) -> Unit raise PolarsError {
  let n = cols.length()
  let dup = (name : String) => {
    DuplicateColumn(
      "could not create a new DataFrame: column with name '\{name}' has more than one occurrence",
    )
  }
  let wrong = (s : Series) => {
    ShapeMismatch(
      "could not create a new DataFrame: height of column '\{s.name}' (\{s.len()}) does not match \{target}",
    )
  }
  if n <= 4 {
    for i in 0..<n {
      if cols[i].len() != height {
        raise wrong(cols[i])
      }
      for j in (i + 1)..<n {
        if cols[i].name == cols[j].name {
          raise dup(cols[i].name)
        }
      }
    }
  } else {
    let seen : Map[String, Bool] = Map([])
    for s in cols {
      if s.len() != height {
        raise wrong(s)
      }
      if seen.contains(s.name) {
        raise dup(s.name)
      }
      seen[s.name] = true
    }
  }
}

// ---------------------------------------------------------------------------
// concat
// ---------------------------------------------------------------------------

///|
/// polars' fold of `Vertical`: a leading frame without columns is dropped,
/// every other frame must match the first frame that has columns.
fn concat_vertical(frames : Array[DataFrame]) -> DataFrame raise PolarsError {
  let parts : Array[DataFrame] = []
  for f in frames {
    if parts.length() == 0 {
      if f.width() > 0 {
        parts.push(f)
      }
    } else {
      concat_check_append(parts[0], f, "width \{parts[0].width()}")
      parts.push(f)
    }
  }
  if parts.length() == 0 {
    return DataFrame::empty()
  }
  if parts.length() == 1 {
    return parts[0]
  }
  concat_stack(parts)
}

///|
/// The type a column takes in `VerticalRelaxed`: this library's `supertype`,
/// and `String` for a string next to a number (polars' supertype, which
/// `supertype` leaves out because comparison and arithmetic reject it).
fn concat_supertype(a : DataType, b : DataType) -> DataType? {
  match supertype(a, b) {
    Some(t) => Some(t)
    None =>
      match (a, b) {
        (String, t) | (t, String) =>
          if t.is_numeric() {
            Some(String)
          } else {
            None
          }
        _ => None
      }
  }
}

///|
/// polars' checks of `VerticalRelaxed`, frame by frame: the width, then for
/// every column its name and the common type so far.
fn concat_relaxed(frames : Array[DataFrame]) -> DataFrame raise PolarsError {
  let first = frames[0]
  let w = first.width()
  let types = first.dtypes()
  for k in 1..<frames.length() {
    let f = frames[k]
    if f.width() != w {
      raise ComputeError("schema lengths differ")
    }
    for i in 0..<w {
      let name = first.cols[i].name
      if f.cols[i].name != name {
        raise ComputeError(
          "schema names differ: got \{name}, expected \{f.cols[i].name}",
        )
      }
      let dt = f.cols[i].dtype()
      match concat_supertype(types[i], dt) {
        Some(t) => types[i] = t
        None =>
          raise SchemaMismatch(
            "failed to determine supertype of \{types[i]} and \{dt}",
          )
      }
    }
  }
  if frames.length() == 1 {
    return first
  }
  let cols : Array[Series] = Array(capacity=w)
  for i in 0..<w {
    let pieces : Array[Column] = Array(capacity=frames.length())
    for f in frames {
      let s = f.cols[i]
      pieces.push(
        if s.dtype() == types[i] {
          s.col
        } else {
          s.cast(types[i], strict=false).col
        },
      )
    }
    cols.push(Series::make(first.cols[i].name, Column::concat(pieces)))
  }
  DataFrame::from_valid(cols)
}

///|
/// Side by side. Frames without columns are ignored; the others must have the
/// same height (checked before the names).
fn concat_horizontal(frames : Array[DataFrame]) -> DataFrame raise PolarsError {
  let parts = frames.filter(f => f.width() > 0)
  if parts.length() == 0 {
    return DataFrame::empty()
  }
  if parts.length() == 1 {
    return parts[0]
  }
  let h = parts[0].height()
  for f in parts {
    if f.height() != h {
      raise ShapeMismatch(
        "cannot concat dataframes with different heights in 'strict' mode",
      )
    }
  }
  let cols : Array[Series] = []
  for f in parts {
    for s in f.cols {
      cols.push(s)
    }
  }
  concat_validate_columns(cols, h, "the height of the first column")
  DataFrame::from_valid(cols)
}

///|
/// Stacks over the union of the columns. A column has the type of its first
/// appearance (a later `Null` fits, any other different type is an error);
/// where a frame lacks the column it is null.
fn concat_diagonal(frames : Array[DataFrame]) -> DataFrame raise PolarsError {
  if frames.length() == 1 {
    return frames[0]
  }
  let names : Array[String] = []
  let types : Array[DataType] = []
  let position : Map[String, Int32] = Map([])
  for f in frames {
    for s in f.cols {
      if !position.contains(s.name) {
        position[s.name] = names.length()
        names.push(s.name)
        types.push(s.dtype())
      }
    }
  }
  for f in frames {
    for j in 0..<names.length() {
      match f.index.get(names[j]) {
        Some(i) => concat_check_type(types[j], f.cols[i].dtype())
        None => ()
      }
    }
  }
  let cols : Array[Series] = Array(capacity=names.length())
  for j in 0..<names.length() {
    let pieces : Array[Column] = Array(capacity=frames.length())
    for f in frames {
      match f.index.get(names[j]) {
        Some(i) => pieces.push(concat_fit(f.cols[i].col, types[j]))
        None => pieces.push(null_column(types[j], f.height()))
      }
    }
    cols.push(Series::make(names[j], Column::concat(pieces)))
  }
  DataFrame::from_valid(cols)
}

///|
/// Joins frames into one; see `ConcatHow` for the four modes.
///
/// A single frame is returned as it is. Each column is copied once, so the
/// cost is linear in the total number of rows however many frames are joined.
///
/// # Errors
/// - `InvalidOperation` (`cannot concat empty list`) for an empty array.
/// - `Vertical`: `ShapeMismatch` when a frame has another number of columns
///   (`unable to append to a DataFrame of width 2 with a DataFrame of width
///   1`; a frame without columns only fits before the first frame that has
///   columns) or another name at some position (`unable to vstack, column
///   names don't match: "a" and "q"`); `SchemaMismatch` when a type differs
///   and is not `Null` (`type Int32 is incompatible with expected type
///   Int64`). The first mismatch in frame order, then column order, is
///   reported; a column's name is checked before its type. This is a plain
///   left fold; polars' own order for three or more frames is not
///   deterministic (see docs/golden/known-diffs/concat_describe.md).
/// - `VerticalRelaxed`: `ComputeError` for another number of columns
///   (`schema lengths differ`) or name (`schema names differ: got a,
///   expected q`); `SchemaMismatch` when two types have no common type
///   (`failed to determine supertype of bool and date`).
/// - `Horizontal`: `ShapeMismatch` when the frames with columns differ in
///   height (`cannot concat dataframes with different heights in 'strict'
///   mode`, checked first); `DuplicateColumn` when two columns share a name
///   (`could not create a new DataFrame: column with name 'a' has more than
///   one occurrence`).
/// - `Diagonal`: `SchemaMismatch` when a column's type differs from the type
///   of its first appearance and is not `Null`.
pub fn concat(
  frames : Array[DataFrame],
  how~ : ConcatHow = Vertical,
) -> DataFrame raise PolarsError {
  if frames.length() == 0 {
    raise InvalidOperation("cannot concat empty list")
  }
  match how {
    Vertical => concat_vertical(frames)
    VerticalRelaxed => concat_relaxed(frames)
    Horizontal => concat_horizontal(frames)
    Diagonal => concat_diagonal(frames)
  }
}

// ---------------------------------------------------------------------------
// vstack, hstack, append, to_frame
// ---------------------------------------------------------------------------

///|
/// This frame with the rows of `other` below it. The column names and their
/// order must be the same and the types must match (an `other` column of type
/// `Null` becomes nulls of the type). A frame without columns takes the other
/// frame as it is.
///
/// Every call copies all the data of both frames (the columns are contiguous),
/// so appending in a loop is quadratic: `acc = acc.vstack(chunk)` 1000 times
/// on 1000-row chunks takes tens of seconds. Collect the frames and call
/// `concat` once.
///
/// # Errors
/// `ShapeMismatch` when `other` has no columns or another number of them
/// (`unable to append to a DataFrame of shape (2, 2) with a DataFrame of
/// width 1`) or a column has another name (`unable to vstack, column names
/// don't match: "a" and "q"`); `SchemaMismatch` when a type differs and is not
/// `Null` (`type Int32 is incompatible with expected type Int64`).
pub fn DataFrame::vstack(
  self : DataFrame,
  other : DataFrame,
) -> DataFrame raise PolarsError {
  if self.width() == 0 {
    return other
  }
  concat_check_append(self, other, "shape (\{self.height()}, \{self.width()})")
  concat_stack([self, other])
}

///|
/// This frame with the given columns added on the right. The frame is
/// returned as it is when `columns` is empty. A frame without columns has
/// height 0, so a column added to it must be empty too (the error then names
/// the first empty new column, or says `DataFrame height (0)` if there is none).
///
/// # Errors
/// `DuplicateColumn` when a name is already there or given twice (`could not
/// create a new DataFrame: column with name 'a' has more than one
/// occurrence`); `ShapeMismatch` when a column's length is not the frame's
/// height (`could not create a new DataFrame: height of column 'c' (1) does
/// not match height of column 'a' (2)`). Which one is reported when both
/// kinds of mistake are there follows polars (see `concat_validate_columns`):
/// with at most four columns in all, a repeated name is found before the
/// wrong height of a later column; with more columns the first offending
/// column in order is reported.
pub fn DataFrame::hstack(
  self : DataFrame,
  columns : Array[Series],
) -> DataFrame raise PolarsError {
  if columns.length() == 0 {
    return self
  }
  let h = self.height()
  // Without columns the frame's height is 0; polars then names the first new
  // column of height 0 in the message, or says `DataFrame height (0)` when
  // there is none.
  let target = if self.width() > 0 {
    "height of column '\{self.cols[0].name}' (\{h})"
  } else {
    match columns.search_by(s => s.len() == 0) {
      Some(i) => "height of column '\{columns[i].name}' (0)"
      None => "DataFrame height (\{h})"
    }
  }
  let all = self.cols + columns
  concat_validate_columns(all, h, target)
  DataFrame::from_valid(all)
}

///|
/// This series with the values of `other` after them, under this series'
/// name. The types must be the same; an `other` of type `Null` is read as
/// nulls of this series' type.
///
/// Every call copies all the values of both series, so appending in a loop is
/// quadratic. To append many pieces, collect them in a frame each and call
/// `concat` once, or build one `Series` from the whole array.
///
/// # Errors
/// `SchemaMismatch` for another type (`type Int32 is incompatible with
/// expected type Int64`), also when `other` is empty or when this series is
/// `Null` and `other` is not.
pub fn Series::append(
  self : Series,
  other : Series,
) -> Series raise PolarsError {
  concat_check_type(self.dtype(), other.dtype())
  Series::make(
    self.name,
    Column::concat([self.col, concat_fit(other.col, self.dtype())]),
  )
}

///|
/// A frame with this series as its only column.
pub fn Series::to_frame(self : Series) -> DataFrame {
  DataFrame::from_valid([self])
}
