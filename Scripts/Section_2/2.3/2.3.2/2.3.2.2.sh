#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if systemd-timesyncd is in use and chrony is not
timesyncd_enabled=$(systemctl is-enabled systemd-timesyncd.service 2>/dev/null | grep -q 'enabled' && echo "yes" || echo "no")
timesyncd_active=$(systemctl is-active systemd-timesyncd.service 2>/dev/null | grep -q '^active' && echo "yes" || echo "no")
chrony_enabled=$(systemctl is-enabled chrony.service 2>/dev/null | grep -q 'enabled' && echo "yes" || echo "no")
chrony_active=$(systemctl is-active chrony.service 2>/dev/null | grep -q '^active' && echo "yes" || echo "no")

# Skip if timesyncd not in use or chrony is in use
if [ "$timesyncd_enabled" = "no" ] && [ "$timesyncd_active" = "no" ]; then
    audit_result="Skipped"
    a_output+=("- systemd-timesyncd is not enabled or active (audit skipped)")
elif [ "$chrony_enabled" = "yes" ] || [ "$chrony_active" = "yes" ]; then
    audit_result="Skipped"
    a_output+=("- chrony is enabled or active (audit skipped; only one time sync method should be in use)")
else
    # Check enabled status
    if [ "$timesyncd_enabled" = "yes" ]; then
        a_output+=("- systemd-timesyncd service is enabled")
    else
        a_output2+=("- systemd-timesyncd service is not enabled")
    fi

    # Check active status
    if [ "$timesyncd_active" = "yes" ]; then
        a_output+=("- systemd-timesyncd service is active")
    else
        a_output2+=("- systemd-timesyncd service is not active")
    fi
fi

# Set audit result if not skipped
if [ -z "$audit_result" ]; then
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
    if [ ${#a_output2[@]} -eq 0 ]; then
        echo "(none)"
    else
        printf '%s\n' "${a_output2[@]}"
    fi
fi