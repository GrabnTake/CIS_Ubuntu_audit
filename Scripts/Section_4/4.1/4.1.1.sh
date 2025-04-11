#!/usr/bin/env bash

active_firewall=()
firewalls=("ufw" "nftables" "iptables")

# Check which firewalls are in use
for firewall in "${firewalls[@]}"; do
    case $firewall in
        nftables) cmd="nft" ;;
        *) cmd="$firewall" ;;
    esac
    if command -v "$cmd" &>/dev/null && systemctl is-enabled --quiet "$firewall" && systemctl is-active --quiet "$firewall"; then
        active_firewall+=("$firewall")
    fi
done

# Set audit result
audit_result="FAIL"
if [ ${#active_firewall[@]} -eq 1 ]; then
    audit_result="PASS"
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
if [ ${#active_firewall[@]} -eq 1 ]; then
    printf '%s\n' "- A single firewall is in use: ${active_firewall[0]}"
else
    echo "(none)"
fi

if [ "$audit_result" == "FAIL" ]; then
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    if [ ${#active_firewall[@]} -eq 0 ]; then
        printf '%s\n' "- No firewall in use or unable to determine firewall status"
    else
        printf '%s\n' "- Multiple firewalls are in use: ${active_firewall[*]}"
    fi
fi