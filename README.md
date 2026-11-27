# Pascal Anything

Rewrite your app in **Free Pascal / Lazarus**, and prove it still behaves the same.

Réplica conceitual de [rust-anything](https://github.com/erkamyaman/rust-anything): mesmas ideias (analyze → bridge → record → port → diff → gate), alvo e implementação em Pascal em vez de Rust.

## Quick start

Para o agente:

```text
Instale Pascal Anything (build com fpc em src/), rode pascal-anything setup.
Rode pascal-anything go -- <comando lento do app> e termine o port até pascal-anything gate passar.
```

Na máquina:

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

| Comando | Função |
| --- | --- |
| `analyze` | Mapa do repo e ordem de migração → Pascal/Lazarus |
| `bridge` | Pacote FPC com `src/port.pas` e `harness.lpr` |
| `record` | Grava `cases.jsonl` a partir do original |
| `build` / `diff` | Compila o harness e compara casos |
| `gate` | Critério de pronto da unidade |
| `go` | Atalho para a unidade candidata mais óbvia |
| `setup` / `doctor` | Skill nos agentes e checagem de ferramentas |

## Requisitos

- **Free Pascal 3.2+** (CLI) — instalável em `~/.local` sem root
- **Lazarus / lazbuild** (opcional) — `fpclazup` headless em `~/.local/fpclaz` (ver `docs/research.md`), ou `sudo apt install lazarus`
- Runtimes do app original (node, python3, …) para gravar comportamento

Agentes: leia [`llms.txt`](llms.txt). MCP: `pascal-anything mcp`.

## Demo

```sh
pascal-anything analyze demo/slug-py
pascal-anything bridge demo/slug-py slug.py
# implemente pascal/slug_pas/src/port.pas, complete o harness, depois:
pascal-anything record demo/slug-py/pascal/slug_pas
pascal-anything build  demo/slug-py/pascal/slug_pas
pascal-anything gate   demo/slug-py/pascal/slug_pas
```

## License

MIT OR Apache-2.0, mesma dual license do projeto original. Ports e código gerado no *seu* repositório são seus.

Inspirado em rust-anything © Erkam Yaman. Esta réplica não é afiliada oficialmente.
