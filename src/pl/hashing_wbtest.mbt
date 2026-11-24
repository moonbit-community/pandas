///|
fn hw_f64(vals : Array[Double?]) -> Column {
  Column::Float64(@arrow.PrimArray::from_options(vals))
}

///|
test "hash_at and eq_at: null equals null, NaN equals NaN, -0.0 equals 0.0" {
  let nan = 0.0 / 0.0
  let c = hw_f64([
    Some(nan),
    Some(-nan),
    None,
    None,
    Some(0.0),
    Some(-0.0),
    Some(1.0),
  ])
  assert_true(c.eq_at(0, c, 1))
  assert_eq(c.hash_at(0), c.hash_at(1))
  assert_true(c.eq_at(2, c, 3))
  assert_eq(c.hash_at(2), c.hash_at(3))
  assert_true(c.eq_at(4, c, 5))
  assert_eq(c.hash_at(4), c.hash_at(5))
  assert_false(c.eq_at(0, c, 6))
  assert_false(c.eq_at(2, c, 4))
  assert_false(c.eq_at(4, c, 6))
}

///|
test "hash_at and eq_at work across two columns of one type" {
  let a = Column::String(
    @arrow.StrArray::from_options([Some("x"), None, Some("\u{1F600}")]),
  )
  let b = Column::String(
    @arrow.StrArray::from_options([Some("\u{1F600}"), Some("x"), None]),
  )
  assert_true(a.eq_at(0, b, 1))
  assert_eq(a.hash_at(0), b.hash_at(1))
  assert_true(a.eq_at(1, b, 2))
  assert_true(a.eq_at(2, b, 0))
  assert_eq(a.hash_at(2), b.hash_at(0))
  assert_false(a.eq_at(0, b, 0))
}

///|
test "hash_at and eq_at for every column kind" {
  let kinds : Array[Column] = [
    Column::Boolean(
      @arrow.BoolArray::from_options([Some(true), Some(false), None, Some(true)]),
    ),
    Column::Int32(
      @arrow.PrimArray::from_options([Some(1), Some(-1), None, Some(1)]),
    ),
    Column::Int64(
      @arrow.PrimArray::from_options([
        Some(1L),
        Some(@int64.MAX_VALUE),
        None,
        Some(1L),
      ]),
    ),
    Column::Float32(
      @arrow.PrimArray::from_options([
        Some(Float::from_int(1)),
        Some(-0.0),
        None,
        Some(Float::from_int(1)),
      ]),
    ),
    Column::Float64(
      @arrow.PrimArray::from_options([Some(1.0), Some(2.0), None, Some(1.0)]),
    ),
    Column::String(
      @arrow.StrArray::from_options([Some("a"), Some(""), None, Some("a")]),
    ),
    Column::Date(
      @arrow.PrimArray::from_options([Some(1), Some(2), None, Some(1)]),
    ),
    Column::Datetime(
      @arrow.PrimArray::from_options([Some(1L), Some(2L), None, Some(1L)]),
    ),
  ]
  for c in kinds {
    assert_true(c.eq_at(0, c, 3))
    assert_eq(c.hash_at(0), c.hash_at(3))
    assert_false(c.eq_at(0, c, 1))
    assert_false(c.eq_at(0, c, 2))
    assert_false(c.eq_at(2, c, 1))
    assert_true(c.eq_at(2, c, 2))
  }
  let n = Column::Null(3)
  assert_true(n.eq_at(0, n, 2))
  assert_eq(n.hash_at(0), n.hash_at(2))
  // different kinds never compare equal
  assert_false(kinds[1].eq_at(0, kinds[2], 0))
}

