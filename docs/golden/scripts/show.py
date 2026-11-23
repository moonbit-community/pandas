"""Generates the Show golden data (docs/golden/show.json): `str(df)` and
`str(series)` under polars' default configuration.

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/show.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import polars as pl

from emit import emit, encode_series, series_from_spec

pl.Config.restore_defaults()

nan = float("nan")
inf = float("inf")


def S(name, dtype, values):
    return series_from_spec(name, dtype, values)


def frame_case(case_id, series):
    df = pl.DataFrame(series) if series else pl.DataFrame()
    return {
        "id": case_id,
        "frame": [encode_series(s) for s in series],
        "expected": str(df),
    }


def series_case(case_id, s):
    return {"id": case_id, "series": encode_series(s), "expected": str(s)}


def main():
    cases = []

    # 1. mixed small table
    a = S("a", "i64", [1, 2, None])
    mixed = [
        a,
        S("b", "str", ["x", None, 'a"q']),
        S("c", "f64", [1.0, 2.5, nan]),
        S("d", "bool", [True, None, False]),
    ]
    cases.append(frame_case("frame/mixed", mixed))

    # 2. 25-row single column (row truncation)
    long_col = S("n", "i64", list(range(25)))
    cases.append(frame_case("frame/rows25", [long_col]))
    # boundary heights around the default 10-row cutoff
    for h in (0, 1, 9, 10, 11, 12):
        cases.append(frame_case(f"frame/rows{h}", [S("n", "i64", list(range(h)))]))

    # 3. 12 columns x 2 rows (column truncation)
    wide = [S(f"c{i}", "i32", [i, -i]) for i in range(12)]
    cases.append(frame_case("frame/cols12", wide))
    for w in (7, 8, 9, 10):
        cases.append(
            frame_case(f"frame/cols{w}", [S(f"c{i}", "i32", [i, -i]) for i in range(w)])
        )

    # 4. temporal and narrow types
    narrow = [
        S("d", "date", [-25567, -1, 0, 19782]),
        S("t", "datetime[μs]", [-1, 0, 1709210096123456, 86399999999]),
        S("f", "f32", [0.1, -0.0, inf, 3.4e38]),
        S("i", "i32", [-2147483648, 0, 1, 2147483647]),
    ]
    cases.append(frame_case("frame/temporal_narrow", narrow))
    # extra: datetime precision variants and far dates
    cases.append(
        frame_case(
            "frame/datetime_variants",
            [
                S(
                    "t",
                    "datetime[μs]",
                    [0, 1000, 1000000, 60000000, 1, 123000, None],
                ),
                S("d", "date", [2932896, -719162, 100000, 10000, None, 0, -1]),
            ],
        )
    )

    # 5. float formatting
    cases.append(
        frame_case(
            "frame/floats",
            [S("x", "f64", [0.1, 1e20, 1e-7, 123456789.125, -inf, 1.0 / 3])],
        )
    )
    cases.append(
        frame_case(
            "frame/floats2",
            [
                S(
                    "x",
                    "f64",
                    [1e15, 1e16, 12345678.9, 1e-5, 0.0001, -0.0, 5e-324, 1.7976931348623157e308],
                ),
                S("y", "f32", [1e12, 1e13, 1e-6, 1e-7, 16777216.0, 3.14159274, 0.5, None]),
            ],
        )
    )

    # 6. strings
    strings = S(
        "s",
        "str",
        ["", "0123456789012345678901234567890123456789", "line1\nline2", 'say "hi"'],
    )
    cases.append(frame_case("frame/strings", [strings]))
    cases.append(
        frame_case(
            "frame/strings_more",
            [
                S(
                    "s",
                    "str",
                    [
                        "a" * 30,
                        "a" * 31,
                        "b" * 32,
                        "tab\there",
                        "back\\slash",
                        "cr\rx",
                        None,
                    ],
                )
            ],
        )
    )

    # 7. Null-typed column
    cases.append(frame_case("frame/null_col", [S("z", "null", [None, None])]))
    cases.append(
        frame_case(
            "frame/null_col_mixed",
            [S("z", "null", [None, None]), S("a", "i64", [1, 2])],
        )
    )

    # 8. empty frames
    cases.append(frame_case("frame/no_columns", []))
    cases.append(
        frame_case(
            "frame/zero_rows",
            [S("a", "i64", []), S("b", "str", [])],
        )
    )
    cases.append(
        frame_case(
            "frame/zero_rows_all",
            [
                S("b", "bool", []),
                S("i", "i32", []),
                S("f", "f32", []),
                S("d", "date", []),
                S("t", "datetime[μs]", []),
                S("n", "null", []),
            ],
        )
    )

    # extra frames: int64 extremes, long column names, bool
    cases.append(
        frame_case(
            "frame/int64_extremes",
            [S("big", "i64", [-9223372036854775808, 9223372036854775807, None])],
        )
    )
    cases.append(
        frame_case(
            "frame/long_name",
            [S("a_rather_long_column_name_here", "i64", [1, 22, 333])],
        )
    )
    cases.append(
        frame_case(
            "frame/bools",
            [S("b", "bool", [True, False, None])],
        )
    )
    cases.append(
        frame_case(
            "frame/all_null_cols",
            [S("a", "i64", [None, None]), S("b", "str", [None, None])],
        )
    )

    # 9. Series
    cases.append(series_case("series/mixed_a", a))
    cases.append(series_case("series/rows25", long_col))
    cases.append(series_case("series/empty_str", S("s", "str", [])))
    for case_id, s in [
        ("series/str", mixed[1]),
        ("series/f64", mixed[2]),
        ("series/bool", mixed[3]),
        ("series/date", narrow[0]),
        ("series/datetime", narrow[1]),
        ("series/f32", narrow[2]),
        ("series/i32", narrow[3]),
        ("series/null", S("z", "null", [None, None])),
        ("series/strings", strings),
        ("series/rows10", S("n", "i64", list(range(10)))),
        ("series/rows11", S("n", "i64", list(range(11)))),
        ("series/empty_i64", S("n", "i64", [])),
        ("series/empty_null", S("n", "null", [])),
        ("series/empty_name", S("", "i64", [1, 2])),
        ("series/one", S("one", "f64", [1.5])),
    ]:
        cases.append(series_case(case_id, s))

    # ---- additions: float cell rules (fmt_float), f32 widening, ties -------
    cases.append(
        frame_case(
            "frame/floats_boundaries",
            [
                S(
                    "x",
                    "f64",
                    [
                        999999.0, 999999.5, 1e6, 12345678.0, -99999999.0, -123456789.0,
                        1234567890.0, 0.5, -1.5, 1e-6, 9.99e-7, 0.0000015, 123456.7891,
                        -0.0000001234, 12345500000.0, 12344500000.0, 0.99999999,
                        12.1234565, 1.23456789012, 100.0, -5.0, 1e300, 5e-324,
                    ],
                )
            ],
        )
    )
    cases.append(
        frame_case(
            "frame/f32_widening",
            [
                S(
                    "x",
                    "f32",
                    [
                        1234.5678, 0.12345678, 100.123, 3.4e-5, 1234567.0, 999999.0,
                        -12345678.0, 123456789.0, 99999999.0, 0.99999999, 1.5, 1e-45,
                    ],
                )
            ],
        )
    )
    cases.append(
        series_case("series/floats_boundaries", S("x", "f64", [999999.5, 1e6, 12.1234565, 1e-7, 2.5e-7]))
    )

    cases.append(
        frame_case(
            "frame/floats_carry",
            [
                S(
                    "x",
                    "f64",
                    [
                        9.99996e20, -9.99996e20, 999999.9999999, 0.9999999999,
                        99999.9999999999, 9.999949999999999e-7, 1.00005e10, 1.00015e10,
                        2.5e-6, 0.1 + 0.2, 1e22, 123456.7, 100000.5, 0.000012345678,
                    ],
                )
            ],
        )
    )

    # ---- additions: temporal extremes ---------------------------------------
    cases.append(
        frame_case(
            "frame/temporal_far",
            [
                S("d", "date", [3000000, -1000000, 95000000, -95000000, None]),
                S(
                    "t",
                    "datetime[μs]",
                    [400000000000000000, -400000000000000000, 8000000000000000000, -8000000000000000000, None],
                ),
            ],
        )
    )

    # ---- additions: strings, widths, multi-line cells ----------------------
    cases.append(
        frame_case(
            "frame/strings_edge",
            [
                S(
                    "s",
                    "str",
                    ["x\n", "a\r\nb", " pad ", "é" * 31, "é" * 30, "\n", "a\n\nb"],
                ),
            ],
        )
    )
    cases.append(
        frame_case(
            "frame/multiline_two_cols",
            [S("a", "str", ["l1\nl2\nl3", "x"]), S("b", "i64", [1, 2])],
        )
    )
    cases.append(
        frame_case(
            "frame/wide_chars",
            [
                S("s", "str", ["数据", "ａｂ", "😀x", "日本語" * 5, "日本語" * 6]),
                S("t", "i64", [1, 2, 3, 4, 5]),
            ],
        )
    )
    cases.append(
        frame_case(
            "frame/wide_truncated",
            [S("s", "str", ["日本語" * 11, "数" * 16, "ok"]), S("t", "i64", [1, 2, 3])],
        )
    )
    cases.append(
        frame_case(
            "frame/name_edge",
            [S("a" * 31, "i64", [1]), S("b\nc", "i64", [2]), S("数据", "i64", [3])],
        )
    )
    cases.append(
        frame_case(
            "frame/name_30",
            [S("n" * 30, "i64", [1])],
        )
    )
    cases.append(
        frame_case(
            "frame/folded_both",
            [S(f"c{i}", "i64", list(range(25))) for i in range(12)],
        )
    )
    cases.append(
        frame_case(
            "frame/folded_mixed_types",
            [
                S("a", "str", [str(i) for i in range(11)]),
                S("b", "f64", [i / 3 for i in range(11)]),
                S("c", "date", list(range(11))),
                S("d", "bool", [i % 2 == 0 for i in range(11)]),
            ],
        )
    )
    cases.append(series_case("series/str_30", S("s", "str", ["a" * 30])))
    cases.append(series_case("series/str_31", S("s", "str", ["a" * 31, "数" * 31, "x\ty"])))
    cases.append(series_case("series/folded_str", S("s", "str", [str(i) for i in range(12)])))
    cases.append(series_case("series/temporal_far", S("t", "datetime[μs]", [400000000000000000, 1000, 1])))
    cases.append(series_case("series/date_far", S("d", "date", [3000000, -1000000])))
    cases.append(series_case("series/f32_widening", S("x", "f32", [1234.5678, 0.1, 1e-7])))

    # ---- additions: character widths (Hangul, combining, zero-width, ...) ---
    width_samples = [
        ("hangul", "한국어"),
        ("combining", "e\u0301"),
        ("zwsp", "a\u200bb"),
        ("variation_selector", "\u263a\ufe0f"),
        ("fullwidth_yen", "\uffe5"),
        ("halfwidth_katakana", "\uff71\uff72\uff73"),
        ("halfwidth_form", "\uffe8"),
        ("cjk_ext_b", "\U00020000"),
        ("rocket", "\U0001f680"),
        # U+FE0F makes these text symbols two columns wide (a is not one)
        ("vs16_digit", "1\ufe0f"),
        ("vs16_copyright", "\u00a9\ufe0f"),
        ("vs16_arrow", "\u2194\ufe0f"),
        ("vs16_ship", "\U0001f6f3\ufe0f"),
        ("vs16_letter", "a\ufe0f"),
    ]
    for key, text in width_samples:
        cases.append(
            frame_case(
                f"frame/width_{key}",
                [S("s", "str", [text, "ab"]), S("t", "i64", [1, 2])],
            )
        )
    cases.append(
        frame_case(
            "frame/width_mixed",
            [S("s", "str", [text for _, text in width_samples])],
        )
    )
    cases.append(
        series_case("series/width_mixed", S("s", "str", [text for _, text in width_samples]))
    )

    emit("show", cases)
    print(f"polars {pl.__version__}: wrote {len(cases)} cases")


main()
