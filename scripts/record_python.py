#!/usr/bin/env python3
"""Run original Python functions for pascal-anything record.

Usage:
  record_python.py --root <repo> --unit <relpath> --out cases.jsonl [--inputs extra.jsonl] [--count N]

Each output line: {"fn": name, "args": [...], "ok": value} or {"fn", "args", "err": message}.
"""
from __future__ import annotations

import argparse
import importlib.util
import inspect
import json
import sys
from pathlib import Path
from typing import Any, Callable


EDGE_STRINGS = [
    "",
    " ",
    "a",
    "Hello, World!",
    "café",
    "😀",
    "TAB\tline",
    "already-ok",
    "  padded  ",
]


def load_module(root: Path, unit: str):
    path = (root / unit).resolve()
    if not path.is_file():
        raise SystemExit(f"unit not found: {path}")
    sys.path.insert(0, str(path.parent))
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"cannot load {path}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def public_functions(mod) -> dict[str, Callable]:
    out: dict[str, Callable] = {}
    for name, obj in inspect.getmembers(mod, inspect.isfunction):
        if name.startswith("_"):
            continue
        if getattr(obj, "__module__", None) != mod.__name__:
            continue
        out[name] = obj
    return out


def call_case(fn: Callable, args: list[Any]) -> dict[str, Any]:
    row: dict[str, Any] = {"fn": fn.__name__, "args": args}
    try:
        row["ok"] = fn(*args)
    except Exception as exc:  # noqa: BLE001 — characterization
        row["err"] = f"{type(exc).__name__}: {exc}"
    return row


def generate_cases(fns: dict[str, Callable], count: int) -> list[dict[str, Any]]:
    cases: list[dict[str, Any]] = []
    names = list(fns.keys())
    if not names:
        return cases
    i = 0
    while len(cases) < count:
        name = names[i % len(names)]
        fn = fns[name]
        sig = inspect.signature(fn)
        params = [
            p
            for p in sig.parameters.values()
            if p.kind
            in (inspect.Parameter.POSITIONAL_ONLY, inspect.Parameter.POSITIONAL_OR_KEYWORD)
        ]
        if len(params) == 0:
            cases.append(call_case(fn, []))
        elif len(params) == 1:
            cases.append(call_case(fn, [EDGE_STRINGS[i % len(EDGE_STRINGS)]]))
        else:
            args = []
            for j, _p in enumerate(params):
                args.append(EDGE_STRINGS[(i + j) % len(EDGE_STRINGS)])
            cases.append(call_case(fn, args))
        i += 1
    return cases


def load_inputs(path: Path, fns: dict[str, Callable]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        data = json.loads(line)
        name = data["fn"]
        args = data.get("args", [])
        if name not in fns:
            rows.append({"fn": name, "args": args, "err": "unknown function"})
            continue
        rows.append(call_case(fns[name], args))
    return rows


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    ap.add_argument("--unit", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--inputs")
    ap.add_argument("--count", type=int, default=50)
    args = ap.parse_args()

    root = Path(args.root)
    mod = load_module(root, args.unit)
    fns = public_functions(mod)
    if not fns:
        raise SystemExit(f"no public functions in {args.unit}")

    cases: list[dict[str, Any]] = []
    if args.inputs:
        cases.extend(load_inputs(Path(args.inputs), fns))
    else:
        cases.extend(generate_cases(fns, args.count))

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8") as fh:
        for row in cases:
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(f"wrote {len(cases)} cases to {out}", file=sys.stderr)


if __name__ == "__main__":
    main()
