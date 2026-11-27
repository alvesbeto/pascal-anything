<h1 align="center">Pascal Anything</h1>

<p align="center">
<a href="https://github.com/alvesbeto/pascal-anything/stargazers"><img src="https://img.shields.io/github/stars/alvesbeto/pascal-anything?style=flat&colorA=111111&colorB=005A9C&label=stars" alt="GitHub stars"></a>
<a href="#license"><img src="https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-111111?style=flat&colorA=111111&colorB=005A9C" alt="MIT or Apache-2.0 license"></a>
<a href="https://www.freepascal.org/"><img src="https://img.shields.io/badge/Free%20Pascal-3.2%2B-111111?style=flat&colorA=111111&colorB=005A9C" alt="Free Pascal 3.2+"></a>
<a href="https://www.lazarus-ide.org/"><img src="https://img.shields.io/badge/Lazarus-optional-111111?style=flat&colorA=111111&colorB=005A9C" alt="Lazarus optional"></a>
</p>

<p align="center">
Rewrite your app in Free Pascal / Lazarus, and prove it still behaves the same.
</p>

<p align="center">
<b>Docs:</b> <a href="docs/how-it-works.md">how it works</a> · <a href="docs/SDD.md">SDD</a> · <a href="llms.txt">llms.txt</a>
</p>

<p align="center"><a href="docs/translations.md">🌐 Other languages</a> · <a href="README.pt-BR.md">Português (Brasil)</a></p>

<p align="center"><sub>Conceptual counterpart of <a href="https://github.com/erkamyaman/rust-anything">rust-anything</a> — same verified loop, Pascal/Lazarus target. Not affiliated.</sub></p>

## Quick start

Paste this into your coding agent:

```text
Install Pascal Anything: build with fpc under src/, put bin/pascalanything on PATH as pascal-anything, then run pascal-anything setup. Run pascal-anything go -- <slow command of this app> and finish the port until pascal-anything gate passes.
```

Or install it yourself:

**Linux / macOS**

```sh
./scripts/build.sh
pascal-anything doctor
pascal-anything setup           # skill + MCP snippet for Claude Code, Cursor, …
```

**Windows (PowerShell)**

```powershell
.\scripts\build.ps1
pascal-anything doctor
pascal-anything setup
```

Needs Free Pascal on `PATH`. Details: [`docs/platforms.md`](docs/platforms.md).

> [!TIP]
> **Agents:** read [`llms.txt`](llms.txt) for install steps, every command, and the porting workflow.

## The loop

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

More detail: [`docs/how-it-works.md`](docs/how-it-works.md).

## Requirements

- **OS:** Windows, Linux, or macOS
- **Free Pascal 3.2+** on `PATH` (see [`docs/platforms.md`](docs/platforms.md))
- **Lazarus / lazbuild** (optional for GUI)
- Original-app runtimes (`node`, `python3` / `python`, …) when recording behavior

CI builds all three OSes via GitHub Actions.

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

Licensed under either of [MIT](./LICENSE-MIT) or [Apache-2.0](./LICENSE-APACHE), at your option. Ports and generated code in your repository are yours.

Unless you explicitly state otherwise, any contribution you intentionally submit for inclusion in pascal-anything, as defined in the Apache-2.0 license, is dual licensed as above, without any additional terms or conditions.

Inspired by [rust-anything](https://github.com/erkamyaman/rust-anything) © [Erkam Yaman](https://github.com/erkamyaman). This project is not officially affiliated.
