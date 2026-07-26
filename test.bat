@echo off
REM ─────────────────────────────────────────────────────────────
REM  test.bat - run tests for runner.bat
REM  Usage: test.bat
REM ─────────────────────────────────────────────────────────────

setlocal EnableDelayedExpansion

set "RUNNER=runner.bat"
set "PASS=0"
set "FAIL=0"

REM ── Test: successful run exits 0 ──────────────────────────────
call %RUNNER% examples\HelloWorld.java >"%TEMP%\runner_out.txt" 2>&1
if !ERRORLEVEL! EQU 0 (
  call :pass "successful run exits 0"
) else (
  call :fail "successful run exits 0"
)

REM ── Test: successful run prints expected output ───────────────
findstr /C:"Hello, World" "%TEMP%\runner_out.txt" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
  call :pass "successful run prints expected output"
) else (
  call :fail "successful run prints expected output"
)

REM ── Test: successful run shows elapsed time ───────────────────
findstr /R "Finished in [0-9]*ms" "%TEMP%\runner_out.txt" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
  call :pass "successful run shows elapsed time"
) else (
  call :fail "successful run shows elapsed time"
)

REM ── Test: compile error exits non-zero ────────────────────────
call %RUNNER% tests\CompileError.java >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
  call :pass "compile error exits non-zero"
) else (
  call :fail "compile error exits non-zero"
)

REM ── Test: compile error prints 'Compilation failed' ──────────
call %RUNNER% tests\CompileError.java >"%TEMP%\runner_out.txt" 2>&1
findstr /C:"Compilation failed" "%TEMP%\runner_out.txt" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
  call :pass "compile error prints 'Compilation failed'"
) else (
  call :fail "compile error prints 'Compilation failed'"
)

REM ── Test: runtime error exits non-zero ────────────────────────
call %RUNNER% tests\RuntimeError.java >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
  call :pass "runtime error exits non-zero"
) else (
  call :fail "runtime error exits non-zero"
)

REM ── Test: runtime error shows exit code in output ────────────
call %RUNNER% tests\RuntimeError.java >"%TEMP%\runner_out.txt" 2>&1
findstr /C:"exit code" "%TEMP%\runner_out.txt" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
  call :pass "runtime error shows exit code in output"
) else (
  call :fail "runtime error shows exit code in output"
)

REM ── Test: missing file exits non-zero ─────────────────────────
call %RUNNER% tests\DoesNotExist.java >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
  call :pass "missing file exits non-zero"
) else (
  call :fail "missing file exits non-zero"
)

REM ── Summary ───────────────────────────────────────────────────
echo.
echo Results: !PASS! passed, !FAIL! failed
if !FAIL! EQU 0 (exit /b 0) else (exit /b 1)

:pass
  echo [PASS] %~1
  set /a PASS+=1
  exit /b

:fail
  echo [FAIL] %~1
  set /a FAIL+=1
  exit /b
