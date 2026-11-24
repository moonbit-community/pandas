///|
fn seq_df() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::int32_nullable("a", [Some(1), None, Some(3), Some(4)]),
    @pl.Series::float64_nullable("f", [Some(1.5), Some(2.5), None, Some(0.5)]),
    @pl.Series::str_nullable("s", [Some("b"), None, Some("a"), Some("c")]),
    @pl.Series::bool_nullable("p", [Some(true), None, Some(false), Some(true)]),
    @pl.Series::date_nullable("d", [Some(0), None, Some(2), Some(3)]),
    @pl.Series::null("n", 4),
  ])
}

///|
/// The only column of `select([e])` on the sequence frame.
fn seq_out(e : @pl.Expr) -> @pl.Series raise @pl.PolarsError {
  seq_df().select([e]).get_columns()[0]
}

///|
test "Expr::shift: values, fill value, direction, types and names" {
  let a = @pl.col("a")
  let out = seq_out(a.shift(n=1))
  assert_eq(out.name(), "a")
  assert_eq(out.dtype(), @pl.DataType::Int32)
  assert_eq(out.to_int32_array(), [None, Some(1), None, Some(3)])
  assert_eq(seq_out(a.shift(n=-1)).to_int32_array(), [
    None,
    Some(3),
    Some(4),
    None,
  ])
  assert_eq(seq_out(a.shift(n=0)).to_int32_array(), [
    Some(1),
    None,
    Some(3),
    Some(4),
  ])
  assert_eq(seq_out(a.shift(n=9)).to_int32_array(), [None, None, None, None])
  assert_eq(
    seq_out(a.shift(n=1, fill_value=@pl.AnyValue::Int32(7))).to_int32_array(),
    [Some(7), Some(1), None, Some(3)],
  )
  // the fill value is typed: the result is the supertype
  let wide = seq_out(a.shift(n=1, fill_value=@pl.AnyValue::Float64(0.5)))
  assert_eq(wide.dtype(), @pl.DataType::Float64)
  assert_eq(wide.to_float64_array(), [Some(0.5), Some(1.0), None, Some(3.0)])
  assert_eq(
    seq_out(@pl.col("s").shift(n=1, fill_value=@pl.AnyValue::String("z"))).to_str_array(),
    [Some("z"), Some("b"), None, Some("a")],
  )
  // a Null column stays Null
  let n = seq_out(@pl.col("n").shift(n=2))
  assert_eq(n.dtype(), @pl.DataType::Null)
  assert_eq(n.len(), 4)
  // Boolean and Date
  assert_eq(seq_out(@pl.col("p").shift(n=1)).to_bool_array(), [
    None,
    Some(true),
    None,
    Some(false),
  ])
  assert_eq(seq_out(@pl.col("d").shift(n=1)).dtype(), @pl.DataType::Date)
  // a fill value that does not fit raises when evaluated
  assert_true(
    raises(() => {
      seq_out(@pl.col("p").shift(n=1, fill_value=@pl.AnyValue::Date(1)))
    })
    is Some(@pl.ComputeError(_)),
  )
  assert_true(
    raises(() => {
      seq_out(@pl.col("a").shift(n=1, fill_value=@pl.AnyValue::Boolean(true)))
    })
    is None,
  )
  assert_true(
    raises(() => seq_out(@pl.col("zz").shift(n=1)))
    is Some(@pl.ColumnNotFound(_)),
  )
}

