// 由 docs/golden/scripts/expr_agg.py 生成，勿手改

///|
fn golden_expr_agg_cases_0(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/sum/i32"] = [@pl.col("i32").sum()]
  m["agg/sum/i64"] = [@pl.col("i64").sum()]
  m["agg/sum/f32"] = [@pl.col("f32").sum()]
  m["agg/sum/f64"] = [@pl.col("f64").sum()]
  m["agg/sum/s"] = [@pl.col("s").sum()]
  m["agg/sum/b"] = [@pl.col("b").sum()]
  m["agg/sum/d"] = [@pl.col("d").sum()]
  m["agg/sum/dt"] = [@pl.col("dt").sum()]
  m["agg/sum/n"] = [@pl.col("n").sum()]
  m["agg/mean/i32"] = [@pl.col("i32").mean()]
  m["agg/mean/i64"] = [@pl.col("i64").mean()]
  m["agg/mean/f32"] = [@pl.col("f32").mean()]
  m["agg/mean/f64"] = [@pl.col("f64").mean()]
  m["agg/mean/s"] = [@pl.col("s").mean()]
  m["agg/mean/b"] = [@pl.col("b").mean()]
  m["agg/mean/d"] = [@pl.col("d").mean()]
  m["agg/mean/dt"] = [@pl.col("dt").mean()]
  m["agg/mean/n"] = [@pl.col("n").mean()]
  m["agg/min/i32"] = [@pl.col("i32").min()]
  m["agg/min/i64"] = [@pl.col("i64").min()]
  m["agg/min/f32"] = [@pl.col("f32").min()]
  m["agg/min/f64"] = [@pl.col("f64").min()]
  m["agg/min/s"] = [@pl.col("s").min()]
  m["agg/min/b"] = [@pl.col("b").min()]
  m["agg/min/d"] = [@pl.col("d").min()]
  m["agg/min/dt"] = [@pl.col("dt").min()]
  m["agg/min/n"] = [@pl.col("n").min()]
  m["agg/max/i32"] = [@pl.col("i32").max()]
  m["agg/max/i64"] = [@pl.col("i64").max()]
  m["agg/max/f32"] = [@pl.col("f32").max()]
  m["agg/max/f64"] = [@pl.col("f64").max()]
  m["agg/max/s"] = [@pl.col("s").max()]
  m["agg/max/b"] = [@pl.col("b").max()]
  m["agg/max/d"] = [@pl.col("d").max()]
  m["agg/max/dt"] = [@pl.col("dt").max()]
  m["agg/max/n"] = [@pl.col("n").max()]
  m["agg/count/i32"] = [@pl.col("i32").count()]
  m["agg/count/i64"] = [@pl.col("i64").count()]
  m["agg/count/f32"] = [@pl.col("f32").count()]
  m["agg/count/f64"] = [@pl.col("f64").count()]
  m["agg/count/s"] = [@pl.col("s").count()]
  m["agg/count/b"] = [@pl.col("b").count()]
  m["agg/count/d"] = [@pl.col("d").count()]
  m["agg/count/dt"] = [@pl.col("dt").count()]
  m["agg/count/n"] = [@pl.col("n").count()]
  m["agg/len/i32"] = [@pl.col("i32").len()]
  m["agg/len/i64"] = [@pl.col("i64").len()]
  m["agg/len/f32"] = [@pl.col("f32").len()]
  m["agg/len/f64"] = [@pl.col("f64").len()]
  m["agg/len/s"] = [@pl.col("s").len()]
  m["agg/len/b"] = [@pl.col("b").len()]
  m["agg/len/d"] = [@pl.col("d").len()]
  m["agg/len/dt"] = [@pl.col("dt").len()]
  m["agg/len/n"] = [@pl.col("n").len()]
  m["agg/n_unique/i32"] = [@pl.col("i32").n_unique()]
  m["agg/n_unique/i64"] = [@pl.col("i64").n_unique()]
  m["agg/n_unique/f32"] = [@pl.col("f32").n_unique()]
  m["agg/n_unique/f64"] = [@pl.col("f64").n_unique()]
  m["agg/n_unique/s"] = [@pl.col("s").n_unique()]
  m["agg/n_unique/b"] = [@pl.col("b").n_unique()]
}

///|
fn golden_expr_agg_cases_1(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/n_unique/d"] = [@pl.col("d").n_unique()]
  m["agg/n_unique/dt"] = [@pl.col("dt").n_unique()]
  m["agg/n_unique/n"] = [@pl.col("n").n_unique()]
  m["agg/first/i32"] = [@pl.col("i32").first()]
  m["agg/first/i64"] = [@pl.col("i64").first()]
  m["agg/first/f32"] = [@pl.col("f32").first()]
  m["agg/first/f64"] = [@pl.col("f64").first()]
  m["agg/first/s"] = [@pl.col("s").first()]
  m["agg/first/b"] = [@pl.col("b").first()]
  m["agg/first/d"] = [@pl.col("d").first()]
  m["agg/first/dt"] = [@pl.col("dt").first()]
  m["agg/first/n"] = [@pl.col("n").first()]
  m["agg/last/i32"] = [@pl.col("i32").last()]
  m["agg/last/i64"] = [@pl.col("i64").last()]
  m["agg/last/f32"] = [@pl.col("f32").last()]
  m["agg/last/f64"] = [@pl.col("f64").last()]
  m["agg/last/s"] = [@pl.col("s").last()]
  m["agg/last/b"] = [@pl.col("b").last()]
  m["agg/last/d"] = [@pl.col("d").last()]
  m["agg/last/dt"] = [@pl.col("dt").last()]
  m["agg/last/n"] = [@pl.col("n").last()]
  m["agg/median/i32"] = [@pl.col("i32").median()]
  m["agg/median/i64"] = [@pl.col("i64").median()]
  m["agg/median/f32"] = [@pl.col("f32").median()]
  m["agg/median/f64"] = [@pl.col("f64").median()]
  m["agg/median/s"] = [@pl.col("s").median()]
  m["agg/median/b"] = [@pl.col("b").median()]
  m["agg/median/d"] = [@pl.col("d").median()]
  m["agg/median/dt"] = [@pl.col("dt").median()]
  m["agg/median/n"] = [@pl.col("n").median()]
  m["agg/product/i32"] = [@pl.col("i32").product()]
  m["agg/product/i64"] = [@pl.col("i64").product()]
  m["agg/product/f32"] = [@pl.col("f32").product()]
  m["agg/product/f64"] = [@pl.col("f64").product()]
  m["agg/product/s"] = [@pl.col("s").product()]
  m["agg/product/b"] = [@pl.col("b").product()]
  m["agg/product/d"] = [@pl.col("d").product()]
  m["agg/product/dt"] = [@pl.col("dt").product()]
  m["agg/product/n"] = [@pl.col("n").product()]
  m["agg/std0/i32"] = [@pl.col("i32").std(ddof=0)]
  m["agg/var0/i32"] = [@pl.col("i32").var_(ddof=0)]
  m["agg/std0/i64"] = [@pl.col("i64").std(ddof=0)]
  m["agg/var0/i64"] = [@pl.col("i64").var_(ddof=0)]
  m["agg/std0/f32"] = [@pl.col("f32").std(ddof=0)]
  m["agg/var0/f32"] = [@pl.col("f32").var_(ddof=0)]
  m["agg/std0/f64"] = [@pl.col("f64").std(ddof=0)]
  m["agg/var0/f64"] = [@pl.col("f64").var_(ddof=0)]
  m["agg/std0/s"] = [@pl.col("s").std(ddof=0)]
  m["agg/var0/s"] = [@pl.col("s").var_(ddof=0)]
  m["agg/std0/b"] = [@pl.col("b").std(ddof=0)]
  m["agg/var0/b"] = [@pl.col("b").var_(ddof=0)]
  m["agg/std0/d"] = [@pl.col("d").std(ddof=0)]
  m["agg/var0/d"] = [@pl.col("d").var_(ddof=0)]
  m["agg/std0/dt"] = [@pl.col("dt").std(ddof=0)]
  m["agg/var0/dt"] = [@pl.col("dt").var_(ddof=0)]
  m["agg/std0/n"] = [@pl.col("n").std(ddof=0)]
  m["agg/var0/n"] = [@pl.col("n").var_(ddof=0)]
  m["agg/std1/i32"] = [@pl.col("i32").std(ddof=1)]
  m["agg/var1/i32"] = [@pl.col("i32").var_(ddof=1)]
  m["agg/std1/i64"] = [@pl.col("i64").std(ddof=1)]
}

