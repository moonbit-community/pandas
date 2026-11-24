# Known differences from polars: `Expr::over` and expression methods inside `group_by(...).agg(...)`

Compared with polars 2.1.0 on 574 cases of `over` (`docs/golden/window.json`)
and 757 cases of expression methods inside `group_by(...).agg(...)`
(`docs/golden/group_by_ext.json`). What the data looks like is described under
"Notes on the golden data" at the end.

## What matches

- Aggregations over a partition (`sum`, `mean`, `min`, `max`, `count`, `len`,
  `n_unique`, `first`, `last`, `median`, `product`, `std`, `var`, `quantile`) on
  every value type, `len()` and literals, repeated on every row of the
  partition; also on a frame without rows (the result has no rows and the type
  polars gives).
- Sequence operations (`cum_sum`, `cum_min`, `cum_max`, `cum_prod`, `cum_count`,
  `shift`, `diff`, `rank`, `reverse`, `fill_null` with a strategy), `sort`,
  `arg_sort` and `sort_by` see the rows of the partition in their order.
- Expressions that work row by row, and expressions that mix rows and
  aggregations (`(x - x.mean()).over(...)`, `when(x > x.mean())...`,
  `x.fill_null(x.mean())`, `sum_horizontal(x, x.sum())`).
- The length rule: a partition whose result is not as long as the partition is
  a `ShapeMismatch` (`head(1)`, `tail`, `slice`, `unique`, `drop_nulls`,
  `filter` that drops rows), also when only some partitions have such a result;
  a result as long as the partition (`head(100)`, a `filter` that keeps every
  row) is accepted.
