<h1 align="center">Pascal Anything</h1>

<p align="center">
<a href="https://github.com/alvesbeto/pascal-anything/stargazers"><img src="https://img.shields.io/github/stars/alvesbeto/pascal-anything?style=flat&colorA=111111&colorB=005A9C&label=stars" alt="GitHub stars"></a>
<a href="#licença"><img src="https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-111111?style=flat&colorA=111111&colorB=005A9C" alt="MIT or Apache-2.0 license"></a>
<a href="https://www.freepascal.org/"><img src="https://img.shields.io/badge/Free%20Pascal-3.2%2B-111111?style=flat&colorA=111111&colorB=005A9C" alt="Free Pascal 3.2+"></a>
<a href="https://www.lazarus-ide.org/"><img src="https://img.shields.io/badge/Lazarus-opcional-111111?style=flat&colorA=111111&colorB=005A9C" alt="Lazarus opcional"></a>
</p>

<p align="center">
Reescreva seu app em Free Pascal / Lazarus e prove que o comportamento continua o mesmo.
</p>

<p align="center">
<b>Docs:</b> <a href="docs/how-it-works.md">como funciona</a> · <a href="docs/stack.pt-BR.md">stack</a> · <a href="docs/faq.pt-BR.md">FAQ</a> · <a href="docs/showcase.md">showcase</a> · <a href="docs/SDD.md">SDD</a> · <a href="llms.txt">llms.txt</a> · <a href="CONTRIBUTING.md">contribuindo</a>

</p>


<p align="center"><a href="docs/translations.md">🌐 Outros idiomas</a> · <a href="README.md">English</a></p>

<p align="center"><sub>Esta tradução pode ficar atrás do <a href="README.md">README em inglês</a>. Contraparte conceitual do <a href="https://github.com/erkamyaman/rust-anything">rust-anything</a> — mesmo loop verificado, alvo Pascal/Lazarus. Sem afiliação oficial.</sub></p>

## Início rápido

Cole isto no seu agente de código:

```text
Install Pascal Anything: build with fpc under src/, put bin/pascalanything on PATH as pascal-anything, then run pascal-anything setup. Run pascal-anything go -- <slow command of this app> and finish the port until pascal-anything gate passes.
```

Ou instale você mesmo:

**Linux / macOS**

```sh
./scripts/build.sh
pascal-anything doctor
pascal-anything setup           # skill + snippet MCP para Claude Code, Cursor, …
```

**Windows (PowerShell)**

```powershell
.\scripts\build.ps1
pascal-anything doctor
pascal-anything setup
```

Precisa do Free Pascal no `PATH`. Detalhes: [`docs/platforms.md`](docs/platforms.md).

> [!TIP]
> **Agentes:** leiam [`llms.txt`](llms.txt) para instalação, todos os comandos e o fluxo de port.

## O loop

```
analyze → bridge → record → port.pas → build → diff → gate → report → enable
```

| Comando | Função |
| --- | --- |
| `analyze` | Mapa do repositório e ordem de migração → Pascal/Lazarus |
| `bridge` | Pacote FPC com `src/port.pas`, `harness.lpr` e `--end-state` |
| `record` | Gera `cases.jsonl` a partir do original (Python executa o módulo) |
| `build` / `diff` | Compila o harness e compara os casos (respeita `known-diffs.jsonl`) |
| `gate` | Critério de pronto de uma unidade (rastreia comportamento e known diffs) |
| `report` | Relatório de revisão em `report/REPORT.md` (end-state, métricas, intended diffs) |
| `go` | Atalho para a unidade candidata óbvia |
| `setup` / `doctor` | Skill nos agentes + checagem de ferramentas |
| `mcp` | Ferramentas MCP stdio dos mesmos passos |

Mais detalhe: [`docs/how-it-works.md`](docs/how-it-works.md).

## Requisitos

- **SO:** Windows, Linux ou macOS
- **Free Pascal 3.2+** no `PATH` (veja [`docs/platforms.md`](docs/platforms.md))
- **Lazarus / lazbuild** (opcional para GUI)
- Runtimes do app original (`node`, `python3` / `python`, …) ao gravar comportamento

O CI compila nos três sistemas via GitHub Actions.

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

Licenciado sob [MIT](./LICENSE-MIT) ou [Apache-2.0](./LICENSE-APACHE), à sua escolha. Ports e código gerado no seu repositório são seus.

Salvo declaração explícita em contrário, qualquer contribuição que você envie de propósito para inclusão no pascal-anything, conforme a licença Apache-2.0, fica sob a dual license acima, sem termos adicionais.

Inspirado em [rust-anything](https://github.com/erkamyaman/rust-anything) © [Erkam Yaman](https://github.com/erkamyaman). Cultura de verificação e checagens bilíngues também se inspiram em [awesome-reverse-engineer-anything](https://github.com/AIshihzong/awesome-reverse-engineer-anything) (citação; este projeto é reescrita verificada por comportamento a partir de fonte, não REA). Sem afiliação oficial com nenhum dos dois.

