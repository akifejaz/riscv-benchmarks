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

CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
# EDIT: Change this URL to update Geekbench version or architecture as needed
readonly GEEKBENCH_URL="https://cdn.geekbench.com/Geekbench-6.4.0-LinuxRISCVPreview.tar.gz"
readonly GEEKBENCH_ARCHIVE="geekbench-riscv.tar.gz"
readonly GEEKBENCH_DIR="geekbench-riscv"

setup_workspace() {
    cd $CURR_DIR
}

download_geekbench() {
    log INFO "Downloading GeekBench 6 RISC-V from $GEEKBENCH_URL"
    if [[ -f "$GEEKBENCH_ARCHIVE" ]]; then
        log INFO "Archive already exists, skipping download"
        return 0
    fi
    
    curl -L -o "$GEEKBENCH_ARCHIVE" "$GEEKBENCH_URL" || die "Failed to download GeekBench archive"
    log SUCCESS "Download completed successfully"
}

extract_archive() {
    log INFO "Extracting $GEEKBENCH_ARCHIVE"
    mkdir -p "$GEEKBENCH_DIR"
    tar -xf "$GEEKBENCH_ARCHIVE" -C "$GEEKBENCH_DIR" || die "Failed to extract archive"
    log SUCCESS "Extraction completed"
}

run_benchmark() {
    log INFO "Starting GeekBench 6 CPU benchmark"
    cd "$GEEKBENCH_DIR"
    
    local geekbench_binary
    geekbench_binary=$(find . -name "geekbench6" -type f -executable 2>/dev/null | head -1)
    
    if [[ -z "$geekbench_binary" ]]; then
        die "GeekBench 6 binary not found in extracted archive"
    fi
    
    log INFO "Found GeekBench binary: $geekbench_binary"
    log INFO "Running CPU benchmark (output will be saved to $LOG_FILE)"
    
    "$geekbench_binary" --cpu 2>&1 | tee "$LOG_FILE" || die "Benchmark execution failed"
    
    log SUCCESS "Benchmark completed successfully"
    log INFO "Results saved to: $LOG_FILE"
}

main() {
    log INFO "Starting $SCRIPT_NAME"
    
    setup_workspace
    download_geekbench
    extract_archive
    run_benchmark
    
    log SUCCESS "GeekBench 6 RISC-V benchmark completed successfully"
}

main "$@"