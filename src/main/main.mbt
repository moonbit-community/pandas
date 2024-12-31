///|
fn main {
  let df = @pandas.DataFrame::new?([
    @pandas.Series::new("A", @pandas.SeriesData::Int([1, 2, 3, 4, 5, 6])),
    @pandas.Series::new("B", @pandas.SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
    @pandas.Series::new("C", @pandas.SeriesData::Bool([true, false, true, false, true, false])),
    @pandas.Series::new("D", @pandas.SeriesData::Str(["a", "b", "c", "d", "e", "f"])),
  ])
  println(df)
}
