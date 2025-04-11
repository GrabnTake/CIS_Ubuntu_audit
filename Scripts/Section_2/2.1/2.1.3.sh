#!/usr/bin/env bash
{
    # Function to check the installation status of isc-dhcp-server
    check_isc_dhcp_installed() {
        dpkg-query -s isc-dhcp-server &>/dev/null && echo "isc-dhcp-server is installed" 
    }

    # Function to check if the isc-dhcp-server.socket and isc-dhcp-server.service are enabled or active
    check_isc_dhcp_service_status() {
        enabled=$(systemctl is-enabled isc-dhcp-server.service isc-dhcp-server6.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active isc-dhcp-server.service isc-dhcp-server6.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- isc-dhcp-server.socket or isc-dhcp-server.service is enabled")
        else
            l_output+=( "- isc-dhcp-server.socket or isc-dhcp-server.service is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- isc-dhcp-server.socket or isc-dhcp-server.service is active")
        else
            l_output+=( "- isc-dhcp-server.socket or isc-dhcp-server.service is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if isc-dhcp-server is installed
    result=$(check_isc_dhcp_installed)

    # If isc-dhcp-server is installed, check the service status
    if [[ "$result" == "isc-dhcp-server is installed" ]]; then
        check_isc_dhcp_service_status
    fi

    # Check if isc-dhcp-server is installed
    if [[ "$result" == "isc-dhcp-server is installed" ]]; then
        l_output2+=("- $result")
    else
       l_output+=("- isc-dhcp-server is not installed")
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

