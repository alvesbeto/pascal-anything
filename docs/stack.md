# Preferred Pascal / Lazarus stack

**English** · [Português (Brasil)](stack.pt-BR.md) · [Back to README](../README.md)

When porting with Pascal Anything, **prefer the official Lazarus / Free Pascal ecosystem** before inventing custom UI or reinventing libraries.

## Order of preference

1. **RTL / FCL** — Free Pascal run-time and free-component library (`Classes`, `SysUtils`, `Generics.*`, `fpjson`, `fphttpclient`, `sqldb`, …).
2. **Official Lazarus LCL** — forms, frames, standard and common controls shipped with Lazarus (`StdCtrls`, `ExtCtrls`, `ComCtrls`, `Dialogs`, `Menus`, `Graphics`, `Controls`, …). Build with `lazbuild` when the unit needs LCL.
3. **Lazarus CCR / maintained packages** — components and packages from the [Lazarus Code and Component Repository](https://wiki.lazarus.freepascal.org/Lazarus_CCR) or other well-known, maintained Lazarus/FPC packages when LCL alone is not enough (charts, grids extras, networking helpers, etc.).
4. **Relevant domain frameworks** — established FPC/Lazarus frameworks that match the original app’s domain (for example database layers, REST routers, or reporting tools commonly used with Lazarus). Prefer packages with clear licenses and active maintenance.
5. **Thin FFI / external process** — only when a dependency cannot be replaced reasonably; keep the boundary small and gate-tested.

## Rules for agents

- CLI / library ports: stay on **FPC + FCL**; do not pull LCL unless the unit is UI.
- GUI ports: use **LCL components** (and official packages) rather than custom-drawn widgets or foreign GUI toolkits.
- Do not introduce Electron, Qt-via-non-LCL bindings, or ad-hoc UI frameworks unless the user explicitly asks.
- Keep business logic in non-visual units so `harness` / `gate` stay usable.
- Document any third-party `.lpk` in the crate `TASK.md` and in the migration plan.

## References

- [Lazarus IDE](https://www.lazarus-ide.org/)
- [Free Pascal](https://www.freepascal.org/)
- [Lazarus Wiki — Components and Code](https://wiki.lazarus.freepascal.org/)
