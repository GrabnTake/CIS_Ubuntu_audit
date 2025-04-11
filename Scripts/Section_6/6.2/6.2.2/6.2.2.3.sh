#!/usr/bin/env bash

a_output=()
a_output2=()

# Check disk_full_action
l_disk_full_action=$(grep -Pi -- '^\h*disk_full_action\h*=\h*(halt|single)\b' /etc/audit/auditd.conf 2>/dev/null)
if [ -n "$l_disk_full_action" ]; then
    l_full_value=$(echo "$l_disk_full_action" | grep -Po '(halt|single)\b')
    a_output+=("- disk_full_action is set to '$l_full_value' (valid: halt or single)")
else
    l_full_any=$(grep -Po -- '^\h*disk_full_action\h*=\h*\S+' /etc/audit/auditd.conf 2>/dev/null)
    if [ -n "$l_full_any" ]; then
        l_full_value=$(echo "$l_full_any" | grep -Po '(?<=\h*=)\h*\S+')
        a_output2+=("- disk_full_action is set to '$l_full_value' (invalid; must be 'halt' or 'single')")
    else
        a_output2+=("- disk_full_action is not set in /etc/audit/auditd.conf (default is 'suspend', invalid; must be 'halt' or 'single')")
    fi
    a_output2+=("- Update /etc/audit/auditd.conf to set disk_full_action to 'halt' or 'single'")
fi

# Check disk_error_action
l_disk_error_action=$(grep -Pi -- '^\h*disk_error_action\h*=\h*(syslog|single|halt)\b' /etc/audit/auditd.conf 2>/dev/null)
if [ -n "$l_disk_error_action" ]; then
    l_error_value=$(echo "$l_disk_error_action" | grep -Po '(syslog|single|halt)\b')
    a_output+=("- disk_error_action is set to '$l_error_value' (valid: syslog, single, or halt)")
else
    l_error_any=$(grep -Po -- '^\h*disk_error_action\h*=\h*\S+' /etc/audit/auditd.conf 2>/dev/null)
    if [ -n "$l_error_any" ]; then
        l_error_value=$(echo "$l_error_any" | grep -Po '(?<=\h*=)\h*\S+')
        a_output2+=("- disk_error_action is set to '$l_error_value' (invalid; must be 'syslog', 'single', or 'halt')")
    else
        a_output2+=("- disk_error_action is not set in /etc/audit/auditd.conf (default is 'syslog', valid but verify site policy)")
    fi
    # Only suggest remediation if explicitly invalid
    [ -n "$l_error_any" ] && a_output2+=("- Update /etc/audit/auditd.conf to set disk_error_action to 'syslog', 'single', or 'halt'")
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