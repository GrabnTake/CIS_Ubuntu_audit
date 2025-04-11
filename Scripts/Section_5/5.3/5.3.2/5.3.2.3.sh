#!/usr/bin/env bash

a_output=()
a_output2=()

# Check for pam_pwquality.so in common-password
pam_pwquality=$(grep -P '\bpam_pwquality\.so\b' /etc/pam.d/common-password 2>/dev/null)

if [ -n "$pam_pwquality" ]; then
    audit_result="PASS"
    a_output+=("- pam_pwquality is enabled in the following PAM configuration:")
    while IFS= read -r line; do
        a_output+=("  $line")
    done <<< "$pam_pwquality"
else
    audit_result="FAIL"
    a_output2+=("- pam_pwquality.so is not enabled in /etc/pam.d/common-password")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"