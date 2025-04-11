#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if systemd (including journald) is installed
if dpkg -l systemd &>/dev/null || rpm -q systemd &>/dev/null; then
    # Check enabled status for both units
    enabled_check=$(systemctl is-enabled systemd-journal-remote.socket systemd-journal-remote.service 2>/dev/null | grep -P -- '^enabled')
    if [ -z "$enabled_check" ]; then
        a_output+=("- systemd-journal-remote.socket is not enabled")
        a_output+=("- systemd-journal-remote.service is not enabled")
    else
        while read -r line; do
            a_output2+=("- $line is enabled (should not be)")
            a_output2+=("- Disable with: systemctl disable $line")
        done <<< "$enabled_check"
    fi

    # Check active status for both units
    active_check=$(systemctl is-active systemd-journal-remote.socket systemd-journal-remote.service 2>/dev/null | grep -P -- '^active')
    if [ -z "$active_check" ]; then
        a_output+=("- systemd-journal-remote.socket is not active")
        a_output+=("- systemd-journal-remote.service is not active")
    else
        while read -r line; do
            a_output2+=("- $line is active (should not be)")
            a_output2+=("- Stop with: systemctl stop $line")
        done <<< "$active_check"
    fi

    # Determine result
    if [ ${#a_output2[@]} -eq 0 ]; then
        audit_result="PASS"
    else
        audit_result="FAIL"
    fi
else
    # journald not installed, skip audit
    audit_result="SKIP"
    a_output+=("- systemd-journald is not installed")
    a_output+=("- This audit is skipped as journald is not the chosen logging method")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
echo "--------------------------"
echo "Note: This audit applies only if journald is the chosen method for client-side logging. Ignore if rsyslog is used."