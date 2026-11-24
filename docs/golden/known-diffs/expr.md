# 与 polars 的已知差异：Expr、select、with_columns（T7）

数据：`docs/golden/expr.json`（`scripts/expr.py` 生成，polars 2.1.0；表达式由 `src/pl/expr_golden_cases_test.mbt` 按用例 id 构造）。下面几处本库与 polars 不同。对应用例在 JSON 里带 `"restricted": true`（只要求 `InvalidOperation`）、`"known_diff"`（`result` 是本库的结果，polars 的 schema 在 `polars_schema`）或 `"polars_error"`（polars 的异常类，本库用另一个变体）。

## spec 规定的差异

| 场景 | polars | 本库 |
| --- | --- | --- |
| 单独出现的弱整数字面量（`lit_int(1)`、`lit_int(1) + lit_int(2)`、`select([lit_int(1)])`） | dyn int，物化成 `Int32`（值放不下时 `Int64`，超过 `Int64` 时 `UInt64`、`Int128`） | `Int64`（spec 5.5：字面量单独出现时整数默认 `Int64`）。`known_diff: "dyn-literal-default"`，约 74 条 |
| 算术作用于 `Boolean`、`String`、`Date`、`Datetime`；`&`、`|`、`~` 作用于整数 | 很多组合能算（`bool + i32`、`str + str`、`i32 & i32` 按位） | `InvalidOperation`（`restricted`，与 `arith.md` 同一条规则） |

“弱”的含义和 polars 一致：`col(Int32) + lit_int(1)` 是 `Int32`，`col(Int32) + lit_int(3_000_000_000)` 是 `Int64` 且不回绕，`col(Float32) * lit_float(1e300)` 是 `Float32`（值为 inf）。弱字面量在 `alias`、取负、两个弱字面量之间的 `+ - * // %` 里保持弱（`(lit_int(1) + lit_int(2)) + col(Int32)` 是 `Int32`），`/` 和 `cast` 之后变强；这也与 polars 一致。

## 别的差异

- **`AnyValue::Null` 的类型是 `Null`**：polars 的 `pl.lit(None, dtype=pl.Int32)` 是带类型的 null。本库没有带类型的 null 字面量，要用 `lit(AnyValue::Null).cast(DataType::Int32)`（对照用例 `cast/lit-null->i32`）。因此 `lit(Null) + lit_int(1)` 得 `Int32`（与 polars 一致：弱整数在 `Null` 旁取 `Int32`），而 `typed null` 的用例没有。
- **弱字面量的整数溢出**：polars 的 dyn int 是 128 位。`lit_int(MAX) + lit_int(1)` 在 polars 里是 `UInt64`，`lit_int(2^62) * lit_int(4)` 是 `Int128`；`(lit_int(1) // lit_int(0)) + col(Int32)` 是全 null 的 `Int32`。本库在 `Int64` 里算：溢出时按 `Int64` 回绕（`ll/add/imax,i1` 等的 `result` 是本库的），除以 0 得 `Int64` null，结果不再是弱的。这些用例的 `result` 是本库的 `Int64` 结果（脚本把弱字面量换成 64 位强字面量再算一遍得到）；`weak/(imax+1)+i32` 的 polars 结果是 `Int128`，对不上任何本库类型，脚本把它跳过（打印 `SKIP`）。
- **`with_columns` 里重名**：polars 报 `ComputeError`（`the name 'q' passed to `LazyFrame.with_columns` is duplicate`），本库按 spec 报 `DuplicateColumn`，文案取 polars 的。`select` 里重名两边都是 `DuplicateError`（文案一致）。
- **字面量 `cast` 失败的文案**：polars 说 `conversion from `i128` to `i32` failed in column 'scalar' ...`，本库是 `i64` 和 `'literal'`。没有对照用例，`expr_test.mbt` 只钉住 `cast` 的列名行为。
- **整个表上的 `all()` 遇到不能算的列**：`all() + lit_int(1)` 遇到 `str`/`date` 列时，polars 报它先遇到的那一列的错（文案各不相同），本库按列顺序报第一列的 `InvalidOperation`。对照用例标 `restricted`。
- **polars 的优化器**：`col + 0` 被简化成 `col`，所以 `Float32 -0.0 + lit(0)` 在 polars 里仍是 `-0.0`（只在对有多行的表做急切的 `select` 时成立；lazy 的 `.collect()` 和只有一行的表得 `+0.0`，`Float32`、`Float64` 都探测过）；本库一律按 IEEE 算得 `0.0`。没有对照用例（`cw/add/f32/0` 和 `cw/add/f32/f0.0` 在脚本里被跳过）。

## 表达式引擎与 Series 运算符不同、本库跟着表达式引擎的地方

`T1` 的 `Series` 运算符按 Series 的行为对照；`Expr` 求值时在调用它们之前多做了下面几项检查（`eval.mbt` 的 `compare_check`、`logic_check`），因为 polars 的表达式引擎和 Python 的 Series 运算符在这几处不同：

