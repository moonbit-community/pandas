// White-box tests of the display width rules (`char_width.mbt`). The expected
// widths are polars 2.1.0's own (measured with docs/golden/scripts/char_width.py);
// `show_golden_test.mbt` checks the same sequences inside whole tables.

///|
/// Sequences and the width polars gives them.
let char_width_sequence_cases : Array[(String, String, Int32)] = [
  ("zwj_family", "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}", 2),
  (
    "zwj_family_four", "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}",
    2,
  ),
  ("zwj_profession", "\u{1F469}\u{200D}\u{1F4BB}", 2),
  ("zwj_couple_heart", "\u{1F469}\u{200D}\u{2764}\u{FE0F}\u{200D}\u{1F468}", 2),
  ("zwj_pride_flag", "\u{1F3F3}\u{FE0F}\u{200D}\u{1F308}", 2),
  (
    "zwj_tone_chain", "\u{1F469}\u{1F3FD}\u{200D}\u{1F91D}\u{200D}\u{1F468}\u{1F3FB}",
    2,
  ),
  ("zwj_text_heart", "\u{2764}\u{200D}\u{1F525}", 3),
  ("zwj_heart_vs16", "\u{2764}\u{FE0F}\u{200D}\u{1F525}", 2),
  ("zwj_after_ascii", "a\u{200D}\u{1F600}", 3),
  ("zwj_before_ascii", "\u{1F600}\u{200D}a", 3),
  ("zwj_wide_text", "\u{3042}\u{200D}\u{3044}", 4),
  ("zwj_alone", "\u{200D}", 0),
  ("zwj_twice", "\u{1F600}\u{200D}\u{200D}\u{1F600}", 4),
  ("tone_thumb", "\u{1F44D}\u{1F3FD}", 2),
  ("tone_text_base", "\u{261D}\u{1F3FB}", 2),
  ("tone_after_ascii", "a\u{1F3FD}", 3),
  ("tone_alone", "\u{1F3FD}", 2),
  ("keycap_digit", "1\u{FE0F}\u{20E3}", 2),
  ("keycap_hash", "#\u{FE0F}\u{20E3}", 2),
  ("keycap_no_vs16", "1\u{20E3}", 1),
  ("keycap_on_emoji", "\u{1F600}\u{20E3}", 2),
  ("flag_cn", "\u{1F1E8}\u{1F1F3}", 2),
  ("flag_single", "\u{1F1E8}", 1),
  ("flag_three", "\u{1F1E8}\u{1F1F3}\u{1F1FA}", 3),
  ("flag_two", "\u{1F1E8}\u{1F1F3}\u{1F1FA}\u{1F1F8}", 4),
  (
    "flag_england", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}",
    2,
  ),
  ("vs15_emoji", "\u{231A}\u{FE0E}", 1),
  ("vs15_text", "\u{263A}\u{FE0E}", 1),
  ("vs15_thumb", "\u{1F44D}\u{FE0E}", 1),
  ("vs16_on_wide", "\u{3042}\u{FE0F}", 2),
  ("vs16_twice", "\u{263A}\u{FE0F}\u{FE0F}", 2),
  ("vs16_alone", "\u{FE0F}", 0),
  ("vs1_quote", "\u{2018}\u{FE01}", 2),
  ("vs1_other", "a\u{FE01}", 1),
  ("vs_mongolian", "\u{1820}\u{180B}", 1),
  ("hangul_lv", "\u{1100}\u{1161}", 2),
  ("hangul_lvt", "\u{1100}\u{1161}\u{11A8}", 2),
  ("hangul_v_alone", "\u{1161}", 0),
  ("hangul_t_alone", "\u{11A8}", 0),
  ("hangul_syllable_t", "\u{AC00}\u{11A8}", 2),
  ("hangul_ll", "\u{1100}\u{1100}", 4),
  ("hangul_extended", "\u{A960}\u{D7B0}\u{D7CB}", 2),
  ("hangul_filler", "\u{3164}\u{FFA0}", 0),
  ("comb_on_wide", "\u{3042}\u{301}", 2),
  ("comb_on_narrow", "e\u{301}", 1),
  ("comb_stack", "e\u{301}\u{302}\u{323}", 1),
  ("comb_alone", "\u{301}", 0),
  ("comb_enclosing", "a\u{20DD}", 1),
  ("devanagari_conjunct", "\u{915}\u{94D}\u{937}\u{93F}", 3),
  ("devanagari_vowel_sign", "\u{915}\u{93F}", 2),
  ("devanagari_virama", "\u{915}\u{94D}", 1),
  ("bengali", "\u{995}\u{9CD}\u{9B7}", 2),
  ("tamil", "\u{BA4}\u{BAE}\u{BBF}\u{BB4}\u{BCD}", 4),
  ("telugu", "\u{C24}\u{C46}\u{C32}\u{C41}\u{C17}\u{C41}", 5),
  ("malayalam", "\u{D2E}\u{D32}\u{D2F}\u{D3E}\u{D33}\u{D02}", 5),
  ("sinhala", "\u{DC3}\u{DD2}\u{D82}\u{DC4}\u{DBD}", 4),
  ("tibetan", "\u{F56}\u{F7C}\u{F51}\u{F0B}\u{F61}\u{F72}\u{F42}", 5),
  ("myanmar", "\u{1019}\u{103C}\u{1014}\u{103A}\u{1019}\u{102C}", 5),
  ("khmer", "\u{1781}\u{17D2}\u{1798}\u{17C2}\u{179A}", 3),
  ("thai", "\u{E2A}\u{E27}\u{E31}\u{E2A}\u{E14}\u{E35}", 4),
  ("thai_sara_am", "\u{E19}\u{E49}\u{E33}", 2),
  ("lao", "\u{EA5}\u{EB2}\u{EA7}", 3),
  (
    "arabic_diacritics", "\u{645}\u{64F}\u{62D}\u{64E}\u{645}\u{64E}\u{651}\u{62F}",
    4,
  ),
  ("arabic_lam_alef", "\u{644}\u{627}", 1),
  ("arabic_lam_mark_alef", "\u{644}\u{64E}\u{627}", 1),
  ("arabic_lam_madda", "\u{644}\u{622}", 1),
  ("arabic_lam_alone", "\u{644}", 1),
  ("hebrew_points", "\u{5E9}\u{5B8}\u{5C1}\u{5DC}\u{5D5}\u{5B9}\u{5DD}", 4),
  ("hebrew_alef_zwj_lamed", "\u{5D0}\u{200D}\u{5DC}", 1),
  ("hebrew_alef_lamed", "\u{5D0}\u{5DC}", 2),
  ("tangut", "\u{17000}\u{17001}", 4),
  ("khitan", "\u{18B00}\u{18B01}", 4),
  ("nushu", "\u{1B170}", 2),
  ("kana_extended", "\u{1B000}\u{1B132}", 4),
  ("symbols_wide", "\u{2329}\u{232A}\u{23E9}\u{2614}\u{2630}\u{268A}", 12),
  ("symbols_new_emoji", "\u{1F971}\u{1FAE0}\u{1FA70}", 6),
  ("vertical_forms", "\u{FE10}\u{FE19}", 4),
  ("enclosed_ideographic", "\u{1F201}\u{1F250}", 4),
  ("ideographic_description", "\u{2FF0}\u{2FFB}", 4),
  ("khmer_beyyal", "\u{17D8}", 3),
  ("three_em_dash", "\u{2E3B}", 1),
  ("soft_hyphen", "a\u{AD}b", 2),
  ("invisible_format", "a\u{2060}\u{180E}b\u{2062}", 2),
  ("variation_supplement", "a\u{E0100}", 1),
  ("braille_misc", "\u{2800}\u{2801}", 2),
  ("empty", "", 0),
  ("ascii", "hello", 5),
  ("hard_cases_flag_pair_after_zwj", "\u{1F600}\u{200D}\u{1F1E8}\u{1F1F3}", 2),
  ("flag_pair_then_zwj", "\u{1F1E8}\u{1F1F3}\u{200D}\u{1F600}", 2),
  ("flag_three_then_zwj", "\u{1F1E8}\u{1F1F3}\u{1F1FA}\u{200D}\u{1F600}", 5),
  ("zwj_vs16_after_emoji", "\u{1F44D}\u{200D}\u{270C}\u{FE0F}", 2),
  ("emb_text_after_zwj", "\u{1F3F4}\u{200D}\u{261D}\u{1F3FB}", 2),
  ("vs15_after_zwj", "\u{1F44D}\u{200D}\u{1F550}\u{FE0E}", 3),
  ("keycap_zwj", "1\u{FE0F}\u{20E3}\u{200D}\u{1F600}", 2),
  ("emoji_vs16_zwj_emoji", "\u{1F44D}\u{FE0F}\u{200D}\u{1F46A}", 2),
  ("arabic_chain_lam", "\u{644}\u{644}\u{627}", 2),
  ("arabic_lam_two_marks", "\u{644}\u{64E}\u{64F}\u{627}", 1),
  ("hebrew_alef_vs_zwj_lamed", "\u{5D0}\u{FE0F}\u{200D}\u{5DC}", 1),
  ("leak_alef", "\u{26F5}\u{FE01}\u{FE0E}\u{627}", 2),
  ("leak_khmer", "\u{2018}\u{FE01}\u{FE0E}\u{FE0F}\u{1786}", 2),
  ("leak_lamed", "\u{231A}\u{FE01}\u{FE0E}\u{5DC}", 2),
  ("leak_ascii", "a\u{FE01}\u{FE0E}\u{627}", 2),
  ("leak_other", "\u{26F5}\u{FE01}\u{FE0E}\u{628}", 3),
  ("vs16w_zwj", "\u{1F22F}\u{FE0F}\u{200D}\u{1F600}", 2),
  ("vs16_plain_ep_zwj", "\u{1F600}\u{FE0F}\u{200D}\u{1F600}", 4),
  ("hebrew_two_zwj", "\u{5D0}\u{200D}\u{200D}\u{5DC}", 1),
  ("hebrew_alef_x_zwj_lamed", "\u{5D0}a\u{200D}\u{5DC}", 3),
  // one case for each trigger of a sequence rule, and the edges of the classes they use
  ("hebrew_alef_zwj_a_lamed", "\u{5D0}\u{200D}a\u{5DC}", 3),
  ("vs_pair_at_start", "\u{FE01}\u{FE0E}", 0),
  ("khmer_coeng_zwj_letter", "A\u{17D2}\u{200D}\u{1786}", 1),
  ("khmer_coeng_fe0f_letter", "A\u{17D2}\u{FE0F}\u{1786}", 1),
  ("khmer_coeng_fe0e_letter", "A\u{17D2}\u{FE0E}\u{1786}", 1),
  ("arabic_lam_zwj_alef", "A\u{644}\u{200D}\u{627}", 3),
  ("vs15_emoji_zwj_emoji", "\u{231A}\u{FE0E}\u{200D}\u{1F600}", 3),
  ("arabic_lam_vs_pair_alef", "\u{644}\u{FE01}\u{FE0E}\u{627}", 2),
  ("arabic_lam_vs_pair_alef_rev", "\u{644}\u{FE0E}\u{FE01}\u{627}", 2),
  ("arabic_lam_other_letter", "AA\u{644}A", 4),
  ("arabic_allah", "\u{627}\u{644}\u{644}\u{647}", 4),
  ("arabic_lam_meem", "\u{644}\u{645}", 2),
  ("ri_first_last", "\u{1F1E6}\u{1F1FF}", 2),
  ("tone_last", "\u{1F44D}\u{1F3FF}", 2),
  ("vs1_rsquo", "\u{2019}\u{FE01}", 2),
  ("vs1_ldquo", "\u{201C}\u{FE01}", 2),
  ("vs1_rdquo", "\u{201D}\u{FE01}", 2),
  ("just_after_blocks", "\u{D7A4}\u{3097}\u{30FB}\u{4DC0}", 6),
  (
    "tags_zwj_emoji", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E0063}\u{E0074}\u{E007F}\u{200D}\u{1F600}",
    2,
  ),
  (
    "tags_zwj_flag", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E007F}\u{200D}\u{1F1E8}\u{1F1F3}",
    2,
  ),
  (
    "tags_zwj_tone", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E007F}\u{200D}\u{1F44D}\u{1F3FD}",
    2,
  ),
  (
    "tags_zwj_vs16", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E007F}\u{200D}\u{263A}\u{FE0F}",
    2,
  ),
  (
    "tags_zwj_keycap", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E007F}\u{200D}1\u{FE0F}\u{20E3}",
    2,
  ),
  (
    "tags_zwj_tags", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E007F}\u{200D}\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E007F}",
    2,
  ),
  (
    "tags_zwj_ascii", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E007F}\u{200D}a", 3,
  ),
  (
    "tags_digits", "\u{1F3F4}\u{E0031}\u{E0032}\u{E0033}\u{E007F}\u{200D}\u{1F600}",
    2,
  ),
  ("tags_two", "\u{1F3F4}\u{E0067}\u{E0062}\u{E007F}\u{200D}\u{1F600}", 4),
  (
    "tags_six", "\u{1F3F4}\u{E0061}\u{E0061}\u{E0061}\u{E0061}\u{E0061}\u{E0061}\u{E007F}\u{200D}\u{1F600}",
    2,
  ),
  (
    "tags_seven", "\u{1F3F4}\u{E0061}\u{E0061}\u{E0061}\u{E0061}\u{E0061}\u{E0061}\u{E0061}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_other_base", "\u{1F3F3}\u{E0067}\u{E0062}\u{E0073}\u{E007F}\u{200D}\u{1F600}",
    3,
  ),
  (
    "tags_not_letter", "\u{1F3F4}\u{E0020}\u{E0021}\u{E0022}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  ("tags_no_end", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{200D}\u{1F600}", 4),
  ("khmer_coeng_vs_pair", "\u{17D2}\u{FE0E}\u{FE01}\u{1781}", 1),
  ("khmer_coeng_vs_pair_rev", "\u{17D2}\u{FE01}\u{FE0E}\u{1781}", 1),
  (
    "khmer_coeng_vs_pair_after_mark", "\u{17D2}\u{34F}\u{FE01}\u{FE0E}\u{1781}",
    0,
  ),
  ("khmer_coeng_vs_fe0f_pair", "\u{17D2}\u{FE01}\u{FE0F}\u{FE0E}\u{1781}", 1),
  ("hebrew_vs_pair", "\u{5D0}\u{FE0E}\u{FE01}\u{200D}\u{5DC}", 2),
  ("zwj_ri_pair_edges", "\u{1F600}\u{200D}\u{1F1E6}\u{1F1FF}", 2),
  ("zwj_before_ri_pair", "\u{1F600}\u{200D}\u{1F1E5}\u{1F1E6}", 4),
  ("zwj_ri_then_after", "\u{1F600}\u{200D}\u{1F1E6}\u{1F200}", 5),
  ("zwj_ri_last_then_after", "\u{1F600}\u{200D}\u{1F1FF}\u{1F200}", 5),
  ("zwj_after_then_ri", "\u{1F600}\u{200D}\u{1F200}\u{1F1E6}", 5),
  ("zwj_before_then_ri", "\u{1F600}\u{200D}\u{1F1E5}\u{1F1E5}", 4),
  ("ri_pair_before", "\u{1F1E5}\u{1F1E6}", 2),
  ("ri_pair_after", "\u{1F1FF}\u{1F200}", 3),
  ("ri_pair_last_first", "\u{1F1FF}\u{1F1E6}", 2),
  ("tone_before", "\u{1F44D}\u{1F3FA}", 4),
  ("tone_first", "\u{1F44D}\u{1F3FB}", 2),
  ("tone_after", "\u{1F44D}\u{1F400}", 4),
  ("zwj_tone_before", "\u{1F600}\u{200D}\u{1F44D}\u{1F3FA}", 4),
  ("zwj_tone_first", "\u{1F600}\u{200D}\u{1F44D}\u{1F3FB}", 2),
  ("zwj_tone_last", "\u{1F600}\u{200D}\u{1F44D}\u{1F3FF}", 2),
  ("zwj_tone_after", "\u{1F600}\u{200D}\u{1F44D}\u{1F400}", 4),
  ("tone_alone_before", "a\u{1F3FA}", 3),
  ("tone_alone_after", "a\u{1F400}", 3),
  ("tone_alone_first", "a\u{1F3FB}", 3),
  (
    "arabic_lam_fe01_fe0f_fe0e_alef", "\u{644}\u{FE01}\u{FE0F}\u{FE0E}\u{627}", 2,
  ),
  (
    "arabic_lam_fe0e_fe0f_fe01_alef", "\u{644}\u{FE0E}\u{FE0F}\u{FE01}\u{627}", 2,
  ),
  ("arabic_lam_fe0f_alef", "\u{644}\u{FE0F}\u{627}", 1),
  ("arabic_lam_fe0f_fe0f_alef", "\u{644}\u{FE0F}\u{FE0F}\u{627}", 1),
  (
    "tags_ll_d", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0030}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_dddd", "\u{1F3F4}\u{E0030}\u{E0030}\u{E0030}\u{E0030}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_ddddd", "\u{1F3F4}\u{E0030}\u{E0030}\u{E0030}\u{E0030}\u{E0030}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_ddd", "\u{1F3F4}\u{E0030}\u{E0030}\u{E0030}\u{E007F}\u{200D}\u{1F600}",
    2,
  ),
  (
    "tags_ddd_l", "\u{1F3F4}\u{E0030}\u{E0030}\u{E0030}\u{E0061}\u{E007F}\u{200D}\u{1F600}",
    2,
  ),
  (
    "tags_ddd_llll", "\u{1F3F4}\u{E0030}\u{E0030}\u{E0030}\u{E0061}\u{E0061}\u{E0061}\u{E0061}\u{E007F}\u{200D}\u{1F600}",
    2,
  ),
  (
    "tags_ddd_lllll", "\u{1F3F4}\u{E0030}\u{E0030}\u{E0030}\u{E0061}\u{E0061}\u{E0061}\u{E0061}\u{E0061}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_dd_lll", "\u{1F3F4}\u{E0030}\u{E0030}\u{E0061}\u{E0061}\u{E0061}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_l_ddd", "\u{1F3F4}\u{E0061}\u{E0030}\u{E0030}\u{E0030}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_lll_d", "\u{1F3F4}\u{E0061}\u{E0061}\u{E0061}\u{E0030}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_edge_3a", "\u{1F3F4}\u{E0067}\u{E0062}\u{E003A}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_edge_60", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0060}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_edge_7b", "\u{1F3F4}\u{E0067}\u{E0062}\u{E007B}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_edge_2f", "\u{1F3F4}\u{E0067}\u{E0062}\u{E002F}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_edge_3a_run", "\u{1F3F4}\u{E003A}\u{E003A}\u{E003A}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_edge_3a_first", "\u{1F3F4}\u{E003A}\u{E0030}\u{E0030}\u{E007F}\u{200D}\u{1F600}",
    4,
  ),
  (
    "tags_edge_39", "\u{1F3F4}\u{E0039}\u{E0039}\u{E0039}\u{E007F}\u{200D}\u{1F600}",
    2,
  ),
  (
    "tags_edge_7a", "\u{1F3F4}\u{E007A}\u{E007A}\u{E007A}\u{E007F}\u{200D}\u{1F600}",
    2,
  ),
  (
    "khmer_coeng_stale_vs", "\u{17D2}\u{FE0E}\u{17D2}\u{FE00}\u{FE01}\u{FE0E}\u{1781}",
    0,
  ),
]

