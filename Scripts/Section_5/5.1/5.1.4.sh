#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if SSH server is in use
if ! { dpkg-query -s openssh-server &>/dev/null && systemctl is-active ssh &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- SSH server is not in use (not installed or not active), audit skipped")
else
    # Check sshd config for allow/deny directives
    sshd_output=$(sshd -T 2>/dev/null | grep -Pi '^\h*(allow|deny)(users|groups)\h+\H+')
    
    if [ -n "$sshd_output" ]; then
        audit_result="PASS"
        a_output+=("- SSH configuration includes allow/deny settings:")
        while IFS= read -r line; do
            a_output+=("  $line")
        done <<< "$sshd_output"
        a_output+=("- Note: Verify listed users/groups match local site policy separately")
    else
        audit_result="FAIL"
        a_output2+=("- No allowusers, allowgroups, denyusers, or denygroups settings found")
    fi
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
if [ ${#a_output[@]} -eq 0 ]; then
    echo "(none)"
else
    printf '%s\n' "${a_output[@]}"
fi

if [ "$audit_result" == "FAIL" ]; then
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${a_output2[@]}"
fi