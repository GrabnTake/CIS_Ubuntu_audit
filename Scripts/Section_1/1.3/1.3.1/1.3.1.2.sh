#!/usr/bin/env bash

# Initialize variables
audit_result="Pass"
reason_for_failure=""
correct_settings=""

# Check if all 'linux' lines contain 'apparmor=1'
if grep "^\s*linux" /boot/grub/grub.cfg | grep -q "apparmor=1"; then
    correct_settings+="- AppArmor is enabled with 'apparmor=1' parameter\n"
else
    audit_result="Fail"
    reason_for_failure+="- Missing 'apparmor=1' parameter in bootloader configuration.\n"
fi

# Check if all 'linux' lines contain 'security=apparmor'
if grep "^\s*linux" /boot/grub/grub.cfg | grep -q "security=apparmor"; then
    correct_settings+="- AppArmor is set as security module with 'security=apparmor' parameter\n"
else
    audit_result="Fail"
    reason_for_failure+="- Missing 'security=apparmor' parameter in bootloader configuration.\n"
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
