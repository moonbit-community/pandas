// The `str()` namespace of expressions: string functions on the column an
// expression stands for. The kernels are those of `str_ops.mbt`; the result
// is named after the input and as long as it is.

///|
/// The string functions of an expression, from `Expr::str`: `col("s").str()
/// .to_uppercase()`.
struct ExprStr {
  expr : Expr
}

///|
/// A string operation of one expression.
priv enum StrOp {
  /// `Contains(pattern, literal)`
  Contains(String, Bool)
  StartsWith(String)
  EndsWith(String)
  ToLowercase
  ToUppercase
  LenChars
  LenBytes
  /// `Replace(pattern, value, literal, all)`
  Replace(String, String, Bool, Bool)
  /// `Strip(characters, side)`
  Strip(String?, StripSide)
  /// `ToDate(strict)` and `ToDatetime(strict)` (`date_parse.mbt`)
  ToDate(Bool)
  ToDatetime(Bool)
}

///|
/// The call as polars prints it: `str.contains(["a"])`,
/// `str.replace(["a", "b"])`, `str.strip_chars([null])` (the `literal` flag
/// is not part of the text).
fn StrOp::text(self : StrOp) -> String {
  match self {
    Contains(p, _) => "str.contains([\"\{p}\"])"
    StartsWith(p) => "str.starts_with([\"\{p}\"])"
    EndsWith(p) => "str.ends_with([\"\{p}\"])"
    ToLowercase => "str.to_lowercase()"
    ToUppercase => "str.to_uppercase()"
    LenChars => "str.len_chars()"
    LenBytes => "str.len_bytes()"
    Replace(p, v, _, all) =>
      "str.\{if all { "replace_all" } else { "replace" }}([\"\{p}\", \"\{v}\"])"
    Strip(chars, side) => {
      let name = match side {
        Both => "strip_chars"
        Start => "strip_chars_start"
        End => "strip_chars_end"
      }
      match chars {
        Some(c) => "str.\{name}([\"\{c}\"])"
        None => "str.\{name}([null])"
      }
    }
    // polars prints both, strict or not, as `strptime` with the mode "raise"
    ToDate(_) | ToDatetime(_) => "str.strptime([\"raise\"])"
  }
}

///|
/// The operation on the evaluated input.
fn StrOp::apply(self : StrOp, s : Series) -> Series raise PolarsError {
  match self {
    Contains(pattern, literal) => str_contains(s, pattern, literal)
    StartsWith(prefix) => str_starts_with(s, prefix)
    EndsWith(suffix) => str_ends_with(s, suffix)
    ToLowercase => str_to_lowercase(s)
    ToUppercase => str_to_uppercase(s)
    LenChars => str_len_chars(s)
    LenBytes => str_len_bytes(s)
    Replace(pattern, value, literal, all) =>
      str_replace(s, pattern, value, literal, all)
    Strip(chars, side) => str_strip_chars(s, chars, side)
    ToDate(strict) => str_to_temporal(s, Date, strict)
    ToDatetime(strict) => str_to_temporal(s, Datetime, strict)
  }
}

///|
fn ExprStr::op(self : ExprStr, op : StrOp) -> Expr {
  Expr::of(ExprNode::Str(op, self.expr.node))
}

///|
/// The string functions of this expression (`col("s").str().contains("a")`).
/// Every function is an error on a column that is not a `String` (a `Null`
/// column included), raised when the expression is evaluated.
pub fn Expr::str(self : Expr) -> ExprStr {
  { expr: self, }
}

///|
/// A `Boolean` expression: whether each string matches the regular expression
/// `pattern` somewhere in it (anchor it with `^` and `$`), or, with `literal`,
/// whether it contains the text `pattern`. A null stays null. The regular
/// expression syntax is that of `@string.Regex`, a part of Rust's `regex`
/// (see docs/golden/known-diffs/regex.md). The common Rust idioms that it
/// rejects, and what to write instead: `\d` -> `[[:digit:]]`, `\s` ->
/// `[[:space:]]`, `\w` -> `[[:word:]]`, `(?i)x` -> `(?i:x)`.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::str("s", ["abc", "xyz"])])
///   let out = df.select([@pl.col("s").str().contains("^a")])
///   assert_eq(out.column("s").to_bool_array(), [Some(true), Some(false)])
/// }
/// ```
///
/// # Errors
/// Evaluating it raises `InvalidOperation` for a column that is not `String`
/// (`expected String type, got: i32`) and `ComputeError` for a pattern that
/// is not a valid regular expression (also when there is no row); the message
/// keeps the engine's hint: `regex error: regex parse error: "<pattern>":
/// <hint>`.
pub fn ExprStr::contains(
  self : ExprStr,
  pattern : String,
  literal~ : Bool = false,
) -> Expr {
  self.op(StrOp::Contains(pattern, literal))
}

///|
/// A `Boolean` expression: whether each string starts with `prefix` (text,
/// not a pattern). Errors as `ExprStr::contains`.
pub fn ExprStr::starts_with(self : ExprStr, prefix : String) -> Expr {
  self.op(StrOp::StartsWith(prefix))
}

///|
/// A `Boolean` expression: whether each string ends with `suffix` (text, not a
/// pattern). Errors as `ExprStr::contains`.
pub fn ExprStr::ends_with(self : ExprStr, suffix : String) -> Expr {
  self.op(StrOp::EndsWith(suffix))
}

