# FAQ

**English** · [Português (Brasil)](faq.pt-BR.md) · [Back to README](../README.md)

## What is Pascal Anything?

A CLI and agent skill that rewrites an application into **Free Pascal / Lazarus** one unit at a time. It records the original's behaviour, you (or your agent) write `port.pas`, and `gate` passes only when every recorded case matches.

## How is this different from rust-anything?

Same loop and idea; the target and implementation are Pascal/Lazarus instead of Rust. See [erkamyaman/rust-anything](https://github.com/erkamyaman/rust-anything).

## Is this reverse engineering (REA)?

No. Pascal Anything assumes you have the **source** of the program you are porting. Tools like [morluto/rea](https://github.com/morluto/rea) inspect binaries without source. The curated list [awesome-reverse-engineer-anything](https://github.com/AIshihzong/awesome-reverse-engineer-anything) places behaviour-checked source rewrites (including rust-anything) in their own category, separate from REA.

## When is a unit "done"?

Only when `pascal-anything gate <crate>` passes. Diff mismatches mean fix the port, not the recording (unless the user intentionally documents a known difference later).

## Which platforms?

Windows, Linux, and macOS. See [platforms.md](platforms.md).

## Where is the agent workflow?

[`llms.txt`](../llms.txt) and [`skills/pascal-anything/SKILL.md`](../skills/pascal-anything/SKILL.md).
