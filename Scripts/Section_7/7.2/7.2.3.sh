#!/usr/bin/env bash

a_output=()
a_output2=()

# Get unique GIDs from /etc/passwd and /etc/group
a_passwd_group_gid=($(awk -F: '{print $4}' /etc/passwd | sort -u))
a_group_gid=($(awk -F: '{print $3}' /etc/group | sort -u))

# Find GIDs that are in /etc/passwd but not in /etc/group
# (unique lines from the union of both arrays, then find duplicates with passwd GIDs)
a_passwd_group_diff=($(printf '%s\n' "${a_group_gid[@]}" "${a_passwd_group_gid[@]}" | sort | uniq -u))
l_missing_gids=($(printf '%s\n' "${a_passwd_group_gid[@]}" "${a_passwd_group_diff[@]}" | sort | uniq -D | uniq))

# Check each missing GID and list users in /etc/passwd with that GID
while IFS= read -r l_gid; do
    while IFS= read -r l_line; do
        a_output2+=("- $l_line")
    done < <(awk -F: '($4 == "'"$l_gid"'") {print "User: \"" $1 "\" has GID: \"" $4 "\" which does not exist in /etc/group"}' /etc/passwd)
done < <(printf '%s\n' "${l_missing_gids[@]}")

# If no violations found, report success
if [ ${#a_output2[@]} -eq 0 ]; then
    a_output+=("- All GIDs in /etc/passwd exist in /etc/group")
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