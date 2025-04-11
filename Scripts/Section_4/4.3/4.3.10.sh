#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if nftables is in use
if ! { command -v nft &>/dev/null && nft list ruleset 2>/dev/null | grep -q "hook"; }; then
    audit_result="SKIP"
    a_output+=("- nftables is not in use (no rules exist or not installed), audit skipped")
else
    # Check if /etc/nftables.conf has include statements
    if [ -n "$(grep -E '^\s*include' /etc/nftables.conf 2>/dev/null)" ]; then
        # Get included files
        include_files=$(awk '$1 ~ /^\s*include/ { gsub("\"","",$2); print $2 }' /etc/nftables.conf)
        config_rules=$(cat $include_files 2>/dev/null)

        # INPUT checks
        input_chain=$(echo "$config_rules" | awk '/hook input/,/}/' | grep -c 'type filter hook input priority 0; policy drop')
        input_lo=$(echo "$config_rules" | awk '/hook input/,/}/' | grep -c 'iif "lo" accept')
        input_ipv4_drop=$(echo "$config_rules" | awk '/hook input/,/}/' | grep -c 'ip saddr 127.0.0.0/8.*drop')
        input_ipv6_drop=$(echo "$config_rules" | awk '/hook input/,/}/' | grep -c 'ip6 saddr ::1.*drop')
        input_tcp_est=$(echo "$config_rules" | awk '/hook input/,/}/' | grep -c 'ip protocol tcp ct state established accept')
        input_udp_est=$(echo "$config_rules" | awk '/hook input/,/}/' | grep -c 'ip protocol udp ct state established accept')
        input_ssh=$(echo "$config_rules" | awk '/hook input/,/}/' | grep -c 'tcp dport ssh accept')

        # FORWARD check
        forward_chain=$(echo "$config_rules" | awk '/hook forward/,/}/' | grep -c 'type filter hook forward priority 0; policy drop')

        # OUTPUT checks
        output_chain=$(echo "$config_rules" | awk '/hook output/,/}/' | grep -c 'type filter hook output priority 0; policy drop')
        output_tcp=$(echo "$config_rules" | awk '/hook output/,/}/' | grep -c 'ip protocol tcp ct state established,related,new accept')
        output_udp=$(echo "$config_rules" | awk '/hook output/,/}/' | grep -c 'ip protocol udp ct state established,related,new accept')

        # Verify all required rules
        if [ "$input_chain" -gt 0 ] && [ "$input_lo" -gt 0 ] && [ "$input_ipv4_drop" -gt 0 ] && \
           [ "$input_ipv6_drop" -gt 0 ] && [ "$input_tcp_est" -gt 0 ] && [ "$input_udp_est" -gt 0 ] && \
           [ "$input_ssh" -gt 0 ] && [ "$forward_chain" -gt 0 ] && [ "$output_chain" -gt 0 ] && \
           [ "$output_tcp" -gt 0 ] && [ "$output_udp" -gt 0 ]; then
            audit_result="PASS"
            a_output+=("- nftables base chains are configured on boot:")
            a_output+=("  - INPUT: chain with policy drop, loopback rules, established connections, SSH accept")
            a_output+=("  - FORWARD: chain with policy drop")
            a_output+=("  - OUTPUT: chain with policy drop, established/new connections")
        else
            audit_result="FAIL"
            if [ "$input_chain" -eq 0 ]; then a_output2+=("- INPUT: Missing base chain with policy drop"); fi
            if [ "$input_lo" -eq 0 ]; then a_output2+=("- INPUT: Missing lo accept rule"); fi
            if [ "$input_ipv4_drop" -eq 0 ]; then a_output2+=("- INPUT: Missing IPv4 loopback drop rule"); fi
            if [ "$input_ipv6_drop" -eq 0 ]; then a_output2+=("- INPUT: Missing IPv6 loopback drop rule"); fi
            if [ "$input_tcp_est" -eq 0 ]; then a_output2+=("- INPUT: Missing TCP established accept rule"); fi
            if [ "$input_udp_est" -eq 0 ]; then a_output2+=("- INPUT: Missing UDP established accept rule"); fi
            if [ "$input_ssh" -eq 0 ]; then a_output2+=("- INPUT: Missing SSH accept rule"); fi
            if [ "$forward_chain" -eq 0 ]; then a_output2+=("- FORWARD: Missing base chain with policy drop"); fi
            if [ "$output_chain" -eq 0 ]; then a_output2+=("- OUTPUT: Missing base chain with policy drop"); fi
            if [ "$output_tcp" -eq 0 ]; then a_output2+=("- OUTPUT: Missing TCP established/new accept rule"); fi
            if [ "$output_udp" -eq 0 ]; then a_output2+=("- OUTPUT: Missing UDP established/new accept rule"); fi
        fi
    else
        audit_result="FAIL"
        a_output2+=("- No include statements found in /etc/nftables.conf")
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