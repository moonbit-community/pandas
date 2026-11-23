///|
test "bool from_options and slice" {
  let a = @arrow.BoolArray::from_options([
    Some(true),
    None,
    Some(false),
    None,
    Some(true),
  ])
  assert_eq(a.length(), 5)
  assert_eq(a.null_count(), 2)
  let s = a.slice(1, 3)
  assert_eq(s.to_options(), [None, Some(false), None])
  assert_eq(s.slice(1, 2).to_options(), [Some(false), None])
  assert_eq(a.gather([4, 0, 0]).to_options(), [
    Some(true),
    Some(true),
    Some(true),
  ])
  assert_true(a.gather([4, 0]).validity() is None)
  assert_eq(a.gather([4, 1]).null_count(), 1)
}

///|
test "bool null slots do not affect equality" {
  let a = @arrow.BoolArray::new(
    @arrow.Bitmap::from_array([true, true, false]),
    Some(@arrow.Bitmap::from_array([true, false, true])),
  )
  let b = @arrow.BoolArray::new(
    @arrow.Bitmap::from_array([true, false, false]),
    Some(@arrow.Bitmap::from_array([true, false, true])),
  )
  assert_eq(a, b)
  let c = @arrow.BoolArray::new(
    @arrow.Bitmap::from_array([true, false, false]),
    Some(@arrow.Bitmap::from_array([true, true, true])),
  )
  assert_true(a != c)
  assert_true(c != @arrow.BoolArray::from_array([true, false, true]))
  assert_eq(c, @arrow.BoolArray::from_array([true, false, false]))
  assert_true(c != @arrow.BoolArray::from_array([true, false]))
}

///|
test "bool accessors" {
  let a = @arrow.BoolArray::from_options([Some(true), None, Some(false)])
  assert_eq(a.get(0), Some(true))
  assert_eq(a.get(1), None)
  assert_eq(a.get(2), Some(false))
  assert_eq(a.value(1), false)
  assert_true(!a.is_valid(1))
  assert_eq(a.iter().collect(), [Some(true), None, Some(false)])
  assert_eq(@arrow.BoolArray::from_array([true, false]).null_count(), 0)
  assert_true(@arrow.BoolArray::from_array([true]).validity() is None)
  assert_true(@arrow.BoolArray::from_options([Some(true)]).validity() is None)
}

///|
test "bool slice across word boundaries" {
  let xs : Array[Bool?] = Array::makei(200, i => {
    if i % 7 == 0 {
      None
    } else {
      Some(i % 3 == 0)
    }
  })
  let a = @arrow.BoolArray::from_options(xs)
  let s = a.slice(61, 100)
  assert_eq(s.to_options(), xs[61:161].to_owned())
  assert_eq(s.null_count(), xs[61:161].iter().filter(x => x is None).count())
  assert_eq(s, @arrow.BoolArray::from_options(xs[61:161].to_owned()))
  assert_eq(s.gather([99, 0]).to_options(), [xs[160], xs[61]])
}

///|
test "bool builder" {
  let b = @arrow.BoolBuilder::new(capacity=3)
  b.push(true)
  b.push_null()
  b.push_option(Some(false))
  b.push_option(None)
  assert_eq(b.length(), 4)
  let a = b.finish()
  assert_eq(a.to_options(), [Some(true), None, Some(false), None])
  assert_eq(b.length(), 0)
  b.push(false)
  let c = b.finish()
  assert_eq(c.to_options(), [Some(false)])
  assert_true(c.validity() is None)
  assert_eq(@arrow.BoolBuilder::new().finish().length(), 0)
}

///|
test "empty arrays" {
  assert_eq(@arrow.BoolArray::from_array([]).length(), 0)
  assert_eq(@arrow.BoolArray::from_options([]).slice(0, 0).null_count(), 0)
  assert_eq(@arrow.BoolArray::from_array([]).gather([]).to_options(), [])
}

///|
test "bool debug" {
  let a = @arrow.BoolArray::from_options([Some(true), None])
  assert_eq(@debug.to_string(a), @debug.to_string([Some(true), None]))
}

///|
test "panic bool new length mismatch" {
  ignore(
    @arrow.BoolArray::new(
      @arrow.Bitmap::from_array([true, false]),
      Some(@arrow.Bitmap::from_array([true])),
    ),
  )
}

///|
test "panic bool slice out of range" {
  ignore(@arrow.BoolArray::from_array([true]).slice(0, 2))
}

///|
test "panic bool gather out of range" {
  ignore(@arrow.BoolArray::from_array([true]).gather([1]))
}

///|
test "panic bool value out of range" {
  ignore(@arrow.BoolArray::from_array([true]).value(1))
}

///|
test "bool inequality: valid values, null versus false, both orders" {
  // same validity, different valid value
  assert_true(
    @arrow.BoolArray::from_options([Some(true), None]) !=
    @arrow.BoolArray::from_options([Some(false), None]),
  )
  assert_true(
    @arrow.BoolArray::from_options([None, Some(true)]) !=
    @arrow.BoolArray::from_options([None, Some(false)]),
  )
  // null versus false, in both operand orders, with validity on the null side
  let null_arr = @arrow.BoolArray::from_options([None])
  let false_arr = @arrow.BoolArray::from_array([false])
  let true_arr = @arrow.BoolArray::from_array([true])
  assert_true(null_arr != false_arr)
  assert_true(false_arr != null_arr)
  assert_true(null_arr != true_arr)
  assert_true(true_arr != null_arr)
  // a validity bitmap that is all valid equals the plain array, both orders
  let all_valid = @arrow.BoolArray::new(
    @arrow.Bitmap::from_array([true, false]),
    Some(@arrow.Bitmap::from_array([true, true])),
  )
  let plain = @arrow.BoolArray::from_array([true, false])
  assert_true(all_valid == plain)
  assert_true(plain == all_valid)
  // ... and differs from a plain array with another value, both orders
  let other = @arrow.BoolArray::from_array([true, true])
  assert_true(all_valid != other)
  assert_true(other != all_valid)
  // one null among valid slots versus a plain array, both orders
  let one_null = @arrow.BoolArray::from_options([Some(false), None])
  let plain_f = @arrow.BoolArray::from_array([false, false])
  assert_true(one_null != plain_f)
  assert_true(plain_f != one_null)
  // same validity and values: equal
  assert_true(
    @arrow.BoolArray::from_options([Some(true), None]) ==
    @arrow.BoolArray::from_options([Some(true), None]),
  )
}

///|
test "prop: bool arrays are equal exactly when their options are" {
  @quickcheck.check(
    (t : (Array[Bool?], Array[Bool?])) => {
      let (xs, ys) = t
      (@arrow.BoolArray::from_options(xs) == @arrow.BoolArray::from_options(ys)) ==
      (xs == ys)
    },
    count=500,
    max_size=70,
  )
}

///|
test "prop: changing one element makes bool arrays unequal" {
  @quickcheck.check(
    (t : (Array[Bool?], UInt32, Int32)) => {
      let (xs, pos, pick) = t
      if xs.length() == 0 {
        return true
      }
      let i = (pos % xs.length().reinterpret_as_uint()).reinterpret_as_int()
      // pick one of the three states that differs from the current one
      let all : Array[Bool?] = [None, Some(false), Some(true)]
      let candidates = all.filter(c => c != xs[i])
      let r = candidates[pick & 1]
      let ys = xs.copy()
      ys[i] = r
      let a = @arrow.BoolArray::from_options(xs)
      let b = @arrow.BoolArray::from_options(ys)
      a != b && b != a
    },
    count=500,
    max_size=130,
  )
}
