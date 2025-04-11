#!/usr/bin/env bash

a_output=()
a_output2=()

# Check ENCRYPT_METHOD in /etc/login.defs
encrypt_method=$(grep -Pi -- '^\h*ENCRYPT_METHOD\h+(SHA512|yescrypt)\b' /etc/login.defs 2>/dev/null)

if [ -n "$encrypt_method" ]; then
    audit_result="PASS"
    a_output+=("- ENCRYPT_METHOD is set to a strong hashing algorithm: $encrypt_method")
else
    audit_result="FAIL"
    a_output2+=("- ENCRYPT_METHOD is not set to SHA512 or yescrypt in /etc/login.defs")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"