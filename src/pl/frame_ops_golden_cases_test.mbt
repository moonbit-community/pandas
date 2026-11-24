// 由 docs/golden/scripts/frame_ops.py 生成，勿手改

///|
fn golden_frame_ops_cases_0(
  m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError],
) -> Unit {
  m["filter/t/b"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("b"))
  }
  m["filter/t/not-b"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("b").not_())
  }
  m["filter/t/i32>0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("i32").gt(@pl.lit_int(0L)))
  }
  m["filter/t/i32>=1"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("i32").ge(@pl.lit_int(1L)))
  }
  m["filter/t/i64<25"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("i64").lt(@pl.lit_int(25L)))
  }
  m["filter/t/and"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("i32").gt(@pl.lit_int(0L)) & @pl.col("b"))
  }
  m["filter/t/or"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("b") | @pl.col("i32").lt(@pl.lit_int(0L)))
  }
  m["filter/t/s==a"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("s").eq(@pl.lit_str("a")))
  }
  m["filter/t/s>z"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("s").gt(@pl.lit_str("😀")))
  }
  m["filter/t/f64>0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("f64").gt(@pl.lit_float(0.0)))
  }
  m["filter/t/f64==nan"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("f64").eq(@pl.lit_float(0.0 / 0.0)))
  }
  m["filter/t/f32==-0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("f32").eq(@pl.lit_float(0.0)))
  }
  m["filter/t/is_null"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("i32").is_null())
  }
  m["filter/t/not-is_null"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("i32").is_null().not_())
  }
  m["filter/t/d>0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("d").gt(@pl.lit(@pl.AnyValue::Date(0))))
  }
  m["filter/t/dt<5"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("dt").lt(@pl.lit(@pl.AnyValue::Datetime(5L))))
  }
  m["filter/t/lit-true"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_bool(true))
  }
  m["filter/t/lit-false"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_bool(false))
  }
  m["filter/t/lit-bool-expr"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit(@pl.AnyValue::Boolean(true)))
  }
  m["filter/t/neg-b"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("b") & @pl.lit_bool(true))
  }
  m["filter/p/a>1"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("a").gt(@pl.lit_int(1L)))
  }
  m["filter/p/all-true"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("a").ge(@pl.lit_int(0L)))
  }
  m["filter/p/none-true"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("a").gt(@pl.lit_int(9L)))
  }
  m["filter/p/lit-true"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_bool(true))
  }
  m["filter/p/lit-false"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_bool(false))
  }
  m["filter/e0/lit-true"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_bool(true))
  }
  m["filter/e0/lit-false"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_bool(false))
  }
  m["filter/z0/lit-true"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_bool(true))
  }
  m["filter/z0/lit-false"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_bool(false))
  }
  m["filter/e0/b"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("b"))
  }
  m["filter/e0/i32>0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("i32").gt(@pl.lit_int(0L)))
  }
  m["filter/t/not-bool/i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("i32"))
  }
  m["filter/t/not-bool/i64"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("i64"))
  }
  m["filter/t/not-bool/f32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("f32"))
  }
  m["filter/t/not-bool/f64"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("f64"))
  }
  m["filter/t/not-bool/s"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("s"))
  }
  m["filter/t/not-bool/d"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("d"))
  }
  m["filter/t/not-bool/dt"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("dt"))
  }
  m["filter/t/not-bool/n"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("n"))
  }
  m["filter/t/lit-int"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(1L))
  }
  m["filter/t/lit-int-big"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(3000000000L))
  }
  m["filter/t/lit-float"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_float(1.5))
  }
  m["filter/t/weak/alias"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(1L).alias("x"))
  }
  m["filter/t/weak/neg"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(-@pl.lit_int(1L))
  }
  m["filter/t/weak/neg-big"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(-@pl.lit_int(3000000000L))
  }
  m["filter/t/weak/add"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(1L) + @pl.lit_int(2L))
  }
  m["filter/t/weak/add-big"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(3000000000L) + @pl.lit_int(1L))
  }
  m["filter/t/weak/mul"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(2L) * @pl.lit_int(3L))
  }
  m["filter/t/weak/float-add"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_float(1.5) + @pl.lit_int(1L))
  }
  m["filter/t/weak/float-neg"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(-@pl.lit_float(1.5))
  }
  m["filter/t/weak/float-alias"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_float(1.5).alias("y"))
  }
  m["filter/t/weak/alias-neg-add"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter((-(@pl.lit_int(5L) - @pl.lit_int(2L))).alias("z"))
  }
  m["filter/t/weak/e0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(1L).alias("x"))
  }
  m["filter/t/weak/strong-col-alias"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("b").alias("x"))
  }
  m["filter/t/weak/plus-col"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("i32").gt(@pl.lit_int(1L) + @pl.lit_int(2L)))
  }
  m["filter/t/weak/rem-zero"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(3L) % @pl.lit_int(0L))
  }
  m["filter/t/weak/fdiv-zero"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(3L).floor_div(@pl.lit_int(0L)))
  }
  m["filter/t/weak/float-rem-zero"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_float(3.0) % @pl.lit_float(0.0))
  }
  m["filter/t/weak/max-add"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(9223372036854775807L) + @pl.lit_int(1L))
  }
  m["filter/t/weak/mul-overflow"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(4611686018427387904L) * @pl.lit_int(2L))
  }
}

