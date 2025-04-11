#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if sudo or sudo-ldap is installed
if ! { dpkg-query -s sudo &>/dev/null || dpkg-query -s sudo-ldap &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- Neither sudo nor sudo-ldap is installed, audit skipped")
else
    # Check for timestamp_timeout in sudoers files
    timeout=$(grep -roP "timestamp_timeout=\K[0-9]*" /etc/sudoers* 2>/dev/null | head -n 1)
    
    if [ -z "$timeout" ]; then
        # Check default timeout, extract number before "minutes"
        default_timeout=$(sudo -V 2>/dev/null | grep "Authentication timestamp timeout:" | grep -o "[0-9]\+" | head -n 1)
        if [ -n "$default_timeout" ] && [ "$default_timeout" -le 15 ]; then
            audit_result="PASS"
            a_output+=("- No timestamp_timeout set; default is $default_timeout minutes (15 or less)")
        else
            audit_result="FAIL"
            a_output2+=("- No timestamp_timeout set; default is ${default_timeout:-unset} minutes (exceeds 15)")
        fi
    elif [ "$timeout" -eq -1 ]; then
        audit_result="FAIL"
        a_output2+=("- timestamp_timeout is -1 (disabled, exceeds 15 minutes)")
    elif [ "$timeout" -le 15 ]; then
        audit_result="PASS"
        a_output+=("- timestamp_timeout is $timeout minutes (15 or less)")
    else
        audit_result="FAIL"
        a_output2+=("- timestamp_timeout is $timeout minutes (exceeds 15)")
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"