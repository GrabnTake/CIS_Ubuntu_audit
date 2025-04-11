#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if /etc/audit/ exists
if [ -d "/etc/audit/" ]; then
    # Check ownership of .conf and .rules files
    while IFS= read -r l_fname; do
        l_owner="$(stat -Lc '%U' "$l_fname")"
        a_output2+=("- File: \"$l_fname\" is owned by user: \"$l_owner\" (should be owned by user: \"root\")")
    done < <(find /etc/audit/ -type f \( -name "*.conf" -o -name '*.rules' \) ! -user root -print)
    
    # If no violations found, report success
    if [ ${#a_output2[@]} -eq 0 ]; then
        a_output+=("- All audit configuration files in /etc/audit/ are owned by user: \"root\"")
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

