#!/usr/bin/env bash

a_output=()
a_output2=()
l_mod_name="tipc"
l_mod_type="net"
l_mod_path=$(readlink -f /lib/modules/**/kernel/$l_mod_type 2>/dev/null | sort -u)

# Function to check module status
f_module_chk() {
    # Check if module is loaded (running kernel)
    if ! lsmod | grep "$l_mod_chk_name" &>/dev/null; then
        a_output+=("- Kernel module \"$l_mod_name\" is not loaded")
    else
        a_output2+=("- Kernel module \"$l_mod_name\" is loaded")
    fi

    # Check modprobe --showconfig for install and blacklist (system-wide)
    a_showconfig=($(modprobe --showconfig 2>/dev/null | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b'))
    
    if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
        a_output+=("- Kernel module \"$l_mod_name\" is not loadable")
    else
        a_output2+=("- Kernel module \"$l_mod_name\" is loadable")
    fi

    if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
        a_output+=("- Kernel module \"$l_mod_name\" is blacklisted")
    else
        a_output2+=("- Kernel module \"$l_mod_name\" is not blacklisted")
    fi
}

# Check for tipc module availability across all kernels
module_found="no"
for l_mod_base_directory in $l_mod_path; do
    if [ -d "$l_mod_base_directory/${l_mod_name/-/\/}" ] && [ -n "$(ls -A "$l_mod_base_directory/${l_mod_name/-/\/}" 2>/dev/null)" ]; then
        module_found="yes"
        # Don’t run f_module_chk here yet, just mark as found
    fi
done

# If module exists in any kernel, check its status once
if [ "$module_found" = "yes" ]; then
    l_mod_chk_name="$l_mod_name"
    f_module_chk
else
    a_output+=("- Kernel module \"$l_mod_name\" is not available in any installed kernel")
fi

# Set audit result
audit_result="FAIL"
if [ "$module_found" = "no" ] || [ ${#a_output2[@]} -le 0 ]; then
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