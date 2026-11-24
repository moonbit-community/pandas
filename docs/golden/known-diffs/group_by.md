# Known differences from polars: `group_by(...).agg(...)` and `pl.len()`

Compared with polars 2.1.0 on 814 cases (`docs/golden/group_by.json`, every one
with `maintain_order=True`) and the 269 cases of `docs/golden/group_final.json`
(date parsing per group, the kernels of a group with no key). What the data
looks like is described under "Notes on the golden data" at the end.

## What matches

- Keys of every type, several keys, expression keys (`col("a") % 2`,
  `col("s").str.len_chars()`), `all()` and `cols([...])` as keys, a literal key,
  and no key at all. Null is a key value of its own, all NaNs are one key, and
  `-0.0` equals `0.0` (the group shows the first one that appears). No key and
  a key that is one value (a literal, an aggregation, `len()`) make one group
  that is aggregated like a whole column (see "Float sums, means, variances:
  the order of addition").
- `str().to_date()` and `to_datetime()` inside an aggregation read the format
  of each group from the first value of that group (see "Dates are read per
  group").
- Every aggregation (`sum`, `mean`, `min`, `max`, `count`, `len`, `n_unique`,
  `first`, `last`, `median`, `product`, `std`, `var`, `quantile`) on every
  value type, with and without null, also on a frame without rows (the result
  has no rows and the types polars gives).
- Aggregations of row-by-row expressions (`(a * b).sum()`,
  `when(...).then(...).otherwise(...).sum()`, `a.fill_null(0).mean()`),
  operations on aggregations (`a.sum() / a.count()`, `a.max() - a.min()`),
  literals, `pl.len()`, `all().sum()` (which leaves the key columns out, as
  polars does: a key is called by its output name), aliases, and sequence
  operations on one value per group.
- The error that is raised when several things are wrong at once, in most
  combinations (see "Which error comes first").

## Groups come in first-appearance order, always

polars keeps the order of first appearance only with `maintain_order=True`. This
library does it always, and `group_by(..., maintain_order~)` is accepted for
compatibility only. The golden data is generated with `maintain_order=True`.

## No List type: restricted cases

polars returns a `list[...]` column for an aggregation expression that is not
one value per group (`col("b")`, `col("b").cum_sum()`, `col("b") + 1`,
`col("b") + col("b").sum()`, `col("b").is_in(...)`, `all()` without an
aggregation). This library has no List type and raises `InvalidOperation`:

    expression col("b") does not reduce each group to one value; this library
    has no List type, so aggregate it (for example with first(), sum() or len())

The decision depends on the shape of the expression only, never on the sizes of
the groups: `col("b")` is also refused when every group has a single row (it
is a list in polars too). These cases are `restricted` in the data: only
`InvalidOperation` and, for the cases marked `list`, the text above are
required. `is_in` is refused even on one value per group, because polars gives
a list there as well.

## The library is stricter, or raises where polars returns null

Marked `restricted` (only `InvalidOperation` is required):

- **The sum of a `Date` or `Datetime` column.** polars returns null for each
  group; the library raises `InvalidOperation`, as `select` does.
- **The quantile of `String`, `Boolean` and `Null` columns.** polars returns
  null for each group; the library raises `InvalidOperation` as in `select`.
- **Arithmetic on text.** `col("s") + 1` and the like fail in both, with a
  different message (polars reports the types of the operands in its own
  wording). Only the variant `InvalidOperation` is compared.

Not in the data, because polars gives nulls where the library raises:

- **A quantile outside `[0, 1]`** gives null in polars' `group_by`; the library
  raises `ComputeError` as `select` does (with the backquoted `quantile` text
  when the column has a null).
- **A negative `ddof`** fails in polars' Python layer before any evaluation;
  the library raises `InvalidOperation`.

## Float sums, means, variances: the order of addition

polars does not add up a group the way it adds up a whole column, and which
way it takes depends on the key.

**A key column (or an expression of columns).** The library follows polars'
grouped algorithms:

- `sum` of a float column: Kahan summation (a `Float32` column is summed in
  `Float32`). A sum that reaches an infinity, or overflows to one, stays
  `+inf` or `-inf` (`[1.0, inf, 2.0]` is `inf`); `[inf, -inf]` is NaN.
- `mean`: the Kahan sum over the number of non-null values, for float,
  integer, `Boolean`, `Date` and `Datetime` columns alike.
- `var` and `std`: Welford's online algorithm in double precision, for float,
  integer, `Boolean`, `Date` and `Datetime` columns alike; a `Float32` result
  is rounded once, at the end.
- A group of one row gives its value as it is (so a `-0.0` stays `-0.0`).
- An expression with aggregations inside it, such as `(a - a.mean()).sum()`,
  is aggregated like a whole column (the pairwise sum used by `select`), while
  the `mean` inside it is the group one.

**No key, or only keys that are one value** (a literal such as `lit(1)`,
`lit(1).cast(Int32)` or `lit("a")`, an aggregation such as `sum()`, `len()`).
The whole column is one group, and polars then uses the kernels of `select`
(the pairwise float sum, and the variance of `select`), not the grouped ones.
The library does the same: `group_by([])`, a key of this kind, and `over` with
partitions of this kind give exactly what `select` gives for the same
aggregation (a float `sum`, `mean`, `std` and `var`; also inside an expression
such as `(a - a.mean()).sum()`). A constant key *column* is a key column: it
takes the grouped algorithms above, as in polars. On 20 random floats with
nulls the two ways of adding often differ in the last digit (`20.610000000000003`
against `20.61`); the first digit that differs is
the 16th or 17th.

How well this matches polars 2.1.0 (random floats with nulls, compared bit for
bit):

- Key columns, `sum` and `mean`: groups of up to 32 rows match. From about 40
  rows the last digit differs in 40% to 90% of the groups, and at 2,000 rows or
  more nearly every group differs: polars adds long groups in another order
  than the Kahan sum the library uses. The library does not follow that. (The
  golden data of `window.json` and `group_by.json` has small groups, which is
  why it matches.) Key columns, `var` and `std`: exact at every size tried (2
  to 2,000 rows per group).
- No key, a one-value key, and `over` with a one-value partition: this is the
  whole-column kernel of `select`, the same one `select` uses. `sum` and `mean`
  match polars up to 1,000 rows (`group_final.json`, cases `kernel/...`, on
  1,000 rows); at 100,000 rows the `sum` of `group_by([])` and of a literal
  key differs in the last digit, as the `sum` of `select` does (`over(lit)` did
  not in the probe). `std` and `var`
  of this kernel differ from polars in the last digits at every size (also
  `select(v.std())`); the `group_final.json` cases for them hold only values
  on which the two agree. The library does not follow polars here.

polars does not guarantee any of this: its aggregation may change how it adds
up a group on another size or version, and then the last digits of a float
`sum`, `mean`, `var` or `std` can differ. The library is deterministic and does
not depend on the size of the frame.

Integer sums, `min`, `max`, `count`, `first`, `last`, `median`, `quantile`,
`product` and `n_unique` are exact.

The variance and standard deviation of an expression with aggregations inside
it (`(a - a.mean()).var()`), and `cum_sum` of a `Float32` column, inherit the
last-digit differences `select` has for those operations.

## Dates are read per group

`str().to_date()` and `to_datetime()` guess the format of a column from its
first non-null value (see `known-diffs/date_parse.md`). Inside `agg` (and in
`over`, see `known-diffs/window.md`) polars reads each group on its own, so the
first value of each group decides, not the first of the column; the library
does the same. A table whose groups use `2020-03-02`, `2020/04/05` and
`05.06.2020` is read with three formats; a group that holds an unreadable text
fails in strict mode and gives null in lenient mode. A strict failure inside a
group names the column as `''` (polars' series of a group has no name), as in
``conversion from `str` to `date` failed in column '' for 1 out of 2 values:
[...]``. With no key the whole column is the group and the error keeps the
column name. When several groups fail inside `over`, polars reports the failure
of one of them, and which one is not fixed; the library reports the first group
in the order of the groups (those cases are not in the golden data).

## Which error comes first

When several things are wrong in one call, polars raises one of them, and the
library tries to raise the same one. The order it follows:

1. a missing column in a key (and in the selectors of the aggregations);
2. two keys with the same output name;
3. an error found while the types are resolved, keys before aggregations and
   each in the order written: an aggregation a type does not have (`sum`,
   `mean`, `median`, `std`, `var`, `quantile` of text), `&` or `|` of an
   integer and a Boolean, arithmetic on a `Date` or `Datetime`;
4. a missing column in an aggregation;
5. the other errors of the aggregations, then of the keys, when the kernels
   run (a failed cast, arithmetic on text);
6. two output columns with the same name, then an expression that is a list.

For example `[(i32 & b).sum(), s.sum()]` raises the `&` error (`ComputeError`)
and `[s.sum(), (i32 & b).sum()]` the `sum` one; a key `i32 & b` is raised
before an aggregation of a missing column `zz`.

The library tells the errors of step 3 from those of step 5 by the text of the
error, and that is not exact. The known differences, all of which need two
mistakes in one call:

- **A kernel-time error of an aggregation that polars raises later than the
  library does.** `bool - bool` is raised by the library as it is found (step
  5, in the order written); polars raises it after a failed cast in another
  aggregation (`[(b - b).sum(), s.first().cast(Int64)]` gives the cast error in
  polars, the subtraction error here).
- **Arithmetic on text** (`s - s`, `s * s`, `s + 1`) is refused by the library
  as soon as it is evaluated, as in `select`; polars finds a type for the
  expression and reports the aggregation applied to it instead (`[(s + 1).sum(),
  (i32 & b).sum()]` gives the `sum` error in polars, the `&` error here).
- **Other type errors.** An error that polars finds while it resolves types
  and that the library does not recognise by its text is treated as a
  kernel-time one, and so is reported after the type errors of later
  expressions. `product` of text and `|` of a float and an integer are
  kernel-time errors in polars too, and the library treats them so.

The count in the message of a failed cast inside an expression that is
aggregated again (`(a.first().cast(Int64) * b).sum()`, or
`(s.cast(Int64) + len()).sum()`) counts the values of one group, where polars
counts the values of all groups together.

On a frame without rows, `when(...).then(a.sum()).otherwise(0).sum()` gives
an `Int32` column in the library where polars gives a `Null` column.

## The sign of zero

Numerically equal zeros can differ in sign in three cases of a `group_by`
aggregation; the values compare equal, only the printed `-0.0` against `0.0`
and `1 / x` can tell them apart:

- **`unique().sum()` of a group whose only value is `-0.0`** gives `+0.0` in
  the library and `-0.0` in polars (`sort().sum()` the same way). `col("x").sum()`
  on that group gives `-0.0` in both.
- **`min()` of a group that holds both `+0.0` and `-0.0`**: the zero that comes
  out can have the other sign than polars gives.
- **An aggregation of an aggregate (or of a reordered column) over a group
  whose only value is `-0.0`**: `f.mean().mean()`, `f.mean().sum()` and
  `f.reverse().sum()` give `-0.0` in polars and `+0.0` in the library. The
  inner aggregate is one value per group, and the library adds it up like a
  whole column, starting from `+0.0`, which loses the sign; polars returns the
  value as it is. `with_columns(...over("k"))` shows the same for the `sum` and
  `reverse().sum()` forms. `select` gives `0.0` in both. Nothing else changes
  (about 40 sign-only differences in 20,000 random pipelines), and nothing is
  planned for it.

## A frame without rows and the empty group

With no key, a frame without rows is one group without rows (`sum` is 0,
`mean` is null, `len` is 0), as in polars. A one-row key (a literal) on a
frame without rows is also one group without rows. With a column key there are
no groups at all and the result has no rows.

## Weak literals

`pl.lit(1)` in a `group_by` is an `Int32` in polars; here a lone integer
literal is an `Int64` (see `known-diffs/expr.md`). The cases where only that
type differs are marked `known_diff: "dyn-literal-default"` and carry the
library's result (18 cases). A literal that meets a column or a typed literal
takes its type, as in polars.

## Notes on the golden data

- `group_by.json` is written by `scripts/group_by.py`, `group_final.json` by
  `scripts/group_final.py`, both with polars 2.1.0. The format is that of
  `expr.json` (see `known-diffs/expr.md`): a case has the tables it runs on,
  the key expressions, the aggregation expressions (or `how = "len"` for
  `GroupBy::len`), and one of `result`, `error` + `message`, or `restricted`.
  `group_final.json` also has cases whose `op` is `select` or `with_columns`
  (the `over` and `select` side of the same checks).
- Every case also records the polars spelling and `str()` of each expression;
  the tests compare `to_string()` of each key and aggregation with it.
- `known_diff` marks a case whose `result` is the library's and not polars'
  (the weak literals above: 18 cases of `group_by.json`, and 14 cases of
  `group_final.json` whose key is the literal `lit(1)`).
- The data is generated with `maintain_order=True`.
- The generated `.mbt` case files (`src/pl/group_by_cases_test.mbt`,
  `src/pl/group_final_cases_test.mbt`) and the embedded data are committed after
  `moon fmt`; see `docs/golden/README.md` for how to reproduce them.
