# 与 polars 的已知差异：表达式的聚合、逐元素函数、`when/then/otherwise`（T8）

数据：`docs/golden/expr_agg.json`（`scripts/expr_agg.py` 生成，polars 2.1.0，1415 条用例；格式与 `expr.json` 相同，另有 `inputs` 表放 `is_in` 的值）。`expr_agg.py` 先执行 `expr.py` 里“用例之前”的部分（表、表达式树、渲染器、`run`、`case`），再扩展本任务的节点；`result`、`error`、`restricted`、`known_diff` 的含义见 `known-diffs/expr.md`。

## 与 `expr.json` 共享的取舍

- **单独的弱字面量是 `Int64`/`Float64`**（spec 优先，T7 已裁定）：`lit_int(1).sum()`、`when(c).then(lit_int(1)).otherwise(lit_int(2))` 在 polars 里是 `Int32`，本库得 `Int64`。脚本检测到“只有结果类型不同”时自动标 `known_diff: "dyn-literal-default"`，`result` 是本库的结果，polars 的类型在 `polars_schema`（共 42 条：`when` 27、`bc` 9、`agg` 4、`fn` 1、`fill` 1）。与列（或强类型字面量）相遇的弱字面量按 T7 的规则变成对方的类型，与 polars 一致。
- **有意更严（spec 5.5）**：`abs`、`sqrt`、`exp`、`log`、`round` 作用于 `bool`、`str`、`date`、`datetime` 一律 `InvalidOperation`（与 `elementwise.md` 相同，41 条 `restricted`）；`str + str`（`col("s") + col("s").max()`）polars 能拼接，本库 `InvalidOperation`（1 条 `restricted`）。

## 聚合

- **`quantile` 越界的文案**：polars 的表达式在列里**有 null**（全 null 也算）时写 ``` `quantile` should be between 0.0 and 1.0, got 1.5 ```（带反引号）；没有 null 的列、空列、以及 Series 方法都不带反引号。`Expr::quantile` 照此（`xagg_agg`：`null_count() > 0` 时给 T2 的文案加反引号）。对照数据里 `t` 的列都有 null，没有 null 的情形用 `r1`（一行）的 `agg/quantile-bad/1.5/*/r1` 和 `expr_agg_test` 里的四行无 null 列钉住。
- **`std`/`var` 的 `ddof`、`quantile` 的 `interpolation`、`round` 的 `decimals` 不出现在 `str(expr)` 里**（polars 打印 `col("a").std()`、`col("a").quantile([dyn float: 0.25])`、`col("a").round()`），`Show` 照此。`log` 的底数出现，且按浮点字面量打印（`dyn float: 2`，Rust `Display`）；Python 里 `log(2)` 的整数底数会打印成 `dyn int: 2`，`Expr::log` 的底数是 `Double`，没有这种写法。
- **`Date` 列全是 null（含空列）时的 `quantile`**：polars panic（`Option::unwrap()` on a `None`，`polars-core/.../date.rs`），不是错误，没有可对照的值；脚本跳过该用例（`agg/quantile/d/e0`）。本库不 panic，返回一个 null（类型是 `Datetime`，T2 已记）。非空且全 null 的 `Date` 列也一样（审查 8 发现，脚本里没有对应用例）。
- **负的 `ddof`、负的 `decimals`**：polars 的 Python 层先抛 `OverflowError`，没有对照用例；本库 `InvalidOperation`（`agg_test`/`expr_agg_test` 钉住）。

## `fill_null`

