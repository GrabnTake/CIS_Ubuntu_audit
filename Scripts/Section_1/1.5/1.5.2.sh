#!/usr/bin/env bash

# Initialize arrays for output
a_output=()
a_output2=()

# List of parameters to check
a_parlist=("kernel.yama.ptrace_scope")

# Get UFW configuration file, if exists
l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"

# Function to check kernel parameter
f_kernel_parameter_chk() {
    # Get the running parameter value using sysctl
    l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"
    
    # Check if the running configuration matches the required values
    if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
        a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\" in the running configuration")
    else
        a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\" in the running configuration and should have a value of: \"$l_value_out\"")
    fi

    unset A_out
    declare -A A_out

    # Check durable setting in files
    while read -r l_out; do
        if [ -n "$l_out" ]; then
            if [[ $l_out =~ ^\s*# ]]; then
                l_file="${l_out//# /}"
            else
                l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_file")
            fi
        fi
    done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

    # If UFW configuration is found, check for the parameter in UFW file
    if [ -n "$l_ufwscf" ]; then
        l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
        l_kpar="${l_kpar//\//.}"
        [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
    fi

    # Assess output from configuration files
    if (( ${#A_out[@]} > 0 )); then
        while IFS="=" read -r l_fkpname l_file_parameter_value; do
            l_fkpname="${l_fkpname// /}"
            l_file_parameter_value="${l_file_parameter_value// /}"

            if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"")
            else
                a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value of: \"$l_value_out\"")
            fi
        done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
    else
        a_output2+=(" - \"$l_parameter_name\" is not set in an included file")
        a_output2+=(" ** Note: \"$l_parameter_name\" may be set in a file that's ignored by the load procedure **")
    fi
}

# Path to systemd-sysctl
l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

# Loop through parameters and check them
while IFS="=" read -r l_parameter_name l_parameter_value; do
    l_parameter_name="${l_parameter_name// /}"
    l_parameter_value="${l_parameter_value// /}"
    l_value_out="${l_parameter_value//-/ through }"
    l_value_out="${l_value_out//|/ or }"
    l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

    # Call function to check the parameter
    f_kernel_parameter_chk
done < <(printf '%s\n' "${a_parlist[@]}")


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
