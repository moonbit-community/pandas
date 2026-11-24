// 由 docs/golden/scripts/expr_seq.py 生成，勿手改

///|
fn golden_expr_seq_cases_0(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["shift/q/i32/1"] = [@pl.col("i32").shift(n=1)]
  m["shift/q/i32/-2"] = [@pl.col("i32").shift(n=-2)]
  m["shift/q/i32/0"] = [@pl.col("i32").shift(n=0)]
  m["shift/q/i32/20"] = [@pl.col("i32").shift(n=20)]
  m["diff/q/i32/1"] = [@pl.col("i32").diff(n=1)]
  m["diff/q/i32/2"] = [@pl.col("i32").diff(n=2)]
  m["diff/q/i32/-1"] = [@pl.col("i32").diff(n=-1)]
  m["shift/q/i64/1"] = [@pl.col("i64").shift(n=1)]
  m["shift/q/i64/-2"] = [@pl.col("i64").shift(n=-2)]
  m["shift/q/i64/0"] = [@pl.col("i64").shift(n=0)]
  m["shift/q/i64/20"] = [@pl.col("i64").shift(n=20)]
  m["diff/q/i64/1"] = [@pl.col("i64").diff(n=1)]
  m["diff/q/i64/2"] = [@pl.col("i64").diff(n=2)]
  m["diff/q/i64/-1"] = [@pl.col("i64").diff(n=-1)]
  m["shift/q/f32/1"] = [@pl.col("f32").shift(n=1)]
  m["shift/q/f32/-2"] = [@pl.col("f32").shift(n=-2)]
  m["shift/q/f32/0"] = [@pl.col("f32").shift(n=0)]
  m["shift/q/f32/20"] = [@pl.col("f32").shift(n=20)]
  m["diff/q/f32/1"] = [@pl.col("f32").diff(n=1)]
  m["diff/q/f32/2"] = [@pl.col("f32").diff(n=2)]
  m["diff/q/f32/-1"] = [@pl.col("f32").diff(n=-1)]
  m["shift/q/f64/1"] = [@pl.col("f64").shift(n=1)]
  m["shift/q/f64/-2"] = [@pl.col("f64").shift(n=-2)]
  m["shift/q/f64/0"] = [@pl.col("f64").shift(n=0)]
  m["shift/q/f64/20"] = [@pl.col("f64").shift(n=20)]
  m["diff/q/f64/1"] = [@pl.col("f64").diff(n=1)]
  m["diff/q/f64/2"] = [@pl.col("f64").diff(n=2)]
  m["diff/q/f64/-1"] = [@pl.col("f64").diff(n=-1)]
  m["shift/q/s/1"] = [@pl.col("s").shift(n=1)]
  m["shift/q/s/-2"] = [@pl.col("s").shift(n=-2)]
  m["shift/q/s/0"] = [@pl.col("s").shift(n=0)]
  m["shift/q/s/20"] = [@pl.col("s").shift(n=20)]
  m["diff/q/s/1"] = [@pl.col("s").diff(n=1)]
  m["diff/q/s/2"] = [@pl.col("s").diff(n=2)]
  m["diff/q/s/-1"] = [@pl.col("s").diff(n=-1)]
  m["shift/q/b/1"] = [@pl.col("b").shift(n=1)]
  m["shift/q/b/-2"] = [@pl.col("b").shift(n=-2)]
  m["shift/q/b/0"] = [@pl.col("b").shift(n=0)]
  m["shift/q/b/20"] = [@pl.col("b").shift(n=20)]
  m["diff/q/b/1"] = [@pl.col("b").diff(n=1)]
  m["diff/q/b/2"] = [@pl.col("b").diff(n=2)]
  m["diff/q/b/-1"] = [@pl.col("b").diff(n=-1)]
  m["shift/q/d/1"] = [@pl.col("d").shift(n=1)]
  m["shift/q/d/-2"] = [@pl.col("d").shift(n=-2)]
  m["shift/q/d/0"] = [@pl.col("d").shift(n=0)]
  m["shift/q/d/20"] = [@pl.col("d").shift(n=20)]
  m["diff/q/d/1"] = [@pl.col("d").diff(n=1)]
  m["diff/q/d/2"] = [@pl.col("d").diff(n=2)]
  m["diff/q/d/-1"] = [@pl.col("d").diff(n=-1)]
  m["shift/q/dt/1"] = [@pl.col("dt").shift(n=1)]
  m["shift/q/dt/-2"] = [@pl.col("dt").shift(n=-2)]
  m["shift/q/dt/0"] = [@pl.col("dt").shift(n=0)]
  m["shift/q/dt/20"] = [@pl.col("dt").shift(n=20)]
  m["diff/q/dt/1"] = [@pl.col("dt").diff(n=1)]
  m["diff/q/dt/2"] = [@pl.col("dt").diff(n=2)]
  m["diff/q/dt/-1"] = [@pl.col("dt").diff(n=-1)]
  m["shift/q/n/1"] = [@pl.col("n").shift(n=1)]
  m["shift/q/n/-2"] = [@pl.col("n").shift(n=-2)]
  m["shift/q/n/0"] = [@pl.col("n").shift(n=0)]
  m["shift/q/n/20"] = [@pl.col("n").shift(n=20)]
}

///|
fn golden_expr_seq_cases_1(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["diff/q/n/1"] = [@pl.col("n").diff(n=1)]
  m["diff/q/n/2"] = [@pl.col("n").diff(n=2)]
  m["diff/q/n/-1"] = [@pl.col("n").diff(n=-1)]
  m["shift/t/i32/1"] = [@pl.col("i32").shift(n=1)]
  m["shift/t/i32/-2"] = [@pl.col("i32").shift(n=-2)]
  m["shift/t/i32/0"] = [@pl.col("i32").shift(n=0)]
  m["shift/t/i32/20"] = [@pl.col("i32").shift(n=20)]
  m["diff/t/i32/1"] = [@pl.col("i32").diff(n=1)]
  m["diff/t/i32/2"] = [@pl.col("i32").diff(n=2)]
  m["shift/t/f64/1"] = [@pl.col("f64").shift(n=1)]
  m["shift/t/f64/-2"] = [@pl.col("f64").shift(n=-2)]
  m["shift/t/f64/0"] = [@pl.col("f64").shift(n=0)]
  m["shift/t/f64/20"] = [@pl.col("f64").shift(n=20)]
  m["diff/t/f64/1"] = [@pl.col("f64").diff(n=1)]
  m["diff/t/f64/2"] = [@pl.col("f64").diff(n=2)]
  m["shift/t/s/1"] = [@pl.col("s").shift(n=1)]
  m["shift/t/s/-2"] = [@pl.col("s").shift(n=-2)]
  m["shift/t/s/0"] = [@pl.col("s").shift(n=0)]
  m["shift/t/s/20"] = [@pl.col("s").shift(n=20)]
  m["diff/t/s/1"] = [@pl.col("s").diff(n=1)]
  m["diff/t/s/2"] = [@pl.col("s").diff(n=2)]
  m["shift/t/b/1"] = [@pl.col("b").shift(n=1)]
  m["shift/t/b/-2"] = [@pl.col("b").shift(n=-2)]
  m["shift/t/b/0"] = [@pl.col("b").shift(n=0)]
  m["shift/t/b/20"] = [@pl.col("b").shift(n=20)]
  m["diff/t/b/1"] = [@pl.col("b").diff(n=1)]
  m["diff/t/b/2"] = [@pl.col("b").diff(n=2)]
  m["shift-fill/q/i32/date"] = [
    @pl.col("i32").shift(n=1, fill_value=@pl.AnyValue::Date(100)),
  ]
  m["shift-fill/q/i32/i32"] = [
    @pl.col("i32").shift(n=1, fill_value=@pl.AnyValue::Int32(99)),
  ]
  m["shift-fill/q/i32/i64"] = [
    @pl.col("i32").shift(n=1, fill_value=@pl.AnyValue::Int64(-5L)),
  ]
  m["shift-fill/q/i32/str"] = [
    @pl.col("i32").shift(n=1, fill_value=@pl.AnyValue::String("x")),
  ]
  m["shift-fill/q/i32/back"] = [
    @pl.col("i32").shift(n=-3, fill_value=@pl.AnyValue::Int32(99)),
  ]
  m["shift-fill/q/i64/date"] = [
    @pl.col("i64").shift(n=1, fill_value=@pl.AnyValue::Date(100)),
  ]
  m["shift-fill/q/i64/i64"] = [
    @pl.col("i64").shift(n=1, fill_value=@pl.AnyValue::Int64(-5L)),
  ]
  m["shift-fill/q/i64/str"] = [
    @pl.col("i64").shift(n=1, fill_value=@pl.AnyValue::String("x")),
  ]
  m["shift-fill/q/i64/back"] = [
    @pl.col("i64").shift(n=-3, fill_value=@pl.AnyValue::Int64(-5L)),
  ]
  m["shift-fill/q/f32/date"] = [
    @pl.col("f32").shift(n=1, fill_value=@pl.AnyValue::Date(100)),
  ]
  m["shift-fill/q/f32/f32"] = [
    @pl.col("f32").shift(n=1, fill_value=@pl.AnyValue::Float32(1.5)),
  ]
  m["shift-fill/q/f32/i64"] = [
    @pl.col("f32").shift(n=1, fill_value=@pl.AnyValue::Int64(-5L)),
  ]
  m["shift-fill/q/f32/str"] = [
    @pl.col("f32").shift(n=1, fill_value=@pl.AnyValue::String("x")),
  ]
  m["shift-fill/q/f32/back"] = [
    @pl.col("f32").shift(n=-3, fill_value=@pl.AnyValue::Float32(1.5)),
  ]
  m["shift-fill/q/f64/date"] = [
    @pl.col("f64").shift(n=1, fill_value=@pl.AnyValue::Date(100)),
  ]
  m["shift-fill/q/f64/f64"] = [
    @pl.col("f64").shift(n=1, fill_value=@pl.AnyValue::Float64(2.5)),
  ]
  m["shift-fill/q/f64/i64"] = [
    @pl.col("f64").shift(n=1, fill_value=@pl.AnyValue::Int64(-5L)),
  ]
  m["shift-fill/q/f64/str"] = [
    @pl.col("f64").shift(n=1, fill_value=@pl.AnyValue::String("x")),
  ]
  m["shift-fill/q/f64/back"] = [
    @pl.col("f64").shift(n=-3, fill_value=@pl.AnyValue::Float64(2.5)),
  ]
  m["shift-fill/q/s/date"] = [
    @pl.col("s").shift(n=1, fill_value=@pl.AnyValue::Date(100)),
  ]
  m["shift-fill/q/s/i64"] = [
    @pl.col("s").shift(n=1, fill_value=@pl.AnyValue::Int64(-5L)),
  ]
  m["shift-fill/q/s/str"] = [
    @pl.col("s").shift(n=1, fill_value=@pl.AnyValue::String("x")),
  ]
  m["shift-fill/q/s/back"] = [
    @pl.col("s").shift(n=-3, fill_value=@pl.AnyValue::String("x")),
  ]
  m["shift-fill/q/b/bool"] = [
    @pl.col("b").shift(n=1, fill_value=@pl.AnyValue::Boolean(true)),
  ]
  m["shift-fill/q/b/date"] = [
    @pl.col("b").shift(n=1, fill_value=@pl.AnyValue::Date(100)),
  ]
  m["shift-fill/q/b/i64"] = [
    @pl.col("b").shift(n=1, fill_value=@pl.AnyValue::Int64(-5L)),
  ]
  m["shift-fill/q/b/str"] = [
    @pl.col("b").shift(n=1, fill_value=@pl.AnyValue::String("x")),
  ]
  m["shift-fill/q/b/back"] = [
    @pl.col("b").shift(n=-3, fill_value=@pl.AnyValue::Boolean(true)),
  ]
  m["shift-fill/q/d/date"] = [
    @pl.col("d").shift(n=1, fill_value=@pl.AnyValue::Date(100)),
  ]
  m["shift-fill/q/d/i64"] = [
    @pl.col("d").shift(n=1, fill_value=@pl.AnyValue::Int64(-5L)),
  ]
  m["shift-fill/q/d/str"] = [
    @pl.col("d").shift(n=1, fill_value=@pl.AnyValue::String("x")),
  ]
  m["shift-fill/q/d/back"] = [
    @pl.col("d").shift(n=-3, fill_value=@pl.AnyValue::Date(100)),
  ]
  m["shift-fill/q/dt/date"] = [
    @pl.col("dt").shift(n=1, fill_value=@pl.AnyValue::Date(100)),
  ]
}

