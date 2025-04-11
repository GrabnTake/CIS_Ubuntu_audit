#!/usr/bin/env bash
{
    # Function to check the installation status of dnsmasq
    check_dnsmasq_installed() {
        dpkg-query -s dnsmasq &>/dev/null && echo "dnsmasq is installed"
    }

    # Function to check if the dnsmasq.service is enabled or active
    check_dnsmasq_service_status() {
        enabled=$(systemctl is-enabled dnsmasq.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active dnsmasq.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- dnsmasq.service is enabled")
        else
            l_output+=( "- dnsmasq.service is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- dnsmasq.service is active")
        else
            l_output+=( "- dnsmasq.service is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if dnsmasq is installed
    result=$(check_dnsmasq_installed)

    # If dnsmasq is installed, check the service status
    if [[ "$result" == "dnsmasq is installed" ]]; then
        check_dnsmasq_service_status
    fi

    # Check if dnsmasq is installed
    if [[ "$result" == "dnsmasq is installed" ]]; then
        l_output2+=("- $result")
    else
       l_output+=("- dnsmasq is not installed")
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
