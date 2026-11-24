// 由 docs/golden/scripts/group_final.py 生成，勿手改

///|
fn golden_group_final_cases_0(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["parse/over/first/dd/date/strict"] = (
    [],
    [@pl.col("sd").str().to_date(strict=true).first().over([@pl.col("k")])],
  )
  m["parse/over/count/dd/date/strict"] = (
    [],
    [@pl.col("sd").str().to_date(strict=true).count().over([@pl.col("k")])],
  )
  m["parse/over/row/dd/date/strict"] = (
    [],
    [@pl.col("sd").str().to_date(strict=true).over([@pl.col("k")])],
  )
  m["parse/over/key/dd/date/strict"] = (
    [],
    [@pl.col("v").sum().over([@pl.col("sd").str().to_date(strict=true)])],
  )
  m["parse/select/dd/date/strict"] = (
    [],
    [@pl.col("sd").str().to_date(strict=true)],
  )
  m["parse/over/first/dd/date/lenient"] = (
    [],
    [@pl.col("sd").str().to_date(strict=false).first().over([@pl.col("k")])],
  )
  m["parse/over/count/dd/date/lenient"] = (
    [],
    [@pl.col("sd").str().to_date(strict=false).count().over([@pl.col("k")])],
  )
  m["parse/over/row/dd/date/lenient"] = (
    [],
    [@pl.col("sd").str().to_date(strict=false).over([@pl.col("k")])],
  )
  m["parse/over/key/dd/date/lenient"] = (
    [],
    [@pl.col("v").sum().over([@pl.col("sd").str().to_date(strict=false)])],
  )
  m["parse/select/dd/date/lenient"] = (
    [],
    [@pl.col("sd").str().to_date(strict=false)],
  )
  m["parse/over/first/dd/datetime/strict"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=true).first().over([@pl.col("k")])],
  )
  m["parse/over/count/dd/datetime/strict"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=true).count().over([@pl.col("k")])],
  )
  m["parse/over/row/dd/datetime/strict"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=true).over([@pl.col("k")])],
  )
  m["parse/over/key/dd/datetime/strict"] = (
    [],
    [@pl.col("v").sum().over([@pl.col("st").str().to_datetime(strict=true)])],
  )
  m["parse/select/dd/datetime/strict"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=true)],
  )
  m["parse/over/first/dd/datetime/lenient"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=false).first().over([@pl.col("k")])],
  )
  m["parse/over/count/dd/datetime/lenient"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=false).count().over([@pl.col("k")])],
  )
  m["parse/over/row/dd/datetime/lenient"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=false).over([@pl.col("k")])],
  )
  m["parse/over/key/dd/datetime/lenient"] = (
    [],
    [@pl.col("v").sum().over([@pl.col("st").str().to_datetime(strict=false)])],
  )
  m["parse/select/dd/datetime/lenient"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=false)],
  )
  m["parse/over/first/ddx/date/lenient"] = (
    [],
    [@pl.col("sd").str().to_date(strict=false).first().over([@pl.col("k")])],
  )
  m["parse/over/count/ddx/date/lenient"] = (
    [],
    [@pl.col("sd").str().to_date(strict=false).count().over([@pl.col("k")])],
  )
  m["parse/over/row/ddx/date/lenient"] = (
    [],
    [@pl.col("sd").str().to_date(strict=false).over([@pl.col("k")])],
  )
  m["parse/over/key/ddx/date/lenient"] = (
    [],
    [@pl.col("v").sum().over([@pl.col("sd").str().to_date(strict=false)])],
  )
  m["parse/select/ddx/date/lenient"] = (
    [],
    [@pl.col("sd").str().to_date(strict=false)],
  )
  m["parse/over/first/ddx/datetime/lenient"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=false).first().over([@pl.col("k")])],
  )
  m["parse/over/count/ddx/datetime/lenient"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=false).count().over([@pl.col("k")])],
  )
  m["parse/over/row/ddx/datetime/lenient"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=false).over([@pl.col("k")])],
  )
  m["parse/over/key/ddx/datetime/lenient"] = (
    [],
    [@pl.col("v").sum().over([@pl.col("st").str().to_datetime(strict=false)])],
  )
  m["parse/select/ddx/datetime/lenient"] = (
    [],
    [@pl.col("st").str().to_datetime(strict=false)],
  )
  m["kernel/over/lit/v/sum"] = (
    [],
    [@pl.col("v").sum().over([@pl.lit_int(1L)]).first().alias("sum_v")],
  )
  m["kernel/over/lit/v/mean"] = (
    [],
    [@pl.col("v").mean().over([@pl.lit_int(1L)]).first().alias("mean_v")],
  )
  m["kernel/over/lit/v/std"] = (
    [],
    [@pl.col("v").std(ddof=1).over([@pl.lit_int(1L)]).first().alias("std_v")],
  )
  m["kernel/over/lit/v/var"] = (
    [],
    [@pl.col("v").var_(ddof=1).over([@pl.lit_int(1L)]).first().alias("var_v")],
  )
  m["kernel/over/lit/f/sum"] = (
    [],
    [@pl.col("f").sum().over([@pl.lit_int(1L)]).first().alias("sum_f")],
  )
  m["kernel/over/lit/f/mean"] = (
    [],
    [@pl.col("f").mean().over([@pl.lit_int(1L)]).first().alias("mean_f")],
  )
  m["kernel/over/lit/i/mean"] = (
    [],
    [@pl.col("i").mean().over([@pl.lit_int(1L)]).first().alias("mean_i")],
  )
  m["kernel/over/lit/i/std"] = (
    [],
    [@pl.col("i").std(ddof=1).over([@pl.lit_int(1L)]).first().alias("std_i")],
  )
  m["kernel/over/lit/i/var"] = (
    [],
    [@pl.col("i").var_(ddof=1).over([@pl.lit_int(1L)]).first().alias("var_i")],
  )
  m["kernel/over/lit/nested"] = (
    [],
    [
      (@pl.col("v") - @pl.col("v").mean())
      .sum()
      .over([@pl.lit_int(1L)])
      .first()
      .alias("dev_sum"),
      (@pl.col("v") - @pl.col("v").mean())
      .over([@pl.lit_int(1L)])
      .last()
      .alias("dev_last"),
    ],
  )
}

