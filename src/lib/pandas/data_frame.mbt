///|
pub(all) struct DataFrame {
  mut data : Array[Series]
  mut shape : Array[Int]
  mut index : Map[String, Int]
}

///|
type! InconsistentSeriesLength String derive(Show)

///| Create a new DataFrame
///
/// # Parameters
///
/// - `data` : Array of Series
///
/// # Returns
///
/// - `DataFrame!InconsistentSeriesLength` : A new DataFrame instance
///
/// # Errors
///
/// - `InconsistentSeriesLength` : Raised if the lengths of the Series are not equal
///
pub fn DataFrame::new(
  data : Array[Series]
) -> DataFrame!InconsistentSeriesLength {
  let index : Map[String, Int] = Map::new()
  for i = 0; i < data.length(); i = i + 1 {
    if data[i].data().length() != data[0].data().length() {
      raise InconsistentSeriesLength(
        "Could not create a new DataFrame. The Series lengths are not equal.",
      )
    }
    index[data[i].name()] = i
  }
  DataFrame::{ data, shape: [data[0].data().length(), data.length()], index }
}

///|
pub fn DataFrame::shape(self : DataFrame) -> Array[Int] {
  self.shape
}

///|
pub fn DataFrame::data(self : DataFrame) -> Array[Series] {
  self.data
}

///| Trait Show for DataFrame
pub impl Show for DataFrame with output(self, logger) {
  let mut row_str = "\t"
  for col in self.data {
    row_str = row_str + col.name() + "\t"
  }
  logger.write_string(row_str + "\n")
  row_str = ""
  for i = 0; i < self.shape()[0]; i = i + 1 {
    row_str += i.to_string() + "\t"
    for col in self.data {
      match col.data() {
        SeriesData::Int(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Float(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Bool(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Str(vals) => row_str += vals[i] + "\t"
      }
    }
    row_str += "\n"
  }
  logger.write_string(row_str)
}

///| Display the first few rows of the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
///
/// # Returns
///
/// - `Unit` : This function prints the first few rows of the DataFrame
///
/// # Example
/// ```
/// test {
///   let col1 = Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6]))
///   let col2 = Series::new("B", SeriesData::Float([1.1, 2.2, 3.3, 4.4, 5.5, 6.6]))
///   let df = DataFrame::new([col1, col2])
///   df.head()
/// }
/// ```
pub fn DataFrame::head(self : DataFrame) -> Unit {
  let mut row_str = "\t"
  for col in self.data {
    row_str = row_str + col.name() + "\t"
  }
  println(row_str)
  row_str = ""
  for i = 0; i < @math.minimum(5, self.shape()[0]); i = i + 1 {
    row_str += i.to_string() + "\t"
    for col in self.data {
      match col.data() {
        SeriesData::Int(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Float(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Bool(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Str(vals) => row_str += vals[i] + "\t"
      }
    }
    row_str += "\n"
  }
  println(row_str)
}

///|
type! AddColumnError String derive(Show)

///| Add a new column to the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `col` : The Series to be added as a new column
///
/// # Returns
///
/// - `Unit!AddColumnError` : This function adds a new column to the DataFrame or raises an error
///
/// # Errors
///
/// - `AddColumnError` : Raised if the Series length is not equal to the DataFrame length or if the Series name already exists
///
/// # Example
/// ```
/// df.add_column(new_column)
/// ```
pub fn DataFrame::add_column(
  self : DataFrame,
  col : Series
) -> Unit!AddColumnError {
  if col.data().length() != self.shape()[0] {
    raise AddColumnError(
      "Could not add a new column to the DataFrame. The Series length is not equal to the DataFrame length.",
    )
  }
  if self.index.contains(col.name()) {
    raise AddColumnError(
      "Could not add a new column to the DataFrame. The Series name already exists.",
    )
  }
  self.data += [col]
  self.shape = [self.shape()[0], self.shape()[1] + 1]
  self.index[col.name()] = self.shape()[1] - 1
}

///| Drop a column from the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `col_name` : The name of the column to be dropped
///
/// # Returns
///
/// - `Unit` : This function drops a column from the DataFrame
///
/// # Example
/// ```
/// df.drop_column("column_name")
/// ```
pub fn DataFrame::drop_column(self : DataFrame, col_name : String) -> Unit {
  match self.index.get(col_name) {
    Some(idx) => {
      let _ = self.data.remove(idx)
      self.index.remove(col_name)
      self.shape = [self.shape()[0], self.shape()[1] - 1]
      self.index.each(fn(k, v) { if v > idx { self.index[k] = v - 1 } })
    }
    None => ()
  }
}

///| Rename a column in the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `old_name` : The current name of the column to be renamed
/// - `new_name` : The new name for the column
///
/// # Returns
///
/// - `Unit` : This function renames a column in the DataFrame
///
/// # Example
/// ```
/// test {
///   let col1 = Series::new("A", SeriesData::Int([1, 2, 3]))
///   let mut df = DataFrame::new([col1])
///   df.rename("A", "B")
///   inspect!(df.data()[0].name(), context="B")
/// }
/// ```
pub fn DataFrame::rename_column(
  self : DataFrame,
  old_name : String,
  new_name : String
) -> Unit {
  match self.index.get(old_name) {
    Some(idx) => self.data[idx].name = new_name
    None => ()
  }
}

///| Select specific columns from the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `cols` : An array of column names to be selected
///
/// # Returns
///
/// - `DataFrame` : A new DataFrame containing only the selected columns
///
/// # Example
/// ```
/// test {
///   let col1 = Series::new("A", SeriesData::Int([1, 2, 3]))
///   let col2 = Series::new("B", SeriesData::Float([1.1, 2.2, 3.3]))
///   let df = DataFrame::new([col1, col2])
///   let df_selected = df.select_columns(["A", "B"])
/// }
/// ```
pub fn DataFrame::select_columns(
  self : DataFrame,
  cols : Array[String]
) -> DataFrame {
  let selected_cols : Array[Series] = []
  let index : Map[String, Int] = Map::new()
  for name in cols {
    match self.index.get(name) {
      Some(idx) => {
        selected_cols.push(self.data[idx])
        index[name] = selected_cols.length() - 1
      }
      None => ()
    }
  }
  DataFrame::{
    data: selected_cols,
    shape: [self.shape()[0], selected_cols.length()],
    index,
  }
}

test "data_frame" {
  let df = DataFrame::new!([
    Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
    Series::new("C", SeriesData::Bool([true, false, true, false, true, false])),
    Series::new("D", SeriesData::Str(["a", "b", "c", "d", "e", "f"])),
  ])
  inspect!(df.shape(), content="[6, 4]")
  df.add_column!(Series::new("E", SeriesData::Int([7, 8, 9, 10, 11, 12])))
  inspect!(df.shape(), content="[6, 5]")
  df.drop_column("E")
  inspect!(df.shape(), content="[6, 4]")
  df.rename_column("A", "A1")
  println(df)
  inspect!(df.data()[0].name(), content="A1")
}
