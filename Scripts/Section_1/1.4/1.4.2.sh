#!/bin/bash

# Path to the grub configuration file
grub_file="/boot/grub/grub.cfg"

# Initialize variables
audit_result="Pass"
reason_for_failure=()
correct_settings=()
# Check if the file exists
if [ ! -f "$grub_file" ]; then
    audit_result="Fail"
    reason_for_failure="File $grub_file does not exist."
else
    # Get stat output using the CIS command
    file_stat=$(stat -Lc 'Access: (%#a/%A) Uid: ( %u/ %U) Gid: ( %g/ %G)' "$grub_file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        audit_result="Fail"
        reason_for_failure="- Failed to retrieve stat information for $grub_file."
    else
        

        # Extract permissions, UID, and GID with more robust parsing
        permissions=$(echo "$file_stat" | grep -o 'Access: ([0-7]\{4\}' | cut -d'(' -f2)  # Extracts "0664" from "Access: (0664"
        uid=$(echo "$file_stat" | grep -o 'Uid: ([[:space:]]*[0-9]\+' | cut -d'(' -f2 | tr -d ' ')  # Extracts "0" from "Uid: ( 0"
        gid=$(echo "$file_stat" | grep -o 'Gid: ([[:space:]]*[0-9]\+' | cut -d'(' -f2 | tr -d ' ')  # Extracts "0" from "Gid: ( 0"

        

        # Check UID and GID (must be 0 for root)
        if [ -z "$uid" ] || [ -z "$gid" ] || [ "$uid" -ne 0 ] || [ "$gid" -ne 0 ]; then
            audit_result="Fail"
            reason_for_failure+="- UID ($uid) or GID ($gid) is invalid or not 0 (root)."
        else
            correct_settings+=("- UID and GID are correctly set to root (0).")
        fi

        # Check permissions (must be 0600 or more restrictive)
        if [ "$permissions" -gt 0600 ]; then
            audit_result="Fail"
            if [ -n "$reason_for_failure" ]; then
                reason_for_failure+="- Permissions ($permissions) are less restrictive than 0600."
            else
                reason_for_failure+="- Permissions ($permissions) are less restrictive than 0600."
            
            fi
        else
            correct_settings+=("- File permissions ($permissions) are correctly set.")
        fi
    fi
fi

# Report results in plain text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"

# Report results in plain text format
if [ ${#reason_for_failure[@]} -le 0 ]; then
    echo "Correct Settings:"
    printf '%s\n' "${correct_settings[@]}"
else
    echo "Correct Settings:"
    printf '%s\n' "${correct_settings[@]}"
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${reason_for_failure[@]}"
fi

