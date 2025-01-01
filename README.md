# Pandas In Moonbit

## Introduction
This is a data processing library written in Moonbit. It provides a DataFrame data structure for efficient data manipulation and analysis.

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

### Print the DataFrame structure
DataFrame already traits the `Show`, so you can print the structure of the DataFrame directly:
```moonbit
println(df)
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
Select rows by range or by specific indices:
```moonbit
let row_selected_range = df.select_rows(range=(1, 3))

let row_selected_indices = df.select_rows(indices=[1, 3, 5])
```

### Filter rows based on a condition
Filter rows based on a condition applied to a specific column:
```moonbit
let filtered = df.filter("A", fn(x) -> Bool { x < DType::Int(3) })
```

## Contributing
Issues and pull requests are welcome. Please make sure to run all tests before submitting.

## Contact
If you have questions, feel free to open an issue in the repository. For other inquiries, contact me via email: [2421342308a@gmail.com].

## License
This project is licensed under the Apache License 2.0. See the LICENSE file for details.