"""Generates the display-width tables of `@pl`'s `Show` (src/pl/char_width_data.mbt)
by measuring polars' own table output, and checks the width rules that
`str_width` (src/pl/char_width.mbt) applies to character sequences.

Run from the repository root, on a machine that has polars 2.1.0:

    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/char_width.py && moon fmt
    /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/char_width.py --fuzz 200000 [seed]

(`moon fmt` re-wraps the number lists of the generated file; the committed file is
the formatted one.)

How a width is measured
-----------------------
polars prints a table with comfy-table, which pads every cell with spaces up to
the column width, using the width of the cell text as the layout engine sees it.
So the width of a text `s` is read off the table itself, with no Python width
library involved:

    pl.Config.set_tbl_hide_column_data_types(True)
    pl.Config.set_tbl_hide_column_names(True)
    str(pl.DataFrame({"s": [s]}))

is
    ┌────┐          column width W = len(top border) - 4
    │ s  │   ->     the row is "│ " + s + (W - width(s)) spaces + " │"
    └────┘

so `width(s) = W - (number of padding characters after s)`. The column is at
least one column wide (that is why a zero-width character leaves one padding
space), which the formula already accounts for. Every code point is measured
alone, in a table of its own. A second, independent method (all code points of a
chunk as rows of one column next to a reference row `x * 10`) is used as a
cross-check; the two must agree on every code point.

What is special
---------------
* U+0000-U+001F, U+007F-U+009F and the other control characters are printed as
  they are and counted as 1 column (as comfy-table does), so they need no rule.
* U+000A (`\\n`) cannot be measured: polars splits a cell at `\\n` into lines
  before it measures anything. The table records 1 for it (the old behaviour);
  `cell_lines` splits at `\\n` first, so the value is never used in a layout.
  It is left out of the comparison counts.
* U+D800-U+DFFF are not characters and are skipped.

Sequence rules
--------------
polars 2.1.0 lays out text with the `unicode-width` crate's *string* width (0.2),
which is not the sum of the character widths. The rules below were found by
measuring pairs/triples of characters against all 1 114 112 code points and then
fuzzing random sequences against polars (see `--fuzz`). The sets they use are
*derived here* by probing polars, not copied from a table:

* VS16 (U+FE0F) after a one-column character of the set `vs16` widens it to 2.
  VS15 (U+FE0E) after a two-column character of the set `vs15` narrows it to 1.
  U+FE01 after U+2018/2019/201C/201D widens it to 2 (`lq`).
* A Fitzpatrick modifier (`mod`, U+1F3FB-1F3FF) after an emoji modifier base
  (`emb`) is zero wide, and the base is then two columns wide.
* ZWJ (U+200D) after an "emoji" makes the next emoji zero wide. Emoji are: a
  character of `ejoin` (the emoji-presentation characters), a `vs16`/`vs15`
  character followed by U+FE0F (including a keycap U+20E3 after it), an `emb`
  base plus modifier, and a regional-indicator *pair*. A single regional
  indicator is one column and is not an emoji for this purpose; indicators pair up
  from the left; a pair right after a ZWJ is zero wide.
* Arabic ligature: a lam (`lam`) followed, possibly through transparent marks
  (`lamt`, and further lam letters), by an alef (`alef`) makes the alef zero wide.
* Hebrew: alef U+05D0, ZWJ, lamed U+05DC (variation selectors and a few other
  default-ignorable characters, `hebt`, may sit between) makes the lamed zero wide.
* Khmer: a letter of the set `coeng` right after COENG U+17D2 (variation selectors
  and ZWJ, `hebt`, may sit between) is zero wide: the subscript consonant. A run of marks
  that holds U+FE01 and U+FE0E (`vs_step`) breaks the chain, in the Hebrew rule too.
* Emoji tag sequence: U+1F3F4, tags and U+E007F count as an emoji for a following ZWJ (the
  base and the tag characters keep their own widths). The tags are 3 to 6 tag letters
  (U+E0061-U+E007A), or exactly 3 tag digits (U+E0030-U+E0039) followed by up to 4 letters;
  any other run (digits after letters, 1, 2, 4 or more digits, ...) is not an emoji.
* Everything else (Hangul jamo vowels/finals, Indic signs, combining marks,
  keycap U+20E3, tags, ZWJ itself ...) is just the per-character width, and
  those are zero or two wide by the table already.

* Quirk: after `<character of vs15 or lq> U+FE01 U+FE0E` (variation selectors may
  follow), the next hebrew lamed, `alef` letter or `coeng` letter is zero wide.

Known leftover differences (not reproduced; all come from the state machine of the width
library and none occurs in real text):

* U+2018 (or another curly quote) U+FE0F U+FE01, then any marks except ZWJ/ZWNJ, then an
  alef-group letter, the lamed or a Khmer subscript letter: polars widens the quote (one
  column more than here).
* The `leak` quirk above only lets variation selectors (`hebt`) sit between the quote and the
  letter; polars lets every zero-wide mark except ZWJ sit there.
* A Hebrew alef, a run of variation selectors with U+FE01 and U+FE0E, and then a ZWJ: the
  chain is cut by `vs_step` here, polars cuts it differently when the ZWJ follows a U+FE0E.
* An Arabic lam, then U+FE01 / U+FE0E in either order with two or more U+FE0F between them:
  polars loses the ligature, `lam` here only looks through one U+FE0F.
"""
import bisect
import multiprocessing as mp
import os
import random
import re
import sys

