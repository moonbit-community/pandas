///|
/// Final avalanche step of the 32-bit murmur3 hash, so that the low bits of
/// a table index depend on every input bit.
fn hash_finalize(h : Int32) -> Int32 {
  let mut x = h.reinterpret_as_uint()
  x = x ^ (x >> 16)
  x = x * 0x85ebca6bU
  x = x ^ (x >> 13)
  x = x * 0xc2b2ae35U
  x = x ^ (x >> 16)
  x.reinterpret_as_int()
}

///|
/// Hash of a 64-bit value: the two 32-bit halves are scrambled separately
/// (murmur3 `x86` steps), added into each other and pushed through `fmix32`,
/// so that every bit of both halves reaches every output bit. A linear fold
/// of the halves would collide on packed keys such as `(shard << 32) | seq`.
/// 32-bit multiplications only: 64-bit ones are emulated on the JavaScript
/// backend (an `fmix64` version made integer hashing 4 to 5 times slower
/// there).
fn hash_int64(v : Int64) -> Int32 {
  let k1 = hash_scramble(
    v.to_int().reinterpret_as_uint(),
    0x239b961bU,
    0xab0e9789U,
  )
  let k2 = hash_scramble(
    (v >> 32).to_int().reinterpret_as_uint(),
    0xab0e9789U,
    0x239b961bU,
  )
  let mut h1 = 0x9e3779b9U ^ k1
  let mut h2 = 0x7f4a7c15U ^ k2
  h1 = h1 + h2
  h2 = h2 + h1
  h1 = hash_finalize(h1.reinterpret_as_int()).reinterpret_as_uint()
  h2 = hash_finalize(h2.reinterpret_as_int()).reinterpret_as_uint()
  h1 = h1 + h2
  h2 = h2 + h1
  (h1 ^ hash_rotl32(h2, 16)).reinterpret_as_int()
}

///|
fn hash_rotl32(x : UInt32, r : Int32) -> UInt32 {
  (x << r) | (x >> (32 - r))
}

///|
/// The murmur3 `x86_32` per-word step for a lane: scramble `k`.
fn hash_scramble(k : UInt32, c1 : UInt32, c2 : UInt32) -> UInt32 {
  hash_rotl32(k * c1, 15) * c2
}

///|
/// Up to two UTF-16 code units from index `i` as one 32-bit word, the first
/// one in the low 16 bits.
fn hash_string_word(s : String, i : Int32, count : Int32) -> UInt32 {
  if count >= 2 {
    s.unsafe_get(i).to_int().reinterpret_as_uint() |
    (s.unsafe_get(i + 1).to_int().reinterpret_as_uint() << 16)
  } else if count == 1 {
    s.unsafe_get(i).to_int().reinterpret_as_uint()
  } else {
    0U
  }
}

