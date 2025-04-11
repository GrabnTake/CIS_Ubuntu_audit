#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if UFW is in use first
if ! {command -v ufw &>/dev/null && systemctl is-active --quiet ufw; } ; then
    audit_result="SKIP"
    a_output+=("- UFW is not in use, audit skipped")
else
    # Check if UFW is enabled
    if systemctl is-enabled ufw.service | grep -q "^enabled$"; then
        a_output+=("- UFW service is enabled")
    else
        a_output2+=("- UFW service is not enabled")
    fi

    # Check if UFW is active via systemctl
    if systemctl is-active ufw | grep -q "^active$"; then
        a_output+=("- UFW service is active (systemctl)")
    else
        a_output2+=("- UFW service is not active (systemctl)")
    fi

    # Check if UFW is active via ufw status
    if ufw status | grep -q "^Status: active$"; then
        a_output+=("- UFW is active with status")
    else
        a_output2+=("- UFW is not active (status check)")
    fi

    # Set audit result based on checks
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