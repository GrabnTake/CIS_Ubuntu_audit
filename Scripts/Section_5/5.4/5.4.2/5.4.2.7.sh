#!/usr/bin/env bash

a_output=()
a_output2=()

# Get valid shells (excluding nologin) from /etc/shells
l_valid_shells="^($(awk -F/ '$NF != "nologin" {print}' /etc/shells 2>/dev/null | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' -))$"
# Get UID_MIN from /etc/login.defs
uid_min=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)
[ -z "$uid_min" ] && uid_min=1000  # Default to 1000 if not found

# Check system accounts with valid shells
invalid_accounts=$(awk -v pat="$l_valid_shells" -F: '($1!~/^(root|halt|sync|shutdown|nfsnobody)$/ && ($3<'"$uid_min"' || $3 == 65534) && $(NF) ~ pat) {print "Service account: \"" $1 "\" has a valid shell: " $7}' /etc/passwd 2>/dev/null)

if [ -z "$invalid_accounts" ]; then
    audit_result="PASS"
    a_output+=("- No system accounts (except root, halt, sync, shutdown, nfsnobody) have a valid login shell")
else
    audit_result="FAIL"
    a_output2+=("- System accounts with valid login shells found (should have nologin or similar):")
    while IFS= read -r line; do
        a_output2+=("  $line")
    done <<< "$invalid_accounts"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"