#!/usr/bin/env bash

# Initialize variables
audit_result="PASS"
a_output=()
a_output2=()

# Check maxrepeat setting in pwquality.conf files
mapfile -t pwquality_output < <(grep -Psi -- '^\h*maxrepeat\h*=\h*[1-3]\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null)

# Check if maxrepeat is incorrectly set in /etc/pam.d/common-password
mapfile -t pam_override_output < <(grep -Psi -- '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?maxrepeat\h*=\h*(0|[4-9]|[1-9][0-9]+)\b' /etc/pam.d/common-password 2>/dev/null)

# Process outputs
if [[ ${#pwquality_output[@]} -gt 0 ]]; then
    a_output+=("${pwquality_output[@]}")
else
    audit_result="FAIL"
    a_output2+=("- maxrepeat setting not found or incorrectly configured in /etc/security/pwquality.conf or /etc/security/pwquality.conf.d/.")
fi

if [[ ${#pam_override_output[@]} -gt 0 ]]; then
    audit_result="FAIL"
    a_output2+=("- maxrepeat setting may be overridden in /etc/pam.d/common-password.")
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
