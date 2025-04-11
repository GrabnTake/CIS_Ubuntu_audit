#!/usr/bin/env bash

a_output=()
a_output2=()

# Check PASS_MAX_DAYS in /etc/login.defs
pass_max_days=$(grep -Pi -- '^\h*PASS_MAX_DAYS\h+\d+\b' /etc/login.defs 2>/dev/null | awk '{print $2}')
# Check /etc/shadow for non-compliant PASS_MAX_DAYS
shadow_violations=$(awk -F: '($2~/^\$.+\$/) {if($5 > 365 || $5 < 1)print "User: " $1 " PASS_MAX_DAYS: " $5}' /etc/shadow 2>/dev/null)

if [ -n "$pass_max_days" ] && [ "$pass_max_days" -le 365 ]; then
    if [ -z "$shadow_violations" ]; then
        audit_result="PASS"
        a_output+=("- PASS_MAX_DAYS in /etc/login.defs is set to $pass_max_days (≤ 365 days)")
        a_output+=("- All /etc/shadow passwords have PASS_MAX_DAYS between 1 and 365 days")
        a_output+=("- Note: Verify PASS_MAX_DAYS meets local site policy")
    else
        audit_result="FAIL"
        a_output2+=("- PASS_MAX_DAYS in /etc/login.defs is $pass_max_days, but /etc/shadow violations found:")
        while IFS= read -r line; do
            a_output2+=("  $line")
        done <<< "$shadow_violations"
    fi
else
    audit_result="FAIL"
    [ -z "$pass_max_days" ] && a_output2+=("- PASS_MAX_DAYS not set in /etc/login.defs")
    [ -n "$pass_max_days" ] && [ "$pass_max_days" -gt 365 ] && a_output2+=("- PASS_MAX_DAYS in /etc/login.defs is $pass_max_days (> 365 days)")
    [ -n "$shadow_violations" ] && a_output2+=("- /etc/shadow violations found:") && while IFS= read -r line; do a_output2+=("  $line"); done <<< "$shadow_violations"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"