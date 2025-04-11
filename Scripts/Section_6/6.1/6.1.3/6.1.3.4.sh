#!/usr/bin/env bash

a_output=()
a_output2=()

l_analyze_cmd=$(readlink -f /bin/systemd-analyze 2>/dev/null || echo "/bin/systemd-analyze")
l_include='$IncludeConfig'
a_config_files=("rsyslog.conf")
l_parameter_name='$FileCreateMode'

f_parameter_chk() {
    l_perm_mask="0137"  # Masks write/execute for group/others
    l_maxperm=$(printf '%o' $((0777 & ~$l_perm_mask)))  # 0640
    l_file_mode=$(awk '{print $2}' <<< "$l_used_parameter_setting" | xargs)
    # Convert to decimal for comparison
    l_mode_dec=$((8#$l_file_mode))
    l_maxperm_dec=$((8#$l_maxperm))
    if [ $((l_mode_dec & l_perm_mask)) -gt 0 ] || [ $l_mode_dec -gt $l_maxperm_dec ]; then
        a_output2+=("- Parameter \"${l_parameter_name//\\/}\" is incorrectly set to mode \"$l_file_mode\" in \"$l_file\" (should be \"$l_maxperm\" or more restrictive)")
    else
        a_output+=("- Parameter \"${l_parameter_name//\\/}\" is correctly set to mode \"$l_file_mode\" in \"$l_file\" (meets \"$l_maxperm\" or more restrictive)")
    fi
}

# Check if rsyslog is installed
if dpkg-query -s rsyslog &>/dev/null || rpm -q rsyslog &>/dev/null; then
    # Find included config files
    while IFS= read -r l_file; do
        l_conf_loc=$(awk '$1~/^\s*'"$l_include"'$/ {print $2}' "$(tr -d '# ' <<< "$l_file")" | tail -n 1)
        [ -n "$l_conf_loc" ] && break
    done < <($l_analyze_cmd cat-config "${a_config_files[*]}" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b' || echo "")

    if [ -d "$l_conf_loc" ]; then
        l_dir="$l_conf_loc"
        l_ext="*"
    elif grep -Psq '\/\*\.([^#/\n\r]+)?\h*$' <<< "$l_conf_loc" || [ -f "$(readlink -f "$l_conf_loc")" ]; then
        l_dir=$(dirname "$l_conf_loc")
        l_ext=$(basename "$l_conf_loc")
    fi

    while read -r -d $'\0' l_file_name; do
        [ -f "$(readlink -f "$l_file_name")" ] && a_config_files+=("$(readlink -f "$l_file_name")")
    done < <(find -L "$l_dir" -type f -name "$l_ext" -print0 2>/dev/null)

    # Check for parameter
    while IFS= read -r l_file; do
        l_file=$(tr -d '# ' <<< "$l_file")
        l_used_parameter_setting=$(grep -PHs -- "^\h*$l_parameter_name\b" "$l_file" | tail -n 1)
        [ -n "$l_used_parameter_setting" ] && break
    done < <($l_analyze_cmd cat-config "${a_config_files[@]}" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b' || echo "")

    if [ -n "$l_used_parameter_setting" ]; then
        f_parameter_chk
    else
        a_output2+=("- Parameter \"${l_parameter_name//\\/}\" is not set in any configuration file (should be \"0640\" or more restrictive)")
        a_output2+=("- Note: Default is typically \"0640\", but explicitly set for compliance")
    fi

    # Determine result
    if [ ${#a_output2[@]} -eq 0 ]; then
        audit_result="PASS"
    else
        audit_result="FAIL"
    fi
else
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
echo "Note: This audit applies only if rsyslog is the chosen method for client-side logging. Ignore if journald is used."