#!/usr/bin/env bash

a_output=()
a_output2=()

# Minimum acceptable value in MB (default 5 is too small per section warning)
min_size=6

# Check for max_log_file setting
l_max_log_file=$(grep -Po -- '^\h*max_log_file\h*=\h*\d+\b' /etc/audit/auditd.conf 2>/dev/null)
if [ -n "$l_max_log_file" ]; then
    l_value=$(echo "$l_max_log_file" | grep -Po '\d+\b')
    if [ "$l_value" -ge "$min_size" ]; then
        a_output+=("- max_log_file is set to $l_value MB (meets or exceeds minimum of $min_size MB)")
    else
        a_output2+=("- max_log_file is set to $l_value MB (below minimum of $min_size MB)")
        a_output2+=("- Update /etc/audit/auditd.conf to set max_log_file >= $min_size")
    fi
else
    a_output2+=("- max_log_file is not set in /etc/audit/auditd.conf (default is 5 MB, below minimum of $min_size MB)")
    a_output2+=("- Update /etc/audit/auditd.conf to set max_log_file >= $min_size")
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