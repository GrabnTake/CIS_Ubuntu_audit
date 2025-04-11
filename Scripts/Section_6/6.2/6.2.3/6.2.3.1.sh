#!/usr/bin/env bash

a_output=()
a_output2=()

# Expected rule components
expected_files=("/etc/sudoers" "/etc/sudoers.d")
expected_perms="wa"
expected_key="scope"

# Check on-disk rules in /etc/audit/rules.d/*.rules
disk_sudoers_rule=$(awk '/^ *-w/ &&/\/etc\/sudoers/ &&/ +-p *wa/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' /etc/audit/rules.d/*.rules 2>/dev/null | grep -v '^/etc/audit/rules.d/.*: No such file or directory')
disk_sudoersd_rule=$(awk '/^ *-w/ &&/\/etc\/sudoers.d/ &&/ +-p *wa/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' /etc/audit/rules.d/*.rules 2>/dev/null | grep -v '^/etc/audit/rules.d/.*: No such file or directory')

if echo "$disk_sudoers_rule" | grep -qP -- "^\s*-w\s+/etc/sudoers\s+-p\s+wa\s+-k\s+$expected_key\b"; then
    a_output+=("- On-disk rule for /etc/sudoers matches: -w /etc/sudoers -p wa -k $expected_key")
else
    a_output2+=("- On-disk rule for /etc/sudoers missing or incorrect (expected: -w /etc/sudoers -p wa -k $expected_key)")
    [ -n "$disk_sudoers_rule" ] && a_output2+=("- Found: $disk_sudoers_rule")
    a_output2+=("- Add to /etc/audit/rules.d/: -w /etc/sudoers -p wa -k $expected_key")
fi

if echo "$disk_sudoersd_rule" | grep -qP -- "^\s*-w\s+/etc/sudoers.d\s+-p\s+wa\s+-k\s+$expected_key\b"; then
    a_output+=("- On-disk rule for /etc/sudoers.d matches: -w /etc/sudoers.d -p wa -k $expected_key")
else
    a_output2+=("- On-disk rule for /etc/sudoers.d missing or incorrect (expected: -w /etc/sudoers.d -p wa -k $expected_key)")
    [ -n "$disk_sudoersd_rule" ] && a_output2+=("- Found: $disk_sudoersd_rule")
    a_output2+=("- Add to /etc/audit/rules.d/: -w /etc/sudoers.d -p wa -k $expected_key")
fi

# Check running rules with auditctl -l
running_sudoers_rule=$(auditctl -l | awk '/^ *-w/ &&/\/etc\/sudoers/ &&/ +-p *wa/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' 2>/dev/null)
running_sudoersd_rule=$(auditctl -l | awk '/^ *-w/ &&/\/etc\/sudoers.d/ &&/ +- показалp *wa/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/) {print}' 2>/dev/null)

if echo "$running_sudoers_rule" | grep -qP -- "^\s*-w\s+/etc/sudoers\s+-p\s+wa\s+-k\s+$expected_key\b"; then
    a_output+=("- Running rule for /etc/sudoers matches: -w /etc/sudoers -p wa -k $expected_key")
else
    a_output2+=("- Running rule for /etc/sudoers missing or incorrect (expected: -w /etc/sudoers -p wa -k $expected_key)")
    [ -n "$running_sudoers_rule" ] && a_output2+=("- Found: $running_sudoers_rule")
    a_output2+=("- Load rule with auditctl or ensure it persists in /etc/audit/rules.d/")
fi

if echo "$running_sudoersd_rule" | grep -qP -- "^\s*-w\s+/etc/sudoers.d\s+-p\s+wa\s+-k\s+$expected_key\b"; then
    a_output+=("- Running rule for /etc/sudoers.d matches: -w /etc/sudoers.d -p wa -k $expected_key")
else
    a_output2+=("- Running rule for /etc/sudoers.d missing or incorrect (expected: -w /etc/sudoers.d -p wa -k $expected_key)")
    [ -n "$running_sudoersd_rule" ] && a_output2+=("- Found: $running_sudoersd_rule")
    a_output2+=("- Load rule with auditctl or ensure it persists in /etc/audit/rules.d/")
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