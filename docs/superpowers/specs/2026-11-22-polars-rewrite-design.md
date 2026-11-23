# smallbearrr/pandas 全面翻新设计（polars 方向）

- 日期：2026-11-22
- 负责人：lly
- 当前版本：0.8.0（2026-11-22 发布，main `5bcf47e`）
- 本文档范围：整体架构写到可以开工的程度；M1、M2 两个阶段写细；M3、M4 只写轮廓，开工前另行细化。

## 1. 为什么要翻新

`smallbearrr/pandas` 写于 MoonBit 早期。当时语言能力不够，很多地方只能凑合。0.8.0 只是让它能在新工具链上编译，结构问题都还在：

- 数据层：
  - 一列数据是 `enum SeriesData { Int(Array[Int]) ... }`；
  - null 位图是 `Array[Bool]`，并不是真正的位图；
  - `DataFrame` 的字段全是 `pub(all) mut`，外部可以随意改，改完内部状态就对不上了。
- 类型：浮点只有 Float32，没有 Int64、Float64、日期类型。
- 行为不一致：
  - 字符串 Series 相加时把两个数组拼接起来，而不是逐元素相加；
  - 类型不匹配时直接 `abort`，调用方没法处理；
  - `rename` 后旧的列名索引失效；
  - `sort` 实际排的是一份拷贝，原数据不变。
- 有 8 个零散的错误类型，其中 4 个是 priv，用户拿不到。
- 缺少 DataFrame 库最核心的能力：表达式、`group_by`/`agg`、`join`。

**目标定位**：做成 MoonBit 社区可以长期依赖的 DataFrame 基础库，设计对齐 polars。

## 2. 目标、非目标、反目标

### 2.1 目标

1. **数据模型对齐 polars/Arrow**：
   - 按列存储；
   - 每种类型有自己的数组，配真正的按位 null 位图；
   - 没有行索引；
   - 对外不可变，所有操作都返回新对象。
2. **以表达式 API 为核心**：`select`、`with_columns`、`filter`、`sort`、`group_by().agg()`、`join` 都接收表达式。
3. **统一错误处理**：只有一个公开错误类型 `PolarsError`。用户输入引起的问题一律 `raise`，不许 `abort`。
4. **四个后端都可用**：wasm、wasm-gc、js、native。核心包不依赖文件系统。
5. **文档就是测试**：示例写在 `.mbt.md` 里，随 `moon test` 一起执行。
6. **工程质量**：
   - 每个公开函数都有测试；
   - 核心算子有 `quickcheck` 性质测试；
   - 有 `moon bench` 基准；
   - 告警数为 0；
   - CI 覆盖 stable 和 nightly 两个工具链。
7. **为将来的 lazy 留好路**：表达式是纯数据（`enum`），不是闭包。“描述做什么”和“执行”分开，以后可以在上面加 lazy 模式和查询优化，不用重写。

### 2.2 非目标（这一轮不做）

- lazy 执行、查询优化器、流式处理（放到 1.0 以后）。
- 嵌套类型：List、Struct、Categorical、Decimal、带时区的 Datetime。
- 多线程并行。MoonBit 目前在 wasm/js 上没有线程。
- Parquet、Arrow IPC、数据库连接。
- 兼容旧 API。旧的 `lib/pandas` 在 M5 删除，只提供迁移说明。

### 2.3 反目标（做了就算失败，即使功能能用）

- 照搬 pandas 的行索引、`inplace`、`loc`/`iloc`。
- 公开类型暴露可变字段，让用户能改出不一致的状态。
- 用户输入错误时 `abort` 崩溃，比如列名不存在、类型不匹配、长度不一致。
- 核心包依赖 `moonbitlang/x/fs`，导致 wasm 用不了。
- 为了“像 polars”而写出不符合 MoonBit 习惯的 API，比如用字符串表示枚举选项（`keep: "first"` 这种）。
- 文档示例不经测试、和代码脱节。

## 3. 约束