///|
test "hash_at spreads distinct Int64 values" {
  let n = 4096
  let c = Column::Int64(
    @arrow.PrimArray::from_array(Array::makei(n, i => (i * 4096).to_int64())),
  )
  let seen : Array[Bool] = Array::make(8192, false)
  let mut distinct = 0
  for i in 0..<n {
    let b = c.hash_at(i) & 8191
    if !seen[b] {
      seen[b] = true
      distinct += 1
    }
  }
  // 4096 keys into 8192 buckets: a good mix fills well over a third
  assert_true(distinct > 2500)
}

///|
test "unique_row_indices of no columns is empty and keeps row order" {
  assert_eq(unique_row_indices([], UniqueKeep::First), [])
  let c = Column::Int32(@arrow.PrimArray::from_array([5, 5, 6, 5, 7]))
  assert_eq(unique_row_indices([c], UniqueKeep::First), [0, 2, 4])
  assert_eq(unique_row_indices([c], UniqueKeep::Any), [0, 2, 4])
  assert_eq(unique_row_indices([c], UniqueKeep::Last), [2, 3, 4])
  assert_eq(unique_row_indices([c], UniqueKeep::KeepNone), [2, 4])
  assert_eq(unique_row_indices([Column::Null(3)], UniqueKeep::First), [0])
  assert_eq(unique_row_indices([Column::Null(3)], UniqueKeep::Last), [2])
  assert_eq(unique_row_indices([Column::Null(3)], UniqueKeep::KeepNone), [])
}

///|
test "arg_sort_columns: three keys, mixed flags, empty and single row" {
  let a = Column::Int32(
    @arrow.PrimArray::from_options([Some(1), Some(1), None, Some(1), None]),
  )
  let b = Column::String(
    @arrow.StrArray::from_options([
      Some("b"),
      Some("a"),
      Some("z"),
      Some("a"),
      Some("z"),
    ]),
  )
  let c = Column::Boolean(
    @arrow.BoolArray::from_array([true, false, true, true, false]),
  )
  assert_eq(
    arg_sort_columns([a, b, c], [false, true, false], [true, false, false]),
    [0, 1, 3, 4, 2],
  )
  assert_eq(arg_sort_columns([], [], []), [])
  assert_eq(
    arg_sort_columns(
      [Column::Int32(@arrow.PrimArray::from_array([]))],
      [false],
      [false],
    ),
    [],
  )
  assert_eq(arg_sort_columns([c], [true], [false]), [0, 2, 3, 1, 4])
  assert_eq(
    arg_sort_columns([Column::Null(5), c], [false, false], [false, false]),
    [1, 4, 0, 2, 3],
  )
}

///|
/// Number of distinct values among `hashes` (a hash set over the full 32 bits
/// would be enough; a sort keeps it simple and allocation-light).
fn hw_distinct(hashes : Array[Int32]) -> Int32 {
  let sorted = hashes.copy()
  sorted.sort()
  let mut d = 0
  for i in 0..<sorted.length() {
    if i == 0 || sorted[i] != sorted[i - 1] {
      d += 1
    }
  }
  d
}

///|
/// Spread check: at least 90% of the rows must have a distinct hash. A hash
/// that only loses information (ignores a half, a column or the string) is
/// still correct but turns `unique` / joins quadratic.
fn hw_assert_spread(name : String, hashes : Array[Int32]) -> Unit raise {
  let d = hw_distinct(hashes)
  if d * 10 < hashes.length() * 9 {
    fail("\{name}: only \{d} distinct hashes for \{hashes.length()} rows")
  }
}

///|
test "hash spread: composite Int64 ids (shard << 32) | seq" {
  let n = 200000
  let c = Column::Int64(
    @arrow.PrimArray::from_array(
      Array::makei(n, i => ((i / 2000).to_int64() << 32) | (i % 2000).to_int64()),
    ),
  )
  hw_assert_spread("int64 composite", Array::makei(n, i => c.hash_at(i)))
  // the same values as Datetime and as row hashes
  let t = Column::Datetime(
    @arrow.PrimArray::from_array(
      Array::makei(n, i => ((i / 2000).to_int64() << 32) | (i % 2000).to_int64()),
    ),
  )
  hw_assert_spread("datetime composite", Array::makei(n, i => t.hash_at(i)))
  hw_assert_spread("row_hash composite", Array::makei(n, i => row_hash([c], i)))
}

