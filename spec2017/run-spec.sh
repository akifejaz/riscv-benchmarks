# Gist url : https://gist.github.com/akifejaz/9d0b6f04b183228791e546e0e6107005/raw

#!/bin/bash
# ==============================================================================
# SPEC CPU 2017 Benchmark - Automation Script (Tuned for RISCV Systems)
#
# Description:
#   This script automates the setup and execution of SPEC CPU benchmark.
#   It runs intrate, fprate only for now.
#
#   It's designed for auto-run scenarios — — all user prompts are
#   pre-handled within the script, making it ideal for remote execution and
#   continuous integration (CI) workflows.
#
# Usage:
#   sudo bash run-spec.sh
#
# Notes:
#   - Feel free to customize or Tweak it as needed :)
#
# Author:
#   Akif Ejaz | github.com/akifejaz
#
# ==============================================================================

set -euo pipefail

#==============================================================================
# Helper Functions
#==============================================================================
CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# EDIT : Update the path of ISO File
ISO_FILE="$CURR_DIR/cpu2017-1.1.9.iso"
MOUNT_DIR="$CURR_DIR/mnt-spec"
INSTALL_DIR="$CURR_DIR/spec-17"

setup_spec() {
    log INFO "Installing SPEC ..."

    if [[ -z "$ISO_FILE" ]]; then
        log ERROR "No ISO file matching '$ISO_FILE' found."
        exit 1
    fi

    # dirs create
    mkdir -p "$MOUNT_DIR" "$INSTALL_DIR" 
    log INFO "Mounting ISO: $ISO_FILE"
    sudo mount "$ISO_FILE" "$MOUNT_DIR"

    log INFO "Starting SPEC  installer..."
    cd "$MOUNT_DIR"
    
    INSTALL_SCRIPT="./install.sh"
    if [[ ! -x "$INSTALL_SCRIPT" ]]; then
        log ERROR "Installer script not found"
        exit 1
    fi
    
    # Feed input non-interactively to the install script
    "$INSTALL_SCRIPT" <<EOF
$INSTALL_DIR
yes
EOF
    log SUCCESS "SPEC installed to: $INSTALL_DIR"
}

clean_spec(){

    if [[ -d "$INSTALL_DIR" ]]; then
        sudo umount "$MOUNT_DIR"
        rm -rf "$MOUNT_DIR" "$INSTALL_DIR"
        log SUCCESS "Removed $INSTALL_DIR and $MOUNT_DIR"
    else
        log WARNING "No SPEC  installation found to clean."
    fi
}

tweak_config() {
    log INFO "Tweaking SPEC configuration..."
    
    # Download the example config
    # EDIT: Update this URL if the config file location changes
    curl -L -o $INSTALL_DIR/gcc-linux-riscv.cfg https://www.spec.org/cpu2017/Docs/Example-gcc-linux-riscv.cfg 
    
    # EDIT : change lable (curruntly set to hostname-memory-ram-user-test)
    HOSTNAME=$(hostname -s)
    MEM=$(free -g | awk '/Mem:/ {print $2}') 
    RAM=$(df -h / | awk 'NR==2 {print $4}')  
    USER=$(whoami)
    
    # Replace 'mytest' with dynamic label
    sed -i "s|%   define label \"mytest\"|%   define label \"$HOSTNAME-$MEM\GB-$RAM-$USER-test\"|" $INSTALL_DIR/gcc-linux-riscv.cfg
    
    # EDIT : Setup the email configuration on your system or comment out this
    echo "default:
   mailto = akif.ejaz@10xengineers.ai, akifejaz40@gmail.com" >> $INSTALL_DIR/gcc-linux-riscv.cfg

    log SUCCESS "Configuration tweaked successfully."
}

run_spec() {
    log INFO "Running SPEC benchmark..."
    
    cd "$INSTALL_DIR"
    # EDIT : Change the cores and which benchmarks you want to run
    # NOTE : fprate, intspeed, fpspeed might not work on RISC-V :(
    cores=$(nproc)
    benchmarks="intrate fprate fpspeed intspeed"
    
    # Run benchmark with multiple copies (multi-core rate mode)
    ./bin/runcpu \
        --config=$INSTALL_DIR/gcc-linux-riscv.cfg \
        --action=run \
        --tune=all \
        --iterations=1 \
        --copies="$cores" \
        --output_format=text,html,mail \
        --reportable \
        $benchmarks

    if [[ $? -ne 0 ]]; then
        log ERROR "SPEC benchmark failed."
        exit 1
    fi
}

#==============================================================================
# Main Execution
#==============================================================================

main() {
    log INFO "Starting SPEC - Log: $LOG_FILE"
    
    # clean_spec
    check_sudo
    setup_spec
    tweak_config
    run_spec
    
    log SUCCESS "SPEC benchmark completed successfully. Check $LOG_FILE for details."
}

main "$@"