#!/usr/bin/env bash

a_output=()
a_output2=()

# Permission mask for 0640 (rw-r-----), restricting to owner read/write, group read
l_perm_mask="0137"  # Bits to disallow: o+rwx, g+w
l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )))"  # 0640

# Check if /etc/audit/ exists
if [ -d "/etc/audit/" ]; then
    # Check all .conf and .rules files in /etc/audit/
    while IFS= read -r -d $'\0' l_fname; do
        l_mode="$(stat -Lc '%#a' "$l_fname")"
        if [ $(( "$l_mode" & "$l_perm_mask" )) -gt 0 ]; then
            a_output2+=("- File: \"$l_fname\" is mode: \"$l_mode\" (should be mode: \"$l_maxperm\" or more restrictive)")
        fi
    done < <(find /etc/audit/ -type f \( -name "*.conf" -o -name '*.rules' \) -print0)
    
    # If no violations found, report success
    if [ ${#a_output2[@]} -eq 0 ]; then
        a_output+=("- All audit configuration files in /etc/audit/ are mode: \"$l_maxperm\" or more restrictive")
    fi
else
    a_output2+=("- Directory: \"/etc/audit/\" not found - verify auditd is installed")
fi

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