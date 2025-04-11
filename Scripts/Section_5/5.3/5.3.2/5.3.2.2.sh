#!/usr/bin/env bash

a_output=()
a_output2=()

# Check for pam_faillock.so in common-auth and common-account
pam_faillock=$(grep -P '\bpam_faillock\.so\b' /etc/pam.d/common-{auth,account} 2>/dev/null)

if [ -n "$pam_faillock" ]; then
    audit_result="PASS"
    a_output+=("- pam_faillock is enabled in the following PAM configurations:")
    while IFS= read -r line; do
        a_output+=("  $line")
    done <<< "$pam_faillock"
else
    audit_result="FAIL"
    a_output2+=("- pam_faillock.so is not enabled in /etc/pam.d/common-{auth,account}")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"