# 与 polars 的已知差异：拼接和 describe（T11）

数据：`docs/golden/concat_describe.json`（`scripts/concat_describe.py` 生成，polars 2.1.0，共 1033 条：`concat` 609、`describe` 146、`append` 114、`vstack` 99、`hstack` 46、`to_frame` 19）。除下面几条外，值、结果类型、报错变体和文案都与 polars 一致。

## 接口上的差异

| 项 | polars | 本库 | 原因 |
| --- | --- | --- | --- |
| Python 的 `ValueError` / `TypeError` | 空列表 `concat` 抛 `ValueError("cannot concat empty list")`；`describe` 的百分位越界抛 `ValueError`、无列抛 `TypeError` | 一律 `InvalidOperation`，文案同 polars；JSON 里 `polars_error` 记原类名 | 本库没有对应变体（M2 错误种类映射允许任务自定） |
| `concat` 的 `how` | 还有 `diagonal_relaxed`、`horizontal_extend`、`align*` | 只有 `Vertical`、`VerticalRelaxed`、`Horizontal`、`Diagonal` | 设计只要求这四种 |
| `describe` 的 `percentiles` | 可以传单个 float 或 `None` | 只收 `Array[Double]`，空数组等于 `None` | 没有联合类型 |

## 与 polars 对不上的取值

- **`describe` 里超出 Python 日期范围的值**：polars 的 `describe` 用 Python 的 `str(date)`/`str(datetime)`，年份不在 1..9999 时 Python 抛 `ValueError`（例如 `year 0 is out of range`）。本库照常输出（年份四位以上或带负号，不 abort），没有对照用例。
- **浮点 `std`（和 `mean`）的末位**：polars 在 `describe(percentiles=[])`（不排序）里对同一输入每次运行的 `std` 末位可以不同（10 个整数 `[3, 1, 2, 5, 4, 8, 6, 7, 9, 10]` 的 `std` 在 `3.0276503540974913`、`…917`、`…92` 之间变；5 个浮点 `[1.5, 2.5, 0.1, -3.0, 7.0]` 的 `std` 在 `3.653354622809015` 和 `…0152` 之间约各一半），原因是分块合并的舍入随线程调度而变；本库是 T2 的两遍算法。另外，同一输入的 `std` 末位还随 polars 线程池的大小而变（`d_all` 的 Int64 列 `std` 在 4 个线程时是 `2848326498395535.0`，线程更多时可以是 `…534.5`，差 1 ulp）。生成数据时的处理（终审修复轮）：(1) `concat_describe.py` 在导入 polars 之前把 `POLARS_MAX_THREADS` 固定为 4，数据是 4 线程下的结果（脚本在 2、16 个线程的环境变量下各跑一遍，sha256 相同）；(2) `describe/pcts/empty/small` 的输入 `d_small` 改成 8 行（2 的幂）、各部分和都精确的数据（`x = [3,1,2,5,4,8,6,7]`，`y = [0.5, ..., 7.5]`），polars 在 1000 次运行里结果不变；`pcts/empty/pct`（5 个浮点）和 `pcts/empty/all` 按 id 排除，不再生成（`percentiles=[]` 不排序，这两个输入的 `std` 在 100 次运行里有 1 到 30 次末位不同）；(3) 其余的 `describe` 用例由 `settle_describe` 各跑 100 次，除 `mean`/`std` 的 Float64 单元格外所有值必须完全相同（否则脚本报错），有变化的单元格取 100 次里的最小值（本轮没有出现需要取最小的单元格）。其余带百分位的 `describe` 先排序，结果稳定。生成脚本两遍的 sha256 因此一致。测试对 `mean`、`std` 两行仍用相对 1e-12 的容差（`describe` 例外，不属于 4 ulp 的收紧范围），其余行逐位比较（`min`、`max`、百分位、`count` 都逐位相同）。
- **正负极大值相消时的 `mean`**：整数列 `[1, -1, 0, Int64 最大值, Int64 最小值, null, 3000000000]` 的 `mean` 取决于 polars 走哪条路径（审查实测）：单列表的默认 `describe()` 在 300 次运行里都是 `500000000.0`，与本库相同；多列表的默认和 `percentiles=[0.5]` 在 300 次里都是 `500000085.3333333`（确定，但与本库不同；350 行时是 `500000058.02666664`）；`percentiles=[]` 每次运行随机（`5e8`、`500000085.33`、`499999914.67` ……）。本库按固定顺序求和，得 `500000000.0`。所以对照数据里没有这类输入（`describe` 的整数列用 ±2^52 代替极值；极值只在每个部分和都精确的 `d_big` 里出现）。
- **`describe` 先排序**：polars 在有百分位时先把数值和时间列排序，再算全部统计量；本库按原顺序算。除浮点 `mean`/`std` 的末位（容差内）外，还有两处可见差异（审查实测，输入是确定的）：
  - **零的符号**：同一 `Float64` 列里同时有 `0.0` 和 `-0.0` 时，排序改变并列元素的顺序，`min` 和百分位行里零的符号可能不同。例：`[1.5, 0.0, -0.0]`，`percentiles=[0.123456789]`，`interpolation="higher"`，polars 得 `0.0`，本库得 `-0.0`。polars 自己在同一列里 `min` 与 0% 行的符号也可能不一致，不模拟它的排序就对不上。
  - **溢出的 `std`**：`[1e308, 1e308, -1e308, 3.0, null, 0.1]`（审查各跑 100 次）：单列表的默认和 `percentiles=[0.5]` 里 polars 的 `std` 是 `NaN`（100/100），本库得 `inf`；有第二列时默认和 `[0.5]` 都是 `inf`（100/100，与本库相同）；`percentiles=[]` 不论单列还是两列都随机（`inf` 54 次、`NaN` 46 次）。`Series.std()` 得 `inf`。`mean` 两边都是 `inf`。所以只有单列表的排序路径稳定地对不上，`[]` 路径约一半时间对不上。

