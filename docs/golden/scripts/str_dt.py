"""Generates the `str` and `dt` kernel golden data
(docs/golden/str_dt.json, src/pl/golden_str_dt_data_wbtest.mbt).

Run from the repository root:
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/str_dt.py

The file is `{"inputs": {key: series}, "cases": [...]}` (compact layout, see
`emit(compact=True)`); `a` of a case is a key of `inputs`. Every case has `id`,
`op` (`contains`, `starts_with`, `ends_with`, `lower`, `upper`, `len_chars`,
`len_bytes`, `replace`, `strip`, `dt`), `a`, the arguments the operation takes
(`pattern`, `literal`, `prefix`, `suffix`, `value`, `all`, `chars`, `side`,
`field`), `polars` (the Python spelling that produced it) and one of

* `result`: a series, through `to_ours` (Int8/Int16 -> Int32, UInt32 -> Int64);
* `error` + `message`: variant per the M2 error mapping and the message the
  library must produce. polars' first line is kept in `polars_message` when
  the library appends to it (an invalid regex: polars' first line is just
  `regex error: regex parse error:`, the library adds the pattern in quotes,
  spec 5.6).

A case with `skip` is a documented difference (docs/golden/known-diffs/regex.md):
polars' answer is kept as `result`/`error` and the test checks that the library
still differs from it (so that a fix in core is noticed).

The data is the one the polars behaviour was probed with: no polars behaviour
is assumed, every expected value comes from running polars 2.1.0 here.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import polars as pl

from emit import DTYPE_NAMES, emit, encode_series, series_from_spec, to_ours

DTYPES = list(DTYPE_NAMES)

VARIANTS = {
    "ColumnNotFoundError": "ColumnNotFound",
    "DuplicateError": "DuplicateColumn",
    "SchemaError": "SchemaMismatch",
    "ShapeError": "ShapeMismatch",
    "OutOfBoundsError": "OutOfBounds",
    "InvalidOperationError": "InvalidOperation",
    "ComputeError": "ComputeError",
}

# Strings: null, empty, non-ASCII (Chinese, German sharp s, Turkish dotted I,
# Greek final sigma), emoji, the Review Focus 1 set, characters whose case
# mapping is irregular (Kelvin sign, Ohm sign, title-case digraphs,
# `ŉ`, `ǰ`, `ΐ`, ligature `ﬁ`), characters of every UTF-8 length, and a cased
# supplementary-plane letter before a sigma.
STRINGS = [
    "Straße", "İstanbul", "ΑΣ", "ΑΣ Σ", "ΑΣ.", "ǅ", "ŉ", "ﬁ", None, "", "😀", "中文",
    "ÀÉÎõü", "Hello World", " mixed Case 123 ", "｡", "\U0001F600", "a", "Z", "ΣΑΣ",
    "Σ", "ΑΣ́", "A­Σ", "ǈ", "ῼ", "ᾈ", "ǰ", "ΐ", "İ", "I", "ı", "ſ", "K",
    "Ω", "\U00010400Σ", "Σ.Α", "\u0080", "߿", "ࠀ", "￿", "\U0010ffff",
    "tab\there", "line1\nline2", "x y",
]
# Texts for the pattern operations.
TEXTS = [
    "abc", "a.c", "ABC", "aXc", " abc ", "abcabc", "aaa", "aab", "ab12cd345", "x.y.z",
    "héllo wörld", "😀a😀", "Cat dog", "αβγ", "a+b", "(x)", "", None, "bbb", "a1 b22 c333",
    "ß", "İ", "ΑΣ", "cat", "dog", "bird",
]
# Strings for the strip operations.
STRIP_STRINGS = [
    "  hi  ", "\t\n x  　", "​ x ​", "\u0085x ", "xxhixx", "", "  ",
    None, "😀a😀", "﻿x", "᠎x᠎", "\u000bx\u000b", " x  y ",
    "xhix", "é x é", " ",
]
DATES = [
    0, -1, 19782, -25567, 2932896, 2932897, -719528, -719529, -1000000, 10**7, 11016,
    11017, 60, 59, 19783, 365243 * 4, None, 100_000_000, 2147483647, -2147483648, 95026236,
    95026237, -96465292, -96465293, 95_000_000, -96_000_000, 2932895, -719162, -1461, 1461,
]
DATETIMES = [
    0, -1, 1709210096123456, 86399999999, -86400000000, -86400000001, 253402300799999999,
    253402300800000000, 10**17, -10**17, 9223372036854775807, -9223372036854775808,
    9223372036854775807 - 999, None, 1_000_000, 59_999_999, 3_599_999_999, -3_600_000_000,
    -1_000_000_000_000_000_000, 8210266876799999999, 8210266876800000000,
    -8334601228800000000, -8334601228800000001, 951782400000000, -62135596800000000,
    -2209075200000000, -2208988800000000, 1_000_000_000_000,
]
# one value per dtype, used for the "wrong dtype" cases
OTHER = {
    "bool": [True, None, False], "i32": [1, None, -3], "i64": [1, 0, None], "f32": [1.0, None, 2.5],
    "f64": [0.0, -1.5, None], "str": ["a", "b", None], "date": [4, 5, None],
    "datetime[μs]": [4, 5, None], "null": [None, None, None],
}


def error_of(e):
    name = type(e).__name__
    return VARIANTS.get(name, name), str(e).split("\n")[0]


def attempt(f):
    try:
        return f(), None
    except Exception as e:  # noqa: BLE001
        return None, error_of(e)
    except BaseException as e:  # noqa: BLE001
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        return None, error_of(e)


INPUTS = {}


def ref(label, series):
    enc = encode_series(series)
    for key, value in INPUTS.items():
        if {k: v for k, v in value.items() if k != "for"} == enc:
            return key
    key = f"i{len(INPUTS)}"
    INPUTS[key] = dict(enc, **{"for": label})
    return key


def mk(dtype, values, name="a"):
    return series_from_spec(name, dtype, values)


CASES = []
IDS = set()


def add(cid, op, series, args, spelling, run, skip=None, regex_pattern=None):
    assert cid not in IDS, cid
    IDS.add(cid)
    result, err = attempt(run)
    case = {"id": cid, "op": op, "a": ref(cid, series), "polars": spelling}
    case.update(args)
    if skip is not None:
        case["skip"] = skip
    if err is not None:
        case["error"], case["message"] = err
        if err[0] == "ComputeError" and err[1] == "regex error: regex parse error:":
            # the library names the pattern as well (spec 5.6)
            case["polars_message"] = err[1]
            case["message"] = f'{err[1]} "{regex_pattern}"'
    else:
        ours, original = to_ours(result)
        case["result"] = encode_series(ours)
        if ours.dtype != result.dtype:
            case["polars_dtype"] = original
    CASES.append(case)


def lit_py(v):
    return repr(v)


def main():
    main_s = mk("str", STRINGS)
    text_s = mk("str", TEXTS)
    strip_s = mk("str", STRIP_STRINGS)

    # ---- unary string functions on the string and on every other dtype ----
    unary = {
        "lower": ("to_lowercase", "s.str.to_lowercase()"),
        "upper": ("to_uppercase", "s.str.to_uppercase()"),
        "len_chars": ("len_chars", "s.str.len_chars()"),
        "len_bytes": ("len_bytes", "s.str.len_bytes()"),
    }
    for op, (meth, spelling) in unary.items():
        add(f"{op}/str", op, main_s, {}, spelling, lambda: getattr(main_s.str, meth)())
        add(f"{op}/str-empty", op, mk("str", []), {}, spelling, lambda: getattr(mk("str", []).str, meth)())
        add(f"{op}/str-all-null", op, mk("str", [None, None]), {}, spelling,
            lambda: getattr(mk("str", [None, None]).str, meth)())
        for dt in DTYPES:
            if dt == "str":
                continue
            s = mk(dt, OTHER[dt])
            add(f"{op}/{dt}", op, s, {}, spelling, lambda: getattr(s.str, meth)())

    # ---- contains / starts_with / ends_with --------------------------------
    regexes = [
        "a.c", "^abc$", "b", "", "[a-z]+[0-9]", "[^a-z]", "a{2,3}b", "a{2}", "a{2,}", "(ab)+",
        "cat|dog", "(?i:ABC)", "^$", "x*", ".", "é", "😀", "[α-ω]+", "a|", "(?:ab)c", "\\.",
        "\\+", "\\(x\\)", "[[:digit:]]+", "[[:alpha:]][[:digit:]]", "[[:space:]]", "[[:upper:]]",
        "\\bcat\\b", "\\Bat", "^a", "c$", "^.$", "a.?c", "a+?b", "(a)(b)?", "\\u00e9", "[a-c]{3}",
        "^\\.|^a", "b+$", "[é-ü]", "a\\tb", "^(abc){2}$", "[x.]y", "a.*z", "(?:cat|dog) ?",
        "(?<n>a)b", "\\\\", "[.]", "ab|cd|12", "^[^ ]+$", "A|b", "a{0}b", "ΑΣ", "[ΑΣ]+$",
    ]
    for i, pat in enumerate(regexes):
        add(f"contains/regex/{i}", "contains", text_s, {"pattern": pat, "literal": False},
            f"s.str.contains({lit_py(pat)}, literal=False)", lambda: text_s.str.contains(pat, literal=False))
    literals = ["a.c", "", "(x)", "é", "😀", "ab", "a+b", "ΑΣ", "\\.", "A", "a b", " ", "c", "cat"]
    for i, pat in enumerate(literals):
        add(f"contains/literal/{i}", "contains", text_s, {"pattern": pat, "literal": True},
            f"s.str.contains({lit_py(pat)}, literal=True)", lambda: text_s.str.contains(pat, literal=True))
    # the same text, literal vs regex
    one = mk("str", ["abc", "a.c", "aXc", None])
    for lit in (False, True):
        add(f"contains/a.c/literal-{lit}", "contains", one, {"pattern": "a.c", "literal": lit},
            f"s.str.contains('a.c', literal={lit})", lambda: one.str.contains("a.c", literal=lit))
    for dt in DTYPES:
        if dt == "str":
            continue
        s = mk(dt, OTHER[dt])
        for lit in (False, True):
            add(f"contains/{dt}/literal-{lit}", "contains", s, {"pattern": "a", "literal": lit},
                f"s.str.contains('a', literal={lit})", lambda: s.str.contains("a", literal=lit))
    add("contains/empty-series", "contains", mk("str", []), {"pattern": "a", "literal": False},
        "s.str.contains('a')", lambda: mk("str", []).str.contains("a"))
    add("contains/all-null", "contains", mk("str", [None, None]), {"pattern": "", "literal": False},
        "s.str.contains('')", lambda: mk("str", [None, None]).str.contains(""))

    bad_regexes = ["(", "[a", "a{2,1}", "\\", "(()", ")", "a)", "[z-a]", "*", "a|*", "(?<n>a)(?<n>b)"]
    for i, pat in enumerate(bad_regexes):
        add(f"contains/bad-regex/{i}", "contains", one, {"pattern": pat, "literal": False},
            f"s.str.contains({lit_py(pat)})", lambda: one.str.contains(pat), regex_pattern=pat)
        add(f"replace/bad-regex/{i}", "replace", one, {"pattern": pat, "value": "x", "literal": False, "all": False},
            f"s.str.replace({lit_py(pat)}, 'x')", lambda: one.str.replace(pat, "x"), regex_pattern=pat)
        add(f"replace-all/bad-regex/{i}", "replace", one, {"pattern": pat, "value": "x", "literal": False, "all": True},
            f"s.str.replace_all({lit_py(pat)}, 'x')", lambda: one.str.replace_all(pat, "x"), regex_pattern=pat)
    # a bad pattern is no error when it is a literal, or when there is no row to match
    add("contains/bad-regex-literal", "contains", one, {"pattern": "(", "literal": True},
        "s.str.contains('(', literal=True)", lambda: one.str.contains("(", literal=True))
    add("replace/bad-regex-literal", "replace", one, {"pattern": "(", "value": "x", "literal": True, "all": True},
        "s.str.replace_all('(', 'x', literal=True)", lambda: one.str.replace_all("(", "x", literal=True))
    empty_s = mk("str", [])
    add("contains/bad-regex-empty-series", "contains", empty_s, {"pattern": "(", "literal": False},
        "s.str.contains('(')", lambda: empty_s.str.contains("("), regex_pattern="(")

    for name, meth in (("starts_with", "starts_with"), ("ends_with", "ends_with")):
        key = "prefix" if name == "starts_with" else "suffix"
        affixes = ["a", "", "abc", "ab", "bc", "c", "a.", "é", "😀", "ΑΣ", "Σ", "ABC", " ", "x.y.z", "abcabcx", "(", ".*", "\\"]
        for i, af in enumerate(affixes):
            add(f"{name}/{i}", name, text_s, {key: af}, f"s.str.{meth}({lit_py(af)})",
                lambda: getattr(text_s.str, meth)(af))
        add(f"{name}/empty-series", name, empty_s, {key: "a"}, f"s.str.{meth}('a')", lambda: getattr(empty_s.str, meth)("a"))
        for dt in DTYPES:
            if dt == "str":
                continue
            s = mk(dt, OTHER[dt])
            add(f"{name}/{dt}", name, s, {key: "a"}, f"s.str.{meth}('a')", lambda: getattr(s.str, meth)("a"))

    # ---- replace / replace_all -----------------------------------------------
    replaces = [
        ("b", "X", False), ("b", "X", True), ("a", "", False), ("a", "", True), ("", "-", False),
        ("", "-", True), ("b*", "-", False), ("x*", "-", False), ("([a-z])([0-9]+)", "<$2|$1>", False),
        ("([a-z])([0-9]+)", "<$2$1>", False), ("[0-9]+", "[$0]", False),
        ("([a-z])([0-9]+)", "${1}_${2}x", False), ("([a-z])([0-9]+)", "$1a", False),
        ("b", "$$", False), ("b", "$", False), ("b", "a$", False), ("b", "a${", False),
        ("b", "a${1", False), ("b", "$-", False), ("b", "[$9]", False),
        ("(?<n>[0-9]+)", "[$n]{${n}}", False), ("(?<n>[0-9]+)", "[$nope]", False),
        ("([a-z])([0-9]+)", "[$10]", False), ("b", "[$_]", False), ("b", "[${ 0 }]", False),
        ("b", "[${}]", False), ("(a)|(c)", "[$1,$2]", False), ("b", "$0", True), ("x.y", "$1", True),
        (".", "!", True), (".", "!", False), ("^", ">", False), ("$", "<", False), ("^a", ">", False),
        ("(?i:b)", "-", False), ("a+?", "-", False), ("é", "e", False), ("😀", "<>", False),
        ("[α-ω]+", "-", False), ("\\.", "!", False), ("(a)(b)?", "[$2]", False),
        ("(ab)+", "<$1>", False), ("a", "$$$$", False), ("(a)", "${1}${1}", False),
        ("(a)", "$1$1", False), ("ab", "$0$0", False), ("A", "$0", True), ("c", "\\", False),
        ("ab12", "-", True), (" ", "", True), ("b|c", "($0)", False), ("(?:a)(b)", "<$1>", False),
        ("(?<x>a)(?<y>b)", "$y$x", False), ("(?<x>a)(?<y>b)", "${y}${x}!", False),
        ("[[:digit:]]+", "#", False), ("$", "$", False), ("l+", "L", False), ("ß", "ss", True),
        ("[^a-z ]", "?", False), ("a|", "-", False), ("(x)?", "[$1]", False), ("a{2}", "<$0>", False),
        ("b", "${+1}", False), ("(b)", "${+1}", False), ("(b)", "${01}", False), ("(b)", "$01", False),
        ("(b)", "$1x", False), ("(b)", "${1}x", False), ("(b)", "$ 1", False),
    ]
    for i, (pat, val, lit) in enumerate(replaces):
        for all_ in (False, True):
            meth = "replace_all" if all_ else "replace"
            add(f"replace/{i}/{'all' if all_ else 'first'}", "replace", text_s,
                {"pattern": pat, "value": val, "literal": lit, "all": all_},
                f"s.str.{meth}({lit_py(pat)}, {lit_py(val)}, literal={lit})",
                lambda: getattr(text_s.str, meth)(pat, val, literal=lit))
    for dt in DTYPES:
        if dt == "str":
            continue
        s = mk(dt, OTHER[dt])
        for all_ in (False, True):
            meth = "replace_all" if all_ else "replace"
            add(f"replace/{dt}/{'all' if all_ else 'first'}", "replace", s,
                {"pattern": "a", "value": "b", "literal": False, "all": all_}, f"s.str.{meth}('a', 'b')",
                lambda: getattr(s.str, meth)("a", "b"))
    add("replace/empty-series", "replace", empty_s, {"pattern": "a", "value": "b", "literal": False, "all": True},
        "s.str.replace_all('a', 'b')", lambda: empty_s.str.replace_all("a", "b"))

    # ---- strip ----------------------------------------------------------------
    chars_list = [None, "", " ", "x", "x ", "😀", "xh", " ", "é", "hi", "\u0085x", "ab"]
    for side, suffix in (("both", ""), ("start", "_start"), ("end", "_end")):
        meth = "strip_chars" + suffix
        for i, ch in enumerate(chars_list):
            add(f"strip/{side}/{i}", "strip", strip_s, {"chars": ch, "side": side},
                f"s.str.{meth}({lit_py(ch)})", lambda: getattr(strip_s.str, meth)(ch))
        add(f"strip/{side}/empty-series", "strip", empty_s, {"chars": None, "side": side},
            f"s.str.{meth}()", lambda: getattr(empty_s.str, meth)())
        for dt in DTYPES:
            if dt == "str":
                continue
            s = mk(dt, OTHER[dt])
            add(f"strip/{side}/{dt}", "strip", s, {"chars": None, "side": side}, f"s.str.{meth}()",
                lambda: getattr(s.str, meth)())

    # ---- dt -------------------------------------------------------------------
    fields = ["year", "month", "day", "weekday", "ordinal_day", "hour", "minute", "second"]
    date_s = mk("date", DATES)
    dt_s = mk("datetime[μs]", DATETIMES)
    for fld in fields:
        add(f"dt/{fld}/date", "dt", date_s, {"field": fld}, f"s.dt.{fld}()", lambda: getattr(date_s.dt, fld)())
        add(f"dt/{fld}/datetime", "dt", dt_s, {"field": fld}, f"s.dt.{fld}()", lambda: getattr(dt_s.dt, fld)())
        for dt in DTYPES:
            if dt in ("date", "datetime[μs]"):
                continue
            s = mk(dt, OTHER[dt])
            add(f"dt/{fld}/{dt}", "dt", s, {"field": fld}, f"s.dt.{fld}()", lambda: getattr(s.dt, fld)())
        e = mk("date", [])
        add(f"dt/{fld}/date-empty", "dt", e, {"field": fld}, f"s.dt.{fld}()", lambda: getattr(e.dt, fld)())
        n = mk("datetime[μs]", [None, None])
        add(f"dt/{fld}/datetime-all-null", "dt", n, {"field": fld}, f"s.dt.{fld}()", lambda: getattr(n.dt, fld)())

    # ---- documented differences (docs/golden/known-diffs/regex.md) -----------
    skips = [
        ("digit-escape", "\\d", "a1", "\\d is not supported by @string.Regex (use [[:digit:]])"),
        ("word-escape", "\\w+", "a_1 b", "\\w is not supported by @string.Regex (use [[:word:]])"),
        ("space-escape", "\\s", "a b", "\\s is not supported by @string.Regex (use [[:space:]])"),
        ("hex-escape", "\\x41", "A", "\\xHH is not supported by @string.Regex"),
        ("nested-repeat", "a**", "abc", "@string.Regex rejects a repetition of a repetition"),
        ("global-flag", "(?i)abc", "ABC", "@string.Regex has no global flag group (?i); use (?i:...)"),
        ("flag-s", "(?s)a.b", "a\nb", "@string.Regex has no (?s) flag group"),
        ("flag-m", "(?m)^b", "a\nb", "@string.Regex has no (?m) flag group, ^ and $ are not multi-line"),
        ("ci-unicode", "(?i:é)", "É", "(?i:...) folds ASCII letters only"),
        ("ci-kelvin", "(?i:k)", "K", "(?i:...) folds ASCII letters only"),
        ("dot-newline", "a.b", "a\nb", "`.` matches \\n in @string.Regex but not in Rust regex"),
        ("unicode-class", "\\p{L}+", "αβ", "\\p{..} Unicode classes are not supported by @string.Regex"),
        ("posix-negated", "[[:^digit:]]", "a1", "[[:^name:]] negated POSIX classes are not supported"),
        ("non-greedy-flag", "(?U)a+", "aaa", "@string.Regex has no (?U) flag group"),
        ("named-p", "(?P<n>a)", "a", "@string.Regex names a group (?<n>...), not (?P<n>...)"),
        ("class-escape", "[\\d]", "1", "\\d is not supported by @string.Regex, also inside a class"),
        ("word-boundary", "\\bé", "é", "\\b is an ASCII word boundary in @string.Regex, a Unicode one in Rust regex"),
        ("text-start", "\\Aa", "a", "\\A is not supported by @string.Regex (use ^)"),
        ("text-end", "a\\z", "a", "\\z is not supported by @string.Regex (use $)"),
        ("escaped-hyphen", "a\\-b", "a-b", "@string.Regex only accepts the escapes it knows; \\- is not one (write the character, or use a class)"),
        ("class-bracket-first", "[]a]", "]", "a ] right after [ is a literal in Rust regex, a syntax error in @string.Regex"),
        ("class-dash", "[a-]", "-", "a - at the start or end of a class is a literal in Rust regex, a syntax error in @string.Regex (write \\-)"),
        ("repeat-repeat", "a{2}{3}", "aaaaaa", "@string.Regex rejects a repetition of a repetition"),
        ("unicode-letter", "\\pL", "a", "\\p classes are not supported by @string.Regex"),
    ]
    for cid, pat, text, reason in skips:
        s = mk("str", [text])
        add(f"skip/contains/{cid}", "contains", s, {"pattern": pat, "literal": False},
            f"s.str.contains({lit_py(pat)})", lambda: s.str.contains(pat), skip=reason, regex_pattern=pat)
        add(f"skip/replace/{cid}", "replace", s, {"pattern": pat, "value": "-", "literal": False, "all": True},
            f"s.str.replace_all({lit_py(pat)}, '-')", lambda: s.str.replace_all(pat, "-"), skip=reason,
            regex_pattern=pat)

    emit("str_dt", {"cases": CASES, "inputs": INPUTS}, compact=True)
    root = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
    src = os.path.join(root, "src", "pl", "golden_str_dt_data_test.mbt")
    dst = os.path.join(root, "src", "pl", "golden_str_dt_data_wbtest.mbt")
    # A white-box test file: the data is read by str_dt_golden_wbtest.mbt. MoonBit
    # source may not contain a raw U+2028/U+2029 (not even in a `#|` string), so
    # they are written as the JSON escape, which the JSON parser turns back.
    with open(src, encoding="utf-8") as f:
        text = f.read()
    text = text.replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")
    with open(dst, "w", encoding="utf-8") as f:
        f.write(text)
    os.remove(src)
    nerr = sum(1 for c in CASES if "error" in c)
    nskip = sum(1 for c in CASES if "skip" in c)
    print(f"polars {pl.__version__}: wrote {len(CASES)} cases ({nerr} errors, {nskip} skipped)")


main()
