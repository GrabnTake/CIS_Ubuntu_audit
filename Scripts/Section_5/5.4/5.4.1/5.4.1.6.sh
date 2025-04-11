#!/usr/bin/env bash

a_output=()
a_output2=()

# Check for future password change dates
future_changes=""
while IFS= read -r l_user; do
    l_change=$(date -d "$(chage --list "$l_user" 2>/dev/null | grep '^Last password change' | cut -d: -f2 | grep -v 'never$')" +%s 2>/dev/null)
    if [ -n "$l_change" ] && [ "$l_change" -gt "$(date +%s)" ]; then
        future_changes="$future_changes\nUser: \"$l_user\" last password change was \"$(chage --list "$l_user" | grep '^Last password change' | cut -d: -f2)\""
    fi
done < <(awk -F: '$2~/^\$.+\$/{print $1}' /etc/shadow 2>/dev/null)

if [ -z "$future_changes" ]; then
    audit_result="PASS"
    a_output+=("- No users with a last password change date in the future found in /etc/shadow")
else
    audit_result="FAIL"
    a_output2+=("- Users with last password change dates in the future found:")
    while IFS= read -r line; do
        [ -n "$line" ] && a_output2+=("  $line")
    done <<< "$future_changes"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"