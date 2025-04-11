#!/usr/bin/env bash
{
    # Function to check if autofs is installed
    check_autofs_installed() {
        dpkg-query -s autofs &>/dev/null && echo "autofs is installed" || echo "autofs is not installed"
    }

    # Function to check if autofs service is enabled
    check_autofs_service_enabled() {
        systemctl is-enabled autofs.service 2>/dev/null | grep 'enabled' && echo "autofs.service is enabled" || echo "autofs.service is not enabled"
    }

    # Function to check if autofs service is active
    check_autofs_service_active() {
        systemctl is-active autofs.service 2>/dev/null | grep '^active' && echo "autofs.service is active" || echo "autofs.service is not active"
    }

    # Arrays to collect output messages
    l_output=()
    l_output2=()

    # Run checks for autofs installation, enabled and active status
    result_installed=$(check_autofs_installed)
    if [[ $result_installed == *"installed"* ]]; then
        l_output2+=("- $result_installed")  # Failure: autofs is installed
    else
        l_output+=("- $result_installed")   # Success: autofs is not installed
    fi

    result_enabled=$(check_autofs_service_enabled)
    if [[ $result_enabled == *"enabled"* ]]; then
        l_output2+=("- $result_enabled")  # Failure: autofs.service is enabled
    else
        l_output+=("- $result_enabled")   # Success: autofs.service is not enabled
    fi

    result_active=$(check_autofs_service_active)
    if [[ $result_active == *"active"* ]]; then
        l_output2+=("- $result_active")  # Failure: autofs.service is active
    else
        l_output+=("- $result_active")   # Success: autofs.service is not active
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
