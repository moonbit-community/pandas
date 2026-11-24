"""Shared helpers for the polars golden-data scripts.

Usage from a generator script (run from the repository root):

    from emit import emit, encode_series, series_from_spec
    emit("cast", cases)

`emit` writes `docs/golden/<name>.json` and the embedded MoonBit copy
`src/pl/golden_<name>_data_test.mbt` (tests cannot read files at runtime).
"""
import json
import math
import os

import polars as pl

# Display names of the nine supported dtypes (same as `DataType`'s Show).
DTYPE_NAMES = {
    "bool": pl.Boolean,
    "i32": pl.Int32,
    "i64": pl.Int64,
    "f32": pl.Float32,
    "f64": pl.Float64,
    "str": pl.String,
    "date": pl.Date,
    "datetime[μs]": pl.Datetime("us"),
    "null": pl.Null,
}


def dtype_name(dtype):
    """Display name of a polars dtype, e.g. `pl.Int32` -> `"i32"`."""
    if dtype == pl.Datetime:
        return "datetime[μs]"
    for name, dt in DTYPE_NAMES.items():
        if dtype == dt:
            return name
    raise ValueError(f"unsupported dtype {dtype}")


def polars_dtype(name):
    return DTYPE_NAMES[name]


def float_repr(v):
    """Python `repr` for floats: `nan`, `inf`, `-inf`, `-0.0`."""
    return repr(float(v))


def encode_value(v, dtype):
    """Encode one non-null Python value (as returned by `Series.to_list()`
    after the temporal types were converted to integers) as a string."""
    if v is None:
        return None
    if dtype == "bool":
        return "true" if v else "false"
    if dtype in ("i32", "i64", "date", "datetime[μs]"):
        return str(int(v))
    if dtype in ("f32", "f64"):
        return float_repr(v)
    if dtype == "str":
        return v
    raise ValueError(f"cannot encode value of dtype {dtype}")


def encode_series(s):
    """`{"name", "dtype", "values"}`; non-null values are strings, nulls are
    JSON null. Date is days since 1970-01-01, Datetime is microseconds."""
    name = dtype_name(s.dtype)
    if name == "date":
        raw = s.cast(pl.Int32).to_list()
    elif name == "datetime[μs]":
        raw = s.cast(pl.Int64).to_list()
    else:
        raw = s.to_list()
    return {
        "name": s.name,
        "dtype": name,
        "values": [encode_value(v, name) for v in raw],
    }


# Types polars has but this library does not, and what they map to
# (M2 global constraints): UInt32/UInt64 -> Int64, Int8/Int16/UInt8/UInt16
# -> Int32. `count`, `len`, `n_unique`, `arg_sort`, `rank`, ... return these.
OURS_DTYPE_MAP = [
    (pl.UInt32, pl.Int64),
    (pl.UInt64, pl.Int64),
    (pl.Int8, pl.Int32),
    (pl.Int16, pl.Int32),
    (pl.UInt8, pl.Int32),
    (pl.UInt16, pl.Int32),
]


def to_ours(series):
    """`(series, original_dtype_name)`: `series` cast to the library's
    dtype per `OURS_DTYPE_MAP` (strict, so a value that does not fit raises;
    types the library has are returned unchanged), `original_dtype_name` is
    `str(dtype)` of the polars result (e.g. `"UInt32"`). `encode_series` is
    not affected: call it on the first element of the pair."""
    original = str(series.dtype)
    for src, dst in OURS_DTYPE_MAP:
        if series.dtype == src:
            return series.cast(dst, strict=True), original
    return series, original


def series_from_spec(name, dtype, values):
    """Build a polars Series from python values; temporal values are given as
    integers (days / microseconds)."""
    if dtype == "date":
        return pl.Series(name, values, dtype=pl.Int32).cast(pl.Date)
    if dtype == "datetime[μs]":
        return pl.Series(name, values, dtype=pl.Int64).cast(pl.Datetime("us"))
    if dtype == "null":
        return pl.Series(name, values, dtype=pl.Null)
    return pl.Series(name, values, dtype=polars_dtype(dtype))


def _repo_root():
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.normpath(os.path.join(here, "..", "..", ".."))


def _compact_text(doc):
    """Compact layout of a document `{section: dict | list}`: one entry per
    line (`"key":value` for a dict section, the element for a list section),
    values as minimal JSON. Sections are written in sorted order, dict
    sections with sorted keys, list sections in list order."""
    dump = lambda v: json.dumps(v, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    out = ["{"]
    names = sorted(doc)
    for i, key in enumerate(names):
        sec = doc[key]
        if isinstance(sec, dict):
            open_, close = "{", "}"
            rows = [f"{dump(k)}:{dump(sec[k])}" for k in sorted(sec)]
        else:
            open_, close = "[", "]"
            rows = [dump(v) for v in sec]
        out.append(f" {dump(key)}:{open_}")
        out += ["  " + r + ("," if j < len(rows) - 1 else "") for j, r in enumerate(rows)]
        out.append(" " + close + ("," if i < len(names) - 1 else ""))
    out.append("}")
    return "\n".join(out)


def emit(name, cases, compact=False):
    """Write `docs/golden/<name>.json` and `src/pl/golden_<name>_data_test.mbt`.

    By default `cases` (any JSON value) is written with `indent=1`. With
    `compact=True` it must be a dict whose values are dicts or lists and is
    written by `_compact_text` (one entry per line, no extra spaces), for data
    sets that would otherwise be large."""
    root = _repo_root()
    if compact:
        text = _compact_text(cases)
    else:
        text = json.dumps(cases, indent=1, sort_keys=True, ensure_ascii=False)
    json_path = os.path.join(root, "docs", "golden", f"{name}.json")
    with open(json_path, "w", encoding="utf-8") as f:
        f.write(text + "\n")
    lines = [
        f"// 由 docs/golden/scripts/{name}.py 生成，勿手改",
        "",
        f"///|",
        f"let golden_{name} : String =",
    ]
    for line in text.split("\n"):
        lines.append("  #|" + line)
    mbt_path = os.path.join(root, "src", "pl", f"golden_{name}_data_test.mbt")
    with open(mbt_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
