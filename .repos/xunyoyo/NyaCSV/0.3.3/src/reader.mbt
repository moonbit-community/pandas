///|
/// Represents configuration options for CSV parsing operations.
///
/// Parameters:
///
/// * `delimiter` : Character used to separate fields in the CSV data (typically
/// a comma ',').
/// * `allow_newlines_in_quotes` : Boolean flag indicating whether newline
/// characters are allowed within quoted fields.
/// * `quote_char` : Character used for quoting fields that contain special
/// characters (typically a double quote '"').
/// * `skip_empty_lines` : Boolean flag indicating whether empty lines in the
/// input should be ignored.
/// * `trim_spaces` : Boolean flag indicating whether leading and trailing
/// whitespace should be removed from fields.
///
pub(all) struct CSVOptions {
  delimiter : Char
  allow_newlines_in_quotes : Bool
  quote_char : Char
  skip_empty_lines : Bool
  trim_spaces : Bool
}

///|
priv trait CSVReader {
  read_char(Self) -> Char?
  peek_char(Self) -> Char?
  is_eof(Self) -> Bool
}

///|
priv struct StringReader {
  source : String
  mut pos : Int
}

///|
impl CSVReader for StringReader with read_char(self) -> Char? {
  if self.pos < self.source.length() {
    let ch = self.source.code_unit_at(self.pos).unsafe_to_char()
    self.pos += 1
    Some(ch)
  } else {
    None
  }
}

///|
test "StringReader::read_char/normal_case" {
  let reader : StringReader = { source: "Hello, World!", pos: 0 }
  inspect!(reader.read_char(), content="Some('H')")
  inspect!(reader.read_char(), content="Some('e')")
  inspect!(reader.read_char(), content="Some('l')")
}

///|
test "StringReader::read_char/empty_string" {
  let reader : StringReader = { source: "", pos: 0 }
  inspect!(reader.read_char(), content="None")
}

///|
test "StringReader::read_char/past_end_of_string" {
  let reader : StringReader = { source: "Hello", pos: 5 } // 'pos' is set to the length of the string
  inspect!(reader.read_char(), content="None")
}

///|
impl CSVReader for StringReader with peek_char(self) -> Char? {
  if self.pos < self.source.length() {
    Some(self.source.code_unit_at(self.pos).unsafe_to_char())
  } else {
    None
  }
}

///|
test "StringReader::peek_char/normal_case" {
  let reader : StringReader = { source: "Hello, World!", pos: 0 }
  inspect!(reader.peek_char(), content="Some('H')")
  reader.pos = 7
  inspect!(reader.peek_char(), content="Some('W')")
}

///|
test "StringReader::peek_char/empty_string" {
  let reader : StringReader = { source: "", pos: 0 }
  inspect!(reader.peek_char(), content="None")
}

///|
test "StringReader::peek_char/at_end_of_string" {
  let reader : StringReader = { source: "Hello", pos: 5 } // 'pos' is set to the length of the string
  inspect!(reader.peek_char(), content="None")
}

///|
impl CSVReader for StringReader with is_eof(self) -> Bool {
  self.pos >= self.source.length()
}
