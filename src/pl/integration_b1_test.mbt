// Tests of what the pieces of batch one do together: `group_by` with the
// shape methods (`filter`, `sort_by`, `sort`, `unique`, `any`, `all`,
// `sum_horizontal`), `join` keys that are not elementwise, `len()`, and the
// `shift()` default. Every expected value is what polars 2.1.0 gives for the
// expression in the comment (`maintain_order=True` for `group_by`,
// `maintain_order="left_right"` for `join`).

///|
/// df = pl.DataFrame({"a": [1, 2, 1, 2, 1, 3], "b": [10, 20, 30, 40, 50, 60],
///   "c": [3, -1, 0, 5, -2, 7], "p": [True, False, True, True, False, False]})
fn b1_df() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 1L, 2L, 1L, 3L]),
    @pl.Series::int64("b", [10L, 20L, 30L, 40L, 50L, 60L]),
    @pl.Series::int64("c", [3L, -1L, 0L, 5L, -2L, 7L]),
    @pl.Series::bool("p", [true, false, true, true, false, false]),
  ])
}

///|
/// other = pl.DataFrame({"a": [1, 2, 3], "z": [7, 8, 9]})
fn b1_other() -> @pl.DataFrame raise {
  @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L]),
    @pl.Series::int64("z", [7L, 8L, 9L]),
  ])
}

///|
fn b1_err(f : () -> @pl.DataFrame raise @pl.PolarsError) -> @pl.PolarsError? {
  try {
    f() |> ignore
    None
  } catch {
    e => Some(e)
  }
}

///|
fn b1_list_text(expr_text : String) -> String {
  "expression \{expr_text} does not reduce each group to one value; this library has no List type, so aggregate it (for example with first(), sum() or len())"
}

///|
test "agg of filter, sort_by, sort, unique, any, all and sum_horizontal" {
  // df.group_by("a", maintain_order=True).agg(
  //   b.filter(c > 0).sum().alias("fs"), b.sort_by(c).last().alias("sl"),
  //   b.sort().first().alias("sf"), b.unique().len().alias("ul"),
  //   p.any().alias("pa"), p.all().alias("pall"),
  //   pl.sum_horizontal(b.sum(), c.sum()).alias("hs"))
  let df = b1_df()
  let b = @pl.col("b")
  let c = @pl.col("c")
  let p = @pl.col("p")
  let out = df
    .group_by([@pl.col("a")])
    .agg([
      b.filter(c.gt(@pl.lit_int(0L))).sum().alias("fs"),
      b.sort_by([c]).last().alias("sl"),
      b.sort().first().alias("sf"),
      b.unique().len().alias("ul"),
      p.any().alias("pa"),
      p.all().alias("pall"),
      @pl.sum_horizontal([b.sum(), c.sum()]).alias("hs"),
    ])
  assert_eq(out.columns(), ["a", "fs", "sl", "sf", "ul", "pa", "pall", "hs"])
  assert_eq(out.column("a").to_int64_array(), [Some(1L), Some(2L), Some(3L)])
  assert_eq(out.column("fs").to_int64_array(), [Some(10L), Some(40L), Some(60L)])
  assert_eq(out.column("sl").to_int64_array(), [Some(10L), Some(40L), Some(60L)])
  assert_eq(out.column("sf").to_int64_array(), [Some(10L), Some(20L), Some(60L)])
  assert_eq(out.column("ul").to_int64_array(), [Some(3L), Some(2L), Some(1L)])
  assert_eq(out.column("pa").to_bool_array(), [
    Some(true),
    Some(true),
    Some(false),
  ])
  assert_eq(out.column("pall").to_bool_array(), [
    Some(false),
    Some(false),
    Some(false),
  ])
  assert_eq(out.column("hs").to_int64_array(), [Some(91L), Some(64L), Some(67L)])
}

