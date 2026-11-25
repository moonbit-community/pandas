///|
/// A frame from series known to be valid.
fn csvw_frame(cols : Array[@pl.Series]) -> @pl.DataFrame {
  must(() => @pl.DataFrame::new(cols))
}

///|
/// `write_csv_str` with the options given as labelled arguments of
/// `CsvWriteOptions::new`.
fn csvw(
  df : @pl.DataFrame,
  include_header~ : Bool = true,
  separator~ : Char = ',',
  line_terminator~ : String = "\n",
  quote_char~ : Char = '"',
  quote_style~ : @pl.QuoteStyle = Necessary,
  null_value~ : String = "",
  include_bom~ : Bool = false,
) -> String {
  must(() => {
    @pl.write_csv_str(
      df,
      options=@pl.CsvWriteOptions::new(
        include_header~,
        separator~,
        line_terminator~,
        quote_char~,
        quote_style~,
        null_value~,
        include_bom~,
      ),
    )
  })
}

///|
/// The frame `s,i,f,b,d` with s = `x`, `a,b`, empty string, null,
/// `1`, `-2.5`, `a"b`, ` lead`.
fn csvw_style_frame() -> @pl.DataFrame {
  csvw_frame([
    @pl.Series::str_nullable("s", [
      Some("x"),
      Some("a,b"),
      Some(""),
      None,
      Some("1"),
      Some("-2.5"),
      Some("a\"b"),
      Some(" lead"),
    ]),
    @pl.Series::int64_nullable("i", [
      Some(1L),
      None,
      Some(-3L),
      Some(4L),
      Some(5L),
      Some(6L),
      Some(7L),
      Some(8L),
    ]),
    @pl.Series::float64_nullable("f", [
      Some(1.5),
      Some(0.0 / 0.0),
      Some(1.0 / 0.0),
      Some(-1.0 / 0.0),
      None,
      Some(1.0e20),
      Some(-0.0),
      Some(0.1),
    ]),
    @pl.Series::bool_nullable("b", [
      Some(true),
      Some(false),
      None,
      Some(true),
      Some(true),
      Some(true),
      Some(true),
      Some(true),
    ]),
    @pl.Series::date_nullable("d", [
      Some(0),
      Some(19724),
      None,
      Some(1),
      Some(2),
      Some(3),
      Some(4),
      Some(5),
    ]),
  ])
}

///|
test "quote_style necessary: only fields that need it are quoted" {
  assert_eq(
    csvw(csvw_style_frame()),
    "s,i,f,b,d\n" +
    "x,1,1.5,true,1970-01-01\n" +
    "\"a,b\",,NaN,false,2024-01-02\n" +
    "\"\",-3,inf,,\n" +
    ",4,-inf,true,1970-01-02\n" +
    "1,5,,true,1970-01-03\n" +
    "-2.5,6,1e+20,true,1970-01-04\n" +
    "\"a\"\"b\",7,-0.0,true,1970-01-05\n" +
    " lead,8,0.1,true,1970-01-06\n",
  )
}

///|
test "quote_style always: everything is quoted, null is quote + null_value + quote" {
  let out = csvw(csvw_style_frame(), quote_style=Always)
  assert_eq(
    out,
    "\"s\",\"i\",\"f\",\"b\",\"d\"\n" +
    "\"x\",\"1\",\"1.5\",\"true\",\"1970-01-01\"\n" +
    "\"a,b\",\"\",\"NaN\",\"false\",\"2024-01-02\"\n" +
    "\"\",\"-3\",\"inf\",\"\",\"\"\n" +
    "\"\",\"4\",\"-inf\",\"true\",\"1970-01-02\"\n" +
    "\"1\",\"5\",\"\",\"true\",\"1970-01-03\"\n" +
    "\"-2.5\",\"6\",\"1e+20\",\"true\",\"1970-01-04\"\n" +
    "\"a\"\"b\",\"7\",\"-0.0\",\"true\",\"1970-01-05\"\n" +
    "\" lead\",\"8\",\"0.1\",\"true\",\"1970-01-06\"\n",
  )
  let na = csvw(csvw_style_frame(), quote_style=Always, null_value="NA")
  assert_true(na.contains("\"a,b\",\"NA\",\"NaN\""))
  assert_true(na.contains("\"\",\"-3\",\"inf\",\"NA\",\"NA\"\n"))
}

