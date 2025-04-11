#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if nftables is in use first
if ! { command -v nft &>/dev/null && nft list tables 2>/dev/null | grep -q "^table"; }; then
    audit_result="SKIP"
    a_output+=("- nftables is not in use, audit skipped")
else
    # Check iptables rules
    iptables_rules=$(iptables -L --no-numeric 2>/dev/null | grep -v "^Chain\|^$" | wc -l)
    if [ "$iptables_rules" -eq 0 ]; then
        a_output+=("- No iptables rules exist")
    else
        a_output2+=("- iptables rules exist")
    fi

    # Check ip6tables rules
    ip6tables_rules=$(ip6tables -L --no-numeric 2>/dev/null | grep -v "^Chain\|^$" | wc -l)
    if [ "$ip6tables_rules" -eq 0 ]; then
        a_output+=("- No ip6tables rules exist")
    else
        a_output2+=("- ip6tables rules exist")
    fi

    # Set audit result
    audit_result="FAIL"
    if [ ${#a_output2[@]} -le 0 ]; then
        audit_result="PASS"
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