#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Function to check MOTD contents
check_motd() {
    # Check if /etc/motd exists
    if [ -f "/etc/motd" ]; then
        # Check the contents of /etc/motd
        motd_content=$(cat /etc/motd)

        if [ -n "$motd_content" ]; then
            a_output+=(" - /etc/motd contains information")
        else
            a_output2+=(" - /etc/motd is empty or does not contain policy-violating information")
        fi

        # Check if any sensitive system information exists in /etc/motd
        if grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))" /etc/motd &> /dev/null; then
            a_output2+=(" - Sensitive system information found in /etc/motd")
        else
            a_output+=(" - No sensitive information found in /etc/motd")
        fi
    else
        a_output2+=(" - /etc/motd does not exist")
    fi
}

# Run the function to check /etc/motd
check_motd

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
