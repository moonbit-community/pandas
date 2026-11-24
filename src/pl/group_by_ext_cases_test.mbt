// 由 docs/golden/scripts/group_by_ext.py 生成，勿手改

///|
fn golden_group_by_ext_cases_0(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["filter/sum/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").filter(@pl.col("y").gt(@pl.lit_int(40L))).sum()],
  )
  m["filter/sum/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").filter(@pl.col("y").gt(@pl.lit_int(40L))).sum()],
  )
  m["filter/sum/s"] = (
    [@pl.col("k")],
    [@pl.col("s").filter(@pl.col("y").gt(@pl.lit_int(40L))).sum()],
  )
  m["filter/sum/b"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("y").gt(@pl.lit_int(40L))).sum()],
  )
  m["filter/sum/d"] = (
    [@pl.col("k")],
    [@pl.col("d").filter(@pl.col("y").gt(@pl.lit_int(40L))).sum()],
  )
  m["filter/mean/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").filter(@pl.col("y").gt(@pl.lit_int(40L))).mean()],
  )
  m["filter/mean/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").filter(@pl.col("y").gt(@pl.lit_int(40L))).mean()],
  )
  m["filter/mean/s"] = (
    [@pl.col("k")],
    [@pl.col("s").filter(@pl.col("y").gt(@pl.lit_int(40L))).mean()],
  )
  m["filter/mean/b"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("y").gt(@pl.lit_int(40L))).mean()],
  )
  m["filter/mean/d"] = (
    [@pl.col("k")],
    [@pl.col("d").filter(@pl.col("y").gt(@pl.lit_int(40L))).mean()],
  )
  m["filter/min/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").filter(@pl.col("y").gt(@pl.lit_int(40L))).min()],
  )
  m["filter/min/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").filter(@pl.col("y").gt(@pl.lit_int(40L))).min()],
  )
  m["filter/min/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").filter(@pl.col("y").gt(@pl.lit_int(40L))).min()],
  )
  m["filter/min/s"] = (
    [@pl.col("k")],
    [@pl.col("s").filter(@pl.col("y").gt(@pl.lit_int(40L))).min()],
  )
  m["filter/min/b"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("y").gt(@pl.lit_int(40L))).min()],
  )
  m["filter/min/d"] = (
    [@pl.col("k")],
    [@pl.col("d").filter(@pl.col("y").gt(@pl.lit_int(40L))).min()],
  )
  m["filter/min/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").filter(@pl.col("y").gt(@pl.lit_int(40L))).min()],
  )
  m["filter/min/n"] = (
    [@pl.col("k")],
    [@pl.col("n").filter(@pl.col("y").gt(@pl.lit_int(40L))).min()],
  )
  m["filter/max/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").filter(@pl.col("y").gt(@pl.lit_int(40L))).max()],
  )
  m["filter/max/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").filter(@pl.col("y").gt(@pl.lit_int(40L))).max()],
  )
  m["filter/max/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").filter(@pl.col("y").gt(@pl.lit_int(40L))).max()],
  )
  m["filter/max/s"] = (
    [@pl.col("k")],
    [@pl.col("s").filter(@pl.col("y").gt(@pl.lit_int(40L))).max()],
  )
  m["filter/max/b"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("y").gt(@pl.lit_int(40L))).max()],
  )
  m["filter/max/d"] = (
    [@pl.col("k")],
    [@pl.col("d").filter(@pl.col("y").gt(@pl.lit_int(40L))).max()],
  )
  m["filter/max/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").filter(@pl.col("y").gt(@pl.lit_int(40L))).max()],
  )
  m["filter/max/n"] = (
    [@pl.col("k")],
    [@pl.col("n").filter(@pl.col("y").gt(@pl.lit_int(40L))).max()],
  )
  m["filter/first/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").filter(@pl.col("y").gt(@pl.lit_int(40L))).first()],
  )
  m["filter/first/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").filter(@pl.col("y").gt(@pl.lit_int(40L))).first()],
  )
  m["filter/first/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").filter(@pl.col("y").gt(@pl.lit_int(40L))).first()],
  )
  m["filter/first/s"] = (
    [@pl.col("k")],
    [@pl.col("s").filter(@pl.col("y").gt(@pl.lit_int(40L))).first()],
  )
  m["filter/first/b"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("y").gt(@pl.lit_int(40L))).first()],
  )
  m["filter/first/d"] = (
    [@pl.col("k")],
    [@pl.col("d").filter(@pl.col("y").gt(@pl.lit_int(40L))).first()],
  )
  m["filter/first/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").filter(@pl.col("y").gt(@pl.lit_int(40L))).first()],
  )
  m["filter/first/n"] = (
    [@pl.col("k")],
    [@pl.col("n").filter(@pl.col("y").gt(@pl.lit_int(40L))).first()],
  )
  m["filter/last/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").filter(@pl.col("y").gt(@pl.lit_int(40L))).last()],
  )
  m["filter/last/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").filter(@pl.col("y").gt(@pl.lit_int(40L))).last()],
  )
  m["filter/last/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").filter(@pl.col("y").gt(@pl.lit_int(40L))).last()],
  )
  m["filter/last/s"] = (
    [@pl.col("k")],
    [@pl.col("s").filter(@pl.col("y").gt(@pl.lit_int(40L))).last()],
  )
  m["filter/last/b"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("y").gt(@pl.lit_int(40L))).last()],
  )
  m["filter/last/d"] = (
    [@pl.col("k")],
    [@pl.col("d").filter(@pl.col("y").gt(@pl.lit_int(40L))).last()],
  )
}

///|
fn golden_group_by_ext_cases_1(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["filter/last/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").filter(@pl.col("y").gt(@pl.lit_int(40L))).last()],
  )
  m["filter/last/n"] = (
    [@pl.col("k")],
    [@pl.col("n").filter(@pl.col("y").gt(@pl.lit_int(40L))).last()],
  )
  m["filter/count/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").filter(@pl.col("y").gt(@pl.lit_int(40L))).count()],
  )
  m["filter/count/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").filter(@pl.col("y").gt(@pl.lit_int(40L))).count()],
  )
  m["filter/count/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").filter(@pl.col("y").gt(@pl.lit_int(40L))).count()],
  )
  m["filter/count/s"] = (
    [@pl.col("k")],
    [@pl.col("s").filter(@pl.col("y").gt(@pl.lit_int(40L))).count()],
  )
  m["filter/count/b"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("y").gt(@pl.lit_int(40L))).count()],
  )
  m["filter/count/d"] = (
    [@pl.col("k")],
    [@pl.col("d").filter(@pl.col("y").gt(@pl.lit_int(40L))).count()],
  )
  m["filter/count/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").filter(@pl.col("y").gt(@pl.lit_int(40L))).count()],
  )
  m["filter/count/n"] = (
    [@pl.col("k")],
    [@pl.col("n").filter(@pl.col("y").gt(@pl.lit_int(40L))).count()],
  )
  m["filter/len/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").filter(@pl.col("y").gt(@pl.lit_int(40L))).len()],
  )
  m["filter/len/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").filter(@pl.col("y").gt(@pl.lit_int(40L))).len()],
  )
  m["filter/len/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").filter(@pl.col("y").gt(@pl.lit_int(40L))).len()],
  )
  m["filter/len/s"] = (
    [@pl.col("k")],
    [@pl.col("s").filter(@pl.col("y").gt(@pl.lit_int(40L))).len()],
  )
  m["filter/len/b"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("y").gt(@pl.lit_int(40L))).len()],
  )
  m["filter/len/d"] = (
    [@pl.col("k")],
    [@pl.col("d").filter(@pl.col("y").gt(@pl.lit_int(40L))).len()],
  )
  m["filter/len/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").filter(@pl.col("y").gt(@pl.lit_int(40L))).len()],
  )
  m["filter/len/n"] = (
    [@pl.col("k")],
    [@pl.col("n").filter(@pl.col("y").gt(@pl.lit_int(40L))).len()],
  )
  m["filter/n_unique/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").filter(@pl.col("y").gt(@pl.lit_int(40L))).n_unique()],
  )
  m["filter/n_unique/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").filter(@pl.col("y").gt(@pl.lit_int(40L))).n_unique()],
  )
  m["filter/n_unique/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").filter(@pl.col("y").gt(@pl.lit_int(40L))).n_unique()],
  )
  m["filter/n_unique/s"] = (
    [@pl.col("k")],
    [@pl.col("s").filter(@pl.col("y").gt(@pl.lit_int(40L))).n_unique()],
  )
  m["filter/n_unique/b"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("y").gt(@pl.lit_int(40L))).n_unique()],
  )
  m["filter/n_unique/d"] = (
    [@pl.col("k")],
    [@pl.col("d").filter(@pl.col("y").gt(@pl.lit_int(40L))).n_unique()],
  )
  m["filter/n_unique/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").filter(@pl.col("y").gt(@pl.lit_int(40L))).n_unique()],
  )
  m["filter/n_unique/n"] = (
    [@pl.col("k")],
    [@pl.col("n").filter(@pl.col("y").gt(@pl.lit_int(40L))).n_unique()],
  )
  m["filter/sum/null-pred"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("b")).sum()],
  )
  m["filter/sum/all-false"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").lt(@pl.lit_int(-5L))).sum()],
  )
  m["filter/sum/agg-pred"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.col("v").mean())).sum()],
  )
  m["filter/sum/by-j"] = (
    [@pl.col("j")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum()],
  )
  m["filter/sum/e"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum()],
  )
  m["filter/len/null-pred"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("b")).len()],
  )
  m["filter/len/all-false"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").lt(@pl.lit_int(-5L))).len()],
  )
  m["filter/len/agg-pred"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.col("v").mean())).len()],
  )
  m["filter/len/by-j"] = (
    [@pl.col("j")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).len()],
  )
  m["filter/len/e"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).len()],
  )
  m["filter/first/null-pred"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("b")).first()],
  )
  m["filter/first/all-false"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").lt(@pl.lit_int(-5L))).first()],
  )
  m["filter/first/agg-pred"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.col("v").mean())).first()],
  )
  m["filter/first/by-j"] = (
    [@pl.col("j")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).first()],
  )
}

///|
fn golden_group_by_ext_cases_2(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["filter/first/e"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).first()],
  )
  m["filter/count/null-pred"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("b")).count()],
  )
  m["filter/count/all-false"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").lt(@pl.lit_int(-5L))).count()],
  )
  m["filter/count/agg-pred"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.col("v").mean())).count()],
  )
  m["filter/count/by-j"] = (
    [@pl.col("j")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).count()],
  )
  m["filter/count/e"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).count()],
  )
  m["filter/sum-two-keys"] = (
    [@pl.col("k"), @pl.col("j")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum(), @pl.len()],
  )
  m["filter/spec-example"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("y").gt(@pl.lit_int(0L))).sum()],
  )
  m["filter/ratio"] = (
    [@pl.col("k")],
    [
      (@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum() / @pl.len()).alias(
        "r",
      ),
    ],
  )
  m["filter/two-aggs"] = (
    [@pl.col("k")],
    [
      @pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum().alias("a"),
      @pl.col("v").filter(@pl.col("v").le(@pl.lit_int(2L))).sum().alias("b"),
    ],
  )
  m["filter/of-sorted"] = (
    [@pl.col("k")],
    [@pl.col("v").sort().filter(@pl.col("v").gt(@pl.lit_int(2L))).first()],
  )
  m["filter/when"] = (
    [@pl.col("k")],
    [
      @pl.when(
        @pl.col("v")
        .filter(@pl.col("v").gt(@pl.lit_int(2L)))
        .sum()
        .gt(@pl.lit_int(10L)),
      )
      .then(@pl.lit_int(1L))
      .otherwise(@pl.lit_int(0L))
      .alias("w"),
    ],
  )
  m["filter/no-key"] = (
    [],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum(), @pl.len()],
  )
  m["filter/no-key/e"] = (
    [],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum(), @pl.len()],
  )
  m["filter/bad-pred-type"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v")).sum()],
  )
  m["filter/missing"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("zz").gt(@pl.lit_int(2L))).sum()],
  )
  m["filter/list"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L)))],
  )
  m["filter/list-sum-of-scalar"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().filter(@pl.lit_bool(true))],
  )
  m["filter/list-lit"] = (
    [@pl.col("k")],
    [@pl.lit_int(1L).filter(@pl.lit_bool(true))],
  )
  m["sort_by/first/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").sort_by([@pl.col("y")]).first()],
  )
  m["sort_by/first-desc/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").sort_by([@pl.col("y")], descending=[true]).first()],
  )
  m["sort_by/first/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").sort_by([@pl.col("y")]).first()],
  )
  m["sort_by/first-desc/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").sort_by([@pl.col("y")], descending=[true]).first()],
  )
  m["sort_by/first/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").sort_by([@pl.col("y")]).first()],
  )
  m["sort_by/first-desc/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").sort_by([@pl.col("y")], descending=[true]).first()],
  )
  m["sort_by/first/s"] = (
    [@pl.col("k")],
    [@pl.col("s").sort_by([@pl.col("y")]).first()],
  )
  m["sort_by/first-desc/s"] = (
    [@pl.col("k")],
    [@pl.col("s").sort_by([@pl.col("y")], descending=[true]).first()],
  )
  m["sort_by/first/b"] = (
    [@pl.col("k")],
    [@pl.col("b").sort_by([@pl.col("y")]).first()],
  )
  m["sort_by/first-desc/b"] = (
    [@pl.col("k")],
    [@pl.col("b").sort_by([@pl.col("y")], descending=[true]).first()],
  )
  m["sort_by/first/d"] = (
    [@pl.col("k")],
    [@pl.col("d").sort_by([@pl.col("y")]).first()],
  )
  m["sort_by/first-desc/d"] = (
    [@pl.col("k")],
    [@pl.col("d").sort_by([@pl.col("y")], descending=[true]).first()],
  )
  m["sort_by/first/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").sort_by([@pl.col("y")]).first()],
  )
  m["sort_by/first-desc/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").sort_by([@pl.col("y")], descending=[true]).first()],
  )
  m["sort_by/first/n"] = (
    [@pl.col("k")],
    [@pl.col("n").sort_by([@pl.col("y")]).first()],
  )
  m["sort_by/first-desc/n"] = (
    [@pl.col("k")],
    [@pl.col("n").sort_by([@pl.col("y")], descending=[true]).first()],
  )
  m["sort_by/first/two-keys"] = (
    [@pl.col("k")],
    [
      @pl.col("y")
      .sort_by([@pl.col("i32"), @pl.col("id")], descending=[true, false])
      .first(),
    ],
  )
  m["sort_by/first/null-key"] = (
    [@pl.col("k")],
    [
      @pl.col("y")
      .sort_by([@pl.col("i32"), @pl.col("id")], nulls_last=true)
      .first(),
    ],
  )
  m["sort_by/first/null-key-first"] = (
    [@pl.col("k")],
    [@pl.col("y").sort_by([@pl.col("i32"), @pl.col("id")]).first()],
  )
  m["sort_by/first/float-key"] = (
    [@pl.col("k")],
    [@pl.col("y").sort_by([@pl.col("f64"), @pl.col("id")]).first()],
  )
  m["sort_by/first/str-key"] = (
    [@pl.col("k")],
    [
      @pl.col("y")
      .sort_by([@pl.col("s"), @pl.col("id")], descending=[true, false])
      .first(),
    ],
  )
}

