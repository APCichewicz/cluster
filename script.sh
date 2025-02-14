#!/bin/bash

# Exit on error
set -e

# Print commands before executing
set -x

# Script variables
LOG_FILE="/var/log/script.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    local message="$1"
    echo "[${TIMESTAMP}] ${message}" | tee -a "${LOG_FILE}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_message "This script must be run as root"
        exit 1
    fi
}

# Function for cleanup
cleanup() {
    log_message "Performing cleanup..."
    # Add cleanup tasks here
}

# Trap errors and cleanup
trap cleanup EXIT

# Main script logic
main() {
    log_message "Starting script execution"
    
    # Your code goes here
    
    log_message "Script completed successfully"
}

# Run main function
main "$@" 