# polars 对照数据（golden data）

`src/pl` 的行为以 polars 为准。这里的数据由 polars 生成，测试把它嵌进 MoonBit 源码后逐条比对。

- polars 版本：**2.1.0**（Python 3.12，lab5 上的 `/data/lly-moonbit/polars-venv`）
- 数据只由脚本生成，不手改；改脚本后重新生成并一起提交。

## 生成方法

在仓库根目录运行（需要装了 polars 的 Python）：

```
python docs/golden/scripts/cast.py
python docs/golden/scripts/show.py
python docs/golden/scripts/char_width.py   # 宽度表，见下面“字符宽度表”；生成后再跑一次 moon fmt
```

（Python 会在 `scripts/` 下生成 `__pycache__/`，已在 `.gitignore` 里忽略；也可设 `PYTHONDONTWRITEBYTECODE=1`。）

每个脚本调用 `emit(name, cases)`（`scripts/emit.py`），一次写两个文件：

| 文件 | 用途 |
| --- | --- |
| `docs/golden/<name>.json` | 人可读的数据（`indent=1, sort_keys=True, ensure_ascii=False`） |
| `src/pl/golden_<name>_data_test.mbt` | 同一份 JSON 嵌成 `let golden_<name> : String`，因为 wasm 下测试读不了文件 |

测试里用 `@json.parse(golden_<name>)` 解析，`src/pl/golden_helpers_test.mbt` 的 `golden_series` 把 Series 的 JSON 编码还原成 `@pl.Series`。

## Series 的 JSON 编码

```
{"name": "a", "dtype": "<显示名>", "values": [...]}
```

- 显示名：`bool`、`i32`、`i64`、`f32`、`f64`、`str`、`date`、`datetime[μs]`、`null`。
- 非 null 的值一律是字符串，null 是 JSON `null`：
  - 整数：十进制。
  - 浮点：Python `repr`（`nan`、`inf`、`-inf`、`-0.0`、`1e+20`）。`f32` 的值先扩成 `f64` 再 `repr`，所以 `3.4e38` 的 `f32` 写成 `3.3999999521443642e+38`。
  - 布尔：`true` / `false`。
  - 字符串：原样。
  - Date：天数；Datetime：微秒。

## cast.json

`cast.py` 对 9×9 种 (from, to) 类型组合，各在 `strict=True` 和 `strict=False` 下执行 `Series.cast`，共 162 条，另外对每种类型的空序列（9 种）和全 null 序列（`null` 除外，8 种）各做一遍，共 468 条。每条：

```
{"id": "i64->i32/strict", "from": <series>, "to": "<显示名>", "strict": true,
 "result": <series>}                      // 成功
{..., "error": "InvalidOperation", "message": "<polars 报错信息的第一行>"}
```

`error` 是 polars 的异常类名去掉 `Error`（`InvalidOperationError` → `InvalidOperation`，对应 `PolarsError` 的同名变体），`message` 是信息的第一行（polars 有时在后面追加提示行，不属于对照内容）。测试比较变体和整行文案。两种失败 polars 都报 `InvalidOperationError`：`strict=False` 也失败是类型对不支持（`casting from Date to Boolean not supported`）；只有 `strict=True` 失败是有值转换不了（`conversion from `str` to `i64` failed in column 'a' for 3 out of 4 values: ["x", "y", "z"]`）。

用例的取值（含 `nan`、`inf`、`-0.0`、1970 年之前的日期和微秒、`Int32` / `Int64` 的边界值及其前后一位、`Int64` 微秒能表示的最大天数 ±106 751 991 及其外一位）见 `scripts/cast.py` 的 `SOURCES`。

polars 对一部分超范围日期会 panic（`PanicException: out-of-range date`，它不是 `Exception` 的子类）：`date` 转 `str` 在 |天数| 超过约 9 570 万时，严格模式下 `date` 转 `datetime` 在天数乘微秒溢出 `Int64` 时。脚本捕获 panic，把触发 panic 的值从那一条用例的 `from` 里去掉再重跑，被去掉的值记在该用例的 `omitted_values` 字段里（目前是 `date->str` 的两条用例和 `date->datetime[μs]/strict`）。这些边界值（±110 000 000 天）由 `src/pl/cast_test.mbt` 里手写的用例钉住。

### polars 2.1.0 的几条行为（实现据此）

