///| Tests
test "new" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesInput::Float32([1.5, 2.0, 3.5, 6.0, 6.0, 6.0])),
    Series::new("C", SeriesInput::Bool([true, false, true, false, true, false])),
    Series::new("D", SeriesInput::Str(["a", "b", "c", "d", "e", "f"])),
  ])
  inspect!(df.shape(), content="[6, 4]")
}

test "rename" {
  let df = DataFrame::new!([Series::new("A", SeriesInput::Int32([1, 2, 3]))])
  df.rename!("A", "A1")
  inspect!(df.data()[0].name(), content="A1")
}

test "select" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesInput::Float32([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
    Series::new("C", SeriesInput::Bool([true, false, true, false, true, false])),
    Series::new("D", SeriesInput::Str(["a", "b", "c", "d", "e", "f"])),
  ])
  let col_selected = df.select_columns!(["A", "B"])
  inspect!(col_selected.shape(), content="[6, 2]")
  let row_selected = df.select_rows!(range=(1, 3))
  inspect!(row_selected.shape(), content="[2, 4]")
  let row_selected = df.select_rows!(indices=[1, 3, 5])
  inspect!(row_selected.shape(), content="[3, 4]")
}

test "filter" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 1, 3, 1, 1, 6])),
    Series::new("B", SeriesInput::Float32([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
    Series::new("C", SeriesInput::Bool([true, false, true, false, true, false])),
    Series::new("D", SeriesInput::Str(["a", "b", "c", "d", "e", "f"])),
  ])
  let filtered = df.filter!("A", fn(x) -> Bool { x < SeriesValue::Int(3) })
  inspect!(filtered.shape(), content="[4, 4]")
}

test "sort" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([2, 1, 3, 5, 4])),
    Series::new("B", SeriesInput::Float32([2.2, 1.1, 3.3, 5.5, 4.4])),
    Series::new("C", SeriesInput::Bool([true, false, true, false, true])),
    Series::new("D", SeriesInput::Str(["b", "a", "c", "e", "d"])),
  ])
  df.sort!("A")
  inspect!(df.data()[0].data(), content="Int([1, 2, 3, 4, 5])")
  df.sort!("A", descending=true)
  inspect!(df.data()[0].data(), content="Int([5, 4, 3, 2, 1])")
  inspect!(
    df.data()[3].data(),
    content="Str([\"e\", \"d\", \"c\", \"b\", \"a\"])",
  )
}

test "new_error" {
  let col1 = Series::new("A", SeriesInput::Int32([1, 2, 3, 4, 5, 6]))
  let col2 = Series::new("B", SeriesInput::Float32([1.5, 2.0, 3.5]))
  let res = DataFrame::new?([col1, col2])
  inspect!(
    res,
    content="Err(InconsistentSeriesLength(\"Could not create a new DataFrame. The Series lengths are not equal.\"))",
  )
}

test "add_column_error" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesInput::Float32([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
  ])
  let col = Series::new("B", SeriesInput::Int32([1, 2, 3, 4, 5, 6]))
  let res = df.add_column?(col)
  inspect!(
    res,
    content="Err(DuplicateColumnError(\"Could not add a new column to the DataFrame. The Series name already exists.\"))",
  )
  let res = df.add_column?(Series::new("C", SeriesInput::Int32([1, 2, 3])))
  inspect!(
    res,
    content="Err(InconsistentSeriesLength(\"Could not add a new column to the DataFrame. The Series lengths are not equal.\"))",
  )
}

test "drop_column_error" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesInput::Float32([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
  ])
  let res = df.drop_column?("C")
  inspect!(res, content="Err(ColumnNotFoundError(\"Column 'C' not found\"))")
}

test "rename_column_error" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesInput::Float32([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
  ])
  let res = df.rename?("C", "D")
  inspect!(res, content="Err(ColumnNotFoundError(\"Column 'C' not found\"))")
}

test "vstack" {
  let df1 = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Str(["a", "b", "c"])),
  ])
  let df2 = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([4, 5, 6])),
    Series::new("B", SeriesInput::Str(["d", "e", "f"])),
  ])
  let res = df1.vstack!(df2)
  inspect!(res.shape(), content="[6, 2]")
  inspect!(res.data()[0].data(), content="Int([1, 2, 3, 4, 5, 6])")
  inspect!(
    res.data()[1].data(),
    content="Str([\"a\", \"b\", \"c\", \"d\", \"e\", \"f\"])",
  )
}