///|
fn golden_expr_seq_cases_2(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["shift-fill/q/dt/datetime[μs]"] = [
    @pl.col("dt").shift(n=1, fill_value=@pl.AnyValue::Datetime(1000000L)),
  ]
  m["shift-fill/q/dt/i64"] = [
    @pl.col("dt").shift(n=1, fill_value=@pl.AnyValue::Int64(-5L)),
  ]
  m["shift-fill/q/dt/str"] = [
    @pl.col("dt").shift(n=1, fill_value=@pl.AnyValue::String("x")),
  ]
  m["shift-fill/q/dt/back"] = [
    @pl.col("dt").shift(n=-3, fill_value=@pl.AnyValue::Datetime(1000000L)),
  ]
  m["shift-fill/q/n/date"] = [
    @pl.col("n").shift(n=1, fill_value=@pl.AnyValue::Date(100)),
  ]
  m["shift-fill/q/n/i32"] = [
    @pl.col("n").shift(n=1, fill_value=@pl.AnyValue::Int32(99)),
  ]
  m["shift-fill/q/n/i64"] = [
    @pl.col("n").shift(n=1, fill_value=@pl.AnyValue::Int64(-5L)),
  ]
  m["shift-fill/q/n/str"] = [
    @pl.col("n").shift(n=1, fill_value=@pl.AnyValue::String("x")),
  ]
  m["shift-fill/q/n/back"] = [
    @pl.col("n").shift(n=-3, fill_value=@pl.AnyValue::Int32(7)),
  ]
  m["shift/e0/i32"] = [@pl.col("i32").shift(n=1)]
  m["diff/e0/i32"] = [@pl.col("i32").diff(n=1)]
  m["shift-fill/e0/i32"] = [
    @pl.col("i32").shift(n=1, fill_value=@pl.AnyValue::Int32(5)),
  ]
  m["shift/e0/s"] = [@pl.col("s").shift(n=1)]
  m["diff/e0/s"] = [@pl.col("s").diff(n=1)]
  m["shift-fill/e0/s"] = [
    @pl.col("s").shift(n=1, fill_value=@pl.AnyValue::Int32(5)),
  ]
  m["shift/e0/n"] = [@pl.col("n").shift(n=1)]
  m["diff/e0/n"] = [@pl.col("n").diff(n=1)]
  m["shift-fill/e0/n"] = [
    @pl.col("n").shift(n=1, fill_value=@pl.AnyValue::Int32(5)),
  ]
  m["cum_sum/q/i32/fwd"] = [@pl.col("i32").cum_sum()]
  m["cum_sum/q/i32/rev"] = [@pl.col("i32").cum_sum(reverse=true)]
  m["cum_sum/q/i64/fwd"] = [@pl.col("i64").cum_sum()]
  m["cum_sum/q/i64/rev"] = [@pl.col("i64").cum_sum(reverse=true)]
  m["cum_sum/q/f32/fwd"] = [@pl.col("f32").cum_sum()]
  m["cum_sum/q/f32/rev"] = [@pl.col("f32").cum_sum(reverse=true)]
  m["cum_sum/q/f64/fwd"] = [@pl.col("f64").cum_sum()]
  m["cum_sum/q/f64/rev"] = [@pl.col("f64").cum_sum(reverse=true)]
  m["cum_sum/q/s/fwd"] = [@pl.col("s").cum_sum()]
  m["cum_sum/q/s/rev"] = [@pl.col("s").cum_sum(reverse=true)]
  m["cum_sum/q/b/fwd"] = [@pl.col("b").cum_sum()]
  m["cum_sum/q/b/rev"] = [@pl.col("b").cum_sum(reverse=true)]
  m["cum_sum/q/d/fwd"] = [@pl.col("d").cum_sum()]
  m["cum_sum/q/d/rev"] = [@pl.col("d").cum_sum(reverse=true)]
  m["cum_sum/q/dt/fwd"] = [@pl.col("dt").cum_sum()]
  m["cum_sum/q/dt/rev"] = [@pl.col("dt").cum_sum(reverse=true)]
  m["cum_sum/q/n/fwd"] = [@pl.col("n").cum_sum()]
  m["cum_sum/q/n/rev"] = [@pl.col("n").cum_sum(reverse=true)]
  m["cum_min/q/i32/fwd"] = [@pl.col("i32").cum_min()]
  m["cum_min/q/i32/rev"] = [@pl.col("i32").cum_min(reverse=true)]
  m["cum_min/q/i64/fwd"] = [@pl.col("i64").cum_min()]
  m["cum_min/q/i64/rev"] = [@pl.col("i64").cum_min(reverse=true)]
  m["cum_min/q/f32/fwd"] = [@pl.col("f32").cum_min()]
  m["cum_min/q/f32/rev"] = [@pl.col("f32").cum_min(reverse=true)]
  m["cum_min/q/f64/fwd"] = [@pl.col("f64").cum_min()]
  m["cum_min/q/f64/rev"] = [@pl.col("f64").cum_min(reverse=true)]
  m["cum_min/q/s/fwd"] = [@pl.col("s").cum_min()]
  m["cum_min/q/s/rev"] = [@pl.col("s").cum_min(reverse=true)]
  m["cum_min/q/b/fwd"] = [@pl.col("b").cum_min()]
  m["cum_min/q/b/rev"] = [@pl.col("b").cum_min(reverse=true)]
  m["cum_min/q/d/fwd"] = [@pl.col("d").cum_min()]
  m["cum_min/q/d/rev"] = [@pl.col("d").cum_min(reverse=true)]
  m["cum_min/q/dt/fwd"] = [@pl.col("dt").cum_min()]
  m["cum_min/q/dt/rev"] = [@pl.col("dt").cum_min(reverse=true)]
  m["cum_min/q/n/fwd"] = [@pl.col("n").cum_min()]
  m["cum_min/q/n/rev"] = [@pl.col("n").cum_min(reverse=true)]
  m["cum_max/q/i32/fwd"] = [@pl.col("i32").cum_max()]
  m["cum_max/q/i32/rev"] = [@pl.col("i32").cum_max(reverse=true)]
  m["cum_max/q/i64/fwd"] = [@pl.col("i64").cum_max()]
  m["cum_max/q/i64/rev"] = [@pl.col("i64").cum_max(reverse=true)]
  m["cum_max/q/f32/fwd"] = [@pl.col("f32").cum_max()]
  m["cum_max/q/f32/rev"] = [@pl.col("f32").cum_max(reverse=true)]
}

///|
fn golden_expr_seq_cases_3(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["cum_max/q/f64/fwd"] = [@pl.col("f64").cum_max()]
  m["cum_max/q/f64/rev"] = [@pl.col("f64").cum_max(reverse=true)]
  m["cum_max/q/s/fwd"] = [@pl.col("s").cum_max()]
  m["cum_max/q/s/rev"] = [@pl.col("s").cum_max(reverse=true)]
  m["cum_max/q/b/fwd"] = [@pl.col("b").cum_max()]
  m["cum_max/q/b/rev"] = [@pl.col("b").cum_max(reverse=true)]
  m["cum_max/q/d/fwd"] = [@pl.col("d").cum_max()]
  m["cum_max/q/d/rev"] = [@pl.col("d").cum_max(reverse=true)]
  m["cum_max/q/dt/fwd"] = [@pl.col("dt").cum_max()]
  m["cum_max/q/dt/rev"] = [@pl.col("dt").cum_max(reverse=true)]
  m["cum_max/q/n/fwd"] = [@pl.col("n").cum_max()]
  m["cum_max/q/n/rev"] = [@pl.col("n").cum_max(reverse=true)]
  m["cum_prod/q/i32/fwd"] = [@pl.col("i32").cum_prod()]
  m["cum_prod/q/i32/rev"] = [@pl.col("i32").cum_prod(reverse=true)]
  m["cum_prod/q/i64/fwd"] = [@pl.col("i64").cum_prod()]
  m["cum_prod/q/i64/rev"] = [@pl.col("i64").cum_prod(reverse=true)]
  m["cum_prod/q/f32/fwd"] = [@pl.col("f32").cum_prod()]
  m["cum_prod/q/f32/rev"] = [@pl.col("f32").cum_prod(reverse=true)]
  m["cum_prod/q/f64/fwd"] = [@pl.col("f64").cum_prod()]
  m["cum_prod/q/f64/rev"] = [@pl.col("f64").cum_prod(reverse=true)]
  m["cum_prod/q/s/fwd"] = [@pl.col("s").cum_prod()]
  m["cum_prod/q/s/rev"] = [@pl.col("s").cum_prod(reverse=true)]
  m["cum_prod/q/b/fwd"] = [@pl.col("b").cum_prod()]
  m["cum_prod/q/b/rev"] = [@pl.col("b").cum_prod(reverse=true)]
  m["cum_prod/q/d/fwd"] = [@pl.col("d").cum_prod()]
  m["cum_prod/q/d/rev"] = [@pl.col("d").cum_prod(reverse=true)]
  m["cum_prod/q/dt/fwd"] = [@pl.col("dt").cum_prod()]
  m["cum_prod/q/dt/rev"] = [@pl.col("dt").cum_prod(reverse=true)]
  m["cum_prod/q/n/fwd"] = [@pl.col("n").cum_prod()]
  m["cum_prod/q/n/rev"] = [@pl.col("n").cum_prod(reverse=true)]
  m["cum_count/q/i32/fwd"] = [@pl.col("i32").cum_count()]
  m["cum_count/q/i32/rev"] = [@pl.col("i32").cum_count(reverse=true)]
  m["cum_count/q/i64/fwd"] = [@pl.col("i64").cum_count()]
  m["cum_count/q/i64/rev"] = [@pl.col("i64").cum_count(reverse=true)]
  m["cum_count/q/f32/fwd"] = [@pl.col("f32").cum_count()]
  m["cum_count/q/f32/rev"] = [@pl.col("f32").cum_count(reverse=true)]
  m["cum_count/q/f64/fwd"] = [@pl.col("f64").cum_count()]
  m["cum_count/q/f64/rev"] = [@pl.col("f64").cum_count(reverse=true)]
  m["cum_count/q/s/fwd"] = [@pl.col("s").cum_count()]
  m["cum_count/q/s/rev"] = [@pl.col("s").cum_count(reverse=true)]
  m["cum_count/q/b/fwd"] = [@pl.col("b").cum_count()]
  m["cum_count/q/b/rev"] = [@pl.col("b").cum_count(reverse=true)]
  m["cum_count/q/d/fwd"] = [@pl.col("d").cum_count()]
  m["cum_count/q/d/rev"] = [@pl.col("d").cum_count(reverse=true)]
  m["cum_count/q/dt/fwd"] = [@pl.col("dt").cum_count()]
  m["cum_count/q/dt/rev"] = [@pl.col("dt").cum_count(reverse=true)]
  m["cum_count/q/n/fwd"] = [@pl.col("n").cum_count()]
  m["cum_count/q/n/rev"] = [@pl.col("n").cum_count(reverse=true)]
  m["rank/q/average/i32/asc"] = [
    @pl.col("i32").rank(method_=@pl.RankMethod::Average),
  ]
  m["rank/q/average/i32/desc"] = [
    @pl.col("i32").rank(method_=@pl.RankMethod::Average, descending=true),
  ]
  m["rank/q/average/i64/asc"] = [
    @pl.col("i64").rank(method_=@pl.RankMethod::Average),
  ]
  m["rank/q/average/i64/desc"] = [
    @pl.col("i64").rank(method_=@pl.RankMethod::Average, descending=true),
  ]
  m["rank/q/average/f32/asc"] = [
    @pl.col("f32").rank(method_=@pl.RankMethod::Average),
  ]
  m["rank/q/average/f32/desc"] = [
    @pl.col("f32").rank(method_=@pl.RankMethod::Average, descending=true),
  ]
  m["rank/q/average/f64/asc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Average),
  ]
  m["rank/q/average/f64/desc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Average, descending=true),
  ]
  m["rank/q/average/s/asc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Average),
  ]
  m["rank/q/average/s/desc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Average, descending=true),
  ]
  m["rank/q/average/b/asc"] = [
    @pl.col("b").rank(method_=@pl.RankMethod::Average),
  ]
  m["rank/q/average/b/desc"] = [
    @pl.col("b").rank(method_=@pl.RankMethod::Average, descending=true),
  ]
}

