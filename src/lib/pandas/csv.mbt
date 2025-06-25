///| Read a CSV file and convert it into a DataFrame
///
/// Parameters
///
/// - `path` : The file path of the CSV file to read
///
/// Returns
///
/// - `DataFrame` : A DataFrame containing the data from the CSV file
///
/// Errors
///
/// - `NotCSVFile` : File is not a CSV file
/// - `PathNotFound` : Specified file path does not exist
///
/// Example
/// ```moonbit
/// let df = DataFrame::read_csv!("./data.csv")
/// ```
pub fn DataFrame::read_csv(path : String) -> DataFrame raise {
  guard path.length() >= 4 && path.substring(start=path.length() - 4) == ".csv" else {
    raise NotCSVFile("Specified file is not a CSV file")
  }
  guard @fs.path_exists(path) else {
    raise PathNotFound("Path \{path} not found")
  }
  let file = @fs.read_file_to_string(path)
  let csv = @NyaCSV.CSV::parse_string(file)
  let data = csv.data()
  let header = csv.header()
  let shape = (data.length(), data[0].length())
  let reshaped_data = Array::makei(shape.1, fn(row) {
    Array::makei(shape.0, fn(col) { data[col][row] })
  })
  let series : Array[Series] = Array::makei(shape.1, fn(i) {
    let name = header[i]
    let type_ = type_infer_from_array(reshaped_data[i])
    let series_values = match type_ {
      None => type_convert_from_array(reshaped_data[i])
      Some(type_) => type_convert_from_array(reshaped_data[i], type_~)
    }
    Series::{
      name,
      data: seriesValueArray_to_seriesData(series_values),
      data_type: type_.unwrap(),
      bitmap: BitMap::new_from_SeriesValues_array(series_values),
      length: shape.1,
    }
  })
  DataFrame::new(series)
}

///|
test "DataFrame::read_csv" {
  let df = DataFrame::read_csv("./csv_test/full.csv")
  inspect(df.data()[0].get_type(), content="Int32")
  inspect(df.data()[1].get_type(), content="String")
  inspect(df.data()[2].get_type(), content="Bool")
  inspect(
    try? DataFrame::read_csv("./csv.mbt"),
    content="Err(NotCSVFile(\"Specified file is not a CSV file\"))",
  )
}

///| Convert a NyaCSV.CSV object into a DataFrame
///
/// Parameters
///
/// - `csv` : A NyaCSV.CSV object containing the data to be converted
///
/// Returns
///
/// - `DataFrame` : A DataFrame containing the data from the NyaCSV.CSV object
///
/// Example
/// ```
/// let csv = @NyaCSV.CSV::parse_string("A,B,C\n1,1.5,true\n2,2.0,false\n3,2.5,true")
/// let df = DataFrame::from_NyaCSV(csv)
/// inspect!(df.data()[0].get_type(), content="Int32")
/// inspect!(df.data()[1].get_type(), content="Float32")
/// inspect!(df.data()[2].get_type(), content="Bool")
/// ```
pub fn DataFrame::from_NyaCSV(csv : @NyaCSV.CSV) -> DataFrame {
  let data = csv.data()
  let header = csv.header()
  let shape = (data.length(), data[0].length())
  let reshaped_data = Array::makei(shape.1, fn(row) {
    Array::makei(shape.0, fn(col) { data[col][row] })
  })
  let series : Array[Series] = Array::makei(shape.1, fn(i) {
    let name = header[i]
    let type_ = type_infer_from_array(reshaped_data[i])
    let series_values = match type_ {
      None => type_convert_from_array(reshaped_data[i])
      Some(type_) => type_convert_from_array(reshaped_data[i], type_~)
    }
    Series::{
      name,
      data: seriesValueArray_to_seriesData(series_values),
      data_type: type_.unwrap(),
      bitmap: BitMap::new_from_SeriesValues_array(series_values),
      length: shape.1,
    }
  })
  (try? DataFrame::new(series)).unwrap()
}

