// 由 docs/golden/scripts/expr_shape.py 生成，勿手改

///|
fn golden_expr_shape_cases_0(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["sort/q/i32/asc"] = [@pl.col("i32").sort()]
  m["arg_sort/q/i32/asc"] = [@pl.col("i32").arg_sort()]
  m["sort/q/i32/desc"] = [@pl.col("i32").sort(descending=true)]
  m["arg_sort/q/i32/desc"] = [@pl.col("i32").arg_sort(descending=true)]
  m["sort/q/i32/asc-nl"] = [@pl.col("i32").sort(nulls_last=true)]
  m["arg_sort/q/i32/asc-nl"] = [@pl.col("i32").arg_sort(nulls_last=true)]
  m["sort/q/i32/desc-nl"] = [
    @pl.col("i32").sort(descending=true, nulls_last=true),
  ]
  m["arg_sort/q/i32/desc-nl"] = [
    @pl.col("i32").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/q/i64/asc"] = [@pl.col("i64").sort()]
  m["arg_sort/q/i64/asc"] = [@pl.col("i64").arg_sort()]
  m["sort/q/i64/desc-nl"] = [
    @pl.col("i64").sort(descending=true, nulls_last=true),
  ]
  m["arg_sort/q/i64/desc-nl"] = [
    @pl.col("i64").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/q/f32/asc"] = [@pl.col("f32").sort()]
  m["arg_sort/q/f32/asc"] = [@pl.col("f32").arg_sort()]
  m["sort/q/f32/desc-nl"] = [
    @pl.col("f32").sort(descending=true, nulls_last=true),
  ]
  m["arg_sort/q/f32/desc-nl"] = [
    @pl.col("f32").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/q/f64/asc"] = [@pl.col("f64").sort()]
  m["arg_sort/q/f64/asc"] = [@pl.col("f64").arg_sort()]
  m["sort/q/f64/desc"] = [@pl.col("f64").sort(descending=true)]
  m["arg_sort/q/f64/desc"] = [@pl.col("f64").arg_sort(descending=true)]
  m["sort/q/f64/asc-nl"] = [@pl.col("f64").sort(nulls_last=true)]
  m["arg_sort/q/f64/asc-nl"] = [@pl.col("f64").arg_sort(nulls_last=true)]
  m["sort/q/f64/desc-nl"] = [
    @pl.col("f64").sort(descending=true, nulls_last=true),
  ]
  m["arg_sort/q/f64/desc-nl"] = [
    @pl.col("f64").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/q/s/asc"] = [@pl.col("s").sort()]
  m["arg_sort/q/s/asc"] = [@pl.col("s").arg_sort()]
  m["sort/q/s/desc"] = [@pl.col("s").sort(descending=true)]
  m["arg_sort/q/s/desc"] = [@pl.col("s").arg_sort(descending=true)]
  m["sort/q/s/asc-nl"] = [@pl.col("s").sort(nulls_last=true)]
  m["arg_sort/q/s/asc-nl"] = [@pl.col("s").arg_sort(nulls_last=true)]
  m["sort/q/s/desc-nl"] = [@pl.col("s").sort(descending=true, nulls_last=true)]
  m["arg_sort/q/s/desc-nl"] = [
    @pl.col("s").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/q/b/asc"] = [@pl.col("b").sort()]
  m["arg_sort/q/b/asc"] = [@pl.col("b").arg_sort()]
  m["sort/q/b/desc"] = [@pl.col("b").sort(descending=true)]
  m["arg_sort/q/b/desc"] = [@pl.col("b").arg_sort(descending=true)]
  m["sort/q/b/asc-nl"] = [@pl.col("b").sort(nulls_last=true)]
  m["arg_sort/q/b/asc-nl"] = [@pl.col("b").arg_sort(nulls_last=true)]
  m["sort/q/b/desc-nl"] = [@pl.col("b").sort(descending=true, nulls_last=true)]
  m["arg_sort/q/b/desc-nl"] = [
    @pl.col("b").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/q/d/asc"] = [@pl.col("d").sort()]
  m["arg_sort/q/d/asc"] = [@pl.col("d").arg_sort()]
  m["sort/q/d/desc-nl"] = [@pl.col("d").sort(descending=true, nulls_last=true)]
  m["arg_sort/q/d/desc-nl"] = [
    @pl.col("d").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/q/dt/asc"] = [@pl.col("dt").sort()]
  m["arg_sort/q/dt/asc"] = [@pl.col("dt").arg_sort()]
  m["sort/q/dt/desc-nl"] = [
    @pl.col("dt").sort(descending=true, nulls_last=true),
  ]
  m["arg_sort/q/dt/desc-nl"] = [
    @pl.col("dt").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/q/n/asc"] = [@pl.col("n").sort()]
  m["arg_sort/q/n/asc"] = [@pl.col("n").arg_sort()]
  m["sort/q/n/desc"] = [@pl.col("n").sort(descending=true)]
  m["arg_sort/q/n/desc"] = [@pl.col("n").arg_sort(descending=true)]
  m["sort/q/n/asc-nl"] = [@pl.col("n").sort(nulls_last=true)]
  m["arg_sort/q/n/asc-nl"] = [@pl.col("n").arg_sort(nulls_last=true)]
  m["sort/q/n/desc-nl"] = [@pl.col("n").sort(descending=true, nulls_last=true)]
  m["arg_sort/q/n/desc-nl"] = [
    @pl.col("n").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/e0/i32"] = [@pl.col("i32").sort()]
  m["arg_sort/e0/i32"] = [
    @pl.col("i32").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/r1/i32"] = [@pl.col("i32").sort()]
  m["arg_sort/r1/i32"] = [
    @pl.col("i32").arg_sort(descending=true, nulls_last=true),
  ]
}

///|
fn golden_expr_shape_cases_1(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["sort/e0/s"] = [@pl.col("s").sort()]
  m["arg_sort/e0/s"] = [@pl.col("s").arg_sort(descending=true, nulls_last=true)]
  m["sort/r1/s"] = [@pl.col("s").sort()]
  m["arg_sort/r1/s"] = [@pl.col("s").arg_sort(descending=true, nulls_last=true)]
  m["sort/e0/n"] = [@pl.col("n").sort()]
  m["arg_sort/e0/n"] = [@pl.col("n").arg_sort(descending=true, nulls_last=true)]
  m["sort/r1/n"] = [@pl.col("n").sort()]
  m["arg_sort/r1/n"] = [@pl.col("n").arg_sort(descending=true, nulls_last=true)]
  m["sort/e0/f64"] = [@pl.col("f64").sort()]
  m["arg_sort/e0/f64"] = [
    @pl.col("f64").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/r1/f64"] = [@pl.col("f64").sort()]
  m["arg_sort/r1/f64"] = [
    @pl.col("f64").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/dup/i64"] = [@pl.col("i64").sort()]
  m["sort/dup/i64/desc-nl"] = [
    @pl.col("i64").sort(descending=true, nulls_last=true),
  ]
  m["arg_sort/dup/i64"] = [@pl.col("i64").arg_sort()]
  m["arg_sort/dup/i64/desc"] = [@pl.col("i64").arg_sort(descending=true)]
  m["arg_sort/dup/i64/desc-nl"] = [
    @pl.col("i64").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/dup/f64"] = [@pl.col("f64").sort()]
  m["sort/dup/f64/desc-nl"] = [
    @pl.col("f64").sort(descending=true, nulls_last=true),
  ]
  m["arg_sort/dup/f64"] = [@pl.col("f64").arg_sort()]
  m["arg_sort/dup/f64/desc"] = [@pl.col("f64").arg_sort(descending=true)]
  m["arg_sort/dup/f64/desc-nl"] = [
    @pl.col("f64").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/dup/s"] = [@pl.col("s").sort()]
  m["sort/dup/s/desc-nl"] = [
    @pl.col("s").sort(descending=true, nulls_last=true),
  ]
  m["arg_sort/dup/s"] = [@pl.col("s").arg_sort()]
  m["arg_sort/dup/s/desc"] = [@pl.col("s").arg_sort(descending=true)]
  m["arg_sort/dup/s/desc-nl"] = [
    @pl.col("s").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort/dup/b"] = [@pl.col("b").sort()]
  m["sort/dup/b/desc-nl"] = [
    @pl.col("b").sort(descending=true, nulls_last=true),
  ]
  m["arg_sort/dup/b"] = [@pl.col("b").arg_sort()]
  m["arg_sort/dup/b/desc"] = [@pl.col("b").arg_sort(descending=true)]
  m["arg_sort/dup/b/desc-nl"] = [
    @pl.col("b").arg_sort(descending=true, nulls_last=true),
  ]
  m["sort_by/sk/a/asc"] = [@pl.col("x").sort_by([@pl.col("a"), @pl.col("id")])]
  m["sort_by/sk/a/desc-nl"] = [
    @pl.col("x").sort_by(
      [@pl.col("a"), @pl.col("id")],
      descending=[true, false],
      nulls_last=true,
    ),
  ]
  m["sort_by/sk/s/asc"] = [@pl.col("x").sort_by([@pl.col("s"), @pl.col("id")])]
  m["sort_by/sk/s/desc-nl"] = [
    @pl.col("x").sort_by(
      [@pl.col("s"), @pl.col("id")],
      descending=[true, false],
      nulls_last=true,
    ),
  ]
  m["sort_by/sk/f/asc"] = [@pl.col("x").sort_by([@pl.col("f"), @pl.col("id")])]
  m["sort_by/sk/f/desc-nl"] = [
    @pl.col("x").sort_by(
      [@pl.col("f"), @pl.col("id")],
      descending=[true, false],
      nulls_last=true,
    ),
  ]
  m["sort_by/sk/bo/asc"] = [
    @pl.col("x").sort_by([@pl.col("bo"), @pl.col("id")]),
  ]
  m["sort_by/sk/bo/desc-nl"] = [
    @pl.col("x").sort_by(
      [@pl.col("bo"), @pl.col("id")],
      descending=[true, false],
      nulls_last=true,
    ),
  ]
  m["sort_by/sk/id/asc"] = [
    @pl.col("x").sort_by([@pl.col("id"), @pl.col("id")]),
  ]
  m["sort_by/sk/id/desc"] = [
    @pl.col("x").sort_by([@pl.col("id"), @pl.col("id")], descending=[
      true, false,
    ]),
  ]
  m["sort_by/sk/id/asc-nl"] = [
    @pl.col("x").sort_by([@pl.col("id"), @pl.col("id")], nulls_last=true),
  ]
  m["sort_by/sk/id/desc-nl"] = [
    @pl.col("x").sort_by(
      [@pl.col("id"), @pl.col("id")],
      descending=[true, false],
      nulls_last=true,
    ),
  ]
  m["sort_by/sk/single-id"] = [
    @pl.col("x").sort_by([@pl.col("id")], descending=[true]),
  ]
  m["sort_by/sk/two-desc-bool"] = [
    @pl.col("x").sort_by([@pl.col("s"), @pl.col("a"), @pl.col("id")], descending=[
      true, true, true,
    ]),
  ]
  m["sort_by/sk/two-desc-list"] = [
    @pl.col("x").sort_by([@pl.col("s"), @pl.col("a"), @pl.col("id")], descending=[
      true, false, true,
    ]),
  ]
  m["sort_by/sk/two-desc-nl"] = [
    @pl.col("x").sort_by(
      [@pl.col("s"), @pl.col("a"), @pl.col("id")],
      descending=[false, true, false],
      nulls_last=true,
    ),
  ]
  m["sort_by/sk/by-self"] = [
    @pl.col("a").sort_by([@pl.col("a"), @pl.col("id")]),
  ]
  m["sort_by/sk/expr-key"] = [
    @pl.col("x").sort_by([@pl.col("a") * @pl.lit_int(-1L), @pl.col("id")]),
  ]
  m["sort_by/sk/key-is-bool"] = [
    @pl.col("x").sort_by([@pl.col("bo"), @pl.col("id")]),
  ]
  m["sort_by/sk/key-float"] = [
    @pl.col("x").sort_by([@pl.col("f"), @pl.col("id")], descending=[true, false]),
  ]
  m["sort_by/sk/key-float-nl"] = [
    @pl.col("x").sort_by([@pl.col("f"), @pl.col("id")], nulls_last=true),
  ]
  m["sort_by/sk/ties-stable"] = [@pl.col("x").sort_by([@pl.col("a")])]
  m["sort_by/sk/ties-stable-desc"] = [
    @pl.col("x").sort_by([@pl.col("a")], descending=[true]),
  ]
  m["sort_by/sk/ties-stable-nl"] = [
    @pl.col("x").sort_by([@pl.col("s")], nulls_last=true),
  ]
  m["sort_by/sk/ties-two-keys"] = [
    @pl.col("x").sort_by([@pl.col("a"), @pl.col("s")]),
  ]
  m["sort_by/sk/no-keys"] = [@pl.col("x").sort_by([])]
  m["sort_by/sk/lit-key"] = [
    @pl.col("x").sort_by([@pl.lit(@pl.AnyValue::Int32(1))]),
  ]
  m["sort_by/sk/lit-weak-key"] = [@pl.col("x").sort_by([@pl.lit_int(1L)])]
}

///|
fn golden_expr_shape_cases_2(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["sort_by/sk/agg-key"] = [@pl.col("x").sort_by([@pl.col("a").sum()])]
  m["sort_by/sk/agg-base"] = [@pl.col("x").sum().sort_by([@pl.col("a")])]
  m["sort_by/sk/agg-both"] = [@pl.col("x").sum().sort_by([@pl.col("a").sum()])]
  m["sort_by/sk/short-key"] = [@pl.col("x").sort_by([@pl.col("a").head(n=3)])]
  m["sort_by/sk/short-base"] = [@pl.col("x").head(n=3).sort_by([@pl.col("a")])]
  m["sort_by/sk/short-both"] = [
    @pl.col("x").head(n=3).sort_by([@pl.col("a").head(n=3), @pl.col("id")]),
  ]
  m["sort_by/sk/desc-too-long"] = [
    @pl.col("x").sort_by([@pl.col("a"), @pl.col("id")], descending=[
      true, false, true,
    ]),
  ]
  m["sort_by/sk/desc-one-of-two"] = [
    @pl.col("x").sort_by([@pl.col("a"), @pl.col("id")], descending=[true]),
  ]
  m["sort_by/sk/desc-one-of-one"] = [
    @pl.col("x").sort_by([@pl.col("id")], descending=[true]),
  ]
  m["sort_by/sk/missing-key"] = [@pl.col("x").sort_by([@pl.col("zz")])]
  m["sort_by/sk/missing-base"] = [@pl.col("zz").sort_by([@pl.col("a")])]
  m["sort_by/sk/chain-head"] = [
    @pl.col("x").sort_by([@pl.col("a"), @pl.col("id")]).head(n=3),
  ]
  m["sort_by/sk/first"] = [
    @pl.col("x")
    .sort_by([@pl.col("a"), @pl.col("id")], descending=[true, true])
    .first(),
  ]
  m["sort_by/sk/cols"] = [
    @pl.cols(["x", "a"]).sort_by([@pl.col("s"), @pl.col("id")]),
  ]
  m["sort_by/sk/all"] = [@pl.all().sort_by([@pl.col("id")], descending=[true])]
  m["sort_by/sk/cols-key"] = [@pl.col("x").sort_by([@pl.cols(["s", "id"])])]
  m["sort_by/sk/alias"] = [
    @pl.col("x").sort_by([@pl.col("a"), @pl.col("id")]).alias("z"),
  ]
  m["sort_by/sk/with-col"] = [
    @pl.col("x").sort_by([@pl.col("a"), @pl.col("id")]).alias("sorted"),
  ]
  m["sort_by/e0"] = [@pl.col("i32").sort_by([@pl.col("i64")])]
  m["sort_by/e0/lit"] = [
    @pl.col("i32").sort_by([@pl.lit(@pl.AnyValue::Int32(1))]),
  ]
  m["sort_by/r1"] = [
    @pl.col("i32").sort_by([@pl.col("i64"), @pl.col("f64")], descending=[
      true, false,
    ]),
  ]
  m["sort_by/z0"] = [@pl.lit_int(1L).sort_by([@pl.lit_int(2L)])]
  m["sort_by/q/str-by-date"] = [
    @pl.col("s").sort_by([@pl.col("d"), @pl.col("dt")], descending=[false, true]),
  ]
  m["sort_by/q/null-key"] = [@pl.col("i32").sort_by([@pl.col("n")])]
  m["head/q/i32/0"] = [@pl.col("i32").head(n=0)]
  m["tail/q/i32/0"] = [@pl.col("i32").tail(n=0)]
  m["head/q/i32/2"] = [@pl.col("i32").head(n=2)]
  m["tail/q/i32/2"] = [@pl.col("i32").tail(n=2)]
  m["head/q/i32/100"] = [@pl.col("i32").head(n=100)]
  m["tail/q/i32/100"] = [@pl.col("i32").tail(n=100)]
  m["head/q/f64/0"] = [@pl.col("f64").head(n=0)]
  m["tail/q/f64/0"] = [@pl.col("f64").tail(n=0)]
  m["head/q/f64/2"] = [@pl.col("f64").head(n=2)]
  m["tail/q/f64/2"] = [@pl.col("f64").tail(n=2)]
  m["head/q/f64/100"] = [@pl.col("f64").head(n=100)]
  m["tail/q/f64/100"] = [@pl.col("f64").tail(n=100)]
  m["head/q/s/0"] = [@pl.col("s").head(n=0)]
  m["tail/q/s/0"] = [@pl.col("s").tail(n=0)]
  m["head/q/s/2"] = [@pl.col("s").head(n=2)]
  m["tail/q/s/2"] = [@pl.col("s").tail(n=2)]
  m["head/q/s/100"] = [@pl.col("s").head(n=100)]
  m["tail/q/s/100"] = [@pl.col("s").tail(n=100)]
  m["head/q/b/0"] = [@pl.col("b").head(n=0)]
  m["tail/q/b/0"] = [@pl.col("b").tail(n=0)]
  m["head/q/b/2"] = [@pl.col("b").head(n=2)]
  m["tail/q/b/2"] = [@pl.col("b").tail(n=2)]
  m["head/q/b/100"] = [@pl.col("b").head(n=100)]
  m["tail/q/b/100"] = [@pl.col("b").tail(n=100)]
  m["head/q/d/0"] = [@pl.col("d").head(n=0)]
  m["tail/q/d/0"] = [@pl.col("d").tail(n=0)]
  m["head/q/d/2"] = [@pl.col("d").head(n=2)]
  m["tail/q/d/2"] = [@pl.col("d").tail(n=2)]
  m["head/q/d/100"] = [@pl.col("d").head(n=100)]
  m["tail/q/d/100"] = [@pl.col("d").tail(n=100)]
  m["head/q/n/0"] = [@pl.col("n").head(n=0)]
  m["tail/q/n/0"] = [@pl.col("n").tail(n=0)]
  m["head/q/n/2"] = [@pl.col("n").head(n=2)]
  m["tail/q/n/2"] = [@pl.col("n").tail(n=2)]
  m["head/q/n/100"] = [@pl.col("n").head(n=100)]
  m["tail/q/n/100"] = [@pl.col("n").tail(n=100)]
}

///|
fn golden_expr_shape_cases_3(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["slice/q/i32/1/2"] = [@pl.col("i32").slice(1, length=2)]
  m["slice/q/i32/-3/None"] = [@pl.col("i32").slice(-3)]
  m["slice/q/i32/-3/2"] = [@pl.col("i32").slice(-3, length=2)]
  m["slice/q/i32/8/5"] = [@pl.col("i32").slice(8, length=5)]
  m["slice/q/i32/0/0"] = [@pl.col("i32").slice(0, length=0)]
  m["slice/q/i32/-20/12"] = [@pl.col("i32").slice(-20, length=12)]
  m["slice/q/s/1/2"] = [@pl.col("s").slice(1, length=2)]
  m["slice/q/s/-3/None"] = [@pl.col("s").slice(-3)]
  m["slice/q/s/-3/2"] = [@pl.col("s").slice(-3, length=2)]
  m["slice/q/s/8/5"] = [@pl.col("s").slice(8, length=5)]
  m["slice/q/s/0/0"] = [@pl.col("s").slice(0, length=0)]
  m["slice/q/s/-20/12"] = [@pl.col("s").slice(-20, length=12)]
  m["slice/q/d/1/2"] = [@pl.col("d").slice(1, length=2)]
  m["slice/q/d/-3/None"] = [@pl.col("d").slice(-3)]
  m["slice/q/d/-3/2"] = [@pl.col("d").slice(-3, length=2)]
  m["slice/q/d/8/5"] = [@pl.col("d").slice(8, length=5)]
  m["slice/q/d/0/0"] = [@pl.col("d").slice(0, length=0)]
  m["slice/q/d/-20/12"] = [@pl.col("d").slice(-20, length=12)]
  m["slice/q/n/1/2"] = [@pl.col("n").slice(1, length=2)]
  m["slice/q/n/-3/None"] = [@pl.col("n").slice(-3)]
  m["slice/q/n/-3/2"] = [@pl.col("n").slice(-3, length=2)]
  m["slice/q/n/8/5"] = [@pl.col("n").slice(8, length=5)]
  m["slice/q/n/0/0"] = [@pl.col("n").slice(0, length=0)]
  m["slice/q/n/-20/12"] = [@pl.col("n").slice(-20, length=12)]
  m["head/q/default"] = [@pl.col("i32").head(n=10)]
  m["tail/q/default"] = [@pl.col("i32").tail(n=10)]
  m["head/q/neg-1"] = [@pl.col("i32").head(n=-1)]
  m["tail/q/neg-1"] = [@pl.col("i32").tail(n=-1)]
  m["head/e0/neg-1"] = [@pl.col("i32").head(n=-1)]
  m["head/q/neg-3"] = [@pl.col("i32").head(n=-3)]
  m["tail/q/neg-3"] = [@pl.col("i32").tail(n=-3)]
  m["head/e0/neg-3"] = [@pl.col("i32").head(n=-3)]
  m["slice/q/neg-length"] = [@pl.col("i32").slice(1, length=-1)]
  m["slice/q/neg-length-zero-offset"] = [@pl.col("s").slice(0, length=-2)]
  m["head/e0/i32"] = [@pl.col("i32").head(n=3)]
  m["tail/e0/i32"] = [@pl.col("i32").tail(n=3)]
  m["slice/e0/i32"] = [@pl.col("i32").slice(-1, length=2)]
  m["head/e0/s"] = [@pl.col("s").head(n=3)]
  m["tail/e0/s"] = [@pl.col("s").tail(n=3)]
  m["slice/e0/s"] = [@pl.col("s").slice(-1, length=2)]
  m["head/e0/n"] = [@pl.col("n").head(n=3)]
  m["tail/e0/n"] = [@pl.col("n").tail(n=3)]
  m["slice/e0/n"] = [@pl.col("n").slice(-1, length=2)]
  m["head/r1/i32"] = [@pl.col("i32").head(n=3)]
  m["tail/r1/i32"] = [@pl.col("i32").tail(n=3)]
  m["slice/r1/i32"] = [@pl.col("i32").slice(-1, length=2)]
  m["head/r1/s"] = [@pl.col("s").head(n=3)]
  m["tail/r1/s"] = [@pl.col("s").tail(n=3)]
  m["slice/r1/s"] = [@pl.col("s").slice(-1, length=2)]
  m["head/r1/n"] = [@pl.col("n").head(n=3)]
  m["tail/r1/n"] = [@pl.col("n").tail(n=3)]
  m["slice/r1/n"] = [@pl.col("n").slice(-1, length=2)]
  m["head/z0-lit"] = [@pl.lit_int(1L).head(n=3)]
  m["head/lit"] = [@pl.lit_int(1L).head(n=3)]
  m["head/lit-strong"] = [@pl.lit(@pl.AnyValue::Int32(4)).head(n=3)]
  m["head/lit-str"] = [@pl.lit_str("a").head(n=0)]
  m["tail/lit"] = [@pl.lit_str("a").tail(n=2)]
  m["slice/lit"] = [@pl.lit_float(1.5).slice(0, length=5)]
  m["head/agg"] = [@pl.col("i32").sum().head(n=3)]
  m["head/cols"] = [@pl.cols(["i32", "i64"]).head(n=3)]
}

///|
fn golden_expr_shape_cases_4(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["head/all"] = [@pl.all().head(n=2)]
  m["head/all-z0"] = [@pl.all().head(n=2)]
  m["head/cols-empty"] = [@pl.cols([]).head(n=2)]
  m["head/missing"] = [@pl.col("zz").head(n=2)]
  m["head/alias"] = [@pl.col("i32").head(n=2).alias("h")]
  m["head/alias-inner"] = [@pl.col("i32").alias("z").head(n=2)]
  m["head/names"] = [
    @pl.col("i32").head(n=2),
    @pl.col("i64").head(n=2).alias("b"),
    @pl.col("f64").tail(n=2).alias("c"),
  ]
  m["head/dup-name"] = [@pl.col("i32").head(n=2), @pl.col("i32").tail(n=2)]
  m["head/dup-with-col"] = [@pl.col("i32"), @pl.col("i32").head(n=2)]
  m["unique/dup/i32/stable"] = [@pl.col("i32").unique(maintain_order=true)]
  m["unique/dup/i32/sorted"] = [@pl.col("i32").unique().sort()]
  m["drop_nulls/q/i32"] = [@pl.col("i32").drop_nulls()]
  m["drop_nulls/dup/i32"] = [@pl.col("i32").drop_nulls()]
  m["unique/q/i32/stable"] = [@pl.col("i32").unique(maintain_order=true)]
  m["unique/dup/i64/stable"] = [@pl.col("i64").unique(maintain_order=true)]
  m["unique/dup/i64/sorted"] = [@pl.col("i64").unique().sort()]
  m["drop_nulls/q/i64"] = [@pl.col("i64").drop_nulls()]
  m["unique/dup/f32/stable"] = [@pl.col("f32").unique(maintain_order=true)]
  m["unique/dup/f32/sorted"] = [@pl.col("f32").unique().sort()]
  m["drop_nulls/q/f32"] = [@pl.col("f32").drop_nulls()]
  m["unique/dup/f64/stable"] = [@pl.col("f64").unique(maintain_order=true)]
  m["unique/dup/f64/sorted"] = [@pl.col("f64").unique().sort()]
  m["drop_nulls/q/f64"] = [@pl.col("f64").drop_nulls()]
  m["unique/dup/s/stable"] = [@pl.col("s").unique(maintain_order=true)]
  m["unique/dup/s/sorted"] = [@pl.col("s").unique().sort()]
  m["drop_nulls/q/s"] = [@pl.col("s").drop_nulls()]
  m["drop_nulls/dup/s"] = [@pl.col("s").drop_nulls()]
  m["unique/q/s/stable"] = [@pl.col("s").unique(maintain_order=true)]
  m["unique/dup/b/stable"] = [@pl.col("b").unique(maintain_order=true)]
  m["unique/dup/b/sorted"] = [@pl.col("b").unique().sort()]
  m["drop_nulls/q/b"] = [@pl.col("b").drop_nulls()]
  m["unique/dup/d/stable"] = [@pl.col("d").unique(maintain_order=true)]
  m["unique/dup/d/sorted"] = [@pl.col("d").unique().sort()]
  m["drop_nulls/q/d"] = [@pl.col("d").drop_nulls()]
  m["unique/dup/dt/stable"] = [@pl.col("dt").unique(maintain_order=true)]
  m["unique/dup/dt/sorted"] = [@pl.col("dt").unique().sort()]
  m["drop_nulls/q/dt"] = [@pl.col("dt").drop_nulls()]
  m["unique/dup/n/stable"] = [@pl.col("n").unique(maintain_order=true)]
  m["unique/dup/n/sorted"] = [@pl.col("n").unique().sort()]
  m["drop_nulls/q/n"] = [@pl.col("n").drop_nulls()]
  m["drop_nulls/dup/n"] = [@pl.col("n").drop_nulls()]
  m["unique/q/n/stable"] = [@pl.col("n").unique(maintain_order=true)]
  m["unique/e0/i32"] = [@pl.col("i32").unique(maintain_order=true)]
  m["drop_nulls/e0/i32"] = [@pl.col("i32").drop_nulls()]
  m["unique/e0/s"] = [@pl.col("s").unique(maintain_order=true)]
  m["drop_nulls/e0/s"] = [@pl.col("s").drop_nulls()]
  m["unique/e0/n"] = [@pl.col("n").unique(maintain_order=true)]
  m["drop_nulls/e0/n"] = [@pl.col("n").drop_nulls()]
  m["unique/r1/i32"] = [@pl.col("i32").unique(maintain_order=true)]
  m["drop_nulls/r1/i32"] = [@pl.col("i32").drop_nulls()]
  m["unique/r1/s"] = [@pl.col("s").unique(maintain_order=true)]
  m["drop_nulls/r1/s"] = [@pl.col("s").drop_nulls()]
  m["unique/r1/n"] = [@pl.col("n").unique(maintain_order=true)]
  m["drop_nulls/r1/n"] = [@pl.col("n").drop_nulls()]
  m["unique/lit"] = [@pl.lit_int(3L).unique(maintain_order=true)]
  m["unique/z0-lit"] = [@pl.lit_str("a").unique(maintain_order=true)]
  m["drop_nulls/lit"] = [@pl.lit_int(3L).drop_nulls()]
  m["drop_nulls/lit-null"] = [@pl.lit(@pl.AnyValue::Null).drop_nulls()]
  m["unique/agg"] = [@pl.col("i32").sum().unique(maintain_order=true)]
  m["unique/count"] = [@pl.col("i32").unique(maintain_order=true).count()]
}

///|
fn golden_expr_shape_cases_5(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["unique/n_unique-same"] = [
    @pl.col("f64").unique(maintain_order=true).n_unique(),
    @pl.col("f64").n_unique().alias("m"),
  ]
  m["drop_nulls/mean"] = [@pl.col("f64").drop_nulls().mean()]
  m["drop_nulls/sum-len"] = [
    @pl.col("i32").drop_nulls().len(),
    @pl.col("i32").count().alias("c"),
  ]
  m["unique/cols"] = [@pl.cols(["i32", "i64"]).unique(maintain_order=true)]
  m["unique/cols-uneven"] = [
    @pl.cols(["i32", "i64"]).unique(maintain_order=true),
  ]
  m["drop_nulls/all-qn"] = [@pl.all().drop_nulls()]
  m["drop_nulls/wc"] = [@pl.col("i32").drop_nulls().alias("x")]
  m["drop_nulls/wc-same-name"] = [@pl.col("i32").drop_nulls()]
  m["filter/q/i32/b"] = [@pl.col("i32").filter(@pl.col("b"))]
  m["filter/e0/i32"] = [@pl.col("i32").filter(@pl.col("b"))]
  m["filter/q/i64/b"] = [@pl.col("i64").filter(@pl.col("b"))]
  m["filter/q/f32/b"] = [@pl.col("f32").filter(@pl.col("b"))]
  m["filter/q/f64/b"] = [@pl.col("f64").filter(@pl.col("b"))]
  m["filter/q/s/b"] = [@pl.col("s").filter(@pl.col("b"))]
  m["filter/e0/s"] = [@pl.col("s").filter(@pl.col("b"))]
  m["filter/q/b/b"] = [@pl.col("b").filter(@pl.col("b"))]
  m["filter/q/d/b"] = [@pl.col("d").filter(@pl.col("b"))]
  m["filter/q/dt/b"] = [@pl.col("dt").filter(@pl.col("b"))]
  m["filter/q/n/b"] = [@pl.col("n").filter(@pl.col("b"))]
  m["filter/e0/n"] = [@pl.col("n").filter(@pl.col("b"))]
  m["filter/q/pred-type/i64"] = [@pl.col("i32").filter(@pl.col("i64"))]
  m["filter/q/pred-type/f64"] = [@pl.col("i32").filter(@pl.col("f64"))]
  m["filter/q/pred-type/s"] = [@pl.col("i32").filter(@pl.col("s"))]
  m["filter/q/pred-type/d"] = [@pl.col("i32").filter(@pl.col("d"))]
  m["filter/q/pred-type/n"] = [@pl.col("i32").filter(@pl.col("n"))]
  m["filter/q/gt"] = [@pl.col("i64").filter(@pl.col("i64").gt(@pl.lit_int(0L)))]
  m["filter/q/sum"] = [
    @pl.col("i64").filter(@pl.col("i64").gt(@pl.lit_int(0L))).sum(),
  ]
  m["filter/q/sum-i32"] = [
    @pl.col("i32").filter(@pl.col("i32").gt(@pl.lit_int(1L))).sum(),
  ]
  m["filter/q/mean-two"] = [
    @pl.col("f64").filter(@pl.col("b")).mean(),
    @pl.col("f64").filter(@pl.col("b").not_()).sum().alias("t"),
  ]
  m["filter/q/lit-true"] = [@pl.col("i32").filter(@pl.lit_bool(true))]
  m["filter/q/lit-false"] = [@pl.col("i32").filter(@pl.lit_bool(false))]
  m["filter/q/lit-null"] = [@pl.col("i32").filter(@pl.lit(@pl.AnyValue::Null))]
  m["filter/q/lit-int"] = [@pl.col("i32").filter(@pl.lit_int(1L))]
  m["filter/q/lit-float"] = [@pl.col("i32").filter(@pl.lit_float(1.5))]
  m["filter/q/lit-str"] = [@pl.col("i32").filter(@pl.lit_str("a"))]
  m["filter/q/agg-pred"] = [
    @pl.col("i32").filter(@pl.col("i64").sum().gt(@pl.lit_int(0L))),
  ]
  m["filter/q/agg-pred-false"] = [
    @pl.col("i32").filter(@pl.col("i64").sum().lt(@pl.lit_int(0L))),
  ]
  m["filter/q/agg-base"] = [@pl.col("i32").sum().filter(@pl.col("b"))]
  m["filter/q/agg-base-true"] = [
    @pl.col("i32").sum().filter(@pl.lit_bool(true)),
  ]
  m["filter/q/agg-base-false"] = [
    @pl.col("i32").sum().filter(@pl.lit_bool(false)),
  ]
  m["filter/q/lit-base"] = [
    @pl.lit(@pl.AnyValue::Int32(1)).filter(@pl.col("b")),
  ]
  m["filter/q/short-pred"] = [@pl.col("i32").filter(@pl.col("b").head(n=2))]
  m["filter/q/short-base"] = [@pl.col("i32").head(n=3).filter(@pl.col("b"))]
  m["filter/q/short-both"] = [
    @pl.col("i32").head(n=3).filter(@pl.col("b").head(n=3)),
  ]
  m["filter/q/one-pred"] = [@pl.col("i32").filter(@pl.col("b").head(n=1))]
  m["filter/q/chain-head"] = [@pl.col("i64").filter(@pl.col("b")).head(n=2)]
  m["filter/q/chain-sort"] = [
    @pl.col("i64").filter(@pl.col("i64").is_not_null()).sort(descending=true),
  ]
  m["filter/q/filter-filter"] = [
    @pl.col("i64")
    .filter(@pl.col("i64").is_not_null())
    .filter(
      @pl.col("i64").filter(@pl.col("i64").is_not_null()).gt(@pl.lit_int(0L)),
    ),
  ]
  m["filter/q/cols"] = [
    @pl.cols(["i32", "i64"]).filter(@pl.col("f64").gt(@pl.lit_float(0.0))),
  ]
  m["filter/q/all-pred"] = [
    @pl.all().filter(@pl.col("f64").gt(@pl.lit_float(0.0))),
  ]
  m["filter/q/pred-cols"] = [
    @pl.col("i32").filter(@pl.cols(["i32", "i64"]).gt(@pl.lit_int(0L))),
  ]
  m["filter/q/missing-base"] = [@pl.col("zz").filter(@pl.col("b"))]
  m["filter/q/missing-pred"] = [@pl.col("i32").filter(@pl.col("zz"))]
  m["filter/q/alias"] = [@pl.col("i32").filter(@pl.col("b")).alias("z")]
  m["filter/q/wc"] = [@pl.col("i32").filter(@pl.col("b")).alias("z")]
  m["filter/q/wc-agg"] = [
    @pl.col("i32").filter(@pl.col("b")).sum().alias("tot"),
  ]
  m["filter/z0-lit"] = [@pl.lit_int(1L).filter(@pl.lit_bool(true))]
  m["filter/z0-lit-false"] = [@pl.lit_int(1L).filter(@pl.lit_bool(false))]
  m["filter/r1"] = [@pl.col("i32").filter(@pl.col("b"))]
  m["shape/head-and-col"] = [@pl.col("i32").head(n=2), @pl.col("i64")]
}

///|
fn golden_expr_shape_cases_6(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["shape/col-and-head"] = [@pl.col("i64"), @pl.col("i32").head(n=2)]
  m["shape/head1-and-col"] = [@pl.col("i32").head(n=1), @pl.col("i64")]
  m["shape/tail1-and-col"] = [@pl.col("i32").tail(n=1), @pl.col("i64")]
  m["shape/slice1-and-col"] = [
    @pl.col("i32").slice(3, length=1),
    @pl.col("i64"),
  ]
  m["shape/filter1-and-col"] = [
    @pl.col("i32").filter(@pl.col("i32").eq(@pl.lit_int(4L))),
    @pl.col("i64"),
  ]
  m["shape/unique1-and-col"] = [
    @pl.col("n").unique(maintain_order=true),
    @pl.col("i32"),
  ]
  m["shape/drop1-and-col"] = [
    @pl.col("s").head(n=2).drop_nulls().alias("s1"),
    @pl.col("i64"),
  ]
  m["shape/head1-and-head3"] = [
    @pl.col("i32").head(n=1),
    @pl.col("i64").head(n=3),
  ]
  m["shape/head2-and-head3"] = [
    @pl.col("i32").head(n=2),
    @pl.col("i64").head(n=3),
  ]
  m["shape/head3-and-head2"] = [
    @pl.col("i32").head(n=3),
    @pl.col("i64").head(n=2),
  ]
  m["shape/head2-and-sum"] = [@pl.col("i32").head(n=2), @pl.col("i64").sum()]
  m["shape/head2-and-lit"] = [@pl.col("i32").head(n=2), @pl.lit_int(1L)]
  m["shape/head1-and-lit"] = [@pl.col("i32").head(n=1), @pl.lit_int(1L)]
  m["shape/head1-and-sum"] = [
    @pl.col("i32").head(n=1),
    @pl.col("i64").sum().alias("s"),
  ]
  m["shape/head1-alone"] = [@pl.col("i32").head(n=1)]
  m["shape/head2-alone"] = [@pl.col("i32").head(n=2)]
  m["shape/head0-and-col"] = [@pl.col("i32").head(n=0), @pl.col("i64")]
  m["shape/head0-and-sum"] = [@pl.col("i32").head(n=0), @pl.col("i64").sum()]
  m["shape/head0-and-head0"] = [
    @pl.col("i32").head(n=0),
    @pl.col("i64").head(n=0),
  ]
  m["shape/head0-and-head1"] = [
    @pl.col("i32").head(n=0),
    @pl.col("i64").head(n=1),
  ]
  m["shape/r1-head0-and-col"] = [@pl.col("i32").head(n=0), @pl.col("i64")]
  m["shape/r1-filter-false-and-col"] = [
    @pl.col("i32").filter(@pl.lit_bool(false)),
    @pl.col("i64"),
  ]
  m["shape/r1-slice-and-head"] = [
    @pl.col("i32").slice(1, length=3),
    @pl.col("i64").head(n=2),
  ]
  m["shape/r1-head0-and-lit"] = [@pl.col("i32").head(n=0), @pl.lit_int(1L)]
  m["shape/r1-head0-and-sum"] = [
    @pl.col("i32").head(n=0),
    @pl.col("i64").sum().alias("s"),
  ]
  m["shape/r1-col-and-head3"] = [@pl.col("i32"), @pl.col("i64").head(n=3)]
  m["horiz/r1-head0-head1-and-col"] = [
    @pl.sum_horizontal([@pl.col("i32").head(n=0), @pl.col("i64").head(n=1)]),
    @pl.col("i64"),
  ]
  m["filter/e0-agg-base"] = [@pl.col("i32").sum().filter(@pl.col("b"))]
  m["filter/e0-agg-base-alias"] = [
    @pl.col("i32").sum().filter(@pl.col("b")).alias("x"),
    @pl.col("i64"),
  ]
  m["filter/q/head1-base-empty-pred"] = [
    @pl.col("i32").head(n=1).filter(@pl.col("b").head(n=0)),
  ]
  m["filter/q/agg-empty-pred"] = [
    @pl.col("i32").sum().filter(@pl.col("b").head(n=0)),
  ]
  m["filter/q/any-base"] = [@pl.col("b").any().filter(@pl.col("b"))]
  m["filter/q/all-base"] = [@pl.col("b").all().filter(@pl.col("b"))]
  m["filter/q/lit-base-empty-pred"] = [
    @pl.lit_int(1L).filter(@pl.col("b").head(n=0)),
  ]
  m["sort_by/sk/key-head1"] = [@pl.col("x").sort_by([@pl.col("a").head(n=1)])]
  m["sort_by/sk/key-drop-head1"] = [
    @pl.col("x").sort_by([@pl.col("a").drop_nulls().head(n=1)]),
  ]
  m["sort_by/sk/base-head2-key-head1"] = [
    @pl.col("x").head(n=2).sort_by([@pl.col("a").head(n=1)]),
  ]
  m["sort_by/sk/multi-key-head1"] = [
    @pl.col("x").sort_by([@pl.col("a"), @pl.col("a").head(n=1)]),
  ]
  m["sort_by/sk/multi-head1-key"] = [
    @pl.col("x").sort_by([@pl.col("a").head(n=1), @pl.col("a")]),
  ]
  m["sort_by/sk/multi-empty-base"] = [
    @pl.col("x")
    .head(n=0)
    .sort_by([@pl.col("a").head(n=1), @pl.col("a").head(n=0)]),
  ]
  m["sort_by/sk/multi-agg-key"] = [
    @pl.col("x").sort_by([@pl.col("a"), @pl.col("id").sum()]),
  ]
  m["sort_by/r1-head0-and-sorted"] = [
    @pl.col("i32").head(n=0),
    @pl.col("i64").sort_by([@pl.col("i64")]),
  ]
  m["sort_by/r1-key-col"] = [@pl.col("i32").sort_by([@pl.col("i64")])]
  m["shape/sum-sort-and-col"] = [@pl.col("i32").sum().sort(), @pl.col("i64")]
  m["shape/lit-sort-and-col"] = [@pl.lit_int(1L).sort(), @pl.col("i64")]
  m["shape/sum-arg_sort-and-col"] = [
    @pl.col("i32").sum().arg_sort(),
    @pl.col("i64"),
  ]
  m["shape/sum-head-and-col"] = [@pl.col("i32").sum().head(n=1), @pl.col("i64")]
  m["shape/lit-head-and-col"] = [@pl.lit_int(1L).head(n=1), @pl.col("i64")]
  m["shape/sum-unique-and-col"] = [
    @pl.col("i32").sum().unique(),
    @pl.col("i64"),
  ]
  m["shape/sum-filter-and-col"] = [
    @pl.col("i32").sum().filter(@pl.lit_bool(true)),
    @pl.col("i64"),
  ]
  m["shape/sum-drop_nulls-and-col"] = [
    @pl.col("i32").sum().drop_nulls(),
    @pl.col("i64"),
  ]
  m["shape/sum-slice-and-col"] = [
    @pl.col("i32").sum().slice(0, length=1),
    @pl.col("i64"),
  ]
  m["shape/head1-sin-and-col"] = [
    @pl.col("i32").head(n=1).sin(),
    @pl.col("i64"),
  ]
  m["shape/head1-plus-and-col"] = [
    @pl.col("i32").head(n=1) + @pl.lit_int(1L),
    @pl.col("i64"),
  ]
  m["shape/head1-plus-col"] = [@pl.col("i32").head(n=1) + @pl.col("i64")]
  m["shape/head2-plus-col"] = [@pl.col("i32").head(n=2) + @pl.col("i64")]
  m["shape/head1-plus-head3"] = [
    @pl.col("i32").head(n=1) + @pl.col("i64").head(n=3),
  ]
  m["shape/sum-plus-head1-and-col"] = [
    @pl.col("i32").sum() + @pl.col("i64").head(n=1),
    @pl.col("f64"),
  ]
  m["shape/head1-alias-and-col"] = [
    @pl.col("i32").head(n=1).alias("z"),
    @pl.col("i64"),
  ]
  m["shape/head1-cast-and-col"] = [
    @pl.col("i32").head(n=1).cast(@pl.DataType::Int64),
    @pl.col("f64"),
  ]
}

///|
fn golden_expr_shape_cases_7(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["shape/head1-fill-and-col"] = [
    @pl.col("i32").head(n=1).fill_null(@pl.lit_int(0L)),
    @pl.col("i64"),
  ]
  m["shape/head1-shift-and-col"] = [
    @pl.col("i32").head(n=1).shift(n=1),
    @pl.col("i64"),
  ]
  m["shape/head1-is_null-and-col"] = [
    @pl.col("i32").head(n=1).is_null(),
    @pl.col("i64"),
  ]
  m["shape/head1-not-and-col"] = [@pl.col("b").head(n=1).not_(), @pl.col("i64")]
  m["shape/head1-sort-and-col"] = [
    @pl.col("i32").head(n=1).sort(),
    @pl.col("i64"),
  ]
  m["shape/head1-and-r1"] = [@pl.col("i32").head(n=1), @pl.col("i64")]
  m["shape/head5-and-r1"] = [@pl.col("i32").head(n=5), @pl.col("i64")]
  m["shape/e0-head-and-col"] = [@pl.col("i32").head(n=1), @pl.col("i64")]
  m["shape/e0-head-and-sum"] = [@pl.col("i32").head(n=1), @pl.col("i64").sum()]
  m["shape/e0-sum-and-col"] = [@pl.col("i32").sum(), @pl.col("i64")]
  m["shape/wc-head2"] = [@pl.col("i32").head(n=2)]
  m["shape/wc-head2-alias"] = [@pl.col("i32").head(n=2).alias("x")]
  m["shape/wc-head1"] = [@pl.col("i32").head(n=1)]
  m["shape/wc-head1-alias"] = [@pl.col("i32").head(n=1).alias("x")]
  m["shape/wc-head10"] = [@pl.col("i32").head(n=10).alias("x")]
  m["shape/wc-head100"] = [@pl.col("i32").head(n=100).alias("x")]
  m["shape/wc-tail1"] = [@pl.col("i32").tail(n=1)]
  m["shape/wc-filter1"] = [
    @pl.col("i32").filter(@pl.col("i32").eq(@pl.lit_int(4L))).alias("x"),
  ]
  m["shape/wc-filter-all"] = [
    @pl.col("i32").filter(@pl.lit_bool(true)).alias("x"),
  ]
  m["shape/wc-unique1"] = [@pl.col("n").unique(maintain_order=true)]
  m["shape/wc-sort"] = [@pl.col("i32").sort().alias("x")]
  m["shape/wc-sort-in-place"] = [@pl.col("i32").sort()]
  m["shape/wc-arg_sort"] = [@pl.col("i32").arg_sort().alias("rank")]
  m["shape/wc-sum-sort"] = [@pl.col("i32").sum().sort().alias("x")]
  m["shape/wc-lit-head1"] = [@pl.lit_int(1L).head(n=1).alias("x")]
  m["shape/wc-sum-head1"] = [@pl.col("i32").sum().head(n=1).alias("x")]
  m["shape/wc-drop_nulls"] = [@pl.col("i32").drop_nulls().alias("x")]
  m["shape/wc-e0-head"] = [@pl.col("i32").head(n=1).alias("x")]
  m["shape/wc-e0-head0"] = [@pl.col("i32").head(n=0).alias("x")]
  m["shape/wc-r1-head1"] = [@pl.col("i32").head(n=1).alias("x")]
  m["shape/wc-z0-head"] = [@pl.lit_int(1L).head(n=0).alias("x")]
  m["shape/m2-head-two-cols"] = [
    @pl.col("i32").head(n=2),
    @pl.col("i64").head(n=4),
  ]
  m["shape/m2-all-lengths"] = [
    @pl.col("i32"),
    @pl.col("i64").head(n=4),
    @pl.col("f64").sum(),
  ]
  m["mix/sort-first"] = [@pl.col("i32").sort().first()]
  m["mix/sort-last"] = [@pl.col("i32").sort(descending=true).last()]
  m["mix/sort-median"] = [@pl.col("f64").sort().median()]
  m["mix/sort-plus"] = [@pl.col("i64").sort() + @pl.col("i32").sort()]
  m["mix/sort-minus-col"] = [@pl.col("i64").sort() - @pl.col("i64")]
  m["mix/sort-cum_sum"] = [@pl.col("i64").sort().cum_sum()]
  m["mix/sort-shift"] = [@pl.col("i64").sort().shift(n=1)]
  m["mix/sort-reverse"] = [@pl.col("s").sort().reverse()]
  m["mix/sort-rank"] = [
    @pl.col("i64").sort().rank(method_=@pl.RankMethod::Average),
  ]
  m["mix/sort-abs"] = [@pl.col("i32").sort().abs()]
  m["mix/sort-fill"] = [@pl.col("i32").sort().fill_null(@pl.lit_int(0L))]
  m["mix/sort-cast"] = [@pl.col("i32").sort().cast(@pl.DataType::Float64)]
  m["mix/sort-is_null"] = [@pl.col("i32").sort().is_null()]
  m["mix/sort-between"] = [
    @pl.col("i32")
    .sort()
    .between(@pl.lit_int(0L), @pl.lit_int(5L), closed=@pl.ClosedInterval::Both),
  ]
  m["mix/sort-when"] = [
    @pl.when(@pl.col("i64").sort().gt(@pl.lit_int(0L)))
    .then(@pl.lit_int(1L))
    .otherwise(@pl.lit_int(0L)),
  ]
  m["mix/sort-sort"] = [@pl.col("i32").sort(descending=true).sort()]
  m["mix/sort-desc-sort"] = [@pl.col("i32").sort().sort(descending=true)]
  m["mix/arg_sort-head"] = [@pl.col("i64").arg_sort().head(n=3)]
  m["mix/arg_sort-sum"] = [@pl.col("i64").arg_sort().sum()]
  m["mix/arg_sort-eq-rank"] = [
    @pl.col("f64")
    .arg_sort()
    .eq(@pl.col("f64").rank(method_=@pl.RankMethod::Ordinal)),
  ]
  m["mix/arg_sort-arg_sort"] = [@pl.col("i64").arg_sort().arg_sort()]
  m["mix/arg_sort-gt"] = [@pl.col("s").arg_sort().gt(@pl.lit_int(4L))]
  m["mix/head-sum"] = [@pl.col("i32").head(n=3).sum()]
  m["mix/head-mean"] = [@pl.col("f64").head(n=4).mean()]
  m["mix/tail-max"] = [@pl.col("i64").tail(n=4).max()]
  m["mix/head-count"] = [
    @pl.col("i32").head(n=5).count(),
    @pl.col("i32").head(n=5).len().alias("l"),
  ]
  m["mix/head-head"] = [@pl.col("i32").head(n=6).head(n=3)]
}

///|
fn golden_expr_shape_cases_8(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["mix/head-tail"] = [@pl.col("i32").head(n=6).tail(n=2)]
  m["mix/tail-head"] = [@pl.col("i32").tail(n=6).head(n=2)]
  m["mix/slice-slice"] = [@pl.col("i32").slice(2, length=6).slice(-2, length=5)]
  m["mix/head-plus-head"] = [
    @pl.col("i32").head(n=3) + @pl.col("i64").head(n=3),
  ]
  m["mix/head-plus-lit"] = [@pl.col("i64").head(n=3) + @pl.lit_int(1L)]
  m["mix/head-plus-sum"] = [@pl.col("i64").head(n=3) - @pl.col("i64").sum()]
  m["mix/head-sort"] = [
    @pl.col("i32").head(n=5).sort(descending=true, nulls_last=true),
  ]
  m["mix/head-unique"] = [@pl.col("i32").head(n=5).unique(maintain_order=true)]
  m["mix/head-drop_nulls"] = [@pl.col("i32").head(n=5).drop_nulls()]
  m["mix/head-cum_sum"] = [@pl.col("i64").head(n=5).cum_sum()]
  m["mix/head-shift"] = [@pl.col("i64").head(n=5).shift(n=1)]
  m["mix/head-rank"] = [
    @pl.col("f64").head(n=5).rank(method_=@pl.RankMethod::Average),
  ]
  m["mix/head-is_null"] = [@pl.col("i32").head(n=5).is_null()]
  m["mix/head-fill"] = [
    @pl.col("i32").head(n=5).fill_null(@pl.col("i64").head(n=5)),
  ]
  m["mix/head-fill-long"] = [@pl.col("i32").head(n=5).fill_null(@pl.col("i64"))]
  m["mix/head-when"] = [
    @pl.when(@pl.col("b").head(n=3))
    .then(@pl.col("i32").head(n=3))
    .otherwise(@pl.col("i64").head(n=3)),
  ]
  m["mix/head-cast"] = [@pl.col("i32").head(n=3).cast(@pl.DataType::String)]
  m["mix/head-str"] = [@pl.col("s").head(n=3).str().to_uppercase()]
  m["mix/head-dt"] = [@pl.col("d").head(n=3).dt().year()]
  m["mix/unique-sum"] = [@pl.col("i32").unique(maintain_order=true).sum()]
  m["mix/unique-len"] = [@pl.col("s").unique(maintain_order=true).len()]
  m["mix/unique-sort"] = [
    @pl.col("f64")
    .unique(maintain_order=true)
    .sort(descending=true, nulls_last=true),
  ]
  m["mix/unique-shift"] = [
    @pl.col("i64").unique(maintain_order=true).shift(n=1),
  ]
  m["mix/unique-plus"] = [
    @pl.col("i32").unique(maintain_order=true) + @pl.lit_int(1L),
  ]
  m["mix/filter-then-sort"] = [
    @pl.col("x").filter(@pl.col("a").gt(@pl.lit_int(1L))).sort(descending=true),
  ]
  m["mix/filter-by-sort-by"] = [
    @pl.col("x")
    .sort_by([@pl.col("a"), @pl.col("id")])
    .filter(@pl.col("x").gt(@pl.lit_int(30L))),
  ]
  m["mix/filter-pred-sorted"] = [
    @pl.col("x").filter(@pl.col("a").gt(@pl.lit_int(1L)).sort()),
  ]
  m["mix/drop_nulls-sort"] = [@pl.col("i32").drop_nulls().sort()]
  m["mix/drop_nulls-first"] = [@pl.col("i32").drop_nulls().first()]
  m["mix/drop_nulls-null-col"] = [@pl.col("n").drop_nulls()]
  m["mix/drop_nulls-null-sum"] = [@pl.col("i32").drop_nulls().sum()]
  m["mix/names-several"] = [
    @pl.col("i32").sort(),
    @pl.col("i64").arg_sort().alias("ia"),
    @pl.col("f64").head(n=10).alias("h"),
  ]
  m["mix/dup-name-sort"] = [@pl.col("i32"), @pl.col("i32").sort()]
  m["mix/dup-name-arg_sort"] = [
    @pl.col("i32").arg_sort(),
    @pl.col("i32").sort(),
  ]
  m["mix/missing-sort"] = [@pl.col("zz").sort()]
  m["mix/missing-after"] = [@pl.col("i32").sort(), @pl.col("zz").unique()]
  m["mix/cols-sort"] = [@pl.cols(["i32", "i64"]).sort(descending=true)]
  m["mix/all-sort"] = [@pl.all().sort()]
  m["mix/all-arg_sort"] = [@pl.all().arg_sort()]
  m["mix/all-z0"] = [@pl.all().sort()]
  m["mix/cols-empty"] = [@pl.cols([]).sort()]
  m["mix/cols-width"] = [
    @pl.cols(["i32", "i64"]).sort_by([@pl.cols(["f32", "f64"]), @pl.col("i32")]),
  ]
  m["mix/alias-inner-sort"] = [@pl.col("i32").alias("z").sort()]
  m["mix/alias-sort"] = [@pl.col("i32").sort().alias("z")]
  m["mix/lit-sort"] = [@pl.lit_int(1L).sort()]
  m["mix/lit-arg_sort"] = [@pl.lit_int(1L).arg_sort()]
  m["mix/lit-sort-null"] = [@pl.lit(@pl.AnyValue::Null).sort()]
  m["mix/lit-sort-str"] = [@pl.lit_str("a").sort()]
  m["mix/lit-arg_sort-z0"] = [@pl.lit_int(1L).arg_sort()]
  m["mix/sum-sort"] = [@pl.col("i32").sum().sort()]
  m["mix/sum-arg_sort"] = [@pl.col("i32").sum().arg_sort()]
  m["mix/wc-sort-sum"] = [@pl.col("i32").sort().sum().alias("tot")]
  m["any/an/t/ign"] = [@pl.col("t").any()]
  m["all/an/t/ign"] = [@pl.col("t").all()]
  m["any/an/t/keep"] = [@pl.col("t").any(ignore_nulls=false)]
  m["all/an/t/keep"] = [@pl.col("t").all(ignore_nulls=false)]
  m["any/an/f/ign"] = [@pl.col("f").any()]
  m["all/an/f/ign"] = [@pl.col("f").all()]
  m["any/an/f/keep"] = [@pl.col("f").any(ignore_nulls=false)]
  m["all/an/f/keep"] = [@pl.col("f").all(ignore_nulls=false)]
}

///|
fn golden_expr_shape_cases_9(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["any/an/m/ign"] = [@pl.col("m").any()]
  m["all/an/m/ign"] = [@pl.col("m").all()]
  m["any/an/m/keep"] = [@pl.col("m").any(ignore_nulls=false)]
  m["all/an/m/keep"] = [@pl.col("m").all(ignore_nulls=false)]
  m["any/an/tn/ign"] = [@pl.col("tn").any()]
  m["all/an/tn/ign"] = [@pl.col("tn").all()]
  m["any/an/tn/keep"] = [@pl.col("tn").any(ignore_nulls=false)]
  m["all/an/tn/keep"] = [@pl.col("tn").all(ignore_nulls=false)]
  m["any/an/fn/ign"] = [@pl.col("fn").any()]
  m["all/an/fn/ign"] = [@pl.col("fn").all()]
  m["any/an/fn/keep"] = [@pl.col("fn").any(ignore_nulls=false)]
  m["all/an/fn/keep"] = [@pl.col("fn").all(ignore_nulls=false)]
  m["any/an/tfn/ign"] = [@pl.col("tfn").any()]
  m["all/an/tfn/ign"] = [@pl.col("tfn").all()]
  m["any/an/tfn/keep"] = [@pl.col("tfn").any(ignore_nulls=false)]
  m["all/an/tfn/keep"] = [@pl.col("tfn").all(ignore_nulls=false)]
  m["any/an/n1/ign"] = [@pl.col("n1").any()]
  m["all/an/n1/ign"] = [@pl.col("n1").all()]
  m["any/an/n1/keep"] = [@pl.col("n1").any(ignore_nulls=false)]
  m["all/an/n1/keep"] = [@pl.col("n1").all(ignore_nulls=false)]
  m["any/an/i/ign"] = [@pl.col("i").any()]
  m["all/an/i/ign"] = [@pl.col("i").all()]
  m["any/an/i/keep"] = [@pl.col("i").any(ignore_nulls=false)]
  m["all/an/i/keep"] = [@pl.col("i").all(ignore_nulls=false)]
  m["any/an/iz/ign"] = [@pl.col("iz").any()]
  m["all/an/iz/ign"] = [@pl.col("iz").all()]
  m["any/an/iz/keep"] = [@pl.col("iz").any(ignore_nulls=false)]
  m["all/an/iz/keep"] = [@pl.col("iz").all(ignore_nulls=false)]
  m["any/an/i1/ign"] = [@pl.col("i1").any()]
  m["all/an/i1/ign"] = [@pl.col("i1").all()]
  m["any/an/i1/keep"] = [@pl.col("i1").any(ignore_nulls=false)]
  m["all/an/i1/keep"] = [@pl.col("i1").all(ignore_nulls=false)]
  m["any/an/fl/ign"] = [@pl.col("fl").any()]
  m["all/an/fl/ign"] = [@pl.col("fl").all()]
  m["any/an/fl/keep"] = [@pl.col("fl").any(ignore_nulls=false)]
  m["all/an/fl/keep"] = [@pl.col("fl").all(ignore_nulls=false)]
  m["any/an/fnan/ign"] = [@pl.col("fnan").any()]
  m["all/an/fnan/ign"] = [@pl.col("fnan").all()]
  m["any/an/fnan/keep"] = [@pl.col("fnan").any(ignore_nulls=false)]
  m["all/an/fnan/keep"] = [@pl.col("fnan").all(ignore_nulls=false)]
  m["any/an/fz/ign"] = [@pl.col("fz").any()]
  m["all/an/fz/ign"] = [@pl.col("fz").all()]
  m["any/an/fz/keep"] = [@pl.col("fz").any(ignore_nulls=false)]
  m["all/an/fz/keep"] = [@pl.col("fz").all(ignore_nulls=false)]
  m["any/an/f32/ign"] = [@pl.col("f32").any()]
  m["all/an/f32/ign"] = [@pl.col("f32").all()]
  m["any/an/f32/keep"] = [@pl.col("f32").any(ignore_nulls=false)]
  m["all/an/f32/keep"] = [@pl.col("f32").all(ignore_nulls=false)]
  m["any/q/i32/ign"] = [@pl.col("i32").any()]
  m["all/q/i32/ign"] = [@pl.col("i32").all()]
  m["any/q/i32/keep"] = [@pl.col("i32").any(ignore_nulls=false)]
  m["all/q/i32/keep"] = [@pl.col("i32").all(ignore_nulls=false)]
  m["any/q/f64/ign"] = [@pl.col("f64").any()]
  m["all/q/f64/ign"] = [@pl.col("f64").all()]
  m["any/q/f64/keep"] = [@pl.col("f64").any(ignore_nulls=false)]
  m["all/q/f64/keep"] = [@pl.col("f64").all(ignore_nulls=false)]
  m["any/q/s/ign"] = [@pl.col("s").any()]
  m["all/q/s/ign"] = [@pl.col("s").all()]
  m["any/q/s/keep"] = [@pl.col("s").any(ignore_nulls=false)]
  m["all/q/s/keep"] = [@pl.col("s").all(ignore_nulls=false)]
}

///|
fn golden_expr_shape_cases_10(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["any/q/d/ign"] = [@pl.col("d").any()]
  m["all/q/d/ign"] = [@pl.col("d").all()]
  m["any/q/d/keep"] = [@pl.col("d").any(ignore_nulls=false)]
  m["all/q/d/keep"] = [@pl.col("d").all(ignore_nulls=false)]
  m["any/q/n/ign"] = [@pl.col("n").any()]
  m["all/q/n/ign"] = [@pl.col("n").all()]
  m["any/q/n/keep"] = [@pl.col("n").any(ignore_nulls=false)]
  m["all/q/n/keep"] = [@pl.col("n").all(ignore_nulls=false)]
  m["any/e0/i32/ign"] = [@pl.col("i32").any()]
  m["all/e0/i32/ign"] = [@pl.col("i32").all()]
  m["any/e0/i32/keep"] = [@pl.col("i32").any(ignore_nulls=false)]
  m["all/e0/i32/keep"] = [@pl.col("i32").all(ignore_nulls=false)]
  m["any/e0/b/ign"] = [@pl.col("b").any()]
  m["all/e0/b/ign"] = [@pl.col("b").all()]
  m["any/e0/b/keep"] = [@pl.col("b").any(ignore_nulls=false)]
  m["all/e0/b/keep"] = [@pl.col("b").all(ignore_nulls=false)]
  m["any/e0/n/ign"] = [@pl.col("n").any()]
  m["all/e0/n/ign"] = [@pl.col("n").all()]
  m["any/e0/n/keep"] = [@pl.col("n").any(ignore_nulls=false)]
  m["all/e0/n/keep"] = [@pl.col("n").all(ignore_nulls=false)]
  m["any/e0/s/ign"] = [@pl.col("s").any()]
  m["all/e0/s/ign"] = [@pl.col("s").all()]
  m["any/e0/s/keep"] = [@pl.col("s").any(ignore_nulls=false)]
  m["all/e0/s/keep"] = [@pl.col("s").all(ignore_nulls=false)]
  m["any/e0/d/ign"] = [@pl.col("d").any()]
  m["all/e0/d/ign"] = [@pl.col("d").all()]
  m["any/e0/d/keep"] = [@pl.col("d").any(ignore_nulls=false)]
  m["all/e0/d/keep"] = [@pl.col("d").all(ignore_nulls=false)]
  m["any/e0/dt/ign"] = [@pl.col("dt").any()]
  m["all/e0/dt/ign"] = [@pl.col("dt").all()]
  m["any/e0/dt/keep"] = [@pl.col("dt").any(ignore_nulls=false)]
  m["all/e0/dt/keep"] = [@pl.col("dt").all(ignore_nulls=false)]
  m["any/e0/f32/ign"] = [@pl.col("f32").any()]
  m["all/e0/f32/ign"] = [@pl.col("f32").all()]
  m["any/e0/f32/keep"] = [@pl.col("f32").any(ignore_nulls=false)]
  m["all/e0/f32/keep"] = [@pl.col("f32").all(ignore_nulls=false)]
  m["any/ng/x"] = [@pl.col("x").any(), @pl.col("x").all().alias("al")]
  m["any/ng/y"] = [@pl.col("y").any(), @pl.col("y").all().alias("al")]
  m["any/ng/z"] = [@pl.col("z").any(), @pl.col("z").all().alias("al")]
  m["any/ng/w"] = [@pl.col("w").any(), @pl.col("w").all().alias("al")]
  m["any/r1"] = [@pl.col("b").any(), @pl.col("b").all().alias("al")]
  m["any/lit-true"] = [@pl.lit_bool(true).any()]
  m["any/lit-false"] = [@pl.lit_bool(false).all()]
  m["any/lit-int"] = [@pl.lit_int(0L).any()]
  m["any/lit-float"] = [@pl.lit_float(0.5).all()]
  m["any/lit-null"] = [@pl.lit(@pl.AnyValue::Null).any()]
  m["any/lit-null-keep"] = [@pl.lit(@pl.AnyValue::Null).all(ignore_nulls=false)]
  m["any/lit-str"] = [@pl.lit_str("a").any()]
  m["any/z0-lit"] = [@pl.lit_bool(true).any()]
  m["any/expr"] = [@pl.col("i32").gt(@pl.lit_int(5L)).any()]
  m["all/expr"] = [@pl.col("i64").gt(@pl.lit_int(-5L)).all()]
  m["all/expr-keep"] = [
    @pl.col("i64").gt(@pl.lit_int(-5L)).all(ignore_nulls=false),
  ]
  m["any/mixed-with-col"] = [@pl.col("i32"), @pl.col("b").any().alias("a")]
  m["any/mixed-with-col-error"] = [
    @pl.col("i32"),
    @pl.col("s").any().alias("a"),
  ]
  m["any/and"] = [@pl.col("b").any() & @pl.col("b").all()]
  m["any/not"] = [@pl.col("b").any().not_()]
  m["any/when"] = [
    @pl.when(@pl.col("b").any()).then(@pl.col("i32")).otherwise(@pl.lit_int(0L)),
  ]
  m["any/cols"] = [@pl.cols(["t", "f", "m"]).any()]
  m["any/all"] = [@pl.all().any()]
  m["any/all-z0"] = [@pl.all().any()]
}

///|
fn golden_expr_shape_cases_11(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["any/alias"] = [@pl.col("m").any().alias("x")]
  m["any/alias-inner"] = [@pl.col("m").alias("x").any()]
  m["any/missing"] = [@pl.col("zz").any()]
  m["any/head"] = [@pl.col("m").head(n=1).any()]
  m["any/sort"] = [@pl.col("tfn").sort().any(ignore_nulls=false)]
  m["any/filter"] = [@pl.col("b").filter(@pl.col("b")).any()]
  m["all/filter"] = [@pl.col("b").filter(@pl.col("b")).all()]
  m["all/filter-empty"] = [@pl.col("b").filter(@pl.lit_bool(false)).all()]
  m["any/filter-empty"] = [
    @pl.col("b").filter(@pl.lit_bool(false)).any(ignore_nulls=false),
  ]
  m["any/wc"] = [@pl.col("m").any().alias("x")]
  m["any/sum"] = [@pl.col("m").any().sum()]
  m["any/names"] = [
    @pl.col("m").any(),
    @pl.col("tn").all(ignore_nulls=false).alias("b"),
  ]
  m["trig/sin/q/i32"] = [@pl.col("i32").sin()]
  m["trig/sin/q/i64"] = [@pl.col("i64").sin()]
  m["trig/sin/q/f32"] = [@pl.col("f32").sin()]
  m["trig/sin/q/f64"] = [@pl.col("f64").sin()]
  m["trig/sin/q/s"] = [@pl.col("s").sin()]
  m["trig/sin/q/b"] = [@pl.col("b").sin()]
  m["trig/sin/q/d"] = [@pl.col("d").sin()]
  m["trig/sin/q/dt"] = [@pl.col("dt").sin()]
  m["trig/sin/q/n"] = [@pl.col("n").sin()]
  m["trig/sin/lit-int"] = [@pl.lit_int(1L).sin()]
  m["trig/sin/e0/i32"] = [@pl.col("i32").sin()]
  m["trig/sin/e0/f32"] = [@pl.col("f32").sin()]
  m["trig/sin/e0/n"] = [@pl.col("n").sin()]
  m["trig/sin/e0/s"] = [@pl.col("s").sin()]
  m["trig/sin/lit-float"] = [@pl.lit_float(0.5).sin()]
  m["trig/sin/lit-strong"] = [@pl.lit(@pl.AnyValue::Float32(0.5)).sin()]
  m["trig/sin/lit-str"] = [@pl.lit_str("a").sin()]
  m["trig/sin/sum"] = [@pl.col("i32").sum().sin()]
  m["trig/sin/r1"] = [@pl.col("f64").sin()]
  m["trig/cos/q/i32"] = [@pl.col("i32").cos()]
  m["trig/cos/q/i64"] = [@pl.col("i64").cos()]
  m["trig/cos/q/f32"] = [@pl.col("f32").cos()]
  m["trig/cos/q/f64"] = [@pl.col("f64").cos()]
  m["trig/cos/q/n"] = [@pl.col("n").cos()]
  m["trig/tan/q/i32"] = [@pl.col("i32").tan()]
  m["trig/tan/q/i64"] = [@pl.col("i64").tan()]
  m["trig/tan/q/f32"] = [@pl.col("f32").tan()]
  m["trig/tan/q/f64"] = [@pl.col("f64").tan()]
  m["trig/tan/q/s"] = [@pl.col("s").tan()]
  m["trig/tan/q/b"] = [@pl.col("b").tan()]
  m["trig/tan/q/d"] = [@pl.col("d").tan()]
  m["trig/tan/q/dt"] = [@pl.col("dt").tan()]
  m["trig/tan/q/n"] = [@pl.col("n").tan()]
  m["trig/tan/lit-int"] = [@pl.lit_int(1L).tan()]
  m["trig/arcsin/q/i32"] = [@pl.col("i32").arcsin()]
  m["trig/arcsin/q/i64"] = [@pl.col("i64").arcsin()]
  m["trig/arcsin/q/f32"] = [@pl.col("f32").arcsin()]
  m["trig/arcsin/q/f64"] = [@pl.col("f64").arcsin()]
  m["trig/arcsin/q/n"] = [@pl.col("n").arcsin()]
  m["trig/arcsin/e0/i32"] = [@pl.col("i32").arcsin()]
  m["trig/arcsin/e0/f32"] = [@pl.col("f32").arcsin()]
  m["trig/arcsin/e0/n"] = [@pl.col("n").arcsin()]
  m["trig/arcsin/e0/s"] = [@pl.col("s").arcsin()]
  m["trig/arcsin/lit-float"] = [@pl.lit_float(0.5).arcsin()]
  m["trig/arcsin/lit-strong"] = [@pl.lit(@pl.AnyValue::Float32(0.5)).arcsin()]
  m["trig/arcsin/lit-str"] = [@pl.lit_str("a").arcsin()]
  m["trig/arcsin/sum"] = [@pl.col("i32").sum().arcsin()]
  m["trig/arcsin/r1"] = [@pl.col("f64").arcsin()]
}

///|
fn golden_expr_shape_cases_12(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["trig/arccos/q/i32"] = [@pl.col("i32").arccos()]
  m["trig/arccos/q/i64"] = [@pl.col("i64").arccos()]
  m["trig/arccos/q/f32"] = [@pl.col("f32").arccos()]
  m["trig/arccos/q/f64"] = [@pl.col("f64").arccos()]
  m["trig/arccos/q/n"] = [@pl.col("n").arccos()]
  m["trig/arctan/q/i32"] = [@pl.col("i32").arctan()]
  m["trig/arctan/q/i64"] = [@pl.col("i64").arctan()]
  m["trig/arctan/q/f32"] = [@pl.col("f32").arctan()]
  m["trig/arctan/q/f64"] = [@pl.col("f64").arctan()]
  m["trig/arctan/q/n"] = [@pl.col("n").arctan()]
  m["trig/alias"] = [@pl.col("f64").sin().alias("s")]
  m["trig/alias-inner"] = [@pl.col("f64").alias("z").sin()]
  m["trig/names"] = [
    @pl.col("f64").sin(),
    @pl.col("f32").cos().alias("c"),
    @pl.col("i32").tan().alias("t"),
  ]
  m["trig/dup"] = [@pl.col("f64").sin(), @pl.col("f64").cos()]
  m["trig/cols"] = [@pl.cols(["i32", "f64"]).sin()]
  m["trig/all"] = [@pl.all().arctan()]
  m["trig/all-z0"] = [@pl.all().sin()]
  m["trig/cols-error"] = [@pl.cols(["i32", "s"]).sin()]
  m["trig/missing"] = [@pl.col("zz").sin()]
  m["trig/wc"] = [@pl.col("f64").cos().alias("c")]
  m["trig/pyth"] = [
    @pl.col("f64").sin() * @pl.col("f64").sin() +
    @pl.col("f64").cos() * @pl.col("f64").cos(),
  ]
  m["trig/sin-arcsin"] = [@pl.col("f32").sin().arcsin()]
  m["trig/sum-of-sin"] = [@pl.col("f64").sin().sum()]
  m["trig/head"] = [@pl.col("f64").tan().head(n=3)]
  m["trig/sort"] = [@pl.col("f64").sin().sort()]
  m["trig/sin/ex"] = [@pl.col("x").sin()]
  m["trig/cos/ex"] = [@pl.col("x").cos()]
  m["trig/tan/ex"] = [@pl.col("x").tan()]
  m["trig/arcsin/ex"] = [@pl.col("x").arcsin()]
  m["trig/arccos/ex"] = [@pl.col("x").arccos()]
  m["trig/arctan/ex"] = [@pl.col("x").arctan()]
  m["horiz/sum/two/a/a"] = [@pl.sum_horizontal([@pl.col("a"), @pl.col("a")])]
  m["horiz/sum/two/a/i"] = [@pl.sum_horizontal([@pl.col("a"), @pl.col("i")])]
  m["horiz/sum/two/a/i32"] = [
    @pl.sum_horizontal([@pl.col("a"), @pl.col("i32")]),
  ]
  m["horiz/sum/two/a/f32"] = [
    @pl.sum_horizontal([@pl.col("a"), @pl.col("f32")]),
  ]
  m["horiz/sum/two/a/s"] = [@pl.sum_horizontal([@pl.col("a"), @pl.col("s")])]
  m["horiz/sum/two/a/bo"] = [@pl.sum_horizontal([@pl.col("a"), @pl.col("bo")])]
  m["horiz/sum/two/a/d"] = [@pl.sum_horizontal([@pl.col("a"), @pl.col("d")])]
  m["horiz/sum/two/a/dt"] = [@pl.sum_horizontal([@pl.col("a"), @pl.col("dt")])]
  m["horiz/sum/two/a/n"] = [@pl.sum_horizontal([@pl.col("a"), @pl.col("n")])]
  m["horiz/sum/two/i/i"] = [@pl.sum_horizontal([@pl.col("i"), @pl.col("i")])]
  m["horiz/sum/two/i/i32"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32")]),
  ]
  m["horiz/sum/two/i/f32"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("f32")]),
  ]
  m["horiz/sum/two/i/s"] = [@pl.sum_horizontal([@pl.col("i"), @pl.col("s")])]
  m["horiz/sum/two/i/bo"] = [@pl.sum_horizontal([@pl.col("i"), @pl.col("bo")])]
  m["horiz/sum/two/i/d"] = [@pl.sum_horizontal([@pl.col("i"), @pl.col("d")])]
  m["horiz/sum/two/i/dt"] = [@pl.sum_horizontal([@pl.col("i"), @pl.col("dt")])]
  m["horiz/sum/two/i/n"] = [@pl.sum_horizontal([@pl.col("i"), @pl.col("n")])]
  m["horiz/sum/two/i32/i32"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("i32")]),
  ]
  m["horiz/sum/two/i32/f32"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("f32")]),
  ]
  m["horiz/sum/two/i32/s"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("s")]),
  ]
  m["horiz/sum/two/i32/bo"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("bo")]),
  ]
  m["horiz/sum/two/i32/d"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("d")]),
  ]
  m["horiz/sum/two/i32/dt"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("dt")]),
  ]
  m["horiz/sum/two/i32/n"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("n")]),
  ]
  m["horiz/sum/two/f32/f32"] = [
    @pl.sum_horizontal([@pl.col("f32"), @pl.col("f32")]),
  ]
  m["horiz/sum/two/f32/s"] = [
    @pl.sum_horizontal([@pl.col("f32"), @pl.col("s")]),
  ]
  m["horiz/sum/two/f32/bo"] = [
    @pl.sum_horizontal([@pl.col("f32"), @pl.col("bo")]),
  ]
  m["horiz/sum/two/f32/d"] = [
    @pl.sum_horizontal([@pl.col("f32"), @pl.col("d")]),
  ]
  m["horiz/sum/two/f32/dt"] = [
    @pl.sum_horizontal([@pl.col("f32"), @pl.col("dt")]),
  ]
}