- 浮点转字符串：最短往返数字；`f64` 在 `1e-5 <= |x| < 1e16` 用定点，其余用 `1.5e+16`、`1e-6`；`f32` 的定点范围是 `1e-6 <= |x| < 1e13`；`NaN`、`inf`、`-inf`、`-0.0`。
- 浮点转整数向零截断，超出范围或 NaN/inf 是失败值。浮点转 `bool` 是 `!= 0`（NaN 为 true）。
- 整数转 `datetime` 把整数当微秒；`date` 转 `datetime` 乘 86 400 000 000；`datetime` 转 `date` 向下取整。
- 字符串只能转整数和浮点；转 `bool`、`date`、`datetime` 是 `InvalidOperation`。`date`、`datetime` 转 `bool`、`null` 也是。
- 任何类型转 `null`：只有源值全是 null 才成功。
- 空序列和全 null 序列转任何类型都成功（包括下面那 7 个不支持的类型对、两种模式），得到同名同长度的全 null 序列（`[empty]`、`[all-null]` 用例，17 个输入 × 9 个目标类型 × 2 种模式 = 306 个组合实测无一例外）；不支持的类型对的错误只在至少有一个非 null 值时才出现。
- 字符串转 `f32`：按十进制串的精确值舍入到最近的 `f32`（平局取偶，即 Rust 的 `f32::from_str`），不经过 `f64` 再舍入；只有精确值不小于 2^128 − 2^103 才是 `inf`。`SOURCES["str"]` 里有 `f32::MAX` 与无穷的分界、最小次正规数的分界、双重舍入会出错的串。另有 0.5 + 2^-25 的精确平局（`0.5…`、`.5…` 两种写法及多一位的串）、`-0` / `-0.0` / `-0e5` / `-1e-400` 的负零、超过 Int32 甚至 Int64 的指数（`1e4294967297`、`1e99999999999999999999`）。
- 字符串转 `f64`：尾数很长时按精确十进制值舍入，溢出才是 `inf`。`SOURCES["str"]` 里有 400 位尾数加负指数的串（`1` 后 400 个 `0` 再 `e-91` 是 1e309，得 `inf`；`e-92` 是 1e308，是有限值；`e-400` 得 1.0）和 `f64::MAX` 的分界（`17976931348623157` 后 292 个 `0` 是有限值，`…159` 得 `inf`）。
- 字符串转 `i64`：`SOURCES["str"]` 里有前 18 位已超过 922337203685477580 的 19 位数（`9223372036854775810` 等），都是失败值。`datetime[μs]` 的 `1152921573326323713`（2^60 + 2^36 + 1）转 `f32` 要直接舍入一次（经过 `f64` 会差 1）。
- 严格模式转换失败的列表：polars 收集前 10 个失败值（个数是完整的），失败值不超过 3 个时全列（`["x", "y", "z"]`），多于 3 个时列前两个、`…`、已收集的最后一个（`["x0", "x1", … "x9"]`，哪怕有 20 个失败）。值的写法同表格单元格：浮点是 `fmt_float`（`f32` 先扩成 `f64`，如 `3.0000e10`、`NaN`、`-inf`），整数、布尔原样，日期时间同 Show（`2024-02-29 12:34:56.123456`），字符串加双引号但不转义、不截断（`"a"b"`、换行原样）；列名也原样写在单引号里。

## show.json

`show.py` 开头调用 `pl.Config.restore_defaults()`，记录 363 条 `str(...)` 的结果：

```
{"id": "frame/mixed", "frame": [<series>, ...], "expected": "<str(df)>"}
{"id": "series/rows25", "series": <series>, "expected": "<str(series)>"}
```

