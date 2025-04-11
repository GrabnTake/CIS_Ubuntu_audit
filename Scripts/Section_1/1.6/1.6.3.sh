#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Function to check issue.net contents
check_issue() {
    # Check if /etc/issue.net exists
    if [ -f "/etc/issue.net" ]; then
        # Check the contents of /etc/issue.net
        issue_content=$(cat /etc/issue.net)

        if [ -n "$issue_content" ]; then
            a_output+=(" - /etc/issue.net contains information")
        else
            a_output2+=(" - /etc/issue.net is empty or does not contain policy-violating information")
        fi

        # Check if any sensitive system information exists in /etc/issue.net
        if grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/"//g'))" /etc/issue.net &> /dev/null; then
            a_output2+=(" - Sensitive system information found in /etc/issue.net")
        else
            a_output+=(" - No sensitive information found in /etc/issue.net")
        fi
    else
        a_output2+=(" - /etc/issue.net does not exist")
    fi
}

# Run the function to check /etc/issue.net
check_issue

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
