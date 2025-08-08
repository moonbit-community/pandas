///|
fn main {
  let df = try? @pandas.DataFrame::new([
    @pandas.Series::new("A", @pandas.SeriesInput::Int32([1, 2, 3, 4, 5, 6])),
    @pandas.Series::new(
      "B",
      @pandas.SeriesInput::Float32([1.5, 2.0, 3.5, 4.0, 5.5, 6.0]),
    ),
    @pandas.Series::new(
      "C",
      @pandas.SeriesInput::Bool([true, false, true, false, true, false]),
    ),
    @pandas.Series::new(
      "D",
      @pandas.SeriesInput::Str(["a", "b", "c", "d", "e", "f"]),
    ),
  ])
  println(df)
}
