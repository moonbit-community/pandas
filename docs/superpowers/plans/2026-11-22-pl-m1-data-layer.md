# M1 数据层 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `smallbearrr/pandas` 里新建 `@pl` 包的数据层：Arrow 式数组与位图、DataType/AnyValue/PolarsError、Series、DataFrame、cast、polars 风格的 Show，四个后端测试全过。

**Architecture:** 新增两个包，与旧的 `src/lib/pandas` 并存、互不引用。`src/pl/internal/arrow`（`@arrow`）只放与 DataFrame 语义无关的底层数组：Bitmap、PrimArray[T]、BoolArray、StrArray 及各自 builder。`src/pl`（`@pl`）放用户可见的一切：DataType、AnyValue、PolarsError、包内私有的 `Column` 枚举、Series、DataFrame、cast、Show。和 polars 行为相关、文档说不清的地方（cast 矩阵、Show 格式），用 lab5 上真实 polars 生成 JSON 标准答案，测试对照。

**Tech Stack:** MoonBit（moon 0.1.20261119 / moonc v0.10.22），仅依赖 `moonbitlang/core`；对照数据用 Python 3.12 + PyPI 最新稳定版 polars（lab5 上查到是 2.1.0，以安装时为准）。

**Spec:** `docs/superpowers/specs/2026-11-22-polars-rewrite-design.md`（执行期间在 lab5 上的副本：`/data/lly-moonbit/m1/spec.md`）。M1 范围见 spec §5.2、§5.3、§6 的 M1 行、§7。

## Global Constraints

- 模块名 `smallbearrr/pandas`，`moon.mod` 不改（不加依赖、不改版本号；NyaCSV 和 x 的依赖留给 M5 删除）。
- `src/pl` 与 `src/pl/internal/arrow` 只允许 import `moonbitlang/core/*`。不许 import `moonbitlang/x`、NyaCSV，也不许 import 旧的 `src/lib/pandas`。
- 不许修改 `src/lib/pandas`、`src/main`、`csv_test`、`README.md`。
- 所有公开类型都是抽象类型，不暴露字段（spec §5.2）。
- 用户输入引起的失败一律 `raise PolarsError`，不许 `abort`；`abort` 只用于库内部不变式被破坏（spec §5.3）。`@arrow` 包是内部包，它的越界等前置条件违例可以 `abort`，由 `@pl` 在调用前校验。
- 错误信息用英文，包含列名、类型或位置。
- 所有选项参数用枚举或 `Bool`/`Int` 带标签参数，不用字符串。
- `@pl` 的每个公开函数有 `///` 文档注释；每个公开函数至少有正常、null、错误三类测试（无错误路径的函数写明“无错误路径”即可）。
- `moon check --target all` 输出中，路径含 `src/pl/` 的告警数为 0（旧包已有的 342 条告警不算，M5 处理）。
- 测试命令在 lab5 上执行，先 `. /data/lly-moonbit/env.sh`。完成标准用 `moon test --target all`（wasm、wasm-gc、js、native 四个后端）。
- DataType 的显示名与 polars 一致：`bool`、`i32`、`i64`、`f32`、`f64`、`str`、`date`、`datetime[μs]`、`null`。
- 负下标语义与 polars 一致：`get`、`row`、`gather` 接受负下标（从末尾数），越界 `raise OutOfBounds`；`slice`、`head`、`tail` 从不报错，超出范围就截断。
- 浮点相等：`Series::equals` / `DataFrame::equals` 里 null 等于 null，NaN 等于 NaN（与 polars 一致，T5/T7 的对照数据如有冲突以对照数据为准并汇报）。

## Review Focus

1. **非 64 位对齐的位图切片**：offset 不是 64 的倍数、长度跨字长边界的两个位图做 `bit_and`/`bit_or`/`bit_not`/`==`，结果必须与逐元素计算一致；底层 word 里切片范围之外的脏位不能影响 `count_ones` 和相等比较。→ T2 的 quickcheck 用任意 offset 覆盖。
2. **空输入**：长度 0 的 Series、0 列的 DataFrame、有列但 0 行的 DataFrame、`head(0)`、`gather([])`、对空表 Show，都不能崩，结果形状正确。→ T4、T6、T7 各有用例。
3. **极端下标**：`slice(Int::min_value(), …)`、`slice(…, length=Int::max_value())`、`get(-len)`、`get(len)`、`gather([-len-1])` 不能整数溢出或 abort，前三个返回截断/正确结果，后两个 `raise OutOfBounds`。→ T4 用例。
4. **浮点特殊值**：NaN、±inf、-0.0 在 cast（转整数、转字符串）、`equals`、Show 里的行为与 polars 一致。→ T5、T7 对照数据包含这些值。
5. **1970 年之前的日期时间**：负天数、负微秒的 Date/Datetime 在 cast（Datetime→Date 必须向下取整：-1µs 是 1969-12-31）和 Show 中正确。→ T1 单测 + T5、T7 对照数据。

---

## 执行组织（主会话负责，不派 agent）

- **Task 0（主会话）**：
  1. 在 `/data/lly-moonbit/pandas` 里 `git fetch --all --prune`，从 `origin/main` 显式建本地分支 `feat/pl-m1`，用 `git worktree add /data/lly-moonbit/m1/int feat/pl-m1` 作为集成目录。
  2. 建 venv：`python3 -m venv /data/lly-moonbit/polars-venv && /data/lly-moonbit/polars-venv/bin/pip install polars`，记下版本号。
  3. 把 spec 和本计划拷到 `/data/lly-moonbit/m1/spec.md`、`/data/lly-moonbit/m1/plan.md`；写 `/data/lly-moonbit/m1/AGENT_RULES.md`（CLAUDE.md §8.3 的禁止事项、lab5 根分区满只写 `/data/lly-moonbit/`、env.sh、测试命令）。
