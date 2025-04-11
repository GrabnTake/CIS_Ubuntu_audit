#!/usr/bin/env bash

# Function to check and report if a specific setting is locked and set to true
check_setting() {
    if grep -Psrilq "^\h*$1\h*=\h*true\b" /etc/dconf/db/local.d/locks/* 2> /dev/null; then
        echo "- \"$3\" is locked and set to true"
        return 0  # success: setting is correct
    else
        echo "- \"$3\" is not locked or not set to true"
        return 1  # failure: setting is incorrect
    fi
}

# Array of settings to check
declare -A settings=(["autorun-never"]="org/gnome/desktop/media-handling")

# Initialize output arrays
l_output=()
l_output2=()

# Check GNOME Desktop Manager configurations
for setting in "${!settings[@]}"; do
    result=$(check_setting "$setting" "${settings[$setting]}" "$setting")
    if [[ $? -eq 0 ]]; then
        l_output+=("$result")  # Correct setting
    else
        l_output2+=("$result")  # Incorrect or missing setting
    fi
done

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
