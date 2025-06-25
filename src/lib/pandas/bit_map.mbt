///|
priv struct BitMap {
  mut optional : Bool
  mut bitmap : Array[Bool]
  mut length : Int
  mut offset : Int
} derive(Show, Eq)

///|
let emptyBitMap : BitMap = BitMap::{
  optional: false,
  bitmap: [],
  length: 0,
  offset: 0,
}

///|
fn[T] BitMap::new(data? : Array[T?]) -> BitMap {
  match data {
    None => BitMap::{ optional: false, bitmap: [], length: 0, offset: 0 }
    Some(data) => {
      let bitmap = Array::makei(data.length(), fn(i) {
        match data[i] {
          None => true
          Some(_) => false
        }
      })
      BitMap::{ optional: true, bitmap, length: data.length(), offset: 0 }
    }
  }
}

///|
impl Add for BitMap with op_add(self : BitMap, other : BitMap) -> BitMap {
  match (self.optional, other.optional) {
    (false, false) => emptyBitMap
    (true, false) => self
    (false, true) => other
    (true, true) => {
      let bitmap = self.bitmap
      bitmap.iter().eachi(fn(i, v) { bitmap[i] = v || other.bitmap[i] })
      BitMap::{
        optional: self.optional || other.optional,
        bitmap,
        length: self.length,
        offset: self.offset,
      }
    }
  }
}

///|
fn BitMap::append(self : BitMap, other : BitMap) -> BitMap {
  match (self.optional, other.optional) {
    (false, false) => emptyBitMap
    (true, true) =>
      BitMap::{
        optional: true,
        bitmap: self.bitmap + other.bitmap,
        length: self.length + other.length,
        offset: self.offset,
      }
    (true, false) =>
      BitMap::{
        optional: true,
        bitmap: self.bitmap + Array::make(other.length, false),
        length: self.length + other.length,
        offset: self.offset,
      }
    (false, true) =>
      BitMap::{
        optional: true,
        bitmap: Array::make(self.length, false) + other.bitmap,
        length: self.length + other.length,
        offset: self.offset,
      }
  }
}

///|
test "BitMap::op_add" {
  let a = BitMap::new(data=[Some(1), None, Some(3)])
  let b = BitMap::new(data=[None, Some(2), Some(3)])
  let c = a + b
  inspect(
    c,
    content="{optional: true, bitmap: [true, true, false], length: 3, offset: 0}",
  )
}

///|
fn BitMap::op_get(self : BitMap, index : Int) -> Bool {
  if self.optional == false {
    return false
  }
  self.bitmap[index]
}

///|
fn BitMap::op_set(self : BitMap, index : Int, value : Bool) -> Unit {
  self.bitmap[index] = value
}

///|
fn BitMap::slice(self : BitMap, start : Int, length? : Int) -> BitMap {
  match self.optional {
    false => emptyBitMap
    true =>
      match length {
        None => {
          let bitmap = self.bitmap.split_at(start).1
          BitMap::{
            optional: self.optional,
            bitmap,
            length: self.length - start,
            offset: self.offset + start,
          }
        }
        Some(length) => {
          let length = @math.minimum(length, self.length - start)
          let bitmap = self.bitmap.split_at(start).1.split_at(length).0
          BitMap::{
            optional: self.optional,
            bitmap,
            length,
            offset: self.offset + start,
          }
        }
      }
  }
}

///|
fn BitMap::has_nulls(self : BitMap) -> Bool {
  match self.optional {
    false => false
    true => self.bitmap.iter().any(fn(v) { v })
  }
}

///|
fn BitMap::clear(
  self : BitMap,
  n~ : Int = 0,
  inplace~ : Bool = false
) -> BitMap {
  match inplace {
    false => BitMap::new_by_size(n, optional=n != 0, value=true)
    true => {
      self.optional = n != 0
      self.bitmap = Array::make(n, true)
      self.length = n
      self.offset = 0
      self
    }
  }
}

