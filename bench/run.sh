#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================"
echo "  CakeSpark vs Python Benchmark"
echo "============================================"
echo ""

# Build CakeSpark binary
if [ ! -f "$PROJECT_DIR/cakespark" ]; then
  echo "[build] Compiling CakeSpark..."
  nim c --path:src -o:"$PROJECT_DIR/cakespark" "$PROJECT_DIR/src/cakespark.nim"
  echo ""
fi

# CakeSpark benchmark
echo "--- CakeSpark ---"
CS_OUTPUT=$(time ( "$PROJECT_DIR/cakespark" "$SCRIPT_DIR/bench.cake" ) 2>&1)
CS_TIME=$(echo "$CS_OUTPUT" | grep -E '^real' | awk '{print $2}')
echo "$CS_OUTPUT" | grep -v '^real\|^user\|^sys\|^ '
echo "  CakeSpark wall time: $CS_TIME"
echo ""

# Python benchmark
echo "--- Python ---"
PY_OUTPUT=$(time ( python3 "$SCRIPT_DIR/bench.py" ) 2>&1)
PY_TIME=$(echo "$PY_OUTPUT" | grep -E '^real' | awk '{print $2}')
PY_SELF=$(echo "$PY_OUTPUT" | grep "Python elapsed" | awk '{print $3}')
echo "$PY_OUTPUT" | grep -v '^real\|^user\|^sys\|^ '
echo "  Python wall time:    $PY_TIME"
echo "  Python self-reported: $PY_SELF"
echo ""

echo "============================================"
echo "  Benchmark Complete"
echo "============================================"
