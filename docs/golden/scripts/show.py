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
# polars' default table width is 100 columns (it shrinks and wraps columns beyond that,
# also when stdout is not a terminal). `Show` does not simulate that, so the golden data is
# generated with the limit set far out of reach; the output is the same as polars' default
# output only for tables that fit in 100 columns (see docs/golden/README.md, "Show").
pl.Config.set_tbl_width_chars(60000)

nan = float("nan")
inf = float("inf")

# Character sequences whose width is not the sum of the per-character widths, and
# scripts/blocks where the first (hand-written) width table disagreed with polars.
# The rules behind them are in docs/golden/scripts/char_width.py.
SEQ_SAMPLES = [
    # ZWJ emoji sequences
    ("zwj_family", "👨‍👩‍👧"),
    ("zwj_family_four", "👨‍👩‍👧‍👦"),
    ("zwj_profession", "👩‍💻"),
    ("zwj_couple_heart", "👩‍❤️‍👨"),
    ("zwj_pride_flag", "🏳️‍🌈"),
    ("zwj_tone_chain", "👩🏽‍🤝‍👨🏻"),
    ("zwj_text_heart", "❤‍🔥"),
    ("zwj_heart_vs16", "❤️‍🔥"),
    ("zwj_after_ascii", "a‍😀"),
    ("zwj_before_ascii", "😀‍a"),
    ("zwj_wide_text", "あ‍い"),
    ("zwj_alone", "‍"),
    ("zwj_twice", "😀‍‍😀"),
    # emoji modifiers
    ("tone_thumb", "👍\U0001f3fd"),
    ("tone_text_base", "☝\U0001f3fb"),
    ("tone_after_ascii", "a\U0001f3fd"),
    ("tone_alone", "\U0001f3fd"),
    # keycaps
    ("keycap_digit", "1️⃣"),
    ("keycap_hash", "#️⃣"),
    ("keycap_no_vs16", "1⃣"),
    ("keycap_on_emoji", "😀⃣"),
    # regional indicators and tags
    ("flag_cn", "\U0001f1e8\U0001f1f3"),
    ("flag_single", "\U0001f1e8"),
    ("flag_three", "\U0001f1e8\U0001f1f3\U0001f1fa"),
    ("flag_two", "\U0001f1e8\U0001f1f3\U0001f1fa\U0001f1f8"),
    ("flag_england", "🏴\U000e0067\U000e0062\U000e0065\U000e006e\U000e0067\U000e007f"),
    # variation selectors
    ("vs15_emoji", "⌚︎"),
    ("vs15_text", "☺︎"),
    ("vs15_thumb", "👍︎"),
    ("vs16_on_wide", "あ️"),
    ("vs16_twice", "☺️️"),
    ("vs16_alone", "️"),
    ("vs1_quote", "‘︁"),
    ("vs1_other", "a︁"),
    ("vs_mongolian", "ᠠ᠋"),
    # Hangul jamo
    ("hangul_lv", "가"),
    ("hangul_lvt", "각"),
    ("hangul_v_alone", "ᅡ"),
    ("hangul_t_alone", "ᆨ"),
    ("hangul_syllable_t", "각"),
    ("hangul_ll", "ᄀᄀ"),
    ("hangul_extended", "ꥠힰퟋ"),
    ("hangul_filler", "ㅤﾠ"),
    # combining marks
    ("comb_on_wide", "あ́"),
    ("comb_on_narrow", "é"),
    ("comb_stack", "ẹ́̂"),
    ("comb_alone", "́"),
    ("comb_enclosing", "a⃝"),
    # Indic scripts
    ("devanagari_conjunct", "क्षि"),
    ("devanagari_vowel_sign", "कि"),
    ("devanagari_virama", "क्"),
    ("bengali", "ক্ষ"),
    ("tamil", "தமிழ்"),
    ("telugu", "తెలుగు"),
    ("malayalam", "മലയാളം"),
    ("sinhala", "සිංහල"),
    ("tibetan", "བོད་ཡིག"),
    ("myanmar", "မြန်မာ"),
    ("khmer", "ខ្មែរ"),
    ("thai", "สวัสดี"),
    ("thai_sara_am", "น้ำ"),
    ("lao", "ລາວ"),
    # Arabic and Hebrew
    ("arabic_diacritics", "مُحَمَّد"),
    ("arabic_lam_alef", "لا"),
    ("arabic_lam_mark_alef", "لَا"),
    ("arabic_lam_madda", "لآ"),
    ("arabic_lam_alone", "ل"),
    ("hebrew_points", "שָׁלוֹם"),
    ("hebrew_alef_zwj_lamed", "א‍ל"),
    ("hebrew_alef_lamed", "אל"),
    # scripts and blocks the old table got wrong
    ("tangut", "\U00017000\U00017001"),
    ("khitan", "\U00018b00\U00018b01"),
    ("nushu", "\U0001b170"),
    ("kana_extended", "\U0001b000\U0001b132"),
    ("symbols_wide", "〈〉⏩☔☰⚊"),
    ("symbols_new_emoji", "\U0001f971\U0001fae0\U0001fa70"),
    ("vertical_forms", "︐︙"),
    ("enclosed_ideographic", "\U0001f201\U0001f250"),
    ("ideographic_description", "⿰⿻"),
    ("khmer_beyyal", "៘"),
    ("three_em_dash", "⸻"),
    ("soft_hyphen", "a­b"),
    ("invisible_format", "a⁠᠎b⁢"),
    ("variation_supplement", "a\U000e0100"),
    ("braille_misc", "⠀⠁"),
    # sequence rules that had no case before (U+05D0 / U+17D2 / U+0644 chains, VS15 + ZWJ)
    ("hebrew_alef_zwj_a_lamed", "א‍aל"),
    ("vs_pair_at_start", "\ufe01\ufe0e"),
    ("khmer_coeng_zwj_letter", "A\u17d2\u200d\u1786"),
    ("khmer_coeng_fe0f_letter", "A\u17d2\ufe0f\u1786"),
    ("khmer_coeng_fe0e_letter", "A\u17d2\ufe0e\u1786"),
    ("arabic_lam_zwj_alef", "A\u0644\u200d\u0627"),
    ("vs15_emoji_zwj_emoji", "\u231a\ufe0e\u200d\U0001f600"),
    ("arabic_lam_vs_pair_alef", "\u0644\ufe01\ufe0e\u0627"),
    ("arabic_lam_vs_pair_alef_rev", "\u0644\ufe0e\ufe01\u0627"),
    ("arabic_lam_other_letter", "AA\u0644A"),
    ("arabic_allah", "\u0627\u0644\u0644\u0647"),
    ("arabic_lam_meem", "\u0644\u0645"),
    # edges of the character classes the rules use
    ("ri_first_last", "\U0001f1e6\U0001f1ff"),
    ("tone_last", "\U0001f44d\U0001f3ff"),
    ("vs1_rsquo", "\u2019\ufe01"),
    ("vs1_ldquo", "\u201c\ufe01"),
    ("vs1_rdquo", "\u201d\ufe01"),
    ("just_after_blocks", "\ud7a4\u3097\u30fb\u4dc0"),
    # emoji tag sequences joined by a ZWJ: U+1F3F4, 3 to 6 tag digits/letters, U+E007F
    ("tags_zwj_emoji", "\U0001f3f4\U000e0067\U000e0062\U000e0073\U000e0063\U000e0074\U000e007f\u200d\U0001f600"),
    ("tags_zwj_flag", "\U0001f3f4\U000e0067\U000e0062\U000e0073\U000e007f\u200d\U0001f1e8\U0001f1f3"),
    ("tags_zwj_tone", "\U0001f3f4\U000e0067\U000e0062\U000e0073\U000e007f\u200d\U0001f44d\U0001f3fd"),
    ("tags_zwj_vs16", "\U0001f3f4\U000e0067\U000e0062\U000e0073\U000e007f\u200d\u263a\ufe0f"),
    ("tags_zwj_keycap", "\U0001f3f4\U000e0067\U000e0062\U000e0073\U000e007f\u200d1\ufe0f\u20e3"),
    ("tags_zwj_tags", "\U0001f3f4\U000e0067\U000e0062\U000e0073\U000e007f\u200d\U0001f3f4\U000e0067\U000e0062\U000e0073\U000e007f"),
    ("tags_zwj_ascii", "\U0001f3f4\U000e0067\U000e0062\U000e0073\U000e007f\u200da"),
    ("tags_digits", "\U0001f3f4\U000e0031\U000e0032\U000e0033\U000e007f\u200d\U0001f600"),
    ("tags_two", "\U0001f3f4\U000e0067\U000e0062\U000e007f\u200d\U0001f600"),
    ("tags_six", "\U0001f3f4" + "\U000e0061" * 6 + "\U000e007f\u200d\U0001f600"),
    ("tags_seven", "\U0001f3f4" + "\U000e0061" * 7 + "\U000e007f\u200d\U0001f600"),
    ("tags_other_base", "\U0001f3f3\U000e0067\U000e0062\U000e0073\U000e007f\u200d\U0001f600"),
    ("tags_not_letter", "\U0001f3f4\U000e0020\U000e0021\U000e0022\U000e007f\u200d\U0001f600"),
    ("tags_no_end", "\U0001f3f4\U000e0067\U000e0062\U000e0073\u200d\U0001f600"),
    # a run of variation selectors with U+FE01 and U+FE0E between COENG / alef and the letter
    ("khmer_coeng_vs_pair", "\u17d2\ufe0e\ufe01\u1781"),
    ("khmer_coeng_vs_pair_rev", "\u17d2\ufe01\ufe0e\u1781"),
    ("khmer_coeng_vs_pair_after_mark", "\u17d2\u034f\ufe01\ufe0e\u1781"),
    ("khmer_coeng_vs_fe0f_pair", "\u17d2\ufe01\ufe0f\ufe0e\u1781"),
    ("hebrew_vs_pair", "\u05d0\ufe0e\ufe01\u200d\u05dc"),
    # neighbours of the regional indicators and of the skin-tone modifiers
    ("zwj_ri_pair_edges", "\U0001f600\u200d\U0001f1e6\U0001f1ff"),
    ("zwj_before_ri_pair", "\U0001f600\u200d\U0001f1e5\U0001f1e6"),
    ("zwj_ri_then_after", "\U0001f600\u200d\U0001f1e6\U0001f200"),
    ("zwj_ri_last_then_after", "\U0001f600\u200d\U0001f1ff\U0001f200"),
    ("zwj_after_then_ri", "\U0001f600\u200d\U0001f200\U0001f1e6"),
    ("zwj_before_then_ri", "\U0001f600\u200d\U0001f1e5\U0001f1e5"),
    ("ri_pair_before", "\U0001f1e5\U0001f1e6"),
    ("ri_pair_after", "\U0001f1ff\U0001f200"),
    ("ri_pair_last_first", "\U0001f1ff\U0001f1e6"),
    ("tone_before", "\U0001f44d\U0001f3fa"),
    ("tone_first", "\U0001f44d\U0001f3fb"),
    ("tone_after", "\U0001f44d\U0001f400"),
    ("zwj_tone_before", "\U0001f600\u200d\U0001f44d\U0001f3fa"),
    ("zwj_tone_first", "\U0001f600\u200d\U0001f44d\U0001f3fb"),
    ("zwj_tone_last", "\U0001f600\u200d\U0001f44d\U0001f3ff"),
    ("zwj_tone_after", "\U0001f600\u200d\U0001f44d\U0001f400"),
    ("tone_alone_before", "a\U0001f3fa"),
    ("tone_alone_after", "a\U0001f400"),
    ("tone_alone_first", "a\U0001f3fb"),
    # the lam ligature and runs of variation selectors with U+FE0F between
    ("arabic_lam_fe01_fe0f_fe0e_alef", "\u0644\ufe01\ufe0f\ufe0e\u0627"),
    ("arabic_lam_fe0e_fe0f_fe01_alef", "\u0644\ufe0e\ufe0f\ufe01\u0627"),
    ("arabic_lam_fe0f_alef", "\u0644\ufe0f\u0627"),
    ("arabic_lam_fe0f_fe0f_alef", "\u0644\ufe0f\ufe0f\u0627"),
    # tag runs: 3 to 6 letters, or exactly 3 digits and up to 4 letters, are an emoji tag sequence
    ("tags_ll_d", "\U0001f3f4\U000e0067\U000e0062\U000e0030" + "\U000e007f\u200d\U0001f600"),
    ("tags_dddd", "\U0001f3f4" + "\U000e0030" * 4 + "\U000e007f\u200d\U0001f600"),
    ("tags_ddddd", "\U0001f3f4" + "\U000e0030" * 5 + "\U000e007f\u200d\U0001f600"),
    ("tags_ddd", "\U0001f3f4" + "\U000e0030" * 3 + "\U000e007f\u200d\U0001f600"),
    ("tags_ddd_l", "\U0001f3f4" + "\U000e0030" * 3 + "\U000e0061" + "\U000e007f\u200d\U0001f600"),
    ("tags_ddd_llll", "\U0001f3f4" + "\U000e0030" * 3 + "\U000e0061" * 4 + "\U000e007f\u200d\U0001f600"),
    ("tags_ddd_lllll", "\U0001f3f4" + "\U000e0030" * 3 + "\U000e0061" * 5 + "\U000e007f\u200d\U0001f600"),
    ("tags_dd_lll", "\U0001f3f4" + "\U000e0030" * 2 + "\U000e0061" * 3 + "\U000e007f\u200d\U0001f600"),
    ("tags_l_ddd", "\U0001f3f4\U000e0061" + "\U000e0030" * 3 + "\U000e007f\u200d\U0001f600"),
    ("tags_lll_d", "\U0001f3f4" + "\U000e0061" * 3 + "\U000e0030" + "\U000e007f\u200d\U0001f600"),
    ("tags_edge_3a", "\U0001f3f4\U000e0067\U000e0062\U000e003a" + "\U000e007f\u200d\U0001f600"),
    ("tags_edge_60", "\U0001f3f4\U000e0067\U000e0062\U000e0060" + "\U000e007f\u200d\U0001f600"),
    ("tags_edge_7b", "\U0001f3f4\U000e0067\U000e0062\U000e007b" + "\U000e007f\u200d\U0001f600"),
    ("tags_edge_2f", "\U0001f3f4\U000e0067\U000e0062\U000e002f" + "\U000e007f\u200d\U0001f600"),
    ("tags_edge_3a_run", "\U0001f3f4" + "\U000e003a" * 3 + "\U000e007f\u200d\U0001f600"),
    ("tags_edge_3a_first", "\U0001f3f4\U000e003a\U000e0030\U000e0030\U000e007f\u200d\U0001f600"),
    ("tags_edge_39", "\U0001f3f4" + "\U000e0039" * 3 + "\U000e007f\u200d\U0001f600"),
    ("tags_edge_7a", "\U0001f3f4" + "\U000e007a" * 3 + "\U000e007f\u200d\U0001f600"),
    # COENG state left over from an earlier chain
    ("khmer_coeng_stale_vs", "\u17d2\ufe0e\u17d2\ufe00\ufe01\ufe0e\u1781"),
]


