#!/usr/bin/env bash

a_output=()
a_output2=()

# Arrays to store unowned and ungrouped files/directories
a_nouser=()
a_nogroup=()

# Paths to exclude from the find command
a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "*/kubelet/plugins/*" -a ! -path "/sys/fs/cgroup/memory/*" -a ! -path "/var/*/private/*")

# Get local mount points, excluding specific filesystem types and paths
while IFS= read -r l_mount; do
    while IFS= read -r -d $'\0' l_file; do
        if [ -e "$l_file" ]; then
            # Get user and group ownership
            IFS=':' read -r l_user l_group < <(stat -Lc '%U:%G' "$l_file")
            # Check for unowned (no valid user)
            if [ "$l_user" = "UNKNOWN" ]; then
                a_nouser+=("$l_file")
            fi
            # Check for ungrouped (no valid group)
            if [ "$l_group" = "UNKNOWN" ]; then
                a_nogroup+=("$l_file")
            fi
        fi
    done < <(find "$l_mount" -xdev \( "${a_path[@]}" \) \( -type f -o -type d \) \( -nouser -o -nogroup \) -print0 2> /dev/null)
done < <(findmnt -Dkerno fstype,target | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^\/run\/user\//) {print $2}')

# Check for unowned files or directories
if [ ${#a_nouser[@]} -eq 0 ]; then
    a_output+=("- No files or directories without an owner exist on the local filesystem")
else
    a_output2+=("- Found \"${#a_nouser[@]}\" unowned files or directories on the system:")
    for file in "${a_nouser[@]}"; do
        a_output2+=("  - \"$file\"")
    done
fi

# Check for ungrouped files or directories
if [ ${#a_nogroup[@]} -eq 0 ]; then
    a_output+=("- No files or directories without a group exist on the local filesystem")
else
    a_output2+=("- Found \"${#a_nogroup[@]}\" ungrouped files or directories on the system:")
    for file in "${a_nogroup[@]}"; do
        a_output2+=("  - \"$file\"")
    done
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
echo "Note: This audit may take time on systems with many files or directories."