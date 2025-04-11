#!/usr/bin/env bash

a_output=()   
a_output2=()   

# Check for duplicate group names in /etc/group
while read -r l_count l_group; do
    if [ "$l_count" -gt 1 ]; then
        # Extract group names with the duplicate name (redundant but matches original)
        l_groups=$(awk -F: '($1 == n) { print $1 }' n="$l_group" /etc/group | xargs)
        a_output2+=("- Duplicate Group: \"$l_group\" appears $l_count times in /etc/group")
    fi
done < <(cut -f1 -d":" /etc/group | sort | uniq -c)  # Get group name counts from /etc/group

# Report success if no duplicates found
if [ ${#a_output2[@]} -eq 0 ]; then
    a_output+=("- No duplicate group names found in /etc/group")
fi

# Determine audit result
if [ ${#a_output2[@]} -eq 0 ]; then
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