#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  java-runner - run Java exercises without an IDE
#  Usage: ./runner.sh [File.java] [--watch]
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ── Detect OS ─────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Linux*)  PLATFORM="linux" ;;
  Darwin*) PLATFORM="mac" ;;
  *)       PLATFORM="unknown" ;;
esac

# ── Arguments ─────────────────────────────────────────────────
FILE=""
WATCH=false

for arg in "$@"; do
  case $arg in
    --watch) WATCH=true ;;
    *.java)  FILE="$arg" ;;
    --help|-h)
      echo -e "Usage: ./runner.sh [File.java] [--watch]"
      echo -e "  File.java   Java file to compile and run (optional if only one .java exists)"
      echo -e "  --watch     Recompile and rerun on every file save"
      exit 0
      ;;
  esac
done

# ── Auto-detect .java file ────────────────────────────────────
if [[ -z "$FILE" ]]; then
  mapfile -t found < <(find . -maxdepth 1 -name "*.java")

  # If none in current dir, fall back to examples/
  if [[ ${#found[@]} -eq 0 ]] && [[ -d "./examples" ]]; then
    mapfile -t found < <(find ./examples -maxdepth 1 -name "*.java")
    [[ ${#found[@]} -gt 0 ]] && echo -e "${YELLOW}⚠ No .java in current dir, searching examples/${RESET}"
  fi

  if [[ ${#found[@]} -eq 1 ]]; then
    FILE="${found[0]}"
  elif [[ ${#found[@]} -eq 0 ]]; then
    echo -e "${RED}✗ No .java file found in current directory or examples/${RESET}"
    exit 1
  else
    echo -e "${YELLOW}⚠ Multiple .java files found. Please specify one:${RESET}"
    printf '  %s\n' "${found[@]}"
    exit 1
  fi
fi

# ── Validate file exists ──────────────────────────────────────
if [[ ! -f "$FILE" ]]; then
  echo -e "${RED}✗ File not found: $FILE${RESET}"
  exit 1
fi

# ── Main run function ─────────────────────────────────────────
run() {
  local classname
  classname=$(basename "$FILE" .java)
  local tmpdir
  tmpdir=$(mktemp -d)

  echo -e ""
  echo -e "${CYAN}▶  Compiling ${classname}.java...${RESET}"

  # Compile - capture errors
  if ! javac -d "$tmpdir" "$FILE" 2>"$tmpdir/errors.txt"; then
    echo -e "${RED}✗  Compilation failed:${RESET}\n"
    # Strip absolute path noise
    sed "s|$PWD/||g" "$tmpdir/errors.txt"
    rm -rf "$tmpdir"
    return 1
  fi

  echo -e "${GREEN}✓  Compiled successfully${RESET}"
  echo -e "${CYAN}───────────────────────── output ─────────────────────────${RESET}"

  # Run and measure time
  local start
  start=$(date +%s%N 2>/dev/null || date +%s)
  set +e
  java -cp "$tmpdir" "$classname"
  local java_exit=$?
  set -e
  local end
  end=$(date +%s%N 2>/dev/null || date +%s)

  # Calculate elapsed (nanoseconds if available, else seconds)
  local elapsed
  if [[ ${#start} -gt 10 ]]; then
    elapsed=$(( (end - start) / 1000000 ))
    echo -e "${CYAN}───────────────────────────────────────────────────────────${RESET}"
    if [[ $java_exit -ne 0 ]]; then
      echo -e "${RED}✗  Finished in ${elapsed}ms (exit code ${java_exit})${RESET}\n"
    else
      echo -e "${GREEN}✓  Finished in ${elapsed}ms${RESET}\n"
    fi
  else
    elapsed=$(( end - start ))
    echo -e "${CYAN}───────────────────────────────────────────────────────────${RESET}"
    if [[ $java_exit -ne 0 ]]; then
      echo -e "${RED}✗  Finished in ${elapsed}s (exit code ${java_exit})${RESET}\n"
    else
      echo -e "${GREEN}✓  Finished in ${elapsed}s${RESET}\n"
    fi
  fi

  rm -rf "$tmpdir"
  return $java_exit
}

# ── Watch mode ────────────────────────────────────────────────
if $WATCH; then
  echo -e "${YELLOW}👁  Watch mode enabled - save the file to rerun${RESET}"
  run || true

  if [[ "$PLATFORM" == "linux" ]]; then
    if ! command -v inotifywait &>/dev/null; then
      echo -e "${RED}✗  inotifywait not found. Install it with: sudo apt install inotify-tools${RESET}"
      exit 1
    fi
    while inotifywait -q -e close_write "$FILE"; do
      echo -e "\n${YELLOW}↻  Change detected...${RESET}"
      run || true
    done

  elif [[ "$PLATFORM" == "mac" ]]; then
    if ! command -v fswatch &>/dev/null; then
      echo -e "${RED}✗  fswatch not found. Install it with: brew install fswatch${RESET}"
      exit 1
    fi
    fswatch -o "$FILE" | while read -r; do
      echo -e "\n${YELLOW}↻  Change detected...${RESET}"
      run || true
    done

  else
    echo -e "${RED}✗  Watch mode is not supported on this platform${RESET}"
    exit 1
  fi

else
  run
fi
