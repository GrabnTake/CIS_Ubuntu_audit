#!/usr/bin/env bash

a_output=()
a_output2=()

l_analyze_cmd=$(readlink -f /bin/systemd-analyze 2>/dev/null || echo "/bin/systemd-analyze")
l_include='$IncludeConfig'
a_config_files=("rsyslog.conf")

# Check if rsyslog is installed
if dpkg-query -s rsyslog &>/dev/null || rpm -q rsyslog &>/dev/null; then
    # Find included config files
    while IFS= read -r l_file; do
        l_conf_loc=$(awk '$1~/^\s*'"$l_include"'$/ {print $2}' "$(tr -d '# ' <<< "$l_file")" | tail -n 1)
        [ -n "$l_conf_loc" ] && break
    done < <($l_analyze_cmd cat-config "${a_config_files[@]}" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b' || echo "")

    if [ -d "$l_conf_loc" ]; then
        l_dir="$l_conf_loc"
        l_ext="*"
    elif grep -Psq '\/\*\.([^#/\n\r]+)?\h*$' <<< "$l_conf_loc" || [ -f "$(readlink -f "$l_conf_loc")" ]; then
        l_dir=$(dirname "$l_conf_loc")
        l_ext=$(basename "$l_conf_loc")
    fi

    while read -r -d $'\0' l_file_name; do
        [ -f "$(readlink -f "$l_file_name")" ] && a_config_files+=("$(readlink -f "$l_file_name")")
    done < <(find -L "$l_dir" -type f -name "$l_ext" -print0 2>/dev/null)

    # Check for imtcp configurations
    for l_logfile in "${a_config_files[@]}"; do
        l_fail=$(grep -Psi -- '^\h*module\(load=\"?imtcp\"?\)' "$l_logfile")
        [ -n "$l_fail" ] && a_output2+=("- Advanced format entry to accept incoming logs: \"$l_fail\" found in \"$l_logfile\"")

        l_fail=$(grep -Psi -- '^\h*input\(type=\"?imtcp\"?\b' "$l_logfile")
        [ -n "$l_fail" ] && a_output2+=("- Advanced format entry to accept incoming logs: \"$l_fail\" found in \"$l_logfile\"")
    done

    # Determine result
    if [ ${#a_output2[@]} -eq 0 ]; then
        audit_result="PASS"
        a_output+=("- No entries to accept incoming logs found")
    else
        audit_result="FAIL"
    fi
else
    audit_result="SKIP"
    a_output+=("- rsyslog is not installed")
    a_output+=("- This audit is skipped as rsyslog is not the chosen logging method")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
echo "--------------------------"
echo "Note: This audit applies only if rsyslog is the chosen method for client-side logging and the system is not primarily a logfile server. Ignore if journald is used or if this is a log server."