#!/usr/bin/env bash
{
    # Function to check the installation status of xinetd
    check_xinetd_installed() {
        dpkg-query -s xinetd &>/dev/null && echo "xinetd is installed"
    }

    # Function to check if the xinetd is enabled or active
    check_xinetd_service_status() {
        enabled=$(systemctl is-enabled xinetd.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active xinetd.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- xinetd is enabled")
        else
            l_output+=( "- xinetd is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- xinetd is active")
        else
            l_output+=( "- xinetd is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if xinetd is installed
    result=$(check_xinetd_installed)

    # If xinetd is installed, check the service status
    if [[ "$result" == "xinetd is installed" ]]; then
        l_output2+=("- $result")
        check_xinetd_service_status
    else
       l_output+=("- xinetd is not installed")
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