# SDD — Pascal Anything

## Spec

Ferramenta CLI + skills de agente para migrar qualquer codebase para Free Pascal/Lazarus com verificação comportamental (record/diff/gate), espelhando o fluxo do rust-anything.

## Decisions

| ID | Decisão | Motivo |
| --- | --- | --- |
| D1 | Implementação do CLI em Free Pascal | O kit de destino é o próprio stack |
| D2 | Bridge = pacote FPC + harness, não FFI automático completo no v0.1 | Entrega o loop verificável; parsers por linguagem evoluem depois |
| D3 | Skill/plugin para agentes (Cursor, Claude, …) | Mesmo modelo de distribuição do original |
| D4 | FPC em `~/.local` sem root | Instalação possível sem sudo; Lazarus IDE opcional |

## Status

- v0.1.0: CLI base + demo slug (gate pass)
- v0.2.0: pesquisa aplicada — `record` Python real, MCP stdio (`pascal-anything mcp`), `llms.txt`, `docs/research.md`, instalação Lazarus via **fpclazup** headless em `~/.local/fpclaz`
- Pendente: gravadores TS/JS/Go, shadow/bench/fuzz, merge MCP no Cursor, skill-eval
