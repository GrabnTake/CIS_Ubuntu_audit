#!/usr/bin/env bash
{
    # Function to check the installation status of dovecot
    check_dovecot_imapd_installed() {
        dpkg-query -s dovecot-imapd &>/dev/null && echo "dovecot-imapd is installed"
    }
    check_dovecot_pop3d_installed() {
        dpkg-query -s dovecot-pop3d &>/dev/null && echo "dovecot-pop3d is installed"
    }

    # Function to check if the dovecot.service is enabled or active
    check_dovecot_service_status() {
        enabled=$(systemctl is-enabled dovecot.socket dovecot.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active dovecot.socket dovecot.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- dovecot.service is enabled")
        else
            l_output+=( "- dovecot.service is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- dovecot.service is active")
        else
            l_output+=( "- dovecot.service is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if dovecot is installed
    result=$(check_dovecot_imapd_installed)
    result1=$(check_dovecot_pop3d_installed)

    # If dovecot-impad is installed, check the service status
    if [[ "$result" == "dovecot-imapd is installed" ]]; then
        check_dovecot_service_status
    fi

    # Check if dovecot-impad is installed
    if [[ "$result" == "dovecot-imapd is installed" ]]; then
        l_output2+=("- $result")
    else
       l_output+=("- dovecot-imapd is not installed")
    fi
    
    

    # If dovecot-pop3d is installed, check the service status
    if [[ "$result" == "dovecot-pop3d is installed" ]]; then
        check_dovecot_service_status
    fi

    # Check if dovecot-pop3d is installed
    if [[ "$result" == "dovecot-pop3d is installed" ]]; then
        l_output2+=("- $result")
    else
       l_output+=("- dovecot-pop3d is not installed")
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
