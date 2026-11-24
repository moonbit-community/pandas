# 与 polars 的已知差异：表达式的序列操作、`str()`、`dt()` 和 `DataFrame::fill_null_strategy`（T9）

数据：`docs/golden/expr_seq.json`（`scripts/expr_seq.py` 生成，polars 2.1.0）。格式 `{"tables", "inputs", "cases", "frame_cases"}`。`cases` 是表达式用例（`select` 或 `with_columns`，表达式由 `src/pl/expr_seq_cases_test.mbt` 按用例 id 构造，并且每个用例的 `to_string()` 要等于 polars 的 `str(expr)`）；`frame_cases` 是 `df.fill_null(strategy=..., limit=...)` 用例（由 `expr_seq_golden_test.mbt` 里的数据驱动测试执行）。字段 `result`、`error`+`message`、`restricted`、`known_diff` 的含义同 `expr.md`。额外字段：

- `build_error: true`：polars 在**构造表达式**时（Python 里）就报错，所以没有 `str(expr)`（`str` 为空数组）；本库在展开或求值表达式时才报同样的错。
- `polars_error`：polars 的 Python 异常类，本库用另一个变体（`ValueError`、`OverflowError` 对应 `InvalidOperation`，`ComputeError` 的重名对应 `DuplicateColumn`）。
- `polars_message`：polars 原文，本库在其后追加了内容（非法正则，同 `regex.md`：本库的文案是 `regex error: regex parse error: "<pattern>"`）。

## 与 brief 或 spec 相关的差异

| 场景 | polars | 本库 |
| --- | --- | --- |
| `diff` 作用于 `Date`、`Datetime` | 得 `Duration` | 没有 `Duration` 类型，报 `InvalidOperation`（T4 的裁定）。用例 `diff/q/d/*`、`diff/q/dt/*`、`sel/all-diff-dates` 标 `restricted` |
| 单独的弱字面量作序列操作的输入（`lit_int(1).cum_sum()`、`lit_int(1).shift(1)`、`lit_int(1).diff()`、`lit_int(1).reverse()`） | 字面量按 `Int32`（放得下时） | spec 5.5：单独的弱字面量是 `Int64` / `Float64`。13 个用例带 `known_diff: "dyn-literal-default"`，`result` 是本库的，polars 的类型在 `polars_schema` |
| 单独的弱整数作 `str()`、`dt()` 的输入（`lit_int(1).str().to_uppercase()`） | 错误文案里类型名是 `i32` | 文案里是 `i64`（同上，本库的弱字面量单独出现时是 `Int64`）。没有对照用例，`expr_str_test.mbt`、`expr_dt_test.mbt` 钉住本库的文案 |
| `fill_null(strategy=..., limit=...)` 的 `limit` 不合法（用于非 forward/backward 策略、负数） | Python 在**构造表达式**时抛 `ValueError` / `OverflowError`，与表和列无关 | 构造表达式的函数不能 `raise`，所以在展开表达式（`select`/`with_columns`）或求值时报 `InvalidOperation`，文案取 polars 的整行（`can only specify \`limit\` when strategy is set to 'backward' or 'forward'`；负数是 `number too small to fit in target type`）。选择器展开成 0 列时也报（`cols([]).fill_null_strategy(Min, limit=1)`，用例 `fills/limit-bad/*-empty` 等）；表达式只构造、不用于任何 `select` 时本库不报错 |
| `shift` 的 `fill_value` | 任何 Python 标量或表达式；Python 弱标量（`5`）不改变列类型 | 强类型的 `AnyValue`（T4 的裁定）：结果类型是列与值的超类型；`AnyValue::Null` 表示“不填”。对照用例用 `pl.lit(v, dtype=...)`，`str(expr)` 里写作 `shift_and_fill([dyn int: 1, 5])` |
| `strip_chars` 的参数 | `characters: str \| None` | `characters? : String`（主会话裁定，和 `limit?` 同一写法；调用写 `characters="x"`，不写就是去空白） |
| `Series` 上没有 `str()`、`dt()` | 有 | 只有 `Expr` 有（和 `Series::str` 构造函数撞名，已裁定） |

## polars 的不确定性，对照数据里没有这些用例

polars 并行求值 `select` 的各个表达式和 `DataFrame::fill_null(strategy=...)` 的各列。**两处以上同时失败**时，报哪一个会随运行变化（同一个表同一个调用，Boolean 列的 `` `mean` operation not supported for dtype `Boolean` `` 和 String 列的 `fill-null strategy Mean is not supported` 都出现过）。这些输入按 id 排除（`expr_seq.py` 里的 `FLAKY_CASES` 和 `FLAKY_FRAME_CASES`），根本不生成，所以对照数据逐字节可复现（`expr_seq.py` 和 `frame_ops.py` 各跑多次，输出的 sha256 相同）。排除表是实测得出的：`EXPR_SEQ_CHECK_FLAKY=1` 时脚本把每个错误用例重跑 200 次、不写任何文件，只打印文案会变的用例，并断言它们都在排除表里（几秒钟）。被排除的用例：

