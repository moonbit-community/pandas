# 与 polars 的已知差异：Series 算术、比较、逻辑、filter（T1）

数据：`docs/golden/arith.json`（`scripts/arith.py` 生成，polars 2.1.0）。下面几处本库有意比 polars 严，或接口不同；`arith.json` 里对应用例带 `"restricted": true`，测试只要求 `InvalidOperation`。

## 有意更严（spec 5.5）

| 场景 | polars | 本库 |
| --- | --- | --- |
| 算术（`add sub mul div floor_div rem`）有一侧是 `bool`、`str`、`date`、`datetime` | 很多组合能算：`bool + i32` 得 `Int32`，`bool + bool` 得 `UInt32`，`str + str` 拼接，`date - date` 得 Duration，`i32 % date` 得 `Int32`；不能算的报文案各不相同（`TypeError`、`SchemaError`、`InvalidOperationError`，文案有五六种） | 一律 `InvalidOperation`，文案 ``{op} operation not supported for dtypes `{a}` and `{b}` ``（`op` 为 `add sub mul div floor_div rem`） |
| `and_` / `or_` 两侧同为 `Int32` 或同为 `Int64` | 按位与、按位或 | `InvalidOperation`（`` `bitand` operation not supported for dtype `i32` ``） |
| `not_` 作用于 `Int32`、`Int64` | 按位取反 | `InvalidOperation`（`dtype Int32 not supported in 'not' operation`） |

`restricted` 用例在 JSON 里保留 polars 成功时的结果类型（`polars_dtype`），不保留值。

## 文案或路径的取舍

- **长度不一致**：polars 的 Series 运算符对算术报 `InvalidOperationError`（`cannot do arithmetic operation on series of different lengths: got 2 and 3`），对比较报 `ShapeError`，对 `&` 直接 panic。本库对所有运算统一报 `ShapeMismatch`，文案用表达式引擎的 `cannot evaluate two Series of different lengths (2 and 3)`；对照用例用 `pl.select(pl.lit(s1) + pl.lit(s2))` 取得。
- **`Null` 与 `Boolean` 的 `and_` / `or_`**：Series 运算符报错（`cannot unpack series of type `null` into `bool``），表达式引擎把 `Null` 当全 null 的 `Boolean`。本库取后者（后续表达式要用），对照用例用 `pl.DataFrame([s1, s2]).select(pl.col("a") & pl.col("b"))`。`Null` 与其它类型、`Null` 与 `Null` 仍按 Series 运算符报错，文案相同。
- **`Series::filter` 的掩码不是 `Boolean`**（含 `Null`）：polars 抛 Python 的 `RuntimeError: Expected a boolean mask`，不在错误映射里。本库报 `SchemaMismatch`（`filter mask must be Boolean, got i32`），没有对照用例，由 `filter_test.mbt` 钉住。
- **`str` 与数字**：polars 的 supertype 是 `String`，但比较报 `ComputeError`（`cannot compare string with numeric type (i32)`），算术报 `InvalidOperationError`。本库的 `supertype(str, 数字)` 是 `None`，比较照 polars 报 `ComputeError`。
- **`Date` 比 `str` 时超范围日期**：polars 在把约 9570 万天以外的 `Date` 转成字符串时 panic；本库按 `cast(strict=false)` 得 null。没有对照用例（polars 无法给出期望值）。

## 与 polars 一致、容易被误以为是差异的行为

- 整数除以 0：`floor_div`、`rem` 得 null；`/` 得 `inf`、`NaN`。`MIN // -1` 回绕为 `MIN`，`MIN % -1` 是 0。整数加减乘溢出回绕。
- 浮点 `floor_div` 是 `floor(x / y)`，`rem` 是 `x - y * floor(x / y)`（`1.0 % inf` 和 `x % 0.0` 是 NaN）。
- 浮点比较：NaN 等于 NaN、大于所有数，`-0.0 == 0.0`。
- `Null / Float32` 是 `Float64`，`Float32 / Null` 是 `Float32`；`Null // Null` 报 `InvalidOperation`（`floor_div operation not supported for dtype `null``）。
- 比较前双方 `cast(strict=false)` 到 supertype：`Int64` 对 `Float64` 以 `f64` 比较，`Date` 对 `Datetime` 乘 86 400 000 000，`str` 对 `bool` / `date` / `datetime` 比较文本；cast 失败的值得 null。