- **弱字面量填 `Date`/`Datetime`**：polars 报 `InvalidOperation: got invalid or ambiguous dtypes: '[date, dyn int]' in expression 'fill_null'`（顺序是 `[自己, 值]`；弱字面量在左边时写 `[dyn int, date]`；整数、浮点都一样，`neg`、`alias`、两个字面量相加后仍是弱的）。本库照做（`xagg_fill_null`）。带类型的字面量（`lit(Int32(0))`）与 `Date` 得 `Int32`，与 polars 一致。
- **列填列是逐行的**：`col("a").fill_null(col("b"))` 按行取 `b`；长度 1 的值（字面量、聚合）填满所有 null；`self` 长度为 1、值是长列时，结果是长列的长度（`col("n").first().fill_null(col("a"))`）。公共类型取 `ew_fill_type`（上位类型，数字配 `String` 得 `String`），与 `Series::fill_null` 一致。
- 两边长度不同且都不是 1 的 `ShapeMismatch` 在表上造不出来（`Expr` 里没有 `head` 一类改变长度的操作），只有内核层的 wbtest。

## `between`

- 实现是 `(x >= lo) & (x <= hi)`（`closed` 把对应一端换成严格比较），比较的类型规则、弱字面量的适配、`String` 对 `Date` 的 `InvalidOperation` 都与二元比较相同，与 polars 对照一致。`str(expr)` 是 `col("a").is_between([lo, hi])`（不含 `closed`）。
- **一个界是 null 字面量时对不上**：`col("i32").is_between(pl.lit(None), 7)`，polars 得全 null，`str` 列、`f64` 列也不报错、全 null；`pl.lit(None, dtype=Int32)` 配 `Int32` 列却是 Kleene 结果（`x <= 7` 为 false 的行得 false），配 `Float64` 列又是全 null，规则不统一。本库一律按 `&` 的 Kleene 逻辑（两个比较各自算，`String` 列配数字界会报 `ComputeError`）。对照数据只留了两边一致的几条（两个界都是 null 字面量、`Null` 类型的列做界、`Int32` 配同类型的 null）；`btw/<列>/null`、`null-hi`、`typed-null-*` 等不一致的用例已删。

## `when/then/otherwise`

- **结构**：链式 `when(c1).then(v1).when(c2).then(v2).otherwise(v3)` 存成嵌套三元（`c1 ? v1 : (c2 ? v2 : v3)`），`Show` 与 polars 一致（`.when(c1).then(v1).otherwise(.when(c2)...)`）。输出名取第一个 `then`。没有 `otherwise` 的 `when(c).then(v)`（polars 补 `null`）没有对应的 API（brief 的 `Then` 只有 `otherwise`）。
- **公共类型**：`ew_fill_type`（与 `fill_null` 相同）。polars 的矩阵（9×9 去掉对角线，`when/types/*`）全部一致，包括 `bool` 配数字得数字、数字配 `str` 得 `String`、`date` 配 `datetime` 得 `datetime`、`bool` 配 `date` 报 `SchemaMismatch: failed to determine supertype of bool and date`。
- **条件不是 `Boolean`**：`SchemaMismatch`，``invalid series dtype: expected `Boolean`, got `i32` for series with name `a` ``（`Null` 类型的列、`lit(None)` 也是）。弱字面量做条件（`when(lit_int(1))`）本库报 `i64`，polars 报 `i32`（弱字面量差异），没有对照用例，对照里用强类型的 `lit(Int32(1))`。
- **错误的先后**（polars 2.1.0 实测，`when/err/*`）：缺列按先序（条件、`then`、`otherwise`；链里后面的分支在 `otherwise` 里）；然后“公共类型不存在”（polars 在规划阶段发现，嵌套的 `when` 里的也先于外层条件的运行错误）；然后条件的运行错误，条件的类型错误，`then`，`otherwise`。`when_eval` 把三部分都算完再按这个顺序报错。对不上的有：
  - 一个分支求值失败时，本库不知道它的类型，所以 `when(b).then(s == i32).otherwise(date)`（polars 知道 `s == i32` 是 `bool`，先报 `bool` 与 `date` 的类型错误）本库报分支的 `ComputeError`。
  - polars 在规划阶段报的类型错误（例如 `str + 1` 的 `arithmetic on dtypes ...`）排在所有运行错误之前，且 `then`、`otherwise`、条件的顺序与运行时不同（then、otherwise、条件）；本库对它们按运行错误的顺序处理。`str + 1` 本库本来就是 `restricted`，所以没有对照用例钉住顺序。
