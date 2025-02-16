struct BitMap {
    optional : Bool
    bitmap : Array[Bool]
    length : Int
    offset : Int
} derive(Show, Eq)

let emptyBitMap : BitMap = BitMap::{ optional: false, bitmap: [], length: 0, offset: 0 }

fn BitMap::new[T](data? : Array[Option[T]]) -> BitMap {
    match data {
        None => BitMap::{ optional: false, bitmap: [], length: 0, offset: 0 }
        Some(data) => {
          let bitmap = Array::makei(data.length(), fn(i) { match data[i] { 
            None => false 
            Some(_) => true 
          } })
          BitMap::{ optional: true, bitmap: bitmap, length: data.length(), offset: 0 }
        }
    }
}

fn BitMap::op_add(self : BitMap, other : BitMap) -> BitMap {
    let bitmap = self.bitmap
    bitmap.iter().eachi(fn(i, v) { bitmap[i] = v && other.bitmap[i] })
    BitMap::{ optional: self.optional || other.optional, bitmap: bitmap, length: self.length, offset: self.offset }
}

fn BitMap::op_get(self : BitMap, index : Int) -> Bool {
    self.bitmap[index]
}

fn BitMap::slice(self : BitMap, start : Int, length? : Int) -> BitMap {
    match length {
        None => {
            let bitmap = self.bitmap.split_at(start).1
            BitMap::{ optional: self.optional, bitmap: bitmap, length: self.length - start, offset: self.offset + start }
        }
        Some(length) => {
            let length = @math.minimum(length, self.length - start)
            let bitmap = self.bitmap.split_at(start).1.split_at(length).0
            BitMap::{ optional: self.optional, bitmap: bitmap, length: length, offset: self.offset + start }
        }
    }
}