#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if bluez package is installed
if dpkg-query -s bluez &>/dev/null; then
    a_output2+=("- bluez package is installed")
    
    # If installed, check bluetooth.service status
    enabled_status=$(systemctl is-enabled bluetooth.service 2>/dev/null | grep -q 'enabled' && echo "yes" || echo "no")
    active_status=$(systemctl is-active bluetooth.service 2>/dev/null | grep -q '^active' && echo "yes" || echo "no")

    if [ "$enabled_status" = "no" ]; then
        a_output+=("- bluetooth.service is not enabled")
    else
        a_output2+=("- bluetooth.service is enabled")
    fi

    if [ "$active_status" = "no" ]; then
        a_output+=("- bluetooth.service is not active")
    else
        a_output2+=("- bluetooth.service is active")
    fi
else
    a_output+=("- bluez package is not installed")
fi

# Set audit result
audit_result="FAIL"
if [ ${#a_output2[@]} -le 0 ]; then
    audit_result="PASS"
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
    if [ ${#a_output2[@]} -eq 0 ]; then
        echo "(none)"
    else
        printf '%s\n' "${a_output2[@]}"
    fi
fi