`frame` 为空数组表示 0 列的空表。覆盖：混合小表、行折叠（0、1、9、10、11、12、25 行）、列折叠（7 到 12 列，12 列 x 25 行）、
date/datetime（1970 年之前、年份超过 9999、负年份、毫秒/微秒小数）、f32/f64 的各种数量级和四舍五入进位、
`NaN`/`inf`/`-0.0`、字符串（空串、30/31 个字符、换行、引号、制表符、非 ASCII、全角、emoji）、Null 类型列、0 列空表、有列 0 行的表、
各类型的 0 行表、长列名/带换行的列名，以及对应的 Series 输出。字符宽度专项（`frame/width_*`、`series/width_mixed`）：韩文、组合字符、零宽空格、变体选择符（`U+FE0F` 接在文本符号后）、半角/全角形式、CJK 扩展 B、`U+1F680` 区的 emoji。字符序列专项（`frame/seq_*`、`series/seq_*`，样例在 `show.py` 的 `SEQ_SAMPLES`）：ZWJ emoji 序列（家庭、职业、旗帜、肤色链）、肤色修饰符、键帽、国旗（区域指示符成对）、标签序列、`U+FE0E`/`U+FE0F`/`U+FE01`、组合型韩文字母、组合符号叠在宽/窄字符上、印度系/东南亚文字（天城文、孟加拉文、泰米尔文、泰文、高棉文、藏文、缅文等）、阿拉伯文变音符号和 lam-alef 连字、希伯来文、西夏文、契丹小字、几个旧宽度表出错的符号区间，以及超过 30 个字符/31 列的长单元格（截断和折行）。折行专项（`frame/wrap_*`、`frame/cluster_*`、`frame/khmer_*`）：带空格的中日韩句子、连续空格、超长单词、单词恰好放得下或差一列、剩余不足 4 列、列名/类型名折行，折行处落在国旗、键帽、天城文连字、lam-alef、ZWJ 序列中间，以及 `U+17D8`（3 列宽）引起的列宽规则。

### polars 2.1.0 的显示规则（实现据此）

- 表最多显示 10 行（超出则前 5 行、`…`、后 5 行）和 8 列（超出则前 4 列、`…` 列、后 4 列）；Series 超过 10 个元素同样折叠。
- 字符串超过 30 个字符截成 30 个字符加 `…`。表里不加引号；Series 里加引号，被截断的元素没有结尾引号（polars 的行为）。列名同样按 30 个字符截断。
- 单元格里的换行把单元格拆成多行；同一行其它列补空。每行最宽 31 列，更宽的按 comfy-table 的规则折行（见 Show 一节的“折行”），列宽取 31。
- 宽度：CJK、全角、emoji 算 2 列，组合字符和零宽字符算 0，其它（含制表符、`\r`）算 1。
- 浮点（polars 的 `fmt_float`，`f32` 先扩成 `f64`）：
  - 整数值且 `|x| < 999999` 写成 `1.0`、`-0.0`；
  - 其它值如果 Rust `Display` 文本（定点、不用科学计数法）超过 9 个字符：`|x| < 1e-6` 或 `|x| > 999999` 用 5 位有效数字的科学计数法（`1.2346e8`、`1.0000e-7`），否则最多 6 位小数并去掉末尾的 0（`0.333333`、`12.0`）；舍入按精确十进制值、五入偶数（`12345500000.0` 是 `1.2346e10`，`12344500000.0` 是 `1.2344e10`）；
  - 其余整数值用最短位数的科学计数法（`1e6`、`1.2345678e7`），其余小数直接用最短文本；
  - `NaN`、`inf`、`-inf`。
- Date：`YYYY-MM-DD`（年份超过 9999 前缀 `+`，负年份前缀 `-`）。Datetime：`YYYY-MM-DD HH:MM:SS`，有小数时整毫秒写 3 位、否则写 6 位。
- 0 列的表：`shape: (0, 0)` 加空框 `┌┐ ╞╡ └┘`。有列 0 行：表头和 `╞═╡` 之后直接是底边。
- polars 默认把表格宽度限制在 100 列（非终端、`POLARS_TABLE_WIDTH` 未设时也一样），超出时缩窄并折行靠后的列；这里不模拟，见下面 Show 的“表格总宽度”。

`AnyValue` 的 `Show` 与表格单元格同文（字符串不带引号、超过 30 个字符会被截断）。

## 已知差异

没有被跳过的用例：cast 的 468 条和 show 的 363 条全部与 polars 一致（cast 里有 3 条为避开 polars 的 panic 去掉了个别输入值，见上）。下面是对照数据没覆盖、或实现有意不同的地方（其中前几条是 polars 在这些输入上 panic，没有可对照的结果）：

