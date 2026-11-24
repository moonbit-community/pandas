///|
/// The error `f` raises, if any.
fn[T] wb_err(f : () -> T raise PolarsError) -> PolarsError? {
  try {
    ignore(f())
    None
  } catch {
    e => Some(e)
  }
}

///|
fn wb_frame() -> DataFrame raise PolarsError {
  DataFrame::new([
    Series::int32_nullable("a", [Some(1), None, Some(3)]),
    Series::int64("b", [10L, 20L, 30L]),
    Series::float32("f", [0.5, 1.5, 2.5]),
    Series::str("s", ["x", "y", "z"]),
  ])
}

///|
fn wb_names(nodes : Array[ExprNode]) -> Array[String] {
  nodes.map(output_name)
}

///|
/// `expand_selectors` and then `check_columns` on each result: the expansion
/// of one expression as a whole (a list of expressions is resolved by
/// `eval_unbroadcast`, in polars' order).
fn wb_expand(df : DataFrame, e : Expr) -> Array[ExprNode] raise PolarsError {
  let nodes = expand_selectors(df, e)
  for node in nodes {
    check_columns(df, node)
  }
  nodes
}

///|
test "output_name: leftmost column, literal, alias" {
  assert_eq(output_name(col("a").node), "a")
  assert_eq(output_name((col("a") + col("b")).node), "a")
  assert_eq(output_name((lit_int(1L) + col("b")).node), "literal")
  assert_eq(output_name(lit_str("x").node), "literal")
  assert_eq(output_name(lit(AnyValue::Null).node), "literal")
  assert_eq(output_name((-col("a")).node), "a")
  assert_eq(output_name(col("a").not_().node), "a")
  assert_eq(output_name(col("a").is_null().node), "a")
  assert_eq(output_name(col("a").is_not_null().node), "a")
  assert_eq(output_name(col("a").cast(Float64).node), "a")
  assert_eq(output_name(col("a").alias("z").node), "z")
  assert_eq(output_name((col("a").alias("z") + col("b")).node), "z")
  assert_eq(output_name((col("a") + col("b").alias("z")).node), "a")
}

///|
test "expand: selectors become one column expression each" {
  let df = wb_frame()
  assert_eq(wb_names(wb_expand(df, col("a"))), ["a"])
  assert_eq(wb_names(wb_expand(df, cols(["b", "a"]))), ["b", "a"])
  assert_eq(wb_names(wb_expand(df, all())), ["a", "b", "f", "s"])
  assert_eq(wb_names(wb_expand(df, lit_int(1L))), ["literal"])
  // duplicates in `cols` count once, in the order of first appearance
  assert_eq(wb_names(wb_expand(df, cols(["b", "a", "b"]))), ["b", "a"])
  // the operation is repeated per column
  let nodes = wb_expand(df, cols(["a", "b"]) + lit_int(1L))
  assert_eq(nodes.length(), 2)
  assert_eq(nodes[1].text(), "[(col(\"b\")) + (dyn int: 1)]")
  // nothing to expand
  assert_eq(wb_expand(df, cols([])).length(), 0)
  assert_eq(wb_expand(DataFrame::empty(), all()).length(), 0)
  assert_eq(wb_expand(DataFrame::empty(), lit_int(1L)).length(), 1)
}

///|
test "expand: pairing of selectors" {
  let df = wb_frame()
  // equal widths pair up, names are the left side's
  let zip = wb_expand(df, cols(["a", "b"]) + cols(["b", "a"]))
  assert_eq(wb_names(zip), ["a", "b"])
  assert_eq(zip[0].text(), "[(col(\"a\")) + (col(\"b\"))]")
  assert_eq(zip[1].text(), "[(col(\"b\")) + (col(\"a\"))]")
  // a single column pairs with each column of the other side
  let one_right = wb_expand(df, cols(["a", "b"]) + col("f"))
  assert_eq(one_right.map(n => n.text()), [
    "[(col(\"a\")) + (col(\"f\"))]", "[(col(\"b\")) + (col(\"f\"))]",
  ])
  let one_left = wb_expand(df, col("f") + cols(["a", "b"]))
  assert_eq(wb_names(one_left), ["f", "f"])
  // an empty selector against one column: nothing
  assert_eq(wb_expand(df, cols([]) + col("a")).length(), 0)
  assert_eq(wb_expand(df, col("a") + cols([])).length(), 0)
  // unary operations map over the selector
  assert_eq(wb_expand(df, cols(["a", "b"]).cast(Int32)).map(n => n.text()), [
    "col(\"a\").strict_cast(Int32)", "col(\"b\").strict_cast(Int32)",
  ])
  assert_eq(wb_expand(df, all().is_null()).map(n => n.text()).length(), 4)
}

