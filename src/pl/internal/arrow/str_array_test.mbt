///|
test "str builder" {
  let b = @arrow.StrBuilder::new()
  b.push("a")
  b.push_null()
  b.push_option(Some(""))
  assert_eq(b.finish().to_options(), [Some("a"), None, Some("")])
}

///|
test "str from_options slice gather" {
  let a = @arrow.StrArray::from_options([
    Some("x"),
    None,
    Some("z"),
    None,
    Some(""),
  ])
  assert_eq(a.length(), 5)
  assert_eq(a.null_count(), 2)
  let s = a.slice(1, 3)
  assert_eq(s.to_options(), [None, Some("z"), None])
  assert_eq(s.slice(1, 2).to_options(), [Some("z"), None])
  assert_eq(a.gather([4, 0, 0]).to_options(), [Some(""), Some("x"), Some("x")])
  assert_true(a.gather([4, 0]).validity() is None)
  assert_eq(a.gather([1]).null_count(), 1)
}

///|
test "str accessors" {
  let a = @arrow.StrArray::from_options([Some("é"), None])
  assert_eq(a.get(0), Some("é"))
  assert_eq(a.get(1), None)
  assert_eq(a.value(1), "")
  assert_true(a.is_valid(0))
  assert_true(!a.is_valid(1))
  assert_eq(a.iter().collect(), [Some("é"), None])
  let b = @arrow.StrArray::from_array(["a", "b"])
  assert_true(b.validity() is None)
  assert_eq(b.null_count(), 0)
  assert_true(@arrow.StrArray::from_options([Some("a")]).validity() is None)
}

///|
test "str null slots do not affect equality" {
  let v = Some(@arrow.Bitmap::from_array([true, false]))
  let a = @arrow.StrArray::new(FixedArray::from_array(["a", "zzz"]), v)
  let b = @arrow.StrArray::new(FixedArray::from_array(["a", ""]), v)
  assert_eq(a, b)
  assert_true(a != @arrow.StrArray::from_array(["a", ""]))
  assert_true(a != @arrow.StrArray::from_array(["a"]))
  assert_true(
    @arrow.StrArray::from_array(["a", "b"]) !=
    @arrow.StrArray::from_array(["a", "c"]),
  )
}

///|
test "str slice across word boundaries" {
  let xs : Array[String?] = Array::makei(200, i => {
    if i % 7 == 0 {
      None
    } else {
      Some("v\{i}")
    }
  })
  let a = @arrow.StrArray::from_options(xs)
  let s = a.slice(61, 100)
  assert_eq(s.to_options(), xs[61:161].to_owned())
  assert_eq(s.null_count(), xs[61:161].iter().filter(x => x is None).count())
  assert_eq(s, @arrow.StrArray::from_options(xs[61:161].to_owned()))
  assert_eq(s.gather([99, 0]).to_options(), [xs[160], xs[61]])
  assert_eq(s.value(1), "v62")
}

///|
test "str builder reuse" {
  let b = @arrow.StrBuilder::new(capacity=2)
  b.push("q")
  assert_eq(b.length(), 1)
  assert_eq(b.finish().to_options(), [Some("q")])
  assert_eq(b.length(), 0)
  b.push_null()
  let c = b.finish()
  assert_eq(c.to_options(), [None])
  assert_eq(c.null_count(), 1)
  assert_eq(@arrow.StrBuilder::new().finish().length(), 0)
}

///|
test "empty str arrays" {
  assert_eq(@arrow.StrArray::from_options([]).slice(0, 0).null_count(), 0)
  assert_eq(@arrow.StrArray::from_array([]).gather([]).length(), 0)
}

///|
test "str debug" {
  let a = @arrow.StrArray::from_options([Some("a"), None])
  assert_eq(@debug.to_string(a), @debug.to_string([Some("a"), None]))
}

///|
test "panic str new length mismatch" {
  ignore(
    @arrow.StrArray::new(
      FixedArray::from_array(["a", "b"]),
      Some(@arrow.Bitmap::from_array([true])),
    ),
  )
}

///|
test "panic str slice out of range" {
  ignore(@arrow.StrArray::from_array(["a"]).slice(1, 1))
}

///|
test "panic str gather out of range" {
  ignore(@arrow.StrArray::from_array(["a"]).gather([-1]))
}

///|
test "panic str value out of range" {
  ignore(@arrow.StrArray::from_array(["a"]).value(1))
}
