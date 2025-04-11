#!/usr/bin/env bash

a_output=()

# Check if augenrules is available before proceeding
if ! command -v augenrules >/dev/null 2>&1; then
    echo "====== Audit Report ======"
    echo "Audit Result: MANUAL"
    echo "--------------------------"
    echo "Current Settings:"
    echo "(none)"
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    echo "- augenrules not found; cannot perform merged rule sets check"
    echo "- Install audit package to enable augenrules"
    exit 1
fi

# Expected output from augenrules
expected_output="/usr/sbin/augenrules: No change"

# Run augenrules --check to verify merged rule sets (exact logic from your input)
check_result=$(augenrules --check 2>&1)

# Store the result for display
if [ "$check_result" = "$expected_output" ]; then
    a_output+=("- Merged rule sets check: \"$check_result\" (all rules in /etc/audit/rules.d/ merged into /etc/audit/audit.rules)")
else
    a_output+=("- Merged rule sets check: \"$check_result\" (differences detected between /etc/audit/rules.d/ and /etc/audit/audit.rules)")
fi

echo "====== Audit Report ======"
echo "Audit Result: MANUAL "
echo "--------------------------"
echo "Current Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
echo "--------------------------"
echo "Note: Verify that the output matches \"$expected_output\" to ensure no configuration differences."