///|
test "expand: errors" {
  let df = wb_frame()
  assert_eq(
    wb_err(() => wb_expand(df, col("zz"))).map(e => e.to_string()),
    Some(
      "ColumnNotFound: unable to find column \"zz\"; valid columns: [\"a\", \"b\", \"f\", \"s\"]",
    ),
  )
  assert_eq(
    wb_err(() => wb_expand(df, cols(["a", "zz", "yy"]))).map(e => e.to_string()),
    Some("ColumnNotFound: \"zz\" not found"),
  )
  assert_eq(
    wb_err(() => wb_expand(df, cols(["a", "b"]) + cols(["a", "b", "f"]))).map(e => {
      e.to_string()
    }),
    Some(
      "InvalidOperation: cannot combine selectors that produce a different number of columns (3 != 2)",
    ),
  )
  // names with quotes and newlines are escaped as Rust's Debug does
  let odd = DataFrame::new([Series::int32("q\"x\n", [1])])
  assert_eq(
    wb_err(() => wb_expand(odd, col("a"))).map(e => e.to_string()),
    Some(
      "ColumnNotFound: unable to find column \"a\"; valid columns: [\"q\\\"x\\n\"]",
    ),
  )
}

///|
test "eval_exprs: names, selectors and broadcasting" {
  let df = wb_frame()
  let r = eval_exprs(df, [col("a"), lit_int(5L).alias("k"), cols(["b", "f"])])
  assert_eq(r.map(s => s.name()), ["a", "k", "b", "f"])
  assert_eq(r.map(s => s.len()), [3, 3, 3, 3])
  // all results of length 1: not broadcast
  let ones = eval_exprs(df, [lit_int(1L), lit_str("x").alias("t")])
  assert_eq(ones.map(s => s.len()), [1, 1])
  // no expression
  assert_eq(eval_exprs(df, []).length(), 0)
  // duplicates
  assert_true(
    wb_err(() => eval_exprs(df, [col("a"), col("a")]))
    is Some(DuplicateColumn(_)),
  )
  // evaluation errors surface
  assert_true(
    wb_err(() => eval_exprs(df, [col("s") + col("s")]))
    is Some(InvalidOperation(_)),
  )
}

///|
test "broadcast_results: lengths" {
  let two = Series::int32("x", [1, 2])
  let one = Series::int32("y", [9])
  let zero = Series::int32("z", [])
  // 1 and n: the 1 is repeated; the others are kept as they are
  let r = broadcast_results([one, two, one.rename("w")])
  assert_eq(r.map(s => s.len()), [2, 2, 2])
  assert_eq(r[0].to_list(), [AnyValue::Int32(9), Int32(9)])
  // 1 and 0: zero rows
  let e = broadcast_results([one, zero])
  assert_eq(e.map(s => s.len()), [0, 0])
  // all 1: unchanged
  assert_eq(broadcast_results([one, one.rename("w")]).map(s => s.len()), [1, 1])
  assert_eq(broadcast_results([]).length(), 0)
  // two lengths that are not 1
  assert_eq(
    wb_err(() => broadcast_results([two, Series::int32("w", [1, 2, 3])])).map(e => {
      e.to_string()
    }),
    Some(
      "ShapeMismatch: Series length 2 doesn't match the DataFrame height of 3",
    ),
  )
  assert_eq(
    wb_err(() => broadcast_results([zero, two])).map(e => e.to_string()),
    Some(
      "ShapeMismatch: Series length 0 doesn't match the DataFrame height of 2",
    ),
  )
  // polars: the height is the longest result, the first that differs is named
  let three = Series::int32("t", [1, 2, 3])
  let four = Series::int32("q", [1, 2, 3, 4])
  assert_eq(
    wb_err(() => broadcast_results([four, two])).map(e => e.to_string()),
    Some(
      "ShapeMismatch: Series length 2 doesn't match the DataFrame height of 4",
    ),
  )
  assert_eq(
    wb_err(() => broadcast_results([three, two, four])).map(e => e.to_string()),
    Some(
      "ShapeMismatch: Series length 3 doesn't match the DataFrame height of 4",
    ),
  )
  // an empty result in the mix: a length 1 is not repeated, it is the
  // offender if it comes first (polars)
  assert_eq(
    wb_err(() => broadcast_results([one, zero, two])).map(e => e.to_string()),
    Some(
      "ShapeMismatch: Series length 1 doesn't match the DataFrame height of 2",
    ),
  )
  assert_eq(
    wb_err(() => broadcast_results([zero, one, two])).map(e => e.to_string()),
    Some(
      "ShapeMismatch: Series length 0 doesn't match the DataFrame height of 2",
    ),
  )
  assert_eq(
    wb_err(() => broadcast_results([two, one, zero])).map(e => e.to_string()),
    Some(
      "ShapeMismatch: Series length 1 doesn't match the DataFrame height of 2",
    ),
  )
  assert_eq(
    wb_err(() => broadcast_results([two, zero, one])).map(e => e.to_string()),
    Some(
      "ShapeMismatch: Series length 0 doesn't match the DataFrame height of 2",
    ),
  )
  assert_eq(
    wb_err(() => broadcast_results([two, zero])).map(e => e.to_string()),
    Some(
      "ShapeMismatch: Series length 0 doesn't match the DataFrame height of 2",
    ),
  )
}

