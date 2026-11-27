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

## Diretrizes canônicas de GUI LCL

Ao portar ou gerar interfaces gráficas com o Lazarus LCL:

1. **Vincular `TMainMenu` nativo no formulário**:
   Sempre que um formulário contiver um menu principal, atribua `TForm.Menu := MainMenu` no `.lfm` e na declaração do formulário. Isso assegura integração com a barra de menus nativa do sistema operacional (barra global no macOS, menus nativos no Windows, GTK/Qt no Linux).
2. **Preservação de hierarquias completas e submenus em cascata**:
   Nunca achatar árvores de menus em um único nível. Preserve rigorosamente a estrutura de submenus aninhados (ex.: `Query -> Explain -> Visual Explain`, `View -> Panels`, `Database -> Engineering -> Reverse Engineer`), gerando os `TMenuItem` filhos com seus devidos separadores (`Caption = '-'`). Evite menus vazios (como menu `Edit` sem ações filhas) ou menus truncados apenas no primeiro nível.
3. **Uso prioritário de `TActionList` (`TAction`)**:
   Para comandos compartilhados entre menus principais, submenus em cascata, menus de contexto (`TPopupMenu`), barras de ferramentas (`TToolBar`) e atalhos de teclado (`ShortCut`), instancie ações em um `TActionList`. Vincule cada item de menu ou botão de ferramenta diretamente via `Action := act...`, sincronizando automaticamente legendas, atalhos e estados (Enabled/Checked). Evite código de cola manual entre cliques e eventos de menu.
4. **Barra de status nativa (`TStatusBar`)**:
   Use `TStatusBar` com `TStatusPanels` dedicados para rodapés de janelas em vez de painéis avulsos (`TPanel`) ou rótulos soltos.
5. **Menus de contexto nativos (`TPopupMenu`)**:
   Associe instâncias de `TPopupMenu` diretamente à propriedade `PopupMenu` de controles interativos (`TTreeView`, `TPageControl`, `TStringGrid` etc.), mantendo toda a hierarquia de submenus de contexto.
6. **Componentes canônicos consolidados**:
   Priorize componentes oficiais da LCL/FCL (`TSynEdit`, `TSplitter`, `TPageControl`, `TCheckListBox`, `FPCUnit`) antes de criar estruturas ad-hoc.
