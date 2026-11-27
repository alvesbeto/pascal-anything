# How it works

```
analyze → bridge → record → port.pas → build → diff → gate
  what to   FPC      what the   you /       harness   cases
  port      package  original   agent       vs        match?
                     does       writes      Pascal
```

The original is ground truth. `record` stores returns; `diff` / `gate` require the same from the Pascal port.

Target: **Free Pascal** (console/library) and **Lazarus** (LCL GUI). Default bridge: `pascal/<unit>_pas/` with `pascal-anything.json`, `src/port.pas`, `harness.lpr`.
