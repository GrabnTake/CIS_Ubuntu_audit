#!/usr/bin/env bash

a_output=()
a_output2=()
a_parlist=("NTP=[^#\n\r]+" "FallbackNTP=[^#\n\r]+")
l_systemd_config_file="/etc/systemd/timesyncd.conf"
l_systemdanalyze="$(readlink -f /bin/systemd-analyze)"

# Check if systemd-timesyncd is in use and chrony is not
timesyncd_enabled=$(systemctl is-enabled systemd-timesyncd.service 2>/dev/null | grep -q 'enabled' && echo "yes" || echo "no")
timesyncd_active=$(systemctl is-active systemd-timesyncd.service 2>/dev/null | grep -q '^active' && echo "yes" || echo "no")
chrony_enabled=$(systemctl is-enabled chrony.service 2>/dev/null | grep -q 'enabled' && echo "yes" || echo "no")
chrony_active=$(systemctl is-active chrony.service 2>/dev/null | grep -q '^active' && echo "yes" || echo "no")

if [ "$timesyncd_enabled" = "no" ] && [ "$timesyncd_active" = "no" ]; then
    audit_result="Skipped"
    a_output+=("- systemd-timesyncd is not enabled or active (audit skipped)")
elif [ "$chrony_enabled" = "yes" ] || [ "$chrony_active" = "yes" ]; then
    audit_result="Skipped"
    a_output+=("- chrony is enabled or active (audit skipped; only one time sync method should be in use)")
else
    # Function to check config file parameters
    f_config_file_parameter_chk() {
        unset A_out
        declare -A A_out
        while read -r l_out; do
            if [ -n "$l_out" ]; then
                if [[ "$l_out" =~ ^\s*# ]]; then
                    l_file="${l_out//# /}"
                else
                    l_param_name=$(awk -F= '{print $1}' <<< "$l_out" | xargs)
                    if grep -Piq "^\h*$l_systemd_parameter_name\b" <<< "$l_param_name"; then
                        A_out["$l_param_name"]="$l_file"
                    fi
                fi
            fi
        done < <("$l_systemdanalyze" cat-config "$l_systemd_config_file" | grep -Pio '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

        if [ ${#A_out[@]} -gt 0 ]; then
            while IFS="=" read -r l_param_name l_param_value; do
                l_param_name="${l_param_name// /}"
                l_param_value="${l_param_value// /}"
                if grep -Piq "\b$l_systemd_parameter_value\b" <<< "$l_param_value"; then
                    a_output+=("- \"$l_param_name\" is correctly set to \"$l_param_value\" in \"${A_out[$l_param_name]}\"")
                else
                    a_output2+=("- \"$l_param_name\" is incorrectly set to \"$l_param_value\" in \"${A_out[$l_param_name]}\" (expected value matching: \"$l_systemd_parameter_value\")")
                fi
            done < <(grep -Pio "^\h*$l_systemd_parameter_name\h*=\h*\H+" "${A_out[@]}")
        else
            a_output2+=("- \"$l_systemd_parameter_name\" is not set in any included file (may be ignored by load procedure)")
        fi
    }

    # Check each parameter
    for param in "${a_parlist[@]}"; do
        l_systemd_parameter_name="${param%%=*}"
        l_systemd_parameter_value="${param#*=}"
        f_config_file_parameter_chk
    done
fi

# Set audit result if not skipped
if [ -z "$audit_result" ]; then
    audit_result="FAIL"
    if [ ${#a_output2[@]} -le 0 ]; then
        audit_result="PASS"
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
    if [ ${#a_output2[@]} -eq 0 ]; then
        echo "(none)"
    else
        printf '%s\n' "${a_output2[@]}"
    fi
fi