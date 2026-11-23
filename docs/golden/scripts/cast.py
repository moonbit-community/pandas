"""Generates the Series.cast golden data (docs/golden/cast.json).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/cast.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import polars as pl

from emit import DTYPE_NAMES, emit, encode_series, polars_dtype, series_from_spec

nan = float("nan")
inf = float("inf")

SOURCES = {
    "bool": [True, False, None],
    "i32": [0, 1, -1, 2147483647, -2147483648, None],
    "i64": [
        0, 1, -1, 2147483648, 9223372036854775807, -9223372036854775808,
        -2147483648, 2147483647, 2147483649, -2147483649, None,
    ],
    "f32": [0.0, -0.0, 1.5, -1.5, 3.4e38, nan, inf, -inf, None],
    "f64": [
        0.0, -0.0, 1.5, -2.5, 0.1, 1e20, 1e300, 123456789.125, nan, inf, -inf,
        -2147483648.0, -2147483649.0, 2147483647.0, 2147483648.0,
        -9223372036854775808.0, 9223372036854775807.0, None,
    ],
    "str": [
        "1", "-7", " 3", "1.5", "1e3", "true", "False", "2024-02-29",
        "1969-12-31", "2024-01-01 12:34:56", "2024-01-01T12:34:56.123456",
        "abc", "", "9223372036854775808", None,
    ],
    # 106751991 is the largest day count whose microseconds fit Int64. polars
    # panics (out-of-range date) when it formats a date beyond about +-95.7M
    # days and when a strict Date -> Datetime cast overflows; `main` leaves
    # exactly those values out of the affected cases.
    "date": [
        0, -1, 19782, -25567, 2932896,
        106751991, 106751992, -106751991, -106751992, None,
    ],
    "datetime[μs]": [0, -1, 1709210096123456, 86399999999, -86400000001, None],
    "null": [None, None],
}


def try_cast(s, to, strict):
    """Returns (result, error message, panicked). polars panics (a
    `PanicException`, which is a BaseException) on some out-of-range dates."""
    try:
        return s.cast(to, strict=strict), None, False
    except Exception as e:  # noqa: BLE001
        return None, f"{type(e).__name__}: {e}", False
    except BaseException as e:  # noqa: BLE001  (pyo3 PanicException)
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        return None, f"{type(e).__name__}: {e}", True


def run(s, to, strict):
    """Casts `s`; when polars panics, drops the values that panic one by one
    and retries. Returns (series used, result, error, omitted values)."""
    r, err, panicked = try_cast(s, to, strict)
    if not panicked:
        return s, r, err, []
    keep = []
    omitted = []
    for i in range(s.len()):
        one = s.slice(i, 1)
        _, _, p = try_cast(one, to, strict)
        (omitted if p else keep).append(i)
    used = pl.concat([s.slice(i, 1) for i in keep]) if keep else s.clear()
    omitted_enc = [encode_series(s.slice(i, 1))["values"][0] for i in omitted]
    r, err, panicked = try_cast(used, to, strict)
    assert not panicked, "polars still panics after dropping the bad values"
    return used, r, err, omitted_enc


def main():
    cases = []
    for src_name, values in SOURCES.items():
        s = series_from_spec("a", src_name, values)
        for dst_name in DTYPE_NAMES:
            to = polars_dtype(dst_name)
            _, _, lenient_err, _ = run(s, to, False)
            for strict in (True, False):
                used, r, err, omitted = run(s, to, strict)
                case = {"from": encode_series(used), "to": dst_name, "strict": strict}
                if omitted:
                    case["omitted_values"] = omitted
                if lenient_err is not None:
                    # even strict=False fails: the type pair is unsupported
                    case["error"] = "InvalidOperation"
                    case["polars_error"] = lenient_err
                elif err is not None:
                    # only strict=True fails: a value cannot be converted
                    case["error"] = "ComputeError"
                    case["polars_error"] = err
                else:
                    case["result"] = encode_series(r)
                case["id"] = f"{src_name}->{dst_name}/{'strict' if strict else 'lenient'}"
                cases.append(case)
    emit("cast", cases)
    print(f"polars {pl.__version__}: wrote {len(cases)} cases")


main()
