# 与 polars 的已知差异：DataFrame 操作（T10）

数据：`docs/golden/frame_ops.json`（`scripts/frame_ops.py` 生成，polars 2.1.0；调用由 `src/pl/frame_ops_golden_cases_test.mbt` 按用例 id 构造）。用例里 `"restricted": true` 只要求 `InvalidOperation`；`"known_diff"` 的 `result` 是本库的，polars 的形状在 `polars_shape`；`"polars_error"` 是 polars 的异常类，本库用另一个变体；`"rows"` 表示结果是该表按这些行号取出的行（只为缩小文件）；`"unordered"` 表示 polars 不保证行序，测试按行集合比较。

## 与 brief 或 spec 相关的差异

| 场景 | polars | 本库 |
| --- | --- | --- |
| `sort` 的 `descending` 长度为 1、`by` 有多个键 | Python 的 `descending=[True]` 与 2 个键报 `ValueError`；`descending=True`（单个 bool）才广播 | 长度 1 的数组就是广播（本库没有 bool 参数，brief 规定）；空数组是全升序。对照用例拿 `descending=True/False` 对照 |
| `sort` 的 `descending` 与 `by` 含选择器（`cols`、`all()`） | Python 按未展开的 `by` 列表长度比较：`by=[pl.col("a","s")]` 配 `descending=[True,False]` 报错 | 按展开后的键数比较（brief 规定）。对照用例把 `by` 逐列写开再传给 polars（`note` 字段） |
| `sort` 的 `descending` 与 `by` 的检查次序 | Python 在查列之前就把 `descending` 与未展开的 `by` 比长度：`by=[col("zz"), col("a")], descending=[True]` 报 `ValueError`（长度 1 不等于 2） | 长度 1 是广播，不报错，随后报 `ColumnNotFound`（brief 的裁定）。长度 ≥ 2 且不等于键数时，两边都是先报长度错误，再查列 |
| `ValueError`（`descending` 长度不符、`with_row_index` 的 `offset` 为负） | Python `ValueError` | `InvalidOperation`，文案取 polars 的整行；用例带 `polars_error: "ValueError"` |
| 去掉所有列后的形状 | `df.drop(*all)` 得 `(7, 0)`，高度保留 | 没有列的表是 `(0, 0)`（M1 的 DataFrame 约定）。结果的列为空，对照比较通过 |
| `null_count` 在没有列的表上 | `(1, 0)` | `(0, 0)`（同上）。用例 `null_count/z0` 标 `known_diff: "no-columns-height"` |
| `with_row_index` 的索引类型和范围 | `UInt32`，`offset` 加高度超过 `u32::MAX` 报 `ComputeError`，`offset > u32::MAX` 报 `ValueError` | `Int64`（M2 类型映射，对照数据已映射）；`offset` 是 `Int32`，最大 `2147483647`，不会溢出，没有这两种错误 |
| `unique(maintain_order=false)` | 行序不保证 | 总是按原来的先后顺序（`maintain_order` 不起作用）。对照用例标 `unordered`，按行集合比较，只用 `keep` 为 `first`/`last`/`none` 或整行去重，避免 polars 在“任取一行”上的不确定 |
| `sort` 的 `maintain_order` | 默认 `false`，并列的次序不保证 | 一律稳定（brief 规定）。对照用例全部用 `maintain_order=True` |

## `fill_null(value : Expr)` 的语义

`DataFrame::fill_null` 接 `Expr`。字面量按 polars 的 `df.fill_null(<Python 标量>)` 处理，其余按 `F.all().fill_null(expr)`（polars 的 `LazyFrame.fill_null` 的两条路径，见 `lazyframe/frame.py`）：