import polars as pl

pl.Config.restore_defaults()
pl.Config.set_tbl_hide_column_data_types(True)
pl.Config.set_tbl_hide_column_names(True)

MAX_CP = 0x110000
NEWLINE = 0x0A
ZWJ = 0x200D
EDGES_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "src", "pl", "char_width_edges_data_wbtest.mbt"
)
OUT_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "src", "pl", "char_width_data.mbt"
)


def width(s):
    """Width of `s` in a polars table cell (see the module docstring)."""
    lines = str(pl.DataFrame({"s": [s]})).split("\n")
    inner = len(lines[1]) - 4  # the top border is "┌" + "─" * (inner + 2) + "┐"
    row = lines[2]
    assert row.startswith("│ ") and row.endswith(" │"), repr(row)
    region = row[2:-2]
    assert region.startswith(s), (repr(s), repr(region))
    return inner - (len(region) - len(s))


def is_scalar(cp):
    return not (0xD800 <= cp <= 0xDFFF)


# --- parallel helpers -------------------------------------------------------

_PROBE = None


def _run_probe(args):
    lo, hi = args
    f = _PROBE
    return [f(chr(cp)) if is_scalar(cp) and cp != NEWLINE else -1 for cp in range(lo, hi)]


def probe_all(f, procs):
    """`f(chr(cp))` for every code point (-1 for the skipped ones)."""
    global _PROBE
    _PROBE = f
    step = 0x8000
    chunks = [(a, min(a + step, MAX_CP)) for a in range(0, MAX_CP, step)]
    with mp.get_context("fork").Pool(procs) as pool:
        parts = pool.map(_run_probe, chunks)
    return [x for part in parts for x in part]


# --- independent cross-check -------------------------------------------------


def _batch_check(args):
    lo, hi = args
    cps = [cp for cp in range(lo, hi) if is_scalar(cp) and cp != NEWLINE]
    ref = "x" * 10
    pl.Config.set_tbl_rows(-1)
    pl.Config.set_tbl_hide_column_data_types(False)
    pl.Config.set_tbl_hide_column_names(False)
    out = str(pl.DataFrame({"s": [ref] + [chr(c) for c in cps]})).split("\n")
    rows = out[6 : 6 + 1 + len(cps)]  # after the name, "---", dtype and "╞═╡" lines
    # row 0 is the reference: its width is 10, so every row is padded to 10 columns
    res = {}
    for cp, row in zip(cps, rows[1:]):
        region = row[2:-2]
        if not region.startswith(chr(cp)):
            res[cp] = None
            continue
        res[cp] = 10 - (len(region) - 1)
    return res