///|
test "Expr::diff: values, nulls, errors" {
  let a = @pl.col("a")
  assert_eq(seq_out(a.diff()).to_int32_array(), [None, None, None, Some(1)])
  assert_eq(seq_out(a.diff(n=2)).to_int32_array(), [None, None, Some(2), None])
  assert_eq(seq_out(a.diff(n=-1)).to_int32_array(), [None, None, Some(-1), None])
  assert_eq(seq_out(@pl.col("f").diff()).to_float64_array(), [
    None,
    Some(1.0),
    None,
    None,
  ])
  assert_eq(seq_out(a.diff()).name(), "a")
  // no Duration type: a date difference and the other types are refused
  assert_true(
    raises(() => seq_out(@pl.col("d").diff())) is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => seq_out(@pl.col("s").diff())) is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => seq_out(@pl.col("p").diff())) is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "Expr::cum_*: values, reverse, types, errors" {
  let a = @pl.col("a")
  assert_eq(seq_out(a.cum_sum()).to_int32_array(), [
    Some(1),
    None,
    Some(4),
    Some(8),
  ])
  assert_eq(seq_out(a.cum_sum(reverse=true)).to_int32_array(), [
    Some(8),
    None,
    Some(7),
    Some(4),
  ])
  assert_eq(seq_out(a.cum_min()).to_int32_array(), [
    Some(1),
    None,
    Some(1),
    Some(1),
  ])
  assert_eq(seq_out(a.cum_max()).to_int32_array(), [
    Some(1),
    None,
    Some(3),
    Some(4),
  ])
  assert_eq(seq_out(a.cum_prod()).to_int64_array(), [
    Some(1L),
    None,
    Some(3L),
    Some(12L),
  ])
  // cum_count counts the valid values so far
  let c = seq_out(a.cum_count())
  assert_eq(c.dtype(), @pl.DataType::Int64)
  assert_eq(c.to_int64_array(), [Some(1L), Some(1L), Some(2L), Some(3L)])
  assert_eq(seq_out(a.cum_count(reverse=true)).to_int64_array(), [
    Some(3L),
    Some(2L),
    Some(2L),
    Some(1L),
  ])
  assert_eq(seq_out(@pl.col("s").cum_min()).to_str_array(), [
    Some("b"),
    None,
    Some("a"),
    Some("a"),
  ])
  assert_eq(seq_out(@pl.col("p").cum_sum()).to_int64_array(), [
    Some(1L),
    None,
    Some(1L),
    Some(2L),
  ])
  assert_eq(seq_out(a.cum_sum()).name(), "a")
  // errors
  assert_true(
    raises(() => seq_out(@pl.col("s").cum_sum()))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => seq_out(@pl.col("d").cum_sum()))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => seq_out(@pl.col("n").cum_sum()))
    is Some(@pl.InvalidOperation(_)),
  )
  // cum_count of a Null column counts nothing; cum_min of a Null column is refused
  assert_eq(seq_out(@pl.col("n").cum_count()).to_int64_array(), [
    Some(0L),
    Some(0L),
    Some(0L),
    Some(0L),
  ])
}

///|
test "Expr::rank and Expr::reverse" {
  let a = @pl.col("a")
  let r = seq_out(a.rank())
  assert_eq(r.dtype(), @pl.DataType::Float64)
  assert_eq(r.to_float64_array(), [Some(1.0), None, Some(2.0), Some(3.0)])
  let d = seq_out(a.rank(method_=@pl.RankMethod::Dense, descending=true))
  assert_eq(d.dtype(), @pl.DataType::Int64)
  assert_eq(d.to_int64_array(), [Some(3L), None, Some(2L), Some(1L)])
  let s = seq_out(@pl.col("s").rank(method_=@pl.RankMethod::Ordinal))
  assert_eq(s.to_int64_array(), [Some(2L), None, Some(1L), Some(3L)])
  assert_eq(seq_out(@pl.col("n").rank()).dtype(), @pl.DataType::Float64)
  assert_eq(seq_out(a.reverse()).to_int32_array(), [
    Some(4),
    Some(3),
    None,
    Some(1),
  ])
  assert_eq(seq_out(a.reverse()).name(), "a")
  assert_eq(seq_out(@pl.col("n").reverse()).dtype(), @pl.DataType::Null)
  assert_eq(seq_out(@pl.col("s").reverse()).to_str_array(), [
    Some("c"),
    Some("a"),
    None,
    Some("b"),
  ])
}

