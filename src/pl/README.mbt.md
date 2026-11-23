# `smallbearrr/pandas/pl`

A polars-style data layer for MoonBit: typed, nullable, immutable columns
(`Series`) grouped into a `DataFrame`. This is the M1 milestone: construction,
inspection, slicing, `cast` and printing. Every fallible call raises
`PolarsError`; nothing aborts on bad user input.

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
      inspect(name, content="column with name 'a' has more than one occurrence")
    _ => fail("expected DuplicateColumn")
  } noraise {
    _ => fail("expected an error")
  }
}
```
