///|
/// Where the tests write: `_fs_test_tmp/<backend>/` relative to the module root
/// (probed: every backend resolves a relative path to the same place, the
/// module root). The backend name comes from `backend_<target>_test.mbt`, a file
/// per backend chosen by `targets` in `moon.pkg`, so two backends that run at
/// the same time never touch the same file.
///
/// Every test starts with `fs_prepare`, which empties the backend's directory
/// (files a failed earlier run left behind are gone) and creates it when it is
/// missing; it ends with `fs_cleanup`, which removes the files the test made,
/// then the backend's directory and `_fs_test_tmp` when they can be removed.
/// `@xfs.remove_dir` fails on a directory that is not empty on native, and is
/// recursive on js, wasm and wasm-gc (there the last cleanup of a run also
/// removes the directories of the other backends that exist at that moment).
/// A failed removal is ignored.
let fs_test_root : String = "_fs_test_tmp"

///|
let fs_test_dir : String = "\{fs_test_root}/\{fs_backend()}"

///|
fn fs_path(name : String) -> String {
  "\{fs_test_dir}/\{name}"
}

///|
/// Removes everything inside the directory `dir` (sub-directories too, deepest
/// first), ignoring failures.
fn fs_empty_dir(dir : String) -> Unit {
  let names : Array[String] = []
  try {
    for name in @xfs.read_dir(dir) {
      names.push(name)
    }
  } catch {
    _ => ()
  }
  for name in names {
    let p = "\{dir}/\{name}"
    let is_directory = @xfs.is_dir(p) catch { _ => false }
    if is_directory {
      fs_empty_dir(p)
      @xfs.remove_dir(p) catch {
        _ => ()
      }
    } else {
      @xfs.remove_file(p) catch {
        _ => ()
      }
    }
  }
}

///|
/// Empties the backend's directory (it may hold what a failed earlier run left).
fn fs_wipe() -> Unit {
  if @xfs.path_exists(fs_test_dir) {
    fs_empty_dir(fs_test_dir)
  }
}

///|
/// Empties and creates `_fs_test_tmp/<backend>`. `create_dir` fails when the
/// directory exists (native) or when another backend creates the root at the
/// same moment, so every failure is ignored and the result is checked; a root
/// that another backend removes between the two calls is created again.
fn fs_prepare() -> Unit raise Error {
  fs_wipe()
  for _ in 0..<5 {
    if @xfs.path_exists(fs_test_dir) {
      return
    }
    if !@xfs.path_exists(fs_test_root) {
      @xfs.create_dir(fs_test_root) catch {
        _ => ()
      }
    }
    @xfs.create_dir(fs_test_dir) catch {
      _ => ()
    }
  }
  if !@xfs.path_exists(fs_test_dir) {
    fail("cannot create \{fs_test_dir}")
  }
}

///|
/// Removes the given files (when they exist), then the backend's directory and
/// `_fs_test_tmp` when they are empty.
fn fs_cleanup(names : Array[String]) -> Unit {
  for name in names {
    let p = fs_path(name)
    if @xfs.path_exists(p) {
      @xfs.remove_file(p) catch {
        _ => ()
      }
    }
  }
  @xfs.remove_dir(fs_test_dir) catch {
    _ => ()
  }
  @xfs.remove_dir(fs_test_root) catch {
    _ => ()
  }
}

///|
/// The error `f` raises; fails when it does not raise.
fn[T] fs_error_of(f : () -> T raise Error) -> Error raise Error {
  let mut r : Error? = None
  try f() |> ignore catch {
    e => r = Some(e)
  }
  match r {
    Some(e) => e
    None => fail("expected an error, got a value")
  }
}

///|
/// Checks that `e` is `@pl.PolarsError::IOError` whose message names `path`
/// and that `to_string()` starts with `IOError: `. The rest of the text is the
/// operating system's and differs between backends.
fn fs_expect_io_error(e : Error, path : String) -> Unit raise Error {
  match e {
    @pl.PolarsError::IOError(msg) => {
      assert_true(msg.contains(path))
      assert_true(msg.length() > path.length())
      assert_true(e.to_string().has_prefix("IOError: "))
      assert_eq(e.to_string(), "IOError: " + msg)
    }
    _ => fail("expected IOError, got \{e}")
  }
}

