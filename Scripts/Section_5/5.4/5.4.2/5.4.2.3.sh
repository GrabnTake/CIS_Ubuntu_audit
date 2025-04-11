#!/usr/bin/env bash

a_output=()
a_output2=()

# Check groups with GID 0 in /etc/group
gid_zero_groups=$(awk -F: '$3=="0"{print $1":"$3}' /etc/group 2>/dev/null)

# Analyze results
if [ -n "$gid_zero_groups" ]; then
    gid_zero_count=$(echo "$gid_zero_groups" | wc -l)
    root_found=$(echo "$gid_zero_groups" | grep -Fx "root:0" || true)
    if [ "$gid_zero_count" -eq 1 ] && [ -n "$root_found" ]; then
        audit_result="PASS"
        a_output+=("- Only 'root' group has GID 0 in /etc/group")
        a_output+=("- Rationale: Ensures root group owned files remain inaccessible to non-privileged users")
    else
        audit_result="FAIL"
        a_output2+=("- Groups with GID 0 in /etc/group (should only be 'root:0'):")
        while IFS= read -r line; do
            a_output2+=("  $line")
        done <<< "$gid_zero_groups"
    fi
else
    audit_result="FAIL"
    a_output2+=("- No groups with GID 0 found in /etc/group (expected 'root:0')")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"