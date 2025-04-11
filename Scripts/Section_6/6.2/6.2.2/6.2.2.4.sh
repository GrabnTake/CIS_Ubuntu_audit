#!/usr/bin/env bash

a_output=()
a_output2=()

# Check space_left_action
l_space_left_action=$(grep -P -- '^\h*space_left_action\h*=\h*(email|exec|single|halt)\b' /etc/audit/auditd.conf 2>/dev/null)
if [ -n "$l_space_left_action" ]; then
    l_space_value=$(echo "$l_space_left_action" | grep -Po '(email|exec|single|halt)\b')
    a_output+=("- space_left_action is set to '$l_space_value' (valid: email, exec, single, or halt)")
    [ "$l_space_value" = "email" ] && a_output+=("- Note: Ensure a Mail Transfer Agent (MTA) is installed and configured for 'email' action")
else
    l_space_any=$(grep -Po -- '^\h*space_left_action\h*=\h*\S+' /etc/audit/auditd.conf 2>/dev/null)
    if [ -n "$l_space_any" ]; then
        l_space_value=$(echo "$l_space_any" | grep -Po '(?<=\h*=)\h*\S+')
        a_output2+=("- space_left_action is set to '$l_space_value' (invalid; must be 'email', 'exec', 'single', or 'halt')")
    else
        a_output2+=("- space_left_action is not set in /etc/audit/auditd.conf (default is 'syslog', invalid; must be 'email', 'exec', 'single', or 'halt')")
    fi
    a_output2+=("- Update /etc/audit/auditd.conf to set space_left_action to 'email', 'exec', 'single', or 'halt'")
fi

# Check admin_space_left_action
l_admin_space_left_action=$(grep -P -- '^\h*admin_space_left_action\h*=\h*(single|halt)\b' /etc/audit/auditd.conf 2>/dev/null)
if [ -n "$l_admin_space_left_action" ]; then
    l_admin_value=$(echo "$l_admin_space_left_action" | grep -Po '(single|halt)\b')
    a_output+=("- admin_space_left_action is set to '$l_admin_value' (valid: single or halt)")
else
    l_admin_any=$(grep -Po -- '^\h*admin_space_left_action\h*=\h*\S+' /etc/audit/auditd.conf 2>/dev/null)
    if [ -n "$l_admin_any" ]; then
        l_admin_value=$(echo "$l_admin_any" | grep -Po '(?<=\h*=)\h*\S+')
        a_output2+=("- admin_space_left_action is set to '$l_admin_value' (invalid; must be 'single' or 'halt')")
    else
        a_output2+=("- admin_space_left_action is not set in /etc/audit/auditd.conf (default is 'suspend', invalid; must be 'single' or 'halt')")
    fi
    a_output2+=("- Update /etc/audit/auditd.conf to set admin_space_left_action to 'single' or 'halt'")
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