///|
test "quote_style non_numeric: strings, bools, dates and header quoted; numbers and null not" {
  assert_eq(
    csvw(csvw_style_frame(), quote_style=NonNumeric),
    "\"s\",\"i\",\"f\",\"b\",\"d\"\n" +
    "\"x\",1,1.5,\"true\",\"1970-01-01\"\n" +
    "\"a,b\",,NaN,\"false\",\"2024-01-02\"\n" +
    "\"\",-3,inf,,\n" +
    ",4,-inf,\"true\",\"1970-01-02\"\n" +
    "\"1\",5,,\"true\",\"1970-01-03\"\n" +
    "\"-2.5\",6,1e+20,\"true\",\"1970-01-04\"\n" +
    "\"a\"\"b\",7,-0.0,\"true\",\"1970-01-05\"\n" +
    "\" lead\",8,0.1,\"true\",\"1970-01-06\"\n",
  )
  // a null string is empty and unquoted, also with a null_value
  let na = csvw(csvw_style_frame(), quote_style=NonNumeric, null_value="NA")
  assert_true(na.contains("\nNA,4,-inf,\"true\",\"1970-01-02\"\n"))
  assert_true(na.contains("\"\",-3,inf,NA,NA\n"))
}

///|
test "quote_style never: nothing is quoted, even when it corrupts the row" {
  let df = csvw_frame([@pl.Series::str("a,b", ["x,y", "p\"q", "l1\nl2", ""])])
  assert_eq(csvw(df, quote_style=Never), "a,b\nx,y\np\"q\nl1\nl2\n\n")
  assert_eq(
    csvw(df, quote_style=Never, include_header=false),
    "x,y\np\"q\nl1\nl2\n\n",
  )
}

///|
test "necessary: separator, quote, LF and CR trigger quoting; terminator text does not" {
  let df = csvw_frame([
    @pl.Series::str("a", [
      "x;y", "q\"", "l\nm", "l\rm", "l\r\nm", "tab\there", "#hash", "NA", "null",
      "\u{A0}", " ", "a,b",
    ]),
  ])
  assert_eq(
    csvw(df, separator=';'),
    "a\n\"x;y\"\n\"q\"\"\"\n\"l\nm\"\n\"l\rm\"\n\"l\r\nm\"\ntab\there\n#hash\nNA\nnull\n\u{A0}\n \na,b\n",
  )
  // a line terminator text inside a value is not a reason to quote
  let t = csvw_frame([@pl.Series::str("a", ["x;;y"])])
  assert_eq(csvw(t, line_terminator=";;"), "a;;x;;y;;")
}

///|
test "header names follow the same quoting rule" {
  let df = csvw_frame([
    @pl.Series::int32("a,b", [1]),
    @pl.Series::int32("c\"d", [2]),
    @pl.Series::int32("e f", [3]),
    @pl.Series::int32(" g", [4]),
    @pl.Series::int32("", [5]),
    @pl.Series::int32("h\ni", [6]),
  ])
  assert_eq(csvw(df), "\"a,b\",\"c\"\"d\",e f, g,\"\",\"h\ni\"\n1,2,3,4,5,6\n")
  assert_eq(
    csvw(df, include_header=false, quote_style=Always),
    "\"1\",\"2\",\"3\",\"4\",\"5\",\"6\"\n",
  )
}