// test "hstack" {
//   let df1 = DataFrame::new!([
//     Series::new("A", SeriesInput::Int([1, 2, 3])),
//     Series::new("B", SeriesInput::Str(["a", "b", "c"])),
//   ])
//   let df2 = DataFrame::new!([
//     Series::new("A", SeriesInput::Int([4, 5, 6])),
//     Series::new("C", SeriesInput::Str(["d", "e", "f"])),
//   ])
//   let res = df1.hstack!(df2)
//   inspect!(res.shape(), content="[3, 3]")
//   inspect!(res.column!("A"), content="{name: \"A\", data: Int([4, 5, 6]), data_type: Int32, bitmap: {optional: false, bitmap: [], length: 0, offset: 0}}")
//   inspect!(
//     res.column!("B"),
//     content="{name: \"B\", data: Str([\"a\", \"b\", \"c\"]), data_type: String, bitmap: {optional: false, bitmap: [], length: 0, offset: 0}}",
//   )
//   inspect!(
//     res.column!("C"),
//     content="{name: \"C\", data: Str([\"d\", \"e\", \"f\"]), data_type: String, bitmap: {optional: false, bitmap: [], length: 0, offset: 0}}",
//   )
// }

test "item" {
  let df = DataFrame::new!([Series::new("A", SeriesInput::Int32([1, 2, 3]))])
  inspect!(df.item?(1, ColumnSelector::Str("A")), content="Ok(Int(2))")
  inspect!(
    df.item?(0, ColumnSelector::Int(2)),
    content="Err(IndexOutOfBounds(\"Row index out of bounds\"))",
  )
}

test "unique/basic" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 1, 2, 2])),
    Series::new("B", SeriesInput::Int32([1, 1, 2, 3])),
  ])
  let unique_first = df.unique!(["A"], keep="first")
  inspect!(unique_first.shape(), content="[2, 2]")
  inspect!(unique_first.data()[0].data(), content="Int([1, 2])")
}

test "unique/empty" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([])),
    Series::new("B", SeriesInput::Int32([])),
  ])
  let unique_df = df.unique!(["A"])
  inspect!(unique_df.shape(), content="[0, 0]")
}

test "panic unique/invalid_keep" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 1, 2, 2])),
    Series::new("B", SeriesInput::Int32([1, 1, 2, 3])),
  ])
  df.unique!(["A"], keep="invalid") |> ignore
}

test "op_get" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Str(["a", "b", "c"])),
  ])
  let res = df[1]
  inspect!(res.shape(), content="[1, 2]")
  inspect!(res.data()[0].data(), content="Int([2])")
  inspect!(res.data()[1].data(), content="Str([\"b\"])")
}

test "replace_column" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Str(["a", "b", "c"])),
  ])
  df.replace_column!(1, Series::new("C", SeriesInput::Int32([4, 5, 6])))
  inspect!(df.data()[1].data(), content="Int([4, 5, 6])")
}

test "reverse" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Str(["a", "b", "c"])),
  ])
  df.reverse()
  inspect!(df.data[0].data, content="Int([3, 2, 1])")
  inspect!(df.data[1].data, content="Str([\"c\", \"b\", \"a\"])")
}

test "row_index" {
  let df = DataFrame::new!([Series::new("A", SeriesInput::Int32([1, 2, 3]))])
  let new_df = df.with_row_index(offset=1000)
  inspect!(new_df.shape, content="[3, 2]")
  inspect!(new_df.data[0].data, content="Int([1000, 1001, 1002])")
}

test "transpose" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Int32([4, 5, 6])),
  ])
  let trans_df = df.transpose!()
  inspect!(trans_df.shape(), content="[2, 3]")
  let trans_df = df.transpose!(include_header=true)
  inspect!(trans_df.data[0].data(), content="Str([\"A\", \"B\"])")
  let trans_df = df.transpose!(include_header=true, header_name="header")
  inspect!(trans_df.data[0].data(), content="Str([\"A\", \"B\"])")
  inspect!(trans_df.data[0].name, content="header")
  let trans_df = df.transpose!(include_header=true, column_names=["x", "y", "z"])
  inspect!(trans_df.data[1].name, content="y")
}

// test "min/max" {
//   let df = DataFrame::new!([
//     Series::new("A", SeriesInput::Int([1, 2, 3])),
//     Series::new("B", SeriesInput::Float([1.5, 2.0, 3.5])),
//     Series::new("C", SeriesInput::Bool([true, false, true])),
//     Series::new("D", SeriesInput::Str(["a", "b", "c"])),
//   ])
//   let min = df.min!()
//   inspect!(
//     min.data,
//     content="[{name: \"A\", data: Int([1])}, {name: \"B\", data: Float([1.5])}, {name: \"C\", data: Bool([false])}, {name: \"D\", data: Str([\"a\"])}]",
//   )
//   let max = df.max!()
//   inspect!(
//     max.data,
//     content="[{name: \"A\", data: Int([3])}, {name: \"B\", data: Float([3.5])}, {name: \"C\", data: Bool([true])}, {name: \"D\", data: Str([\"c\"])}]",
//   )
// }

