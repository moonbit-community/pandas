///|
/// polars' look of a float: `inf`, `1.0` (a point after a whole number).
fn csv_num(s : String) -> String {
  match s {
    "Infinity" => "inf"
    "-Infinity" => "-inf"
    _ =>
      if s.contains(".") || s.contains("e") || s.contains("N") {
        s
      } else {
        s + ".0"
      }
  }
}

///|
/// Compact text of a frame: `name:dtype=[v,...]` per column, `null` for a null
/// and `'text'` for a string.
fn csv_show(df : @pl.DataFrame) -> String {
  let parts : Array[String] = []
  for s in df.get_columns() {
    let vals : Array[String] = []
    for v in s.to_list() {
      vals.push(
        match v {
          Null => "null"
          Boolean(b) => "\{b}"
          Int32(x) => "\{x}"
          Int64(x) => "\{x}"
          Float32(x) => csv_num("\{x}")
          Float64(x) =>
            if x == 0.0 && 1.0 / x < 0.0 {
              "-0.0"
            } else {
              csv_num("\{x}")
            }
          String(t) => "'\{t}'"
          Date(d) => "d\{d}"
          Datetime(t) => "t\{t}"
        },
      )
    }
    parts.push("\{s.name()}:\{s.dtype()}=[\{vals.join(",")}]")
  }
  parts.join(" ")
}

///|
/// Reads `text` and shows the frame, or the error as `<Variant>: <message>`.
fn csv_run(
  text : String,
  options~ : @pl.CsvReadOptions = @pl.CsvReadOptions::new(),
) -> String {
  let r : Result[@pl.DataFrame, @pl.PolarsError] = Ok(
    @pl.read_csv_str(text, options~),
  ) catch {
    e => Err(e)
  }
  match r {
    Ok(df) => csv_show(df)
    Err(e) => "\{e}"
  }
}

///|
test "csv read: plain tables and inference" {
  assert_eq(csv_run("a,b\n1,2\n3,4\n"), "a:i64=[1,3] b:i64=[2,4]")
  assert_eq(csv_run("a,b\n1,x\n2,y"), "a:i64=[1,2] b:str=['x','y']")
  assert_eq(csv_run("a\n1\n2.5\n"), "a:f64=[1.0,2.5]")
  assert_eq(csv_run("a\ntrue\nFALSE\ntRuE\n"), "a:bool=[true,false,true]")
  assert_eq(csv_run("a\n1\ntrue\n"), "a:str=['1','true']")
  assert_eq(csv_run("a\n007\n-007\n-0\n"), "a:i64=[7,-7,0]")
  assert_eq(csv_run("a\n1\nx\n"), "a:str=['1','x']")
  assert_eq(csv_run("a\n1\n1.5\nx\n"), "a:str=['1','1.5','x']")
  // quotes are ignored for inference
  assert_eq(
    csv_run("a,b,c\n\"1\",\"1.5\",\"true\"\n"),
    "a:i64=[1] b:f64=[1.5] c:bool=[true]",
  )
  // no trimming
  assert_eq(csv_run("a\n 1\n"), "a:str=[' 1']")
  assert_eq(csv_run("a\ntrue \n"), "a:str=['true ']")
  assert_eq(csv_run("a\n1 \n"), "a:str=['1 ']")
  // the empty header-only table has String columns
  assert_eq(csv_run("a,b\n"), "a:str=[] b:str=[]")
  assert_eq(csv_run("a,b"), "a:str=[] b:str=[]")
  // unicode
  assert_eq(csv_run("né,日本\n1,😀\n"), "né:i64=[1] 日本:str=['😀']")
}

///|
test "csv read: float and integer inference edge cases" {
  // strict predicate: no `+5`, `Inf`, `nan`, `-nan`
  assert_eq(csv_run("a\n+5\n"), "a:str=['+5']")
  assert_eq(csv_run("a\n+5\n1\n"), "a:str=['+5','1']")
  assert_eq(csv_run("a\n+1.5\n"), "a:f64=[1.5]")
  assert_eq(csv_run("a\n+.5\n-.5\n"), "a:f64=[0.5,-0.5]")
  assert_eq(csv_run("a\n5.\n+5.\n"), "a:f64=[5.0,5.0]")
  assert_eq(
    csv_run("a\n1e3\n1E-3\n1e+3\n+1e3\n"),
    "a:f64=[1000.0,0.001,1000.0,1000.0]",
  )
  assert_eq(csv_run("a\n.5e1\n00.5\n"), "a:f64=[5.0,0.5]")
  assert_eq(csv_run("a\ninf\n-inf\n+inf\nNaN\n"), "a:f64=[inf,-inf,inf,NaN]")
  assert_eq(csv_run("a\n+NaN\n-NaN\n"), "a:f64=[NaN,NaN]")
  assert_eq(csv_run("a\nInf\n"), "a:str=['Inf']")
  assert_eq(csv_run("a\nINF\n"), "a:str=['INF']")
  assert_eq(csv_run("a\ninfinity\n"), "a:str=['infinity']")
  assert_eq(csv_run("a\nnan\n"), "a:str=['nan']")
  assert_eq(csv_run("a\nNAN\n"), "a:str=['NAN']")
  assert_eq(csv_run("a\n-nan\n"), "a:str=['-nan']")
  assert_eq(csv_run("a\n1\nnan\n"), "a:str=['1','nan']")
  assert_eq(csv_run("a\n1\nNaN\n"), "a:f64=[1.0,NaN]")
  assert_eq(csv_run("a\n1e\n"), "a:str=['1e']")
  assert_eq(csv_run("a\n1e+\n"), "a:str=['1e+']")
  assert_eq(csv_run("a\ne3\n"), "a:str=['e3']")
  assert_eq(csv_run("a\n1e3.5\n"), "a:str=['1e3.5']")
  assert_eq(csv_run("a\n1.5.5\n"), "a:str=['1.5.5']")
  assert_eq(csv_run("a\n1_000\n"), "a:str=['1_000']")
  assert_eq(csv_run("a\n0x10\n"), "a:str=['0x10']")
  assert_eq(csv_run("a\n1.e5\n"), "a:str=['1.e5']")
  assert_eq(csv_run("a\n.e5\n"), "a:str=['.e5']")
  assert_eq(csv_run("a\n-\n"), "a:str=['-']")
  assert_eq(csv_run("a\n.\n"), "a:str=['.']")
  assert_eq(csv_run("a\n1e400\n1.5\n"), "a:f64=[inf,1.5]")
  assert_eq(csv_run("a\n-0.0\n"), "a:f64=[-0.0]")
  // int and float mix
  assert_eq(csv_run("a\n1\n2.5\n3\n"), "a:f64=[1.0,2.5,3.0]")
  // bound of Int64, and beyond it (a String: polars has Int128, this library
  // has not)
  assert_eq(
    csv_run("a\n9223372036854775807\n-9223372036854775808\n"),
    "a:i64=[9223372036854775807,-9223372036854775808]",
  )
  assert_eq(
    csv_run("a\n9223372036854775808\n"),
    "a:str=['9223372036854775808']",
  )
  assert_eq(
    csv_run("a\n1\n-9223372036854775809\n"),
    "a:str=['1','-9223372036854775809']",
  )
}

///|
test "csv read: nulls and empty strings" {
  assert_eq(csv_run("a,b\n1,\n,2\n"), "a:i64=[1,null] b:i64=[null,2]")
  // an all-empty column is String
  assert_eq(csv_run("a,b\n1,\n2,\n"), "a:i64=[1,2] b:str=[null,null]")
  // a quoted empty string is the empty string, and forces String
  assert_eq(csv_run("a,b\n1,\"\"\n2,\"\"\n"), "a:i64=[1,2] b:str=['','']")
  assert_eq(csv_run("a\n1\n\n\"\"\n5\n"), "a:str=['1',null,'','5']")
  // by default only the empty field is null
  assert_eq(csv_run("a\nNA\nnull\nNone\n-\n"), "a:str=['NA','null','None','-']")
  // a null does not decide the type
  assert_eq(csv_run("a\ntrue\n\nfalse\n"), "a:bool=[true,null,false]")
}

///|
test "csv read: null_values" {
  let nv = @pl.CsvReadOptions::new(null_values=["NA"])
  assert_eq(
    csv_run("a,b\n1,NA\n2,x\nNA,y\n", options=nv),
    "a:i64=[1,2,null] b:str=[null,'x','y']",
  )
  // quoted fields count, and they do not make the column String
  assert_eq(
    csv_run("a,b\n1,\"NA\"\n2,3\n", options=nv),
    "a:i64=[1,2] b:i64=[null,3]",
  )
  // not applied to the header
  assert_eq(csv_run("NA,b\n1,2\n", options=nv), "NA:i64=[1] b:i64=[2]")
  // exact match: no trimming, case-sensitive
  assert_eq(csv_run("a\n 1\nNA \nna\n", options=nv), "a:str=[' 1','NA ','na']")
  // an all-null column is String
  assert_eq(csv_run("a\nNA\nNA\n", options=nv), "a:str=[null,null]")
  // several values
  let nv2 = @pl.CsvReadOptions::new(null_values=["NA", "-"])
  assert_eq(csv_run("a\n1\n-\nNA\n", options=nv2), "a:i64=[1,null,null]")
  // quoted empty string is only null when "" is in the list
  assert_eq(csv_run("a\n1\n\"\"\n", options=nv), "a:str=['1','']")
  let nv3 = @pl.CsvReadOptions::new(null_values=[""])
  assert_eq(
    csv_run("a,b\n1,\n2,\"\"\n3,x\n", options=nv3),
    "a:i64=[1,2,3] b:str=[null,null,'x']",
  )
  // the text is compared as written between the quotes: a doubled quote stays doubled
  let nv4 = @pl.CsvReadOptions::new(null_values=["a\"\"b"])
  assert_eq(csv_run("a\n\"a\"\"b\"\nc\n", options=nv4), "a:str=[null,'c']")
  let nv4b = @pl.CsvReadOptions::new(null_values=["a\"b"])
  assert_eq(csv_run("a\n\"a\"\"b\"\nc\n", options=nv4b), "a:str=['a\"b','c']")
  // date columns
  let nv5 = @pl.CsvReadOptions::new(null_values=["NA"], try_parse_dates=true)
  assert_eq(csv_run("a\n2024-01-02\nNA\n", options=nv5), "a:date=[d19724,null]")
}

