#!/usr/bin/env bash

a_output=()
a_output2=()

# Check for pam_unix.so in common PAM files
pam_unix=$(grep -P '\bpam_unix\.so\b' /etc/pam.d/common-{account,session,auth,password} 2>/dev/null)

if [ -n "$pam_unix" ]; then
    audit_result="PASS"
    a_output+=("- pam_unix is enabled in the following PAM configurations:")
    while IFS= read -r line; do
        a_output+=("  $line")
    done <<< "$pam_unix"
else
    audit_result="FAIL"
    a_output2+=("- pam_unix.so is not enabled in /etc/pam.d/common-{account,session,auth,password}")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"