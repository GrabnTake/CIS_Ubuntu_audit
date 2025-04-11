#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if UFW is in use first
if ! {command -v ufw &>/dev/null && systemctl is-active --quiet ufw; } ; then
    audit_result="SKIP"
    a_output+=("- UFW is not in use, audit skipped")
else
    # Check loopback accepts traffic in before.rules
    if grep -P -- 'lo|127.0.0.0' /etc/ufw/before.rules | grep -q -e "-A ufw-before-input -i lo -j ACCEPT" -e "-A ufw-before-output -o lo -j ACCEPT"; then
        a_output+=("- Loopback interface accepts all traffic")
    else
        a_output2+=("- Loopback interface does not accept all traffic in /etc/ufw/before.rules")
    fi

    # Check other interfaces deny loopback network traffic
    if ufw status verbose | grep -q -e "Anywhere\s\+DENY IN\s\+127.0.0.0/8" -e "Anywhere (v6)\s\+DENY IN\s\+::1"; then
        a_output+=("- Other interfaces deny traffic to loopback network (127.0.0.0/8 and ::1/128)")
    else
        a_output2+=("- Other interfaces do not deny traffic to loopback network (127.0.0.0/8 and ::1/128)")
    fi

    # Set audit result based on checks
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