///|
test "csv read: quoting and records" {
  assert_eq(csv_run("a,b\n\"x,y\",2\n"), "a:str=['x,y'] b:i64=[2]")
  assert_eq(csv_run("a,b\n\"x\ny\",2\n"), "a:str=['x\ny'] b:i64=[2]")
  assert_eq(csv_run("a,b\n\"x\r\ny\",2\n"), "a:str=['x\r\ny'] b:i64=[2]")
  assert_eq(csv_run("a\n\"he said \"\"hi\"\"\"\n"), "a:str=['he said \"hi\"']")
  assert_eq(csv_run("a\n\"\"\"\"\n"), "a:str=['\"']")
  assert_eq(csv_run("a\n\"\n\"\n"), "a:str=['\n']")
  // a quote inside an unquoted field is literal
  assert_eq(csv_run("a,b\nab\"c\"d,2\n"), "a:str=['ab\"c\"d'] b:i64=[2]")
  assert_eq(csv_run("a,b\nab\"c,2\n"), "a:str=['ab\"c'] b:i64=[2]")
  assert_eq(csv_run("a,b\nab\"\",2\n"), "a:str=['ab\"\"'] b:i64=[2]")
  // a quote after a space is literal
  assert_eq(csv_run("a,b\n \"ab\",2\n"), "a:str=[' \"ab\"'] b:i64=[2]")
  // quote_char = None: quotes are ordinary
  let noq = @pl.CsvReadOptions::new(quote_char=None)
  assert_eq(csv_run("a,b\n\"x\",2\n", options=noq), "a:str=['\"x\"'] b:i64=[2]")
  assert_eq(
    csv_run("a,b\n\"x,y\",2\n", options=noq),
    "ParseError: found more fields than defined in 'Schema' at line 2",
  )
  // another quote character
  let sq = @pl.CsvReadOptions::new(quote_char=Some('\''))
  assert_eq(csv_run("a,b\n'x,y',2\n", options=sq), "a:str=['x,y'] b:i64=[2]")
  assert_eq(csv_run("a,b\n\"x\",2\n", options=sq), "a:str=['\"x\"'] b:i64=[2]")
  // CRLF, LF and a final line without a terminator
  assert_eq(csv_run("a,b\r\n1,2\r\n3,4\r\n"), "a:i64=[1,3] b:i64=[2,4]")
  assert_eq(csv_run("a,b\r\n1,2\n3,4"), "a:i64=[1,3] b:i64=[2,4]")
  assert_eq(csv_run("a\r\n1\r"), "a:i64=[1]")
  assert_eq(csv_run("a,b\n1,\"x\"\r\n2,3\r\n"), "a:i64=[1,2] b:str=['x','3']")
  // a bare CR is not a line break
  assert_eq(csv_run("a\n1\r2\n"), "a:str=['1\r2']")
  assert_eq(csv_run("a,b\r1,2\r"), "a:str=[] b\r1:str=[] 2:str=[]")
}

///|
test "csv read: blank lines, short and long rows" {
  // the final terminator is not a record, any other blank line is a null row
  assert_eq(csv_run("a,b\n1,2\n\n"), "a:i64=[1,null] b:i64=[2,null]")
  assert_eq(csv_run("a\n1\n\n3\n"), "a:i64=[1,null,3]")
  assert_eq(csv_run("a\r\n1\r\n\r\n3\r\n"), "a:i64=[1,null,3]")
  assert_eq(csv_run("a\r\n\r\n\r\n"), "a:str=[null,null]")
  assert_eq(csv_run("a,b\n  \n1,2\n"), "a:str=['  ','1'] b:i64=[null,2]")
  // blank lines before the header are skipped
  assert_eq(csv_run("\n\na,b\n1,2\n"), "a:i64=[1] b:i64=[2]")
  assert_eq(csv_run("\r\na\r\n1\r\n"), "a:i64=[1]")
  // short rows are padded with null
  assert_eq(
    csv_run("a,b,c\n1\n2,3\n"),
    "a:i64=[1,2] b:i64=[null,3] c:str=[null,null]",
  )
  assert_eq(csv_run("a,b,c\n\"x\"\n"), "a:str=['x'] b:str=[null] c:str=[null]")
  // long rows are errors
  assert_eq(
    csv_run("a,b\n1,2,3\n"),
    "ParseError: found more fields than defined in 'Schema' at line 2",
  )
  assert_eq(
    csv_run("a,b\n1,2\n3,4,5\n"),
    "ParseError: found more fields than defined in 'Schema' at line 3",
  )
  assert_eq(
    csv_run("a,b\n1,2,\n"),
    "ParseError: found more fields than defined in 'Schema' at line 2",
  )
  assert_eq(
    csv_run("a\n1,\"x\"y\n"),
    "ParseError: found more fields than defined in 'Schema' at line 2",
  )
}

///|
test "csv read: quote errors" {
  assert_eq(
    csv_run("a,b\n1,\"x\"y\n"),
    "ParseError: could not parse `\"x\"y` as dtype `str` at column 'b' (column number 2) at line 2",
  )
  assert_eq(
    csv_run("a,b\n\"x,y\"z,2\n"),
    "ParseError: could not parse `\"x,y\"z` as dtype `str` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a,b\n\"x\"  ,2\n"),
    "ParseError: could not parse `\"x\"  ` as dtype `str` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a,b\n1,\"x\" \n"),
    "ParseError: could not parse `\"x\" ` as dtype `str` at column 'b' (column number 2) at line 2",
  )
  assert_eq(
    csv_run("a,b\r\n1,\"x\"y\r\n"),
    "ParseError: could not parse `\"x\"y` as dtype `str` at column 'b' (column number 2) at line 2",
  )
  // unterminated quote to the end of the file (the message is the first line)
  assert_eq(
    csv_run("a,b\n1,\"abc"),
    "ParseError: could not parse `\"abc` as dtype `str` at column 'b' (column number 2) at line 2",
  )
  assert_eq(csv_run("a,b\n1,\"\n"), "ParseError: could not parse `\" at line 2")
  assert_eq(
    csv_run("a,b\n1,\"x\ny,z\nq"),
    "ParseError: could not parse `\"x at line 2",
  )
  // the row number is where the record starts
  assert_eq(
    csv_run("a,b\n1,2\n3,\"x\ny\n"),
    "ParseError: could not parse `\"x at line 3",
  )
  // header with a broken quote
  assert_eq(
    csv_run("a,\"b\n1,2\n"),
    "ParseError: could not parse `\"b at line 1",
  )
}

///|
test "csv read: headers" {
  assert_eq(csv_run("a,a\n1,2\n"), "a:i64=[1] a_duplicated_0:i64=[2]")
  assert_eq(
    csv_run("a,a,a,a\n1,2,3,4\n"),
    "a:i64=[1] a_duplicated_0:i64=[2] a_duplicated_1:i64=[3] a_duplicated_2:i64=[4]",
  )
  assert_eq(
    csv_run("a,b,a,b,a\n1,2,3,4,5\n"),
    "a:i64=[1] b:i64=[2] a_duplicated_0:i64=[3] b_duplicated_0:i64=[4] a_duplicated_1:i64=[5]",
  )
  assert_eq(csv_run("a,A\n1,2\n"), "a:i64=[1] A:i64=[2]")
  assert_eq(
    csv_run("a,a,a_duplicated_0\n1,2,3\n"),
    "DuplicateColumn: de-duplication of occurrence #2 of column name 'a' failed; the name 'a_duplicated_0' also exists in the file.",
  )
  assert_eq(
    csv_run("a_duplicated_0,a,a\n1,2,3\n"),
    "DuplicateColumn: de-duplication of occurrence #2 of column name 'a' failed; the name 'a_duplicated_0' also exists in the file.",
  )
  assert_eq(
    csv_run("a,a,a,a_duplicated_1\n1,2,3,4\n"),
    "DuplicateColumn: de-duplication of occurrence #3 of column name 'a' failed; the name 'a_duplicated_1' also exists in the file.",
  )
  // empty names are kept
  assert_eq(csv_run(",a\n1,2\n"), ":i64=[1] a:i64=[2]")
  assert_eq(
    csv_run(",,\n1,2,3\n"),
    ":i64=[1] _duplicated_0:i64=[2] _duplicated_1:i64=[3]",
  )
  assert_eq(csv_run("a,b,\n1,2,3\n"), "a:i64=[1] b:i64=[2] :i64=[3]")
  assert_eq(csv_run("a,b,\n1,2\n"), "a:i64=[1] b:i64=[2] :str=[null]")
  // spaces are part of the name
  assert_eq(csv_run(" a , b \n1,2\n"), " a :i64=[1]  b :i64=[2]")
  // quoted names; the header does not unescape `\"\"`
  assert_eq(csv_run("\"a b\",\"c,d\"\n1,2\n"), "a b:i64=[1] c,d:i64=[2]")
  assert_eq(csv_run("\"a\"\"b\"\n1\n"), "a\"\"b:i64=[1]")
  assert_eq(csv_run("a,\"b\nc\"\n1,2\n"), "a:i64=[1] b\nc:i64=[2]")
  assert_eq(csv_run("\"\"\n1\n"), ":i64=[1]")
  // BOM
  assert_eq(csv_run("\u{FEFF}a,b\n1,2\n"), "a:i64=[1] b:i64=[2]")
  assert_eq(csv_run("\u{FEFF}\"a\",b\n1,2\n"), "a:i64=[1] b:i64=[2]")
  assert_eq(csv_run("a\n1\n\u{FEFF}2\n"), "a:str=['1','\u{FEFF}2']")
  assert_eq(csv_run("\u{FEFF}\na,b\n1,2\n"), "a:i64=[1] b:i64=[2]")
}