///|
test "str_width matches polars for character sequences" {
  for case in char_width_sequence_cases {
    let (name, text, expected) = case
    let actual = str_width(text)
    if actual != expected {
      fail("\{name}: expected \{expected}, got \{actual}")
    }
  }
}

///|
test "cp_width: single code points" {
  // one column: ASCII, control characters, Latin, Greek, Cyrillic
  assert_eq(cp_width(0x41), 1)
  assert_eq(cp_width(0x00), 1)
  assert_eq(cp_width(0x7f), 1)
  assert_eq(cp_width(0x3b1), 1)
  // zero wide: soft hyphen, combining marks, ZWSP, ZWJ, variation selectors,
  // Devanagari virama, Hangul vowels, tags
  assert_eq(cp_width(0xad), 0)
  assert_eq(cp_width(0x301), 0)
  assert_eq(cp_width(0x200b), 0)
  assert_eq(cp_width(0x200d), 0)
  assert_eq(cp_width(0xfe0f), 0)
  assert_eq(cp_width(0x94d), 0)
  assert_eq(cp_width(0x1161), 0)
  assert_eq(cp_width(0xe0067), 0)
  // two wide: CJK, kana, Hangul syllables, fullwidth forms, emoji, Tangut, Khitan
  assert_eq(cp_width(0x4e2d), 2)
  assert_eq(cp_width(0x3042), 2)
  assert_eq(cp_width(0xac00), 2)
  assert_eq(cp_width(0xff21), 2)
  assert_eq(cp_width(0x1f600), 2)
  assert_eq(cp_width(0x17000), 2)
  assert_eq(cp_width(0x18b00), 2)
  // the one three-column character: Khmer sign beyyal
  assert_eq(cp_width(0x17d8), 3)
  // one column again just past the ends of wide blocks
  assert_eq(cp_width(0x20000), 2)
  assert_eq(cp_width(0x3fffd), 2)
  assert_eq(cp_width(0x3fffe), 1)
  assert_eq(cp_width(0x10ffff), 1)
}

