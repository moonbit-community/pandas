# 与 polars 的已知差异：`str` / `dt` 内核（T6）

数据：`docs/golden/str_dt.json`（`scripts/str_dt.py` 生成，polars 2.1.0）。大小写表：`src/pl/case_data.mbt`（`scripts/case_tables.py` 生成）。

正则用 `moonbitlang/core` 的 `@string.Regex`（lexmatch 风格），polars 用 Rust 的 `regex` crate，两者语法和语义有出入。下表以 core 文档（`string/README.mbt.md`）和 moonc v0.10.22 上的实测为准。`str_dt.json` 里这些差异对应的用例带 `"skip": "<原因>"`，值是 polars 的结果；测试检查本库**仍然**与 polars 不同（core 改了、差异消失时测试会提醒，把用例从跳过列表里去掉即可）。对照数据里其余的正则用例只用两边共有的语法，全部对得上。

## 正则语法差异

下面的写法 Rust regex 接受，`@string.Regex` 不接受，构造时 `raise`，本库报 `ComputeError`（文案见下）。

| 写法 | Rust regex | `@string.Regex` | 替代写法 |
| --- | --- | --- | --- |
| `\d` `\D` `\s` `\S` `\w` `\W`（含在 `[...]` 里） | Unicode 类 | 不支持，报错 `Use POSIX character class instead` | `[[:digit:]]` `[[:space:]]` `[[:word:]]`（ASCII） |
| `\xHH`、`\x{H..}` | 支持 | 不支持（`Byte escape sequences are not allowed`） | `\uXXXX`、`\u{X...}`（两边都支持） |
| `\p{L}`、`\pL`、`\P{..}` | Unicode 属性类 | 不支持 | 无 |
| `\A`、`\z` | 文本首、文本尾 | 不支持 | `^`、`$`（本来就只匹配整个输入的首尾） |
| `(?i)abc`、`(?s)`、`(?m)`、`(?U)` 等全局标志 | 支持 | 不支持（只有 `(?i:...)` 这种带作用域的写法） | `(?i:abc)` |
| `(?P<name>...)` | 支持（同时支持 `(?<name>...)`） | 只支持 `(?<name>...)` | `(?<name>...)` |
| `a**`、`a{2}{3}`（重复的重复） | 支持 | 报错 `Unexpected character` | `(?:a*)*`、`(?:a{2}){3}` |
| `[]a]`、`[^]a]`（`[` 后紧跟 `]` 当字面量） | 支持 | 报错 | `[\]a]` |
| `\-`（在类外）、`\<` 等转义标点 | Rust 允许转义任意标点 | 只认它认识的转义（`\\ \. \+ \( \) \[ \] \/ \n \t \r \f \v` 等），其余报 `Invalid escape sequence`；`\-` 只在 `[...]` 里可用 | 直接写字符（`a-b`） |
| `[a-]`、`[-a]`（`-` 在类的开头或末尾） | 字面量 `-` | 报错 `Dash at the start or end of character class is not supported` | `[a\-]`、`[\-a]` |
| `[[:^digit:]]`（取反的 POSIX 类） | 支持 | 报错 `Invalid POSIX character class` | `[^[:digit:]]` |

两边都不支持（都报 `ComputeError`）：反向引用 `\1`、先行断言 `(?=...)`、`(?!...)`、`a{,3}`、`\Q..\E`、`\q`、`[a-\d]`、`(` `)` `[` 不配对、`a{2,1}`、`[z-a]`、开头的 `*`、重复的组名。

## 正则语义差异

- **`.` 匹配换行**：Rust 的 `.` 不匹配 `\n`，`@string.Regex` 的匹配（`a.b` 能匹配 `a\nb`）。没有 `(?s)`，也没法关掉。需要“除换行外的任意字符”时写 `[^\n]`。
- **`(?i:...)` 只折叠 ASCII 字母**：Rust 做 Unicode 简单大小写折叠，所以 `(?i:é)` 在 polars 里匹配 `É`，`(?i:k)` 匹配开尔文符号 U+212A；本库不匹配。`(?i:ss)` 对 `ß` 两边都不匹配。
- **`\b` 是 ASCII 单词边界**：`\bé` 在 Rust 里匹配 `é`，本库不匹配（`é` 不算单词字符）。`[[:word:]]`、`[[:alpha:]]` 两边都是 ASCII 类。
- `^`、`$` 在两边都不是多行模式，只匹配整个输入的首尾；`$` 不匹配结尾 `\n` 之前（`a$` 不匹配 `"a\n"`），两边一致。

已经与 polars 对齐、不需要使用者注意的：