- 工具链：moon 0.1.20261119（moonc v0.10.22）。CI 另外跑 nightly。
- 模块名仍为 `smallbearrr/pandas`（lly 选定的方案 A：同仓库、同包名重写）。是否改名，到 1.0 之前再决定。
- 版本节奏：新 API 能覆盖旧 API 的主要用法后，删除旧包并发布 0.9.0；之后每个阶段发一个 0.x；稳定后发 1.0。
- 依赖：核心包只依赖 `moonbitlang/core`。文件读写放在单独的包里，可以依赖 `moonbitlang/x/fs`。不再依赖 NyaCSV，CSV 解析自己实现。
- 开发环境：lab5（`ssh lab5`，先 `. /data/lly-moonbit/env.sh`）。lab5 根分区满，只能写 `/data/lly-moonbit/`。
- 所有实现工作交给 sonnet agent，按 `/root/.claude/CLAUDE.md` 第 8 节的多 agent 流程走。主会话只负责契约、合并、回归和汇报。
- commit、push、开 PR、合并、发布，每次都要 lly 确认。

## 4. 选过的方案

### 4.1 怎么对待现有代码（lly 选 A）

- **A（选定）**：同仓库、同包名，从头重写，不留兼容层。现有下载量只有 105，破坏兼容的代价小。
- B：重写并换新包名。名实相符，但下载量和关注从零开始，还要定命名空间。
- C：在旧代码上渐进重构。整个数据层都要换，会长期背着两套结构，工作量最大。

### 4.2 列在内部怎么表示（lly 认可方案 1）

- **方案 1（选定）**：类型化枚举加 Arrow 式数组：
  ```
  Column = enum { Int64(PrimArray[Int64]); Float64(PrimArray[Double]); Bool(BoolArray); Str(StrArray); ... }
  ```
  用 `match` 分发，编译器检查是否穷尽，热路径不装箱。polars 自己也是这个模型。
- 方案 2：trait 对象（类似 arrow-rs 的 `dyn Array`）。MoonBit 的 trait 对象不支持泛型方法，向下转型也别扭，而基础库并不需要用户自定义列类型。
- 方案 3：编译期泛型 `Series[T]`。DataFrame 里各列类型不同，最后还是要擦除类型，等于多绕一层。

### 4.3 落地方式（lly 认可）

在同一仓库新建一套包，与旧的 `src/lib/pandas` 并存，互不影响，各阶段可以分别合进 main。新 API 能覆盖旧用法后（M5），删除旧包并发布 0.9.0。不在旧文件上原地改，因为那样会长期编译不过，也没法并行开发。

## 5. 架构

### 5.1 包结构

| 包路径 | 导入别名 | 内容 | 依赖 |
|---|---|---|---|
| `smallbearrr/pandas/pl` | `@pl` | 唯一面向用户的核心包：数据类型、Series、DataFrame、Expr、CSV 字符串读写 | 只依赖 core |
| `smallbearrr/pandas/pl/fs` | `@plfs` | `read_csv(path)` 和 `write_csv(df, path)` 的文件封装，仅 native/js | `@pl`、`moonbitlang/x/fs` |
| `smallbearrr/pandas/pl/internal/...` | — | 构建方可选的内部拆分，例如 `bitmap`、`kernels` | — |

- 用户只需要 `import "smallbearrr/pandas/pl"`，写法上接近 Python 的 `import polars as pl`：`@pl.col("a")`、`@pl.DataFrame::new(...)`。
- 内部要不要再拆包、怎么拆，由构建方决定。但 `@pl` 的公开 API 就是契约，以 `pkg.generated.mbti` 为准。

### 5.2 数据层（M1）

- **`Bitmap`**：按位存储，底层是 `FixedArray[UInt64]`，带 `offset` 和 `length`，支持零拷贝切片。
  - 位为 1 表示“有效”，和 Arrow 一致。
  - 没有 null 的列，validity 为 `None`，不分配位图。
