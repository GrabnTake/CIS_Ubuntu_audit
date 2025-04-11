#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if iptables is in use (custom rules beyond defaults)
if ! { command -v iptables &>/dev/null && iptables -L -n --line-numbers 2>/dev/null | grep -v "^Chain\|^$" | grep -q "[1-9]"; }; then
    audit_result="SKIP"
    a_output+=("- iptables is not in use (no custom rules or not installed), audit skipped")
else
    # Check ufw installation
    if dpkg-query -s ufw &>/dev/null 2>&1; then
        a_output2+=("- ufw is installed")
        # If installed, check status
        ufw_status=$(systemctl status ufw.service 2>/dev/null || echo "unavailable")
        enabled=$(echo "$ufw_status" | grep -q "Loaded:.*enabled" && echo "yes" || echo "no")
        active=$(echo "$ufw_status" | grep -q "Active: active" && echo "yes" || echo "no")
        # Cross-check with ufw status for "inactive"
        ufw_inactive=$(ufw status 2>/dev/null | grep -q "Status: inactive" && echo "yes" || echo "no")

        if [ "$enabled" = "yes" ]; then
            a_output2+=("- ufw.service is enabled")
        else
            a_output+=("- ufw.service is not enabled")
        fi
        if [ "$active" = "yes" ]; then
            a_output2+=("- ufw.service is active")
        else
            a_output+=("- ufw.service is not active")
        fi
        if [ "$ufw_inactive" = "yes" ]; then
            a_output+=("- ufw is disabled (status: inactive)")
        else
            a_output2+=("- ufw is active (status not inactive)")
        fi
    else
        a_output+=("- ufw is not installed (service checks skipped)")
        enabled="no"
        active="no"
        ufw_inactive="yes"  # Not installed counts as "disabled"
    fi

    # PASS if ufw is not installed OR (installed but disabled, not enabled, not active)
    if ! dpkg-query -s ufw &>/dev/null || { [ "$ufw_inactive" = "yes" ] && [ "$enabled" = "no" ] && [ "$active" = "no" ]; }; then
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