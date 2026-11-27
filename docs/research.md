# Research notes

## rust-anything (model)

- Repo: https://github.com/erkamyaman/rust-anything
- Agent pack: https://rustanything.ai/llms.txt
- Loop: analyze → bridge → record → port → build → diff → gate
- MCP: newline-delimited JSON-RPC 2.0 over stdio (`initialize`, `tools/list`, `tools/call`, protocol `2025-06-18`)
- Skill: one unit at a time; done = `gate`; never paste recorded results into source

## Free Pascal / Lazarus

- FPC user-local tarball: SourceForge `fpc-3.2.2.x86_64-linux.tar` → `~/.local`
- **fpclazup** (headless CLI, not the fpcupdeluxe GUI):  
  https://github.com/LongDirtyAnimAlf/Reiniero-fpcup  
  Example: `--fpcURL=stable --lazURL=stable --installdir=$HOME/.local/fpclaz --fpcsplit --noconfirm`  
  Refs: [Fpcupdeluxe wiki](https://wiki.freepascal.org/Fpcupdeluxe), [pascal.chat Ansible](https://pascal.chat/wiki/Installation_on_Linux_with_Ansible)
- Or system packages: `sudo apt install lazarus` → `/usr/bin/lazbuild`

## Gaps closed so far

| Gap | Action |
| --- | --- |
| Lazarus without a GUI installer | apt `lazbuild` and/or `fpclazup` → `~/.local/fpclaz` |
| Skeleton-only `record` | `scripts/record_python.py` runs the real module |
| Missing MCP | `pascal-anything mcp` |
| Agent discoverability | `llms.txt` |
| README parity with upstream | Centered header, badges, agent paste + TIP, dual-license blurb, `docs/translations.md`; skip sponsors/Discord/npm/crates branding |

## Next

- TS/JS and Go recorders
- `shadow` / `bench` / `known-diffs.jsonl`
- Auto-merge into `~/.cursor/mcp.json`
- Skill eval harness (upstream pattern)
