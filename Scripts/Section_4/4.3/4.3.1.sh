#!/usr/bin/env bash
a_output=()
a_output2=()
if ! { command -v nft &>/dev/null && nft list tables 2>/dev/null | grep -q "^table"; }; then
    if  dpkg-query -s nftables &>/dev/null ; then  
        audit_result="PASS"
        a_output+=("- Uncomplicated Firewall (nftables) is installed")
    else
        a_output2+=("- Uncomplicated Firewall (nftables) is not installed")
        audit_result="FAIL"
    fi
else
    audit_result="SKIP"
    a_output+=("- nftables is not in use (no tables exist or not installed), audit skipped")
fi

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