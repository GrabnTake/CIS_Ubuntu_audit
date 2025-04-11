#!/usr/bin/env bash

# Initialize variables
audit_result="PASS"
reason_for_failure=""
correct_settings=()

# Check if AppArmor profiles are loaded
loaded_profiles=$(apparmor_status | grep "profiles are loaded" | awk '{print $1}')
if [[ -z "$loaded_profiles" || "$loaded_profiles" -eq 0 ]]; then
    audit_result="FAIL"
    reason_for_failure="No AppArmor profiles are loaded."
else
    correct_settings+=("- $loaded_profiles profiles are loaded.")
fi

# Check if any processes are unconfined
unconfined_count=$(apparmor_status | grep "processes are unconfined" | awk '{print $1}')
if [[ -n "$unconfined_count" && "$unconfined_count" -ne 0 ]]; then
    audit_result="FAIL"
    reason_for_failure="${reason_for_failure:+$reason_for_failure }Some processes are unconfined ($unconfined_count)."
else
    correct_settings+=("- No unconfined processes found.")
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
echo -e "$correct_settings" | sed '/^$/d'
if [ "$audit_result" == "Fail" ]; then
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    echo -e "$reason_for_failure" | sed '/^$/d'
fi

