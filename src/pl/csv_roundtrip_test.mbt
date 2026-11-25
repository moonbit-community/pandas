///|
/// Round trips: `write_csv_str` then `read_csv_str`.
///
/// - With `schema_overrides` for every column the table comes back equal
///   (floats bit for bit, `-0.0` included): the quickcheck properties
///   `csv roundtrip prop: ...`.
/// - Without overrides the reader sniffs the types, so some tables come back
///   different. The properties pin what is stable; the example tests pin the
///   rest (strings that look like numbers or booleans, all-null columns).

///|
fn rt_mod(x : Int32, n : Int32) -> Int32 {
  (x % n + n) % n
}

///|
/// A selector in `0..<m` made of some bits of `c`.
fn rt_sel(c : Int64, shift : Int32, m : Int32) -> Int32 {
  ((c >> shift) & 0xFFFFL).to_int() % m
}

///|
let rt_f64_pool : Array[Double] = [
  0.0 / 0.0,
  1.0 / 0.0,
  -1.0 / 0.0,
  -0.0,
  0.0,
  5.0e-324,
  -5.0e-324,
  2.2250738585072014e-308,
  1.7976931348623157e308,
  1.0e16,
  1.0e-5,
  0.1,
  123456789.123456789,
  1.0e21,
  -1.5,
]

///|
let rt_f32_pool : Array[Float] = [
  Float::from_double(0.0 / 0.0),
  Float::from_double(1.0 / 0.0),
  Float::from_double(-1.0 / 0.0),
  Float::from_double(-0.0),
  Float::from_double(0.0),
  Float::from_double(0.1),
  Float::from_double(3.4028234663852886e38),
  Float::from_double(1.0e16),
  Float::from_double(1.0e-5),
  Float::from_double(16777216.0),
  Float::reinterpret_from_int(1),
  Float::reinterpret_from_int(0x007FFFFF),
]

///|
let rt_date_pool : Array[Int32] = [
  0, -1, 19000, -719162, -719163, -719528, -800000, 2932896, 2932897, 3000000, 93999999,
  -93999999, 94000000, -94000000, 11017,
]

///|
/// One row of seeds: three `Int64` and three `Int32` values.
type RtRow = ((Int64, Int64, Int64), (Int32, Int32, Int32))

///|
/// The frame of every dtype (no `Null`) made of the seeds. With `dense`, row 0
/// has no null (so no column is all null) and dates stay in years 1..9999 and
/// datetimes in years 1..9999.
fn rt_frame(rows : Array[RtRow], dense~ : Bool = false) -> @pl.DataFrame {
  let i32s : Array[Int32?] = []
  let i64s : Array[Int64?] = []
  let f64s : Array[Double?] = []
  let f32s : Array[Float?] = []
  let bools : Array[Bool?] = []
  let dates : Array[Int32?] = []
  let dts : Array[Int64?] = []
  for i, row in rows {
    let ((a, b, c), (_, e, f)) = row
    let first = dense && i == 0
    i32s.push(if rt_sel(c, 0, 6) == 0 && !first { None } else { Some(f) })
    i64s.push(if rt_sel(c, 8, 6) == 0 && !first { None } else { Some(a) })
    let k = rt_sel(c, 16, 18)
    f64s.push(
      if k == 0 && !first {
        None
      } else if k <= rt_f64_pool.length() && k > 0 {
        Some(rt_f64_pool[k - 1])
      } else {
        let x = b.reinterpret_as_double()
        // random bit patterns; NaN payloads are not interesting
        Some(x)
      },
    )
    let k = rt_sel(c, 24, 14)
    f32s.push(
      if k == 0 && !first {
        None
      } else if k <= rt_f32_pool.length() && k > 0 {
        Some(rt_f32_pool[k - 1])
      } else {
        Some(Float::reinterpret_from_int(e))
      },
    )
    let k = rt_sel(c, 32, 3)
    bools.push(if k == 0 && !first { None } else { Some(k == 1) })
    let k = rt_sel(c, 40, 20)
    if dense {
      // years 1..9999: 2932896 days after 0001-01-01
      dates.push(
        if first || k != 0 {
          Some(rt_mod(e, 3652059) - 719162)
        } else {
          None
        },
      )
    } else {
      dates.push(
        if k == 0 {
          None
        } else if k <= rt_date_pool.length() {
          Some(rt_date_pool[k - 1])
        } else {
          Some(e % 94000001)
        },
      )
    }
    let k = rt_sel(c, 48, 5)
    if dense {
      // 0001-01-01T00:00:00 is -62135596800 s, 9999-12-31T23:59:59 is
      // 253402300799 s: a span of 315537897600 s.
      let w = 315537897600L
      let secs = (b % w + w) % w - 62135596800L
      let us = secs * 1000000L + rt_mod(e, 1000000).to_int64()
      dts.push(if first || k != 0 { Some(us) } else { None })
    } else {
      dts.push(
        if k == 0 {
          None
        } else if k == 1 {
          Some(b % 100000000000000L)
        } else {
          Some(b % 8000000000000000000L)
        },
      )
    }
  }
  must(() => {
    @pl.DataFrame::new([
      @pl.Series::int32_nullable("i32", i32s),
      @pl.Series::int64_nullable("i 64, x", i64s),
      @pl.Series::float64_nullable("f64", f64s),
      @pl.Series::float32_nullable("f32", f32s),
      @pl.Series::bool_nullable("b", bools),
      @pl.Series::date_nullable("d", dates),
      @pl.Series::datetime_nullable("dt", dts),
    ])
  })
}

