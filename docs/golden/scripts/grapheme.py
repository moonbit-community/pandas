"""Generates the grapheme-cluster table of `@pl`'s `Show` (src/pl/grapheme_data.mbt) and
checks the table-wrapping model of `cell_lines` (src/pl/format.mbt) against polars.

Why `Show` needs grapheme clusters
----------------------------------
polars prints with comfy-table. When a cell line is wider than its column (31 columns at
most), comfy-table's `split_line` wraps it at spaces and cuts a word that is wider than the
column with `split_long_word`, which walks the word *grapheme cluster by grapheme cluster*
(the `unicode-segmentation` crate) and adds up `UnicodeWidthStr::width` of every cluster on
its own. So a flag, a keycap or `क्षि` is never split across two lines, and a Arabic
lam-alef pair counts 1 + 1 (two clusters), not 1 (one string).

The UCD version
---------------
`unicode-segmentation` inside polars 2.1.0 implements UAX #29 with the data of Unicode 17.0.0
(measured: Unicode 16.0.0 and 18.0.0 data each give different cluster boundaries for
U+2605 ZWJ U+2605 and for Myanmar consonant + U+1039 + consonant, Unicode 17.0.0 gives none).
The files are downloaded, not committed (they are large):

    https://www.unicode.org/Public/17.0.0/ucd/auxiliary/GraphemeBreakProperty.txt
        sha256 d6b51d1d2ae5c33b451b7ed994b48f1f4dc62b2272a5831e7fd418514a6bae89
    https://www.unicode.org/Public/17.0.0/ucd/emoji/emoji-data.txt
        sha256 2cb2bb9455cda83e8481541ecf5b6dfda66a3bb89efa3fa7c5297eccf607b72b
    https://www.unicode.org/Public/17.0.0/ucd/DerivedCoreProperties.txt
        sha256 24c7fed1195c482faaefd5c1e7eb821c5ee1fb6de07ecdbaa64b56a99da22c08

Usage (repository root; the check needs polars 2.1.0, the generator only Python 3):

    python3 docs/golden/scripts/grapheme.py UCD_DIR && moon fmt
    # (UCD_DIR also needs auxiliary/GraphemeBreakTest.txt, flat like the other files:
    #  https://www.unicode.org/Public/17.0.0/ucd/auxiliary/GraphemeBreakTest.txt
    #  sha256 e2d134d2c52919bace503ebb6a551c1855fe1a1faec18478c78fff254a1793ec)
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/grapheme.py --check UCD_DIR [n [seed]]

The table
---------
`grapheme_ranges` holds `first, last, class` for every code point whose class is not 0, in
ascending order. `class` is the Grapheme_Cluster_Break value (low 4 bits: 1 CR, 2 LF,
3 Control, 4 Extend, 5 ZWJ, 6 Regional_Indicator, 7 Prepend, 8 SpacingMark, 9 L, 10 V, 11 T)
plus 16 for Extended_Pictographic and 32 / 64 / 128 for InCB=Consonant / Linker / Extend
(rule GB9c, Unicode 15.1+). The Hangul syllables U+AC00-U+D7A3 (LV and LVT) are left out of
the table; `grapheme_class` computes them.

The generator also writes `src/pl/grapheme_break_data_wbtest.mbt`: the lines of Unicode's own
conformance file GraphemeBreakTest.txt (766 cases), which `grapheme_wbtest.mbt` runs through
`grapheme_break` (independent of polars: the table and the rules are checked against the
standard, `--check` and `show.json` check the use in table cells against polars).

The wrapping model (`--check`)
------------------------------
`wrap_line` below is the model of comfy-table's `split_line` that `cell_lines` implements; the
check wraps random strings with it and compares every line with polars' table output.
A line whose width is at most the column width is kept as it is. Otherwise it is split at
single spaces into words and the words are laid out in order:

* the current line is full (not even one column is left after the joining space): it is
  closed and the word is laid out again on the next line;
* the word fits on the current line (`line_width + 1 + word_width <= column width`, the 1 for
  the joining space when the line is not empty): it is appended;
* the word is wider than the column and the current line has at least `MIN_FREE` (4) columns
  left (measured without the joining space; always true for an empty line): as much of the
  word as fits in the space left after the joining space (whole grapheme clusters, each
  measured on its own) is appended, the line is closed and the rest of the word is laid out
  as the next word (if not even the first cluster fits an empty line, one code point is
  taken: a run of 16 Hangul choseong is one cluster of 32 columns);
* otherwise the current line is closed and the word starts the next line (and is split there
  if it is still too wide).

Spaces that end a line are not printed (the cell is padded anyway); a leading run of empty
words (leading spaces) is dropped, because "the line is empty" is decided on the text.

The column width is `min(31, widest cell)`, where no cell counts for more than the largest
`min(2 * code points, UTF-8 bytes)` of the cells of the column (`column_width`; the name,
`---` and the dtype are cells too). Only U+17D8, three columns and three bytes, is ever
wider than that bound, so the bound only matters for cells with that character.
"""
import bisect
import os
import random
import sys

