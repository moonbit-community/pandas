// 由 docs/golden/scripts/expr.py 生成，勿手改

///|
fn golden_expr_cases_0(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cc/add/i32/i32"] = [@pl.col("i32") + @pl.col("i32")]
  m["cc/add/i32/i64"] = [@pl.col("i32") + @pl.col("i64")]
  m["cc/add/i32/f32"] = [@pl.col("i32") + @pl.col("f32")]
  m["cc/add/i32/f64"] = [@pl.col("i32") + @pl.col("f64")]
  m["cc/add/i64/i32"] = [@pl.col("i64") + @pl.col("i32")]
  m["cc/add/i64/i64"] = [@pl.col("i64") + @pl.col("i64")]
  m["cc/add/i64/f32"] = [@pl.col("i64") + @pl.col("f32")]
  m["cc/add/i64/f64"] = [@pl.col("i64") + @pl.col("f64")]
  m["cc/add/f32/i32"] = [@pl.col("f32") + @pl.col("i32")]
  m["cc/add/f32/i64"] = [@pl.col("f32") + @pl.col("i64")]
  m["cc/add/f32/f32"] = [@pl.col("f32") + @pl.col("f32")]
  m["cc/add/f32/f64"] = [@pl.col("f32") + @pl.col("f64")]
  m["cc/add/f64/i32"] = [@pl.col("f64") + @pl.col("i32")]
  m["cc/add/f64/i64"] = [@pl.col("f64") + @pl.col("i64")]
  m["cc/add/f64/f32"] = [@pl.col("f64") + @pl.col("f32")]
  m["cc/add/f64/f64"] = [@pl.col("f64") + @pl.col("f64")]
  m["cc/add/n/i32"] = [@pl.col("n") + @pl.col("i32")]
  m["cc/add/i32/n"] = [@pl.col("i32") + @pl.col("n")]
  m["cc/add/n/f32"] = [@pl.col("n") + @pl.col("f32")]
  m["cc/add/f32/n"] = [@pl.col("f32") + @pl.col("n")]
  m["cc/add/n/n"] = [@pl.col("n") + @pl.col("n")]
  m["cc/add/n/i64"] = [@pl.col("n") + @pl.col("i64")]
  m["cc/add/f64/n"] = [@pl.col("f64") + @pl.col("n")]
  m["cc/sub/i32/i32"] = [@pl.col("i32") - @pl.col("i32")]
  m["cc/sub/i32/i64"] = [@pl.col("i32") - @pl.col("i64")]
  m["cc/sub/i32/f32"] = [@pl.col("i32") - @pl.col("f32")]
  m["cc/sub/i32/f64"] = [@pl.col("i32") - @pl.col("f64")]
  m["cc/sub/i64/i32"] = [@pl.col("i64") - @pl.col("i32")]
  m["cc/sub/i64/i64"] = [@pl.col("i64") - @pl.col("i64")]
  m["cc/sub/i64/f32"] = [@pl.col("i64") - @pl.col("f32")]
  m["cc/sub/i64/f64"] = [@pl.col("i64") - @pl.col("f64")]
  m["cc/sub/f32/i32"] = [@pl.col("f32") - @pl.col("i32")]
  m["cc/sub/f32/i64"] = [@pl.col("f32") - @pl.col("i64")]
  m["cc/sub/f32/f32"] = [@pl.col("f32") - @pl.col("f32")]
  m["cc/sub/f32/f64"] = [@pl.col("f32") - @pl.col("f64")]
  m["cc/sub/f64/i32"] = [@pl.col("f64") - @pl.col("i32")]
  m["cc/sub/f64/i64"] = [@pl.col("f64") - @pl.col("i64")]
  m["cc/sub/f64/f32"] = [@pl.col("f64") - @pl.col("f32")]
  m["cc/sub/f64/f64"] = [@pl.col("f64") - @pl.col("f64")]
  m["cc/mul/i32/i32"] = [@pl.col("i32") * @pl.col("i32")]
  m["cc/mul/i32/i64"] = [@pl.col("i32") * @pl.col("i64")]
  m["cc/mul/i32/f32"] = [@pl.col("i32") * @pl.col("f32")]
  m["cc/mul/i32/f64"] = [@pl.col("i32") * @pl.col("f64")]
  m["cc/mul/i64/i32"] = [@pl.col("i64") * @pl.col("i32")]
  m["cc/mul/i64/i64"] = [@pl.col("i64") * @pl.col("i64")]
  m["cc/mul/i64/f32"] = [@pl.col("i64") * @pl.col("f32")]
  m["cc/mul/i64/f64"] = [@pl.col("i64") * @pl.col("f64")]
  m["cc/mul/f32/i32"] = [@pl.col("f32") * @pl.col("i32")]
  m["cc/mul/f32/i64"] = [@pl.col("f32") * @pl.col("i64")]
  m["cc/mul/f32/f32"] = [@pl.col("f32") * @pl.col("f32")]
  m["cc/mul/f32/f64"] = [@pl.col("f32") * @pl.col("f64")]
  m["cc/mul/f64/i32"] = [@pl.col("f64") * @pl.col("i32")]
  m["cc/mul/f64/i64"] = [@pl.col("f64") * @pl.col("i64")]
  m["cc/mul/f64/f32"] = [@pl.col("f64") * @pl.col("f32")]
  m["cc/mul/f64/f64"] = [@pl.col("f64") * @pl.col("f64")]
  m["cc/div/i32/i32"] = [@pl.col("i32") / @pl.col("i32")]
  m["cc/div/i32/i64"] = [@pl.col("i32") / @pl.col("i64")]
  m["cc/div/i32/f32"] = [@pl.col("i32") / @pl.col("f32")]
  m["cc/div/i32/f64"] = [@pl.col("i32") / @pl.col("f64")]
  m["cc/div/i64/i32"] = [@pl.col("i64") / @pl.col("i32")]
}

///|
fn golden_expr_cases_1(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cc/div/i64/i64"] = [@pl.col("i64") / @pl.col("i64")]
  m["cc/div/i64/f32"] = [@pl.col("i64") / @pl.col("f32")]
  m["cc/div/i64/f64"] = [@pl.col("i64") / @pl.col("f64")]
  m["cc/div/f32/i32"] = [@pl.col("f32") / @pl.col("i32")]
  m["cc/div/f32/i64"] = [@pl.col("f32") / @pl.col("i64")]
  m["cc/div/f32/f32"] = [@pl.col("f32") / @pl.col("f32")]
  m["cc/div/f32/f64"] = [@pl.col("f32") / @pl.col("f64")]
  m["cc/div/f64/i32"] = [@pl.col("f64") / @pl.col("i32")]
  m["cc/div/f64/i64"] = [@pl.col("f64") / @pl.col("i64")]
  m["cc/div/f64/f32"] = [@pl.col("f64") / @pl.col("f32")]
  m["cc/div/f64/f64"] = [@pl.col("f64") / @pl.col("f64")]
  m["cc/floordiv/i32/i32"] = [@pl.col("i32").floor_div(@pl.col("i32"))]
  m["cc/floordiv/i32/i64"] = [@pl.col("i32").floor_div(@pl.col("i64"))]
  m["cc/floordiv/i32/f32"] = [@pl.col("i32").floor_div(@pl.col("f32"))]
  m["cc/floordiv/i32/f64"] = [@pl.col("i32").floor_div(@pl.col("f64"))]
  m["cc/floordiv/i64/i32"] = [@pl.col("i64").floor_div(@pl.col("i32"))]
  m["cc/floordiv/i64/i64"] = [@pl.col("i64").floor_div(@pl.col("i64"))]
  m["cc/floordiv/i64/f32"] = [@pl.col("i64").floor_div(@pl.col("f32"))]
  m["cc/floordiv/i64/f64"] = [@pl.col("i64").floor_div(@pl.col("f64"))]
  m["cc/floordiv/f32/i32"] = [@pl.col("f32").floor_div(@pl.col("i32"))]
  m["cc/floordiv/f32/i64"] = [@pl.col("f32").floor_div(@pl.col("i64"))]
  m["cc/floordiv/f32/f32"] = [@pl.col("f32").floor_div(@pl.col("f32"))]
  m["cc/floordiv/f32/f64"] = [@pl.col("f32").floor_div(@pl.col("f64"))]
  m["cc/floordiv/f64/i32"] = [@pl.col("f64").floor_div(@pl.col("i32"))]
  m["cc/floordiv/f64/i64"] = [@pl.col("f64").floor_div(@pl.col("i64"))]
  m["cc/floordiv/f64/f32"] = [@pl.col("f64").floor_div(@pl.col("f32"))]
  m["cc/floordiv/f64/f64"] = [@pl.col("f64").floor_div(@pl.col("f64"))]
  m["cc/floordiv/n/i32"] = [@pl.col("n").floor_div(@pl.col("i32"))]
  m["cc/floordiv/i32/n"] = [@pl.col("i32").floor_div(@pl.col("n"))]
  m["cc/floordiv/n/f32"] = [@pl.col("n").floor_div(@pl.col("f32"))]
  m["cc/floordiv/f32/n"] = [@pl.col("f32").floor_div(@pl.col("n"))]
  m["cc/floordiv/n/n"] = [@pl.col("n").floor_div(@pl.col("n"))]
  m["cc/floordiv/n/i64"] = [@pl.col("n").floor_div(@pl.col("i64"))]
  m["cc/floordiv/f64/n"] = [@pl.col("f64").floor_div(@pl.col("n"))]
  m["cc/mod/i32/i32"] = [@pl.col("i32") % @pl.col("i32")]
  m["cc/mod/i32/i64"] = [@pl.col("i32") % @pl.col("i64")]
  m["cc/mod/i32/f32"] = [@pl.col("i32") % @pl.col("f32")]
  m["cc/mod/i32/f64"] = [@pl.col("i32") % @pl.col("f64")]
  m["cc/mod/i64/i32"] = [@pl.col("i64") % @pl.col("i32")]
  m["cc/mod/i64/i64"] = [@pl.col("i64") % @pl.col("i64")]
  m["cc/mod/i64/f32"] = [@pl.col("i64") % @pl.col("f32")]
  m["cc/mod/i64/f64"] = [@pl.col("i64") % @pl.col("f64")]
  m["cc/mod/f32/i32"] = [@pl.col("f32") % @pl.col("i32")]
  m["cc/mod/f32/i64"] = [@pl.col("f32") % @pl.col("i64")]
  m["cc/mod/f32/f32"] = [@pl.col("f32") % @pl.col("f32")]
  m["cc/mod/f32/f64"] = [@pl.col("f32") % @pl.col("f64")]
  m["cc/mod/f64/i32"] = [@pl.col("f64") % @pl.col("i32")]
  m["cc/mod/f64/i64"] = [@pl.col("f64") % @pl.col("i64")]
  m["cc/mod/f64/f32"] = [@pl.col("f64") % @pl.col("f32")]
  m["cc/mod/f64/f64"] = [@pl.col("f64") % @pl.col("f64")]
  m["cc/eq/i32/i32"] = [@pl.col("i32").eq(@pl.col("i32"))]
  m["cc/eq/i32/i64"] = [@pl.col("i32").eq(@pl.col("i64"))]
  m["cc/eq/i32/f32"] = [@pl.col("i32").eq(@pl.col("f32"))]
  m["cc/eq/i32/f64"] = [@pl.col("i32").eq(@pl.col("f64"))]
  m["cc/eq/i64/i32"] = [@pl.col("i64").eq(@pl.col("i32"))]
  m["cc/eq/i64/i64"] = [@pl.col("i64").eq(@pl.col("i64"))]
  m["cc/eq/i64/f32"] = [@pl.col("i64").eq(@pl.col("f32"))]
  m["cc/eq/i64/f64"] = [@pl.col("i64").eq(@pl.col("f64"))]
  m["cc/eq/f32/i32"] = [@pl.col("f32").eq(@pl.col("i32"))]
  m["cc/eq/f32/i64"] = [@pl.col("f32").eq(@pl.col("i64"))]
}

///|
fn golden_expr_cases_2(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cc/eq/f32/f32"] = [@pl.col("f32").eq(@pl.col("f32"))]
  m["cc/eq/f32/f64"] = [@pl.col("f32").eq(@pl.col("f64"))]
  m["cc/eq/f64/i32"] = [@pl.col("f64").eq(@pl.col("i32"))]
  m["cc/eq/f64/i64"] = [@pl.col("f64").eq(@pl.col("i64"))]
  m["cc/eq/f64/f32"] = [@pl.col("f64").eq(@pl.col("f32"))]
  m["cc/eq/f64/f64"] = [@pl.col("f64").eq(@pl.col("f64"))]
  m["cc/eq/n/i32"] = [@pl.col("n").eq(@pl.col("i32"))]
  m["cc/eq/i32/n"] = [@pl.col("i32").eq(@pl.col("n"))]
  m["cc/eq/n/f32"] = [@pl.col("n").eq(@pl.col("f32"))]
  m["cc/eq/f32/n"] = [@pl.col("f32").eq(@pl.col("n"))]
  m["cc/eq/n/n"] = [@pl.col("n").eq(@pl.col("n"))]
  m["cc/eq/n/i64"] = [@pl.col("n").eq(@pl.col("i64"))]
  m["cc/eq/f64/n"] = [@pl.col("f64").eq(@pl.col("n"))]
  m["cc/neq/i32/i32"] = [@pl.col("i32").neq(@pl.col("i32"))]
  m["cc/neq/i32/i64"] = [@pl.col("i32").neq(@pl.col("i64"))]
  m["cc/neq/i32/f32"] = [@pl.col("i32").neq(@pl.col("f32"))]
  m["cc/neq/i32/f64"] = [@pl.col("i32").neq(@pl.col("f64"))]
  m["cc/neq/i64/i32"] = [@pl.col("i64").neq(@pl.col("i32"))]
  m["cc/neq/i64/i64"] = [@pl.col("i64").neq(@pl.col("i64"))]
  m["cc/neq/i64/f32"] = [@pl.col("i64").neq(@pl.col("f32"))]
  m["cc/neq/i64/f64"] = [@pl.col("i64").neq(@pl.col("f64"))]
  m["cc/neq/f32/i32"] = [@pl.col("f32").neq(@pl.col("i32"))]
  m["cc/neq/f32/i64"] = [@pl.col("f32").neq(@pl.col("i64"))]
  m["cc/neq/f32/f32"] = [@pl.col("f32").neq(@pl.col("f32"))]
  m["cc/neq/f32/f64"] = [@pl.col("f32").neq(@pl.col("f64"))]
  m["cc/neq/f64/i32"] = [@pl.col("f64").neq(@pl.col("i32"))]
  m["cc/neq/f64/i64"] = [@pl.col("f64").neq(@pl.col("i64"))]
  m["cc/neq/f64/f32"] = [@pl.col("f64").neq(@pl.col("f32"))]
  m["cc/neq/f64/f64"] = [@pl.col("f64").neq(@pl.col("f64"))]
  m["cc/ge/i32/i32"] = [@pl.col("i32").ge(@pl.col("i32"))]
  m["cc/ge/i32/i64"] = [@pl.col("i32").ge(@pl.col("i64"))]
  m["cc/ge/i32/f32"] = [@pl.col("i32").ge(@pl.col("f32"))]
  m["cc/ge/i32/f64"] = [@pl.col("i32").ge(@pl.col("f64"))]
  m["cc/ge/i64/i32"] = [@pl.col("i64").ge(@pl.col("i32"))]
  m["cc/ge/i64/i64"] = [@pl.col("i64").ge(@pl.col("i64"))]
  m["cc/ge/i64/f32"] = [@pl.col("i64").ge(@pl.col("f32"))]
  m["cc/ge/i64/f64"] = [@pl.col("i64").ge(@pl.col("f64"))]
  m["cc/ge/f32/i32"] = [@pl.col("f32").ge(@pl.col("i32"))]
  m["cc/ge/f32/i64"] = [@pl.col("f32").ge(@pl.col("i64"))]
  m["cc/ge/f32/f32"] = [@pl.col("f32").ge(@pl.col("f32"))]
  m["cc/ge/f32/f64"] = [@pl.col("f32").ge(@pl.col("f64"))]
  m["cc/ge/f64/i32"] = [@pl.col("f64").ge(@pl.col("i32"))]
  m["cc/ge/f64/i64"] = [@pl.col("f64").ge(@pl.col("i64"))]
  m["cc/ge/f64/f32"] = [@pl.col("f64").ge(@pl.col("f32"))]
  m["cc/ge/f64/f64"] = [@pl.col("f64").ge(@pl.col("f64"))]
  m["cc/lt/i32/i32"] = [@pl.col("i32").lt(@pl.col("i32"))]
  m["cc/lt/i32/i64"] = [@pl.col("i32").lt(@pl.col("i64"))]
  m["cc/lt/i32/f32"] = [@pl.col("i32").lt(@pl.col("f32"))]
  m["cc/lt/i32/f64"] = [@pl.col("i32").lt(@pl.col("f64"))]
  m["cc/lt/i64/i32"] = [@pl.col("i64").lt(@pl.col("i32"))]
  m["cc/lt/i64/i64"] = [@pl.col("i64").lt(@pl.col("i64"))]
  m["cc/lt/i64/f32"] = [@pl.col("i64").lt(@pl.col("f32"))]
  m["cc/lt/i64/f64"] = [@pl.col("i64").lt(@pl.col("f64"))]
  m["cc/lt/f32/i32"] = [@pl.col("f32").lt(@pl.col("i32"))]
  m["cc/lt/f32/i64"] = [@pl.col("f32").lt(@pl.col("i64"))]
  m["cc/lt/f32/f32"] = [@pl.col("f32").lt(@pl.col("f32"))]
  m["cc/lt/f32/f64"] = [@pl.col("f32").lt(@pl.col("f64"))]
  m["cc/lt/f64/i32"] = [@pl.col("f64").lt(@pl.col("i32"))]
  m["cc/lt/f64/i64"] = [@pl.col("f64").lt(@pl.col("i64"))]
  m["cc/lt/f64/f32"] = [@pl.col("f64").lt(@pl.col("f32"))]
}

///|
fn golden_expr_cases_3(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cc/lt/f64/f64"] = [@pl.col("f64").lt(@pl.col("f64"))]
  m["cc/eq/s/s"] = [@pl.col("s").eq(@pl.col("s"))]
  m["cc/eq/b/b"] = [@pl.col("b").eq(@pl.col("b"))]
  m["cc/eq/d/d"] = [@pl.col("d").eq(@pl.col("d"))]
  m["cc/eq/dt/dt"] = [@pl.col("dt").eq(@pl.col("dt"))]
  m["cc/eq/d/dt"] = [@pl.col("d").eq(@pl.col("dt"))]
  m["cc/eq/dt/d"] = [@pl.col("dt").eq(@pl.col("d"))]
  m["cc/eq/s/b"] = [@pl.col("s").eq(@pl.col("b"))]
  m["cc/eq/b/s"] = [@pl.col("b").eq(@pl.col("s"))]
  m["cc/eq/b/i32"] = [@pl.col("b").eq(@pl.col("i32"))]
  m["cc/eq/b/f64"] = [@pl.col("b").eq(@pl.col("f64"))]
  m["cc/eq/d/i32"] = [@pl.col("d").eq(@pl.col("i32"))]
  m["cc/eq/dt/i64"] = [@pl.col("dt").eq(@pl.col("i64"))]
  m["cc/eq/n/s"] = [@pl.col("n").eq(@pl.col("s"))]
  m["cc/eq/s/n"] = [@pl.col("s").eq(@pl.col("n"))]
  m["cc/eq/n/b"] = [@pl.col("n").eq(@pl.col("b"))]
  m["cc/eq/s/i32"] = [@pl.col("s").eq(@pl.col("i32"))]
  m["cc/eq/i32/s"] = [@pl.col("i32").eq(@pl.col("s"))]
  m["cc/eq/b/d"] = [@pl.col("b").eq(@pl.col("d"))]
  m["cc/eq/s/d"] = [@pl.col("s").eq(@pl.col("d"))]
  m["cc/eq/s/dt"] = [@pl.col("s").eq(@pl.col("dt"))]
  m["cc/lt/s/s"] = [@pl.col("s").lt(@pl.col("s"))]
  m["cc/lt/b/b"] = [@pl.col("b").lt(@pl.col("b"))]
  m["cc/lt/d/d"] = [@pl.col("d").lt(@pl.col("d"))]
  m["cc/lt/dt/dt"] = [@pl.col("dt").lt(@pl.col("dt"))]
  m["cc/lt/d/dt"] = [@pl.col("d").lt(@pl.col("dt"))]
  m["cc/lt/dt/d"] = [@pl.col("dt").lt(@pl.col("d"))]
  m["cc/lt/s/b"] = [@pl.col("s").lt(@pl.col("b"))]
  m["cc/lt/b/s"] = [@pl.col("b").lt(@pl.col("s"))]
  m["cc/lt/b/i32"] = [@pl.col("b").lt(@pl.col("i32"))]
  m["cc/lt/b/f64"] = [@pl.col("b").lt(@pl.col("f64"))]
  m["cc/lt/d/i32"] = [@pl.col("d").lt(@pl.col("i32"))]
  m["cc/lt/dt/i64"] = [@pl.col("dt").lt(@pl.col("i64"))]
  m["cc/lt/n/s"] = [@pl.col("n").lt(@pl.col("s"))]
  m["cc/lt/s/n"] = [@pl.col("s").lt(@pl.col("n"))]
  m["cc/lt/n/b"] = [@pl.col("n").lt(@pl.col("b"))]
  m["cc/lt/s/i32"] = [@pl.col("s").lt(@pl.col("i32"))]
  m["cc/lt/i32/s"] = [@pl.col("i32").lt(@pl.col("s"))]
  m["cc/lt/b/d"] = [@pl.col("b").lt(@pl.col("d"))]
  m["cc/lt/s/d"] = [@pl.col("s").lt(@pl.col("d"))]
  m["cc/lt/s/dt"] = [@pl.col("s").lt(@pl.col("dt"))]
  m["cc/add/b/b"] = [@pl.col("b") + @pl.col("b")]
  m["cc/add/b/i32"] = [@pl.col("b") + @pl.col("i32")]
  m["cc/add/i32/b"] = [@pl.col("i32") + @pl.col("b")]
  m["cc/add/s/s"] = [@pl.col("s") + @pl.col("s")]
  m["cc/add/s/i32"] = [@pl.col("s") + @pl.col("i32")]
  m["cc/add/i64/s"] = [@pl.col("i64") + @pl.col("s")]
  m["cc/add/d/d"] = [@pl.col("d") + @pl.col("d")]
  m["cc/add/d/i32"] = [@pl.col("d") + @pl.col("i32")]
  m["cc/add/dt/dt"] = [@pl.col("dt") + @pl.col("dt")]
  m["cc/add/dt/i64"] = [@pl.col("dt") + @pl.col("i64")]
  m["cc/add/b/n"] = [@pl.col("b") + @pl.col("n")]
  m["cc/add/s/n"] = [@pl.col("s") + @pl.col("n")]
  m["cc/div/b/b"] = [@pl.col("b") / @pl.col("b")]
  m["cc/div/b/i32"] = [@pl.col("b") / @pl.col("i32")]
  m["cc/div/i32/b"] = [@pl.col("i32") / @pl.col("b")]
  m["cc/div/s/s"] = [@pl.col("s") / @pl.col("s")]
  m["cc/div/s/i32"] = [@pl.col("s") / @pl.col("i32")]
  m["cc/div/i64/s"] = [@pl.col("i64") / @pl.col("s")]
  m["cc/div/d/d"] = [@pl.col("d") / @pl.col("d")]
}

