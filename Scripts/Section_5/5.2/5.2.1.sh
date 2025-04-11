#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if sudo or sudo-ldap is installed
if dpkg-query -s sudo &>/dev/null; then
    audit_result="PASS"
    a_output+=("- sudo is installed")
elif dpkg-query -s sudo-ldap &>/dev/null; then
    audit_result="PASS"
    a_output+=("- sudo-ldap is installed")
else
    audit_result="FAIL"
    a_output2+=("- Neither sudo nor sudo-ldap is installed")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"