///|
/// A lone UTF-16 surrogate half as a string (`code` in U+D800..U+DFFF).
fn fs_unit(code : Int32) -> String {
  let sb = StringBuilder()
  sb.write_char(Int32::unsafe_to_char(code))
  sb.to_string()
}

///|
let fs_unpaired_message : String = "cannot write a string with an unpaired surrogate as UTF-8"

///|
/// Checks that `e` is the `ComputeError` of an unpaired surrogate.
fn fs_expect_unpaired(e : Error) -> Unit raise Error {
  match e {
    @pl.PolarsError::ComputeError(msg) => assert_eq(msg, fs_unpaired_message)
    _ => fail("expected ComputeError, got \{e}")
  }
}

///|
fn fs_frame(cols : Array[@pl.Series]) -> @pl.DataFrame raise Error {
  @pl.DataFrame::new(cols)
}

///|
/// The bytes of a file, as a value that `assert_eq` can show.
fn fs_bytes(p : String) -> Array[Byte] raise Error {
  let b = @xfs.read_file_to_bytes(p)
  Array::makei(b.length(), i => b[i])
}

///|
fn fs_expect_bytes(p : String, expected : Bytes) -> Unit raise Error {
  assert_eq(fs_bytes(p), Array::makei(expected.length(), i => expected[i]))
}

///|
test "fs: the test directory is created, usable and removed" {
  fs_prepare()
  // Create a marker by its relative path and read it back through the same
  // path; on every backend the file must exist right there, and after the
  // cleanup neither the file nor the directories are left.
  let p = fs_path("where.txt")
  @xfs.write_bytes_to_file(p, b"here")
  assert_true(@xfs.path_exists(p))
  assert_true(@xfs.is_file(p))
  assert_true(@xfs.is_dir(fs_test_dir))
  fs_expect_bytes(p, b"here")
  fs_cleanup(["where.txt"])
  assert_false(@xfs.path_exists(p))
  assert_false(@xfs.path_exists(fs_test_dir))
}

///|
test "fs: write_csv then read_csv" {
  fs_prepare()
  let df = fs_frame([
    @pl.Series::int64("i", [1L, -2L, 3L]),
    @pl.Series::float64("f", [1.5, 0.0 / 0.0, -0.0]),
    @pl.Series::str_nullable("s", [Some("a,b"), None, Some("")]),
    @pl.Series::bool("b", [true, false, true]),
  ])
  let p = fs_path("plain.csv")
  @plfs.write_csv(df, p)
  fs_expect_bytes(
    p, b"i,f,s,b\n1,1.5,\"a,b\",true\n-2,NaN,,false\n3,-0.0,\"\",true\n",
  )
  let back = @plfs.read_csv(p)
  assert_eq(back.shape(), (3, 4))
  assert_eq(back.dtypes(), [@pl.DataType::Int64, Float64, String, Boolean])
  assert_eq(back.column("i").to_int64_array(), [Some(1L), Some(-2L), Some(3L)])
  assert_eq(back.column("s").to_str_array(), [Some("a,b"), None, Some("")])
  assert_eq(back.column("b").to_bool_array(), [
    Some(true),
    Some(false),
    Some(true),
  ])
  fs_cleanup(["plain.csv"])
}

///|
test "fs: write_csv overwrites an existing file and creates a missing one" {
  fs_prepare()
  let p = fs_path("over.csv")
  assert_false(@xfs.path_exists(p))
  let long = fs_frame([@pl.Series::str("s", ["aaaaaaaaaa", "bbbbbbbbbb"])])
  @plfs.write_csv(long, p)
  assert_true(@xfs.path_exists(p))
  fs_expect_bytes(p, b"s\naaaaaaaaaa\nbbbbbbbbbb\n")
  let short = fs_frame([@pl.Series::int64("n", [7L])])
  @plfs.write_csv(short, p)
  // Nothing of the longer first file is left.
  fs_expect_bytes(p, b"n\n7\n")
  assert_eq(@plfs.read_csv(p).shape(), (1, 1))
  fs_cleanup(["over.csv"])
}

