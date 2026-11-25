// Edge cases of `read_csv_str`: the words next to the
// inference words, integers beyond Int64, the scanner after a closing quote,
// separators and quote characters outside the BMP, and the order of errors.
// Expectations come from polars 2.1.0 where polars can do the case (it takes
// one-byte separators and quotes only), else from the rules in the docs.

///|
test "csv read: near misses of true, false, inf and NaN are strings" {
  for
    w in ["f", "fa", "fal", "xrue", "xalse", "ixx", "ixf", "inx", "Nxx", "Nax"] {
    assert_eq(csv_run("a\n\{w}\n"), "a:str=['\{w}']")
    // and no error either when the word comes after the inference window
    assert_eq(
      csv_run(
        "a\n\{w}\nx\n",
        options=@pl.CsvReadOptions::new(infer_schema_length=Some(1)),
      ),
      "a:str=['\{w}','x']",
    )
  }
}

///|
test "csv read: big integer, no float-shaped value: String (polars Int128)" {
  let big = "9223372036854775808"
  assert_eq(csv_run("a\n\{big}\n"), "a:str=['\{big}']")
  assert_eq(csv_run("a\n1\n\{big}\n"), "a:str=['1','\{big}']")
  assert_eq(csv_run("a\n\{big}\n1\n"), "a:str=['\{big}','1']")
  assert_eq(csv_run("a\n\{big}\n\n"), "a:str=['\{big}',null]")
  assert_eq(csv_run("a\n\n\{big}\n"), "a:str=[null,'\{big}']")
  assert_eq(csv_run("a\n1\n\n\{big}\n"), "a:str=['1',null,'\{big}']")
  assert_eq(csv_run("a\n\"\{big}\"\n"), "a:str=['\{big}']")
  assert_eq(csv_run("a\n\{big}\n\{big}\n"), "a:str=['\{big}','\{big}']")
}

///|
test "csv read: big integer and a float-shaped value, no small integer: Float64" {
  let big = "9223372036854775808"
  let f = "9223372036854776000.0"
  // as in polars; `inf`, `NaN` and `1e3` are float-shaped too
  assert_eq(csv_run("a\n\{big}\n1.5\n"), "a:f64=[\{f},1.5]")
  assert_eq(csv_run("a\n1.5\n\{big}\n"), "a:f64=[1.5,\{f}]")
  assert_eq(csv_run("a\n\{big}\ninf\n"), "a:f64=[\{f},inf]")
  assert_eq(csv_run("a\n\{big}\nNaN\n"), "a:f64=[\{f},NaN]")
  assert_eq(csv_run("a\n\{big}\n1e3\n"), "a:f64=[\{f},1000.0]")
  assert_eq(csv_run("a\n\n\{big}\n1.5\n"), "a:f64=[null,\{f},1.5]")
  assert_eq(csv_run("a\n\"\{big}\"\n1.5\n"), "a:f64=[\{f},1.5]")
  assert_eq(
    csv_run("a\n-9223372036854775809\n-2.5\n"),
    "a:f64=[-9223372036854776000.0,-2.5]",
  )
  assert_eq(
    csv_run("\{big}\n1.5\n", options=@pl.CsvReadOptions::new(has_header=false)),
    "column_0:f64=[\{f},1.5]",
  )
}

///|
test "csv read: small integer, big integer and a float-shaped value: String" {
  let big = "9223372036854775808"
  // any order, as in polars
  assert_eq(csv_run("a\n1\n\{big}\n1.5\n"), "a:str=['1','\{big}','1.5']")
  assert_eq(csv_run("a\n1.5\n1\n\{big}\n"), "a:str=['1.5','1','\{big}']")
  assert_eq(csv_run("a\n\{big}\n1.5\n-7\n"), "a:str=['\{big}','1.5','-7']")
  assert_eq(csv_run("a\n1\n\{big}\ninf\n"), "a:str=['1','\{big}','inf']")
  assert_eq(csv_run("a\n1\n\{big}\n1e3\n"), "a:str=['1','\{big}','1e3']")
}

///|
test "csv read: a big integer next to a bool or a word is a String" {
  let big = "9223372036854775808"
  assert_eq(csv_run("a\n\{big}\ntrue\n"), "a:str=['\{big}','true']")
  assert_eq(csv_run("a\n\{big}\nx\n"), "a:str=['\{big}','x']")
  assert_eq(csv_run("a\n1.5\n\{big}\nx\n"), "a:str=['1.5','\{big}','x']")
}

