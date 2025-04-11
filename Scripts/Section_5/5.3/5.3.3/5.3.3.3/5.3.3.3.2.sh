#!/usr/bin/env bash

a_output=()
a_output2=()

# Check pwhistory with enforce_for_root in common-password
pwhistory_line=$(grep -Psi -- '^\h*password\h+[^#\n\r]+\h+pam_pwhistory\.so\h+([^#\n\r]+\h+)?enforce_for_root\b' /etc/pam.d/common-password 2>/dev/null)

if [ -n "$pwhistory_line" ]; then
    audit_result="PASS"
    a_output+=("- pam_pwhistory.so with enforce_for_root found: $pwhistory_line")
else
    audit_result="FAIL"
    a_output2+=("- No pam_pwhistory.so with enforce_for_root found in /etc/pam.d/common-password")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"