- **每个任务的工作目录**：主会话在派任务前 `rsync -a --exclude _build /data/lly-moonbit/m1/int/ /data/lly-moonbit/m1/tN/`，agent 只在 `tN` 里改；验收后主会话把 `tN` 的改动同步回 `int`，在 `int` 跑全量测试。agent 不 commit；全部 M1 完成后，主会话做成一个 patch 带回 Mac，提交和开 PR 前找 lly 确认。
- **并行批次**：① T1 ‖ T2 → ② T3 → ③ T4 → ④ T5 ‖ T6 → ⑤ T7 → ⑥ T8。
- **测试命令约定**（下文简写）：
  - `CHK` = `cd /data/lly-moonbit/m1/tN && moon check --target all 2>&1 | grep -c 'src/pl/'`，期望输出 `0`。
  - `TEST(pkg)` = `cd /data/lly-moonbit/m1/tN && moon test --target all -p smallbearrr/pandas/<pkg>`，期望最后一行 `Total tests: N, passed: N, failed: 0.`（四个后端各一行）。
  - `TEST1(pkg, filter)` = 同上加 `--target native -f <file>`，用于 TDD 的单文件快速循环。

---

### Task 1: `@pl` 基础类型：PolarsError、DataType、AnyValue、日历换算

**Files:**
- Create: `src/pl/moon.pkg`（暂时只 import core 里需要的包；`@arrow` 的 import 由 T4 加）
- Create: `src/pl/error.mbt`、`src/pl/dtype.mbt`、`src/pl/any_value.mbt`、`src/pl/temporal.mbt`
- Test: `src/pl/error_test.mbt`、`src/pl/dtype_test.mbt`、`src/pl/any_value_test.mbt`、`src/pl/temporal_wbtest.mbt`
- Create: `src/pl/test_helpers_test.mbt`（黑盒测试共用辅助函数）

**Interfaces:**
- Consumes: 无。
- Produces:
  - `pub suberror PolarsError { ColumnNotFound(String); DuplicateColumn(String); SchemaMismatch(String); ShapeMismatch(String); OutOfBounds(String); InvalidOperation(String); ComputeError(String); ParseError(String) }`，`impl Show`：输出 `<变体名>: <message>`，例如 `ColumnNotFound: column 'x' not found`。
  - `pub(all) enum DataType { Boolean; Int32; Int64; Float32; Float64; String; Date; Datetime; Null }`，derive `Eq, Hash, Debug`；`impl Show` 输出上文 Global Constraints 里的显示名；方法 `is_numeric`、`is_integer`、`is_float`、`is_temporal`，均 `(Self) -> Bool`。
  - `pub(all) enum AnyValue { Null; Boolean(Bool); Int32(Int); Int64(Int64); Float32(Float); Float64(Double); String(String); Date(Int); Datetime(Int64) }`，derive `Eq, Debug`（**不实现 Show，Show 由 T7 加**）；方法 `dtype(Self) -> DataType`（`Null` → `DataType::Null`）、`is_null(Self) -> Bool`。
  - 测试辅助（`test_helpers_test.mbt`，所有黑盒测试可用）：`fn[T] raises(f : () -> T raise @pl.PolarsError) -> @pl.PolarsError?`，调用 `f`，抛错则返回 `Some(错误)`，正常返回则 `None`。当前工具链已移除 `try?`，后续任务的错误路径测试统一写成 `assert_true(raises(() => ...) is Some(@pl.OutOfBounds(_)))`。
  - 包内私有（不加 `pub`）：`days_from_civil(y : Int, m : Int, d : Int) -> Int`、`civil_from_days(days : Int) -> (Int, Int, Int)`、`format_date(days : Int) -> String`（`YYYY-MM-DD`，年份不足 4 位补零，负年份带 `-`）、`parse_date(s : StringView) -> Int?`（只接受严格的 `YYYY-MM-DD`，月日越界返回 `None`）、`floor_div64(a : Int64, b : Int64) -> Int64`、`floor_mod64(a : Int64, b : Int64) -> Int64`。

- [ ] **Step 1: 写失败测试**

```moonbit
// temporal_wbtest.mbt
test "civil round trip" {
  assert_eq(days_from_civil(1970, 1, 1), 0)
  assert_eq(days_from_civil(2024, 2, 29), 19782)
  assert_eq(days_from_civil(1969, 12, 31), -1)
  assert_eq(days_from_civil(1900, 1, 1), -25567)
  assert_eq(days_from_civil(9999, 12, 31), 2932896)
  assert_eq(civil_from_days(-1), (1969, 12, 31))
  assert_eq(civil_from_days(19782), (2024, 2, 29))
  assert_eq(format_date(-25567), "1900-01-01")
  assert_eq(parse_date("2024-02-29"), Some(19782))
  assert_eq(parse_date("2023-02-29"), None)
  assert_eq(parse_date("2024-2-1"), None)
  assert_eq(floor_div64(-1L, 86_400_000_000L), -1L)
  assert_eq(floor_mod64(-1L, 86_400_000_000L), 86_399_999_999L)
}
// dtype_test.mbt
test "dtype display names" {
  inspect(@pl.DataType::Datetime, content="datetime[μs]")
  inspect(@pl.DataType::String, content="str")
  assert_true(@pl.DataType::Date.is_temporal())
  assert_false(@pl.DataType::Boolean.is_numeric())
}
// any_value_test.mbt
test "any value dtype" {
  assert_eq(@pl.AnyValue::Int32(1).dtype(), @pl.DataType::Int32)
  assert_eq(@pl.AnyValue::Null.dtype(), @pl.DataType::Null)
}
// error_test.mbt
test "error show" {
  let e : @pl.PolarsError = @pl.ColumnNotFound("column 'x' not found")
  inspect(e, content="ColumnNotFound: column 'x' not found")
}
```