- **超范围的 Date 转字符串**：polars 2.1.0 在 |天数| 超过约 9 570 万（chrono 的 ±262 143 年上限）时 panic（`out-of-range date`；实测 `95_000_000` 能格式化，`96_000_000` panic）。这里能格式化到 ±110 000 000 天，超过则 `Series::cast` 不 abort：`strict=false` 得 null，`strict=true` 报 `ComputeError`。
- **超范围的 Date 转 Datetime**：天数乘微秒溢出 `Int64`（`|days| > 106 751 991`）时，polars 严格模式 panic，`strict=false` 得 null。这里 `strict=false` 同样得 null，`strict=true` 报 `ComputeError`。
- **Datetime 转字符串**：`Int64` 微秒的全部取值都能格式化（年份超过 9999 时前缀 `+`，如 `+10000-01-01`，与 polars 一致）；polars 对超出 chrono 范围（约 ±26 万年）的值 panic，这里仍给出文本。
- **`Series::equals` 的默认参数**：这里 `check_names=true`、`check_dtypes=true`，polars 的 `Series.equals` 两者默认都是 false；`DataFrame::equals` 也比较列类型（polars 的 `pl.DataFrame({"a":[1]}).equals(pl.DataFrame({"a":[1.0]}))` 为 True）。原因：MoonBit 的 `Eq` 是结构相等，`equals()` 的默认值与 `Eq` 保持一致。
- **`Series::equals(check_dtypes=false)` 的语义**：整数与整数按 `Int64`、只要有浮点就按 `Double` 比较，所以绝对值超过 2^53 的整数与浮点比较会丢精度；null 只等于 null（`int32 [1]` 与 `int64 [null]` 不等），NaN 等于 NaN（`f32` 与 `f64` 之间也是）；两个全 null 的序列（长度相同）无论类型是否不同都相等，长度不同则不等；日期/字符串等其它类型对不同类型一律不等。
- **负长度**：`slice(offset, length=负数)` 返回空序列（polars 抛 `OverflowError`）；`Series::null(name, 负数)` 得到长度 0（polars 抛 `ComputeError`）。
- **`AnyValue` 的 `Eq`**：`AnyValue` 派生 `Eq`，是结构相等，所以 `AnyValue::Float64(nan) != AnyValue::Float64(nan)`；而 `Series::equals` 把 NaN 当作等于 NaN。

### Show

- **超范围的 Date**：polars 2.1.0 在 |天数| 超过约 9 570 万（chrono 的 ±262 143 年）时打印会 panic（`out-of-range date`；实测 `95_000_000` 能打印，`96_000_000` panic）。这里能打印到 ±110 000 000 天，超过则 `Show` 不 abort，输出占位文本 `<out-of-range date>`。
- **超范围的 Datetime**：`Int64` 微秒的全部取值都会输出文本（`+292277-01-01 ...` 这类）；polars 对超出 chrono 范围（约 ±26 万年）的值 panic。
- **空列名**：`pl.DataFrame([series])` 会把空列名改成 `column_N`，这里的 `DataFrame::new` 保留空名，所以对照数据里空列名只出现在 Series 用例（`series/empty_name`）。
- **字符宽度**：宽度表不是手写的，由 `scripts/char_width.py` 在 polars 2.1.0 上逐码点实测生成（`src/pl/char_width_data.mbt`；方法见脚本开头：从 polars 打印出的表格里读列宽，不借用任何 Python 宽度库），序列规则（`U+FE0F`/`U+FE0E`/`U+FE01` 变体选择符、ZWJ emoji、emoji 标签序列（3 到 6 个标签字母，或恰好 3 个标签数字加最多 4 个字母）、肤色修饰符、区域指示符、阿拉伯 lam-alef、希伯来 alef-ZWJ-lamed、高棉 COENG）也由它实测、推导并用随机序列与 polars 对照（`--fuzz`）。全量对照：U+0000–U+10FFFF 去掉代理区和 `U+000A`（polars 先按 `\n` 分行，测不出它自己的宽度，这里记 1，`cell_lines` 先按 `\n` 分行所以不会用到）共 1 112 063 个码点，本实现与 polars 0 差异；另外随机序列 150 万条 0 差异（这两项是一次性的检查）。常驻的检查：`show.json` 的 363 条、`char_width_wbtest.mbt`（每条序列规则的触发样例、字符类边界样例，以及 `char_width_edges_data_wbtest.mbt`：由脚本从 polars 实测生成的 1 800 多个码点，覆盖宽度表每个区间的首尾和两侧邻居、几个快速路径块的边界，测试逐个对照 `cp_width` 和 `str_width`）。还没复现的是 polars 宽度库状态机里几处怪癖，都是真实文本里见不到的组合：
  - 弯引号（`U+2018`、`U+2019`、`U+201C`、`U+201D`）后面跟 `U+FE01`、再跟 alef 类字母、希伯来 lamed 或高棉下标字母时，polars 把引号多算 1 列。这是一族组合，不是单一触发：`U+FE01` 前可夹 `U+FE0F`，`U+FE01` 与字母之间可夹 `U+034F`、`U+200B` 一类零宽标记（紧夹 ZWJ/ZWNJ 时不触发），另有序列里 ZWJ 出现在别处、或引号前多一个 alef/lam 的变体也会触发（复审里的例子：`‘ ZWJ U+FE01 U+FE0E ក ខ ZWJ`，`א ‘ U+FE0F U+FE01 ខ ZWJ`，`ل ‘ U+FE0F U+FE01 ا U+FE01 ل`）。本实现只让变体选择符穿过去，其它零宽标记不穿过，所以这一族都差 1 列；随机序列里查出的差异全部属于这一族，触发条件没有穷尽。
  - 希伯来 alef 后面一串带 `U+FE01` 和 `U+FE0E` 的变体选择符、再接 ZWJ 的组合：本实现的 `vs_step` 在这串变体选择符处断开，polars 在 ZWJ 紧跟 `U+FE0E` 时另有断法。
  - 阿拉伯 lam 后面 `U+FE01`/`U+FE0E` 两种顺序之间夹两个以上 `U+FE0F`：polars 不再成连字，本实现只穿过一个 `U+FE0F`。
