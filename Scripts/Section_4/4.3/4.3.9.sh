#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if nftables is in use
if ! { command -v nft &>/dev/null && nft list ruleset 2>/dev/null | grep -q "hook"; }; then
    audit_result="SKIP"
    a_output+=("- nftables is not in use (no rules exist or not installed), audit skipped")
else
    # Check if nftables service is enabled
    if systemctl is-enabled nftables &>/dev/null; then
        audit_result="PASS"
        a_output+=("- nftables service is enabled")
    else
        audit_result="FAIL"
        a_output2+=("- nftables service is not enabled")
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