def cross_check(W, procs):
    step = 0x4000
    chunks = [(a, min(a + step, MAX_CP)) for a in range(0, MAX_CP, step)]
    with mp.get_context("fork").Pool(procs) as pool:
        parts = pool.map(_batch_check, chunks)
    checked = bad = 0
    for part in parts:
        for cp, wd in part.items():
            checked += 1
            if wd != W[cp]:
                bad += 1
                if bad <= 10:
                    print(f"  cross-check mismatch U+{cp:04X}: single {W[cp]} batch {wd}")
    return checked, bad


# --- sets ----------------------------------------------------------------------


def ranges(cps):
    out = []
    for c in cps:
        if out and out[-1][1] == c - 1:
            out[-1][1] = c
        else:
            out.append([c, c])
    return [(a, b) for a, b in out]


def derive_sets(W, procs):
    ok = [c for c in range(MAX_CP) if W[c] >= 0]
    P = {}
    probes = {
        "vs16": lambda x: width(x + "️"),
        "vs15": lambda x: width(x + "︎"),
        "lq": lambda x: width(x + "︁"),
        "after_zwj": lambda x: width("😀‍" + x),
        "after_zwj_pair": lambda x: width("😀‍" + x + x),
        "after_base": lambda x: width("👍" + x),
        "before_tone": lambda x: width(x + "🏽"),
        "then_alef": lambda x: width(x + "ا"),
        "lam_then": lambda x: width("ل" + x),
        "lam_x_alef": lambda x: width("ل" + x + "ا"),
        "coeng": lambda x: width("\u1780\u17d2" + x),
        "vs16_zwj": lambda x: width(x + "\ufe0f\u200d😀"),
        "heb_before_zwj": lambda x: width("א" + x + "‍ל"),
        "heb_after_zwj": lambda x: width("א‍" + x + "ל"),
    }
    for name, f in probes.items():
        P[name] = probe_all(f, procs)
    S = {}
    S["vs16"] = [c for c in ok if W[c] == 1 and P["vs16"][c] == 2]
    S["vs15"] = [c for c in ok if W[c] == 2 and P["vs15"][c] == 1]
    S["lq"] = [c for c in ok if W[c] == 1 and P["lq"][c] == 2]
    S["ejoin"] = [c for c in ok if W[c] > 0 and P["after_zwj"][c] == 2]
    S["ri"] = [c for c in ok if W[c] == 1 and P["after_zwj_pair"][c] == 2]
    S["mod"] = [c for c in ok if W[c] == 2 and P["after_base"][c] == 2]
    mods = set(S["mod"])
    S["emb"] = [c for c in ok if W[c] > 0 and c not in mods and P["before_tone"][c] == 2]
    S["lam"] = [c for c in ok if W[c] == 1 and P["then_alef"][c] == 1]
    S["alef"] = [c for c in ok if W[c] == 1 and P["lam_then"][c] == 1]
    S["lamt"] = [c for c in ok if W[c] == 0 and P["lam_x_alef"][c] == 1]
    # characters that take U+FE0F in an emoji presentation sequence but are two
    # columns wide already: the FE0F keeps the "emoji" for a following ZWJ
    S["vs16w"] = [c for c in ok if W[c] == 2 and P["vs16_zwj"][c] == 2]
    S["coeng"] = [c for c in ok if W[c] > 0 and P["coeng"][c] == 1]
    S["hebt"] = [
        c for c in ok if W[c] == 0 and P["heb_before_zwj"][c] == 1 and P["heb_after_zwj"][c] == 1
    ]
    assert S["mod"] == list(range(0x1F3FB, 0x1F400)), "modifier set changed"
    assert S["ri"] == list(range(0x1F1E6, 0x1F200)), "regional indicator set changed"
    assert S["lq"] == [0x2018, 0x2019, 0x201C, 0x201D], "lq set changed"
    return S


# --- reference model of the sequence rules -------------------------------------


