#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if rsyslog is installed
if dpkg-query -s rsyslog &>/dev/null || rpm -q rsyslog &>/dev/null; then
    # Check if rsyslog.service is enabled
    enabled_status=$(systemctl is-enabled rsyslog.service 2>/dev/null)
    if [ "$enabled_status" = "enabled" ]; then
        a_output+=("- rsyslog.service is enabled")
    else
        a_output2+=("- rsyslog.service is not enabled (current status: $enabled_status)")
        a_output2+=("- Enable it with: systemctl enable rsyslog.service")
    fi

    # Check if rsyslog.service is active
    active_status=$(systemctl is-active rsyslog.service 2>/dev/null)
    if [ "$active_status" = "active" ]; then
        a_output+=("- rsyslog.service is active")
    else
        a_output2+=("- rsyslog.service is not active (current status: $active_status)")
        a_output2+=("- Start it with: systemctl start rsyslog.service")
    fi

    # Determine result
    if [ ${#a_output2[@]} -eq 0 ]; then
        audit_result="PASS"
    else
        audit_result="FAIL"
    fi
else
    # rsyslog not installed, check journald
    if dpkg -l systemd &>/dev/null || rpm -q systemd &>/dev/null; then
        a_output+=("- rsyslog is not installed")
        a_output+=("- This audit is skipped as rsyslog is not the chosen logging method (journald likely in use)")
        audit_result="SKIP"
    else
        a_output2+=("- rsyslog is not installed")
        a_output2+=("- Install and enable rsyslog with: apt install rsyslog && systemctl enable rsyslog.service")
        audit_result="FAIL"
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
echo "--------------------------"
echo "Note: This audit applies only if rsyslog is the chosen method for client-side logging. Ignore if journald is used."