#!/usr/bin/env bash

a_output=()
a_output2=()

l_systemd_config_file="/etc/tmpfiles.d/systemd.conf"
l_analyze_cmd=$(readlink -f /bin/systemd-analyze 2>/dev/null || echo "/bin/systemd-analyze")

f_file_chk() {
    local l_maxperm=$(printf '%o' $((0777 & ~$l_perm_mask)))
    if [ $((l_mode & l_perm_mask)) -le 0 ] || [[ "$l_type" = "Directory" && "$l_mode" =~ 275(0|5) ]]; then
        a_output+=("- $l_type \"$l_logfile\": mode \"$l_mode\", owner \"$l_user\", group \"$l_group\"")
    else
        a_output2+=("- $l_type \"$l_logfile\": mode \"$l_mode\", owner \"$l_user\", group \"$l_group\" (should be \"$l_maxperm\" or more restrictive)")
    fi
}

while IFS= read -r l_file; do
    l_file=$(tr -d '# ' <<< "$l_file")
    l_logfile_perms_line=$(awk '($1~/^(f|d)$/ && $2~/\/\S+/ && $3~/[0-9]{3,}/){print $2 ":" $3 ":" $4 ":" $5}' "$l_file" 2>/dev/null)
    while IFS=: read -r l_logfile l_mode l_user l_group; do
        if [ -n "$l_logfile" ]; then
            if [ -d "$l_logfile" ] || echo "$l_logfile" | grep -q "^/"; then
                l_type="Directory"
                if echo "$l_logfile" | grep -Psq '^(\/run|\/var\/lib\/systemd)\b'; then
                    l_perm_mask="0022"  # 0755
                else
                    l_perm_mask="0027"  # 2755 or 0750
                fi
            else
                l_type="File"
                l_perm_mask="0137"  # 0640
            fi
            grep -Psq '^(\/run|\/var\/lib\/systemd)\b' <<< "$l_logfile" && l_perm_mask="0022"
            f_file_chk
        fi
    done <<< "$l_logfile_perms_line"
done < <($l_analyze_cmd cat-config "$l_systemd_config_file" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b' || echo "")

# Fallback to filesystem if no config found
if [ ${#a_output[@]} -eq 0 ] && [ ${#a_output2[@]} -eq 0 ]; then
    for l_logfile in /var/log/journal/*/*.journal; do
        if [ -f "$l_logfile" ]; then
            l_mode=$(stat -c '%a' "$l_logfile" 2>/dev/null)
            l_user=$(stat -c '%U' "$l_logfile" 2>/dev/null)
            l_group=$(stat -c '%G' "$l_logfile" 2>/dev/null)
            l_perm_mask="0137"
            l_type="File"
            f_file_chk
        fi
    done
    for l_logfile in /run /var/lib/systemd; do
        if [ -d "$l_logfile" ]; then
            l_mode=$(stat -c '%a' "$l_logfile" 2>/dev/null)
            l_user=$(stat -c '%U' "$l_logfile" 2>/dev/null)
            l_group=$(stat -c '%G' "$l_logfile" 2>/dev/null)
            l_perm_mask="0022"
            l_type="Directory"
            f_file_chk
        fi
    done
fi

if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
    [ ${#a_output[@]} -eq 0 ] && a_output+=("- No specific systemd-journald log file or directory permissions configured; defaults assumed compliant")
else
    audit_result="FAIL"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
echo "--------------------------"
echo "Review Required: Ensure listed permissions align with site policy (e.g., log files ≤ 0640, dirs ≤ 0755 or 2755/0750)"