- **链的宽度错误的次序**：`when` 的链里，先比较外层 `(条件, then)` 的列数，再展开嵌套的 `otherwise`，最后比较三者（polars 的次序；对 1 至 3 个分支、宽度 0 至 3 的全部组合与 polars 一致）。`(0,2,0,3,1)` 得 `(2 != 0)`；对照用例 `when/width/*`。
- **长度为 1 的条件：polars 不运行没被选中的分支里的运行时错误，本库照常求值每个分支**：`when(col("h").sum().gt(10)).then(col("a")).otherwise(col("d").sum())` 在 polars 里得 `a`，本库报 `d` 求和的 `InvalidOperation`（`when_test` 钉住）。规划阶段的类型错误（`str` 求和、`str + lit_int(1)`、没有公共类型）两边都报。polars 的懒规则不简单（只有被选中的 `then` 是整列时才跳过嵌套的 `when`；长度为 1 的 `then` 仍报后面条件不是 `Boolean`；还会把结果广播到表的高度），第一轮曾试着只跑被选中的分支，把原来与 polars 一致的 114 个用例弄成了不一致，已整个撤销。常量条件（`lit_bool`）、聚合条件的链里的类型和不报错与否，同属这一类，没有对照用例。
- **帧高度的条件也是：polars 逐行只在被选中的行上运行分支**：`g=[T,F,null,T]`、`a=[1,2,3,4]`、`s=["x","1",null,"w"]` 时，`when(col("g")).then(col("a")).otherwise(col("s").cast(Int32))` 在 polars 里得 `a:i32 [1,1,null,4]`（`otherwise` 只在 `g` 不为真的行上运行，`"x"`、`"w"` 所在的行用的是 `then`），本库先把整个 `otherwise` 算完，报 `InvalidOperation: conversion from str to i32 failed ... 2 out of 4 values: ["x","w"]`。`then` 里的严格转换、`f64` 的 `3e9` 转 `i32`、`i64` 的 `2**40` 转 `i32` 同理；两个分支都出错时，polars 的计数只算被选中的行（`1 out of 4`，本库 `2 out of 4`）。与上一条同类，不限于长度为 1 的条件。
- **条件全真、全假或为 null（含长度为 1 的聚合条件）时，polars 直接取被选中的分支，不做上位类型转换**：弱字面量配 `Date`/`Datetime`（也包括配 `bool`、`Null` 列）时看得出来：`when(lit_bool(False)).then(lit_int(1)).otherwise(col("d"))`、`when(col("f").is_nan()).then(lit_int(1)).otherwise(col("d"))`（掩码全假）在 polars 里是 `Date`，本库得数字的上位类型（`i32`）；掩码有真有假时两边一致。值相同，只有类型不同；`Datetime` 变成 `i64` 再转成 `String` 时，本库打印 `0`，不是时间戳。与 lazy 路径无关，是第一轮写过又随撤销丢掉的一条，现补回。
- **两个同时出现的错误**：外层 `when` 的“没有公共类型”（规划阶段）本该先于内层条件的运行错误；本库先求值内层（`when(g).then(dt).when(a).then(lit_bool(true)).otherwise(g)`：polars `failed to determine supertype of datetime[μs] and bool`，本库 `invalid series dtype: expected Boolean, got i32`）。和上面“出错的分支没有类型”是同一类，需要两个错误同时出现。
- **全是弱字面量的 `when`**：`col("a") + when(g).then(lit_int(1)).otherwise(lit_int(2))` 在 polars 里是 `i32`（`dyn int` 一路保持到遇见 `a`），本库是 `i64`，`f32` 列旁的浮点同理（`f64`）；单独的 `when(...)` 本来就按 spec 是 `Int64`/`Float64`。原因：`eval_operand` 的 `Weak` 只带一个值，`when` 的结果是逐行不同的一列，要保持“弱”得给 `Operand` 增加一个带整列的变体，那会改 T10 用到的 `Operand` 的形状，所以没有做。对 `fill_null`、嵌套的 `when` 的分支、二元运算的操作数都是这样，值相同，只有类型不同；没有对照用例。
- **链的深度**：表达式树的求值（`eval_node`）、`weak` 字面量的折叠和 `Expr` 的文本都是递归的，栈深随链长线性增长（文本和弱字面量折叠的时间已是线性，见 `bench_test.mbt` 的 `deep chain` 基准）。终审修复轮在 lab5 上按后端实测（`moon test`，调试构建；每个深度单独起一个进程，`DataFrame::select([chain.alias("x")])` 取第一个值；探针是 `docs/bench/m2.md` 里“链的深度”一节描述的那组）。下表是“正常 / 栈溢出”的最大/最小测过的链长（两者之间没有测）：

  | 链 | native（栈 8 MB，溢出是进程崩溃） | wasm-gc | wasm | js |
  | --- | --- | --- | --- | --- |
  | `col + lit_int(1) + ...`（二元，字面量） | 10000 正常，20000 溢出 | 700 / 1000 | 700 / 1000 | 500 / 700 |
  | `col + col + ...`（二元，列） | 10000 / 20000 | 700 / 1000 | 700 / 1000 | 500 / 700 |
  | `-(-(...))`（取负） | 5000 / 20000 | 200 / 1000 | 1000 / 5000 | 200 / 1000 |
  | `when(..).then(..).when(..)...`（分支数） | 5000 / 7000 | 300 / 500 | 300 / 500 | 300 / 500 |
  | 只含弱字面量的 `lit_int + lit_int + ...` | 5000 / 20000 | 未测下限，1000 已溢出 | 同左 | 同左 |
  | `Expr` 的文本（`to_string`） | 10000 / 100000 | 1000 / 5000 | 1000 / 5000 | 500 / 1000 |

  所以 JS 和 wasm 上约 500 项的链就接近极限（native 的 7000 个 `when` 分支、20000 项的链才溢出）。需要更长的链时分段求值，或在调用前自己把表达式拆成几次 `with_columns`。没有改成迭代：链里错误的先后要求整条链算完再比较，改写会动 T7 的错误次序，代价高于这个深度的实际需要。`deferred_tests_test.mbt` 的 `an expression chain of 500 terms prints and folds`（500 项的 `to_string`、弱字面量折叠和求值）在四个后端都通过；5000、10000 项的耗时基准在 `bench_test.mbt`（native）。
