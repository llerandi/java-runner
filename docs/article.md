# Run Any Compiled Language Without an IDE

Most compiled languages share the same basic workflow: you write code in a file, you compile it, and you run the result. The tools change depending on the language, but the pattern is always the same.

That pattern is also where most beginners spend a surprising amount of time. Not writing code -- managing the tooling around it. Setting up an IDE, configuring a project, learning a build system. All of that before writing a single line.

This article is about a simpler approach: a small script that wraps the compile-and-run loop into a single command, adds a few useful features, and gets out of the way.

---

## The Pattern

The idea is straightforward. Instead of running two commands every time you want to test your code:

```bash
javac MyFile.java
java MyFile
```

You run one:

```bash
./runner.sh MyFile.java
```

The script handles compilation, runs the result, prints the output, shows how long it took, and cleans up the compiled files. If compilation fails, it shows the errors. If the program crashes at runtime, it shows the exit code.

This is not a new idea. It is just automation of something you would do manually anyway.

---

## What Languages This Works For

This pattern fits any language where compilation and execution are separate steps. Some examples:

**C and C++.** Compile with `gcc` or `g++`, run the binary. The binary is a file, so cleanup after each run is easy.

**Go.** You can use `go run file.go` directly, which already does compile-and-run in one step. But wrapping it still gives you timing, watch mode, and auto-detection for free.

**Rust.** Compile with `rustc`, run the binary. Same idea as C.

**C#.** On .NET, you use `dotnet build` to compile and `dotnet run` to execute. Unlike the other languages on this list, the compiler expects a project structure, so a single-file wrapper requires a bit more setup.

**Kotlin.** Similar to Java -- `kotlinc` compiles to a `.class` file or a jar, `java` or `kotlin` runs it.

Interpreted languages like Python, Ruby, or Node.js do not need a compilation step, but the same wrapper approach still adds value: automatic file detection, timing, and watch mode work exactly the same way.

---

## The Java Implementation

The rest of this article walks through how this pattern was implemented for Java in a project called java-runner.

### Why Java

Java is a common first language for people learning to program in university or through structured courses. It is also a language where the gap between "I want to run this file" and "I know how to set up the tooling" is large enough to be a real obstacle.

java-runner was built specifically for that context: someone working through exercises, one file at a time, who wants to focus on the code and not the infrastructure.

### How It Works

When you run java-runner against a `.java` file, it does the following:

1. Compiles the file into a temporary directory using `javac`.
2. Runs the resulting class with `java`.
3. Prints the output, the elapsed time, and cleans up the temporary directory.

If compilation fails, it prints the errors with the absolute file paths stripped out, so the output is shorter and easier to read. If the program throws an exception at runtime, it captures the exit code and includes it in the output.

### File Detection

If you are in a directory with a single `.java` file, you do not need to specify it:

```bash
./runner.sh
```

The script finds it automatically. If there are multiple files, it lists them and asks you to be specific. If there are none, it falls back to an `examples/` folder before giving up.

This is a small feature, but it saves keystrokes when switching between exercises.

### Watch Mode

Watch mode reruns the file automatically every time you save it:

```bash
./runner.sh MyFile.java --watch
```

On Linux it uses `inotifywait`, which gets notified by the OS the moment a file changes. On macOS it uses `fswatch`. Both react instantly. On Windows, the batch script checks the file's last-modified timestamp every two seconds and only reruns if it changed -- no extra tools needed.

The result: you keep your editor open on one side, your terminal on the other, and every save immediately shows the new output.

### Cross-Platform

java-runner ships as two scripts: `runner.sh` for Linux and macOS, and `runner.bat` for Windows. Both do the same things. The Windows version required more work -- batch scripting has its own quirks around variable expansion, time parsing, and file watching -- but the end result behaves the same way on all three platforms.

A CI pipeline runs the full test suite on Ubuntu, macOS, and Windows on every push to catch any regressions.

---

## Applying This to Another Language

If you wanted to build the same thing for, say, Go, the structure would be almost identical. The script would:

1. Accept a `.go` file as input.
2. Run `go build -o /tmp/runner-out file.go` to compile it.
3. Run `/tmp/runner-out` to execute it.
4. Print the output, elapsed time, and clean up.

Watch mode, file detection, and error handling would all work the same way. The only parts that change are the compiler command and the file extension.

For C, you would swap `go build` for `gcc -o /tmp/runner-out file.c`. For Rust, `rustc -o /tmp/runner-out file.rs`. The shell script logic around it stays the same.

---

## When This Is Not Enough

This approach has a clear limit: it works well for single files. As soon as your program spans multiple files, imports packages from other directories, or depends on external libraries, a proper build tool is the right answer.

Maven, Gradle, Cargo, Go modules -- these exist for a reason. They handle dependency management, multi-file compilation, and reproducible builds in ways a wrapper script cannot.

java-runner is for the stage before that. When you are learning, when you are practicing, when you just want to run one file and see what happens.

---

## The Takeaway

The compile-and-run loop is not specific to Java. It is a pattern that shows up in most compiled languages, and the friction it causes for beginners is the same everywhere.

A small script that wraps that loop -- adds automatic file detection, watch mode, clean error output, and timing -- is worth building for any language you practice regularly. The implementation details change. The value does not.

java-runner is one version of that idea. The source is on GitHub. If you work in a different language, the structure is there to copy.

https://github.com/llerandi/java-runner
