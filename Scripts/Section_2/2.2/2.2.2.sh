#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if rsh-client is installed
if dpkg-query -s rsh-client &>/dev/null; then
    a_output2+=("- rsh-client package is installed")
else
    a_output+=("- rsh-client package is not installed")
fi

# Set audit result
audit_result="FAIL"
if [ ${#a_output2[@]} -le 0 ]; then
    audit_result="PASS"
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
if [ ${#a_output[@]} -eq 0 ]; then
    echo "(none)"
else
    printf '%s\n' "${a_output[@]}"
fi

if [ "$audit_result" == "FAIL" ]; then
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    if [ ${#a_output2[@]} -eq 0 ]; then
        echo "(none)"
    else
        printf '%s\n' "${a_output2[@]}"
    fi
fi