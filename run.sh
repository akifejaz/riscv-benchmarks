#!/bin/bash

set -euo pipefail

LOG_DIR="logs"

if [ $# -ne 1 ]; then
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/benchmark_$(date +%Y%m%d_%H%M%S).log"
  echo "Usage: $0 <benchmark>" | tee -a "$LOG_FILE"
  echo "Available benchmarks: coremark, spec2017, phoronix, geekbench, unixbench" | tee -a "$LOG_FILE"
  exit 1
fi

BENCHMARK="$1"
LOG_FILE="$LOG_DIR/${BENCHMARK}_$(date +%Y%m%d_%H%M%S).log"

# List of global dependencies (not checked by sub-scripts)
GLOBAL_DEPS=("bash" "git" "tee" "date")

usage() {
  echo "Usage: $0 <benchmark>" | tee -a "$LOG_FILE"
  echo "Available benchmarks: coremark, spec2017, phoronix, geekbench, unixbench" | tee -a "$LOG_FILE"
  exit 1
}

log() {
  mkdir -p "$LOG_DIR"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

check_global_dependencies() {
  log "Checking global dependencies..."
  for dep in "${GLOBAL_DEPS[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      log "ERROR: Required dependency '$dep' is not installed."
      exit 1
    fi
  done
  log "All global dependencies are satisfied."
}

check_global_dependencies
log "Starting benchmark: $BENCHMARK"

case "$BENCHMARK" in
  coremark)
    bash coremark/run-coremark.sh 2>&1 | tee -a "$LOG_FILE"
    ;;
  spec2017)
    bash spec2017/run-spec.sh 2>&1 | tee -a "$LOG_FILE"
    ;;
  phoronix)
    bash phoronix-test-suite/run-phoronix.sh 2>&1 | tee -a "$LOG_FILE"
    ;;
  geekbench)
    bash geekbench/run-geekbench.sh 2>&1 | tee -a "$LOG_FILE"
    ;;
  unixbench)
    bash unixbench/run-unixbench.sh 2>&1 | tee -a "$LOG_FILE"
    ;;
  *)
    usage
    ;;
esac

log "Benchmark '$BENCHMARK' completed. See $LOG_FILE for details."
