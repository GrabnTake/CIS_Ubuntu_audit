#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if systemd (including journald) is installed
if dpkg -l systemd &>/dev/null || rpm -q systemd &>/dev/null; then
    # Check if systemd-journal-upload.service is enabled
    enabled_status=$(systemctl is-enabled systemd-journal-upload.service 2>/dev/null)
    if [ "$enabled_status" = "enabled" ]; then
        a_output+=("- systemd-journal-upload.service is enabled")
    else
        a_output2+=("- systemd-journal-upload.service is not enabled (current status: $enabled_status)")
        a_output2+=("- Enable it with: systemctl enable systemd-journal-upload.service")
    fi

    # Check if systemd-journal-upload.service is active
    active_status=$(systemctl is-active systemd-journal-upload.service 2>/dev/null)
    if [ "$active_status" = "active" ]; then
        a_output+=("- systemd-journal-upload.service is active")
    else
        a_output2+=("- systemd-journal-upload.service is not active (current status: $active_status)")
        a_output2+=("- Start it with: systemctl start systemd-journal-upload.service")
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