#!/usr/bin/env bash
{
    # Function to check the installation status of bind9
    check_bind9_installed() {
        dpkg-query -s bind9 &>/dev/null && echo "bind9 is installed" 
    }

    # Function to check if the named.service is enabled or active
    check_named_service_status() {
        enabled=$(systemctl is-enabled named.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active named.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- named.service is enabled")
        else
            l_output+=( "- named.service is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- named.service is active")
        else
            l_output+=( "- named.service is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if bind9 is installed
    result=$(check_bind9_installed)

    # If bind9 is installed, check the service status
    if [[ "$result" == "bind9 is installed" ]]; then
        check_named_service_status
    fi

    # Check if bind9 is installed
    if [[ "$result" == "bind9 is installed" ]]; then
        l_output2+=("- $result")
    else
       l_output+=("- bind9 is not installed")
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