///|
test "fs: write_csv passes the options on" {
  fs_prepare()
  let df = fs_frame([
    @pl.Series::int64("a", [1L, 2L]),
    @pl.Series::str("b", ["x;y", "z"]),
  ])
  let p = fs_path("opts.csv")
  @plfs.write_csv(
    df,
    p,
    options=@pl.CsvWriteOptions::new(
      separator=';',
      line_terminator="\r\n",
      include_bom=true,
    ),
  )
  fs_expect_bytes(p, b"\xef\xbb\xbfa;b\r\n1;\"x;y\"\r\n2;z\r\n")
  let back = @plfs.read_csv(p, options=@pl.CsvReadOptions::new(separator=';'))
  assert_eq(back.columns(), ["a", "b"])
  assert_eq(back.column("b").to_str_array(), [Some("x;y"), Some("z")])
  fs_cleanup(["opts.csv"])
}

///|
test "fs: write_csv of a frame with no rows writes the header only" {
  fs_prepare()
  let p = fs_path("empty_frame.csv")
  let df = fs_frame([@pl.Series::int64("a", []), @pl.Series::str("b", [])])
  @plfs.write_csv(df, p)
  fs_expect_bytes(p, b"a,b\n")
  let back = @plfs.read_csv(p)
  assert_eq(back.shape(), (0, 2))
  assert_eq(back.columns(), ["a", "b"])
  fs_cleanup(["empty_frame.csv"])
}

///|
test "fs: read_csv of a missing file raises IOError" {
  fs_prepare()
  let p = fs_path("missing.csv")
  let e = fs_error_of(() => @plfs.read_csv(p))
  fs_expect_io_error(e, p)
  assert_false(@xfs.path_exists(p))
  fs_cleanup([])
}

///|
test "fs: read_csv of a directory raises IOError" {
  fs_prepare()
  let e = fs_error_of(() => @plfs.read_csv(fs_test_dir))
  fs_expect_io_error(e, fs_test_dir)
  fs_cleanup([])
}

///|
/// A relative path of a directory whose name is a part of the word "directory"
/// (the text of some operating systems for reading a directory), a different
/// one per backend so that backends running at the same time do not share it.
/// The name is reserved for this test: it is removed first when a failed run
/// left it.
fn fs_word_dir() -> String {
  match fs_backend() {
    "native" => "dir"
    "js" => "ect"
    "wasm" => "ory"
    _ => "tor"
  }
}

///|
/// Whether `msg` has `p` as a path of its own and not only inside a word.
fn fs_names_path(msg : String, p : String) -> Bool {
  msg.has_prefix(p + ": ") ||
  msg.contains(" " + p + ":") ||
  msg.contains(" " + p + ",") ||
  msg.contains("'" + p + "'") ||
  msg.contains("\"" + p + "\"")
}

///|
test "fs: reading a directory whose name is part of the word directory names the path" {
  fs_prepare()
  let p = fs_word_dir()
  if @xfs.path_exists(p) {
    @xfs.remove_dir(p) catch {
      _ => ()
    }
  }
  @xfs.create_dir(p)
  let e = fs_error_of(() => @plfs.read_csv(p))
  fs_expect_io_error(e, p)
  match e {
    @pl.PolarsError::IOError(msg) => assert_true(fs_names_path(msg, p))
    _ => fail("expected IOError, got \{e}")
  }
  @xfs.remove_dir(p)
  assert_false(@xfs.path_exists(p))
  fs_cleanup([])
}

///|
test "fs: write_csv into a missing parent directory raises IOError" {
  fs_prepare()
  let df = fs_frame([@pl.Series::int64("a", [1L])])
  let p = "\{fs_test_dir}/no_such_dir/x.csv"
  let e = fs_error_of(() => @plfs.write_csv(df, p))
  fs_expect_io_error(e, p)
  // Neither the directory nor the file was created.
  assert_false(@xfs.path_exists("\{fs_test_dir}/no_such_dir"))
  assert_false(@xfs.path_exists(p))
  fs_cleanup([])
}

///|
test "fs: write_csv onto a directory raises IOError and keeps the directory" {
  fs_prepare()
  let df = fs_frame([@pl.Series::int64("a", [1L])])
  let e = fs_error_of(() => @plfs.write_csv(df, fs_test_dir))
  fs_expect_io_error(e, fs_test_dir)
  assert_true(@xfs.is_dir(fs_test_dir))
  fs_cleanup([])
}

