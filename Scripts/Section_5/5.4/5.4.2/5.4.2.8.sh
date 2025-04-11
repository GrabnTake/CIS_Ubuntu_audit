#!/usr/bin/env bash

a_output=()
a_output2=()

# Get valid shells (excluding nologin) from /etc/shells
l_valid_shells="^($(awk -F/ '$NF != "nologin" {print}' /etc/shells 2>/dev/null | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' -))$"

# Check non-root accounts without valid shells for lock status
unlocked_accounts=""
while IFS= read -r l_user; do
    result=$(passwd -S "$l_user" 2>/dev/null | awk '$2 !~ /^L/ {print "Account: \"" $1 "\" does not have a valid login shell and is not locked"}')
    if [ -n "$result" ]; then
        unlocked_accounts="$unlocked_accounts\n$result"
    fi
done < <(awk -v pat="$l_valid_shells" -F: '($1 != "root" && $(NF) !~ pat) {print $1}' /etc/passwd 2>/dev/null)

if [ -z "$unlocked_accounts" ]; then
    audit_result="PASS"
    a_output+=("- All non-root accounts without a valid login shell are locked")
else
    audit_result="FAIL"
    a_output2+=("- Non-root accounts without a valid login shell are not locked:")
    while IFS= read -r line; do
        [ -n "$line" ] && a_output2+=("  $line")
    done <<< "$unlocked_accounts"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"