///| sort the data by the indices
fn indices_sort[T](data : Array[T], indices : Array[Int]) -> Unit {
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

test "indices_sort" {
  let arr = [3, 2, 1]
  let indices = [2, 1, 0]
  indices_sort(arr, indices)
  inspect!(arr, content="[1, 2, 3]")
}
