#!/usr/bin/env bash

a_output=()
a_output2=()

# Check for pam_pwhistory.so in common-password
pam_pwhistory=$(grep -P '\bpam_pwhistory\.so\b' /etc/pam.d/common-password 2>/dev/null)

if [ -n "$pam_pwhistory" ]; then
    audit_result="PASS"
    a_output+=("- pam_pwhistory is enabled in the following PAM configuration:")
    while IFS= read -r line; do
        a_output+=("  $line")
    done <<< "$pam_pwhistory"
else
    audit_result="FAIL"
    a_output2+=("- pam_pwhistory.so is not enabled in /etc/pam.d/common-password")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"