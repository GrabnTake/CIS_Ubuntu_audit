#!/usr/bin/env bash

a_output=()
a_output2=()

# Check umask in root's bash config files
umask_setting=$(grep -Psi -- '^\h*umask\h+(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b|[0-7][0-7][0-6]\b)|(u=[rwx]{1,3},)?(((g=[rx]?[rx]?w[rx]?[rx]?\b)(,o=[rwx]{1,3})?)|((g=[wrx]{1,3},)?o=[wrx]{1,3}\b)))' /root/.bash_profile /root/.bashrc 2>/dev/null)

if [ -n "$umask_setting" ]; then
    audit_result="PASS"
    a_output+=("- Root's umask is configured to enforce permissions ≤ 750 (dirs) and ≤ 640 (files):")
    while IFS= read -r line; do
        a_output+=("  $line")
    done <<< "$umask_setting"
    a_output+=("- Note: Precedence is /root/.bash_profile > /root/.bashrc > system default")
else
    audit_result="FAIL"
    a_output2+=("- No umask setting found in /root/.bash_profile or /root/.bashrc that enforces ≤ 750 (dirs) and ≤ 640 (files)")
    a_output2+=("- Expected examples: 'umask 027', 'umask 077', 'umask u=rwx,g=rx,o='")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"