# 与 polars 的已知差异：排序、去重、is_in（T5）

数据：`docs/golden/sort.json`、`docs/golden/sort_multi.json`（`scripts/sort.py` 生成，polars 2.1.0）。

| 场景 | polars | 本库 |
| --- | --- | --- |
| `Series.sort` 的浮点列里 `-0.0` 与 `0.0` 的相对顺序 | 32 行以上时不保证稳定（随机数据里 `sort()` 与 `gather(arg_sort())` 的 `-0.0`/`0.0` 顺序不同；`arg_sort` 一直是稳定的） | `sort` 与 `arg_sort` 同一个稳定排序，`-0.0` 与 `0.0` 保持原来的先后。对应的对照用例（`sort/random/f32/*`、`sort/random/f64/*`）用 `s.gather(s.arg_sort(...))` 作期望，用例里带 `note` 字段 |
| `Series.unique(maintain_order=False)` | 顺序不保证 | 总是按首次出现的顺序返回（只有 `maintain_order=true` 时才是承诺） |
| `Series.is_in(other)`，`other` 与自身同类型的 Series | 2.1 里已弃用（要求 `implode`），仍可用，语义是把 `other` 当集合 | 同样把 `other` 当集合；对照数据用不带 `implode` 的写法生成（`warnings` 已屏蔽） |
| `is_in` 的 `nulls_equal` 参数 | 默认 `false`，可设 `true` | 不提供该参数，只实现默认行为：自身的 null 得 null，`other` 里的 null 不匹配任何值 |
| `UniqueKeep::Any` | 不保证取哪一行 | 取第一行（与 `First` 相同；`maintain_order=True` 时 polars 实测也是第一行） |
| `unique` 的 `-0.0` 与 `0.0` | 视为同一个值，保留先出现的那个（实测） | 相同 |
| `is_in` 里 `Float32` 对 `Float64` | 先提升到 `Float64` 再比较（`0.1f` 不等于 `0.1`，实测） | 相同 |
