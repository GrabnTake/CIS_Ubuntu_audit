#!/usr/bin/env bash

a_output=()
a_output2=()

# Expected value for max_log_file_action
expected_action="keep_logs"

# Check for max_log_file_action setting
l_max_log_file_action=$(grep -Po -- '^\h*max_log_file_action\h*=\h*\S+' /etc/audit/auditd.conf 2>/dev/null)
if [ -n "$l_max_log_file_action" ]; then
    l_value=$(echo "$l_max_log_file_action" | grep -Po '(?<=\h*=)\h*\S+')
    if [ "$l_value" = "$expected_action" ]; then
        a_output+=("- max_log_file_action is set to '$l_value' (matches required value '$expected_action')")
    else
        a_output2+=("- max_log_file_action is set to '$l_value' (does not match required value '$expected_action')")
        a_output2+=("- Update /etc/audit/auditd.conf to set max_log_file_action = $expected_action")
    fi
else
    a_output2+=("- max_log_file_action is not set in /etc/audit/auditd.conf (default is 'rotate', does not match required value '$expected_action')")
    a_output2+=("- Update /etc/audit/auditd.conf to set max_log_file_action = $expected_action")
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