///|
fn golden_frame_ops_cases_1(
  m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError],
) -> Unit {
  m["filter/t/weak/min-sub"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(-9223372036854775807L - 1L) - @pl.lit_int(1L))
  }
  m["filter/t/weak/neg-min"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(-@pl.lit_int(-9223372036854775807L - 1L))
  }
  m["filter/t/weak/i32max-add"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(2147483647L) + @pl.lit_int(1L))
  }
  m["filter/t/weak/null-add"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit(@pl.AnyValue::Null) + @pl.lit_int(1L))
  }
  m["filter/t/weak/add-null"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(1L) + @pl.lit(@pl.AnyValue::Null))
  }
  m["filter/t/weak/null-mul-float"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit(@pl.AnyValue::Null) * @pl.lit_float(1.5))
  }
  m["filter/t/weak/neg-null"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(-@pl.lit(@pl.AnyValue::Null))
  }
  m["filter/t/weak/and-int"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(1L) & @pl.lit_int(2L))
  }
  m["filter/t/weak/or-int"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(1L) | @pl.lit_int(2L))
  }
  m["filter/t/weak/and-int-big"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(3000000000L) & @pl.lit_int(1L))
  }
  m["filter/t/weak/not-int"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_int(1L).not_())
  }
  m["filter/t/lit-str"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit_str("a"))
  }
  m["filter/t/lit-null"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit(@pl.AnyValue::Null))
  }
  m["filter/t/lit-i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.lit(@pl.AnyValue::Int32(1)))
  }
  m["filter/t/missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("zz"))
  }
  m["filter/t/two-cols"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.cols(["b", "i32"]))
  }
  m["filter/t/one-of-cols"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.cols(["b"]))
  }
  m["filter/t/neg-int"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(-@pl.col("i32"))
  }
  m["filter/z0/missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("a"))
  }
  m["filter/z0/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.all())
  }
  m["filter/t/all-bool"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.all())
  }
  m["filter/t/null-pred"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.filter(@pl.col("n").eq(@pl.lit_int(1L)))
  }
  m["sort/t/i32/dFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32")])
  }
  m["sort/t/i32/dFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32")], nulls_last=true)
  }
  m["sort/t/i32/dTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32")], descending=[true])
  }
  m["sort/t/i32/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32")], descending=[true], nulls_last=true)
  }
  m["sort/t/i64/dFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i64")])
  }
  m["sort/t/i64/dFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i64")], nulls_last=true)
  }
  m["sort/t/i64/dTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i64")], descending=[true])
  }
  m["sort/t/i64/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i64")], descending=[true], nulls_last=true)
  }
  m["sort/t/f32/dFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f32")])
  }
  m["sort/t/f32/dFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f32")], nulls_last=true)
  }
  m["sort/t/f32/dTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f32")], descending=[true])
  }
  m["sort/t/f32/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f32")], descending=[true], nulls_last=true)
  }
  m["sort/t/f64/dFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f64")])
  }
  m["sort/t/f64/dFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f64")], nulls_last=true)
  }
  m["sort/t/f64/dTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f64")], descending=[true])
  }
  m["sort/t/f64/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f64")], descending=[true], nulls_last=true)
  }
  m["sort/t/s/dFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("s")])
  }
  m["sort/t/s/dFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("s")], nulls_last=true)
  }
  m["sort/t/s/dTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("s")], descending=[true])
  }
  m["sort/t/s/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("s")], descending=[true], nulls_last=true)
  }
  m["sort/t/b/dFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b")])
  }
  m["sort/t/b/dFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b")], nulls_last=true)
  }
  m["sort/t/b/dTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b")], descending=[true])
  }
  m["sort/t/b/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b")], descending=[true], nulls_last=true)
  }
  m["sort/t/d/dFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("d")])
  }
  m["sort/t/d/dFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("d")], nulls_last=true)
  }
  m["sort/t/d/dTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("d")], descending=[true])
  }
  m["sort/t/d/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("d")], descending=[true], nulls_last=true)
  }
  m["sort/t/dt/dFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("dt")])
  }
  m["sort/t/dt/dFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("dt")], nulls_last=true)
  }
  m["sort/t/dt/dTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("dt")], descending=[true])
  }
  m["sort/t/dt/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("dt")], descending=[true], nulls_last=true)
  }
  m["sort/t/n/dFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("n")])
  }
  m["sort/t/n/dFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("n")], nulls_last=true)
  }
  m["sort/t/n/dTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("n")], descending=[true])
  }
  m["sort/t/n/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("n")], descending=[true], nulls_last=true)
  }
  m["sort/t/i32,s/dFFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("s")], descending=[])
  }
  m["sort/t/i32,s/dFFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("s")], descending=[], nulls_last=true)
  }
}

