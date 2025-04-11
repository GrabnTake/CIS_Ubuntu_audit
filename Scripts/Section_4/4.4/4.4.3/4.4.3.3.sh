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
    # ip6tables is in use, display rules for manual review
    ip6tables_rules=$(ip6tables -L -v -n --line-numbers 2>/dev/null || echo "Failed to retrieve ip6tables rules")

    audit_result="MANUAL"
    a_output+=("- Review the following ip6tables rules against site policy for new outbound and established connections:")
    a_output+=("- Rules:")
    while IFS= read -r line; do
        a_output+=("  $line")
    done <<< "$ip6tables_rules"
    a_output+=("- Note: Check OUTPUT chain for new outbound connections and INPUT/OUTPUT chains for established connections")
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