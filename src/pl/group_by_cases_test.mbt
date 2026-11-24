// 由 docs/golden/scripts/group_by.py 生成，勿手改

///|
fn golden_group_by_cases_0(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["key/i32"] = (
    [@pl.col("i32")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/i32/noagg"] = ([@pl.col("i32")], [], None)
  m["key/i32/e"] = (
    [@pl.col("i32")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/i64"] = (
    [@pl.col("i64")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/i64/noagg"] = ([@pl.col("i64")], [], None)
  m["key/i64/e"] = (
    [@pl.col("i64")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/f32"] = (
    [@pl.col("f32")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/f32/noagg"] = ([@pl.col("f32")], [], None)
  m["key/f32/e"] = (
    [@pl.col("f32")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/f64"] = (
    [@pl.col("f64")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/f64/noagg"] = ([@pl.col("f64")], [], None)
  m["key/f64/e"] = (
    [@pl.col("f64")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/s"] = (
    [@pl.col("s")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/s/noagg"] = ([@pl.col("s")], [], None)
  m["key/s/e"] = (
    [@pl.col("s")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/b"] = (
    [@pl.col("b")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/b/noagg"] = ([@pl.col("b")], [], None)
  m["key/b/e"] = (
    [@pl.col("b")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/d"] = (
    [@pl.col("d")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/d/noagg"] = ([@pl.col("d")], [], None)
  m["key/d/e"] = (
    [@pl.col("d")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/dt"] = (
    [@pl.col("dt")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/dt/noagg"] = ([@pl.col("dt")], [], None)
  m["key/dt/e"] = (
    [@pl.col("dt")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/n"] = (
    [@pl.col("n")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/n/noagg"] = ([@pl.col("n")], [], None)
  m["key/n/e"] = (
    [@pl.col("n")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/multi/i32+s"] = (
    [@pl.col("i32"), @pl.col("s")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/multi/b+d"] = (
    [@pl.col("b"), @pl.col("d")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/multi/s+i32"] = (
    [@pl.col("s"), @pl.col("i32")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/multi/i32+f64+s"] = (
    [@pl.col("i32"), @pl.col("f64"), @pl.col("s")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/multi/n+i32"] = (
    [@pl.col("n"), @pl.col("i32")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/multi/k+b+dt"] = (
    [@pl.col("k"), @pl.col("b"), @pl.col("dt")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/multi/f32+f64"] = (
    [@pl.col("f32"), @pl.col("f64")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/multi/i64+dt"] = (
    [@pl.col("i64"), @pl.col("dt")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/multi/e"] = (
    [@pl.col("i32"), @pl.col("s")],
    [
      @pl.len(),
      @pl.col("y").sum().alias("ys"),
      @pl.col("s").first().alias("sf"),
    ],
    None,
  )
  m["key/expr/mod"] = ([@pl.col("i32") % @pl.lit_int(2L)], [@pl.len()], None)
  m["key/expr/k-plus"] = ([@pl.col("k") + @pl.lit_int(1L)], [@pl.len()], None)
  m["key/expr/alias"] = (
    [(@pl.col("k") % @pl.lit_int(2L)).alias("kk")],
    [@pl.len(), @pl.col("y").sum()],
    None,
  )
  m["key/expr/str-len"] = ([@pl.col("s").str().len_chars()], [@pl.len()], None)
}

///|
fn golden_group_by_cases_1(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["key/expr/is-nan"] = ([@pl.col("f64").is_nan()], [@pl.len()], None)
  m["key/expr/is-null"] = (
    [@pl.col("i32").is_null()],
    [@pl.len(), @pl.col("y").sum()],
    None,
  )
  m["key/expr/cast"] = (
    [@pl.col("f64").cast(@pl.DataType::Int64, strict=false)],
    [@pl.len()],
    None,
  )
  m["key/expr/two"] = (
    [@pl.col("k") % @pl.lit_int(2L), @pl.col("b")],
    [@pl.len()],
    None,
  )
  m["key/expr/same-name"] = (
    [@pl.col("k"), @pl.col("k") + @pl.lit_int(1L)],
    [@pl.len()],
    None,
  )
  m["key/expr/same-name2"] = (
    [@pl.col("k"), (@pl.col("k") + @pl.lit_int(1L)).alias("k2")],
    [@pl.len()],
    None,
  )
  m["key/lit"] = ([@pl.lit_int(1L)], [@pl.col("y").sum()], None)
  m["key/lit/e"] = ([@pl.lit_int(1L)], [@pl.col("y").sum()], None)
  m["key/lit-str"] = ([@pl.lit_str("q")], [@pl.len()], None)
  m["key/lit+col"] = ([@pl.lit_int(1L), @pl.col("b")], [@pl.len()], None)
  m["key/lit+col/e"] = ([@pl.lit_int(1L), @pl.col("b")], [@pl.len()], None)
  m["key/lit+col/e2"] = ([@pl.col("b"), @pl.lit_int(1L)], [@pl.len()], None)
  m["key/agg"] = ([@pl.col("k").sum()], [@pl.col("y").sum()], None)
  m["key/agg/e"] = ([@pl.col("k").sum()], [@pl.col("y").sum(), @pl.len()], None)
  m["key/cols"] = ([@pl.cols(["i32", "b"])], [@pl.len()], None)
  m["key/cols-one"] = ([@pl.cols(["b"])], [@pl.len()], None)
  m["key/all"] = ([@pl.all()], [@pl.len()], None)
  m["key/none"] = ([], [@pl.len(), @pl.col("y").sum()], None)
  m["key/none/noagg"] = ([], [], None)
  m["key/none/e"] = (
    [],
    [@pl.len(), @pl.col("y").sum(), @pl.col("y").mean().alias("m")],
    None,
  )
  m["key/none/z0"] = ([], [@pl.len()], None)
  m["key/none/z0-lit"] = ([], [@pl.lit_int(1L)], None)
  m["key/none/z0-noagg"] = ([], [], None)
  m["key/none/sums"] = (
    [],
    [
      @pl.col("i64").sum(),
      @pl.col("f64").mean().alias("m"),
      @pl.len().alias("n"),
    ],
    None,
  )
  m["key/none/sums/e"] = (
    [],
    [
      @pl.col("i64").sum(),
      @pl.col("f64").mean().alias("m"),
      @pl.len().alias("n"),
    ],
    None,
  )
  m["key/none/first"] = (
    [],
    [
      @pl.col("i32").first(),
      @pl.col("s").last().alias("sl"),
      @pl.col("b").n_unique().alias("nu"),
      @pl.col("f64").min().alias("mn"),
      @pl.col("y").median().alias("md"),
      @pl.col("y").product().alias("pr"),
      @pl.col("d").count().alias("cn"),
    ],
    None,
  )
  m["key/none/std"] = (
    [
      @pl.col("y").std(ddof=1),
      @pl.col("y").var_(ddof=0).alias("v0"),
      @pl.col("x")
      .quantile(0.3, interpolation=@pl.QuantileMethod::Nearest)
      .alias("q"),
    ],
    [],
    None,
  )
  m["key/none/group-level"] = (
    [
      (@pl.col("x") - @pl.col("x").mean()).sum().alias("dev"),
      @pl.col("y").cum_sum().last().alias("cl"),
    ],
    [],
    None,
  )
  m["key/none/group-level/g"] = (
    [
      (@pl.col("x") - @pl.col("x").mean()).sum().alias("dev"),
      @pl.col("y").cum_sum().last().alias("cl"),
    ],
    [],
    None,
  )
  m["key/none/list/e"] = ([], [@pl.col("y")], None)
  m["key/none/list"] = ([], [@pl.col("y")], None)
  m["key/none/lit/e"] = ([], [@pl.lit_int(1L)], None)
  m["key/none/lit"] = (
    [],
    [@pl.lit_int(1L), @pl.lit_float(2.5).alias("f")],
    None,
  )
  m["key/missing"] = ([@pl.col("zz")], [@pl.len()], None)
  m["key/missing2"] = ([@pl.col("k"), @pl.col("zz")], [@pl.len()], None)
  m["key/missing/z0"] = ([@pl.col("zz")], [@pl.len()], None)
  m["key/dup"] = ([@pl.col("k"), @pl.col("k")], [@pl.len()], None)
  m["key/dup-alias"] = (
    [@pl.col("k"), @pl.col("i32").alias("k")],
    [@pl.len()],
    None,
  )
  m["key/type-error"] = ([@pl.col("k") + @pl.col("s")], [@pl.len()], None)
  m["key/type-error/agg-type-error"] = (
    [@pl.col("k") + @pl.col("s")],
    [@pl.col("s").sum()],
    None,
  )
}

///|
fn golden_group_by_cases_2(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["key/agg-type-error"] = ([@pl.col("k")], [@pl.col("s").sum()], None)
  m["key/cols-missing"] = ([@pl.cols(["i32", "zz"])], [@pl.len()], None)
  m["agg/sum/i32"] = ([@pl.col("k")], [@pl.col("i32").sum()], None)
  m["agg/sum/i64"] = ([@pl.col("k")], [@pl.col("i64").sum()], None)
  m["agg/sum/f32"] = ([@pl.col("k")], [@pl.col("f32").sum()], None)
  m["agg/sum/f64"] = ([@pl.col("k")], [@pl.col("f64").sum()], None)
  m["agg/sum/s"] = ([@pl.col("k")], [@pl.col("s").sum()], None)
  m["agg/sum/b"] = ([@pl.col("k")], [@pl.col("b").sum()], None)
  m["agg/sum/d"] = ([@pl.col("k")], [@pl.col("d").sum()], None)
  m["agg/sum/dt"] = ([@pl.col("k")], [@pl.col("dt").sum()], None)
  m["agg/sum/n"] = ([@pl.col("k")], [@pl.col("n").sum()], None)
  m["agg/mean/i32"] = ([@pl.col("k")], [@pl.col("i32").mean()], None)
  m["agg/mean/i64"] = ([@pl.col("k")], [@pl.col("i64").mean()], None)
  m["agg/mean/f32"] = ([@pl.col("k")], [@pl.col("f32").mean()], None)
  m["agg/mean/f64"] = ([@pl.col("k")], [@pl.col("f64").mean()], None)
  m["agg/mean/s"] = ([@pl.col("k")], [@pl.col("s").mean()], None)
  m["agg/mean/b"] = ([@pl.col("k")], [@pl.col("b").mean()], None)
  m["agg/mean/d"] = ([@pl.col("k")], [@pl.col("d").mean()], None)
  m["agg/mean/dt"] = ([@pl.col("k")], [@pl.col("dt").mean()], None)
  m["agg/mean/n"] = ([@pl.col("k")], [@pl.col("n").mean()], None)
  m["agg/min/i32"] = ([@pl.col("k")], [@pl.col("i32").min()], None)
  m["agg/min/i64"] = ([@pl.col("k")], [@pl.col("i64").min()], None)
  m["agg/min/f32"] = ([@pl.col("k")], [@pl.col("f32").min()], None)
  m["agg/min/f64"] = ([@pl.col("k")], [@pl.col("f64").min()], None)
  m["agg/min/s"] = ([@pl.col("k")], [@pl.col("s").min()], None)
  m["agg/min/b"] = ([@pl.col("k")], [@pl.col("b").min()], None)
  m["agg/min/d"] = ([@pl.col("k")], [@pl.col("d").min()], None)
  m["agg/min/dt"] = ([@pl.col("k")], [@pl.col("dt").min()], None)
  m["agg/min/n"] = ([@pl.col("k")], [@pl.col("n").min()], None)
  m["agg/max/i32"] = ([@pl.col("k")], [@pl.col("i32").max()], None)
  m["agg/max/i64"] = ([@pl.col("k")], [@pl.col("i64").max()], None)
  m["agg/max/f32"] = ([@pl.col("k")], [@pl.col("f32").max()], None)
  m["agg/max/f64"] = ([@pl.col("k")], [@pl.col("f64").max()], None)
  m["agg/max/s"] = ([@pl.col("k")], [@pl.col("s").max()], None)
  m["agg/max/b"] = ([@pl.col("k")], [@pl.col("b").max()], None)
  m["agg/max/d"] = ([@pl.col("k")], [@pl.col("d").max()], None)
  m["agg/max/dt"] = ([@pl.col("k")], [@pl.col("dt").max()], None)
  m["agg/max/n"] = ([@pl.col("k")], [@pl.col("n").max()], None)
  m["agg/count/i32"] = ([@pl.col("k")], [@pl.col("i32").count()], None)
  m["agg/count/i64"] = ([@pl.col("k")], [@pl.col("i64").count()], None)
}

///|
fn golden_group_by_cases_3(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/count/f32"] = ([@pl.col("k")], [@pl.col("f32").count()], None)
  m["agg/count/f64"] = ([@pl.col("k")], [@pl.col("f64").count()], None)
  m["agg/count/s"] = ([@pl.col("k")], [@pl.col("s").count()], None)
  m["agg/count/b"] = ([@pl.col("k")], [@pl.col("b").count()], None)
  m["agg/count/d"] = ([@pl.col("k")], [@pl.col("d").count()], None)
  m["agg/count/dt"] = ([@pl.col("k")], [@pl.col("dt").count()], None)
  m["agg/count/n"] = ([@pl.col("k")], [@pl.col("n").count()], None)
  m["agg/len/i32"] = ([@pl.col("k")], [@pl.col("i32").len()], None)
  m["agg/len/i64"] = ([@pl.col("k")], [@pl.col("i64").len()], None)
  m["agg/len/f32"] = ([@pl.col("k")], [@pl.col("f32").len()], None)
  m["agg/len/f64"] = ([@pl.col("k")], [@pl.col("f64").len()], None)
  m["agg/len/s"] = ([@pl.col("k")], [@pl.col("s").len()], None)
  m["agg/len/b"] = ([@pl.col("k")], [@pl.col("b").len()], None)
  m["agg/len/d"] = ([@pl.col("k")], [@pl.col("d").len()], None)
  m["agg/len/dt"] = ([@pl.col("k")], [@pl.col("dt").len()], None)
  m["agg/len/n"] = ([@pl.col("k")], [@pl.col("n").len()], None)
  m["agg/n_unique/i32"] = ([@pl.col("k")], [@pl.col("i32").n_unique()], None)
  m["agg/n_unique/i64"] = ([@pl.col("k")], [@pl.col("i64").n_unique()], None)
  m["agg/n_unique/f32"] = ([@pl.col("k")], [@pl.col("f32").n_unique()], None)
  m["agg/n_unique/f64"] = ([@pl.col("k")], [@pl.col("f64").n_unique()], None)
  m["agg/n_unique/s"] = ([@pl.col("k")], [@pl.col("s").n_unique()], None)
  m["agg/n_unique/b"] = ([@pl.col("k")], [@pl.col("b").n_unique()], None)
  m["agg/n_unique/d"] = ([@pl.col("k")], [@pl.col("d").n_unique()], None)
  m["agg/n_unique/dt"] = ([@pl.col("k")], [@pl.col("dt").n_unique()], None)
  m["agg/n_unique/n"] = ([@pl.col("k")], [@pl.col("n").n_unique()], None)
  m["agg/first/i32"] = ([@pl.col("k")], [@pl.col("i32").first()], None)
  m["agg/first/i64"] = ([@pl.col("k")], [@pl.col("i64").first()], None)
  m["agg/first/f32"] = ([@pl.col("k")], [@pl.col("f32").first()], None)
  m["agg/first/f64"] = ([@pl.col("k")], [@pl.col("f64").first()], None)
  m["agg/first/s"] = ([@pl.col("k")], [@pl.col("s").first()], None)
  m["agg/first/b"] = ([@pl.col("k")], [@pl.col("b").first()], None)
  m["agg/first/d"] = ([@pl.col("k")], [@pl.col("d").first()], None)
  m["agg/first/dt"] = ([@pl.col("k")], [@pl.col("dt").first()], None)
  m["agg/first/n"] = ([@pl.col("k")], [@pl.col("n").first()], None)
  m["agg/last/i32"] = ([@pl.col("k")], [@pl.col("i32").last()], None)
  m["agg/last/i64"] = ([@pl.col("k")], [@pl.col("i64").last()], None)
  m["agg/last/f32"] = ([@pl.col("k")], [@pl.col("f32").last()], None)
  m["agg/last/f64"] = ([@pl.col("k")], [@pl.col("f64").last()], None)
  m["agg/last/s"] = ([@pl.col("k")], [@pl.col("s").last()], None)
  m["agg/last/b"] = ([@pl.col("k")], [@pl.col("b").last()], None)
}

///|
fn golden_group_by_cases_4(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/last/d"] = ([@pl.col("k")], [@pl.col("d").last()], None)
  m["agg/last/dt"] = ([@pl.col("k")], [@pl.col("dt").last()], None)
  m["agg/last/n"] = ([@pl.col("k")], [@pl.col("n").last()], None)
  m["agg/median/i32"] = ([@pl.col("k")], [@pl.col("i32").median()], None)
  m["agg/median/i64"] = ([@pl.col("k")], [@pl.col("i64").median()], None)
  m["agg/median/f32"] = ([@pl.col("k")], [@pl.col("f32").median()], None)
  m["agg/median/f64"] = ([@pl.col("k")], [@pl.col("f64").median()], None)
  m["agg/median/s"] = ([@pl.col("k")], [@pl.col("s").median()], None)
  m["agg/median/b"] = ([@pl.col("k")], [@pl.col("b").median()], None)
  m["agg/median/d"] = ([@pl.col("k")], [@pl.col("d").median()], None)
  m["agg/median/dt"] = ([@pl.col("k")], [@pl.col("dt").median()], None)
  m["agg/median/n"] = ([@pl.col("k")], [@pl.col("n").median()], None)
  m["agg/product/i32"] = ([@pl.col("k")], [@pl.col("i32").product()], None)
  m["agg/product/i64"] = ([@pl.col("k")], [@pl.col("i64").product()], None)
  m["agg/product/f32"] = ([@pl.col("k")], [@pl.col("f32").product()], None)
  m["agg/product/f64"] = ([@pl.col("k")], [@pl.col("f64").product()], None)
  m["agg/product/s"] = ([@pl.col("k")], [@pl.col("s").product()], None)
  m["agg/product/b"] = ([@pl.col("k")], [@pl.col("b").product()], None)
  m["agg/product/d"] = ([@pl.col("k")], [@pl.col("d").product()], None)
  m["agg/product/dt"] = ([@pl.col("k")], [@pl.col("dt").product()], None)
  m["agg/product/n"] = ([@pl.col("k")], [@pl.col("n").product()], None)
  m["agg/std0/i32"] = ([@pl.col("k")], [@pl.col("i32").std(ddof=0)], None)
  m["agg/std0/i64"] = ([@pl.col("k")], [@pl.col("i64").std(ddof=0)], None)
  m["agg/std0/f32"] = ([@pl.col("k")], [@pl.col("f32").std(ddof=0)], None)
  m["agg/std0/f64"] = ([@pl.col("k")], [@pl.col("f64").std(ddof=0)], None)
  m["agg/std0/s"] = ([@pl.col("k")], [@pl.col("s").std(ddof=0)], None)
  m["agg/std0/b"] = ([@pl.col("k")], [@pl.col("b").std(ddof=0)], None)
  m["agg/std0/d"] = ([@pl.col("k")], [@pl.col("d").std(ddof=0)], None)
  m["agg/std0/dt"] = ([@pl.col("k")], [@pl.col("dt").std(ddof=0)], None)
  m["agg/std0/n"] = ([@pl.col("k")], [@pl.col("n").std(ddof=0)], None)
  m["agg/std1/i32"] = ([@pl.col("k")], [@pl.col("i32").std(ddof=1)], None)
  m["agg/std1/i64"] = ([@pl.col("k")], [@pl.col("i64").std(ddof=1)], None)
  m["agg/std1/f32"] = ([@pl.col("k")], [@pl.col("f32").std(ddof=1)], None)
  m["agg/std1/f64"] = ([@pl.col("k")], [@pl.col("f64").std(ddof=1)], None)
  m["agg/std1/s"] = ([@pl.col("k")], [@pl.col("s").std(ddof=1)], None)
  m["agg/std1/b"] = ([@pl.col("k")], [@pl.col("b").std(ddof=1)], None)
  m["agg/std1/d"] = ([@pl.col("k")], [@pl.col("d").std(ddof=1)], None)
  m["agg/std1/dt"] = ([@pl.col("k")], [@pl.col("dt").std(ddof=1)], None)
  m["agg/std1/n"] = ([@pl.col("k")], [@pl.col("n").std(ddof=1)], None)
  m["agg/std2/i32"] = ([@pl.col("k")], [@pl.col("i32").std(ddof=2)], None)
}

///|
fn golden_group_by_cases_5(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/std2/i64"] = ([@pl.col("k")], [@pl.col("i64").std(ddof=2)], None)
  m["agg/std2/f32"] = ([@pl.col("k")], [@pl.col("f32").std(ddof=2)], None)
  m["agg/std2/f64"] = ([@pl.col("k")], [@pl.col("f64").std(ddof=2)], None)
  m["agg/std2/s"] = ([@pl.col("k")], [@pl.col("s").std(ddof=2)], None)
  m["agg/std2/b"] = ([@pl.col("k")], [@pl.col("b").std(ddof=2)], None)
  m["agg/std2/d"] = ([@pl.col("k")], [@pl.col("d").std(ddof=2)], None)
  m["agg/std2/dt"] = ([@pl.col("k")], [@pl.col("dt").std(ddof=2)], None)
  m["agg/std2/n"] = ([@pl.col("k")], [@pl.col("n").std(ddof=2)], None)
  m["agg/var0/i32"] = ([@pl.col("k")], [@pl.col("i32").var_(ddof=0)], None)
  m["agg/var0/i64"] = ([@pl.col("k")], [@pl.col("i64").var_(ddof=0)], None)
  m["agg/var0/f32"] = ([@pl.col("k")], [@pl.col("f32").var_(ddof=0)], None)
  m["agg/var0/f64"] = ([@pl.col("k")], [@pl.col("f64").var_(ddof=0)], None)
  m["agg/var0/s"] = ([@pl.col("k")], [@pl.col("s").var_(ddof=0)], None)
  m["agg/var0/b"] = ([@pl.col("k")], [@pl.col("b").var_(ddof=0)], None)
  m["agg/var0/d"] = ([@pl.col("k")], [@pl.col("d").var_(ddof=0)], None)
  m["agg/var0/dt"] = ([@pl.col("k")], [@pl.col("dt").var_(ddof=0)], None)
  m["agg/var0/n"] = ([@pl.col("k")], [@pl.col("n").var_(ddof=0)], None)
  m["agg/var1/i32"] = ([@pl.col("k")], [@pl.col("i32").var_(ddof=1)], None)
  m["agg/var1/i64"] = ([@pl.col("k")], [@pl.col("i64").var_(ddof=1)], None)
  m["agg/var1/f32"] = ([@pl.col("k")], [@pl.col("f32").var_(ddof=1)], None)
  m["agg/var1/f64"] = ([@pl.col("k")], [@pl.col("f64").var_(ddof=1)], None)
  m["agg/var1/s"] = ([@pl.col("k")], [@pl.col("s").var_(ddof=1)], None)
  m["agg/var1/b"] = ([@pl.col("k")], [@pl.col("b").var_(ddof=1)], None)
  m["agg/var1/d"] = ([@pl.col("k")], [@pl.col("d").var_(ddof=1)], None)
  m["agg/var1/dt"] = ([@pl.col("k")], [@pl.col("dt").var_(ddof=1)], None)
  m["agg/var1/n"] = ([@pl.col("k")], [@pl.col("n").var_(ddof=1)], None)
  m["agg/var2/i32"] = ([@pl.col("k")], [@pl.col("i32").var_(ddof=2)], None)
  m["agg/var2/i64"] = ([@pl.col("k")], [@pl.col("i64").var_(ddof=2)], None)
  m["agg/var2/f32"] = ([@pl.col("k")], [@pl.col("f32").var_(ddof=2)], None)
  m["agg/var2/f64"] = ([@pl.col("k")], [@pl.col("f64").var_(ddof=2)], None)
  m["agg/var2/s"] = ([@pl.col("k")], [@pl.col("s").var_(ddof=2)], None)
  m["agg/var2/b"] = ([@pl.col("k")], [@pl.col("b").var_(ddof=2)], None)
  m["agg/var2/d"] = ([@pl.col("k")], [@pl.col("d").var_(ddof=2)], None)
  m["agg/var2/dt"] = ([@pl.col("k")], [@pl.col("dt").var_(ddof=2)], None)
  m["agg/var2/n"] = ([@pl.col("k")], [@pl.col("n").var_(ddof=2)], None)
  m["agg/quantile/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/i64"] = (
    [@pl.col("k")],
    [@pl.col("i64").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/f32"] = (
    [@pl.col("k")],
    [@pl.col("f32").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/s"] = (
    [@pl.col("k")],
    [@pl.col("s").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
}

///|
fn golden_group_by_cases_6(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/quantile/b"] = (
    [@pl.col("k")],
    [@pl.col("b").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/d"] = (
    [@pl.col("k")],
    [@pl.col("d").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/dt"] = (
    [@pl.col("k")],
    [@pl.col("dt").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/n"] = (
    [@pl.col("k")],
    [@pl.col("n").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile-nearest/0.0/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.0, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile-nearest/0.3/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.3, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile-nearest/1.0/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(1.0, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile-nearest/0.0/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.0, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile-nearest/0.3/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.3, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile-nearest/1.0/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(1.0, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile-nearest/0.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.0, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile-nearest/0.3/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.3, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile-nearest/1.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(1.0, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile-higher/0.0/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.0, interpolation=@pl.QuantileMethod::Higher)],
    None,
  )
  m["agg/quantile-higher/0.3/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.3, interpolation=@pl.QuantileMethod::Higher)],
    None,
  )
  m["agg/quantile-higher/1.0/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(1.0, interpolation=@pl.QuantileMethod::Higher)],
    None,
  )
  m["agg/quantile-higher/0.0/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.0, interpolation=@pl.QuantileMethod::Higher)],
    None,
  )
  m["agg/quantile-higher/0.3/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.3, interpolation=@pl.QuantileMethod::Higher)],
    None,
  )
  m["agg/quantile-higher/1.0/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(1.0, interpolation=@pl.QuantileMethod::Higher)],
    None,
  )
  m["agg/quantile-higher/0.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.0, interpolation=@pl.QuantileMethod::Higher)],
    None,
  )
  m["agg/quantile-higher/0.3/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.3, interpolation=@pl.QuantileMethod::Higher)],
    None,
  )
  m["agg/quantile-higher/1.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(1.0, interpolation=@pl.QuantileMethod::Higher)],
    None,
  )
  m["agg/quantile-lower/0.0/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.0, interpolation=@pl.QuantileMethod::Lower)],
    None,
  )
  m["agg/quantile-lower/0.3/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.3, interpolation=@pl.QuantileMethod::Lower)],
    None,
  )
  m["agg/quantile-lower/1.0/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(1.0, interpolation=@pl.QuantileMethod::Lower)],
    None,
  )
  m["agg/quantile-lower/0.0/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.0, interpolation=@pl.QuantileMethod::Lower)],
    None,
  )
  m["agg/quantile-lower/0.3/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.3, interpolation=@pl.QuantileMethod::Lower)],
    None,
  )
  m["agg/quantile-lower/1.0/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(1.0, interpolation=@pl.QuantileMethod::Lower)],
    None,
  )
  m["agg/quantile-lower/0.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.0, interpolation=@pl.QuantileMethod::Lower)],
    None,
  )
  m["agg/quantile-lower/0.3/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.3, interpolation=@pl.QuantileMethod::Lower)],
    None,
  )
  m["agg/quantile-lower/1.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(1.0, interpolation=@pl.QuantileMethod::Lower)],
    None,
  )
  m["agg/quantile-midpoint/0.0/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.0, interpolation=@pl.QuantileMethod::Midpoint)],
    None,
  )
  m["agg/quantile-midpoint/0.3/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.3, interpolation=@pl.QuantileMethod::Midpoint)],
    None,
  )
  m["agg/quantile-midpoint/1.0/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(1.0, interpolation=@pl.QuantileMethod::Midpoint)],
    None,
  )
  m["agg/quantile-midpoint/0.0/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.0, interpolation=@pl.QuantileMethod::Midpoint)],
    None,
  )
  m["agg/quantile-midpoint/0.3/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.3, interpolation=@pl.QuantileMethod::Midpoint)],
    None,
  )
  m["agg/quantile-midpoint/1.0/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(1.0, interpolation=@pl.QuantileMethod::Midpoint)],
    None,
  )
  m["agg/quantile-midpoint/0.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.0, interpolation=@pl.QuantileMethod::Midpoint)],
    None,
  )
  m["agg/quantile-midpoint/0.3/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.3, interpolation=@pl.QuantileMethod::Midpoint)],
    None,
  )
  m["agg/quantile-midpoint/1.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(1.0, interpolation=@pl.QuantileMethod::Midpoint)],
    None,
  )
}

///|
fn golden_group_by_cases_7(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/quantile-linear/0.0/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.0, interpolation=@pl.QuantileMethod::Linear)],
    None,
  )
  m["agg/quantile-linear/0.3/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.3, interpolation=@pl.QuantileMethod::Linear)],
    None,
  )
  m["agg/quantile-linear/1.0/i32"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(1.0, interpolation=@pl.QuantileMethod::Linear)],
    None,
  )
  m["agg/quantile-linear/0.0/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.0, interpolation=@pl.QuantileMethod::Linear)],
    None,
  )
  m["agg/quantile-linear/0.3/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.3, interpolation=@pl.QuantileMethod::Linear)],
    None,
  )
  m["agg/quantile-linear/1.0/f64"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(1.0, interpolation=@pl.QuantileMethod::Linear)],
    None,
  )
  m["agg/quantile-linear/0.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.0, interpolation=@pl.QuantileMethod::Linear)],
    None,
  )
  m["agg/quantile-linear/0.3/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.3, interpolation=@pl.QuantileMethod::Linear)],
    None,
  )
  m["agg/quantile-linear/1.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(1.0, interpolation=@pl.QuantileMethod::Linear)],
    None,
  )
  m["agg/quantile-equiprobable/0.0/i32"] = (
    [@pl.col("k")],
    [
      @pl.col("i32").quantile(
        0.0,
        interpolation=@pl.QuantileMethod::Equiprobable,
      ),
    ],
    None,
  )
  m["agg/quantile-equiprobable/0.3/i32"] = (
    [@pl.col("k")],
    [
      @pl.col("i32").quantile(
        0.3,
        interpolation=@pl.QuantileMethod::Equiprobable,
      ),
    ],
    None,
  )
  m["agg/quantile-equiprobable/1.0/i32"] = (
    [@pl.col("k")],
    [
      @pl.col("i32").quantile(
        1.0,
        interpolation=@pl.QuantileMethod::Equiprobable,
      ),
    ],
    None,
  )
  m["agg/quantile-equiprobable/0.0/f64"] = (
    [@pl.col("k")],
    [
      @pl.col("f64").quantile(
        0.0,
        interpolation=@pl.QuantileMethod::Equiprobable,
      ),
    ],
    None,
  )
  m["agg/quantile-equiprobable/0.3/f64"] = (
    [@pl.col("k")],
    [
      @pl.col("f64").quantile(
        0.3,
        interpolation=@pl.QuantileMethod::Equiprobable,
      ),
    ],
    None,
  )
  m["agg/quantile-equiprobable/1.0/f64"] = (
    [@pl.col("k")],
    [
      @pl.col("f64").quantile(
        1.0,
        interpolation=@pl.QuantileMethod::Equiprobable,
      ),
    ],
    None,
  )
  m["agg/quantile-equiprobable/0.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.0, interpolation=@pl.QuantileMethod::Equiprobable)],
    None,
  )
  m["agg/quantile-equiprobable/0.3/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.3, interpolation=@pl.QuantileMethod::Equiprobable)],
    None,
  )
  m["agg/quantile-equiprobable/1.0/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(1.0, interpolation=@pl.QuantileMethod::Equiprobable)],
    None,
  )
  m["agg/sum/i32/e"] = ([@pl.col("k")], [@pl.col("i32").sum()], None)
  m["agg/sum/i64/e"] = ([@pl.col("k")], [@pl.col("i64").sum()], None)
  m["agg/sum/f32/e"] = ([@pl.col("k")], [@pl.col("f32").sum()], None)
  m["agg/sum/f64/e"] = ([@pl.col("k")], [@pl.col("f64").sum()], None)
  m["agg/sum/s/e"] = ([@pl.col("k")], [@pl.col("s").sum()], None)
  m["agg/sum/b/e"] = ([@pl.col("k")], [@pl.col("b").sum()], None)
  m["agg/sum/d/e"] = ([@pl.col("k")], [@pl.col("d").sum()], None)
  m["agg/sum/dt/e"] = ([@pl.col("k")], [@pl.col("dt").sum()], None)
  m["agg/sum/n/e"] = ([@pl.col("k")], [@pl.col("n").sum()], None)
  m["agg/mean/i32/e"] = ([@pl.col("k")], [@pl.col("i32").mean()], None)
  m["agg/mean/i64/e"] = ([@pl.col("k")], [@pl.col("i64").mean()], None)
  m["agg/mean/f32/e"] = ([@pl.col("k")], [@pl.col("f32").mean()], None)
  m["agg/mean/f64/e"] = ([@pl.col("k")], [@pl.col("f64").mean()], None)
  m["agg/mean/s/e"] = ([@pl.col("k")], [@pl.col("s").mean()], None)
  m["agg/mean/b/e"] = ([@pl.col("k")], [@pl.col("b").mean()], None)
  m["agg/mean/d/e"] = ([@pl.col("k")], [@pl.col("d").mean()], None)
  m["agg/mean/dt/e"] = ([@pl.col("k")], [@pl.col("dt").mean()], None)
  m["agg/mean/n/e"] = ([@pl.col("k")], [@pl.col("n").mean()], None)
  m["agg/min/i32/e"] = ([@pl.col("k")], [@pl.col("i32").min()], None)
  m["agg/min/i64/e"] = ([@pl.col("k")], [@pl.col("i64").min()], None)
  m["agg/min/f32/e"] = ([@pl.col("k")], [@pl.col("f32").min()], None)
  m["agg/min/f64/e"] = ([@pl.col("k")], [@pl.col("f64").min()], None)
}

///|
fn golden_group_by_cases_8(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/min/s/e"] = ([@pl.col("k")], [@pl.col("s").min()], None)
  m["agg/min/b/e"] = ([@pl.col("k")], [@pl.col("b").min()], None)
  m["agg/min/d/e"] = ([@pl.col("k")], [@pl.col("d").min()], None)
  m["agg/min/dt/e"] = ([@pl.col("k")], [@pl.col("dt").min()], None)
  m["agg/min/n/e"] = ([@pl.col("k")], [@pl.col("n").min()], None)
  m["agg/max/i32/e"] = ([@pl.col("k")], [@pl.col("i32").max()], None)
  m["agg/max/i64/e"] = ([@pl.col("k")], [@pl.col("i64").max()], None)
  m["agg/max/f32/e"] = ([@pl.col("k")], [@pl.col("f32").max()], None)
  m["agg/max/f64/e"] = ([@pl.col("k")], [@pl.col("f64").max()], None)
  m["agg/max/s/e"] = ([@pl.col("k")], [@pl.col("s").max()], None)
  m["agg/max/b/e"] = ([@pl.col("k")], [@pl.col("b").max()], None)
  m["agg/max/d/e"] = ([@pl.col("k")], [@pl.col("d").max()], None)
  m["agg/max/dt/e"] = ([@pl.col("k")], [@pl.col("dt").max()], None)
  m["agg/max/n/e"] = ([@pl.col("k")], [@pl.col("n").max()], None)
  m["agg/count/i32/e"] = ([@pl.col("k")], [@pl.col("i32").count()], None)
  m["agg/count/i64/e"] = ([@pl.col("k")], [@pl.col("i64").count()], None)
  m["agg/count/f32/e"] = ([@pl.col("k")], [@pl.col("f32").count()], None)
  m["agg/count/f64/e"] = ([@pl.col("k")], [@pl.col("f64").count()], None)
  m["agg/count/s/e"] = ([@pl.col("k")], [@pl.col("s").count()], None)
  m["agg/count/b/e"] = ([@pl.col("k")], [@pl.col("b").count()], None)
  m["agg/count/d/e"] = ([@pl.col("k")], [@pl.col("d").count()], None)
  m["agg/count/dt/e"] = ([@pl.col("k")], [@pl.col("dt").count()], None)
  m["agg/count/n/e"] = ([@pl.col("k")], [@pl.col("n").count()], None)
  m["agg/len/i32/e"] = ([@pl.col("k")], [@pl.col("i32").len()], None)
  m["agg/len/i64/e"] = ([@pl.col("k")], [@pl.col("i64").len()], None)
  m["agg/len/f32/e"] = ([@pl.col("k")], [@pl.col("f32").len()], None)
  m["agg/len/f64/e"] = ([@pl.col("k")], [@pl.col("f64").len()], None)
  m["agg/len/s/e"] = ([@pl.col("k")], [@pl.col("s").len()], None)
  m["agg/len/b/e"] = ([@pl.col("k")], [@pl.col("b").len()], None)
  m["agg/len/d/e"] = ([@pl.col("k")], [@pl.col("d").len()], None)
  m["agg/len/dt/e"] = ([@pl.col("k")], [@pl.col("dt").len()], None)
  m["agg/len/n/e"] = ([@pl.col("k")], [@pl.col("n").len()], None)
  m["agg/n_unique/i32/e"] = ([@pl.col("k")], [@pl.col("i32").n_unique()], None)
  m["agg/n_unique/i64/e"] = ([@pl.col("k")], [@pl.col("i64").n_unique()], None)
  m["agg/n_unique/f32/e"] = ([@pl.col("k")], [@pl.col("f32").n_unique()], None)
  m["agg/n_unique/f64/e"] = ([@pl.col("k")], [@pl.col("f64").n_unique()], None)
  m["agg/n_unique/s/e"] = ([@pl.col("k")], [@pl.col("s").n_unique()], None)
  m["agg/n_unique/b/e"] = ([@pl.col("k")], [@pl.col("b").n_unique()], None)
  m["agg/n_unique/d/e"] = ([@pl.col("k")], [@pl.col("d").n_unique()], None)
  m["agg/n_unique/dt/e"] = ([@pl.col("k")], [@pl.col("dt").n_unique()], None)
}

///|
fn golden_group_by_cases_9(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/n_unique/n/e"] = ([@pl.col("k")], [@pl.col("n").n_unique()], None)
  m["agg/first/i32/e"] = ([@pl.col("k")], [@pl.col("i32").first()], None)
  m["agg/first/i64/e"] = ([@pl.col("k")], [@pl.col("i64").first()], None)
  m["agg/first/f32/e"] = ([@pl.col("k")], [@pl.col("f32").first()], None)
  m["agg/first/f64/e"] = ([@pl.col("k")], [@pl.col("f64").first()], None)
  m["agg/first/s/e"] = ([@pl.col("k")], [@pl.col("s").first()], None)
  m["agg/first/b/e"] = ([@pl.col("k")], [@pl.col("b").first()], None)
  m["agg/first/d/e"] = ([@pl.col("k")], [@pl.col("d").first()], None)
  m["agg/first/dt/e"] = ([@pl.col("k")], [@pl.col("dt").first()], None)
  m["agg/first/n/e"] = ([@pl.col("k")], [@pl.col("n").first()], None)
  m["agg/last/i32/e"] = ([@pl.col("k")], [@pl.col("i32").last()], None)
  m["agg/last/i64/e"] = ([@pl.col("k")], [@pl.col("i64").last()], None)
  m["agg/last/f32/e"] = ([@pl.col("k")], [@pl.col("f32").last()], None)
  m["agg/last/f64/e"] = ([@pl.col("k")], [@pl.col("f64").last()], None)
  m["agg/last/s/e"] = ([@pl.col("k")], [@pl.col("s").last()], None)
  m["agg/last/b/e"] = ([@pl.col("k")], [@pl.col("b").last()], None)
  m["agg/last/d/e"] = ([@pl.col("k")], [@pl.col("d").last()], None)
  m["agg/last/dt/e"] = ([@pl.col("k")], [@pl.col("dt").last()], None)
  m["agg/last/n/e"] = ([@pl.col("k")], [@pl.col("n").last()], None)
  m["agg/median/i32/e"] = ([@pl.col("k")], [@pl.col("i32").median()], None)
  m["agg/median/i64/e"] = ([@pl.col("k")], [@pl.col("i64").median()], None)
  m["agg/median/f32/e"] = ([@pl.col("k")], [@pl.col("f32").median()], None)
  m["agg/median/f64/e"] = ([@pl.col("k")], [@pl.col("f64").median()], None)
  m["agg/median/s/e"] = ([@pl.col("k")], [@pl.col("s").median()], None)
  m["agg/median/b/e"] = ([@pl.col("k")], [@pl.col("b").median()], None)
  m["agg/median/d/e"] = ([@pl.col("k")], [@pl.col("d").median()], None)
  m["agg/median/dt/e"] = ([@pl.col("k")], [@pl.col("dt").median()], None)
  m["agg/median/n/e"] = ([@pl.col("k")], [@pl.col("n").median()], None)
  m["agg/product/i32/e"] = ([@pl.col("k")], [@pl.col("i32").product()], None)
  m["agg/product/i64/e"] = ([@pl.col("k")], [@pl.col("i64").product()], None)
  m["agg/product/f32/e"] = ([@pl.col("k")], [@pl.col("f32").product()], None)
  m["agg/product/f64/e"] = ([@pl.col("k")], [@pl.col("f64").product()], None)
  m["agg/product/s/e"] = ([@pl.col("k")], [@pl.col("s").product()], None)
  m["agg/product/b/e"] = ([@pl.col("k")], [@pl.col("b").product()], None)
  m["agg/product/d/e"] = ([@pl.col("k")], [@pl.col("d").product()], None)
  m["agg/product/dt/e"] = ([@pl.col("k")], [@pl.col("dt").product()], None)
  m["agg/product/n/e"] = ([@pl.col("k")], [@pl.col("n").product()], None)
  m["agg/std0/i32/e"] = ([@pl.col("k")], [@pl.col("i32").std(ddof=0)], None)
  m["agg/std0/f32/e"] = ([@pl.col("k")], [@pl.col("f32").std(ddof=0)], None)
  m["agg/std0/f64/e"] = ([@pl.col("k")], [@pl.col("f64").std(ddof=0)], None)
}

///|
fn golden_group_by_cases_10(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/std0/s/e"] = ([@pl.col("k")], [@pl.col("s").std(ddof=0)], None)
  m["agg/std0/d/e"] = ([@pl.col("k")], [@pl.col("d").std(ddof=0)], None)
  m["agg/std0/n/e"] = ([@pl.col("k")], [@pl.col("n").std(ddof=0)], None)
  m["agg/std0/b/e"] = ([@pl.col("k")], [@pl.col("b").std(ddof=0)], None)
  m["agg/std1/i32/e"] = ([@pl.col("k")], [@pl.col("i32").std(ddof=1)], None)
  m["agg/std1/f32/e"] = ([@pl.col("k")], [@pl.col("f32").std(ddof=1)], None)
  m["agg/std1/f64/e"] = ([@pl.col("k")], [@pl.col("f64").std(ddof=1)], None)
  m["agg/std1/s/e"] = ([@pl.col("k")], [@pl.col("s").std(ddof=1)], None)
  m["agg/std1/d/e"] = ([@pl.col("k")], [@pl.col("d").std(ddof=1)], None)
  m["agg/std1/n/e"] = ([@pl.col("k")], [@pl.col("n").std(ddof=1)], None)
  m["agg/std1/b/e"] = ([@pl.col("k")], [@pl.col("b").std(ddof=1)], None)
  m["agg/std2/i32/e"] = ([@pl.col("k")], [@pl.col("i32").std(ddof=2)], None)
  m["agg/std2/f32/e"] = ([@pl.col("k")], [@pl.col("f32").std(ddof=2)], None)
  m["agg/std2/f64/e"] = ([@pl.col("k")], [@pl.col("f64").std(ddof=2)], None)
  m["agg/std2/s/e"] = ([@pl.col("k")], [@pl.col("s").std(ddof=2)], None)
  m["agg/std2/d/e"] = ([@pl.col("k")], [@pl.col("d").std(ddof=2)], None)
  m["agg/std2/n/e"] = ([@pl.col("k")], [@pl.col("n").std(ddof=2)], None)
  m["agg/std2/b/e"] = ([@pl.col("k")], [@pl.col("b").std(ddof=2)], None)
  m["agg/var0/i32/e"] = ([@pl.col("k")], [@pl.col("i32").var_(ddof=0)], None)
  m["agg/var0/f32/e"] = ([@pl.col("k")], [@pl.col("f32").var_(ddof=0)], None)
  m["agg/var0/f64/e"] = ([@pl.col("k")], [@pl.col("f64").var_(ddof=0)], None)
  m["agg/var0/s/e"] = ([@pl.col("k")], [@pl.col("s").var_(ddof=0)], None)
  m["agg/var0/d/e"] = ([@pl.col("k")], [@pl.col("d").var_(ddof=0)], None)
  m["agg/var0/n/e"] = ([@pl.col("k")], [@pl.col("n").var_(ddof=0)], None)
  m["agg/var0/b/e"] = ([@pl.col("k")], [@pl.col("b").var_(ddof=0)], None)
  m["agg/var1/i32/e"] = ([@pl.col("k")], [@pl.col("i32").var_(ddof=1)], None)
  m["agg/var1/f32/e"] = ([@pl.col("k")], [@pl.col("f32").var_(ddof=1)], None)
  m["agg/var1/f64/e"] = ([@pl.col("k")], [@pl.col("f64").var_(ddof=1)], None)
  m["agg/var1/s/e"] = ([@pl.col("k")], [@pl.col("s").var_(ddof=1)], None)
  m["agg/var1/d/e"] = ([@pl.col("k")], [@pl.col("d").var_(ddof=1)], None)
  m["agg/var1/n/e"] = ([@pl.col("k")], [@pl.col("n").var_(ddof=1)], None)
  m["agg/var1/b/e"] = ([@pl.col("k")], [@pl.col("b").var_(ddof=1)], None)
  m["agg/var2/i32/e"] = ([@pl.col("k")], [@pl.col("i32").var_(ddof=2)], None)
  m["agg/var2/f32/e"] = ([@pl.col("k")], [@pl.col("f32").var_(ddof=2)], None)
  m["agg/var2/f64/e"] = ([@pl.col("k")], [@pl.col("f64").var_(ddof=2)], None)
  m["agg/var2/s/e"] = ([@pl.col("k")], [@pl.col("s").var_(ddof=2)], None)
  m["agg/var2/d/e"] = ([@pl.col("k")], [@pl.col("d").var_(ddof=2)], None)
  m["agg/var2/n/e"] = ([@pl.col("k")], [@pl.col("n").var_(ddof=2)], None)
  m["agg/var2/b/e"] = ([@pl.col("k")], [@pl.col("b").var_(ddof=2)], None)
  m["agg/quantile/i32/e"] = (
    [@pl.col("k")],
    [@pl.col("i32").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
}

///|
fn golden_group_by_cases_11(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/quantile/i64/e"] = (
    [@pl.col("k")],
    [@pl.col("i64").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/f32/e"] = (
    [@pl.col("k")],
    [@pl.col("f32").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/f64/e"] = (
    [@pl.col("k")],
    [@pl.col("f64").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/s/e"] = (
    [@pl.col("k")],
    [@pl.col("s").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/b/e"] = (
    [@pl.col("k")],
    [@pl.col("b").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/d/e"] = (
    [@pl.col("k")],
    [@pl.col("d").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/dt/e"] = (
    [@pl.col("k")],
    [@pl.col("dt").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/quantile/n/e"] = (
    [@pl.col("k")],
    [@pl.col("n").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)],
    None,
  )
  m["agg/focus2/i32"] = (
    [@pl.col("i32")],
    [@pl.col("y").sum(), @pl.col("y").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2-f64/i32"] = (
    [@pl.col("i32")],
    [@pl.col("x").sum(), @pl.col("x").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2/i64"] = (
    [@pl.col("i64")],
    [@pl.col("y").sum(), @pl.col("y").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2-f64/i64"] = (
    [@pl.col("i64")],
    [@pl.col("x").sum(), @pl.col("x").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2/f32"] = (
    [@pl.col("f32")],
    [@pl.col("y").sum(), @pl.col("y").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2-f64/f32"] = (
    [@pl.col("f32")],
    [@pl.col("x").sum(), @pl.col("x").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2/f64"] = (
    [@pl.col("f64")],
    [@pl.col("y").sum(), @pl.col("y").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2-f64/f64"] = (
    [@pl.col("f64")],
    [@pl.col("x").sum(), @pl.col("x").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2/s"] = (
    [@pl.col("s")],
    [@pl.col("y").sum(), @pl.col("y").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2-f64/s"] = (
    [@pl.col("s")],
    [@pl.col("x").sum(), @pl.col("x").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2/b"] = (
    [@pl.col("b")],
    [@pl.col("y").sum(), @pl.col("y").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2-f64/b"] = (
    [@pl.col("b")],
    [@pl.col("x").sum(), @pl.col("x").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2/d"] = (
    [@pl.col("d")],
    [@pl.col("y").sum(), @pl.col("y").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2-f64/d"] = (
    [@pl.col("d")],
    [@pl.col("x").sum(), @pl.col("x").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2/dt"] = (
    [@pl.col("dt")],
    [@pl.col("y").sum(), @pl.col("y").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2-f64/dt"] = (
    [@pl.col("dt")],
    [@pl.col("x").sum(), @pl.col("x").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2/n"] = (
    [@pl.col("n")],
    [@pl.col("y").sum(), @pl.col("y").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/focus2-f64/n"] = (
    [@pl.col("n")],
    [@pl.col("x").sum(), @pl.col("x").mean().alias("m"), @pl.len()],
    None,
  )
  m["agg/many"] = (
    [@pl.col("k")],
    [
      @pl.col("i32").sum(),
      @pl.col("f64").mean().alias("m"),
      @pl.col("s").min().alias("mn"),
      @pl.col("d").max().alias("mx"),
      @pl.col("n").count().alias("cn"),
      @pl.len(),
    ],
    None,
  )
  m["agg/many/e"] = (
    [@pl.col("k")],
    [
      @pl.col("i32").sum(),
      @pl.col("f64").mean().alias("m"),
      @pl.col("s").min().alias("mn"),
      @pl.col("d").max().alias("mx"),
      @pl.col("n").count().alias("cn"),
      @pl.len(),
    ],
    None,
  )
  m["big/sum/x"] = ([@pl.col("k")], [@pl.col("x").sum()], None)
  m["big/sum/xf"] = ([@pl.col("k")], [@pl.col("xf").sum()], None)
  m["big/sum/v"] = ([@pl.col("k")], [@pl.col("v").sum()], None)
  m["big/mean/x"] = ([@pl.col("k")], [@pl.col("x").mean()], None)
  m["big/mean/xf"] = ([@pl.col("k")], [@pl.col("xf").mean()], None)
  m["big/mean/v"] = ([@pl.col("k")], [@pl.col("v").mean()], None)
  m["big/min/x"] = ([@pl.col("k")], [@pl.col("x").min()], None)
  m["big/min/xf"] = ([@pl.col("k")], [@pl.col("xf").min()], None)
  m["big/min/v"] = ([@pl.col("k")], [@pl.col("v").min()], None)
  m["big/max/x"] = ([@pl.col("k")], [@pl.col("x").max()], None)
  m["big/max/xf"] = ([@pl.col("k")], [@pl.col("xf").max()], None)
  m["big/max/v"] = ([@pl.col("k")], [@pl.col("v").max()], None)
}

///|
fn golden_group_by_cases_12(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["big/median/x"] = ([@pl.col("k")], [@pl.col("x").median()], None)
  m["big/median/xf"] = ([@pl.col("k")], [@pl.col("xf").median()], None)
  m["big/median/v"] = ([@pl.col("k")], [@pl.col("v").median()], None)
  m["big/first/x"] = ([@pl.col("k")], [@pl.col("x").first()], None)
  m["big/first/xf"] = ([@pl.col("k")], [@pl.col("xf").first()], None)
  m["big/first/v"] = ([@pl.col("k")], [@pl.col("v").first()], None)
  m["big/last/x"] = ([@pl.col("k")], [@pl.col("x").last()], None)
  m["big/last/xf"] = ([@pl.col("k")], [@pl.col("xf").last()], None)
  m["big/last/v"] = ([@pl.col("k")], [@pl.col("v").last()], None)
  m["big/count/x"] = ([@pl.col("k")], [@pl.col("x").count()], None)
  m["big/count/xf"] = ([@pl.col("k")], [@pl.col("xf").count()], None)
  m["big/count/v"] = ([@pl.col("k")], [@pl.col("v").count()], None)
  m["big/n_unique/x"] = ([@pl.col("k")], [@pl.col("x").n_unique()], None)
  m["big/n_unique/xf"] = ([@pl.col("k")], [@pl.col("xf").n_unique()], None)
  m["big/n_unique/v"] = ([@pl.col("k")], [@pl.col("v").n_unique()], None)
  m["big/product/x"] = ([@pl.col("k")], [@pl.col("x").product()], None)
  m["big/product/xf"] = ([@pl.col("k")], [@pl.col("xf").product()], None)
  m["big/product/v"] = ([@pl.col("k")], [@pl.col("v").product()], None)
  m["big/std1/x"] = ([@pl.col("k")], [@pl.col("x").std(ddof=1)], None)
  m["big/std1/xf"] = ([@pl.col("k")], [@pl.col("xf").std(ddof=1)], None)
  m["big/std1/v"] = ([@pl.col("k")], [@pl.col("v").std(ddof=1)], None)
  m["big/var1/x"] = ([@pl.col("k")], [@pl.col("x").var_(ddof=1)], None)
  m["big/var1/xf"] = ([@pl.col("k")], [@pl.col("xf").var_(ddof=1)], None)
  m["big/var1/v"] = ([@pl.col("k")], [@pl.col("v").var_(ddof=1)], None)
  m["big/var0/x"] = ([@pl.col("k")], [@pl.col("x").var_(ddof=0)], None)
  m["big/var0/xf"] = ([@pl.col("k")], [@pl.col("xf").var_(ddof=0)], None)
  m["big/var0/v"] = ([@pl.col("k")], [@pl.col("v").var_(ddof=0)], None)
  m["big/quantile/x"] = (
    [@pl.col("k")],
    [@pl.col("x").quantile(0.3, interpolation=@pl.QuantileMethod::Linear)],
    None,
  )
  m["big/quantile/xf"] = (
    [@pl.col("k")],
    [@pl.col("xf").quantile(0.3, interpolation=@pl.QuantileMethod::Linear)],
    None,
  )
  m["big/sum-mean-len"] = (
    [@pl.col("k")],
    [@pl.col("x").sum(), @pl.col("xf").mean().alias("m"), @pl.len()],
    None,
  )
  m["big/none"] = (
    [],
    [@pl.col("x").sum(), @pl.col("xf").mean().alias("m"), @pl.len()],
    None,
  )
  m["lit/int"] = ([@pl.col("k")], [@pl.lit_int(1L)], None)
  m["lit/int-alias"] = ([@pl.col("k")], [@pl.lit_int(1L).alias("x")], None)
  m["lit/float"] = ([@pl.col("k")], [@pl.lit_float(1.5)], None)
  m["lit/str"] = ([@pl.col("k")], [@pl.lit_str("q")], None)
  m["lit/bool"] = ([@pl.col("k")], [@pl.lit_bool(true)], None)
  m["lit/null"] = ([@pl.col("k")], [@pl.lit(@pl.AnyValue::Null)], None)
  m["lit/i32"] = ([@pl.col("k")], [@pl.lit(@pl.AnyValue::Int32(7))], None)
  m["lit/sum"] = ([@pl.col("k")], [@pl.lit_int(1L).sum()], None)
  m["lit/count"] = ([@pl.col("k")], [@pl.lit_int(1L).count()], None)
}

///|
fn golden_group_by_cases_13(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["lit/len"] = ([@pl.col("k")], [@pl.lit_int(1L).len()], None)
  m["lit/n_unique"] = ([@pl.col("k")], [@pl.lit_int(1L).n_unique()], None)
  m["lit/mean"] = ([@pl.col("k")], [@pl.lit_float(2.0).mean()], None)
  m["lit/sum-lits"] = (
    [@pl.col("k")],
    [(@pl.lit_int(1L) + @pl.lit_int(2L)).sum()],
    None,
  )
  m["lit/sum-str"] = ([@pl.col("k")], [@pl.lit_str("a").sum()], None)
  m["lit/plus-agg"] = (
    [@pl.col("k")],
    [@pl.lit_int(1L) + @pl.col("y").sum()],
    None,
  )
  m["lit/e"] = (
    [@pl.col("k")],
    [
      @pl.lit_int(1L),
      @pl.lit_float(2.5).alias("f"),
      @pl.lit_str("q").alias("s"),
    ],
    None,
  )
  m["plen/expr"] = ([@pl.col("k")], [@pl.len()], None)
  m["plen/times"] = ([@pl.col("k")], [@pl.len() * @pl.lit_int(2L)], None)
  m["plen/alias"] = (
    [@pl.col("k")],
    [@pl.len().alias("n"), @pl.col("y").sum()],
    None,
  )
  m["plen/as-k"] = ([@pl.col("k")], [@pl.len().alias("k")], None)
  m["plen/vs-count"] = (
    [@pl.col("k")],
    [
      @pl.len(),
      @pl.col("i32").count().alias("c"),
      @pl.col("i32").len().alias("l"),
    ],
    None,
  )
  m["plen/ratio"] = (
    [@pl.col("k")],
    [(@pl.col("i32").count() / @pl.len()).alias("r")],
    None,
  )
  m["plen/e"] = ([@pl.col("k")], [@pl.len()], None)
  m["plen/select"] = ([], [@pl.len()], None)
  m["expr/sum-over-count"] = (
    [@pl.col("k")],
    [(@pl.col("y").sum() / @pl.col("y").count()).alias("avg")],
    None,
  )
  m["expr/max-minus-min"] = (
    [@pl.col("k")],
    [(@pl.col("y").max() - @pl.col("y").min()).alias("range")],
    None,
  )
  m["expr/sum-plus-1"] = (
    [@pl.col("k")],
    [@pl.col("y").sum() + @pl.lit_int(1L)],
    None,
  )
  m["expr/sum-plus-1.5"] = (
    [@pl.col("k")],
    [@pl.col("y").sum() + @pl.lit_float(1.5)],
    None,
  )
  m["expr/1-plus-sum"] = (
    [@pl.col("k")],
    [@pl.lit_int(1L) + @pl.col("y").sum()],
    None,
  )
  m["expr/neg-sum"] = ([@pl.col("k")], [-@pl.col("y").sum()], None)
  m["expr/abs-sum"] = ([@pl.col("k")], [@pl.col("i32").sum().abs()], None)
  m["expr/sqrt-sum"] = ([@pl.col("k")], [@pl.col("x").sum().sqrt()], None)
  m["expr/round-mean"] = (
    [@pl.col("k")],
    [@pl.col("x").mean().round(decimals=1)],
    None,
  )
  m["expr/cast-sum"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().cast(@pl.DataType::Float64)],
    None,
  )
  m["expr/is-null-sum"] = (
    [@pl.col("k")],
    [@pl.col("i32").min().is_null()],
    None,
  )
  m["expr/gt-sum"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().gt(@pl.lit_int(100L))],
    None,
  )
  m["expr/and-gt"] = (
    [@pl.col("k")],
    [
      @pl.col("y").sum().gt(@pl.lit_int(100L)) &
      @pl.col("y").count().lt(@pl.lit_int(5L)),
    ],
    None,
  )
  m["expr/fill-null-min"] = (
    [@pl.col("k")],
    [@pl.col("i32").min().fill_null(@pl.lit_int(-1L))],
    None,
  )
  m["expr/fill-null-mean"] = (
    [@pl.col("k")],
    [@pl.col("i32").mean().fill_null(@pl.lit_float(0.0))],
    None,
  )
  m["expr/between"] = (
    [@pl.col("k")],
    [
      @pl.col("y")
      .sum()
      .between(
        @pl.lit_int(60L),
        @pl.lit_int(300L),
        closed=@pl.ClosedInterval::Both,
      ),
    ],
    None,
  )
  m["expr/when-sums"] = (
    [@pl.col("k")],
    [
      @pl.when(@pl.col("y").sum().gt(@pl.lit_int(100L)))
      .then(@pl.col("x").sum())
      .otherwise(@pl.lit_float(0.0)),
    ],
    None,
  )
  m["expr/when-lit"] = (
    [@pl.col("k")],
    [
      @pl.when(@pl.col("y").count().gt(@pl.lit_int(2L)))
      .then(@pl.lit_int(1L))
      .otherwise(@pl.lit_int(0L)),
    ],
    None,
  )
  m["expr/str-of-min"] = (
    [@pl.col("k")],
    [@pl.col("s").min().str().len_chars()],
    None,
  )
  m["expr/str-of-first"] = (
    [@pl.col("k")],
    [@pl.col("s").first().str().to_uppercase()],
    None,
  )
  m["expr/dt-of-max"] = ([@pl.col("k")], [@pl.col("d").max().dt().year()], None)
  m["expr/sum-of-sum"] = ([@pl.col("k")], [@pl.col("y").sum().sum()], None)
  m["expr/mean-of-sum"] = ([@pl.col("k")], [@pl.col("y").sum().mean()], None)
  m["expr/first-of-mean"] = (
    [@pl.col("k")],
    [@pl.col("x").mean().first()],
    None,
  )
  m["expr/min-of-count"] = (
    [@pl.col("k")],
    [@pl.col("i32").count().min()],
    None,
  )
}

///|
fn golden_group_by_cases_14(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["expr/two-aggs-names"] = (
    [@pl.col("k")],
    [
      @pl.col("y").sum() + @pl.col("i32").sum(),
      @pl.col("i32").sum() + @pl.col("y").sum(),
    ],
    None,
  )
  m["expr/sum+sum-names"] = (
    [@pl.col("k")],
    [(@pl.col("y").sum() + @pl.col("y").max()).alias("z"), @pl.col("y").min()],
    None,
  )
  m["expr/agg-str-lit"] = (
    [@pl.col("k")],
    [@pl.col("s").min() + @pl.lit_str("x")],
    None,
  )
  m["rows/a*b-sum"] = (
    [@pl.col("k")],
    [(@pl.col("y") * @pl.col("i32")).sum().alias("p")],
    None,
  )
  m["rows/x*y-sum"] = (
    [@pl.col("k")],
    [(@pl.col("x") * @pl.col("y")).sum().alias("p")],
    None,
  )
  m["rows/when-sum"] = (
    [@pl.col("k")],
    [
      @pl.when(@pl.col("i32").gt(@pl.lit_int(0L)))
      .then(@pl.col("y"))
      .otherwise(@pl.lit_int(0L))
      .sum(),
    ],
    None,
  )
  m["rows/when-sum-f"] = (
    [@pl.col("k")],
    [
      @pl.when(@pl.col("x").gt(@pl.lit_float(0.5)))
      .then(@pl.col("x"))
      .otherwise(@pl.lit_float(0.0))
      .sum(),
    ],
    None,
  )
  m["rows/fill_null-mean"] = (
    [@pl.col("k")],
    [@pl.col("i32").fill_null(@pl.lit_int(0L)).mean()],
    None,
  )
  m["rows/fill_null-sum-f"] = (
    [@pl.col("k")],
    [@pl.col("f64").fill_null(@pl.lit_float(0.0)).sum()],
    None,
  )
  m["rows/abs-max"] = ([@pl.col("k")], [@pl.col("i32").abs().max()], None)
  m["rows/is_null-sum"] = (
    [@pl.col("k")],
    [@pl.col("i32").is_null().sum()],
    None,
  )
  m["rows/is_not_null-mean"] = (
    [@pl.col("k")],
    [@pl.col("s").is_not_null().mean()],
    None,
  )
  m["rows/cast-sum"] = (
    [@pl.col("k")],
    [@pl.col("b").cast(@pl.DataType::Int32).sum()],
    None,
  )
  m["rows/b-sum"] = ([@pl.col("k")], [@pl.col("b").sum()], None)
  m["rows/gt-sum"] = (
    [@pl.col("k")],
    [@pl.col("y").gt(@pl.lit_int(50L)).sum()],
    None,
  )
  m["rows/str-len-max"] = (
    [@pl.col("k")],
    [@pl.col("s").str().len_chars().max()],
    None,
  )
  m["rows/str-upper-first"] = (
    [@pl.col("k")],
    [@pl.col("s").str().to_uppercase().first()],
    None,
  )
  m["rows/dt-year-max"] = (
    [@pl.col("k")],
    [@pl.col("d").dt().year().max()],
    None,
  )
  m["rows/is_in-sum"] = (
    [@pl.col("k")],
    [@pl.col("i32").is_in(vs["i32"]).sum()],
    None,
  )
  m["rows/between-sum"] = (
    [@pl.col("k")],
    [
      @pl.col("y")
      .between(
        @pl.lit_int(30L),
        @pl.lit_int(90L),
        closed=@pl.ClosedInterval::Both,
      )
      .sum(),
    ],
    None,
  )
  m["rows/n_unique-expr"] = (
    [@pl.col("k")],
    [(@pl.col("y") % @pl.lit_int(20L)).n_unique()],
    None,
  )
  m["rows/lit-sum"] = (
    [@pl.col("k")],
    [(@pl.col("y") + @pl.lit_int(1L)).sum()],
    None,
  )
  m["rows/e"] = (
    [@pl.col("k")],
    [
      (@pl.col("y") * @pl.col("i32")).sum().alias("p"),
      @pl.col("i32").fill_null(@pl.lit_int(0L)).mean().alias("m"),
    ],
    None,
  )
  m["rows/neg-min"] = ([@pl.col("k")], [(-@pl.col("y")).min()], None)
  m["rows/type-error"] = (
    [@pl.col("k")],
    [(@pl.col("s") + @pl.lit_int(1L)).sum()],
    None,
  )
  m["grp/dev-sum"] = (
    [@pl.col("k")],
    [(@pl.col("x") - @pl.col("x").mean()).sum()],
    None,
  )
  m["grp/dev-sum-int"] = (
    [@pl.col("k")],
    [(@pl.col("y") - @pl.col("y").min()).sum()],
    None,
  )
  m["grp/cum_sum-last"] = (
    [@pl.col("k")],
    [@pl.col("y").cum_sum().last()],
    None,
  )
  m["grp/cum_max-sum"] = (
    [@pl.col("k")],
    [@pl.col("i32").cum_max().sum()],
    None,
  )
  m["grp/shift-sum"] = ([@pl.col("k")], [@pl.col("y").shift(n=1).sum()], None)
  m["grp/shift-first"] = (
    [@pl.col("k")],
    [@pl.col("y").shift(n=1).first()],
    None,
  )
  m["grp/shift-neg-last"] = (
    [@pl.col("k")],
    [@pl.col("y").shift(n=-1).last()],
    None,
  )
  m["grp/diff-sum"] = ([@pl.col("k")], [@pl.col("y").diff(n=1).sum()], None)
  m["grp/rank-max"] = (
    [@pl.col("k")],
    [@pl.col("y").rank(method_=@pl.RankMethod::Average).max()],
    None,
  )
  m["grp/rank-min-ordinal"] = (
    [@pl.col("k")],
    [@pl.col("f64").rank(method_=@pl.RankMethod::Ordinal).max()],
    None,
  )
  m["grp/reverse-first"] = (
    [@pl.col("k")],
    [@pl.col("y").reverse().first()],
    None,
  )
  m["grp/fill-forward-last"] = (
    [@pl.col("k")],
    [@pl.col("i32").fill_null_strategy(@pl.FillStrategy::Forward).last()],
    None,
  )
  m["grp/count-of-shift"] = (
    [@pl.col("k")],
    [@pl.col("i32").shift(n=1).count()],
    None,
  )
  m["grp/len-of-shift"] = (
    [@pl.col("k")],
    [@pl.col("i32").shift(n=1).len()],
    None,
  )
  m["grp/n_unique-of-rank"] = (
    [@pl.col("k")],
    [@pl.col("y").rank(method_=@pl.RankMethod::Average).n_unique()],
    None,
  )
}

///|
fn golden_group_by_cases_15(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["grp/sum-in-when"] = (
    [@pl.col("k")],
    [
      @pl.when(@pl.col("y").gt(@pl.col("y").mean()))
      .then(@pl.lit_int(1L))
      .otherwise(@pl.lit_int(0L))
      .sum(),
    ],
    None,
  )
  m["grp/dev-over-len"] = (
    [@pl.col("k")],
    [(@pl.col("y") / @pl.len()).max()],
    None,
  )
  m["grp/dev-sq"] = (
    [@pl.col("k")],
    [
      ((@pl.col("x") - @pl.col("x").mean()) *
      (@pl.col("x") - @pl.col("x").mean())).mean(),
    ],
    None,
  )
  m["grp/sum-of-sum-in-agg"] = (
    [@pl.col("k")],
    [(@pl.col("y") + @pl.col("y").sum()).sum()],
    None,
  )
  m["grp/median-dev"] = (
    [@pl.col("k")],
    [(@pl.col("x") - @pl.col("x").median()).median()],
    None,
  )
  m["grp/e"] = (
    [@pl.col("k")],
    [
      (@pl.col("x") - @pl.col("x").mean()).sum(),
      @pl.col("y").cum_sum().last().alias("cl"),
      @pl.col("y").rank(method_=@pl.RankMethod::Average).max().alias("rm"),
    ],
    None,
  )
  m["grp/rank-str"] = (
    [@pl.col("k")],
    [@pl.col("s").rank(method_=@pl.RankMethod::Average).max()],
    None,
  )
  m["grp/cum_sum-str"] = ([@pl.col("k")], [@pl.col("s").cum_sum().last()], None)
  m["grp/big-dev"] = (
    [@pl.col("k")],
    [(@pl.col("x") - @pl.col("x").mean()).sum()],
    None,
  )
  m["scalar-seq/cum_sum"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().cum_sum()],
    None,
  )
  m["scalar-seq/shift"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().shift(n=1)],
    None,
  )
  m["scalar-seq/shift-neg"] = (
    [@pl.col("k")],
    [@pl.col("i32").max().shift(n=-1)],
    None,
  )
  m["scalar-seq/diff"] = ([@pl.col("k")], [@pl.col("y").sum().diff(n=1)], None)
  m["scalar-seq/rank"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().rank(method_=@pl.RankMethod::Average)],
    None,
  )
  m["scalar-seq/rank-null"] = (
    [@pl.col("k")],
    [@pl.col("i32").min().rank(method_=@pl.RankMethod::Average)],
    None,
  )
  m["scalar-seq/reverse"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().reverse()],
    None,
  )
  m["scalar-seq/cum_count"] = (
    [@pl.col("k")],
    [@pl.col("i32").min().cum_count()],
    None,
  )
  m["scalar-seq/fill-forward"] = (
    [@pl.col("k")],
    [@pl.col("i32").min().fill_null_strategy(@pl.FillStrategy::Forward)],
    None,
  )
  m["scalar-seq/e"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().cum_sum(), @pl.col("y").sum().shift(n=1).alias("sh")],
    None,
  )
  m["list/col"] = ([@pl.col("k")], [@pl.col("y")], None)
  m["list/col-s"] = ([@pl.col("k")], [@pl.col("s")], None)
  m["list/col-n"] = ([@pl.col("k")], [@pl.col("n")], None)
  m["list/alias"] = ([@pl.col("k")], [@pl.col("y").alias("z")], None)
  m["list/cum_sum"] = ([@pl.col("k")], [@pl.col("y").cum_sum()], None)
  m["list/shift"] = ([@pl.col("k")], [@pl.col("y").shift(n=1)], None)
  m["list/rank"] = (
    [@pl.col("k")],
    [@pl.col("y").rank(method_=@pl.RankMethod::Average)],
    None,
  )
  m["list/reverse"] = ([@pl.col("k")], [@pl.col("y").reverse()], None)
  m["list/plus-1"] = ([@pl.col("k")], [@pl.col("y") + @pl.lit_int(1L)], None)
  m["list/plus-agg"] = (
    [@pl.col("k")],
    [@pl.col("y") + @pl.col("y").sum()],
    None,
  )
  m["list/agg-plus"] = (
    [@pl.col("k")],
    [@pl.col("y").sum() + @pl.col("y")],
    None,
  )
  m["list/lit-plus-col"] = (
    [@pl.col("k")],
    [@pl.lit_int(1L) + @pl.col("y")],
    None,
  )
  m["list/is_null"] = ([@pl.col("k")], [@pl.col("i32").is_null()], None)
  m["list/abs"] = ([@pl.col("k")], [@pl.col("i32").abs()], None)
  m["list/cast"] = (
    [@pl.col("k")],
    [@pl.col("f64").cast(@pl.DataType::Int64, strict=false)],
    None,
  )
  m["list/fill_null"] = (
    [@pl.col("k")],
    [@pl.col("i32").fill_null(@pl.lit_int(0L))],
    None,
  )
  m["list/when-col"] = (
    [@pl.col("k")],
    [
      @pl.when(@pl.col("y").gt(@pl.lit_int(50L)))
      .then(@pl.col("y"))
      .otherwise(@pl.lit_int(0L)),
    ],
    None,
  )
  m["list/when-mix"] = (
    [@pl.col("k")],
    [
      @pl.when(@pl.col("y").sum().gt(@pl.lit_int(100L)))
      .then(@pl.col("y"))
      .otherwise(@pl.lit_int(0L)),
    ],
    None,
  )
  m["list/when-cond"] = (
    [@pl.col("k")],
    [
      @pl.when(@pl.col("y").gt(@pl.lit_int(50L)))
      .then(@pl.col("y").sum())
      .otherwise(@pl.lit_int(0L)),
    ],
    None,
  )
  m["list/str"] = ([@pl.col("k")], [@pl.col("s").str().to_uppercase()], None)
  m["list/dt"] = ([@pl.col("k")], [@pl.col("d").dt().year()], None)
}

///|
fn golden_group_by_cases_16(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["list/is_in"] = ([@pl.col("k")], [@pl.col("i32").is_in(vs["i32"])], None)
  m["list/between"] = (
    [@pl.col("k")],
    [
      @pl.col("y").between(
        @pl.lit_int(1L),
        @pl.lit_int(50L),
        closed=@pl.ClosedInterval::Both,
      ),
    ],
    None,
  )
  m["list/neg"] = ([@pl.col("k")], [-@pl.col("y")], None)
  m["list/not"] = ([@pl.col("k")], [@pl.col("b").not_()], None)
  m["list/sum-of-col-plus"] = (
    [@pl.col("k")],
    [@pl.col("y").sum() + (@pl.col("y") + @pl.lit_int(1L))],
    None,
  )
  m["list/is_in-scalar"] = (
    [@pl.col("k")],
    [@pl.col("i32").first().is_in(vs["i32"])],
    None,
  )
  m["list/is_in-sum"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().is_in(vs["i64"])],
    None,
  )
  m["list/is_in-lit"] = (
    [@pl.col("k")],
    [@pl.lit_int(1L).is_in(vs["i64"])],
    None,
  )
  m["list/two"] = ([@pl.col("k")], [@pl.col("y").sum(), @pl.col("x")], None)
  m["list/first-bad-second"] = (
    [@pl.col("k")],
    [@pl.col("x"), @pl.col("y").sum().alias("s")],
    None,
  )
  m["list/all"] = ([@pl.col("k")], [@pl.all()], None)
  m["list/cols"] = ([@pl.col("k")], [@pl.cols(["i32", "i64"])], None)
  m["list/e"] = ([@pl.col("k")], [@pl.col("y")], None)
  m["list/e-cum"] = ([@pl.col("k")], [@pl.col("y").cum_sum()], None)
  m["list/e-plus-agg"] = (
    [@pl.col("k")],
    [@pl.col("y") + @pl.col("y").sum()],
    None,
  )
  m["sel/all-sum"] = ([@pl.col("k")], [@pl.all().sum()], None)
  m["sel/all-sum-key-i32"] = ([@pl.col("i32")], [@pl.all().sum()], None)
  m["sel/all-sum-key-expr"] = (
    [@pl.col("k") % @pl.lit_int(2L)],
    [@pl.all().sum()],
    None,
  )
  m["sel/all-sum-key-alias"] = (
    [@pl.col("k").alias("kk")],
    [@pl.all().sum()],
    None,
  )
  m["sel/all-sum-two-keys"] = (
    [@pl.col("k"), @pl.col("i32")],
    [@pl.all().sum()],
    None,
  )
  m["sel/all-sum-key-lit"] = ([@pl.lit_int(1L)], [@pl.all().sum()], None)
  m["sel/all-sum-no-key"] = ([], [@pl.all().sum()], None)
  m["sel/all-mean-e"] = ([@pl.col("k")], [@pl.all().mean()], None)
  m["sel/all-len"] = ([@pl.col("k")], [@pl.all().len()], None)
  m["sel/all-alias"] = ([@pl.col("k")], [@pl.all().sum().alias("x")], None)
  m["sel/all-first-str"] = ([@pl.col("k")], [@pl.all().first()], None)
  m["sel/all-sum-str"] = ([@pl.col("k")], [@pl.all().sum()], None)
  m["sel/all-plus"] = (
    [@pl.col("k")],
    [@pl.all().sum() + @pl.lit_int(1L)],
    None,
  )
  m["sel/all-sum-plus-all"] = (
    [@pl.col("k")],
    [@pl.all().sum() + @pl.all().count()],
    None,
  )
  m["sel/cols-sum"] = ([@pl.col("k")], [@pl.cols(["i32", "i64"]).sum()], None)
  m["sel/cols-with-key"] = (
    [@pl.col("k")],
    [@pl.cols(["k", "i32"]).sum()],
    None,
  )
  m["sel/cols-missing"] = (
    [@pl.col("k")],
    [@pl.cols(["i32", "zz"]).sum()],
    None,
  )
  m["sel/cols-and-col"] = (
    [@pl.col("k")],
    [@pl.cols(["i32", "i64"]).sum(), @pl.col("f64").mean()],
    None,
  )
  m["sel/cols-empty"] = ([@pl.col("k")], [@pl.cols([]).sum()], None)
  m["sel/cols-width"] = (
    [@pl.col("k")],
    [@pl.cols(["i32", "i64"]).sum() + @pl.cols(["f32", "f64", "i32"]).sum()],
    None,
  )
  m["sel/cols-pair"] = (
    [@pl.col("k")],
    [@pl.cols(["i32", "i64"]).sum() + @pl.cols(["f32", "f64"]).sum()],
    None,
  )
  m["sel/cols-dup"] = (
    [@pl.col("k")],
    [@pl.cols(["i32", "i64"]).sum(), @pl.cols(["i32"]).min()],
    None,
  )
  m["name/key-vs-agg"] = ([@pl.col("k")], [@pl.col("k").sum()], None)
  m["name/key-vs-col"] = ([@pl.col("k")], [@pl.col("k")], None)
  m["name/key-vs-alias"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().alias("k")],
    None,
  )
}

///|
fn golden_group_by_cases_17(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["name/key-vs-len"] = ([@pl.col("k")], [@pl.len().alias("k")], None)
  m["name/key-vs-lit"] = ([@pl.col("k")], [@pl.lit_int(1L).alias("k")], None)
  m["name/key-alias-vs-agg"] = (
    [@pl.col("i32").alias("k")],
    [@pl.col("k").sum()],
    None,
  )
  m["name/key-expr-vs-agg"] = (
    [@pl.col("k") % @pl.lit_int(2L)],
    [@pl.col("k").sum()],
    None,
  )
  m["name/two-aggs"] = (
    [@pl.col("k")],
    [@pl.col("y").sum(), @pl.col("y").mean()],
    None,
  )
  m["name/two-aliases"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().alias("a"), @pl.col("y").mean().alias("a")],
    None,
  )
  m["name/lit-lit"] = ([@pl.col("k")], [@pl.lit_int(1L), @pl.lit_int(2L)], None)
  m["name/len-len"] = ([@pl.col("k")], [@pl.len(), @pl.len()], None)
  m["name/len-vs-col"] = (
    [@pl.col("k")],
    [@pl.len(), @pl.col("y").sum().alias("len")],
    None,
  )
  m["name/alias-of-key"] = (
    [@pl.col("k")],
    [@pl.col("y").sum().alias("y")],
    None,
  )
  m["name/key-named-len"] = ([@pl.col("k").alias("len")], [@pl.len()], None)
  m["name/three-same"] = (
    [@pl.col("k")],
    [@pl.col("y").sum(), @pl.col("y").min(), @pl.col("y").max()],
    None,
  )
  m["name/empty-alias"] = ([@pl.col("k")], [@pl.col("y").sum().alias("")], None)
  m["name/empty-key-alias"] = ([@pl.col("k").alias("")], [@pl.len()], None)
  m["err/missing-agg"] = ([@pl.col("k")], [@pl.col("zz").sum()], None)
  m["err/missing-agg-z0"] = ([@pl.col("k")], [@pl.col("zz").sum()], None)
  m["err/missing-both"] = ([@pl.col("zz")], [@pl.col("zz2").sum()], None)
  m["err/missing-second"] = (
    [@pl.col("k")],
    [@pl.col("y").sum(), @pl.col("zz").sum()],
    None,
  )
  m["err/missing-vs-dup"] = (
    [@pl.col("k")],
    [@pl.col("y").sum(), @pl.col("y").mean(), @pl.col("zz").sum()],
    None,
  )
  m["err/dup-vs-missing"] = (
    [@pl.col("k")],
    [@pl.col("k").sum(), @pl.col("zz").sum()],
    None,
  )
  m["err/missing-vs-type"] = (
    [@pl.col("k")],
    [@pl.col("s").sum(), @pl.col("zz").sum()],
    None,
  )
  m["err/type-vs-missing"] = (
    [@pl.col("k")],
    [@pl.col("zz").sum(), @pl.col("s").sum()],
    None,
  )
  m["err/type-vs-dup"] = (
    [@pl.col("k")],
    [@pl.col("s").sum(), @pl.col("s").min()],
    None,
  )
  m["err/type-vs-key-dup"] = (
    [@pl.col("k")],
    [@pl.col("s").sum(), @pl.col("k").sum()],
    None,
  )
  m["err/type-vs-list"] = (
    [@pl.col("k")],
    [@pl.col("s") + @pl.lit_int(1L)],
    None,
  )
  m["err/list-vs-type"] = (
    [@pl.col("k")],
    [@pl.col("x"), @pl.col("s").sum()],
    None,
  )
  m["err/list-vs-dup"] = (
    [@pl.col("k")],
    [@pl.col("y"), @pl.col("y").sum()],
    None,
  )
  m["err/list-vs-key-dup"] = (
    [@pl.col("k")],
    [@pl.col("x"), @pl.col("k").sum()],
    None,
  )
  m["err/list-vs-missing"] = (
    [@pl.col("k")],
    [@pl.col("y"), @pl.col("zz").sum()],
    None,
  )
  m["err/missing-vs-list"] = (
    [@pl.col("k")],
    [@pl.col("zz").sum(), @pl.col("y")],
    None,
  )
  m["err/type-1"] = ([@pl.col("k")], [@pl.col("s").sum()], None)
  m["err/type-2"] = ([@pl.col("k")], [@pl.col("s").mean()], None)
  m["err/type-date-sum"] = ([@pl.col("k")], [@pl.col("d").sum()], None)
  m["err/type-2-aggs"] = (
    [@pl.col("k")],
    [@pl.col("s").sum(), @pl.col("d").sum().alias("dd")],
    None,
  )
  m["err/type-late"] = (
    [@pl.col("k")],
    [@pl.col("y").sum(), @pl.col("s").sum().alias("ss")],
    None,
  )
  m["err/type-in-expr"] = (
    [@pl.col("k")],
    [(@pl.col("s") + @pl.lit_int(1L)).sum()],
    None,
  )
  m["err/type-nested"] = (
    [@pl.col("k")],
    [@pl.col("s").sum() + @pl.lit_int(1L)],
    None,
  )
  m["err/key-missing-vs-agg-type"] = (
    [@pl.col("zz")],
    [@pl.col("s").sum()],
    None,
  )
  m["err/key-type-vs-agg-missing"] = (
    [@pl.col("k") + @pl.col("s")],
    [@pl.col("zz").sum()],
    None,
  )
  m["err/key-dup-vs-agg-missing"] = (
    [@pl.col("k"), @pl.col("k")],
    [@pl.col("zz").sum()],
    None,
  )
}

///|
fn golden_group_by_cases_18(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["err/key-dup-vs-key-type"] = (
    [@pl.col("k"), @pl.col("k"), @pl.col("k") + @pl.col("s")],
    [@pl.len()],
    None,
  )
  m["err/key-dup-vs-agg-type"] = (
    [@pl.col("k"), @pl.col("k")],
    [@pl.col("s").sum()],
    None,
  )
  m["err/key-type-vs-key-missing"] = (
    [@pl.col("k") + @pl.col("s"), @pl.col("zz")],
    [@pl.len()],
    None,
  )
  m["err/key-missing-vs-key-type"] = (
    [@pl.col("zz"), @pl.col("k") + @pl.col("s")],
    [@pl.len()],
    None,
  )
  m["err/e-type"] = ([@pl.col("k")], [@pl.col("s").sum()], None)
  m["err/e-list-type"] = (
    [@pl.col("k")],
    [@pl.col("s") + @pl.lit_int(1L)],
    None,
  )
  m["err/e-missing"] = ([@pl.col("k")], [@pl.col("zz").sum()], None)
  m["len/key/i32"] = ([@pl.col("i32")], [], None)
  m["len/key/i64"] = ([@pl.col("i64")], [], None)
  m["len/key/f32"] = ([@pl.col("f32")], [], None)
  m["len/key/f64"] = ([@pl.col("f64")], [], None)
  m["len/key/s"] = ([@pl.col("s")], [], None)
  m["len/key/b"] = ([@pl.col("b")], [], None)
  m["len/key/d"] = ([@pl.col("d")], [], None)
  m["len/key/dt"] = ([@pl.col("dt")], [], None)
  m["len/key/n"] = ([@pl.col("n")], [], None)
  m["len/default"] = ([@pl.col("k")], [], None)
  m["len/name"] = ([@pl.col("k")], [], Some("n"))
  m["len/name-empty"] = ([@pl.col("k")], [], Some(""))
  m["len/name-key"] = ([@pl.col("k")], [], Some("k"))
  m["len/two-keys"] = ([@pl.col("i32"), @pl.col("s")], [], None)
  m["len/expr-key"] = ([@pl.col("k") % @pl.lit_int(2L)], [], None)
  m["len/expr-key-name"] = ([@pl.col("k") % @pl.lit_int(2L)], [], Some("k"))
  m["len/lit-key"] = ([@pl.lit_int(1L)], [], None)
  m["len/none"] = ([], [], None)
  m["len/none/e"] = ([], [], None)
  m["len/none/z0"] = ([], [], None)
  m["len/e"] = ([@pl.col("k")], [], None)
  m["len/e-name"] = ([@pl.col("k")], [], Some("n"))
  m["len/missing"] = ([@pl.col("zz")], [], None)
  m["len/dup-keys"] = ([@pl.col("k"), @pl.col("k")], [], None)
  m["len/type-error"] = ([@pl.col("k") + @pl.col("s")], [], None)
  m["len/cols"] = ([@pl.cols(["i32", "b"])], [], None)
  m["len/big"] = ([@pl.col("k")], [], None)
  m["inf/sum/x"] = ([@pl.col("k")], [@pl.col("x").sum()], None)
  m["inf/mean/x"] = ([@pl.col("k")], [@pl.col("x").mean()], None)
  m["inf/min/x"] = ([@pl.col("k")], [@pl.col("x").min()], None)
  m["inf/max/x"] = ([@pl.col("k")], [@pl.col("x").max()], None)
  m["inf/first/x"] = ([@pl.col("k")], [@pl.col("x").first()], None)
  m["inf/last/x"] = ([@pl.col("k")], [@pl.col("x").last()], None)
}

///|
fn golden_group_by_cases_19(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["inf/product/x"] = ([@pl.col("k")], [@pl.col("x").product()], None)
  m["inf/std1/x"] = ([@pl.col("k")], [@pl.col("x").std(ddof=1)], None)
  m["inf/var1/x"] = ([@pl.col("k")], [@pl.col("x").var_(ddof=1)], None)
  m["inf/std0/x"] = ([@pl.col("k")], [@pl.col("x").std(ddof=0)], None)
  m["inf/var0/x"] = ([@pl.col("k")], [@pl.col("x").var_(ddof=0)], None)
  m["inf/times-one/x"] = (
    [@pl.col("k")],
    [(@pl.col("x") * @pl.lit_float(1.0)).sum()],
    None,
  )
  m["inf/dev-sum/x"] = (
    [@pl.col("k")],
    [(@pl.col("x") - @pl.col("x").mean()).sum()],
    None,
  )
  m["inf/fill-sum/x"] = (
    [@pl.col("k")],
    [@pl.col("x").fill_null(@pl.lit_float(0.0)).sum()],
    None,
  )
  m["inf/sum-plus/x"] = (
    [@pl.col("k")],
    [@pl.col("x").sum() + @pl.lit_float(1.0)],
    None,
  )
  m["inf/sum/y"] = ([@pl.col("k")], [@pl.col("y").sum()], None)
  m["inf/mean/y"] = ([@pl.col("k")], [@pl.col("y").mean()], None)
  m["inf/min/y"] = ([@pl.col("k")], [@pl.col("y").min()], None)
  m["inf/max/y"] = ([@pl.col("k")], [@pl.col("y").max()], None)
  m["inf/first/y"] = ([@pl.col("k")], [@pl.col("y").first()], None)
  m["inf/last/y"] = ([@pl.col("k")], [@pl.col("y").last()], None)
  m["inf/product/y"] = ([@pl.col("k")], [@pl.col("y").product()], None)
  m["inf/std1/y"] = ([@pl.col("k")], [@pl.col("y").std(ddof=1)], None)
  m["inf/var1/y"] = ([@pl.col("k")], [@pl.col("y").var_(ddof=1)], None)
  m["inf/std0/y"] = ([@pl.col("k")], [@pl.col("y").std(ddof=0)], None)
  m["inf/var0/y"] = ([@pl.col("k")], [@pl.col("y").var_(ddof=0)], None)
  m["inf/times-one/y"] = (
    [@pl.col("k")],
    [(@pl.col("y") * @pl.lit_float(1.0)).sum()],
    None,
  )
  m["inf/dev-sum/y"] = (
    [@pl.col("k")],
    [(@pl.col("y") - @pl.col("y").mean()).sum()],
    None,
  )
  m["inf/fill-sum/y"] = (
    [@pl.col("k")],
    [@pl.col("y").fill_null(@pl.lit_float(0.0)).sum()],
    None,
  )
  m["inf/sum-plus/y"] = (
    [@pl.col("k")],
    [@pl.col("y").sum() + @pl.lit_float(1.0)],
    None,
  )
  m["inf/no-key"] = (
    [],
    [@pl.col("x").sum(), @pl.col("y").mean().alias("m")],
    None,
  )
  m["gl/sum-times-len"] = (
    [@pl.col("k")],
    [(@pl.col("group leaf 0") * @pl.len()).sum()],
    None,
  )
  m["gl/dev-sum"] = (
    [@pl.col("k")],
    [(@pl.col("group leaf 0") - @pl.col("group leaf 0").mean()).sum()],
    None,
  )
  m["gl/dev-sum-both"] = (
    [@pl.col("k")],
    [
      (@pl.col("group leaf 1") - @pl.col("group leaf 0").mean())
      .sum()
      .alias("a"),
      (@pl.col("group leaf 0") + (@pl.len() + @pl.col("group leaf 1").max()))
      .sum()
      .alias("b"),
    ],
    None,
  )
  m["gl/plain"] = (
    [@pl.col("k")],
    [@pl.col("group leaf 0").sum(), @pl.col("group leaf 1").sum()],
    None,
  )
  m["gl/leaf-add"] = (
    [@pl.col("k")],
    [@pl.col("group leaf 0").sum() + @pl.col("group leaf 1").max() * @pl.len()],
    None,
  )
  m["gl/key"] = (
    [@pl.col("group leaf 0")],
    [@pl.col("group leaf 1").sum()],
    None,
  )
  m["gl/cast-error"] = (
    [@pl.col("k")],
    [@pl.col("s").first().cast(@pl.DataType::Int64)],
    None,
  )
  m["gl/cast-error-two"] = (
    [@pl.col("k")],
    [
      @pl.col("s").first().cast(@pl.DataType::Int64) +
      @pl.col("group leaf 0").last(),
    ],
    None,
  )
  m["err2/and-then-unsupported"] = (
    [@pl.col("k")],
    [(@pl.col("i32") & @pl.col("b")).sum(), @pl.col("s").sum()],
    None,
  )
  m["err2/unsupported-then-and"] = (
    [@pl.col("k")],
    [@pl.col("s").sum(), (@pl.col("i32") & @pl.col("b")).sum()],
    None,
  )
  m["err2/add-then-unsupported"] = (
    [@pl.col("k")],
    [(@pl.col("s") + @pl.lit_int(1L)).sum(), @pl.col("s").sum()],
    None,
  )
  m["err2/unsupported-then-add"] = (
    [@pl.col("k")],
    [@pl.col("s").sum(), (@pl.col("s") + @pl.lit_int(1L)).sum()],
    None,
  )
  m["err2/key-and-then-unsupported"] = (
    [@pl.col("i32") & @pl.col("b")],
    [@pl.col("s").sum()],
    None,
  )
  m["err2/two-and"] = (
    [@pl.col("k")],
    [
      (@pl.col("i32") & @pl.col("b")).sum(),
      (@pl.col("i64") & @pl.col("b")).sum(),
    ],
    None,
  )
  m["gl/cast-error-value"] = (
    [@pl.col("k")],
    [@pl.col("sv").first().cast(@pl.DataType::Int64)],
    None,
  )
}

///|
fn golden_group_by_cases_20(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["gl/cast-error-value-two"] = (
    [@pl.col("k")],
    [
      @pl.col("sv").first().cast(@pl.DataType::Int64) +
      @pl.col("group leaf 0").max(),
    ],
    None,
  )
  m["err2/product-then-and"] = (
    [@pl.col("k")],
    [@pl.col("s").product(), (@pl.col("i32") & @pl.col("b")).sum()],
    None,
  )
  m["err2/and-then-product"] = (
    [@pl.col("k")],
    [(@pl.col("i32") & @pl.col("b")).sum(), @pl.col("s").product()],
    None,
  )
  m["err2/key-or-then-unsupported"] = (
    [@pl.col("f64") | @pl.col("i64")],
    [@pl.col("s").sum()],
    None,
  )
  m["err2/key-and-then-missing"] = (
    [@pl.col("i32") & @pl.col("b")],
    [@pl.col("zz").sum()],
    None,
  )
  m["err2/key-date-then-missing"] = (
    [@pl.col("d") + @pl.col("d")],
    [@pl.col("zz").sum()],
    None,
  )
  m["err2/key-missing-then-key-type"] = (
    [@pl.col("zz"), @pl.col("i32") & @pl.col("b")],
    [@pl.len()],
    None,
  )
  m["err2/and-then-add"] = (
    [@pl.col("k")],
    [
      (@pl.col("i32") & @pl.col("b")).sum(),
      (@pl.col("s") + @pl.lit_int(1L)).sum(),
    ],
    None,
  )
  m["first/zero-keys"] = ([@pl.col("k")], [@pl.col("v").sum()], None)
  m["first/zero-keys-len"] = ([@pl.col("k")], [@pl.len()], None)
  m["nest/sum-plus-sum"] = (
    [@pl.col("k")],
    [(@pl.col("y").sum() + @pl.lit_int(1L)).sum()],
    None,
  )
  m["nest/len-plus-sum"] = (
    [@pl.col("k")],
    [(@pl.len() + @pl.lit_int(1L)).sum()],
    None,
  )
  m["nest/len-plus-mean"] = (
    [@pl.col("k")],
    [(@pl.len() + @pl.col("y")).mean()],
    None,
  )
  m["nest/lit-sum"] = ([@pl.col("k")], [@pl.lit_int(5L).sum()], None)
}

///|
/// Every case id with its key expressions, aggregation expressions and the
/// `name` of a `GroupBy::len` case (`Some` only for the `len` cases that pass one).
fn golden_group_by_cases(
  vs : Map[String, @pl.Series],
) -> Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)] {
  let m : Map[String, (Array[@pl.Expr], Array[@pl.Expr], String?)] = Map([])
  golden_group_by_cases_0(m, vs)
  golden_group_by_cases_1(m, vs)
  golden_group_by_cases_2(m, vs)
  golden_group_by_cases_3(m, vs)
  golden_group_by_cases_4(m, vs)
  golden_group_by_cases_5(m, vs)
  golden_group_by_cases_6(m, vs)
  golden_group_by_cases_7(m, vs)
  golden_group_by_cases_8(m, vs)
  golden_group_by_cases_9(m, vs)
  golden_group_by_cases_10(m, vs)
  golden_group_by_cases_11(m, vs)
  golden_group_by_cases_12(m, vs)
  golden_group_by_cases_13(m, vs)
  golden_group_by_cases_14(m, vs)
  golden_group_by_cases_15(m, vs)
  golden_group_by_cases_16(m, vs)
  golden_group_by_cases_17(m, vs)
  golden_group_by_cases_18(m, vs)
  golden_group_by_cases_19(m, vs)
  golden_group_by_cases_20(m, vs)
  m
}