///|
fn golden_frame_ops_cases_2(
  m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError],
) -> Unit {
  m["sort/t/i32,s/dTTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("s")], descending=[true])
  }
  m["sort/t/i32,s/dTTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("s")], descending=[true], nulls_last=true)
  }
  m["sort/t/i32,s/dTFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("s")], descending=[true, false])
  }
  m["sort/t/i32,s/dTFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("i32"), @pl.col("s")],
      descending=[true, false],
      nulls_last=true,
    )
  }
  m["sort/t/i32,s/dFTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("s")], descending=[false, true])
  }
  m["sort/t/i32,s/dFTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("i32"), @pl.col("s")],
      descending=[false, true],
      nulls_last=true,
    )
  }
  m["sort/t/b,f64/dFFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("f64")], descending=[])
  }
  m["sort/t/b,f64/dFFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("f64")], descending=[], nulls_last=true)
  }
  m["sort/t/b,f64/dTTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("f64")], descending=[true])
  }
  m["sort/t/b,f64/dTTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("f64")], descending=[true], nulls_last=true)
  }
  m["sort/t/b,f64/dTFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("f64")], descending=[true, false])
  }
  m["sort/t/b,f64/dTFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("b"), @pl.col("f64")],
      descending=[true, false],
      nulls_last=true,
    )
  }
  m["sort/t/b,f64/dFTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("f64")], descending=[false, true])
  }
  m["sort/t/b,f64/dFTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("b"), @pl.col("f64")],
      descending=[false, true],
      nulls_last=true,
    )
  }
  m["sort/t/s,i64/dFFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("s"), @pl.col("i64")], descending=[])
  }
  m["sort/t/s,i64/dFFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("s"), @pl.col("i64")], descending=[], nulls_last=true)
  }
  m["sort/t/s,i64/dTTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("s"), @pl.col("i64")], descending=[true])
  }
  m["sort/t/s,i64/dTTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("s"), @pl.col("i64")], descending=[true], nulls_last=true)
  }
  m["sort/t/s,i64/dTFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("s"), @pl.col("i64")], descending=[true, false])
  }
  m["sort/t/s,i64/dTFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("s"), @pl.col("i64")],
      descending=[true, false],
      nulls_last=true,
    )
  }
  m["sort/t/s,i64/dFTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("s"), @pl.col("i64")], descending=[false, true])
  }
  m["sort/t/s,i64/dFTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("s"), @pl.col("i64")],
      descending=[false, true],
      nulls_last=true,
    )
  }
  m["sort/t/f64,i32/dFFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f64"), @pl.col("i32")], descending=[])
  }
  m["sort/t/f64,i32/dFFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f64"), @pl.col("i32")], descending=[], nulls_last=true)
  }
  m["sort/t/f64,i32/dTTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f64"), @pl.col("i32")], descending=[true])
  }
  m["sort/t/f64,i32/dTTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("f64"), @pl.col("i32")],
      descending=[true],
      nulls_last=true,
    )
  }
  m["sort/t/f64,i32/dTFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f64"), @pl.col("i32")], descending=[true, false])
  }
  m["sort/t/f64,i32/dTFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("f64"), @pl.col("i32")],
      descending=[true, false],
      nulls_last=true,
    )
  }
  m["sort/t/f64,i32/dFTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f64"), @pl.col("i32")], descending=[false, true])
  }
  m["sort/t/f64,i32/dFTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("f64"), @pl.col("i32")],
      descending=[false, true],
      nulls_last=true,
    )
  }
  m["sort/t/f32,dt/dFFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f32"), @pl.col("dt")], descending=[])
  }
  m["sort/t/f32,dt/dFFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f32"), @pl.col("dt")], descending=[], nulls_last=true)
  }
  m["sort/t/f32,dt/dTTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f32"), @pl.col("dt")], descending=[true])
  }
  m["sort/t/f32,dt/dTTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f32"), @pl.col("dt")], descending=[true], nulls_last=true)
  }
  m["sort/t/f32,dt/dTFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f32"), @pl.col("dt")], descending=[true, false])
  }
  m["sort/t/f32,dt/dTFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("f32"), @pl.col("dt")],
      descending=[true, false],
      nulls_last=true,
    )
  }
  m["sort/t/f32,dt/dFTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f32"), @pl.col("dt")], descending=[false, true])
  }
  m["sort/t/f32,dt/dFTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("f32"), @pl.col("dt")],
      descending=[false, true],
      nulls_last=true,
    )
  }
  m["sort/t/d,b/dFFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("d"), @pl.col("b")], descending=[])
  }
  m["sort/t/d,b/dFFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("d"), @pl.col("b")], descending=[], nulls_last=true)
  }
  m["sort/t/d,b/dTTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("d"), @pl.col("b")], descending=[true])
  }
  m["sort/t/d,b/dTTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("d"), @pl.col("b")], descending=[true], nulls_last=true)
  }
  m["sort/t/d,b/dTFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("d"), @pl.col("b")], descending=[true, false])
  }
  m["sort/t/d,b/dTFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("d"), @pl.col("b")],
      descending=[true, false],
      nulls_last=true,
    )
  }
  m["sort/t/d,b/dFTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("d"), @pl.col("b")], descending=[false, true])
  }
  m["sort/t/d,b/dFTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("d"), @pl.col("b")],
      descending=[false, true],
      nulls_last=true,
    )
  }
  m["sort/t/n,i32/dFFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("n"), @pl.col("i32")], descending=[])
  }
  m["sort/t/n,i32/dFFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("n"), @pl.col("i32")], descending=[], nulls_last=true)
  }
  m["sort/t/n,i32/dTTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("n"), @pl.col("i32")], descending=[true])
  }
  m["sort/t/n,i32/dTTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("n"), @pl.col("i32")], descending=[true], nulls_last=true)
  }
  m["sort/t/n,i32/dTFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("n"), @pl.col("i32")], descending=[true, false])
  }
  m["sort/t/n,i32/dTFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("n"), @pl.col("i32")],
      descending=[true, false],
      nulls_last=true,
    )
  }
  m["sort/t/n,i32/dFTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("n"), @pl.col("i32")], descending=[false, true])
  }
  m["sort/t/n,i32/dFTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("n"), @pl.col("i32")],
      descending=[false, true],
      nulls_last=true,
    )
  }
  m["sort/t/i64,i64/dFFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i64"), @pl.col("i64")], descending=[])
  }
  m["sort/t/i64,i64/dFFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i64"), @pl.col("i64")], descending=[], nulls_last=true)
  }
  m["sort/t/i64,i64/dTTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i64"), @pl.col("i64")], descending=[true])
  }
  m["sort/t/i64,i64/dTTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("i64"), @pl.col("i64")],
      descending=[true],
      nulls_last=true,
    )
  }
  m["sort/t/i64,i64/dTFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i64"), @pl.col("i64")], descending=[true, false])
  }
  m["sort/t/i64,i64/dTFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("i64"), @pl.col("i64")],
      descending=[true, false],
      nulls_last=true,
    )
  }
}