///|
test "DataFrame::from_NyaCSV" {
  let csv = @NyaCSV.CSV::parse_string(
    "A,B,C\n1,1.5,true\n2,2.0,false\n3,2.5,true",
  )
  println(csv.to_string())
  let df = DataFrame::from_NyaCSV(csv)
  inspect(df.data()[0].get_type(), content="Int32")
  inspect(df.data()[1].get_type(), content="Float32")
  inspect(df.data()[2].get_type(), content="Bool")
  inspect(df.data()[0].name(), content="A")
}

///| Convert the DataFrame to a `NyaCSV.CSV` object
///
/// Parameters
///
/// - `self` : An instance of the DataFrame
/// - `has_header~` : Whether to include the header row in the CSV (default is true)
///
/// Returns
///
/// - `@NyaCSV.CSV` : A NyaCSV.CSV object representing the DataFrame
///
/// Example
/// ```
/// let csv: @NyaCSV.CSV = df.to_NyaCSV()
/// ```
pub fn DataFrame::to_NyaCSV(
  self : DataFrame,
  has_header~ : Bool = true
) -> @NyaCSV.CSV {
  let data = Array::makei(self.shape[0], fn(j) {
    Array::makei(self.shape[1], fn(i) { self.data[i][j].to_string_csv() })
  })
  if has_header {
    let header = Array::makei(self.shape[1], fn(i) { self.data[i].name })
    data.insert(0, header)
  }
  @NyaCSV.CSV::from_array(data)
}

///|
test "DataFrame::to_NyaCSV" {
  let df = DataFrame::new([
    Series::new("A", SeriesInput::Int32([1, 2, 3])),
    Series::new("B", SeriesInput::Float32([1.5, 2.0, 2.5])),
    Series::new("C", SeriesInput::Bool([true, false, true])),
    Series::new("D", SeriesInput::Str(["a", "b", "c"])),
    Series::new("E", SeriesInput::Int32_Nullable([Some(1), None, Some(3)])),
  ])
  let csv = df.to_NyaCSV()
  inspect(csv.header(), content="[\"A\", \"B\", \"C\", \"D\", \"E\"]")
  inspect(
    csv.data(),
    content="[[\"1\", \"1.5\", \"true\", \"a\", \"1\"], [\"2\", \"2\", \"false\", \"b\", \"\"], [\"3\", \"2.5\", \"true\", \"c\", \"3\"]]",
  )
}

///| Write the DataFrame to a CSV file
///
/// Parameters
///
/// - `self` : An instance of the DataFrame
/// - `path` : The file path where the CSV file will be written
/// - `has_header` : Whether to include the header row in the CSV (default is true)
///
/// Returns
///
/// - `Unit` : This function does not return a value
///
/// Errors
///
/// - `PathNotFound` : Raised if the specified file path does not exist
///
/// Example
/// ```
/// df.write_csv!("./output.csv")
/// ```
pub fn DataFrame::write_csv(
  self : DataFrame,
  path : String,
  has_header~ : Bool = true
) -> Unit raise {
  guard @fs.path_exists(path) else {
    raise PathNotFound("Path \{path} not found")
  }
  let csv = self.to_NyaCSV(has_header~)
  @fs.write_string_to_file(path, csv.to_string())
}

// test "DataFrame::write_csv" {
//   let df = DataFrame::new!([
//     Series::new("A", SeriesInput::Int32([1, 2, 3])),
//     Series::new("B", SeriesInput::Float32([1.5, 2.0, 2.5])),
//     Series::new("C", SeriesInput::Bool([true, false, true])),
//     Series::new("D", SeriesInput::Str(["a", "b", "c"])),
//     Series::new("E", SeriesInput::Int32_Nullable([Some(1), None, Some(3)])),
//   ])
//   df.write_csv!("./csv_test/test_write.csv")
// }
