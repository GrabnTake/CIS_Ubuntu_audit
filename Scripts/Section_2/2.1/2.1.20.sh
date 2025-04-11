#!/usr/bin/env bash
{
    # Function to check the installation status of xserver-common
    check_xserver_common_installed() {
        dpkg-query -s xserver-common &>/dev/null && echo "xserver-common is installed"
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if xserver-common is installed
    result=$(check_xserver_common_installed)

    # If xserver-common is installed, check the service status
    if [[ "$result" == "xserver-common is installed" ]]; then
        l_output2+=("- $result")
    else
       l_output+=("- xserver-common is not installed")
    fi

 # Report results in plain text format
    if [ ${#l_output2[@]} -le 0 ]; then
        echo "====== Audit Report ======"
        echo "Audit Result: PASS"
        echo "--------------------------"
        echo "Correct Settings:"
        printf '%s\n' "${l_output[@]}"
    else
        echo "====== Audit Report ======"
        echo "Audit Result: FAIL"
        echo "--------------------------"
        echo "Correct Settings:"
        printf '%s\n' "${l_output[@]}"
        echo "--------------------------"
        echo "Reason(s) for Failure:"
        printf '%s\n' "${l_output2[@]}"
    fi

}