///|
test "eval_unbroadcast: expands and checks names before evaluating" {
  let df = DataFrame::new([
    Series::str("s", ["x", "y"]),
    Series::int32("i", [1, 2]),
  ])
  // a missing column wins over an earlier kernel error
  assert_eq(
    wb_err(() => {
      eval_unbroadcast(df, [col("s") + lit_int(1L), col("zz")], false)
    }).map(e => e.to_string().split(":").next().unwrap().to_owned()),
    Some("ColumnNotFound"),
  )
  // so does a repeated name
  assert_true(
    wb_err(() => {
      eval_unbroadcast(df, [col("i"), col("i"), col("s") + lit_int(1L)], false)
    })
    is Some(DuplicateColumn(_)),
  )
  // results are not broadcast among themselves
  let r = eval_unbroadcast(df, [lit_int(1L), col("i")], true)
  assert_eq(r.map(s => s.len()), [1, 2])
}

///|
test "expand_n: three children, and a selector with no column" {
  let df = wb_frame()
  let join3 = fn(g : Array[ExprNode]) {
    ExprNode::Binary(Add, Binary(Add, g[0], g[1]), g[2])
  }
  // cols pair up; single children pair with every column
  let r = expand_n(
    df,
    [Columns(["a", "b"]), Column("f"), Columns(["s", "a"])],
    join3,
  )
  assert_eq(r.length(), 2)
  assert_eq(r.map(output_name), ["a", "b"])
  assert_eq(
    wb_err(() => {
      expand_n(
        df,
        [Columns(["a", "b"]), Column("f"), Columns(["s", "a", "b"])],
        join3,
      )
    }).map(e => e.to_string()),
    Some(
      "InvalidOperation: cannot combine selectors that produce a different number of columns (3 != 2)",
    ),
  )
  // all() with no column: the other children are not looked at
  let empty = DataFrame::new([])
  assert_eq(
    expand_n(empty, [All, Column("zz"), Literal(AnyValue::Null, Strong)], join3).length(),
    0,
  )
  // expand_n does not look plain columns up; `wb_expand` does, once the
  // selectors have given a column
  assert_eq(expand_n(df, [All, Column("zz")], g => g[0]).length(), 4)
  assert_true(
    wb_err(() => wb_expand(df, all() + col("zz"))) is Some(ColumnNotFound(_)),
  )
  assert_eq(wb_expand(empty, all() + col("zz")).length(), 0)
}

