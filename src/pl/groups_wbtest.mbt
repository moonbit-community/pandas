///|
/// A small deterministic generator (xorshift-style), so the tests are
/// repeatable on every backend.
struct GwRng {
  mut state : Int64
}

///|
fn GwRng::new(seed : Int64) -> GwRng {
  { state: seed * 6364136223846793005L + 1442695040888963407L, }
}

///|
/// A number in `0..<bound`.
fn GwRng::below(self : GwRng, bound : Int32) -> Int32 {
  self.state = self.state * 6364136223846793005L + 1442695040888963407L
  let x = (self.state >> 33) & 0x7fffffffL
  (x % bound.to_int64()).to_int()
}

///|
fn GwRng::chance(self : GwRng, percent : Int32) -> Bool {
  self.below(100) < percent
}

///|
let gw_doubles : Array[Double] = [
  0.0,
  -0.0,
  1.0,
  -1.0,
  1.5,
  -2.25,
  0.1,
  0.2,
  0.3,
  1.0e300,
  -1.0e300,
  1.0e-300,
  123456.789,
  -0.5,
  0.0 / 0.0,
  1.0 / 0.0,
  -1.0 / 0.0,
]

///|
let gw_words : Array[String] = [
  "", "a", "b", "ab", "abc", "B", "\u{e9}", "\u{1F600}", "zz", "0",
]

///|
/// One column of each kind with `n` rows, a fifth of the rows null.
fn gw_columns(rng : GwRng, n : Int32) -> Array[Column] {
  let out : Array[Column] = []
  let nul = () => rng.chance(20)
  let bools : Array[Bool?] = []
  let i32s : Array[Int32?] = []
  let i64s : Array[Int64?] = []
  let f32s : Array[Float?] = []
  let f64s : Array[Double?] = []
  let strs : Array[String?] = []
  let dates : Array[Int32?] = []
  let dts : Array[Int64?] = []
  for _ in 0..<n {
    bools.push(if nul() { None } else { Some(rng.chance(50)) })
    i32s.push(if nul() { None } else { Some(rng.below(9) - 4) })
    i64s.push(
      if nul() {
        None
      } else if rng.chance(10) {
        Some(9223372036854775800L + rng.below(8).to_int64())
      } else {
        Some((rng.below(2001) - 1000).to_int64())
      },
    )
    f32s.push(
      if nul() {
        None
      } else {
        Some(Float::from_double(gw_doubles[rng.below(gw_doubles.length())]))
      },
    )
    f64s.push(
      if nul() {
        None
      } else {
        Some(gw_doubles[rng.below(gw_doubles.length())])
      },
    )
    strs.push(
      if nul() {
        None
      } else {
        Some(gw_words[rng.below(gw_words.length())])
      },
    )
    dates.push(if nul() { None } else { Some(rng.below(40) - 10) })
    dts.push(
      if nul() {
        None
      } else {
        Some((rng.below(5000) - 2000).to_int64() * 1000000L)
      },
    )
  }
  out.push(Boolean(@arrow.BoolArray::from_options(bools)))
  out.push(Int32(@arrow.PrimArray::from_options(i32s)))
  out.push(Int64(@arrow.PrimArray::from_options(i64s)))
  out.push(Float32(@arrow.PrimArray::from_options(f32s)))
  out.push(Float64(@arrow.PrimArray::from_options(f64s)))
  out.push(String(@arrow.StrArray::from_options(strs)))
  out.push(Date(@arrow.PrimArray::from_options(dates)))
  out.push(Datetime(@arrow.PrimArray::from_options(dts)))
  out.push(Null(n))
  out
}

///|
/// Whether two columns hold the same type, the same nulls and bit for bit the
/// same values (a NaN is a NaN whatever its payload).
fn gw_same(a : Column, b : Column) -> Bool {
  let x = Series::make("x", a)
  let y = Series::make("x", b)
  if !x.equals(y) {
    return false
  }
  let xs = x.to_list()
  let ys = y.to_list()
  for i in 0..<xs.length() {
    match (xs[i], ys[i]) {
      (Float64(p), Float64(q)) =>
        if !p.is_nan() && p.reinterpret_as_int64() != q.reinterpret_as_int64() {
          return false
        }
      (Float32(p), Float32(q)) =>
        if !p.is_nan() && p.reinterpret_as_int() != q.reinterpret_as_int() {
          return false
        }
      _ => ()
    }
  }
  true
}

