///|
struct BitMap {
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
fn BitMap::new[T](data? : Array[T?]) -> BitMap {
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
fn BitMap::op_add(self : BitMap, other : BitMap) -> BitMap {
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

test "BitMap::op_add" {
  let a = BitMap::new(data=[Some(1), None, Some(3)])
  let b = BitMap::new(data=[None, Some(2), Some(3)])
  let c = a + b
  inspect!(
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
fn BitMap::clear(self : BitMap) -> Unit {
  self.optional = false
  self.bitmap = []
  self.length = 0
  self.offset = 0
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
fn BitMap::new_by_size(size : Int, optional~ : Bool = true) -> BitMap {
  BitMap::{
    optional,
    bitmap: Array::make(size, false),
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

test "BitMap::select_rows" {
  let a = BitMap::new(data=[Some(1), None, Some(3)])
  let b = a.select_rows([0, 1])
  inspect!(
    b,
    content="{optional: true, bitmap: [false, true], length: 2, offset: 0}",
  )
}
