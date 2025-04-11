#!/usr/bin/env bash

a_output=()
a_output2=()
a_parlist=("net.ipv4.ip_forward=0" "net.ipv6.conf.all.forwarding=0")
l_ufwscf=$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)
l_systemdsysctl=$(readlink -f /lib/systemd/systemd-sysctl)

# Check if IPv6 is disabled
f_ipv6_chk() {
    l_ipv6_disabled="no"
    if ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable; then
        l_ipv6_disabled="yes"
    elif sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
         sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
        l_ipv6_disabled="yes"
    fi
}

# Check kernel parameter status
f_kernel_parameter_chk() {
    # Check running configuration
    l_running_parameter_value=$(sysctl "$l_parameter_name" 2>/dev/null | awk -F= '{print $2}' | xargs)
    if grep -Pq -- "\b$l_parameter_value\b" <<< "$l_running_parameter_value"; then
        a_output+=("- \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\" in the running configuration")
    else
        a_output2+=("- \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\" in the running configuration (should be: \"$l_parameter_value\")")
    fi

    # Check persistent configuration files
    unset A_out
    declare -A A_out
    while read -r l_out; do
        if [ -n "$l_out" ]; then
            if [[ $l_out =~ ^\s*# ]]; then
                l_file="${l_out//# /}"
            else
                l_kpar=$(awk -F= '{print $1}' <<< "$l_out" | xargs)
                [ "$l_kpar" = "$l_parameter_name" ] && A_out["$l_kpar"]="$l_file"
            fi
        fi
    done < <("$l_systemdsysctl" --cat-config 2>/dev/null | grep -Po '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

    # Check UFW sysctl file if defined
    if [ -n "$l_ufwscf" ]; then
        l_kpar=$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" 2>/dev/null | xargs)
        l_kpar="${l_kpar//\//.}"
        [ "$l_kpar" = "$l_parameter_name" ] && A_out["$l_kpar"]="$l_ufwscf"
    fi

    if [ ${#A_out[@]} -gt 0 ]; then
        while IFS="=" read -r l_fkpname l_file_parameter_value; do
            l_fkpname="${l_fkpname// /}"
            l_file_parameter_value="${l_file_parameter_value// /}"
            if grep -Pq -- "\b$l_parameter_value\b" <<< "$l_file_parameter_value"; then
                a_output+=("- \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\" in \"${A_out[$l_fkpname]}\"")
            else
                a_output2+=("- \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\" in \"${A_out[$l_fkpname]}\" (should be: \"$l_parameter_value\")")
            fi
        done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
    else
        a_output2+=("- \"$l_parameter_name\" is not set in any included file (may be ignored by load procedure)")
    fi
}

# Process each parameter
for param in "${a_parlist[@]}"; do
    l_parameter_name="${param%%=*}"
    l_parameter_value="${param#*=}"
    
    if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
        [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
        if [ "$l_ipv6_disabled" = "yes" ]; then
            a_output+=("- IPv6 is disabled on the system, \"$l_parameter_name\" is not applicable")
        else
            f_kernel_parameter_chk
        fi
    else
        f_kernel_parameter_chk
    fi
done

# Set audit result
audit_result="FAIL"
if [ ${#a_output2[@]} -le 0 ]; then
    audit_result="PASS"
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