///|
/// Overrides that give every column of `df` its own type back (a `Null`
/// column cannot be overridden: it is read as `String`).
fn rt_overrides(df : @pl.DataFrame) -> Map[String, @pl.DataType] {
  let m : Map[String, @pl.DataType] = Map([])
  for p in df.schema() {
    if p.1 != Null {
      m[p.0] = p.1
    }
  }
  m
}

///|
/// Separators, quote characters, terminators, quote styles and BOMs chosen by
/// `sel`. The write and read options agree.
fn rt_options(
  sel : Int32,
  overrides : Map[String, @pl.DataType],
  always~ : Bool = false,
) -> (@pl.CsvWriteOptions, @pl.CsvReadOptions) {
  let seps : Array[Char] = [',', ';', '\t', '|', 'é', '😀', ',', ',']
  let quotes : Array[Char] = ['"', '\'', '`', '"', 'ç', '"']
  // Under Always a null is written as "" (polars does the same), so it is
  // read back as null only with null_values=[""]; that makes every empty
  // string null as well, which is why Always is for frames with no strings.
  let styles : Array[@pl.QuoteStyle] = if always {
    [Necessary, Always, NonNumeric, Always]
  } else {
    [Necessary, NonNumeric, Necessary, NonNumeric]
  }
  let sep = seps[rt_mod(sel, seps.length())]
  let mut quote = quotes[rt_mod(sel / 8, quotes.length())]
  if quote == sep {
    quote = '"'
  }
  if quote == sep {
    quote = '\''
  }
  let style = styles[rt_mod(sel / 48, styles.length())]
  let eol = if rt_mod(sel / 192, 2) == 0 { "\n" } else { "\r\n" }
  let bom = rt_mod(sel / 384, 2) == 1
  (
    @pl.CsvWriteOptions::new(
      separator=sep,
      quote_char=quote,
      quote_style=style,
      line_terminator=eol,
      include_bom=bom,
    ),
    @pl.CsvReadOptions::new(
      separator=sep,
      quote_char=Some(quote),
      schema_overrides=overrides,
      null_values=if style == Always { [""] } else { [] },
    ),
  )
}

///|
/// Fails (with the text and the column) unless `back` is `df`, floats bit for
/// bit.
fn rt_assert_same(
  df : @pl.DataFrame,
  back : @pl.DataFrame,
  text : String,
) -> Unit raise Error {
  if df.columns() != back.columns() {
    fail(
      "columns \{df.columns().join("|")} became \{back.columns().join("|")}\ntext: \{text.escape()}",
    )
  }
  if df.height() != back.height() {
    fail(
      "height \{df.height()} became \{back.height()}\ntext: \{text.escape()}",
    )
  }
  let a = df.get_columns()
  let b = back.get_columns()
  for i in 0..<a.length() {
    if !golden_same(a[i], b[i]) {
      fail(
        "column \{a[i].name()}:\n  \{a[i].dtype()} \{a[i]}\n  \{b[i].dtype()} \{b[i]}\ntext: \{text.escape()}",
      )
    }
  }
}