///|
test "eval_unbroadcast: polars' order of the error phases" {
  let df = wb_frame()
  let text = fn(op : Bool, es : Array[Expr]) {
    wb_err(() => eval_unbroadcast(df, es, op)).map(e => e.to_string())
  }
  let miss = "ColumnNotFound: unable to find column \"zz\"; valid columns: [\"a\", \"b\", \"f\", \"s\"]"
  let dup_sel = "DuplicateColumn: projections contained duplicate output name 'a'. It's possible that multiple expressions are returning the same default column name. If this is the case, try renaming the columns with `.alias(\"new_name\")` to avoid duplicate column names."
  let dup_wc = "DuplicateColumn: the name 'a' passed to `LazyFrame.with_columns` is duplicate"
  // a selector error beats an earlier missing plain column, in both
  for op in [false, true] {
    assert_eq(
      text(op, [col("zz"), cols(["qq"])]),
      Some("ColumnNotFound: \"qq\" not found"),
    )
    assert_eq(
      text(op, [col("zz"), cols(["a", "b"]) + cols(["a", "b", "f"])]),
      Some(
        "InvalidOperation: cannot combine selectors that produce a different number of columns (3 != 2)",
      ),
    )
  }
  // duplicates: in select, expression by expression after its plain columns;
  // in with_columns, after all the plain columns
  assert_eq(text(false, [col("a"), col("a"), col("zz")]), Some(dup_sel))
  assert_eq(text(false, [col("a"), col("zz"), col("a")]), Some(miss))
  assert_eq(text(false, [col("zz"), col("a"), col("a")]), Some(miss))
  assert_eq(
    text(false, [col("a").alias("q"), col("zz").alias("q")]),
    Some(miss),
  )
  assert_eq(text(true, [col("a"), col("a"), col("zz")]), Some(miss))
  assert_eq(text(true, [col("a"), col("a")]), Some(dup_wc))
  // and both before any kernel
  assert_eq(
    text(false, [col("s") + lit_int(1L), col("s").cast(Int32)]).map(e => {
      e.split(":").next().unwrap().to_owned()
    }),
    Some("DuplicateColumn"),
  )
  // a selector with columns: the plain column next to it is looked up; with
  // none (an empty frame) it is not
  assert_eq(text(false, [all() + col("zz")]), Some(miss))
  assert_true(
    wb_err(() => {
      eval_unbroadcast(DataFrame::new([]), [all() + col("zz")], false)
    })
    is None,
  )
}

///|
test "fit_height: with_columns' length rule" {
  let two = Series::int32("x", [1, 2])
  let one = Series::int32("y", [9])
  assert_eq(fit_height(two, 2).len(), 2)
  assert_eq(fit_height(one, 4).len(), 4)
  assert_eq(fit_height(one, 0).len(), 0)
  assert_eq(fit_height(one, 1).len(), 1)
  assert_eq(
    wb_err(() => fit_height(two, 4)).map(e => e.to_string()),
    Some("ShapeMismatch: can't broadcast Series 'x' of length 2 to length 4"),
  )
  assert_true(wb_err(() => fit_height(two, 0)) is Some(ShapeMismatch(_)))
}

///|
test "weak_series: the type a weak literal takes" {
  fn dt(w : WeakVal, other : DataType) -> DataType {
    weak_series("x", w, other).dtype()
  }

  assert_eq(dt(Int(1L), Int32), DataType::Int32)
  assert_eq(dt(Int(2147483647L), Int32), DataType::Int32)
  assert_eq(dt(Int(2147483648L), Int32), DataType::Int64)
  assert_eq(dt(Int(-2147483648L), Int32), DataType::Int32)
  assert_eq(dt(Int(-2147483649L), Int32), DataType::Int64)
  assert_eq(dt(Int(1L << 40), Int64), DataType::Int64)
  assert_eq(dt(Int(1L), Float32), DataType::Float32)
  assert_eq(dt(Int(1L), Float64), DataType::Float64)
  assert_eq(dt(Int(1L), Null), DataType::Int32)
  assert_eq(dt(Int(1L << 40), Null), DataType::Int64)
  assert_eq(dt(Int(1L), Boolean), DataType::Int32)
  assert_eq(dt(Int(1L), String), DataType::Int32)
  assert_eq(dt(Int(1L), Date), DataType::Int32)
  assert_eq(dt(Float(1.5), Float32), DataType::Float32)
  assert_eq(dt(Float(1.5), Float64), DataType::Float64)
  assert_eq(dt(Float(1.5), Int32), DataType::Float64)
  assert_eq(dt(Float(1.5), Null), DataType::Float64)
  // a float too big for Float32 is infinity there
  assert_true(
    weak_series("x", Float(1.0e300), Float32).to_float32_array()[0]
    .unwrap()
    .is_inf(),
  )
  assert_eq(weak_default("x", Int(7L)).dtype(), DataType::Int64)
  assert_eq(weak_default("x", Float(7.0)).dtype(), DataType::Float64)
}

