#!/usr/bin/env bash

a_output=()
a_output2=()

l_systemd_config_file="systemd/journald.conf"
l_analyze_cmd=$(readlink -f /bin/systemd-analyze 2>/dev/null || echo "/bin/systemd-analyze")
a_parameters=("SystemMaxUse=^.+$" "SystemKeepFree=^.+$" "RuntimeMaxUse=^.+$" "RuntimeKeepFree=^.+$" "MaxFileSec=^.+$")

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
                if grep -Pq -- "$l_parameter_value" <<< "$l_file_parameter_value"; then
                    a_output+=("- Parameter \"$l_file_parameter_name\" set to \"$l_file_parameter_value\" in \"$l_file_name\"")
                fi
            done <<< "$l_file_parameter"
        done <<< "$l_used_parameter_setting"
    else
        a_output2+=("- Parameter \"$l_parameter_name\" is not set in any included file")
        a_output2+=("- Note: \"$l_parameter_name\" may be set in a file ignored by the load procedure")
    fi
}

for l_input_parameter in "${a_parameters[@]}"; do
    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name=${l_parameter_name// /}
        l_parameter_value=${l_parameter_value// /}
        f_config_file_parameter_chk
    done <<< "$l_input_parameter"
done

if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
    [ ${#a_output[@]} -eq 0 ] && a_output+=("- All required systemd-journald log rotation parameters are set")
else
    audit_result="FAIL"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
echo "--------------------------"
echo "Review Required: Ensure listed parameters align with site-specific log rotation policy (e.g., size, time limits)"