///|
fn rt_roundtrip(
  df : @pl.DataFrame,
  wo : @pl.CsvWriteOptions,
  ro : @pl.CsvReadOptions,
) -> Unit raise Error {
  let text = @pl.write_csv_str(df, options=wo)
  let back = @pl.read_csv_str(text, options=ro) catch {
    e => fail("\{e}\ntext: \{text.escape()}")
  }
  rt_assert_same(df, back, text)
}

///|
test "csv roundtrip prop: every dtype with overrides, random options" {
  @quickcheck.check(
    (t : (Array[RtRow], Int32)) => {
      let (rows, sel) = t
      let df = rt_frame(rows)
      let (wo, ro) = rt_options(sel, rt_overrides(df), always=true)
      rt_roundtrip(df, wo, ro)
      true
    },
    count=300,
    max_size=40,
  )
}

///|
test "csv roundtrip prop: every dtype with overrides, default options" {
  @quickcheck.check(
    (rows : Array[RtRow]) => {
      let df = rt_frame(rows)
      let ro = @pl.CsvReadOptions::new(schema_overrides=rt_overrides(df))
      rt_roundtrip(df, @pl.CsvWriteOptions::new(), ro)
      true
    },
    count=300,
    max_size=40,
  )
}

///|
/// Fragments of strings that are hard to write and read.
let rt_fragments : Array[String] = [
  ",", "\"", "\n", "\r\n", "\r", " ", "a", "é", "日", "😀", ";", "\t", "|", "'",
  "007", "NaN", "true", "null", "\u{feff}", "\u{0}", "\\", "`", "x y", "\"\"", "\n\n",
  ",,", "NA", "1e5", "-", "2024-01-02",
]

///|
fn rt_string(frags : Array[Int32]) -> String {
  let sb = StringBuilder()
  for f in frags {
    sb.write_string(rt_fragments[rt_mod(f, rt_fragments.length())])
  }
  sb.to_string()
}

///|
/// Three columns: strings made of fragments (null where the flag is set),
/// arbitrary strings (null or not) and an `Int64` (so a row is never blank).
fn rt_string_frame(
  rows : Array[((Bool, Array[Int32]), String?, Int64)],
) -> @pl.DataFrame {
  must(() => {
    @pl.DataFrame::new([
      @pl.Series::str_nullable(
        "frag",
        rows.map(r => if r.0.0 { None } else { Some(rt_string(r.0.1)) }),
      ),
      @pl.Series::str_nullable("arb", rows.map(r => r.1)),
      @pl.Series::int64("n", rows.map(r => r.2)),
    ])
  })
}

///|
test "csv roundtrip prop: strings with separators, quotes, breaks, spaces" {
  @quickcheck.check(
    (t : (Array[((Bool, Array[Int32]), String?, Int64)], Int32)) => {
      let (rows, sel) = t
      let df = rt_string_frame(rows)
      let (wo, ro) = rt_options(sel, rt_overrides(df))
      rt_roundtrip(df, wo, ro)
      true
    },
    count=300,
    max_size=30,
  )
}

///|
test "csv roundtrip prop: one string column, nulls and empty strings" {
  @quickcheck.check(
    (t : (Array[(Bool, Array[Int32])], Int32)) => {
      let (rows, sel) = t
      let df = must(() => {
        @pl.DataFrame::new([
          @pl.Series::str_nullable(
            "s",
            rows.map(r => if r.0 { None } else { Some(rt_string(r.1)) }),
          ),
        ])
      })
      let (wo, ro) = rt_options(sel, rt_overrides(df))
      // A one-column table whose last rows are null ends in blank lines; with
      // zero rows the text is the header only. Both come back.
      rt_roundtrip(df, wo, ro)
      true
    },
    count=300,
    max_size=30,
  )
}

///|
test "csv roundtrip prop: one Int64 column with nulls" {
  @quickcheck.check(
    (rows : Array[Int64?]) => {
      let df = must(() => {
        @pl.DataFrame::new([@pl.Series::int64_nullable("n", rows)])
      })
      let ro = @pl.CsvReadOptions::new(schema_overrides=rt_overrides(df))
      rt_roundtrip(df, @pl.CsvWriteOptions::new(), ro)
      true
    },
    count=300,
    max_size=30,
  )
}