///|
fn golden_group_final_cases_1(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["kernel/over/lit-i32/v/sum"] = (
    [],
    [
      @pl.col("v")
      .sum()
      .over([@pl.lit_int(1L).cast(@pl.DataType::Int32)])
      .first()
      .alias("sum_v"),
    ],
  )
  m["kernel/over/lit-i32/v/mean"] = (
    [],
    [
      @pl.col("v")
      .mean()
      .over([@pl.lit_int(1L).cast(@pl.DataType::Int32)])
      .first()
      .alias("mean_v"),
    ],
  )
  m["kernel/over/lit-i32/v/std"] = (
    [],
    [
      @pl.col("v")
      .std(ddof=1)
      .over([@pl.lit_int(1L).cast(@pl.DataType::Int32)])
      .first()
      .alias("std_v"),
    ],
  )
  m["kernel/over/lit-i32/v/var"] = (
    [],
    [
      @pl.col("v")
      .var_(ddof=1)
      .over([@pl.lit_int(1L).cast(@pl.DataType::Int32)])
      .first()
      .alias("var_v"),
    ],
  )
  m["kernel/over/lit-i32/f/sum"] = (
    [],
    [
      @pl.col("f")
      .sum()
      .over([@pl.lit_int(1L).cast(@pl.DataType::Int32)])
      .first()
      .alias("sum_f"),
    ],
  )
  m["kernel/over/lit-i32/f/mean"] = (
    [],
    [
      @pl.col("f")
      .mean()
      .over([@pl.lit_int(1L).cast(@pl.DataType::Int32)])
      .first()
      .alias("mean_f"),
    ],
  )
  m["kernel/over/lit-i32/i/mean"] = (
    [],
    [
      @pl.col("i")
      .mean()
      .over([@pl.lit_int(1L).cast(@pl.DataType::Int32)])
      .first()
      .alias("mean_i"),
    ],
  )
  m["kernel/over/lit-i32/i/std"] = (
    [],
    [
      @pl.col("i")
      .std(ddof=1)
      .over([@pl.lit_int(1L).cast(@pl.DataType::Int32)])
      .first()
      .alias("std_i"),
    ],
  )
  m["kernel/over/lit-i32/i/var"] = (
    [],
    [
      @pl.col("i")
      .var_(ddof=1)
      .over([@pl.lit_int(1L).cast(@pl.DataType::Int32)])
      .first()
      .alias("var_i"),
    ],
  )
  m["kernel/over/lit-i32/nested"] = (
    [],
    [
      (@pl.col("v") - @pl.col("v").mean())
      .sum()
      .over([@pl.lit_int(1L).cast(@pl.DataType::Int32)])
      .first()
      .alias("dev_sum"),
      (@pl.col("v") - @pl.col("v").mean())
      .over([@pl.lit_int(1L).cast(@pl.DataType::Int32)])
      .last()
      .alias("dev_last"),
    ],
  )
  m["kernel/over/lit-str/v/sum"] = (
    [],
    [@pl.col("v").sum().over([@pl.lit_str("a")]).first().alias("sum_v")],
  )
  m["kernel/over/lit-str/v/mean"] = (
    [],
    [@pl.col("v").mean().over([@pl.lit_str("a")]).first().alias("mean_v")],
  )
  m["kernel/over/lit-str/v/std"] = (
    [],
    [@pl.col("v").std(ddof=1).over([@pl.lit_str("a")]).first().alias("std_v")],
  )
  m["kernel/over/lit-str/v/var"] = (
    [],
    [@pl.col("v").var_(ddof=1).over([@pl.lit_str("a")]).first().alias("var_v")],
  )
  m["kernel/over/lit-str/f/sum"] = (
    [],
    [@pl.col("f").sum().over([@pl.lit_str("a")]).first().alias("sum_f")],
  )
  m["kernel/over/lit-str/f/mean"] = (
    [],
    [@pl.col("f").mean().over([@pl.lit_str("a")]).first().alias("mean_f")],
  )
  m["kernel/over/lit-str/i/mean"] = (
    [],
    [@pl.col("i").mean().over([@pl.lit_str("a")]).first().alias("mean_i")],
  )
  m["kernel/over/lit-str/i/std"] = (
    [],
    [@pl.col("i").std(ddof=1).over([@pl.lit_str("a")]).first().alias("std_i")],
  )
  m["kernel/over/lit-str/i/var"] = (
    [],
    [@pl.col("i").var_(ddof=1).over([@pl.lit_str("a")]).first().alias("var_i")],
  )
  m["kernel/over/lit-str/nested"] = (
    [],
    [
      (@pl.col("v") - @pl.col("v").mean())
      .sum()
      .over([@pl.lit_str("a")])
      .first()
      .alias("dev_sum"),
      (@pl.col("v") - @pl.col("v").mean())
      .over([@pl.lit_str("a")])
      .last()
      .alias("dev_last"),
    ],
  )
  m["kernel/over/agg/v/sum"] = (
    [],
    [@pl.col("v").sum().over([@pl.col("v").sum()]).first().alias("sum_v")],
  )
  m["kernel/over/agg/v/mean"] = (
    [],
    [@pl.col("v").mean().over([@pl.col("v").sum()]).first().alias("mean_v")],
  )
  m["kernel/over/agg/v/std"] = (
    [],
    [@pl.col("v").std(ddof=1).over([@pl.col("v").sum()]).first().alias("std_v")],
  )
  m["kernel/over/agg/v/var"] = (
    [],
    [
      @pl.col("v")
      .var_(ddof=1)
      .over([@pl.col("v").sum()])
      .first()
      .alias("var_v"),
    ],
  )
  m["kernel/over/agg/f/sum"] = (
    [],
    [@pl.col("f").sum().over([@pl.col("v").sum()]).first().alias("sum_f")],
  )
  m["kernel/over/agg/f/mean"] = (
    [],
    [@pl.col("f").mean().over([@pl.col("v").sum()]).first().alias("mean_f")],
  )
  m["kernel/over/agg/i/mean"] = (
    [],
    [@pl.col("i").mean().over([@pl.col("v").sum()]).first().alias("mean_i")],
  )
  m["kernel/over/agg/i/std"] = (
    [],
    [@pl.col("i").std(ddof=1).over([@pl.col("v").sum()]).first().alias("std_i")],
  )
  m["kernel/over/agg/i/var"] = (
    [],
    [
      @pl.col("i")
      .var_(ddof=1)
      .over([@pl.col("v").sum()])
      .first()
      .alias("var_i"),
    ],
  )
  m["kernel/over/agg/nested"] = (
    [],
    [
      (@pl.col("v") - @pl.col("v").mean())
      .sum()
      .over([@pl.col("v").sum()])
      .first()
      .alias("dev_sum"),
      (@pl.col("v") - @pl.col("v").mean())
      .over([@pl.col("v").sum()])
      .last()
      .alias("dev_last"),
    ],
  )
  m["kernel/over/len/v/sum"] = (
    [],
    [@pl.col("v").sum().over([@pl.len()]).first().alias("sum_v")],
  )
  m["kernel/over/len/v/mean"] = (
    [],
    [@pl.col("v").mean().over([@pl.len()]).first().alias("mean_v")],
  )
  m["kernel/over/len/v/std"] = (
    [],
    [@pl.col("v").std(ddof=1).over([@pl.len()]).first().alias("std_v")],
  )
  m["kernel/over/len/v/var"] = (
    [],
    [@pl.col("v").var_(ddof=1).over([@pl.len()]).first().alias("var_v")],
  )
  m["kernel/over/len/f/sum"] = (
    [],
    [@pl.col("f").sum().over([@pl.len()]).first().alias("sum_f")],
  )
  m["kernel/over/len/f/mean"] = (
    [],
    [@pl.col("f").mean().over([@pl.len()]).first().alias("mean_f")],
  )
  m["kernel/over/len/i/mean"] = (
    [],
    [@pl.col("i").mean().over([@pl.len()]).first().alias("mean_i")],
  )
  m["kernel/over/len/i/std"] = (
    [],
    [@pl.col("i").std(ddof=1).over([@pl.len()]).first().alias("std_i")],
  )
  m["kernel/over/len/i/var"] = (
    [],
    [@pl.col("i").var_(ddof=1).over([@pl.len()]).first().alias("var_i")],
  )
  m["kernel/over/len/nested"] = (
    [],
    [
      (@pl.col("v") - @pl.col("v").mean())
      .sum()
      .over([@pl.len()])
      .first()
      .alias("dev_sum"),
      (@pl.col("v") - @pl.col("v").mean())
      .over([@pl.len()])
      .last()
      .alias("dev_last"),
    ],
  )
}