///|
test "fold_int: overflow and division by zero give no weak value" {
  let max = @int64.MAX_VALUE
  let min = @int64.MIN_VALUE
  assert_eq(fold_int(BinaryOp::Add, 1L, 2L), Some(3L))
  assert_eq(fold_int(BinaryOp::Add, max, 1L), None)
  assert_eq(fold_int(BinaryOp::Add, min, -1L), None)
  assert_eq(fold_int(BinaryOp::Add, max, min), Some(-1L))
  assert_eq(fold_int(BinaryOp::Sub, 1L, 2L), Some(-1L))
  assert_eq(fold_int(BinaryOp::Sub, min, 1L), None)
  assert_eq(fold_int(BinaryOp::Sub, max, -1L), None)
  assert_eq(fold_int(BinaryOp::Sub, -1L, min), Some(max))
  assert_eq(fold_int(BinaryOp::Mul, 3L, -4L), Some(-12L))
  assert_eq(fold_int(BinaryOp::Mul, 0L, min), Some(0L))
  assert_eq(fold_int(BinaryOp::Mul, min, -1L), None)
  assert_eq(fold_int(BinaryOp::Mul, -1L, min), None)
  assert_eq(fold_int(BinaryOp::Mul, 1L << 62, 4L), None)
  assert_eq(fold_int(BinaryOp::Mul, 1L << 31, 1L << 31), Some(1L << 62))
  assert_eq(fold_int(BinaryOp::Mul, max, 1L), Some(max))
  assert_eq(fold_int(BinaryOp::Mul, min, 1L), Some(min))
  assert_eq(fold_int(BinaryOp::FloorDiv, -7L, 2L), Some(-4L))
  assert_eq(fold_int(BinaryOp::FloorDiv, 7L, 0L), None)
  assert_eq(fold_int(BinaryOp::FloorDiv, min, -1L), None)
  assert_eq(fold_int(BinaryOp::Rem, -7L, 2L), Some(1L))
  assert_eq(fold_int(BinaryOp::Rem, 7L, 0L), None)
  assert_eq(fold_int(BinaryOp::Rem, min, -1L), None)
  assert_eq(fold_int(BinaryOp::Div, 7L, 2L), None)
  assert_eq(fold_int(BinaryOp::Eq, 7L, 7L), None)
}

///|
test "weak literals: overflow falls back to the Int64 kernels" {
  let df = wb_frame()
  let max = @int64.MAX_VALUE
  // lit(MAX) + lit(1) wraps around in Int64, as a strong series would
  let r = eval_exprs(df, [lit_int(max) + lit_int(1L)])
  assert_eq(r[0].to_list(), [AnyValue::Int64(@int64.MIN_VALUE)])
  // -lit(MIN) wraps too
  let n = eval_exprs(df, [-lit_int(@int64.MIN_VALUE)])
  assert_eq(n[0].to_list(), [AnyValue::Int64(@int64.MIN_VALUE)])
  // floor division by zero is a null Int64
  let z = eval_exprs(df, [lit_int(1L).floor_div(lit_int(0L))])
  assert_eq(z[0].to_list(), [AnyValue::Null])
  assert_eq(z[0].dtype(), DataType::Int64)
}

///|
test "null_mask on a sliced column and a column without nulls" {
  let s = Series::int32_nullable("a", [Some(1), None, Some(3), None, Some(5)])
  let sliced = s.slice(1, length=3)
  assert_eq(sliced.null_mask(true).to_list(), [
    AnyValue::Boolean(true),
    Boolean(false),
    Boolean(true),
  ])
  assert_eq(sliced.null_mask(false).to_list(), [
    AnyValue::Boolean(false),
    Boolean(true),
    Boolean(false),
  ])
  let plain = Series::str("p", ["x", "y"])
  assert_eq(plain.null_mask(true).to_list(), [
    AnyValue::Boolean(false),
    Boolean(false),
  ])
  assert_eq(plain.null_mask(false).null_count(), 0)
  assert_eq(Series::null("n", 2).null_mask(true).to_list(), [
    AnyValue::Boolean(true),
    Boolean(true),
  ])
  assert_eq(Series::null("n", 0).null_mask(true).len(), 0)
}

