# How it works

```
analyze → bridge → record → port.pas → build → diff → gate
  o quê     pacote    o que o     você /       harness   casos     feito
  portar    FPC       original    agente       vs        batem?
                      faz         escreve      Pascal
```

O original é a fonte da verdade. `record` salva retornos; `diff` / `gate` exigem o mesmo no port Pascal.

Alvo: **Free Pascal** (console/biblioteca) e **Lazarus** (GUI LCL). Bridge padrão: pasta `pascal/<unit>_pas/` com `pascal-anything.json`, `src/port.pas`, `harness.lpr`.
