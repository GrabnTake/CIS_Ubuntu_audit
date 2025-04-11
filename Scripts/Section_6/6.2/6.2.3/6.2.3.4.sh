#!/usr/bin/env bash

a_output=()
a_output2=()

# Expected rule components
expected_key="time-change"
declare -A expected_rules=(
    ["b64_adj_set"]="-a always,exit -F arch=b64 -S adjtimex,settimeofday -k $expected_key"
    ["b32_adj_set"]="-a always,exit -F arch=b32 -S adjtimex,settimeofday -k $expected_key"
    ["b64_clock"]="-a always,exit -F arch=b64 -S clock_settime -F a0=0x0 -k $expected_key"
    ["b32_clock"]="-a always,exit -F arch=b32 -S clock_settime -F a0=0x0 -k $expected_key"
    ["localtime"]="-w /etc/localtime -p wa -k $expected_key"
)
declare -A running_rules=(
    ["b64_adj_set"]="-a always,exit -F arch=b64 -S adjtimex,settimeofday -k $expected_key"
    ["b32_adj_set"]="-a always,exit -F arch=b32 -S settimeofday,adjtimex -k $expected_key"
    ["b64_clock"]="-a always,exit -F arch=b64 -S clock_settime -F a0=0x0 -k $expected_key"
    ["b32_clock"]="-a always,exit -F arch=b32 -S clock_settime -F a0=0x0 -k $expected_key"
    ["localtime"]="-w /etc/localtime -p wa -k $expected_key"
)

# Function to check rules
check_rules() {
    local type="$1"  # "disk" or "running"
    local cmd="$2"
    local rule_key="$3"
    local expected="$4"
    local found_rule

    if [ "$type" = "disk" ]; then
        found_rule=$(eval "$cmd" 2>/dev/null | grep -v '^/etc/audit/rules.d/.*: No such file or directory')
    else
        found_rule=$(eval "$cmd" 2>/dev/null)
    fi

    if echo "$found_rule" | grep -qP -- "^\s*${expected}\b"; then
        a_output+=("- ${type^} rule for $rule_key matches: $expected")
    else
        a_output2+=("- ${type^} rule for $rule_key missing or incorrect (expected: $expected)")
        [ -n "$found_rule" ] && a_output2+=("- Found: $found_rule")
        if [ "$type" = "disk" ]; then
            a_output2+=("- Add to /etc/audit/rules.d/: $expected")
        else
            a_output2+=("- Load rule with auditctl or ensure it persists in /etc/audit/rules.d/")
        fi
    fi
}

# Define audit commands
disk_cmds=(
    "awk '/^ *-a *always,exit/ &&/ -F *arch=b64/ &&/ -S/ &&(/adjtimex/ ||/settimeofday/) &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' /etc/audit/rules.d/*.rules"
    "awk '/^ *-a *always,exit/ &&/ -F *arch=b32/ &&/ -S/ &&(/adjtimex/ ||/settimeofday/) &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' /etc/audit/rules.d/*.rules"
    "awk '/^ *-a *always,exit/ &&/ -F *arch=b64/ &&/ -S *clock_settime/ &&/ -F *a0=0x0/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' /etc/audit/rules.d/*.rules"
    "awk '/^ *-a *always,exit/ &&/ -F *arch=b32/ &&/ -S *clock_settime/ &&/ -F *a0=0x0/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' /etc/audit/rules.d/*.rules"
    "awk '/^ *-w/ &&/\/etc\/localtime/ &&/ +-p *wa/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' /etc/audit/rules.d/*.rules"
)
running_cmds=(
    "auditctl -l | awk '/^ *-a *always,exit/ &&/ -F *arch=b64/ &&/ -S/ &&(/adjtimex/ ||/settimeofday/) &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}'"
    "auditctl -l | awk '/^ *-a *always,exit/ &&/ -F *arch=b32/ &&/ -S/ &&(/adjtimex/ ||/settimeofday/) &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}'"
    "auditctl -l | awk '/^ *-a *always,exit/ &&/ -F *arch=b64/ &&/ -S *clock_settime/ &&/ -F *a0=0x0/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}'"
    "auditctl -l | awk '/^ *-a *always,exit/ &&/ -F *arch=b32/ &&/ -S *clock_settime/ &&/ -F *a0=0x0/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}'"
    "auditctl -l | awk '/^ *-w/ &&/\/etc\/localtime/ &&/ +-p *wa/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}'"
)

# Check all rules
keys=("b64_adj_set" "b32_adj_set" "b64_clock" "b32_clock" "localtime")
for i in "${!keys[@]}"; do
    check_rules "disk" "${disk_cmds[$i]}" "${keys[$i]}" "${expected_rules[${keys[$i]}]}"
    check_rules "running" "${running_cmds[$i]}" "${keys[$i]}" "${running_rules[${keys[$i]}]}"
done

# Check if auditctl is available
if ! command -v auditctl >/dev/null 2>&1; then
    a_output2+=("- auditctl not found; running configuration checks skipped or incomplete")
    a_output2+=("- Install auditd package to enable rule checking")
fi

# Determine result
if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
else
    audit_result="FAIL"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"