- **`PrimArray[T]`**：`values : FixedArray[T]`、`offset`、`length`、`validity : Bitmap?`。用于 Int32、Int64、Float32、Float64、Date（Int32，自 1970-01-01 起的天数）、Datetime（Int64，自 epoch 起的微秒数，无时区）。
- **`BoolArray`**：值本身也用 `Bitmap` 存储。
- **`StrArray`**：v1 内部先用 `FixedArray[String]` 加 validity。这是抽象类型，以后改成 offsets 加 UTF-8 缓冲区不影响 API。MoonBit 的 `String` 是 UTF-16，过早改用 UTF-8 缓冲区，每次访问都要解码，不划算。
- **不可变**：数组一旦构建完成就不再修改。构建用 `ArrayBuilder`。`slice` 是零拷贝的，共享底层缓冲。
- **`DataType`**（公开枚举）：`Boolean`、`Int32`、`Int64`、`Float32`、`Float64`、`String`、`Date`、`Datetime`、`Null`。`Null` 用于全是 null 的列和 `lit(null)`。
- **`AnyValue`**（公开枚举，对应 polars 的 AnyValue）：用于单个值的取出、字面量、`row()` 等。各分支和 `DataType` 一一对应，外加 `Null`。
- **`Series`**（抽象类型）：一个名字加一个 `Column`。所有公开类型都是抽象类型，不暴露字段。
- **`DataFrame`**（抽象类型）：
  - 内部是 `Array[Series]`，加一个列名到下标的映射。
  - 构造时校验：所有列长度相同，列名不重复。
  - 高度、宽度现算，不单独存 `shape`。

### 5.3 错误

```
pub suberror PolarsError {
  ColumnNotFound(String)
  DuplicateColumn(String)
  SchemaMismatch(String)      // 类型不匹配
  ShapeMismatch(String)       // 长度或形状不匹配
  OutOfBounds(String)
  InvalidOperation(String)    // 当前类型不支持该操作，包括严格 cast 失败（2026-11-23 改为与 polars 一致）
  ComputeError(String)        // 其它运行时错误，例如超范围日期的转换
  ParseError(String)          // CSV/文本解析，message 里带行号和列号
}
```

- 所有可能失败的公开函数都写 `raise PolarsError`。只有内部不变式被破坏（属于库自身的 bug）时，才允许 `abort`。
- 错误信息用英文，包含具体的列名、类型和位置。

### 5.4 null 语义（与 polars 一致）

- 算术、比较中有任一侧为 null，结果为 null。
- `&`、`|` 用 Kleene 三值逻辑：`false & null = false`，`true | null = true`。
- 聚合跳过 null：`sum` 的结果全为 null 时得 0；`mean`、`min`、`max` 全为 null 时得 null；`count` 只数非 null，`len` 数全部。
- 浮点 `NaN` 和 null 是两回事，`is_nan` 和 `is_null` 分开。
- `filter` 时，谓词为 null 的行丢弃。
- 排序时 null 默认排在最前，可以用 `nulls_last=true` 改成排在最后，与 polars 默认一致。

### 5.5 类型提升（主会话决定：以 polars 为准）

二元运算的结果类型按 polars 的 supertype 规则确定。下面列出本库涉及的类型，表中没有的组合也以 polars 为准：

- Int32 与 Int64 得到 Int64。
- Float32 与 Int32、Int64、Float64 中的任意一个运算，得到 Float64。只有 Float32 与 Float32 运算，结果才是 Float32。
- 整数 `/` 整数得到 Float64（真除法）；整除另提供 `floor_div`。
- Date、Datetime 在 M2 只支持比较运算。日期算术不在本轮范围内。
- Boolean 参与算术时报 `InvalidOperation`。
- String 只支持比较运算，以及 `str` 命名空间下的操作。
- 不兼容的类型报 `SchemaMismatch`。

**字面量是弱类型，和 polars 一致：**

- `lit_int(Int64)` 与整型列运算时，如果字面量的值在列的类型范围内，就采用列的类型。例如 `col(Int32) + lit_int(1)` 的结果是 Int32。
- `lit_float(Double)` 与 Float32 列运算时，结果保持 Float32。
- 字面量单独出现时（不和列运算），整数默认 Int64，浮点默认 Float64。
- 便捷字面量的参数类型：`lit_int` 取 `Int64`，`lit_float` 取 `Double`，`lit_str` 取 `String`，`lit_bool` 取 `Bool`。另外提供 `lit(AnyValue)`，类型按 `AnyValue` 本身来定，不做弱类型处理。