///|
test "csv roundtrip prop: without overrides, the types that survive sniffing" {
  // Int64, Float64 and Boolean come back as they are when the column has a
  // value; a string column whose texts start with a letter is a string column.
  @quickcheck.check(
    (t : (Array[RtRow], Int32)) => {
      let (rows, sel) = t
      let full = rt_frame(rows, dense=true)
      let letters = rows.map(r => {
        let k = rt_sel(r.0.2, 0, 4)
        if k == 0 {
          None
        } else if k == 1 {
          Some("")
        } else {
          Some("x" + rt_string([r.1.0, r.1.1]))
        }
      })
      let df = must(() => {
        @pl.DataFrame::new([
          full.column("i 64, x"),
          full.column("f64"),
          full.column("b"),
          @pl.Series::str_nullable("s", letters),
        ])
      })
      if rows.length() == 0 {
        return true
      }
      let (wo, ro) = rt_options(sel, Map([]))
      rt_roundtrip(df, wo, ro)
      true
    },
    count=300,
    max_size=40,
  )
}

///|
test "csv roundtrip prop: Date and Datetime in years 1..9999 with try_parse_dates" {
  @quickcheck.check(
    (rows : Array[RtRow]) => {
      if rows.length() == 0 {
        return true
      }
      let full = rt_frame(rows, dense=true)
      let df = must(() => {
        @pl.DataFrame::new([full.column("d"), full.column("dt")])
      })
      rt_roundtrip(
        df,
        @pl.CsvWriteOptions::new(),
        @pl.CsvReadOptions::new(try_parse_dates=true),
      )
      true
    },
    count=300,
    max_size=40,
  )
}

///|
test "csv roundtrip prop: floats bit for bit (no override needed)" {
  @quickcheck.check(
    (bits : Array[Int64]) => {
      if bits.length() == 0 {
        return true
      }
      // Finite and infinite values, subnormals included; NaN is covered by
      // the pool tests above.
      let xs = bits.map(b => b.reinterpret_as_double())
      let df = must(() => @pl.DataFrame::new([@pl.Series::float64("x", xs)]))
      let text = @pl.write_csv_str(df)
      let back = @pl.read_csv_str(
        text,
        options=@pl.CsvReadOptions::new(
          schema_overrides=Map::from_array([("x", @pl.DataType::Float64)]),
        ),
      )
      rt_assert_same(df, back, text)
      true
    },
    count=500,
    max_size=40,
  )
}

///|
fn rt_one(s : @pl.Series) -> Unit raise Error {
  let df = @pl.DataFrame::new([s])
  rt_roundtrip(
    df,
    @pl.CsvWriteOptions::new(),
    @pl.CsvReadOptions::new(schema_overrides=rt_overrides(df)),
  )
}

///|
test "csv roundtrip: the special values of every dtype" {
  rt_one(@pl.Series::float64("f", rt_f64_pool))
  rt_one(@pl.Series::float32("g", rt_f32_pool))
  rt_one(@pl.Series::date("d", rt_date_pool))
  rt_one(
    @pl.Series::datetime("t", [
      0L,
      -1L,
      1L,
      -62135596800000000L,
      253402300799999999L,
      253402300800000000L,
      -62135596800000001L,
      -86400000000L * 365L * 100L,
      8000000000000000000L,
      -8000000000000000000L,
      1000000L,
      -1000000L,
      999999L,
      -999999L,
    ]),
  )
  rt_one(
    @pl.Series::int64("i", [
      0L,
      -1L,
      9223372036854775807L,
      -9223372036854775807L - 1L,
    ]),
  )
  rt_one(@pl.Series::int32("i", [0, -1, 2147483647, -2147483648]))
  rt_one(@pl.Series::bool("b", [true, false]))
}

///|
/// The message of the `ParseError` that reading `text` raises, `None` when it
/// reads.
fn rt_parse_error(text : String, ro : @pl.CsvReadOptions) -> String? {
  try {
    @pl.read_csv_str(text, options=ro) |> ignore
    None
  } catch {
    @pl.PolarsError::ParseError(m) => Some(m)
    e => Some("other error: \{e}")
  }
}