///|
fn golden_expr_cases_4(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cc/div/d/i32"] = [@pl.col("d") / @pl.col("i32")]
  m["cc/div/dt/dt"] = [@pl.col("dt") / @pl.col("dt")]
  m["cc/div/dt/i64"] = [@pl.col("dt") / @pl.col("i64")]
  m["cc/div/b/n"] = [@pl.col("b") / @pl.col("n")]
  m["cc/div/s/n"] = [@pl.col("s") / @pl.col("n")]
  m["cc/floordiv/b/b"] = [@pl.col("b").floor_div(@pl.col("b"))]
  m["cc/floordiv/b/i32"] = [@pl.col("b").floor_div(@pl.col("i32"))]
  m["cc/floordiv/i32/b"] = [@pl.col("i32").floor_div(@pl.col("b"))]
  m["cc/floordiv/s/s"] = [@pl.col("s").floor_div(@pl.col("s"))]
  m["cc/floordiv/s/i32"] = [@pl.col("s").floor_div(@pl.col("i32"))]
  m["cc/floordiv/i64/s"] = [@pl.col("i64").floor_div(@pl.col("s"))]
  m["cc/floordiv/d/d"] = [@pl.col("d").floor_div(@pl.col("d"))]
  m["cc/floordiv/d/i32"] = [@pl.col("d").floor_div(@pl.col("i32"))]
  m["cc/floordiv/dt/dt"] = [@pl.col("dt").floor_div(@pl.col("dt"))]
  m["cc/floordiv/dt/i64"] = [@pl.col("dt").floor_div(@pl.col("i64"))]
  m["cc/floordiv/b/n"] = [@pl.col("b").floor_div(@pl.col("n"))]
  m["cc/floordiv/s/n"] = [@pl.col("s").floor_div(@pl.col("n"))]
  m["cc/and/b/b"] = [@pl.col("b") & @pl.col("b")]
  m["cc/and/b/n"] = [@pl.col("b") & @pl.col("n")]
  m["cc/and/n/b"] = [@pl.col("n") & @pl.col("b")]
  m["cc/and/n/n"] = [@pl.col("n") & @pl.col("n")]
  m["cc/and/s/b"] = [@pl.col("s") & @pl.col("b")]
  m["cc/and/b/s"] = [@pl.col("b") & @pl.col("s")]
  m["cc/and/b/i32"] = [@pl.col("b") & @pl.col("i32")]
  m["cc/and/i32/b"] = [@pl.col("i32") & @pl.col("b")]
  m["cc/and/f64/b"] = [@pl.col("f64") & @pl.col("b")]
  m["cc/and/f64/f64"] = [@pl.col("f64") & @pl.col("f64")]
  m["cc/and/d/d"] = [@pl.col("d") & @pl.col("d")]
  m["cc/and/n/s"] = [@pl.col("n") & @pl.col("s")]
  m["cc/and/i32/i32"] = [@pl.col("i32") & @pl.col("i32")]
  m["cc/and/i64/i64"] = [@pl.col("i64") & @pl.col("i64")]
  m["cc/and/i32/i64"] = [@pl.col("i32") & @pl.col("i64")]
  m["cc/and/b/d"] = [@pl.col("b") & @pl.col("d")]
  m["cc/and/d/b"] = [@pl.col("d") & @pl.col("b")]
  m["cc/and/s/d"] = [@pl.col("s") & @pl.col("d")]
  m["cc/and/dt/b"] = [@pl.col("dt") & @pl.col("b")]
  m["cc/and/dt/dt"] = [@pl.col("dt") & @pl.col("dt")]
  m["cc/or/b/b"] = [@pl.col("b") | @pl.col("b")]
  m["cc/or/b/n"] = [@pl.col("b") | @pl.col("n")]
  m["cc/or/n/b"] = [@pl.col("n") | @pl.col("b")]
  m["cc/or/n/n"] = [@pl.col("n") | @pl.col("n")]
  m["cc/or/s/b"] = [@pl.col("s") | @pl.col("b")]
  m["cc/or/b/s"] = [@pl.col("b") | @pl.col("s")]
  m["cc/or/b/i32"] = [@pl.col("b") | @pl.col("i32")]
  m["cc/or/i32/b"] = [@pl.col("i32") | @pl.col("b")]
  m["cc/or/f64/b"] = [@pl.col("f64") | @pl.col("b")]
  m["cc/or/f64/f64"] = [@pl.col("f64") | @pl.col("f64")]
  m["cc/or/d/d"] = [@pl.col("d") | @pl.col("d")]
  m["cc/or/n/s"] = [@pl.col("n") | @pl.col("s")]
  m["cc/or/i32/i32"] = [@pl.col("i32") | @pl.col("i32")]
  m["cc/or/i64/i64"] = [@pl.col("i64") | @pl.col("i64")]
  m["cc/or/i32/i64"] = [@pl.col("i32") | @pl.col("i64")]
  m["cc/or/b/d"] = [@pl.col("b") | @pl.col("d")]
  m["cc/or/d/b"] = [@pl.col("d") | @pl.col("b")]
  m["cc/or/s/d"] = [@pl.col("s") | @pl.col("d")]
  m["cc/or/dt/b"] = [@pl.col("dt") | @pl.col("b")]
  m["cc/or/dt/dt"] = [@pl.col("dt") | @pl.col("dt")]
  m["cw/add/i32/1"] = [@pl.col("i32") + @pl.lit_int(1L)]
  m["cw/add/i32/3e9"] = [@pl.col("i32") + @pl.lit_int(3000000000L)]
  m["cw/add/i32/2^40"] = [@pl.col("i32") + @pl.lit_int(1099511627776L)]
}

///|
fn golden_expr_cases_5(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cw/add/i32/f1.5"] = [@pl.col("i32") + @pl.lit_float(1.5)]
  m["cw/add/i32/f1e300"] = [@pl.col("i32") + @pl.lit_float(1.0e300)]
  m["cw/add/i64/1"] = [@pl.col("i64") + @pl.lit_int(1L)]
  m["cw/add/i64/3e9"] = [@pl.col("i64") + @pl.lit_int(3000000000L)]
  m["cw/add/i64/2^40"] = [@pl.col("i64") + @pl.lit_int(1099511627776L)]
  m["cw/add/i64/f1.5"] = [@pl.col("i64") + @pl.lit_float(1.5)]
  m["cw/add/i64/f1e300"] = [@pl.col("i64") + @pl.lit_float(1.0e300)]
  m["cw/add/f32/1"] = [@pl.col("f32") + @pl.lit_int(1L)]
  m["cw/add/f32/3e9"] = [@pl.col("f32") + @pl.lit_int(3000000000L)]
  m["cw/add/f32/2^40"] = [@pl.col("f32") + @pl.lit_int(1099511627776L)]
  m["cw/add/f32/f1.5"] = [@pl.col("f32") + @pl.lit_float(1.5)]
  m["cw/add/f32/f1e300"] = [@pl.col("f32") + @pl.lit_float(1.0e300)]
  m["cw/add/f64/1"] = [@pl.col("f64") + @pl.lit_int(1L)]
  m["cw/add/f64/3e9"] = [@pl.col("f64") + @pl.lit_int(3000000000L)]
  m["cw/add/f64/2^40"] = [@pl.col("f64") + @pl.lit_int(1099511627776L)]
  m["cw/add/f64/f1.5"] = [@pl.col("f64") + @pl.lit_float(1.5)]
  m["cw/add/f64/f1e300"] = [@pl.col("f64") + @pl.lit_float(1.0e300)]
  m["cw/sub/i32/1"] = [@pl.col("i32") - @pl.lit_int(1L)]
  m["cw/sub/i32/3e9"] = [@pl.col("i32") - @pl.lit_int(3000000000L)]
  m["cw/sub/i32/f1.5"] = [@pl.col("i32") - @pl.lit_float(1.5)]
  m["cw/sub/f32/1"] = [@pl.col("f32") - @pl.lit_int(1L)]
  m["cw/sub/f32/3e9"] = [@pl.col("f32") - @pl.lit_int(3000000000L)]
  m["cw/sub/f32/f1.5"] = [@pl.col("f32") - @pl.lit_float(1.5)]
  m["cw/mul/i32/1"] = [@pl.col("i32") * @pl.lit_int(1L)]
  m["cw/mul/i32/3e9"] = [@pl.col("i32") * @pl.lit_int(3000000000L)]
  m["cw/mul/i32/f1.5"] = [@pl.col("i32") * @pl.lit_float(1.5)]
  m["cw/mul/i32/f1e300"] = [@pl.col("i32") * @pl.lit_float(1.0e300)]
  m["cw/mul/i64/1"] = [@pl.col("i64") * @pl.lit_int(1L)]
  m["cw/mul/i64/3e9"] = [@pl.col("i64") * @pl.lit_int(3000000000L)]
  m["cw/mul/i64/f1.5"] = [@pl.col("i64") * @pl.lit_float(1.5)]
  m["cw/mul/i64/f1e300"] = [@pl.col("i64") * @pl.lit_float(1.0e300)]
  m["cw/mul/f32/1"] = [@pl.col("f32") * @pl.lit_int(1L)]
  m["cw/mul/f32/3e9"] = [@pl.col("f32") * @pl.lit_int(3000000000L)]
  m["cw/mul/f32/f1.5"] = [@pl.col("f32") * @pl.lit_float(1.5)]
  m["cw/mul/f32/f1e300"] = [@pl.col("f32") * @pl.lit_float(1.0e300)]
  m["cw/mul/f64/1"] = [@pl.col("f64") * @pl.lit_int(1L)]
  m["cw/mul/f64/3e9"] = [@pl.col("f64") * @pl.lit_int(3000000000L)]
  m["cw/mul/f64/f1.5"] = [@pl.col("f64") * @pl.lit_float(1.5)]
  m["cw/mul/f64/f1e300"] = [@pl.col("f64") * @pl.lit_float(1.0e300)]
  m["cw/div/i32/1"] = [@pl.col("i32") / @pl.lit_int(1L)]
  m["cw/div/i32/3e9"] = [@pl.col("i32") / @pl.lit_int(3000000000L)]
  m["cw/div/i32/f1.5"] = [@pl.col("i32") / @pl.lit_float(1.5)]
  m["cw/div/i32/f1e300"] = [@pl.col("i32") / @pl.lit_float(1.0e300)]
  m["cw/div/i64/1"] = [@pl.col("i64") / @pl.lit_int(1L)]
  m["cw/div/i64/3e9"] = [@pl.col("i64") / @pl.lit_int(3000000000L)]
  m["cw/div/i64/f1.5"] = [@pl.col("i64") / @pl.lit_float(1.5)]
  m["cw/div/i64/f1e300"] = [@pl.col("i64") / @pl.lit_float(1.0e300)]
  m["cw/div/f32/1"] = [@pl.col("f32") / @pl.lit_int(1L)]
  m["cw/div/f32/3e9"] = [@pl.col("f32") / @pl.lit_int(3000000000L)]
  m["cw/div/f32/f1.5"] = [@pl.col("f32") / @pl.lit_float(1.5)]
  m["cw/div/f32/f1e300"] = [@pl.col("f32") / @pl.lit_float(1.0e300)]
  m["cw/div/f64/1"] = [@pl.col("f64") / @pl.lit_int(1L)]
  m["cw/div/f64/3e9"] = [@pl.col("f64") / @pl.lit_int(3000000000L)]
  m["cw/div/f64/f1.5"] = [@pl.col("f64") / @pl.lit_float(1.5)]
  m["cw/div/f64/f1e300"] = [@pl.col("f64") / @pl.lit_float(1.0e300)]
  m["cw/floordiv/i32/1"] = [@pl.col("i32").floor_div(@pl.lit_int(1L))]
  m["cw/floordiv/i32/3e9"] = [
    @pl.col("i32").floor_div(@pl.lit_int(3000000000L)),
  ]
  m["cw/floordiv/i32/2^40"] = [
    @pl.col("i32").floor_div(@pl.lit_int(1099511627776L)),
  ]
  m["cw/floordiv/i32/f1.5"] = [@pl.col("i32").floor_div(@pl.lit_float(1.5))]
  m["cw/floordiv/i64/1"] = [@pl.col("i64").floor_div(@pl.lit_int(1L))]
}

///|
fn golden_expr_cases_6(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cw/floordiv/i64/3e9"] = [
    @pl.col("i64").floor_div(@pl.lit_int(3000000000L)),
  ]
  m["cw/floordiv/i64/2^40"] = [
    @pl.col("i64").floor_div(@pl.lit_int(1099511627776L)),
  ]
  m["cw/floordiv/i64/f1.5"] = [@pl.col("i64").floor_div(@pl.lit_float(1.5))]
  m["cw/floordiv/f32/1"] = [@pl.col("f32").floor_div(@pl.lit_int(1L))]
  m["cw/floordiv/f32/3e9"] = [
    @pl.col("f32").floor_div(@pl.lit_int(3000000000L)),
  ]
  m["cw/floordiv/f32/2^40"] = [
    @pl.col("f32").floor_div(@pl.lit_int(1099511627776L)),
  ]
  m["cw/floordiv/f32/f1.5"] = [@pl.col("f32").floor_div(@pl.lit_float(1.5))]
  m["cw/floordiv/f64/1"] = [@pl.col("f64").floor_div(@pl.lit_int(1L))]
  m["cw/floordiv/f64/3e9"] = [
    @pl.col("f64").floor_div(@pl.lit_int(3000000000L)),
  ]
  m["cw/floordiv/f64/2^40"] = [
    @pl.col("f64").floor_div(@pl.lit_int(1099511627776L)),
  ]
  m["cw/floordiv/f64/f1.5"] = [@pl.col("f64").floor_div(@pl.lit_float(1.5))]
  m["cw/mod/i32/1"] = [@pl.col("i32") % @pl.lit_int(1L)]
  m["cw/mod/i32/3e9"] = [@pl.col("i32") % @pl.lit_int(3000000000L)]
  m["cw/mod/i32/f1.5"] = [@pl.col("i32") % @pl.lit_float(1.5)]
  m["cw/mod/f32/1"] = [@pl.col("f32") % @pl.lit_int(1L)]
  m["cw/mod/f32/3e9"] = [@pl.col("f32") % @pl.lit_int(3000000000L)]
  m["cw/mod/f32/f1.5"] = [@pl.col("f32") % @pl.lit_float(1.5)]
  m["cw/eq/i32/1"] = [@pl.col("i32").eq(@pl.lit_int(1L))]
  m["cw/eq/i32/3e9"] = [@pl.col("i32").eq(@pl.lit_int(3000000000L))]
  m["cw/eq/i32/2^40"] = [@pl.col("i32").eq(@pl.lit_int(1099511627776L))]
  m["cw/eq/i32/f1.5"] = [@pl.col("i32").eq(@pl.lit_float(1.5))]
  m["cw/eq/i64/1"] = [@pl.col("i64").eq(@pl.lit_int(1L))]
  m["cw/eq/i64/3e9"] = [@pl.col("i64").eq(@pl.lit_int(3000000000L))]
  m["cw/eq/i64/2^40"] = [@pl.col("i64").eq(@pl.lit_int(1099511627776L))]
  m["cw/eq/i64/f1.5"] = [@pl.col("i64").eq(@pl.lit_float(1.5))]
  m["cw/eq/f32/1"] = [@pl.col("f32").eq(@pl.lit_int(1L))]
  m["cw/eq/f32/3e9"] = [@pl.col("f32").eq(@pl.lit_int(3000000000L))]
  m["cw/eq/f32/2^40"] = [@pl.col("f32").eq(@pl.lit_int(1099511627776L))]
  m["cw/eq/f32/f1.5"] = [@pl.col("f32").eq(@pl.lit_float(1.5))]
  m["cw/eq/f64/1"] = [@pl.col("f64").eq(@pl.lit_int(1L))]
  m["cw/eq/f64/3e9"] = [@pl.col("f64").eq(@pl.lit_int(3000000000L))]
  m["cw/eq/f64/2^40"] = [@pl.col("f64").eq(@pl.lit_int(1099511627776L))]
  m["cw/eq/f64/f1.5"] = [@pl.col("f64").eq(@pl.lit_float(1.5))]
  m["cw/neq/i32/1"] = [@pl.col("i32").neq(@pl.lit_int(1L))]
  m["cw/neq/i32/3e9"] = [@pl.col("i32").neq(@pl.lit_int(3000000000L))]
  m["cw/neq/i32/f1.5"] = [@pl.col("i32").neq(@pl.lit_float(1.5))]
  m["cw/neq/f32/1"] = [@pl.col("f32").neq(@pl.lit_int(1L))]
  m["cw/neq/f32/3e9"] = [@pl.col("f32").neq(@pl.lit_int(3000000000L))]
  m["cw/neq/f32/f1.5"] = [@pl.col("f32").neq(@pl.lit_float(1.5))]
  m["cw/gt/i32/1"] = [@pl.col("i32").gt(@pl.lit_int(1L))]
  m["cw/gt/i32/3e9"] = [@pl.col("i32").gt(@pl.lit_int(3000000000L))]
  m["cw/gt/i32/2^40"] = [@pl.col("i32").gt(@pl.lit_int(1099511627776L))]
  m["cw/gt/i32/f1.5"] = [@pl.col("i32").gt(@pl.lit_float(1.5))]
  m["cw/gt/i64/1"] = [@pl.col("i64").gt(@pl.lit_int(1L))]
  m["cw/gt/i64/3e9"] = [@pl.col("i64").gt(@pl.lit_int(3000000000L))]
  m["cw/gt/i64/2^40"] = [@pl.col("i64").gt(@pl.lit_int(1099511627776L))]
  m["cw/gt/i64/f1.5"] = [@pl.col("i64").gt(@pl.lit_float(1.5))]
  m["cw/gt/f32/1"] = [@pl.col("f32").gt(@pl.lit_int(1L))]
  m["cw/gt/f32/3e9"] = [@pl.col("f32").gt(@pl.lit_int(3000000000L))]
  m["cw/gt/f32/2^40"] = [@pl.col("f32").gt(@pl.lit_int(1099511627776L))]
  m["cw/gt/f32/f1.5"] = [@pl.col("f32").gt(@pl.lit_float(1.5))]
  m["cw/gt/f64/1"] = [@pl.col("f64").gt(@pl.lit_int(1L))]
  m["cw/gt/f64/3e9"] = [@pl.col("f64").gt(@pl.lit_int(3000000000L))]
  m["cw/gt/f64/2^40"] = [@pl.col("f64").gt(@pl.lit_int(1099511627776L))]
  m["cw/gt/f64/f1.5"] = [@pl.col("f64").gt(@pl.lit_float(1.5))]
  m["cw/ge/i32/1"] = [@pl.col("i32").ge(@pl.lit_int(1L))]
  m["cw/ge/i32/3e9"] = [@pl.col("i32").ge(@pl.lit_int(3000000000L))]
  m["cw/ge/i32/f1.5"] = [@pl.col("i32").ge(@pl.lit_float(1.5))]
  m["cw/ge/f32/1"] = [@pl.col("f32").ge(@pl.lit_int(1L))]
  m["cw/ge/f32/3e9"] = [@pl.col("f32").ge(@pl.lit_int(3000000000L))]
}