- `lit_int`、`lit_float`（Python `int`/`float`）：只填 `Int32`、`Int64`、`Float32`、`Float64` 和 `Null` 列；字面量是弱的，取列的类型（`Int32` 列填 `lit_int(0)` 还是 `Int32`，填 `3_000_000_000` 变 `Int64`；整数列填 `lit_float(1.5)` 变 `Float64`；`Null` 列变 `Int32`/`Int64`/`Float64`）。
- `lit_bool`、`lit_str`、`Date`、`Datetime` 字面量：只填同类型的列和 `Null` 列（`Null` 列取字面量的类型）。
- `Null` 字面量：什么都不变（polars 对 `pl.lit(None)` 也是这样；Python 的 `None` 本身报 `ValueError`，本库没有对应写法）。
- 其他字面量（`lit(Int32(0))`、`lit(Float64(0.5))` 等，对应 `pl.lit(0, dtype=pl.Int32)`）：所有列都填，结果类型是列与值的超类型（`Series::fill_null` 的规则：`Boolean` 填 `Int32` 变 `Int32`，数字填字符串变 `String`，`Boolean` 与 `Date` 无超类型报 `SchemaMismatch`）。

本库与 polars 不同的地方：

- **值是整列的表达式**（`col("a")`、`-col("a")`、`col("a") + lit_int(1)`、聚合）：T9 起与 polars 一致，按 `all().fill_null(expr)` 逐列、逐行填（`Expr::fill_null` 的类型规则：列与值的超类型，字符串列被数字填成 `String`，`Null` 列取值的类型，`Boolean` 与 `Date` 没有超类型报 `SchemaMismatch`）。对照用例 `fill_null/t/expr/*`、`fill_null/p/expr/*`、`fill_null/e0/expr/*`、`fill_null/z0/expr/col` 不再是 `restricted`。没有列的表得没有列的表（polars 保留高度，同上“没有列的表”一条）。
- **值展开成多列**（`cols([...])`、`all()`）：与表的列逐列配对，宽度不同报 `cannot combine selectors that produce a different number of columns (2 != 9)`；宽度相同时逐列配对（用例 `fill_null/p/expr/cols3`）。例外：值是 `all()` 时 polars 报 `(4 != 3)`（它内部把一个高度列也算进 `all()`，所以比表多一列，与 `valid columns` 里多出内部列是同一个原因），本库 `all()` 恰好和表的列逐列配对，结果是每列用自己填自己（等于不变）。没有对照用例。
- **整数字面量之间的运算作值**（`lit_int(1) + lit_int(2)`、`-lit_int(1)`）：T9 起仍是弱的，按 `Expr::fill_null` 的规则取列的类型（`Int32` 列还是 `Int32`），遇到 `Date`/`Datetime` 列报 `got invalid or ambiguous dtypes: '[date, dyn int]' in expression 'fill_null'`（polars 同）。对照用例只放在没有日期列的表 `p` 上：表 `t` 有 `d` 和 `dt` 两列，polars 报**最后一列**（`[datetime[μs], dyn int]`），本库报第一列（`[date, dyn int]`），见 `known-diffs/expr_seq.md`。
- **`col("zz")` 缺列的文案**：polars 的 `valid columns` 里多一个内部列 `__POLARS_INTERNAL_HEIGHT_COLUMN`，本库没有，所以没有这条对照用例（`frame_ops_test.mbt` 里测 `ColumnNotFound`）。
- 对照用例里 `lit_int(0)` 对应 Python 的 `df.fill_null(0)`，**不是** `df.fill_null(pl.lit(0))`（后者是 dyn int 表达式，遇 `Datetime` 列报上面那个错）。

## `filter`

