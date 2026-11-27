# Platforms

Pascal Anything targets **Windows**, **Linux**, and **macOS** (x86_64 / Apple Silicon via FPC).

## Build

| OS | Command |
| --- | --- |
| Linux / macOS | `./scripts/build.sh` |
| Windows (PowerShell) | `.\scripts\build.ps1` |

Requires `fpc` on `PATH`. The CLI binary is `bin/pascalanything` (`.exe` on Windows).

## Install Free Pascal

- **Linux:** distro package (`fpc`) or the official tarball under `~/.local`
- **macOS:** `brew install fpc`
- **Windows:** [freepascal.org downloads](https://www.freepascal.org/download.html), Chocolatey `choco install freepascal`, or the installer from SourceForge. After Chocolatey, open a new shell or refresh PATH (`C:\tools\freepascal\bin\i386-win32`). `build.ps1` also probes common install locations.


## Lazarus (optional)

Needed for GUI ports / `lazbuild`. Install the Lazarus IDE for your OS, or use `fpclazup` on Unix.

## Python recorder

`record` looks for `python3`, then `python` (and `py` on Windows). Set `PASCAL_ANYTHING_HOME` to the repo root if the CLI binary is installed away from the source tree.

## CI

GitHub Actions (`.github/workflows/ci.yml`) builds and runs `doctor` + the slug demo gate on Ubuntu, macOS, and Windows.