///|
fn BitMap::erase(self : BitMap, index : Int) -> Unit {
  self.length -= 1
  self.bitmap.remove(index) |> ignore
}

///|
fn BitMap::swap(self : BitMap, index1 : Int, index2 : Int) -> Unit {
  self.bitmap.swap(index1, index2)
}

///|
fn BitMap::copy(self : BitMap) -> BitMap {
  BitMap::{
    optional: self.optional,
    bitmap: self.bitmap.copy(),
    length: self.length,
    offset: self.offset,
  }
}

///|
fn BitMap::reverse(self : BitMap) -> Unit {
  self.bitmap.rev_inplace()
}

///|
fn BitMap::new_by_size(
  size : Int,
  optional~ : Bool = true,
  value~ : Bool = false
) -> BitMap {
  BitMap::{
    optional,
    bitmap: Array::make(size, value),
    length: size,
    offset: 0,
  }
}

///|
fn BitMap::select_rows(self : BitMap, rows : Array[Int]) -> BitMap {
  match self.optional {
    false => emptyBitMap
    true => {
      rows.sort()
      let bitmap = Array::make(rows.length(), false)
      bitmap.iter().eachi(fn(i, _) { bitmap[i] = self.bitmap[rows[i]] })
      BitMap::{ optional: true, bitmap, length: rows.length(), offset: 0 }
    }
  }
}

///|
test "BitMap::select_rows" {
  let a = BitMap::new(data=[Some(1), None, Some(3)])
  let b = a.select_rows([0, 1])
  inspect(
    b,
    content="{optional: true, bitmap: [false, true], length: 2, offset: 0}",
  )
}

///|
fn BitMap::merge(
  self : BitMap,
  other : BitMap,
  inplace~ : Bool = false
) -> BitMap {
  match inplace {
    false =>
      match (self.optional, other.optional) {
        (false, false) => emptyBitMap
        (true, false) =>
          BitMap::{
            optional: true,
            bitmap: self.bitmap.copy() + Array::make(other.length, false),
            length: self.length + other.length,
            offset: 0,
          }
        (false, true) =>
          BitMap::{
            optional: true,
            bitmap: Array::make(self.length, false) + other.bitmap.copy(),
            length: self.length + other.length,
            offset: 0,
          }
        (true, true) =>
          BitMap::{
            optional: true,
            bitmap: self.bitmap.copy() + other.bitmap.copy(),
            length: self.length + other.length,
            offset: 0,
          }
      }
    true => {
      match (self.optional, other.optional) {
        (false, false) => ()
        (true, false) => {
          self.bitmap += Array::make(other.length, false)
          self.length += other.length
        }
        (false, true) => {
          self.bitmap = Array::make(self.length, false) + other.bitmap
          self.length += other.length
        }
        (true, true) => {
          self.bitmap += other.bitmap
          self.length += other.length
        }
      }
      self
    }
  }
}

///|
test "BitMap::merge" {
  let a = BitMap::new(data=[Some(1), None, Some(3)])
  let b = BitMap::new(data=[Some(1), Some(2), Some(3)])
  a.merge(b, inplace=true) |> ignore
  inspect(
    a,
    content="{optional: true, bitmap: [false, true, false, false, false, false], length: 6, offset: 0}",
  )
}

///|
fn BitMap::new_from_SeriesValues_array(data : Array[SeriesValue]) -> BitMap {
  let n = data.length()
  let null = data
    .iter()
    .all(fn(v) {
      match v {
        SeriesValue::Null => true
        _ => false
      }
    })
  match null {
    true => {
      let bitmap = Array::makei(n, fn(i) {
        match data[i] {
          SeriesValue::Null => true
          _ => false
        }
      })
      BitMap::{ optional: true, bitmap, length: n, offset: 0 }
    }
    false => emptyBitMap
  }
}