NAMES = {"Other": 0, "CR": 1, "LF": 2, "Control": 3, "Extend": 4, "ZWJ": 5, "Regional_Indicator": 6,
         "Prepend": 7, "SpacingMark": 8, "L": 9, "V": 10, "T": 11, "LV": 12, "LVT": 13}
EP = 16
MIN_FREE = 4  # comfy-table does not split a word into a line with fewer free columns
INCB = {"None": 0, "Consonant": 32, "Linker": 64, "Extend": 128}
MAX_CP = 0x110000
HANGUL_FIRST, HANGUL_LAST = 0xAC00, 0xD7A3
OUT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "src", "pl", "grapheme_data.mbt")
TEST_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "src", "pl", "grapheme_break_data_wbtest.mbt"
)


def parse(path, prop_filter):
    out = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.split("#")[0].strip()
            if not line:
                continue
            parts = [p.strip() for p in line.split(";")]
            if len(parts) < 2 or not prop_filter(parts):
                continue
            a, _, b = parts[0].partition("..")
            out.append((int(a, 16), int(b or a, 16), parts))
    return sorted(out)


class Props:
    """Grapheme_Cluster_Break, Extended_Pictographic and InCB of every code point."""

    def __init__(self, ucd):
        gcb = parse(os.path.join(ucd, "GraphemeBreakProperty.txt"), lambda p: True)
        ep = parse(os.path.join(ucd, "emoji-data.txt"), lambda p: p[1] == "Extended_Pictographic")
        incb = parse(os.path.join(ucd, "DerivedCoreProperties.txt"), lambda p: p[1] == "InCB")
        self.cls = [0] * MAX_CP
        for a, b, p in gcb:
            for c in range(a, b + 1):
                self.cls[c] = NAMES[p[1]]
        for a, b, p in ep:
            for c in range(a, b + 1):
                self.cls[c] |= EP
        for a, b, p in incb:
            for c in range(a, b + 1):
                self.cls[c] |= INCB[p[2]]

    def gcb(self, c):
        return self.cls[c] & 15

    def ep(self, c):
        return self.cls[c] & EP != 0

    def incb(self, c):
        return self.cls[c] & 224


def clusters(P, cps):
    """UAX #29 extended grapheme clusters of the code point list `cps` (list of lists)."""
    out = []
    for i, b in enumerate(cps):
        if i == 0 or boundary(P, cps, i):
            out.append([b])
        else:
            out[-1].append(b)
    return out