### 5.6 表达式（M2）

`Expr` 是公开的抽象类型，内部是纯数据的枚举，比如 `Column(name)`、`Literal(AnyValue)`、`Binary(op, l, r)`、`Unary`、`Agg`、`Alias`、`Cast`、`Ternary`、`Function(...)`。由求值器在 DataFrame 上求值。

- **构造**：`col(name)`、`cols(names)`、`all()`、`lit(AnyValue)`，以及便捷字面量 `lit_int`、`lit_float`、`lit_str`、`lit_bool`。
- **运算符**：
  - `+`、`-`、`*`、`/`、`%`、取负，靠 `Add`/`Sub`/`Mul`/`Div`/`Mod`/`Neg` trait；
  - `&`、`|` 靠 `BitAnd`/`BitOr`；
  - 比较必须写成方法：`eq`、`neq`、`gt`、`ge`、`lt`、`le`，因为 MoonBit 的 `==` 和 `<` 不能返回 `Expr`；
  - 取反用 `not_()`。
- **常用方法**：
  - `alias`、`cast(DataType, strict~)`；
  - `is_null`、`is_not_null`、`fill_null(Expr)`、`fill_null_strategy(FillStrategy)`；
  - `is_in`、`between`；
  - `abs`、`round`、`sqrt`、`log`、`exp`；
  - `when(cond).then(e).otherwise(e)`。
- **聚合**：`sum`、`mean`、`min`、`max`、`count`、`len`、`n_unique`、`first`、`last`、`std(ddof~)`、`var(ddof~)`、`median`、`quantile(q, QuantileMethod)`。
- **窗口和序列操作**：`shift`、`diff`、`cum_sum`、`cum_max`、`rank`、`over(partition_by)`。`over` 可以推迟到 M3。
- **命名空间**：`e.str().contains/starts_with/ends_with/to_lowercase/to_uppercase/len_chars/replace/strip`，`e.dt().year/month/day`。命名空间的实现方式由构建方决定，但必须是这种调用形状。
  - **`str().contains`、`str().replace` 默认按正则处理（主会话决定，与 polars 一致）**：
    - 正则引擎用 `moonbitlang/core` 自带的 `Regex`。它的语法和 Rust regex 不完全相同，需要在文档里写明差异；测试只使用两者共有的语法。
    - 参数 `literal~ : Bool = false` 为 `true` 时，改为按字面量匹配。
    - 正则写得不合法时报 `ComputeError`，错误信息里带上 pattern。
    - `replace` 只替换第一处匹配，另外提供 `replace_all`，与 polars 一致。
- **输出列名**：默认取表达式最左边的列名；`lit` 的输出列名是 `literal`；`alias` 可以覆盖。不同表达式输出同名列时，报 `DuplicateColumn`。
- **广播**：长度为 1 的结果（字面量或聚合）在 `select`、`with_columns` 中会广播成 DataFrame 的高度。其它长度不一致的情况报 `ShapeMismatch`。

### 5.7 DataFrame 和 Series 的 API

**DataFrame 的立即执行 API（M1、M2）：**

- 构造与基本信息：
  - `DataFrame::new(Array[Series])`、`DataFrame::empty()`；
  - `height`、`width`、`shape`、`columns`、`dtypes`、`schema`（返回 `Array[(String, DataType)]`，按列顺序）；
  - `column(name)`、`get_column_index(name)`。
- 选取与变换：
  - `select(Array[Expr])`、`with_columns(Array[Expr])`、`filter(Expr)`；
  - `sort(by : Array[Expr], descending~ : Array[Bool], nulls_last~, stable)`：一律稳定排序；
  - `head(n)`、`tail(n)`、`slice(offset, len)`、`gather(indices)`；
  - `unique(subset~, keep : UniqueKeep, maintain_order~)`；
  - `drop(names)`、`rename(Map[String, String])`；
  - `fill_null(...)`、`drop_nulls(subset~)`、`null_count()`、`with_row_index(name~, offset~)`；
  - `vstack`、`hstack`，以及 `concat(Array[DataFrame], how : ConcatHow)`。
