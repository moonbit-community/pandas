///| Tests
test "series" {
  let series = Series::new("test", SeriesInput::Int32([1, 2, 3, 4, 5]))
  assert_eq!(series.name(), "test")
  assert_eq!(series.data(), SeriesData::Int([1, 2, 3, 4, 5]))
}

test "argsort_indices" {
  let series = Series::new("test", SeriesInput::Int32([2, 1, 3, 5, 4]))
  let indices = series.data.get_argsort_indices()
  inspect!(indices, content="[1, 0, 2, 4, 3]")
  let series = Series::new("test", SeriesInput::Str(["a", "b", "c", "d", "e"]))
  inspect!(series.data.get_argsort_indices(), content="[0, 1, 2, 3, 4]")
}

// test "argsort" {
//   let series = Series::new("test", SeriesInput::Int32([2, 1, 3, 5, 4]))
//   let indices = series.argsort()
//   // inspect!(indices, content="[1, 0, 2, 4, 3]")
// }

// test "series_add" {
//   let a = Series::new("a", SeriesData::Float([1.5, 2, 3.5]))
//   let b = Series::new("b", SeriesData::Int([4, 5, 6]))
//   let c = a.data + b.data
//   inspect!(c, content="Float([5.5, 7, 9.5])")
//   let c = a + b
//   inspect!(c, content="{name: \"a\", data: Float([5.5, 7, 9.5]), data_type: Float32, bitmap: {optional: false, bitmap: [], length: 0, offset: 0}}")
// }

// test "series_sub" {
//   let a = Series::new("a", SeriesData::Float([1.5, 2, 3.5]))
//   let b = Series::new("b", SeriesData::Int([4, 5, 6]))
//   let c = a.data - b.data
//   inspect!(c, content="Float([-2.5, -3, -2.5])")
//   let c = a - b
//   inspect!(c, content="{name: \"a\", data: Float([-2.5, -3, -2.5]), data_type: Float32, bitmap: {optional: false, bitmap: [], length: 0, offset: 0}}")
// }

// test "series_mul" {
//   let a = Series::new("a", SeriesData::Float([1.5, 2, 3.5]))
//   let b = Series::new("b", SeriesData::Int([4, 5, 6]))
//   let c = a.data * b.data
//   inspect!(c, content="Float([6, 10, 21])")
//   let c = a * b
//   inspect!(c, content="{name: \"a\", data: Float([6, 10, 21]), data_type: Float32, bitmap: {optional: false, bitmap: [], length: 0, offset: 0}}")
// }

// test "series_div" {
//   let a = Series::new("a", SeriesData::Int([2, 4, 9]))
//   let b = Series::new("b", SeriesData::Int([1, 2, 3]))
//   let c = a.data / b.data
//   inspect!(c, content="Int([2, 2, 3])")
//   let c = a / b
//   inspect!(c, content="{name: \"a\", data: Int([2, 2, 3]), data_type: Int32, bitmap: {optional: false, bitmap: [], length: 0, offset: 0}}")
// }

test "Series::var/int" {
  let series = Series::new("test", SeriesInput::Int32([1, 2, 3, 4, 5]))
  inspect!(series.var!(), content="2.5")
}

test "Series::var/float" {
  let series = Series::new(
    "test",
    SeriesInput::Float32([1.5, 2.0, 3.5, 4.0, 5.5]),
  )
  series.var!() |> ignore
  // series.var!() |> println
  // 2.575
}

test "Series::var/ddof" {
  let series = Series::new(
    "test",
    SeriesInput::Float32([1.5, 2.0, 3.5, 4.0, 5.0]),
  )
  series.var!(ddof=1) |> ignore
  // series.var!(ddof=1) |> println
  // 2.075
}

test "panic Series::var/invalid_type" {
  let series = Series::new("test", SeriesInput::Str(["a", "b", "c"]))
  ignore(series.var!())
}

test "panic Series::var/empty_array" {
  let series = Series::new("test", SeriesInput::Int32([]))
  ignore(series.var!())
}

test "Series::sort" {
  let series = Series::new("test", SeriesInput::Int32([2, 1, 3, 5, 4]))
  series.sort()
  inspect!(series.data, content="Int([1, 2, 3, 4, 5])")
  let series = Series::new(
    "test",
    SeriesInput::Int32_Nullable([Some(2), None, Some(3)]),
  )
  // println(series.bitmap)
  series.sort()
  inspect!(series.data, content="Int([0, 2, 3])")
}

test "Series::length()" {
  let series = Series::new("test", SeriesInput::Int32([1, 2, 3, 4, 5]))
  assert_eq!(series.length(), 5)
}

// test "SeriesValue::op_compare" {
//   let a = SeriesValue::Int(1)
//   let b = SeriesValue::Null
//   println(a < b)
// }

test "Series::max" {
  let series = Series::new("test", SeriesInput::Int32([1, 3, 2]))
  inspect!(series.max!(), content="Int(3)")
  let series = Series::new(
    "test",
    SeriesInput::Int32_Nullable([None, None, None]),
  )
  inspect!(series.max!(), content="Null")
}

test "Series::min" {
  let series = Series::new("test", SeriesInput::Int32([1, 3, 2]))
  inspect!(series.min!(), content="Int(1)")
  let series = Series::new(
    "test",
    SeriesInput::Int32_Nullable([None, None, None]),
  )
  inspect!(series.min!(), content="Null")
}

test "Series::is_null" {
  let series = Series::new(
    "test",
    SeriesInput::Int32_Nullable([Some(1), None, Some(2)]),
  )
  inspect!(
    series.is_null().data.to_string(),
    content="Bool([false, true, false])",
  )
  let series = Series::new("test", SeriesInput::Int32([1, 2, 3]))
  inspect!(
    series.is_null().data.to_string(),
    content="Bool([false, false, false])",
  )
}

test "Series::is_not_null" {
  let series = Series::new(
    "test",
    SeriesInput::Int32_Nullable([Some(1), None, Some(2)]),
  )
  inspect!(
    series.is_not_null().data.to_string(),
    content="Bool([true, false, true])",
  )
}

test "Series::is_sorted" {
  let series = Series::new("test", SeriesInput::Int32([1, 2, 3]))
  inspect!(series.is_sorted(), content="true")
  let series = Series::new("test", SeriesInput::Int32([3, 2, 1]))
  inspect!(series.is_sorted(descending=true), content="true")
  let series = Series::new(
    "test",
    SeriesInput::Int32_Nullable([Some(1), None, Some(3)]),
  )
  inspect!(series.is_sorted(), content="false")
  let series = Series::new(
    "test",
    SeriesInput::Int32_Nullable([None, Some(1), Some(3)]),
  )
  inspect!(series.is_sorted(), content="true")
  let series = Series::new(
    "test",
    SeriesInput::Int32_Nullable([Some(3), Some(2), None]),
  )
  inspect!(series.is_sorted(descending=true, nulls_last=true), content="true")
}

test "Series::null_count" {
  let series = Series::new(
    "test",
    SeriesInput::Int32_Nullable([Some(1), None, Some(2)]),
  )
  inspect!(series.null_count(), content="1")
}

test "Series::n_unique" {
  let series = Series::new("test", SeriesInput::Int32([1, 2, 3, 1]))
  inspect!(series.n_unique(), content="3")
  let series = Series::new(
    "test",
    SeriesInput::Int32_Nullable([Some(1), None, Some(3), Some(1)]),
  )
  inspect!(series.n_unique(), content="2")
}