///|
test "csv read: a big integer, other text shapes and columns" {
  let big = "9223372036854775808"
  assert_eq(
    csv_run("a\n-9223372036854775809\n1\n"),
    "a:str=['-9223372036854775809','1']",
  )
  assert_eq(csv_run("a\n\{big}\n\{big}\n"), "a:str=['\{big}','\{big}']")
  // 25 digits stay exact
  assert_eq(
    csv_run("a\n1111111111111111111111111\n"),
    "a:str=['1111111111111111111111111']",
  )
  // leading zeros do not count: the value decides
  assert_eq(
    csv_run("a\n0009223372036854775807\n"),
    "a:i64=[9223372036854775807]",
  )
  assert_eq(
    csv_run("a\n-0009223372036854775808\n"),
    "a:i64=[-9223372036854775808]",
  )
  assert_eq(csv_run("a\n00000000000000000001\n"), "a:i64=[1]")
  assert_eq(
    csv_run("a\n0009223372036854775808\n"),
    "a:str=['0009223372036854775808']",
  )
  // a text with a sign or a space is not an integer text: a String anyway
  assert_eq(csv_run("a\n+\{big}\n"), "a:str=['+\{big}']")
  assert_eq(csv_run("a\n\{big} \n"), "a:str=['\{big} ']")
  // columns are independent
  assert_eq(
    csv_run("a,b\n\{big},1.5\n1,2\n"),
    "a:str=['\{big}','1'] b:f64=[1.5,2.0]",
  )
  // a null text is not a value
  assert_eq(
    csv_run(
      "a\n\{big}\n1\n",
      options=@pl.CsvReadOptions::new(null_values=[big]),
    ),
    "a:i64=[null,1]",
  )
  assert_eq(
    csv_run(
      "a\nNA\n\{big}\n",
      options=@pl.CsvReadOptions::new(null_values=["NA"]),
    ),
    "a:str=[null,'\{big}']",
  )
  // the other options
  assert_eq(
    csv_run("a\n\{big}\n", options=@pl.CsvReadOptions::new(n_rows=0)),
    "a:str=[]",
  )
  assert_eq(
    csv_run(
      "a\n\{big}\n",
      options=@pl.CsvReadOptions::new(try_parse_dates=true),
    ),
    "a:str=['\{big}']",
  )
}

///|
test "csv read: an integer beyond Int64 outside the window" {
  let big = "9223372036854775808"
  let w1 = @pl.CsvReadOptions::new(infer_schema_length=Some(1))
  let w2 = @pl.CsvReadOptions::new(infer_schema_length=Some(2))
  // an Int64 column: a ParseError, as in polars
  assert_eq(
    csv_run("a\n1\n\{big}\n", options=w1),
    "ParseError: could not parse `\{big}` as dtype `i64` at column 'a' (column number 1) at line 3",
  )
  assert_eq(
    csv_run("a\n1\n2\n\{big}\n", options=w2),
    "ParseError: could not parse `\{big}` as dtype `i64` at column 'a' (column number 1) at line 4",
  )
  // a Float64 column reads it as a float
  assert_eq(
    csv_run("a\n1.5\n\{big}\n", options=w1),
    "a:f64=[1.5,9223372036854776000.0]",
  )
  assert_eq(
    csv_run("a\n1.5\n2.5\n\{big}\n", options=w2),
    "a:f64=[1.5,2.5,9223372036854776000.0]",
  )
  // a String column keeps the text
  assert_eq(
    csv_run("a\nx\ny\n\{big}\n", options=w2),
    "a:str=['x','y','\{big}']",
  )
  // the window of 1 sees the big one only: Int128 in polars, a String here, and
  // the float after it is no error (polars raises there)
  assert_eq(csv_run("a\n\{big}\n1.5\n", options=w1), "a:str=['\{big}','1.5']")
  // no inference at all
  assert_eq(
    csv_run(
      "a\n\{big}\n",
      options=@pl.CsvReadOptions::new(infer_schema_length=Some(0)),
    ),
    "a:str=['\{big}']",
  )
}

