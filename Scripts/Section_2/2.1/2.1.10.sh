#!/usr/bin/env bash
{
    # Function to check the installation status of ypserv
    check_ypserv_installed() {
        dpkg-query -s ypserv &>/dev/null && echo "ypserv is installed"
    }

    # Function to check if the ypserv.service is enabled or active
    check_ypserv_service_status() {
        enabled=$(systemctl is-enabled ypserv.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active ypserv.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- ypserv.service is enabled")
        else
            l_output+=( "- ypserv.service is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- ypserv.service is active")
        else
            l_output+=( "- ypserv.service is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if ypserv is installed
    result=$(check_ypserv_installed)

    # If ypserv is installed, check the service status
    if [[ "$result" == "ypserv is installed" ]]; then
        check_ypserv_service_status
    fi

    # Check if ypserv is installed
    if [[ "$result" == "ypserv is installed" ]]; then
        l_output2+=("- $result")
    else
       l_output+=("- ypserv is not installed")
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