///|
test "Float64 text is polars' (positional in [1e-5, 1e16), else scientific)" {
  let xs : Array[Double] = [
    1.0,
    0.1,
    -0.0,
    0.0,
    1.0e20,
    1.0e21,
    1.0e15,
    1.0e16,
    1.2345678901234568e17,
    0.00001,
    1.0e-6,
    9.99e-6,
    1.0e-7,
    1.5e-10,
    5.0e-324,
    1.7976931348623157e308,
    0.30000000000000004,
    123456780000000.0,
    0.000025,
    0.0000100001,
    9999999999999998.0,
    0.0 / 0.0,
    1.0 / 0.0,
    -1.0 / 0.0,
    -2.5,
  ]
  let out = csvw(csvw_frame([@pl.Series::float64("x", xs)]))
  assert_eq(
    out, "x\n1.0\n0.1\n-0.0\n0.0\n1e+20\n1e+21\n1000000000000000.0\n1e+16\n1.2345678901234568e+17\n0.00001\n1e-6\n9.99e-6\n1e-7\n1.5e-10\n5e-324\n1.7976931348623157e+308\n0.30000000000000004\n123456780000000.0\n0.000025\n0.0000100001\n9999999999999998.0\nNaN\ninf\n-inf\n-2.5\n",
  )
}

///|
test "Float32 text is polars' (positional in [1e-6, 1e13))" {
  let xs : Array[Float] = [
    0.1, 0.000001, 0.0000015, 9.99e-7, 1.0e-7, 1.0e10, 1.0e12, 1.0e13, 1.0e15, 3.4028235e38,
    123456789.0, 123456.79, 1.1754944e-38, -0.0, 0.0,
  ]
  let out = csvw(csvw_frame([@pl.Series::float32("x", xs)]))
  assert_eq(
    out, "x\n0.1\n0.000001\n0.0000015\n9.99e-7\n1e-7\n10000000000.0\n1000000000000.0\n1e+13\n1e+15\n3.4028235e+38\n123456790.0\n123456.79\n1.1754944e-38\n-0.0\n0.0\n",
  )
  let nan = csvw(
    csvw_frame([
      @pl.Series::float32("x", [Float::from_double(0.0 / 0.0)]),
      @pl.Series::float32("y", [Float::from_double(-1.0 / 0.0)]),
    ]),
    quote_style=NonNumeric,
  )
  assert_eq(nan, "\"x\",\"y\"\nNaN,-inf\n")
}

///|
test "Int32 and Int64 text, extremes included" {
  let df = csvw_frame([
    @pl.Series::int32("a", [-2147483648, 2147483647, 0]),
    @pl.Series::int64("b", [@int64.MIN_VALUE, @int64.MAX_VALUE, 0L]),
  ])
  assert_eq(
    csvw(df),
    "a,b\n-2147483648,-9223372036854775808\n2147483647,9223372036854775807\n0,0\n",
  )
}

///|
test "Date text: years above 9999 get +, negative years -, year 1 is padded" {
  // 2932896 is 9999-12-31, 2932897 is +10000-01-01
  let df = csvw_frame([
    @pl.Series::date("d", [
      0, -1, 19724, 2932896, 2932897, 3_000_000, -719162, -719528, -800000,
    ]),
  ])
  let out = csvw(df)
  assert_eq(
    out, "d\n1970-01-01\n1969-12-31\n2024-01-02\n9999-12-31\n+10000-01-01\n+10183-09-21\n0001-01-01\n0000-01-01\n-0221-09-04\n",
  )
}

///|
test "Datetime text: T separator and six digits, floor division before 1970" {
  let df = csvw_frame([
    @pl.Series::datetime("t", [
      0L, 1_704_164_645_000_000L, 1_704_164_645_123_456L, -1_500_000L, -1L, 86_399_999_999L,
      253_402_300_800_000_000L,
    ]),
  ])
  assert_eq(
    csvw(df),
    "t\n1970-01-01T00:00:00.000000\n2024-01-02T03:04:05.000000\n2024-01-02T03:04:05.123456\n1969-12-31T23:59:58.500000\n1969-12-31T23:59:59.999999\n1970-01-01T23:59:59.999999\n+10000-01-01T00:00:00.000000\n",
  )
  // the whole Int64 range formats without trapping
  let ext = csvw_frame([
    @pl.Series::datetime("t", [@int64.MIN_VALUE, @int64.MAX_VALUE]),
  ])
  assert_eq(
    csvw(ext),
    "t\n-290308-12-21T19:59:05.224192\n+294247-01-10T04:00:54.775807\n",
  )
}

