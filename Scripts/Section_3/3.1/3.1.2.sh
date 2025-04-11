#!/usr/bin/env bash

a_output=()
a_output2=()

# Function to check module status
module_chk() {
    # Check if module is loadable
    l_loadable=$(modprobe -n -v "$l_mname" 2>/dev/null)
    if grep -Pq -- '^\h*install \/bin\/(true|false)' <<< "$l_loadable"; then
        a_output+=("- Module \"$l_mname\" is not loadable: \"$l_loadable\"")
    else
        a_output2+=("- Module \"$l_mname\" is loadable: \"$l_loadable\"")
    fi

    # Check if module is loaded
    if ! lsmod | grep "$l_mname" >/dev/null 2>&1; then
        a_output+=("- Module \"$l_mname\" is not loaded")
    else
        a_output2+=("- Module \"$l_mname\" is loaded")
    fi

    # Check if module is blacklisted
    if modprobe --showconfig | grep -Pq -- "^\h*blacklist\h+$l_mname\b"; then
        blacklist_file=$(grep -Pl -- "^\h*blacklist\h+$l_mname\b" /etc/modprobe.d/* 2>/dev/null)
        a_output+=("- Module \"$l_mname\" is blacklisted in: \"$blacklist_file\"")
    else
        a_output2+=("- Module \"$l_mname\" is not blacklisted")
    fi
}

# Check for wireless NICs and their modules
if [ -n "$(find /sys/class/net/*/ -type d -name wireless 2>/dev/null)" ]; then
    l_dname=$(for driverdir in $(find /sys/class/net/*/ -type d -name wireless | xargs -0 dirname); do
        basename "$(readlink -f "$driverdir"/device/driver/module)" 2>/dev/null
    done | sort -u)
    
    if [ -n "$l_dname" ]; then
        for l_mname in $l_dname; do
            module_chk
        done
    else
        a_output+=("- Wireless NICs detected, but no associated kernel modules identified")
    fi
else
    a_output+=("- System has no wireless NICs installed")
fi

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