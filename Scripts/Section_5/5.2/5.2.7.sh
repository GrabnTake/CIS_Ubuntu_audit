#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if PAM (for su) is relevant; assuming sudo/su context from 5.2
if ! [ -f /etc/pam.d/su ]; then
    audit_result="SKIP"
    a_output+=("- /etc/pam.d/su not found, audit skipped")
else
    # Check pam_wheel.so with use_uid and group
    pam_line=$(grep -Pi '^\h*auth\h+(?:required|requisite)\h+pam_wheel\.so\h+(?:[^#\n\r]+\h+)?((?!\2)(use_uid\b|group=\H+\b))\h+(?:[^#\n\r]+\h+)?((?!\1)(use_uid\b|group=\H+\b))(\h+.*)?$' /etc/pam.d/su 2>/dev/null)
    
    if [ -n "$pam_line" ]; then
        # Extract group name
        group_name=$(echo "$pam_line" | grep -oP 'group=\K\H+' || echo "")
        if [ -n "$group_name" ]; then
            a_output+=("- PAM configuration found: $pam_line")
            # Check group membership
            group_entry=$(grep "^$group_name:" /etc/group)
            if [ -n "$group_entry" ] && ! echo "$group_entry" | grep -q "[^:]$"; then
                audit_result="PASS"
                a_output+=("- Group $group_name has no users: $group_entry")
            else
                audit_result="FAIL"
                a_output2+=("- Group $group_name contains users: $group_entry")
            fi
        else
            audit_result="FAIL"
            a_output2+=("- No group specified in PAM configuration: $pam_line")
        fi
    else
        audit_result="FAIL"
        a_output2+=("- No matching auth required pam_wheel.so with use_uid and group=<group_name> found")
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"