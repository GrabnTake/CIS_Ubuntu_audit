#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if UFW is in use first
if ! {command -v ufw &>/dev/null && systemctl is-active --quiet ufw; } ; then
    audit_result="SKIP"
    a_output+=("- UFW is not in use, audit skipped")
else
    # Check if iptables-persistent is installed
    if dpkg-query -s iptables-persistent &>/dev/null; then
        audit_result="FAIL"
        a_output2+=("- iptables-persistent is installed while UFW is present")
    else
        audit_result="PASS"
        a_output+=("- iptables-persistent is not installed with UFW")
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