///|
test "agg: group scalars of sort, sort_by and any inside other expressions" {
  // (b.sort_by(c).first() + c.sum()).alias("x")  -> 51, 24, 67
  // (b.sum().sort() + 1).alias("y")              -> 91, 61, 61
  // b.sum().sort_by(c.sum()).alias("z")          -> 90, 60, 60
  // b.sum().arg_sort().alias("w")                -> 0, 0, 0 (u32 in polars)
  // pl.when(p.any()).then(b.sum()).otherwise(0).alias("v") -> 90, 60, 0
  // c.filter(p).any().alias("u")                 -> True, True, False
  let df = b1_df()
  let b = @pl.col("b")
  let c = @pl.col("c")
  let p = @pl.col("p")
  let out = df
    .group_by([@pl.col("a")])
    .agg([
      (b.sort_by([c]).first() + c.sum()).alias("x"),
      (b.sum().sort() + @pl.lit_int(1L)).alias("y"),
      b.sum().sort_by([c.sum()]).alias("z"),
      b.sum().arg_sort().alias("w"),
      @pl.when(p.any()).then(b.sum()).otherwise(@pl.lit_int(0L)).alias("v"),
      c.filter(p).any().alias("u"),
    ])
  assert_eq(out.column("x").to_int64_array(), [Some(51L), Some(24L), Some(67L)])
  assert_eq(out.column("y").to_int64_array(), [Some(91L), Some(61L), Some(61L)])
  assert_eq(out.column("z").to_int64_array(), [Some(90L), Some(60L), Some(60L)])
  assert_eq(out.column("w").to_int64_array(), [Some(0L), Some(0L), Some(0L)])
  assert_eq(out.column("v").to_int64_array(), [Some(90L), Some(60L), Some(0L)])
  assert_eq(out.column("u").to_bool_array(), [
    Some(true),
    Some(true),
    Some(false),
  ])
}

///|
test "agg: len, horizontal functions and shape methods under an aggregation" {
  // agg(pl.len(), (pl.len() + 1).alias("n1"),
  //     pl.max_horizontal(b.sum(), pl.lit(1)).alias("mh"),
  //     pl.sum_horizontal(b, c).sum().alias("hsum"), b.head(2).sum().alias("h2"),
  //     b.drop_nulls().sum().alias("dn"), pl.max_horizontal(b, c).sum().alias("mx"))
  let df = b1_df()
  let b = @pl.col("b")
  let c = @pl.col("c")
  let out = df
    .group_by([@pl.col("a")])
    .agg([
      @pl.len(),
      (@pl.len() + @pl.lit_int(1L)).alias("n1"),
      @pl.max_horizontal([b.sum(), @pl.lit_int(1L)]).alias("mh"),
      @pl.sum_horizontal([b, c]).sum().alias("hsum"),
      b.head(n=2).sum().alias("h2"),
      b.drop_nulls().sum().alias("dn"),
      @pl.max_horizontal([b, c]).sum().alias("mx"),
    ])
  assert_eq(out.column("len").to_int64_array(), [Some(3L), Some(2L), Some(1L)])
  assert_eq(out.column("n1").to_int64_array(), [Some(4L), Some(3L), Some(2L)])
  assert_eq(out.column("mh").to_int64_array(), [Some(90L), Some(60L), Some(60L)])
  assert_eq(out.column("hsum").to_int64_array(), [
    Some(91L),
    Some(64L),
    Some(67L),
  ])
  assert_eq(out.column("h2").to_int64_array(), [Some(40L), Some(60L), Some(60L)])
  assert_eq(out.column("dn").to_int64_array(), [Some(90L), Some(60L), Some(60L)])
  assert_eq(out.column("mx").to_int64_array(), [Some(90L), Some(60L), Some(60L)])
}

///|
test "agg: shift() with the default n inside an aggregation" {
  // agg(b.shift().sum().alias("s"), b.shift().first().alias("f"),
  //     b.sum().shift().alias("g"))
  //   s: 40, 20, 0   f: null, null, null   g: null, null, null
  let df = b1_df()
  let b = @pl.col("b")
  let out = df
    .group_by([@pl.col("a")])
    .agg([
      b.shift().sum().alias("s"),
      b.shift().first().alias("f"),
      b.sum().shift().alias("g"),
    ])
  assert_eq(out.column("s").to_int64_array(), [Some(40L), Some(20L), Some(0L)])
  assert_eq(out.column("f").to_int64_array(), [None, None, None])
  assert_eq(out.column("g").to_int64_array(), [None, None, None])
}

