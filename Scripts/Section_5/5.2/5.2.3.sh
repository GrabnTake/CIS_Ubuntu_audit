#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if sudo or sudo-ldap is installed
if ! { dpkg-query -s sudo &>/dev/null || dpkg-query -s sudo-ldap &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- Neither sudo nor sudo-ldap is installed, audit skipped")
else
    # Check for custom sudo log file
    logfile=$(grep -rPsi "^\h*Defaults\h+([^#]+,\h*)?logfile\h*=\h*(\"|\')?\H+(\"|\')?(,\h*\H+\h*)*\h*(#.*)?$" /etc/sudoers* 2>/dev/null)

    if [ -n "$logfile" ]; then
        audit_result="PASS"
        a_output+=("- Sudo custom log file is configured: $logfile")
    else
        audit_result="FAIL"
        a_output2+=("- No custom sudo log file (e.g., logfile=\"/var/log/sudo.log\") is configured")
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"