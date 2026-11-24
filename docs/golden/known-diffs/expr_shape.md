# Known differences from polars: sorting, cutting, filtering, trigonometry and horizontal functions

Compared with polars 2.1.0 on 1021 expression cases, 341 `Series` cases and 15
`DataFrame` cases (`docs/golden/expr_shape.json`). The layout of the data is
described under "Notes on the golden data" at the end.

Types follow the usual mapping: polars' `UInt32` (the result of `arg_sort`) is `Int64` here.

## Numeric results

| Case | polars | This library |
| --- | --- | --- |
| `sin`, `cos`, `tan`, `arcsin`, `arccos`, `arctan` | the C math library | the library's own routines. A few values differ from polars in the last bit; no value in the golden data differs by more than one unit in the last place (on any backend), and `Float32` `tan` is computed in double precision and rounded once, which brought the values that were two units off in a bulk comparison back into line. The library does not promise a tighter bound than that. The golden test compares trigonometric cases with a tolerance of one unit (cases and series cases carry `ulp: true`); NaN, infinities and the sign of zero must match exactly. |

## Literals

| Case | polars | This library |
| --- | --- | --- |
| An integer literal (`lit_int`) that nothing gives a type to: on its own, or next to another literal, as the input of `sort`, `head`, `unique`, `drop_nulls`, `filter`, `sort_by`, or in `sum_horizontal` / `min_horizontal` / `max_horizontal` with only literals | `Int32` when the value fits | `Int64` (a lone integer literal is `Int64`, a lone float literal `Float64`). 21 cases carry `known_diff: "dyn-literal-default"`; `result` is the library's and polars' dtype is in `polars_schema`. |
| A literal next to columns in a horizontal function | takes the type of the other inputs | same; with three or more inputs it takes the common type of all the column inputs, which is the same thing polars arrives at for every case in the data. A literal next to a `Date` or `Datetime` input is an error in both (`got invalid or ambiguous dtypes: '[date, dyn int]'`). |

## Errors that polars raises while it builds the expression

Python raises these before any frame is looked at. Building an `Expr` cannot fail here, so the same error comes out when the expression is expanded or evaluated (`select` / `with_columns`); the cases carry `build_error: true`, and there is no `str(expr)` to compare.

- `sum_horizontal([])` and the other two horizontal functions with no input: `ComputeError: cannot return empty fold because the number of output rows is unknown`.
- `sort_by` with a `descending` list that does not have one flag per key: `InvalidOperation: the length of \`descending\` (1) does not match the length of \`by\` (2)`.
- `head` and `tail` with a negative `n`, `slice` with a negative length: polars reports an internal message that quotes the literal it built (`unable to extract length from Scalar(...)`), and the library repeats it. `Series::head` and `Series::tail` accept a negative `n` (all but the last rows); the expression methods do not.

## Shape rules that are easy to trip over (same in both)

- `head`, `tail`, `slice`, `unique`, `drop_nulls`, `filter` give a column, not a scalar, even when it has one row. Next to longer results in `select` that is a `ShapeMismatch` (`Series x, length 1 doesn't match the DataFrame height of 5`), and in `with_columns` an `InvalidOperation` with the same text. Only literals and aggregations (and `any` / `all`, except as the subject of `filter`, see below) are repeated, and so is no column of the frame that happens to have one row: in `select([a.head(0), k])` on a one-row frame `k` is a `ShapeMismatch` against height 0, as is a cut to one row next to an empty result. `sort` and `arg_sort` keep the kind of their input.
- A selector in `sort_by(by=...)` makes one output per selected column, each sorted by one key (so `col("x").sort_by([cols(["a", "b"])])` gives two columns called `x`, a `DuplicateColumn` error). A selector inside a horizontal function does not: its columns are inputs of one output.
- In horizontal functions the first input that is not one row long sets the length; every later one that is neither one row nor that length is a `ShapeMismatch` (`can't compute broadcast length, found incompatible lengths 3 (column 'b') and 2 (column 'a')`).

## `filter` and `sort_by` with one-row operands

