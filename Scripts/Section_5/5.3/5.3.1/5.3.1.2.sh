#!/usr/bin/env bash

a_output=()
a_output2=()

# Check libpam-modules status and version
pam_status=$(dpkg-query -s libpam-modules 2>/dev/null | grep -P '^(Status|Version)\b')
version=$(echo "$pam_status" | grep "^Version:" | awk '{print $2}')

if [ -n "$pam_status" ] && echo "$pam_status" | grep -q "Status: install ok installed"; then
    # Compare version (assuming dpkg handles version comparison reliably)
    if dpkg --compare-versions "$version" "ge" "1.5.3-5" 2>/dev/null; then
        audit_result="PASS"
        a_output+=("- libpam-modules is installed and version is $version (1.5.3-5 or later):")
        while IFS= read -r line; do
            a_output+=("  $line")
        done <<< "$pam_status"
    else
        audit_result="FAIL"
        a_output2+=("- libpam-modules version $version is earlier than 1.5.3-5")
    fi
else
    audit_result="FAIL"
    a_output2+=("- libpam-modules is not installed or status is not 'install ok installed'")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"