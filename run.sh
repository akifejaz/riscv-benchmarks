#!/bin/bash

set -euo pipefail

# ===================== CONFIGURATION =====================
LOG_DIR="$PWD/logs"
BENCHMARKS=(coremark spec2017 phoronix geekbench unixbench)
GLOBAL_DEPS=(bash git tee date curl tar find)

# ===================== LOGGING & HELPERS =====================
export RED='\033[0;31m'; export GREEN='\033[0;32m'; export YELLOW='\033[1;33m'; export BLUE='\033[0;34m'; export NC='\033[0m'

log() {
    mkdir -p "$LOG_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] ${*:2}" | tee -a "$LOG_FILE"
    case $1 in
        ERROR)   echo -e "${RED}[ERROR]${NC} ${*:2}" >&2 ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} ${*:2}" ;;
        WARNING) echo -e "${YELLOW}[WARNING]${NC} ${*:2}" ;;
        *)       echo -e "${BLUE}[INFO]${NC} ${*:2}" ;;
    esac
}
export -f log

die() { log ERROR "$@"; exit 1; }
export -f die

check_sudo() {
    log INFO "Checking sudo privileges..."
    [[ $EUID -eq 0 ]] || die "Must run with sudo: sudo $0"
    export USER="${SUDO_USER:-$(whoami)}"
}
export -f check_sudo

usage() {
    echo "Usage: $0 <benchmark>" | tee -a "$LOG_FILE"
    echo -n "Available benchmarks: " | tee -a "$LOG_FILE"
    printf "%s " "${BENCHMARKS[@]}" | tee -a "$LOG_FILE"
    echo | tee -a "$LOG_FILE"
    exit 1
}

check_global_dependencies() {
    log INFO "Checking global dependencies..."
    for dep in "${GLOBAL_DEPS[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            die "Required dependency '$dep' is not installed."
        fi
    done
    log SUCCESS "All global dependencies are satisfied."
}

main() {
    if [[ $# -ne 1 ]]; then
        mkdir -p "$LOG_DIR"
        LOG_FILE="$LOG_DIR/benchmark_$(date +%Y%m%d_%H%M%S).log"
        usage
    fi

    BENCHMARK="$1"
    LOG_FILE="$LOG_DIR/${BENCHMARK}_$(date +%Y%m%d_%H%M%S).log"

    check_global_dependencies
    log INFO "Starting benchmark: $BENCHMARK"

    case "$BENCHMARK" in
        coremark)
            LOG_FILE="$LOG_FILE" LOG_DIR="$LOG_DIR" bash coremark/run-coremark.sh 2>&1 | tee -a "$LOG_FILE"
            ;;
        spec2017)
            LOG_FILE="$LOG_FILE" LOG_DIR="$LOG_DIR" bash spec2017/run-spec.sh 2>&1 | tee -a "$LOG_FILE"
            ;;
        phoronix)
            LOG_FILE="$LOG_FILE" LOG_DIR="$LOG_DIR" bash phoronix-test-suite/run-phoronix.sh 2>&1 | tee -a "$LOG_FILE"
            ;;
        geekbench)
            LOG_FILE="$LOG_FILE" LOG_DIR="$LOG_DIR" bash geekbench/run-geekbench.sh 2>&1 | tee -a "$LOG_FILE"
            ;;
        unixbench)
            LOG_FILE="$LOG_FILE" LOG_DIR="$LOG_DIR" bash unixbench/run-unixbench.sh 2>&1 | tee -a "$LOG_FILE"
            ;;
        *)
            usage
            ;;
    esac

    log SUCCESS "Benchmark '$BENCHMARK' completed. See $LOG_FILE for details."
}

main "$@"
