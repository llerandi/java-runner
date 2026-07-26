@echo off
REM ─────────────────────────────────────────────────────────────
REM  java-runner - run Java exercises without an IDE (Windows)
REM  Usage: runner.bat [File.java] [--watch]
REM ─────────────────────────────────────────────────────────────

setlocal EnableDelayedExpansion

set "FILE="
set "WATCH=false"

REM ── Parse arguments ───────────────────────────────────────────
for %%A in (%*) do (
  if "%%A"=="--watch" set "WATCH=true"
  if "%%~xA"==".java" set "FILE=%%A"
  if "%%A"=="--help" goto :help
  if "%%A"=="-h" goto :help
)

REM ── Auto-detect .java file ────────────────────────────────────
if "%FILE%"=="" (
  set "count=0"
  for %%F in (*.java) do (
    set "FILE=%%F"
    set /a count+=1
  )

  REM If none found in current dir, fall back to examples\
  if "!count!"=="0" (
    if exist examples\ (
      echo [INFO] No .java in current dir, searching examples\
      for %%F in (examples\*.java) do (
        set "FILE=%%F"
        set /a count+=1
      )
    )
  )

  if "!count!"=="0" (
    echo [ERROR] No .java file found in current directory or examples\
    exit /b 1
  )
  if !count! GTR 1 (
    echo [WARNING] Multiple .java files found. Please specify one:
    for %%F in (*.java) do echo   %%F
    if exist examples\ for %%F in (examples\*.java) do echo   %%F
    exit /b 1
  )
)

REM ── Validate file exists ──────────────────────────────────────
if not exist "%FILE%" (
  echo [ERROR] File not found: %FILE%
  exit /b 1
)

REM ── Watch mode ────────────────────────────────────────────────
if "%WATCH%"=="true" (
  echo [WATCH] Watch mode enabled - save the file to rerun
  :watchloop
  call :run
  echo [WATCH] Waiting for changes... Press Ctrl+C to stop.
  REM Poll every 2 seconds (Windows has no native inotify)
  timeout /t 2 /nobreak >nul
  goto :watchloop
)

call :run
exit /b

REM ── Help ──────────────────────────────────────────────────────
:help
echo Usage: runner.bat [File.java] [--watch]
echo   File.java   Java file to compile and run
echo   --watch     Recompile and rerun every 2 seconds
exit /b

REM ── Main run function ─────────────────────────────────────────
:run
  for %%F in ("%FILE%") do set "CLASSNAME=%%~nF"
  set "TMPDIR=%TEMP%\java-runner-%RANDOM%"
  mkdir "%TMPDIR%" 2>nul

  echo.
  echo [....] Compiling %CLASSNAME%.java...

  javac -d "%TMPDIR%" "%FILE%" 2>"%TMPDIR%\errors.txt"
  if errorlevel 1 (
    echo [FAIL] Compilation failed:
    echo.
    type "%TMPDIR%\errors.txt"
    rmdir /s /q "%TMPDIR%"
    exit /b 1
  )

  echo [ OK ] Compiled successfully
  echo ───────────────────────── output ─────────────────────────

  set "START_TIME=%TIME%"
  java -cp "%TMPDIR%" "%CLASSNAME%"
  set "END_TIME=%TIME%"

  echo ───────────────────────────────────────────────────────────
  echo [ OK ] Done
  echo.

  rmdir /s /q "%TMPDIR%"
  exit /b