def vs_step(state, c):
    """The marks between U+17D2 (or U+05D0) and the next letter are transparent, except that
    polars' width library loses the letter after a run of variation selectors that holds
    U+FE01 and U+FE0E (in either order, U+FE0F may sit between). Returns `(state, broke)`.
    States: 0 start, 1 only U+FE01/U+FE0F so far (with a U+FE01), 2 only U+FE0E/U+FE0F so far
    (with a U+FE0E), 3 only U+FE0F so far, 4 any other mark seen (nothing breaks any more).
    After a U+FE0E run, another mark starts again from 0."""
    if state == 0 or state == 3:
        if c == 0xFE01:
            return 1, False
        if c == 0xFE0E:
            return 2, False
        if c == 0xFE0F:
            return 3, False
        return 4, False
    if state == 1:
        if c == 0xFE0E:
            return 1, True
        return (1 if c in (0xFE01, 0xFE0F) else 4), False
    if state == 2:
        if c == 0xFE01:
            return 2, True
        return (2 if c in (0xFE0E, 0xFE0F) else 0), False
    return 4, False


class Model:
    def __init__(self, W, S):
        self.W = W
        self.s = {k: set(v) for k, v in S.items()}

    def width(self, text):
        W, S = self.W, self.s
        cs = [ord(ch) for ch in text]
        n = len(cs)
        tot = 0
        last = None  # previous code point
        lastw = 0  # width counted for it
        emoji = False  # the text so far ends in an emoji (a ZWJ may join the next one)
        zr = False  # the previous char was a ZWJ after an emoji
        lam = False  # inside an Arabic lam ... (marks) run, waiting for an alef
        vf = False  # the previous char was a U+FE0F that completed an emoji presentation
        heb = 0  # 1 after alef, 2 after alef (marks) ZWJ
        coeng = False  # after U+17D2 (and transparent marks)
        leak = False  # after `<vs15 or curly quote> U+FE01 U+FE0E` (see the docstring)
        tags = -1  # -1: not in an emoji tag sequence after U+1F3F4; else tags are counted below
        tagd = tagl = 0  # tag digits (U+E0030-E0039) and tag letters (U+E0061-E007A) so far
        tagbad = False  # a tag digit came after a tag letter
        vsd = 0  # `vs_step` state of the marks after U+17D2 / U+05D0
        tag_end = False  # this character completes an emoji tag sequence
        i = 0
        while i < n:
            c = cs[i]
            nxt = cs[i + 1] if i + 1 < n else None
            zr_here, zr = zr, False
            vf_here, vf = vf, False
            # U+1F3F4 + tags + U+E007F is an emoji for a following ZWJ; the tags are 3 to 6
            # letters, or exactly 3 digits followed by up to 4 letters (measured on every
            # run of up to 8 tags)
            tag_end = False
            if c == 0x1F3F4:
                tags, tagd, tagl, tagbad = 0, 0, 0, False
            elif tags >= 0 and 0xE0030 <= c <= 0xE0039:
                tagbad = tagbad or tagl > 0  # digits count only in front of the letters
                tagd += 1
            elif tags >= 0 and 0xE0061 <= c <= 0xE007A:
                tagl += 1
            elif (c == 0xE007F and tags >= 0 and not tagbad
                  and ((tagd == 0 and 3 <= tagl <= 6) or (tagd == 3 and tagl <= 4))):
                tag_end, tags = True, -1
            else:
                tags = -1
            if c == 0x5D0:
                heb, vsd = 1, 0
            elif c == ZWJ and heb >= 1:
                heb = 2
            elif c in S["hebt"] and heb >= 1:
                if heb == 1:
                    vsd, broke = vs_step(vsd, c)
                    if broke:
                        heb = 0
            elif c != 0x5DC or heb != 2:
                heb = 0
            leak_hit = False
            if c == 0xFE0E and i >= 2 and cs[i - 1] == 0xFE01 and (cs[i - 2] in S["lq"] or cs[i - 2] in S["vs15"]):
                leak = True
            elif leak and c not in S["hebt"]:
                leak = False
                leak_hit = c == 0x5DC or c in S["alef"] or c in S["coeng"]
            coeng_hit = False
            if c == 0x17D2:
                coeng, vsd = True, 0
            elif coeng and c in S["hebt"]:
                vsd, broke = vs_step(vsd, c)
                if broke:
                    coeng = False
            elif coeng and c in S["coeng"]:
                coeng, coeng_hit = False, True
            else:
                coeng = False
            if c == ZWJ:
                zr, emoji, last, lam = emoji, False, c, False
                i += 1
                continue
            if zr_here:
                if c in S["ri"] and nxt in S["ri"]:
                    emoji, last, lastw, lam = True, nxt, 0, False
                    i += 2
                    continue
                if c in S["ejoin"] and not (c in S["vs15"] and nxt == 0xFE0E):
                    emoji, last, lastw, lam = True, c, 0, False
                    i += 1
                    continue
                if c in S["vs16"] and nxt == 0xFE0F:
                    emoji, last, lastw, lam = True, 0xFE0F, 0, False
                    i += 2
                    continue
                if c in S["emb"] and nxt in S["mod"]:
                    emoji, last, lastw, lam = True, nxt, 0, False
                    i += 2
                    continue
            if heb == 2 and c == 0x5DC:
                heb, last, lastw, emoji, lam = 0, c, 0, False, False
                i += 1
                continue
            if c in S["ri"] and nxt in S["ri"]:
                tot += 2
                emoji, last, lastw, lam = True, nxt, 1, False
                i += 2
                continue
            if c == 0xFE0F and last in S["vs16"] and lastw == 1:
                tot += 1
                lastw, emoji, last, vf = 2, True, c, True
                i += 1
                continue
            if c == 0xFE0F and (last in S["vs16"] or last in S["vs16w"]):
                emoji, last, vf = True, c, True
                i += 1
                continue
            if c == 0x20E3 and last == 0xFE0F and vf_here:
                last = c
                i += 1
                continue
            if c == 0xFE01 and last in S["lq"] and lastw == 1:
                tot += 1
                lastw, last = 2, c
                i += 1
                continue
            if c == 0xFE0E and last in S["vs15"] and lastw == 2:
                tot -= 1
                lastw, emoji, last = 1, False, c
                i += 1
                continue
            if c in S["mod"] and last in S["emb"]:
                if lastw == 1:
                    tot += 1
                    lastw = 2
                emoji, last = True, c
                i += 1
                continue
            if lam and (
                (last == 0xFE01 and c == 0xFE0E)
                or (last == 0xFE0E and c == 0xFE01)
                or (c == 0xFE0E and last == 0xFE0F and i >= 2 and cs[i - 2] == 0xFE01)
                or (c == 0xFE01 and last == 0xFE0F and i >= 2 and cs[i - 2] == 0xFE0E)
            ):
                lam = False
            wd = 0 if (coeng_hit or leak_hit) else W[c]
            if coeng_hit or leak_hit:
                lam = False
            elif lam and c in S["alef"]:
                wd, lam = 0, False
            elif c in S["lam"] or (lam and c in S["lamt"]):
                lam = True
            else:
                lam = False
            tot += wd
            last, lastw = c, wd
            emoji = tag_end or c in S["ejoin"]
            i += 1
        return tot