- 表达式：`sel/all-fills-mean-mixed`、`sel/all-cum_sum-mixed`、`str/all`、`dt/all`、`dt/error-order`、`dt/error-order2`；
- 整表：`frame/q/mean`、`frame/q/one`、`frame/t/mean`、`frame/t/one`（`q` 和 `t` 里 String 与 Boolean、Null 列都不支持这些策略）。

本库按列的顺序，报第一个失败的列（和 `Series::fill_null_strategy` 逐列调用一致）。单独只有一列会失败的用例（`frame/c_<type>/<strategy>` 对每种类型×每种策略各一个）是确定的，都在对照数据里。

## 错误的先后

- **两个表达式都失败，一个在计划阶段、一个在运行阶段**：polars 先报计划阶段（求输出类型时）的错。例：`select([col("i32").str.to_uppercase(), col("d").str.contains("a")])`，`to_uppercase` 作用于 `Int32` 是运行时才报的 `SchemaMismatch`，`contains` 作用于 `Date` 在计划阶段就报 `InvalidOperation: expected String type, got: date`，polars 报后者；本库按表达式顺序，报前者。反过来写（`contains` 在前）两者一致，对照数据里留了这个顺序（`str/error-order2`）。本库没有按表达式推断输出类型的计划阶段，这与 T7 复审记下的“计划阶段的类型错误先于重名/缺列检查”同一个根因（`known-diffs/expr.md`）。
- **多列选择器下 `str().contains`、`starts_with`、`ends_with`、`replace(_all)` 作用于非字符串列**：计划阶段的类型检查，polars 报**最后一个**失败的列（`cols(["s","a","n","d","g"]).str.contains("a")` 报 `got: bool`；`cols(["d","n"])` 报 `got: null`），是确定的；本库按列的顺序报第一个（`got: i32`、`got: date`）。只差文案，没有值的差异。`str/all` 因为这个原因（以及并行求值的不确定性）不在对照数据里，对照数据里只放单列的此类用例。
- **`fill_null(value)` 带弱字面量、多个 `Date`/`Datetime` 列**：polars 报**最后一个**失败表达式的错误（`got invalid or ambiguous dtypes: '[datetime[μs], dyn int]'` 先于 `'[date, dyn int]'`，不管列的顺序），本库报第一个。`DataFrame::fill_null(lit_int(1) + lit_int(2))` 在表 `t`（有 `d` 和 `dt`）上会遇到，对照数据里这个用例只放在没有日期列的表 `p` 上（见 `known-diffs/frame_ops.md`）。

## 其他

- **`Expr` 的 `str()` 命名空间的错误文案**与 T6 的 `Series` 内核一致：`contains`、`starts_with`、`ends_with`、`replace(_all)` 作用于非字符串列是 `InvalidOperation: expected String type, got: i32`；`to_lowercase`、`to_uppercase`、`len_chars`、`len_bytes`、`strip_chars*` 是 `SchemaMismatch: invalid series dtype: expected \`String\`, got \`i32\` for series with name \`i\``（表达式里与 Series 里文案相同，已由对照数据确认）。`Null` 列同样报错，不是 null 进 null 出。
- **非法正则、正则语法的差异、大小写、`.` 是否匹配 `\n`**：同 `regex.md`。对照数据里避开了 `.` 与 `\n` 同时出现的输入（`replace_all("[a-c]", ...)` 代替 `replace_all(".", ...)`）。
- **`dt()`**：`weekday` 是 ISO（周一为 1）；日历范围外的 `year`、`month`、`day`、`ordinal_day` 得 null，`weekday` 仍有值（T6，`expr_dt_test.mbt` 里有一例）。结果类型是 `Int32`（polars 的 `Int8`/`Int16`，M2 类型映射），`weekday`、`month` 等的原类型在 `polars_dtype` 里（经 `to_ours`）。
- **`rank`、`cum_count` 的结果类型**：`Int64`（polars 的 `UInt32`，M2 类型映射）。
- **`cum_sum`、`cum_prod` 作用于 `Boolean`**：结果是 `Int64`，与 polars 一致（不是 spec 5.5 的算术限制，累计函数不受限）。
- **`fill_null_strategy` 的 `Mean` 在整数列上**：截断到 0（T4）；`fills/q/mean/i32` 等用例已对上 polars。
- **表达式 `limit?`**：写作 `limit=1`（仓库惯例，主会话裁定，覆盖计划里的 `limit~ : Int? = None`）。
