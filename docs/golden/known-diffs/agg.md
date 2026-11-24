# 与 polars 的已知差异：Series 聚合（T2）

数据：`docs/golden/agg.json`（`scripts/agg.py` 生成，polars 2.1.0，共 2472 条）。除下面几条外，值、结果类型、报错变体和文案都与 polars 一致。`sum`、`mean`、`product`、`median`、`quantile`、`min`、`max`、`first`、`last`、`count`、`len` 逐位相同（含 `-0.0`）；只有 `std`、`var` 允许浮点末位误差（`Float64` 和 `Float32` 都是 4 个 ulp 以内，不再是相对 1e-12 / 1e-6；对照数据里差 1 到 4 ulp 的是 3 条 `Float64` 用例，其余逐位相同）。对照数据含 127、128、129、257 个无 null 的随机 `Float64`，卡住两两求和的分块界限（把 `n < 128` 改成 `n <= 128`，128 个值的和会差 2 ulp）。

## 接口上的差异

| 项 | 要求 | 实际 | 原因 |
| --- | --- | --- | --- |
| 方差方法名 | `Series::var` | `Series::var_` | `var` 是 MoonBit 关键字，不能当方法名（词法错误，没有转义写法），按 spec 的保留字写法（`and_`、`or_`、`not_`）加下划线。`std` 不受影响。T8 的 `Expr::var` 会遇到同样的问题 |
| 分位数的方法参数 | `method~` | `interpolation~`（polars 的参数名） | `method` 是保留字，作形参名会触发 warning 0035（`#warnings(...)` 压不住），CHK 会变成非 0 |

## 与 polars 对不上的取值

- **`Date` 序列在没有值时的 `quantile`**：polars 直接 panic（`Option::unwrap()` on a `None` value），本库得 `Datetime` 类型的 null（`median`、`mean` 与 polars 一致，也是 null）。没有对照用例。
- **`Float64` 方差溢出**：`[1e308, 1e308]` 和 `[1e308, 1e308, -1e308]` 的 `var`/`std`，polars 得 NaN，本库得 `inf`（先求均值再求偏差平方和，均值本身已溢出）。`[1e200, -1e200]` 的方差溢出为 `inf`，两边一致（在对照数据里）；另两条不在对照数据里。
- **大偏移量的方差**：`1e9 + i * 0.001`（1000 个值），精确方差（按这些 double 的精确值）是 0.08341666666857711，本库两遍算法得到这个值（相对误差 1e-12 以内）；polars 得 0.08341669533418049（相对误差 3e-7，它按 128 个值一块算再合并）。`agg_test.mbt` 钉住本库的值，对照数据对这类输入不含 `std`/`var`。
- **相等的零的符号**：`quantile` 在 `[0.0, -0.0]`、`[-0.0, 0.0]` 这类相等零的输入上，polars 用不稳定的部分排序，最高位置上零的符号随内部实现而定（例如 `[0.0, -0.0]` 的 `q=1` 得 `+0.0`，`[0.0, 0.0, -0.0, -0.0]` 的 `q=1` 也得 `+0.0`）；本库按输入顺序稳定排序，相等的值取下标处那个。`agg_golden_test.mbt` 的 `golden_agg_zero_sign` 列出 20 条这样的用例（只有零的符号不同，值用 `==` 比较）；其余含零的用例都逐位一致，包括 `[-0.0, -0.0]` 的 `median`（`-0.0`）。**实际会不同的输入比这 20 条多**：列表里同时有 `+0.0` 和 `-0.0` 时，`nearest`、`higher`（`q` 为 0.25、0.5）、`equiprobable`（`q` 为 0.75）都可能得到另一种符号（复审的网格里 372 次调用有 33 次，如 `[-1.0, 0.0, -0.0]` 的 `q` 为 0.75 和 1）。以后新增含两种零的对照输入，要把用例 id 加进 `golden_agg_zero_sign`，否则对照测试会失败。`median`/`quantile` 现在用选择算法，结果与全排序版本逐位相同（`agg_wbtest.mbt` 的 `quantile by selection is bit for bit the full-sort quantile` 逐位比较，只把 NaN 当同一个值，因为算术产生的 NaN 的符号位随引擎而定）。
- **常数列或近乎常数的列的 `std`/`var` 不是精确的 0**：`[10000000000.3] * 10` 的 `std` 本库得 `2.0105219905652234e-06`，polars 是 `0.0`；200 个 `0.1`，本库 `5.6e-17`，polars `0.0`；78 个 `-599448.5581961358`，本库 `7.0e-10`，polars `1.2e-10`（都不是 0，但数值不同）。本库先求均值再求偏差平方和，均值有舍入误差；polars 的分块合并在这类输入上恰好得 0。都在浮点噪声以内，没有改。
- **很长的 `Float32` 求和**：polars 对约 10 万个以上的数组按线程数分段求和，末位随机器而定；本库在 6 万个以内与 polars 逐位相同（`sum`、`mean`）。6 万个以上，`Float64` 的和相对差在 1e-13 以内（复审实测最大 1.3e-14，例如 `1e9 + ((i*7919)%1000)*0.001`、10 万个、每 10 个一个 null：polars 得 `90000000044930.0`，本库 `90000000044930.02`；不是“100 万个以内逐位相同”）。`Float32` 的 10 万个值差约 2e-7，100 万个差约 8e-8（在 1e-6 以内，`agg_test.mbt` 里有 10 万个的用例）。
- **负的 `ddof`**：polars 的 Python 层抛 `OverflowError`（`ddof` 是 `UInt8`），本库报 `InvalidOperation`（`ddof must not be negative, got -1`）。大于 255 的 `ddof` 本库不拦，结果是 null。没有对照用例。
- **`Datetime` 的 `quantile`/`median`/`mean` 精度**：先转 `Double` 再截断（polars 在位置上加了 null 个数，本库照做，所以带 null 的 Date/Datetime 线性分位数与 polars 逐微秒一致；`Date` 先在天数上插值再乘 86 400 000 000），绝对值超过 2^53 微秒（约公元 2255 年之后、1685 年之前）时不精确。polars 是否同样不精确没有验证。
- **报错里 `q` 的写法**：`NaN`、`inf`、`-inf` 和一般小数（`1.5`、`-0.1`、`2`）与 polars 的 Rust 输出一致；很大或很小的数（`1e20`）两边的科学计数写法不同，没有对照。

