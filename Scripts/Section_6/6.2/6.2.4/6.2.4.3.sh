#!/usr/bin/env bash

a_output=()
a_output2=()

# Part 1: Check log_group in auditd.conf
if [ -e "/etc/audit/auditd.conf" ]; then
    # Grep for log_group, exclude 'adm' as per command (implies root is expected)
    log_group_output=$(grep -Piws -- '^\h*log_group\h*=\h*\H+\b' /etc/audit/auditd.conf | grep -Pvi -- '(adm)')
    if [ -n "$log_group_output" ]; then
        a_output2+=("- log_group setting in \"/etc/audit/auditd.conf\" is invalid: \"$log_group_output\" (must be \"root\" or \"adm\")")
    else
        log_group_value=$(awk -F '=' '/^\s*log_group\s*=/ {print $2}' /etc/audit/auditd.conf | xargs)
        a_output+=("- log_group in \"/etc/audit/auditd.conf\" is set to: \"$log_group_value\" (valid: \"root\" or \"adm\")")
    fi

    # Part 2: Check group ownership of audit log files
    l_fpath="$(dirname "$(awk -F "=" '/^\s*log_file/ {print $2}' /etc/audit/auditd.conf | xargs)")"
    if [ -d "$l_fpath" ]; then
        # Find files not owned by root or adm group, excluding lost+found
        while IFS= read -r l_file; do
            l_group="$(stat -Lc '%G' "$l_file")"
            a_output2+=("- File: \"$l_file\" is owned by group: \"$l_group\" (should be \"root\" or \"adm\")")
        done < <(find -L "$l_fpath" -not -path "$l_fpath/lost+found" -type f \( ! -group root -a ! -group adm \) -print)
    else
        a_output2+=("- Log file directory \"$l_fpath\" not found or not set in \"/etc/audit/auditd.conf\"")
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