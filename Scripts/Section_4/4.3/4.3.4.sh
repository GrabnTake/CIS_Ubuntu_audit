#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if nftables is in use first
if ! { command -v nft &>/dev/null && nft list tables 2>/dev/null | grep -q "^table"; }; then
    audit_result="SKIP"
    a_output+=("- nftables is not in use, audit skipped")
else
    # Check for nftables tables
    table_count=$(nft list tables 2>/dev/null | grep -c "^table")
    if [ "$table_count" -gt 0 ]; then
        audit_result="PASS"
        a_output+=("- nftables table(s) exist (count: $table_count)")
    else
        audit_result="FAIL"
        a_output2+=("- No nftables tables exist")
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