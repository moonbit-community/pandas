# Pandas In Moonbit
mooncakes.io link: https://mooncakes.io/docs/#/smallbearrr/pandas/ <br>
moonbit-community link: https://github.com/moonbit-community/pandas

## Introduction
This is a data processing library written in Moonbit. It provides a DataFrame data structure for efficient data manipulation and analysis.

## Installation
To install the package, run the following command in the terminal:
```moonbit
moon add smallbearrr/pandas
```

## Usage

### DataFrame
create a DataFrame
```moonbit
let col1 = Series::new("A", SeriesInput::Int32([1, 2, 3]))
let col2 = Series::new("B", SeriesInput::Float32([1.5, 2.5, 3.5]))
let col3 = Series::new("C", SeriesInput::Int32_Nullable([Some(1), None, Some(3)]))
let df = DataFrame::new([col1, col2, col3])
```

Display the first few(min(size, 5)) rows of the DataFrame
```moonbit
df.head()
```

DataFrame already traits the `Show`, it can print the DataFrame directly:
```moonbit
println(df)
```

Add a new column
```moonbit
let new_col = Series::new("C", SeriesInput::Bool([true, false, true]))
df.add_column!(new_col)
```

Drop a column
```moonbit
df.drop_column!("C")
```

Rename a column
```moonbit
df.rename!("A", "A1")
```

Select a column
```moonbit
let df_col = df.column("A")
```

Select specific columns
```moonbit
let df_cols = df.select_columns!(["A1", "B"])
```

Drop a row
```moonbit
df.drop_row!(0)
```

Add a new row
```moonbit
df.add_row!([SeriesValue::Int32(7), SeriesValue::Float32(7.5), SeriesValue::Bool(true), SeriesValue::Str("ok")])
```

Select rows by range or by specific indices:
```moonbit
let row_selected_range = df.select_rows!(range=(1, 3))
let row_selected_indices = df.select_rows!(indices=[1, 3, 5])
```

Filter rows based on a condition applied to a specific column:
```moonbit
let filtered = df.filter!("A", fn(x) -> Bool { x < DType::Int(3) })
```

Sort the DataFrame by a specified column in ascending or descending order:
```moonbit
df.sort!("A")
df.sort!("B", descending=true)
```

Vertically stack two DataFrame
```moonbit
let new_df = df1.vstack!(df2)
```

Horizontally stack two DataFra
```moonbit
let new_df = df1.hstack!(df2)
```

### Series
Create a Series
```moonbit
let series_int = Series::new("IntColumn", SeriesInput::Int32([1, 2, 3]))
let series_float = Series::new("FloatColumn", SeriesInput::Float32([1.1, 2.2, 3.3]))
let series_bool = Series::new("BoolColumn", SeriesInput::Bool([true, false, true]))
let series_str = Series::new("StrColumn", SeriesInput::Str(["a", "b", "c"]))
```

Erase element
```moonbit
series.erase(1)
```

Sort the SeriesData in Series and return the indices of the sorted elements
```moonbit
let indices = series.sort()
```

Add two Series
```moonbit
let series1 = Series::new("A", SeriesInput::Int32([1, 2, 3]))
let series2 = Series::new("B", SeriesInput::Float32([1.5, 2.0, 3.5]))
let add = series1 + series2
```

Operation of add, subtract, multiply and divide
```moonbit
let add_op = series1 + series2
let sub_op = series1 - series2
let mul_op = series1 * series2
let div_op = series1 / series2
```

## Feature

### DataFrame Methods