///|
test "Datetime under quote_style non_numeric is quoted, null is not" {
  let df = csvw_frame([@pl.Series::datetime_nullable("t", [Some(0L), None])])
  assert_eq(
    csvw(df, quote_style=NonNumeric),
    "\"t\"\n\"1970-01-01T00:00:00.000000\"\n\n",
  )
}

///|
test "Null type column: an empty field per row, or the null_value" {
  let df = csvw_frame([@pl.Series::null("n", 2), @pl.Series::int32("m", [1, 2])])
  assert_eq(csvw(df), "n,m\n,1\n,2\n")
  assert_eq(csvw(df, null_value="NA"), "n,m\nNA,1\nNA,2\n")
  assert_eq(
    csvw(df, quote_style=Always),
    "\"n\",\"m\"\n\"\",\"1\"\n\"\",\"2\"\n",
  )
  assert_eq(
    csvw(df, quote_style=Always, null_value="NA"),
    "\"n\",\"m\"\n\"NA\",\"1\"\n\"NA\",\"2\"\n",
  )
  // non_numeric: null is not quoted
  let only = csvw_frame([@pl.Series::null("n", 2)])
  assert_eq(csvw(only, quote_style=NonNumeric), "\"n\"\n\n\n")
}

///|
test "null_value is written raw (not quoted, not escaped) unless Always" {
  let df = csvw_frame([
    @pl.Series::str_nullable("a", [Some("x,y"), None, Some(""), Some("it's")]),
    @pl.Series::int64_nullable("b", [Some(1L), None, Some(3L), Some(4L)]),
  ])
  assert_eq(csvw(df), "a,b\n\"x,y\",1\n,\n\"\",3\nit's,4\n")
  assert_eq(
    csvw(df, null_value="x,y"),
    "a,b\n\"x,y\",1\nx,y,x,y\n\"\",3\nit's,4\n",
  )
  assert_eq(
    csvw(df, null_value="a\"b"),
    "a,b\n\"x,y\",1\na\"b,a\"b\n\"\",3\nit's,4\n",
  )
  assert_eq(
    csvw(df, quote_style=NonNumeric, null_value="NA"),
    "\"a\",\"b\"\n\"x,y\",1\nNA,NA\n\"\",3\n\"it's\",4\n",
  )
}

///|
test "shapes: zero rows, zero columns, one null cell" {
  let empty_rows = csvw_frame([
    @pl.Series::int64("a", []),
    @pl.Series::str("b", []),
  ])
  assert_eq(csvw(empty_rows), "a,b\n")
  assert_eq(csvw(empty_rows, include_header=false), "")
  assert_eq(csvw(empty_rows, quote_style=Always), "\"a\",\"b\"\n")
  assert_eq(csvw(@pl.DataFrame::empty()), "\n")
  assert_eq(csvw(@pl.DataFrame::empty(), include_header=false), "")
  assert_eq(csvw(@pl.DataFrame::empty(), line_terminator="\r\n"), "\r\n")
  assert_eq(csvw(@pl.DataFrame::empty(), quote_style=Always), "\n")
  // a frame whose columns were all selected away keeps its height but has no
  // columns: still a single empty line
  let none = must(() => {
    csvw_frame([@pl.Series::int32("a", [1, 2, 3])]).select([])
  })
  assert_eq(csvw(none), "\n")
  // one column
  let one = csvw_frame([@pl.Series::str_nullable("a", [None])])
  assert_eq(csvw(one), "a\n\n")
  let two = csvw_frame([@pl.Series::str_nullable("a", [None, None])])
  assert_eq(csvw(two), "a\n\n\n")
  let both = csvw_frame([
    @pl.Series::str_nullable("a", [None]),
    @pl.Series::str_nullable("b", [None]),
  ])
  assert_eq(csvw(both), "a,b\n,\n")
  let blank = csvw_frame([@pl.Series::str("a", [""])])
  assert_eq(csvw(blank), "a\n\"\"\n")
}

