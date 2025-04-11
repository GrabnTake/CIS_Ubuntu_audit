#!/usr/bin/env bash

a_output=()
a_output2=()

# Check systemd-timesyncd
if systemctl is-enabled systemd-timesyncd.service 2>/dev/null | grep -q 'enabled' || systemctl is-active systemd-timesyncd.service 2>/dev/null | grep -q '^active'; then
    timesyncd_active="y"
    a_output2+=("- Daemon: \"systemd-timesyncd\" is enabled or active")
else
    timesyncd_active="n"
    a_output+=("- Daemon: \"systemd-timesyncd\" is not enabled or active")
fi

# Check chrony
if systemctl is-enabled chrony.service 2>/dev/null | grep -q 'enabled' || systemctl is-active chrony.service 2>/dev/null | grep -q '^active'; then
    chrony_active="y"
    a_output2+=("- Daemon: \"chrony\" is enabled or active")
else
    chrony_active="n"
    a_output+=("- Daemon: \"chrony\" is not enabled or active")
fi

# Determine status
status="$timesyncd_active$chrony_active"
case "$status" in
    "yy")
        a_output2+=("- More than one time sync daemon is in use")
        ;;
    "nn")
        a_output2+=("- No time sync daemon is in use")
        ;;
    "yn"|"ny")
        a_output+=("- Only one time sync daemon is in use")
        ;;
    *)
        a_output2+=("- Unable to determine time sync daemon status")
        ;;
esac

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