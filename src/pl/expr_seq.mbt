// Sequence operations on expressions: `shift`, `diff`, the running
// aggregates, `rank`, `reverse` and `fill_null_strategy`.
//
// Each one is the method of the same name on `Series` applied to the column
// the expression stands for, so the types, the null rules and the errors are
// those of the Series methods (`sequence.mbt`). The output column is named
// after the input; the length is the input's (a length-1 input, such as an
// aggregate or a literal, stays length 1 and is repeated by `select` next to
// longer columns).

// ---------------------------------------------------------------------------
// The operations
// ---------------------------------------------------------------------------

///|
/// A sequence operation of one expression.
priv enum SeqOp {
  /// `Shift(n, fill_value)`; `AnyValue::Null` is "no fill value"
  Shift(Int32, AnyValue)
  Diff(Int32)
  /// `CumSum(reverse)` and the like
  CumSum(Bool)
  CumMin(Bool)
  CumMax(Bool)
  CumProd(Bool)
  CumCount(Bool)
  Rank(RankMethod, Bool)
  Reverse
  /// `Fill(strategy, limit)`
  Fill(FillStrategy, Int32?)
}

///|
/// The call as polars prints it: `shift([dyn int: 1])`,
/// `shift_and_fill([dyn int: 1, 5])`, `cum_sum()` (the direction is not part
/// of the text), `rank()`, `fill_null_with_strategy()`.
fn SeqOp::text(self : SeqOp) -> String {
  match self {
    Shift(n, Null) => "shift([dyn int: \{n}])"
    Shift(n, fill) =>
      "shift_and_fill([dyn int: \{n}, \{literal_text(fill, Strong)}])"
    Diff(n) => "diff([dyn int: \{n}])"
    CumSum(_) => "cum_sum()"
    CumMin(_) => "cum_min()"
    CumMax(_) => "cum_max()"
    CumProd(_) => "cum_prod()"
    CumCount(_) => "cum_count()"
    Rank(_, _) => "rank()"
    Reverse => "reverse()"
    Fill(_, _) => "fill_null_with_strategy()"
  }
}

///|
/// polars refuses a `limit` that does not go with the strategy, or a negative
/// one, while the expression is built (a Python error); the library reports
/// the same errors with the same text, as `InvalidOperation`, when the
/// expression is expanded or evaluated.
///
/// # Errors
/// `InvalidOperation` for a `limit` with a strategy other than `Forward` or
/// `Backward`, and for a negative `limit`.
fn xseq_check_limit(
  strategy : FillStrategy,
  limit : Int32?,
) -> Unit raise PolarsError {
  match limit {
    Some(l) =>
      if !(strategy is (Forward | Backward)) {
        raise InvalidOperation(
          "can only specify `limit` when strategy is set to 'backward' or 'forward'",
        )
      } else if l < 0 {
        raise InvalidOperation("number too small to fit in target type")
      }
    None => ()
  }
}

///|
/// The operation on the evaluated input.
fn SeqOp::apply(self : SeqOp, s : Series) -> Series raise PolarsError {
  match self {
    Shift(n, fill) => s.shift(n, fill_value=fill)
    Diff(n) => s.diff(n~)
    CumSum(rev) => s.cum_sum(reverse=rev)
    CumMin(rev) => s.cum_min(reverse=rev)
    CumMax(rev) => s.cum_max(reverse=rev)
    CumProd(rev) => s.cum_prod(reverse=rev)
    CumCount(rev) => s.cum_count(reverse=rev)
    Rank(method, descending) => s.rank(method~, descending~)
    Reverse => s.reverse()
    Fill(strategy, limit) => s.fill_null_strategy(strategy, limit?)
  }
}

///|
fn Expr::seq(self : Expr, op : SeqOp) -> Expr {
  Expr::of(ExprNode::Seq(op, self.node))
}

// ---------------------------------------------------------------------------
// Public methods
// ---------------------------------------------------------------------------

