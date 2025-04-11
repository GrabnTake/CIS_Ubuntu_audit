#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if SSH server is in use
if ! { dpkg-query -s openssh-server &>/dev/null && systemctl is-active ssh &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- SSH server is not in use (not installed or not active), audit skipped")
else
    # Get ClientAlive settings
    sshd_output=$(sshd -T 2>/dev/null | grep -Pi '(clientaliveinterval|clientalivecountmax)')
    interval=$(echo "$sshd_output" | grep -i "clientaliveinterval" | awk '{print $2}')
    countmax=$(echo "$sshd_output" | grep -i "clientalivecountmax" | awk '{print $2}')

    # Verify settings
    if [ -n "$interval" ] && [ "$interval" -gt 0 ] && [ -n "$countmax" ] && [ "$countmax" -gt 0 ]; then
        audit_result="PASS"
        a_output+=("- ClientAliveInterval is $interval (greater than 0)")
        a_output+=("- ClientAliveCountMax is $countmax (greater than 0)")
    else
        audit_result="FAIL"
        [ -z "$interval" ] || [ "$interval" -le 0 ] && a_output2+=("- ClientAliveInterval is ${interval:-unset}, must be greater than 0")
        [ -z "$countmax" ] || [ "$countmax" -le 0 ] && a_output2+=("- ClientAliveCountMax is ${countmax:-unset}, must be greater than 0")
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"