#!/usr/bin/env bash

a_output=()
a_output2=()
a_port_list=("25" "465" "587")

# Check ports for non-loopback listening
for l_port_number in "${a_port_list[@]}"; do
    if ss -plntu | grep -P -- ":${l_port_number}\b" | grep -Pvq -- '\h+(127\.0\.0\.1|\[?::1\]?):'"${l_port_number}"'\b'; then
        a_output2+=(" - Port \"${l_port_number}\" is listening on a non-loopback network interface")
    else
        a_output+=(" - Port \"${l_port_number}\" is not listening on a non-loopback network interface")
    fi
done

# Check MTA binding
if command -v postconf &> /dev/null; then
    l_interfaces="$(postconf -n inet_interfaces)"
elif command -v exim &> /dev/null; then
    l_interfaces="$(exim -bP local_interfaces)"
elif command -v sendmail &> /dev/null; then
    l_interfaces="$(grep -i '0 DaemonPortOptions=' /etc/mail/sendmail.cf | grep -oP '(?<=Addr=)[^,]+')"
else
    l_interfaces=""
fi

if [ -n "$l_interfaces" ]; then
    if grep -Pqi '\ball\b' <<< "$l_interfaces"; then
        a_output2+=(" - MTA is bound to all network interfaces")
    elif ! grep -Pqi '(127\.0\.0\.1|::1|loopback|localhost)' <<< "$l_interfaces"; then
        a_output2+=(" - MTA is bound to a non-loopback network interface: \"$l_interfaces\"")
    else
        a_output+=(" - MTA is bound to a loopback network interface: \"$l_interfaces\"")
    fi
else
    a_output+=(" - No MTA detected or configured")
fi

# Set audit result
audit_result="FAIL"
if [ "${#a_output2[@]}" -le 0 ]; then
    audit_result="PASS"
fi

# Report results in plain text format
if [ ${#l_output2[@]} -le 0 ]; then
    echo "====== Audit Report ======"
    echo "Audit Result: PASS"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${l_output[@]}"
else
    echo "====== Audit Report ======"
    echo "Audit Result: FAIL"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${l_output[@]}"
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${l_output2[@]}"
fi