另外加 quickcheck：任意 `days` 在 `[-1_000_000, 3_000_000]` 内，`days_from_civil(civil_from_days(days)) == days`，且 `parse_date(format_date(days)) == Some(days)`（年份在 0000–9999 范围内时）。

- [ ] **Step 2: 跑测试确认失败**：`TEST1(pl, temporal_wbtest.mbt)`，期望编译错误（函数未定义）。
- [ ] **Step 3: 实现**。日历换算用 Howard Hinnant 的 `days_from_civil`/`civil_from_days` 算法（纯整数，支持负数）。
- [ ] **Step 4: 跑测试确认通过**：`TEST(pl)` 四后端全过；`CHK` 为 0。

---

### Task 2: `@arrow` Bitmap

**Files:**
- Create: `src/pl/internal/arrow/moon.pkg`（`for "test"` import `moonbitlang/core/quickcheck`）
- Create: `src/pl/internal/arrow/bitmap.mbt`
- Test: `src/pl/internal/arrow/bitmap_test.mbt`、`src/pl/internal/arrow/bitmap_prop_test.mbt`

**Interfaces:**
- Consumes: 无。
- Produces（全部 `pub`，类型抽象）：
  - `Bitmap`：底层 `FixedArray[UInt64]` + `offset : Int` + `length : Int`，位 1 表示有效。
  - `Bitmap::from_array(Array[Bool]) -> Bitmap`、`Bitmap::filled(length : Int, value : Bool) -> Bitmap`
  - `length(Self) -> Int`、`get(Self, Int) -> Bool`（越界 abort）
  - `count_ones(Self) -> Int`、`count_zeros(Self) -> Int`
  - `slice(Self, offset : Int, length : Int) -> Bitmap`：零拷贝，共享底层数组；范围不合法 abort。
  - `bit_and(Self, Bitmap) -> Bitmap`、`bit_or(Self, Bitmap) -> Bitmap`、`bit_not(Self) -> Bitmap`：长度不同 abort；结果 offset 为 0。
  - `gather(Self, Array[Int]) -> Bitmap`：下标须为 `[0, length)`，否则 abort。
  - `to_array(Self) -> Array[Bool]`、`iter(Self) -> Iter[Bool]`
  - `impl Eq`：按逻辑位比较（长度相同且每一位相同），与 offset、底层 word 内容无关。`impl Debug`。
  - `BitmapBuilder::new(capacity~ : Int = 0) -> BitmapBuilder`、`push(Self, Bool) -> Unit`、`length(Self) -> Int`、`finish(Self) -> Bitmap`。

- [ ] **Step 1: 写失败测试**（`bitmap_test.mbt`）

```moonbit
test "slice is zero copy view with logical equality" {
  let xs = Array::makei(200, i => i % 3 == 0)
  let b = @arrow.Bitmap::from_array(xs)
  let s = b.slice(61, 70)
  assert_eq(s.length(), 70)
  assert_eq(s.to_array(), xs[61:131].to_array())
  assert_eq(s, @arrow.Bitmap::from_array(xs[61:131].to_array()))
  assert_eq(s.count_ones(), xs[61:131].iter().filter(x => x).count())
}
test "ops on unaligned slices" {
  let a = @arrow.Bitmap::filled(130, true).slice(3, 100)
  let b = @arrow.Bitmap::from_array(Array::makei(150, i => i % 2 == 0)).slice(37, 100)
  assert_eq(a.bit_and(b).to_array(), Array::makei(100, i => (i + 37) % 2 == 0))
  assert_eq(b.bit_not().count_ones(), 50)
}
test "empty bitmap" {
  let e = @arrow.Bitmap::from_array([])
  assert_eq(e.length(), 0)
  assert_eq(e.count_ones(), 0)
  assert_eq(e.bit_not().length(), 0)
}
```

- [ ] **Step 2: quickcheck 性质**（`bitmap_prop_test.mbt`），输入为任意 `Array[Bool]` 加任意切片区间（由生成器保证合法）：
  1. `from_array(xs).to_array() == xs`；
  2. `from_array(xs).slice(o, l).to_array() == xs[o:o+l]`；
  3. 两个不同 offset 切出的等长位图，`bit_and`/`bit_or`/`bit_not` 结果的 `to_array()` 等于逐元素 `&&`/`||`/`!`；
  4. `count_ones` 等于 `true` 的个数；
  5. `a == b` 当且仅当 `a.to_array() == b.to_array()`；
  6. `BitmapBuilder` 依次 `push` 后 `finish()` 等于 `from_array`；
  7. `gather(idx).to_array() == idx.map(i => xs[i])`。
