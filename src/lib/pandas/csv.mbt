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
/// inspect!(df.data()[0].get_type(), content="Int32")
/// inspect!(df.data()[1].get_type(), content="String")
/// inspect!(df.data()[2].get_type(), content="Bool")
/// ```
pub fn DataFrame::read_csv(path: String) -> DataFrame! {
  guard path.length() >= 4 && path.substring(start=path.length()-4) == ".csv" else {
    raise NotCSVFile("Specified file is not a CSV file")
  }
  guard @fs.path_exists(path) else {
    raise PathNotFound("Path \{path} not found")
  }
  let file = @fs.read_file_to_string!(path)
  let csv = @NyaCSV.CSV::parse_string(file)
  let data = csv.data()
  let header = csv.header()
  let shape = (data.length(), data[0].length())
  let reshaped_data = Array::makei(shape.1, fn(row){
    Array::makei(shape.0, fn(col){
      data[col][row]
    })
  })
  let series: Array[Series] = Array::makei(shape.1, fn(i){
    let name = header[i]
    let type_ = type_infer_from_array(reshaped_data[i])
    let series_values = match type_ {
      None => type_convert_from_array(reshaped_data[i])
      Some(type_) => type_convert_from_array(reshaped_data[i], type_ = type_)
    }
    Series::{
      name: name,
      data: seriesValueArray_to_seriesData(series_values),
      data_type: type_.unwrap(),
      bitmap: BitMap::new_from_SeriesValues_array(series_values),
      length: shape.1,
    }
  })
  DataFrame::new!(series)
}

test "DataFrame::read_csv" {
  let df = DataFrame::read_csv!("./csv_test/full.csv")
  inspect!(df.data()[0].get_type(), content="Int32")
  inspect!(df.data()[1].get_type(), content="String")
  inspect!(df.data()[2].get_type(), content="Bool")

  inspect!(DataFrame::read_csv?("./csv.mbt"), content="Err(NotCSVFile(\"Specified file is not a CSV file\"))")
}