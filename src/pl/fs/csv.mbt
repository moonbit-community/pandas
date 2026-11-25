///|
/// Whether `path` stands in `text` as a path of its own: some occurrence has a
/// space, `'`, `"` or the start of the text before it, and the end of the text,
/// `:`, `,`, a space, `'` or `"` after it. An occurrence inside a longer word
/// (`dir` in `directory`) does not count.
fn names_path(text : String, path : String) -> Bool {
  let n = text.length()
  let m = path.length()
  if m == 0 {
    return false
  }
  let mut i = 0
  while i + m <= n {
    let mut same = true
    for k in 0..<m {
      if text[i + k] != path[k] {
        same = false
        break
      }
    }
    if same {
      let before_ok = i == 0 ||
        (match text[i - 1].to_int() {
          32 | 39 | 34 => true
          _ => false
        })
      let after_ok = i + m == n ||
        (match text[i + m].to_int() {
          58 | 44 | 32 | 39 | 34 => true
          _ => false
        })
      if before_ok && after_ok {
        return true
      }
    }
    i += 1
  }
  false
}

///|
/// The `@pl.PolarsError::IOError` for a failure of `moonbitlang/x/fs` on
/// `path`: the message is the operating system's text, with `<path>: ` put in
/// front when the text does not name the path (see `names_path`).
fn io_error(path : String, payload : String) -> @pl.PolarsError {
  let msg = if names_path(payload, path) {
    payload
  } else {
    path + ": " + payload
  }
  @pl.PolarsError::IOError(msg)
}

///|
/// Whether `text` holds an unpaired surrogate (U+D800..U+DFFF that is not half
/// of a high-then-low pair). One pass over the code units.
fn has_unpaired_surrogate(text : String) -> Bool {
  let n = text.length()
  let mut i = 0
  while i < n {
    let c = text[i].to_int()
    if c >= 0xD800 && c <= 0xDBFF {
      if i + 1 < n &&
        text[i + 1].to_int() >= 0xDC00 &&
        text[i + 1].to_int() <= 0xDFFF {
        i += 2
        continue
      }
      return true
    }
    if c >= 0xDC00 && c <= 0xDFFF {
      return true
    }
    i += 1
  }
  false
}

///|
/// Reads the CSV file at `path` into a `DataFrame`.
///
/// The bytes are decoded as strict UTF-8 (invalid input is
/// `@pl.PolarsError::ParseError("invalid utf-8 sequence")`) and parsed by
/// `@pl.read_csv_str` with `options`; a UTF-8 BOM at the start of the file is
/// removed there, not here.
///
/// Errors are all `@pl.PolarsError`. A file system error (a missing file, a
/// directory, no permission) is `@pl.PolarsError::IOError(message)`: the
/// message is the operating system's text, which depends on the backend, and
/// it always contains `path` (the path is put in front when the text does not
/// name it). `to_string()` gives `IOError: <message>`. Parse errors are those
/// of `read_csv_str`.
pub fn read_csv(
  path : String,
  options~ : @pl.CsvReadOptions = @pl.CsvReadOptions::new(),
) -> @pl.DataFrame raise @pl.PolarsError {
  let bytes = @xfs.read_file_to_bytes(path) catch {
    @xfs.IOError(payload) => raise io_error(path, payload)
  }
  let text = @utf8.decode(bytes) catch {
    @utf8.Malformed(_) =>
      raise @pl.PolarsError::ParseError("invalid utf-8 sequence")
  }
  @pl.read_csv_str(text, options~)
}

///|
/// Writes `df` to the file at `path` as CSV (UTF-8), creating the file when it
/// does not exist and replacing its content when it does.
///
/// The text is that of `@pl.write_csv_str(df, options~)`. The file is not
/// touched (not created, not changed) when the text cannot be built or
/// encoded, so every error below leaves it as it was:
///
/// - an error of `write_csv_str` is raised as it is;
/// - a string that holds an unpaired surrogate (a lone half of a UTF-16 pair,
///   possible in a cell, a column name, `null_value` or `line_terminator`
///   because MoonBit strings are UTF-16) cannot be written as UTF-8: it is
///   `@pl.PolarsError::ComputeError("cannot write a string with an unpaired
///   surrogate as UTF-8")` on every backend. `write_csv_str` itself accepts
///   such strings.
///
/// The parent directory must exist. A file system error (it does not, or the
/// file cannot be written) is `@pl.PolarsError::IOError(message)` as for
/// `read_csv`: the message is the operating system's text, which depends on
/// the backend, and it always contains `path`.
pub fn write_csv(
  df : @pl.DataFrame,
  path : String,
  options~ : @pl.CsvWriteOptions = @pl.CsvWriteOptions::new(),
) -> Unit raise @pl.PolarsError {
  let text = @pl.write_csv_str(df, options~)
  if has_unpaired_surrogate(text) {
    raise @pl.PolarsError::ComputeError(
      "cannot write a string with an unpaired surrogate as UTF-8",
    )
  }
  @xfs.write_bytes_to_file(path, @utf8.encode(text)) catch {
    @xfs.IOError(payload) => raise io_error(path, payload)
  }
}