- [ ] **Step 3: 跑测试确认失败**：`TEST1(pl/internal/arrow, bitmap_test.mbt)`。
- [ ] **Step 4: 实现**。`count_ones` 用 `UInt64::popcnt` 之类的整 word 计数，首尾不完整的 word 先掩码；`bit_*` 对未对齐的输入按 word 拼接移位后计算，不许逐位循环（这是 1M 行热路径）。
- [ ] **Step 5: 跑测试确认通过**：`TEST(pl/internal/arrow)`；`CHK` 为 0。

---

### Task 3: `@arrow` PrimArray、BoolArray、StrArray 和 builder

**Files:**
- Create: `src/pl/internal/arrow/prim_array.mbt`、`bool_array.mbt`、`str_array.mbt`
- Test: `src/pl/internal/arrow/prim_array_test.mbt`、`bool_array_test.mbt`、`str_array_test.mbt`、`array_prop_test.mbt`

**Interfaces:**
- Consumes: T2 的 `Bitmap`、`BitmapBuilder` 全部接口。
- Produces（三种数组 API 同形，下面以 `PrimArray[T]` 写全，`BoolArray` 的元素类型为 `Bool`、`StrArray` 为 `String`，去掉泛型参数，其余同名同语义）：
  - `PrimArray::new[T](values : FixedArray[T], validity : Bitmap?) -> PrimArray[T]`：长度不等 abort。`BoolArray::new(values : Bitmap, validity : Bitmap?)`。`StrArray::new(values : FixedArray[String], validity : Bitmap?)`。
  - `PrimArray::from_array[T](Array[T]) -> PrimArray[T]`（validity 为 `None`）
  - `PrimArray::from_options[T : Default](Array[T?]) -> PrimArray[T]`（没有 null 时 validity 为 `None`；null 位置的值填 `T::default()`）
  - `length`、`null_count`、`is_valid(Int) -> Bool`、`get(Int) -> T?`、`value(Int) -> T`（不看 validity 的原始值）、`validity() -> Bitmap?`
  - `slice(offset : Int, length : Int) -> Self`：零拷贝，values 与 validity 同步切；范围不合法 abort。
  - `gather(Array[Int]) -> Self`：下标须在 `[0, length)`，否则 abort；结果里没有 null 时 validity 为 `None`。
  - `to_options() -> Array[T?]`、`iter() -> Iter[T?]`
  - `impl[T : Eq] Eq`：逻辑相等（长度、每个位置是否有效、有效位置的值），null 位置的原始值不参与比较。浮点用 `T` 自身的 `==`（NaN 不等于 NaN，NaN 语义由 `@pl` 层处理）。`impl Debug`。
  - 约定：`validity()` 返回 `Some` 不代表一定有 null（切片后可能全有效），调用方以 `null_count()` 为准。
  - `PrimBuilder::new[T : Default](capacity~ : Int = 0) -> PrimBuilder[T]`、`push(T)`、`push_null()`、`push_option(T?)`、`length() -> Int`、`finish() -> PrimArray[T]`。`BoolBuilder`、`StrBuilder` 同形。

- [ ] **Step 1: 写失败测试**，每种数组至少：

```moonbit
test "prim from_options and slice" {
  let a = @arrow.PrimArray::from_options([Some(1L), None, Some(3L), None, Some(5L)])
  assert_eq(a.null_count(), 2)
  let s = a.slice(1, 3)
  assert_eq(s.to_options(), [None, Some(3L), None])
  assert_eq(s.slice(1, 2).to_options(), [Some(3L), None])
  assert_eq(a.gather([4, 0, 0]).to_options(), [Some(5L), Some(1L), Some(1L)])
  assert_true(a.gather([4, 0]).validity() is None)
}
test "null slots do not affect equality" {
  let a = @arrow.PrimArray::new(FixedArray::from_array([1, 99]), Some(@arrow.Bitmap::from_array([true, false])))
  let b = @arrow.PrimArray::new(FixedArray::from_array([1, 7]), Some(@arrow.Bitmap::from_array([true, false])))
  assert_eq(a, b)
}
test "str builder" {
  let b = @arrow.StrBuilder::new()
  b.push("a"); b.push_null(); b.push_option(Some(""))
  assert_eq(b.finish().to_options(), [Some("a"), None, Some("")])
}
test "empty arrays" {
  assert_eq(@arrow.BoolArray::from_array([]).length(), 0)
  assert_eq(@arrow.StrArray::from_options([]).slice(0, 0).null_count(), 0)
}
```

- [ ] **Step 2: quickcheck 性质**（`array_prop_test.mbt`，至少对 `PrimArray[Int64]` 和 `StrArray`）：`from_options(xs).to_options() == xs`；`slice(a,b).slice(c,d) == slice(a+c, d)`；`gather(idx).to_options() == idx.map(i => xs[i])`；builder 逐个 `push_option` 等于 `from_options`。
- [ ] **Step 3: 跑测试确认失败**：`TEST1(pl/internal/arrow, prim_array_test.mbt)`。
- [ ] **Step 4: 实现**。
- [ ] **Step 5: 跑测试确认通过**：`TEST(pl/internal/arrow)`；`CHK` 为 0。

---

### Task 4: `Column` 与 `Series`（构造、访问、切片、gather）

**Files:**
- Modify: `src/pl/moon.pkg`（import `smallbearrr/pandas/pl/internal/arrow`）
- Create: `src/pl/column.mbt`、`src/pl/series.mbt`
- Test: `src/pl/series_test.mbt`、`src/pl/series_prop_test.mbt`

