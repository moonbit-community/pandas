///|
test "prim from_options and slice" {
  let a = @arrow.PrimArray::from_options([
    Some(1L),
    None,
    Some(3L),
    None,
    Some(5L),
  ])
  assert_eq(a.null_count(), 2)
  let s = a.slice(1, 3)
  assert_eq(s.to_options(), [None, Some(3L), None])
  assert_eq(s.slice(1, 2).to_options(), [Some(3L), None])
  assert_eq(a.gather([4, 0, 0]).to_options(), [Some(5L), Some(1L), Some(1L)])
  assert_true(a.gather([4, 0]).validity() is None)
}

///|
test "null slots do not affect equality" {
  let a = @arrow.PrimArray::new(
    FixedArray::from_array([1, 99]),
    Some(@arrow.Bitmap::from_array([true, false])),
  )
  let b = @arrow.PrimArray::new(
    FixedArray::from_array([1, 7]),
    Some(@arrow.Bitmap::from_array([true, false])),
  )
  assert_eq(a, b)
  let c = @arrow.PrimArray::new(
    FixedArray::from_array([1, 7]),
    Some(@arrow.Bitmap::from_array([true, true])),
  )
  assert_true(a != c)
  assert_true(c != @arrow.PrimArray::from_array([1, 8]))
  assert_true(c != @arrow.PrimArray::from_array([1]))
}

///|
test "prim from_array and accessors" {
  let a = @arrow.PrimArray::from_array([10, 20, 30])
  assert_eq(a.length(), 3)
  assert_eq(a.null_count(), 0)
  assert_true(a.validity() is None)
  assert_eq(a.get(1), Some(20))
  assert_eq(a.value(2), 30)
  assert_true(a.is_valid(0))
  assert_eq(a.iter().collect(), [Some(10), Some(20), Some(30)])
  assert_eq(a.to_options(), [Some(10), Some(20), Some(30)])
}

///|
test "prim from_options fills null slots with default" {
  let a = @arrow.PrimArray::from_options([Some(1.5), None, Some(-0.0)])
  assert_eq(a.null_count(), 1)
  assert_true(!a.is_valid(1))
  assert_eq(a.get(1), None)
  assert_eq(a.value(1), 0.0)
  assert_true(a.validity() is Some(_))
  let b = @arrow.PrimArray::from_options([Some(1), Some(2)])
  assert_true(b.validity() is None)
  assert_eq(b.null_count(), 0)
}

///|
test "prim slice keeps validity in sync and shares offsets" {
  let xs : Array[Int32?] = Array::makei(200, i => {
    if i % 7 == 0 {
      None
    } else {
      Some(i)
    }
  })
  let a = @arrow.PrimArray::from_options(xs)
  let s = a.slice(61, 100)
  assert_eq(s.length(), 100)
  assert_eq(s.to_options(), xs[61:161].to_owned())
  assert_eq(s.null_count(), xs[61:161].iter().filter(x => x is None).count())
  assert_eq(s.get(0), xs[61])
  assert_eq(s.value(1), 62)
  assert_eq(s, @arrow.PrimArray::from_options(xs[61:161].to_owned()))
  // slice with all valid positions keeps (maybe) a validity but null_count is 0
  let t = @arrow.PrimArray::from_options([None, Some(1), Some(2)]).slice(1, 2)
  assert_eq(t.null_count(), 0)
  assert_eq(t, @arrow.PrimArray::from_array([1, 2]))
  // gather on a slice
  assert_eq(s.gather([99, 0]).to_options(), [xs[160], xs[61]])
}

///|
test "prim gather drops validity when no null is selected" {
  let a = @arrow.PrimArray::from_options([Some(1), None, Some(3)])
  let g = a.gather([2, 0, 2])
  assert_true(g.validity() is None)
  assert_eq(g.to_options(), [Some(3), Some(1), Some(3)])
  let h = a.gather([1, 1])
  assert_eq(h.null_count(), 2)
  assert_eq(h.to_options(), [None, None])
  assert_eq(a.gather([]).length(), 0)
}

///|
test "prim builder" {
  let b = @arrow.PrimBuilder::new(capacity=4)
  b.push(1.5)
  b.push_null()
  b.push_option(Some(2.5))
  b.push_option(None)
  assert_eq(b.length(), 4)
  let a = b.finish()
  assert_eq(a.to_options(), [Some(1.5), None, Some(2.5), None])
  assert_eq(a.null_count(), 2)
  // builder is reusable after finish
  assert_eq(b.length(), 0)
  b.push(9.0)
  let c = b.finish()
  assert_eq(c.to_options(), [Some(9.0)])
  assert_true(c.validity() is None)
  // finishing an empty builder
  let e : @arrow.PrimBuilder[Int32] = @arrow.PrimBuilder::new()
  assert_eq(e.finish().length(), 0)
}

///|
test "prim builder spanning more than one bitmap word" {
  let b : @arrow.PrimBuilder[Int32] = @arrow.PrimBuilder::new()
  for i in 0..<130 {
    if i % 5 == 0 {
      b.push_null()
    } else {
      b.push(i)
    }
  }
  let a = b.finish()
  assert_eq(a.length(), 130)
  assert_eq(a.null_count(), 26)
  assert_eq(a.get(65), None)
  assert_eq(a.get(66), Some(66))
}

///|
test "prim float equality uses element ==" {
  let nan = 0.0 / 0.0
  let a = @arrow.PrimArray::from_array([nan])
  assert_true(a != a)
  assert_eq(
    @arrow.PrimArray::from_array([0.0]),
    @arrow.PrimArray::from_array([-0.0]),
  )
}

///|
test "empty prim arrays" {
  let e : @arrow.PrimArray[Int32] = @arrow.PrimArray::from_array([])
  assert_eq(e.length(), 0)
  assert_eq(e.null_count(), 0)
  assert_eq(e.slice(0, 0).length(), 0)
  assert_eq(e.gather([]).length(), 0)
  assert_eq(e.to_options(), [])
  let o : @arrow.PrimArray[Int32] = @arrow.PrimArray::from_options([])
  assert_eq(e, o)
}

///|
test "debug shows options" {
  let a = @arrow.PrimArray::from_options([Some(1), None])
  assert_eq(@debug.to_string(a), @debug.to_string([Some(1), None]))
}

///|
test "panic prim new length mismatch" {
  ignore(
    @arrow.PrimArray::new(
      FixedArray::from_array([1, 2]),
      Some(@arrow.Bitmap::from_array([true])),
    ),
  )
}

///|
test "panic prim slice out of range" {
  ignore(@arrow.PrimArray::from_array([1, 2, 3]).slice(2, 2))
}

///|
test "panic prim slice negative offset" {
  ignore(@arrow.PrimArray::from_array([1, 2, 3]).slice(-1, 1))
}

///|
test "panic prim slice length overflow" {
  ignore(@arrow.PrimArray::from_array([1, 2, 3]).slice(1, 2147483647))
}

///|
test "panic prim gather out of range" {
  ignore(@arrow.PrimArray::from_array([1, 2, 3]).gather([3]))
}

///|
test "panic prim gather negative" {
  ignore(@arrow.PrimArray::from_array([1, 2, 3]).gather([-1]))
}

///|
test "panic prim value out of range" {
  ignore(@arrow.PrimArray::from_array([1, 2, 3]).value(3))
}

///|
test "panic prim value beyond a slice" {
  // index 2 exists in the backing array but not in the 2-element window
  ignore(@arrow.PrimArray::from_array([1, 2, 3]).slice(0, 2).value(2))
}