///|
/// The reader reads years -262143 to 262142 (the range of `chrono`); the writer
/// writes any date within 110 000 000 days and any Datetime. A value outside
/// the reader's range is written but read back as a `ParseError`.
test "csv roundtrip: dates and datetimes the reader cannot read back" {
  let max_day = match @pl.AnyValue::date_ymd(262142, 12, 31) {
    Date(d) => d
    _ => abort("not a date")
  }
  let min_day = match @pl.AnyValue::date_ymd(-262143, 1, 1) {
    Date(d) => d
    _ => abort("not a date")
  }
  // the edges themselves come back
  rt_one(@pl.Series::date("d", [min_day, max_day]))
  // one day further is written (`+262143-01-01`) and not read
  let text = @pl.write_csv_str(
    @pl.DataFrame::new([@pl.Series::date("d", [max_day + 1])]),
  )
  assert_eq(text, "d\n+262143-01-01\n")
  let ro = @pl.CsvReadOptions::new(
    schema_overrides=Map::from_array([("d", @pl.DataType::Date)]),
  )
  match rt_parse_error(text, ro) {
    Some(m) => assert_true(m.contains("at line 2"))
    None => fail("expected a ParseError")
  }
  // Int64 extremes
  for v in [9223372036854775807L, -9223372036854775807L - 1L] {
    let df = @pl.DataFrame::new([@pl.Series::datetime("t", [v])])
    let text = @pl.write_csv_str(df)
    let ro = @pl.CsvReadOptions::new(
      schema_overrides=Map::from_array([("t", @pl.DataType::Datetime)]),
    )
    match rt_parse_error(text, ro) {
      Some(m) => assert_true(m.contains("at line 2"))
      None => fail("expected a ParseError for \{text.escape()}")
    }
  }
}

///|
/// `csv_run` of the text `write_csv_str` makes of `df`: what a default
/// `read_csv_str` gives back.
fn rt_back(
  df : @pl.DataFrame,
  options~ : @pl.CsvReadOptions = @pl.CsvReadOptions::new(),
) -> String {
  csv_run(must(() => @pl.write_csv_str(df)), options~)
}

///|
fn rt_df(cols : Array[@pl.Series]) -> @pl.DataFrame {
  must(() => @pl.DataFrame::new(cols))
}

///|
/// Tables that read back different: the reader sniffs the types of
/// the text, so a string that looks like a number or a boolean changes type.
test "csv roundtrip without overrides: strings that look like other types" {
  assert_eq(
    rt_back(rt_df([@pl.Series::str("s", ["007", "1", "-5"])])),
    "s:i64=[7,1,-5]",
  )
  assert_eq(
    rt_back(rt_df([@pl.Series::str("s", ["NaN", "1.5"])])),
    "s:f64=[NaN,1.5]",
  )
  assert_eq(
    rt_back(rt_df([@pl.Series::str("s", ["true", "FALSE"])])),
    "s:bool=[true,false]",
  )
  // These stay strings.
  assert_eq(
    rt_back(rt_df([@pl.Series::str("s", ["nan", "inf", "+5", "x"])])),
    "s:str=['nan','inf','+5','x']",
  )
  // One text that is not a number keeps the column a string, "007" included.
  assert_eq(
    rt_back(rt_df([@pl.Series::str("s", ["007", "x"])])),
    "s:str=['007','x']",
  )
  // Overrides bring them back.
  let df = rt_df([@pl.Series::str("s", ["007", "1", "true", "NaN"])])
  assert_eq(
    rt_back(
      df,
      options=@pl.CsvReadOptions::new(
        schema_overrides=Map::from_array([("s", @pl.DataType::String)]),
      ),
    ),
    "s:str=['007','1','true','NaN']",
  )
}

///|
test "csv roundtrip without overrides: the empty string and null stay apart" {
  assert_eq(
    rt_back(rt_df([@pl.Series::str_nullable("s", [Some(""), None, Some("a")])])),
    "s:str=['',null,'a']",
  )
  // a column of only empty strings is a column of empty strings
  assert_eq(
    rt_back(
      rt_df([@pl.Series::str("s", ["", ""]), @pl.Series::int64("n", [1L, 2L])]),
    ),
    "s:str=['',''] n:i64=[1,2]",
  )
  // one empty string makes an integer-looking column a string column
  assert_eq(
    rt_back(rt_df([@pl.Series::str_nullable("s", [Some("1"), Some(""), None])])),
    "s:str=['1','',null]",
  )
}

