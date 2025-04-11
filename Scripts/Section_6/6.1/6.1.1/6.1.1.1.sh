#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if systemd-journald is enabled (should be static)
enabled_status=$(systemctl is-enabled systemd-journald.service 2>/dev/null)
# Check if systemd-journald is active (should be active)
active_status=$(systemctl is-active systemd-journald.service 2>/dev/null)

if [ "$enabled_status" = "static" ]; then
    if [ "$active_status" = "active" ]; then
        audit_result="PASS"
        a_output+=("- systemd-journald.service is enabled (static) and active")
        a_output+=("- Note: 'static' is expected as systemd-journald typically lacks an [Install] section")
    else
        audit_result="FAIL"
        a_output2+=("- systemd-journald.service is enabled (static) but not active (current status: \"$active_status\")")
        a_output2+=("- Expected active status: \"active\"")
    fi
else
    audit_result="FAIL"
    a_output2+=("- systemd-journald.service is not enabled as 'static' (current status: \"$enabled_status\")")
    a_output2+=("- Note: Investigate why status is not 'static', as it should lack an [Install] section")
    [ "$active_status" != "active" ] && a_output2+=("- systemd-journald.service is also not active (current status: \"$active_status\")")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"