#!/usr/bin/env bash
{
    # Function to check the installation status of nfs-server
    check_nfs_server_installed() {
        dpkg-query -s nfs-kernel-server &>/dev/null && echo "nfs-kernel-server is installed"
    }

    # Function to check if the nfs-server.service is enabled or active
    check_nfs_server_service_status() {
        enabled=$(systemctl is-enabled nfs-server.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active nfs-server.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- nfs-server.service is enabled")
        else
            l_output+=( "- nfs-server.service is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- nfs-server.service is active")
        else
            l_output+=( "- nfs-server.service is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if nfs-server is installed
    result=$(check_nfs_server_installed)

    # If nfs-server is installed, check the service status
    if [[ "$result" == "nfs-server is installed" ]]; then
        check_nfs_server_service_status
    fi

    # Check if nfs-server is installed
    if [[ "$result" == "nfs-server is installed" ]]; then
        l_output2+=("- $result")
    else
       l_output+=("- nfs-server is not installed")
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