///|
/// Hash of the string by UTF-16 code unit (equal strings hash equally): a
/// 64-bit state in two 32-bit lanes (the murmur3 `x86_128` scheme with two
/// lanes). The units are read four at a time (8 bytes), each half into its own
/// lane, the lanes are mixed into each other after every block, the length
/// goes in at the end, and both lanes pass through `fmix32` before they are
/// folded to the 32 bits returned. It is deterministic (no random seed) so
/// that results are reproducible. The 32-bit FNV-1a it replaces could be made
/// to collide in bulk with a multicollision construction, which turned
/// `unique` and `is_in` quadratic. The lanes use 32-bit multiplications only:
/// 64-bit ones are emulated on the JavaScript backend and made the string
/// hash 6 times slower there.
fn hash_string(s : String) -> Int32 {
  let c1 = 0x239b961bU
  let c2 = 0xab0e9789U
  let n = s.length()
  let len = n.reinterpret_as_uint()
  let mut h1 = 0x9e3779b9U
  let mut h2 = 0x7f4a7c15U
  let mut i = 0
  while i + 4 <= n {
    let k1 = hash_scramble(hash_string_word(s, i, 2), c1, c2)
    let k2 = hash_scramble(hash_string_word(s, i + 2, 2), c2, c1)
    h1 = hash_rotl32(h1 ^ k1, 19)
    h1 = (h1 + h2) * 5U + 0x561ccd1bU
    h2 = hash_rotl32(h2 ^ k2, 17)
    h2 = (h2 + h1) * 5U + 0x0bcaa747U
    i += 4
  }
  let rem = n - i
  if rem > 0 {
    let k1 = hash_scramble(hash_string_word(s, i, rem), c1, c2)
    h1 = h1 ^ k1
    if rem > 2 {
      let k2 = hash_scramble(hash_string_word(s, i + 2, rem - 2), c2, c1)
      h2 = h2 ^ k2
    }
  }
  h1 = h1 ^ len
  h2 = h2 ^ len
  h1 = h1 + h2
  h2 = h2 + h1
  h1 = hash_finalize(h1.reinterpret_as_int()).reinterpret_as_uint()
  h2 = hash_finalize(h2.reinterpret_as_int()).reinterpret_as_uint()
  h1 = h1 + h2
  h2 = h2 + h1
  (h1 ^ hash_rotl32(h2, 16)).reinterpret_as_int()
}

///|
/// Hash of the value in row `i`, consistent with `eq_at`: every null (and
/// every row of a `Null` column) hashes alike, all NaNs hash alike and
/// `-0.0` hashes like `0.0`.
fn Column::hash_at(self : Column, i : Int32) -> Int32 {
  match self {
    Boolean(a) =>
      if a.is_valid(i) {
        if a.value(i) {
          0x2545f491
        } else {
          0x1b873593
        }
      } else {
        0x7f4a7c15
      }
    Int32(a) | Date(a) =>
      if a.is_valid(i) {
        hash_finalize(a.value(i))
      } else {
        0x7f4a7c15
      }
    Int64(a) | Datetime(a) =>
      if a.is_valid(i) {
        hash_int64(a.value(i))
      } else {
        0x7f4a7c15
      }
    Float32(a) =>
      if a.is_valid(i) {
        let x = a.value(i)
        if x != x {
          0x7ff80000
        } else if x == 0.0 {
          0
        } else {
          hash_finalize(x.reinterpret_as_int())
        }
      } else {
        0x7f4a7c15
      }
    Float64(a) =>
      if a.is_valid(i) {
        let x = a.value(i)
        if x != x {
          0x7ff80000
        } else if x == 0.0 {
          0
        } else {
          hash_int64(x.reinterpret_as_int64())
        }
      } else {
        0x7f4a7c15
      }
    String(a) =>
      if a.is_valid(i) {
        hash_string(a.value(i))
      } else {
        0x7f4a7c15
      }
    Null(_) => 0x7f4a7c15
  }
}

///|
/// Whether row `i` of `self` and row `j` of `other` hold the same value. Both
/// columns must have the same type, otherwise the answer is `false`. A null
/// equals a null, NaN equals NaN and `-0.0` equals `0.0`.
fn Column::eq_at(self : Column, i : Int32, other : Column, j : Int32) -> Bool {
  match (self, other) {
    (Boolean(a), Boolean(b)) =>
      match (a.is_valid(i), b.is_valid(j)) {
        (true, true) => a.value(i) == b.value(j)
        (x, y) => x == y
      }
    (Int32(a), Int32(b)) | (Date(a), Date(b)) =>
      match (a.is_valid(i), b.is_valid(j)) {
        (true, true) => a.value(i) == b.value(j)
        (x, y) => x == y
      }
    (Int64(a), Int64(b)) | (Datetime(a), Datetime(b)) =>
      match (a.is_valid(i), b.is_valid(j)) {
        (true, true) => a.value(i) == b.value(j)
        (x, y) => x == y
      }
    (Float32(a), Float32(b)) =>
      match (a.is_valid(i), b.is_valid(j)) {
        (true, true) => {
          let x = a.value(i)
          let y = b.value(j)
          x == y || (x != x && y != y)
        }
        (x, y) => x == y
      }
    (Float64(a), Float64(b)) =>
      match (a.is_valid(i), b.is_valid(j)) {
        (true, true) => {
          let x = a.value(i)
          let y = b.value(j)
          x == y || (x != x && y != y)
        }
        (x, y) => x == y
      }
    (String(a), String(b)) =>
      match (a.is_valid(i), b.is_valid(j)) {
        (true, true) => a.value(i) == b.value(j)
        (x, y) => x == y
      }
    (Null(_), Null(_)) => true
    _ => false
  }
}