class _Widths:
    """`W[cp]` for the code points of a width table."""

    def __init__(self, ranges):
        self.ranges = ranges
        self.starts = [a for a, _, _ in ranges]

    def __getitem__(self, cp):
        i = bisect.bisect_right(self.starts, cp) - 1
        if i >= 0 and self.ranges[i][0] <= cp <= self.ranges[i][1]:
            return self.ranges[i][2]
        return 1


def load_tables(path):
    """Reads `W` and the character sets `S` back from a generated `char_width_data.mbt`
    (the same data `Model` gets while the script measures)."""
    src = open(path, encoding="utf-8").read()

    def numbers(name):
        body = re.search(r"let %s : FixedArray\[Int32\] = \[(.*?)\]" % name, src, re.S).group(1)
        return [int(x, 0) for x in re.findall(r"0x[0-9a-f]+|\d+", body)]

    flat = numbers("char_width_ranges")
    W = _Widths(list(zip(flat[0::3], flat[1::3], flat[2::3])))
    S = {}
    for key in ("vs16", "vs15", "ejoin", "emb", "lam", "alef", "lamt", "vs16w", "hebt", "coeng"):
        flat = numbers("char_set_" + key)
        S[key] = {c for a, b in zip(flat[0::2], flat[1::2]) for c in range(a, b + 1)}
    S["lq"] = {0x2018, 0x2019, 0x201C, 0x201D}
    S["ri"] = set(range(0x1F1E6, 0x1F200))
    S["mod"] = set(range(0x1F3FB, 0x1F400))
    return W, S


