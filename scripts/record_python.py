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
import os
import sys
from pathlib import Path
from typing import Any, Callable


SECRET_NAME_PARTS = (
    "SECRET",
    "TOKEN",
    "PASSWORD",
    "PASSWD",
    "PASSPHRASE",
    "CREDENTIAL",
    "API_KEY",
    "PRIVATE_KEY",
)
MIN_SECRET_CHARS = 8


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


def serialize_value(val: Any) -> Any:
    """Normalize values for JSON serialization.

    pathlib.Path objects are serialized as path strings, not as raw objects or JSON reprs.
    """
    if isinstance(val, Path):
        return str(val)
    if isinstance(val, dict):
        return {k: serialize_value(v) for k, v in val.items()}
    if isinstance(val, (list, tuple)):
        return [serialize_value(v) for v in val]
    return val


def required_param_count(fn: Callable) -> int:
    """How many leading positional parameters of `fn` have no default."""
    try:
        params = inspect.signature(fn).parameters.values()
    except (TypeError, ValueError):
        return 0
    count = 0
    for p in params:
        if p.kind not in (inspect.Parameter.POSITIONAL_ONLY, inspect.Parameter.POSITIONAL_OR_KEYWORD):
            break
        if p.default is not inspect.Parameter.empty:
            break
        count += 1
    return count


def call_args(fn: Callable, args: list[Any]) -> list[Any]:
    """Prepare arguments for call: trailing undefined arguments are omitted so defaults apply.

    A parameter without a default always receives its argument (e.g. None if undefined),
    never leaving it out to prevent missing positional argument TypeErrors.
    """
    args = list(args)
    keep = required_param_count(fn)
    while len(args) > keep and args and args[-1] == {"$undefined": True}:
        args.pop()
    return [None if a == {"$undefined": True} else a for a in args]


def call_case(fn: Callable, args: list[Any]) -> dict[str, Any]:
    effective_args = call_args(fn, args)
    row: dict[str, Any] = {"fn": fn.__name__, "args": serialize_value(effective_args)}
    try:
        res = fn(*effective_args)
        row["ok"] = serialize_value(res)
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
        try:
            sig = inspect.signature(fn)
            params = [
                p
                for p in sig.parameters.values()
                if p.kind
                in (inspect.Parameter.POSITIONAL_ONLY, inspect.Parameter.POSITIONAL_OR_KEYWORD)
            ]
        except (TypeError, ValueError):
            params = []

        req_count = required_param_count(fn)
        if len(params) == 0:
            cases.append(call_case(fn, []))
        else:
            include_defaults = (i % 2 == 1) or (req_count == len(params))
            active_params = params if include_defaults else params[:req_count]
            args = []
            for j, p in enumerate(active_params):
                edge = EDGE_STRINGS[(i + j) % len(EDGE_STRINGS)]
                if p.default is inspect.Parameter.empty and j >= 1 and (i + j) % 5 == 0:
                    args.append(None)
                else:
                    args.append(edge)
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


def find_recorded_secrets(
    cases: list[dict[str, Any]], env: dict[str, str] | None = None
) -> list[tuple[str, list[str]]]:
    """Find environment variables whose secret value appears in recorded cases.

    Returns a list of (var_name, [fn_names]) without exposing the secret value.
    """
    if env is None:
        env = dict(os.environ)

    def value_in_obj(obj: Any, secret: str) -> bool:
        if isinstance(obj, str):
            return secret in obj
        if isinstance(obj, dict):
            return any(secret in str(k) or value_in_obj(v, secret) for k, v in obj.items())
        if isinstance(obj, (list, tuple, set)):
            return any(value_in_obj(v, secret) for v in obj)
        return False

    matches: list[tuple[str, list[str]]] = []
    for name, val in env.items():
        if len(val) < MIN_SECRET_CHARS:
            continue
        upper = name.upper()
        if not any(part in upper for part in SECRET_NAME_PARTS):
            continue
        fns_with_secret: list[str] = []
        for c in cases:
            fn_name = str(c.get("fn", "?"))
            if value_in_obj(c, val):
                if fn_name not in fns_with_secret:
                    fns_with_secret.append(fn_name)
        if fns_with_secret:
            matches.append((name, fns_with_secret))
    matches.sort(key=lambda item: item[0])
    return matches


def remove_or_empty(path: Path) -> None:
    try:
        path.unlink(missing_ok=True)
    except Exception:
        try:
            path.write_text("", encoding="utf-8")
        except Exception:
            pass


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
    secrets = find_recorded_secrets(cases)
    if secrets:
        remove_or_empty(out)
        details = ", ".join(f"{name} in {', '.join(fns)}" for name, fns in secrets)
        raise SystemExit(
            f"record refused: cases hold secret from environment variable {details}. "
            "Record with env -u NAME or change inputs."
        )

    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8") as fh:
        for row in cases:
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")
    case_noun = "case" if len(cases) == 1 else "cases"
    print(f"wrote {len(cases)} {case_noun} to {out}", file=sys.stderr)


if __name__ == "__main__":
    main()
