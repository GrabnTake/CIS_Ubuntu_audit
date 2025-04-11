#!/usr/bin/env bash

a_output=()
a_output2=()

l_analyze_cmd=$(readlink -f /bin/systemd-analyze 2>/dev/null || echo "/bin/systemd-analyze")
l_config_file="/etc/logrotate.conf"

# Check if rsyslog is installed
if dpkg-query -s rsyslog &>/dev/null || rpm -q rsyslog &>/dev/null; then
    # Get include directive
    l_include=$(awk '$1~/^\s*include$/{print$2}' "$l_config_file" 2>/dev/null)
    [ -d "$l_include" ] && l_include="$l_include/*"

    # Capture logrotate config output
    while IFS= read -r l_line; do
        a_output+=("- $l_line")
    done < <($l_analyze_cmd cat-config "$l_config_file" "$l_include" 2>/dev/null)

    if [ ${#a_output[@]} -eq 0 ]; then
        a_output2+=("- No logrotate configuration found or systemd-analyze failed")
    fi

    audit_result="MANUAL"
else
    audit_result="SKIP"
    a_output+=("- rsyslog is not installed")
    a_output+=("- This audit is skipped as rsyslog is not the chosen logging method")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Logrotate Configuration:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "REVIEW REQUIRED" ] && [ ${#a_output2[@]} -gt 0 ] && echo "--------------------------" && echo "Potential Issues:" && printf '%s\n' "${a_output2[@]}"
echo "--------------------------"
echo "Note: This audit applies only if rsyslog is the chosen method for client-side logging. Ignore if journald is used."
[ "$audit_result" = "REVIEW REQUIRED" ] && echo "Review Note: Manually analyze the listed logrotate configuration. The last occurrence of each setting takes precedence."