///|
test "line_terminator ends every line, header and last row included" {
  let df = csvw_frame([@pl.Series::int32("a", [1, 2])])
  assert_eq(csvw(df, line_terminator="\r\n"), "a\r\n1\r\n2\r\n")
  assert_eq(csvw(df, line_terminator="\r"), "a\r1\r2\r")
  assert_eq(csvw(df, line_terminator=""), "a12")
  assert_eq(csvw(df, line_terminator="", include_header=false), "12")
  assert_eq(csvw(df, line_terminator=";;"), "a;;1;;2;;")
  let two = csvw_frame([
    @pl.Series::str("a", ["x"]),
    @pl.Series::str("b", ["y"]),
  ])
  assert_eq(csvw(two, separator=';', line_terminator=";;"), "a;b;;x;y;;")
}

///|
test "include_bom puts U+FEFF first, also before an empty output" {
  let df = csvw_frame([@pl.Series::int32("a", [1])])
  assert_eq(csvw(df, include_bom=true), "\u{FEFF}a\n1\n")
  assert_eq(csvw(df, include_bom=true, include_header=false), "\u{FEFF}1\n")
  assert_eq(csvw(@pl.DataFrame::empty(), include_bom=true), "\u{FEFF}\n")
  assert_eq(
    csvw(@pl.DataFrame::empty(), include_bom=true, include_header=false),
    "\u{FEFF}",
  )
  let rows0 = csvw_frame([@pl.Series::int64("a", [])])
  assert_eq(csvw(rows0, include_bom=true, include_header=false), "\u{FEFF}")
  assert_eq(csvw(rows0, include_bom=true), "\u{FEFF}a\n")
  assert_eq(csvw(df), "a\n1\n")
}

///|
test "separator and quote_char options" {
  let df = csvw_frame([
    @pl.Series::str("a", ["x,y", "it's", "p;q", "t\tu", "a b"]),
    @pl.Series::int32("b", [1, 2, 3, 4, 5]),
  ])
  assert_eq(
    csvw(df, separator=';'),
    "a;b\nx,y;1\nit's;2\n\"p;q\";3\nt\tu;4\na b;5\n",
  )
  assert_eq(
    csvw(df, separator='\t'),
    "a\tb\nx,y\t1\nit's\t2\np;q\t3\n\"t\tu\"\t4\na b\t5\n",
  )
  assert_eq(
    csvw(df, separator=' '),
    "a b\nx,y 1\nit's 2\np;q 3\nt\tu 4\n\"a b\" 5\n",
  )
  assert_eq(
    csvw(df, quote_char='\''),
    "a,b\n'x,y',1\n'it''s',2\np;q,3\nt\tu,4\na b,5\n",
  )
  // the default quote char is no longer special
  let q = csvw_frame([@pl.Series::str("a", ["q\"r", "q'r"])])
  assert_eq(csvw(q, quote_char='\''), "a\nq\"r\n'q''r'\n")
  assert_eq(
    csvw(q, quote_char='\'', quote_style=Always),
    "'a'\n'q\"r'\n'q''r'\n",
  )
  // a separator that is a letter is still only special inside fields
  let l = csvw_frame([
    @pl.Series::str("a", ["pax", "pq"]),
    @pl.Series::str("b", ["1", "2"]),
  ])
  assert_eq(csvw(l, separator='x'), "axb\n\"pax\"x1\npqx2\n")
}