///|
test "agg: a shape method that gives a list per group raises the List text" {
  // df.group_by("a").agg(b.head(2))                     -> list[i64]
  // df.group_by("a").agg(b.sort())                      -> list[i64]
  // df.group_by("a").agg(b.sum().head(1))               -> list[i64], also for one value
  // df.group_by("a").agg(pl.sum_horizontal(b, c.sum())) -> list[i64]
  let df = b1_df()
  let b = @pl.col("b")
  let c = @pl.col("c")
  let g = df.group_by([@pl.col("a")])
  expect_error(
    b1_err(() => g.agg([b.head(n=2)])),
    "InvalidOperation",
    b1_list_text("col(\"b\").slice(offset=dyn int: 0, length=dyn int: 2)"),
  )
  expect_error(
    b1_err(() => g.agg([b.sort()])),
    "InvalidOperation",
    b1_list_text("col(\"b\").sort(asc)"),
  )
  expect_error(
    b1_err(() => g.agg([b.sum().head(n=1)])),
    "InvalidOperation",
    b1_list_text("col(\"b\").sum().slice(offset=dyn int: 0, length=dyn int: 1)"),
  )
  expect_error(
    b1_err(() => g.agg([@pl.sum_horizontal([b, c.sum()])])),
    "InvalidOperation",
    b1_list_text("col(\"b\").sum_horizontal([col(\"c\").sum()])"),
  )
}

///|
test "join: a key that sorts, cuts or filters is not elementwise" {
  // df.join(other, left_on=pl.col("a").sort(), right_on="a")
  //   -> InvalidOperationError: all join key expressions must be elementwise.
  // (same for sort_by, arg_sort, head, tail, slice, unique, drop_nulls, filter,
  // and `a.sort() + 1`; and for the same keys on the right side)
  let df = b1_df()
  let other = b1_other()
  let a = @pl.col("a")
  let keys : Array[@pl.Expr] = [
    a.sort(),
    a.sort_by([@pl.col("b")]),
    a.arg_sort(),
    a.head(n=3),
    a.tail(n=3),
    a.slice(0, length=3),
    a.unique(),
    a.drop_nulls(),
    a.filter(@pl.col("c").gt(@pl.lit_int(0L))),
    a.sort() + @pl.lit_int(1L),
  ]
  for k in keys {
    expect_error(
      b1_err(() => df.join(other, left_on=[k], right_on=[@pl.col("a")])),
      "InvalidOperation",
      "all join key expressions must be elementwise.",
    )
  }
  expect_error(
    b1_err(() => df.join(other, left_on=[a], right_on=[a.sort()])),
    "InvalidOperation",
    "all join key expressions must be elementwise.",
  )
  // the key types are compared first, as for a sequence operation:
  // df.join(other2, left_on=pl.col("a").sort(), right_on="s")
  //   -> SchemaError: datatypes of join keys don't match - `a`: i64 on left
  //      does not match `s`: str on right (and no other type was available to cast to)
  let other2 = @pl.DataFrame::new([
    @pl.Series::str("s", ["x", "y"]),
    @pl.Series::int64("z", [7L, 8L]),
  ])
  expect_error(
    b1_err(() => df.join(other2, left_on=[a.sort()], right_on=[@pl.col("s")])),
    "SchemaMismatch",
    "datatypes of join keys don't match - `a`: i64 on left does not match `s`: str on right (and no other type was available to cast to)",
  )
  // df.join(other2, left_on=pl.col("a").head(2), right_on="s") -> the same SchemaError
  expect_error(
    b1_err(() => df.join(other2, left_on=[a.head(n=2)], right_on=[@pl.col("s")])),
    "SchemaMismatch",
    "datatypes of join keys don't match - `a`: i64 on left does not match `s`: str on right (and no other type was available to cast to)",
  )
  // df.join(other2, left_on=pl.col("a").arg_sort(), right_on="s") -> SchemaError
  //   with `a`: u32 (an index is u32 in polars, i64 in this library)
  expect_error(
    b1_err(() => {
      df.join(other2, left_on=[a.arg_sort()], right_on=[@pl.col("s")])
    }),
    "SchemaMismatch",
    "datatypes of join keys don't match - `a`: i64 on left does not match `s`: str on right (and no other type was available to cast to)",
  )
  // df.join(other2, left_on=pl.col("nope").sort(), right_on="s")
  //   -> ColumnNotFoundError: the missing column comes first
  expect_error(
    b1_err(() => {
      df.join(other2, left_on=[@pl.col("nope").sort()], right_on=[@pl.col("s")])
    }),
    "ColumnNotFound",
    "unable to find column \"nope\"; valid columns: [\"a\", \"b\", \"c\", \"p\"]",
  )
}

