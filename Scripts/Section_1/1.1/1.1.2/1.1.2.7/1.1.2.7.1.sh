#!/bin/bash

correct_settings=""
mount_output=$(findmnt -kn /var/log/audit)
audit_result="FAIL"
reason_for_failure=""

# Check if /var/log/audit is mounted
if [[ -n "$mount_output" ]]; then
  audit_result="PASS"
  correct_settings="- /var/log/audit is mounted: $mount_output"
else
  reason_for_failure="- /var/log/audit is not mounted as a separate filesystem"
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