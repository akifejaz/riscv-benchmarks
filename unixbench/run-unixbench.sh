# ==============================================================================
# UnixBench CPU Benchmark - Automation Script
#
# Description:
#   Automates installing dependencies, fetching, building, and running the
#   UnixBench CPU benchmark on RISC-V linux.
#
#   UnixBench is a classic CPU and system benchmark suite for Unix-like systems,
#   measuring a variety of system and CPU performance metrics.
#
# Usage:
#   bash run-unixbench.sh
#
# Author:
#   Akif Ejaz | github.com/akifejaz
# ==============================================================================

set -euo pipefail

install_dependencies() {
    log "Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y build-essential perl make gcc g++ || error "Failed to install dependencies"
    log "Dependencies installed successfully."
}

fetch_unixbench() {
    log "Fetching UnixBench repository..."
    mkdir -p "$HOME/projects"
    cd "$HOME/projects"
    if [ ! -d byte-unixbench ]; then
        git clone https://github.com/kdlucas/byte-unixbench.git || error "Failed to clone UnixBench repo"
    else
        cd byte-unixbench
        git pull || error "Failed to update UnixBench repo"
        cd ..
    fi
    log "UnixBench repository ready."
}


run_unixbench() {
    log "Building and running UnixBench..."
    cd "$HOME/projects/byte-unixbench/UnixBench" || error "UnixBench directory not found"
    make || error "Build failed"
    ./Run "$@" 2>&1 | tee -a "$LOG_FILE"
    log "UnixBench run completed. Results saved to $LOG_FILE"
}

main() {
    log "Starting UnixBench automation script. Log: $LOG_FILE"
    install_dependencies
    fetch_unixbench
    run_unixbench "$@"
    log "UnixBench benchmark completed successfully."
}

main "$@"