- **三个及以上表的 `Vertical` 拼接**：polars 的 `pl.concat` 用 rayon 的 `fold`/`reduce`，种子是清空的第一个表，不是简单的左折叠，结果还与线程数有关（`POLARS_MAX_THREADS=1` 与 ≥2 在 5 个表的输入上不同），所以没有确定的模型能完全对上。本库保持确定的左折叠（先第一个有列的表，再逐个检查）。审查实测的差异：`concat([empty, F, empty, F])`（`F` 有一列 `a`）polars 成功（4 行），本库报 `unable to append to a DataFrame of width 1 with a DataFrame of width 0`；`[empty, F3, F1, empty]`（`F3` 三列、`F1` 一列）polars 报 `width 1 with width 0`，本库报 `width 3 with width 1`。3000 个随机输入里 21 个报错选择不同（除上面第一例外都是“报错对报错”）。两个表、或所有表同宽且列名相同时不受影响。开头有无列的表也不保证：`concat([empty, F(c), F(b), F(a)])`（Int64、各一行）polars 报 `"b" and "a"`，本库（每个表都和第一个有列的表比较）报 `"c" and "b"`；3000 个例子的网格里，开头有无列的表且后面有 3 个以上非空表时 279 个报错选择不同，没有开头无列的表时 0 个。本库的 `concat` 文档注释里“plain left fold”指每个表都与第一个有列的表比较，不是 polars 的折叠顺序。

## 与 polars 一致、容易被误以为是差异的行为

- `describe` 的列类型：数值、`Boolean`、`Null` 列的结果是 `Float64`（`Boolean` 按 0/1，没有 `std` 和百分位；`Null` 只有 `count`、`null_count`）；`String`、`Date`、`Datetime` 列的结果是 `String`，`count` 和 `null_count` 也是文本（`"4"`），其余是 Python `str` 的结果：`Datetime` 只有微秒部分非零时才带 `.ffffff`（`1970-01-01 00:00:00`，`1970-01-01 00:00:00.000005`）。`Date`、`Datetime` 的百分位是“物理值的分位数再转回类型”，所以线性插值在日期上截断到整天（向零）。
- `describe` 的行标签是 `f"{p * 100:g}%"`（六位有效数字，`33.3%`、`1e-05%`、`0%`、`-0%`）；百分位升序排列（相同的值报 `DuplicateColumn`，`-0.0` 和 `0.0` 算不同）；列名为 `statistic` 的表报 `DuplicateColumn`。
- `concat` 的 `Vertical`：`Null` 类型的列接在别的类型后面按该类型补 null；`Null` 列在前、别的类型在后则是 `SchemaMismatch`（`type Int64 is incompatible with expected type Null`）。开头没有列的表被丢掉，之后没有列的表报宽度不符。`VerticalRelaxed` 里数字或日期和 `String` 的公共类型是 `String`（`supertype` 对这些对返回 `None`，`concat` 另外补上），按逐帧累加：`bool, i32, date` 得 `Int32`，`bool, date, i32` 报 `failed to determine supertype of bool and date`。
- `hstack`（和横向 `concat`）里重复列名和高度错误谁先报，polars 按列数分两条路径：新旧列合计不超过 4 列时，逐列先查高度、再查后面有没有同名列（所以别的列高度不对时，和已有列重名也先报重名）；超过 4 列时逐列先查高度、再查是否和前面的列重名。本库按同样的规则（`concat_validate_columns`），在 3276 种组合上与 polars 对过；空表（无列）调用 `hstack` 时，只要有高度为 0 的新列，报错里 `does not match` 后面写第一个高度为 0 的新列（`height of column 'a' (0)`），否则写 `DataFrame height (0)`（审查在 283 个例子上验证，已加进对照数据）。M1 的 `DataFrame::new` 对重名和高度的先后、文案（没有 `could not create a new DataFrame:` 前缀）与这里不同，没有改。
- `Series::append` 和 `vstack` 里 polars 的 `append` 是原地修改，本库返回新序列。