///|
test "csv read: has_header = false" {
  let nh = @pl.CsvReadOptions::new(has_header=false)
  assert_eq(
    csv_run("1,2\n3,4\n", options=nh),
    "column_0:i64=[1,3] column_1:i64=[2,4]",
  )
  // the first line is data, blank lines are null rows
  assert_eq(
    csv_run("\n1,2\n3,4\n", options=nh),
    "column_0:i64=[null,1,3] column_1:i64=[null,2,4]",
  )
  assert_eq(csv_run("\n", options=nh), "column_0:str=[null]")
  assert_eq(
    csv_run("1,2\r\n\r\n3,4\r\n", options=nh),
    "column_0:i64=[1,null,3] column_1:i64=[2,null,4]",
  )
  // the width is the widest line of the inference window
  assert_eq(
    csv_run("1\n3,4\n", options=nh),
    "column_0:i64=[1,3] column_1:i64=[null,4]",
  )
  assert_eq(
    csv_run("1,2\n3,4,5\n", options=nh),
    "column_0:i64=[1,3] column_1:i64=[2,4] column_2:i64=[null,5]",
  )
  let nh2 = @pl.CsvReadOptions::new(
    has_header=false,
    infer_schema_length=Some(1),
  )
  assert_eq(
    csv_run("1\n2,3\n", options=nh2),
    "ParseError: found more fields than defined in 'Schema' at line 2",
  )
  let nh3 = @pl.CsvReadOptions::new(has_header=false, infer_schema_length=None)
  assert_eq(
    csv_run("1\n2,3\n4,5,6\n", options=nh3),
    "column_0:i64=[1,2,4] column_1:i64=[null,3,5] column_2:i64=[null,null,6]",
  )
  assert_eq(
    csv_run("a,a\n", options=nh),
    "column_0:str=['a'] column_1:str=['a']",
  )
  assert_eq(
    csv_run(",\n", options=nh),
    "column_0:str=[null] column_1:str=[null]",
  )
  assert_eq(csv_run("", options=nh), "ParseError: empty CSV")
  assert_eq(csv_run("\u{FEFF}", options=nh), "ParseError: empty CSV")
  let nh4 = @pl.CsvReadOptions::new(has_header=false, n_rows=0)
  assert_eq(
    csv_run("1,2\n3,4\n", options=nh4),
    "column_0:i64=[] column_1:i64=[]",
  )
  let nh5 = @pl.CsvReadOptions::new(has_header=false, skip_rows=1)
  assert_eq(
    csv_run("x\n1,2\n3,4\n", options=nh5),
    "column_0:i64=[1,3] column_1:i64=[2,4]",
  )
  assert_eq(
    csv_run(
      "x\n1,2\n3,4\n",
      options=@pl.CsvReadOptions::new(has_header=false, skip_rows=5),
    ),
    "ParseError: empty CSV",
  )
}

///|
test "csv read: empty input" {
  assert_eq(csv_run(""), "ParseError: empty CSV")
  assert_eq(csv_run("\n"), "ParseError: empty CSV")
  assert_eq(csv_run("\n\n"), "ParseError: empty CSV")
  assert_eq(csv_run("\r\n"), "ParseError: empty CSV")
  assert_eq(csv_run("\u{FEFF}"), "ParseError: empty CSV")
  assert_eq(csv_run("\u{FEFF}\n"), "ParseError: empty CSV")
  assert_eq(
    csv_run("x\ny\n", options=@pl.CsvReadOptions::new(skip_rows=2)),
    "ParseError: empty CSV",
  )
  assert_eq(
    csv_run("x\ny\n", options=@pl.CsvReadOptions::new(skip_rows=9)),
    "ParseError: empty CSV",
  )
  // spaces are a header
  assert_eq(csv_run("  "), "  :str=[]")
}

///|
test "csv read: skip_rows and n_rows" {
  let d = "a,b\n1,2\n3,4\n5,6\n"
  assert_eq(
    csv_run(d, options=@pl.CsvReadOptions::new(n_rows=2)),
    "a:i64=[1,3] b:i64=[2,4]",
  )
  assert_eq(
    csv_run(d, options=@pl.CsvReadOptions::new(n_rows=10)),
    "a:i64=[1,3,5] b:i64=[2,4,6]",
  )
  assert_eq(
    csv_run(d, options=@pl.CsvReadOptions::new(n_rows=0)),
    "a:i64=[] b:i64=[]",
  )
  assert_eq(
    csv_run(
      d,
      options=@pl.CsvReadOptions::new(n_rows=0, infer_schema_length=Some(0)),
    ),
    "a:str=[] b:str=[]",
  )
  // skip_rows skips records before the header
  assert_eq(
    csv_run(d, options=@pl.CsvReadOptions::new(skip_rows=1)),
    "1:i64=[3,5] 2:i64=[4,6]",
  )
  assert_eq(
    csv_run(d, options=@pl.CsvReadOptions::new(skip_rows=3)),
    "5:str=[] 6:str=[]",
  )
  assert_eq(
    csv_run(d, options=@pl.CsvReadOptions::new(skip_rows=4)),
    "ParseError: empty CSV",
  )
  assert_eq(
    csv_run(d, options=@pl.CsvReadOptions::new(skip_rows=1, n_rows=1)),
    "1:i64=[3] 2:i64=[4]",
  )
  // a quoted newline is inside one record
  assert_eq(
    csv_run(
      "x\n\"y\nz\"\na,b\n1,2\n",
      options=@pl.CsvReadOptions::new(skip_rows=2),
    ),
    "a:i64=[1] b:i64=[2]",
  )
  assert_eq(
    csv_run(
      "x\r\ny\r\na,b\r\n1,2\r\n",
      options=@pl.CsvReadOptions::new(skip_rows=2),
    ),
    "a:i64=[1] b:i64=[2]",
  )
  assert_eq(
    csv_run("x\ny\na,b\n", options=@pl.CsvReadOptions::new(skip_rows=2)),
    "a:str=[] b:str=[]",
  )
  assert_eq(
    csv_run("x\ny\n", options=@pl.CsvReadOptions::new(skip_rows=1)),
    "y:str=[]",
  )
  // a BOM is removed before skipping
  assert_eq(
    csv_run(
      "\u{FEFF}x\na,b\n1,2\n",
      options=@pl.CsvReadOptions::new(skip_rows=1),
    ),
    "a:i64=[1] b:i64=[2]",
  )
  // n_rows only trims the result: the inference still looks at infer_schema_length rows
  assert_eq(
    csv_run("a\n1\n2.5\n", options=@pl.CsvReadOptions::new(n_rows=1)),
    "a:f64=[1.0]",
  )
  assert_eq(
    csv_run("a\n1\nx\n", options=@pl.CsvReadOptions::new(n_rows=1)),
    "a:str=['1']",
  )
  // a long row inside the inference window is still an error
  assert_eq(
    csv_run("a,b\n1,2\n3,4\n5,6,7\n", options=@pl.CsvReadOptions::new(n_rows=1)),
    "ParseError: found more fields than defined in 'Schema' at line 4",
  )
}

