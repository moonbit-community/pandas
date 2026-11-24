# Migrating from `lib/pandas` to `@pl`

`smallbearrr/pandas/pl` (`@pl`) replaces `smallbearrr/pandas/lib/pandas`. It
follows [polars](https://pola.rs) instead of pandas, so a few ideas change:

- **Columns are immutable.** Every operation returns a new `Series` or
  `DataFrame`; nothing is modified in place (`inplace~` flags, `add_row`,
  `drop_row`, `sort` returning `Unit`, ... are gone). Copies are cheap because
  columns are shared, not copied.
- **Operations are expressions.** Instead of `filter(name, closure)` or
  `select_columns`, you write `df.filter(col("a").gt(lit_int(1)))` or
  `df.select([col("a"), (col("b") * lit_float(2.0)).alias("c")])`. See
  `src/pl/README.mbt.md`.
- **More types.** `Boolean`, `Int32`, `Int64`, `Float32`, `Float64`, `String`,
  `Date`, `Datetime` and `Null` (the old package had `Bool`, `Int32`,
  `Float32`, `String`). Plain integers are `Int64` and plain floats `Float64`
  where the type is not forced by a column.
- **Nulls are first class** (a validity bitmap, not a sentinel), and null,
  NaN and ordering rules follow polars.
- **One error type.** Every fallible call is `raise PolarsError` with the
  variants `ColumnNotFound`, `DuplicateColumn`, `SchemaMismatch`,
  `ShapeMismatch`, `OutOfBounds`, `InvalidOperation`, `ComputeError` and
  `ParseError`. User errors never abort.
- **Abstract types.** `Series`, `DataFrame` and `Expr` have no public fields.

Status words used below:

| Status | Meaning |
| --- | --- |
| Available | Same idea, same or very similar name; differences are noted. |
| Changed | Available under a different shape (immutable result, other name, other arguments). |
| M4 | Arrives with CSV input and output (M4). |
| Not provided | Intentionally absent; see [Not provided on purpose](#not-provided-on-purpose). |

Examples assume `using @pl { col, lit_int, lit_float, lit_str, lit_bool }` or
the `@pl.` prefix.

## DataFrame

| Old (`lib/pandas`) | Status | New (`@pl`) |
| --- | --- | --- |
| `DataFrame::new` | Available | `DataFrame::new(Array[Series])`; raises `ShapeMismatch` for unequal lengths and `DuplicateColumn` for repeated names (the old `InconsistentSeriesLength`), with the text and the order of checks of `pl.DataFrame([...])` (`could not create a new DataFrame: height of column 'b' (2) does not match height of column 'a' (3)`). Also `DataFrame::empty()` |
| `DataFrame::add_column` | Changed | `df.hstack([series])` returns a new frame; `df.with_columns([expr.alias("c")])` adds a computed column |
| `DataFrame::add_row` | Not provided | `df.vstack(one_row_frame)` or `concat([df, one_row_frame])`. Every `vstack` copies all the data, so a loop of `acc = acc.vstack(row)` is quadratic (1000 calls on 1000-row chunks took about 30 s, against 52 ms for one `concat` of the same chunks): collect the frames and call `concat` once |
| `DataFrame::all` | Changed | `df.select([all().all()])`, or `col("c").all()` for one column: `Expr::all(ignore_nulls=true)` gives one `Boolean`. Unlike the old one it also accepts numbers (`value != 0`), and null follows Kleene logic with `ignore_nulls=false` |
| `DataFrame::any` | Changed | `df.select([all().any()])`, or `col("c").any()`; same rules as `all` |
| `DataFrame::cast` | Changed | `df.with_columns([col("a").cast(Int64)])`; every column: `df.select([all().cast(Float64)])`; `strict=false` turns failures into null |
| `DataFrame::clear` | Changed | `df.head(n=0)` keeps the schema and drops the rows. The old `n` null-filled rows has no equivalent |
| `DataFrame::clone` | Not provided | not needed: frames are immutable and share their columns |
| `DataFrame::column` | Available | `df.column(name)` raises `ColumnNotFound` |
| `DataFrame::count` | Changed | `df.shape()`, a `(rows, columns)` tuple |
| `DataFrame::data` | Changed | `df.get_columns()` (all columns), `df.columns()` (names) |
| `DataFrame::drop_column` | Changed | `df.drop([name])` returns a new frame; `strict=false` ignores missing names |
| `DataFrame::drop_in_place` | Changed | `df.column(name)` to read it and `df.drop([name])` for the rest |
| `DataFrame::drop_nulls` | Available | `df.drop_nulls(subset=["a"])`; `subset? : Array[String]` |
| `DataFrame::drop_row` | Not provided | `df.filter(...)`, or `df.gather(indices)` with the rows you keep |
| `DataFrame::dtypes` | Changed | returns `Array[DataType]` (the old one returned strings); `DataType::to_string()` gives the name |
| `DataFrame::fill_null` | Changed | value: `df.fill_null(lit_int(0))` (an `Expr`; `Series::fill_null` takes an `AnyValue`, see [Operations](#operations)); strategy: `df.fill_null_strategy(Forward, limit=2)` with the `FillStrategy` enum (`Forward`, `Backward`, `Min`, `Max`, `Mean`, `Zero`, `One`) instead of strings |
| `DataFrame::filter` | Changed | takes an expression, not a closure: `df.filter(col("a").gt(lit_int(1)))` |
| `DataFrame::from_NyaCSV` | M4 | `@pl.read_csv_str` |
| `DataFrame::gather_every` | Available | `df.gather_every(n, offset=0)`; raises `InvalidOperation` for `n = 0` as polars does |
| `DataFrame::get_column_index` | Changed | returns `Int32?` (`None` when the column does not exist) instead of raising |
| `DataFrame::has_nulls` | Changed | `df.null_count()` is a one-row frame of per-column null counts |
| `DataFrame::head` | Changed | `df.head(n=5)` returns a frame (default 5, as in polars 2.1.0 and as the old default); the old one printed its rows and returned `Unit`. Print with `println(df)`. `Series::head` defaults to 10 (polars) |
| `DataFrame::height` | Available | `df.height()` |
| `DataFrame::hstack` | Changed | `df.hstack(columns : Array[Series])`; for a frame use `df.hstack(other.get_columns())`. Always returns a new frame |
| `DataFrame::is_empty` | Changed | `df.height() == 0` |
| `DataFrame::item` | Changed | `df.get(row, "name")` returns an `AnyValue`; by position `df.get_columns()[j].get(i)`. `ColumnSelector` is gone |
| `DataFrame::limit` | Changed | `df.head(n=n)` |
| `DataFrame::max` | Changed | `df.select([all().max()])` (or `cols([...])` to pick columns) |
| `DataFrame::max_horizontal` | Changed | `df.select([max_horizontal([col("a"), col("b")])])`, or `max_horizontal([all()])` for every column; nulls are skipped and NaN loses against a number |
| `DataFrame::min` | Changed | `df.select([all().min()])` |
| `DataFrame::min_horizontal` | Changed | `df.select([min_horizontal([col("a"), col("b")])])` |
| `DataFrame::null_count` | Available | `df.null_count()`, one row of `Int64` counts |
| `DataFrame::op_get` | Changed | `df.slice(i, length=1)` is a one-row frame; `df.row(i)` is `Array[AnyValue]`. Negative `i` counts from the end |
| `DataFrame::product` | Changed | `df.select([all().product()])` |
| `DataFrame::read_csv` | M4 | `@plfs.read_csv` |
| `DataFrame::rename` | Changed | `df.rename({"old": "new"})` takes a `Map` and returns a new frame |
| `DataFrame::replace_column` | Changed | `df.with_columns([expr.alias(name)])` replaces a column in place of its position; `df.drop([name]).hstack([series])` appends the series instead |
| `DataFrame::reverse` | Changed | `df.select([all().reverse()])` |
| `DataFrame::schema` | Changed | returns `Array[(String, DataType)]` in column order (the old one was `Map[String, String]`) |
| `DataFrame::select_columns` | Changed | `df.select([col("a"), col("b")])` or `df.select([cols(["a", "b"])])` |
| `DataFrame::select_rows` | Changed | `df.slice(offset, length=n)` for a range, `df.gather(indices)` for indices, `df.filter(...)` for a condition |
| `DataFrame::shape` | Changed | returns a tuple `(Int32, Int32)` instead of `Array[Int32]` |
| `DataFrame::slice` | Available | `df.slice(offset, length=n)`; never raises, clips to the table, negative offset counts from the end |
| `DataFrame::sort` | Changed | `df.sort([col("a")], descending=[true], nulls_last=true)` returns a new frame; keys are expressions, several keys allowed; always stable |
| `DataFrame::sum` | Changed | `df.select([all().sum()])` (numeric columns; pick with `cols([...])`) |
| `DataFrame::sum_horizontal` | Changed | `df.select([sum_horizontal([col("a"), col("b")])])`; nulls count as zero unless `ignore_nulls=false` |
| `DataFrame::tail` | Changed | `df.tail(n=5)` (default 5 as in polars; the old `tail(n)` had no default). `Series::tail` defaults to 10 (polars) |
| `DataFrame::to_NyaCSV` | M4 | `@pl.write_csv_str` |
| `DataFrame::to_dict` | Changed | `df.to_dict()` returns `Map[String, Series]`, the columns by name (always the series; use `Series::to_list` for values) |
| `DataFrame::to_init_repr` | Not provided | printing is `df.to_string()` / `println(df)` (polars-style table) |
| `DataFrame::to_series` | Changed | `df.get_columns()[i]` by position, `df.column(name)` by name |
| `DataFrame::transpose` | Available | `df.transpose(include_header=false, header_name="column", column_names?)`; every column is cast to their common type. A frame with no rows gives shape `(0, 0)` where polars gives `(n, 0)` (see [Differences](#differences-from-polars)) |
| `DataFrame::unique` | Changed | `df.unique(subset=["a"], keep=First, maintain_order=true)` with the `UniqueKeep` enum (`Any`, `First`, `Last`, `KeepNone`) instead of a string |
| `DataFrame::vstack` | Changed | `df.vstack(other)` returns a new frame and copies all the data on every call; use `concat([a, b, c], how=Vertical)` once for many frames, not `vstack` in a loop |
| `DataFrame::width` | Available | `df.width()` |
| `DataFrame::with_row_index` | Changed | `df.with_row_index(name="index", offset=0)`; the column is `Int64` |
| `DataFrame::write_csv` | M4 | `@plfs.write_csv` |
| `impl Hash for DataFrame` | Not provided | compare with `df.equals(other)` or `==` |
| `impl Show for DataFrame` | Changed | `Show` prints a polars-style table with `shape`, dtype row and folded rows |
| `DataFrame` (the struct and its fields `data`, `shape`, `index`) | Changed | abstract type; use `get_columns()`, `shape()`, `get_column_index(name)` |

## Series

| Old (`lib/pandas`) | Status | New (`@pl`) |
| --- | --- | --- |
| `Series::new` | Changed | typed constructors: `Series::int32`, `int64`, `float32`, `float64`, `bool`, `str`, `date`, `datetime`, each with a `_nullable` variant taking `Option` elements; `Series::null(name, n)`; `Series::from_any_values` |
| `Series::abs` | Available | `s.abs()`; on a column `col("a").abs()`. Raises `InvalidOperation` on `Boolean`, `String`, `Date`, `Datetime` |
| `Series::acos` | Changed | `s.arccos()` (polars name); also `arcsin`, `arctan`. Raises `InvalidOperation` on non-numeric types. On a column: `col("a").arccos()` |
| `Series::all` | Changed | `s.all(ignore_nulls=true)` returns `Bool?` (`None` when the answer is null) and raises `SchemaMismatch` for a non-`Boolean` series (polars). `col("a").all()` also accepts numbers |
| `Series::any` | Changed | `s.any(ignore_nulls=true)` returns `Bool?`; same rules as `all` |
| `Series::append` | Available | `s.append(other)` returns a new series; types must match |
| `Series::argsort` | Changed | `s.arg_sort(descending=, nulls_last=)` returns an `Int64` series; `to_int64_array()` for an array |
| `Series::clear` | Changed | `s.head(n=0)` |
| `Series::concat` | Changed | `a.append(b).append(c)`; for frames `@pl.concat` |
| `Series::copy` | Not provided | not needed: series are immutable |
| `Series::cos` | Available | `s.cos()`, `col("a").cos()`. The result can differ from polars by one unit in the last place |
| `Series::count` | Changed | `s.count()` now counts the non-null values (polars); the old one returned the length, which is `s.len()` |
| `Series::data` | Changed | `s.to_list()` gives `Array[AnyValue]`; typed arrays: `to_int32_array()`, `to_int64_array()`, `to_float32_array()`, `to_float64_array()`, `to_bool_array()`, `to_str_array()` (elements are options, `None` is null) |
| `Series::erase` | Not provided | `s.filter(mask)` or `s.gather(indices)` |
| `Series::extend_from` | Not provided | `s.append(other)` returns the longer series |
| `Series::get_argsort_indices` | Changed | `s.arg_sort(descending=, nulls_last=)` |
| `Series::get_type` | Changed | `s.dtype()` |
| `Series::has_null` | Changed | `s.null_count() > 0` |
| `Series::is_empty` | Available | `s.is_empty()` |
| `Series::is_not_null` | Available | `s.is_not_null()` |
| `Series::is_null` | Available | `s.is_null()` |
| `Series::is_sorted` | Available | `s.is_sorted(descending=false, nulls_last=false)` returns `Bool` |
| `Series::length` | Changed | `s.len()` |
| `Series::log` | Available | `s.log(base=2.0)` (default base e); raises `InvalidOperation` on non-numeric types |
| `Series::log10` | Changed | `s.log(base=10.0)` |
| `Series::lower_bound` | Not provided | not scheduled |
| `Series::max` | Available | `s.max()` returns an `AnyValue` |
| `Series::mean` | Changed | `s.mean()` returns an `AnyValue` (`Float64`, or null for an empty series) |
| `Series::merge` | Changed | `s.append(other)` (no `inplace~`) |
| `Series::min` | Available | `s.min()` returns an `AnyValue` |
| `Series::move_nulls_back` | Not provided | not scheduled; `s.sort(nulls_last=true)` also sorts the other values |
| `Series::move_nulls_front` | Not provided | not scheduled |
| `Series::n_unique` | Changed | `s.n_unique()`; null now counts as a distinct value (polars). The old one ignored nulls |
| `Series::name` | Available | `s.name()`; `s.rename("x")` returns a renamed series |
| `Series::not_` | Available | `s.not_()` raises on non-`Boolean` input |
| `Series::null_count` | Available | `s.null_count()` |
| `Series::op_get` | Changed | `s.get(i)` returns an `AnyValue` and raises `OutOfBounds`; negative `i` counts from the end |
| `Series::reverse` | Changed | `s.reverse()` returns a new series |
| `Series::sin` | Available | `s.sin()`, `col("a").sin()` (same last-place caveat as `cos`) |
| `Series::slice` | Changed | `s.slice(offset, length=n)`: the second argument is a **length**, the old one was an end index |
| `Series::sort` | Changed | `s.sort(descending=, nulls_last=)` returns a new series |
| `Series::sum` | Available | `s.sum()` returns an `AnyValue`; integers wrap on overflow |
| `Series::swap` | Not provided | `s.gather(indices)` with the permutation |
| `Series::tan` | Available | `s.tan()`, `col("a").tan()` |
| `Series::unique_counts` | Available | `s.unique_counts()` returns the `Int64` count of each distinct value, in order of first appearance (polars promises no order). See also `s.value_counts(sort=, name=, normalize=)`, a two-column frame |
| `Series::upper_bound` | Not provided | not scheduled |
| `Series::variance` | Changed | `s.var_(ddof=1)`; `var` is a MoonBit keyword. Also `s.std(ddof=1)` |
| `impl Add for Series` | Changed | `s.add(other)` raises `PolarsError`; operators exist only on `Expr` (core's `Add` cannot raise) |
| `impl Sub for Series` | Changed | `s.sub(other)` |
| `impl Mul for Series` | Changed | `s.mul(other)` |
| `impl Div for Series` | Changed | `s.div(other)` (true division, `Float64`); `floor_div`, `rem` also exist |
| `impl Hash for Series` | Not provided | compare with `s.equals(other)` or `==` |
| `Series` (derives `Eq`, `Show`, `Debug`) | Available | `Eq`, `Show` and `Debug` are implemented; `==` treats null as equal to null and NaN as equal to NaN |

## SeriesData

The old public `SeriesData` (a variant over typed arrays) is replaced by an
internal column type; read values through `Series`.

| Old (`lib/pandas`) | Status | New (`@pl`) |
| --- | --- | --- |
| `SeriesData::clear` | Not provided | `s.head(n=0)` |
| `SeriesData::get_argsort_indices` | Changed | `s.arg_sort(...)` |
| `SeriesData` (the type) | Changed | `Series::to_list()` and the typed `to_*_array()` methods |

## Types, enums and errors

| Old (`lib/pandas`) | Status | New (`@pl`) |
| --- | --- | --- |
| `DataType` (`Int32`, `Float32`, `String`, `Bool`) | Changed | `DataType` with `Boolean`, `Int32`, `Int64`, `Float32`, `Float64`, `String`, `Date`, `Datetime`, `Null`; `Bool` is now `Boolean`. Predicates `is_integer`, `is_float`, `is_numeric`, `is_temporal` |
| `ColumnSelector` (`Int`, `Str`) | Not provided | columns are addressed by name (`col("a")`, `df.column("a")`) or by position through `get_columns()` |
| `SeriesInput` (`Int32`, `Float32`, `Bool`, `Str` and their `_Nullable` forms) | Changed | the typed constructors `Series::int32`, `float32`, `bool`, `str` and the `_nullable` versions |
| `SeriesValue` (`Int`, `Float`, `Bool`, `Str`, `Null`) | Changed | `AnyValue` (`Null`, `Boolean`, `Int32`, `Int64`, `Float32`, `Float64`, `String`, `Date`, `Datetime`) |
| `ColumnNotFoundError` | Changed | `PolarsError::ColumnNotFound(String)` |
| `InconsistentSeriesLength` | Changed | `PolarsError::ShapeMismatch(String)` (and `DuplicateColumn` for repeated names) |
| `IndexOutOfBounds` | Changed | `PolarsError::OutOfBounds(String)` |
| `InvalidType` | Changed | `PolarsError::InvalidOperation(String)` for an operation the type does not support, `SchemaMismatch(String)` for incompatible types |

## Not provided on purpose

- **In-place row and column edits**: `add_row`, `drop_row`, `drop_column`,
  `drop_in_place`, `add_column`, `replace_column`, `rename`, `reverse`, `sort`
  (the `Unit` versions), `Series::swap`, `Series::erase`, `Series::extend_from`,
  `Series::merge(inplace=true)`. They conflict with immutability. The
  replacements are in the tables above: `vstack` / `concat` add rows,
  `filter` / `gather` / `slice` select or remove them, `hstack` /
  `with_columns` / `drop` / `rename` change columns, and every one of them
  returns a new value.
- **Copies**: `clone` and `copy`. A shared immutable column cannot be
  affected by anyone else, so there is nothing to protect.
- **Internal representation helpers**: `to_init_repr`, the public
  `SeriesData`, `ColumnSelector` and `SeriesInput` variants, and the public
  fields of `DataFrame`. They only existed to serve the old implementation.
- **Hashing**: `Hash` for `DataFrame` and `Series`. Use `equals`.
- **`lower_bound`, `upper_bound`, `move_nulls_front`, `move_nulls_back`**: no
  polars-style replacement is scheduled. Say so if you need one.
- **`explode` and anything that returns a list per group** (`agg` of a bare
  column, `over(mapping_strategy="join")`): they need a `List` type, which
  `@pl` does not have. Aggregate to one value per group, or `join` the
  aggregate back to the table. To keep the rows, use a window instead: `rank().over([...])` and `filter` give the top N rows of each group (see the idiom table above).

## polars convenience functions

The old package already offered some of these polars functions; the rest arrived with M3. Status in `@pl`:

| polars | Status | Notes |
| --- | --- | --- |
| `product` | Available | `Series::product`, `Expr::product`, `df.select([all().product()])` |
| `reverse` | Available | `Series::reverse`, `Expr::reverse` |
| `arg_sort` | Available | `Series::arg_sort`, `Expr::arg_sort(descending=, nulls_last=)` (an `Int64` column; polars gives `UInt32`) |
| `sort`, `sort_by`, `head`, `tail`, `slice`, `unique`, `drop_nulls`, `filter` | Available | on `Expr`, next to the `Series` and `DataFrame` versions. They change the length of a column: see [Operations](#operations) |
| `any`, `all` | Available | `Series::any/all` (`Boolean` only, `Bool?` result: write `s.any() == Some(true)`, since `if s.any()` does not compile), `Expr::any/all(ignore_nulls=true)`; for a frame `df.select([all().any()])` |
| `is_sorted` | Available | `Series::is_sorted` |
| `gather_every` | Available | `Series::gather_every(n, offset=0)`, `DataFrame::gather_every` |
| `sin`, `cos`, `tan`, `arcsin`, `arccos`, `arctan` | Available | `Series` and `Expr`, next to `exp`, `log`, `sqrt` (the old `acos` is `arccos`). Can differ from polars by one unit in the last place |
| `sum_horizontal`, `min_horizontal`, `max_horizontal` | Available | functions that take `Array[Expr]`: `sum_horizontal([col("a"), col("b")], ignore_nulls=true)` |
| `transpose`, `to_dict` | Available | `DataFrame::transpose`, `DataFrame::to_dict` (a `Map[String, Series]`) |
| `pivot`, `unpivot` | Available | `DataFrame::pivot(on, index=, values=, aggregate_function=PivotAgg, sort_columns=, separator=)`, `DataFrame::unpivot(on=, index=, variable_name=, value_name=)`; `on`, `index` and `values` are column names |
| `unique_counts`, `value_counts` | Available | `Series::unique_counts`, `Series::value_counts(sort=, name=, normalize=)` |
| `pl.len()` | Available | `len()`, the number of rows (in `agg`, of the group) |
| `group_by`, `agg`, `over` | Available | `df.group_by([col("k")]).agg([...])`, `expr.over([col("k")])` |
| `join` | Available | `df.join(other, on=[col("k")], how=Inner)` with `JoinHow` `Inner`, `Left`, `Right`, `Full`, `Semi`, `Anti`, `Cross` |
| `explode` | Not provided | needs a `List` type, which this package does not have |
| `read_csv`, `write_csv` | M4 | `@pl.read_csv_str`, `@pl.write_csv_str`, `@plfs.read_csv`, `@plfs.write_csv` |

### Grouping, joining and reshaping (new in M3)

The old package had no `group_by`, `join` or reshaping functions. If you
come from pandas or from polars, these are the spellings:

| Idea | pandas | `@pl` |
| --- | --- | --- |
| aggregate per group | `df.groupby("k").agg(...)` | `df.group_by([col("k")]).agg([col("v").sum(), col("v").mean().alias("m"), len()])`; group sizes only: `df.group_by([col("k")]).len()` |
| keys sort, null keys | `groupby("k")` sorts the keys and drops rows whose key is null (`dropna=True`) | groups come out in first-appearance order and null is a group of its own; add `.sort([col("k")])` for sorted keys and `df.drop_nulls(subset=["k"])` before the `group_by` to drop null keys |
| one column, two aggregations | `groupby("k")["v"].agg(["sum", "mean"])` | `agg([col("v").sum().alias("v_sum"), col("v").mean().alias("v_mean")])`: an aggregation keeps its column's name, so without `alias` the second one raises `DuplicateColumn: column with name 'v' has more than one occurrence` |
| nulls per group | `groupby("k")["x"].apply(lambda s: s.isna().sum())` | `agg([col("x").is_null().sum()])`; there is no `Expr::null_count` |
| group value next to every row | `groupby("k")["v"].transform("sum")` | `df.with_columns([col("v").sum().over([col("k")])])` |
| rank inside a group | `groupby("k")["v"].rank(method="first", ascending=False)` | `col("v").rank(method_=Ordinal, descending=true).over([col("k")])`; the pandas `method` values are `Average`, `Min`, `Max`, `Dense`, and `"first"` is `Ordinal` (the argument is `method_`, see [Naming](#naming-and-shape-deviations-from-polars)) |
| top N per group | `df.sort_values("v", ascending=False).groupby("k").head(2)` | `df.filter(col("v").rank(method_=Ordinal, descending=true).over([col("k")]).le(lit_int(2)))` (the rows keep the table order; `sort` afterwards if you want them ordered) |
| one row per group, picked by another column | `df.loc[df.groupby("k")["v"].idxmax()]` | `df.group_by([col("k")]).agg([col("id").sort_by([col("v")], descending=[true]).first()])` |
| all the values of a group | `groupby("k")["v"].apply(list)`, `agg(list)` | not available (no `List` type, see below); keep the rows and cut them with a window (`rank().over`, then `filter`), or aggregate to one value |
| join on a key | `a.merge(b, on="k", how="left")` | `a.join(b, on=[col("k")], how=Left)`; different names: `left_on=[...], right_on=[...]` |
| rows of `a` with or without a match in `b` | `a[a.k.isin(b.k)]` | `a.join(b, on=[col("k")], how=Semi)` / `how=Anti` |
| long to wide | `df.pivot_table(index=, columns=, values=, aggfunc=)` (the default `aggfunc` is `"mean"`) | `df.pivot(["columns"], index=[...], values=[...], aggregate_function=Sum)`. `pivot` has no default: when a cell gets several rows it raises `ComputeError: aggregation 'item' expected no or a single value, got 2 values` (the text does not mention `aggregate_function`), so pass `aggregate_function=Mean` for pandas' behaviour |
| wide to long | `df.melt(id_vars=, value_vars=)` | `df.unpivot(on=[...], index=[...])` |
| count the values | `s.value_counts()` | `s.value_counts(sort=true)`; there is no `Expr::value_counts` or `Expr::unique_counts`: in a table use `df.group_by([col("v")]).len()` |

The things to know when you move code: keys are expressions, not names;
`agg` accepts only expressions that give one value per group (there is no
`List` type, see below); the order of the rows is always deterministic (groups
in first-appearance order, not sorted by key as in pandas, and a null key is a
group); and `over` takes `partition_by` only.

## Naming and shape deviations from polars

These are places where `@pl` spells something differently from polars
because MoonBit does not allow it or the repository has a convention:

| polars | `@pl` | Why |
| --- | --- | --- |
| `var` | `Series::var_`, `Expr::var_` | `var` is a MoonBit keyword; `and_`, `or_`, `not_` follow the same rule |
| `rank(method=...)` | `Series::rank(method_=RankMethod)`, `Expr::rank(method_=...)` | `method` is a reserved word in MoonBit and warns at every call in a downstream package, so the argument takes a trailing underscore, the same convention as `var_`; `RankMethod` is `Average`, `Min`, `Max`, `Dense`, `Ordinal` |
| `quantile(q, interpolation=...)` | `quantile(q, interpolation=QuantileMethod)` | the parameter is `interpolation`, not `method`, because `method` is reserved |
| `unique(keep="none")` | `UniqueKeep::KeepNone` | `None` would clash with `Option` |
| `is_between(closed="none")` | `ClosedInterval::Neither` | same |
| `str.strip_chars(characters)` | `strip_chars(characters?)`, `strip_chars_start`, `strip_chars_end` | optional arguments use `name? : T` (no `Option` wrapper); `strip` is spelled `strip_chars` as in polars |
| `fill_null(strategy=..., limit=None)` | `fill_null_strategy(FillStrategy, limit?)` | enums instead of strings; `limit? : Int` |
| `s.str.contains(...)`, `s.dt.year()` | `col("s").str().contains(...)`, `col("d").dt().year()` | the namespaces exist on `Expr` only; `Series::str` is a constructor |
| `==`, `<` on columns | `eq`, `neq`, `gt`, `ge`, `lt`, `le` | operators cannot return an `Expr`; `&`, `|`, `+ - * / %` and unary `-` are operators on `Expr` |
| `//` | `floor_div` | |
| `~expr` | `not_()` | |
| `Series.op(other)` raising | `s.add(o)`, `s.eq(o)`, `s.and_(o)` ... | no operator traits on `Series` because core's traits cannot raise |
| `descending=True` for many keys | `descending=[true, false]` | a one-element array applies to every key; an empty array means ascending |
| `pl.when(c).then(a).otherwise(b)` | `@pl.when(c).then(a).otherwise(b)` | `otherwise` is required (no implicit null branch) |
| `lit(None, dtype=...)` | `lit(AnyValue::Null).cast(dtype)` | there is no typed null literal |
| Python scalars as weak literals | `lit_int(Int64)`, `lit_float(Double)`, `lit_str`, `lit_bool` | the integer and float forms are "weak" like Python scalars (see below) |

## Differences from polars

`@pl` takes polars 2.1.0 as the reference and checks itself against about
20,700 recorded polars results (`docs/golden/*.json`; each case names the
polars call that produced it). The cases where the two disagree are listed
here. The long form, with the exact inputs, is in `docs/golden/known-diffs/`
(the files for `group_by`, `join`, `expr_shape`, `window`, `reshape` and
`date_parse` are in English; the earlier ones are still in Chinese) and in the
"已知差异" section of `docs/golden/README.md`.

### Deliberately stricter than polars (the design spec wins)

- **No arithmetic on `Boolean`, `String`, `Date`, `Datetime`.**
  `+ - * / // %` on them raise `InvalidOperation`, although polars computes
  many of them (`bool + int`, `str + str` concatenation, `date - date` as a
  duration). `abs`, `sqrt`, `exp`, `log` and `round` on those types raise as
  well. `&`, `|` and `not_` on integers (bitwise in polars) raise
  `InvalidOperation`; they take `Boolean` only.
- **A literal on its own is `Int64` / `Float64`.** `select([lit_int(1)])`,
  `lit_int(1).cum_sum()` and `when(c).then(lit_int(1)).otherwise(lit_int(2))`
  give `i64`, where polars gives `i32` (a "dynamic int"). A literal next to a
  column adapts like a Python scalar in the common cases: `col(i32) + lit_int(1)` is
  `i32`, `col(i32) + lit_int(3_000_000_000L)` is `i64` without wrapping,
  `col(f32) * lit_float(1e300)` is `f32` (infinity). Arithmetic between two
  weak integer literals is done in `Int64` (polars uses 128 bits), so it wraps
  at the `Int64` limits. **The literal stops being weak** when it passes
  through `when/then/otherwise`, `fill_null` or a nested `when` branch: for
  example `col(i32) + when(g).then(lit_int(1)).otherwise(lit_int(2))` is
  `i64` here and `i32` in polars (the values are the same). `when` with a
  condition that is all true or all false also skips polars' type merge, so a
  weak literal in a `when` branch next to a `Date` column can come out as an
  integer here where polars returns the `Date` (`col(date) + lit_int(1)` is an
  error in both). Details in `docs/golden/known-diffs/expr_agg.md`.
- **`diff` on `Date` and `Datetime` raises `InvalidOperation`**: there is no
  `Duration` type yet.
- **Duplicate output names in `with_columns`** raise `DuplicateColumn`
  (polars: `ComputeError`).
- **`Series::equals` compares names and dtypes by default**
  (`check_names=true`, `check_dtypes=true`), to match `==`; polars defaults to
  false for both. `DataFrame::equals` has no flags: it always compares column
  names, order and dtypes (polars' `DataFrame.equals` ignores dtypes). `==` itself treats null as equal to null and NaN
  as equal to NaN; `AnyValue` derives structural `Eq`, so there
  `Float64(NaN) != Float64(NaN)`.

### Types and errors

- **Missing types**: no `UInt8` to `UInt64`, `Int8`, `Int16`, `Int128`,
  `Duration`, `Time`, `Decimal`, `List`, `Struct`, `Categorical`, `Binary`.
  Results polars gives in those types map to `Int64` (for `UInt32`,
  `UInt64`: `count`, `len`, `n_unique`, `arg_sort`, `with_row_index`, `rank`
  except `average`, `str.len_chars`, `cum_count`) and `Int32` (for the 8 and
  16-bit types: `dt.month`, `dt.day`, `dt.weekday`, ...). The mapped results
  keep the mapped type in later steps: arithmetic on them does not wrap like
  an unsigned type (`cum_count(reverse=true) - n_unique()` on 3 rows is
  `[0, -1, -2]` here and `[0, 4294967295, 4294967294]` in polars), and the
  sum of an `Int32` day number stays `Int32` where polars widens `Int8` to
  `Int64`.
- **Strict casts raise `InvalidOperation`**, not `ComputeError` (spec 5.3
  suggests `ComputeError` for a strict cast failure; polars raises
  `InvalidOperationError`, and so does this library); the text is polars'
  (`conversion from `str` to `i64` failed in column 'a' for 1 out of 3 values:
  ["x"]`).
- **The same mistake can be a different `PolarsError` in different
  functions**, because each one copies polars (spec 5.3 defines
  `SchemaMismatch` as "the types do not match" and `InvalidOperation` as "the
  type does not support the operation", but polars is not consistent): a
  string function on a number column is `InvalidOperation` for `contains` /
  `starts_with` / `replace` and `SchemaMismatch` for `to_uppercase` /
  `strip_chars` / `len_chars`; a non-`Boolean` filter mask is
  `SchemaMismatch` for `Series::filter` and `InvalidOperation` for
  `DataFrame::filter`; `&` of a Boolean and a number is `ComputeError` while
  `+` of a date and a number is `InvalidOperation`. Matching on the variant
  alone cannot tell these apart reliably; match on the message when you need
  to.
- **`ColumnNotFound` has two texts**, both polars': the short `"zz" not found`
  and the long `unable to find column "zz"; valid columns: ["id", ...]`. Which
  one you get depends on how the function looks the column up:
  - Short: the functions that take column *names* as strings (`DataFrame::column`
    and `get`, like polars' `df.get_column("zz")`; `drop`, `rename`,
    `drop_nulls`, `unpivot` (`on` and `index`), `pivot` (`index` and `values`)),
    and the selector `cols(["zz"])` in any function, `group_by`, `join` and
    `sort` included.
  - Long: a plain `col("zz")` in an expression, in `select`, `with_columns`,
    `filter`, `sort`, `unique(subset=...)`, `group_by`, `agg`, `join` (`on`,
    `left_on`, `right_on`) and `over`, and the `on` argument of `pivot`.
  The name is quoted as Rust's `Debug` does (`"`, `\`, `\n`, `\r`, `\t`, `\0`
  and `\u{..}` for control, combining and other non-printable characters).
- **`is_in` type errors say `List(...)`** (`'is_in' cannot check for Int64
  values in List(String) data`), polars' wording. The `List(...)` is the
  series you passed as the set of values (the library has no list type).
- **Python-level errors** (`ValueError`, `TypeError`, `OverflowError`) become
  `InvalidOperation` with polars' message, for example a `limit` used with a
  non-directional `fill_null` strategy, a negative `ddof`, a negative `round`
  `decimals`, an out-of-range `describe` percentile. Because `Expr` builders
  cannot raise, the errors polars reports while building an expression are
  reported by `select` / `with_columns` / `filter` instead; an expression you
  build and never evaluate does not complain.
- **Error wording**: the first line of polars' message, with details appended
  after `: ` where polars gives none. `regex error: regex parse error:` is
  followed by the pattern and the engine's hint
  (`regex error: regex parse error: "\d+": Use POSIX character class instead of \w, \W, \d, \D, \s, \S`).
- **Which error wins** when several things are wrong can differ. `select`,
  `with_columns` and `filter` raise the type errors that polars finds while it
  plans (`date * i64`, `~date`, `f64 & date`) before a missing column or a
  duplicate output name, as polars does; which of the two classes an error
  belongs to is decided by its text, so a few rarer pairs can still come out in
  the other order. Beyond that polars evaluates selected expressions in
  parallel (so the reported error is sometimes random), and for several
  columns of a selector reports the last failing one where `@pl` reports the
  first. Behavior for valid input is not affected.
- **A `filter` predicate made of weak literals that cannot be folded**
  (`lit_int(3) % lit_int(0)`, an `Int64` overflow, `null + 1`,
  `lit_int(1) & lit_int(2)`) raises `ComputeError` naming polars' weak type
  (`filter predicate must be of type `Boolean`, got `i32``), except `-null`
  and `null + null`, which are `InvalidOperation` (`got `Null``) as in polars.
- **`DataFrame::filter` with `is_in` of an empty `Series`** returns no rows
  whatever its type, as polars does (it folds the predicate before looking at
  types); `select` and `Series::is_in` raise.

### Operations

- **Sorting and uniqueness are deterministic.** `sort` is always stable
  (polars: only with `maintain_order=true`); `unique(maintain_order=false)`
  still returns first-occurrence order; `UniqueKeep::Any` keeps the first row;
  `Series::sort` and `arg_sort` order `-0.0` and `0.0` by position.
  `is_in` has no `nulls_equal` option; a null in the other series never
  matches.
- **`rank(method="random")`** is not offered (`RankMethod` is `Average`,
  `Min`, `Max`, `Dense`, `Ordinal`). The argument is called `method_` here, as
  `method` is a reserved word: `rank(method_=Dense)`.
- **`shift(fill_value=...)`** takes a typed `AnyValue`, so `Int32` column with
  `AnyValue::Int64(5)` gives `i64` (a Python `5` would keep `i32`).
  `AnyValue::Null` means "no fill".
- **`fill_null(AnyValue::Null)` / `fill_null(lit(Null))`** returns the column
  unchanged (polars' Python `fill_null(None)` raises).
- **`fill_null` takes three kinds of value.** `Series::fill_null(AnyValue)`
  is typed (`AnyValue::Int64(0L)`); `Expr::fill_null(Expr)` and
  `DataFrame::fill_null(Expr)` take an expression, so a plain `0` is
  `lit_int(0)` and a column can fill another. The expression forms use the
  weak literal rules (an `Int32` column filled with `lit_int(0)` stays `i32`);
  `Series::fill_null(AnyValue::Int64(0L))` on an `Int32` column gives `i64`, as
  `shift(fill_value=...)` does. `fill_null_strategy(strategy, limit?)` has one
  shape on all three.
- **A `Series` has no `str()` or `dt()`** (`Series::str` is the constructor).
  Use the table: `s.to_frame().select([col(s.name()).str().to_uppercase()]).column(s.name())`.
- **`Expr` methods that change the length** are `sort`, `sort_by`, `arg_sort`,
  `head`, `tail`, `slice`, `unique`, `drop_nulls` and `filter`; `any` and `all`
  reduce to one value. `is_unique` and `clip` are not provided. The result of
  these methods is a column, not a scalar, even when it has one row: next to
  longer columns in `select` it is a `ShapeMismatch`, as in polars (only
  literals and aggregations are repeated). `unique()` without
  `maintain_order=true` gives first-appearance order here and no defined order
  in polars.
- **`Series::to_array` (spec 5.7) is `to_list()` and the typed `to_*_array()`
  methods**, which keep nulls (`Array[T?]`).
- **`shift` takes `n` by name and defaults to 1**, like polars: `s.shift()` is
  `s.shift(n=1)`, `col("a").shift(n=2)`, `s.shift(fill_value=AnyValue::Int32(0))`.
  (It was a required positional `n` before: `shift(2)` is now `shift(n=2)`.) `diff`
  defaults to 1 too.
- **Hashing is deterministic, not seeded.** `unique`, `n_unique`, `is_in`,
  `DataFrame::unique` and `describe` hash strings with a fixed two-lane 32-bit
  hash and integers with the same scheme; a run is reproducible and never
  random. A multicollision attack on the older 32-bit FNV hash (65,536 strings
  with one hash) made `Series::unique` take 22 s and `is_in` 24 s on native
  (47 s and 33 s on js); the same strings now take 3.7 ms and 7.4 ms on native
  and 14 ms and 25 ms on js. A hash without a per-process seed can in
  principle still be attacked; do not feed untrusted strings to a service
  without a size limit.
- **`vstack` and `append` copy everything on every call**, so adding rows one
  at a time in a loop is quadratic: collect the frames and call `concat` once
  (1000 `vstack` calls on 1000-row chunks took about 30 s; one `concat` of the
  same chunks 52 ms). polars appends chunks without copying.
- **`concat`** supports `Vertical`, `VerticalRelaxed`, `Horizontal`,
  `Diagonal`; polars' `diagonal_relaxed`, `horizontal_extend` and `align*` are
  not offered. For three or more frames in a vertical concat, mixing in empty
  (0-column) frames can make `concat` raise where polars succeeds:
  `concat([DataFrame::empty(), f, DataFrame::empty(), f])` is a frame with both copies of `f`'s rows
  in polars and `ShapeMismatch` (`unable to append to a DataFrame of width 1
  with a DataFrame of width 0`) here, because `@pl` uses a deterministic left
  fold while polars' own fold depends on its thread count. When frames
  disagree the error that is chosen can differ too. Two frames, or frames of
  equal width and names, are not affected.
- **`describe`**: `percentiles` is an array (empty means none). polars sorts
  numeric columns first, so a column mixing `0.0` and `-0.0` can show a
  different zero sign in `min` and the percentiles; and a `std` that
  overflows gives `inf` here but `NaN` in polars' single-table path. The last
  digit of `std`/`mean` can differ (polars itself varies between runs).
- **Closures in `filter`, `apply` and similar** do not exist; use expressions.
  `DataFrame::filter` takes one predicate (polars' `df.filter(a, b)` ANDs
  several; write `a & b`).
- **`Series::filter` with a non-`Boolean` mask** raises `SchemaMismatch`
  (polars: a Python `RuntimeError`).
- **`ddof` above 255** is not rejected: the result is null (polars: Python
  `OverflowError`).
- **`head` / `tail` defaults** follow polars (`DataFrame` 5 rows, `Series` 10).
  The old `DataFrame::head` also defaulted to 5 but printed instead of
  returning a frame; the old `tail(n)` had no default.
- **Deep expression chains overflow the stack** (a recursive evaluator).
  Measured in a debug build, the longest chain that worked / the shortest that
  failed: `col + lit + lit ...` 10000 / 20000 on native, 700 / 1000 on wasm and
  wasm-gc, 500 / 700 on js; a `when/then` chain 5000 / 7000 on native and
  300 / 500 on the other three. Printing and weak literal folding are linear in
  the length. Evaluate long chains in pieces. The full table is in
  `docs/golden/known-diffs/expr_agg.md`.
- **`when/then/otherwise`** evaluates every branch; polars skips branches it
  does not select (so some inputs that succeed there raise here, for example a
  failing cast in an unselected branch). When the condition is all true or all
  false polars returns the chosen branch without a type merge, so the result
  type can differ for weak literals next to `Date`.
- **`between` with a null literal bound** follows `&` (Kleene logic); polars
  gives mixed results depending on types.
- **`DataFrame::with_row_index`** is `Int64` with `Int32` offsets; polars'
  overflow errors cannot occur.
- **Frames with no columns** have height 0 (polars keeps the height, so
  `df.drop(all_columns)` is `(7, 0)` there and `(0, 0)` here).
- **Slicing and sizes**: a negative `length` gives an empty result (polars
  raises `OverflowError`); `Series::null(name, n)` with negative `n` is empty.

### Numbers

- **`exp` and `log` can differ in the last bits.** They use MoonBit's own
  `@math.exp` / `@math.ln` instead of glibc, so some values differ by 1 to 2
  ulp, and `log(x, base=3.0)` by up to 4 ulp (`ln(3.0)` itself is 1 ulp off).
  `Float32` results and bases 2, 10 and 0.5 matched in every recorded case.
- **`round`** uses half to even like polars 2.1; for `decimals` above about
  300 the result may differ from polars for extreme subnormal values.
  Negative `decimals` raise `InvalidOperation`.
- **`describe` `mean` with huge cancelling values** (for example `Int64` max,
  min and small numbers in one column) depends on which code path polars takes,
  so the result can differ in the last digits or more; `describe` of dates
  outside Python's year 1 to 9999 range raises in polars and prints here.
- **`-0.0 + lit_int(0)`** on a float column: in an eager `select` on a frame
  with several rows polars' optimizer drops the `+ 0` and keeps `-0.0` (a lazy
  `.collect()` and a one-row frame give `0.0`); `@pl` always computes it and gets
  `0.0`.
- **Variance of huge values**: `var`/`std` of `[1e308, 1e308]` is `inf` here
  and `NaN` in polars. For data with a large common offset (`1e9 + i * 0.001`)
  this library's two-pass algorithm is more accurate than polars' blockwise one.
- **Very long `Float32` sums** (over about 100,000 rows) can differ from
  polars in the last digit because polars splits them by thread count; up to
  60,000 rows are bit-identical.
- **`quantile` and zero signs**: for ties between `0.0` and `-0.0` polars'
  partial sort makes the sign of the result machine dependent; `@pl` takes the
  value at the sorted position of a stable sort.
- **`Date` and `Datetime` statistics** (`mean`, `median`, `quantile`) are
  computed through `Double` and are exact only within 2^53 microseconds
  (roughly years 1685 to 2255). A `quantile` of an all-null `Date` column
  is a null `Datetime` here and a Rust panic in polars.
- **Casting**: `Date` values beyond about plus or minus 95 million days
  cannot be formatted by polars (it panics); `@pl` formats up to 110 million
  days and above that gives null (`strict=false`) or `ComputeError`
  (`strict=true`). A strict `Date` to `Datetime` cast that overflows `Int64`
  is `ComputeError` here (polars panics).

### Strings and regular expressions

- **Engine.** `str().contains`, `replace`, `replace_all` use MoonBit core's
  `Regex`, not Rust's `regex` crate. Syntax that Rust accepts but `Regex`
  rejects raises `ComputeError` (with the pattern in the message):
  - `\d \w \s` (and `\D \W \S`): write `[[:digit:]]`, `[[:word:]]`,
    `[[:space:]]` (ASCII only);
  - `\xHH`: write `\uXXXX`; `\p{..}` classes, `\A`, `\z`: not available
    (`^` and `$` already match only at the ends of the whole text);
  - global flags `(?i)`, `(?s)`, `(?m)`: write `(?i:...)`; `(?P<name>...)`:
    write `(?<name>...)`;
  - stacked repeats `a**`, a leading `]` in a class `[]a]`, `-` at the
    start or end of a class `[a-]`, negated POSIX classes `[[:^digit:]]`, and
    escapes of arbitrary punctuation such as `\<`.
- **Semantics.** `.` also matches `\n` (use `[^\n]`); `(?i:...)` folds ASCII
  letters only; `\b` is an ASCII word boundary. Replacement strings follow
  Rust's `$1`, `${name}`, `$$` rules, and an empty match right after a
  previous match is skipped as in Rust.
- **Case conversion** uses a Unicode table generated from polars itself, so
  `ß` to `SS`, final sigma and the Kelvin sign match polars; strings compare
  by code point (UTF-8 byte order).
- **`str().*` on non-string columns** (and on `Null` columns) raise rather than
  returning nulls.

### Printing and casting (`Show`)

- Tables print like polars: at most 10 rows and 8 columns, then a fold row or
  column; cells longer than 30 characters are cut with `…`; wide, emoji and
  combining characters are measured with a width table recorded from polars
  2.1.0 (verified over every code point).
- **Total table width is not limited to 100 columns.** polars shrinks and
  wraps later columns when a table is wider than 100 columns; `@pl` only wraps
  cells at 31 columns. Output matches polars for tables up to 100 columns wide.
- **Dates outside the years -262143 to 262142** print as `<out-of-range date>` (polars
  panics).
- **Empty column names** are kept (`pl.DataFrame([s])` renames them
  `column_N`).
- A few rare combinations of curly quotes, variation selectors and Hebrew,
  Arabic or Khmer letters are measured one column differently from polars
  (details in `docs/golden/README.md`).
- **Strings read as dates, and dates built from numbers.** polars 2.1.0 has no
  `String` to `Date` cast, and neither does `@pl` (`cast(Date)` of a string
  raises, as in polars). Use `col("d").str().to_date(strict=...)` and
  `str().to_datetime(strict=...)`, the counterparts of `str.to_date()` and
  `str.to_datetime(time_unit="us")` (`2024-01-15`, `2024/1/5`, `15-01-2024`,
  `2024-01-15 10:20:30.5`; as in polars, a datetime text with a UTC offset is
  refused: `ComputeError`, or nulls with `strict=false`; there is no `format`
  parameter, only polars' format inference). `AnyValue::date_ymd(2024, 1, 15)`
  and `AnyValue::datetime_ymd(2024, 1, 15, hour=10)` build the values from
  numbers and raise `ComputeError` for an invalid date (years -262143 to
  262142). Details: `docs/golden/known-diffs/date_parse.md`.

### Grouping, joins, windows and reshaping (M3)

Details and exact inputs: [`group_by.md`](golden/known-diffs/group_by.md),
[`join.md`](golden/known-diffs/join.md),
[`window.md`](golden/known-diffs/window.md),
[`expr_shape.md`](golden/known-diffs/expr_shape.md),
[`reshape.md`](golden/known-diffs/reshape.md) and
[`date_parse.md`](golden/known-diffs/date_parse.md).

- **No `List` type.** In `group_by(...).agg(...)`, an expression that polars
  turns into a `list` column (`col("b")` on its own, `head(2)`, `sort()`,
  `col("b") + col("b").sum()`, `is_in`, `all()` without an aggregation, and
  also `col("b").over(k)` or `sort().over(k)` written inside the `agg`) raises
  `InvalidOperation: expression <expr> does not reduce each group to one
  value; this library has no List type, so aggregate it (for example with
  first(), sum() or len())`. The decision depends on the shape of the
  expression, never on the group sizes (`col("b")` is refused even when every
  group has one row). An aggregation of such an expression (`b.sort().first()`,
  `b.head(2).sum()`) works. `explode` is not provided.
  `over` itself never raises that error: in `select` and `with_columns`,
  `col("v").over(k)`, `col("v").sort().over(k)` and `(v + v.sum()).over(k)` all
  work, because they give one value per row. What `over` raises is
  `ShapeMismatch: the length of the window expression did not match that of the
  group` when the result of a partition is not as long as the partition
  (`col("v").head(n=2).over(k)`).
- **Row order is always deterministic.** Groups come in order of first
  appearance; `maintain_order` on `group_by` is accepted and has no effect.
  `join` has no `maintain_order`: the order is polars' `"left_right"` (for
  `Right`: `"right_left"`), and `Full` lists the unmatched right rows last.
  `value_counts`, `unique_counts` and `unique()` list values by first
  appearance (`sort=true` puts the biggest count first and keeps ties in
  first-appearance order).
- **Float aggregations in a group follow polars' grouped algorithms** (Kahan
  summation for `sum` and `mean`, Welford for `var` and `std`), but they do not
  match polars bit for bit at every size. Keyed `sum` and `mean` match for
  groups of up to 32 rows; from about 40 rows the last digit differs in many
  groups, and at 2,000 rows or more in nearly all. Keyed `var` and `std` were
  exact at every size tried. With no key, a literal key or `over(lit)` the
  whole column is one group and the library uses the whole-column kernel of
  `select`: `sum` and `mean` match polars up to 1,000 rows (the `sum` differs
  at 100,000 rows, as in `select`), `var` and `std` differ in the last digits
  at every size. Grouped results differ from `select`'s whole-column sum as
  they do in polars. polars may change how it adds a group on another version
  or size; the library does not depend on the size.
- **The sign of zero.** `unique().sum()` of a group whose only value is
  `-0.0` gives `+0.0` (polars: `-0.0`), and `min()` of a group with both zeros
  can give the other one (the values are equal).
- **Stricter than polars (raises `InvalidOperation` where polars returns null
  or a value)**: the sum of a `Date` or `Datetime` column in `group_by`,
  `pivot` or `over`; the quantile of `String`, `Boolean` and `Null` columns;
  arithmetic on text in a key; `diff` of a `Date`.
- **Literals.** A lone `lit_int` is `Int64` (polars: `Int32`), also in `agg`,
  `over` and horizontal functions with only literals.
- **`join` arguments.** Keys are `Expr` values (`on=[col("a")]`, not
  strings); `how` and `validate` are enums; `join_nulls` is `nulls_equal`;
  `maintain_order` and `"outer"` do not exist (`Full`). Keys of different
  types need a common type (`Int32` with `Int64`, `Float32` with `Float64`),
  every other pair is `SchemaMismatch`.
- **`join` keys that are not row-wise.** polars accepts a key whose root is an
  aggregation of a non-row-wise expression (`a.sort().sum()`,
  `a.cum_sum().sum()`); the library refuses it (`InvalidOperation: all join
  key expressions must be elementwise.`). `a.sum()` is accepted by both.
- **`join` with `coalesce=true` on a `Full` join** where one right column
  serves two keys: polars also drops the next right column (a quirk); the
  library keeps every column that no key refers to. A `Cross` join must have at
  most `2^31 - 1` result rows.
- **`over`** takes `partition_by` only: no `order_by`, no `mapping_strategy`
  (`join` and `explode` need a `List`).
- **`pivot`** takes `aggregate_function` as the `PivotAgg` enum (`First`,
  `Last`, `Sum`, `Min`, `Max`, `Mean`, `Median`, `Len`), not `"item"`,
  `"count"` or an expression; `on`, `index` and `values` are column names;
  `maintain_order`, `on_columns` and `column_naming` do not exist. `unpivot`
  and `transpose` take names, not selectors; `transpose` takes `column_names`
  as an array. `to_dict` always gives series.
- **`transpose` of a table without rows** has shape `(0, 0)`; polars gives
  `(n, 0)` for `n` columns (a table without columns has height 0 here).
- **Error text and order.** Where several things are wrong at once the library
  tries to raise the error polars raises first and follows polars' texts, with
  these exceptions: three results of three different lengths name a column in
  the `ShapeMismatch` text where polars does not; a few kernel-time versus
  type-time orders in `group_by`; the text of arithmetic errors inside join
  keys and of `sort_by` / `filter` group-length errors inside `agg`.
- **Trigonometry** (`sin`, `cos`, `tan`, `arcsin`, `arccos`, `arctan`) uses the
  library's own routines; no golden value differs by more than one unit in
  the last place.
- **Dates from text.** There is no `String` to `Date` cast (as in polars);
  use `str().to_date()` and `str().to_datetime()` (see the casting entry
  above).

### Things you may notice that are not differences

`null` sorts first by default and `NaN` sorts after every number, `-0.0 == 0.0`,
integer division by zero gives null (`floor_div`, `%`) or `inf` / `NaN`
(`/`), `Int64::MIN // -1` wraps instead of trapping on every backend, strings
compare by code point, and `mean` / `sum` / `min` / `max` skip nulls: all as in
polars.
