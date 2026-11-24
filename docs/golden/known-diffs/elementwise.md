# 与 polars 的已知差异：逐元素函数（T3）

数据：`docs/golden/elementwise.json`（`scripts/elementwise.py` 生成，polars 2.1.0，415 条用例）。参照物是表达式引擎的结果（`pl.DataFrame([s]).select(pl.col("a").<op>())`，`fill_null` 用带类型的 `pl.lit`），后续表达式任务包的就是这一层；Series 方法在这些函数上与表达式结果一致。

## 有意更严（spec 5.5，M2 补充约定：spec 与 polars 冲突以 spec 为准）

`abs`、`sqrt`、`exp`、`log`、`round` 作用于 `bool`、`str`、`date`、`datetime` 时，本库一律 `InvalidOperation`，文案 `<fn> is not supported for dtype <dtype>`（例：`sqrt is not supported for dtype str`、`round is not supported for dtype datetime[μs]`）。`elementwise.json` 里对应的 25 条用例带 `"restricted": true`，测试只要求 `InvalidOperation`；polars 成功时的结果类型记在 `polars_dtype`。

| 函数 | polars 对这四种类型 | 本库 |
| --- | --- | --- |
| `sqrt` | 先 `cast(strict=false)` 成 `Float64` 再开方：`bool`、`date`（天数）、`datetime`（微秒数）得数，`str` 被解析（`"4"` 得 `2.0`，`"x"` 得 null） | `InvalidOperation` |
| `exp`、`log` | `bool` 得 `Float64`；`str`、`date`、`datetime` 报 `` `exp` operation not supported for dtype `str` as argument 0 `` | `InvalidOperation`（`bool` 也拒绝） |
| `abs`、`round` | 都报错，文案各异 | `InvalidOperation`，统一文案 |

`Null` 类型保持 polars 的行为：`sqrt(Null)` 是全 null 的 `Float64`；`abs`、`exp`、`log`、`round` 报 polars 的文案（`` `abs` operation not supported for dtype `null` ``、`` `exp` operation not supported for dtype `null` as argument 0 ``、`rounding ('half_to_even') operation not supported for dtype `null` (expected: numeric)`）。

`is_nan` 系列、`fill_null`、`between`、`is_null` 仍按 polars（含 `fill_null` 里字符串与数字得 `String`）。

## 数值差异

| 场景 | polars | 本库 |
| --- | --- | --- |
| `round(decimals=-1)`（负数） | `decimals` 是无符号整数，Python 层在进入 polars 前抛 `OverflowError: number too small to fit in target type` | `InvalidOperation`，`decimals must be non-negative, got -1`；对照用例带 `python_error` 记录原文，期望值是本库的文案 |
| `exp`、`log` 的最后一位 | 调用 C 库（glibc） | 用 `@math.exp` / `@math.ln`（纯 MoonBit 实现），个别值差几个 ulp：`ln(3.0)` 差 1 ulp，`log(base=3.0)` 的 3 条 `Float64` 用例（`i32`、`i64`、`f64`）因此差 1 到 2 个 ulp（对照数据里最多 2 ulp，测试的宽容度就是 2 ulp）。底数 3 在别的输入上最多可差到 4 ulp（`ln(x) / ln(3)` 把 `ln(3)` 的 1 ulp 误差和商的舍入加在一起；`docs/migration.md` 写的就是这个上界，没有穷举验证）。其余用例（含 `log` 底数 2、10、0.5、`exp` 全部、`Float32` 全部）逐位一致。对照测试对 `exp`/`log` 的 `Float64` 结果允许 2 ulp，并断言恰好 3 条用例用到了这个宽容（`golden_elementwise_inexact`） |
| `round` 的 `decimals` 很大（约 300 以上） | 按数学结果舍入：`round(1e-320, 310)` 是 `0.0`，`round(5e-324, 400)` 是 `5e-324`；`round(1e-300, 300)` 因 `10^300` 不精确得 `9.999999999999994e-301` | 照 `round(x * 10^d) / 10^d` 算，`x * 10^d` 溢出（含 `10^d` 为 `inf`，`d >= 309`）就原样返回。`10^d` 用与编译器 `powi` 相同的逐次平方求，`d <= 22` 时精确，所以 `d` 到 22 的对照数据（`decimals` 取 0、1、2、5、15、22）逐位一致；更大的 `d` 没有对照用例，个别极小的非规格化数结果可能不同 |
| `Float32` 的 `exp`、`log`、`round` | f32 库函数 | `exp`、`log` 用 `@math.expf`、`@math.lnf`（随机抽样与 polars 只在个别值上差最后一位的情况未在对照数据里出现）；`round` 在 `Float64` 里算再转回 `Float32`（与 polars 逐位一致，纯 `Float32` 算术反而对不上） |