///|
test "csv read: infer_schema_length and later bad values" {
  let isl2 = @pl.CsvReadOptions::new(infer_schema_length=Some(2))
  assert_eq(
    csv_run("a\n1\n2\n3\nx\n5\n", options=isl2),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 5",
  )
  assert_eq(
    csv_run("a\n1\n2\n2.5\n", options=isl2),
    "ParseError: could not parse `2.5` as dtype `i64` at column 'a' (column number 1) at line 4",
  )
  assert_eq(
    csv_run("a\n1\n2\n99999999999999999999\n", options=isl2),
    "ParseError: could not parse `99999999999999999999` as dtype `i64` at column 'a' (column number 1) at line 4",
  )
  assert_eq(
    csv_run("a\n1\n2\ntrue\n", options=isl2),
    "ParseError: could not parse `true` as dtype `i64` at column 'a' (column number 1) at line 4",
  )
  assert_eq(
    csv_run("a\n1\n2\n5 \n", options=isl2),
    "ParseError: could not parse `5 ` as dtype `i64` at column 'a' (column number 1) at line 4",
  )
  assert_eq(
    csv_run("a\n1.5\n2.5\nx\n", options=isl2),
    "ParseError: could not parse `x` as dtype `f64` at column 'a' (column number 1) at line 4",
  )
  assert_eq(
    csv_run("a\ntrue\nfalse\n1\n", options=isl2),
    "ParseError: could not parse `1` as dtype `bool` at column 'a' (column number 1) at line 4",
  )
  assert_eq(
    csv_run("b,a\n1,2\n1,3\n1,x\n", options=isl2),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 2) at line 4",
  )
  // what the other type accepts later
  assert_eq(csv_run("a\n1.5\n2\n3\n", options=isl2), "a:f64=[1.5,2.0,3.0]")
  assert_eq(csv_run("a\n1\n2\n+5\n", options=isl2), "a:i64=[1,2,5]")
  assert_eq(csv_run("a\n1\n2\n 5\n", options=isl2), "a:i64=[1,2,5]")
  assert_eq(csv_run("a\n1\n2\n\"\"\n", options=isl2), "a:i64=[1,2,null]")
  assert_eq(csv_run("a\n1.5\n2.5\nnan\n", options=isl2), "a:f64=[1.5,2.5,NaN]")
  assert_eq(csv_run("a\n1.5\n2.5\nInf\n", options=isl2), "a:f64=[1.5,2.5,inf]")
  assert_eq(
    csv_run("a\ntrue\nfalse\nTRUE\n", options=isl2),
    "a:bool=[true,false,true]",
  )
  assert_eq(csv_run("a\nx\ny\n3\n", options=isl2), "a:str=['x','y','3']")
  // the quoted text of the bad value is shown with its quotes
  assert_eq(
    csv_run("a\n1\n2\n\"x\"\n", options=isl2),
    "ParseError: could not parse `\"x\"` as dtype `i64` at column 'a' (column number 1) at line 4",
  )
  assert_eq(
    csv_run("a\n1\n2\n\"x\"\"y\"\n", options=isl2),
    "ParseError: could not parse `\"x\"\"y\"` as dtype `i64` at column 'a' (column number 1) at line 4",
  )
  // the message is the first line of polars'; the row is where the record starts
  assert_eq(
    csv_run("a\n1\n2\n\"x\ny\"\n5\n", options=isl2),
    "ParseError: could not parse `\"x at line 4",
  )
  assert_eq(
    csv_run(
      "a\n1\n\"p\nq\"\nx\n",
      options=@pl.CsvReadOptions::new(infer_schema_length=Some(1)),
    ),
    "ParseError: could not parse `\"p at line 3",
  )
  assert_eq(
    csv_run("a\r\n1\r\n2\r\nx\r\n", options=isl2),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 4",
  )
  // None scans everything, Some(0) reads everything as String
  let all = @pl.CsvReadOptions::new(infer_schema_length=None)
  assert_eq(csv_run("a\n1\n2.5\nx\n", options=all), "a:str=['1','2.5','x']")
  let zero = @pl.CsvReadOptions::new(infer_schema_length=Some(0))
  assert_eq(
    csv_run("a,b\n1,\n2.5,x\n", options=zero),
    "a:str=['1','2.5'] b:str=[null,'x']",
  )
  // the first row is the whole window
  assert_eq(
    csv_run(
      "a\n1\n2.5\nx\n",
      options=@pl.CsvReadOptions::new(infer_schema_length=Some(1)),
    ),
    "ParseError: could not parse `2.5` as dtype `i64` at column 'a' (column number 1) at line 3",
  )
  // nulls inside the window, a value after it
  assert_eq(
    csv_run(
      "a,b\n,\n,\n1,5\n",
      options=@pl.CsvReadOptions::new(infer_schema_length=Some(2)),
    ),
    "a:str=[null,null,'1'] b:str=[null,null,'5']",
  )
  // a quoted empty string in the window forces String
  assert_eq(csv_run("a\n1\n\"\"\n"), "a:str=['1','']")
}

///|
test "csv read: schema_overrides" {
  fn ov(name : String, dt : @pl.DataType) -> @pl.CsvReadOptions {
    @pl.CsvReadOptions::new(schema_overrides=Map::from_array([(name, dt)]))
  }

  // Int
  assert_eq(
    csv_run("a\n 1\n\t2\n+5\n 3\n", options=ov("a", @pl.DataType::Int64)),
    "a:i64=[1,2,5,3]",
  )
  assert_eq(
    csv_run("a\n007\n", options=ov("a", @pl.DataType::Int32)),
    "a:i32=[7]",
  )
  assert_eq(
    csv_run("a\n3000000000\n", options=ov("a", @pl.DataType::Int32)),
    "ParseError: could not parse `3000000000` as dtype `i32` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run(
      "a\n2147483647\n-2147483648\n",
      options=ov("a", @pl.DataType::Int32),
    ),
    "a:i32=[2147483647,-2147483648]",
  )
  assert_eq(
    csv_run("a\n1.0\n", options=ov("a", @pl.DataType::Int64)),
    "ParseError: could not parse `1.0` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n1e3\n", options=ov("a", @pl.DataType::Int64)),
    "ParseError: could not parse `1e3` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n1 \n", options=ov("a", @pl.DataType::Int64)),
    "ParseError: could not parse `1 ` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n9223372036854775808\n", options=ov("a", @pl.DataType::Int64)),
    "ParseError: could not parse `9223372036854775808` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n+ 5\n", options=ov("a", @pl.DataType::Int64)),
    "ParseError: could not parse `+ 5` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n--5\n", options=ov("a", @pl.DataType::Int64)),
    "ParseError: could not parse `--5` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n\n1\n", options=ov("a", @pl.DataType::Int32)),
    "a:i32=[null,1]",
  )
  assert_eq(
    csv_run("a\n1\n\"\"\n", options=ov("a", @pl.DataType::Int64)),
    "a:i64=[1,null]",
  )
  // Float
  assert_eq(
    csv_run(
      "a\n+5\n 1.5\nnan\nNaN\nInf\ninf\n-inf\n",
      options=ov("a", @pl.DataType::Float64),
    ),
    "a:f64=[5.0,1.5,NaN,NaN,inf,inf,-inf]",
  )
  assert_eq(
    csv_run("a\n  -Inf\n \t +1.5\n", options=ov("a", @pl.DataType::Float64)),
    "a:f64=[-inf,1.5]",
  )
  assert_eq(
    csv_run("a\n1.5 \n", options=ov("a", @pl.DataType::Float64)),
    "ParseError: could not parse `1.5 ` as dtype `f64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\nx\n", options=ov("a", @pl.DataType::Float64)),
    "ParseError: could not parse `x` as dtype `f64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n.\n", options=ov("a", @pl.DataType::Float64)),
    "ParseError: could not parse `.` as dtype `f64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run(
      "a\n1e400\n-1e400\n1e-400\n",
      options=ov("a", @pl.DataType::Float64),
    ),
    "a:f64=[inf,-inf,0.0]",
  )
  assert_eq(
    csv_run(
      "a\ninf\n1e39\n3.4028235e38\n",
      options=ov("a", @pl.DataType::Float32),
    ),
    "a:f32=[inf,inf,3.4028235e+38]",
  )
  assert_eq(
    csv_run("a\n0.1\n 1.5\n", options=ov("a", @pl.DataType::Float32)),
    "a:f32=[0.1,1.5]",
  )
  assert_eq(
    csv_run("a\nx\n", options=ov("a", @pl.DataType::Float32)),
    "ParseError: could not parse `x` as dtype `f32` at column 'a' (column number 1) at line 2",
  )
  // Boolean: only true/false, any case, no spaces
  assert_eq(
    csv_run("a\nTRUE\nfalse\nTrUe\n", options=ov("a", @pl.DataType::Boolean)),
    "a:bool=[true,false,true]",
  )
  assert_eq(
    csv_run("a\ntrue\n1\n", options=ov("a", @pl.DataType::Boolean)),
    "ParseError: could not parse `1` as dtype `bool` at column 'a' (column number 1) at line 3",
  )
  assert_eq(
    csv_run("a\n true\n", options=ov("a", @pl.DataType::Boolean)),
    "ParseError: could not parse ` true` as dtype `bool` at column 'a' (column number 1) at line 2",
  )
  // String keeps the text
  assert_eq(
    csv_run("a\n007\n 1\n\"\"\n\n", options=ov("a", @pl.DataType::String)),
    "a:str=['007',' 1','',null]",
  )
  assert_eq(
    csv_run("a\n\"true\"\nfalse\n", options=ov("a", @pl.DataType::String)),
    "a:str=['true','false']",
  )
  // Date
  assert_eq(
    csv_run(
      "a\n2024-01-02\n2024/01/02\n 2024-01-02\n",
      options=ov("a", @pl.DataType::Date),
    ),
    "a:date=[d19724,d19724,d19724]",
  )
  assert_eq(
    csv_run("a\n01/02/2024\n", options=ov("a", @pl.DataType::Date)),
    "a:date=[d19754]",
  )
  assert_eq(
    csv_run("a\n2024-13-02\n", options=ov("a", @pl.DataType::Date)),
    "ParseError: could not parse `2024-13-02` as dtype `date` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n2024-01-02\n01/02/2024\n", options=ov("a", @pl.DataType::Date)),
    "ParseError: could not parse `01/02/2024` as dtype `date` at column 'a' (column number 1) at line 3",
  )
  assert_eq(
    csv_run("a\n2024-01-02T01:02:03\n", options=ov("a", @pl.DataType::Date)),
    "ParseError: could not parse `2024-01-02T01:02:03` as dtype `date` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n2024-01-02\n\"\"\n", options=ov("a", @pl.DataType::Date)),
    "a:date=[d19724,null]",
  )
  // Datetime
  assert_eq(
    csv_run(
      "a\n2024-01-02T01:02:03\n2024-01-02 01:02:03\n",
      options=ov("a", @pl.DataType::Datetime),
    ),
    "a:datetime[μs]=[t1704157323000000,t1704157323000000]",
  )
  assert_eq(
    csv_run(
      "a\n2024-01-02\n2024-01-02T01:02:03\n",
      options=ov("a", @pl.DataType::Datetime),
    ),
    "a:datetime[μs]=[t1704153600000000,t1704157323000000]",
  )
  assert_eq(
    csv_run(
      "a\n2024-01-02T01:02:03\n2024-01-02\n",
      options=ov("a", @pl.DataType::Datetime),
    ),
    "a:datetime[μs]=[t1704157323000000,t1704153600000000]",
  )
  assert_eq(
    csv_run("a\n2024-1-2 1:2:3\n", options=ov("a", @pl.DataType::Datetime)),
    "a:datetime[μs]=[t1704157323000000]",
  )
  assert_eq(
    csv_run(
      "a\n 2024-01-02T01:02:03\n",
      options=ov("a", @pl.DataType::Datetime),
    ),
    "a:datetime[μs]=[t1704157323000000]",
  )
  assert_eq(
    csv_run(
      "a\n2024-01-02T01:02:03.123456789\n",
      options=ov("a", @pl.DataType::Datetime),
    ),
    "a:datetime[μs]=[t1704157323123456]",
  )
  assert_eq(
    csv_run("a\nx\n", options=ov("a", @pl.DataType::Datetime)),
    "ParseError: could not parse `x` as dtype `datetime[μs]` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run(
      "a\n2024-01-02T01:02:03\n01/02/2024 01:02:03\n",
      options=ov("a", @pl.DataType::Datetime),
    ),
    "ParseError: could not parse `01/02/2024 01:02:03` as dtype `datetime[μs]` at column 'a' (column number 1) at line 3",
  )
  // an offset is a time zone, which the library has not (polars converts to UTC)
  assert_eq(
    csv_run(
      "a\n2024-01-02T01:02:03Z\n",
      options=ov("a", @pl.DataType::Datetime),
    ),
    "ParseError: could not parse `2024-01-02T01:02:03Z` as dtype `datetime[μs]` at column 'a' (column number 1) at line 2",
  )
  // Null is not a CSV type
  assert_eq(
    csv_run("a\n1\n", options=ov("a", @pl.DataType::Null)),
    "ComputeError: unsupported data type when reading CSV: null when reading CSV",
  )
  // an unknown column name is ignored
  assert_eq(csv_run("a\n1\n", options=ov("b", @pl.DataType::Null)), "a:i64=[1]")
  // the header-only table takes the types of the overrides
  assert_eq(
    csv_run("a,b\n", options=ov("a", @pl.DataType::Int32)),
    "a:i32=[] b:str=[]",
  )
  // an override of an all-empty column
  assert_eq(
    csv_run("a,b\n1,\n2,\n", options=ov("b", @pl.DataType::Int64)),
    "a:i64=[1,2] b:i64=[null,null]",
  )
  // overrides see the names after de-duplication
  assert_eq(
    csv_run("a,a\n1,2\n", options=ov("a", @pl.DataType::String)),
    "a:str=['1'] a_duplicated_0:i64=[2]",
  )
  assert_eq(
    csv_run("a,a\n1,2\n", options=ov("a_duplicated_0", @pl.DataType::String)),
    "a:i64=[1] a_duplicated_0:str=['2']",
  )
  assert_eq(
    csv_run(
      "1,2\n",
      options=@pl.CsvReadOptions::new(has_header=false, schema_overrides={
        "column_0": @pl.DataType::String,
      }),
    ),
    "column_0:str=['1'] column_1:i64=[2]",
  )
  // a quoted number is parsed too
  assert_eq(
    csv_run("a\n\"1\"\n", options=ov("a", @pl.DataType::Float64)),
    "a:f64=[1.0]",
  )
  // overrides need not be a column of the inferred type
  assert_eq(
    csv_run("a\n1\n2\n", options=ov("a", @pl.DataType::Float64)),
    "a:f64=[1.0,2.0]",
  )
  assert_eq(
    csv_run("a\n2024-01-02\n", options=ov("a", @pl.DataType::Int64)),
    "ParseError: could not parse `2024-01-02` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
}

