#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if cron/crond is installed
if systemctl list-unit-files | grep -E '^crond?\.service' >/dev/null 2>&1; then
    # Get stat output for /etc/cron.daily/
    cron_daily_stat=$(stat -Lc 'Access: (%a/%A) Uid: (%u/%U) Gid: (%g/%G)' /etc/cron.daily/ 2>/dev/null)

    if [ -n "$cron_daily_stat" ]; then
        # Parse stat output
        access=$(echo "$cron_daily_stat" | grep -oP 'Access: \(\K[^)]+')
        uid=$(echo "$cron_daily_stat" | grep -oP 'Uid: \(\s*\K\d+')
        gid=$(echo "$cron_daily_stat" | grep -oP 'Gid: \(\s*\K\d+')
        user=$(echo "$cron_daily_stat" | grep -oP 'Uid: .*/\s*\K[^)]+')
        group=$(echo "$cron_daily_stat" | grep -oP 'Gid: .*/\s*\K[^)]+')

        # Check permissions and ownership
        if [ "$access" = "700/drwx------" ]; then
            a_output+=("- /etc/cron.daily/ permissions are correct: \"$access\"")
        else
            a_output2+=("- /etc/cron.daily/ permissions are incorrect: \"$access\" (expected: 700/drwx------)")
        fi

        if [ "$uid" = "0" ] && [ "$user" = "root" ]; then
            a_output+=("- /etc/cron.daily/ owner is correct: Uid: $uid/$user")
        else
            a_output2+=("- /etc/cron.daily/ owner is incorrect: Uid: $uid/$user (expected: 0/root)")
        fi

        if [ "$gid" = "0" ] && [ "$group" = "root" ]; then
            a_output+=("- /etc/cron.daily/ group is correct: Gid: $gid/$group")
        else
            a_output2+=("- /etc/cron.daily/ group is incorrect: Gid: $gid/$group (expected: 0/root)")
        fi
    else
        a_output2+=("- /etc/cron.daily/ does not exist")
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