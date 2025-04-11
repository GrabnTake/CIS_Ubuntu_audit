#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if at is installed (look for atd service)
if systemctl list-unit-files | grep -E '^atd\.service' >/dev/null 2>&1; then
    # Check /etc/at.allow
    if [ -e "/etc/at.allow" ]; then
        at_allow_stat=$(stat -Lc 'Access: (%a/%A) Owner: (%U) Group: (%G)' /etc/at.allow 2>/dev/null)
        access=$(echo "$at_allow_stat" | grep -oP 'Access: \(\K[^)]+')
        owner=$(echo "$at_allow_stat" | grep -oP 'Owner: \(\K[^)]+')
        group=$(echo "$at_allow_stat" | grep -oP 'Group: \(\K[^)]+')
        access_num=$(echo "$access" | cut -d'/' -f1)

        # Validate /etc/at.allow
        if [ "$access_num" -le 640 ] && echo "$access" | grep -q '^-rw[-r][-w][------]$'; then
            a_output+=(" - /etc/at.allow permissions are correct: \"$access\"")
        else
            a_output2+=(" - /etc/at.allow permissions are incorrect: \"$access\" (expected: 0640/-rw-r----- or more restrictive)")
        fi

        if [ "$owner" = "root" ]; then
            a_output+=(" - /etc/at.allow owner is correct: \"$owner\"")
        else
            a_output2+=(" - /etc/at.allow owner is incorrect: \"$owner\" (expected: root)")
        fi

        if [ "$group" = "daemon" ] || [ "$group" = "root" ]; then
            a_output+=(" - /etc/at.allow group is correct: \"$group\"")
        else
            a_output2+=(" - /etc/at.allow group is incorrect: \"$group\" (expected: daemon or root)")
        fi
    else
        a_output2+=(" - /etc/at.allow does not exist")
    fi

    # Check /etc/at.deny
    if [ -e "/etc/at.deny" ]; then
        at_deny_stat=$(stat -Lc 'Access: (%a/%A) Owner: (%U) Group: (%G)' /etc/at.deny 2>/dev/null)
        access=$(echo "$at_deny_stat" | grep -oP 'Access: \(\K[^)]+')
        owner=$(echo "$at_deny_stat" | grep -oP 'Owner: \(\K[^)]+')
        group=$(echo "$at_deny_stat" | grep -oP 'Group: \(\K[^)]+')
        access_num=$(echo "$access" | cut -d'/' -f1)

        # Validate /etc/at.deny
        if [ "$access_num" -le 640 ] && echo "$access" | grep -q '^-rw[-r][-w][------]$'; then
            a_output+=(" - /etc/at.deny permissions are correct: \"$access\"")
        else
            a_output2+=(" - /etc/at.deny permissions are incorrect: \"$access\" (expected: 0640/-rw-r----- or more restrictive)")
        fi

        if [ "$owner" = "root" ]; then
            a_output+=(" - /etc/at.deny owner is correct: \"$owner\"")
        else
            a_output2+=(" - /etc/at.deny owner is incorrect: \"$owner\" (expected: root)")
        fi

        if [ "$group" = "daemon" ] || [ "$group" = "root" ]; then
            a_output+=(" - /etc/at.deny group is correct: \"$group\"")
        else
            a_output2+=(" - /etc/at.deny group is incorrect: \"$group\" (expected: daemon or root)")
        fi
    else
        a_output+=(" - /etc/at.deny does not exist (acceptable)")
    fi
else
    audit_result="SKIP"
    a_output+=(" - at daemon is not installed (audit skipped per local policy review)")
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