#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if rsyslog is installed
if dpkg-query -s rsyslog &>/dev/null; then
    a_output+=("- rsyslog is installed")
    audit_result="PASS"
else
    # Check if journald is installed (indicating rsyslog isn’t the chosen method)
    if dpkg -l systemd &>/dev/null || rpm -q systemd &>/dev/null; then
        a_output+=("- rsyslog is not installed")
        a_output+=("- This audit is skipped as rsyslog is not the chosen logging method (journald likely in use)")
        audit_result="SKIP"
    else
        a_output2+=("- rsyslog is not installed")
        a_output2+=("- Install rsyslog with: apt install rsyslog (or equivalent for your package manager)")
        audit_result="FAIL"
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
echo "--------------------------"
echo "Note: This audit applies only if rsyslog is the chosen method for client-side logging. Ignore if journald is used."