///|
let gw_ops : Array[AggOp] = [
  Sum,
  Mean,
  Min,
  Max,
  Count,
  Len,
  First,
  Last,
  Std(0),
  Std(1),
  Var(0),
  Var(1),
  Var(-1),
  Median,
  Quantile(0.5, Nearest),
  Quantile(0.3, Linear),
  Quantile(0.7, Lower),
  Quantile(0.25, Midpoint),
  Product,
]

///|
/// What the per-group reference gives: the `group_agg_column` of the rows of
/// each group under one another, or the first error.
fn gw_reference(
  col : Column,
  groups : GroupIndex,
  op : AggOp,
  one : (Column, AggOp) -> Column raise PolarsError,
) -> Result[Column, String] {
  let parts : Array[Column] = []
  for g in 0..<groups.length() {
    let part = one(col.gather(groups.rows(g).to_owned()), op) catch {
      e => return Err(e.to_string())
    }
    parts.push(part)
  }
  Ok(Column::concat(parts))
}

///|
fn gw_check(
  col : Column,
  groups : GroupIndex,
  op : AggOp,
  what : String,
  one~ : (Column, AggOp) -> Column raise PolarsError = group_agg_column,
) -> Unit raise {
  let expected = gw_reference(col, groups, op, one)
  let actual : Result[Column, String] = Ok(grouped_agg(col, groups, op)) catch {
    e => Err(e.to_string())
  }
  match (expected, actual) {
    (Ok(e), Ok(a)) =>
      if !gw_same(e, a) {
        fail(
          "\{what} \{op.name()}: expected \{@debug.to_string(Series::make("x", e).to_list())}, got \{@debug.to_string(Series::make("x", a).to_list())}",
        )
      }
    (Err(e), Err(a)) =>
      if e != a {
        fail("\{what} \{op.name()}: expected the error \{e}, got \{a}")
      }
    (Ok(_), Err(a)) => fail("\{what} \{op.name()}: unexpected error \{a}")
    (Err(e), Ok(_)) =>
      fail("\{what} \{op.name()}: expected the error \{e}, got a column")
  }
}

///|
/// A group key column of `n` rows: `groups` distinct small values and nulls.
fn gw_key(rng : GwRng, n : Int32, kinds : Int32) -> Column {
  let ks : Array[Int32?] = []
  for _ in 0..<n {
    ks.push(if rng.chance(10) { None } else { Some(rng.below(kinds)) })
  }
  Int32(@arrow.PrimArray::from_options(ks))
}

///|
test "grouped_agg gives group by group what group_agg_column gives" {
  let rng = GwRng::new(7L)
  // heights, and how many different keys there are
  for
    shape in [
      (1, 1),
      (2, 1),
      (2, 2),
      (7, 3),
      (30, 1),
      (30, 4),
      (60, 60),
      (200, 5),
      (300, 140),
    ] {
    let (n, kinds) = shape
    let cols = gw_columns(rng, n)
    let groups = GroupIndex::from_keys([gw_key(rng, n, kinds)], n)
    for i in 0..<cols.length() {
      for op in gw_ops {
        gw_check(cols[i], groups, op, "n=\{n} kinds=\{kinds} column \{i}")
      }
    }
  }
}

///|
/// Everything but the float `sum`, `mean`, `std` and `var` is what
/// `agg_column` gives on the rows of the group.
test "grouped_agg is agg_column except for float sum, mean, std and var" {
  let rng = GwRng::new(11L)
  for shape in [(3, 2), (40, 3), (150, 7)] {
    let (n, kinds) = shape
    let cols = gw_columns(rng, n)
    let groups = GroupIndex::from_keys([gw_key(rng, n, kinds)], n)
    for i in 0..<cols.length() {
      for op in gw_ops {
        let float_flavour = match (op, cols[i]) {
          (Mean | Std(_) | Var(_), _) => true
          (Sum, Float32(_) | Float64(_)) => true
          _ => false
        }
        if !float_flavour {
          gw_check(cols[i], groups, op, "n=\{n} column \{i}", one=agg_column)
        }
      }
    }
  }
}