///|
test "str_width: empty, ASCII and plain text" {
  assert_eq(str_width(""), 0)
  assert_eq(str_width("hello, world"), 12)
  assert_eq(str_width("héllo"), 5)
  assert_eq(str_width("数据"), 4)
  assert_eq(str_width("a数b"), 4)
}

///|
test "code_points_width measures a prefix" {
  // 👨 ZWJ 👩 ZWJ 👧: each prefix ending right after an emoji is two wide
  let cs : Array[Int32] = [0x1f468, 0x200d, 0x1f469, 0x200d, 0x1f467]
  assert_eq(code_points_width(cs, 0), 0)
  assert_eq(code_points_width(cs, 1), 2)
  assert_eq(code_points_width(cs, 2), 2)
  assert_eq(code_points_width(cs, 3), 2)
  assert_eq(code_points_width(cs, 5), 2)
  // a prefix of a keycap: digit, then U+FE0F makes it two wide
  let k : Array[Int32] = [0x31, 0xfe0f, 0x20e3]
  assert_eq(code_points_width(k, 1), 1)
  assert_eq(code_points_width(k, 2), 2)
  assert_eq(code_points_width(k, 3), 2)
}

///|
test "in_char_set: binary search edges" {
  assert_eq(in_char_set(char_set_vs16, 0x23), true)
  assert_eq(in_char_set(char_set_vs16, 0x22), false)
  assert_eq(in_char_set(char_set_vs16, 0x30), true)
  assert_eq(in_char_set(char_set_vs16, 0x39), true)
  assert_eq(in_char_set(char_set_vs16, 0x3a), false)
  assert_eq(in_char_set(char_set_vs16, -1), false)
  assert_eq(in_char_set(char_set_vs16, 0x10ffff), false)
  assert_eq(in_char_set(char_set_ejoin, 0x1f600), true)
  assert_eq(in_char_set(char_set_ejoin, 0x2764), false)
}

