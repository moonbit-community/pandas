# 与 polars 的已知差异：序列操作（T4）

数据：`docs/golden/sequence.json`（`scripts/sequence.py` 生成，polars 2.1.0）。涉及 `shift`、`diff`、`cum_sum`、`cum_min`、`cum_max`、`cum_prod`、`cum_count`、`rank`、`reverse`、`fill_null(strategy=...)`（本库叫 `fill_null_strategy`）。

| 场景 | polars | 本库 |
| --- | --- | --- |
| `diff` 作用于 `Date`、`Datetime` | 得 `Duration` 列 | 本库没有 `Duration` 类型，报 `InvalidOperation`（文案 ``\`diff\` operation not supported for dtype \`date\`: the difference would be a duration, ...``）。对照用例带 `"restricted": true`，只要求 `InvalidOperation`，`polars_dtype` 记 `Duration(time_unit='us')` |
| `shift(fill_value=...)` 的填充值 | Python 标量是“弱类型”：`Int32` 列填 Python `5` 仍是 `Int32`，填 `3_000_000_000` 才变 `Int64`；`bool` 列填 `1` 得 `Int32` | `fill_value` 是有类型的 `AnyValue`，一律按强类型字面量处理：结果类型是两边的 supertype（与 `Series::fill_null(value)` 同一规则，`Int32` 填 `Int64(5)` 得 `Int64`）。对照用例用 `pl.lit(v, dtype=...)`（强类型）生成 |
| `shift` 填显式 null：`Null` 列 `shift(n, fill_value=pl.lit(None))` | 报 ``InvalidOperation: \`shift_and_fill\` operation not supported for dtype \`null\` `` | `AnyValue::Null` 就是默认值，与“不填”无法区分，按不填处理（得 `Null` 列）。对照数据不含这 3 个用例 |
| `shift` / `diff` 的 `n` | 接受任意 Python 整数（超过 `Int32` 也行，得全 null） | `n` 是 `Int32`；`Int32::MIN`、`Int32::MAX` 也不会溢出（内部按 `Int64` 算） |
| `fill_null_strategy` 的 `limit` 与 `min`/`max`/`mean`/`zero`/`one` 同用 | Python 抛 `ValueError`（`limit=0` 也抛） | `InvalidOperation`，文案同 polars：``can only specify `limit` when strategy is set to 'backward' or 'forward'``（先于类型检查） |
| `limit` 为负数 | Python 抛 `OverflowError: number too small to fit in target type` | `InvalidOperation`，同一句文案（`limit` 与非方向策略同用时，先报上一行的错） |
| `fill_null(strategy='mean')` 作用于 `Int64`，均值（`f64`）超出 `Int64`（例如 `[null, MAX, MAX]`，求和后舍入到 2^63） | polars panic（`Option::unwrap()` on `None`） | 夹到 `Int64` 的最大 / 最小值，不陷入。没有对照用例（polars 给不出期望值） |
| `rank(method='random')` | 支持（要 `seed`） | 不提供，`RankMethod` 只有 `Average`、`Min`、`Max`、`Dense`、`Ordinal` |
| `Boolean` 列的 `cum_sum` / `cum_prod`、`Int32` 列的 `cum_prod` | 分别得 `UInt32`、`Int64`、`Int64` | `Int64`、`Int64`、`Int64`（`UInt32` 按全局类型映射记作 `Int64`，对照数据里 `polars_dtype` 记 `UInt32`）。不受 spec 5.5 “Boolean 不参与算术”的限制：它们是累计操作，按 polars 实现 |

## 与 polars 一致、容易被误以为是差异的行为

- 浮点 `cum_sum` 从 `0.0` 开始加，所以开头的 `-0.0` 得 `0.0`；`cum_prod` 从 `1.0` 开始乘，`-0.0` 保持（实测）。
- 浮点 `cum_min` / `cum_max`：NaN 不会替换已有的数；开头的 NaN 由第一个数替换；`-0.0` 和 `0.0` 相等时取后面那个（实测）。
- `cum_count` 对 null 行重复前面的计数（不是 null），`Null` 列得全 0，结果是 `Int64`（polars 的 `UInt32`）。
- `rank` 对 null 行得 null，只给非 null 行排名；`Null` 列的 `rank` 得全 null（`Average` 为 `Float64`，其余为 `Int64`）；`Date`、`Datetime`、`String`、`Boolean` 都能排。
- `fill_null_strategy`：没有 null 的列原样返回（不检查类型，所以 `String` 无 null 时 `One` 也不报错）；全 null 的列用 `Mean` 原样返回；`Null` 列的 `Zero`、`One` 在有行时报 ``fill null strategy not yet supported for dtype: null``；`Mean` 对 `Boolean` 报 ``\`mean\` operation not supported for dtype \`Boolean\``（注意 `Boolean` 的大小写是 polars 的），对 `String` 报 `fill-null strategy Mean is not supported`。
- `Mean` 对整数、`Date`、`Datetime` 先算 `f64` 均值再向零截断（`-1.5` 得 `-1`）。
- `shift` 的 `Boolean` 填充值落在 `Date` / `Datetime` 列里按 0 / 1 天（微秒）算；`Date` / `Datetime` 填充值落在 `Boolean` 列里报 ``ComputeError: fill value '1970-04-11' is not supported``。
