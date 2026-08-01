# JAVA Runner

[![CI](https://img.shields.io/github/actions/workflow/status/llerandi/java-runner/ci.yaml?label=CI&logo=github)](https://github.com/llerandi/java-runner/actions/workflows/ci.yaml)
[![License](https://img.shields.io/github/license/llerandi/java-runner)](LICENSE)
[![Stars](https://img.shields.io/github/stars/llerandi/java-runner?style=social)](https://github.com/llerandi/java-runner/stargazers)
[![Last commit](https://img.shields.io/github/last-commit/llerandi/java-runner)](https://github.com/llerandi/java-runner/commits/main)
[![Java](https://img.shields.io/badge/java-11%2B-orange?logo=openjdk)](https://openjdk.org/)
[![Medium](https://img.shields.io/badge/Medium-article-black?logo=medium)](https://medium.com/@llerandi/run-any-compiled-language-without-an-ide-6d910879ac04)
[![Live site](https://img.shields.io/badge/live%20site-GitHub%20Pages-0969da)](https://llerandi.github.io/java-runner/)

A command-line tool to compile and run Java exercises instantly, without an IDE, a build system, or any project structure. Point it at a `.java` file and it handles the rest.

**Live site:** [llerandi.github.io/java-runner](https://llerandi.github.io/java-runner/)

The same pattern - wrap the compile-and-run loop into a single command, add watch mode and clean error output - applies to any compiled language. This project implements it for Java.

> [!TIP]
> If you want to validate your solutions with automated tests, check out [java-kata-judge](https://github.com/llerandi/java-kata-judge) - a local kata judge that compiles your solution and JUnit tests, runs them, and reports pass/fail.

---

## How it works

java-runner wraps `javac` and `java` into a single command. It compiles the file into a temporary directory, runs the resulting class, prints the output, shows the execution time, and cleans up after itself. If compilation fails, it prints the errors with the absolute path noise removed so they are easier to read.

---

## Requirements

| Tool | Purpose | Notes |
|------|---------|-------|
| Java JDK | Compile and run | Version 11 or higher. Must include `javac`. |
| Bash | Run `runner.sh` | Version 4+. Linux and macOS only. |
| `inotify-tools` | Watch mode on Linux | Install with `sudo apt install inotify-tools` |
| `fswatch` | Watch mode on macOS | Install with `brew install fswatch` |

> Windows users should use `runner.bat`. No additional tools are needed for watch mode on Windows, which polls every 2 seconds.

> Make sure you have the **JDK** installed, not just the JRE. The JRE does not include `javac`. You can verify with `javac -version`.

---

## Installation

```bash
git clone https://github.com/llerandi/java-runner.git
cd java-runner
chmod +x runner.sh
```

---

## Usage

### Linux and macOS

```bash
./runner.sh HelloWorld.java           # run a specific file
./runner.sh                           # auto-detect
./runner.sh HelloWorld.java --watch   # watch mode
./runner.sh *.java --all              # compile all .java in the directory together
./runner.sh Main.java --input in.txt  # pipe file into stdin
./runner.sh Main.java --output out.txt
./runner.sh Main.java --classpath lib/junit.jar
./runner.sh --help
```

### Windows (Command Prompt)

```cmd
runner.bat HelloWorld.java
runner.bat HelloWorld.java --watch
runner.bat Main.java --all
runner.bat Main.java --input in.txt --output out.txt
runner.bat Main.java --classpath lib\junit.jar
```

### Windows (PowerShell)

`runner.ps1` uses `FileSystemWatcher` for event-based watch mode instead of polling.

```powershell
.\runner.ps1 HelloWorld.java
.\runner.ps1 HelloWorld.java -Watch
.\runner.ps1 Main.java -All
.\runner.ps1 Main.java -InputFile in.txt -OutputFile out.txt
.\runner.ps1 Main.java -Classpath lib\junit.jar
```

---

## Flags

| Flag | Short form (PS1) | Description |
|------|-----------------|-------------|
| `--watch` | `-Watch` | Recompile and rerun every time the file is saved |
| `--all` | `-All` | Compile all `.java` files in the same directory together |
| `--input <file>` | `-InputFile <file>` | Pipe a file into stdin when running |
| `--classpath <path>` | `-Classpath <path>` | Append to the compile and run classpath |
| `--output <file>` | `-OutputFile <file>` | Save program output to a file (also prints to terminal) |

---

## File detection order

When no file is passed as an argument, runner searches in this order:

1. Any `.java` file in the current directory. If exactly one is found, it runs it. If more than one is found, it lists them and asks you to specify.
2. If none is found in the current directory, it falls back to the `examples/` folder and applies the same logic.

---

## Output

Successful run:

```
Compiling FizzBuzz.java...
Compiled successfully
───────────────────────── output ─────────────────────────
1
2
Fizz
4
Buzz
Fizz
7
...
───────────────────────────────────────────────────────────
Finished in 143ms
```

Compilation error:

```
Compiling FizzBuzz.java...
Compilation failed:

FizzBuzz.java:6: error: ';' expected
        int x = 10
                   ^
1 error
```

---

## Watch mode

Watch mode recompiles and reruns the file automatically every time you save it. It is useful when working through an exercise and iterating quickly without leaving the terminal.

```bash
./runner.sh HelloWorld.java --watch
```

On Linux it uses `inotifywait`. On macOS it uses `fswatch`. On Windows it polls every 2 seconds using a built-in loop in the batch script, so no extra tool is needed.

Press `Ctrl+C` to stop watch mode.

---

## Testing

To run the test suite locally:

```bash
# Linux and macOS
chmod +x test.sh
./test.sh

# Windows
test.bat
```

The tests cover successful runs, compilation errors, runtime errors, and missing files. The same suite runs automatically on every push via the CI pipeline.

---

## Project structure

```
java-runner/
├── .github/
│   └── workflows/
│       ├── ci.yaml         # Test pipeline (Linux, macOS, Windows)
│       └── pages.yaml      # GitHub Pages deploy pipeline
├── docs/
│   ├── diagrams/           # draw.io source files
│   ├── img/                # Exported images
│   ├── article.md          # Published Medium article
│   ├── index.html          # GitHub Pages site
│   ├── robots.txt
│   └── sitemap.xml
├── examples/
│   ├── HelloWorld.java     # Basic output
│   ├── FizzBuzz.java       # Classic exercise
│   └── ReadInput.java      # Reading input from stdin
├── tests/
│   ├── CompileError.java   # Fixture: syntax error
│   └── RuntimeError.java   # Fixture: runtime exception
├── .gitattributes
├── .gitignore
├── README.md
├── runner.bat              # Windows (Command Prompt)
├── runner.ps1              # Windows (PowerShell, event-based watch mode)
├── runner.sh               # Linux and macOS
├── test.bat                # Test suite for Windows
└── test.sh                 # Test suite for Linux and macOS
```

---

## CI pipeline

Every push to `main` or `dev`, and every pull request targeting `main`, triggers the CI pipeline defined in `.github/workflows/ci.yaml`. It runs on Ubuntu, macOS, and Windows in parallel. Each job installs JDK 21 and runs the full test suite.

---

## Examples

The `examples/` folder contains three files you can use to verify the setup or as a starting point for exercises.

```bash
./runner.sh examples/HelloWorld.java
./runner.sh examples/FizzBuzz.java
./runner.sh examples/ReadInput.java
```

`ReadInput.java` reads from stdin, so the terminal will wait for you to type input before producing output.

---

## Roadmap

### Phase 1 - Core

- [x] Compile and run a `.java` file with a single command
- [x] Clean compilation error output (absolute paths stripped)
- [x] Elapsed time display after each run
- [x] Automatic file detection in current directory and `examples/` fallback
- [x] Watch mode on Linux (`inotifywait`) and macOS (`fswatch`)
- [x] Windows support (`runner.bat`) with polling-based watch mode
- [x] Cross-platform CI pipeline (Ubuntu, macOS, Windows)

### Phase 2 - Robustness

- [x] Runtime exit code capture and display on failure
- [x] Watch mode skips rerun if file has not changed (Windows)
- [x] Local test suite (`test.sh` / `test.bat`) with fixtures for compile errors and runtime errors
- [x] CI simplified to run the full test suite on every push

### Phase 3 - Polish

- [x] ANSI color output on Windows
- [x] Auto-detect test added to `test.sh` and `test.bat`
- [x] GitHub Pages site with project documentation
- [x] Clear screen between runs in watch mode
- [x] `runner.ps1` using PowerShell `FileSystemWatcher` for event-based watch mode on Windows

### Phase 4 - Features

- [x] `--all` flag: compile all `.java` files in the same directory together
- [x] `--input <file>` flag to pipe a file into stdin
- [x] `--classpath <path>` flag to append jars to the compile and run commands
- [x] `--output <file>` flag to save program output to a file (also prints to terminal)

### Phase 5 - Community

- [x] `CONTRIBUTING.md`
- [x] Issue templates

---

## License

MIT. Free to use, modify, and share.
