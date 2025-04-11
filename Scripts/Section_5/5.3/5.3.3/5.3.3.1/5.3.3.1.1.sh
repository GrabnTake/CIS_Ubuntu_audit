#!/usr/bin/env bash

a_output=()
a_output2=()

# Check deny in faillock.conf
faillock_deny=$(grep -Pi '^\h*deny\h*=\h*[1-5]\b' /etc/security/faillock.conf 2>/dev/null)
# Check for excessive deny in pam_faillock.so
pam_deny=$(grep -Pi '^\h*auth\h+(requisite|required|sufficient)\h+pam_faillock\.so\h+([^#\n\r]+\h+)?deny\h*=\h*(0|[6-9]|[1-9][0-9]+)\b' /etc/pam.d/common-auth 2>/dev/null)

if [ -n "$faillock_deny" ] && [ -z "$pam_deny" ]; then
    audit_result="PASS"
    a_output+=("- deny in /etc/security/faillock.conf is set to 5 or less: $faillock_deny")
    a_output+=("- No excessive deny (>5) found in /etc/pam.d/common-auth")
    a_output+=("- Note: Verify deny value meets local site policy")
else
    audit_result="FAIL"
    [ -z "$faillock_deny" ] && a_output2+=("- deny in /etc/security/faillock.conf is not set to 1-5")
    [ -n "$pam_deny" ] && a_output2+=("- Excessive deny (>5) found in /etc/pam.d/common-auth: $pam_deny")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"