///|
fn golden_group_by_ext_cases_3(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["sort_by/first/e"] = (
    [@pl.col("k")],
    [@pl.col("y").sort_by([@pl.col("x")]).first()],
  )
  m["sort_by/first/by-j"] = (
    [@pl.col("j")],
    [@pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).first()],
  )
  m["sort_by/last/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").sort_by([@pl.col("y")]).last()],
  )
  m["sort_by/last-desc/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").sort_by([@pl.col("y")], descending=[true]).last()],
  )
  m["sort_by/last/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").sort_by([@pl.col("y")]).last()],
  )
  m["sort_by/last-desc/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").sort_by([@pl.col("y")], descending=[true]).last()],
  )
  m["sort_by/last/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").sort_by([@pl.col("y")]).last()],
  )
  m["sort_by/last-desc/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").sort_by([@pl.col("y")], descending=[true]).last()],
  )
  m["sort_by/last/s"] = (
    [@pl.col("k")],
    [@pl.col("s").sort_by([@pl.col("y")]).last()],
  )
  m["sort_by/last-desc/s"] = (
    [@pl.col("k")],
    [@pl.col("s").sort_by([@pl.col("y")], descending=[true]).last()],
  )
  m["sort_by/last/b"] = (
    [@pl.col("k")],
    [@pl.col("b").sort_by([@pl.col("y")]).last()],
  )
  m["sort_by/last-desc/b"] = (
    [@pl.col("k")],
    [@pl.col("b").sort_by([@pl.col("y")], descending=[true]).last()],
  )
  m["sort_by/last/d"] = (
    [@pl.col("k")],
    [@pl.col("d").sort_by([@pl.col("y")]).last()],
  )
  m["sort_by/last-desc/d"] = (
    [@pl.col("k")],
    [@pl.col("d").sort_by([@pl.col("y")], descending=[true]).last()],
  )
  m["sort_by/last/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").sort_by([@pl.col("y")]).last()],
  )
  m["sort_by/last-desc/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").sort_by([@pl.col("y")], descending=[true]).last()],
  )
  m["sort_by/last/n"] = (
    [@pl.col("k")],
    [@pl.col("n").sort_by([@pl.col("y")]).last()],
  )
  m["sort_by/last-desc/n"] = (
    [@pl.col("k")],
    [@pl.col("n").sort_by([@pl.col("y")], descending=[true]).last()],
  )
  m["sort_by/last/two-keys"] = (
    [@pl.col("k")],
    [
      @pl.col("y")
      .sort_by([@pl.col("i32"), @pl.col("id")], descending=[true, false])
      .last(),
    ],
  )
  m["sort_by/last/null-key"] = (
    [@pl.col("k")],
    [
      @pl.col("y")
      .sort_by([@pl.col("i32"), @pl.col("id")], nulls_last=true)
      .last(),
    ],
  )
  m["sort_by/last/null-key-first"] = (
    [@pl.col("k")],
    [@pl.col("y").sort_by([@pl.col("i32"), @pl.col("id")]).last()],
  )
  m["sort_by/last/float-key"] = (
    [@pl.col("k")],
    [@pl.col("y").sort_by([@pl.col("f64"), @pl.col("id")]).last()],
  )
  m["sort_by/last/str-key"] = (
    [@pl.col("k")],
    [
      @pl.col("y")
      .sort_by([@pl.col("s"), @pl.col("id")], descending=[true, false])
      .last(),
    ],
  )
  m["sort_by/last/e"] = (
    [@pl.col("k")],
    [@pl.col("y").sort_by([@pl.col("x")]).last()],
  )
  m["sort_by/last/by-j"] = (
    [@pl.col("j")],
    [@pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).last()],
  )
  m["sort_by/sum"] = (
    [@pl.col("k")],
    [@pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).sum()],
  )
  m["sort_by/cum-last"] = (
    [@pl.col("k")],
    [@pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).cum_sum().last()],
  )
  m["sort_by/first-minus-last"] = (
    [@pl.col("k")],
    [
      (@pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).first() -
      @pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).last()).alias("d"),
    ],
  )
  m["sort_by/expr-key"] = (
    [@pl.col("k")],
    [
      @pl.col("y")
      .sort_by([@pl.col("v") * @pl.lit_int(-1L), @pl.col("id")])
      .first(),
    ],
  )
  m["sort_by/agg-key"] = (
    [@pl.col("k")],
    [@pl.col("y").sort_by([@pl.col("v").sum()]).first()],
  )
  m["sort_by/no-key"] = (
    [],
    [
      @pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).first(),
      @pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).last().alias("l"),
    ],
  )
  m["sort_by/scalar-both"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().sort_by([@pl.col("v").sum()]).alias("s")],
  )
  m["sort_by/scalar-both-lits"] = (
    [@pl.col("k")],
    [
      @pl.col("y")
      .max()
      .sort_by([@pl.col("v").min(), @pl.col("x").sum()])
      .alias("s"),
    ],
  )
  m["sort_by/filtered-base-unfiltered-key"] = (
    [@pl.col("k")],
    [
      @pl.col("v")
      .filter(@pl.col("v").gt(@pl.lit_int(2L)))
      .sort_by([@pl.col("v")])
      .first(),
    ],
  )
  m["sort_by/filtered-base-unfiltered-key-sum"] = (
    [@pl.col("k")],
    [
      @pl.col("v")
      .filter(@pl.col("v").gt(@pl.lit_int(2L)))
      .sort_by([@pl.col("y")])
      .sum(),
    ],
  )
  m["sort_by/list"] = (
    [@pl.col("k")],
    [@pl.col("y").sort_by([@pl.col("v"), @pl.col("id")])],
  )
  m["sort_by/list-scalar-key"] = (
    [@pl.col("k")],
    [@pl.col("y").sort_by([@pl.col("v").sum()])],
  )
  m["sort/first/i32"] = ([@pl.col("k")], [@pl.col("i32").sort().first()])
  m["sort/last/i32"] = ([@pl.col("k")], [@pl.col("i32").sort().last()])
  m["sort/first/i64"] = ([@pl.col("k")], [@pl.col("i64").sort().first()])
}

///|
fn golden_group_by_ext_cases_4(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["sort/last/i64"] = ([@pl.col("k")], [@pl.col("i64").sort().last()])
  m["sort/first/f32"] = ([@pl.col("k")], [@pl.col("f32").sort().first()])
  m["sort/last/f32"] = ([@pl.col("k")], [@pl.col("f32").sort().last()])
  m["sort/first/f64"] = ([@pl.col("k")], [@pl.col("f64").sort().first()])
  m["sort/last/f64"] = ([@pl.col("k")], [@pl.col("f64").sort().last()])
  m["sort/first/s"] = ([@pl.col("k")], [@pl.col("s").sort().first()])
  m["sort/last/s"] = ([@pl.col("k")], [@pl.col("s").sort().last()])
  m["sort/first/b"] = ([@pl.col("k")], [@pl.col("b").sort().first()])
  m["sort/last/b"] = ([@pl.col("k")], [@pl.col("b").sort().last()])
  m["sort/first/d"] = ([@pl.col("k")], [@pl.col("d").sort().first()])
  m["sort/last/d"] = ([@pl.col("k")], [@pl.col("d").sort().last()])
  m["sort/first/dt"] = ([@pl.col("k")], [@pl.col("dt").sort().first()])
  m["sort/last/dt"] = ([@pl.col("k")], [@pl.col("dt").sort().last()])
  m["sort/first/n"] = ([@pl.col("k")], [@pl.col("n").sort().first()])
  m["sort/last/n"] = ([@pl.col("k")], [@pl.col("n").sort().last()])
  m["sort/first/f64/TrueFalse"] = (
    [@pl.col("k")],
    [@pl.col("f64").sort(descending=true).first()],
  )
  m["sort/last/i32/TrueFalse"] = (
    [@pl.col("k")],
    [@pl.col("i32").sort(descending=true).last()],
  )
  m["sort/first/f64/FalseTrue"] = (
    [@pl.col("k")],
    [@pl.col("f64").sort(nulls_last=true).first()],
  )
  m["sort/last/i32/FalseTrue"] = (
    [@pl.col("k")],
    [@pl.col("i32").sort(nulls_last=true).last()],
  )
  m["sort/first/f64/TrueTrue"] = (
    [@pl.col("k")],
    [@pl.col("f64").sort(descending=true, nulls_last=true).first()],
  )
  m["sort/last/i32/TrueTrue"] = (
    [@pl.col("k")],
    [@pl.col("i32").sort(descending=true, nulls_last=true).last()],
  )
  m["sort/sum"] = ([@pl.col("k")], [@pl.col("v").sort().sum()])
  m["sort/mean-f64"] = ([@pl.col("k")], [@pl.col("f64").sort().mean()])
  m["sort/e"] = (
    [@pl.col("k")],
    [@pl.col("v").sort().first(), @pl.col("s").sort().last().alias("l")],
  )
  m["sort/no-key"] = (
    [],
    [@pl.col("v").sort().first(), @pl.col("v").sort().last().alias("l")],
  )
  m["sort/of-sum"] = ([@pl.col("k")], [@pl.col("v").sum().sort().alias("s")])
  m["sort/of-sum-plus"] = (
    [@pl.col("k")],
    [(@pl.col("v").sum().sort() + @pl.lit_int(1L)).alias("s")],
  )
  m["sort/of-lit"] = ([@pl.col("k")], [@pl.lit_int(1L).sort().alias("s")])
  m["sort/of-len"] = ([@pl.col("k")], [@pl.len().sort().alias("n")])
  m["arg_sort/of-sum"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().arg_sort().alias("a")],
  )
  m["arg_sort/first"] = ([@pl.col("k")], [@pl.col("v").arg_sort().first()])
  m["arg_sort/last-desc"] = (
    [@pl.col("k")],
    [@pl.col("vn").arg_sort(descending=true, nulls_last=true).last()],
  )
  m["arg_sort/sum"] = ([@pl.col("k")], [@pl.col("v").arg_sort().sum()])
  m["sort/list"] = ([@pl.col("k")], [@pl.col("v").sort()])
  m["sort/list-str"] = ([@pl.col("k")], [@pl.col("s").sort()])
  m["sort/list-plus"] = (
    [@pl.col("k")],
    [@pl.col("v").sort() + @pl.lit_int(1L)],
  )
  m["arg_sort/list"] = ([@pl.col("k")], [@pl.col("v").arg_sort()])
  m["unique/len/i32"] = ([@pl.col("k")], [@pl.col("i32").unique().len()])
  m["unique/count/i32"] = ([@pl.col("k")], [@pl.col("i32").unique().count()])
  m["unique/n_unique/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").unique().n_unique()],
  )
}