FUZZ_POOLS = {
    "mixed": [
        0x41, 0x31, 0x23, 0x20, 0x3042, 0x1F600, 0x1F44D, 0x1F3FD, 0x261D, 0x2764, 0x263A,
        0x231A, 0x1F1E8, 0x1F1F3, 0x200D, 0xFE0F, 0xFE0E, 0x20E3, 0x301, 0x94D, 0x915,
        0x937, 0x93F, 0x1100, 0x1161, 0x11A8, 0xAC00, 0xAC01, 0x644, 0x622, 0x627, 0x64E,
        0x5D0, 0x5DC, 0x5B9, 0x1F3F4, 0xE0067, 0xE007F, 0x200B, 0x200C, 0x2060, 0x17D8,
        0x2E3B, 0xFFE5, 0xFF71, 0x20000, 0x1F680, 0x1F469, 0x1F525, 0x2642, 0x2640, 0x1F3FB,
        0x270C, 0xA9, 0x1F3CB, 0x9BE, 0xAD, 0x605, 0x61C, 0x34F, 0xFE00, 0xFE01, 0x2018,
        0x1F3F3, 0x1F308, 0x5B4, 0x5BF, 0x591, 0xE0020, 0xE0041, 0x1F1E6, 0x1F1FF, 0x1F3FF,
    ],
    "emoji": [
        0x1F600, 0x1F469, 0x1F44D, 0x1F3FD, 0x261D, 0x2764, 0xFE0F, 0xFE0E, 0x200D, 0x1F1E8,
        0x1F1F3, 0x20E3, 0x31, 0x23, 0x1F550, 0x231A, 0x1F3F4, 0xE0067, 0x41, 0x3042, 0xA9,
        0x1F3CB,
    ],
    "hebrew": [0x5D0, 0x5DC, 0x200D, 0x5B9, 0x5B4, 0x591, 0x5D1, 0x41, 0x1F600, 0x300, 0xFE0F, 0x200C],
    "khmer": [0x1780, 0x1781, 0x17D2, 0x17C2, 0x179A, 0x200D, 0x200C, 0x17B6, 0x41, 0x17D8, 0xFE0F, 0x1F600, 0x300],
    "leak": [0x26F5, 0x2018, 0xFE01, 0xFE0E, 0xFE0F, 0x627, 0x1780, 0x17D2, 0x5DC, 0x41, 0x644, 0x1786, 0x200D, 0x1F22F, 0x1F600],
    "tags": [
        0x1F3F4, 0xE0067, 0xE0062, 0xE0030, 0xE0039, 0xE0061, 0xE007A, 0xE007F, 0xE0020, 0xE007E, 0x200D,
        0x1F600, 0x41, 0x1F1E8, 0x1F1F3, 0xFE0F, 0x263A, 0x1F44D, 0x1F3FD, 0x31, 0x20E3, 0x3042,
    ],
    "vspair": [
        0x17D2, 0x1780, 0x1781, 0xFE0E, 0xFE01, 0xFE0F, 0xFE00, 0x200D, 0x5D0, 0x5DC, 0x644, 0x627, 0x2018,
        0x26F5, 0x41, 0x34F, 0x1F600, 0x180B, 0xE0100,
    ],
    "hangul": [
        0x1100, 0x1161, 0x11A8, 0xAC00, 0xAC01, 0x1160, 0xA960, 0xD7B0, 0xD7CB, 0x41, 0x300,
        0x200D, 0x115F, 0x3164, 0xFFA0, 0x302E,
    ],
    "arabic": [
        0x644, 0x627, 0x622, 0x64E, 0xFE0F, 0xFE00, 0x200D, 0x61C, 0x41, 0x6B8, 0x87D, 0x2062,
        0x300, 0x1F600,
    ],
}