///|
test "csv read: try_parse_dates" {
  let td = @pl.CsvReadOptions::new(try_parse_dates=true)
  // default: dates are strings
  assert_eq(csv_run("a\n2024-01-02\n"), "a:str=['2024-01-02']")
  assert_eq(csv_run("a\n20240102\n"), "a:i64=[20240102]")
  assert_eq(
    csv_run("a\n2024-01-02T01:02:03\n"),
    "a:str=['2024-01-02T01:02:03']",
  )
  // dates
  assert_eq(
    csv_run("a\n2024-01-02\n2024-1-2\n2024/01/03\n", options=td),
    "a:date=[d19724,d19724,d19725]",
  )
  assert_eq(csv_run("a\n01/02/2024\n", options=td), "a:date=[d19754]")
  assert_eq(csv_run("a\n02-01-2024\n", options=td), "a:date=[d19724]")
  assert_eq(csv_run("a\n02.01.2024\n", options=td), "a:date=[d19724]")
  assert_eq(csv_run("a\n  2024-01-02\n", options=td), "a:date=[d19724]")
  assert_eq(csv_run("a\n\"2024-01-02\"\n", options=td), "a:date=[d19724]")
  assert_eq(
    csv_run("a\n2024-01-02\n\n2024-01-03\n", options=td),
    "a:date=[d19724,null,d19725]",
  )
  // not dates
  assert_eq(csv_run("a\n2024-01-02 \n", options=td), "a:str=['2024-01-02 ']")
  assert_eq(csv_run("a\n2024-13-01\n", options=td), "a:str=['2024-13-01']")
  assert_eq(csv_run("a\n2024-02-30\n", options=td), "a:str=['2024-02-30']")
  assert_eq(csv_run("a\n2024-01\n", options=td), "a:str=['2024-01']")
  assert_eq(csv_run("a\nJan 2 2024\n", options=td), "a:str=['Jan 2 2024']")
  assert_eq(csv_run("a\n12024-01-02\n", options=td), "a:str=['12024-01-02']")
  assert_eq(csv_run("a\n2024-01-02T\n", options=td), "a:str=['2024-01-02T']")
  assert_eq(csv_run("a\n\n\n", options=td), "a:str=[null,null]")
  assert_eq(
    csv_run("a\n2024-01-02\n\"\"\n", options=td),
    "a:str=['2024-01-02','']",
  )
  assert_eq(
    csv_run("a\n2024-01-02\n5\n", options=td),
    "a:str=['2024-01-02','5']",
  )
  assert_eq(
    csv_run("a\n5\n2024-01-02\n", options=td),
    "a:str=['5','2024-01-02']",
  )
  // a date column whose texts have different formats is an error, not a String
  assert_eq(
    csv_run("a\n2024-01-02\n01/02/2024\n", options=td),
    "ParseError: could not parse `01/02/2024` as dtype `date` at column 'a' (column number 1) at line 3",
  )
  assert_eq(
    csv_run("a\n01/02/2024\n2024-01-02\n", options=td),
    "ParseError: could not parse `2024-01-02` as dtype `date` at column 'a' (column number 1) at line 3",
  )
  // datetimes (no time zone)
  assert_eq(
    csv_run("a\n2024-01-02T01:02:03\n2024-01-02 01:02:03\n", options=td),
    "a:datetime[μs]=[t1704157323000000,t1704157323000000]",
  )
  assert_eq(
    csv_run("a\n2024-01-02T01:02:03\n2024-01-02T01:02\n", options=td),
    "a:datetime[μs]=[t1704157323000000,t1704157320000000]",
  )
  assert_eq(
    csv_run(
      "a\n2024-01-02T01:02:03.123456789\n2024-01-02T01:02:03.5\n",
      options=td,
    ),
    "a:datetime[μs]=[t1704157323123456,t1704157323500000]",
  )
  assert_eq(
    csv_run("a\n2024/01/02 03:04:05\n", options=td),
    "a:datetime[μs]=[t1704164645000000]",
  )
  // a date and a datetime in one column make a String
  assert_eq(
    csv_run("a\n2024-01-02T01:02:03\n2024-01-02\n", options=td),
    "a:str=['2024-01-02T01:02:03','2024-01-02']",
  )
  assert_eq(
    csv_run("a\n2024-01-02\n2024-01-02T01:02:03\n", options=td),
    "a:str=['2024-01-02','2024-01-02T01:02:03']",
  )
  // time zones and bare times are not supported: String
  assert_eq(
    csv_run("a\n2024-01-02T01:02:03Z\n", options=td),
    "a:str=['2024-01-02T01:02:03Z']",
  )
  assert_eq(
    csv_run("a\n2024-01-02T01:02:03+01:00\n", options=td),
    "a:str=['2024-01-02T01:02:03+01:00']",
  )
  assert_eq(
    csv_run("a\n2024-01-02T01:02:03\n2024-01-02T01:02:03Z\n", options=td),
    "a:str=['2024-01-02T01:02:03','2024-01-02T01:02:03Z']",
  )
  assert_eq(csv_run("a\n03:04:05\n", options=td), "a:str=['03:04:05']")
  // the format of the first datetime decides
  assert_eq(
    csv_run("a\n2024-01-02T01:02:03\n01/02/2024 01:02:03\n", options=td),
    "ParseError: could not parse `01/02/2024 01:02:03` as dtype `datetime[μs]` at column 'a' (column number 1) at line 3",
  )
  // beyond the inference window
  let td2 = @pl.CsvReadOptions::new(
    try_parse_dates=true,
    infer_schema_length=Some(2),
  )
  assert_eq(
    csv_run("a\n2024-01-02\n2024-01-03\nx\n", options=td2),
    "ParseError: could not parse `x` as dtype `date` at column 'a' (column number 1) at line 4",
  )
  assert_eq(
    csv_run("a\n2024-01-02T01:02:03\n2024-01-03T01:02:03\nx\n", options=td2),
    "ParseError: could not parse `x` as dtype `datetime[μs]` at column 'a' (column number 1) at line 4",
  )
  assert_eq(
    csv_run("a\n2024-01-02\n2024-01-03\n2024-01-03T01:02:03\n", options=td2),
    "ParseError: could not parse `2024-01-03T01:02:03` as dtype `date` at column 'a' (column number 1) at line 4",
  )
  assert_eq(
    csv_run(
      "a\n2024-01-02T01:02:03\n2024-01-03T01:02:03\n2024-01-03\n",
      options=td2,
    ),
    "a:datetime[μs]=[t1704157323000000,t1704243723000000,t1704240000000000]",
  )
  assert_eq(
    csv_run("a\n2024-01-02\n2024-01-03\n2024-1-4\n", options=td2),
    "a:date=[d19724,d19725,d19726]",
  )
}

