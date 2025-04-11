#!/usr/bin/env bash

# Define base directories
SCRIPT_DIR="script"
RESULT_DIR="result"

# Ensure the result directory exists
mkdir -p "$RESULT_DIR"

# Check for root/admin privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root (sudo)." >&2
    exit 1
fi

# Check Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_CODENAME=$(lsb_release -cs)
if [ "$UBUNTU_VERSION" != "24.04" ]; then
    echo "Error: This script is only designed for Ubuntu 24.04 LTS." >&2
    exit 1
fi

# Collect system details
HOSTNAME=$(hostname)
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
SYSINFO_FILE="$RESULT_DIR/System_Info.txt"

# Save system details to file
{
    echo "Audit Time: $TIMESTAMP"
    echo "Machine Name: $HOSTNAME"
    echo "Ubuntu Version: $UBUNTU_VERSION ($UBUNTU_CODENAME)"
} > "$SYSINFO_FILE"

# Find and execute all scripts under the script directory
find "$SCRIPT_DIR" -type f -name "*.sh" | while read -r script; do
    # Get a clean name for the output file
    clean_script_name=$(echo "$script" | sed 's|/|_|g' | sed 's|.sh$||')
    
    # Define the output file path (all at the same level inside result/)
    audit_file="$RESULT_DIR/AUDIT_${clean_script_name}.txt"

    echo "Running audit: $script"

    # Execute the script and capture its output
    bash "$script" &> "$audit_file"
done

# Zip all audit reports
zip -r audit_reports.zip "$RESULT_DIR"

echo "All audits completed. Reports are saved in audit_reports.zip."