///|
test "hash spread: strings with a long common prefix and floats" {
  let n = 10000
  let strs = Column::String(
    @arrow.StrArray::from_array(
      Array::makei(n, i => {
        let d = i.to_string()
        "user_" + String::make(6 - d.length(), '0') + d
      }),
    ),
  )
  hw_assert_spread("strings", Array::makei(n, i => strs.hash_at(i)))
  let f = Column::Float64(
    @arrow.PrimArray::from_array(Array::makei(n, i => i.to_double() * 0.5)),
  )
  hw_assert_spread("float64", Array::makei(n, i => f.hash_at(i)))
  let g = Column::Float32(
    @arrow.PrimArray::from_array(Array::makei(n, i => Float::from_int(i))),
  )
  hw_assert_spread("float32", Array::makei(n, i => g.hash_at(i)))
  let d = Column::Date(@arrow.PrimArray::from_array(Array::makei(n, i => i)))
  hw_assert_spread("date", Array::makei(n, i => d.hash_at(i)))
}

///|
test "hash spread: row_hash with two columns where only the second varies" {
  let n = 10000
  let a = Column::Int32(@arrow.PrimArray::from_array(Array::make(n, 7)))
  let b = Column::Int64(
    @arrow.PrimArray::from_array(Array::makei(n, i => i.to_int64())),
  )
  hw_assert_spread(
    "second column only",
    Array::makei(n, i => row_hash([a, b], i)),
  )
  // and only the first varies, and a swapped pair (i, j) vs (j, i)
  hw_assert_spread(
    "first column only",
    Array::makei(n, i => row_hash([b, a], i)),
  )
  let x = Column::Int32(
    @arrow.PrimArray::from_array(Array::makei(n, i => i / 100)),
  )
  let y = Column::Int32(
    @arrow.PrimArray::from_array(Array::makei(n, i => i % 100)),
  )
  hw_assert_spread("grid", Array::makei(n, i => row_hash([x, y], i)))
  hw_assert_spread("grid swapped", Array::makei(n, i => row_hash([y, x], i)))
}

///|
/// 16 pairs of three-character blocks: every choice of one block per pair gives a
/// string of 48 characters, and all 65536 of them collide under 32-bit FNV-1a
/// over UTF-16 code units, the hash the library used before the 64-bit one
/// (a Joux multicollision, built by `fw-scripts/collide.py` of the fix wave).
fn collision_pairs() -> Array[(String, String)] {
  [
    ("酈瞌給", "鉣譋貜"),
    ("朸骅綎", "碑惘鼄"),
    ("茪數礹", "獈聜澷"),
    ("蕙輊袑", "畅餙悘"),
    ("躄堓踞", "蘄蔧递"),
    ("填悕貒", "韼彎垔"),
    ("体鶤悶", "糺裧垪"),
    ("余謋韺", "勰寚兜"),
    ("笛匬奾", "虤葀才"),
    ("于寙安", "辠峤用"),
    ("讎反猢", "坱凜塖"),
    ("棹灡緤", "膚纤杔"),
    ("臆環柳", "佾敨瓳"),
    ("踦隩烗", "嚀罱忽"),
    ("郠牕贿", "欯蠣蹺"),
    ("衦咘历", "鞞嶶蝌"),
  ]
}

///|
/// The 65536 strings of the multicollision table.
fn hw_collision_strings() -> Array[String] {
  let pairs = collision_pairs()
  Array::makei(65536, i => {
    let sb = StringBuilder()
    for k in 0..<16 {
      let (a, b) = pairs[k]
      sb.write_string(if ((i >> k) & 1) == 0 { a } else { b })
    }
    sb.to_string()
  })
}

