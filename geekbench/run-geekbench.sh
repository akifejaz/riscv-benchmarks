# Gist url : https://gist.github.com/akifejaz/41aacdbfd3334aec601948f5ccc385b2/raw

#!/bin/bash
# ==============================================================================
# GeekBench 6 CPU Benchmark - Automation Script
#
# Description:
#   Automates downloading, extracting, and running the GeekBench 6 CPU benchmark
#   on RISC-V architecture. The script checks dependencies, sets up a workspace,
#   downloads the latest RISC-V preview, extracts it, and runs the CPU benchmark.
#   Results are saved to a log file for review.
#
#   GeekBench 6 is a cross-platform CPU benchmark that measures your system's
#   single-core and multi-core performance using tests modeled on real-world tasks.
#
# Usage:
#   bash run-geekbench.sh
#
# Author:
#   Akif Ejaz | github.com/akifejaz
# ==============================================================================


set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
# TODO: Double check / change for other versions or if link doesnt work.
readonly GEEKBENCH_URL="https://cdn.geekbench.com/Geekbench-6.4.0-LinuxRISCVPreview.tar.gz"
readonly GEEKBENCH_ARCHIVE="geekbench-riscv.tar.gz"
readonly GEEKBENCH_DIR="geekbench-riscv"
readonly PROJECTS_DIR="$HOME/projects"
readonly LOG_FILE="logs.txt"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

check_dependencies() {
    local deps=("curl" "tar" "find")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || error "$dep is not installed"
    done
}

setup_workspace() {
    log "Setting up workspace in $PROJECTS_DIR"
    mkdir -p "$PROJECTS_DIR"
    cd "$PROJECTS_DIR"
}

download_geekbench() {
    log "Downloading GeekBench 6 RISC-V from $GEEKBENCH_URL"
    if [[ -f "$GEEKBENCH_ARCHIVE" ]]; then
        log "Archive already exists, skipping download"
        return 0
    fi
    
    curl -L -o "$GEEKBENCH_ARCHIVE" "$GEEKBENCH_URL" || error "Failed to download GeekBench archive"
    log "Download completed successfully"
}

extract_archive() {
    log "Extracting $GEEKBENCH_ARCHIVE"
    mkdir -p "$GEEKBENCH_DIR"
    tar -xf "$GEEKBENCH_ARCHIVE" -C "$GEEKBENCH_DIR" || error "Failed to extract archive"
    log "Extraction completed"
}

run_benchmark() {
    log "Starting GeekBench 6 CPU benchmark"
    cd "$GEEKBENCH_DIR"
    
    local geekbench_binary
    geekbench_binary=$(find . -name "geekbench6" -type f -executable 2>/dev/null | head -1)
    
    if [[ -z "$geekbench_binary" ]]; then
        error "GeekBench 6 binary not found in extracted archive"
    fi
    
    log "Found GeekBench binary: $geekbench_binary"
    log "Running CPU benchmark (output will be saved to $LOG_FILE)"
    
    "$geekbench_binary" --cpu 2>&1 | tee "$LOG_FILE" || error "Benchmark execution failed"
    
    log "Benchmark completed successfully"
    log "Results saved to: $PWD/$LOG_FILE"
}

main() {
    log "Starting $SCRIPT_NAME"
    
    check_dependencies
    setup_workspace
    download_geekbench
    extract_archive
    run_benchmark
    
    log "GeekBench 6 RISC-V benchmark completed successfully"
}

main "$@"