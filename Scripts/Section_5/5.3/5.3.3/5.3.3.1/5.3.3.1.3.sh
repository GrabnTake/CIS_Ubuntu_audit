#!/usr/bin/env bash

a_output=()
a_output2=()

# Check for even_deny_root or root_unlock_time in faillock.conf
faillock_settings=$(grep -Pi '^\h*(even_deny_root|root_unlock_time\h*=\h*\d+)\b' /etc/security/faillock.conf 2>/dev/null)
# Check for root_unlock_time < 60 in faillock.conf
low_unlock_conf=$(grep -Pi '^\h*root_unlock_time\h*=\h*([1-9]|[1-5][0-9])\b' /etc/security/faillock.conf 2>/dev/null)
# Check for root_unlock_time < 60 in pam_faillock.so
low_unlock_pam=$(grep -Pi '^\h*auth\h+([^#\n\r]+\h+)pam_faillock\.so\h+([^#\n\r]+\h+)?root_unlock_time\h*=\h*([1-9]|[1-5][0-9])\b' /etc/pam.d/common-auth 2>/dev/null)

if [ -n "$faillock_settings" ] && [ -z "$low_unlock_conf" ] && [ -z "$low_unlock_pam" ]; then
    audit_result="PASS"
    a_output+=("- even_deny_root and/or root_unlock_time enabled: $faillock_settings")
    a_output+=("- No root_unlock_time < 60 found in /etc/security/faillock.conf or /etc/pam.d/common-auth")
else
    audit_result="FAIL"
    [ -z "$faillock_settings" ] && a_output2+=("- Neither even_deny_root nor root_unlock_time is enabled in /etc/security/faillock.conf")
    [ -n "$low_unlock_conf" ] && a_output2+=("- root_unlock_time < 60 found in /etc/security/faillock.conf: $low_unlock_conf")
    [ -n "$low_unlock_pam" ] && a_output2+=("- root_unlock_time < 60 found in /etc/pam.d/common-auth: $low_unlock_pam")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"