**Interfaces:**
- Consumes: T1 全部；T3 全部数组与 builder。
- Produces：
  - 包内私有 `priv enum Column { Boolean(@arrow.BoolArray); Int32(@arrow.PrimArray[Int]); Int64(@arrow.PrimArray[Int64]); Float32(@arrow.PrimArray[Float]); Float64(@arrow.PrimArray[Double]); String(@arrow.StrArray); Date(@arrow.PrimArray[Int]); Datetime(@arrow.PrimArray[Int64]); Null(Int) }`（`Null` 携带长度）。方法（包内私有）：`length`、`dtype`、`null_count`、`get(Int) -> AnyValue`（下标已校验为非负且在范围内）、`slice(offset, length)`（已规范化）、`gather(Array[Int])`（已规范化）、`equals(Column) -> Bool`（null 等于 null，NaN 等于 NaN）。
  - 包内私有 `normalize_slice(len : Int, offset : Int, length : Int?) -> (Int, Int)`：polars 语义——负 offset 从末尾数，结果截断到 `[0, len]`，不溢出。`normalize_index(len : Int, i : Int) -> Int raise PolarsError`：负数从末尾数，越界 `raise OutOfBounds("index {i} is out of bounds for length {len}")`。T6 复用这两个函数。
  - `pub struct Series`（抽象）。构造：`Series::bool`、`int32`、`int64`、`float32`、`float64`、`str`、`date`（`Array[Int]`，天数）、`datetime`（`Array[Int64]`，微秒），签名形如 `Series::int64(name : String, values : Array[Int64]) -> Series`；每个都有 `_nullable` 版本，参数为 `Array[T?]`；`Series::null(name : String, length : Int) -> Series`；`Series::from_any_values(name : String, values : Array[AnyValue], dtype? : DataType) -> Series raise PolarsError`（不传 `dtype` 时取第一个非 null 值的类型，全 null 得 `Null` 类型；值与目标类型不同即 `raise SchemaMismatch`，M1 不做隐式提升）。
  - 访问：`name() -> String`、`rename(String) -> Series`、`len() -> Int`、`is_empty() -> Bool`、`dtype() -> DataType`、`null_count() -> Int`、`get(Int) -> AnyValue raise PolarsError`、`slice(offset : Int, length? : Int) -> Series`、`head(n~ : Int = 10) -> Series`、`tail(n~ : Int = 10) -> Series`（n 为负时与 polars 一致：`head(-k)` 是去掉最后 k 个）、`gather(Array[Int]) -> Series raise PolarsError`、`to_list() -> Array[AnyValue]`、`to_bool_array`/`to_int32_array`/`to_int64_array`/`to_float32_array`/`to_float64_array`/`to_str_array`（返回 `Array[T?]`，类型不对 `raise SchemaMismatch`；Date/Datetime 不走这些，用 T5 的 `cast`）、`equals(Series, check_names~ : Bool = true, check_dtypes~ : Bool = true) -> Bool`。
  - `impl Eq for Series`（等于 `equals` 默认参数）、`impl Debug for Series`（内容由构建方定，能看出名字、类型和值即可）。

- [ ] **Step 1: 写失败测试**（每个函数正常、null、错误三类；下面是必须包含的断言）

```moonbit
test "series basics" {
  let s = @pl.Series::int64_nullable("a", [Some(1L), None, Some(3L)])
  assert_eq(s.len(), 3)
  assert_eq(s.null_count(), 1)
  assert_eq(s.dtype(), @pl.DataType::Int64)
  assert_eq(s.get(-1), @pl.AnyValue::Int64(3L))
  assert_eq(s.get(1), @pl.AnyValue::Null)
  assert_eq(s.rename("b").name(), "b")
  assert_eq(s.to_int64_array(), [Some(1L), None, Some(3L)])
}
test "series errors" {
  let s = @pl.Series::str("s", ["x"])
  assert_true(raises(() => s.get(1)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => s.get(-2)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => s.gather([0, 5])) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => s.to_int64_array()) is Some(@pl.SchemaMismatch(_)))
  assert_true(raises(() => @pl.Series::from_any_values("m", [@pl.AnyValue::Int64(1L), @pl.AnyValue::String("x")])) is Some(@pl.SchemaMismatch(_)))
}
test "slice head tail clamp" {
  let s = @pl.Series::int32("a", [0, 1, 2, 3, 4])
  assert_eq(s.slice(-2).to_int32_array(), [Some(3), Some(4)])
  assert_eq(s.slice(3, length=100).len(), 2)
  assert_eq(s.slice(Int::min_value(), length=Int::max_value()).len(), 5)
  assert_eq(s.slice(10).len(), 0)
  assert_eq(s.head(n=-2).len(), 3)
  assert_eq(s.tail(n=0).len(), 0)
  assert_eq(s.gather([-1, 0]).to_int32_array(), [Some(4), Some(0)])
  assert_eq(s.gather([]).len(), 0)
}
test "equals treats null and NaN as equal" {
  let nan = 0.0 / 0.0
  assert_eq(@pl.Series::float64_nullable("f", [Some(nan), None]), @pl.Series::float64_nullable("f", [Some(nan), None]))
  assert_false(@pl.Series::int64("a", [1L]).equals(@pl.Series::int64("b", [1L])))
  assert_true(@pl.Series::int64("a", [1L]).equals(@pl.Series::int64("b", [1L]), check_names=false))
}
test "null series" {
  let n = @pl.Series::null("n", 3)
  assert_eq(n.dtype(), @pl.DataType::Null)
  assert_eq(n.null_count(), 3)
  assert_eq(@pl.Series::from_any_values("x", [Null, Null]).dtype(), @pl.DataType::Null)
}
```

