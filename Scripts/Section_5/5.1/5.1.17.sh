#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if SSH server is in use
if ! { dpkg-query -s openssh-server &>/dev/null && systemctl is-active ssh &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- SSH server is not in use (not installed or not active), audit skipped")
else
    # Check MaxSessions from sshd -T
    maxsessions=$(sshd -T 2>/dev/null | grep -i "maxsessions" | awk '{print $2}')

    # Check config files for excessive MaxSessions
    config_files="/etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf"
    bad_maxsessions=$(grep -Psi '^\h*MaxSessions\h+\"?(1[1-9]|[2-9][0-9]|[1-9][0-9][0-9]+)\b' $config_files 2>/dev/null)

    if [ -n "$maxsessions" ] && [ "$maxsessions" -le 10 ]; then
        a_output+=("- MaxSessions is $maxsessions (10 or less)")
        if [ -z "$bad_maxsessions" ]; then
            audit_result="PASS"
            a_output+=("- No MaxSessions greater than 10 found in config files")
        else
            audit_result="FAIL"
            a_output2+=("- MaxSessions > 10 found in config: $bad_maxsessions")
        fi
    else
        audit_result="FAIL"
        a_output2+=("- MaxSessions is ${maxsessions:-unset}, must be 10 or less")
        [ -n "$bad_maxsessions" ] && a_output2+=("- MaxSessions > 10 found in config: $bad_maxsessions")
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"