///|
fn golden_expr_shape_cases_13(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["horiz/sum/two/f32/n"] = [
    @pl.sum_horizontal([@pl.col("f32"), @pl.col("n")]),
  ]
  m["horiz/sum/two/s/s"] = [@pl.sum_horizontal([@pl.col("s"), @pl.col("s")])]
  m["horiz/sum/two/s/bo"] = [@pl.sum_horizontal([@pl.col("s"), @pl.col("bo")])]
  m["horiz/sum/two/s/d"] = [@pl.sum_horizontal([@pl.col("s"), @pl.col("d")])]
  m["horiz/sum/two/s/dt"] = [@pl.sum_horizontal([@pl.col("s"), @pl.col("dt")])]
  m["horiz/sum/two/s/n"] = [@pl.sum_horizontal([@pl.col("s"), @pl.col("n")])]
  m["horiz/sum/two/bo/bo"] = [
    @pl.sum_horizontal([@pl.col("bo"), @pl.col("bo")]),
  ]
  m["horiz/sum/two/bo/d"] = [@pl.sum_horizontal([@pl.col("bo"), @pl.col("d")])]
  m["horiz/sum/two/bo/dt"] = [
    @pl.sum_horizontal([@pl.col("bo"), @pl.col("dt")]),
  ]
  m["horiz/sum/two/bo/n"] = [@pl.sum_horizontal([@pl.col("bo"), @pl.col("n")])]
  m["horiz/sum/two/d/d"] = [@pl.sum_horizontal([@pl.col("d"), @pl.col("d")])]
  m["horiz/sum/two/d/dt"] = [@pl.sum_horizontal([@pl.col("d"), @pl.col("dt")])]
  m["horiz/sum/two/d/n"] = [@pl.sum_horizontal([@pl.col("d"), @pl.col("n")])]
  m["horiz/sum/two/dt/dt"] = [
    @pl.sum_horizontal([@pl.col("dt"), @pl.col("dt")]),
  ]
  m["horiz/sum/two/dt/n"] = [@pl.sum_horizontal([@pl.col("dt"), @pl.col("n")])]
  m["horiz/sum/two/n/n"] = [@pl.sum_horizontal([@pl.col("n"), @pl.col("n")])]
  m["horiz/sum/two/s/i32"] = [
    @pl.sum_horizontal([@pl.col("s"), @pl.col("i32")]),
  ]
  m["horiz/sum/two/d/bo"] = [@pl.sum_horizontal([@pl.col("d"), @pl.col("bo")])]
  m["horiz/sum/two/d/s"] = [@pl.sum_horizontal([@pl.col("d"), @pl.col("s")])]
  m["horiz/sum/two/dt/d"] = [@pl.sum_horizontal([@pl.col("dt"), @pl.col("d")])]
  m["horiz/sum/two/bo/s"] = [@pl.sum_horizontal([@pl.col("bo"), @pl.col("s")])]
  m["horiz/sum/one/a"] = [@pl.sum_horizontal([@pl.col("a")])]
  m["horiz/sum/one/i"] = [@pl.sum_horizontal([@pl.col("i")])]
  m["horiz/sum/one/i32"] = [@pl.sum_horizontal([@pl.col("i32")])]
  m["horiz/sum/one/f32"] = [@pl.sum_horizontal([@pl.col("f32")])]
  m["horiz/sum/one/s"] = [@pl.sum_horizontal([@pl.col("s")])]
  m["horiz/sum/one/bo"] = [@pl.sum_horizontal([@pl.col("bo")])]
  m["horiz/sum/one/d"] = [@pl.sum_horizontal([@pl.col("d")])]
  m["horiz/sum/one/dt"] = [@pl.sum_horizontal([@pl.col("dt")])]
  m["horiz/sum/one/n"] = [@pl.sum_horizontal([@pl.col("n")])]
  m["horiz/sum/three-num"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32"), @pl.col("f32")]),
  ]
  m["horiz/sum/three-str-num"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("s"), @pl.col("i")]),
  ]
  m["horiz/sum/three-bool-date-str"] = [
    @pl.sum_horizontal([@pl.col("bo"), @pl.col("d"), @pl.col("s")]),
  ]
  m["horiz/sum/three-str-bool-date"] = [
    @pl.sum_horizontal([@pl.col("s"), @pl.col("bo"), @pl.col("d")]),
  ]
  m["horiz/sum/three-str"] = [
    @pl.sum_horizontal([@pl.col("s"), @pl.col("s2"), @pl.col("s")]),
  ]
  m["horiz/sum/three-null"] = [
    @pl.sum_horizontal([@pl.col("n"), @pl.col("i"), @pl.col("n")]),
  ]
  m["horiz/sum/zeros3"] = [
    @pl.sum_horizontal([@pl.col("a"), @pl.col("b"), @pl.col("a")]),
  ]
  m["horiz/sum/nan-first"] = [@pl.sum_horizontal([@pl.col("b"), @pl.col("a")])]
  m["horiz/sum/lit-weak"] = [
    @pl.sum_horizontal([@pl.lit_int(1L), @pl.col("i32")]),
  ]
  m["horiz/sum/lit-weak-big"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.lit_int(1099511627776L)]),
  ]
  m["horiz/sum/lit-weak-float"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.lit_float(1.5)]),
  ]
  m["horiz/sum/lit-two-weak"] = [
    @pl.sum_horizontal([@pl.lit_int(1L), @pl.lit_int(2L)]),
  ]
  m["horiz/sum/lit-null-col"] = [
    @pl.sum_horizontal([@pl.lit(@pl.AnyValue::Null), @pl.col("i")]),
  ]
  m["horiz/sum/agg"] = [
    @pl.sum_horizontal([@pl.col("i32").sum(), @pl.col("i32")]),
  ]
  m["horiz/sum/shape-head"] = [
    @pl.sum_horizontal([@pl.col("i").head(n=2), @pl.col("i32").head(n=3)]),
  ]
  m["horiz/sum/shape-one"] = [
    @pl.sum_horizontal([@pl.col("i").head(n=1), @pl.col("i32")]),
  ]
  m["horiz/sum/shape-one-alone"] = [
    @pl.sum_horizontal([@pl.col("i").head(n=1), @pl.col("i32").head(n=1)]),
    @pl.col("i"),
  ]
  m["horiz/sum/shape-zero"] = [
    @pl.sum_horizontal([@pl.col("i").head(n=0), @pl.col("i32")]),
  ]
  m["horiz/sum/cols-empty"] = [@pl.sum_horizontal([@pl.cols([])])]
  m["horiz/sum/no-inputs"] = [@pl.sum_horizontal([])]
  m["horiz/sum/e0"] = [@pl.sum_horizontal([@pl.col("i32"), @pl.col("f64")])]
  m["horiz/sum/e0-str"] = [@pl.sum_horizontal([@pl.col("s"), @pl.col("s")])]
  m["horiz/sum/e0-error"] = [@pl.sum_horizontal([@pl.col("i32"), @pl.col("s")])]
  m["horiz/min/two/a/a"] = [@pl.min_horizontal([@pl.col("a"), @pl.col("a")])]
  m["horiz/min/two/a/i"] = [@pl.min_horizontal([@pl.col("a"), @pl.col("i")])]
  m["horiz/min/two/i/i32"] = [
    @pl.min_horizontal([@pl.col("i"), @pl.col("i32")]),
  ]
  m["horiz/min/two/f32/a"] = [
    @pl.min_horizontal([@pl.col("f32"), @pl.col("a")]),
  ]
  m["horiz/min/two/f32/f32"] = [
    @pl.min_horizontal([@pl.col("f32"), @pl.col("f32")]),
  ]
  m["horiz/min/two/i32/i32"] = [
    @pl.min_horizontal([@pl.col("i32"), @pl.col("i32")]),
  ]
  m["horiz/min/two/s/s"] = [@pl.min_horizontal([@pl.col("s"), @pl.col("s")])]
}

