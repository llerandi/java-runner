# java-runner

![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Java](https://img.shields.io/badge/java-%23ED8B00.svg?style=for-the-badge&logo=openjdk&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=macos&logoColor=F0F0F0)
![CI](https://github.com/llerandi/java-runner/actions/workflows/ci.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)
[![Medium](https://img.shields.io/badge/Medium-12100E?style=for-the-badge&logo=medium&logoColor=white)](https://medium.com/@llerandi/run-any-compiled-language-without-an-ide-6d910879ac04)

A command-line tool to compile and run Java exercises instantly, without an IDE, a build system, or any project structure. Point it at a `.java` file and it handles the rest.

The same pattern -- wrap the compile-and-run loop into a single command, add watch mode and clean error output -- applies to any compiled language. This project implements it for Java.

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
# Run a specific file
./runner.sh HelloWorld.java

# If there is only one .java file in the current directory, the argument is optional
./runner.sh

# If no .java file is found in the current directory, runner looks inside examples/ automatically
./runner.sh

# Enable watch mode: recompiles and reruns every time the file is saved
./runner.sh HelloWorld.java --watch

# Show help
./runner.sh --help
```

### Windows

```cmd
runner.bat HelloWorld.java
runner.bat
runner.bat HelloWorld.java --watch
```

From PowerShell, prefix with `.\`:

```powershell
.\runner.bat HelloWorld.java
.\runner.bat HelloWorld.java --watch
```

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
│       └── ci.yaml         # GitHub Actions CI pipeline
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
├── runner.bat              # Windows script
├── runner.sh               # Linux and macOS script
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

## License

MIT. Free to use, modify, and share.
