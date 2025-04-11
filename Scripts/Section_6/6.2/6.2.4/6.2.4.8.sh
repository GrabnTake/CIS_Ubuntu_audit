#!/usr/bin/env bash

a_output=()
a_output2=()

# Permission mask for 0755 (rwxr-xr-x), restricting to owner rwx, group rx, others rx
l_perm_mask="0022"  # Bits to disallow: o+w, g+w
l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )))"  # 0755

# List of audit tools to check
a_audit_tools=("/sbin/auditctl" "/sbin/aureport" "/sbin/ausearch" "/sbin/autrace" "/sbin/auditd" "/sbin/augenrules")

# Check each audit tool's permissions
for l_audit_tool in "${a_audit_tools[@]}"; do
    if [ -e "$l_audit_tool" ]; then
        l_mode="$(stat -Lc '%#a' "$l_audit_tool")"
        if [ $(( "$l_mode" & "$l_perm_mask" )) -gt 0 ]; then
            a_output2+=("- Audit tool \"$l_audit_tool\" is mode: \"$l_mode\" (should be mode: \"$l_maxperm\" or more restrictive)")
        else
            a_output+=("- Audit tool \"$l_audit_tool\" is mode: \"$l_mode\" (mode: \"$l_maxperm\" or more restrictive)")
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