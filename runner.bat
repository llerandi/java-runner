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
  REM Capture initial timestamp
  for %%F in ("%FILE%") do set "LAST_MOD=%%~tF"
  call :run
  :watchloop
  echo [WATCH] Waiting for changes... Press Ctrl+C to stop.
  timeout /t 2 /nobreak >nul
  for %%F in ("%FILE%") do set "CURR_MOD=%%~tF"
  if not "!CURR_MOD!"=="!LAST_MOD!" (
    set "LAST_MOD=!CURR_MOD!"
    echo [WATCH] Change detected...
    call :run
  )
  goto :watchloop
)

call :run
exit /b

REM ── Help ──────────────────────────────────────────────────────
:help
echo Usage: runner.bat [File.java] [--watch]
echo   File.java   Java file to compile and run
echo   --watch     Recompile and rerun on every file change
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
  set "JAVA_EXIT=%ERRORLEVEL%"
  set "END_TIME=%TIME%"

  REM Parse start time (HH:MM:SS.cc)
  for /f "tokens=1-4 delims=:,. " %%a in ("!START_TIME!") do (
    set /a "START_MS=(1%%a-100)*3600000 + (1%%b-100)*60000 + (1%%c-100)*1000 + (1%%d-100)*10"
  )
  REM Parse end time
  for /f "tokens=1-4 delims=:,. " %%a in ("!END_TIME!") do (
    set /a "END_MS=(1%%a-100)*3600000 + (1%%b-100)*60000 + (1%%c-100)*1000 + (1%%d-100)*10"
  )
  set /a "ELAPSED_MS=END_MS-START_MS"
  if !ELAPSED_MS! LSS 0 set /a "ELAPSED_MS+=86400000"

  echo ───────────────────────────────────────────────────────────
  if !JAVA_EXIT! NEQ 0 (
    echo [FAIL] Finished in !ELAPSED_MS!ms ^(exit code !JAVA_EXIT!^)
  ) else (
    echo [ OK ] Finished in !ELAPSED_MS!ms
  )
  echo.

  rmdir /s /q "%TMPDIR%"
  exit /b !JAVA_EXIT!
