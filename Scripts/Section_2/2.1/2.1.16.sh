#!/usr/bin/env bash
{
    # Function to check the installation status of tftpd_hpa
    check_tftpd_hpa_installed() {
        dpkg-query -s tftpd-hpa &>/dev/null && echo "tftpd-hpa is installed"
    }

    # Function to check if the tftpd_hpa is enabled or active
    check_tftpd_hpa_service_status() {
        enabled=$(systemctl is-enabled tftpd-hpa.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active tftpd-hpa.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- tftpd_hpa is enabled")
        else
            l_output+=( "- tftpd_hpa is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- tftpd_hpa is active")
        else
            l_output+=( "- tftpd_hpa is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if tftpd_hpa is installed
    result=$(check_tftpd_hpa_installed)

    # If tftpd_hpa is installed, check the service status
    if [[ "$result" == "tftpd_hpa is installed" ]]; then
        l_output2+=("- $result")
        check_tftpd_hpa_service_status
    else
       l_output+=("- tftpd_hpa is not installed")
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