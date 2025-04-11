#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if SSH server is in use
if ! { dpkg-query -s openssh-server &>/dev/null && systemctl is-active ssh &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- SSH server is not in use (not installed or not active), audit skipped")
else
    # Check for weak ciphers
    weak_ciphers=$(sshd -T 2>/dev/null | grep -Pi '^ciphers\h+\"?([^#\n\r]+,)?((3des|blowfish|cast128|aes(128|192|256))-cbc|arcfour(128|256)?|rijndael-cbc@lysator\.liu\.se|chacha20-poly1305@openssh\.com)\b')

    if [ -z "$weak_ciphers" ]; then
        audit_result="PASS"
        a_output+=("- No weak ciphers detected in SSH configuration")
    else
        audit_result="FAIL"
        a_output2+=("- Weak ciphers detected: $weak_ciphers")
        if echo "$weak_ciphers" | grep -q "chacha20-poly1305@openssh\.com"; then
            a_output2+=("- Note: chacha20-poly1305@openssh.com found; verify CVE-2023-48795 patch")
        fi
        a_output2+=("- Weak ciphers to avoid: 3des-cbc, aes128-cbc, aes192-cbc, aes256-cbc")
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"