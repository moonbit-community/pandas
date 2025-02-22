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
  let bitmap = self.bitmap
  bitmap.iter().eachi(fn(i, v) { bitmap[i] = v && other.bitmap[i] })
  BitMap::{
    optional: self.optional || other.optional,
    bitmap,
    length: self.length,
    offset: self.offset,
  }
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

fn BitMap::swap(self: BitMap, index1: Int, index2: Int) -> Unit {
  self.bitmap.swap(index1, index2)
}