- [ ] **Step 2: quickcheck 性质**（`series_prop_test.mbt`）：对任意 `Array[Int64?]` 和任意 `Int` offset/length（含负数和极值），`slice` 的结果等于在 `to_list()` 上按 polars 规则算出的子数组，且从不 abort。
- [ ] **Step 3: 跑测试确认失败**：`TEST1(pl, series_test.mbt)`。
- [ ] **Step 4: 实现**。`Series` 内部为 `name : String` + `col : Column`。
- [ ] **Step 5: 跑测试确认通过**：`TEST(pl)`；`CHK` 为 0。

---

### Task 5: `Series::cast` 与 polars 对照数据基础设施

**Files:**
- Create: `docs/golden/README.md`（polars 版本号、生成方法、“已知差异”一节）
- Create: `docs/golden/scripts/emit.py`、`docs/golden/scripts/cast.py`
- Create（脚本生成，提交）：`docs/golden/cast.json`、`src/pl/golden_cast_data_test.mbt`
- Create: `src/pl/cast.mbt`（含包内私有的浮点、日期时间文本格式化与解析）
- Test: `src/pl/golden_helpers_test.mbt`、`src/pl/cast_test.mbt`、`src/pl/cast_golden_test.mbt`

**Interfaces:**
- Consumes: T1 的日历函数、`floor_div64`；T4 的 `Series`、`Column`。
- Produces：
  - `Series::cast(Self, DataType, strict~ : Bool = true) -> Series raise PolarsError`。
    - 类型对不支持（polars 在 `strict=False` 下也报错的组合）→ `raise InvalidOperation("cannot cast {from} to {to}")`。
    - `strict=true` 时有值转换失败（polars 在 `strict=False` 下会把它变成 null 的情况）→ `raise ComputeError`，信息里带第一个失败值和它的下标。
    - `strict=false` 时转换失败的值变成 null。
    - 具体每一对类型、每个边界值的结果以 `docs/golden/cast.json` 为准。
  - `emit.py` 提供 `emit(name : str, cases : list) -> None`：写 `docs/golden/<name>.json`（`indent=1, sort_keys=True, ensure_ascii=False`），并写 `src/pl/golden_<name>_data_test.mbt`，内容为一个 `let golden_<name> : String =` 后接 `#|` 多行原始字符串，文件头注释写明“由 docs/golden/scripts/<name>.py 生成，勿手改”。T7 复用。
  - 对照数据中 Series 的统一 JSON 编码：`{"name": str, "dtype": "<显示名>", "values": [...]}`，非 null 值一律编码成字符串：整数十进制、浮点用 Python `repr`（`nan`、`inf`、`-inf`、`-0.0`）、布尔 `true`/`false`、字符串原样、Date 为天数、Datetime 为微秒。
  - `golden_helpers_test.mbt` 提供测试辅助 `golden_series(@json.Json) -> @pl.Series raise`（按上面的编码还原 Series），T7 复用。

- [ ] **Step 1: 写对照脚本并生成数据**。`cast.py` 对 9×9 种 (from, to) 组合，各在 `strict=True` 和 `strict=False` 下执行，记录 `{"from": series, "to": "<dtype>", "strict": bool, "result": series}` 或 `{"..., "error": "InvalidOperation" | "ComputeError", "polars_error": "<异常类名: 消息>"}`。错误归类：`strict=False` 也失败 → `InvalidOperation`，否则 → `ComputeError`。各源类型的取值：
  - bool `[true, false, null]`
  - i32 `[0, 1, -1, 2147483647, -2147483648, null]`
  - i64 `[0, 1, -1, 2147483648, 9223372036854775807, -9223372036854775808, null]`
  - f32 `[0.0, -0.0, 1.5, -1.5, 3.4e38, nan, inf, -inf, null]`
  - f64 `[0.0, -0.0, 1.5, -2.5, 0.1, 1e20, 1e300, 123456789.125, nan, inf, -inf, null]`
  - str `["1", "-7", " 3", "1.5", "1e3", "true", "False", "2024-02-29", "1969-12-31", "2024-01-01 12:34:56", "2024-01-01T12:34:56.123456", "abc", "", "9223372036854775808", null]`
  - date `[0, -1, 19782, -25567, 2932896, null]`
  - datetime `[0, -1, 1709210096123456, 86399999999, -86400000001, null]`
  - null `[null, null]`
  
  运行：`/data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/cast.py`，在 README 里记下 polars 版本。
- [ ] **Step 2: 写失败测试**：`cast_golden_test.mbt` 遍历 `golden_cast` 中每个用例，断言结果 `equals`（或错误变体相同）；失败信息里带用例的 from/to/strict。`cast_test.mbt` 写几个可读的单例：

```moonbit
test "cast basics" {
  let s = @pl.Series::int64_nullable("a", [Some(1L), None, Some(3_000_000_000L)])
  assert_eq(s.cast(@pl.DataType::Int32, strict=false).to_int32_array(), [Some(1), None, None])
  assert_true(raises(() => s.cast(@pl.DataType::Int32)) is Some(@pl.ComputeError(_)))
  assert_eq(@pl.Series::datetime("t", [-1L]).cast(@pl.DataType::Date).get(0), @pl.AnyValue::Date(-1))
  assert_eq(s.cast(@pl.DataType::Int64), s)
  assert_eq(@pl.Series::null("n", 2).cast(@pl.DataType::String).null_count(), 2)
}
```
- [ ] **Step 3: 跑测试确认失败**：`TEST1(pl, cast_golden_test.mbt)`。
- [ ] **Step 4: 实现 `cast.mbt`**。同类型 cast 直接返回原 Series。浮点转字符串的格式要与对照数据一致（需要自己写格式化，不能直接用 `Double::to_string`，以对照为准）。
- [ ] **Step 5: 跑测试确认通过**：`TEST(pl)`；`CHK` 为 0。确实无法与 polars 一致的用例，不许删用例，在测试里显式跳过并在 `docs/golden/README.md` 的“已知差异”写明原因，汇报给主会话。

