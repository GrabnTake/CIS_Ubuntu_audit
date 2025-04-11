#!/usr/bin/env bash

a_output=()
a_output2=()

# Get listening ports/services (TCP/UDP, exclude headers)
mapfile -t listening_services < <(ss -plntu | grep -v '^State' | grep -E 'LISTEN|\*' | awk '{print $1 " " $4 " " $NF}')

# Check if there are any listening services
if [ ${#listening_services[@]} -eq 0 ]; then
    a_output+=("- No services are listening on any network ports")
else
    for service in "${listening_services[@]}"; do
        proto=$(echo "$service" | awk '{print $1}')  # e.g., tcp, udp
        addr_port=$(echo "$service" | awk '{print $2}')  # e.g., 0.0.0.0:22
        process=$(echo "$service" | awk '{$1=$2=""; print substr($0,3)}' | sed 's/^[[:space:]]*//')  # e.g., "users:(("sshd",pid=1234,fd=3))"
        a_output2+=("- Service listening: Protocol: \"$proto\", Address:Port: \"$addr_port\", Process: \"$process\"")
    done
fi

# Set audit result to Manual
audit_result="Manual"

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

echo "--------------------------"
echo "Reason(s) for Failure (Review Required):"
if [ ${#a_output2[@]} -eq 0 ]; then
    echo "(none)"
else
    printf '%s\n' "${a_output2[@]}"
fi