#!/usr/bin/env bash
{
    # Function to check the installation status of snmp
    check_snmp_installed() {
        dpkg-query -s snmpd &>/dev/null && echo "snmpd is installed"
    }

    # Function to check if the snmp is enabled or active
    check_snmp_service_status() {
        enabled=$(systemctl is-enabled snmpd.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active snmpd.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- snmp is enabled")
        else
            l_output+=( "- snmp is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- snmp is active")
        else
            l_output+=( "- snmp is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if snmp is installed
    result=$(check_snmp_installed)

    # If snmp is installed, check the service status
    if [[ "$result" == "snmp is installed" ]]; then
        l_output2+=("- $result")
        check_snmp_service_status
    else
       l_output+=("- snmp is not installed")
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