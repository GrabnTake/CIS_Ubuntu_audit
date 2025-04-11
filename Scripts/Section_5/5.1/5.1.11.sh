#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if SSH server is in use
if ! { dpkg-query -s openssh-server &>/dev/null && systemctl is-active ssh &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- SSH server is not in use (not installed or not active), audit skipped")
else
    # Check ignorerhosts setting
    gssapi=$(sshd -T 2>/dev/null | grep -i "ignorerhosts")

    if echo "$gssapi" | grep -qi "ignorerhosts yes"; then
        audit_result="PASS"
        a_output+=("- ignorerhosts is set to yes")
    else
        audit_result="FAIL"
        a_output2+=("- ignorerhosts is not set to yes (found: ${gssapi:-unset})")
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"