///|
test "join: horizontal and aggregate keys are accepted" {
  // df.join(other, left_on=pl.sum_horizontal(pl.col("a"), pl.lit(0)), right_on="a",
  //         how="inner", maintain_order="left_right")
  //   -> 6 rows, z = 7, 8, 7, 8, 7, 9
  let df = b1_df()
  let other = b1_other()
  let out = df.join(
    other,
    left_on=[@pl.sum_horizontal([@pl.col("a"), @pl.lit_int(0L)])],
    right_on=[@pl.col("a")],
  )
  assert_eq(out.height(), 6)
  assert_eq(out.column("z").to_int64_array(), [
    Some(7L),
    Some(8L),
    Some(7L),
    Some(8L),
    Some(7L),
    Some(9L),
  ])
  // df.join(other, left_on=pl.col("p").any(), right_on=pl.lit(True)) -> 18 rows
  // (the one value is repeated and matches every row of `other`)
  let any_key = df.join(other, left_on=[@pl.col("p").any()], right_on=[
    @pl.lit_bool(true),
  ])
  assert_eq(any_key.height(), 18)
  // df.join(other, left_on=pl.len(), right_on="a") -> 0 rows (len is 6)
  let len_key = df.join(other, left_on=[@pl.len()], right_on=[@pl.col("a")])
  assert_eq(len_key.height(), 0)
}

///|
test "select([len()]) and len() next to an aggregation" {
  // df.select(pl.len())                  -> [6]
  // df.select(pl.len(), b.sum())         -> [6], [210]
  // df.filter(c > 0).select(pl.len())    -> [3]
  let df = b1_df()
  let out = df.select([@pl.len()])
  assert_eq(out.columns(), ["len"])
  assert_eq(out.column("len").to_int64_array(), [Some(6L)])
  let two = df.select([@pl.len(), @pl.col("b").sum()])
  assert_eq(two.column("len").to_int64_array(), [Some(6L)])
  assert_eq(two.column("b").to_int64_array(), [Some(210L)])
  let kept = df.filter(@pl.col("c").gt(@pl.lit_int(0L)))
  assert_eq(kept.select([@pl.len()]).column("len").to_int64_array(), [Some(3L)])
}

///|
test "filter with group_by and join results" {
  let df = b1_df()
  let other = b1_other()
  let b = @pl.col("b")
  let c = @pl.col("c")
  // df.filter(c > 0).group_by("a", maintain_order=True).agg(b.sum())
  //   .join(other, on="a", how="left", maintain_order="left_right")
  //   -> a 1,2,3  b 10,40,60  z 7,8,9
  let kept = df
    .filter(c.gt(@pl.lit_int(0L)))
    .group_by([@pl.col("a")])
    .agg([b.sum()])
    .join(other, on=[@pl.col("a")], how=Left)
  assert_eq(kept.columns(), ["a", "b", "z"])
  assert_eq(kept.column("b").to_int64_array(), [Some(10L), Some(40L), Some(60L)])
  assert_eq(kept.column("z").to_int64_array(), [Some(7L), Some(8L), Some(9L)])
  // df.group_by("a", maintain_order=True).agg(b.sum().alias("s")).filter(pl.col("s") > 50)
  //   -> s 90, 60, 60; with `> 70` -> s 90
  let big = df
    .group_by([@pl.col("a")])
    .agg([b.sum().alias("s")])
    .filter(@pl.col("s").gt(@pl.lit_int(50L)))
  assert_eq(big.column("s").to_int64_array(), [Some(90L), Some(60L), Some(60L)])
  let top = df
    .group_by([@pl.col("a")])
    .agg([b.sum().alias("s")])
    .filter(@pl.col("s").gt(@pl.lit_int(70L)))
  assert_eq(top.column("s").to_int64_array(), [Some(90L)])
  // df.join(other, on="a", how="inner", maintain_order="left_right")
  //   .group_by("z", maintain_order=True).agg(b.sum(), pl.len())
  //   -> z 7,8,9  b 90,60,60  len 3,2,1
  let joined = df
    .join(other, on=[@pl.col("a")])
    .group_by([@pl.col("z")])
    .agg([b.sum(), @pl.len()])
  assert_eq(joined.column("z").to_int64_array(), [Some(7L), Some(8L), Some(9L)])
  assert_eq(joined.column("b").to_int64_array(), [
    Some(90L),
    Some(60L),
    Some(60L),
  ])
  assert_eq(joined.column("len").to_int64_array(), [
    Some(3L),
    Some(2L),
    Some(1L),
  ])
  // df.join(other, on="a", how="inner", maintain_order="left_right")
  //   .filter(pl.col("z") > 7).group_by("z", maintain_order=True)
  //   .agg(b.filter(c > 0).sum().alias("fs"), p.any().alias("pa"))
  //   -> z 8,9  fs 40,60  pa True,False
  let both = df
    .join(other, on=[@pl.col("a")])
    .filter(@pl.col("z").gt(@pl.lit_int(7L)))
    .group_by([@pl.col("z")])
    .agg([
      b.filter(c.gt(@pl.lit_int(0L))).sum().alias("fs"),
      @pl.col("p").any().alias("pa"),
    ])
  assert_eq(both.column("z").to_int64_array(), [Some(8L), Some(9L)])
  assert_eq(both.column("fs").to_int64_array(), [Some(40L), Some(60L)])
  assert_eq(both.column("pa").to_bool_array(), [Some(true), Some(false)])
  // df.group_by("a", maintain_order=True).agg(b.sum().alias("s"))
  //   .join(other, on="a", how="left", maintain_order="left_right")
  //   .select(pl.len())  -> [3]
  let n = df
    .group_by([@pl.col("a")])
    .agg([b.sum().alias("s")])
    .join(other, on=[@pl.col("a")], how=Left)
    .select([@pl.len()])
  assert_eq(n.column("len").to_int64_array(), [Some(3L)])
}