///|
fn golden_frame_ops_cases_3(
  m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError],
) -> Unit {
  m["sort/t/i64,i64/dFTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i64"), @pl.col("i64")], descending=[false, true])
  }
  m["sort/t/i64,i64/dFTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("i64"), @pl.col("i64")],
      descending=[false, true],
      nulls_last=true,
    )
  }
  m["sort/t/b,s,i32/dTFTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("s"), @pl.col("i32")], descending=[
      true, false, true,
    ])
  }
  m["sort/t/b,s,i32/dTFTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("b"), @pl.col("s"), @pl.col("i32")],
      descending=[true, false, true],
      nulls_last=true,
    )
  }
  m["sort/t/b,s,i32/dFTFnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("s"), @pl.col("i32")], descending=[
      false, true, false,
    ])
  }
  m["sort/t/b,s,i32/dFTFnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("b"), @pl.col("s"), @pl.col("i32")],
      descending=[false, true, false],
      nulls_last=true,
    )
  }
  m["sort/t/b,s,i32/dTTTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("s"), @pl.col("i32")], descending=[
      true, true, true,
    ])
  }
  m["sort/t/b,s,i32/dTTTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("b"), @pl.col("s"), @pl.col("i32")],
      descending=[true, true, true],
      nulls_last=true,
    )
  }
  m["sort/t/b,s,i32/dFFTnF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("s"), @pl.col("i32")], descending=[
      false, false, true,
    ])
  }
  m["sort/t/b,s,i32/dFFTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("b"), @pl.col("s"), @pl.col("i32")],
      descending=[false, false, true],
      nulls_last=true,
    )
  }
  m["sort/t/b,s,i32/nodesc"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("s"), @pl.col("i32")])
  }
  m["sort/t/b,s,i32/desc1"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b"), @pl.col("s"), @pl.col("i32")], descending=[true])
  }
  m["sort/t/i32,i64,f64/d[F]"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("i64"), @pl.col("f64")], descending=[false])
  }
  m["sort/p/a"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("a")])
  }
  m["sort/p/a,b/dTF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("a"), @pl.col("b")], descending=[true, false])
  }
  m["sort/p/c,a/dFT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("c"), @pl.col("a")], descending=[false, true])
  }
  m["sort/p/c/dT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("c")], descending=[true])
  }
  m["sort/t/expr/neg-i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([-@pl.col("i32")])
  }
  m["sort/t/expr/neg-i32/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([-@pl.col("i32")], descending=[true], nulls_last=true)
  }
  m["sort/t/expr/neg-f64"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([-@pl.col("f64")])
  }
  m["sort/t/expr/neg-f64/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([-@pl.col("f64")], descending=[true], nulls_last=true)
  }
  m["sort/t/expr/i32*-1"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32") * @pl.lit_int(-1L)])
  }
  m["sort/t/expr/i32*-1/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("i32") * @pl.lit_int(-1L)],
      descending=[true],
      nulls_last=true,
    )
  }
  m["sort/t/expr/i32+i64"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32") + @pl.col("i64")])
  }
  m["sort/t/expr/i32+i64/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("i32") + @pl.col("i64")],
      descending=[true],
      nulls_last=true,
    )
  }
  m["sort/t/expr/i32-i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32") - @pl.col("i32")])
  }
  m["sort/t/expr/i32-i32/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("i32") - @pl.col("i32")],
      descending=[true],
      nulls_last=true,
    )
  }
  m["sort/t/expr/is_null-i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32").is_null()])
  }
  m["sort/t/expr/is_null-i32/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32").is_null()], descending=[true], nulls_last=true)
  }
  m["sort/t/expr/not-b"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b").not_()])
  }
  m["sort/t/expr/not-b/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b").not_()], descending=[true], nulls_last=true)
  }
  m["sort/t/expr/i32>0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32").gt(@pl.lit_int(0L))])
  }
  m["sort/t/expr/i32>0/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("i32").gt(@pl.lit_int(0L))],
      descending=[true],
      nulls_last=true,
    )
  }
  m["sort/t/expr/f64*2"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("f64") * @pl.lit_float(2.0)])
  }
  m["sort/t/expr/f64*2/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("f64") * @pl.lit_float(2.0)],
      descending=[true],
      nulls_last=true,
    )
  }
  m["sort/t/expr/cast-i32-f64"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32").cast(@pl.DataType::Float64)])
  }
  m["sort/t/expr/cast-i32-f64/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("i32").cast(@pl.DataType::Float64)],
      descending=[true],
      nulls_last=true,
    )
  }
  m["sort/t/expr/cast-b-i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("b").cast(@pl.DataType::Int32)])
  }
  m["sort/t/expr/cast-b-i32/dTnT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort(
      [@pl.col("b").cast(@pl.DataType::Int32)],
      descending=[true],
      nulls_last=true,
    )
  }
  m["sort/t/expr/is_null,s"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32").is_null(), @pl.col("s")], descending=[true, false])
  }
  m["sort/t/expr/neg,i64"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([-@pl.col("i32"), @pl.col("i64")], descending=[false, true])
  }
  m["sort/t/cols-i32,s"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.cols(["i32", "s"])])
  }
  m["sort/t/cols-i32,s/dTF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.cols(["i32", "s"])], descending=[true, false])
  }
  m["sort/t/cols-i32,s/dT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.cols(["i32", "s"])], descending=[true])
  }
  m["sort/t/cols+f64/dTFT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.cols(["i32", "s"]), @pl.col("f64")], descending=[
      true, false, true,
    ])
  }
  m["sort/t/cols+f64/dTF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.cols(["i32", "s"]), @pl.col("f64")], descending=[true, false])
  }
  m["sort/t/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.all()])
  }
  m["sort/t/all/dT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.all()], descending=[true], nulls_last=true)
  }
  m["sort/p/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.all()])
  }
  m["sort/t/dup-keys"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("i32")])
  }
  m["sort/t/dup-keys/dTF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("i32")], descending=[true, false])
  }
  m["sort/t/no-keys"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([])
  }
  m["sort/t/no-keys/nlT"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([], nulls_last=true)
  }
  m["sort/e0/i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32")])
  }
  m["sort/e0/i32,s/dTF"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("s")], descending=[true, false])
  }
  m["sort/z0/no-keys"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([])
  }
  m["sort/err/desc3-by2"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("s")], descending=[true, false, true])
  }
  m["sort/err/desc4-by2"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("s")], descending=[
      true, false, true, false,
    ])
  }
  m["sort/err/desc2-by1"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32")], descending=[true, false])
  }
  m["sort/err/desc2-by3"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("s"), @pl.col("b")], descending=[
      true, false,
    ])
  }
}

