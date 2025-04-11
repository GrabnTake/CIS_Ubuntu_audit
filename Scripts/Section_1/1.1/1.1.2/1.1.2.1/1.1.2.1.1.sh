#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if /tmp is a separate partition
if findmnt -kn /tmp &> /dev/null; then
    a_output+=(" - /tmp is mounted as a separate partition")
else
    a_output2+=(" - /tmp is NOT mounted as a separate partition")
fi

# Check if systemd mounts /tmp at boot
if systemctl is-enabled tmp.mount 2>/dev/null | grep -qE 'enabled|generated'; then
    a_output+=(" - systemd is configured to mount /tmp at boot")
else
    a_output2+=(" - systemd is NOT configured to mount /tmp at boot")
fi

# Standardized JSON Output using jq
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
