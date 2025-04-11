#!/usr/bin/env bash

a_output=()
a_output2=()

# Check pwhistory with remember in common-password
pwhistory_line=$(grep -Psi -- '^\h*password\h+[^#\n\r]+\h+pam_pwhistory\.so\h+([^#\n\r]+\h+)?remember=\d+\b' /etc/pam.d/common-password 2>/dev/null)

if [ -n "$pwhistory_line" ]; then
    # Extract remember value
    remember_value=$(echo "$pwhistory_line" | grep -oP 'remember=\K\d+')
    if [ "$remember_value" -ge 24 ]; then
        audit_result="PASS"
        a_output+=("- pam_pwhistory.so with remember >= 24 found: $pwhistory_line")
        a_output+=("- Note: Verify remember=$remember_value meets local site policy")
    else
        audit_result="FAIL"
        a_output2+=("- pam_pwhistory.so found but remember=$remember_value is less than 24: $pwhistory_line")
    fi
else
    audit_result="FAIL"
    a_output2+=("- No pam_pwhistory.so with remember=<N> found in /etc/pam.d/common-password")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"