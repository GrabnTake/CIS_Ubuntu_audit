#!/bin/bash

correct_settings=""
# Check if /home is mounted first, then check nodev
mount_output=$(findmnt -kn /home)
audit_result="FAIL"
reason_for_failure=""

if [[ -n "$mount_output" ]]; then
  if echo "$mount_output" | grep -v 'nodev' >/dev/null 2>&1; then
    reason_for_failure="- The /home partition does not have the 'nodev' mount option set. Current mount options: $mount_output"
  else
    audit_result="PASS"
    correct_settings="- The /home partition has the 'nodev' mount option set."
  fi
else
  reason_for_failure="- /home is not mounted as a separate filesystem"
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

