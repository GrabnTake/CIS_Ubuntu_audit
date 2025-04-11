#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if nftables is in use first
if ! { command -v nft &>/dev/null && nft list tables 2>/dev/null | grep -q "^table"; }; then
    audit_result="SKIP"
    a_output+=("- nftables is not in use, audit skipped")
else
    # Check if ufw is installed
    if dpkg-query -s ufw &>/dev/null; then
        audit_result="FAIL"
        a_output2+=("- ufw is installed while nftables is present")
    else
        audit_result="PASS"
        a_output+=("- ufw is not installed with nftables")
    fi
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
    printf '%s\n' "${a_output2[@]}"
fi