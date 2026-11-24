// The `dt()` namespace of expressions: calendar and clock fields of `Date`
// and `Datetime` columns, by the kernel `dt_field` (`dt_ops.mbt`).

///|
/// The date and time functions of an expression, from `Expr::dt`.
struct ExprDt {
  expr : Expr
}

///|
/// The call as polars prints it: `dt.year()`.
fn DtField::text(self : DtField) -> String {
  "dt.\{self.name()}()"
}

///|
fn ExprDt::field(self : ExprDt, f : DtField) -> Expr {
  Expr::of(ExprNode::Dt(f, self.expr.node))
}

///|
/// The date and time functions of this expression (`col("d").dt().year()`).
/// Each field is an `Int32` expression named after the column; evaluating it
/// raises `InvalidOperation` for a column that is not a `Date` or `Datetime`
/// (a `Null` column too), and for a clock field of a `Date`.
pub fn Expr::dt(self : Expr) -> ExprDt {
  { expr: self, }
}

///|
/// The year (negative before year 1; null for a date outside the supported
/// calendar, which runs from -262143-01-01 to 262142-12-31).
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::date("d", [0, 19782])])
///   let out = df.select([@pl.col("d").dt().year()])
///   assert_eq(out.column("d").to_int32_array(), [Some(1970), Some(2024)])
/// }
/// ```
pub fn ExprDt::year(self : ExprDt) -> Expr {
  self.field(DtField::Year)
}

///|
/// The month, 1 to 12.
pub fn ExprDt::month(self : ExprDt) -> Expr {
  self.field(DtField::Month)
}

///|
/// The day of the month, 1 to 31.
pub fn ExprDt::day(self : ExprDt) -> Expr {
  self.field(DtField::Day)
}

///|
/// The ISO weekday: Monday is 1, Sunday is 7.
pub fn ExprDt::weekday(self : ExprDt) -> Expr {
  self.field(DtField::Weekday)
}

///|
/// The day of the year, 1 to 366.
pub fn ExprDt::ordinal_day(self : ExprDt) -> Expr {
  self.field(DtField::OrdinalDay)
}

///|
/// The hour, 0 to 23; a `Datetime` is needed.
pub fn ExprDt::hour(self : ExprDt) -> Expr {
  self.field(DtField::Hour)
}

///|
/// The minute, 0 to 59; a `Datetime` is needed.
pub fn ExprDt::minute(self : ExprDt) -> Expr {
  self.field(DtField::Minute)
}

///|
/// The second, 0 to 59 (no leap seconds); a `Datetime` is needed.
pub fn ExprDt::second(self : ExprDt) -> Expr {
  self.field(DtField::Second)
}
