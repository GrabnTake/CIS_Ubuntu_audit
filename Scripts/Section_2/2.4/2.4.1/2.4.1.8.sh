#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if cron/crond is installed
if systemctl list-unit-files | grep -E '^crond?\.service' >/dev/null 2>&1; then
    # Check /etc/cron.allow
    if [ -e "/etc/cron.allow" ]; then
        cron_allow_stat=$(stat -Lc 'Access: (%a/%A) Owner: (%U) Group: (%G)' /etc/cron.allow 2>/dev/null)
        access=$(echo "$cron_allow_stat" | grep -oP 'Access: \(\K[^)]+')
        owner=$(echo "$cron_allow_stat" | grep -oP 'Owner: \(\K[^)]+')
        group=$(echo "$cron_allow_stat" | grep -oP 'Group: \(\K[^)]+')
        access_num=$(echo "$access" | cut -d'/' -f1)

        # Validate /etc/cron.allow
        if [ "$access_num" -le 640 ] && echo "$access" | grep -q '^-rw[-r][-w][------]$'; then
            a_output+=(" - /etc/cron.allow permissions are correct: \"$access\"")
        else
            a_output2+=(" - /etc/cron.allow permissions are incorrect: \"$access\" (expected: 0640/-rw-r----- or more restrictive)")
        fi

        if [ "$owner" = "root" ]; then
            a_output+=(" - /etc/cron.allow owner is correct: \"$owner\"")
        else
            a_output2+=(" - /etc/cron.allow owner is incorrect: \"$owner\" (expected: root)")
        fi

        if [ "$group" = "root" ] || [ "$group" = "crontab" ]; then
            a_output+=(" - /etc/cron.allow group is correct: \"$group\"")
        else
            a_output2+=(" - /etc/cron.allow group is incorrect: \"$group\" (expected: root or crontab)")
        fi
    else
        a_output2+=(" - /etc/cron.allow does not exist")
    fi

    # Check /etc/cron.deny
    if [ -e "/etc/cron.deny" ]; then
        cron_deny_stat=$(stat -Lc 'Access: (%a/%A) Owner: (%U) Group: (%G)' /etc/cron.deny 2>/dev/null)
        access=$(echo "$cron_deny_stat" | grep -oP 'Access: \(\K[^)]+')
        owner=$(echo "$cron_deny_stat" | grep -oP 'Owner: \(\K[^)]+')
        group=$(echo "$cron_deny_stat" | grep -oP 'Group: \(\K[^)]+')
        access_num=$(echo "$access" | cut -d'/' -f1)

        # Validate /etc/cron.deny
        if [ "$access_num" -le 640 ] && echo "$access" | grep -q '^-rw[-r][-w][------]$'; then
            a_output+=(" - /etc/cron.deny permissions are correct: \"$access\"")
        else
            a_output2+=(" - /etc/cron.deny permissions are incorrect: \"$access\" (expected: 0640/-rw-r----- or more restrictive)")
        fi

        if [ "$owner" = "root" ]; then
            a_output+=(" - /etc/cron.deny owner is correct: \"$owner\"")
        else
            a_output2+=(" - /etc/cron.deny owner is incorrect: \"$owner\" (expected: root)")
        fi

        if [ "$group" = "root" ] || [ "$group" = "crontab" ]; then
            a_output+=(" - /etc/cron.deny group is correct: \"$group\"")
        else
            a_output2+=(" - /etc/cron.deny group is incorrect: \"$group\" (expected: root or crontab)")
        fi
    else
        a_output+=(" - /etc/cron.deny does not exist (acceptable)")
    fi
else
    audit_result="SKIP"
    a_output+=(" - Cron daemon is not installed (audit skipped per local policy review)")
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