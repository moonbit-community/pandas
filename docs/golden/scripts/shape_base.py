"""The base of `window.py` and `group_by_ext.py`: the part of `expr_shape.py`
before its first case (which is itself built on `expr_seq.py`, `expr_agg.py`
and `expr.py`), plus two nodes:

  ("len",)                 `pl.len()`
  ("over", x, [keys])      `x.over([keys])`

`W` is the namespace of the executed part of `expr_shape.py`: tables,
expression trees, renderers and the `case` function of `expr_shape.py`.
Importing this module changes nothing on disk.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

_path = os.path.join(HERE, "expr_shape.py")
_src = open(_path, encoding="utf-8").read()
_prefix = _src[: _src.index('DTS = ["i32", "i64", "f32"')]
W = {"__name__": "expr_shape_prefix", "__file__": _path}
exec(compile(_prefix, _path, "exec"), W)

pl = W["pl"]
N = W["N"]
_prev = {k: W[k] for k in ("to_pl", "to_py", "to_mb", "strengthen")}


def to_pl(n):
    if n[0] == "len":
        return pl.len()
    if n[0] == "over":
        return to_pl(n[1]).over([to_pl(k) for k in n[2]])
    return _prev["to_pl"](n)


def to_py(n):
    if n[0] == "len":
        return "pl.len()"
    if n[0] == "over":
        return f"{to_py(n[1])}.over([{', '.join(to_py(k) for k in n[2])}])"
    return _prev["to_py"](n)


def to_mb(n):
    if n[0] == "len":
        return "@pl.len()"
    if n[0] == "over":
        return f"{to_mb(n[1])}.over([{', '.join(to_mb(k) for k in n[2])}])"
    return _prev["to_mb"](n)


def strengthen(n, keep_weak=False):
    if n[0] == "over":
        return N(("over", strengthen(n[1]), [strengthen(k) for k in n[2]]))
    return _prev["strengthen"](n, keep_weak)


for _d in (W, W["_ns"], W["A"], W["S"]):
    _d["to_pl"], _d["to_py"], _d["to_mb"] = to_pl, to_py, to_mb
    _d["strengthen"] = strengthen

len_ = N(("len",))
over = lambda x, keys: N(("over", x, list(keys)))


def gen_div_exprs(seed, count, columns, aggregate_columns=None, wrap=True):
    """`count` seeded random arithmetic expressions with at least one `/`, `//` or
    `%`, built of the columns `columns`, aggregations of `aggregate_columns` (the
    same list by default), `pl.len()` and literals; the divisors are aggregated
    values, columns or a mix. With `wrap` an expression that still reads a column
    is closed by `first`, `last`, `sum` or `mean` (the shape `agg` needs); returns
    `(expression, reads_a_column)` pairs.

    Only the operations whose result is `+-0.0` free are drawn for the closing
    aggregation, so no case depends on the order of `+0.0` and `-0.0`."""
    import random

    rng = random.Random(seed)
    aggcols = list(aggregate_columns or columns)
    col_, agg_, bin__ = W["col"], W["agg"], W["bin_"]
    li_, lf_ = W["li"], W["lf"]

    def leaf():
        r = rng.random()
        if r < 0.4:
            return col_(rng.choice(columns)), True
        if r < 0.85:
            if rng.random() < 0.1:
                return len_, False
            return agg_(rng.choice(["sum", "max", "min", "first", "last", "mean"]),
                        col_(rng.choice(aggcols))), False
        return (lf_(rng.choice([0.5, 2.5, 3.0])) if rng.random() < 0.5 else li_(rng.choice([2, 3, 7]))), False

    def gen(depth):
        if depth == 0 or rng.random() < 0.2:
            return leaf()
        op = rng.choices(["div", "floordiv", "mod", "mul", "add", "sub"], [4, 3, 3, 2, 1, 1])[0]
        a, ca = gen(depth - 1)
        b, cb = gen(depth - 1)
        return bin__(op, a, b), ca or cb

    def has_div(n):
        if n[0] == "bin":
            return n[1] in ("div", "floordiv", "mod") or has_div(n[2]) or has_div(n[3])
        return False

    out = []
    while len(out) < count:
        e, reads = gen(rng.choice([1, 2, 2, 3]))
        if not has_div(e):
            continue
        if wrap and reads:
            e = agg_(rng.choice(["first", "last", "sum", "mean"]), e)
        out.append((e, reads))
    return out


W["gen_div_exprs"] = gen_div_exprs