///|
fn golden_expr_seq_cases_4(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["rank/q/average/d/asc"] = [
    @pl.col("d").rank(method_=@pl.RankMethod::Average),
  ]
  m["rank/q/average/d/desc"] = [
    @pl.col("d").rank(method_=@pl.RankMethod::Average, descending=true),
  ]
  m["rank/q/average/dt/asc"] = [
    @pl.col("dt").rank(method_=@pl.RankMethod::Average),
  ]
  m["rank/q/average/dt/desc"] = [
    @pl.col("dt").rank(method_=@pl.RankMethod::Average, descending=true),
  ]
  m["rank/q/average/n/asc"] = [
    @pl.col("n").rank(method_=@pl.RankMethod::Average),
  ]
  m["rank/q/average/n/desc"] = [
    @pl.col("n").rank(method_=@pl.RankMethod::Average, descending=true),
  ]
  m["rank/q/min/i32/asc"] = [@pl.col("i32").rank(method_=@pl.RankMethod::Min)]
  m["rank/q/min/i64/asc"] = [@pl.col("i64").rank(method_=@pl.RankMethod::Min)]
  m["rank/q/min/f32/asc"] = [@pl.col("f32").rank(method_=@pl.RankMethod::Min)]
  m["rank/q/min/f64/asc"] = [@pl.col("f64").rank(method_=@pl.RankMethod::Min)]
  m["rank/q/min/f64/desc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Min, descending=true),
  ]
  m["rank/q/min/s/asc"] = [@pl.col("s").rank(method_=@pl.RankMethod::Min)]
  m["rank/q/min/s/desc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Min, descending=true),
  ]
  m["rank/q/min/b/asc"] = [@pl.col("b").rank(method_=@pl.RankMethod::Min)]
  m["rank/q/min/d/asc"] = [@pl.col("d").rank(method_=@pl.RankMethod::Min)]
  m["rank/q/min/dt/asc"] = [@pl.col("dt").rank(method_=@pl.RankMethod::Min)]
  m["rank/q/min/n/asc"] = [@pl.col("n").rank(method_=@pl.RankMethod::Min)]
  m["rank/q/max/i32/asc"] = [@pl.col("i32").rank(method_=@pl.RankMethod::Max)]
  m["rank/q/max/i64/asc"] = [@pl.col("i64").rank(method_=@pl.RankMethod::Max)]
  m["rank/q/max/f32/asc"] = [@pl.col("f32").rank(method_=@pl.RankMethod::Max)]
  m["rank/q/max/f64/asc"] = [@pl.col("f64").rank(method_=@pl.RankMethod::Max)]
  m["rank/q/max/f64/desc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Max, descending=true),
  ]
  m["rank/q/max/s/asc"] = [@pl.col("s").rank(method_=@pl.RankMethod::Max)]
  m["rank/q/max/s/desc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Max, descending=true),
  ]
  m["rank/q/max/b/asc"] = [@pl.col("b").rank(method_=@pl.RankMethod::Max)]
  m["rank/q/max/d/asc"] = [@pl.col("d").rank(method_=@pl.RankMethod::Max)]
  m["rank/q/max/dt/asc"] = [@pl.col("dt").rank(method_=@pl.RankMethod::Max)]
  m["rank/q/max/n/asc"] = [@pl.col("n").rank(method_=@pl.RankMethod::Max)]
  m["rank/q/dense/i32/asc"] = [
    @pl.col("i32").rank(method_=@pl.RankMethod::Dense),
  ]
  m["rank/q/dense/i32/desc"] = [
    @pl.col("i32").rank(method_=@pl.RankMethod::Dense, descending=true),
  ]
  m["rank/q/dense/i64/asc"] = [
    @pl.col("i64").rank(method_=@pl.RankMethod::Dense),
  ]
  m["rank/q/dense/i64/desc"] = [
    @pl.col("i64").rank(method_=@pl.RankMethod::Dense, descending=true),
  ]
  m["rank/q/dense/f32/asc"] = [
    @pl.col("f32").rank(method_=@pl.RankMethod::Dense),
  ]
  m["rank/q/dense/f32/desc"] = [
    @pl.col("f32").rank(method_=@pl.RankMethod::Dense, descending=true),
  ]
  m["rank/q/dense/f64/asc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Dense),
  ]
  m["rank/q/dense/f64/desc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Dense, descending=true),
  ]
  m["rank/q/dense/s/asc"] = [@pl.col("s").rank(method_=@pl.RankMethod::Dense)]
  m["rank/q/dense/s/desc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Dense, descending=true),
  ]
  m["rank/q/dense/b/asc"] = [@pl.col("b").rank(method_=@pl.RankMethod::Dense)]
  m["rank/q/dense/b/desc"] = [
    @pl.col("b").rank(method_=@pl.RankMethod::Dense, descending=true),
  ]
  m["rank/q/dense/d/asc"] = [@pl.col("d").rank(method_=@pl.RankMethod::Dense)]
  m["rank/q/dense/d/desc"] = [
    @pl.col("d").rank(method_=@pl.RankMethod::Dense, descending=true),
  ]
  m["rank/q/dense/dt/asc"] = [@pl.col("dt").rank(method_=@pl.RankMethod::Dense)]
  m["rank/q/dense/dt/desc"] = [
    @pl.col("dt").rank(method_=@pl.RankMethod::Dense, descending=true),
  ]
  m["rank/q/dense/n/asc"] = [@pl.col("n").rank(method_=@pl.RankMethod::Dense)]
  m["rank/q/dense/n/desc"] = [
    @pl.col("n").rank(method_=@pl.RankMethod::Dense, descending=true),
  ]
  m["rank/q/ordinal/i32/asc"] = [
    @pl.col("i32").rank(method_=@pl.RankMethod::Ordinal),
  ]
  m["rank/q/ordinal/i32/desc"] = [
    @pl.col("i32").rank(method_=@pl.RankMethod::Ordinal, descending=true),
  ]
  m["rank/q/ordinal/i64/asc"] = [
    @pl.col("i64").rank(method_=@pl.RankMethod::Ordinal),
  ]
  m["rank/q/ordinal/i64/desc"] = [
    @pl.col("i64").rank(method_=@pl.RankMethod::Ordinal, descending=true),
  ]
  m["rank/q/ordinal/f32/asc"] = [
    @pl.col("f32").rank(method_=@pl.RankMethod::Ordinal),
  ]
  m["rank/q/ordinal/f32/desc"] = [
    @pl.col("f32").rank(method_=@pl.RankMethod::Ordinal, descending=true),
  ]
  m["rank/q/ordinal/f64/asc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Ordinal),
  ]
  m["rank/q/ordinal/f64/desc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Ordinal, descending=true),
  ]
  m["rank/q/ordinal/s/asc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Ordinal),
  ]
  m["rank/q/ordinal/s/desc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Ordinal, descending=true),
  ]
  m["rank/q/ordinal/b/asc"] = [
    @pl.col("b").rank(method_=@pl.RankMethod::Ordinal),
  ]
  m["rank/q/ordinal/b/desc"] = [
    @pl.col("b").rank(method_=@pl.RankMethod::Ordinal, descending=true),
  ]
  m["rank/q/ordinal/d/asc"] = [
    @pl.col("d").rank(method_=@pl.RankMethod::Ordinal),
  ]
  m["rank/q/ordinal/d/desc"] = [
    @pl.col("d").rank(method_=@pl.RankMethod::Ordinal, descending=true),
  ]
}

///|
fn golden_expr_seq_cases_5(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["rank/q/ordinal/dt/asc"] = [
    @pl.col("dt").rank(method_=@pl.RankMethod::Ordinal),
  ]
  m["rank/q/ordinal/dt/desc"] = [
    @pl.col("dt").rank(method_=@pl.RankMethod::Ordinal, descending=true),
  ]
  m["rank/q/ordinal/n/asc"] = [
    @pl.col("n").rank(method_=@pl.RankMethod::Ordinal),
  ]
  m["rank/q/ordinal/n/desc"] = [
    @pl.col("n").rank(method_=@pl.RankMethod::Ordinal, descending=true),
  ]
  m["reverse/q/i32"] = [@pl.col("i32").reverse()]
  m["reverse/q/i64"] = [@pl.col("i64").reverse()]
  m["reverse/q/f32"] = [@pl.col("f32").reverse()]
  m["reverse/q/f64"] = [@pl.col("f64").reverse()]
  m["reverse/q/s"] = [@pl.col("s").reverse()]
  m["reverse/q/b"] = [@pl.col("b").reverse()]
  m["reverse/q/d"] = [@pl.col("d").reverse()]
  m["reverse/q/dt"] = [@pl.col("dt").reverse()]
  m["reverse/q/n"] = [@pl.col("n").reverse()]
  m["cum_sum/t/i32/fwd"] = [@pl.col("i32").cum_sum()]
  m["cum_sum/t/i32/rev"] = [@pl.col("i32").cum_sum(reverse=true)]
  m["cum_sum/t/f64/fwd"] = [@pl.col("f64").cum_sum()]
  m["cum_sum/t/f64/rev"] = [@pl.col("f64").cum_sum(reverse=true)]
  m["cum_sum/t/s/fwd"] = [@pl.col("s").cum_sum()]
  m["cum_sum/t/s/rev"] = [@pl.col("s").cum_sum(reverse=true)]
  m["cum_min/t/i32/fwd"] = [@pl.col("i32").cum_min()]
  m["cum_min/t/i32/rev"] = [@pl.col("i32").cum_min(reverse=true)]
  m["cum_min/t/f64/fwd"] = [@pl.col("f64").cum_min()]
  m["cum_min/t/f64/rev"] = [@pl.col("f64").cum_min(reverse=true)]
  m["cum_min/t/s/fwd"] = [@pl.col("s").cum_min()]
  m["cum_min/t/s/rev"] = [@pl.col("s").cum_min(reverse=true)]
  m["cum_max/t/i32/fwd"] = [@pl.col("i32").cum_max()]
  m["cum_max/t/i32/rev"] = [@pl.col("i32").cum_max(reverse=true)]
  m["cum_max/t/f64/fwd"] = [@pl.col("f64").cum_max()]
  m["cum_max/t/f64/rev"] = [@pl.col("f64").cum_max(reverse=true)]
  m["cum_max/t/s/fwd"] = [@pl.col("s").cum_max()]
  m["cum_max/t/s/rev"] = [@pl.col("s").cum_max(reverse=true)]
  m["cum_prod/t/i32/fwd"] = [@pl.col("i32").cum_prod()]
  m["cum_prod/t/i32/rev"] = [@pl.col("i32").cum_prod(reverse=true)]
  m["cum_prod/t/f64/fwd"] = [@pl.col("f64").cum_prod()]
  m["cum_prod/t/f64/rev"] = [@pl.col("f64").cum_prod(reverse=true)]
  m["cum_prod/t/s/fwd"] = [@pl.col("s").cum_prod()]
  m["cum_prod/t/s/rev"] = [@pl.col("s").cum_prod(reverse=true)]
  m["cum_count/t/i32/fwd"] = [@pl.col("i32").cum_count()]
  m["cum_count/t/i32/rev"] = [@pl.col("i32").cum_count(reverse=true)]
  m["cum_count/t/f64/fwd"] = [@pl.col("f64").cum_count()]
  m["cum_count/t/f64/rev"] = [@pl.col("f64").cum_count(reverse=true)]
  m["cum_count/t/s/fwd"] = [@pl.col("s").cum_count()]
  m["cum_count/t/s/rev"] = [@pl.col("s").cum_count(reverse=true)]
  m["rank/t/average/f64/asc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Average),
  ]
  m["rank/t/average/f64/desc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Average, descending=true),
  ]
  m["rank/t/average/s/asc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Average),
  ]
  m["rank/t/average/s/desc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Average, descending=true),
  ]
  m["rank/t/min/f64/asc"] = [@pl.col("f64").rank(method_=@pl.RankMethod::Min)]
  m["rank/t/min/f64/desc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Min, descending=true),
  ]
  m["rank/t/min/s/asc"] = [@pl.col("s").rank(method_=@pl.RankMethod::Min)]
  m["rank/t/min/s/desc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Min, descending=true),
  ]
  m["rank/t/max/f64/asc"] = [@pl.col("f64").rank(method_=@pl.RankMethod::Max)]
  m["rank/t/max/f64/desc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Max, descending=true),
  ]
  m["rank/t/max/s/asc"] = [@pl.col("s").rank(method_=@pl.RankMethod::Max)]
  m["rank/t/max/s/desc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Max, descending=true),
  ]
  m["rank/t/dense/f64/asc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Dense),
  ]
  m["rank/t/dense/f64/desc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Dense, descending=true),
  ]
  m["rank/t/dense/s/asc"] = [@pl.col("s").rank(method_=@pl.RankMethod::Dense)]
  m["rank/t/dense/s/desc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Dense, descending=true),
  ]
  m["rank/t/ordinal/f64/asc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Ordinal),
  ]
}

