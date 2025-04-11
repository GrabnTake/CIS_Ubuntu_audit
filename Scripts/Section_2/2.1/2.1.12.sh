#!/usr/bin/env bash
{
    # Function to check the installation status of rpcbind
    check_rpcbind_installed() {
        dpkg-query -s rpcbind &>/dev/null && echo "rpcbind is installed"
    }

    # Function to check if the rpcbind is enabled or active
    check_rpcbind_service_status() {
        enabled=$(systemctl is-enabled rpcbind.socket rpcbind.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active rpcbind.socket rpcbind.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- rpcbind is enabled")
        else
            l_output+=( "- rpcbind is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- rpcbind is active")
        else
            l_output+=( "- rpcbind is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if rpcbind is installed
    result=$(check_rpcbind_installed)

    # If rpcbind is installed, check the service status
    if [[ "$result" == "rpcbind is installed" ]]; then
        check_rpcbind_service_status
    fi

    # Check if rpcbind is installed
    if [[ "$result" == "rpcbind is installed" ]]; then
        l_output2+=("- $result")
    else
       l_output+=("- rpcbind is not installed")
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