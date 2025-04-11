#!/usr/bin/env bash

a_output=()
a_output2=()

# Check PASS_WARN_AGE in /etc/login.defs
pass_warn_age=$(grep -Pi -- '^\h*PASS_WARN_AGE\h+\d+\b' /etc/login.defs 2>/dev/null | awk '{print $2}')
# Check /etc/shadow for non-compliant PASS_WARN_AGE
shadow_violations=$(awk -F: '($2~/^\$.+\$/) {if($6 < 7)print "User: " $1 " PASS_WARN_AGE: " $6}' /etc/shadow 2>/dev/null)

if [ -n "$pass_warn_age" ] && [ "$pass_warn_age" -ge 7 ]; then
    if [ -z "$shadow_violations" ]; then
        audit_result="PASS"
        a_output+=("- PASS_WARN_AGE in /etc/login.defs is set to $pass_warn_age (≥ 7 days)")
        a_output+=("- All /etc/shadow passwords have PASS_WARN_AGE ≥ 7")
        a_output+=("- Note: Verify PASS_WARN_AGE meets local site policy")
    else
        audit_result="FAIL"
        a_output2+=("- PASS_WARN_AGE in /etc/login.defs is $pass_warn_age, but /etc/shadow violations found:")
        while IFS= read -r line; do
            a_output2+=("  $line")
        done <<< "$shadow_violations"
    fi
else
    audit_result="FAIL"
    [ -z "$pass_warn_age" ] && a_output2+=("- PASS_WARN_AGE not set in /etc/login.defs")
    [ -n "$pass_warn_age" ] && [ "$pass_warn_age" -lt 7 ] && a_output2+=("- PASS_WARN_AGE in /etc/login.defs is $pass_warn_age (< 7 days)")
    [ -n "$shadow_violations" ] && a_output2+=("- /etc/shadow violations found:") && while IFS= read -r line; do a_output2+=("  $line"); done <<< "$shadow_violations"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"