# `smallbearrr/pandas/pl`

A polars-style data layer for MoonBit: typed, nullable, immutable columns
(`Series`) grouped into a `DataFrame`, plus expressions (`Expr`) to describe
what to compute and eager operations that run them: `select`,
`with_columns`, `filter`, `sort`, aggregation, `group_by`, `join`, window
expressions (`over`), `pivot` and `unpivot`, `unique`, `concat`, `describe`,
`cast`, printing, and CSV reading and writing.

Every fallible call raises `PolarsError` (the file functions of `@plfs` also pass
on file system errors through); nothing aborts on bad user input.
Coming from the old `lib/pandas` package? See `docs/migration.md`. Not here
yet: ndjson (later). There is no `List` type: see
[group_by and agg](#group_by-and-agg).

## Quick start

Import the package in `moon.pkg` with `import { "smallbearrr/pandas/pl" }`
and write `@pl.` in front of everything, or bring the names you use into
scope with `using @pl { col, lit_int, lit_float }`.

The usual flow is three steps: build a table from typed columns, describe
the result with expressions, print or read it.

```mbt check
///|
test "quick start" {
  // 1. A table is a list of named, typed columns of the same length.
  let sales = @pl.DataFrame::new([
    @pl.Series::str("region", ["north", "south", "north", "east"]),
    @pl.Series::int64("units", [10L, 4L, 7L, 12L]),
    @pl.Series::float64("price", [2.5, 4.0, 2.5, 1.5]),
  ])
  // 2. Expressions say what to compute; every table method returns a new
  //    table and leaves the old one alone.
  let top = sales
    .with_columns([(@pl.col("units") * @pl.col("price")).alias("revenue")])
    .filter(@pl.col("revenue").ge(@pl.lit_float(17.0)))
    .sort([@pl.col("revenue")], descending=[true])
  // 3. Print it (polars-style) or read single values back.
  inspect(
    top,
    content=(
      #|shape: (3, 4)
      #|┌────────┬───────┬───────┬─────────┐
      #|│ region ┆ units ┆ price ┆ revenue │
      #|│ ---    ┆ ---   ┆ ---   ┆ ---     │
      #|│ str    ┆ i64   ┆ f64   ┆ f64     │
      #|╞════════╪═══════╪═══════╪═════════╡
      #|│ north  ┆ 10    ┆ 2.5   ┆ 25.0    │
      #|│ east   ┆ 12    ┆ 1.5   ┆ 18.0    │
      #|│ north  ┆ 7     ┆ 2.5   ┆ 17.5    │
      #|└────────┴───────┴───────┴─────────┘
    ),
  )
  inspect(top.get(0, "region"), content="north")
  // An aggregation gives a one-row table, or a value on a single column.
  inspect(sales.column("units").sum(), content="33")
}
```

## Where to look

| You want to | Section |
| --- | --- |
| build a table, check its shape and types, print it | [DataFrame](#dataframe), [Series](#series) |
| compute new columns, keep some rows, order them | [Expressions](#expressions): `select`, `with_columns`, `filter`, `sort` |
| totals, means, quantiles, a value per column | [Aggregations and broadcasting](#aggregations-and-broadcasting) |
| one result per group | [group_by and agg](#group_by-and-agg) |
| combine two tables on a key | [join](#join) |
| a group's total next to every row, a rank inside the group | [Window expressions: over](#window-expressions-over) |
| the top N rows of each group, or all the values of a group | [group_by and agg](#group_by-and-agg) (the top-N recipe) |
| spread values into columns, or fold columns into rows | [pivot, unpivot and counting](#pivot-unpivot-and-counting) |
| sort, cut or filter inside an expression, trigonometry, row-wise sums | [More expression functions](#more-expression-functions) |
| handle nulls | [Missing values](#missing-values) |
| text and dates (`to_date`, `date_ymd`) | [Strings and dates](#strings-and-dates) |
| stack tables, drop duplicates, summarize | [concat, unique and describe](#concat-unique-and-describe) |
| work on one column without a table | [Series operations](#series-operations) |
| change a type | [Cast](#cast) |
| read or write CSV text or files | [CSV](#csv) |
| understand an error | [Error handling](#error-handling), [Errors](#errors) |
| the few places where this package differs from polars | [Good to know](#good-to-know) |

## DataFrame

A `DataFrame` is an ordered list of equally long, uniquely named columns.
Printing gives the polars-style table, with `null` for missing values.

```mbt check
///|
test "DataFrame and printing" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64_nullable("id", [Some(1L), Some(2L), None]),
    @pl.Series::str("name", ["ann", "bob", "cy"]),
    @pl.Series::float64("score", [1.5, 2.0, 0.25]),
  ])
  @debug.debug_inspect(df.shape(), content="(3, 3)")
  @debug.debug_inspect(df.columns(), content="[\"id\", \"name\", \"score\"]")
  inspect(
    df,
    content=(
      #|shape: (3, 3)
      #|┌──────┬──────┬───────┐
      #|│ id   ┆ name ┆ score │
      #|│ ---  ┆ ---  ┆ ---   │
      #|│ i64  ┆ str  ┆ f64   │
      #|╞══════╪══════╪═══════╡
      #|│ 1    ┆ ann  ┆ 1.5   │
      #|│ 2    ┆ bob  ┆ 2.0   │
      #|│ null ┆ cy   ┆ 0.25  │
      #|└──────┴──────┴───────┘
    ),
  )
  inspect(df.get(0, "name"), content="ann")
  @debug.debug_inspect(
    df.row(-1),
    content="[Null, String(\"cy\"), Float64(0.25)]",
  )
}
```

Mismatched lengths and duplicate names are rejected when the frame is built.

```mbt check
///|
test "DataFrame::new validates its columns" {
  let a = @pl.Series::int64("a", [1L, 2L])
  let b = @pl.Series::int64("b", [1L])
  try @pl.DataFrame::new([a, b]) catch {
    @pl.ShapeMismatch(_) => ()
    _ => fail("expected ShapeMismatch")
  } noraise {
    _ => fail("expected an error")
  }
  try @pl.DataFrame::new([a, a]) catch {
    @pl.DuplicateColumn(name) =>
      inspect(
        name,
        content="could not create a new DataFrame: column with name 'a' has more than one occurrence",
      )
    _ => fail("expected DuplicateColumn")
  } noraise {
    _ => fail("expected an error")
  }
}
```

## Series

Build a column with a typed constructor. The `_nullable` variants take
`Option` elements, where `None` is a null.

```mbt check
///|
test "construct and read a Series" {
  let s = @pl.Series::int64_nullable("a", [Some(1L), None, Some(3L)])
  inspect(s.len(), content="3")
  inspect(s.null_count(), content="1")
  inspect(s.dtype(), content="i64")
  inspect(s.get(0), content="1")
  inspect(s.get(1), content="null")
  // A negative index counts from the end.
  inspect(s.get(-1), content="3")
}
```

Printing a `Series` gives the polars-style listing: the shape, the name and
type, then one element per line (indented with a tab), `null` for missing
values and quotes around strings.

```mbt check
///|
test "print a Series" {
  let s = @pl.Series::int64_nullable("a", [Some(1L), None, Some(3L)])
  inspect(
    s,
    content=(
      #|shape: (3,)
      #|Series: 'a' [i64]
      #|[
      #|	1
      #|	null
      #|	3
      #|]
    ),
  )
  let t = @pl.Series::str("t", ["x", "y"])
  inspect(
    t,
    content=(
      #|shape: (2,)
      #|Series: 't' [str]
      #|[
      #|	"x"
      #|	"y"
      #|]
    ),
  )
}
```

`slice`, `head` and `tail` never fail: ranges outside the series are clipped.
`slice` shares storage with the original instead of copying it.

```mbt check
///|
test "slice, head and tail" {
  let s = @pl.Series::int32("n", [10, 20, 30, 40, 50])
  @debug.debug_inspect(
    s.slice(1, length=2).to_int32_array(),
    content="[Some(20), Some(30)]",
  )
  @debug.debug_inspect(
    s.head(n=2).to_int32_array(),
    content="[Some(10), Some(20)]",
  )
  @debug.debug_inspect(s.tail(n=1).to_int32_array(), content="[Some(50)]")
  inspect(s.slice(3, length=100).len(), content="2")
}
```

## Expressions

An `Expr` describes a computation; it does nothing until a `DataFrame` method
(`select`, `with_columns`, `filter`, `sort`, ...) evaluates it. Build one with
`col(name)` or a literal (`lit_int`, `lit_float`, `lit_str`, `lit_bool`, or
`lit(AnyValue)` for a typed one), then combine it with operators and methods.

- Arithmetic and logic use operators: `+ - * / %`, unary `-`, `&` and `|`.
  `//` is the method `floor_div` and `not` is `not_()`.
- Comparisons are methods, because `==` and `<` cannot return an `Expr`:
  `eq`, `neq`, `gt`, `ge`, `lt`, `le`.
- Building an expression never fails. Type errors and missing columns are
  raised as `PolarsError` when the expression is evaluated.
- The output column takes the name of the leftmost column in the expression
  (`literal` for a literal); `alias` renames it.

The examples below use this table.

```mbt check
///|
fn people() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::str("name", ["Ann", "bob", "Cy", "Dee"]),
    @pl.Series::int64("age", [34L, 28L, 41L, 19L]),
    @pl.Series::float64_nullable("score", [
      Some(8.5),
      None,
      Some(6.0),
      Some(9.5),
    ]),
  ])
}

///|
test "an expression prints as its polars spelling" {
  let e = (@pl.col("age") * @pl.lit_int(2) + @pl.lit_int(1)).alias("x")
  inspect(
    e,
    content=(
      #|[([(col("age")) * (dyn int: 2)]) + (dyn int: 1)].alias("x")
    ),
  )
}
```

### select, with_columns and filter

`select` returns exactly the expressions you list. `with_columns` keeps the
existing columns and adds the results (a result with an existing name
replaces that column). `filter` keeps the rows where a `Boolean` expression
is true; null counts as false.

```mbt check
///|
test "select, with_columns and filter" {
  let df = people()
  inspect(
    df.select([
      @pl.col("name"),
      (@pl.col("score") * @pl.lit_float(2.0)).alias("double"),
    ]),
    content=(
      #|shape: (4, 2)
      #|┌──────┬────────┐
      #|│ name ┆ double │
      #|│ ---  ┆ ---    │
      #|│ str  ┆ f64    │
      #|╞══════╪════════╡
      #|│ Ann  ┆ 17.0   │
      #|│ bob  ┆ null   │
      #|│ Cy   ┆ 12.0   │
      #|│ Dee  ┆ 19.0   │
      #|└──────┴────────┘
    ),
  )
  inspect(
    df.with_columns([(@pl.col("age") + @pl.lit_int(1)).alias("next_age")]),
    content=(
      #|shape: (4, 4)
      #|┌──────┬─────┬───────┬──────────┐
      #|│ name ┆ age ┆ score ┆ next_age │
      #|│ ---  ┆ --- ┆ ---   ┆ ---      │
      #|│ str  ┆ i64 ┆ f64   ┆ i64      │
      #|╞══════╪═════╪═══════╪══════════╡
      #|│ Ann  ┆ 34  ┆ 8.5   ┆ 35       │
      #|│ bob  ┆ 28  ┆ null  ┆ 29       │
      #|│ Cy   ┆ 41  ┆ 6.0   ┆ 42       │
      #|│ Dee  ┆ 19  ┆ 9.5   ┆ 20       │
      #|└──────┴─────┴───────┴──────────┘
    ),
  )
  // A result named like an existing column replaces that column.
  inspect(
    df
    .with_columns([(@pl.col("age") * @pl.lit_int(2)).alias("age")])
    .select([@pl.col("age")]),
    content=(
      #|shape: (4, 1)
      #|┌─────┐
      #|│ age │
      #|│ --- │
      #|│ i64 │
      #|╞═════╡
      #|│ 68  │
      #|│ 56  │
      #|│ 82  │
      #|│ 38  │
      #|└─────┘
    ),
  )
  inspect(
    df.filter(
      @pl.col("age").ge(@pl.lit_int(30)) & @pl.col("score").is_not_null(),
    ),
    content=(
      #|shape: (2, 3)
      #|┌──────┬─────┬───────┐
      #|│ name ┆ age ┆ score │
      #|│ ---  ┆ --- ┆ ---   │
      #|│ str  ┆ i64 ┆ f64   │
      #|╞══════╪═════╪═══════╡
      #|│ Ann  ┆ 34  ┆ 8.5   │
      #|│ Cy   ┆ 41  ┆ 6.0   │
      #|└──────┴─────┴───────┘
    ),
  )
}
```

A literal such as `lit_int(1)` adapts to the other operand: `Int32 column +
lit_int(1)` stays `i32`, and a value that does not fit widens the result to
`i64` instead of wrapping. A literal on its own is `i64` (`lit_int`) or `f64`
(`lit_float`).

Conditions are combined with `&` and `|`. When you mix the two operators,
write the grouping with parentheses: `(a & b) | c`. MoonBit warns about the
ambiguous precedence of a bare `a & b | c`, and the grouping you meant is easy
to get wrong. The comparison methods (`ge`, `eq`, ...) need no parentheses of
their own.

```mbt check
///|
test "combining conditions with & and |" {
  let df = people()
  let a = @pl.col("age").ge(@pl.lit_int(30))
  let b = @pl.col("score").is_not_null()
  let c = @pl.col("name").eq(@pl.lit_str("Dee"))
  @debug.debug_inspect(
    df.filter((a & b) | c).column("name").to_str_array(),
    content="[Some(\"Ann\"), Some(\"Cy\"), Some(\"Dee\")]",
  )
}
```

### sort

`sort` takes a list of key expressions and one `descending` flag per key (a
single flag applies to every key). It is always stable. Nulls come first
unless `nulls_last=true`.

```mbt check
///|
test "sort" {
  let df = people()
  inspect(
    df.sort([@pl.col("score")], descending=[true], nulls_last=true),
    content=(
      #|shape: (4, 3)
      #|┌──────┬─────┬───────┐
      #|│ name ┆ age ┆ score │
      #|│ ---  ┆ --- ┆ ---   │
      #|│ str  ┆ i64 ┆ f64   │
      #|╞══════╪═════╪═══════╡
      #|│ Dee  ┆ 19  ┆ 9.5   │
      #|│ Ann  ┆ 34  ┆ 8.5   │
      #|│ Cy   ┆ 41  ┆ 6.0   │
      #|│ bob  ┆ 28  ┆ null  │
      #|└──────┴─────┴───────┘
    ),
  )
  inspect(
    df.sort([@pl.col("name").str().to_lowercase()]).select([@pl.col("name")]),
    content=(
      #|shape: (4, 1)
      #|┌──────┐
      #|│ name │
      #|│ ---  │
      #|│ str  │
      #|╞══════╡
      #|│ Ann  │
      #|│ bob  │
      #|│ Cy   │
      #|│ Dee  │
      #|└──────┘
    ),
  )
}
```

### Aggregations and broadcasting

`sum`, `mean`, `min`, `max`, `count`, `len`, `n_unique`, `first`, `last`,
`median`, `std`, `var_` (the name `var` is a keyword), `product` and
`quantile` reduce a column to one value. A length-1 result is broadcast to
the height of the table when it is selected next to full-length columns.

```mbt check
///|
test "aggregations" {
  let df = people()
  inspect(
    df.select([
      @pl.col("age").sum().alias("total"),
      @pl.col("score").mean().alias("avg_score"),
      @pl.col("score").count().alias("scored"),
    ]),
    content=(
      #|shape: (1, 3)
      #|┌───────┬───────────┬────────┐
      #|│ total ┆ avg_score ┆ scored │
      #|│ ---   ┆ ---       ┆ ---    │
      #|│ i64   ┆ f64       ┆ i64    │
      #|╞═══════╪═══════════╪════════╡
      #|│ 122   ┆ 8.0       ┆ 3      │
      #|└───────┴───────────┴────────┘
    ),
  )
  inspect(
    df.select([
      @pl.col("name"),
      (@pl.col("age") - @pl.col("age").mean()).alias("centered"),
    ]),
    content=(
      #|shape: (4, 2)
      #|┌──────┬──────────┐
      #|│ name ┆ centered │
      #|│ ---  ┆ ---      │
      #|│ str  ┆ f64      │
      #|╞══════╪══════════╡
      #|│ Ann  ┆ 3.5      │
      #|│ bob  ┆ -2.5     │
      #|│ Cy   ┆ 10.5     │
      #|│ Dee  ┆ -11.5    │
      #|└──────┴──────────┘
    ),
  )
}
```

### when / then / otherwise

```mbt check
///|
test "when/then/otherwise" {
  let df = people()
  let band = @pl.when(@pl.col("age").ge(@pl.lit_int(30)))
    .then(@pl.lit_str("senior"))
    .otherwise(@pl.lit_str("junior"))
    .alias("band")
  inspect(
    df.select([@pl.col("name"), band]),
    content=(
      #|shape: (4, 2)
      #|┌──────┬────────┐
      #|│ name ┆ band   │
      #|│ ---  ┆ ---    │
      #|│ str  ┆ str    │
      #|╞══════╪════════╡
      #|│ Ann  ┆ senior │
      #|│ bob  ┆ junior │
      #|│ Cy   ┆ senior │
      #|│ Dee  ┆ junior │
      #|└──────┴────────┘
    ),
  )
}
```

### Missing values

`is_null`, `is_not_null`, `fill_null(expr)` and `fill_null_strategy`
(`Forward`, `Backward`, `Min`, `Max`, `Mean`, `Zero`, `One`) work on
expressions; `DataFrame::fill_null`, `fill_null_strategy`, `drop_nulls` and
`null_count` do the same for a whole table.

```mbt check
///|
test "missing values" {
  let df = people()
  inspect(
    df.with_columns([
      @pl.col("score").fill_null(@pl.lit_float(0.0)).alias("filled"),
      @pl.col("score").is_null().alias("missing"),
    ]),
    content=(
      #|shape: (4, 5)
      #|┌──────┬─────┬───────┬────────┬─────────┐
      #|│ name ┆ age ┆ score ┆ filled ┆ missing │
      #|│ ---  ┆ --- ┆ ---   ┆ ---    ┆ ---     │
      #|│ str  ┆ i64 ┆ f64   ┆ f64    ┆ bool    │
      #|╞══════╪═════╪═══════╪════════╪═════════╡
      #|│ Ann  ┆ 34  ┆ 8.5   ┆ 8.5    ┆ false   │
      #|│ bob  ┆ 28  ┆ null  ┆ 0.0    ┆ true    │
      #|│ Cy   ┆ 41  ┆ 6.0   ┆ 6.0    ┆ false   │
      #|│ Dee  ┆ 19  ┆ 9.5   ┆ 9.5    ┆ false   │
      #|└──────┴─────┴───────┴────────┴─────────┘
    ),
  )
  inspect(
    df.drop_nulls().height(),
    content=(
      #|3
    ),
  )
  inspect(
    df.null_count(),
    content=(
      #|shape: (1, 3)
      #|┌──────┬─────┬───────┐
      #|│ name ┆ age ┆ score │
      #|│ ---  ┆ --- ┆ ---   │
      #|│ i64  ┆ i64 ┆ i64   │
      #|╞══════╪═════╪═══════╡
      #|│ 0    ┆ 0   ┆ 1     │
      #|└──────┴─────┴───────┘
    ),
  )
}
```

### Strings and dates

`e.str()` gives the string functions: `contains`, `starts_with`, `ends_with`,
`replace`, `replace_all`, `to_lowercase`, `to_uppercase`, `len_chars`,
`len_bytes`, `strip_chars` (with `_start` / `_end` variants), `to_date` and
`to_datetime`. `contains` and `replace` take a regular expression unless you
pass `literal=true`; the engine is MoonBit's `Regex`, whose syntax is close to
but not the same as Rust's (see `docs/migration.md`). `e.dt()` gives `year`,
`month`, `day`, `hour`, `minute`, `second`, `weekday` and `ordinal_day` for
`Date` and `Datetime` columns.

```mbt check
///|
test "str and dt namespaces" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("name", ["Ann", "bob", "Cy"]),
    @pl.Series::from_any_values("born", [
      @pl.AnyValue::date_ymd(1970, 1, 1),
      @pl.AnyValue::date_ymd(1971, 1, 1),
      @pl.AnyValue::date_ymd(2022, 1, 8),
    ]),
  ])
  inspect(
    df.select([
      @pl.col("name").str().to_uppercase().alias("upper"),
      @pl.col("name").str().contains("^[A-Z]").alias("capital"),
      @pl.col("name").str().len_chars().alias("chars"),
      @pl.col("born").dt().year().alias("year"),
      @pl.col("born").dt().month().alias("month"),
    ]),
    content=(
      #|shape: (3, 5)
      #|┌───────┬─────────┬───────┬──────┬───────┐
      #|│ upper ┆ capital ┆ chars ┆ year ┆ month │
      #|│ ---   ┆ ---     ┆ ---   ┆ ---  ┆ ---   │
      #|│ str   ┆ bool    ┆ i64   ┆ i32  ┆ i32   │
      #|╞═══════╪═════════╪═══════╪══════╪═══════╡
      #|│ ANN   ┆ true    ┆ 3     ┆ 1970 ┆ 1     │
      #|│ BOB   ┆ false   ┆ 3     ┆ 1971 ┆ 1     │
      #|│ CY    ┆ true    ┆ 2     ┆ 2022 ┆ 1     │
      #|└───────┴─────────┴───────┴──────┴───────┘
    ),
  )
}
```

**Building dates.** A `Date` is stored as the number of days since 1970-01-01
and a `Datetime` as microseconds since 1970-01-01 00:00:00 (no time zone), but
you rarely want to write those numbers. `AnyValue::date_ymd(2024, 1, 15)` and
`AnyValue::datetime_ymd(2024, 1, 15, hour=10, minute=30)` build the values from
a calendar date (the optional `second` and `microsecond` default to 0); an
invalid date such as February 30 raises `ComputeError`. Put them in a column
with `Series::from_any_values`. To read text, use
`col(name).str().to_date()` and `.str().to_datetime()`: ISO texts
`2024-01-15`, `2024/1/5`, and for `to_datetime` also `2024-01-15 10:20:30` or
`2024-01-15T10:20:30` (fraction and `Z` / `+02:00` offset allowed). There is no
`format` argument. With the default `strict=true` a text that is not a date
raises `InvalidOperation`; with `strict=false` it becomes null.

```mbt check
///|
test "dates from numbers and from text" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("d", ["2024-01-15", "2024/1/5", "x"]),
    @pl.Series::str("t", ["2024-01-15 10:20:30", "2024-01-15T00:00:01", "x"]),
  ])
  // Lenient: the text "x" is null.
  inspect(
    df.select([
      @pl.col("d").str().to_date(strict=false),
      @pl.col("t").str().to_datetime(strict=false),
    ]),
    content=(
      #|shape: (3, 2)
      #|┌────────────┬─────────────────────┐
      #|│ d          ┆ t                   │
      #|│ ---        ┆ ---                 │
      #|│ date       ┆ datetime[μs]        │
      #|╞════════════╪═════════════════════╡
      #|│ 2024-01-15 ┆ 2024-01-15 10:20:30 │
      #|│ 2024-01-05 ┆ 2024-01-15 00:00:01 │
      #|│ null       ┆ null                │
      #|└────────────┴─────────────────────┘
    ),
  )
  // Strict (the default): the same column raises.
  try df.select([@pl.col("d").str().to_date()]) catch {
    @pl.InvalidOperation(msg) =>
      inspect(
        msg,
        content=(
          #|conversion from `str` to `date` failed in column 'd' for 1 out of 3 values: ["x"]
        ),
      )
    _ => fail("expected InvalidOperation")
  } noraise {
    _ => fail("expected an error")
  }
  // From numbers: a date, a datetime, and an invalid date.
  let built = @pl.DataFrame::new([
    @pl.Series::from_any_values("at", [
      @pl.AnyValue::datetime_ymd(2024, 1, 15, hour=10, minute=30),
      @pl.AnyValue::datetime_ymd(2024, 1, 15),
    ]),
  ])
  inspect(
    built,
    content=(
      #|shape: (2, 1)
      #|┌─────────────────────┐
      #|│ at                  │
      #|│ ---                 │
      #|│ datetime[μs]        │
      #|╞═════════════════════╡
      #|│ 2024-01-15 10:30:00 │
      #|│ 2024-01-15 00:00:00 │
      #|└─────────────────────┘
    ),
  )
  try @pl.AnyValue::date_ymd(2024, 2, 30) |> ignore catch {
    @pl.ComputeError(msg) => inspect(msg, content="invalid date: 2024-2-30")
    _ => fail("expected ComputeError")
  } noraise {
    _ => fail("expected an error")
  }
}
```

### concat, unique and describe

`concat` stacks tables: `Vertical` (same schema), `VerticalRelaxed` (widens
types), `Diagonal` (union of the columns, missing cells become null) and
`Horizontal` (side by side). `unique` takes `keep` (`UniqueKeep`) and
`maintain_order`. `describe` summarizes every column.

```mbt check
///|
test "concat, unique and describe" {
  let df = people()
  let both = @pl.concat([df, df.head(n=2)])
  inspect(
    both.height(),
    content=(
      #|6
    ),
  )
  let extra = @pl.DataFrame::new([
    @pl.Series::str("name", ["Eve"]),
    @pl.Series::str("city", ["Oslo"]),
  ])
  inspect(
    @pl.concat([df.head(n=1), extra], how=Diagonal),
    content=(
      #|shape: (2, 4)
      #|┌──────┬──────┬───────┬──────┐
      #|│ name ┆ age  ┆ score ┆ city │
      #|│ ---  ┆ ---  ┆ ---   ┆ ---  │
      #|│ str  ┆ i64  ┆ f64   ┆ str  │
      #|╞══════╪══════╪═══════╪══════╡
      #|│ Ann  ┆ 34   ┆ 8.5   ┆ null │
      #|│ Eve  ┆ null ┆ null  ┆ Oslo │
      #|└──────┴──────┴───────┴──────┘
    ),
  )
  inspect(
    both.unique(subset=["name"]).height(),
    content=(
      #|4
    ),
  )
  inspect(
    df.select([@pl.col("age"), @pl.col("score")]).describe(percentiles=[0.5]),
    content=(
      #|shape: (7, 3)
      #|┌────────────┬──────────┬──────────┐
      #|│ statistic  ┆ age      ┆ score    │
      #|│ ---        ┆ ---      ┆ ---      │
      #|│ str        ┆ f64      ┆ f64      │
      #|╞════════════╪══════════╪══════════╡
      #|│ count      ┆ 4.0      ┆ 3.0      │
      #|│ null_count ┆ 0.0      ┆ 1.0      │
      #|│ mean       ┆ 30.5     ┆ 8.0      │
      #|│ std        ┆ 9.327379 ┆ 1.802776 │
      #|│ min        ┆ 19.0     ┆ 6.0      │
      #|│ 50%        ┆ 34.0     ┆ 8.5      │
      #|│ max        ┆ 41.0     ┆ 9.5      │
      #|└────────────┴──────────┴──────────┘
    ),
  )
}
```

### Errors

Expression errors are `PolarsError` values and carry polars' wording.

```mbt check
///|
test "expression errors" {
  let df = people()
  try df.select([@pl.col("nope")]) catch {
    @pl.ColumnNotFound(msg) =>
      inspect(
        msg,
        content=(
          #|unable to find column "nope"; valid columns: ["name", "age", "score"]
        ),
      )
    _ => fail("expected ColumnNotFound")
  } noraise {
    _ => fail("expected an error")
  }
  try df.select([@pl.col("name") + @pl.lit_int(1)]) catch {
    @pl.InvalidOperation(msg) =>
      inspect(
        msg,
        content=(
          #|add operation not supported for dtypes `str` and `i32`
        ),
      )
    _ => fail("expected InvalidOperation")
  } noraise {
    _ => fail("expected an error")
  }
}
```

## group_by and agg

`df.group_by(keys)` splits the table by the values of the key expressions;
`.agg(expressions)` gives one row per group: the key columns first, then one
column per aggregation. Keys are expressions (`col("a")`,
`col("a") % lit_int(2)`, `all()`, ...), and null is a key value of its own.
Groups come out in the order
of their first appearance (polars promises that only with
`maintain_order=true`; this package always does it, and the argument is
accepted for compatibility). `df.group_by(keys).len()` is the shortcut for
counting the rows of every group.

The examples below use this table.

```mbt check
///|
fn orders() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::int64("id", [1L, 2L, 3L, 4L, 5L, 6L]),
    @pl.Series::str("region", [
      "north", "south", "north", "east", "south", "north",
    ]),
    @pl.Series::int64("units", [10L, 4L, 7L, 12L, 6L, 3L]),
    @pl.Series::float64("price", [2.5, 4.0, 2.5, 1.5, 4.0, 3.0]),
  ])
}

///|
test "group_by and agg" {
  let df = orders()
  inspect(
    df
    .group_by([@pl.col("region")])
    .agg([
      @pl.col("units").sum().alias("units"),
      (@pl.col("units") * @pl.col("price")).sum().alias("revenue"),
      @pl.col("price").mean().alias("avg_price"),
      @pl.len().alias("orders"),
    ]),
    content=(
      #|shape: (3, 5)
      #|┌────────┬───────┬─────────┬───────────┬────────┐
      #|│ region ┆ units ┆ revenue ┆ avg_price ┆ orders │
      #|│ ---    ┆ ---   ┆ ---     ┆ ---       ┆ ---    │
      #|│ str    ┆ i64   ┆ f64     ┆ f64       ┆ i64    │
      #|╞════════╪═══════╪═════════╪═══════════╪════════╡
      #|│ north  ┆ 20    ┆ 51.5    ┆ 2.666667  ┆ 3      │
      #|│ south  ┆ 10    ┆ 40.0    ┆ 4.0       ┆ 2      │
      #|│ east   ┆ 12    ┆ 18.0    ┆ 1.5       ┆ 1      │
      #|└────────┴───────┴─────────┴───────────┴────────┘
    ),
  )
  // Only the key and a count: group_by(...).len()
  inspect(
    df.group_by([@pl.col("region")]).len(name="rows"),
    content=(
      #|shape: (3, 2)
      #|┌────────┬──────┐
      #|│ region ┆ rows │
      #|│ ---    ┆ ---  │
      #|│ str    ┆ i64  │
      #|╞════════╪══════╡
      #|│ north  ┆ 3    │
      #|│ south  ┆ 2    │
      #|│ east   ┆ 1    │
      #|└────────┴──────┘
    ),
  )
  // A key can be an expression; it is named like the expression's output.
  inspect(
    df
    .group_by([(@pl.col("units") % @pl.lit_int(2)).alias("odd")])
    .agg([@pl.col("units").max()]),
    content=(
      #|shape: (2, 2)
      #|┌─────┬───────┐
      #|│ odd ┆ units │
      #|│ --- ┆ ---   │
      #|│ i64 ┆ i64   │
      #|╞═════╪═══════╡
      #|│ 0   ┆ 12    │
      #|│ 1   ┆ 7     │
      #|└─────┴───────┘
    ),
  )
}
```

**Names of the aggregated columns.** An aggregation keeps the name of its
column (`col("units").sum()` is called `units`), so aggregating one column
twice needs `alias`; without it the two outputs clash and `agg` raises
`DuplicateColumn`. There is no null-count method on `Expr`; count the nulls
of a group with `col("x").is_null().sum()`. There is no `Expr::value_counts`
or `Expr::unique_counts` either: use `group_by(...).len()` to count the rows
of each key and `Series::value_counts` for one column.

```mbt check
///|
test "aggregation names and null counts" {
  let df = orders()
  try
    df
    .group_by([@pl.col("region")])
    .agg([@pl.col("units").sum(), @pl.col("units").mean()])
  catch {
    @pl.DuplicateColumn(msg) =>
      inspect(
        msg,
        content="column with name 'units' has more than one occurrence",
      )
    _ => fail("expected DuplicateColumn")
  } noraise {
    _ => fail("expected an error")
  }
  inspect(
    df
    .group_by([@pl.col("region")])
    .agg([
      @pl.col("units").sum().alias("total"),
      @pl.col("units").mean().alias("avg"),
    ]),
    content=(
      #|shape: (3, 3)
      #|┌────────┬───────┬──────────┐
      #|│ region ┆ total ┆ avg      │
      #|│ ---    ┆ ---   ┆ ---      │
      #|│ str    ┆ i64   ┆ f64      │
      #|╞════════╪═══════╪══════════╡
      #|│ north  ┆ 20    ┆ 6.666667 │
      #|│ south  ┆ 10    ┆ 5.0      │
      #|│ east   ┆ 12    ┆ 12.0     │
      #|└────────┴───────┴──────────┘
    ),
  )
  // Nulls per group: a Boolean column sums to the number of `true`s.
  let readings = @pl.DataFrame::new([
    @pl.Series::str("sensor", ["a", "a", "b", "b", "b"]),
    @pl.Series::int64_nullable("x", [Some(1L), None, None, None, Some(5L)]),
  ])
  inspect(
    readings
    .group_by([@pl.col("sensor")])
    .agg([@pl.col("x").is_null().sum().alias("missing")]),
    content=(
      #|shape: (2, 2)
      #|┌────────┬─────────┐
      #|│ sensor ┆ missing │
      #|│ ---    ┆ ---     │
      #|│ str    ┆ i64     │
      #|╞════════╪═════════╡
      #|│ a      ┆ 1       │
      #|│ b      ┆ 2       │
      #|└────────┴─────────┘
    ),
  )
}
```

**There is no `List` type.** In polars an expression in `agg` that does not
reduce a group to one value (`col("units")` on its own, `col("units").sort()`,
`col("units").head(2)`) gives a `list` column. This package cannot build one,
so it raises `InvalidOperation` with a fixed text that names the expression.
The decision looks at the shape of the expression only, never at how many rows
a group has: `col("units")` is refused even when every group has one row.
Aggregate the column (`first()`, `sum()`, `len()`, ...), or an expression built
on the sorted or cut column (`col("units").sort().first()`).

```mbt check
///|
test "agg needs one value per group" {
  let df = orders()
  try df.group_by([@pl.col("region")]).agg([@pl.col("units")]) catch {
    @pl.InvalidOperation(msg) =>
      inspect(
        msg,
        content=(
          #|expression col("units") does not reduce each group to one value; this library has no List type, so aggregate it (for example with first(), sum() or len())
        ),
      )
    _ => fail("expected InvalidOperation")
  } noraise {
    _ => fail("expected an error")
  }
  // The sorted column is still a column; its first value is one value.
  inspect(
    df
    .group_by([@pl.col("region")])
    .agg([@pl.col("units").sort(descending=true).first().alias("top")]),
    content=(
      #|shape: (3, 2)
      #|┌────────┬─────┐
      #|│ region ┆ top │
      #|│ ---    ┆ --- │
      #|│ str    ┆ i64 │
      #|╞════════╪═════╡
      #|│ north  ┆ 10  │
      #|│ south  ┆ 6   │
      #|│ east   ┆ 12  │
      #|└────────┴─────┘
    ),
  )
}
```

**All the values of a group, or the top N of each group.** What a polars user
usually wants behind `agg([col("units")])` or `agg([col("units").head(2)])` is
the rows themselves, not a list. Keep the rows and cut them with a window
expression ([`over`](#window-expressions-over)), which stays one value per
row: rank the rows inside each group, then `filter` on the rank. For the top N
use `rank(descending=true)` and keep the ranks up to N. The default rank method
`Average` gives fractional ranks for ties (two tied leaders are both 1.5); pass
`method_=Ordinal` (ties broken by row order) to get exactly the ranks
1 to n in each group, so the filter keeps exactly N rows per group. The
argument is spelled `method_` because `method` is a reserved word in MoonBit
and would warn at every call, the same convention as `var_`. When you want a
single row per group, `sort_by` inside `agg` gives it: pick the value of
another column at the extreme.

```mbt check
///|
test "top N per group" {
  let df = orders().select([@pl.col("id"), @pl.col("region"), @pl.col("units")])
  let by_region = [@pl.col("region")]
  // The two biggest orders of each region: rank 1 is the biggest.
  inspect(
    df.filter(
      @pl.col("units")
      .rank(descending=true)
      .over(by_region)
      .le(@pl.lit_float(2.0)),
    ),
    content=(
      #|shape: (5, 3)
      #|┌─────┬────────┬───────┐
      #|│ id  ┆ region ┆ units │
      #|│ --- ┆ ---    ┆ ---   │
      #|│ i64 ┆ str    ┆ i64   │
      #|╞═════╪════════╪═══════╡
      #|│ 1   ┆ north  ┆ 10    │
      #|│ 2   ┆ south  ┆ 4     │
      #|│ 3   ┆ north  ┆ 7     │
      #|│ 4   ┆ east   ┆ 12    │
      #|│ 5   ┆ south  ┆ 6     │
      #|└─────┴────────┴───────┘
    ),
  )
  // One row per group: the id of the biggest order of each region.
  inspect(
    df
    .group_by(by_region)
    .agg([
      @pl.col("id")
      .sort_by([@pl.col("units")], descending=[true])
      .first()
      .alias("biggest_id"),
    ]),
    content=(
      #|shape: (3, 2)
      #|┌────────┬────────────┐
      #|│ region ┆ biggest_id │
      #|│ ---    ┆ ---        │
      #|│ str    ┆ i64        │
      #|╞════════╪════════════╡
      #|│ north  ┆ 1          │
      #|│ south  ┆ 5          │
      #|│ east   ┆ 4          │
      #|└────────┴────────────┘
    ),
  )
  // `over` needs a result as long as the group: `sort()` is fine, `head(2)`
  // is not.
  try df.select([@pl.col("units").head(n=2).over(by_region)]) catch {
    @pl.ShapeMismatch(msg) =>
      inspect(
        msg,
        content="the length of the window expression did not match that of the group",
      )
    _ => fail("expected ShapeMismatch")
  } noraise {
    _ => fail("expected an error")
  }
}
```

## join

`left.join(right, on=[...], how=...)` combines two tables on key expressions.
`how` is `Inner` (the default), `Left`, `Right`, `Full`, `Semi`, `Anti` or
`Cross`. Use `on` when both tables call the key the same, `left_on` and
`right_on` otherwise (each is an `Array[Expr]`, so a key can be computed). For
`Inner` and `Left` the two key columns become one (the left one); a right
column whose name the left table already has gets the `suffix` (default
`_right`). `Right` also gives one key column, but it holds the right table's
key and comes after the other columns of the left table (`v, region, manager`
for `a.join(b, on=[col("region")], how=Right)`). `Full` keeps both key
columns (`region` and `region_right`), each null where the other table had no
match. `coalesce` overrides this: `coalesce=true` merges the two key columns
into one (the left value, or the right one where the left row is missing), and
`coalesce=false` keeps both key columns for any `how` that has them.

The rows come out in a fixed order: for `Inner`, `Left`, `Semi` and `Anti` the
order of the left table, and for one left row its matches in the order of the
right table. `Right` follows the right table. There is no `maintain_order`
argument.

```mbt check
///|
fn customers() -> @pl.DataFrame raise @pl.PolarsError {
  @pl.DataFrame::new([
    @pl.Series::str("region", ["north", "south", "west"]),
    @pl.Series::str("manager", ["Ann", "Bob", "Cy"]),
  ])
}

///|
test "inner, left and anti joins" {
  let df = orders().select([@pl.col("id"), @pl.col("region"), @pl.col("units")])
  let managers = customers()
  // Inner: only the rows whose key is on both sides.
  inspect(
    df.join(managers, on=[@pl.col("region")]),
    content=(
      #|shape: (5, 4)
      #|┌─────┬────────┬───────┬─────────┐
      #|│ id  ┆ region ┆ units ┆ manager │
      #|│ --- ┆ ---    ┆ ---   ┆ ---     │
      #|│ i64 ┆ str    ┆ i64   ┆ str     │
      #|╞═════╪════════╪═══════╪═════════╡
      #|│ 1   ┆ north  ┆ 10    ┆ Ann     │
      #|│ 2   ┆ south  ┆ 4     ┆ Bob     │
      #|│ 3   ┆ north  ┆ 7     ┆ Ann     │
      #|│ 5   ┆ south  ┆ 6     ┆ Bob     │
      #|│ 6   ┆ north  ┆ 3     ┆ Ann     │
      #|└─────┴────────┴───────┴─────────┘
    ),
  )
  // Left: every left row; the right columns are null where nothing matches.
  inspect(
    df.join(managers, on=[@pl.col("region")], how=Left),
    content=(
      #|shape: (6, 4)
      #|┌─────┬────────┬───────┬─────────┐
      #|│ id  ┆ region ┆ units ┆ manager │
      #|│ --- ┆ ---    ┆ ---   ┆ ---     │
      #|│ i64 ┆ str    ┆ i64   ┆ str     │
      #|╞═════╪════════╪═══════╪═════════╡
      #|│ 1   ┆ north  ┆ 10    ┆ Ann     │
      #|│ 2   ┆ south  ┆ 4     ┆ Bob     │
      #|│ 3   ┆ north  ┆ 7     ┆ Ann     │
      #|│ 4   ┆ east   ┆ 12    ┆ null    │
      #|│ 5   ┆ south  ┆ 6     ┆ Bob     │
      #|│ 6   ┆ north  ┆ 3     ┆ Ann     │
      #|└─────┴────────┴───────┴─────────┘
    ),
  )
  // Anti: the left rows with no match (Semi is the opposite). Only the left
  // columns remain.
  inspect(
    df.join(managers, on=[@pl.col("region")], how=Anti),
    content=(
      #|shape: (1, 3)
      #|┌─────┬────────┬───────┐
      #|│ id  ┆ region ┆ units │
      #|│ --- ┆ ---    ┆ ---   │
      #|│ i64 ┆ str    ┆ i64   │
      #|╞═════╪════════╪═══════╡
      #|│ 4   ┆ east   ┆ 12    │
      #|└─────┴────────┴───────┘
    ),
  )
}

///|
test "full join and coalesce" {
  let a = @pl.DataFrame::new([
    @pl.Series::str("region", ["north", "south", "east"]),
    @pl.Series::int64("v", [1L, 2L, 3L]),
  ])
  let b = customers()
  // Full: every row of both sides; the two key columns stay apart.
  inspect(
    a.join(b, on=[@pl.col("region")], how=Full),
    content=(
      #|shape: (4, 4)
      #|┌────────┬──────┬──────────────┬─────────┐
      #|│ region ┆ v    ┆ region_right ┆ manager │
      #|│ ---    ┆ ---  ┆ ---          ┆ ---     │
      #|│ str    ┆ i64  ┆ str          ┆ str     │
      #|╞════════╪══════╪══════════════╪═════════╡
      #|│ north  ┆ 1    ┆ north        ┆ Ann     │
      #|│ south  ┆ 2    ┆ south        ┆ Bob     │
      #|│ east   ┆ 3    ┆ null         ┆ null    │
      #|│ null   ┆ null ┆ west         ┆ Cy      │
      #|└────────┴──────┴──────────────┴─────────┘
    ),
  )
  // coalesce=true: one key column that is never null here.
  inspect(
    a.join(b, on=[@pl.col("region")], how=Full, coalesce=true),
    content=(
      #|shape: (4, 3)
      #|┌────────┬──────┬─────────┐
      #|│ region ┆ v    ┆ manager │
      #|│ ---    ┆ ---  ┆ ---     │
      #|│ str    ┆ i64  ┆ str     │
      #|╞════════╪══════╪═════════╡
      #|│ north  ┆ 1    ┆ Ann     │
      #|│ south  ┆ 2    ┆ Bob     │
      #|│ east   ┆ 3    ┆ null    │
      #|│ west   ┆ null ┆ Cy      │
      #|└────────┴──────┴─────────┘
    ),
  )
}

///|
test "different key names, suffix and null keys" {
  let a = @pl.DataFrame::new([
    @pl.Series::int64_nullable("k", [Some(1L), None, Some(2L)]),
    @pl.Series::str("v", ["a", "b", "c"]),
  ])
  let b = @pl.DataFrame::new([
    @pl.Series::int64_nullable("key", [None, Some(2L), Some(2L)]),
    @pl.Series::str("v", ["x", "y", "z"]),
  ])
  // Different names: left_on and right_on. The right `v` becomes `v_right`
  // and the key column keeps the left name. A null key matches nothing...
  inspect(
    a.join(b, left_on=[@pl.col("k")], right_on=[@pl.col("key")]),
    content=(
      #|shape: (2, 3)
      #|┌─────┬─────┬─────────┐
      #|│ k   ┆ v   ┆ v_right │
      #|│ --- ┆ --- ┆ ---     │
      #|│ i64 ┆ str ┆ str     │
      #|╞═════╪═════╪═════════╡
      #|│ 2   ┆ c   ┆ y       │
      #|│ 2   ┆ c   ┆ z       │
      #|└─────┴─────┴─────────┘
    ),
  )
  // ...unless nulls_equal=true.
  inspect(
    a.join(
      b,
      left_on=[@pl.col("k")],
      right_on=[@pl.col("key")],
      nulls_equal=true,
      suffix="_b",
    ),
    content=(
      #|shape: (3, 3)
      #|┌──────┬─────┬─────┐
      #|│ k    ┆ v   ┆ v_b │
      #|│ ---  ┆ --- ┆ --- │
      #|│ i64  ┆ str ┆ str │
      #|╞══════╪═════╪═════╡
      #|│ null ┆ b   ┆ x   │
      #|│ 2    ┆ c   ┆ y   │
      #|│ 2    ┆ c   ┆ z   │
      #|└──────┴─────┴─────┘
    ),
  )
}
```

Keys of different types are an error unless polars would promote them
(`Int32` with `Int64`, `Float32` with `Float64`); `validate` checks that the
sides are `OneToMany`, `ManyToOne` or `OneToOne` and raises when they are
not. See `docs/golden/known-diffs/join.md`.

## Window expressions: over

`expr.over([keys])` computes `expr` per group of the keys and puts the result
on every row of that group, so the table keeps its height. It is the
`group_to_rows` mapping of polars; `order_by` and the other mapping strategies
are not provided. Aggregations give one value repeated on the group's rows;
sequence operations (`cum_sum`, `shift`, `rank`, `sort`, ...) see the rows of
the group in table order.

```mbt check
///|
test "over" {
  let df = orders().select([@pl.col("id"), @pl.col("region"), @pl.col("units")])
  inspect(
    df.with_columns([
      @pl.col("units").sum().over([@pl.col("region")]).alias("region_total"),
      (@pl.col("units").cast(Float64) /
      @pl.col("units").sum().over([@pl.col("region")]).cast(Float64)).alias(
        "share",
      ),
      @pl.col("units").cum_sum().over([@pl.col("region")]).alias("running"),
    ]),
    content=(
      #|shape: (6, 6)
      #|┌─────┬────────┬───────┬──────────────┬───────┬─────────┐
      #|│ id  ┆ region ┆ units ┆ region_total ┆ share ┆ running │
      #|│ --- ┆ ---    ┆ ---   ┆ ---          ┆ ---   ┆ ---     │
      #|│ i64 ┆ str    ┆ i64   ┆ i64          ┆ f64   ┆ i64     │
      #|╞═════╪════════╪═══════╪══════════════╪═══════╪═════════╡
      #|│ 1   ┆ north  ┆ 10    ┆ 20           ┆ 0.5   ┆ 10      │
      #|│ 2   ┆ south  ┆ 4     ┆ 10           ┆ 0.4   ┆ 4       │
      #|│ 3   ┆ north  ┆ 7     ┆ 20           ┆ 0.35  ┆ 17      │
      #|│ 4   ┆ east   ┆ 12    ┆ 12           ┆ 1.0   ┆ 12      │
      #|│ 5   ┆ south  ┆ 6     ┆ 10           ┆ 0.6   ┆ 10      │
      #|│ 6   ┆ north  ┆ 3     ┆ 20           ┆ 0.15  ┆ 20      │
      #|└─────┴────────┴───────┴──────────────┴───────┴─────────┘
    ),
  )
}
```

`over` needs one value per row: an expression whose result has the group's
length is fine (`col("units").over(...)`, `sort()`, `rank()`, `cum_sum()`; a
`sort` puts the sorted values back on the group's rows in table order), and a
result of another length (`head(2)`) raises `ShapeMismatch`. A window `rank`
numbers the rows inside each group; see
[the top-N recipe](#group_by-and-agg) for filtering on it.

```mbt check
///|
test "rank within a group" {
  let df = orders().select([@pl.col("id"), @pl.col("region"), @pl.col("units")])
  // 1.0 is the biggest order of its region (the default method is Average,
  // so the ranks are Float64).
  inspect(
    df.with_columns([
      @pl.col("units")
      .rank(descending=true)
      .over([@pl.col("region")])
      .alias("rank_in_region"),
    ]),
    content=(
      #|shape: (6, 4)
      #|┌─────┬────────┬───────┬────────────────┐
      #|│ id  ┆ region ┆ units ┆ rank_in_region │
      #|│ --- ┆ ---    ┆ ---   ┆ ---            │
      #|│ i64 ┆ str    ┆ i64   ┆ f64            │
      #|╞═════╪════════╪═══════╪════════════════╡
      #|│ 1   ┆ north  ┆ 10    ┆ 1.0            │
      #|│ 2   ┆ south  ┆ 4     ┆ 2.0            │
      #|│ 3   ┆ north  ┆ 7     ┆ 2.0            │
      #|│ 4   ┆ east   ┆ 12    ┆ 1.0            │
      #|│ 5   ┆ south  ┆ 6     ┆ 1.0            │
      #|│ 6   ┆ north  ┆ 3     ┆ 3.0            │
      #|└─────┴────────┴───────┴────────────────┘
    ),
  )
}
```

## pivot, unpivot and counting

`pivot` turns the values of the `on` columns into new columns: one row per
`index` value, one column per `on` value, the `values` column in the cells.
When a cell would get more than one row you must pass `aggregate_function`
(`First`, `Last`, `Sum`, `Min`, `Max`, `Mean`, `Median` or `Len`); otherwise
it raises. `unpivot` is the opposite: it folds columns into `variable` and
`value` rows. `Series::value_counts` counts the rows per value.

```mbt check
///|
test "pivot and unpivot" {
  let sales = @pl.DataFrame::new([
    @pl.Series::str("region", ["north", "north", "south", "south", "south"]),
    @pl.Series::str("quarter", ["Q1", "Q2", "Q1", "Q1", "Q2"]),
    @pl.Series::int64("units", [10L, 4L, 7L, 12L, 6L]),
  ])
  // South has two rows in Q1, so a function says how to combine them.
  let wide = sales.pivot(
    ["quarter"],
    index=["region"],
    values=["units"],
    aggregate_function=Sum,
  )
  inspect(
    wide,
    content=(
      #|shape: (2, 3)
      #|┌────────┬─────┬─────┐
      #|│ region ┆ Q1  ┆ Q2  │
      #|│ ---    ┆ --- ┆ --- │
      #|│ str    ┆ i64 ┆ i64 │
      #|╞════════╪═════╪═════╡
      #|│ north  ┆ 10  ┆ 4   │
      #|│ south  ┆ 19  ┆ 6   │
      #|└────────┴─────┴─────┘
    ),
  )
  // Back to long: `region` stays, the other columns become rows.
  inspect(
    wide.unpivot(index=["region"], variable_name="quarter", value_name="units"),
    content=(
      #|shape: (4, 3)
      #|┌────────┬─────────┬───────┐
      #|│ region ┆ quarter ┆ units │
      #|│ ---    ┆ ---     ┆ ---   │
      #|│ str    ┆ str     ┆ i64   │
      #|╞════════╪═════════╪═══════╡
      #|│ north  ┆ Q1      ┆ 10    │
      #|│ south  ┆ Q1      ┆ 19    │
      #|│ north  ┆ Q2      ┆ 4     │
      #|│ south  ┆ Q2      ┆ 6     │
      #|└────────┴─────────┴───────┘
    ),
  )
  try sales.pivot(["quarter"], index=["region"], values=["units"]) catch {
    @pl.ComputeError(msg) =>
      inspect(
        msg,
        content=(
          #|aggregation 'item' expected no or a single value, got 2 values
        ),
      )
    _ => fail("expected ComputeError")
  } noraise {
    _ => fail("expected an error")
  }
}

///|
test "value_counts" {
  let s = @pl.Series::str("region", ["north", "south", "north", "north"])
  inspect(
    s.value_counts(sort=true),
    content=(
      #|shape: (2, 2)
      #|┌────────┬───────┐
      #|│ region ┆ count │
      #|│ ---    ┆ ---   │
      #|│ str    ┆ i64   │
      #|╞════════╪═══════╡
      #|│ north  ┆ 3     │
      #|│ south  ┆ 1     │
      #|└────────┴───────┘
    ),
  )
}
```

`DataFrame::transpose` swaps rows and columns (all columns are cast to their
common type), and `DataFrame::to_dict` gives the columns as a
`Map[String, Series]`.

## More expression functions

Expressions can also reorder or cut a column, which changes its length:
`sort`, `sort_by`, `arg_sort`, `head`, `tail`, `slice`, `unique`, `drop_nulls`
and `filter`. Only literals and aggregations are repeated against longer
columns in a `select`; a column cut to a different length next to a full
column is a `ShapeMismatch`. `any` and `all` reduce a column to one `Boolean`.
`sin`, `cos`, `tan`, `arcsin`, `arccos` and `arctan` work on numbers, and
`sum_horizontal`, `min_horizontal` and `max_horizontal` combine columns row by
row. `Series` has `any`, `all`, `is_sorted`, `gather_every`, `value_counts` and
`unique_counts`; `DataFrame` has `gather_every`.

```mbt check
///|
test "expressions that change the length" {
  let df = orders()
  inspect(
    df.select([
      @pl.col("units").sort(descending=true).head(n=3).alias("top3"),
      @pl.col("region").unique(maintain_order=true).head(n=3).alias("regions"),
    ]),
    content=(
      #|shape: (3, 2)
      #|┌──────┬─────────┐
      #|│ top3 ┆ regions │
      #|│ ---  ┆ ---     │
      #|│ i64  ┆ str     │
      #|╞══════╪═════════╡
      #|│ 12   ┆ north   │
      #|│ 10   ┆ south   │
      #|│ 7    ┆ east    │
      #|└──────┴─────────┘
    ),
  )
  inspect(
    df.select([
      @pl.sum_horizontal([@pl.col("units"), @pl.col("id")]).alias("both"),
      @pl.col("units").gt(@pl.lit_int(5)).any().alias("any_big"),
    ]),
    content=(
      #|shape: (6, 2)
      #|┌──────┬─────────┐
      #|│ both ┆ any_big │
      #|│ ---  ┆ ---     │
      #|│ i64  ┆ bool    │
      #|╞══════╪═════════╡
      #|│ 11   ┆ true    │
      #|│ 6    ┆ true    │
      #|│ 10   ┆ true    │
      #|│ 16   ┆ true    │
      #|│ 11   ┆ true    │
      #|│ 9    ┆ true    │
      #|└──────┴─────────┘
    ),
  )
}
```

## Series operations

A `Series` has the same kernels the expressions use, as methods that take
and return series: arithmetic (`add`, `sub`, `mul`, `div`, `floor_div`,
`rem`, `neg`), comparison (`eq`, `neq`, `gt`, `ge`, `lt`, `le`), logic
(`and_`, `or_`, `not_`), aggregation (`sum`, `mean`, `min`, `max`, `median`,
`std`, `quantile`, ...), ordering (`sort`, `arg_sort`, `rank`, `unique`,
`is_in`), running values (`cum_sum`, `shift`, `diff`, `fill_null`) and
`between`.

A scalar operand is a series of length 1, which is repeated against the
other side. Aggregations return an `AnyValue`: print it, match on it, or
use `to_double` / `to_int64` for a number.

```mbt check
///|
test "Series operations" {
  let s = @pl.Series::int64("a", [3L, 1L, 2L])
  let one = @pl.Series::int64("one", [1L])
  @debug.debug_inspect(
    s.add(one).to_int64_array(),
    content="[Some(4), Some(2), Some(3)]",
  )
  @debug.debug_inspect(
    s.gt(one).to_bool_array(),
    content="[Some(true), Some(false), Some(true)]",
  )
  @debug.debug_inspect(
    s.sort().to_int64_array(),
    content="[Some(1), Some(2), Some(3)]",
  )
  @debug.debug_inspect(
    s.cum_sum().to_int64_array(),
    content="[Some(3), Some(4), Some(6)]",
  )
  inspect(s.sum(), content="6")
  @debug.debug_inspect(s.sum().to_int64(), content="Some(6)")
  @debug.debug_inspect(s.mean().to_double(), content="Some(2)")
}
```

`Series::any` and `Series::all` work on `Boolean` series and return a `Bool?`,
as polars' `bool | None`. With the default `ignore_nulls=true` the result is
never `None`, but it is still an `Option`, so `if s.any() { ... }` does not
compile: compare it, as in `s.any() == Some(true)`.

```mbt check
///|
test "any and all" {
  let flags = @pl.Series::bool("b", [false, true])
  if flags.any() == Some(true) {
    inspect("some", content="some")
  } else {
    fail("expected true")
  }
  inspect(flags.all() == Some(true), content="false")
}
```

## Cast

`cast` converts between types. By default it is strict and raises when a
value does not fit or parse; `strict=false` turns such values into nulls.

```mbt check
///|
test "cast" {
  let s = @pl.Series::int32("n", [1, 2, 3])
  @debug.debug_inspect(
    s.cast(Float64).to_float64_array(),
    content="[Some(1), Some(2), Some(3)]",
  )
  let text = @pl.Series::str("t", ["1", "x"])
  @debug.debug_inspect(
    text.cast(Int64, strict=false).to_int64_array(),
    content="[Some(1), None]",
  )
}
```

## CSV

`read_csv_str` turns CSV text into a `DataFrame` and `write_csv_str` turns a
`DataFrame` into CSV text. Both work on every backend (they only touch
strings); reading and writing files is in the separate package
[`@plfs`](#files).

### Reading

The first line is the header. Each column gets the first of `Int64`,
`Float64`, `Boolean` and `String` that reads all of its values; an empty
field is null. The inference looks at the first 100 records (see
`infer_schema_length` below).

```mbt check
///|
test "csv: read text" {
  let df = @pl.read_csv_str(
    "name,score,ratio,passed\nann,3,0.5,true\nbob,5,,false\n",
  )
  inspect(
    df,
    content=(
      #|shape: (2, 4)
      #|┌──────┬───────┬───────┬────────┐
      #|│ name ┆ score ┆ ratio ┆ passed │
      #|│ ---  ┆ ---   ┆ ---   ┆ ---    │
      #|│ str  ┆ i64   ┆ f64   ┆ bool   │
      #|╞══════╪═══════╪═══════╪════════╡
      #|│ ann  ┆ 3     ┆ 0.5   ┆ true   │
      #|│ bob  ┆ 5     ┆ null  ┆ false  │
      #|└──────┴───────┴───────┴────────┘
    ),
  )
}
```

The options are labelled arguments of `CsvReadOptions::new`; leave out the
ones you do not need.

| Option | Default | Meaning |
| --- | --- | --- |
| `separator` | `','` | the field separator, any one character except a line break |
| `has_header` | `true` | with `false` the columns are `column_0`, `column_1`, ... |
| `quote_char` | `Some('"')` | a `Char?`: `Some('\'')` for single quotes, `None` turns quoting off (the writer's `quote_char` is a plain `Char`) |
| `null_values` | `[]` | texts that read as null in every column, quoted ones too |
| `schema_overrides` | `{}` | column name to `DataType`: read the column as that type instead of inferring it |
| `infer_schema_length` | `Some(100)` | how many records the inference looks at; `None` is all, `Some(0)` makes every column a `String` |
| `n_rows` | all | stop after this many rows |
| `skip_rows` | `0` | records to skip before the header |
| `try_parse_dates` | `false` | read dates and datetimes (see [Dates](#dates)); day first is tried before month first, so `01/02/2024` is 1 February, and there is no `format` option |

```mbt check
///|
test "csv: read options" {
  // a semicolon file, no header, "-" for missing, only the first 2 rows
  let text = "1;x\n2;-\n3;z\n"
  let df = @pl.read_csv_str(
    text,
    options=@pl.CsvReadOptions::new(
      separator=';',
      has_header=false,
      null_values=["-"],
      n_rows=2,
    ),
  )
  @debug.debug_inspect(df.columns(), content="[\"column_0\", \"column_1\"]")
  @debug.debug_inspect(
    df.column("column_1").to_str_array(),
    content="[Some(\"x\"), None]",
  )
  // an id column that looks like a number but is a code
  let ids = @pl.read_csv_str(
    "id,n\n007,1\n010,2\n",
    options=@pl.CsvReadOptions::new(schema_overrides={ "id": String }),
  )
  @debug.debug_inspect(
    ids.column("id").to_str_array(),
    content="[Some(\"007\"), Some(\"010\")]",
  )
}
```

Only an empty field is null by default. `NA`, `null` and `N/A` are not: they
make the column a `String`. `NaN` is the float NaN, not null. List the texts
you want as missing in `null_values`.

An integer too big for `Int64` follows polars, except where polars reads
`Int128`, which the library does not have: there the column is a `String` and
the original text is kept to the last digit. That is the case when the window
holds such integers and no float-shaped value (`1.5`, `1e3`, `NaN`, `inf`).
With float-shaped values and no small integer the column is `Float64`, as in
polars; with a small integer as well it is a `String`, also as in polars. To
get floats from big integers use `schema_overrides={ "id": Float64 }`.

Quoted fields may hold separators, line breaks and doubled quotes, `\r\n` and
`\n` both end a record, a blank line is a row of nulls, a short record is
padded with nulls, and a leading byte order mark is dropped. A record with more
fields than the header is a `ParseError`. Without a header, the table is as wide
as the widest record the inference looks at (the whole file with
`infer_schema_length=None`) and every shorter row is padded with nulls, as in
polars. So a table of N rows and one record of W fields is N x W cells: one very
wide row in a long file takes a lot of memory.

### Dates

Like polars, the reader leaves `2024-01-02` as a `String` unless you ask for
dates with `try_parse_dates=true` (or give the column a `Date` or `Datetime`
override). Datetimes with a time zone (`Z`, `+01:00`) and bare times stay
strings.

For texts such as `01/02/2024` the day-first reading is tried before the
month-first one, so `01/02/2024` is 1 February 2024 (day 1, month 2). There is
no `format` option to change that. If the same column also holds a value that
can only be read month first, such as `03/13/2024`, the whole column stays a
`String`; `str().to_date()` has no `format` argument either, so such a column
cannot be turned into dates afterwards.

```mbt check
///|
test "csv: try_parse_dates" {
  let text = "d,t\n2024-01-02,2024-01-02T03:04:05\n"
  let plain = @pl.read_csv_str(text)
  @debug.debug_inspect(plain.dtypes(), content="[String, String]")
  let parsed = @pl.read_csv_str(
    text,
    options=@pl.CsvReadOptions::new(try_parse_dates=true),
  )
  @debug.debug_inspect(parsed.dtypes(), content="[Date, Datetime]")
}
```

### null and the empty string

An empty field with no quotes is null; `""` is the empty string. The writer
keeps them apart the same way (null is empty, the empty string is `""`), so
the pair survives a round trip.

```mbt check
///|
test "csv: null versus empty string" {
  let df = @pl.read_csv_str("a,b\n1,\n2,\"\"\n3,x\n")
  @debug.debug_inspect(
    df.column("b").to_str_array(),
    content="[None, Some(\"\"), Some(\"x\")]",
  )
  assert_eq(@pl.write_csv_str(df), "a,b\n1,\n2,\"\"\n3,x\n")
}
```

### Errors

Reading raises `ParseError` for a value that does not parse, a record with too
many fields, a quote that is never closed, text after a closing quote and
empty input. The message is polars' first line followed by ` at line N`, the
line (counting line breaks inside quotes) where the record starts. Bad options
are `InvalidOperation`, with these texts:

- `separator must not be a line break (LF or CR)`
- `quote_char must not be a line break (LF or CR)`
- `separator and quote_char must differ, got '<c>'`
- `n_rows must not be negative, got <n>` (and the same for `skip_rows` and
  `infer_schema_length`)

The types come from the first 100 records only. A value after that window that
does not fit the type is a `ParseError` (`could not parse `N/A` as dtype `i64`
...`), so a file that has 150 integers and then `N/A` fails on row 151. There
are three ways out: read the whole file for the inference with
`infer_schema_length=None`, name the type of the column in `schema_overrides`
(`{ "a": String }` keeps the text), or list the text in `null_values`.

```mbt check
///|
test "csv: parse errors name the line" {
  try
    @pl.read_csv_str(
      "a\n1\nx\n",
      options=@pl.CsvReadOptions::new(schema_overrides={ "a": Int64 }),
    )
  catch {
    @pl.ParseError(msg) =>
      inspect(
        msg,
        content="could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 3",
      )
    _ => fail("expected ParseError")
  } noraise {
    _ => fail("expected an error")
  }
}
```

```mbt check
///|
test "csv: a bad value after the inference window" {
  // the window is 2 records, so `N/A` on the third is not seen by the inference
  let text = "a\n1\n2\nN/A\n"
  try
    @pl.read_csv_str(
      text,
      options=@pl.CsvReadOptions::new(infer_schema_length=Some(2)),
    )
  catch {
    @pl.ParseError(_) => ()
    _ => fail("expected ParseError")
  } noraise {
    _ => fail("expected an error")
  }
  // look at every record, or say which texts are missing
  let all = @pl.read_csv_str(
    text,
    options=@pl.CsvReadOptions::new(infer_schema_length=None),
  )
  @debug.debug_inspect(all.dtypes(), content="[String]")
  let nulls = @pl.read_csv_str(
    text,
    options=@pl.CsvReadOptions::new(infer_schema_length=Some(2), null_values=[
      "N/A",
    ]),
  )
  @debug.debug_inspect(
    nulls.column("a").to_int64_array(),
    content="[Some(1), Some(2), None]",
  )
}
```

### Not supported

These polars options and inputs have no counterpart in the CSV functions:

- `decimal_comma` (reading and writing), `comment_prefix`, `skip_lines`,
  `truncate_ragged_lines`, `ignore_errors`, and the other options listed in
  `docs/golden/known-diffs/csv_read.md`
- encodings other than UTF-8
- `null_values` for one column only (the list applies to every column)
- a date `format` (dates and datetimes are read in the formats of
  `try_parse_dates`, see [Dates](#dates))
- reading from `Bytes`: pass the text, or use `@plfs.read_csv` for a file
- streaming, `scan_csv` and `read_ndjson` / `write_ndjson`; everything is read
  into memory at once

For writing see `docs/golden/known-diffs/csv_write.md`.

### Writing

`write_csv_str(df, options~)` returns the text; every line, the last one
included, ends with the line terminator. A field is quoted when it is empty or
contains the separator, the quote character, `\n` or `\r`; quote characters
inside are doubled.

| Option | Default | Meaning |
| --- | --- | --- |
| `include_header` | `true` | write the column names first |
| `separator` | `','` | any one character except a line break |
| `line_terminator` | `"\n"` | the end of every line |
| `quote_char` | `'"'` | |
| `quote_style` | `Necessary` | `Necessary`, `Always`, `NonNumeric` (quote strings, booleans, dates, datetimes and names) or `Never` |
| `null_value` | `""` | what a null looks like |
| `include_bom` | `false` | start with a UTF-8 byte order mark |

Floats are written in the shortest form that reads back exactly (`1.0`, `0.1`,
`1e+20`, `NaN`, `inf`, `-0.0`), dates as `2024-01-02` and datetimes as
`2024-01-02T03:04:05.000000`.

```mbt check
///|
test "csv: write text" {
  let df = @pl.DataFrame::new([
    @pl.Series::str_nullable("note", [Some("a,b"), None, Some("say \"hi\"")]),
    @pl.Series::float64("x", [1.0, 0.1, 0.0 / 0.0]),
  ])
  assert_eq(
    @pl.write_csv_str(df),
    "note,x\n\"a,b\",1.0\n,0.1\n\"say \"\"hi\"\"\",NaN\n",
  )
  assert_eq(
    @pl.write_csv_str(
      df,
      options=@pl.CsvWriteOptions::new(
        separator=';',
        null_value="NA",
        line_terminator="\r\n",
      ),
    ),
    "note;x\r\na,b;1.0\r\nNA;0.1\r\n\"say \"\"hi\"\"\";NaN\r\n",
  )
}
```

A field that contains the separator is always quoted, numbers and dates
included (polars writes them as they are, which breaks the row for a
separator such as `.`). `Never` writes no quotes at all and cannot be read
back when a value needs them. Under `Always` a null is written as `""`, so it
is read back as null only with `null_values=[""]` (which also turns real empty
strings into null).

### Round trips

`read_csv_str(write_csv_str(df), options~)` gives back `df` when
`schema_overrides` names the type of every column. Without them the reader
sniffs the text, so a `String` column of `"007"` comes back `Int64`
(`7`), `Int32` comes back `Int64`, `Float32` comes back `Float64`, `Date` and
`Datetime` come back `String` (unless `try_parse_dates=true`), and a `Null`
column or an `Int64` column with no value comes back as a `String` column of
nulls. A `Null` column cannot be overridden. A table with no rows comes back
with `String` columns; a table with no columns writes one empty line, which is
not a CSV (`ParseError`: `empty CSV`).

```mbt check
///|
test "csv: a round trip with overrides" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("code", ["007", "x,y"]),
    @pl.Series::date("day", [19000, -1]),
    @pl.Series::float64("v", [-0.0, 5.0e-324]),
  ])
  let text = @pl.write_csv_str(df)
  assert_eq(
    text, "code,day,v\n007,2022-01-08,-0.0\n\"x,y\",1969-12-31,5e-324\n",
  )
  let back = @pl.read_csv_str(
    text,
    options=@pl.CsvReadOptions::new(schema_overrides={
      "code": String,
      "day": Date,
      "v": Float64,
    }),
  )
  assert_true(back.equals(df))
  // without overrides "007" turns into the integer 7 and the date into text
  @debug.debug_inspect(
    @pl.read_csv_str(text).dtypes(),
    content="[String, String, Float64]",
  )
}
```

The reader reads years -262143 to 262142 (the range of the calendar library
polars uses). The writer formats `Date` values up to 110 000 000 days from
1970 and every `Datetime`, so a date or datetime beyond that range is written
but read back as a `ParseError`.

### Files

The file functions live in a separate package so that `@pl` stays free of
file system code. Import it in `moon.pkg` next to `@pl`; the alias is yours to
choose (it is `@plfs` here):

```
import {
  "smallbearrr/pandas/pl" @pl,
  "smallbearrr/pandas/pl/fs" @plfs,
}
```

```mbt nocheck
///|
fn example() -> Unit raise Error {
  let df = @plfs.read_csv(
    "data/in.csv",
    options=@pl.CsvReadOptions::new(separator=';'),
  )
  @plfs.write_csv(
    df,
    "data/out.csv",
    options=@pl.CsvWriteOptions::new(include_bom=true),
  )
}
```

A file that cannot be read or written is a `PolarsError`, like every other
problem. `IOError(msg)` carries the text of the operating system, including the
path, and `e.to_string()` is `IOError: <msg>`. You do not need to import
`moonbitlang/x` to handle it:

```mbt nocheck
///|
fn load(path : String) -> Unit {
  try @plfs.read_csv(path) catch {
    @pl.IOError(msg) => println("cannot read the file: \{msg}")
    @pl.ParseError(msg) => println("not a valid CSV: \{msg}")
    e => println("failed: \{e}")
  } noraise {
    df => println(df)
  }
}
```

- `read_csv(path, options~)` reads the whole file, decodes it as strict UTF-8
  and calls `read_csv_str`. A file that is not UTF-8 is
  `ParseError("invalid utf-8 sequence")`. A byte order mark is removed by
  `read_csv_str`. `\r\n` files work.
- `write_csv(df, path, options~)` writes `write_csv_str`'s text as UTF-8,
  creating the file or replacing its content. The directory must exist. A string
  that holds a lone surrogate cannot be encoded as UTF-8: `write_csv` raises
  `ComputeError` and leaves the file alone, while `write_csv_str` returns the
  string as usual.
- Both functions raise `PolarsError`: `IOError` for file system problems (a
  missing file, a missing directory, no permission), `ParseError` and
  `InvalidOperation` for the text and the options, `ComputeError` as above.
- They work on native, js, wasm and wasm-gc. On js the package uses
  `import ... from "node:fs"`, so Node has to load the output as an ES module;
  if it reports `Cannot use import statement outside a module`, set
  `link: { "js": { "format": "cjs" } }` in the `moon.pkg` of your program.
- The snippets above are not checked examples because `@pl` cannot depend on
  `@plfs`; the file functions are tested in `src/pl/fs/csv_test.mbt`.

## Error handling

Errors are values of the `PolarsError` suberror; match on the variant.

```mbt check
///|
test "errors" {
  let s = @pl.Series::int32("n", [1, 2, 3])
  try s.get(3) catch {
    @pl.OutOfBounds(msg) =>
      inspect(msg, content="index 3 is out of bounds for sequence of length 3")
    _ => fail("expected OutOfBounds")
  } noraise {
    _ => fail("expected an error")
  }
  let text = @pl.Series::str("t", ["1", "x"])
  try text.cast(Int64) catch {
    @pl.InvalidOperation(msg) =>
      inspect(
        msg,
        content="conversion from `str` to `i64` failed in column 't' for 1 out of 2 values: [\"x\"]",
      )
    _ => fail("expected InvalidOperation")
  } noraise {
    _ => fail("expected an error")
  }
}
```


## Good to know

The package follows polars 2.1.0; the full list of differences is in
`docs/migration.md`. These are the ones people meet first.

- **`fill_null` has three shapes.** `Series::fill_null` takes an
  `AnyValue`, while `Expr::fill_null` and `DataFrame::fill_null` take an
  expression (`lit_int(0)`, or a column).
- **A `Series` has no `str()` or `dt()`.** Put it in a table and use the
  expression namespaces.
- **Mixed `&` and `|` need parentheses**: `(a & b) | c`. MoonBit warns about
  the ambiguous precedence otherwise.
- **`lit_int(1)` and friends adapt to the other operand**, as polars'
  literals do. On their own they are `i64` and `f64` (polars: `i32`).
- **`head` and `tail` default to 5 rows for a `DataFrame` and 10 for a
  `Series`**, as in polars.
- **There is no `List` type.** Inside `group_by(...).agg(...)` every
  expression must give one value per group; anything that polars would turn
  into a `list` column raises `InvalidOperation` (see
  [group_by and agg](#group_by-and-agg)). `explode` is not provided for the
  same reason.
- **Row order is always deterministic.** Groups come out in order of first
  appearance, joins follow the left table (the right one for `Right`),
  `value_counts` lists values by first appearance. polars guarantees this only
  with `maintain_order`, which this package does not need.
- **`over` takes `partition_by` only**: no `order_by`, no `mapping_strategy`.
- **Keys are expressions**: `group_by([col("a")])`, `join(on=[col("a")])`,
  not plain strings.
- **CSV reads only an empty field as null, and looks at 100 records to pick the
  types.** `NA` and `N/A` are text, and a bad value after the window is a
  `ParseError`: use `null_values`, `schema_overrides` or
  `infer_schema_length=None` (see [CSV](#csv)). An integer beyond `Int64`
  makes the column a `String` unless floats are in the window (details above). `try_parse_dates` has no `format` option. What
  CSV does not support is listed under [Not supported](#not-supported), and the
  details are in `docs/golden/known-diffs/csv_read.md` and `csv_write.md`.

```mbt check
///|
test "differences you meet first" {
  // fill_null: AnyValue on a Series, an expression on a table
  let s = @pl.Series::int64_nullable("a", [Some(1L), None])
  @debug.debug_inspect(
    s.fill_null(@pl.AnyValue::Int64(0L)).to_int64_array(),
    content="[Some(1), Some(0)]",
  )
  let df = @pl.DataFrame::new([s])
  @debug.debug_inspect(
    df.fill_null(@pl.lit_int(0)).column("a").to_int64_array(),
    content="[Some(1), Some(0)]",
  )
  // text functions on a Series go through a table
  let t = @pl.Series::str("t", ["ab", "cd"])
  let upper = t
    .to_frame()
    .select([@pl.col("t").str().to_uppercase()])
    .column("t")
  @debug.debug_inspect(
    upper.to_str_array(),
    content="[Some(\"AB\"), Some(\"CD\")]",
  )
  // head defaults
  let long = @pl.Series::int64("n", Array::makei(20, i => i.to_int64()))
  inspect(long.head().len(), content="10")
  inspect(long.to_frame().head().height(), content="5")
}
```
