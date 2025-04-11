#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if iptables is in use (custom rules beyond defaults)
if ! { command -v iptables &>/dev/null && iptables -L -n --line-numbers 2>/dev/null | grep -v "^Chain\|^$" | grep -q "[1-9]"; }; then
    audit_result="SKIP"
    a_output+=("- iptables is not in use (no custom rules or not installed), audit skipped")
else
    # Check nftables installation
    if dpkg-query -s nftables &>/dev/null 2>&1; then
        a_output2+=("- nftables is installed")
        # If installed, check service status
        nftables_status=$(systemctl status nftables.service 2>/dev/null || echo "unavailable")
        enabled=$(echo "$nftables_status" | grep -q "Loaded:.*enabled" && echo "yes" || echo "no")
        active=$(echo "$nftables_status" | grep -q "Active: active" && echo "yes" || echo "no")

        if [ "$enabled" = "yes" ]; then
            a_output2+=("- nftables.service is enabled")
        else
            a_output+=("- nftables.service is not enabled")
        fi
        if [ "$active" = "yes" ]; then
            a_output2+=("- nftables.service is active")
        else
            a_output+=("- nftables.service is not active")
        fi
    else
        a_output+=("- nftables is not installed (service checks skipped)")
        enabled="no"
        active="no"
    fi

    # PASS if nftables is not installed OR (installed but neither enabled nor active)
    if ! dpkg-query -s nftables &>/dev/null || { [ "$enabled" = "no" ] && [ "$active" = "no" ]; }; then
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