- `str_contains` 是不锚定的搜索；空模式匹配所有非 null 行，也匹配空串。
- `str_replace` 的找匹配规则与 Rust 一致：紧接在上一个匹配之后的空匹配被跳过，所以 `b*` 对 `abc` 的 replace_all 是 `-a-c-`（core 自带的 `Regex::replace_by` 会得到 `-a--c-`，所以本库自己迭代）；空模式在每个字符前和末尾各匹配一次，补充平面字符算一个字符。
- 替换文本里的引用按 Rust `regex` 展开：`$0` 整个匹配、`$n`、`$name`（取最长的 `[0-9A-Za-z_]` 串，`$1a` 是名为 `1a` 的组，不存在，得空串）、`${name}`（取到 `}` 为止的任意字符，`${ 0 }`、`${}` 是名字，得空串；`${+1}` 是第 1 组）、`$$` 是 `$`；不构成引用的 `$`（`$-`、结尾的 `$`、没有 `}` 的 `${1`）保持原样；不存在的组、没参与匹配的组得空串。`literal=true` 时模式和替换文本都按字面量。
- 非法正则报 `ComputeError`，即使列是空的、全 null 的也报（polars 先编译正则）。文案：polars 的第一行是 `regex error: regex parse error:`，没有 pattern，本库追加 pattern 和引擎给的提示：`regex error: regex parse error: "<pattern>": <hint>`（spec 5.6），例如 `regex error: regex parse error: "\d+": Use POSIX character class instead of \w, \W, \d, \D, \s, \S`、`... "(": Unclosed group`。用例里 `polars_message` 存 polars 的原文，`message` 存 `regex error: regex parse error: "<pattern>"`（不含提示，提示随 core 版本变）；对照测试要求本库的文案等于 `message`，或以 `message + ": "` 开头（后面是提示）。
- `literal=true` 的 pattern 不会被当成正则解析，`(` 之类不报错。

## 大小写转换差异

core 的 `String::to_lower` / `to_upper` 只处理 ASCII（`TODO: deal with non-ascii characters`），core 里也没有 Unicode 大小写映射可用（`path/internal/unicode` 是内部包，且只有简单的 `to_lowercase`）。所以本库自己带表：`src/pl/case_data.mbt` 由 `scripts/case_tables.py` 向 polars 2.1.0 逐个码点取得（与 `char_width.py` 测宽度的做法相同），不经过 Python 的 Unicode 库，所以 Unicode 版本与 polars 一致。结果：

- `str_to_lowercase`、`str_to_uppercase` 与 polars 完全一致，包括多字符映射（`ß` → `SS`，`İ` → `i` + U+0307，`ŉ` → `ʼN`，`ﬁ` → `FI`，`ΐ` → 三个字符）、开尔文符号 U+212A → `k`、希腊词尾 `Σ` → `ς`（前面有带大小写的字母、后面没有，两边跳过 Case_Ignorable 字符；这两个集合也是向 polars 探出来的）。
- 没有已知差异，所以 `str_dt.json` 里大小写用例没有 `skip`。代价是 `case_data.mbt` 约 100 KB 源码；以后 core 有了 Unicode 大小写，可以换掉。
- 孤立的代理码元（MoonBit 字符串可能有，polars 的字符串不可能有）原样保留。

## 其它

- **`dt.weekday` 在 `Date` 最小的四个值（-2147483648 到 -2147483645 天）上**：polars 按 32 位算 `(days - 4) mod 7`，`days - 4` 回绕，得到的星期与日历不符（-2147483648 天得 6，按日历应是 2）。本库照 polars 的算法（`Int32` 同样回绕），对得上。
- **超出日历范围的 `Date`/`Datetime`**：polars 能分解的日历是 -262143-01-01（第 -96465292 天）到 262142-12-31（第 95026236 天）。范围外 `year/month/day/ordinal_day`（以及 `Datetime` 的 `hour/minute/second`）得 null，`weekday` 仍按天数算出。本库一致。
- **`hour/minute/second` 作用于 `Date`**、**`dt.*` 作用于非时间类型**：`InvalidOperation`，文案 `` `hour` operation not supported for dtype `date` ``。
- **`str.*` 作用于非 `String` 列（含 `Null` 列）**：`contains`、`starts_with`、`ends_with`、`replace` 报 `InvalidOperation`（`expected String type, got: i32`），`to_lowercase`、`to_uppercase`、`len_chars`、`len_bytes`、`strip_chars` 报 `SchemaMismatch`（``invalid series dtype: expected `String`, got `i32` for series with name `a` ``）。`Null` 列不是“全 null 进、全 null 出”，而是同样报错。
- **`len_bytes` 遇到孤立代理码元**：按 3 字节算（WTF-8）；polars 的字符串里没有这种值，没有对照用例。
- **`strip_chars` 的空白**：Unicode `White_Space`（U+0009–U+000D、U+0020、U+0085、U+00A0、U+1680、U+2000–U+200A、U+2028、U+2029、U+202F、U+205F、U+3000），不含 U+001C–U+001F 和零宽字符。core 的 `Char::is_whitespace` 与这个集合相同（实测），本库仍把集合写在 `str_is_space` 里，不随 core 的 Unicode 版本变。`chars` 是字符集合而不是前后缀；`chars = Some("")` 什么也不去掉（不会退化成去空白）。