///|
test "fs: both functions raise @pl.PolarsError, so no other error type is needed" {
  fs_prepare()
  let p = fs_path("typed.csv")
  let df = fs_frame([@pl.Series::int64("a", [1L])])
  // These patterns only compile when the error type is `@pl.PolarsError`.
  try @plfs.read_csv(p) |> ignore catch {
    @pl.IOError(msg) => assert_true(msg.contains(p))
    e => fail("expected IOError, got \{e}")
  } noraise {
    _ => fail("expected an error")
  }
  try @plfs.write_csv(df, "\{fs_test_dir}/no_such_dir/typed.csv") catch {
    @pl.IOError(msg) => assert_true(msg.contains("no_such_dir"))
    e => fail("expected IOError, got \{e}")
  } noraise {
    _ => fail("expected an error")
  }
  fs_cleanup([])
}

///|
test "fs: write_csv refuses an unpaired surrogate in a cell and leaves no file" {
  fs_prepare()
  let p = fs_path("lone.csv")
  let hi = fs_unit(0xD800)
  let lo = fs_unit(0xDC00)
  let hi_last = fs_unit(0xDBFF)
  let lo_first = fs_unit(0xDFFF)
  let cells = [
    "a" + hi + "b",
    "a" + lo + "b",
    hi,
    lo,
    hi_last + "x",
    "x" + lo_first,
    // a low half before a high half is two lone halves
    lo + hi,
    // a high half followed by a character that is not a low half
    hi + "\u{10000}",
    hi + hi + lo,
    // a high half at the very end of the text (no line terminator)
    "ok" + hi,
  ]
  for i, cell in cells {
    let df = fs_frame([@pl.Series::str("s", [cell])])
    let e = fs_error_of(() => {
      @plfs.write_csv(
        df,
        p,
        options=@pl.CsvWriteOptions::new(
          line_terminator=if i == cells.length() - 1 { "" } else { "\n" },
        ),
      )
    })
    fs_expect_unpaired(e)
    assert_false(@xfs.path_exists(p))
  }
  fs_cleanup(["lone.csv"])
}

///|
test "fs: write_csv refuses an unpaired surrogate in a name, null_value or line_terminator" {
  fs_prepare()
  let p = fs_path("lone_opts.csv")
  let hi = fs_unit(0xD83D)
  let lo = fs_unit(0xDE00)
  let plain = fs_frame([@pl.Series::int64("a", [1L, 2L])])
  let with_null = fs_frame([@pl.Series::int64_nullable("a", [Some(1L), None])])
  // a column name
  let named = fs_frame([@pl.Series::int64("n" + hi, [1L])])
  fs_expect_unpaired(fs_error_of(() => @plfs.write_csv(named, p)))
  let named_lo = fs_frame([@pl.Series::int64(lo + "n", [1L])])
  fs_expect_unpaired(fs_error_of(() => @plfs.write_csv(named_lo, p)))
  // the name is not written when the header is off
  @plfs.write_csv(
    named,
    p,
    options=@pl.CsvWriteOptions::new(include_header=false),
  )
  fs_expect_bytes(p, b"1\n")
  @xfs.remove_file(p)
  // null_value
  fs_expect_unpaired(
    fs_error_of(() => {
      @plfs.write_csv(
        with_null,
        p,
        options=@pl.CsvWriteOptions::new(null_value="N" + hi),
      )
    }),
  )
  fs_expect_unpaired(
    fs_error_of(() => {
      @plfs.write_csv(
        with_null,
        p,
        options=@pl.CsvWriteOptions::new(null_value=lo),
      )
    }),
  )
  // null_value is only written for a null: no null, no problem
  @plfs.write_csv(
    plain,
    p,
    options=@pl.CsvWriteOptions::new(null_value="N" + hi),
  )
  fs_expect_bytes(p, b"a\n1\n2\n")
  @xfs.remove_file(p)
  // line_terminator
  fs_expect_unpaired(
    fs_error_of(() => {
      @plfs.write_csv(
        plain,
        p,
        options=@pl.CsvWriteOptions::new(line_terminator=hi),
      )
    }),
  )
  fs_expect_unpaired(
    fs_error_of(() => {
      @plfs.write_csv(
        plain,
        p,
        options=@pl.CsvWriteOptions::new(line_terminator=lo + "\n"),
      )
    }),
  )
  assert_false(@xfs.path_exists(p))
  fs_cleanup(["lone_opts.csv"])
}

