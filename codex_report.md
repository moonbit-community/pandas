# Dependency check report

`moon check` still fails after running:

- `moon add xunyoyo/NyaCSV`
- `moon add moonbitlang/x`

`moon add moonbitlang/x` updated `moonbitlang/x` from `0.4.23` to `0.4.43`, which removed the earlier `moonbitlang/x/internal/ffi` error.

The remaining errors come from dependency `xunyoyo/NyaCSV` in `.mooncakes/xunyoyo/NyaCSV`.

## Remaining dependency errors

`xunyoyo/NyaCSV/src/parser.mbt`:

- Several `.trim("\n")`, `.trim("\r")`, `.trim("\t")`, and `.trim(" ")` calls fail with error `[4080]`.
- The current MoonBit `trim` signature expects the character set as a named optional argument (`chars?`) rather than a second positional argument.

`xunyoyo/NyaCSV/src/reader.mbt`:

- `Some(ch)` at line 43 fails with error `[4014]`: the expression has type `UInt16` but `Char` is expected.
- `Some(self.source[self.pos])` at line 72 fails with error `[4014]`: the expression has type `UInt16` but `Char` is expected.

Because these failures are in dependency source code under `.mooncakes`, this repository cannot complete `moon check` without an upstream dependency fix or a compatible dependency version.
