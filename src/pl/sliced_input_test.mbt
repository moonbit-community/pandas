// A series that is a slice of a longer one (the arrays start at an offset
// other than 0 and their validity is a slice of the bitmap) must behave like
// the same rows in a series of their own. Every operation is applied to both
// and the printed results (or errors) are compared.

///|
fn sl_fixtures() -> Array[@pl.Series] {
  let nan = 0.0 / 0.0
  [
    @pl.Series::bool_nullable("b", [
      Some(true),
      None,
      Some(false),
      Some(true),
      None,
      Some(false),
      Some(false),
      Some(true),
      None,
    ]),
    @pl.Series::int32_nullable("i", [
      Some(5),
      None,
      Some(-3),
      Some(9),
      Some(2147483647),
      None,
      Some(-3),
      Some(0),
      Some(9),
    ]),
    @pl.Series::int64_nullable("l", [
      Some(5L),
      None,
      Some(-3L),
      Some(9L),
      Some(9223372036854775807L),
      None,
      Some(-3L),
      Some(0L),
      Some(9L),
    ]),
    @pl.Series::float32_nullable("f", [
      Some(1.5),
      None,
      Some(-0.0),
      Some(0.0),
      Some(Float::from_double(nan)),
      None,
      Some(-2.5),
      Some(1.5),
      Some(3.0),
    ]),
    @pl.Series::float64_nullable("d", [
      Some(1.5),
      None,
      Some(-0.0),
      Some(0.0),
      Some(nan),
      None,
      Some(-2.5),
      Some(1.5),
      Some(3.0),
    ]),
    @pl.Series::str_nullable("s", [
      Some("b"),
      None,
      Some("a"),
      Some(""),
      Some("\u{1F600}"),
      None,
      Some("a"),
      Some("b"),
      Some("Z"),
    ]),
    @pl.Series::date_nullable("t", [
      Some(0),
      None,
      Some(-5),
      Some(19782),
      Some(7),
      None,
      Some(7),
      Some(1),
      Some(0),
    ]),
    @pl.Series::datetime_nullable("u", [
      Some(0L),
      None,
      Some(-5L),
      Some(1709210096123456L),
      Some(7L),
      None,
      Some(7L),
      Some(1L),
      Some(0L),
    ]),
    @pl.Series::null("n", 9),
  ]
}

///|
fn sl_show(f : () -> @pl.Series raise @pl.PolarsError) -> String {
  "\{f()}" catch {
    e => "error: \{e}"
  }
}

///|
fn sl_show_value(f : () -> @pl.AnyValue raise @pl.PolarsError) -> String {
  "\{f()}" catch {
    e => "error: \{e}"
  }
}

///|
fn sl_ops() -> Array[(String, (@pl.Series) -> String)] {
  [
    ("is_null", s => "\{s.is_null()}"),
    ("is_not_null", s => "\{s.is_not_null()}"),
    ("sort", s => sl_show(() => s.sort())),
    (
      "sort desc nulls last",
      s => sl_show(() => s.sort(descending=true, nulls_last=true)),
    ),
    ("arg_sort", s => sl_show(() => s.arg_sort())),
    ("unique", s => "\{s.unique(maintain_order=true)}"),
    ("n_unique", s => "\{s.n_unique()}"),
    ("is_in self", s => sl_show(() => s.is_in(s))),
    ("eq self", s => sl_show(() => s.eq(s))),
    ("lt self", s => sl_show(() => s.lt(s))),
    ("add self", s => sl_show(() => s.add(s))),
    ("neg", s => sl_show(() => s.neg())),
    ("cum_sum", s => sl_show(() => s.cum_sum())),
    ("cum_max reverse", s => sl_show(() => s.cum_max(reverse=true))),
    ("shift", s => sl_show(() => s.shift(n=1))),
    ("diff", s => sl_show(() => s.diff())),
    ("rank", s => "\{s.rank()}"),
    ("reverse", s => "\{s.reverse()}"),
    ("fill_null forward", s => sl_show(() => s.fill_null_strategy(Forward))),
    ("fill_null backward", s => sl_show(() => s.fill_null_strategy(Backward))),
    ("cast String", s => sl_show(() => s.cast(String))),
    ("cast Int64 lenient", s => sl_show(() => s.cast(Int64, strict=false))),
    ("cast Float64 lenient", s => sl_show(() => s.cast(Float64, strict=false))),
    ("sum", s => sl_show_value(() => s.sum())),
    ("min", s => sl_show_value(() => s.min())),
    ("max", s => sl_show_value(() => s.max())),
    ("median", s => sl_show_value(() => s.median())),
    ("std", s => sl_show_value(() => s.std())),
    ("count", s => "\{s.count()}"),
    ("null_count", s => "\{s.null_count()}"),
    ("head 3", s => "\{s.head(n=3)}"),
    ("tail 3", s => "\{s.tail(n=3)}"),
    ("slice 1 2", s => "\{s.slice(1, length=2)}"),
    ("gather", s => sl_show(() => s.gather([4, 0, -1, 2]))),
    (
      "filter by its own is_null",
      s => sl_show(() => s.filter(s.is_null().not_())),
    ),
    (
      "filter by a sliced mask",
      s => sl_show(() => s.filter(sl_mask().slice(2, length=s.len()))),
    ),
  ]
}

///|
fn sl_mask() -> @pl.Series {
  @pl.Series::bool_nullable("m", [
    Some(true),
    Some(false),
    Some(true),
    None,
    Some(true),
    Some(true),
    Some(false),
    Some(true),
    Some(true),
    Some(false),
    None,
  ])
}

///|
test "operations on a slice with offset 3 equal those on a copy of its rows" {
  let mut checked = 0
  for s in sl_fixtures() {
    let part = s.slice(3, length=5)
    let own = s.gather([3, 4, 5, 6, 7])
    assert_eq(part.len(), 5)
    assert_eq(own.len(), 5)
    for op in sl_ops() {
      let (name, f) = op
      let a = f(part)
      let b = f(own)
      if a != b {
        fail("\{s.name()} / \{name}: slice gives\n\{a}\nbut a copy gives\n\{b}")
      }
      checked += 1
    }
  }
  assert_eq(checked, 9 * sl_ops().length())
}
