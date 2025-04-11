#!/usr/bin/env bash

a_output=()
a_output2=()

# List of audit tools to check
a_audit_tools=("/sbin/auditctl" "/sbin/aureport" "/sbin/ausearch" "/sbin/autrace" "/sbin/auditd" "/sbin/augenrules")

# Check ownership of each audit tool
for l_audit_tool in "${a_audit_tools[@]}"; do
    if [ -e "$l_audit_tool" ]; then
        l_owner="$(stat -Lc '%U' "$l_audit_tool")"
        if [ "$l_owner" != "root" ]; then
            a_output2+=("- Audit tool \"$l_audit_tool\" is owned by user: \"$l_owner\" (should be owned by user: \"root\")")
        else
            a_output+=("- Audit tool \"$l_audit_tool\" is owned by user: \"root\"")
        fi
    else
        a_output2+=("- Audit tool \"$l_audit_tool\" not found")
    fi
done

# Determine result
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