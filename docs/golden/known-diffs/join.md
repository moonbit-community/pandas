# `join`: differences from polars 2.1.0

`DataFrame::join` follows `polars.DataFrame.join`. It was compared with polars
2.1.0 on 793 cases (every `how`, key types, null and float keys, column names,
expression keys, argument errors, `validate`, empty sides, the order of the
errors); see "Notes on the golden data" at the end.

## Row order

- polars has `maintain_order` (default `"none"`, where the order of the rows is
  not defined). The library has no such argument: the order is always
  `left_right` (for `how=Right`: `right_left`), which polars gives with
  `maintain_order="left_right"` / `"right_left"`. The comparison data is
  generated with these values.
- `Full`: the rows that have a left row first (in the order of the left
  frame), then the right rows that matched nothing, in the order of the right
  frame.
- `Semi` and `Anti` keep the left frame's order.

## Arguments that do not exist

- `maintain_order`, `join_nulls` (use `nulls_equal`), `left_on`/`right_on`
  given as plain strings (keys are `Expr` values: `col("a")`).
- `how` has the seven values `Inner`, `Left`, `Right`, `Full`, `Semi`, `Anti`,
  `Cross`. polars' `"outer"` spelling is `Full`.
- `validate` is an enum (`ManyToMany`, `OneToMany`, `ManyToOne`, `OneToOne`)
  instead of the strings `"m:m"`, `"1:m"`, `"m:1"`, `"1:1"`. A validation other
  than `ManyToMany` on a `Right`, `Semi` or `Anti` join is an error, as in
  polars.

## Keys

- A key is an `Expr` and must not contain `alias`, a sequence-dependent
  operation (`cum_sum`, `shift`, `diff`, ...) or `str().to_date()` /
  `to_datetime()` (the format is guessed from the first value, so a value
  depends on the others); all are errors as in polars. The type of a date key is
  `Date` (`Datetime` for `to_datetime`), so it is compared with the other side
  first: against an `Int64` key the error is the `SchemaMismatch`, against a
  `Date` key it is the "must be elementwise" `InvalidOperation`.
  Aggregations (`sum`, `len`, ...) are accepted and broadcast to every row,
  as in polars.
- The type of a key is found by evaluating the expression on a frame with no
  rows. Both sides then need a common type: the same type, `Int32` with
  `Int64` (compared as `Int64`), or `Float32` with `Float64` (compared as
  `Float64`). Every other pair (a number with a date, text with a number, a
  `Null` key with a typed one, an integer with a float) is a `SchemaMismatch`
  with polars' text.
- A key that is not elementwise is refused after the key types are compared,
  as in polars: the type of `col("s").cum_sum()` is `Int64` for a text column
  (`Date` for a date column), so against a text key the error is a
  `SchemaMismatch`, and against an `Int64` key it is the "must be elementwise"
  `InvalidOperation`. This holds for the cumulative sum and product and for
  `rank`; any other sequence operation that refuses the type of its input is
  compared by the input's type, and a refusing operation nested deeper in a key
  is not compared at all.
- Floating point keys: `NaN` equals `NaN`, `-0.0` equals `0.0`. `null` never
  matches `null` unless `nulls_equal=true`.
- Strings are compared by their code points (the same as a byte comparison of
  the UTF-8 text).

## Differences

- **Text of an arithmetic error in a key.** polars resolves the type of a key
  such as `col("d") + 1` (a `Date` plus an integer literal) without making the
  literal a column and reports `+ not allowed on date and dyn int`. The library
  makes the literal an `Int32` first and reports
  ``add operation not supported for dtypes `date` and `i32` ``. The error is
  the same variant (`InvalidOperation`) and comes at the same place in the
  order of the errors; only the text differs. The comparison cases carry
  `message_differs` and only the variant is compared.
- **Arithmetic on a `String` key** (`col("b") + 1`): polars reports `arithmetic
  on dtypes str and dyn int is not allowed (...)`, the library reports
  `InvalidOperation` with its own text. The cases are marked `restricted`: the
  test checks for `InvalidOperation` only.
- **Full join, `coalesce=true`, one right column used for two keys**
  (`left_on=[a, x]`, `right_on=[y, y]`): polars drops a second column of the
  right frame as well (a polars quirk, the column that follows the repeated
  key); the library drops only the key column `y` and keeps every other right
  column. The library keeps the unrelated column because the result of a join
  should not lose data that no key refers to. The case is not in the
  comparison data; a hand-written test pins the library's result.
- **The size of the result.** The number of result rows must fit in `Int32`.
  A `Cross` join pairs every left row with every right row; for `Inner`,
  `Left`, `Right` and `Full` the library counts the rows from the sizes of the
  key groups before it builds anything. A `ComputeError` is raised when the
  count is more than 2147483647 (`the inner join would have more than
  2147483647 rows (2500000000 rows)`; two frames of 50,000 rows on one constant
  key). `Semi` and `Anti` never multiply rows. polars has no such limit below
  `2^32` rows.
- **A key whose root is an aggregation of a non-row-wise expression.** polars
  accepts a key such as `col("a").sort().sum()` or `col("a").cum_sum().sum()`:
  the aggregation reduces the column to one value, which is repeated on every
  row. The library looks for a sequence or reshaping operation (`cum_sum`,
  `shift`, `sort`, `head`, `unique`, `filter`, `over`, ...) anywhere inside the
  key, also below an aggregation, and raises `InvalidOperation: all join key
  expressions must be elementwise.` Aggregate a plain column (`col("a").sum()`
  is accepted), or compute the key with `with_columns` before the join.

## Names of the output columns

A right column whose name the left frame has gets `suffix` (default
`_right`). The errors when the new name cannot be used follow polars: the new
name is a left column name: `column with name 'b_right' already exists`; the new
name is another right column (or, with an empty `suffix`, the column itself):
`column 'b_right' is duplicate`.

With `coalesce` unset: `Inner` and `Left` merge each pair of key columns into
one (the left column, with the left name), `Right` merges them into the right
column (right name, placed after the left frame's other columns), `Full` keeps
both (`a` and `a_right`). `coalesce=true` makes `Full` merge them too;
`coalesce=false` keeps both columns in every one of the four. `Semi`, `Anti`
and `Cross` ignore `coalesce`. A key that is not a plain column
(`col("a") % 10`) is never merged: both sides keep their columns.

## Notes on the golden data

- `docs/golden/join.json` (793 cases) is written by
  `docs/golden/scripts/join.py` with polars 2.1.0; the key expressions of each
  case are built in `src/pl/join_golden_test.mbt` from the case id.
- The data is generated with `maintain_order="left_right"` (`"right_left"` for
  `how=Right`), the order the library always gives.
- `message_differs` marks a case where only the variant of the error is
  compared; `restricted` marks a case where the library is stricter and only
  `InvalidOperation` is required.
- The embedded data (`src/pl/golden_join_data_test.mbt`) is committed after `moon fmt`; see
  `docs/golden/README.md`.