///|
fn golden_group_by_ext_cases_5(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["unique/first-stable/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").unique(maintain_order=true).first()],
  )
  m["unique/last-stable/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").unique(maintain_order=true).last()],
  )
  m["unique/len/i64"] = ([@pl.col("k")], [@pl.col("i64").unique().len()])
  m["unique/count/i64"] = ([@pl.col("k")], [@pl.col("i64").unique().count()])
  m["unique/n_unique/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").unique().n_unique()],
  )
  m["unique/first-stable/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").unique(maintain_order=true).first()],
  )
  m["unique/last-stable/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").unique(maintain_order=true).last()],
  )
  m["unique/len/f64"] = ([@pl.col("k")], [@pl.col("f64").unique().len()])
  m["unique/count/f64"] = ([@pl.col("k")], [@pl.col("f64").unique().count()])
  m["unique/n_unique/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").unique().n_unique()],
  )
  m["unique/first-stable/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").unique(maintain_order=true).first()],
  )
  m["unique/last-stable/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").unique(maintain_order=true).last()],
  )
  m["unique/len/s"] = ([@pl.col("k")], [@pl.col("s").unique().len()])
  m["unique/count/s"] = ([@pl.col("k")], [@pl.col("s").unique().count()])
  m["unique/n_unique/s"] = ([@pl.col("k")], [@pl.col("s").unique().n_unique()])
  m["unique/first-stable/s"] = (
    [@pl.col("k")],
    [@pl.col("s").unique(maintain_order=true).first()],
  )
  m["unique/last-stable/s"] = (
    [@pl.col("k")],
    [@pl.col("s").unique(maintain_order=true).last()],
  )
  m["unique/len/b"] = ([@pl.col("k")], [@pl.col("b").unique().len()])
  m["unique/count/b"] = ([@pl.col("k")], [@pl.col("b").unique().count()])
  m["unique/n_unique/b"] = ([@pl.col("k")], [@pl.col("b").unique().n_unique()])
  m["unique/first-stable/b"] = (
    [@pl.col("k")],
    [@pl.col("b").unique(maintain_order=true).first()],
  )
  m["unique/last-stable/b"] = (
    [@pl.col("k")],
    [@pl.col("b").unique(maintain_order=true).last()],
  )
  m["unique/len/d"] = ([@pl.col("k")], [@pl.col("d").unique().len()])
  m["unique/count/d"] = ([@pl.col("k")], [@pl.col("d").unique().count()])
  m["unique/n_unique/d"] = ([@pl.col("k")], [@pl.col("d").unique().n_unique()])
  m["unique/first-stable/d"] = (
    [@pl.col("k")],
    [@pl.col("d").unique(maintain_order=true).first()],
  )
  m["unique/last-stable/d"] = (
    [@pl.col("k")],
    [@pl.col("d").unique(maintain_order=true).last()],
  )
  m["unique/len/dt"] = ([@pl.col("k")], [@pl.col("dt").unique().len()])
  m["unique/count/dt"] = ([@pl.col("k")], [@pl.col("dt").unique().count()])
  m["unique/n_unique/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").unique().n_unique()],
  )
  m["unique/first-stable/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").unique(maintain_order=true).first()],
  )
  m["unique/last-stable/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").unique(maintain_order=true).last()],
  )
  m["unique/len/n"] = ([@pl.col("k")], [@pl.col("n").unique().len()])
  m["unique/count/n"] = ([@pl.col("k")], [@pl.col("n").unique().count()])
  m["unique/n_unique/n"] = ([@pl.col("k")], [@pl.col("n").unique().n_unique()])
  m["unique/first-stable/n"] = (
    [@pl.col("k")],
    [@pl.col("n").unique(maintain_order=true).first()],
  )
  m["unique/last-stable/n"] = (
    [@pl.col("k")],
    [@pl.col("n").unique(maintain_order=true).last()],
  )
  m["unique/sum"] = ([@pl.col("k")], [@pl.col("v").unique().sum()])
  m["unique/sum-stable-f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").unique(maintain_order=true).sum()],
  )
  m["unique/max"] = ([@pl.col("k")], [@pl.col("v").unique().max()])
}

///|
fn golden_group_by_ext_cases_6(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["unique/len-by-j"] = ([@pl.col("j")], [@pl.col("v").unique().len()])
  m["unique/len-minus-n_unique"] = (
    [@pl.col("k")],
    [(@pl.col("v").unique().len() - @pl.col("v").n_unique()).alias("d")],
  )
  m["unique/e"] = ([@pl.col("k")], [@pl.col("v").unique().len()])
  m["unique/no-key"] = ([], [@pl.col("v").unique().len()])
  m["unique/spec-example"] = (
    [@pl.col("k")],
    [@pl.col("v").unique().len(), @pl.col("v").sum().alias("s")],
  )
  m["drop_nulls/len/vn"] = ([@pl.col("k")], [@pl.col("vn").drop_nulls().len()])
  m["drop_nulls/first/vn"] = (
    [@pl.col("k")],
    [@pl.col("vn").drop_nulls().first()],
  )
  m["drop_nulls/last/vn"] = (
    [@pl.col("k")],
    [@pl.col("vn").drop_nulls().last()],
  )
  m["drop_nulls/len/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").drop_nulls().len()],
  )
  m["drop_nulls/first/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").drop_nulls().first()],
  )
  m["drop_nulls/last/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").drop_nulls().last()],
  )
  m["drop_nulls/len/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").drop_nulls().len()],
  )
  m["drop_nulls/first/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").drop_nulls().first()],
  )
  m["drop_nulls/last/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").drop_nulls().last()],
  )
  m["drop_nulls/len/s"] = ([@pl.col("k")], [@pl.col("s").drop_nulls().len()])
  m["drop_nulls/first/s"] = (
    [@pl.col("k")],
    [@pl.col("s").drop_nulls().first()],
  )
  m["drop_nulls/last/s"] = ([@pl.col("k")], [@pl.col("s").drop_nulls().last()])
  m["drop_nulls/len/n"] = ([@pl.col("k")], [@pl.col("n").drop_nulls().len()])
  m["drop_nulls/first/n"] = (
    [@pl.col("k")],
    [@pl.col("n").drop_nulls().first()],
  )
  m["drop_nulls/last/n"] = ([@pl.col("k")], [@pl.col("n").drop_nulls().last()])
  m["drop_nulls/sum"] = ([@pl.col("k")], [@pl.col("vn").drop_nulls().sum()])
  m["drop_nulls/mean"] = ([@pl.col("k")], [@pl.col("vn").drop_nulls().mean()])
  m["drop_nulls/count-vs-len"] = (
    [@pl.col("k")],
    [
      @pl.col("vn").count().alias("c"),
      @pl.col("vn").drop_nulls().len().alias("l"),
    ],
  )
  m["drop_nulls/e"] = ([@pl.col("k")], [@pl.col("vn").drop_nulls().sum()])
  m["unique/list"] = ([@pl.col("k")], [@pl.col("v").unique()])
  m["unique/list-stable"] = (
    [@pl.col("k")],
    [@pl.col("v").unique(maintain_order=true)],
  )
  m["unique/list-of-sum"] = ([@pl.col("k")], [@pl.col("v").sum().unique()])
  m["drop_nulls/list"] = ([@pl.col("k")], [@pl.col("vn").drop_nulls()])
  m["drop_nulls/list-of-sum"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().drop_nulls()],
  )
  m["head/sum/0"] = ([@pl.col("k")], [@pl.col("v").head(n=0).sum()])
  m["head/len/0"] = ([@pl.col("k")], [@pl.col("v").head(n=0).len()])
  m["head/first/0"] = ([@pl.col("k")], [@pl.col("v").head(n=0).first()])
  m["head/last/0"] = ([@pl.col("k")], [@pl.col("v").head(n=0).last()])
  m["head/sum/1"] = ([@pl.col("k")], [@pl.col("v").head(n=1).sum()])
  m["head/len/1"] = ([@pl.col("k")], [@pl.col("v").head(n=1).len()])
  m["head/first/1"] = ([@pl.col("k")], [@pl.col("v").head(n=1).first()])
  m["head/last/1"] = ([@pl.col("k")], [@pl.col("v").head(n=1).last()])
  m["head/sum/2"] = ([@pl.col("k")], [@pl.col("v").head(n=2).sum()])
  m["head/len/2"] = ([@pl.col("k")], [@pl.col("v").head(n=2).len()])
  m["head/first/2"] = ([@pl.col("k")], [@pl.col("v").head(n=2).first()])
}

///|
fn golden_group_by_ext_cases_7(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["head/last/2"] = ([@pl.col("k")], [@pl.col("v").head(n=2).last()])
  m["head/sum/100"] = ([@pl.col("k")], [@pl.col("v").head(n=100).sum()])
  m["head/len/100"] = ([@pl.col("k")], [@pl.col("v").head(n=100).len()])
  m["head/first/100"] = ([@pl.col("k")], [@pl.col("v").head(n=100).first()])
  m["head/last/100"] = ([@pl.col("k")], [@pl.col("v").head(n=100).last()])
  m["tail/sum/1"] = ([@pl.col("k")], [@pl.col("v").tail(n=1).sum()])
  m["tail/len/1"] = ([@pl.col("k")], [@pl.col("v").tail(n=1).len()])
  m["tail/first/1"] = ([@pl.col("k")], [@pl.col("v").tail(n=1).first()])
  m["tail/last/1"] = ([@pl.col("k")], [@pl.col("v").tail(n=1).last()])
  m["tail/sum/2"] = ([@pl.col("k")], [@pl.col("v").tail(n=2).sum()])
  m["tail/len/2"] = ([@pl.col("k")], [@pl.col("v").tail(n=2).len()])
  m["tail/first/2"] = ([@pl.col("k")], [@pl.col("v").tail(n=2).first()])
  m["tail/last/2"] = ([@pl.col("k")], [@pl.col("v").tail(n=2).last()])
  m["tail/sum/100"] = ([@pl.col("k")], [@pl.col("v").tail(n=100).sum()])
  m["tail/len/100"] = ([@pl.col("k")], [@pl.col("v").tail(n=100).len()])
  m["tail/first/100"] = ([@pl.col("k")], [@pl.col("v").tail(n=100).first()])
  m["tail/last/100"] = ([@pl.col("k")], [@pl.col("v").tail(n=100).last()])
  m["slice/sum/1/2"] = ([@pl.col("k")], [@pl.col("v").slice(1, length=2).sum()])
  m["slice/len/1/2"] = ([@pl.col("k")], [@pl.col("v").slice(1, length=2).len()])
  m["slice/first/1/2"] = (
    [@pl.col("k")],
    [@pl.col("v").slice(1, length=2).first()],
  )
  m["slice/sum/-2/None"] = ([@pl.col("k")], [@pl.col("v").slice(-2).sum()])
  m["slice/len/-2/None"] = ([@pl.col("k")], [@pl.col("v").slice(-2).len()])
  m["slice/first/-2/None"] = ([@pl.col("k")], [@pl.col("v").slice(-2).first()])
  m["slice/sum/-2/1"] = (
    [@pl.col("k")],
    [@pl.col("v").slice(-2, length=1).sum()],
  )
  m["slice/len/-2/1"] = (
    [@pl.col("k")],
    [@pl.col("v").slice(-2, length=1).len()],
  )
  m["slice/first/-2/1"] = (
    [@pl.col("k")],
    [@pl.col("v").slice(-2, length=1).first()],
  )
  m["slice/sum/5/3"] = ([@pl.col("k")], [@pl.col("v").slice(5, length=3).sum()])
  m["slice/len/5/3"] = ([@pl.col("k")], [@pl.col("v").slice(5, length=3).len()])
  m["slice/first/5/3"] = (
    [@pl.col("k")],
    [@pl.col("v").slice(5, length=3).first()],
  )
  m["slice/sum/0/0"] = ([@pl.col("k")], [@pl.col("v").slice(0, length=0).sum()])
  m["slice/len/0/0"] = ([@pl.col("k")], [@pl.col("v").slice(0, length=0).len()])
  m["slice/first/0/0"] = (
    [@pl.col("k")],
    [@pl.col("v").slice(0, length=0).first()],
  )
  m["head/first/type/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").head(n=2).first()],
  )
  m["tail/last/type/i32"] = ([@pl.col("k")], [@pl.col("i32").tail(n=2).last()])
  m["head/first/type/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").head(n=2).first()],
  )
  m["tail/last/type/f64"] = ([@pl.col("k")], [@pl.col("f64").tail(n=2).last()])
  m["head/first/type/s"] = ([@pl.col("k")], [@pl.col("s").head(n=2).first()])
  m["tail/last/type/s"] = ([@pl.col("k")], [@pl.col("s").tail(n=2).last()])
  m["head/first/type/b"] = ([@pl.col("k")], [@pl.col("b").head(n=2).first()])
  m["tail/last/type/b"] = ([@pl.col("k")], [@pl.col("b").tail(n=2).last()])
}