- 谓词是弱字面量（`lit_int(1)`、`lit_float(1.5)`，以及经过 `alias`、取负、两个弱字面量之间的 `+ - * // %` 之后仍是弱的，如 `lit_int(1) + lit_int(2)`、`-lit_int(1)`）：polars 报 `ComputeError`，文案里是弱类型名（`got \`i32\``，值放不下 `Int32` 时 `i64`，浮点 `f64`）；本库用 `eval_operand` 的弱结果判断，文案相同。`/` 之后是强的 `Float64`，按 `InvalidOperation`（`got \`Float64\``）。对照用例 `filter/t/weak/*`。
- 弱字面量折叠出错的谓词（终审修复轮）：`lit_int(3) % lit_int(0)`、`lit_int(3) // lit_int(0)`（除数为 0，得被除数类型的 null）、溢出（`lit_int(i64::MAX) + lit_int(1)` 是 `u64`，负方向是 `i128`，`-lit_int(i64::MIN)` 是 `u64`）、`lit_int(1) & lit_int(2)`（按位，类型是 `i32`，值放不下 `Int32` 时 `i64`）、`null + lit_int(1)`、`null * lit_float(1.5)`（`i32` / `i64` / `f64`，由数字的类型定）都报 `ComputeError`，文案 ``filter predicate must be of type `Boolean`, got `<弱类型名>` ``。`null + null` 和 `-null` 例外：polars 报 `InvalidOperation`，got `Null`，本库照做。这些名字只在 `filter` 里用：`select`、`with_columns` 里同样的折叠失败没有变化（得 null 或回绕成强类型），因为那里 polars 的行为不是报错。实现是 `eval.mbt` 的 `weak_probe`，对照用例 `filter/t/weak/*`。
- 对空集合的 `is_in`（`col("a").is_in(Series::int32("s", []))`，值的类型随意）：polars 的 `DataFrame.filter` 在谓词本身、或者谓词是 `&`/`|` 链（任意深度，可带别名）的一个操作数时，把它折叠成 `false`，不检查类型：`a.is_in(空) | g` 等于 `g`，`a.is_in(空) & g` 没有行。本库同样折叠（`frame_ops.mbt` 的 `fold_empty_is_in`，被折叠的左边仍会求值，缺列等错误照报）。折叠只发生在这两处：`~is_in(...)`、`.eq(false)`、`.is_null()`、`when(...)`、`^` 里的空 `is_in` 在 polars 里仍报类型错误，本库也报（用例见 `m2_leftovers_test.mbt`，polars 2.1.0 核实）。`select`、`with_columns`、`Series::is_in` 里 polars 仍报类型错误，本库也报。非空而类型不符的集合两边都报错。一个窄的例外：`(x & a.is_in(非空且类型不符)) | x` 里 polars 的布尔吸收化简先去掉了出错的操作数，所以不报错、返回 `x` 为真的行；本库报 `InvalidOperation`（`x & 坏集合 | x` 这一种形状，不考虑别的）。
- 谓词长度既不是表高也不是 1 的 `ShapeMismatch`（`filter's length: 2 differs from that of the series: 5`）：公开的 `Expr` 里没有能改变长度的方法（没有 `head`、`unique`、`drop_nulls`、`sort` 等，见 `docs/migration.md`），所以这个分支从公开 API 到不了，也没有测试。
- 一次只能有一个谓词（polars 的 `df.filter(a, b)` 是 `&`）；传多列选择器报 polars 的 `expanded to multiple expressions` 那一行。

## `sort`

- 按表达式排序用 `-col("a")`、`col("a") * lit_int(-1)`、`is_null`、`abs` 等（`abs` 的排序有手写测试 `sort by abs of a column`，T9 补上）。
- 排序键必须和表同高：字面量、聚合不广播，报 `ShapeMismatch`（polars 同，文案 `sort expressions must have same length as DataFrame, got DataFrame height: 5 and Series length: 1`）。这与 `select` 里“长度 1 广播”不同，所以本任务没有用 `eval_exprs`/`fit_height`，而是直接 `eval_node`。
- 键里有重名（`[col("a"), col("a")]`）不报错（polars 同）。

## `rename`

- 先查重名再查缺失：`{"zz": "s", "i32": "s"}`（strict）报重名而不是缺失（polars 同，用例 `rename/t/missing-dup-strict`）。
