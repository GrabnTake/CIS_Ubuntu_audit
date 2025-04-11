#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if nftables is in use
if ! { command -v nft &>/dev/null && nft list ruleset 2>/dev/null | grep -q "hook"; }; then
    audit_result="SKIP"
    a_output+=("- nftables is not in use (no rules exist or not installed), audit skipped")
else
    # Capture ruleset once
    ruleset=$(nft list ruleset 2>/dev/null)

    # Check base chain policies
    input_drop=$(echo "$ruleset" | grep -c 'hook input.*policy drop')
    forward_drop=$(echo "$ruleset" | grep -c 'hook forward.*policy drop')
    output_drop=$(echo "$ruleset" | grep -c 'hook output.*policy drop')

    # Verify all chains have DROP policy
    if [ "$input_drop" -gt 0 ] && [ "$forward_drop" -gt 0 ] && [ "$output_drop" -gt 0 ]; then
        audit_result="PASS"
        a_output+=("- nftables base chains have DROP policy:")
        a_output+=("  - INPUT chain: policy drop")
        a_output+=("  - FORWARD chain: policy drop")
        a_output+=("  - OUTPUT chain: policy drop")
    else
        audit_result="FAIL"
        if [ "$input_drop" -eq 0 ]; then
            a_output2+=("- INPUT chain missing DROP policy")
        fi
        if [ "$forward_drop" -eq 0 ]; then
            a_output2+=("- FORWARD chain missing DROP policy")
        fi
        if [ "$output_drop" -eq 0 ]; then
            a_output2+=("- OUTPUT chain missing DROP policy")
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