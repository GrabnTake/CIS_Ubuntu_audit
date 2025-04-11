#!/usr/bin/env bash

a_output=()    # Array for output messages (for manual review)

# Check GPG key files in /etc/apt/trusted.gpg.d/ and /etc/apt/sources.list.d/
for file in /etc/apt/trusted.gpg.d/*.{gpg,asc} /etc/apt/sources.list.d/*.{gpg,asc}; do
    if [ -f "$file" ]; then
        # Start output for this file
        a_output+=("- File: \"$file\"")
        
        # Extract and list unique key IDs
        while read -r line; do
            a_output+=("  $line")
        done < <(gpg --list-packets "$file" 2>/dev/null | awk '/keyid/ && !seen[$NF]++ {print "keyid: " $NF}')
        
        # Extract Signed-By fields (if present)
        while read -r line; do
            a_output+=("  $line")
        done < <(gpg --list-packets "$file" 2>/dev/null | awk '/Signed-By:/ {print "signed-by: " $NF}')
        
        # Add a separator for readability
        a_output+=("")
    fi
done

# Print audit report for manual review
echo "====== Audit Report ======"
echo "Audit Result: MANUAL"
echo "--------------------------"
echo "GPG Key Configuration Details:"
if [ ${#a_output[@]} -eq 0 ]; then
    echo "- No GPG key files found in /etc/apt/trusted.gpg.d/ or /etc/apt/sources.list.d/"
else
    printf '%s\n' "${a_output[@]}"
fi
echo "--------------------------"
echo "Instructions:"
echo "- REVIEW and VERIFY the listed GPG keys against site policy to ensure correct configuration for the package manager."
echo "- Note: apt-key is deprecated; use keyring files in /etc/apt/trusted.gpg.d/ and the Signed-By option in sources.list."