///|
fn golden_frame_ops_cases_4(
  m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError],
) -> Unit {
  m["sort/err/desc4-by3"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("s"), @pl.col("b")], descending=[
      true, false, true, false,
    ])
  }
  m["sort/err/desc3-by2-missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("zz"), @pl.col("i32")], descending=[true, false, true])
  }
  m["sort/err/missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("zz")])
  }
  m["sort/err/second-missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.col("zz")])
  }
  m["sort/err/missing-e0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("zz")])
  }
  m["sort/err/lit-int"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.lit_int(1L)])
  }
  m["sort/err/col+lit"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.col("i32"), @pl.lit_int(1L)])
  }
  m["sort/err/lit-str"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.lit_str("a")])
  }
  m["sort/err/lit-e0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.lit_int(1L)])
  }
  m["sort/err/lit-z0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.lit_int(1L)])
  }
  m["sort/err/lit-p"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.sort([@pl.lit_bool(true)])
  }
  m["unique/t/all/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(maintain_order=true)
  }
  m["unique/t/all/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(keep=@pl.UniqueKeep::First, maintain_order=true)
  }
  m["unique/t/all/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(keep=@pl.UniqueKeep::Last, maintain_order=true)
  }
  m["unique/t/all/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(keep=@pl.UniqueKeep::KeepNone, maintain_order=true)
  }
  m["unique/t/i32/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["i32"], maintain_order=true)
  }
  m["unique/t/i32/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["i32"], keep=@pl.UniqueKeep::First, maintain_order=true)
  }
  m["unique/t/i32/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["i32"], keep=@pl.UniqueKeep::Last, maintain_order=true)
  }
  m["unique/t/i32/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["i32"],
      keep=@pl.UniqueKeep::KeepNone,
      maintain_order=true,
    )
  }
  m["unique/t/i64,s/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["i64", "s"], maintain_order=true)
  }
  m["unique/t/i64,s/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["i64", "s"],
      keep=@pl.UniqueKeep::First,
      maintain_order=true,
    )
  }
  m["unique/t/i64,s/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["i64", "s"],
      keep=@pl.UniqueKeep::Last,
      maintain_order=true,
    )
  }
  m["unique/t/i64,s/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["i64", "s"],
      keep=@pl.UniqueKeep::KeepNone,
      maintain_order=true,
    )
  }
  m["unique/t/f64/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["f64"], maintain_order=true)
  }
  m["unique/t/f64/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["f64"], keep=@pl.UniqueKeep::First, maintain_order=true)
  }
  m["unique/t/f64/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["f64"], keep=@pl.UniqueKeep::Last, maintain_order=true)
  }
  m["unique/t/f64/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["f64"],
      keep=@pl.UniqueKeep::KeepNone,
      maintain_order=true,
    )
  }
  m["unique/t/f32/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["f32"], maintain_order=true)
  }
  m["unique/t/f32/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["f32"], keep=@pl.UniqueKeep::First, maintain_order=true)
  }
  m["unique/t/f32/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["f32"], keep=@pl.UniqueKeep::Last, maintain_order=true)
  }
  m["unique/t/f32/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["f32"],
      keep=@pl.UniqueKeep::KeepNone,
      maintain_order=true,
    )
  }
  m["unique/t/b/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["b"], maintain_order=true)
  }
  m["unique/t/b/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["b"], keep=@pl.UniqueKeep::First, maintain_order=true)
  }
  m["unique/t/b/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["b"], keep=@pl.UniqueKeep::Last, maintain_order=true)
  }
  m["unique/t/b/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["b"], keep=@pl.UniqueKeep::KeepNone, maintain_order=true)
  }
  m["unique/t/n/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["n"], maintain_order=true)
  }
  m["unique/t/n/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["n"], keep=@pl.UniqueKeep::First, maintain_order=true)
  }
  m["unique/t/n/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["n"], keep=@pl.UniqueKeep::Last, maintain_order=true)
  }
  m["unique/t/n/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["n"], keep=@pl.UniqueKeep::KeepNone, maintain_order=true)
  }
  m["unique/t/s,d/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["s", "d"], maintain_order=true)
  }
  m["unique/t/s,d/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["s", "d"],
      keep=@pl.UniqueKeep::First,
      maintain_order=true,
    )
  }
  m["unique/t/s,d/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["s", "d"], keep=@pl.UniqueKeep::Last, maintain_order=true)
  }
  m["unique/t/s,d/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["s", "d"],
      keep=@pl.UniqueKeep::KeepNone,
      maintain_order=true,
    )
  }
  m["unique/t/dt,n/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["dt", "n"], maintain_order=true)
  }
  m["unique/t/dt,n/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["dt", "n"],
      keep=@pl.UniqueKeep::First,
      maintain_order=true,
    )
  }
  m["unique/t/dt,n/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["dt", "n"],
      keep=@pl.UniqueKeep::Last,
      maintain_order=true,
    )
  }
  m["unique/t/dt,n/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["dt", "n"],
      keep=@pl.UniqueKeep::KeepNone,
      maintain_order=true,
    )
  }
  m["unique/t/s/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["s"], maintain_order=true)
  }
  m["unique/t/s/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["s"], keep=@pl.UniqueKeep::First, maintain_order=true)
  }
  m["unique/t/s/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["s"], keep=@pl.UniqueKeep::Last, maintain_order=true)
  }
  m["unique/t/s/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["s"], keep=@pl.UniqueKeep::KeepNone, maintain_order=true)
  }
  m["unique/t/i32,i64,f64,s,b/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["i32", "i64", "f64", "s", "b"], maintain_order=true)
  }
  m["unique/t/i32,i64,f64,s,b/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["i32", "i64", "f64", "s", "b"],
      keep=@pl.UniqueKeep::First,
      maintain_order=true,
    )
  }
  m["unique/t/i32,i64,f64,s,b/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["i32", "i64", "f64", "s", "b"],
      keep=@pl.UniqueKeep::Last,
      maintain_order=true,
    )
  }
  m["unique/t/i32,i64,f64,s,b/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["i32", "i64", "f64", "s", "b"],
      keep=@pl.UniqueKeep::KeepNone,
      maintain_order=true,
    )
  }
  m["unique/t/all/first/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(keep=@pl.UniqueKeep::First, maintain_order=false)
  }
  m["unique/t/all/last/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(keep=@pl.UniqueKeep::Last, maintain_order=false)
  }
  m["unique/t/all/none/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(keep=@pl.UniqueKeep::KeepNone, maintain_order=false)
  }
  m["unique/t/i32/first/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["i32"], keep=@pl.UniqueKeep::First, maintain_order=false)
  }
  m["unique/t/i32/last/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["i32"], keep=@pl.UniqueKeep::Last, maintain_order=false)
  }
}