///|
test "csv roundtrip without overrides: widths, Float32, Date, Datetime" {
  // Int32 comes back Int64, Float32 comes back Float64 (the text is `0.1`).
  assert_eq(rt_back(rt_df([@pl.Series::int32("a", [1, -2])])), "a:i64=[1,-2]")
  assert_eq(
    rt_back(rt_df([@pl.Series::float32("a", [Float::from_double(0.1)])])),
    "a:f64=[0.1]",
  )
  // with a Float32 override the same value comes back exactly
  assert_eq(
    rt_back(
      rt_df([@pl.Series::float32("a", [Float::from_double(0.1)])]),
      options=@pl.CsvReadOptions::new(
        schema_overrides=Map::from_array([("a", @pl.DataType::Float32)]),
      ),
    ),
    "a:f32=[0.1]",
  )
  // Date and Datetime are strings unless try_parse_dates is on (or overridden)
  let dates = rt_df([
    @pl.Series::date("d", [19000, 0]),
    @pl.Series::datetime("t", [1700000000000000L, -1L]),
  ])
  assert_eq(
    rt_back(dates),
    "d:str=['2022-01-08','1970-01-01'] t:str=['2023-11-14T22:13:20.000000','1969-12-31T23:59:59.999999']",
  )
  assert_eq(
    rt_back(dates, options=@pl.CsvReadOptions::new(try_parse_dates=true)),
    "d:date=[d19000,d0] t:datetime[μs]=[t1700000000000000,t-1]",
  )
}

///|
test "csv roundtrip without overrides: null columns, no rows, no columns" {
  // A Null column, and an Int64 column with no value, come back as String
  // columns of nulls; an override restores the Int64 one, but a Null column
  // cannot be overridden.
  let df = rt_df([
    @pl.Series::null("n", 2),
    @pl.Series::int64_nullable("i", [None, None]),
    @pl.Series::int64("k", [1L, 2L]),
  ])
  assert_eq(rt_back(df), "n:str=[null,null] i:str=[null,null] k:i64=[1,2]")
  assert_eq(
    rt_back(
      df,
      options=@pl.CsvReadOptions::new(
        schema_overrides=Map::from_array([("i", @pl.DataType::Int64)]),
      ),
    ),
    "n:str=[null,null] i:i64=[null,null] k:i64=[1,2]",
  )
  assert_eq(
    rt_back(
      df,
      options=@pl.CsvReadOptions::new(
        schema_overrides=Map::from_array([("n", @pl.DataType::Null)]),
      ),
    ),
    "ComputeError: unsupported data type when reading CSV: null when reading CSV",
  )
}

///|
test "csv roundtrip: zero rows, one null column, zero columns" {
  // No rows: the header only; a reader that is told the types gives the frame
  // back, without them every column is a string column.
  let empty = rt_df([@pl.Series::int64("a", []), @pl.Series::str("b", [])])
  assert_eq(rt_back(empty), "a:str=[] b:str=[]")
  rt_roundtrip(
    empty,
    @pl.CsvWriteOptions::new(),
    @pl.CsvReadOptions::new(schema_overrides=rt_overrides(empty)),
  )
  // One column, all null: every row is a blank line.
  let nulls = rt_df([@pl.Series::str_nullable("s", [None, None, None])])
  assert_eq(must(() => @pl.write_csv_str(nulls)), "s\n\n\n\n")
  assert_eq(rt_back(nulls), "s:str=[null,null,null]")
  rt_roundtrip(
    nulls,
    @pl.CsvWriteOptions::new(),
    @pl.CsvReadOptions::new(schema_overrides=rt_overrides(nulls)),
  )
  let ints = rt_df([@pl.Series::int64_nullable("n", [None, Some(1L), None])])
  assert_eq(must(() => @pl.write_csv_str(ints)), "n\n\n1\n\n")
  rt_roundtrip(
    ints,
    @pl.CsvWriteOptions::new(),
    @pl.CsvReadOptions::new(schema_overrides=rt_overrides(ints)),
  )
  // The Null dtype: one column of nulls is a column of blank lines too.
  let nulldf = rt_df([@pl.Series::null("n", 2)])
  assert_eq(rt_back(nulldf), "n:str=[null,null]")
  // No columns: the text is a newline, which is no CSV.
  let nocols = rt_df([])
  assert_eq(must(() => @pl.write_csv_str(nocols)), "\n")
  assert_eq(rt_back(nocols), "ParseError: empty CSV")
}

///|
test "csv roundtrip without header: names are column_0, column_1, ..." {
  let df = rt_df([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::str("b", ["x", "y,z"]),
  ])
  let text = must(() => {
    @pl.write_csv_str(
      df,
      options=@pl.CsvWriteOptions::new(include_header=false),
    )
  })
  assert_eq(text, "1,x\n2,\"y,z\"\n")
  assert_eq(
    csv_run(text, options=@pl.CsvReadOptions::new(has_header=false)),
    "column_0:i64=[1,2] column_1:str=['x','y,z']",
  )
}
