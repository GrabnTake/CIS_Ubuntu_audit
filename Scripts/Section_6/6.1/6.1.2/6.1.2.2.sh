#!/usr/bin/env bash

a_output=()
a_output2=()

l_systemd_config_file="systemd/journald.conf"
l_analyze_cmd=$(readlink -f /bin/systemd-analyze 2>/dev/null || echo "/bin/systemd-analyze")
a_parameters=("ForwardToSyslog=no")

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
        # Check if explicitly set to something else or not set
        l_any_setting=$(grep -r "^\h*$l_parameter_name\b" /etc/systemd/journald.conf* 2>/dev/null | tail -n 1)
        if [ -n "$l_any_setting" ]; then
            while IFS=: read -r l_file_name l_file_parameter; do
                while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
                    a_output2+=("- Parameter \"$l_file_parameter_name\" incorrectly set to \"$l_file_parameter_value\" in \"$l_file_name\" (should be \"$l_parameter_value\")")
                done <<< "$l_file_parameter"
            done <<< "$l_any_setting"
        else
            a_output2+=("- Parameter \"$l_parameter_name\" is not set in any included file (should be \"$l_parameter_value\")")
            a_output2+=("- Note: Default behavior may apply if not explicitly set; configure explicitly to \"no\"")
        fi
    fi
}

# Check if systemd (including journald) is installed
if dpkg -l systemd &>/dev/null || rpm -q systemd &>/dev/null; then
    for l_input_parameter in "${a_parameters[@]}"; do
        while IFS="=" read -r l_parameter_name l_parameter_value; do
            l_parameter_name=${l_parameter_name// /}
            l_parameter_value=${l_parameter_value// /}
            f_config_file_parameter_chk
        done <<< "$l_input_parameter"
    done

    # Determine result
    if [ ${#a_output2[@]} -eq 0 ]; then
        audit_result="PASS"
    else
        audit_result="FAIL"
    fi
else
    audit_result="SKIP"
    a_output+=("- systemd-journald is not installed")
    a_output+=("- This audit is skipped as journald is not the chosen logging method")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
echo "--------------------------"
echo "Note: This audit applies only if journald is the chosen method for client-side logging. Ignore if rsyslog is used."