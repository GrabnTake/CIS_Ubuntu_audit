#!/usr/bin/env bash

a_output=()
a_output2=()
# Check if /tmp is mounted
mount_output=$(findmnt -kn /tmp)
# If mounted, check for nodev
if [[ -n "$mount_output" ]]; then
  if echo "$mount_output" | grep -v 'nodev' >/dev/null 2>&1; then
    reason_for_failure="- The /tmp partition does not have the 'nodev' mount option set. Current mount options: $mount_output"
  else
    audit_result="PASS"
    correct_settings="- The /tmp partition has the 'nodev' mount option set: $mount_output"
  fi
else
  reason_for_failure="- /tmp is not mounted as a separate filesystem"
fi

audit_result="FAIL"
if [ "${#a_output2[@]}" -le 0 ]; then
    audit_result="PASS"
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
printf '%s\n' "${a_output[@]}"

if [ "$audit_result" == "FAIL" ]; then
  echo "--------------------------"
  echo "Reason(s) for Failure:"
  printf '%s\n' "${a_output2[@]}"
fi