test "sum" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Float32([1.5, 2.0, 3.5])),
  ])
  let df_sum = df.sum!()
  inspect!(df_sum.data[0].data, content="Int([6])")
  inspect!(df_sum.data[1].data, content="Float([7])")
}

test "sum_horizontal" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Float32([1.5, 2.5, 3.0])),
  ])
  let sum = df.sum_horizontal!()
  inspect!(sum.data(), content="Float([2.5, 4.5, 6])")
}

test "min_horizontal" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Float32([1.5, 2.0, 1.5])),
  ])
  let min = df.min_horizontal!()
  inspect!(min.data, content="Float([1, 2, 1.5])")
}

test "max_horizontal" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Float32([1.5, 2.0, 1.5])),
  ])
  let max = df.max_horizontal!()
  inspect!(max.data, content="Float([1.5, 2, 3])")
}

test "schema" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Float32([1.5, 2.5, 3.5])),
    Series::new("C", SeriesInput::Bool([true, false, true])),
    Series::new("D", SeriesInput::Str(["a", "b", "c"])),
  ])
  let schema = df.schema()
  inspect!(
    schema,
    content="{\"A\": \"int32\", \"B\": \"float32\", \"C\": \"bool\", \"D\": \"string\"}",
  )
}

test "product" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Float32([1.5, 2, 3.0])),
  ])
  let df_product = df.product()
  inspect!(df_product.data[0].data, content="Int([6])")
  inspect!(df_product.data[1].data, content="Float([9])")
}

test "dtypes" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Float32([1.5, 2.0, 3.5])),
    Series::new("C", SeriesInput::Bool([true, false, true])),
    Series::new("D", SeriesInput::Str(["a", "b", "c"])),
  ])
  inspect!(
    df.dtypes(),
    content="[\"int32\", \"float32\", \"bool\", \"string\"]",
  )
}

test "DataFrame::slice" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3, 4, 5])),
    Series::new("B", SeriesInput::Float32([1.0, 2.0, 3.0, 4.0, 5.0])),
  ])
  let sliced = df.slice!(1, length=2)
  // sliced |> println
  // sliced.data()[1].data() |> println
  inspect!(sliced.shape(), content="[2, 2]")
  inspect!(sliced.data()[0].data(), content="Int([2, 3])")
  inspect!(sliced.data()[1].data(), content="Float([2, 3])")
}

// test "DataFrame Show" {
//   let df = DataFrame::new!([
//     Series::new("A", SeriesInput::Int32([1, 2, 3])),
//     Series::new("B", SeriesInput::Int32_Nullable([Some(1), Some(2), None])),
//   ])
//   println(df)
// }
// test "DataFrame head" {
//   let df = DataFrame::new!([
//     Series::new("A", SeriesInput::Int32([1, 2, 3])),
//     Series::new("B", SeriesInput::Int32_Nullable([Some(1), Some(2), None])),
//   ])
//   df.head()
//   df.head(rows=2)
// }

test "DataFrame::add_row" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2])),
    Series::new("B", SeriesInput::Float32([1.5, 2.5])),
  ])
  df.add_row!([SeriesValue::Int(3), SeriesValue::Float(3.5)])
  inspect!(df.data[0].data(), content="Int([1, 2, 3])")
  df.add_row!([SeriesValue::Int(4), SeriesValue::Null])
  inspect!(df.data[1].data(), content="Float([1.5, 2.5, 3.5, 0])")
  inspect!(
    df.data[1].bitmap,
    content="{optional: true, bitmap: [false, false, false, true], length: 4, offset: 0}",
  )
}

test "DataFrame::all" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Bool([true, true, true])),
    Series::new("B", SeriesInput::Bool([true, false, true])),
  ])
  inspect!(df.all!().data[0][0], content="Bool(true)")
  inspect!(df.all!().data[1][0], content="Bool(false)")
}

test "DataFrame::any" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Bool([true, true, true])),
    Series::new("B", SeriesInput::Bool([true, false, true])),
  ])
  inspect!(df.any!().data[0][0], content="Bool(true)")
  inspect!(df.any!().data[1][0], content="Bool(true)")
}

test "DataFrame::has_nulls" {
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Int32([1, 2, 3])),
  ])
  inspect!(df.has_nulls().data[0][0], content="Bool(false)")
  let df = DataFrame::new!([
    Series::new("A", SeriesInput::Int32_Nullable([Some(1), None, Some(3)])),
    Series::new("B", SeriesInput::Int32([1, 2, 3])),
  ])
  inspect!(df.has_nulls().data[0][0], content="Bool(true)")
}
