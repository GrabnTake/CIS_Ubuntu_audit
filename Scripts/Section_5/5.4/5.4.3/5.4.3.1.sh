#!/usr/bin/env bash

a_output=()
a_output2=()

# Check for nologin in /etc/shells
nologin_found=$(grep -Ps '^\h*([^#\n\r]+)?\/nologin\b' /etc/shells 2>/dev/null)

if [ -z "$nologin_found" ]; then
    audit_result="PASS"
    a_output+=("- '/nologin' is not listed in /etc/shells")
else
    audit_result="FAIL"
    a_output2+=("- '/nologin' is listed in /etc/shells:")
    while IFS= read -r line; do
        a_output2+=("  $line")
    done <<< "$nologin_found"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"