- **表格总宽度**：polars 的表格默认总宽 100 列（`Config.set_tbl_width_chars` 的默认值；脚本在非终端环境下也如此），总宽超过时 polars 把靠后的列缩窄并在窄列里折行；这里的 `Show` 不做这件事，只按每列的 31 列上限折行。所以 `show.json` 是在宽度限制关掉的条件下生成的：`show.py` 开头 `pl.Config.restore_defaults()` 之后紧接 `pl.Config.set_tbl_width_chars(60000)`（u16 内的一个够大的值，更大的值 polars 会 panic；用例都只有 1 到几列，不到 100 列，打开或关掉限制结果相同，已逐条核对 `show.json` 逐字节一致）。结论：只有当表格总宽（各列列宽加分隔）不超过 100 列、或者 polars 一侧关掉了宽度限制时，本实现的输出才与 polars 一致；例如 8 列每列 10 个 `x` 的表（105 列），polars 默认输出把后 5 列缩到 9 列宽并折行，这里 8 列都是 12 列宽。没有实现的原因：comfy-table 的动态排版（按内容比例分配列宽）不在这一轮范围内。
- **折行**：单元格超过列宽时，按 comfy-table 的 `split_line`/`split_long_word` 折行：只在单个空格 `U+0020` 处断词（连续空格里多出来的是空词，行首的丢掉，行尾的是补位），放得下就接在当前行后面（加一列的空格），比列宽还宽的词在当前行剩余不少于 4 列时切进当前行、否则另起一行，切词按字素簇（UAX #29 加 GB9c 的印度系连字，数据取 Unicode 17.0.0，`src/pl/grapheme_data.mbt` 由 `scripts/grapheme.py` 生成；polars 用的 `unicode-segmentation` 带的就是 17.0 的表，换成 16 或 18 的数据会有差异）整簇切，每个簇单独量宽（所以 lam-alef 记 1+1，一串韩文初声 `U+1100` 是一个 32 列的簇，行首放不下时只取一个码点）。折行宽度（列宽）：各单元格（包括列名、`---`、类型名）里最宽的一行，上限 31；但每个单元格按 `min(2×码点数, UTF-8 字节数)` 封顶，取这一列里最大的封顶值，只有 `U+17D8`（3 列、3 字节）会超过这个封顶。验证：`scripts/grapheme.py --check` 对 polars 随机折行（单词、组合符、emoji、印度系、韩文、阿拉伯文、初声串、高棉文各 2 万条单元格）0 差异；字素簇切分另有 Unicode 官方的 `GraphemeBreakTest.txt`（766 条）常驻测试；`show.json` 的折行用例见上。已知差异（polars 的随机折行里没有对照出来的）：上面“字符宽度”里列的几处怪癖落在折行单元格里时宽度也会差。
