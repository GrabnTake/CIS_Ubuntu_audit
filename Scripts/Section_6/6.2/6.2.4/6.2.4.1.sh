#!/usr/bin/env bash

a_output=()
a_output2=()

# Permission mask for 0640 (rw-r-----), restricting to owner read/write, group read
l_perm_mask="0137"  # Bits to disallow: o+rwx, g+w
l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )))"  # 0640

# Check if auditd.conf exists
if [ -e "/etc/audit/auditd.conf" ]; then
    # Extract log file path and get its directory
    l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/{print $2}' /etc/audit/auditd.conf | xargs)")"
    
    # Verify the directory exists
    if [ -d "$l_audit_log_directory" ]; then
        # Find files with permissions less restrictive than 0640
        a_files=()
        while IFS= read -r -d $'\0' l_file; do
            [ -e "$l_file" ] && a_files+=("$l_file")
        done < <(find "$l_audit_log_directory" -maxdepth 1 -type f -perm /"$l_perm_mask" -print0)
        
        # Check results
        if (( "${#a_files[@]}" > 0 )); then
            for l_file in "${a_files[@]}"; do
                l_file_mode="$(stat -Lc '%#a' "$l_file")"
                a_output2+=("- File: \"$l_file\" is mode: \"$l_file_mode\" (should be mode: \"$l_maxperm\" or more restrictive)")
            done
        else
            a_output+=("- All files in \"$l_audit_log_directory\" are mode: \"$l_maxperm\" or more restrictive")
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