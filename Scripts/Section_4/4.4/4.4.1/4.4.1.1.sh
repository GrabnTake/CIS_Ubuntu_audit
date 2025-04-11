#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if iptables is in use
if ! { command -v iptables &>/dev/null && iptables -L -n 2>/dev/null | grep -v "^Chain\|^$" | grep -q .; }; then
    audit_result="SKIP"
    a_output+=("- iptables is not in use (no rules exist or not installed), audit skipped")
else
    # Check if iptables and iptables-persistent are installed
    iptables_installed=false
    if dpkg-query -s iptables &>/dev/null; then
        iptables_installed=true
        a_output+=("- iptables is installed")
    else
        a_output2+=("- iptables is not installed")
    fi

    persistent_installed=false
    if dpkg-query -s iptables-persistent &>/dev/null; then
        persistent_installed=true
        a_output+=("- iptables-persistent is installed")
    else
        a_output2+=("- iptables-persistent is not installed")
    fi

    # Set result based on both checks
    if $iptables_installed && $persistent_installed; then
        audit_result="PASS"
    else
        audit_result="FAIL"
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