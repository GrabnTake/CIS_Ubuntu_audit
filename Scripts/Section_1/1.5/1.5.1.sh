#!/usr/bin/env bash

# Define variables
a_output=()
a_output2=()
a_parlist=("kernel.randomize_va_space=2")

l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"
l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

# Function to check kernel parameters
f_kernel_parameter_chk() {
    local l_parameter_name="$1"
    local l_parameter_value="$2"

    # Get the running configuration
    l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

    # Check if the parameter is correctly set
    if [[ "$l_running_parameter_value" == "$l_parameter_value" ]]; then
        a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\" in the running configuration")
    else
        a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\" in the running configuration and should have a value of: \"$l_parameter_value\"")
    fi

    unset A_out
    declare -A A_out

    # Check durable setting in configuration files
    while read -r l_out; do
        if [[ -n "$l_out" ]]; then
            if [[ "$l_out" =~ ^\s*# ]]; then
                l_file="${l_out//# /}"
            else
                l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                [[ "$l_kpar" == "$l_parameter_name" ]] && A_out["$l_kpar"]="$l_file"
            fi
        fi
    done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

    # Account for UFW configurations
    if [[ -n "$l_ufwscf" ]]; then
        l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
        l_kpar="${l_kpar//\//.}"
        [[ "$l_kpar" == "$l_parameter_name" ]] && A_out["$l_kpar"]="$l_ufwscf"
    fi

    # Assess file-based configurations
    if (( ${#A_out[@]} > 0 )); then
        while IFS="=" read -r l_fkpname l_file_parameter_value; do
            l_fkpname="${l_fkpname// /}"
            l_file_parameter_value="${l_file_parameter_value// /}"

            if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"")
            else
                a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value of: \"$l_parameter_value\"")
            fi
        done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
    else
        a_output2+=(" - \"$l_parameter_name\" is not set in an included file")
    fi
}

# Loop through kernel parameters to check them
for param in "${a_parlist[@]}"; do
    IFS="=" read -r param_name param_value <<< "$param"
    f_kernel_parameter_chk "$param_name" "$param_value"
done


# Report results in plain text format
if [ ${#a_output2[@]} -eq 0 ]; then
    echo "====== Audit Report ======"
    echo "Audit Result: PASS"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${a_output[@]}"
else
    echo "====== Audit Report ======"
    echo "Audit Result: FAIL"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${a_output[@]}"
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${a_output2[@]}"
fi