---

### Task 6: `DataFrame`（构造校验、列访问、行操作、相等）

**Files:**
- Create: `src/pl/dataframe.mbt`
- Test: `src/pl/dataframe_test.mbt`

**Interfaces:**
- Consumes: T4 的 `Series`、`Column`、`normalize_slice`、`normalize_index`。
- Produces：
  - `pub struct DataFrame`（抽象）：内部 `Array[Series]` + 列名到下标的 `Map`。
  - `DataFrame::new(Array[Series]) -> DataFrame raise PolarsError`：列名重复 → `DuplicateColumn("column with name '{name}' has more than one occurrence")`；长度不一 → `ShapeMismatch`，信息里带两列的名字和长度。空数组得到 0×0 的表。
  - `DataFrame::empty() -> DataFrame`
  - `height() -> Int`（0 列时为 0）、`width() -> Int`、`shape() -> (Int, Int)`、`columns() -> Array[String]`、`dtypes() -> Array[DataType]`、`schema() -> Array[(String, DataType)]`、`get_columns() -> Array[Series]`（返回新数组，改它不影响 DataFrame）
  - `column(String) -> Series raise PolarsError`（`ColumnNotFound("column '{name}' not found")`）、`get_column_index(String) -> Int?`
  - `head(n~ : Int = 10)`、`tail(n~ : Int = 10)`、`slice(offset : Int, length? : Int)`：语义同 Series，返回 `DataFrame`，不报错。
  - `gather(Array[Int]) -> DataFrame raise PolarsError`
  - `row(Int) -> Array[AnyValue] raise PolarsError`、`get(row : Int, column : String) -> AnyValue raise PolarsError`
  - `equals(DataFrame) -> Bool`：列名、顺序、类型、值都相同；null 等于 null，NaN 等于 NaN。
  - `impl Eq for DataFrame`（= `equals`）、`impl Debug for DataFrame`。

- [ ] **Step 1: 写失败测试**

```moonbit
test "dataframe construct and validate" {
  let df = @pl.DataFrame::new([
    @pl.Series::int64("a", [1L, 2L, 3L]),
    @pl.Series::str_nullable("b", [Some("x"), None, Some("z")]),
  ])
  assert_eq(df.shape(), (3, 2))
  assert_eq(df.schema(), [("a", @pl.DataType::Int64), ("b", @pl.DataType::String)])
  assert_eq(df.get(-1, "b"), @pl.AnyValue::String("z"))
  assert_eq(df.row(1), [@pl.AnyValue::Int64(2L), @pl.AnyValue::Null])
  assert_eq(df.get_column_index("b"), Some(1))
  assert_eq(df.tail(n=2).column("a").to_int64_array(), [Some(2L), Some(3L)])
  assert_eq(df.gather([2, 0]).row(0), [@pl.AnyValue::Int64(3L), @pl.AnyValue::String("z")])
}
test "dataframe errors" {
  let a = @pl.Series::int64("a", [1L])
  assert_true(raises(() => @pl.DataFrame::new([a, a])) is Some(@pl.DuplicateColumn(_)))
  assert_true(raises(() => @pl.DataFrame::new([a, @pl.Series::int64("b", [1L, 2L])])) is Some(@pl.ShapeMismatch(_)))
  let df = @pl.DataFrame::new([a])
  assert_true(raises(() => df.column("zz")) is Some(@pl.ColumnNotFound(_)))
  assert_true(raises(() => df.row(1)) is Some(@pl.OutOfBounds(_)))
  assert_true(raises(() => df.get(0, "zz")) is Some(@pl.ColumnNotFound(_)))
}
test "empty frames" {
  assert_eq(@pl.DataFrame::empty().shape(), (0, 0))
  assert_eq(@pl.DataFrame::new([]).shape(), (0, 0))
  let z = @pl.DataFrame::new([@pl.Series::int64("a", [])])
  assert_eq(z.shape(), (0, 1))
  assert_eq(z.head().shape(), (0, 1))
  assert_eq(z.gather([]).shape(), (0, 1))
}
test "get_columns does not leak internal state" {
  let df = @pl.DataFrame::new([@pl.Series::int64("a", [1L])])
  let cols = df.get_columns()
  cols.push(@pl.Series::int64("b", [2L]))
  assert_eq(df.width(), 1)
}
```

- [ ] **Step 2: 跑测试确认失败**：`TEST1(pl, dataframe_test.mbt)`。
- [ ] **Step 3: 实现**。
- [ ] **Step 4: 跑测试确认通过**：`TEST(pl)`；`CHK` 为 0。

---

### Task 7: polars 风格的 Show（AnyValue、Series、DataFrame）

**Files:**
- Create: `docs/golden/scripts/show.py`
- Create（脚本生成，提交）：`docs/golden/show.json`、`src/pl/golden_show_data_test.mbt`
- Create: `src/pl/format.mbt`
- Test: `src/pl/show_golden_test.mbt`、`src/pl/show_test.mbt`

