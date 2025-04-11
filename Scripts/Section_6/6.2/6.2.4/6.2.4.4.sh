#!/usr/bin/env bash

a_output=()
a_output2=()

# Permission mask for 0750 (rwxr-x---), restricting to owner rwx, group rx
l_perm_mask="0027"  # Bits to disallow: o+rwx
l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )))"  # 0750

# Check if auditd.conf exists
if [ -e "/etc/audit/auditd.conf" ]; then
    # Extract log file path and get its directory
    l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/{print $2}' /etc/audit/auditd.conf | xargs)")"
    
    # Verify the directory exists
    if [ -d "$l_audit_log_directory" ]; then
        # Check directory permissions
        l_directory_mode="$(stat -Lc '%#a' "$l_audit_log_directory")"
        if [ $(( $l_directory_mode & $l_perm_mask )) -gt 0 ]; then
            a_output2+=("- Directory: \"$l_audit_log_directory\" is mode: \"$l_directory_mode\" (should be mode: \"$l_maxperm\" or more restrictive)")
        else
            a_output+=("- Directory: \"$l_audit_log_directory\" is mode: \"$l_directory_mode\" (mode: \"$l_maxperm\" or more restrictive)")
        fi
    else
        a_output2+=("- Log file directory \"$l_audit_log_directory\" not found or not set in \"/etc/audit/auditd.conf\"")
    fi
else
    a_output2+=("- File: \"/etc/audit/auditd.conf\" not found - verify auditd is installed")
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