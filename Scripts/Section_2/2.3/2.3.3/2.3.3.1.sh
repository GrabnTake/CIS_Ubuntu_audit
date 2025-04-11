#!/usr/bin/env bash

a_output=()
a_output2=()
a_config_files=("/etc/chrony/chrony.conf")
l_include='(confdir|sourcedir)'
l_parameter_name='(server|pool)'
l_parameter_value='.+'  # Matches any non-empty value

# Check if chrony is in use and systemd-timesyncd is not
chrony_enabled=$(systemctl is-enabled chrony.service 2>/dev/null | grep -q 'enabled' && echo "yes" || echo "no")
chrony_active=$(systemctl is-active chrony.service 2>/dev/null | grep -q '^active' && echo "yes" || echo "no")
timesyncd_enabled=$(systemctl is-enabled systemd-timesyncd.service 2>/dev/null | grep -q 'enabled' && echo "yes" || echo "no")
timesyncd_active=$(systemctl is-active systemd-timesyncd.service 2>/dev/null | grep -q '^active' && echo "yes" || echo "no")

# Skip if chrony not in use or timesyncd is in use
if [ "$chrony_enabled" = "no" ] && [ "$chrony_active" = "no" ]; then
    audit_result="Skipped"
    a_output+=("- chrony is not enabled or active (audit skipped)")
elif [ "$timesyncd_enabled" = "yes" ] || [ "$timesyncd_active" = "yes" ]; then
    audit_result="Skipped"
    a_output+=("- systemd-timesyncd is enabled or active (audit skipped; only one time sync method should be in use)")
else
    # Populate config files array with includes
    while IFS= read -r l_conf_loc; do
        l_dir=""
        l_ext=""
        if [ -d "$l_conf_loc" ]; then
            l_dir="$l_conf_loc"
            l_ext="*"
        elif grep -Psq '\/\*\.([^#/\n\r]+)?\h*$' <<< "$l_conf_loc" || [ -f "$(readlink -f "$l_conf_loc")" ]; then
            l_dir="$(dirname "$l_conf_loc")"
            l_ext="$(basename "$l_conf_loc")"
        fi
        if [[ -n "$l_dir" && -n "$l_ext" ]]; then
            while IFS= read -r -d $'\0' l_file_name; do
                [ -f "$(readlink -f "$l_file_name")" ] && a_config_files+=("$(readlink -f "$l_file_name")")
            done < <(find -L "$l_dir" -type f -name "$l_ext" -print0 2>/dev/null)
        fi
    done < <(awk '$1~/^\s*'"$l_include"'$/{print $2}' "${a_config_files[@]}" 2>/dev/null)

    # Check for server or pool in config files
    for l_file in "${a_config_files[@]}"; do
        l_parameter_line=$(grep -Psi "^\h*$l_parameter_name(\h+|\h*:\h*)$l_parameter_value\b" "$l_file")
        if [ -n "$l_parameter_line" ]; then
            a_output+=("- Parameter: \"$(tr -d '()' <<< ${l_parameter_name//|/ or })\" exists in \"$l_file\" as: \"$l_parameter_line\"")
        fi
    done

    # If no server/pool found, fail
    if [ ${#a_output[@]} -le 0 ]; then
        a_output2+=("- Parameter: \"$(tr -d '()' <<< ${l_parameter_name//|/ or })\" does not exist in chrony configuration")
    fi
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