def boundary(P, cps, i):
    a, b = cps[i - 1], cps[i]
    ga, gb = P.gcb(a), P.gcb(b)
    CR, LF, CTRL, EXT, ZWJ, RI, PRE, SM, L, V, T, LV, LVT = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
    if ga == CR and gb == LF:
        return False
    if ga in (CR, LF, CTRL) or gb in (CR, LF, CTRL):
        return True
    if ga == L and gb in (L, V, LV, LVT):
        return False
    if ga in (LV, V) and gb in (V, T):
        return False
    if ga in (LVT, T) and gb == T:
        return False
    if gb in (EXT, ZWJ, SM) or ga == PRE:
        return False
    if P.incb(b) == 32:  # GB9c: Consonant [Extend Linker]* Linker [Extend Linker]* x Consonant
        j, linker = i - 1, False
        while j >= 0 and P.incb(cps[j]) in (64, 128):
            linker = linker or P.incb(cps[j]) == 64
            j -= 1
        if j >= 0 and P.incb(cps[j]) == 32 and linker:
            return False
    if ga == ZWJ and P.ep(b):  # GB11: ExtPict Extend* ZWJ x ExtPict
        j = i - 2
        while j >= 0 and P.gcb(cps[j]) == EXT:
            j -= 1
        if j >= 0 and P.ep(cps[j]):
            return False
    if ga == RI and gb == RI:  # GB12, GB13: regional indicators pair up from the left
        n, j = 0, i - 1
        while j >= 0 and P.gcb(cps[j]) == RI:
            n, j = n + 1, j - 1
        if n % 2 == 1:
            return False
    return True


def emit(P, path):
    rows = []
    for c in range(MAX_CP):
        v = P.cls[c]
        if v == 0 or HANGUL_FIRST <= c <= HANGUL_LAST:
            continue
        if rows and rows[-1][1] == c - 1 and rows[-1][2] == v:
            rows[-1][1] = c
        else:
            rows.append([c, c, v])
    # the table must reproduce every class, the Hangul syllables aside
    for c in range(HANGUL_FIRST, HANGUL_LAST + 1):
        assert P.gcb(c) == (12 if (c - HANGUL_FIRST) % 28 == 0 else 13) and P.cls[c] == P.gcb(c), hex(c)
    assert P.cls[HANGUL_FIRST - 1] != 12 and P.cls[HANGUL_LAST + 1] != 12
    lines = [
        "// Generated by docs/golden/scripts/grapheme.py from the Unicode 17.0.0 data files",
        "// (GraphemeBreakProperty.txt, emoji-data.txt, DerivedCoreProperties.txt). Do not",
        "// edit by hand; run the script again instead.",
        "//",
        "// `grapheme_ranges`: `first, last, class` of every code point range whose class is",
        "// not 0 (Other), in ascending order, except the Hangul syllables U+AC00-U+D7A3. The",
        "// class is the Grapheme_Cluster_Break value (the low 4 bits) plus 16 for",
        "// Extended_Pictographic and 32 / 64 / 128 for InCB=Consonant / Linker / Extend.",
        "",
        "///|",
        "let grapheme_ranges : FixedArray[Int32] = [",
    ]
    for a, b, v in rows:
        lines.append(f"  0x{a:x}, 0x{b:x}, {v},")
    lines.append("]")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    return len(rows)


def emit_tests(P, ucd, path):
    """Copies the cases of GraphemeBreakTest.txt (after checking `boundary` against them)."""
    cases = []
    with open(os.path.join(ucd, "GraphemeBreakTest.txt"), encoding="utf-8") as f:
        for line in f:
            body = line.split("#")[0].strip()
            if body:
                cases.append(body)
    for body in cases:
        items = body.split()
        cps = [int(x, 16) for x in items[1::2]]
        want = [items[2 * i] == "÷" for i in range(1, len(cps))]
        got = [boundary(P, cps, i) for i in range(1, len(cps))]
        assert want == got, body
    lines = [
        "// Generated by docs/golden/scripts/grapheme.py from Unicode 17.0.0's",
        "// GraphemeBreakTest.txt. Do not edit by hand; run the script again instead.",
        "//",
        "// Each case is the test line: code points in hex, `÷` where there is a cluster",
        "// boundary and `×` where there is none (the boundaries at both ends included).",
        "",
        "///|",
        "let grapheme_break_cases : Array[String] = [",
    ]
    for body in cases:
        lines.append(f'  "{body}",')
    lines.append("]")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    return len(cases)


