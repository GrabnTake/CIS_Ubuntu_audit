#!/usr/bin/env bash

a_output=()
a_output2=()

# Check dictcheck in pwquality config files
dictcheck_conf=$(grep -Psi '^\h*dictcheck\h*=\h*0\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null)
# Check dictcheck in pam_pwquality.so
dictcheck_pam=$(grep -Psi '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?dictcheck\h*=\h*0\b' /etc/pam.d/common-password 2>/dev/null)

if [ -z "$dictcheck_conf" ] && [ -z "$dictcheck_pam" ]; then
    audit_result="PASS"
    a_output+=("- dictcheck is not set to 0 in /etc/security/pwquality.conf or /etc/security/pwquality.conf.d/*.conf")
    a_output+=("- dictcheck is not set to 0 in /etc/pam.d/common-password")
else
    audit_result="FAIL"
    [ -n "$dictcheck_conf" ] && a_output2+=("- dictcheck = 0 found in config: $dictcheck_conf")
    [ -n "$dictcheck_pam" ] && a_output2+=("- dictcheck = 0 found in /etc/pam.d/common-password: $dictcheck_pam")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"