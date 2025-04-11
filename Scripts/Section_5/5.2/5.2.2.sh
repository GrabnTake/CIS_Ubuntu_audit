#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if sudo or sudo-ldap is installed
if ! { dpkg-query -s sudo &>/dev/null || dpkg-query -s sudo-ldap &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- Neither sudo nor sudo-ldap is installed, audit skipped")
else
    # Check for Defaults use_pty
    use_pty=$(grep -rPi '^\h*Defaults\h+([^#\n\r]+,\h*)?use_pty\b' /etc/sudoers* 2>/dev/null)
    # Check for Defaults !use_pty
    no_use_pty=$(grep -rPi '^\h*Defaults\h+([^#\n\r]+,\h*)?!use_pty\b' /etc/sudoers* 2>/dev/null)

    if [ -n "$use_pty" ] && [ -z "$no_use_pty" ]; then
        audit_result="PASS"
        a_output+=("- Defaults use_pty is set: $use_pty")
        a_output+=("- Defaults !use_pty is not set")
    else
        audit_result="FAIL"
        [ -z "$use_pty" ] && a_output2+=("- Defaults use_pty is not set")
        [ -n "$no_use_pty" ] && a_output2+=("- Defaults !use_pty is set: $no_use_pty")
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"