## 接口取舍

- **`round` 的 `decimals` 约 300 以上没有对照用例**，不保证与 polars 一致（见上表）。
- **`fill_null` 接受 `AnyValue::Null`**：结果就是原列（类型不变）。Python 的 `Series.fill_null(None)` 报 `ValueError`，表达式里 `fill_null(pl.lit(None))` 则正常；本库取表达式的行为。
- **`fill_null` 的值是带类型的**：`AnyValue::Int64(7)` 填进 `Int32` 列得 `Int64` 列。弱类型字面量（`lit_int` 等）由表达式层（T8）处理。数字与字符串的组合得 `String`（polars 的 `fill_null` 如此，虽然比较和算术拒绝这一对，所以 `supertype(str, 数字)` 仍是 `None`，`fill_null` 自己补了这一条）。
- **`between` 的长度报错**：`self` 与某个边界长度不同且都不是 1 时，文案与 polars 一致（`could not perform '>=' comparison between series 'a' of length: 6 and series 'lo' of length: 3, because they have different lengths`，先检查下界）。`self` 长度为 1、两个边界长度又互不相同时，polars 在 Rust 层 panic（`lhs and rhs must have the same length`），本库报 `ShapeMismatch`（来自 `and_` 的长度检查）；没有对照用例。
- **类型报错的列名**：`between` 的类型不兼容错误取 `compare` 的文案，列名是各 Series 自己的名字。

## 与 polars 一致、容易被误以为是差异的行为

- `round` 默认 `half_to_even`（polars 2.1.0 的默认），不是四舍五入：`round(0.5) = 0.0`，`round(2.5) = 2.0`，`round(-0.5) = -0.0`，`round(2.675, 2) = 2.68`（`2.675 * 100` 在浮点里恰好是 `267.5`，平局取偶）。整数列原样返回。
- `sqrt`：`Float32` 保持 `Float32`，整数先转成 `Float64`，`Null` 得全 null 的 `Float64`；`exp`、`log` 只接受数字（`Null` 报 polars 的文案）。
- `abs(MIN)` 回绕为 `MIN`；`abs(-0.0)` 是 `0.0`；`sqrt(-0.0)` 是 `-0.0`；`log(0)` 是 `-inf`，`log(-1)` 是 NaN。
- `log` 是 `ln(x) / ln(base)`，默认底数 `2.718281828459045`；`Float32` 的底数先转成 `Float32`，除法也在 `Float32` 里做。`base=1` 时 `log(1)` 是 NaN、其它正数是 `inf`；`base=0` 得 `-0.0`（`ln(x) / -inf`）；负底数得 NaN。
- `is_nan` 系列：整数列全 `false`（`is_not_nan`、`is_finite` 全 `true`），null 保持 null；`Null` 列得全 null 的 `Boolean`；`bool`、`str`、`date`、`datetime` 报 `` `is_nan` operation not supported for dtype `bool` ``。`is_null` 的结果没有 null，`Null` 列全为 `true`。
- `between` 是 `(x >= lo) & (x <= hi)`（`closed` 把对应的一端换成严格比较），按 Kleene 逻辑：`x` 不满足下界时即使上界是 null 也得 `false`。NaN 比所有数大，`-0.0 == 0.0`，字符串按码点比较，`lo > hi` 不报错、全 `false`。
