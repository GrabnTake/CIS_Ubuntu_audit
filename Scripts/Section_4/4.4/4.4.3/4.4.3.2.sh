#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if ip6tables is in use (custom rules beyond defaults)
if ! { command -v ip6tables &>/dev/null && ip6tables -L -n --line-numbers 2>/dev/null | grep -v "^Chain\|^$" | grep -q "[1-9]"; }; then
    # If ip6tables isn’t in use, check if IPv6 is disabled
    ipv6_enabled="is"
    if ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable 2>/dev/null; then
        ipv6_enabled="is not"
    fi
    if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
       sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
        ipv6_enabled="is not"
    fi

    if [ "$ipv6_enabled" = "is not" ]; then
        audit_result="PASS"
        a_output+=("- IPv6 is disabled on the system (ip6tables not required)")
    else
        audit_result="SKIP"
        a_output+=("- ip6tables is not in use (no custom rules or not installed) and IPv6 is enabled, audit skipped")
    fi
else
    # ip6tables is in use, check INPUT and OUTPUT rules
    input_rules=$(ip6tables -L INPUT -v -n --line-numbers 2>/dev/null)
    output_rules=$(ip6tables -L OUTPUT -v -n --line-numbers 2>/dev/null)

    # INPUT chain checks
    input_lo_accept=$(echo "$input_rules" | grep -E "^ *[1-9].*ACCEPT +all +[^ ]* +lo +\* +::/0 +::/0" | wc -l)
    input_loopback_drop=$(echo "$input_rules" | grep -E "^ *[1-9].*DROP +all +[^ ]* +\* +\* +::1 +::/0" | wc -l)

    # OUTPUT chain check
    output_lo_accept=$(echo "$output_rules" | grep -E "^ *[1-9].*ACCEPT +all +[^ ]* +\* +lo +::/0 +::/0" | wc -l)

    # Verify rules exist
    if [ "$input_lo_accept" -ge 1 ]; then
        a_output+=("- INPUT: ACCEPT rule for lo interface exists")
    else
        a_output2+=("- INPUT: Missing ACCEPT rule for lo interface")
    fi

    if [ "$input_loopback_drop" -ge 1 ]; then
        a_output+=("- INPUT: DROP rule for ::1 exists")
    else
        a_output2+=("- INPUT: Missing DROP rule for ::1")
    fi

    if [ "$output_lo_accept" -ge 1 ]; then
        a_output+=("- OUTPUT: ACCEPT rule for lo interface exists")
    else
        a_output2+=("- OUTPUT: Missing ACCEPT rule for lo interface")
    fi

    # PASS if all required rules are present
    if [ "$input_lo_accept" -ge 1 ] && [ "$input_loopback_drop" -ge 1 ] && [ "$output_lo_accept" -ge 1 ]; then
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