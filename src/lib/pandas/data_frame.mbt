///|
pub(all) struct DataFrame {
  data : Array[Series]
  shape : Array[Int]
}

///|
type! InconsistentSeriesLength String derive(Show)
pub fn DataFrame::new(data : Array[Series]) -> DataFrame!InconsistentSeriesLength {
  for i = 1; i < data.length(); i=i+1 {
    if data[i].data().length() != data[0].data().length() {
      raise InconsistentSeriesLength("Could not create a new DataFrame. The Series lengths are not equal.")
    }
  }
  DataFrame::{ data, shape: [data[0].data().length(), data.length()] }
}

///|
pub fn DataFrame::shape(self : DataFrame) -> Array[Int] {
  self.shape
}

///|
pub fn DataFrame::data(self : DataFrame) -> Array[Series] {
  self.data
}

///|
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

///|
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

test "data_frame" {
  let df = DataFrame::new!([
    Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
    Series::new("C", SeriesData::Bool([true, false, true, false, true, false])),
    Series::new("D", SeriesData::Str(["a", "b", "c", "d", "e", "f"])),
  ])
  assert_eq!(df.shape(), [6, 4])
  df.head()
  println(df)
}