///|
fn golden_group_final_cases_2(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["kernel/select/v/sum"] = ([], [@pl.col("v").sum().alias("sum_v")])
  m["kernel/select/v/mean"] = ([], [@pl.col("v").mean().alias("mean_v")])
  m["kernel/select/v/std"] = ([], [@pl.col("v").std(ddof=1).alias("std_v")])
  m["kernel/select/v/var"] = ([], [@pl.col("v").var_(ddof=1).alias("var_v")])
  m["kernel/select/f/sum"] = ([], [@pl.col("f").sum().alias("sum_f")])
  m["kernel/select/f/mean"] = ([], [@pl.col("f").mean().alias("mean_f")])
  m["kernel/select/i/mean"] = ([], [@pl.col("i").mean().alias("mean_i")])
  m["kernel/select/i/std"] = ([], [@pl.col("i").std(ddof=1).alias("std_i")])
  m["kernel/select/i/var"] = ([], [@pl.col("i").var_(ddof=1).alias("var_i")])
  m["kernel/select/nested-var"] = (
    [],
    [(@pl.col("v") - @pl.col("v").mean()).var_(ddof=1).alias("var_dev")],
  )
  m["kernel/over/lit/full-mean"] = (
    [],
    [@pl.col("v").mean().over([@pl.lit_int(1L)]).alias("t")],
  )
  m["kernel/over/agg/full-sum"] = (
    [],
    [@pl.col("v").sum().over([@pl.col("v").sum()]).alias("t")],
  )
  m["kernel/over/lit/full-std"] = (
    [],
    [@pl.col("v").std(ddof=1).over([@pl.lit_int(1L)]).alias("t")],
  )
  m["parse/agg/first/dd/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).first()],
  )
  m["parse/agg/last/dd/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).last()],
  )
  m["parse/agg/count/dd/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).count()],
  )
  m["parse/agg/n_unique/dd/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).n_unique()],
  )
  m["parse/agg/max/dd/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).max()],
  )
  m["parse/agg/min/dd/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).min()],
  )
  m["parse/agg/len/dd/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).len()],
  )
  m["parse/agg/two/dd/date/strict"] = (
    [@pl.col("k")],
    [
      @pl.col("sd").str().to_date(strict=true).first().alias("a"),
      @pl.col("sd").str().to_date(strict=true).count().alias("b"),
      @pl.col("v").sum().alias("s"),
    ],
  )
  m["parse/agg/is-null-sum/dd/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).is_null().sum()],
  )
  m["parse/agg/no-key/dd/date/strict"] = (
    [],
    [
      @pl.col("sd").str().to_date(strict=true).first(),
      @pl.col("sd").str().to_date(strict=true).count().alias("n"),
    ],
  )
  m["parse/key/dd/date/strict"] = (
    [@pl.col("sd").str().to_date(strict=true)],
    [@pl.col("v").sum()],
  )
  m["parse/agg/first/dd/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).first()],
  )
  m["parse/agg/last/dd/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).last()],
  )
  m["parse/agg/count/dd/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).count()],
  )
  m["parse/agg/n_unique/dd/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).n_unique()],
  )
  m["parse/agg/max/dd/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).max()],
  )
  m["parse/agg/min/dd/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).min()],
  )
  m["parse/agg/len/dd/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).len()],
  )
  m["parse/agg/two/dd/date/lenient"] = (
    [@pl.col("k")],
    [
      @pl.col("sd").str().to_date(strict=false).first().alias("a"),
      @pl.col("sd").str().to_date(strict=false).count().alias("b"),
      @pl.col("v").sum().alias("s"),
    ],
  )
  m["parse/agg/is-null-sum/dd/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).is_null().sum()],
  )
  m["parse/agg/no-key/dd/date/lenient"] = (
    [],
    [
      @pl.col("sd").str().to_date(strict=false).first(),
      @pl.col("sd").str().to_date(strict=false).count().alias("n"),
    ],
  )
  m["parse/key/dd/date/lenient"] = (
    [@pl.col("sd").str().to_date(strict=false)],
    [@pl.col("v").sum()],
  )
  m["parse/agg/first/dd/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).first()],
  )
  m["parse/agg/last/dd/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).last()],
  )
  m["parse/agg/count/dd/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).count()],
  )
  m["parse/agg/n_unique/dd/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).n_unique()],
  )
  m["parse/agg/max/dd/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).max()],
  )
}

