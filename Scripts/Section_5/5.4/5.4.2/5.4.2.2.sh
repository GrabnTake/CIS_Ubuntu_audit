#!/usr/bin/env bash

a_output=()
a_output2=()

# Check users with GID 0 in /etc/passwd, excluding sync, shutdown, halt, operator
gid_zero_users=$(awk -F: '($1 !~ /^(sync|shutdown|halt|operator)/ && $4=="0") {print $1":"$4}' /etc/passwd 2>/dev/null)

# Analyze results
if [ -n "$gid_zero_users" ]; then
    gid_zero_count=$(echo "$gid_zero_users" | wc -l)
    root_found=$(echo "$gid_zero_users" | grep -Fx "root:0" || true)
    if [ "$gid_zero_count" -eq 1 ] && [ -n "$root_found" ]; then
        audit_result="PASS"
        a_output+=("- Root user's primary GID is 0, and no other users have GID 0 as primary")
    else
        audit_result="FAIL"
        a_output2+=("- Users with primary GID 0 in /etc/passwd (should only be 'root:0'):")
        while IFS= read -r line; do
            a_output2+=("  $line")
        done <<< "$gid_zero_users"
    fi
else
    audit_result="FAIL"
    a_output2+=("- No users with primary GID 0 found in /etc/passwd (expected 'root:0')")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"