def fuzz(W, S, n, seed):
    model = Model(W, S)
    rnd = random.Random(seed)
    extra = [x for k in ("vs16", "vs15", "ejoin", "emb", "lam", "alef", "lamt") for x in rnd.sample(S[k], 6)]
    total_bad = 0
    for mode, pool in FUZZ_POOLS.items():
        pool = pool + extra
        bad = {}
        for _ in range(n):
            s = "".join(chr(rnd.choice(pool)) for _ in range(rnd.randint(1, 10)))
            a, b = model.width(s), width(s)
            if a != b:
                bad[s] = (a, b)
        print(f"fuzz {mode}: {n} sequences, {len(bad)} differ")
        for s, (a, b) in sorted(bad.items(), key=lambda kv: len(kv[0]))[:8]:
            print("   ", " ".join(f"{ord(c):X}" for c in s), "model", a, "polars", b)
        total_bad += len(bad)
    return total_bad


# --- MoonBit output ------------------------------------------------------------


def emit(W, S, path):
    # width table: ranges of code points whose width is not 1
    wr = []
    for cp in range(MAX_CP):
        v = W[cp]
        if v < 0 or v == 1:
            continue
        if wr and wr[-1][1] == cp - 1 and wr[-1][2] == v:
            wr[-1][1] = cp
        else:
            wr.append([cp, cp, v])
    fast = wr[0][0]  # every code point below this is one column wide
    # `cp_width` short-cuts these blocks (src/pl/char_width.mbt); they must be 2 wide
    for a, b in [(0x4E00, 0x9FFF), (0xAC00, 0xD7A3), (0x3041, 0x3096), (0x30A1, 0x30FA), (0x3400, 0x4DBF)]:
        assert all(W[cp] == 2 for cp in range(a, b + 1)), f"shortcut block {a:X}-{b:X} is not all 2 wide"
    lines = [
        "// Generated by docs/golden/scripts/char_width.py from polars 2.1.0's own",
        "// table output. Do not edit by hand; run the script again instead.",
        "//",
        "// `char_width_ranges`: inclusive code point ranges and their width (every code",
        "// point that is not listed is one column wide, except U+D800-U+DFFF which are",
        "// not characters). The other tables are the character sets the sequence rules",
        "// of `str_width` use; see the script for how each is derived. Ranges are stored",
        "// flat, as `first, last` (and `width` for the width table), in ascending order.",
        "",
        "///|",
        "/// Every code point below this is one column wide.",
        f"let char_width_fast_limit : Int32 = 0x{fast:x}",
        "",
        "///|",
        "/// `first, last, width` of each range of code points that is not one column wide.",
        "let char_width_ranges : FixedArray[Int32] = [",
    ]
    for a, b, v in wr:
        lines.append(f"  0x{a:x}, 0x{b:x}, {v},")
    lines.append("]")
    docs = {
        "vs16": "One column wide, two columns wide when directly followed by U+FE0F.",
        "vs15": "Two columns wide, one column wide when directly followed by U+FE0E.",
        "ejoin": "Emoji presentation characters: zero wide after an emoji and a ZWJ.",
        "emb": "Emoji modifier bases: zero-width modifier after them (the base becomes two columns).",
        "lam": "Arabic lam letters that form a ligature with a following alef.",
        "alef": "Arabic alef letters that vanish after a lam.",
        "lamt": "Zero-width marks that do not break a lam ... alef ligature.",
        "vs16w": "Two columns wide and taking U+FE0F in an emoji presentation sequence (a ZWJ may follow).",
        "hebt": "Zero-width marks that do not break the alef ZWJ lamed ligature (nor COENG + letter).",
        "coeng": "Khmer letters that are zero wide right after COENG (U+17D2).",
    }
    for key, doc in docs.items():
        lines += ["", "///|", f"/// {doc} `first, last` of each range.", f"let char_set_{key} : FixedArray[Int32] = ["]
        for a, b in ranges(S[key]):
            lines.append(f"  0x{a:x}, 0x{b:x},")
        lines.append("]")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    return len(wr)


