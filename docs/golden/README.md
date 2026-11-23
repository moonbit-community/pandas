# polars 对照数据（golden data）

`src/pl` 的行为以 polars 为准。这里的数据由 polars 生成，测试把它嵌进 MoonBit 源码后逐条比对。

- polars 版本：**2.1.0**（Python 3.12，lab5 上的 `/data/lly-moonbit/polars-venv`）
- 数据只由脚本生成，不手改；改脚本后重新生成并一起提交。

## 生成方法

在仓库根目录运行（需要装了 polars 的 Python）：

```
python docs/golden/scripts/cast.py
python docs/golden/scripts/show.py
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

`cast.py` 对 9×9 种 (from, to) 类型组合，各在 `strict=True` 和 `strict=False` 下执行 `Series.cast`，共 162 条。每条：

```
{"id": "i64->i32/strict", "from": <series>, "to": "<显示名>", "strict": true,
 "result": <series>}                      // 成功
{..., "error": "InvalidOperation" | "ComputeError", "polars_error": "<类名: 消息>"}
```

错误归类：`strict=False` 也失败 → `InvalidOperation`（类型对不支持）；只有 `strict=True` 失败 → `ComputeError`（有值转换失败）。

用例的取值（含 `nan`、`inf`、`-0.0`、1970 年之前的日期和微秒、`Int32` / `Int64` 的边界值及其前后一位、`Int64` 微秒能表示的最大天数 ±106 751 991 及其外一位）见 `scripts/cast.py` 的 `SOURCES`。

polars 对一部分超范围日期会 panic（`PanicException: out-of-range date`，它不是 `Exception` 的子类）：`date` 转 `str` 在 |天数| 超过约 9 570 万时，严格模式下 `date` 转 `datetime` 在天数乘微秒溢出 `Int64` 时。脚本捕获 panic，把触发 panic 的值从那一条用例的 `from` 里去掉再重跑，被去掉的值记在该用例的 `omitted_values` 字段里（目前是 `date->str` 的两条用例和 `date->datetime[μs]/strict`）。这些边界值（±110 000 000 天）由 `src/pl/cast_test.mbt` 里手写的用例钉住。

### polars 2.1.0 的几条行为（实现据此）

- 浮点转字符串：最短往返数字；`f64` 在 `1e-5 <= |x| < 1e16` 用定点，其余用 `1.5e+16`、`1e-6`；`f32` 的定点范围是 `1e-6 <= |x| < 1e13`；`NaN`、`inf`、`-inf`、`-0.0`。
- 浮点转整数向零截断，超出范围或 NaN/inf 是失败值。浮点转 `bool` 是 `!= 0`（NaN 为 true）。
- 整数转 `datetime` 把整数当微秒；`date` 转 `datetime` 乘 86 400 000 000；`datetime` 转 `date` 向下取整。
- 字符串只能转整数和浮点；转 `bool`、`date`、`datetime` 是 `InvalidOperation`。`date`、`datetime` 转 `bool`、`null` 也是。
- 任何类型转 `null`：只有源值全是 null 才成功。

## show.json

`show.py` 开头调用 `pl.Config.restore_defaults()`，记录 81 条 `str(...)` 的结果：

```
{"id": "frame/mixed", "frame": [<series>, ...], "expected": "<str(df)>"}
{"id": "series/rows25", "series": <series>, "expected": "<str(series)>"}
```

`frame` 为空数组表示 0 列的空表。覆盖：混合小表、行折叠（0、1、9、10、11、12、25 行）、列折叠（7 到 12 列，12 列 x 25 行）、
date/datetime（1970 年之前、年份超过 9999、负年份、毫秒/微秒小数）、f32/f64 的各种数量级和四舍五入进位、
`NaN`/`inf`/`-0.0`、字符串（空串、30/31 个字符、换行、引号、制表符、非 ASCII、全角、emoji）、Null 类型列、0 列空表、有列 0 行的表、
各类型的 0 行表、长列名/带换行的列名，以及对应的 Series 输出。字符宽度专项（`frame/width_*`、`series/width_mixed`）：韩文、组合字符、零宽空格、变体选择符（`U+FE0F` 接在文本符号后）、半角/全角形式、CJK 扩展 B、`U+1F680` 区的 emoji。

### polars 2.1.0 的显示规则（实现据此）

- 表最多显示 10 行（超出则前 5 行、`…`、后 5 行）和 8 列（超出则前 4 列、`…` 列、后 4 列）；Series 超过 10 个元素同样折叠。
- 字符串超过 30 个字符截成 30 个字符加 `…`。表里不加引号；Series 里加引号，被截断的元素没有结尾引号（polars 的行为）。列名同样按 30 个字符截断。
- 单元格里的换行把单元格拆成多行；同一行其它列补空。每行最宽 31 列，更宽的（只会出现在宽字符上）硬折行，列宽取 31。
- 宽度：CJK、全角、emoji 算 2 列，组合字符和零宽字符算 0，其它（含制表符、`\r`）算 1。
- 浮点（polars 的 `fmt_float`，`f32` 先扩成 `f64`）：
  - 整数值且 `|x| < 999999` 写成 `1.0`、`-0.0`；
  - 其它值如果 Rust `Display` 文本（定点、不用科学计数法）超过 9 个字符：`|x| < 1e-6` 或 `|x| > 999999` 用 5 位有效数字的科学计数法（`1.2346e8`、`1.0000e-7`），否则最多 6 位小数并去掉末尾的 0（`0.333333`、`12.0`）；舍入按精确十进制值、五入偶数（`12345500000.0` 是 `1.2346e10`，`12344500000.0` 是 `1.2344e10`）；
  - 其余整数值用最短位数的科学计数法（`1e6`、`1.2345678e7`），其余小数直接用最短文本；
  - `NaN`、`inf`、`-inf`。
- Date：`YYYY-MM-DD`（年份超过 9999 前缀 `+`，负年份前缀 `-`）。Datetime：`YYYY-MM-DD HH:MM:SS`，有小数时整毫秒写 3 位、否则写 6 位。
- 0 列的表：`shape: (0, 0)` 加空框 `┌┐ ╞╡ └┘`。有列 0 行：表头和 `╞═╡` 之后直接是底边。
- 生成环境不是终端，没有宽度限制（`POLARS_TABLE_WIDTH` 未设）；在终端里 polars 会按终端宽度换行/折列，这里不模拟。

`AnyValue` 的 `Show` 与表格单元格同文（字符串不带引号、超过 30 个字符会被截断）。

## 已知差异

没有被跳过的用例：cast 的 162 条和 show 的 81 条全部与 polars 一致（cast 里有 3 条为避开 polars 的 panic 去掉了个别输入值，见上）。下面是对照数据没覆盖、或实现有意不同的地方（其中前几条是 polars 在这些输入上 panic，没有可对照的结果）：

- **超范围的 Date 转字符串**：polars 2.1.0 在 |天数| 超过约 9 570 万（chrono 的 ±262 143 年上限）时 panic（`out-of-range date`；实测 `95_000_000` 能格式化，`96_000_000` panic）。这里能格式化到 ±110 000 000 天，超过则 `Series::cast` 不 abort：`strict=false` 得 null，`strict=true` 报 `ComputeError`。
- **超范围的 Date 转 Datetime**：天数乘微秒溢出 `Int64`（`|days| > 106 751 991`）时，polars 严格模式 panic，`strict=false` 得 null。这里 `strict=false` 同样得 null，`strict=true` 报 `ComputeError`。
- **Datetime 转字符串**：`Int64` 微秒的全部取值都能格式化（年份超过 9999 时前缀 `+`，如 `+10000-01-01`，与 polars 一致）；polars 对超出 chrono 范围（约 ±26 万年）的值 panic，这里仍给出文本。
- **字符串转 `f32`**：先按 `f64` 解析再舍入到 `f32`，极少数处于舍入边界的十进制串可能与 polars 差 1 ulp；比 `f32::MAX` 刚大一点的值，如 `"3.4028235677973366e38"`，这里得到 `inf`，polars 得到 `f32::MAX`。
- **`cast(Null, strict=true)`**：非 null 值转 `Null` 时这里报 `ComputeError`，polars 报 `InvalidOperationError`（`strict=false` 两边都得 null）。
- **`Series::equals` 的默认参数**：这里 `check_names=true`、`check_dtypes=true`，polars 的 `Series.equals` 两者默认都是 false；`DataFrame::equals` 也比较列类型（polars 的 `pl.DataFrame({"a":[1]}).equals(pl.DataFrame({"a":[1.0]}))` 为 True）。原因：MoonBit 的 `Eq` 是结构相等，`equals()` 的默认值与 `Eq` 保持一致。
- **`Series::equals(check_dtypes=false)` 的语义**：整数与整数按 `Int64`、只要有浮点就按 `Double` 比较，所以绝对值超过 2^53 的整数与浮点比较会丢精度；null 只等于 null（`int32 [1]` 与 `int64 [null]` 不等），NaN 等于 NaN（`f32` 与 `f64` 之间也是）；两个全 null 的序列（长度相同）无论类型是否不同都相等，长度不同则不等；日期/字符串等其它类型对不同类型一律不等。
- **负长度**：`slice(offset, length=负数)` 返回空序列（polars 抛 `OverflowError`）；`Series::null(name, 负数)` 得到长度 0（polars 抛 `ComputeError`）。
- **`AnyValue` 的 `Eq`**：`AnyValue` 派生 `Eq`，是结构相等，所以 `AnyValue::Float64(nan) != AnyValue::Float64(nan)`；而 `Series::equals` 把 NaN 当作等于 NaN。

### Show

- **超范围的 Date**：polars 2.1.0 在 |天数| 超过约 9 570 万（chrono 的 ±262 143 年）时打印会 panic（`out-of-range date`；实测 `95_000_000` 能打印，`96_000_000` panic）。这里能打印到 ±110 000 000 天，超过则 `Show` 不 abort，输出占位文本 `<out-of-range date>`。
- **超范围的 Datetime**：`Int64` 微秒的全部取值都会输出文本（`+292277-01-01 ...` 这类）；polars 对超出 chrono 范围（约 ±26 万年）的值 panic。
- **空列名**：`pl.DataFrame([series])` 会把空列名改成 `column_N`，这里的 `DataFrame::new` 保留空名，所以对照数据里空列名只出现在 Series 用例（`series/empty_name`）。
- **字符宽度**：`char_width` 是 Unicode 宽度表的简化版（主要的东亚宽字符区间、emoji、组合字符），对照数据钉住了 ASCII、日文汉字、韩文、全角/半角形式、组合字符、零宽空格、CJK 扩展 B、`U+1F680` 区 emoji，以及 `U+FE0F` 接在文本符号后变成 2 列（这一条按 polars 的输出做成了一张基字符表）。与 polars 逐码点对照仍有出入（约 1.5 万个码点，主要是印度系等文字的组合符号 polars 算 0 列、西夏文/契丹小字等区间 polars 算 2 列、少数符号区间宽度不同）；冷僻字符的表格边框可能错位。
- **ZWJ 和修饰符序列**：ZWJ emoji 序列（如 `"👨‍👩‍👧"`）在这里按码点逐个计宽（6 列），polars 按整个序列算 2 列，表格边框会错位；肤色修饰符序列、键帽序列 `1️⃣`、组合型韩文字母同理。
- **折行**：只实现了硬折行（每行最宽 31 列）；comfy-table 在单词边界折行的行为只在宽字符的长串里才可能触发，没有对照。
