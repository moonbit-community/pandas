///|
/// Stable merge sort of `idx` under `cmp` (a three-way comparison of two row
/// numbers): runs of 16 by insertion sort, then bottom-up merges that take
/// from the right run only when it is strictly smaller. O(n log n), `cmp` is
/// called on row numbers so no values are boxed.
fn sort_stable_indices(
  idx : FixedArray[Int32],
  cmp : (Int32, Int32) -> Int32,
) -> FixedArray[Int32] {
  let n = idx.length()
  let run = 16
  let mut start = 0
  while start < n {
    let stop = if n - start > run { start + run } else { n }
    for i in (start + 1)..<stop {
      let x = idx[i]
      let mut j = i
      while j > start && cmp(idx[j - 1], x) > 0 {
        idx[j] = idx[j - 1]
        j -= 1
      }
      idx[j] = x
    }
    start = stop
  }
  let mut src = idx
  let mut dst : FixedArray[Int32] = FixedArray::make(n, 0)
  let mut width = run
  while width < n {
    let mut lo = 0
    while lo < n {
      let mid = if n - lo > width { lo + width } else { n }
      let hi = if n - mid > width { mid + width } else { n }
      if mid >= hi || cmp(src[mid - 1], src[mid]) <= 0 {
        // nothing to merge, or the two runs are already in order
        for k in lo..<hi {
          dst[k] = src[k]
        }
      } else {
        let mut i = lo
        let mut j = mid
        let mut k = lo
        while i < mid && j < hi {
          if cmp(src[j], src[i]) < 0 {
            dst[k] = src[j]
            j += 1
          } else {
            dst[k] = src[i]
            i += 1
          }
          k += 1
        }
        while i < mid {
          dst[k] = src[i]
          i += 1
          k += 1
        }
        while j < hi {
          dst[k] = src[j]
          j += 1
          k += 1
        }
      }
      lo = hi
    }
    let t = src
    src = dst
    dst = t
    if width > n / 2 {
      break
    }
    width = width * 2
  }
  src
}

///|
/// A comparison of two rows of one column by value only (the caller has
/// checked that both rows are valid): NaN is equal to NaN and greater than
/// every number, `-0.0 == 0.0`, strings by code point. `desc` swaps the
/// operands, so ties stay ties and the sort stays stable. The values are
/// copied out once so that a comparison is two array reads, not an
/// `AnyValue`.
fn Column::value_cmp(self : Column, desc : Bool) -> (Int32, Int32) -> Int32 {
  match self {
    Boolean(a) => {
      let v = FixedArray::makei(a.length(), i => a.value(i))
      if desc {
        (i, j) => ord_cmp(v[j], v[i])
      } else {
        (i, j) => ord_cmp(v[i], v[j])
      }
    }
    Int32(a) | Date(a) => {
      let v = FixedArray::makei(a.length(), i => a.value(i))
      if desc {
        (i, j) => ord_cmp(v[j], v[i])
      } else {
        (i, j) => ord_cmp(v[i], v[j])
      }
    }
    Int64(a) | Datetime(a) => {
      let v = FixedArray::makei(a.length(), i => a.value(i))
      if desc {
        (i, j) => ord_cmp(v[j], v[i])
      } else {
        (i, j) => ord_cmp(v[i], v[j])
      }
    }
    Float32(a) => {
      let v = FixedArray::makei(a.length(), i => a.value(i))
      if desc {
        (i, j) => float_cmp(v[j], v[i])
      } else {
        (i, j) => float_cmp(v[i], v[j])
      }
    }
    Float64(a) => {
      let v = FixedArray::makei(a.length(), i => a.value(i))
      if desc {
        (i, j) => float_cmp(v[j], v[i])
      } else {
        (i, j) => float_cmp(v[i], v[j])
      }
    }
    String(a) => {
      let v = FixedArray::makei(a.length(), i => a.value(i))
      if desc {
        (i, j) => str_cmp(v[j], v[i])
      } else {
        (i, j) => str_cmp(v[i], v[j])
      }
    }
    Null(_) => (_, _) => 0
  }
}

