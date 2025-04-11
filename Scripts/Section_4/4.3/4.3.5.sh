#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if nftables is in use
if ! { command -v nft &>/dev/null && nft list tables 2>/dev/null | grep -q "^table"; }; then
    audit_result="SKIP"
    a_output+=("- nftables is not in use (no tables exist or not installed), audit skipped")
else
    # Check for base chains if nftables is in use
    input_chain=$(nft list ruleset 2>/dev/null | grep -c "hook input")
    forward_chain=$(nft list ruleset 2>/dev/null | grep -c "hook forward")
    output_chain=$(nft list ruleset 2>/dev/null | grep -c "hook output")

    if [ "$input_chain" -gt 0 ] && [ "$forward_chain" -gt 0 ] && [ "$output_chain" -gt 0 ]; then
        audit_result="PASS"
        a_output+=("- nftables base chains exist for INPUT, FORWARD, and OUTPUT")
    else
        audit_result="FAIL"
        if [ "$input_chain" -eq 0 ]; then
            a_output2+=("- Missing base chain for INPUT")
        fi
        if [ "$forward_chain" -eq 0 ]; then
            a_output2+=("- Missing base chain for FORWARD")
        fi
        if [ "$output_chain" -eq 0 ]; then
            a_output2+=("- Missing base chain for OUTPUT")
        fi
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