///|
test "Expr::fill_null_strategy: strategies, limit, errors" {
  let a = @pl.col("a")
  let fwd = @pl.FillStrategy::Forward
  assert_eq(seq_out(a.fill_null_strategy(fwd)).to_int32_array(), [
    Some(1),
    Some(1),
    Some(3),
    Some(4),
  ])
  assert_eq(
    seq_out(a.fill_null_strategy(@pl.FillStrategy::Backward)).to_int32_array(),
    [Some(1), Some(3), Some(3), Some(4)],
  )
  assert_eq(
    seq_out(a.fill_null_strategy(@pl.FillStrategy::Min)).to_int32_array(),
    [Some(1), Some(1), Some(3), Some(4)],
  )
  assert_eq(
    seq_out(a.fill_null_strategy(@pl.FillStrategy::Max)).to_int32_array(),
    [Some(1), Some(4), Some(3), Some(4)],
  )
  // the mean of an integer column is truncated and the type kept
  assert_eq(
    seq_out(a.fill_null_strategy(@pl.FillStrategy::Mean)).to_int32_array(),
    [Some(1), Some(2), Some(3), Some(4)],
  )
  assert_eq(
    seq_out(a.fill_null_strategy(@pl.FillStrategy::Zero)).to_int32_array(),
    [Some(1), Some(0), Some(3), Some(4)],
  )
  assert_eq(
    seq_out(a.fill_null_strategy(@pl.FillStrategy::One)).to_int32_array(),
    [Some(1), Some(1), Some(3), Some(4)],
  )
  // limit
  let g = @pl.DataFrame::new([
    @pl.Series::int32_nullable("g", [Some(1), None, None, None, Some(5)]),
  ])
  let lim1 = g
    .select([@pl.col("g").fill_null_strategy(fwd, limit=1)])
    .column("g")
  assert_eq(lim1.to_int32_array(), [Some(1), Some(1), None, None, Some(5)])
  let lim0 = g
    .select([@pl.col("g").fill_null_strategy(fwd, limit=0)])
    .column("g")
  assert_eq(lim0.null_count(), 3)
  // errors
  assert_true(
    raises(() => seq_out(a.fill_null_strategy(@pl.FillStrategy::Min, limit=1)))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => seq_out(a.fill_null_strategy(fwd, limit=-1)))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => {
      seq_out(@pl.col("s").fill_null_strategy(@pl.FillStrategy::Mean))
    })
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => {
      seq_out(@pl.col("p").fill_null_strategy(@pl.FillStrategy::Mean))
    })
    is Some(@pl.InvalidOperation(_)),
  )
  // the limit is checked even when the selector gives no column at all
  assert_true(
    raises(() => {
      seq_df().select([
        @pl.cols([]).fill_null_strategy(@pl.FillStrategy::Min, limit=1),
      ])
    })
    is Some(@pl.InvalidOperation(_)),
  )
  // a Null column: forward fill leaves it, zero is refused
  assert_eq(
    seq_out(@pl.col("n").fill_null_strategy(fwd)).dtype(),
    @pl.DataType::Null,
  )
  assert_true(
    raises(() => {
      seq_out(@pl.col("n").fill_null_strategy(@pl.FillStrategy::Zero))
    })
    is Some(@pl.InvalidOperation(_)),
  )
}

///|
test "sequence expressions: show text" {
  let a = @pl.col("a")
  assert_eq(a.shift(n=1).to_string(), "col(\"a\").shift([dyn int: 1])")
  assert_eq(a.shift(n=-2).to_string(), "col(\"a\").shift([dyn int: -2])")
  assert_eq(
    a.shift(n=1, fill_value=@pl.AnyValue::Int32(5)).to_string(),
    "col(\"a\").shift_and_fill([dyn int: 1, 5])",
  )
  assert_eq(a.diff(n=2).to_string(), "col(\"a\").diff([dyn int: 2])")
  assert_eq(a.cum_sum().to_string(), "col(\"a\").cum_sum()")
  assert_eq(a.cum_sum(reverse=true).to_string(), "col(\"a\").cum_sum()")
  assert_eq(a.cum_min().to_string(), "col(\"a\").cum_min()")
  assert_eq(a.cum_max().to_string(), "col(\"a\").cum_max()")
  assert_eq(a.cum_prod().to_string(), "col(\"a\").cum_prod()")
  assert_eq(a.cum_count().to_string(), "col(\"a\").cum_count()")
  assert_eq(a.rank().to_string(), "col(\"a\").rank()")
  assert_eq(a.reverse().to_string(), "col(\"a\").reverse()")
  assert_eq(
    a.fill_null_strategy(@pl.FillStrategy::Mean).to_string(),
    "col(\"a\").fill_null_with_strategy()",
  )
  assert_eq(a.cum_sum().max().to_string(), "col(\"a\").cum_sum().max()")
}

