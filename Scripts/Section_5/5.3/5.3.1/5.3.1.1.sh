#!/usr/bin/env bash

a_output=()
a_output2=()

# Check libpam-runtime version
pam_status=$(dpkg-query -s libpam-runtime 2>/dev/null | grep -P '^(Status|Version)\b')

if [ -n "$pam_status" ] && echo "$pam_status" | grep -q "Status: install ok installed"; then
    audit_result="PASS"
    a_output+=("- libpam-runtime is installed with the following details:")
    while IFS= read -r line; do
        a_output+=("  $line")
    done <<< "$pam_status"
else
    audit_result="FAIL"
    a_output2+=("- libpam-runtime is not installed or status is not 'install ok installed'")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"