///|
/// Every string in lower case, with Unicode case mapping (`İ` becomes `i`
/// and a combining dot above, a final `Σ` becomes `ς`).
///
/// # Errors
/// Evaluating it raises `SchemaMismatch` for a column that is not `String`
/// (``invalid series dtype: expected `String`, got `i32` for series with name
/// `a` ``).
pub fn ExprStr::to_lowercase(self : ExprStr) -> Expr {
  self.op(StrOp::ToLowercase)
}

///|
/// Every string in upper case (`ß` becomes `SS`). Errors as
/// `ExprStr::to_lowercase`.
pub fn ExprStr::to_uppercase(self : ExprStr) -> Expr {
  self.op(StrOp::ToUppercase)
}

///|
/// The number of Unicode code points of each string, as `Int64`. Errors as
/// `ExprStr::to_lowercase`.
pub fn ExprStr::len_chars(self : ExprStr) -> Expr {
  self.op(StrOp::LenChars)
}

///|
/// The number of UTF-8 bytes of each string, as `Int64`. Errors as
/// `ExprStr::to_lowercase`.
pub fn ExprStr::len_bytes(self : ExprStr) -> Expr {
  self.op(StrOp::LenBytes)
}

///|
/// Replaces the first match of the regular expression `pattern` (the text
/// `pattern` with `literal`) by `value`. In a regular expression `value` may
/// refer to groups: `$1`, `${name}`, `$0` for the whole match, and `$$` for a
/// dollar sign; with `literal` it is plain text. Errors as
/// `ExprStr::contains`.
pub fn ExprStr::replace(
  self : ExprStr,
  pattern : String,
  value : String,
  literal~ : Bool = false,
) -> Expr {
  self.op(StrOp::Replace(pattern, value, literal, false))
}

///|
/// Replaces every match; see `ExprStr::replace`.
pub fn ExprStr::replace_all(
  self : ExprStr,
  pattern : String,
  value : String,
  literal~ : Bool = false,
) -> Expr {
  self.op(StrOp::Replace(pattern, value, literal, true))
}

///|
/// Removes characters from both ends: the white space with `characters` left
/// out, otherwise every character that occurs in `characters` (a set, not a
/// prefix; the empty text removes nothing).
///
/// # Errors
/// Evaluating it raises `SchemaMismatch` for a column that is not `String`.
pub fn ExprStr::strip_chars(self : ExprStr, characters? : String) -> Expr {
  self.op(StrOp::Strip(characters, Both))
}

///|
/// Removes characters from the start only; see `ExprStr::strip_chars`.
pub fn ExprStr::strip_chars_start(self : ExprStr, characters? : String) -> Expr {
  self.op(StrOp::Strip(characters, Start))
}

///|
/// Removes characters from the end only; see `ExprStr::strip_chars`.
pub fn ExprStr::strip_chars_end(self : ExprStr, characters? : String) -> Expr {
  self.op(StrOp::Strip(characters, End))
}

///|
/// Reads each string as a `Date`, like polars' `str.to_date()` without a
/// `format`: polars finds the format itself, and so does this library, for the
/// ISO texts `YYYY-MM-DD` and `YYYY/MM/DD` (one or two digits for month and
/// day). An explicit format is not supported. A null stays null. With
/// `strict=false` a text that is not a date is null; with `strict=true` it is
/// an error. See `docs/golden/known-diffs/date_parse.md`.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::str("d", ["2024-01-15", "x"])])
///   let out = df.select([@pl.col("d").str().to_date(strict=false)])
///   assert_eq(out.column("d").to_list(), [
///     @pl.AnyValue::Date(19737),
///     @pl.AnyValue::Null,
///   ])
/// }
/// ```
///
/// # Errors
/// Evaluating it raises `SchemaMismatch` for a column that is not `String`
/// (as `ExprStr::to_lowercase`); with `strict=true` `InvalidOperation`
/// (`conversion from `str` to `date` failed in column 'd' for 1 out of 2
/// values: ["x"]`) for texts that are not dates; `ComputeError` (`could not
/// find an appropriate format to parse dates, please define a format`) when
/// no text in the column is a date (with `strict=false` too for a `Datetime`
/// but not for a `Date`, which then gives only nulls).
pub fn ExprStr::to_date(self : ExprStr, strict~ : Bool = true) -> Expr {
  self.op(StrOp::ToDate(strict))
}

///|
/// Reads each string as a `Datetime` in microseconds, like polars'
/// `str.to_datetime(time_unit="us")` without a `format`: a date alone
/// (midnight), or a date followed by `T` or a space and a time of day with an
/// optional fraction, then optionally a UTC offset (`Z`, `+02:00`), which
/// gives the UTC time (the library has no time zones, so the result is a plain
/// `Datetime`; polars gives `datetime[us, UTC]`). An explicit format is not
/// supported. Otherwise as `ExprStr::to_date`.
///
/// ```mbt check
/// test {
///   let df = @pl.DataFrame::new([@pl.Series::str("t", ["2024-01-15 10:20:30"])])
///   let out = df.select([@pl.col("t").str().to_datetime()])
///   assert_eq(out.column("t").to_list(), [
///     @pl.AnyValue::Datetime(1705314030000000L),
///   ])
/// }
/// ```
pub fn ExprStr::to_datetime(self : ExprStr, strict~ : Bool = true) -> Expr {
  self.op(StrOp::ToDatetime(strict))
}
