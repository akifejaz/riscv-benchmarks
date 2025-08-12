# Gist url : https://gist.githubusercontent.com/akifejaz/bbfd96c8ded8205ffa586657f7910339/raw

#!/bin/bash
# ==============================================================================
# CoreMark CPU Benchmark - Automation Script
#
# Description:
#   Automates building and running the EEMBC CoreMark benchmark in both
#   single-threaded (ST) and multi-threaded (MT) modes, capturing results for
#   multiple iteration counts and averaging them for accuracy.
#
#   CoreMark is a small, portable CPU benchmark designed to measure core
#   performance using a representative mix of integer workloads:
#     - Linked list processing
#     - Matrix operations
#     - State-machine processing
#     - CRC checks
#
#   The benchmark runs a given number of iterations (N) and reports throughput
#   in Iterations/Sec. To improve reliability, in this script each N is run multiple times (n)
#   and the mean is calculated to smooth out fluctuations.
#
# Usage:
#   bash run-coremark.sh
#
# Author:
#   Akif Ejaz | github.com/akifejaz
# ==============================================================================

set -euo pipefail

CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="$CURR_DIR/results"

# Here calling N as ITERATIONS and n as RUNS_PER_ITER 
ITERATIONS=(200000 400000 1000000 2000000 4000000 8000000)
RUNS_PER_ITER=5

# ===================== UTILITIES =====================
get_ips()      { grep "Iterations/Sec" "$1" | awk -F':' '{print $2}' | xargs; }
get_time()     { grep "Total time (secs)" "$1" | awk -F':' '{print $2}' | xargs; }
get_compiler() { grep "Compiler version" "$1" | awk -F':' '{print $2}' | xargs; }
get_correct()  { grep -q "Correct operation validated" "$1" && echo 1 || echo 0; }


build_coremark() {
    cd "$CURR_DIR"
    echo "== Cloning CoreMark repository =="
    git clone https://github.com/eembc/coremark.git 2>/dev/null || \
        echo "Repo already exists, skipping clone."
    cd "$CURR_DIR/coremark" && \
    mkdir -p coremark-st coremark-mt

    echo "== Building Single-Core CoreMark =="
    make \
        OPATH=coremark-st/ \
        ITERATIONS=8000 \
        CC=gcc \
        PORT_DIR=linux/ \
        XCFLAGS="-DPERFORMANCE_RUN=1" &> /dev/null || \
        echo "CoreMark Single Core Build failed"

    # EDIT : Change the number of threads you want to use for multi-core
    echo "== Building Multi-Core CoreMark ($(nproc) threads) =="
    make \
        OPATH=coremark-mt/ \
        ITERATIONS=800 \
        CC=gcc \
        PORT_DIR=linux/ \
        XCFLAGS="-DMULTITHREAD=$nproc -DUSE_PTHREAD -pthread -DPERFORMANCE_RUN=1" \
        &> /dev/null || \
        echo "CoreMark Multi Core Build failed"
    
    cd $CURR_DIR
}


run_benchmarks() {
    mkdir -p "$OUTDIR"
    BIN_DIR="coremark-$1"
    for iter in "${ITERATIONS[@]}"; do
        echo "== Running $1 tests for iteration: $iter =="
        for ((i=1; i<=RUNS_PER_ITER; i++)); do
            OUTFILE="$OUTDIR/coremark_${1}_${iter}_run${i}.log"
            echo "  -> Run #$i"
            "./coremark/${BIN_DIR}/coremark.exe" 0x0 0x0 0x66 "$iter" 7 1 2000 > "$OUTFILE"
        done
    done
}


summarize_results() {
    local mode="$1"

    echo
    echo "===================== Summary (${mode^^}) ====================="
    printf "%-10s | %-20s | %-17s | %-22s | %-13s\n" \
           "Iteration" "Avg Iter/Sec" "Compiler" "Avg Total Time (s)" "Correct Run?"
    echo "---------------------------------------------------------------------------------------------"

    for iter in "${ITERATIONS[@]}"; do
        sum_ips=0
        sum_time=0
        correct=1
        compiler=""
        count=0

        for ((i=1; i<=RUNS_PER_ITER; i++)); do
            FILE="$OUTDIR/coremark_${mode}_${iter}_run${i}.log"
            ips=$(get_ips "$FILE")
            time=$(get_time "$FILE")
            valid=$(get_correct "$FILE")
            compiler_this=$(get_compiler "$FILE")

            [[ -n "$compiler_this" && -z "$compiler" ]] && compiler="$compiler_this"
            [[ "$valid" -ne 1 ]] && correct=0

            if [[ -n "$ips" && -n "$time" ]]; then
                sum_ips=$(echo "$sum_ips + $ips" | bc)
                sum_time=$(echo "$sum_time + $time" | bc)
                count=$((count + 1))
            fi
        done

        if [[ $count -gt 0 ]]; then
            avg_ips=$(echo "scale=4; $sum_ips / $count" | bc)
            avg_time=$(echo "scale=4; $sum_time / $count" | bc)
            result_icon=$([[ "$correct" -eq 1 ]] && echo "✅" || echo "❌")
            printf "%-10s | %-20s | %-17s | %-22s | %-13s\n" \
                   "$iter" "$avg_ips" "$compiler" "$avg_time" "$result_icon"
        else
            printf "%-10s | %-20s | %-17s | %-22s | %-13s\n" \
                   "$iter" "N/A" "N/A" "N/A" "❌"
        fi
    done
    echo "==================================================="
}


main() {
    build_coremark

    run_benchmarks "st"
    summarize_results "st"

    run_benchmarks "mt"
    summarize_results "mt"
}

main "$@"