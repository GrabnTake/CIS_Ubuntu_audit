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
    # Get open IPv6 ports (non-localhost only)
    open_ports=$(ss -6tuln 2>/dev/null | awk 'NR>1 && $5 !~ /::1:/ {print $1 " " $5}' | sort -u)

    # Get ip6tables INPUT rules
    input_rules=$(ip6tables -L INPUT -v -n --line-numbers 2>/dev/null)

    # Check each open port against firewall rules
    all_ports_ok=true
    while read -r proto port; do
        # Extract port number (e.g., :::22 -> 22)
        port_num=$(echo "$port" | cut -d':' -f4)
        # Look for ACCEPT rule matching protocol and destination port
        if echo "$input_rules" | grep -E "^ *[1-9].*ACCEPT +${proto} +[^ ]* +\* +\* +::/0 +::/0.*dpt:${port_num}" >/dev/null; then
            a_output+=("- Port ${proto}/${port_num} has an ACCEPT rule in INPUT chain")
        else
            a_output2+=("- Port ${proto}/${port_num} lacks an ACCEPT rule in INPUT chain")
            all_ports_ok=false
        fi
    done <<< "$open_ports"

    # Set result
    if [ -z "$open_ports" ]; then
        audit_result="PASS"
        a_output+=("- No non-localhost IPv6 listening ports detected")
    elif $all_ports_ok; then
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