///|
test "non-ASCII and supplementary-plane separator and quote characters" {
  let df = csvw_frame([
    @pl.Series::str("a", [
      "x|y", "x\u{1F600}y", "x\u{1F601}y", "\u{E9}", "x\u{E9}y",
    ]),
    @pl.Series::str("b", ["1", "2", "3", "4", "5"]),
  ])
  // BMP non-ASCII separator
  assert_eq(
    csvw(df, separator='\u{E9}'),
    "a\u{E9}b\nx|y\u{E9}1\nx\u{1F600}y\u{E9}2\nx\u{1F601}y\u{E9}3\n\"\u{E9}\"\u{E9}4\n\"x\u{E9}y\"\u{E9}5\n",
  )
  // astral separator: only the exact pair triggers quoting
  assert_eq(
    csvw(df, separator='\u{1F600}'),
    "a\u{1F600}b\nx|y\u{1F600}1\n\"x\u{1F600}y\"\u{1F600}2\nx\u{1F601}y\u{1F600}3\n\u{E9}\u{1F600}4\nx\u{E9}y\u{1F600}5\n",
  )
  // astral quote character is doubled
  let q = csvw_frame([
    @pl.Series::str("a", ["a\u{1F600}b", "\u{1F600}", "plain"]),
  ])
  assert_eq(
    csvw(q, quote_char='\u{1F600}'),
    "a\n\u{1F600}a\u{1F600}\u{1F600}b\u{1F600}\n\u{1F600}\u{1F600}\u{1F600}\u{1F600}\nplain\n",
  )
  // the high surrogate of the quote alone does not match
  let h = csvw_frame([@pl.Series::str("a", ["\u{1F601}"])])
  assert_eq(csvw(h, quote_char='\u{1F600}'), "a\n\u{1F601}\n")
}

///|
test "strings keep their text: non-ASCII, emoji, edge spaces" {
  let df = csvw_frame([
    @pl.Series::str("s", [
      "\u{4F60}\u{597D}", "\u{1F600}", " lead", "trail ", "\u{FEFF}x",
    ]),
  ])
  assert_eq(
    csvw(df),
    "s\n\u{4F60}\u{597D}\n\u{1F600}\n lead\ntrail \n\u{FEFF}x\n",
  )
}

///|
test "invalid options raise InvalidOperation" {
  let df = csvw_frame([@pl.Series::int32("a", [1])])
  fn run(sep : Char, quote : Char) -> @pl.PolarsError? {
    raises(() => {
      @pl.write_csv_str(
        df,
        options=@pl.CsvWriteOptions::new(separator=sep, quote_char=quote),
      )
    })
  }

  assert_true(run(',', ',') is Some(@pl.InvalidOperation(_)))
  assert_true(run('\'', '\'') is Some(@pl.InvalidOperation(_)))
  assert_true(run('\n', '"') is Some(@pl.InvalidOperation(_)))
  assert_true(run('\r', '"') is Some(@pl.InvalidOperation(_)))
  assert_true(run(',', '\n') is Some(@pl.InvalidOperation(_)))
  assert_true(run(',', '\r') is Some(@pl.InvalidOperation(_)))
  assert_true(run('\u{1F600}', '\u{1F600}') is Some(@pl.InvalidOperation(_)))
  assert_true(run(';', '"') is None)
  assert_true(run('\t', '\'') is None)
  match run(',', ',') {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(m, "separator and quote_char must differ, got ','")
    _ => fail("expected InvalidOperation")
  }
  match run('\n', '"') {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(m, "separator must not be a line break (LF or CR)")
    _ => fail("expected InvalidOperation")
  }
  match run(',', '\r') {
    Some(@pl.InvalidOperation(m)) =>
      assert_eq(m, "quote_char must not be a line break (LF or CR)")
    _ => fail("expected InvalidOperation")
  }
  // the options are checked even when there is nothing to write
  let e = raises(() => {
    @pl.write_csv_str(
      @pl.DataFrame::empty(),
      options=@pl.CsvWriteOptions::new(separator=',', quote_char=','),
    )
  })
  assert_true(e is Some(@pl.InvalidOperation(_)))
}

///|
test "a Date that cannot be formatted raises ComputeError, like cast to str" {
  let df = csvw_frame([
    @pl.Series::int32("i", [1, 2]),
    @pl.Series::date_nullable("d", [Some(0), Some(110_000_001)]),
  ])
  match raises(() => @pl.write_csv_str(df)) {
    Some(@pl.ComputeError(m)) =>
      assert_eq(
        m, "column \"d\": cannot write Date to CSV: value date(110000001) at index 1 cannot be formatted",
      )
    _ => fail("expected ComputeError")
  }
  let neg = csvw_frame([@pl.Series::date("d", [-110_000_001])])
  assert_true(raises(() => @pl.write_csv_str(neg)) is Some(@pl.ComputeError(_)))
  // the limit itself is fine, and null slots are not looked at
  let ok = csvw_frame([
    @pl.Series::date_nullable("d", [Some(110_000_000), Some(-110_000_000), None]),
  ])
  let lines = csvw(ok).split("\n").collect()
  assert_eq(lines.length(), 5)
  // the same value is what Series::cast reports
  assert_true(
    raises(() => df.get_columns()[1].cast(@pl.DataType::String))
    is Some(@pl.ComputeError(_)),
  )
}