///|
fn golden_frame_ops_cases_5(
  m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError],
) -> Unit {
  m["unique/t/i32/none/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["i32"],
      keep=@pl.UniqueKeep::KeepNone,
      maintain_order=false,
    )
  }
  m["unique/t/f64/first/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["f64"], keep=@pl.UniqueKeep::First, maintain_order=false)
  }
  m["unique/t/f64/last/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["f64"], keep=@pl.UniqueKeep::Last, maintain_order=false)
  }
  m["unique/t/f64/none/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["f64"],
      keep=@pl.UniqueKeep::KeepNone,
      maintain_order=false,
    )
  }
  m["unique/t/s/first/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["s"], keep=@pl.UniqueKeep::First, maintain_order=false)
  }
  m["unique/t/s/last/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["s"], keep=@pl.UniqueKeep::Last, maintain_order=false)
  }
  m["unique/t/s/none/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["s"], keep=@pl.UniqueKeep::KeepNone, maintain_order=false)
  }
  m["unique/t/b/first/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["b"], keep=@pl.UniqueKeep::First, maintain_order=false)
  }
  m["unique/t/b/last/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["b"], keep=@pl.UniqueKeep::Last, maintain_order=false)
  }
  m["unique/t/b/none/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["b"], keep=@pl.UniqueKeep::KeepNone, maintain_order=false)
  }
  m["unique/t/n/first/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["n"], keep=@pl.UniqueKeep::First, maintain_order=false)
  }
  m["unique/t/n/last/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["n"], keep=@pl.UniqueKeep::Last, maintain_order=false)
  }
  m["unique/t/n/none/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["n"], keep=@pl.UniqueKeep::KeepNone, maintain_order=false)
  }
  m["unique/t/all/any/unordered"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(maintain_order=false)
  }
  m["unique/p/all/any"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(maintain_order=true)
  }
  m["unique/p/c/first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["c"], keep=@pl.UniqueKeep::First, maintain_order=true)
  }
  m["unique/p/c/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["c"], keep=@pl.UniqueKeep::Last, maintain_order=true)
  }
  m["unique/p/c/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["c"], keep=@pl.UniqueKeep::KeepNone, maintain_order=true)
  }
  m["unique/p/b,c/last"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["b", "c"], keep=@pl.UniqueKeep::Last, maintain_order=true)
  }
  m["unique/t/dup-names"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["i32", "i32"],
      keep=@pl.UniqueKeep::First,
      maintain_order=true,
    )
  }
  m["unique/t/order-names"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["s", "i32"],
      keep=@pl.UniqueKeep::Last,
      maintain_order=true,
    )
  }
  m["unique/e0/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(maintain_order=true)
  }
  m["unique/e0/i32/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(
      subset=["i32"],
      keep=@pl.UniqueKeep::KeepNone,
      maintain_order=true,
    )
  }
  m["unique/z0/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(maintain_order=true)
  }
  m["unique/z0/all/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(keep=@pl.UniqueKeep::KeepNone, maintain_order=true)
  }
  m["unique/err/missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["zz"], maintain_order=true)
  }
  m["unique/err/second-missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["i32", "zz"], maintain_order=true)
  }
  m["unique/err/empty-subset"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=[], maintain_order=true)
  }
  m["unique/err/z0-subset"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["a"], maintain_order=true)
  }
  m["unique/err/e0-missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.unique(subset=["zz"], keep=@pl.UniqueKeep::First, maintain_order=true)
  }
  m["drop/t/i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["i32"])
  }
  m["drop/t/i32,s"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["i32", "s"])
  }
  m["drop/t/s,i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["s", "i32"])
  }
  m["drop/t/last-first"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["n", "i32"])
  }
  m["drop/t/dup"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["i32", "i32"])
  }
  m["drop/t/none"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop([])
  }
  m["drop/t/none-nonstrict"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop([], strict=false)
  }
  m["drop/t/all-but-one"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["i64", "f32", "f64", "s", "b", "d", "dt", "n"])
  }
  m["drop/t/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["i32", "i64", "f32", "f64", "s", "b", "d", "dt", "n"])
  }
  m["drop/t/missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["zz"])
  }
  m["drop/t/missing-nonstrict"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["zz"], strict=false)
  }
  m["drop/t/missing-then-present"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["zz", "i32"])
  }
  m["drop/t/present-then-missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["i32", "zz"])
  }
  m["drop/t/two-missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["zz", "yy"])
  }
  m["drop/t/two-missing-b"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["yy", "zz"])
  }
  m["drop/t/mixed-nonstrict"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["i32", "zz", "i32", "s"], strict=false)
  }
  m["drop/t/mixed-strict"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["i32", "zz", "i32"])
  }
  m["drop/p/a"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["a"])
  }
  m["drop/e0/i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["i32"])
  }
  m["drop/e0/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["i32", "i64", "f32", "f64", "s", "b", "d", "dt", "n"])
  }
  m["drop/z0/a"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["a"])
  }
  m["drop/z0/a-nonstrict"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop(["a"], strict=false)
  }
  m["rename/t/one"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "x" })
  }
  m["rename/t/two"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "x", "s": "y" })
  }
  m["rename/t/swap"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "i64", "i64": "i32" })
  }
  m["rename/t/chain"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "i64", "i64": "f32" })
  }
  m["rename/t/rotate"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "i64", "i64": "f32", "f32": "i32" })
  }
  m["rename/t/same"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "i32" })
  }
  m["rename/t/empty-map"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename(({} : Map[String, String]))
  }
  m["rename/t/empty-name"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "" })
  }
}