///|
/// The 32-bit FNV-1a over UTF-16 code units that `hash_string` used to be
/// (before the finalizer).
fn hw_fnv32(s : String) -> UInt32 {
  let mut h = 0x811c9dc5U
  for i in 0..<s.length() {
    h = (h ^ s.unsafe_get(i).to_int().reinterpret_as_uint()) * 16777619U
  }
  h
}

///|
/// Distinct values among the low 16 bits of `hashes` (the table index of a
/// 65536-slot table).
fn hw_distinct_low16(hashes : Array[Int32]) -> Int32 {
  hw_distinct(hashes.map(h => h & 0xffff))
}

///|
test "string hash: multicollision strings of the old FNV-1a spread" {
  let strs = hw_collision_strings()
  // the construction really collides under the old hash
  let first = hw_fnv32(strs[0])
  for s in strs {
    assert_eq(hw_fnv32(s), first)
  }
  assert_eq(hw_distinct(strs.map(s => s.length())), 1)
  let hashes = strs.map(s => hash_string(s))
  let d = hw_distinct(hashes)
  if d < 65000 {
    fail("only \{d} distinct hashes for 65536 colliding strings")
  }
  let low = hw_distinct_low16(hashes)
  if low < 35000 {
    fail("only \{low} distinct low 16 bits for 65536 colliding strings")
  }
}

///|
test "string hash: unique, is_in and n_unique on the multicollision strings" {
  let strs = hw_collision_strings()
  let s = Series::str("s", strs)
  assert_eq(s.unique().len(), 65536)
  assert_eq(s.n_unique(), 65536)
  // every string is in itself, none of them in a shifted copy of the table
  let inn = s.is_in(s)
  assert_eq(inn.to_bool_array().filter(x => x == Some(true)).length(), 65536)
  let other = Series::str("o", strs.map(x => x + "x"))
  let out = s.is_in(other)
  assert_eq(out.to_bool_array().filter(x => x == Some(true)).length(), 0)
  // DataFrame::unique takes the same path
  let df = DataFrame::new([s])
  assert_eq(df.unique().height(), 65536)
}

///|
test "string hash: strings that differ only in the last four characters" {
  let letters = "abcdefghijklmnop"
  let prefix = "a-common-prefix-of-some-length-0123456789-"
  let strs : Array[String] = Array::makei(65536, i => {
    let sb = StringBuilder()
    sb.write_string(prefix)
    for k in 0..<4 {
      sb.write_char(letters[(i >> (4 * k)) & 15].to_int().unsafe_to_char())
    }
    sb.to_string()
  })
  let hashes = strs.map(s => hash_string(s))
  let d = hw_distinct(hashes)
  if d < 65000 {
    fail("only \{d} distinct hashes")
  }
  let low = hw_distinct_low16(hashes)
  if low < 35000 {
    fail("only \{low} distinct low 16 bits")
  }
}

///|
test "string hash: length, trailing code units and lane boundaries" {
  // equal strings hash equally, different lengths and tails differ
  let seen : Array[Int32] = []
  for n in 0..<40 {
    let s = "a".repeat(n)
    assert_eq(hash_string(s), hash_string("a".repeat(n)))
    seen.push(hash_string(s))
  }
  assert_eq(hw_distinct(seen), 40)
  assert_true(hash_string("a") != hash_string("a\u{0}"))
  assert_true(hash_string("") != hash_string("\u{0}"))
  assert_true(hash_string("abcd") != hash_string("abce"))
  assert_true(hash_string("abcde") != hash_string("abcdf"))
  assert_true(hash_string("abcdefgh") != hash_string("abcdefgi"))
  // a supplementary character is two code units
  assert_true(hash_string("\u{1F600}") != hash_string("\u{1F601}"))
  assert_eq(hash_string("\u{1F600}"), hash_string("\u{1F600}"))
}