///|
fn golden_expr_seq_cases_6(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["rank/t/ordinal/f64/desc"] = [
    @pl.col("f64").rank(method_=@pl.RankMethod::Ordinal, descending=true),
  ]
  m["rank/t/ordinal/s/asc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Ordinal),
  ]
  m["rank/t/ordinal/s/desc"] = [
    @pl.col("s").rank(method_=@pl.RankMethod::Ordinal, descending=true),
  ]
  m["reverse/t/i32"] = [@pl.col("i32").reverse()]
  m["reverse/t/f64"] = [@pl.col("f64").reverse()]
  m["reverse/t/s"] = [@pl.col("s").reverse()]
  m["cum_sum/e0/i32"] = [@pl.col("i32").cum_sum()]
  m["cum_min/e0/i32"] = [@pl.col("i32").cum_min()]
  m["cum_max/e0/i32"] = [@pl.col("i32").cum_max()]
  m["cum_prod/e0/i32"] = [@pl.col("i32").cum_prod()]
  m["cum_count/e0/i32"] = [@pl.col("i32").cum_count()]
  m["rank/e0/i32"] = [@pl.col("i32").rank(method_=@pl.RankMethod::Average)]
  m["rank/e0/i32/ordinal"] = [
    @pl.col("i32").rank(method_=@pl.RankMethod::Ordinal),
  ]
  m["reverse/e0/i32"] = [@pl.col("i32").reverse()]
  m["cum_sum/e0/s"] = [@pl.col("s").cum_sum()]
  m["cum_min/e0/s"] = [@pl.col("s").cum_min()]
  m["cum_max/e0/s"] = [@pl.col("s").cum_max()]
  m["cum_prod/e0/s"] = [@pl.col("s").cum_prod()]
  m["cum_count/e0/s"] = [@pl.col("s").cum_count()]
  m["rank/e0/s"] = [@pl.col("s").rank(method_=@pl.RankMethod::Average)]
  m["rank/e0/s/ordinal"] = [@pl.col("s").rank(method_=@pl.RankMethod::Ordinal)]
  m["reverse/e0/s"] = [@pl.col("s").reverse()]
  m["cum_sum/e0/n"] = [@pl.col("n").cum_sum()]
  m["cum_min/e0/n"] = [@pl.col("n").cum_min()]
  m["cum_max/e0/n"] = [@pl.col("n").cum_max()]
  m["cum_prod/e0/n"] = [@pl.col("n").cum_prod()]
  m["cum_count/e0/n"] = [@pl.col("n").cum_count()]
  m["rank/e0/n"] = [@pl.col("n").rank(method_=@pl.RankMethod::Average)]
  m["rank/e0/n/ordinal"] = [@pl.col("n").rank(method_=@pl.RankMethod::Ordinal)]
  m["reverse/e0/n"] = [@pl.col("n").reverse()]
  m["fills/q/forward/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/q/forward/i64"] = [
    @pl.col("i64").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/q/forward/f32"] = [
    @pl.col("f32").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/q/forward/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/q/forward/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/q/forward/b"] = [
    @pl.col("b").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/q/forward/d"] = [
    @pl.col("d").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/q/forward/dt"] = [
    @pl.col("dt").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/q/forward/n"] = [
    @pl.col("n").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/q/backward/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/q/backward/i64"] = [
    @pl.col("i64").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/q/backward/f32"] = [
    @pl.col("f32").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/q/backward/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/q/backward/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/q/backward/b"] = [
    @pl.col("b").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/q/backward/d"] = [
    @pl.col("d").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/q/backward/dt"] = [
    @pl.col("dt").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/q/backward/n"] = [
    @pl.col("n").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/q/min/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Min),
  ]
  m["fills/q/min/i64"] = [
    @pl.col("i64").fill_null_strategy(@pl.FillStrategy::Min),
  ]
  m["fills/q/min/f32"] = [
    @pl.col("f32").fill_null_strategy(@pl.FillStrategy::Min),
  ]
  m["fills/q/min/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Min),
  ]
  m["fills/q/min/s"] = [@pl.col("s").fill_null_strategy(@pl.FillStrategy::Min)]
  m["fills/q/min/b"] = [@pl.col("b").fill_null_strategy(@pl.FillStrategy::Min)]
  m["fills/q/min/d"] = [@pl.col("d").fill_null_strategy(@pl.FillStrategy::Min)]
  m["fills/q/min/dt"] = [
    @pl.col("dt").fill_null_strategy(@pl.FillStrategy::Min),
  ]
  m["fills/q/min/n"] = [@pl.col("n").fill_null_strategy(@pl.FillStrategy::Min)]
  m["fills/q/max/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Max),
  ]
  m["fills/q/max/i64"] = [
    @pl.col("i64").fill_null_strategy(@pl.FillStrategy::Max),
  ]
  m["fills/q/max/f32"] = [
    @pl.col("f32").fill_null_strategy(@pl.FillStrategy::Max),
  ]
}

///|
fn golden_expr_seq_cases_7(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["fills/q/max/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Max),
  ]
  m["fills/q/max/s"] = [@pl.col("s").fill_null_strategy(@pl.FillStrategy::Max)]
  m["fills/q/max/b"] = [@pl.col("b").fill_null_strategy(@pl.FillStrategy::Max)]
  m["fills/q/max/d"] = [@pl.col("d").fill_null_strategy(@pl.FillStrategy::Max)]
  m["fills/q/max/dt"] = [
    @pl.col("dt").fill_null_strategy(@pl.FillStrategy::Max),
  ]
  m["fills/q/max/n"] = [@pl.col("n").fill_null_strategy(@pl.FillStrategy::Max)]
  m["fills/q/mean/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/q/mean/i64"] = [
    @pl.col("i64").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/q/mean/f32"] = [
    @pl.col("f32").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/q/mean/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/q/mean/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/q/mean/b"] = [
    @pl.col("b").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/q/mean/d"] = [
    @pl.col("d").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/q/mean/dt"] = [
    @pl.col("dt").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/q/mean/n"] = [
    @pl.col("n").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/q/zero/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/q/zero/i64"] = [
    @pl.col("i64").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/q/zero/f32"] = [
    @pl.col("f32").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/q/zero/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/q/zero/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/q/zero/b"] = [
    @pl.col("b").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/q/zero/d"] = [
    @pl.col("d").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/q/zero/dt"] = [
    @pl.col("dt").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/q/zero/n"] = [
    @pl.col("n").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/q/one/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::One),
  ]
  m["fills/q/one/i64"] = [
    @pl.col("i64").fill_null_strategy(@pl.FillStrategy::One),
  ]
  m["fills/q/one/f32"] = [
    @pl.col("f32").fill_null_strategy(@pl.FillStrategy::One),
  ]
  m["fills/q/one/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::One),
  ]
  m["fills/q/one/s"] = [@pl.col("s").fill_null_strategy(@pl.FillStrategy::One)]
  m["fills/q/one/b"] = [@pl.col("b").fill_null_strategy(@pl.FillStrategy::One)]
  m["fills/q/one/d"] = [@pl.col("d").fill_null_strategy(@pl.FillStrategy::One)]
  m["fills/q/one/dt"] = [
    @pl.col("dt").fill_null_strategy(@pl.FillStrategy::One),
  ]
  m["fills/q/one/n"] = [@pl.col("n").fill_null_strategy(@pl.FillStrategy::One)]
  m["fills/t/forward/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/t/forward/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/t/backward/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/t/backward/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/t/min/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Min),
  ]
  m["fills/t/min/s"] = [@pl.col("s").fill_null_strategy(@pl.FillStrategy::Min)]
  m["fills/t/max/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Max),
  ]
  m["fills/t/max/s"] = [@pl.col("s").fill_null_strategy(@pl.FillStrategy::Max)]
  m["fills/t/mean/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/t/mean/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/t/zero/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/t/zero/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/t/one/f64"] = [
    @pl.col("f64").fill_null_strategy(@pl.FillStrategy::One),
  ]
  m["fills/t/one/s"] = [@pl.col("s").fill_null_strategy(@pl.FillStrategy::One)]
  m["fills/q/forward-limit0/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Forward, limit=0),
  ]
  m["fills/q/forward-limit1/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Forward, limit=1),
  ]
  m["fills/q/forward-limit2/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Forward, limit=2),
  ]
  m["fills/q/forward-limit0/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Forward, limit=0),
  ]
  m["fills/q/forward-limit1/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Forward, limit=1),
  ]
  m["fills/q/forward-limit2/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Forward, limit=2),
  ]
  m["fills/q/forward-limit0/b"] = [
    @pl.col("b").fill_null_strategy(@pl.FillStrategy::Forward, limit=0),
  ]
  m["fills/q/forward-limit1/b"] = [
    @pl.col("b").fill_null_strategy(@pl.FillStrategy::Forward, limit=1),
  ]
  m["fills/q/forward-limit2/b"] = [
    @pl.col("b").fill_null_strategy(@pl.FillStrategy::Forward, limit=2),
  ]
  m["fills/q/forward-limit0/d"] = [
    @pl.col("d").fill_null_strategy(@pl.FillStrategy::Forward, limit=0),
  ]
  m["fills/q/forward-limit1/d"] = [
    @pl.col("d").fill_null_strategy(@pl.FillStrategy::Forward, limit=1),
  ]
  m["fills/q/forward-limit2/d"] = [
    @pl.col("d").fill_null_strategy(@pl.FillStrategy::Forward, limit=2),
  ]
  m["fills/q/backward-limit0/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Backward, limit=0),
  ]
}

///|
fn golden_expr_seq_cases_8(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["fills/q/backward-limit1/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Backward, limit=1),
  ]
  m["fills/q/backward-limit2/i32"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Backward, limit=2),
  ]
  m["fills/q/backward-limit0/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Backward, limit=0),
  ]
  m["fills/q/backward-limit1/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Backward, limit=1),
  ]
  m["fills/q/backward-limit2/s"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Backward, limit=2),
  ]
  m["fills/q/backward-limit0/b"] = [
    @pl.col("b").fill_null_strategy(@pl.FillStrategy::Backward, limit=0),
  ]
  m["fills/q/backward-limit1/b"] = [
    @pl.col("b").fill_null_strategy(@pl.FillStrategy::Backward, limit=1),
  ]
  m["fills/q/backward-limit2/b"] = [
    @pl.col("b").fill_null_strategy(@pl.FillStrategy::Backward, limit=2),
  ]
  m["fills/q/backward-limit0/d"] = [
    @pl.col("d").fill_null_strategy(@pl.FillStrategy::Backward, limit=0),
  ]
  m["fills/q/backward-limit1/d"] = [
    @pl.col("d").fill_null_strategy(@pl.FillStrategy::Backward, limit=1),
  ]
  m["fills/q/backward-limit2/d"] = [
    @pl.col("d").fill_null_strategy(@pl.FillStrategy::Backward, limit=2),
  ]
  m["fills/limit-bad/min"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Min, limit=1),
  ]
  m["fills/limit-bad0/min"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Min, limit=0),
  ]
  m["fills/limit-bad/mean"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Mean, limit=1),
  ]
  m["fills/limit-bad0/mean"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Mean, limit=0),
  ]
  m["fills/limit-bad/zero"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Zero, limit=1),
  ]
  m["fills/limit-bad0/zero"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Zero, limit=0),
  ]
  m["fills/limit-negative"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Forward, limit=-1),
  ]
  m["fills/limit-negative/bad-strategy"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Min, limit=-1),
  ]
  m["fills/e0/forward"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/e0/forward/str"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["fills/e0/backward"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/e0/backward/str"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Backward),
  ]
  m["fills/e0/min"] = [@pl.col("i32").fill_null_strategy(@pl.FillStrategy::Min)]
  m["fills/e0/min/str"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Min),
  ]
  m["fills/e0/max"] = [@pl.col("i32").fill_null_strategy(@pl.FillStrategy::Max)]
  m["fills/e0/max/str"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Max),
  ]
  m["fills/e0/mean"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/e0/mean/str"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["fills/e0/zero"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/e0/zero/str"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::Zero),
  ]
  m["fills/e0/one"] = [@pl.col("i32").fill_null_strategy(@pl.FillStrategy::One)]
  m["fills/e0/one/str"] = [
    @pl.col("s").fill_null_strategy(@pl.FillStrategy::One),
  ]
  m["fills/limit-bad/z0-cols"] = [
    @pl.cols([]).fill_null_strategy(@pl.FillStrategy::Min, limit=1),
  ]
  m["fills/limit-bad/q-cols-empty"] = [
    @pl.cols([]).fill_null_strategy(@pl.FillStrategy::Min, limit=1),
  ]
  m["fills/limit-neg/q-cols-empty"] = [
    @pl.cols([]).fill_null_strategy(@pl.FillStrategy::Forward, limit=-1),
  ]
  m["mix/cum_sum-max"] = [@pl.col("i32").cum_sum().max()]
  m["mix/cum_sum-max/e0"] = [@pl.col("i32").cum_sum().max()]
  m["mix/cum_sum-sum"] = [@pl.col("f64").cum_sum().sum()]
  m["mix/cum_sum-last"] = [@pl.col("i64").cum_sum().last().alias("l")]
  m["mix/cum_max-first"] = [@pl.col("f32").cum_max().first()]
  m["mix/diff-sum"] = [@pl.col("i32").diff(n=1).sum()]
  m["mix/diff-mean"] = [@pl.col("f64").diff(n=2).mean()]
  m["mix/rank-max"] = [@pl.col("s").rank(method_=@pl.RankMethod::Average).max()]
  m["mix/rank-sum"] = [@pl.col("i32").rank(method_=@pl.RankMethod::Dense).sum()]
  m["mix/shift-count"] = [@pl.col("i32").shift(n=3).count()]
  m["mix/shift-null_count-like"] = [@pl.col("i32").shift(n=2).is_null().sum()]
  m["mix/reverse-first"] = [@pl.col("s").reverse().first()]
  m["mix/cum_sum-minus-col"] = [@pl.col("i64").cum_sum() - @pl.col("i64")]
  m["mix/col-minus-shift"] = [
    (@pl.col("f64") - @pl.col("f64").shift(n=1)).alias("d"),
  ]
  m["mix/cum_sum-plus-lit"] = [@pl.col("i32").cum_sum() + @pl.lit_int(1L)]
  m["mix/cum_sum-gt"] = [@pl.col("i32").cum_sum().gt(@pl.lit_int(10L))]
  m["mix/lit-times-cum"] = [@pl.lit_int(2L) * @pl.col("i32").cum_max()]
  m["mix/abs-diff"] = [@pl.col("i32").diff(n=1).abs()]
  m["mix/diff-is_null"] = [@pl.col("i64").diff(n=1).is_null()]
  m["mix/shift-fill_null"] = [
    @pl.col("i32").shift(n=1).fill_null(@pl.lit_int(0L)),
  ]
  m["mix/shift-fill_null-col"] = [
    @pl.col("i64").shift(n=1).fill_null(@pl.col("i64")),
  ]
  m["mix/shift-fill-lit"] = [
    (@pl.col("i32") + @pl.lit_int(1L)).shift(
      n=2,
      fill_value=@pl.AnyValue::Int32(0),
    ),
  ]
  m["mix/shift-twice"] = [@pl.col("i32").shift(n=1).shift(n=2)]
  m["mix/cum-of-cum"] = [@pl.col("i32").cum_sum().cum_sum()]
}