///|
fn golden_expr_shape_cases_14(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["horiz/min/two/s/i32"] = [
    @pl.min_horizontal([@pl.col("s"), @pl.col("i32")]),
  ]
  m["horiz/min/two/bo/bo"] = [
    @pl.min_horizontal([@pl.col("bo"), @pl.col("bo")]),
  ]
  m["horiz/min/two/bo/i32"] = [
    @pl.min_horizontal([@pl.col("bo"), @pl.col("i32")]),
  ]
  m["horiz/min/two/bo/d"] = [@pl.min_horizontal([@pl.col("bo"), @pl.col("d")])]
  m["horiz/min/two/d/d"] = [@pl.min_horizontal([@pl.col("d"), @pl.col("d")])]
  m["horiz/min/two/d/dt"] = [@pl.min_horizontal([@pl.col("d"), @pl.col("dt")])]
  m["horiz/min/two/dt/dt"] = [
    @pl.min_horizontal([@pl.col("dt"), @pl.col("dt")]),
  ]
  m["horiz/min/two/dt/i32"] = [
    @pl.min_horizontal([@pl.col("dt"), @pl.col("i32")]),
  ]
  m["horiz/min/two/n/n"] = [@pl.min_horizontal([@pl.col("n"), @pl.col("n")])]
  m["horiz/min/two/n/s"] = [@pl.min_horizontal([@pl.col("n"), @pl.col("s")])]
  m["horiz/min/two/a/n"] = [@pl.min_horizontal([@pl.col("a"), @pl.col("n")])]
  m["horiz/min/two/d/i32"] = [
    @pl.min_horizontal([@pl.col("d"), @pl.col("i32")]),
  ]
  m["horiz/min/two/f32/bo"] = [
    @pl.min_horizontal([@pl.col("f32"), @pl.col("bo")]),
  ]
  m["horiz/min/two/i/s"] = [@pl.min_horizontal([@pl.col("i"), @pl.col("s")])]
  m["horiz/min/two/s/d"] = [@pl.min_horizontal([@pl.col("s"), @pl.col("d")])]
  m["horiz/min/two/s/bo"] = [@pl.min_horizontal([@pl.col("s"), @pl.col("bo")])]
  m["horiz/min/two/i32/d"] = [
    @pl.min_horizontal([@pl.col("i32"), @pl.col("d")]),
  ]
  m["horiz/min/two/i/n"] = [@pl.min_horizontal([@pl.col("i"), @pl.col("n")])]
  m["horiz/min/two/bo/bo2"] = [
    @pl.min_horizontal([@pl.col("bo"), @pl.col("bo2")]),
  ]
  m["horiz/min/two/s/s2"] = [@pl.min_horizontal([@pl.col("s"), @pl.col("s2")])]
  m["horiz/min/one/a"] = [@pl.min_horizontal([@pl.col("a")])]
  m["horiz/min/one/i"] = [@pl.min_horizontal([@pl.col("i")])]
  m["horiz/min/one/i32"] = [@pl.min_horizontal([@pl.col("i32")])]
  m["horiz/min/one/f32"] = [@pl.min_horizontal([@pl.col("f32")])]
  m["horiz/min/one/s"] = [@pl.min_horizontal([@pl.col("s")])]
  m["horiz/min/one/bo"] = [@pl.min_horizontal([@pl.col("bo")])]
  m["horiz/min/one/d"] = [@pl.min_horizontal([@pl.col("d")])]
  m["horiz/min/one/dt"] = [@pl.min_horizontal([@pl.col("dt")])]
  m["horiz/min/one/n"] = [@pl.min_horizontal([@pl.col("n")])]
  m["horiz/min/f32-signed-zero"] = [
    @pl.min_horizontal([@pl.col("f32"), -@pl.col("f32")]),
  ]
  m["horiz/min/str-code-point-order"] = [
    @pl.min_horizontal([@pl.col("x"), @pl.col("y")]),
  ]
  m["horiz/min/three-num"] = [
    @pl.min_horizontal([@pl.col("i"), @pl.col("i32"), @pl.col("f32")]),
  ]
  m["horiz/min/three-str-num"] = [
    @pl.min_horizontal([@pl.col("i"), @pl.col("s"), @pl.col("i")]),
  ]
  m["horiz/min/three-bool-date-str"] = [
    @pl.min_horizontal([@pl.col("bo"), @pl.col("d"), @pl.col("s")]),
  ]
  m["horiz/min/three-str-bool-date"] = [
    @pl.min_horizontal([@pl.col("s"), @pl.col("bo"), @pl.col("d")]),
  ]
  m["horiz/min/three-str"] = [
    @pl.min_horizontal([@pl.col("s"), @pl.col("s2"), @pl.col("s")]),
  ]
  m["horiz/min/three-null"] = [
    @pl.min_horizontal([@pl.col("n"), @pl.col("i"), @pl.col("n")]),
  ]
  m["horiz/min/zeros3"] = [
    @pl.min_horizontal([@pl.col("a"), @pl.col("b"), @pl.col("a")]),
  ]
  m["horiz/min/nan-first"] = [@pl.min_horizontal([@pl.col("b"), @pl.col("a")])]
  m["horiz/min/lit-weak"] = [
    @pl.min_horizontal([@pl.lit_int(1L), @pl.col("i32")]),
  ]
  m["horiz/min/lit-weak-big"] = [
    @pl.min_horizontal([@pl.col("i32"), @pl.lit_int(1099511627776L)]),
  ]
  m["horiz/min/lit-weak-float"] = [
    @pl.min_horizontal([@pl.col("i32"), @pl.lit_float(1.5)]),
  ]
  m["horiz/min/lit-two-weak"] = [
    @pl.min_horizontal([@pl.lit_int(1L), @pl.lit_int(2L)]),
  ]
  m["horiz/min/lit-null-col"] = [
    @pl.min_horizontal([@pl.lit(@pl.AnyValue::Null), @pl.col("i")]),
  ]
  m["horiz/min/agg"] = [
    @pl.min_horizontal([@pl.col("i32").sum(), @pl.col("i32")]),
  ]
  m["horiz/min/shape-head"] = [
    @pl.min_horizontal([@pl.col("i").head(n=2), @pl.col("i32").head(n=3)]),
  ]
  m["horiz/min/shape-one"] = [
    @pl.min_horizontal([@pl.col("i").head(n=1), @pl.col("i32")]),
  ]
  m["horiz/min/shape-one-alone"] = [
    @pl.min_horizontal([@pl.col("i").head(n=1), @pl.col("i32").head(n=1)]),
    @pl.col("i"),
  ]
  m["horiz/min/shape-zero"] = [
    @pl.min_horizontal([@pl.col("i").head(n=0), @pl.col("i32")]),
  ]
  m["horiz/min/cols-empty"] = [@pl.min_horizontal([@pl.cols([])])]
  m["horiz/min/no-inputs"] = [@pl.min_horizontal([])]
  m["horiz/min/e0"] = [@pl.min_horizontal([@pl.col("i32"), @pl.col("f64")])]
  m["horiz/min/e0-str"] = [@pl.min_horizontal([@pl.col("s"), @pl.col("s")])]
  m["horiz/min/e0-error"] = [@pl.min_horizontal([@pl.col("i32"), @pl.col("s")])]
  m["horiz/max/two/bo/bo2"] = [
    @pl.max_horizontal([@pl.col("bo"), @pl.col("bo2")]),
  ]
  m["horiz/max/two/s/s2"] = [@pl.max_horizontal([@pl.col("s"), @pl.col("s2")])]
  m["horiz/max/two/a/a"] = [@pl.max_horizontal([@pl.col("a"), @pl.col("a")])]
  m["horiz/max/two/a/i"] = [@pl.max_horizontal([@pl.col("a"), @pl.col("i")])]
  m["horiz/max/two/i/i32"] = [
    @pl.max_horizontal([@pl.col("i"), @pl.col("i32")]),
  ]
  m["horiz/max/two/f32/a"] = [
    @pl.max_horizontal([@pl.col("f32"), @pl.col("a")]),
  ]
}

