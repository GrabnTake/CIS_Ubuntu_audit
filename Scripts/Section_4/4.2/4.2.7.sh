#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if UFW is in use first
if ! {command -v ufw &>/dev/null && systemctl is-active --quiet ufw; } ; then
    audit_result="SKIP"
    a_output+=("- UFW is not in use, audit skipped")
else
    # Capture default policy line
    default_line=$(ufw status verbose | grep "Default:")

    # Extract policies
    incoming=$(echo "$default_line" | grep -oP "Default:\s*\K\w+(?=\s*\(incoming\))")
    outgoing=$(echo "$default_line" | grep -oP "Default:.*\b\K\w+(?=\s*\(outgoing\))")
    routed=$(echo "$default_line" | grep -oP "Default:.*\b\K\w+(?=\s*\(routed\))")

    # Valid policies
    valid_policies="deny reject disabled"

    # Check each policy
    if echo "$valid_policies" | grep -qw "$incoming"; then
        a_output+=("- Default incoming policy is $incoming")
    else
        a_output2+=("- Default incoming policy is $incoming (must be deny, reject, or disabled)")
    fi

    if echo "$valid_policies" | grep -qw "$outgoing"; then
        a_output+=("- Default outgoing policy is $outgoing")
    else
        a_output2+=("- Default outgoing policy is $outgoing (must be deny, reject, or disabled)")
    fi

    if echo "$valid_policies" | grep -qw "$routed"; then
        a_output+=("- Default routed policy is $routed")
    else
        a_output2+=("- Default routed policy is $routed (must be deny, reject, or disabled)")
    fi

    # Set audit result
    audit_result="FAIL"
    if [ ${#a_output2[@]} -le 0 ]; then
        audit_result="PASS"
    fi
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
if [ ${#a_output[@]} -eq 0 ]; then
    echo "(none)"
else
    printf '%s\n' "${a_output[@]}"
fi

if [ "$audit_result" == "FAIL" ]; then
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${a_output2[@]}"
fi