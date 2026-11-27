# Research notes (fontes usadas)

## rust-anything (modelo)

- Repo: https://github.com/erkamyaman/rust-anything
- Agent prompt pack: https://rustanything.ai/llms.txt
- Loop: analyze → bridge → record → port → build → diff → gate
- MCP: JSON-RPC 2.0 newline-delimited em stdio (`initialize`, `tools/list`, `tools/call`, protocol `2025-06-18`)
- Skill: porta uma unidade; done = `gate`; não colar resultados gravados no código

## Free Pascal / Lazarus

- FPC tarball user-local: SourceForge `fpc-3.2.2.x86_64-linux.tar` → `~/.local`
- **fpclazup** (CLI headless, não a GUI fpcupdeluxe):  
  https://github.com/LongDirtyAnimAlf/Reiniero-fpcup  
  Ex.: `--fpcURL=stable --lazURL=stable --installdir=$HOME/.local/fpclaz --fpcsplit --noconfirm`  
  Refs: [wiki Fpcupdeluxe](https://wiki.freepascal.org/Fpcupdeluxe), [pascal.chat Ansible](https://pascal.chat/wiki/Installation_on_Linux_with_Ansible), [DeepWiki install](https://deepwiki.com/LongDirtyAnimAlf/fpcupdeluxe/2-installation-and-usage)
- Deps Debian/Ubuntu: `build-essential`, `libgtk-3-dev`, git, make, zip/unzip (já presentes nesta máquina)

## Gaps cobertos neste avanço

| Gap | Ação |
| --- | --- |
| Lazarus sem sudo | `fpclazup` em background → `~/.local/fpclaz` |
| `record` só esqueleto | `scripts/record_python.py` executa o módulo original |
| MCP ausente | `pascal-anything mcp` (tools do loop) |
| Discoverability agentes | `llms.txt` |

## Próximo

- Gravadores TS/JS e Go espelhando o Python
- `shadow` / `bench` / `known-diffs.jsonl`
- Setup merge automático em `~/.cursor/mcp.json`
- Avaliar skill com `scripts/skill-eval` (padrão do original)
