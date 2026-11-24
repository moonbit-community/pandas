///|
/// Which of several identical rows `unique` keeps.
///
/// - `Any`: any one of them (this library keeps the first).
/// - `First`: the first occurrence.
/// - `Last`: the last occurrence.
/// - `KeepNone`: none of them; only rows that occur once survive (polars'
///   `keep="none"`).
#derive(Eq, @debug.Debug)
pub(all) enum UniqueKeep {
  Any
  First
  Last
  KeepNone
}

///|
/// Formats the option with its polars name (`any`, `first`, `last`, `none`).
pub impl Show for UniqueKeep with fn output(self, logger) {
  logger.write_string(
    match self {
      Any => "any"
      First => "first"
      Last => "last"
      KeepNone => "none"
    },
  )
}

///|
/// Makes `to_string` callable as a method, giving the same polars name as
/// `Show`.
pub extend UniqueKeep with Show::{to_string}

///|
/// The rows `keep` retains when rows are compared on all `cols` (null equals
/// null, NaN equals NaN, `-0.0` equals `0.0`), as row numbers in ascending
/// order, so the original order is always preserved. A hash table makes this
/// O(n); with no key column the result is empty.
///
/// # Panics
/// Aborts when the columns differ in length.
fn unique_row_indices(cols : Array[Column], keep : UniqueKeep) -> Array[Int32] {
  if cols.length() == 0 {
    return []
  }
  let n = cols[0].length()
  for c in cols {
    if c.length() != n {
      abort("unique_row_indices: columns differ in length")
    }
  }
  let table = GroupTable::new(if n < 64 { n } else { 64 })
  let count : Array[Int32] = []
  let last : Array[Int32] = []
  for i in 0..<n {
    let h = row_hash(cols, i)
    let g = table.find(h, cols, cols, i)
    if g < 0 {
      ignore(table.add(h, i))
      count.push(1)
      last.push(i)
    } else {
      count[g] += 1
      last[g] = i
    }
  }
  let groups = table.length()
  let out : Array[Int32] = Array(capacity=groups)
  match keep {
    Any | First =>
      for g in 0..<groups {
        out.push(table.group_row[g])
      }
    KeepNone =>
      for g in 0..<groups {
        if count[g] == 1 {
          out.push(table.group_row[g])
        }
      }
    Last => {
      // the last rows are not in row order by group: mark and scan
      let mark : Array[Bool] = Array::make(n, false)
      for g in 0..<groups {
        mark[last[g]] = true
      }
      for i in 0..<n {
        if mark[i] {
          out.push(i)
        }
      }
    }
  }
  out
}

///|
/// The distinct values, each at its first occurrence, null counted as a value
/// (one null at most), NaN as one value and `-0.0` equal to `0.0` (the first
/// of them is kept). This library always returns the values in order of first
/// appearance; the order is only guaranteed when `maintain_order` is `true`.
/// The name and type are kept.
pub fn Series::unique(self : Series, maintain_order~ : Bool = false) -> Series {
  ignore(maintain_order)
  let rows = unique_row_indices([self.col], First)
  if rows.length() == self.col.length() {
    return self
  }
  Series::make(self.name, self.col.gather(rows))
}

///|
/// Number of distinct values; null counts as one value (a `Null` series has
/// one if it is not empty), NaN is one value and `-0.0` equals `0.0`.
pub fn Series::n_unique(self : Series) -> Int32 {
  unique_row_indices([self.col], First).length()
}

///|
fn is_int_type(t : DataType) -> Bool {
  t == Int32 || t == Int64
}

///|
fn is_float_type(t : DataType) -> Bool {
  t == Float32 || t == Float64
}

///|
/// Whether each value is in `other`, as a `Boolean` series named like `self`.
///
/// - A null in `self` gives null (also when `other` has a null; this is
///   polars' default `nulls_equal=false`); nulls in `other` never match.
/// - NaN matches NaN and `-0.0` matches `0.0`.
/// - `Int32` and `Int64` mix (compared as `Int64`), so do `Float32` and
///   `Float64` (compared as `Float64`: `0.1f` is not `0.1`). Integer against
///   float, or any other pair of different types, is an error. A `Null`
///   series on either side is accepted: a `Null` `self` gives all null, a
///   `Null` or empty `other` gives false (null where `self` is null).
/// - The lookup is a hash table over `other`, O(n + m).
///
/// # Errors
/// `InvalidOperation` (`'is_in' cannot check for Int32 values in List(String)
/// data`) when the types are incompatible.
pub fn Series::is_in(self : Series, other : Series) -> Series raise PolarsError {
  let a = self.dtype()
  let b = other.dtype()
  let ok = a == b ||
    a == Null ||
    b == Null ||
    (is_int_type(a) && is_int_type(b)) ||
    (is_float_type(a) && is_float_type(b))
  if !ok {
    // polars ends the message with a period when an integer meets a float
    let mixed = (is_int_type(a) && is_float_type(b)) ||
      (is_float_type(a) && is_int_type(b))
    raise InvalidOperation(
      "'is_in' cannot check for \{polars_type_name(a)} values in List(\{polars_type_name(b)}) data" +
      (if mixed { "." } else { "" }),
    )
  }
  let n = self.col.length()
  if a == Null {
    return Series::make(self.name, Column::full_null(Boolean, n))
  }
  if b == Null || other.col.length() == 0 {
    // nothing can match: false for a value, null for a null
    let valid = match self.col.validity() {
      None => None
      Some(v) => Some(v)
    }
    return Series::make(
      self.name,
      Boolean(@arrow.BoolArray::new(@arrow.Bitmap::filled(n, false), valid)),
    )
  }
  let (sc, oc) = if a == b {
    (self.col, other.col)
  } else if is_int_type(a) {
    (self.col.cast_lenient(Int64), other.col.cast_lenient(Int64))
  } else {
    (self.col.cast_lenient(Float64), other.col.cast_lenient(Float64))
  }
  let m = oc.length()
  let build = [oc]
  let table = GroupTable::new(if m < 64 { m } else { 64 })
  for j in 0..<m {
    if oc.is_valid(j) {
      let h = oc.hash_at(j)
      if table.find(h, build, build, j) < 0 {
        ignore(table.add(h, j))
      }
    }
  }
  let probe = [sc]
  let out = @arrow.BoolBuilder::new(capacity=n)
  for i in 0..<n {
    if sc.is_valid(i) {
      out.push(table.find(sc.hash_at(i), build, probe, i) >= 0)
    } else {
      out.push_null()
    }
  }
  Series::make(self.name, Boolean(out.finish()))
}
