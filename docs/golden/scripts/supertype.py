"""Golden data for `supertype`: the dtype polars gives two columns of the
nine supported types when it has to unify them.

Run from the repository root (needs polars 2.1.0):

    python docs/golden/scripts/supertype.py

Writes `docs/golden/supertype.json` and `src/pl/golden_supertype_data_wbtest.mbt`
(a white-box test file: `supertype` is private).

There is one case per ordered pair of types (81). polars unifies two empty
frames with `pl.concat(..., how="vertical_relaxed")`; `result` is the display
name of the dtype, or `null` when polars raises (`error`, `message` then
hold the variant and the first message line). A case with `"restricted": true`
is a pair where the library deliberately has no supertype although polars has
one: `String` with a number (polars says `str`, but the library rejects both
comparison and arithmetic of that pair). `result` is polars' answer; the
library has no supertype there.
"""
import os
import warnings

warnings.simplefilter("ignore")

import polars as pl

from emit import DTYPE_NAMES, _compact_text, _repo_root, dtype_name

NAMES = list(DTYPE_NAMES)
NUMBERS = ("i32", "i64", "f32", "f64")


def frame(name):
    return pl.DataFrame(schema={"a": DTYPE_NAMES[name]})


def cases():
    out = []
    for a in NAMES:
        for b in NAMES:
            rec = {
                "id": f"supertype/{a}/{b}",
                "a": a,
                "b": b,
                "polars": f'pl.concat([pl.DataFrame(schema={{"a": {DTYPE_NAMES[a]!r}}}), pl.DataFrame(schema={{"a": {DTYPE_NAMES[b]!r}}})], how="vertical_relaxed").schema["a"]',
                "result": None,
            }
            try:
                df = pl.concat([frame(a), frame(b)], how="vertical_relaxed")
                rec["result"] = dtype_name(df.schema["a"])
            except Exception as e:  # noqa: BLE001
                rec["error"] = type(e).__name__
                rec["message"] = str(e).split("\n")[0]
            if rec["result"] == "str" and (
                (a == "str" and b in NUMBERS) or (b == "str" and a in NUMBERS)
            ):
                rec["restricted"] = True
            out.append(rec)
    return out


def main():
    cs = cases()
    root = _repo_root()
    text = _compact_text({"cases": cs})
    with open(os.path.join(root, "docs", "golden", "supertype.json"), "w", encoding="utf-8") as f:
        f.write(text + "\n")
    lines = ["// 由 docs/golden/scripts/supertype.py 生成，勿手改", "", "///|", "let golden_supertype : String ="]
    lines += ["  #|" + line for line in text.split("\n")]
    with open(os.path.join(root, "src", "pl", "golden_supertype_data_wbtest.mbt"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"polars {pl.__version__}: wrote {len(cs)} cases ({sum(1 for c in cs if c['result'] is None)} errors)")


main()
