#!/usr/bin/env bash
{
    # Function to check the installation status of apache2
    check_apache_installed() {
        dpkg-query -s apache2 &>/dev/null && echo "apache2 is installed"
    }

    # Function to check the installation status of nginx
    check_nginx_installed() {
        dpkg-query -s nginx &>/dev/null && echo "nginx is installed"
    }

    # Function to check if the apache2 is enabled or active
    check_apache_service_status() {
        enabled=$(systemctl is-enabled apache2.socket apache2.service nginx.service 2>/dev/null | grep 'enabled')
        active=$(systemctl is-active apache2.socket apache2.service nginx.service 2>/dev/null | grep '^active')

        if [[ -n "$enabled" ]]; then
            l_output2+=( "- apache2.socket apache2.service nginx.service is enabled")
        else
            l_output+=( "- apache2.socket apache2.service nginx.service is not enabled")
        fi

        if [[ -n "$active" ]]; then
            l_output2+=( "- apache2.socket apache2.service nginx.service is active")
        else
            l_output+=( "- apache2.socket apache2.service nginx.service is not activate")
        fi
    }

    # Arrays to store correct and incorrect results
    l_output=()
    l_output2=()

    # Check if apache is installed
    result=$(check_apache_installed)
    result1=$(check_nginx_installed)

    # If apache is installed, check the service status
    if [[ "$result" == "apache is installed" || "$result1" == "nginx is installed" ]]; then
        l_output2+=("- $result")
        l_output2+=("- $result1")
        check_apache_service_status
    else
       l_output+=("- apache is not installed")
       l_output+=("- nginx is not installed")
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