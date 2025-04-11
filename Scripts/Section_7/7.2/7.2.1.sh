#!/usr/bin/env bash

a_output=()
a_output2=()

# Check /etc/passwd for non-shadowed passwords
while IFS= read -r l_line; do
    a_output2+=("- $l_line")
done < <(awk -F: '($2 != "x") { print "User: \"" $1 "\" is not set to shadowed passwords" }' /etc/passwd)

# If no violations found, report success
if [ ${#a_output2[@]} -eq 0 ]; then
    a_output+=("- All user accounts in /etc/passwd are set to use shadowed passwords")
fi

# Determine result
if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
else
    audit_result="FAIL"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"