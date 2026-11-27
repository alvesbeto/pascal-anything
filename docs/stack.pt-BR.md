# Stack Pascal / Lazarus preferida

**Português (Brasil)** · [English](stack.md) · [Voltar ao README](../README.pt-BR.md)

Ao portar com o Pascal Anything, **prefira o ecossistema oficial Lazarus / Free Pascal** antes de inventar UI própria ou reinventar bibliotecas.

## Ordem de preferência

1. **RTL / FCL** — runtime e free-component library do Free Pascal (`Classes`, `SysUtils`, `Generics.*`, `fpjson`, `fphttpclient`, `sqldb`, …).
2. **LCL oficial do Lazarus** — forms, frames e controles padrão/comum do Lazarus. Use `lazbuild` quando a unidade precisar de LCL.
3. **Lazarus CCR / pacotes mantidos** — componentes do [Lazarus CCR](https://wiki.lazarus.freepascal.org/Lazarus_CCR) ou outros pacotes Lazarus/FPC conhecidos e mantidos quando o LCL sozinho não basta.
4. **Frameworks de domínio relevantes** — frameworks FPC/Lazarus estabelecidos que batem com o domínio do app original (banco, REST, relatórios, etc.), com licença clara e manutenção ativa.
5. **FFI fino / processo externo** — só quando a dependência não puder ser substituída de forma razoável; mantenha a fronteira pequena e coberta pelo `gate`.

## Regras para agentes

- Ports CLI / biblioteca: fique em **FPC + FCL**; não puxe LCL sem UI.
- Ports GUI: use **componentes LCL** (e pacotes oficiais) em vez de widgets desenhados à mão ou toolkits estrangeiros.
- Não introduza Electron, bindings Qt fora do LCL ou frameworks de UI ad hoc, salvo pedido explícito do usuário.
- Lógica de negócio em unidades não visuais para o `harness` / `gate` continuarem utilizáveis.
- Documente qualquer `.lpk` de terceiros no `TASK.md` do crate e no plano de migração.
