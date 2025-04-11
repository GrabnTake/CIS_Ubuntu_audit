#!/usr/bin/env bash

a_output=()
a_output2=()

# Check credits and minclass in pwquality config files
pwquality_settings=$(grep -Psi '^\h*(minclass|[dulo]credit)\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null)
# Check for overrides in pam_pwquality.so
pam_overrides=$(grep -Psi '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?(minclass=\d*|[dulo]credit=-?\d*)\b' /etc/pam.d/common-password 2>/dev/null)

# Check if credits are ≤ 0
credits_ok=true
if [ -n "$pwquality_settings" ]; then
    while IFS= read -r line; do
        if echo "$line" | grep -Pi '^\h*[dulo]credit\h*=\h*[1-9]' >/dev/null; then
            credits_ok=false
            a_output2+=("- Credit value > 0 found: $line")
        fi
    done <<< "$pwquality_settings"
fi

if [ -n "$pwquality_settings" ] && [ "$credits_ok" = true ] && [ -z "$pam_overrides" ]; then
    audit_result="PASS"
    a_output+=("- Password complexity settings: $pwquality_settings")
    a_output+=("- All dcredit, ucredit, lcredit, ocredit are ≤ 0")
    a_output+=("- No overrides found in /etc/pam.d/common-password")
    a_output+=("- Note: Verify complexity conforms to local site policy")
else
    audit_result="FAIL"
    [ -z "$pwquality_settings" ] && a_output2+=("- No minclass or [dulo]credit settings found in /etc/security/pwquality.conf or /etc/security/pwquality.conf.d/*.conf")
    [ "$credits_ok" = false ] && : # Failure reason already added in loop
    [ -n "$pam_overrides" ] && a_output2+=("- Overrides found in /etc/pam.d/common-password: $pam_overrides")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"