///|
test "agg after filter: sort descending first and len" {
  // df.filter(c > 0).group_by("a", maintain_order=True).agg(
  //   b.sort(descending=True).first().alias("mx"), pl.len().alias("n"))
  //   -> mx 10, 40, 60   n 1, 1, 1
  let df = b1_df()
  let out = df
    .filter(@pl.col("c").gt(@pl.lit_int(0L)))
    .group_by([@pl.col("a")])
    .agg([
      @pl.col("b").sort(descending=true).first().alias("mx"),
      @pl.len().alias("n"),
    ])
  assert_eq(out.column("mx").to_int64_array(), [Some(10L), Some(40L), Some(60L)])
  assert_eq(out.column("n").to_int64_array(), [Some(1L), Some(1L), Some(1L)])
}

///|
test "agg: any, all, filter and sort_by on a frame without rows" {
  // e = pl.DataFrame({"a": [], "p": []}, schema={"a": pl.Int64, "p": pl.Boolean})
  // e.group_by("a").agg(p.any().alias("x"), p.all().alias("y"), pl.len().alias("n"))
  //   -> 0 rows: a i64, x bool, y bool, n u32 (i64 here)
  // e.group_by("a").agg(a.sort_by(a).first().alias("sf"), a.unique().len().alias("ul"),
  //   pl.sum_horizontal(a.sum(), pl.lit(1)).alias("hs"), a.filter(p).sum().alias("fs"))
  //   -> 0 rows: sf i64, ul u32 (i64 here), hs i64, fs i64
  let empty = @pl.DataFrame::new([
    @pl.Series::int64("a", []),
    @pl.Series::bool("p", []),
  ])
  let a = @pl.col("a")
  let out = empty
    .group_by([a])
    .agg([
      @pl.col("p").any().alias("x"),
      @pl.col("p").all().alias("y"),
      @pl.len().alias("n"),
    ])
  assert_eq(out.height(), 0)
  assert_eq(out.column("x").dtype().to_string(), "bool")
  assert_eq(out.column("y").dtype().to_string(), "bool")
  assert_eq(out.column("n").dtype().to_string(), "i64")
  let out2 = empty
    .group_by([a])
    .agg([
      a.sort_by([a]).first().alias("sf"),
      a.unique().len().alias("ul"),
      @pl.sum_horizontal([a.sum(), @pl.lit_int(1L)]).alias("hs"),
      a.filter(@pl.col("p")).sum().alias("fs"),
    ])
  assert_eq(out2.height(), 0)
  assert_eq(out2.column("sf").dtype().to_string(), "i64")
  assert_eq(out2.column("ul").dtype().to_string(), "i64")
  assert_eq(out2.column("hs").dtype().to_string(), "i64")
  assert_eq(out2.column("fs").dtype().to_string(), "i64")
}
