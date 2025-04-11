#!/usr/bin/env bash

a_output=()
a_output2=()

# Check PASS_MIN_DAYS in /etc/login.defs
pass_min_days=$(grep -Pi -- '^\h*PASS_MIN_DAYS\h+\d+\b' /etc/login.defs 2>/dev/null | awk '{print $2}')
# Check /etc/shadow for non-compliant PASS_MIN_DAYS
shadow_violations=$(awk -F: '($2~/^\$.+\$/) {if($4 < 1)print "User: " $1 " PASS_MIN_DAYS: " $4}' /etc/shadow 2>/dev/null)

if [ -n "$pass_min_days" ] && [ "$pass_min_days" -gt 0 ]; then
    if [ -z "$shadow_violations" ]; then
        audit_result="PASS"
        a_output+=("- PASS_MIN_DAYS in /etc/login.defs is set to $pass_min_days (> 0 days)")
        a_output+=("- All /etc/shadow passwords have PASS_MIN_DAYS > 0")
        a_output+=("- Note: Verify PASS_MIN_DAYS meets local site policy")
    else
        audit_result="FAIL"
        a_output2+=("- PASS_MIN_DAYS in /etc/login.defs is $pass_min_days, but /etc/shadow violations found:")
        while IFS= read -r line; do
            a_output2+=("  $line")
        done <<< "$shadow_violations"
    fi
else
    audit_result="FAIL"
    [ -z "$pass_min_days" ] && a_output2+=("- PASS_MIN_DAYS not set in /etc/login.defs")
    [ -n "$pass_min_days" ] && [ "$pass_min_days" -le 0 ] && a_output2+=("- PASS_MIN_DAYS in /etc/login.defs is $pass_min_days (≤ 0 days)")
    [ -n "$shadow_violations" ] && a_output2+=("- /etc/shadow violations found:") && while IFS= read -r line; do a_output2+=("  $line"); done <<< "$shadow_violations"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"