///|
fn golden_expr_seq_cases_9(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["mix/rank-of-neg"] = [
    (-@pl.col("f64")).rank(method_=@pl.RankMethod::Average),
  ]
  m["mix/reverse-reverse"] = [@pl.col("s").reverse().reverse()]
  m["mix/fills-of-shift"] = [
    @pl.col("i32").shift(n=1).fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["mix/shift-of-fills"] = [
    @pl.col("i32").fill_null_strategy(@pl.FillStrategy::Forward).shift(n=1),
  ]
  m["mix/cast-cum"] = [@pl.col("b").cast(@pl.DataType::Int32).cum_sum()]
  m["mix/when-cum"] = [
    @pl.when(@pl.col("i32").cum_sum().gt(@pl.lit_int(5L)))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(0L)),
  ]
  m["mix/is_in-shift"] = [@pl.col("i32").shift(n=1).is_in(vs["i32"])]
  m["mix/alias"] = [@pl.col("i32").cum_sum().alias("z")]
  m["mix/alias-inner"] = [@pl.col("i32").alias("z").cum_sum()]
  m["mix/alias-inner-shift"] = [@pl.col("i32").alias("z").shift(n=1)]
  m["mix/names-several"] = [
    @pl.col("i32").shift(n=1),
    @pl.col("i64").diff(n=1).alias("d64"),
    @pl.col("f64").rank(method_=@pl.RankMethod::Average).alias("r"),
    @pl.col("s").cum_count().alias("c"),
    @pl.col("d").reverse().alias("rev"),
  ]
  m["mix/dup-name"] = [@pl.col("i32"), @pl.col("i32").shift(n=1)]
  m["mix/dup-name-shift"] = [
    @pl.col("i32").shift(n=1),
    @pl.col("i32").cum_sum(),
  ]
  m["mix/missing"] = [@pl.col("zz").shift(n=1)]
  m["mix/missing-after"] = [@pl.col("s").cum_sum(), @pl.col("zz").cum_sum()]
  m["mix/type-error-first"] = [@pl.col("s").cum_sum(), @pl.col("s").diff(n=1)]
  m["mix/error-then-missing"] = [
    @pl.col("s").cum_sum(),
    @pl.col("zz").shift(n=1),
  ]
  m["mix/wc"] = [
    @pl.col("i32").cum_sum().alias("cs"),
    @pl.col("i32").shift(n=1).alias("sh"),
  ]
  m["mix/wc-in-place"] = [@pl.col("i32").cum_sum().alias("i32")]
  m["mix/wc-dup"] = [@pl.col("i32").cum_sum(), @pl.col("i32").shift(n=1)]
  m["mix/wc-e0"] = [@pl.col("i32").cum_sum().alias("cs")]
  m["mix/wc-agg-seq"] = [@pl.col("i32").cum_sum().sum().alias("tot")]
  m["sel/cols-cum_sum"] = [@pl.cols(["i32", "f64"]).cum_sum()]
  m["sel/all-shift"] = [@pl.all().shift(n=1)]
  m["sel/all-cum_max"] = [@pl.all().cum_max(reverse=true)]
  m["sel/all-rank"] = [@pl.all().rank(method_=@pl.RankMethod::Min)]
  m["sel/all-diff"] = [@pl.all().diff(n=1)]
  m["sel/all-diff-dates"] = [@pl.all().diff(n=1)]
  m["sel/all-reverse"] = [@pl.all().reverse()]
  m["sel/all-fills"] = [@pl.all().fill_null_strategy(@pl.FillStrategy::Forward)]
  m["sel/all-fills-mean"] = [
    @pl.all().fill_null_strategy(@pl.FillStrategy::Mean),
  ]
  m["sel/all-shift-z0"] = [@pl.all().shift(n=1)]
  m["sel/all-shift-e0"] = [@pl.all().shift(n=1)]
  m["sel/cols-empty"] = [@pl.cols([]).shift(n=1)]
  m["sel/cols-missing"] = [@pl.cols(["i32", "zz"]).shift(n=1)]
  m["sel/cols-op"] = [
    @pl.cols(["i32", "i64"]) - @pl.cols(["i32", "i64"]).shift(n=1),
  ]
  m["sel/cols-op-width"] = [
    @pl.cols(["i32", "i64"]) - @pl.cols(["i32", "i64", "f64"]).shift(n=1),
  ]
  m["sel/cols-alias"] = [@pl.cols(["i32", "i64"]).cum_sum().alias("x")]
  m["sel/all-wc"] = [@pl.all().cum_sum()]
  m["len1/sum-shift"] = [@pl.col("i32").sum().shift(n=1)]
  m["len1/sum-shift-neg"] = [@pl.col("i32").sum().shift(n=-1)]
  m["len1/sum-shift-fill"] = [
    @pl.col("i32").sum().shift(n=1, fill_value=@pl.AnyValue::Int32(7)),
  ]
  m["len1/sum-cum_sum"] = [@pl.col("i32").sum().cum_sum()]
  m["len1/sum-diff"] = [@pl.col("i32").sum().diff(n=1)]
  m["len1/sum-rank"] = [
    @pl.col("i32").sum().rank(method_=@pl.RankMethod::Average),
  ]
  m["len1/sum-reverse"] = [@pl.col("i32").sum().reverse()]
  m["len1/sum-fills"] = [
    @pl.col("n").first().fill_null_strategy(@pl.FillStrategy::Forward),
  ]
  m["len1/lit-cum_sum"] = [@pl.lit_int(1L).cum_sum()]
  m["len1/litf-cum_sum"] = [@pl.lit_float(1.5).cum_sum()]
  m["len1/lit-shift"] = [@pl.lit_int(1L).shift(n=1)]
  m["len1/lit-diff"] = [@pl.lit_int(1L).diff(n=1)]
  m["len1/lit-rank"] = [@pl.lit_int(1L).rank(method_=@pl.RankMethod::Average)]
  m["len1/lit-reverse"] = [@pl.lit_int(1L).reverse()]
  m["len1/lit-cum_count"] = [@pl.lit_int(1L).cum_count()]
  m["len1/lit-strong-cum_sum"] = [@pl.lit(@pl.AnyValue::Int32(5)).cum_sum()]
  m["len1/lit-str-cum_min"] = [@pl.lit_str("a").cum_min()]
  m["len1/lit-null-cum_sum"] = [@pl.lit(@pl.AnyValue::Null).cum_sum()]
  m["len1/lit-null-shift"] = [@pl.lit(@pl.AnyValue::Null).shift(n=1)]
  m["len1/col-and-lit-cum"] = [
    @pl.col("i32"),
    @pl.lit_int(1L).cum_sum().alias("c"),
  ]
  m["len1/col-and-sum-shift"] = [
    @pl.col("i32"),
    @pl.col("i32").sum().shift(n=1).alias("s"),
  ]
}

///|
fn golden_expr_seq_cases_10(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["len1/col-and-seq"] = [
    @pl.col("i32"),
    @pl.col("i64").sum().cum_sum().alias("c"),
  ]
  m["len1/wc-lit-cum"] = [@pl.lit_int(1L).cum_sum().alias("c")]
  m["len1/wc-sum-shift"] = [@pl.col("i32").sum().shift(n=1).alias("c")]
  m["len1/z0-lit-cum"] = [@pl.lit_int(1L).cum_sum()]
  m["len1/z0-lit-shift"] = [@pl.lit_int(1L).shift(n=1)]
  m["len1/e0-col-and-seq"] = [
    @pl.col("i32"),
    @pl.col("i64").sum().cum_sum().alias("c"),
  ]
  m["len1/e0-lit-cum"] = [@pl.lit_int(1L).cum_sum()]
  m["len1/e0-cum-lit"] = [@pl.lit_int(1L).cum_sum().alias("c"), @pl.col("i32")]
  m["len1/r1-cum"] = [
    @pl.col("i32").cum_sum(),
    @pl.col("i64").shift(n=1).alias("s"),
  ]
  m["len1/r1-lit-seq"] = [@pl.col("i32"), @pl.lit_int(2L).cum_sum().alias("c")]
  m["shape/two-lens"] = [
    @pl.col("i32").shift(n=1),
    @pl.lit_int(1L).cum_sum().alias("x"),
  ]
  m["shape/sum-vs-col"] = [@pl.col("i32").sum().cum_sum(), @pl.col("i64")]
  m["str/to_lowercase/s"] = [@pl.col("s").str().to_lowercase()]
  m["str/to_lowercase/u"] = [@pl.col("u").str().to_lowercase()]
  m["str/to_lowercase/i32"] = [@pl.col("i32").str().to_lowercase()]
  m["str/to_lowercase/d"] = [@pl.col("d").str().to_lowercase()]
  m["str/to_lowercase/n"] = [@pl.col("n").str().to_lowercase()]
  m["str/to_lowercase/b"] = [@pl.col("b").str().to_lowercase()]
  m["str/to_lowercase/e0"] = [@pl.col("s").str().to_lowercase()]
  m["str/to_lowercase/e0-i32"] = [@pl.col("i32").str().to_lowercase()]
  m["str/to_lowercase/t"] = [@pl.col("s").str().to_lowercase()]
  m["str/to_uppercase/s"] = [@pl.col("s").str().to_uppercase()]
  m["str/to_uppercase/u"] = [@pl.col("u").str().to_uppercase()]
  m["str/to_uppercase/i32"] = [@pl.col("i32").str().to_uppercase()]
  m["str/to_uppercase/d"] = [@pl.col("d").str().to_uppercase()]
  m["str/to_uppercase/n"] = [@pl.col("n").str().to_uppercase()]
  m["str/to_uppercase/b"] = [@pl.col("b").str().to_uppercase()]
  m["str/to_uppercase/e0"] = [@pl.col("s").str().to_uppercase()]
  m["str/to_uppercase/e0-i32"] = [@pl.col("i32").str().to_uppercase()]
  m["str/to_uppercase/t"] = [@pl.col("s").str().to_uppercase()]
  m["str/len_chars/s"] = [@pl.col("s").str().len_chars()]
  m["str/len_chars/u"] = [@pl.col("u").str().len_chars()]
  m["str/len_chars/i32"] = [@pl.col("i32").str().len_chars()]
  m["str/len_chars/d"] = [@pl.col("d").str().len_chars()]
  m["str/len_chars/n"] = [@pl.col("n").str().len_chars()]
  m["str/len_chars/b"] = [@pl.col("b").str().len_chars()]
  m["str/len_chars/e0"] = [@pl.col("s").str().len_chars()]
  m["str/len_chars/e0-i32"] = [@pl.col("i32").str().len_chars()]
  m["str/len_chars/t"] = [@pl.col("s").str().len_chars()]
  m["str/len_bytes/s"] = [@pl.col("s").str().len_bytes()]
  m["str/len_bytes/u"] = [@pl.col("u").str().len_bytes()]
  m["str/len_bytes/i32"] = [@pl.col("i32").str().len_bytes()]
  m["str/len_bytes/d"] = [@pl.col("d").str().len_bytes()]
  m["str/len_bytes/n"] = [@pl.col("n").str().len_bytes()]
  m["str/len_bytes/b"] = [@pl.col("b").str().len_bytes()]
  m["str/len_bytes/e0"] = [@pl.col("s").str().len_bytes()]
  m["str/len_bytes/e0-i32"] = [@pl.col("i32").str().len_bytes()]
  m["str/len_bytes/t"] = [@pl.col("s").str().len_bytes()]
  m["str/contains/a/False"] = [@pl.col("s").str().contains("a")]
  m["str/contains/a/True"] = [@pl.col("s").str().contains("a", literal=true)]
  m["str/contains/a.c/False"] = [@pl.col("s").str().contains("a.c")]
  m["str/contains/a.c/True"] = [
    @pl.col("s").str().contains("a.c", literal=true),
  ]
  m["str/contains/^a/False"] = [@pl.col("s").str().contains("^a")]
  m["str/contains/^a/True"] = [@pl.col("s").str().contains("^a", literal=true)]
  m["str/contains/b+/False"] = [@pl.col("s").str().contains("b+")]
  m["str/contains/b+/True"] = [@pl.col("s").str().contains("b+", literal=true)]
  m["str/contains/(ab)+/False"] = [@pl.col("s").str().contains("(ab)+")]
  m["str/contains/(ab)+/True"] = [
    @pl.col("s").str().contains("(ab)+", literal=true),
  ]
  m["str/contains//False"] = [@pl.col("s").str().contains("")]
  m["str/contains//True"] = [@pl.col("s").str().contains("", literal=true)]
}