///|
test "csv read: separators" {
  assert_eq(
    csv_run("a\tb\n1\t2\n", options=@pl.CsvReadOptions::new(separator='\t')),
    "a:i64=[1] b:i64=[2]",
  )
  assert_eq(
    csv_run("a;b\n\"1;2\";3\n", options=@pl.CsvReadOptions::new(separator=';')),
    "a:str=['1;2'] b:i64=[3]",
  )
  // a non-ASCII separator, also one outside the BMP
  assert_eq(
    csv_run("a§b\n1§2\n", options=@pl.CsvReadOptions::new(separator='§')),
    "a:i64=[1] b:i64=[2]",
  )
  assert_eq(
    csv_run(
      "a😀b\n1😀2\n",
      options=@pl.CsvReadOptions::new(separator='😀'),
    ),
    "a:i64=[1] b:i64=[2]",
  )
  assert_eq(
    csv_run(
      "a😀b\n1😁2\n😀\n",
      options=@pl.CsvReadOptions::new(separator='😀'),
    ),
    "a:str=['1😁2',null] b:str=[null,null]",
  )
  assert_eq(
    csv_run(
      "a,b\n’x,y’,2\n",
      options=@pl.CsvReadOptions::new(quote_char=Some('’')),
    ),
    "a:str=['x,y'] b:i64=[2]",
  )
  assert_eq(
    csv_run(
      "a,b\n😀x,y😀,2\n",
      options=@pl.CsvReadOptions::new(quote_char=Some('😀')),
    ),
    "a:str=['x,y'] b:i64=[2]",
  )
  assert_eq(
    csv_run(
      "a,b\n😀x😀😀y😀,2\n",
      options=@pl.CsvReadOptions::new(quote_char=Some('😀')),
    ),
    "a:str=['x😀y'] b:i64=[2]",
  )
  // a space separator: two spaces make an empty column
  assert_eq(
    csv_run("a b\n1 2\n", options=@pl.CsvReadOptions::new(separator=' ')),
    "a:i64=[1] b:i64=[2]",
  )
}

///|
test "csv read: invalid options" {
  fn bad(o : @pl.CsvReadOptions) -> String {
    csv_run("a\n1\n", options=o)
  }

  assert_eq(
    bad(@pl.CsvReadOptions::new(n_rows=-1)),
    "InvalidOperation: n_rows must not be negative, got -1",
  )
  assert_eq(
    bad(@pl.CsvReadOptions::new(skip_rows=-2)),
    "InvalidOperation: skip_rows must not be negative, got -2",
  )
  assert_eq(
    bad(@pl.CsvReadOptions::new(infer_schema_length=Some(-3))),
    "InvalidOperation: infer_schema_length must not be negative, got -3",
  )
  assert_eq(
    bad(@pl.CsvReadOptions::new(separator='\n')),
    "InvalidOperation: separator must not be a line break (LF or CR)",
  )
  assert_eq(
    bad(@pl.CsvReadOptions::new(separator='\r')),
    "InvalidOperation: separator must not be a line break (LF or CR)",
  )
  assert_eq(
    bad(@pl.CsvReadOptions::new(quote_char=Some('\n'))),
    "InvalidOperation: quote_char must not be a line break (LF or CR)",
  )
  assert_eq(
    bad(@pl.CsvReadOptions::new(quote_char=Some('\r'))),
    "InvalidOperation: quote_char must not be a line break (LF or CR)",
  )
  assert_eq(
    bad(@pl.CsvReadOptions::new(separator='"')),
    "InvalidOperation: separator and quote_char must differ, got '\"'",
  )
  assert_eq(
    bad(@pl.CsvReadOptions::new(separator='|', quote_char=Some('|'))),
    "InvalidOperation: separator and quote_char must differ, got '|'",
  )
  // a separator equal to the quote is fine when quoting is off
  assert_eq(
    csv_run(
      "a\"b\n1\"2\n",
      options=@pl.CsvReadOptions::new(separator='"', quote_char=None),
    ),
    "a:i64=[1] b:i64=[2]",
  )
  // the options are checked before the text is read
  assert_eq(
    csv_run("", options=@pl.CsvReadOptions::new(n_rows=-1)),
    "InvalidOperation: n_rows must not be negative, got -1",
  )
  // the options struct reads back
  let o = @pl.CsvReadOptions::new(n_rows=5, skip_rows=2)
  assert_eq(o.n_rows, Some(5))
  assert_eq(o.skip_rows, 2)
  assert_eq(o.separator, ',')
  assert_eq(o.quote_char, Some('"'))
  assert_eq(o.infer_schema_length, Some(100))
  assert_eq(o.has_header, true)
  assert_eq(o.try_parse_dates, false)
  assert_eq(o.null_values.length(), 0)
  assert_eq(o.schema_overrides.length(), 0)
  assert_eq(@pl.CsvReadOptions::new().n_rows, None)
}

