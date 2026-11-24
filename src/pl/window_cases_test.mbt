// 由 docs/golden/scripts/window.py 生成，勿手改

///|
fn golden_window_cases_0(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["agg/sum/i32"] = [@pl.col("i32").sum().over([@pl.col("k")])]
  m["agg/sum/i64"] = [@pl.col("i64").sum().over([@pl.col("k")])]
  m["agg/sum/f32"] = [@pl.col("f32").sum().over([@pl.col("k")])]
  m["agg/sum/f64"] = [@pl.col("f64").sum().over([@pl.col("k")])]
  m["agg/sum/s"] = [@pl.col("s").sum().over([@pl.col("k")])]
  m["agg/sum/b"] = [@pl.col("b").sum().over([@pl.col("k")])]
  m["agg/sum/d"] = [@pl.col("d").sum().over([@pl.col("k")])]
  m["agg/sum/dt"] = [@pl.col("dt").sum().over([@pl.col("k")])]
  m["agg/sum/n"] = [@pl.col("n").sum().over([@pl.col("k")])]
  m["agg/mean/i32"] = [@pl.col("i32").mean().over([@pl.col("k")])]
  m["agg/mean/i64"] = [@pl.col("i64").mean().over([@pl.col("k")])]
  m["agg/mean/f32"] = [@pl.col("f32").mean().over([@pl.col("k")])]
  m["agg/mean/f64"] = [@pl.col("f64").mean().over([@pl.col("k")])]
  m["agg/mean/s"] = [@pl.col("s").mean().over([@pl.col("k")])]
  m["agg/mean/b"] = [@pl.col("b").mean().over([@pl.col("k")])]
  m["agg/mean/d"] = [@pl.col("d").mean().over([@pl.col("k")])]
  m["agg/mean/dt"] = [@pl.col("dt").mean().over([@pl.col("k")])]
  m["agg/mean/n"] = [@pl.col("n").mean().over([@pl.col("k")])]
  m["agg/min/i32"] = [@pl.col("i32").min().over([@pl.col("k")])]
  m["agg/min/i64"] = [@pl.col("i64").min().over([@pl.col("k")])]
  m["agg/min/f32"] = [@pl.col("f32").min().over([@pl.col("k")])]
  m["agg/min/f64"] = [@pl.col("f64").min().over([@pl.col("k")])]
  m["agg/min/s"] = [@pl.col("s").min().over([@pl.col("k")])]
  m["agg/min/b"] = [@pl.col("b").min().over([@pl.col("k")])]
  m["agg/min/d"] = [@pl.col("d").min().over([@pl.col("k")])]
  m["agg/min/dt"] = [@pl.col("dt").min().over([@pl.col("k")])]
  m["agg/min/n"] = [@pl.col("n").min().over([@pl.col("k")])]
  m["agg/max/i32"] = [@pl.col("i32").max().over([@pl.col("k")])]
  m["agg/max/i64"] = [@pl.col("i64").max().over([@pl.col("k")])]
  m["agg/max/f32"] = [@pl.col("f32").max().over([@pl.col("k")])]
  m["agg/max/f64"] = [@pl.col("f64").max().over([@pl.col("k")])]
  m["agg/max/s"] = [@pl.col("s").max().over([@pl.col("k")])]
  m["agg/max/b"] = [@pl.col("b").max().over([@pl.col("k")])]
  m["agg/max/d"] = [@pl.col("d").max().over([@pl.col("k")])]
  m["agg/max/dt"] = [@pl.col("dt").max().over([@pl.col("k")])]
  m["agg/max/n"] = [@pl.col("n").max().over([@pl.col("k")])]
  m["agg/count/i32"] = [@pl.col("i32").count().over([@pl.col("k")])]
  m["agg/count/i64"] = [@pl.col("i64").count().over([@pl.col("k")])]
  m["agg/count/f32"] = [@pl.col("f32").count().over([@pl.col("k")])]
  m["agg/count/f64"] = [@pl.col("f64").count().over([@pl.col("k")])]
  m["agg/count/s"] = [@pl.col("s").count().over([@pl.col("k")])]
  m["agg/count/b"] = [@pl.col("b").count().over([@pl.col("k")])]
  m["agg/count/d"] = [@pl.col("d").count().over([@pl.col("k")])]
  m["agg/count/dt"] = [@pl.col("dt").count().over([@pl.col("k")])]
  m["agg/count/n"] = [@pl.col("n").count().over([@pl.col("k")])]
  m["agg/n_unique/i32"] = [@pl.col("i32").n_unique().over([@pl.col("k")])]
  m["agg/n_unique/i64"] = [@pl.col("i64").n_unique().over([@pl.col("k")])]
  m["agg/n_unique/f32"] = [@pl.col("f32").n_unique().over([@pl.col("k")])]
  m["agg/n_unique/f64"] = [@pl.col("f64").n_unique().over([@pl.col("k")])]
  m["agg/n_unique/s"] = [@pl.col("s").n_unique().over([@pl.col("k")])]
  m["agg/n_unique/b"] = [@pl.col("b").n_unique().over([@pl.col("k")])]
  m["agg/n_unique/d"] = [@pl.col("d").n_unique().over([@pl.col("k")])]
  m["agg/n_unique/dt"] = [@pl.col("dt").n_unique().over([@pl.col("k")])]
  m["agg/n_unique/n"] = [@pl.col("n").n_unique().over([@pl.col("k")])]
  m["agg/first/i32"] = [@pl.col("i32").first().over([@pl.col("k")])]
  m["agg/first/i64"] = [@pl.col("i64").first().over([@pl.col("k")])]
  m["agg/first/f32"] = [@pl.col("f32").first().over([@pl.col("k")])]
  m["agg/first/f64"] = [@pl.col("f64").first().over([@pl.col("k")])]
  m["agg/first/s"] = [@pl.col("s").first().over([@pl.col("k")])]
  m["agg/first/b"] = [@pl.col("b").first().over([@pl.col("k")])]
}

///|
fn golden_window_cases_1(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["agg/first/d"] = [@pl.col("d").first().over([@pl.col("k")])]
  m["agg/first/dt"] = [@pl.col("dt").first().over([@pl.col("k")])]
  m["agg/first/n"] = [@pl.col("n").first().over([@pl.col("k")])]
  m["agg/len/i32"] = [@pl.col("i32").len().over([@pl.col("k")])]
  m["agg/len/f64"] = [@pl.col("f64").len().over([@pl.col("k")])]
  m["agg/len/s"] = [@pl.col("s").len().over([@pl.col("k")])]
  m["agg/len/b"] = [@pl.col("b").len().over([@pl.col("k")])]
  m["agg/last/i32"] = [@pl.col("i32").last().over([@pl.col("k")])]
  m["agg/last/f64"] = [@pl.col("f64").last().over([@pl.col("k")])]
  m["agg/last/s"] = [@pl.col("s").last().over([@pl.col("k")])]
  m["agg/last/b"] = [@pl.col("b").last().over([@pl.col("k")])]
  m["agg/median/i32"] = [@pl.col("i32").median().over([@pl.col("k")])]
  m["agg/median/f64"] = [@pl.col("f64").median().over([@pl.col("k")])]
  m["agg/median/s"] = [@pl.col("s").median().over([@pl.col("k")])]
  m["agg/median/b"] = [@pl.col("b").median().over([@pl.col("k")])]
  m["agg/product/i32"] = [@pl.col("i32").product().over([@pl.col("k")])]
  m["agg/product/f64"] = [@pl.col("f64").product().over([@pl.col("k")])]
  m["agg/product/s"] = [@pl.col("s").product().over([@pl.col("k")])]
  m["agg/product/b"] = [@pl.col("b").product().over([@pl.col("k")])]
  m["agg/std1/i32"] = [@pl.col("i32").std(ddof=1).over([@pl.col("k")])]
  m["agg/std1/f32"] = [@pl.col("f32").std(ddof=1).over([@pl.col("k")])]
  m["agg/std1/f64"] = [@pl.col("f64").std(ddof=1).over([@pl.col("k")])]
  m["agg/std1/v"] = [@pl.col("v").std(ddof=1).over([@pl.col("k")])]
  m["agg/std0/i32"] = [@pl.col("i32").std(ddof=0).over([@pl.col("k")])]
  m["agg/std0/f32"] = [@pl.col("f32").std(ddof=0).over([@pl.col("k")])]
  m["agg/std0/f64"] = [@pl.col("f64").std(ddof=0).over([@pl.col("k")])]
  m["agg/std0/v"] = [@pl.col("v").std(ddof=0).over([@pl.col("k")])]
  m["agg/var1/i32"] = [@pl.col("i32").var_(ddof=1).over([@pl.col("k")])]
  m["agg/var1/f32"] = [@pl.col("f32").var_(ddof=1).over([@pl.col("k")])]
  m["agg/var1/f64"] = [@pl.col("f64").var_(ddof=1).over([@pl.col("k")])]
  m["agg/var1/v"] = [@pl.col("v").var_(ddof=1).over([@pl.col("k")])]
  m["agg/var0/i32"] = [@pl.col("i32").var_(ddof=0).over([@pl.col("k")])]
  m["agg/var0/f32"] = [@pl.col("f32").var_(ddof=0).over([@pl.col("k")])]
  m["agg/var0/f64"] = [@pl.col("f64").var_(ddof=0).over([@pl.col("k")])]
  m["agg/var0/v"] = [@pl.col("v").var_(ddof=0).over([@pl.col("k")])]
  m["agg/quantile/i32"] = [
    @pl.col("i32")
    .quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)
    .over([@pl.col("k")]),
  ]
  m["agg/quantile/f64"] = [
    @pl.col("f64")
    .quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)
    .over([@pl.col("k")]),
  ]
  m["agg/quantile/v"] = [
    @pl.col("v")
    .quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)
    .over([@pl.col("k")]),
  ]
  m["agg/quantile/s"] = [
    @pl.col("s")
    .quantile(0.5, interpolation=@pl.QuantileMethod::Nearest)
    .over([@pl.col("k")]),
  ]
  m["agg/quantile-lower/f64"] = [
    @pl.col("f64")
    .quantile(0.3, interpolation=@pl.QuantileMethod::Lower)
    .over([@pl.col("k")]),
  ]
  m["agg/sum/v-by-j"] = [@pl.col("v").sum().over([@pl.col("j")])]
  m["agg/sum-two"] = [
    @pl.col("v").sum().over([@pl.col("k")]),
    @pl.col("x").mean().over([@pl.col("k")]).alias("m"),
  ]
  m["agg/sum-with-columns"] = [
    @pl.col("v").sum().over([@pl.col("k")]).alias("tot"),
  ]
  m["agg/sum-replaces"] = [@pl.col("v").sum().over([@pl.col("k")])]
  m["agg/sum-literal-next"] = [
    @pl.lit(@pl.AnyValue::Int32(7)),
    @pl.col("v").sum().over([@pl.col("k")]).alias("t"),
  ]
  m["agg/sum-cols"] = [@pl.cols(["v", "y"]).sum().over([@pl.col("k")])]
  m["agg/sum-all-is-text"] = [@pl.all().sum().over([@pl.col("k")])]
  m["agg/sum-unsupported-text"] = [@pl.col("s").sum().over([@pl.col("k")])]
  m["agg/mean-unsupported-text"] = [@pl.col("s").mean().over([@pl.col("k")])]
  m["agg/missing-column"] = [@pl.col("zz").sum().over([@pl.col("k")])]
  m["lit/int"] = [@pl.lit_int(1L).over([@pl.col("k")])]
  m["lit/float"] = [@pl.lit_float(1.5).over([@pl.col("k")])]
  m["lit/str"] = [@pl.lit_str("q").over([@pl.col("k")])]
  m["lit/bool"] = [@pl.lit_bool(true).over([@pl.col("k")])]
  m["lit/null"] = [@pl.lit(@pl.AnyValue::Null).over([@pl.col("k")])]
  m["lit/i32"] = [@pl.lit(@pl.AnyValue::Int32(7)).over([@pl.col("k")])]
  m["lit/plus-lit"] = [(@pl.lit_int(1L) + @pl.lit_int(2L)).over([@pl.col("k")])]
  m["len/plain"] = [@pl.len().over([@pl.col("k")])]
  m["len/plus"] = [(@pl.len() + @pl.lit_int(1L)).over([@pl.col("k")])]
  m["len/times-sum"] = [(@pl.len() * @pl.col("v").sum()).over([@pl.col("k")])]
}

