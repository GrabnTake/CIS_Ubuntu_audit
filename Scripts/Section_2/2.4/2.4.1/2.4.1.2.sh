#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if cron/crond is installed
if systemctl list-unit-files | grep -E '^crond?\.service' >/dev/null 2>&1; then
    # Get stat output for /etc/crontab
    crontab_stat=$(stat -Lc 'Access: (%a/%A) Uid: (%u/%U) Gid: (%g/%G)' /etc/crontab 2>/dev/null)

    if [ -n "$crontab_stat" ]; then
        # Parse stat output
        access=$(echo "$crontab_stat" | grep -oP 'Access: \(\K[^)]+')
        uid=$(echo "$crontab_stat" | grep -oP 'Uid: \(\s*\K\d+')
        gid=$(echo "$crontab_stat" | grep -oP 'Gid: \(\s*\K\d+')
        user=$(echo "$crontab_stat" | grep -oP 'Uid: .*/\s*\K[^)]+')
        group=$(echo "$crontab_stat" | grep -oP 'Gid: .*/\s*\K[^)]+')

        # Check permissions and ownership
        if [ "$access" = "600/-rw-------" ]; then
            a_output+=("- /etc/crontab permissions are correct: \"$access\"")
        else
            a_output2+=("- /etc/crontab permissions are incorrect: \"$access\" (expected: 600/-rw-------)")
        fi

        if [ "$uid" = "0" ] && [ "$user" = "root" ]; then
            a_output+=("- /etc/crontab owner is correct: Uid: $uid/$user")
        else
            a_output2+=("- /etc/crontab owner is incorrect: Uid: $uid/$user (expected: 0/root)")
        fi

        if [ "$gid" = "0" ] && [ "$group" = "root" ]; then
            a_output+=("- /etc/crontab group is correct: Gid: $gid/$group")
        else
            a_output2+=("- /etc/crontab group is incorrect: Gid: $gid/$group (expected: 0/root)")
        fi
    else
        a_output2+=("- /etc/crontab does not exist")
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