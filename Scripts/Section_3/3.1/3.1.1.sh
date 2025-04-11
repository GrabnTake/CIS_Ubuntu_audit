#!/usr/bin/env bash

a_output=()

# Check if IPv6 is disabled via kernel module parameter
if ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable; then
    a_output+=("- IPv6 is not enabled (kernel module parameter indicates disabled)")
else
    # Check sysctl settings if module isn’t explicitly disabled
    all_disabled=$(sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -Pqs "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && echo "yes" || echo "no")
    default_disabled=$(sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null | grep -Pqs "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b" && echo "yes" || echo "no")
    
    if [ "$all_disabled" = "yes" ] && [ "$default_disabled" = "yes" ]; then
        a_output+=("- IPv6 is not enabled (sysctl settings: net.ipv6.conf.all.disable_ipv6=1, net.ipv6.conf.default.disable_ipv6=1)")
    else
        a_output+=("- IPv6 is enabled")
    fi
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: MANUAL"
echo "--------------------------"
echo "Correct Settings:"
if [ ${#a_output[@]} -eq 0 ]; then
    echo "(none)"
else
    printf '%s\n' "${a_output[@]}"
fi