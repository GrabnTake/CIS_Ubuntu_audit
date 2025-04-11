#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if SSH server is in use
if ! { dpkg-query -s openssh-server &>/dev/null && systemctl is-active ssh &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- SSH server is not in use (not installed or not active), audit skipped")
else
    # Check if Banner is set
    banner_line=$(sshd -T 2>/dev/null | grep -Pi '^banner\h+\/\H+')
    banner_file=$(echo "$banner_line" | awk '$1 == "banner" {print $2}')

    if [ -n "$banner_line" ]; then
        a_output+=("- Banner is set: $banner_line")
        # Check banner file exists
        if [ -e "$banner_file" ]; then
            a_output+=("- Banner file $banner_file exists")
            # Check for prohibited content
            os_id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed 's/"//g')
            if grep -Psi "(\\\v|\\\r|\\\m|\\\s|\b$os_id\b)" "$banner_file" &>/dev/null; then
                audit_result="FAIL"
                a_output2+=("- Banner file $banner_file contains prohibited content (e.g., \\v, \\r, \\m, \\s, or $os_id)")
            else
                audit_result="PASS"
                a_output+=("- Banner file $banner_file has no prohibited content")
                a_output+=("- Note: Verify $banner_file content matches site policy separately")
            fi
        else
            audit_result="FAIL"
            a_output2+=("- Banner file $banner_file does not exist")
        fi
    else
        audit_result="FAIL"
        a_output2+=("- Banner is not set in SSH configuration")
    fi
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"