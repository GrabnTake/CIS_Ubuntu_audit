#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if ip6tables is in use (custom rules beyond defaults)
if ! { command -v ip6tables &>/dev/null && ip6tables -L -n --line-numbers 2>/dev/null | grep -v "^Chain\|^$" | grep -q "[1-9]"; }; then
    # If ip6tables isn’t in use, check if IPv6 is disabled
    ipv6_enabled="is"
    if ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable 2>/dev/null; then
        ipv6_enabled="is not"
    fi
    if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
       sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
        ipv6_enabled="is not"
    fi

    if [ "$ipv6_enabled" = "is not" ]; then
        audit_result="PASS"
        a_output+=("- IPv6 is disabled on the system (ip6tables not required)")
    else
        audit_result="SKIP"
        a_output+=("- ip6tables is not in use (no custom rules or not installed) and IPv6 is enabled, audit skipped")
    fi
else
    # ip6tables is in use, check chain policies
    ip6tables_output=$(ip6tables -L -n 2>/dev/null)

    # Extract policies
    input_policy=$(echo "$ip6tables_output" | grep "^Chain INPUT" | grep -o "policy [A-Z]\+" | cut -d' ' -f2)
    forward_policy=$(echo "$ip6tables_output" | grep "^Chain FORWARD" | grep -o "policy [A-Z]\+" | cut -d' ' -f2)
    output_policy=$(echo "$ip6tables_output" | grep "^Chain OUTPUT" | grep -o "policy [A-Z]\+" | cut -d' ' -f2)

    # Verify policies
    input_ok=false
    if [ "$input_policy" = "DROP" ] || [ "$input_policy" = "REJECT" ]; then
        input_ok=true
        a_output+=("- INPUT chain policy is $input_policy")
    else
        a_output2+=("- INPUT chain policy is $input_policy (should be DROP or REJECT)")
    fi

    forward_ok=false
    if [ "$forward_policy" = "DROP" ] || [ "$forward_policy" = "REJECT" ]; then
        forward_ok=true
        a_output+=("- FORWARD chain policy is $forward_policy")
    else
        a_output2+=("- FORWARD chain policy is $forward_policy (should be DROP or REJECT)")
    fi

    output_ok=false
    if [ "$output_policy" = "DROP" ] || [ "$output_policy" = "REJECT" ]; then
        output_ok=true
        a_output+=("- OUTPUT chain policy is $output_policy")
    else
        a_output2+=("- OUTPUT chain policy is $output_policy (should be DROP or REJECT)")
    fi

    # PASS if all policies are DROP or REJECT
    if $input_ok && $forward_ok && $output_ok; then
        audit_result="PASS"
    else
        audit_result="FAIL"
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