///|
/// Moves the values down by `n` rows (up for a negative `n`); the rows that
/// are left empty are null, or `fill_value` when it is not `AnyValue::Null`.
/// The type is that of the column, or the supertype of the column and the
/// fill value (a typed value: an `Int32` column with `AnyValue::Float64(0.5)`
/// gives `Float64`). `n` beyond the length gives all nulls. The output is
/// named after the column.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::int32("a", [1, 2, 3])])
///   let out = df.select([@pl.col("a").shift(1)])
///   assert_eq(out.column("a").to_int32_array(), [None, Some(1), Some(2)])
/// }
/// ```
///
/// # Errors
/// Evaluating it raises `SchemaMismatch` when the column and the fill value
/// have no common type and `ComputeError` for a `Date` or `Datetime` fill
/// value in a `Boolean` column (see `Series::shift`).
pub fn Expr::shift(
  self : Expr,
  n : Int32,
  fill_value~ : AnyValue = AnyValue::Null,
) -> Expr {
  self.seq(SeqOp::Shift(n, fill_value))
}

///|
/// The difference with the value `n` rows before (`self - self.shift(n)`):
/// null for the first `n` rows and wherever either value is null. Integers
/// wrap around on overflow; a `Boolean` or `String` column is refused, and so
/// is a `Date` or `Datetime` one (polars gives a `Duration`, which this
/// library has not). The output is named after the column.
///
/// # Errors
/// Evaluating it raises `InvalidOperation` for those types (see
/// `Series::diff`).
pub fn Expr::diff(self : Expr, n~ : Int32 = 1) -> Expr {
  self.seq(SeqOp::Diff(n))
}

///|
/// The running sum of the non-null values, as `Series::cum_sum` (a null row
/// stays null and is skipped; `reverse` starts at the last row; integers wrap
/// around; a `Boolean` counts as `Int64`).
///
/// # Errors
/// Evaluating it raises `InvalidOperation` for `String`, `Date`, `Datetime`
/// and `Null` columns.
pub fn Expr::cum_sum(self : Expr, reverse~ : Bool = false) -> Expr {
  self.seq(SeqOp::CumSum(reverse))
}

///|
/// The running minimum, as `Series::cum_min`; works on `String` and `Boolean`
/// too. Errors as `Expr::cum_sum` for `Date`, `Datetime` and `Null`.
pub fn Expr::cum_min(self : Expr, reverse~ : Bool = false) -> Expr {
  self.seq(SeqOp::CumMin(reverse))
}

///|
/// The running maximum, as `Series::cum_max`; see `Expr::cum_min`.
pub fn Expr::cum_max(self : Expr, reverse~ : Bool = false) -> Expr {
  self.seq(SeqOp::CumMax(reverse))
}

///|
/// The running product, as `Series::cum_prod` (integers of 32 bits or fewer
/// give `Int64`). Errors as `Expr::cum_sum`.
pub fn Expr::cum_prod(self : Expr, reverse~ : Bool = false) -> Expr {
  self.seq(SeqOp::CumProd(reverse))
}

///|
/// The number of non-null values so far (`Int64`), as `Series::cum_count`;
/// never null and never an error.
pub fn Expr::cum_count(self : Expr, reverse~ : Bool = false) -> Expr {
  self.seq(SeqOp::CumCount(reverse))
}

///|
/// The rank of each value, as `Series::rank`: a `Float64` for `Average`,
/// `Int64` for the other methods; a null row stays null and takes no rank.
/// The output is named after the column.
pub fn Expr::rank(
  self : Expr,
  method~ : RankMethod = Average,
  descending~ : Bool = false,
) -> Expr {
  self.seq(SeqOp::Rank(method, descending))
}

///|
/// The values in reverse order; type and name are kept.
pub fn Expr::reverse(self : Expr) -> Expr {
  self.seq(SeqOp::Reverse)
}

///|
/// Replaces the nulls using `strategy`, as `Series::fill_null_strategy` (type
/// kept). `limit` (`limit=1`) bounds how many consecutive nulls `Forward` and
/// `Backward` fill.
///
/// # Errors
/// `InvalidOperation` for a `limit` with another strategy than `Forward` or
/// `Backward` or a negative `limit` (polars raises these while building the
/// expression; here it is when the expression is expanded or evaluated, also
/// when a selector gives no column), and for the types a strategy refuses
/// (`Mean` of a `Boolean` or `String`, `One` of a `String`, `Zero` and `One`
/// of a `Null` column) when the column has a null.
pub fn Expr::fill_null_strategy(
  self : Expr,
  strategy : FillStrategy,
  limit? : Int32,
) -> Expr {
  self.seq(SeqOp::Fill(strategy, limit))
}
