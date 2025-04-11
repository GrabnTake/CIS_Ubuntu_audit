#!/usr/bin/env bash
{
    # Function to check the installation status of rsync
    check_rsync_installed() {
        dpkg-query -s samba &>/dev/null && echo "samba is installed"
    }

    # Function to check if the rsync is enabled or active
    check_rsync_service_status() {
        enabled=$(systemctl is-enabled smbd.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active smbd.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- rsync is enabled")
        else
            l_output+=( "- rsync is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- rsync is active")
        else
            l_output+=( "- rsync is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if rsync is installed
    result=$(check_rsync_installed)

    # If rsync is installed, check the service status
    if [[ "$result" == "rsync is installed" ]]; then
        l_output2+=("- $result")
        check_rsync_service_status
    else
       l_output+=("- rsync is not installed")
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