- 统计与输出：
  - `describe()`；
  - `row(i) -> Array[AnyValue]`、`get(i, name) -> AnyValue`；
  - `equals(other)`（null 与 null 视为相等）；
  - `Show`：仿照 polars 的表格输出，带 `shape: (h, w)`、列名行、dtype 行，行数多时中间折叠。

**Series 的 API：**

- 构造：`Series::int64(name, Array[Int64])`、`Series::int64_nullable(name, Array[Int64?])`，其余类型按同一命名规则（`int32`、`float32`、`float64`、`bool`、`str`、`date`、`datetime`）。
- 算术与逻辑（主会话决定）：
  - 核心库的 `Add` 等 trait 签名里没有 `raise`。所以 **Series 不实现运算符 trait**，改为提供会 raise 的方法：`add`、`sub`、`mul`、`div`、`floor_div`、`rem`、`neg`、`and_`、`or_`、`not_`，以及比较方法 `eq`、`neq`、`gt`、`ge`、`lt`、`le`。这些方法都是 `raise PolarsError`。
  - **运算符只在 `Expr` 上提供**。`Expr` 的运算符只负责构造表达式树，本身不会失败；类型错误等到 `select`、`filter` 这类求值操作时才报出来。
- 访问：`len`、`dtype`、`name`、`rename`、`get(i) -> AnyValue`、`null_count`、`slice`、`cast`、`to_array` 等。
- Series 上的聚合、比较等方法与表达式同名，直接在 Series 上调用，不用先包成 DataFrame。

**M3 再做：**

- `group_by(Array[Expr]).agg(Array[Expr])`：基于哈希。结果顺序默认不保证；传 `maintain_order=true` 时保持各组首次出现的顺序。
- `join(other, on~/left_on~/right_on~, how : JoinHow)`：`how` 支持 Inner、Left、Right、Full、Semi、Anti、Cross；同名列加后缀，`suffix~` 默认 `"_right"`。
- `pivot`、`unpivot`（melt）、`explode` 视进度而定。

**所有选项参数都用枚举，不用字符串**：`JoinHow`、`UniqueKeep`、`ConcatHow`、`FillStrategy`、`QuantileMethod` 等。

### 5.8 IO（M4）

- `@pl.read_csv_str(text, options~ : CsvReadOptions)` 和 `@pl.write_csv_str(df, options~)`：纯字符串接口，四个后端都能用。
  - 支持的选项：分隔符、是否有表头、引号字符、哪些值算 null、指定部分列的类型（`schema_overrides`）、类型推断扫描的行数、只读前 n 行、跳过前 n 行。
  - 解析遵循 RFC 4180：字段内可以有引号、换行、`""` 转义，支持 CRLF。
- **类型推断**：依次尝试 Int64、Float64、Boolean（只认 `true` 和 `false`，大小写不敏感）、Date（ISO `YYYY-MM-DD`），都不行就是 String。
  - 负数、科学计数法都要支持。
  - 整数超出 Int64 范围时退为 Float64。
- **文件读写**：`@plfs.read_csv(path, options~)`、`@plfs.write_csv(df, path, options~)`。目标文件不存在时自动新建。
- JSON（ndjson）读写视进度而定。

## 6. 阶段划分

| 阶段 | 内容 | 完成标准 |
|---|---|---|
| **M1 数据层** | Bitmap、各类数组和 builder、DataType、AnyValue、Series（构造、取值、切片、cast、null_count）、DataFrame（构造校验、列访问、head/tail/slice/gather、Show）、PolarsError | 四个后端测试全部通过；Bitmap 和切片有 quickcheck 性质测试；有基础 bench |
| **M2 表达式与立即执行操作** | 5.4–5.7 节的表达式、select/with_columns/filter/sort/unique/fill_null/drop_nulls/concat/describe、聚合、when/then、str/dt 命名空间 | 5.4–5.7 节列出的 API 全部实现并通过测试；新增 `docs/migration.md`，见下方说明 |
| **M3 分组与连接** | group_by/agg、join（所有 how）、over | 与 polars 行为对照测试 |
| **M4 IO** | CSV 读写（字符串接口和 fs 包），可选 ndjson | 覆盖 RFC 4180 各种边界情况 |
| **M5 发布 0.9.0** | 删除 `src/lib/pandas` 和旧的 `src/main`；README 改成 `README.mbt.md`；写迁移指南；CI 跑 stable 和 nightly；bench 基线 | 告警数为 0；lly 确认后发布 |

