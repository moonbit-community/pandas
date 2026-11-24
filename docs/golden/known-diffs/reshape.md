# Known differences from polars: counting and reshaping

Compared with polars 2.1.0 on 715 cases (`docs/golden/reshape.json`). Covered:
`Series.value_counts`, `Series.unique_counts`, `DataFrame.pivot`, `unpivot`,
`transpose` and `to_dict`, on all nine types, with nulls, NaN, `-0.0`, repeated
values and frames without rows or columns. What the data looks like is
described under "Notes on the golden data" at the end.

## What matches

- `value_counts` and `unique_counts`: the values and counts, `normalize`,
  `name`, the `DuplicateColumn` error for a `name` equal to the series name,
  and `Null`, NaN (one value), `-0.0` (equal to `0.0`; the first one that
  appears is shown) as values. Counts are `Int64`, proportions `Float64`.
- `pivot`: output rows and columns in order of first appearance, `sort_columns`
  (sorted by the `on` value, nulls first, NaN last), `separator`, several
  `index`, `on` and `values` columns, the names of the new columns (the value
  as text, `null` for a null value, `{1,"a"}` for several `on` columns), cells
  that no row lands in (0 for `Sum` and `Len`, null for the others), the types
  each `PivotAgg` gives for each value type, a frame without rows, and the
  errors (empty or unknown columns, a cell with several rows and no
  `aggregate_function`, names that clash).
- `unpivot`: `on` and `index` defaults, the common type of the unpivoted
  columns (also when it is `String`, `Null` or has no answer), repeated names,
  and the name clash errors.
- `transpose`: the common type, `include_header`, `header_name`,
  `column_names`, and the errors.
- `to_dict`: the columns by name, in column order.

## Order of `value_counts` and `unique_counts`

polars promises no order (the order differs between runs and between
`sort=True` ties). This library always lists values in order of first
appearance; with `sort=True` the biggest count comes first and values with the
same count stay in order of first appearance. The golden cases are written in
that order (the script checks that polars returned the same values and
counts, and counts that are not increasing for `sort=True`).

## `value_counts(name="")`

polars treats an empty `name` as not given and uses `count` (or `proportion`).
So does this library.

## Several cells with several rows: which one is named

`pivot` without `aggregate_function` raises `ComputeError` ("aggregation 'item'
expected no or a single value, got N values") when a cell gets more than one
row. When several cells do, polars names the size of one of them and which one
changes from run to run. This library names the cell whose first row comes
first in the frame. The golden cases have one size of offending cell only.

## Not supported

- `pivot`: `aggregate_function` is an enum (`PivotAgg`): `First`, `Last`, `Sum`,
  `Min`, `Max`, `Mean`, `Median`, `Len`. polars also takes `"item"` (an error
  for a cell without a row), `"count"` (deprecated, an error there) and an
  expression. `on`, `index` and `values` are lists of column names; selectors
  and expressions are not accepted. There is no `maintain_order` (the order is
  always the first-appearance order, polars' default), `on_columns` or
  `column_naming`.
- `unpivot` and `transpose`: names only, no selectors. `transpose` takes
  `column_names` as an array of names; polars also takes the name of a
  `String` column and an iterator, and replaces a `null` in the list by
  `column_<i>`.
- `to_dict`: always the series (`as_series=False`: use `Series::to_list`).
- `value_counts`: no `parallel` argument.

## `sum` of `Date` and `Datetime` (restricted cases)

`pivot(..., aggregate_function=Sum)` on a `Date` or `Datetime` column raises
`InvalidOperation`, as `group_by(...).agg(col.sum())` and `Series::sum` do;
polars returns a column of the same type whose cells are all null (the sum of
dates is not defined there either, but it does not raise). The cases are
`restricted`. The other
aggregations of those types (including `Mean` and `Median`, which give
`Datetime`) match.

## `transpose` of a frame without rows

For a table with `n` columns and no rows, polars returns a frame with no
columns that still has `n` rows (shape `(n, 0)`). A frame of this library that
has no columns always has height 0 (its height comes from its columns), so
the result has shape `(0, 0)`. With `include_header=true` the result is the
header column and matches polars. The case `transpose/e0/column-names` is a
`known_diff`.

## An empty-string `on` value

A `pivot` whose `on` column has the empty string as a value names that column
`""`, and the column of the null value `null`, in this library and in polars
(`k=[1,1,2,2]`, `s=["","a","",null]` gives `k, "", a, null`). Building a
`pl.DataFrame` from a series with an empty name renames it `column_N` in
Python, which is not something `pivot` does; this library's `DataFrame::new`
keeps empty names, as everywhere. A hand-written test pins the names.

## The size of the result

`unpivot` makes `height x number of columns` rows and `transpose` makes
`height x number of columns` cells; as for `pivot` and `Cross` joins the count
must fit in `Int32`, and a `ComputeError` is raised before anything is built
when it does not (`the unpivot would have more than 2147483647 rows (50000 x
50000)`, `the transpose would have more than 2147483647 cells (50000 x 50000)`;
a frame of 50,000 rows with 50,000 columns that share one buffer is enough).
polars has no such limit below `2^32` rows.

## Float sums

The sums and means of floats in `pivot` are those of `group_by` (see
`known-diffs/group_by.md`): bit for bit with polars in the golden cases (small
groups), but the last digits can differ for groups of about 40 rows or more
and for the sums of a whole column; see there for the sizes.

## Notes on the golden data

- `docs/golden/reshape.json` (715 cases) is written by `scripts/reshape.py`
  with polars 2.1.0. A case is `{id, op, table, args, polars, ...}` plus one of
  `result`, `error` + `message` or `restricted`; `known_diff` marks a case
  whose `result` is the library's and not polars' (one case,
  `transpose/e0/column-names`). The message of every error case is polars'
  text.
- The embedded data (`src/pl/golden_reshape_data_test.mbt`) is committed after
  `moon fmt`; see `docs/golden/README.md`.
