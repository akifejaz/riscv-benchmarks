# Gist url : https://gist.github.com/akifejaz/1d6e240649d8161e2aa8a4dd651192c7/raw

#!/bin/bash
# ==============================================================================
# Phoronix Test Suite - Automation Script
#
# Description:
#   This script automates the setup and execution of Phoronix Test Suite (PTS),
#   specifically running a CPU benchmark and uploading the results to
#   OpenBenchmarking.org.
#
#   It's designed for auto-run scenarios — all user prompts are
#   pre-handled within the script, making it ideal for remote execution and
#   continuous integration (CI) workflows.
#
# Usage:
#   sudo bash run-phoronix.sh
#
# Notes:
#   - Feel free to customize or Tweak it as needed :)
#
# Author:
#   Akif Ejaz | github.com/akifejaz
#
# ==============================================================================  

set -euo pipefail

# Variables
# Use the main LOG_FILE from the parent script, do not set it here
PHORONIX_URL="https://github.com/phoronix-test-suite/phoronix-test-suite/releases/download/v10.8.4/phoronix-test-suite-10.8.4.tar.gz"

#==============================================================================
# Phoronix Test Suite Functions
#==============================================================================

setup_phoronix () {
    log INFO "Setting up Phoronix Test Suite..."

    if command -v phoronix-test-suite &> /dev/null; then
        log INFO "Phoronix Test Suite is already installed. Skipping installation." 
        return
    fi
    
    # Setup User Dirs. & install phoronix
    cd /home/$USER; mkdir -p projects/; cd projects/; mkdir -p phoronix-test-suite;
    curl -L -o phoronix-test-suite.tar.gz https://github.com/phoronix-test-suite/phoronix-test-suite/releases/download/v10.8.4/phoronix-test-suite-10.8.4.tar.gz && \
    tar -xf phoronix-test-suite.tar.gz -C phoronix-test-suite

    cd phoronix-test-suite/phoronix-test-suite && sudo bash install-sh &>> "$LOG_FILE"

    # TODO: Fix this please :) Its not working ... Unable to detect by alias
    # echo "alias phoronix='phoronix-test-suite'" >> /home/$USER/.bashrc
    # source /home/$USER/.bashrc

    # # Check if phoronix is installed.
    # if ! eval phoronix &> /dev/null; then
    #     die "PTS Install failed : $LOG_FILE"
    # fi

    # Alternatively, Check if phoronix is installed.
    if ! command -v phoronix-test-suite &> /dev/null; then
        die "PTS Install failed : $LOG_FILE"
    fi

    log SUCCESS "Phoronix Test Suite setup completed."
}


run_phoronix() {
    log INFO "Starting Phoronix Test Suite..."
    
    # EDIT : Add OpenBenchmarking credentials
    # SignUp Here : https://openbenchmarking.org/register
    export OB_USER=""
    export OB_PASS=""

    # Ensure OpenBenchmarking credentials are set
    if [[ -z "${OB_USER:-}" || -z "${OB_PASS:-}" ]]; then
        die "Please set your OpenBenchmarking credentials as environment variables OB_USER and OB_PASS."
    fi


    # Login to OpenBenchmarking.org
    {
        echo "$OB_USER"
        echo "$OB_PASS"
    } | phoronix-test-suite openbenchmarking-setup

    # EDIT : configure batch setup preferences
    printf 'y\nn\nn\nn\nn\nn\nn\n' | phoronix-test-suite batch-setup

    # Configure environment for non-interactive run
    export PTS_NON_INTERACTIVE=1
    export PTS_SAVE_RESULTS=1

    # EDIT : Setup the test results identifier (curruntly set to <user>_<hostname>_<YYYYMMDD_HHMM>)
    HOSTNAME=$(hostname -s)
    USER=$(whoami)
    DATE_TAG=$(date +%Y%m%d_%H%M)
    export TEST_RESULTS_IDENTIFIER="${USER}_${HOSTNAME}_${DATE_TAG}"
    # NOTE: You'll find the tests results with this name under ~/.phoronix-test-suite/test-results/ 
    # or /var/lib/phoronix-test-suite/test-results/ (when run as root)
    export TEST_RESULTS_NAME="RISCV CPU Benchmark ${DATE_TAG}" 

    # EDIT : Choose which benchmarks to run 
    TEST_LIST="coremark cachebench npb compress-7zip scimark2 openssl byte fftw"

    log INFO "Running benchmarks: $TEST_LIST"
    # EDIT : This is importent, choose correct options for your benchmarks you selected above
    # Not sure which options to use? Run manually to see the options like "phoronix-test-suite benchmark scimark2"
    echo -e "4\n11\n7\n2\n5\n3\n7" | phoronix-test-suite batch-benchmark $TEST_LIST

    log SUCCESS "Phoronix Test Suite run completed."
}

push_results () {
    log INFO "Pushing results to OpenBenchmarking.org..."

    for dir in /var/lib/phoronix-test-suite/test-results/*/; do
        dirname=$(basename "$dir")
        log INFO "➡ Uploading $dirname..."
        
        {
            echo 'y'
            echo 'n'
        } | phoronix-test-suite upload-results "$dirname" &>> "$LOG_FILE" && \
        log SUCCESS "✔ Done uploading $dirname" || log ERROR "✖ Failed to upload $dirname"
    done

    log SUCCESS "All results pushed successfully."
}

#==============================================================================
# Main Execution
#==============================================================================

main() {
    log INFO "Starting Phoronix automation - Log: $LOG_FILE"

    check_sudo
    setup_phoronix
    run_phoronix
    push_results
    
    log SUCCESS "PTS benchmark completed successfully. Check $LOG_FILE for details."
    log INFO "You can view your results at https://openbenchmarking.org/user/${OB_USER}"
}

main "$@"