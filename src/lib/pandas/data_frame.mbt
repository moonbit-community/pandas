pub(all) struct DataFrame {
  data: Array[Series]
  shape: Array[Int]
} derive(Show)

pub fn DataFrame::new(data: Array[Series]) -> DataFrame {
  DataFrame :: {
    data: data,
    shape: [data[0].data().length(), data.length()],
  }
}

pub fn DataFrame::shape(self : DataFrame) -> Array[Int] {
  self.shape
}

pub fn DataFrame::data(self : DataFrame) -> Array[Series] {
  self.data
}

pub fn DataFrame::head(self : DataFrame) -> Unit {
  let mut row_str = "\t"
  for col in self.data {
    row_str = row_str + col.name() + "\t"
  }
  println(row_str)
  row_str = ""
  for i=0; i < @math.minimum(5, self.shape()[0]); i=i+1 {
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
  let data_frame = DataFrame::new([
    Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6])), 
    Series::new("B", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
    Series::new("C", SeriesData::Bool([true, false, true, false, true, false])),
    Series::new("D", SeriesData::Str(["a", "b", "c", "d", "e", "f"])),
  ])
  assert_eq!(data_frame.shape(), [6, 4])
  data_frame.head()
}