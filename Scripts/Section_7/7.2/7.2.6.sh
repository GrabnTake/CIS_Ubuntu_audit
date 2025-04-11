#!/usr/bin/env bash

a_output=()    
a_output2=()   

# Check for duplicate GIDs in /etc/group
while read -r l_count l_gid; do
    if [ "$l_count" -gt 1 ]; then
        # Extract group names with the duplicate GID
        l_groups=$(awk -F: '($3 == n) { print $1 }' n="$l_gid" /etc/group | xargs)
        a_output2+=("- Duplicate GID: \"$l_gid\" Groups: \"$l_groups\"")
    fi
done < <(cut -f3 -d":" /etc/group | sort -n | uniq -c)  # Get GID counts from /etc/group

# Report success if no duplicates found
if [ ${#a_output2[@]} -eq 0 ]; then
    a_output+=("- No duplicate GIDs found in /etc/group")
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