///|
test "cp_width: the two-column shortcut blocks agree with the measured table" {
  fn table_width(u : Int32) -> Int32 {
    let mut i = 0
    while i < char_width_ranges.length() {
      if u >= char_width_ranges[i] && u <= char_width_ranges[i + 1] {
        return char_width_ranges[i + 2]
      }
      i += 3
    }
    1
  }

  for
    block in [
      (0x4e00, 0x9fff),
      (0xac00, 0xd7a3),
      (0x3041, 0x3096),
      (0x30a1, 0x30fa),
      (0x3400, 0x4dbf),
    ] {
    let (a, b) = block
    for u in a..<=b {
      if table_width(u) != 2 || cp_width(u) != 2 {
        fail("U+\{u.to_string(radix=16)} is not two columns wide in the table")
      }
    }
  }
}

///|
test "cp_width and str_width agree with polars around every edge of the width table" {
  // `char_width_edges` (generated, polars' own measurements): code point, width
  let mut i = 0
  while i < char_width_edges.length() {
    let u = char_width_edges[i]
    let w = char_width_edges[i + 1]
    if cp_width(u) != w {
      fail("cp_width(U+\{u.to_string(radix=16)}) = \{cp_width(u)}, polars \{w}")
    }
    if str_width(u.unsafe_to_char().to_string()) != w {
      fail("str_width(U+\{u.to_string(radix=16)}) differs from polars \{w}")
    }
    i += 2
  }
  // the table is not small: every range contributes its edges
  assert_true(char_width_edges.length() > 3000)
}
