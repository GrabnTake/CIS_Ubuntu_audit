#!/usr/bin/env bash

a_output=()    
a_output2=()  

# Check for duplicate usernames in /etc/passwd
while read -r l_count l_user; do
    if [ "$l_count" -gt 1 ]; then
        # Extract usernames with the duplicate name (though typically redundant since $l_user is the name)
        l_users=$(awk -F: '($1 == n) { print $1 }' n="$l_user" /etc/passwd | xargs)
        a_output2+=("- Duplicate User: \"$l_user\" appears $l_count times in /etc/passwd")
    fi
done < <(cut -f1 -d":" /etc/passwd | sort | uniq -c)  # Get username counts from /etc/passwd (corrected from /etc/group)

# Report success if no duplicates found
if [ ${#a_output2[@]} -eq 0 ]; then
    a_output+=("- No duplicate usernames found in /etc/passwd")
    audit_result="PASS"
else
    audit_result="FAIL"
fi

# Print audit report
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"