# --- the wrapping model --------------------------------------------------------


def wrap_line(line, P, width_of, limit=31):
    """Wraps one line (no newline) as comfy-table's `split_line` does; `width_of` is the width
    of a string, `P` the grapheme properties."""
    if width_of(line) <= limit:
        return [line]
    words = list(reversed(line.split(" ")))
    lines, cur = [], ""
    while words:
        word = words.pop()
        join = 1 if cur != "" else 0
        if join and limit - width_of(cur) - join <= 0:
            lines.append(cur)  # no column left for anything (not even a zero-width word)
            cur = ""
            words.append(word)
        elif width_of(cur) + join + width_of(word) <= limit:
            cur = cur + " " + word if join else word
        elif width_of(word) > limit and (cur == "" or limit - width_of(cur) >= MIN_FREE):
            room = limit - width_of(cur) - join
            first, w = "", 0
            rest = word
            for g in clusters(P, [ord(c) for c in word]):
                gs = "".join(map(chr, g))
                if w + width_of(gs) > room:
                    break
                w += width_of(gs)
                first += gs
            if first == "" and cur == "":  # not even the first cluster fits a fresh line: one code point is taken anyway
                first = word[0]
            rest = word[len(first):]
            lines.append((cur + " " if join else cur) + first)
            cur = ""
            words.append(rest)
        else:
            lines.append(cur)
            cur = ""
            words.append(word)
    if cur != "":
        lines.append(cur)
    return lines


def column_width(texts, width_of, limit=31):
    """The width polars gives a column: `texts` are all its cells, the name, `---` and the
    dtype included. Every cell has a width (its widest line) and a bound `min(2 * code
    points, UTF-8 bytes)`; the column is as wide as its widest cell, but no cell counts for
    more than the widest bound in the column, and never more than 31. The bound only
    matters for U+17D8 (3 columns, 3 bytes), the one character wider than two columns per
    code point."""
    bound = max(min(2 * len(t), len(t.encode("utf-8"))) for t in texts)
    w = max(min(max(width_of(part) for part in t.split("\n")), bound) for t in texts)
    return min(w, limit)


def model_cell(text, P, width_of, column_width):
    out = []
    for part in text.split("\n"):
        out += [x.rstrip(" ") for x in wrap_line(part, P, width_of, column_width)]
    return out


# --- check against polars ------------------------------------------------------