///|
/// Hash of row `i` over all `cols`.
fn row_hash(cols : Array[Column], i : Int32) -> Int32 {
  let mut h = 0x9e3779b9U.reinterpret_as_int()
  for c in cols {
    // finalize after every column so that a later column cannot cancel an
    // earlier one and each column changes the whole hash
    h = hash_finalize(h * 31 + c.hash_at(i))
  }
  h
}

///|
/// Whether row `i` of `a` equals row `j` of `b`, column by column.
fn rows_eq(a : Array[Column], i : Int32, b : Array[Column], j : Int32) -> Bool {
  for k in 0..<a.length() {
    if !a[k].eq_at(i, b[k], j) {
      return false
    }
  }
  true
}

///|
/// Open-addressing table of groups (distinct rows). A slot holds a group id
/// or `-1`; a group knows its hash and one representative row (the row that
/// created it, in the table's `build` columns). Capacity is a power of two
/// kept at most half full, probing is linear.
priv struct GroupTable {
  mut slots : FixedArray[Int32]
  mut mask : Int32
  group_hash : Array[Int32]
  group_row : Array[Int32]
}

///|
fn GroupTable::new(expected : Int32) -> GroupTable {
  let mut cap = 16
  while cap < expected * 2 {
    cap = cap * 2
  }
  {
    slots: FixedArray::make(cap, -1),
    mask: cap - 1,
    group_hash: Array(capacity=expected),
    group_row: Array(capacity=expected),
  }
}

///|
/// Number of groups.
fn GroupTable::length(self : GroupTable) -> Int32 {
  self.group_row.length()
}

///|
/// The group whose representative row in `build` equals row `i` of `probe`
/// (whose hash is `h`), or `-1`.
fn GroupTable::find(
  self : GroupTable,
  h : Int32,
  build : Array[Column],
  probe : Array[Column],
  i : Int32,
) -> Int32 {
  let mut pos = h & self.mask
  while true {
    let g = self.slots[pos]
    if g < 0 {
      return -1
    }
    if self.group_hash[g] == h && rows_eq(build, self.group_row[g], probe, i) {
      return g
    }
    pos = (pos + 1) & self.mask
  }
  -1
}

///|
/// Adds a new group represented by row `row` of the build columns (the caller
/// has checked with `find` that no equal group exists) and returns its id.
fn GroupTable::add(self : GroupTable, h : Int32, row : Int32) -> Int32 {
  let g = self.group_row.length()
  self.group_hash.push(h)
  self.group_row.push(row)
  if (g + 1) * 2 > self.slots.length() {
    self.grow()
  } else {
    self.place(g)
  }
  g
}

///|
fn GroupTable::place(self : GroupTable, g : Int32) -> Unit {
  let mut pos = self.group_hash[g] & self.mask
  while self.slots[pos] >= 0 {
    pos = (pos + 1) & self.mask
  }
  self.slots[pos] = g
}

///|
fn GroupTable::grow(self : GroupTable) -> Unit {
  let cap = self.slots.length() * 2
  self.slots = FixedArray::make(cap, -1)
  self.mask = cap - 1
  for g in 0..<self.group_row.length() {
    self.place(g)
  }
}
