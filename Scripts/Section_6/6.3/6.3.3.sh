#!/usr/bin/env bash

# Arrays to store output
a_output=()
a_output2=()

# Define variables
l_tool_dir="$(readlink -f /sbin)"
a_items=("p" "i" "n" "u" "g" "s" "b" "acl" "xattrs" "sha512")
l_aide_cmd="$(command -v aide)"
a_audit_files=("auditctl" "auditd" "ausearch" "aureport" "autrace" "augenrules")

# Check if AIDE is installed
if [ -z "$l_aide_cmd" ]; then
    a_output2+=("- AIDE is not installed. Please install AIDE.")
else
    # Locate AIDE configuration files
    a_aide_conf_files=($(find -L /etc -type f -name 'aide.conf'))

    # Function to check AIDE configuration for each audit tool file
    check_aide_config() {
        local file_output=()
        for item in "${a_items[@]}"; do
            if ! grep -Psiq -- '(\h+|\+)'"$item"'(\h+|\+)' <<< "$config_output"; then
                file_output+=("- Missing \"$item\" option")
            fi
        done
        
        if [ ${#file_output[@]} -eq 0 ]; then
            a_output+=("- Audit tool file: \"$audit_file\" includes: ${a_items[*]}")
        else
            a_output2+=("- Audit tool file: \"$audit_file\"" "${file_output[@]}")
        fi
    }

    # Check each audit tool file
    for audit_file in "${a_audit_files[@]}"; do
        if [ -f "$l_tool_dir/$audit_file" ]; then
            config_output="$("$l_aide_cmd" --config "${a_aide_conf_files[@]}" -p f:"$l_tool_dir/$audit_file")"
            check_aide_config
        else
            a_output2+=("- Audit tool file \"$audit_file\" does not exist")
        fi
    done
fi

# Determine audit result
audit_result="FAIL"
[ ${#a_output2[@]} -eq 0 ] && audit_result="PASS"

# Output audit report
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
if [ "$audit_result" = "FAIL" ]; then
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${a_output2[@]}"
fi
