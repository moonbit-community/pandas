///|
/// A frame of `n` rows (the shortest of the arrays) with a column of every
/// type, including a `Null` column.
fn concat_prop_frame(
  i32s : Array[Int32?],
  i64s : Array[Int64?],
  f64s : Array[Double?],
  strs : Array[String?],
  bools : Array[Bool?],
) -> @pl.DataFrame {
  let mut n = i32s.length()
  for len in [i64s.length(), f64s.length(), strs.length(), bools.length()] {
    if len < n {
      n = len
    }
  }
  let f32s : Array[Float?] = f64s[:n].map(x => x.map(v => Float::from_double(v)))
  @pl.DataFrame::new([
    @pl.Series::int32_nullable("i32", i32s[:n].to_owned()),
    @pl.Series::int64_nullable("i64", i64s[:n].to_owned()),
    @pl.Series::float32_nullable("f32", f32s),
    @pl.Series::float64_nullable("f64", f64s[:n].to_owned()),
    @pl.Series::str_nullable("s", strs[:n].to_owned()),
    @pl.Series::bool_nullable("b", bools[:n].to_owned()),
    @pl.Series::date_nullable("d", i32s[:n].to_owned()),
    @pl.Series::datetime_nullable("dt", i64s[:n].to_owned()),
    @pl.Series::null("n", n.to_int()),
  ]) catch {
    e => abort("concat_prop_frame: \{e}")
  }
}

///|
test "prop: a frame cut in two and concatenated again is the frame" {
  @quickcheck.check(
    (
      t : (
        Array[Int32?],
        Array[Int64?],
        Array[Double?],
        Array[String?],
        Array[Bool?],
        Int32,
      ),
    ) => {
      let (a, b, c, d, e, cut) = t
      let df = concat_prop_frame(a, b, c, d, e)
      let h = df.height()
      let k = if h == 0 { 0 } else { (cut % (h + 1) + h + 1) % (h + 1) }
      let joined = @pl.concat([df.slice(0, length=k), df.slice(k)]) catch {
        _ => return false
      }
      joined == df
    },
    count=300,
    max_size=40,
  )
}

///|
test "prop: a frame cut in three, in every mode that keeps the schema" {
  @quickcheck.check(
    (
      t : (
        Array[Int32?],
        Array[Int64?],
        Array[Double?],
        Array[String?],
        Array[Bool?],
        Int32,
        Int32,
      ),
    ) => {
      let (a, b, c, d, e, c1, c2) = t
      let df = concat_prop_frame(a, b, c, d, e)
      let h = df.height()
      let k1 = if h == 0 { 0 } else { (c1 % (h + 1) + h + 1) % (h + 1) }
      let k2 = if h == 0 { 0 } else { (c2 % (h + 1) + h + 1) % (h + 1) }
      let lo = if k1 < k2 { k1 } else { k2 }
      let hi = if k1 < k2 { k2 } else { k1 }
      let parts = [
        df.slice(0, length=lo),
        df.slice(lo, length=hi - lo),
        df.slice(hi),
      ]
      for
        how in [
          @pl.ConcatHow::Vertical,
          @pl.ConcatHow::VerticalRelaxed,
          @pl.ConcatHow::Diagonal,
        ] {
        let joined = @pl.concat(parts, how~) catch { _ => return false }
        if joined != df {
          return false
        }
      }
      // vstack twice gives the same rows as one three-way concat
      let stacked = parts[0].vstack(parts[1]).vstack(parts[2]) catch {
          _ => return false
        }
      stacked == df
    },
    count=200,
    max_size=40,
  )
}

///|
test "prop: append keeps the values of both series in order" {
  @quickcheck.check(
    (t : (Array[Int64?], Array[Int64?])) => {
      let (xs, ys) = t
      let a = @pl.Series::int64_nullable("a", xs)
      let b = @pl.Series::int64_nullable("b", ys)
      let r = a.append(b) catch { _ => return false }
      r.name() == "a" && r.to_int64_array() == xs + ys
    },
    count=300,
    max_size=40,
  )
}

///|
test "prop: horizontal concat of the two halves of the columns is the frame" {
  @quickcheck.check(
    (
      t : (
        Array[Int32?],
        Array[Int64?],
        Array[Double?],
        Array[String?],
        Array[Bool?],
      ),
    ) => {
      let (a, b, c, d, e) = t
      let df = concat_prop_frame(a, b, c, d, e)
      let cols = df.get_columns()
      let left = @pl.DataFrame::new(cols[:4].to_owned()) catch {
        _ => return false
      }
      let right = @pl.DataFrame::new(cols[4:].to_owned()) catch {
        _ => return false
      }
      let joined = @pl.concat([left, right], how=Horizontal) catch {
        _ => return false
      }
      joined == df
    },
    count=200,
    max_size=40,
  )
}