- A subject that is an aggregate or a literal meets a predicate of any other length by being repeated, also to no row (`col("a").sum().filter(col("b"))` on a frame without rows is an empty column). `any` and `all` are not repeated there: `col("a").any().filter(col("b"))` is `ShapeMismatch: filter's length: 5 differs from that of the series: 1`.
- A `sort_by` key that is a literal or an aggregate orders nothing, but a column cut to one row (`col("k").head(1)`) next to a longer subject is `ShapeMismatch: `sort_by` produced different length (1) than the Series that has to be sorted (5)`.
- With several keys a one-row key that is not a scalar next to a longer key is `ShapeMismatch: non-scalar expression produces broadcasting column`; literal and aggregate keys stretch.

## Three results of three different lengths: the text names a column

When the results of a `select` have three different lengths (for example a
column cut to one row, one cut to two rows and a full column), both polars and
the library raise `ShapeMismatch`, but the texts differ. The library says which
column it means: ``Series x, length 1 doesn't match the DataFrame height of 5``.
polars does not name it: ``Series length N doesn't match the DataFrame height
of M``. Match on the variant, not on the text.

## Order

- `unique()` without `maintain_order` gives no order in polars. This library always gives the values in order of first appearance, but only `maintain_order=true` promises it. The golden data uses `maintain_order=True`, or sorts the result of an unordered `unique()`.

## Horizontal functions: the rules the data pins

- `sum_horizontal` counts nulls as zero (empty text for text) unless `ignore_nulls=false`; the result type is the common type of the inputs. A number next to text gives text (`"1a"`); `Boolean` sums to `Int64`; a `Date` or `Datetime` input is only accepted alone (two or more is `InvalidOperation: add operation not supported for dtypes \`date\` and \`date\``).
- `min_horizontal` and `max_horizontal` skip nulls and treat NaN as "no value" (a NaN loses against any number; two NaN give NaN). When two values compare equal the later input wins (`-0.0` against `0.0`). Text next to anything but text or null is `InvalidOperation: got invalid or ambiguous dtypes: '[i64, str]' in expression 'min_horizontal'`.
- Types without a common type are `SchemaMismatch` (`failed to determine supertype of bool and date`).
- The output name is the name of the first input.
- A selector that expands to no column is `InvalidOperation: expected at least 1 input in null.sum_horizontal()`.

## `any` and `all`

- On an expression, a number counts as `value != 0` (NaN is true); `Boolean` and `Null` columns work as usual; text is `InvalidOperation: casting from Utf8View to Boolean not supported`, `Date` and `Datetime` are `InvalidOperation: expected boolean input for 'any_ignore_nulls()' (got date)`. `Series::any` and `Series::all` accept only `Boolean` (`SchemaMismatch`, as polars does).
- With `ignore_nulls=false` the result follows Kleene logic and can be null.
- An empty `String` column gives `false` for `any` and `true` for `all` (nothing is cast); a non-empty one is the error above.

## `fill_null` of columns of different lengths

`col("a").head(5).fill_null(col("b"))` on a 10-row frame is a `ShapeMismatch` with polars' text `arguments for \`fill_null\` have different lengths (5 != 10)`. (The other operators keep their own text, `cannot evaluate two Series of different lengths`.)

## Notes on the golden data

Data: `docs/golden/expr_shape.json` (written by `scripts/expr_shape.py`, polars 2.1.0). The file has the layout `{"tables", "inputs", "cases", "series_cases", "frame_cases"}`:

- `cases` are expression cases (`select`, or `with_columns` when `op` says so). The expressions are built in `src/pl/expr_shape_cases_test.mbt` from the case id, and the `to_string()` of every expression must equal polars' `str(expr)`. The fields `result`, `error` + `message`, `known_diff` and `build_error` mean what they mean in `expr.md` and `expr_seq.md`.
- `series_cases` call a `Series` method (`is_sorted`, `any`, `all`, `gather_every`, the trigonometric methods) on a series from the top-level `inputs`.
- `frame_cases` are `df.gather_every(n, offset)` calls.
- The generated `.mbt` case files (`src/pl/expr_shape_cases_test.mbt`) and the embedded data are committed after `moon fmt`; see `docs/golden/README.md`.
