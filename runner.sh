#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  java-runner - run Java exercises without an IDE
#  Usage: ./runner.sh [File.java] [--watch] [--all] [--input f] [--classpath p] [--output f]
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
ALL=false
INPUT_FILE=""
EXTRA_CP=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --watch)     WATCH=true ;;
    --all)       ALL=true ;;
    --input)     INPUT_FILE="$2"; shift ;;
    --classpath) EXTRA_CP="$2"; shift ;;
    --output)    OUTPUT_FILE="$2"; shift ;;
    --help|-h)
      echo "Usage: ./runner.sh [File.java] [options]"
      echo ""
      echo "Options:"
      echo "  --watch            Recompile and rerun on every file save"
      echo "  --all              Compile all .java files in the same directory together"
      echo "  --input <file>     Pipe file contents into stdin when running"
      echo "  --classpath <path> Append to the compile and run classpath"
      echo "  --output <file>    Save program output to file (also prints to terminal)"
      exit 0
      ;;
    *.java) FILE="$1" ;;
    *) echo -e "${RED}✗  Unknown argument: $1${RESET}"; exit 1 ;;
  esac
  shift
done

# ── Auto-detect .java file ────────────────────────────────────
if [[ -z "$FILE" ]]; then
  found=()
  while IFS= read -r f; do found+=("$f"); done < <(find . -maxdepth 1 -name "*.java")

  # If none in current dir, fall back to examples/
  if [[ ${#found[@]} -eq 0 ]] && [[ -d "./examples" ]]; then
    while IFS= read -r f; do found+=("$f"); done < <(find ./examples -maxdepth 1 -name "*.java")
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
  local filedir
  filedir=$(dirname "$FILE")
  local tmpdir
  tmpdir=$(mktemp -d)

  # Build classpath
  local cp="$tmpdir"
  [[ -n "$EXTRA_CP" ]] && cp="$cp:$EXTRA_CP"

  echo -e ""
  echo -e "${CYAN}▶  Compiling ${classname}.java...${RESET}"

  # Choose sources: --all compiles every .java in the same directory
  local sources
  if $ALL; then
    sources=("$filedir"/*.java)
  else
    sources=("$FILE")
  fi

  if ! javac ${EXTRA_CP:+-cp "$EXTRA_CP"} -d "$tmpdir" "${sources[@]}" 2>"$tmpdir/errors.txt"; then
    echo -e "${RED}✗  Compilation failed:${RESET}\n"
    sed "s|$PWD/||g" "$tmpdir/errors.txt"
    rm -rf "$tmpdir"
    return 1
  fi

  echo -e "${GREEN}✓  Compiled successfully${RESET}"
  echo -e "${CYAN}───────────────────────── output ─────────────────────────${RESET}"

  # Run and measure time
  local start
  start=$(date +%s%N 2>/dev/null || date +%s)

  local java_exit
  set +e
  if [[ -n "$INPUT_FILE" && -n "$OUTPUT_FILE" ]]; then
    java -cp "$cp" "$classname" < "$INPUT_FILE" | tee "$OUTPUT_FILE"
    java_exit=${PIPESTATUS[0]}
  elif [[ -n "$INPUT_FILE" ]]; then
    java -cp "$cp" "$classname" < "$INPUT_FILE"
    java_exit=$?
  elif [[ -n "$OUTPUT_FILE" ]]; then
    java -cp "$cp" "$classname" | tee "$OUTPUT_FILE"
    java_exit=${PIPESTATUS[0]}
  else
    java -cp "$cp" "$classname"
    java_exit=$?
  fi
  set -e

  local end
  end=$(date +%s%N 2>/dev/null || date +%s)

  # Calculate elapsed
  local elapsed
  if [[ ${#start} -gt 10 ]]; then
    elapsed=$(( (end - start) / 1000000 ))
    echo -e "${CYAN}───────────────────────────────────────────────────────────${RESET}"
    if [[ $java_exit -ne 0 ]]; then
      echo -e "${RED}✗  Finished in ${elapsed}ms (exit code ${java_exit})${RESET}\n"
    else
      echo -e "${GREEN}✓  Finished in ${elapsed}ms${RESET}\n"
      [[ -n "$OUTPUT_FILE" ]] && echo -e "${CYAN}   Output saved to: ${OUTPUT_FILE}${RESET}"
    fi
  else
    elapsed=$(( end - start ))
    echo -e "${CYAN}───────────────────────────────────────────────────────────${RESET}"
    if [[ $java_exit -ne 0 ]]; then
      echo -e "${RED}✗  Finished in ${elapsed}s (exit code ${java_exit})${RESET}\n"
    else
      echo -e "${GREEN}✓  Finished in ${elapsed}s${RESET}\n"
      [[ -n "$OUTPUT_FILE" ]] && echo -e "${CYAN}   Output saved to: ${OUTPUT_FILE}${RESET}"
    fi
  fi

  rm -rf "$tmpdir"
  return $java_exit
}

# ── Watch mode ────────────────────────────────────────────────
if $WATCH; then
  echo -e "${YELLOW}👁  Watch mode enabled - save the file to rerun${RESET}"
  clear
  run || true

  if [[ "$PLATFORM" == "linux" ]]; then
    if ! command -v inotifywait &>/dev/null; then
      echo -e "${RED}✗  inotifywait not found. Install it with: sudo apt install inotify-tools${RESET}"
      exit 1
    fi
    while inotifywait -q -e close_write "$FILE"; do
      clear
      run || true
    done

  elif [[ "$PLATFORM" == "mac" ]]; then
    if ! command -v fswatch &>/dev/null; then
      echo -e "${RED}✗  fswatch not found. Install it with: brew install fswatch${RESET}"
      exit 1
    fi
    fswatch -o "$FILE" | while read -r; do
      clear
      run || true
    done

  else
    echo -e "${RED}✗  Watch mode is not supported on this platform${RESET}"
    exit 1
  fi

else
  run
fi
