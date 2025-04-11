#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if iptables is in use (custom rules beyond defaults)
if ! { command -v iptables &>/dev/null && iptables -L -n --line-numbers 2>/dev/null | grep -v "^Chain\|^$" | grep -q "[1-9]"; }; then
    audit_result="SKIP"
    a_output+=("- iptables is not in use (no custom rules or not installed), audit skipped")
else
    # Capture INPUT and OUTPUT chain rules
    input_rules=$(iptables -L INPUT -v -n --line-numbers 2>/dev/null)
    output_rules=$(iptables -L OUTPUT -v -n --line-numbers 2>/dev/null)

    # INPUT chain checks
    input_lo_accept=$(echo "$input_rules" | grep -E "^ *[1-9].*ACCEPT +(all|0) +[^ ]* +lo +\* +0\.0\.0\.0/0 +0\.0\.0\.0/0" | wc -l)
    input_127_drop=$(echo "$input_rules" | grep -E "^ *[1-9].*DROP +(all|0) +[^ ]* +\* +\* +127\.0\.0\.0/8 +0\.0\.0\.0/0" | wc -l)

    # OUTPUT chain check
    output_lo_accept=$(echo "$output_rules" | grep -E "^ *[1-9].*ACCEPT +(all|0) +[^ ]* +\* +lo +0\.0\.0\.0/0 +0\.0\.0\.0/0" | wc -l)

    # Verify rules exist
    if [ "$input_lo_accept" -ge 1 ]; then
        a_output+=("- INPUT: ACCEPT rule for lo interface exists")
    else
        a_output2+=("- INPUT: Missing ACCEPT rule for lo interface")
    fi

    if [ "$input_127_drop" -ge 1 ]; then
        a_output+=("- INPUT: DROP rule for 127.0.0.0/8 exists")
    else
        a_output2+=("- INPUT: Missing DROP rule for 127.0.0.0/8")
    fi

    if [ "$output_lo_accept" -ge 1 ]; then
        a_output+=("- OUTPUT: ACCEPT rule for lo interface exists")
    else
        a_output2+=("- OUTPUT: Missing ACCEPT rule for lo interface")
    fi

    # PASS if all required rules are present
    if [ "$input_lo_accept" -ge 1 ] && [ "$input_127_drop" -ge 1 ] && [ "$output_lo_accept" -ge 1 ]; then
        audit_result="PASS"
    else
        audit_result="FAIL"
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