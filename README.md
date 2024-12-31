# smallbearrr/pandas

## Introduction
This is a data processing library written in Moonbit, similar to Python's pandas library. It provides a DataFrame data structure for efficient data manipulation and analysis.

## Usage Examples
Here are some basic usage examples:

### Create a DataFrame
```moonbit
let col1 = Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6]))
let col2 = Series::new("B", SeriesData::Float([1.1, 2.2, 3.3, 4.4, 5.5, 6.6]))
let df = DataFrame::new([col1, col2])
```

### Display the first few rows of the DataFrame
```moonbit
df.head()
```

### Add a new column
```moonbit
let new_col = Series::new("C", SeriesData::Bool([true, false, true, false, true, false]))
df.add_column(new_col)
```

### Drop a column
```moonbit
df.drop_column("C")
```

### Rename a column
```moonbit
df.rename_column("A", "A1")
```

### Select specific columns
```moonbit
let df_selected = df.select_columns(["A1", "B"])
```

### Drop a row
```moonbit
df.drop_row(0)
```

### Add a new row
```moonbit
df.add_row([DType::Int(7), DType::Float(7.5), DType::Bool(true), DType::Str("g")])
```

### Select specific rows
```moonbit
let row_selected = df.select_rows(1, 3)
```

## Testing
Run the following command to execute tests:
```sh
moonbit test
```

## Contributing
Issues and pull requests are welcome. Please make sure to run all tests before submitting.

## License
This project is licensed under the MIT License. See the LICENSE file for details.