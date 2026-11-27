---
name: pascal-anything
description: Port TypeScript/JavaScript, Python, C, Go, Ruby, Java, PHP, Rust and more to Free Pascal/Lazarus with the pascal-anything CLI, from one hot function up to a whole app rewritten as a Pascal/Lazarus app - analyze, bridge one unit at a time, record the original's behavior, port, diff and gate. Use when asked to rewrite, port or migrate code or an app to Pascal, Free Pascal, Lazarus or Object Pascal.
---

# Migration to Free Pascal / Lazarus with pascal-anything

pascal-anything gives you ground truth; you write the Pascal. Port one unit at a time, even when the
goal is the whole app, and call a port done only when `gate` passes.

**Whole app to a pure Pascal/Lazarus app** (the user wants the app rewritten in Pascal, with the
original kept only as reference): read [whole-app.md](whole-app.md) first and follow it.

Languages detected: TypeScript/JavaScript, Python, Go, Rust, PHP, Ruby, Java, Pascal. Override with
`--lang`. The steps are the same everywhere; the bridge scaffolds an FPC package under
`pascal/<name>_pas/` with `src/port.pas` stubs and a `harness.lpr` for replaying cases.

Tools: the `pascal-anything` CLI. If it is missing, ask the user to build it (`fpc` in `src/`) and
run `pascal-anything setup`, then restart the agent. When a step fails because a runtime is missing,
run `pascal-anything doctor`.

## Only the slow part: `go`

```sh
pascal-anything go -- python3 app.py
# port src/port.pas as TASK.md says, then:
pascal-anything build pascal/<unit>_pas
pascal-anything gate pascal/<unit>_pas
```

## The loop (one unit)

1. `pascal-anything analyze <repo>` — ranked units, target Pascal/Lazarus.
2. `pascal-anything bridge <repo> <unit>` — package + `port.pas` + `TASK.md`.
3. `pascal-anything record <crate>` — write `cases.jsonl` (fill `ok` from the original).
4. You (the agent) implement `src/port.pas` and wire `harness.lpr` by function name.
5. `pascal-anything build <crate>` then `pascal-anything diff <crate>`.
6. `pascal-anything gate <crate>` — definition of done.
7. `pascal-anything enable <crate>` only after gate passes.
8. Report to the user and **wait** before the next unit.

## Hard rules

- The original is the source of truth.
- Do not paste recorded results into the port.
- Do not weaken tests or edit `cases.jsonl` to force a pass.
- Prefer Free Pascal style: `{$mode objfpc}{$H+}`, clear units, no unnecessary LCL for CLI ports.
- GUI ports use Lazarus LCL; keep business logic in non-visual units.

## Install

```sh
export PATH="$HOME/.local/bin:$HOME/.local/lib/fpc/3.2.2:$PATH"
cd /path/to/pascal-anything/src && fpc -O2 -Fu. -FE../bin pascalanything.lpr
ln -sfn "$(pwd)/../bin/pascalanything" "$HOME/.local/bin/pascal-anything"
pascal-anything setup
pascal-anything doctor
```
