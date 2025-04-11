#!/usr/bin/env bash

a_output=()
a_output2=()

# Check users with UID 0 in /etc/passwd
uid_zero_users=$(awk -F: '($3 == 0) { print $1 }' /etc/passwd 2>/dev/null)

# Count and compare
if [ -n "$uid_zero_users" ]; then
    uid_zero_count=$(echo "$uid_zero_users" | wc -l)
    if [ "$uid_zero_count" -eq 1 ] && [ "$uid_zero_users" = "root" ]; then
        audit_result="PASS"
        a_output+=("- Only 'root' has UID 0 in /etc/passwd")
    else
        audit_result="FAIL"
        a_output2+=("- Users with UID 0 in /etc/passwd (should only be 'root'):")
        while IFS= read -r line; do
            a_output2+=("  $line")
        done <<< "$uid_zero_users"
    fi
else
    audit_result="FAIL"
    a_output2+=("- No users with UID 0 found in /etc/passwd (expected 'root')")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"