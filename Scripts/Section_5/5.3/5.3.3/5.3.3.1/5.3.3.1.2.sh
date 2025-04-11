#!/usr/bin/env bash

a_output=()
a_output2=()

# Check unlock_time in faillock.conf
unlock_time_conf=$(grep -Pi '^\h*unlock_time\h*=\h*(0|9[0-9][0-9]|[1-9][0-9]{3,})\b' /etc/security/faillock.conf 2>/dev/null)
# Check for invalid unlock_time in pam_faillock.so
unlock_time_pam=$(grep -Pi '^\h*auth\h+(requisite|required|sufficient)\h+pam_faillock\.so\h+([^#\n\r]+\h+)?unlock_time\h*=\h*([1-9]|[1-9][0-9]|[1-8][0-9][0-9])\b' /etc/pam.d/common-auth 2>/dev/null)

if [ -n "$unlock_time_conf" ] && [ -z "$unlock_time_pam" ]; then
    audit_result="PASS"
    a_output+=("- unlock_time in /etc/security/faillock.conf is 0 or ≥900: $unlock_time_conf")
    a_output+=("- No invalid unlock_time (1-899) found in /etc/pam.d/common-auth")
    a_output+=("- Note: Verify unlock_time meets local site policy")
else
    audit_result="FAIL"
    [ -z "$unlock_time_conf" ] && a_output2+=("- unlock_time in /etc/security/faillock.conf is not set to 0 or ≥900")
    [ -n "$unlock_time_pam" ] && a_output2+=("- Invalid unlock_time (1-899) found in /etc/pam.d/common-auth: $unlock_time_pam")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"