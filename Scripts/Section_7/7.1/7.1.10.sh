#!/usr/bin/env bash

a_output=()
a_output2=()

# Expected values
expected_mode="0600"  # rw-------
expected_uid="0"      # root
expected_gid="0"      # root
l_perm_mask="0177"    # Disallow o+rwx, g+rwx (for 0600 or stricter)
l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )))"  # 0600

# Files to check
a_files=("/etc/security/opasswd" "/etc/security/opasswd.old")

# Check each file
for l_file in "${a_files[@]}"; do
    if [ -e "$l_file" ]; then
        # Get file attributes
        l_mode="$(stat -Lc '%#a' "$l_file")"
        l_uid="$(stat -Lc '%u' "$l_file")"
        l_gid="$(stat -Lc '%g' "$l_file")"
        l_user="$(stat -Lc '%U' "$l_file")"
        l_group="$(stat -Lc '%G' "$l_file")"

        # Verify permissions (0600 or more restrictive)
        if [ $(( "$l_mode" & "$l_perm_mask" )) -gt 0 ]; then
            a_output2+=("- $l_file permissions are \"$l_mode\" (should be \"$expected_mode\" or more restrictive)")
        fi

        # Verify UID (0/root)
        if [ "$l_uid" != "$expected_uid" ]; then
            a_output2+=("- $l_file is owned by UID: \"$l_uid/$l_user\" (should be UID: \"$expected_uid/root\")")
        fi

        # Verify GID (0/root)
        if [ "$l_gid" != "$expected_gid" ]; then
            a_output2+=("- $l_file has GID: \"$l_gid/$l_group\" (should be GID: \"$expected_gid/root\")")
        fi

        # If no violations, report success for this file
        if ! printf '%s\n' "${a_output2[@]}" | grep -q "$l_file"; then
            a_output+=("- $l_file is correctly configured - Access: ($l_mode/-rw-------) Uid: ($l_uid/$l_user) Gid: ($l_gid/$l_group)")
        fi
    fi
done

# If no files exist and no violations, report a general pass
if [ ${#a_output[@]} -eq 0 ] && [ ${#a_output2[@]} -eq 0 ]; then
    a_output+=("- No files (/etc/security/opasswd, /etc/security/opasswd.old) exist, nothing to audit")
fi

# Determine result
if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
else
    audit_result="FAIL"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"