def S(name, dtype, values):
    return series_from_spec(name, dtype, values)


def frame_case(case_id, series):
    df = pl.DataFrame(series) if series else pl.DataFrame()
    return {
        "id": case_id,
        "frame": [encode_series(s) for s in series],
        "expected": str(df),
        "polars": "str(pl.DataFrame(frame))" if series else "str(pl.DataFrame())",
    }


def series_case(case_id, s):
    return {
        "id": case_id,
        "series": encode_series(s),
        "expected": str(s),
        "polars": "str(series)",
    }


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

    # ---- additions: character sequences (see char_width.py for the rules) ------
    for key, text in SEQ_SAMPLES:
        cases.append(
            frame_case(
                f"frame/seq_{key}",
                [S("s", "str", [text, "ab"]), S("t", "i64", [1, 2])],
            )
        )
    texts = [text for _, text in SEQ_SAMPLES]
    # several different widths in one column (9 rows: no row folding)
    for start in range(0, len(texts), 9):
        cases.append(
            frame_case(
                f"frame/seq_mixed_{start // 9}",
                [S("s", "str", texts[start : start + 9])],
            )
        )
    cases.append(series_case("series/seq_mixed", S("s", "str", texts[:10])))
    # long cells: cut at 30 characters, and wrapped at 31 columns
    cases.append(
        frame_case(
            "frame/seq_cut_zwj",
            [S("s", "str", ["👨\u200d👩\u200d👧" * 8, "👍\U0001f3fd" * 20, "e\u0301" * 31, "あ\u0301" * 20])],
        )
    )
    cases.append(
        frame_case(
            "frame/seq_wrap",
            [
                S(
                    "s",
                    "str",
                    ["あ" * 15 + "\u0301" + "い", "あ" * 16 + "\u200d" + "い", "👩\u200d💻" * 6, "ab" * 14 + "👨\u200d👩\u200d👧"],
                )
            ],
        )
    )
    cases.append(
        series_case("series/seq_cut", S("s", "str", ["👨\u200d👩\u200d👧" * 8, "e\u0301" * 31]))
    )

    # ---- additions: word wrapping, clusters and U+17D8 (see grapheme.py) -------------
    def two_cols(case_id, texts, name="s"):
        cases.append(
            frame_case(case_id, [S(name, "str", texts), S("t", "i64", list(range(len(texts))))])
        )

    wrap_samples = [
        # CJK sentences with spaces, wider than 31 columns
        ("korean", "안녕하세요 저는 한국어를 공부하고 있습니다"),
        ("chinese", "东京 大学 的 学生 都 喜欢 吃 日本 料理 和 中国 菜"),
        ("latin_cjk", "Hello 世界 this is a test 你好世界 ok"),
        ("japanese", "私は 毎日 学校へ 行って 友達と 一緒に 勉強します ね"),
        ("chinese_long", "我 爱 北京 天安门 天安门 上 太阳 升 伟大 领袖 毛主席"),
        # runs of spaces: the spaces at a break are dropped
        ("two_spaces", "日" * 10 + "  " + "日" * 5),
        ("three_spaces", "日" * 5 + "   " + "日" * 5 + "   " + "日" * 5 + "   " + "日" * 5),
        ("leading_spaces", "   " + "日" * 16),
        ("trailing_spaces", "日" * 16 + "   "),
        ("spaces_only_gap", "日" * 15 + "     " + "日" * 3),
        ("single_space_gap", "日" * 15 + " " + "日" * 5),
        # a word wider than the column
        ("long_word_first", "日" * 20 + " 日日"),
        ("long_word_second", "ab " + "日" * 20),
        ("long_word_after_cjk", "日" * 5 + " " + "日" * 20),
        ("long_word_exact", "日" * 16 + " " + "日" * 5),
        ("long_word_three_lines", "ab " + "日" * 26),
        ("two_long_words", "日" * 16 + " " + "日" * 12),
        # words that fit exactly, or by one column
        ("fits_exactly", "日" * 14 + " aa " + "日" * 10),
        ("one_short", "日" * 14 + " a " + "日" * 10),
        ("one_over", "日" * 14 + " aaa " + "日" * 10),
        ("ascii_words_cjk", "a b c d e f g h " + "日" * 10 + " 日日日"),
        # not a single column left, even for a zero-wide word
        ("zero_wide_word_fits", "日" * 14 + "a \u0301 日日"),
        ("zero_wide_word_full", "日" * 15 + " \u0301 日日"),
        ("zero_wide_word_full_zwsp", "日" * 15 + " \u200b 日日"),
        # at least 4 free columns are needed to cut a word into the current line
        ("cut_room_three", "៘" * 9 + " a" + "日" * 16),
        ("cut_room_two", "៘" * 9 + "a" + " a" + "日" * 16),
        ("cut_room_two_wide", "日" * 5 + "៘" * 6 + " " + "日" * 18),
        ("cut_room_one", "៘" * 9 + "aa" + " a" + "日" * 12),
        ("cut_room_four", "៘" * 9 + " " + "日" * 18),
        # multi-line cells
        ("newline_wrap", "日" * 10 + " " + "日" * 10 + "\n" + "日 " * 14),
        ("newline_short_long", "ab\n" + "日" * 17),
        # exactly the column width: a line (with a leading space), and a word after a short word
        ("exact_31_line", "日" * 15 + "x"),
        ("exact_31_leading_space", " " + "日" * 15),
        ("exact_31_trailing_space", "日" * 15 + " "),
        ("exact_31_word_after_word", "ab " + "日" * 15 + "x"),
        ("exact_31_word_after_cjk", "日 " + "日" * 15 + "x"),
        ("exact_31_word_first", "日" * 15 + "x ab"),
        ("exact_31_word_empty_cur", " " + "日" * 15 + "x"),
        ("exact_32_word_after_word", "ab " + "日" * 16),
        # a cut cell (more than 30 characters)
        ("cut_wide_words", "日 " * 20),
        ("cut_mixed", "ab日 " * 10),
    ]
    for key, text in wrap_samples:
        two_cols(f"frame/wrap_{key}", [text, "ab"])
    cases.append(
        frame_case(
            "frame/wrap_rows",
            [S("s", "str", [t for _, t in wrap_samples[:5]] + ["ok", None, "x y"])],
        )
    )
    cases.append(
        frame_case(
            "frame/wrap_header",
            [
                S("数据 分析 结果 汇总 表 的 名称 很 长 很 长 很 长", "i64", [1, 2]),
                S("a" * 40, "str", ["日 " * 14, "x"]),
            ],
        )
    )
    cases.append(
        frame_case(
            "frame/wrap_header_cjk",
            [S("数据" * 10, "str", ["x"]), S("é" * 20 + " " + "日" * 10, "i64", [1])],
        )
    )
    cluster_samples = [
        # a cluster that straddles the 31-column wrap moves whole to the next line
        ("flag", "日" * 15 + "\U0001f1e8\U0001f1f3" + "日日"),
        ("flag_two", "日" * 14 + "x\U0001f1e8\U0001f1f3\U0001f1fa\U0001f1f8日"),
        ("keycap", "日" * 15 + "1\ufe0f\u20e3" + "日日"),
        ("vs16", "日" * 15 + "\u263a\ufe0f"),
        ("conjunct_after_x", "日" * 14 + "x" + "क्षि"),
        ("conjunct", "日" * 15 + "क्षि"),
        ("vs1_quote", "日" * 15 + "\u2018\ufe01"),
        ("zwj_family", "日" * 14 + "x\U0001f468\u200d\U0001f469\u200d\U0001f467" + "日日"),
        ("tone", "日" * 15 + "\U0001f44d\U0001f3fd" + "日日"),
        ("myanmar_virama", "日" * 15 + "\u1000\u1039\u1000"),
        ("star_zwj_star", "日" * 15 + "\u2605\u200d\u2605"),
        ("khmer_coeng", "日" * 15 + "\u1780\u17d2\u1781"),
        ("hangul_lvt", "日" * 15 + "\u1100\u1161\u11a8"),
        ("prepend", "日" * 15 + "\u0600\u0627"),
        ("combining_run", "日" * 15 + "e\u0301\u0302\u0303"),
        # lam-alef: two clusters, each measured on its own (1 + 1 columns)
        ("lam_alef", "日" * 14 + "\u0644\u0627" + "日日"),
        ("lam_alef_end", "日" * 14 + "\u0644\u0627"),
        ("lam_alef_two", "日" * 13 + "\u0644\u0627\u0644\u0627" + "日日"),
        # a run of Hangul choseong is one cluster of 32 columns: one code point is taken
        ("jamo_run", "\u1100" * 16),
        ("jamo_run_after_word", "ab " + "\u1100" * 20),
        ("jamo_run_after_cjk", "\u1100" * 20 + " 日"),
        ("jamo_run_in_line", "日" * 10 + " " + "\u1100" * 12),
    ]
    for key, text in cluster_samples:
        two_cols(f"frame/cluster_{key}", [text, "ab"])
    cases.append(
        frame_case(
            "frame/cluster_rows",
            [S("s", "str", [t for _, t in cluster_samples[:9]])],
        )
    )
    khmer_samples = [
        # U+17D8 is three columns wide, but polars bounds a cell at twice its code points
        # (or its UTF-8 length): such a cell wraps in the column it makes
        ("pair", "\u17d8\u17d8"),
        ("emoji", "\U0001f44d\u17d8"),
        ("wide", "日\u17d8"),
        ("two_wide", "日日\u17d8"),
        ("in_ascii", "a\u17d8b"),
        ("ascii_before", "ab\u17d8"),
        ("ascii_after", "\u17d8a"),
        ("single", "\u17d8"),
        ("ten", "\u17d8" * 10),
        ("eleven", "\u17d8" * 11),
        ("twelve", "\u17d8" * 12),
        ("thirty", "\u17d8" * 30),
        ("thirty_one", "\u17d8" * 30 + "x"),
        ("sandwich", "\u17d8a\u17d8"),
        ("word_wrap", "\u17d8" * 4 + " " + "\u17d8" * 4),
        ("ascii_prefix", "a" + "\u17d8" * 11),
        ("ascii_prefix_words", "ab " + "\u17d8" * 11),
        ("mark_between", "\u17d8\u0301\u17d8"),
    ]
    for key, text in khmer_samples:
        two_cols(f"frame/khmer_{key}", [text, "ab"])
    # the bound is a property of the column: other cells change where a cell wraps
    for key, cells in [
        ("with_mixed", ["a日a", "\u17d8\u17d8"]),
        ("with_cjk_ascii", ["日日a", "\u17d8\u17d8"]),
        ("with_ascii", ["aaaa", "\u17d8\u17d8"]),
        ("with_ascii_5", ["aaaaa", "\u17d8\u17d8"]),
        ("with_wide_ascii", ["日aaa", "\u17d8\u17d8"]),
        ("with_cjk", ["日日", "\u17d8\u17d8"]),
        ("three_cells", ["a日 \u17d8a", "\u17d8\u17d8 \u17d8", "日日a"]),
        ("with_header_5", ["\u17d8\u17d8"]),
    ]:
        name = "xxxxx" if key == "with_header_5" else "s"
        two_cols(f"frame/khmer_col_{key}", cells, name)
    cases.append(
        frame_case(
            "frame/khmer_header",
            [S("\u17d8\u17d8", "i64", [1, 2]), S("\u17d8" * 6, "str", ["x", "y"])],
        )
    )
    cases.append(
        frame_case(
            "frame/khmer_dtype",
            [S("d", "datetime[μs]", [0]), S("s", "str", ["\u17d8\u17d8\u17d8"])],
        )
    )

    emit("show", cases)
    print(f"polars {pl.__version__}: wrote {len(cases)} cases")


main()
