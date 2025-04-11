#!/usr/bin/env bash

a_output=()
a_output2=()

# Expected rule components
expected_key="user_emulation"
expected_rules=(
    "-a always,exit -F arch=b64 -C euid!=uid -F auid!=unset -S execve -k $expected_key"
    "-a always,exit -F arch=b32 -C euid!=uid -F auid!=unset -S execve -k $expected_key"
)
running_rules=(
    "-a always,exit -F arch=b64 -S execve -C uid!=euid -F auid!=-1 -k $expected_key"
    "-a always,exit -F arch=b32 -S execve -C uid!=euid -F auid!=-1 -k $expected_key"
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
disk_cmd="awk '/^ *-a *always,exit/ &&/ -F *arch=b(32|64)/ &&(/ -F *auid!=unset/||/ -F *auid!=-1/||/ -F *auid!=4294967295/) &&(/ -C *euid!=uid/||/ -C *uid!=euid/) &&/ -S *execve/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' /etc/audit/rules.d/*.rules"
running_cmd="auditctl -l | awk '/^ *-a *always,exit/ &&/ -F *arch=b(32|64)/ &&(/ -F *auid!=unset/||/ -F *auid!=-1/||/ -F *auid!=4294967295/) &&(/ -C *euid!=uid/||/ -C *uid!=euid/) &&/ -S *execve/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}'"

# Check all rules
for i in "${!expected_rules[@]}"; do
    check_rules "disk" "$disk_cmd" "${expected_rules[$i]}"
    check_rules "running" "$running_cmd" "${running_rules[$i]}"
done

# Summarize failures if all are missing
if [ ${#a_output[@]} -eq 0 ] && [ ${#a_output2[@]} -eq 4 ]; then
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