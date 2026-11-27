# Whole app → Free Pascal / Lazarus

Use this when the user wants the **entire** application rewritten in Pascal/Lazarus, not only a hot function.

## Decisions to grill first

1. CLI, HTTP server, library, or Lazarus GUI?
2. Keep the original as reference only, or dual-run (shadow) for a while?
3. Which entry points must stay byte-compatible for callers?
4. Dependencies: rewrite, bind via FFI, or keep as external process?

## Flow

```
analyze --whole-app → record app behavior → front door (Pascal owns entry) →
  for each unit: bridge → record → port → build → diff → gate →
  wire units → lift to standalone FPC/Lazarus binary
```

1. `pascal-anything analyze <repo> --whole-app -o PLAN.md`
2. Confirm the plan and dependency strategy with the user.
3. Port units in plan order; never skip a failed `gate`.
4. After all units pass, assemble a Lazarus project (`.lpi`) or FPC program that links them.
5. Replay end-to-end cases against the Pascal front door before calling the migration done.

## Lazarus notes

- Non-visual logic lives in units under `pascal/`.
- Forms/frames only for UI; business rules stay testable via `harness`.
- Use `lazbuild` when available; otherwise `fpc` for console packages.
- Prefer **official LCL controls and FCL/RTL units**, then Lazarus CCR / maintained packages, then relevant domain frameworks. Do not invent a parallel UI stack. See [docs/stack.md](../../docs/stack.md).

