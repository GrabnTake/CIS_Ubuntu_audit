#!/usr/bin/env bash

# Initialize variables
audit_result="Pass"
reason_for_failure=()
correct_settings=()

# Check if a superuser is configured in GRUB
superuser_config=$(grep "^set superusers" /boot/grub/grub.cfg)

# Check if a password is configured in GRUB
password_config=$(awk -F. '/^\s*password/ {print $1"."$2"."$3}' /boot/grub/grub.cfg)

# Logic to check if both superuser and password are configured
if [[ -z "$superuser_config" ]]; then
  audit_result="Fail"
  reason_for_failure+="- No superuser is set in GRUB configuration."
else
correct_settings+="- Superuser is set in GRUB configuration."
fi

if [[ -z "$password_config" ]]; then
  # If the reason_for_failure is already set, append the new reason
  if [[ -n "$reason_for_failure" ]]; then
    reason_for_failure+="- No password is set for the GRUB bootloader."
    
  fi
else
  correct_settings+="- Password is set for the GRUB bootloader."
fi

# Report results in plain text format
if [ ${#reason_for_failure[@]} -le 0 ]; then
    echo "====== Audit Report ======"
    echo "Audit Result: PASS"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${correct_settings[@]}"
else
    echo "====== Audit Report ======"
    echo "Audit Result: FAIL"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${correct_settings[@]}"
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${reason_for_failure[@]}"
fi