///|
test "fs: a refused write leaves an existing file as it was" {
  fs_prepare()
  let p = fs_path("keep.csv")
  let good = fs_frame([@pl.Series::str("s", ["keep", "me"])])
  @plfs.write_csv(good, p)
  fs_expect_bytes(p, b"s\nkeep\nme\n")
  let bad = fs_frame([@pl.Series::str("s", ["x" + fs_unit(0xD800)])])
  fs_expect_unpaired(fs_error_of(() => @plfs.write_csv(bad, p)))
  fs_expect_bytes(p, b"s\nkeep\nme\n")
  let bad_lo = fs_frame([@pl.Series::str("s", [fs_unit(0xDC00) + "x"])])
  fs_expect_unpaired(fs_error_of(() => @plfs.write_csv(bad_lo, p)))
  fs_expect_bytes(p, b"s\nkeep\nme\n")
  fs_cleanup(["keep.csv"])
}

///|
test "fs: paired surrogates are written as UTF-8, also next to lone-looking text" {
  fs_prepare()
  let p = fs_path("pairs.csv")
  // A pair written as two separate characters is the supplementary character.
  let pair = fs_unit(0xD83D) + fs_unit(0xDE00)
  let words = ["\u{1F600}", pair, "\u{10000}", "\u{10FFFF}", "a" + pair + "b"]
  let df = fs_frame([@pl.Series::str("w", words)])
  @plfs.write_csv(df, p)
  fs_expect_bytes(
    p, b"w\n\xf0\x9f\x98\x80\n\xf0\x9f\x98\x80\n\xf0\x90\x80\x80\n\xf4\x8f\xbf\xbf\na\xf0\x9f\x98\x80b\n",
  )
  assert_eq(@plfs.read_csv(p).column("w").to_str_array(), [
    Some("\u{1F600}"),
    Some("\u{1F600}"),
    Some("\u{10000}"),
    Some("\u{10FFFF}"),
    Some("a\u{1F600}b"),
  ])
  fs_cleanup(["pairs.csv"])
}

///|
test "fs: the code points next to the surrogate range and the last pair are written" {
  fs_prepare()
  let p = fs_path("edges.csv")
  let words = [
    "\u{D7FF}",
    "\u{E000}",
    "a\u{D7FF}\u{E000}b",
    // the last high half with the first low half, and the first with the last
    fs_unit(0xDBFF) + fs_unit(0xDC00),
    fs_unit(0xD800) + fs_unit(0xDFFF),
  ]
  let df = fs_frame([@pl.Series::str("w", words)])
  @plfs.write_csv(df, p)
  fs_expect_bytes(
    p, b"w\n\xed\x9f\xbf\n\xee\x80\x80\na\xed\x9f\xbf\xee\x80\x80b\n\xf4\x8f\xb0\x80\n\xf0\x90\x8f\xbf\n",
  )
  let back = @plfs.read_csv(p).column("w").to_str_array()
  assert_eq(back, words.map(w => Some(w)))
  fs_cleanup(["edges.csv"])
}

///|
test "fs: invalid UTF-8 is a ParseError" {
  fs_prepare()
  let p = fs_path("bad.csv")
  let cases : Array[Bytes] = [
    b"a\n\xff\xfe\n",
    // A truncated two-byte sequence at the end.
     b"a\nx\xc3",
    // A continuation byte on its own.
     b"a\n\x80\n",
    // An encoded surrogate (U+D800).
     b"a\n\xed\xa0\x80\n",
    // An overlong encoding of "/".
     b"a\n\xc0\xaf\n",
    // Above U+10FFFF.
     b"a\n\xf4\x90\x80\x80\n",
  ]
  for i, bytes in cases {
    @xfs.write_bytes_to_file(p, bytes)
    let e = fs_error_of(() => @plfs.read_csv(p))
    match e {
      @pl.PolarsError::ParseError(msg) =>
        assert_eq(msg, "invalid utf-8 sequence")
      _ => fail("case \{i}: expected ParseError, got \{e}")
    }
  }
  fs_cleanup(["bad.csv"])
}

