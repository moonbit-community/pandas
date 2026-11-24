"""Golden data for `DataFrame::new`: the errors of `pl.DataFrame([series, ...])`.

Run from the repository root (needs polars 2.1.0):

    python docs/golden/scripts/df_new.py

Writes `docs/golden/df_new.json` and `src/pl/golden_df_new_data_test.mbt`.
Every case is a list of columns `[name, height]` (an `Int32` series
`0..height`), built in this order. The expected result is the shape of the
frame, or the error variant and polars' first message line (`DuplicateError` is
`DuplicateColumn`, `ShapeError` is `ShapeMismatch`).

Cases: every list of 0 to 3 columns over the names `a`, `b` and the heights 0, 1,
2, plus 200 seeded random lists of 4 columns (same names and heights) and 200
each of 5 and 6 columns over the names `a`..`e` and the heights 1..3. With at most four columns polars checks each
column in turn (its height against the first column, then whether a later
column repeats its name); with more it checks height and then repeated name
column by column.
"""
import itertools
import random
import warnings

warnings.simplefilter("ignore")

import polars as pl

from emit import emit

VARIANTS = {"DuplicateError": "DuplicateColumn", "ShapeError": "ShapeMismatch"}


def series(name, height):
    return pl.Series(name, list(range(height)), dtype=pl.Int32)


def spelling(cols):
    return "pl.DataFrame([pl.Series(n, range(h), dtype=pl.Int32) for n, h in cols])"


def case(cols):
    cid = "new/" + ",".join(f"{n}{h}" for n, h in cols)
    rec = {"id": cid, "polars": spelling(cols), "cols": [[n, h] for n, h in cols]}
    try:
        df = pl.DataFrame([series(n, h) for n, h in cols])
        rec["shape"] = [df.height, df.width]
    except Exception as e:  # noqa: BLE001
        name = type(e).__name__
        if name not in VARIANTS:
            raise
        rec["error"] = VARIANTS[name]
        rec["message"] = str(e).split("\n")[0]
    return rec


lists = [[]]
for k in (1, 2, 3):
    for names in itertools.product("ab", repeat=k):
        for hs in itertools.product((0, 1, 2), repeat=k):
            lists.append(list(zip(names, hs)))
lists += [[(n, h) for n in "abcdef"[:k]] for k in (3, 5, 6) for h in (0, 1, 3)]
rng = random.Random(7)
for _ in range(200):
    lists.append([(rng.choice("ab"), rng.choice((0, 1, 2))) for _ in range(4)])
for k in (5, 6):
    for _ in range(200):
        lists.append([(rng.choice("abcde"), rng.choice((1, 2, 3))) for _ in range(k)])
# the same list can be drawn twice: keep the first
seen = set()
cases = []
for cols in lists:
    key = tuple(cols)
    if key in seen:
        continue
    seen.add(key)
    cases.append(case(cols))
emit("df_new", {"cases": cases}, compact=True)
errors = sum(1 for c in cases if "error" in c)
print(f"{len(cases)} cases, {errors} errors")