///|
fn golden_expr_cases_7(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cw/ge/f32/f1.5"] = [@pl.col("f32").ge(@pl.lit_float(1.5))]
  m["cw/lt/i32/1"] = [@pl.col("i32").lt(@pl.lit_int(1L))]
  m["cw/lt/i32/3e9"] = [@pl.col("i32").lt(@pl.lit_int(3000000000L))]
  m["cw/lt/i32/f1.5"] = [@pl.col("i32").lt(@pl.lit_float(1.5))]
  m["cw/lt/i32/f1e300"] = [@pl.col("i32").lt(@pl.lit_float(1.0e300))]
  m["cw/lt/i64/1"] = [@pl.col("i64").lt(@pl.lit_int(1L))]
  m["cw/lt/i64/3e9"] = [@pl.col("i64").lt(@pl.lit_int(3000000000L))]
  m["cw/lt/i64/f1.5"] = [@pl.col("i64").lt(@pl.lit_float(1.5))]
  m["cw/lt/i64/f1e300"] = [@pl.col("i64").lt(@pl.lit_float(1.0e300))]
  m["cw/lt/f32/1"] = [@pl.col("f32").lt(@pl.lit_int(1L))]
  m["cw/lt/f32/3e9"] = [@pl.col("f32").lt(@pl.lit_int(3000000000L))]
  m["cw/lt/f32/f1.5"] = [@pl.col("f32").lt(@pl.lit_float(1.5))]
  m["cw/lt/f32/f1e300"] = [@pl.col("f32").lt(@pl.lit_float(1.0e300))]
  m["cw/lt/f64/1"] = [@pl.col("f64").lt(@pl.lit_int(1L))]
  m["cw/lt/f64/3e9"] = [@pl.col("f64").lt(@pl.lit_int(3000000000L))]
  m["cw/lt/f64/f1.5"] = [@pl.col("f64").lt(@pl.lit_float(1.5))]
  m["cw/lt/f64/f1e300"] = [@pl.col("f64").lt(@pl.lit_float(1.0e300))]
  m["cw/le/i32/1"] = [@pl.col("i32").le(@pl.lit_int(1L))]
  m["cw/le/i32/3e9"] = [@pl.col("i32").le(@pl.lit_int(3000000000L))]
  m["cw/le/i32/f1.5"] = [@pl.col("i32").le(@pl.lit_float(1.5))]
  m["cw/le/i64/1"] = [@pl.col("i64").le(@pl.lit_int(1L))]
  m["cw/le/i64/3e9"] = [@pl.col("i64").le(@pl.lit_int(3000000000L))]
  m["cw/le/i64/f1.5"] = [@pl.col("i64").le(@pl.lit_float(1.5))]
  m["cw/le/f32/1"] = [@pl.col("f32").le(@pl.lit_int(1L))]
  m["cw/le/f32/3e9"] = [@pl.col("f32").le(@pl.lit_int(3000000000L))]
  m["cw/le/f32/f1.5"] = [@pl.col("f32").le(@pl.lit_float(1.5))]
  m["cw/le/f64/1"] = [@pl.col("f64").le(@pl.lit_int(1L))]
  m["cw/le/f64/3e9"] = [@pl.col("f64").le(@pl.lit_int(3000000000L))]
  m["cw/le/f64/f1.5"] = [@pl.col("f64").le(@pl.lit_float(1.5))]
  m["cw/add/i32/i32max"] = [@pl.col("i32") + @pl.lit_int(2147483647L)]
  m["cw/add/i32/i32max+1"] = [@pl.col("i32") + @pl.lit_int(2147483648L)]
  m["cw/add/i64/i32max"] = [@pl.col("i64") + @pl.lit_int(2147483647L)]
  m["cw/add/i64/i32max+1"] = [@pl.col("i64") + @pl.lit_int(2147483648L)]
  m["cw/add/f32/i32max"] = [@pl.col("f32") + @pl.lit_int(2147483647L)]
  m["cw/add/f32/i32max+1"] = [@pl.col("f32") + @pl.lit_int(2147483648L)]
  m["cw/eq/i32/i32max"] = [@pl.col("i32").eq(@pl.lit_int(2147483647L))]
  m["cw/eq/i32/i32max+1"] = [@pl.col("i32").eq(@pl.lit_int(2147483648L))]
  m["cw/eq/i64/i32max"] = [@pl.col("i64").eq(@pl.lit_int(2147483647L))]
  m["cw/eq/i64/i32max+1"] = [@pl.col("i64").eq(@pl.lit_int(2147483648L))]
  m["cw/eq/f32/i32max"] = [@pl.col("f32").eq(@pl.lit_int(2147483647L))]
  m["cw/eq/f32/i32max+1"] = [@pl.col("f32").eq(@pl.lit_int(2147483648L))]
  m["cw/lt/i32/i32max"] = [@pl.col("i32").lt(@pl.lit_int(2147483647L))]
  m["cw/lt/i32/i32max+1"] = [@pl.col("i32").lt(@pl.lit_int(2147483648L))]
  m["cw/lt/i64/i32max"] = [@pl.col("i64").lt(@pl.lit_int(2147483647L))]
  m["cw/lt/i64/i32max+1"] = [@pl.col("i64").lt(@pl.lit_int(2147483648L))]
  m["cw/lt/f32/i32max"] = [@pl.col("f32").lt(@pl.lit_int(2147483647L))]
  m["cw/lt/f32/i32max+1"] = [@pl.col("f32").lt(@pl.lit_int(2147483648L))]
  m["cw/add/i32/0"] = [@pl.col("i32") + @pl.lit_int(0L)]
  m["cw/add/i32/-3e9"] = [@pl.col("i32") + @pl.lit_int(-3000000000L)]
  m["cw/add/i32/i32min"] = [@pl.col("i32") + @pl.lit_int(-2147483648L)]
  m["cw/add/i32/i32min-1"] = [@pl.col("i32") + @pl.lit_int(-2147483649L)]
  m["cw/add/i32/i64max"] = [@pl.col("i32") + @pl.lit_int(9223372036854775807L)]
  m["cw/add/i32/i64min"] = [
    @pl.col("i32") + @pl.lit_int(-9223372036854775807L - 1L),
  ]
  m["cw/add/i32/f0.0"] = [@pl.col("i32") + @pl.lit_float(0.0)]
  m["cw/add/i32/f-0.0"] = [@pl.col("i32") + @pl.lit_float(-0.0)]
  m["cw/add/i32/fnan"] = [@pl.col("i32") + @pl.lit_float(0.0 / 0.0)]
  m["cw/add/i32/finf"] = [@pl.col("i32") + @pl.lit_float(1.0 / 0.0)]
  m["cw/add/i32/f-1.5"] = [@pl.col("i32") + @pl.lit_float(-1.5)]
  m["cw/add/f32/-3e9"] = [@pl.col("f32") + @pl.lit_int(-3000000000L)]
  m["cw/add/f32/i32min"] = [@pl.col("f32") + @pl.lit_int(-2147483648L)]
}

///|
fn golden_expr_cases_8(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cw/add/f32/i32min-1"] = [@pl.col("f32") + @pl.lit_int(-2147483649L)]
  m["cw/add/f32/i64max"] = [@pl.col("f32") + @pl.lit_int(9223372036854775807L)]
  m["cw/add/f32/i64min"] = [
    @pl.col("f32") + @pl.lit_int(-9223372036854775807L - 1L),
  ]
  m["cw/add/f32/f-0.0"] = [@pl.col("f32") + @pl.lit_float(-0.0)]
  m["cw/add/f32/fnan"] = [@pl.col("f32") + @pl.lit_float(0.0 / 0.0)]
  m["cw/add/f32/finf"] = [@pl.col("f32") + @pl.lit_float(1.0 / 0.0)]
  m["cw/add/f32/f-1.5"] = [@pl.col("f32") + @pl.lit_float(-1.5)]
  m["cw/div/i32/0"] = [@pl.col("i32") / @pl.lit_int(0L)]
  m["cw/div/i32/-3e9"] = [@pl.col("i32") / @pl.lit_int(-3000000000L)]
  m["cw/div/i32/f0.0"] = [@pl.col("i32") / @pl.lit_float(0.0)]
  m["cw/div/i32/fnan"] = [@pl.col("i32") / @pl.lit_float(0.0 / 0.0)]
  m["cw/div/f32/0"] = [@pl.col("f32") / @pl.lit_int(0L)]
  m["cw/div/f32/-3e9"] = [@pl.col("f32") / @pl.lit_int(-3000000000L)]
  m["cw/div/f32/f0.0"] = [@pl.col("f32") / @pl.lit_float(0.0)]
  m["cw/div/f32/fnan"] = [@pl.col("f32") / @pl.lit_float(0.0 / 0.0)]
  m["cw/eq/i32/0"] = [@pl.col("i32").eq(@pl.lit_int(0L))]
  m["cw/eq/i32/-3e9"] = [@pl.col("i32").eq(@pl.lit_int(-3000000000L))]
  m["cw/eq/i32/i32min"] = [@pl.col("i32").eq(@pl.lit_int(-2147483648L))]
  m["cw/eq/i32/i32min-1"] = [@pl.col("i32").eq(@pl.lit_int(-2147483649L))]
  m["cw/eq/i32/i64max"] = [@pl.col("i32").eq(@pl.lit_int(9223372036854775807L))]
  m["cw/eq/i32/i64min"] = [
    @pl.col("i32").eq(@pl.lit_int(-9223372036854775807L - 1L)),
  ]
  m["cw/eq/i32/f0.0"] = [@pl.col("i32").eq(@pl.lit_float(0.0))]
  m["cw/eq/i32/f-0.0"] = [@pl.col("i32").eq(@pl.lit_float(-0.0))]
  m["cw/eq/i32/fnan"] = [@pl.col("i32").eq(@pl.lit_float(0.0 / 0.0))]
  m["cw/eq/i32/finf"] = [@pl.col("i32").eq(@pl.lit_float(1.0 / 0.0))]
  m["cw/eq/i32/f-1.5"] = [@pl.col("i32").eq(@pl.lit_float(-1.5))]
  m["cw/eq/f32/0"] = [@pl.col("f32").eq(@pl.lit_int(0L))]
  m["cw/eq/f32/-3e9"] = [@pl.col("f32").eq(@pl.lit_int(-3000000000L))]
  m["cw/eq/f32/i32min"] = [@pl.col("f32").eq(@pl.lit_int(-2147483648L))]
  m["cw/eq/f32/i32min-1"] = [@pl.col("f32").eq(@pl.lit_int(-2147483649L))]
  m["cw/eq/f32/i64max"] = [@pl.col("f32").eq(@pl.lit_int(9223372036854775807L))]
  m["cw/eq/f32/i64min"] = [
    @pl.col("f32").eq(@pl.lit_int(-9223372036854775807L - 1L)),
  ]
  m["cw/eq/f32/f0.0"] = [@pl.col("f32").eq(@pl.lit_float(0.0))]
  m["cw/eq/f32/f-0.0"] = [@pl.col("f32").eq(@pl.lit_float(-0.0))]
  m["cw/eq/f32/fnan"] = [@pl.col("f32").eq(@pl.lit_float(0.0 / 0.0))]
  m["cw/eq/f32/finf"] = [@pl.col("f32").eq(@pl.lit_float(1.0 / 0.0))]
  m["cw/eq/f32/f-1.5"] = [@pl.col("f32").eq(@pl.lit_float(-1.5))]
  m["wc/sub/1/i32"] = [@pl.lit_int(1L) - @pl.col("i32")]
  m["wc/sub/3e9/i32"] = [@pl.lit_int(3000000000L) - @pl.col("i32")]
  m["wc/sub/f1.5/i32"] = [@pl.lit_float(1.5) - @pl.col("i32")]
  m["wc/sub/1/i64"] = [@pl.lit_int(1L) - @pl.col("i64")]
  m["wc/sub/3e9/i64"] = [@pl.lit_int(3000000000L) - @pl.col("i64")]
  m["wc/sub/f1.5/i64"] = [@pl.lit_float(1.5) - @pl.col("i64")]
  m["wc/sub/1/f32"] = [@pl.lit_int(1L) - @pl.col("f32")]
  m["wc/sub/3e9/f32"] = [@pl.lit_int(3000000000L) - @pl.col("f32")]
  m["wc/sub/f1.5/f32"] = [@pl.lit_float(1.5) - @pl.col("f32")]
  m["wc/sub/1/f64"] = [@pl.lit_int(1L) - @pl.col("f64")]
  m["wc/sub/3e9/f64"] = [@pl.lit_int(3000000000L) - @pl.col("f64")]
  m["wc/sub/f1.5/f64"] = [@pl.lit_float(1.5) - @pl.col("f64")]
  m["wc/div/1/i32"] = [@pl.lit_int(1L) / @pl.col("i32")]
  m["wc/div/3e9/i32"] = [@pl.lit_int(3000000000L) / @pl.col("i32")]
  m["wc/div/f1.5/i32"] = [@pl.lit_float(1.5) / @pl.col("i32")]
  m["wc/div/1/i64"] = [@pl.lit_int(1L) / @pl.col("i64")]
  m["wc/div/3e9/i64"] = [@pl.lit_int(3000000000L) / @pl.col("i64")]
  m["wc/div/f1.5/i64"] = [@pl.lit_float(1.5) / @pl.col("i64")]
  m["wc/div/1/f32"] = [@pl.lit_int(1L) / @pl.col("f32")]
  m["wc/div/3e9/f32"] = [@pl.lit_int(3000000000L) / @pl.col("f32")]
  m["wc/div/f1.5/f32"] = [@pl.lit_float(1.5) / @pl.col("f32")]
  m["wc/div/1/f64"] = [@pl.lit_int(1L) / @pl.col("f64")]
  m["wc/div/3e9/f64"] = [@pl.lit_int(3000000000L) / @pl.col("f64")]
}

///|
fn golden_expr_cases_9(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["wc/div/f1.5/f64"] = [@pl.lit_float(1.5) / @pl.col("f64")]
  m["wc/floordiv/1/i32"] = [@pl.lit_int(1L).floor_div(@pl.col("i32"))]
  m["wc/floordiv/3e9/i32"] = [
    @pl.lit_int(3000000000L).floor_div(@pl.col("i32")),
  ]
  m["wc/floordiv/f1.5/i32"] = [@pl.lit_float(1.5).floor_div(@pl.col("i32"))]
  m["wc/floordiv/1/i64"] = [@pl.lit_int(1L).floor_div(@pl.col("i64"))]
  m["wc/floordiv/3e9/i64"] = [
    @pl.lit_int(3000000000L).floor_div(@pl.col("i64")),
  ]
  m["wc/floordiv/f1.5/i64"] = [@pl.lit_float(1.5).floor_div(@pl.col("i64"))]
  m["wc/floordiv/1/f32"] = [@pl.lit_int(1L).floor_div(@pl.col("f32"))]
  m["wc/floordiv/3e9/f32"] = [
    @pl.lit_int(3000000000L).floor_div(@pl.col("f32")),
  ]
  m["wc/floordiv/f1.5/f32"] = [@pl.lit_float(1.5).floor_div(@pl.col("f32"))]
  m["wc/floordiv/1/f64"] = [@pl.lit_int(1L).floor_div(@pl.col("f64"))]
  m["wc/floordiv/3e9/f64"] = [
    @pl.lit_int(3000000000L).floor_div(@pl.col("f64")),
  ]
  m["wc/floordiv/f1.5/f64"] = [@pl.lit_float(1.5).floor_div(@pl.col("f64"))]
  m["wc/lt/1/i32"] = [@pl.lit_int(1L).lt(@pl.col("i32"))]
  m["wc/lt/3e9/i32"] = [@pl.lit_int(3000000000L).lt(@pl.col("i32"))]
  m["wc/lt/f1.5/i32"] = [@pl.lit_float(1.5).lt(@pl.col("i32"))]
  m["wc/lt/1/i64"] = [@pl.lit_int(1L).lt(@pl.col("i64"))]
  m["wc/lt/3e9/i64"] = [@pl.lit_int(3000000000L).lt(@pl.col("i64"))]
  m["wc/lt/f1.5/i64"] = [@pl.lit_float(1.5).lt(@pl.col("i64"))]
  m["wc/lt/1/f32"] = [@pl.lit_int(1L).lt(@pl.col("f32"))]
  m["wc/lt/3e9/f32"] = [@pl.lit_int(3000000000L).lt(@pl.col("f32"))]
  m["wc/lt/f1.5/f32"] = [@pl.lit_float(1.5).lt(@pl.col("f32"))]
  m["wc/lt/1/f64"] = [@pl.lit_int(1L).lt(@pl.col("f64"))]
  m["wc/lt/3e9/f64"] = [@pl.lit_int(3000000000L).lt(@pl.col("f64"))]
  m["wc/lt/f1.5/f64"] = [@pl.lit_float(1.5).lt(@pl.col("f64"))]
  m["cw/eq/b/1"] = [@pl.col("b").eq(@pl.lit_int(1L))]
  m["cw/eq/b/3e9"] = [@pl.col("b").eq(@pl.lit_int(3000000000L))]
  m["cw/eq/b/f1.5"] = [@pl.col("b").eq(@pl.lit_float(1.5))]
  m["cw/eq/s/1"] = [@pl.col("s").eq(@pl.lit_int(1L))]
  m["cw/eq/s/3e9"] = [@pl.col("s").eq(@pl.lit_int(3000000000L))]
  m["cw/eq/s/f1.5"] = [@pl.col("s").eq(@pl.lit_float(1.5))]
  m["cw/eq/d/1"] = [@pl.col("d").eq(@pl.lit_int(1L))]
  m["cw/eq/d/3e9"] = [@pl.col("d").eq(@pl.lit_int(3000000000L))]
  m["cw/eq/d/f1.5"] = [@pl.col("d").eq(@pl.lit_float(1.5))]
  m["cw/eq/dt/1"] = [@pl.col("dt").eq(@pl.lit_int(1L))]
  m["cw/eq/dt/3e9"] = [@pl.col("dt").eq(@pl.lit_int(3000000000L))]
  m["cw/eq/dt/f1.5"] = [@pl.col("dt").eq(@pl.lit_float(1.5))]
  m["cw/eq/n/1"] = [@pl.col("n").eq(@pl.lit_int(1L))]
  m["cw/eq/n/3e9"] = [@pl.col("n").eq(@pl.lit_int(3000000000L))]
  m["cw/eq/n/f1.5"] = [@pl.col("n").eq(@pl.lit_float(1.5))]
  m["cw/lt/b/1"] = [@pl.col("b").lt(@pl.lit_int(1L))]
  m["cw/lt/b/3e9"] = [@pl.col("b").lt(@pl.lit_int(3000000000L))]
  m["cw/lt/b/f1.5"] = [@pl.col("b").lt(@pl.lit_float(1.5))]
  m["cw/lt/s/1"] = [@pl.col("s").lt(@pl.lit_int(1L))]
  m["cw/lt/s/3e9"] = [@pl.col("s").lt(@pl.lit_int(3000000000L))]
  m["cw/lt/s/f1.5"] = [@pl.col("s").lt(@pl.lit_float(1.5))]
  m["cw/lt/d/1"] = [@pl.col("d").lt(@pl.lit_int(1L))]
  m["cw/lt/d/3e9"] = [@pl.col("d").lt(@pl.lit_int(3000000000L))]
  m["cw/lt/d/f1.5"] = [@pl.col("d").lt(@pl.lit_float(1.5))]
  m["cw/lt/dt/1"] = [@pl.col("dt").lt(@pl.lit_int(1L))]
  m["cw/lt/dt/3e9"] = [@pl.col("dt").lt(@pl.lit_int(3000000000L))]
  m["cw/lt/dt/f1.5"] = [@pl.col("dt").lt(@pl.lit_float(1.5))]
  m["cw/lt/n/1"] = [@pl.col("n").lt(@pl.lit_int(1L))]
  m["cw/lt/n/3e9"] = [@pl.col("n").lt(@pl.lit_int(3000000000L))]
  m["cw/lt/n/f1.5"] = [@pl.col("n").lt(@pl.lit_float(1.5))]
  m["cw/add/b/1"] = [@pl.col("b") + @pl.lit_int(1L)]
  m["cw/add/b/3e9"] = [@pl.col("b") + @pl.lit_int(3000000000L)]
  m["cw/add/b/f1.5"] = [@pl.col("b") + @pl.lit_float(1.5)]
  m["cw/add/s/1"] = [@pl.col("s") + @pl.lit_int(1L)]
  m["cw/add/s/3e9"] = [@pl.col("s") + @pl.lit_int(3000000000L)]
}