- Partition keys: every value type, several keys, expression keys, a literal or
  an aggregate (one partition, aggregated like a whole column, see "Float
  results"), a key of one row (repeated), a key of another
  length (`ShapeMismatch`), selectors (they pair up like the operands of an
  operator). Null is a partition of its own, all NaNs are one partition and
  `-0.0` equals `0.0`.
- A window inside a window is partitioned by both keys; a window as the sort key
  or predicate of a frame; an empty list of keys is a `ComputeError` on a frame
  with rows and no error on a frame without rows.
- In `group_by(...).agg(...)`: `filter`, `sort_by`, `sort`, `unique`, `head`,
  `tail`, `slice`, `drop_nulls`, `arg_sort` under an aggregation (`b.filter(c >
  0).sum()`, `b.sort_by(c).last()`, `b.sort().first()`, `b.unique().len()`,
  `b.head(2).sum()`), `any` and `all`, the horizontal functions of aggregations
  (`sum_horizontal(a.sum(), b.sum())`), and `over` inside an aggregation
  (`b.sum().over(c).first()`: the window is the group).

## Only `partition_by`

`Expr::over(partition_by)` has no `order_by` and no `mapping_strategy`: the
result always has one value per row of the frame (polars' default,
`group_to_rows`). The strategies `join` (a list per row) and `explode` need a
List type, which this library does not have.

## No List type: restricted cases

As for `group_by` (see `known-diffs/group_by.md`), an aggregation expression that
polars turns into a `list[...]` per group raises `InvalidOperation` here with
the fixed text `expression ... does not reduce each group to one value; ...`.
That covers `head`, `tail`, `slice`, `unique`, `drop_nulls`, `filter`, `sort`,
`arg_sort`, `sort_by` on a column, `sum_horizontal(a, b)` of columns, and a
window on its own (`b.sum().over(c)`), as well as expressions built on them
(`b.sort() + 1`). An aggregation of such an expression is one value per group
and works (`b.sort().first()`, `b.head(2).sum()`, `b.sum().over(c).first()`).
The decision depends on the shape of the expression, not on the size of the
groups.

## `over` inside `agg`: the partition must be elementwise

`b.sum().over(c).first()` inside `agg` is accepted when the partition `c` is
elementwise (a column, a literal, arithmetic, `str().to_uppercase()`, `is_in`).
A partition that is not is refused, as in polars, before anything is run:
`InvalidOperation: window expression with non-elementwise `partition_by` or
`order_by` not allowed in aggregation context`. Not elementwise: `str().to_date()`
and `to_datetime()` (the format is guessed from the first value), a sequence
operation (`cum_sum`, `rank`, `reverse`, ...), `sort`, `head`, `unique`,
`filter`, `sort_by`, an aggregation, `n_unique`, `len()`, `any`/`all`, and a
nested `over`; they count anywhere inside the partition expression. The check
comes after the missing-column and duplicate-name errors and before the
list-expression error. A plain `select` or `with_columns` accepts them (a
`to_date` partition is read with one format for the whole column).

## `over` and `str().to_date()` / `to_datetime()`

In a window the format of `to_date` / `to_datetime` is guessed per partition,
from the first value of the partition, as in polars (see
`known-diffs/group_by.md`, "Dates are read per group"). The same holds when
the parsed value is the partition key itself: the key is read with one format
for the whole column.

## `sort_by` of a scalar in a group of one row

In `agg`, `b.sum().sort_by(c)` by a key of several values per group is a
`ShapeMismatch`; in a group of one row the key has one value, as long as the
aggregate, and both polars and the library accept it (`lit(0.5).sort_by(w).count()`
on a group of one row is 1). A frame with groups of one and of several rows
fails as a whole.

## Weak literals

`lit_int(1).over([...])`, `lit_float(1.5).over([...])` and a weak literal inside
an aggregation are `Int64` / `Float64` as everywhere in this library, where
polars uses `Int32` for an integer that fits. The cases carry `known_diff:
"dyn-literal-default"`; the result is the library's and the polars type is in
`polars_schema` (8 cases of `window.json`, 5 of `group_by_ext.json`).

## Cases where the library is stricter (`restricted`)

- `sum` of a `Date` or `Datetime` column, `quantile` of text, Boolean and `Null`
  columns: polars gives null (or the input type), the library raises
  `InvalidOperation` as in `select`.
- `diff` of a `Date` column: polars gives a `Duration`, which the library does
  not have; the library raises `InvalidOperation`.
- A partition key whose types do not combine (`k + s`, arithmetic on text): the
  library raises `InvalidOperation`; only that variant is checked.

## Differences in the text of an error

The variant is the same, the text differs.

- `with_columns` with two windows of one output name: polars raises
  `ComputeError`, the library `DuplicateColumn` (same text, as for any
  `with_columns`).
- `b.sum().sort_by(c)` (an aggregate sorted by a column) inside `agg`, on a
  group of several rows: both raise `ShapeMismatch` (polars: `ShapeError`), but
  the texts differ. The library says `expressions in 'sort_by' must have
  matching group lengths`; polars says `` `sort_by` produced different length
  (2) than the Series that has to be sorted (1)`` (with the group's own
  numbers).
- `b.filter(p1).filter(p2)` inside `agg`, where `p2` reads a column of the
  whole group: both raise `ShapeMismatch` (a predicate must be as long as the
  filtered column in both); polars says `arguments for `filter` have different
  lengths (4 != 6)`, the library `filter's length: 6 differs from that of the
  series: 4`.

## Float results

Aggregations in a window over a key column use the same algorithms as
`group_by` (Kahan summation for a float sum and mean, Welford for variance).
Against polars, `sum` and `mean` match bit for bit for partitions of up to 32
rows; from about 40 rows the last digit differs in many partitions, and at
2,000 rows or more in nearly all (the golden data has small partitions); `var`
and `std` were exact at every size tried. See `known-diffs/group_by.md`.
A partition that is one value (a literal such as `lit(1)`, an aggregation,
`len()`) is the whole column, and polars then uses the kernels of `select`
(pairwise float sums); so does the library, and the results are those of
`select`. They match polars for `sum` and `mean` up to 1,000 rows
(`docs/golden/group_final.json`, cases `kernel/over/...`); `std` and `var` of
that kernel differ from polars in the last digits at every size, also in
`select` (see `known-diffs/group_by.md`). A constant key *column* is a key
column and takes the group kernels. A float column divided by an aggregate of
the
same window (`(x / x.sum()).over(k)`) is multiplied by the reciprocal of the
aggregate, as polars does (it can differ from the plain quotient in the last
digit); `x / x.sum().over(k)` divides plainly, in polars and here.

`//` and `%` by an aggregate do the same (the quotient of a float column by an
aggregate is `floor(x * (1 / s))`, and `x % s` likewise). A division of
two aggregates is a plain quotient of two scalars, also when a column
multiplies it next (`(x.max() / x.sum() * x).last()`). The cases `dv/...` (window) and `div/...` (group_by) of
both data files (random expressions with aggregated, column and mixed
divisors, `Float64`, `Float32` and `Int64`) pin this.

A `Float32` `cum_sum` can differ from polars in the last digits, as in `select`
(see `known-diffs/group_by.md`); the window cases use `Float64` for it.

## Cost

A window that gives one value per partition costs what the same aggregation
costs in a `group_by` (the rows are hashed once). A sequence operation, `sort`
and the like are evaluated partition by partition: linear in the number of rows
plus a constant per partition (1 000 000 rows, native release build:
`cum_sum` over 1 000 partitions 41 ms, over 500 000 partitions 750 ms).

## Notes on the golden data

- `docs/golden/window.json` (574 cases, `scripts/window.py`) and
  `docs/golden/group_by_ext.json` (757 cases, `scripts/group_by_ext.py`) were
  generated with polars 2.1.0. The formats are those of `expr.json` and
  `group_by.json` (see `known-diffs/expr.md` and `known-diffs/group_by.md`): a
  case has the table it runs on, the expressions, and one of `result`,
  `error` + `message`, or `restricted`.
- Every case records the polars spelling and `str()` of each expression.
  `known_diff` marks a case whose `result` is the library's and not polars'
  (8 cases of `window.json`, 5 of `group_by_ext.json`).
- A window case runs `select`, `with_columns`, `DataFrame::filter` (a window as
  the predicate) or `DataFrame::sort` (a window as a sort key, with an `id`
  column to break ties).
- The per-partition date reading and the kernels of a partition that is one
  value are in `docs/golden/group_final.json` (`scripts/group_final.py`).
- The generated `.mbt` case files and the embedded data are committed after
  `moon fmt`; see `docs/golden/README.md`.
