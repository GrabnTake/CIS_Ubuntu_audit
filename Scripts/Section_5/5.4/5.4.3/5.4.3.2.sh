#!/usr/bin/env bash

a_output=()
a_output2=()

# Set BRC if /etc/bashrc exists
[ -f /etc/bashrc ] && BRC="/etc/bashrc" || BRC=""

# Check for correct TMOUT configuration
tmout_config=""
for f in "$BRC" /etc/profile /etc/profile.d/*.sh; do
    if [ -f "$f" ] && grep -Pq '^\s*([^#]+\s+)?TMOUT=(900|[1-8][0-9][0-9]|[1-9][0-9]|[1-9])\b' "$f" 2>/dev/null && \
       grep -Pq '^\s*([^#]+;\s*)?readonly\s+TMOUT(\s+|\s*;|\s*$|=(900|[1-8][0-9][0-9]|[1-9][0-9]|[1-9]))\b' "$f" 2>/dev/null && \
       grep -Pq '^\s*([^#]+;\s*)?export\s+TMOUT(\s+|\s*;|\s*$|=(900|[1-8][0-9][0-9]|[1-9][0-9]|[1-9]))\b' "$f" 2>/dev/null; then
        tmout_config="$f"
        break  # Stop at first valid config
    fi
done

# Check for incorrect TMOUT (longer than 900)
tmout_incorrect=$(grep -Ps '^\s*([^#]+\s+)?TMOUT=(9[0-9][1-9]|9[1-9][0-9]|0+|[1-9]\d{3,})\b' /etc/profile /etc/profile.d/*.sh "$BRC" 2>/dev/null)

# Determine result
if [ -n "$tmout_config" ] && [ -z "$tmout_incorrect" ]; then
    audit_result="PASS"
    a_output+=("- TMOUT is configured correctly in: \"$tmout_config\"")
    a_output+=("- Timeout is ≤ 900 seconds, readonly, and exported")
else
    audit_result="FAIL"
    [ -z "$tmout_config" ] && a_output2+=("- TMOUT is not configured with timeout ≤ 900, readonly, and exported in /etc/profile, /etc/profile.d/*.sh, or $BRC")
    [ -n "$tmout_incorrect" ] && a_output2+=("- TMOUT is incorrectly set to a timeout > 900 seconds:") && \
        while IFS= read -r line; do
            a_output2+=("  $line")
        done <<< "$tmout_incorrect"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"