///|
fn golden_group_by_ext_cases_8(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["head/first/type/d"] = ([@pl.col("k")], [@pl.col("d").head(n=2).first()])
  m["tail/last/type/d"] = ([@pl.col("k")], [@pl.col("d").tail(n=2).last()])
  m["head/first/type/n"] = ([@pl.col("k")], [@pl.col("n").head(n=2).first()])
  m["tail/last/type/n"] = ([@pl.col("k")], [@pl.col("n").tail(n=2).last()])
  m["head/sum-f64"] = ([@pl.col("k")], [@pl.col("f64").head(n=2).sum()])
  m["head/mean"] = ([@pl.col("k")], [@pl.col("x").head(n=2).mean()])
  m["head/sum-of-sorted"] = (
    [@pl.col("k")],
    [@pl.col("v").sort(descending=true).head(n=2).sum()],
  )
  m["head/sum-top-2-by"] = (
    [@pl.col("k")],
    [
      @pl.col("y")
      .sort_by([@pl.col("v"), @pl.col("id")], descending=[true, true])
      .head(n=2)
      .sum(),
    ],
  )
  m["head/e"] = ([@pl.col("k")], [@pl.col("v").head(n=2).sum()])
  m["head/no-key"] = (
    [],
    [@pl.col("v").head(n=2).sum(), @pl.col("v").tail(n=3).len().alias("l")],
  )
  m["head/by-j"] = ([@pl.col("j")], [@pl.col("v").head(n=2).sum()])
  m["head/with-len"] = (
    [@pl.col("k")],
    [@pl.col("v").head(n=2).sum() + @pl.len()],
  )
  m["head/default"] = ([@pl.col("k")], [@pl.col("v").head(n=10).len()])
  m["head/negative"] = ([@pl.col("k")], [@pl.col("v").head(n=-1).len()])
  m["head/lit"] = ([@pl.col("k")], [@pl.lit_int(1L).head(n=3).sum()])
  m["head/list"] = ([@pl.col("k")], [@pl.col("v").head(n=2)])
  m["head/list-1"] = ([@pl.col("k")], [@pl.col("v").head(n=1)])
  m["tail/list"] = ([@pl.col("k")], [@pl.col("v").tail(n=2)])
  m["slice/list"] = ([@pl.col("k")], [@pl.col("v").slice(1, length=2)])
  m["head/list-of-sum"] = ([@pl.col("k")], [@pl.col("v").sum().head(n=1)])
  m["head/list-plus"] = (
    [@pl.col("k")],
    [@pl.col("v").head(n=2) + @pl.lit_int(1L)],
  )
  m["head/list-two"] = (
    [@pl.col("k")],
    [@pl.col("v").head(n=2), @pl.col("v").sum().alias("s")],
  )
  m["any/b"] = ([@pl.col("k")], [@pl.col("b").any()])
  m["all/b"] = ([@pl.col("k")], [@pl.col("b").all()])
  m["any/i32"] = ([@pl.col("k")], [@pl.col("i32").any()])
  m["all/i32"] = ([@pl.col("k")], [@pl.col("i32").all()])
  m["any/f64"] = ([@pl.col("k")], [@pl.col("f64").any()])
  m["all/f64"] = ([@pl.col("k")], [@pl.col("f64").all()])
  m["any/vn"] = ([@pl.col("k")], [@pl.col("vn").any()])
  m["all/vn"] = ([@pl.col("k")], [@pl.col("vn").all()])
  m["any/n"] = ([@pl.col("k")], [@pl.col("n").any()])
  m["all/n"] = ([@pl.col("k")], [@pl.col("n").all()])
  m["any/cmp"] = ([@pl.col("k")], [@pl.col("v").gt(@pl.lit_int(8L)).any()])
  m["all/cmp"] = ([@pl.col("k")], [@pl.col("v").gt(@pl.lit_int(0L)).all()])
  m["any/e"] = (
    [@pl.col("k")],
    [@pl.col("b").any(), @pl.col("b").all().alias("a")],
  )
  m["any/no-key"] = ([], [@pl.col("b").any(), @pl.col("b").all().alias("a")])
  m["any/b-keep"] = ([@pl.col("k")], [@pl.col("b").any(ignore_nulls=false)])
  m["all/b-keep"] = ([@pl.col("k")], [@pl.col("b").all(ignore_nulls=false)])
  m["any/i32-keep"] = ([@pl.col("k")], [@pl.col("i32").any(ignore_nulls=false)])
  m["all/i32-keep"] = ([@pl.col("k")], [@pl.col("i32").all(ignore_nulls=false)])
}

///|
fn golden_group_by_ext_cases_9(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["any/f64-keep"] = ([@pl.col("k")], [@pl.col("f64").any(ignore_nulls=false)])
  m["all/f64-keep"] = ([@pl.col("k")], [@pl.col("f64").all(ignore_nulls=false)])
  m["any/vn-keep"] = ([@pl.col("k")], [@pl.col("vn").any(ignore_nulls=false)])
  m["all/vn-keep"] = ([@pl.col("k")], [@pl.col("vn").all(ignore_nulls=false)])
  m["any/n-keep"] = ([@pl.col("k")], [@pl.col("n").any(ignore_nulls=false)])
  m["all/n-keep"] = ([@pl.col("k")], [@pl.col("n").all(ignore_nulls=false)])
  m["any/cmp-keep"] = (
    [@pl.col("k")],
    [@pl.col("v").gt(@pl.lit_int(8L)).any(ignore_nulls=false)],
  )
  m["all/cmp-keep"] = (
    [@pl.col("k")],
    [@pl.col("v").gt(@pl.lit_int(0L)).all(ignore_nulls=false)],
  )
  m["any/e-keep"] = (
    [@pl.col("k")],
    [
      @pl.col("b").any(ignore_nulls=false),
      @pl.col("b").all(ignore_nulls=false).alias("a"),
    ],
  )
  m["any/no-key-keep"] = (
    [],
    [
      @pl.col("b").any(ignore_nulls=false),
      @pl.col("b").all(ignore_nulls=false).alias("a"),
    ],
  )
  m["any/of-filter"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("v").gt(@pl.lit_int(2L))).any()],
  )
  m["all/of-filter-empty"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("v").gt(@pl.lit_int(100L))).all()],
  )
  m["any/of-filter-empty"] = (
    [@pl.col("k")],
    [@pl.col("b").filter(@pl.col("v").gt(@pl.lit_int(100L))).any()],
  )
  m["any/of-sort"] = ([@pl.col("k")], [@pl.col("b").sort().any()])
  m["any/of-head"] = ([@pl.col("k")], [@pl.col("b").head(n=1).any()])
  m["any/of-scalar"] = ([@pl.col("k")], [@pl.col("v").sum().any().alias("a")])
  m["any/of-lit"] = ([@pl.col("k")], [@pl.lit_bool(true).any().alias("a")])
  m["all/of-lit-false"] = (
    [@pl.col("k")],
    [@pl.lit_bool(false).all().alias("a")],
  )
  m["any/in-when"] = (
    [@pl.col("k")],
    [
      @pl.when(@pl.col("v").gt(@pl.lit_int(8L)).any())
      .then(@pl.lit_int(1L))
      .otherwise(@pl.lit_int(0L))
      .alias("w"),
    ],
  )
  m["any/and-all"] = (
    [@pl.col("k")],
    [
      @pl.col("b").any().alias("a"),
      @pl.col("b").all().alias("l"),
      @pl.col("v").sum(),
    ],
  )
  m["any/not"] = ([@pl.col("k")], [@pl.col("b").any().not_().alias("n")])
  m["any/of-str"] = ([@pl.col("k")], [@pl.col("s").any()])
  m["any/of-date"] = ([@pl.col("k")], [@pl.col("d").any()])
  m["any/by-j"] = (
    [@pl.col("j")],
    [@pl.col("b").any(), @pl.col("v").gt(@pl.lit_int(0L)).all().alias("a")],
  )
  m["any/by-two"] = (
    [@pl.col("k"), @pl.col("j")],
    [@pl.col("b").any(), @pl.col("b").all().alias("a")],
  )
  m["horiz/sum/scalars"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("v").sum(), @pl.col("y").max()])],
  )
  m["horiz/sum/scalar-lit"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("v").sum(), @pl.lit_int(1L)])],
  )
  m["horiz/sum/scalar-lit-strong"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("v").sum(), @pl.lit(@pl.AnyValue::Int64(5L))])],
  )
  m["horiz/sum/three-scalars"] = (
    [@pl.col("k")],
    [
      @pl.sum_horizontal([
        @pl.col("v").sum(),
        @pl.col("y").max(),
        @pl.col("v").len(),
      ]),
    ],
  )
  m["horiz/sum/floats"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("v").mean(), @pl.col("x").max()])],
  )
  m["horiz/sum/len"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.len(), @pl.col("v").sum()])],
  )
  m["horiz/sum/sum-of-rows"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("v"), @pl.col("y")]).sum()],
  )
  m["horiz/sum/first-of-rows"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("v"), @pl.col("x")]).first()],
  )
  m["horiz/sum/last-of-rows-nulls"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("vn"), @pl.col("v")]).last()],
  )
  m["horiz/sum/rows-and-scalar-inside"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("v"), @pl.col("v").mean()]).sum()],
  )
  m["horiz/sum/e"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("v").sum(), @pl.col("y").max()])],
  )
  m["horiz/sum/no-key"] = (
    [],
    [@pl.sum_horizontal([@pl.col("v").sum(), @pl.col("y").max()])],
  )
  m["horiz/sum/plus-one"] = (
    [@pl.col("k")],
    [
      (@pl.sum_horizontal([@pl.col("v").sum(), @pl.col("y").max()]) +
      @pl.lit_int(1L)).alias("h"),
    ],
  )
  m["horiz/sum/list-rows"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("v"), @pl.col("y")])],
  )
  m["horiz/sum/list-mixed"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("v"), @pl.col("y").sum()])],
  )
}

///|
fn golden_group_by_ext_cases_10(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["horiz/min/scalars"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("v").sum(), @pl.col("y").max()])],
  )
  m["horiz/min/scalar-lit"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("v").sum(), @pl.lit_int(1L)])],
  )
  m["horiz/min/scalar-lit-strong"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("v").sum(), @pl.lit(@pl.AnyValue::Int64(5L))])],
  )
  m["horiz/min/three-scalars"] = (
    [@pl.col("k")],
    [
      @pl.min_horizontal([
        @pl.col("v").sum(),
        @pl.col("y").max(),
        @pl.col("v").len(),
      ]),
    ],
  )
  m["horiz/min/floats"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("v").mean(), @pl.col("x").max()])],
  )
  m["horiz/min/len"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.len(), @pl.col("v").sum()])],
  )
  m["horiz/min/sum-of-rows"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("v"), @pl.col("y")]).sum()],
  )
  m["horiz/min/first-of-rows"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("v"), @pl.col("x")]).first()],
  )
  m["horiz/min/last-of-rows-nulls"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("vn"), @pl.col("v")]).last()],
  )
  m["horiz/min/rows-and-scalar-inside"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("v"), @pl.col("v").mean()]).sum()],
  )
  m["horiz/min/e"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("v").sum(), @pl.col("y").max()])],
  )
  m["horiz/min/no-key"] = (
    [],
    [@pl.min_horizontal([@pl.col("v").sum(), @pl.col("y").max()])],
  )
  m["horiz/min/plus-one"] = (
    [@pl.col("k")],
    [
      (@pl.min_horizontal([@pl.col("v").sum(), @pl.col("y").max()]) +
      @pl.lit_int(1L)).alias("h"),
    ],
  )
  m["horiz/min/list-rows"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("v"), @pl.col("y")])],
  )
  m["horiz/min/list-mixed"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("v"), @pl.col("y").sum()])],
  )
  m["horiz/max/scalars"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("v").sum(), @pl.col("y").max()])],
  )
  m["horiz/max/scalar-lit"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("v").sum(), @pl.lit_int(1L)])],
  )
  m["horiz/max/scalar-lit-strong"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("v").sum(), @pl.lit(@pl.AnyValue::Int64(5L))])],
  )
  m["horiz/max/three-scalars"] = (
    [@pl.col("k")],
    [
      @pl.max_horizontal([
        @pl.col("v").sum(),
        @pl.col("y").max(),
        @pl.col("v").len(),
      ]),
    ],
  )
  m["horiz/max/floats"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("v").mean(), @pl.col("x").max()])],
  )
  m["horiz/max/len"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.len(), @pl.col("v").sum()])],
  )
  m["horiz/max/sum-of-rows"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("v"), @pl.col("y")]).sum()],
  )
  m["horiz/max/first-of-rows"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("v"), @pl.col("x")]).first()],
  )
  m["horiz/max/last-of-rows-nulls"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("vn"), @pl.col("v")]).last()],
  )
  m["horiz/max/rows-and-scalar-inside"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("v"), @pl.col("v").mean()]).sum()],
  )
  m["horiz/max/e"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("v").sum(), @pl.col("y").max()])],
  )
  m["horiz/max/no-key"] = (
    [],
    [@pl.max_horizontal([@pl.col("v").sum(), @pl.col("y").max()])],
  )
  m["horiz/max/plus-one"] = (
    [@pl.col("k")],
    [
      (@pl.max_horizontal([@pl.col("v").sum(), @pl.col("y").max()]) +
      @pl.lit_int(1L)).alias("h"),
    ],
  )
  m["horiz/max/list-rows"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("v"), @pl.col("y")])],
  )
  m["horiz/max/list-mixed"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("v"), @pl.col("y").sum()])],
  )
  m["horiz/sum/keep-nulls"] = (
    [@pl.col("k")],
    [
      @pl.sum_horizontal(
        [@pl.col("vn").first(), @pl.col("vn").last()],
        ignore_nulls=false,
      ),
    ],
  )
  m["horiz/sum/ignore-nulls"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("vn").first(), @pl.col("vn").last()])],
  )
  m["horiz/sum/null-aggregate"] = (
    [@pl.col("k")],
    [
      @pl.sum_horizontal(
        [@pl.col("i32").first(), @pl.col("v").sum()],
        ignore_nulls=false,
      ),
    ],
  )
  m["horiz/sum/strings-min"] = (
    [@pl.col("k")],
    [@pl.min_horizontal([@pl.col("s").first(), @pl.col("s").last()])],
  )
  m["horiz/sum/bool-max"] = (
    [@pl.col("k")],
    [@pl.max_horizontal([@pl.col("b").first(), @pl.col("b").last()])],
  )
  m["horiz/sum/types"] = (
    [@pl.col("k")],
    [@pl.sum_horizontal([@pl.col("i32").sum(), @pl.col("f32").sum()])],
  )
  m["over/sum-first"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().over([@pl.col("j")]).first()],
  )
  m["over/cum-first"] = (
    [@pl.col("k")],
    [@pl.col("v").cum_sum().over([@pl.col("j")]).first()],
  )
  m["over/len-first"] = (
    [@pl.col("k")],
    [@pl.len().over([@pl.col("j")]).first()],
  )
  m["over/sum-last"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().over([@pl.col("j")]).last()],
  )
}