## 与 polars 一致、容易被误以为是差异的行为

- `Date`/`Datetime` 的 `mean`/`median`/`quantile` 结果是 `Datetime`（`Date` 先按天算再乘 86 400 000 000，向零截断到微秒）。
- `Boolean` 有 `sum`（得 `Int64`，true 的个数）、`mean`、`median`、`std`、`var`、`product`（`Int64`），没有 `quantile`；`String` 只有 `min`/`max`/`first`/`last`/`count`/`len`；`Null` 没有 `product` 和 `quantile`。其余组合报 `InvalidOperation`，文案 ``` `sum` operation not supported for dtype `str` ```（类型用本库显示名）。
- `min`/`max` 忽略 NaN（全是 NaN 才得 NaN）；相同值（`-0.0` 与 `0.0`）取后一个。`first`/`last` 保留 null。
- `Int32` 的 `sum` 仍是 `Int32`（回绕），`product` 是 `Int64`（`Int32` 先升到 `Int64` 再乘，回绕在 64 位）。`Float32` 的 `sum`/`product` 用 `Float32` 累加（`sum` 与 polars 一样按两两相加的顺序：不足 128 个按顺序加；否则先按顺序加开头的 `n % 128` 个，其余每 128 个一块（16 路交错再对折），块和按二分递归相加）；`mean`/`std`/`var`/`median`/`quantile` 用 `Double` 算完再转 `Float32`。
- `std`/`var` 的 `ddof` 不小于有效值个数时得 null；有效值个数为 1、`ddof=0` 时得 0。
- 报错先检查类型，再检查 `q` 是否在 `[0, 1]`；空序列和全 null 序列也检查 `q`。
