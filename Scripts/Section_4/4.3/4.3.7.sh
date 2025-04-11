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

    # Extract INPUT rules for manual verification
    input_rules=$(echo "$ruleset" | awk '/hook input/,/}/' | grep -E 'ip protocol (tcp|udp) ct state' || echo "No matching INPUT rules found")
    # Extract OUTPUT rules for manual verification
    output_rules=$(echo "$ruleset" | awk '/hook output/,/}/' | grep -E 'ip protocol (tcp|udp) ct state' || echo "No matching OUTPUT rules found")

    # Set result to MANUAL for user review
    audit_result="MANUAL"
    a_output+=("- Review the following nftables rules against site policy:")
    a_output+=("  - INPUT rules:")
    # Split input_rules into lines for cleaner output
    while IFS= read -r line; do
        a_output+=("    $line")
    done <<< "$input_rules"
    a_output+=("  - OUTPUT rules:")
    while IFS= read -r line; do
        a_output+=("    $line")
    done <<< "$output_rules"
    a_output+=("- Expected INPUT: 'ip protocol {tcp,udp} ct state established accept'")
    a_output+=("- Expected OUTPUT: 'ip protocol {tcp,udp} ct state established,related,new accept'")
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