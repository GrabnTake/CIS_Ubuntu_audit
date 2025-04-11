#!/usr/bin/env bash
{
    # Function to check the installation status of squid
    check_squid_installed() {
        dpkg-query -s squid &>/dev/null && echo "squid is installed"
    }

    # Function to check if the squid is enabled or active
    check_squid_service_status() {
        enabled=$(systemctl is-enabled squid.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active squid.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- squid is enabled")
        else
            l_output+=( "- squid is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- squid is active")
        else
            l_output+=( "- squid is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if squid is installed
    result=$(check_squid_installed)

    # If squid is installed, check the service status
    if [[ "$result" == "squid is installed" ]]; then
        l_output2+=("- $result")
        check_squid_service_status
    else
       l_output+=("- squid is not installed")
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