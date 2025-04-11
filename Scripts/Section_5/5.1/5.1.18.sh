#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if SSH server is in use
if ! { dpkg-query -s openssh-server &>/dev/null && systemctl is-active ssh &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- SSH server is not in use (not installed or not active), audit skipped")
else
    # Check MaxStartups
    maxstartups_line=$(sshd -T 2>/dev/null | grep -i "^maxstartups")
    maxstartups_check=$(echo "$maxstartups_line" | awk '$1 ~ /^\s*maxstartups/{split($2, a, ":"); if(a[1] > 10 || a[2] > 30 || a[3] > 60) print $0}')

    if [ -z "$maxstartups_check" ]; then
        audit_result="PASS"
        a_output+=("- MaxStartups is $maxstartups_line (10:30:60 or more restrictive)")
    else
        audit_result="FAIL"
        a_output2+=("- MaxStartups is less restrictive than 10:30:60: $maxstartups_line")
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"