def emit_edges(W, path):
    """A white-box test table: the code points around every edge of the width table, as polars
    measured them. For each range of `char_width_ranges` its first and last code point and the
    code points just before and after; the same for the five blocks `cp_width` short-cuts; the
    ends of the code space. `char_width_wbtest.mbt` checks every one of them against `cp_width`
    and `str_width`, so a wrong edge of the table (a hand edit, a different polars) fails."""
    edges = set()
    cur = None
    for cp in range(MAX_CP):
        v = W[cp]
        if v >= 0 and v != 1:
            if cur is None or cur[2] != v or cur[1] != cp - 1:
                if cur is not None:
                    edges.update((cur[0] - 1, cur[0], cur[1], cur[1] + 1))
                cur = [cp, cp, v]
            else:
                cur[1] = cp
    edges.update((cur[0] - 1, cur[0], cur[1], cur[1] + 1))
    for a, b in [(0x4E00, 0x9FFF), (0xAC00, 0xD7A3), (0x3041, 0x3096), (0x30A1, 0x30FA), (0x3400, 0x4DBF)]:
        edges.update((a - 1, a, b, b + 1))
    edges.update((0, 0x7F, 0x80, 0xAC, 0xAD, 0xAE, 0x10FFFE, 0x10FFFF))
    pts = sorted(cp for cp in edges if 0 <= cp < MAX_CP and W[cp] >= 0)
    lines = [
        "// Generated by docs/golden/scripts/char_width.py from polars 2.1.0's own table output.",
        "// Do not edit by hand; run the script again instead.",
        "//",
        "// `char_width_edges`: `code point, width` for the code points around every edge of the",
        "// width table (first, last, the one before the first and the one after the last of each",
        "// range, and of the blocks `cp_width` short-cuts), as polars measured them.",
        "",
        "///|",
        "let char_width_edges : FixedArray[Int32] = [",
    ]
    for cp in pts:
        lines.append(f"  0x{cp:x}, {W[cp]},")
    lines.append("]")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    return len(pts)


def main():
    procs = min(8, os.cpu_count() or 1)
    if len(sys.argv) > 1 and sys.argv[1] == "--fuzz":
        n = int(sys.argv[2]) if len(sys.argv) > 2 else 100000
        seed = int(sys.argv[3]) if len(sys.argv) > 3 else 1
        W = probe_all(width, procs)
        for cp in range(MAX_CP):
            if cp == NEWLINE:
                W[cp] = 1
        S = derive_sets(W, procs)
        bad = fuzz(W, S, n, seed)
        sys.exit(1 if bad else 0)
    W = probe_all(width, procs)
    W[NEWLINE] = 1
    measured = sum(1 for cp in range(MAX_CP) if W[cp] >= 0 and cp != NEWLINE)
    checked, bad = cross_check(W, procs)
    print(f"polars {pl.__version__}: measured {measured} code points; cross-check {checked} compared, {bad} differ")
    assert bad == 0
    S = derive_sets(W, procs)
    count = emit(W, S, OUT_PATH)
    print(f"wrote {OUT_PATH}: {count} width ranges; " + ", ".join(f"{k} {len(v)}" for k, v in S.items()))
    n = emit_edges(W, EDGES_PATH)
    print(f"wrote {EDGES_PATH}: {n} code points")


if __name__ == "__main__":
    main()
