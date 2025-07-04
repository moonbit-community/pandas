///| sort the data by the indices
fn[T] indices_sort(data : Array[T], indices : Array[Int]) -> Unit {
  let n = data.length()
  let visited = Array::make(n, false)
  for i = 0; i < n; i = i + 1 {
    let mut current = i
    while visited[current] == false {
      visited[current] = true
      let next = indices[current]
      if next == i {
        break
      }
      data.swap(current, next)
      current = next
    }
  }
}

///|
test "indices_sort" {
  let arr = [3, 2, 1]
  let indices = [2, 1, 0]
  indices_sort(arr, indices)
  inspect(arr, content="[1, 2, 3]")
}

///|
fn type_check_operation(a : DataType, b : DataType) -> Bool {
  match (a, b) {
    (DataType::Int32, DataType::Int32)
    | (DataType::Float32, DataType::Float32)
    | (DataType::Int32, DataType::Float32)
    | (DataType::Float32, DataType::Int32)
    | (DataType::String, DataType::String)
    | (DataType::Bool, DataType::Bool) => true
    _ => false
  }
}

// fn type_check_equal(a : DataType, b : DataType) -> Bool {
//   match (a, b) {
//     (DataType::Int32, DataType::Int32) |
//     (DataType::Float32, DataType::Float32) |
//     (DataType::String, DataType::String) |
//     (DataType::Bool, DataType::Bool) => true
//     _ => false
//   }
// }

///|
fn quick_pow(base : Int64, exp : Int) -> Int64 {
  let mut result = 1L
  let mut base = base
  let mut exp = exp
  while exp > 0 {
    if exp % 2 == 1 {
      result = result * base
    }
    base = base * base
    exp = exp / 2
  }
  result
}
