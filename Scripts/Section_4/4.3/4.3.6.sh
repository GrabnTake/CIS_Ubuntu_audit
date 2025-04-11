#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if nftables is in use
if ! { command -v nft &>/dev/null && nft list ruleset 2>/dev/null | grep -q "hook"; }; then
    audit_result="SKIP"
    a_output+=("- nftables is not in use (no rules exist or not installed), audit skipped")
else
    # Check loopback rules if nftables is in use
    ruleset=$(nft list ruleset 2>/dev/null)
    
    # Check lo accept
    lo_accept=$(echo "$ruleset" | awk '/hook input/,/}/' | grep -c 'iif "lo" accept')
    # Check IPv4 loopback drop
    ipv4_drop=$(echo "$ruleset" | awk '/hook input/,/}/' | grep -c 'ip saddr 127.0.0.0/8.*drop')
    # Check IPv6 status and loopback drop if enabled
    ipv6_enabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)
    if [ "$ipv6_enabled" = "0" ]; then
        ipv6_drop=$(echo "$ruleset" | awk '/hook input/,/}/' | grep -c 'ip6 saddr ::1.*drop')
    else
        ipv6_drop=1  # Pass if IPv6 is disabled
    fi

    if [ "$lo_accept" -gt 0 ] && [ "$ipv4_drop" -gt 0 ] && [ "$ipv6_drop" -gt 0 ]; then
        audit_result="PASS"
        a_output+=("- nftables loopback interface is configured correctly:")
        a_output+=("  - Accepts traffic on 'lo' interface")
        a_output+=("  - Drops IPv4 loopback traffic (127.0.0.0/8)")
        if [ "$ipv6_enabled" = "0" ]; then
            a_output+=("  - Drops IPv6 loopback traffic (::1)")
        else
            a_output+=("  - IPv6 is disabled, no loopback rule needed")
        fi
    else
        audit_result="FAIL"
        if [ "$lo_accept" -eq 0 ]; then
            a_output2+=("- Missing rule to accept traffic on 'lo' interface")
        fi
        if [ "$ipv4_drop" -eq 0 ]; then
            a_output2+=("- Missing rule to drop IPv4 loopback traffic (127.0.0.0/8)")
        fi
        if [ "$ipv6_enabled" = "0" ] && [ "$ipv6_drop" -eq 0 ]; then
            a_output2+=("- Missing rule to drop IPv6 loopback traffic (::1)")
        fi
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