///|
fn golden_expr_seq_cases_11(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["str/contains/[a-c]{2}/False"] = [@pl.col("s").str().contains("[a-c]{2}")]
  m["str/contains/[a-c]{2}/True"] = [
    @pl.col("s").str().contains("[a-c]{2}", literal=true),
  ]
  m["str/contains/é/False"] = [@pl.col("s").str().contains("é")]
  m["str/contains/é/True"] = [@pl.col("s").str().contains("é", literal=true)]
  m["str/contains/u"] = [@pl.col("u").str().contains("a")]
  m["str/contains/u-literal"] = [@pl.col("u").str().contains("a", literal=true)]
  m["str/contains/i32"] = [@pl.col("i32").str().contains("a")]
  m["str/contains/i32-literal"] = [
    @pl.col("i32").str().contains("a", literal=true),
  ]
  m["str/contains/d"] = [@pl.col("d").str().contains("a")]
  m["str/contains/d-literal"] = [@pl.col("d").str().contains("a", literal=true)]
  m["str/contains/n"] = [@pl.col("n").str().contains("a")]
  m["str/contains/n-literal"] = [@pl.col("n").str().contains("a", literal=true)]
  m["str/contains/b"] = [@pl.col("b").str().contains("a")]
  m["str/contains/b-literal"] = [@pl.col("b").str().contains("a", literal=true)]
  m["str/contains/bad/("] = [@pl.col("s").str().contains("(")]
  m["str/contains/bad/(/e0"] = [@pl.col("s").str().contains("(")]
  m["str/replace/bad/("] = [@pl.col("s").str().replace("(", "x")]
  m["str/replace_all/bad/("] = [@pl.col("s").str().replace_all("(", "x")]
  m["str/contains/bad/[a"] = [@pl.col("s").str().contains("[a")]
  m["str/contains/bad/[a/e0"] = [@pl.col("s").str().contains("[a")]
  m["str/replace/bad/[a"] = [@pl.col("s").str().replace("[a", "x")]
  m["str/replace_all/bad/[a"] = [@pl.col("s").str().replace_all("[a", "x")]
  m["str/contains/bad/a{2,1}"] = [@pl.col("s").str().contains("a{2,1}")]
  m["str/contains/bad/a{2,1}/e0"] = [@pl.col("s").str().contains("a{2,1}")]
  m["str/replace/bad/a{2,1}"] = [@pl.col("s").str().replace("a{2,1}", "x")]
  m["str/replace_all/bad/a{2,1}"] = [
    @pl.col("s").str().replace_all("a{2,1}", "x"),
  ]
  m["str/contains/bad/*"] = [@pl.col("s").str().contains("*")]
  m["str/contains/bad/*/e0"] = [@pl.col("s").str().contains("*")]
  m["str/replace/bad/*"] = [@pl.col("s").str().replace("*", "x")]
  m["str/replace_all/bad/*"] = [@pl.col("s").str().replace_all("*", "x")]
  m["str/contains/bad-literal-ok"] = [
    @pl.col("s").str().contains("(", literal=true),
  ]
  m["str/contains/bad-wrong-dtype"] = [@pl.col("i32").str().contains("(")]
  m["str/starts_with/aff-a"] = [@pl.col("s").str().starts_with("a")]
  m["str/starts_with/aff-"] = [@pl.col("s").str().starts_with("")]
  m["str/starts_with/aff-abc"] = [@pl.col("s").str().starts_with("abc")]
  m["str/starts_with/aff-x"] = [@pl.col("s").str().starts_with("x")]
  m["str/starts_with/aff-é"] = [@pl.col("s").str().starts_with("é")]
  m["str/starts_with/aff-｡"] = [@pl.col("s").str().starts_with("｡")]
  m["str/starts_with/aff-b"] = [@pl.col("s").str().starts_with("b")]
  m["str/starts_with/aff-  "] = [@pl.col("s").str().starts_with("  ")]
  m["str/starts_with/u"] = [@pl.col("u").str().starts_with("a")]
  m["str/starts_with/i32"] = [@pl.col("i32").str().starts_with("a")]
  m["str/starts_with/d"] = [@pl.col("d").str().starts_with("a")]
  m["str/starts_with/n"] = [@pl.col("n").str().starts_with("a")]
  m["str/starts_with/b"] = [@pl.col("b").str().starts_with("a")]
  m["str/starts_with/e0"] = [@pl.col("s").str().starts_with("a")]
  m["str/ends_with/aff-a"] = [@pl.col("s").str().ends_with("a")]
  m["str/ends_with/aff-"] = [@pl.col("s").str().ends_with("")]
  m["str/ends_with/aff-abc"] = [@pl.col("s").str().ends_with("abc")]
  m["str/ends_with/aff-x"] = [@pl.col("s").str().ends_with("x")]
  m["str/ends_with/aff-é"] = [@pl.col("s").str().ends_with("é")]
  m["str/ends_with/aff-｡"] = [@pl.col("s").str().ends_with("｡")]
  m["str/ends_with/aff-b"] = [@pl.col("s").str().ends_with("b")]
  m["str/ends_with/aff-  "] = [@pl.col("s").str().ends_with("  ")]
  m["str/ends_with/u"] = [@pl.col("u").str().ends_with("a")]
  m["str/ends_with/i32"] = [@pl.col("i32").str().ends_with("a")]
  m["str/ends_with/d"] = [@pl.col("d").str().ends_with("a")]
  m["str/ends_with/n"] = [@pl.col("n").str().ends_with("a")]
  m["str/ends_with/b"] = [@pl.col("b").str().ends_with("a")]
  m["str/ends_with/e0"] = [@pl.col("s").str().ends_with("a")]
}

///|
fn golden_expr_seq_cases_12(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["str/replace/b/X/False"] = [@pl.col("s").str().replace("b", "X")]
  m["str/replace/a//False"] = [@pl.col("s").str().replace("a", "")]
  m["str/replace//-/False"] = [@pl.col("s").str().replace("", "-")]
  m["str/replace/[0-9]+/<$0>/False"] = [
    @pl.col("s").str().replace("[0-9]+", "<$0>"),
  ]
  m["str/replace/([a-z])([0-9]+)/$2$1/False"] = [
    @pl.col("s").str().replace("([a-z])([0-9]+)", "$2$1"),
  ]
  m["str/replace/./!/True"] = [
    @pl.col("s").str().replace(".", "!", literal=true),
  ]
  m["str/replace/[a-c]/!/False"] = [@pl.col("s").str().replace("[a-c]", "!")]
  m["str/replace/A/$0/True"] = [
    @pl.col("s").str().replace("A", "$0", literal=true),
  ]
  m["str/replace/x*/-/False"] = [@pl.col("s").str().replace("x*", "-")]
  m["str/replace/b/$$/False"] = [@pl.col("s").str().replace("b", "$$")]
  m["str/replace/[a-c]/😀/False"] = [
    @pl.col("s").str().replace("[a-c]", "😀"),
  ]
  m["str/replace/a/😀/False"] = [@pl.col("s").str().replace("a", "😀")]
  m["str/replace/a/a😀/False"] = [@pl.col("s").str().replace("a", "a😀")]
  m["str/replace/b/𝒳y/False"] = [@pl.col("s").str().replace("b", "𝒳y")]
  m["str/replace/[0-9]+/<$0>😀/False"] = [
    @pl.col("s").str().replace("[0-9]+", "<$0>😀"),
  ]
  m["str/replace/([a-z])([0-9]+)/😀$2$1😀/False"] = [
    @pl.col("s").str().replace("([a-z])([0-9]+)", "😀$2$1😀"),
  ]
  m["str/replace/(a)/😀${1}😀$$/False"] = [
    @pl.col("s").str().replace("(a)", "😀${1}😀$$"),
  ]
  m["str/replace/a/😀/True"] = [
    @pl.col("s").str().replace("a", "😀", literal=true),
  ]
  m["str/replace/u"] = [@pl.col("u").str().replace("a", "b")]
  m["str/replace/i32"] = [@pl.col("i32").str().replace("a", "b")]
  m["str/replace/d"] = [@pl.col("d").str().replace("a", "b")]
  m["str/replace/n"] = [@pl.col("n").str().replace("a", "b")]
  m["str/replace/b"] = [@pl.col("b").str().replace("a", "b")]
  m["str/replace/e0"] = [@pl.col("s").str().replace("a", "b")]
  m["str/replace_all/b/X/False"] = [@pl.col("s").str().replace_all("b", "X")]
  m["str/replace_all/a//False"] = [@pl.col("s").str().replace_all("a", "")]
  m["str/replace_all//-/False"] = [@pl.col("s").str().replace_all("", "-")]
  m["str/replace_all/[0-9]+/<$0>/False"] = [
    @pl.col("s").str().replace_all("[0-9]+", "<$0>"),
  ]
  m["str/replace_all/([a-z])([0-9]+)/$2$1/False"] = [
    @pl.col("s").str().replace_all("([a-z])([0-9]+)", "$2$1"),
  ]
  m["str/replace_all/./!/True"] = [
    @pl.col("s").str().replace_all(".", "!", literal=true),
  ]
  m["str/replace_all/[a-c]/!/False"] = [
    @pl.col("s").str().replace_all("[a-c]", "!"),
  ]
  m["str/replace_all/A/$0/True"] = [
    @pl.col("s").str().replace_all("A", "$0", literal=true),
  ]
  m["str/replace_all/x*/-/False"] = [@pl.col("s").str().replace_all("x*", "-")]
  m["str/replace_all/b/$$/False"] = [@pl.col("s").str().replace_all("b", "$$")]
  m["str/replace_all/[a-c]/😀/False"] = [
    @pl.col("s").str().replace_all("[a-c]", "😀"),
  ]
  m["str/replace_all/a/😀/False"] = [
    @pl.col("s").str().replace_all("a", "😀"),
  ]
  m["str/replace_all/a/a😀/False"] = [
    @pl.col("s").str().replace_all("a", "a😀"),
  ]
  m["str/replace_all/b/𝒳y/False"] = [
    @pl.col("s").str().replace_all("b", "𝒳y"),
  ]
  m["str/replace_all/[0-9]+/<$0>😀/False"] = [
    @pl.col("s").str().replace_all("[0-9]+", "<$0>😀"),
  ]
  m["str/replace_all/([a-z])([0-9]+)/😀$2$1😀/False"] = [
    @pl.col("s").str().replace_all("([a-z])([0-9]+)", "😀$2$1😀"),
  ]
  m["str/replace_all/(a)/😀${1}😀$$/False"] = [
    @pl.col("s").str().replace_all("(a)", "😀${1}😀$$"),
  ]
  m["str/replace_all/a/😀/True"] = [
    @pl.col("s").str().replace_all("a", "😀", literal=true),
  ]
  m["str/replace_all/u"] = [@pl.col("u").str().replace_all("a", "b")]
  m["str/replace_all/i32"] = [@pl.col("i32").str().replace_all("a", "b")]
  m["str/replace_all/d"] = [@pl.col("d").str().replace_all("a", "b")]
  m["str/replace_all/n"] = [@pl.col("n").str().replace_all("a", "b")]
  m["str/replace_all/b"] = [@pl.col("b").str().replace_all("a", "b")]
  m["str/replace_all/e0"] = [@pl.col("s").str().replace_all("a", "b")]
  m["str/strip_chars/chars-None"] = [@pl.col("s").str().strip_chars()]
  m["str/strip_chars/chars-"] = [@pl.col("s").str().strip_chars(characters="")]
  m["str/strip_chars/chars- "] = [
    @pl.col("s").str().strip_chars(characters=" "),
  ]
  m["str/strip_chars/chars-x"] = [
    @pl.col("s").str().strip_chars(characters="x"),
  ]
  m["str/strip_chars/chars-x "] = [
    @pl.col("s").str().strip_chars(characters="x "),
  ]
  m["str/strip_chars/chars-😀"] = [
    @pl.col("s").str().strip_chars(characters="😀"),
  ]
  m["str/strip_chars/chars-hi"] = [
    @pl.col("s").str().strip_chars(characters="hi"),
  ]
  m["str/strip_chars/chars-ab"] = [
    @pl.col("s").str().strip_chars(characters="ab"),
  ]
  m["str/strip_chars/u"] = [@pl.col("u").str().strip_chars()]
  m["str/strip_chars/i32"] = [@pl.col("i32").str().strip_chars()]
  m["str/strip_chars/d"] = [@pl.col("d").str().strip_chars()]
  m["str/strip_chars/n"] = [@pl.col("n").str().strip_chars()]
}

