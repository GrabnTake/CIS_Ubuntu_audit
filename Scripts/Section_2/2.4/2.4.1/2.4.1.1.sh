#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if cron/crond is installed (look for service file)
if systemctl list-unit-files | grep -E '^crond?\.service' >/dev/null 2>&1; then
    # Check enabled status
    enabled_status=$(systemctl list-unit-files | awk '$1~/^crond?\.service/{print $2}')
    if [ "$enabled_status" = "enabled" ]; then
        a_output+=("- Cron daemon is enabled")
    else
        a_output2+=("- Cron daemon is not enabled (Status: \"$enabled_status\")")
    fi

    # Check active status
    active_status=$(systemctl list-units | awk '$1~/^crond?\.service/{print $3}')
    if [ "$active_status" = "active" ]; then
        a_output+=("- Cron daemon is active")
    else
        a_output2+=("- Cron daemon is not active (Status: \"$active_status\")")
    fi
else
    audit_result="SKIP"
    a_output+=("- Cron daemon is not installed (audit skipped per local policy review)")
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