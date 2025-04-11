#!/bin/bash

correct_settings=""
# Check if /var is mounted
mount_output=$(findmnt -kn /var)

# Result and reason for failure
audit_result="FAIL"
reason_for_failure=""

# If mounted, check for nodev
if [[ -n "$mount_output" ]]; then
  if echo "$mount_output" | grep -v 'nodev' >/dev/null 2>&1; then
    reason_for_failure="- The /var partition does not have the 'nodev' mount option set. Current mount options: $mount_output"
  else
    audit_result="PASS"
    correct_settings="- The /var partition has the 'nodev' mount option set: $mount_output"
  fi
else
  reason_for_failure="- /var is not mounted as a separate filesystem"
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
echo -e "$correct_settings" | sed '/^$/d'

if [ "$audit_result" == "FAIL" ]; then
  echo "--------------------------"
  echo "Reason(s) for Failure:"
  echo -e "$reason_for_failure" | sed '/^$/d'
fi
