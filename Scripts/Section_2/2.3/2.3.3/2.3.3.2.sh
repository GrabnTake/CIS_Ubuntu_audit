#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if chrony is in use and systemd-timesyncd is not
chrony_enabled=$(systemctl is-enabled chrony.service 2>/dev/null | grep -q 'enabled' && echo "yes" || echo "no")
chrony_active=$(systemctl is-active chrony.service 2>/dev/null | grep -q '^active' && echo "yes" || echo "no")
timesyncd_enabled=$(systemctl is-enabled systemd-timesyncd.service 2>/dev/null | grep -q 'enabled' && echo "yes" || echo "no")
timesyncd_active=$(systemctl is-active systemd-timesyncd.service 2>/dev/null | grep -q '^active' && echo "yes" || echo "no")

# Skip if chrony not in use or timesyncd is in use
if [ "$chrony_enabled" = "no" ] && [ "$chrony_active" = "no" ]; then
    audit_result="Skipped"
    a_output+=("- chrony is not enabled or active (audit skipped)")
elif [ "$timesyncd_enabled" = "yes" ] || [ "$timesyncd_active" = "yes" ]; then
    audit_result="Skipped"
    a_output+=("- systemd-timesyncd is enabled or active (audit skipped; only one time sync method should be in use)")
else
    # Check if chronyd is running as _chrony
    incorrect_users=$(ps -ef | awk '(/[c]hronyd/ && $1!="_chrony") { print $1 }' | sort -u)
    if [ -z "$incorrect_users" ]; then
        a_output+=("- chronyd service is running as the correct user: _chrony")
    else
        while IFS= read -r user; do
            a_output2+=("- chronyd service is running as incorrect user: \"$user\" (expected: _chrony)")
        done <<< "$incorrect_users"
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