#!/usr/bin/env bash

# Initialize variables
audit_result="Pass"
reason_for_failure=""
correct_settings=""

# Check if AppArmor is installed
if dpkg-query -s apparmor &>/dev/null; then
    correct_settings+="- AppArmor is properly installed\n"
else
    audit_result="Fail"
    reason_for_failure+="- AppArmor is not installed.\n"
fi

# Check if AppArmor utilities are installed
if dpkg-query -s apparmor-utils &>/dev/null; then
    correct_settings+="- AppArmor utilities are properly installed\n"
else
    audit_result="Fail"
    reason_for_failure+="- AppArmor-utils is not installed.\n"
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
if [ "$audit_result" == "Pass" ]; then
    echo "Correct Settings:"
    echo -e "$correct_settings" | sed '/^$/d'
else
    echo "Correct Settings:"
    echo -e "$correct_settings" | sed '/^$/d'
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    echo -e "$reason_for_failure" | sed '/^$/d'
fi