///|
fn golden_expr_cases_10(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cw/add/s/f1.5"] = [@pl.col("s") + @pl.lit_float(1.5)]
  m["cw/add/d/1"] = [@pl.col("d") + @pl.lit_int(1L)]
  m["cw/add/d/3e9"] = [@pl.col("d") + @pl.lit_int(3000000000L)]
  m["cw/add/d/f1.5"] = [@pl.col("d") + @pl.lit_float(1.5)]
  m["cw/add/dt/1"] = [@pl.col("dt") + @pl.lit_int(1L)]
  m["cw/add/dt/3e9"] = [@pl.col("dt") + @pl.lit_int(3000000000L)]
  m["cw/add/dt/f1.5"] = [@pl.col("dt") + @pl.lit_float(1.5)]
  m["cw/add/n/1"] = [@pl.col("n") + @pl.lit_int(1L)]
  m["cw/add/n/3e9"] = [@pl.col("n") + @pl.lit_int(3000000000L)]
  m["cw/add/n/f1.5"] = [@pl.col("n") + @pl.lit_float(1.5)]
  m["cs/add/i32/i32:1"] = [@pl.col("i32") + @pl.lit(@pl.AnyValue::Int32(1))]
  m["cs/add/i32/i32:max"] = [
    @pl.col("i32") + @pl.lit(@pl.AnyValue::Int32(2147483647)),
  ]
  m["cs/add/i32/i64:3e9"] = [
    @pl.col("i32") + @pl.lit(@pl.AnyValue::Int64(3000000000L)),
  ]
  m["cs/add/i32/f32:1.5"] = [
    @pl.col("i32") + @pl.lit(@pl.AnyValue::Float32(1.5)),
  ]
  m["cs/add/i32/f64:1.5"] = [
    @pl.col("i32") + @pl.lit(@pl.AnyValue::Float64(1.5)),
  ]
  m["cs/add/i32/f64:nan"] = [
    @pl.col("i32") + @pl.lit(@pl.AnyValue::Float64(0.0 / 0.0)),
  ]
  m["cs/add/i64/i32:1"] = [@pl.col("i64") + @pl.lit(@pl.AnyValue::Int32(1))]
  m["cs/add/i64/i32:max"] = [
    @pl.col("i64") + @pl.lit(@pl.AnyValue::Int32(2147483647)),
  ]
  m["cs/add/i64/i64:3e9"] = [
    @pl.col("i64") + @pl.lit(@pl.AnyValue::Int64(3000000000L)),
  ]
  m["cs/add/i64/f32:1.5"] = [
    @pl.col("i64") + @pl.lit(@pl.AnyValue::Float32(1.5)),
  ]
  m["cs/add/i64/f64:1.5"] = [
    @pl.col("i64") + @pl.lit(@pl.AnyValue::Float64(1.5)),
  ]
  m["cs/add/i64/f64:nan"] = [
    @pl.col("i64") + @pl.lit(@pl.AnyValue::Float64(0.0 / 0.0)),
  ]
  m["cs/add/f32/i32:1"] = [@pl.col("f32") + @pl.lit(@pl.AnyValue::Int32(1))]
  m["cs/add/f32/i32:max"] = [
    @pl.col("f32") + @pl.lit(@pl.AnyValue::Int32(2147483647)),
  ]
  m["cs/add/f32/i64:3e9"] = [
    @pl.col("f32") + @pl.lit(@pl.AnyValue::Int64(3000000000L)),
  ]
  m["cs/add/f32/f32:1.5"] = [
    @pl.col("f32") + @pl.lit(@pl.AnyValue::Float32(1.5)),
  ]
  m["cs/add/f32/f64:1.5"] = [
    @pl.col("f32") + @pl.lit(@pl.AnyValue::Float64(1.5)),
  ]
  m["cs/add/f32/f64:nan"] = [
    @pl.col("f32") + @pl.lit(@pl.AnyValue::Float64(0.0 / 0.0)),
  ]
  m["cs/add/f64/i32:1"] = [@pl.col("f64") + @pl.lit(@pl.AnyValue::Int32(1))]
  m["cs/add/f64/i32:max"] = [
    @pl.col("f64") + @pl.lit(@pl.AnyValue::Int32(2147483647)),
  ]
  m["cs/add/f64/i64:3e9"] = [
    @pl.col("f64") + @pl.lit(@pl.AnyValue::Int64(3000000000L)),
  ]
  m["cs/add/f64/f32:1.5"] = [
    @pl.col("f64") + @pl.lit(@pl.AnyValue::Float32(1.5)),
  ]
  m["cs/add/f64/f64:1.5"] = [
    @pl.col("f64") + @pl.lit(@pl.AnyValue::Float64(1.5)),
  ]
  m["cs/add/f64/f64:nan"] = [
    @pl.col("f64") + @pl.lit(@pl.AnyValue::Float64(0.0 / 0.0)),
  ]
  m["cs/div/i32/i32:1"] = [@pl.col("i32") / @pl.lit(@pl.AnyValue::Int32(1))]
  m["cs/div/i32/i32:max"] = [
    @pl.col("i32") / @pl.lit(@pl.AnyValue::Int32(2147483647)),
  ]
  m["cs/div/i32/i64:3e9"] = [
    @pl.col("i32") / @pl.lit(@pl.AnyValue::Int64(3000000000L)),
  ]
  m["cs/div/i32/f32:1.5"] = [
    @pl.col("i32") / @pl.lit(@pl.AnyValue::Float32(1.5)),
  ]
  m["cs/div/i32/f64:1.5"] = [
    @pl.col("i32") / @pl.lit(@pl.AnyValue::Float64(1.5)),
  ]
  m["cs/div/i32/f64:nan"] = [
    @pl.col("i32") / @pl.lit(@pl.AnyValue::Float64(0.0 / 0.0)),
  ]
  m["cs/div/i64/i32:1"] = [@pl.col("i64") / @pl.lit(@pl.AnyValue::Int32(1))]
  m["cs/div/i64/i64:3e9"] = [
    @pl.col("i64") / @pl.lit(@pl.AnyValue::Int64(3000000000L)),
  ]
  m["cs/div/i64/f32:1.5"] = [
    @pl.col("i64") / @pl.lit(@pl.AnyValue::Float32(1.5)),
  ]
  m["cs/div/i64/f64:1.5"] = [
    @pl.col("i64") / @pl.lit(@pl.AnyValue::Float64(1.5)),
  ]
  m["cs/div/f32/i32:1"] = [@pl.col("f32") / @pl.lit(@pl.AnyValue::Int32(1))]
  m["cs/div/f32/i32:max"] = [
    @pl.col("f32") / @pl.lit(@pl.AnyValue::Int32(2147483647)),
  ]
  m["cs/div/f32/i64:3e9"] = [
    @pl.col("f32") / @pl.lit(@pl.AnyValue::Int64(3000000000L)),
  ]
  m["cs/div/f32/f32:1.5"] = [
    @pl.col("f32") / @pl.lit(@pl.AnyValue::Float32(1.5)),
  ]
  m["cs/div/f32/f64:1.5"] = [
    @pl.col("f32") / @pl.lit(@pl.AnyValue::Float64(1.5)),
  ]
  m["cs/div/f32/f64:nan"] = [
    @pl.col("f32") / @pl.lit(@pl.AnyValue::Float64(0.0 / 0.0)),
  ]
  m["cs/div/f64/i32:1"] = [@pl.col("f64") / @pl.lit(@pl.AnyValue::Int32(1))]
  m["cs/div/f64/i64:3e9"] = [
    @pl.col("f64") / @pl.lit(@pl.AnyValue::Int64(3000000000L)),
  ]
  m["cs/div/f64/f32:1.5"] = [
    @pl.col("f64") / @pl.lit(@pl.AnyValue::Float32(1.5)),
  ]
  m["cs/div/f64/f64:1.5"] = [
    @pl.col("f64") / @pl.lit(@pl.AnyValue::Float64(1.5)),
  ]
  m["cs/eq/i32/i32:1"] = [@pl.col("i32").eq(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/eq/i32/i32:max"] = [
    @pl.col("i32").eq(@pl.lit(@pl.AnyValue::Int32(2147483647))),
  ]
  m["cs/eq/i32/i64:3e9"] = [
    @pl.col("i32").eq(@pl.lit(@pl.AnyValue::Int64(3000000000L))),
  ]
  m["cs/eq/i32/f32:1.5"] = [
    @pl.col("i32").eq(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["cs/eq/i32/f64:1.5"] = [
    @pl.col("i32").eq(@pl.lit(@pl.AnyValue::Float64(1.5))),
  ]
  m["cs/eq/i32/f64:nan"] = [
    @pl.col("i32").eq(@pl.lit(@pl.AnyValue::Float64(0.0 / 0.0))),
  ]
}

///|
fn golden_expr_cases_11(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cs/eq/i64/i32:1"] = [@pl.col("i64").eq(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/eq/i64/i32:max"] = [
    @pl.col("i64").eq(@pl.lit(@pl.AnyValue::Int32(2147483647))),
  ]
  m["cs/eq/i64/i64:3e9"] = [
    @pl.col("i64").eq(@pl.lit(@pl.AnyValue::Int64(3000000000L))),
  ]
  m["cs/eq/i64/f32:1.5"] = [
    @pl.col("i64").eq(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["cs/eq/i64/f64:1.5"] = [
    @pl.col("i64").eq(@pl.lit(@pl.AnyValue::Float64(1.5))),
  ]
  m["cs/eq/i64/f64:nan"] = [
    @pl.col("i64").eq(@pl.lit(@pl.AnyValue::Float64(0.0 / 0.0))),
  ]
  m["cs/eq/f32/i32:1"] = [@pl.col("f32").eq(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/eq/f32/i32:max"] = [
    @pl.col("f32").eq(@pl.lit(@pl.AnyValue::Int32(2147483647))),
  ]
  m["cs/eq/f32/i64:3e9"] = [
    @pl.col("f32").eq(@pl.lit(@pl.AnyValue::Int64(3000000000L))),
  ]
  m["cs/eq/f32/f32:1.5"] = [
    @pl.col("f32").eq(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["cs/eq/f32/f64:1.5"] = [
    @pl.col("f32").eq(@pl.lit(@pl.AnyValue::Float64(1.5))),
  ]
  m["cs/eq/f32/f64:nan"] = [
    @pl.col("f32").eq(@pl.lit(@pl.AnyValue::Float64(0.0 / 0.0))),
  ]
  m["cs/eq/f64/i32:1"] = [@pl.col("f64").eq(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/eq/f64/i32:max"] = [
    @pl.col("f64").eq(@pl.lit(@pl.AnyValue::Int32(2147483647))),
  ]
  m["cs/eq/f64/i64:3e9"] = [
    @pl.col("f64").eq(@pl.lit(@pl.AnyValue::Int64(3000000000L))),
  ]
  m["cs/eq/f64/f32:1.5"] = [
    @pl.col("f64").eq(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["cs/eq/f64/f64:1.5"] = [
    @pl.col("f64").eq(@pl.lit(@pl.AnyValue::Float64(1.5))),
  ]
  m["cs/eq/f64/f64:nan"] = [
    @pl.col("f64").eq(@pl.lit(@pl.AnyValue::Float64(0.0 / 0.0))),
  ]
  m["cs/lt/i32/i32:1"] = [@pl.col("i32").lt(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/lt/i32/i32:max"] = [
    @pl.col("i32").lt(@pl.lit(@pl.AnyValue::Int32(2147483647))),
  ]
  m["cs/lt/i32/i64:3e9"] = [
    @pl.col("i32").lt(@pl.lit(@pl.AnyValue::Int64(3000000000L))),
  ]
  m["cs/lt/i32/f32:1.5"] = [
    @pl.col("i32").lt(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["cs/lt/i32/f64:1.5"] = [
    @pl.col("i32").lt(@pl.lit(@pl.AnyValue::Float64(1.5))),
  ]
  m["cs/lt/i32/f64:nan"] = [
    @pl.col("i32").lt(@pl.lit(@pl.AnyValue::Float64(0.0 / 0.0))),
  ]
  m["cs/lt/i64/i32:1"] = [@pl.col("i64").lt(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/lt/i64/i64:3e9"] = [
    @pl.col("i64").lt(@pl.lit(@pl.AnyValue::Int64(3000000000L))),
  ]
  m["cs/lt/i64/f32:1.5"] = [
    @pl.col("i64").lt(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["cs/lt/i64/f64:1.5"] = [
    @pl.col("i64").lt(@pl.lit(@pl.AnyValue::Float64(1.5))),
  ]
  m["cs/lt/f32/i32:1"] = [@pl.col("f32").lt(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/lt/f32/i32:max"] = [
    @pl.col("f32").lt(@pl.lit(@pl.AnyValue::Int32(2147483647))),
  ]
  m["cs/lt/f32/i64:3e9"] = [
    @pl.col("f32").lt(@pl.lit(@pl.AnyValue::Int64(3000000000L))),
  ]
  m["cs/lt/f32/f32:1.5"] = [
    @pl.col("f32").lt(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["cs/lt/f32/f64:1.5"] = [
    @pl.col("f32").lt(@pl.lit(@pl.AnyValue::Float64(1.5))),
  ]
  m["cs/lt/f32/f64:nan"] = [
    @pl.col("f32").lt(@pl.lit(@pl.AnyValue::Float64(0.0 / 0.0))),
  ]
  m["cs/lt/f64/i32:1"] = [@pl.col("f64").lt(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/lt/f64/i64:3e9"] = [
    @pl.col("f64").lt(@pl.lit(@pl.AnyValue::Int64(3000000000L))),
  ]
  m["cs/lt/f64/f32:1.5"] = [
    @pl.col("f64").lt(@pl.lit(@pl.AnyValue::Float32(1.5))),
  ]
  m["cs/lt/f64/f64:1.5"] = [
    @pl.col("f64").lt(@pl.lit(@pl.AnyValue::Float64(1.5))),
  ]
  m["cs/eq/b/bool:true"] = [
    @pl.col("b").eq(@pl.lit(@pl.AnyValue::Boolean(true))),
  ]
  m["cs/eq/b/str:a"] = [@pl.col("b").eq(@pl.lit(@pl.AnyValue::String("a")))]
  m["cs/eq/b/null"] = [@pl.col("b").eq(@pl.lit(@pl.AnyValue::Null))]
  m["cs/eq/b/date:1"] = [@pl.col("b").eq(@pl.lit(@pl.AnyValue::Date(1)))]
  m["cs/eq/b/datetime:5"] = [
    @pl.col("b").eq(@pl.lit(@pl.AnyValue::Datetime(5L))),
  ]
  m["cs/eq/b/i32:1"] = [@pl.col("b").eq(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/eq/b/str:emoji"] = [
    @pl.col("b").eq(@pl.lit(@pl.AnyValue::String("😀"))),
  ]
  m["cs/eq/s/bool:true"] = [
    @pl.col("s").eq(@pl.lit(@pl.AnyValue::Boolean(true))),
  ]
  m["cs/eq/s/str:a"] = [@pl.col("s").eq(@pl.lit(@pl.AnyValue::String("a")))]
  m["cs/eq/s/null"] = [@pl.col("s").eq(@pl.lit(@pl.AnyValue::Null))]
  m["cs/eq/s/date:1"] = [@pl.col("s").eq(@pl.lit(@pl.AnyValue::Date(1)))]
  m["cs/eq/s/datetime:5"] = [
    @pl.col("s").eq(@pl.lit(@pl.AnyValue::Datetime(5L))),
  ]
  m["cs/eq/s/i32:1"] = [@pl.col("s").eq(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/eq/s/str:emoji"] = [
    @pl.col("s").eq(@pl.lit(@pl.AnyValue::String("😀"))),
  ]
  m["cs/eq/d/bool:true"] = [
    @pl.col("d").eq(@pl.lit(@pl.AnyValue::Boolean(true))),
  ]
  m["cs/eq/d/str:a"] = [@pl.col("d").eq(@pl.lit(@pl.AnyValue::String("a")))]
  m["cs/eq/d/null"] = [@pl.col("d").eq(@pl.lit(@pl.AnyValue::Null))]
  m["cs/eq/d/date:1"] = [@pl.col("d").eq(@pl.lit(@pl.AnyValue::Date(1)))]
  m["cs/eq/d/datetime:5"] = [
    @pl.col("d").eq(@pl.lit(@pl.AnyValue::Datetime(5L))),
  ]
  m["cs/eq/d/i32:1"] = [@pl.col("d").eq(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/eq/d/str:emoji"] = [
    @pl.col("d").eq(@pl.lit(@pl.AnyValue::String("😀"))),
  ]
  m["cs/eq/dt/bool:true"] = [
    @pl.col("dt").eq(@pl.lit(@pl.AnyValue::Boolean(true))),
  ]
}

///|
fn golden_expr_cases_12(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cs/eq/dt/str:a"] = [@pl.col("dt").eq(@pl.lit(@pl.AnyValue::String("a")))]
  m["cs/eq/dt/null"] = [@pl.col("dt").eq(@pl.lit(@pl.AnyValue::Null))]
  m["cs/eq/dt/date:1"] = [@pl.col("dt").eq(@pl.lit(@pl.AnyValue::Date(1)))]
  m["cs/eq/dt/datetime:5"] = [
    @pl.col("dt").eq(@pl.lit(@pl.AnyValue::Datetime(5L))),
  ]
  m["cs/eq/dt/i32:1"] = [@pl.col("dt").eq(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/eq/dt/str:emoji"] = [
    @pl.col("dt").eq(@pl.lit(@pl.AnyValue::String("😀"))),
  ]
  m["cs/eq/n/bool:true"] = [
    @pl.col("n").eq(@pl.lit(@pl.AnyValue::Boolean(true))),
  ]
  m["cs/eq/n/str:a"] = [@pl.col("n").eq(@pl.lit(@pl.AnyValue::String("a")))]
  m["cs/eq/n/null"] = [@pl.col("n").eq(@pl.lit(@pl.AnyValue::Null))]
  m["cs/eq/n/date:1"] = [@pl.col("n").eq(@pl.lit(@pl.AnyValue::Date(1)))]
  m["cs/eq/n/datetime:5"] = [
    @pl.col("n").eq(@pl.lit(@pl.AnyValue::Datetime(5L))),
  ]
  m["cs/eq/n/i32:1"] = [@pl.col("n").eq(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/eq/n/str:emoji"] = [
    @pl.col("n").eq(@pl.lit(@pl.AnyValue::String("😀"))),
  ]
  m["cs/lt/b/bool:true"] = [
    @pl.col("b").lt(@pl.lit(@pl.AnyValue::Boolean(true))),
  ]
  m["cs/lt/b/str:a"] = [@pl.col("b").lt(@pl.lit(@pl.AnyValue::String("a")))]
  m["cs/lt/b/null"] = [@pl.col("b").lt(@pl.lit(@pl.AnyValue::Null))]
  m["cs/lt/b/date:1"] = [@pl.col("b").lt(@pl.lit(@pl.AnyValue::Date(1)))]
  m["cs/lt/b/datetime:5"] = [
    @pl.col("b").lt(@pl.lit(@pl.AnyValue::Datetime(5L))),
  ]
  m["cs/lt/b/i32:1"] = [@pl.col("b").lt(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/lt/b/str:emoji"] = [
    @pl.col("b").lt(@pl.lit(@pl.AnyValue::String("😀"))),
  ]
  m["cs/lt/s/bool:true"] = [
    @pl.col("s").lt(@pl.lit(@pl.AnyValue::Boolean(true))),
  ]
  m["cs/lt/s/str:a"] = [@pl.col("s").lt(@pl.lit(@pl.AnyValue::String("a")))]
  m["cs/lt/s/null"] = [@pl.col("s").lt(@pl.lit(@pl.AnyValue::Null))]
  m["cs/lt/s/date:1"] = [@pl.col("s").lt(@pl.lit(@pl.AnyValue::Date(1)))]
  m["cs/lt/s/datetime:5"] = [
    @pl.col("s").lt(@pl.lit(@pl.AnyValue::Datetime(5L))),
  ]
  m["cs/lt/s/i32:1"] = [@pl.col("s").lt(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/lt/s/str:emoji"] = [
    @pl.col("s").lt(@pl.lit(@pl.AnyValue::String("😀"))),
  ]
  m["cs/lt/d/bool:true"] = [
    @pl.col("d").lt(@pl.lit(@pl.AnyValue::Boolean(true))),
  ]
  m["cs/lt/d/str:a"] = [@pl.col("d").lt(@pl.lit(@pl.AnyValue::String("a")))]
  m["cs/lt/d/null"] = [@pl.col("d").lt(@pl.lit(@pl.AnyValue::Null))]
  m["cs/lt/d/date:1"] = [@pl.col("d").lt(@pl.lit(@pl.AnyValue::Date(1)))]
  m["cs/lt/d/datetime:5"] = [
    @pl.col("d").lt(@pl.lit(@pl.AnyValue::Datetime(5L))),
  ]
  m["cs/lt/d/i32:1"] = [@pl.col("d").lt(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/lt/d/str:emoji"] = [
    @pl.col("d").lt(@pl.lit(@pl.AnyValue::String("😀"))),
  ]
  m["cs/lt/dt/bool:true"] = [
    @pl.col("dt").lt(@pl.lit(@pl.AnyValue::Boolean(true))),
  ]
  m["cs/lt/dt/str:a"] = [@pl.col("dt").lt(@pl.lit(@pl.AnyValue::String("a")))]
  m["cs/lt/dt/null"] = [@pl.col("dt").lt(@pl.lit(@pl.AnyValue::Null))]
  m["cs/lt/dt/date:1"] = [@pl.col("dt").lt(@pl.lit(@pl.AnyValue::Date(1)))]
  m["cs/lt/dt/datetime:5"] = [
    @pl.col("dt").lt(@pl.lit(@pl.AnyValue::Datetime(5L))),
  ]
  m["cs/lt/dt/i32:1"] = [@pl.col("dt").lt(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/lt/dt/str:emoji"] = [
    @pl.col("dt").lt(@pl.lit(@pl.AnyValue::String("😀"))),
  ]
  m["cs/lt/n/bool:true"] = [
    @pl.col("n").lt(@pl.lit(@pl.AnyValue::Boolean(true))),
  ]
  m["cs/lt/n/str:a"] = [@pl.col("n").lt(@pl.lit(@pl.AnyValue::String("a")))]
  m["cs/lt/n/null"] = [@pl.col("n").lt(@pl.lit(@pl.AnyValue::Null))]
  m["cs/lt/n/date:1"] = [@pl.col("n").lt(@pl.lit(@pl.AnyValue::Date(1)))]
  m["cs/lt/n/datetime:5"] = [
    @pl.col("n").lt(@pl.lit(@pl.AnyValue::Datetime(5L))),
  ]
  m["cs/lt/n/i32:1"] = [@pl.col("n").lt(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["cs/lt/n/str:emoji"] = [
    @pl.col("n").lt(@pl.lit(@pl.AnyValue::String("😀"))),
  ]
  m["cs/add/i32/bool:true"] = [
    @pl.col("i32") + @pl.lit(@pl.AnyValue::Boolean(true)),
  ]
  m["cs/add/i32/str:a"] = [@pl.col("i32") + @pl.lit(@pl.AnyValue::String("a"))]
  m["cs/add/i32/null"] = [@pl.col("i32") + @pl.lit(@pl.AnyValue::Null)]
  m["cs/add/i32/date:1"] = [@pl.col("i32") + @pl.lit(@pl.AnyValue::Date(1))]
  m["cs/add/i64/bool:true"] = [
    @pl.col("i64") + @pl.lit(@pl.AnyValue::Boolean(true)),
  ]
  m["cs/add/i64/str:a"] = [@pl.col("i64") + @pl.lit(@pl.AnyValue::String("a"))]
  m["cs/add/i64/null"] = [@pl.col("i64") + @pl.lit(@pl.AnyValue::Null)]
  m["cs/add/i64/date:1"] = [@pl.col("i64") + @pl.lit(@pl.AnyValue::Date(1))]
  m["cs/add/f32/bool:true"] = [
    @pl.col("f32") + @pl.lit(@pl.AnyValue::Boolean(true)),
  ]
  m["cs/add/f32/str:a"] = [@pl.col("f32") + @pl.lit(@pl.AnyValue::String("a"))]
  m["cs/add/f32/null"] = [@pl.col("f32") + @pl.lit(@pl.AnyValue::Null)]
  m["cs/add/f32/date:1"] = [@pl.col("f32") + @pl.lit(@pl.AnyValue::Date(1))]
}

///|
fn golden_expr_cases_13(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cs/add/f64/bool:true"] = [
    @pl.col("f64") + @pl.lit(@pl.AnyValue::Boolean(true)),
  ]
  m["cs/add/f64/str:a"] = [@pl.col("f64") + @pl.lit(@pl.AnyValue::String("a"))]
  m["cs/add/f64/null"] = [@pl.col("f64") + @pl.lit(@pl.AnyValue::Null)]
  m["cs/add/f64/date:1"] = [@pl.col("f64") + @pl.lit(@pl.AnyValue::Date(1))]
  m["cs/add/n/i32:1"] = [@pl.col("n") + @pl.lit(@pl.AnyValue::Int32(1))]
  m["cs/add/n/null"] = [@pl.col("n") + @pl.lit(@pl.AnyValue::Null)]
  m["cs/add/n/f64:1.5"] = [@pl.col("n") + @pl.lit(@pl.AnyValue::Float64(1.5))]
  m["lit/int1"] = [@pl.lit_int(1L)]
  m["lit/int1/z0"] = [@pl.lit_int(1L)]
  m["lit/int1/alias"] = [@pl.lit_int(1L).alias("x")]
  m["lit/int1/is_null"] = [@pl.lit_int(1L).is_null()]
  m["lit/int-1"] = [@pl.lit_int(-1L)]
  m["lit/int3e9"] = [@pl.lit_int(3000000000L)]
  m["lit/intmax"] = [@pl.lit_int(9223372036854775807L)]
  m["lit/intmin"] = [@pl.lit_int(-9223372036854775807L - 1L)]
  m["lit/int0"] = [@pl.lit_int(0L)]
  m["lit/float1.5"] = [@pl.lit_float(1.5)]
  m["lit/float1.5/z0"] = [@pl.lit_float(1.5)]
  m["lit/float1.5/alias"] = [@pl.lit_float(1.5).alias("x")]
  m["lit/float1.5/is_null"] = [@pl.lit_float(1.5).is_null()]
  m["lit/float1"] = [@pl.lit_float(1.0)]
  m["lit/float1e20"] = [@pl.lit_float(1.0e20)]
  m["lit/float1e300"] = [@pl.lit_float(1.0e300)]
  m["lit/float-0"] = [@pl.lit_float(-0.0)]
  m["lit/floatnan"] = [@pl.lit_float(0.0 / 0.0)]
  m["lit/floatinf"] = [@pl.lit_float(1.0 / 0.0)]
  m["lit/float-inf"] = [@pl.lit_float(-1.0 / 0.0)]
  m["lit/float0.1"] = [@pl.lit_float(0.1)]
  m["lit/float1e-7"] = [@pl.lit_float(1.0e-07)]
  m["lit/float1e15"] = [@pl.lit_float(1000000000000000.0)]
  m["lit/float123456789.123456789"] = [@pl.lit_float(123456789.12345679)]
  m["lit/str"] = [@pl.lit_str("a")]
  m["lit/str/z0"] = [@pl.lit_str("a")]
  m["lit/str/alias"] = [@pl.lit_str("a").alias("x")]
  m["lit/str/is_null"] = [@pl.lit_str("a").is_null()]
  m["lit/str-uni"] = [@pl.lit_str("😀｡")]
  m["lit/str-empty"] = [@pl.lit_str("")]
  m["lit/str-quote"] = [@pl.lit_str("a\"b")]
  m["lit/bool-t"] = [@pl.lit_bool(true)]
  m["lit/bool-t/z0"] = [@pl.lit_bool(true)]
  m["lit/bool-t/alias"] = [@pl.lit_bool(true).alias("x")]
  m["lit/bool-t/is_null"] = [@pl.lit_bool(true).is_null()]
  m["lit/bool-f"] = [@pl.lit_bool(false)]
  m["lit/null"] = [@pl.lit(@pl.AnyValue::Null)]
  m["lit/null/z0"] = [@pl.lit(@pl.AnyValue::Null)]
  m["lit/null/alias"] = [@pl.lit(@pl.AnyValue::Null).alias("x")]
  m["lit/null/is_null"] = [@pl.lit(@pl.AnyValue::Null).is_null()]
  m["lit/i32"] = [@pl.lit(@pl.AnyValue::Int32(5))]
  m["lit/i32/z0"] = [@pl.lit(@pl.AnyValue::Int32(5))]
  m["lit/i32/alias"] = [@pl.lit(@pl.AnyValue::Int32(5)).alias("x")]
  m["lit/i32/is_null"] = [@pl.lit(@pl.AnyValue::Int32(5)).is_null()]
  m["lit/i32-neg"] = [@pl.lit(@pl.AnyValue::Int32(-5))]
  m["lit/i32-min"] = [@pl.lit(@pl.AnyValue::Int32(-2147483647 - 1))]
  m["lit/i64"] = [@pl.lit(@pl.AnyValue::Int64(5L))]
  m["lit/i64-min"] = [@pl.lit(@pl.AnyValue::Int64(-9223372036854775807L - 1L))]
  m["lit/f32"] = [@pl.lit(@pl.AnyValue::Float32(1.5))]
  m["lit/f32-0.1"] = [@pl.lit(@pl.AnyValue::Float32(0.1))]
  m["lit/f32-1e20"] = [@pl.lit(@pl.AnyValue::Float32(1.0e20))]
  m["lit/f32-nan"] = [@pl.lit(@pl.AnyValue::Float32(0.0 / 0.0))]
  m["lit/f32-inf"] = [@pl.lit(@pl.AnyValue::Float32(1.0 / 0.0))]
}

///|
fn golden_expr_cases_14(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["lit/f32--0"] = [@pl.lit(@pl.AnyValue::Float32(-0.0))]
  m["lit/f64"] = [@pl.lit(@pl.AnyValue::Float64(1.5))]
  m["lit/f64-1e20"] = [@pl.lit(@pl.AnyValue::Float64(1.0e20))]
  m["lit/f64-1e-7"] = [@pl.lit(@pl.AnyValue::Float64(1.0e-07))]
  m["lit/f64-nan"] = [@pl.lit(@pl.AnyValue::Float64(0.0 / 0.0))]
  m["lit/f64--inf"] = [@pl.lit(@pl.AnyValue::Float64(-1.0 / 0.0))]
  m["lit/f64--0"] = [@pl.lit(@pl.AnyValue::Float64(-0.0))]
  m["lit/f64-123456.789"] = [@pl.lit(@pl.AnyValue::Float64(123456.789))]
  m["lit/f64-0.333"] = [@pl.lit(@pl.AnyValue::Float64(0.3333333333333333))]
  m["lit/bool"] = [@pl.lit(@pl.AnyValue::Boolean(true))]
  m["lit/str-lit"] = [@pl.lit(@pl.AnyValue::String("x y"))]
  m["lit/date"] = [@pl.lit(@pl.AnyValue::Date(19782))]
  m["lit/date/z0"] = [@pl.lit(@pl.AnyValue::Date(19782))]
  m["lit/date/alias"] = [@pl.lit(@pl.AnyValue::Date(19782)).alias("x")]
  m["lit/date/is_null"] = [@pl.lit(@pl.AnyValue::Date(19782)).is_null()]
  m["lit/date-neg"] = [@pl.lit(@pl.AnyValue::Date(-25567))]
  m["lit/datetime"] = [@pl.lit(@pl.AnyValue::Datetime(1709210096123456L))]
  m["lit/datetime-ms"] = [@pl.lit(@pl.AnyValue::Datetime(1500000L))]
  m["lit/datetime-s"] = [@pl.lit(@pl.AnyValue::Datetime(1000000L))]
  m["lit/datetime-neg"] = [@pl.lit(@pl.AnyValue::Datetime(-1L))]
  m["lit/int1/neg"] = [-@pl.lit_int(1L)]
  m["lit/int1/neg-neg"] = [-(-@pl.lit_int(1L))]
  m["lit/int3e9/neg"] = [-@pl.lit_int(3000000000L)]
  m["lit/int3e9/neg-neg"] = [-(-@pl.lit_int(3000000000L))]
  m["lit/intmin/neg"] = [-@pl.lit_int(-9223372036854775807L - 1L)]
  m["lit/intmin/neg-neg"] = [-(-@pl.lit_int(-9223372036854775807L - 1L))]
  m["lit/float1.5/neg"] = [-@pl.lit_float(1.5)]
  m["lit/float1.5/neg-neg"] = [-(-@pl.lit_float(1.5))]
  m["lit/float1e300/neg"] = [-@pl.lit_float(1.0e300)]
  m["lit/float1e300/neg-neg"] = [-(-@pl.lit_float(1.0e300))]
  m["lit/i32/neg"] = [-@pl.lit(@pl.AnyValue::Int32(5))]
  m["lit/i64/neg"] = [-@pl.lit(@pl.AnyValue::Int64(5L))]
  m["lit/f32/neg"] = [-@pl.lit(@pl.AnyValue::Float32(1.5))]
  m["lit/f64/neg"] = [-@pl.lit(@pl.AnyValue::Float64(1.5))]
  m["lit/i32-min/neg"] = [-@pl.lit(@pl.AnyValue::Int32(-2147483647 - 1))]
  m["lit/i64-min/neg"] = [
    -@pl.lit(@pl.AnyValue::Int64(-9223372036854775807L - 1L)),
  ]
  m["lit/bool-t/not"] = [@pl.lit_bool(true).not_()]
  m["lit/bool-f/not"] = [@pl.lit_bool(false).not_()]
  m["lit/bool/not"] = [@pl.lit(@pl.AnyValue::Boolean(true)).not_()]
  m["lit/null/not"] = [@pl.lit(@pl.AnyValue::Null).not_()]
  m["lit/str/neg"] = [-@pl.lit_str("a")]
  m["lit/int1/not"] = [@pl.lit_int(1L).not_()]
  m["ll/add/i1,i2"] = [@pl.lit_int(1L) + @pl.lit_int(2L)]
  m["ll/add/i3e9,i2"] = [@pl.lit_int(3000000000L) + @pl.lit_int(2L)]
  m["ll/add/i2,i0"] = [@pl.lit_int(2L) + @pl.lit_int(0L)]
  m["ll/add/i-7,i2"] = [@pl.lit_int(-7L) + @pl.lit_int(2L)]
  m["ll/add/i7,i-2"] = [@pl.lit_int(7L) + @pl.lit_int(-2L)]
  m["ll/add/i1,f2.5"] = [@pl.lit_int(1L) + @pl.lit_float(2.5)]
  m["ll/add/f1.5,i2"] = [@pl.lit_float(1.5) + @pl.lit_int(2L)]
  m["ll/add/f1.5,f2.5"] = [@pl.lit_float(1.5) + @pl.lit_float(2.5)]
  m["ll/add/f1,f0"] = [@pl.lit_float(1.0) + @pl.lit_float(0.0)]
  m["ll/add/imax,i1"] = [@pl.lit_int(9223372036854775807L) + @pl.lit_int(1L)]
  m["ll/add/imin,i-1"] = [
    @pl.lit_int(-9223372036854775807L - 1L) + @pl.lit_int(-1L),
  ]
  m["ll/add/i2^62,i4"] = [@pl.lit_int(4611686018427387904L) + @pl.lit_int(4L)]
  m["ll/sub/i1,i2"] = [@pl.lit_int(1L) - @pl.lit_int(2L)]
  m["ll/sub/i3e9,i2"] = [@pl.lit_int(3000000000L) - @pl.lit_int(2L)]
  m["ll/sub/i2,i0"] = [@pl.lit_int(2L) - @pl.lit_int(0L)]
  m["ll/sub/i-7,i2"] = [@pl.lit_int(-7L) - @pl.lit_int(2L)]
  m["ll/sub/i7,i-2"] = [@pl.lit_int(7L) - @pl.lit_int(-2L)]
  m["ll/sub/i1,f2.5"] = [@pl.lit_int(1L) - @pl.lit_float(2.5)]
}

///|
fn golden_expr_cases_15(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["ll/sub/f1.5,i2"] = [@pl.lit_float(1.5) - @pl.lit_int(2L)]
  m["ll/sub/f1.5,f2.5"] = [@pl.lit_float(1.5) - @pl.lit_float(2.5)]
  m["ll/sub/f1,f0"] = [@pl.lit_float(1.0) - @pl.lit_float(0.0)]
  m["ll/sub/imax,i1"] = [@pl.lit_int(9223372036854775807L) - @pl.lit_int(1L)]
  m["ll/sub/imin,i-1"] = [
    @pl.lit_int(-9223372036854775807L - 1L) - @pl.lit_int(-1L),
  ]
  m["ll/sub/i2^62,i4"] = [@pl.lit_int(4611686018427387904L) - @pl.lit_int(4L)]
  m["ll/mul/i1,i2"] = [@pl.lit_int(1L) * @pl.lit_int(2L)]
  m["ll/mul/i3e9,i2"] = [@pl.lit_int(3000000000L) * @pl.lit_int(2L)]
  m["ll/mul/i2,i0"] = [@pl.lit_int(2L) * @pl.lit_int(0L)]
  m["ll/mul/i-7,i2"] = [@pl.lit_int(-7L) * @pl.lit_int(2L)]
  m["ll/mul/i7,i-2"] = [@pl.lit_int(7L) * @pl.lit_int(-2L)]
  m["ll/mul/i1,f2.5"] = [@pl.lit_int(1L) * @pl.lit_float(2.5)]
  m["ll/mul/f1.5,i2"] = [@pl.lit_float(1.5) * @pl.lit_int(2L)]
  m["ll/mul/f1.5,f2.5"] = [@pl.lit_float(1.5) * @pl.lit_float(2.5)]
  m["ll/mul/f1,f0"] = [@pl.lit_float(1.0) * @pl.lit_float(0.0)]
  m["ll/mul/imax,i1"] = [@pl.lit_int(9223372036854775807L) * @pl.lit_int(1L)]
  m["ll/mul/imin,i-1"] = [
    @pl.lit_int(-9223372036854775807L - 1L) * @pl.lit_int(-1L),
  ]
  m["ll/mul/i2^62,i4"] = [@pl.lit_int(4611686018427387904L) * @pl.lit_int(4L)]
  m["ll/div/i1,i2"] = [@pl.lit_int(1L) / @pl.lit_int(2L)]
  m["ll/div/i3e9,i2"] = [@pl.lit_int(3000000000L) / @pl.lit_int(2L)]
  m["ll/div/i2,i0"] = [@pl.lit_int(2L) / @pl.lit_int(0L)]
  m["ll/div/i-7,i2"] = [@pl.lit_int(-7L) / @pl.lit_int(2L)]
  m["ll/div/i7,i-2"] = [@pl.lit_int(7L) / @pl.lit_int(-2L)]
  m["ll/div/i1,f2.5"] = [@pl.lit_int(1L) / @pl.lit_float(2.5)]
  m["ll/div/f1.5,i2"] = [@pl.lit_float(1.5) / @pl.lit_int(2L)]
  m["ll/div/f1.5,f2.5"] = [@pl.lit_float(1.5) / @pl.lit_float(2.5)]
  m["ll/div/f1,f0"] = [@pl.lit_float(1.0) / @pl.lit_float(0.0)]
  m["ll/div/imax,i1"] = [@pl.lit_int(9223372036854775807L) / @pl.lit_int(1L)]
  m["ll/div/imin,i-1"] = [
    @pl.lit_int(-9223372036854775807L - 1L) / @pl.lit_int(-1L),
  ]
  m["ll/div/i2^62,i4"] = [@pl.lit_int(4611686018427387904L) / @pl.lit_int(4L)]
  m["ll/floordiv/i1,i2"] = [@pl.lit_int(1L).floor_div(@pl.lit_int(2L))]
  m["ll/floordiv/i3e9,i2"] = [
    @pl.lit_int(3000000000L).floor_div(@pl.lit_int(2L)),
  ]
  m["ll/floordiv/i2,i0"] = [@pl.lit_int(2L).floor_div(@pl.lit_int(0L))]
  m["ll/floordiv/i-7,i2"] = [@pl.lit_int(-7L).floor_div(@pl.lit_int(2L))]
  m["ll/floordiv/i7,i-2"] = [@pl.lit_int(7L).floor_div(@pl.lit_int(-2L))]
  m["ll/floordiv/i1,f2.5"] = [@pl.lit_int(1L).floor_div(@pl.lit_float(2.5))]
  m["ll/floordiv/f1.5,i2"] = [@pl.lit_float(1.5).floor_div(@pl.lit_int(2L))]
  m["ll/floordiv/f1.5,f2.5"] = [
    @pl.lit_float(1.5).floor_div(@pl.lit_float(2.5)),
  ]
  m["ll/floordiv/f1,f0"] = [@pl.lit_float(1.0).floor_div(@pl.lit_float(0.0))]
  m["ll/floordiv/imax,i1"] = [
    @pl.lit_int(9223372036854775807L).floor_div(@pl.lit_int(1L)),
  ]
  m["ll/floordiv/imin,i-1"] = [
    @pl.lit_int(-9223372036854775807L - 1L).floor_div(@pl.lit_int(-1L)),
  ]
  m["ll/floordiv/i2^62,i4"] = [
    @pl.lit_int(4611686018427387904L).floor_div(@pl.lit_int(4L)),
  ]
  m["ll/eq/i1,i2"] = [@pl.lit_int(1L).eq(@pl.lit_int(2L))]
  m["ll/eq/i3e9,i2"] = [@pl.lit_int(3000000000L).eq(@pl.lit_int(2L))]
  m["ll/eq/i2,i0"] = [@pl.lit_int(2L).eq(@pl.lit_int(0L))]
  m["ll/eq/i-7,i2"] = [@pl.lit_int(-7L).eq(@pl.lit_int(2L))]
  m["ll/eq/i7,i-2"] = [@pl.lit_int(7L).eq(@pl.lit_int(-2L))]
  m["ll/eq/i1,f2.5"] = [@pl.lit_int(1L).eq(@pl.lit_float(2.5))]
  m["ll/eq/f1.5,i2"] = [@pl.lit_float(1.5).eq(@pl.lit_int(2L))]
  m["ll/eq/f1.5,f2.5"] = [@pl.lit_float(1.5).eq(@pl.lit_float(2.5))]
  m["ll/eq/f1,f0"] = [@pl.lit_float(1.0).eq(@pl.lit_float(0.0))]
  m["ll/eq/imax,i1"] = [@pl.lit_int(9223372036854775807L).eq(@pl.lit_int(1L))]
  m["ll/eq/imin,i-1"] = [
    @pl.lit_int(-9223372036854775807L - 1L).eq(@pl.lit_int(-1L)),
  ]
  m["ll/eq/i2^62,i4"] = [@pl.lit_int(4611686018427387904L).eq(@pl.lit_int(4L))]
  m["ll/lt/i1,i2"] = [@pl.lit_int(1L).lt(@pl.lit_int(2L))]
  m["ll/lt/i3e9,i2"] = [@pl.lit_int(3000000000L).lt(@pl.lit_int(2L))]
  m["ll/lt/i2,i0"] = [@pl.lit_int(2L).lt(@pl.lit_int(0L))]
  m["ll/lt/i-7,i2"] = [@pl.lit_int(-7L).lt(@pl.lit_int(2L))]
  m["ll/lt/i7,i-2"] = [@pl.lit_int(7L).lt(@pl.lit_int(-2L))]
  m["ll/lt/i1,f2.5"] = [@pl.lit_int(1L).lt(@pl.lit_float(2.5))]
}

///|
fn golden_expr_cases_16(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["ll/lt/f1.5,i2"] = [@pl.lit_float(1.5).lt(@pl.lit_int(2L))]
  m["ll/lt/f1.5,f2.5"] = [@pl.lit_float(1.5).lt(@pl.lit_float(2.5))]
  m["ll/lt/f1,f0"] = [@pl.lit_float(1.0).lt(@pl.lit_float(0.0))]
  m["ll/lt/imax,i1"] = [@pl.lit_int(9223372036854775807L).lt(@pl.lit_int(1L))]
  m["ll/lt/imin,i-1"] = [
    @pl.lit_int(-9223372036854775807L - 1L).lt(@pl.lit_int(-1L)),
  ]
  m["ll/lt/i2^62,i4"] = [@pl.lit_int(4611686018427387904L).lt(@pl.lit_int(4L))]
  m["ls/add/i32:1,i2"] = [@pl.lit(@pl.AnyValue::Int32(1)) + @pl.lit_int(2L)]
  m["ls/add/i32:1,i3e9"] = [
    @pl.lit(@pl.AnyValue::Int32(1)) + @pl.lit_int(3000000000L),
  ]
  m["ls/add/i2,i32:1"] = [@pl.lit_int(2L) + @pl.lit(@pl.AnyValue::Int32(1))]
  m["ls/add/i64:1,i2"] = [@pl.lit(@pl.AnyValue::Int64(1L)) + @pl.lit_int(2L)]
  m["ls/add/i32:1,f1.5"] = [
    @pl.lit(@pl.AnyValue::Int32(1)) + @pl.lit_float(1.5),
  ]
  m["ls/add/f32:1.5,i2"] = [
    @pl.lit(@pl.AnyValue::Float32(1.5)) + @pl.lit_int(2L),
  ]
  m["ls/add/f32:1.5,f1e300"] = [
    @pl.lit(@pl.AnyValue::Float32(1.5)) + @pl.lit_float(1.0e300),
  ]
  m["ls/add/f64:1.5,i2"] = [
    @pl.lit(@pl.AnyValue::Float64(1.5)) + @pl.lit_int(2L),
  ]
  m["ls/add/i32:1,i64:2"] = [
    @pl.lit(@pl.AnyValue::Int32(1)) + @pl.lit(@pl.AnyValue::Int64(2L)),
  ]
  m["ls/add/i32:1,f32:2"] = [
    @pl.lit(@pl.AnyValue::Int32(1)) + @pl.lit(@pl.AnyValue::Float32(2.0)),
  ]
  m["ls/add/f32:1,f64:2"] = [
    @pl.lit(@pl.AnyValue::Float32(1.0)) + @pl.lit(@pl.AnyValue::Float64(2.0)),
  ]
  m["ls/add/null,i1"] = [@pl.lit(@pl.AnyValue::Null) + @pl.lit_int(1L)]
  m["ls/add/i1,null"] = [@pl.lit_int(1L) + @pl.lit(@pl.AnyValue::Null)]
  m["ls/add/null,f1.5"] = [@pl.lit(@pl.AnyValue::Null) + @pl.lit_float(1.5)]
  m["ls/add/i32:null,i1"] = [@pl.lit(@pl.AnyValue::Null) + @pl.lit_int(1L)]
  m["ls/add/str:a,str:b"] = [
    @pl.lit(@pl.AnyValue::String("a")) + @pl.lit(@pl.AnyValue::String("b")),
  ]
  m["ls/add/bool,bool"] = [
    @pl.lit(@pl.AnyValue::Boolean(true)) + @pl.lit(@pl.AnyValue::Boolean(false)),
  ]
  m["ls/add/date:1,date:2"] = [
    @pl.lit(@pl.AnyValue::Date(1)) + @pl.lit(@pl.AnyValue::Date(2)),
  ]
  m["ls/add/date:1,i1"] = [@pl.lit(@pl.AnyValue::Date(1)) + @pl.lit_int(1L)]
  m["ls/div/i32:1,i2"] = [@pl.lit(@pl.AnyValue::Int32(1)) / @pl.lit_int(2L)]
  m["ls/div/i32:1,i3e9"] = [
    @pl.lit(@pl.AnyValue::Int32(1)) / @pl.lit_int(3000000000L),
  ]
  m["ls/div/i2,i32:1"] = [@pl.lit_int(2L) / @pl.lit(@pl.AnyValue::Int32(1))]
  m["ls/div/i64:1,i2"] = [@pl.lit(@pl.AnyValue::Int64(1L)) / @pl.lit_int(2L)]
  m["ls/div/i32:1,f1.5"] = [
    @pl.lit(@pl.AnyValue::Int32(1)) / @pl.lit_float(1.5),
  ]
  m["ls/div/f32:1.5,i2"] = [
    @pl.lit(@pl.AnyValue::Float32(1.5)) / @pl.lit_int(2L),
  ]
  m["ls/div/f32:1.5,f1e300"] = [
    @pl.lit(@pl.AnyValue::Float32(1.5)) / @pl.lit_float(1.0e300),
  ]
  m["ls/div/f64:1.5,i2"] = [
    @pl.lit(@pl.AnyValue::Float64(1.5)) / @pl.lit_int(2L),
  ]
  m["ls/div/i32:1,i64:2"] = [
    @pl.lit(@pl.AnyValue::Int32(1)) / @pl.lit(@pl.AnyValue::Int64(2L)),
  ]
  m["ls/div/i32:1,f32:2"] = [
    @pl.lit(@pl.AnyValue::Int32(1)) / @pl.lit(@pl.AnyValue::Float32(2.0)),
  ]
  m["ls/div/f32:1,f64:2"] = [
    @pl.lit(@pl.AnyValue::Float32(1.0)) / @pl.lit(@pl.AnyValue::Float64(2.0)),
  ]
  m["ls/div/null,i1"] = [@pl.lit(@pl.AnyValue::Null) / @pl.lit_int(1L)]
  m["ls/div/i1,null"] = [@pl.lit_int(1L) / @pl.lit(@pl.AnyValue::Null)]
  m["ls/div/null,f1.5"] = [@pl.lit(@pl.AnyValue::Null) / @pl.lit_float(1.5)]
  m["ls/div/i32:null,i1"] = [@pl.lit(@pl.AnyValue::Null) / @pl.lit_int(1L)]
  m["ls/div/str:a,str:b"] = [
    @pl.lit(@pl.AnyValue::String("a")) / @pl.lit(@pl.AnyValue::String("b")),
  ]
  m["ls/div/bool,bool"] = [
    @pl.lit(@pl.AnyValue::Boolean(true)) / @pl.lit(@pl.AnyValue::Boolean(false)),
  ]
  m["ls/div/date:1,date:2"] = [
    @pl.lit(@pl.AnyValue::Date(1)) / @pl.lit(@pl.AnyValue::Date(2)),
  ]
  m["ls/div/date:1,i1"] = [@pl.lit(@pl.AnyValue::Date(1)) / @pl.lit_int(1L)]
  m["ls/eq/i32:1,i2"] = [@pl.lit(@pl.AnyValue::Int32(1)).eq(@pl.lit_int(2L))]
  m["ls/eq/i32:1,i3e9"] = [
    @pl.lit(@pl.AnyValue::Int32(1)).eq(@pl.lit_int(3000000000L)),
  ]
  m["ls/eq/i2,i32:1"] = [@pl.lit_int(2L).eq(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["ls/eq/i64:1,i2"] = [@pl.lit(@pl.AnyValue::Int64(1L)).eq(@pl.lit_int(2L))]
  m["ls/eq/i32:1,f1.5"] = [
    @pl.lit(@pl.AnyValue::Int32(1)).eq(@pl.lit_float(1.5)),
  ]
  m["ls/eq/f32:1.5,i2"] = [
    @pl.lit(@pl.AnyValue::Float32(1.5)).eq(@pl.lit_int(2L)),
  ]
  m["ls/eq/f32:1.5,f1e300"] = [
    @pl.lit(@pl.AnyValue::Float32(1.5)).eq(@pl.lit_float(1.0e300)),
  ]
  m["ls/eq/f64:1.5,i2"] = [
    @pl.lit(@pl.AnyValue::Float64(1.5)).eq(@pl.lit_int(2L)),
  ]
  m["ls/eq/i32:1,i64:2"] = [
    @pl.lit(@pl.AnyValue::Int32(1)).eq(@pl.lit(@pl.AnyValue::Int64(2L))),
  ]
  m["ls/eq/i32:1,f32:2"] = [
    @pl.lit(@pl.AnyValue::Int32(1)).eq(@pl.lit(@pl.AnyValue::Float32(2.0))),
  ]
  m["ls/eq/f32:1,f64:2"] = [
    @pl.lit(@pl.AnyValue::Float32(1.0)).eq(@pl.lit(@pl.AnyValue::Float64(2.0))),
  ]
  m["ls/eq/null,i1"] = [@pl.lit(@pl.AnyValue::Null).eq(@pl.lit_int(1L))]
  m["ls/eq/i1,null"] = [@pl.lit_int(1L).eq(@pl.lit(@pl.AnyValue::Null))]
  m["ls/eq/null,f1.5"] = [@pl.lit(@pl.AnyValue::Null).eq(@pl.lit_float(1.5))]
  m["ls/eq/i32:null,i1"] = [@pl.lit(@pl.AnyValue::Null).eq(@pl.lit_int(1L))]
  m["ls/eq/str:a,str:b"] = [
    @pl.lit(@pl.AnyValue::String("a")).eq(@pl.lit(@pl.AnyValue::String("b"))),
  ]
}

///|
fn golden_expr_cases_17(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["ls/eq/bool,bool"] = [
    @pl.lit(@pl.AnyValue::Boolean(true)).eq(
      @pl.lit(@pl.AnyValue::Boolean(false)),
    ),
  ]
  m["ls/eq/date:1,date:2"] = [
    @pl.lit(@pl.AnyValue::Date(1)).eq(@pl.lit(@pl.AnyValue::Date(2))),
  ]
  m["ls/eq/date:1,i1"] = [@pl.lit(@pl.AnyValue::Date(1)).eq(@pl.lit_int(1L))]
  m["ls/lt/i32:1,i2"] = [@pl.lit(@pl.AnyValue::Int32(1)).lt(@pl.lit_int(2L))]
  m["ls/lt/i32:1,i3e9"] = [
    @pl.lit(@pl.AnyValue::Int32(1)).lt(@pl.lit_int(3000000000L)),
  ]
  m["ls/lt/i2,i32:1"] = [@pl.lit_int(2L).lt(@pl.lit(@pl.AnyValue::Int32(1)))]
  m["ls/lt/i64:1,i2"] = [@pl.lit(@pl.AnyValue::Int64(1L)).lt(@pl.lit_int(2L))]
  m["ls/lt/i32:1,f1.5"] = [
    @pl.lit(@pl.AnyValue::Int32(1)).lt(@pl.lit_float(1.5)),
  ]
  m["ls/lt/f32:1.5,i2"] = [
    @pl.lit(@pl.AnyValue::Float32(1.5)).lt(@pl.lit_int(2L)),
  ]
  m["ls/lt/f32:1.5,f1e300"] = [
    @pl.lit(@pl.AnyValue::Float32(1.5)).lt(@pl.lit_float(1.0e300)),
  ]
  m["ls/lt/f64:1.5,i2"] = [
    @pl.lit(@pl.AnyValue::Float64(1.5)).lt(@pl.lit_int(2L)),
  ]
  m["ls/lt/i32:1,i64:2"] = [
    @pl.lit(@pl.AnyValue::Int32(1)).lt(@pl.lit(@pl.AnyValue::Int64(2L))),
  ]
  m["ls/lt/i32:1,f32:2"] = [
    @pl.lit(@pl.AnyValue::Int32(1)).lt(@pl.lit(@pl.AnyValue::Float32(2.0))),
  ]
  m["ls/lt/f32:1,f64:2"] = [
    @pl.lit(@pl.AnyValue::Float32(1.0)).lt(@pl.lit(@pl.AnyValue::Float64(2.0))),
  ]
  m["ls/lt/null,i1"] = [@pl.lit(@pl.AnyValue::Null).lt(@pl.lit_int(1L))]
  m["ls/lt/i1,null"] = [@pl.lit_int(1L).lt(@pl.lit(@pl.AnyValue::Null))]
  m["ls/lt/null,f1.5"] = [@pl.lit(@pl.AnyValue::Null).lt(@pl.lit_float(1.5))]
  m["ls/lt/i32:null,i1"] = [@pl.lit(@pl.AnyValue::Null).lt(@pl.lit_int(1L))]
  m["ls/lt/str:a,str:b"] = [
    @pl.lit(@pl.AnyValue::String("a")).lt(@pl.lit(@pl.AnyValue::String("b"))),
  ]
  m["ls/lt/bool,bool"] = [
    @pl.lit(@pl.AnyValue::Boolean(true)).lt(
      @pl.lit(@pl.AnyValue::Boolean(false)),
    ),
  ]
  m["ls/lt/date:1,date:2"] = [
    @pl.lit(@pl.AnyValue::Date(1)).lt(@pl.lit(@pl.AnyValue::Date(2))),
  ]
  m["ls/lt/date:1,i1"] = [@pl.lit(@pl.AnyValue::Date(1)).lt(@pl.lit_int(1L))]
  m["ll/and/b,b"] = [@pl.lit_bool(true) & @pl.lit_bool(false)]
  m["ll/and/b,null"] = [@pl.lit_bool(true) & @pl.lit(@pl.AnyValue::Null)]
  m["ll/and/null,b"] = [@pl.lit(@pl.AnyValue::Null) & @pl.lit_bool(false)]
  m["ll/and/b,col"] = [@pl.lit_bool(true) & @pl.col("b")]
  m["ll/and/col,b"] = [@pl.col("b") & @pl.lit_bool(false)]
  m["ll/and/null,col"] = [@pl.lit(@pl.AnyValue::Null) & @pl.col("b")]
  m["ll/or/b,b"] = [@pl.lit_bool(true) | @pl.lit_bool(false)]
  m["ll/or/b,null"] = [@pl.lit_bool(true) | @pl.lit(@pl.AnyValue::Null)]
  m["ll/or/null,b"] = [@pl.lit(@pl.AnyValue::Null) | @pl.lit_bool(false)]
  m["ll/or/b,col"] = [@pl.lit_bool(true) | @pl.col("b")]
  m["ll/or/col,b"] = [@pl.col("b") | @pl.lit_bool(false)]
  m["ll/or/null,col"] = [@pl.lit(@pl.AnyValue::Null) | @pl.col("b")]
  m["weak/(1+2)+i32"] = [@pl.lit_int(1L) + @pl.lit_int(2L) + @pl.col("i32")]
  m["weak/(3e9+2)+i32"] = [
    @pl.lit_int(3000000000L) + @pl.lit_int(2L) + @pl.col("i32"),
  ]
  m["weak/(-1)+i32"] = [-@pl.lit_int(1L) + @pl.col("i32")]
  m["weak/i32+(-3e9)"] = [@pl.col("i32") + -@pl.lit_int(3000000000L)]
  m["weak/(1*2.5)+f32"] = [
    @pl.lit_int(1L) * @pl.lit_float(2.5) + @pl.col("f32"),
  ]
  m["weak/(1.5+1)+f32"] = [
    @pl.lit_float(1.5) + @pl.lit_int(1L) + @pl.col("f32"),
  ]
  m["weak/(1/2)+f32"] = [@pl.lit_int(1L) / @pl.lit_int(2L) + @pl.col("f32")]
  m["weak/(1.5/2.0)+f32"] = [
    @pl.lit_float(1.5) / @pl.lit_float(2.0) + @pl.col("f32"),
  ]
  m["weak/(1//2)+i32"] = [
    @pl.lit_int(1L).floor_div(@pl.lit_int(2L)) + @pl.col("i32"),
  ]
  m["weak/(7%4)+i32"] = [@pl.lit_int(7L) % @pl.lit_int(4L) + @pl.col("i32")]
  m["weak/(1+2.5)+i32"] = [
    @pl.lit_int(1L) + @pl.lit_float(2.5) + @pl.col("i32"),
  ]
  m["weak/i32+alias(1)"] = [@pl.col("i32") + @pl.lit_int(5L).alias("x")]
  m["weak/alias(3e9)+i32"] = [
    @pl.lit_int(3000000000L).alias("x") + @pl.col("i32"),
  ]
  m["weak/i32+cast(1,i64)"] = [
    @pl.col("i32") + @pl.lit_int(1L).cast(@pl.DataType::Int64),
  ]
  m["weak/i32+((1+2)==3)"] = [
    @pl.col("i32") + (@pl.lit_int(1L) + @pl.lit_int(2L)).eq(@pl.lit_int(3L)),
  ]
  m["weak/f32+(-1e300)"] = [@pl.col("f32") + -@pl.lit_float(1.0e300)]
  m["weak/f32*alias(1e300)"] = [
    @pl.col("f32") * @pl.lit_float(1.0e300).alias("x"),
  ]
  m["name/col"] = [@pl.col("i32")]
  m["name/lit+col"] = [@pl.lit_int(1L) + @pl.col("i32")]
  m["name/col+lit"] = [@pl.col("i32") + @pl.lit_int(1L)]
  m["name/col+col"] = [@pl.col("i64") + @pl.col("i32")]
  m["name/(lit+lit)+col"] = [@pl.lit_int(1L) + @pl.lit_int(2L) + @pl.col("i32")]
  m["name/-col"] = [-@pl.col("i32")]
  m["name/-(a+b)"] = [-(@pl.col("i64") + @pl.col("i32"))]
  m["name/~col"] = [@pl.col("b").not_()]
  m["name/~(a>0)"] = [@pl.col("i32").gt(@pl.lit_int(0L)).not_()]
}

///|
fn golden_expr_cases_18(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["name/cast"] = [@pl.col("i32").cast(@pl.DataType::Float64)]
  m["name/is_null"] = [@pl.col("f32").is_null()]
  m["name/alias"] = [@pl.col("i32").alias("z")]
  m["name/alias-alias"] = [@pl.col("i32").alias("a").alias("b")]
  m["name/alias-in-lhs"] = [@pl.col("i32").alias("a") + @pl.col("i64")]
  m["name/alias-in-rhs"] = [@pl.col("i32") + @pl.col("i64").alias("zz")]
  m["name/alias-over-op"] = [(@pl.col("i32") * @pl.lit_int(2L)).alias("twice")]
  m["name/alias-lit"] = [@pl.lit_int(1L).alias("one")]
  m["name/lit-alias+col"] = [@pl.lit_int(1L).alias("x") + @pl.col("i32")]
  m["name/is_null-alias"] = [
    @pl.col("i32").cast(@pl.DataType::Int32).alias("x").is_null(),
  ]
  m["name/alias-empty"] = [@pl.col("i32").alias("")]
  m["name/alias-unicode"] = [@pl.col("i32").alias("é😀")]
  m["name/alias-same"] = [@pl.col("i32").alias("i32")]
  m["name/alias-swap"] = [
    @pl.col("i32").alias("i64"),
    @pl.col("i64").alias("i32"),
  ]
  m["name/col-quote"] = [@pl.col("i32").alias("a\"b")]
  m["name/two-lits"] = [@pl.lit_int(1L), @pl.lit_int(2L).alias("x")]
  m["name/dup-col"] = [@pl.col("i32"), @pl.col("i32")]
  m["name/dup-alias"] = [@pl.col("i32"), @pl.col("i64").alias("i32")]
  m["name/dup-lit"] = [@pl.lit_int(1L), @pl.lit_int(2L)]
  m["name/dup-expr"] = [@pl.col("i32") + @pl.lit_int(1L), @pl.col("i32")]
  m["name/dup-alias2"] = [
    @pl.col("i32").alias("q"),
    @pl.col("i64").alias("q"),
    @pl.col("s"),
  ]
  m["name/missing"] = [@pl.col("zz")]
  m["name/missing-in-op"] = [@pl.col("i32") + @pl.col("zz")]
  m["name/missing-in-lit-op"] = [@pl.lit_int(1L) + @pl.col("zz")]
  m["name/missing-case"] = [@pl.col("I32")]
  m["name/missing-z0"] = [@pl.col("a")]
  m["name/missing-e0"] = [@pl.col("a")]
  m["name/missing-second"] = [@pl.col("i32"), @pl.col("zz")]
  m["prec/select/missing-then-width"] = [
    @pl.col("zz"),
    @pl.cols(["i32", "i64"]) + @pl.cols(["i32", "i64", "f32"]),
  ]
  m["prec/select/dup-before-missing"] = [
    @pl.col("i32"),
    @pl.col("i32"),
    @pl.col("zz"),
  ]
  m["prec/select/missing-before-dup"] = [
    @pl.col("zz"),
    @pl.col("i32"),
    @pl.col("i32"),
  ]
  m["prec/with_columns/missing-before-dup"] = [
    @pl.col("i32"),
    @pl.col("i32"),
    @pl.col("zz"),
  ]
  m["prec/select/z0-cols-before-col"] = [@pl.col("s"), @pl.cols(["qq"])]
  m["prec/select/kernel-then-missing"] = [
    @pl.col("s") + @pl.lit_int(1L),
    @pl.col("zz"),
  ]
  m["prec/select/dup-then-kernel"] = [
    @pl.col("i32"),
    @pl.col("i32"),
    @pl.col("s") + @pl.lit_int(1L),
  ]
  m["prec/select/missing-then-cols-missing"] = [@pl.col("zz"), @pl.cols(["qq"])]
  m["prec/select/all-empty+missing"] = [@pl.all() + @pl.col("i32").alias("x")]
  m["prec/select/missing+cols"] = [@pl.col("f32") + @pl.cols(["i32", "i64"])]
  m["prec/with_columns/kernel-then-missing"] = [
    @pl.col("s") + @pl.lit_int(1L),
    @pl.col("zz"),
  ]
  m["prec/with_columns/dup-then-kernel"] = [
    @pl.col("i32"),
    @pl.col("i32"),
    @pl.col("s") + @pl.lit_int(1L),
  ]
  m["prec/with_columns/missing-then-cols-missing"] = [
    @pl.col("zz"),
    @pl.cols(["qq"]),
  ]
  m["prec/with_columns/all-empty+missing"] = [
    @pl.all() + @pl.col("i32").alias("x"),
  ]
  m["cols/basic"] = [@pl.cols(["i32", "i64"])]
  m["cols/single"] = [@pl.cols(["i32"])]
  m["cols/empty"] = [@pl.cols([])]
  m["cols/empty-z0"] = [@pl.cols([])]
  m["cols/empty+col"] = [@pl.cols([]) + @pl.col("i32")]
  m["cols/empty+lit"] = [@pl.cols([]) + @pl.lit_int(1L)]
  m["cols/empty+lit2"] = [@pl.cols([]), @pl.lit_int(1L)]
  m["cols/order"] = [@pl.cols(["f32", "i32", "i64"])]
  m["cols/dup-names"] = [@pl.cols(["i32", "i32", "i64"])]
  m["cols/+1"] = [@pl.cols(["i32", "i64", "f32", "f64"]) + @pl.lit_int(1L)]
  m["cols/*1.5"] = [@pl.cols(["i32", "i64", "f32", "f64"]) * @pl.lit_float(1.5)]
  m["cols/3e9"] = [@pl.cols(["i32", "i64", "f32"]) + @pl.lit_int(3000000000L)]
  m["cols/lit+"] = [@pl.lit_int(1L) + @pl.cols(["i32"])]
  m["cols/lit+2"] = [@pl.lit_int(1L) + @pl.cols(["i32", "i64"])]
  m["cols/zip"] = [@pl.cols(["i32", "i64"]) + @pl.cols(["i64", "i32"])]
  m["cols/zip-names"] = [@pl.cols(["i64", "i32"]) + @pl.cols(["i32", "i64"])]
  m["cols/zip3"] = [@pl.cols(["i32", "i64"]) + @pl.cols(["i64", "i32", "f32"])]
  m["cols/zip-cmp"] = [@pl.cols(["i32", "i64"]).lt(@pl.cols(["i64", "f64"]))]
}

///|
fn golden_expr_cases_19(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cols/x-col"] = [@pl.cols(["i32", "i64"]) + @pl.col("i32")]
  m["cols/col-x"] = [@pl.col("i32") + @pl.cols(["i32", "i64"])]
  m["cols/col-x-alias"] = [@pl.col("f32") + @pl.cols(["i32", "i64"]).alias("q")]
  m["cols/self"] = [@pl.cols(["i32", "i64"]) * @pl.cols(["i32", "i64"])]
  m["cols/alias"] = [@pl.cols(["i32", "i64"]).alias("z")]
  m["cols/alias-single"] = [@pl.cols(["i32"]).alias("z")]
  m["cols/cast"] = [@pl.cols(["i32", "i64"]).cast(@pl.DataType::Float64)]
  m["cols/cast-ns"] = [
    @pl.cols(["i64"]).cast(@pl.DataType::Int32, strict=false),
  ]
  m["cols/is_null"] = [@pl.cols(["i32", "s", "n"]).is_null()]
  m["cols/neg"] = [-@pl.cols(["i32", "i64", "f32"])]
  m["cols/not"] = [@pl.cols(["b"]).not_()]
  m["cols/missing"] = [@pl.cols(["i32", "zz"])]
  m["cols/missing-first"] = [@pl.cols(["zz", "yy"])]
  m["cols/missing-z0"] = [@pl.cols(["a"])]
  m["cols/+cols-other"] = [@pl.cols(["i32"]), @pl.cols(["i64"])]
  m["cols/overlap"] = [@pl.cols(["i32", "i64"]), @pl.cols(["i64", "f32"])]
  m["cols/and-all"] = [
    @pl.cols(["i32", "i64"]).lt(@pl.lit_int(5L)),
    @pl.col("s"),
  ]
  m["cols/str"] = [@pl.cols(["s", "b"])]
  m["cols/quoted"] = [@pl.cols(["i32"]).alias("q'q")]
  m["cols/restricted"] = [@pl.cols(["i32", "s"]) + @pl.lit_int(1L)]
  m["all/t"] = [@pl.all()]
  m["all/num"] = [@pl.all()]
  m["all/num+1"] = [@pl.all() + @pl.lit_int(1L)]
  m["all/num+3e9"] = [@pl.all() + @pl.lit_int(3000000000L)]
  m["all/num*1.5"] = [@pl.all() * @pl.lit_float(1.5)]
  m["all/num-self"] = [@pl.all() - @pl.all()]
  m["all/num-neg"] = [-@pl.all()]
  m["all/num-cast"] = [@pl.all().cast(@pl.DataType::Float64)]
  m["all/num-alias"] = [@pl.all().alias("x")]
  m["all/num-is_null"] = [@pl.all().is_null()]
  m["all/num+lit"] = [@pl.all(), @pl.lit_int(1L)]
  m["all/num+lit-alias"] = [@pl.all(), @pl.lit_int(1L).alias("one")]
  m["all/num+all"] = [@pl.all(), @pl.all()]
  m["all/num+col"] = [@pl.all(), @pl.col("i32")]
  m["all/num+col-alias"] = [@pl.all(), @pl.col("i32").alias("q")]
  m["all/num+ops"] = [@pl.all() + @pl.col("i32")]
  m["all/num-lt"] = [@pl.all().lt(@pl.lit_int(1L))]
  m["all/z0"] = [@pl.all()]
  m["all/z0+lit"] = [@pl.all(), @pl.lit_int(1L)]
  m["all/z0+op"] = [@pl.all() + @pl.lit_int(1L)]
  m["all/e0"] = [@pl.all()]
  m["all/e0+lit"] = [@pl.all(), @pl.lit_int(1L)]
  m["all/e0+op"] = [@pl.all() + @pl.lit_int(1L)]
  m["all/t+1"] = [@pl.all() + @pl.lit_int(1L)]
  m["all/t-is_null"] = [@pl.all().is_null()]
  m["all/t-cast-str"] = [@pl.all().cast(@pl.DataType::String)]
  m["shape/select-lit/t"] = [@pl.lit_int(1L)]
  m["shape/select-lit-lit/t"] = [@pl.lit_int(1L), @pl.lit_int(2L).alias("x")]
  m["shape/select-lit-lit-lit/t"] = [
    @pl.lit_int(1L),
    @pl.lit_str("x").alias("x"),
    @pl.lit(@pl.AnyValue::Null).alias("y"),
  ]
  m["shape/select-empty/t"] = []
  m["shape/wc-empty/t"] = []
  m["shape/wc-lit/t"] = [@pl.lit_int(1L)]
  m["shape/wc-lit-lit/t"] = [@pl.lit_int(1L), @pl.lit_str("x").alias("x")]
  m["shape/wc-lit-null/t"] = [@pl.lit(@pl.AnyValue::Null)]
  m["shape/wc-lit-alias/t"] = [
    @pl.lit_float(1.5).alias("x"),
    @pl.lit(@pl.AnyValue::Int32(4)).alias("y"),
  ]
  m["shape/select-lit/e0"] = [@pl.lit_int(1L)]
  m["shape/select-lit-lit/e0"] = [@pl.lit_int(1L), @pl.lit_int(2L).alias("x")]
  m["shape/select-lit-lit-lit/e0"] = [
    @pl.lit_int(1L),
    @pl.lit_str("x").alias("x"),
    @pl.lit(@pl.AnyValue::Null).alias("y"),
  ]
  m["shape/select-empty/e0"] = []
  m["shape/wc-empty/e0"] = []
}

///|
fn golden_expr_cases_20(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["shape/wc-lit/e0"] = [@pl.lit_int(1L)]
  m["shape/wc-lit-lit/e0"] = [@pl.lit_int(1L), @pl.lit_str("x").alias("x")]
  m["shape/wc-lit-null/e0"] = [@pl.lit(@pl.AnyValue::Null)]
  m["shape/wc-lit-alias/e0"] = [
    @pl.lit_float(1.5).alias("x"),
    @pl.lit(@pl.AnyValue::Int32(4)).alias("y"),
  ]
  m["shape/select-lit/z0"] = [@pl.lit_int(1L)]
  m["shape/select-lit-lit/z0"] = [@pl.lit_int(1L), @pl.lit_int(2L).alias("x")]
  m["shape/select-lit-lit-lit/z0"] = [
    @pl.lit_int(1L),
    @pl.lit_str("x").alias("x"),
    @pl.lit(@pl.AnyValue::Null).alias("y"),
  ]
  m["shape/select-empty/z0"] = []
  m["shape/wc-empty/z0"] = []
  m["shape/wc-lit/z0"] = [@pl.lit_int(1L)]
  m["shape/wc-lit-lit/z0"] = [@pl.lit_int(1L), @pl.lit_str("x").alias("x")]
  m["shape/wc-lit-null/z0"] = [@pl.lit(@pl.AnyValue::Null)]
  m["shape/wc-lit-alias/z0"] = [
    @pl.lit_float(1.5).alias("x"),
    @pl.lit(@pl.AnyValue::Int32(4)).alias("y"),
  ]
  m["shape/select-col-lit/t"] = [@pl.col("i32"), @pl.lit_int(1L)]
  m["shape/select-lit-col/t"] = [@pl.lit_int(1L), @pl.col("i32")]
  m["shape/select-col-lit-col/t"] = [
    @pl.col("i32"),
    @pl.lit_int(7L).alias("k"),
    @pl.col("s"),
  ]
  m["shape/select-lit-expr/t"] = [
    @pl.col("i32") + @pl.lit_int(1L),
    @pl.lit_float(2.5).alias("k"),
  ]
  m["shape/select-reorder/t"] = [@pl.col("s"), @pl.col("i32")]
  m["shape/select-is_null-lit/t"] = [
    @pl.lit_int(1L).is_null(),
    @pl.col("i32").is_not_null().alias("nn"),
  ]
  m["shape/select-lit-cmp/t"] = [
    @pl.lit_int(1L).lt(@pl.lit_int(2L)),
    @pl.col("b").alias("bb"),
  ]
  m["shape/select-lit-op-col/t"] = [@pl.lit_int(1L) + @pl.col("i32")]
  m["shape/select-lit+lit/t"] = [@pl.lit_int(1L) + @pl.lit_int(2L)]
  m["shape/wc-replace/t"] = [@pl.col("i32") + @pl.lit_int(1L)]
  m["shape/wc-replace-mid/t"] = [
    (@pl.col("i64") * @pl.lit_int(2L)).alias("i32"),
    @pl.lit_str("x").alias("new"),
  ]
  m["shape/wc-append/t"] = [(@pl.col("i32") + @pl.col("i64")).alias("sum")]
  m["shape/wc-append-2/t"] = [
    @pl.lit_int(1L).alias("one"),
    (@pl.col("i32") + @pl.lit_int(1L)).alias("i32p"),
  ]
  m["shape/wc-replace-all/t"] = [
    @pl.lit_int(0L).alias("i32"),
    @pl.lit_int(0L).alias("s"),
    @pl.lit_int(0L).alias("n"),
  ]
  m["shape/wc-cols/t"] = [@pl.cols(["i32", "i64"]) * @pl.lit_int(2L)]
  m["shape/wc-cast/t"] = [
    @pl.col("i32").cast(@pl.DataType::Float64),
    @pl.col("i64").cast(@pl.DataType::Int32, strict=false),
  ]
  m["shape/wc-dup/t"] = [@pl.col("i32").alias("q"), @pl.col("i64").alias("q")]
  m["shape/wc-dup-col/t"] = [@pl.col("i32"), @pl.col("i32")]
  m["shape/wc-missing/t"] = [@pl.col("zz")]
  m["shape/wc-swap/t"] = [
    @pl.col("i32").alias("i64"),
    @pl.col("i64").alias("i32"),
  ]
  m["shape/wc-self-ref/t"] = [
    (@pl.col("i32") + @pl.lit_int(1L)).alias("i32"),
    (@pl.col("i32") + @pl.lit_int(2L)).alias("i32b"),
  ]
  m["shape/select-col-lit/e0"] = [@pl.col("i32"), @pl.lit_int(1L)]
  m["shape/select-lit-col/e0"] = [@pl.lit_int(1L), @pl.col("i32")]
  m["shape/select-col-lit-col/e0"] = [
    @pl.col("i32"),
    @pl.lit_int(7L).alias("k"),
    @pl.col("s"),
  ]
  m["shape/select-lit-expr/e0"] = [
    @pl.col("i32") + @pl.lit_int(1L),
    @pl.lit_float(2.5).alias("k"),
  ]
  m["shape/select-reorder/e0"] = [@pl.col("s"), @pl.col("i32")]
  m["shape/select-is_null-lit/e0"] = [
    @pl.lit_int(1L).is_null(),
    @pl.col("i32").is_not_null().alias("nn"),
  ]
  m["shape/select-lit-cmp/e0"] = [
    @pl.lit_int(1L).lt(@pl.lit_int(2L)),
    @pl.col("b").alias("bb"),
  ]
  m["shape/select-lit-op-col/e0"] = [@pl.lit_int(1L) + @pl.col("i32")]
  m["shape/select-lit+lit/e0"] = [@pl.lit_int(1L) + @pl.lit_int(2L)]
  m["shape/wc-replace/e0"] = [@pl.col("i32") + @pl.lit_int(1L)]
  m["shape/wc-replace-mid/e0"] = [
    (@pl.col("i64") * @pl.lit_int(2L)).alias("i32"),
    @pl.lit_str("x").alias("new"),
  ]
  m["shape/wc-append/e0"] = [(@pl.col("i32") + @pl.col("i64")).alias("sum")]
  m["shape/wc-append-2/e0"] = [
    @pl.lit_int(1L).alias("one"),
    (@pl.col("i32") + @pl.lit_int(1L)).alias("i32p"),
  ]
  m["shape/wc-replace-all/e0"] = [
    @pl.lit_int(0L).alias("i32"),
    @pl.lit_int(0L).alias("s"),
    @pl.lit_int(0L).alias("n"),
  ]
  m["shape/wc-cols/e0"] = [@pl.cols(["i32", "i64"]) * @pl.lit_int(2L)]
  m["shape/wc-cast/e0"] = [
    @pl.col("i32").cast(@pl.DataType::Float64),
    @pl.col("i64").cast(@pl.DataType::Int32, strict=false),
  ]
  m["shape/wc-dup/e0"] = [@pl.col("i32").alias("q"), @pl.col("i64").alias("q")]
  m["shape/wc-dup-col/e0"] = [@pl.col("i32"), @pl.col("i32")]
  m["shape/wc-missing/e0"] = [@pl.col("zz")]
  m["shape/wc-swap/e0"] = [
    @pl.col("i32").alias("i64"),
    @pl.col("i64").alias("i32"),
  ]
  m["shape/wc-self-ref/e0"] = [
    (@pl.col("i32") + @pl.lit_int(1L)).alias("i32"),
    (@pl.col("i32") + @pl.lit_int(2L)).alias("i32b"),
  ]
  m["shape/wc-all/num"] = [@pl.all()]
  m["shape/wc-all+1/num"] = [@pl.all() + @pl.lit_int(1L)]
  m["shape/wc-all+lit/num"] = [@pl.all(), @pl.lit_int(1L)]
  m["shape/wc-all-alias/num"] = [@pl.all().alias("x")]
  m["shape/z0-select-all-lit"] = [@pl.all(), @pl.lit_int(1L).alias("k")]
}

///|
fn golden_expr_cases_21(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["shape/z0-select-all-and-lit-expr"] = [@pl.lit_int(1L) + @pl.lit_int(2L)]
  m["shape/num-select-lit-first"] = [@pl.lit_int(1L).alias("k"), @pl.all()]
  m["shape/num-select-1-row"] = [@pl.lit_int(1L).alias("k")]
  m["cast/i32->bool/strict"] = [@pl.col("i32").cast(@pl.DataType::Boolean)]
  m["cast/i32->bool/lenient"] = [
    @pl.col("i32").cast(@pl.DataType::Boolean, strict=false),
  ]
  m["cast/i32->i32/strict"] = [@pl.col("i32").cast(@pl.DataType::Int32)]
  m["cast/i32->i32/lenient"] = [
    @pl.col("i32").cast(@pl.DataType::Int32, strict=false),
  ]
  m["cast/i32->i64/strict"] = [@pl.col("i32").cast(@pl.DataType::Int64)]
  m["cast/i32->i64/lenient"] = [
    @pl.col("i32").cast(@pl.DataType::Int64, strict=false),
  ]
  m["cast/i32->f32/strict"] = [@pl.col("i32").cast(@pl.DataType::Float32)]
  m["cast/i32->f32/lenient"] = [
    @pl.col("i32").cast(@pl.DataType::Float32, strict=false),
  ]
  m["cast/i32->f64/strict"] = [@pl.col("i32").cast(@pl.DataType::Float64)]
  m["cast/i32->f64/lenient"] = [
    @pl.col("i32").cast(@pl.DataType::Float64, strict=false),
  ]
  m["cast/i32->str/strict"] = [@pl.col("i32").cast(@pl.DataType::String)]
  m["cast/i32->str/lenient"] = [
    @pl.col("i32").cast(@pl.DataType::String, strict=false),
  ]
  m["cast/i32->date/strict"] = [@pl.col("i32").cast(@pl.DataType::Date)]
  m["cast/i32->date/lenient"] = [
    @pl.col("i32").cast(@pl.DataType::Date, strict=false),
  ]
  m["cast/i32->datetime[μs]/strict"] = [
    @pl.col("i32").cast(@pl.DataType::Datetime),
  ]
  m["cast/i32->datetime[μs]/lenient"] = [
    @pl.col("i32").cast(@pl.DataType::Datetime, strict=false),
  ]
  m["cast/i32->null/strict"] = [@pl.col("i32").cast(@pl.DataType::Null)]
  m["cast/i32->null/lenient"] = [
    @pl.col("i32").cast(@pl.DataType::Null, strict=false),
  ]
  m["cast/i64->bool/strict"] = [@pl.col("i64").cast(@pl.DataType::Boolean)]
  m["cast/i64->bool/lenient"] = [
    @pl.col("i64").cast(@pl.DataType::Boolean, strict=false),
  ]
  m["cast/i64->i32/strict"] = [@pl.col("i64").cast(@pl.DataType::Int32)]
  m["cast/i64->i32/lenient"] = [
    @pl.col("i64").cast(@pl.DataType::Int32, strict=false),
  ]
  m["cast/i64->i64/strict"] = [@pl.col("i64").cast(@pl.DataType::Int64)]
  m["cast/i64->i64/lenient"] = [
    @pl.col("i64").cast(@pl.DataType::Int64, strict=false),
  ]
  m["cast/i64->f32/strict"] = [@pl.col("i64").cast(@pl.DataType::Float32)]
  m["cast/i64->f32/lenient"] = [
    @pl.col("i64").cast(@pl.DataType::Float32, strict=false),
  ]
  m["cast/i64->f64/strict"] = [@pl.col("i64").cast(@pl.DataType::Float64)]
  m["cast/i64->f64/lenient"] = [
    @pl.col("i64").cast(@pl.DataType::Float64, strict=false),
  ]
  m["cast/i64->str/strict"] = [@pl.col("i64").cast(@pl.DataType::String)]
  m["cast/i64->str/lenient"] = [
    @pl.col("i64").cast(@pl.DataType::String, strict=false),
  ]
  m["cast/i64->date/strict"] = [@pl.col("i64").cast(@pl.DataType::Date)]
  m["cast/i64->date/lenient"] = [
    @pl.col("i64").cast(@pl.DataType::Date, strict=false),
  ]
  m["cast/i64->datetime[μs]/strict"] = [
    @pl.col("i64").cast(@pl.DataType::Datetime),
  ]
  m["cast/i64->datetime[μs]/lenient"] = [
    @pl.col("i64").cast(@pl.DataType::Datetime, strict=false),
  ]
  m["cast/i64->null/strict"] = [@pl.col("i64").cast(@pl.DataType::Null)]
  m["cast/i64->null/lenient"] = [
    @pl.col("i64").cast(@pl.DataType::Null, strict=false),
  ]
  m["cast/f32->bool/strict"] = [@pl.col("f32").cast(@pl.DataType::Boolean)]
  m["cast/f32->bool/lenient"] = [
    @pl.col("f32").cast(@pl.DataType::Boolean, strict=false),
  ]
  m["cast/f32->i64/strict"] = [@pl.col("f32").cast(@pl.DataType::Int64)]
  m["cast/f32->i64/lenient"] = [
    @pl.col("f32").cast(@pl.DataType::Int64, strict=false),
  ]
  m["cast/f32->f64/strict"] = [@pl.col("f32").cast(@pl.DataType::Float64)]
  m["cast/f32->f64/lenient"] = [
    @pl.col("f32").cast(@pl.DataType::Float64, strict=false),
  ]
  m["cast/f32->str/strict"] = [@pl.col("f32").cast(@pl.DataType::String)]
  m["cast/f32->str/lenient"] = [
    @pl.col("f32").cast(@pl.DataType::String, strict=false),
  ]
  m["cast/f32->date/strict"] = [@pl.col("f32").cast(@pl.DataType::Date)]
  m["cast/f32->date/lenient"] = [
    @pl.col("f32").cast(@pl.DataType::Date, strict=false),
  ]
  m["cast/f64->bool/strict"] = [@pl.col("f64").cast(@pl.DataType::Boolean)]
  m["cast/f64->bool/lenient"] = [
    @pl.col("f64").cast(@pl.DataType::Boolean, strict=false),
  ]
  m["cast/f64->i32/strict"] = [@pl.col("f64").cast(@pl.DataType::Int32)]
  m["cast/f64->i32/lenient"] = [
    @pl.col("f64").cast(@pl.DataType::Int32, strict=false),
  ]
  m["cast/f64->i64/strict"] = [@pl.col("f64").cast(@pl.DataType::Int64)]
  m["cast/f64->i64/lenient"] = [
    @pl.col("f64").cast(@pl.DataType::Int64, strict=false),
  ]
  m["cast/f64->f32/strict"] = [@pl.col("f64").cast(@pl.DataType::Float32)]
  m["cast/f64->f32/lenient"] = [
    @pl.col("f64").cast(@pl.DataType::Float32, strict=false),
  ]
  m["cast/f64->f64/strict"] = [@pl.col("f64").cast(@pl.DataType::Float64)]
  m["cast/f64->f64/lenient"] = [
    @pl.col("f64").cast(@pl.DataType::Float64, strict=false),
  ]
  m["cast/f64->str/strict"] = [@pl.col("f64").cast(@pl.DataType::String)]
}

///|
fn golden_expr_cases_22(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cast/f64->str/lenient"] = [
    @pl.col("f64").cast(@pl.DataType::String, strict=false),
  ]
  m["cast/f64->date/strict"] = [@pl.col("f64").cast(@pl.DataType::Date)]
  m["cast/f64->date/lenient"] = [
    @pl.col("f64").cast(@pl.DataType::Date, strict=false),
  ]
  m["cast/f64->datetime[μs]/strict"] = [
    @pl.col("f64").cast(@pl.DataType::Datetime),
  ]
  m["cast/f64->datetime[μs]/lenient"] = [
    @pl.col("f64").cast(@pl.DataType::Datetime, strict=false),
  ]
  m["cast/f64->null/strict"] = [@pl.col("f64").cast(@pl.DataType::Null)]
  m["cast/f64->null/lenient"] = [
    @pl.col("f64").cast(@pl.DataType::Null, strict=false),
  ]
  m["cast/s->bool/strict"] = [@pl.col("s").cast(@pl.DataType::Boolean)]
  m["cast/s->bool/lenient"] = [
    @pl.col("s").cast(@pl.DataType::Boolean, strict=false),
  ]
  m["cast/s->i32/strict"] = [@pl.col("s").cast(@pl.DataType::Int32)]
  m["cast/s->i32/lenient"] = [
    @pl.col("s").cast(@pl.DataType::Int32, strict=false),
  ]
  m["cast/s->i64/strict"] = [@pl.col("s").cast(@pl.DataType::Int64)]
  m["cast/s->i64/lenient"] = [
    @pl.col("s").cast(@pl.DataType::Int64, strict=false),
  ]
  m["cast/s->f32/strict"] = [@pl.col("s").cast(@pl.DataType::Float32)]
  m["cast/s->f32/lenient"] = [
    @pl.col("s").cast(@pl.DataType::Float32, strict=false),
  ]
  m["cast/s->f64/strict"] = [@pl.col("s").cast(@pl.DataType::Float64)]
  m["cast/s->f64/lenient"] = [
    @pl.col("s").cast(@pl.DataType::Float64, strict=false),
  ]
  m["cast/s->str/strict"] = [@pl.col("s").cast(@pl.DataType::String)]
  m["cast/s->str/lenient"] = [
    @pl.col("s").cast(@pl.DataType::String, strict=false),
  ]
  m["cast/s->date/strict"] = [@pl.col("s").cast(@pl.DataType::Date)]
  m["cast/s->date/lenient"] = [
    @pl.col("s").cast(@pl.DataType::Date, strict=false),
  ]
  m["cast/s->datetime[μs]/strict"] = [
    @pl.col("s").cast(@pl.DataType::Datetime),
  ]
  m["cast/s->datetime[μs]/lenient"] = [
    @pl.col("s").cast(@pl.DataType::Datetime, strict=false),
  ]
  m["cast/s->null/strict"] = [@pl.col("s").cast(@pl.DataType::Null)]
  m["cast/s->null/lenient"] = [
    @pl.col("s").cast(@pl.DataType::Null, strict=false),
  ]
  m["cast/b->bool/strict"] = [@pl.col("b").cast(@pl.DataType::Boolean)]
  m["cast/b->bool/lenient"] = [
    @pl.col("b").cast(@pl.DataType::Boolean, strict=false),
  ]
  m["cast/b->i64/strict"] = [@pl.col("b").cast(@pl.DataType::Int64)]
  m["cast/b->i64/lenient"] = [
    @pl.col("b").cast(@pl.DataType::Int64, strict=false),
  ]
  m["cast/b->f64/strict"] = [@pl.col("b").cast(@pl.DataType::Float64)]
  m["cast/b->f64/lenient"] = [
    @pl.col("b").cast(@pl.DataType::Float64, strict=false),
  ]
  m["cast/b->str/strict"] = [@pl.col("b").cast(@pl.DataType::String)]
  m["cast/b->str/lenient"] = [
    @pl.col("b").cast(@pl.DataType::String, strict=false),
  ]
  m["cast/b->date/strict"] = [@pl.col("b").cast(@pl.DataType::Date)]
  m["cast/b->date/lenient"] = [
    @pl.col("b").cast(@pl.DataType::Date, strict=false),
  ]
  m["cast/d->bool/strict"] = [@pl.col("d").cast(@pl.DataType::Boolean)]
  m["cast/d->bool/lenient"] = [
    @pl.col("d").cast(@pl.DataType::Boolean, strict=false),
  ]
  m["cast/d->i64/strict"] = [@pl.col("d").cast(@pl.DataType::Int64)]
  m["cast/d->i64/lenient"] = [
    @pl.col("d").cast(@pl.DataType::Int64, strict=false),
  ]
  m["cast/d->f64/strict"] = [@pl.col("d").cast(@pl.DataType::Float64)]
  m["cast/d->f64/lenient"] = [
    @pl.col("d").cast(@pl.DataType::Float64, strict=false),
  ]
  m["cast/d->str/strict"] = [@pl.col("d").cast(@pl.DataType::String)]
  m["cast/d->str/lenient"] = [
    @pl.col("d").cast(@pl.DataType::String, strict=false),
  ]
  m["cast/d->date/strict"] = [@pl.col("d").cast(@pl.DataType::Date)]
  m["cast/d->date/lenient"] = [
    @pl.col("d").cast(@pl.DataType::Date, strict=false),
  ]
  m["cast/dt->bool/strict"] = [@pl.col("dt").cast(@pl.DataType::Boolean)]
  m["cast/dt->bool/lenient"] = [
    @pl.col("dt").cast(@pl.DataType::Boolean, strict=false),
  ]
  m["cast/dt->i64/strict"] = [@pl.col("dt").cast(@pl.DataType::Int64)]
  m["cast/dt->i64/lenient"] = [
    @pl.col("dt").cast(@pl.DataType::Int64, strict=false),
  ]
  m["cast/dt->f64/strict"] = [@pl.col("dt").cast(@pl.DataType::Float64)]
  m["cast/dt->f64/lenient"] = [
    @pl.col("dt").cast(@pl.DataType::Float64, strict=false),
  ]
  m["cast/dt->str/strict"] = [@pl.col("dt").cast(@pl.DataType::String)]
  m["cast/dt->str/lenient"] = [
    @pl.col("dt").cast(@pl.DataType::String, strict=false),
  ]
  m["cast/dt->date/strict"] = [@pl.col("dt").cast(@pl.DataType::Date)]
  m["cast/dt->date/lenient"] = [
    @pl.col("dt").cast(@pl.DataType::Date, strict=false),
  ]
  m["cast/n->bool/strict"] = [@pl.col("n").cast(@pl.DataType::Boolean)]
  m["cast/n->bool/lenient"] = [
    @pl.col("n").cast(@pl.DataType::Boolean, strict=false),
  ]
  m["cast/n->i64/strict"] = [@pl.col("n").cast(@pl.DataType::Int64)]
  m["cast/n->i64/lenient"] = [
    @pl.col("n").cast(@pl.DataType::Int64, strict=false),
  ]
  m["cast/n->f64/strict"] = [@pl.col("n").cast(@pl.DataType::Float64)]
}

///|
fn golden_expr_cases_23(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["cast/n->f64/lenient"] = [
    @pl.col("n").cast(@pl.DataType::Float64, strict=false),
  ]
  m["cast/n->str/strict"] = [@pl.col("n").cast(@pl.DataType::String)]
  m["cast/n->str/lenient"] = [
    @pl.col("n").cast(@pl.DataType::String, strict=false),
  ]
  m["cast/n->date/strict"] = [@pl.col("n").cast(@pl.DataType::Date)]
  m["cast/n->date/lenient"] = [
    @pl.col("n").cast(@pl.DataType::Date, strict=false),
  ]
  m["cast/lit-int->f64"] = [@pl.lit_int(1L).cast(@pl.DataType::Float64)]
  m["cast/lit-int->i32"] = [
    @pl.lit_int(3000000000L).cast(@pl.DataType::Int32, strict=false),
  ]
  m["cast/lit-str->i32-lenient"] = [
    @pl.lit_str("a").cast(@pl.DataType::Int32, strict=false),
  ]
  m["cast/lit-float->i32"] = [@pl.lit_float(1.9).cast(@pl.DataType::Int32)]
  m["cast/lit-null->i32"] = [
    @pl.lit(@pl.AnyValue::Null).cast(@pl.DataType::Int32),
  ]
  m["cast/cast-cast"] = [
    @pl.col("i32").cast(@pl.DataType::Float32).cast(@pl.DataType::Int64),
  ]
  m["cast/in-op"] = [@pl.col("i32").cast(@pl.DataType::Int64) + @pl.col("i32")]
  m["cast/in-op-lit"] = [
    @pl.col("i32").cast(@pl.DataType::Float32) + @pl.lit_int(1L),
  ]
  m["cast/in-op-lit-f"] = [
    @pl.col("i32").cast(@pl.DataType::Float32) * @pl.lit_float(1.0e300),
  ]
  m["cast/lit-cast-op"] = [
    @pl.col("i32") + @pl.lit_int(1L).cast(@pl.DataType::Int64),
  ]
  m["cast/lit-cast-op2"] = [
    @pl.col("i32") + @pl.lit_int(1L).cast(@pl.DataType::Float32),
  ]
  m["cast/alias"] = [@pl.col("i32").cast(@pl.DataType::Float64).alias("x")]
  m["cast/z0-lit"] = [@pl.lit_int(1L).cast(@pl.DataType::Float64)]
  m["cast/e0"] = [
    @pl.col("i32").cast(@pl.DataType::Float64),
    @pl.col("s").cast(@pl.DataType::Int64, strict=false),
  ]
  m["cast/i64-big"] = [@pl.col("i64").cast(@pl.DataType::Int32)]
  m["cast/f64-nan->i64"] = [@pl.col("f64").cast(@pl.DataType::Int64)]
  m["cast/f64-nan->i64-lenient"] = [
    @pl.col("f64").cast(@pl.DataType::Int64, strict=false),
  ]
  m["cast/s->f64"] = [@pl.col("s").cast(@pl.DataType::Float64)]
  m["null/is_null/i32"] = [@pl.col("i32").is_null()]
  m["null/is_not_null/i32"] = [@pl.col("i32").is_not_null()]
  m["null/is_null/i32/e0"] = [@pl.col("i32").is_null()]
  m["null/is_null/i64"] = [@pl.col("i64").is_null()]
  m["null/is_not_null/i64"] = [@pl.col("i64").is_not_null()]
  m["null/is_null/i64/e0"] = [@pl.col("i64").is_null()]
  m["null/is_null/f32"] = [@pl.col("f32").is_null()]
  m["null/is_not_null/f32"] = [@pl.col("f32").is_not_null()]
  m["null/is_null/f32/e0"] = [@pl.col("f32").is_null()]
  m["null/is_null/f64"] = [@pl.col("f64").is_null()]
  m["null/is_not_null/f64"] = [@pl.col("f64").is_not_null()]
  m["null/is_null/f64/e0"] = [@pl.col("f64").is_null()]
  m["null/is_null/s"] = [@pl.col("s").is_null()]
  m["null/is_not_null/s"] = [@pl.col("s").is_not_null()]
  m["null/is_null/s/e0"] = [@pl.col("s").is_null()]
  m["null/is_null/b"] = [@pl.col("b").is_null()]
  m["null/is_not_null/b"] = [@pl.col("b").is_not_null()]
  m["null/is_null/b/e0"] = [@pl.col("b").is_null()]
  m["null/is_null/d"] = [@pl.col("d").is_null()]
  m["null/is_not_null/d"] = [@pl.col("d").is_not_null()]
  m["null/is_null/d/e0"] = [@pl.col("d").is_null()]
  m["null/is_null/dt"] = [@pl.col("dt").is_null()]
  m["null/is_not_null/dt"] = [@pl.col("dt").is_not_null()]
  m["null/is_null/dt/e0"] = [@pl.col("dt").is_null()]
  m["null/is_null/n"] = [@pl.col("n").is_null()]
  m["null/is_not_null/n"] = [@pl.col("n").is_not_null()]
  m["null/is_null/n/e0"] = [@pl.col("n").is_null()]
  m["null/is_null-op"] = [(@pl.col("i32") + @pl.lit_int(1L)).is_null()]
  m["null/is_null-cmp"] = [@pl.col("f32").lt(@pl.col("i32")).is_null()]
  m["null/not-is_null"] = [@pl.col("i32").is_null().not_()]
  m["null/is_null-nan"] = [
    @pl.col("f64").is_null(),
    @pl.col("f64").eq(@pl.col("f64")).alias("eq"),
  ]
  m["null/is_null-lit"] = [
    @pl.lit(@pl.AnyValue::Null).is_null(),
    @pl.lit(@pl.AnyValue::Null).is_not_null().alias("nn"),
  ]
  m["null/is_null-cols"] = [@pl.cols(["i32", "n"]).is_not_null()]
  m["null/is_null-z0"] = [@pl.lit_int(1L).is_null()]
  m["unary/neg/i32"] = [-@pl.col("i32")]
  m["unary/not/i32"] = [@pl.col("i32").not_()]
  m["unary/neg/i64"] = [-@pl.col("i64")]
}

///|
fn golden_expr_cases_24(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["unary/not/i64"] = [@pl.col("i64").not_()]
  m["unary/neg/f32"] = [-@pl.col("f32")]
  m["unary/not/f32"] = [@pl.col("f32").not_()]
  m["unary/neg/f64"] = [-@pl.col("f64")]
  m["unary/not/f64"] = [@pl.col("f64").not_()]
  m["unary/neg/s"] = [-@pl.col("s")]
  m["unary/not/s"] = [@pl.col("s").not_()]
  m["unary/neg/b"] = [-@pl.col("b")]
  m["unary/not/b"] = [@pl.col("b").not_()]
  m["unary/neg/d"] = [-@pl.col("d")]
  m["unary/not/d"] = [@pl.col("d").not_()]
  m["unary/neg/dt"] = [-@pl.col("dt")]
  m["unary/not/dt"] = [@pl.col("dt").not_()]
  m["unary/neg/n"] = [-@pl.col("n")]
  m["unary/not/n"] = [@pl.col("n").not_()]
  m["unary/neg-neg"] = [-(-@pl.col("i32"))]
  m["unary/neg-op"] = [-(@pl.col("i32") + @pl.lit_int(1L))]
  m["unary/neg-in-op"] = [-@pl.col("i32") + -@pl.col("i64")]
  m["unary/not-cmp"] = [@pl.col("i32").lt(@pl.lit_int(0L)).not_()]
  m["unary/not-and"] = [(@pl.col("b") & @pl.col("b")).not_()]
  m["unary/and-cmp"] = [
    @pl.col("i32").gt(@pl.lit_int(0L)) & @pl.col("i64").lt(@pl.lit_int(3L)),
  ]
  m["unary/or-cmp"] = [
    @pl.col("i32").gt(@pl.lit_int(0L)) | @pl.col("i64").lt(@pl.lit_int(3L)),
  ]
  m["unary/and-lit"] = [
    @pl.col("b") & @pl.lit_bool(true),
    (@pl.col("b") | @pl.lit_bool(false)).alias("o"),
    (@pl.col("b") & @pl.lit_bool(false)).alias("a2"),
    (@pl.col("b") | @pl.lit_bool(true)).alias("o2"),
  ]
  m["unary/not-n"] = [@pl.col("n").not_()]
  m["unary/not-lit"] = [@pl.lit_bool(true).not_()]
  m["rf5/i32+3e9"] = [@pl.col("i32") + @pl.lit_int(3000000000L)]
  m["rf5/i32==2^40"] = [@pl.col("i32").eq(@pl.lit_int(1099511627776L))]
  m["rf5/i32!=2^40"] = [@pl.col("i32").neq(@pl.lit_int(1099511627776L))]
  m["rf5/i32<2^40"] = [@pl.col("i32").lt(@pl.lit_int(1099511627776L))]
  m["rf5/f32*1e300"] = [@pl.col("f32") * @pl.lit_float(1.0e300)]
  m["rf5/f32+3e9"] = [@pl.col("f32") + @pl.lit_int(3000000000L)]
  m["rf5/i32*1.5"] = [@pl.col("i32") * @pl.lit_float(1.5)]
  m["rf5/i32-i64max"] = [@pl.col("i32") - @pl.lit_int(9223372036854775807L)]
  m["rf5/i64+i64max"] = [@pl.col("i64") + @pl.lit_int(9223372036854775807L)]
  m["rf4/select-col-lit/e0"] = [@pl.col("i32"), @pl.lit_int(1L)]
  m["rf4/wc-lit/e0"] = [@pl.lit_int(1L)]
  m["rf4/select-lit/z0"] = [@pl.lit_int(1L)]
  m["rf4/select-lit-lit/e0"] = [@pl.lit_int(1L), @pl.lit_int(2L).alias("k")]
  m["rf4/select-lit-expr/e0"] = [
    @pl.lit_int(1L).alias("k"),
    @pl.col("i32") + @pl.lit_int(1L),
  ]
}

///|
/// Every case id with the expressions it builds.
fn golden_expr_cases() -> Map[String, Array[@pl.Expr]] {
  let m : Map[String, Array[@pl.Expr]] = Map([])
  golden_expr_cases_0(m)
  golden_expr_cases_1(m)
  golden_expr_cases_2(m)
  golden_expr_cases_3(m)
  golden_expr_cases_4(m)
  golden_expr_cases_5(m)
  golden_expr_cases_6(m)
  golden_expr_cases_7(m)
  golden_expr_cases_8(m)
  golden_expr_cases_9(m)
  golden_expr_cases_10(m)
  golden_expr_cases_11(m)
  golden_expr_cases_12(m)
  golden_expr_cases_13(m)
  golden_expr_cases_14(m)
  golden_expr_cases_15(m)
  golden_expr_cases_16(m)
  golden_expr_cases_17(m)
  golden_expr_cases_18(m)
  golden_expr_cases_19(m)
  golden_expr_cases_20(m)
  golden_expr_cases_21(m)
  golden_expr_cases_22(m)
  golden_expr_cases_23(m)
  golden_expr_cases_24(m)
  m
}