///|
fn golden_frame_ops_cases_6(
  m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError],
) -> Unit {
  m["rename/t/unicode"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "s": "😀", "b": "｡" })
  }
  m["rename/t/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({
      "i32": "I32",
      "i64": "I64",
      "f32": "F32",
      "f64": "F64",
      "s": "S",
      "b": "B",
      "d": "D",
      "dt": "DT",
      "n": "N",
    })
  }
  m["rename/t/dup-existing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "s" })
  }
  m["rename/t/dup-new"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "x", "s": "x" })
  }
  m["rename/t/dup-new-3"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "x", "s": "y", "b": "x" })
  }
  m["rename/t/dup-two"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "s", "i64": "b" })
  }
  m["rename/t/dup-nonstrict"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "s", "zz": "q" }, strict=false)
  }
  m["rename/t/missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "zz": "x" })
  }
  m["rename/t/missing-nonstrict"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "zz": "x" }, strict=false)
  }
  m["rename/t/missing-two"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "zz": "x", "yy": "w" })
  }
  m["rename/t/missing-two-b"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "yy": "w", "zz": "x" })
  }
  m["rename/t/present-missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "x", "zz": "y" })
  }
  m["rename/t/missing-present"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "zz": "y", "i32": "x" })
  }
  m["rename/t/present-missing-nonstrict"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "x", "zz": "y" }, strict=false)
  }
  m["rename/t/missing-dup-strict"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "zz": "s", "i32": "s" })
  }
  m["rename/t/missing-to-existing-nonstrict"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "zz": "s" }, strict=false)
  }
  m["rename/p/a"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "a": "x" })
  }
  m["rename/e0/i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "i32": "x" })
  }
  m["rename/z0/a"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "a": "b" })
  }
  m["rename/z0/a-nonstrict"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.rename({ "a": "b" }, strict=false)
  }
  m["fill_null/t/int0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_int(0L))
  }
  m["fill_null/t/int-1"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_int(-1L))
  }
  m["fill_null/t/int3e9"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_int(3000000000L))
  }
  m["fill_null/t/int2^40"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_int(1099511627776L))
  }
  m["fill_null/t/int-max"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_int(9223372036854775807L))
  }
  m["fill_null/t/int-min"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_int(-9223372036854775807L - 1L))
  }
  m["fill_null/t/float1.5"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_float(1.5))
  }
  m["fill_null/t/float0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_float(0.0))
  }
  m["fill_null/t/float-0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_float(-0.0))
  }
  m["fill_null/t/float-nan"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_float(0.0 / 0.0))
  }
  m["fill_null/t/float-inf"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_float(1.0 / 0.0))
  }
  m["fill_null/t/float1e300"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_float(1.0e300))
  }
  m["fill_null/t/str-z"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_str("z"))
  }
  m["fill_null/t/str-empty"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_str(""))
  }
  m["fill_null/t/str-emoji"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_str("😀"))
  }
  m["fill_null/t/str-0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_str("0"))
  }
  m["fill_null/t/bool-true"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_bool(true))
  }
  m["fill_null/t/bool-false"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_bool(false))
  }
  m["fill_null/t/date"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Date(3)))
  }
  m["fill_null/t/datetime"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Datetime(7L)))
  }
  m["fill_null/t/i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Int32(0)))
  }
  m["fill_null/t/i32-neg"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Int32(-5)))
  }
  m["fill_null/t/i64"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Int64(3000000000L)))
  }
  m["fill_null/t/f32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Float32(0.5)))
  }
  m["fill_null/t/f64"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Float64(0.5)))
  }
  m["fill_null/t/f64-nan"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Float64(0.0 / 0.0)))
  }
  m["fill_null/t/null"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Null))
  }
  m["fill_null/p/int0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_int(0L))
  }
  m["fill_null/e0/int0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_int(0L))
  }
  m["fill_null/z0/int0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_int(0L))
  }
  m["fill_null/p/float1.5"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_float(1.5))
  }
  m["fill_null/e0/float1.5"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_float(1.5))
  }
  m["fill_null/z0/float1.5"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_float(1.5))
  }
  m["fill_null/p/str-z"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_str("z"))
  }
  m["fill_null/e0/str-z"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_str("z"))
  }
  m["fill_null/z0/str-z"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_str("z"))
  }
  m["fill_null/p/bool-true"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_bool(true))
  }
  m["fill_null/e0/bool-true"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_bool(true))
  }
  m["fill_null/z0/bool-true"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_bool(true))
  }
  m["fill_null/p/i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Int32(0)))
  }
}

