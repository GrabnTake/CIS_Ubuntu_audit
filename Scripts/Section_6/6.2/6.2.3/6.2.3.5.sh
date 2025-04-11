#!/usr/bin/env bash

a_output=()
a_output2=()

# Expected rule components
expected_key="system-locale"
expected_rules=(
    "-a always,exit -F arch=b64 -S sethostname,setdomainname -k $expected_key"
    "-a always,exit -F arch=b32 -S sethostname,setdomainname -k $expected_key"
    "-w /etc/issue -p wa -k $expected_key"
    "-w /etc/issue.net -p wa -k $expected_key"
    "-w /etc/hosts -p wa -k $expected_key"
    "-w /etc/networks -p wa -k $expected_key"
    "-w /etc/network -p wa -k $expected_key"
    "-w /etc/netplan -p wa -k $expected_key"
)

# Function to check rules
check_rules() {
    local type="$1"  # "disk" or "running"
    local cmd="$2"
    local expected="$3"
    local found_rule

    if [ "$type" = "disk" ]; then
        found_rule=$(eval "$cmd" 2>/dev/null | grep -v '^/etc/audit/rules.d/.*: No such file or directory')
    else
        found_rule=$(eval "$cmd" 2>/dev/null)
    fi

    if echo "$found_rule" | grep -qP -- "^\s*${expected}\b"; then
        a_output+=("- ${type^} rule matches: $expected")
    else
        a_output2+=("- ${type^} rule missing or incorrect: $expected")
    fi
}

# Define audit commands
disk_cmd_syscall="awk '/^ *-a *always,exit/ &&/ -F *arch=b(32|64)/ &&/ -S/ &&(/sethostname/ ||/setdomainname/) &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' /etc/audit/rules.d/*.rules"
disk_cmd_files="awk '/^ *-w/ &&(/\/etc\/issue$/ ||/\/etc\/issue.net$/ ||/\/etc\/hosts$/ ||/\/etc\/networks$/ ||/\/etc\/network$/ ||/\/etc\/netplan$/) &&/ +-p *wa/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' /etc/audit/rules.d/*.rules"
running_cmd_syscall="auditctl -l | awk '/^ *-a *always,exit/ &&/ -F *arch=b(32|64)/ &&/ -S/ &&(/sethostname/ ||/setdomainname/) &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}'"
running_cmd_files="auditctl -l | awk '/^ *-w/ &&(/\/etc\/issue$/ ||/\/etc\/issue.net$/ ||/\/etc\/hosts$/ ||/\/etc\/networks$/ ||/\/etc\/network$/ ||/\/etc\/netplan$/) &&/ +-p *wa/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}'"

# Check all rules
for rule in "${expected_rules[@]}"; do
    if [[ "$rule" =~ "arch=b" ]]; then
        check_rules "disk" "$disk_cmd_syscall" "$rule"
        check_rules "running" "$running_cmd_syscall" "$rule"
    else
        check_rules "disk" "$disk_cmd_files" "$rule"
        check_rules "running" "$running_cmd_files" "$rule"
    fi
done

# Summarize failures if all are missing
if [ ${#a_output[@]} -eq 0 ] && [ ${#a_output2[@]} -ge 16 ]; then
    a_output2=("- All expected on-disk and running rules are missing (key: $expected_key)")
fi

# Check if auditctl is available
if ! command -v auditctl >/dev/null 2>&1; then
    a_output2+=("- auditctl not found; running configuration checks incomplete")
    a_output2+=("- Install auditd package")
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