///|
test "logic_check and compare_check: polars' expression errors" {
  assert_true(
    wb_err(() => logic_check(BinaryOp::And, Boolean, Boolean)) is None,
  )
  assert_true(wb_err(() => logic_check(BinaryOp::Or, Boolean, Null)) is None)
  assert_eq(
    wb_err(() => logic_check(BinaryOp::And, Boolean, Int32)).map(e => {
      e.to_string()
    }),
    Some("ComputeError: & on Boolean and Int32 is not supported"),
  )
  assert_eq(
    wb_err(() => logic_check(BinaryOp::Or, Float64, Boolean)).map(e => {
      e.to_string()
    }),
    Some("ComputeError: | on Float64 and Boolean is not supported"),
  )
  assert_eq(
    wb_err(() => logic_check(BinaryOp::And, Null, String)).map(e => {
      e.to_string()
    }),
    Some("InvalidOperation: `bitand` operation not supported for dtype `str`"),
  )
  assert_eq(
    wb_err(() => logic_check(BinaryOp::Or, Date, Date)).map(e => e.to_string()),
    Some("InvalidOperation: | not allowed on date and date"),
  )
  assert_true(
    wb_err(() => logic_check(BinaryOp::And, Int32, Int64))
    is Some(InvalidOperation(_)),
  )
  assert_true(wb_err(() => compare_check(Int32, Int64)) is None)
  assert_true(wb_err(() => compare_check(String, Boolean)) is None)
  assert_true(
    wb_err(() => compare_check(String, Date)) is Some(InvalidOperation(_)),
  )
  assert_true(
    wb_err(() => compare_check(Datetime, String)) is Some(InvalidOperation(_)),
  )
}

///|
test "logic_check: Date and Datetime on either side, before String and numbers" {
  let text = fn(op, a, b) {
    wb_err(() => logic_check(op, a, b)).map(e => e.to_string())
  }
  assert_eq(
    text(BinaryOp::And, Datetime, Datetime),
    Some(
      "InvalidOperation: & not allowed on datetime[\u{3bc}s] and datetime[\u{3bc}s]",
    ),
  )
  assert_eq(
    text(BinaryOp::And, Boolean, Date),
    Some("InvalidOperation: & not allowed on bool and date"),
  )
  assert_eq(
    text(BinaryOp::Or, Date, Boolean),
    Some("InvalidOperation: | not allowed on date and bool"),
  )
  assert_eq(
    text(BinaryOp::And, Int32, Date),
    Some("InvalidOperation: & not allowed on i32 and date"),
  )
  assert_eq(
    text(BinaryOp::Or, String, Datetime),
    Some("InvalidOperation: | not allowed on str and datetime[\u{3bc}s]"),
  )
  assert_eq(
    text(BinaryOp::And, Date, Datetime),
    Some("InvalidOperation: & not allowed on date and datetime[\u{3bc}s]"),
  )
}

///|
test "weak -lit(MIN) leaves the weak path (known difference: polars gives UInt64)" {
  let df = wb_frame()
  let min = @int64.MIN_VALUE
  // as a strong Int64 it meets a Float32 column in Float64; a weak literal
  // would have kept Float32
  let r = eval_exprs(df, [col("f") + -lit_int(min)])
  assert_eq(r[0].dtype(), DataType::Float64)
  // a weak -5 stays weak
  let w = eval_exprs(df, [col("f") + -lit_int(5L)])
  assert_eq(w[0].dtype(), DataType::Float32)
}

///|
test "weak float %: the sign follows the divisor" {
  let df = wb_frame()
  let f = fn(e) raise { eval_exprs(df, [e])[0] }
  // f = [0.5, 1.5, 2.5]; -1.5 % 1.0 = 0.5, 5.5 % -2.0 = -0.5
  assert_eq(f(col("f") + lit_float(-1.5) % lit_float(1.0)).to_list(), [
    AnyValue::Float32(1.0),
    Float32(2.0),
    Float32(3.0),
  ])
  assert_eq(f(col("f") + lit_float(5.5) % lit_float(-2.0)).to_list(), [
    AnyValue::Float32(0.0),
    Float32(1.0),
    Float32(2.0),
  ])
  assert_eq(f(lit_float(-1.5) % lit_float(1.0)).to_list(), [
    AnyValue::Float64(0.5),
  ])
  assert_eq(f(lit_float(1.5) % lit_float(-1.0)).to_list(), [
    AnyValue::Float64(-0.5),
  ])
}

///|
test "column names with a backslash are escaped in errors" {
  let odd = DataFrame::new([Series::int32("a\\b", [1])])
  assert_eq(
    wb_err(() => wb_expand(odd, col("x\\y"))).map(e => e.to_string()),
    Some(
      "ColumnNotFound: unable to find column \"x\\\\y\"; valid columns: [\"a\\\\b\"]",
    ),
  )
  assert_eq(
    wb_err(() => wb_expand(odd, cols(["q\\"]))).map(e => e.to_string()),
    Some("ColumnNotFound: \"q\\\\\" not found"),
  )
}
