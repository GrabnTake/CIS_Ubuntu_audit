#!/usr/bin/env bash

# Arrays to store results
a_output=()
a_output2=()

# Check if AIDE is installed
if dpkg-query -s aide &>/dev/null; then
    a_output+=("- AIDE is installed")
else
    a_output2+=("- AIDE is NOT installed.")
fi

# Check if aide-common is installed
if dpkg-query -s aide-common &>/dev/null; then
    a_output+=("- aide-common is installed")
else
    a_output2+=("- aide-common is NOT installed.")
fi

# Determine audit result
audit_result="FAIL"
[ ${#a_output2[@]} -eq 0 ] && audit_result="PASS"

# Output audit report
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
if [ "$audit_result" = "FAIL" ]; then
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${a_output2[@]}"
fi
