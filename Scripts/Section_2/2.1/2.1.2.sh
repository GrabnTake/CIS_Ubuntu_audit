#!/usr/bin/env bash
{
    # Function to check the installation status of avahi-daemon
    check_avahi_installed() {
        dpkg-query -s avahi-daemon &>/dev/null && echo "avahi-daemon is installed" || echo "avahi-daemon is not installed"
    }

    # Function to check if the avahi-daemon.socket and avahi-daemon.service are enabled or active
    check_avahi_service_status() {
        enabled=$(systemctl is-enabled avahi-daemon.socket avahi-daemon.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active avahi-daemon.socket avahi-daemon.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- avahi-daemon.socket or avahi-daemon.service is enabled")
        else
            l_output+=( "- avahi-daemon.socket or avahi-daemon.service is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- avahi-daemon.socket or avahi-daemon.service is active")
        else
            l_output+=( "- avahi-daemon.socket or avahi-daemon.service is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if avahi-daemon is installed
    result=$(check_avahi_installed)

    # If avahi-daemon is installed, check the service status
    if [[ "$result" == "avahi-daemon is installed" ]]; then
        check_avahi_service_status
    fi

    # Check if avahi-daemon is installed
    if [[ "$result" == "avahi-daemon is installed" ]]; then
        l_output2+=("- $result")
    else
        l_output+=("- $result")
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
