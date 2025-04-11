#!/usr/bin/env bash

a_output=()
a_output2=()

# Check enforce_for_root in pwquality config files
enforce_root=$(grep -Psi '^\h*enforce_for_root\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null)

if [ -n "$enforce_root" ]; then
    audit_result="PASS"
    a_output+=("- enforce_for_root is enabled in config: $enforce_root")
else
    audit_result="FAIL"
    a_output2+=("- enforce_for_root is not enabled in /etc/security/pwquality.conf or /etc/security/pwquality.conf.d/*.conf")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"