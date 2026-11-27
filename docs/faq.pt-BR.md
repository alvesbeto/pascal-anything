# FAQ

**Português (Brasil)** · [English](faq.md) · [Voltar ao README](../README.pt-BR.md)

## O que é o Pascal Anything?

CLI e skill de agente que reescreve um aplicativo em **Free Pascal / Lazarus** unidade a unidade. Grava o comportamento do original, você (ou o agente) escreve `port.pas`, e o `gate` só passa quando todos os casos batem.

## Qual a diferença para o rust-anything?

O mesmo loop e ideia; o alvo e a implementação são Pascal/Lazarus em vez de Rust. Veja [erkamyaman/rust-anything](https://github.com/erkamyaman/rust-anything).

## Isso é engenharia reversa (REA)?

Não. O Pascal Anything assume que você tem o **código-fonte** do programa. Ferramentas como [morluto/rea](https://github.com/morluto/rea) inspecionam binários sem fonte. A lista [awesome-reverse-engineer-anything](https://github.com/AIshihzong/awesome-reverse-engineer-anything) separa reescritas verificadas por comportamento (como o rust-anything) da categoria REA.

## Quando uma unidade está "pronta"?

Só quando `pascal-anything gate <crate>` passa. Divergências no diff exigem corrigir o port, não a gravação.

## Qual stack de UI / bibliotecas os ports devem usar?

**RTL/FCL do Free Pascal** e **LCL do Lazarus** primeiro; depois Lazarus CCR ou outros frameworks FPC/Lazarus mantidos e relevantes ao domínio. Veja [stack.pt-BR.md](stack.pt-BR.md).

## Quais plataformas?

Windows, Linux e macOS. Veja [platforms.md](platforms.md).


## Onde está o fluxo do agente?

[`llms.txt`](../llms.txt) e [`skills/pascal-anything/SKILL.md`](../skills/pascal-anything/SKILL.md).
