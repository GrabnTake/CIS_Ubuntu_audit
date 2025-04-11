#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if SSH server is in use
if ! { dpkg-query -s openssh-server &>/dev/null && systemctl is-active ssh &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- SSH server is not in use (not installed or not active), audit skipped")
else
    # Check for weak MACs
    weak_macs=$(sshd -T 2>/dev/null | grep -Pi 'macs\h+([^#\n\r]+,)?(hmac-md5|hmac-md5-96|hmac-ripemd160|hmac-sha1-96|umac-64@openssh\.com|hmac-md5-etm@openssh\.com|hmac-md5-96-etm@openssh\.com|hmac-ripemd160-etm@openssh\.com|hmac-sha1-96-etm@openssh\.com|umac-64-etm@openssh\.com|umac-128-etm@openssh\.com)\b')

    if [ -z "$weak_macs" ]; then
        audit_result="PASS"
        a_output+=("- No weak MACs detected in SSH configuration")
    else
        audit_result="FAIL"
        a_output2+=("- Weak MACs detected: $weak_macs")
        a_output2+=("- Note: Review CVE-2023-48795 for ETM MACs and verify system is patched")
        a_output2+=("- Weak MACs to avoid: hmac-md5, hmac-md5-96, hmac-ripemd160, hmac-sha1-96, umac-64@openssh.com, hmac-md5-etm@openssh.com, hmac-md5-96-etm@openssh.com, hmac-ripemd160-etm@openssh.com, hmac-sha1-96-etm@openssh.com, umac-64-etm@openssh.com, umac-128-etm@openssh.com")
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"