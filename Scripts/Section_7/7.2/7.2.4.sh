#!/usr/bin/env bash

a_output=()
a_output2=()

# Get the GID of the shadow group
shadow_gid=$(getent group shadow | awk -F: '{print $3}' | xargs)

# Check 1: Verify no users are listed in the shadow group in /etc/group
while IFS= read -r l_users; do
    if [ -n "$l_users" ]; then
        a_output2+=("- The 'shadow' group in /etc/group has users listed: \"$l_users\" (should be empty)")
    fi
done < <(awk -F: '($1=="shadow") {print $NF}' /etc/group)

# Check 2: Verify no users in /etc/passwd have shadow as their primary group
if [ -n "$shadow_gid" ]; then
    while IFS= read -r l_line; do
        a_output2+=("- $l_line")
    done < <(awk -F: '($4 == "'"$shadow_gid"'") {print "User: \"" $1 "\" primary group is the shadow group"}' /etc/passwd)
else
    a_output2+=("- The 'shadow' group does not exist in /etc/group")
fi

# If no violations found, report success
if [ ${#a_output2[@]} -eq 0 ]; then
    a_output+=("- No users are listed in the 'shadow' group in /etc/group")
    a_output+=("- No users in /etc/passwd have the 'shadow' group as their primary group")
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