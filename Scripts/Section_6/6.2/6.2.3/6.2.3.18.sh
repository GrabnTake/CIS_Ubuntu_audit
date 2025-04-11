#!/usr/bin/env bash

a_output=()
a_output2=()

# Get UID_MIN from /etc/login.defs
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
if [ -z "$UID_MIN" ]; then
    a_output2+=("- ERROR: Variable 'UID_MIN' is unset in /etc/login.defs")
fi

# Expected rule components
expected_key="usermod"
expected_rules=(
    "-a always,exit -F path=/usr/sbin/usermod -F perm=x -F auid>=$UID_MIN -F auid!=unset -k $expected_key"
)
running_rules=(
    "-a always,exit -S all -F path=/usr/sbin/usermod -F perm=x -F auid>=$UID_MIN -F auid!=-1 -F key=$expected_key"
)

# Function to check rules (logic unchanged)
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

# Define audit commands (exact logic from your input)
[ -n "$UID_MIN" ] && {
    disk_cmd="awk '/^ *-a *always,exit/ &&(/ -F *auid!=unset/||/ -F *auid!=-1/||/ -F *auid!=4294967295/) &&/ -F *auid>=$UID_MIN/ &&/ -F *perm=x/ &&/ -F *path=\/usr\/sbin\/usermod/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' /etc/audit/rules.d/*.rules"
    running_cmd="auditctl -l | awk '/^ *-a *always,exit/ &&(/ -F *auid!=unset/||/ -F *auid!=-1/||/ -F *auid!=4294967295/) &&/ -F *auid>=$UID_MIN/ &&/ -F *perm=x/ &&/ -F *path=\/usr\/sbin\/usermod/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}'"
}

# Check all rules if UID_MIN is set (logic preserved)
if [ -n "$UID_MIN" ]; then
    for i in "${!expected_rules[@]}"; do
        check_rules "disk" "$disk_cmd" "${expected_rules[$i]}"
        check_rules "running" "$running_cmd" "${running_rules[$i]}"
    done
fi

# Summarize failures if all are missing
if [ ${#a_output[@]} -eq 0 ] && [ ${#a_output2[@]} -eq 2 ] && [ -n "$UID_MIN" ]; then
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