///|
fn golden_expr_shape_cases_15(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["horiz/max/two/f32/f32"] = [
    @pl.max_horizontal([@pl.col("f32"), @pl.col("f32")]),
  ]
  m["horiz/max/two/i32/i32"] = [
    @pl.max_horizontal([@pl.col("i32"), @pl.col("i32")]),
  ]
  m["horiz/max/two/s/s"] = [@pl.max_horizontal([@pl.col("s"), @pl.col("s")])]
  m["horiz/max/two/s/i32"] = [
    @pl.max_horizontal([@pl.col("s"), @pl.col("i32")]),
  ]
  m["horiz/max/two/bo/bo"] = [
    @pl.max_horizontal([@pl.col("bo"), @pl.col("bo")]),
  ]
  m["horiz/max/two/bo/i32"] = [
    @pl.max_horizontal([@pl.col("bo"), @pl.col("i32")]),
  ]
  m["horiz/max/two/bo/d"] = [@pl.max_horizontal([@pl.col("bo"), @pl.col("d")])]
  m["horiz/max/two/d/d"] = [@pl.max_horizontal([@pl.col("d"), @pl.col("d")])]
  m["horiz/max/two/d/dt"] = [@pl.max_horizontal([@pl.col("d"), @pl.col("dt")])]
  m["horiz/max/two/dt/dt"] = [
    @pl.max_horizontal([@pl.col("dt"), @pl.col("dt")]),
  ]
  m["horiz/max/two/dt/i32"] = [
    @pl.max_horizontal([@pl.col("dt"), @pl.col("i32")]),
  ]
  m["horiz/max/two/n/n"] = [@pl.max_horizontal([@pl.col("n"), @pl.col("n")])]
  m["horiz/max/two/n/s"] = [@pl.max_horizontal([@pl.col("n"), @pl.col("s")])]
  m["horiz/max/two/a/n"] = [@pl.max_horizontal([@pl.col("a"), @pl.col("n")])]
  m["horiz/max/two/d/i32"] = [
    @pl.max_horizontal([@pl.col("d"), @pl.col("i32")]),
  ]
  m["horiz/max/two/f32/bo"] = [
    @pl.max_horizontal([@pl.col("f32"), @pl.col("bo")]),
  ]
  m["horiz/max/f32-signed-zero"] = [
    @pl.max_horizontal([@pl.col("f32"), -@pl.col("f32")]),
  ]
  m["horiz/max/str-code-point-order"] = [
    @pl.max_horizontal([@pl.col("x"), @pl.col("y")]),
  ]
  m["horiz/max/three-num"] = [
    @pl.max_horizontal([@pl.col("i"), @pl.col("i32"), @pl.col("f32")]),
  ]
  m["horiz/max/three-str-num"] = [
    @pl.max_horizontal([@pl.col("i"), @pl.col("s"), @pl.col("i")]),
  ]
  m["horiz/max/three-bool-date-str"] = [
    @pl.max_horizontal([@pl.col("bo"), @pl.col("d"), @pl.col("s")]),
  ]
  m["horiz/max/three-str-bool-date"] = [
    @pl.max_horizontal([@pl.col("s"), @pl.col("bo"), @pl.col("d")]),
  ]
  m["horiz/max/three-str"] = [
    @pl.max_horizontal([@pl.col("s"), @pl.col("s2"), @pl.col("s")]),
  ]
  m["horiz/max/three-null"] = [
    @pl.max_horizontal([@pl.col("n"), @pl.col("i"), @pl.col("n")]),
  ]
  m["horiz/max/zeros3"] = [
    @pl.max_horizontal([@pl.col("a"), @pl.col("b"), @pl.col("a")]),
  ]
  m["horiz/max/nan-first"] = [@pl.max_horizontal([@pl.col("b"), @pl.col("a")])]
  m["horiz/max/lit-weak"] = [
    @pl.max_horizontal([@pl.lit_int(1L), @pl.col("i32")]),
  ]
  m["horiz/max/lit-weak-big"] = [
    @pl.max_horizontal([@pl.col("i32"), @pl.lit_int(1099511627776L)]),
  ]
  m["horiz/max/lit-weak-float"] = [
    @pl.max_horizontal([@pl.col("i32"), @pl.lit_float(1.5)]),
  ]
  m["horiz/max/lit-two-weak"] = [
    @pl.max_horizontal([@pl.lit_int(1L), @pl.lit_int(2L)]),
  ]
  m["horiz/max/lit-null-col"] = [
    @pl.max_horizontal([@pl.lit(@pl.AnyValue::Null), @pl.col("i")]),
  ]
  m["horiz/max/agg"] = [
    @pl.max_horizontal([@pl.col("i32").sum(), @pl.col("i32")]),
  ]
  m["horiz/max/shape-head"] = [
    @pl.max_horizontal([@pl.col("i").head(n=2), @pl.col("i32").head(n=3)]),
  ]
  m["horiz/max/shape-one"] = [
    @pl.max_horizontal([@pl.col("i").head(n=1), @pl.col("i32")]),
  ]
  m["horiz/max/shape-one-alone"] = [
    @pl.max_horizontal([@pl.col("i").head(n=1), @pl.col("i32").head(n=1)]),
    @pl.col("i"),
  ]
  m["horiz/max/shape-zero"] = [
    @pl.max_horizontal([@pl.col("i").head(n=0), @pl.col("i32")]),
  ]
  m["horiz/max/cols-empty"] = [@pl.max_horizontal([@pl.cols([])])]
  m["horiz/max/no-inputs"] = [@pl.max_horizontal([])]
  m["horiz/max/e0"] = [@pl.max_horizontal([@pl.col("i32"), @pl.col("f64")])]
  m["horiz/max/e0-str"] = [@pl.max_horizontal([@pl.col("s"), @pl.col("s")])]
  m["horiz/max/e0-error"] = [@pl.max_horizontal([@pl.col("i32"), @pl.col("s")])]
  m["horiz/sum/three-int"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("i"), @pl.col("bo")]),
  ]
  m["horiz/sum/three-date-int"] = [
    @pl.sum_horizontal([@pl.col("d"), @pl.col("i"), @pl.col("i32")]),
  ]
  m["horiz/sum/three-bool"] = [
    @pl.sum_horizontal([@pl.col("bo"), @pl.col("bo2"), @pl.col("bo")]),
  ]
  m["horiz/sum/alias"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32")]).alias("z"),
  ]
  m["horiz/sum/alias-inner"] = [
    @pl.sum_horizontal([@pl.col("i").alias("q"), @pl.col("i32")]),
  ]
  m["horiz/sum/lit-first"] = [
    @pl.sum_horizontal([@pl.lit(@pl.AnyValue::Int64(5L)), @pl.col("i")]),
  ]
  m["horiz/sum/lit-last"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.lit(@pl.AnyValue::Int64(5L))]),
  ]
  m["horiz/sum/lit-weak-last"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.lit_int(1L)]),
  ]
  m["horiz/sum/lit-weak-i64"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.lit_int(1L)]),
  ]
  m["horiz/sum/lit-weak-f32"] = [
    @pl.sum_horizontal([@pl.col("f32"), @pl.lit_int(1L)]),
  ]
  m["horiz/sum/lit-weak-float-f32"] = [
    @pl.sum_horizontal([@pl.col("f32"), @pl.lit_float(1.5)]),
  ]
  m["horiz/sum/lit-weak-bool"] = [
    @pl.sum_horizontal([@pl.col("bo"), @pl.lit_int(1L)]),
  ]
  m["horiz/sum/lit-weak-str"] = [
    @pl.sum_horizontal([@pl.col("s"), @pl.lit_int(1L)]),
  ]
  m["horiz/sum/lit-weak-date"] = [
    @pl.sum_horizontal([@pl.col("d"), @pl.lit_int(1L)]),
  ]
  m["horiz/sum/lit-weak-float-int"] = [
    @pl.sum_horizontal([@pl.lit_int(1L), @pl.lit_float(1.5)]),
  ]
  m["horiz/sum/lit-bools"] = [
    @pl.sum_horizontal([@pl.lit_bool(true), @pl.lit_bool(false)]),
  ]
  m["horiz/sum/lit-str-col"] = [
    @pl.sum_horizontal([@pl.lit_str("x"), @pl.col("s")]),
  ]
  m["horiz/sum/lit-null"] = [@pl.sum_horizontal([@pl.lit(@pl.AnyValue::Null)])]
  m["horiz/sum/lit-col-null"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.lit(@pl.AnyValue::Null)]),
  ]
}

