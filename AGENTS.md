# AGENTS.md

Instructions for coding agents working on Pascal Anything.

## What this project is

A **behaviour-checked rewrite toolkit**: record what the original program returns, port one unit to Free Pascal/Lazarus, replay every case, and call the unit done only when `pascal-anything gate` passes.

It is the Pascal/Lazarus counterpart of [rust-anything](https://github.com/erkamyaman/rust-anything). It is **not** reverse engineering of closed binaries. You rewrite code you already have source (and rights) for.

Inspiration for verification culture and bilingual docs also comes from the curated list [awesome-reverse-engineer-anything](https://github.com/AIshihzong/awesome-reverse-engineer-anything) (unofficial; not affiliated).

## The one rule that matters

**Do not claim a port is done unless `pascal-anything gate` passes on that crate**, with a recording that still matches the original. Do not paste `cases.jsonl` results into source. Do not edit cases to force a pass.

## Language

- English for code, commits, CLI messages, skills, and primary docs
- Comments rare and English-only
- Keep [`README.md`](README.md) and [`README.pt-BR.md`](README.pt-BR.md) in parity (same sections); see [`docs/translations.md`](docs/translations.md)

## Tags (for showcase / evidence notes)

| Tag | Means |
| --- | --- |
| `Gate` | `pascal-anything gate` passed; keep the command output or CI link |
| `Recorded` | `cases.jsonl` produced from the original (not hand-faked `ok` values) |
| `Rebuild` | Clean-room Pascal port of available source |
| `Claim?` | Asserted but not yet verified with gate |

## Loop

```
analyze → bridge → record → port.pas → build → diff → gate → enable
```

One unit at a time. Wait for the user before the next unit after a successful gate.

## Before you open a pull request

```bash
python3 scripts/validate_project.py
./scripts/build.sh   # or .\scripts\build.ps1 on Windows
pascal-anything doctor
```

If you touched record/diff/gate, re-run the slug demo gate when feasible.

## Do not

- mark a unit done without a passing gate
- weaken tests or rewrite recordings to hide mismatches
- claim reverse-engineering of proprietary binaries as this project's purpose
- update only one of README.md / README.pt-BR.md for shared sections
- invent affiliation with rust-anything, REA, or awesome-REA beyond "inspired by" / citation
