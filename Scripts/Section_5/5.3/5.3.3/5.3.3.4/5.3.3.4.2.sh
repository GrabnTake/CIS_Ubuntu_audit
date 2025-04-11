#!/usr/bin/env bash

a_output=()
a_output2=()

# Check pam_unix.so lines and filter out remember
pam_unix_lines=$(grep -PH -- '^\h*[^#\n\r]+\h+pam_unix\.so\b' /etc/pam.d/common-{password,auth,account,session,session-noninteractive} 2>/dev/null | grep -Pv -- '\bremember\b')

if [ -n "$pam_unix_lines" ]; then
    audit_result="PASS"
    a_output+=("- pam_unix.so found without remember in the following lines:")
    while IFS= read -r line; do
        a_output+=("  $line")
    done <<< "$pam_unix_lines"
else
    audit_result="FAIL"
    a_output2+=("- No pam_unix.so lines without remember found in /etc/pam.d/common-{password,auth,account,session,session-noninteractive}")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"