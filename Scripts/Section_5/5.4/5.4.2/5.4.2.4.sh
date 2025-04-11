#!/usr/bin/env bash

a_output=()
a_output2=()

# Check root password status
root_status=$(passwd -S root 2>/dev/null | awk '$2 ~ /^(P|L)/ {print "User: \"" $1 "\" Password is status: " $2}')

if [ -n "$root_status" ]; then
    if echo "$root_status" | grep -qE 'User: "root" Password is status: (P|L)'; then
        audit_result="PASS"
        a_output+=("- $root_status")
        a_output+=("- Note: P means password is set, L means password is locked")
    else
        audit_result="FAIL"
        a_output2+=("- Root password status is invalid: $root_status")
        a_output2+=("- Expected: 'User: \"root\" Password is status: P' or 'L'")
    fi
else
    audit_result="FAIL"
    a_output2+=("- No valid password status returned for root (expected P or L)")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"