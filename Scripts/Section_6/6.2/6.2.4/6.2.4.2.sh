#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if auditd.conf exists
if [ -e "/etc/audit/auditd.conf" ]; then
    # Extract log file path and get its directory
    l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/{print $2}' /etc/audit/auditd.conf | xargs)")"
    
    # Verify the directory exists
    if [ -d "$l_audit_log_directory" ]; then
        # Find files not owned by root
        while IFS= read -r -d $'\0' l_file; do
            l_owner="$(stat -Lc '%U' "$l_file")"
            a_output2+=("- File: \"$l_file\" is owned by user: \"$l_owner\" (should be owned by user: \"root\")")
        done < <(find "$l_audit_log_directory" -maxdepth 1 -type f ! -user root -print0)
        
        # If no violations found, report success
        if [ ${#a_output2[@]} -eq 0 ]; then
            a_output+=("- All files in \"$l_audit_log_directory\" are owned by user: \"root\"")
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