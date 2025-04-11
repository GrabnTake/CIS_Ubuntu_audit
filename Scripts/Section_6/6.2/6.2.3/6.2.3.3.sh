#!/bin/bash

# Define expected settings
expected_settings=(
    "-a always,exit -F arch=b64 -S adjtimex,settimeofday -F key=time-change"
    "-a always,exit -F arch=b32 -S settimeofday,adjtimex -F key=time-change"
    "-a always,exit -F arch=b64 -S clock_settime -F a0=0x0 -F key=time-change"
    "-a always,exit -F arch=b32 -S clock_settime -F a0=0x0 -F key=time-change"
    "-w /etc/localtime -p wa -k time-change"
)

# Initialize audit output array
a_output=()

# Check if audit rules file exists
if ls /etc/audit/rules.d/*.rules >/dev/null 2>&1; then
    a_output+=( $(awk '/^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -S/ && (/adjtimex/ || /settimeofday/ || /clock_settime/) && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)' /etc/audit/rules.d/*.rules) )
    a_output+=( $(awk '/^ *-w/ && /\/etc\/localtime/ && / +-p *wa/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)' /etc/audit/rules.d/*.rules) )
fi

# Check if auditctl is available
if command -v auditctl >/dev/null 2>&1; then
    a_output+=( $(auditctl -l | awk '/^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -S/ && (/adjtimex/ || /settimeofday/ || /clock_settime/) && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)') )
    a_output+=( $(auditctl -l | awk '/^ *-w/ && /\/etc\/localtime/ && / +-p *wa/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)') )
fi

# Determine compliance
non_compliant=()
for expected in "${expected_settings[@]}"; do
    if ! printf '%s\n' "${a_output[@]}" | grep -q -- "$expected"; then
        non_compliant+=("Missing: $expected")
    fi
done

# Define audit result
audit_result="PASS"
if [ ${#non_compliant[@]} -gt 0 ]; then
    audit_result="FAIL"
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${non_compliant[@]}"