///|
test "grouped_agg on a frame without rows" {
  let rng = GwRng::new(3L)
  let cols = gw_columns(rng, 0)
  // keys next to no rows: no group at all, and the type of the empty result
  let none = GroupIndex::from_keys([gw_key(rng, 0, 3)], 0)
  assert_eq(none.length(), 0)
  for c in cols {
    for op in gw_ops {
      let expected : Result[DataType, String] = Ok(agg_column(c, op).dtype()) catch {
        e => Err(e.to_string())
      }
      let actual : Result[(DataType, Int32), String] = Ok(
        {
          let r = grouped_agg(c, none, op)
          (r.dtype(), r.length())
        },
      ) catch {
        e => Err(e.to_string())
      }
      match (expected, actual) {
        (Ok(t), Ok((u, len))) => {
          assert_eq(len, 0)
          assert_eq(u, t)
        }
        (Err(e), Err(a)) => assert_eq(e, a)
        _ => fail("\{op.name()} on \{c.dtype()}: raises on one side only")
      }
    }
  }
  // no key and no rows: one group of no rows
  let one = GroupIndex::from_keys([], 0)
  assert_eq(one.length(), 1)
  assert_eq(one.rows(0).length(), 0)
  for c in cols {
    for op in gw_ops {
      gw_check(c, one, op, "no key, no rows, \{c.dtype()}")
    }
  }
}

///|
test "grouped_n_unique counts each group's distinct values" {
  let rng = GwRng::new(5L)
  for shape in [(1, 1), (12, 2), (80, 3), (300, 11)] {
    let (n, kinds) = shape
    let cols = gw_columns(rng, n)
    let groups = GroupIndex::from_keys([gw_key(rng, n, kinds)], n)
    for c in cols {
      let got = grouped_n_unique(c, groups)
      let parts : Array[Column] = []
      for g in 0..<groups.length() {
        parts.push(
          Int64(
            @arrow.PrimArray::from_array([
              Series::make("x", c.gather(groups.rows(g).to_owned()))
              .n_unique()
              .to_int64(),
            ]),
          ),
        )
      }
      assert_true(gw_same(got, Column::concat(parts)))
    }
  }
}

///|
test "group_agg_column returns the value of a one-row group, even -0.0" {
  let neg = Column::Float64(@arrow.PrimArray::from_array([-0.0]))
  let s = group_agg_column(neg, Sum)
  assert_true(gw_same(s, neg))
  let m = group_agg_column(neg, Mean)
  assert_true(gw_same(m, neg))
  let two = Column::Float64(@arrow.PrimArray::from_array([-0.0, -0.0]))
  let t = group_agg_column(two, Sum)
  assert_true(gw_same(t, Float64(@arrow.PrimArray::from_array([0.0]))))
}

///|
/// The sum of a group of a key column is Kahan's, not the pairwise sum of a
/// column: the first is exact here, the second is not. With no key (one group
/// by construction) polars uses the pairwise sum of `select`.
test "the float sum of a group is the Kahan sum" {
  let xs : Array[Double] = []
  for _ in 0..<200 {
    xs.push(0.1)
  }
  let col = Column::Float64(@arrow.PrimArray::from_array(xs))
  let one_key = Column::Int32(@arrow.PrimArray::from_array(Array::make(200, 7)))
  let groups = GroupIndex::from_keys([one_key], 200)
  assert_false(groups.whole)
  let got = grouped_agg(col, groups, Sum)
  assert_true(
    gw_same(got, Float64(@arrow.PrimArray::from_array([kahan_sum(xs)]))),
  )
  assert_true(gw_same(got, group_agg_column(col, Sum)))
  // no key: the kernel of `select`, which is not Kahan's here
  let whole = GroupIndex::from_keys([], 200)
  assert_true(whole.whole)
  let w = grouped_agg(col, whole, Sum)
  assert_true(gw_same(w, agg_column(col, Sum)))
  assert_false(gw_same(w, got))
  // a mean is the same, and the aggregations without such a difference are not touched
  assert_true(gw_same(grouped_agg(col, whole, Mean), agg_column(col, Mean)))
  assert_true(gw_same(grouped_agg(col, whole, Min), agg_column(col, Min)))
}

///|
/// Checks the three promises of an index on a set of keys.
fn gw_check_index(keys : Array[Column], n : Int32) -> Unit raise {
  let g = GroupIndex::from_keys(keys, n)
  let firsts = g.first_rows()
  assert_eq(firsts.length(), g.length())
  // groups come in order of first appearance
  let mut next = 0
  for i in 0..<n {
    let id = g.group_of(i)
    if id > next {
      fail("row \{i} is in group \{id} before group \{next} appeared")
    }
    if id == next {
      assert_eq(firsts[id], i)
      next += 1
    }
  }
  assert_eq(next, g.length())
  // `rows` ascend, cover every row once, and hold rows of equal keys
  let seen : Array[Bool] = Array::make(n, false)
  let mut total = 0
  for id in 0..<g.length() {
    let rows = g.rows(id)
    assert_eq(rows.length(), g.size(id))
    total += rows.length()
    for j in 0..<rows.length() {
      let r = rows[j]
      if j > 0 && rows[j - 1] >= r {
        fail("rows of group \{id} do not ascend")
      }
      if seen[r] {
        fail("row \{r} is in two groups")
      }
      seen[r] = true
      assert_eq(g.group_of(r), id)
      for k in keys {
        if !k.eq_at(r, k, firsts[id]) {
          fail("row \{r} of group \{id} has another key than its first row")
        }
      }
    }
    // and different groups have different keys
    for other in 0..<id {
      let mut same = keys.length() > 0
      for k in keys {
        if !k.eq_at(firsts[id], k, firsts[other]) {
          same = false
        }
      }
      if same {
        fail("groups \{other} and \{id} have the same key")
      }
    }
  }
  assert_eq(total, n)
}

