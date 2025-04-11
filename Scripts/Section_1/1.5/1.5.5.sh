#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Function to check if Apport Error Reporting Service is installed and enabled
check_apport_service() {
    # Check if Apport is installed
    if dpkg-query -s apport &>/dev/null; then
        # Check if Apport is enabled in /etc/default/apport
        if grep -Pqi -- '^\h*enabled\h*=\h*[^0]\b' /etc/default/apport; then
            a_output2+=(" - Apport is enabled in /etc/default/apport")
        else
            a_output+=(" - Apport is not enabled in /etc/default/apport")
        fi

        # Check if the Apport service is active
        if systemctl is-active --quiet apport.service; then
            a_output2+=(" - Apport service is active")
        else
            a_output+=(" - Apport service is not active")
        fi
    else
        a_output+=(" - Apport is not installed on the system")
    fi
}

# Run the function to check Apport
check_apport_service

# Report results in plain text format
if [ ${#a_output2[@]} -eq 0 ]; then
    echo "====== Audit Report ======"
    echo "Audit Result: PASS"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${a_output[@]}"
else
    echo "====== Audit Report ======"
    echo "Audit Result: FAIL"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${a_output[@]}"
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${a_output2[@]}"
fi