///|
fn golden_expr_shape_cases_16(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["horiz/sum/agg-two"] = [
    @pl.sum_horizontal([@pl.col("i").sum(), @pl.col("i").max()]),
  ]
  m["horiz/sum/arith"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32")]) + @pl.lit_int(1L),
  ]
  m["horiz/sum/in-arith"] = [
    @pl.sum_horizontal([@pl.col("i") + @pl.lit_int(1L), @pl.col("i32")]),
  ]
  m["horiz/sum/shape-head2"] = [
    @pl.sum_horizontal([
      @pl.col("i32").head(n=3),
      @pl.col("i").head(n=2),
      @pl.col("f32"),
    ]),
  ]
  m["horiz/sum/shape-head3"] = [
    @pl.sum_horizontal([
      @pl.col("i32"),
      @pl.col("i").head(n=2),
      @pl.col("f32").head(n=3),
    ]),
  ]
  m["horiz/sum/shape-same"] = [
    @pl.sum_horizontal([@pl.col("i").head(n=2), @pl.col("i32").head(n=2)]),
  ]
  m["horiz/sum/shape-one-first"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("i").head(n=1)]),
  ]
  m["horiz/sum/shape-zero-alone"] = [
    @pl.sum_horizontal([@pl.col("i").head(n=0), @pl.col("i32").head(n=0)]),
  ]
  m["horiz/sum/shape-zero-one"] = [
    @pl.sum_horizontal([@pl.col("i").head(n=0), @pl.col("i32").head(n=1)]),
  ]
  m["horiz/sum/dup-name"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32")]),
    @pl.col("i"),
  ]
  m["horiz/sum/names"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("i")]),
    @pl.sum_horizontal([@pl.col("a"), @pl.col("b")]).alias("ab"),
  ]
  m["horiz/sum/missing"] = [@pl.sum_horizontal([@pl.col("i"), @pl.col("zz")])]
  m["horiz/sum/missing-first"] = [
    @pl.sum_horizontal([@pl.col("zz"), @pl.col("i")]),
  ]
  m["horiz/sum/cols"] = [@pl.sum_horizontal([@pl.cols(["i", "i32"])])]
  m["horiz/sum/cols-and-col"] = [
    @pl.sum_horizontal([@pl.cols(["i", "i32"]), @pl.col("f32")]),
  ]
  m["horiz/sum/col-and-cols"] = [
    @pl.sum_horizontal([@pl.col("f32"), @pl.cols(["i", "i32"])]),
  ]
  m["horiz/sum/two-cols"] = [
    @pl.sum_horizontal([@pl.cols(["i", "i32"]), @pl.cols(["f32", "a"])]),
  ]
  m["horiz/sum/all"] = [@pl.sum_horizontal([@pl.all()])]
  m["horiz/min/all"] = [@pl.min_horizontal([@pl.all()])]
  m["horiz/sum/cols-empty-and-col"] = [
    @pl.sum_horizontal([@pl.cols([]), @pl.col("i")]),
  ]
  m["horiz/sum/all-z0"] = [@pl.sum_horizontal([@pl.all()])]
  m["horiz/sum/z0-lit"] = [
    @pl.sum_horizontal([@pl.lit_int(1L), @pl.lit_int(2L)]),
  ]
  m["horiz/sum/z0-lit-str"] = [
    @pl.sum_horizontal([@pl.lit_str("a"), @pl.lit_str("b")]),
  ]
  m["horiz/sum/e0-null"] = [@pl.sum_horizontal([@pl.col("n"), @pl.col("n")])]
  m["horiz/sum/e0-lit"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.lit_int(1L)]),
  ]
  m["horiz/sum/r1"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("i64"), @pl.col("f64")]),
  ]
  m["horiz/min/r1"] = [
    @pl.min_horizontal([@pl.col("i32"), @pl.col("i64"), @pl.col("f64")]),
  ]
  m["horiz/sum/wc"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32")]).alias("w"),
  ]
  m["horiz/sum/wc-in-place"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32")]),
  ]
  m["horiz/sum/wc-shape"] = [
    @pl.sum_horizontal([@pl.col("i").head(n=2), @pl.col("i32").head(n=2)]).alias(
      "w",
    ),
  ]
  m["horiz/sum/wc-shape-one"] = [
    @pl.sum_horizontal([@pl.col("i").head(n=1), @pl.col("i32").head(n=1)]).alias(
      "w",
    ),
  ]
  m["horiz/sum/wc-lit"] = [
    @pl.sum_horizontal([@pl.lit_int(1L), @pl.lit_int(2L)]).alias("w"),
  ]
  m["horiz/sum/wc-agg"] = [
    @pl.sum_horizontal([@pl.col("i").sum(), @pl.col("i").max()]).alias("w"),
  ]
  m["horiz/sum/sort"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32")]).sort(),
  ]
  m["horiz/sum/cast"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32")]).cast(
      @pl.DataType::Float64,
    ),
  ]
  m["horiz/sum/sum-of"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32")]).sum(),
  ]
  m["horiz/sum/fill"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32")]).fill_null(
      @pl.lit_int(0L),
    ),
  ]
  m["horiz/min/nested"] = [
    @pl.min_horizontal([
      @pl.min_horizontal([@pl.col("i"), @pl.col("i32")]),
      @pl.col("f32"),
    ]),
  ]
  m["horiz/sum-keep/two/i/i"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/two/a/b"] = [
    @pl.sum_horizontal([@pl.col("a"), @pl.col("b")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/two/s/s2"] = [
    @pl.sum_horizontal([@pl.col("s"), @pl.col("s2")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/two/bo/bo2"] = [
    @pl.sum_horizontal([@pl.col("bo"), @pl.col("bo2")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/two/n/n"] = [
    @pl.sum_horizontal([@pl.col("n"), @pl.col("n")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/two/i/n"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("n")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/two/i32/i"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("i")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/two/f32/i"] = [
    @pl.sum_horizontal([@pl.col("f32"), @pl.col("i")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/two/d/d"] = [
    @pl.sum_horizontal([@pl.col("d"), @pl.col("d")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/two/dt/i"] = [
    @pl.sum_horizontal([@pl.col("dt"), @pl.col("i")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/one/i"] = [
    @pl.sum_horizontal([@pl.col("i")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/one/bo"] = [
    @pl.sum_horizontal([@pl.col("bo")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/one/s"] = [
    @pl.sum_horizontal([@pl.col("s")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/one/d"] = [
    @pl.sum_horizontal([@pl.col("d")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/one/n"] = [
    @pl.sum_horizontal([@pl.col("n")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/one/f32"] = [
    @pl.sum_horizontal([@pl.col("f32")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/three-num"] = [
    @pl.sum_horizontal(
      [@pl.col("i"), @pl.col("i32"), @pl.col("f32")],
      ignore_nulls=false,
    ),
  ]
  m["horiz/sum-keep/lit"] = [
    @pl.sum_horizontal([@pl.lit_int(1L), @pl.col("i")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/lit-null"] = [
    @pl.sum_horizontal(
      [@pl.lit(@pl.AnyValue::Null), @pl.col("i")],
      ignore_nulls=false,
    ),
  ]
  m["horiz/sum-keep/lits"] = [
    @pl.sum_horizontal([@pl.lit_int(1L), @pl.lit_int(2L)], ignore_nulls=false),
  ]
  m["horiz/sum-keep/e0"] = [
    @pl.sum_horizontal([@pl.col("i32"), @pl.col("i64")], ignore_nulls=false),
  ]
  m["horiz/sum-keep/agg"] = [
    @pl.sum_horizontal([@pl.col("i").sum(), @pl.col("i")], ignore_nulls=false),
  ]
}

///|
fn golden_expr_shape_cases_17(m : Map[String, Array[@pl.Expr]]) -> Unit {
  m["horiz/sum-keep/wc"] = [
    @pl.sum_horizontal([@pl.col("i"), @pl.col("i32")], ignore_nulls=false).alias(
      "w",
    ),
  ]
}

///|
/// Every case id with the expressions it builds.
fn golden_expr_shape_cases() -> Map[String, Array[@pl.Expr]] {
  let m : Map[String, Array[@pl.Expr]] = Map([])
  golden_expr_shape_cases_0(m)
  golden_expr_shape_cases_1(m)
  golden_expr_shape_cases_2(m)
  golden_expr_shape_cases_3(m)
  golden_expr_shape_cases_4(m)
  golden_expr_shape_cases_5(m)
  golden_expr_shape_cases_6(m)
  golden_expr_shape_cases_7(m)
  golden_expr_shape_cases_8(m)
  golden_expr_shape_cases_9(m)
  golden_expr_shape_cases_10(m)
  golden_expr_shape_cases_11(m)
  golden_expr_shape_cases_12(m)
  golden_expr_shape_cases_13(m)
  golden_expr_shape_cases_14(m)
  golden_expr_shape_cases_15(m)
  golden_expr_shape_cases_16(m)
  golden_expr_shape_cases_17(m)
  m
}
