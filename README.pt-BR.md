# Pascal Anything

[English](README.md)

Reescreva seu app em **Free Pascal / Lazarus** e prove que o comportamento continua o mesmo.

Contraparte conceitual do [rust-anything](https://github.com/erkamyaman/rust-anything): o mesmo loop (`analyze` → `bridge` → `record` → `port` → `diff` → `gate`), com alvo em Pascal em vez de Rust.

## Início rápido

Para um agente de código:

```text
Instale o Pascal Anything (compile com fpc em src/), rode pascal-anything setup.
Rode pascal-anything go -- <comando lento deste app> e termine o port até pascal-anything gate passar.
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
| `analyze` | Mapa do repositório e ordem de migração → Pascal/Lazarus |
| `bridge` | Pacote FPC com `src/port.pas` e `harness.lpr` |
| `record` | Gera `cases.jsonl` a partir do original (Python executa o módulo de verdade) |
| `build` / `diff` | Compila o harness e compara os casos |
| `gate` | Critério de pronto de uma unidade |
| `go` | Atalho para a unidade candidata óbvia |
| `setup` / `doctor` | Skill nos agentes + checagem de ferramentas |
| `mcp` | Ferramentas MCP stdio dos mesmos passos |

Agentes: leia [`llms.txt`](llms.txt).

## Requisitos

- **Free Pascal 3.2+** — instalável em `~/.local` sem root
- **Lazarus / lazbuild** (opcional para GUI) — `sudo apt install lazarus`, ou `fpclazup` headless (veja [`docs/research.md`](docs/research.md))
- Runtimes do app original (`node`, `python3`, …) ao gravar comportamento

## Demo

```sh
pascal-anything analyze demo/slug-py
pascal-anything bridge demo/slug-py slug.py
pascal-anything record demo/slug-py/pascal/slug_pas --inputs demo/slug-py/inputs.jsonl
# implemente src/port.pas e o despacho do harness, depois:
pascal-anything build demo/slug-py/pascal/slug_pas
pascal-anything gate  demo/slug-py/pascal/slug_pas
```

## Licença

MIT OR Apache-2.0, mesma dual license da ideia original. Ports e código gerado no *seu* repositório são seus.

Inspirado em rust-anything © Erkam Yaman. Este projeto não é afiliado oficialmente.
