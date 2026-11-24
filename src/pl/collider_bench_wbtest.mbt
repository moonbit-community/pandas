///|
/// The 65536 strings that all collide under the old 32-bit FNV-1a (see
/// `hw_collision_strings`): `unique` and `is_in` on them were quadratic.
test "bench Series::unique string 65536 old-FNV colliders" (it : @bench.T) {
  let s = Series::str("s", hw_collision_strings())
  it.bench(fn() { it.keep(s.unique()) })
}

///|
test "bench Series::is_in string 65536 old-FNV colliders" (it : @bench.T) {
  let strs = hw_collision_strings()
  let s = Series::str("s", strs)
  let o = Series::str("o", strs.map(x => x + "x"))
  it.bench(fn() { it.keep(s.is_in(o) catch { _ => abort("is_in") }) })
}
