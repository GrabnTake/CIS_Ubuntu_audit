#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if systemd-journald is active
if systemctl is-active --quiet systemd-journald 2>/dev/null; then
    # journald is active, check systemd-journal-remote
    if dpkg-query -s systemd-journal-remote &>/dev/null; then
        a_output+=("- systemd-journald is active")
        a_output+=("- systemd-journal-remote is installed")
        audit_result="PASS"
    else
        a_output+=("- systemd-journald is active")
        a_output2+=("- systemd-journal-remote is not installed")
        a_output2+=("- Install systemd-journal-remote for journald logging")
        audit_result="FAIL"
    fi
else
    # journald is not active, audit doesn’t apply
    a_output+=("- systemd-journald is not active")
    a_output+=("- This audit is not applicable as journald is not the chosen logging method")
    audit_result="N/A"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
echo "--------------------------"
echo "Note: This audit applies only if journald is the chosen method for client-side logging. Ignore if rsyslog is used."