///|
/// The sort order of rows under several keys, as row numbers: `cols[k]` is
/// the k-th key, sorted `descending[k]` and with its nulls last when
/// `nulls_last[k]`. The sort is stable (rows equal on every key keep their
/// original order, also for descending keys) and takes O(n log n)
/// comparisons. Ordering is polars': nulls go first or last as asked
/// (independent of `descending`), NaN is greater than every number, `-0.0`
/// equals `0.0`, strings compare by code point.
///
/// # Panics
/// The three arrays must have the same length and all columns the same number
/// of rows; with no key the result is empty.
fn arg_sort_columns(
  cols : Array[Column],
  descending : Array[Bool],
  nulls_last : Array[Bool],
) -> Array[Int32] {
  if cols.length() != descending.length() ||
    cols.length() != nulls_last.length() {
    abort(
      "arg_sort_columns: the key, descending and nulls_last arrays differ in length",
    )
  }
  if cols.length() == 0 {
    return []
  }
  let n = cols[0].length()
  if cols.length() == 1 {
    return arg_sort_one(cols[0], descending[0], nulls_last[0])
  }
  let cmps : Array[(Int32, Int32) -> Int32] = []
  let valids : Array[@arrow.Bitmap?] = []
  for k in 0..<cols.length() {
    if cols[k].length() != n {
      abort("arg_sort_columns: columns differ in length")
    }
    cmps.push(cols[k].value_cmp(descending[k]))
    valids.push(cols[k].validity())
  }
  let nk = cols.length()
  let cmp = (i : Int32, j : Int32) => {
    for k in 0..<nk {
      let c = match valids[k] {
        None => cmps[k](i, j)
        Some(v) =>
          match (v.get(i), v.get(j)) {
            (true, true) => cmps[k](i, j)
            (false, false) => 0
            (false, true) => if nulls_last[k] { 1 } else { -1 }
            (true, false) => if nulls_last[k] { -1 } else { 1 }
          }
      }
      if c != 0 {
        return c
      }
    }
    0
  }
  let idx = FixedArray::makei(n, i => i)
  let sorted = sort_stable_indices(idx, cmp)
  Array::makei(n, i => sorted[i])
}

///|
/// One key: the nulls (original order) and the valid rows (sorted by value)
/// are separated first, so the value comparison needs no null checks.
fn arg_sort_one(col : Column, desc : Bool, nulls_last : Bool) -> Array[Int32] {
  let n = col.length()
  let valid_rows : Array[Int32] = Array(capacity=n)
  let null_rows : Array[Int32] = []
  match col.validity() {
    None =>
      for i in 0..<n {
        valid_rows.push(i)
      }
    Some(v) =>
      for i in 0..<n {
        if v.get(i) {
          valid_rows.push(i)
        } else {
          null_rows.push(i)
        }
      }
  }
  let sorted = sort_stable_indices(
    FixedArray::from_array(valid_rows),
    col.value_cmp(desc),
  )
  let out : Array[Int32] = Array(capacity=n)
  if !nulls_last {
    out.append(null_rows)
  }
  for x in sorted {
    out.push(x)
  }
  if nulls_last {
    out.append(null_rows)
  }
  out
}

///|
/// The sorted series: rows ordered ascending (or `descending`), nulls first
/// (or last with `nulls_last`, independent of the direction), NaN after every
/// number, strings by code point. The sort is stable and takes O(n log n)
/// comparisons; the name and type are kept.
pub fn Series::sort(
  self : Series,
  descending~ : Bool = false,
  nulls_last~ : Bool = false,
) -> Series {
  if self.col.length() <= 1 {
    return self
  }
  let order = arg_sort_columns([self.col], [descending], [nulls_last])
  Series::make(self.name, self.col.gather(order))
}

///|
/// The row numbers that sort the series, as an `Int64` series with the same
/// name. Ordering rules and stability as in `Series::sort`: rows that compare
/// equal keep their original order, also when `descending` is set.
pub fn Series::arg_sort(
  self : Series,
  descending~ : Bool = false,
  nulls_last~ : Bool = false,
) -> Series {
  let order = arg_sort_columns([self.col], [descending], [nulls_last])
  Series::make(
    self.name,
    Int64(@arrow.PrimArray::from_array(order.map(i => i.to_int64()))),
  )
}
