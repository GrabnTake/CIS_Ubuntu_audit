#!/usr/bin/env bash

a_output=()
a_output2=()

# Expected output
expected_rule="-e 2"

# Check for immutable mode (exact logic from your input)
found_rule=$(grep -Ph -- '^\h*-e\h+2\b' /etc/audit/rules.d/*.rules 2>/dev/null | tail -1)

if [ "$found_rule" = "$expected_rule" ]; then
    a_output+=("- Disk rule matches: $expected_rule (immutable mode enabled)")
else
    if [ -z "$found_rule" ]; then
        a_output2+=("- No immutable mode rule found (-e 2 missing)")
    else
        a_output2+=("- Incorrect or misplaced immutable mode rule: found \"$found_rule\", expected \"$expected_rule\" as the last rule")
    fi
fi

# Additional check: Ensure /etc/audit/rules.d/ exists and has files
if ! ls /etc/audit/rules.d/*.rules >/dev/null 2>&1; then
    a_output2+=("- No audit rule files found in /etc/audit/rules.d/")
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