**迁移对照表（主会话决定）**

`docs/migration.md` 在 M2 新建，后续各阶段持续补充。

- 内容：把旧 `lib/pandas` 的每个公开函数逐一列出，写明在新 API 里对应哪一个。
- 有意不做的函数要单独列成一节，并写清原因，例如：
  - `add_row`、`drop_row`、`swap`、`erase` 这类原地修改行的操作，与“不可变”原则冲突。新写法：用 `vstack`/`concat` 加行，用 `filter`/`gather` 删行或选行。
  - `to_init_repr` 等只服务旧实现的内部表示。
- polars 里也有的函数（例如 `transpose`、`sum_horizontal`/`min_horizontal`/`max_horizontal`、`sin`/`cos`/`tan`、`product`、`any`/`all`、`reverse`、`arg_sort`、`is_sorted`、`gather_every`、`to_dict`），按 polars 的签名放进新 API；放进哪个阶段由构建方决定。
- M5 发布前，主会话会把对照表交给 lly 确认。
- `read_csv`、`write_csv` 属于 M4，不计入 M2 的完成标准。

每个阶段结束时开一个 PR 合进 main。M1–M4 期间旧包还在，所以中途合并不会影响已发布的版本。是否在中途发预览版（如 0.9.0-alpha），届时再问 lly。

## 7. 质量要求（每个阶段都适用）

- 先写测试再实现。每个公开函数至少有正常路径、null 路径、错误路径三类测试。
- 核心算子要有 `@quickcheck` 性质测试，例如：
  - `filter` 后的长度等于谓词为真的个数；
  - `sort` 稳定，且结果有序；
  - `slice` 后再 `concat` 能还原原数据；
  - Bitmap 的位运算与按 Bool 数组逐个计算的结果一致。
- **行为对照**：凡是本文没写清的语义，以 polars（Python）的行为为准。具体做法如下（由主会话决定）：
  - **环境**：M1 开工前，主会话在 lab5 上建一个 Python venv，路径是 `/data/lly-moonbit/polars-venv`，装 PyPI 上当时最新的稳定版 polars，并把版本号写进 `docs/golden/README.md`。
  - **对照数据怎么出**：需要对照的场景，先写一个 polars 脚本，放在 `docs/golden/scripts/` 下，由它生成期望结果，存成 JSON，放在 `docs/golden/` 下并提交。MoonBit 测试读取这些固定的 JSON 来比对，不在测试运行时调用 Python。
  - **适用范围**：NaN 与 null 的排序、join 时的 null 键、`describe`、`quantile` 插值、类型提升，这几类必须按上面的方式对照。
  - **测试注释**：每个对照用例都要写明对应的 polars 写法。
  - **差异处理**：如果因为 MoonBit 的限制只能和 polars 不一样，要写进 `docs/migration.md` 的“与 polars 的差异”一节。
- **性能**：不设硬指标，但每个阶段都要在 `moon bench` 里记录 100 万行规模下 filter、sort、group_by、join、CSV 解析的耗时，作为基线。明显的 O(n²) 写法不许出现。
- `moon check --target all` 的告警数为 0。所有公开 API 都写文档注释。

## 8. 交给构建方决定的事

- 内部包怎么拆，以及各个算子的具体算法：排序算法、哈希表实现、join 策略。
- `str()`、`dt()` 命名空间的具体实现方式。
- `Show` 表格输出的细节：列宽、折叠阈值。
- builder API 的具体形状。
- 本文没有列出、但 polars 中有的便捷方法，只要不违反第 2 节，可以自行补充；补充的要写进汇报。
