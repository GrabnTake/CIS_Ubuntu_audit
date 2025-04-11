#!/usr/bin/env bash

a_output=()
a_output2=()

# Check INACTIVE in useradd defaults
inactive_default=$(useradd -D 2>/dev/null | grep -i 'INACTIVE' | awk -F= '{print $2}')
# Check /etc/shadow for non-compliant INACTIVE
shadow_violations=$(awk -F: '($2~/^\$.+\$/) {if($7 > 45 || $7 < 0)print "User: " $1 " INACTIVE: " $7}' /etc/shadow 2>/dev/null)

if [ -n "$inactive_default" ] && [ "$inactive_default" -le 45 ] && [ "$inactive_default" -ge 0 ]; then
    if [ -z "$shadow_violations" ]; then
        audit_result="PASS"
        a_output+=("- INACTIVE in useradd defaults is set to $inactive_default (≤ 45 days)")
        a_output+=("- All /etc/shadow passwords have INACTIVE ≤ 45 and ≥ 0 days")
        a_output+=("- Note: Verify INACTIVE meets local site policy")
    else
        audit_result="FAIL"
        a_output2+=("- INACTIVE in useradd defaults is $inactive_default, but /etc/shadow violations found:")
        while IFS= read -r line; do
            a_output2+=("  $line")
        done <<< "$shadow_violations"
    fi
else
    audit_result="FAIL"
    [ -z "$inactive_default" ] && a_output2+=("- INACTIVE not set in useradd defaults")
    [ -n "$inactive_default" ] && { [ "$inactive_default" -gt 45 ] || [ "$inactive_default" -lt 0 ]; } && a_output2+=("- INACTIVE in useradd defaults is $inactive_default (> 45 or < 0 days)")
    [ -n "$shadow_violations" ] && a_output2+=("- /etc/shadow violations found:") && while IFS= read -r line; do a_output2+=("  $line"); done <<< "$shadow_violations"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"