#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if SSH server is in use (installed and active)
if ! { dpkg-query -s openssh-server &>/dev/null && systemctl is-active ssh &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- SSH server is not in use (not installed or not active), audit skipped")
else
    # Define permission mask (0600 = 0777 & ~0177)
    perm_mask='0177'
    maxperm="$(printf '%o' $((0777 & ~$perm_mask)))"  # 0600

    # Function to check file permissions, owner, and group
    check_sshd_file() {
        local l_file="$1"
        while IFS=: read -r l_mode l_user l_group; do
            local issues=()
            if [ $((l_mode & perm_mask)) -gt 0 ]; then
                issues+=("- Mode is $l_mode, should be $maxperm or more restrictive")
            fi
            if [ "$l_user" != "root" ]; then
                issues+=("- Owned by $l_user, should be root")
            fi
            if [ "$l_group" != "root" ]; then
                issues+=("- Group owned by $l_group, should be root")
            fi
            if [ ${#issues[@]} -gt 0 ]; then
                a_output2+=("- File: $l_file has issues:" "${issues[@]}")
            else
                a_output+=("- File: $l_file is correct (mode $l_mode, owner $l_user, group $l_group)")
            fi
        done < <(stat -Lc '%#a:%U:%G' "$l_file" 2>/dev/null)
    }

    # Check /etc/ssh/sshd_config
    if [ -e "/etc/ssh/sshd_config" ]; then
        check_sshd_file "/etc/ssh/sshd_config"
    fi

    # Check /etc/ssh/sshd_config.d/*.conf
    while IFS= read -r -d $'\0' l_file; do
        [ -e "$l_file" ] && check_sshd_file "$l_file"
    done < <(find /etc/ssh/sshd_config.d -type f -name '*.conf' \( -perm /077 -o ! -user root -o ! -group root \) -print0 2>/dev/null)

    # Check for Include statements in sshd_config and process additional directories
    if [ -e "/etc/ssh/sshd_config" ]; then
        while IFS= read -r include_dir; do
            while IFS= read -r -d $'\0' l_file; do
                [ -e "$l_file" ] && check_sshd_file "$l_file"
            done < <(find "$include_dir" -type f -name '*.conf' \( -perm /077 -o ! -user root -o ! -group root \) -print0 2>/dev/null)
        done < <(grep -Ei '^\s*Include\s+' /etc/ssh/sshd_config | awk '{print $2}' | tr -d '"')
    fi

    # Set audit result
    if [ ${#a_output2[@]} -eq 0 ]; then
        audit_result="PASS"
        if [ ${#a_output[@]} -eq 0 ]; then
            a_output+=("- No SSH configuration files found to check")
        fi
    else
        audit_result="FAIL"
    fi
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
if [ ${#a_output[@]} -eq 0 ]; then
    echo "(none)"
else
    printf '%s\n' "${a_output[@]}"
fi

if [ "$audit_result" == "FAIL" ]; then
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${a_output2[@]}"
fi