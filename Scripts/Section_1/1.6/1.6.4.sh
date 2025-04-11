#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Function to check /etc/motd permissions
check_motd_permissions() {
    if [ -e "/etc/motd" ]; then
        # Get file permissions, UID, and GID
        file_stat=$(stat -Lc '%#a %u %g' /etc/motd)
        file_perm=$(echo "$file_stat" | awk '{print $1}')
        file_uid=$(echo "$file_stat" | awk '{print $2}')
        file_gid=$(echo "$file_stat" | awk '{print $3}')

        # Check if permissions are 644 or more restrictive (600, 640, etc.)
        if [[ "$file_perm" -le 644 && "$file_uid" -eq 0 && "$file_gid" -eq 0 ]]; then
            a_output+=(" - /etc/motd has correct permissions and ownership")
        else
            a_output2+=(" - Incorrect permissions or ownership for /etc/motd (Current: $file_stat)")
        fi
    else
        a_output+=(" - /etc/motd does not exist")
    fi
}

# Run the function to check /etc/motd
check_motd_permissions

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