///|
test "sequence expressions: composition, broadcasting and selectors" {
  let df = seq_df()
  // an aggregate of a running total
  assert_eq(
    df.select([@pl.col("a").cum_sum().max()]).column("a").to_int32_array(),
    [Some(8)],
  )
  // the difference with the previous row, and a running total in place
  let out = df.with_columns([
    (@pl.col("f") - @pl.col("f").shift(n=1)).alias("df"),
    @pl.col("a").cum_sum().alias("a"),
  ])
  assert_eq(out.columns(), ["a", "f", "s", "p", "d", "n", "df"])
  assert_eq(out.column("a").to_int32_array(), [Some(1), None, Some(4), Some(8)])
  assert_eq(out.column("df").to_float64_array(), [None, Some(1.0), None, None])
  // selectors
  let sel = df.select([@pl.cols(["a", "f"]).shift(n=1)])
  assert_eq(sel.columns(), ["a", "f"])
  assert_eq(sel.column("f").to_float64_array(), [
    None,
    Some(1.5),
    Some(2.5),
    None,
  ])
  // a literal's running total has length 1 and is repeated next to a column
  let b = df.select([@pl.col("a"), @pl.lit_int(1L).cum_sum().alias("one")])
  assert_eq(b.column("one").len(), 4)
  assert_eq(b.column("one").to_int64_array(), [
    Some(1L),
    Some(1L),
    Some(1L),
    Some(1L),
  ])
  // an aggregate shifted by one is a null of length 1
  let c = df.select([@pl.col("a").sum().shift(n=1)])
  assert_eq(c.column("a").to_int32_array(), [None])
  // duplicated output names
  assert_true(
    raises(() => df.select([@pl.col("a"), @pl.col("a").shift(n=1)]))
    is Some(@pl.DuplicateColumn(_)),
  )
  // empty frames
  let e = df.head(n=0)
  assert_eq(
    e.select([@pl.col("a").cum_sum(), @pl.col("s").rank()]).shape(),
    (0, 2),
  )
  assert_eq(
    e.select([@pl.col("a").cum_sum().max()]).column("a").to_int32_array(),
    [None],
  )
}

///|
fn fill_frame() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::int32_nullable("a", [None, Some(1), None, Some(4), None]),
    @pl.Series::float64_nullable("f", [Some(1.5), None, None, Some(3.5), None]),
    @pl.Series::str_nullable("s", [None, Some("x"), None, None, Some("y")]),
    @pl.Series::null("n", 5),
  ])
}

///|
test "DataFrame::fill_null_strategy: directional strategies, limit, types" {
  let df = fill_frame()
  let f = df.fill_null_strategy(@pl.FillStrategy::Forward)
  assert_eq(f.columns(), ["a", "f", "s", "n"])
  assert_eq(f.dtypes(), df.dtypes())
  assert_eq(f.column("a").to_int32_array(), [
    None,
    Some(1),
    Some(1),
    Some(4),
    Some(4),
  ])
  assert_eq(f.column("f").to_float64_array(), [
    Some(1.5),
    Some(1.5),
    Some(1.5),
    Some(3.5),
    Some(3.5),
  ])
  assert_eq(f.column("s").to_str_array(), [
    None,
    Some("x"),
    Some("x"),
    Some("x"),
    Some("y"),
  ])
  assert_eq(f.column("n").null_count(), 5)
  let b = df.fill_null_strategy(@pl.FillStrategy::Backward, limit=1)
  assert_eq(b.column("a").to_int32_array(), [
    Some(1),
    Some(1),
    Some(4),
    Some(4),
    None,
  ])
  assert_eq(b.column("s").to_str_array(), [
    Some("x"),
    Some("x"),
    None,
    Some("y"),
    Some("y"),
  ])
  let z = df.fill_null_strategy(@pl.FillStrategy::Forward, limit=0)
  assert_true(z.equals(df))
}