| Method             | Description                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| `new`              | Create a new DataFrame                                                      |
| `shape`            | Get the shape of the DataFrame                                              |
| `data`             | Get the data of the DataFrame                                               |
| `head`             | Display the first few rows of the DataFrame                                 |
| `add_column`       | Add a new column to the DataFrame                                           |
| `drop_column`      | Drop a column from the DataFrame                                            |
| `rename`           | Rename a column in the DataFrame                                            |
| `column`           | Select a column from the DataFrame                                          |
| `select_columns`   | Select specific columns from the DataFrame                                  |
| `drop_row`         | Drop a row from the DataFrame                                               |
| `add_row`          | Add a new row to the DataFrame                                              |
| `select_rows`      | Select specific rows from the DataFrame                                     |
| `filter`           | Filter rows in the DataFrame based on a condition                           |
| `sort`             | Sort the DataFrame by a specified column                                    |
| `vstack`           | Vertically stack two DataFrames                                             |
| `hstack`           | Horizontally stack two DataFrames                                           |
| `clear`            | Clear all data in the DataFrame                                             |
| `clone`            | Create a deep copy of the DataFrame                                         |
| `item`             | Retrieve a single item from the DataFrame                                   |
| `limit`            | Create a new DataFrame containing only the first N rows                     |
| `tail`             | Create a new DataFrame containing only the last N rows                      |
| `slice`            | Create a new DataFrame containing a slice of rows                           |
| `to_series`        | Convert a column of the DataFrame to a Series                               |
| `unique`           | Remove duplicate rows from the DataFrame                                    |
| `replace_column`   | Replace a column in the DataFrame                                           |
| `reverse`          | Reverse the order of rows in the DataFrame                                  |
| `get_column_index` | Get the index of a column by its name                                       |
| `with_row_index`   | Add a row index column to the DataFrame                                     |
| `transpose`        | Transpose the DataFrame over the diagonal                                   |
| `mean`             | Calculate the mean of each column in the DataFrame                          |
| `var`              | Calculate the variance of each column in the DataFrame                      |
| `count`            | Count the number of rows and columns in the DataFrame                       |
| `max`              | Get the maximum value of each column in the DataFrame                       |
| `max_horizontal`   | Get the maximum value of each row in the DataFrame                          |
| `min`              | Get the minimum value of each column in the DataFrame                       |
| `min_horizontal`   | Get the minimum value of each row in the DataFrame                          |
| `sum`              | Calculate the sum of each column in the DataFrame                           |
| `sum_horizontal`   | Calculate the sum of each row in the DataFrame                              |
| `dtypes`           | Get the data types of each column in the DataFrame                          |
| `height`           | Get the number of rows in the DataFrame                                     |
| `width`            | Get the number of columns in the DataFrame                                  |
| `product`          | Calculate the product of each column in the DataFrame                       |
| `schema`           | Get the schema of the DataFrame                                             |
| `is_empty`         | Return whether the DataFrame is empty                                       |
| `fill_null`        | Fill null values using the specified value or strategy                      |
| `null_count`       | Return the number of null values in the DataFrame                           |
| `cast`             | Cast DataFrame column(s) to the specified dtype(s)                          |
| `to_dict`          | Convert the DataFrame to a dictionary                                       |
| `to_init_repr`     | Convert DataFrame to instantiable string representation                     |
| `drop_nulls`       | Drop all rows that contain null values                                      |
| `gather_every`     | Take every nth row in the DataFrame and return as a new DataFrame           |
| `drop_in_place`    | Drop a single column in-place and return the dropped column                 |

### Series Methods

| Method             | Description                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| `new`              | Create a new Series                                                         |
| `data`             | Get the data of the Series                                                  |
| `erase`            | Erase an element from the Series                                            |
| `sort`             | Sort the SeriesData in Series and return the indices of the sorted elements |
| `+`                | Add two Series                                                              |
| `-`                | Subtract two Series                                                         |
| `*`                | Multiply two Series                                                         |
| `/`                | Divide two Series                                                           |
| `mean`             | Calculate the mean of the Series                                            |
| `var`              | Calculate the variance of the Series                                        |
| `argsort`          | Return the indices that would sort the Series                               |
| `copy`             | Create a copy of the Series                                                 |
| `count`            | Count the number of elements in the Series                                  |
| `get_type`         | Get the type of the Series                                                  |
| `max`              | Get the maximum value of the Series                                         |
| `merge`            | Merge two Series                                                            |
| `min`              | Get the minimum value of the Series                                         |
| `name`             | Get the name of the Series                                                  |
| `reverse`          | Reverse the order of elements in the Series                                 |
| `sum`              | Calculate the sum of the Series                                             |
| `abs`              | Return a new Series with the absolute value of each element                 |
| `acos`             | Return a new Series with the arccos of each element                         |
| `all`              | Return whether all non-null elements in the Series are true                 |
| `any`              | Return whether any non-null element in the Series is true                   |
| `append`           | Append another Series to the current one and return a new Series            |
| `clear`            | Remove all elements from the current Series                                 |
| `concat`           | Concatenate multiple Series and return the result                           |
| `cos`              | Return a new Series with the cosine of each element                         |
| `extend`           | Extend the current Series in-place with another Series                      |
| `has_null`         | Check if the current Series contains any null values                        |
| `is_empty`         | Check if the current Series is empty                                        |
| `is_not_null`      | Return a boolean Series indicating non-null elements                        |
| `is_null`          | Return a boolean Series indicating null elements                            |
| `is_sorted`        | Check if the current Series is sorted                                       |
| `length`           | Return the length of the current Series                                     |
| `log`              | Return a new Series with the logarithm of each element                      |
| `log10`            | Return a new Series with the base-10 log of each element                    |
| `lower_bound`      | Return a new Series with each element replaced by the lower bound           |
| `n_unique`         | Return the number of unique elements in the Series                          |
| `not_`             | Return the logical NOT of a boolean Series                                  |
| `null_count`       | Return the count of null values in the Series                               |
| `op_get`           | Return the element at a given index in the Series                           |
| `sin`              | Return a new Series with the sine of each element                           |
| `tan`              | Return a new Series with the tangent of each element                        |
| `unique_counts`    | Return a new Series showing the count of each unique value                  |
| `upper_bound`      | Return a new Series with each element replaced by the upper bound           |
| `slice`            | Return a new Series containing elements in the specified range              |
| `swap`             | Swap two elements in the Series                                             |
| `get_argsort_indices`| Get the indices that would sort the Series                                |
| `move_nulls_front` | Move null values to the front of the Series                                 |
| `move_nulls_back`  | Move null values to the back of the Series                                  |

## Contributing
Issues and pull requests are welcome. Please make sure to run all tests before submitting.

## Contact
If you have questions, feel free to open an issue in the repository. For other inquiries, contact me via email: [2421342308a@gmail.com].

## License
This project is licensed under the Apache-2.0 License. See the LICENSE file for details.