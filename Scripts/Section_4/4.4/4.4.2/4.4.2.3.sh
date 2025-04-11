#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if iptables is in use (custom rules beyond defaults)
if ! { command -v iptables &>/dev/null && iptables -L -n --line-numbers 2>/dev/null | grep -v "^Chain\|^$" | grep -q "[1-9]"; }; then
    audit_result="SKIP"
    a_output+=("- iptables is not in use (no custom rules or not installed), audit skipped")
else
    # Capture full iptables rules for manual review
    iptables_rules=$(iptables -L -v -n --line-numbers 2>/dev/null || echo "Failed to retrieve iptables rules")

    # Set result to MANUAL
    audit_result="MANUAL"
    a_output+=("- Review the following iptables rules against site policy for new outbound and established connections:")
    a_output+=("- Rules:")
    while IFS= read -r line; do
        a_output+=("  $line")
    done <<< "$iptables_rules"
    a_output+=("- Note: Check rules in OUTPUT chain for new outbound connections and INPUT/OUTPUT chains for established connections")
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