#!/bin/bash

correct_settings=""
mount_output=$(findmnt -kn /home)
audit_result="FAIL"
reason_for_failure=""

# Check if /home is mounted
if [[ -n "$mount_output" ]]; then
  audit_result="PASS"
  correct_settings="- /home is mounted: $mount_output"
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