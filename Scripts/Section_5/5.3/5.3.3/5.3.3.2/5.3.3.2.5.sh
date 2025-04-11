#!/usr/bin/env bash

a_output=()
a_output2=()

# Check maxsequence in pwquality config files
maxsequence_conf=$(grep -Psi '^\h*maxsequence\h*=\h*[1-3]\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null)
# Check for invalid maxsequence (0 or >3) in pam_pwquality.so
maxsequence_pam=$(grep -Psi '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?maxsequence\h*=\h*(0|[4-9]|[1-9][0-9]+)\b' /etc/pam.d/common-password 2>/dev/null)

if [ -n "$maxsequence_conf" ] && [ -z "$maxsequence_pam" ]; then
    audit_result="PASS"
    a_output+=("- maxsequence is set to 3 or less (not 0) in config: $maxsequence_conf")
    a_output+=("- No invalid maxsequence (0 or >3) found in /etc/pam.d/common-password")
    a_output+=("- Note: Verify maxsequence value meets local site policy")
else
    audit_result="FAIL"
    [ -z "$maxsequence_conf" ] && a_output2+=("- maxsequence is not set to 1-3 in /etc/security/pwquality.conf or /etc/security/pwquality.conf.d/*.conf")
    [ -n "$maxsequence_pam" ] && a_output2+=("- Invalid maxsequence (0 or >3) found in /etc/pam.d/common-password: $maxsequence_pam")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"