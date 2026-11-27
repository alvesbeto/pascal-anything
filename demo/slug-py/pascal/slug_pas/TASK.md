# TASK — port `slug.py` → Free Pascal

1. Read the original unit and fill `src/port.pas` with the same API.
2. `pascal-anything record` this crate (with `--inputs` when useful).
3. Wire `harness.lpr` to dispatch each `fn` from `cases.jsonl`.
4. `pascal-anything build` then `pascal-anything diff`.
5. Call it done only when `pascal-anything gate` passes.

Do not paste recorded results into source. Do not weaken tests.