///|
fn golden_frame_ops_cases_7(
  m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError],
) -> Unit {
  m["fill_null/e0/i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Int32(0)))
  }
  m["fill_null/z0/i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Int32(0)))
  }
  m["fill_null/p/null"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Null))
  }
  m["fill_null/e0/null"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Null))
  }
  m["fill_null/z0/null"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit(@pl.AnyValue::Null))
  }
  m["fill_null/t/expr/col-i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("i32"))
  }
  m["fill_null/t/expr/col-f64"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("f64"))
  }
  m["fill_null/t/expr/col-s"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("s"))
  }
  m["fill_null/t/expr/col-b"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("b"))
  }
  m["fill_null/t/expr/col-n"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("n"))
  }
  m["fill_null/t/expr/col-d"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("d"))
  }
  m["fill_null/t/expr/expr-i32+1"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("i32") + @pl.lit_int(1L))
  }
  m["fill_null/t/expr/neg-i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(-@pl.col("i32"))
  }
  m["fill_null/t/expr/alias"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("i64").alias("z"))
  }
  m["fill_null/p/expr/col-a"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("a"))
  }
  m["fill_null/p/expr/col-c"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("c"))
  }
  m["fill_null/e0/expr/col-i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("i32"))
  }
  m["fill_null/e0/expr/col-s"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("s"))
  }
  m["fill_null/z0/expr/col"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.col("i32"))
  }
  m["fill_null/p/expr/lit-sum"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_int(1L) + @pl.lit_int(2L))
  }
  m["fill_null/p/expr/lit-float-sum"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.lit_float(0.5) + @pl.lit_int(2L))
  }
  m["fill_null/p/expr/neg-lit"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(-@pl.lit_int(1L))
  }
  m["fill_null/t/expr/cols"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.cols(["i32", "i64"]))
  }
  m["fill_null/p/expr/cols3"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.fill_null(@pl.cols(["c", "a", "b"]))
  }
  m["drop_nulls/t/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls()
  }
  m["drop_nulls/t/i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["i32"])
  }
  m["drop_nulls/t/i32,s"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["i32", "s"])
  }
  m["drop_nulls/t/f64"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["f64"])
  }
  m["drop_nulls/t/f32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["f32"])
  }
  m["drop_nulls/t/s"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["s"])
  }
  m["drop_nulls/t/b,d"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["b", "d"])
  }
  m["drop_nulls/t/n"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["n"])
  }
  m["drop_nulls/t/i32,n"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["i32", "n"])
  }
  m["drop_nulls/t/dt"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["dt"])
  }
  m["drop_nulls/t/i64,b,dt"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["i64", "b", "dt"])
  }
  m["drop_nulls/t/i32,i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["i32", "i32"])
  }
  m["drop_nulls/t/s,i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["s", "i32"])
  }
  m["drop_nulls/t/d,b,f64"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["d", "b", "f64"])
  }
  m["drop_nulls/t/empty"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=[])
  }
  m["drop_nulls/t/missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["zz"])
  }
  m["drop_nulls/t/second-missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["i32", "zz"])
  }
  m["drop_nulls/t/two-missing"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["yy", "zz"])
  }
  m["drop_nulls/p/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls()
  }
  m["drop_nulls/p/a"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["a"])
  }
  m["drop_nulls/e0/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls()
  }
  m["drop_nulls/e0/i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["i32"])
  }
  m["drop_nulls/z0/all"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls()
  }
  m["drop_nulls/z0/empty"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=[])
  }
  m["drop_nulls/z0/a"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.drop_nulls(subset=["a"])
  }
  m["null_count/t"] = fn(df : @pl.DataFrame) -> @pl.DataFrame {
    df.null_count()
  }
  m["null_count/p"] = fn(df : @pl.DataFrame) -> @pl.DataFrame {
    df.null_count()
  }
  m["null_count/e0"] = fn(df : @pl.DataFrame) -> @pl.DataFrame {
    df.null_count()
  }
  m["null_count/z0"] = fn(df : @pl.DataFrame) -> @pl.DataFrame {
    df.null_count()
  }
  m["with_row_index/t/default"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index()
  }
  m["with_row_index/p/default"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index()
  }
  m["with_row_index/e0/default"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index()
  }
  m["with_row_index/z0/default"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index()
  }
  m["with_row_index/t/name"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(name="r")
  }
  m["with_row_index/t/offset"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(offset=5)
  }
  m["with_row_index/t/name+offset"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(name="r", offset=100)
  }
}

///|
fn golden_frame_ops_cases_8(
  m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError],
) -> Unit {
  m["with_row_index/t/offset0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(offset=0)
  }
  m["with_row_index/t/offset-max"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(offset=2147483647)
  }
  m["with_row_index/t/offset-1000000000"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(offset=1000000000)
  }
  m["with_row_index/t/empty-name"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(name="")
  }
  m["with_row_index/t/unicode-name"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(name="😀")
  }
  m["with_row_index/p/name"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(name="row")
  }
  m["with_row_index/e0/offset"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(offset=3)
  }
  m["with_row_index/z0/name+offset"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(name="r", offset=4)
  }
  m["with_row_index/err/dup-i32"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(name="i32")
  }
  m["with_row_index/err/dup-n"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(name="n", offset=1)
  }
  m["with_row_index/err/dup-e0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(name="s")
  }
  m["with_row_index/err/neg-1"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(offset=-1)
  }
  m["with_row_index/err/neg-big"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(offset=-2147483647 - 1)
  }
  m["with_row_index/err/neg-dup"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(name="i32", offset=-1)
  }
  m["with_row_index/err/neg-z0"] = fn(
    df : @pl.DataFrame,
  ) -> @pl.DataFrame raise @pl.PolarsError {
    df.with_row_index(offset=-3)
  }
}

///|
/// Every case id with the operation it runs.
fn golden_frame_ops_cases() -> Map[
  String,
  (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError,
] {
  let m : Map[String, (@pl.DataFrame) -> @pl.DataFrame raise @pl.PolarsError] = Map([],
  )
  golden_frame_ops_cases_0(m)
  golden_frame_ops_cases_1(m)
  golden_frame_ops_cases_2(m)
  golden_frame_ops_cases_3(m)
  golden_frame_ops_cases_4(m)
  golden_frame_ops_cases_5(m)
  golden_frame_ops_cases_6(m)
  golden_frame_ops_cases_7(m)
  golden_frame_ops_cases_8(m)
  m
}
