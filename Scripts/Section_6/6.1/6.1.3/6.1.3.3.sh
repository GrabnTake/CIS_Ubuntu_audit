#!/usr/bin/env bash

a_output=()
a_output2=()

l_systemd_config_file="systemd/journald.conf"
l_analyze_cmd=$(readlink -f /bin/systemd-analyze 2>/dev/null || echo "/bin/systemd-analyze")
a_parameters=("ForwardToSyslog=yes")

f_config_file_parameter_chk() {
    local l_used_parameter_setting=""
    while IFS= read -r l_file; do
        l_file=$(tr -d '# ' <<< "$l_file")
        l_used_parameter_setting=$(grep -PHs -- "^\h*$l_parameter_name\b" "$l_file" | tail -n 1)
        [ -n "$l_used_parameter_setting" ] && break
    done < <($l_analyze_cmd cat-config "$l_systemd_config_file" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b' || echo "")
    if [ -n "$l_used_parameter_setting" ]; then
        while IFS=: read -r l_file_name l_file_parameter; do
            while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
                if [ "$l_file_parameter_value" = "$l_parameter_value" ]; then
                    a_output+=("- Parameter \"$l_file_parameter_name\" correctly set to \"$l_file_parameter_value\" in \"$l_file_name\"")
                else
                    a_output2+=("- Parameter \"$l_file_parameter_name\" incorrectly set to \"$l_file_parameter_value\" in \"$l_file_name\" (should be \"$l_parameter_value\")")
                fi
            done <<< "$l_file_parameter"
        done <<< "$l_used_parameter_setting"
    else
        l_any_setting=$(grep -r "^\h*$l_parameter_name\b" /etc/systemd/journald.conf* 2>/dev/null | tail -n 1)
        if [ -n "$l_any_setting" ]; then
            while IFS=: read -r l_file_name l_file_parameter; do
                while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
                    a_output2+=("- Parameter \"$l_file_parameter_name\" incorrectly set to \"$l_file_parameter_value\" in \"$l_file_name\" (should be \"$l_parameter_value\")")
                done <<< "$l_file_parameter"
            done <<< "$l_any_setting"
        else
            a_output2+=("- Parameter \"$l_parameter_name\" is not set in any included file (should be \"$l_parameter_value\")")
            a_output2+=("- Note: Default is \"yes\" if rsyslog is present, but explicitly set for compliance")
        fi
    fi
}

# Check if rsyslog is installed
if dpkg-query -s rsyslog &>/dev/null || rpm -q rsyslog &>/dev/null; then
    # Check ForwardToSyslog=yes
    for l_input_parameter in "${a_parameters[@]}"; do
        while IFS="=" read -r l_parameter_name l_parameter_value; do
            l_parameter_name=${l_parameter_name// /}
            l_parameter_value=${l_parameter_value// /}
            f_config_file_parameter_chk
        done <<< "$l_input_parameter"
    done

    # Check service status
    journald_status=$(systemctl list-units --type service 2>/dev/null | grep -P -- '\bsystemd-journald.service\b')
    rsyslog_status=$(systemctl list-units --type service 2>/dev/null | grep -P -- '\brsyslog.service\b')

    if echo "$journald_status" | grep -q "loaded active running"; then
        a_output+=("- systemd-journald.service is loaded, active, and running")
    else
        a_output2+=("- systemd-journald.service is not loaded, active, and running (current status: $(systemctl is-active systemd-journald.service 2>/dev/null || echo 'unknown'))")
        a_output2+=("- Start it with: systemctl start systemd-journald.service")
    fi

    if echo "$rsyslog_status" | grep -q "loaded active running"; then
        a_output+=("- rsyslog.service is loaded, active, and running")
    else
        a_output2+=("- rsyslog.service is not loaded, active, and running (current status: $(systemctl is-active rsyslog.service 2>/dev/null || echo 'unknown'))")
        a_output2+=("- Start it with: systemctl start rsyslog.service")
    fi

    # Determine result
    if [ ${#a_output2[@]} -eq 0 ]; then
        audit_result="PASS"
    else
        audit_result="FAIL"
    fi
else
    # rsyslog not installed, skip audit
    audit_result="SKIP"
    a_output+=("- rsyslog is not installed")
    a_output+=("- This audit is skipped as rsyslog is not the chosen logging method")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
echo "--------------------------"
echo "Note: This audit applies only if rsyslog is the chosen method for client-side logging. Ignore if systemd-journald is used exclusively."