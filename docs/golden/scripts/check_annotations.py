"""Checks the golden data under docs/golden.

1. Annotations (default, plain Python 3, no polars needed). Every case of every
   `docs/golden/*.json` must carry a non-empty `polars` field naming the polars
   call it was generated from (spec section 7, "test comments"). A case is any
   JSON object with an `id` key, wherever it sits in the document. Every
   element of a case list (`cases`, `frame_cases`, `sort`, `unique`, or the
   top-level list of cast.json and show.json) must have an `id` too. Exit
   status 1 when a case lacks the field or an id, or a file has no case.

       python3 docs/golden/scripts/check_annotations.py

2. Reproducibility (`--repro`, needs polars). Every generator script is run
   twice in a scratch copy of `docs/golden` and `src/pl`, and the sha256 of each
   file it writes is compared between the two runs (and with the committed
   file). The scratch directory must not exist yet; delete it afterwards.

       /data/lly-moonbit/polars-venv/bin/python docs/golden/scripts/check_annotations.py \\
           --repro /data/lly-moonbit/m2/t12-repro [--ucd UCD_DIR]

   `grapheme.py` needs the Unicode 17.0.0 files (see its docstring); it is
   skipped unless `--ucd UCD_DIR` is given. Some scripts (`case_tables.py`,
   `char_width.py`, `grapheme.py`, the `*_cases_test.mbt` files) write
   unformatted MoonBit that was run through `moon fmt` before it was committed.
   With `--moonfmt PATH` (default: `moonfmt` on PATH, e.g.
   `/data/lly-moonbit/moon/bin/moonfmt`) the "committed" column also accepts a
   file whose formatted text equals the committed one.
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
GOLDEN = os.path.join(ROOT, "docs", "golden")
NOT_GENERATORS = {"emit.py", "check_annotations.py"}


def walk_cases(node):
    """Every dict that has an `id` key, at any depth."""
    if isinstance(node, dict):
        if "id" in node:
            yield node
        for v in node.values():
            yield from walk_cases(v)
    elif isinstance(node, list):
        for v in node:
            yield from walk_cases(v)


# Keys whose value is a list of cases (besides the top-level list of cast.json
# and show.json). Every element of such a list must be an object with an `id`.
CASE_LISTS = ("cases", "frame_cases", "sort", "unique")


def case_lists(doc):
    if isinstance(doc, list):
        yield doc
    elif isinstance(doc, dict):
        for key in CASE_LISTS:
            if isinstance(doc.get(key), list):
                yield doc[key]


def check_annotations():
    bad = False
    total = 0
    print(f"{'file':<24}{'cases':>8}{'annotated':>11}  status")
    for name in sorted(os.listdir(GOLDEN)):
        if not name.endswith(".json"):
            continue
        with open(os.path.join(GOLDEN, name), encoding="utf-8") as f:
            doc = json.load(f)
        cases = list(walk_cases(doc))
        missing = [
            c["id"]
            for c in cases
            if not (isinstance(c.get("polars"), str) and c["polars"].strip())
        ]
        no_id = sum(
            1
            for lst in case_lists(doc)
            for c in lst
            if not (isinstance(c, dict) and "id" in c)
        )
        if no_id:
            missing += [f"<{no_id} case(s) without an id>"]
        total += len(cases)
        ok = bool(cases) and not missing
        bad = bad or not ok
        status = "ok" if ok else f"FAIL ({len(missing)} missing, e.g. {missing[:3]})"
        if not cases:
            status = "FAIL (no cases found)"
        print(f"{name:<24}{len(cases):>8}{len(cases) - len(missing):>11}  {status}")
    print(f"total cases: {total}")
    print("annotations: " + ("FAIL" if bad else "OK"))
    return not bad


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def formatted_sha(moonfmt, path):
    """sha256 of the file's text after `moonfmt` (None when unavailable)."""
    if not moonfmt:
        return None
    proc = subprocess.run([moonfmt, path], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    if proc.returncode != 0:
        return None
    return hashlib.sha256(proc.stdout).hexdigest()


def tracked_files(root):
    """Files a generator may write: docs/golden/*.json (and known-diffs are not
    written by scripts) and src/pl/*.mbt."""
    out = []
    for sub, ext in (("docs/golden", ".json"), ("src/pl", ".mbt")):
        d = os.path.join(root, sub)
        for name in sorted(os.listdir(d)):
            if name.endswith(ext) and os.path.isfile(os.path.join(d, name)):
                out.append(os.path.join(sub, name))
    return out


def run_once(scratch, python, script, extra):
    """Runs a script in the scratch tree; returns ({relative path: sha256} of
    the files it wrote, return code). Written files are found by mtime: every
    tracked file is set to the epoch before the run."""
    for rel in tracked_files(scratch):
        os.utime(os.path.join(scratch, rel), ns=(0, 0))
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
    proc = subprocess.run(
        [python, os.path.join("docs", "golden", "scripts", script)] + extra,
        cwd=scratch,
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    written = {}
    for rel in tracked_files(scratch):
        if os.stat(os.path.join(scratch, rel)).st_mtime_ns > 0:
            written[rel] = sha256(os.path.join(scratch, rel))
    return written, proc.returncode


def check_repro(scratch, python, ucd, moonfmt):
    if os.path.exists(scratch):
        sys.exit(f"{scratch} already exists; pass a new directory")
    os.makedirs(scratch)
    for sub in ("docs/golden", "src/pl"):
        shutil.copytree(
            os.path.join(ROOT, sub),
            os.path.join(scratch, sub),
            ignore=shutil.ignore_patterns("__pycache__", "_build", ".mooncakes"),
        )
    scripts = sorted(
        n for n in os.listdir(HERE) if n.endswith(".py") and n not in NOT_GENERATORS
    )
    rows = []
    differing = []
    for script in scripts:
        extra = []
        if script == "grapheme.py":
            if ucd is None:
                rows.append((script, "-", "-", "-", "skipped (needs --ucd UCD_DIR)"))
                continue
            extra = [ucd]
        first, rc1 = run_once(scratch, python, script, extra)
        second, rc2 = run_once(scratch, python, script, extra)
        if rc1 != 0 or rc2 != 0 or not first:
            rows.append((script, "-", "-", "-", f"FAILED (exit {rc1}/{rc2}, wrote {len(first)} files)"))
            differing.append(script)
            continue
        for rel in sorted(set(first) | set(second)):
            a, b = first.get(rel), second.get(rel)
            committed = os.path.join(ROOT, rel)
            same_as_committed = os.path.exists(committed) and sha256(committed) == a
            formatted = False
            if not same_as_committed and os.path.exists(committed) and rel.endswith(".mbt"):
                formatted = formatted_sha(moonfmt, os.path.join(scratch, rel)) == sha256(committed)
            rows.append(
                (
                    script,
                    rel,
                    (a or "-"),
                    (b or "-"),
                    ("SAME" if a == b else "DIFFERENT")
                    + (
                        ", = committed"
                        if same_as_committed
                        else ", = committed after moonfmt" if formatted else ", != committed"
                    ),
                )
            )
            if a != b:
                differing.append(f"{script}:{rel}")
    print("script | file | sha256 run 1 | sha256 run 2 | result")
    print("--- | --- | --- | --- | ---")
    for r in rows:
        print(" | ".join(r))
    print("different or failed: " + (", ".join(differing) if differing else "none"))
    return not differing


def main():
    args = sys.argv[1:]
    if "--repro" in args:
        i = args.index("--repro")
        scratch = os.path.abspath(args[i + 1])
        ucd = None
        if "--ucd" in args:
            ucd = os.path.abspath(args[args.index("--ucd") + 1])
        moonfmt = shutil.which("moonfmt")
        if "--moonfmt" in args:
            moonfmt = os.path.abspath(args[args.index("--moonfmt") + 1])
        ok = check_repro(scratch, sys.executable, ucd, moonfmt)
        sys.exit(0 if ok else 1)
    sys.exit(0 if check_annotations() else 1)


if __name__ == "__main__":
    main()
