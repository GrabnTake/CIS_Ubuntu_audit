#!/usr/bin/env bash

a_output=()
a_output2=()

# Function to check umask in files
file_umask_chk() {
    local l_file="$1"
    # Check if umask is set correctly
    if grep -Psiq -- '^\h*umask\h+(0?[0-7][2-7]7|u(=[rwx]{0,3}),g=([rx]{0,2}),o=)(\h*#.*)?$' "$l_file" 2>/dev/null; then
        a_output+=("- umask is set correctly in \"$l_file\"")
    # Check if umask is set incorrectly
    elif grep -Psiq -- '^\h*umask\h+(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b|[0-7][0-7][0-6]\b)|(u=[rwx]{1,3},)?(((g=[rx]?[rx]?w[rx]?[rx]?\b)(,o=[rwx]{1,3})?)|((g=[wrx]{1,3},)?o=[wrx]{1,3}\b)))' "$l_file" 2>/dev/null; then
        a_output2+=("- umask is incorrectly set in \"$l_file\"")
    fi
}

# Check /etc/profile.d/*.sh
while IFS= read -r -d $'\0' l_file; do
    file_umask_chk "$l_file"
done < <(find /etc/profile.d/ -type f -name '*.sh' -print0 2>/dev/null)

# Check other files if no correct umask found yet
[ ${#a_output[@]} -eq 0 ] && l_file="/etc/profile" && file_umask_chk "$l_file"
[ ${#a_output[@]} -eq 0 ] && l_file="/etc/bashrc" && file_umask_chk "$l_file"
[ ${#a_output[@]} -eq 0 ] && l_file="/etc/bash.bashrc" && file_umask_chk "$l_file"

# Check pam_umask.so in /etc/pam.d/postlogin
[ ${#a_output[@]} -eq 0 ] && l_file="/etc/pam.d/postlogin"
if [ ${#a_output[@]} -eq 0 ] && [ -f "$l_file" ]; then
    if grep -Psiq -- '^\h*session\h+[^#\n\r]+\h+pam_umask\.so\h+([^#\n\r]+\h+)?umask=(0?[0-7][2-7]7)\b' "$l_file" 2>/dev/null; then
        a_output+=("- umask is set correctly in \"$l_file\"")
    elif grep -Psiq '^\h*session\h+[^#\n\r]+\h+pam_umask\.so\h+([^#\n\r]+\h+)?umask=(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b))' "$l_file" 2>/dev/null; then
        a_output2+=("- umask is incorrectly set in \"$l_file\"")
    fi
fi

# Check remaining files
[ ${#a_output[@]} -eq 0 ] && l_file="/etc/login.defs" && file_umask_chk "$l_file"
[ ${#a_output[@]} -eq 0 ] && l_file="/etc/default/login" && file_umask_chk "$l_file"

# Check if umask is not set at all
[ ${#a_output[@]} -eq 0 ] && [ ${#a_output2[@]} -eq 0 ] && a_output2+=("- umask is not set in any checked configuration files")

# Determine result
if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
    [ ${#a_output[@]} -eq 0 ] && a_output+=("- umask is correctly configured by default (e.g., system default meets requirements)")
else
    audit_result="FAIL"
fi

# Print audit report
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"