///|
fn golden_expr_seq_cases_13(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["str/strip_chars/b"] = [@pl.col("b").str().strip_chars()]
  m["str/strip_chars/e0"] = [@pl.col("s").str().strip_chars()]
  m["str/strip_chars_start/chars-None"] = [
    @pl.col("s").str().strip_chars_start(),
  ]
  m["str/strip_chars_start/chars-"] = [
    @pl.col("s").str().strip_chars_start(characters=""),
  ]
  m["str/strip_chars_start/chars- "] = [
    @pl.col("s").str().strip_chars_start(characters=" "),
  ]
  m["str/strip_chars_start/chars-x"] = [
    @pl.col("s").str().strip_chars_start(characters="x"),
  ]
  m["str/strip_chars_start/chars-x "] = [
    @pl.col("s").str().strip_chars_start(characters="x "),
  ]
  m["str/strip_chars_start/chars-😀"] = [
    @pl.col("s").str().strip_chars_start(characters="😀"),
  ]
  m["str/strip_chars_start/chars-hi"] = [
    @pl.col("s").str().strip_chars_start(characters="hi"),
  ]
  m["str/strip_chars_start/chars-ab"] = [
    @pl.col("s").str().strip_chars_start(characters="ab"),
  ]
  m["str/strip_chars_start/u"] = [@pl.col("u").str().strip_chars_start()]
  m["str/strip_chars_start/i32"] = [@pl.col("i32").str().strip_chars_start()]
  m["str/strip_chars_start/d"] = [@pl.col("d").str().strip_chars_start()]
  m["str/strip_chars_start/n"] = [@pl.col("n").str().strip_chars_start()]
  m["str/strip_chars_start/b"] = [@pl.col("b").str().strip_chars_start()]
  m["str/strip_chars_start/e0"] = [@pl.col("s").str().strip_chars_start()]
  m["str/strip_chars_end/chars-None"] = [@pl.col("s").str().strip_chars_end()]
  m["str/strip_chars_end/chars-"] = [
    @pl.col("s").str().strip_chars_end(characters=""),
  ]
  m["str/strip_chars_end/chars- "] = [
    @pl.col("s").str().strip_chars_end(characters=" "),
  ]
  m["str/strip_chars_end/chars-x"] = [
    @pl.col("s").str().strip_chars_end(characters="x"),
  ]
  m["str/strip_chars_end/chars-x "] = [
    @pl.col("s").str().strip_chars_end(characters="x "),
  ]
  m["str/strip_chars_end/chars-😀"] = [
    @pl.col("s").str().strip_chars_end(characters="😀"),
  ]
  m["str/strip_chars_end/chars-hi"] = [
    @pl.col("s").str().strip_chars_end(characters="hi"),
  ]
  m["str/strip_chars_end/chars-ab"] = [
    @pl.col("s").str().strip_chars_end(characters="ab"),
  ]
  m["str/strip_chars_end/u"] = [@pl.col("u").str().strip_chars_end()]
  m["str/strip_chars_end/i32"] = [@pl.col("i32").str().strip_chars_end()]
  m["str/strip_chars_end/d"] = [@pl.col("d").str().strip_chars_end()]
  m["str/strip_chars_end/n"] = [@pl.col("n").str().strip_chars_end()]
  m["str/strip_chars_end/b"] = [@pl.col("b").str().strip_chars_end()]
  m["str/strip_chars_end/e0"] = [@pl.col("s").str().strip_chars_end()]
  m["str/chain"] = [@pl.col("s").str().strip_chars().str().len_chars()]
  m["str/chain-case"] = [
    @pl.col("s").str().to_lowercase().str().contains("hello"),
  ]
  m["str/chain-replace"] = [
    @pl.col("s").str().replace_all("a", "b").str().to_uppercase(),
  ]
  m["str/len-sum"] = [@pl.col("s").str().len_chars().sum()]
  m["str/len-max"] = [@pl.col("s").str().len_bytes().max().alias("m")]
  m["str/len-plus"] = [@pl.col("s").str().len_chars() + @pl.lit_int(1L)]
  m["str/len-gt"] = [@pl.col("s").str().len_chars().gt(@pl.lit_int(3L))]
  m["str/len-mean"] = [
    @pl.col("s").str().len_chars() / @pl.col("s").str().len_chars().mean(),
  ]
  m["str/contains-and"] = [
    @pl.col("s").str().contains("a") & @pl.col("u").str().starts_with("c"),
  ]
  m["str/contains-not"] = [@pl.col("s").str().contains("a").not_()]
  m["str/contains-sum"] = [@pl.col("s").str().contains("a").sum()]
  m["str/contains-is_null"] = [@pl.col("s").str().contains("a").is_null()]
  m["str/when"] = [
    @pl.when(@pl.col("s").str().contains("a"))
    .then(@pl.col("s").str().to_uppercase())
    .otherwise(@pl.col("u")),
  ]
  m["str/fill"] = [
    @pl.col("s").str().to_uppercase().fill_null(@pl.lit_str("none")),
  ]
  m["str/fill-value"] = [
    @pl.col("s").fill_null(@pl.col("u").str().to_uppercase()),
  ]
  m["str/alias"] = [@pl.col("s").str().to_uppercase().alias("z")]
  m["str/alias-inner"] = [@pl.col("s").alias("z").str().to_uppercase()]
  m["str/names"] = [
    @pl.col("s").str().to_uppercase(),
    @pl.col("u").str().to_lowercase(),
    @pl.col("s").str().len_chars().alias("n"),
  ]
  m["str/dup"] = [
    @pl.col("s").str().to_uppercase(),
    @pl.col("s").str().to_lowercase(),
  ]
  m["str/dup-with-col"] = [@pl.col("s"), @pl.col("s").str().to_lowercase()]
  m["str/wc"] = [
    @pl.col("s").str().to_uppercase().alias("up"),
    @pl.col("s").str().len_chars().alias("n"),
  ]
  m["str/wc-in-place"] = [@pl.col("s").str().to_uppercase()]
  m["str/cols"] = [@pl.cols(["s", "u"]).str().to_uppercase()]
  m["str/cols-len"] = [@pl.cols(["s", "u"]).str().len_chars()]
  m["str/cols-with-error"] = [@pl.cols(["s", "i32"]).str().to_uppercase()]
  m["str/all-strings"] = [@pl.cols(["s", "u"]).str().to_uppercase()]
  m["str/all-z0"] = [@pl.all().str().to_uppercase()]
  m["str/cols-empty"] = [@pl.cols([]).str().to_uppercase()]
  m["str/missing"] = [@pl.col("zz").str().to_uppercase()]
  m["str/missing-after-error"] = [
    @pl.col("i32").str().to_uppercase(),
    @pl.col("zz").str().to_uppercase(),
  ]
}

///|
fn golden_expr_seq_cases_14(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["str/error-order2"] = [
    @pl.col("d").str().contains("a"),
    @pl.col("i32").str().to_uppercase(),
  ]
  m["str/lit"] = [@pl.lit_str("abc").str().to_uppercase()]
  m["str/lit-len"] = [@pl.lit_str("a😀").str().len_chars()]
  m["str/lit-contains"] = [@pl.lit_str("abc").str().contains("b")]
  m["str/lit-replace"] = [@pl.lit_str("abc").str().replace("b", "X")]
  m["str/lit-strip"] = [@pl.lit_str("  a  ").str().strip_chars()]
  m["str/lit-col"] = [
    @pl.col("s"),
    @pl.lit_str("abc").str().to_uppercase().alias("k"),
  ]
  m["str/lit-col-len"] = [
    @pl.lit_str("abc").str().len_chars().alias("k"),
    @pl.col("i32"),
  ]
  m["str/lit-wc"] = [@pl.lit_str("abc").str().to_uppercase().alias("k")]
  m["str/lit-e0"] = [@pl.lit_str("abc").str().to_uppercase()]
  m["str/lit-e0-col"] = [
    @pl.col("s"),
    @pl.lit_str("abc").str().to_uppercase().alias("k"),
  ]
  m["str/lit-z0"] = [@pl.lit_str("abc").str().to_uppercase()]
  m["str/lit-float"] = [@pl.lit_float(1.5).str().len_chars()]
  m["str/lit-bool"] = [@pl.lit_bool(true).str().to_uppercase()]
  m["str/lit-null"] = [@pl.lit(@pl.AnyValue::Null).str().to_uppercase()]
  m["str/lit-null-contains"] = [@pl.lit(@pl.AnyValue::Null).str().contains("a")]
  m["str/agg-input"] = [@pl.col("s").max().str().to_uppercase()]
  m["str/agg-input-len"] = [@pl.col("s").min().str().len_chars()]
  m["str/agg-input-int"] = [@pl.col("i32").sum().str().to_uppercase()]
  m["str/agg-and-col"] = [
    @pl.col("s"),
    @pl.col("s").max().str().to_uppercase().alias("m"),
  ]
  m["str/shift-then"] = [@pl.col("s").shift(n=1).str().to_uppercase()]
  m["str/cum_min-then"] = [@pl.col("s").cum_min().str().len_chars()]
  m["str/add-strings"] = [@pl.col("s").str().to_uppercase() + @pl.col("u")]
  m["str/cast-len"] = [
    @pl.col("s").str().len_chars().cast(@pl.DataType::String),
  ]
  m["str/cast-then"] = [
    @pl.col("i32").cast(@pl.DataType::String).str().len_chars(),
  ]
  m["str/cast-upper"] = [
    @pl.col("d").cast(@pl.DataType::String).str().to_uppercase(),
  ]
  m["str/is_in"] = [@pl.col("s").str().to_lowercase().is_in(vs["str"])]
  m["str/is_in-a"] = [@pl.col("s").str().to_lowercase().is_in(vs["str"])]
  m["str/between"] = [
    @pl.col("s")
    .str()
    .to_lowercase()
    .between(
      @pl.lit_str("a"),
      @pl.lit_str("m"),
      closed=@pl.ClosedInterval::Both,
    ),
  ]
  m["str/rank-len"] = [
    @pl.col("s").str().len_chars().rank(method_=@pl.RankMethod::Dense),
  ]
  m["str/cum_sum-len"] = [@pl.col("s").str().len_chars().cum_sum()]
  m["str/diff-len"] = [@pl.col("s").str().len_chars().diff(n=1)]
  m["str/r1"] = [
    @pl.col("s").str().to_uppercase(),
    @pl.col("s").str().len_chars().alias("n"),
  ]
  m["str/cum_sum-str"] = [@pl.col("s").str().to_uppercase().cum_sum()]
  m["dt/year/d"] = [@pl.col("d").dt().year()]
  m["dt/year/dt"] = [@pl.col("dt").dt().year()]
  m["dt/year/i32"] = [@pl.col("i32").dt().year()]
  m["dt/year/s"] = [@pl.col("s").dt().year()]
  m["dt/year/n"] = [@pl.col("n").dt().year()]
  m["dt/year/e0-date"] = [@pl.col("d").dt().year()]
  m["dt/year/e0-dt"] = [@pl.col("dt").dt().year()]
  m["dt/year/t"] = [@pl.col("dt").dt().year()]
  m["dt/year/t-date"] = [@pl.col("d").dt().year()]
  m["dt/year/lit"] = [
    @pl.lit(@pl.AnyValue::Datetime(1709210096123456L)).dt().year(),
  ]
  m["dt/year/lit-date"] = [@pl.lit(@pl.AnyValue::Date(19782)).dt().year()]
  m["dt/year/agg"] = [@pl.col("dt").max().dt().year()]
  m["dt/month/d"] = [@pl.col("d").dt().month()]
  m["dt/month/dt"] = [@pl.col("dt").dt().month()]
  m["dt/month/i32"] = [@pl.col("i32").dt().month()]
  m["dt/month/s"] = [@pl.col("s").dt().month()]
  m["dt/month/n"] = [@pl.col("n").dt().month()]
  m["dt/month/e0-date"] = [@pl.col("d").dt().month()]
  m["dt/month/e0-dt"] = [@pl.col("dt").dt().month()]
  m["dt/month/t"] = [@pl.col("dt").dt().month()]
  m["dt/month/t-date"] = [@pl.col("d").dt().month()]
  m["dt/month/lit"] = [
    @pl.lit(@pl.AnyValue::Datetime(1709210096123456L)).dt().month(),
  ]
  m["dt/month/lit-date"] = [@pl.lit(@pl.AnyValue::Date(19782)).dt().month()]
  m["dt/month/agg"] = [@pl.col("dt").max().dt().month()]
  m["dt/day/d"] = [@pl.col("d").dt().day()]
  m["dt/day/dt"] = [@pl.col("dt").dt().day()]
}

