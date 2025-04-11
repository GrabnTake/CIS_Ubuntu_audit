#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if auditd is installed
if dpkg-query -s auditd &>/dev/null; then
    a_output+=("- auditd is installed")
else
    a_output2+=("- auditd is not installed")
    a_output2+=("- Install it with: apt install auditd")
fi

# Check if audispd-plugins is installed
if dpkg-query -s audispd-plugins &>/dev/null; then
    a_output+=("- audispd-plugins is installed")
else
    a_output2+=("- audispd-plugins is not installed")
    a_output2+=("- Install it with: apt install audispd-plugins")
fi

# Determine result
if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
else
    audit_result="FAIL"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
