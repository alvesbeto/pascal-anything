# Contributing

Thanks for helping. Pascal Anything stays useful only when ports are **checkable**.

## What belongs here

1. Improvements to the Free Pascal CLI, skills, docs, demos, or CI
2. Recorders and bridges for more source languages
3. Verified demo ports with a passing `gate` (evidence in the PR)
4. Documentation that keeps English / Brazilian Portuguese README parity

## What does not

1. Pasting recorded case outputs into `port.pas`
2. Editing `cases.jsonl` to force a green gate
3. Reverse-engineering closed binaries or shipping copyrighted assets
4. Changing only one language edition of a paired README section

## Checks

```bash
python3 scripts/validate_project.py
./scripts/build.sh          # Windows: .\scripts\build.ps1
pascal-anything doctor
```

CI also builds on Ubuntu, macOS, and Windows (`.github/workflows/ci.yml`).

## Pull requests

Use the PR template. Say:

- what changed and why
- which commands you ran (`doctor`, `gate`, …)
- whether README EN and PT-BR both need updates

## License

Contributions are dual-licensed MIT OR Apache-2.0 unless you state otherwise (see the README license section).