///|
test "default options" {
  let df = csvw_frame([@pl.Series::int32("a", [1])])
  assert_eq(must(() => @pl.write_csv_str(df)), "a\n1\n")
  assert_eq(
    must(() => @pl.write_csv_str(df, options=@pl.CsvWriteOptions::new())),
    "a\n1\n",
  )
}

///|
test "QuoteStyle shows polars' names and compares by value" {
  assert_eq(@pl.QuoteStyle::Necessary.to_string(), "necessary")
  assert_eq(@pl.QuoteStyle::Always.to_string(), "always")
  assert_eq(@pl.QuoteStyle::NonNumeric.to_string(), "non_numeric")
  assert_eq(@pl.QuoteStyle::Never.to_string(), "never")
  assert_eq("\{@pl.QuoteStyle::NonNumeric}", "non_numeric")
  assert_true(@pl.QuoteStyle::Always == @pl.QuoteStyle::Always)
  assert_true(@pl.QuoteStyle::Always != @pl.QuoteStyle::Never)
}

///|
test "a long string column and many rows are written once, in order" {
  let n = 20000
  let df = csvw_frame([
    @pl.Series::int32("i", Array::makei(n, i => i)),
    @pl.Series::str(
      "s",
      Array::makei(n, i => if i % 3 == 0 { "a,\{i}" } else { "v\{i}" }),
    ),
  ])
  let out = csvw(df)
  let lines = out.split("\n").collect()
  assert_eq(lines.length(), n + 2)
  assert_eq(lines[0].to_owned(), "i,s")
  assert_eq(lines[1].to_owned(), "0,\"a,0\"")
  assert_eq(lines[2].to_owned(), "1,v1")
  assert_eq(lines[n].to_owned(), "\{n - 1},v\{n - 1}")
  assert_eq(lines[n + 1].to_owned(), "")
}

///|
/// A string of one UTF-16 code unit (a lone surrogate half when `code` is in
/// U+D800..U+DFFF).
fn csvw_unit(code : Int32) -> String {
  let sb = StringBuilder()
  sb.write_char(Int32::unsafe_to_char(code))
  sb.to_string()
}

///|
/// The two UTF-16 halves of a supplementary-plane character.
fn csvw_halves(c : Char) -> (String, String) {
  let v = c.to_int() - 0x10000
  (csvw_unit(0xD800 + (v >> 10)), csvw_unit(0xDC00 + (v & 0x3FF)))
}

///|
/// Characters at the edges of the UTF-16 split: the last one of the basic
/// plane, the first and the last of the first high-surrogate block, the last
/// one of all.
fn csvw_edge_chars() -> Array[Char] {
  ['\u{FFFF}', '\u{10000}', '\u{103FF}', '\u{10FFFF}']
}

///|
/// Strings that are not `c` but share a half with it or sit next to it.
fn csvw_near_misses(c : Char) -> Array[String] {
  let code = c.to_int()
  let out = [
    Int32::unsafe_to_char(code - 1).to_string(),
    Int32::unsafe_to_char(code - 1024).to_string(),
  ]
  if code < 0x10FFFF {
    out.push(Int32::unsafe_to_char(code + 1).to_string())
  }
  out
}

