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
        "abc", "", "9223372036854775808",
        # str -> f32 must round the exact decimal value once (Rust's
        # `f32::from_str`): the f32::MAX / infinity boundary (the midpoint is
        # 2^128 - 2^103 = 3.40282356779733661637...e38), the smallest
        # subnormals (halfway to zero is 2^-150 = 7.0064923216240853546...e-46,
        # halfway from 1 to 2 subnormals is 2.1019476964872256...e-45) and
        # decimal strings that double rounding through f64 gets wrong.
        "3.4028235677973366e38", "3.4028235677973367e38", "3.4028235e38",
        "3.40282357e38", "3.4028236e38", "1e39", "-3.4028235677973366e38",
        "-1e39", "1e-45", "7e-46", "7.006492321624085e-46",
        "7.006492321624086e-46", "2.1019476964872255e-45",
        "2.1019476964872257e-45", "1.17549435e-38", "-1.4e-45", "1e-400",
        "1.00000005960464477539062500001", "1.0000000596046447753906250",
        "1.00000017881393432617187499", "1.000000178813934326171875",
        "16777217", "16777217.0000000001", "0.1", "3.4028234663852886e38",
        # exact ties below 1.0 (0.5 + 2^-25), with a leading `0.` and `.`, and
        # one digit past the tie
        "0.5000000298023223876953125", ".5000000298023223876953125",
        "0.50000002980232238769531251",
        # signed zero
        "-0", "-0.0", "-0e5", "-1e-400",
        # exponents beyond Int32 (and beyond Int64) are saturated, not wrapped
        "1e4294967297", "-1e4294967297", "1e-4294967297",
        "1e99999999999999999999",
        # Int64 overflow: 19 digits whose first 18 exceed 922337203685477580
        "9223372036854775810", "-9223372036854775810", "9223372036854775819",
        # str -> f64: a 400-digit mantissa with a negative exponent. The value
        # is 1e309 (inf), -1e310 (-inf), 1e308 (finite), 1e307, 1e-0 ... and
        # `0.<400 zeros>1e400` is 0.1.
        "1" + "0" * 400 + "e-91", "-1" + "0" * 400 + "e-90",
        "1" + "0" * 400 + "e-92", "1" + "0" * 400 + "e-93",
        "1" + "0" * 400 + "e-400", "1" + "0" * 400 + "e5",
        "0." + "0" * 400 + "1e400", "1" + "0" * 400 + "e-10000000000",
        "17976931348623157" + "0" * 292, "17976931348623159" + "0" * 292,
        None,
    ],
    # 106751991 is the largest day count whose microseconds fit Int64. polars
    # panics (out-of-range date) when it formats a date beyond about +-95.7M
    # days and when a strict Date -> Datetime cast overflows; `main` leaves
    # exactly those values out of the affected cases.
    "date": [
        0, -1, 19782, -25567, 2932896,
        106751991, 106751992, -106751991, -106751992, None,
    ],
    # 1152921573326323713 = 2^60 + 2^36 + 1: rounding it to f32 through f64
    # (instead of directly) gives a different value
    "datetime[μs]": [
        0, -1, 1709210096123456, 86399999999, -86400000001, 1152921573326323713,
        None,
    ],
    "null": [None, None],
}


def error_of(e):
    """(variant name, first line of the message): polars' `InvalidOperationError`
    is the variant `InvalidOperation`. Only the first line is the contract:
    polars appends hints on further lines."""
    name = type(e).__name__
    if name.endswith("Error"):
        name = name[: -len("Error")]
    return name, str(e).split("\n")[0]


def try_cast(s, to, strict):
    """Returns (result, (variant, first line) of the error, panicked). polars
    panics (a `PanicException`, which is a BaseException) on some out-of-range
    dates."""
    try:
        return s.cast(to, strict=strict), None, False
    except Exception as e:  # noqa: BLE001
        return None, error_of(e), False
    except BaseException as e:  # noqa: BLE001  (pyo3 PanicException)
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        return None, error_of(e), True


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


def inputs():
    """(id prefix, source series): the `SOURCES` columns, then for every type
    an empty series and (except `null`, already in `SOURCES`) an all-null
    one. polars casts those to every type, unsupported pairs included."""
    for src_name, values in SOURCES.items():
        yield src_name, series_from_spec("a", src_name, values)
    for src_name in DTYPE_NAMES:
        yield f"{src_name}[empty]", series_from_spec("a", src_name, [])
        if src_name != "null":
            yield f"{src_name}[all-null]", series_from_spec("a", src_name, [None, None, None])


def main():
    cases = []
    for src_name, s in inputs():
        for dst_name in DTYPE_NAMES:
            to = polars_dtype(dst_name)
            _, _, lenient_err, _ = run(s, to, False)
            for strict in (True, False):
                used, r, err, omitted = run(s, to, strict)
                case = {"from": encode_series(used), "to": dst_name, "strict": strict}
                if omitted:
                    case["omitted_values"] = omitted
                # even strict=False fails: the type pair is unsupported; only
                # strict=True fails: a value cannot be converted
                failure = lenient_err if lenient_err is not None else err
                if failure is not None:
                    case["error"], case["message"] = failure
                else:
                    case["result"] = encode_series(r)
                case["id"] = f"{src_name}->{dst_name}/{'strict' if strict else 'lenient'}"
                cases.append(case)
    emit("cast", cases)
    print(f"polars {pl.__version__}: wrote {len(cases)} cases")


main()