///|
fn golden_expr_agg_cases_2(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/var1/i64"] = [@pl.col("i64").var_(ddof=1)]
  m["agg/std1/f32"] = [@pl.col("f32").std(ddof=1)]
  m["agg/var1/f32"] = [@pl.col("f32").var_(ddof=1)]
  m["agg/std1/f64"] = [@pl.col("f64").std(ddof=1)]
  m["agg/var1/f64"] = [@pl.col("f64").var_(ddof=1)]
  m["agg/std1/s"] = [@pl.col("s").std(ddof=1)]
  m["agg/var1/s"] = [@pl.col("s").var_(ddof=1)]
  m["agg/std1/b"] = [@pl.col("b").std(ddof=1)]
  m["agg/var1/b"] = [@pl.col("b").var_(ddof=1)]
  m["agg/std1/d"] = [@pl.col("d").std(ddof=1)]
  m["agg/var1/d"] = [@pl.col("d").var_(ddof=1)]
  m["agg/std1/dt"] = [@pl.col("dt").std(ddof=1)]
  m["agg/var1/dt"] = [@pl.col("dt").var_(ddof=1)]
  m["agg/std1/n"] = [@pl.col("n").std(ddof=1)]
  m["agg/var1/n"] = [@pl.col("n").var_(ddof=1)]
  m["agg/std2/i32"] = [@pl.col("i32").std(ddof=2)]
  m["agg/var2/i32"] = [@pl.col("i32").var_(ddof=2)]
  m["agg/std2/i64"] = [@pl.col("i64").std(ddof=2)]
  m["agg/var2/i64"] = [@pl.col("i64").var_(ddof=2)]
  m["agg/std2/f32"] = [@pl.col("f32").std(ddof=2)]
  m["agg/var2/f32"] = [@pl.col("f32").var_(ddof=2)]
  m["agg/std2/f64"] = [@pl.col("f64").std(ddof=2)]
  m["agg/var2/f64"] = [@pl.col("f64").var_(ddof=2)]
  m["agg/std2/s"] = [@pl.col("s").std(ddof=2)]
  m["agg/var2/s"] = [@pl.col("s").var_(ddof=2)]
  m["agg/std2/b"] = [@pl.col("b").std(ddof=2)]
  m["agg/var2/b"] = [@pl.col("b").var_(ddof=2)]
  m["agg/std2/d"] = [@pl.col("d").std(ddof=2)]
  m["agg/var2/d"] = [@pl.col("d").var_(ddof=2)]
  m["agg/std2/dt"] = [@pl.col("dt").std(ddof=2)]
  m["agg/var2/dt"] = [@pl.col("dt").var_(ddof=2)]
  m["agg/std2/n"] = [@pl.col("n").std(ddof=2)]
  m["agg/var2/n"] = [@pl.col("n").var_(ddof=2)]
  m["agg/quantile/i32"] = [
    @pl.col("i32").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/i64"] = [
    @pl.col("i64").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/f32"] = [
    @pl.col("f32").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/f64"] = [
    @pl.col("f64").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/s"] = [
    @pl.col("s").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/b"] = [
    @pl.col("b").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/d"] = [
    @pl.col("d").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/dt"] = [
    @pl.col("dt").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/n"] = [
    @pl.col("n").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/sum/i32/e0"] = [@pl.col("i32").sum()]
  m["agg/sum/i64/e0"] = [@pl.col("i64").sum()]
  m["agg/sum/f32/e0"] = [@pl.col("f32").sum()]
  m["agg/sum/f64/e0"] = [@pl.col("f64").sum()]
  m["agg/sum/s/e0"] = [@pl.col("s").sum()]
  m["agg/sum/b/e0"] = [@pl.col("b").sum()]
  m["agg/sum/d/e0"] = [@pl.col("d").sum()]
  m["agg/sum/dt/e0"] = [@pl.col("dt").sum()]
  m["agg/sum/n/e0"] = [@pl.col("n").sum()]
  m["agg/mean/i32/e0"] = [@pl.col("i32").mean()]
  m["agg/mean/i64/e0"] = [@pl.col("i64").mean()]
  m["agg/mean/f32/e0"] = [@pl.col("f32").mean()]
  m["agg/mean/f64/e0"] = [@pl.col("f64").mean()]
  m["agg/mean/s/e0"] = [@pl.col("s").mean()]
  m["agg/mean/b/e0"] = [@pl.col("b").mean()]
  m["agg/mean/d/e0"] = [@pl.col("d").mean()]
  m["agg/mean/dt/e0"] = [@pl.col("dt").mean()]
  m["agg/mean/n/e0"] = [@pl.col("n").mean()]
}

///|
fn golden_expr_agg_cases_3(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/min/i32/e0"] = [@pl.col("i32").min()]
  m["agg/min/i64/e0"] = [@pl.col("i64").min()]
  m["agg/min/f32/e0"] = [@pl.col("f32").min()]
  m["agg/min/f64/e0"] = [@pl.col("f64").min()]
  m["agg/min/s/e0"] = [@pl.col("s").min()]
  m["agg/min/b/e0"] = [@pl.col("b").min()]
  m["agg/min/d/e0"] = [@pl.col("d").min()]
  m["agg/min/dt/e0"] = [@pl.col("dt").min()]
  m["agg/min/n/e0"] = [@pl.col("n").min()]
  m["agg/max/i32/e0"] = [@pl.col("i32").max()]
  m["agg/max/i64/e0"] = [@pl.col("i64").max()]
  m["agg/max/f32/e0"] = [@pl.col("f32").max()]
  m["agg/max/f64/e0"] = [@pl.col("f64").max()]
  m["agg/max/s/e0"] = [@pl.col("s").max()]
  m["agg/max/b/e0"] = [@pl.col("b").max()]
  m["agg/max/d/e0"] = [@pl.col("d").max()]
  m["agg/max/dt/e0"] = [@pl.col("dt").max()]
  m["agg/max/n/e0"] = [@pl.col("n").max()]
  m["agg/count/i32/e0"] = [@pl.col("i32").count()]
  m["agg/count/i64/e0"] = [@pl.col("i64").count()]
  m["agg/count/f32/e0"] = [@pl.col("f32").count()]
  m["agg/count/f64/e0"] = [@pl.col("f64").count()]
  m["agg/count/s/e0"] = [@pl.col("s").count()]
  m["agg/count/b/e0"] = [@pl.col("b").count()]
  m["agg/count/d/e0"] = [@pl.col("d").count()]
  m["agg/count/dt/e0"] = [@pl.col("dt").count()]
  m["agg/count/n/e0"] = [@pl.col("n").count()]
  m["agg/len/i32/e0"] = [@pl.col("i32").len()]
  m["agg/len/i64/e0"] = [@pl.col("i64").len()]
  m["agg/len/f32/e0"] = [@pl.col("f32").len()]
  m["agg/len/f64/e0"] = [@pl.col("f64").len()]
  m["agg/len/s/e0"] = [@pl.col("s").len()]
  m["agg/len/b/e0"] = [@pl.col("b").len()]
  m["agg/len/d/e0"] = [@pl.col("d").len()]
  m["agg/len/dt/e0"] = [@pl.col("dt").len()]
  m["agg/len/n/e0"] = [@pl.col("n").len()]
  m["agg/n_unique/i32/e0"] = [@pl.col("i32").n_unique()]
  m["agg/n_unique/i64/e0"] = [@pl.col("i64").n_unique()]
  m["agg/n_unique/f32/e0"] = [@pl.col("f32").n_unique()]
  m["agg/n_unique/f64/e0"] = [@pl.col("f64").n_unique()]
  m["agg/n_unique/s/e0"] = [@pl.col("s").n_unique()]
  m["agg/n_unique/b/e0"] = [@pl.col("b").n_unique()]
  m["agg/n_unique/d/e0"] = [@pl.col("d").n_unique()]
  m["agg/n_unique/dt/e0"] = [@pl.col("dt").n_unique()]
  m["agg/n_unique/n/e0"] = [@pl.col("n").n_unique()]
  m["agg/first/i32/e0"] = [@pl.col("i32").first()]
  m["agg/first/i64/e0"] = [@pl.col("i64").first()]
  m["agg/first/f32/e0"] = [@pl.col("f32").first()]
  m["agg/first/f64/e0"] = [@pl.col("f64").first()]
  m["agg/first/s/e0"] = [@pl.col("s").first()]
  m["agg/first/b/e0"] = [@pl.col("b").first()]
  m["agg/first/d/e0"] = [@pl.col("d").first()]
  m["agg/first/dt/e0"] = [@pl.col("dt").first()]
  m["agg/first/n/e0"] = [@pl.col("n").first()]
  m["agg/last/i32/e0"] = [@pl.col("i32").last()]
  m["agg/last/i64/e0"] = [@pl.col("i64").last()]
  m["agg/last/f32/e0"] = [@pl.col("f32").last()]
  m["agg/last/f64/e0"] = [@pl.col("f64").last()]
  m["agg/last/s/e0"] = [@pl.col("s").last()]
  m["agg/last/b/e0"] = [@pl.col("b").last()]
}

///|
fn golden_expr_agg_cases_4(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/last/d/e0"] = [@pl.col("d").last()]
  m["agg/last/dt/e0"] = [@pl.col("dt").last()]
  m["agg/last/n/e0"] = [@pl.col("n").last()]
  m["agg/median/i32/e0"] = [@pl.col("i32").median()]
  m["agg/median/i64/e0"] = [@pl.col("i64").median()]
  m["agg/median/f32/e0"] = [@pl.col("f32").median()]
  m["agg/median/f64/e0"] = [@pl.col("f64").median()]
  m["agg/median/s/e0"] = [@pl.col("s").median()]
  m["agg/median/b/e0"] = [@pl.col("b").median()]
  m["agg/median/d/e0"] = [@pl.col("d").median()]
  m["agg/median/dt/e0"] = [@pl.col("dt").median()]
  m["agg/median/n/e0"] = [@pl.col("n").median()]
  m["agg/product/i32/e0"] = [@pl.col("i32").product()]
  m["agg/product/i64/e0"] = [@pl.col("i64").product()]
  m["agg/product/f32/e0"] = [@pl.col("f32").product()]
  m["agg/product/f64/e0"] = [@pl.col("f64").product()]
  m["agg/product/s/e0"] = [@pl.col("s").product()]
  m["agg/product/b/e0"] = [@pl.col("b").product()]
  m["agg/product/d/e0"] = [@pl.col("d").product()]
  m["agg/product/dt/e0"] = [@pl.col("dt").product()]
  m["agg/product/n/e0"] = [@pl.col("n").product()]
  m["agg/std0/i32/e0"] = [@pl.col("i32").std(ddof=0)]
  m["agg/var0/i32/e0"] = [@pl.col("i32").var_(ddof=0)]
  m["agg/std0/i64/e0"] = [@pl.col("i64").std(ddof=0)]
  m["agg/var0/i64/e0"] = [@pl.col("i64").var_(ddof=0)]
  m["agg/std0/f32/e0"] = [@pl.col("f32").std(ddof=0)]
  m["agg/var0/f32/e0"] = [@pl.col("f32").var_(ddof=0)]
  m["agg/std0/f64/e0"] = [@pl.col("f64").std(ddof=0)]
  m["agg/var0/f64/e0"] = [@pl.col("f64").var_(ddof=0)]
  m["agg/std0/s/e0"] = [@pl.col("s").std(ddof=0)]
  m["agg/var0/s/e0"] = [@pl.col("s").var_(ddof=0)]
  m["agg/std0/b/e0"] = [@pl.col("b").std(ddof=0)]
  m["agg/var0/b/e0"] = [@pl.col("b").var_(ddof=0)]
  m["agg/std0/d/e0"] = [@pl.col("d").std(ddof=0)]
  m["agg/var0/d/e0"] = [@pl.col("d").var_(ddof=0)]
  m["agg/std0/dt/e0"] = [@pl.col("dt").std(ddof=0)]
  m["agg/var0/dt/e0"] = [@pl.col("dt").var_(ddof=0)]
  m["agg/std0/n/e0"] = [@pl.col("n").std(ddof=0)]
  m["agg/var0/n/e0"] = [@pl.col("n").var_(ddof=0)]
  m["agg/std1/i32/e0"] = [@pl.col("i32").std(ddof=1)]
  m["agg/var1/i32/e0"] = [@pl.col("i32").var_(ddof=1)]
  m["agg/std1/i64/e0"] = [@pl.col("i64").std(ddof=1)]
  m["agg/var1/i64/e0"] = [@pl.col("i64").var_(ddof=1)]
  m["agg/std1/f32/e0"] = [@pl.col("f32").std(ddof=1)]
  m["agg/var1/f32/e0"] = [@pl.col("f32").var_(ddof=1)]
  m["agg/std1/f64/e0"] = [@pl.col("f64").std(ddof=1)]
  m["agg/var1/f64/e0"] = [@pl.col("f64").var_(ddof=1)]
  m["agg/std1/s/e0"] = [@pl.col("s").std(ddof=1)]
  m["agg/var1/s/e0"] = [@pl.col("s").var_(ddof=1)]
  m["agg/std1/b/e0"] = [@pl.col("b").std(ddof=1)]
  m["agg/var1/b/e0"] = [@pl.col("b").var_(ddof=1)]
  m["agg/std1/d/e0"] = [@pl.col("d").std(ddof=1)]
  m["agg/var1/d/e0"] = [@pl.col("d").var_(ddof=1)]
  m["agg/std1/dt/e0"] = [@pl.col("dt").std(ddof=1)]
  m["agg/var1/dt/e0"] = [@pl.col("dt").var_(ddof=1)]
  m["agg/std1/n/e0"] = [@pl.col("n").std(ddof=1)]
  m["agg/var1/n/e0"] = [@pl.col("n").var_(ddof=1)]
  m["agg/quantile/i32/e0"] = [
    @pl.col("i32").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/i64/e0"] = [
    @pl.col("i64").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/f32/e0"] = [
    @pl.col("f32").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
}

///|
fn golden_expr_agg_cases_5(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/quantile/f64/e0"] = [
    @pl.col("f64").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/s/e0"] = [
    @pl.col("s").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/b/e0"] = [
    @pl.col("b").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/dt/e0"] = [
    @pl.col("dt").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile/n/e0"] = [
    @pl.col("n").quantile(0.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/0.0/i32"] = [
    @pl.col("i32").quantile(0.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/0.25/i32"] = [
    @pl.col("i32").quantile(0.25, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/0.9/i32"] = [
    @pl.col("i32").quantile(0.9, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/1.0/i32"] = [
    @pl.col("i32").quantile(1.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/0.0/f64"] = [
    @pl.col("f64").quantile(0.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/0.25/f64"] = [
    @pl.col("f64").quantile(0.25, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/0.9/f64"] = [
    @pl.col("f64").quantile(0.9, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/1.0/f64"] = [
    @pl.col("f64").quantile(1.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/0.0/d"] = [
    @pl.col("d").quantile(0.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/0.25/d"] = [
    @pl.col("d").quantile(0.25, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/0.9/d"] = [
    @pl.col("d").quantile(0.9, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-nearest/1.0/d"] = [
    @pl.col("d").quantile(1.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-higher/0.0/i32"] = [
    @pl.col("i32").quantile(0.0, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-higher/0.25/i32"] = [
    @pl.col("i32").quantile(0.25, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-higher/0.9/i32"] = [
    @pl.col("i32").quantile(0.9, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-higher/1.0/i32"] = [
    @pl.col("i32").quantile(1.0, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-higher/0.0/f64"] = [
    @pl.col("f64").quantile(0.0, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-higher/0.25/f64"] = [
    @pl.col("f64").quantile(0.25, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-higher/0.9/f64"] = [
    @pl.col("f64").quantile(0.9, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-higher/1.0/f64"] = [
    @pl.col("f64").quantile(1.0, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-higher/0.0/d"] = [
    @pl.col("d").quantile(0.0, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-higher/0.25/d"] = [
    @pl.col("d").quantile(0.25, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-higher/0.9/d"] = [
    @pl.col("d").quantile(0.9, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-higher/1.0/d"] = [
    @pl.col("d").quantile(1.0, interpolation=@pl.QuantileMethod::Higher),
  ]
  m["agg/quantile-lower/0.0/i32"] = [
    @pl.col("i32").quantile(0.0, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-lower/0.25/i32"] = [
    @pl.col("i32").quantile(0.25, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-lower/0.9/i32"] = [
    @pl.col("i32").quantile(0.9, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-lower/1.0/i32"] = [
    @pl.col("i32").quantile(1.0, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-lower/0.0/f64"] = [
    @pl.col("f64").quantile(0.0, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-lower/0.25/f64"] = [
    @pl.col("f64").quantile(0.25, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-lower/0.9/f64"] = [
    @pl.col("f64").quantile(0.9, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-lower/1.0/f64"] = [
    @pl.col("f64").quantile(1.0, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-lower/0.0/d"] = [
    @pl.col("d").quantile(0.0, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-lower/0.25/d"] = [
    @pl.col("d").quantile(0.25, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-lower/0.9/d"] = [
    @pl.col("d").quantile(0.9, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-lower/1.0/d"] = [
    @pl.col("d").quantile(1.0, interpolation=@pl.QuantileMethod::Lower),
  ]
  m["agg/quantile-midpoint/0.0/i32"] = [
    @pl.col("i32").quantile(0.0, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-midpoint/0.25/i32"] = [
    @pl.col("i32").quantile(0.25, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-midpoint/0.9/i32"] = [
    @pl.col("i32").quantile(0.9, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-midpoint/1.0/i32"] = [
    @pl.col("i32").quantile(1.0, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-midpoint/0.0/f64"] = [
    @pl.col("f64").quantile(0.0, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-midpoint/0.25/f64"] = [
    @pl.col("f64").quantile(0.25, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-midpoint/0.9/f64"] = [
    @pl.col("f64").quantile(0.9, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-midpoint/1.0/f64"] = [
    @pl.col("f64").quantile(1.0, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-midpoint/0.0/d"] = [
    @pl.col("d").quantile(0.0, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-midpoint/0.25/d"] = [
    @pl.col("d").quantile(0.25, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-midpoint/0.9/d"] = [
    @pl.col("d").quantile(0.9, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-midpoint/1.0/d"] = [
    @pl.col("d").quantile(1.0, interpolation=@pl.QuantileMethod::Midpoint),
  ]
  m["agg/quantile-linear/0.0/i32"] = [
    @pl.col("i32").quantile(0.0, interpolation=@pl.QuantileMethod::Linear),
  ]
  m["agg/quantile-linear/0.25/i32"] = [
    @pl.col("i32").quantile(0.25, interpolation=@pl.QuantileMethod::Linear),
  ]
  m["agg/quantile-linear/0.9/i32"] = [
    @pl.col("i32").quantile(0.9, interpolation=@pl.QuantileMethod::Linear),
  ]
  m["agg/quantile-linear/1.0/i32"] = [
    @pl.col("i32").quantile(1.0, interpolation=@pl.QuantileMethod::Linear),
  ]
  m["agg/quantile-linear/0.0/f64"] = [
    @pl.col("f64").quantile(0.0, interpolation=@pl.QuantileMethod::Linear),
  ]
  m["agg/quantile-linear/0.25/f64"] = [
    @pl.col("f64").quantile(0.25, interpolation=@pl.QuantileMethod::Linear),
  ]
  m["agg/quantile-linear/0.9/f64"] = [
    @pl.col("f64").quantile(0.9, interpolation=@pl.QuantileMethod::Linear),
  ]
}

///|
fn golden_expr_agg_cases_6(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/quantile-linear/1.0/f64"] = [
    @pl.col("f64").quantile(1.0, interpolation=@pl.QuantileMethod::Linear),
  ]
  m["agg/quantile-linear/0.0/d"] = [
    @pl.col("d").quantile(0.0, interpolation=@pl.QuantileMethod::Linear),
  ]
  m["agg/quantile-linear/0.25/d"] = [
    @pl.col("d").quantile(0.25, interpolation=@pl.QuantileMethod::Linear),
  ]
  m["agg/quantile-linear/0.9/d"] = [
    @pl.col("d").quantile(0.9, interpolation=@pl.QuantileMethod::Linear),
  ]
  m["agg/quantile-linear/1.0/d"] = [
    @pl.col("d").quantile(1.0, interpolation=@pl.QuantileMethod::Linear),
  ]
  m["agg/quantile-equiprobable/0.0/i32"] = [
    @pl.col("i32").quantile(0.0, interpolation=@pl.QuantileMethod::Equiprobable),
  ]
  m["agg/quantile-equiprobable/0.25/i32"] = [
    @pl.col("i32").quantile(
      0.25,
      interpolation=@pl.QuantileMethod::Equiprobable,
    ),
  ]
  m["agg/quantile-equiprobable/0.9/i32"] = [
    @pl.col("i32").quantile(0.9, interpolation=@pl.QuantileMethod::Equiprobable),
  ]
  m["agg/quantile-equiprobable/1.0/i32"] = [
    @pl.col("i32").quantile(1.0, interpolation=@pl.QuantileMethod::Equiprobable),
  ]
  m["agg/quantile-equiprobable/0.0/f64"] = [
    @pl.col("f64").quantile(0.0, interpolation=@pl.QuantileMethod::Equiprobable),
  ]
  m["agg/quantile-equiprobable/0.25/f64"] = [
    @pl.col("f64").quantile(
      0.25,
      interpolation=@pl.QuantileMethod::Equiprobable,
    ),
  ]
  m["agg/quantile-equiprobable/0.9/f64"] = [
    @pl.col("f64").quantile(0.9, interpolation=@pl.QuantileMethod::Equiprobable),
  ]
  m["agg/quantile-equiprobable/1.0/f64"] = [
    @pl.col("f64").quantile(1.0, interpolation=@pl.QuantileMethod::Equiprobable),
  ]
  m["agg/quantile-equiprobable/0.0/d"] = [
    @pl.col("d").quantile(0.0, interpolation=@pl.QuantileMethod::Equiprobable),
  ]
  m["agg/quantile-equiprobable/0.25/d"] = [
    @pl.col("d").quantile(0.25, interpolation=@pl.QuantileMethod::Equiprobable),
  ]
  m["agg/quantile-equiprobable/0.9/d"] = [
    @pl.col("d").quantile(0.9, interpolation=@pl.QuantileMethod::Equiprobable),
  ]
  m["agg/quantile-equiprobable/1.0/d"] = [
    @pl.col("d").quantile(1.0, interpolation=@pl.QuantileMethod::Equiprobable),
  ]
  m["agg/quantile-bad/-0.1/f64"] = [
    @pl.col("f64").quantile(-0.1, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/-0.1/i32"] = [
    @pl.col("i32").quantile(-0.1, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/-0.1/s"] = [
    @pl.col("s").quantile(-0.1, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/-0.1/b"] = [
    @pl.col("b").quantile(-0.1, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/-0.1/n"] = [
    @pl.col("n").quantile(-0.1, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/-0.1/e0"] = [
    @pl.col("f64").quantile(-0.1, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/1.5/f64"] = [
    @pl.col("f64").quantile(1.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/1.5/i32"] = [
    @pl.col("i32").quantile(1.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/1.5/s"] = [
    @pl.col("s").quantile(1.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/1.5/b"] = [
    @pl.col("b").quantile(1.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/1.5/n"] = [
    @pl.col("n").quantile(1.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/1.5/e0"] = [
    @pl.col("f64").quantile(1.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/nan/f64"] = [
    @pl.col("f64").quantile(
      0.0 / 0.0,
      interpolation=@pl.QuantileMethod::Nearest,
    ),
  ]
  m["agg/quantile-bad/nan/i32"] = [
    @pl.col("i32").quantile(
      0.0 / 0.0,
      interpolation=@pl.QuantileMethod::Nearest,
    ),
  ]
  m["agg/quantile-bad/nan/s"] = [
    @pl.col("s").quantile(0.0 / 0.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/nan/b"] = [
    @pl.col("b").quantile(0.0 / 0.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/nan/n"] = [
    @pl.col("n").quantile(0.0 / 0.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/nan/e0"] = [
    @pl.col("f64").quantile(
      0.0 / 0.0,
      interpolation=@pl.QuantileMethod::Nearest,
    ),
  ]
  m["agg/quantile-bad/inf/f64"] = [
    @pl.col("f64").quantile(
      1.0 / 0.0,
      interpolation=@pl.QuantileMethod::Nearest,
    ),
  ]
  m["agg/quantile-bad/inf/i32"] = [
    @pl.col("i32").quantile(
      1.0 / 0.0,
      interpolation=@pl.QuantileMethod::Nearest,
    ),
  ]
  m["agg/quantile-bad/inf/s"] = [
    @pl.col("s").quantile(1.0 / 0.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/inf/b"] = [
    @pl.col("b").quantile(1.0 / 0.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/inf/n"] = [
    @pl.col("n").quantile(1.0 / 0.0, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/inf/e0"] = [
    @pl.col("f64").quantile(
      1.0 / 0.0,
      interpolation=@pl.QuantileMethod::Nearest,
    ),
  ]
  m["agg/quantile-bad/1.5/i32/r1"] = [
    @pl.col("i32").quantile(1.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/1.5/f64/r1"] = [
    @pl.col("f64").quantile(1.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/1.5/d/r1"] = [
    @pl.col("d").quantile(1.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/quantile-bad/1.5/s/r1"] = [
    @pl.col("s").quantile(1.5, interpolation=@pl.QuantileMethod::Nearest),
  ]
  m["agg/many"] = [
    @pl.col("i32").sum(),
    @pl.col("f64").mean().alias("m"),
    @pl.col("s").min().alias("mn"),
    @pl.col("d").max().alias("mx"),
    @pl.col("n").count().alias("cn"),
  ]
  m["agg/many/e0"] = [
    @pl.col("i32").sum(),
    @pl.col("f64").mean().alias("m"),
    @pl.col("s").min().alias("mn"),
    @pl.col("d").max().alias("mx"),
    @pl.col("n").len().alias("ln"),
  ]
  m["agg/many/z0-lit"] = [
    @pl.lit_int(1L).sum(),
    @pl.lit_int(1L).count().alias("c"),
  ]
  m["agg/of-expr"] = [(@pl.col("i32") + @pl.lit_int(1L)).sum()]
  m["agg/of-expr/cmp"] = [@pl.col("i64").gt(@pl.lit_int(0L)).sum()]
  m["agg/of-expr/cast"] = [
    @pl.col("f32").cast(@pl.DataType::Float64).sum().alias("x"),
  ]
  m["agg/of-agg"] = [@pl.col("i32").mean().sum()]
  m["agg/of-alias"] = [@pl.col("i64").alias("z").max()]
  m["agg/alias-after"] = [@pl.col("i32").sum().alias("z")]
  m["agg/neg"] = [-@pl.col("i32").sum()]
  m["agg/is_null"] = [@pl.col("n").sum().is_null()]
  m["agg/cols"] = [@pl.cols(["i32", "f64"]).sum()]
  m["agg/all"] = [@pl.all().max()]
  m["agg/all/e0"] = [@pl.all().count()]
  m["agg/cols-mean-lit"] = [@pl.cols(["i32", "i64"]).mean() + @pl.lit_int(1L)]
}

///|
fn golden_expr_agg_cases_7(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["agg/lit/sum"] = [@pl.lit_int(1L).sum()]
  m["agg/litf/sum"] = [@pl.lit_float(1.5).sum()]
  m["agg/lit/min"] = [@pl.lit_int(1L).min()]
  m["agg/litf/min"] = [@pl.lit_float(1.5).min()]
  m["agg/lit/mean"] = [@pl.lit_int(1L).mean()]
  m["agg/litf/mean"] = [@pl.lit_float(1.5).mean()]
  m["agg/lit/count"] = [@pl.lit_int(1L).count()]
  m["agg/litf/count"] = [@pl.lit_float(1.5).count()]
  m["agg/lit/n_unique"] = [@pl.lit_int(1L).n_unique()]
  m["agg/litf/n_unique"] = [@pl.lit_float(1.5).n_unique()]
  m["agg/lit/first"] = [@pl.lit_int(1L).first()]
  m["agg/litf/first"] = [@pl.lit_float(1.5).first()]
  m["agg/lit-str/max"] = [@pl.lit_str("abc").max()]
  m["agg/lit-null/sum"] = [@pl.lit(@pl.AnyValue::Null).sum()]
  m["agg/lit-null/n_unique"] = [@pl.lit(@pl.AnyValue::Null).n_unique()]
  m["agg/missing-col"] = [@pl.col("zz").sum()]
  m["agg/sum-str-error-first"] = [
    @pl.col("i32").sum(),
    @pl.col("s").sum().alias("x"),
  ]
  m["agg/dup-name"] = [@pl.col("i32").sum(), @pl.col("i32").max()]
  m["agg/op/i32-mean"] = [@pl.col("i32") - @pl.col("i32").mean()]
  m["agg/op/i32-over-sum"] = [@pl.col("i32") / @pl.col("i32").sum()]
  m["agg/op/i32-floordiv-sum"] = [
    @pl.col("i32").floor_div(@pl.col("i32").sum()),
  ]
  m["agg/op/i32-mod-max"] = [@pl.col("i32") % @pl.col("i32").max()]
  m["agg/op/i32-gt-mean"] = [@pl.col("i32").gt(@pl.col("i32").mean())]
  m["agg/op/i64-mean"] = [@pl.col("i64") - @pl.col("i64").mean()]
  m["agg/op/i64-over-sum"] = [@pl.col("i64") / @pl.col("i64").sum()]
  m["agg/op/i64-floordiv-sum"] = [
    @pl.col("i64").floor_div(@pl.col("i64").sum()),
  ]
  m["agg/op/i64-mod-max"] = [@pl.col("i64") % @pl.col("i64").max()]
  m["agg/op/i64-gt-mean"] = [@pl.col("i64").gt(@pl.col("i64").mean())]
  m["agg/op/f32-mean"] = [@pl.col("f32") - @pl.col("f32").mean()]
  m["agg/op/f32-over-sum"] = [@pl.col("f32") / @pl.col("f32").sum()]
  m["agg/op/f32-floordiv-sum"] = [
    @pl.col("f32").floor_div(@pl.col("f32").sum()),
  ]
  m["agg/op/f32-mod-max"] = [@pl.col("f32") % @pl.col("f32").max()]
  m["agg/op/f32-gt-mean"] = [@pl.col("f32").gt(@pl.col("f32").mean())]
  m["agg/op/f64-mean"] = [@pl.col("f64") - @pl.col("f64").mean()]
  m["agg/op/f64-over-sum"] = [@pl.col("f64") / @pl.col("f64").sum()]
  m["agg/op/f64-floordiv-sum"] = [
    @pl.col("f64").floor_div(@pl.col("f64").sum()),
  ]
  m["agg/op/f64-mod-max"] = [@pl.col("f64") % @pl.col("f64").max()]
  m["agg/op/f64-gt-mean"] = [@pl.col("f64").gt(@pl.col("f64").mean())]
  m["agg/op/agg-agg"] = [@pl.col("i32").max() - @pl.col("i32").min()]
  m["agg/op/agg-div-agg"] = [@pl.col("i64").sum() / @pl.col("i64").count()]
  m["agg/op/agg-lit"] = [@pl.col("i32").sum() + @pl.lit_int(1L)]
  m["agg/op/lit-agg"] = [@pl.lit_int(1L) + @pl.col("i32").sum()]
  m["agg/op/agg-over-lit"] = [@pl.col("i32").sum() / @pl.lit_int(0L)]
  m["agg/op/str-agg"] = [@pl.col("s") + @pl.col("s").max()]
  m["agg/op/z-score"] = [
    (@pl.col("f64") - @pl.col("f64").mean()) / @pl.col("f64").std(ddof=1),
  ]
  m["agg/op/z-score/e0"] = [
    (@pl.col("f64") - @pl.col("f64").mean()) / @pl.col("f64").std(ddof=1),
  ]
  m["bc/select/col-sum/i32/t"] = [
    @pl.col("i32"),
    @pl.col("i32").sum().alias("agg"),
  ]
  m["bc/select/sum-col/i32/t"] = [
    @pl.col("i32").count().alias("agg"),
    @pl.col("i32"),
  ]
  m["bc/select/col-sum/s/t"] = [@pl.col("s"), @pl.col("s").max().alias("agg")]
  m["bc/select/sum-col/s/t"] = [@pl.col("s").count().alias("agg"), @pl.col("s")]
  m["bc/select/col-sum/n/t"] = [@pl.col("n"), @pl.col("n").sum().alias("agg")]
  m["bc/select/sum-col/n/t"] = [@pl.col("n").count().alias("agg"), @pl.col("n")]
  m["bc/wc/len/t"] = [@pl.col("i32").len().alias("agg")]
  m["bc/select/two-aggs/t"] = [
    @pl.col("i32").sum(),
    @pl.col("f64").mean().alias("m"),
  ]
  m["bc/select/lit-agg/t"] = [@pl.lit_int(1L), @pl.col("i32").sum()]
  m["bc/select/agg-lit/t"] = [@pl.col("i32").sum(), @pl.lit_int(1L).alias("k")]
  m["bc/select/agg-col-lit/t"] = [
    @pl.col("i32").sum().alias("s"),
    @pl.col("i64"),
    @pl.lit_str("k").alias("k"),
  ]
  m["bc/wc/agg-in-place/t"] = [@pl.col("i32").sum().alias("i32")]
  m["bc/wc/two-aggs/t"] = [
    @pl.col("i32").sum().alias("a"),
    @pl.col("f64").mean().alias("b"),
  ]
  m["bc/wc/mix/t"] = [
    (@pl.col("i64") - @pl.col("i64").mean()).alias("c"),
    @pl.col("s").max().alias("m"),
  ]
}

///|
fn golden_expr_agg_cases_8(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["bc/select/centered/t"] = [
    @pl.col("f64") - @pl.col("f64").mean(),
    (@pl.col("i64") - @pl.col("i64").min()).alias("r"),
  ]
  m["bc/select/frac/t"] = [
    (@pl.col("i32") / @pl.col("i32").sum()).alias("frac"),
  ]
  m["bc/select/col-sum/i32/e0"] = [
    @pl.col("i32"),
    @pl.col("i32").sum().alias("agg"),
  ]
  m["bc/select/sum-col/i32/e0"] = [
    @pl.col("i32").count().alias("agg"),
    @pl.col("i32"),
  ]
  m["bc/select/col-sum/s/e0"] = [@pl.col("s"), @pl.col("s").max().alias("agg")]
  m["bc/select/sum-col/s/e0"] = [
    @pl.col("s").count().alias("agg"),
    @pl.col("s"),
  ]
  m["bc/select/col-sum/n/e0"] = [@pl.col("n"), @pl.col("n").sum().alias("agg")]
  m["bc/select/sum-col/n/e0"] = [
    @pl.col("n").count().alias("agg"),
    @pl.col("n"),
  ]
  m["bc/wc/len/e0"] = [@pl.col("i32").len().alias("agg")]
  m["bc/select/two-aggs/e0"] = [
    @pl.col("i32").sum(),
    @pl.col("f64").mean().alias("m"),
  ]
  m["bc/select/lit-agg/e0"] = [@pl.lit_int(1L), @pl.col("i32").sum()]
  m["bc/select/agg-lit/e0"] = [@pl.col("i32").sum(), @pl.lit_int(1L).alias("k")]
  m["bc/select/agg-col-lit/e0"] = [
    @pl.col("i32").sum().alias("s"),
    @pl.col("i64"),
    @pl.lit_str("k").alias("k"),
  ]
  m["bc/wc/agg-in-place/e0"] = [@pl.col("i32").sum().alias("i32")]
  m["bc/wc/two-aggs/e0"] = [
    @pl.col("i32").sum().alias("a"),
    @pl.col("f64").mean().alias("b"),
  ]
  m["bc/wc/mix/e0"] = [
    (@pl.col("i64") - @pl.col("i64").mean()).alias("c"),
    @pl.col("s").max().alias("m"),
  ]
  m["bc/select/centered/e0"] = [
    @pl.col("f64") - @pl.col("f64").mean(),
    (@pl.col("i64") - @pl.col("i64").min()).alias("r"),
  ]
  m["bc/select/frac/e0"] = [
    (@pl.col("i32") / @pl.col("i32").sum()).alias("frac"),
  ]
  m["bc/select/col-sum/i32/r1"] = [
    @pl.col("i32"),
    @pl.col("i32").sum().alias("agg"),
  ]
  m["bc/select/sum-col/i32/r1"] = [
    @pl.col("i32").count().alias("agg"),
    @pl.col("i32"),
  ]
  m["bc/select/col-sum/s/r1"] = [@pl.col("s"), @pl.col("s").max().alias("agg")]
  m["bc/select/sum-col/s/r1"] = [
    @pl.col("s").count().alias("agg"),
    @pl.col("s"),
  ]
  m["bc/select/col-sum/n/r1"] = [@pl.col("n"), @pl.col("n").sum().alias("agg")]
  m["bc/select/sum-col/n/r1"] = [
    @pl.col("n").count().alias("agg"),
    @pl.col("n"),
  ]
  m["bc/wc/len/r1"] = [@pl.col("i32").len().alias("agg")]
  m["bc/select/two-aggs/r1"] = [
    @pl.col("i32").sum(),
    @pl.col("f64").mean().alias("m"),
  ]
  m["bc/select/lit-agg/r1"] = [@pl.lit_int(1L), @pl.col("i32").sum()]
  m["bc/select/agg-lit/r1"] = [@pl.col("i32").sum(), @pl.lit_int(1L).alias("k")]
  m["bc/select/agg-col-lit/r1"] = [
    @pl.col("i32").sum().alias("s"),
    @pl.col("i64"),
    @pl.lit_str("k").alias("k"),
  ]
  m["bc/select/centered/r1"] = [
    @pl.col("f64") - @pl.col("f64").mean(),
    (@pl.col("i64") - @pl.col("i64").min()).alias("r"),
  ]
  m["bc/select/frac/r1"] = [
    (@pl.col("i32") / @pl.col("i32").sum()).alias("frac"),
  ]
  m["bc/select/agg-all/z0"] = [
    @pl.lit_int(1L).sum(),
    @pl.lit_int(2L).max().alias("m"),
  ]
  m["bc/select/agg-lit/z0"] = [
    @pl.lit_int(1L),
    @pl.lit_int(2L).sum().alias("s"),
  ]
  m["bc/wc/agg/z0"] = [@pl.lit_int(1L).sum()]
  m["bc/select/cols-agg"] = [
    @pl.cols(["i32", "i64"]).sum(),
    @pl.col("f64").max().alias("x"),
  ]
  m["bc/select/all-sum-broadcast"] = [
    @pl.col("i32"),
    @pl.col("i64").sum().alias("s"),
    @pl.col("f32").mean().alias("m"),
  ]
  m["bc/select/dup"] = [@pl.col("i32"), @pl.col("i32").sum()]
  m["bc/wc/dup"] = [
    @pl.col("i32").sum().alias("x"),
    @pl.col("i32").max().alias("x"),
  ]
  m["fn/is_nan/i32"] = [@pl.col("i32").is_nan()]
  m["fn/is_nan/i64"] = [@pl.col("i64").is_nan()]
  m["fn/is_nan/f32"] = [@pl.col("f32").is_nan()]
  m["fn/is_nan/f64"] = [@pl.col("f64").is_nan()]
  m["fn/is_nan/s"] = [@pl.col("s").is_nan()]
  m["fn/is_nan/b"] = [@pl.col("b").is_nan()]
  m["fn/is_nan/d"] = [@pl.col("d").is_nan()]
  m["fn/is_nan/dt"] = [@pl.col("dt").is_nan()]
  m["fn/is_nan/n"] = [@pl.col("n").is_nan()]
  m["fn/is_nan/e0"] = [
    @pl.col("f64").is_nan(),
    @pl.col("i32").is_nan().alias("i"),
  ]
  m["fn/is_nan/lit-float"] = [@pl.lit_float(-2.5).is_nan()]
  m["fn/is_nan/lit-int"] = [@pl.lit_int(-4L).is_nan()]
  m["fn/is_not_nan/i32"] = [@pl.col("i32").is_not_nan()]
  m["fn/is_not_nan/i64"] = [@pl.col("i64").is_not_nan()]
  m["fn/is_not_nan/f32"] = [@pl.col("f32").is_not_nan()]
  m["fn/is_not_nan/f64"] = [@pl.col("f64").is_not_nan()]
  m["fn/is_not_nan/s"] = [@pl.col("s").is_not_nan()]
  m["fn/is_not_nan/b"] = [@pl.col("b").is_not_nan()]
  m["fn/is_not_nan/d"] = [@pl.col("d").is_not_nan()]
  m["fn/is_not_nan/dt"] = [@pl.col("dt").is_not_nan()]
  m["fn/is_not_nan/n"] = [@pl.col("n").is_not_nan()]
  m["fn/is_not_nan/e0"] = [
    @pl.col("f64").is_not_nan(),
    @pl.col("i32").is_not_nan().alias("i"),
  ]
}

///|
fn golden_expr_agg_cases_9(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["fn/is_not_nan/lit-float"] = [@pl.lit_float(-2.5).is_not_nan()]
  m["fn/is_not_nan/lit-int"] = [@pl.lit_int(-4L).is_not_nan()]
  m["fn/is_finite/i32"] = [@pl.col("i32").is_finite()]
  m["fn/is_finite/i64"] = [@pl.col("i64").is_finite()]
  m["fn/is_finite/f32"] = [@pl.col("f32").is_finite()]
  m["fn/is_finite/f64"] = [@pl.col("f64").is_finite()]
  m["fn/is_finite/s"] = [@pl.col("s").is_finite()]
  m["fn/is_finite/b"] = [@pl.col("b").is_finite()]
  m["fn/is_finite/d"] = [@pl.col("d").is_finite()]
  m["fn/is_finite/dt"] = [@pl.col("dt").is_finite()]
  m["fn/is_finite/n"] = [@pl.col("n").is_finite()]
  m["fn/is_finite/e0"] = [
    @pl.col("f64").is_finite(),
    @pl.col("i32").is_finite().alias("i"),
  ]
  m["fn/is_finite/lit-float"] = [@pl.lit_float(-2.5).is_finite()]
  m["fn/is_finite/lit-int"] = [@pl.lit_int(-4L).is_finite()]
  m["fn/is_infinite/i32"] = [@pl.col("i32").is_infinite()]
  m["fn/is_infinite/i64"] = [@pl.col("i64").is_infinite()]
  m["fn/is_infinite/f32"] = [@pl.col("f32").is_infinite()]
  m["fn/is_infinite/f64"] = [@pl.col("f64").is_infinite()]
  m["fn/is_infinite/s"] = [@pl.col("s").is_infinite()]
  m["fn/is_infinite/b"] = [@pl.col("b").is_infinite()]
  m["fn/is_infinite/d"] = [@pl.col("d").is_infinite()]
  m["fn/is_infinite/dt"] = [@pl.col("dt").is_infinite()]
  m["fn/is_infinite/n"] = [@pl.col("n").is_infinite()]
  m["fn/is_infinite/e0"] = [
    @pl.col("f64").is_infinite(),
    @pl.col("i32").is_infinite().alias("i"),
  ]
  m["fn/is_infinite/lit-float"] = [@pl.lit_float(-2.5).is_infinite()]
  m["fn/is_infinite/lit-int"] = [@pl.lit_int(-4L).is_infinite()]
  m["fn/abs/i32"] = [@pl.col("i32").abs()]
  m["fn/abs/i64"] = [@pl.col("i64").abs()]
  m["fn/abs/f32"] = [@pl.col("f32").abs()]
  m["fn/abs/f64"] = [@pl.col("f64").abs()]
  m["fn/abs/s"] = [@pl.col("s").abs()]
  m["fn/abs/b"] = [@pl.col("b").abs()]
  m["fn/abs/d"] = [@pl.col("d").abs()]
  m["fn/abs/dt"] = [@pl.col("dt").abs()]
  m["fn/abs/n"] = [@pl.col("n").abs()]
  m["fn/abs/e0"] = [@pl.col("f64").abs(), @pl.col("i32").abs().alias("i")]
  m["fn/abs/lit-float"] = [@pl.lit_float(-2.5).abs()]
  m["fn/abs/lit-int"] = [@pl.lit_int(-4L).abs()]
  m["fn/sqrt/i32"] = [@pl.col("i32").sqrt()]
  m["fn/sqrt/i64"] = [@pl.col("i64").sqrt()]
  m["fn/sqrt/f32"] = [@pl.col("f32").sqrt()]
  m["fn/sqrt/f64"] = [@pl.col("f64").sqrt()]
  m["fn/sqrt/s"] = [@pl.col("s").sqrt()]
  m["fn/sqrt/b"] = [@pl.col("b").sqrt()]
  m["fn/sqrt/d"] = [@pl.col("d").sqrt()]
  m["fn/sqrt/dt"] = [@pl.col("dt").sqrt()]
  m["fn/sqrt/n"] = [@pl.col("n").sqrt()]
  m["fn/sqrt/e0"] = [@pl.col("f64").sqrt(), @pl.col("i32").sqrt().alias("i")]
  m["fn/sqrt/lit-float"] = [@pl.lit_float(-2.5).sqrt()]
  m["fn/sqrt/lit-int"] = [@pl.lit_int(-4L).sqrt()]
  m["fn/exp/i32"] = [@pl.col("i32").exp()]
  m["fn/exp/i64"] = [@pl.col("i64").exp()]
  m["fn/exp/f32"] = [@pl.col("f32").exp()]
  m["fn/exp/f64"] = [@pl.col("f64").exp()]
  m["fn/exp/s"] = [@pl.col("s").exp()]
  m["fn/exp/b"] = [@pl.col("b").exp()]
  m["fn/exp/d"] = [@pl.col("d").exp()]
  m["fn/exp/dt"] = [@pl.col("dt").exp()]
  m["fn/exp/n"] = [@pl.col("n").exp()]
  m["fn/exp/e0"] = [@pl.col("f64").exp(), @pl.col("i32").exp().alias("i")]
}

///|
fn golden_expr_agg_cases_10(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["fn/exp/lit-float"] = [@pl.lit_float(-2.5).exp()]
  m["fn/exp/lit-int"] = [@pl.lit_int(-4L).exp()]
  m["fn/log/None/i32"] = [@pl.col("i32").log()]
  m["fn/log/None/i64"] = [@pl.col("i64").log()]
  m["fn/log/None/f32"] = [@pl.col("f32").log()]
  m["fn/log/None/f64"] = [@pl.col("f64").log()]
  m["fn/log/None/b"] = [@pl.col("b").log()]
  m["fn/log/None/s"] = [@pl.col("s").log()]
  m["fn/log/None/d"] = [@pl.col("d").log()]
  m["fn/log/None/dt"] = [@pl.col("dt").log()]
  m["fn/log/None/n"] = [@pl.col("n").log()]
  m["fn/log/None/e0"] = [@pl.col("f64").log()]
  m["fn/log/2.0/i32"] = [@pl.col("i32").log(base=2.0)]
  m["fn/log/2.0/i64"] = [@pl.col("i64").log(base=2.0)]
  m["fn/log/2.0/f32"] = [@pl.col("f32").log(base=2.0)]
  m["fn/log/2.0/f64"] = [@pl.col("f64").log(base=2.0)]
  m["fn/log/2.0/s"] = [@pl.col("s").log(base=2.0)]
  m["fn/log/2.0/n"] = [@pl.col("n").log(base=2.0)]
  m["fn/log/2.0/e0"] = [@pl.col("f64").log(base=2.0)]
  m["fn/log/10.0/i32"] = [@pl.col("i32").log(base=10.0)]
  m["fn/log/10.0/i64"] = [@pl.col("i64").log(base=10.0)]
  m["fn/log/10.0/f32"] = [@pl.col("f32").log(base=10.0)]
  m["fn/log/10.0/f64"] = [@pl.col("f64").log(base=10.0)]
  m["fn/log/10.0/s"] = [@pl.col("s").log(base=10.0)]
  m["fn/log/10.0/n"] = [@pl.col("n").log(base=10.0)]
  m["fn/log/10.0/e0"] = [@pl.col("f64").log(base=10.0)]
  m["fn/log/0.5/i32"] = [@pl.col("i32").log(base=0.5)]
  m["fn/log/0.5/i64"] = [@pl.col("i64").log(base=0.5)]
  m["fn/log/0.5/f32"] = [@pl.col("f32").log(base=0.5)]
  m["fn/log/0.5/f64"] = [@pl.col("f64").log(base=0.5)]
  m["fn/log/0.5/s"] = [@pl.col("s").log(base=0.5)]
  m["fn/log/0.5/n"] = [@pl.col("n").log(base=0.5)]
  m["fn/log/0.5/e0"] = [@pl.col("f64").log(base=0.5)]
  m["fn/log/1.0/i32"] = [@pl.col("i32").log(base=1.0)]
  m["fn/log/1.0/i64"] = [@pl.col("i64").log(base=1.0)]
  m["fn/log/1.0/f32"] = [@pl.col("f32").log(base=1.0)]
  m["fn/log/1.0/f64"] = [@pl.col("f64").log(base=1.0)]
  m["fn/log/1.0/s"] = [@pl.col("s").log(base=1.0)]
  m["fn/log/1.0/n"] = [@pl.col("n").log(base=1.0)]
  m["fn/log/1.0/e0"] = [@pl.col("f64").log(base=1.0)]
  m["fn/log/-2.0/i32"] = [@pl.col("i32").log(base=-2.0)]
  m["fn/log/-2.0/i64"] = [@pl.col("i64").log(base=-2.0)]
  m["fn/log/-2.0/f32"] = [@pl.col("f32").log(base=-2.0)]
  m["fn/log/-2.0/f64"] = [@pl.col("f64").log(base=-2.0)]
  m["fn/log/-2.0/s"] = [@pl.col("s").log(base=-2.0)]
  m["fn/log/-2.0/n"] = [@pl.col("n").log(base=-2.0)]
  m["fn/log/-2.0/e0"] = [@pl.col("f64").log(base=-2.0)]
  m["fn/round/0/i32"] = [@pl.col("i32").round(decimals=0)]
  m["fn/round/0/i64"] = [@pl.col("i64").round(decimals=0)]
  m["fn/round/0/f32"] = [@pl.col("f32").round(decimals=0)]
  m["fn/round/0/f64"] = [@pl.col("f64").round(decimals=0)]
  m["fn/round/0/s"] = [@pl.col("s").round(decimals=0)]
  m["fn/round/0/b"] = [@pl.col("b").round(decimals=0)]
  m["fn/round/0/d"] = [@pl.col("d").round(decimals=0)]
  m["fn/round/0/dt"] = [@pl.col("dt").round(decimals=0)]
  m["fn/round/0/n"] = [@pl.col("n").round(decimals=0)]
  m["fn/round/0/e0"] = [@pl.col("f64").round(decimals=0)]
  m["fn/round/1/i32"] = [@pl.col("i32").round(decimals=1)]
  m["fn/round/1/i64"] = [@pl.col("i64").round(decimals=1)]
  m["fn/round/1/f32"] = [@pl.col("f32").round(decimals=1)]
}

///|
fn golden_expr_agg_cases_11(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["fn/round/1/f64"] = [@pl.col("f64").round(decimals=1)]
  m["fn/round/1/s"] = [@pl.col("s").round(decimals=1)]
  m["fn/round/1/b"] = [@pl.col("b").round(decimals=1)]
  m["fn/round/1/d"] = [@pl.col("d").round(decimals=1)]
  m["fn/round/1/dt"] = [@pl.col("dt").round(decimals=1)]
  m["fn/round/1/n"] = [@pl.col("n").round(decimals=1)]
  m["fn/round/1/e0"] = [@pl.col("f64").round(decimals=1)]
  m["fn/round/2/i32"] = [@pl.col("i32").round(decimals=2)]
  m["fn/round/2/i64"] = [@pl.col("i64").round(decimals=2)]
  m["fn/round/2/f32"] = [@pl.col("f32").round(decimals=2)]
  m["fn/round/2/f64"] = [@pl.col("f64").round(decimals=2)]
  m["fn/round/2/s"] = [@pl.col("s").round(decimals=2)]
  m["fn/round/2/b"] = [@pl.col("b").round(decimals=2)]
  m["fn/round/2/d"] = [@pl.col("d").round(decimals=2)]
  m["fn/round/2/dt"] = [@pl.col("dt").round(decimals=2)]
  m["fn/round/2/n"] = [@pl.col("n").round(decimals=2)]
  m["fn/round/2/e0"] = [@pl.col("f64").round(decimals=2)]
  m["fn/round/5/i32"] = [@pl.col("i32").round(decimals=5)]
  m["fn/round/5/i64"] = [@pl.col("i64").round(decimals=5)]
  m["fn/round/5/f32"] = [@pl.col("f32").round(decimals=5)]
  m["fn/round/5/f64"] = [@pl.col("f64").round(decimals=5)]
  m["fn/round/5/s"] = [@pl.col("s").round(decimals=5)]
  m["fn/round/5/b"] = [@pl.col("b").round(decimals=5)]
  m["fn/round/5/d"] = [@pl.col("d").round(decimals=5)]
  m["fn/round/5/dt"] = [@pl.col("dt").round(decimals=5)]
  m["fn/round/5/n"] = [@pl.col("n").round(decimals=5)]
  m["fn/round/5/e0"] = [@pl.col("f64").round(decimals=5)]
  m["fn/round/15/i32"] = [@pl.col("i32").round(decimals=15)]
  m["fn/round/15/i64"] = [@pl.col("i64").round(decimals=15)]
  m["fn/round/15/f32"] = [@pl.col("f32").round(decimals=15)]
  m["fn/round/15/f64"] = [@pl.col("f64").round(decimals=15)]
  m["fn/round/15/s"] = [@pl.col("s").round(decimals=15)]
  m["fn/round/15/b"] = [@pl.col("b").round(decimals=15)]
  m["fn/round/15/d"] = [@pl.col("d").round(decimals=15)]
  m["fn/round/15/dt"] = [@pl.col("dt").round(decimals=15)]
  m["fn/round/15/n"] = [@pl.col("n").round(decimals=15)]
  m["fn/round/15/e0"] = [@pl.col("f64").round(decimals=15)]
  m["fn/round/lit"] = [@pl.lit_float(2.675).round(decimals=2)]
  m["fn/chain"] = [@pl.col("f64").log(base=2.0).abs()]
  m["fn/in-op"] = [@pl.col("i32").abs() + @pl.lit_int(1L)]
  m["fn/in-op-sqrt"] = [@pl.col("f32").sqrt() * @pl.col("f64")]
  m["fn/is_nan-agg"] = [@pl.col("f64").sum().is_nan()]
  m["fn/abs-agg"] = [@pl.col("f64").min().abs()]
  m["fn/abs-alias"] = [@pl.col("i32").alias("z").abs()]
  m["fn/abs-cols"] = [@pl.cols(["i32", "f64"]).abs()]
  m["fn/abs-all"] = [@pl.all().is_nan()]
  m["fn/abs-neg"] = [(-@pl.col("i32")).abs()]
  m["fn/abs-missing"] = [@pl.col("zz").abs()]
  m["fn/abs-str-then-missing"] = [@pl.col("s").abs(), @pl.col("zz")]
  m["fn/null-is_nan-agg"] = [@pl.col("n").mean().is_nan()]
  m["fill/lit/i32/int0"] = [@pl.col("i32").fill_null(@pl.lit_int(0L))]
  m["fill/lit/i32/int3e9"] = [
    @pl.col("i32").fill_null(@pl.lit_int(3000000000L)),
  ]
  m["fill/lit/i32/float1.5"] = [@pl.col("i32").fill_null(@pl.lit_float(1.5))]
  m["fill/lit/i32/str"] = [@pl.col("i32").fill_null(@pl.lit_str("x"))]
  m["fill/lit/i32/bool"] = [@pl.col("i32").fill_null(@pl.lit_bool(true))]
  m["fill/lit/i32/null"] = [
    @pl.col("i32").fill_null(@pl.lit(@pl.AnyValue::Null)),
  ]
  m["fill/lit/i32/i64"] = [
    @pl.col("i32").fill_null(@pl.lit(@pl.AnyValue::Int64(7L))),
  ]
  m["fill/lit/i32/f32"] = [
    @pl.col("i32").fill_null(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["fill/lit/i32/date"] = [
    @pl.col("i32").fill_null(@pl.lit(@pl.AnyValue::Date(5))),
  ]
  m["fill/lit/i32/e0"] = [@pl.col("i32").fill_null(@pl.lit_int(0L))]
}

///|
fn golden_expr_agg_cases_12(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["fill/lit/i64/int0"] = [@pl.col("i64").fill_null(@pl.lit_int(0L))]
  m["fill/lit/i64/int3e9"] = [
    @pl.col("i64").fill_null(@pl.lit_int(3000000000L)),
  ]
  m["fill/lit/i64/float1.5"] = [@pl.col("i64").fill_null(@pl.lit_float(1.5))]
  m["fill/lit/i64/str"] = [@pl.col("i64").fill_null(@pl.lit_str("x"))]
  m["fill/lit/i64/bool"] = [@pl.col("i64").fill_null(@pl.lit_bool(true))]
  m["fill/lit/i64/null"] = [
    @pl.col("i64").fill_null(@pl.lit(@pl.AnyValue::Null)),
  ]
  m["fill/lit/i64/i64"] = [
    @pl.col("i64").fill_null(@pl.lit(@pl.AnyValue::Int64(7L))),
  ]
  m["fill/lit/i64/f32"] = [
    @pl.col("i64").fill_null(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["fill/lit/i64/date"] = [
    @pl.col("i64").fill_null(@pl.lit(@pl.AnyValue::Date(5))),
  ]
  m["fill/lit/i64/e0"] = [@pl.col("i64").fill_null(@pl.lit_int(0L))]
  m["fill/lit/f32/int0"] = [@pl.col("f32").fill_null(@pl.lit_int(0L))]
  m["fill/lit/f32/int3e9"] = [
    @pl.col("f32").fill_null(@pl.lit_int(3000000000L)),
  ]
  m["fill/lit/f32/float1.5"] = [@pl.col("f32").fill_null(@pl.lit_float(1.5))]
  m["fill/lit/f32/str"] = [@pl.col("f32").fill_null(@pl.lit_str("x"))]
  m["fill/lit/f32/bool"] = [@pl.col("f32").fill_null(@pl.lit_bool(true))]
  m["fill/lit/f32/null"] = [
    @pl.col("f32").fill_null(@pl.lit(@pl.AnyValue::Null)),
  ]
  m["fill/lit/f32/i64"] = [
    @pl.col("f32").fill_null(@pl.lit(@pl.AnyValue::Int64(7L))),
  ]
  m["fill/lit/f32/f32"] = [
    @pl.col("f32").fill_null(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["fill/lit/f32/date"] = [
    @pl.col("f32").fill_null(@pl.lit(@pl.AnyValue::Date(5))),
  ]
  m["fill/lit/f32/e0"] = [@pl.col("f32").fill_null(@pl.lit_int(0L))]
  m["fill/lit/f64/int0"] = [@pl.col("f64").fill_null(@pl.lit_int(0L))]
  m["fill/lit/f64/int3e9"] = [
    @pl.col("f64").fill_null(@pl.lit_int(3000000000L)),
  ]
  m["fill/lit/f64/float1.5"] = [@pl.col("f64").fill_null(@pl.lit_float(1.5))]
  m["fill/lit/f64/str"] = [@pl.col("f64").fill_null(@pl.lit_str("x"))]
  m["fill/lit/f64/bool"] = [@pl.col("f64").fill_null(@pl.lit_bool(true))]
  m["fill/lit/f64/null"] = [
    @pl.col("f64").fill_null(@pl.lit(@pl.AnyValue::Null)),
  ]
  m["fill/lit/f64/i64"] = [
    @pl.col("f64").fill_null(@pl.lit(@pl.AnyValue::Int64(7L))),
  ]
  m["fill/lit/f64/f32"] = [
    @pl.col("f64").fill_null(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["fill/lit/f64/date"] = [
    @pl.col("f64").fill_null(@pl.lit(@pl.AnyValue::Date(5))),
  ]
  m["fill/lit/f64/e0"] = [@pl.col("f64").fill_null(@pl.lit_int(0L))]
  m["fill/lit/s/int0"] = [@pl.col("s").fill_null(@pl.lit_int(0L))]
  m["fill/lit/s/int3e9"] = [@pl.col("s").fill_null(@pl.lit_int(3000000000L))]
  m["fill/lit/s/float1.5"] = [@pl.col("s").fill_null(@pl.lit_float(1.5))]
  m["fill/lit/s/str"] = [@pl.col("s").fill_null(@pl.lit_str("x"))]
  m["fill/lit/s/bool"] = [@pl.col("s").fill_null(@pl.lit_bool(true))]
  m["fill/lit/s/null"] = [@pl.col("s").fill_null(@pl.lit(@pl.AnyValue::Null))]
  m["fill/lit/s/i64"] = [
    @pl.col("s").fill_null(@pl.lit(@pl.AnyValue::Int64(7L))),
  ]
  m["fill/lit/s/f32"] = [
    @pl.col("s").fill_null(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["fill/lit/s/date"] = [
    @pl.col("s").fill_null(@pl.lit(@pl.AnyValue::Date(5))),
  ]
  m["fill/lit/s/e0"] = [@pl.col("s").fill_null(@pl.lit_int(0L))]
  m["fill/lit/b/int0"] = [@pl.col("b").fill_null(@pl.lit_int(0L))]
  m["fill/lit/b/int3e9"] = [@pl.col("b").fill_null(@pl.lit_int(3000000000L))]
  m["fill/lit/b/float1.5"] = [@pl.col("b").fill_null(@pl.lit_float(1.5))]
  m["fill/lit/b/str"] = [@pl.col("b").fill_null(@pl.lit_str("x"))]
  m["fill/lit/b/bool"] = [@pl.col("b").fill_null(@pl.lit_bool(true))]
  m["fill/lit/b/null"] = [@pl.col("b").fill_null(@pl.lit(@pl.AnyValue::Null))]
  m["fill/lit/b/i64"] = [
    @pl.col("b").fill_null(@pl.lit(@pl.AnyValue::Int64(7L))),
  ]
  m["fill/lit/b/f32"] = [
    @pl.col("b").fill_null(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["fill/lit/b/date"] = [
    @pl.col("b").fill_null(@pl.lit(@pl.AnyValue::Date(5))),
  ]
  m["fill/lit/b/e0"] = [@pl.col("b").fill_null(@pl.lit_int(0L))]
  m["fill/lit/d/int0"] = [@pl.col("d").fill_null(@pl.lit_int(0L))]
  m["fill/lit/d/int3e9"] = [@pl.col("d").fill_null(@pl.lit_int(3000000000L))]
  m["fill/lit/d/float1.5"] = [@pl.col("d").fill_null(@pl.lit_float(1.5))]
  m["fill/lit/d/str"] = [@pl.col("d").fill_null(@pl.lit_str("x"))]
  m["fill/lit/d/bool"] = [@pl.col("d").fill_null(@pl.lit_bool(true))]
  m["fill/lit/d/null"] = [@pl.col("d").fill_null(@pl.lit(@pl.AnyValue::Null))]
  m["fill/lit/d/i64"] = [
    @pl.col("d").fill_null(@pl.lit(@pl.AnyValue::Int64(7L))),
  ]
  m["fill/lit/d/f32"] = [
    @pl.col("d").fill_null(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["fill/lit/d/date"] = [
    @pl.col("d").fill_null(@pl.lit(@pl.AnyValue::Date(5))),
  ]
  m["fill/lit/d/e0"] = [@pl.col("d").fill_null(@pl.lit_int(0L))]
}

///|
fn golden_expr_agg_cases_13(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["fill/lit/dt/int0"] = [@pl.col("dt").fill_null(@pl.lit_int(0L))]
  m["fill/lit/dt/int3e9"] = [@pl.col("dt").fill_null(@pl.lit_int(3000000000L))]
  m["fill/lit/dt/float1.5"] = [@pl.col("dt").fill_null(@pl.lit_float(1.5))]
  m["fill/lit/dt/str"] = [@pl.col("dt").fill_null(@pl.lit_str("x"))]
  m["fill/lit/dt/bool"] = [@pl.col("dt").fill_null(@pl.lit_bool(true))]
  m["fill/lit/dt/null"] = [@pl.col("dt").fill_null(@pl.lit(@pl.AnyValue::Null))]
  m["fill/lit/dt/i64"] = [
    @pl.col("dt").fill_null(@pl.lit(@pl.AnyValue::Int64(7L))),
  ]
  m["fill/lit/dt/f32"] = [
    @pl.col("dt").fill_null(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["fill/lit/dt/date"] = [
    @pl.col("dt").fill_null(@pl.lit(@pl.AnyValue::Date(5))),
  ]
  m["fill/lit/dt/e0"] = [@pl.col("dt").fill_null(@pl.lit_int(0L))]
  m["fill/lit/n/int0"] = [@pl.col("n").fill_null(@pl.lit_int(0L))]
  m["fill/lit/n/int3e9"] = [@pl.col("n").fill_null(@pl.lit_int(3000000000L))]
  m["fill/lit/n/float1.5"] = [@pl.col("n").fill_null(@pl.lit_float(1.5))]
  m["fill/lit/n/str"] = [@pl.col("n").fill_null(@pl.lit_str("x"))]
  m["fill/lit/n/bool"] = [@pl.col("n").fill_null(@pl.lit_bool(true))]
  m["fill/lit/n/null"] = [@pl.col("n").fill_null(@pl.lit(@pl.AnyValue::Null))]
  m["fill/lit/n/i64"] = [
    @pl.col("n").fill_null(@pl.lit(@pl.AnyValue::Int64(7L))),
  ]
  m["fill/lit/n/f32"] = [
    @pl.col("n").fill_null(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["fill/lit/n/date"] = [
    @pl.col("n").fill_null(@pl.lit(@pl.AnyValue::Date(5))),
  ]
  m["fill/lit/n/e0"] = [@pl.col("n").fill_null(@pl.lit_int(0L))]
  m["fill/col/i32/i64"] = [@pl.col("i32").fill_null(@pl.col("i64"))]
  m["fill/col/i32/f64"] = [@pl.col("i32").fill_null(@pl.col("f64"))]
  m["fill/col/i32/s"] = [@pl.col("i32").fill_null(@pl.col("s"))]
  m["fill/col/i32/b"] = [@pl.col("i32").fill_null(@pl.col("b"))]
  m["fill/col/i32/d"] = [@pl.col("i32").fill_null(@pl.col("d"))]
  m["fill/col/i32/n"] = [@pl.col("i32").fill_null(@pl.col("n"))]
  m["fill/col/i64/i32"] = [@pl.col("i64").fill_null(@pl.col("i32"))]
  m["fill/col/i64/f64"] = [@pl.col("i64").fill_null(@pl.col("f64"))]
  m["fill/col/i64/s"] = [@pl.col("i64").fill_null(@pl.col("s"))]
  m["fill/col/i64/b"] = [@pl.col("i64").fill_null(@pl.col("b"))]
  m["fill/col/i64/d"] = [@pl.col("i64").fill_null(@pl.col("d"))]
  m["fill/col/i64/n"] = [@pl.col("i64").fill_null(@pl.col("n"))]
  m["fill/col/f32/i32"] = [@pl.col("f32").fill_null(@pl.col("i32"))]
  m["fill/col/f32/i64"] = [@pl.col("f32").fill_null(@pl.col("i64"))]
  m["fill/col/f32/f64"] = [@pl.col("f32").fill_null(@pl.col("f64"))]
  m["fill/col/f32/s"] = [@pl.col("f32").fill_null(@pl.col("s"))]
  m["fill/col/f32/b"] = [@pl.col("f32").fill_null(@pl.col("b"))]
  m["fill/col/f32/d"] = [@pl.col("f32").fill_null(@pl.col("d"))]
  m["fill/col/f32/n"] = [@pl.col("f32").fill_null(@pl.col("n"))]
  m["fill/col/f64/i32"] = [@pl.col("f64").fill_null(@pl.col("i32"))]
  m["fill/col/f64/i64"] = [@pl.col("f64").fill_null(@pl.col("i64"))]
  m["fill/col/f64/s"] = [@pl.col("f64").fill_null(@pl.col("s"))]
  m["fill/col/f64/b"] = [@pl.col("f64").fill_null(@pl.col("b"))]
  m["fill/col/f64/d"] = [@pl.col("f64").fill_null(@pl.col("d"))]
  m["fill/col/f64/n"] = [@pl.col("f64").fill_null(@pl.col("n"))]
  m["fill/col/s/i32"] = [@pl.col("s").fill_null(@pl.col("i32"))]
  m["fill/col/s/i64"] = [@pl.col("s").fill_null(@pl.col("i64"))]
  m["fill/col/s/f64"] = [@pl.col("s").fill_null(@pl.col("f64"))]
  m["fill/col/s/b"] = [@pl.col("s").fill_null(@pl.col("b"))]
  m["fill/col/s/d"] = [@pl.col("s").fill_null(@pl.col("d"))]
  m["fill/col/s/n"] = [@pl.col("s").fill_null(@pl.col("n"))]
  m["fill/col/b/i32"] = [@pl.col("b").fill_null(@pl.col("i32"))]
  m["fill/col/b/i64"] = [@pl.col("b").fill_null(@pl.col("i64"))]
  m["fill/col/b/f64"] = [@pl.col("b").fill_null(@pl.col("f64"))]
  m["fill/col/b/s"] = [@pl.col("b").fill_null(@pl.col("s"))]
  m["fill/col/b/d"] = [@pl.col("b").fill_null(@pl.col("d"))]
  m["fill/col/b/n"] = [@pl.col("b").fill_null(@pl.col("n"))]
  m["fill/col/d/i32"] = [@pl.col("d").fill_null(@pl.col("i32"))]
  m["fill/col/d/i64"] = [@pl.col("d").fill_null(@pl.col("i64"))]
  m["fill/col/d/f64"] = [@pl.col("d").fill_null(@pl.col("f64"))]
}

///|
fn golden_expr_agg_cases_14(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["fill/col/d/s"] = [@pl.col("d").fill_null(@pl.col("s"))]
  m["fill/col/d/b"] = [@pl.col("d").fill_null(@pl.col("b"))]
  m["fill/col/d/n"] = [@pl.col("d").fill_null(@pl.col("n"))]
  m["fill/col/dt/i32"] = [@pl.col("dt").fill_null(@pl.col("i32"))]
  m["fill/col/dt/i64"] = [@pl.col("dt").fill_null(@pl.col("i64"))]
  m["fill/col/dt/f64"] = [@pl.col("dt").fill_null(@pl.col("f64"))]
  m["fill/col/dt/s"] = [@pl.col("dt").fill_null(@pl.col("s"))]
  m["fill/col/dt/b"] = [@pl.col("dt").fill_null(@pl.col("b"))]
  m["fill/col/dt/d"] = [@pl.col("dt").fill_null(@pl.col("d"))]
  m["fill/col/dt/n"] = [@pl.col("dt").fill_null(@pl.col("n"))]
  m["fill/col/n/i32"] = [@pl.col("n").fill_null(@pl.col("i32"))]
  m["fill/col/n/i64"] = [@pl.col("n").fill_null(@pl.col("i64"))]
  m["fill/col/n/f64"] = [@pl.col("n").fill_null(@pl.col("f64"))]
  m["fill/col/n/s"] = [@pl.col("n").fill_null(@pl.col("s"))]
  m["fill/col/n/b"] = [@pl.col("n").fill_null(@pl.col("b"))]
  m["fill/col/n/d"] = [@pl.col("n").fill_null(@pl.col("d"))]
  m["fill/agg"] = [@pl.col("i32").fill_null(@pl.col("i32").mean())]
  m["fill/agg-i64"] = [@pl.col("i64").fill_null(@pl.col("i64").min())]
  m["fill/agg-all-null"] = [@pl.col("i32").fill_null(@pl.col("n").first())]
  m["fill/agg-self"] = [@pl.col("n").max().fill_null(@pl.col("i32"))]
  m["fill/agg-self2"] = [@pl.col("i32").sum().fill_null(@pl.col("i64"))]
  m["fill/agg-agg"] = [@pl.col("n").first().fill_null(@pl.col("i32").sum())]
  m["fill/agg-agg/e0"] = [
    @pl.col("i32").first().fill_null(@pl.col("i64").sum()),
  ]
  m["fill/agg-self/e0"] = [@pl.col("i32").first().fill_null(@pl.col("i64"))]
  m["fill/e0-col"] = [@pl.col("i32").fill_null(@pl.col("i64"))]
  m["fill/expr"] = [
    (@pl.col("i32") + @pl.lit_int(1L)).fill_null(@pl.lit_int(0L)),
  ]
  m["fill/expr-both"] = [
    (@pl.col("i32") + @pl.lit_int(1L)).fill_null(
      @pl.col("i64") * @pl.lit_int(2L),
    ),
  ]
  m["fill/lit-lit"] = [@pl.lit_int(1L).fill_null(@pl.lit_int(2L))]
  m["fill/lit-date"] = [@pl.lit_int(1L).fill_null(@pl.col("d"))]
  m["fill/lit-dt"] = [@pl.lit_float(1.5).fill_null(@pl.col("dt"))]
  m["fill/lit-neg-date"] = [@pl.col("d").fill_null(-@pl.lit_int(1L))]
  m["fill/lit-alias-date"] = [
    @pl.col("d").fill_null(@pl.lit_int(1L).alias("q")),
  ]
  m["fill/lit-arith-date"] = [
    @pl.col("d").fill_null(@pl.lit_int(1L) + @pl.lit_int(2L)),
  ]
  m["fill/lit-strong-date"] = [
    @pl.col("d").fill_null(@pl.lit(@pl.AnyValue::Int32(0))),
  ]
  m["fill/lit-date-agg"] = [@pl.col("d").fill_null(@pl.col("d").min())]
  m["fill/lit-col"] = [@pl.lit_int(1L).fill_null(@pl.col("i32"))]
  m["fill/null-lit-col"] = [
    @pl.lit(@pl.AnyValue::Null).fill_null(@pl.col("i32")),
  ]
  m["fill/null-lit-lit"] = [
    @pl.lit(@pl.AnyValue::Null).fill_null(@pl.lit_int(1L)),
  ]
  m["fill/alias"] = [@pl.col("i32").fill_null(@pl.lit_int(0L)).alias("z")]
  m["fill/alias-value"] = [@pl.col("i32").fill_null(@pl.col("i64").alias("z"))]
  m["fill/cols"] = [@pl.cols(["i32", "i64"]).fill_null(@pl.lit_int(0L))]
  m["fill/all-lit"] = [@pl.all().fill_null(@pl.lit_float(0.5))]
  m["fill/cols-cols"] = [
    @pl.cols(["i32", "f32"]).fill_null(@pl.cols(["i64", "f64"])),
  ]
  m["fill/nan-kept"] = [@pl.col("f64").fill_null(@pl.lit_int(0L))]
  m["fill/missing"] = [@pl.col("i32").fill_null(@pl.col("zz"))]
  m["fill/missing-order"] = [@pl.col("zz1").fill_null(@pl.col("zz2"))]
  m["fill/wc"] = [@pl.col("i32").fill_null(@pl.lit_int(0L))]
  m["fill/wc-col"] = [@pl.col("i32").fill_null(@pl.col("i64")).alias("x")]
  m["fill/neg-lit"] = [@pl.col("i32").fill_null(-@pl.lit_int(1L))]
  m["fill/lit-arith"] = [
    @pl.col("i32").fill_null(@pl.lit_int(1L) + @pl.lit_int(2L)),
  ]
  m["fill/f32-1e300"] = [@pl.col("f32").fill_null(@pl.lit_float(1.0e300))]
  m["fill/i32-minus3e9"] = [@pl.col("i32").fill_null(@pl.lit_int(-3000000000L))]
  m["isin/i32/i32"] = [@pl.col("i32").is_in(vs["i32"])]
  m["isin/i32/i64"] = [@pl.col("i32").is_in(vs["i64"])]
  m["isin/i32/f32"] = [@pl.col("i32").is_in(vs["f32"])]
  m["isin/i32/f64"] = [@pl.col("i32").is_in(vs["f64"])]
  m["isin/i32/str"] = [@pl.col("i32").is_in(vs["str"])]
  m["isin/i32/bool"] = [@pl.col("i32").is_in(vs["bool"])]
  m["isin/i32/bool-f"] = [@pl.col("i32").is_in(vs["bool-f"])]
  m["isin/i32/date"] = [@pl.col("i32").is_in(vs["date"])]
}

///|
fn golden_expr_agg_cases_15(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["isin/i32/dt"] = [@pl.col("i32").is_in(vs["dt"])]
  m["isin/i32/null"] = [@pl.col("i32").is_in(vs["null"])]
  m["isin/i32/empty-i32"] = [@pl.col("i32").is_in(vs["empty-i32"])]
  m["isin/i32/empty-str"] = [@pl.col("i32").is_in(vs["empty-str"])]
  m["isin/i32/i32-unnamed"] = [@pl.col("i32").is_in(vs["i32-unnamed"])]
  m["isin/i32/i32-one"] = [@pl.col("i32").is_in(vs["i32-one"])]
  m["isin/i32/e0"] = [@pl.col("i32").is_in(vs["i32"])]
  m["isin/i64/i32"] = [@pl.col("i64").is_in(vs["i32"])]
  m["isin/i64/i64"] = [@pl.col("i64").is_in(vs["i64"])]
  m["isin/i64/f32"] = [@pl.col("i64").is_in(vs["f32"])]
  m["isin/i64/f64"] = [@pl.col("i64").is_in(vs["f64"])]
  m["isin/i64/str"] = [@pl.col("i64").is_in(vs["str"])]
  m["isin/i64/bool"] = [@pl.col("i64").is_in(vs["bool"])]
  m["isin/i64/bool-f"] = [@pl.col("i64").is_in(vs["bool-f"])]
  m["isin/i64/date"] = [@pl.col("i64").is_in(vs["date"])]
  m["isin/i64/dt"] = [@pl.col("i64").is_in(vs["dt"])]
  m["isin/i64/null"] = [@pl.col("i64").is_in(vs["null"])]
  m["isin/i64/empty-i32"] = [@pl.col("i64").is_in(vs["empty-i32"])]
  m["isin/i64/empty-str"] = [@pl.col("i64").is_in(vs["empty-str"])]
  m["isin/i64/i32-unnamed"] = [@pl.col("i64").is_in(vs["i32-unnamed"])]
  m["isin/i64/i32-one"] = [@pl.col("i64").is_in(vs["i32-one"])]
  m["isin/i64/e0"] = [@pl.col("i64").is_in(vs["i32"])]
  m["isin/f32/i32"] = [@pl.col("f32").is_in(vs["i32"])]
  m["isin/f32/i64"] = [@pl.col("f32").is_in(vs["i64"])]
  m["isin/f32/f32"] = [@pl.col("f32").is_in(vs["f32"])]
  m["isin/f32/f64"] = [@pl.col("f32").is_in(vs["f64"])]
  m["isin/f32/str"] = [@pl.col("f32").is_in(vs["str"])]
  m["isin/f32/bool"] = [@pl.col("f32").is_in(vs["bool"])]
  m["isin/f32/bool-f"] = [@pl.col("f32").is_in(vs["bool-f"])]
  m["isin/f32/date"] = [@pl.col("f32").is_in(vs["date"])]
  m["isin/f32/dt"] = [@pl.col("f32").is_in(vs["dt"])]
  m["isin/f32/null"] = [@pl.col("f32").is_in(vs["null"])]
  m["isin/f32/empty-i32"] = [@pl.col("f32").is_in(vs["empty-i32"])]
  m["isin/f32/empty-str"] = [@pl.col("f32").is_in(vs["empty-str"])]
  m["isin/f32/i32-unnamed"] = [@pl.col("f32").is_in(vs["i32-unnamed"])]
  m["isin/f32/i32-one"] = [@pl.col("f32").is_in(vs["i32-one"])]
  m["isin/f32/e0"] = [@pl.col("f32").is_in(vs["null"])]
  m["isin/f64/i32"] = [@pl.col("f64").is_in(vs["i32"])]
  m["isin/f64/i64"] = [@pl.col("f64").is_in(vs["i64"])]
  m["isin/f64/f32"] = [@pl.col("f64").is_in(vs["f32"])]
  m["isin/f64/f64"] = [@pl.col("f64").is_in(vs["f64"])]
  m["isin/f64/str"] = [@pl.col("f64").is_in(vs["str"])]
  m["isin/f64/bool"] = [@pl.col("f64").is_in(vs["bool"])]
  m["isin/f64/bool-f"] = [@pl.col("f64").is_in(vs["bool-f"])]
  m["isin/f64/date"] = [@pl.col("f64").is_in(vs["date"])]
  m["isin/f64/dt"] = [@pl.col("f64").is_in(vs["dt"])]
  m["isin/f64/null"] = [@pl.col("f64").is_in(vs["null"])]
  m["isin/f64/empty-i32"] = [@pl.col("f64").is_in(vs["empty-i32"])]
  m["isin/f64/empty-str"] = [@pl.col("f64").is_in(vs["empty-str"])]
  m["isin/f64/i32-unnamed"] = [@pl.col("f64").is_in(vs["i32-unnamed"])]
  m["isin/f64/i32-one"] = [@pl.col("f64").is_in(vs["i32-one"])]
  m["isin/f64/e0"] = [@pl.col("f64").is_in(vs["null"])]
  m["isin/s/i32"] = [@pl.col("s").is_in(vs["i32"])]
  m["isin/s/i64"] = [@pl.col("s").is_in(vs["i64"])]
  m["isin/s/f32"] = [@pl.col("s").is_in(vs["f32"])]
  m["isin/s/f64"] = [@pl.col("s").is_in(vs["f64"])]
  m["isin/s/str"] = [@pl.col("s").is_in(vs["str"])]
  m["isin/s/bool"] = [@pl.col("s").is_in(vs["bool"])]
  m["isin/s/bool-f"] = [@pl.col("s").is_in(vs["bool-f"])]
  m["isin/s/date"] = [@pl.col("s").is_in(vs["date"])]
}

///|
fn golden_expr_agg_cases_16(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["isin/s/dt"] = [@pl.col("s").is_in(vs["dt"])]
  m["isin/s/null"] = [@pl.col("s").is_in(vs["null"])]
  m["isin/s/empty-i32"] = [@pl.col("s").is_in(vs["empty-i32"])]
  m["isin/s/empty-str"] = [@pl.col("s").is_in(vs["empty-str"])]
  m["isin/s/i32-unnamed"] = [@pl.col("s").is_in(vs["i32-unnamed"])]
  m["isin/s/i32-one"] = [@pl.col("s").is_in(vs["i32-one"])]
  m["isin/s/e0"] = [@pl.col("s").is_in(vs["null"])]
  m["isin/b/i32"] = [@pl.col("b").is_in(vs["i32"])]
  m["isin/b/i64"] = [@pl.col("b").is_in(vs["i64"])]
  m["isin/b/f32"] = [@pl.col("b").is_in(vs["f32"])]
  m["isin/b/f64"] = [@pl.col("b").is_in(vs["f64"])]
  m["isin/b/str"] = [@pl.col("b").is_in(vs["str"])]
  m["isin/b/bool"] = [@pl.col("b").is_in(vs["bool"])]
  m["isin/b/bool-f"] = [@pl.col("b").is_in(vs["bool-f"])]
  m["isin/b/date"] = [@pl.col("b").is_in(vs["date"])]
  m["isin/b/dt"] = [@pl.col("b").is_in(vs["dt"])]
  m["isin/b/null"] = [@pl.col("b").is_in(vs["null"])]
  m["isin/b/empty-i32"] = [@pl.col("b").is_in(vs["empty-i32"])]
  m["isin/b/empty-str"] = [@pl.col("b").is_in(vs["empty-str"])]
  m["isin/b/i32-unnamed"] = [@pl.col("b").is_in(vs["i32-unnamed"])]
  m["isin/b/i32-one"] = [@pl.col("b").is_in(vs["i32-one"])]
  m["isin/b/e0"] = [@pl.col("b").is_in(vs["null"])]
  m["isin/d/i32"] = [@pl.col("d").is_in(vs["i32"])]
  m["isin/d/i64"] = [@pl.col("d").is_in(vs["i64"])]
  m["isin/d/f32"] = [@pl.col("d").is_in(vs["f32"])]
  m["isin/d/f64"] = [@pl.col("d").is_in(vs["f64"])]
  m["isin/d/str"] = [@pl.col("d").is_in(vs["str"])]
  m["isin/d/bool"] = [@pl.col("d").is_in(vs["bool"])]
  m["isin/d/bool-f"] = [@pl.col("d").is_in(vs["bool-f"])]
  m["isin/d/date"] = [@pl.col("d").is_in(vs["date"])]
  m["isin/d/dt"] = [@pl.col("d").is_in(vs["dt"])]
  m["isin/d/null"] = [@pl.col("d").is_in(vs["null"])]
  m["isin/d/empty-i32"] = [@pl.col("d").is_in(vs["empty-i32"])]
  m["isin/d/empty-str"] = [@pl.col("d").is_in(vs["empty-str"])]
  m["isin/d/i32-unnamed"] = [@pl.col("d").is_in(vs["i32-unnamed"])]
  m["isin/d/i32-one"] = [@pl.col("d").is_in(vs["i32-one"])]
  m["isin/d/e0"] = [@pl.col("d").is_in(vs["null"])]
  m["isin/dt/i32"] = [@pl.col("dt").is_in(vs["i32"])]
  m["isin/dt/i64"] = [@pl.col("dt").is_in(vs["i64"])]
  m["isin/dt/f32"] = [@pl.col("dt").is_in(vs["f32"])]
  m["isin/dt/f64"] = [@pl.col("dt").is_in(vs["f64"])]
  m["isin/dt/str"] = [@pl.col("dt").is_in(vs["str"])]
  m["isin/dt/bool"] = [@pl.col("dt").is_in(vs["bool"])]
  m["isin/dt/bool-f"] = [@pl.col("dt").is_in(vs["bool-f"])]
  m["isin/dt/date"] = [@pl.col("dt").is_in(vs["date"])]
  m["isin/dt/dt"] = [@pl.col("dt").is_in(vs["dt"])]
  m["isin/dt/null"] = [@pl.col("dt").is_in(vs["null"])]
  m["isin/dt/empty-i32"] = [@pl.col("dt").is_in(vs["empty-i32"])]
  m["isin/dt/empty-str"] = [@pl.col("dt").is_in(vs["empty-str"])]
  m["isin/dt/i32-unnamed"] = [@pl.col("dt").is_in(vs["i32-unnamed"])]
  m["isin/dt/i32-one"] = [@pl.col("dt").is_in(vs["i32-one"])]
  m["isin/dt/e0"] = [@pl.col("dt").is_in(vs["null"])]
  m["isin/n/i32"] = [@pl.col("n").is_in(vs["i32"])]
  m["isin/n/i64"] = [@pl.col("n").is_in(vs["i64"])]
  m["isin/n/f32"] = [@pl.col("n").is_in(vs["f32"])]
  m["isin/n/f64"] = [@pl.col("n").is_in(vs["f64"])]
  m["isin/n/str"] = [@pl.col("n").is_in(vs["str"])]
  m["isin/n/bool"] = [@pl.col("n").is_in(vs["bool"])]
  m["isin/n/bool-f"] = [@pl.col("n").is_in(vs["bool-f"])]
  m["isin/n/date"] = [@pl.col("n").is_in(vs["date"])]
}

///|
fn golden_expr_agg_cases_17(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["isin/n/dt"] = [@pl.col("n").is_in(vs["dt"])]
  m["isin/n/null"] = [@pl.col("n").is_in(vs["null"])]
  m["isin/n/empty-i32"] = [@pl.col("n").is_in(vs["empty-i32"])]
  m["isin/n/empty-str"] = [@pl.col("n").is_in(vs["empty-str"])]
  m["isin/n/i32-unnamed"] = [@pl.col("n").is_in(vs["i32-unnamed"])]
  m["isin/n/i32-one"] = [@pl.col("n").is_in(vs["i32-one"])]
  m["isin/n/e0"] = [@pl.col("n").is_in(vs["null"])]
  m["isin/expr"] = [(@pl.col("i32") + @pl.lit_int(1L)).is_in(vs["i32"])]
  m["isin/agg"] = [@pl.col("i32").max().is_in(vs["i32"])]
  m["isin/lit-int"] = [@pl.lit_int(7L).is_in(vs["i32"])]
  m["isin/lit-str"] = [@pl.lit_str("a").is_in(vs["str"])]
  m["isin/alias"] = [@pl.col("i32").is_in(vs["i32"]).alias("z")]
  m["isin/cols"] = [@pl.cols(["i32", "i64"]).is_in(vs["i32"])]
  m["isin/not"] = [@pl.col("i32").is_in(vs["i32"]).not_()]
  m["isin/and"] = [
    @pl.col("i32").is_in(vs["i32"]) & @pl.col("i64").is_in(vs["i64"]),
  ]
  m["isin/missing"] = [@pl.col("zz").is_in(vs["i32"])]
  m["isin/wc"] = [@pl.col("i32").is_in(vs["i32"]).alias("x")]
  m["btw/i32/int"] = [
    @pl.col("i32").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i32/int-wide"] = [
    @pl.col("i32").between(
      @pl.lit_int(-3000000000L),
      @pl.lit_int(3000000000L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i32/float"] = [
    @pl.col("i32").between(
      @pl.lit_float(-1.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i32/float-big"] = [
    @pl.col("i32").between(
      @pl.lit_float(-1.0e300),
      @pl.lit_float(1.0e300),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i32/str"] = [
    @pl.col("i32").between(
      @pl.lit_str("A"),
      @pl.lit_str("a"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i32/swapped"] = [
    @pl.col("i32").between(
      @pl.lit_int(7L),
      @pl.lit_int(0L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i32/bool"] = [
    @pl.col("i32").between(
      @pl.lit_bool(false),
      @pl.lit_bool(true),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i32/same"] = [
    @pl.col("i32").between(
      @pl.lit_int(1L),
      @pl.lit_int(1L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i32/e0"] = [
    @pl.col("i32").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i64/int"] = [
    @pl.col("i64").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i64/int-wide"] = [
    @pl.col("i64").between(
      @pl.lit_int(-3000000000L),
      @pl.lit_int(3000000000L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i64/float"] = [
    @pl.col("i64").between(
      @pl.lit_float(-1.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i64/float-big"] = [
    @pl.col("i64").between(
      @pl.lit_float(-1.0e300),
      @pl.lit_float(1.0e300),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i64/str"] = [
    @pl.col("i64").between(
      @pl.lit_str("A"),
      @pl.lit_str("a"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i64/swapped"] = [
    @pl.col("i64").between(
      @pl.lit_int(7L),
      @pl.lit_int(0L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i64/bool"] = [
    @pl.col("i64").between(
      @pl.lit_bool(false),
      @pl.lit_bool(true),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i64/same"] = [
    @pl.col("i64").between(
      @pl.lit_int(1L),
      @pl.lit_int(1L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i64/e0"] = [
    @pl.col("i64").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f32/int"] = [
    @pl.col("f32").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f32/int-wide"] = [
    @pl.col("f32").between(
      @pl.lit_int(-3000000000L),
      @pl.lit_int(3000000000L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f32/float"] = [
    @pl.col("f32").between(
      @pl.lit_float(-1.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f32/float-big"] = [
    @pl.col("f32").between(
      @pl.lit_float(-1.0e300),
      @pl.lit_float(1.0e300),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f32/str"] = [
    @pl.col("f32").between(
      @pl.lit_str("A"),
      @pl.lit_str("a"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f32/swapped"] = [
    @pl.col("f32").between(
      @pl.lit_int(7L),
      @pl.lit_int(0L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f32/bool"] = [
    @pl.col("f32").between(
      @pl.lit_bool(false),
      @pl.lit_bool(true),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f32/same"] = [
    @pl.col("f32").between(
      @pl.lit_int(1L),
      @pl.lit_int(1L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f32/e0"] = [
    @pl.col("f32").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f64/int"] = [
    @pl.col("f64").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f64/int-wide"] = [
    @pl.col("f64").between(
      @pl.lit_int(-3000000000L),
      @pl.lit_int(3000000000L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f64/float"] = [
    @pl.col("f64").between(
      @pl.lit_float(-1.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f64/float-big"] = [
    @pl.col("f64").between(
      @pl.lit_float(-1.0e300),
      @pl.lit_float(1.0e300),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f64/str"] = [
    @pl.col("f64").between(
      @pl.lit_str("A"),
      @pl.lit_str("a"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f64/swapped"] = [
    @pl.col("f64").between(
      @pl.lit_int(7L),
      @pl.lit_int(0L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f64/bool"] = [
    @pl.col("f64").between(
      @pl.lit_bool(false),
      @pl.lit_bool(true),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f64/same"] = [
    @pl.col("f64").between(
      @pl.lit_int(1L),
      @pl.lit_int(1L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f64/e0"] = [
    @pl.col("f64").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/s/int"] = [
    @pl.col("s").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/s/int-wide"] = [
    @pl.col("s").between(
      @pl.lit_int(-3000000000L),
      @pl.lit_int(3000000000L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/s/float"] = [
    @pl.col("s").between(
      @pl.lit_float(-1.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/s/float-big"] = [
    @pl.col("s").between(
      @pl.lit_float(-1.0e300),
      @pl.lit_float(1.0e300),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/s/str"] = [
    @pl.col("s").between(
      @pl.lit_str("A"),
      @pl.lit_str("a"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/s/swapped"] = [
    @pl.col("s").between(
      @pl.lit_int(7L),
      @pl.lit_int(0L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/s/bool"] = [
    @pl.col("s").between(
      @pl.lit_bool(false),
      @pl.lit_bool(true),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
}

///|
fn golden_expr_agg_cases_18(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["btw/s/same"] = [
    @pl.col("s").between(
      @pl.lit_int(1L),
      @pl.lit_int(1L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/s/e0"] = [
    @pl.col("s").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/b/int"] = [
    @pl.col("b").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/b/int-wide"] = [
    @pl.col("b").between(
      @pl.lit_int(-3000000000L),
      @pl.lit_int(3000000000L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/b/float"] = [
    @pl.col("b").between(
      @pl.lit_float(-1.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/b/float-big"] = [
    @pl.col("b").between(
      @pl.lit_float(-1.0e300),
      @pl.lit_float(1.0e300),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/b/str"] = [
    @pl.col("b").between(
      @pl.lit_str("A"),
      @pl.lit_str("a"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/b/swapped"] = [
    @pl.col("b").between(
      @pl.lit_int(7L),
      @pl.lit_int(0L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/b/bool"] = [
    @pl.col("b").between(
      @pl.lit_bool(false),
      @pl.lit_bool(true),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/b/same"] = [
    @pl.col("b").between(
      @pl.lit_int(1L),
      @pl.lit_int(1L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/b/e0"] = [
    @pl.col("b").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/d/int"] = [
    @pl.col("d").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/d/int-wide"] = [
    @pl.col("d").between(
      @pl.lit_int(-3000000000L),
      @pl.lit_int(3000000000L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/d/float"] = [
    @pl.col("d").between(
      @pl.lit_float(-1.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/d/float-big"] = [
    @pl.col("d").between(
      @pl.lit_float(-1.0e300),
      @pl.lit_float(1.0e300),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/d/str"] = [
    @pl.col("d").between(
      @pl.lit_str("A"),
      @pl.lit_str("a"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/d/swapped"] = [
    @pl.col("d").between(
      @pl.lit_int(7L),
      @pl.lit_int(0L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/d/bool"] = [
    @pl.col("d").between(
      @pl.lit_bool(false),
      @pl.lit_bool(true),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/d/same"] = [
    @pl.col("d").between(
      @pl.lit_int(1L),
      @pl.lit_int(1L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/d/e0"] = [
    @pl.col("d").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/dt/int"] = [
    @pl.col("dt").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/dt/int-wide"] = [
    @pl.col("dt").between(
      @pl.lit_int(-3000000000L),
      @pl.lit_int(3000000000L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/dt/float"] = [
    @pl.col("dt").between(
      @pl.lit_float(-1.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/dt/float-big"] = [
    @pl.col("dt").between(
      @pl.lit_float(-1.0e300),
      @pl.lit_float(1.0e300),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/dt/str"] = [
    @pl.col("dt").between(
      @pl.lit_str("A"),
      @pl.lit_str("a"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/dt/swapped"] = [
    @pl.col("dt").between(
      @pl.lit_int(7L),
      @pl.lit_int(0L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/dt/bool"] = [
    @pl.col("dt").between(
      @pl.lit_bool(false),
      @pl.lit_bool(true),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/dt/same"] = [
    @pl.col("dt").between(
      @pl.lit_int(1L),
      @pl.lit_int(1L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/dt/e0"] = [
    @pl.col("dt").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/n/int"] = [
    @pl.col("n").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/n/int-wide"] = [
    @pl.col("n").between(
      @pl.lit_int(-3000000000L),
      @pl.lit_int(3000000000L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/n/float"] = [
    @pl.col("n").between(
      @pl.lit_float(-1.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/n/float-big"] = [
    @pl.col("n").between(
      @pl.lit_float(-1.0e300),
      @pl.lit_float(1.0e300),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/n/str"] = [
    @pl.col("n").between(
      @pl.lit_str("A"),
      @pl.lit_str("a"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/n/swapped"] = [
    @pl.col("n").between(
      @pl.lit_int(7L),
      @pl.lit_int(0L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/n/bool"] = [
    @pl.col("n").between(
      @pl.lit_bool(false),
      @pl.lit_bool(true),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/n/same"] = [
    @pl.col("n").between(
      @pl.lit_int(1L),
      @pl.lit_int(1L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/n/e0"] = [
    @pl.col("n").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-closed/both/i32"] = [
    @pl.col("i32").between(
      @pl.col("i32"),
      @pl.col("i32"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-closed/both/i64"] = [
    @pl.col("i64").between(
      @pl.col("i64"),
      @pl.col("i64"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-closed/both/f32"] = [
    @pl.col("f32").between(
      @pl.col("f32"),
      @pl.col("f32"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-closed/both/f64"] = [
    @pl.col("f64").between(
      @pl.col("f64"),
      @pl.col("f64"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-closed/both/s"] = [
    @pl.col("s").between(
      @pl.col("s"),
      @pl.col("s"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-closed/both/d"] = [
    @pl.col("d").between(
      @pl.col("d"),
      @pl.col("d"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-closed/both/lit"] = [
    @pl.col("i32").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-closed/both/f64-lit"] = [
    @pl.col("f64").between(
      @pl.lit_float(-0.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-closed/left/i32"] = [
    @pl.col("i32").between(
      @pl.col("i32"),
      @pl.col("i32"),
      closed=@pl.ClosedInterval::Left,
    ),
  ]
  m["btw-closed/left/i64"] = [
    @pl.col("i64").between(
      @pl.col("i64"),
      @pl.col("i64"),
      closed=@pl.ClosedInterval::Left,
    ),
  ]
  m["btw-closed/left/f32"] = [
    @pl.col("f32").between(
      @pl.col("f32"),
      @pl.col("f32"),
      closed=@pl.ClosedInterval::Left,
    ),
  ]
  m["btw-closed/left/f64"] = [
    @pl.col("f64").between(
      @pl.col("f64"),
      @pl.col("f64"),
      closed=@pl.ClosedInterval::Left,
    ),
  ]
  m["btw-closed/left/s"] = [
    @pl.col("s").between(
      @pl.col("s"),
      @pl.col("s"),
      closed=@pl.ClosedInterval::Left,
    ),
  ]
  m["btw-closed/left/d"] = [
    @pl.col("d").between(
      @pl.col("d"),
      @pl.col("d"),
      closed=@pl.ClosedInterval::Left,
    ),
  ]
  m["btw-closed/left/lit"] = [
    @pl.col("i32").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Left,
    ),
  ]
  m["btw-closed/left/f64-lit"] = [
    @pl.col("f64").between(
      @pl.lit_float(-0.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Left,
    ),
  ]
  m["btw-closed/right/i32"] = [
    @pl.col("i32").between(
      @pl.col("i32"),
      @pl.col("i32"),
      closed=@pl.ClosedInterval::Right,
    ),
  ]
  m["btw-closed/right/i64"] = [
    @pl.col("i64").between(
      @pl.col("i64"),
      @pl.col("i64"),
      closed=@pl.ClosedInterval::Right,
    ),
  ]
  m["btw-closed/right/f32"] = [
    @pl.col("f32").between(
      @pl.col("f32"),
      @pl.col("f32"),
      closed=@pl.ClosedInterval::Right,
    ),
  ]
  m["btw-closed/right/f64"] = [
    @pl.col("f64").between(
      @pl.col("f64"),
      @pl.col("f64"),
      closed=@pl.ClosedInterval::Right,
    ),
  ]
  m["btw-closed/right/s"] = [
    @pl.col("s").between(
      @pl.col("s"),
      @pl.col("s"),
      closed=@pl.ClosedInterval::Right,
    ),
  ]
  m["btw-closed/right/d"] = [
    @pl.col("d").between(
      @pl.col("d"),
      @pl.col("d"),
      closed=@pl.ClosedInterval::Right,
    ),
  ]
}

///|
fn golden_expr_agg_cases_19(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["btw-closed/right/lit"] = [
    @pl.col("i32").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Right,
    ),
  ]
  m["btw-closed/right/f64-lit"] = [
    @pl.col("f64").between(
      @pl.lit_float(-0.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Right,
    ),
  ]
  m["btw-closed/none/i32"] = [
    @pl.col("i32").between(
      @pl.col("i32"),
      @pl.col("i32"),
      closed=@pl.ClosedInterval::Neither,
    ),
  ]
  m["btw-closed/none/i64"] = [
    @pl.col("i64").between(
      @pl.col("i64"),
      @pl.col("i64"),
      closed=@pl.ClosedInterval::Neither,
    ),
  ]
  m["btw-closed/none/f32"] = [
    @pl.col("f32").between(
      @pl.col("f32"),
      @pl.col("f32"),
      closed=@pl.ClosedInterval::Neither,
    ),
  ]
  m["btw-closed/none/f64"] = [
    @pl.col("f64").between(
      @pl.col("f64"),
      @pl.col("f64"),
      closed=@pl.ClosedInterval::Neither,
    ),
  ]
  m["btw-closed/none/s"] = [
    @pl.col("s").between(
      @pl.col("s"),
      @pl.col("s"),
      closed=@pl.ClosedInterval::Neither,
    ),
  ]
  m["btw-closed/none/d"] = [
    @pl.col("d").between(
      @pl.col("d"),
      @pl.col("d"),
      closed=@pl.ClosedInterval::Neither,
    ),
  ]
  m["btw-closed/none/lit"] = [
    @pl.col("i32").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Neither,
    ),
  ]
  m["btw-closed/none/f64-lit"] = [
    @pl.col("f64").between(
      @pl.lit_float(-0.0),
      @pl.lit_float(2.5),
      closed=@pl.ClosedInterval::Neither,
    ),
  ]
  m["btw-col/i32/i64/f64"] = [
    @pl.col("i32").between(
      @pl.col("i64"),
      @pl.col("f64"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/i64/i32/i32"] = [
    @pl.col("i64").between(
      @pl.col("i32"),
      @pl.col("i32"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/f32/f64/i64"] = [
    @pl.col("f32").between(
      @pl.col("f64"),
      @pl.col("i64"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/s/s/s"] = [
    @pl.col("s").between(
      @pl.col("s"),
      @pl.col("s"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/d/dt/dt"] = [
    @pl.col("d").between(
      @pl.col("dt"),
      @pl.col("dt"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/dt/d/d"] = [
    @pl.col("dt").between(
      @pl.col("d"),
      @pl.col("d"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/b/i32/i64"] = [
    @pl.col("b").between(
      @pl.col("i32"),
      @pl.col("i64"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/n/n/n"] = [
    @pl.col("n").between(
      @pl.col("n"),
      @pl.col("n"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/i32/n/i64"] = [
    @pl.col("i32").between(
      @pl.col("n"),
      @pl.col("i64"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/s/d/d"] = [
    @pl.col("s").between(
      @pl.col("d"),
      @pl.col("d"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/d/s/s"] = [
    @pl.col("d").between(
      @pl.col("s"),
      @pl.col("s"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/s/i32/i32"] = [
    @pl.col("s").between(
      @pl.col("i32"),
      @pl.col("i32"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/b/d/d"] = [
    @pl.col("b").between(
      @pl.col("d"),
      @pl.col("d"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw-col/f64/f64/f32"] = [
    @pl.col("f64").between(
      @pl.col("f64"),
      @pl.col("f32"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/agg-bounds"] = [
    @pl.col("i32").between(
      @pl.col("i32").min(),
      @pl.col("i32").max(),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/agg-bounds-f64"] = [
    @pl.col("f64").between(
      @pl.col("f64").min(),
      @pl.col("f64").max(),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/lit-value"] = [
    @pl.lit_int(2L).between(
      @pl.col("i32"),
      @pl.col("i64"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/lit-value-all-lit"] = [
    @pl.lit_int(2L).between(
      @pl.lit_int(1L),
      @pl.lit_int(3L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/alias"] = [
    @pl.col("i32")
    .between(@pl.lit_int(0L), @pl.lit_int(7L), closed=@pl.ClosedInterval::Both)
    .alias("z"),
  ]
  m["btw/expr"] = [
    (@pl.col("i32") + @pl.lit_int(1L)).between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/not"] = [
    @pl.col("i32")
    .between(@pl.lit_int(0L), @pl.lit_int(7L), closed=@pl.ClosedInterval::Both)
    .not_(),
  ]
  m["btw/cols"] = [
    @pl.cols(["i32", "i64"]).between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/all"] = [
    @pl.all().between(
      @pl.lit_float(0.0),
      @pl.lit_float(3.0),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/and"] = [
    @pl.col("i32").between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ) &
    @pl.col("f64").between(
      @pl.lit_float(0.0),
      @pl.lit_float(3.0),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/missing"] = [
    @pl.col("i32").between(
      @pl.col("zz"),
      @pl.lit_int(1L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/missing-order"] = [
    @pl.col("zz1").between(
      @pl.col("zz2"),
      @pl.col("zz3"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/missing-order2"] = [
    @pl.col("i32").between(
      @pl.col("zz2"),
      @pl.col("zz3"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i32/null-both"] = [
    @pl.col("i32").between(
      @pl.lit(@pl.AnyValue::Null),
      @pl.lit(@pl.AnyValue::Null),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i32/null-col-lo"] = [
    @pl.col("i32").between(
      @pl.col("n"),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f64/null-both"] = [
    @pl.col("f64").between(
      @pl.lit(@pl.AnyValue::Null),
      @pl.lit(@pl.AnyValue::Null),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/f64/null-col-lo"] = [
    @pl.col("f64").between(
      @pl.col("n"),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/s/null-both"] = [
    @pl.col("s").between(
      @pl.lit(@pl.AnyValue::Null),
      @pl.lit(@pl.AnyValue::Null),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/s/null-col-lo"] = [
    @pl.col("s").between(
      @pl.col("n"),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/d/null-both"] = [
    @pl.col("d").between(
      @pl.lit(@pl.AnyValue::Null),
      @pl.lit(@pl.AnyValue::Null),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/d/null-col-lo"] = [
    @pl.col("d").between(
      @pl.col("n"),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/i32/typed-null-lo"] = [
    @pl.col("i32").between(
      @pl.lit(@pl.AnyValue::Null),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/null-lit-value"] = [
    @pl.lit(@pl.AnyValue::Null).between(
      @pl.lit_int(0L),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/null-lit-cast"] = [
    @pl.col("i32").between(
      @pl.lit(@pl.AnyValue::Null).cast(@pl.DataType::Int32),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/null-lit-e0"] = [
    @pl.col("i32").between(
      @pl.lit(@pl.AnyValue::Null),
      @pl.lit_int(7L),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["btw/wc"] = [
    @pl.col("i32")
    .between(@pl.lit_int(0L), @pl.lit_int(7L), closed=@pl.ClosedInterval::Both)
    .alias("x"),
  ]
  m["when/types/i32/i64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("i64")),
  ]
  m["when/types/i32/f32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("f32")),
  ]
  m["when/types/i32/f64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("f64")),
  ]
  m["when/types/i32/s"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("s")),
  ]
  m["when/types/i32/b"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("b")),
  ]
  m["when/types/i32/d"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("d")),
  ]
  m["when/types/i32/dt"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("dt")),
  ]
  m["when/types/i32/n"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("n")),
  ]
  m["when/types/i64/i32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i64")).otherwise(@pl.col("i32")),
  ]
  m["when/types/i64/f32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i64")).otherwise(@pl.col("f32")),
  ]
}

///|
fn golden_expr_agg_cases_20(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["when/types/i64/f64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i64")).otherwise(@pl.col("f64")),
  ]
  m["when/types/i64/s"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i64")).otherwise(@pl.col("s")),
  ]
  m["when/types/i64/b"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i64")).otherwise(@pl.col("b")),
  ]
  m["when/types/i64/d"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i64")).otherwise(@pl.col("d")),
  ]
  m["when/types/i64/dt"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i64")).otherwise(@pl.col("dt")),
  ]
  m["when/types/i64/n"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i64")).otherwise(@pl.col("n")),
  ]
  m["when/types/f32/i32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f32")).otherwise(@pl.col("i32")),
  ]
  m["when/types/f32/i64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f32")).otherwise(@pl.col("i64")),
  ]
  m["when/types/f32/f64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f32")).otherwise(@pl.col("f64")),
  ]
  m["when/types/f32/s"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f32")).otherwise(@pl.col("s")),
  ]
  m["when/types/f32/b"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f32")).otherwise(@pl.col("b")),
  ]
  m["when/types/f32/d"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f32")).otherwise(@pl.col("d")),
  ]
  m["when/types/f32/dt"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f32")).otherwise(@pl.col("dt")),
  ]
  m["when/types/f32/n"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f32")).otherwise(@pl.col("n")),
  ]
  m["when/types/f64/i32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f64")).otherwise(@pl.col("i32")),
  ]
  m["when/types/f64/i64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f64")).otherwise(@pl.col("i64")),
  ]
  m["when/types/f64/f32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f64")).otherwise(@pl.col("f32")),
  ]
  m["when/types/f64/s"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f64")).otherwise(@pl.col("s")),
  ]
  m["when/types/f64/b"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f64")).otherwise(@pl.col("b")),
  ]
  m["when/types/f64/d"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f64")).otherwise(@pl.col("d")),
  ]
  m["when/types/f64/dt"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f64")).otherwise(@pl.col("dt")),
  ]
  m["when/types/f64/n"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f64")).otherwise(@pl.col("n")),
  ]
  m["when/types/s/i32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("s")).otherwise(@pl.col("i32")),
  ]
  m["when/types/s/i64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("s")).otherwise(@pl.col("i64")),
  ]
  m["when/types/s/f32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("s")).otherwise(@pl.col("f32")),
  ]
  m["when/types/s/f64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("s")).otherwise(@pl.col("f64")),
  ]
  m["when/types/s/b"] = [
    @pl.when(@pl.col("b")).then(@pl.col("s")).otherwise(@pl.col("b")),
  ]
  m["when/types/s/d"] = [
    @pl.when(@pl.col("b")).then(@pl.col("s")).otherwise(@pl.col("d")),
  ]
  m["when/types/s/dt"] = [
    @pl.when(@pl.col("b")).then(@pl.col("s")).otherwise(@pl.col("dt")),
  ]
  m["when/types/s/n"] = [
    @pl.when(@pl.col("b")).then(@pl.col("s")).otherwise(@pl.col("n")),
  ]
  m["when/types/b/i32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("b")).otherwise(@pl.col("i32")),
  ]
  m["when/types/b/i64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("b")).otherwise(@pl.col("i64")),
  ]
  m["when/types/b/f32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("b")).otherwise(@pl.col("f32")),
  ]
  m["when/types/b/f64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("b")).otherwise(@pl.col("f64")),
  ]
  m["when/types/b/s"] = [
    @pl.when(@pl.col("b")).then(@pl.col("b")).otherwise(@pl.col("s")),
  ]
  m["when/types/b/d"] = [
    @pl.when(@pl.col("b")).then(@pl.col("b")).otherwise(@pl.col("d")),
  ]
  m["when/types/b/dt"] = [
    @pl.when(@pl.col("b")).then(@pl.col("b")).otherwise(@pl.col("dt")),
  ]
  m["when/types/b/n"] = [
    @pl.when(@pl.col("b")).then(@pl.col("b")).otherwise(@pl.col("n")),
  ]
  m["when/types/d/i32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("d")).otherwise(@pl.col("i32")),
  ]
  m["when/types/d/i64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("d")).otherwise(@pl.col("i64")),
  ]
  m["when/types/d/f32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("d")).otherwise(@pl.col("f32")),
  ]
  m["when/types/d/f64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("d")).otherwise(@pl.col("f64")),
  ]
  m["when/types/d/s"] = [
    @pl.when(@pl.col("b")).then(@pl.col("d")).otherwise(@pl.col("s")),
  ]
  m["when/types/d/b"] = [
    @pl.when(@pl.col("b")).then(@pl.col("d")).otherwise(@pl.col("b")),
  ]
  m["when/types/d/dt"] = [
    @pl.when(@pl.col("b")).then(@pl.col("d")).otherwise(@pl.col("dt")),
  ]
  m["when/types/d/n"] = [
    @pl.when(@pl.col("b")).then(@pl.col("d")).otherwise(@pl.col("n")),
  ]
  m["when/types/dt/i32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("dt")).otherwise(@pl.col("i32")),
  ]
  m["when/types/dt/i64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("dt")).otherwise(@pl.col("i64")),
  ]
  m["when/types/dt/f32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("dt")).otherwise(@pl.col("f32")),
  ]
  m["when/types/dt/f64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("dt")).otherwise(@pl.col("f64")),
  ]
  m["when/types/dt/s"] = [
    @pl.when(@pl.col("b")).then(@pl.col("dt")).otherwise(@pl.col("s")),
  ]
  m["when/types/dt/b"] = [
    @pl.when(@pl.col("b")).then(@pl.col("dt")).otherwise(@pl.col("b")),
  ]
  m["when/types/dt/d"] = [
    @pl.when(@pl.col("b")).then(@pl.col("dt")).otherwise(@pl.col("d")),
  ]
  m["when/types/dt/n"] = [
    @pl.when(@pl.col("b")).then(@pl.col("dt")).otherwise(@pl.col("n")),
  ]
  m["when/types/n/i32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("n")).otherwise(@pl.col("i32")),
  ]
  m["when/types/n/i64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("n")).otherwise(@pl.col("i64")),
  ]
  m["when/types/n/f32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("n")).otherwise(@pl.col("f32")),
  ]
  m["when/types/n/f64"] = [
    @pl.when(@pl.col("b")).then(@pl.col("n")).otherwise(@pl.col("f64")),
  ]
  m["when/types/n/s"] = [
    @pl.when(@pl.col("b")).then(@pl.col("n")).otherwise(@pl.col("s")),
  ]
  m["when/types/n/b"] = [
    @pl.when(@pl.col("b")).then(@pl.col("n")).otherwise(@pl.col("b")),
  ]
}

///|
fn golden_expr_agg_cases_21(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["when/types/n/d"] = [
    @pl.when(@pl.col("b")).then(@pl.col("n")).otherwise(@pl.col("d")),
  ]
  m["when/types/n/dt"] = [
    @pl.when(@pl.col("b")).then(@pl.col("n")).otherwise(@pl.col("dt")),
  ]
  m["when/cond/i32"] = [
    @pl.when(@pl.col("i32")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/cond/i64"] = [
    @pl.when(@pl.col("i64")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/cond/f32"] = [
    @pl.when(@pl.col("f32")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/cond/f64"] = [
    @pl.when(@pl.col("f64")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/cond/s"] = [
    @pl.when(@pl.col("s")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/cond/b"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/cond/d"] = [
    @pl.when(@pl.col("d")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/cond/dt"] = [
    @pl.when(@pl.col("dt")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/cond/n"] = [
    @pl.when(@pl.col("n")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/basic"] = [
    @pl.when(@pl.col("i32").gt(@pl.lit_int(1L)))
    .then(@pl.lit_str("big"))
    .otherwise(@pl.lit_str("small")),
  ]
  m["when/basic-int"] = [
    @pl.when(@pl.col("i32").gt(@pl.lit_int(1L)))
    .then(@pl.col("i32"))
    .otherwise(@pl.lit_int(0L)),
  ]
  m["when/basic-null-cond"] = [
    @pl.when(@pl.col("i32").gt(@pl.lit_int(0L)))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(2L)),
  ]
  m["when/cond-null-goes-otherwise"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("i64")),
  ]
  m["when/no-match"] = [
    @pl.when(@pl.lit_bool(false)).then(@pl.col("i32")).otherwise(@pl.col("i64")),
  ]
  m["when/all-match"] = [
    @pl.when(@pl.lit_bool(true)).then(@pl.col("i32")).otherwise(@pl.col("i64")),
  ]
  m["when/cond-lit-null"] = [
    @pl.when(@pl.lit(@pl.AnyValue::Null))
    .then(@pl.col("i32"))
    .otherwise(@pl.col("i64")),
  ]
  m["when/cond-agg"] = [
    @pl.when(@pl.col("i32").sum().gt(@pl.lit_int(3L)))
    .then(@pl.col("i32"))
    .otherwise(@pl.lit_int(0L)),
  ]
  m["when/cond-agg-false"] = [
    @pl.when(@pl.col("i32").sum().gt(@pl.lit_int(100L)))
    .then(@pl.col("i32"))
    .otherwise(@pl.lit_int(0L)),
  ]
  m["when/then-agg"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32").sum()).otherwise(@pl.col("i32")),
  ]
  m["when/otherwise-agg"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("i32").max()),
  ]
  m["when/all-agg"] = [
    @pl.when(@pl.col("i32").sum().gt(@pl.lit_int(3L)))
    .then(@pl.col("i32").sum())
    .otherwise(@pl.col("i32").min()),
  ]
  m["when/all-lit-cond"] = [
    @pl.when(@pl.lit_bool(true))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(2L)),
  ]
  m["when/all-lit-cond-null"] = [
    @pl.when(@pl.col("n").sum().gt(@pl.lit_int(3L)))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(2L)),
  ]
  m["when/lit-lit"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/lit-lit-big"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(3000000000L)),
  ]
  m["when/lit-lit-float"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.lit_float(2.5)),
  ]
  m["when/lit-lit-neg"] = [
    @pl.when(@pl.col("b")).then(-@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/lit-str"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_str("x")).otherwise(@pl.lit_str("y")),
  ]
  m["when/lit-bool"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_bool(true))
    .otherwise(@pl.lit_bool(false)),
  ]
  m["when/lit-null-then"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit(@pl.AnyValue::Null))
    .otherwise(@pl.col("i32")),
  ]
  m["when/lit-null-otherwise"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .otherwise(@pl.lit(@pl.AnyValue::Null)),
  ]
  m["when/lit-null-both"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit(@pl.AnyValue::Null))
    .otherwise(@pl.lit(@pl.AnyValue::Null)),
  ]
  m["when/weak-i32"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.lit_int(1L)),
  ]
  m["when/weak-i32-big"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .otherwise(@pl.lit_int(3000000000L)),
  ]
  m["when/weak-i32-big-then"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_int(3000000000L))
    .otherwise(@pl.col("i32")),
  ]
  m["when/weak-f32"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("f32"))
    .otherwise(@pl.lit_float(1.0e300)),
  ]
  m["when/weak-f32-int"] = [
    @pl.when(@pl.col("b")).then(@pl.col("f32")).otherwise(@pl.lit_int(3L)),
  ]
  m["when/weak-i64-float"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i64")).otherwise(@pl.lit_float(0.5)),
  ]
  m["when/weak-i32-float"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.lit_float(0.5)),
  ]
  m["when/weak-str"] = [
    @pl.when(@pl.col("b")).then(@pl.col("s")).otherwise(@pl.lit_int(1L)),
  ]
  m["when/weak-str-lit-int"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.col("s")),
  ]
  m["when/weak-bool"] = [
    @pl.when(@pl.col("b")).then(@pl.col("b")).otherwise(@pl.lit_int(1L)),
  ]
  m["when/weak-date"] = [
    @pl.when(@pl.col("b")).then(@pl.col("d")).otherwise(@pl.lit_int(1L)),
  ]
  m["when/weak-null"] = [
    @pl.when(@pl.col("b")).then(@pl.col("n")).otherwise(@pl.lit_int(1L)),
  ]
  m["when/strong-lit"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .otherwise(@pl.lit(@pl.AnyValue::Int64(5L))),
  ]
  m["when/strong-lit-date"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("d"))
    .otherwise(@pl.lit(@pl.AnyValue::Date(5))),
  ]
  m["when/strong-lit-dt"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("dt"))
    .otherwise(@pl.lit(@pl.AnyValue::Datetime(5L))),
  ]
  m["when/strong-f32"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("f32"))
    .otherwise(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["when/names/then-col"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("i64")),
  ]
  m["when/names/then-lit"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.col("i32")),
  ]
  m["when/names/alias-then"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32").alias("q"))
    .otherwise(@pl.col("i64").alias("r")),
  ]
  m["when/names/alias-otherwise"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .otherwise(@pl.col("i64").alias("r")),
  ]
  m["when/names/alias-after"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .otherwise(@pl.col("i64"))
    .alias("z"),
  ]
  m["when/names/cond-named"] = [
    @pl.when(@pl.col("b").alias("c"))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(2L)),
  ]
  m["when/names/dup"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.lit_int(0L)),
    @pl.col("i32"),
  ]
  m["when/names/dup-ok"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.lit_int(0L)),
    @pl.col("i32").alias("x"),
  ]
  m["when/chain/2"] = [
    @pl.when(@pl.col("i32").gt(@pl.lit_int(0L)))
    .then(@pl.col("i32"))
    .when(@pl.col("i32").gt(@pl.lit_int(1L)))
    .then(@pl.col("i64"))
    .otherwise(@pl.lit_int(0L)),
  ]
  m["when/chain/3"] = [
    @pl.when(@pl.col("i32").gt(@pl.lit_int(0L)))
    .then(@pl.col("i32"))
    .when(@pl.col("i32").gt(@pl.lit_int(1L)))
    .then(@pl.col("i64"))
    .when(@pl.col("i32").gt(@pl.lit_int(2L)))
    .then(@pl.col("i32"))
    .otherwise(@pl.lit_int(0L)),
  ]
}

///|
fn golden_expr_agg_cases_22(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["when/chain/4"] = [
    @pl.when(@pl.col("i32").gt(@pl.lit_int(0L)))
    .then(@pl.col("i32"))
    .when(@pl.col("i32").gt(@pl.lit_int(1L)))
    .then(@pl.col("i64"))
    .when(@pl.col("i32").gt(@pl.lit_int(2L)))
    .then(@pl.col("i32"))
    .when(@pl.col("i32").gt(@pl.lit_int(3L)))
    .then(@pl.col("i64"))
    .otherwise(@pl.lit_int(0L)),
  ]
  m["when/chain/names-first-lit"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_int(1L))
    .when(@pl.col("i32").gt(@pl.lit_int(1L)))
    .then(@pl.col("i64"))
    .otherwise(@pl.col("f64")),
  ]
  m["when/chain/names-first-col"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .when(@pl.col("i32").gt(@pl.lit_int(1L)))
    .then(@pl.lit_int(5L))
    .otherwise(@pl.col("f64")),
  ]
  m["when/chain/null-conds"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_int(1L))
    .when(@pl.col("i32").is_null())
    .then(@pl.lit_int(2L))
    .otherwise(@pl.lit_int(3L)),
  ]
  m["when/chain/null-conds-all"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_str("b"))
    .when(@pl.col("i32").gt(@pl.lit_int(0L)))
    .then(@pl.lit_str("pos"))
    .when(@pl.col("i32").lt(@pl.lit_int(0L)))
    .then(@pl.lit_str("neg"))
    .otherwise(@pl.lit_str("zero")),
  ]
  m["when/chain/types"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .when(@pl.col("i32").is_null())
    .then(@pl.col("f32"))
    .otherwise(@pl.col("i64")),
  ]
  m["when/chain/weak"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .when(@pl.col("i32").is_null())
    .then(@pl.lit_int(5L))
    .otherwise(@pl.lit_int(3L)),
  ]
  m["when/chain/weak-lits"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_int(1L))
    .when(@pl.col("i32").is_null())
    .then(@pl.lit_int(5L))
    .otherwise(@pl.lit_int(3L)),
  ]
  m["when/chain/weak-big"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_int(1L))
    .when(@pl.col("i32").is_null())
    .then(@pl.lit_int(3000000000L))
    .otherwise(@pl.lit_int(3L)),
  ]
  m["when/chain/weak-float"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_int(1L))
    .when(@pl.col("i32").is_null())
    .then(@pl.lit_float(0.5))
    .otherwise(@pl.lit_int(3L)),
  ]
  m["when/chain/str"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_str("T"))
    .when(@pl.col("s").is_null())
    .then(@pl.col("s"))
    .otherwise(@pl.lit_str("none")),
  ]
  m["when/chain/scalar-branch"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32").sum())
    .when(@pl.col("i32").is_null())
    .then(@pl.col("i64").min())
    .otherwise(@pl.col("i32")),
  ]
  m["when/chain/alias"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_int(1L))
    .when(@pl.col("i32").is_null())
    .then(@pl.lit_int(2L))
    .otherwise(@pl.lit_int(3L))
    .alias("z"),
  ]
  m["when/nested/otherwise"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_int(1L))
    .otherwise(
      @pl.when(@pl.col("i32").is_null())
      .then(@pl.lit_int(2L))
      .otherwise(@pl.lit_int(3L)),
    ),
  ]
  m["when/nested/then"] = [
    @pl.when(@pl.col("b"))
    .then(
      @pl.when(@pl.col("i32").is_null())
      .then(@pl.lit_int(1L))
      .otherwise(@pl.lit_int(2L)),
    )
    .otherwise(@pl.lit_int(3L)),
  ]
  m["when/nested/cond"] = [
    @pl.when(
      @pl.when(@pl.col("b"))
      .then(@pl.lit_bool(true))
      .otherwise(@pl.col("i32").is_null()),
    )
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(2L)),
  ]
  m["when/nested/then-chain"] = [
    @pl.when(@pl.col("b"))
    .then(
      @pl.when(@pl.col("i32").is_null())
      .then(@pl.lit_int(1L))
      .when(@pl.col("i32").gt(@pl.lit_int(1L)))
      .then(@pl.lit_int(2L))
      .otherwise(@pl.lit_int(3L)),
    )
    .otherwise(@pl.lit_int(4L)),
  ]
  m["when/chain/e0"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .when(@pl.col("i32").is_null())
    .then(@pl.col("i64"))
    .otherwise(@pl.col("f64")),
  ]
  m["when/err/cond-int"] = [
    @pl.when(@pl.col("i32")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/err/cond-str"] = [
    @pl.when(@pl.col("s")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/err/cond-null-col"] = [
    @pl.when(@pl.col("n")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/err/cond-lit-int"] = [
    @pl.when(@pl.lit(@pl.AnyValue::Int32(1)))
    .then(@pl.col("i32"))
    .otherwise(@pl.col("i64")),
  ]
  m["when/err/cond-agg"] = [
    @pl.when(@pl.col("i32").sum())
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(2L)),
  ]
  m["when/err/cond-date"] = [
    @pl.when(@pl.col("d")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/err/supertype"] = [
    @pl.when(@pl.col("b")).then(@pl.col("b")).otherwise(@pl.col("d")),
  ]
  m["when/err/supertype-dt"] = [
    @pl.when(@pl.col("b")).then(@pl.col("dt")).otherwise(@pl.col("b")),
  ]
  m["when/err/supertype-then-cond"] = [
    @pl.when(@pl.col("i32")).then(@pl.col("b")).otherwise(@pl.col("d")),
  ]
  m["when/err/chain-supertype"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .when(@pl.col("b"))
    .then(@pl.col("d"))
    .otherwise(@pl.col("i64")),
  ]
  m["when/err/then-kernel"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("s").eq(@pl.col("i32")))
    .otherwise(@pl.col("b")),
  ]
  m["when/err/otherwise-kernel"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("b"))
    .otherwise(@pl.col("s").eq(@pl.col("i32"))),
  ]
  m["when/err/cond-kernel"] = [
    @pl.when(@pl.col("s").eq(@pl.col("i32")))
    .then(@pl.col("i32"))
    .otherwise(@pl.col("i64")),
  ]
  m["when/err/order-then-otherwise"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("s").eq(@pl.col("i32")))
    .otherwise(@pl.col("s").eq(@pl.col("i64"))),
  ]
  m["when/err/order-otherwise-cond"] = [
    @pl.when(@pl.col("s").eq(@pl.col("i32")))
    .then(@pl.col("b"))
    .otherwise(@pl.col("s").eq(@pl.col("i64"))),
  ]
  m["when/err/order-then-cond"] = [
    @pl.when(@pl.col("s").eq(@pl.col("i32")))
    .then(@pl.col("s").eq(@pl.col("i64")))
    .otherwise(@pl.col("b")),
  ]
  m["when/err/order-all"] = [
    @pl.when(@pl.col("s").eq(@pl.col("i32")))
    .then(@pl.col("s").eq(@pl.col("i64")))
    .otherwise(@pl.col("s").eq(@pl.col("f64"))),
  ]
  m["when/err/order-chain-conds"] = [
    @pl.when(@pl.col("s").eq(@pl.col("i32")))
    .then(@pl.col("b"))
    .when(@pl.col("s").eq(@pl.col("i64")))
    .then(@pl.col("b").not_())
    .otherwise(@pl.col("s").is_null()),
  ]
  m["when/err/order-chain-then1-then2"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("s").eq(@pl.col("i32")))
    .when(@pl.col("s").is_null())
    .then(@pl.col("s").eq(@pl.col("i64")))
    .otherwise(@pl.col("b").not_()),
  ]
  m["when/err/order-chain-then1-cond2"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("s").eq(@pl.col("i32")))
    .when(@pl.col("s").eq(@pl.col("i64")))
    .then(@pl.col("b").not_())
    .otherwise(@pl.col("s").is_null()),
  ]
  m["when/err/order-chain-cond1-then2"] = [
    @pl.when(@pl.col("s").eq(@pl.col("i32")))
    .then(@pl.col("b"))
    .when(@pl.col("s").is_null())
    .then(@pl.col("s").eq(@pl.col("i64")))
    .otherwise(@pl.col("b").not_()),
  ]
  m["when/err/order-chain-cond2-then2"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("b").not_())
    .when(@pl.col("s").eq(@pl.col("i32")))
    .then(@pl.col("s").eq(@pl.col("i64")))
    .otherwise(@pl.col("s").is_null()),
  ]
  m["when/err/order-chain-cond2-otherwise"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("b").not_())
    .when(@pl.col("s").eq(@pl.col("i32")))
    .then(@pl.col("s").is_null())
    .otherwise(@pl.col("s").eq(@pl.col("i64"))),
  ]
  m["when/err/order-chain-then2-otherwise"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("b").not_())
    .when(@pl.col("s").is_null())
    .then(@pl.col("s").eq(@pl.col("i32")))
    .otherwise(@pl.col("s").eq(@pl.col("i64"))),
  ]
  m["when/err/order-chain-supertype-cond"] = [
    @pl.when(@pl.col("s").eq(@pl.col("i32")))
    .then(@pl.col("b"))
    .when(@pl.col("b"))
    .then(@pl.col("d"))
    .otherwise(@pl.col("b").not_()),
  ]
  m["when/err/kernel-vs-cond"] = [
    @pl.when(@pl.col("i32"))
    .then(@pl.col("s").eq(@pl.col("i64")))
    .otherwise(@pl.col("b")),
  ]
  m["when/err/missing-cond"] = [
    @pl.when(@pl.col("zz")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/err/missing-then"] = [
    @pl.when(@pl.col("b")).then(@pl.col("zz")).otherwise(@pl.lit_int(2L)),
  ]
  m["when/err/missing-otherwise"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.col("zz")),
  ]
  m["when/err/missing-vs-kernel"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("s") + @pl.lit_int(1L))
    .otherwise(@pl.col("zz")),
  ]
  m["when/err/missing-order"] = [
    @pl.when(@pl.col("zz1")).then(@pl.col("zz2")).otherwise(@pl.col("zz3")),
  ]
  m["when/err/missing-order2"] = [
    @pl.when(@pl.col("b")).then(@pl.col("zz2")).otherwise(@pl.col("zz3")),
  ]
  m["when/err/missing-order-chain"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .when(@pl.col("zz1"))
    .then(@pl.col("zz2"))
    .otherwise(@pl.col("zz3")),
  ]
  m["when/err/missing-chain"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.lit_int(1L))
    .when(@pl.col("b"))
    .then(@pl.col("zz"))
    .otherwise(@pl.lit_int(3L)),
  ]
  m["when/width/02031"] = [
    @pl.when(@pl.cols([]).is_not_null())
    .then(@pl.cols(["i32", "i64"]))
    .when(@pl.cols([]).is_not_null())
    .then(@pl.cols(["i32", "i64", "f64"]))
    .otherwise(@pl.col("i32")),
  ]
  m["when/width/22331"] = [
    @pl.when(@pl.cols(["i32", "i64"]).is_not_null())
    .then(@pl.cols(["i32", "i64"]))
    .when(@pl.cols(["i32", "i64", "f64"]).is_not_null())
    .then(@pl.cols(["i32", "i64", "f64"]))
    .otherwise(@pl.col("i32")),
  ]
  m["when/width/12132"] = [
    @pl.when(@pl.col("i32").is_not_null())
    .then(@pl.cols(["i32", "i64"]))
    .when(@pl.col("i32").is_not_null())
    .then(@pl.cols(["i32", "i64", "f64"]))
    .otherwise(@pl.cols(["i32", "i64"])),
  ]
  m["when/width/12222"] = [
    @pl.when(@pl.col("i32").is_not_null())
    .then(@pl.cols(["i32", "i64"]))
    .when(@pl.cols(["i32", "i64"]).is_not_null())
    .then(@pl.cols(["i32", "i64"]))
    .otherwise(@pl.cols(["i32", "i64"])),
  ]
  m["when/width/0203021"] = [
    @pl.when(@pl.cols([]).is_not_null())
    .then(@pl.cols(["i32", "i64"]))
    .when(@pl.cols([]).is_not_null())
    .then(@pl.cols(["i32", "i64", "f64"]))
    .when(@pl.cols([]).is_not_null())
    .then(@pl.cols(["i32", "i64"]))
    .otherwise(@pl.col("i32")),
  ]
  m["when/width/1212322"] = [
    @pl.when(@pl.col("i32").is_not_null())
    .then(@pl.cols(["i32", "i64"]))
    .when(@pl.col("i32").is_not_null())
    .then(@pl.cols(["i32", "i64"]))
    .when(@pl.cols(["i32", "i64", "f64"]).is_not_null())
    .then(@pl.cols(["i32", "i64"]))
    .otherwise(@pl.cols(["i32", "i64"])),
  ]
  m["when/width/21110"] = [
    @pl.when(@pl.cols(["i32", "i64"]).is_not_null())
    .then(@pl.col("i32"))
    .when(@pl.col("i32").is_not_null())
    .then(@pl.col("i32"))
    .otherwise(@pl.cols([])),
  ]
  m["when/shape/e0"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("i64")),
  ]
}

///|
fn golden_expr_agg_cases_23(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["when/shape/e0-lit"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/shape/e0-then-agg"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32").sum()).otherwise(@pl.col("i64")),
  ]
  m["when/shape/e0-otherwise-agg"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("i64").sum()),
  ]
  m["when/shape/e0-cond-agg"] = [
    @pl.when(@pl.col("b").first())
    .then(@pl.col("i32"))
    .otherwise(@pl.col("i64")),
  ]
  m["when/shape/e0-all-agg"] = [
    @pl.when(@pl.col("b").first())
    .then(@pl.col("i32").sum())
    .otherwise(@pl.col("i64").sum()),
  ]
  m["when/shape/e0-lit-agg"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.col("i64").sum()),
  ]
  m["when/shape/z0-lit"] = [
    @pl.when(@pl.lit_bool(true))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(2L)),
  ]
  m["when/shape/r1"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.col("i64")),
  ]
  m["when/shape/r1-agg"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32").sum()).otherwise(@pl.col("i64")),
  ]
  m["when/shape/select-lit"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.lit_int(0L)),
    @pl.lit_int(1L),
  ]
  m["when/shape/select-agg"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .otherwise(@pl.lit_int(0L))
    .alias("x"),
    @pl.col("i32").sum(),
  ]
  m["when/shape/wc"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/shape/wc-in-place"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .otherwise(@pl.lit_int(0L))
    .alias("i32"),
  ]
  m["when/shape/wc-agg"] = [
    @pl.when(@pl.col("i32").sum().gt(@pl.lit_int(3L)))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(2L)),
  ]
  m["when/shape/wc-e0"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/shape/wc-z0"] = [
    @pl.when(@pl.lit_bool(true))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(2L)),
  ]
  m["when/sel/cols-then"] = [
    @pl.when(@pl.lit_bool(true))
    .then(@pl.cols(["i32", "i64"]))
    .otherwise(@pl.lit_int(0L)),
  ]
  m["when/sel/cols-cond"] = [
    @pl.when(@pl.cols(["b"])).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
  ]
  m["when/sel/all-otherwise"] = [
    @pl.when(@pl.lit_bool(true)).then(@pl.col("i32")).otherwise(@pl.all()),
  ]
  m["when/sel/width"] = [
    @pl.when(@pl.lit_bool(false))
    .then(@pl.cols(["i32", "i64"]))
    .otherwise(@pl.cols(["i32", "i64", "f64"])),
  ]
  m["when/sel/all-all"] = [
    @pl.when(@pl.lit_bool(false)).then(@pl.all()).otherwise(@pl.all()),
  ]
  m["when/in-op"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.lit_int(0L)) +
    @pl.lit_int(1L),
  ]
  m["when/in-op-weak"] = [
    @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)) +
    @pl.col("i32"),
  ]
  m["when/in-agg"] = [
    @pl.when(@pl.col("b")).then(@pl.col("i32")).otherwise(@pl.lit_int(0L)).sum(),
  ]
  m["when/in-cmp"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .otherwise(@pl.lit_int(0L))
    .gt(@pl.lit_int(1L)),
  ]
  m["when/in-fill"] = [
    @pl.when(@pl.col("b"))
    .then(@pl.col("i32"))
    .otherwise(@pl.lit(@pl.AnyValue::Null))
    .fill_null(@pl.lit_int(-1L)),
  ]
  m["when/fill-value"] = [
    @pl.col("i32").fill_null(
      @pl.when(@pl.col("b")).then(@pl.lit_int(1L)).otherwise(@pl.lit_int(2L)),
    ),
  ]
  m["when/not-cond"] = [
    @pl.when(@pl.col("b").not_()).then(@pl.col("i32")).otherwise(@pl.col("i64")),
  ]
  m["when/cond-and"] = [
    @pl.when(@pl.col("b") & @pl.col("i32").gt(@pl.lit_int(0L)))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(0L)),
  ]
  m["when/cond-between"] = [
    @pl.when(
      @pl.col("i32").between(
        @pl.lit_int(0L),
        @pl.lit_int(7L),
        closed=@pl.ClosedInterval::Both,
      ),
    )
    .then(@pl.lit_str("in"))
    .otherwise(@pl.lit_str("out")),
  ]
  m["when/cond-isin"] = [
    @pl.when(@pl.col("i32").is_in(vs["i32"]))
    .then(@pl.lit_str("in"))
    .otherwise(@pl.lit_str("out")),
  ]
  m["when/cond-is_null"] = [
    @pl.when(@pl.col("i32").is_null())
    .then(@pl.lit_int(0L))
    .otherwise(@pl.col("i32")),
  ]
  m["when/cond-nan"] = [
    @pl.when(@pl.col("f64").is_nan())
    .then(@pl.lit_float(0.0))
    .otherwise(@pl.col("f64")),
  ]
  m["when/clip"] = [
    @pl.when(@pl.col("i64").gt(@pl.lit_int(10L)))
    .then(@pl.lit_int(10L))
    .otherwise(@pl.col("i64"))
    .alias("i64"),
  ]
  m["when/sign"] = [
    @pl.when(@pl.col("f64").gt(@pl.lit_float(0.0)))
    .then(@pl.lit_int(1L))
    .otherwise(
      @pl.when(@pl.col("f64").lt(@pl.lit_float(0.0)))
      .then(@pl.lit_int(-1L))
      .otherwise(@pl.lit_int(0L)),
    ),
  ]
}

///|
/// Every case id with the expressions it builds; `vs` is the `inputs` table.
fn golden_expr_agg_cases(
  vs : Map[String, @pl.Series],
) -> Map[String, Array[@pl.Expr]] {
  let m : Map[String, Array[@pl.Expr]] = Map([])
  golden_expr_agg_cases_0(m, vs)
  golden_expr_agg_cases_1(m, vs)
  golden_expr_agg_cases_2(m, vs)
  golden_expr_agg_cases_3(m, vs)
  golden_expr_agg_cases_4(m, vs)
  golden_expr_agg_cases_5(m, vs)
  golden_expr_agg_cases_6(m, vs)
  golden_expr_agg_cases_7(m, vs)
  golden_expr_agg_cases_8(m, vs)
  golden_expr_agg_cases_9(m, vs)
  golden_expr_agg_cases_10(m, vs)
  golden_expr_agg_cases_11(m, vs)
  golden_expr_agg_cases_12(m, vs)
  golden_expr_agg_cases_13(m, vs)
  golden_expr_agg_cases_14(m, vs)
  golden_expr_agg_cases_15(m, vs)
  golden_expr_agg_cases_16(m, vs)
  golden_expr_agg_cases_17(m, vs)
  golden_expr_agg_cases_18(m, vs)
  golden_expr_agg_cases_19(m, vs)
  golden_expr_agg_cases_20(m, vs)
  golden_expr_agg_cases_21(m, vs)
  golden_expr_agg_cases_22(m, vs)
  golden_expr_agg_cases_23(m, vs)
  m
}
