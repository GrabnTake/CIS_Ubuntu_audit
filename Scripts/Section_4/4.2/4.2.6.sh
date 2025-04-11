#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if UFW is in use first
if ! {command -v ufw &>/dev/null && systemctl is-active --quiet ufw; } ; then
    audit_result="SKIP"
    a_output+=("- UFW is not in use, audit skipped")
else
    # Get UFW ports
    unset a_ufwout
    while read -r l_ufwport; do
        [ -n "$l_ufwport" ] && a_ufwout+=("$l_ufwport")
    done < <(ufw status verbose | grep -Po '^\h*\d+\b' | sort -u)

    # Get open ports (exclude loopback)
    unset a_openports
    while read -r l_openport; do
        [ -n "$l_openport" ] && a_openports+=("$l_openport")
    done < <(ss -tuln | awk '($5!~/%lo:/ && $5!~/127.0.0.1:/ && $5!~/\[?::1\]?:/) {split($5, a, ":"); print a[2]}' | sort -u)

    # Find ports missing UFW rules
    unset a_diff
    mapfile -t a_diff < <(printf '%s\n' "${a_openports[@]}" "${a_ufwout[@]}" "${a_ufwout[@]}" | sort | uniq -u)

    # Set audit result
    if [ -n "${a_diff[*]}" ]; then
        audit_result="FAIL"
        a_output2+=("- The following open ports lack UFW rules:")
        for port in "${a_diff[@]}"; do
            a_output2+=("- $port")
        done
    else
        audit_result="PASS"
        a_output+=("- All open ports have a rule in UFW")
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