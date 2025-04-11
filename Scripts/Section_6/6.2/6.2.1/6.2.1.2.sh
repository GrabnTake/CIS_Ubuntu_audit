#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if auditd is enabled
enabled_status=$(systemctl is-enabled auditd | grep '^enabled' 2>/dev/null)
if [ "$enabled_status" = "enabled" ]; then
    a_output+=("- auditd is enabled")
else
    a_output2+=("- auditd is not enabled (current status: $enabled_status)")
    a_output2+=("- Enable it with: systemctl enable auditd")
fi

# Check if auditd is active
active_status=$(systemctl is-active auditd | grep '^active' 2>/dev/null)
if [ "$active_status" = "active" ]; then
    a_output+=("- auditd is active")
else
    a_output2+=("- auditd is not active (current status: $active_status)")
    a_output2+=("- Start it with: systemctl start auditd")
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
