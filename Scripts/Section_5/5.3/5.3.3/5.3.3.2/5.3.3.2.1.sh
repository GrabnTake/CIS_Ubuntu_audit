#!/usr/bin/env bash

a_output=()
a_output2=()

# Check difok in pwquality config files
difok_conf=$(grep -Psi '^\h*difok\h*=\h*([2-9]|[1-9][0-9]+)\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null)
# Check for invalid difok (0-1) in pam_pwquality.so
difok_pam=$(grep -Psi '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?difok\h*=\h*([0-1])\b' /etc/pam.d/common-password 2>/dev/null)

if [ -n "$difok_conf" ] && [ -z "$difok_pam" ]; then
    audit_result="PASS"
    a_output+=("- difok is set to 2 or more in config: $difok_conf")
    a_output+=("- No invalid difok (0-1) found in /etc/pam.d/common-password")
    a_output+=("- Note: Verify difok value meets local site policy")
else
    audit_result="FAIL"
    [ -z "$difok_conf" ] && a_output2+=("- difok is not set to 2 or more in /etc/security/pwquality.conf or /etc/security/pwquality.conf.d/*.conf")
    [ -n "$difok_pam" ] && a_output2+=("- Invalid difok (0-1) found in /etc/pam.d/common-password: $difok_pam")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"