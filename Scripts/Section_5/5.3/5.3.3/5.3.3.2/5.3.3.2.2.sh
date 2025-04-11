#!/usr/bin/env bash

a_output=()
a_output2=()

# Check minlen in pwquality config files
minlen_conf=$(grep -Psi '^\h*minlen\h*=\h*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,})\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null)
# Check for invalid minlen (0-13) in pam_pwquality.so
minlen_pam=$(grep -Psi '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?minlen\h*=\h*([0-9]|1[0-3])\b' /etc/pam.d/system-auth /etc/pam.d/common-password 2>/dev/null)

if [ -n "$minlen_conf" ] && [ -z "$minlen_pam" ]; then
    audit_result="PASS"
    a_output+=("- minlen is set to 14 or more in config: $minlen_conf")
    a_output+=("- No invalid minlen (0-13) found in /etc/pam.d/system-auth or /etc/pam.d/common-password")
    a_output+=("- Note: Verify minlen value meets local site policy")
else
    audit_result="FAIL"
    [ -z "$minlen_conf" ] && a_output2+=("- minlen is not set to 14 or more in /etc/security/pwquality.conf or /etc/security/pwquality.conf.d/*.conf")
    [ -n "$minlen_pam" ] && a_output2+=("- Invalid minlen (0-13) found in PAM config: $minlen_pam")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"