///|
test "DataFrame::fill_null_strategy: value strategies and the types that refuse them" {
  let df = fill_frame().select([@pl.col("a"), @pl.col("f")])
  let mn = df.fill_null_strategy(@pl.FillStrategy::Min)
  assert_eq(mn.column("a").to_int32_array(), [
    Some(1),
    Some(1),
    Some(1),
    Some(4),
    Some(1),
  ])
  let mean = df.fill_null_strategy(@pl.FillStrategy::Mean)
  assert_eq(mean.column("a").to_int32_array(), [
    Some(2),
    Some(1),
    Some(2),
    Some(4),
    Some(2),
  ])
  assert_eq(mean.column("f").to_float64_array(), [
    Some(1.5),
    Some(2.5),
    Some(2.5),
    Some(3.5),
    Some(2.5),
  ])
  let zero = df.fill_null_strategy(@pl.FillStrategy::Zero)
  assert_eq(zero.column("a").null_count(), 0)
  assert_eq(
    df.fill_null_strategy(@pl.FillStrategy::One).column("f").to_float64_array()[1],
    Some(1.0),
  )
  // Mean on a String column is refused, `n` makes zero fail
  assert_true(
    raises(() => fill_frame().fill_null_strategy(@pl.FillStrategy::Mean))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => fill_frame().fill_null_strategy(@pl.FillStrategy::Zero))
    is Some(@pl.InvalidOperation(_)),
  )
  // a limit needs a directional strategy; a negative one is refused
  assert_true(
    raises(() => df.fill_null_strategy(@pl.FillStrategy::Min, limit=1))
    is Some(@pl.InvalidOperation(_)),
  )
  assert_true(
    raises(() => df.fill_null_strategy(@pl.FillStrategy::Forward, limit=-1))
    is Some(@pl.InvalidOperation(_)),
  )
  // no column: nothing to fill, but the limit is still checked
  let empty = @pl.DataFrame::empty()
  assert_eq(empty.fill_null_strategy(@pl.FillStrategy::Mean).shape(), (0, 0))
  assert_true(
    raises(() => empty.fill_null_strategy(@pl.FillStrategy::Min, limit=1))
    is Some(@pl.InvalidOperation(_)),
  )
  // no row
  let e = fill_frame().head(n=0).fill_null_strategy(@pl.FillStrategy::Forward)
  assert_eq(e.shape(), (0, 4))
}

///|
test "sequence expressions on a Null column and on a weak literal" {
  // diff and shift of a Null column stay Null and as long as the column
  let d = seq_out(@pl.col("n").diff())
  assert_eq(d.dtype(), @pl.DataType::Null)
  assert_eq(d.len(), 4)
  assert_eq(
    seq_out(@pl.col("n").cum_count(reverse=true)).dtype(),
    @pl.DataType::Int64,
  )
  assert_eq(
    seq_out(@pl.col("n").rank(method_=@pl.RankMethod::Dense)).dtype(),
    @pl.DataType::Int64,
  )
  // a lone weak literal is an Int64 (spec 5.5; polars gives Int32 here)
  let lit = seq_out(@pl.lit_int(5L).cum_sum())
  assert_eq(lit.dtype(), @pl.DataType::Int64)
  assert_eq(lit.name(), "literal")
  assert_eq(lit.to_int64_array(), [Some(5L)])
  assert_eq(seq_out(@pl.lit_int(5L).shift(n=1)).to_int64_array(), [None])
  // a typed literal keeps its type
  let typed = seq_out(@pl.lit(@pl.AnyValue::Int32(5)).cum_sum())
  assert_eq(typed.dtype(), @pl.DataType::Int32)
  // the length of the frame decides the broadcast, also for several results
  let df = seq_df().select([
    @pl.col("a").cum_sum(),
    @pl.lit_int(1L).cum_sum().alias("one"),
    @pl.col("a").sum().cum_sum().alias("tot"),
  ])
  assert_eq(df.shape(), (4, 3))
  assert_eq(df.column("tot").to_int32_array(), [
    Some(8),
    Some(8),
    Some(8),
    Some(8),
  ])
}

///|
test "sequence expressions: Int32 limits and long runs do not trap" {
  let df = @pl.DataFrame::new([
    @pl.Series::int32("a", [2147483647, 1]),
    @pl.Series::int64("b", [9223372036854775807L, 1L]),
  ])
  // wraps around like the Series methods
  assert_eq(df.select([@pl.col("a").cum_sum()]).column("a").to_int32_array(), [
    Some(2147483647),
    Some(-2147483648),
  ])
  assert_eq(df.select([@pl.col("b").cum_sum()]).column("b").to_int64_array(), [
    Some(9223372036854775807L),
    Some(-9223372036854775808L),
  ])
  assert_eq(df.select([@pl.col("a").diff(n=1)]).column("a").to_int32_array(), [
    None,
    Some(-2147483646),
  ])
  // the shift distance can be as large as an Int
  assert_eq(
    df.select([@pl.col("a").shift(n=2147483647)]).column("a").null_count(),
    2,
  )
  assert_eq(
    df.select([@pl.col("a").shift(n=-2147483647 - 1)]).column("a").null_count(),
    2,
  )
}
