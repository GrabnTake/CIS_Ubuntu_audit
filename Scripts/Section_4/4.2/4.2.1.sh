#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if ufw is in use
if ! { command -v ufw &>/dev/null && systemctl is-active --quiet ufw; } ; then
    if dpkg-query -s ufw &>/dev/null; then
        audit_result="PASS"
        a_output+=("- Uncomplicated Firewall (UFW) is installed")
    else
        audit_result="FAIL"
        a_output2+=("- Uncomplicated Firewall (UFW) is active but not installed (unexpected state)")
    fi
else
    audit_result="SKIP"
    a_output+=("- Uncomplicated Firewall (UFW) is not in use (not active or not installed), audit skipped")
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