#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if iptables is in use (custom rules beyond defaults)
if ! { command -v iptables &>/dev/null && iptables -L -n --line-numbers 2>/dev/null | grep -v "^Chain\|^$" | grep -q "[1-9]"; }; then
    audit_result="SKIP"
    a_output+=("- iptables is not in use (no custom rules or not installed), audit skipped")
else
    # Get open ports from ss (non-localhost only)
    open_ports=$(ss -4tuln 2>/dev/null | awk 'NR>1 && $5 !~ /127\.[0-9]+\.[0-9]+\.[0-9]+:/ {print $1 " " $5}' | sort -u)

    # Get iptables INPUT rules
    input_rules=$(iptables -L INPUT -v -n --line-numbers 2>/dev/null)

    # Check each open port against firewall rules
    all_ports_ok=true
    while read -r proto port; do
        # Extract port number (e.g., *:22 -> 22)
        port_num=$(echo "$port" | cut -d':' -f2)
        # Look for ACCEPT rule matching protocol and destination port
        if echo "$input_rules" | grep -E "^ *[1-9].*ACCEPT +${proto} +[^ ]* +\* +\* +0\.0\.0\.0/0 +0\.0\.0\.0/0.*dpt:${port_num}" >/dev/null; then
            a_output+=("- Port ${proto}/${port_num} has an ACCEPT rule in INPUT chain")
        else
            a_output2+=("- Port ${proto}/${port_num} lacks an ACCEPT rule in INPUT chain")
            all_ports_ok=false
        fi
    done <<< "$open_ports"

    # Set result based on whether all ports have rules
    if [ -z "$open_ports" ]; then
        audit_result="PASS"
        a_output+=("- No non-localhost listening ports detected")
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