- **`between` 的 `self`**：只求值一次（`xagg_between`），不再是 `(x >= lo) & (x <= hi)` 里的两次，嵌套的 `between` 因此是线性的。
- **常量条件**：`when(lit(True)).then(col.head(2))` 之类 polars 会直接取分支（长度可以是 2），本库没有 `head`，无此情况。三部分长度不一致且都不是 1 时，本库报 `ShapeMismatch: shapes of `self`, `mask` and `other` are not suitable for `zip_with` operation`（polars 的文案），只有 wbtest。
- **优化器**：所有分支完全相同的 `when(c).then(x).otherwise(x)` polars 会化简掉条件，条件的错误不会出现；本库照常求值。没有对照用例。

## 其它

- `is_in` 的值是 `Series`（`Expr::is_in(values : Series)`），`Show` 是 `Series[<名字>]`，没有名字时是 `Series`；Python 列表参数在 polars 里打印成 `[[1, 2, 3]]`，本库没有这种写法。类型规则与错误文案同 T5 的 `Series::is_in`（表达式层与 Series 层一致）。
- 报错优先级：本任务新增的节点按 T7 的两遍展开（先选择器、再逐表达式查列和重名、最后求值）处理；`Between`、`FillNull`、`Ternary` 在 `check_columns` 里按子节点先后（条件、`then`、`otherwise`；值、下界、上界）查列，`when/err/missing-order*` 等用例钉住。