///|
test "csv read: line numbers" {
  // first data row
  assert_eq(
    csv_run(
      "a\nx\n",
      options=@pl.CsvReadOptions::new(schema_overrides={
        "a": @pl.DataType::Int64,
      }),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  // after a quoted field with newlines
  assert_eq(
    csv_run(
      "a,b\n\"p\nq\nr\",1\nx,2\n",
      options=@pl.CsvReadOptions::new(schema_overrides={
        "a": @pl.DataType::Int64,
      }),
    ),
    "ParseError: could not parse `\"p at line 2",
  )
  assert_eq(
    csv_run(
      "a,b\n1,\"p\nq\nr\"\nx,2\n",
      options=@pl.CsvReadOptions::new(schema_overrides={
        "a": @pl.DataType::Int64,
      }),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 5",
  )
  // CRLF file
  assert_eq(
    csv_run(
      "a,b\r\n1,2\r\nx,3\r\n",
      options=@pl.CsvReadOptions::new(schema_overrides={
        "a": @pl.DataType::Int64,
      }),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 3",
  )
  // blank lines before the header and skipped rows count as lines
  assert_eq(
    csv_run(
      "\n\na\nx\n",
      options=@pl.CsvReadOptions::new(schema_overrides={
        "a": @pl.DataType::Int64,
      }),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 4",
  )
  assert_eq(
    csv_run(
      "junk\nmore\na\nx\n",
      options=@pl.CsvReadOptions::new(skip_rows=2, schema_overrides={
        "a": @pl.DataType::Int64,
      }),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 4",
  )
  // the BOM is not a line
  assert_eq(
    csv_run(
      "\u{FEFF}a\nx\n",
      options=@pl.CsvReadOptions::new(schema_overrides={
        "a": @pl.DataType::Int64,
      }),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  // a bare CR does not count
  assert_eq(
    csv_run(
      "a,b\n1\r2,3\nx,4\n",
      options=@pl.CsvReadOptions::new(schema_overrides={
        "b": @pl.DataType::Int64,
        "a": @pl.DataType::Int64,
      }),
    ),
    "ParseError: could not parse `1\r2` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  // a header spanning lines
  assert_eq(
    csv_run(
      "\"a\nb\"\nx\n",
      options=@pl.CsvReadOptions::new(schema_overrides={
        "a\nb": @pl.DataType::Int64,
      }),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a at line 3",
  )
  // a long row after blank lines
  assert_eq(
    csv_run("a,b\n\n\n1,2,3\n"),
    "ParseError: found more fields than defined in 'Schema' at line 4",
  )
  // an unterminated quote after a multi-line record
  assert_eq(
    csv_run("a\n\"x\ny\"\n\"z\n"),
    "ParseError: could not parse `\"z at line 4",
  )
}

///|
fn csv_ov(name : String, dt : @pl.DataType) -> @pl.CsvReadOptions {
  @pl.CsvReadOptions::new(schema_overrides=Map::from_array([(name, dt)]))
}

///|
fn csv_ov2(a : @pl.DataType, b : @pl.DataType) -> @pl.CsvReadOptions {
  @pl.CsvReadOptions::new(
    schema_overrides=Map::from_array([("a", a), ("b", b)]),
  )
}

///|
test "csv read: the first bad record in file order is the error" {
  let i64 = csv_ov("a", @pl.DataType::Int64)
  let nf = "found more fields than defined in 'Schema'"
  // a value error before a long row
  assert_eq(
    csv_run("a,b\nx,2\n1,2,3\n", options=i64),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  // a long row before a value error
  assert_eq(
    csv_run("a,b\n1,2,3\nx,2\n", options=i64),
    "ParseError: \{nf} at line 2",
  )
  // the same record: values of the columns before the field of the structural
  // error come first, a long row is after every column
  assert_eq(
    csv_run("a,b\nx,2,3\n", options=i64),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a,b\nx,\"y\"z\n", options=i64),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a,b\nx,\"y\n", options=i64),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a,b\n\"y\"z,x\n", options=csv_ov("b", @pl.DataType::Int64)),
    "ParseError: could not parse `\"y\"z` as dtype `str` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a,b\n1,\"y\"z\nx,2\n", options=i64),
    "ParseError: could not parse `\"y\"z` as dtype `str` at column 'b' (column number 2) at line 2",
  )
  assert_eq(
    csv_run("a,b\nx,2\n1,\"y\"z\n", options=i64),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a,b\nx,2\n1,2,3\n", options=csv_ov("b", @pl.DataType::Int64)),
    "ParseError: \{nf} at line 3",
  )
  assert_eq(
    csv_run("a,b\n1,2,3\n1,\"y\"z\n", options=i64),
    "ParseError: \{nf} at line 2",
  )
  // the first row, then the first column
  assert_eq(
    csv_run(
      "a,b\n1,x\ny,2\n",
      options=csv_ov2(@pl.DataType::Int64, @pl.DataType::Int64),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'b' (column number 2) at line 2",
  )
  assert_eq(
    csv_run(
      "a,b\ny,x\n",
      options=csv_ov2(@pl.DataType::Int64, @pl.DataType::Int64),
    ),
    "ParseError: could not parse `y` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run(
      "a,b\n1,2\ny,x\n3,4,5\n",
      options=csv_ov2(@pl.DataType::Int64, @pl.DataType::Int64),
    ),
    "ParseError: could not parse `y` as dtype `i64` at column 'a' (column number 1) at line 3",
  )
  assert_eq(
    csv_run(
      "a,b\n1,2,3\nx,y\n",
      options=csv_ov2(@pl.DataType::Int64, @pl.DataType::Int64),
    ),
    "ParseError: \{nf} at line 2",
  )
  // a value error beyond the inference window before a bad quote
  assert_eq(
    csv_run(
      "a\n1\nx\n\"x\"y\n",
      options=@pl.CsvReadOptions::new(infer_schema_length=Some(1)),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 3",
  )
  // structural errors alone, in file order
  assert_eq(
    csv_run("a,b\n1,2\n3,4,5\n6,\"x\"y\n"),
    "ParseError: \{nf} at line 3",
  )
  assert_eq(
    csv_run("a,b\n1,\"x\"y\n3,4,5\n"),
    "ParseError: could not parse `\"x\"y` as dtype `str` at column 'b' (column number 2) at line 2",
  )
  assert_eq(
    csv_run("a,b\n1,2\n\"x\"y,3\n3,4,5\n"),
    "ParseError: could not parse `\"x\"y` as dtype `str` at column 'a' (column number 1) at line 3",
  )
  // a multi-line record before the problems
  assert_eq(
    csv_run(
      "a,b\n\"p\nq\",1\n1,x\n3,4,5\n",
      options=csv_ov("b", @pl.DataType::Int64),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'b' (column number 2) at line 4",
  )
}

///|
test "csv read: whitespace-only fields of number columns are null" {
  let numeric : Array[@pl.DataType] = [Int32, Int64, Float32, Float64]
  let names = ["i32", "i64", "f32", "f64"]
  for k, dt in numeric {
    for ws in [" ", "   ", "\t", " \t", "\"  \"", "\"\t\""] {
      assert_eq(
        csv_run("a,b\n\{ws},x\n", options=csv_ov("a", dt)),
        "a:\{names[k]}=[null] b:str=['x']",
      )
      assert_eq(
        csv_run("a\n1\n\{ws}\n2\n", options=csv_ov("a", dt)),
        "a:\{names[k]}=[" +
        (if k < 2 { "1,null,2" } else { "1.0,null,2.0" }) +
        "]",
      )
    }
  }
  // past the inference window
  let w1 = @pl.CsvReadOptions::new(infer_schema_length=Some(1))
  assert_eq(csv_run("a\n1\n \n3\n", options=w1), "a:i64=[1,null,3]")
  assert_eq(csv_run("a\n1.5\n\t\n", options=w1), "a:f64=[1.5,null]")
  assert_eq(csv_run("a\n1\n\" \"\n", options=w1), "a:i64=[1,null]")
  // not for the other types; other white space is not blank
  assert_eq(
    csv_run("a\ntrue\n \n", options=w1),
    "ParseError: could not parse ` ` as dtype `bool` at column 'a' (column number 1) at line 3",
  )
  assert_eq(
    csv_run("a\n \n", options=csv_ov("a", @pl.DataType::Boolean)),
    "ParseError: could not parse ` ` as dtype `bool` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n\t\n", options=csv_ov("a", @pl.DataType::Date)),
    "ParseError: could not parse `\t` as dtype `date` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n\"  \"\n", options=csv_ov("a", @pl.DataType::Datetime)),
    "ParseError: could not parse `\"  \"` as dtype `datetime[μs]` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n \t\n", options=csv_ov("a", @pl.DataType::String)),
    "a:str=[' \t']",
  )
  assert_eq(
    csv_run("a\n\u{A0}\n", options=csv_ov("a", @pl.DataType::Int64)),
    "ParseError: could not parse `\u{A0}` as dtype `i64` at column 'a' (column number 1) at line 2",
  )
  assert_eq(
    csv_run("a\n\u{2003}\n", options=csv_ov("a", @pl.DataType::Float64)),
    "ParseError: could not parse `\u{2003}` as dtype `f64` at column 'a' (column number 1) at line 2",
  )
  // inference: a blank text is a string
  assert_eq(csv_run("a\n \n1\n"), "a:str=[' ','1']")
  assert_eq(csv_run("a\n\"\t\"\n1\n"), "a:str=['\t','1']")
  // trailing blanks after a number are still an error
  assert_eq(
    csv_run("a\n1\n1 \n", options=csv_ov("a", @pl.DataType::Int64)),
    "ParseError: could not parse `1 ` as dtype `i64` at column 'a' (column number 1) at line 3",
  )
  // all-blank column
  assert_eq(
    csv_run("a\n \n \n", options=csv_ov("a", @pl.DataType::Float64)),
    "a:f64=[null,null]",
  )
}

///|
test "csv read: n_rows = 0 reads the inference window and raises nothing" {
  let n0 = @pl.CsvReadOptions::new(n_rows=0)
  // a long row, a bad quote, a value of another type: nothing is raised
  assert_eq(csv_run("a\n1\n2,3\n", options=n0), "a:i64=[]")
  assert_eq(csv_run("a,b\n1,2\n3,4,5\n", options=n0), "a:i64=[] b:i64=[]")
  assert_eq(
    csv_run(
      "a\n1\n2,3\n",
      options=@pl.CsvReadOptions::new(n_rows=0, infer_schema_length=None),
    ),
    "a:i64=[]",
  )
  assert_eq(
    csv_run(
      "a\n1\n\"x\"y\n",
      options=@pl.CsvReadOptions::new(n_rows=0, infer_schema_length=Some(1)),
    ),
    "a:i64=[]",
  )
  // the types come from the first infer_schema_length records
  assert_eq(
    csv_run(
      "a\n1\nx\n",
      options=@pl.CsvReadOptions::new(n_rows=0, infer_schema_length=Some(1)),
    ),
    "a:i64=[]",
  )
  assert_eq(
    csv_run(
      "a\n1\nx\n",
      options=@pl.CsvReadOptions::new(n_rows=0, infer_schema_length=Some(2)),
    ),
    "a:str=[]",
  )
  assert_eq(
    csv_run(
      "a\n1\n2.5\n",
      options=@pl.CsvReadOptions::new(n_rows=0, infer_schema_length=Some(1)),
    ),
    "a:i64=[]",
  )
  assert_eq(
    csv_run(
      "a\nx\n1\n",
      options=@pl.CsvReadOptions::new(n_rows=0, infer_schema_length=Some(1)),
    ),
    "a:str=[]",
  )
  // a malformed record is inferred with the others (here b is a string)
  assert_eq(csv_run("a,b\n1,2\n3,4,5\n6,x\n", options=n0), "a:i64=[] b:str=[]")
  // an override is not read at all
  assert_eq(
    csv_run(
      "a\n1\nx\n",
      options=@pl.CsvReadOptions::new(
        n_rows=0,
        schema_overrides=Map::from_array([("a", @pl.DataType::Int64)]),
      ),
    ),
    "a:i64=[]",
  )
  // n_rows = 1 still reads the inference window (100 records by default)
  assert_eq(
    csv_run("a,b\n1,2\n3,4\n5,6,7\n", options=@pl.CsvReadOptions::new(n_rows=1)),
    "ParseError: found more fields than defined in 'Schema' at line 4",
  )
  // no header
  assert_eq(
    csv_run(
      "a,b\n\n1,2,3\n",
      options=@pl.CsvReadOptions::new(has_header=false, n_rows=0),
    ),
    "column_0:str=[] column_1:str=[] column_2:i64=[]",
  )
}

///|
test "csv read: blank lines before the first record are not skipped rows" {
  let s1 = @pl.CsvReadOptions::new(skip_rows=1)
  let s2 = @pl.CsvReadOptions::new(skip_rows=2)
  assert_eq(csv_run("\na,b\n1,2\n3,4\n", options=s1), "1:i64=[3] 2:i64=[4]")
  assert_eq(csv_run("\n\na,b\n1,2\n3,4\n", options=s1), "1:i64=[3] 2:i64=[4]")
  assert_eq(csv_run("\na,b\n1,2\n3,4\n", options=s2), "3:str=[] 4:str=[]")
  assert_eq(
    csv_run("\nx\na,b\n1,2\n3,4\n", options=s1),
    "a:i64=[1,3] b:i64=[2,4]",
  )
  assert_eq(csv_run("\nx\na,b\n1,2\n3,4\n", options=s2), "1:i64=[3] 2:i64=[4]")
  assert_eq(csv_run("\n\nx\ny\na,b\n1,2\n", options=s2), "a:i64=[1] b:i64=[2]")
  assert_eq(csv_run("\r\na,b\r\n1,2\r\n", options=s1), "1:str=[] 2:str=[]")
  assert_eq(
    csv_run("\n\"x\ny\"\na,b\n1,2\n", options=s1),
    "a:i64=[1] b:i64=[2]",
  )
  assert_eq(csv_run("\n\"x\ny\"\na,b\n1,2\n", options=s2), "1:str=[] 2:str=[]")
  assert_eq(csv_run("\n\n", options=s1), "ParseError: empty CSV")
  assert_eq(
    csv_run("\na,b\n1,2\n", options=@pl.CsvReadOptions::new(skip_rows=3)),
    "ParseError: empty CSV",
  )
  // a blank line right after the skipped records is the header (polars does the same)
  assert_eq(
    csv_run("x\n\na,b\n1,2\n", options=s1),
    "ParseError: found more fields than defined in 'Schema' at line 3",
  )
  assert_eq(csv_run("x\n\na,b\n1,2\n", options=s2), "a:i64=[1] b:i64=[2]")
  assert_eq(csv_run("x\n\na\n1\n", options=s1), ":str=['a','1']")
  // line numbers count the blank lines
  assert_eq(
    csv_run(
      "\n\njunk\na\nx\n",
      options=@pl.CsvReadOptions::new(
        skip_rows=1,
        schema_overrides=Map::from_array([("a", @pl.DataType::Int64)]),
      ),
    ),
    "ParseError: could not parse `x` as dtype `i64` at column 'a' (column number 1) at line 5",
  )
  // without a header every record is data: the blank line is skipped
  assert_eq(
    csv_run(
      "\na,b\n1,2\n",
      options=@pl.CsvReadOptions::new(has_header=false, skip_rows=1),
    ),
    "column_0:str=['a','1'] column_1:str=['b','2']",
  )
  assert_eq(
    csv_run(
      "\na,b\n1,2\n",
      options=@pl.CsvReadOptions::new(has_header=false, skip_rows=2),
    ),
    "column_0:i64=[1] column_1:i64=[2]",
  )
}

///|
test "csv read: line number after a CRLF record that ends with a quoted field" {
  let i64 = @pl.CsvReadOptions::new(
    schema_overrides=Map::from_array([("a", @pl.DataType::Int64)]),
  )
  assert_eq(
    csv_run("a,b\r\n1,\"x\"\r\ny,2\r\n", options=i64),
    "ParseError: could not parse `y` as dtype `i64` at column 'a' (column number 1) at line 3",
  )
  assert_eq(
    csv_run("a,b\r\n1,\"x\"\r\n2,\"p\r\nq\"\r\ny,2\r\n", options=i64),
    "ParseError: could not parse `y` as dtype `i64` at column 'a' (column number 1) at line 5",
  )
  // an LF after the closing quote
  assert_eq(
    csv_run("a,b\n1,\"x\"\ny,2\n", options=i64),
    "ParseError: could not parse `y` as dtype `i64` at column 'a' (column number 1) at line 3",
  )
  // and at the end of the text the CR is dropped
  assert_eq(csv_run("a,b\r\n1,\"x\"\r"), "a:i64=[1] b:str=['x']")
}

///|
test "csv read: small ints, an int beyond Int64 and a float make a String column" {
  // polars: String (a big integer and a float alone give Float64, see
  // csv_read_edge_test.mbt)
  assert_eq(
    csv_run("a\n1\n9223372036854775808\n1.5\n"),
    "a:str=['1','9223372036854775808','1.5']",
  )
  assert_eq(
    csv_run("a\n1.5\n1\n9223372036854775808\n"),
    "a:str=['1.5','1','9223372036854775808']",
  )
}

///|
test "csv read: a malformed record is inferred like any other" {
  let nf = "found more fields than defined in 'Schema'"
  // the fields of a long row (before the extra ones) are read for the inference
  assert_eq(csv_run("a\n-5\n1.5,x\n"), "ParseError: \{nf} at line 3")
  assert_eq(csv_run("a,b\n1,2\nz,5,y\n"), "ParseError: \{nf} at line 3")
  // so are the records after it, inside the window
  assert_eq(
    csv_run(
      "a\n1\n1.5,x\n-7\n",
      options=@pl.CsvReadOptions::new(infer_schema_length=Some(2)),
    ),
    "ParseError: \{nf} at line 3",
  )
  // outside the window the column keeps its type, and the value error of the
  // record comes first
  assert_eq(
    csv_run(
      "a\n1\n1.5,x\n-7\n",
      options=@pl.CsvReadOptions::new(infer_schema_length=Some(1)),
    ),
    "ParseError: could not parse `1.5` as dtype `i64` at column 'a' (column number 1) at line 3",
  )
  // a wrong quote: its field is a string in the inference, and the error names
  // the type of the column
  assert_eq(
    csv_run(
      "a,b\nfalse,0.1\n   \t ,\"x\"y\nTrue,\"ab\"cd\n",
      options=csv_ov("b", @pl.DataType::Float32),
    ),
    "ParseError: could not parse `\"x\"y` as dtype `f32` at column 'b' (column number 2) at line 3",
  )
  assert_eq(
    csv_run(
      "a\n1\n\"x\"y\n2.5\n",
      options=@pl.CsvReadOptions::new(infer_schema_length=Some(3)),
    ),
    "ParseError: could not parse `\"x\"y` as dtype `str` at column 'a' (column number 1) at line 3",
  )
  // a quote that never closes names the type of the column too
  assert_eq(
    csv_run(
      "a,b,c\n-5,007,NaNa\n ,\"x,NA",
      options=@pl.CsvReadOptions::new(infer_schema_length=Some(1)),
    ),
    "ParseError: could not parse `\"x,NA` as dtype `i64` at column 'b' (column number 2) at line 3",
  )
  // n_rows = 0: the types come from the window with the malformed records
  let n0 = @pl.CsvReadOptions::new(n_rows=0)
  assert_eq(csv_run("a,b\n\"x\"y,false\n", options=n0), "a:str=[] b:bool=[]")
  assert_eq(csv_run("a\n1\n\"x\n", options=n0), "a:str=[]")
  assert_eq(
    csv_run(
      "a,b,c\n\"x\",007,2000-02-29,x\n",
      options=@pl.CsvReadOptions::new(n_rows=0, try_parse_dates=true),
    ),
    "a:str=[] b:i64=[] c:date=[]",
  )
  assert_eq(csv_run("a,b\n1,2\n3,4,5\nx,y\n", options=n0), "a:str=[] b:str=[]")
  assert_eq(
    csv_run(
      "a,b\n1,2\n3,4,5\nx,y\n",
      options=@pl.CsvReadOptions::new(n_rows=0, infer_schema_length=Some(2)),
    ),
    "a:i64=[] b:i64=[]",
  )
  assert_eq(
    csv_run(
      "a,b\n1,2\n3,4,5\nx,y\n",
      options=@pl.CsvReadOptions::new(n_rows=0, infer_schema_length=Some(3)),
    ),
    "a:str=[] b:str=[]",
  )
  // no header: a malformed first record gives the width, the type is the
  // override's
  assert_eq(
    csv_run(
      "007,\"x\"y\n",
      options=@pl.CsvReadOptions::new(
        has_header=false,
        schema_overrides=Map::from_array([("column_1", @pl.DataType::Int64)]),
      ),
    ),
    "ParseError: could not parse `\"x\"y` as dtype `i64` at column 'column_1' (column number 2) at line 1",
  )
  // a quote that never closes in a skipped record is skipped
  assert_eq(
    csv_run("\u{FEFF}a\n\"x\r\n", options=@pl.CsvReadOptions::new(skip_rows=2)),
    "ParseError: empty CSV",
  )
}