def check(ucd, n, seed):
    import importlib.util

    import polars as pl

    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location("char_width", os.path.join(here, "char_width.py"))
    cw = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(cw)
    W, S = cw.load_tables(os.path.join(here, "..", "..", "..", "src", "pl", "char_width_data.mbt"))
    model = cw.Model(W, S)
    width_of = model.width
    P = Props(ucd)

    def frame_cells(strs):
        """Lays out one frame of at most 10 str cells in polars; returns the lines of each."""
        pl.Config.restore_defaults()
        df = pl.DataFrame({"s": strs, "i": list(range(len(strs)))})
        out = str(df).split("\n")
        top = out[1].split("┬")[0]
        head = [i for i, l in enumerate(out) if l.startswith("╞")][0]
        cells = []
        for r in out[head + 1 : -1]:
            body = r[1:-1].rsplit("┆", 1)
            text = body[0][1:-1] if body[0].endswith(" ") else body[0][1:]
            if body[1].strip():
                cells.append([text.rstrip(" ")])
            else:
                cells[-1].append(text.rstrip(" "))
        return len(top) - 3, cells

    def cut(s):
        return s if len(s) <= 30 else s[:30] + "…"

    pools = {
        "words": [0x65E5] * 8 + [0x61] * 2 + [0x20],
        "marks": [0x65E5] * 30 + [0x61, 0x301, 0x302, 0x20, 0xFE0F, 0xFE0E, 0x200D, 0x20E3, 0x31, 0x1F1E8, 0x1F1F3, 0x1F600, 0x1F44D, 0x1F3FD, 0x915, 0x94D, 0x937, 0x93F, 0x1100, 0x1161, 0x11A8, 0xAC00, 0xAC01, 0x644, 0x627, 0x600, 0x5D0, 0x5DC, 0xE33, 0xE31, 0x17D2, 0x1781, 0x17D8, 0x2764, 0x263A, 0x1F468, 0x1F469, 0x1F467, 0x0D, 0x7F],
        "emoji": [0x65E5] * 24 + [0x1F468, 0x1F469, 0x1F467, 0x200D, 0x1F3FD, 0x1F600, 0x1F1E8, 0x1F1F3, 0x1F1FA, 0xFE0F, 0x2764, 0x1F525, 0x20E3, 0x31, 0x23, 0x61, 0x301, 0x1F3F4, 0xE0067, 0xE007F, 0x263A, 0x2605],
        "indic": [0x65E5] * 16 + [0x915, 0x94D, 0x937, 0x93F, 0x200D, 0x9A4, 0x9CD, 0x9B7, 0xD15, 0xD4D, 0xB95, 0xBCD, 0xC15, 0xC4D, 0xA95, 0xACD, 0x1780, 0x17D2, 0x1781, 0x301, 0x93C, 0x1000, 0x1039],
        "hangul": [0x65E5] * 16 + [0x1100, 0x1161, 0x11A8, 0xAC00, 0xAC01, 0x1160, 0xA960, 0xD7B0, 0xD7CB, 0x115F, 0x302E, 0x300, 0x200D],
        "arabic": [0x65E5] * 16 + [0x644, 0x627, 0x600, 0x605, 0x6DD, 0x64E, 0x622, 0x61C, 0x200D, 0x8E2, 0x110BD, 0x0D, 0x1F600],
        "jamo": [0x1100] * 12 + [0x1161, 0x11A8, 0x61, 0x20, 0x65E5, 0xAC00],
        "khmer": [0x65E5] * 8 + [0x17D8, 0x17D8, 0x17D8, 0x61, 0x20, 0x1780, 0x17D2],
    }
    rnd = random.Random(seed)
    total_bad = 0
    for name, pool in pools.items():
        strs = [cut("".join(chr(rnd.choice(pool)) for _ in range(rnd.randint(8, 32)))) for _ in range(n)]
        bad = []
        for k in range(0, len(strs), 10):
            chunk = strs[k : k + 10]
            col, got = frame_cells(chunk)
            # the column width the model expects (the header is "s", "---", "str")
            limit = column_width(chunk + ["s", "---", "str"], width_of)
            for s, g in zip(chunk, got):
                m = model_cell(s, P, width_of, limit)
                if m != g or limit != col:
                    bad.append((s, g, m, limit, col))
        print(f"wrap {name}: {len(strs)} cells, {len(bad)} differ")
        for s, g, m, limit, col in bad[:5]:
            print("   ", " ".join(f"{ord(c):X}" for c in s), "\n      polars", col, g, "\n      model ", limit, m)
        total_bad += len(bad)
    return total_bad


def main():
    args = sys.argv[1:]
    if args and args[0] == "--check":
        n = int(args[2]) if len(args) > 2 else 2000
        seed = int(args[3]) if len(args) > 3 else 1
        sys.exit(1 if check(args[1], n, seed) else 0)
    if len(args) != 1:
        sys.exit(__doc__)
    P = Props(args[0])
    count = emit(P, OUT_PATH)
    print(f"wrote {OUT_PATH}: {count} ranges")
    n = emit_tests(P, args[0], TEST_PATH)
    print(f"wrote {TEST_PATH}: {n} cases")


if __name__ == "__main__":
    main()
