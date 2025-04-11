#!/usr/bin/env bash

a_output=()
a_output2=()

# Check enforcing in pwquality config files
enforcing_conf=$(grep -PHsi '^\h*enforcing\h*=\h*0\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null)
# Check enforcing in pam_pwquality.so
enforcing_pam=$(grep -PHsi '^\h*password\h+[^#\n\r]+\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?enforcing=0\b' /etc/pam.d/common-password 2>/dev/null)

if [ -z "$enforcing_conf" ] && [ -z "$enforcing_pam" ]; then
    audit_result="PASS"
    a_output+=("- enforcing is not set to 0 in /etc/security/pwquality.conf or /etc/security/pwquality.conf.d/*.conf")
    a_output+=("- enforcing=0 is not set in /etc/pam.d/common-password")
else
    audit_result="FAIL"
    [ -n "$enforcing_conf" ] && a_output2+=("- enforcing = 0 found in config: $enforcing_conf")
    [ -n "$enforcing_pam" ] && a_output2+=("- enforcing=0 found in /etc/pam.d/common-password: $enforcing_pam")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"