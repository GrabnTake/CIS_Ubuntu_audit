#!/usr/bin/env bash

# Arrays to store output
a_output=()
a_output2=()

# Check if dailyaidecheck.timer and service exist
aide_status=$(systemctl list-unit-files | awk '$1~/^dailyaidecheck\.(timer|service)$/{print $1 "\t" $2}')

if echo "$aide_status" | grep -q "dailyaidecheck.timer"; then
    if echo "$aide_status" | grep -q "dailyaidecheck.timer.*enabled"; then
        a_output+=("✔ dailyaidecheck.timer is enabled")
    else
        a_output2+=("❌ dailyaidecheck.timer is not enabled")
    fi
else
    a_output2+=("❌ dailyaidecheck.timer is missing")
fi

if echo "$aide_status" | grep -q "dailyaidecheck.service"; then
    if echo "$aide_status" | grep -qE "dailyaidecheck.service\s+(static|enabled)"; then
        a_output+=("✔ dailyaidecheck.service is correctly set to static or enabled")
    else
        a_output2+=("❌ dailyaidecheck.service is not static or enabled")
    fi
else
    a_output2+=("❌ dailyaidecheck.service is missing")
fi

# Check if dailyaidecheck.timer is active
if systemctl is-active --quiet dailyaidecheck.timer; then
    a_output+=("✔ dailyaidecheck.timer is active")
else
    a_output2+=("❌ dailyaidecheck.timer is not active")
fi

# Determine audit result
audit_result="FAIL"
[ ${#a_output2[@]} -eq 0 ] && audit_result="PASS"

# Output audit report
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
if [ "$audit_result" = "FAIL" ]; then
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${a_output2[@]}"
fi