///|
test "fs: a BOM is removed once and not twice" {
  fs_prepare()
  let p = fs_path("bom.csv")
  @xfs.write_bytes_to_file(p, b"\xef\xbb\xbfa,b\n1,2\n")
  let df = @plfs.read_csv(p)
  // The first column is "a", not "\u{feff}a".
  assert_eq(df.columns(), ["a", "b"])
  assert_eq(df.shape(), (1, 2))
  // Two BOMs: only the first is a BOM, the second belongs to the name.
  @xfs.write_bytes_to_file(p, b"\xef\xbb\xbf\xef\xbb\xbfa\n1\n")
  assert_eq(@plfs.read_csv(p).columns(), ["\u{feff}a"])
  // A BOM in front of a quoted first field.
  @xfs.write_bytes_to_file(p, b"\xef\xbb\xbf\"a\",b\n1,2\n")
  assert_eq(@plfs.read_csv(p).columns(), ["a", "b"])
  fs_cleanup(["bom.csv"])
}

///|
test "fs: a CRLF file" {
  fs_prepare()
  let p = fs_path("crlf.csv")
  @xfs.write_bytes_to_file(p, b"a,b\r\n1,\"x\r\ny\"\r\n2,z\r\n")
  let df = @plfs.read_csv(p)
  assert_eq(df.shape(), (2, 2))
  assert_eq(df.columns(), ["a", "b"])
  // The \r\n inside quotes is data; the one ending a record is not.
  assert_eq(df.column("b").to_str_array(), [Some("x\r\ny"), Some("z")])
  assert_eq(df.column("a").to_int64_array(), [Some(1L), Some(2L)])
  fs_cleanup(["crlf.csv"])
}

///|
test "fs: a file with LF and CRLF mixed and no final newline" {
  fs_prepare()
  let p = fs_path("mixed.csv")
  @xfs.write_bytes_to_file(p, b"a\n1\r\n2\n3")
  let df = @plfs.read_csv(p)
  assert_eq(df.column("a").to_int64_array(), [Some(1L), Some(2L), Some(3L)])
  fs_cleanup(["mixed.csv"])
}

///|
test "fs: non-ASCII text survives the file" {
  fs_prepare()
  let p = fs_path("utf8.csv")
  let words = ["é", "日本語", "😀 x", "naïve café"]
  let df = fs_frame([@pl.Series::str("w", words)])
  @plfs.write_csv(df, p)
  // The bytes on disk are UTF-8.
  fs_expect_bytes(
    p, b"w\n\xc3\xa9\n\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e\n\xf0\x9f\x98\x80 x\nna\xc3\xafve caf\xc3\xa9\n",
  )
  let back = @plfs.read_csv(p)
  assert_eq(back.column("w").to_str_array(), words.map(w => Some(w)))
  fs_cleanup(["utf8.csv"])
}

///|
test "fs: an empty file is an empty CSV" {
  fs_prepare()
  let p = fs_path("zero.csv")
  @xfs.write_bytes_to_file(p, b"")
  let e = fs_error_of(() => @plfs.read_csv(p))
  match e {
    @pl.PolarsError::ParseError(msg) => assert_eq(msg, "empty CSV")
    _ => fail("expected ParseError, got \{e}")
  }
  fs_cleanup(["zero.csv"])
}

///|
test "fs: parse errors come through unchanged" {
  fs_prepare()
  let p = fs_path("perr.csv")
  @xfs.write_bytes_to_file(p, b"a\n1\nx\n")
  let e = fs_error_of(() => {
    @plfs.read_csv(
      p,
      options=@pl.CsvReadOptions::new(
        schema_overrides=Map::from_array([("a", @pl.DataType::Int64)]),
      ),
    )
  })
  match e {
    @pl.PolarsError::ParseError(msg) => assert_true(msg.contains("at line 3"))
    _ => fail("expected ParseError, got \{e}")
  }
  fs_cleanup(["perr.csv"])
}
