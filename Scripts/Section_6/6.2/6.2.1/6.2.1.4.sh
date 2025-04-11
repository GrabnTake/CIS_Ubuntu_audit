#!/usr/bin/env bash

a_output=()
a_output2=()


while IFS= read -r l_line; do
    a_output2+=("- Found kernel boot line without audit_backlog_limit: \"$l_line\"")
done < <(find /boot -type f -name 'grub.cfg' -exec grep -Ph -- '^\h*linux' {} + 2>/dev/null | grep -Pv 'audit_backlog_limit=\d+\b')

# Determine result
if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
    a_output+=("- All kernel boot lines in /boot/grub.cfg include audit_backlog_limit=<number> (or no grub.cfg found)")
else
    audit_result="FAIL"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"