///|
fn golden_group_final_cases_3(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["parse/agg/min/dd/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).min()],
  )
  m["parse/agg/len/dd/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).len()],
  )
  m["parse/agg/two/dd/datetime/strict"] = (
    [@pl.col("k")],
    [
      @pl.col("st").str().to_datetime(strict=true).first().alias("a"),
      @pl.col("st").str().to_datetime(strict=true).count().alias("b"),
      @pl.col("v").sum().alias("s"),
    ],
  )
  m["parse/agg/is-null-sum/dd/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).is_null().sum()],
  )
  m["parse/agg/no-key/dd/datetime/strict"] = (
    [],
    [
      @pl.col("st").str().to_datetime(strict=true).first(),
      @pl.col("st").str().to_datetime(strict=true).count().alias("n"),
    ],
  )
  m["parse/key/dd/datetime/strict"] = (
    [@pl.col("st").str().to_datetime(strict=true)],
    [@pl.col("v").sum()],
  )
  m["parse/agg/first/dd/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).first()],
  )
  m["parse/agg/last/dd/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).last()],
  )
  m["parse/agg/count/dd/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).count()],
  )
  m["parse/agg/n_unique/dd/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).n_unique()],
  )
  m["parse/agg/max/dd/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).max()],
  )
  m["parse/agg/min/dd/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).min()],
  )
  m["parse/agg/len/dd/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).len()],
  )
  m["parse/agg/two/dd/datetime/lenient"] = (
    [@pl.col("k")],
    [
      @pl.col("st").str().to_datetime(strict=false).first().alias("a"),
      @pl.col("st").str().to_datetime(strict=false).count().alias("b"),
      @pl.col("v").sum().alias("s"),
    ],
  )
  m["parse/agg/is-null-sum/dd/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).is_null().sum()],
  )
  m["parse/agg/no-key/dd/datetime/lenient"] = (
    [],
    [
      @pl.col("st").str().to_datetime(strict=false).first(),
      @pl.col("st").str().to_datetime(strict=false).count().alias("n"),
    ],
  )
  m["parse/key/dd/datetime/lenient"] = (
    [@pl.col("st").str().to_datetime(strict=false)],
    [@pl.col("v").sum()],
  )
  m["parse/agg/year/dd"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).dt().year().max()],
  )
  m["parse/agg/cast/dd"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).cast(@pl.DataType::Int32).max()],
  )
  m["parse/agg/first/ddx/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).first()],
  )
  m["parse/agg/last/ddx/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).last()],
  )
  m["parse/agg/count/ddx/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).count()],
  )
  m["parse/agg/n_unique/ddx/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).n_unique()],
  )
  m["parse/agg/max/ddx/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).max()],
  )
  m["parse/agg/min/ddx/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).min()],
  )
  m["parse/agg/len/ddx/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).len()],
  )
  m["parse/agg/two/ddx/date/strict"] = (
    [@pl.col("k")],
    [
      @pl.col("sd").str().to_date(strict=true).first().alias("a"),
      @pl.col("sd").str().to_date(strict=true).count().alias("b"),
      @pl.col("v").sum().alias("s"),
    ],
  )
  m["parse/agg/is-null-sum/ddx/date/strict"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=true).is_null().sum()],
  )
  m["parse/agg/no-key/ddx/date/strict"] = (
    [],
    [
      @pl.col("sd").str().to_date(strict=true).first(),
      @pl.col("sd").str().to_date(strict=true).count().alias("n"),
    ],
  )
  m["parse/key/ddx/date/strict"] = (
    [@pl.col("sd").str().to_date(strict=true)],
    [@pl.col("v").sum()],
  )
  m["parse/agg/first/ddx/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).first()],
  )
  m["parse/agg/last/ddx/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).last()],
  )
  m["parse/agg/count/ddx/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).count()],
  )
  m["parse/agg/n_unique/ddx/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).n_unique()],
  )
  m["parse/agg/max/ddx/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).max()],
  )
  m["parse/agg/min/ddx/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).min()],
  )
  m["parse/agg/len/ddx/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).len()],
  )
  m["parse/agg/two/ddx/date/lenient"] = (
    [@pl.col("k")],
    [
      @pl.col("sd").str().to_date(strict=false).first().alias("a"),
      @pl.col("sd").str().to_date(strict=false).count().alias("b"),
      @pl.col("v").sum().alias("s"),
    ],
  )
  m["parse/agg/is-null-sum/ddx/date/lenient"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).is_null().sum()],
  )
  m["parse/agg/no-key/ddx/date/lenient"] = (
    [],
    [
      @pl.col("sd").str().to_date(strict=false).first(),
      @pl.col("sd").str().to_date(strict=false).count().alias("n"),
    ],
  )
}

