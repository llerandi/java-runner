#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  test.sh - run tests for runner.sh
#  Usage: ./test.sh
# ─────────────────────────────────────────────────────────────

set -uo pipefail

RUNNER="./runner.sh"
PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

pass() { echo -e "${GREEN}PASS${RESET} $1"; ((PASS++)); }
fail() { echo -e "${RED}FAIL${RESET} $1"; ((FAIL++)); }

# ── Test: successful run exits 0 ──────────────────────────────
output=$("$RUNNER" examples/HelloWorld.java 2>&1)
code=$?
if [[ $code -eq 0 ]]; then
  pass "successful run exits 0"
else
  fail "successful run exits 0 (got $code)"
fi

# ── Test: successful run prints expected output ───────────────
if echo "$output" | grep -q "Hello, World"; then
  pass "successful run prints expected output"
else
  fail "successful run prints expected output"
fi

# ── Test: successful run shows elapsed time ───────────────────
if echo "$output" | grep -qE "Finished in [0-9]+ms"; then
  pass "successful run shows elapsed time"
else
  fail "successful run shows elapsed time"
fi

# ── Test: compile error exits non-zero ────────────────────────
"$RUNNER" tests/CompileError.java >/dev/null 2>&1
code=$?
if [[ $code -ne 0 ]]; then
  pass "compile error exits non-zero"
else
  fail "compile error exits non-zero (got 0)"
fi

# ── Test: compile error prints 'Compilation failed' ──────────
output=$("$RUNNER" tests/CompileError.java 2>&1 || true)
if echo "$output" | grep -q "Compilation failed"; then
  pass "compile error prints 'Compilation failed'"
else
  fail "compile error prints 'Compilation failed'"
fi

# ── Test: runtime error exits non-zero ───────────────────────
"$RUNNER" tests/RuntimeError.java >/dev/null 2>&1
code=$?
if [[ $code -ne 0 ]]; then
  pass "runtime error exits non-zero"
else
  fail "runtime error exits non-zero (got 0)"
fi

# ── Test: runtime error shows exit code in output ────────────
output=$("$RUNNER" tests/RuntimeError.java 2>&1 || true)
if echo "$output" | grep -qE "exit code [0-9]+"; then
  pass "runtime error shows exit code in output"
else
  fail "runtime error shows exit code in output"
fi

# ── Test: missing file exits non-zero ────────────────────────
"$RUNNER" tests/DoesNotExist.java >/dev/null 2>&1
code=$?
if [[ $code -ne 0 ]]; then
  pass "missing file exits non-zero"
else
  fail "missing file exits non-zero (got 0)"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
