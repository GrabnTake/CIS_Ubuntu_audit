#!/usr/bin/env bash
{
    # Function to check the installation status of vsftpd
    check_vsftpd_installed() {
        dpkg-query -s vsftpd &>/dev/null && echo "vsftpd is installed"
    }

    # Function to check if the vsftpd.service is enabled or active
    check_vsftpd_service_status() {
        enabled=$(systemctl is-enabled vsftpd.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active vsftpd.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- vsftpd.service is enabled")
        else
            l_output+=( "- vsftpd.service is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- vsftpd.service is active")
        else
            l_output+=( "- vsftpd.service is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if vsftpd is installed
    result=$(check_vsftpd_installed)

    # If vsftpd is installed, check the service status
    if [[ "$result" == "vsftpd is installed" ]]; then
        check_vsftpd_service_status
    fi

    # Check if vsftpd is installed
    if [[ "$result" == "vsftpd is installed" ]]; then
        l_output2+=("- $result")
    else
       l_output+=("- vsftpd is not installed")
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
