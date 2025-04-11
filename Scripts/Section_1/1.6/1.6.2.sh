#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Function to check issue contents
check_issue() {
    # Check if /etc/issue exists
    if [ -f "/etc/issue" ]; then
        # Check the contents of /etc/issue
        issue_content=$(cat /etc/issue)

        if [ -n "$issue_content" ]; then
            a_output+=(" - /etc/issue contains information")
        else
            a_output2+=(" - /etc/issue is empty or does not contain policy-violating information")
        fi

        # Check if any sensitive system information exists in /etc/issue
        if grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/"//g'))" /etc/issue &> /dev/null; then
            a_output2+=(" - Sensitive system information found in /etc/issue")
        else
            a_output+=(" - No sensitive information found in /etc/issue")
        fi
    else
        a_output2+=(" - /etc/issue does not exist")
    fi
}

# Run the function to check /etc/issue
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