///|
fn golden_group_final_cases_4(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["parse/key/ddx/date/lenient"] = (
    [@pl.col("sd").str().to_date(strict=false)],
    [@pl.col("v").sum()],
  )
  m["parse/agg/first/ddx/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).first()],
  )
  m["parse/agg/last/ddx/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).last()],
  )
  m["parse/agg/count/ddx/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).count()],
  )
  m["parse/agg/n_unique/ddx/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).n_unique()],
  )
  m["parse/agg/max/ddx/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).max()],
  )
  m["parse/agg/min/ddx/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).min()],
  )
  m["parse/agg/len/ddx/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).len()],
  )
  m["parse/agg/two/ddx/datetime/strict"] = (
    [@pl.col("k")],
    [
      @pl.col("st").str().to_datetime(strict=true).first().alias("a"),
      @pl.col("st").str().to_datetime(strict=true).count().alias("b"),
      @pl.col("v").sum().alias("s"),
    ],
  )
  m["parse/agg/is-null-sum/ddx/datetime/strict"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=true).is_null().sum()],
  )
  m["parse/agg/no-key/ddx/datetime/strict"] = (
    [],
    [
      @pl.col("st").str().to_datetime(strict=true).first(),
      @pl.col("st").str().to_datetime(strict=true).count().alias("n"),
    ],
  )
  m["parse/key/ddx/datetime/strict"] = (
    [@pl.col("st").str().to_datetime(strict=true)],
    [@pl.col("v").sum()],
  )
  m["parse/agg/first/ddx/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).first()],
  )
  m["parse/agg/last/ddx/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).last()],
  )
  m["parse/agg/count/ddx/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).count()],
  )
  m["parse/agg/n_unique/ddx/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).n_unique()],
  )
  m["parse/agg/max/ddx/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).max()],
  )
  m["parse/agg/min/ddx/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).min()],
  )
  m["parse/agg/len/ddx/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).len()],
  )
  m["parse/agg/two/ddx/datetime/lenient"] = (
    [@pl.col("k")],
    [
      @pl.col("st").str().to_datetime(strict=false).first().alias("a"),
      @pl.col("st").str().to_datetime(strict=false).count().alias("b"),
      @pl.col("v").sum().alias("s"),
    ],
  )
  m["parse/agg/is-null-sum/ddx/datetime/lenient"] = (
    [@pl.col("k")],
    [@pl.col("st").str().to_datetime(strict=false).is_null().sum()],
  )
  m["parse/agg/no-key/ddx/datetime/lenient"] = (
    [],
    [
      @pl.col("st").str().to_datetime(strict=false).first(),
      @pl.col("st").str().to_datetime(strict=false).count().alias("n"),
    ],
  )
  m["parse/key/ddx/datetime/lenient"] = (
    [@pl.col("st").str().to_datetime(strict=false)],
    [@pl.col("v").sum()],
  )
  m["parse/agg/year/ddx"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).dt().year().max()],
  )
  m["parse/agg/cast/ddx"] = (
    [@pl.col("k")],
    [@pl.col("sd").str().to_date(strict=false).cast(@pl.DataType::Int32).max()],
  )
  m["kernel/none/v/sum"] = ([], [@pl.col("v").sum().alias("sum_v")])
  m["kernel/none/v/mean"] = ([], [@pl.col("v").mean().alias("mean_v")])
  m["kernel/none/v/std"] = ([], [@pl.col("v").std(ddof=1).alias("std_v")])
  m["kernel/none/v/var"] = ([], [@pl.col("v").var_(ddof=1).alias("var_v")])
  m["kernel/none/f/sum"] = ([], [@pl.col("f").sum().alias("sum_f")])
  m["kernel/none/f/mean"] = ([], [@pl.col("f").mean().alias("mean_f")])
  m["kernel/none/i/mean"] = ([], [@pl.col("i").mean().alias("mean_i")])
  m["kernel/none/i/std"] = ([], [@pl.col("i").std(ddof=1).alias("std_i")])
  m["kernel/none/i/var"] = ([], [@pl.col("i").var_(ddof=1).alias("var_i")])
  m["kernel/none/sums"] = (
    [],
    [
      @pl.col("v").sum().alias("sum_v"),
      @pl.col("v").mean().alias("mean_v"),
      @pl.col("f").sum().alias("sum_f"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/none/vars"] = (
    [],
    [
      @pl.col("v").std(ddof=1).alias("std_v"),
      @pl.col("v").var_(ddof=0).alias("var_v0"),
      @pl.col("i").var_(ddof=1).alias("var_i"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/none/nested"] = (
    [],
    [
      (@pl.col("v") - @pl.col("v").mean()).sum().alias("dev_sum"),
      (@pl.col("v") * @pl.col("v")).mean().alias("sq_mean"),
      (@pl.col("v") * @pl.lit_int(2L)).sum().alias("dbl"),
    ],
  )
  m["kernel/none/nested-var"] = (
    [],
    [(@pl.col("v") - @pl.col("v").mean()).var_(ddof=1).alias("var_dev")],
  )
  m["kernel/none/mixed"] = (
    [],
    [
      (@pl.col("v").sum() / @pl.len()).alias("ratio"),
      (@pl.col("f").mean() + @pl.col("v").sum()).alias("m_plus_s"),
    ],
  )
  m["kernel/lit/v/sum"] = (
    [@pl.lit_int(1L)],
    [@pl.col("v").sum().alias("sum_v")],
  )
}

///|
fn golden_group_final_cases_5(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["kernel/lit/v/mean"] = (
    [@pl.lit_int(1L)],
    [@pl.col("v").mean().alias("mean_v")],
  )
  m["kernel/lit/v/std"] = (
    [@pl.lit_int(1L)],
    [@pl.col("v").std(ddof=1).alias("std_v")],
  )
  m["kernel/lit/v/var"] = (
    [@pl.lit_int(1L)],
    [@pl.col("v").var_(ddof=1).alias("var_v")],
  )
  m["kernel/lit/f/sum"] = (
    [@pl.lit_int(1L)],
    [@pl.col("f").sum().alias("sum_f")],
  )
  m["kernel/lit/f/mean"] = (
    [@pl.lit_int(1L)],
    [@pl.col("f").mean().alias("mean_f")],
  )
  m["kernel/lit/i/mean"] = (
    [@pl.lit_int(1L)],
    [@pl.col("i").mean().alias("mean_i")],
  )
  m["kernel/lit/i/std"] = (
    [@pl.lit_int(1L)],
    [@pl.col("i").std(ddof=1).alias("std_i")],
  )
  m["kernel/lit/i/var"] = (
    [@pl.lit_int(1L)],
    [@pl.col("i").var_(ddof=1).alias("var_i")],
  )
  m["kernel/lit/sums"] = (
    [@pl.lit_int(1L)],
    [
      @pl.col("v").sum().alias("sum_v"),
      @pl.col("v").mean().alias("mean_v"),
      @pl.col("f").sum().alias("sum_f"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/lit/vars"] = (
    [@pl.lit_int(1L)],
    [
      @pl.col("v").std(ddof=1).alias("std_v"),
      @pl.col("v").var_(ddof=0).alias("var_v0"),
      @pl.col("i").var_(ddof=1).alias("var_i"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/lit/nested"] = (
    [@pl.lit_int(1L)],
    [
      (@pl.col("v") - @pl.col("v").mean()).sum().alias("dev_sum"),
      (@pl.col("v") * @pl.col("v")).mean().alias("sq_mean"),
      (@pl.col("v") * @pl.lit_int(2L)).sum().alias("dbl"),
    ],
  )
  m["kernel/lit/nested-var"] = (
    [@pl.lit_int(1L)],
    [(@pl.col("v") - @pl.col("v").mean()).var_(ddof=1).alias("var_dev")],
  )
  m["kernel/lit/mixed"] = (
    [@pl.lit_int(1L)],
    [
      (@pl.col("v").sum() / @pl.len()).alias("ratio"),
      (@pl.col("f").mean() + @pl.col("v").sum()).alias("m_plus_s"),
    ],
  )
  m["kernel/lit-i32/v/sum"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [@pl.col("v").sum().alias("sum_v")],
  )
  m["kernel/lit-i32/v/mean"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [@pl.col("v").mean().alias("mean_v")],
  )
  m["kernel/lit-i32/v/std"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [@pl.col("v").std(ddof=1).alias("std_v")],
  )
  m["kernel/lit-i32/v/var"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [@pl.col("v").var_(ddof=1).alias("var_v")],
  )
  m["kernel/lit-i32/f/sum"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [@pl.col("f").sum().alias("sum_f")],
  )
  m["kernel/lit-i32/f/mean"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [@pl.col("f").mean().alias("mean_f")],
  )
  m["kernel/lit-i32/i/mean"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [@pl.col("i").mean().alias("mean_i")],
  )
  m["kernel/lit-i32/i/std"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [@pl.col("i").std(ddof=1).alias("std_i")],
  )
  m["kernel/lit-i32/i/var"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [@pl.col("i").var_(ddof=1).alias("var_i")],
  )
  m["kernel/lit-i32/sums"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [
      @pl.col("v").sum().alias("sum_v"),
      @pl.col("v").mean().alias("mean_v"),
      @pl.col("f").sum().alias("sum_f"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/lit-i32/vars"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [
      @pl.col("v").std(ddof=1).alias("std_v"),
      @pl.col("v").var_(ddof=0).alias("var_v0"),
      @pl.col("i").var_(ddof=1).alias("var_i"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/lit-i32/nested"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [
      (@pl.col("v") - @pl.col("v").mean()).sum().alias("dev_sum"),
      (@pl.col("v") * @pl.col("v")).mean().alias("sq_mean"),
      (@pl.col("v") * @pl.lit_int(2L)).sum().alias("dbl"),
    ],
  )
  m["kernel/lit-i32/nested-var"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [(@pl.col("v") - @pl.col("v").mean()).var_(ddof=1).alias("var_dev")],
  )
  m["kernel/lit-i32/mixed"] = (
    [@pl.lit_int(1L).cast(@pl.DataType::Int32)],
    [
      (@pl.col("v").sum() / @pl.len()).alias("ratio"),
      (@pl.col("f").mean() + @pl.col("v").sum()).alias("m_plus_s"),
    ],
  )
  m["kernel/lit-str/v/sum"] = (
    [@pl.lit_str("a")],
    [@pl.col("v").sum().alias("sum_v")],
  )
  m["kernel/lit-str/v/mean"] = (
    [@pl.lit_str("a")],
    [@pl.col("v").mean().alias("mean_v")],
  )
  m["kernel/lit-str/v/std"] = (
    [@pl.lit_str("a")],
    [@pl.col("v").std(ddof=1).alias("std_v")],
  )
  m["kernel/lit-str/v/var"] = (
    [@pl.lit_str("a")],
    [@pl.col("v").var_(ddof=1).alias("var_v")],
  )
  m["kernel/lit-str/f/sum"] = (
    [@pl.lit_str("a")],
    [@pl.col("f").sum().alias("sum_f")],
  )
  m["kernel/lit-str/f/mean"] = (
    [@pl.lit_str("a")],
    [@pl.col("f").mean().alias("mean_f")],
  )
  m["kernel/lit-str/i/mean"] = (
    [@pl.lit_str("a")],
    [@pl.col("i").mean().alias("mean_i")],
  )
  m["kernel/lit-str/i/std"] = (
    [@pl.lit_str("a")],
    [@pl.col("i").std(ddof=1).alias("std_i")],
  )
  m["kernel/lit-str/i/var"] = (
    [@pl.lit_str("a")],
    [@pl.col("i").var_(ddof=1).alias("var_i")],
  )
  m["kernel/lit-str/sums"] = (
    [@pl.lit_str("a")],
    [
      @pl.col("v").sum().alias("sum_v"),
      @pl.col("v").mean().alias("mean_v"),
      @pl.col("f").sum().alias("sum_f"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/lit-str/vars"] = (
    [@pl.lit_str("a")],
    [
      @pl.col("v").std(ddof=1).alias("std_v"),
      @pl.col("v").var_(ddof=0).alias("var_v0"),
      @pl.col("i").var_(ddof=1).alias("var_i"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/lit-str/nested"] = (
    [@pl.lit_str("a")],
    [
      (@pl.col("v") - @pl.col("v").mean()).sum().alias("dev_sum"),
      (@pl.col("v") * @pl.col("v")).mean().alias("sq_mean"),
      (@pl.col("v") * @pl.lit_int(2L)).sum().alias("dbl"),
    ],
  )
  m["kernel/lit-str/nested-var"] = (
    [@pl.lit_str("a")],
    [(@pl.col("v") - @pl.col("v").mean()).var_(ddof=1).alias("var_dev")],
  )
}

///|
fn golden_group_final_cases_6(
  m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])],
) -> Unit {
  m["kernel/lit-str/mixed"] = (
    [@pl.lit_str("a")],
    [
      (@pl.col("v").sum() / @pl.len()).alias("ratio"),
      (@pl.col("f").mean() + @pl.col("v").sum()).alias("m_plus_s"),
    ],
  )
  m["kernel/agg/v/sum"] = (
    [@pl.col("v").sum()],
    [@pl.col("v").sum().alias("sum_v")],
  )
  m["kernel/agg/v/mean"] = (
    [@pl.col("v").sum()],
    [@pl.col("v").mean().alias("mean_v")],
  )
  m["kernel/agg/v/std"] = (
    [@pl.col("v").sum()],
    [@pl.col("v").std(ddof=1).alias("std_v")],
  )
  m["kernel/agg/v/var"] = (
    [@pl.col("v").sum()],
    [@pl.col("v").var_(ddof=1).alias("var_v")],
  )
  m["kernel/agg/f/sum"] = (
    [@pl.col("v").sum()],
    [@pl.col("f").sum().alias("sum_f")],
  )
  m["kernel/agg/f/mean"] = (
    [@pl.col("v").sum()],
    [@pl.col("f").mean().alias("mean_f")],
  )
  m["kernel/agg/i/mean"] = (
    [@pl.col("v").sum()],
    [@pl.col("i").mean().alias("mean_i")],
  )
  m["kernel/agg/i/std"] = (
    [@pl.col("v").sum()],
    [@pl.col("i").std(ddof=1).alias("std_i")],
  )
  m["kernel/agg/i/var"] = (
    [@pl.col("v").sum()],
    [@pl.col("i").var_(ddof=1).alias("var_i")],
  )
  m["kernel/agg/sums"] = (
    [@pl.col("v").sum()],
    [
      @pl.col("v").sum().alias("sum_v"),
      @pl.col("v").mean().alias("mean_v"),
      @pl.col("f").sum().alias("sum_f"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/agg/vars"] = (
    [@pl.col("v").sum()],
    [
      @pl.col("v").std(ddof=1).alias("std_v"),
      @pl.col("v").var_(ddof=0).alias("var_v0"),
      @pl.col("i").var_(ddof=1).alias("var_i"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/agg/nested"] = (
    [@pl.col("v").sum()],
    [
      (@pl.col("v") - @pl.col("v").mean()).sum().alias("dev_sum"),
      (@pl.col("v") * @pl.col("v")).mean().alias("sq_mean"),
      (@pl.col("v") * @pl.lit_int(2L)).sum().alias("dbl"),
    ],
  )
  m["kernel/agg/nested-var"] = (
    [@pl.col("v").sum()],
    [(@pl.col("v") - @pl.col("v").mean()).var_(ddof=1).alias("var_dev")],
  )
  m["kernel/agg/mixed"] = (
    [@pl.col("v").sum()],
    [
      (@pl.col("v").sum() / @pl.len()).alias("ratio"),
      (@pl.col("f").mean() + @pl.col("v").sum()).alias("m_plus_s"),
    ],
  )
  m["kernel/len/v/sum"] = ([@pl.len()], [@pl.col("v").sum().alias("sum_v")])
  m["kernel/len/v/mean"] = ([@pl.len()], [@pl.col("v").mean().alias("mean_v")])
  m["kernel/len/v/std"] = (
    [@pl.len()],
    [@pl.col("v").std(ddof=1).alias("std_v")],
  )
  m["kernel/len/v/var"] = (
    [@pl.len()],
    [@pl.col("v").var_(ddof=1).alias("var_v")],
  )
  m["kernel/len/f/sum"] = ([@pl.len()], [@pl.col("f").sum().alias("sum_f")])
  m["kernel/len/f/mean"] = ([@pl.len()], [@pl.col("f").mean().alias("mean_f")])
  m["kernel/len/i/mean"] = ([@pl.len()], [@pl.col("i").mean().alias("mean_i")])
  m["kernel/len/i/std"] = (
    [@pl.len()],
    [@pl.col("i").std(ddof=1).alias("std_i")],
  )
  m["kernel/len/i/var"] = (
    [@pl.len()],
    [@pl.col("i").var_(ddof=1).alias("var_i")],
  )
  m["kernel/len/sums"] = (
    [@pl.len()],
    [
      @pl.col("v").sum().alias("sum_v"),
      @pl.col("v").mean().alias("mean_v"),
      @pl.col("f").sum().alias("sum_f"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/len/vars"] = (
    [@pl.len()],
    [
      @pl.col("v").std(ddof=1).alias("std_v"),
      @pl.col("v").var_(ddof=0).alias("var_v0"),
      @pl.col("i").var_(ddof=1).alias("var_i"),
      @pl.len().alias("n"),
    ],
  )
  m["kernel/len/nested"] = (
    [@pl.len()],
    [
      (@pl.col("v") - @pl.col("v").mean()).sum().alias("dev_sum"),
      (@pl.col("v") * @pl.col("v")).mean().alias("sq_mean"),
      (@pl.col("v") * @pl.lit_int(2L)).sum().alias("dbl"),
    ],
  )
  m["kernel/len/nested-var"] = (
    [@pl.len()],
    [(@pl.col("v") - @pl.col("v").mean()).var_(ddof=1).alias("var_dev")],
  )
  m["kernel/len/mixed"] = (
    [@pl.len()],
    [
      (@pl.col("v").sum() / @pl.len()).alias("ratio"),
      (@pl.col("f").mean() + @pl.col("v").sum()).alias("m_plus_s"),
    ],
  )
}

///|
/// Every case id with its key expressions (none for a `select` or `with_columns`
/// case) and its expressions.
fn golden_group_final_cases() -> Map[String, (Array[@pl.Expr], Array[@pl.Expr])] {
  let m : Map[String, (Array[@pl.Expr], Array[@pl.Expr])] = Map([])
  golden_group_final_cases_0(m)
  golden_group_final_cases_1(m)
  golden_group_final_cases_2(m)
  golden_group_final_cases_3(m)
  golden_group_final_cases_4(m)
  golden_group_final_cases_5(m)
  golden_group_final_cases_6(m)
  m
}
