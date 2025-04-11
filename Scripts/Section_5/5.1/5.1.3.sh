#!/usr/bin/env bash

a_output=()
a_output2=()

# Check if SSH server is in use
if ! { dpkg-query -s openssh-server &>/dev/null && systemctl is-active ssh &>/dev/null; }; then
    audit_result="SKIP"
    a_output+=("- SSH server is not in use (not installed or not active), audit skipped")
else
    # Define permission mask (0644)
    pmask="0133"
    maxperm=$(printf '%o' $((0777 & ~pmask)))  # 0644

    # Check file permissions
    check_file() {
        local l_file="$1"
        while IFS=: read -r mode owner group; do
            local issues=()
            [ $((mode & pmask)) -gt 0 ] && issues+=("- Mode is $mode, should be $maxperm or more restrictive")
            [ "$owner" != "root" ] && issues+=("- Owned by $owner, should be root")
            [ "$group" != "root" ] && issues+=("- Group is $group, should be root")
            if [ ${#issues[@]} -gt 0 ]; then
                a_output2+=("- File: $l_file has issues:" "${issues[@]}")
            else
                a_output+=("- File: $l_file is correct (mode $mode, owner $owner, group $group)")
            fi
        done < <(stat -Lc '%#a:%U:%G' "$l_file" 2>/dev/null)
    }

    # Find and verify public key files
    while IFS= read -r -d $'\0' file; do
        if ssh-keygen -lf "$file" &>/dev/null && file "$file" | grep -Piq '\bopenssh\b.*\bpublic\b.*\bkey\b'; then
            check_file "$file"
        fi
    done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null)

    # Set result
    if [ ${#a_output2[@]} -eq 0 ]; then
        audit_result="PASS"
        [ ${#a_output[@]} -eq 0 ] && a_output+=("- No SSH public key files found")
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