///|
fn golden_window_cases_2(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["len/by-id"] = [@pl.len().over([@pl.col("id")])]
  m["len/by-two"] = [@pl.len().over([@pl.col("k"), @pl.col("j")])]
  m["len/count-vs-len"] = [
    @pl.col("vn").count().over([@pl.col("k")]).alias("c"),
    @pl.col("vn").len().over([@pl.col("k")]).alias("l"),
    @pl.len().over([@pl.col("k")]).alias("n"),
  ]
  m["cum_sum/v/fwd"] = [@pl.col("v").cum_sum().over([@pl.col("k")])]
  m["cum_sum/v/rev"] = [@pl.col("v").cum_sum(reverse=true).over([@pl.col("k")])]
  m["cum_sum/vn/fwd"] = [@pl.col("vn").cum_sum().over([@pl.col("k")])]
  m["cum_sum/vn/rev"] = [
    @pl.col("vn").cum_sum(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_sum/f64/fwd"] = [@pl.col("f64").cum_sum().over([@pl.col("k")])]
  m["cum_sum/f64/rev"] = [
    @pl.col("f64").cum_sum(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_sum/i32/fwd"] = [@pl.col("i32").cum_sum().over([@pl.col("k")])]
  m["cum_sum/i32/rev"] = [
    @pl.col("i32").cum_sum(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_min/vn/fwd"] = [@pl.col("vn").cum_min().over([@pl.col("k")])]
  m["cum_min/vn/rev"] = [
    @pl.col("vn").cum_min(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_min/f64/fwd"] = [@pl.col("f64").cum_min().over([@pl.col("k")])]
  m["cum_min/f64/rev"] = [
    @pl.col("f64").cum_min(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_max/v/fwd"] = [@pl.col("v").cum_max().over([@pl.col("k")])]
  m["cum_max/v/rev"] = [@pl.col("v").cum_max(reverse=true).over([@pl.col("k")])]
  m["cum_max/vn/fwd"] = [@pl.col("vn").cum_max().over([@pl.col("k")])]
  m["cum_max/vn/rev"] = [
    @pl.col("vn").cum_max(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_max/f64/fwd"] = [@pl.col("f64").cum_max().over([@pl.col("k")])]
  m["cum_max/f64/rev"] = [
    @pl.col("f64").cum_max(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_max/i32/fwd"] = [@pl.col("i32").cum_max().over([@pl.col("k")])]
  m["cum_max/i32/rev"] = [
    @pl.col("i32").cum_max(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_prod/vn/fwd"] = [@pl.col("vn").cum_prod().over([@pl.col("k")])]
  m["cum_prod/vn/rev"] = [
    @pl.col("vn").cum_prod(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_prod/f64/fwd"] = [@pl.col("f64").cum_prod().over([@pl.col("k")])]
  m["cum_prod/f64/rev"] = [
    @pl.col("f64").cum_prod(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_count/vn/fwd"] = [@pl.col("vn").cum_count().over([@pl.col("k")])]
  m["cum_count/vn/rev"] = [
    @pl.col("vn").cum_count(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_count/f64/fwd"] = [@pl.col("f64").cum_count().over([@pl.col("k")])]
  m["cum_count/f64/rev"] = [
    @pl.col("f64").cum_count(reverse=true).over([@pl.col("k")]),
  ]
  m["cum_sum/s"] = [@pl.col("s").cum_sum().over([@pl.col("k")])]
  m["cum_sum/b"] = [@pl.col("b").cum_sum().over([@pl.col("k")])]
  m["cum_sum/d"] = [@pl.col("d").cum_sum().over([@pl.col("k")])]
  m["cum_sum/n"] = [@pl.col("n").cum_sum().over([@pl.col("k")])]
  m["shift/v/1"] = [@pl.col("v").shift(n=1).over([@pl.col("k")])]
  m["shift/s/1"] = [@pl.col("s").shift(n=1).over([@pl.col("k")])]
  m["shift/d/1"] = [@pl.col("d").shift(n=1).over([@pl.col("k")])]
  m["shift/v/2"] = [@pl.col("v").shift(n=2).over([@pl.col("k")])]
  m["shift/s/2"] = [@pl.col("s").shift(n=2).over([@pl.col("k")])]
  m["shift/d/2"] = [@pl.col("d").shift(n=2).over([@pl.col("k")])]
  m["shift/v/-1"] = [@pl.col("v").shift(n=-1).over([@pl.col("k")])]
  m["shift/s/-1"] = [@pl.col("s").shift(n=-1).over([@pl.col("k")])]
  m["shift/d/-1"] = [@pl.col("d").shift(n=-1).over([@pl.col("k")])]
  m["shift/v/0"] = [@pl.col("v").shift(n=0).over([@pl.col("k")])]
  m["shift/s/0"] = [@pl.col("s").shift(n=0).over([@pl.col("k")])]
  m["shift/d/0"] = [@pl.col("d").shift(n=0).over([@pl.col("k")])]
  m["shift/v/20"] = [@pl.col("v").shift(n=20).over([@pl.col("k")])]
  m["shift/s/20"] = [@pl.col("s").shift(n=20).over([@pl.col("k")])]
  m["shift/d/20"] = [@pl.col("d").shift(n=20).over([@pl.col("k")])]
  m["shift/fill"] = [
    @pl.col("v")
    .shift(n=1, fill_value=@pl.AnyValue::Int32(5))
    .over([@pl.col("k")]),
  ]
  m["shift/fill-neg"] = [
    @pl.col("s")
    .shift(n=-2, fill_value=@pl.AnyValue::String("z"))
    .over([@pl.col("k")]),
  ]
  m["diff/v/1"] = [@pl.col("v").diff(n=1).over([@pl.col("k")])]
  m["diff/vn/1"] = [@pl.col("vn").diff(n=1).over([@pl.col("k")])]
  m["diff/f64/1"] = [@pl.col("f64").diff(n=1).over([@pl.col("k")])]
  m["diff/i32/1"] = [@pl.col("i32").diff(n=1).over([@pl.col("k")])]
  m["diff/v/2"] = [@pl.col("v").diff(n=2).over([@pl.col("k")])]
  m["diff/vn/2"] = [@pl.col("vn").diff(n=2).over([@pl.col("k")])]
  m["diff/f64/2"] = [@pl.col("f64").diff(n=2).over([@pl.col("k")])]
  m["diff/i32/2"] = [@pl.col("i32").diff(n=2).over([@pl.col("k")])]
}

///|
fn golden_window_cases_3(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["diff/v/-1"] = [@pl.col("v").diff(n=-1).over([@pl.col("k")])]
  m["diff/vn/-1"] = [@pl.col("vn").diff(n=-1).over([@pl.col("k")])]
  m["diff/f64/-1"] = [@pl.col("f64").diff(n=-1).over([@pl.col("k")])]
  m["diff/i32/-1"] = [@pl.col("i32").diff(n=-1).over([@pl.col("k")])]
  m["diff/date"] = [@pl.col("d").diff(n=1).over([@pl.col("k")])]
  m["rank/average/v/asc"] = [
    @pl.col("v").rank(method_=@pl.RankMethod::Average).over([@pl.col("k")]),
  ]
  m["rank/average/v/desc"] = [
    @pl.col("v")
    .rank(method_=@pl.RankMethod::Average, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/average/vn/asc"] = [
    @pl.col("vn").rank(method_=@pl.RankMethod::Average).over([@pl.col("k")]),
  ]
  m["rank/average/vn/desc"] = [
    @pl.col("vn")
    .rank(method_=@pl.RankMethod::Average, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/average/f64/asc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Average).over([@pl.col("k")]),
  ]
  m["rank/average/f64/desc"] = [
    @pl.col("f64")
    .rank(method_=@pl.RankMethod::Average, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/average/s/asc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Average).over([@pl.col("k")]),
  ]
  m["rank/average/s/desc"] = [
    @pl.col("s")
    .rank(method_=@pl.RankMethod::Average, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/min/v/asc"] = [
    @pl.col("v").rank(method_=@pl.RankMethod::Min).over([@pl.col("k")]),
  ]
  m["rank/min/v/desc"] = [
    @pl.col("v")
    .rank(method_=@pl.RankMethod::Min, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/min/vn/asc"] = [
    @pl.col("vn").rank(method_=@pl.RankMethod::Min).over([@pl.col("k")]),
  ]
  m["rank/min/f64/asc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Min).over([@pl.col("k")]),
  ]
  m["rank/min/f64/desc"] = [
    @pl.col("f64")
    .rank(method_=@pl.RankMethod::Min, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/min/s/asc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Min).over([@pl.col("k")]),
  ]
  m["rank/max/v/asc"] = [
    @pl.col("v").rank(method_=@pl.RankMethod::Max).over([@pl.col("k")]),
  ]
  m["rank/max/v/desc"] = [
    @pl.col("v")
    .rank(method_=@pl.RankMethod::Max, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/max/vn/asc"] = [
    @pl.col("vn").rank(method_=@pl.RankMethod::Max).over([@pl.col("k")]),
  ]
  m["rank/max/f64/asc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Max).over([@pl.col("k")]),
  ]
  m["rank/max/f64/desc"] = [
    @pl.col("f64")
    .rank(method_=@pl.RankMethod::Max, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/max/s/asc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Max).over([@pl.col("k")]),
  ]
  m["rank/dense/v/asc"] = [
    @pl.col("v").rank(method_=@pl.RankMethod::Dense).over([@pl.col("k")]),
  ]
  m["rank/dense/v/desc"] = [
    @pl.col("v")
    .rank(method_=@pl.RankMethod::Dense, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/dense/vn/asc"] = [
    @pl.col("vn").rank(method_=@pl.RankMethod::Dense).over([@pl.col("k")]),
  ]
  m["rank/dense/vn/desc"] = [
    @pl.col("vn")
    .rank(method_=@pl.RankMethod::Dense, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/dense/f64/asc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Dense).over([@pl.col("k")]),
  ]
  m["rank/dense/f64/desc"] = [
    @pl.col("f64")
    .rank(method_=@pl.RankMethod::Dense, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/dense/s/asc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Dense).over([@pl.col("k")]),
  ]
  m["rank/dense/s/desc"] = [
    @pl.col("s")
    .rank(method_=@pl.RankMethod::Dense, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/ordinal/v/asc"] = [
    @pl.col("v").rank(method_=@pl.RankMethod::Ordinal).over([@pl.col("k")]),
  ]
  m["rank/ordinal/v/desc"] = [
    @pl.col("v")
    .rank(method_=@pl.RankMethod::Ordinal, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/ordinal/vn/asc"] = [
    @pl.col("vn").rank(method_=@pl.RankMethod::Ordinal).over([@pl.col("k")]),
  ]
  m["rank/ordinal/f64/asc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Ordinal).over([@pl.col("k")]),
  ]
  m["rank/ordinal/f64/desc"] = [
    @pl.col("f64")
    .rank(method_=@pl.RankMethod::Ordinal, descending=true)
    .over([@pl.col("k")]),
  ]
  m["rank/ordinal/s/asc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Ordinal).over([@pl.col("k")]),
  ]
  m["rank/b"] = [
    @pl.col("b").rank(method_=@pl.RankMethod::Average).over([@pl.col("k")]),
  ]
  m["reverse/v"] = [@pl.col("v").reverse().over([@pl.col("k")])]
  m["reverse/vn"] = [@pl.col("vn").reverse().over([@pl.col("k")])]
  m["reverse/s"] = [@pl.col("s").reverse().over([@pl.col("k")])]
  m["reverse/f64"] = [@pl.col("f64").reverse().over([@pl.col("k")])]
  m["fills/forward/vn"] = [
    @pl.col("vn")
    .fill_null_strategy(@pl.FillStrategy::Forward)
    .over([@pl.col("k")]),
  ]
  m["fills/forward/f64"] = [
    @pl.col("f64")
    .fill_null_strategy(@pl.FillStrategy::Forward)
    .over([@pl.col("k")]),
  ]
  m["fills/backward/vn"] = [
    @pl.col("vn")
    .fill_null_strategy(@pl.FillStrategy::Backward)
    .over([@pl.col("k")]),
  ]
  m["fills/backward/f64"] = [
    @pl.col("f64")
    .fill_null_strategy(@pl.FillStrategy::Backward)
    .over([@pl.col("k")]),
  ]
  m["fills/min/vn"] = [
    @pl.col("vn").fill_null_strategy(@pl.FillStrategy::Min).over([@pl.col("k")]),
  ]
  m["fills/min/f64"] = [
    @pl.col("f64")
    .fill_null_strategy(@pl.FillStrategy::Min)
    .over([@pl.col("k")]),
  ]
  m["fills/max/vn"] = [
    @pl.col("vn").fill_null_strategy(@pl.FillStrategy::Max).over([@pl.col("k")]),
  ]
  m["fills/max/f64"] = [
    @pl.col("f64")
    .fill_null_strategy(@pl.FillStrategy::Max)
    .over([@pl.col("k")]),
  ]
  m["fills/mean/vn"] = [
    @pl.col("vn")
    .fill_null_strategy(@pl.FillStrategy::Mean)
    .over([@pl.col("k")]),
  ]
  m["fills/mean/f64"] = [
    @pl.col("f64")
    .fill_null_strategy(@pl.FillStrategy::Mean)
    .over([@pl.col("k")]),
  ]
  m["fills/zero/vn"] = [
    @pl.col("vn")
    .fill_null_strategy(@pl.FillStrategy::Zero)
    .over([@pl.col("k")]),
  ]
  m["fills/zero/f64"] = [
    @pl.col("f64")
    .fill_null_strategy(@pl.FillStrategy::Zero)
    .over([@pl.col("k")]),
  ]
  m["fills/one/vn"] = [
    @pl.col("vn").fill_null_strategy(@pl.FillStrategy::One).over([@pl.col("k")]),
  ]
  m["fills/one/f64"] = [
    @pl.col("f64")
    .fill_null_strategy(@pl.FillStrategy::One)
    .over([@pl.col("k")]),
  ]
  m["fills/forward/s"] = [
    @pl.col("s")
    .fill_null_strategy(@pl.FillStrategy::Forward)
    .over([@pl.col("k")]),
  ]
  m["fills/forward-limit/vn"] = [
    @pl.col("vn")
    .fill_null_strategy(@pl.FillStrategy::Forward, limit=1)
    .over([@pl.col("k")]),
  ]
}

///|
fn golden_window_cases_4(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["seq/by-j"] = [
    @pl.col("v").cum_sum().over([@pl.col("j")]),
    @pl.col("v").shift(n=1).over([@pl.col("j")]).alias("sh"),
  ]
  m["seq/cum-two-keys"] = [
    @pl.col("v").cum_sum().over([@pl.col("k"), @pl.col("j")]),
  ]
  m["seq/cum-and-total"] = [
    @pl.col("v").cum_sum().over([@pl.col("k")]) /
    @pl.col("v").sum().over([@pl.col("k")]),
  ]
  m["seq/cum-over-len"] = [
    (@pl.col("v").cum_sum() / @pl.len()).over([@pl.col("k")]),
  ]
  m["seq/rank-over-len"] = [
    (@pl.col("v").rank(method_=@pl.RankMethod::Ordinal) / @pl.len()).over([
      @pl.col("k"),
    ]),
  ]
  m["seq/diff-of-cum"] = [@pl.col("v").cum_sum().diff(n=1).over([@pl.col("k")])]
  m["seq/cum-of-diff"] = [@pl.col("v").diff(n=1).cum_sum().over([@pl.col("k")])]
  m["seq/last-of-cum"] = [@pl.col("v").cum_sum().last().over([@pl.col("k")])]
  m["seq/shift-minus-self"] = [
    (@pl.col("v") - @pl.col("v").shift(n=1)).over([@pl.col("k")]),
  ]
  m["row/col"] = [@pl.col("v").over([@pl.col("k")])]
  m["row/col-str"] = [@pl.col("s").over([@pl.col("k")])]
  m["row/plus-lit"] = [(@pl.col("v") + @pl.lit_int(1L)).over([@pl.col("k")])]
  m["row/times"] = [(@pl.col("v") * @pl.col("y")).over([@pl.col("k")])]
  m["row/float"] = [(@pl.col("x") + @pl.lit_float(0.5)).over([@pl.col("k")])]
  m["row/is-null"] = [@pl.col("vn").is_null().over([@pl.col("k")])]
  m["row/is-not-null"] = [@pl.col("i32").is_not_null().over([@pl.col("k")])]
  m["row/cast"] = [
    @pl.col("v").cast(@pl.DataType::Float64, strict=false).over([@pl.col("k")]),
  ]
  m["row/neg"] = [(-@pl.col("v")).over([@pl.col("k")])]
  m["row/not"] = [@pl.col("b").not_().over([@pl.col("k")])]
  m["row/alias"] = [@pl.col("v").alias("z").over([@pl.col("k")])]
  m["row/str-len"] = [@pl.col("s").str().len_chars().over([@pl.col("k")])]
  m["row/when"] = [
    @pl.when(@pl.col("v").gt(@pl.lit_int(3L)))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(0L))
    .over([@pl.col("k")]),
  ]
  m["row/fill-null-lit"] = [
    @pl.col("vn").fill_null(@pl.lit_int(0L)).over([@pl.col("k")]),
  ]
  m["row/is-nan"] = [@pl.col("f64").is_nan().over([@pl.col("k")])]
  m["row/cols"] = [
    (@pl.cols(["v", "y"]) + @pl.lit_int(1L)).over([@pl.col("k")]),
  ]
  m["row/all-on-numbers"] = [
    (@pl.cols(["v", "x", "y"]) + @pl.lit_int(1L)).over([@pl.col("k")]),
  ]
  m["mix/dev-inside"] = [
    (@pl.col("x") - @pl.col("x").mean()).over([@pl.col("k")]),
  ]
  m["mix/dev-outside"] = [
    @pl.col("x") - @pl.col("x").mean().over([@pl.col("k")]),
  ]
  m["mix/dev-both-forms-same-name"] = [
    (@pl.col("v") - @pl.col("v").mean()).over([@pl.col("k")]),
    (@pl.col("v") - @pl.col("v").mean().over([@pl.col("k")])).alias("w"),
  ]
  m["mix/share"] = [
    (@pl.col("y") / @pl.col("y").sum().over([@pl.col("k")])).alias("share"),
  ]
  m["mix/share-inside"] = [
    (@pl.col("y") / @pl.col("y").sum()).over([@pl.col("k")]).alias("share"),
  ]
  m["mix/abs-dev"] = [
    (@pl.col("v") - @pl.col("v").mean()).abs().over([@pl.col("k")]),
  ]
  m["mix/max-minus-self"] = [
    (@pl.col("y").max() - @pl.col("y")).over([@pl.col("k")]),
  ]
  m["mix/when-agg"] = [
    @pl.when(@pl.col("v").gt(@pl.lit_int(3L)))
    .then(@pl.col("v"))
    .otherwise(@pl.col("v").sum())
    .over([@pl.col("k")]),
  ]
  m["mix/when-agg-mean"] = [
    @pl.when(@pl.col("v").gt(@pl.col("v").mean()))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(0L))
    .over([@pl.col("k")]),
  ]
  m["mix/fill-null-mean"] = [
    @pl.col("vn").fill_null(@pl.col("vn").mean()).over([@pl.col("k")]),
  ]
  m["mix/fill-null-agg-of-other"] = [
    @pl.col("vn").fill_null(@pl.col("v").max()).over([@pl.col("k")]),
  ]
  m["mix/sum-plus-sum"] = [
    (@pl.col("v").sum() + @pl.col("y").sum()).over([@pl.col("k")]),
  ]
  m["mix/sum-of-products"] = [
    (@pl.col("v") * @pl.col("x")).sum().over([@pl.col("k")]),
  ]
  m["mix/dev-sum"] = [
    (@pl.col("x") - @pl.col("x").mean()).sum().over([@pl.col("k")]),
  ]
  m["mix/zscore"] = [
    ((@pl.col("x") - @pl.col("x").mean()) / @pl.col("x").std(ddof=1)).over([
      @pl.col("k"),
    ]),
  ]
  m["mix/horizontal-agg"] = [
    @pl.sum_horizontal([@pl.col("v"), @pl.col("v").sum()]).over([@pl.col("k")]),
  ]
  m["mix/horizontal-two-aggs"] = [
    @pl.sum_horizontal([@pl.col("v").sum(), @pl.col("v").max()]).over([
      @pl.col("k"),
    ]),
  ]
  m["mix/horizontal-rows"] = [
    @pl.max_horizontal([@pl.col("v"), @pl.col("y")]).over([@pl.col("k")]),
  ]
  m["mix/any"] = [@pl.col("b").any().over([@pl.col("k")])]
  m["mix/all"] = [
    @pl.col("b").all(ignore_nulls=false).over([@pl.col("k")]).alias("a"),
  ]
  m["mix/any-of-cmp"] = [
    @pl.col("v").gt(@pl.lit_int(8L)).any().over([@pl.col("k")]),
  ]
  m["mix/filter-any"] = [
    @pl.col("b")
    .filter(@pl.col("v").gt(@pl.lit_int(2L)))
    .any()
    .over([@pl.col("k")]),
  ]
  m["mix/outer-alias"] = [
    @pl.col("v").sum().over([@pl.col("k")]).alias("tot"),
    @pl.len().over([@pl.col("k")]).alias("n"),
  ]
  m["mix/cast-sum"] = [
    @pl.col("v")
    .sum()
    .cast(@pl.DataType::Float64, strict=false)
    .over([@pl.col("k")]),
  ]
  m["mix/neg-sum"] = [(-@pl.col("v").sum()).over([@pl.col("k")])]
  m["mix/sum-plus-1"] = [
    (@pl.col("v").sum() + @pl.lit_int(1L)).over([@pl.col("k")]),
  ]
  m["mix/1-plus-sum"] = [
    (@pl.lit_int(1L) + @pl.col("v").sum()).over([@pl.col("k")]),
  ]
  m["mix/first-of-sorted-desc"] = [
    @pl.col("v").sort(descending=true).first().over([@pl.col("k")]),
  ]
  m["sort/v/asc"] = [@pl.col("v").sort().over([@pl.col("k")])]
  m["sort/v/desc"] = [@pl.col("v").sort(descending=true).over([@pl.col("k")])]
  m["sort/v/asc-nl"] = [@pl.col("v").sort(nulls_last=true).over([@pl.col("k")])]
  m["sort/v/desc-nl"] = [
    @pl.col("v").sort(descending=true, nulls_last=true).over([@pl.col("k")]),
  ]
  m["arg_sort/v"] = [@pl.col("v").arg_sort().over([@pl.col("k")])]
  m["sort/vn/asc"] = [@pl.col("vn").sort().over([@pl.col("k")])]
}

///|
fn golden_window_cases_5(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["sort/vn/desc"] = [@pl.col("vn").sort(descending=true).over([@pl.col("k")])]
  m["sort/vn/asc-nl"] = [
    @pl.col("vn").sort(nulls_last=true).over([@pl.col("k")]),
  ]
  m["sort/vn/desc-nl"] = [
    @pl.col("vn").sort(descending=true, nulls_last=true).over([@pl.col("k")]),
  ]
  m["arg_sort/vn"] = [@pl.col("vn").arg_sort().over([@pl.col("k")])]
  m["sort/f64/asc"] = [@pl.col("f64").sort().over([@pl.col("k")])]
  m["sort/f64/desc"] = [
    @pl.col("f64").sort(descending=true).over([@pl.col("k")]),
  ]
  m["sort/f64/asc-nl"] = [
    @pl.col("f64").sort(nulls_last=true).over([@pl.col("k")]),
  ]
  m["sort/f64/desc-nl"] = [
    @pl.col("f64").sort(descending=true, nulls_last=true).over([@pl.col("k")]),
  ]
  m["arg_sort/f64"] = [@pl.col("f64").arg_sort().over([@pl.col("k")])]
  m["sort/s/asc"] = [@pl.col("s").sort().over([@pl.col("k")])]
  m["sort/s/desc"] = [@pl.col("s").sort(descending=true).over([@pl.col("k")])]
  m["sort/s/asc-nl"] = [@pl.col("s").sort(nulls_last=true).over([@pl.col("k")])]
  m["sort/s/desc-nl"] = [
    @pl.col("s").sort(descending=true, nulls_last=true).over([@pl.col("k")]),
  ]
  m["arg_sort/s"] = [@pl.col("s").arg_sort().over([@pl.col("k")])]
  m["sort/b/asc"] = [@pl.col("b").sort().over([@pl.col("k")])]
  m["sort/b/desc"] = [@pl.col("b").sort(descending=true).over([@pl.col("k")])]
  m["sort/b/asc-nl"] = [@pl.col("b").sort(nulls_last=true).over([@pl.col("k")])]
  m["sort/b/desc-nl"] = [
    @pl.col("b").sort(descending=true, nulls_last=true).over([@pl.col("k")]),
  ]
  m["arg_sort/b"] = [@pl.col("b").arg_sort().over([@pl.col("k")])]
  m["arg_sort/desc-nl"] = [
    @pl.col("vn")
    .arg_sort(descending=true, nulls_last=true)
    .over([@pl.col("k")]),
  ]
  m["sort_by/x"] = [
    @pl.col("y").sort_by([@pl.col("x"), @pl.col("id")]).over([@pl.col("k")]),
  ]
  m["sort_by/x-desc"] = [
    @pl.col("y")
    .sort_by([@pl.col("x"), @pl.col("id")], descending=[true, false])
    .over([@pl.col("k")]),
  ]
  m["sort_by/v"] = [
    @pl.col("y").sort_by([@pl.col("v"), @pl.col("id")]).over([@pl.col("k")]),
  ]
  m["sort_by/v-desc"] = [
    @pl.col("y")
    .sort_by([@pl.col("v"), @pl.col("id")], descending=[true, false])
    .over([@pl.col("k")]),
  ]
  m["sort_by/self-key-null"] = [
    @pl.col("vn")
    .sort_by([@pl.col("vn"), @pl.col("id")], nulls_last=true)
    .over([@pl.col("k")]),
  ]
  m["sort_by/sum-key"] = [
    @pl.col("v").sort_by([@pl.col("y").sum()]).over([@pl.col("k")]),
  ]
  m["sort_by/sum-base"] = [
    @pl.col("v").sum().sort_by([@pl.col("y")]).over([@pl.col("k")]),
  ]
  m["sort_by/first"] = [
    @pl.col("y")
    .sort_by([@pl.col("v"), @pl.col("id")])
    .first()
    .over([@pl.col("k")]),
  ]
  m["sort_by/last-desc"] = [
    @pl.col("y")
    .sort_by([@pl.col("v"), @pl.col("id")], descending=[true, true])
    .last()
    .over([@pl.col("k")]),
  ]
  m["sort/first"] = [@pl.col("v").sort().first().over([@pl.col("k")])]
  m["sort/last"] = [@pl.col("v").sort().last().over([@pl.col("k")])]
  m["sort/sum-of-sorted"] = [@pl.col("v").sort().sum().over([@pl.col("k")])]
  m["sort/sum-then-sort"] = [@pl.col("v").sum().sort().over([@pl.col("k")])]
  m["sort/plus-sum"] = [
    (@pl.col("v").sort() + @pl.col("v").sum()).over([@pl.col("k")]),
  ]
  m["sort/lit"] = [@pl.lit_int(3L).sort().over([@pl.col("k")])]
  m["sort/key-id"] = [@pl.col("v").sort().over([@pl.col("id")])]
  m["sort/by-two"] = [@pl.col("v").sort().over([@pl.col("k"), @pl.col("j")])]
  m["head/ok-3"] = [@pl.col("v").head(n=6).over([@pl.col("k")])]
  m["head/ok-100"] = [@pl.col("v").head(n=100).over([@pl.col("k")])]
  m["head/ok-by-id-1"] = [@pl.col("v").head(n=1).over([@pl.col("id")])]
  m["head/ok-by-k2-2"] = [@pl.col("v").head(n=2).over([@pl.col("k2")])]
  m["head/short-1"] = [@pl.col("v").head(n=1).over([@pl.col("k")])]
  m["head/short-2"] = [@pl.col("v").head(n=2).over([@pl.col("k")])]
  m["head/zero"] = [@pl.col("v").head(n=0).over([@pl.col("k")])]
  m["head/by-k2-1"] = [@pl.col("v").head(n=1).over([@pl.col("k2")])]
  m["tail/short-1"] = [@pl.col("v").tail(n=1).over([@pl.col("k")])]
  m["tail/ok-by-k2-2"] = [@pl.col("v").tail(n=2).over([@pl.col("k2")])]
  m["tail/ok-by-id-1"] = [@pl.col("v").tail(n=1).over([@pl.col("id")])]
  m["slice/short"] = [@pl.col("v").slice(1, length=2).over([@pl.col("k")])]
  m["slice/ok-by-k2"] = [@pl.col("v").slice(0, length=5).over([@pl.col("k2")])]
  m["slice/offset-by-k2"] = [@pl.col("v").slice(1).over([@pl.col("k2")])]
  m["unique/by-id"] = [
    @pl.col("v").unique(maintain_order=true).over([@pl.col("id")]),
  ]
  m["unique/by-k"] = [
    @pl.col("v").unique(maintain_order=true).over([@pl.col("k")]),
  ]
  m["unique/by-k2-distinct"] = [
    @pl.col("y").unique(maintain_order=true).over([@pl.col("k2")]),
  ]
  m["unique/by-k2-dups"] = [
    @pl.col("k").unique(maintain_order=true).over([@pl.col("k2")]),
  ]
  m["unique/len"] = [@pl.col("v").unique().len().over([@pl.col("k")])]
  m["unique/n_unique-same"] = [
    @pl.col("v").unique().n_unique().over([@pl.col("k")]),
    @pl.col("v").n_unique().over([@pl.col("k")]).alias("m"),
  ]
  m["drop_nulls/by-k"] = [@pl.col("vn").drop_nulls().over([@pl.col("k")])]
  m["drop_nulls/no-nulls"] = [@pl.col("v").drop_nulls().over([@pl.col("k")])]
  m["drop_nulls/by-id"] = [@pl.col("vn").drop_nulls().over([@pl.col("id")])]
}

///|
fn golden_window_cases_6(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["drop_nulls/sum"] = [@pl.col("vn").drop_nulls().sum().over([@pl.col("k")])]
  m["filter/by-k"] = [
    @pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(2L))).over([@pl.col("k")]),
  ]
  m["filter/all-true"] = [
    @pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(-2L))).over([@pl.col("k")]),
  ]
  m["filter/all-false"] = [
    @pl.col("v").filter(@pl.col("v").lt(@pl.lit_int(-2L))).over([@pl.col("k")]),
  ]
  m["filter/by-id-true"] = [
    @pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(-2L))).over([@pl.col("id")]),
  ]
  m["filter/by-id-mixed"] = [
    @pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(4L))).over([@pl.col("id")]),
  ]
  m["filter/sum"] = [
    @pl.col("v")
    .filter(@pl.col("v").gt(@pl.lit_int(2L)))
    .sum()
    .over([@pl.col("k")]),
  ]
  m["filter/sum-empty-group"] = [
    @pl.col("v")
    .filter(@pl.col("v").gt(@pl.lit_int(100L)))
    .sum()
    .over([@pl.col("k")]),
  ]
  m["filter/len"] = [
    @pl.col("v")
    .filter(@pl.col("v").gt(@pl.lit_int(2L)))
    .len()
    .over([@pl.col("k")]),
  ]
  m["filter/mean"] = [
    @pl.col("x")
    .filter(@pl.col("v").gt(@pl.lit_int(2L)))
    .mean()
    .over([@pl.col("k")]),
  ]
  m["filter/agg-in-predicate"] = [
    @pl.col("v")
    .filter(@pl.col("v").gt(@pl.col("v").mean()))
    .sum()
    .over([@pl.col("k")]),
  ]
  m["filter/null-predicate"] = [
    @pl.col("v").filter(@pl.col("b")).sum().over([@pl.col("k")]),
  ]
  m["head/sum"] = [@pl.col("v").head(n=2).sum().over([@pl.col("k")])]
  m["tail/first"] = [@pl.col("v").tail(n=2).first().over([@pl.col("k")])]
  m["slice/last"] = [
    @pl.col("v").slice(1, length=2).last().over([@pl.col("k")]),
  ]
  m["head/sum-plus-len"] = [
    (@pl.col("v").head(n=2).sum() + @pl.len()).over([@pl.col("k")]),
  ]
  m["key/i32"] = [
    @pl.col("y").sum().over([@pl.col("i32")]),
    @pl.len().over([@pl.col("i32")]).alias("n"),
    @pl.col("y").cum_sum().over([@pl.col("i32")]).alias("cs"),
  ]
  m["key/i32/e"] = [
    @pl.col("y").sum().over([@pl.col("i32")]),
    @pl.len().over([@pl.col("i32")]).alias("n"),
  ]
  m["key/i64"] = [
    @pl.col("y").sum().over([@pl.col("i64")]),
    @pl.len().over([@pl.col("i64")]).alias("n"),
    @pl.col("y").cum_sum().over([@pl.col("i64")]).alias("cs"),
  ]
  m["key/i64/e"] = [
    @pl.col("y").sum().over([@pl.col("i64")]),
    @pl.len().over([@pl.col("i64")]).alias("n"),
  ]
  m["key/f32"] = [
    @pl.col("y").sum().over([@pl.col("f32")]),
    @pl.len().over([@pl.col("f32")]).alias("n"),
    @pl.col("y").cum_sum().over([@pl.col("f32")]).alias("cs"),
  ]
  m["key/f32/e"] = [
    @pl.col("y").sum().over([@pl.col("f32")]),
    @pl.len().over([@pl.col("f32")]).alias("n"),
  ]
  m["key/f64"] = [
    @pl.col("y").sum().over([@pl.col("f64")]),
    @pl.len().over([@pl.col("f64")]).alias("n"),
    @pl.col("y").cum_sum().over([@pl.col("f64")]).alias("cs"),
  ]
  m["key/f64/e"] = [
    @pl.col("y").sum().over([@pl.col("f64")]),
    @pl.len().over([@pl.col("f64")]).alias("n"),
  ]
  m["key/s"] = [
    @pl.col("y").sum().over([@pl.col("s")]),
    @pl.len().over([@pl.col("s")]).alias("n"),
    @pl.col("y").cum_sum().over([@pl.col("s")]).alias("cs"),
  ]
  m["key/s/e"] = [
    @pl.col("y").sum().over([@pl.col("s")]),
    @pl.len().over([@pl.col("s")]).alias("n"),
  ]
  m["key/b"] = [
    @pl.col("y").sum().over([@pl.col("b")]),
    @pl.len().over([@pl.col("b")]).alias("n"),
    @pl.col("y").cum_sum().over([@pl.col("b")]).alias("cs"),
  ]
  m["key/b/e"] = [
    @pl.col("y").sum().over([@pl.col("b")]),
    @pl.len().over([@pl.col("b")]).alias("n"),
  ]
  m["key/d"] = [
    @pl.col("y").sum().over([@pl.col("d")]),
    @pl.len().over([@pl.col("d")]).alias("n"),
    @pl.col("y").cum_sum().over([@pl.col("d")]).alias("cs"),
  ]
  m["key/d/e"] = [
    @pl.col("y").sum().over([@pl.col("d")]),
    @pl.len().over([@pl.col("d")]).alias("n"),
  ]
  m["key/dt"] = [
    @pl.col("y").sum().over([@pl.col("dt")]),
    @pl.len().over([@pl.col("dt")]).alias("n"),
    @pl.col("y").cum_sum().over([@pl.col("dt")]).alias("cs"),
  ]
  m["key/dt/e"] = [
    @pl.col("y").sum().over([@pl.col("dt")]),
    @pl.len().over([@pl.col("dt")]).alias("n"),
  ]
  m["key/n"] = [
    @pl.col("y").sum().over([@pl.col("n")]),
    @pl.len().over([@pl.col("n")]).alias("n"),
    @pl.col("y").cum_sum().over([@pl.col("n")]).alias("cs"),
  ]
  m["key/n/e"] = [
    @pl.col("y").sum().over([@pl.col("n")]),
    @pl.len().over([@pl.col("n")]).alias("n"),
  ]
  m["key/multi/k+j"] = [
    @pl.col("y").sum().over([@pl.col("k"), @pl.col("j")]),
    @pl.col("y").cum_sum().over([@pl.col("k"), @pl.col("j")]).alias("cs"),
  ]
  m["key/multi/j+k"] = [
    @pl.col("y").sum().over([@pl.col("j"), @pl.col("k")]),
    @pl.col("y").cum_sum().over([@pl.col("j"), @pl.col("k")]).alias("cs"),
  ]
  m["key/multi/i32+s"] = [
    @pl.col("y").sum().over([@pl.col("i32"), @pl.col("s")]),
    @pl.col("y").cum_sum().over([@pl.col("i32"), @pl.col("s")]).alias("cs"),
  ]
  m["key/multi/b+d"] = [
    @pl.col("y").sum().over([@pl.col("b"), @pl.col("d")]),
    @pl.col("y").cum_sum().over([@pl.col("b"), @pl.col("d")]).alias("cs"),
  ]
  m["key/multi/f64+f32"] = [
    @pl.col("y").sum().over([@pl.col("f64"), @pl.col("f32")]),
    @pl.col("y").cum_sum().over([@pl.col("f64"), @pl.col("f32")]).alias("cs"),
  ]
  m["key/multi/n+i32"] = [
    @pl.col("y").sum().over([@pl.col("n"), @pl.col("i32")]),
    @pl.col("y").cum_sum().over([@pl.col("n"), @pl.col("i32")]).alias("cs"),
  ]
  m["key/multi/k+b+dt"] = [
    @pl.col("y").sum().over([@pl.col("k"), @pl.col("b"), @pl.col("dt")]),
    @pl.col("y")
    .cum_sum()
    .over([@pl.col("k"), @pl.col("b"), @pl.col("dt")])
    .alias("cs"),
  ]
  m["key/multi/e"] = [@pl.col("y").sum().over([@pl.col("k"), @pl.col("j")])]
  m["key/expr/mod"] = [
    @pl.col("y").sum().over([@pl.col("k") % @pl.lit_int(2L)]),
  ]
  m["key/expr/mod-i32"] = [
    @pl.col("y").sum().over([@pl.col("i32") % @pl.lit_int(2L)]),
  ]
  m["key/expr/k-plus"] = [
    @pl.col("y").sum().over([@pl.col("k") + @pl.lit_int(1L)]),
  ]
  m["key/expr/is-null"] = [@pl.col("y").sum().over([@pl.col("i32").is_null()])]
  m["key/expr/is-nan"] = [@pl.col("y").sum().over([@pl.col("f64").is_nan()])]
  m["key/expr/cmp"] = [
    @pl.col("y").sum().over([@pl.col("v").gt(@pl.lit_int(3L))]),
  ]
  m["key/expr/str-len"] = [
    @pl.col("y").sum().over([@pl.col("s").str().len_chars()]),
  ]
  m["key/expr/cast"] = [
    @pl.col("y")
    .sum()
    .over([@pl.col("f64").cast(@pl.DataType::Int64, strict=false)]),
  ]
  m["key/expr/alias"] = [@pl.col("y").sum().over([@pl.col("k").alias("q")])]
  m["key/expr/two"] = [
    @pl.col("y").sum().over([@pl.col("k") % @pl.lit_int(2L), @pl.col("b")]),
  ]
  m["key/expr/sort"] = [@pl.col("y").sum().over([@pl.col("k").sort()])]
  m["key/expr/cum-sum"] = [
    @pl.col("y").sum().over([@pl.col("id").cum_sum() % @pl.lit_int(2L)]),
  ]
  m["key/expr/over"] = [
    @pl.col("y").sum().over([@pl.col("v").cum_sum().over([@pl.col("k")])]),
  ]
  m["key/expr/over-sum"] = [
    @pl.col("y").sum().over([@pl.col("v").sum().over([@pl.col("k")])]),
  ]
  m["key/lit"] = [@pl.col("y").sum().over([@pl.lit_int(1L)])]
  m["key/lit-str"] = [@pl.col("y").sum().over([@pl.lit_str("q")])]
  m["key/lit-plus-col"] = [
    @pl.col("y").sum().over([@pl.lit_int(1L), @pl.col("k")]),
  ]
  m["key/agg"] = [@pl.col("y").sum().over([@pl.col("k").sum()])]
}

///|
fn golden_window_cases_7(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["key/agg-plus-col"] = [
    @pl.col("y").sum().over([@pl.col("k").sum(), @pl.col("j")]),
  ]
  m["key/head-one"] = [@pl.col("y").sum().over([@pl.col("k").head(n=1)])]
  m["key/head-two"] = [@pl.col("y").sum().over([@pl.col("k").head(n=2)])]
  m["key/lit/e"] = [@pl.col("y").sum().over([@pl.lit_int(1L)])]
  m["key/cols"] = [@pl.cols(["v", "y"]).sum().over([@pl.cols(["k", "j"])])]
  m["key/cols-one-side"] = [@pl.col("v").sum().over([@pl.cols(["k", "j"])])]
  m["key/cols-mismatch"] = [
    @pl.cols(["v", "y", "x"]).sum().over([@pl.cols(["k", "j"])]),
  ]
  m["key/cols-empty"] = [@pl.col("v").sum().over([@pl.cols([])])]
  m["key/none"] = [@pl.col("v").sum().over([])]
  m["key/none/e"] = [@pl.col("v").sum().over([])]
  m["key/missing"] = [@pl.col("v").sum().over([@pl.col("zz")])]
  m["key/missing-and-column"] = [@pl.col("zy").sum().over([@pl.col("zz")])]
  m["key/missing-second"] = [
    @pl.col("v").sum().over([@pl.col("k"), @pl.col("zz")]),
  ]
  m["key/type-error"] = [@pl.col("v").sum().over([@pl.col("k") + @pl.col("s")])]
  m["key/same-twice"] = [@pl.col("y").sum().over([@pl.col("k"), @pl.col("k")])]
  m["key/f64-focus"] = [
    @pl.col("y").sum().over([@pl.col("f64")]),
    @pl.col("f64").first().over([@pl.col("f64")]).alias("fk"),
  ]
  m["key/f32-focus"] = [
    @pl.col("y").len().over([@pl.col("f32")]),
    @pl.col("f32").first().over([@pl.col("f32")]).alias("fk"),
  ]
  m["name/two-same"] = [
    @pl.col("v").sum().over([@pl.col("k")]),
    @pl.col("v").cum_sum().over([@pl.col("j")]),
  ]
  m["name/two-alias"] = [
    @pl.col("v").sum().over([@pl.col("k")]).alias("a"),
    @pl.col("v").cum_sum().over([@pl.col("j")]).alias("b"),
  ]
  m["name/with-columns-two"] = [
    @pl.col("v").sum().over([@pl.col("k")]).alias("a"),
    @pl.col("v").cum_sum().over([@pl.col("k")]).alias("b"),
  ]
  m["name/with-columns-dup"] = [
    @pl.col("v").sum().over([@pl.col("k")]).alias("a"),
    @pl.col("v").cum_sum().over([@pl.col("k")]).alias("a"),
  ]
  m["name/select-lit"] = [
    @pl.lit(@pl.AnyValue::Int32(1)).alias("one"),
    @pl.col("v").sum().over([@pl.col("k")]).alias("t"),
  ]
  m["name/alias-in-key"] = [
    @pl.col("v").sum().alias("inner").over([@pl.col("k")]),
  ]
  m["name/alias-over-alias"] = [
    @pl.col("v").sum().alias("inner").over([@pl.col("k")]).alias("outer"),
  ]
  m["name/cols-both"] = [@pl.cols(["v", "y"]).cum_sum().over([@pl.col("k")])]
  m["name/all-numbers"] = [
    @pl.cols(["v", "x", "y"]).cum_sum().over([@pl.col("k")]),
  ]
  m["name/key-column-too"] = [
    @pl.col("k"),
    @pl.col("v").sum().over([@pl.col("k")]).alias("t"),
  ]
  m["name/same-as-key"] = [@pl.col("v").sum().over([@pl.col("k")]).alias("k")]
  m["nest/sum-over-k-over-j"] = [
    @pl.col("v").sum().over([@pl.col("k")]).over([@pl.col("j")]),
  ]
  m["nest/cum-over-k-over-j"] = [
    @pl.col("v").cum_sum().over([@pl.col("k")]).over([@pl.col("j")]),
  ]
  m["nest/same-as-two-keys"] = [
    @pl.col("v").sum().over([@pl.col("k"), @pl.col("j")]).alias("two"),
  ]
  m["nest/sum-of-window"] = [
    @pl.col("v").sum().over([@pl.col("k")]).sum().over([@pl.col("k")]),
  ]
  m["nest/inner-different-key"] = [
    (@pl.col("v") - @pl.col("v").mean().over([@pl.col("j")])).over([
      @pl.col("k"),
    ]),
  ]
  m["nest/sum-plus-window"] = [
    @pl.col("v").sum().over([@pl.col("k")]) +
    @pl.col("v").max().over([@pl.col("j")]),
  ]
  m["frame/filter/above-mean"] = [
    @pl.col("v").gt(@pl.col("v").mean().over([@pl.col("k")])),
  ]
  m["frame/filter/is-max"] = [
    @pl.col("v").eq(@pl.col("v").max().over([@pl.col("k")])),
  ]
  m["frame/filter/sum-gt"] = [
    @pl.col("v").sum().over([@pl.col("k")]).gt(@pl.lit_int(20L)),
  ]
  m["frame/filter/cum"] = [
    @pl.col("v").cum_sum().over([@pl.col("k")]).le(@pl.lit_int(10L)),
  ]
  m["frame/filter/rank-first"] = [
    @pl.col("v")
    .rank(method_=@pl.RankMethod::Ordinal)
    .over([@pl.col("k")])
    .eq(@pl.lit_int(1L)),
  ]
  m["frame/filter/len"] = [@pl.len().over([@pl.col("k")]).gt(@pl.lit_int(2L))]
  m["frame/filter/sorted-is-itself"] = [
    @pl.col("v").eq(@pl.col("v").sort().over([@pl.col("k")])),
  ]
  m["frame/filter/short"] = [
    @pl.col("v").gt(@pl.col("v").head(n=2).over([@pl.col("k")])),
  ]
  m["frame/filter/e"] = [
    @pl.col("v").gt(@pl.col("v").mean().over([@pl.col("k")])),
  ]
  m["frame/sort/sum"] = [@pl.col("v").sum().over([@pl.col("k")]), @pl.col("id")]
  m["frame/sort/cum"] = [
    @pl.col("v").cum_sum().over([@pl.col("k")]),
    @pl.col("id"),
  ]
  m["frame/sort/rank"] = [
    @pl.col("v").rank(method_=@pl.RankMethod::Min).over([@pl.col("j")]),
    @pl.col("id"),
  ]
  m["frame/sort/len-then-id"] = [@pl.len().over([@pl.col("k")]), @pl.col("id")]
  m["frame/sort/e"] = [@pl.col("v").sum().over([@pl.col("k")]), @pl.col("id")]
  m["e/sum/i32"] = [
    @pl.col("i32").sum().over([@pl.col("k")]),
    @pl.col("i32").mean().over([@pl.col("k")]).alias("m"),
    @pl.len().over([@pl.col("k")]).alias("n"),
  ]
  m["e/sum/f64"] = [
    @pl.col("f64").sum().over([@pl.col("k")]),
    @pl.col("f64").mean().over([@pl.col("k")]).alias("m"),
    @pl.len().over([@pl.col("k")]).alias("n"),
  ]
  m["e/sum/s"] = [
    @pl.col("s").sum().over([@pl.col("k")]),
    @pl.col("s").mean().over([@pl.col("k")]).alias("m"),
    @pl.len().over([@pl.col("k")]).alias("n"),
  ]
  m["e/sum/n"] = [
    @pl.col("n").sum().over([@pl.col("k")]),
    @pl.col("n").mean().over([@pl.col("k")]).alias("m"),
    @pl.len().over([@pl.col("k")]).alias("n"),
  ]
  m["e/cum"] = [
    @pl.col("v").cum_sum().over([@pl.col("k")]),
    @pl.col("s").shift(n=1).over([@pl.col("k")]).alias("sh"),
    @pl.col("f64")
    .rank(method_=@pl.RankMethod::Average)
    .over([@pl.col("k")])
    .alias("rk"),
  ]
  m["e/sort"] = [
    @pl.col("v").sort().over([@pl.col("k")]),
    @pl.col("s").arg_sort().over([@pl.col("k")]).alias("a"),
  ]
  m["e/head"] = [@pl.col("v").head(n=2).over([@pl.col("k")])]
  m["e/unique"] = [@pl.col("v").unique().over([@pl.col("k")])]
  m["e/lit"] = [
    @pl.lit_int(1L).over([@pl.col("k")]),
    @pl.lit_float(2.5).over([@pl.col("k")]).alias("f"),
    @pl.lit_str("q").over([@pl.col("k")]).alias("s"),
  ]
  m["e/row"] = [
    (@pl.col("v") + @pl.lit_int(1L)).over([@pl.col("k")]),
    @pl.col("s").over([@pl.col("k")]),
  ]
  m["e/with-columns"] = [@pl.col("v").sum().over([@pl.col("k")]).alias("t")]
  m["e/key-lit"] = [@pl.col("v").cum_sum().over([@pl.lit_int(1L)])]
}

///|
fn golden_window_cases_8(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["e/missing"] = [@pl.col("zz").sum().over([@pl.col("k")])]
  m["one/sum"] = [
    @pl.col("v").sum().over([@pl.col("k")]),
    @pl.col("v").cum_sum().over([@pl.col("k")]).alias("c"),
    @pl.len().over([@pl.col("k")]).alias("n"),
  ]
  m["one/shift"] = [
    @pl.col("v").shift(n=1).over([@pl.col("k")]),
    @pl.col("v")
    .rank(method_=@pl.RankMethod::Average)
    .over([@pl.col("k")])
    .alias("r"),
  ]
  m["one/head"] = [
    @pl.col("v").head(n=1).over([@pl.col("k")]),
    @pl.col("v").sort().over([@pl.col("k")]).alias("s"),
  ]
  m["one/head-too-long"] = [@pl.col("v").head(n=5).over([@pl.col("k")])]
  m["one/filter"] = [
    @pl.col("v").filter(@pl.col("v").gt(@pl.lit_int(100L))).over([@pl.col("k")]),
  ]
  m["one/unique"] = [@pl.col("v").unique().over([@pl.col("k")])]
  m["z0/sum"] = [@pl.col("v").sum().over([@pl.col("k")])]
  m["z0/lit"] = [@pl.lit_int(1L).over([@pl.col("k")])]
  m["z0/none"] = [@pl.lit_int(1L).over([])]
  m["z0/keys-lit"] = [@pl.lit_int(1L).over([@pl.lit_int(1L)])]
  m["big/sum/x"] = [@pl.col("x").sum().over([@pl.col("k")])]
  m["big/sum/xf"] = [@pl.col("xf").sum().over([@pl.col("k")])]
  m["big/sum/v"] = [@pl.col("v").sum().over([@pl.col("k")])]
  m["big/mean/x"] = [@pl.col("x").mean().over([@pl.col("k")])]
  m["big/mean/xf"] = [@pl.col("xf").mean().over([@pl.col("k")])]
  m["big/mean/v"] = [@pl.col("v").mean().over([@pl.col("k")])]
  m["big/min/x"] = [@pl.col("x").min().over([@pl.col("k")])]
  m["big/min/xf"] = [@pl.col("xf").min().over([@pl.col("k")])]
  m["big/min/v"] = [@pl.col("v").min().over([@pl.col("k")])]
  m["big/max/x"] = [@pl.col("x").max().over([@pl.col("k")])]
  m["big/max/xf"] = [@pl.col("xf").max().over([@pl.col("k")])]
  m["big/max/v"] = [@pl.col("v").max().over([@pl.col("k")])]
  m["big/median/x"] = [@pl.col("x").median().over([@pl.col("k")])]
  m["big/median/xf"] = [@pl.col("xf").median().over([@pl.col("k")])]
  m["big/median/v"] = [@pl.col("v").median().over([@pl.col("k")])]
  m["big/first/x"] = [@pl.col("x").first().over([@pl.col("k")])]
  m["big/first/xf"] = [@pl.col("xf").first().over([@pl.col("k")])]
  m["big/first/v"] = [@pl.col("v").first().over([@pl.col("k")])]
  m["big/last/x"] = [@pl.col("x").last().over([@pl.col("k")])]
  m["big/last/xf"] = [@pl.col("xf").last().over([@pl.col("k")])]
  m["big/last/v"] = [@pl.col("v").last().over([@pl.col("k")])]
  m["big/std1/x"] = [@pl.col("x").std(ddof=1).over([@pl.col("k")])]
  m["big/std1/xf"] = [@pl.col("xf").std(ddof=1).over([@pl.col("k")])]
  m["big/var1/x"] = [@pl.col("x").var_(ddof=1).over([@pl.col("k")])]
  m["big/var1/xf"] = [@pl.col("xf").var_(ddof=1).over([@pl.col("k")])]
  m["big/var0/x"] = [@pl.col("x").var_(ddof=0).over([@pl.col("k")])]
  m["big/var0/xf"] = [@pl.col("xf").var_(ddof=0).over([@pl.col("k")])]
  m["big/dev-sum"] = [
    (@pl.col("x") - @pl.col("x").mean()).sum().over([@pl.col("k")]),
  ]
  m["big/dev-inside"] = [
    (@pl.col("x") - @pl.col("x").mean()).over([@pl.col("k")]),
  ]
  m["big/cum"] = [@pl.col("x").cum_sum().over([@pl.col("k")])]
  m["big/sum-by-expr"] = [
    @pl.col("x").sum().over([@pl.col("v") % @pl.lit_int(3L)]),
  ]
  m["part/all-rows-head"] = [@pl.col("v").head(n=3).over([@pl.lit_int(1L)])]
  m["part/agg-key-head"] = [@pl.col("v").head(n=3).over([@pl.col("k").sum()])]
  m["part/first-key-head"] = [
    @pl.col("v").head(n=3).over([@pl.col("k").first()]),
  ]
  m["part/all-rows-filter"] = [
    @pl.col("v")
    .filter(@pl.col("v").gt(@pl.lit_int(100L)))
    .over([@pl.lit_int(1L)]),
  ]
  m["part/all-rows-ok"] = [
    @pl.col("v").cum_sum().over([@pl.lit_int(1L)]),
    @pl.col("v").sum().over([@pl.lit_int(1L)]).alias("t"),
  ]
  m["dv/quotient-times-col"] = [
    (@pl.col("f").max() / @pl.col("f").sum() * @pl.col("f")).over([@pl.col("k")]),
  ]
  m["dv/quotient-over-col"] = [
    (@pl.col("f").last() / @pl.col("f").sum() / @pl.col("f")).over([
      @pl.col("k"),
    ]),
  ]
  m["dv/sum-per-len-over-col"] = [
    (@pl.col("f").sum() / @pl.len() / @pl.col("f")).over([@pl.col("k")]),
  ]
  m["dv/sum-per-len-times-col"] = [
    (@pl.col("f").sum() / @pl.len() * @pl.col("f")).over([@pl.col("k")]),
  ]
  m["dv/div/f-by-first"] = [
    (@pl.col("f") / @pl.col("f").first()).over([@pl.col("k")]),
  ]
  m["dv/div/f-by-sum"] = [
    (@pl.col("f") / @pl.col("f").sum()).over([@pl.col("k")]),
  ]
  m["dv/div/f-by-mixed"] = [
    (@pl.col("f") / (@pl.col("f") + @pl.col("f").first())).over([@pl.col("k")]),
  ]
  m["dv/div/f3-by-first"] = [
    (@pl.col("f3") / @pl.col("f3").first()).over([@pl.col("k")]),
  ]
  m["dv/div/f3-by-sum"] = [
    (@pl.col("f3") / @pl.col("f3").sum()).over([@pl.col("k")]),
  ]
  m["dv/div/f3-by-mixed"] = [
    (@pl.col("f3") / (@pl.col("f3") + @pl.col("f3").first())).over([
      @pl.col("k"),
    ]),
  ]
  m["dv/div/n-by-first"] = [
    (@pl.col("n") / @pl.col("n").first()).over([@pl.col("k")]),
  ]
  m["dv/div/n-by-sum"] = [
    (@pl.col("n") / @pl.col("n").sum()).over([@pl.col("k")]),
  ]
  m["dv/div/n-by-mixed"] = [
    (@pl.col("n") / (@pl.col("n") + @pl.col("n").first())).over([@pl.col("k")]),
  ]
}

///|
fn golden_window_cases_9(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["dv/floordiv/f-by-first"] = [
    @pl.col("f").floor_div(@pl.col("f").first()).over([@pl.col("k")]),
  ]
  m["dv/floordiv/f-by-sum"] = [
    @pl.col("f").floor_div(@pl.col("f").sum()).over([@pl.col("k")]),
  ]
  m["dv/floordiv/f-by-mixed"] = [
    @pl.col("f")
    .floor_div(@pl.col("f") + @pl.col("f").first())
    .over([@pl.col("k")]),
  ]
  m["dv/floordiv/f3-by-first"] = [
    @pl.col("f3").floor_div(@pl.col("f3").first()).over([@pl.col("k")]),
  ]
  m["dv/floordiv/f3-by-sum"] = [
    @pl.col("f3").floor_div(@pl.col("f3").sum()).over([@pl.col("k")]),
  ]
  m["dv/floordiv/f3-by-mixed"] = [
    @pl.col("f3")
    .floor_div(@pl.col("f3") + @pl.col("f3").first())
    .over([@pl.col("k")]),
  ]
  m["dv/floordiv/n-by-first"] = [
    @pl.col("n").floor_div(@pl.col("n").first()).over([@pl.col("k")]),
  ]
  m["dv/floordiv/n-by-sum"] = [
    @pl.col("n").floor_div(@pl.col("n").sum()).over([@pl.col("k")]),
  ]
  m["dv/floordiv/n-by-mixed"] = [
    @pl.col("n")
    .floor_div(@pl.col("n") + @pl.col("n").first())
    .over([@pl.col("k")]),
  ]
  m["dv/mod/f-by-first"] = [
    (@pl.col("f") % @pl.col("f").first()).over([@pl.col("k")]),
  ]
  m["dv/mod/f-by-sum"] = [
    (@pl.col("f") % @pl.col("f").sum()).over([@pl.col("k")]),
  ]
  m["dv/mod/f-by-mixed"] = [
    (@pl.col("f") % (@pl.col("f") + @pl.col("f").first())).over([@pl.col("k")]),
  ]
  m["dv/mod/f3-by-first"] = [
    (@pl.col("f3") % @pl.col("f3").first()).over([@pl.col("k")]),
  ]
  m["dv/mod/f3-by-sum"] = [
    (@pl.col("f3") % @pl.col("f3").sum()).over([@pl.col("k")]),
  ]
  m["dv/mod/f3-by-mixed"] = [
    (@pl.col("f3") % (@pl.col("f3") + @pl.col("f3").first())).over([
      @pl.col("k"),
    ]),
  ]
  m["dv/mod/n-by-first"] = [
    (@pl.col("n") % @pl.col("n").first()).over([@pl.col("k")]),
  ]
  m["dv/mod/n-by-sum"] = [
    (@pl.col("n") % @pl.col("n").sum()).over([@pl.col("k")]),
  ]
  m["dv/mod/n-by-mixed"] = [
    (@pl.col("n") % (@pl.col("n") + @pl.col("n").first())).over([@pl.col("k")]),
  ]
  m["dv/rand/0"] = [
    (@pl.col("f").min() /
    @pl.col("f3").mean() *
    @pl.col("f3").floor_div(@pl.col("f").max()) %
    (@pl.col("f3") % @pl.col("f") % (@pl.col("f3") / @pl.col("f3").first()))).over([
        @pl.col("k"),
      ],
    ),
  ]
  m["dv/rand/1"] = [
    ((@pl.col("f") % @pl.col("f").last()).floor_div(
      @pl.col("f3").mean() % @pl.col("f3"),
    ) -
    (@pl.col("f3") * @pl.col("f3")).floor_div(
      @pl.col("f").max() / @pl.lit_float(3.0),
    )).over([@pl.col("k")]),
  ]
  m["dv/rand/2"] = [
    (@pl.col("f3") / (@pl.col("f") * @pl.lit_int(2L))).over([@pl.col("k")]),
  ]
  m["dv/rand/3"] = [
    (@pl.col("f").last() -
    @pl.col("f3") -
    @pl.col("f") / @pl.len() * (@pl.col("f") / @pl.lit_int(7L))).over([
      @pl.col("k"),
    ]),
  ]
  m["dv/rand/4"] = [
    ((@pl.col("f3").mean() + @pl.len()) /
    @pl.col("f").mean().floor_div(@pl.col("f3"))).over([@pl.col("k")]),
  ]
  m["dv/rand/5"] = [
    (@pl.col("f3").floor_div(@pl.lit_int(3L) / @pl.col("f").min()) -
    @pl.col("f").max().floor_div(@pl.col("f3")) *
    (@pl.col("f").mean() % @pl.col("f3").sum())).over([@pl.col("k")]),
  ]
  m["dv/rand/6"] = [
    (@pl.col("f").mean() % @pl.col("f").mean()).over([@pl.col("k")]),
  ]
  m["dv/rand/7"] = [
    (@pl.lit_int(7L) *
    (
      @pl.col("f").last() %
      @pl.col("f3").first() *
      (@pl.col("f").sum() * @pl.col("f3").min())
    )).over([@pl.col("k")]),
  ]
  m["dv/rand/8"] = [
    (@pl.col("f3").first() / @pl.col("f3")).over([@pl.col("k")]),
  ]
  m["dv/rand/9"] = [
    (@pl.lit_float(3.0) %
    @pl.col("f").mean() /
    (@pl.col("f3") % @pl.lit_int(7L))).over([@pl.col("k")]),
  ]
  m["dv/rand/10"] = [
    @pl.len()
    .floor_div(@pl.col("f3").sum() % @pl.col("f3"))
    .floor_div(
      @pl.col("f3").min() %
      @pl.col("f") %
      (@pl.col("f3").last() / @pl.col("f").max()),
    )
    .over([@pl.col("k")]),
  ]
  m["dv/rand/11"] = [
    (@pl.col("f3") * @pl.col("f").first() / @pl.col("f3"))
    .floor_div(
      @pl.col("f").first() + @pl.lit_float(0.5).floor_div(@pl.col("f3")),
    )
    .over([@pl.col("k")]),
  ]
  m["dv/rand-mixed/0"] = [
    @pl.lit_float(0.5).floor_div(@pl.col("f")).over([@pl.col("k")]),
  ]
  m["dv/rand-mixed/1"] = [
    (@pl.col("f3").last() * (@pl.col("f3").sum() % @pl.col("n"))).over([
      @pl.col("k"),
    ]),
  ]
  m["dv/rand-mixed/2"] = [
    (@pl.col("n").mean() / @pl.col("n") / (@pl.col("n") + @pl.col("n"))).over([
      @pl.col("k"),
    ]),
  ]
  m["dv/rand-mixed/3"] = [(@pl.col("f") / @pl.col("n")).over([@pl.col("k")])]
}

///|
/// Every case id with the expressions it builds.
fn golden_window_cases() -> Map[String, Array[@pl.Expr]] {
  let m : Map[String, Array[@pl.Expr]] = Map([])
  golden_window_cases_0(m)
  golden_window_cases_1(m)
  golden_window_cases_2(m)
  golden_window_cases_3(m)
  golden_window_cases_4(m)
  golden_window_cases_5(m)
  golden_window_cases_6(m)
  golden_window_cases_7(m)
  golden_window_cases_8(m)
  golden_window_cases_9(m)
  m
}
