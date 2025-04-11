#!/usr/bin/env bash

a_output=()
a_output2=()

while read -r l_count l_uid; do
    if [ "$l_count" -gt 1 ]; then
        l_users=$(awk -F: '($3 == n) { print $1 }' n="$l_uid" /etc/passwd | xargs)
        a_output2+=("- Duplicate UID: \"$l_uid\" Users: \"$l_users\"")
    fi
done < <(cut -f3 -d":" /etc/passwd | sort -n | uniq -c)

if [ ${#a_output2[@]} -eq 0 ]; then
    a_output+=("- No duplicate UIDs found in /etc/passwd")
fi

if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
else
    audit_result="FAIL"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"