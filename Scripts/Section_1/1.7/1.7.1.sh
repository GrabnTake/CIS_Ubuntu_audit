#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Function to check if gdm3 is installed
check_gdm3_installed() {
    if dpkg-query -W -f='${db:Status-Status}\n' gdm3 2>/dev/null | grep -q '^installed$'; then
        a_output2+=(" - gdm3 is installed")
    else
        a_output+=(" - gdm3 is not installed")
    fi
}

# Run the function to check gdm3
check_gdm3_installed

# Report results in plain text format
if [ ${#a_output2[@]} -eq 0 ]; then
    echo "====== Audit Report ======"
    echo "Audit Result: PASS"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${a_output[@]}"
else
    echo "====== Audit Report ======"
    echo "Audit Result: FAIL"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${a_output[@]}"
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${a_output2[@]}"
fi

