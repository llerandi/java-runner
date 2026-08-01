@echo off
REM ─────────────────────────────────────────────────────────────
REM  java-runner - run Java exercises without an IDE (Windows)
REM  Usage: runner.bat [File.java] [--watch] [--all] [--input f] [--classpath p] [--output f]
REM ─────────────────────────────────────────────────────────────

setlocal EnableDelayedExpansion

REM ── Enable ANSI colors ────────────────────────────────────────
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

set "RED=[31m"
set "GREEN=[32m"
set "YELLOW=[33m"
set "CYAN=[36m"
set "RESET=[0m"

set "FILE="
set "WATCH=false"
set "ALL=false"
set "INPUT_FILE="
set "EXTRA_CP="
set "OUTPUT_FILE="

REM ── Parse arguments ───────────────────────────────────────────
:parse_args
if "%~1"=="" goto :end_parse
if /i "%~1"=="--watch"     ( set "WATCH=true"               & shift & goto :parse_args )
if /i "%~1"=="--all"       ( set "ALL=true"                 & shift & goto :parse_args )
if /i "%~1"=="--input"     ( shift & set "INPUT_FILE=%~1"   & shift & goto :parse_args )
if /i "%~1"=="--classpath" ( shift & set "EXTRA_CP=%~1"     & shift & goto :parse_args )
if /i "%~1"=="--output"    ( shift & set "OUTPUT_FILE=%~1"  & shift & goto :parse_args )
if /i "%~1"=="--help"      goto :help
if /i "%~1"=="-h"          goto :help
if "%~x1"==".java"         ( set "FILE=%~1"                 & shift & goto :parse_args )
shift
goto :parse_args
:end_parse

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
      echo !YELLOW![INFO] No .java in current dir, searching examples\!RESET!
      for %%F in (examples\*.java) do (
        set "FILE=%%F"
        set /a count+=1
      )
    )
  )

  if "!count!"=="0" (
    echo !RED![ERROR] No .java file found in current directory or examples\!RESET!
    exit /b 1
  )
  if !count! GTR 1 (
    echo !YELLOW![WARNING] Multiple .java files found. Please specify one:!RESET!
    for %%F in (*.java) do echo   %%F
    if exist examples\ for %%F in (examples\*.java) do echo   %%F
    exit /b 1
  )
)

REM ── Validate file exists ──────────────────────────────────────
if not exist "%FILE%" (
  echo !RED![ERROR] File not found: %FILE%!RESET!
  exit /b 1
)

REM ── Watch mode ────────────────────────────────────────────────
if "%WATCH%"=="true" (
  echo !YELLOW![WATCH] Watch mode enabled - save the file to rerun!RESET!
  REM Capture initial timestamp
  for %%F in ("%FILE%") do set "LAST_MOD=%%~tF"
  cls
  call :run
  :watchloop
  timeout /t 2 /nobreak >nul
  for %%F in ("%FILE%") do set "CURR_MOD=%%~tF"
  if not "!CURR_MOD!"=="!LAST_MOD!" (
    set "LAST_MOD=!CURR_MOD!"
    cls
    call :run
  )
  goto :watchloop
)

call :run
exit /b

REM ── Help ──────────────────────────────────────────────────────
:help
echo Usage: runner.bat [File.java] [options]
echo.
echo Options:
echo   --watch            Recompile and rerun on every file change
echo   --all              Compile all .java files in the same directory together
echo   --input ^<file^>     Pipe file contents into stdin when running
echo   --classpath ^<path^> Append to the compile and run classpath
echo   --output ^<file^>    Save program output to file (also prints to terminal)
exit /b

REM ── Main run function ─────────────────────────────────────────
:run
  for %%F in ("%FILE%") do set "CLASSNAME=%%~nF"
  for %%F in ("%FILE%") do set "FILEDIR=%%~dpF"
  set "TMPDIR=%TEMP%\java-runner-%RANDOM%"
  mkdir "%TMPDIR%" 2>nul

  REM Build classpath
  if defined EXTRA_CP (
    set "CP=!TMPDIR!;!EXTRA_CP!"
    set "CP_FLAG=-cp "!EXTRA_CP!""
  ) else (
    set "CP=!TMPDIR!"
    set "CP_FLAG="
  )

  echo.
  echo !CYAN![....] Compiling !CLASSNAME!.java...!RESET!

  REM Choose sources: --all compiles every .java in the same directory
  if "!ALL!"=="true" (
    set "JAVA_FILES="
    for %%F in ("!FILEDIR!*.java") do set "JAVA_FILES=!JAVA_FILES! "%%~fF""
    javac !CP_FLAG! -d "!TMPDIR!" !JAVA_FILES! 2>"!TMPDIR!\errors.txt"
  ) else (
    javac !CP_FLAG! -d "!TMPDIR!" "%FILE%" 2>"!TMPDIR!\errors.txt"
  )

  if errorlevel 1 (
    echo !RED![FAIL] Compilation failed:!RESET!
    echo.
    type "!TMPDIR!\errors.txt"
    rmdir /s /q "!TMPDIR!"
    exit /b 1
  )

  echo !GREEN![ OK ] Compiled successfully!RESET!
  echo !CYAN!───────────────────────── output ─────────────────────────!RESET!

  set "START_TIME=%TIME%"

  REM Run java with optional input and output redirection
  if defined OUTPUT_FILE (
    set "TMPOUT=!TMPDIR!\output.txt"
    if defined INPUT_FILE (
      java -cp "!CP!" "!CLASSNAME!" < "!INPUT_FILE!" > "!TMPOUT!"
    ) else (
      java -cp "!CP!" "!CLASSNAME!" > "!TMPOUT!"
    )
    set "JAVA_EXIT=!ERRORLEVEL!"
    set "END_TIME=!TIME!"
    type "!TMPOUT!"
    copy "!TMPOUT!" "!OUTPUT_FILE!" >nul
  ) else (
    if defined INPUT_FILE (
      java -cp "!CP!" "!CLASSNAME!" < "!INPUT_FILE!"
    ) else (
      java -cp "!CP!" "!CLASSNAME!"
    )
    set "JAVA_EXIT=!ERRORLEVEL!"
    set "END_TIME=!TIME!"
  )

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

  echo !CYAN!───────────────────────────────────────────────────────────!RESET!
  if !JAVA_EXIT! NEQ 0 (
    echo !RED![FAIL] Finished in !ELAPSED_MS!ms ^(exit code !JAVA_EXIT!^)!RESET!
  ) else (
    echo !GREEN![ OK ] Finished in !ELAPSED_MS!ms!RESET!
    if defined OUTPUT_FILE echo !CYAN!   Output saved to: !OUTPUT_FILE!!RESET!
  )
  echo.

  rmdir /s /q "!TMPDIR!"
  exit /b !JAVA_EXIT!
