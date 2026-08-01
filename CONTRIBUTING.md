# Contributing

Contributions are welcome. This document covers how to report bugs, propose features, and submit pull requests.

## Reporting a bug

Open an issue using the Bug report template. Include the OS and Java version, the exact command you ran, and the output you got vs. what you expected.

## Proposing a feature

Open an issue using the Feature request template before writing any code. Describe the use case and how you would use it.

## Submitting a pull request

1. Fork the repository and create a branch from `main`.
2. Make your changes.
3. Run the test suite and confirm it passes on your platform:
   ```bash
   # Linux and macOS
   chmod +x test.sh
   ./test.sh

   # Windows
   test.bat
   ```
4. Open a pull request against `main`. Describe what changed and why.

## Code style

- `runner.sh`: `set -euo pipefail` stays on. Capture external command exit codes explicitly with `set +e / set -e`. Use the same ANSI color variables already defined. Keep bash 3.2 compatibility (no `mapfile`).
- `runner.bat`: keep `setlocal EnableDelayedExpansion`. Use `!VAR!` inside blocks. Capture `ERRORLEVEL` immediately after the relevant command.
- `runner.ps1`: use `$LASTEXITCODE` after every external command. Keep `Invoke-Run` returning the Java exit code.

## Running CI locally

The CI pipeline runs on Ubuntu, macOS, and Windows in parallel. To replicate a specific job locally, install JDK 21 and run `./test.sh` or `test.bat` depending on your platform.

## License

By contributing you agree that your changes will be licensed under the MIT license.