///|
test "write then read: separators and quotes at the edges of the UTF-16 split" {
  for c in csvw_edge_chars() {
    let cs = c.to_string()
    let near = csvw_near_misses(c)
    let values : Array[String?] = [
      Some("a" + cs + "b"),
      Some("pre" + near[0] + "post"),
      Some(near[1]),
      Some(near[near.length() - 1] + near[0]),
      Some(""),
      None,
      Some(cs),
      Some(cs + cs),
      Some("say \"hi\""),
      Some("\"" + cs + "\""),
      Some("plain"),
    ]
    let df = csvw_frame([
      @pl.Series::str_nullable("s", values),
      @pl.Series::int64("n", Array::makei(values.length(), i => i.to_int64())),
    ])
    let overrides = Map::from_array([
      ("s", @pl.DataType::String),
      ("n", @pl.DataType::Int64),
    ])
    // c as the separator
    let t1 = csvw(df, separator=c)
    let b1 = must(() => {
      @pl.read_csv_str(
        t1,
        options=@pl.CsvReadOptions::new(separator=c, schema_overrides=overrides),
      )
    })
    assert_eq(b1.shape(), (values.length(), 2))
    assert_eq(b1.column("s").to_str_array(), values)
    assert_eq(
      b1.column("n").to_int64_array(),
      Array::makei(values.length(), i => Some(i.to_int64())),
    )
    // only a field that holds c itself is quoted
    assert_true(t1.contains("\"a" + cs + "b\"" + cs + "0\n"))
    assert_true(t1.contains("pre" + near[0] + "post" + cs + "1\n"))
    assert_true(t1.contains("\n" + near[1] + cs + "2\n"))
    // c as the quote character (the separator stays a comma)
    let t2 = csvw(df, quote_char=c)
    let b2 = must(() => {
      @pl.read_csv_str(
        t2,
        options=@pl.CsvReadOptions::new(
          quote_char=Some(c),
          schema_overrides=overrides,
        ),
      )
    })
    assert_eq(b2.shape(), (values.length(), 2))
    assert_eq(b2.column("s").to_str_array(), values)
    // "a" + c + "b" has the quote inside: quoted, with the quote doubled
    assert_true(t2.contains("\n" + cs + "a" + cs + cs + "b" + cs + ",0\n"))
    // near misses are not quotes: written as they are
    assert_true(t2.contains("pre" + near[0] + "post,1\n"))
  }
}

///|
test "write: a string that ends with the first half of a supplementary separator or quote" {
  for c in ['\u{10000}', '\u{103FF}', '\u{10FFFF}', '\u{1F600}'] {
    let cs = c.to_string()
    let (hi, lo) = csvw_halves(c)
    // the last unit of the cell is the first half of c: not c, so no quote
    let df = csvw_frame([
      @pl.Series::str("a", ["x" + hi, "y", lo + "z", hi + "w"]),
      @pl.Series::str("b", ["1", "2", "3", "4"]),
    ])
    assert_eq(
      csvw(df, separator=c),
      "a" +
      cs +
      "b\nx" +
      hi +
      cs +
      "1\ny" +
      cs +
      "2\n" +
      lo +
      "z" +
      cs +
      "3\n" +
      hi +
      "w" +
      cs +
      "4\n",
    )
    // the same at the very end of the output
    let one = csvw_frame([@pl.Series::str("a", ["x" + hi])])
    assert_eq(csvw(one, separator=c, line_terminator=""), "ax" + hi)
    assert_eq(csvw(one, quote_char=c, line_terminator=""), "ax" + hi)
    // as a quote character, with every style that scans the cell
    assert_eq(
      csvw(one, quote_char=c, quote_style=Always, line_terminator=""),
      cs + "a" + cs + cs + "x" + hi + cs,
    )
    assert_eq(
      csvw(one, quote_char=c, quote_style=NonNumeric, line_terminator=""),
      cs + "a" + cs + cs + "x" + hi + cs,
    )
    assert_eq(
      csvw(one, quote_char=c, quote_style=Never, line_terminator=""),
      "ax" + hi,
    )
    // a cell that is c followed by its own first half: quoted
    let two = csvw_frame([@pl.Series::str("a", [cs + hi])])
    assert_eq(
      csvw(two, separator=c, line_terminator=""),
      "a\"" + cs + hi + "\"",
    )
  }
}
