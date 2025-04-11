#!/usr/bin/env bash

a_output=()
a_output2=()

# Check the status of rsyslog and systemd-journald
if systemctl is-active --quiet rsyslog 2>/dev/null; then
    a_output+=("- rsyslog is in use")
    a_output+=("- Follow the recommendations in Configure rsyslog subsection only")
elif systemctl is-active --quiet systemd-journald 2>/dev/null; then
    a_output+=("- journald is in use")
    a_output+=("- Follow the recommendations in Configure journald subsection only")
else
    a_output2+=("- Unable to determine system logging")
    a_output2+=("- Configure only ONE system logging: rsyslog OR journald")
fi

# Check if both are active (not allowed)
if systemctl is-active --quiet rsyslog 2>/dev/null && systemctl is-active --quiet systemd-journald 2>/dev/null; then
    a_output2+=("- Both rsyslog and journald are in use")
    a_output2+=("- Only ONE logging system should be active")
fi

# Determine result
if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
else
    audit_result="FAIL"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"