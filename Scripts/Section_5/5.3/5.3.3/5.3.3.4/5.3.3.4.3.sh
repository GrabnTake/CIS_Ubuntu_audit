#!/usr/bin/env bash

a_output=()
a_output2=()

# Check pam_unix.so with strong hashing algorithm in common-password
pam_unix_hash=$(grep -PH -- '^\h*password\h+([^#\n\r]+)\h+pam_unix\.so\h+([^#\n\r]+\h+)?(sha512|yescrypt)\b' /etc/pam.d/common-password 2>/dev/null)

if [ -n "$pam_unix_hash" ]; then
    audit_result="PASS"
    a_output+=("- pam_unix.so with strong hashing algorithm (sha512 or yescrypt) found:")
    while IFS= read -r line; do
        a_output+=("  $line")
    done <<< "$pam_unix_hash"
else
    audit_result="FAIL"
    a_output2+=("- No pam_unix.so with sha512 or yescrypt found in /etc/pam.d/common-password")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"