///|
fn golden_expr_seq_cases_15(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["dt/day/i32"] = [@pl.col("i32").dt().day()]
  m["dt/day/s"] = [@pl.col("s").dt().day()]
  m["dt/day/n"] = [@pl.col("n").dt().day()]
  m["dt/day/e0-date"] = [@pl.col("d").dt().day()]
  m["dt/day/e0-dt"] = [@pl.col("dt").dt().day()]
  m["dt/day/t"] = [@pl.col("dt").dt().day()]
  m["dt/day/t-date"] = [@pl.col("d").dt().day()]
  m["dt/day/lit"] = [
    @pl.lit(@pl.AnyValue::Datetime(1709210096123456L)).dt().day(),
  ]
  m["dt/day/lit-date"] = [@pl.lit(@pl.AnyValue::Date(19782)).dt().day()]
  m["dt/day/agg"] = [@pl.col("dt").max().dt().day()]
  m["dt/weekday/d"] = [@pl.col("d").dt().weekday()]
  m["dt/weekday/dt"] = [@pl.col("dt").dt().weekday()]
  m["dt/weekday/i32"] = [@pl.col("i32").dt().weekday()]
  m["dt/weekday/s"] = [@pl.col("s").dt().weekday()]
  m["dt/weekday/n"] = [@pl.col("n").dt().weekday()]
  m["dt/weekday/e0-date"] = [@pl.col("d").dt().weekday()]
  m["dt/weekday/e0-dt"] = [@pl.col("dt").dt().weekday()]
  m["dt/weekday/t"] = [@pl.col("dt").dt().weekday()]
  m["dt/weekday/t-date"] = [@pl.col("d").dt().weekday()]
  m["dt/weekday/lit"] = [
    @pl.lit(@pl.AnyValue::Datetime(1709210096123456L)).dt().weekday(),
  ]
  m["dt/weekday/lit-date"] = [@pl.lit(@pl.AnyValue::Date(19782)).dt().weekday()]
  m["dt/weekday/agg"] = [@pl.col("dt").max().dt().weekday()]
  m["dt/ordinal_day/d"] = [@pl.col("d").dt().ordinal_day()]
  m["dt/ordinal_day/dt"] = [@pl.col("dt").dt().ordinal_day()]
  m["dt/ordinal_day/i32"] = [@pl.col("i32").dt().ordinal_day()]
  m["dt/ordinal_day/s"] = [@pl.col("s").dt().ordinal_day()]
  m["dt/ordinal_day/n"] = [@pl.col("n").dt().ordinal_day()]
  m["dt/ordinal_day/e0-date"] = [@pl.col("d").dt().ordinal_day()]
  m["dt/ordinal_day/e0-dt"] = [@pl.col("dt").dt().ordinal_day()]
  m["dt/ordinal_day/t"] = [@pl.col("dt").dt().ordinal_day()]
  m["dt/ordinal_day/t-date"] = [@pl.col("d").dt().ordinal_day()]
  m["dt/ordinal_day/lit"] = [
    @pl.lit(@pl.AnyValue::Datetime(1709210096123456L)).dt().ordinal_day(),
  ]
  m["dt/ordinal_day/lit-date"] = [
    @pl.lit(@pl.AnyValue::Date(19782)).dt().ordinal_day(),
  ]
  m["dt/ordinal_day/agg"] = [@pl.col("dt").max().dt().ordinal_day()]
  m["dt/hour/d"] = [@pl.col("d").dt().hour()]
  m["dt/hour/dt"] = [@pl.col("dt").dt().hour()]
  m["dt/hour/i32"] = [@pl.col("i32").dt().hour()]
  m["dt/hour/s"] = [@pl.col("s").dt().hour()]
  m["dt/hour/n"] = [@pl.col("n").dt().hour()]
  m["dt/hour/e0-date"] = [@pl.col("d").dt().hour()]
  m["dt/hour/e0-dt"] = [@pl.col("dt").dt().hour()]
  m["dt/hour/t"] = [@pl.col("dt").dt().hour()]
  m["dt/hour/t-date"] = [@pl.col("d").dt().hour()]
  m["dt/hour/lit"] = [
    @pl.lit(@pl.AnyValue::Datetime(1709210096123456L)).dt().hour(),
  ]
  m["dt/hour/lit-date"] = [@pl.lit(@pl.AnyValue::Date(19782)).dt().hour()]
  m["dt/hour/agg"] = [@pl.col("dt").max().dt().hour()]
  m["dt/minute/d"] = [@pl.col("d").dt().minute()]
  m["dt/minute/dt"] = [@pl.col("dt").dt().minute()]
  m["dt/minute/i32"] = [@pl.col("i32").dt().minute()]
  m["dt/minute/s"] = [@pl.col("s").dt().minute()]
  m["dt/minute/n"] = [@pl.col("n").dt().minute()]
  m["dt/minute/e0-date"] = [@pl.col("d").dt().minute()]
  m["dt/minute/e0-dt"] = [@pl.col("dt").dt().minute()]
  m["dt/minute/t"] = [@pl.col("dt").dt().minute()]
  m["dt/minute/t-date"] = [@pl.col("d").dt().minute()]
  m["dt/minute/lit"] = [
    @pl.lit(@pl.AnyValue::Datetime(1709210096123456L)).dt().minute(),
  ]
  m["dt/minute/lit-date"] = [@pl.lit(@pl.AnyValue::Date(19782)).dt().minute()]
  m["dt/minute/agg"] = [@pl.col("dt").max().dt().minute()]
  m["dt/second/d"] = [@pl.col("d").dt().second()]
  m["dt/second/dt"] = [@pl.col("dt").dt().second()]
}

///|
fn golden_expr_seq_cases_16(
  m : Map[String, Array[@pl.Expr]],
  vs : Map[String, @pl.Series],
) -> Unit {
  ignore(vs)
  m["dt/second/i32"] = [@pl.col("i32").dt().second()]
  m["dt/second/s"] = [@pl.col("s").dt().second()]
  m["dt/second/n"] = [@pl.col("n").dt().second()]
  m["dt/second/e0-date"] = [@pl.col("d").dt().second()]
  m["dt/second/e0-dt"] = [@pl.col("dt").dt().second()]
  m["dt/second/t"] = [@pl.col("dt").dt().second()]
  m["dt/second/t-date"] = [@pl.col("d").dt().second()]
  m["dt/second/lit"] = [
    @pl.lit(@pl.AnyValue::Datetime(1709210096123456L)).dt().second(),
  ]
  m["dt/second/lit-date"] = [@pl.lit(@pl.AnyValue::Date(19782)).dt().second()]
  m["dt/second/agg"] = [@pl.col("dt").max().dt().second()]
  m["dt/lit-str"] = [@pl.lit_str("2020-01-01").dt().year()]
  m["dt/lit-null"] = [@pl.lit(@pl.AnyValue::Null).dt().year()]
  m["dt/chain"] = [@pl.col("d").dt().year() + @pl.col("d").dt().month()]
  m["dt/year-plus"] = [@pl.col("d").dt().year() + @pl.lit_int(1L)]
  m["dt/weekday-eq"] = [@pl.col("d").dt().weekday().eq(@pl.lit_int(1L))]
  m["dt/weekday-gt"] = [@pl.col("dt").dt().weekday().ge(@pl.lit_int(6L))]
  m["dt/year-sum"] = [@pl.col("d").dt().year().sum()]
  m["dt/year-max-min"] = [
    @pl.col("dt").dt().year().max(),
    @pl.col("dt").dt().year().min().alias("mn"),
  ]
  m["dt/hour-mean"] = [@pl.col("dt").dt().hour().mean()]
  m["dt/year-cast"] = [@pl.col("d").dt().year().cast(@pl.DataType::Int64)]
  m["dt/year-cast-str"] = [@pl.col("d").dt().month().cast(@pl.DataType::String)]
  m["dt/year-fill"] = [@pl.col("d").dt().year().fill_null(@pl.lit_int(0L))]
  m["dt/year-fill-dt"] = [
    @pl.col("dt").dt().hour().fill_null(@pl.col("dt").dt().year()),
  ]
  m["dt/when"] = [
    @pl.when(@pl.col("d").dt().year().gt(@pl.lit_int(1999L)))
    .then(@pl.lit_str("new"))
    .otherwise(@pl.lit_str("old")),
  ]
  m["dt/alias"] = [@pl.col("d").dt().year().alias("y")]
  m["dt/alias-inner"] = [@pl.col("d").alias("y").dt().year()]
  m["dt/names"] = [
    @pl.col("d").dt().year(),
    @pl.col("d").dt().month().alias("m"),
    @pl.col("dt").dt().hour().alias("h"),
  ]
  m["dt/dup"] = [@pl.col("d").dt().year(), @pl.col("d").dt().month()]
  m["dt/dup-col"] = [@pl.col("d"), @pl.col("d").dt().month()]
  m["dt/wc"] = [
    @pl.col("d").dt().year().alias("y"),
    @pl.col("dt").dt().second().alias("sec"),
  ]
  m["dt/wc-in-place"] = [@pl.col("d").dt().year().alias("d")]
  m["dt/cols"] = [@pl.cols(["d", "dt"]).dt().year()]
  m["dt/cols-error"] = [@pl.cols(["d", "s"]).dt().year()]
  m["dt/cols-hour"] = [@pl.cols(["dt", "d"]).dt().hour()]
  m["dt/all-z0"] = [@pl.all().dt().year()]
  m["dt/cols-empty"] = [@pl.cols([]).dt().year()]
  m["dt/missing"] = [@pl.col("zz").dt().year()]
  m["dt/missing-after-error"] = [
    @pl.col("s").dt().year(),
    @pl.col("zz").dt().year(),
  ]
  m["dt/shift-then"] = [@pl.col("d").shift(n=1).dt().year()]
  m["dt/cum_max-then"] = [@pl.col("d").cum_max().dt().year()]
  m["dt/reverse-then"] = [@pl.col("dt").reverse().dt().day()]
  m["dt/fills-then"] = [
    @pl.col("d").fill_null_strategy(@pl.FillStrategy::Forward).dt().year(),
  ]
  m["dt/cast-then"] = [@pl.col("dt").cast(@pl.DataType::Date).dt().year()]
  m["dt/cast-then-hour"] = [
    @pl.col("d").cast(@pl.DataType::Datetime).dt().hour(),
  ]
  m["dt/rank-year"] = [
    @pl.col("d").dt().year().rank(method_=@pl.RankMethod::Min),
  ]
  m["dt/diff-year"] = [@pl.col("d").dt().year().diff(n=1)]
  m["dt/lit-col"] = [
    @pl.col("d"),
    @pl.lit(@pl.AnyValue::Date(19782)).dt().year().alias("y"),
  ]
  m["dt/e0-lit-col"] = [
    @pl.col("d"),
    @pl.lit(@pl.AnyValue::Date(19782)).dt().year().alias("y"),
  ]
  m["dt/e0-lit"] = [@pl.lit(@pl.AnyValue::Date(19782)).dt().year()]
  m["dt/z0-lit"] = [@pl.lit(@pl.AnyValue::Date(19782)).dt().year()]
  m["dt/r1"] = [@pl.col("d").dt().year(), @pl.col("dt").dt().hour().alias("h")]
}

///|
/// Every case id with the expressions it builds; `vs` is the `inputs` table.
fn golden_expr_seq_cases(
  vs : Map[String, @pl.Series],
) -> Map[String, Array[@pl.Expr]] {
  let m : Map[String, Array[@pl.Expr]] = Map([])
  golden_expr_seq_cases_0(m, vs)
  golden_expr_seq_cases_1(m, vs)
  golden_expr_seq_cases_2(m, vs)
  golden_expr_seq_cases_3(m, vs)
  golden_expr_seq_cases_4(m, vs)
  golden_expr_seq_cases_5(m, vs)
  golden_expr_seq_cases_6(m, vs)
  golden_expr_seq_cases_7(m, vs)
  golden_expr_seq_cases_8(m, vs)
  golden_expr_seq_cases_9(m, vs)
  golden_expr_seq_cases_10(m, vs)
  golden_expr_seq_cases_11(m, vs)
  golden_expr_seq_cases_12(m, vs)
  golden_expr_seq_cases_13(m, vs)
  golden_expr_seq_cases_14(m, vs)
  golden_expr_seq_cases_15(m, vs)
  golden_expr_seq_cases_16(m, vs)
  m
}