**Interfaces:**
- Consumes: T5 的 `emit.py`、`golden_series`、cast 里的浮点与日期时间格式化函数（如 T5 的格式化与表格单元格格式不同，T7 新写单元格格式化，不改 T5 的 cast 输出）；T6 的 `DataFrame`。
- Produces：
  - `impl Show for AnyValue`：输出与 polars 表格单元格相同的文本（字符串是否带引号、浮点格式、日期时间格式都以 `show.json` 为准）。
  - `impl Show for Series`、`impl Show for DataFrame`：输出与 polars 在默认配置下 `str(series)` / `str(df)` 完全一致（含 `shape:` 行、边框字符、dtype 行、行列折叠、长字符串截断）。

- [ ] **Step 1: 写对照脚本并生成数据**。`show.py` 开头调用 `pl.Config.restore_defaults()`，对下列输入记录 `{"frame": [series...], "expected": str(df)}`，以及若干 `{"series": series, "expected": str(series)}`：
  1. 混合小表：`a` i64 `[1, 2, null]`；`b` str `["x", null, "a\"q"]`；`c` f64 `[1.0, 2.5, nan]`；`d` bool `[true, null, false]`。
  2. 25 行的 i64 单列（行折叠）。
  3. 12 列 × 2 行的 i32 表（列折叠）。
  4. 时间与窄类型：date `[-25567, -1, 0, 19782]`；datetime `[-1, 0, 1709210096123456, 86399999999]`；f32 `[0.1, -0.0, inf, 3.4e38]`；i32 `[-2147483648, 0, 1, 2147483647]`。
  5. 浮点格式：f64 `[0.1, 1e20, 1e-7, 123456789.125, -inf, 1.0/3]`。
  6. 字符串：空串、40 个字符的串、含换行的串、含 `"` 的串。
  7. Null 类型列 `[null, null]`。
  8. 0 列的空表；有列 `a`(i64)、`b`(str) 但 0 行的表。
  9. Series：混合小表的 `a`、25 行那列、0 长度的 str Series。
- [ ] **Step 2: 写失败测试**：`show_golden_test.mbt` 逐个用例断言 `df.to_string() == expected`（失败时打印两者）。`show_test.mbt` 里另写：非 ASCII 字符串（如 `"数据"`）的表能正常输出、不 abort（宽度不做对照）。
- [ ] **Step 3: 跑测试确认失败**：`TEST1(pl, show_golden_test.mbt)`。
- [ ] **Step 4: 实现 `format.mbt`**。
- [ ] **Step 5: 跑测试确认通过**：`TEST(pl)`；`CHK` 为 0。无法一致的用例按 T5 Step 5 的规则处理。

---

### Task 8: bench、包级文档测试、公开 API 收尾

**Files:**
- Create: `src/pl/bench_test.mbt`（`moon.pkg` 里 `for "test"` import `moonbitlang/core/bench`）
- Create: `src/pl/README.mbt.md`
- Create: `docs/bench/m1.md`
- Modify: `src/pl/*.mbt` 中缺文档注释的公开函数（只加注释，不改行为）

**Interfaces:**
- Consumes: T1–T7 全部公开 API。
- Produces: `src/pl/pkg.generated.mbti` 与 `src/pl/internal/arrow/pkg.generated.mbti`（由 `moon info` 生成，提交，作为 M1 的公开 API 契约）。

- [ ] **Step 1: 写 bench**，每项 1,000,000 行：`Series::int64` 构造；`Series::int64_nullable` 构造（10% null）；`slice` 1000 次；`gather` 1M 个随机下标；`cast` i64→f64；`Bitmap::bit_and`（两个不同 offset 的切片）；`DataFrame::new` 10 列。
- [ ] **Step 2: 跑 bench**：`moon bench --target native -p smallbearrr/pandas/pl`，结果原样写进 `docs/bench/m1.md`（注明机器是 lab5、日期、moon 版本）。任何一项在 1M 行下超过 1 秒，汇报给主会话（视为可能的 O(n²)）。
- [ ] **Step 3: 写 `src/pl/README.mbt.md`**：用 ```mbt check 代码块演示构造 Series 和 DataFrame、`get`、`slice`、`cast`、错误处理和打印（打印用 `inspect` 对照输出），随 `moon test` 执行。
- [ ] **Step 4: 收尾检查**：`moon info` 生成 mbti；人工过一遍 `src/pl/pkg.generated.mbti`，确认没有意外暴露的字段、函数或 `pub(all)` 结构；所有公开函数有 `///` 注释。
- [ ] **Step 5: 全量验证**：在 `tN` 下跑 `moon test --target all`（整个模块，含旧包 79 个测试），四后端全过；`CHK` 为 0；`moon fmt` 后无改动。

---

## M1 完成后（主会话）

1. 在 `int` 跑全量：`moon test --target all`、`moon check --target all`、`moon bench`。
2. 派独立 reviewer（sonnet，general-purpose，只读，每人一个维度）：① API 与 spec §5.2/§5.3/§5.7 的对照；② null、NaN、下标边界与不变式（含本计划 Review Focus）；③ 测试质量（是否有空断言、被跳过的对照用例是否都写进了“已知差异”）。
3. 修完后把 spec 放进 `docs/superpowers/specs/2026-11-22-polars-rewrite-design.md`、本计划放进 `docs/superpowers/plans/2026-11-22-pl-m1-data-layer.md`，做成 patch 带回 Mac，找 lly 确认后 commit、push、开 PR。
