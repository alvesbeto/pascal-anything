# Pascal Anything

[Português (Brasil)](README.pt-BR.md)

Rewrite your app in **Free Pascal / Lazarus**, and prove it still behaves the same.

Conceptual counterpart of [rust-anything](https://github.com/erkamyaman/rust-anything): same loop (`analyze` → `bridge` → `record` → `port` → `diff` → `gate`), targeting Pascal instead of Rust.

## Quick start

For a coding agent:

```text
Install Pascal Anything (build with fpc under src/), run pascal-anything setup.
Run pascal-anything go -- <slow command of this app> and finish the port until pascal-anything gate passes.
```

On the machine:

```sh
export PATH="$HOME/.local/bin:$HOME/.local/lib/fpc/3.2.2:$PATH"
cd src && fpc -O2 -Fu. -FE../bin pascalanything.lpr
ln -sfn "$(pwd)/../bin/pascalanything" "$HOME/.local/bin/pascal-anything"
pascal-anything doctor
pascal-anything setup
```

## Loop

```
analyze → bridge → record → port.pas → build → diff → gate → enable
```

| Command | Role |
| --- | --- |
| `analyze` | Map the repo and migration order → Pascal/Lazarus |
| `bridge` | FPC package with `src/port.pas` and `harness.lpr` |
| `record` | Write `cases.jsonl` from the original (Python runs the real module) |
| `build` / `diff` | Compile the harness and compare cases |
| `gate` | Definition of done for one unit |
| `go` | Shortcut for the obvious candidate unit |
| `setup` / `doctor` | Agent skill + toolchain checks |
| `mcp` | MCP stdio tools for the same steps |

Agents: read [`llms.txt`](llms.txt).

## Requirements

- **Free Pascal 3.2+** — installable under `~/.local` without root
- **Lazarus / lazbuild** (optional for GUI) — `sudo apt install lazarus`, or headless `fpclazup` (see [`docs/research.md`](docs/research.md))
- Original-app runtimes (`node`, `python3`, …) when recording behavior

## Demo

```sh
pascal-anything analyze demo/slug-py
pascal-anything bridge demo/slug-py slug.py
pascal-anything record demo/slug-py/pascal/slug_pas --inputs demo/slug-py/inputs.jsonl
# implement src/port.pas and harness dispatch, then:
pascal-anything build demo/slug-py/pascal/slug_pas
pascal-anything gate  demo/slug-py/pascal/slug_pas
```

## License

MIT OR Apache-2.0, same dual license as the upstream idea. Ports and generated code in *your* repository are yours.

Inspired by rust-anything © Erkam Yaman. This project is not officially affiliated.