///|
fn golden_group_by_ext_cases_11(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["over/cum-last"] = (
    [@pl.col("k")],
    [@pl.col("v").cum_sum().over([@pl.col("j")]).last()],
  )
  m["over/len-last"] = ([@pl.col("k")], [@pl.len().over([@pl.col("j")]).last()])
  m["over/sum-sum"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().over([@pl.col("j")]).sum()],
  )
  m["over/cum-sum"] = (
    [@pl.col("k")],
    [@pl.col("v").cum_sum().over([@pl.col("j")]).sum()],
  )
  m["over/len-sum"] = ([@pl.col("k")], [@pl.len().over([@pl.col("j")]).sum()])
  m["over/sum-max"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().over([@pl.col("j")]).max()],
  )
  m["over/cum-max"] = (
    [@pl.col("k")],
    [@pl.col("v").cum_sum().over([@pl.col("j")]).max()],
  )
  m["over/len-max"] = ([@pl.col("k")], [@pl.len().over([@pl.col("j")]).max()])
  m["over/sum-len"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().over([@pl.col("j")]).len()],
  )
  m["over/cum-len"] = (
    [@pl.col("k")],
    [@pl.col("v").cum_sum().over([@pl.col("j")]).len()],
  )
  m["over/len-len"] = ([@pl.col("k")], [@pl.len().over([@pl.col("j")]).len()])
  m["over/same-key"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().over([@pl.col("k")]).sum()],
  )
  m["over/key-id"] = (
    [@pl.col("k")],
    [@pl.col("v").cum_sum().over([@pl.col("id")]).sum()],
  )
  m["over/two-keys"] = (
    [@pl.col("k")],
    [@pl.col("v").cum_sum().over([@pl.col("j"), @pl.col("b")]).sum()],
  )
  m["over/dev-inside"] = (
    [@pl.col("k")],
    [(@pl.col("v") - @pl.col("v").mean().over([@pl.col("j")])).sum()],
  )
  m["over/dev-sum-of-window"] = (
    [@pl.col("k")],
    [(@pl.col("v") - @pl.col("v").mean()).over([@pl.col("j")]).max()],
  )
  m["over/shift-last"] = (
    [@pl.col("k")],
    [@pl.col("v").shift(n=1).over([@pl.col("j")]).last()],
  )
  m["over/rank-max"] = (
    [@pl.col("k")],
    [
      @pl.col("v")
      .rank(method_=@pl.RankMethod::Dense)
      .over([@pl.col("j")])
      .max(),
    ],
  )
  m["over/mixed"] = (
    [@pl.col("k")],
    [
      @pl.col("v").cum_sum().over([@pl.col("j")]).sum().alias("a"),
      @pl.col("v").sum().alias("b"),
      @pl.len(),
    ],
  )
  m["over/plus-agg"] = (
    [@pl.col("k")],
    [
      (@pl.col("v").sum().over([@pl.col("j")]).first() + @pl.col("v").sum()).alias(
        "p",
      ),
    ],
  )
  m["over/sort-first"] = (
    [@pl.col("k")],
    [@pl.col("v").sort().over([@pl.col("j")]).first()],
  )
  m["over/e"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().over([@pl.col("j")]).first()],
  )
  m["over/no-key"] = (
    [],
    [
      @pl.col("v").sum().over([@pl.col("j")]).first(),
      @pl.col("v").cum_sum().over([@pl.col("k")]).sum().alias("c"),
    ],
  )
  m["over/lit"] = (
    [@pl.col("k")],
    [@pl.lit_int(1L).over([@pl.col("j")]).first()],
  )
  m["over/any"] = (
    [@pl.col("k")],
    [@pl.col("b").any().over([@pl.col("j")]).sum()],
  )
  m["over/inner-key-expr"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().over([@pl.col("v") % @pl.lit_int(2L)]).sum()],
  )
  m["over/missing-key"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().over([@pl.col("zz")]).first()],
  )
  m["over/head-too-short"] = (
    [@pl.col("k")],
    [@pl.col("v").head(n=1).over([@pl.col("j")]).first()],
  )
  m["over/head-fits-by-id"] = (
    [@pl.col("k")],
    [@pl.col("v").head(n=1).over([@pl.col("id")]).sum()],
  )
  m["over/list"] = ([@pl.col("k")], [@pl.col("v").sum().over([@pl.col("j")])])
  m["over/list-by-key"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().over([@pl.col("k")])],
  )
  m["over/list-plus"] = (
    [@pl.col("k")],
    [@pl.col("v").sum().over([@pl.col("j")]) + @pl.lit_int(1L)],
  )
  m["over/list-cum"] = (
    [@pl.col("k")],
    [@pl.col("v").cum_sum().over([@pl.col("j")])],
  )
  m["combo/everything"] = (
    [@pl.col("k")],
    [
      @pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum().alias("fs"),
      @pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).first().alias("sb"),
      @pl.col("v").sort().last().alias("mx"),
      @pl.col("v").unique().len().alias("nu"),
      @pl.col("v").head(n=2).sum().alias("h2"),
      @pl.col("b").any().alias("any"),
      @pl.sum_horizontal([@pl.col("v").sum(), @pl.col("y").max()]).alias("hz"),
      @pl.len(),
    ],
  )
  m["combo/everything-e"] = (
    [@pl.col("k")],
    [
      @pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum().alias("fs"),
      @pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).first().alias("sb"),
      @pl.col("v").sort().last().alias("mx"),
      @pl.col("v").unique().len().alias("nu"),
      @pl.col("v").head(n=2).sum().alias("h2"),
      @pl.col("b").any().alias("any"),
      @pl.sum_horizontal([@pl.col("v").sum(), @pl.col("y").max()]).alias("hz"),
      @pl.len(),
    ],
  )
  m["combo/by-expr-key"] = (
    [@pl.col("v") % @pl.lit_int(2L)],
    [
      @pl.col("y").filter(@pl.col("x").gt(@pl.lit_float(0.5))).sum(),
      @pl.col("v").sort(descending=true).first().alias("m"),
    ],
  )
  m["combo/by-null-key-f64"] = (
    [@pl.col("f64")],
    [
      @pl.col("y").filter(@pl.col("y").gt(@pl.lit_int(30L))).sum(),
      @pl.col("s").unique().len().alias("u"),
      @pl.col("b").any().alias("a"),
    ],
  )
  m["combo/by-null-key-f32"] = (
    [@pl.col("f32")],
    [
      @pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).first(),
      @pl.col("y").head(n=1).sum().alias("h"),
    ],
  )
  m["combo/sum-of-filter-over-total"] = (
    [@pl.col("k")],
    [
      (@pl.col("y").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum() /
      @pl.col("y").sum()).alias("share"),
    ],
  )
  m["combo/dup-name"] = (
    [@pl.col("k")],
    [
      @pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum(),
      @pl.col("v").head(n=2).sum(),
    ],
  )
}

///|
fn golden_group_by_ext_cases_12(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["combo/key-name"] = (
    [@pl.col("k")],
    [@pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).sum().alias("k")],
  )
  m["combo/cols"] = (
    [@pl.col("k")],
    [@pl.cols(["v", "y"]).filter(@pl.col("v").gt(@pl.lit_int(2L))).sum()],
  )
  m["combo/all-numbers"] = (
    [@pl.col("k")],
    [@pl.cols(["v", "x", "y"]).sort().first()],
  )
  m["div/agg-quotient-times-col"] = (
    [@pl.col("k")],
    [(@pl.col("f").max() / @pl.col("f").sum() * @pl.col("f")).last()],
  )
  m["div/agg-quotient-over-col"] = (
    [@pl.col("k")],
    [(@pl.col("f").last() / @pl.col("f").sum() / @pl.col("f")).first()],
  )
  m["div/agg-quotient-len-times-col"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum() / @pl.len() * @pl.col("f")).last()],
  )
  m["div/agg-quotient-f32"] = (
    [@pl.col("k")],
    [(@pl.col("f3").max() / @pl.col("f3").sum() * @pl.col("f3")).last()],
  )
  m["div/div/f-by-first"] = (
    [@pl.col("k")],
    [(@pl.col("f") / @pl.col("f").first()).last()],
  )
  m["div/div/f-by-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f") / @pl.col("f").sum()).last()],
  )
  m["div/div/f-by-agg-expr"] = (
    [@pl.col("k")],
    [(@pl.col("f") / (@pl.col("f").max() + @pl.lit_int(1L))).sum()],
  )
  m["div/div/f-by-mixed"] = (
    [@pl.col("k")],
    [(@pl.col("f") / (@pl.col("f") + @pl.col("f").first())).sum()],
  )
  m["div/div/f-agg-by-col"] = (
    [@pl.col("k")],
    [(@pl.col("f").first() / @pl.col("f")).sum()],
  )
  m["div/div/f-agg-by-agg"] = (
    [@pl.col("k")],
    [@pl.col("f").sum() / @pl.col("f").first()],
  )
  m["div/div/f3-by-first"] = (
    [@pl.col("k")],
    [(@pl.col("f3") / @pl.col("f3").first()).last()],
  )
  m["div/div/f3-by-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f3") / @pl.col("f3").sum()).last()],
  )
  m["div/div/f3-by-agg-expr"] = (
    [@pl.col("k")],
    [(@pl.col("f3") / (@pl.col("f3").max() + @pl.lit_int(1L))).sum()],
  )
  m["div/div/f3-by-mixed"] = (
    [@pl.col("k")],
    [(@pl.col("f3") / (@pl.col("f3") + @pl.col("f3").first())).sum()],
  )
  m["div/div/f3-agg-by-col"] = (
    [@pl.col("k")],
    [(@pl.col("f3").first() / @pl.col("f3")).sum()],
  )
  m["div/div/f3-agg-by-agg"] = (
    [@pl.col("k")],
    [@pl.col("f3").sum() / @pl.col("f3").first()],
  )
  m["div/div/n-by-first"] = (
    [@pl.col("k")],
    [(@pl.col("n") / @pl.col("n").first()).last()],
  )
  m["div/div/n-by-sum"] = (
    [@pl.col("k")],
    [(@pl.col("n") / @pl.col("n").sum()).last()],
  )
  m["div/div/n-by-agg-expr"] = (
    [@pl.col("k")],
    [(@pl.col("n") / (@pl.col("n").max() + @pl.lit_int(1L))).sum()],
  )
  m["div/div/n-by-mixed"] = (
    [@pl.col("k")],
    [(@pl.col("n") / (@pl.col("n") + @pl.col("n").first())).sum()],
  )
  m["div/div/n-agg-by-col"] = (
    [@pl.col("k")],
    [(@pl.col("n").first() / @pl.col("n")).sum()],
  )
  m["div/div/n-agg-by-agg"] = (
    [@pl.col("k")],
    [@pl.col("n").sum() / @pl.col("n").first()],
  )
  m["div/floordiv/f-by-first"] = (
    [@pl.col("k")],
    [@pl.col("f").floor_div(@pl.col("f").first()).last()],
  )
  m["div/floordiv/f-by-sum"] = (
    [@pl.col("k")],
    [@pl.col("f").floor_div(@pl.col("f").sum()).last()],
  )
  m["div/floordiv/f-by-agg-expr"] = (
    [@pl.col("k")],
    [@pl.col("f").floor_div(@pl.col("f").max() + @pl.lit_int(1L)).sum()],
  )
  m["div/floordiv/f-by-mixed"] = (
    [@pl.col("k")],
    [@pl.col("f").floor_div(@pl.col("f") + @pl.col("f").first()).sum()],
  )
  m["div/floordiv/f-agg-by-col"] = (
    [@pl.col("k")],
    [@pl.col("f").first().floor_div(@pl.col("f")).sum()],
  )
  m["div/floordiv/f-agg-by-agg"] = (
    [@pl.col("k")],
    [@pl.col("f").sum().floor_div(@pl.col("f").first())],
  )
  m["div/floordiv/f3-by-first"] = (
    [@pl.col("k")],
    [@pl.col("f3").floor_div(@pl.col("f3").first()).last()],
  )
  m["div/floordiv/f3-by-sum"] = (
    [@pl.col("k")],
    [@pl.col("f3").floor_div(@pl.col("f3").sum()).last()],
  )
  m["div/floordiv/f3-by-agg-expr"] = (
    [@pl.col("k")],
    [@pl.col("f3").floor_div(@pl.col("f3").max() + @pl.lit_int(1L)).sum()],
  )
  m["div/floordiv/f3-by-mixed"] = (
    [@pl.col("k")],
    [@pl.col("f3").floor_div(@pl.col("f3") + @pl.col("f3").first()).sum()],
  )
  m["div/floordiv/f3-agg-by-col"] = (
    [@pl.col("k")],
    [@pl.col("f3").first().floor_div(@pl.col("f3")).sum()],
  )
  m["div/floordiv/f3-agg-by-agg"] = (
    [@pl.col("k")],
    [@pl.col("f3").sum().floor_div(@pl.col("f3").first())],
  )
  m["div/floordiv/n-by-first"] = (
    [@pl.col("k")],
    [@pl.col("n").floor_div(@pl.col("n").first()).last()],
  )
  m["div/floordiv/n-by-sum"] = (
    [@pl.col("k")],
    [@pl.col("n").floor_div(@pl.col("n").sum()).last()],
  )
  m["div/floordiv/n-by-agg-expr"] = (
    [@pl.col("k")],
    [@pl.col("n").floor_div(@pl.col("n").max() + @pl.lit_int(1L)).sum()],
  )
}

