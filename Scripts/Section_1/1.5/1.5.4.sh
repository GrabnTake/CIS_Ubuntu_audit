#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Check if prelink is installed
if dpkg-query -s prelink &>/dev/null; then
    a_output2+=(" - prelink is installed")
else
    a_output+=(" - prelink is not installed")
fi

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

