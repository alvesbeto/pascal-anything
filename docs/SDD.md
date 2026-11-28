# SDD — Pascal Anything

## Spec

CLI + agent skills to migrate any codebase to Free Pascal/Lazarus with behavioral checks (`record` / `diff` / `gate`), following the rust-anything loop.

## Decisions

| ID | Decision | Why |
| --- | --- | --- |
| D1 | CLI implemented in Free Pascal | The destination stack is the toolkit itself |
| D2 | Bridge = FPC package + harness, not full auto-FFI in v0.1 | Delivers a verifiable loop; language parsers grow later |
| D3 | Skill/plugin for agents (Cursor, Claude, …) | Same distribution model as the original |
| D4 | FPC under `~/.local` without root | Installable without sudo; Lazarus IDE optional via apt/fpclazup |
| D5 | English as project language; `README.pt-BR.md` for Brazilian Portuguese | Shared engineering language; local docs stay reachable |
| D6 | First-class Windows / Linux / macOS | Same CLI surface; OS-specific build scripts + CI matrix |
| D7 | Evidence-first docs (awesome-REA patterns) | Gate claims need evidence; EN/PT README parity validated in CI |
| D8 | Official Lazarus/FPC stack first | Ports use RTL/FCL, LCL, then CCR/maintained frameworks — not ad-hoc UI toolkits ([docs/stack.md](stack.md)) |
| D9 | Canonical LCL GUI patterns (Issue #1) | Require native `TMainMenu` (`TForm.Menu`), strict preservation of cascaded submenus, `TActionList` integration, native `TStatusBar` with panels, and `TPopupMenu` over ad-hoc glue code |
| D10 | End-state modeling & reviewer report | Explicitly record port end state (`replace`, `bindings`, `scaffold`), list intended differences from `known-diffs.jsonl` and kept exports in `REPORT.md`, and track known diffs in gate |
| D11 | Python recorder parameter & Path fidelity | Record `pathlib.Path` as path strings and preserve required parameters (including `T | None`) without omitting required arguments, while honoring parameter defaults |
| D12 | Secret refusal in record & cases.jsonl | Refuse to leave secrets from environment variables (SECRET, TOKEN, PASSWORD, etc., >= 8 chars) in cases.jsonl; fail and remove/empty file without leaking values |


## Status

- v0.1.0: base CLI + slug demo (gate pass)
- v0.2.0: real Python `record`, MCP stdio, `llms.txt`, research notes, Lazarus via apt/fpclazup
- v0.2.1: English-first docs/CLI; PT-BR README cross-link
- v0.3.0: cross-platform paths/executables, `build.ps1`, GitHub Actions on Ubuntu/macOS/Windows
- v0.3.1: AGENTS/CONTRIBUTING/FAQ/showcase, `validate_project.py` in CI; awesome-REA tracker
- v0.3.2: stack preference — official Lazarus/FCL/LCL (+ CCR/frameworks); `docs/stack.md`
- v0.3.3: upstream sync — LF line endings via `.gitattributes`, singular/plural CLI count formatting (diff, gate, record, report), report terminology fix
- v0.3.4: canonical LCL GUI patterns — TMainMenu form binding, nested cascaded submenu hierarchy preservation, TActionList wiring, TStatusBar panels, TPopupMenu control binding (Issue #1)
- v0.3.5: port end-state option (`--end-state replace|bindings|scaffold`), reviewer `REPORT.md` with intended differences and kept exports, `known-diffs.jsonl` behavior matching and gate tracking
- v0.3.6: Python recorder parity — bridge `pathlib.Path` as path strings and preserve required Python parameters (including `T | None`) without omitting required positional args
- v0.3.7: secret refusal in record (never commit env secrets to cases.jsonl), MCP initialize instructions naming all 10 supported languages

- OpenBot routine `rust-anything-upstream-sync`: hourly (America/Sao_Paulo :15), thread; tracker `docs/upstream-rust-anything.json`
- OpenBot routine `awesome-rea-upstream-sync`: hourly (America/Sao_Paulo :45), thread; tracker `docs/upstream-awesome-rea.json`
- Pending: TS/JS/Go recorders, shadow/bench/fuzz, Cursor MCP merge, skill-eval

