#!/usr/bin/env bash

# Initialize variables
audit_result="PASS"
reason_for_failure=""
correct_settings=""

# Check if apparmor_status (or aa-status) is available
if ! command -v apparmor_status >/dev/null 2>&1 && ! command -v aa-status >/dev/null 2>&1; then
    audit_result="FAIL"
    reason_for_failure="\n - AppArmor status command (apparmor_status or aa-status) not found."
else
    # Use apparmor_status or fallback to aa-status
    APPARMOR_CMD=$(command -v apparmor_status || command -v aa-status)

    # Get AppArmor status output once
    status_output=$("$APPARMOR_CMD" 2>/dev/null)
    if [ $? -ne 0 ]; then
        audit_result="FAIL"
        reason_for_failure="\n - Failed to retrieve AppArmor status."
    else
        # Extract counts with robust parsing
        loaded_profiles=$(echo "$status_output" | grep -E "[0-9]+ profiles are loaded" | awk '{print $1}' || echo "0")
        enforce_profiles=$(echo "$status_output" | grep -E "[0-9]+ profiles are in enforce mode" | awk '{print $1}' || echo "0")
        complain_profiles=$(echo "$status_output" | grep -E "[0-9]+ profiles are in complain mode" | awk '{print $1}' || echo "0")
        unconfined_count=$(echo "$status_output" | grep -E "[0-9]+ processes are unconfined" | awk '{print $1}' || echo "0")

        # Check if profiles are loaded
        if [ -z "$loaded_profiles" ] || [ "$loaded_profiles" -eq 0 ]; then
            audit_result="FAIL"
            reason_for_failure="\n - No AppArmor profiles are loaded."
        else
            correct_settings="\n - $loaded_profiles profiles are loaded."
            
            # Check if all loaded profiles are in enforce mode
            if [ "$enforce_profiles" -eq "$loaded_profiles" ] && [ "$complain_profiles" -eq 0 ]; then
                correct_settings+="\n - All profiles are in enforce mode."
            else
                audit_result="FAIL"
                reason_for_failure="\n - Not all AppArmor profiles are in enforce mode (Loaded: $loaded_profiles, Enforce: $enforce_profiles, Complain: $complain_profiles)."
            fi
        fi

        # Check if any processes are unconfined
        if [ "$unconfined_count" -ne 0 ]; then
            audit_result="FAIL"
            reason_for_failure+="\n - $unconfined_count processes are unconfined."
        else
            correct_settings+="\n - No unconfined processes found."
        fi
    fi
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
if [ "$audit_result" == "PASS" ]; then
    echo "Correct Settings:"
    echo -e "$correct_settings"| sed '/^$/d'
else
    echo "Correct Settings:"
    echo -e "$correct_settings"| sed '/^$/d'
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    echo -e "$reason_for_failure"| sed '/^$/d'
fi