///|
test "csv read: an override reads an integer beyond Int64" {
  let big = "9223372036854775808"
  assert_eq(
    csv_run("a\n\{big}\n1\n", options=csv_ov("a", @pl.DataType::Float64)),
    "a:f64=[9223372036854776000.0,1.0]",
  )
  assert_eq(
    csv_run(
      "a\n-9223372036854775809\n",
      options=csv_ov("a", @pl.DataType::Float64),
    ),
    "a:f64=[-9223372036854776000.0]",
  )
  assert_eq(
    csv_run("a\n\{big}\n", options=csv_ov("a", @pl.DataType::Float32)),
    "a:f32=[9223372000000000000.0]",
  )
  assert_eq(
    csv_run("a\n\{big}\n1\n", options=csv_ov("a", @pl.DataType::String)),
    "a:str=['\{big}','1']",
  )
  assert_eq(
    csv_run("a\n\{big}\n1\n", options=csv_ov("a", @pl.DataType::Int64)),
    "ParseError: could not parse `\{big}` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n\{big}\n", options=csv_ov("a", @pl.DataType::Int32)),
    "ParseError: could not parse `\{big}` as dtype `i32` at column 'a' (column number 1) at line 2",
  )
}

///|
test "csv read: text after a closing quote names the column and the number" {
  let m = "could not parse `\"y\"z` as dtype `str`"
  assert_eq(
    csv_run("a,b\n\"x\",\"y\"z\n"),
    "ParseError: \{m} at column 'b' (column number 2) at line 2",
  )
  assert_eq(
    csv_run("a,b,c\n1,2,\"y\"z\n"),
    "ParseError: \{m} at column 'c' (column number 3) at line 2",
  )
  assert_eq(
    csv_run("a,b,c\n\"x\",\"y\"z,3\n"),
    "ParseError: \{m} at column 'b' (column number 2) at line 2",
  )
  assert_eq(
    csv_run("a,b,c\n\"x\",\"y\",\"z\"w\n"),
    "ParseError: could not parse `\"z\"w` as dtype `str` at column 'c' (column number 3) at line 2",
  )
  assert_eq(
    csv_run("a,b,c\n\"x\",\"y\",\"z\"w,4\n"),
    "ParseError: could not parse `\"z\"w` as dtype `str` at column 'c' (column number 3) at line 2",
  )
}

///|
test "csv read: a bad record that skip_rows skips is not an error" {
  let skip1 = @pl.CsvReadOptions::new(skip_rows=1)
  assert_eq(csv_run("\"x\"y\na\n1\n", options=skip1), "a:i64=[1]")
  assert_eq(
    csv_run(
      "\"x\"y\na\n1\n",
      options=@pl.CsvReadOptions::new(
        skip_rows=1,
        schema_overrides=Map::from_array([("a", @pl.DataType::Int64)]),
      ),
    ),
    "a:i64=[1]",
  )
  // a skipped record with a break inside the quotes after the closing quote
  assert_eq(
    csv_run("\"x\"y\"p\nq\"z\na\n1\nx\n", options=skip1),
    "a:str=['1','x']",
  )
}