- `String` 与 `Date`/`Datetime` 比较：表达式引擎报 `InvalidOperation`（`cannot compare 'date/datetime/time' to a string value ...`），Series 运算符按文本比较（`arith.md`）。`Expr` 跟表达式引擎。
- `&`、`|` 的类型错误文案：`Boolean` 与数字报 `ComputeError`（`& on Boolean and Int32 is not supported`），含 `String` 报 `InvalidOperation`（`` `bitand` operation not supported for dtype `str` ``），两个 `Date` 报 `InvalidOperation`（`& not allowed on date and date`），与 Series 运算符的 `SchemaMismatch` 不同。
- **除数是长度 1 的 `Series`（字面量）时，polars 用倒数相乘**：`x / y` 算成 `x * (1 / y)`，`//` 是 `floor(x * (1 / y))`，`%` 是 `x - y * floor(x * (1 / y))`（浮点，以及 `/` 的整数）；左边也是长度 1 时不这样。结果可能和逐个除差最后一位（`2147483647 / 3e9` 是 `0.7158278823333333`，不是 `...34`；`Float32` 的 `3e38 // 1.5` 是 `2.0000001e38`，不是 `2e38`）。polars 2.1.0 实测 Series 级的 `s1 / s2`（`s2` 长度 1）行为相同，所以 T8 把这条下沉到了 `arith.mbt` 的内核（`Series::div`、`floor_div`、`rem`），`eval.mbt` 里的 `scalar_divisor` 已删除。

## 类型映射和个别类型的差异（终审修复轮补记）

- **`Null / Float32`（表达式）是 `Float64`，polars 的表达式引擎得 `Float32`**：`select([col("n") / col("f")])`，`n` 是 `Null` 列、`f` 是 `Float32` 列。`Series::null(..).div(f32)` 在 polars 里确实是 `Float64`（`arith.md` 记了这一条），本库的 `Expr` 直接用了同一个内核，所以两边的类型不同；`f / n` 两边都是 `Float32`。结果全是 null，只有类型不同，没有改。
- **polars 里是 `Int8`/`Int16`/`UInt32` 的结果，本库映射成 `Int32`/`Int64`，映射后的后续运算不再有那些类型的位宽和回绕**：
  - `dt().day()` 等本库是 `Int32`，`.sum()`、`.cum_sum()` 仍是 `Int32`；polars 里 `Int8` 的和先加宽成 `Int64`。只有超过约 7e7 行才会溢出，才有差别。
  - 无符号减法：`col("a").cum_count(reverse=true) - col("a").n_unique()`（3 行）在 polars 里是 `[0, 4294967295, 4294967294]`（`UInt32` 回绕），本库是 `[0, -1, -2]`。`len() - k`、`with_row_index` 之后 `index - k`、`null_count()` 的结果、非 `average` 的 `rank`、`str().len_chars() - k` 都一样。本库的行为更合理；依赖回绕的代码迁移后会看到不同。
- **`log` 作用于整数列、旁边有 `Float32` 操作数**：`col("f32") + col("i32").log()`、`col("f32").fill_null(col("i64").log())` 在 polars 里是 `Float32`（`log` 按 `Float32` 精度算，如 `2.5986123`），本库是 `Float64`（`2.5986122886681096`）。`sqrt`、`exp` 作用于整数、`log` 作用于 `Float64` 列时 polars 不这样，这像是 polars 规划里的怪癖，没有跟。

## 错误的先后：类型解析错误先于缺列和重名（终审修复轮）

polars 在规划表达式时就会发现一部分类型错误（`date * i64`、`~date`、`f64 & date`），它们先于“缺列”和“输出重名”报出。本库现在也是这个次序：`select` 对每个表达式依次查缺列、类型解析错误、重名；`with_columns` 先查所有表达式的缺列，再对每个表达式查类型解析错误和重名（`eval.mbt` 的 `plan_check`：把表达式在一个无行的表上先算一遍，只保留下面三类错误，别的错误留给真正的求值）。这次预演只在可能出错时做：表达式里有 `&`、`|`、`~`，或者有算术运算而且涉及时间类型（`Date`/`Datetime` 列或字面量、转成它们的 `cast`、`str().to_date()` / `to_datetime()` 的结果、带时间类型填充值的 `shift`）；预演用的表只含表达式读到的列，`is_in` 的值集合换成同类型的空 Series，所以代价与表的宽度和集合大小无关。

- 三类错误是按**错误文案**判断的（`is_plan_time_error`）：含 `Date`/`Datetime` 操作数的算术（`operation not supported for dtypes ...` 带 `date`/`datetime`，以及 ` not allowed on `；例外：两边都是时间类型的减法 `Date - Date`、`Datetime - Datetime` 在 polars 里合法（得 `Duration`，本库没有这个类型），只在运行时报错，不算规划错误，所以后面的缺列和重名先报；同一个原因的推论：`(d - e) + 1`、`(t - u) + 1`（差再做算术）后面跟缺列或重名时，polars 在规划阶段就报 `InvalidOperation`（`Duration + int` 不合法），本库没有 `Duration`，先报 `ColumnNotFound` / `DuplicateColumn`）、`&`/`|` 的 `ComputeError`（`& on ... is not supported`）、`~` 的 `not supported in 'not' operation`（`Float`、`String`、`Date` 等 polars 没有按位取反的类型；`Int32`/`Int64` 在 polars 里是合法的按位取反，本库在运行时才拒绝，见 `arith.md`，所以不算，名字检查先报）。
- polars 里一个错误是规划阶段还是运行阶段发现的，随运算和类型对而变（终审修复轮在 polars 2.1.0 上核实过的只有上面三类），本库没有逐对核实别的组合。别的类型错误仍按求值次序报，所以同时存在缺列或重名时，次序可能与 polars 相反。
- `tests` 里 `type resolution errors come before missing columns and duplicate names`（`select_test.mbt`）钉住上面三类。