///|
test "GroupIndex numbers groups by first appearance and lists their rows" {
  let rng = GwRng::new(13L)
  for n in [0, 1, 2, 5, 40, 120] {
    let cols = gw_columns(rng, n)
    // each kind of column on its own (nulls and NaNs are keys)
    for c in cols {
      gw_check_index([c], n)
    }
    gw_check_index([cols[1], cols[5]], n)
    gw_check_index([cols[1], cols[4], cols[5]], n)
    gw_check_index([gw_key(rng, n, 3), gw_key(rng, n, 2)], n)
  }
}

///|
test "GroupIndex without key columns is one group of every row" {
  let g = GroupIndex::from_keys([], 4)
  assert_eq(g.length(), 1)
  assert_eq(g.rows(0).to_owned(), [0, 1, 2, 3])
  assert_eq(g.first_rows(), [0])
  let e = GroupIndex::from_keys([], 0)
  assert_eq(e.length(), 1)
  assert_eq(e.rows(0).length(), 0)
}

///|
test "GroupIndex treats null, NaN and -0.0 as keys of their own" {
  let nan = 0.0 / 0.0
  let c = Column::Float64(
    @arrow.PrimArray::from_options([
      Some(0.0),
      None,
      Some(nan),
      Some(-0.0),
      None,
      Some(-nan),
      Some(1.0),
    ]),
  )
  let g = GroupIndex::from_keys([c], 7)
  assert_eq(g.length(), 4)
  assert_eq(g.rows(0).to_owned(), [0, 3])
  assert_eq(g.rows(1).to_owned(), [1, 4])
  assert_eq(g.rows(2).to_owned(), [2, 5])
  assert_eq(g.rows(3).to_owned(), [6])
}

///|
test "GroupIndex::ghost is one group without rows" {
  let g = GroupIndex::ghost()
  assert_eq(g.length(), 1)
  assert_eq(g.rows(0).length(), 0)
}

///|
test "last_rows and sizes" {
  let g = GroupIndex::from_keys(
    [Int32(@arrow.PrimArray::from_array([5, 6, 5, 6, 7]))],
    5,
  )
  assert_eq(g.last_rows(), [2, 3, 4])
  assert_eq(g.sizes(), [2, 2, 1])
}

///|
test "is_row_level and is_group_scalar classify every arm" {
  let c = ExprNode::Column("a")
  let lit = ExprNode::Literal(AnyValue::Int64(1L), LitKind::WeakInt)
  let sum = ExprNode::Agg(Sum, c)
  // row level: columns, literals and what is built element by element on them
  for
    n in [
      c,
      lit,
      Neg(c),
      Not(c),
      Alias(c, "z"),
      Binary(Add, c, lit),
      Cast(c, DataType::Float64, true),
      IsNull(c),
      FillNull(c, lit),
    ] {
    assert_true(is_row_level(n))
  }
  // not row level: they look at the group
  for
    n in [
      sum,
      NUnique(c),
      Len,
      Seq(CumSum(false), c),
      Binary(Add, c, sum),
      All,
      Columns(["a"]),
      // the format is guessed from the first value of each group
      Str(ToDate(true), c),
      Str(ToDatetime(false), c),
      Alias(Str(ToDate(false), c), "z"),
      Binary(Add, Str(ToDate(true), c), lit),
    ] {
    assert_false(is_row_level(n))
  }
  // one value per group
  for
    n in [
      sum,
      NUnique(c),
      Len,
      lit,
      Binary(Add, sum, lit),
      Seq(CumSum(false), sum),
      Alias(sum, "z"),
    ] {
    assert_true(is_group_scalar(n))
  }
  for
    n in [
      c,
      Neg(c),
      Binary(Add, c, sum),
      Seq(CumSum(false), c),
      All,
      Columns(["a"]),
    ] {
    assert_false(is_group_scalar(n))
  }
}