///|
test "csv read: line numbers after a skipped or scanned junk record" {
  let skip1 = @pl.CsvReadOptions::new(skip_rows=1)
  // the junk record `"x"y"p<LF>q"z,2` is lines 1 and 2, the header line 3
  assert_eq(
    csv_run(
      "\"x\"y\"p\nq\"z,2\na,b\n1,x\n",
      options=@pl.CsvReadOptions::new(
        skip_rows=1,
        schema_overrides=Map::from_array([("b", @pl.DataType::Int64)]),
      ),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'b' (column number 2) at line 4",
  )
  assert_eq(
    csv_run("\"x\"y\"p\nq\"z,2\na,b\n1,2\n3,4,5\n", options=skip1),
    "ParseError: found more fields than defined in 'Schema' at line 5",
  )
  assert_eq(
    csv_run(
      "\"x\"y\"p\nq\"z\na\n1\nx\n",
      options=@pl.CsvReadOptions::new(
        skip_rows=1,
        schema_overrides=Map::from_array([("a", @pl.DataType::Int64)]),
      ),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 5",
  )
  // the line break is in the first quoted part, before the closing quote
  assert_eq(
    csv_run(
      "\"p\nq\"z\na\n1\nx\n",
      options=@pl.CsvReadOptions::new(
        skip_rows=1,
        schema_overrides=Map::from_array([("a", @pl.DataType::Int64)]),
      ),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 5",
  )
  assert_eq(
    csv_run(
      "\"p\nq\"z\"r\ns\"t,2\na\n1\nx\n",
      options=@pl.CsvReadOptions::new(
        skip_rows=1,
        schema_overrides=Map::from_array([("a", @pl.DataType::Int64)]),
      ),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 6",
  )
  // two skipped junk records
  assert_eq(
    csv_run(
      "\"x\"y\"p\nq\"z,2\n\"a\"b\"c\nd\"e\nh\n1\nx\n",
      options=@pl.CsvReadOptions::new(
        skip_rows=2,
        schema_overrides=Map::from_array([("h", @pl.DataType::Int64)]),
      ),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'h' (column number 1) at line 7",
  )
  // a junk record after a record with a line break in quotes: its own line
  // (polars reads this text without an error; the library raises, see the
  // known differences; the message stops at the line break, as polars' does)
  assert_eq(
    csv_run("a,b\n\"p\nq\",1\n3,\"x\"y\"z\nw\"\n"),
    "ParseError: could not parse `\"x\"y\"z at line 4",
  )
}

///|
test "csv read: n_rows=0 keeps the types after a junk record with a break" {
  let n0 = @pl.CsvReadOptions::new(n_rows=0)
  assert_eq(
    csv_run("a,b\n\"x\"y\"p\nq\"z,2\n3,4\n", options=n0),
    "a:str=[] b:i64=[]",
  )
  assert_eq(
    csv_run("a,b\n1,\"x\"y\"p\nq\"z\n3,4\n", options=n0),
    "a:i64=[] b:str=[]",
  )
  assert_eq(
    csv_run("a,b\n\"x\"y\"p\nq\"z,2\n\"x\"y\"p\nq\"z,3\n4,5\n", options=n0),
    "a:str=[] b:i64=[]",
  )
  // the record after the junk ones is in the window: 2.5 then x
  assert_eq(
    csv_run("a,b\n\"x\"y\"p\nq\"z,2.5\n\"x\"y\"p\nq\"z,3\n4,x\n", options=n0),
    "a:str=[] b:str=[]",
  )
  // outside the window
  assert_eq(
    csv_run(
      "a,b\n\"x\"y\"p\nq\"z,2\n3,4,5\n",
      options=@pl.CsvReadOptions::new(n_rows=0, infer_schema_length=Some(1)),
    ),
    "a:str=[] b:i64=[]",
  )
  assert_eq(
    csv_run(
      "a\n1\n\"x\"y\"p\nq\"z\n4\n",
      options=@pl.CsvReadOptions::new(n_rows=0, infer_schema_length=Some(1)),
    ),
    "a:i64=[]",
  )
}

///|
test "csv read: a bare CR after a closing quote is text, also at the very end" {
  assert_eq(
    csv_run("a\n\"x\"\rZ"),
    "ParseError: could not parse `\"x\"\rZ` as dtype `str` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a,b\n1,\"x\"\rZ"),
    "ParseError: could not parse `\"x\"\rZ` as dtype `str` at column 'b' (column number 2) at line 2",
  )
  assert_eq(
    csv_run("a\n\"x\"\rZ\n"),
    "ParseError: could not parse `\"x\"\rZ` as dtype `str` at column 'a' (column number 1) at line 2",
  )
  // a CR that ends the text is dropped
  assert_eq(csv_run("a\n\"x\"\r"), "a:str=['x']")
}

///|
test "csv read: no header, no inference, a wider second record" {
  let o = @pl.CsvReadOptions::new(has_header=false, infer_schema_length=Some(0))
  assert_eq(
    csv_run("1\n2,3\n", options=o),
    "ParseError: found more fields than defined in 'Schema' at line 2",
  )
  assert_eq(
    csv_run("1,2\n3,4,5\n", options=o),
    "ParseError: found more fields than defined in 'Schema' at line 2",
  )
  // a window of 1 is the same
  assert_eq(
    csv_run(
      "1\n2,3\n",
      options=@pl.CsvReadOptions::new(
        has_header=false,
        infer_schema_length=Some(1),
      ),
    ),
    "ParseError: found more fields than defined in 'Schema' at line 2",
  )
  // a window of 2 sees the wider record
  assert_eq(
    csv_run(
      "1\n2,3\n",
      options=@pl.CsvReadOptions::new(
        has_header=false,
        infer_schema_length=Some(2),
      ),
    ),
    "column_0:i64=[1,2] column_1:i64=[null,3]",
  )
}

///|
test "csv read: a value error or a malformed record, whichever is first" {
  let f32o = csv_ov("1", @pl.DataType::Float32)
  // the value of the first column comes before "more fields" of the same record
  assert_eq(
    csv_run("1\n1true\"aNA\tinf,\t\n\t", options=f32o),
    "ParseError: could not parse `1true\"aNA\tinf` as dtype `f32` at column '1' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("1\n1true\"aNA\tinf,\t\n", options=f32o),
    "ParseError: could not parse `1true\"aNA\tinf` as dtype `f32` at column '1' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("1\n1true\"aNA\tinf,\t\n\t"),
    "ParseError: found more fields than defined in 'Schema' at line 2",
  )
  assert_eq(
    csv_run("a,b\nx,2,3\n", options=csv_ov("a", @pl.DataType::Int64)),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
}

///|
test "csv read: a Null override is a ComputeError before any bad record" {
  let msg = "ComputeError: unsupported data type when reading CSV: null when reading CSV"
  // the Null column comes after the bad field
  assert_eq(
    csv_run("a,b\n\"1\"x,2\n", options=csv_ov("b", @pl.DataType::Null)),
    msg,
  )
  // and before it
  assert_eq(
    csv_run("a,b\n1,\"2\"x\n", options=csv_ov("a", @pl.DataType::Null)),
    msg,
  )
  assert_eq(
    csv_run(
      "a,b\n\"1\"x,2\n",
      options=@pl.CsvReadOptions::new(
        infer_schema_length=Some(0),
        schema_overrides=Map::from_array([("b", @pl.DataType::Null)]),
      ),
    ),
    msg,
  )
}

///|
test "csv read: separators and quotes of one or two UTF-16 units" {
  // U+FFFF is the last BMP char; the others have two units, with the low half
  // at its smallest (U+10000), 0x3FF (U+103FF) and its largest (U+10FFFF)
  let chars : Array[Char] = ['\u{FFFF}', '\u{10000}', '\u{103FF}', '\u{10FFFF}']
  for s in chars {
    let o = @pl.CsvReadOptions::new(separator=s)
    assert_eq(csv_run("a\{s}b\n1\{s}2\n", options=o), "a:i64=[1] b:i64=[2]")
    // the separator is the last character of the text
    assert_eq(csv_run("a\{s}b\n1\{s}", options=o), "a:i64=[1] b:str=[null]")
    assert_eq(csv_run("a\{s}b\n\{s}", options=o), "a:str=[null] b:str=[null]")
    assert_eq(csv_run("a\{s}", options=o), "a:str=[] :str=[]")
    // quoted, with the separator inside
    assert_eq(
      csv_run("a\{s}b\n\"x\{s}y\"\{s}2\n", options=o),
      "a:str=['x\{s}y'] b:i64=[2]",
    )
    // too many fields
    assert_eq(
      csv_run("a\{s}b\n1\{s}2\{s}3\n", options=o),
      "ParseError: found more fields than defined in 'Schema' at line 2",
    )
    let q = @pl.CsvReadOptions::new(quote_char=Some(s))
    assert_eq(
      csv_run("a,b\n\{s}x,y\{s},2\n", options=q),
      "a:str=['x,y'] b:i64=[2]",
    )
    // a doubled quote is one
    assert_eq(csv_run("a\n\{s}p\{s}\{s}q\{s}\n", options=q), "a:str=['p\{s}q']")
    // text after the closing quote
    assert_eq(
      csv_run("a\n\{s}x\{s}y\n", options=q),
      "ParseError: could not parse `\{s}x\{s}y` as dtype `str` at column 'a' (column number 1) at line 2",
    )
    // an open quote (the message stops at the line break, as polars' does)
    assert_eq(
      csv_run("a\n\{s}x\n", options=q),
      "ParseError: could not parse `\{s}x at line 2",
    )
    assert_eq(
      csv_run("a\n\{s}x", options=q),
      "ParseError: could not parse `\{s}x` as dtype `str` at column 'a' (column number 1) at line 2",
    )
    // a quote at the very end of the text
    assert_eq(csv_run("a\n\{s}x\{s}", options=q), "a:str=['x']")
    assert_eq(csv_run("a\n\{s}\{s}", options=q), "a:str=['']")
  }
}

///|
test "csv read: a digit as the separator" {
  // `5123` is `5` and `23`: the digits of the separator are not part of a value
  let one = @pl.CsvReadOptions::new(separator='1')
  assert_eq(csv_run("a1b\n5123", options=one), "a:i64=[5] b:i64=[23]")
  assert_eq(csv_run("a1b\n5123\n", options=one), "a:i64=[5] b:i64=[23]")
  assert_eq(
    csv_run("a5b\n1525\n", options=@pl.CsvReadOptions::new(separator='5')),
    "ParseError: found more fields than defined in 'Schema' at line 2",
  )
}

///|
test "csv read: a letter or a digit as the quote character" {
  fn q(c : Char) -> @pl.CsvReadOptions {
    @pl.CsvReadOptions::new(quote_char=Some(c))
  }

  // the quote characters are not part of the value that is inferred
  assert_eq(csv_run("a\nx1x\n", options=q('x')), "a:i64=[1]")
  assert_eq(csv_run("a\nxtruex\n", options=q('x')), "a:bool=[true]")
  assert_eq(csv_run("a\n515\n", options=q('5')), "a:i64=[1]")
  assert_eq(csv_run("a\n5x5\n", options=q('5')), "a:str=['x']")
  assert_eq(csv_run("a\nN1.5N\n", options=q('N')), "a:f64=[1.5]")
  assert_eq(csv_run("a\n1.51\n", options=q('1')), "a:f64=[0.5]")
  assert_eq(csv_run("a\n11\n", options=q('1')), "a:str=['']")
  assert_eq(csv_run("a\ne1.5e\n", options=q('e')), "a:f64=[1.5]")
  // an escaped quote at the start of the value: `x1`, `xtrue` are strings
  assert_eq(csv_run("a\nxxx1x\n", options=q('x')), "a:str=['x1']")
  assert_eq(csv_run("a\nxxxtruex\n", options=q('x')), "a:str=['xtrue']")
  assert_eq(csv_run("a\n-5-\n", options=q('-')), "a:i64=[5]")
  // a quote character that is not at the start of the field is an ordinary
  // character (the library; polars raises "CSV malformed" for an odd count)
  assert_eq(csv_run("a\n1e5\n", options=q('e')), "a:f64=[100000.0]")
}

///|
test "csv read: CsvReadOptions is Eq and Debug" {
  let d = @pl.CsvReadOptions::new()
  assert_true(d == @pl.CsvReadOptions::new())
  assert_true(d != @pl.CsvReadOptions::new(separator=';'))
  assert_true(d != @pl.CsvReadOptions::new(has_header=false))
  assert_true(d != @pl.CsvReadOptions::new(quote_char=None))
  assert_true(d != @pl.CsvReadOptions::new(null_values=["NA"]))
  assert_true(d != csv_ov("a", @pl.DataType::Int64))
  assert_true(d != @pl.CsvReadOptions::new(infer_schema_length=None))
  assert_true(d != @pl.CsvReadOptions::new(n_rows=0))
  assert_true(d != @pl.CsvReadOptions::new(skip_rows=1))
  assert_true(d != @pl.CsvReadOptions::new(try_parse_dates=true))
  assert_true(
    csv_ov("a", @pl.DataType::Int64) == csv_ov("a", @pl.DataType::Int64),
  )
  assert_true(
    csv_ov("a", @pl.DataType::Int64) != csv_ov("a", @pl.DataType::Float64),
  )
  @debug.debug_inspect(
    d,
    content=(
      #|{
      #|  separator: ',',
      #|  has_header: true,
      #|  quote_char: Some('"'),
      #|  null_values: [],
      #|  schema_overrides: {},
      #|  infer_schema_length: Some(100),
      #|  n_rows: None,
      #|  skip_rows: 0,
      #|  try_parse_dates: false,
      #|}
    ),
  )
  @debug.debug_inspect(
    @pl.CsvReadOptions::new(
      separator=';',
      has_header=false,
      quote_char=None,
      null_values=["NA", ""],
      schema_overrides=Map::from_array([("a", @pl.DataType::Int64)]),
      infer_schema_length=None,
      n_rows=5,
      skip_rows=2,
      try_parse_dates=true,
    ),
    content=(
      #|{
      #|  separator: ';',
      #|  has_header: false,
      #|  quote_char: None,
      #|  null_values: ["NA", ""],
      #|  schema_overrides: { "a": Int64 },
      #|  infer_schema_length: None,
      #|  n_rows: Some(5),
      #|  skip_rows: 2,
      #|  try_parse_dates: true,
      #|}
    ),
  )
}
