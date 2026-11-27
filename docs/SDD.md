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

## Status

- v0.1.0: base CLI + slug demo (gate pass)
- v0.2.0: real Python `record`, MCP stdio, `llms.txt`, research notes, Lazarus via apt/fpclazup
- v0.2.1: English-first docs/CLI; PT-BR README cross-link
- Pending: TS/JS/Go recorders, shadow/bench/fuzz, Cursor MCP merge, skill-eval
