# `smallbearrr/pandas/pl`

A polars-style data layer for MoonBit: typed, nullable, immutable columns
(`Series`) grouped into a `DataFrame`, plus expressions (`Expr`) to describe
what to compute and eager operations that run them: `select`,
`with_columns`, `filter`, `sort`, aggregation, `unique`, `concat`,
`describe`, `cast` and printing.

Every fallible call raises `PolarsError`; nothing aborts on bad user input.
Coming from the old `lib/pandas` package? See `docs/migration.md`. Not here
yet: `group_by`, joins and CSV (planned).

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
| handle nulls | [Missing values](#missing-values) |
| text and dates | [Strings and dates](#strings-and-dates) |
| stack tables, drop duplicates, summarize | [concat, unique and describe](#concat-unique-and-describe) |
| work on one column without a table | [Series operations](#series-operations) |
| change a type | [Cast](#cast) |
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
  let e = (@pl.col("age") * @pl.lit_int(2L) + @pl.lit_int(1L)).alias("x")
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
    df.with_columns([(@pl.col("age") + @pl.lit_int(1L)).alias("next_age")]),
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
    .with_columns([(@pl.col("age") * @pl.lit_int(2L)).alias("age")])
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
      @pl.col("age").ge(@pl.lit_int(30L)) & @pl.col("score").is_not_null(),
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

A literal such as `lit_int(1L)` adapts to the other operand: `Int32 column +
lit_int(1L)` stays `i32`, and a value that does not fit widens the result to
`i64` instead of wrapping. A literal on its own is `i64` (`lit_int`) or `f64`
(`lit_float`).

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
  let band = @pl.when(@pl.col("age").ge(@pl.lit_int(30L)))
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
`len_bytes` and `strip_chars` (with `_start` / `_end` variants). `contains`
and `replace` take a regular expression unless you pass `literal=true`; the
engine is MoonBit's `Regex`, whose syntax is close to but not the same as
Rust's (see `docs/migration.md`). `e.dt()` gives `year`, `month`, `day`,
`hour`, `minute`, `second`, `weekday` and `ordinal_day` for `Date` and
`Datetime` columns.

```mbt check
///|
test "str and dt namespaces" {
  let df = @pl.DataFrame::new([
    @pl.Series::str("name", ["Ann", "bob", "Cy"]),
    @pl.Series::date("born", [0, 365, 19000]),
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
  try df.select([@pl.col("name") + @pl.lit_int(1L)]) catch {
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
  expression (`lit_int(0L)`, or a column).
- **A `Series` has no `str()` or `dt()`.** Put it in a table and use the
  expression namespaces.
- **Mixed `&` and `|` need parentheses**: `(a & b) | c`. MoonBit warns about
  the ambiguous precedence otherwise.
- **`lit_int(1L)` and friends adapt to the other operand**, as polars'
  literals do. On their own they are `i64` and `f64` (polars: `i32`).
- **`head` and `tail` default to 5 rows for a `DataFrame` and 10 for a
  `Series`**, as in polars.

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
    df.fill_null(@pl.lit_int(0L)).column("a").to_int64_array(),
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