///|
fn golden_group_by_ext_cases_13(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["div/floordiv/n-by-mixed"] = (
    [@pl.col("k")],
    [@pl.col("n").floor_div(@pl.col("n") + @pl.col("n").first()).sum()],
  )
  m["div/floordiv/n-agg-by-col"] = (
    [@pl.col("k")],
    [@pl.col("n").first().floor_div(@pl.col("n")).sum()],
  )
  m["div/floordiv/n-agg-by-agg"] = (
    [@pl.col("k")],
    [@pl.col("n").sum().floor_div(@pl.col("n").first())],
  )
  m["div/mod/f-by-first"] = (
    [@pl.col("k")],
    [(@pl.col("f") % @pl.col("f").first()).last()],
  )
  m["div/mod/f-by-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f") % @pl.col("f").sum()).last()],
  )
  m["div/mod/f-by-agg-expr"] = (
    [@pl.col("k")],
    [(@pl.col("f") % (@pl.col("f").max() + @pl.lit_int(1L))).sum()],
  )
  m["div/mod/f-by-mixed"] = (
    [@pl.col("k")],
    [(@pl.col("f") % (@pl.col("f") + @pl.col("f").first())).sum()],
  )
  m["div/mod/f-agg-by-col"] = (
    [@pl.col("k")],
    [(@pl.col("f").first() % @pl.col("f")).sum()],
  )
  m["div/mod/f-agg-by-agg"] = (
    [@pl.col("k")],
    [@pl.col("f").sum() % @pl.col("f").first()],
  )
  m["div/mod/f3-by-first"] = (
    [@pl.col("k")],
    [(@pl.col("f3") % @pl.col("f3").first()).last()],
  )
  m["div/mod/f3-by-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f3") % @pl.col("f3").sum()).last()],
  )
  m["div/mod/f3-by-agg-expr"] = (
    [@pl.col("k")],
    [(@pl.col("f3") % (@pl.col("f3").max() + @pl.lit_int(1L))).sum()],
  )
  m["div/mod/f3-by-mixed"] = (
    [@pl.col("k")],
    [(@pl.col("f3") % (@pl.col("f3") + @pl.col("f3").first())).sum()],
  )
  m["div/mod/f3-agg-by-col"] = (
    [@pl.col("k")],
    [(@pl.col("f3").first() % @pl.col("f3")).sum()],
  )
  m["div/mod/f3-agg-by-agg"] = (
    [@pl.col("k")],
    [@pl.col("f3").sum() % @pl.col("f3").first()],
  )
  m["div/mod/n-by-first"] = (
    [@pl.col("k")],
    [(@pl.col("n") % @pl.col("n").first()).last()],
  )
  m["div/mod/n-by-sum"] = (
    [@pl.col("k")],
    [(@pl.col("n") % @pl.col("n").sum()).last()],
  )
  m["div/mod/n-by-agg-expr"] = (
    [@pl.col("k")],
    [(@pl.col("n") % (@pl.col("n").max() + @pl.lit_int(1L))).sum()],
  )
  m["div/mod/n-by-mixed"] = (
    [@pl.col("k")],
    [(@pl.col("n") % (@pl.col("n") + @pl.col("n").first())).sum()],
  )
  m["div/mod/n-agg-by-col"] = (
    [@pl.col("k")],
    [(@pl.col("n").first() % @pl.col("n")).sum()],
  )
  m["div/mod/n-agg-by-agg"] = (
    [@pl.col("k")],
    [@pl.col("n").sum() % @pl.col("n").first()],
  )
  m["div/floordiv/f-grid-sum-first"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum().floor_div(@pl.col("f").first()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-sum-min"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum().floor_div(@pl.col("f").min()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-sum-last"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum().floor_div(@pl.col("f").last()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-sum-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum().floor_div(@pl.col("f").mean()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-sum-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum().floor_div(@pl.col("f").sum()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-sum-max"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum().floor_div(@pl.col("f").max()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-max-first"] = (
    [@pl.col("k")],
    [(@pl.col("f").max().floor_div(@pl.col("f").first()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-max-min"] = (
    [@pl.col("k")],
    [(@pl.col("f").max().floor_div(@pl.col("f").min()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-max-last"] = (
    [@pl.col("k")],
    [(@pl.col("f").max().floor_div(@pl.col("f").last()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-max-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f").max().floor_div(@pl.col("f").mean()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-max-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f").max().floor_div(@pl.col("f").sum()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-max-max"] = (
    [@pl.col("k")],
    [(@pl.col("f").max().floor_div(@pl.col("f").max()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-last-first"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").last().floor_div(@pl.col("f").first()) * @pl.col("f")).last(),
    ],
  )
  m["div/floordiv/f-grid-last-min"] = (
    [@pl.col("k")],
    [(@pl.col("f").last().floor_div(@pl.col("f").min()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-last-last"] = (
    [@pl.col("k")],
    [(@pl.col("f").last().floor_div(@pl.col("f").last()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-last-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f").last().floor_div(@pl.col("f").mean()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-last-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f").last().floor_div(@pl.col("f").sum()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-last-max"] = (
    [@pl.col("k")],
    [(@pl.col("f").last().floor_div(@pl.col("f").max()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-mean-first"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").mean().floor_div(@pl.col("f").first()) * @pl.col("f")).last(),
    ],
  )
}

///|
fn golden_group_by_ext_cases_14(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["div/floordiv/f-grid-mean-min"] = (
    [@pl.col("k")],
    [(@pl.col("f").mean().floor_div(@pl.col("f").min()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-mean-last"] = (
    [@pl.col("k")],
    [(@pl.col("f").mean().floor_div(@pl.col("f").last()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-mean-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f").mean().floor_div(@pl.col("f").mean()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-mean-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f").mean().floor_div(@pl.col("f").sum()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f-grid-mean-max"] = (
    [@pl.col("k")],
    [(@pl.col("f").mean().floor_div(@pl.col("f").max()) * @pl.col("f")).last()],
  )
  m["div/floordiv/f3-grid-sum-first"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").sum().floor_div(@pl.col("f3").first()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-sum-min"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").sum().floor_div(@pl.col("f3").min()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-sum-last"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").sum().floor_div(@pl.col("f3").last()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-sum-mean"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").sum().floor_div(@pl.col("f3").mean()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-sum-sum"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").sum().floor_div(@pl.col("f3").sum()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-sum-max"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").sum().floor_div(@pl.col("f3").max()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-max-first"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").max().floor_div(@pl.col("f3").first()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-max-min"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").max().floor_div(@pl.col("f3").min()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-max-last"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").max().floor_div(@pl.col("f3").last()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-max-mean"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").max().floor_div(@pl.col("f3").mean()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-max-sum"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").max().floor_div(@pl.col("f3").sum()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-max-max"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").max().floor_div(@pl.col("f3").max()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-last-first"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").last().floor_div(@pl.col("f3").first()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-last-min"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").last().floor_div(@pl.col("f3").min()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-last-last"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").last().floor_div(@pl.col("f3").last()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-last-mean"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").last().floor_div(@pl.col("f3").mean()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-last-sum"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").last().floor_div(@pl.col("f3").sum()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-last-max"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").last().floor_div(@pl.col("f3").max()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-mean-first"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").mean().floor_div(@pl.col("f3").first()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-mean-min"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").mean().floor_div(@pl.col("f3").min()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-mean-last"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").mean().floor_div(@pl.col("f3").last()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-mean-mean"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").mean().floor_div(@pl.col("f3").mean()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-mean-sum"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").mean().floor_div(@pl.col("f3").sum()) * @pl.col("f3")).last(),
    ],
  )
  m["div/floordiv/f3-grid-mean-max"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").mean().floor_div(@pl.col("f3").max()) * @pl.col("f3")).last(),
    ],
  )
  m["div/mod/f-grid-sum-first"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum() % @pl.col("f").first() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-sum-min"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum() % @pl.col("f").min() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-sum-last"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum() % @pl.col("f").last() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-sum-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum() % @pl.col("f").mean() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-sum-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum() % @pl.col("f").sum() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-sum-max"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum() % @pl.col("f").max() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-max-first"] = (
    [@pl.col("k")],
    [(@pl.col("f").max() % @pl.col("f").first() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-max-min"] = (
    [@pl.col("k")],
    [(@pl.col("f").max() % @pl.col("f").min() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-max-last"] = (
    [@pl.col("k")],
    [(@pl.col("f").max() % @pl.col("f").last() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-max-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f").max() % @pl.col("f").mean() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-max-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f").max() % @pl.col("f").sum() * @pl.col("f")).last()],
  )
}

///|
fn golden_group_by_ext_cases_15(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["div/mod/f-grid-max-max"] = (
    [@pl.col("k")],
    [(@pl.col("f").max() % @pl.col("f").max() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-last-first"] = (
    [@pl.col("k")],
    [(@pl.col("f").last() % @pl.col("f").first() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-last-min"] = (
    [@pl.col("k")],
    [(@pl.col("f").last() % @pl.col("f").min() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-last-last"] = (
    [@pl.col("k")],
    [(@pl.col("f").last() % @pl.col("f").last() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-last-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f").last() % @pl.col("f").mean() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-last-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f").last() % @pl.col("f").sum() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-last-max"] = (
    [@pl.col("k")],
    [(@pl.col("f").last() % @pl.col("f").max() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-mean-first"] = (
    [@pl.col("k")],
    [(@pl.col("f").mean() % @pl.col("f").first() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-mean-min"] = (
    [@pl.col("k")],
    [(@pl.col("f").mean() % @pl.col("f").min() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-mean-last"] = (
    [@pl.col("k")],
    [(@pl.col("f").mean() % @pl.col("f").last() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-mean-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f").mean() % @pl.col("f").mean() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-mean-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f").mean() % @pl.col("f").sum() * @pl.col("f")).last()],
  )
  m["div/mod/f-grid-mean-max"] = (
    [@pl.col("k")],
    [(@pl.col("f").mean() % @pl.col("f").max() * @pl.col("f")).last()],
  )
  m["div/mod/f3-grid-sum-first"] = (
    [@pl.col("k")],
    [(@pl.col("f3").sum() % @pl.col("f3").first() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-sum-min"] = (
    [@pl.col("k")],
    [(@pl.col("f3").sum() % @pl.col("f3").min() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-sum-last"] = (
    [@pl.col("k")],
    [(@pl.col("f3").sum() % @pl.col("f3").last() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-sum-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f3").sum() % @pl.col("f3").mean() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-sum-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f3").sum() % @pl.col("f3").sum() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-sum-max"] = (
    [@pl.col("k")],
    [(@pl.col("f3").sum() % @pl.col("f3").max() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-max-first"] = (
    [@pl.col("k")],
    [(@pl.col("f3").max() % @pl.col("f3").first() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-max-min"] = (
    [@pl.col("k")],
    [(@pl.col("f3").max() % @pl.col("f3").min() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-max-last"] = (
    [@pl.col("k")],
    [(@pl.col("f3").max() % @pl.col("f3").last() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-max-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f3").max() % @pl.col("f3").mean() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-max-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f3").max() % @pl.col("f3").sum() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-max-max"] = (
    [@pl.col("k")],
    [(@pl.col("f3").max() % @pl.col("f3").max() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-last-first"] = (
    [@pl.col("k")],
    [(@pl.col("f3").last() % @pl.col("f3").first() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-last-min"] = (
    [@pl.col("k")],
    [(@pl.col("f3").last() % @pl.col("f3").min() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-last-last"] = (
    [@pl.col("k")],
    [(@pl.col("f3").last() % @pl.col("f3").last() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-last-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f3").last() % @pl.col("f3").mean() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-last-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f3").last() % @pl.col("f3").sum() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-last-max"] = (
    [@pl.col("k")],
    [(@pl.col("f3").last() % @pl.col("f3").max() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-mean-first"] = (
    [@pl.col("k")],
    [(@pl.col("f3").mean() % @pl.col("f3").first() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-mean-min"] = (
    [@pl.col("k")],
    [(@pl.col("f3").mean() % @pl.col("f3").min() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-mean-last"] = (
    [@pl.col("k")],
    [(@pl.col("f3").mean() % @pl.col("f3").last() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-mean-mean"] = (
    [@pl.col("k")],
    [(@pl.col("f3").mean() % @pl.col("f3").mean() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-mean-sum"] = (
    [@pl.col("k")],
    [(@pl.col("f3").mean() % @pl.col("f3").sum() * @pl.col("f3")).last()],
  )
  m["div/mod/f3-grid-mean-max"] = (
    [@pl.col("k")],
    [(@pl.col("f3").mean() % @pl.col("f3").max() * @pl.col("f3")).last()],
  )
  m["div/rand/0"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3") %
      @pl.col("f3").first() /
      (@pl.col("f") % @pl.col("f3").max())).sum(),
    ],
  )
  m["div/rand/1"] = (
    [@pl.col("k")],
    [@pl.col("f").last() / @pl.len() * @pl.lit_int(7L)],
  )
  m["div/rand/2"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").floor_div(@pl.col("f3")) %
      (@pl.lit_float(3.0) / @pl.lit_float(0.5)))
      .floor_div(
        (@pl.lit_float(2.5) % @pl.col("f3")).floor_div(
          @pl.lit_float(3.0) % @pl.col("f3"),
        ),
      )
      .mean(),
    ],
  )
}

///|
fn golden_group_by_ext_cases_16(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["div/rand/3"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").mean() /
      (@pl.col("f3") - @pl.lit_float(2.5)) %
      @pl.col("f3").max().floor_div(@pl.col("f3") / @pl.col("f"))).sum(),
    ],
  )
  m["div/rand/4"] = (
    [@pl.col("k")],
    [@pl.col("f").floor_div(@pl.col("f").max()).last()],
  )
  m["div/rand/5"] = (
    [@pl.col("k")],
    [(@pl.col("f") % @pl.col("f").mean() * @pl.col("f").first()).sum()],
  )
  m["div/rand/6"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").sum() * @pl.col("f3") / (@pl.col("f3") * @pl.col("f"))).sum(),
    ],
  )
  m["div/rand/7"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").floor_div(@pl.col("f3")) / (@pl.col("f") % @pl.lit_int(3L))).last(),
    ],
  )
  m["div/rand/8"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").last() /
      @pl.col("f3") /
      (@pl.col("f").first() - @pl.col("f3"))).sum(),
    ],
  )
  m["div/rand/9"] = (
    [@pl.col("k")],
    [
      (@pl.col("f") %
      @pl.col("f3").sum() /
      @pl.col("f3").max().floor_div(@pl.col("f3"))).sum(),
    ],
  )
  m["div/rand/10"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").first().floor_div(@pl.lit_float(2.5) / @pl.col("f3").min()) /
      @pl.col("f3")).sum(),
    ],
  )
  m["div/rand/11"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3") -
      @pl.col("f3") -
      @pl.col("f").floor_div(@pl.col("f").last())).mean(),
    ],
  )
  m["div/rand/12"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3") *
      @pl.col("f3").max() %
      (@pl.col("f3").max() / @pl.col("f")) /
      (@pl.col("f3").max() * (@pl.col("f3") * @pl.len()))).sum(),
    ],
  )
  m["div/rand/13"] = ([@pl.col("k")], [@pl.lit_float(0.5) / @pl.col("f").sum()])
  m["div/rand/14"] = (
    [@pl.col("k")],
    [
      @pl.col("f").mean() %
      @pl.col("f").min() %
      (@pl.len() * @pl.lit_float(3.0)),
    ],
  )
  m["div/rand/15"] = (
    [@pl.col("k")],
    [
      (@pl.lit_float(2.5) +
      @pl.col("f") * @pl.col("f3") % (@pl.col("f") - @pl.col("f"))).sum(),
    ],
  )
  m["div/rand/16"] = (
    [@pl.col("k")],
    [@pl.col("f").max() % @pl.col("f3").first()],
  )
  m["div/rand/17"] = (
    [@pl.col("k")],
    [
      (@pl.col("f") *
      (@pl.col("f3").mean() % @pl.lit_int(2L)) %
      (@pl.len() / @pl.lit_float(3.0) % (@pl.col("f") - @pl.col("f3")))).first(),
    ],
  )
  m["div/rand/18"] = (
    [@pl.col("k")],
    [
      (@pl.col("f") *
      @pl.lit_float(2.5) %
      (@pl.lit_int(3L) / @pl.col("f").first())).mean(),
    ],
  )
  m["div/rand/19"] = (
    [@pl.col("k")],
    [
      ((@pl.col("f") / @pl.col("f3")).floor_div(
        @pl.col("f").last() / @pl.col("f").sum(),
      ) +
      @pl.col("f") /
      @pl.col("f") %
      (@pl.col("f3").min() - @pl.col("f3").first())).mean(),
    ],
  )
  m["div/rand/20"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3") / @pl.col("f3") + @pl.col("f3").first() * @pl.col("f")).sum(),
    ],
  )
  m["div/rand/21"] = (
    [@pl.col("k")],
    [(@pl.lit_float(3.0) % @pl.col("f")).first()],
  )
  m["div/rand/22"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").mean().floor_div(@pl.col("f").first()) %
      (@pl.col("f3").sum() % @pl.col("f3")) +
      @pl.col("f").max()).mean(),
    ],
  )
  m["div/rand/23"] = (
    [@pl.col("k")],
    [(@pl.len() - (@pl.len() % @pl.lit_int(7L)).floor_div(@pl.col("f"))).mean()],
  )
  m["div/rand/24"] = (
    [@pl.col("k")],
    [@pl.col("f3").mean() * (@pl.col("f3").min() / @pl.col("f3").sum())],
  )
  m["div/rand/25"] = (
    [@pl.col("k")],
    [@pl.col("f").max() / @pl.col("f").last().floor_div(@pl.col("f3").first())],
  )
  m["div/rand/26"] = (
    [@pl.col("k")],
    [@pl.col("f").sum() % @pl.col("f3").max()],
  )
  m["div/rand/27"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").first() *
      (@pl.col("f3") / (@pl.col("f") * @pl.col("f").first()))).sum(),
    ],
  )
  m["div/rand/28"] = (
    [@pl.col("k")],
    [@pl.col("f3").floor_div(@pl.col("f3")).sum()],
  )
  m["div/rand/29"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").last().floor_div(@pl.col("f")) *
      (@pl.lit_int(2L) / @pl.col("f").mean())).sum(),
    ],
  )
  m["div/rand/30"] = (
    [@pl.col("k")],
    [
      @pl.col("f3").sum() /
      @pl.lit_int(3L) *
      (@pl.col("f").sum() / @pl.col("f3").max()),
    ],
  )
  m["div/rand/31"] = ([@pl.col("k")], [@pl.lit_int(2L) % @pl.col("f3").sum()])
  m["div/rand/32"] = ([@pl.col("k")], [(@pl.lit_int(7L) / @pl.col("f")).mean()])
  m["div/rand/33"] = (
    [@pl.col("k")],
    [(@pl.col("f").first() * (@pl.col("f") % @pl.lit_float(3.0))).sum()],
  )
  m["div/rand/34"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").mean().floor_div(@pl.col("f")) /
      @pl.col("f3").floor_div(@pl.col("f3").last())).sum(),
    ],
  )
  m["div/rand/35"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum() % @pl.col("f")).sum()],
  )
  m["div/rand/36"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").max() / @pl.col("f").first())
      .floor_div(@pl.col("f3") - @pl.col("f3"))
      .sum(),
    ],
  )
  m["div/rand/37"] = (
    [@pl.col("k")],
    [
      ((@pl.col("f") % @pl.col("f3")).floor_div(@pl.col("f").first()) /
      @pl.col("f3").mean()).sum(),
    ],
  )
  m["div/rand/38"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").max() % @pl.col("f").mean()).floor_div(
        @pl.col("f").sum() + @pl.col("f").sum(),
      ),
    ],
  )
  m["div/rand/39"] = (
    [@pl.col("k")],
    [@pl.col("f3").min().floor_div(@pl.col("f3").min() * @pl.col("f").first())],
  )
  m["div/rand/40"] = ([@pl.col("k")], [@pl.col("f").last() / @pl.lit_int(3L)])
  m["div/rand/41"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").floor_div(@pl.col("f3")) -
      @pl.col("f3").min() % @pl.col("f3")).first(),
    ],
  )
  m["div/rand/42"] = (
    [@pl.col("k")],
    [
      (@pl.lit_float(3.0) % @pl.col("f3"))
      .floor_div(@pl.col("f") % @pl.col("f").mean())
      .last(),
    ],
  )
}

///|
fn golden_group_by_ext_cases_17(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["div/rand/43"] = ([@pl.col("k")], [@pl.col("f3").min() % @pl.len()])
  m["div/rand/44"] = (
    [@pl.col("k")],
    [(@pl.col("f3").last() % (@pl.col("f") * @pl.col("f").max())).sum()],
  )
  m["div/rand/45"] = (
    [@pl.col("k")],
    [
      @pl.col("f").min() *
      @pl.col("f3").first() %
      (@pl.col("f").last() / @pl.lit_float(3.0)),
    ],
  )
  m["div/rand/46"] = (
    [@pl.col("k")],
    [
      @pl.lit_int(3L)
      .floor_div(
        @pl.col("f").floor_div(@pl.col("f").max()) -
        @pl.col("f3").last().floor_div(@pl.col("f3").mean()),
      )
      .mean(),
    ],
  )
  m["div/rand/47"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").min() %
      @pl.col("f3").sum() %
      (@pl.col("f3") % @pl.col("f") * (@pl.col("f3") + @pl.col("f")))).mean(),
    ],
  )
  m["div/rand/48"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").first() *
      @pl.col("f3") *
      (@pl.lit_float(0.5) % @pl.col("f3"))).first(),
    ],
  )
  m["div/rand/49"] = (
    [@pl.col("k")],
    [
      (@pl.col("f") * @pl.lit_int(3L))
      .floor_div(@pl.col("f") / @pl.col("f").max())
      .sum(),
    ],
  )
  m["div/rand/50"] = ([@pl.col("k")], [@pl.col("f").last() / @pl.lit_int(7L)])
  m["div/rand/51"] = (
    [@pl.col("k")],
    [@pl.col("f3").max() / @pl.col("f").sum() + @pl.col("f3").last()],
  )
  m["div/rand/52"] = (
    [@pl.col("k")],
    [(@pl.lit_float(2.5) / (@pl.col("f3") * @pl.col("f3"))).first()],
  )
  m["div/rand/53"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").max() /
      @pl.col("f3").last() /
      (@pl.col("f3").sum() % @pl.col("f").min()) %
      (
        @pl.col("f3").first() %
        @pl.col("f") %
        (@pl.col("f3").last() % @pl.col("f"))
      )).first(),
    ],
  )
  m["div/rand/54"] = (
    [@pl.col("k")],
    [@pl.lit_int(3L).floor_div(@pl.col("f3")).last()],
  )
  m["div/rand/55"] = (
    [@pl.col("k")],
    [
      ((@pl.col("f") + @pl.col("f3").first()) %
      @pl.lit_int(3L).floor_div(@pl.col("f").mean())).first(),
    ],
  )
  m["div/rand/56"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").floor_div(@pl.col("f").first()) %
      (@pl.col("f") * @pl.col("f").first())).mean(),
    ],
  )
  m["div/rand/57"] = (
    [@pl.col("k")],
    [
      @pl.col("f3")
      .mean()
      .floor_div(
        @pl.col("f")
        .floor_div(@pl.lit_float(2.5))
        .floor_div(@pl.col("f3").mean()),
      )
      .first(),
    ],
  )
  m["div/rand/58"] = (
    [@pl.col("k")],
    [
      (@pl.lit_int(2L).floor_div(@pl.col("f")) +
      @pl.col("f") / @pl.col("f").min()).sum(),
    ],
  )
  m["div/rand/59"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").mean() % @pl.lit_float(3.0) +
      @pl.col("f").first() / @pl.col("f")).sum(),
    ],
  )
  m["div/rand/60"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").last() * @pl.col("f").sum() / (@pl.col("f") % @pl.col("f"))).first(),
    ],
  )
  m["div/rand/61"] = ([@pl.col("k")], [@pl.col("f").sum() / @pl.len()])
  m["div/rand/62"] = (
    [@pl.col("k")],
    [
      @pl.col("f").mean() %
      (@pl.col("f").min() * @pl.col("f").min()) %
      @pl.col("f3").min(),
    ],
  )
  m["div/rand/63"] = (
    [@pl.col("k")],
    [(@pl.col("f") % @pl.col("f") - @pl.col("f") % @pl.col("f3")).first()],
  )
  m["div/rand/64"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").min() /
      @pl.col("f") /
      (@pl.lit_float(2.5) / @pl.col("f")) %
      (@pl.col("f3") % @pl.col("f3").last()).floor_div(
        @pl.col("f3").sum().floor_div(@pl.col("f")),
      )).sum(),
    ],
  )
  m["div/rand/65"] = (
    [@pl.col("k")],
    [
      @pl.col("f").first() /
      @pl.col("f").sum() %
      (@pl.col("f").mean() / @pl.col("f3").first()),
    ],
  )
  m["div/rand/66"] = (
    [@pl.col("k")],
    [@pl.col("f").first() / @pl.lit_float(3.0)],
  )
  m["div/rand/67"] = (
    [@pl.col("k")],
    [
      (@pl.lit_float(3.0) %
      (@pl.col("f3").first() - @pl.col("f")).floor_div(
        @pl.col("f").last() + @pl.col("f").last(),
      )).first(),
    ],
  )
  m["div/rand/68"] = (
    [@pl.col("k")],
    [(@pl.col("f3").last() / @pl.col("f3")).last()],
  )
  m["div/rand/69"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").max().floor_div(@pl.lit_int(7L)) %
      (@pl.col("f3").mean() / @pl.col("f"))).sum(),
    ],
  )
  m["div/rand/70"] = (
    [@pl.col("k")],
    [(@pl.col("f") % @pl.col("f3") * (@pl.lit_int(7L) - @pl.col("f3"))).sum()],
  )
  m["div/rand/71"] = (
    [@pl.col("k")],
    [
      (@pl.col("f") % @pl.col("f3"))
      .floor_div(@pl.col("f") / @pl.col("f"))
      .sum(),
    ],
  )
  m["div/rand/72"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").last() / @pl.col("f"))
      .floor_div(@pl.col("f") * @pl.lit_int(3L))
      .mean(),
    ],
  )
  m["div/rand/73"] = ([@pl.col("k")], [(@pl.col("f3") % @pl.len()).first()])
  m["div/rand/74"] = (
    [@pl.col("k")],
    [
      @pl.col("f3")
      .floor_div(@pl.col("f"))
      .floor_div(@pl.col("f") / @pl.col("f3").max())
      .mean(),
    ],
  )
  m["div/rand/75"] = (
    [@pl.col("k")],
    [
      @pl.col("f")
      .floor_div(@pl.lit_int(7L))
      .floor_div(@pl.col("f").floor_div(@pl.col("f3").first()))
      .sum(),
    ],
  )
  m["div/rand/76"] = (
    [@pl.col("k")],
    [
      ((@pl.col("f3").mean() + @pl.col("f3")) %
      @pl.col("f") *
      (@pl.col("f3").last() % @pl.col("f") - @pl.col("f3") / @pl.col("f"))).last(),
    ],
  )
  m["div/rand/77"] = (
    [@pl.col("k")],
    [
      @pl.col("f3").min().floor_div(@pl.lit_float(2.5)) /
      (@pl.col("f").min() / @pl.col("f3").sum()),
    ],
  )
  m["div/rand/78"] = (
    [@pl.col("k")],
    [@pl.col("f3").sum() * (@pl.col("f3").mean() % @pl.col("f3").min())],
  )
  m["div/rand/79"] = (
    [@pl.col("k")],
    [(@pl.col("f3").first() / @pl.col("f3")).last()],
  )
  m["div/rand/80"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").floor_div(@pl.col("f")) - @pl.col("f3") / @pl.col("f").max()).first(),
    ],
  )
  m["div/rand/81"] = (
    [@pl.col("k")],
    [
      @pl.col("f3").min() /
      @pl.col("f3").max() %
      @pl.lit_int(2L).floor_div(@pl.lit_float(2.5)),
    ],
  )
  m["div/rand/82"] = (
    [@pl.col("k")],
    [((@pl.col("f3").first() - @pl.col("f3").first()) % @pl.col("f3")).last()],
  )
}

///|
fn golden_group_by_ext_cases_18(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["div/rand/83"] = (
    [@pl.col("k")],
    [
      @pl.col("f").first().floor_div(@pl.col("f3").last()) /
      (@pl.lit_float(2.5) / @pl.col("f3").first()),
    ],
  )
  m["div/rand/84"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").mean() - @pl.col("f3"))
      .floor_div(@pl.lit_float(0.5).floor_div(@pl.col("f")))
      .sum(),
    ],
  )
  m["div/rand/85"] = (
    [@pl.col("k")],
    [
      (@pl.col("f") /
      @pl.col("f3").min() %
      (@pl.col("f3").first() * @pl.col("f").sum())).mean(),
    ],
  )
  m["div/rand/86"] = (
    [@pl.col("k")],
    [@pl.col("f3").floor_div(@pl.col("f3")).mean()],
  )
  m["div/rand/87"] = (
    [@pl.col("k")],
    [(@pl.col("f").sum() + @pl.col("f").max() / @pl.col("f3")).sum()],
  )
  m["div/rand/88"] = (
    [@pl.col("k")],
    [(@pl.col("f3") / @pl.col("f").first() % @pl.col("f")).first()],
  )
  m["div/rand/89"] = (
    [@pl.col("k")],
    [
      (@pl.col("f3").min() %
      @pl.col("f").first().floor_div(@pl.lit_float(0.5)) %
      (
        @pl.col("f").max() %
        @pl.col("f") %
        @pl.col("f").floor_div(@pl.col("f3").mean())
      )).last(),
    ],
  )
  m["div/rand-mixed/0"] = (
    [@pl.col("k")],
    [@pl.lit_int(2L) % @pl.col("f").sum()],
  )
  m["div/rand-mixed/1"] = (
    [@pl.col("k")],
    [
      ((@pl.lit_float(3.0) + @pl.col("n")) *
      (@pl.col("f").max() / @pl.col("f")) /
      (@pl.col("f3").last() * @pl.col("f").first().floor_div(@pl.col("f")))).first(),
    ],
  )
  m["div/rand-mixed/2"] = (
    [@pl.col("k")],
    [(@pl.col("n").last() / @pl.lit_int(3L).floor_div(@pl.col("f"))).first()],
  )
  m["div/rand-mixed/3"] = (
    [@pl.col("k")],
    [
      (@pl.col("f") / @pl.col("n").last())
      .floor_div(@pl.col("f3").last())
      .last(),
    ],
  )
  m["div/rand-mixed/4"] = (
    [@pl.col("k")],
    [(@pl.col("n").max() % @pl.col("n")).first()],
  )
  m["div/rand-mixed/5"] = (
    [@pl.col("k")],
    [@pl.col("n").min() / @pl.col("f").max()],
  )
  m["div/rand-mixed/6"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").mean().floor_div(@pl.col("f").mean()) *
      (@pl.col("n").last() % @pl.col("f3").mean()) -
      @pl.col("f") % @pl.lit_float(0.5) / (@pl.col("n").last() % @pl.col("n"))).mean(),
    ],
  )
  m["div/rand-mixed/7"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").mean() % @pl.lit_float(3.0) * (@pl.col("n") * @pl.col("n"))).first(),
    ],
  )
  m["div/rand-mixed/8"] = (
    [@pl.col("k")],
    [(@pl.col("n") * @pl.col("f")).floor_div(@pl.col("n") - @pl.len()).sum()],
  )
  m["div/rand-mixed/9"] = (
    [@pl.col("k")],
    [(@pl.lit_int(7L) / (@pl.col("n").first() / @pl.col("n"))).last()],
  )
  m["div/rand-mixed/10"] = (
    [@pl.col("k")],
    [(@pl.col("f") / (@pl.col("f3").last() / @pl.col("f").first())).sum()],
  )
  m["div/rand-mixed/11"] = (
    [@pl.col("k")],
    [
      (@pl.col("n").floor_div(@pl.len()) / (@pl.col("f").mean() / @pl.col("f"))).last(),
    ],
  )
  m["div/rand-mixed/12"] = (
    [@pl.col("k")],
    [
      (@pl.col("n").mean().floor_div(@pl.col("n").min()) +
      @pl.col("n").mean().floor_div(@pl.col("f")))
      .floor_div(
        @pl.lit_float(0.5) * @pl.col("n") % (@pl.len() + @pl.col("n").min()),
      )
      .mean(),
    ],
  )
  m["div/rand-mixed/13"] = (
    [@pl.col("k")],
    [(@pl.col("f") / @pl.col("f") * (@pl.len() % @pl.col("f"))).sum()],
  )
  m["div/rand-mixed/14"] = (
    [@pl.col("k")],
    [
      (@pl.col("f")
      .floor_div(@pl.col("n"))
      .floor_div(@pl.col("f").floor_div(@pl.lit_float(0.5))) *
      @pl.col("f")
      .floor_div(@pl.col("n"))
      .floor_div(@pl.col("f") % @pl.col("f3").min())).last(),
    ],
  )
  m["div/rand-mixed/15"] = (
    [@pl.col("k")],
    [(@pl.col("n").min() / (@pl.col("n").min() - @pl.col("n"))).first()],
  )
  m["div/rand-mixed/16"] = (
    [@pl.col("k")],
    [
      (@pl.lit_int(2L) / @pl.col("f") % (@pl.col("f").mean() % @pl.col("n"))).first(),
    ],
  )
  m["div/rand-mixed/17"] = (
    [@pl.col("k")],
    [
      (@pl.col("n").first() * @pl.col("n") % (@pl.col("n") / @pl.col("f"))).sum(),
    ],
  )
  m["div/rand-mixed/18"] = (
    [@pl.col("k")],
    [
      (@pl.col("n").floor_div(@pl.col("n")) /
      @pl.lit_int(2L).floor_div(@pl.col("f").sum()) %
      (@pl.lit_float(2.5) / @pl.col("n")).floor_div(
        @pl.col("n") % @pl.col("f").max(),
      )).mean(),
    ],
  )
  m["div/rand-mixed/19"] = (
    [@pl.col("k")],
    [
      @pl.col("f")
      .floor_div(@pl.col("f").min())
      .floor_div(@pl.col("n") * @pl.col("f3").last())
      .first(),
    ],
  )
  m["div/rand-mixed/20"] = (
    [@pl.col("k")],
    [(@pl.col("f") / @pl.col("n") / @pl.col("f3").sum()).first()],
  )
  m["div/rand-mixed/21"] = (
    [@pl.col("k")],
    [
      @pl.lit_int(2L) /
      @pl.col("f").last() %
      (@pl.col("f3").sum() / @pl.col("n").min()),
    ],
  )
  m["div/rand-mixed/22"] = (
    [@pl.col("k")],
    [@pl.col("n").sum() / @pl.col("f").min()],
  )
  m["div/rand-mixed/23"] = (
    [@pl.col("k")],
    [@pl.col("n").sum() / @pl.col("f").sum()],
  )
  m["div/rand-mixed/24"] = (
    [@pl.col("k")],
    [(@pl.col("f3").sum() * @pl.col("f") / @pl.col("n")).last()],
  )
  m["div/rand-mixed/25"] = (
    [@pl.col("k")],
    [
      (@pl.col("n").first() * @pl.col("f"))
      .floor_div(@pl.lit_int(2L) / @pl.col("n"))
      .first(),
    ],
  )
  m["div/rand-mixed/26"] = (
    [@pl.col("k")],
    [
      (@pl.col("n").mean() - @pl.lit_int(3L)) *
      (@pl.col("f").mean() / @pl.col("n").min()),
    ],
  )
  m["div/rand-mixed/27"] = (
    [@pl.col("k")],
    [(@pl.col("f3").min() % @pl.col("n")).sum()],
  )
  m["div/rand-mixed/28"] = (
    [@pl.col("k")],
    [
      (@pl.lit_float(3.0) +
      (@pl.col("n") - @pl.len().floor_div(@pl.col("f").last()))).mean(),
    ],
  )
  m["div/rand-mixed/29"] = (
    [@pl.col("k")],
    [
      (@pl.col("f").first() - @pl.col("f3").mean()) %
      @pl.col("f3").first() %
      @pl.col("f").mean(),
    ],
  )
}

///|
/// Every case id with its key expressions and aggregation expressions.
fn golden_group_by_ext_cases() -> Map[
  String,
  (Array[@pl.Expr], Array[@pl.Expr]),
] {
  let m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])] = Map([])
  golden_group_by_ext_cases_0(m)
  golden_group_by_ext_cases_1(m)
  golden_group_by_ext_cases_2(m)
  golden_group_by_ext_cases_3(m)
  golden_group_by_ext_cases_4(m)
  golden_group_by_ext_cases_5(m)
  golden_group_by_ext_cases_6(m)
  golden_group_by_ext_cases_7(m)
  golden_group_by_ext_cases_8(m)
  golden_group_by_ext_cases_9(m)
  golden_group_by_ext_cases_10(m)
  golden_group_by_ext_cases_11(m)
  golden_group_by_ext_cases_12(m)
  golden_group_by_ext_cases_13(m)
  golden_group_by_ext_cases_14(m)
  golden_group_by_ext_cases_15(m)
  golden_group_by_ext_cases_16(m)
  golden_group_by_ext_cases_17(m)
  golden_group_by_ext_cases_18(m)
  m
}
